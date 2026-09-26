// Print: how the plates and faces get made. A scene is painted in tones, one tone layer per ink
// (how much black, how much red, 0 to 1), with light in it: lamps, glows, the edge of a figure
// against a window. Then each layer is screened into halftone dots the way a two-colour job comes
// off a cheap press (black at 45 degrees, the sign's red at 15, a hair out of register, the ink
// a little uneven) and printed onto cream stock. The drawings are in src/ui/plates.js.
//
//   Print.job(w, h, scale)       two tone layers to paint, in drawing units (scaled to pixels)
//     job.k, job.r               a Pen for the black and for the red
//   Print.press(job, opts)       screen and print; returns a canvas
//   Print.figure(pen, spec)      a person, from a pose, lit from one side (see POSES)
//
// A Pen paints tone: pen.rect(x, y, w, h, tone), pen.poly(points, tone), pen.path(svgPath, tone),
// pen.oval(...), pen.line(x0, y0, x1, y1, width, tone). A tone is a number (0 paper, 1 solid ink)
// or a gradient from pen.lin / pen.rad. The last argument picks the mode: 'ink' (the default;
// ink goes on over what's there), 'set' (the area takes exactly this tone), 'erase' (take ink
// away: light).
(function (B) {
  'use strict';

  const PAPER = [234, 226, 207];
  const BLACK = [29, 26, 23];
  const RED = [199, 45, 33];

  function canvas(w, h) {
    const c = document.createElement('canvas');
    c.width = w; c.height = h;
    return c;
  }

  // ---------------------------------------------------------------- noise, for the ink and the stock

  let NOISE = null;
  const NS = 256;
  function noise() {
    if (NOISE) return NOISE;
    let s = 1234567;
    const rnd = function () { s = (Math.imul(s, 1103515245) + 12345) >>> 0; return s / 4294967296; };
    const base = new Float32Array(NS * NS);
    for (let i = 0; i < base.length; i++) base[i] = rnd();
    // a few octaves of smoothed noise: blotchy ink, then fine grain on top
    const out = new Float32Array(NS * NS);
    const smooth = function (x, y, step) {
      const x0 = Math.floor(x / step) * step, y0 = Math.floor(y / step) * step;
      const fx = (x - x0) / step, fy = (y - y0) / step;
      const a = base[((y0 % NS) * NS + (x0 % NS))], b = base[((y0 % NS) * NS + ((x0 + step) % NS))];
      const c = base[(((y0 + step) % NS) * NS + (x0 % NS))], d = base[(((y0 + step) % NS) * NS + ((x0 + step) % NS))];
      const sx = fx * fx * (3 - 2 * fx), sy = fy * fy * (3 - 2 * fy);
      return (a * (1 - sx) + b * sx) * (1 - sy) + (c * (1 - sx) + d * sx) * sy;
    };
    // and a fine one: the tooth of the paper, specks where the ink skipped
    const fine = new Float32Array(NS * NS);
    for (let y = 0; y < NS; y++) for (let x = 0; x < NS; x++) {
      out[y * NS + x] = smooth(x, y, 32) * 0.45 + smooth(x, y, 8) * 0.3 + smooth(x, y, 2) * 0.15 + base[y * NS + x] * 0.1;
      fine[y * NS + x] = smooth(x, y, 2) * 0.5 + base[(y * NS + x + 7919) % (NS * NS)] * 0.5;
    }
    NOISE = out;
    FINE = fine;
    return out;
  }
  let FINE = null;

  // ---------------------------------------------------------------- a pen that paints tone

  function Pen(ctx, scale) { this.c = ctx; this.s = scale; }
  const P = Pen.prototype;

  P.style = function (t) {
    if (typeof t === 'number') return 'rgba(0,0,0,' + Math.max(0, Math.min(1, t)) + ')';
    return t;
  };
  P.lin = function (x0, y0, x1, y1, stops) {
    const g = this.c.createLinearGradient(x0, y0, x1, y1);
    for (const s of stops) g.addColorStop(s[0], 'rgba(0,0,0,' + Math.max(0, Math.min(1, s[1])) + ')');
    return g;
  };
  P.rad = function (x, y, r0, r1, stops, x1, y1) {
    const g = this.c.createRadialGradient(x, y, r0, x1 == null ? x : x1, y1 == null ? y : y1, r1);
    for (const s of stops) g.addColorStop(s[0], 'rgba(0,0,0,' + Math.max(0, Math.min(1, s[1])) + ')');
    return g;
  };
  // fill whatever path build() makes, in a mode
  P.fill = function (build, tone, mode) {
    const c = this.c;
    c.save();
    if (mode === 'set') {
      c.globalCompositeOperation = 'destination-out';
      c.fillStyle = '#000';
      c.beginPath(); build(c); c.fill();
      c.globalCompositeOperation = 'source-over';
    } else if (mode === 'erase') {
      c.globalCompositeOperation = 'destination-out';
    }
    c.fillStyle = this.style(tone);
    c.beginPath(); build(c); c.fill();
    c.restore();
    return this;
  };
  P.rect = function (x, y, w, h, tone, mode) { return this.fill(function (c) { c.rect(x, y, w, h); }, tone, mode); };
  P.poly = function (pts, tone, mode) {
    return this.fill(function (c) { c.moveTo(pts[0][0], pts[0][1]); for (let i = 1; i < pts.length; i++) c.lineTo(pts[i][0], pts[i][1]); c.closePath(); }, tone, mode);
  };
  P.oval = function (x, y, rx, ry, tone, mode, rot) { return this.fill(function (c) { c.ellipse(x, y, Math.max(0.01, rx), Math.max(0.01, ry), rot || 0, 0, Math.PI * 2); }, tone, mode); };
  P.path = function (d, tone, mode) {
    const p = new Path2D(d);
    const c = this.c;
    c.save();
    if (mode === 'set') { c.globalCompositeOperation = 'destination-out'; c.fillStyle = '#000'; c.fill(p); c.globalCompositeOperation = 'source-over'; }
    else if (mode === 'erase') c.globalCompositeOperation = 'destination-out';
    c.fillStyle = this.style(tone);
    c.fill(p);
    c.restore();
    return this;
  };
  P.line = function (x0, y0, x1, y1, w, tone, mode, cap) {
    const c = this.c;
    c.save();
    if (mode === 'erase') c.globalCompositeOperation = 'destination-out';
    c.strokeStyle = this.style(tone);
    c.lineWidth = w;
    c.lineCap = cap || 'round';
    c.beginPath(); c.moveTo(x0, y0); c.lineTo(x1, y1); c.stroke();
    c.restore();
    return this;
  };
  P.stroke = function (d, w, tone, mode) {
    const c = this.c;
    c.save();
    if (mode === 'erase') c.globalCompositeOperation = 'destination-out';
    c.strokeStyle = this.style(tone);
    c.lineWidth = w; c.lineCap = 'round'; c.lineJoin = 'round';
    c.stroke(new Path2D(d));
    c.restore();
    return this;
  };
  // a cut in the block: a tapered white line, the way a gouge leaves it
  P.gouge = function (x0, y0, x1, y1, w, tone) {
    const dx = x1 - x0, dy = y1 - y0, len = Math.hypot(dx, dy) || 1;
    const nx = -dy / len * w / 2, ny = dx / len * w / 2;
    const mx = x0 + dx * 0.35, my = y0 + dy * 0.35;
    return this.fill(function (c) {
      c.moveTo(x0, y0);
      c.quadraticCurveTo(mx + nx, my + ny, x1, y1);
      c.quadraticCurveTo(mx - nx, my - ny, x0, y0);
    }, tone == null ? 1 : tone, 'erase');
  };
  // light: take ink away in a soft pool
  P.light = function (x, y, r, a, ry) {
    const c = this.c;
    c.save();
    if (ry && ry !== r) { c.translate(x, y); c.scale(1, ry / r); x = 0; y = 0; }
    c.globalCompositeOperation = 'destination-out';
    c.fillStyle = this.rad(x, y, 0, r, [[0, a], [0.5, a * 0.55], [1, 0]]);
    c.beginPath(); c.arc(x, y, r, 0, Math.PI * 2); c.fill();
    c.restore();
    return this;
  };
  // a glow: ink in a soft pool (for the red)
  P.glow = function (x, y, r, a, ry) {
    const c = this.c;
    c.save();
    if (ry && ry !== r) { c.translate(x, y); c.scale(1, ry / r); x = 0; y = 0; }
    c.fillStyle = this.rad(x, y, 0, r, [[0, a], [0.35, a * 0.5], [1, 0]]);
    c.beginPath(); c.arc(x, y, r, 0, Math.PI * 2); c.fill();
    c.restore();
    return this;
  };
  // rain: short slanted strokes, cut (erase) or inked
  P.rain = function (rnd, n, x, y, w, h, opts) {
    opts = opts || {};
    const slant = opts.slant == null ? 0.2 : opts.slant;
    for (let i = 0; i < n; i++) {
      const px = x + rnd() * w, py = y + rnd() * h, l = (opts.len || 10) * (0.5 + rnd());
      this.line(px, py, px - l * slant, py + l, opts.w || 0.7, opts.tone == null ? 0.7 : opts.tone * (0.5 + rnd() * 0.5), opts.ink ? 'ink' : 'erase');
    }
    return this;
  };
  // text, for signs
  P.text = function (s, x, y, size, tone, opts) {
    opts = opts || {};
    const c = this.c;
    c.save();
    if (opts.mode === 'erase') c.globalCompositeOperation = 'destination-out';
    c.fillStyle = this.style(tone);
    c.font = (opts.weight || 600) + ' ' + size + 'px ' + (opts.font || '"Barlow Condensed", "Arial Narrow", Arial, sans-serif');
    c.textAlign = opts.align || 'center';
    c.textBaseline = 'alphabetic';
    if (opts.spacing && 'letterSpacing' in c) c.letterSpacing = opts.spacing + 'px';
    if (opts.stroke) { c.strokeStyle = this.style(tone); c.lineWidth = opts.stroke; c.strokeText(s, x, y); }
    else if (opts.max) c.fillText(s, x, y, opts.max);
    else c.fillText(s, x, y);
    c.restore();
    return this;
  };
  // clip further painting to a shape until done() is called
  P.clip = function (build) {
    const c = this.c;
    c.save();
    c.beginPath(); build(c); c.clip();
    return this;
  };
  P.done = function () { this.c.restore(); return this; };

  // ---------------------------------------------------------------- a job and the press

  function job(uw, uh, scale) {
    const w = Math.round(uw * scale), h = Math.round(uh * scale);
    const kc = canvas(w, h), rc = canvas(w, h);
    const kx = kc.getContext('2d', { willReadFrequently: true });
    const rx = rc.getContext('2d', { willReadFrequently: true });
    kx.setTransform(scale, 0, 0, scale, 0, 0);
    rx.setTransform(scale, 0, 0, scale, 0, 0);
    return { w: w, h: h, uw: uw, uh: uh, scale: scale, kc: kc, rc: rc, k: new Pen(kx, scale), r: new Pen(rx, scale) };
  }

  // screen both layers and print them. opts: cell (dot pitch in px), angle, regX/regY (how far the
  // red is out of register, px), paper/black/red colours, grain (0..1)
  const LUT_N = 2048;
  let COS = null;
  function cosLut() {
    if (COS) return COS;
    COS = new Float32Array(LUT_N);
    for (let i = 0; i < LUT_N; i++) COS[i] = Math.cos(i / LUT_N * Math.PI * 2);
    return COS;
  }

  function press(j, opts) {
    opts = opts || {};
    const w = j.w, h = j.h;
    const kd = j.kc.getContext('2d').getImageData(0, 0, w, h).data;
    const rd = j.rc.getContext('2d').getImageData(0, 0, w, h).data;
    const out = canvas(w, h);
    const ox = out.getContext('2d');
    const img = ox.createImageData(w, h);
    const o = img.data;
    const N = noise(), F = FINE, L = cosLut();
    const paper = opts.paper || PAPER, black = opts.black || BLACK, red = opts.red || RED;
    const cellK = opts.cell || 5.2, cellR = (opts.cellRed || cellK * 0.92);
    const aK = (opts.angle == null ? 45 : opts.angle) * Math.PI / 180, aR = (opts.angleRed == null ? 15 : opts.angleRed) * Math.PI / 180;
    const regX = Math.round(opts.regX == null ? 2 : opts.regX), regY = Math.round(opts.regY == null ? -1 : opts.regY);
    const grain = opts.grain == null ? 1 : opts.grain;
    // LUT index per pixel step along each axis
    const kScale = LUT_N / cellK, rScale = LUT_N / cellR;
    const kux = Math.cos(aK) * kScale, kuy = Math.sin(aK) * kScale, kvx = -Math.sin(aK) * kScale, kvy = Math.cos(aK) * kScale;
    const rux = Math.cos(aR) * rScale, ruy = Math.sin(aR) * rScale, rvx = -Math.sin(aR) * rScale, rvy = Math.cos(aR) * rScale;
    const sharpK = cellK / 1.7, sharpR = cellR / 1.7;
    const mask = LUT_N - 1;
    // multiply factors per channel
    const kf = [1 - black[0] / 255, 1 - black[1] / 255, 1 - black[2] / 255];
    const rf = [1 - red[0] / 255, 1 - red[1] / 255, 1 - red[2] / 255];
    for (let y = 0; y < h; y++) {
      const ny = (y % NS) * NS, ny2 = (((y * 3) >> 1) % NS) * NS;
      let ku = y * kuy, kv = y * kvy, ru = y * ruy, rv = y * rvy;
      const rys = y - regY;
      for (let x = 0; x < w; x++, ku += kux, kv += kvx, ru += rux, rv += rvx) {
        const i = (y * w + x) * 4;
        const n = N[ny + (x % NS)];
        const n2 = N[ny2 + (((x * 3) >> 1) + 97) % NS];
        // black: the lightest dots drop out and the darkest fill in, the way a cheap screen prints;
        // the ink runs uneven in the middle tones
        let t = (kd[i + 3] / 255 - 0.06) * 1.14;
        let cK = 0;
        if (t > 0.012) {
          t += (n - 0.5) * 0.1 * grain * (4 * t * (1 - t) + 0.12);
          if (t >= 0.995) cK = 1;
          else {
            const spot = 0.5 + 0.25 * (L[(ku | 0) & mask] + L[(kv | 0) & mask]);
            cK = (spot - (1 - t)) * sharpK + 0.5;
            cK = cK < 0 ? 0 : cK > 1 ? 1 : cK;
            // the last holes close up gradually, so a dark tone doesn't break up where it nears solid
            if (t > 0.93) { const u = (t - 0.93) / 0.065; cK += (1 - cK) * u * u * (3 - 2 * u); }
          }
          // ink doesn't lie flat on cheap stock: a speck here and there where it skipped
          const f = F[ny2 + (x % NS)], f3 = f * f * f;
          cK *= 1 - 0.3 * grain * f3 * f3;
        }
        // red, a hair out of register
        let cR = 0;
        const rx = x - regX;
        if (rx >= 0 && rx < w && rys >= 0 && rys < h) {
          let tr = (rd[(rys * w + rx) * 4 + 3] / 255 - 0.06) * 1.14;
          if (tr > 0.012) {
            tr += (n2 - 0.5) * 0.09 * grain * (4 * tr * (1 - tr) + 0.12);
            if (tr >= 0.995) cR = 1;
            else {
              const spot = 0.5 + 0.25 * (L[(ru | 0) & mask] + L[(rv | 0) & mask]);
              cR = (spot - (1 - tr)) * sharpR + 0.5;
              cR = cR < 0 ? 0 : cR > 1 ? 1 : cR;
              if (tr > 0.93) { const u = (tr - 0.93) / 0.065; cR += (1 - cR) * u * u * (3 - 2 * u); }
            }
            const fr = F[ny + ((x + 131) % NS)], fr3 = fr * fr * fr;
            cR *= 1 - 0.3 * grain * fr3 * fr3;
          }
        }
        // the stock: a little uneven
        const pv = 1 - 0.035 * grain * (n - 0.5) - 0.025 * grain * (n2 - 0.5);
        const mK0 = 1 - cK * kf[0], mK1 = 1 - cK * kf[1], mK2 = 1 - cK * kf[2];
        const mR0 = 1 - cR * rf[0], mR1 = 1 - cR * rf[1], mR2 = 1 - cR * rf[2];
        o[i] = paper[0] * pv * mK0 * mR0;
        o[i + 1] = paper[1] * pv * mK1 * mR1;
        o[i + 2] = paper[2] * pv * mK2 * mR2;
        o[i + 3] = 255;
      }
    }
    ox.putImageData(img, 0, 0);
    return out;
  }

  // ---------------------------------------------------------------- people
  //
  // A person is a pose (joints, in a frame where they stand 1 tall, feet at y 0, facing +x for side
  // views) filled out into a silhouette: tapered limbs, a torso, a head, clothes. Drawn solid into a
  // mask, then put on the black layer at its tone, darker away from the light, with a rim of light
  // on the lit edge. That's what a person is in a bar at night: a shape against the light.

  // joints: hd (head centre), nk (neck base), sa/sb (shoulders; a is the near or left one),
  // ea/eb (elbows), ha/hb (hands), pa/pb (hips), ka/kb (knees), fa/fb (ankles)
  const POSES = {
    stand: { hd: [0, -0.932], nk: [0, -0.842], sa: [-0.112, -0.81], sb: [0.112, -0.81], ea: [-0.14, -0.6], eb: [0.14, -0.6], ha: [-0.148, -0.43], hb: [0.148, -0.43], pa: [-0.066, -0.505], pb: [0.066, -0.505], ka: [-0.07, -0.275], kb: [0.07, -0.275], fa: [-0.074, -0.035], fb: [0.074, -0.035], view: 'front' },
    // weight on one leg, a hand in a pocket
    easy: { hd: [0.012, -0.93], nk: [0.006, -0.842], sa: [-0.108, -0.8], sb: [0.114, -0.815], ea: [-0.15, -0.6], eb: [0.13, -0.61], ha: [-0.12, -0.47], hb: [0.16, -0.44], pa: [-0.07, -0.51], pb: [0.066, -0.49], ka: [-0.06, -0.275], kb: [0.1, -0.265], fa: [-0.058, -0.035], fb: [0.13, -0.035], view: 'front' },
    armsx: { hd: [0, -0.932], nk: [0, -0.842], sa: [-0.118, -0.81], sb: [0.118, -0.81], ea: [-0.155, -0.64], eb: [0.155, -0.64], ha: [0.085, -0.7], hb: [-0.085, -0.705], pa: [-0.07, -0.505], pb: [0.07, -0.505], ka: [-0.078, -0.275], kb: [0.078, -0.275], fa: [-0.085, -0.035], fb: [0.085, -0.035], view: 'front', crossed: true },
    side: { hd: [0.012, -0.932], nk: [0, -0.845], sa: [0.006, -0.805], sb: [-0.01, -0.805], ea: [0.02, -0.605], eb: [-0.02, -0.605], ha: [0.045, -0.44], hb: [-0.035, -0.445], pa: [0.006, -0.505], pb: [-0.006, -0.505], ka: [0.03, -0.275], kb: [-0.02, -0.275], fa: [0.01, -0.035], fb: [-0.03, -0.035], view: 'side' },
    walk: { hd: [0.02, -0.93], nk: [0.01, -0.842], sa: [0.012, -0.805], sb: [-0.01, -0.805], ea: [-0.06, -0.62], eb: [0.07, -0.625], ha: [-0.1, -0.46], hb: [0.14, -0.47], pa: [0.004, -0.5], pb: [-0.004, -0.5], ka: [0.09, -0.28], kb: [-0.06, -0.29], fa: [0.1, -0.035], fb: [-0.16, -0.06], view: 'side' },
    // at the bar: side-on, a forearm on the bar top, a foot on the rail
    lean: { hd: [0.07, -0.905], nk: [0.045, -0.82], sa: [0.04, -0.785], sb: [0.02, -0.79], ea: [0.14, -0.6], eb: [0.1, -0.61], ha: [0.27, -0.62], hb: [0.24, -0.6], pa: [-0.03, -0.49], pb: [-0.02, -0.49], ka: [0.06, -0.27], kb: [0.02, -0.33], fa: [0.02, -0.035], fb: [0.1, -0.17], view: 'side', drink: true },
    // sitting, seen from behind (seat at y 0): elbows out on the table
    sitback: { hd: [0, -0.445], nk: [0, -0.355], sa: [-0.118, -0.315], sb: [0.118, -0.315], ea: [-0.175, -0.14], eb: [0.175, -0.14], ha: [-0.1, -0.07], hb: [0.1, -0.07], pa: [-0.085, 0], pb: [0.085, 0], ka: [-0.09, 0.05], kb: [0.09, 0.05], fa: [-0.09, 0.24], fb: [0.09, 0.24], view: 'back', seated: true },
    // sitting, side-on, facing +x, a hand on the table
    sitside: { hd: [0.03, -0.445], nk: [0.01, -0.355], sa: [0.0, -0.315], sb: [-0.015, -0.315], ea: [0.05, -0.12], eb: [0.02, -0.13], ha: [0.2, -0.13], hb: [0.17, -0.12], pa: [-0.02, 0], pb: [-0.03, 0], ka: [0.2, -0.01], kb: [0.19, 0.0], fa: [0.2, 0.24], fb: [0.17, 0.24], view: 'side', seated: true },
    // leaning back in the chair, talking, a hand up
    sittalk: { hd: [-0.03, -0.44], nk: [-0.03, -0.35], sa: [-0.13, -0.31], sb: [0.1, -0.315], ea: [-0.18, -0.14], eb: [0.2, -0.2], ha: [-0.09, -0.08], hb: [0.16, -0.36], pa: [-0.085, 0], pb: [0.085, 0], ka: [-0.1, 0.05], kb: [0.1, 0.05], fa: [-0.1, 0.24], fb: [0.1, 0.24], view: 'front', seated: true },
    // over the pool table, lining up a shot, facing +x; lefty: the near (a) arm strokes the cue
    shootL: { hd: [0.36, -0.705], nk: [0.27, -0.7], sa: [0.22, -0.69], sb: [0.235, -0.68], ea: [0.07, -0.74], eb: [0.36, -0.58], ha: [0.035, -0.55], hb: [0.5, -0.47], pa: [-0.07, -0.5], pb: [-0.08, -0.5], ka: [0.04, -0.27], kb: [-0.16, -0.26], fa: [0.08, -0.035], fb: [-0.22, -0.035], view: 'side', cue: true, lefty: true },
    // over the pool table, lining up a shot, facing +x
    shoot: { hd: [0.36, -0.705], nk: [0.27, -0.7], sa: [0.235, -0.68], sb: [0.22, -0.69], ea: [0.36, -0.58], eb: [0.07, -0.74], ha: [0.5, -0.47], hb: [0.035, -0.55], pa: [-0.07, -0.5], pb: [-0.08, -0.5], ka: [0.04, -0.27], kb: [-0.16, -0.26], fa: [0.08, -0.035], fb: [-0.22, -0.035], view: 'side', cue: true },
    // side-on at the rail, cigarette to the mouth
    smoke: { hd: [0.012, -0.932], nk: [0, -0.845], sa: [0.006, -0.805], sb: [-0.01, -0.805], ea: [0.075, -0.66], eb: [-0.02, -0.605], ha: [0.07, -0.87], hb: [-0.03, -0.46], pa: [0.006, -0.505], pb: [-0.006, -0.505], ka: [0.03, -0.275], kb: [-0.02, -0.275], fa: [0.01, -0.035], fb: [-0.035, -0.035], view: 'side', ember: true },
    // from behind, working at something in front of him, elbows out
    backwork: { hd: [0, -0.93], nk: [0, -0.842], sa: [-0.118, -0.805], sb: [0.118, -0.805], ea: [-0.19, -0.63], eb: [0.19, -0.64], ha: [-0.07, -0.56], hb: [0.07, -0.57], pa: [-0.07, -0.505], pb: [0.07, -0.505], ka: [-0.08, -0.275], kb: [0.075, -0.27], fa: [-0.09, -0.035], fb: [0.085, -0.035], view: 'front' },
    // behind the bar, pulling a pint (only the top half shows)
    pour: { hd: [-0.01, -0.932], nk: [0, -0.842], sa: [-0.112, -0.81], sb: [0.112, -0.81], ea: [-0.16, -0.64], eb: [0.17, -0.66], ha: [-0.06, -0.58], hb: [0.2, -0.8], pa: [-0.066, -0.505], pb: [0.066, -0.505], ka: [-0.07, -0.275], kb: [0.07, -0.275], fa: [-0.074, -0.035], fb: [0.074, -0.035], view: 'front' }
  };

  const BUILD = { slight: 0.88, medium: 1, big: 1.26 };

  function tube(c, a, b, wa, wb) {
    const dx = b[0] - a[0], dy = b[1] - a[1], len = Math.hypot(dx, dy) || 1e-6;
    const nx = -dy / len, ny = dx / len;
    c.moveTo(a[0] + nx * wa, a[1] + ny * wa);
    c.lineTo(b[0] + nx * wb, b[1] + ny * wb);
    c.arc(b[0], b[1], wb, Math.atan2(ny, nx), Math.atan2(ny, nx) + Math.PI, true);
    c.lineTo(a[0] - nx * wa, a[1] - ny * wa);
    c.arc(a[0], a[1], wa, Math.atan2(-ny, -nx), Math.atan2(-ny, -nx) + Math.PI, true);
    c.closePath();
  }

  let SCR = null;
  function scratch(w, h) {
    if (!SCR || SCR.w !== w || SCR.h !== h) {
      const a = canvas(w, h), b = canvas(w, h), c = canvas(w, h), d = canvas(w, h);
      SCR = { w: w, h: h, a: a, b: b, c: c, d: d, ax: a.getContext('2d'), bx: b.getContext('2d'), cx: c.getContext('2d'), dx: d.getContext('2d') };
    }
    return SCR;
  }

  // the edge of a solid shape (in S.d) that faces a light: what's left of it when it's moved away
  // from the light by (dx, dy). both: lit from behind, so the edge on both sides and the top.
  function edgeBand(S, dx, dy, both) {
    const b = S.bx, c = S.cx;
    b.setTransform(1, 0, 0, 1, 0, 0);
    b.globalCompositeOperation = 'source-over';
    b.clearRect(0, 0, S.w, S.h);
    b.drawImage(S.d, 0, 0);
    c.setTransform(1, 0, 0, 1, 0, 0);
    c.globalCompositeOperation = 'source-over';
    c.clearRect(0, 0, S.w, S.h);
    c.drawImage(S.d, dx, dy);
    if (both) { c.globalCompositeOperation = 'destination-in'; c.drawImage(S.d, -dx, dy); c.globalCompositeOperation = 'source-over'; }
    b.globalCompositeOperation = 'destination-out';
    b.drawImage(S.c, 0, 0);
    b.globalCompositeOperation = 'source-over';
    return S.b;
  }

  // spec: x, y (feet, or the seat for seated poses), h (standing height in drawing units), pose,
  // flip (face -x), build, top, hat, hair, tone (0..1, how dark), light (-1 lit from the left, 1 from
  // the right), rim (0..1), lit (how much the lit side lifts), legs (false: hidden behind something)
  function figure(pen, spec) {
    const pose = POSES[spec.pose || 'stand'];
    const H = spec.h, flip = spec.flip ? -1 : 1, bw = (BUILD[spec.build] || 1);
    const J = {};
    for (const k in pose) if (Array.isArray(pose[k])) J[k] = [spec.x + pose[k][0] * H * flip, spec.y + pose[k][1] * H];
    const side = pose.view === 'side';
    const W = function (v) { return v * H * bw; };
    const top = spec.top || 'jacket';
    const bulk = { jacket: 1.12, coat: 1.16, hoodie: 1.1, flannel: 1.05, hivis: 1.08, suit: 1.02, apron: 1, whites: 1.04, tshirt: 0.98, cardigan: 1.06 }[top] || 1.05;
    const sc = pen.s;
    const S = scratch(pen.c.canvas.width, pen.c.canvas.height);
    const m = S.ax;
    m.setTransform(1, 0, 0, 1, 0, 0);
    m.clearRect(0, 0, S.w, S.h);
    m.setTransform(sc, 0, 0, sc, 0, 0);
    m.fillStyle = '#000';

    const limb = function (a, b, wa, wb) { m.beginPath(); tube(m, a, b, wa, wb); m.fill(); };
    const ball = function (p, r) { m.beginPath(); m.arc(p[0], p[1], r, 0, Math.PI * 2); m.fill(); };

    // legs
    if (spec.legs !== false) {
      const thigh = W(0.058), calf = W(0.042), ankle = W(0.026);
      limb(J.pb, J.kb, thigh, calf); limb(J.kb, J.fb, calf, ankle);
      limb(J.pa, J.ka, thigh, calf); limb(J.ka, J.fa, calf, ankle);
      // shoes
      const shoe = function (f, dir) {
        m.beginPath();
        if (side || pose.seated && pose.view === 'side') m.ellipse(f[0] + dir * H * 0.045, f[1] + H * 0.018, H * 0.07, H * 0.024, 0, 0, Math.PI * 2);
        else m.ellipse(f[0], f[1] + H * 0.016, H * 0.036, H * 0.024, 0, 0, Math.PI * 2);
        m.fill();
      };
      shoe(J.fb, flip); shoe(J.fa, flip);
    }
    // the torso: shoulders to hips, a little wider for a jacket or a belly
    const belly = spec.build === 'big' ? 1.18 : 1;
    const shw = W(0.012), hipw = W(0.02) * belly;
    const sa = J.sa, sb = J.sb, pa = J.pa, pb = J.pb;
    m.beginPath();
    if (side) {
      // side-on the torso is a thick slab from neck to hips
      const n = J.nk, hp = [(pa[0] + pb[0]) / 2, (pa[1] + pb[1]) / 2];
      const dx = hp[0] - n[0], dy = hp[1] - n[1], len = Math.hypot(dx, dy) || 1;
      const nx = -dy / len, ny = dx / len;
      const chest = W(0.085) * bulk, back = W(0.075) * bulk, waist = W(0.07) * belly * bulk;
      m.moveTo(n[0] + nx * back * 0.6, n[1] + ny * back * 0.6);
      m.quadraticCurveTo(n[0] + nx * back * 1.2 + dx * 0.3, n[1] + ny * back * 1.2 + dy * 0.3, hp[0] + nx * waist, hp[1] + ny * waist);
      m.lineTo(hp[0] + nx * waist * 0.4 + dx * (bulk > 1.08 ? 0.12 : 0.04), hp[1] + ny * waist * 0.4 + dy * (bulk > 1.08 ? 0.12 : 0.04));
      m.lineTo(hp[0] - nx * waist * 1.05 + dx * (bulk > 1.08 ? 0.12 : 0.04), hp[1] - ny * waist * 1.05 + dy * (bulk > 1.08 ? 0.12 : 0.04));
      m.quadraticCurveTo(n[0] - nx * chest * 1.35 + dx * 0.45, n[1] - ny * chest * 1.35 + dy * 0.45, n[0] - nx * chest * 0.7, n[1] - ny * chest * 0.7);
      m.closePath();
      m.fill();
    } else {
      const hem = (top === 'coat' ? 0.1 : top === 'jacket' || top === 'hoodie' || top === 'hivis' ? 0.03 : 0) * H;
      const outA = sa[0] < sb[0] ? -1 : 1;
      m.moveTo(sa[0] + outA * shw * bulk, sa[1] - H * 0.004);
      m.quadraticCurveTo((sa[0] + sb[0]) / 2, sa[1] - H * 0.035, sb[0] - outA * shw * bulk, sb[1] - H * 0.004);
      m.quadraticCurveTo(sb[0] - outA * W(0.005), (sb[1] + pb[1]) / 2, pb[0] - outA * hipw * bulk, pb[1] + hem);
      m.lineTo(pa[0] + outA * hipw * bulk, pa[1] + hem);
      m.quadraticCurveTo(sa[0] + outA * W(0.005), (sa[1] + pa[1]) / 2, sa[0] + outA * shw * bulk, sa[1] - H * 0.004);
      m.closePath();
      m.fill();
      if (spec.build === 'big') { m.beginPath(); m.ellipse((pa[0] + pb[0]) / 2, (pa[1] + sa[1]) / 2 + H * 0.06, W(0.105), H * 0.12, 0, 0, Math.PI * 2); m.fill(); }
    }
    // neck and head
    const hr = H * 0.058, hry = H * 0.068;
    limb(J.nk, J.hd, W(0.03), W(0.028));
    m.beginPath(); m.ellipse(J.hd[0], J.hd[1], hr * (side ? 1.08 : 1), hry, 0, 0, Math.PI * 2); m.fill();
    if (side) { m.beginPath(); m.moveTo(J.hd[0], J.hd[1] + hry * 0.2); m.lineTo(J.hd[0] + flip * hr * 1.18, J.hd[1] + hry * 0.1); m.lineTo(J.hd[0] + flip * hr * 0.4, J.hd[1] + hry * 0.95); m.fill(); }
    // hair and hats
    const hat = spec.hat, hair = spec.hair;
    if (hat === 'cap') {
      m.beginPath(); m.ellipse(J.hd[0], J.hd[1] - hry * 0.35, hr * 1.08, hry * 0.72, 0, Math.PI, 0); m.fill();
      m.beginPath(); m.ellipse(J.hd[0] + (side ? flip * hr * 1.1 : 0), J.hd[1] - hry * 0.38, side ? hr * 0.85 : hr * 1.3, H * 0.012, 0, 0, Math.PI * 2); m.fill();
    } else if (hat === 'flatcap') {
      m.beginPath(); m.ellipse(J.hd[0] + flip * hr * 0.15, J.hd[1] - hry * 0.45, hr * 1.2, hry * 0.5, 0, Math.PI, 0); m.fill();
      m.beginPath(); m.ellipse(J.hd[0] + flip * hr * (side ? 0.9 : 0.1), J.hd[1] - hry * 0.42, hr * (side ? 0.7 : 1.25), H * 0.011, 0, 0, Math.PI * 2); m.fill();
    } else if (hat === 'beanie' || hat === 'bandana') {
      m.beginPath(); m.ellipse(J.hd[0], J.hd[1] - hry * 0.3, hr * 1.06, hry * 0.9, 0, Math.PI, 0); m.fill();
    } else if (hat === 'hood') {
      m.beginPath(); m.ellipse(J.hd[0] - flip * hr * (side ? 0.2 : 0), J.hd[1] - hry * 0.05, hr * 1.32, hry * 1.2, 0, 0, Math.PI * 2); m.fill();
      m.beginPath(); m.moveTo(J.hd[0] - hr * 1.3, J.hd[1]); m.lineTo(J.hd[0] + hr * 1.3, J.hd[1]); m.lineTo(J.nk[0] + W(0.1), J.nk[1] + H * 0.04); m.lineTo(J.nk[0] - W(0.1), J.nk[1] + H * 0.04); m.fill();
    }
    if (!hat || hat === 'none') {
      if (hair === 'bun') ball([J.hd[0] - flip * hr * (side ? 0.8 : 0), J.hd[1] - hry * (side ? 0.55 : 1.05)], hr * 0.45);
      if (hair === 'ponytail') { m.beginPath(); m.moveTo(J.hd[0] - flip * hr * 0.8, J.hd[1] - hry * 0.3); m.quadraticCurveTo(J.hd[0] - flip * hr * 1.9, J.hd[1] + hry * 0.3, J.hd[0] - flip * hr * 1.2, J.hd[1] + hry * 1.4); m.lineTo(J.hd[0] - flip * hr * 0.7, J.hd[1] + hry * 0.3); m.fill(); }
      if (hair === 'long') { m.beginPath(); m.ellipse(J.hd[0] - flip * hr * 0.15, J.hd[1] + hry * 0.35, hr * 1.12, hry * 1.2, 0, 0, Math.PI * 2); m.fill(); }
      if (hair === 'messy' || hair === 'short') { m.beginPath(); m.ellipse(J.hd[0], J.hd[1] - hry * 0.25, hr * 1.1, hry * 0.85, 0, Math.PI * 1.05, Math.PI * 1.95); m.fill(); }
    }
    // arms: the far one first, the near one over the body
    const upper = W(0.036) * bulk, fore = W(0.03) * bulk, wrist = W(0.022);
    const arm = function (s, e, h2) { limb(s, e, upper, fore); limb(e, h2, fore, wrist); ball(h2, W(0.03)); };
    if (pose.crossed) {
      arm(J.sa, J.ea, J.ha); arm(J.sb, J.eb, J.hb);
    } else {
      arm(J.sb, J.eb, J.hb); arm(J.sa, J.ea, J.ha);
    }
    // a glass in the hand, a cue
    if (pose.drink || spec.glass) { m.beginPath(); m.rect(J.ha[0] - H * 0.02, J.ha[1] - H * 0.075, H * 0.04, H * 0.075); m.fill(); }
    if (pose.cue && spec.cue !== false) {
      const back = pose.lefty ? J.ha : J.hb, bridge = pose.lefty ? J.hb : J.ha;
      const tip = [bridge[0] + flip * H * 0.16, bridge[1] + H * 0.045];
      const butt = [back[0] - flip * H * 0.34, back[1] + H * 0.05];
      m.save(); m.lineCap = 'round'; m.strokeStyle = '#000';
      m.lineWidth = H * 0.016; m.beginPath(); m.moveTo(butt[0], butt[1]); m.lineTo(back[0], back[1]); m.stroke();
      m.lineWidth = H * 0.009; m.beginPath(); m.moveTo(back[0], back[1]); m.lineTo(tip[0], tip[1]); m.stroke();
      m.restore();
    }

    // keep a solid copy of the shape for the rims
    S.dx.setTransform(1, 0, 0, 1, 0, 0);
    S.dx.clearRect(0, 0, S.w, S.h);
    S.dx.drawImage(S.a, 0, 0);

    // now onto the plate: make room, then the figure's tone, darker away from the light
    const k = pen.c;
    k.save();
    k.setTransform(1, 0, 0, 1, 0, 0);
    k.globalCompositeOperation = 'destination-out';
    k.drawImage(S.a, 0, 0);
    k.restore();
    // shade the mask in place: its alpha becomes the tone
    const lightDir = spec.light == null ? -1 : spec.light;
    const tone = spec.tone == null ? 0.94 : spec.tone;
    const lift = spec.lit == null ? 0.18 : spec.lit;
    const bx0 = spec.x - H * 0.3, bx1 = spec.x + H * 0.3;
    m.globalCompositeOperation = 'source-in';
    const g = m.createLinearGradient(lightDir < 0 ? bx0 : bx1, 0, lightDir < 0 ? bx1 : bx0, 0);
    g.addColorStop(0, 'rgba(0,0,0,' + Math.max(0, tone - lift) + ')');
    g.addColorStop(0.55, 'rgba(0,0,0,' + tone + ')');
    g.addColorStop(1, 'rgba(0,0,0,' + Math.min(1, tone + 0.04) + ')');
    m.fillStyle = g;
    m.fillRect(spec.x - H, spec.y - H * 1.2, H * 2, H * 1.5);
    m.globalCompositeOperation = 'source-over';
    // clothes that catch light: an apron, whites, hi-vis stripes (painted into the mask's tone)
    const cloth = function (build, t) {
      m.save();
      m.globalCompositeOperation = 'destination-out';
      m.fillStyle = 'rgba(0,0,0,' + t + ')';
      m.beginPath(); build(m); m.fill();
      m.restore();
    };
    if (!side && (top === 'apron' || top === 'whites')) {
      const y0 = top === 'apron' ? (sa[1] + pa[1]) / 2 : sa[1] + H * 0.02;
      cloth(function (c) { c.rect(Math.min(sa[0], sb[0]) + W(0.03), y0, Math.abs(sb[0] - sa[0]) - W(0.06), pa[1] - y0 + H * 0.1); }, top === 'apron' ? 0.45 : 0.62);
    }
    if (top === 'hivis') {
      const x0 = side ? J.nk[0] - W(0.1) : Math.min(sa[0], sb[0]) - W(0.02), x1 = side ? J.nk[0] + W(0.1) : Math.max(sa[0], sb[0]) + W(0.02);
      for (const f of [0.34, 0.62]) {
        const yy = sa[1] + (pa[1] - sa[1]) * f;
        cloth(function (c) { c.rect(x0, yy, x1 - x0, H * 0.022); }, 0.92);
      }
      if (!side) for (const s of [sa, sb]) cloth(function (c) { c.rect(s[0] - H * 0.012 + (s === sa ? W(0.035) : -W(0.035)), s[1], H * 0.022, (pa[1] - sa[1]) * 0.62); }, 0.92);
    }
    if (top === 'whites' && side) cloth(function (c) { c.rect(J.nk[0] - W(0.09), J.nk[1], W(0.18), pa[1] - J.nk[1]); }, 0.55);
    // darker parts: trousers under a light top, a shirt soaked down the back, dark hair; painted
    // over and then cut back to the shape
    if (spec.legsTone || spec.wet || spec.hairTone) {
      m.save();
      m.globalCompositeOperation = 'source-over';
      if (spec.legsTone) { m.fillStyle = 'rgba(0,0,0,' + spec.legsTone + ')'; m.fillRect(spec.x - H, Math.min(pa[1], pb[1]) + H * 0.01, H * 2, H); }
      if (spec.wet) {
        const n = J.nk, hp = [(pa[0] + pb[0]) / 2, (pa[1] + pb[1]) / 2];
        m.fillStyle = 'rgba(0,0,0,' + spec.wet + ')';
        m.beginPath();
        m.moveTo(n[0] - W(0.085), n[1] + H * 0.01);
        m.quadraticCurveTo(n[0] - W(0.075), (n[1] + hp[1]) / 2, hp[0] - W(0.03), hp[1] - H * 0.02);
        m.quadraticCurveTo(hp[0], hp[1] + H * 0.012, hp[0] + W(0.035), hp[1] - H * 0.025);
        m.quadraticCurveTo(n[0] + W(0.08), (n[1] + hp[1]) / 2, n[0] + W(0.085), n[1] + H * 0.01);
        m.closePath(); m.fill();
        // and under the arms
        for (const s2 of [J.sa, J.sb]) { m.beginPath(); m.ellipse(s2[0] * 0.8 + n[0] * 0.2, s2[1] + H * 0.07, W(0.03), H * 0.05, 0, 0, Math.PI * 2); m.fill(); }
      }
      if (spec.hairTone) { m.fillStyle = 'rgba(0,0,0,' + spec.hairTone + ')'; m.fillRect(J.hd[0] - H * 0.1, J.hd[1] - H * 0.12, H * 0.2, H * 0.12 + hry * (pose.view === 'front' && spec.from === 'back' ? 0.85 : 0.1)); }
      m.globalCompositeOperation = 'destination-in';
      m.setTransform(1, 0, 0, 1, 0, 0);
      m.drawImage(S.d, 0, 0);
      m.restore();
    }
    k.save();
    k.setTransform(1, 0, 0, 1, 0, 0);
    k.drawImage(S.a, 0, 0);
    k.restore();
    // the rim: the edge that faces the light, cut out of the ink. back: lit from behind, the edge
    // all round the top. red: a second rim in the sign's red from the other side (spec.red, a pen)
    const rim = spec.rim == null ? 0.75 : spec.rim;
    const d = Math.max(1.2, H * 0.011 * sc) * (spec.rimW || 1);
    if (rim > 0) {
      const band = spec.back ? edgeBand(S, d, d * 0.7, true) : edgeBand(S, -lightDir * d, spec.rimY ? spec.rimY * d : d * 0.35, false);
      k.save();
      k.setTransform(1, 0, 0, 1, 0, 0);
      k.globalCompositeOperation = 'destination-out';
      k.globalAlpha = rim;
      k.drawImage(band, 0, 0);
      k.restore();
    }
    if (spec.red && spec.redRim) {
      const band = edgeBand(S, lightDir * d * 1.1, d * 0.2, false);
      k.save(); k.setTransform(1, 0, 0, 1, 0, 0); k.globalCompositeOperation = 'destination-out'; k.globalAlpha = spec.redRim * 0.9; k.drawImage(band, 0, 0); k.restore();
      const r = spec.red.c;
      r.save(); r.setTransform(1, 0, 0, 1, 0, 0); r.globalAlpha = spec.redRim; r.drawImage(band, 0, 0); r.restore();
    }
    return J;
  }

  B.Print = { job: job, press: press, figure: figure, POSES: POSES, Pen: Pen, canvas: canvas };
})(globalThis.Bouncer = globalThis.Bouncer || {});
