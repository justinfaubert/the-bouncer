// The game runtime. It drives the Ink story and turns its output into items the UI draws:
// lines (narration, the teller, dialogue, voices), check results, sound and art cues, tasks.
// No DOM here: the same class runs the browser build and the playthrough bots in Node.
//
// Conventions the Ink follows (full list in content/ink/README.md):
//   FATHER: text          a line spoken by the voice or character with that id
//   NARRATOR: text        the teller, years later
//   #check: father 8 {n}  on a choice: a check lent by that voice, target 8, situational modifier n
//   #loc: pool            on a choice: where it happens (lights up that spot on the floor sketch)
//   #room: -fighter +kid  on a choice: who it puts out of his head and lets in (the page previews it)
//   #sfx / #music / #amb / #portrait / #screen / #task / #done / #bark / #pause / #prompt / #always
//
// Every line item carries `raw` (the line exactly as the Ink printed it, speaker label and all)
// and `knot` (the part of the Ink it came from), so the director's edits (src/core/director.js)
// can find it again. After a choice, a {kind:'diff'} item lists the story variables it changed.
// When he moves, a {kind:'place'} item marks where the new place starts, with what a plate of it
// would show at that moment (_plateState). When something he does lands with one of the groups
// that judge him (rep_t28, rep_kids ...), a {kind:'word'} item follows the line it happened on:
// what they'll say about him (content/rules/word.yaml).
//
// The sketch: what he last saw of the room and the doors, and when (see _see). The floor sketch
// draws from it, so what he hasn't looked at in a while goes stale on the page.
(function (B) {
  'use strict';

  const SPEAKER = /^([A-Z][A-Z0-9_]*):\s+([\s\S]*)$/;
  const LOG_CAP = 1500;
  const SAVE_LOG = 80;
  const SAVE_VERSION = 1;
  const ROOM = { door: true, floor: true, bar: true, t28: true, pool: true };   // one room: seen from anywhere in it
  const GROUPS = ['t28', 'kids', 'staff', 'owner', 'cook'];                       // rep_<group> in main.ink

  // "door_hoodie.read.0.c-1" -> "door_hoodie"; top-level content ("0") -> ""
  function knotOf(p) {
    const k = String(p || '').split('.')[0];
    return /^\d*$/.test(k) ? '' : k;
  }

  // What a choice changed: scalars as {name, from, to}; lists as {name, add, del}.
  function diffVars(a, b) {
    const out = [];
    const names = Object.keys(b);
    for (const n of Object.keys(a)) if (!(n in b)) names.push(n);
    for (const n of names) {
      const x = a[n], y = b[n];
      if (Array.isArray(x) || Array.isArray(y)) {
        const xa = Array.isArray(x) ? x : [], ya = Array.isArray(y) ? y : [];
        const add = ya.filter(function (v) { return xa.indexOf(v) === -1; });
        const del = xa.filter(function (v) { return ya.indexOf(v) === -1; });
        if (add.length || del.length) out.push({ name: n, add: add, del: del });
      } else if (x !== y) {
        out.push({ name: n, from: x, to: y });
      }
    }
    return out;
  }

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
      this.word = new B.Word(content.word || {});
      this.psyche = new B.Psyche(this.voiceDefs, content.psyche);
      this.rng = new B.Rng(1);
      this.story = null;
      this.errors = [];
      this._reset();
    }

    _reset() {
      this.log = [];
      this.path = [];         // every choice made tonight: {t: turn, c: clock, x: text, k: check}
      this.tasks = {};
      this.checkHistory = [];
      this.barksUsed = [];
      this.wordUsed = [];
      this.taught = [];       // what THE MANUAL has explained (teach:<what> in barks.yaml)
      this.turn = 0;
      this.screen = null;
      this.ended = false;
      this.choices = [];
      this.suppressed = 0;
      this._pending = [];
      this.seed = 0;
      this.sketch = {};
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
        wordUsed: this.wordUsed.slice(),
        taught: this.taught.slice(),
        tasks: B.util.deepClone(this.tasks),
        checks: this.checkHistory.slice(-40),
        screen: this.screen,
        ended: this.ended,
        log: this.log.slice(-SAVE_LOG),
        path: this.path.slice(),
        sketch: B.util.deepClone(this.sketch)
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
      this.wordUsed = (save.wordUsed || []).slice();
      this.taught = (save.taught || ['check', 'tension', 'word', 'room']).slice();
      this.tasks = save.tasks || {};
      this.checkHistory = (save.checks || []).slice();
      this.turn = save.turn | 0;
      this.screen = save.screen || null;
      this.ended = !!save.ended;
      this.log = (save.log || []).slice();
      this.path = (save.path || []).slice();
      this.sketch = save.sketch || {};
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

    here() {
      const h = inkValue(this.getVar('here'));
      return Array.isArray(h) ? (h[0] || '') : String(h || '');
    }

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
      const varsBefore = this.vars();
      this.turn++;
      items.push({ kind: 'chosen', text: choice.text, knot: choice.knot || '', check: choice.check ? { voice: choice.check.voice } : null });
      const step = { t: this.turn, c: before.clock, x: choice.text };
      this.path.push(step);
      if (choice.check) {
        const c = choice.check;
        const def = this.voiceDefs[c.voice] || {};
        const mods = B.Checks.modifiers(def, { drinks: before.drinks, hurt: this.getVar('hurt') | 0 }, c.mod);
        const r = B.Checks.roll(this.rng, c.target, mods.total, this.psyche.tension());
        const rec = { kind: 'check', voice: c.voice, label: this._label(c.voice), target: c.target, word: B.Checks.difficultyWord(c.target), mods: mods.parts, roll: r, success: r.success, turn: this.turn, clock: before.clock };
        this.checkHistory.push(rec);
        if (this.checkHistory.length > 200) this.checkHistory.shift();
        step.k = { v: c.voice, n: r.total, of: c.target, ok: r.success };
        this.setVar('passed', r.success);
        this.setVar('crit', r.crit ? (r.crit === 'success' ? 1 : -1) : 0);
        items.push(rec);
        // after the first line of the outcome, so the voice answers what happened
        events.push({ at: items.length + 1, name: (r.success ? 'check_pass:' : 'check_fail:') + c.voice });
      }
      // once he's there: after the place has been described
      if (choice.loc) events.push({ at: Infinity, name: 'visit:' + choice.loc });
      this.story.ChooseChoiceIndex(choice.inkIndex);
      this._continue(items, events);
      this._afterBatch(before, items, events);
      const changes = diffVars(varsBefore, this.vars());
      if (changes.length) items.push({ kind: 'diff', turn: this.turn, changes: changes });
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
        let from = '';
        try { from = story.state.currentPathString || ''; } catch (e) { from = ''; }
        const wasHere = this.here();
        const stood = this._standing();
        try {
          text = story.Continue();
        } catch (e) {
          this.errors.push({ message: String(e && e.message || e), type: 2, turn: this.turn });
          items.push({ kind: 'line', role: 'system', text: 'Story error: ' + (e && e.message || e) });
          break;
        }
        const tags = (story.currentTags || []).slice();
        // Where the line came from. The path before Continue can sit on a divert into another
        // knot, and the last pointer after it can have run on past the line, so keep both.
        let last = '';
        try { const pp = story.state.previousPointer; last = pp && !pp.isNull && pp.path ? pp.path.toString() : ''; } catch (e) { last = ''; }
        const at = items.length;
        // effects raised by external functions during this Continue
        while (this._pending.length) items.push(this._pending.shift());
        const nowHere = this.here();
        if (nowHere !== wasHere) items.push({ kind: 'place', here: nowHere, from: wasHere, clock: this.getVar('clock') | 0, state: this._plateState() });
        this._line(text, tags, items, events, from, last);
        // What people will say about what he's just done goes under the line that shows it. The Ink
        // sets it just before or after the narration, and runs the logic after a line on its way to
        // the next one, so it usually goes under this line. But when there's more to come, Ink has
        // stopped at the end of this line, and the last pointer says where the line came from: if
        // that's somewhere else (back on the floor, the room, something across it), the change
        // belongs to the scene before, and it goes in above.
        const said = this._word(stood);
        if (said.length) {
          let line = null;
          for (let k = at; k < items.length; k++) if (items[k].kind === 'line') { line = items[k]; break; }
          const origin = line ? (line.knot2 || line.knot || '') : '';
          const above = story.canContinue && line && origin && knotOf(from) && origin !== knotOf(from);
          const i = above ? at : items.length;
          items.splice.apply(items, [i, 0].concat(said));
          for (const ev of events) if (ev.at > i && ev.at !== Infinity) ev.at += said.length;
        }
      }
    }

    _barkItem(rule, answer) {
      return { kind: 'line', role: 'voice', speaker: rule.speaker, label: this._label(rule.speaker), text: rule.text, raw: rule.speaker.toUpperCase() + ': ' + rule.text, knot: '', bark: rule.id, answer: answer || undefined, screen: this.screen };
    }

    // The first time a part of the game comes up, THE MANUAL explains it, once: a check on offer, the
    // noise in his head changing, a group's word on him, a choice that changes who's in his head.
    // Only from the room: if the Manual's been put out, it waits until he's back.
    _teach(what, items, at) {
      if (this.taught.indexOf(what) !== -1) return false;
      const rule = this.barks.pick('teach:' + what, this.getVar.bind(this), this.psyche, this.barksUsed, this.rng);
      if (!rule) return false;
      this.taught.push(what);
      if (rule.once) this.barksUsed.push(rule.id);
      items.splice(Math.min(at, items.length), 0, this._barkItem(rule));
      return true;
    }

    // How the person in a portrait looks at him: warm once he stands well with their group, cold
    // once he's in their bad books (characters.yaml, standing).
    _lean(portrait) {
      for (const id in this.charDefs) {
        const d = this.charDefs[id];
        if (d.portrait !== portrait || !d.standing) continue;
        const v = this.getVar('rep_' + d.standing) | 0;
        return v >= 2 ? 'warm' : v <= -2 ? 'cold' : '';
      }
      return '';
    }

    // where he stands with each group that judges him, -5 .. 5
    _standing() {
      const out = {};
      for (const g of GROUPS) out[g] = this.getVar('rep_' + g) | 0;
      return out;
    }

    // What he's just done has landed with someone: what they'll say about him.
    _word(before) {
      const now = this._standing();
      const getVar = this.getVar.bind(this);
      const out = [];
      for (const g of GROUPS) {
        const d = now[g] - before[g];
        if (!d) continue;
        const way = d > 0 ? 'up' : 'down';
        const rule = this.word.pick(g, way, Math.abs(d), now[g], getVar, this.psyche, this.wordUsed, this.rng);
        out.push({ kind: 'word', group: g, who: this.word.name(g), way: way, by: Math.abs(d), text: rule ? rule.text : '', id: rule ? rule.id : '', turn: this.turn, screen: this.screen });
        if (rule) this.wordUsed.push(rule.id);
      }
      return out;
    }

    _line(rawText, tags, items, events, from, last) {
      const parsed = tags.map(B.util.parseTag);
      const tagv = {};
      for (const t of parsed) tagv[t.key] = t.value;

      for (const t of parsed) {
        switch (t.key) {
          case 'sfx': case 'music': case 'amb': case 'bg':
            items.push({ kind: 'fx', type: t.key, id: String(t.value) });
            break;
          case 'portrait':
            items.push({ kind: 'fx', type: t.key, id: String(t.value), lean: this._lean(String(t.value)) });
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
        const item = { kind: 'line', role: 'narration', text: text.trim(), raw: text.trim(), screen: this.screen };
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
        item.knot = knotOf(from) || knotOf(last);
        const k2 = knotOf(last);
        if (k2 && k2 !== item.knot) item.knot2 = k2;
        if (from) item.at = from;
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
      // the first time the room in his head changes, and the first time someone's word on him comes
      // up, THE MANUAL explains (it goes in ahead of the other voices)
      if (after.tension !== before.tension) this._teach('tension', items, items.length);
      if (this.taught.indexOf('word') === -1) {
        for (let i = items.length - 1; i >= 0; i--) {
          if (items[i].kind !== 'word' || !items[i].text) continue;
          if (this._teach('word', items, i + 1)) for (const ev of events) if (ev.at > i + 1 && ev.at !== Infinity) ev.at++;
          break;
        }
      }

      // Barks: at most one per event, inserted where the event happened (last first, so indexes hold).
      // After each, another voice in the room may answer it.
      const getVar = this.getVar.bind(this);
      const picked = [];
      const usedThisBatch = new Set();
      const barkItem = (rule, answer) => this._barkItem(rule, answer);
      for (const ev of events) {
        const rule = this.barks.pick(ev.name, getVar, this.psyche, this.barksUsed, this.rng);
        if (!rule || usedThisBatch.has(rule.speaker)) continue;
        usedThisBatch.add(rule.speaker);
        if (rule.once) this.barksUsed.push(rule.id);
        const said = [barkItem(rule)];
        const reply = this.barks.pick('answer:' + rule.speaker, getVar, this.psyche, this.barksUsed, this.rng, rule.speaker);
        if (reply && !usedThisBatch.has(reply.speaker)) {
          usedThisBatch.add(reply.speaker);
          if (reply.once) this.barksUsed.push(reply.id);
          said.push(barkItem(reply, rule.speaker));
        }
        picked.push({ at: Math.min(ev.at, items.length), said: said });
      }
      picked.sort(function (a, b) { return b.at - a.at; });
      for (const p of picked) items.splice.apply(items, [p.at, 0].concat(p.said));
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
        const ch = { inkIndex: c.index, text: String(c.text || '').trim(), knot: knotOf(c.sourcePath), loc: tv.loc ? String(tv.loc) : null, cls: tv['class'] ? String(tv['class']) : null, check: null, hidden: false };
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
        // "#room: -fighter +table": who this choice lets in or puts out of his head, so the page
        // can show what the room would sound like after
        if (tv.room) {
          const next = this.psyche.seated.slice();
          for (const op of String(tv.room).split(/\s+/)) {
            const v = op.slice(1).toLowerCase();
            if (op[0] === '+' && v && next.indexOf(v) === -1) next.push(v);
            if (op[0] === '-') { const at = next.indexOf(v); if (at !== -1) next.splice(at, 1); }
          }
          ch.room = { seated: next, now: this.psyche.tension(), full: next.length > B.Psyche.MAX_SEATS };
          ch.room.tension = ch.room.full ? null : this.psyche.tension(next);
        }
        out.push(ch);
      }
      return out;
    }

    // What a plate of the place he's walked into can show (src/ui/plates.js): how full the room is,
    // table 28's rounds, the pool table's heat, the rats, which doors are propped.
    _plateState() {
      const g = this.getVar.bind(this);
      return {
        n: g('room_count') | 0, rounds: g('t28_rounds') | 0, heat: g('pool_heat') | 0, rats: g('rat_count') | 0,
        deck: !!g('deck_door'), kitchen: !!g('kitchen_door'), hotel: !!g('hotel_door'), walter: g('walter') | 0, clock: g('clock') | 0
      };
    }

    // What he can see from where he is goes into the sketch, with the time he saw it.
    // Anywhere in the bar he sees the whole room; the doors he sees only when he's at them.
    _see() {
      const g = this.getVar.bind(this);
      const here = this.here();
      const c = g('clock') | 0;
      const S = this.sketch;
      if (ROOM[here]) {
        S.room = c;
        S.pool = { heat: g('pool_heat') | 0, at: c };
        S.t28 = { rounds: g('t28_rounds') | 0, at: c };
      }
      if (here === 'door') S.door = c;
      if (here === 'deck') S.deck = { open: !!g('deck_door'), at: c };
      if (here === 'kitchen') S.kitchen = { open: !!g('kitchen_door'), at: c };
      if (here === 'hall') S.hotel = { open: !!g('hotel_door'), at: c };
      const lc = g('last_count') | 0;
      if (lc && (!S.count || S.count.at !== lc)) S.count = { n: g('room_count') | 0, at: lc };
    }

    _finish(items) {
      this._see();
      this.choices = this._readChoices();
      const shown = this.choices.filter(function (c) { return !c.hidden; });
      if (shown.some(function (c) { return c.check; })) this._teach('check', items, items.length);
      if (shown.some(function (c) { return c.room; })) this._teach('room', items, items.length);
      if (!this.story.canContinue && this.choices.length === 0) this.ended = true;
      for (const it of items) {
        if (it.kind === 'fx' || it.kind === 'pause') continue;
        this.log.push(it);
      }
      // (place items are logged too: the page draws the place's plate from them on a redraw)
      if (this.log.length > LOG_CAP) this.log.splice(0, this.log.length - LOG_CAP);
      return { items: items, choices: this.choices, ended: this.ended };
    }
  }

  Game.SAVE_VERSION = SAVE_VERSION;
  Game.inkValue = inkValue;
  Game.knotOf = knotOf;
  Game.diffVars = diffVars;
  B.Game = Game;
})(globalThis.Bouncer = globalThis.Bouncer || {});
