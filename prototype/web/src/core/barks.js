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
//
// Criteria forms:  <var> <op> <number|true|false|word>   (op: >= <= > < == !=)
//                  <var> has <item>   /   <var> hasnt <item>      (Ink LIST membership)
//                  seated <voice>     /   unseated <voice>
//                  ally <voice>       /   odds <voice>     (how the speaker gets on with that voice now)
//                  tension <op> <n>
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

    pick(event, getVar, psyche, used, rng, not) {
      const cands = this.candidates(event, getVar, psyche, used, not);
      if (!cands.length) return null;
      let top = -1;
      for (const r of cands) if (r.specificity > top) top = r.specificity;
      const best = cands.filter(function (r) { return r.specificity === top; });
      const rule = rng.pick(best);
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

  B.Barks = Barks;
})(globalThis.Bouncer = globalThis.Bouncer || {});
