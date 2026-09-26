// Plates: the places and the people, printed. Each is painted in tones with its light in it and
// run through the press in src/ui/print.js: black and the sign's red, halftone, on cream stock.
// Drawn here in code as stand-ins until there's art; a file in content/data/assets.yaml wins.
//
// A plate shows the place as it is when he walks in: how full the room is, table 28's glasses,
// eyes in the keg-room wall as the rats double, which doors are propped (Game._plateState), and
// the light of the hour: the room at night, the house lights up at last call, dark after close.
//
//   Plates.look(id, state, phase)   what a plate would show; the same look is the same picture
//   Plates.place(id, state, phase)  a <canvas> of the place (painted a moment later if busy)
//   Plates.portrait(id, look)       a <canvas> of a face, from a character's `look:` in
//                                   content/data/characters.yaml, the way Papers, Please builds
//                                   faces from parts
(function (B) {
  'use strict';

  const W = 640, H = 220;
  const PR = B.Print;

  function rng(seed) {
    let a = seed >>> 0;
    return function () {
      a |= 0; a = a + 0x6D2B79F5 | 0;
      let t = Math.imul(a ^ a >>> 15, 1 | a);
      t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
      return ((t ^ t >>> 14) >>> 0) / 4294967296;
    };
  }
  function seedOf(s) { let h = 2166136261; for (const ch of String(s)) { h ^= ch.charCodeAt(0); h = Math.imul(h, 16777619); } return h >>> 0; }
  const clamp = function (n, lo, hi) { return Math.max(lo, Math.min(hi, n)); };

  // ---------------------------------------------------------------- shared bits

  // the edge of the block
  function edge(k) {
    const c = k.c;
    c.save(); c.fillStyle = '#000';
    c.beginPath(); c.rect(0, 0, W, H); c.rect(2.2, 2.2, W - 4.4, H - 4.4); c.fill('evenodd');
    c.restore();
  }

  // the corners fall off into dark
  function vignette(k, a) {
    k.rect(0, 0, 90, H, k.lin(0, 0, 90, 0, [[0, a], [1, 0]]));
    k.rect(W - 90, 0, 90, H, k.lin(W, 0, W - 90, 0, [[0, a], [1, 0]]));
    k.rect(0, 0, W, 40, k.lin(0, 0, 0, 40, [[0, a * 0.8], [1, 0]]));
    k.rect(0, H - 34, W, 34, k.lin(0, H, 0, H - 34, [[0, a * 0.7], [1, 0]]));
  }

  // wood boards, up and down: the joins dark, a little grain cut in
  function boards(k, x, y, w, h, tone, gap, rnd, grainA) {
    k.rect(x, y, w, h, tone, 'set');
    for (let bx = x + gap; bx < x + w; bx += gap) {
      k.line(bx, y, bx, y + h, 0.7, 0.45);
      k.line(bx + 0.8, y, bx + 0.8, y + h, 0.4, 0.12, 'erase');
      if (grainA && rnd() < 0.7) {
        const gx = bx + gap * (0.25 + rnd() * 0.5);
        k.line(gx, y + rnd() * h * 0.4, gx + (rnd() - 0.5) * 1.5, y + h * (0.55 + rnd() * 0.45), 0.35, grainA, 'erase');
      }
    }
  }

  // a light cone from a lamp: take ink away, strongest near the lamp
  function cone(k, x0, x1, y0, xb0, xb1, yb, a, fall) {
    k.poly([[x0, y0], [x1, y0], [xb1, yb], [xb0, yb]], k.lin(0, y0, 0, yb, [[0, a], [1, a * (fall == null ? 0.35 : fall)]]), 'erase');
  }

  // a glass of beer, catching the light: s is its height
  function glass(k, x, y, s, full, lit) {
    const w = s * 0.62;
    k.poly([[x - w / 2, y - s], [x + w / 2, y - s], [x + w * 0.42, y], [x - w * 0.42, y]], 0.25, 'set');
    if (full) k.poly([[x - w * 0.48, y - s * (0.2 + full * 0.6)], [x + w * 0.48, y - s * (0.2 + full * 0.6)], [x + w * 0.42, y], [x - w * 0.42, y]], 0.55);
    k.line(x - w / 2 + 0.6, y - s + 0.5, x - w * 0.42 + 0.6, y - 0.5, Math.max(0.5, s * 0.08), lit == null ? 0.9 : lit, 'erase');
    k.line(x - w / 2, y - s, x + w / 2, y - s, 0.5, 0.6);
    k.oval(x, y + 0.4, w * 0.5, s * 0.08, 0.5);
  }

  // rain that only shows where there's light behind it
  function litRain(k, rnd, build, n, x, y, w, h, tone, len) {
    k.clip(build);
    k.rain(rnd, n, x, y, w, h, { tone: tone, len: len || 12, w: 0.8 });
    k.done();
  }

  // a pickup, from behind, nose-in to the building: the building's light comes through the
  // windshield, so the back window is lit with the headrests dark in it; the rain on the roof and
  // the bed rails catches the lamp
  function pickup(k, rd, x, y, s, opts) {
    opts = opts || {};
    const w = 66 * s, h = 36 * s;
    rd.rect(x - 2, y - h - 2, w + 4, h + 6, 1, 'erase');
    // a shadow and the wet under it
    k.oval(x + w / 2, y + h * 0.04, w * 0.56, h * 0.07, 1, 'set');
    // the cab
    k.path('M' + (x + w * 0.15) + ' ' + (y - h * 0.56) + ' L' + (x + w * 0.19) + ' ' + (y - h * 0.94) + ' Q' + (x + w * 0.2) + ' ' + (y - h) + ' ' + (x + w * 0.26) + ' ' + (y - h) +
      ' L' + (x + w * 0.74) + ' ' + (y - h) + ' Q' + (x + w * 0.8) + ' ' + (y - h) + ' ' + (x + w * 0.81) + ' ' + (y - h * 0.94) + ' L' + (x + w * 0.85) + ' ' + (y - h * 0.56) + ' Z', 1, 'set');
    // the mirrors
    k.rect(x + w * 0.08, y - h * 0.8, w * 0.07, h * 0.1, 1, 'set');
    k.rect(x + w * 0.85, y - h * 0.8, w * 0.07, h * 0.1, 1, 'set');
    // the back window, lit from in front, the headrests in it
    const wy0 = y - h * 0.92, wy1 = y - h * 0.66;
    k.poly([[x + w * 0.25, wy0], [x + w * 0.75, wy0], [x + w * 0.79, wy1], [x + w * 0.21, wy1]], opts.window == null ? 0.3 : opts.window, 'set');
    k.rect(x + w * 0.25, wy0, w * 0.5, (wy1 - wy0) * 0.35, 0.2, 'erase');
    for (const hx of [0.36, 0.64]) k.path('M' + (x + w * (hx - 0.07)) + ' ' + wy1 + ' L' + (x + w * (hx - 0.06)) + ' ' + (wy0 + (wy1 - wy0) * 0.35) + ' Q' + (x + w * hx) + ' ' + (wy0 + (wy1 - wy0) * 0.12) + ' ' + (x + w * (hx + 0.06)) + ' ' + (wy0 + (wy1 - wy0) * 0.35) + ' L' + (x + w * (hx + 0.07)) + ' ' + wy1 + ' Z', 1, 'set');
    k.rect(x + w * 0.498, wy0, w * 0.012, wy1 - wy0, 1, 'set');
    // the box and the tailgate
    k.rect(x, y - h * 0.6, w, h * 0.5, 1, 'set');
    k.line(x + w * 0.05, y - h * 0.38, x + w * 0.95, y - h * 0.38, 0.7, 0.22, 'erase');
    k.rect(x + w * 0.42, y - h * 0.5, w * 0.16, h * 0.05, 0.5, 'set');
    // the bumper, and the wheels under it
    k.rect(x - w * 0.02, y - h * 0.16, w * 1.04, h * 0.1, 1, 'set');
    k.line(x - w * 0.02, y - h * 0.155, x + w * 1.02, y - h * 0.155, 0.9, 0.7, 'erase');
    k.rect(x + w * 0.04, y - h * 0.08, w * 0.17, h * 0.12, 1, 'set');
    k.rect(x + w * 0.79, y - h * 0.08, w * 0.17, h * 0.12, 1, 'set');
    // the tail lights
    for (const tx of [x + w * 0.012, x + w * 0.938]) {
      k.rect(tx, y - h * 0.57, w * 0.05, h * 0.3, opts.lights ? 0.05 : 0.45, 'set');
      rd.rect(tx, y - h * 0.57, w * 0.05, h * 0.3, 1);
      if (opts.lights) { rd.glow(tx + w * 0.025, y - h * 0.42, 18 * s, 0.6); k.light(tx + w * 0.025, y - h * 0.42, 10 * s, 0.3); }
    }
    // the wet catching the lamp: the roof, the bed rails, the edge of the cab
    k.line(x + w * 0.26, y - h + 0.4, x + w * 0.74, y - h + 0.4, 1.1, 1, 'erase');
    k.line(x + w * 0.01, y - h * 0.6 + 0.4, x + w * 0.2, y - h * 0.6 + 0.4, 1, 0.9, 'erase');
    k.line(x + w * 0.8, y - h * 0.6 + 0.4, x + w * 0.99, y - h * 0.6 + 0.4, 1, 0.9, 'erase');
    k.line(x + w * (opts.side > 0 ? 0.81 : 0.19), y - h * 0.93, x + w * (opts.side > 0 ? 0.85 : 0.15), y - h * 0.57, 0.8, 0.8, 'erase');
    k.line(x + (opts.side > 0 ? w - 0.5 : 0.5), y - h * 0.58, x + (opts.side > 0 ? w - 0.5 : 0.5), y - h * 0.2, 0.8, 0.6, 'erase');
  }

  // an ellipse as a path, for strokes; top: only the upper half
  function ell(x, y, rx, ry, top) {
    if (top) return 'M' + (x - rx) + ' ' + y + ' A' + rx + ' ' + ry + ' 0 0 1 ' + (x + rx) + ' ' + y;
    return 'M' + (x - rx) + ' ' + y + ' A' + rx + ' ' + ry + ' 0 1 0 ' + (x + rx) + ' ' + y + ' A' + rx + ' ' + ry + ' 0 1 0 ' + (x - rx) + ' ' + y;
  }

  // neon: the tube prints solid red with a bloom round it, and the black is lifted where it lights
  // the wall
  function neon(j, d, w, glow, a) {
    const k = j.k, rd = j.r, sc = j.scale;
    a = a == null ? 1 : a;
    rd.c.save(); rd.c.shadowColor = 'rgba(0,0,0,' + a + ')'; rd.c.shadowBlur = glow * sc; rd.stroke(d, w * 1.5, 0.85 * a); rd.c.restore();
    rd.stroke(d, w, a);
    k.c.save(); k.c.shadowColor = 'rgba(0,0,0,' + 0.55 * a + ')'; k.c.shadowBlur = glow * 1.4 * sc; k.stroke(d, w * 2.2, 0.45 * a, 'erase'); k.c.restore();
    k.stroke(d, w * 1.2, a, 'erase');
  }

  // a hanging lamp: the shade, a hot underside, and the pool of light it throws
  function hangLamp(k, x, y, w, drop) {
    k.line(x, 0, x, y - w * 0.3, 0.6, 0.9);
    k.path('M' + (x - w * 0.5) + ' ' + y + ' Q' + (x - w * 0.42) + ' ' + (y - w * 0.36) + ' ' + x + ' ' + (y - w * 0.38) + ' Q' + (x + w * 0.42) + ' ' + (y - w * 0.36) + ' ' + (x + w * 0.5) + ' ' + y + ' Z', 0.95, 'set');
    k.oval(x, y, w * 0.46, w * 0.09, 0, 'set');
    k.light(x, y + drop * 0.5, drop * 0.75, 0.22, drop * 0.6);
  }

  // a bar stool on the carpet at floor point (x, yf), s drawing units to the metre
  function stool(k, x, yf, s, tone) {
    tone = tone == null ? 0.92 : tone;
    const r = 0.19 * s, sy = yf - 0.72 * s, lw = Math.max(0.55, s * 0.028);
    k.line(x - r * 0.3, sy, x - r * 0.42, yf - s * 0.05, lw * 0.9, tone * 0.85);
    k.line(x + r * 0.3, sy, x + r * 0.42, yf - s * 0.05, lw * 0.9, tone * 0.85);
    k.line(x - r * 0.72, sy, x - r * 1.02, yf, lw, tone);
    k.line(x + r * 0.72, sy, x + r * 1.02, yf, lw, tone);
    k.stroke(ell(x, yf - 0.26 * s, r * 0.92, r * 0.2), lw * 0.8, tone * 0.9);
    k.oval(x, sy + r * 0.1, r, r * 0.3, tone, 'set');
    k.stroke(ell(x, sy, r * 0.96, r * 0.24, true), Math.max(0.4, lw * 0.6), 0.55, 'erase');
  }

  // a round table at floor point (x, yf), its top an ellipse rx by ry as the camera sees it
  function roundTable(k, x, yf, s, rx, ry, tone) {
    tone = tone == null ? 0.93 : tone;
    const ty = yf - 0.74 * s;
    k.rect(x - s * 0.05, ty, s * 0.1, yf - ty, tone, 'set');
    k.oval(x, yf - s * 0.02, s * 0.3, s * 0.05, tone, 'set');
    k.oval(x, ty + s * 0.03, rx, ry, tone, 'set');
    k.oval(x, ty, rx, ry, tone * 0.82, 'set');
    k.stroke(ell(x, ty, rx, ry, true), Math.max(0.4, s * 0.012), 0.5, 'erase');
    return { x: x, y: ty, rx: rx, ry: ry };
  }

  // a bottle standing on a shelf at (x, y), lit from under
  function bottle(k, rd, x, y, h, w, rnd) {
    const sh = h * (0.5 + rnd() * 0.15), neck = w * (0.24 + rnd() * 0.1), nh = h - sh;
    k.path('M' + (x - w / 2) + ' ' + y + ' L' + (x - w / 2) + ' ' + (y - sh) + ' Q' + (x - w / 2) + ' ' + (y - sh - nh * 0.35) + ' ' + (x - neck / 2) + ' ' + (y - sh - nh * 0.45) +
      ' L' + (x - neck / 2) + ' ' + (y - h) + ' L' + (x + neck / 2) + ' ' + (y - h) + ' L' + (x + neck / 2) + ' ' + (y - sh - nh * 0.45) + ' Q' + (x + w / 2) + ' ' + (y - sh - nh * 0.35) + ' ' + (x + w / 2) + ' ' + (y - sh) + ' L' + (x + w / 2) + ' ' + y + ' Z', 0.82 + rnd() * 0.14, 'set');
    // the liquid, lit through from the shelf light under it
    const lvl = 0.25 + rnd() * 0.6;
    k.rect(x - w / 2 + w * 0.18, y - sh * lvl, w * 0.64, sh * lvl - 0.3, k.lin(0, y - sh * lvl, 0, y, [[0, 0.62], [1, 0.12]]), 'set');
    const r = rnd();
    if (r < 0.55) k.rect(x - w / 2 + 0.3, y - sh * 0.78, w - 0.6, sh * 0.3, 0.2 + rnd() * 0.35, 'set');
    if (r < 0.12) rd.rect(x - w / 2 + 0.3, y - sh * 0.78, w - 0.6, sh * 0.3, 0.9);
    k.line(x - w / 2 + 0.45, y - 0.5, x - w / 2 + 0.45, y - sh + 0.5, Math.max(0.35, w * 0.1), 0.75, 'erase');
  }

  // a shelf of bottles from x0 to x1, the light strip under it
  function shelf(k, rd, x0, x1, y, h, rnd) {
    k.rect(x0, y - h * 1.35, x1 - x0, h * 1.35, k.lin(0, y - h * 1.35, 0, y, [[0, 0.5], [1, 0.22]]), 'set');
    let x = x0 + 2;
    while (x < x1 - 3) {
      const w = h * (0.22 + rnd() * 0.14);
      if (x + w > x1 - 1) break;
      bottle(k, rd, x + w / 2, y, h * (0.72 + rnd() * 0.3), w, rnd);
      x += w + h * (0.02 + rnd() * 0.08);
    }
    k.rect(x0, y, x1 - x0, Math.max(1, h * 0.08), 0.95, 'set');
    k.line(x0, y - 0.4, x1, y - 0.4, Math.max(0.4, h * 0.03), 0.8, 'erase');
  }

  // a TV up on the wall: the hockey (white ice, the red line) or the news
  function tv(k, rd, x, y, w, h, show, rnd) {
    if (show !== 'off') k.light(x + w / 2, y + h / 2, w * 0.95, 0.3, h * 1.4);
    k.rect(x - w * 0.04, y - w * 0.04, w * 1.08, h + w * 0.08, 0.97, 'set');
    if (show === 'off') {
      k.rect(x, y, w, h, 0.86, 'set');
      k.line(x + w * 0.1, y + h * 0.9, x + w * 0.45, y + h * 0.1, Math.max(0.5, w * 0.04), 0.2, 'erase');
    } else if (show === 'hockey') {
      k.rect(x, y, w, h * 0.34, 0.62, 'set');
      for (let i = 0; i < w * h * 0.08; i++) k.oval(x + rnd() * w, y + rnd() * h * 0.32, 0.35, 0.35, 0.5, 'erase');
      k.rect(x, y + h * 0.34, w, h * 0.66, 0.04, 'set');
      k.rect(x, y + h * 0.33, w, h * 0.05, 0.85, 'set');
      rd.rect(x + w * 0.49, y + h * 0.38, w * 0.035, h * 0.62, 0.95);
      for (const f of [0.28, 0.7]) k.rect(x + w * f, y + h * 0.38, w * 0.02, h * 0.62, 0.5, 'set');
      for (let i = 0; i < 6; i++) { const px = x + w * (0.15 + rnd() * 0.7), py = y + h * (0.5 + rnd() * 0.4); k.oval(px, py, w * 0.018, h * 0.06, 0.9, 'set'); }
    } else {
      k.rect(x, y, w, h, 0.3, 'set');
      k.oval(x + w * 0.35, y + h * 0.45, w * 0.1, h * 0.16, 0.8, 'set');
      k.path('M' + (x + w * 0.16) + ' ' + (y + h) + ' Q' + (x + w * 0.2) + ' ' + (y + h * 0.62) + ' ' + (x + w * 0.35) + ' ' + (y + h * 0.6) + ' Q' + (x + w * 0.5) + ' ' + (y + h * 0.62) + ' ' + (x + w * 0.54) + ' ' + (y + h) + ' Z', 0.8, 'set');
      k.rect(x, y + h * 0.74, w, h * 0.16, 0.05, 'set');
      rd.rect(x, y + h * 0.74, w * 0.22, h * 0.16, 0.95);
      k.rect(x + w * 0.26, y + h * 0.79, w * 0.6, h * 0.05, 0.6, 'set');
    }
  }

  // ---------------------------------------------------------------- the places

  const PLACES = {};

  // Arriving: three storeys of old wood painted a red that has faded to brick, SOVEREIGN on the
  // roof in red neon with the second E dead, HOTEL under it, the cold beer and wine store lit at
  // one end, trucks nose-in along the front, the gravel lot, rain hard enough to bounce.
  PLACES.lot = function (j, look, rnd) {
    const k = j.k, rd = j.r;
    // the sky: low cloud, dark overhead, lighter where the town's light catches it
    k.rect(0, 0, W, H, k.lin(0, 0, 0, 150, [[0, 0.97], [0.5, 0.88], [1, 0.66]]));
    // the ridge behind the town
    k.path('M0 116 C40 108 80 98 118 100 C160 102 186 90 226 88 C262 86 292 98 330 96 C372 94 404 82 446 84 C488 86 520 98 560 94 C596 90 620 98 640 100 L640 170 L0 170 Z', k.lin(0, 84, 0, 130, [[0, 0.8], [1, 0.9]]), 'set');
    // the building
    const bx = 124, bw = 404, by = 66, bb = 188;
    k.rect(bx, by, bw, bb - by, k.lin(bx, 0, bx + bw, 0, [[0, 0.42], [0.55, 0.5], [1, 0.7]]), 'set');
    rd.rect(bx, by, bw, bb - by, rd.lin(0, by, 0, bb, [[0, 0.36], [1, 0.46]]));
    for (let y = by + 3; y < bb; y += 3.1) k.line(bx, y, bx + bw, y, 0.45, 0.3);
    k.rect(bx, by, 6, bb - by, 0.72); k.rect(bx + bw - 6, by, 6, bb - by, 0.86);
    for (const y of [104, 140]) { k.rect(bx, y, bw, 3, 0.85, 'set'); k.line(bx, y, bx + bw, y, 0.6, 0.4, 'erase'); }
    // the cornice, heavy, its top edge catching the sky
    k.rect(bx - 10, by - 9, bw + 20, 11, 0.94, 'set');
    rd.rect(bx - 10, by - 9, bw + 20, 11, 1, 'erase');
    k.line(bx - 10, by - 9, bx + bw + 10, by - 9, 0.9, 0.55, 'erase');
    for (let x = bx - 6; x < bx + bw + 8; x += 9) k.rect(x, by + 2, 3, 3, 0.9);
    // upstairs: two rows of rooms, a few with someone in them
    const lit = { '0,6': 'blind', '1,2': 'man', '1,7': 'tv', '0,1': 'lamp' };
    for (let row = 0; row < 2; row++) {
      for (let i = 0; i < 9; i++) {
        const x = bx + 20 + i * 43, y = by + 8 + row * 37, ww = 21, wh = 25;
        rd.rect(x - 2, y - 2, ww + 4, wh + 4, 1, 'erase');
        k.rect(x - 2, y - 2, ww + 4, wh + 4, 0.34, 'set');
        const what = lit[row + ',' + i];
        if (what) {
          k.rect(x, y, ww, wh, what === 'tv' ? 0.5 : 0.1, 'set');
          if (what === 'tv') k.light(x + ww / 2, y + wh / 2, 12, 0.55);
          if (what === 'blind') { k.rect(x, y, ww, wh * 0.55, 0.55, 'set'); for (let b = 1; b < 7; b++) k.line(x, y + b * 2, x + ww, y + b * 2, 0.4, 0.3, 'erase'); }
          if (what === 'man') { k.oval(x + 13, y + 11, 3.2, 3.8, 0.92, 'set'); k.path('M' + (x + 6) + ' ' + (y + wh) + ' Q' + (x + 7) + ' ' + (y + 16) + ' ' + (x + 13) + ' ' + (y + 15) + ' Q' + (x + 19) + ' ' + (y + 16) + ' ' + (x + 20) + ' ' + (y + wh) + ' Z', 0.92, 'set'); }
          if (what === 'lamp') k.rect(x, y, ww, wh, k.rad(x + ww * 0.7, y + wh * 0.8, 1, 18, [[0, 0.02], [1, 0.32]]), 'set');
        } else {
          k.rect(x, y, ww, wh, 0.94, 'set');
          k.line(x + 2, y + wh - 3, x + 8, y + 3, 0.6, 0.22, 'erase');
        }
        k.line(x, y + wh * 0.5, x + ww, y + wh * 0.5, 1.1, 0.8);
        k.line(x - 3, y + wh + 2, x + ww + 3, y + wh + 2, 1.3, 0.55, 'erase');
      }
    }
    // the ground floor
    const gy = 148;
    // the front window: warm, table 28 in it, the TV's light
    const fx = bx + 16, fw = 148;
    rd.rect(fx - 3, gy - 3, fw + 6, 40, 1, 'erase');
    k.rect(fx - 3, gy - 3, fw + 6, 40, 0.3, 'set');
    k.rect(fx, gy, fw, 34, k.lin(0, gy, 0, gy + 34, [[0, 0.32], [1, 0.12]]), 'set');
    k.light(fx + 118, gy + 7, 20, 0.4);
    k.rect(fx + 108, gy + 3, 20, 11, 0.55, 'set'); k.rect(fx + 110, gy + 5, 16, 7, 0.12, 'set');
    // table 28 in the window, five of them
    const heads = [{ hat: 'cap' }, {}, { bun: 1 }, { glasses: 1 }, { flat: 1 }];
    const hxs = [fx + 15, fx + 34, fx + 64, fx + 84, fx + 116];
    for (let i = 0; i < 5; i++) {
      const hx = hxs[i], hy = gy + 20 + (i % 2) * 2, o = heads[i];
      k.oval(hx, hy, 4.2, 4.9, 1, 'set');
      k.path('M' + (hx - 11) + ' ' + (gy + 34) + ' Q' + (hx - 10) + ' ' + (hy + 7) + ' ' + hx + ' ' + (hy + 6) + ' Q' + (hx + 10) + ' ' + (hy + 7) + ' ' + (hx + 11) + ' ' + (gy + 34) + ' Z', 1, 'set');
      if (o.hat) { k.oval(hx, hy - 2.6, 4.6, 2.6, 1, 'set'); k.rect(hx - 1, hy - 2.2, 7.5, 1.3, 1, 'set'); }
      if (o.bun) k.oval(hx - 1, hy - 5.4, 2.2, 2, 1, 'set');
      if (o.flat) { k.oval(hx + 0.8, hy - 3.2, 5, 1.8, 1, 'set'); }
      if (o.glasses) { k.line(hx + 1.5, hy - 0.4, hx + 4.6, hy - 0.4, 0.6, 1, 'erase'); }
    }
    for (let i = 1; i < 3; i++) k.rect(fx + i * fw / 3 - 1.2, gy, 2.4, 34, 1, 'set');
    k.line(fx - 4, gy + 36, fx + fw + 4, gy + 36, 1.6, 0.5, 'erase');
    // the door, under a little roof, a lamp over it
    const dx = 302;
    rd.rect(dx - 16, gy - 22, 58, 64, 1, 'erase');
    k.rect(dx - 4, gy - 6, 34, 46, 0.86, 'set');
    k.rect(dx, gy, 26, 40, 0.66, 'set');
    k.rect(dx + 5, gy + 4, 16, 17, 0.1, 'set');
    k.line(dx + 20, gy + 26, dx + 20, gy + 31, 1.4, 0.2, 'erase');
    k.poly([[dx - 15, gy - 6], [dx + 41, gy - 6], [dx + 13, gy - 22]], 0.96, 'set');
    k.line(dx - 15, gy - 6, dx + 13, gy - 22, 0.8, 0.45, 'erase');
    k.oval(dx + 13, gy - 3, 2.4, 1.8, 0, 'set');
    k.light(dx + 13, gy + 4, 30, 0.4, 24);
    cone(k, dx - 2, dx + 28, gy - 2, dx - 36, dx + 62, bb + 26, 0.22, 0.35);
    k.rect(dx - 6, bb - 2, 38, 3, 0.4, 'set');
    // the cold beer and wine store, its lights on
    const sx = 432, sw = 88;
    rd.rect(sx - 4, gy - 22, sw + 8, 64, 1, 'erase');
    k.rect(sx - 4, gy - 20, sw + 8, 62, 0.82, 'set');
    k.rect(sx, gy - 17, sw, 13, 0.02, 'set');
    k.text('COLD BEER & WINE', sx + sw / 2, gy - 6.6, 11, 0.95, { spacing: 0.4, max: sw - 6 });
    k.rect(sx + 4, gy + 1, sw - 8, 34, 0.07, 'set');
    for (let i = 0; i < 3; i++) {
      k.line(sx + 4, gy + 11 + i * 9, sx + sw - 4, gy + 11 + i * 9, 1, 0.55);
      for (let b = 0; b < 13; b++) if (rnd() < 0.8) k.rect(sx + 7 + b * 5.8, gy + 11 + i * 9 - 5 - rnd() * 2, 2.6, 5 + rnd() * 2, 0.45 + rnd() * 0.3);
    }
    k.light(sx + sw / 2, bb + 10, 80, 0.38, 28);
    // somebody smoking against the store window
    rd.rect(sx + 6, bb - 38, 22, 40, 1, 'erase');
    PR.figure(k, { x: sx + 16, y: bb, h: 36, pose: 'smoke', top: 'jacket', hat: 'cap', tone: 0.97, light: -1, rim: 0.5, lit: 0.05 });
    rd.glow(sx + 19, bb - 31.5, 5, 1); rd.oval(sx + 19, bb - 31.5, 0.9, 0.9, 1);
    // the sign on the roof: SOVEREIGN, the second E dead, HOTEL under it
    const sy = 42, letters = 'SOVEREIGN', sp = 27, s0 = 332 - sp * 4;
    const SIGN = { font: '"Big Shoulders Display", "Barlow Condensed", "Arial Narrow", sans-serif', weight: 800 };
    k.rect(s0 - 20, 10, sp * 8 + 40, 46, 0.96, 'set');
    for (let x = s0 - 16; x < s0 + sp * 8 + 18; x += 14) { k.line(x, 14, x + 14, 52, 0.45, 0.25, 'erase'); k.line(x + 14, 14, x, 52, 0.45, 0.25, 'erase'); }
    for (const px of [s0 - 8, s0 + sp * 4, s0 + sp * 8 + 8]) k.rect(px - 1.5, 52, 3, by - 52, 0.96, 'set');
    rd.glow(332, 36, 160, 0.3, 58);
    for (let i = 0; i < letters.length; i++) {
      const x = s0 + i * sp;
      if (i === 5) { k.text('E', x, sy, 38, 0.4, Object.assign({ mode: 'erase', stroke: 0.9 }, SIGN)); continue; }
      k.text(letters[i], x, sy, 38, 1, Object.assign({ mode: 'erase' }, SIGN));
      rd.c.save(); rd.c.shadowColor = 'rgba(0,0,0,0.95)'; rd.c.shadowBlur = 14 * j.scale;
      rd.text(letters[i], x, sy, 38, 1, SIGN);
      rd.c.restore();
      rd.text(letters[i], x, sy, 38, 1, SIGN);
      k.light(x, sy - 12, 18, 0.25, 26);
    }
    k.text('H O T E L', 332, 58, 13, 1, Object.assign({ mode: 'erase' }, SIGN));
    rd.c.save(); rd.c.shadowColor = 'rgba(0,0,0,0.9)'; rd.c.shadowBlur = 8 * j.scale; rd.text('H O T E L', 332, 58, 13, 1, SIGN); rd.c.restore();
    rd.text('H O T E L', 332, 58, 13, 1, SIGN);
    // the neon lights the rain around it
    rd.clip(function (c) { c.ellipse(332, 38, 200, 64, 0, 0, Math.PI * 2); });
    rd.rain(rnd, 180, 120, 0, 420, 104, { ink: true, tone: 0.5, len: 11, w: 0.7 });
    rd.done();
    // the lot: wet gravel, ruts, puddles with the sign in them
    k.rect(0, bb, W, H - bb, k.lin(0, bb, 0, H, [[0, 0.78], [1, 0.92]]), 'set');
    for (let i = 0; i < 520; i++) k.oval(rnd() * W, bb + 2 + rnd() * (H - bb), 0.4 + rnd() * 0.7, 0.3, 0.35 + rnd() * 0.45, 'erase');
    k.stroke('M20 220 Q200 196 330 193 Q470 191 620 206', 2.2, 0.25, 'erase');
    const puddles = [[262, 203, 92, 6.5], [446, 211, 58, 5], [142, 214, 46, 4.5]];
    for (const p of puddles) {
      const clipP = function (c) { c.ellipse(p[0], p[1], p[2], p[3], 0, 0, Math.PI * 2); };
      k.oval(p[0], p[1], p[2], p[3], k.lin(0, p[1] - p[3], 0, p[1] + p[3], [[0, 0.42], [1, 0.72]]), 'set');
      k.clip(clipP);
      // the front window and the door lamp, upside down in it
      k.rect(fx, p[1] - p[3], fw, p[3] * 2, k.lin(0, p[1] - p[3], 0, p[1] + p[3], [[0, 0.45], [1, 0]]), 'erase');
      k.rect(dx + 5, p[1] - p[3], 16, p[3] * 2, k.lin(0, p[1] - p[3], 0, p[1] + p[3], [[0, 0.6], [1, 0]]), 'erase');
      for (let i = 0; i < letters.length; i++) if (i !== 5) { const x = s0 + i * sp; k.rect(x - 2.5, p[1] - p[3], 5, p[3] * 2, 0.5, 'erase'); }
      for (let y = p[1] - p[3] + 1.2; y < p[1] + p[3]; y += 1.7) k.line(p[0] - p[2], y, p[0] + p[2], y, 0.45, 0.35);
      k.done();
      rd.clip(clipP);
      for (let i = 0; i < letters.length; i++) if (i !== 5) { const x = s0 + i * sp + (rnd() - 0.5) * 1.5; rd.rect(x - 2.5, p[1] - p[3], 5, p[3] * 2, rd.lin(0, p[1] - p[3], 0, p[1] + p[3], [[0, 0.95], [1, 0.35]])); }
      for (let y = p[1] - p[3] + 1.2; y < p[1] + p[3]; y += 1.7) rd.line(p[0] - p[2], y, p[0] + p[2], y, 0.55, 0.8, 'erase');
      rd.done();
    }
    // rain bouncing where the light is
    for (let i = 0; i < 70; i++) { const x = dx - 40 + rnd() * 250, y = bb + 3 + rnd() * 26; k.line(x - 1, y, x, y - 1.6, 0.5, 0.5, 'erase'); k.line(x + 1, y, x, y - 1.6, 0.5, 0.5, 'erase'); }
    // trucks nose-in along the front, the near ones cut off by the edge
    pickup(k, rd, 6, 228, 1.8, { side: 1 });
    pickup(k, rd, 482, 234, 2.05, { side: -1, window: 0.22 });
    // the light on the pole, and the rain you can only see in it
    const lx = 624;
    k.rect(lx - 1.8, 22, 3.6, 200, 0.97, 'set');
    k.poly([[lx - 26, 22], [lx + 2, 20], [lx + 2, 27], [lx - 26, 28]], 0.97, 'set');
    k.oval(lx - 20, 28, 5.5, 1.7, 0, 'set');
    cone(k, lx - 27, lx - 13, 28, lx - 96, lx + 26, H, 0.36, 0.2);
    litRain(k, rnd, function (c) { c.moveTo(lx - 27, 28); c.lineTo(lx - 13, 28); c.lineTo(lx + 26, H); c.lineTo(lx - 96, H); c.closePath(); }, 110, lx - 100, 28, 130, 192, 0.85, 14);
    // rain over everything, faint
    k.rain(rnd, 560, 0, 0, W, H, { tone: 0.3, len: 10, w: 0.55 });
    vignette(k, 0.42);
    edge(k);
  };

  // A room seen from where he stands: eye height EYE metres, looking along the floor. p3(X, Y, D)
  // puts a point X metres to the side, Y up and D ahead onto the plate; s(D) is units to the metre.
  function camera(vx, hz, f, eye) {
    return {
      vx: vx, hz: hz, f: f, eye: eye,
      x: function (X, D) { return vx + X * f / D; },
      y: function (Y, D) { return hz + (eye - Y) * f / D; },
      s: function (D) { return f / D; }
    };
  }

  // a person in the room at (X, D): stood, sat (at a seat height) or hidden to the waist
  function person(k, cam, X, D, spec) {
    const s = cam.s(D);
    const sit = spec.pose && PR.POSES[spec.pose] && PR.POSES[spec.pose].seated;
    const o = Object.assign({}, spec, { x: cam.x(X, D), y: cam.y(sit ? (spec.seat || 0.46) : 0, D), h: (spec.tall || 1.76) * s });
    return PR.figure(k, o);
  }

  // The room from inside the front door: the bar across the back wall under the backbar light, the
  // neon salmon over the bottles, hockey on the TV, the pool table under its lamp, the pillar with
  // the dartboard, the jukebox by the hall, table 28 against the front window, the carpet worn to
  // the backing in front of the bar. Fills as the night does; the house lights come up at last
  // call; after close the chairs go up and it's the backbar, the jukebox's one song and the lot.
  PLACES.floor = function (j, look, rnd) {
    const k = j.k, rd = j.r;
    const cam = camera(250, 66, 350, 1.8);
    const X = cam.x, Y = cam.y, S = cam.s;
    const light = look.light || 'night';
    const dark = light === 'dark', house = light === 'house';
    const DB = 10.5, XL = -6.6, XR = 5.1, CH = 2.9;
    const bx0 = X(XL, DB), bx1 = X(XR, DB), bt = Y(CH, DB), bb = Y(0, DB);
    const DR = XR * cam.f / (W - cam.vx), DLW = -XL * cam.f / cam.vx;
    // how dark things are: at night the room is ink and its lights; with the house lights up it's
    // all there, flat and grey
    const T = house ? { ceil: 0.55, wall: 0.5, wain: 0.66, carpet: 0.56, bar: 0.8, fig: 0.86, furn: 0.8, rim: 0.25 }
      : { ceil: 1, wall: 0.95, wain: 1, carpet: 0.985, bar: 1, fig: 1, furn: 1, rim: 0.6 };
    const floorPoly = [[0, Y(0, DLW)], [bx0, bb], [bx1, bb], [W, Y(0, DR)], [W, H], [0, H]];
    const inFloor = function (c) { c.moveTo(floorPoly[0][0], floorPoly[0][1]); for (let i = 1; i < floorPoly.length; i++) c.lineTo(floorPoly[i][0], floorPoly[i][1]); c.closePath(); };

    // the ceiling, the walls, the carpet
    k.rect(0, 0, W, H, T.ceil, 'set');
    k.rect(bx0, bt, bx1 - bx0, bb - bt, T.wall, 'set');
    k.poly([[bx1, bt], [W, Y(CH, DR)], [W, Y(0, DR)], [bx1, bb]], T.wall, 'set');
    k.poly([[0, Y(CH, DLW)], [bx0, bt], [bx0, bb], [0, Y(0, DLW)]], Math.min(1, T.wall + 0.04), 'set');
    k.poly(floorPoly, T.carpet, 'set');
    for (const D of [5.2, 6.6, 8.2, 9.8]) {
      k.rect(X(XL, D), Y(CH, D), X(XR, D) - X(XL, D), 0.2 * S(D), Math.min(1, T.ceil + 0.1), 'set');
      if (house) k.line(X(XL, D), Y(CH, D) + 0.2 * S(D), X(XR, D), Y(CH, D) + 0.2 * S(D), 0.5, 0.3, 'erase');
    }

    // light on the carpet: in front of the bar, under the pool table, in from the window
    const PD = 6.9, PX = -2.1, TD = 6.0, TX = 3.5;
    if (!dark) {
      k.clip(inFloor);
      k.poly([[X(XL, 9.6), Y(0, 9.6)], [X(1.6, 9.6), Y(0, 9.6)], [X(1.6, 8.2), Y(0, 8.2)], [X(XL, 8.2), Y(0, 8.2)]], k.lin(0, Y(0, 9.6), 0, Y(0, 8.2), [[0, 0.3], [1, 0]]), 'erase');
      k.light(X(PX, PD), Y(0, PD), 1.9 * S(PD), 0.5, 0.55 * S(PD));
      k.poly([[W, Y(0, DR)], [X(XR, 9.7), Y(0, 9.7)], [X(2.4, 9.7), Y(0, 9.7)], [X(1.2, 4.2), Y(0, 4.2)], [W, Y(0, 4.2)]], k.lin(W, 0, X(1.6, 5), 0, [[0, 0.46], [1, 0]]), 'erase');
      k.light(X(3.65, 9.6), Y(0, 9.6), 30, 0.3, 8);
      // worn to the backing in front of the bar
      k.poly([[X(-6, 9.3), Y(0, 9.3)], [X(1.3, 9.3), Y(0, 9.3)], [X(1.3, 8.7), Y(0, 8.7)], [X(-6, 8.7), Y(0, 8.7)]], 0.12, 'erase');
      // the carpet's pattern: a trellis, only there where the light shows it
      for (let c = -16; c < 20; c += 0.62) {
        for (const sgn of [1, -1]) {
          const x0 = c + sgn * DB, x1 = c + sgn * 2.4;
          k.line(X(x0, DB), Y(0, DB), X(x1, 2.4), Y(0, 2.4), 0.45, 0.3);
        }
      }
      k.done();
    }

    const items = [];
    const put = function (D, draw) { items.push({ D: D, draw: draw }); };

    // the back wall: the wainscot, the mirror and the bottles, the neon salmon, the TVs, the hall
    put(DB, function () {
      const wy = Y(1.0, DB);
      k.rect(bx0, wy, bx1 - bx0, bb - wy, T.wain, 'set');
      for (let x = XL + 0.6; x < XR; x += 0.6) k.line(X(x, DB), wy + 1, X(x, DB), bb - 1, 0.4, house ? 0.3 : 0.1, 'erase');
      // the backbar: a mirror behind three shelves of bottles, lit from under
      const mx0 = X(-6.2, DB), mx1 = X(0.6, DB), my0 = Y(2.25, DB), my1 = Y(0.95, DB);
      k.rect(mx0 - 2, my0 - 3, mx1 - mx0 + 4, my1 - my0 + 5, 1, 'set');
      k.rect(mx0, my0, mx1 - mx0, my1 - my0, dark ? 0.8 : k.lin(0, my0, 0, my1, [[0, 0.55], [1, 0.3]]), 'set');
      for (const h of [2.0, 1.62, 1.26]) shelf(k, rd, mx0 + 1, mx1 - 1, Y(h, DB), 0.3 * S(DB), rnd);
      if (!dark) { k.light((mx0 + mx1) / 2, my1 - 6, (mx1 - mx0) * 0.6, 0.25, 18); k.light((mx0 + mx1) / 2, my0 - 2, (mx1 - mx0) * 0.55, 0.22, 14); }
      // the neon salmon and ON TAP over the backbar
      const nx = X(-3.0, DB), ny = Y(2.62, DB);
      const fish = 'M' + (nx - 34) + ' ' + (ny + 4) + ' C' + (nx - 22) + ' ' + (ny - 10) + ' ' + (nx + 4) + ' ' + (ny - 13) + ' ' + (nx + 22) + ' ' + (ny - 4) +
        ' L' + (nx + 30) + ' ' + (ny - 11) + ' L' + (nx + 27) + ' ' + (ny) + ' L' + (nx + 31) + ' ' + (ny + 9) + ' L' + (nx + 21) + ' ' + (ny + 3) +
        ' C' + (nx + 6) + ' ' + (ny + 10) + ' ' + (nx - 20) + ' ' + (ny + 12) + ' ' + (nx - 34) + ' ' + (ny + 4) + ' Z' +
        ' M' + (nx - 8) + ' ' + (ny - 8) + ' Q' + (nx - 2) + ' ' + (ny - 15) + ' ' + (nx + 6) + ' ' + (ny - 10) +
        ' M' + (nx - 26) + ' ' + (ny + 2) + ' L' + (nx - 25) + ' ' + (ny + 2);
      if (dark) k.stroke(fish, 0.8, 0.5, 'erase');
      else { neon(j, fish, 1.3, 14); k.text('ON TAP', nx - 2, ny + 22, 7.5, 1, { mode: 'erase', spacing: 1.2 }); rd.text('ON TAP', nx - 2, ny + 22, 7.5, 0.95, { spacing: 1.2 }); }
      // the TVs: the hockey by the hall, the news at the far end
      tv(k, rd, X(0.85, DB), Y(2.82, DB), 1.2 * S(DB), 0.66 * S(DB), dark ? 'off' : 'hockey', rnd);
      tv(k, rd, X(-6.35, DB) + 2, Y(2.66, DB), 1.0 * S(DB), 0.56 * S(DB), dark ? 'off' : 'news', rnd);
      // the hall: a doorway, the fluorescent tube down it, the washroom doors
      const hx0 = X(2.2, DB), hx1 = X(3.1, DB), hy0 = Y(2.1, DB);
      k.rect(hx0 - 1.5, hy0 - 1.5, hx1 - hx0 + 3, bb - hy0 + 1.5, 1, 'set');
      k.rect(hx0, hy0, hx1 - hx0, bb - hy0, dark ? 0.85 : k.lin(0, hy0, 0, bb, [[0, 0.22], [1, 0.5]]), 'set');
      k.poly([[hx0 + 4, hy0 + 8], [hx1 - 4, hy0 + 8], [hx1 - 5, bb - 12], [hx0 + 5, bb - 12]], dark ? 0.95 : 0.66, 'set');
      k.rect(hx0 + 5.5, hy0 + 14, 4, 26, dark ? 1 : 0.85, 'set');
      k.rect(hx1 - 9.5, hy0 + 14, 4, 26, dark ? 1 : 0.8, 'set');
      if (!dark) { k.rect(hx0 + 7, hy0 + 10.5, hx1 - hx0 - 14, 1.2, 0, 'set'); k.light((hx0 + hx1) / 2, hy0 + 14, 16, 0.3); }
      // over the hall door, the red sign
      rd.rect(hx0 + 7, hy0 - 6.5, hx1 - hx0 - 14, 4.2, 1); k.rect(hx0 + 7, hy0 - 6.5, hx1 - hx0 - 14, 4.2, 1, 'erase');
      k.text('EXIT', (hx0 + hx1) / 2, hy0 - 3, 3.6, 0.95, { weight: 700 });
      rd.glow((hx0 + hx1) / 2, hy0 - 4.4, 12, 0.35);
      // the lottery screen at the end of the bar
      const lx = X(1.2, 9.9), ly = Y(1.55, 9.9);
      k.rect(lx - 1, ly - 1, 14, 18, 1, 'set');
      k.rect(lx + 0.5, ly + 0.5, 11, 12, dark ? 0.9 : 0.1, 'set');
      if (!dark) { rd.rect(lx + 0.5, ly + 0.5, 11, 3.5, 0.95); for (let i = 0; i < 3; i++) for (let q = 0; q < 3; q++) k.oval(lx + 3 + q * 3, ly + 6.5 + i * 2.2, 0.8, 0.8, 0.5, 'set'); k.light(lx + 6, ly + 6, 16, 0.2); }
      k.rect(lx + 5, ly + 16, 2, Y(1.08, 9.9) - ly - 16, 1, 'set');
    });

    // the jukebox against the back wall past the hall: a tall box, the screen cycling albums
    put(10.2, function () {
      const x0 = X(3.3, 10.2), x1 = X(4.0, 10.2), y0 = Y(1.72, 10.2), y1 = Y(0, 10.2);
      k.light((x0 + x1) / 2, (y0 + y1) / 2, 34, 0.32, 40);
      k.rect(x0, y0, x1 - x0, y1 - y0, 1, 'set');
      k.rect(x0 + 2, y0 + 3, x1 - x0 - 4, (y1 - y0) * 0.5, 0.06, 'set');
      for (let r = 0; r < 4; r++) for (let q = 0; q < 3; q++) k.rect(x0 + 3.2 + q * 6.5, y0 + 5 + r * 6.6, 5, 5, 0.2 + rnd() * 0.65, 'set');
      rd.rect(x0, y0, x1 - x0, 1.6, 1); rd.rect(x0, y0, 1.2, y1 - y0, 0.9); rd.rect(x1 - 1.2, y0, 1.2, y1 - y0, 0.9);
      k.rect(x0, y0, x1 - x0, 1.6, 1, 'erase'); k.rect(x0, y0, 1.2, y1 - y0, 0.7, 'erase'); k.rect(x1 - 1.2, y0, 1.2, y1 - y0, 0.7, 'erase');
      rd.glow((x0 + x1) / 2, y0 + 20, 30, 0.3, 46);
      k.rect(x0 + 3, y0 + (y1 - y0) * 0.62, x1 - x0 - 6, 5, 0.6, 'set');
    });

    // the bartender at the taps; after close at the till, a rye at her elbow
    put(10.15, function () {
      person(k, cam, dark ? -0.9 : -2.9, 10.15, { pose: dark ? 'easy' : 'pour', build: 'slight', hair: 'bun', top: 'apron', tone: T.fig, light: 1, back: !house, rim: dark ? 0.55 : T.rim * 0.8, rimW: 0.8, lit: 0.05, legs: false, tall: 1.68 });
    });

    // the bar: panelled front, the top catching the light, the brass rail, the taps
    put(9.6, function () {
      const fx0 = X(XL, 9.6), fx1 = X(1.6, 9.6), ty = Y(1.08, 9.6), fy = Y(0, 9.6);
      k.rect(fx0, ty, fx1 - fx0, fy - ty, T.bar, 'set');
      for (let x = XL + 0.55; x < 1.6; x += 0.55) { const px = X(x, 9.6); k.line(px + 1.4, ty + 4, px + 1.4, fy - 8, 0.45, house ? 0.35 : 0.12, 'erase'); k.line(px + 1.4 + S(9.6) * 0.42, ty + 4, px + 1.4 + S(9.6) * 0.42, fy - 8, 0.45, house ? 0.35 : 0.12, 'erase'); }
      k.rect(fx0, ty - 1.8, fx1 - fx0, 2.6, 1, 'set');
      if (!dark) k.line(fx0, ty - 1.8, fx1, ty - 1.8, 0.8, 0.9, 'erase');
      // the end of the bar, turning back to the wall
      k.poly([[fx1, ty - 1.8], [X(1.6, 10.2), Y(1.08, 10.2) - 1.8], [X(1.6, 10.2), Y(0, 10.2)], [fx1, fy]], 1, 'set');
      if (!dark) k.line(fx1, ty - 1.8, fx1, fy, 0.6, 0.35, 'erase');
      // the brass rail, shining
      const ry = Y(0.22, 9.35);
      k.line(fx0, ry, fx1, ry, 1.5, 1);
      if (!dark) k.line(fx0, ry - 0.5, fx1, ry - 0.5, 0.6, 0.85, 'erase');
      for (let x = XL + 1.1; x < 1.6; x += 1.6) k.line(X(x, 9.35), ry, X(x, 9.6), ty + 20, 0.8, 1);
      // the taps, one handle red
      for (let i = 0; i < 6; i++) {
        const tx = X(-3.7 + i * 0.26, 9.9), tb = Y(1.1, 9.9);
        k.rect(tx - 0.7, tb - 8.5, 1.4, 8.5, 1, 'set');
        if (!dark) k.line(tx - 0.4, tb - 8, tx - 0.4, tb - 1, 0.4, 0.7, 'erase');
        k.rect(tx - 1.1, tb - 13, 2.2, 5, i === 2 ? 0.3 : 1, 'set');
        if (i === 2) rd.rect(tx - 1.1, tb - 13, 2.2, 5, 1);
      }
      k.rect(X(-3.8, 9.9), Y(1.1, 9.9) - 9, X(-2.2, 9.9) - X(-3.8, 9.9), 1.6, 1, 'set');
      // glasses on the bar top, and the rye by the till after close
      if (!dark) for (const g of [-5.4, -4.6, -1.3, 0.6]) glass(k, X(g, 9.75), Y(1.08, 9.75), 0.15 * S(9.75), 0.6, 0.85);
      else {
        // the till on the back counter, the drawer out, the rye at her elbow
        k.rect(X(-0.55, 10.3), Y(1.28, 10.3), 0.4 * S(10.3), 0.3 * S(10.3), 1, 'set');
        k.rect(X(-0.5, 10.3), Y(1.22, 10.3), 0.3 * S(10.3), 0.1 * S(10.3), 0.2, 'set');
        glass(k, X(-0.35, 9.8), Y(1.08, 9.8), 0.1 * S(9.8), 0.5, 0.9);
      }
    });

    // who's in: the regulars at the pool table and table 28 always; the rest as the night fills
    const crowd = dark ? 0 : clamp(look.crowd | 0, 0, 9);
    const spots = [
      { X: -3.3, D: 9.1, pose: 'sitback', seat: 0.75, top: 'jacket', hat: 'cap', stool: true, back: true },
      { X: -0.6, D: 9.1, pose: 'sitback', seat: 0.75, top: 'flannel', hair: 'short', stool: true, back: true },
      { X: 3.45, D: 9.55, pose: 'side', flip: true, top: 'hoodie', hat: 'hood', light: -1, rim: 0.8 },
      { X: -5.1, D: 9.1, pose: 'sitback', seat: 0.75, top: 'coat', hair: 'long', stool: true, back: true },
      { X: 1.1, D: 7.5, pose: 'easy', top: 'hivis', hat: 'cap', glass: true, light: 1, rim: 0.8 },
      { X: 2.1, D: 8.5, pose: 'sittalk', top: 'tshirt', hair: 'messy', light: 1, rim: 0.8 },
      { X: 0.8, D: 9.2, pose: 'lean', top: 'jacket', hair: 'short', light: -1, back: true },
      { X: -5.3, D: 7.3, pose: 'armsx', top: 'hoodie', hair: 'short', build: 'big', light: 1, rim: 0.5 },
      { X: -1.5, D: 3.7, pose: 'easy', top: 'jacket', hair: 'short', build: 'big', rim: 0.45, light: -1, glass: true }
    ];
    for (let i = 0; i < crowd; i++) {
      const p = spots[i];
      put(p.D - 0.001, function () { person(k, cam, p.X, p.D, Object.assign({ tone: T.fig, light: -1, lit: 0.06, rimW: p.back ? 0.8 : 1 }, p, { rim: (p.rim || 0.9) * T.rim })); });
    }
    // bar stools along the rail, up on the bar top after close
    for (const sx of [-6.0, -5.1, -4.2, -3.3, -2.4, -1.5, -0.6, 0.3, 1.2]) {
      put(9.1, function () {
        if (!dark) { stool(k, X(sx, 9.1), Y(0, 9.1), S(9.1), T.furn); return; }
        const s = S(9.7), ux = X(sx, 9.7), uy = Y(1.1, 9.7);
        k.oval(ux, uy - 0.05 * s, 0.17 * s, 0.05 * s, 1, 'set');
        k.line(ux - 0.13 * s, uy - 0.05 * s, ux - 0.2 * s, uy - 0.7 * s, 0.7, 1);
        k.line(ux + 0.13 * s, uy - 0.05 * s, ux + 0.2 * s, uy - 0.7 * s, 0.7, 1);
      });
    }

    // the pillar with the dartboard on it, the chalk scores
    put(7.8, function () {
      const px0 = X(0.3, 7.8), px1 = X(0.6, 7.8), s = S(7.8);
      k.rect(px0, 0, px1 - px0, Y(0, 7.8), 1, 'set');
      if (!dark) k.line(px1 - 0.6, 0, px1 - 0.6, Y(0, 7.8), 0.6, 0.35, 'erase');
      const dx = (px0 + px1) / 2, dy = Y(1.73, 7.8), r = 0.23 * s;
      k.oval(dx, dy, r * 1.25, r * 1.25, 1, 'set');
      k.oval(dx, dy, r, r, dark ? 0.9 : 0.35, 'set');
      for (let a = 0; a < 20; a++) {
        const a0 = a / 20 * Math.PI * 2, a1 = (a + 1) / 20 * Math.PI * 2;
        if (a % 2) k.poly([[dx, dy], [dx + Math.cos(a0) * r, dy + Math.sin(a0) * r], [dx + Math.cos(a1) * r, dy + Math.sin(a1) * r]], 1, 'set');
      }
      if (!dark) {
        rd.c.save(); rd.c.lineWidth = r * 0.13; rd.c.strokeStyle = 'rgba(0,0,0,0.95)';
        for (const rr of [0.94, 0.6]) { rd.c.beginPath(); rd.c.arc(dx, dy, r * rr, 0, Math.PI * 2); rd.c.stroke(); }
        rd.c.restore();
        k.c.save(); k.c.lineWidth = r * 0.13; k.c.strokeStyle = 'rgba(0,0,0,0.6)'; k.c.globalCompositeOperation = 'destination-out';
        for (const rr of [0.94, 0.6]) { k.c.beginPath(); k.c.arc(dx, dy, r * rr, 0, Math.PI * 2); k.c.stroke(); }
        k.c.restore();
        rd.oval(dx, dy, r * 0.12, r * 0.12, 1);
        k.light(dx, dy, r * 3, 0.18);
      }
      k.rect(px0 - 0.36 * s, dy - r * 1.4, 0.3 * s, 0.46 * s, 1, 'set');
      k.rect(px0 - 0.36 * s + 1, dy - r * 1.4 + 1, 0.3 * s - 2, 0.46 * s - 2, dark ? 1 : 0.78, 'set');
      if (!dark) for (let i = 0; i < 5; i++) k.line(px0 - 0.36 * s + 2.5, dy - r * 1.4 + 3.5 + i * 2.6, px0 - 0.36 * s + 3 + 3 + rnd() * 4, dy - r * 1.4 + 3.5 + i * 2.6, 0.45, 0.65, 'erase');
    });

    // two tables mid-floor, stools round them (up on top after close)
    for (const t of [[2.3, 8.3], [-5.0, 8.1]]) {
      put(t[1], function () {
        const s = S(t[1]), ry = (Y(0.74, t[1] - 0.45) - Y(0.74, t[1] + 0.45)) / 2;
        const top = roundTable(k, X(t[0], t[1]), Y(0, t[1]), s, 0.45 * s, ry, T.furn);
        if (dark) {
          for (const o of [-0.25, 0.25]) {
            const ux = X(t[0] + o, t[1]), uy = top.y - 1;
            k.oval(ux, uy - 0.04 * s, 0.17 * s, 0.05 * s, 1, 'set');
            k.line(ux - 0.12 * s, uy - 0.05 * s, ux - 0.18 * s, uy - 0.72 * s, 0.7, 1);
            k.line(ux + 0.12 * s, uy - 0.05 * s, ux + 0.18 * s, uy - 0.72 * s, 0.7, 1);
          }
        } else {
          for (const o of [-0.62, 0.62]) stool(k, X(t[0] + o, t[1] + 0.25), Y(0, t[1] + 0.25), s, T.furn);
          glass(k, top.x - 5, top.y + 1, 0.15 * s, 0.4, 0.8);
        }
      });
    }

    // the pool table under its lamp
    put(PD, function () {
      const s = S(PD);
      const nD = PD - 0.55, fD = PD + 0.55, lx0 = PX - 1.1, lx1 = PX + 1.1;
      const q = [[X(lx0, fD), Y(0.8, fD)], [X(lx1, fD), Y(0.8, fD)], [X(lx1, nD), Y(0.8, nD)], [X(lx0, nD), Y(0.8, nD)]];
      for (const lx of [lx0 + 0.15, lx1 - 0.15]) k.rect(X(lx, nD) - 2.5, Y(0.62, nD), 5, Y(0, nD) - Y(0.62, nD), T.furn, 'set');
      k.poly([[q[3][0] - 1, q[3][1]], [q[2][0] + 1, q[2][1]], [q[2][0] + 1, Y(0.56, nD)], [q[3][0] - 1, Y(0.56, nD)]], T.furn, 'set');
      // the cloth, lit hard in the middle; the rails dark round it
      k.poly([[q[0][0] - 2, q[0][1] - 1], [q[1][0] + 2, q[1][1] - 1], [q[2][0] + 2, q[2][1] + 1], [q[3][0] - 2, q[3][1] + 1]], 1, 'set');
      k.poly(q, dark ? 0.9 : 0.45, 'set');
      if (!dark) {
        k.poly(q, k.rad(X(PX, PD), Y(0.8, PD), 2, 0.95 * s, [[0, 0.45], [1, 0]]), 'erase');
        k.line(q[3][0] - 2, q[3][1] + 1, q[2][0] + 2, q[2][1] + 1, 0.7, 0.8, 'erase');
      }
      // the balls, the three red
      const balls = [[-2.75, 6.8, 0], [-2.55, 7.05, 0], [-1.55, 6.75, 1], [-1.2, 7.1, 0], [-2.2, 6.62, 0], [-3.0, 7.2, 0], [-1.85, 7.25, 0]];
      if (!dark) for (const b of balls) {
        const bx = X(b[0], b[1]), by = Y(0.83, b[1]), br = 0.03 * S(b[1]) + 0.4;
        k.oval(bx, by + br * 0.8, br * 1.1, br * 0.35, 0.9);
        k.oval(bx, by, br, br, b[2] ? 0.35 : (b[0] === -2.2 ? 0.9 : 0.02), 'set');
        if (b[2]) rd.oval(bx, by, br, br, 1);
      }
      // the lamp: a long shade low over it, the cone
      const ly = Y(1.95, PD), lw = 1.5 * s, cx = X(PX, PD);
      k.line(cx - lw * 0.33, 0, cx - lw * 0.33, ly - 4, 0.5, 1);
      k.line(cx + lw * 0.33, 0, cx + lw * 0.33, ly - 4, 0.5, 1);
      if (!dark) cone(k, cx - lw / 2 + 2, cx + lw / 2 - 2, ly + 1, q[3][0] - 6, q[2][0] + 6, q[3][1], house ? 0.04 : 0.12, 0.8);
      k.poly([[cx - lw / 2, ly], [cx + lw / 2, ly], [cx + lw / 2 - 5, ly - 6], [cx - lw / 2 + 5, ly - 6]], 1, 'set');
      if (!dark) { k.rect(cx - lw / 2 + 2, ly - 0.6, lw - 4, 1.4, 0, 'set'); k.line(cx - lw / 2 + 5, ly - 6, cx + lw / 2 - 5, ly - 6, 0.5, 0.35, 'erase'); }
    });
    // the big man at his shot, the buddy with his cue
    if (!dark) {
      put(PD + 0.62, function () { person(k, cam, PX + 0.25, PD + 0.62, { pose: 'shoot', flip: true, build: 'big', hair: 'short', top: 'flannel', tone: T.fig, light: 1, rim: T.rim, rimY: -1.1, lit: 0.05 }); });
      put(PD - 0.7, function () {
        person(k, cam, -3.75, PD - 0.7, { pose: 'easy', build: 'medium', hat: 'cap', top: 'jacket', tone: T.fig, light: 1, rim: 0.8 * T.rim, lit: 0.05 });
        k.line(X(-3.5, PD - 0.7), Y(0, PD - 0.7) - 1, X(-3.4, PD - 0.7), Y(1.45, PD - 0.7), 1.1, 1);
      });
    }

    // the front window along the right wall: the lot's light, the trucks out there, rain on the
    // glass, the sign's red at the top
    put(5.2, function () {
      const panes = [4.62, 5.9, 7.1, 8.3, 9.6];
      const wx = function (D) { return X(XR, D); };
      k.poly([[wx(4.5), Y(2.52, 4.5)], [wx(9.7), Y(2.52, 9.7)], [wx(9.7), Y(0.78, 9.7)], [wx(4.5), Y(0.78, 4.5)]], 1, 'set');
      for (let i = 0; i < panes.length - 1; i++) {
        const a = panes[i] + 0.06, b = panes[i + 1] - 0.06;
        const pts = [[wx(a), Y(2.45, a)], [wx(b), Y(2.45, b)], [wx(b), Y(0.85, b)], [wx(a), Y(0.85, a)]];
        const build = function (c) { c.moveTo(pts[0][0], pts[0][1]); for (let n = 1; n < 4; n++) c.lineTo(pts[n][0], pts[n][1]); c.closePath(); };
        k.poly(pts, dark ? 0.3 : 0.12, 'set');
        k.clip(build);
        const top = Y(2.45, a), bot = Y(0.85, a);
        k.rect(wx(b), top, wx(a) - wx(b), bot - top, k.lin(0, top, 0, bot, [[0, 0.35], [0.5, 0.05], [1, 0.3]]));
        // the trucks out in the lot, dark against the wet
        k.rect(wx(b), bot - (bot - top) * 0.22, wx(a) - wx(b), (bot - top) * 0.22, 0.72);
        k.rain(rnd, 50, wx(b), top, wx(a) - wx(b), bot - top, { tone: 0.55, len: 7, w: 0.6, ink: true, slant: 0.04 });
        k.done();
        rd.clip(build);
        rd.rect(wx(b), top, wx(a) - wx(b), bot - top, rd.lin(0, top, 0, top + (bot - top) * 0.6, [[0, 0.7], [1, 0]]));
        rd.done();
      }
      if (!dark) k.light(wx(6.5), Y(1.6, 6.5), 70, 0.12, 60);
    });

    // table 28 in the window: five in their seats since two o'clock, the glasses stacking up
    put(TD + 0.9, function () {
      if (dark) return;
      const who = [
        { X: TX - 0.55, D: TD + 0.8, pose: 'sittalk', top: 'jacket', hat: 'cap' },
        { X: TX + 0.05, D: TD + 0.95, pose: 'sittalk', top: 'cardigan', hair: 'short' },
        { X: TX + 0.62, D: TD + 0.78, pose: 'sitside', flip: true, top: 'jacket', hair: 'bun' }
      ];
      for (const p of who) person(k, cam, p.X, p.D, Object.assign({ tone: T.fig, light: 1, rim: T.rim, lit: 0.05, tall: 1.72 }, p));
    });
    put(TD, function () {
      const s = S(TD), ry = (Y(0.74, TD - 0.85) - Y(0.74, TD + 0.85)) / 2;
      const top = roundTable(k, X(TX, TD), Y(0, TD), s, 0.85 * s, ry, T.furn);
      if (!dark) k.stroke(ell(top.x, top.y, top.rx, top.ry, true), 0.9, 0.9 * T.rim, 'erase');
      if (dark) {
        for (const o of [-0.4, 0, 0.4]) {
          const ux = X(TX + o, TD), uy = top.y - 1;
          k.oval(ux, uy - 0.04 * s, 0.17 * s, 0.05 * s, 1, 'set');
          k.line(ux - 0.12 * s, uy - 0.05 * s, ux - 0.18 * s, uy - 0.72 * s, 0.8, 1);
          k.line(ux + 0.12 * s, uy - 0.05 * s, ux + 0.18 * s, uy - 0.72 * s, 0.8, 1);
        }
        return;
      }
      const n = clamp(look.glasses || 5, 3, 12);
      for (let i = 0; i < n; i++) {
        const a = Math.PI * (0.1 + 0.8 * (i + 0.5) / n) + (rnd() - 0.5) * 0.15;
        const gx = top.x + Math.cos(a) * top.rx * 0.72, gy = top.y + Math.sin(a) * top.ry * 0.62;
        glass(k, gx, gy, 0.15 * s, (i % 3) ? 0.2 : 0.7, 0.9);
      }
      k.rect(top.x + top.rx * 0.2, top.y - 1, 6, 2.4, 0.05, 'set');
      k.rect(top.x + top.rx * 0.28, top.y - 2, 6, 2.4, 0.1, 'set');
    });
    put(TD - 0.4, function () {
      if (dark) return;
      person(k, cam, TX - 1.05, TD - 0.15, { pose: 'sitside', top: 'flannel', hair: 'short', tone: T.fig, light: 1, rim: T.rim, lit: 0.05, glass: true, tall: 1.7 });
      person(k, cam, TX + 1.05, TD - 0.35, { pose: 'sitside', flip: true, top: 'coat', hat: 'flatcap', tone: T.fig, light: 1, rim: T.rim, lit: 0.05, tall: 1.72 });
    });

    // in front of him, the corner of a table: a pint going flat, a coaster
    put(2.7, function () {
      const s = S(2.7), ty = Y(0.74, 2.7);
      k.poly([[-10, ty + 2], [X(-0.9, 2.7), ty - 3], [X(-0.6, 2.2), H + 10], [-10, H + 10]], 1, 'set');
      if (!dark) k.line(-10, ty + 2.2, X(-0.9, 2.7), ty - 2.8, 1.3, 0.95, 'erase');
      if (!dark) k.line(X(-0.9, 2.7), ty - 2.8, X(-0.6, 2.2), H + 10, 0.9, 0.45, 'erase');
      const gx = X(-1.7, 2.5), gy = ty + 7;
      k.oval(gx, gy + 0.5, 0.06 * s, 0.016 * s, dark ? 0.9 : 0.35, 'set');
      glass(k, gx, gy, 0.15 * s, dark ? 0 : 0.45, dark ? 0.3 : 1);
    });

    items.sort(function (a, b) { return b.D - a.D; });
    for (const it of items) it.draw();

    // the house lights at last call: the panels in the ceiling on, bright and flat
    if (house) {
      for (const D of [5.6, 7.4, 9.2]) for (const x of [-4, -0.5, 3]) {
        k.poly([[X(x - 0.5, D - 0.3), Y(CH, D - 0.3)], [X(x + 0.5, D - 0.3), Y(CH, D - 0.3)], [X(x + 0.5, D + 0.3), Y(CH, D + 0.3)], [X(x - 0.5, D + 0.3), Y(CH, D + 0.3)]], 0, 'set');
      }
      k.rect(0, 0, W, H, 0.12, 'erase');
    }
    // after close: dark but for the backbar, the jukebox's one song, the light over the till and the lot
    if (dark) {
      k.rect(0, 0, W, H, 0.5);
      rd.rect(0, 0, W, H, 0.45, 'erase');
      // one light left on over the till
      k.light(X(-0.7, 10.0), Y(1.6, 10.0), 34, 0.55, 30);
      k.oval(X(-0.7, 10.3), Y(2.5, 10.3), 5, 1.2, 0, 'set');
      k.light(X(3.65, 10.2), Y(1.1, 10.2), 24, 0.4, 34);
      k.light(X(XR, 7.2), Y(1.6, 7.2), 70, 0.42, 46);
    }
    vignette(k, 0.35);
    edge(k);
  };

  // ---------------------------------------------------------------- the rest (see below)

  const CAPTIONS = {
    lot: 'The Sovereign Hotel', floor: 'The room', door: 'The front door', bar: 'The bar', t28: 'Table 28',
    pool: 'The pool table', hall: 'The back hall', kitchen: 'The kitchen', keg: 'The keg room', deck: 'The deck', upstairs: 'The room upstairs'
  };

  // What each plate shows of the night, in steps, from Game._plateState. Plates with the same look
  // are the same picture.
  const LOOK = {
    floor: function (st) { return { crowd: clamp(Math.round(((st.n || 13) - 10) / 6), 0, 9), glasses: clamp((st.rounds || 3) + 2, 3, 12) }; },
    bar: function (st) { return { crowd: clamp(Math.round((st.n || 13) / 11), 0, 6) }; },
    t28: function (st) { return { glasses: clamp((st.rounds || 3) * 2, 4, 16), rat: st.walter !== 0 }; },
    pool: function (st) { return { watched: (st.heat || 0) >= 5 }; },
    keg: function (st) { return { eyes: clamp(1 + Math.floor(Math.log2(Math.max(30, st.rats || 30) / 30)), 1, 6) }; },
    kitchen: function (st) { return { open: st.kitchen !== false }; },
    deck: function (st) { return { open: st.deck !== false }; },
    hall: function (st) { return { open: st.hotel !== false }; }
  };
  // places whose light changes when the house lights come up and after close
  const LIT = { floor: 1, bar: 1, t28: 1, pool: 1, door: 1 };

  function lookOf(id, state, phase) {
    const look = LOOK[id] ? LOOK[id](state || {}) : {};
    if (LIT[id]) look.light = phase === 'lights' ? 'house' : phase === 'after' ? 'dark' : 'night';
    return look;
  }

  // ---------------------------------------------------------------- printing, and a queue so a
  // long night of plates doesn't hold the page up

  const done = {};
  const queue = [];
  let busy = false;

  function printPlace(id, look) {
    const j = PR.job(W, H, 2);
    PLACES[id](j, look, rng(seedOf('plate:' + id)));
    return PR.press(j, { cell: 4.6 });
  }

  function paint(target, src) {
    target.width = src.width; target.height = src.height;
    target.getContext('2d').drawImage(src, 0, 0);
    target.classList.add('inked');
  }

  function pump() {
    if (busy || !queue.length) return;
    busy = true;
    const go = function () {
      const job = queue.pop();                 // newest first: that's the one on screen
      try {
        if (!done[job.key]) done[job.key] = job.make();
        for (const t of job.targets) paint(t, done[job.key]);
      } catch (e) { /* a plate that won't print stays blank paper */ }
      busy = false;
      if (queue.length) setTimeout(pump, 16);
    };
    if (!pump.fontsOk) fontsReady().then(function () { pump.fontsOk = true; go(); }, go);
    else setTimeout(go, 0);
  }

  // the signs are lettered in the page's own condensed faces
  function fontsReady() {
    const f = globalThis.document && document.fonts;
    if (!f || !f.load) return Promise.resolve();
    return Promise.all([f.load('600 20px "Barlow Condensed"'), f.load('700 20px "Big Shoulders Display"')]).catch(function () {});
  }

  function order(key, make, w, h) {
    const cv = PR.canvas(w, h);
    cv.className = 'print';
    if (done[key]) { paint(cv, done[key]); return cv; }
    const waiting = queue.find(function (q) { return q.key === key; });
    if (waiting) waiting.targets.push(cv);
    else queue.push({ key: key, make: make, targets: [cv] });
    pump();
    return cv;
  }

  B.Plates = {
    places: Object.keys(PLACES),
    has: function (id) { return !!PLACES[id]; },
    caption: function (id) { return CAPTIONS[id] || ''; },
    look: lookOf,
    place: function (id, state, phase) {
      if (!PLACES[id]) return null;
      const look = lookOf(id, state, phase);
      return order('pl:' + id + JSON.stringify(look), function () { return printPlace(id, look); }, W * 2, H * 2);
    },
    // for tests: print now, no queue
    printNow: function (id, look) { return printPlace(id, look || {}); },
    fontsReady: fontsReady,
    _PLACES: PLACES
  };
})(globalThis.Bouncer = globalThis.Bouncer || {});
