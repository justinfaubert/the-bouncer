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
      this._room = null;      // the room as the game last said it was (see room())
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
      if (this.amb.stop && this.amb.stop.set && this._room) this.amb.stop.set(this._room);
    }

    // What the room is doing, for an ambience that follows it (the bar's: see AMB.bar): how many
    // are in, how hot the pool table is, the rats, the hour, and where he's standing.
    // { n, heat, rounds, rats, clock, here }
    room(state) {
      this._room = Object.assign({}, state);
      if (this.amb.stop && this.amb.stop.set) this.amb.stop.set(this._room);
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
    // The bar, live. Its layers follow the room: the talk and the glasses grow with the crowd, the
    // pool table gets louder as it heats up (and past a point, voices raised over it), the jukebox
    // comes on through the evening, rats in the walls as there get to be more of them, rain on the
    // windows. Where he's standing sets the mix: at the door the room is behind him and the rain
    // is louder; from the back hall or the kitchen it comes through a wall.
    bar(a) {
      const c = a.ctx, amb = a.bus.amb;
      const P = { crowd: 0.1, heat: 0, juke: 0, rats: 0, here: 'floor', rain: 0.03 };
      // the room goes through a wall filter, so the places off the room can muffle it
      const wall = c.createBiquadFilter(); wall.type = 'lowpass'; wall.frequency.value = 9000; wall.Q.value = 0.5;
      const roomBus = c.createGain(); roomBus.gain.value = 1;
      roomBus.connect(wall); wall.connect(amb);
      const tone = a.bed(a.brown(), 'lowpass', 280, 0.7, 0.18, roomBus);
      const talk = a.bed(a.noise(), 'bandpass', 520, 1.3, 0.02, roomBus);
      const talk2 = a.bed(a.noise(), 'bandpass', 950, 1.8, 0.01, roomBus);
      const shout = a.bed(a.noise(), 'bandpass', 1250, 2.2, 0, roomBus);
      const lfos = [];
      const wobble = function (param, rate, depth) {
        const o = c.createOscillator(), d = c.createGain();
        o.frequency.value = rate; d.gain.value = depth; o.connect(d); d.connect(param); o.start();
        lfos.push(o);
      };
      wobble(talk.filter.frequency, 0.37, 170);
      wobble(talk2.filter.frequency, 0.23, 260);
      wobble(shout.filter.frequency, 1.7, 300);
      // shouting comes and goes in bursts, not a steady hiss
      const shoutAmp = c.createGain(); shoutAmp.gain.value = 0;
      try { shout.gain.disconnect(); } catch (e) { /* not connected yet */ }
      shout.gain.connect(shoutAmp); shoutAmp.connect(roomBus);
      const hum = a.hum(60, 0.014, roomBus);
      const hum2 = a.hum(120, 0.006, roomBus);
      const rainHiss = a.bed(a.noise(), 'bandpass', 1600, 0.6, 0.03, amb);
      // off the room: the kitchen's fryer and fan, the back hall's extractor
      const fryer = a.bed(a.noise(), 'highpass', 5200, 0.5, 0, amb);
      const fan = a.bed(a.brown(), 'lowpass', 190, 0.8, 0, amb);
      const extractor = a.bed(a.noise(), 'bandpass', 380, 1.2, 0, amb);
      const T = function () { return c.currentTime; };
      const glide = function (g, v, k) { g.gain.cancelScheduledValues(T()); g.gain.setTargetAtTime(v, T(), k || 1.2); };
      const loops = [];
      // run fn at an interval that can change while it runs: gap() is read each time round
      const pulse = function (gap, fn) {
        let alive = true, timer = null;
        const go = function () {
          if (!alive) return;
          try { fn(T() + 0.02); } catch (e) { /* ignore */ }
          timer = setTimeout(go, Math.max(0.12, gap()) * 1000);
        };
        timer = setTimeout(go, Math.max(0.12, gap()) * 1000 * Math.random());
        loops.push(function () { alive = false; clearTimeout(timer); });
      };
      const r = Math.random;
      // glasses on the bar and the tables
      pulse(function () { return (7 - 5.5 * P.crowd) * (0.5 + r()); }, function (t) {
        const lvl = (P.here === 'bar' ? 0.04 : 0.025) * (0.6 + 0.4 * P.crowd);
        a.tone(t, 2300 + r() * 1700, 0.22, lvl, 'sine', roomBus);
        if (r() < 0.35) a.tone(t + 0.06 + r() * 0.05, 3000 + r() * 900, 0.18, lvl * 0.6, 'sine', roomBus);
      });
      // the whole room, or one table, laughing at once: a swell in the talk
      pulse(function () { return (18 - 11 * P.crowd) * (0.6 + 0.8 * r()); }, function (t) {
        const base = 0.012 + 0.11 * P.crowd, up = base * (1.5 + 0.6 * r());
        talk.gain.gain.cancelScheduledValues(t);
        talk.gain.gain.setTargetAtTime(up, t, 0.25);
        talk.gain.gain.setTargetAtTime(base, t + 0.9 + r() * 0.8, 0.8);
      });
      // the pool table: a shot now and then, a break less often; closer and harder as it heats up
      pulse(function () { return (9 - 5 * P.heat) * (0.5 + r()); }, function (t) {
        const near = P.here === 'pool' ? 1.8 : 1;
        const lvl = (0.05 + 0.05 * P.heat) * near;
        if (r() < 0.18) { let d = 0; for (let i = 0; i < 6; i++) { a.burst(t + d, 0.016, 2300 + r() * 1400, 3, lvl * (1 - i * 0.1), roomBus); d += 0.02 + r() * 0.07; } }
        else { a.burst(t, 0.018, 2600, 3, lvl, roomBus); a.burst(t + 0.25 + r() * 0.5, 0.014, 2400, 3, lvl * 0.6, roomBus); }
      });
      // voices raised at the pool table, in bursts
      pulse(function () { return 2.2 + 3 * r(); }, function (t) {
        const hot = Math.max(0, (P.heat - 0.3) / 0.7);
        if (hot <= 0) { shoutAmp.gain.setTargetAtTime(0, t, 0.4); return; }
        const v = 0.05 * hot * (P.here === 'pool' ? 1.6 : 1) * (0.5 + r() * 0.8);
        shoutAmp.gain.setTargetAtTime(v, t, 0.08);
        shoutAmp.gain.setTargetAtTime(v * 0.15, t + 0.35 + r() * 0.6, 0.25);
      });
      // the jukebox, through the room: kick and bass, the rest of the song lost in the talk
      let beat = 0;
      pulse(function () { return 0.625; }, function (t) {
        if (P.juke <= 0 || a.music.el) return;   // a real jukebox track is playing instead
        const bar = Math.floor(beat / 4) % 4, root = [55, 55, 49, 41.2][bar];
        a.tone(t, 70, 0.2, 0.09 * P.juke, 'sine', roomBus, 42);
        if (beat % 2 === 0) a.tone(t, root, 0.55, 0.035 * P.juke, 'triangle', roomBus);
        beat++;
      });
      // the rats, in the wall behind table 28 and under the kitchen
      pulse(function () { return (22 - 16 * P.rats) * (0.5 + r()); }, function (t) {
        const near = P.here === 't28' || P.here === 'kitchen' || P.here === 'hall' ? 1 : 0.35;
        const lvl = (0.03 + 0.04 * P.rats) * near;
        const n = 3 + Math.floor(r() * 5);
        for (let i = 0; i < n; i++) a.burst(t + i * (0.04 + r() * 0.05), 0.03, 2600 + r() * 1800, 2, lvl, amb);
      });
      // rain on the glass
      pulse(function () { return 0.08 + 0.3 * r(); }, function (t) {
        const lvl = P.rain * (0.8 + r());
        a.burst(t, 0.025, 2600 + r() * 3000, 4, lvl, amb);
      });
      // the fryer spits
      pulse(function () { return 0.1 + 0.5 * r(); }, function (t) {
        if (P.here !== 'kitchen') return;
        a.burst(t, 0.012, 3500 + r() * 3000, 1.5, 0.04 + 0.05 * r(), amb);
      });
      const clamp = function (x, lo, hi) { return Math.max(lo, Math.min(hi, x)); };
      const stop = stopper(a, [tone, talk, talk2, shout, hum, hum2, rainHiss, fryer, fan, extractor], loops.concat([
        function () { for (const o of lfos) { try { o.stop(); } catch (e) {} } },
        function () { const t = T(); roomBus.gain.setTargetAtTime(0, t, 0.3); setTimeout(function () { try { roomBus.disconnect(); wall.disconnect(); shoutAmp.disconnect(); } catch (e) {} }, 2500); }
      ]));
      stop.set = function (st) {
        st = st || {};
        const n = st.n == null ? 13 : st.n;
        P.crowd = clamp((n - 8) / 40, 0, 1);
        P.heat = clamp(((st.heat || 0) - 2) / 8, 0, 1);
        P.rats = clamp(Math.log2(Math.max(30, st.rats || 30) / 30) / 3, 0, 1);
        const clock = st.clock || 0;
        P.juke = clock >= 1230 && clock < 1530 && n >= 12 ? (0.6 + 0.4 * P.crowd) : 0;
        P.here = st.here || 'floor';
        P.rain = P.here === 'door' ? 0.09 : P.here === 'hall' || P.here === 'kitchen' ? 0.015 : 0.035;
        glide(tone.gain, 0.13 + 0.1 * P.crowd);
        glide(talk.gain, 0.012 + 0.11 * P.crowd);
        glide(talk2.gain, 0.004 + 0.08 * Math.pow(P.crowd, 1.3));
        glide(shout.gain, 1);
        glide(rainHiss.gain, P.here === 'door' ? 0.07 : 0.025);
        glide(fryer.gain, P.here === 'kitchen' ? 0.035 : 0);
        glide(fan.gain, P.here === 'kitchen' ? 0.12 : 0);
        glide(extractor.gain, P.here === 'hall' ? 0.05 : 0);
        const muffle = { door: 1800, hall: 420, kitchen: 650 }[P.here] || 9000;
        wall.frequency.setTargetAtTime(muffle, T(), 0.6);
        roomBus.gain.setTargetAtTime(P.here === 'hall' ? 0.55 : P.here === 'kitchen' ? 0.5 : P.here === 'door' ? 0.8 : 1, T(), 0.6);
      };
      return stop;
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
    },
    // the till's receipt printer: the head buzzing across a line, then the paper stepping on
    printer(a, t, v) {
      for (let i = 0; i < 9; i++) a.burst(t + i * 0.017, 0.014, 3400 + Math.random() * 1400, 4, 0.11 * v);
      a.tone(t, 610, 0.15, 0.02 * v, 'square');
      a.tone(t + 0.155, 190, 0.05, 0.055 * v, 'sawtooth', null, 140);
      a.burst(t + 0.155, 0.04, 900, 1.2, 0.07 * v);
    },
    // the tape torn off against the teeth
    // a voice leaning in: a breath close to one ear
    whisper(a, t, v) {
      const c = a.ctx;
      const src = c.createBufferSource();
      src.buffer = a.noise();
      const f = c.createBiquadFilter();
      f.type = 'bandpass'; f.Q.value = 1.3;
      f.frequency.setValueAtTime(1500, t);
      f.frequency.linearRampToValueAtTime(3100, t + 0.55);
      const g = c.createGain();
      g.gain.setValueAtTime(0.0001, t);
      g.gain.linearRampToValueAtTime(0.034 * v, t + 0.2);
      g.gain.exponentialRampToValueAtTime(0.0001, t + 0.8);
      let out = g;
      if (c.createStereoPanner) {
        const p = c.createStereoPanner();
        p.pan.value = (Math.random() < 0.5 ? -1 : 1) * (0.45 + Math.random() * 0.3);
        g.connect(p); out = p;
      }
      src.connect(f); f.connect(g); out.connect(a.bus.sfx);
      src.start(t, Math.random()); src.stop(t + 0.85);
    },
    tear(a, t, v) {
      for (let i = 0; i < 11; i++) a.burst(t + i * 0.017 + Math.random() * 0.007, 0.03, 1100 + i * 240 + Math.random() * 300, 1.3, (0.08 + i * 0.01) * v);
    }
  };

  Audio.AMB = AMB;
  Audio.SFX = SFX;
  B.Audio = Audio;
})(globalThis.Bouncer = globalThis.Bouncer || {});
