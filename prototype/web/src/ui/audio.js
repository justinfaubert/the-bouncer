// Sound. Every cue the Ink fires is a slot in content/data/assets.yaml. When a slot's file is
// there, it plays the file. Until then it plays a small synthesized stand-in (the recipes
// below), or nothing, for music. Browsers only allow sound after the player has clicked
// something, so nothing here starts until unlock() is called from a click.
(function (B) {
  'use strict';

  const FADE = 1.6;

  class Audio {
    constructor(assets, base) {
      this.assets = assets || {};
      this.base = base || '';
      this.ctx = null;
      this.enabled = true;
      this.levels = { master: 0.8, amb: 0.6, sfx: 0.8, music: 0.6 };
      this.amb = { id: null, stop: null };
      this.music = { id: null, el: null };
      this._noise = null;
      this._brown = null;
    }

    // ---- setup -----------------------------------------------------------

    unlock() {
      if (this.ctx) {
        if (this.ctx.state === 'suspended') this.ctx.resume().catch(function () {});
        return;
      }
      const AC = globalThis.AudioContext || globalThis.webkitAudioContext;
      if (!AC) return;
      try { this.ctx = new AC(); } catch (e) { this.ctx = null; return; }
      const c = this.ctx;
      this.out = c.createGain();
      this.out.connect(c.destination);
      this.bus = { amb: c.createGain(), sfx: c.createGain(), music: c.createGain() };
      for (const k in this.bus) this.bus[k].connect(this.out);
      this._apply();
      if (this._wantAmb) { const id = this._wantAmb; this._wantAmb = null; this.ambience(id); }
    }

    setLevels(levels, enabled) {
      Object.assign(this.levels, levels || {});
      this.enabled = enabled !== false;
      this._apply();
    }

    _apply() {
      if (!this.ctx) return;
      const t = this.ctx.currentTime;
      this.out.gain.setTargetAtTime(this.enabled ? this.levels.master : 0, t, 0.05);
      this.bus.amb.gain.setTargetAtTime(this.levels.amb * (this._duck || 1), t, 0.05);
      this.bus.sfx.gain.setTargetAtTime(this.levels.sfx, t, 0.05);
      this.bus.music.gain.setTargetAtTime(this.levels.music, t, 0.05);
      if (this.music.el) this.music.el.volume = this.enabled ? this.levels.master * this.levels.music : 0;
    }

    _slot(group, id) {
      const g = this.assets[group] || {};
      return g[id] || null;
    }

    _url(slot) { return slot && slot.file && slot.present ? this.base + slot.file : null; }

    // ---- the three channels ----------------------------------------------

    // vol (0 to 1, default 1) is for cues that come in runs, like a die slowing down
    sfx(id, vol) {
      if (!this.ctx || !this.enabled) return;
      const v = vol == null ? 1 : Math.max(0, Math.min(1, vol));
      const slot = this._slot('sfx', id);
      const url = this._url(slot);
      if (url) {
        const el = new globalThis.Audio(url);
        el.volume = this.levels.master * this.levels.sfx * v;
        el.play().catch(function () {});
        return;
      }
      const recipe = SFX[(slot && slot.synth) || id];
      if (recipe) { try { recipe(this, this.ctx.currentTime + 0.01, v); } catch (e) { /* a bad recipe is not worth a crash */ } }
    }

    // the room drops away while the dice are in the air, and comes back with the result
    duck(on) {
      this._duck = on ? 0.3 : 1;
      if (!this.ctx) return;
      const g = this.bus.amb.gain, t = this.ctx.currentTime;
      g.cancelScheduledValues(t);
      g.setTargetAtTime(this.levels.amb * this._duck, t, on ? 0.2 : 0.7);
    }

    ambience(id) {
      if (id === 'none') id = null;
      if (!this.ctx) { this._wantAmb = id; return; }
      if (this.amb.id === id) return;
      if (this.amb.stop) this.amb.stop(FADE);
      this.amb = { id: id, stop: null };
      if (!id) return;
      const slot = this._slot('ambience', id);
      const url = this._url(slot);
      if (url) { this.amb.stop = this._loopFile(url, this.bus.amb); return; }
      const recipe = AMB[(slot && slot.synth) || id];
      if (recipe) { try { this.amb.stop = recipe(this); } catch (e) { this.amb.stop = null; } }
    }

    track(id) {
      if (id === 'none') id = null;
      if (this.music.id === id) return;
      const old = this.music.el;
      if (old) this._fadeEl(old);
      this.music = { id: id, el: null };
      if (!id) return;
      const url = this._url(this._slot('music', id));
      if (!url) return; // no stand-in for music: silence until the file is there
      const el = new globalThis.Audio(url);
      el.loop = true;
      el.volume = 0;
      el.play().catch(function () {});
      this.music.el = el;
      const target = () => (this.enabled ? this.levels.master * this.levels.music : 0);
      let v = 0;
      const step = () => { if (this.music.el !== el) return; v = Math.min(target(), v + 0.04); el.volume = v; if (v < target()) setTimeout(step, 80); };
      step();
    }

    stopAll() {
      if (this.amb.stop) this.amb.stop(0.4);
      this.amb = { id: null, stop: null };
      if (this.music.el) this._fadeEl(this.music.el);
      this.music = { id: null, el: null };
    }

    _fadeEl(el) {
      const step = () => { el.volume = Math.max(0, el.volume - 0.05); if (el.volume > 0) setTimeout(step, 80); else el.pause(); };
      step();
    }

    _loopFile(url, bus) {
      const el = new globalThis.Audio(url);
      el.loop = true;
      el.crossOrigin = 'anonymous';
      let node = null;
      try { node = this.ctx.createMediaElementSource(el); } catch (e) { node = null; }
      const g = this.ctx.createGain();
      g.gain.value = 0;
      if (node) { node.connect(g); g.connect(bus); }
      el.play().catch(function () {});
      g.gain.setTargetAtTime(1, this.ctx.currentTime, FADE / 3);
      const ctx = this.ctx;
      return function (fade) {
        g.gain.setTargetAtTime(0, ctx.currentTime, Math.max(0.05, fade / 3));
        setTimeout(function () { el.pause(); try { g.disconnect(); } catch (e) {} }, (fade + 0.5) * 1000);
      };
    }

    // ---- building blocks for the stand-ins -------------------------------

    noise() {
      if (this._noise) return this._noise;
      const c = this.ctx, len = c.sampleRate * 2;
      const buf = c.createBuffer(1, len, c.sampleRate);
      const d = buf.getChannelData(0);
      for (let i = 0; i < len; i++) d[i] = Math.random() * 2 - 1;
      return (this._noise = buf);
    }

    brown() {
      if (this._brown) return this._brown;
      const c = this.ctx, len = c.sampleRate * 3;
      const buf = c.createBuffer(1, len, c.sampleRate);
      const d = buf.getChannelData(0);
      let last = 0;
      for (let i = 0; i < len; i++) { last = (last + 0.02 * (Math.random() * 2 - 1)) / 1.02; d[i] = last * 3.5; }
      return (this._brown = buf);
    }

    // a looping noise source through a filter, into its own gain; returns [source, gain]
    bed(buf, type, freq, q, level, dest) {
      const c = this.ctx;
      const src = c.createBufferSource();
      src.buffer = buf;
      src.loop = true;
      src.loopStart = Math.random();
      const f = c.createBiquadFilter();
      f.type = type; f.frequency.value = freq; f.Q.value = q;
      const g = c.createGain();
      g.gain.value = 0;
      src.connect(f); f.connect(g); g.connect(dest);
      src.start();
      g.gain.setTargetAtTime(level, c.currentTime, FADE / 3);
      return { src: src, gain: g, filter: f };
    }

    hum(freq, level, dest) {
      const c = this.ctx;
      const o = c.createOscillator();
      o.type = 'sine'; o.frequency.value = freq;
      const g = c.createGain();
      g.gain.value = 0;
      o.connect(g); g.connect(dest);
      o.start();
      g.gain.setTargetAtTime(level, c.currentTime, FADE / 3);
      return { src: o, gain: g };
    }

    // a short tone with a quick attack and exponential decay
    tone(t, freq, dur, level, type, dest, glideTo) {
      const c = this.ctx;
      const o = c.createOscillator();
      o.type = type || 'sine';
      o.frequency.setValueAtTime(freq, t);
      if (glideTo) o.frequency.exponentialRampToValueAtTime(glideTo, t + dur);
      const g = c.createGain();
      g.gain.setValueAtTime(0.0001, t);
      g.gain.exponentialRampToValueAtTime(level, t + 0.005);
      g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
      o.connect(g); g.connect(dest || this.bus.sfx);
      o.start(t); o.stop(t + dur + 0.05);
    }

    // a filtered burst of noise
    burst(t, dur, freq, q, level, dest, type) {
      const c = this.ctx;
      const src = c.createBufferSource();
      src.buffer = this.noise();
      const f = c.createBiquadFilter();
      f.type = type || 'bandpass'; f.frequency.value = freq; f.Q.value = q;
      const g = c.createGain();
      g.gain.setValueAtTime(0.0001, t);
      g.gain.exponentialRampToValueAtTime(level, t + 0.004);
      g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
      src.connect(f); f.connect(g); g.connect(dest || this.bus.sfx);
      src.start(t, Math.random()); src.stop(t + dur + 0.05);
    }

    // run fn at random intervals while the ambience lasts; returns a stopper
    every(minS, maxS, fn) {
      let alive = true, timer = null;
      const loop = () => {
        if (!alive) return;
        try { fn(this.ctx.currentTime + 0.02); } catch (e) { /* ignore */ }
        timer = setTimeout(loop, (minS + Math.random() * (maxS - minS)) * 1000);
      };
      timer = setTimeout(loop, (minS + Math.random() * (maxS - minS)) * 1000);
      return function () { alive = false; clearTimeout(timer); };
    }
  }

  function stopper(a, parts, extra) {
    return function (fade) {
      const t = a.ctx.currentTime;
      for (const p of parts) {
        p.gain.gain.cancelScheduledValues(t);
        p.gain.gain.setTargetAtTime(0, t, Math.max(0.05, fade / 3));
        setTimeout(function () { try { p.src.stop(); p.gain.disconnect(); } catch (e) {} }, (fade + 0.6) * 1000);
      }
      for (const x of extra || []) x();
    };
  }

  // Ambience stand-ins. Each starts its layers and returns a stop(fadeSeconds) function.
  const AMB = {
    rain(a) {
      const bus = a.bus.amb;
      const hiss = a.bed(a.noise(), 'bandpass', 1400, 0.5, 0.16, bus);
      const low = a.bed(a.brown(), 'lowpass', 500, 0.7, 0.2, bus);
      const drops = a.every(0.05, 0.25, function (t) { a.burst(t, 0.03, 2500 + Math.random() * 3000, 4, 0.04 + Math.random() * 0.05, bus); });
      return stopper(a, [hiss, low], [drops]);
    },
    rain_open(a) {
      const bus = a.bus.amb;
      const hiss = a.bed(a.noise(), 'bandpass', 900, 0.4, 0.2, bus);
      const low = a.bed(a.brown(), 'lowpass', 300, 0.7, 0.3, bus);
      const drips = a.every(0.3, 1.2, function (t) { a.burst(t, 0.06, 1800 + Math.random() * 800, 6, 0.06, bus); });
      return stopper(a, [hiss, low], [drips]);
    },
    room(a) {
      const bus = a.bus.amb;
      const tone = a.bed(a.brown(), 'lowpass', 260, 0.7, 0.22, bus);
      const cooler = a.hum(60, 0.018, bus);
      const cooler2 = a.hum(120, 0.008, bus);
      const clinks = a.every(4, 11, function (t) {
        a.tone(t, 2400 + Math.random() * 1400, 0.25, 0.025, 'sine', bus);
        if (Math.random() < 0.4) a.tone(t + 0.07, 3100 + Math.random() * 900, 0.2, 0.015, 'sine', bus);
      });
      return stopper(a, [tone, cooler, cooler2], [clinks]);
    },
    room_busy(a) {
      const bus = a.bus.amb;
      const tone = a.bed(a.brown(), 'lowpass', 320, 0.7, 0.26, bus);
      const talk = a.bed(a.noise(), 'bandpass', 520, 1.4, 0.05, bus);
      const lfo = a.ctx.createOscillator();
      const depth = a.ctx.createGain();
      lfo.frequency.value = 0.37; depth.gain.value = 180;
      lfo.connect(depth); depth.connect(talk.filter.frequency); lfo.start();
      const cooler = a.hum(60, 0.015, bus);
      const clinks = a.every(1.5, 5, function (t) { a.tone(t, 2200 + Math.random() * 1800, 0.22, 0.03, 'sine', bus); });
      const balls = a.every(6, 16, function (t) { for (let i = 0; i < 3; i++) a.burst(t + i * (0.05 + Math.random() * 0.08), 0.02, 2600, 3, 0.07, bus); });
      return stopper(a, [tone, talk, cooler], [clinks, balls, function () { try { lfo.stop(); } catch (e) {} }]);
    },
    drip(a) {
      const bus = a.bus.amb;
      const tone = a.bed(a.brown(), 'lowpass', 180, 0.7, 0.18, bus);
      const comp = a.hum(50, 0.02, bus);
      const drips = a.every(1.2, 4.5, function (t) { a.tone(t, 1700 + Math.random() * 500, 0.09, 0.05, 'sine', bus, 700); });
      const scratch = a.every(7, 20, function (t) { for (let i = 0; i < 5; i++) a.burst(t + i * 0.06, 0.035, 3200, 2, 0.03, bus); });
      return stopper(a, [tone, comp], [drips, scratch]);
    },
    room_empty(a) {
      const bus = a.bus.amb;
      const comp = a.hum(60, 0.02, bus);
      const comp2 = a.hum(180, 0.004, bus);
      const air = a.bed(a.brown(), 'lowpass', 150, 0.7, 0.08, bus);
      return stopper(a, [comp, comp2, air]);
    }
  };

  // Sound-effect stand-ins: fn(audio, startTime)
  const SFX = {
    click(a, t) { a.burst(t, 0.012, 3000, 2, 0.3); a.tone(t, 1800, 0.02, 0.08, 'square'); },
    beep_ok(a, t) { a.tone(t, 1450, 0.11, 0.12, 'sine'); },
    beep_bad(a, t) { a.tone(t, 330, 0.18, 0.1, 'square'); a.tone(t + 0.24, 330, 0.18, 0.1, 'square'); },
    bell(a, t) {
      for (const s of [0, 0.5]) {
        a.tone(t + s, 1320, 1.8, 0.14, 'sine');
        a.tone(t + s, 2650, 1.1, 0.05, 'sine');
        a.tone(t + s, 3960, 0.6, 0.03, 'sine');
      }
    },
    thump(a, t) { a.tone(t, 90, 0.25, 0.4, 'sine', null, 40); a.burst(t, 0.08, 300, 0.8, 0.2, null, 'lowpass'); },
    thud(a, t) { a.tone(t, 70, 0.35, 0.5, 'sine', null, 32); a.burst(t, 0.12, 220, 0.7, 0.3, null, 'lowpass'); },
    glass(a, t) { a.tone(t, 3300, 0.3, 0.09, 'sine'); a.tone(t, 4400, 0.18, 0.05, 'sine'); a.burst(t, 0.02, 5000, 3, 0.05); },
    scratch(a, t) { for (let i = 0; i < 7; i++) a.burst(t + i * (0.04 + Math.random() * 0.05), 0.03, 2800 + Math.random() * 1500, 2, 0.08); },
    ring(a, t) {
      for (const s of [0, 0.06, 0.12, 0.18, 0.24, 0.3, 0.36, 0.42]) {
        a.tone(t + s, 440, 0.05, 0.06, 'triangle');
        a.tone(t + s, 480, 0.05, 0.06, 'triangle');
      }
    },
    clack(a, t) { let s = 0; for (let i = 0; i < 6; i++) { a.burst(t + s, 0.015, 2400 + Math.random() * 1200, 3, 0.18); s += 0.03 + Math.random() * 0.09; } },
    till(a, t) { a.tone(t, 2100, 0.5, 0.08, 'sine'); a.burst(t + 0.12, 0.1, 400, 0.8, 0.15, null, 'lowpass'); },
    // the dice: shaken in a loose fist, then over the rubber bar mat
    rattle(a, t, v) {
      for (let k = 0; k < 3; k++) {
        const s = t + k * 0.15 + Math.random() * 0.02;
        a.burst(s, 0.05, 240, 0.7, 0.06 * v, null, 'lowpass');
        for (let i = 0; i < 4; i++) a.burst(s + 0.008 + Math.random() * 0.07, 0.009, 2600 + Math.random() * 2600, 7, (0.05 + Math.random() * 0.08) * v);
      }
    },
    tick(a, t, v) {
      a.burst(t, 0.016, 1300 + Math.random() * 900, 2.5, 0.2 * v);
      a.tone(t, 300 + Math.random() * 90, 0.05, 0.07 * v, 'triangle', null, 190);
    },
    tock(a, t, v) {
      a.burst(t, 0.03, 950, 1.4, 0.24 * v);
      a.tone(t, 240, 0.09, 0.13 * v, 'triangle', null, 140);
    },
    stamp(a, t, v) {
      a.tone(t, 125, 0.17, 0.36 * v, 'sine', null, 52);
      a.burst(t, 0.07, 520, 0.8, 0.3 * v, null, 'lowpass');
      a.burst(t + 0.004, 0.035, 3000, 0.9, 0.07 * v);
    }
  };

  Audio.AMB = AMB;
  Audio.SFX = SFX;
  B.Audio = Audio;
})(globalThis.Bouncer = globalThis.Bouncer || {});
