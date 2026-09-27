// His skin: what the night is doing to him, on the page (Settings → In his skin; on by default).
//
//   drink      the print slips. Two inks on a press gone out of register: the red in the pictures
//              drifts off the black, then the black doubles too and the words with it, and from the
//              fourth drink the page sways the way a room does. A drink going down slips it further
//              for a moment, then it settles where it's going to stay.
//   hurt       the edges of the page throb, slower than a heart. It's strong when it's new, then it
//              comes and goes.
//   the door   he's on the stool by the front door's glass, and the rain runs down it at the edges
//              of the page.
//   his heart  comes up in his ears while the dice are in his hand and in the air, faster the worse
//              his odds, and after each thing that happens while the room in his head is arguing or
//              worse. The edges of the page go dark with each beat.
//
// B.Skin(api) -> { update(status, turn), dice(what, odds), stop() }
//   api: { on() -> the setting, audio, reduced() -> less motion }
//   dice: 'hand' (the dice wait in his hand), 'throw', 'stamp' (the result is down), 'stop'
(function (B) {
  'use strict';

  const HEAD = { 2: [820, 0.5], 3: [690, 0.75], 4: [560, 1] };   // the room in his head: ms between beats, how loud
  const RUN_MS = 9000;          // how long it stays up after something happens
  const HOLD_MS = 45000;        // the longest his heart keeps it up with the dice in his hand
  const TAIL_MS = 2600;         // after the result, it comes down
  const JOLT_MS = 1700;         // a drink going down
  const SLIPS = 6;              // the most recent pictures slip; the ones scrolled away don't need to
  // how far the plates have drifted, by how drunk: [red, black]; the black doubles from the fourth drink
  const SLIP = [null, [1.5, 0], [2.5, 0], [3.5, 3], [5, 5]];

  // the dice: the worse the odds, the faster (about 79, 91, 105 and 122 a minute); a sure thing, nothing
  function oddsBeat(p) {
    if (p == null || p >= 0.9) return null;
    return p >= 0.72 ? [760, 0.6] : p >= 0.5 ? [660, 0.75] : p >= 0.28 ? [570, 0.9] : [490, 1];
  }

  function Skin(api) {
    const root = document.getElementById('app');
    const layer = document.getElementById('skin');
    const glass = layer ? Glass(layer.querySelector('.sk-glass'), api) : null;
    let last = { drinks: -1, turn: -1 };
    let joltT = 0, lvl = 0;
    filters();

    function level(d) { return d >= 5 ? 4 : d >= 4 ? 3 : d >= 3 ? 2 : d >= 2 ? 1 : 0; }

    function update(st, turn) {
      if (!root) return;
      if (!st || !api.on()) { clear(); return; }
      const d = st.drinks | 0;
      lvl = level(d);
      if (last.drinks >= 0 && d > last.drinks) jolt();
      else if (!joltT) root.dataset.drunk = lvl;
      root.dataset.hurt = Math.min(2, st.hurt | 0);
      markSlips();
      if (glass) { if (st.here === 'door') glass.start(); else glass.stop(); }
      const t = Math.min(4, st.tension | 0);
      if (t >= 2 && turn !== last.turn) raise('head', HEAD[t], Date.now() + RUN_MS);
      else if (t < 2) delete src.head;
      last = { drinks: d, turn: turn };
    }

    // a drink going down: the print slips further and the page lurches, then it settles
    function jolt() {
      clearTimeout(joltT);
      root.dataset.drunk = Math.min(4, lvl + 1);
      root.classList.remove('jolt');
      void root.offsetWidth;
      if (!api.reduced()) root.classList.add('jolt');
      joltT = setTimeout(function () { joltT = 0; root.classList.remove('jolt'); root.dataset.drunk = lvl; }, JOLT_MS);
    }

    // only the pictures still near the bottom of the page carry the slip
    function markSlips() {
      const imgs = document.querySelectorAll('#log .pl-img img, #log .po-img img, #log .mk-crop img, #log .lc-face img');
      for (let i = 0; i < imgs.length; i++) imgs[i].classList.toggle('slips', i >= imgs.length - SLIPS);
    }

    // ---- his heart
    // What has it up: 'head' and 'dice', each { gap, peak, until }. It beats at the quickest of them.
    const src = {};
    let beatT = 0, t0 = 0;
    function raise(key, b, until) {
      if (!b) { delete src[key]; return; }
      src[key] = { gap: b[0], peak: b[1], until: until };
      if (!beatT) { t0 = Date.now(); beatT = setTimeout(beat, 80); }
    }
    function beat() {
      const now = Date.now();
      let s = null;
      for (const k of Object.keys(src)) {
        const x = src[k];
        if (x.until <= now) { delete src[k]; continue; }
        if (!s || x.gap < s.gap) s = x;
      }
      if (!s || !api.on()) { beatT = 0; return; }
      // it comes up, holds, and falls away at the end
      const v = s.peak * Math.min(1, 0.4 + (now - t0) / 2400, (s.until - now) / 2400);
      if (api.audio) api.audio.sfx('heart', v);
      if (layer && !api.reduced()) {
        layer.style.setProperty('--beat', v.toFixed(2));
        layer.classList.add('beat');
        setTimeout(function () { layer.classList.remove('beat'); }, 110);
      }
      beatT = setTimeout(beat, s.gap);
    }
    function calm() {
      for (const k of Object.keys(src)) delete src[k];
      clearTimeout(beatT);
      beatT = 0;
      if (layer) layer.classList.remove('beat');
    }

    function dice(what, p) {
      if (!root || !api.on()) return;
      if (what === 'hand' || what === 'throw') raise('dice', oddsBeat(p), Date.now() + HOLD_MS);
      else if (what === 'stamp') { if (src.dice) src.dice.until = Math.min(src.dice.until, Date.now() + TAIL_MS); }
      else delete src.dice;
    }

    function clear() {
      calm();
      clearTimeout(joltT); joltT = 0;
      if (root) { delete root.dataset.drunk; delete root.dataset.hurt; root.classList.remove('jolt'); }
      if (glass) glass.stop();
      last = { drinks: -1, turn: -1 };
    }

    return { update: update, dice: dice, stop: clear };
  }

  // The press out of register: the red plate printed again a little off (pulled out of the picture
  // by colour: the red is where red is well over green and blue), and when it's bad, the whole
  // picture twice.
  function filters() {
    if (document.getElementById('skin-filters')) return;
    const NS = 'http://www.w3.org/2000/svg';
    const s = document.createElementNS(NS, 'svg');
    s.setAttribute('id', 'skin-filters');
    s.setAttribute('width', '0');
    s.setAttribute('height', '0');
    s.setAttribute('aria-hidden', 'true');
    s.style.position = 'absolute';
    let defs = '';
    for (let i = 1; i < SLIP.length; i++) {
      const red = SLIP[i][0], blk = SLIP[i][1];
      defs += '<filter id="slip' + i + '" x="-4%" y="-4%" width="108%" height="108%" color-interpolation-filters="sRGB">' +
        '<feColorMatrix in="SourceGraphic" type="matrix" values="0 0 0 0 .7  0 0 0 0 .15  0 0 0 0 .12  1.7 -1.3 -.4 0 0" result="red"/>' +
        '<feOffset in="red" dx="' + red + '" dy="' + (red * 0.4).toFixed(2) + '" result="redoff"/>' +
        '<feBlend in="redoff" in2="SourceGraphic" mode="multiply"' + (blk ? ' result="a"' : '') + '/>';
      if (blk) {
        // and he's seeing it twice: the whole picture again, faint, off to one side
        defs += '<feOffset in="SourceGraphic" dx="' + (-blk) + '" dy="' + (blk * 0.15).toFixed(2) + '" result="twice"/>' +
          '<feComponentTransfer in="twice" result="faint"><feFuncA type="linear" slope="' + (blk > 4 ? 0.36 : 0.26) + '"/></feComponentTransfer>' +
          '<feComposite in="faint" in2="a" operator="over"/>';
      }
      defs += '</filter>';
    }
    s.innerHTML = '<defs>' + defs + '</defs>';
    document.body.append(s);
  }

  // Rain on the glass of the front door, at the edges of the page: drops land and sit; when one's
  // heavy enough it lets go and runs, taking the ones in its way with it and leaving a wet line and
  // a trail of small ones behind. Never over the words: only in the margins, or a thin strip of them
  // on a phone. Drawn in the page's inks: dark water on the pale stock by day, the light catching
  // it by night, and now and then the red of the sign in one.
  const TRAIL = 90;             // steps a wet line lasts
  function Glass(cv, api) {
    if (!cv || !cv.getContext) return null;
    const ctx = cv.getContext('2d');
    let w = 0, h = 0, dpr = 1, bl = 0, br = 0, drops = [], trails = [], raf = 0, on = false, tick = 0, fadeT = 0;
    let sprites = null, ink = '28,27,24';

    // a drop: the rim thick at the bottom where the water sits, a faint body, a highlight up top
    function sprite(inkRGB, dark, red) {
      const S = 64, c0 = document.createElement('canvas');
      c0.width = c0.height = S;
      const c = c0.getContext('2d');
      const R = S / 2 - 1, TAU = Math.PI * 2;
      c.fillStyle = 'rgba(' + (red ? '196,40,30' : inkRGB) + ',' + (dark ? 0.46 : 0.55) + ')';
      c.beginPath(); c.arc(S / 2, S / 2, R, 0, TAU); c.fill();
      c.globalCompositeOperation = 'destination-out';
      c.beginPath(); c.arc(S / 2 - 1.5, S / 2 - 5.5, R - 3.5, 0, TAU); c.fill();
      c.globalCompositeOperation = 'source-over';
      c.fillStyle = 'rgba(' + inkRGB + ',' + (dark ? 0.07 : 0.12) + ')';
      c.beginPath(); c.arc(S / 2, S / 2, R, 0, TAU); c.fill();
      c.fillStyle = dark ? 'rgba(255,248,236,.8)' : 'rgba(255,255,255,.9)';
      c.beginPath(); c.ellipse(S * 0.37, S * 0.29, S * 0.1, S * 0.065, -0.6, 0, TAU); c.fill();
      return c0;
    }
    function inks() {
      const cs = getComputedStyle(cv);
      ink = (cs.getPropertyValue('--sk-drop') || '28,27,24').trim();
      const dark = cs.getPropertyValue('--sk-drop-dark').trim() === '1';
      sprites = [sprite(ink, dark, false), sprite(ink, dark, true)];
    }

    // the canvas covers the story; the drops keep to the margins either side of the words
    function size() {
      const r = cv.getBoundingClientRect();
      const log = document.getElementById('log');
      const t = log ? log.getBoundingClientRect() : r;
      dpr = Math.min(2, globalThis.devicePixelRatio || 1);
      w = Math.max(1, r.width); h = Math.max(1, r.height);
      cv.width = Math.round(w * dpr); cv.height = Math.round(h * dpr);
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      const cl = Math.max(0, t.left - r.left), cr = Math.max(0, r.right - t.right);
      // a wide margin fades out just short of the words; a phone's narrow one fades out at them
      const edge = function (m) { return m < 40 ? [m * 0.55, Math.max(4, m - 1)] : [m - 30, m - 6]; };
      const L = edge(cl), Rt = edge(cr), a = L[0], a2 = Rt[0];
      bl = L[1]; br = Rt[1];
      const m = 'linear-gradient(to right, #000 ' + a + 'px, transparent ' + bl + 'px, transparent calc(100% - ' + br + 'px), #000 calc(100% - ' + a2 + 'px))';
      cv.style.webkitMaskImage = m;
      cv.style.maskImage = m;
    }
    function spot() { const x = Math.random() * (bl + br); return x < bl ? x : w - (x - bl); }
    function area() { return (bl + br) * h; }
    function seed() {
      drops = []; trails = [];
      const n = Math.round(area() / 1500);
      for (let i = 0; i < n; i++) drops.push(drop(spot(), Math.random() * h));
    }
    function drop(x, y, r) {
      return { x: x, y: y, r: r || 0.9 + Math.random() * Math.random() * 4.4, v: 0, run: 0, red: Math.random() < 0.07 };
    }
    function step() {
      // new ones land, as many as the glass there is
      let n = area() / 90000;
      while (n > 0) { if (Math.random() < Math.min(1, n)) drops.push(drop(spot(), Math.random() * h)); n -= 1; }
      for (const d of drops) {
        if (!d.v && d.r > 4.2 && Math.random() < 0.025) d.v = 0.5;
        if (!d.v) continue;
        const x0 = d.x, y0 = d.y;
        d.v = Math.min(5, d.v + 0.1 + d.r * 0.01);
        d.y += d.v;
        d.x += (Math.random() - 0.5) * 0.8;
        d.r -= 0.014;
        trails.push({ x0: x0, y0: y0, x1: d.x, y1: d.y, w: d.r * 0.9, t: 0 });
        if (++d.run % 4 === 0 && d.r > 1.5) { drops.push(drop(x0 + (Math.random() - 0.5) * 1.2, y0 - d.r * 0.6, 0.5 + Math.random() * 0.9)); d.r -= 0.05; }
        // it takes the drops in its path
        for (const o of drops) {
          if (o === d || o.v || o.r <= 0) continue;
          if (Math.abs(o.x - d.x) < d.r + o.r && Math.abs(o.y - d.y) < d.r + o.r) { d.r = Math.min(8, Math.sqrt(d.r * d.r + o.r * o.r)); o.r = 0; }
        }
      }
      drops = drops.filter(function (d) { return d.r > 0.4 && d.y < h + 20; });
      if (drops.length > 1400) drops.splice(0, drops.length - 1400);
      for (const t of trails) t.t++;
      trails = trails.filter(function (t) { return t.t < TRAIL; });
    }
    function draw() {
      ctx.clearRect(0, 0, w, h);
      // the wet lines the runners left, drying
      ctx.lineCap = 'round';
      ctx.strokeStyle = 'rgb(' + ink + ')';
      for (const t of trails) {
        ctx.globalAlpha = 0.16 * (1 - t.t / TRAIL);
        ctx.lineWidth = Math.max(0.6, t.w);
        ctx.beginPath(); ctx.moveTo(t.x0, t.y0); ctx.lineTo(t.x1, t.y1); ctx.stroke();
      }
      ctx.globalAlpha = 1;
      for (const d of drops) {
        const s = d.r * 2, sy = d.v ? s * 1.3 : s;
        ctx.drawImage(sprites[d.red ? 1 : 0], d.x - d.r, d.y - (d.v ? d.r * 1.3 : d.r), s, sy);
      }
    }
    function frame() {
      if (!on) return;
      // half the frame rate is plenty for rain
      if ((tick++ & 1) === 0) { step(); draw(); }
      raf = requestAnimationFrame(frame);
    }
    function onResize() { if (on) { size(); seed(); draw(); } }
    return {
      start: function () {
        if (on) return;
        on = true;
        clearTimeout(fadeT);
        inks(); size(); seed();
        // it's been raining on this glass all night: let it run a while before it's seen
        if (!api.reduced()) for (let i = 0; i < 160; i++) step();
        draw();
        cv.classList.add('on');
        globalThis.addEventListener('resize', onResize);
        if (!api.reduced()) raf = requestAnimationFrame(frame);
      },
      stop: function () {
        if (!on) return;
        on = false;
        cv.classList.remove('on');
        cancelAnimationFrame(raf);
        globalThis.removeEventListener('resize', onResize);
        fadeT = setTimeout(function () { if (!on) ctx.clearRect(0, 0, w, h); }, 1400);
      }
    };
  }

  B.Skin = Skin;
  B.Skin.oddsBeat = oddsBeat;
})(globalThis.Bouncer = globalThis.Bouncer || {});
