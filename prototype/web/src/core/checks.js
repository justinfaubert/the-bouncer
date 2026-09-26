// Checks. A voice lends him its way of seeing, and he rolls two dice.
//
// There are no skill levels. What moves the odds:
//   - the voice's base (how reliable its source is), from content/data/voices.yaml
//   - drink: each voice reacts differently to how much he's had (voices.yaml `drink`)
//   - hurt, for voices marked physical
//   - a situational modifier written into the choice's tag in the Ink ("#check: father 8 {bonus}")
//   - tension in the room, which changes volatility, not the average (bible/02_SYSTEMS.md):
//     the dice's distance from 7 is stretched, so hard checks get likelier and easy ones
//     get riskier as the room gets louder.
// Double one always fails and double six always succeeds, as in Disco Elysium.
(function (B) {
  'use strict';

  const WORDS = [
    [5, 'Trivial'], [7, 'Easy'], [9, 'Medium'], [11, 'Hard'], [13, 'Very hard'], [99, 'Near impossible']
  ];

  function difficultyWord(target) {
    for (const w of WORDS) if (target <= w[0]) return w[1];
    return 'Near impossible';
  }

  function volatility(tension) { return 1 + 0.35 * Math.max(0, tension | 0); }

  function scaled(d1, d2, tension) {
    return 7 + Math.round((d1 + d2 - 7) * volatility(tension));
  }

  function resolve(d1, d2, target, mod, tension) {
    const natural = d1 + d2;
    const total = scaled(d1, d2, tension) + mod;
    let success = total >= target;
    let crit = null;
    if (natural === 2) { success = false; crit = 'fail'; }
    if (natural === 12) { success = true; crit = 'success'; }
    return { d1: d1, d2: d2, natural: natural, total: total, target: target, mod: mod, tension: tension, success: success, crit: crit };
  }

  function odds(target, mod, tension) {
    let wins = 0;
    for (let a = 1; a <= 6; a++) for (let b = 1; b <= 6; b++) if (resolve(a, b, target, mod, tension).success) wins++;
    return wins / 36;
  }

  function oddsWord(p) {
    if (p >= 0.97) return 'certain';
    if (p >= 0.8) return 'near certain';
    if (p >= 0.62) return 'likely';
    if (p >= 0.42) return 'even';
    if (p >= 0.25) return 'unlikely';
    if (p >= 0.1) return 'long shot';
    return 'hopeless';
  }

  // Everything that feeds a check besides the dice.
  function modifiers(voiceDef, ctx, tagMod) {
    const parts = [];
    const base = (voiceDef && voiceDef.base) | 0;
    if (base) parts.push({ label: 'source', value: base });
    const drinks = Math.max(0, ctx.drinks | 0);
    if (voiceDef && Array.isArray(voiceDef.drink) && voiceDef.drink.length) {
      const d = voiceDef.drink[Math.min(drinks, voiceDef.drink.length - 1)] | 0;
      if (d) parts.push({ label: drinks === 1 ? '1 drink' : drinks + ' drinks', value: d });
    }
    if (voiceDef && voiceDef.physical && ctx.hurt) parts.push({ label: 'hurt', value: -(ctx.hurt | 0) });
    if (tagMod) parts.push({ label: 'situation', value: tagMod | 0 });
    let total = 0;
    for (const p of parts) total += p.value;
    return { total: total, parts: parts };
  }

  // "#check: father 8 2" -> {voice:'father', target:8, mod:2}
  function parseSpec(value) {
    const bits = String(value).trim().split(/\s+/);
    if (!bits[0]) return null;
    const target = parseInt(bits[1], 10);
    const mod = bits.length > 2 ? parseInt(bits[2], 10) : 0;
    return { voice: bits[0].toLowerCase(), target: isNaN(target) ? 8 : target, mod: isNaN(mod) ? 0 : mod };
  }

  B.Checks = {
    difficultyWord: difficultyWord,
    volatility: volatility,
    resolve: resolve,
    odds: odds,
    oddsWord: oddsWord,
    modifiers: modifiers,
    parseSpec: parseSpec,
    roll: function (rng, target, mod, tension) { return resolve(rng.d6(), rng.d6(), target, mod, tension); }
  };
})(globalThis.Bouncer = globalThis.Bouncer || {});
