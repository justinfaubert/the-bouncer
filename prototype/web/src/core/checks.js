// Checks. A voice lends him its way of seeing, he brings one of his stats to it, and he rolls two
// dice.
//
// What moves the odds:
//   - the stat the check is rolled on, added to the dice: his seven, 1 to 10 (DECIDED), set by what
//     he says in Gary's office (content/ink/office.ink). The check names it ("#check: father:wis 12")
//     or it's the voice's first (voices.yaml `stats`). An ordinary man's is 4, so a target of 12
//     is what 8 was before the stats.
//   - the voice's base (how reliable its source is), from content/data/voices.yaml
//   - drink: each voice reacts differently to how much he's had (voices.yaml `drink`), counted as
//     the drinks that show: his Constitution holds some, and so does a meal (felt, below)
//   - hurt, for voices marked physical
//   - nothing to eat before the shift: -1 to the body's checks (Strength, Constitution, Dexterity)
//     and +1 to Gut Brain's, which hunger sharpens
//   - a situational modifier written into the choice's tag in the Ink ("#check: father:cha 12 {bonus}")
//   - tension in the room, which changes volatility, not the average (bible/02_SYSTEMS.md):
//     the dice's distance from 7 is stretched, so hard checks get likelier and easy ones
//     get riskier as the room gets louder.
// Double one always fails and double six always succeeds, as in Disco Elysium.
(function (B) {
  'use strict';

  const WORDS = [
    [9, 'Trivial'], [11, 'Easy'], [13, 'Medium'], [15, 'Hard'], [17, 'Very hard'], [99, 'Near impossible']
  ];

  // His seven stats: the Ink's VAR for each (content/ink/main.ink), and its name on a check.
  const STATS = {
    str: { v: 'stat_str', label: 'Strength' },
    con: { v: 'stat_con', label: 'Constitution' },
    dex: { v: 'stat_dex', label: 'Dexterity' },
    int: { v: 'stat_int', label: 'Intelligence' },
    wis: { v: 'stat_wis', label: 'Wisdom' },
    cha: { v: 'stat_cha', label: 'Charisma' },
    gut: { v: 'stat_gut', label: 'Gut Brain' }
  };
  const STAT_ORDER = ['str', 'con', 'dex', 'int', 'wis', 'cha', 'gut'];

  // all seven, read from the story: get(name) -> its value
  function readStats(get) {
    const out = {};
    for (const k of STAT_ORDER) out[k] = get(STATS[k].v) | 0;
    return out;
  }

  // the stat a check is rolled on: the one it names, or the voice's first
  function statOf(voiceDef, stat) {
    if (stat && STATS[stat]) return stat;
    const list = voiceDef && Array.isArray(voiceDef.stats) ? voiceDef.stats : [];
    return list.length && STATS[list[0]] ? list[0] : '';
  }

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

  // The drinks that show. Constitution holds some of them, none at 3 or 4, one at 5 or 6, two at 7
  // or 8, three at 9 or 10, and at 1 or 2 he feels one more than he's had; a meal before the shift
  // holds one more (ate: 1 he ate, -1 he didn't, 0 nobody asked).
  function felt(drinks, stats, ate) {
    drinks = Math.max(0, drinks | 0);
    if (!drinks) return 0;
    const con = ((stats && stats.con) | 0) || 4;
    const holds = Math.floor((con - 3) / 2) + ((ate | 0) > 0 ? 1 : 0);
    return Math.max(0, drinks - holds);
  }

  function drinksLabel(drinks, f) {
    if (!drinks) return 'sober';
    const n = drinks === 1 ? '1 drink' : drinks + ' drinks';
    return f === drinks ? n : n + ' (feels like ' + (f || 'none') + ')';
  }

  // Everything that feeds a check besides the dice. ctx: {drinks, hurt, stats: readStats(), ate}
  function modifiers(voiceDef, ctx, tagMod, stat) {
    const parts = [];
    const st = statOf(voiceDef, stat);
    if (st) parts.push({ label: STATS[st].label, value: (ctx.stats && ctx.stats[st]) | 0, stat: st });
    const base = (voiceDef && voiceDef.base) | 0;
    if (base) parts.push({ label: 'source', value: base });
    const drinks = Math.max(0, ctx.drinks | 0);
    if (voiceDef && Array.isArray(voiceDef.drink) && voiceDef.drink.length) {
      const f = felt(drinks, ctx.stats, ctx.ate);
      const d = voiceDef.drink[Math.min(f, voiceDef.drink.length - 1)] | 0;
      if (d) parts.push({ label: drinksLabel(drinks, f), value: d });
    }
    if (voiceDef && voiceDef.physical && ctx.hurt) parts.push({ label: 'hurt', value: -(ctx.hurt | 0) });
    // hunger sharpens his gut and costs his body (bible/11_SKELETON.md, Him: seven stats)
    if ((ctx.ate | 0) < 0 && st) {
      if (st === 'gut') parts.push({ label: 'nothing to eat', value: 1 });
      else if (st === 'str' || st === 'con' || st === 'dex') parts.push({ label: 'nothing to eat', value: -1 });
    }
    if (tagMod) parts.push({ label: 'situation', value: tagMod | 0 });
    let total = 0;
    for (const p of parts) total += p.value;
    return { total: total, parts: parts };
  }

  // "#check: father:wis 12 2" -> {voice:'father', stat:'wis', target:12, mod:2}; the stat can be left out
  function parseSpec(value) {
    const bits = String(value).trim().split(/\s+/);
    if (!bits[0]) return null;
    const vs = bits[0].toLowerCase().split(':');
    const target = parseInt(bits[1], 10);
    const mod = bits.length > 2 ? parseInt(bits[2], 10) : 0;
    return { voice: vs[0], stat: STATS[vs[1]] ? vs[1] : '', target: isNaN(target) ? 12 : target, mod: isNaN(mod) ? 0 : mod };
  }

  B.Checks = {
    STATS: STATS,
    STAT_ORDER: STAT_ORDER,
    readStats: readStats,
    statOf: statOf,
    felt: felt,
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
