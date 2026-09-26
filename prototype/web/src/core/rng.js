// Seeded random numbers for checks. The state is saved with the game, so
// closing the tab and reopening it cannot re-roll a check.
(function (B) {
  'use strict';

  class Rng {
    constructor(seed) {
      this.seed = (seed >>> 0) || 1;
      this.state = this.seed;
      this.calls = 0;
    }
    // mulberry32
    next() {
      this.calls++;
      let t = (this.state = (this.state + 0x6d2b79f5) >>> 0);
      t = Math.imul(t ^ (t >>> 15), t | 1);
      t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    }
    int(lo, hi) { return lo + Math.floor(this.next() * (hi - lo + 1)); }
    d6() { return this.int(1, 6); }
    pick(arr) { return arr.length ? arr[this.int(0, arr.length - 1)] : undefined; }
    getState() { return { seed: this.seed, state: this.state, calls: this.calls }; }
    setState(s) {
      if (!s) return;
      this.seed = s.seed >>> 0;
      this.state = s.state >>> 0;
      this.calls = s.calls | 0;
    }
  }

  Rng.freshSeed = function () {
    return (Date.now() ^ Math.floor(Math.random() * 0xffffffff)) >>> 0;
  };

  B.Rng = Rng;
})(globalThis.Bouncer = globalThis.Bouncer || {});
