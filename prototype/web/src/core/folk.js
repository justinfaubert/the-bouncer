// The town's people, made once a game from its seed (bible/11_SKELETON.md, "The door, busier: the
// town"). Folk.make(seed, content) puts the first hundred adults, and the teenagers who live with
// them, on the town's fixed streets (content/data/town.yaml) from what content/data/people.yaml
// says they're made of: households, names, birthdays, work, how they drink, how often they're at
// the Sov, a detail the door can read, maybe a debt, a grudge and a secret, who they're tied to, a
// face from parts, and the licence in their wallet, or the one they borrowed. Who comes to the door
// on a night, and when, is Folk.night; the door itself, the line and what he does with it, is
// Folk.Door. Nothing here draws anything.
//
// godot/engine/folk.gd is this file's twin and has to make the same town from the same seed, so
// both keep to the same sums: the game's mulberry32 (rng.js), dates as whole days (no Date), lists
// in the order the YAML gives them, weights summed in that order, and no sort without a tie-break.
// tools/folk_diff.mjs checks the two against each other.
(function (B) {
  'use strict';

  // ---------------------------------------------------------------- dates, as days since 1970-01-01

  function daysFromCivil(y, m, d) {
    y -= m <= 2 ? 1 : 0;
    const era = Math.floor(y / 400);
    const yoe = y - era * 400;
    const doy = Math.floor((153 * (m + (m > 2 ? -3 : 9)) + 2) / 5) + d - 1;
    const doe = yoe * 365 + Math.floor(yoe / 4) - Math.floor(yoe / 100) + doy;
    return era * 146097 + doe - 719468;
  }

  function civilFromDays(z) {
    z += 719468;
    const era = Math.floor(z / 146097);
    const doe = z - era * 146097;
    const yoe = Math.floor((doe - Math.floor(doe / 1460) + Math.floor(doe / 36524) - Math.floor(doe / 146096)) / 365);
    const doy = doe - (365 * yoe + Math.floor(yoe / 4) - Math.floor(yoe / 100));
    const mp = Math.floor((5 * doy + 2) / 153);
    const d = doy - Math.floor((153 * mp + 2) / 5) + 1;
    const m = mp + (mp < 10 ? 3 : -9);
    return [yoe + era * 400 + (m <= 2 ? 1 : 0), m, d];
  }

  function pad2(n) { return (n < 10 ? '0' : '') + n; }
  function iso(days) { const c = civilFromDays(days); return c[0] + '-' + pad2(c[1]) + '-' + pad2(c[2]); }
  function parseIso(s) { const p = String(s).split('-'); return daysFromCivil(+p[0], +p[1], +p[2]); }
  function leap(y) { return y % 4 === 0 && (y % 100 !== 0 || y % 400 === 0); }
  // the same day and month in another year (29 February falls back to the 28th)
  function sameDay(days, year) {
    const c = civilFromDays(days);
    let d = c[2];
    if (c[1] === 2 && d === 29 && !leap(year)) d = 28;
    return daysFromCivil(year, c[1], d);
  }
  // whole years from one day to another
  function yearsBetween(from, to) {
    const a = civilFromDays(from);
    const b = civilFromDays(to);
    let y = b[0] - a[0];
    if (b[1] < a[1] || (b[1] === a[1] && b[2] < a[2])) y--;
    return y;
  }

  // ---------------------------------------------------------------- picking

  function weightOf(v) { return typeof v === 'number' ? v : (v && v.share) || 0; }

  // a key from {key: weight}, or an item from a list of things with .share, by weight
  function weighted(rng, table) {
    const keys = Array.isArray(table) ? null : Object.keys(table);
    const n = keys ? keys.length : table.length;
    let total = 0;
    for (let i = 0; i < n; i++) total += weightOf(keys ? table[keys[i]] : table[i]);
    if (!(total > 0)) return keys ? keys[0] : table[0];
    let r = rng.next() * total;
    for (let i = 0; i < n; i++) {
      r -= weightOf(keys ? table[keys[i]] : table[i]);
      if (r < 0) return keys ? keys[i] : table[i];
    }
    return keys ? keys[n - 1] : table[n - 1];
  }

  function pick(rng, list) { return list.length ? list[rng.int(0, list.length - 1)] : undefined; }
  function chance(rng, p) { return rng.next() < p; }
  function between(rng, r) { return Array.isArray(r) ? rng.int(r[0], r[1]) : r; }

  // a year-keyed table ({1936: [...], 1956: [...]}): the list for a year, the last one at or before it
  function byYear(table, year) {
    const ys = Object.keys(table).map(Number).filter(function (y) { return !isNaN(y); });
    ys.sort(function (a, b) { return a - b; });
    let at = ys[0];
    for (const y of ys) if (y <= year) at = y;
    return table[String(at)] || [];
  }

  // does a person fit a who: {sex, ages, work, drink, home, married}
  function fits(p, who) {
    if (!who) return true;
    if (who.sex && p.sex !== who.sex) return false;
    if (who.ages && (p.age < who.ages[0] || p.age > who.ages[1])) return false;
    if (who.work && who.work.indexOf(p.work) === -1) return false;
    if (who.drink && who.drink.indexOf(p.drink) === -1) return false;
    if (who.home && who.home.indexOf(p.home) === -1) return false;
    if (who.married && !p.partner) return false;
    return true;
  }

  // ---------------------------------------------------------------- the town

  const HAIR_CODE = { hair_dark: 'BLK', hair: 'BRN', hair_blonde: 'BLN', hair_red: 'RED', hair_grey: 'GRY', hair_white: 'WHI' };
  // who works outside, and wears a hat more often for it
  const OUTSIDE = ['mill', 'sawfiler', 'logging', 'log_truck', 'fishing', 'farm', 'trades', 'town_works', 'mechanic', 'ferry'];
  // where the ones working away in Alberta have their licences from (people.yaml alberta_plate)
  const AWAY = [['FORT MCMURRAY', 'T9H'], ['GRANDE PRAIRIE', 'T8V'], ['RED DEER', 'T4N'], ['EDMONTON', 'T5B']];
  const AWAY_STREETS = ['FRANKLIN AVE', 'SIGNAL RD', '100 ST', 'GAETZ AVE', '118 AVE', 'THICKWOOD BLVD'];

  class Folk {
    constructor() {
      this.seed = 0;
      this.people = [];
      this.households = [];
      this.byId = {};
      this.tonight = 0;
    }

    person(id) { return this.byId[id] || null; }
    household(p) { return this.households[+p.hh.slice(1) - 1] || null; }
    adults() { return this.people.filter(function (p) { return !p.teen; }); }

    // the whole town as plain data, for the checks (tools/folk_diff.mjs)
    dump() {
      return {
        households: this.households.map(function (h) { return JSON.parse(JSON.stringify(h)); }),
        people: this.people.map(function (p) { return JSON.parse(JSON.stringify(p)); })
      };
    }
  }

  // ---------------------------------------------------------------- making it
  //
  // In the order the twin does it: households and the people in them, brothers and sisters, exes
  // and friends, work, drink, groups, the rest of a life, the cast's ties, details, faces, sizes,
  // cards, and the teenagers who'll try the door.

  class Maker {
    constructor(seed, content) {
      this.D = content.people;
      this.T = content.town;
      this.town = new Folk();
      this.town.seed = seed >>> 0;
      this.town.tonight = parseIso((content.props && content.props.tonight) || '2026-11-04');
      this.tonightY = civilFromDays(this.town.tonight)[0];
      this.rng = new B.Rng(B.util.hash32(String(this.town.seed) + ':town') || 1);
      this.usedNames = {};
      this.usedNumbers = {};
      this.usedCards = {};
      this.usedLife = {};
    }

    run() {
      this.households();
      this.siblings();
      this.exesAndFriends();
      this.work();
      this.drink();
      this.groups();
      this.lives();
      this.castTies();
      this.details();
      const P = this.town.people;
      for (const p of P) p.look = this.lookOf(p);
      for (const p of P) this.sizeOf(p);
      for (const p of P) p.card = this.cardOf(p);
      for (const p of P) if (p.teen) p.tries = this.triesOf(p);
      return this.town;
    }

    // ---- a person
    // born on a day that makes them `age` tonight
    bornAt(age) {
      const lo = sameDay(this.town.tonight, this.tonightY - age - 1) + 1;
      const hi = sameDay(this.town.tonight, this.tonightY - age);
      return lo + this.rng.int(0, hi - lo);
    }

    newPerson(h, bg, surname, sex, age, teen, bornDays) {
      const rng = this.rng, D = this.D, town = this.town;
      const born = bornDays === undefined ? this.bornAt(age) : bornDays;
      const by = civilFromDays(born)[0];
      age = yearsBetween(born, town.tonight);
      const bgd = D.backgrounds[bg] || {};
      const lists = (bgd.given && bgd.given[sex]) || D.given[sex];
      const notNames = D.not_names || [];
      let given = '';
      for (let tries = 0; tries < 12; tries++) {
        given = pick(rng, byYear(lists, by));
        if (notNames.indexOf(given) === -1 && !this.usedNames[given + ' ' + surname]) break;
      }
      this.usedNames[given + ' ' + surname] = true;
      const middle = bgd.middle ? bgd.middle[sex] : pick(rng, D.middles[sex]);
      const p = {
        id: 'p' + String(town.people.length + 1).padStart(3, '0'),
        hh: h.id, bg: bg, sex: sex, given: given, middle: middle, surname: surname,
        born: iso(born), age: age, teen: !!teen
      };
      town.people.push(p);
      town.byId[p.id] = p;
      h.members.push(p.id);
      return p;
    }

    pickBackground() {
      const table = {};
      for (const k of Object.keys(this.D.backgrounds)) table[k] = this.D.backgrounds[k].share;
      return weighted(this.rng, table);
    }

    pickSurname(bg) {
      const not = this.D.not_names || [];
      return pick(this.rng, this.D.backgrounds[bg].surnames.filter(function (s) { return not.indexOf(s) === -1; }));
    }

    pickSex() { return chance(this.rng, 0.5) ? 'm' : 'f'; }

    // ---- where they live
    address(h, homes) {
      const rng = this.rng, streets = this.T.streets;
      const kind = pick(rng, homes);
      let cands = streets.filter(function (s) { return s.homes.indexOf(kind) !== -1; });
      if (!cands.length) cands = streets.filter(function (s) { return s.homes.indexOf('house') !== -1; });
      const st = weighted(rng, cands.map(function (s) { return { s: s, share: s.weight }; })).s;
      const used = this.usedNumbers[st.id] || (this.usedNumbers[st.id] = {});
      let n = 0;
      for (let tries = 0; tries < 40; tries++) {
        n = rng.int(st.numbers[0], st.numbers[1]);
        // a street's houses go up in twos, a lot's pads and rooms in ones
        if (kind === 'house' || kind === 'suite') n -= n % 2;
        if (!used[n]) break;
      }
      used[n] = true;
      h.street = st.id;
      h.home = kind;
      h.number = n;
      h.area = st.area;
      h.unit = 0;
      if (kind === 'unit') h.unit = rng.int(1, 24);
      else if (kind === 'flat') h.unit = rng.int(1, 2);
      for (const id of h.members) { const p = this.town.byId[id]; p.home = kind; p.area = st.area; }
    }

    // ---- the households, till there are enough adults
    households() {
      const rng = this.rng, D = this.D, town = this.town;
      let adults = 0;
      let guard = 0;
      while (adults < D.adults && guard++ < 1000) {
        const kind = weighted(rng, D.households);
        const h = { id: 'h' + String(town.households.length + 1).padStart(3, '0'), kind: kind.id, members: [] };
        town.households.push(h);
        const bg = this.pickBackground();
        const surname = this.pickSurname(bg);
        const oldest = between(rng, kind.ages);
        const n = between(rng, kind.adults);
        const gap = kind.gap || 4;
        const first = this.newPerson(h, bg, surname, this.pickSex(), oldest, false);
        adults++;
        // the kids' name and background: the household's, or the father's where it's his
        let famBg = bg;
        let famName = surname;
        if (kind.id === 'couple' || kind.id === 'family' || kind.id === 'family_grown') {
          const same = rng.int(1, 100) <= D.couples.same;
          const sex2 = same ? first.sex : (first.sex === 'm' ? 'f' : 'm');
          const age2 = Math.max(19, Math.min(95, oldest + rng.int(-gap, gap)));
          const mixed = chance(rng, 0.12);
          const bg2 = mixed ? this.pickBackground() : bg;
          const kept = rng.int(1, 100) <= D.couples.kept_name;
          const second = this.newPerson(h, bg2, kept || bg2 !== bg ? this.pickSurname(bg2) : surname, sex2, age2, false);
          first.partner = second.id;
          second.partner = first.id;
          adults++;
          if (first.sex === 'f' && second.sex === 'm') { famBg = second.bg; famName = second.surname; }
        } else if (kind.id === 'roommates') {
          for (let i = 1; i < n; i++) {
            const bg2 = this.pickBackground();
            this.newPerson(h, bg2, this.pickSurname(bg2), this.pickSex(), Math.max(19, oldest + rng.int(-gap, gap)), false);
            adults++;
          }
        }
        // the grown kid still at home, and the teenagers
        const parents = h.members.slice();
        let youngest = 999;
        for (const id of parents) youngest = Math.min(youngest, town.byId[id].age);
        // (brothers and sisters are born at least ten months apart, or they're twins)
        const kids = [];
        if (kind.grown) {
          const age = Math.min(between(rng, kind.grown), youngest - 20);
          if (age >= 19) {
            const k = this.newPerson(h, famBg, famName, this.pickSex(), age, false);
            k.kidOf = parents.slice();
            kids.push(parseIso(k.born));
            adults++;
          }
        }
        const teens = kind.teens ? between(rng, kind.teens) : 0;
        for (let i = 0; i < teens; i++) {
          let born = this.bornAt(rng.int(15, 18));
          if (kids.length && chance(rng, 0.08)) born = kids[kids.length - 1];
          else if (!spaced(kids, born)) continue;
          const age = yearsBetween(born, town.tonight);
          if (age < 15 || age > 18 || youngest - age < 20) continue;
          this.newPerson(h, famBg, famName, this.pickSex(), age, true, born).kidOf = parents.slice();
          kids.push(born);
        }
        this.address(h, kind.homes);
      }
    }

    // ---- brothers and sisters: in the same house, and grown ones living elsewhere
    siblings() {
      const rng = this.rng, town = this.town;
      const sibs = function (a, b) {
        a.siblings = a.siblings || [];
        b.siblings = b.siblings || [];
        if (a.siblings.indexOf(b.id) === -1) a.siblings.push(b.id);
        if (b.siblings.indexOf(a.id) === -1) b.siblings.push(a.id);
      };
      for (const h of town.households) {
        const kids = h.members.map(function (id) { return town.byId[id]; }).filter(function (p) { return p.kidOf; });
        for (let i = 0; i < kids.length; i++) for (let j = i + 1; j < kids.length; j++) sibs(kids[i], kids[j]);
      }
      // A family with teenagers often has an older one out on their own: one of the young singles
      // and roommates turns out to be theirs and takes the family's name. It's the older brother's
      // or sister's licence a teenager borrows, so it's the eldest teenager's brother or sister.
      const loose = town.people.filter(function (p) {
        const h = town.household(p);
        return !p.teen && !p.partner && !p.kidOf && p.age >= 19 && p.age <= 27 && (h.kind === 'single' || h.kind === 'roommates');
      });
      for (const h of town.households) {
        let t = null;
        for (const id of h.members) { const k = town.byId[id]; if (k.teen && (!t || k.age > t.age)) t = k; }
        if (!t || !chance(rng, 0.7)) continue;
        let youngest = 999;
        for (const id of t.kidOf) youngest = Math.min(youngest, town.byId[id].age);
        const kids = [];
        for (const id of h.members) { const k = town.byId[id]; if (k.kidOf) kids.push(parseIso(k.born)); }
        let cands = loose.filter(function (p) { return !p.kidOf && youngest - p.age >= 20 && p.age - t.age <= 9 && spaced(kids, parseIso(p.born)); });
        const same = cands.filter(function (p) { return p.sex === t.sex; });
        if (same.length && chance(rng, 0.75)) cands = same;
        if (!cands.length) continue;
        const s = pick(rng, cands);
        s.kidOf = t.kidOf.slice();
        s.bg = t.bg;
        s.surname = t.surname;
        for (const id of h.members) { const k = town.byId[id]; if (k.kidOf && k !== s) sibs(k, s); }
      }
    }

    // ---- exes and friends
    exesAndFriends() {
      const rng = this.rng;
      const grown = this.town.people.filter(function (p) { return !p.teen; });
      for (let i = 0; i < 8; i++) {
        const a = pick(rng, grown);
        const cands = grown.filter(function (b) {
          return b !== a && b.hh !== a.hh && !b.ex && !a.ex && b.sex !== a.sex && Math.abs(b.age - a.age) <= 8 && a.age >= 24;
        });
        if (!cands.length) continue;
        const b = pick(rng, cands);
        a.ex = b.id;
        b.ex = a.id;
      }
      for (const a of grown) {
        if (a.age > 45) continue;
        const k = rng.int(0, 2);
        for (let i = 0; i < k; i++) {
          const cands = grown.filter(function (b) { return b !== a && b.hh !== a.hh && Math.abs(b.age - a.age) <= 4; });
          if (!cands.length) break;
          const b = pick(rng, cands);
          a.friends = a.friends || [];
          b.friends = b.friends || [];
          if (a.friends.indexOf(b.id) === -1) a.friends.push(b.id);
          if (b.friends.indexOf(a.id) === -1) b.friends.push(a.id);
        }
      }
    }

    // ---- work
    work() {
      const rng = this.rng, D = this.D;
      const workIds = Object.keys(D.works);
      for (const p of this.town.people) {
        if (p.teen) {
          // some of them on the till or the fryer after school
          p.work = p.age >= 16 && chance(rng, 0.25) ? (chance(rng, 0.5) ? 'esso' : 'diner') : 'school';
          continue;
        }
        if (p.age >= 65 ? chance(rng, 0.88) : (p.age >= 60 && chance(rng, 0.3))) {
          p.work = 'retired';
          p.retiredFrom = weighted(rng, D.retired_from);
          continue;
        }
        const table = [];
        for (const id of workIds) {
          const w = D.works[id];
          if (!w.share || p.age < w.ages[0] || p.age > w.ages[1]) continue;
          table.push({ id: id, share: w.share * (p.sex === 'm' ? w.m : w.f) });
        }
        p.work = table.length ? weighted(rng, table).id : 'out_of_work';
        const sh = D.works[p.work].shifts || [];
        if (sh.length) p.shift = pick(rng, sh);
      }
    }

    // ---- how they drink, and how often they're at the Sov
    drink() {
      const rng = this.rng, D = this.D;
      for (const p of this.town.people) {
        if (p.teen) {
          p.drink = weighted(rng, { none: 3, light: 3, social: 2, binge: 2 });
          p.regular = 'never';
          continue;
        }
        p.drink = weighted(rng, D.drink);
        let odds = Object.assign({}, D.drink[p.drink].regular);
        // nearer the Sov, more often; the hill comes down for it less
        if ((p.area === 'strip' || p.area === 'flats') && odds.weekly) odds.weekly += 1;
        if (p.area === 'hill' && odds.never != null) odds.never += 1;
        if (this.town.household(p).street === 'sov') odds = { weekly: 2, nightly: 3 };
        p.regular = weighted(rng, odds);
      }
    }

    // ---- who they drink with, by the bar's codes
    groups() {
      const D = this.D;
      for (const p of this.town.people) {
        if (p.teen) p.group = 'teens';
        else if (p.age <= 25) p.group = 'kids';
        else if (p.work === 'retired') p.group = p.retiredFrom === 'forces' ? 'vets' : 'old';
        else p.group = (D.works[p.work] && D.works[p.work].group) || 'town';
      }
    }

    // ---- a debt, a grudge and a secret, for some of them, made out to somebody
    lifeOf(p, kind, list) {
      const rng = this.rng, used = this.usedLife;
      const ok = [];
      for (let i = 0; i < list.length; i++) {
        const x = list[i];
        if ((used[kind + i] || 0) >= (x.times || 1) || !fits(p, x.who)) continue;
        ok.push(i);
      }
      if (!ok.length) return null;
      const i = pick(rng, ok);
      const x = list[i];
      let other = '';
      if (x.text.indexOf('{other}') !== -1) {
        const cands = this.town.people.filter(function (b) {
          if (b.teen || b === p || b.hh === p.hh) return false;
          if (x.other === 'married' && !b.partner) return false;
          if (x.other === 'near' && Math.abs(b.age - p.age) > 6) return false;
          return true;
        });
        if (!cands.length) return null;
        other = pick(rng, cands).id;
      }
      used[kind + i] = (used[kind + i] || 0) + 1;
      return { text: x.text, other: other };
    }

    lives() {
      const rng = this.rng, D = this.D, L = D.life || {};
      for (const p of this.town.people) {
        if (p.teen) continue;
        if (chance(rng, (L.debt || 0) / 100)) p.debt = this.lifeOf(p, 'd', D.debts);
        if (chance(rng, (L.grudge || 0) / 100)) p.grudge = this.lifeOf(p, 'g', D.grudges);
        if (chance(rng, (L.secret || 0) / 100)) p.secret = this.lifeOf(p, 's', D.secrets);
        if (!p.debt) delete p.debt;
        if (!p.grudge) delete p.grudge;
        if (!p.secret) delete p.secret;
      }
    }

    // ---- the cast's ties: one person each at most
    castTies() {
      const rng = this.rng;
      for (const t of this.D.cast_ties || []) {
        const cands = this.town.people.filter(function (p) { return !p.teen && !p.castTie && fits(p, t.who); });
        if (!cands.length || !chance(rng, 0.8)) continue;
        const p = pick(rng, cands);
        p.castTie = { cast: t.cast, text: t.text };
      }
    }

    // ---- what the door can read off them
    details() {
      const rng = this.rng, D = this.D;
      const lifeIds = Object.keys(D.life_details.list);
      for (const p of this.town.people) {
        if (!p.teen && chance(rng, D.life_details.share / 100)) {
          const ok = lifeIds.filter(function (k) { return fits(p, D.life_details.list[k].who); });
          if (ok.length) { p.detail = pick(rng, ok); continue; }
        }
        if (p.teen) { p.detail = pick(rng, D.teen_details); continue; }
        const w = D.works[p.work];
        const list = (w && w.details) || [];
        p.detail = list.length ? pick(rng, list) : 'wet_through';
      }
    }

    // ---- faces, from parts

    lookOf(p) {
      const rng = this.rng, D = this.D, L = D.looks;
      const band = ageBand(p);
      const bl = (D.backgrounds[p.bg] && D.backgrounds[p.bg].looks) || {};
      const look = { sex: p.sex };
      if (band !== 'mid') look.age = band;
      look.build = weighted(rng, L.build);
      look.hair = weighted(rng, L.hair[p.sex][band]);
      look.hair_mat = weighted(rng, (bl.hair_colour === 'dark' ? L.hair_dark : L.hair_colour)[band]);
      const face = [];
      // a turban, and the full beard that goes with it
      const turban = p.sex === 'm' && !p.teen && bl.turban && chance(rng, bl.turban / 10);
      if (p.sex === 'm' && !p.teen) {
        const b = turban ? 'beard' : weighted(rng, L.beard);
        if (b !== 'none') face.push(b);
      }
      if (chance(rng, L.glasses / 10)) face.push('glasses');
      if (band === 'old') face.push('lined');
      if (face.length) look.face = face;
      // a hat, more often on men who work outside
      if (turban) look.hat = 'turban';
      else {
        const outside = OUTSIDE.indexOf(p.work) !== -1;
        if (chance(rng, (L.hat.odds + (outside ? 3 : 0) - (p.sex === 'f' ? 2 : 0)) / 10)) look.hat = weighted(rng, L.hat.kinds);
        if (look.hat === 'flatcap' && band !== 'old') look.hat = 'cap';
      }
      const w = D.works[p.work];
      const tops = p.teen ? ['hoodie', 'jacket', 'tshirt'] : (w && w.tops) || ['jacket'];
      look.top = pick(rng, tops);
      look.top_mat = pick(rng, L.tops[look.top] ? L.tops[look.top].colours : [look.top]);
      if (p.age < 26 && chance(rng, 0.15)) look.extra = ['vape'];
      look.mood = weighted(rng, { flat: 3, tired: 2, wary: 1, smile: 2 });
      return look;
    }

    sizeOf(p) {
      const rng = this.rng, D = this.D;
      const s = D.size[p.sex][p.look.build];
      let h = rng.int(s[0][0], s[0][1]);
      if (p.teen && p.age < 17) h -= rng.int(0, 6);
      p.height = h;
      let w = rng.int(s[1][0], s[1][1]);
      // the teenagers haven't filled out yet
      if (p.teen && p.look.build !== 'slight') w = Math.floor(w * 88 / 100);
      p.weight = w;
      const bl = (D.backgrounds[p.bg] && D.backgrounds[p.bg].looks) || {};
      p.eyes = weighted(rng, bl.eyes === 'dark' ? D.eyes_dark : D.eyes);
      p.hairCode = p.look.hair === 'bald' ? 'BLD' : (HAIR_CODE[p.look.hair_mat] || 'BRN');
    }

    cardNumber() {
      let n = '';
      for (let tries = 0; tries < 20; tries++) {
        n = String(this.rng.int(1000000, 9999999));
        if (!this.usedCards[n]) break;
      }
      this.usedCards[n] = true;
      return n;
    }

    addressOf(p) {
      const h = this.town.household(p);
      return { street: h.street, number: h.number, unit: h.unit || 0, home: h.home };
    }

    // What the photo on a card looks like: the same face some years back, the way they make you
    // take it (no hat, unless it's a turban), in whatever they wore that day.
    photoOf(p, yearsAgo) {
      const rng = this.rng, D = this.D;
      const ph = { hat: p.look.hat === 'turban' ? 'turban' : '' };
      if (yearsAgo >= 3 && p.look.hair !== 'bald' && chance(rng, 0.5)) ph.hair = weighted(rng, D.looks.hair[p.sex][p.age - yearsAgo < 30 ? 'young' : 'mid']);
      if (yearsAgo >= 2) {
        const tops = Object.keys(D.looks.tops).filter(function (t) { return t !== 'scrubs' && t !== 'hivis'; });
        ph.top = pick(rng, tops);
      }
      if (p.age - yearsAgo < 30) ph.age = 'young';
      return ph;
    }

    cardOf(p) {
      const rng = this.rng, town = this.town;
      const bornDays = parseIso(p.born);
      const bornY = civilFromDays(bornDays)[0];
      // a learner's licence at sixteen, a new driver's a year on; some of the old who don't drive
      // carry the province's ID card instead (no class)
      let cls = '5';
      let type = 'licence';
      if (p.teen) {
        if (p.age < 16 || chance(rng, 0.45)) return null;
        cls = p.age >= 17 && chance(rng, 0.5) ? '7N' : '7L';
      } else if (p.age >= 70 && chance(rng, 0.25)) {
        type = 'id';
        cls = '';
      } else if (chance(rng, 0.05)) {
        type = 'id';
        cls = '';
      } else if (p.age <= 21 && chance(rng, 0.55)) {
        cls = '7N';
      }
      // issued on a birthday and good five years, but a learner's runs two from the day it's issued;
      // now and then they let one run out
      const ageNow = yearsBetween(bornDays, town.tonight);
      let issued;
      let expires;
      if (cls === '7L' || cls === '7N') {
        const from = sameDay(bornDays, bornY + (cls === '7L' ? 16 : 17));
        issued = from + rng.int(0, Math.max(0, town.tonight - from - 1));
        const ic = civilFromDays(issued);
        expires = cls === '7L' ? daysFromCivil(ic[0] + 2, ic[1], Math.min(ic[2], 28)) : sameDay(bornDays, ic[0] + 5);
      } else {
        const lastBirthday = sameDay(bornDays, bornY + ageNow);
        const back = !p.teen && chance(rng, 0.04) ? rng.int(5, 7) : rng.int(0, 4);
        issued = sameDay(lastBirthday, civilFromDays(lastBirthday)[0] - back);
        expires = sameDay(bornDays, civilFromDays(issued)[0] + 5);
      }
      const yearsAgo = yearsBetween(issued, town.tonight);
      const card = {
        type: type, cls: cls, prov: 'BC', number: this.cardNumber(),
        surname: p.surname.toUpperCase(), given: (p.given + (p.middle ? ' ' + p.middle : '')).toUpperCase(),
        born: p.born, issued: iso(issued), expires: iso(expires),
        sex: p.sex.toUpperCase(), height: p.height, weight: Math.max(40, p.weight + rng.int(-6, 3)),
        eyes: p.eyes, hair: p.hairCode, address: this.addressOf(p), photo: this.photoOf(p, yearsAgo)
      };
      if (!p.teen && p.detail === 'alberta_plate' && type === 'licence') {
        // working away: it's an Alberta licence, from the address up there
        const a = pick(rng, AWAY);
        card.prov = 'AB';
        card.cls = '5';
        card.number = String(rng.int(100000, 999999)) + '-' + String(rng.int(100, 999));
        card.address = { street: '', number: rng.int(100, 9900), unit: 0, home: 'house', away: pick(rng, AWAY_STREETS), city: a[0], postal: a[1] + ' ' + rng.int(1, 9) + 'K' + rng.int(1, 9) };
      } else if (!p.teen && chance(rng, 0.08)) {
        // moved, and never changed it: the card still says where they used to live
        const st = pick(rng, this.T.streets.filter(function (s) { return s.homes.indexOf('house') !== -1; }));
        let n = rng.int(st.numbers[0], st.numbers[1]);
        n -= n % 2;
        card.address = { street: st.id, number: n, unit: 0, home: 'house', old: true };
      }
      if (expires < town.tonight) card.expired = true;
      return card;
    }

    // A teenager who tries the door, and what with: the older brother's or sister's licence, their
    // own with the year lifted, a printed one off the internet, a photo on a phone, or nothing.
    triesOf(p) {
      const rng = this.rng, town = this.town;
      const odds = p.age >= 18 ? 0.55 : (p.age === 17 ? 0.35 : (p.age === 16 ? 0.1 : 0.03));
      if (!chance(rng, odds)) return null;
      const older = (p.siblings || []).map(function (id) { return town.byId[id]; }).filter(function (s) {
        return s && !s.teen && s.sex === p.sex && s.card && s.card.type === 'licence' && s.card.prov === 'BC' && !s.card.expired && s.age - p.age <= 9;
      });
      const kinds = {};
      if (older.length) kinds.sibling = 12;
      if (p.card) kinds.lifted = 2;
      kinds.printed = 2;
      kinds.phone = 1;
      kinds.none = 1;
      const t = { kind: weighted(rng, kinds) };
      if (t.kind === 'sibling') t.from = pick(rng, older).id;
      if (t.kind === 'lifted' || t.kind === 'printed') t.years = rng.int(2, 4);
      // a printed one either scans, with its own numbers in the barcode, or it doesn't
      if (t.kind === 'printed') t.scans = chance(rng, 0.5);
      return t;
    }
  }

  // ---------------------------------------------------------------- saying it out loud

  const ONES = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten', 'eleven', 'twelve',
    'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen'];
  const TENS = ['', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety'];
  const ORD = ['', 'first', 'second', 'third', 'fourth', 'fifth', 'sixth', 'seventh', 'eighth', 'ninth', 'tenth', 'eleventh',
    'twelfth', 'thirteenth', 'fourteenth', 'fifteenth', 'sixteenth', 'seventeenth', 'eighteenth', 'nineteenth', 'twentieth',
    'twenty-first', 'twenty-second', 'twenty-third', 'twenty-fourth', 'twenty-fifth', 'twenty-sixth', 'twenty-seventh',
    'twenty-eighth', 'twenty-ninth', 'thirtieth', 'thirty-first'];
  const MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  // the sign that starts in each month, and the day it starts
  const SIGNS = ['Aquarius', 'Pisces', 'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 'Libra', 'Scorpio', 'Sagittarius', 'Capricorn'];
  const SIGN_FROM = [20, 19, 21, 20, 21, 21, 23, 23, 23, 23, 22, 22];
  const EYES = { BRN: 'brown', BLU: 'blue', GRN: 'green', HAZ: 'hazel' };

  // 0 to 99 in words
  function words(n) {
    if (n < 20) return ONES[n];
    const o = n % 10;
    return TENS[Math.floor(n / 10)] + (o ? '-' + ONES[o] : '');
  }
  function lastTwo(n) { return n === 0 ? 'hundred' : n < 10 ? 'oh-' + ONES[n] : words(n); }
  // a year the way it's said: nineteen fifty-three, two thousand and three, twenty ten; or short: fifty-three, oh-three
  function yearWords(y, short) {
    const lo = y % 100;
    if (short) return lo < 10 ? 'oh-' + ONES[lo] : words(lo);
    if (y < 2000) return words(Math.floor(y / 100)) + ' ' + lastTwo(lo);
    if (lo === 0) return 'two thousand';
    return lo < 10 ? 'two thousand and ' + ONES[lo] : 'twenty ' + words(lo);
  }
  // a house number the way it's said: fourteen, four-oh-two, seventeen fifty
  function numberWords(n) {
    if (n < 100) return words(n);
    if (n < 1000) return ONES[Math.floor(n / 100)] + (n % 100 ? ' ' + lastTwo(n % 100) : ' hundred');
    if (n % 1000 === 0) return words(n / 1000) + ' thousand';
    return words(Math.floor(n / 100)) + ' ' + lastTwo(n % 100);
  }
  function signOf(m, d) { return d >= SIGN_FROM[m - 1] ? SIGNS[m - 1] : SIGNS[(m + 10) % 12]; }
  // V0R 2K1 -> "V zero R, two K one"
  function postalWords(pc) {
    const c = String(pc).replace(' ', '');
    const w = function (ch) { return ch >= '0' && ch <= '9' ? ONES[+ch] : ch; };
    return w(c[0]) + ' ' + w(c[1]) + ' ' + w(c[2]) + ', ' + w(c[3]) + ' ' + w(c[4]) + ' ' + w(c[5]);
  }
  function cap(s) { return s ? s[0].toUpperCase() + s.slice(1) : s; }
  function title(s) { return String(s).toLowerCase().replace(/(^|[ '-])([a-z])/g, function (m, a, b) { return a + b.toUpperCase(); }); }
  // minutes as he'd say them: "twenty minutes", "an hour", "an hour and a half"
  function minutesWords(m) {
    if (m < 2) return 'a minute';
    if (m < 50) return words(m) + ' minutes';
    if (m < 80) return 'an hour';
    if (m < 110) return 'an hour and a half';
    return words(Math.min(99, Math.floor((m + 30) / 60))) + ' hours';
  }

  // ---------------------------------------------------------------- the night
  //
  // Who comes to the door on a night (content/rules/door.yaml, nights), when, with whom, and how
  // they are when they get there. Made from the game's seed and the day, the same every time.

  function nightOf(content, day) {
    const N = (content.door && content.door.nights) || [];
    for (const n of N) if (n.day === day) return n;
    return null;
  }

  const SWING_GROUPS = ['mill', 'hospital'];

  function night(town, content, day) {
    const out = { day: day, arrivals: [], people: {} };
    const N = nightOf(content, day);
    if (!N) return out;
    const rng = new B.Rng(B.util.hash32(String(town.seed) + ':night:' + day) || 1);
    const W = N.waves || {};
    const info = out.people;
    const comers = [];
    for (const p of town.people) {
      if (p.teen || p.shift === 'graveyard') continue;
      if (chance(rng, ((N.come || {})[p.regular] || 0) / 100)) comers.push(p);
    }
    // the wave each comes with, and when
    for (const p of comers) {
      const swing = p.shift === 'swing';
      let wave = 'trickle';
      if (swing && W.swing && SWING_GROUPS.indexOf(p.group) !== -1) wave = 'swing';
      else if (swing) wave = 'trickle';
      // the day shift's men who wait up to drink with the swing shift when it lets out
      else if (W.swing && p.group === 'mill' && p.sex === 'm' && p.shift === 'day' && chance(rng, 0.25)) wave = 'swing';
      else if (W.legion && (p.group === 'old' || p.group === 'vets' || p.age >= 55) && ['social', 'steady', 'heavy'].indexOf(p.drink) !== -1 && chance(rng, 0.6)) wave = 'legion';
      else if (W.ferry && ((p.work === 'ferry' || p.detail === 'ferry_stub') ? chance(rng, 0.8) : (p.age <= 60 && chance(rng, 0.08)))) wave = 'ferry';
      else if (W.arena && (p.detail === 'rental_skates' || (p.age <= 45 && p.group !== 'hospital' && chance(rng, p.sex === 'm' ? 0.55 : 0.2)))) wave = 'arena';
      else if (W.dinner && p.age >= 40 && ['none', 'dry', 'light', 'social'].indexOf(p.drink) !== -1 && chance(rng, 0.5)) wave = 'dinner';
      let at;
      if (wave !== 'trickle') at = rng.int(W[wave].at[0], W[wave].at[1]);
      else {
        const slot = weighted(rng, N.trickle.map(function (s) { return { s: s[0], share: s[1] }; })).s;
        at = slot + rng.int(0, 39);
        if (swing) at = Math.max(at, 1395 + rng.int(0, 30));
      }
      info[p.id] = { at: at, wave: wave, drunk: 0, noId: false, with: '' };
    }
    // the teenagers who try it tonight, some with one of the kids who's coming anyway
    const triers = town.people.filter(function (p) { return p.teen && p.tries; });
    const kids = comers.filter(function (p) { return p.age <= 22 && info[p.id].wave === 'trickle'; });
    let k = Math.min(triers.length, rng.int(N.tries[0], N.tries[1]));
    const minors = [];
    while (k-- > 0) {
      const t = triers.splice(rng.int(0, triers.length - 1), 1)[0];
      const i = { at: rng.int(N.tries_at[0], N.tries_at[1]), wave: 'trickle', drunk: 0, noId: false, with: '', minor: true };
      if (kids.length && chance(rng, 0.4)) {
        const kid = kids.splice(rng.int(0, kids.length - 1), 1)[0];
        i.with = kid.id;
        i.at = info[kid.id].at;
      }
      info[t.id] = i;
      minors.push(t);
    }
    // who comes together: a partner who's coming too, a friend now and then, a shift's crew, the
    // teenager and the kid they came with
    const all = comers.concat(minors);
    const groupOf = {};
    for (const p of all) {
      if (groupOf[p.id] !== undefined) continue;
      const me = info[p.id];
      const g = { at: me.at, wave: me.wave, who: [p.id] };
      const gi = out.arrivals.length;
      out.arrivals.push(g);
      groupOf[p.id] = gi;
      const add = function (id) { if (g.who.length < 4 && info[id] && groupOf[id] === undefined) { g.who.push(id); groupOf[id] = gi; } };
      if (p.partner) add(p.partner);
      if (me.with) add(me.with);
      for (const f of p.friends || []) if (info[f] && info[f].wave === me.wave && !info[f].minor && chance(rng, 0.5)) add(f);
      if (me.wave === 'swing' || me.wave === 'arena') {
        for (const q of comers) if (q !== p && info[q.id].wave === me.wave && groupOf[q.id] === undefined && g.who.length < 3 && chance(rng, 0.5)) add(q.id);
      }
      // the teenagers who came with any of them
      for (const m of minors) if (g.who.indexOf(info[m.id].with) !== -1) add(m.id);
      for (const id of g.who) { info[id].at = g.at; info[id].wave = g.wave; }
    }
    out.arrivals.sort(function (a, b) { return a.at - b.at || (a.who[0] < b.who[0] ? -1 : 1); });
    // how they are when they get there
    for (const a of out.arrivals) {
      for (const id of a.who) {
        const p = town.byId[id];
        const me = info[id];
        if (p.teen) { me.drunk = p.detail === 'gum' ? 1 : 0; continue; }
        let d = a.wave === 'legion' ? 2 : a.wave === 'arena' || a.wave === 'ferry' ? 1 : a.wave === 'trickle' ? (a.at < 1320 ? 0 : a.at < 1440 ? 1 : 2) : 0;
        if (p.drink === 'none' || p.drink === 'dry') d = 0;
        else if (p.drink === 'light') d = Math.min(d, 1);
        else if (p.drink === 'heavy' || p.drink === 'binge') d = Math.min(3, d + 1);
        if (d > 0 && chance(rng, 0.4)) d--;
        me.drunk = d;
        // the wallet's in the truck
        me.noId = chance(rng, 0.03);
      }
    }
    return out;
  }

  // ---------------------------------------------------------------- the cards they hold out
  //
  // What a person hands him at the door: their own licence, or their brother's or sister's, their
  // own with the year lifted under the laminate, a printed one, a photo of one on a phone. As
  // props.yaml draws a card, made on the spot: "door:<id>:<own|sib|lifted|printed|phone>".

  function variantOf(p, noId) {
    if (p.tries) return p.tries.kind === 'sibling' ? 'sib' : p.tries.kind === 'none' ? '' : p.tries.kind;
    if (noId || !p.card) return '';
    return 'own';
  }

  // whose card it is: theirs, or the brother's or sister's
  function ownerOf(town, p, variant) {
    return variant === 'sib' && p.tries && p.tries.from ? town.byId[p.tries.from] : p;
  }

  // the card's data, as it's printed on it
  function shownCard(town, p, variant) {
    if (!variant) return null;
    const own = p.card;
    if (variant === 'own') return own;
    if (variant === 'sib') return town.byId[p.tries.from].card;
    const c = civilFromDays(parseIso(p.born));
    const years = p.tries.years || 3;
    const day = c[2] === 29 && c[1] === 2 ? 28 : c[2];
    if (variant === 'lifted' && own) {
      const o = JSON.parse(JSON.stringify(own));
      o.born = iso(daysFromCivil(c[0] - years, c[1], day));
      o.lifted = true;
      o.realBorn = own.born;
      return o;
    }
    // printed off the internet, or a photo of a printed one: their own name and face, a better year
    const rng = new B.Rng(B.util.hash32(String(town.seed) + ':printed:' + p.id) || 1);
    const fakeBorn = daysFromCivil(c[0] - years, c[1], day);
    const issued = town.tonight - rng.int(100, 700);
    const h = town.household(p);
    return {
      type: 'licence', cls: '5', prov: 'BC', number: String(rng.int(1000000, 9999999)),
      surname: p.surname.toUpperCase(), given: (p.given + (p.middle ? ' ' + p.middle : '')).toUpperCase(),
      born: iso(fakeBorn), issued: iso(issued), expires: iso(sameDay(fakeBorn, civilFromDays(issued)[0] + 5)),
      sex: p.sex.toUpperCase(), height: p.height + rng.int(0, 4), weight: p.weight + rng.int(0, 6),
      eyes: p.eyes, hair: p.hairCode, address: { street: h.street, number: h.number, unit: h.unit || 0, home: h.home },
      photo: { hat: '' }, printed: true, scans: !!p.tries.scans
    };
  }

  // a street by its id (content/data/town.yaml)
  function streetOf(T, id) {
    for (const s of T.streets) if (s.id === id) return s;
    return null;
  }

  // the postal code on a card's address
  function postalOf(T, a) {
    if (a.city) return a.postal;
    const st = streetOf(T, a.street);
    return st ? T.areas[st.area].postal : '';
  }

  // The card as props.yaml has them, for the page and the Godot build to draw (src/ui/props.js,
  // godot/game/props.gd): whose face, as it looked then, and every line on it.
  function cardProp(town, content, id) {
    const w = String(id).split(':');
    const p = town.byId[w[1]];
    if (!p) return null;
    const variant = w[2] || 'own';
    const c = shownCard(town, p, variant);
    if (!c) return null;
    const owner = ownerOf(town, p, variant);
    const look = Object.assign({}, owner.look, c.photo || {});
    if (!look.hat) delete look.hat;
    const T = content.town;
    let addr = [];
    const a = c.address;
    if (a.city) addr = [a.number + ' ' + a.away, a.city + ' AB  ' + a.postal];
    else {
      const st = streetOf(T, a.street);
      const lot = T.lots && T.lots[a.street];
      const line1 = lot ? lot.prefix + ' ' + a.number + '  ' + lot.number + ' ' + st.short : (a.unit ? a.unit + '-' : '') + a.number + ' ' + (st ? st.short : '');
      addr = [line1, 'BC  ' + postalOf(T, a)];
    }
    const prop = {
      kind: 'card', look: look, surname: c.surname, given: c.given, born: c.born, issued: c.issued, expires: c.expires,
      class: c.cls, sex: c.sex, height: c.height, weight: c.weight, eyes: c.eyes, hair: c.hair, number: c.number,
      address: addr, prov: c.prov || 'BC', town: true
    };
    if (c.type === 'id') prop.type = 'id';
    if (c.printed) prop.holo = 'printed';
    if (c.lifted) prop.lifted = true;
    if (variant === 'phone') prop.phone = true;
    if (c.expired) prop.expired = true;
    return prop;
  }

  // ---------------------------------------------------------------- the door
  //
  // The line and what he does with it, a night at a time. Arrivals join the line when their time
  // comes (tick), the one at the front is whoever he's dealing with (next), and what he does with
  // them is kept: let in on a nod, on a glance at the card, or on a slow read; turned away; the
  // card kept. Whoever waits longer than they'll stand in the rain goes, or goes past him. What
  // they say is the town's lines (content/rules/door.yaml), by who they are, each said once a game
  // where it can be. The Ink asks and decides (content/ink/line.ink); this keeps count.
  //
  // mem is the game's, across nights: met (everyone he's dealt with: {day, did, name, rapport})
  // and used (the door.yaml lines said already).

  const QUESTIONS = ['middle', 'birthday', 'sign', 'postal', 'year'];

  class Door {
    constructor(town, content, day, mem) {
      this.town = town;
      this.C = content;
      this.day = day;
      this.night = night(town, content, day);
      mem = mem || {};
      this.met = mem.met || (mem.met = {});
      this.used = mem.used || (mem.used = []);
      this.idx = 0;
      this.later = [];      // who's coming back, or coming for something: {at, id, why}
      this.line = [];       // {id, at, why}
      this.cur = '';
      this.last = '';       // who was at the front last: what they say going in is said after
      this.st = {};
      this.other = '';      // someone not at the front the Ink is talking about (a minor Paige found)
      this.rec = {};        // id -> {did, at, how, minor}
      this.n = { in: 0, refused: 0, kept: 0, left: 0, slipped: 0, missed: 0, minors: 0, caught: 0, found: 0, longest: 0, nodded: 0, glanced: 0, read: 0, scanned: 0, waved: 0 };
      this.waves = [];
      this.said = [];       // the waves the Ink has announced
      this.scans = {};      // card number -> when it was scanned
      this.tagOf = {};
      this.kept = [];       // {id, variant, at, owner, back}
    }

    toJSON() {
      return { day: this.day, idx: this.idx, later: this.later, line: this.line, cur: this.cur, last: this.last, st: this.st, other: this.other, rec: this.rec,
        n: this.n, waves: this.waves, said: this.said, scans: this.scans, tagOf: this.tagOf, kept: this.kept };
    }

    fromJSON(s) {
      if (!s) return this;
      for (const k of ['idx', 'later', 'line', 'cur', 'last', 'st', 'other', 'rec', 'n', 'waves', 'said', 'scans', 'tagOf', 'kept']) if (s[k] !== undefined) this[k] = s[k];
      return this;
    }

    rngFor(key) { return new B.Rng(B.util.hash32(String(this.town.seed) + ':door:' + this.day + ':' + key) || 1); }
    info(id) { return this.night.people[id] || { at: 0, wave: 'trickle', drunk: 0, noId: false, with: '' }; }
    person(id) { return this.town.byId[id] || null; }

    // ---- the line

    // Arrivals up to now join the line, and whoever's waited longer than they'll stand there goes:
    // home, or past him while he's busy. On a night with nobody on the door between looks (alone),
    // whoever's waited too long has let themselves in.
    tick(clock, alone) {
      const A = this.night.arrivals;
      while (this.idx < A.length && A[this.idx].at <= clock) {
        const a = A[this.idx++];
        for (const id of a.who) this.line.push({ id: id, at: a.at, why: '' });
        if (a.wave !== 'trickle' && this.waves.indexOf(a.wave) === -1) this.waves.push(a.wave);
      }
      while (this.later.length && this.later[0].at <= clock) {
        const l = this.later.shift();
        this.line.push({ id: l.id, at: l.at, why: l.why });
      }
      const keep = [];
      for (let i = 0; i < this.line.length; i++) {
        const l = this.line[i];
        const waited = clock - l.at;
        if (waited <= this.patience(l.id) || l.why === 'card' || (!alone && i < 2)) { keep.push(l); continue; }
        const p = this.person(l.id);
        if (alone) {
          this.rec[l.id] = { did: 'missed', at: clock };
          this.n.missed++;
          continue;
        }
        const known = !!this.met[l.id] || p.regular === 'nightly';
        if (this.line.length >= 5 && (known || p.teen) && chance(this.rngFor('wait:' + l.id), 0.5)) {
          this.rec[l.id] = { did: 'slipped', at: clock };
          this.n.slipped++;
          if (p.teen) { this.rec[l.id].minor = true; this.n.minors++; }
        } else {
          this.rec[l.id] = { did: 'left', at: clock };
          this.n.left++;
        }
      }
      this.line = keep;
      this.n.longest = Math.max(this.n.longest, this.line.length + (this.cur ? 1 : 0));
      return this.line.length;
    }

    // how long they'll stand in the rain
    patience(id) {
      const p = this.person(id);
      const me = this.info(id);
      if (p.teen) return 40;
      if (me.drunk >= 2) return 15;
      if (p.age >= 60) return 35;
      return 25;
    }

    // the next one comes up to the stool: 1, or 0 if there's nobody
    next(clock) {
      if (!this.line.length) { this.cur = ''; return 0; }
      const l = this.line.shift();
      this.cur = l.id;
      const p = this.person(l.id);
      const me = this.info(l.id);
      const before = this.last;
      this.last = l.id;
      const g = this.groupOf(l.id);
      this.st = { id: l.id, why: l.why || '', prev: before, behind: !!before && !!g && g.who.indexOf(before) !== -1 && !l.why, took: false, asked: {}, last: '', said: '', hes: false, wrong: false, slip: '', scanned: '', read: false,
        chat: false, caught: false, looked: '', tilted: '', flipped: '', variant: variantOf(p, me.noId && l.why !== 'back'), waited: clock - l.at, at: clock };
      this.tag(l.id);
      return 1;
    }

    // whoever's next behind the one at the front came with them
    together() {
      if (!this.cur || !this.line.length) return false;
      const a = this.groupOf(this.cur);
      return !!a && a.who.indexOf(this.line[0].id) !== -1;
    }

    // how many behind the one at the front came with them
    party() {
      const a = this.cur ? this.groupOf(this.cur) : null;
      let k = 0;
      if (!a) return 0;
      for (const l of this.line) { if (a.who.indexOf(l.id) === -1) break; k++; }
      return k;
    }

    groupOf(id) {
      for (const a of this.night.arrivals) if (a.who.indexOf(id) !== -1) return a;
      return null;
    }

    // ---- what he calls them

    // The door's tag for someone (HOODIE, HI-VIS: content/data/characters.yaml), tonight's own: by a
    // hat, a top, a face, the hair, and never one of the cast's
    tag(id) {
      if (this.tagOf[id]) return this.tagOf[id];
      const p = this.person(id);
      const L = p.look;
      const T = (this.C.door && this.C.door.tags) || {};
      const taken = {};
      for (const k in this.tagOf) taken[this.tagOf[k]] = true;
      for (const t of T.cast || []) taken[t] = true;
      // what he called them last time, if nobody's using it tonight
      const m = this.met[id];
      if (m && m.tag && !taken[m.tag]) { this.tagOf[id] = m.tag; return m.tag; }
      const cands = [];
      const add = function (list) { for (const t of list || []) cands.push(t); };
      const tops = topOf(T.top || {}, L) || [];
      if (L.hat) add((T.hat || {})[L.hat]);
      add(tops.slice(0, 1));
      for (const f of L.face || []) add((T.face || {})[f]);
      add((T.hair || {})[L.hair]);
      add(tops.slice(1));
      let tag = '';
      for (const t of cands) if (!taken[t]) { tag = t; break; }
      if (!tag) {
        const top = tops[0] || 'COAT';
        for (let i = 2; i < 30 && !tag; i++) if (!taken[top + ' ' + words(i).toUpperCase()]) tag = top + ' ' + words(i).toUpperCase();
      }
      this.tagOf[id] = tag;
      return tag;
    }

    // What the page calls them: the name on the card once he's read it (whosever card it was), or
    // the door's tag till then.
    label(id) {
      id = id || this.cur || this.last;
      if (!id) return '';
      if ((id === this.cur || (!this.cur && id === this.last)) && this.st.took && this.st.variant && this.st.variant !== 'phone') {
        const c = this.card();
        if (c) return c.given.split(' ')[0];
      }
      const m = this.met[id];
      if (m && m.name) return m.name.toUpperCase();
      return this.tag(id);
    }

    // ---- what the Ink can ask about the one in front of him

    card() { return this.cur ? shownCard(this.town, this.person(this.cur), this.st.variant) : null; }

    propId() { return this.cur && this.st.variant ? 'door:' + this.cur + ':' + this.st.variant : ''; }

    has(what) {
      const parts = String(what).split(':');
      switch (parts[0]) {
        case 'front': return !!this.cur;
        case 'waiting': return this.line.length > 0;
        case 'other': return !!this.other;
      }
      const id = this.cur;
      if (!id) return false;
      const p = this.person(id);
      const me = this.info(id);
      const st = this.st;
      const c = this.card();
      switch (parts[0]) {
        case 'card': return !!c && st.variant !== 'phone';
        case 'phone': return st.variant === 'phone';
        case 'nocard': return !st.variant;
        case 'known': return !!this.met[id];
        case 'name': return !!(this.met[id] && this.met[id].name);
        case 'was': return !!this.met[id] && this.met[id].did === parts[1];
        case 'rapport': return !!(this.met[id] && this.met[id].rapport);
        case 'group': return this.together();
        case 'young': return p.age <= 25;
        case 'old': return p.age >= 50;
        case 'teen': return !!p.teen;
        case 'drunk': return me.drunk >= 2;
        case 'hammered': return me.drunk >= 3;
        case 'sober': return me.drunk === 0;
        case 'took': return !!st.took;
        case 'asked': return parts[1] ? !!st.asked[parts[1]] : Object.keys(st.asked).length > 0;
        case 'can': return !!st.took && !!c && !st.asked[parts[1]];
        case 'scanned': return !!st.scanned;
        case 'read': return !!st.read;
        case 'chat': return !!st.chat;
        case 'looked': return !!st.looked;
        case 'tilted': return parts[1] ? st.tilted === parts[1] : !!st.tilted;
        case 'flipped': return parts[1] ? st.flipped === parts[1] : !!st.flipped;
        case 'hes': return !!st.hes;
        case 'wrong': return !!st.wrong;
        case 'slip': return !!st.slip;
        case 'regular': return p.regular === 'nightly' || p.regular === 'weekly';
        case 'expired': return !!c && !!c.expired;
        case 'oop': return !!c && c.prov !== 'BC';
        case 'idcard': return !!c && c.type === 'id';
        case 'oldaddr': return !!c && !!c.address.old;
        case 'fake': return !!p.tries;
        case 'kind': return !!p.tries && st.variant === parts[1];
        // the one whose card it is: he's dealt with them before, or they're inside tonight
        case 'owner_met': return st.variant === 'sib' && !!this.met[p.tries.from];
        case 'owner_in': return st.variant === 'sib' && !!this.rec[p.tries.from] && this.rec[p.tries.from].did === 'in';
        case 'caught': return !!st.caught;
        case 'scan': return st.scanned === parts[1];
        case 'detail': return p.detail === parts[1];
        case 'wave': return me.wave === parts[1];
        case 'why': return st.why === (parts[1] || '');
        case 'kept': return this.keptFor(id) !== -1;
      }
      return false;
    }

    // a card he kept tonight that's this one's
    keptFor(id) {
      for (let i = 0; i < this.kept.length; i++) if (this.kept[i].owner === id && !this.kept[i].back) return i;
      return -1;
    }

    count(what) {
      if (what === 'waiting') return this.line.length;
      if (what === 'front') return this.cur ? 1 : 0;
      if (what === 'waves') return this.waves.length;
      if (what === 'arrivals') { let k = 0; for (const a of this.night.arrivals) k += a.who.length; return k; }
      if (what === 'due') { let k = 0; for (let i = this.idx; i < this.night.arrivals.length; i++) k += this.night.arrivals[i].who.length; return k; }
      if (what === 'party') return this.party();
      if (what === 'waited') return this.cur ? this.st.waited | 0 : 0;
      if (what === 'age') return this.cur ? this.person(this.cur).age : 0;
      if (what === 'kept_out') { let k = 0; for (const x of this.kept) if (!x.back) k++; return k; }
      if (what === 'minors_in') { let k = 0; for (const id in this.rec) if (this.rec[id].minor && (this.rec[id].did === 'in' || this.rec[id].did === 'slipped')) k++; return k; }
      return this.n[what] | 0;
    }

    // the wave that's just begun, once ("" if none, or it's been said)
    wave() {
      for (const w of this.waves) if (this.said.indexOf(w) === -1) { this.said.push(w); return w; }
      return '';
    }

    // ---- doing things

    // ctx: {clock, stats, felt, passed}
    act(what, ctx) {
      const id = this.cur;
      const parts = String(what).split(':');
      if (parts[0] === 'found') return this.find(ctx.clock);
      if (!id) return 0;
      const p = this.person(id);
      const st = this.st;
      switch (parts[0]) {
        case 'nod': this.n.nodded++; return this.letIn(id, ctx.clock, 'nod');
        case 'glance': {
          this.n.glanced++;
          if (!st.variant || st.variant === 'phone') { st.caught = true; return 0; }
          if (this.notice(ctx)) { st.caught = true; return 0; }
          return this.letIn(id, ctx.clock, 'glance');
        }
        case 'take': st.took = true; this.n.read++; return 1;
        case 'look': st.looked = true; return this.look(ctx);
        case 'ask': return this.ask(parts[1], ctx);
        case 'scan': return this.scan(ctx);
        case 'size': st.read = !!ctx.passed; return st.read ? 1 : 0;
        case 'chat': st.chat = true; return 1;
        case 'admit': return this.letIn(id, ctx.clock, st.took ? 'read' : 'nod');
        case 'refuse': return this.turn(id, ctx.clock, 'refused');
        case 'keep': {
          if (!st.variant || st.variant === 'phone') return this.turn(id, ctx.clock, 'refused');
          const owner = ownerOf(this.town, p, st.variant);
          const k = { id: id, variant: st.variant, at: ctx.clock, owner: owner.id, back: false };
          this.kept.push(k);
          this.n.kept++;
          // A brother's or sister's licence: they'll want it back, tonight, if they're out
          if (owner !== p && !(this.rec[owner.id] && this.rec[owner.id].did === 'left')) {
            const r = this.rngFor('owner:' + owner.id);
            this.addLater(ctx.clock + r.int(25, 55), owner.id, 'card');
          }
          return this.turn(id, ctx.clock, 'kept');
        }
        case 'give': {
          // the kept card, back to whose it is
          const i = this.keptFor(id);
          if (i === -1) return 0;
          this.kept[i].back = true;
          return 1;
        }
        case 'back': {
          // gone to get it from the truck: back at the end of the line in a few minutes, card and
          // all; a teenager with nothing to get doesn't come back
          const r = this.rngFor('back:' + id);
          if (p.teen && st.variant === '') {
            this.rec[id] = { did: 'left', at: ctx.clock };
            this.n.left++;
          } else this.addLater(ctx.clock + r.int(3, 8), id, 'back');
          this.cur = '';
          return 1;
        }
        case 'wave': {
          // the rest of the party, in behind the one at the front, on the nod
          const a = this.groupOf(id);
          let k = 0;
          while (a && this.line.length && a.who.indexOf(this.line[0].id) !== -1) {
            const l = this.line.shift();
            this.rec[l.id] = { did: 'in', at: ctx.clock, how: 'wave' };
            this.n.in++;
            this.n.waved++;
            if (this.person(l.id).teen) { this.rec[l.id].minor = true; this.n.minors++; }
            this.meetQuiet(l.id, 'in');
            k++;
          }
          return k;
        }
      }
      return 0;
    }

    addLater(at, id, why) {
      const l = { at: at, id: id, why: why };
      let i = 0;
      while (i < this.later.length && (this.later[i].at < at || (this.later[i].at === at && this.later[i].id < id))) i++;
      this.later.splice(i, 0, l);
    }

    // a glance at a card: whether he sees what's wrong with it
    notice(ctx) {
      const p = this.person(this.cur);
      const v = this.st.variant;
      const c = this.card();
      let base = 0;
      if (v === 'sib') base = this.has('owner_met') ? 0.85 : this.has('owner_in') ? 0.55 : 0.25;
      else if (v === 'lifted') base = 0.2;
      else if (v === 'printed') base = 0.35;
      else if (c && c.expired) base = 0.45;
      else return false;
      const s = ctx.stats || {};
      let odds = base + 0.04 * (((s.wis | 0) + (s.gut | 0)) - 8) - 0.06 * (ctx.felt | 0);
      if (p.teen && p.age <= 16) odds += 0.3;
      odds = Math.max(0.03, Math.min(0.97, odds));
      return chance(this.rngFor('glance:' + this.cur), odds);
    }

    // Holding the card up by the face: what he sees. "match", or what's off: "eyes", "height",
    // "older" (the card's face is somebody older), "young" (the face is younger than the card says)
    look(ctx) {
      const p = this.person(this.cur);
      const c = this.card();
      if (!c) return 0;
      const v = this.st.variant;
      let r = 'match';
      if (c.eyes !== p.eyes) r = 'eyes';
      else if (Math.abs(c.height - p.height) >= 6) r = 'height';
      else if (v === 'sib') r = 'older';
      else if (p.teen && (v === 'lifted' || v === 'printed' || v === 'phone')) r = 'young';
      this.st.looked = r;
      return r === 'match' ? 1 : 0;
    }

    // what the card shows when it's handled: tipped under the light (tilt), turned over (flip)
    handle(what) {
      const c = this.card();
      const st = this.st;
      if (what === 'tilt') {
        st.tilted = !c ? 'none' : c.printed ? 'still' : c.lifted ? 'ridge' : 'moves';
        return st.tilted;
      }
      if (what === 'flip') {
        st.flipped = !c ? 'none' : c.printed ? (c.scans ? 'barcode' : 'blank') : 'barcode';
        return st.flipped;
      }
      if (what === 'look') {
        this.look({});
        return st.looked;
      }
      return '';
    }

    letIn(id, clock, how) {
      const p = this.person(id);
      this.rec[id] = { did: 'in', at: clock, how: how };
      this.n.in++;
      if (p.teen) { this.n.minors++; this.rec[id].minor = true; }
      this.meet(id, 'in');
      this.cur = '';
      return 1;
    }

    turn(id, clock, did) {
      this.rec[id] = { did: did, at: clock };
      this.n.refused++;
      if (this.person(id).teen) this.n.caught++;
      this.meet(id, did);
      this.cur = '';
      return 1;
    }

    // what he's dealt with them over, for the next time; and the name on the card he read
    meet(id, did) {
      const m = this.met[id] || (this.met[id] = { day: this.day, did: did, name: '', rapport: false, tag: '' });
      m.day = this.day;
      m.did = did;
      m.tag = this.tag(id);
      if (this.st.took && this.st.variant && this.st.variant !== 'phone') {
        const c = this.card();
        if (c) m.name = title(c.given.split(' ')[0]);
      }
      if (this.st.chat) m.rapport = true;
    }

    // one of a party he waved in: he's seen them, no more
    meetQuiet(id, did) {
      const m = this.met[id] || (this.met[id] = { day: this.day, did: did, name: '', rapport: false, tag: '' });
      m.day = this.day;
      m.did = did;
      m.tag = this.tag(id);
    }

    // A teenager he let in, found at the bar by Paige: the id, or "" if there's nobody she'd find
    // yet. She finds them half an hour or more after they got past him.
    find(clock) {
      for (const id in this.rec) {
        const r = this.rec[id];
        if (!r.minor || r.found || (r.did !== 'in' && r.did !== 'slipped') || clock < r.at + 30) continue;
        r.found = clock;
        this.n.found++;
        this.other = id;
        return 1;
      }
      this.other = '';
      return 0;
    }

    // a question about the card, and how they answer it
    ask(q, ctx) {
      const st = this.st;
      const p = this.person(this.cur);
      const c = this.card();
      if (!c) return 0;
      const me = this.info(this.cur);
      st.asked[q] = true;
      st.last = q;
      st.slip = '';
      const r = this.rngFor('ask:' + this.cur + ':' + q);
      const v = st.variant;
      const bc = civilFromDays(parseIso(c.born));
      const real = civilFromDays(parseIso(p.born));
      let hes = me.drunk >= 2 && chance(r, 0.35);
      let says = '';
      if (q === 'middle') {
        says = c.given.split(' ').slice(1).join(' ');
        if (v === 'sib') hes = hes || chance(r, 0.25);
      } else if (q === 'birthday') {
        says = MONTHS[bc[1] - 1] + ' ' + bc[2];
        if (v === 'sib') hes = hes || chance(r, 0.4);
      } else if (q === 'sign') {
        says = signOf(bc[1], bc[2]);
        if (v === 'sib') {
          // their own sign comes out first, or they have to work the card's out
          if (chance(r, 0.5)) says = signOf(real[1], real[2]);
          else hes = true;
        }
        if (v === 'printed' && chance(r, 0.2)) hes = true;
      } else if (q === 'postal') {
        const T = this.C.town;
        const code = postalOf(T, c.address);
        says = code;
        const homeCode = T.areas[this.town.household(p).area].postal;
        // the card's from where the brother or sister lives, which may not be home; an old address
        // on their own card, and they say where they live now
        if (v === 'sib' && homeCode !== code && chance(r, 0.6)) says = homeCode;
        if (c.address.old && v === 'own') says = homeCode;
      } else if (q === 'year') {
        says = String(bc[0]);
        if (v === 'sib') { hes = hes || chance(r, 0.5); if (chance(r, 0.2)) says = String(real[0]); }
        if (v === 'lifted' && chance(r, 0.35)) st.slip = String(real[0]);
      }
      st.said = says;
      st.hes = hes;
      st.wrong = this.wrongAnswer(q, says, c);
      return st.wrong ? 0 : 1;
    }

    wrongAnswer(q, says, c) {
      const bc = civilFromDays(parseIso(c.born));
      if (q === 'middle') return says !== c.given.split(' ').slice(1).join(' ');
      if (q === 'birthday') return says !== MONTHS[bc[1] - 1] + ' ' + bc[2];
      if (q === 'sign') return says !== signOf(bc[1], bc[2]);
      if (q === 'year') return says !== String(bc[0]);
      if (q === 'postal') return says !== postalOf(this.C.town, c.address);
      return false;
    }

    // The scanner on the ledge: it reads the barcode on the back, keeps it with the time, and says
    // so: ok (green), red (it can't read it), real (it reads a date that isn't the one on the
    // front), seen (it's had this card tonight), expired, oop (from away: it reads, and it doesn't
    // know what it's reading)
    scan(ctx) {
      const st = this.st;
      const c = this.card();
      this.n.scanned++;
      if (!c || st.variant === 'phone') { st.scanned = 'red'; return 0; }
      const seen = this.scans[c.number];
      this.scans[c.number] = ctx.clock;
      if (c.printed) st.scanned = c.scans ? 'ok' : 'red';
      else if (c.lifted) st.scanned = 'real';
      else if (seen !== undefined) { st.scanned = 'seen'; st.seenAt = seen; }
      else if (c.expired) st.scanned = 'expired';
      else if (c.prov !== 'BC') st.scanned = 'oop';
      else st.scanned = 'ok';
      return st.scanned === 'ok' || st.scanned === 'oop' ? 1 : 0;
    }

    // what the page needs to draw the line through the glass, and the one at the front
    view() {
      const self = this;
      const one = function (id) { const p = self.person(id); return { id: id, label: self.label(id), look: p.look, teen: !!p.teen, drunk: self.info(id).drunk }; };
      return {
        day: this.day,
        front: this.cur ? one(this.cur) : null,
        line: this.line.map(function (l) { return one(l.id); }),
        n: Object.assign({}, this.n)
      };
    }

    // ---- what's said

    // who the one in front of him talks like (content/rules/door.yaml, registers)
    reg(p) {
      if (p.teen) return 'teen';
      if (p.age <= 25) return 'kid';
      if (p.group === 'old' || p.group === 'vets') return 'old';
      if (p.group === 'mill' || p.group === 'trades' || p.group === 'out') return 'work';
      if (p.group === 'hospital' || p.group === 'harbour' || p.group === 'strip') return p.group;
      return 'town';
    }

    facts(id) {
      const p = this.person(id);
      const me = this.info(id);
      const front = id === this.cur || (!this.cur && id === this.last);
      const st = front ? this.st : {};
      const c = front ? shownCard(this.town, p, st.variant) : null;
      const m = this.met[id];
      return {
        reg: this.reg(p), sex: p.sex, age: p.age, drunk: me.drunk, wave: me.wave, known: !!m, was: m ? m.did : '', rapport: !!(m && m.rapport),
        group: p.group, work: p.work, detail: p.detail, fake: !!p.tries, kind: front ? st.variant : '', hes: !!st.hes, wrong: !!st.wrong,
        noid: front && !st.variant, expired: !!(c && c.expired), oop: !!(c && c.prov !== 'BC'), idcard: !!(c && c.type === 'id'),
        slip: !!st.slip, n: this.line.length, regular: p.regular, scan: st.scanned || '', caught: !!st.caught, together: front && this.together(),
        took: !!st.took, waited: st.waited | 0, why: st.why || '', looked: st.looked || '', tilted: st.tilted || '', flipped: st.flipped || '',
        teen: !!p.teen, retired: p.retiredFrom || '', cast: p.castTie ? p.castTie.cast : '', partner: !!p.partner,
        asked: !!st.asked && Object.keys(st.asked).length > 0, behind: !!st.behind
      };
    }

    // the best line for an event: the most particular rule that fits and hasn't been said
    pick(on, id, extra) {
      const L = (this.C.door && this.C.door.lines) || [];
      const f = this.facts(id);
      if (extra) for (const k in extra) f[k] = extra[k];
      let best = [];
      let bestScore = -1e9;
      let bestUsed = true;
      for (let i = 0; i < L.length; i++) {
        const r = L[i];
        if (r.on !== on || !matches(r, f)) continue;
        const at = r.free ? -1 : this.used.indexOf(lineId(r));
        const used = at !== -1;
        // an unsaid line beats a said one, and the more particular the better; once they've all
        // been said, the one said longest ago
        const score = used ? -at : specificity(r);
        if (bestUsed && !used) { best = [r]; bestScore = score; bestUsed = false; continue; }
        if (used && !bestUsed) continue;
        if (score > bestScore) { best = [r]; bestScore = score; } else if (score === bestScore) best.push(r);
      }
      if (!best.length) return null;
      const r = best.length === 1 ? best[0] : best[this.rngFor('line:' + on + ':' + id + ':' + this.used.length).int(0, best.length - 1)];
      if (!r.free) {
        const at = this.used.indexOf(lineId(r));
        if (at !== -1) this.used.splice(at, 1);
        this.used.push(lineId(r));
      }
      return r;
    }

    // a line for the one in front of him (or who just was, or whoever the Ink's talking about), filled in
    say(on, id) {
      id = id || this.cur || this.last;
      if (!id) return '';
      const r = this.pick(on, id);
      return r ? this.fill(r.text, id) : '';
    }

    // what goes into a line's {braces}
    fill(text, id) {
      const p = this.person(id);
      const self = this;
      const front = id === this.cur || (!this.cur && id === this.last);
      const st = front ? this.st : {};
      const c = front ? shownCard(this.town, p, st.variant) : null;
      return String(text).replace(/\{([a-zA-Z_]+)(\|lc)?\}/g, function (m, k, lc) {
        const x = self.value(k, p, st, c);
        return x === undefined ? m : lc ? String(x).toLowerCase() : x;
      });
    }

    value(k, p, st, c) {
      const he = p.sex === 'f' ? 'she' : 'he', him = p.sex === 'f' ? 'her' : 'him', his = p.sex === 'f' ? 'her' : 'his';
      const L = p.look;
      const D = this.C.people;
      const T = this.C.door || {};
      const det = (D.details[p.detail] || D.life_details.list[p.detail]) || {};
      switch (k) {
        case 'he': return he;
        case 'him': return him;
        case 'his': return his;
        case 'hers': return p.sex === 'f' ? 'hers' : 'his';
        case 'He': return cap(he);
        case 'His': return cap(his);
        case 'tag': return this.tag(p.id);
        case 'label': return this.label(p.id);
        case 'given': return p.given;
        case 'name': return p.given + ' ' + p.surname;
        case 'surname': return p.surname;
        case 'age': return words(Math.min(99, p.age));
        case 'Age': return cap(words(Math.min(99, p.age)));
        case 'a_person': return personWord(p, true);
        case 'A_person': return cap(personWord(p, true));
        case 'the_person': return personWord(p, false);
        case 'The_person': return cap(personWord(p, false));
        case 'in_top': return fillPron(topOf(T.wear || {}, L) || 'in a coat', p);
        case 'with_hat': return L.hat && (T.hats || {})[L.hat] ? ' ' + fillPron(T.hats[L.hat], p) : '';
        case 'detail_see': return fillPron(det.see || '', p);
        case 'detail_read': return fillPron(det.read || '', p);
        case 'Detail_see': return cap(fillPron(det.see || '', p));
        case 'Detail_read': return cap(fillPron(det.read || '', p));
        case 'met_when': { const m = this.met[p.id]; return !m ? '' : m.day === this.day ? 'earlier tonight' : m.day === 1 ? 'on Wednesday' : 'the other night'; }
        case 'teen_sib': {
          // to the one come for their licence: the brother or sister who had it
          for (const x of this.kept) if (x.owner === p.id) return this.person(x.id).sex === 'f' ? 'sister' : 'brother';
          return 'brother';
        }
        case 'does': return (D.works[p.work] || {}).does || '';
        case 'work_name': return (D.works[p.work] || {}).name || '';
        case 'n': return words(Math.min(99, this.line.length));
        case 'N': return cap(words(Math.min(99, this.line.length)));
        case 'others': return this.others(p.id);
        case 'prev': return st.prev ? personWord(this.person(st.prev), false) : '';
        case 'party': return words(Math.min(99, this.party()));
        case 'waited': return minutesWords(st.waited | 0);
        case 'said': return st.said || '';
        case 'slip': return st.slip ? yearWords(+st.slip, false) : '';
        case 'seen_at': return st.seenAt !== undefined ? B.util.fmtClock(st.seenAt) : '';
        case 'tie': return p.castTie ? fillPron(p.castTie.text, p) : '';
        case 'street': { const h = this.town.household(p); const s = streetOf(this.C.town, h.street); return s ? s.name : ''; }
      }
      if (k === 'owner_given' || k === 'owner_name' || k === 'owner_when' || k === 'owner_sib') {
        const o = p.tries && p.tries.from ? this.person(p.tries.from) : null;
        if (!o) return '';
        if (k === 'owner_given') return o.given;
        if (k === 'owner_name') return o.given + ' ' + o.surname;
        if (k === 'owner_sib') return o.sex === 'f' ? 'sister' : 'brother';
        const m = this.met[o.id];
        if (!m) return '';
        return m.day === this.day ? 'tonight' : m.day === this.day - 2 ? 'on Wednesday' : 'the other night';
      }
      if (!c) return undefined;
      const bc = civilFromDays(parseIso(c.born));
      const said = st.said || '';
      const sp = said.split(' ');
      const dated = said && MONTHS.indexOf(sp[0]) !== -1;
      switch (k) {
        case 'middle': return title(said);
        case 'month': return dated ? sp[0] : MONTHS[bc[1] - 1];
        case 'day_ord': return dated ? ORD[+sp[1]] : ORD[bc[2]];
        case 'day_num': return dated ? sp[1] : String(bc[2]);
        case 'sign': return said;
        case 'year_long': return yearWords(+said || bc[0], false);
        case 'year_short': return yearWords(+said || bc[0], true);
        case 'postal_said': return said ? postalWords(said) : '';
        case 'card_name': return title(c.given.split(' ')[0]) + ' ' + title(c.surname);
        case 'card_given': return title(c.given.split(' ')[0]);
        case 'card_middle': return title(c.given.split(' ').slice(1).join(' '));
        case 'card_age': return words(Math.min(99, yearsBetween(parseIso(c.born), this.town.tonight)));
        case 'card_year': return yearWords(bc[0], false);
        case 'card_month': return MONTHS[bc[1] - 1];
        case 'card_day': return ORD[bc[2]];
        case 'card_sign': return signOf(bc[1], bc[2]);
        case 'card_postal': return postalWords(postalOf(this.C.town, c.address));
        case 'card_eyes': return EYES[c.eyes] || 'brown';
        case 'eyes': return EYES[p.eyes] || 'brown';
        case 'card_height': return words(Math.floor(c.height / 100)) + ' ' + words(c.height % 100);
        case 'card_expired': { const e = civilFromDays(parseIso(c.expires)); return MONTHS[e[1] - 1] + (e[0] !== civilFromDays(this.town.tonight)[0] ? ' ' + yearWords(e[0], false) : ''); }
        case 'real_age': return words(Math.min(99, p.age));
      }
      return undefined;
    }

    // who's with them, still in the line: "a woman in a fleece and a kid in a hoodie"
    others(id) {
      const a = this.groupOf(id);
      if (!a || a.who.length < 2) return '';
      const waiting = {};
      for (const l of this.line) waiting[l.id] = true;
      const rest = a.who.filter(function (x) { return x !== id && waiting[x]; });
      const T = this.C.door || {};
      const self = this;
      return listWords(rest.map(function (x) { const q = self.person(x); return personWord(q, true) + ' ' + fillPron(topOf(T.wear || {}, q.look) || 'in a coat', q); }));
    }
  }

  function lineId(r) { return r.on + ':' + B.util.hash32(r.text).toString(36); }

  // what a table keyed by top says of someone's: by "top:material" first, then the top's own
  function topOf(table, L) { return table[L.top + ':' + L.top_mat] || table[L.top]; }

  // what a line in door.yaml can ask of who it's for, besides `on`
  const CONDS = ['reg', 'sex', 'drunk', 'sober', 'known', 'was', 'rapport', 'fake', 'kind', 'wave', 'ages', 'hes', 'wrong', 'noid', 'expired',
    'oop', 'idcard', 'slip', 'group', 'work', 'detail', 'n', 'regular', 'scan', 'caught', 'together', 'took', 'waited', 'why', 'looked',
    'tilted', 'flipped', 'teen', 'retired', 'cast', 'partner', 'asked', 'behind'];

  // how particular a line is: a point for each thing it asks, and its rank on top
  function specificity(r) {
    let s = r.rank | 0;
    for (const k of CONDS) if (r[k] !== undefined) s++;
    return s;
  }

  function oneOf(want, have) { return Array.isArray(want) ? want.indexOf(have) !== -1 : want === have; }
  function within(r, v) { return v >= r[0] && v <= r[1]; }

  function matches(r, f) {
    if (r.reg !== undefined && !oneOf(r.reg, f.reg)) return false;
    if (r.sex !== undefined && r.sex !== f.sex) return false;
    if (r.drunk !== undefined && f.drunk < r.drunk) return false;
    if (r.sober !== undefined && (f.drunk === 0) !== r.sober) return false;
    if (r.known !== undefined && f.known !== r.known) return false;
    if (r.was !== undefined && !oneOf(r.was, f.was)) return false;
    if (r.rapport !== undefined && f.rapport !== r.rapport) return false;
    if (r.fake !== undefined && f.fake !== r.fake) return false;
    if (r.kind !== undefined && !oneOf(r.kind, f.kind)) return false;
    if (r.wave !== undefined && !oneOf(r.wave, f.wave)) return false;
    if (r.ages !== undefined && !within(r.ages, f.age)) return false;
    if (r.hes !== undefined && f.hes !== r.hes) return false;
    if (r.wrong !== undefined && f.wrong !== r.wrong) return false;
    if (r.noid !== undefined && f.noid !== r.noid) return false;
    if (r.expired !== undefined && f.expired !== r.expired) return false;
    if (r.oop !== undefined && f.oop !== r.oop) return false;
    if (r.idcard !== undefined && f.idcard !== r.idcard) return false;
    if (r.slip !== undefined && f.slip !== r.slip) return false;
    if (r.group !== undefined && !oneOf(r.group, f.group)) return false;
    if (r.work !== undefined && !oneOf(r.work, f.work)) return false;
    if (r.detail !== undefined && !oneOf(r.detail, f.detail)) return false;
    if (r.n !== undefined && !within(r.n, f.n)) return false;
    if (r.regular !== undefined && !oneOf(r.regular, f.regular)) return false;
    if (r.scan !== undefined && !oneOf(r.scan, f.scan)) return false;
    if (r.caught !== undefined && f.caught !== r.caught) return false;
    if (r.together !== undefined && f.together !== r.together) return false;
    if (r.took !== undefined && f.took !== r.took) return false;
    if (r.waited !== undefined && !within(r.waited, f.waited)) return false;
    if (r.why !== undefined && !oneOf(r.why, f.why)) return false;
    if (r.looked !== undefined && !oneOf(r.looked, f.looked)) return false;
    if (r.tilted !== undefined && !oneOf(r.tilted, f.tilted)) return false;
    if (r.flipped !== undefined && !oneOf(r.flipped, f.flipped)) return false;
    if (r.teen !== undefined && f.teen !== r.teen) return false;
    if (r.retired !== undefined && !oneOf(r.retired, f.retired)) return false;
    if (r.cast !== undefined && !oneOf(r.cast, f.cast)) return false;
    if (r.partner !== undefined && f.partner !== r.partner) return false;
    if (r.asked !== undefined && f.asked !== r.asked) return false;
    if (r.behind !== undefined && f.behind !== r.behind) return false;
    return true;
  }

  // "a man", "an old woman", "a girl"; or "the man"
  function personWord(p, a) {
    let w = p.sex === 'f' ? 'woman' : 'man';
    if (p.teen || p.age <= 21) w = p.sex === 'f' ? 'girl' : 'kid';
    else if (p.age >= 65) w = 'old ' + w;
    if (!a) return 'the ' + w;
    return (/^[aeiou]/.test(w) ? 'an ' : 'a ') + w;
  }

  function fillPron(s, p) {
    const he = p.sex === 'f' ? 'she' : 'he', him = p.sex === 'f' ? 'her' : 'him', his = p.sex === 'f' ? 'her' : 'his';
    return String(s).replace(/\{his\}/g, his).replace(/\{he\}/g, he).replace(/\{him\}/g, him);
  }

  function listWords(xs) {
    if (xs.length <= 1) return xs.join('');
    return xs.slice(0, -1).join(', ') + ' and ' + xs[xs.length - 1];
  }

  function ageBand(p) { return p.age < 30 ? 'young' : (p.age < 60 ? 'mid' : 'old'); }

  // a birthday at least ten months from every other child's in the family
  function spaced(kids, born) {
    for (const k of kids) if (Math.abs(k - born) < 300) return false;
    return true;
  }

  function make(seed, content) { return new Maker(seed, content).run(); }

  Folk.make = make;
  Folk.night = night;
  Folk.Door = Door;
  Folk.cardProp = cardProp;
  Folk.shownCard = shownCard;
  Folk.variantOf = variantOf;
  Folk.QUESTIONS = QUESTIONS;
  Folk.say = { words: words, yearWords: yearWords, numberWords: numberWords, signOf: signOf, postalWords: postalWords, minutesWords: minutesWords };
  Folk.dates = { daysFromCivil: daysFromCivil, civilFromDays: civilFromDays, iso: iso, parseIso: parseIso, sameDay: sameDay, yearsBetween: yearsBetween };
  Folk.weighted = weighted;
  Folk.fits = fits;
  Folk.ageBand = ageBand;
  B.Folk = Folk;
})(globalThis.Bouncer = globalThis.Bouncer || {});
