// The game runtime. It drives the Ink story and turns its output into items the UI draws:
// lines (narration, the teller, dialogue, voices), check results, sound and art cues, tasks.
// No DOM here: the same class runs the browser build and the playthrough bots in Node.
//
// Conventions the Ink follows (full list in content/ink/README.md):
//   FATHER: text          a line spoken by the voice or character with that id
//   NARRATOR: text        the teller, years later
//   #check: father 8 {n}  on a choice: a check lent by that voice, target 8, situational modifier n
//   #loc: pool            on a choice: where it happens (lights up that spot on the floor sketch)
//   #sfx / #music / #amb / #portrait / #screen / #task / #done / #bark / #pause / #prompt / #always
(function (B) {
  'use strict';

  const SPEAKER = /^([A-Z][A-Z0-9_]*):\s+([\s\S]*)$/;
  const LOG_CAP = 400;
  const SAVE_LOG = 80;
  const SAVE_VERSION = 1;

  function inkValue(v) {
    if (v == null) return v;
    if (typeof v === 'object' && typeof v.orderedItems !== 'undefined') {
      return v.orderedItems.map(function (kv) { return kv.Key.itemName; });
    }
    return v;
  }

  class Game {
    // content: { story, voices, characters, barks, psyche, assets, meta }
    constructor(content, opts) {
      opts = opts || {};
      this.content = content;
      this.ink = opts.ink || globalThis.inkjs;
      if (!this.ink) throw new Error('inkjs is not loaded');
      this.voiceDefs = content.voices || {};
      this.charDefs = content.characters || {};
      this.speakers = {};
      for (const id in this.voiceDefs) this.speakers[id.toUpperCase()] = { id: id, kind: 'voice', def: this.voiceDefs[id] };
      for (const id in this.charDefs) this.speakers[id.toUpperCase()] = { id: id, kind: 'character', def: this.charDefs[id] };
      this.barks = new B.Barks(content.barks || []);
      this.psyche = new B.Psyche(this.voiceDefs, content.psyche);
      this.rng = new B.Rng(1);
      this.story = null;
      this.errors = [];
      this._reset();
    }

    _reset() {
      this.log = [];
      this.tasks = {};
      this.checkHistory = [];
      this.barksUsed = [];
      this.turn = 0;
      this.screen = null;
      this.ended = false;
      this.choices = [];
      this.suppressed = 0;
      this._pending = [];
      this.seed = 0;
    }

    _makeStory() {
      const story = new this.ink.Story(this.content.story);
      story.allowExternalFunctionFallbacks = true;
      const self = this;
      story.onError = function (message, type) {
        self.errors.push({ message: String(message), type: type, turn: self.turn });
      };
      const P = this.psyche;
      const bind = function (name, fn, safe) {
        try { story.BindExternalFunction(name, fn, !!safe); } catch (e) { /* not declared in this story */ }
      };
      bind('seated', function (v) { return P.isSeated(String(v)); }, true);
      bind('tension', function () { return P.tension(); }, true);
      bind('seats_free', function () { return B.Psyche.MAX_SEATS - P.seated.length; }, true);
      bind('seat', function (v) {
        const ok = P.seat(String(v));
        if (ok) self._pending.push({ kind: 'psyche', op: 'seat', voice: String(v) });
        return ok;
      });
      bind('unseat', function (v) {
        const ok = P.unseat(String(v));
        if (ok) self._pending.push({ kind: 'psyche', op: 'unseat', voice: String(v) });
        return ok;
      });
      bind('learn', function (v) { return P.learn(String(v)); });
      bind('bond', function (a, b, sign) {
        const before = P.getRel(String(a), String(b));
        const ok = P.setRel(String(a), String(b), sign);
        if (ok && before !== (sign < 0 ? -1 : 1)) self._pending.push({ kind: 'psyche', op: sign < 0 ? 'rift' : 'bond', a: String(a), b: String(b) });
        return ok;
      });
      return story;
    }

    // ---- lifecycle -------------------------------------------------------

    newGame(seed) {
      this._reset();
      this.errors = [];
      this.seed = (seed >>> 0) || B.Rng.freshSeed();
      this.rng = new B.Rng(this.seed);
      this.story = this._makeStory();
      this.story.state.storySeed = this.seed % 2147483647;
      const start = [];
      for (const id in this.voiceDefs) if (this.voiceDefs[id].start) start.push(id);
      this.psyche.reset(start);
      return this.next();
    }

    serialize() {
      return {
        v: SAVE_VERSION,
        game: 'the-bouncer',
        build: (this.content.meta && this.content.meta.build) || '',
        savedAt: new Date().toISOString(),
        turn: this.turn,
        seed: this.seed,
        ink: this.story.state.toJson(),
        psyche: this.psyche.toJSON(),
        rng: this.rng.getState(),
        barksUsed: this.barksUsed.slice(),
        tasks: B.util.deepClone(this.tasks),
        checks: this.checkHistory.slice(-40),
        screen: this.screen,
        ended: this.ended,
        log: this.log.slice(-SAVE_LOG)
      };
    }

    load(save) {
      if (!save || save.game !== 'the-bouncer' || !save.ink) throw new Error('Not a save from this game');
      this._reset();
      this.errors = [];
      this.story = this._makeStory();
      this.story.state.LoadJson(save.ink);
      this.seed = save.seed >>> 0;
      this.rng = new B.Rng(this.seed);
      this.rng.setState(save.rng);
      this.psyche.fromJSON(save.psyche);
      this.barksUsed = (save.barksUsed || []).slice();
      this.tasks = save.tasks || {};
      this.checkHistory = (save.checks || []).slice();
      this.turn = save.turn | 0;
      this.screen = save.screen || null;
      this.ended = !!save.ended;
      this.log = (save.log || []).slice();
      this.choices = this._readChoices();
      return { items: [], choices: this.choices, ended: this.ended };
    }

    // ---- reading state ---------------------------------------------------

    getVar(name) {
      if (!this.story) return undefined;
      try { return this.story.variablesState[name]; } catch (e) { return undefined; }
    }

    setVar(name, value) {
      try { this.story.variablesState[name] = value; return true; } catch (e) { return false; }
    }

    vars() {
      const out = {};
      if (!this.story) return out;
      const vs = this.story.variablesState;
      const names = vs._globalVariables ? Array.from(vs._globalVariables.keys()) : [];
      for (const n of names) out[n] = inkValue(vs[n]);
      return out;
    }

    status() {
      const g = this.getVar.bind(this);
      const here = inkValue(g('here'));
      return {
        clock: g('clock') | 0,
        clockText: B.util.fmtClock(g('clock') | 0),
        day: g('day') | 0,
        cash: g('cash') | 0,
        drinks: g('drinks') | 0,
        count: g('count_in') | 0,
        hurt: g('hurt') | 0,
        here: Array.isArray(here) ? (here[0] || '') : String(here || ''),
        tension: this.psyche.tension(),
        seated: this.psyche.seated.slice()
      };
    }

    speaker(label) { return this.speakers[label] || null; }

    // ---- flow ------------------------------------------------------------

    next() {
      const items = [];
      const events = [];
      const before = this._watch();
      this._continue(items, events);
      this._afterBatch(before, items, events);
      return this._finish(items);
    }

    choose(visibleIndex) {
      const choice = this.choices.filter(function (c) { return !c.hidden; })[visibleIndex];
      if (!choice) throw new Error('No such choice: ' + visibleIndex);
      return this.chooseChoice(choice);
    }

    chooseChoice(choice) {
      const items = [];
      const events = [];
      const before = this._watch();
      this.turn++;
      items.push({ kind: 'chosen', text: choice.text, check: choice.check ? { voice: choice.check.voice } : null });
      if (choice.check) {
        const c = choice.check;
        const def = this.voiceDefs[c.voice] || {};
        const mods = B.Checks.modifiers(def, { drinks: before.drinks, hurt: this.getVar('hurt') | 0 }, c.mod);
        const r = B.Checks.roll(this.rng, c.target, mods.total, this.psyche.tension());
        const rec = { kind: 'check', voice: c.voice, label: this._label(c.voice), target: c.target, word: B.Checks.difficultyWord(c.target), mods: mods.parts, roll: r, success: r.success, turn: this.turn, clock: before.clock };
        this.checkHistory.push(rec);
        if (this.checkHistory.length > 200) this.checkHistory.shift();
        this.setVar('passed', r.success);
        this.setVar('crit', r.crit ? (r.crit === 'success' ? 1 : -1) : 0);
        items.push(rec);
        events.push({ at: items.length, name: (r.success ? 'check_pass:' : 'check_fail:') + c.voice });
      }
      if (choice.loc) events.push({ at: items.length + 1, name: 'visit:' + choice.loc });
      this.story.ChooseChoiceIndex(choice.inkIndex);
      this._continue(items, events);
      this._afterBatch(before, items, events);
      return this._finish(items);
    }

    jump(path) {
      const items = [];
      const events = [];
      const before = this._watch();
      this.story.ChoosePathString(path);
      this._continue(items, events);
      this._afterBatch(before, items, events);
      return this._finish(items);
    }

    // ---- internals -------------------------------------------------------

    _label(id) {
      const s = this.speakers[String(id).toUpperCase()];
      return s ? (s.def.label || s.def.name || id) : String(id).toUpperCase();
    }

    _watch() {
      return { drinks: this.getVar('drinks') | 0, clock: this.getVar('clock') | 0, tension: this.psyche.tension() };
    }

    _continue(items, events) {
      const story = this.story;
      let guard = 0;
      while (story.canContinue && guard++ < 5000) {
        let text;
        try {
          text = story.Continue();
        } catch (e) {
          this.errors.push({ message: String(e && e.message || e), type: 2, turn: this.turn });
          items.push({ kind: 'line', role: 'system', text: 'Story error: ' + (e && e.message || e) });
          break;
        }
        const tags = (story.currentTags || []).slice();
        // effects raised by external functions during this Continue
        while (this._pending.length) items.push(this._pending.shift());
        this._line(text, tags, items, events);
      }
    }

    _line(rawText, tags, items, events) {
      const parsed = tags.map(B.util.parseTag);
      const tagv = {};
      for (const t of parsed) tagv[t.key] = t.value;

      for (const t of parsed) {
        switch (t.key) {
          case 'sfx': case 'music': case 'amb': case 'portrait': case 'bg':
            items.push({ kind: 'fx', type: t.key, id: String(t.value) });
            break;
          case 'screen':
            this.screen = (t.value === 'none' || t.value === true) ? null : String(t.value);
            items.push({ kind: 'screen', name: this.screen });
            break;
          case 'task': {
            // #task: id :: what the task says
            const s = String(t.value);
            const sep = s.indexOf('::');
            const id = (sep === -1 ? s : s.slice(0, sep)).trim();
            const text = sep === -1 ? id : s.slice(sep + 2).trim();
            this.tasks[id] = { text: text, done: false, turn: this.turn };
            items.push({ kind: 'task', op: 'add', id: id, text: text });
            break;
          }
          case 'done': {
            const id = String(t.value).trim();
            if (this.tasks[id]) this.tasks[id].done = true;
            else this.tasks[id] = { text: id, done: true, turn: this.turn };
            items.push({ kind: 'task', op: 'done', id: id, text: this.tasks[id].text });
            break;
          }
        }
      }

      const text = String(rawText || '').replace(/\s+$/, '');
      if (text.trim()) {
        const item = { kind: 'line', role: 'narration', text: text.trim(), screen: this.screen };
        const m = SPEAKER.exec(item.text);
        if (m) {
          const label = m[1];
          if (label === 'NARRATOR') {
            item.role = 'teller';
            item.text = m[2];
          } else {
            const sp = this.speakers[label];
            if (sp) {
              item.speaker = sp.id;
              item.label = sp.def.label || sp.def.name || sp.id;
              item.role = sp.kind === 'voice' ? 'voice' : 'dialogue';
              item.text = m[2];
              if (sp.kind === 'voice' && !this.psyche.isSeated(sp.id) && !tagv.always) {
                this.suppressed++;
                item.suppressed = true;
              }
            }
          }
        }
        if (tagv.prompt) item.prompt = String(tagv.prompt);
        if (tagv['class']) item.cls = String(tagv['class']);
        if (!item.suppressed) items.push(item);
      }

      if (tagv.bark) events.push({ at: items.length, name: String(tagv.bark) });
      if (tagv.pause) items.push({ kind: 'pause' });
    }

    _afterBatch(before, items, events) {
      const after = this._watch();
      if (after.drinks > before.drinks) events.push({ at: items.length, name: 'drink' });
      if (Math.floor(after.clock / 60) > Math.floor(before.clock / 60)) events.push({ at: items.length, name: 'hour' });
      if (after.tension !== before.tension) events.push({ at: items.length, name: after.tension > before.tension ? 'tension_up' : 'tension_down' });

      // Barks: at most one per event, inserted where the event happened (last first, so indexes hold).
      const getVar = this.getVar.bind(this);
      const picked = [];
      const usedThisBatch = new Set();
      for (const ev of events) {
        const rule = this.barks.pick(ev.name, getVar, this.psyche, this.barksUsed.concat(Array.from(usedThisBatch)), this.rng);
        if (!rule || usedThisBatch.has(rule.speaker)) continue;
        usedThisBatch.add(rule.speaker);
        if (rule.once) this.barksUsed.push(rule.id);
        picked.push({ at: Math.min(ev.at, items.length), item: { kind: 'line', role: 'voice', speaker: rule.speaker, label: this._label(rule.speaker), text: rule.text, bark: rule.id, screen: this.screen } });
      }
      picked.sort(function (a, b) { return b.at - a.at; });
      for (const p of picked) items.splice(p.at, 0, p.item);
      this.psyche.record(after.clock);
    }

    _readChoices() {
      const out = [];
      const list = this.story.currentChoices || [];
      for (let i = 0; i < list.length; i++) {
        const c = list[i];
        const tags = (c.tags || []).map(B.util.parseTag);
        const tv = {};
        for (const t of tags) tv[t.key] = t.value;
        const ch = { inkIndex: c.index, text: String(c.text || '').trim(), loc: tv.loc ? String(tv.loc) : null, cls: tv['class'] ? String(tv['class']) : null, check: null, hidden: false };
        if (tv.check) {
          const spec = B.Checks.parseSpec(tv.check);
          if (spec) {
            const def = this.voiceDefs[spec.voice] || {};
            const mods = B.Checks.modifiers(def, { drinks: this.getVar('drinks') | 0, hurt: this.getVar('hurt') | 0 }, spec.mod);
            const p = B.Checks.odds(spec.target, mods.total, this.psyche.tension());
            ch.check = {
              voice: spec.voice, label: this._label(spec.voice), target: spec.target, mod: spec.mod,
              word: B.Checks.difficultyWord(spec.target), odds: p, oddsWord: B.Checks.oddsWord(p), mods: mods.parts
            };
            if (!this.psyche.isSeated(spec.voice)) ch.hidden = true;
          }
        }
        out.push(ch);
      }
      return out;
    }

    _finish(items) {
      this.choices = this._readChoices();
      if (!this.story.canContinue && this.choices.length === 0) this.ended = true;
      for (const it of items) {
        if (it.kind === 'fx' || it.kind === 'pause') continue;
        this.log.push(it);
      }
      if (this.log.length > LOG_CAP) this.log.splice(0, this.log.length - LOG_CAP);
      return { items: items, choices: this.choices, ended: this.ended };
    }
  }

  Game.SAVE_VERSION = SAVE_VERSION;
  Game.inkValue = inkValue;
  B.Game = Game;
})(globalThis.Bouncer = globalThis.Bouncer || {});
