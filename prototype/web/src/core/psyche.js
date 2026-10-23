// The room in his head: the relational psyche from bible/02_SYSTEMS.md (PROPOSED).
//
// Up to five voices sit in the room. Every pair of voices is allied (+1) or at odds (-1).
// No voice has a level. Tension is the frustration index of the seated voices: the fewest
// conflicts left after any combination of voices reversing all their loyalties. It runs 0-4
// for five voices. With exactly five seated, the room is one of the 34 states in
// data/psyche_states.json (generated and checked by tools/psyche_census.py).
(function (B) {
  'use strict';

  const MAX_SEATS = 5;

  function pairKey(a, b) { return a < b ? a + '|' + b : b + '|' + a; }

  function permutations(n) {
    const out = [];
    const a = [];
    for (let i = 0; i < n; i++) a.push(i);
    (function rec(k) {
      if (k === n) { out.push(a.slice()); return; }
      for (let i = k; i < n; i++) {
        [a[k], a[i]] = [a[i], a[k]];
        rec(k + 1);
        [a[k], a[i]] = [a[i], a[k]];
      }
    })(0);
    return out;
  }
  const PERMS5 = permutations(5);

  // Canonical string for a set of conflict pairs on 5 labeled points, up to relabeling.
  function canonConflicts(pairs) {
    let best = null;
    for (const p of PERMS5) {
      const mapped = pairs.map(function (e) {
        const x = p[e[0]], y = p[e[1]];
        return x < y ? x * 5 + y : y * 5 + x;
      }).sort(function (u, v) { return u - v; }).join(',');
      if (best === null || mapped < best) best = mapped;
    }
    return best === null ? '' : best;
  }

  class Psyche {
    constructor(voiceDefs, statesData) {
      this.defs = voiceDefs || {};
      this.seated = [];
      this.rel = {};          // explicit relationships, set in play; defaults come from the voice data
      this.learned = [];      // voices he has, in the room or not
      this.history = [];      // tension over the night, for the inspector
      this.heard = {};        // voice -> how many of its reads of a thing in his hand he's kept (heed)
      this.stateIndex = {};
      if (statesData && statesData.states) {
        for (const s of statesData.states) this.stateIndex[canonConflicts(s.conflicts)] = s;
        this.classes = {};
        for (const c of statesData.classes || []) this.classes[c.class] = c;
      }
    }

    reset(initialSeated) {
      this.seated = [];
      this.rel = {};
      this.learned = [];
      this.history = [];
      this.heard = {};
      for (const id of initialSeated || []) { this.learn(id); this.seat(id); }
    }

    known(id) { return Object.prototype.hasOwnProperty.call(this.defs, id); }

    learn(id) {
      if (!this.known(id)) return false;
      if (this.learned.indexOf(id) === -1) this.learned.push(id);
      return true;
    }

    isSeated(id) { return this.seated.indexOf(id) !== -1; }
    isFull() { return this.seated.length >= MAX_SEATS; }

    seat(id) {
      if (!this.known(id) || this.isSeated(id) || this.isFull()) return false;
      this.learn(id);
      this.seated.push(id);
      return true;
    }

    unseat(id) {
      const i = this.seated.indexOf(id);
      if (i === -1) return false;
      this.seated.splice(i, 1);
      return true;
    }

    // He kept this voice's read of a thing in his hand (content/ink/hand.ink): the voices he heeds
    // speak more often (Barks.best, Barks.pick).
    heed(id) {
      if (!this.known(id)) return false;
      this.heard[id] = (this.heard[id] | 0) + 1;
      return true;
    }

    heeded(id) { return this.heard[id] | 0; }

    getRel(a, b) {
      if (a === b) return 1;
      const k = pairKey(a, b);
      if (Object.prototype.hasOwnProperty.call(this.rel, k)) return this.rel[k];
      const da = this.defs[a], db = this.defs[b];
      if (da && da.relations && da.relations[b] !== undefined) return da.relations[b] < 0 ? -1 : 1;
      if (db && db.relations && db.relations[a] !== undefined) return db.relations[a] < 0 ? -1 : 1;
      return 1;
    }

    setRel(a, b, sign) {
      if (!this.known(a) || !this.known(b) || a === b) return false;
      this.rel[pairKey(a, b)] = sign < 0 ? -1 : 1;
      return true;
    }

    // Frustration index over the seated voices.
    tension(seatedOverride) {
      const s = seatedOverride || this.seated;
      const n = s.length;
      if (n < 3) return 0;
      const sign = [];
      for (let i = 0; i < n; i++) {
        sign.push([]);
        for (let j = 0; j < n; j++) sign[i].push(i === j ? 1 : this.getRel(s[i], s[j]));
      }
      let best = Infinity;
      // Switching every voice is the same as switching none, so fix voice 0.
      for (let mask = 0; mask < (1 << (n - 1)); mask++) {
        const bits = mask << 1;
        let neg = 0;
        for (let i = 0; i < n; i++) {
          for (let j = i + 1; j < n; j++) {
            const flip = ((bits >> i) & 1) !== ((bits >> j) & 1);
            const v = flip ? -sign[i][j] : sign[i][j];
            if (v < 0) neg++;
          }
        }
        if (neg < best) best = neg;
      }
      return best;
    }

    conflicts() {
      const out = [];
      const s = this.seated;
      for (let i = 0; i < s.length; i++)
        for (let j = i + 1; j < s.length; j++)
          if (this.getRel(s[i], s[j]) < 0) out.push([s[i], s[j]]);
      return out;
    }

    // With five seated: which of the 34 states the room is in.
    state() {
      const t = this.tension();
      if (this.seated.length !== MAX_SEATS || !this.stateIndex) return { tension: t, id: null, cls: null, seats: this.seated.length };
      const idx = {};
      this.seated.forEach(function (v, i) { idx[v] = i; });
      const pairs = this.conflicts().map(function (c) { return [idx[c[0]], idx[c[1]]]; });
      const st = this.stateIndex[canonConflicts(pairs)] || null;
      return { tension: t, id: st ? st.id : null, cls: st ? st.class : null, note: st ? st.note || '' : '', seats: 5 };
    }

    record(clock) {
      const t = this.tension();
      const last = this.history[this.history.length - 1];
      if (!last || last.t !== t || last.seats !== this.seated.length) this.history.push({ clock: clock, t: t, seats: this.seated.length });
      if (this.history.length > 200) this.history.shift();
    }

    toJSON() {
      return { seated: this.seated.slice(), rel: Object.assign({}, this.rel), learned: this.learned.slice(), history: this.history.slice(-100), heard: Object.assign({}, this.heard) };
    }

    fromJSON(o) {
      if (!o) return;
      this.seated = (o.seated || []).filter(this.known.bind(this)).slice(0, MAX_SEATS);
      this.rel = Object.assign({}, o.rel || {});
      this.learned = (o.learned || []).filter(this.known.bind(this));
      this.history = (o.history || []).slice();
      this.heard = {};
      for (const id in (o.heard || {})) if (this.known(id)) this.heard[id] = o.heard[id] | 0;
    }
  }

  Psyche.MAX_SEATS = MAX_SEATS;
  Psyche.pairKey = pairKey;
  Psyche.canonConflicts = canonConflicts;
  B.Psyche = Psyche;
})(globalThis.Bouncer = globalThis.Bouncer || {});
