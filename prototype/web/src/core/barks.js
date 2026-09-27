// Rule-matched lines ("barks"), after Valve's dialogue system: many short lines, each tied to
// facts about the world, where the most specific match wins. Authored in content/rules/barks.yaml.
//
// A rule:
//   id: pool_left_hand
//   on: visit:pool            # the event that offers it (see Game for the event names)
//   speaker: fighter          # a voice id; voices only speak from the room
//   when:                     # every criterion must hold; more criteria = more specific
//     - pool_heat >= 3
//     - knows has pool_lefty
//     - seated fighter
//   text: Left hand's flat on the rail. That's where it comes from.
//   once: true                # default true
//   mark: pool.lefthand       # optional: the voice marks that spot on the picture (content/data/marks.yaml)
//
// Criteria forms:  <var> <op> <number|true|false|word>   (op: >= <= > < == !=)
//                  <var> has <item>   /   <var> hasnt <item>      (Ink LIST membership)
//                  seated <voice>     /   unseated <voice>
//                  ally <voice>       /   odds <voice>     (how the speaker gets on with that voice now)
//                  tension <op> <n>
//
// The hand: rules with `on: hand:<kind>` are what the voices say to the player while a hand is
// on a choice, and when they notice the player (Game.whisper, Game.murmur). They're said whatever
// the tension, and each once a night.
//
// Toys: rules with `on: toy:<thing>:<what>` answer the player handling a thing between choices
// (Game.toy): an idle click on the clicker, a card turned over. No chance gate here either: the
// when: says exactly when a voice speaks up.
//
// Answers: after a voice barks, the others may answer it. A rule with `on: answer:father` is
// offered right after THE FATHER says something; its speaker has to be someone else in the room.
// Allies back each other up and voices at odds contradict, so the relationships in his head
// (bible/02_SYSTEMS.md) can be heard, and the louder the room, the more they argue.
(function (B) {
  'use strict';

  const CRIT = /^\s*([a-z_][a-z0-9_]*)\s*(>=|<=|==|!=|>|<|has|hasnt)\s*([a-z0-9_.\-]+)\s*$/i;
  const SEAT = /^\s*(seated|unseated|ally|odds)\s+([a-z_][a-z0-9_]*)\s*$/i;

  function parseCriterion(s) {
    let m = SEAT.exec(s);
    if (m) return { kind: m[1].toLowerCase(), voice: m[2].toLowerCase(), src: s };
    m = CRIT.exec(s);
    if (!m) return { kind: 'bad', src: s };
    let val = m[3];
    if (/^-?\d+(\.\d+)?$/.test(val)) val = parseFloat(val);
    else if (val === 'true') val = true;
    else if (val === 'false') val = false;
    return { kind: 'cmp', name: m[1], op: m[2].toLowerCase(), value: val, src: s };
  }

  function compile(rules) {
    return (rules || []).map(function (r, i) {
      const when = (r.when || []).map(parseCriterion);
      return {
        id: r.id || ('bark_' + i),
        on: r.on,
        speaker: String(r.speaker || '').toLowerCase(),
        text: r.text,
        when: when,
        once: r.once !== false,
        always: !!r.always,
        mark: r.mark ? String(r.mark) : null,
        specificity: when.length
      };
    });
  }

  function listHas(v, item) {
    if (v == null) return false;
    if (typeof v.ContainsItemNamed === 'function') return v.ContainsItemNamed(item);
    if (Array.isArray(v)) return v.indexOf(item) !== -1;
    return String(v) === item;
  }

  function test(c, getVar, psyche, speaker) {
    if (c.kind === 'seated') return psyche.isSeated(c.voice);
    if (c.kind === 'unseated') return !psyche.isSeated(c.voice);
    if (c.kind === 'ally' || c.kind === 'odds') {
      if (!psyche.isSeated(c.voice) || c.voice === speaker) return false;
      const rel = psyche.getRel(speaker, c.voice);
      return c.kind === 'ally' ? rel > 0 : rel < 0;
    }
    if (c.kind !== 'cmp') return false;
    const v = c.name === 'tension' ? psyche.tension() : getVar(c.name);
    switch (c.op) {
      case 'has': return listHas(v, c.value);
      case 'hasnt': return !listHas(v, c.value);
      case '==': return v == c.value || String(v) === String(c.value); // eslint-disable-line eqeqeq
      case '!=': return !(v == c.value || String(v) === String(c.value)); // eslint-disable-line eqeqeq
      case '>=': return Number(v) >= c.value;
      case '<=': return Number(v) <= c.value;
      case '>': return Number(v) > c.value;
      case '<': return Number(v) < c.value;
    }
    return false;
  }

  // Chance that a voice speaks up at all, by tension. At 0 the room is quiet.
  const CHANCE = [0, 0.45, 0.65, 0.85, 1];

  class Barks {
    constructor(rules) { this.rules = compile(rules); }

    // not: a voice that may not speak (the one being answered)
    candidates(event, getVar, psyche, used, not) {
      return this.rules.filter(function (r) {
        if (r.on !== event) return false;
        if (r.once && used.indexOf(r.id) !== -1) return false;
        if (!psyche.isSeated(r.speaker) || r.speaker === not) return false;
        for (const c of r.when) if (!test(c, getVar, psyche, r.speaker)) return false;
        return true;
      });
    }

    // The most specific rule that holds, whatever the noise in his head (the hand's lines use it:
    // a voice that's leaning in on a choice always gets a word in).
    best(event, getVar, psyche, used, rng, not) {
      const cands = this.candidates(event, getVar, psyche, used, not);
      if (!cands.length) return null;
      let top = -1;
      for (const r of cands) if (r.specificity > top) top = r.specificity;
      return rng.pick(cands.filter(function (r) { return r.specificity === top; }));
    }

    pick(event, getVar, psyche, used, rng, not) {
      const rule = this.best(event, getVar, psyche, used, rng, not);
      if (!rule) return null;
      if (!rule.always) {
        const t = Math.min(4, psyche.tension());
        if (rng.next() >= CHANCE[t]) return null;
      }
      return rule;
    }

    // Criteria that reference variables, for the build-time validator.
    variables() {
      const out = new Set();
      for (const r of this.rules) for (const c of r.when) if (c.kind === 'cmp' && c.name !== 'tension') out.add(c.name);
      return Array.from(out);
    }

    badCriteria() {
      const out = [];
      for (const r of this.rules) for (const c of r.when) if (c.kind === 'bad') out.push(r.id + ': ' + c.src);
      return out;
    }
  }

  // The word on him: what a group says about him when something he's done lands with them, by its
  // own code (bible/02_SYSTEMS.md). Authored in content/rules/word.yaml.
  //
  // A rule:
  //   id: t28_down_first
  //   group: t28               # t28 | kids | staff | owner | cook (the rep_ variable it follows)
  //   way: down                # up or down
  //   when: [by >= 2]          # the same criteria as barks, plus two of its own:
  //                            #   by   how far this act moved them (1 to 5)
  //                            #   now  where he stands with them after it (-5 to 5)
  //   text: He won't last.
  //   once: true               # default true; a line with once: false can come round again
  //
  // The most specific rule that holds wins, a rule that has already been said is passed over, and
  // when every line for a group has been said, the ones marked once: false come round again.
  class Word {
    // spec: { groups: {t28: 'Table 28', ...}, lines: [rule, ...] }
    constructor(spec) {
      spec = spec || {};
      this.names = spec.groups || {};
      this.rules = (spec.lines || []).map(function (r, i) {
        const when = (r.when || []).map(parseCriterion);
        return { id: r.id || ('word_' + i), group: String(r.group || ''), way: String(r.way || ''), text: r.text, when: when, once: r.once !== false, specificity: when.length };
      });
    }

    groups() {
      const out = new Set(Object.keys(this.names));
      for (const r of this.rules) out.add(r.group);
      return Array.from(out);
    }

    name(group) { return this.names[group] || group; }

    byId(id) {
      for (const r of this.rules) if (r.id === id) return r;
      return null;
    }

    pick(group, way, by, now, getVar, psyche, used, rng) {
      const vars = function (name) { return name === 'by' ? by : name === 'now' ? now : getVar(name); };
      const cands = this.rules.filter(function (r) {
        if (r.group !== group || r.way !== way) return false;
        if (r.once && used.indexOf(r.id) !== -1) return false;
        for (const c of r.when) if (!test(c, vars, psyche, '')) return false;
        return true;
      });
      if (!cands.length) return null;
      // Lines not yet said tonight first, the most specific of them, and a one-off before a line
      // that can come round again; a repeatable line that's been said waits until nothing else is left.
      const fresh = cands.filter(function (r) { return used.indexOf(r.id) === -1; });
      const pool = fresh.length ? fresh : cands;
      const rank = function (r) { return r.specificity * 2 + (r.once ? 1 : 0); };
      let top = -1;
      for (const r of pool) if (rank(r) > top) top = rank(r);
      return rng.pick(pool.filter(function (r) { return rank(r) === top; }));
    }

    variables() {
      const out = new Set();
      for (const r of this.rules) for (const c of r.when) if (c.kind === 'cmp' && c.name !== 'tension' && c.name !== 'by' && c.name !== 'now') out.add(c.name);
      return Array.from(out);
    }

    badCriteria() {
      const out = [];
      for (const r of this.rules) for (const c of r.when) if (c.kind === 'bad') out.push(r.id + ': ' + c.src);
      return out;
    }
  }

  B.Barks = Barks;
  B.Word = Word;
})(globalThis.Bouncer = globalThis.Bouncer || {});
