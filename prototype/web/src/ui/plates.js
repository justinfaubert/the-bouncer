// Plates: the places and the people, printed. Each is painted in tones with its light in it and
// run through the press in src/ui/print.js: black and the sign's red, halftone, on cream stock.
// Drawn here in code as stand-ins until there's art; a file in content/data/assets.yaml wins.
//
// A plate shows the place as it is when he walks in: how full the room is, table 28's glasses,
// eyes in the keg-room wall as the rats double, which doors are propped (Game._plateState), and
// the light of the hour: the room at night, the house lights up at last call, dark after close.
//
//   Plates.look(id, state, phase)   what a plate would show; the same look is the same picture
//   Plates.place(id, state, phase)  an <img> of the place, filled when it's off the press
//   Plates.portrait(id, look)       an <img> of a face, from a character's `look:` in
//                                   content/data/characters.yaml, the way Papers, Please builds
//                                   faces from parts
//   Plates.prewarm([...])           print ahead: [{place, state, phase}] or [{face, look}]
//   Plates.hold(ms)                 nothing off the press for a while (the dice are rolling)
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
  // After close (look.closed): the sign off, the store shut, the chairs up in the dark front
  // window, the trucks gone, one window lit upstairs (his), and still the rain. A truck left in
  // the lot if somebody's keys are in the lost-and-found drawer (look.truck).
  PLACES.lot = function (j, look, rnd) {
    const k = j.k, rd = j.r;
    const shut = !!(look && look.closed);
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
    const lit = shut ? { '1,8': 'lamp' } : { '0,6': 'blind', '1,2': 'man', '1,7': 'tv', '0,1': 'lamp' };
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
    if (shut) {
      // closed: the room dark but for the backbar at the far end; the chairs up on the tables
      k.rect(fx, gy, fw, 34, k.lin(fx, 0, fx + fw, 0, [[0, 0.93], [0.7, 0.86], [1, 0.72]]), 'set');
      for (const tx of [fx + 22, fx + 70, fx + 118]) {
        k.rect(tx - 15, gy + 22, 30, 2.2, 0.62, 'set');
        for (const cx of [tx - 9, tx + 5]) {
          k.rect(cx, gy + 13, 7, 1.6, 0.62, 'set');
          k.line(cx + 0.8, gy + 13, cx + 0.3, gy + 5, 0.9, 0.62); k.line(cx + 6.2, gy + 13, cx + 6.7, gy + 5, 0.9, 0.62);
          k.line(cx + 0.6, gy + 14.6, cx + 1.2, gy + 21.5, 0.9, 0.62); k.line(cx + 6.4, gy + 14.6, cx + 5.8, gy + 21.5, 0.9, 0.62);
        }
      }
    } else {
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
    k.light(dx + 13, gy + 4, 30, shut ? 0.22 : 0.4, 24);
    cone(k, dx - 2, dx + 28, gy - 2, dx - 36, dx + 62, bb + 26, shut ? 0.12 : 0.22, 0.35);
    k.rect(dx - 6, bb - 2, 38, 3, 0.4, 'set');
    // the cold beer and wine store, its lights on
    const sx = 432, sw = 88;
    rd.rect(sx - 4, gy - 22, sw + 8, 64, 1, 'erase');
    k.rect(sx - 4, gy - 20, sw + 8, 62, 0.82, 'set');
    if (shut) {
      // shut: the sign unlit, the grille down
      k.rect(sx, gy - 17, sw, 13, 0.7, 'set');
      k.text('COLD BEER & WINE', sx + sw / 2, gy - 6.6, 11, 0.35, { spacing: 0.4, max: sw - 6 });
      k.rect(sx + 4, gy + 1, sw - 8, 34, 0.9, 'set');
      for (let y = gy + 3; y < gy + 35; y += 2.6) k.line(sx + 4, y, sx + sw - 4, y, 0.5, 0.22, 'erase');
    } else {
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
    }
    // the sign on the roof: SOVEREIGN, the second E dead, HOTEL under it
    const sy = 42, letters = 'SOVEREIGN', sp = 27, s0 = 332 - sp * 4;
    const SIGN = { font: '"Big Shoulders Display", "Barlow Condensed", "Arial Narrow", sans-serif', weight: 800 };
    k.rect(s0 - 20, 10, sp * 8 + 40, 46, 0.96, 'set');
    for (let x = s0 - 16; x < s0 + sp * 8 + 18; x += 14) { k.line(x, 14, x + 14, 52, 0.45, 0.25, 'erase'); k.line(x + 14, 14, x, 52, 0.45, 0.25, 'erase'); }
    for (const px of [s0 - 8, s0 + sp * 4, s0 + sp * 8 + 8]) k.rect(px - 1.5, 52, 3, by - 52, 0.96, 'set');
    if (shut) {
      // the neon off: dead tubes on the frame, a little lighter than the night behind them
      for (let i = 0; i < letters.length; i++) k.text(letters[i], s0 + i * sp, sy, 38, 0.2, Object.assign({ mode: 'erase', stroke: 0.9 }, SIGN));
      k.text('H O T E L', 332, 58, 13, 0.22, Object.assign({ mode: 'erase' }, SIGN));
    } else {
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
    }
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
      if (!shut) k.rect(fx, p[1] - p[3], fw, p[3] * 2, k.lin(0, p[1] - p[3], 0, p[1] + p[3], [[0, 0.45], [1, 0]]), 'erase');
      k.rect(dx + 5, p[1] - p[3], 16, p[3] * 2, k.lin(0, p[1] - p[3], 0, p[1] + p[3], [[0, shut ? 0.35 : 0.6], [1, 0]]), 'erase');
      if (shut) k.rect(bx + 20 + 8 * 43, p[1] - p[3], 21, p[3] * 2, k.lin(0, p[1] - p[3], 0, p[1] + p[3], [[0, 0.5], [1, 0]]), 'erase');
      else for (let i = 0; i < letters.length; i++) if (i !== 5) { const x = s0 + i * sp; k.rect(x - 2.5, p[1] - p[3], 5, p[3] * 2, 0.5, 'erase'); }
      for (let y = p[1] - p[3] + 1.2; y < p[1] + p[3]; y += 1.7) k.line(p[0] - p[2], y, p[0] + p[2], y, 0.45, 0.35);
      k.done();
      if (!shut) {
        rd.clip(clipP);
        for (let i = 0; i < letters.length; i++) if (i !== 5) { const x = s0 + i * sp + (rnd() - 0.5) * 1.5; rd.rect(x - 2.5, p[1] - p[3], 5, p[3] * 2, rd.lin(0, p[1] - p[3], 0, p[1] + p[3], [[0, 0.95], [1, 0.35]])); }
        for (let y = p[1] - p[3] + 1.2; y < p[1] + p[3]; y += 1.7) rd.line(p[0] - p[2], y, p[0] + p[2], y, 0.55, 0.8, 'erase');
        rd.done();
      }
    }
    // rain bouncing where the light is
    for (let i = 0; i < 70; i++) { const x = dx - 40 + rnd() * 250, y = bb + 3 + rnd() * 26; k.line(x - 1, y, x, y - 1.6, 0.5, 0.5, 'erase'); k.line(x + 1, y, x, y - 1.6, 0.5, 0.5, 'erase'); }
    // trucks nose-in along the front, the near ones cut off by the edge; after close, gone, unless
    // one's been left where it was, its keys in the drawer inside
    if (!shut) {
      pickup(k, rd, 6, 228, 1.8, { side: 1 });
      pickup(k, rd, 482, 234, 2.05, { side: -1, window: 0.22 });
    } else if (look.truck) pickup(k, rd, 96, 222, 1.55, { side: 1, window: 0.75 });
    if (shut) {
      // with the sign off the front goes dark, and the red goes out of the paint; his window
      // stays lit, a bulb with no shade
      k.rect(bx - 10, by - 9, bw + 20, bb - by + 9, 0.26);
      rd.rect(bx, by, bw, bb - by, 0.45, 'erase');
      const wx = bx + 20 + 8 * 43, wy = by + 8 + 37;
      k.rect(wx, wy, 21, 25, 0.04, 'set');
      k.line(wx, wy + 12.5, wx + 21, wy + 12.5, 1.1, 0.8);
      rd.rect(wx, wy, 21, 25, 0.3);
      k.light(wx + 10.5, wy + 12, 34, 0.22, 20);
    }
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

  // a tone that changes with depth, fn(D), as a gradient across a wall at X = at (plane 'x') or a
  // floor or ceiling at height at (plane 'y'), from depth d0 to d1
  function depthTone(pen, cam, plane, at, d0, d1, fn, n) {
    n = n || 32;
    const pos = function (D) { return plane === 'y' ? cam.y(at, D) : cam.x(at, D); };
    const p0 = pos(d0), p1 = pos(d1), stops = [];
    // even steps on the plate, which are even steps in 1/D
    for (let i = 0; i <= n; i++) stops.push([i / n, fn(1 / (1 / d0 + i / n * (1 / d1 - 1 / d0)))]);
    return plane === 'y' ? pen.lin(0, p0, 0, p1, stops) : pen.lin(p0, 0, p1, 0, stops);
  }

  // paint on a side wall (at X = Xw) as if it faced you: fn(k, r) draws in centimetres from the
  // point (D, Yv) on the wall, u along it the way you'd read it standing in front of it, v down.
  // A local fit of the perspective, fine for anything smaller than a door.
  function onWall(j, cam, Xw, D, Yv, fn) {
    const f = cam.f, sg = Xw < 0 ? 1 : -1;
    const ux = sg * -Xw * f / (D * D) / 100, uy = sg * -(cam.eye - Yv) * f / (D * D) / 100, vy = f / D / 100;
    const x0 = cam.x(Xw, D), y0 = cam.y(Yv, D);
    for (const p of [j.k, j.r]) { p.c.save(); p.c.transform(ux, uy, 0, vy, x0, y0); }
    try { fn(j.k, j.r); } finally { j.k.c.restore(); j.r.c.restore(); }
  }

  // the same for something big and near, from dNear to dFar along the wall and yTop down to yBot:
  // fn(k, r) paints it flat, in centimetres, and it's laid onto the wall in thin upright strips,
  // each with its own fit, added together so the joins don't show
  const FLAT = {};
  function onWallBig(j, cam, Xw, dNear, dFar, yTop, yBot, fn, n) {
    n = n || 24;
    const left = Xw < 0, f = cam.f, sg = left ? 1 : -1, ym = (yTop + yBot) / 2, res = 10;
    const wcm = Math.abs(dFar - dNear) * 100, hcm = (yTop - yBot) * 100;
    const fk = PR.canvas(Math.ceil(wcm * res), Math.ceil(hcm * res)), fr = PR.canvas(fk.width, fk.height);
    const pk = new PR.Pen(fk.getContext('2d'), res), pr = new PR.Pen(fr.getContext('2d'), res);
    pk.c.setTransform(res, 0, 0, res, 0, 0); pr.c.setTransform(res, 0, 0, res, 0, 0);
    fn(pk, pr);
    if (!FLAT.k || FLAT.k.width !== j.w || FLAT.k.height !== j.h) { FLAT.k = PR.canvas(j.w, j.h); FLAT.r = PR.canvas(j.w, j.h); }
    const out = [[FLAT.k, fk, j.k], [FLAT.r, fr, j.r]];
    for (const o of out) { const c = o[0].getContext('2d'); c.setTransform(1, 0, 0, 1, 0, 0); c.globalCompositeOperation = 'source-over'; c.clearRect(0, 0, j.w, j.h); }
    for (let i = 0; i < n; i++) {
      const da = dNear + (dFar - dNear) * i / n, db = dNear + (dFar - dNear) * (i + 1) / n, dm = (da + db) / 2;
      const um = (left ? dm - dNear : dFar - dm) * 100;
      const ux = sg * -Xw * f / (dm * dm) / 100, uy = sg * -(cam.eye - ym) * f / (dm * dm) / 100, vy = f / dm / 100;
      const ox = cam.x(Xw, dm), oy = cam.y(yTop, dm);
      const q = [[cam.x(Xw, da), cam.y(yTop, da)], [cam.x(Xw, db), cam.y(yTop, db)], [cam.x(Xw, db), cam.y(yBot, db)], [cam.x(Xw, da), cam.y(yBot, da)]];
      for (const o of out) {
        const c = o[0].getContext('2d');
        c.save();
        c.setTransform(j.scale, 0, 0, j.scale, 0, 0);
        c.beginPath(); c.moveTo(q[0][0], q[0][1]); for (let e = 1; e < 4; e++) c.lineTo(q[e][0], q[e][1]); c.closePath(); c.clip();
        c.transform(ux, uy, 0, vy, ox - um * ux, oy - um * uy);
        c.globalCompositeOperation = 'lighter';
        c.drawImage(o[1], 0, 0, wcm, hcm);
        c.restore();
      }
    }
    // clear the wall under it and lay it down
    const whole = [[cam.x(Xw, dNear), cam.y(yTop, dNear)], [cam.x(Xw, dFar), cam.y(yTop, dFar)], [cam.x(Xw, dFar), cam.y(yBot, dFar)], [cam.x(Xw, dNear), cam.y(yBot, dNear)]];
    j.k.poly(whole, 0, 'set');
    for (const o of out) { const c = o[2].c; c.save(); c.setTransform(1, 0, 0, 1, 0, 0); c.drawImage(o[0], 0, 0); c.restore(); }
  }

  // light falling off down a side wall at Xw from yTop to yBot (the tubes are in the ceiling): ink
  // added from aTop to aBot, as a sweep round the vanishing point, which is how heights on a wall run
  function wallFall(k, cam, Xw, d0, d1, yTop, yBot, aTop, aBot) {
    const th = function (Yv) { return Math.atan2(cam.eye - Yv, Xw); };
    const TAU = Math.PI * 2, t1 = th(yTop), t2 = th(yBot);
    const start = Xw > 0 ? t1 : t2, span = (((Xw > 0 ? t2 - t1 : t1 - t2) % TAU) + TAU) % TAU;
    const g = k.c.createConicGradient(start, cam.vx, cam.hz);
    for (let i = 0; i <= 8; i++) {
      const t = i / 8, Yv = yTop + (yBot - yTop) * t, a = aTop + (aBot - aTop) * Math.pow(t, 1.4);
      const fr = ((((th(Yv) - start) % TAU) + TAU) % TAU) / TAU;
      g.addColorStop(Math.min(1, Math.max(0, fr)), 'rgba(0,0,0,' + a + ')');
    }
    k.poly([[cam.x(Xw, d0), cam.y(yTop, d0)], [cam.x(Xw, d1), cam.y(yTop, d1)], [cam.x(Xw, d1), cam.y(yBot, d1)], [cam.x(Xw, d0), cam.y(yBot, d0)]], g);
  }

  // A camera turned th off the run of a place, for looking along something and out at once: u runs
  // along it, w across it (to the right), Y up. Lines along u meet on the horizon at vu, lines
  // across it at vw. p(u, w, Y) is the point on the plate, sc(u, w) how big a metre is there.
  function turned(vx, hz, f, eye, th) {
    const c = Math.cos(th), s = Math.sin(th);
    const cam = { vx: vx, hz: hz, f: f, eye: eye, c: c, s: s, vu: vx - f * s / c, vw: vx + f * c / s };
    cam.D = function (u, w) { return u * c + w * s; };
    cam.p = function (u, w, Y) { const D = u * c + w * s, X = -u * s + w * c; return [vx + X * f / D, hz + (eye - Y) * f / D]; };
    cam.sc = function (u, w) { return f / (u * c + w * s); };
    return cam;
  }
  // a flat shape given in the world, cut off where it goes behind the eye, as points on the plate
  function shape3(cam, pts) {
    const out = [], n = pts.length, near = 0.08;
    for (let i = 0; i < n; i++) {
      const a = pts[i], b = pts[(i + 1) % n], da = cam.D(a[0], a[1]) - near, db = cam.D(b[0], b[1]) - near;
      if (da >= 0) out.push(a);
      if ((da >= 0) !== (db >= 0)) { const t = da / (da - db); out.push([a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t]); }
    }
    return out.map(function (q) { return cam.p(q[0], q[1], q[2]); });
  }
  // ink that changes along one thing where the lines of equal ink all meet at one point (cx, cy),
  // as they do on any flat surface in perspective: sample(t) is a point on the plate on the line
  // for t, fn(t) the ink there. A sweep round the point, so it's exact whatever the depth.
  function fan(ctx, cx, cy, t0, t1, sample, fn, n) {
    n = n || 40;
    const st = [];
    let a0 = null;
    for (let i = 0; i <= n; i++) {
      const t = t0 + (t1 - t0) * i / n, p = sample(t);
      let a = Math.atan2(p[1] - cy, p[0] - cx);
      if (a0 === null) a0 = a; else a = a0 + Math.atan2(Math.sin(a - a0), Math.cos(a - a0));
      st.push([a, clamp(fn(t), 0, 1)]);
    }
    st.sort(function (p, q) { return p[0] - q[0]; });
    const lo = st[0][0], TAU = Math.PI * 2, col = function (v) { return 'rgba(0,0,0,' + v + ')'; };
    const g = ctx.createConicGradient(lo, cx, cy);
    for (const q of st) g.addColorStop(Math.min(1, (q[0] - lo) / TAU), col(q[1]));
    // round the back of the sweep, each end holds its own value
    const mid = ((st[st.length - 1][0] - lo) / TAU + 1) / 2;
    g.addColorStop(mid, col(st[st.length - 1][1])); g.addColorStop(Math.min(1, mid + 1e-4), col(st[0][1]));
    return g;
  }
  // light on a surface that falls off two ways at once (along it and across it, from a lamp): a
  // and b make the two gradients (ctx => how much light, 0 to 1), their product comes off the ink
  const TWO = {};
  function lit2(j, pen, pts, a, b, amt) {
    if (!pts.length) return;
    if (!TWO.c || TWO.c.width !== j.w || TWO.c.height !== j.h) TWO.c = PR.canvas(j.w, j.h);
    const t = TWO.c.getContext('2d');
    t.setTransform(1, 0, 0, 1, 0, 0); t.globalCompositeOperation = 'source-over'; t.clearRect(0, 0, j.w, j.h);
    t.setTransform(j.scale, 0, 0, j.scale, 0, 0);
    const path = function () { t.beginPath(); t.moveTo(pts[0][0], pts[0][1]); for (let i = 1; i < pts.length; i++) t.lineTo(pts[i][0], pts[i][1]); t.closePath(); };
    path(); t.fillStyle = a(t); t.fill();
    if (b) { t.globalCompositeOperation = 'destination-in'; path(); t.fillStyle = b(t); t.fill(); }
    const c = pen.c;
    c.save(); c.setTransform(1, 0, 0, 1, 0, 0); c.globalAlpha = amt == null ? 1 : amt;
    c.globalCompositeOperation = 'destination-out'; c.drawImage(TWO.c, 0, 0); c.restore();
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

  // The front door from his stool: the door and its wired glass with the lot through it (the rain,
  // the pickup at the edge of the lot with its lights on, the sign's red), the jelly-jar lamp over
  // it, the ledge with the scanner and a glass of water, his stool, the smokes
  // machine, the jacket the last doorman walked out and left on the hook, the mat soaked through.
  PLACES.door = function (j, look, rnd) {
    const k = j.k, rd = j.r;
    const cam = camera(330, 92, 270, 1.35);
    const X = cam.x, Y = cam.y, S = cam.s;
    const light = look.light || 'night';
    const dark = light === 'dark', house = light === 'house';
    const DW = 3.4, s = S(DW), fy = Y(0, DW);
    const T = house ? { wall: 0.5, wood: 0.66, floor: 0.6, dark: 0.82 } : { wall: 0.94, wood: 1, floor: 1, dark: 1 };

    // the wall, the old boards below the chair rail, the floor
    k.rect(0, 0, W, fy, T.wall, 'set');
    const ry = Y(1.0, DW);
    boards(k, 0, ry, W, fy - ry, T.wood, 12, rnd, house ? 0.3 : 0.1);
    k.rect(0, ry - 2.5, W, 3.5, 1, 'set');
    k.line(0, ry - 2.5, W, ry - 2.5, 0.7, house ? 0.5 : 0.3, 'erase');
    k.rect(0, fy, W, H - fy, T.floor, 'set');
    // tiles going away, only where the lamp gets them
    k.clip(function (c) { c.rect(0, fy, W, H - fy); });
    for (let x = -3; x <= 3; x += 0.3) k.line(X(x, DW), fy, X(x, 1.2), Y(0, 1.2), 0.5, 0.35);
    for (const D of [3.1, 2.8, 2.55, 2.33]) k.line(0, Y(0, D), W, Y(0, D), 0.5, 0.35);
    k.done();

    // the jelly-jar lamp over the door, and its light on the door and the floor
    const lx = X(0, DW), ly = Y(2.36, DW);
    if (!dark) {
      k.light(lx, ly + 40, 150, house ? 0.2 : 0.5, 120);
      k.light(lx, fy + 10, 120, 0.4, 16);
    }

    // the board of notices: the meat draw, karaoke, a card about credit
    const nb = [X(-2.95, DW), Y(1.95, DW), X(-1.75, DW), Y(1.25, DW)];
    k.rect(nb[0], nb[1], nb[2] - nb[0], nb[3] - nb[1], 0.8, 'set');
    k.rect(nb[0] - 1.5, nb[1] - 1.5, nb[2] - nb[0] + 3, 1.5, 1, 'set');
    const notice = function (x, y, w, h, tone, rot) {
      k.c.save(); k.c.translate(x + w / 2, y + h / 2); k.c.rotate(rot); k.rect(-w / 2, -h / 2, w, h, tone, 'set'); k.c.restore();
    };
    notice(nb[0] + 4, nb[1] + 4, 34, 26, 0.04, -0.03);
    k.text('MEAT DRAW', nb[0] + 21, nb[1] + 13, 7, 1, { weight: 700 });
    k.text('SAT 3PM', nb[0] + 21, nb[1] + 21, 5.5, 0.85);
    rd.rect(nb[0] + 8, nb[1] + 23.5, 26, 2, 0.9);
    notice(nb[0] + 44, nb[1] + 6, 26, 32, 0.12, 0.05);
    k.text('KARAOKE', nb[0] + 57, nb[1] + 14, 5, 0.9, { weight: 700 });
    for (let i = 0; i < 4; i++) k.line(nb[0] + 48, nb[1] + 19 + i * 3.5, nb[0] + 66, nb[1] + 19 + i * 3.5, 0.5, 0.5);
    notice(nb[0] + 12, nb[1] + 33, 30, 18, 0.1, 0.02);
    for (let i = 0; i < 3; i++) k.line(nb[0] + 15, nb[1] + 38 + i * 4, nb[0] + 34 + rnd() * 6, nb[1] + 38 + i * 4, 0.55, 0.6);
    notice(nb[0] + 74, nb[1] + 4, 16, 20, 0.2, -0.06);

    // the ledge, burned along its front edge, the scanner on its stand, a glass of water
    const lgy = Y(1.05, DW), lg0 = X(-3.1, DW), lg1 = X(-1.25, DW);
    k.rect(lg0, lgy, lg1 - lg0, 4, 1, 'set');
    k.line(lg0, lgy + 0.3, lg1, lgy + 0.3, 0.9, house ? 0.6 : 0.75, 'erase');
    for (let i = 0; i < 7; i++) { const bx = lg0 + 8 + rnd() * (lg1 - lg0 - 16); k.oval(bx, lgy + 0.6, 1.6 + rnd() * 1.5, 0.6, 1, 'set'); }
    for (const bx of [lg0 + 10, lg1 - 10]) k.poly([[bx - 2, lgy + 4], [bx + 2, lgy + 4], [bx, lgy + 12]], 1, 'set');
    const sx = X(-2.2, DW);
    if (!dark) k.light(sx, lgy - 20, 34, 0.35);
    k.poly([[sx - 6, lgy], [sx + 6, lgy], [sx + 2, lgy - 12], [sx - 2, lgy - 12]], 1, 'set');
    k.c.save(); k.c.translate(sx, lgy - 22); k.c.rotate(-0.12);
    k.rect(-15, -11, 30, 21, 1, 'set');
    k.rect(-13, -9, 26, 17, dark ? 0.92 : 0.04, 'set');
    if (!dark) {
      k.rect(-10, -6, 9, 11, 0.6, 'set'); k.oval(-5.5, -2.8, 2, 2.3, 0.95, 'set'); k.path('M-9 5 Q-5.5 -0.5 -2 5 Z', 0.95, 'set');
      for (let i = 0; i < 3; i++) k.line(1.5, -4 + i * 3.2, 9.5, -4 + i * 3.2, 0.9, 0.6);
      rd.c.save(); rd.c.translate(sx, lgy - 22); rd.c.rotate(-0.12); rd.rect(-13, 4.5, 26, 3.5, 0.95); rd.c.restore();
      k.rect(-13, 4.5, 26, 3.5, 0.9, 'erase');
    }
    k.line(-15, -11, 15, -11, 0.7, 0.5, 'erase');
    k.c.restore();
    glass(k, X(-1.65, DW), lgy, 12, 0.08, 1);

    // MINORS PROHIBITED
    const mx = X(-0.95, DW), my = Y(1.72, DW);
    k.rect(mx - 22, my - 12, 44, 24, 1, 'set');
    k.rect(mx - 20.5, my - 10.5, 41, 21, 0.03, 'set');
    k.text('MINORS', mx, my - 1, 9, 1, { weight: 700, spacing: 0.6 });
    k.text('PROHIBITED', mx, my + 7.5, 6.4, 1, { weight: 700, spacing: 0.4 });

    // the door: steel, painted, the kick plate scuffed, the push bar, the wired glass
    const d0 = X(-0.48, DW), d1 = X(0.48, DW), dt = Y(2.1, DW);
    k.rect(X(-0.58, DW), Y(2.2, DW), X(0.58, DW) - X(-0.58, DW), fy - Y(2.2, DW), 1, 'set');
    if (!dark) { k.line(X(-0.58, DW), Y(2.2, DW), X(-0.58, DW), fy, 0.8, 0.6, 'erase'); k.line(X(-0.58, DW), Y(2.2, DW), X(0.58, DW), Y(2.2, DW), 0.8, 0.5, 'erase'); }
    k.rect(d0, dt, d1 - d0, fy - dt, house ? 0.72 : 0.93, 'set');
    if (!dark) k.rect(d0, dt, d1 - d0, fy - dt, k.rad(lx, dt, 5, 100, [[0, 0.28], [1, 0]]), 'erase');
    const kp = Y(0.3, DW);
    k.rect(d0 + 3, kp, d1 - d0 - 6, fy - kp - 2, house ? 0.5 : 0.62, 'set');
    for (let i = 0; i < 26; i++) { const x0 = d0 + 5 + rnd() * (d1 - d0 - 10), y0 = kp + 2 + rnd() * (fy - kp - 6); k.line(x0, y0, x0 + (rnd() - 0.5) * 12, y0 + (rnd() - 0.5) * 3, 0.4, 0.5, 'erase'); }
    const pb = Y(1.0, DW);
    k.rect(d0 + 4, pb - 3, d1 - d0 - 8, 6, 1, 'set');
    if (!dark) k.line(d0 + 5, pb - 2.2, d1 - 5, pb - 2.2, 0.9, 0.9, 'erase');
    for (const hy of [Y(1.9, DW), Y(0.35, DW)]) k.rect(d0 - 1.5, hy, 3, 10, 0.4, 'set');
    // the glass, and the lot through it
    const g0 = X(-0.3, DW), g1 = X(0.3, DW), gt = Y(1.9, DW), gb = Y(1.15, DW);
    k.rect(g0 - 3, gt - 3, g1 - g0 + 6, gb - gt + 6, 1, 'set');
    const inGlass = function (c) { c.rect(g0, gt, g1 - g0, gb - gt); };
    k.rect(g0, gt, g1 - g0, gb - gt, 0.9, 'set');
    k.clip(inGlass);
    // the far side of the lot, the lamp on its pole, the pickup with its lights on
    k.rect(g0, gt, g1 - g0, gb - gt, k.lin(0, gt, 0, gb, [[0, 0.1], [0.45, 0.5], [0.62, 0.72], [1, 0.4]]), 'erase');
    const hx = g0 + (g1 - g0) * 0.34, hy = gt + (gb - gt) * 0.64;
    k.rect(hx - 17, hy - 7, 36, 11, 1, 'set');
    k.rect(hx - 11, hy - 11, 22, 5, 1, 'set');
    for (const o of [-12, 13]) { k.light(hx + o, hy - 1, 18, 1); k.oval(hx + o, hy - 1, 3.2, 2.2, 0, 'set'); k.line(hx + o - 14, hy - 1, hx + o + 14, hy - 1, 0.9, 1, 'erase'); rd.oval(hx + o, hy - 1, 5, 3.6, 1, 'erase'); }
    k.rect(g1 - 16, gt, 2, gb - gt, 1, 'set');
    k.light(g1 - 15, gt + 10, 20, 0.6);
    k.rain(rnd, 70, g0, gt, g1 - g0, gb - gt, { tone: 0.8, len: 9, w: 0.7, slant: 0.03 });
    // drops running down the glass, the jelly jar's light caught in them
    for (let i = 0; i < 16; i++) { const x0 = g0 + rnd() * (g1 - g0), y0 = gt + rnd() * (gb - gt) * 0.7; k.line(x0, y0, x0 + (rnd() - 0.5) * 2, y0 + 6 + rnd() * 14, 0.9, 0.9, 'erase'); k.oval(x0, y0 + 0.5, 1, 1.2, 0.9, 'erase'); }
    // the wire in it
    for (let x = g0 + 3; x < g1; x += 5.2) k.line(x, gt, x, gb, 0.4, 0.55);
    for (let y = gt + 3; y < gb; y += 5.2) k.line(g0, y, g1, y, 0.4, 0.55);
    k.done();
    // the sign's red, on the glass
    rd.clip(inGlass);
    rd.rect(g0, gt, g1 - g0, gb - gt, rd.lin(0, gt, 0, gb, [[0, 0.8], [0.55, 0.25], [1, 0.05]]));
    rd.done();
    k.line(g0 - 3, gt - 3, g1 + 3, gt - 3, 0.8, 0.5, 'erase');

    // the lamp itself: a glass jar in a cage
    k.rect(lx - 7, ly - 13, 14, 4, 1, 'set');
    k.oval(lx, ly - 2, 7, 9, dark ? 0.9 : 0.03, 'set');
    for (let i = -2; i <= 2; i++) k.line(lx + i * 3, ly - 10, lx + i * 3.3, ly + 6, 0.7, 1);
    k.line(lx - 7, ly - 2, lx + 7, ly - 2, 0.7, 1);
    k.line(lx - 6, ly + 4, lx + 6, ly + 4, 0.7, 1);

    // the smokes machine: a tall box, the packs lit behind their glass, a pull knob under each
    const vm0 = X(0.95, DW), vm1 = X(1.62, DW), vmt = Y(1.78, DW);
    k.rect(vm0, vmt, vm1 - vm0, fy - vmt, 1, 'set');
    k.rect(vm0 + 4, vmt + 5, vm1 - vm0 - 8, 9, dark ? 0.9 : 0.1, 'set');
    if (!dark) { k.text('SMOKES', (vm0 + vm1) / 2, vmt + 12.5, 7.5, 1, { weight: 700, spacing: 1 }); }
    const pw = (vm1 - vm0 - 10) / 5;
    for (let r = 0; r < 3; r++) for (let q = 0; q < 5; q++) {
      const px = vm0 + 5 + q * pw, py = vmt + 20 + r * 17;
      k.rect(px + 0.8, py, pw - 1.6, 11, dark ? 0.9 : 0.12 + rnd() * 0.3, 'set');
      if (!dark) { k.rect(px + 0.8, py + 3, pw - 1.6, 2.4, 0.6 + rnd() * 0.3, 'set'); if (rnd() < 0.3) rd.rect(px + 0.8, py, pw - 1.6, 3, 0.9); }
    }
    for (let q = 0; q < 5; q++) { const px = vm0 + 5 + q * pw + pw / 2, py = vmt + 75; k.rect(px - 2.5, py, 5, 3, 0.5, 'set'); k.line(px - 2, py + 0.4, px + 2, py + 0.4, 0.5, 0.8, 'erase'); }
    if (!dark) k.light((vm0 + vm1) / 2, vmt + 45, 40, 0.18, 50);
    k.line(vm0 + 0.5, vmt, vm0 + 0.5, fy, 0.8, 0.5, 'erase');

    // the hooks, and his jacket on one: canvas, heavy, the lining showing at the collar
    const hky = Y(1.82, DW);
    k.rect(X(1.95, DW), hky - 3, X(3.3, DW) - X(1.95, DW), 5, 1, 'set');
    if (!dark) k.line(X(1.95, DW), hky - 2.6, X(3.3, DW), hky - 2.6, 1, 0.8, 'erase');
    for (let i = 0; i < 4; i++) { const hx2 = X(2.1 + i * 0.36, DW); k.stroke('M' + hx2 + ' ' + (hky + 1) + ' q0 7 5 6', 1.3, 1); }
    const jx = X(2.46, DW), jt = hky + 3, jh = 0.84 * s, jw = 0.26 * s;
    k.path('M' + (jx - 4) + ' ' + jt + ' L' + (jx + 4) + ' ' + jt + ' Q' + (jx + jw * 0.8) + ' ' + (jt + 5) + ' ' + (jx + jw) + ' ' + (jt + jh * 0.2) +
      ' L' + (jx + jw * 1.05) + ' ' + (jt + jh * 0.86) + ' L' + (jx + jw * 0.75) + ' ' + (jt + jh * 0.9) + ' L' + (jx + jw * 0.72) + ' ' + (jt + jh) + ' L' + (jx - jw * 0.72) + ' ' + (jt + jh) +
      ' L' + (jx - jw * 0.75) + ' ' + (jt + jh * 0.9) + ' L' + (jx - jw * 1.05) + ' ' + (jt + jh * 0.86) + ' L' + (jx - jw) + ' ' + (jt + jh * 0.2) + ' Q' + (jx - jw * 0.8) + ' ' + (jt + 5) + ' ' + (jx - 4) + ' ' + jt + ' Z', 1, 'set');
    k.poly([[jx - 5, jt + 1], [jx + 5, jt + 1], [jx, jt + 14]], house ? 0.4 : 0.55, 'set');
    k.line(jx, jt + 14, jx, jt + jh, 0.6, 0.45, 'erase');
    k.line(jx - jw * 0.55, jt + jh * 0.55, jx - jw * 0.15, jt + jh * 0.55, 0.6, 0.35, 'erase');
    if (!dark) {
      k.line(jx - jw + 0.7, jt + jh * 0.2, jx - jw * 1.04 + 0.7, jt + jh * 0.86, 1.4, 0.95, 'erase');
      k.line(jx - 4, jt + 0.6, jx - jw * 0.8, jt + 5.5, 1.2, 0.9, 'erase');
      k.line(jx - jw * 1.04 + 0.7, jt + jh * 0.86, jx - jw * 0.75, jt + jh * 0.9, 1, 0.7, 'erase');
      k.rect(jx - jw * 0.95, jt + jh * 0.25, jw * 0.35, jh * 0.6, k.lin(jx - jw, 0, jx - jw * 0.6, 0, [[0, 0.35], [1, 0]]), 'erase');
    }

    // the mat in front of the door, soaked, the lamp in the wet
    k.poly([[X(-0.72, DW - 0.05), Y(0, DW - 0.05)], [X(0.72, DW - 0.05), Y(0, DW - 0.05)], [X(0.8, 2.55), Y(0, 2.55)], [X(-0.8, 2.55), Y(0, 2.55)]], house ? 0.7 : 1, 'set');
    for (let i = 1; i < 12; i++) { const t = i / 12, x0 = -0.72 + t * 1.44, x1 = -0.8 + t * 1.6; k.line(X(x0, DW - 0.05), Y(0, DW - 0.05), X(x1, 2.55), Y(0, 2.55), 0.6, house ? 0.3 : 0.2, 'erase'); }
    if (!dark) k.light(lx, Y(0, 3.0), 40, 0.35, 6);

    // his stool in the corner of his eye
    const st = { x: X(-1.3, 2.2), yf: Y(0, 2.2), s: S(2.2) };
    stool(k, st.x, st.yf, st.s, 1);
    if (!dark) k.stroke(ell(st.x, st.yf - 0.72 * st.s, 0.19 * st.s * 0.96, 0.19 * st.s * 0.24, true), 1.2, 0.8, 'erase');

    // the room behind him, its light on the right edge of things
    if (!dark) k.light(W + 30, 110, 120, house ? 0.1 : 0.22, 130);
    if (dark) { k.rect(0, 0, W, H, 0.55); k.light((g0 + g1) / 2, (gt + gb) / 2, 70, 0.3, 60); }
    vignette(k, 0.35);
    edge(k);
  };

  // At the bar: the bar top with its rings and coasters and the card machine, the taps (one
  // handle red), the bartender pulling a pint, the till with the brass bell over it and the price
  // up on its pole, the limes and the knife, the bottles lit from under in front of the mirror,
  // and at the end of the bar a full glass nobody's drinking. Backs at the rail as it fills;
  // after close the stools go up on the bar top.
  PLACES.bar = function (j, look, rnd) {
    const k = j.k, rd = j.r;
    const cam = camera(320, 70, 300, 1.6);
    const X = cam.x, Y = cam.y, S = cam.s;
    const light = look.light || 'night';
    const dark = light === 'dark', house = light === 'house';
    const T = house ? { wall: 0.5, mirror: 0.45, fig: 0.84, top: 0.7, rim: 0.2 } : { wall: 0.96, mirror: dark ? 0.85 : 0.5, fig: 1, top: 1, rim: 0.7 };
    const DB = 3.3, sb = S(DB);

    // the wall behind the bar, the mirror
    k.rect(0, 0, W, H, T.wall, 'set');
    const m0 = Y(2.45, DB), m1 = Y(0.95, DB);
    k.rect(0, m0, W, m1 - m0, dark ? 0.9 : k.lin(0, m0, 0, m1, [[0, 0.6], [0.5, T.mirror], [1, 0.4]]), 'set');
    // the room in the mirror, dim: a lamp, the window, shapes
    if (!dark) {
      k.light(470, m0 + 30, 50, 0.2, 30);
      k.rect(520, m0 + 8, 90, 60, 0.18, 'erase');
      for (let i = 0; i < 6; i++) { const px = 40 + rnd() * 560, py = m1 - 12 - rnd() * 20; k.oval(px, py, 4, 5, 0.25, 'ink'); k.rect(px - 7, py + 4, 14, 14, 0.25); }
    }
    // four shelves of bottles, lit from under
    for (const h of [2.3, 1.95, 1.6, 1.25]) {
      shelf(k, rd, -4, W + 4, Y(h, DB), 0.3 * sb, rnd);
      if (!dark) k.light(W / 2, Y(h, DB) - 4, W * 0.7, house ? 0.08 : 0.18, 10);
    }
    // the brass bell over the till, its rope
    const bx = X(1.2, DB), by = Y(2.05, DB) + 10;
    k.rect(bx - 12, by - 12, 24, 3, 1, 'set');
    k.line(bx, by - 9, bx, by - 5, 1, 1);
    k.path('M' + (bx - 7) + ' ' + (by + 6) + ' Q' + (bx - 6) + ' ' + (by - 6) + ' ' + bx + ' ' + (by - 6) + ' Q' + (bx + 6) + ' ' + (by - 6) + ' ' + (bx + 7) + ' ' + (by + 6) + ' Z', house ? 0.5 : 0.7, 'set');
    if (!dark) { k.line(bx - 4, by + 4, bx - 3, by - 3, 1.1, 0.85, 'erase'); k.oval(bx - 3.5, by - 1, 1, 2.5, 1, 'erase'); }
    k.stroke('M' + (bx + 1) + ' ' + (by + 7) + ' q3 8 -1 16 q-3 6 1 12', 0.7, 1);

    // the back counter: the till, the limes and the knife, the ice well
    const DC = 3.0, cy = Y(0.95, DC), sc = S(DC);
    k.rect(0, cy, W, H - cy, 1, 'set');
    k.line(0, cy + 0.3, W, cy + 0.3, 0.8, house ? 0.6 : 0.4, 'erase');
    const t0 = X(0.85, DC), t1 = X(1.4, DC), tt = Y(1.28, DC);
    k.rect(t0, tt, t1 - t0, cy - tt, 1, 'set');
    k.poly([[t0 + 2, tt + 2], [t1 - 2, tt + 2], [t1 - 6, tt + 13], [t0 + 6, tt + 13]], house ? 0.6 : 0.8, 'set');
    for (let r = 0; r < 3; r++) for (let q = 0; q < 5; q++) k.rect(t0 + 9 + q * 7.5, tt + 16 + r * 5, 5, 3, dark ? 0.9 : 0.55, 'set');
    k.rect(t1 - 16, tt + 3, 11, 8, 0.12, 'set');
    k.line(t1 - 14, tt + 5.5, t1 - 7, tt + 5.5, 0.5, 0.6); k.line(t1 - 14, tt + 8, t1 - 9, tt + 8, 0.5, 0.6);
    // the price on the pole
    const px = (t0 + t1) / 2 - 8, pt = Y(1.62, DC);
    k.rect(px - 1.2, pt, 2.4, tt - pt, 1, 'set');
    k.rect(px - 15, pt - 11, 30, 12, 1, 'set');
    if (!dark) { k.text('8.50', px, pt - 2.3, 9.5, 1, { mode: 'erase', weight: 700, spacing: 1.2, font: '"Big Shoulders Display", "Barlow Condensed", sans-serif' }); k.light(px, pt - 5, 16, 0.12); }
    // the lime board and the knife
    const lb0 = X(0.05, DC), lb1 = X(0.6, DC);
    k.rect(lb0, cy - 3.5, lb1 - lb0, 3.5, house ? 0.35 : 0.5, 'set');
    for (let i = 0; i < 5; i++) {
      const wx = lb0 + 7 + i * 9.5, wy = cy - 3.5;
      k.path('M' + (wx - 4) + ' ' + wy + ' A4 4 0 0 1 ' + (wx + 4) + ' ' + wy + ' Z', 0.6, 'set');
      k.path('M' + (wx - 3) + ' ' + wy + ' A3 3 0 0 1 ' + (wx + 3) + ' ' + wy + ' Z', dark ? 0.8 : 0.15, 'set');
      if (!dark) for (let a = 1; a < 4; a++) k.line(wx, wy, wx + Math.cos(Math.PI + a * Math.PI / 4) * 2.6, wy + Math.sin(Math.PI + a * Math.PI / 4) * 2.6, 0.35, 0.5);
    }
    k.poly([[lb1 - 22, cy - 5], [lb1 + 4, cy - 8.5], [lb1 + 4, cy - 6.2], [lb1 - 22, cy - 4]], house ? 0.3 : 0.2, 'set');
    k.rect(lb1 + 4, cy - 9.5, 14, 4.5, 1, 'set');
    if (!dark) k.line(lb1 - 21, cy - 5.2, lb1 + 3, cy - 8.3, 0.5, 0.9, 'erase');

    // the bartender pulling a pint; after close at the till with a rye, counting
    const bt = { X: dark ? 1.05 : -0.78, D: 2.55 };
    person(k, cam, bt.X, bt.D, { pose: dark ? 'stand' : 'pour', build: 'slight', hair: 'bun', top: 'apron', tone: T.fig, light: 1, back: !house, rim: T.rim, rimW: 0.9, lit: 0.08, legs: false, tall: 1.66 });

    // the bar top: its far edge catching the bottles' light; the drip mat, the taps, the glasses
    const DF = 2.1, DN = 1.5, yf = Y(1.08, DF), yn = Y(1.08, DN);
    k.rect(0, yf, W, H - yf, 1, 'set');
    k.rect(0, yf, W, yn - yf, T.top, 'set');
    if (!dark) {
      k.rect(0, yf, W, yn - yf, k.lin(0, yf, 0, yn, [[0, 0.3], [0.4, 0.06], [1, 0]]), 'erase');
      k.line(0, yf + 0.4, W, yf + 0.4, 0.8, 0.8, 'erase');
      // rings and coasters
      for (let i = 0; i < 9; i++) { const rx = 20 + rnd() * 600, ryy = yf + 6 + rnd() * (yn - yf - 10), r = 5 + rnd() * 5; k.stroke(ell(rx, ryy, r, r * 0.22), 0.5, 0.45, 'erase'); }
      for (const c of [[92, 162], [548, 166], [410, 150]]) k.oval(c[0], c[1], 9, 2.2, 0.08, 'set');
    }
    k.rect(0, yn, W, 3, 1, 'set');
    if (!dark) k.line(0, yn + 0.5, W, yn + 0.5, 1, 0.55, 'erase');
    // the drip mat and the tap tower
    const tapX = [-0.98, -0.85, -0.72, -0.59, -0.46, -0.33], DT = 2.0;
    k.poly([[X(-1.08, 2.12), Y(1.08, 2.12)], [X(-0.24, 2.12), Y(1.08, 2.12)], [X(-0.24, 1.86), Y(1.08, 1.86)], [X(-1.08, 1.86), Y(1.08, 1.86)]], 0.9, 'set');
    for (let i = 0; i < 9; i++) { const yy = Y(1.08, 1.88 + i * 0.027); k.line(X(-1.06, 2.1), yy, X(-0.26, 2.1), yy, 0.35, dark ? 0.1 : 0.35, 'erase'); }
    k.rect(X(-1.08, DT), Y(1.33, DT), X(-0.23, DT) - X(-1.08, DT), 8, 1, 'set');
    if (!dark) k.line(X(-1.08, DT), Y(1.33, DT) + 0.5, X(-0.23, DT), Y(1.33, DT) + 0.5, 0.8, 0.8, 'erase');
    for (let i = 0; i < tapX.length; i++) {
      const tx = X(tapX[i], DT), ty = Y(1.33, DT);
      k.rect(tx - 1.6, ty + 6, 3.2, 9, 1, 'set');
      if (!dark) k.line(tx - 0.8, ty + 7, tx - 0.8, ty + 14, 0.6, 0.7, 'erase');
      const hh = 26 + (i % 3) * 3;
      k.path('M' + (tx - 3.2) + ' ' + ty + ' L' + (tx - 4.2) + ' ' + (ty - hh) + ' Q' + tx + ' ' + (ty - hh - 3) + ' ' + (tx + 4.2) + ' ' + (ty - hh) + ' L' + (tx + 3.2) + ' ' + ty + ' Z', i === 3 ? 0.35 : 1, 'set');
      if (i === 3) rd.path('M' + (tx - 3.2) + ' ' + ty + ' L' + (tx - 4.2) + ' ' + (ty - hh) + ' Q' + tx + ' ' + (ty - hh - 3) + ' ' + (tx + 4.2) + ' ' + (ty - hh) + ' L' + (tx + 3.2) + ' ' + ty + ' Z', 1);
      if (!dark) k.line(tx - 2.6, ty - 2, tx - 3.3, ty - hh + 2, 0.9, i === 3 ? 0.3 : 0.75, 'erase');
      k.rect(tx - 3.5, ty - hh * 0.45, 7, 5, i === 3 ? 0.5 : 0.25, 'set');
    }
    // the pint she's pulling, beer running into it
    if (!dark) {
      const gx = X(tapX[5], DT) + 1, gy = Y(1.08, 1.95);
      k.line(gx, Y(1.33, DT) + 15, gx, gy - 20, 1.1, 0.5, 'erase');
      glass(k, gx, gy, 24, 0.55, 1);
    }
    // glasses on the bar, and at the end of the bar the full one nobody's drinking
    if (!dark) {
      for (const g of [[1.5, 1.95, 0.4], [1.72, 1.8, 0.1], [-1.9, 1.9, 0.6]]) glass(k, X(g[0], g[1]), Y(1.08, g[1]), 0.15 * S(g[1]), g[2], 1);
      glass(k, X(-1.58, 2.02), Y(1.08, 2.02), 0.15 * S(2.02), 0.95, 1);
      // the card machine
      const cm = [X(0.75, 1.8), Y(1.08, 1.8)];
      k.poly([[cm[0] - 9, cm[1]], [cm[0] + 9, cm[1]], [cm[0] + 7, cm[1] - 20], [cm[0] - 7, cm[1] - 20]], 1, 'set');
      k.rect(cm[0] - 5, cm[1] - 18, 10, 6, 0.1, 'set');
      for (let r = 0; r < 3; r++) for (let q = 0; q < 3; q++) k.rect(cm[0] - 5 + q * 3.6, cm[1] - 10 + r * 2.8, 2.4, 1.6, 0.5, 'set');
    }
    // after close, the stools go up on the bar top, legs in the air
    if (dark) {
      for (let i = 0; i < 5; i++) {
        const ux = X(-2.4 + i * 1.2, 1.75), uy = Y(1.08, 1.75), s = S(1.75), r = 0.19 * s;
        k.oval(ux, uy - 0.04 * s, r, r * 0.26, 1, 'set');
        for (const d of [-1, 1]) k.line(ux + d * r * 0.72, uy - 0.05 * s, ux + d * r * 1.05, uy - 0.72 * s, Math.max(0.6, s * 0.028), 1);
        k.stroke(ell(ux, uy - 0.46 * s, r * 0.92, r * 0.2), Math.max(0.5, s * 0.02), 1);
      }
    }

    // who's at the rail: backs in the foreground, more of them as it fills
    const crowd = dark ? 0 : clamp(look.crowd | 0, 0, 6);
    const spots = [
      { X: 1.05, D: 1.32, top: 'hivis', hat: 'cap' }, { X: -1.12, D: 1.36, top: 'jacket', hair: 'short' },
      { X: 1.78, D: 1.75, top: 'flannel', hair: 'messy' }, { X: -1.8, D: 1.8, top: 'coat', hair: 'long' },
      { X: 0.64, D: 1.45, top: 'hoodie', hat: 'beanie' }, { X: -0.52, D: 1.42, top: 'jacket', hat: 'flatcap' }
    ].slice(0, crowd).sort(function (a, b) { return b.D - a.D; });
    for (const p of spots) person(k, cam, p.X, p.D, Object.assign({ pose: 'sitback', seat: 0.76, tone: T.fig, light: -1, back: !house, rim: T.rim * 0.8, rimW: 0.8, lit: 0.04 }, p));

    if (house) k.rect(0, 0, W, H, 0.1, 'erase');
    if (dark) {
      k.rect(0, 0, W, H, 0.45);
      rd.rect(0, 0, W, H, 0.5, 'erase');
      k.light(X(1.05, 2.8), Y(1.6, 2.8), 90, 0.5, 70);
    }
    vignette(k, 0.35);
    edge(k);
  };

  // Table 28 from the empty chair: five of them against the front window, the rain on it and the
  // lot out there with the pickup's lights on and the sign's red coming down the glass; the
  // glasses stacking up in front of them through the night, the scratch tickets and the coins.
  // Down by the baseboard, the hole, and a rat at it while the old man's still coming round.
  PLACES.t28 = function (j, look, rnd) {
    const k = j.k, rd = j.r;
    const cam = camera(320, 86, 260, 1.2);
    const X = cam.x, Y = cam.y, S = cam.s;
    const light = look.light || 'night';
    const dark = light === 'dark', house = light === 'house';
    const DW = 3.2, sw = S(DW), sill = Y(0.8, DW), fy = Y(0, DW);
    const T = house ? { wall: 0.5, fig: 0.82, rim: 0.2, glassOut: 0.7 } : { wall: 1, fig: 1, rim: 0.85, glassOut: dark ? 0.4 : 0.12 };

    // the window: the lot at night through four big panes
    k.rect(0, 0, W, sill, 1, 'set');
    const panes = [-3.9, -2.4, -0.8, 0.8, 2.4, 3.9];
    const tr = Y(2.05, DW);
    for (let i = 0; i < panes.length - 1; i++) {
      const x0 = X(panes[i], DW) + 3, x1 = X(panes[i + 1], DW) - 3;
      const inPane = function (c) { c.rect(x0, tr + 3, x1 - x0, sill - tr - 6); };
      k.rect(x0, tr + 3, x1 - x0, sill - tr - 6, T.glassOut, 'set');
      k.clip(inPane);
      // the lot: the far edge dark, the wet catching the building's light
      k.rect(x0, tr, x1 - x0, 30, k.lin(0, tr, 0, tr + 30, [[0, 0.6], [1, 0]]));
      k.rect(x0, sill - 22, x1 - x0, 22, k.lin(0, sill - 22, 0, sill, [[0, 0], [1, 0.35]]));
      k.done();
      k.rect(x0, 0, x1 - x0, tr, dark ? 0.6 : 0.4, 'set');
      rd.clip(function (c) { c.rect(x0, 0, x1 - x0, sill); });
      rd.rect(x0, 0, x1 - x0, sill, rd.lin(0, 0, 0, sill * 0.75, [[0, 0.85], [1, 0]]));
      rd.done();
    }
    // out there: the pickup with its lights on at the edge of the lot, the lamp on its pole
    const px = X(-1.6, DW), py = tr + 48;
    k.rect(px - 36, py - 10, 76, 16, 1, 'set');
    k.path('M' + (px - 22) + ' ' + (py - 10) + ' L' + (px - 16) + ' ' + (py - 21) + ' L' + (px + 12) + ' ' + (py - 21) + ' L' + (px + 20) + ' ' + (py - 10) + ' Z', 1, 'set');
    for (const o of [-26, 28]) { k.light(px + o, py - 3, 30, 0.95, 20); k.oval(px + o, py - 3, 3.5, 2.4, 0, 'set'); k.line(px + o - 22, py - 3, px + o + 22, py - 3, 0.7, 0.9, 'erase'); }
    k.rect(X(2.9, DW), 0, 3, py + 4, 1, 'set');
    k.light(X(2.9, DW) - 6, tr + 8, 40, dark ? 0.2 : 0.5, 40);
    // rain on the glass
    for (let i = 0; i < panes.length - 1; i++) {
      const x0 = X(panes[i], DW) + 3, x1 = X(panes[i + 1], DW) - 3;
      k.clip(function (c) { c.rect(x0, 0, x1 - x0, sill - 3); });
      k.rain(rnd, 110, x0, 0, x1 - x0, sill, { tone: 0.55, len: 8, w: 0.6, ink: true, slant: 0.03 });
      for (let n = 0; n < 12; n++) { const x = x0 + rnd() * (x1 - x0), y = rnd() * sill * 0.8; k.line(x, y, x + (rnd() - 0.5) * 2, y + 8 + rnd() * 18, 1, 0.9, 'erase'); k.oval(x, y + 0.5, 1.3, 1.5, 0.95, 'erase'); }
      k.done();
    }
    // the frame: mullions, transom
    for (const p of panes) k.rect(X(p, DW) - 3, 0, 6, sill, 1, 'set');
    k.rect(0, tr - 3, W, 6, 1, 'set');
    // the wall under the sill, the baseboard, and the hole in it
    k.rect(0, sill, W, H - sill, T.wall, 'set');
    k.rect(0, sill - 2, W, 5, 1, 'set');
    if (!dark) k.line(0, sill - 1.6, W, sill - 1.6, 0.9, 0.7, 'erase');
    boards(k, 0, sill + 3, W, fy - sill - 3, house ? 0.66 : 1, 13, rnd, house ? 0.3 : 0.06);
    const hx = X(1.95, DW), hy = fy - 1;
    k.rect(0, fy - 7, W, 7, 1, 'set');
    k.path('M' + (hx - 8) + ' ' + hy + ' Q' + (hx - 7) + ' ' + (hy - 9) + ' ' + hx + ' ' + (hy - 9.5) + ' Q' + (hx + 7) + ' ' + (hy - 9) + ' ' + (hx + 8) + ' ' + hy + ' Z', 1, 'set');
    if (!dark) k.stroke('M' + (hx - 8) + ' ' + hy + ' Q' + (hx - 7) + ' ' + (hy - 9) + ' ' + hx + ' ' + (hy - 9.5), 0.6, 0.5, 'erase');
    // the carpet
    k.rect(0, fy, W, H - fy, house ? 0.6 : 1, 'set');
    if (look.rat) {
      // a rat at the hole, the last fry of the night by it
      const rx = hx + 14, ryy = fy + 5;
      k.path('M' + (rx - 10) + ' ' + ryy + ' Q' + (rx - 9) + ' ' + (ryy - 7) + ' ' + (rx - 1) + ' ' + (ryy - 7.5) + ' Q' + (rx + 5) + ' ' + (ryy - 7) + ' ' + (rx + 9) + ' ' + (ryy - 3) + ' L' + (rx + 13) + ' ' + (ryy - 1.5) + ' L' + (rx + 9) + ' ' + ryy + ' Z', 1, 'set');
      k.oval(rx + 3, ryy - 7.5, 2, 2.2, 1, 'set');
      k.stroke('M' + (rx - 10) + ' ' + (ryy - 1) + ' q-10 1 -16 -4', 0.9, 1);
      if (!dark) { k.stroke('M' + (rx - 9) + ' ' + (ryy - 4) + ' Q' + (rx - 8) + ' ' + (ryy - 7.4) + ' ' + (rx - 1) + ' ' + (ryy - 7.6), 0.6, 0.6, 'erase'); rd.oval(rx + 7.5, ryy - 4, 0.9, 0.9, 1); k.oval(rx + 7.5, ryy - 4, 0.9, 0.9, 1, 'erase'); }
      k.rect(rx + 16, ryy - 1.2, 7, 1.6, dark ? 0.8 : 0.15, 'set');
    }

    // the five, in the seats they've had since two o'clock, the window behind them
    const five = dark ? [] : [
      { X: -1.32, D: 2.95, pose: 'sitside', top: 'jacket', hat: 'cap', badge: true },
      { X: -0.66, D: 3.08, pose: 'sitback', top: 'jacket', hair: 'short', aid: true },
      { X: 0.02, D: 3.12, pose: 'sitback', top: 'cardigan', hair: 'bun', build: 'slight' },
      { X: 0.68, D: 3.05, pose: 'sittalk', top: 'coat', hat: 'cap' },
      { X: 1.3, D: 2.92, pose: 'sitside', flip: true, top: 'flannel', hair: 'short', specs: true }
    ];
    for (const p of five) {
      const J = person(k, cam, p.X, p.D, Object.assign({ tone: T.fig, light: 1, back: !house, rim: T.rim * 0.7, rimW: 0.85, lit: 0.05, tall: 1.72 }, p));
      const s = S(p.D), hd = J.hd;
      // what tells them apart against the light: the crest, the hearing aid, the big glasses
      if (p.badge && !house) k.oval(J.sa[0] + 0.05 * s, J.sa[1] + 0.12 * s, 0.035 * s, 0.035 * s, 0.6, 'erase');
      if (p.aid && !house) k.stroke('M' + (hd[0] + 0.05 * s) + ' ' + (hd[1] - 0.03 * s) + ' q' + (0.035 * s) + ' ' + (0.02 * s) + ' ' + (0.01 * s) + ' ' + (0.07 * s), 0.9, 1, 'erase');
      if (p.specs && !house) { k.line(hd[0] - 0.075 * s, hd[1] - 0.012 * s, hd[0] - 0.035 * s, hd[1] - 0.012 * s, 0.8, 0.9, 'erase'); k.oval(hd[0] - 0.07 * s, hd[1] - 0.004 * s, 0.9, 1.2, 1, 'erase'); }
    }

    // the table: big, round, its top shining with the window in it
    const DT = 1.95, st = S(DT), ty = Y(0.74, DT), rx = 1.0 * st;
    const yb = Y(0.74, DT + 1.0), yfr = Y(0.74, DT - 1.0);
    const ry = (yfr - yb) / 2, tcy = (yfr + yb) / 2;
    k.oval(X(0, DT), tcy + 5, rx, ry, 1, 'set');
    k.oval(X(0, DT), tcy, rx, ry, dark ? 1 : T.fig * 0.97, 'set');
    if (!dark) {
      k.clip(function (c) { c.ellipse(X(0, DT), tcy, rx, ry, 0, 0, Math.PI * 2); });
      k.rect(0, yb, W, ry * 0.9, k.lin(0, yb, 0, yb + ry * 0.9, [[0, house ? 0.2 : 0.55], [1, 0]]), 'erase');
      for (const p of panes) k.rect(X(p, DW) - 2, yb, 4, ry * 0.8, 0.5);
      k.done();
      k.stroke(ell(X(0, DT), tcy, rx, ry, true), 1.3, 0.9, 'erase');
    } else {
      for (const o of [-0.62, 0, 0.62]) {
        const ux = X(o, DT + 0.25), uy = Y(0.74, DT + 0.25), s = S(DT + 0.25), r = 0.21 * s;
        k.rect(ux - r, uy - 0.05 * s, r * 2, 0.05 * s, 1, 'set');
        const top = uy - 0.5 * s;
        for (const d of [-1, -0.45, 0.45, 1]) k.line(ux + d * r * 0.9, uy - 0.04 * s, ux + d * r * 0.98, top, Math.abs(d) === 1 ? 2.2 : 1.6, 1);
        k.line(ux - r * 0.92, uy - 0.3 * s, ux + r * 0.92, uy - 0.3 * s, 1.3, 1);
        k.line(ux - r * 0.96, top + 0.06 * s, ux + r * 0.96, top + 0.06 * s, 1.1, 1);
      }
    }
    // the glasses: in front of each of them, stacking up; the scratch tickets; the coins
    if (!dark) {
      const n = clamp(look.glasses || 6, 4, 16);
      const spots = [];
      for (let i = 0; i < 16; i++) {
        const seat = i % 5, row = Math.floor(i / 5);
        const a = Math.PI * (1.12 + seat * 0.19) + (rnd() - 0.5) * 0.08;
        const rr = 0.72 - row * 0.15 + (rnd() - 0.5) * 0.05;
        spots.push([X(0, DT) + Math.cos(a) * rx * rr, tcy - Math.sin(a) * ry * rr * -1, row]);
      }
      const chosen = spots.slice(0, n).sort(function (a, b) { return a[1] - b[1]; });
      for (let i = 0; i < chosen.length; i++) {
        const g = chosen[i], gs = 0.15 * S(DT + (1 - (g[1] - yb) / (2 * ry)) * 0.8);
        glass(k, g[0], g[1], gs, g[2] === 0 ? (i % 2 ? 0.45 : 0.2) : 0.1, 1);
      }
      // the scratch tickets in front of the one with the coin
      const sx = X(0.75, DT + 0.35), sy = Y(0.74, DT + 0.35);
      for (let i = 0; i < 3; i++) {
        k.c.save(); k.c.translate(sx + i * 9, sy + i * 2); k.c.rotate(-0.1 + i * 0.12);
        k.rect(-6, -3, 12, 6, 0.04, 'set');
        k.rect(-4, -1.6, 8, 3.2, i === 0 ? 0.9 : 0.6, 'set');
        if (i) for (let q = 0; q < 5; q++) k.line(-3.5 + q * 1.8, -1.2, -3.2 + q * 1.8, 1.2, 0.5, 0.7, 'erase');
        k.c.restore();
      }
      for (const c of [[sx - 12, sy + 4], [sx - 7, sy + 7]]) { k.oval(c[0], c[1], 3.2, 1.4, 0.4, 'set'); k.stroke(ell(c[0], c[1], 3.2, 1.4, true), 0.5, 0.9, 'erase'); }
      // in front of the empty chair, a coaster somebody put down for him
      const ex = X(-0.18, DT - 0.62), ey = Y(0.74, DT - 0.62);
      k.oval(ex, ey, 0.05 * S(DT - 0.62), 0.014 * S(DT - 0.62), 0.12, 'set');
      k.stroke(ell(ex, ey, 0.05 * S(DT - 0.62), 0.014 * S(DT - 0.62)), 0.6, 0.6);
    }
    if (house) k.rect(0, 0, W, H, 0.1, 'erase');
    if (dark) k.rect(0, sill, W, H - sill, 0.4);
    vignette(k, 0.32);
    edge(k);
  };

  // The pool table under its lamp: the big man bent to his shot at the end of the table with the
  // cue in his left hand, the buddy chalking his, the balls on the cloth with the red three, a
  // twenty under the rail. When the heat's up, people standing in the dark watching.
  PLACES.pool = function (j, look, rnd) {
    const k = j.k, rd = j.r;
    const cam = camera(300, 48, 300, 1.9);
    const X = cam.x, Y = cam.y, S = cam.s;
    const light = look.light || 'night';
    const dark = light === 'dark', house = light === 'house';
    const T = house ? { room: 0.5, fig: 0.84, rim: 0.25 } : { room: 1, fig: 1, rim: 0.7 };
    const DC = 3.05, s = S(DC), nD = DC - 0.56, fD = DC + 0.56, L0 = -1.12, L1 = 1.12;

    // the room: dark, the jukebox glowing back there, the pillar with the dartboard
    k.rect(0, 0, W, H, T.room, 'set');
    const DB = 6.5;
    if (!dark || true) {
      const jx0 = X(-2.3, DB), jx1 = X(-1.7, DB), jt = Y(1.72, DB), jb = Y(0, DB);
      k.light((jx0 + jx1) / 2, (jt + jb) / 2, 40, 0.3, 50);
      k.rect(jx0, jt, jx1 - jx0, jb - jt, 1, 'set');
      k.rect(jx0 + 2, jt + 3, jx1 - jx0 - 4, (jb - jt) * 0.48, 0.08, 'set');
      for (let r = 0; r < 3; r++) for (let q = 0; q < 2; q++) k.rect(jx0 + 4 + q * 8, jt + 6 + r * 9, 6, 6, 0.3 + rnd() * 0.5, 'set');
      rd.rect(jx0, jt, 1.4, jb - jt, 0.9); rd.rect(jx1 - 1.4, jt, 1.4, jb - jt, 0.9);
      k.rect(jx0, jt, 1.4, jb - jt, 0.8, 'erase'); k.rect(jx1 - 1.4, jt, 1.4, jb - jt, 0.8, 'erase');
      rd.glow((jx0 + jx1) / 2, jt + 20, 30, 0.3, 40);
    }
    const pl0 = X(2.2, DB), pl1 = X(2.55, DB);
    k.rect(pl0, 0, pl1 - pl0, Y(0, DB), 1, 'set');
    const dbx = (pl0 + pl1) / 2, dby = Y(1.73, DB), dr = 0.23 * S(DB);
    k.oval(dbx, dby, dr * 1.25, dr * 1.25, 1, 'set');
    k.oval(dbx, dby, dr, dr, dark ? 0.9 : 0.5, 'set');
    if (!dark) { rd.c.save(); rd.c.lineWidth = dr * 0.14; rd.c.strokeStyle = 'rgba(0,0,0,.9)'; rd.c.beginPath(); rd.c.arc(dbx, dby, dr * 0.94, 0, 7); rd.c.stroke(); rd.c.beginPath(); rd.c.arc(dbx, dby, dr * 0.6, 0, 7); rd.c.stroke(); rd.c.restore(); }

    // people watching, back in the dark, when the heat's up
    if (look.watched && !dark) {
      for (const w of [[-2.6, 4.6, 'armsx', 'hoodie', 'hood'], [-0.2, 5.0, 'easy', 'jacket', 'cap'], [2.0, 4.4, 'stand', 'flannel', null], [0.9, 4.8, 'armsx', 'coat', 'beanie']]) {
        person(k, cam, w[0], w[1], { pose: w[2], top: w[3], hat: w[4], hair: 'short', tone: T.fig, light: 1, rim: T.rim * 0.5, rimY: -1, lit: 0.04, glass: w[2] === 'easy' });
      }
    }

    // the lamp: a long shade low over the table, and all the light there is
    const lw = 1.5 * s, ly = Y(1.8, DC), lcx = X(0, DC);
    k.line(lcx - lw * 0.3, 0, lcx - lw * 0.3, ly - 7, 0.8, 1);
    k.line(lcx + lw * 0.3, 0, lcx + lw * 0.3, ly - 7, 0.8, 1);
    const q = [[X(L0, fD), Y(0.8, fD)], [X(L1, fD), Y(0.8, fD)], [X(L1, nD), Y(0.8, nD)], [X(L0, nD), Y(0.8, nD)]];
    if (!dark) {
      cone(k, lcx - lw / 2 + 4, lcx + lw / 2 - 4, ly + 1, q[3][0] - 10, q[2][0] + 10, q[3][1], house ? 0.05 : 0.14, 0.9);
      k.light(lcx, Y(0, DC), 2.4 * s, 0.35, 0.6 * s);
    }

    // the buddy at the far end, chalking his cue
    if (!dark) {
      person(k, cam, L0 - 0.45, DC + 0.35, { pose: 'easy', build: 'medium', hat: 'cap', top: 'jacket', tone: T.fig, light: 1, rim: T.rim * 0.9, rimY: -0.6, lit: 0.08 });
      const bx = X(L0 - 0.3, DC + 0.35), by = Y(0, DC + 0.35);
      k.line(bx, by - 2, bx + 6, Y(1.5, DC + 0.35), 1.6, 1);
      if (!dark) k.line(bx + 0.8, by - 20, bx + 5.5, Y(1.45, DC + 0.35), 0.6, 0.5, 'erase');
    }

    // the table: the rails, the pockets, the cloth lit hard, the balls
    const rail = 0.12;
    const R = [[X(L0 - rail, fD + rail), Y(0.8, fD + rail)], [X(L1 + rail, fD + rail), Y(0.8, fD + rail)], [X(L1 + rail, nD - rail), Y(0.8, nD - rail)], [X(L0 - rail, nD - rail), Y(0.8, nD - rail)]];
    // the body under the rail and the legs
    k.poly([[R[3][0], R[3][1]], [R[2][0], R[2][1]], [R[2][0], Y(0.55, nD - rail)], [R[3][0], Y(0.55, nD - rail)]], 1, 'set');
    for (const lx of [L0 + 0.1, L1 - 0.1]) k.rect(X(lx, nD) - 6, Y(0.55, nD), 12, Y(0, nD) - Y(0.55, nD), 1, 'set');
    k.rect(X(0, nD) - 10, Y(0.55, nD), 20, Y(0, nD) - Y(0.55, nD), 1, 'set');
    k.poly(R, 1, 'set');
    k.poly(q, dark ? 0.85 : (house ? 0.5 : 0.42), 'set');
    if (!dark) {
      k.poly(q, k.rad(lcx, Y(0.8, DC), 4, 1.25 * s, [[0, house ? 0.25 : 0.4], [0.7, 0.12], [1, 0]]), 'erase');
      // the rail's edge catching it
      k.line(R[3][0], R[3][1] + 0.5, R[2][0], R[2][1] + 0.5, 1.2, 0.85, 'erase');
      k.line(q[0][0], q[0][1] - 0.4, q[1][0], q[1][1] - 0.4, 0.8, 0.4, 'erase');
      // the diamonds on the rail
      for (let i = 1; i < 8; i++) { const t = i / 8; k.oval(R[3][0] + (R[2][0] - R[3][0]) * t, (R[3][1] + q[3][1]) / 2 + 1, 1.3, 0.6, 0.9, 'erase'); }
    }
    // the pockets
    for (const pp of [[L0, fD], [0, fD + 0.02], [L1, fD], [L0, nD], [0, nD - 0.02], [L1, nD]]) {
      k.oval(X(pp[0], pp[1]), Y(0.8, pp[1]), 0.07 * S(pp[1]), 0.022 * S(pp[1]), 1, 'set');
    }
    // a twenty tucked under the near rail, the chalk on the corner
    if (!dark) {
      const mx = X(0.62, nD - 0.1), my = Y(0.8, nD - 0.1) + 2;
      k.poly([[mx - 9, my - 1], [mx + 9, my - 2], [mx + 10, my + 3], [mx - 8, my + 4]], 0.15, 'set');
      k.line(mx - 5, my + 1, mx + 6, my + 0.5, 0.5, 0.5);
      rd.oval(mx + 6, my + 1, 1.6, 1, 0.6);
      k.rect(X(L1 + 0.04, nD - 0.08) - 3, Y(0.8, nD - 0.08) - 3, 6, 4, 0.7, 'set');
    }
    // the balls
    const balls = dark ? [] : [[-0.62, DC - 0.1, 'w'], [-0.35, DC + 0.2, 's'], [0.05, DC - 0.28, 'r'], [0.3, DC + 0.3, 'k'], [0.52, DC - 0.05, 'st'], [0.78, DC + 0.36, 's'], [-0.9, DC + 0.4, 'st'], [0.95, DC - 0.35, 's']];
    for (const b of balls) {
      const bx = X(b[0], b[1]), by = Y(0.83, b[1]), br = 0.03 * S(b[1]);
      k.oval(bx + br * 0.5, by + br * 0.85, br * 1.2, br * 0.4, 0.9);
      if (b[2] === 'w') k.oval(bx, by, br, br, 0.02, 'set');
      else if (b[2] === 'r') { k.oval(bx, by, br, br, 0.3, 'set'); rd.oval(bx, by, br, br, 1); k.oval(bx, by, br * 0.45, br * 0.45, 0.05, 'set'); }
      else if (b[2] === 'st') { k.oval(bx, by, br, br, 0.05, 'set'); k.rect(bx - br, by - br * 0.45, br * 2, br * 0.9, 0.95); }
      else k.oval(bx, by, br, br, b[2] === 'k' ? 1 : 0.85, 'set');
      k.oval(bx - br * 0.35, by - br * 0.4, br * 0.28, br * 0.22, 0.9, 'erase');
    }
    if (dark) {
      // the balls racked for tomorrow
      for (let r = 0; r < 5; r++) for (let c = 0; c <= r; c++) { const bx = X(0.5 + r * 0.055, DC - r * 0.03 + c * 0.06), by = Y(0.83, DC - r * 0.03 + c * 0.06); k.oval(bx, by, 0.03 * s, 0.03 * s, 0.9, 'set'); }
    }

    // the big man at the end of the table, bent to it, the cue in his left hand
    if (!dark) {
      person(k, cam, L1 + 0.62, DC + 0.02, { pose: 'shootL', flip: true, build: 'big', hair: 'short', top: 'flannel', tone: T.fig, light: -1, rim: T.rim * 0.8, rimW: 0.8, rimY: -1.3, lit: 0.05, tall: 1.9 });
    }
    // the lamp's shade over it all
    k.poly([[lcx - lw / 2, ly], [lcx + lw / 2, ly], [lcx + lw / 2 - 8, ly - 8], [lcx - lw / 2 + 8, ly - 8]], 1, 'set');
    if (!dark) { k.rect(lcx - lw / 2 + 3, ly - 0.8, lw - 6, 1.8, 0, 'set'); k.line(lcx - lw / 2 + 8, ly - 8, lcx + lw / 2 - 8, ly - 8, 0.9, 0.75, 'erase'); k.line(lcx - lw / 2, ly, lcx - lw / 2 + 8, ly - 8, 0.8, 0.5, 'erase'); }

    if (house) k.rect(0, 0, W, H, 0.1, 'erase');
    if (dark) k.rect(0, 0, W, H, 0.4);
    vignette(k, 0.35);
    edge(k);
  };

  // The back hall from the end of the pool table: the single washroom first on the left, shut, the
  // light on in there and OCCUPIED in the little window over the handle; the women's and the men's
  // further down with their signs out over the doors, a wet floor sign; on the right the dead
  // payphone with forty years of phone numbers round it; an old photo of the hotel; tubes in the
  // ceiling, the middle one going; at the end the hotel door under the EXIT sign, wedged open with
  // the stair light coming down the hall, or shut.
  PLACES.hall = function (j, look, rnd) {
    const k = j.k, rd = j.r;
    const cam = camera(340, 92, 250, 1.75);
    const X = cam.x, Y = cam.y, S = cam.s;
    const XL = -0.85, XR = 0.85, CH = 2.45, DN = 0.45, DE = 8.6;
    const open = look.open !== false;
    const TUBES = [[1.1, 2.1, 1], [3.9, 4.9, 0.18], [6.4, 7.4, 0.95]];
    // how much light there is at each depth: under the tubes, and the stairs' through the end door
    const L = function (D) {
      let l = 0;
      for (const t of TUBES) l += t[2] * Math.exp(-Math.pow((D - (t[0] + t[1]) / 2) / 1.25, 2));
      l += (open ? 0.6 : 0.1) * Math.exp(-Math.pow((D - DE) / 1.6, 2));
      return Math.min(1, l);
    };
    const quad = function (Xw, y0, y1, d0, d1) { return [[X(Xw, d0), Y(y1, d0)], [X(Xw, d1), Y(y1, d1)], [X(Xw, d1), Y(y0, d1)], [X(Xw, d0), Y(y0, d0)]]; };
    const flat = function (Yh, x0, x1, d0, d1) { return [[X(x0, d0), Y(Yh, d0)], [X(x1, d0), Y(Yh, d0)], [X(x1, d1), Y(Yh, d1)], [X(x0, d1), Y(Yh, d1)]]; };
    const byDepth = function (plane, at, d0, d1, fn) { return depthTone(k, cam, plane, at, d0, d1, fn); };

    // the ceiling, the floor and the walls: lit under the tubes, dark between
    k.rect(0, 0, W, H, 0.9, 'set');
    k.poly(flat(CH, XL, XR, DN, DE), byDepth('y', CH, DN, DE, function (D) { return clamp(0.97 - 0.36 * L(D), 0.55, 0.97); }), 'set');
    k.poly(flat(0, XL, XR, DN, DE), byDepth('y', 0, DN, DE, function (D) { return clamp(0.92 - 0.62 * L(D), 0.3, 0.95); }), 'set');
    for (const Xw of [XL, XR]) {
      k.poly(quad(Xw, 0.98, CH, DN, DE), byDepth('x', Xw, DN, DE, function (D) { return clamp(0.93 - 0.92 * L(D), 0.03, 0.93); }), 'set');
      wallFall(k, cam, Xw, DN, DE, CH, 0.98, 0, 0.42);
      k.poly(quad(Xw, 0, 0.98, DN, DE), byDepth('x', Xw, DN, DE, function (D) { return clamp(0.99 - 0.42 * L(D), 0.55, 1); }), 'set');
      // the boards of the wainscot, the chair rail with the light along its top, the baseboard
      for (let D = DN + 0.06; D < DE; D += 0.11) k.line(X(Xw, D), Y(0.96, D), X(Xw, D), Y(0.1, D), Math.max(0.3, 0.012 * S(D)), 0.5);
      k.poly(quad(Xw, 0.95, 1.02, DN, DE), 1, 'set');
      k.line(X(Xw, DN), Y(1.02, DN), X(Xw, DE), Y(1.02, DE), 1.3, byDepth('x', Xw, DN, DE, function (D) { return 0.95 * L(D); }), 'erase');
      k.poly(quad(Xw, 0, 0.1, DN, DE), 1, 'set');
    }

    // the end wall, and the hotel door in it
    const ex0 = X(-0.46, DE), ex1 = X(0.46, DE), et = Y(2.05, DE), eb = Y(0, DE), ew = ex1 - ex0, eh = eb - et;
    k.rect(X(XL, DE), Y(CH, DE), X(XR, DE) - X(XL, DE), eb - Y(CH, DE), clamp(0.92 - 0.85 * L(DE), 0.15, 0.92), 'set');
    k.rect(X(XL, DE), Y(1.02, DE), X(XR, DE) - X(XL, DE), eb - Y(1.02, DE), 0.93, 'set');
    k.rect(ex0 - 1.6, et - 1.6, ew + 3.2, eh + 1.6, 1, 'set');
    if (open) {
      // wedged open: the stairs up to the rooms, lit, and the light of them down the hall
      k.rect(ex0, et, ew, eh, 0, 'set');
      for (let i = 0; i < 8; i++) {
        const y = eb - eh * 0.08 - i * eh * 0.1, x = ex0 + ew * 0.36 + i * ew * 0.085;
        k.line(x, y, ex1, y, 0.7, 0.6);
        k.line(x, y, x, y + eh * 0.1, 0.45, 0.3);
      }
      k.line(ex0 + ew * 0.32, eb - eh * 0.46, ex1, et + eh * 0.12, 0.9, 0.85);
      k.rect(ex0 + ew * 0.29, eb - eh * 0.5, ew * 0.05, eh * 0.5, 0.85, 'set');
      k.poly([[ex1, et], [ex1 - ew * 0.26, et + eh * 0.05], [ex1 - ew * 0.26, eb - eh * 0.015], [ex1, eb]], 0.95, 'set');
      k.poly([[ex1 - ew * 0.3, eb + 0.3], [ex1 - ew * 0.08, eb + 0.3], [ex1 - ew * 0.3, eb - eh * 0.05]], 1, 'set');
      k.poly([[ex0, eb], [ex1, eb], [X(0.66, 4.4), Y(0, 4.4)], [X(-0.34, 4.4), Y(0, 4.4)]], k.lin(0, eb, 0, Y(0, 4.4), [[0, 0.75], [1, 0]]), 'erase');
      k.light((ex0 + ex1) / 2, (et + eb) / 2, 30, 0.4, 40);
    } else {
      // shut: the push bar, the wired window, the light under it
      k.rect(ex0, et, ew, eh, 0.94, 'set');
      k.rect(ex0 + ew * 0.3, et + eh * 0.14, ew * 0.4, eh * 0.24, 0.5, 'set');
      for (let g = 1; g < 4; g++) k.line(ex0 + ew * 0.3, et + eh * (0.14 + g * 0.06), ex0 + ew * 0.7, et + eh * (0.14 + g * 0.06), 0.3, 0.6);
      k.rect(ex0 + 1.5, et + eh * 0.5, ew - 3, 1.2, 0.3, 'set');
      k.line(ex0 + 1, eb - 0.4, ex1 - 1, eb - 0.4, 0.9, 1, 'erase');
      k.poly([[ex0, eb], [ex1, eb], [X(0.5, 7), Y(0, 7)], [X(-0.5, 7), Y(0, 7)]], k.lin(0, eb, 0, Y(0, 7), [[0, 0.35], [1, 0]]), 'erase');
    }
    // EXIT, lit
    const sx = (ex0 + ex1) / 2, sy = Y(2.3, DE), sw = 0.42 * S(DE), sh = 0.2 * S(DE);
    rd.glow(sx, sy, sw * 2.4, 0.5);
    k.rect(sx - sw / 2 - 0.7, sy - sh / 2 - 0.7, sw + 1.4, sh + 1.4, 1, 'set');
    k.rect(sx - sw / 2, sy - sh / 2, sw, sh, 0, 'set');
    rd.text('EXIT', sx, sy + sh * 0.36, sh * 1.05, 1, { weight: 700, max: sw * 0.92 });
    k.light(sx, sy, sw * 1.3, 0.35);

    // the carpet runner, dark, its pattern showing only where the light's on it, worn down the middle
    k.poly(flat(0, -0.52, 0.52, DN, DE), byDepth('y', 0, DN, DE, function (D) { return clamp(1 - 0.32 * L(D), 0.6, 1); }), 'set');
    for (let D = 3.3; D < DE - 0.2; D += 0.36) {
      const a = 0.42 * L(D);
      k.poly([[X(-0.3, D), Y(0, D)], [X(0, D - 0.15), Y(0, D - 0.15)], [X(0.3, D), Y(0, D)], [X(0, D + 0.15), Y(0, D + 0.15)]], a, 'erase');
      k.poly([[X(-0.14, D), Y(0, D)], [X(0, D - 0.07), Y(0, D - 0.07)], [X(0.14, D), Y(0, D)], [X(0, D + 0.07), Y(0, D + 0.07)]], a, 'ink');
    }
    for (const x of [-0.45, 0.45]) k.line(X(x, DN), Y(0, DN), X(x, DE), Y(0, DE), 0.8, byDepth('y', 0, DN, DE, function (D) { return 0.6 * L(D); }), 'erase');
    k.poly(flat(0, -0.2, 0.2, DN, DE), byDepth('y', 0, DN, DE, function (D) { return 0.16 * L(D); }), 'erase');

    // the doors down the left: the single, then the women's and the men's
    const DOORS = [[1.15, 1.95, 'single'], [3.3, 4.1, 'WOMEN'], [5.25, 6.05, 'MEN']];
    const XD = XL - 0.05;
    for (const d of DOORS) {
      const d0 = d[0], d1 = d[1];
      k.poly(quad(XL, 0, 2.13, d0 - 0.08, d1 + 0.08), 1, 'set');
      k.poly(quad(XD, 0, 2.05, d0, d1), byDepth('x', XD, d0, d1, function (D) { return clamp(0.96 - 0.4 * L(D), 0.55, 0.96); }), 'set');
      // the near casing hides the edge of the door; the far jamb catches the light
      k.poly(quad(XL, 0, 2.13, d0 - 0.08, d0), 1, 'set');
      k.poly([[X(XD, d1), Y(2.05, d1)], [X(XL, d1), Y(2.05, d1)], [X(XL, d1), Y(0, d1)], [X(XD, d1), Y(0, d1)]], clamp(0.25 + 0.8 * L(d1), 0, 0.95), 'erase');
      k.line(X(XL, d0 - 0.08), Y(2.13, d0 - 0.08), X(XL, d1 + 0.08), Y(2.13, d1 + 0.08), 0.8, 0.7 * L(d0), 'erase');
      // the kick plate
      k.poly(quad(XD, 0.04, 0.28, d0 + 0.05, d1 - 0.05), 0.5, 'set');
      if (d[2] === 'single') {
        // the light's on in there: it shows round the edge of the door
        k.line(X(XD, d1 - 0.006), Y(2.04, d1), X(XD, d1 - 0.006), Y(0.02, d1), 0.9, 1, 'erase');
        k.line(X(XD, d0 + 0.04), Y(2.046, d0 + 0.04), X(XD, d1), Y(2.046, d1), 0.8, 0.8, 'erase');
        // the lever, and over it the bolt's little window: OCCUPIED
        onWall(j, cam, XD, d1 - 0.1, 1.02, function (kk) {
          kk.rect(-4, -6, 8, 15, 0.35, 'set');
          kk.rect(-15, 1.2, 17, 3.2, 1, 'set');
          kk.line(-15, 1.6, 2, 1.6, 0.9, 0.9, 'erase');
          kk.oval(0, 2.8, 3.2, 3.2, 1, 'set');
        });
        onWall(j, cam, XD, d1 - 0.1, 1.3, function (kk, rr) {
          kk.rect(-5.5, -4.5, 11, 13, 0.3, 'set');
          kk.rect(-4.8, -3.6, 9.6, 5, 1, 'set');
          rr.rect(-4.2, -3.1, 8.4, 4, 1);
          kk.rect(-4.2, -3.1, 8.4, 4, 0.08, 'set');
          kk.text('OCCUPIED', 0, 0.3, 2.2, 0.35, { weight: 700, max: 8 });
          kk.oval(0, 5, 2.4, 2.4, 0.95, 'set');
          kk.line(-1.8, 5, 1.8, 5, 0.9, 0.6, 'erase');
        });
        // a sheet taped to the door
        onWall(j, cam, XD, d0 + 0.26, 1.74, function (kk) {
          kk.rect(0, 0, 28, 21, 0.05, 'set');
          kk.text('ONE PERSON', 14, 8.6, 6.4, 0.95, { weight: 700 });
          kk.text('AT A TIME', 14, 16.2, 6.4, 0.95, { weight: 700 });
          for (const c of [[-1.5, -1.5], [25.5, -1.5], [-1.5, 19.5], [25.5, 19.5]]) kk.rect(c[0], c[1], 4, 3, 0.3, 'set');
        });
      } else {
        // the push plate, and the sign out over the door facing up the hall
        k.poly(quad(XD, 1.02, 1.36, d1 - 0.13, d1 - 0.05), 0.2, 'set');
        const dm = (d0 + d1) / 2, s = S(dm);
        const x0 = X(XL, dm), x1 = X(XL + 0.38, dm), y0 = Y(2.36, dm), y1 = Y(2.16, dm);
        k.line(x0, y0 - 0.8, x1 - 1, y0 - 0.8, Math.max(0.6, 0.012 * s), 1);
        k.rect(x0 + 0.5, y0, x1 - x0 - 0.5, y1 - y0, 1, 'set');
        k.rect(x0 + 0.5 + 0.02 * s, y0 + 0.02 * s, x1 - x0 - 0.5 - 0.04 * s, y1 - y0 - 0.04 * s, 0.03, 'set');
        k.text(d[2], (x0 + x1) / 2 + 0.3, y1 - (y1 - y0) * 0.24, (y1 - y0) * 0.66, 1, { weight: 700, max: x1 - x0 - 0.1 * s });
      }
    }

    // an old photo of the hotel on the near wall, the staff out front, the tube in its glass
    onWallBig(j, cam, XL, 0.66, 1.06, 1.92, 1.6, function (kk) {
      kk.rect(0, 0, 40, 32, 1, 'set');
      kk.rect(3, 3, 34, 26, 0.07, 'set');
      kk.rect(6, 5.5, 28, 17.5, kk.lin(0, 5.5, 0, 23, [[0, 0.22], [0.55, 0.35], [1, 0.5]]), 'set');
      kk.rect(8.5, 9.5, 23, 10, 0.72, 'set');
      kk.rect(8, 8.6, 24, 1.2, 0.9, 'set');
      for (let r = 0; r < 2; r++) for (let c = 0; c < 9; c++) kk.rect(9.6 + c * 2.45, 10.6 + r * 3.2, 1.1, 1.7, 0.3, 'set');
      kk.rect(8.5, 17.2, 23, 0.7, 0.95, 'set');
      for (let i = 0; i < 16; i++) { const x = 9.2 + i * 1.4 + (i % 3) * 0.2; kk.rect(x, 18.6, 0.55, 2.4, 0.95, 'set'); kk.oval(x + 0.27, 18.3, 0.36, 0.42, 0.95, 'set'); }
      kk.oval(33, 20.3, 2.2, 1.1, 0.8, 'set');
      kk.text('1911', 20, 27.6, 2.4, 0.7, { weight: 600 });
      kk.poly([[4, 29], [13, 3], [19, 3], [10, 29]], 0.5, 'erase');
    }, 28);

    // the payphone on the right, dead, and forty years of numbers on the wall round it
    const P0 = 1.45, P1 = 1.66, PX = XR - 0.14, PT = 1.72, PB = 1.15;
    const SCRAWL = [
      ['TRUCK FOR SALE', 2.05, 1.96, 5.4, -3, 'k', 700], ['CALL SHEILA', 1.98, 1.5, 3.8, 2, 'r', 600], ['HARBOUR CABS 24 HRS', 1.36, 2.06, 3.8, -1, 'k', 600],
      ['754-0092', 1.3, 1.3, 4.2, -5, 'k', 700], ['DAVE', 2.3, 1.78, 3.4, 1, 'k', 500], ['MANDY', 1.22, 1.64, 4, 4, 'r', 700],
      ['R + D', 1.24, 1.9, 4.2, 0, 'k', 700], ['FOR A GOOD TIME', 2.36, 1.16, 3, 3, 'k', 500], ['NO', 1.18, 1.1, 4.4, -8, 'k', 700]
    ];
    // thickest where a hand can reach with the phone to its ear, thinning out away from it
    for (let i = 0, got = 0; i < 400 && got < 80; i++) {
      const a = rnd() * Math.PI * 2, r = Math.sqrt(rnd());
      const D = 1.55 + Math.cos(a) * r * 0.75, Yv = 1.46 + Math.sin(a) * r * 0.62;
      if (D < 1.06 || Yv < 1.0 || Yv > 2.14) continue;
      if (D > P0 - 0.1 && D < P1 + 0.05 && Yv > PB - 0.06 && Yv < PT + 0.06) continue;
      got++;
      let n = '';
      for (let c = 0; c < 7; c++) n += (c === 0 ? 7 : Math.floor(rnd() * 10)) + (c === 2 ? '-' : '');
      const q = rnd();
      SCRAWL.push([q < 0.22 ? '250 ' + n : q < 0.34 ? n.slice(0, 3) + ' ' + ['JEN', 'TY', 'BIG MIKE', 'ROXY', 'CAB', 'LORNA', 'WES'][Math.floor(rnd() * 7)] : n, D, Yv, 2 + rnd() * 1.5, (rnd() - 0.5) * 14, rnd() < 0.14 ? 'r' : 'k', rnd() < 0.5 ? 700 : 600, rnd()]);
    }
    for (const w of SCRAWL) {
      onWall(j, cam, XR, w[1], w[2], function (kk, rr) {
        kk.c.rotate(w[4] * Math.PI / 180);
        const pen = w[5] === 'r' ? rr : kk, tone = 1, len = w[0].length * w[3] * 0.42;
        pen.text(w[0], 0, 0, w[3], tone, { weight: w[6], align: 'left' });
        // some crossed out, some underlined, some ringed
        if (w[7] != null && w[7] < 0.12) for (let z = 0; z < 5; z++) pen.line(z * len / 5, -w[3] * 0.8, (z + 1.4) * len / 5, 0.4, 0.5, tone);
        else if (w[7] != null && w[7] < 0.22) pen.line(0, 1, len, 0.6, 0.45, tone);
        else if (w[7] != null && w[7] < 0.28) pen.stroke(ell(len / 2, -w[3] * 0.35, len * 0.62, w[3] * 0.9), 0.4, tone);
      });
    }
    // a heart with two sets of initials, and a third scratched in and scratched out
    onWall(j, cam, XR, 2.0, 1.34, function (kk) {
      kk.stroke('M0 5 C-7 -1 -4 -8 0 -3.2 C4 -8 7 -1 0 5', 0.7, 0.9);
      kk.text('J+K', 0, 0.6, 3, 0.9, { weight: 600 });
      kk.text('T.M.', 10, 1, 3.4, 0.9, { weight: 600, align: 'left' });
      for (let z = 0; z < 7; z++) kk.line(9.5 + z * 1.3, -2.5, 10.5 + z * 1.3, 1.6, 0.9, 1);
    });
    // the phone: its steel side toward you, the handset, the armoured cord, the keypad
    k.poly([[X(PX, P0), Y(PT, P0)], [X(XR, P0), Y(PT, P0)], [X(XR, P0), Y(PB, P0)], [X(PX, P0), Y(PB, P0)]], 0.92, 'set');
    k.poly([[X(PX, P0), Y(PT, P0)], [X(PX, P1), Y(PT, P1)], [X(PX, P1), Y(PB, P1)], [X(PX, P0), Y(PB, P0)]], 0.7, 'set');
    k.line(X(PX, P0) + 0.5, Y(PT, P0), X(PX, P0) + 0.5, Y(PB, P0), 1, 0.8, 'erase');
    k.line(X(PX, P0), Y(PT, P0) + 0.5, X(XR, P0), Y(PT, P0) + 0.5, 1, 0.9, 'erase');
    for (let r = 0; r < 4; r++) for (let c = 0; c < 3; c++) {
      const D = P0 + 0.05 + c * 0.045, Yv = 1.5 - r * 0.05;
      k.rect(X(PX, D) - 0.9, Y(Yv, D) - 0.9, 1.8, 1.6, 0.85, 'erase');
    }
    k.rect(X(PX, P0 + 0.06) - 3, Y(1.64, P0 + 0.06), 5, 2.4, 1, 'set');
    k.line(X(PX, P0 + 0.14) - 1, Y(1.63, P0 + 0.14), X(PX, P0 + 0.14) + 1.4, Y(1.63, P0 + 0.14), 0.8, 1);
    const hx = X(PX - 0.04, P0 + 0.005), s1 = S(P0);
    k.rect(hx - 0.035 * s1, Y(1.64, P0), 0.07 * s1, 0.4 * s1, 1, 'set');
    k.oval(hx, Y(1.64, P0), 0.05 * s1, 0.04 * s1, 1, 'set');
    k.oval(hx, Y(1.24, P0), 0.05 * s1, 0.04 * s1, 1, 'set');
    k.line(hx - 0.02 * s1, Y(1.6, P0), hx - 0.02 * s1, Y(1.28, P0), 0.9, 0.7, 'erase');
    k.stroke('M' + hx + ' ' + Y(1.22, P0) + ' C' + (hx - 0.06 * s1) + ' ' + Y(0.92, P0) + ' ' + (hx + 0.14 * s1) + ' ' + Y(0.86, P0) + ' ' + (X(XR - 0.05, P0 + 0.08)) + ' ' + Y(PB, P0 + 0.08), Math.max(1, 0.028 * s1), 1);
    k.stroke('M' + hx + ' ' + Y(1.22, P0) + ' C' + (hx - 0.06 * s1) + ' ' + Y(0.92, P0) + ' ' + (hx + 0.14 * s1) + ' ' + Y(0.86, P0) + ' ' + (X(XR - 0.05, P0 + 0.08)) + ' ' + Y(PB, P0 + 0.08), 0.6, 0.7, 'erase');

    // a wet floor sign by the men's
    { const D = 4.9, s = S(D), x = X(-0.5, D), y = Y(0, D), w = 0.3 * s, h = 0.62 * s;
      k.poly([[x - w * 0.42, y - h], [x + w * 0.42, y - h], [x + w / 2, y], [x - w / 2, y]], 0.08, 'set');
      k.stroke('M' + (x - w * 0.42) + ' ' + (y - h) + ' L' + (x + w * 0.42) + ' ' + (y - h) + ' L' + (x + w / 2) + ' ' + y + ' L' + (x - w / 2) + ' ' + y + ' Z', 0.9, 1);
      k.rect(x - w * 0.4, y - h * 0.86, w * 0.8, h * 0.14, 1, 'set');
      k.path('M' + (x - w * 0.12) + ' ' + (y - h * 0.3) + ' L' + x + ' ' + (y - h * 0.6) + ' L' + (x + w * 0.16) + ' ' + (y - h * 0.3) + ' Z', 0.9, 'set');
      k.oval(x + w * 0.04, y - h * 0.66, w * 0.05, w * 0.05, 0.9, 'set'); }

    // the tubes in the ceiling, the middle one going
    for (const t of TUBES) {
      const c = (t[0] + t[1]) / 2;
      k.light(X(0, c), Y(CH, c) + 2, 0.9 * S(c), 0.5 * t[2], 0.25 * S(c));
      k.poly(flat(CH, -0.17, 0.17, t[0] - 0.04, t[1] + 0.04), 1, 'set');
      if (t[2] > 0.5) k.poly(flat(CH, -0.12, 0.12, t[0], t[1]), 0, 'set');
      else {
        k.poly(flat(CH, -0.12, 0.12, t[0], t[1]), 0.6, 'set');
        k.poly(flat(CH, -0.12, 0.12, t[0] + 0.25, t[1] - 0.3), 0.3, 'set');
      }
    }
    vignette(k, 0.28);
    edge(k);
  };

  // The kitchen through the swing door at the end of the bar: the line down the left under the
  // hood (the pass with its heat lamps and the fries going soft under them, the flat-top, the
  // fryer with the cook at it, his t-shirt soaked dark down the back, shaking a basket of wings),
  // the steel prep table, the walk-in at the back, and the back door to the alley propped with a
  // milk crate, the steam going out and the rain coming in, or shut. After eleven the cook's gone:
  // dark, the dead heat lamps, and the little light on the walk-in.
  PLACES.kitchen = function (j, look, rnd) {
    const k = j.k, rd = j.r;
    const cam = camera(400, 84, 250, 1.75);
    const X = cam.x, Y = cam.y, S = cam.s;
    const XL = -2.9, XR = 0.7, CH = 2.7, DN = 0.5, DB = 6.2;
    const open = look.open !== false, on = look.cook !== false;
    const t = function (lit, dark) { return on ? lit : dark; };
    const quad = function (Xw, y0, y1, d0, d1) { return [[X(Xw, d0), Y(y1, d0)], [X(Xw, d1), Y(y1, d1)], [X(Xw, d1), Y(y0, d1)], [X(Xw, d0), Y(y0, d0)]]; };
    const flat = function (Yh, x0, x1, d0, d1) { return [[X(x0, d0), Y(Yh, d0)], [X(x1, d0), Y(Yh, d0)], [X(x1, d1), Y(Yh, d1)], [X(x0, d1), Y(Yh, d1)]]; };
    const front = function (D, x0, x1, y0, y1) { return [[X(x0, D), Y(y1, D)], [X(x1, D), Y(y1, D)], [X(x1, D), Y(y0, D)], [X(x0, D), Y(y0, D)]]; };
    // a box standing in the room: its top, the face toward you, and the side toward the middle
    const box = function (x0, x1, d0, d1, y0, y1, tTop, tFront, tSide) {
      if (tSide != null) {
        if (x1 < 0) k.poly(quad(x1, y0, y1, d0, d1), tSide, 'set');
        else if (x0 > 0) k.poly(quad(x0, y0, y1, d0, d1), tSide, 'set');
      }
      if (tTop != null && y1 < cam.eye) k.poly(flat(y1, x0, x1, d0, d1), tTop, 'set');
      if (tFront != null) k.poly(front(d0, x0, x1, y0, y1), tFront, 'set');
    };

    // the room: white tile and steel under the tubes, a quarry-tile floor
    k.rect(0, 0, W, H, t(0.3, 0.86), 'set');
    k.poly(flat(CH, XL, XR, DN, DB), t(k.lin(0, 0, 0, Y(CH, DB), [[0, 0.55], [1, 0.38]]), 0.88), 'set');
    k.poly(quad(XR, 0, CH, DN, DB), t(k.lin(W, 0, X(XR, DB), 0, [[0, 0.1], [1, 0.16]]), 0.84), 'set');
    k.poly(quad(XL, 0, CH, DN, DB), t(0.14, 0.86), 'set');
    k.poly(front(DB, XL, XR, 0, CH), t(0.1, 0.84), 'set');
    k.poly(flat(0, XL, XR, DN, DB), t(k.lin(0, H, 0, Y(0, DB), [[0, 0.88], [1, 0.74]]), 0.9), 'set');
    if (on) {
      // the grout, and the tubes shining in the wet
      for (let x = XL + 0.3; x < XR; x += 0.3) k.line(X(x, DN), Y(0, DN), X(x, DB), Y(0, DB), 0.6, 0.3, 'erase');
      for (let D = 1.3; D < DB; D += 0.3) k.line(X(XL, D), Y(0, D), X(XR, D), Y(0, D), Math.max(0.35, 0.004 * S(D)), 0.3, 'erase');
      for (const tb of [[-1.0, 2.5], [-1.0, 4.8]]) k.poly([[X(tb[0] - 0.2, tb[1]), Y(0, tb[1])], [X(tb[0] + 0.2, tb[1]), Y(0, tb[1])], [X(tb[0] + 0.3, 1.5), Y(0, 1.5)], [X(tb[0] - 0.3, 1.5), Y(0, 1.5)]], k.lin(0, Y(0, tb[1]), 0, Y(0, 1.5), [[0, 0.5], [1, 0]]), 'erase');
      // white tile up the walls
      for (let y = 1.0; y < CH; y += 0.15) {
        k.line(X(XR, DN), Y(y, DN), X(XR, DB), Y(y, DB), 0.4, 0.22);
        k.line(X(XL, DN), Y(y, DN), X(XL, DB), Y(y, DB), 0.4, 0.2);
        k.line(X(XL, DB), Y(y, DB), X(XR, DB), Y(y, DB), 0.35, 0.22);
      }
      for (let D = 0.6; D < DB; D += 0.15) k.line(X(XR, D), Y(1.0, D), X(XR, D), Y(CH, D), 0.3, 0.15);
      for (let x = XL; x < XR; x += 0.15) k.line(X(x, DB), Y(1.0, DB), X(x, DB), Y(CH, DB), 0.3, 0.16);
    }

    // the back wall: the walk-in, and the door to the alley
    const wx0 = -2.45, wx1 = -1.35;
    k.poly(front(DB, wx0 - 0.08, wx1 + 0.08, 0, 2.18), t(0.6, 0.97), 'set');
    k.poly(front(DB, wx0, wx1, 0, 2.1), t(k.lin(X(wx0, DB), 0, X(wx1, DB), 0, [[0, 0.42], [0.35, 0.12], [0.55, 0.3], [1, 0.5]]), 0.93), 'set');
    if (on) for (let i = 1; i < 14; i++) k.line(X(wx0 + i * (wx1 - wx0) / 14, DB), Y(2.08, DB), X(wx0 + i * (wx1 - wx0) / 14, DB), Y(0.05, DB), 0.3, 0.2 + (i % 3) * 0.1);
    for (const hy of [0.4, 1.7]) k.rect(X(wx0 - 0.02, DB), Y(hy + 0.1, DB), 0.06 * S(DB), 0.2 * S(DB), t(1, 0.97), 'set');
    k.rect(X(wx1 - 0.22, DB), Y(1.18, DB), 0.16 * S(DB), 0.22 * S(DB), t(1, 0.97), 'set');
    k.rect(X(wx1 - 0.2, DB), Y(1.1, DB), 0.12 * S(DB), 0.05 * S(DB), t(0.2, 0.8), 'set');
    // the little light on the walk-in: after eleven, the only one
    const gx = X(wx0 + 0.14, DB), gy = Y(1.96, DB);
    if (!on) { k.light(gx, gy, 26, 0.3); k.light(gx, gy, 9, 0.5); k.line(X(wx1 - 0.21, DB), Y(1.17, DB), X(wx1 - 0.21, DB), Y(0.97, DB), 0.6, 0.45, 'erase'); k.line(X(wx0, DB), Y(2.1, DB), X(wx1, DB), Y(2.1, DB), 0.6, 0.35, 'erase'); }
    k.oval(gx, gy, 1, 1, 0, 'set');
    const bx0 = -0.4, bx1 = 0.5, bd0 = X(bx0, DB), bd1 = X(bx1, DB), bt = Y(2.05, DB), bb = Y(0, DB);
    k.poly(front(DB, bx0 - 0.06, bx1 + 0.06, 0, 2.11), t(0.75, 1), 'set');
    if (open) {
      // propped: the night, the rain in the light from in here, the steam going out
      k.rect(bd0, bt, bd1 - bd0, bb - bt, t(1, 0.62), 'set');
      k.clip(function (c) { c.rect(bd0, bt, bd1 - bd0, bb - bt); });
      k.rain(rnd, 80, bd0, bt, bd1 - bd0, bb - bt, { tone: t(0.8, 0.5), len: 7, w: 0.6, ink: !on });
      if (on) k.rect(bd0, bb - 4, bd1 - bd0, 4, k.lin(0, bb - 4, 0, bb, [[0, 0], [1, 0.55]]), 'erase');
      k.done();
      // the door swung out into the alley, and the milk crate holding it
      k.poly([[bd1, bt], [bd1 + 0.16 * S(DB), bt - 1.2], [bd1 + 0.16 * S(DB), bb + 1], [bd1, bb]], t(0.65, 0.97), 'set');
      const cx = X(0.25, DB - 0.1), cy = Y(0, DB - 0.1), cs = S(DB - 0.1);
      k.rect(cx - 0.21 * cs, cy - 0.28 * cs, 0.42 * cs, 0.28 * cs, t(0.3, 0.8), 'set');
      rd.rect(cx - 0.21 * cs, cy - 0.28 * cs, 0.42 * cs, 0.28 * cs, t(1, 0.45));
      for (let g = 1; g < 5; g++) k.line(cx - 0.21 * cs + g * 0.084 * cs, cy - 0.25 * cs, cx - 0.21 * cs + g * 0.084 * cs, cy - 0.04 * cs, 0.6, t(0.9, 1));
      k.line(cx - 0.21 * cs, cy - 0.27 * cs, cx + 0.21 * cs, cy - 0.27 * cs, 0.6, t(1, 1));
      if (on) {
        for (let i = 0; i < 6; i++) k.light(bd0 + (bd1 - bd0) * (0.1 + rnd() * 0.8), bt + 3 + rnd() * 12, 5 + rnd() * 5, 0.5, 3.5);
      } else {
        // the alley's light, what there is of it, on the floor
        k.poly([[bd0, bb], [bd1, bb], [X(0.9, 3.8), Y(0, 3.8)], [X(-0.6, 3.8), Y(0, 3.8)]], k.lin(0, bb, 0, Y(0, 3.8), [[0, 0.3], [1, 0]]), 'erase');
        k.line(bd0, bt, bd0, bb, 0.6, 0.5, 'erase');
      }
    } else {
      k.rect(bd0, bt, bd1 - bd0, bb - bt, t(0.5, 0.96), 'set');
      k.rect(bd0 + 1, bt + (bb - bt) * 0.48, bd1 - bd0 - 2, 1.4, t(0.9, 0.9), 'set');
      if (on) k.line(bd0 + 1, bt + (bb - bt) * 0.48, bd1 - 1, bt + (bb - bt) * 0.48, 0.5, 0.8, 'erase');
    }

    // the right wall: the office door open on the dark, the shelf of dry goods, and near the door
    // the hand sink and its sign
    k.poly(quad(XR - 0.01, 1.6, 2.1, 3.2, 4.8), t(0.1, 0.92), 'set');
    for (const y of [1.6, 2.1]) k.line(X(XR, 3.2), Y(y, 3.2), X(XR, 4.8), Y(y, 4.8), 1.2, t(1, 0.97));
    for (let i = 0; i < 9; i++) {
      const d = 3.25 + i * 0.17, h = 0.18 + rnd() * 0.22, w = 0.12;
      k.poly(quad(XR - 0.02, 1.62, 1.62 + h, d, d + w), t(0.35 + rnd() * 0.5, 0.95), 'set');
      k.poly(quad(XR - 0.02, 2.12, 2.12 + h * 0.8, d, d + w), t(0.35 + rnd() * 0.5, 0.95), 'set');
    }
    k.poly(quad(XR, 0, 2.05, 2.1, 2.9), 1, 'set');
    k.poly(quad(XR, 1.45, 1.75, 1.98, 2.06), t(0.05, 0.85), 'set');
    box(XR - 0.42, XR, 1.1, 1.5, 0.76, 0.88, t(0.35, 0.95), t(0.25, 0.92), t(0.4, 0.95));
    k.stroke('M' + X(XR - 0.08, 1.3) + ' ' + Y(0.88, 1.3) + ' q ' + (-0.05 * S(1.3)) + ' ' + (-0.14 * S(1.3)) + ' ' + (-0.14 * S(1.3)) + ' ' + (-0.1 * S(1.3)), Math.max(0.8, 0.02 * S(1.3)), t(0.9, 1));
    onWall(j, cam, XR, 1.5, 1.62, function (kk) {
      kk.rect(0, 0, 30, 32, t(0.85, 0.97), 'set');
      kk.rect(3, 26, 24, 3, t(0.2, 0.9), 'set');
      kk.line(1, 1, 1, 31, 0.8, t(0.5, 0.9), 'erase');
    });
    onWall(j, cam, XR, 1.52, 1.95, function (kk) {
      kk.rect(0, 0, 32, 16, t(0.02, 0.9), 'set');
      kk.text('EMPLOYEES', 16, 6.2, 5.2, t(0.95, 0.96), { weight: 700, max: 29 });
      kk.text('MUST WASH HANDS', 16, 12.8, 4.6, t(0.95, 0.96), { weight: 600, max: 29 });
    });

    // the prep table, steel, down the middle: the board, the wings in a tub, the bleach bottle
    const TX0 = -1.25, TX1 = -0.55, TD0 = 2.8, TD1 = 4.4, TY = 0.92;
    for (const lg of [[TX0 + 0.04, TD0 + 0.04], [TX1 - 0.04, TD0 + 0.04], [TX0 + 0.04, TD1 - 0.04], [TX1 - 0.04, TD1 - 0.04]]) k.line(X(lg[0], lg[1]), Y(0, lg[1]), X(lg[0], lg[1]), Y(TY, lg[1]), Math.max(0.8, 0.035 * S(lg[1])), t(0.85, 1));
    k.poly(flat(0.22, TX0, TX1, TD0, TD1), t(0.75, 0.97), 'set');
    box(TX0 + 0.1, TX0 + 0.4, TD0 + 0.2, TD0 + 0.6, 0.23, 0.4, t(0.9, 0.97), t(0.25, 0.9), t(0.4, 0.95));
    box(TX0 + 0.1, TX0 + 0.4, TD0 + 0.8, TD0 + 1.2, 0.23, 0.36, t(0.9, 0.97), t(0.4, 0.92), t(0.55, 0.95));
    box(TX0, TX1, TD0, TD1, TY - 0.04, TY, t(k.lin(0, Y(TY, TD1), 0, Y(TY, TD0), [[0, 0.35], [0.45, 0.04], [0.7, 0.2], [1, 0.1]]), 0.94), t(0.75, 0.97), t(0.5, 0.96));
    k.line(X(TX0, TD0), Y(TY, TD0), X(TX1, TD0), Y(TY, TD0), 0.9, t(0.9, 0.3), 'erase');
    if (on) {
      k.poly(flat(TY + 0.005, TX0 + 0.08, TX0 + 0.45, TD0 + 0.15, TD0 + 0.6), 0.06, 'set');
      k.line(X(TX0 + 0.12, TD0 + 0.42), Y(TY + 0.01, TD0 + 0.42), X(TX0 + 0.42, TD0 + 0.3), Y(TY + 0.01, TD0 + 0.3), 1.3, 0.95);
      box(TX0 + 0.1, TX1 - 0.1, TD0 + 0.85, TD0 + 1.25, TY, TY + 0.14, 0.85, 0.3, 0.45);
      for (let i = 0; i < 7; i++) k.oval(X(TX0 + 0.16 + rnd() * 0.3, TD0 + 0.95 + rnd() * 0.2), Y(TY + 0.14, TD0 + 1.05), 1.5, 1, 0.55, 'set');
      const sx = X(TX1 - 0.12, TD0 + 0.3), sy = Y(TY, TD0 + 0.3), ss = S(TD0 + 0.3);
      k.rect(sx - 0.035 * ss, sy - 0.22 * ss, 0.07 * ss, 0.22 * ss, 0.12, 'set');
      k.rect(sx - 0.02 * ss, sy - 0.29 * ss, 0.05 * ss, 0.07 * ss, 0.95, 'set');
      k.line(sx + 0.03 * ss, sy - 0.27 * ss, sx + 0.05 * ss, sy - 0.25 * ss, 0.8, 0.95);
      k.rect(sx - 0.03 * ss, sy - 0.15 * ss, 0.06 * ss, 0.06 * ss, 0.6, 'set');
    }

    // the line down the left under the hood: the pass, the flat-top, the fryer, the burners
    const LX = XL + 0.8, LY = 0.92, P0 = 1.8, P1 = 2.5, G1 = 3.2, F1 = 3.9, E1 = 4.9;
    k.poly(quad(XL, 0.92, 2.0, P0 - 0.3, E1), t(0.5, 0.97), 'set');
    if (on) for (let D = P0; D < E1; D += 0.12) k.line(X(XL, D), Y(0.95, D), X(XL, D), Y(1.95, D), 0.4, 0.15 + rnd() * 0.2);
    // the counter fronts, steel, with the room in them
    k.poly(quad(LX, 0, LY, P0 - 0.3, E1), t(k.lin(X(LX, P0), 0, X(LX, E1), 0, [[0, 0.6], [1, 0.7]]), 0.98), 'set');
    if (on) for (let D = P0 - 0.25; D < E1; D += 0.06 + rnd() * 0.12) k.line(X(LX, D), Y(LY - 0.06, D), X(LX, D), Y(0.16, D), Math.max(0.35, 0.012 * S(D) * rnd()), 0.25 + rnd() * 0.5, 'erase');
    for (const D of [P1, G1, F1]) k.line(X(LX, D), Y(LY - 0.05, D), X(LX, D), Y(0.12, D), Math.max(0.5, 0.02 * S(D)), 1);
    k.poly(quad(LX, 0, 0.14, P0 - 0.3, E1), 1, 'set');
    for (const D of [2.8, 3.0, 3.55, 4.2, 4.5]) k.oval(X(LX + 0.01, D), Y(0.8, D), 0.03 * S(D), 0.03 * S(D), 1, 'set');
    k.line(X(LX, P0 - 0.3), Y(LY, P0 - 0.3), X(LX, E1), Y(LY, E1), 1.2, t(0.95, 0.4), 'erase');
    // rubber mats on the floor in front of it
    k.poly(flat(0.005, LX + 0.05, LX + 0.75, P0, E1), 1, 'set');
    if (on) for (let D = P0 + 0.1; D < E1; D += 0.12) for (let x = LX + 0.12; x < LX + 0.72; x += 0.12) k.oval(X(x, D), Y(0.005, D), 0.02 * S(D), 0.008 * S(D), 0.5, 'erase');
    // the pass: a steel shelf under the heat lamps, the fries going soft on it
    k.poly(flat(LY, XL, LX, P0, P1), t(0.12, 0.96), 'set');
    k.poly(flat(1.42, XL, LX - 0.08, P0, P1), t(0.45, 0.98), 'set');
    k.line(X(LX - 0.08, P0), Y(1.42, P0), X(LX - 0.08, P1), Y(1.42, P1), 1.4, 1);
    { const D = 2.1, fx = X(LX - 0.3, D), fy = Y(1.43, D), s = S(D);
      k.poly([[fx - 0.12 * s, fy - 0.07 * s], [fx + 0.12 * s, fy - 0.07 * s], [fx + 0.1 * s, fy], [fx - 0.1 * s, fy]], t(0.08, 0.85), 'set');
      rd.poly([[fx - 0.12 * s, fy - 0.035 * s], [fx + 0.12 * s, fy - 0.035 * s], [fx + 0.1 * s, fy], [fx - 0.1 * s, fy]], t(0.9, 0.3));
      for (let i = 0; i < 16; i++) { const a = fx - 0.09 * s + rnd() * 0.18 * s; k.line(a, fy - 0.07 * s, a + (rnd() - 0.5) * 0.06 * s, fy - (0.1 + rnd() * 0.06) * s, Math.max(0.6, 0.014 * s), t(0.4, 0.9)); }
      // the tickets on the rail, the bell
      k.line(X(XL, P0 + 0.05), Y(1.98, P0 + 0.05), X(XL, P1), Y(1.98, P1), 1.2, 1);
      for (const tk of [P0 + 0.1, P0 + 0.28, P0 + 0.5]) k.poly(quad(XL + 0.01, 1.76, 1.97, tk, tk + 0.1), t(0.03, 0.85), 'set');
      const bxp = X(LX - 0.2, P1 - 0.1), byp = Y(1.43, P1 - 0.1), sb = S(P1 - 0.1);
      k.path('M' + (bxp - 0.045 * sb) + ' ' + byp + ' Q' + (bxp - 0.045 * sb) + ' ' + (byp - 0.06 * sb) + ' ' + bxp + ' ' + (byp - 0.06 * sb) + ' Q' + (bxp + 0.045 * sb) + ' ' + (byp - 0.06 * sb) + ' ' + (bxp + 0.045 * sb) + ' ' + byp + ' Z', 1, 'set');
      if (on) k.line(bxp - 0.025 * sb, byp - 0.04 * sb, bxp - 0.01 * sb, byp - 0.052 * sb, 0.7, 0.85, 'erase');
      // the heat lamps over it, red, or dead
      for (const hd of [P0 + 0.2, P1 - 0.2]) {
        const hx = X(LX - 0.38, hd), hy = Y(1.88, hd), hs = S(hd);
        k.line(hx, Y(CH, hd), hx, hy - 0.08 * hs, Math.max(0.6, 0.012 * hs), 1);
        k.path('M' + (hx - 0.1 * hs) + ' ' + hy + ' L' + (hx - 0.05 * hs) + ' ' + (hy - 0.1 * hs) + ' L' + (hx + 0.05 * hs) + ' ' + (hy - 0.1 * hs) + ' L' + (hx + 0.1 * hs) + ' ' + hy + ' Z', 1, 'set');
        if (on) {
          rd.glow(hx, hy + 0.25 * hs, 0.5 * hs, 0.6, 0.34 * hs);
          rd.oval(hx, hy + 0.012 * hs, 0.085 * hs, 0.028 * hs, 1);
          k.oval(hx, hy + 0.012 * hs, 0.085 * hs, 0.028 * hs, 0, 'set');
          k.light(hx, hy + 0.3 * hs, 0.35 * hs, 0.25, 0.25 * hs);
        } else k.oval(hx, hy + 0.012 * hs, 0.085 * hs, 0.028 * hs, 0.85, 'set');
      }
    }
    // the flat-top: black steel with the shine on it, a scraper on it
    k.poly(flat(LY, XL, LX, P1 + 0.05, G1), 1, 'set');
    if (on) {
      k.poly(flat(LY + 0.002, XL + 0.2, LX - 0.08, P1 + 0.15, G1 - 0.1), k.lin(X(XL, 2.9), 0, X(LX, 2.9), 0, [[0, 0], [0.75, 0.4], [1, 0]]), 'erase');
      k.line(X(LX - 0.32, G1 - 0.2), Y(LY + 0.01, G1 - 0.2), X(LX - 0.12, G1 - 0.35), Y(LY + 0.01, G1 - 0.35), 1.4, 0.35, 'set');
    }
    // the fryer: the oil in its wells, a basket hung up to drain
    k.poly(flat(LY, XL, LX, G1 + 0.05, F1), 0.95, 'set');
    k.poly(flat(LY - 0.01, XL + 0.12, LX - 0.1, G1 + 0.12, F1 - 0.08), t(0.82, 1), 'set');
    if (on) k.line(X(XL + 0.2, 3.7), Y(LY, 3.7), X(LX - 0.2, 3.6), Y(LY, 3.6), 0.9, 0.55, 'erase');
    { const hd = F1 - 0.15, hx = X(XL + 0.25, hd), hy = Y(1.22, hd), s = S(hd);
      k.rect(hx, hy, 0.3 * s, 0.14 * s, t(0.55, 1), 'set');
      for (let g = 1; g < 6; g++) k.line(hx + g * 0.05 * s, hy, hx + g * 0.05 * s, hy + 0.14 * s, 0.4, 1);
    }
    // the burners, a stockpot on one
    k.poly(flat(LY, XL, LX, F1 + 0.05, E1), 0.9, 'set');
    box(XL + 0.2, XL + 0.55, F1 + 0.3, F1 + 0.65, LY, LY + 0.35, t(0.95, 1), t(0.35, 0.97), t(0.5, 0.98));
    // the hood over the line, greasy steel, its filters, the light under it
    k.poly([[X(XL, P0 - 0.3), Y(CH, P0 - 0.3)], [X(XL + 1.05, P0 - 0.3), Y(2.02, P0 - 0.3)], [X(XL + 1.05, E1 + 0.05), Y(2.02, E1 + 0.05)], [X(XL, E1 + 0.05), Y(CH, E1 + 0.05)]], t(k.lin(0, Y(CH, 2.5), 0, Y(2.02, 2.5), [[0, 0.6], [1, 0.35]]), 1), 'set');
    k.poly([[X(XL + 1.05, P0 - 0.3), Y(2.02, P0 - 0.3)], [X(XL + 1.05, E1 + 0.05), Y(2.02, E1 + 0.05)], [X(XL + 1.05, E1 + 0.05), Y(1.88, E1 + 0.05)], [X(XL + 1.05, P0 - 0.3), Y(1.88, P0 - 0.3)]], t(0.8, 1), 'set');
    if (on) {
      k.line(X(XL + 1.05, P0 - 0.3), Y(1.88, P0 - 0.3), X(XL + 1.05, E1 + 0.05), Y(1.88, E1 + 0.05), 1.1, 0.95, 'erase');
      k.line(X(XL + 1.05, P0 - 0.3), Y(2.02, P0 - 0.3), X(XL + 1.05, E1 + 0.05), Y(2.02, E1 + 0.05), 0.8, 0.7, 'erase');
      for (let D = P0; D < E1; D += 0.28) k.line(X(XL + 0.15, D), Y(2.55, D), X(XL + 0.95, D), Y(2.06, D), Math.max(0.4, 0.012 * S(D)), 0.7);
      // grease run down the front
      for (let i = 0; i < 10; i++) { const D = P0 + rnd() * (E1 - P0); k.line(X(XL + 1.05, D), Y(1.88, D), X(XL + 1.05, D), Y(1.88 - 0.02 - rnd() * 0.05, D), 0.5, 0.8); }
    }

    // the cook at the fryer, his back to you, shaking a basket of wings; the steam off it
    if (on) {
      // off the fryer and up into the hood
      for (let i = 0; i < 12; i++) { const D = G1 + 0.1 + rnd() * (F1 - G1), Yv = 1.0 + i * 0.1 + rnd() * 0.1; k.light(X(XL + 0.35 + rnd() * 0.5, D), Y(Yv, D), (0.12 + rnd() * 0.12) * S(D), 0.4, (0.08 + rnd() * 0.06) * S(D)); }
      person(k, cam, -1.7, 3.55, { pose: 'backwork', build: 'medium', hair: 'short', top: 'tshirt', tone: 0.28, legsTone: 0.94, wet: 0.9, hairTone: 0.95, from: 'back', light: 1, rim: 0.25, lit: 0.1, tall: 1.8 });
    }

    // the tubes in the ceiling
    for (const tb of [[1.4, 2.6, -1.6], [3.9, 5.1, -1.6], [1.4, 2.6, -0.3], [3.9, 5.1, -0.3]]) {
      k.poly(flat(CH, tb[2] - 0.25, tb[2] + 0.25, tb[0], tb[1]), t(0.95, 1), 'set');
      if (on) {
        const dm = (tb[0] + tb[1]) / 2;
        k.light(X(tb[2], dm), Y(CH, dm), 0.9 * S(dm), 0.3, 0.3 * S(dm));
        k.poly(flat(CH, tb[2] - 0.2, tb[2] + 0.2, tb[0] + 0.05, tb[1] - 0.05), 0, 'set');
      }
    }
    vignette(k, t(0.2, 0.4));
    edge(k);
  };

  // The keg room, from the foot of the stairs: the stone foundation sweating down the left, the
  // kegs on pallets in two rows down the right with the lines going up through the floor above to
  // the taps, the compressor, the joists low overhead. His flashlight on the bottom of the wall:
  // droppings like spilled rice, the grease line at the height of a rat's back running to the hole
  // where the wall meets the dirt. Past the kegs the concrete gives out and the foundation runs on
  // into the dark over the stumps of old pilings, and there are eyes in it, more as they double.
  PLACES.keg = function (j, look, rnd) {
    const k = j.k, rd = j.r;
    const cam = camera(292, 86, 240, 1.62);
    const X = cam.x, Y = cam.y, S = cam.s;
    const XL = -1.3, XR = 2.3, CH = 2.15, DN = 0.5, DC = 6.6, DE = 12;
    const eyes = clamp(look.eyes || 1, 1, 6);
    const quad = function (Xw, y0, y1, d0, d1) { return [[X(Xw, d0), Y(y1, d0)], [X(Xw, d1), Y(y1, d1)], [X(Xw, d1), Y(y0, d1)], [X(Xw, d0), Y(y0, d0)]]; };
    const flat = function (Yh, x0, x1, d0, d1) { return [[X(x0, d0), Y(Yh, d0)], [X(x1, d0), Y(Yh, d0)], [X(x1, d1), Y(Yh, d1)], [X(x0, d1), Y(Yh, d1)]]; };
    // the light: the bulb at the foot of the stairs behind him, dying off down the room
    const BD = 1.9, BX = 0.25, BY = 1.86;
    const L = function (D) { return clamp(0.85 * Math.exp(-Math.pow((D - BD) / 2.1, 2)), 0, 1); };
    const byDepth = function (plane, at, d0, d1, fn) { return depthTone(k, cam, plane, at, d0, d1, fn); };

    k.rect(0, 0, W, H, 1, 'set');
    // the joists and the subfloor overhead
    k.poly(flat(CH, XL, XR, DN, DE), byDepth('y', CH, DN, DE, function (D) { return clamp(0.98 - 0.4 * L(D), 0.55, 1); }), 'set');
    for (let D = 0.9; D < DE; D += 0.42) {
      k.poly([[X(XL, D), Y(CH, D)], [X(XR, D), Y(CH, D)], [X(XR, D), Y(CH - 0.2, D)], [X(XL, D), Y(CH - 0.2, D)]], clamp(0.99 - 0.25 * L(D), 0.7, 1), 'set');
      k.line(X(XL, D), Y(CH - 0.2, D), X(XR, D), Y(CH - 0.2, D), Math.max(0.4, 0.008 * S(D)), 0.5 * L(D), 'erase');
    }
    // the stone foundation down the left, sweating: dark, the bulb's light on the near part, his
    // flashlight's pool at the bottom of it; then the stones, which show where the light is
    const fD = 3.9, fx = X(XL + 0.05, fD), fy = Y(0.2, fD), fs = S(fD);
    const pool = function (D, Yv) { return Math.exp(-Math.pow((D - fD) / 0.8, 2) - Math.pow((Yv - 0.28) / 0.45, 2)); };
    k.poly(quad(XL, 0, CH, DN, DE), 0.95, 'set');
    onWall(j, cam, XL, fD, 0.3, function (kk) { kk.light(0, 0, 80, 0.75, 46); });
    for (let y0 = 0; y0 < CH;) {
      const rh = 0.1 + rnd() * 0.17;
      let D = 1.0 + rnd() * 0.2;
      while (D < DC + 2) {
        const len = 0.1 + rnd() * 0.36, cxD = D + len / 2, cyY = y0 + rh / 2, s = S(cxD);
        const bl = L(cxD), pl = pool(cxD, cyY);
        if (bl + pl > 0.04) {
          // a rounded stone: its face lighter where there's light on it, the light along its top,
          // and in his light the dark joint round it
          const n = 7, pts = [];
          for (let a = 0; a < n; a++) {
            const ang = a / n * Math.PI * 2 + (rnd() - 0.5) * 0.5, rr = 0.9 + rnd() * 0.12;
            const dd = cxD + Math.cos(ang) * len * 0.5 * rr;
            pts.push([X(XL + 0.001, dd), Y(cyY + Math.sin(ang) * rh * 0.5 * rr, dd)]);
          }
          let d = 'M' + ((pts[0][0] + pts[1][0]) / 2) + ' ' + ((pts[0][1] + pts[1][1]) / 2);
          for (let a = 1; a <= n; a++) { const p0 = pts[a % n], p1 = pts[(a + 1) % n]; d += ' Q' + p0[0] + ' ' + p0[1] + ' ' + ((p0[0] + p1[0]) / 2) + ' ' + ((p0[1] + p1[1]) / 2); }
          k.path(d + ' Z', Math.min(0.9, 0.3 * bl + 0.4 * pl) * (0.6 + rnd() * 0.5), 'erase');
          const l0 = [X(XL, cxD - len * 0.36), Y(cyY + rh * 0.18, cxD - len * 0.36)], l1 = [X(XL, cxD + len * 0.36), Y(cyY + rh * 0.18, cxD + len * 0.36)], c = [X(XL, cxD), Y(cyY + rh * 0.62, cxD)];
          k.stroke('M' + l0[0] + ' ' + l0[1] + ' Q' + c[0] + ' ' + c[1] + ' ' + l1[0] + ' ' + l1[1], Math.max(0.4, 0.012 * s), Math.min(1, 0.25 * bl + 0.6 * pl), 'erase');
          if (pl > 0.12) k.stroke(d + ' Z', Math.max(0.5, 0.016 * s), 0.7 * pl);
        }
        D += len;
      }
      y0 += rh;
    }
    // wet streaks down the stone, where there's light to see them
    for (let i = 0; i < 30; i++) { const D = 1.1 + rnd() * 4.5, y = 0.2 + rnd() * 1.8, lit = Math.min(1, L(D) * 0.7 + pool(D, y)); if (lit > 0.15) k.line(X(XL, D), Y(y, D), X(XL, D), Y(y - 0.06 - rnd() * 0.18, D), Math.max(0.4, 0.007 * S(D)), 0.5 * lit, 'erase'); }
    // the far wall of kegs' side, dark; the floor: concrete, then dirt
    k.poly(quad(XR, 0, CH, DN, DE), 0.98, 'set');
    k.poly(flat(0, XL, XR, DN, DC), byDepth('y', 0, DN, DC, function (D) { return clamp(0.95 - 0.5 * L(D), 0.45, 1); }), 'set');
    k.poly(flat(0, XL, XR, DC, DE), 1, 'set');
    k.line(X(XL, DC), Y(0, DC), X(XR, DC), Y(0, DC), 0.7, 0.35, 'erase');
    // the floor drain
    { const D = 3.2, x = X(-0.3, D), y = Y(0, D), s = S(D);
      k.oval(x, y, 0.13 * s, 0.035 * s, 1, 'set');
      for (let g = -2; g <= 2; g++) k.line(x + g * 0.045 * s, y - 0.03 * s, x + g * 0.045 * s, y + 0.03 * s, 0.5, 0.5, 'erase'); }

    // the kegs, two rows down the right on pallets, the lines going up from them into the dark
    const kegAt = function (xc, D, lit) {
      const s = S(D), x = X(xc, D), y = Y(0.14, D), r = 0.2 * s, h = 0.6 * s, ry = r * Math.max(0.12, (cam.eye - 0.74) / D * 0.95);
      const tone = clamp(0.96 - 0.3 * lit, 0.55, 1);
      // the body: dark steel, the bulb's light down the front of it
      k.rect(x - r, y - h, 2 * r, h, k.lin(x - r, 0, x + r, 0, [[0, 1], [0.25, tone], [0.42, clamp(tone - 0.75 * lit, 0.05, 1)], [0.5, tone], [0.85, 1]]), 'set');
      k.oval(x, y, r, ry, 1, 'set');
      for (const f of [0.22, 0.78]) {
        k.poly([[x - r, y - h * f - ry * 0.2], [x + r, y - h * f - ry * 0.2], [x + r, y - h * f + ry * 0.35], [x - r, y - h * f + ry * 0.35]], 1, 'set');
        k.line(x - r * 0.6, y - h * f - ry * 0.15, x + r * 0.3, y - h * f - ry * 0.15, Math.max(0.4, 0.01 * s), 0.8 * lit, 'erase');
      }
      // the top: the chime ring, the handle holes, the flat, the coupler on the spear
      k.oval(x, y - h, r, ry, 0.97, 'set');
      k.stroke(ell(x, y - h, r * 0.97, ry * 0.97, true), Math.max(0.5, 0.02 * s), 0.9 * lit + 0.1, 'erase');
      k.oval(x, y - h + ry * 0.05, r * 0.8, ry * 0.78, clamp(0.85 - 0.45 * lit, 0.35, 0.9), 'set');
      for (const hx of [-0.55, 0.55]) k.oval(x + hx * r, y - h - ry * 0.35, r * 0.18, ry * 0.12, 1, 'set');
      k.rect(x - 0.035 * s, y - h - 0.09 * s, 0.07 * s, 0.09 * s, 1, 'set');
      k.line(x - 0.06 * s, y - h - 0.075 * s, x + 0.06 * s, y - h - 0.075 * s, Math.max(0.6, 0.02 * s), 1);
      k.line(x + 0.03 * s, y - h - 0.08 * s, x + 0.1 * s, y - h - 0.12 * s, Math.max(0.5, 0.016 * s), 1);
      const cx = x + 0.1 * s, cy = y - h - 0.12 * s, top = Y(CH - 0.1, D);
      const path = 'M' + cx + ' ' + cy + ' C' + (cx + 0.12 * s) + ' ' + (cy - 0.25 * s) + ' ' + (x + 0.02 * s) + ' ' + (top + 0.35 * s) + ' ' + (x + 0.06 * s) + ' ' + top;
      k.stroke(path, Math.max(0.5, 0.013 * s), 0.95);
      if (lit > 0.3) k.stroke(path, Math.max(0.3, 0.004 * s), 0.35 * lit, 'erase');
    };
    const pallet = function (x0, x1, d0, d1) {
      k.poly(flat(0.14, x0, x1, d0, d1), 0.95, 'set');
      k.poly([[X(x0, d0), Y(0.14, d0)], [X(x1, d0), Y(0.14, d0)], [X(x1, d0), Y(0, d0)], [X(x0, d0), Y(0, d0)]], 1, 'set');
      for (const f of [0.15, 0.5, 0.85]) { const xx = x0 + (x1 - x0) * f; k.line(X(xx, d0), Y(0.12, d0), X(xx, d0), Y(0.02, d0), Math.max(0.5, 0.03 * S(d0)), 0.4 * L(d0), 'erase'); }
      k.line(X(x0, d0), Y(0.14, d0), X(x1, d0), Y(0.14, d0), 0.7, 0.6 * L(d0), 'erase');
    };
    const ROWS = [[1.25, 1.95], [0.35, 1.05]];
    for (const rw of ROWS) {
      for (let D = 6.2; D >= 2.3; D -= 1.4) {
        pallet(rw[0], rw[1], D - 1.25, D);
      }
    }
    for (const rw of ROWS) {
      for (let D = 6.1; D >= 2.3; D -= 0.46) {
        for (const xc of [rw[0] + 0.18, rw[1] - 0.18]) if (rnd() < 0.92) kegAt(xc, D, L(D));
      }
    }
    // cardboard cases along the right wall, every one gnawed through at the bottom
    for (const cs of [[3.0, 3], [3.7, 2], [4.5, 4], [5.3, 2]]) {
      const D = cs[0], x0 = XR - 0.42, lit = L(D);
      for (let i = 0; i < cs[1]; i++) {
        const y0 = i * 0.3, tone = clamp(0.9 - 0.45 * lit - rnd() * 0.08, 0.3, 0.95);
        k.poly([[X(x0, D), Y(y0 + 0.29, D)], [X(XR, D), Y(y0 + 0.29, D)], [X(XR, D), Y(y0, D)], [X(x0, D), Y(y0, D)]], tone, 'set');
        k.poly(quad(x0, y0, y0 + 0.29, D, D + 0.4), clamp(tone + 0.06, 0, 0.97), 'set');
        k.line(X(x0, D), Y(y0 + 0.29, D), X(XR, D), Y(y0 + 0.29, D), 0.6, 0.6 * lit, 'erase');
        if (i === 0) { let d = 'M' + X(x0, D) + ' ' + Y(0, D); for (let g = 0; g <= 8; g++) d += ' L' + X(x0 + (XR - x0) * g / 8, D) + ' ' + Y(0.02 + rnd() * 0.07, D); d += ' L' + X(XR, D) + ' ' + Y(0, D) + ' Z'; k.path(d, 1, 'set'); }
      }
    }
    // the compressor on the wall at the back, its fan
    { const D = DC - 0.3, x = X(XR - 0.05, D), y = Y(0.95, D), s = S(D);
      k.poly(quad(XR - 0.5, 0.95, 1.5, D - 0.5, D), 0.85, 'set');
      k.oval(X(XR - 0.5, D - 0.25), Y(1.22, D - 0.25), 0.17 * s, 0.2 * s, 1, 'set');
      for (let a = 0; a < 5; a++) k.line(X(XR - 0.5, D - 0.25), Y(1.22, D - 0.25), X(XR - 0.5, D - 0.25) + Math.cos(a * 1.26) * 0.14 * s, Y(1.22, D - 0.25) + Math.sin(a * 1.26) * 0.16 * s, 0.6, 0.3, 'erase'); }

    // the dark past the kegs: the foundation running on, the stumps of the old pilings
    for (let i = 0; i < 7; i++) {
      const D = DC + 0.8 + i * 0.75 + rnd() * 0.4, xc = -0.9 + rnd() * 2.6, s = S(D), x = X(xc, D), y = Y(0, D);
      k.path('M' + (x - 0.14 * s) + ' ' + y + ' L' + (x - 0.12 * s) + ' ' + (y - (0.3 + rnd() * 0.5) * s) + ' L' + (x + 0.1 * s) + ' ' + (y - (0.25 + rnd() * 0.4) * s) + ' L' + (x + 0.14 * s) + ' ' + y + ' Z', 1, 'set');
      k.line(x - 0.12 * s, y - 0.1 * s, x - 0.12 * s, y - 0.3 * s, 0.4, 0.18, 'erase');
    }

    // his flashlight: a pool on the bottom of the wall and the floor in front of it
    k.light(fx + 0.45 * fs, Y(0, fD + 0.3) + 0.02 * fs, 0.95 * fs, 0.85, 0.2 * fs);
    // what it shows: the grease line at a rat's height, from the drain to the hole; the droppings
    k.clip(function (c) { c.ellipse(fx, fy, 1.6 * fs, 0.5 * fs, -0.25, 0, Math.PI * 2); });
    k.poly([[X(XL, 2.9), Y(0.11, 2.9)], [X(XL, 5.3), Y(0.11, 5.3)], [X(XL, 5.3), Y(0.06, 5.3)], [X(XL, 2.9), Y(0.06, 2.9)]], 0.72);
    k.done();
    k.stroke('M' + X(-0.3, 3.2) + ' ' + Y(0, 3.2) + ' Q' + X(XL + 0.3, 3.4) + ' ' + Y(0, 3.4) + ' ' + X(XL + 0.02, 3.6) + ' ' + Y(0, 3.6), Math.max(1, 0.04 * fs), 0.35);
    { const hx = X(XL, 5.0), hy = Y(0, 5.0), hs = S(5.0);
      k.path('M' + (hx - 0.03 * hs) + ' ' + hy + ' Q' + (hx - 0.02 * hs) + ' ' + (hy - 0.16 * hs) + ' ' + (hx - 0.1 * hs) + ' ' + (hy - 0.15 * hs) + ' Q' + (hx - 0.2 * hs) + ' ' + (hy - 0.12 * hs) + ' ' + (hx - 0.19 * hs) + ' ' + (hy + 0.01 * hs) + ' Z', 1, 'set'); }
    for (let i = 0; i < 160; i++) {
      const D = 2.4 + rnd() * 3, xx = XL + 0.03 + Math.pow(rnd(), 1.8) * 0.9, s = S(D);
      k.oval(X(xx, D), Y(0, D), Math.max(0.35, 0.012 * s), Math.max(0.25, 0.005 * s), 0.9, 'set');
    }
    // the bare bulb on its cord
    { const x = X(BX, BD), y = Y(BY, BD), s = S(BD);
      k.line(x, Y(CH - 0.2, BD), x, y - 0.05 * s, Math.max(0.5, 0.008 * s), 1);
      k.rect(x - 0.02 * s, y - 0.07 * s, 0.04 * s, 0.04 * s, 1, 'set');
      k.light(x, y + 0.02 * s, 1.5 * s, 0.3);
      k.light(x, y + 0.02 * s, 0.6 * s, 0.6);
      k.oval(x, y + 0.02 * s, 0.035 * s, 0.045 * s, 0, 'set'); }
    // the beam through the dust, from his hand to the wall
    k.poly([[W * 0.82, H + 2], [W * 1.02, H - 30], [fx + 0.9 * fs, fy - 0.12 * fs], [fx - 0.1 * fs, fy + 0.05 * fs]], k.lin(W, H, fx, fy, [[0, 0.16], [1, 0.03]]), 'erase');

    // eyes in the dark past the kegs, more as they double
    for (let i = 0; i < eyes; i++) {
      const D = DC + 1.0 + rnd() * 4.2, xc = -1.25 + rnd() * 3.2, s = S(D), x = X(xc, D), y = Y(0.06 + (rnd() < 0.4 ? rnd() * 0.45 : 0.03), D), gap = Math.max(1.4, 0.035 * s);
      for (const e of [-gap / 2, gap / 2]) { rd.glow(x + e, y, 6, 0.6); rd.oval(x + e, y, 1.2, 0.9, 1); k.oval(x + e, y, 1.1, 0.85, 0.7, 'erase'); k.oval(x + e + 0.3, y - 0.25, 0.3, 0.3, 1, 'erase'); }
    }
    vignette(k, 0.3);
    edge(k);
  };

  // The deck, on the water side, from its near end and turned out toward the water: down the left
  // the siding and the deck door under its caged bulb (the folded coaster in the latch so it won't
  // lock, or locked), the bar's window lit red from inside; the tin awning overhead and the rain
  // coming off its edge in ropes; the rail, the gap for the steps, the coffee can of butts on the
  // rail, white plastic chairs. Past the rail, across the highway under its lamps and the seawall,
  // the strait, black, the mountains black over it and the lights of the far shore laid down the water.
  PLACES.deck = function (j, look, rnd) {
    const k = j.k, rd = j.r;
    const open = look.open !== false;
    const cam = turned(300, 90, 240, 1.65, 26 * Math.PI / 180);
    const P = cam.p, SC = cam.sc, hz = cam.hz, vu = cam.vu, vw = cam.vw;
    const WB = -1.6, WR = 1.3, WA = 1.55, AT = 2.7, AE = 2.35, U0 = -1.5, UE = 13, GY = -1.3;
    const RY = -2.6, R0 = 21.2, R1 = 29.6, SW = 30.4;          // the road, its edges, the seawall
    const slope = (AE - AT) / (WA - WB), aY = function (w) { return AT + slope * (w - WB); };
    const G = function (x, m, s2) { return Math.exp(-(x - m) * (x - m) / s2); };
    // the caged bulb over the door, and how much of it gets to a place
    const BU = 5.05, BW = WB + 0.16, BY = 2.3, S2 = 7.5;
    const bulb = function (u, w, Y) { return G(u, BU, S2) * G(w, BW, S2) * G(Y, BY, S2); };
    // ink along u on the flat at height Yp (the lines across meet at vw), across it (they meet at vu)
    const onU = function (Yp, u0, u1, fn) { return function (c) { return fan(c, vw, hz, u0, u1, function (u) { return P(u, Math.max(WR, (0.6 - u * cam.c) / cam.s), Yp); }, fn); }; };
    const onW = function (Yp, w0, w1, fn, uAt) { return function (c) { return fan(c, vu, hz, w0, w1, function (w) { return P(uAt || 40, w, typeof Yp === 'function' ? Yp(w) : Yp); }, fn); }; };
    const poly = function (pen, pts, tone, mode) { const q = shape3(cam, pts); if (q.length > 2) pen.poly(q, tone, mode); return q; };
    const line3 = function (pen, a, b, wd, tone, mode) {
      // cut at the eye, or a line with an end behind you comes back round in front
      const da = cam.D(a[0], a[1]) - 0.08, db = cam.D(b[0], b[1]) - 0.08;
      if (da < 0 && db < 0) return;
      const cut = function (p, q, dp, dq) { const t = dp / (dp - dq); return [p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t, p[2] + (q[2] - p[2]) * t]; };
      if (da < 0) a = cut(a, b, da, db); else if (db < 0) b = cut(b, a, db, da);
      const p = P(a[0], a[1], a[2]), q = P(b[0], b[1], b[2]); pen.line(p[0], p[1], q[0], q[1], wd, tone, mode);
    };

    // ---- out there. The sky: cloud, with the town's light under it low down
    k.rect(0, 0, W, H, 1, 'set');
    k.rect(0, 0, W, hz + 1, k.lin(0, 0, 0, hz, [[0, 0.95], [0.45, 0.9], [0.8, 0.78], [1, 0.66]]), 'set');
    for (let i = 0; i < 7; i++) { const x = 260 + rnd() * 380, y = 20 + rnd() * (hz - 40); k.light(x, y, 50 + rnd() * 60, 0.05, 2.5 + rnd() * 2); }
    // the mountains over the far shore, black on the cloud
    const ridge = [];
    for (let x = 120, y = hz - 6; x <= W + 6; x += 4 + rnd() * 5) {
      const base = 7 + 16 * Math.pow(Math.sin((x - 120) / 520 * Math.PI * 1.6 + 0.4), 2) * (x > 330 ? 1 : 0.5 + (x - 120) / 420);
      y = hz - base - (rnd() - 0.5) * 4; ridge.push([x, y]);
    }
    k.poly([[120, hz + 1]].concat(ridge, [[W + 6, hz + 1]]), 0.96, 'set');
    // the far shore's lights along the foot of them, thick toward the end of the strait, a town
    // where the ferry goes in, and a red one on a tower up the ridge
    const shore = [];
    for (let i = 0; i < 44; i++) {
      const t = Math.pow(rnd(), 1.7), x = 186 + t * 460;
      if (x > W - 2) continue;
      const y = hz - 0.6 - rnd() * (rnd() < 0.2 ? 5 : 1.4);
      shore.push([x, y, rnd()]);
    }
    for (let i = 0; i < 14; i++) shore.push([424 + rnd() * 40, hz - 0.5 - rnd() * rnd() * 6, rnd()]);
    for (const sh of shore) { k.oval(sh[0], sh[1], 0.7, 0.55, 0.9, 'erase'); if (sh[2] > 0.75) k.light(sh[0], sh[1], 4, 0.35); }
    k.light(443, hz - 2, 26, 0.16, 6);
    const TWX = 512, TWY = hz - 17;
    k.line(TWX, TWY + 1, TWX, TWY + 7, 0.5, 1);
    rd.glow(TWX, TWY, 6, 0.85); rd.oval(TWX, TWY, 0.9, 0.9, 1); k.oval(TWX, TWY, 0.8, 0.8, 0.5, 'erase');

    // the strait, black, the far lights laid down it in broken bars, the red one too
    k.rect(0, hz + 0.6, W, H - hz, 0.97, 'set');
    for (const sh of shore) {
      if (sh[2] < 0.7) continue;
      let x = sh[0];
      const len = 5 + (sh[2] - 0.7) * 40;
      for (let y = hz + 1.8; y < hz + len; y += 1.1 + rnd() * 1.6) {
        x += (rnd() - 0.5) * 0.5;
        const f = (y - hz) / len, wd = 0.4 + (y - hz) * 0.05 + rnd() * 0.5;
        if (rnd() < 0.6) k.line(x - wd, y, x + wd, y, 0.45, (0.75 - f * 0.6) * (0.5 + rnd() * 0.5), 'erase');
      }
    }
    for (let y = hz + 2; y < hz + 30; y += 1.2 + rnd() * 1.6) { const wd = 0.6 + (y - hz) * 0.05; rd.line(TWX - wd + (rnd() - 0.5), y, TWX + wd + (rnd() - 0.5), y, 0.5, 0.75 * (1 - (y - hz) / 30)); }

    // the highway along the shore, wet, its lamps on the near side leaning out over it, going away
    const LAMPS = [7, 31, 55, 79, 103, 127, 151, 175, 199];
    const lampAt = function (u) { let a = 0; for (const lu of LAMPS) a += G(u, lu, 26); return Math.min(1, a); };
    // where a line along the shore at (w, Y) crosses the plate at x
    const atX = function (w, Y, x) { let a = -60, b = 6000; const dir = P(b, w, Y)[0] > P(Math.max(a, (0.5 - w * cam.s) / cam.c), w, Y)[0] ? 1 : -1; a = Math.max(a, (0.5 - w * cam.s) / cam.c); for (let i = 0; i < 50; i++) { const m = (a + b) / 2; if ((P(m, w, Y)[0] - x) * dir < 0) a = m; else b = m; } return P((a + b) / 2, w, Y); };
    // the seawall and its rail: the face toward the road catching the lamps
    poly(k, [[-40, SW, RY], [4000, SW, RY], [4000, SW, RY + 0.75], [-40, SW, RY + 0.75]], 0.93, 'set');
    lit2(j, k, shape3(cam, [[-40, SW, RY], [4000, SW, RY], [4000, SW, RY + 0.75], [-40, SW, RY + 0.75]]), onU(RY + 0.4, -10, 260, function (u) { return 0.06 + 0.4 * lampAt(u); }), null, 1);
    for (let u = -10; u < 260; u += 0.5) { const l = lampAt(u); if (l > 0.08 && cam.D(u, SW) > 2) line3(k, [u, SW, RY + 0.75], [u + 0.5, SW, RY + 0.75], 0.7, 0.75 * l, 'erase'); }
    for (let u = 2; u < 400; u += 3.2) {
      const d = cam.D(u, SW); if (d < 1) continue;
      const lw = Math.max(0.35, 0.04 * SC(u, SW)), l = lampAt(u);
      line3(k, [u, SW, RY + 0.75], [u, SW, RY + 1.7], lw, 0.85);
      if (l > 0.3) line3(k, [u, SW - 0.03, RY + 0.8], [u, SW - 0.03, RY + 1.66], lw * 0.5, 0.5 * l, 'erase');
    }
    line3(k, [-40, SW, RY + 1.7], [4000, SW, RY + 1.7], 0.6, 0.85);
    for (let u = -10; u < 260; u += 0.5) { const l = lampAt(u); if (l > 0.15 && cam.D(u, SW) > 2) line3(k, [u, SW - 0.02, RY + 1.72], [u + 0.5, SW - 0.02, RY + 1.72], 0.45, 0.6 * l, 'erase'); }
    // the road, black and wet: the lamps' pools on it, their lights down it toward you, the line
    const road = [[-40, R0, RY], [4000, R0, RY], [4000, R1, RY], [-40, R1, RY]];
    poly(k, road, 0.95, 'set');
    lit2(j, k, shape3(cam, road), onU(RY, -10, 260, function (u) { return 0.5 * lampAt(u); }), onW(RY, R0 - 2, R1 + 2, function (w) { return G(w, 23, 30); }), 1);
    for (let u = 3; u < 300; u += 6) { if (cam.D(u, 25.4) < 2) continue; line3(k, [u, 25.4, RY], [u + 3, 25.4, RY], Math.max(0.35, 0.1 * SC(u, 25.4)), 0.3 + 0.5 * lampAt(u), 'erase'); }
    // the curb and the walk along the wall
    line3(k, [-40, R1, RY + 0.12], [4000, R1, RY + 0.12], 0.7, 0.45, 'erase');
    // the grass down to the road, black, going grey where the lamps get to it
    const yard = [[-40, WR, GY], [4000, WR, GY], [4000, R0, RY], [-40, R0, RY]];
    poly(k, yard, 0.97, 'set');
    lit2(j, k, shape3(cam, yard), onU(RY, -10, 260, lampAt), onW(function (w) { return GY + (RY - GY) * (w - WR) / (R0 - WR); }, WR, R0, function (w) { return 0.32 * G(w, R0, 18); }), 1);
    // the lamps: poles, arms out over the road, the heads, their light in the rain
    for (let li = LAMPS.length - 1; li >= 0; li--) {
      const u = LAMPS[li], s = SC(u, 21);
      if (cam.D(u, 21) < 3) continue;
      const foot = P(u, R0 - 0.3, RY), top = P(u, R0 - 0.3, 6.4), end = P(u, R0 + 1.7, 6.1), head = P(u, R0 + 1.9, 5.95);
      k.line(foot[0], foot[1], top[0], top[1], Math.max(0.5, 0.2 * s), 1);
      k.stroke('M' + top[0] + ' ' + top[1] + ' Q' + (top[0] + (end[0] - top[0]) * 0.3) + ' ' + (top[1] - 0.25 * s) + ' ' + end[0] + ' ' + end[1], Math.max(0.45, 0.12 * s), 1);
      k.oval(head[0], head[1], Math.max(1, 0.45 * s), Math.max(0.5, 0.12 * s), 1, 'set');
      k.light(head[0], head[1] + 0.2 * s, Math.max(7, 2.4 * s), 0.3);
      k.light(head[0], head[1] + 0.15 * s, Math.max(2.4, 0.9 * s), 0.9);
      k.oval(head[0], head[1] + 0.1 * s, Math.max(0.8, 0.3 * s), Math.max(0.4, 0.07 * s), 0, 'set');
      // its cone down through the rain
      k.clip(function (c) { c.moveTo(head[0] - 0.2 * s, head[1]); c.lineTo(head[0] + 0.2 * s, head[1]); c.lineTo(head[0] + 3 * s, head[1] + 8.5 * s); c.lineTo(head[0] - 3 * s, head[1] + 8.5 * s); c.closePath(); });
      k.rain(rnd, Math.round(clamp(s * 6, 4, 60)), head[0] - 3 * s, head[1], 6 * s, 8.5 * s, { tone: 0.5, len: Math.max(2, 0.5 * s), w: 0.45, slant: 0.08 });
      k.done();
      // its light down the wet road toward you
      { const yf = atX(R1, RY, head[0])[1], yn = atX(R0, RY, head[0])[1];
        for (let y = yf + 0.5; y < Math.min(H, yn); y += 0.8 + rnd() * 0.8) {
          const f = (y - yf) / Math.max(1, yn - yf), x = head[0] + (rnd() - 0.5) * 0.25 * s, wd = Math.max(0.4, 0.12 * s) * (0.5 + rnd()) * (1 - 0.5 * f);
          if (rnd() < 0.75) k.line(x - wd, y, x + wd, y, 0.5, 0.7 * (1 - 0.6 * f) * (0.5 + rnd() * 0.5), 'erase');
        } }
    }
    // a car going away up the shore, slow: its tail lights, red, and down the wet road; its own
    // lights out ahead of it along the seawall
    { const u = 44, a = P(u, 27.0, RY + 0.75), b = P(u, 28.4, RY + 0.75), s = SC(u, 27.7);
      lit2(j, k, shape3(cam, [[u + 2, R0, RY], [u + 40, R0, RY], [u + 40, SW, RY + 0.75], [u + 2, SW, RY + 0.75]]), onU(RY, u, u + 44, function (x) { return 0.55 * G(x, u + 16, 120); }), onW(RY, R0, SW + 1, function (w) { return G(w, 28.5, 12); }), 0.8);
      const bo = P(u + 0.3, 27.7, RY + 1.2), bs = 1.7 * s;
      k.rect(bo[0] - bs * 0.55, bo[1], bs * 1.1, 0.8 * s, 1, 'set');
      k.path('M' + (bo[0] - bs * 0.5) + ' ' + bo[1] + ' L' + (bo[0] - bs * 0.35) + ' ' + (bo[1] - 0.45 * s) + ' L' + (bo[0] + bs * 0.35) + ' ' + (bo[1] - 0.45 * s) + ' L' + (bo[0] + bs * 0.5) + ' ' + bo[1] + ' Z', 1, 'set');
      for (const t of [a, b]) {
        rd.glow(t[0], t[1], Math.max(3, 1.1 * s), 0.9); rd.oval(t[0], t[1], Math.max(0.7, 0.14 * s), Math.max(0.5, 0.08 * s), 1);
        for (let y = t[1] + 2; y < t[1] + 3 + 2.4 * s; y += 0.8 + rnd() * 0.8) { const wd = Math.max(0.3, 0.1 * s) * (0.5 + rnd()); if (rnd() < 0.75) rd.line(t[0] - wd, y, t[0] + wd, y, 0.45, 0.6 * (0.5 + rnd() * 0.5)); }
      } }

    // ---- the building going on past the end of the deck, into the dark
    poly(k, [[UE, WB, GY], [90, WB, GY], [90, WB, 8.6], [UE, WB, 8.6]], 0.95, 'set');

    // ---- the rain off the awning's edge in ropes: thick where the troughs gather it, broken into
    // drops as it goes, white where the bulb gets to it
    for (let u = 1.0 + rnd() * 0.3; u < UE - 0.1; u += 0.28 + rnd() * 0.55) {
      const str = 0.25 + rnd() * 0.75;
      const top = P(u, WA, AE), bot = P(u, WA, GY), s = SC(u, WA);
      const L = clamp(0.08 + bulb(u, WA, 1.2) * 3.2, 0, 1);
      const th = Math.max(0.45, (0.006 + str * 0.012) * s);
      const brk = top[1] + (bot[1] - top[1]) * (0.35 + rnd() * 0.4);
      let x = top[0], y = top[1];
      k.c.save(); k.c.globalCompositeOperation = 'destination-out'; k.c.lineCap = 'round';
      while (y < Math.min(H + 4, bot[1])) {
        const seg = y < brk ? 6 + rnd() * 10 : 1 + rnd() * 3, gap = y < brk ? rnd() * 1.2 : 1.5 + rnd() * 4;
        const f = (y - top[1]) / Math.max(1, bot[1] - top[1]);
        k.c.strokeStyle = 'rgba(0,0,0,' + clamp(L * (0.95 - 0.5 * f) * (0.6 + str * 0.4), 0, 1) + ')';
        k.c.lineWidth = th * (y < brk ? 1 : 0.8);
        k.c.beginPath(); k.c.moveTo(x, y); x += (rnd() - 0.5) * 0.4; y += seg; k.c.lineTo(x, y); k.c.stroke();
        y += gap;
      }
      k.c.restore();
      k.oval(top[0], top[1] + 0.6, th * 0.8, th * 0.5, clamp(L, 0, 0.9), 'erase');
    }
    // ---- the awning: corrugated tin, ribs running out to its edge, lit round the bulb
    const awn = [[U0, WB, AT], [UE, WB, AT], [UE, WA, AE], [U0, WA, AE]];
    const awq = poly(k, awn, 0.93, 'set');
    const avx = vw, avy = hz - cam.f * slope / cam.s;
    lit2(j, k, awq,
      function (c) { return fan(c, avx, avy, 0, UE, function (u) { return P(u, WA, AE); }, function (u) { return 0.95 * G(u, BU, S2); }); },
      onW(aY, WB, WA, function (w) { return G(w, BW, S2) * G(aY(w), BY, 3); }, 8), 1);
    for (let u = 0.02; u < UE; u += 0.19) {
      const L = bulb(u, 0, AT - 0.2), sw = Math.max(0.35, 0.028 * SC(u, 0));
      line3(k, [u, WB, AT], [u, WA, AE], sw, 0.35 + 0.35 * (1 - L));
      if (L > 0.05) line3(k, [u + 0.06, WB, AT], [u + 0.06, WA, AE], sw * 0.6, 0.6 * L, 'erase');
    }
    // the beam it hangs off, and its edge
    line3(k, [U0, WA, AE], [UE, WA, AE], 1.6, 1);
    line3(k, [UE, WB, AT], [UE, WA, AE], 1.2, 1);

    // ---- the wall down the left: siding, lit round the door
    const wall = [[0.9, WB, 0], [UE, WB, 0], [UE, WB, AT], [0.9, WB, AT]];
    const wq = poly(k, wall, 0.92, 'set');
    const xU = function (u0, u1, fn) { return function (c) { const x0 = P(u0, WB, 0)[0], x1 = P(u1, WB, 0)[0], g = c.createLinearGradient(x0, 0, x1, 0); for (let i = 0; i <= 40; i++) { const u = u0 + (u1 - u0) * i / 40; g.addColorStop(clamp((P(u, WB, 0)[0] - x0) / (x1 - x0), 0, 1), 'rgba(0,0,0,' + clamp(fn(u), 0, 1) + ')'); } return g; }; };
    const upW = function (fn) { return function (c) { return fan(c, vu, hz, -0.2, AT + 0.2, function (Y) { return P(8, WB, Y); }, fn); }; };
    lit2(j, k, wq, xU(1, UE, function (u) { return 0.9 * G(u, BU, 4.5); }), upW(function (Y) { return G(Y, BY - 0.1, 3.2); }), 1);
    // lap siding: each board's lower edge a line of shadow
    for (let Y = 0.1; Y < AT; Y += 0.16) line3(k, [0.9, WB, Y], [UE, WB, Y], 0.6, 0.55);
    for (let Y = 0.1; Y < AT; Y += 0.16) line3(k, [0.9, WB + 0.004, Y + 0.02], [UE, WB + 0.004, Y + 0.02], 0.4, 0.22, 'erase');
    // the corner boards at the end, the trim at the bottom
    poly(k, [[UE - 0.12, WB, 0], [UE, WB, 0], [UE, WB, AT], [UE - 0.12, WB, AT]], 0.95, 'set');
    line3(k, [0.9, WB, 0.05], [UE, WB, 0.05], 1.2, 0.95);

    // the bar's window: inside, the room lit and the neon red in it, the bottles on the backbar;
    // it lays a square of its light out on the boards
    const w0 = 6.3, w1 = 7.6, wy0 = 0.95, wy1 = 2.02;
    poly(k, [[w0 - 0.08, WB, wy0 - 0.1], [w1 + 0.08, WB, wy0 - 0.1], [w1 + 0.08, WB, wy1 + 0.08], [w0 - 0.08, WB, wy1 + 0.08]], 1, 'set');
    const wiq = poly(k, [[w0, WB, wy0], [w1, WB, wy0], [w1, WB, wy1], [w0, WB, wy1]], 0.3, 'set');
    { const c = P((w0 + w1) / 2, WB, (wy0 + wy1) / 2), s = SC((w0 + w1) / 2, WB);
      rd.clip(function (cc) { cc.moveTo(wiq[0][0], wiq[0][1]); for (const q of wiq) cc.lineTo(q[0], q[1]); cc.closePath(); });
      rd.rect(c[0] - 40, c[1] - 40, 80, 80, 0.3); rd.glow(c[0] + 0.1 * s, c[1] - 0.2 * s, 0.9 * s, 0.9, 0.5 * s);
      rd.done();
      k.clip(function (cc) { cc.moveTo(wiq[0][0], wiq[0][1]); for (const q of wiq) cc.lineTo(q[0], q[1]); cc.closePath(); });
      for (let b = 0; b < 9; b++) { const bu = w0 + 0.1 + b * 0.13, bh = 0.18 + rnd() * 0.12; poly(k, [[bu, WB, 1.55], [bu + 0.05, WB, 1.55], [bu + 0.05, WB, 1.55 + bh], [bu, WB, 1.55 + bh]], 0.8, 'set'); }
      poly(k, [[w0, WB, wy0], [w1, WB, wy0], [w1, WB, 1.22], [w0, WB, 1.22]], 0.85, 'set');
      k.done(); }
    line3(k, [(w0 + w1) / 2, WB, wy0], [(w0 + w1) / 2, WB, wy1], 1.2, 1);
    line3(k, [w0, WB, (wy0 + wy1) / 2 + 0.1], [w1, WB, (wy0 + wy1) / 2 + 0.1], 0.9, 1);

    // the deck door under the bulb: a slab with a lite of glass, the bar through it; a folded
    // coaster in the latch so it won't lock, a sliver of the room's light down that edge; or shut
    const d0 = 4.55, d1 = 5.5, dh = 2.06;
    poly(k, [[d0 - 0.08, WB, 0], [d1 + 0.08, WB, 0], [d1 + 0.08, WB, dh + 0.08], [d0 - 0.08, WB, dh + 0.08]], 0.2, 'set');
    const dq = poly(k, [[d0, WB, 0], [d1, WB, 0], [d1, WB, dh], [d0, WB, dh]], 0.72, 'set');
    lit2(j, k, dq, xU(d0, d1, function (u) { return 0.75 * G(u, BU, 4.5); }), upW(function (Y) { return G(Y, BY - 0.2, 2.6); }), 1);
    const gq = poly(k, [[d0 + 0.14, WB, 1.05], [d1 - 0.14, WB, 1.05], [d1 - 0.14, WB, 1.86], [d0 + 0.14, WB, 1.86]], 0.35, 'set');
    rd.poly(gq, 0.14); rd.glow((gq[0][0] + gq[2][0]) / 2, (gq[0][1] + gq[2][1]) / 2, 10, 0.18);
    line3(k, [d0 + 0.14, WB, 1.45], [d1 - 0.14, WB, 1.45], 0.6, 0.7);
    // the lever and the latch, on the near edge
    { const p = P(d0 + 0.09, WB, 1.0), s = SC(d0 + 0.09, WB); k.line(p[0], p[1], p[0] + 0.07 * s, p[1] + 0.01 * s, Math.max(1, 0.03 * s), 1); k.oval(p[0], p[1], Math.max(0.9, 0.028 * s), Math.max(0.9, 0.028 * s), 0.9, 'set'); }
    if (open) {
      line3(k, [d0 + 0.01, WB + 0.01, 0.04], [d0 + 0.01, WB + 0.01, dh - 0.03], 1.2, 0.9, 'erase');
      poly(k, [[d0 - 0.02, WB + 0.01, 1.03], [d0 + 0.05, WB + 0.01, 1.03], [d0 + 0.05, WB + 0.01, 1.11], [d0 - 0.02, WB + 0.01, 1.11]], 0, 'set');
      const q = P(d0, WB + 0.3, 0); rd.glow(q[0] + 4, q[1] - 2, 10, 0.18);
    }
    // the caged bulb
    { const p = P(BU, BW, BY), s = SC(BU, BW);
      k.light(p[0], p[1], 1.6 * s, 0.4); k.light(p[0], p[1], 0.45 * s, 0.85);
      k.oval(p[0], p[1], 0.05 * s, 0.065 * s, 0, 'set');
      for (let c = -2; c <= 2; c++) k.line(p[0] + c * 0.022 * s, p[1] - 0.075 * s, p[0] + c * 0.027 * s, p[1] + 0.075 * s, 0.5, 0.75);
      k.line(p[0] - 0.065 * s, p[1], p[0] + 0.065 * s, p[1], 0.5, 0.75);
      const m = P(BU, WB, BY + 0.12); k.rect(Math.min(m[0], p[0]) - 0.02 * s, p[1] - 0.14 * s, Math.abs(p[0] - m[0]) + 0.05 * s, 0.05 * s, 1, 'set'); }

    // ---- the deck: boards running its length, wet, the bulb and the window lying in the wet
    const deck = [[U0, WB, 0], [UE, WB, 0], [UE, WR, 0], [U0, WR, 0]];
    const fq = poly(k, deck, 0.9, 'set');
    lit2(j, k, fq, onU(0, 1, UE, function (u) { return 0.8 * G(u, BU, S2); }), onW(0, WB, WR, function (w) { return G(w, BW, S2) * 0.8; }, 8), 1);
    // the window's square of light on the boards, red in it
    { const sq = shape3(cam, [[w0 + 0.1, WB, 0], [w1 + 0.3, WB, 0], [w1 + 0.7, WB + 1.3, 0], [w0 + 0.4, WB + 1.3, 0]]);
      k.poly(sq, 0.25, 'erase'); rd.poly(sq, 0.2); }
    for (let w = WB + 0.14; w < WR; w += 0.14) line3(k, [U0, w, 0], [UE, w, 0], 0.55, 0.6);
    // the bulb in the wet: a smear down the boards toward you
    { const r = P(BU + 0.2, BW + 0.9, 0), s = SC(BU + 0.2, BW + 0.9);
      for (let y = r[1]; y < Math.min(H, r[1] + 1.4 * s); y += 1.2 + rnd() * 1.6) { const f = (y - r[1]) / (1.4 * s), wd = (0.02 + f * 0.05) * s * (0.4 + rnd()); if (rnd() < 0.6) k.line(r[0] - wd + f * 6, y, r[0] + wd + f * 6, y, 0.5, 0.3 * (1 - f) * (0.4 + rnd() * 0.6), 'erase'); } }
    // the steps' prints are for the night it happens; tonight the boards are just wet
    // the end of the deck, its rail across, the dark past it
    for (let w = WB + 0.1; w < WR; w += 0.12) line3(k, [UE, w, 0.08], [UE, w, 1.0], 0.5, 0.95);
    line3(k, [UE, WB, 1.05], [UE, WR, 1.05], 1.2, 0.95);

    // plastic chairs: one out at the rail facing the water, two stacked against the wall past the
    // window, one tipped against the rail to drain
    const chair = function (u, w, tip, flip, back) {
      const p = P(u, w, 0), s = SC(u, w), L = bulb(u, w, 0.6) * 1.3 + 0.08;
      const x = p[0], y = p[1];
      const wd = 0.5 * s, sh = 0.43 * s, bh = 0.84 * s, ah = 0.62 * s;
      const face = clamp(0.55 - 0.6 * L, 0.04, 0.6);
      k.c.save(); k.c.translate(x, y); if (tip) k.c.rotate(tip); if (flip) k.c.scale(flip, 1);
      for (const lx of [-0.46, 0.46]) k.line(lx * wd, -sh, lx * wd * 1.18, 0, Math.max(0.7, 0.045 * s), 0.85);
      if (back) {
        k.path('M' + (-0.47 * wd) + ' ' + (-sh) + ' L' + (-0.5 * wd) + ' ' + (-bh + 0.05 * s) + ' Q0 ' + (-bh - 0.07 * s) + ' ' + (0.5 * wd) + ' ' + (-bh + 0.05 * s) + ' L' + (0.47 * wd) + ' ' + (-sh) + ' Z', face + 0.2, 'set');
      } else {
        k.path('M' + (-0.47 * wd) + ' ' + (-sh) + ' L' + (-0.5 * wd) + ' ' + (-bh + 0.05 * s) + ' Q0 ' + (-bh - 0.07 * s) + ' ' + (0.5 * wd) + ' ' + (-bh + 0.05 * s) + ' L' + (0.47 * wd) + ' ' + (-sh) + ' Z', face, 'set');
        for (let i = 0; i < 6; i++) { const sx = (-0.3 + i * 0.12) * wd; k.line(sx, -bh + 0.1 * s, sx, -ah + 0.02 * s, Math.max(0.5, 0.02 * s), 0.9); }
      }
      for (const ax of [-1, 1]) k.path('M' + (ax * 0.5 * wd) + ' ' + (-ah) + ' Q' + (ax * 0.62 * wd) + ' ' + (-ah - 0.01 * s) + ' ' + (ax * 0.62 * wd) + ' ' + (-ah + 0.04 * s) + ' L' + (ax * 0.58 * wd) + ' ' + (-sh) + ' L' + (ax * 0.5 * wd) + ' ' + (-sh) + ' Z', face, 'set');
      k.poly([[-0.56 * wd, -sh], [0.56 * wd, -sh], [0.5 * wd, -sh + 0.05 * s], [-0.5 * wd, -sh + 0.05 * s]], face, 'set');
      k.line(-0.5 * wd, -sh + 0.05 * s, 0.5 * wd, -sh + 0.05 * s, Math.max(0.5, 0.016 * s), 0.9);
      k.stroke('M' + (-0.5 * wd) + ' ' + (-bh + 0.05 * s) + ' Q0 ' + (-bh - 0.07 * s) + ' ' + (0.5 * wd) + ' ' + (-bh + 0.05 * s), Math.max(0.5, 0.012 * s), 0.8);
      k.c.restore();
    };
    chair(8.6, -1.3, 0, 0.6, false);
    chair(8.62, -1.28, 0, 0.6, false);
    chair(9.9, 1.0, -0.42, 0.8, true);
    chair(5.9, 0.75, 0, 0.75, true);

    // ---- the rail: posts, the pickets, the top rail catching the bulb; a gap for the steps down
    const ST0 = 3.1, ST1 = 4.2;
    const posts = [U0, 0.5, 2.0, ST0, ST1, 5.7, 7.2, 8.7, 10.2, 11.7, UE];
    for (let u = U0 + 0.06; u < UE; u += 0.12) {
      if (u > ST0 && u < ST1) continue;
      if (cam.D(u, WR) < 0.3) continue;
      const L = bulb(u, WR, 0.6), s = SC(u, WR);
      line3(k, [u, WR, 0.1], [u, WR, 1.0], Math.max(0.5, 0.04 * s), 0.95);
      if (L > 0.06) line3(k, [u - 0.012, WR - 0.02, 0.12], [u - 0.012, WR - 0.02, 0.98], Math.max(0.3, 0.012 * s), 0.8 * L, 'erase');
    }
    for (const u of posts) {
      if (cam.D(u, WR) < 0.3) continue;
      const s = SC(u, WR), L = bulb(u, WR, 0.6);
      line3(k, [u, WR, 0], [u, WR, 1.1], Math.max(0.8, 0.09 * s), 1);
      if (L > 0.05) line3(k, [u - 0.03, WR - 0.045, 0], [u - 0.03, WR - 0.045, 1.08], Math.max(0.3, 0.025 * s), 0.8 * L, 'erase');
    }
    const xAt = function (w, u0, u1, fn) { return function (c) { const x0 = P(u0, w, 0)[0], x1 = P(u1, w, 0)[0], g = c.createLinearGradient(x0, 0, x1, 0); for (let i = 0; i <= 40; i++) { const u = u0 + (u1 - u0) * i / 40; g.addColorStop(clamp((P(u, w, 0)[0] - x0) / (x1 - x0), 0, 1), 'rgba(0,0,0,' + clamp(fn(u), 0, 1) + ')'); } return g; }; };
    const railTop = function (a, b) {
      const wi = WR - 0.07, a1 = Math.max(a, 0.2);
      line3(k, [a, WR, 0.1], [b, WR, 0.1], 1.2, 1);
      const fq = poly(k, [[a, wi, 0.94], [b, wi, 0.94], [b, wi, 1.05], [a, wi, 1.05]], 0.82, 'set');
      lit2(j, k, fq, xAt(wi, a1, b, function (u) { return 0.2 + 0.72 * G(u, BU, 6); }), null, 1);
      line3(k, [a, wi, 0.94], [b, wi, 0.94], 0.8, 1);
      for (let u = a1; u < b; u += 0.2) line3(k, [u, wi, 1.05], [Math.min(b, u + 0.2), wi, 1.05], 1, 0.35 + 0.6 * G(u + 0.1, BU, 8), 'erase');
    };
    railTop(U0, ST0); railTop(ST1, UE);
    // the steps going down in the gap, their rails
    for (let i = 1; i <= 5; i++) {
      const Y = -i * 0.22, w = WR + i * 0.28;
      poly(k, [[ST0, w - 0.28, Y], [ST1, w - 0.28, Y], [ST1, w, Y], [ST0, w, Y]], clamp(0.5 + i * 0.09 - bulb(3.6, WR, 0) * 0.5, 0.3, 0.97), 'set');
      line3(k, [ST0, w, Y], [ST1, w, Y], 0.6, 0.95);
    }
    for (const u of [ST0, ST1]) { line3(k, [u, WR, 1.05], [u, WR + 1.5, -0.1], 1.1, 1); line3(k, [u, WR + 1.5, -0.1], [u, WR + 1.5, -1.25], 0.9, 1); }

    // the coffee can of butts on the rail
    { const u = 2.3, p = P(u, WR, 1.05), s = SC(u, WR), L = bulb(u, WR, 1.1) * 1.6;
      const x = p[0], y = p[1], r = 0.055 * s, h = 0.15 * s;
      k.rect(x - r, y - h, 2 * r, h, k.lin(x - r, 0, x + r, 0, [[0, clamp(0.55 - L, 0.1, 0.9)], [0.3, clamp(0.45 - L, 0.1, 0.9)], [0.7, 0.85], [1, 0.97]]), 'set');
      for (const f of [0.18, 0.82]) k.line(x - r, y - f * h, x + r, y - f * h, 0.45, 0.6);
      k.oval(x, y - h, r, r * 0.28, 1, 'set');
      for (let i = 0; i < 10; i++) { const bx = x + (rnd() - 0.5) * 1.6 * r, by = y - h; k.line(bx, by, bx + (rnd() - 0.5) * 0.8 * r, by - (0.3 + rnd() * 0.6) * r, Math.max(0.6, 0.012 * s), 0.08, 'set'); }
      k.line(x - r * 0.6, y - h - 0.2, x + r * 0.2, y - h - r * 1.1, 0.6, 0.15, 'set'); }

    // rain in the bulb's light
    { const p = P(BU, 0.4, 1.4), s = SC(BU, 0.4);
      k.clip(function (c) { c.arc(p[0], p[1], 2.6 * s, 0, Math.PI * 2); });
      k.rain(rnd, 110, p[0] - 2.6 * s, p[1] - 2.6 * s, 5.2 * s, 5.2 * s, { tone: 0.45, len: 0.14 * s, w: 0.45, slant: 0.1 });
      k.done(); }

    vignette(k, 0.28);
    edge(k);
  };

  // The room upstairs, the one that came with the job, at twenty past three: a bed, a chair, a sink
  // in the corner, and a window onto the lot and the highway and the water. No light on. The lot's
  // lamp comes up through the rain on the glass and lies on the ceiling; the red of the sign on the
  // roof comes down and lies across the bed. An iron bed, the hotel's spread on it; a wooden chair;
  // the basin in the corner with its mirror; the radiator under the window; a bulb on a chain.
  // What he brought up with him isn't drawn: that's Hutch's to say (the HUTCH note in closing.ink).
  PLACES.upstairs = function (j, look, rnd) {
    const k = j.k, rd = j.r;
    const cam = camera(300, 100, 190, 1.62);
    const X = cam.x, Y = cam.y, S = cam.s;
    const XL = -2.1, XR = 1.9, CH = 2.8, DN = 0.6, DB = 3.1;
    const quad = function (Xw, y0, y1, d0, d1) { return [[X(Xw, d0), Y(y1, d0)], [X(Xw, d1), Y(y1, d1)], [X(Xw, d1), Y(y0, d1)], [X(Xw, d0), Y(y0, d0)]]; };
    const flat = function (Yh, x0, x1, d0, d1) { return [[X(x0, d0), Y(Yh, d0)], [X(x1, d0), Y(Yh, d0)], [X(x1, d1), Y(Yh, d1)], [X(x0, d1), Y(Yh, d1)]]; };
    const face = function (D, x0, x1, y0, y1) { return [[X(x0, D), Y(y1, D)], [X(x1, D), Y(y1, D)], [X(x1, D), Y(y0, D)], [X(x0, D), Y(y0, D)]]; };
    const byDepth = function (plane, at, d0, d1, fn) { return depthTone(k, cam, plane, at, d0, d1, fn); };
    // the window, in the far wall
    const WX0 = -0.28, WX1 = 0.74, WY0 = 0.92, WY1 = 2.36, WM = 1.64, REV = 0.16;
    const wx0 = X(WX0, DB), wx1 = X(WX1, DB), wy0 = Y(WY1, DB), wy1 = Y(WY0, DB);

    // ---- the ceiling, the walls, the floor: dark, the walls papered in a stripe gone to nothing
    k.rect(0, 0, W, H, 0.92, 'set');
    k.poly(flat(CH, XL, XR, DN, DB), byDepth('y', CH, DN, DB, function (D) { return clamp(0.93 - 0.1 * Math.pow((D - DN) / (DB - DN), 2), 0.8, 0.95); }), 'set');
    // the lot's lamp, up through the window: a pale smear of it on the ceiling over the glass
    { const c = [X((WX0 + WX1) / 2 + 0.15, 2.45), Y(CH, 2.45)]; k.light(c[0], c[1], 90, 0.3, 14); k.light(c[0], c[1] + 2, 40, 0.18, 8); }
    // a water stain, a ring, from some winter
    { const c = [X(-1.1, 2.6), Y(CH, 2.6)]; k.oval(c[0], c[1], 16, 3.2, 0.12, 'erase'); k.stroke('M' + (c[0] - 15) + ' ' + c[1] + ' q 6 -3.5 15 -3 q 10 0.5 14 2.6', 0.7, 0.35); }
    // the walls
    for (const Xw of [XL, XR]) {
      k.poly(quad(Xw, 0, CH, DN, DB), byDepth('x', Xw, DN, DB, function (D) { return clamp(0.87 - (Xw > 0 ? 0.24 : 0.18) * Math.pow((D - DN) / (DB - DN), 1.6), 0.55, 0.95); }), 'set');
      wallFall(k, cam, Xw, DN, DB, CH, 0, 0.08, 0.1);
      for (let D = DN + 0.02; D < DB; D += 0.1) k.line(X(Xw, D), Y(2.2, D), X(Xw, D), Y(0.14, D), Math.max(0.4, 0.035 * S(D)), 0.1);
      k.poly(quad(Xw, 2.2, 2.26, DN, DB), 0.98, 'set');
      k.poly(quad(Xw, 0, 0.14, DN, DB), 0.98, 'set');
      k.line(X(Xw, DN), Y(0.145, DN), X(Xw, DB), Y(0.145, DB), 0.6, byDepth('x', Xw, DN, DB, function (D) { return 0.35 * Math.pow((D - DN) / (DB - DN), 2); }), 'erase');
    }
    // the far wall, the dark side of the window
    k.poly(face(DB, XL, XR, 0, CH), 0.86, 'set');
    k.light((wx0 + wx1) / 2, (wy0 + wy1) / 2 + 20, 120, 0.12, 70);
    for (let x = XL + 0.05; x < XR; x += 0.1) k.line(X(x, DB), Y(2.2, DB), X(x, DB), Y(0.14, DB), Math.max(0.4, 0.035 * S(DB)), 0.06);
    k.poly(face(DB, XL, XR, 2.2, 2.26), 1, 'set');
    k.poly(face(DB, XL, XR, 0, 0.14), 1, 'set');
    // the floor: old carpet, nearly black
    k.poly(flat(0, XL, XR, DN, DB), 0.94, 'set');

    // ---- the window: the lot and the highway and the water through the rain on it
    // what's out there
    k.rect(wx0, wy0, wx1 - wx0, wy1 - wy0, k.lin(0, wy0, 0, wy1, [[0, 0.8], [0.45, 0.86], [0.62, 0.95], [1, 0.9]]), 'set');
    const ohz = wy0 + (wy1 - wy0) * 0.55;
    // far shore lights on the black water, the highway's lamps in a line, the lot lamp close and low
    for (let i = 0; i < 22; i++) { const x = wx0 + rnd() * (wx1 - wx0), y = ohz - rnd() * 1.2; k.oval(x, y, 0.45, 0.4, 0.8, 'erase'); if (rnd() < 0.5) k.line(x, y + 1.5, x, y + 2 + rnd() * 5, 0.4, 0.4, 'erase'); }
    k.rect(wx0, ohz + 6, wx1 - wx0, 1.4, 0.55, 'erase');
    for (let i = 0; i < 5; i++) { const x = wx0 + 6 + i * (wx1 - wx0 - 8) / 4.2, y = ohz + 4.5 - i * 0.4; k.light(x, y, 4, 0.5); k.oval(x, y, 0.8, 0.6, 1, 'erase'); }
    const LX = wx0 + (wx1 - wx0) * 0.24, LY = wy0 + (wy1 - wy0) * 0.72;
    k.light(LX, LY, 26, 0.55);
    k.light(LX, LY, 7, 0.9);
    k.oval(LX, LY, 1.8, 1.2, 0, 'set');
    // the sign up on the roof, out of sight: its red coming down over the top of the glass
    rd.rect(wx0, wy0, wx1 - wx0, (wy1 - wy0) * 0.5, rd.lin(0, wy0, 0, wy0 + (wy1 - wy0) * 0.5, [[0, 0.75], [1, 0]]));
    k.rect(wx0, wy0, wx1 - wx0, (wy1 - wy0) * 0.4, k.lin(0, wy0, 0, wy0 + (wy1 - wy0) * 0.4, [[0, 0.4], [1, 0]]), 'erase');
    // rain on the glass: drops, a few running, lit where the lamp's behind them
    for (let i = 0; i < 150; i++) {
      const x = wx0 + rnd() * (wx1 - wx0), y = wy0 + rnd() * (wy1 - wy0), r = 0.4 + rnd() * rnd() * 1.4;
      const near = Math.exp(-((x - LX) * (x - LX) + (y - LY) * (y - LY)) / 500);
      k.oval(x, y + r * 0.4, r, r * 1.1, 0.35 + 0.3 * (1 - near), 'ink');
      k.oval(x - r * 0.3, y - r * 0.2, r * 0.45, r * 0.45, 0.4 + 0.6 * near, 'erase');
      if (y < wy0 + (wy1 - wy0) * 0.45) rd.oval(x, y, r * 0.8, r * 0.8, 0.25);
    }
    for (let i = 0; i < 9; i++) { const x = wx0 + 2 + rnd() * (wx1 - wx0 - 4), y = wy0 + rnd() * (wy1 - wy0) * 0.6; let d = 'M' + x + ' ' + y, xx = x; for (let yy = y; yy < wy1; yy += 2.5) { xx += (rnd() - 0.5) * 0.9; d += ' L' + xx + ' ' + yy; } k.stroke(d, 0.7, 0.45); k.stroke(d, 0.3, 0.5, 'erase'); }
    // the reveal: the wall's thickness round the glass, lit red down its left side
    k.poly([[X(WX0, DB), Y(WY1, DB)], [X(WX0, DB + REV), Y(WY1, DB + REV)], [X(WX0, DB + REV), Y(WY0, DB + REV)], [X(WX0, DB), Y(WY0, DB)]], 0.6, 'set');
    rd.poly([[X(WX0, DB), Y(WY1, DB)], [X(WX0, DB + REV), Y(WY1, DB + REV)], [X(WX0, DB + REV), Y(WY0, DB + REV)], [X(WX0, DB), Y(WY0, DB)]], rd.lin(0, Y(WY1, DB), 0, Y(WY0, DB), [[0, 0.6], [1, 0.15]]));
    k.poly([[X(WX1, DB), Y(WY1, DB)], [X(WX1, DB + REV), Y(WY1, DB + REV)], [X(WX1, DB + REV), Y(WY0, DB + REV)], [X(WX1, DB), Y(WY0, DB)]], 0.9, 'set');
    k.poly([[X(WX0, DB), Y(WY0, DB)], [X(WX1, DB), Y(WY0, DB)], [X(WX1, DB + REV), Y(WY0, DB + REV)], [X(WX0, DB + REV), Y(WY0, DB + REV)]], 0.45, 'set');
    rd.poly([[X(WX0, DB), Y(WY0, DB)], [X(WX1, DB), Y(WY0, DB)], [X(WX1, DB + REV), Y(WY0, DB + REV)], [X(WX0, DB + REV), Y(WY0, DB + REV)]], 0.35);
    k.poly([[X(WX0, DB), Y(WY1, DB)], [X(WX1, DB), Y(WY1, DB)], [X(WX1, DB + REV), Y(WY1, DB + REV)], [X(WX0, DB + REV), Y(WY1, DB + REV)]], 0.97, 'set');
    // the sashes: two over two, the meeting rail, paint over paint
    { const D = DB + REV * 0.7, fw = Math.max(1.2, 0.05 * S(D));
      const gx0 = X(WX0, D), gx1 = X(WX1, D), gy0 = Y(WY1, D), gy1 = Y(WY0, D), gm = Y(WM, D), gc = (gx0 + gx1) / 2;
      k.rect(gx0, gy0, gx1 - gx0, fw, 1, 'set'); k.rect(gx0, gy1 - fw, gx1 - gx0, fw, 1, 'set');
      k.rect(gx0, gy0, fw, gy1 - gy0, 1, 'set'); k.rect(gx1 - fw, gy0, fw, gy1 - gy0, 1, 'set');
      k.rect(gx0, gm - fw * 0.7, gx1 - gx0, fw * 1.4, 1, 'set');
      k.rect(gc - fw * 0.35, gy0, fw * 0.7, gy1 - gy0, 1, 'set');
      k.line(gx0 + fw, gm - fw * 0.7, gx1 - fw, gm - fw * 0.7, 0.5, 0.5, 'erase');
      // the blind rolled up under the head, its cord and ring
      k.rect(gx0 - 1, gy0 + fw, gx1 - gx0 + 2, fw * 1.5, 0.85, 'set');
      k.line(gc + 6, gy0 + fw * 2.5, gc + 6, gm + 8, 0.45, 0.9);
      k.oval(gc + 6, gm + 9.5, 1.5, 1.5, 0.9, 'set'); k.oval(gc + 6, gm + 9.5, 0.8, 0.8, 0, 'set'); }
    // the sill, its front edge catching the red
    k.poly(face(DB - 0.04, WX0 - 0.08, WX1 + 0.08, WY0 - 0.05, WY0), 0.3, 'set');
    rd.poly(face(DB - 0.04, WX0 - 0.08, WX1 + 0.08, WY0 - 0.05, WY0), 0.45);

    // ---- the radiator under it: iron columns, the red along their tops
    { const D = DB - 0.13, y0 = Y(0.12, D), y1 = Y(0.72, D);
      for (let x = WX0 + 0.02; x < WX1 - 0.02; x += 0.065) {
        const a = X(x, D), b = X(x + 0.05, D);
        k.rect(a, y1 + 1, b - a, y0 - y1 - 1, 1, 'set');
        k.oval((a + b) / 2, y1 + 1.2, (b - a) / 2, 1.1, 0.7, 'set');
        rd.oval((a + b) / 2, y1 + 0.9, (b - a) / 2, 0.8, 0.5);
      }
      k.rect(X(WX0 + 0.02, D), Y(0.12, D), X(WX1 - 0.02, D) - X(WX0 + 0.02, D), 1.5, 1, 'set');
      // its riser, up the wall
      k.line(X(WX1 + 0.05, D + 0.05), Y(0.2, D + 0.05), X(WX1 + 0.05, D + 0.05), Y(CH, D + 0.05), 1.3, 1); }
    // a gap in the baseboard by it, gnawed
    k.poly([[X(1.05, DB), Y(0, DB)], [X(1.12, DB), Y(0, DB)], [X(1.1, DB), Y(0.06, DB)], [X(1.07, DB), Y(0.065, DB)]], 1, 'set');

    // ---- the chair: wood, against the wall right of the window, its top rail catching the lamp
    { const D = DB - 0.3, cx = 1.28, sw = 0.42, s = S(D);
      const x0 = X(cx - sw / 2, D), x1 = X(cx + sw / 2, D), ys = Y(0.46, D), yb = Y(0.95, D), yf = Y(0, D);
      for (const lx of [x0 + 0.03 * s, x1 - 0.03 * s]) k.line(lx, yb, lx, yf, Math.max(1, 0.035 * s), 1);
      const yb2 = Y(0.46, D + 0.3), yf2 = Y(0, D + 0.3);
      k.line(X(cx - sw / 2 + 0.03, D + 0.3), ys, X(cx - sw / 2 + 0.03, D + 0.3), yf2, Math.max(0.8, 0.03 * s), 1);
      k.poly([[x0 - 1, ys], [x1 + 1, ys], [X(cx + sw / 2, D + 0.36), yb2], [X(cx - sw / 2, D + 0.36), yb2]], 0.6, 'set');
      k.rect(x0 - 1, ys, x1 - x0 + 2, 0.04 * s, 1, 'set');
      k.rect(x0, yb - 0.02 * s, x1 - x0, 0.09 * s, 1, 'set');
      for (let i = 1; i < 4; i++) { const x = x0 + (x1 - x0) * i / 4; k.line(x, yb + 0.07 * s, x, ys, Math.max(0.6, 0.018 * s), 1); }
      k.line(x0 + 0.5, yb - 0.02 * s, x1 - 1, yb - 0.02 * s, 0.7, 0.55, 'erase');
      k.line(x0 - 1, ys + 0.2, x1 + 1, ys + 0.2, 0.6, 0.35, 'erase'); }

    // ---- the basin in the corner, on the right wall: porcelain, the one pale thing in the room; the
    // mirror over it with the window in it, red; the pipes under, the gap where they go into the wall
    { const d0 = 2.42, d1 = 2.96, Xs = XR, dm = (d0 + d1) / 2;
      // the mirror, its frame, the window and the red in it
      k.poly(quad(Xs, 1.22, 1.84, d0 + 0.04, d1 - 0.04), 1, 'set');
      const mq = quad(Xs, 1.26, 1.8, d0 + 0.07, d1 - 0.07);
      k.poly(mq, 0.62, 'set');
      rd.poly(mq, rd.lin(mq[0][0], 0, mq[1][0], 0, [[0, 0.1], [0.6, 0.5], [1, 0.3]]));
      k.poly([[X(Xs, d0 + 0.3), Y(1.72, d0 + 0.3)], [X(Xs, d1 - 0.1), Y(1.74, d1 - 0.1)], [X(Xs, d1 - 0.1), Y(1.38, d1 - 0.1)], [X(Xs, d0 + 0.3), Y(1.36, d0 + 0.3)]], 0.35, 'erase');
      // the basin
      const bx = X(Xs - 0.42, dm), bxr = X(Xs, dm), by = Y(0.82, dm), s = S(dm);
      k.path('M' + bx + ' ' + by + ' L' + bxr + ' ' + (by - 0.02 * s) + ' L' + bxr + ' ' + (by + 0.22 * s) + ' Q' + ((bx + bxr) / 2) + ' ' + (by + 0.3 * s) + ' ' + (bx + 0.03 * s) + ' ' + (by + 0.12 * s) + ' Z', 0.3, 'set');
      k.path('M' + bx + ' ' + by + ' L' + bxr + ' ' + (by - 0.02 * s) + ' L' + bxr + ' ' + (by + 0.22 * s) + ' Q' + ((bx + bxr) / 2) + ' ' + (by + 0.3 * s) + ' ' + (bx + 0.03 * s) + ' ' + (by + 0.12 * s) + ' Z', k.lin(bx, 0, bxr, 0, [[0, 0], [0.5, 0.25], [1, 0.6]]), 'ink');
      k.oval((bx + bxr) / 2 + 0.03 * s, by + 0.01 * s, (bxr - bx) / 2 - 0.02 * s, 0.035 * s, 0.75, 'set');
      k.line(bx, by, bxr, by - 0.02 * s, Math.max(0.7, 0.015 * s), 0.1, 'set');
      rd.oval(bx + 0.08 * s, by + 0.05 * s, 0.1 * s, 0.06 * s, 0.25);
      // the taps
      for (const t of [-0.12, 0.08]) { const tx = X(Xs - 0.06, dm + t), ty = Y(0.9, dm + t); k.line(tx, ty, tx, ty + 0.05 * s, Math.max(0.8, 0.02 * s), 1); k.line(tx - 0.03 * s, ty, tx + 0.03 * s, ty, Math.max(0.8, 0.02 * s), 1); k.oval(tx, ty - 0.005 * s, 0.012 * s, 0.012 * s, 0.4, 'erase'); }
      // the trap and the pipes into the wall
      const px = (bx + bxr) / 2 + 0.02 * s, py = by + 0.28 * s;
      k.stroke('M' + px + ' ' + py + ' L' + px + ' ' + (py + 0.12 * s) + ' Q' + px + ' ' + (py + 0.2 * s) + ' ' + (px + 0.06 * s) + ' ' + (py + 0.2 * s) + ' L' + (bxr - 0.01 * s) + ' ' + (py + 0.2 * s), Math.max(0.9, 0.035 * s), 0.95);
      k.line(px - 0.01 * s, py + 0.05 * s, px - 0.01 * s, py + 0.15 * s, 0.4, 0.4, 'erase');
      k.oval(bxr - 0.005 * s, py + 0.2 * s, 0.035 * s, 0.05 * s, 1, 'set');
      // the light over the mirror, off
      k.rect(X(Xs, dm) - 0.12 * s, Y(1.95, dm), 0.1 * s, 0.05 * s, 1, 'set'); }

    // ---- the bed: iron, along the left wall, its head to the window wall; the hotel's spread on it
    const BX0 = XL + 0.03, BX1 = -0.95, BD0 = 1.28, BD1 = DB - 0.05, BT = 0.58;
    // the headboard against the far wall: iron bars and a bent top rail
    { const D = BD1 + 0.02, s = S(D), x0 = X(BX0, D), x1 = X(BX1, D), yt = Y(1.22, D), yb = Y(0.3, D);
      k.line(x0 + 1, yt, x0 + 1, Y(0, D), Math.max(1.2, 0.04 * s), 1);
      k.line(x1 - 1, yt, x1 - 1, Y(0, D), Math.max(1.2, 0.04 * s), 1);
      k.stroke('M' + x0 + ' ' + (yt + 3) + ' Q' + ((x0 + x1) / 2) + ' ' + (yt - 5) + ' ' + x1 + ' ' + (yt + 3), Math.max(1.1, 0.03 * s), 1);
      k.line(x0, Y(0.95, D), x1, Y(0.95, D), Math.max(0.8, 0.02 * s), 1);
      for (let i = 1; i < 9; i++) { const x = x0 + (x1 - x0) * i / 9; k.line(x, Y(0.95, D), x, yt + 3 - 5 * Math.sin(Math.PI * i / 9) + 1, Math.max(0.6, 0.012 * s), 1); }
      for (const bx of [x0 + 1, x1 - 1]) k.oval(bx, yt - 1.5, 2, 2, 1, 'set');
      k.line(x1 - 0.4, yt + 1, x1 - 0.4, Y(0.35, D), 0.5, 0.45, 'erase'); rd.line(x1 - 0.4, yt + 1, x1 - 0.4, Y(0.35, D), 0.5, 0.4); }
    // the spread over the mattress, the long side hanging down, chenille in rows
    const top = flat(BT, BX0, BX1, BD0, BD1);
    k.poly(top, byDepth('y', BT, BD0, BD1, function (D) { return clamp(0.8 - 0.14 * (D - BD0), 0.55, 0.85); }), 'set');
    k.poly(quad(BX1, 0.25, BT, BD0, BD1), 0.9, 'set');
    for (let x = BX0 + 0.08; x < BX1; x += 0.085) k.line(X(x, BD0), Y(BT, BD0), X(x, BD1), Y(BT, BD1), 0.55, 0.3);
    for (let D = BD0 + 0.06; D < BD1; D += 0.12) for (let x = BX0 + 0.12; x < BX1; x += 0.17) k.oval(X(x, D), Y(BT, D), Math.max(0.4, 0.012 * S(D)), Math.max(0.3, 0.006 * S(D)), 0.35, 'erase');
    for (let D = BD0 + 0.05; D < BD1; D += 0.07) k.line(X(BX1, D), Y(BT, D), X(BX1, D), Y(0.27, D), 0.5, 0.35);
    k.line(X(BX1, BD0), Y(BT, BD0), X(BX1, BD1), Y(BT, BD1), 1, 0.4, 'erase');
    // the pillow, flat, the spread folded over it
    { const D = BD1 - 0.28, pts = [[X(BX0 + 0.12, D - 0.08), Y(BT + 0.02, D - 0.08)], [X(BX1 - 0.12, D - 0.1), Y(BT + 0.02, D - 0.1)], [X(BX1 - 0.1, BD1 - 0.04), Y(BT + 0.12, BD1 - 0.04)], [X(BX0 + 0.1, BD1 - 0.03), Y(BT + 0.13, BD1 - 0.03)]];
      k.poly(pts, 0.45, 'set');
      k.stroke('M' + pts[0][0] + ' ' + pts[0][1] + ' Q' + ((pts[0][0] + pts[1][0]) / 2) + ' ' + (pts[0][1] - 3) + ' ' + pts[1][0] + ' ' + pts[1][1], 1, 0.7);
      k.line(X(BX0, D - 0.12), Y(BT, D - 0.12), X(BX1, D - 0.12), Y(BT, D - 0.12), 1.4, 0.85); }
    // the red across it, the shape of the window with the cross of the sash in it
    { const P = [[-1.35, 2.62], [-0.75, 2.62], [-1.3, 1.62], [-1.95, 1.62]];
      const q = P.map(function (p) { return [X(p[0], p[1]), Y(BT, p[1])]; });
      k.clip(function (c) { const t = top; c.moveTo(t[0][0], t[0][1]); for (const p of t) c.lineTo(p[0], p[1]); c.closePath(); });
      rd.clip(function (c) { const t = top; c.moveTo(t[0][0], t[0][1]); for (const p of t) c.lineTo(p[0], p[1]); c.closePath(); });
      rd.poly(q, 0.62); k.poly(q, 0.3, 'erase');
      const mid = function (a, b, t) { return [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t]; };
      const l0 = mid(q[0], q[3], 0.5), l1 = mid(q[1], q[2], 0.5), c0 = mid(q[0], q[1], 0.5), c1 = mid(q[3], q[2], 0.5);
      k.line(l0[0], l0[1], l1[0], l1[1], 2.2, 0.8); rd.line(l0[0], l0[1], l1[0], l1[1], 2.2, 0.62, 'erase');
      k.line(c0[0], c0[1], c1[0], c1[1], 1.5, 0.8); rd.line(c0[0], c0[1], c1[0], c1[1], 1.5, 0.62, 'erase');
      k.done(); rd.done(); }
    // the footboard toward you: the rail, the posts and their knobs, the bars going down out of sight
    { const D = BD0, s = S(D), x0 = X(BX0, D), x1 = X(BX1, D), yt = Y(0.95, D);
      for (let i = 1; i < 12; i++) { const x = x0 + (x1 - x0) * i / 12; k.line(x, yt, x, H + 2, Math.max(0.8, 0.014 * s), 1); if (i > 8) k.line(x + 0.6, yt + 2, x + 0.6, H, 0.5, 0.3, 'erase'); }
      k.line(x0, yt, x1, yt, Math.max(1.4, 0.028 * s), 1);
      k.line(x0, yt - 0.9, x1, yt - 0.9, 0.6, 0.35, 'erase');
      for (const px of [x0 + 0.02 * s, x1 - 0.02 * s]) {
        k.line(px, yt - 0.05 * s, px, H + 2, Math.max(1.6, 0.04 * s), 1);
        k.oval(px, yt - 0.07 * s, 0.035 * s, 0.035 * s, 1, 'set');
        k.oval(px + 0.01 * s, yt - 0.08 * s, 0.012 * s, 0.012 * s, 0.5, 'erase');
      }
      rd.line(x1 - 0.02 * s + 1, yt - 0.04 * s, x1 - 0.02 * s + 1, H, 0.8, 0.35); }

    // ---- the bulb on its chain from the ceiling, off
    { const D = 1.95, s = S(D), x = X(0.2, D), y = Y(2.5, D);
      k.line(x, 0, x, y - 0.1 * s, Math.max(0.6, 0.012 * s), 1);
      k.rect(x - 0.03 * s, y - 0.1 * s, 0.06 * s, 0.07 * s, 0.95, 'set');
      k.oval(x, y + 0.02 * s, 0.03 * s, 0.045 * s, 0.75, 'set');
      k.oval(x + 0.01 * s, y + 0.01 * s, 0.01 * s, 0.015 * s, 0.4, 'erase');
      let cy = y - 0.05 * s;
      for (let i = 0; i < 22; i++) { k.oval(x + 0.035 * s, cy, 0.005 * s, 0.008 * s, 0.9, 'set'); cy += 0.016 * s; }
      k.oval(x + 0.035 * s, cy + 1, 1, 1.3, 1, 'set'); }

    vignette(k, 0.34);
    edge(k);
  };

  // The front room of his late mother's house, VAN DUSEN HOLDINGS now, at four in the afternoon,
  // from his chair behind the desk. The big oak desk across the bottom, its near edge and the brass
  // lamp's pool on it: the adding machine, its tape up over the roll, a mug of pens, his phone face
  // down. Across the desk the wooden armchair, empty. Behind it the front door, the name in gold
  // leaf on its glass reading backwards from in here, the porch and the rain through it. On the
  // left the front window, the blinds half up, the grey day, the old bank across the street that's
  // a cafe now. On the right the bookkeeper's desk against the wall (the monitor, the ledger, her
  // mug, her chair with her cardigan over the back of it), and in the corner by the door a carton
  // open on another, a black T-shirt out of it and hung over the front, SECURITY across it in
  // white. The wallpaper's painted over above the wainscot. Later on (look.dusk) the day goes out
  // of the window and the lamp is the light.
  PLACES.office = function (j, look, rnd) {
    const k = j.k;
    const dusk = !!look.dusk;
    const t = function (day, late) { return dusk ? late : day; };
    const cam = camera(318, 68, 270, 1.2);
    const X = cam.x, Y = cam.y, S = cam.s;
    const XL = -2.4, XR = 2, CH = 2.8, DN = 1.5, DB = 3.2, WN = 0.9, sb = S(DB);
    const P = function (x, y, D) { return [X(x, D), Y(y, D)]; };
    const quad = function (Xw, y0, y1, d0, d1) { return [P(Xw, y1, d0), P(Xw, y1, d1), P(Xw, y0, d1), P(Xw, y0, d0)]; };
    const flat = function (Yh, x0, x1, d0, d1) { return [P(x0, Yh, d0), P(x1, Yh, d0), P(x1, Yh, d1), P(x0, Yh, d1)]; };
    const face = function (D, x0, x1, y0, y1) { return [P(x0, y1, D), P(x1, y1, D), P(x1, y0, D), P(x0, y0, D)]; };
    const seg = function (a, b, w, tone, mode) { k.line(a[0], a[1], b[0], b[1], w, tone, mode); };
    const clipTo = function (pts) { k.clip(function (c) { c.moveTo(pts[0][0], pts[0][1]); for (const q of pts) c.lineTo(q[0], q[1]); c.closePath(); }); };
    // a box standing in the room: its top, the face toward him, and the side toward the middle
    const box = function (x0, x1, d0, d1, y0, y1, tTop, tFront, tSide) {
      if (tSide != null) {
        if (x1 < 0) k.poly(quad(x1, y0, y1, d0, d1), tSide, 'set');
        else if (x0 > 0) k.poly(quad(x0, y0, y1, d0, d1), tSide, 'set');
      }
      if (tTop != null && y1 < cam.eye) k.poly(flat(y1, x0, x1, d0, d1), tTop, 'set');
      if (tFront != null) k.poly(face(d0, x0, x1, y0, y1), tFront, 'set');
    };
    const byDepth = function (plane, at, d0, d1, fn) { return depthTone(k, cam, plane, at, d0, d1, fn); };

    // ---- the room: the window's grey along the left wall and full on the right one; the front
    // wall, the window's own, gets only what comes back off the room
    k.rect(0, 0, W, H, t(0.56, 0.8), 'set');
    k.poly(quad(XL, 0, CH, DN, DB), byDepth('x', XL, DN, DB, function (D) { return t(0.42 + 0.14 * clamp((D - 2.3) / 0.9, 0, 1), 0.8); }), 'set');
    k.poly(quad(XR, 0, CH, DN, DB), byDepth('x', XR, DN, DB, function (D) { return t(0.28 + 0.26 * clamp((D - 1.8) / 1.4, 0, 1), 0.78); }), 'set');
    k.poly(face(DB, XL, XR, 0, CH), t(0.56, 0.8), 'set');
    if (!dusk) onWall(j, cam, XR, 2.2, 1.4, function (kk) { kk.light(0, 0, 80, 0.22, 50); });
    // the paper under the paint: its trellis standing up through it, a flower in every diamond,
    // and its seams
    const walls = [
      { pt: function (u, v) { return P(XL + u, v, DB); }, len: XR - XL },
      { pt: function (u, v) { return P(XL, v, DB - u); }, len: DB - DN },
      { pt: function (u, v) { return P(XR, v, DB - u); }, len: DB - DN }
    ];
    const sp = 0.24, hgt = CH - WN;
    for (const w of walls) {
      clipTo([w.pt(0, CH), w.pt(w.len, CH), w.pt(w.len, WN), w.pt(0, WN)]);
      for (let u = -hgt; u < w.len; u += sp) { seg(w.pt(u, WN), w.pt(u + hgt, CH), 0.8, t(0.2, 0.14)); seg(w.pt(u + hgt, WN), w.pt(u, CH), 0.8, t(0.2, 0.14)); }
      for (let b = 1; WN + b * sp / 2 < CH; b++) for (let u = (b % 2) ? 0 : sp / 2; u < w.len; u += sp) { const q = w.pt(u, WN + b * sp / 2); k.oval(q[0], q[1], 1.2, 1.2, t(0.4, 0.25), 'erase'); }
      for (let u = 0.12; u < w.len; u += 0.53) { const a = w.pt(u, CH), b = w.pt(u, WN); seg(a, b, 0.6, 0.45); seg([a[0] + 0.8, a[1]], [b[0] + 0.8, b[1]], 0.5, t(0.3, 0.12), 'erase'); }
      k.done();
    }
    // the wainscot round all three walls: its boards, the cap rail catching the light
    for (const Xw of [XL, XR]) {
      k.poly(quad(Xw, 0, WN, DN, DB), t(0.82, 0.92), 'set');
      for (let D = DN + 0.05; D < DB; D += 0.1) seg(P(Xw, WN - 0.06, D), P(Xw, 0.12, D), 0.5, 0.5);
      k.poly(quad(Xw, WN - 0.06, WN + 0.02, DN, DB), 0.95, 'set');
      seg(P(Xw, WN + 0.02, DN), P(Xw, WN + 0.02, DB), 0.9, t(0.55, 0.25), 'erase');
    }
    k.poly(face(DB, XL, XR, 0, WN), t(0.82, 0.92), 'set');
    for (let x = XL + 0.1; x < XR; x += 0.1) seg(P(x, WN - 0.06, DB), P(x, 0.12, DB), 0.5, 0.5);
    k.poly(face(DB, XL, XR, WN - 0.06, WN + 0.02), 0.95, 'set');
    seg(P(XL, WN + 0.02, DB), P(XR, WN + 0.02, DB), 0.9, t(0.5, 0.22), 'erase');

    // ---- the front window: the grey day, the old bank across the street, the blinds half up
    const WX0 = -2.1, WX1 = -0.76, WY0 = 0.86, WY1 = 2.3, BL = 1.62;
    const gx0 = X(WX0, DB), gx1 = X(WX1, DB), gy0 = Y(WY1, DB), gy1 = Y(WY0, DB), gb = Y(BL, DB), cw = 0.1 * sb;
    k.rect(gx0 - cw, gy0 - cw, gx1 - gx0 + 2 * cw, gy1 - gy0 + 2 * cw, t(0.36, 0.68), 'set');
    k.clip(function (c) { c.rect(gx0, gy0, gx1 - gx0, gy1 - gy0); });
    // out there: the sky low and wet; the bank, stone, its columns, the cafe's windows lit between
    // them; the wet street; a car at the far curb
    k.rect(gx0, gy0, gx1 - gx0, gy1 - gy0, k.lin(0, gy0, 0, gy1, [[0, t(0.04, 0.52)], [1, t(0.12, 0.62)]]), 'set');
    { const DS = 30, gY = -0.45, B0 = -18.6, B1 = -8.2;
      // next door on the right, clapboard, a shop lit along the bottom
      k.poly(face(DS + 1, B1, -4, gY, 6.2), t(0.5, 0.8), 'set');
      for (let y = gY + 0.3; y < 6.2; y += 0.3) seg(P(B1, y, DS + 1), P(-4, y, DS + 1), 0.4, 0.3);
      { const a = P(-7.6, 2.6, DS + 1), b = P(-5, 0.4, DS + 1); k.rect(a[0], a[1], b[0] - a[0], b[1] - a[1], t(0.3, 0.1), 'set'); }
      // the bank: its face, the beam over the columns, the pediment
      k.poly(face(DS, B0, B1, gY, 4.9), t(0.4, 0.74), 'set');
      k.poly(face(DS, B0 - 0.3, B1 + 0.3, 4, 4.9), t(0.22, 0.62), 'set');
      seg(P(B0 - 0.3, 4.32, DS), P(B1 + 0.3, 4.32, DS), 0.6, 0.6);
      seg(P(B0 - 0.3, 4, DS), P(B1 + 0.3, 4, DS), 0.9, 0.85);
      k.poly([P(B0 + 1.8, 4.9, DS), P(B1 - 1.8, 4.9, DS), P((B0 + B1) / 2, 6.3, DS)], t(0.3, 0.66), 'set');
      // the cafe's windows between the columns: dim in the day with a lamp in each, bright at dusk
      for (let i = 0; i < 4; i++) {
        const cx = B0 + 2.1 + i * 2.2, a = P(cx - 0.62, 3.3, DS), b = P(cx + 0.62, 0.9, DS);
        k.rect(a[0], a[1], b[0] - a[0], b[1] - a[1], t(0.62, 0.06), 'set');
        k.light((a[0] + b[0]) / 2, b[1] - 6, 6, t(0.6, 0.4), 8);
        k.line(a[0], (a[1] + b[1]) / 2 - 2, b[0], (a[1] + b[1]) / 2 - 2, 0.6, 0.75);
      }
      for (let i = 0; i < 5; i++) {
        const cx = B0 + 1 + i * 2.2, a = P(cx - 0.3, 4, DS), b = P(cx + 0.3, 0.4, DS);
        k.rect(a[0], a[1], b[0] - a[0], b[1] - a[1], t(0.08, 0.5), 'set');
        k.line(b[0] - 0.8, a[1], b[0] - 0.8, b[1], 1.2, t(0.42, 0.85));
      }
      // the steps up to it, and the street, wet, the windows lying in it
      for (let y = gY; y < 0.4; y += 0.28) { const a = P(B0 - 0.4, y + 0.28, DS), b = P(B1 + 0.4, y, DS); k.rect(a[0], a[1], b[0] - a[0], b[1] - a[1], t(0.2, 0.64), 'set'); k.line(a[0], a[1] + 0.3, b[0], a[1] + 0.3, 0.6, t(0.6, 0.25), 'erase'); }
      k.rect(gx0, Y(gY, DS), gx1 - gx0, gy1 - Y(gY, DS) + 1, t(0.44, 0.72), 'set');
      for (let i = 0; i < 4; i++) { const x = X(B0 + 2.1 + i * 2.2, DS); for (let y = Y(gY, DS) + 1; y < gy1; y += 1.4 + rnd()) k.line(x - 1.2 - rnd(), y, x + 1.2 + rnd(), y, 0.5, t(0.3, 0.75) * (0.5 + rnd() * 0.5), 'erase'); }
      // the car at the far curb, its roof and glass catching the sky
      const c0 = X(-16.4, 27), c1 = X(-12.2, 27), cy = Y(-0.4, 27), cr = Y(1.4, 27), cl = c1 - c0, ch = cy - cr;
      k.path('M' + c0 + ' ' + cy + ' L' + c0 + ' ' + (cy - ch * 0.5) + ' L' + (c0 + cl * 0.22) + ' ' + (cy - ch * 0.56) + ' L' + (c0 + cl * 0.33) + ' ' + cr + ' L' + (c0 + cl * 0.72) + ' ' + cr + ' L' + (c0 + cl * 0.83) + ' ' + (cy - ch * 0.56) + ' L' + c1 + ' ' + (cy - ch * 0.48) + ' L' + c1 + ' ' + cy + ' Z', t(0.86, 0.92), 'set');
      k.rect(c0 + cl * 0.36, cr + 1, cl * 0.33, ch * 0.34, t(0.38, 0.7), 'set');
      seg([c0 + cl * 0.33, cr + 0.4], [c0 + cl * 0.72, cr + 0.4], 0.8, t(0.65, 0.35), 'erase');
      if (dusk) { const l = P(-7.8, 5.2, 28); k.line(l[0], l[1], l[0], Y(gY, 28), 0.8, 0.9); k.light(l[0], l[1] + 8, 22, 0.45, 28); k.oval(l[0], l[1], 1.6, 1, 0, 'set'); }
      k.rain(rnd, 150, gx0, gy0, gx1 - gx0, gy1 - gy0, { tone: t(0.3, 0.25), len: 6, w: 0.5, ink: !dusk, slant: 0.05 }); }
    // rain on the glass: drops, a few of them running
    for (let i = 0; i < 60; i++) {
      const x = gx0 + rnd() * (gx1 - gx0), y = gb + rnd() * (gy1 - gb), r = 0.4 + rnd() * rnd() * 1.1;
      k.oval(x, y + r * 0.4, r, r * 1.1, 0.4);
      k.oval(x - r * 0.3, y - r * 0.2, r * 0.45, r * 0.45, 0.8, 'erase');
    }
    for (let i = 0; i < 5; i++) { const x = gx0 + 3 + rnd() * (gx1 - gx0 - 6); let d = 'M' + x + ' ' + (gb + 2 + rnd() * 10), xx = x; for (let yy = gb + 4; yy < gy1; yy += 2.5) { xx += (rnd() - 0.5) * 0.8; d += ' L' + xx + ' ' + yy; } k.stroke(d, 0.6, 0.4); k.stroke(d, 0.3, 0.6, 'erase'); }
    // the blinds, let down halfway: the slats tipped open on the street, the bottom rail, the tapes
    for (let y = WY1; y > BL + 0.03; y -= 0.045) { const yy = Y(y, DB); k.rect(gx0, yy, gx1 - gx0, 0.031 * sb, t(0.3, 0.74), 'set'); k.line(gx0, yy + 0.3, gx1, yy + 0.3, 0.5, t(0.55, 0.2), 'erase'); }
    k.rect(gx0, gb - 0.04 * sb, gx1 - gx0, 0.045 * sb, t(0.3, 0.7), 'set');
    k.line(gx0, gb - 0.04 * sb + 0.4, gx1, gb - 0.04 * sb + 0.4, 0.7, t(0.7, 0.3), 'erase');
    for (const x of [WX0 + 0.3, WX1 - 0.3]) k.line(X(x, DB), gy0, X(x, DB), gb, 0.6, 0.6);
    k.done();
    // the sash's sides, its bottom rail on the sill, the sill catching the light; the cord
    k.rect(gx0, gy0, 0.045 * sb, gy1 - gy0, t(0.3, 0.66), 'set'); k.rect(gx1 - 0.045 * sb, gy0, 0.045 * sb, gy1 - gy0, t(0.3, 0.66), 'set');
    k.rect(gx0, gy1 - 0.05 * sb, gx1 - gx0, 0.05 * sb, t(0.3, 0.66), 'set');
    k.rect(gx0 - cw * 1.3, gy1 + cw * 0.3, gx1 - gx0 + cw * 2.6, 0.05 * sb, t(0.24, 0.6), 'set');
    k.line(gx0 - cw * 1.3, gy1 + cw * 0.3 + 0.3, gx1 + cw * 1.3, gy1 + cw * 0.3 + 0.3, 1, t(0.9, 0.4), 'erase');
    for (const x of [gx0 - 0.5, gx1 + 0.5]) k.line(x, gy0, x, gy1, 0.6, 0.6);
    { const x = X(WX1 - 0.1, DB), y = Y(1.16, DB); k.line(x, gb, x, y, 0.5, 0.85); k.path('M' + (x - 1.1) + ' ' + y + ' L' + (x + 1.1) + ' ' + y + ' L' + (x + 0.7) + ' ' + (y + 3.6) + ' L' + (x - 0.7) + ' ' + (y + 3.6) + ' Z', 0.9, 'set'); }

    // ---- the front door: painted, a glass in the top half, the porch and the rain through it,
    // and the name on the glass in gold leaf the wrong way round from in here
    const DX0 = -0.3, DX1 = 0.6, DH = 2.05;
    k.poly(face(DB, DX0 - 0.1, DX1 + 0.1, 0, DH + 0.1), t(0.34, 0.66), 'set');
    k.poly(face(DB, DX0, DX1, 0, DH), t(0.4, 0.7), 'set');
    seg(P(DX1, DH, DB), P(DX1, 0, DB), 1.4, 0.75);
    seg(P(DX0, DH, DB), P(DX0, 0, DB), 0.9, t(0.6, 0.3), 'erase');
    // the two panels under the glass: lit along the top and the left, dark along the others
    for (const p of [[DX0 + 0.1, DX0 + 0.42], [DX0 + 0.48, DX1 - 0.1]]) {
      const q = face(DB, p[0], p[1], 0.14, 0.8);
      k.poly(q, t(0.46, 0.74), 'set');
      seg(q[0], q[1], 0.8, t(0.5, 0.2), 'erase'); seg(q[0], q[3], 0.8, t(0.5, 0.2), 'erase');
      seg(q[1], q[2], 0.8, 0.6); seg(q[3], q[2], 0.8, 0.6);
    }
    const GX0 = DX0 + 0.12, GX1 = DX1 - 0.12, GY0 = 0.9, GY1 = 1.92;
    const dg0 = X(GX0, DB), dg1 = X(GX1, DB), dgt = Y(GY1, DB), dgb = Y(GY0, DB);
    k.clip(function (c) { c.rect(dg0, dgt, dg1 - dg0, dgb - dgt); });
    // through it: a house across the street, the wet road, the porch rail and its post, the drips
    // off the porch roof; at dusk the porch light on
    k.rect(dg0, dgt, dg1 - dg0, dgb - dgt, t(0.14, 0.6), 'set');
    { const DS = 24;
      k.poly(face(DS, -1.4, 6, -0.45, 5.4), t(0.38, 0.76), 'set');
      for (const wx of [-0.6, 1.2, 3]) { const a = P(wx, 4.4, DS); k.rect(a[0], a[1], 1 * S(DS), 1.2 * S(DS), t(0.62, 0.3), 'set'); const b = P(wx, 2.1, DS); k.rect(b[0], b[1], 1 * S(DS), 1.4 * S(DS), t(0.6, dusk ? 0.2 : 0.5), 'set'); }
      k.rect(dg0, Y(-0.45, DS), dg1 - dg0, dgb - Y(-0.45, DS), t(0.42, 0.74), 'set');
      seg([dg0, Y(-0.45, DS) + 0.4], [dg1, Y(-0.45, DS) + 0.4], 0.6, t(0.4, 0.3), 'erase'); }
    { const DP = 4.5, s = S(DP);
      for (let x = X(-0.28, DP); x < dg1; x += 0.13 * s) k.rect(x, Y(0.87, DP), 0.04 * s, dgb - Y(0.87, DP), t(0.3, 0.55), 'set');
      k.rect(dg0, Y(0.94, DP), dg1 - dg0, 0.07 * s, t(0.26, 0.5), 'set');
      seg([dg0, Y(0.87, DP)], [dg1, Y(0.87, DP)], 0.8, t(0.7, 0.85));
      const px = X(0.36, DP); k.rect(px, dgt, 0.12 * s, Y(0.94, DP) - dgt, t(0.24, 0.5), 'set');
      k.rect(px + 0.08 * s, dgt, 0.04 * s, Y(0.94, DP) - dgt, t(0.55, 0.75), 'set');
      if (dusk) k.light(X(-0.05, DP), dgt + 6, 40, 0.75, 34); }
    for (let x = dg0 + 1.5 + rnd() * 2; x < dg1; x += 2.5 + rnd() * 3) { let y = dgt; while (y < dgb) { const l = 2 + rnd() * 5; k.line(x, y, x, y + l, 0.5, t(0.5, 0.45), dusk ? 'erase' : 'ink'); y += l + 1 + rnd() * 3; } }
    k.done();
    // the name, gilded on the outside: from in here the backs of the letters, an arch and a line
    // under it, all of it backwards
    { const cx = (dg0 + dg1) / 2, top = dgt + 13, R = 52, da = 0.098, word = 'VAN DUSEN', n = word.length;
      k.c.save(); k.c.translate(2 * cx, 0); k.c.scale(-1, 1);
      for (let i = 0; i < n; i++) {
        const a = (i - (n - 1) / 2) * da;
        k.c.save(); k.c.translate(cx + Math.sin(a) * R, top + R - Math.cos(a) * R); k.c.rotate(a);
        k.text(word[i], 0, 0, 10, 1);
        k.c.restore();
      }
      k.text('HOLDINGS', cx, top + 10.5, 6.6, 1, { spacing: 0.6 });
      k.line(cx - 15, top + 13, cx + 15, top + 13, 0.7, 1);
      k.c.restore(); }
    k.stroke('M' + dg0 + ' ' + dgt + ' L' + dg1 + ' ' + dgt + ' L' + dg1 + ' ' + dgb + ' L' + dg0 + ' ' + dgb + ' Z', 1.6, t(0.6, 0.8));
    { const q = P(DX1 - 0.08, 0.98, DB); k.oval(q[0], q[1], 2, 2, 0.75, 'set'); k.oval(q[0] - 0.6, q[1] - 0.6, 0.8, 0.8, 0.8, 'erase'); }

    // ---- in the corner by the door, a carton open on another, a black T-shirt out of it and hung
    // over the front, SECURITY across it in white
    box(0.86, 1.46, 2.72, 3.14, 0, 0.42, t(0.3, 0.62), t(0.46, 0.74), t(0.36, 0.66));
    box(0.89, 1.43, 2.75, 3.11, 0.42, 0.8, null, t(0.44, 0.72), t(0.34, 0.64));
    k.poly(flat(0.8, 0.89, 1.43, 2.75, 3.11), 0.92, 'set');
    // the flaps standing up at the back and the sides
    k.poly([P(0.89, 0.8, 3.11), P(1.43, 0.8, 3.11), P(1.45, 1.06, 3.16), P(0.87, 1.06, 3.16)], t(0.36, 0.66), 'set');
    k.poly([P(0.89, 0.8, 2.75), P(0.89, 0.8, 3.11), P(0.72, 1.04, 3.09), P(0.72, 1.02, 2.77)], t(0.26, 0.6), 'set');
    k.poly([P(1.43, 0.8, 2.75), P(1.43, 0.8, 3.11), P(1.6, 1.02, 3.09), P(1.6, 1.0, 2.77)], t(0.5, 0.74), 'set');
    seg(P(0.89, 0.8, 2.75), P(0.72, 1.02, 2.77), 0.6, t(0.6, 0.3), 'erase');
    { const D = 2.74, s = S(D), cx = X(1.16, D), yt = Y(0.81, D), w = 0.25 * s;
      const shirt = 'M' + (cx - 0.075 * s) + ' ' + yt + ' Q' + cx + ' ' + (yt + 0.07 * s) + ' ' + (cx + 0.075 * s) + ' ' + yt +
        ' L' + (cx + w) + ' ' + (yt + 0.02 * s) + ' L' + (cx + w + 0.06 * s) + ' ' + (yt + 0.15 * s) + ' L' + (cx + w - 0.01 * s) + ' ' + (yt + 0.18 * s) +
        ' L' + (cx + w - 0.03 * s) + ' ' + (yt + 0.13 * s) + ' L' + (cx + w - 0.025 * s) + ' ' + (yt + 0.34 * s) + ' L' + (cx - w + 0.025 * s) + ' ' + (yt + 0.34 * s) +
        ' L' + (cx - w + 0.03 * s) + ' ' + (yt + 0.13 * s) + ' L' + (cx - w + 0.01 * s) + ' ' + (yt + 0.18 * s) + ' L' + (cx - w - 0.06 * s) + ' ' + (yt + 0.15 * s) + ' L' + (cx - w) + ' ' + (yt + 0.02 * s) + ' Z';
      k.path(shirt, 0.95, 'set');
      k.stroke('M' + (cx - 0.075 * s) + ' ' + (yt + 0.6) + ' Q' + cx + ' ' + (yt + 0.07 * s + 0.6) + ' ' + (cx + 0.075 * s) + ' ' + (yt + 0.6), 0.8, t(0.45, 0.3), 'erase');
      k.text('SECURITY', cx, yt + 0.16 * s, 0.075 * s, 1, { mode: 'erase', spacing: 0.3, max: 1.5 * w });
      for (const f of [[-0.6, 0.2], [0.35, 0.24], [0.75, 0.28]]) k.line(cx + f[0] * w, yt + 0.22 * s, cx + f[0] * w + 1, yt + 0.33 * s, 0.5, t(0.35, 0.2), 'erase'); }

    // ---- the armchair across the desk, wood, empty: the crest rail, the spindles, the arms
    { const A0 = -0.26, A1 = 0.34, AD0 = 2.22, AD1 = 2.62, AS = 0.46, AA = 0.66, AB = 0.94, ink = t(0.92, 0.96), lit = t(0.55, 0.25);
      for (const x of [A0 + 0.03, A1 - 0.03]) seg(P(x, AB, AD1), P(x, AS - 0.4, AD1), Math.max(1.4, 0.04 * S(AD1)), ink);
      for (let i = 1; i < 7; i++) {
        const x = A0 + 0.03 + (A1 - A0 - 0.06) * i / 7;
        seg(P(x, AB - 0.04, AD1 - 0.01), P(x, AS, AD1 - 0.01), Math.max(0.9, 0.02 * S(AD1)), ink);
        seg([X(x, AD1 - 0.01) - 0.5, Y(AB - 0.06, AD1)], [X(x, AD1 - 0.01) - 0.5, Y(AS + 0.04, AD1)], 0.4, lit * 0.5, 'erase');
      }
      const c0 = P(A0 - 0.04, AB, AD1), c1 = P(A1 + 0.04, AB, AD1), cm = P((A0 + A1) / 2, AB + 0.02, AD1 + 0.08), th = 0.075 * S(AD1);
      k.path('M' + c0[0] + ' ' + c0[1] + ' Q' + cm[0] + ' ' + (cm[1] - 3) + ' ' + c1[0] + ' ' + c1[1] + ' L' + c1[0] + ' ' + (c1[1] + th) + ' Q' + cm[0] + ' ' + (cm[1] - 3 + th) + ' ' + c0[0] + ' ' + (c0[1] + th) + ' Z', ink, 'set');
      k.stroke('M' + c0[0] + ' ' + (c0[1] + 0.5) + ' Q' + cm[0] + ' ' + (cm[1] - 2.5) + ' ' + (cm[0] + 6) + ' ' + (cm[1] - 2.7), 0.9, lit, 'erase');
      // the arms out to the front, their posts down to the seat
      for (const x of [A0, A1]) {
        seg(P(x, AA, AD1 - 0.03), P(x, AA, AD0 + 0.02), Math.max(1.8, 0.05 * S(AD0)), ink);
        seg(P(x, AA, AD0 + 0.06), P(x, AS - 0.4, AD0 + 0.06), Math.max(1.3, 0.035 * S(AD0)), ink);
      }
      seg([X(A0, AD1 - 0.03), Y(AA, AD1 - 0.03) - 0.6], [X(A0, AD0 + 0.02), Y(AA, AD0 + 0.02) - 0.6], 0.7, lit, 'erase');
      seg([X(A1, AD1 - 0.03), Y(AA, AD1 - 0.03) - 0.6], [X(A1, AD0 + 0.02), Y(AA, AD0 + 0.02) - 0.6], 0.6, lit * 0.6, 'erase'); }

    // ---- the bookkeeper's desk against the right wall: the monitor, the ledger open, her mug; her
    // chair pulled out, her cardigan over the back of it
    const BX0 = 1.32, BD0 = 1.1, BD1 = 2.45, BT = 0.74;
    k.poly(quad(BX0, 0.04, BT - 0.03, BD0, BD1), t(0.66, 0.86), 'set');
    { const q = quad(BX0, 0.12, BT - 0.1, BD0 + 0.12, BD1 - 0.08); k.stroke('M' + q[0][0] + ' ' + q[0][1] + ' L' + q[1][0] + ' ' + q[1][1] + ' L' + q[2][0] + ' ' + q[2][1], 0.7, 0.85); k.stroke('M' + q[2][0] + ' ' + q[2][1] + ' L' + q[3][0] + ' ' + q[3][1], 0.7, t(0.4, 0.2), 'erase'); }
    k.poly(quad(BX0, BT - 0.03, BT, BD0, BD1), t(0.3, 0.62), 'set');
    k.poly(flat(BT, BX0, XR, BD0, BD1), t(0.54, 0.78), 'set');
    seg(P(BX0, BT, BD0), P(BX0, BT, BD1), 0.8, t(0.6, 0.3), 'erase');
    // the monitor, side-on to him, her spreadsheet up on it
    { const MX = 1.74, M0 = 1.78, M1 = 2.18, MY0 = 0.88, MY1 = 1.16;
      if (dusk) { onWall(j, cam, XR, 2, 1.0, function (kk) { kk.light(0, 0, 70, 0.3, 50); }); k.light(X(1.6, 1.98), Y(BT, 1.98), 40, 0.3, 12); }
      k.poly(flat(BT + 0.004, MX + 0.02, MX + 0.18, 1.9, 2.06), 0.9, 'set');
      seg(P(MX + 0.08, BT, 1.98), P(MX + 0.08, MY0, 1.98), Math.max(1, 0.035 * S(1.98)), 0.92);
      k.poly(quad(MX + 0.02, MY0 - 0.015, MY1 + 0.015, M0 - 0.015, M1 + 0.015), 0.96, 'set');
      k.poly(quad(MX, MY0 - 0.015, MY1 + 0.015, M0 - 0.015, M1 + 0.015), 0.92, 'set');
      const sq = quad(MX - 0.001, MY0, MY1, M0, M1);
      k.poly(sq, t(0.12, 0.04), 'set');
      for (let y = MY0 + 0.03; y < MY1 - 0.02; y += 0.022) seg(P(MX - 0.002, y, M0 + 0.015), P(MX - 0.002, y, M1 - 0.015), 0.4, 0.4);
      for (const dd of [0.1, 0.2, 0.3]) seg(P(MX - 0.002, MY1 - 0.03, M0 + dd), P(MX - 0.002, MY0 + 0.015, M0 + dd), 0.4, 0.4);
      k.poly(quad(MX - 0.002, MY1 - 0.035, MY1 - 0.012, M0 + 0.012, M1 - 0.012), 0.55, 'set'); }
    // the ledger open in front of her place, ruled; her mug behind it
    { const p = flat(BT + 0.005, 1.4, 1.7, 1.48, 1.76);
      k.poly(p, t(0.06, 0.3), 'set');
      for (let D = 1.5; D < 1.75; D += 0.024) seg(P(1.41, BT + 0.006, D), P(1.69, BT + 0.006, D), 0.4, 0.35);
      for (const x of [1.47, 1.52, 1.62, 1.66]) seg(P(x, BT + 0.006, 1.49), P(x, BT + 0.006, 1.75), 0.4, 0.3);
      seg(P(1.55, BT + 0.006, 1.48), P(1.55, BT + 0.006, 1.76), 1, 0.7);
      const m = P(1.46, BT, 2.02), ms = S(2.02);
      k.rect(m[0] - 0.04 * ms, m[1] - 0.095 * ms, 0.08 * ms, 0.095 * ms, k.lin(m[0] - 0.04 * ms, 0, m[0] + 0.04 * ms, 0, [[0, t(0.55, 0.7)], [1, 0.92]]), 'set');
      k.oval(m[0], m[1] - 0.095 * ms, 0.04 * ms, 0.01 * ms, 0.85, 'set');
      k.stroke('M' + (m[0] - 0.04 * ms) + ' ' + (m[1] - 0.075 * ms) + ' q ' + (-0.035 * ms) + ' ' + (0.02 * ms) + ' 0 ' + (0.055 * ms), Math.max(0.7, 0.012 * ms), t(0.6, 0.8)); }
    // her chair, its back to the room, the cardigan hung over it by the shoulders: the knit, the
    // button band, the sleeves down
    { const CX = 1.0, C0 = 1.47, C1 = 1.81, top = 0.94, CM = (C0 + C1) / 2, s = S(CM);
      for (const d of [C0 + 0.02, C1 - 0.02]) seg(P(CX, top, d), P(CX, 0.3, d), Math.max(1.2, 0.028 * S(d)), 0.94);
      k.poly(quad(CX, top - 0.04, top, C0 - 0.02, C1 + 0.02), 0.94, 'set');
      const cg = [P(CX - 0.035, top + 0.025, C0 + 0.02), P(CX - 0.035, top + 0.025, C1 - 0.02), P(CX - 0.045, 0.5, C1 - 0.03), P(CX - 0.045, 0.5, C0 + 0.03)];
      k.poly(cg, t(0.3, 0.62), 'set');
      clipTo(cg);
      for (let d = C0; d < C1; d += 0.016) seg(P(CX - 0.035, top + 0.03, d), P(CX - 0.045, 0.5, d), 0.5, 0.35);
      k.light(cg[1][0] + 3, cg[1][1] + 6, 16, t(0.25, 0.05));
      k.done();
      seg(cg[0], cg[1], 1, t(0.6, 0.25), 'erase');
      // the V of the neck, the band down the front and its buttons
      const nk = P(CX - 0.04, top - 0.11, CM);
      k.poly([P(CX - 0.035, top + 0.025, CM - 0.06), P(CX - 0.035, top + 0.025, CM + 0.06), nk], 0.9, 'set');
      seg(P(CX - 0.035, top + 0.025, CM - 0.06), nk, 1.4, t(0.1, 0.45)); seg(P(CX - 0.035, top + 0.025, CM + 0.06), nk, 1.4, t(0.1, 0.45));
      seg(nk, P(CX - 0.045, 0.5, CM), 2.2, t(0.1, 0.45));
      for (let y = top - 0.14; y > 0.55; y -= 0.07) { const q = P(CX - 0.045, y, CM); k.oval(q[0], q[1], 1, 1, 0.95, 'set'); }
      // the sleeves down either side, the near one longer
      for (const sl of [[C0 + 0.015, 0.46, 1], [C1 - 0.015, 0.6, -1]]) {
        const a = P(CX - 0.04, top + 0.01, sl[0]), b = P(CX - 0.045, sl[1], sl[0] + sl[2] * 0.01);
        k.line(a[0], a[1], b[0], b[1], 0.065 * s, t(0.44, 0.7));
        k.line(a[0] + sl[2] * 0.033 * s, a[1] + 3, b[0] + sl[2] * 0.033 * s, b[1], 0.6, 0.6);
      } }

    // ---- his desk: oak, the window's sheen on the far side of it and the lamp's pool on this
    // end, the near edge across the bottom
    const DX = 0.95, DD0 = 0.82, DD1 = 1.55, DT = 0.76;
    const top = flat(DT, -DX, DX, DD0, DD1);
    k.poly(top, t(0.72, 0.84), 'set');
    clipTo(top);
    for (let D = DD0 + 0.01; D < DD1; D += 0.012 + rnd() * 0.024) { const y = Y(DT, D); k.line(0, y + (rnd() - 0.5) * 0.6, W, y + (rnd() - 0.5) * 0.6, 0.5, 0.14 + rnd() * 0.2, rnd() < 0.5 ? 'ink' : 'erase'); }
    for (const D of [1.0, 1.28]) k.line(0, Y(DT, D), W, Y(DT, D), 0.5, 0.45);
    k.light((gx0 + gx1) / 2, Y(DT, 1.4), 60, t(0.3, 0.06), 20);
    k.light(X(-0.92, 1.15), Y(DT, 1.12), 200, t(0.55, 0.74), 52);
    k.light(X(-0.92, 1.15), Y(DT, 1.1), 85, t(0.4, 0.55), 22);
    k.done();
    seg(top[3], top[2], 1, t(0.6, 0.4), 'erase');
    k.rect(0, Y(DT, DD0), W, H - Y(DT, DD0), 0.97, 'set');
    k.line(0, Y(DT, DD0) + 0.5, W, Y(DT, DD0) + 0.5, 1.2, t(0.5, 0.55), 'erase');
    k.light(X(-0.92, 1.15), Y(DT, DD0) + 1, 100, t(0.4, 0.6), 3);

    // his phone, face down, the camera's corner up
    { const p = flat(DT + 0.008, 0.08, 0.155, 0.95, 1.1);
      k.poly(p, 0.95, 'set');
      seg([p[0][0], p[0][1] + 0.3], [p[1][0], p[1][1] + 0.3], 0.6, t(0.45, 0.3), 'erase');
      seg([p[0][0] + 0.4, p[0][1]], [p[3][0] + 0.4, p[3][1]], 0.6, t(0.4, 0.25), 'erase');
      const cq = flat(DT + 0.009, 0.09, 0.12, 1.06, 1.09); k.poly(cq, 0.7, 'set');
      k.oval((cq[0][0] + cq[1][0]) / 2, (cq[0][1] + cq[2][1]) / 2, 1.5, 1, 0.95, 'set'); }
    // the mug of pens
    { const D = 1.42, m = P(-0.68, DT, D), s = S(D), r = 0.042 * s, h = 0.1 * s, x = m[0], y = m[1];
      for (const p of [[-0.6, 0.13, -0.02], [-0.2, 0.15, 0.01], [0.3, 0.12, 0.03], [0.65, 0.14, 0.05], [0.05, 0.11, -0.04]]) {
        const bx = x + p[0] * r, tx = bx + p[2] * s * 1.2, ty = y - h - p[1] * s;
        k.line(bx, y - h + 1, tx, ty, Math.max(0.9, 0.009 * s), 0.92);
        k.line(tx, ty, tx + (tx - bx) * 0.12, ty - 0.02 * s, Math.max(1.1, 0.012 * s), 0.95);
      }
      k.rect(x - r, y - h, 2 * r, h, k.lin(x - r, 0, x + r, 0, [[0, t(0.1, 0.25)], [0.6, t(0.28, 0.45)], [1, t(0.5, 0.6)]]), 'set');
      k.oval(x, y - h, r, r * 0.25, 0.85, 'set');
      k.stroke(ell(x, y - h, r, r * 0.25, true), 0.6, t(0.2, 0.4));
      k.stroke('M' + (x + r) + ' ' + (y - h * 0.8) + ' q ' + (0.035 * s) + ' ' + (0.02 * s) + ' 0 ' + (0.06 * s), Math.max(0.8, 0.012 * s), t(0.35, 0.5)); }
    // the adding machine in the lamp's light: beige, its keys dark on the slope, the head at the
    // back with the roll up behind it, the tape up out of it; a length torn off lying in front
    { const M0 = -0.46, M1 = -0.18, MD0 = 1.06, MD1 = 1.32, MH = 1.22, MX = (M0 + M1) / 2;
      { const p = [P(-0.5, DT + 0.002, 0.97), P(-0.33, DT + 0.002, 0.95), P(-0.3, DT + 0.002, 0.995), P(-0.47, DT + 0.002, 1.015)];
        k.poly(p, t(0.02, 0.1), 'set');
        k.stroke('M' + p[1][0] + ' ' + p[1][1] + ' C' + (p[1][0] + 7) + ' ' + (p[1][1] - 9) + ' ' + (p[2][0] + 9) + ' ' + (p[2][1] + 1) + ' ' + p[2][0] + ' ' + p[2][1], 1.2, t(0.08, 0.2), 'erase');
        for (let i = 1; i < 6; i++) { const u = i / 6, x = p[0][0] + (p[1][0] - p[0][0]) * u, y = p[0][1] + (p[1][1] - p[0][1]) * u; k.line(x + 0.5, y + 1.5, x + 2.5, y + 4.5, 0.5, 0.5); } }
      box(M0, M1, MD0, MD1, DT, DT + 0.045, null, t(0.38, 0.56), t(0.26, 0.46));
      const kt = [P(M0, DT + 0.045, MD0), P(M1, DT + 0.045, MD0), P(M1, DT + 0.1, MH), P(M0, DT + 0.1, MH)];
      k.poly(kt, t(0.26, 0.46), 'set');
      seg([kt[0][0], kt[0][1] + 0.3], [kt[1][0], kt[1][1] + 0.3], 0.8, 0.6, 'erase');
      for (let r = 0; r < 4; r++) for (let c = 0; c < 4; c++) {
        const u = (c + 0.6) / 5.2, v = (r + 0.6) / 4.4, D = MD0 + 0.015 + v * (MH - MD0 - 0.03), q = P(M0 + 0.02 + u * (M1 - M0 - 0.04), DT + 0.045 + 0.055 * (D - MD0) / (MH - MD0), D);
        k.oval(q[0], q[1] - 0.6, 0.014 * S(D), 0.009 * S(D), 0.95, 'set');
        k.oval(q[0] - 0.3, q[1] - 1, 0.007 * S(D), 0.003 * S(D), 0.5, 'erase');
      }
      k.poly([P(M1 - 0.06, DT + 0.055, MD0 + 0.03), P(M1 - 0.02, DT + 0.055, MD0 + 0.03), P(M1 - 0.02, DT + 0.095, MH - 0.03), P(M1 - 0.06, DT + 0.095, MH - 0.03)], 0.95, 'set');
      box(M0 + 0.015, M1 - 0.015, MH, MD1, DT + 0.045, DT + 0.13, t(0.5, 0.64), t(0.62, 0.74), t(0.5, 0.64));
      // the roll on its arms, white, wider than the tape, its end toward him with the core in it
      const rc = P(MX, DT + 0.2, MD1 - 0.02), rs = S(MD1), rw = 0.055 * rs, rr = 0.034 * rs;
      for (const e of [-1, 1]) k.line(rc[0] + e * rw * 1.08, rc[1], rc[0] + e * rw * 1.08, Y(DT + 0.13, MD1 - 0.02), 0.9, 0.9);
      k.rect(rc[0] - rw, rc[1] - rr, 2 * rw, 2 * rr, k.lin(0, rc[1] - rr, 0, rc[1] + rr, [[0, 0.04], [0.55, t(0.14, 0.3)], [1, t(0.45, 0.6)]]), 'set');
      k.stroke('M' + (rc[0] - rw) + ' ' + (rc[1] - rr) + ' L' + (rc[0] + rw) + ' ' + (rc[1] - rr) + ' M' + (rc[0] - rw) + ' ' + (rc[1] + rr) + ' L' + (rc[0] + rw) + ' ' + (rc[1] + rr), 0.5, 0.6);
      k.oval(rc[0] + rw, rc[1], rr * 0.4, rr, t(0.12, 0.3), 'set');
      k.stroke(ell(rc[0] + rw, rc[1], rr * 0.4, rr), 0.5, 0.6);
      k.oval(rc[0] + rw, rc[1], rr * 0.15, rr * 0.34, 0.9, 'set');
      // the tape up out of the head in front of the roll, narrower, its end curled back over it
      const tx = X(MX, MH + 0.01), ty = Y(DT + 0.13, MH + 0.01), tw = 0.026 * S(MH), tt = rc[1] - rr * 0.6;
      const tape = 'M' + (tx - tw) + ' ' + ty + ' L' + (tx - tw) + ' ' + tt + ' Q' + tx + ' ' + (tt - 4.5) + ' ' + (tx + tw) + ' ' + tt + ' L' + (tx + tw) + ' ' + ty + ' Z';
      k.path(tape, 0.02, 'set');
      k.path('M' + (tx - tw) + ' ' + tt + ' Q' + tx + ' ' + (tt - 4.5) + ' ' + (tx + tw) + ' ' + tt + ' Q' + tx + ' ' + (tt - 1.5) + ' ' + (tx - tw) + ' ' + tt + ' Z', 0.45, 'set');
      k.stroke(tape, 0.5, 0.6);
      for (let i = 1; i < 5; i++) k.line(tx - tw * 0.6, ty - i * (ty - tt) / 5.2, tx + tw * (0.5 - (i % 3) * 0.3), ty - i * (ty - tt) / 5.2, 0.5, 0.6); }

    // ---- the brass lamp at his end of the desk: the turned column catching the light, the shade
    // lit through, its pool on the desk and its glow up the wall
    { const LX = -0.92, LD = 1.15, s = S(LD), x = X(LX, LD), yb = Y(DT, LD), y1 = Y(1.0, LD), y0 = Y(1.25, LD), rb = 0.155 * s, rt = 0.1 * s;
      k.light(x, y0 + 4, 70, t(0.3, 0.55), 52);
      // the base, stepped, and the column up out of it, an urn and a neck
      k.oval(x, yb, 0.08 * s, 0.022 * s, 0.92, 'set');
      const prof = [[0.075, 0], [0.07, 0.012], [0.045, 0.018], [0.04, 0.03], [0.016, 0.04], [0.012, 0.07], [0.034, 0.11], [0.04, 0.15], [0.028, 0.19], [0.01, 0.21], [0.01, 0.235], [0.018, 0.245], [0.008, 0.25]];
      let d = 'M' + (x - prof[0][0] * s) + ' ' + yb;
      for (const q of prof) d += ' L' + (x - q[0] * s) + ' ' + (yb - q[1] * s);
      for (let i = prof.length - 1; i >= 0; i--) d += ' L' + (x + prof[i][0] * s) + ' ' + (yb - prof[i][1] * s);
      k.path(d + ' Z', k.lin(x - 0.075 * s, 0, x + 0.075 * s, 0, [[0, t(0.75, 0.8)], [0.3, t(0.2, 0.15)], [0.45, t(0.5, 0.45)], [0.8, 0.88], [1, 0.95]]), 'set');
      for (const q of [[0.045, 0.018], [0.016, 0.04], [0.04, 0.15], [0.01, 0.21]]) k.line(x - q[0] * s, yb - q[1] * s, x + q[0] * s, yb - q[1] * s, 0.6, 0.85);
      // the shade, pleated, lit through, the trim at its edges
      const shade = 'M' + (x - rt) + ' ' + y0 + ' Q' + x + ' ' + (y0 + 0.012 * s) + ' ' + (x + rt) + ' ' + y0 + ' L' + (x + rb) + ' ' + y1 + ' Q' + x + ' ' + (y1 + 0.04 * s) + ' ' + (x - rb) + ' ' + y1 + ' Z';
      k.path(shade, k.lin(0, y0, 0, y1, [[0, t(0.34, 0.2)], [0.75, t(0.14, 0.04)], [1, t(0.06, 0)]]), 'set');
      k.path(shade, k.lin(x - rb, 0, x + rb, 0, [[0, t(0.3, 0.25)], [0.25, 0], [0.7, 0.04], [1, t(0.4, 0.35)]]));
      for (let i = 1; i < 14; i++) { const u = i / 14; k.line(x - rt + 2 * rt * u, y0 + 0.5, x - rb + 2 * rb * u, y1 + 0.03 * s * Math.sin(u * Math.PI) - 0.5, 0.45, 0.2); }
      k.stroke('M' + (x - rb) + ' ' + y1 + ' Q' + x + ' ' + (y1 + 0.04 * s) + ' ' + (x + rb) + ' ' + y1, 1.4, 0.75);
      k.stroke('M' + (x - rt) + ' ' + y0 + ' Q' + x + ' ' + (y0 + 0.012 * s) + ' ' + (x + rt) + ' ' + y0, 1.1, 0.7);
      k.oval(x, y0 - 0.012 * s, 0.01 * s, 0.012 * s, 0.85, 'set'); }

    vignette(k, t(0.36, 0.42));
    edge(k);
  };

  // Out on the old main street at twenty to five, the light going and a drizzle in it: from the
  // sidewalk near the top, looking down the hill to the highway and the harbour. The asphalt wet,
  // the lamps and the lit windows lying in it, the power poles down the far side and the lines
  // between them. Over there, from the top: the old bank with its columns (a cafe now), two shops,
  // the library, brick, its big window lit, and the Legion, a long low hall with a field gun on a
  // plinth on the grass in front, and over its roof the white wooden steeple of the church across
  // the highway. On this side old houses going down the hill, a window lit in the nearest. Out
  // past the highway the government wharf on its pilings, a light at the end of it and a man in a
  // flat cap at the rail, a few fish boats tied up, then the strait, grey, and the far shore lost
  // in the cloud. After six (look.night) it's dark and the lights are all there is.
  PLACES.street = function (j, look, rnd) {
    const k = j.k;
    const night = !!look.night;
    const t = function (dusk, late) { return night ? late : dusk; };
    const cam = camera(300, 60, 760, 1.65), hz = cam.hz;
    // u metres down the street from him, v across it toward the far side, h up from where he
    // stands. The street runs off a little to the right of where he's looking and falls G to the
    // metre to the highway at UH; past it at UF the sea's four metres down, the tide in
    const sn = Math.sin(0.3), cs = Math.cos(0.3), G = 0.11, UH = 94, UF = 106, HW = -G * UH, SEA = HW - 4.2, WH = HW - 1.2;
    const VN = -4, VC0 = 0.6, VC1 = 20.6, VF = 24;
    const gnd = function (u) { return -G * Math.min(u, UH); };
    const dOf = function (u, v) { return u * cs + v * sn; };
    const P = function (u, v, h) { const D = dOf(u, v); return [cam.x(u * sn - v * cs, D), cam.y(h, D)]; };
    const S = function (u, v) { return cam.s(dOf(u, v)); };
    const q = function (pts, tone, mode) { k.poly(pts, tone, mode || 'set'); };
    const seg = function (a, b, w, tone, mode) { k.line(a[0], a[1], b[0], b[1], w, tone, mode); };
    // a patch on a face along the street (at v), or on one across it (at u)
    const onV = function (v, ua, ub, ha, hb, tone, mode) { q([P(ua, v, hb), P(ub, v, hb), P(ub, v, ha), P(ua, v, ha)], tone, mode); };
    const onU = function (u, va, vb, ha, hb, tone, mode) { q([P(u, va, hb), P(u, vb, hb), P(u, vb, ha), P(u, va, ha)], tone, mode); };
    // a building on the hill, u0 to u1 down the street and v0 (its face on the street) to v1 back,
    // its top at h: the face, the end that looks up the hill, and the roof once it's below him
    const block = function (u0, u1, v0, v1, h, tFace, tEnd, tRoof) {
      if (h < cam.eye) q([P(u0, v0, h), P(u1, v0, h), P(u1, v1, h), P(u0, v1, h)], tRoof);
      q([P(u0, v0, h), P(u0, v1, h), P(u0, v1, gnd(u0)), P(u0, v0, gnd(u0))], tEnd);
      q([P(u0, v0, h), P(u1, v0, h), P(u1, v0, gnd(u1)), P(u0, v0, gnd(u0))], tFace);
      seg(P(u0, v0, h), P(u1, v0, h), 0.7, t(0.4, 0.2), 'erase');
    };
    // where a light lies in the wet: a broken streak down the road toward him from under it
    const wet = [];
    const shine = function (u, v, h, w, a) { const m = P(u, v, 2 * gnd(u) - h); wet.push([m[0], m[1], w, a]); };

    // ---- the sky: low cloud, and the last of the light in under it over the strait
    k.rect(0, 0, W, hz + 1, k.lin(0, 0, 0, hz, [[0, t(0.8, 0.97)], [0.5, t(0.66, 0.95)], [1, t(0.38, 0.88)]]), 'set');
    for (let i = 0; i < 9; i++) k.glow(rnd() * W, 4 + rnd() * (hz - 26), 60 + rnd() * 90, t(0.16, 0.05), 5 + rnd() * 5);
    k.light(W * 0.62, hz - 2, 300, t(0.3, 0.05), 11);
    // the far shore, low across the strait, most of it lost in the cloud
    { let d = 'M0 ' + (hz + 0.5);
      for (let x = 0; x <= W; x += 12) d += ' L' + x + ' ' + (hz - 2 - 3.5 * Math.abs(Math.sin(x * 0.012 + 1.3)) - 2 * Math.sin(x * 0.041) - rnd());
      k.path(d + ' L' + W + ' ' + (hz + 0.5) + ' Z', t(0.72, 0.94), 'set');
      for (let i = 0; i < 5; i++) k.light(rnd() * W, hz - 5, 50 + rnd() * 70, t(0.32, 0.08), 6); }
    // ---- the strait, grey, the swell catching what light there is
    k.rect(0, hz, W, H - hz, k.lin(0, hz, 0, hz + 90, [[0, t(0.52, 0.9)], [1, t(0.6, 0.93)]]), 'set');
    for (let i = 0; i < 170; i++) { const y = hz + 1 + Math.pow(rnd(), 1.5) * 85, x = rnd() * W, l = 3 + rnd() * 12 * (y - hz + 6) / 40; k.line(x, y, x + l, y, 0.6, t(0.34, 0.16) * (0.4 + rnd() * 0.6), 'erase'); }

    // ---- the church across the highway: white board, only its steeple over the Legion's roof;
    // the tower, the belfry with its louvres dark, the spire and a cross
    { const cu = 112, cv = 38, b = HW, tw = 1.15, s = S(cu, cv);
      onU(cu, cv - tw, cv + tw, b, b + 10.5, t(0.16, 0.7));
      onV(cv - tw, cu, cu + 2 * tw, b, b + 10.5, t(0.38, 0.84));
      onU(cu, cv - tw - 0.15, cv + tw + 0.15, b + 10.4, b + 10.8, t(0.3, 0.78));
      onU(cu, cv - tw + 0.4, cv + tw - 0.4, b + 11.1, b + 12.4, t(0.86, 0.95));
      onU(cu, cv - tw, cv - tw + 0.4, b + 10.8, b + 12.8, t(0.16, 0.7)); onU(cu, cv + tw - 0.4, cv + tw, b + 10.8, b + 12.8, t(0.16, 0.7));
      onV(cv - tw, cu, cu + 2 * tw, b + 10.8, b + 12.8, t(0.4, 0.86));
      onV(cv - tw, cu + 0.4, cu + 2 * tw - 0.4, b + 11.1, b + 12.4, t(0.9, 0.96));
      const ap = P(cu + tw, cv, b + 20.4);
      q([P(cu, cv - tw - 0.1, b + 12.8), ap, P(cu, cv + tw + 0.1, b + 12.8)], t(0.14, 0.7));
      q([P(cu, cv - tw - 0.1, b + 12.8), ap, P(cu + 2 * tw, cv - tw - 0.1, b + 12.8)], t(0.38, 0.84));
      seg(ap, P(cu + tw, cv, b + 21.6), Math.max(0.6, 0.12 * s), 0.92);
      seg(P(cu + tw, cv - 0.35, b + 21.1), P(cu + tw, cv + 0.35, b + 21.1), Math.max(0.6, 0.1 * s), 0.92); }

    // ---- the boats tied up along the wharf head, their wheelhouses and masts over it, and one
    // lying off the end of it
    const WU0 = 152, WU1 = 158, WV0 = -26, WV1 = 18;
    for (const b of [[163, 14, 11], [166, -1, 13], [165, -15, 10]]) {
      const ub = b[0], v0 = b[1], L = b[2], s = S(ub, v0), wl = SEA + 0.2, dk = SEA + 1.7;
      q([P(ub, v0, wl), P(ub, v0 + L, wl), P(ub, v0 + L + 0.8, dk + 0.5), P(ub, v0 - 0.3, dk)], t(0.84, 0.95));
      const c0 = v0 + L * 0.5, c1 = v0 + L * 0.82;
      q([P(ub, c0, dk), P(ub, c0, dk + 3), P(ub, c1 - 0.5, dk + 3.1), P(ub, c1, dk + 2.2), P(ub, c1, dk)], t(0.66, 0.92));
      for (let w = c0 + 0.3; w < c1 - 0.8; w += 0.9) onU(ub, w, w + 0.55, dk + 1.9, dk + 2.6, night && w < c0 + 0.5 ? 0.04 : t(0.3, 0.86));
      const m0 = P(ub, c0 - 0.7, dk), m1 = P(ub, c0 - 0.7, dk + 9.5);
      seg(m0, m1, Math.max(0.6, 0.14 * s), 0.92);
      seg(P(ub, c0 - 0.7, dk + 5), P(ub, v0 + 0.6, dk + 1.6), 0.6, 0.85);
      seg(m1, P(ub, v0 + L, dk + 0.5), 0.4, 0.65);
      seg(m1, P(ub, v0 - 0.2, dk + 0.1), 0.4, 0.65);
      if (night) k.light(m1[0], m1[1], 3, 0.9);
    }
    // ---- the wharf: the head side-on on its pilings and the approach out to it, the rails, the
    // light on its post at the end, and him at the far rail by it in his flat cap, looking out
    for (let v = WV0; v <= WV1; v += 2.4) seg(P(WU0, v, WH), P(WU0, v, SEA), Math.max(0.7, 0.32 * S(WU0, v)), t(0.86, 0.95));
    for (let v = WV0; v < WV1 - 2; v += 4.8) { seg(P(WU0, v, WH - 0.6), P(WU0, v + 4.8, SEA + 1.2), 0.5, t(0.7, 0.9)); seg(P(WU0, v + 4.8, WH - 0.6), P(WU0, v, SEA + 1.2), 0.5, t(0.7, 0.9)); }
    q([P(WU0, WV0, WH), P(WU0, WV1, WH), P(WU1, WV1, WH), P(WU1, WV0, WH)], t(0.5, 0.86));
    const lp = P(WU0 + 0.5, WV1 - 0.6, WH), lt = P(WU0 + 0.5, WV1 - 0.6, WH + 4.6);
    k.light(lt[0], lt[1] + 2, t(26, 18), t(0.8, 0.85), t(22, 15));
    { const pl = P(WU0 + 3, 16, WH); k.light(pl[0], pl[1], 12, t(0.7, 0.9), 3); }
    { const f = P(WU1 - 1.4, 15.8, WH), fs = S(WU1 - 1.4, 15.8);
      PR.figure(k, { x: f[0], y: f[1], h: 1.76 * fs, pose: 'stand', back: true, hat: 'flatcap', top: 'coat', tone: 1, rim: 0, lit: 0 }); }
    for (let v = WV0; v <= WV1; v += 2) seg(P(WU1, v, WH), P(WU1, v, WH + 1.1), 0.5, 0.8);
    seg(P(WU1, WV0, WH + 1.1), P(WU1, WV1, WH + 1.1), 0.6, 0.85);
    onU(WU0, WV0, WV1, WH - 0.5, WH, t(0.9, 0.96));
    for (let v = WV0; v <= WV1; v += 2) seg(P(WU0, v, WH), P(WU0, v, WH + 1.1), 0.6, 0.92);
    seg(P(WU0, WV0, WH + 1.1), P(WU0, WV1, WH + 1.1), 0.8, 0.94);
    for (let u = UF + 3; u < WU0; u += 4) seg(P(u, 2.2, WH), P(u, 2.2, SEA), 0.7, 0.9);
    q([P(UF, 2, WH), P(UF, 6, WH), P(WU0, 6, WH), P(WU0, 2, WH)], t(0.5, 0.88));
    seg(lp, lt, 0.9, 0.95);
    k.rect(lt[0] - 1.8, lt[1] - 2.4, 3.6, 1.3, 0.9, 'set');
    k.oval(lt[0], lt[1], 1.4, 1.3, 0, 'set');
    for (let y = P(WU0 + 2, WV1, SEA)[1] + 1; y < P(UF + 8, WV1, SEA)[1]; y += 1.3) k.line(lt[0] - 1 - rnd() * 2.5, y, lt[0] + 1 + rnd() * 2.5, y, 0.6, t(0.55, 0.8) * rnd(), 'erase');

    // ---- the highway along the shore, wet, the guardrail on the sea side, a car going by
    q([P(UH, -60, HW), P(UH, 70, HW), P(UF, 70, HW), P(UF, -60, HW)], t(0.64, 0.9));
    for (let v = -40; v < 70; v += 7) seg(P(UH + 6, v, HW), P(UH + 6, v + 3, HW), 0.6, t(0.35, 0.3), 'erase');
    for (let v = -40; v < 70; v += 2.5) seg(P(UF, v, HW), P(UF, v, HW + 0.7), 0.6, 0.9);
    seg(P(UF, -60, HW + 0.7), P(UF, 70, HW + 0.7), 0.9, t(0.3, 0.55), 'erase');
    { const cu = UH + 8.5, cv = 12, c = P(cu, cv, HW), s = S(cu, cv);
      onU(cu, cv - 2.2, cv + 2.2, HW + 0.3, HW + 1, 1); onU(cu, cv - 1.3, cv + 1.2, HW + 1, HW + 1.5, 1);
      const hl = P(cu, cv - 2.2, HW + 0.65);
      k.light(hl[0] - 3 * s, hl[1] + 0.2 * s, 5 * s, t(0.55, 0.9), 0.9 * s);
      k.oval(hl[0], hl[1], 0.25 * s, 0.18 * s, 0, 'set');
      wet.push([hl[0] - 1.5 * s, c[1] + 1, 2.2, t(0.35, 0.6)]); }

    // ---- the street: wet asphalt, the gutters, the line down the middle, the sidewalks
    const U0 = 6;
    q([P(U0, VC0, gnd(U0)), P(U0, VC1, gnd(U0)), P(UH, VC1, HW), P(UH, VC0, HW)], k.lin(0, P(UH, 10, HW)[1], 0, H, [[0, t(0.5, 0.84)], [1, t(0.82, 0.96)]]));
    q([P(U0, VC1, gnd(U0)), P(U0, VF, gnd(U0)), P(UH, VF, HW), P(UH, VC1, HW)], t(0.68, 0.9));
    q([P(U0, VN, gnd(U0)), P(U0, VC0, gnd(U0)), P(UH, VC0, HW), P(UH, VN, HW)], t(0.62, 0.9));
    for (const v of [VC0, VC1]) seg(P(U0, v, gnd(U0)), P(UH, v, HW), 1, t(0.45, 0.3), 'erase');
    for (let u = 9; u < UH - 3; u += 8) seg(P(u, 10.6, gnd(u)), P(u + 3.5, 10.6, gnd(u + 3.5)), Math.max(0.6, 0.12 * S(u, 10.6)), t(0.4, 0.35), 'erase');
    // the water lying along the gutters, holding the sky
    for (const p of [[16, 19.7, 4, 0.4], [27, 19.8, 3, 0.4], [24, 1.3, 3, 0.25]]) {
      const a = P(p[0] - p[2], p[1], gnd(p[0] - p[2])), b = P(p[0] + p[2], p[1], gnd(p[0] + p[2])), c = P(p[0], p[1] - p[3], gnd(p[0])), d = P(p[0], p[1] + p[3], gnd(p[0]));
      q([a, c, b, d], t(0.3, 0.1), 'erase');
    }

    // ---- the Legion: a long low hall, white board, its floor level and the ground falling away
    // under the far end; a row of small windows lit, the door under its porch; on the grass in
    // front the field gun on its plinth, its barrel to the street
    { const L0 = 70, L1 = 92, LV = 26, LB = 40, fl = gnd(L0) + 0.3, top = fl + 3.6, rg = top + 1.5, mv = (LV + LB) / 2;
      q([P(L0, LV - 0.5, top - 0.15), P(L1 + 0.5, LV - 0.5, top - 0.15), P(L1 + 0.5, mv, rg), P(L0, mv, rg)], t(0.76, 0.93));
      q([P(L0, LV, gnd(L0)), P(L0, LV, top), P(L0, mv, rg), P(L0, LB, top), P(L0, LB, gnd(L0))], t(0.5, 0.86));
      q([P(L0, LV, top), P(L1, LV, top), P(L1, LV, fl), P(L0, LV, fl)], t(0.42, 0.84));
      q([P(L0, LV, fl), P(L1, LV, fl), P(L1, LV, gnd(L1)), P(L0, LV, gnd(L0))], t(0.74, 0.93));
      for (let h = fl + 0.45; h < top; h += 0.45) seg(P(L0, LV, h), P(L1, LV, h), 0.45, t(0.16, 0.1));
      seg(P(L0, LV, top), P(L1, LV, top), 1, 0.9);
      for (let u = L0 + 4.5; u < L1 - 1.5; u += 2.4) onV(LV, u, u + 1.1, fl + 1.1, fl + 2.3, t(0.06, 0.04));
      onV(LV, L0 + 1.4, L0 + 2.6, fl, fl + 2.3, t(0.7, 0.88));
      q([P(L0 + 0.9, LV, fl + 2.6), P(L0 + 3.1, LV, fl + 2.6), P(L0 + 3.1, LV - 1.4, fl + 2.4), P(L0 + 0.9, LV - 1.4, fl + 2.4)], t(0.84, 0.94));
      shine(L0 + 2, LV, fl + 2.6, 1.2, t(0.25, 0.5));
      for (let u = L0 + 6; u < L1 - 2; u += 4.8) shine(u, LV, fl + 1.7, 1, t(0.2, 0.4));
      // the grass, and the gun
      q([P(L0, VF, gnd(L0)), P(L1, VF, gnd(L1)), P(L1, LV, gnd(L1)), P(L0, LV, gnd(L0))], t(0.72, 0.92));
      const gu = 81, gv = 24.9, gb = gnd(gu), pt = gb + 0.9, s = S(gu, gv);
      onU(gu - 0.6, gv - 1.1, gv + 1.1, gb, pt, t(0.4, 0.85));
      onV(gv - 1.1, gu - 0.6, gu + 0.6, gb, pt, t(0.56, 0.9));
      q([P(gu - 0.6, gv - 1.1, pt), P(gu + 0.6, gv - 1.1, pt), P(gu + 0.6, gv + 1.1, pt), P(gu - 0.6, gv + 1.1, pt)], t(0.28, 0.8));
      const ax = P(gu - 0.1, gv + 0.1, pt + 0.65);
      seg(ax, P(gu - 0.1, gv + 1.9, pt + 0.05), 0.24 * s, 1);
      seg(P(gu - 0.1, gv - 0.1, pt + 0.8), P(gu - 0.1, gv - 2.6, pt + 1.3), 0.24 * s, 1);
      seg(P(gu - 0.1, gv - 2.5, pt + 1.28), P(gu - 0.1, gv - 2.75, pt + 1.33), 0.3 * s, 1);
      onV(gv - 0.25, gu - 0.75, gu + 0.55, pt + 0.5, pt + 1.6, 1);
      for (const du of [-0.75, 0.55]) {
        const w = P(gu + du, gv + 0.1, pt + 0.65), r = 0.62 * S(gu + du, gv);
        k.oval(w[0], w[1], r, r, 1, 'set');
        if (du < 0) { k.oval(w[0], w[1], r * 0.72, r * 0.72, t(0.45, 0.85), 'set'); k.oval(w[0], w[1], r * 0.2, r * 0.2, 1, 'set'); for (let a = 0; a < 8; a++) k.line(w[0], w[1], w[0] + Math.cos(a * 0.785) * r * 0.75, w[1] + Math.sin(a * 0.785) * r * 0.75, 0.5, 1); }
      }
    }

    // ---- the library: brick, one high storey, a stone band along the top, the big window lit
    { const L0 = 56, L1 = 68, fl = gnd(L0), top = fl + 6.2;
      block(L0, L1, VF, VF + 16, top, t(0.74, 0.92), t(0.8, 0.93), t(0.66, 0.9));
      for (let h = fl + 0.4; h < top - 0.7; h += 0.42) seg(P(L0, VF, h), P(L1, VF, h), 0.45, t(0.26, 0.12), 'erase');
      onV(VF, L0, L1, top - 0.7, top, t(0.46, 0.84));
      onV(VF, L0, L1, fl, fl + 0.6, t(0.54, 0.86));
      const wa = 59.2, wb = 62.6, w0 = fl + 1.1, w1 = fl + 4.1, arch = [], rim = [];
      for (let i = 0; i <= 10; i++) {
        const a = Math.PI * i / 10, mu = (wa + wb) / 2, hw = (wb - wa) / 2;
        arch.push(P(mu - Math.cos(a) * hw, VF, w1 + Math.sin(a) * 0.9));
        rim.push(P(mu - Math.cos(a) * (hw + 0.3), VF, w1 + Math.sin(a) * 1.2));
      }
      q([P(wa - 0.3, VF, w0 - 0.3)].concat(rim).concat([P(wb + 0.3, VF, w0 - 0.3)]), t(0.44, 0.82));
      q([P(wa, VF, w0)].concat(arch).concat([P(wb, VF, w0)]), t(0.05, 0.02));
      for (const u of [wa + 1.13, wa + 2.27]) seg(P(u, VF, w0), P(u, VF, w1 + 0.85), 0.6, 0.7);
      seg(P(wa, VF, w1), P(wb, VF, w1), 0.6, 0.7);
      onV(VF, 64.6, 66.4, fl + 1.1, fl + 4.1, t(0.86, 0.93));
      onV(VF, 66.8, 67.8, fl, fl + 2.6, t(0.6, 0.86));
      const lw = P((wa + wb) / 2, VF - 1, fl + 2.5);
      k.light(lw[0], lw[1], 10, t(0.25, 0.4), 14);
      shine((wa + wb) / 2, VF, fl + 2.6, 2.2, t(0.42, 0.6)); }

    // ---- two shops, two storeys: the windows lit at the street, an awning, a few lit upstairs
    for (const sh of [[48, 54, 6.8, 0.64, false], [42, 48, 7.4, 0.72, true]]) {
      const u0 = sh[0], u1 = sh[1], fl = gnd(u0), top = fl + sh[2];
      block(u0, u1, VF, VF + 16, top, t(sh[3], 0.9), t(sh[3] + 0.06, 0.92), t(0.6, 0.9));
      onV(VF, u0, u1, top - 0.55, top, t(0.84, 0.94));
      onV(VF, u0, u1, fl + 2.9, fl + 3.6, t(0.84, 0.94));
      onV(VF, u0 + 0.5, u1 - 1.7, fl + 0.5, fl + 2.8, t(0.07, 0.03));
      for (let u = u0 + 1.6; u < u1 - 1.8; u += 1.2) seg(P(u, VF, fl + 0.5), P(u, VF, fl + 2.8), 0.6, 0.6);
      onV(VF, u1 - 1.5, u1 - 0.5, fl, fl + 2.5, t(0.5, 0.86));
      for (let u = u0 + 0.8; u < u1 - 1; u += 1.9) onV(VF, u, u + 1, fl + 4.3, fl + 5.9, rnd() < 0.4 ? t(0.12, 0.05) : t(0.88, 0.95));
      if (sh[4]) q([P(u0 + 0.3, VF, fl + 3.3), P(u1 - 0.3, VF, fl + 3.3), P(u1 - 0.3, VF - 1.7, fl + 2.6), P(u0 + 0.3, VF - 1.7, fl + 2.6)], t(0.9, 0.96));
      else { const a = P(u0 + 1, VF, fl + 3.6), b = P(u0 + 1, VF - 1.4, fl + 3.6); seg(a, b, 0.6, 0.9); onU(u0 + 1, VF - 1.3, VF - 0.2, fl + 2.7, fl + 3.5, t(0.3, 0.75)); }
      shine((u0 + u1) / 2 - 0.6, VF, fl + 1.6, 3, t(0.42, 0.6));
    }

    // ---- the old bank at the top: stone, the columns and the beam on them, the cornice; a cafe
    // in it now, its glass lit low in the dark behind the columns. Its floor's level, so the
    // ground falls away under its far end and the stone base shows
    { const B0 = 26, B1 = 42, fl = gnd(B0) + 0.4, top = gnd(B0) + 8.6, cv = VF - 0.9;
      block(B0, B1, VF, VF + 16, top, t(0.56, 0.88), t(0.62, 0.9), 0.8);
      q([P(B0, VF, fl), P(B1, VF, fl), P(B1, VF, gnd(B1)), P(B0, VF, gnd(B0))], t(0.74, 0.92));
      onV(VF, B0 + 0.6, B1 - 0.6, fl, fl + 5.8, t(0.88, 0.96));
      onV(VF, B0 + 1, B1 - 1, fl + 0.4, fl + 2.6, t(0.1, 0.04));
      for (let u = B0 + 2.2; u < B1 - 1; u += 1.2) seg(P(u, VF, fl + 0.4), P(u, VF, fl + 2.6), 0.5, 0.6);
      for (let u = B0 + 4; u < B1 - 1; u += 3.6) shine(u, VF, fl + 1.8, 3, t(0.35, 0.5));
      onV(VF, B0, B1, fl + 5.8, fl + 6.8, t(0.36, 0.8));
      onV(VF, B0, B1, fl + 6.8, fl + 7.3, t(0.3, 0.78));
      seg(P(B0, VF, fl + 6.8), P(B1, VF, fl + 6.8), 1, 0.85);
      seg(P(B0, VF, fl + 5.8), P(B1, VF, fl + 5.8), 0.7, 0.8);
      q([P(B0, cv, fl), P(B1, cv, fl), P(B1, VF, fl), P(B0, VF, fl)], t(0.36, 0.8));
      for (let i = 0; i <= 4; i++) {
        const u = B0 + 1.6 + i * 3.6, s = S(u, cv), c0 = P(u, cv, fl), c1 = P(u, cv, fl + 5.8), r = 0.36 * s;
        k.rect(c1[0] - r, c1[1], 2 * r, c0[1] - c1[1], t(0.3, 0.74), 'set');
        k.rect(c1[0] - r, c1[1], 0.7 * r, c0[1] - c1[1], t(0.52, 0.86), 'set');
        k.line(c1[0] + 0.45 * r, c1[1], c1[0] + 0.45 * r, c0[1], Math.max(0.5, 0.1 * s), t(0.3, 0.15), 'erase');
        k.rect(c1[0] - 1.3 * r, c1[1], 2.6 * r, 0.3 * s, t(0.28, 0.76), 'set');
        k.rect(c0[0] - 1.25 * r, c0[1] - 0.3 * s, 2.5 * r, 0.3 * s, t(0.32, 0.78), 'set');
      }
    }

    // ---- this side, down the hill: a shop at the bottom, two old houses with their gables to the
    // street, and the nearest house at the edge of things, its porch roof and its windows lit
    { const NB = VN - 14;
      for (const hs of [[78, 88, 4.6, 0, 0.74], [62, 75, 4.4, 2.6, 0.68], [45, 59, 4.8, 2.8, 0.74]]) {
        const u0 = hs[0], u1 = hs[1], fl = gnd(u0), eave = fl + hs[2], rg = eave + hs[3], mu = (u0 + u1) / 2;
        block(u0, u1, VN, NB, eave, t(hs[4], 0.92), t(hs[4] + 0.06, 0.93), t(0.72, 0.92));
        if (hs[3]) {
          q([P(u0, VN, eave), P(mu, VN, rg), P(u1, VN, eave)], t(hs[4] - 0.04, 0.92));
          q([P(u0 - 0.3, VN, eave - 0.1), P(mu, VN, rg + 0.2), P(mu, NB, rg + 0.2), P(u0 - 0.3, NB, eave - 0.1)], t(0.84, 0.95));
          seg(P(u0 - 0.3, VN, eave - 0.1), P(mu, VN, rg + 0.2), 0.8, t(0.35, 0.2), 'erase');
          onV(VN, mu - 0.7, mu + 0.7, eave + 0.3, eave + 1.6, rnd() < 0.5 ? t(0.1, 0.04) : t(0.88, 0.95));
        }
        for (let u = u0 + 1; u < u1 - 1.2; u += 2.6) onV(VN, u, u + 1.2, fl + 1, fl + 2.6, t(0.14, 0.05));
        shine(mu, VN, fl + 1.8, 3, t(0.3, 0.5));
      }
      block(12, 43, VN, VN - 10, gnd(12) + 4.6, t(0.78, 0.93), t(0.82, 0.94), 0.8);
      for (const u of [22, 30, 37]) { onV(VN, u, u + 2.2, gnd(14) + 0.9, gnd(14) + 2.7, t(0.08, 0.03)); seg(P(u + 1.1, VN, gnd(14) + 0.9), P(u + 1.1, VN, gnd(14) + 2.7), 0.8, 0.7); }
      q([P(12, VN, gnd(12) + 3.3), P(43, VN, gnd(12) + 3.3), P(43, VN + 1.4, gnd(12) + 3), P(12, VN + 1.4, gnd(12) + 3)], t(0.9, 0.96));
      shine(30, VN, gnd(14) + 1.7, 5, t(0.4, 0.6)); }

    // the wet: every light down the road toward him, broken by the drizzle on it
    k.clip(function (c) { const a = P(U0, VN, gnd(U0)), b = P(U0, VF, gnd(U0)), cc = P(UF, VF, HW), d = P(UF, VN, HW); c.moveTo(a[0], a[1]); c.lineTo(b[0], b[1]); c.lineTo(cc[0], cc[1]); c.lineTo(d[0], d[1]); c.closePath(); });
    for (const w of wet) {
      const len = Math.min(H - w[1], 20 + (w[1] - hz) * 0.5);
      for (let y = w[1] - len * 0.5; y < w[1] + len; y += 1.1 + rnd() * 0.9) {
        const f = 1 - Math.abs(y - w[1]) / len, hw = w[2] * (0.4 + rnd() * 0.6) * (0.6 + 0.4 * f);
        k.line(w[0] - hw, y, w[0] + hw, y, 0.6, w[3] * f, 'erase');
      }
    }
    k.done();

    // ---- the power poles down the far side, a lamp on an arm off each over the street, and the
    // lines down the hill between them and away along the highway
    { const poles = [34, 62, 88], pv = 21.6, ph = 10, wires = [-1.2, 0, 1.2];
      for (const u of poles) {
        const s = S(u, pv), b = gnd(u), p0 = P(u, pv, b), p1 = P(u, pv, b + ph + 0.4);
        seg(p0, p1, Math.max(0.9, 0.3 * s), 0.95);
        seg(P(u, pv - 1.5, b + ph), P(u, pv + 1.5, b + ph), Math.max(0.7, 0.14 * s), 0.95);
        const a0 = P(u, pv, b + 7.4), a1 = P(u, pv - 2.4, b + 7.6);
        k.stroke('M' + a0[0] + ' ' + a0[1] + ' Q' + a0[0] + ' ' + (a1[1] - 0.2 * s) + ' ' + a1[0] + ' ' + a1[1], Math.max(0.6, 0.1 * s), 0.92);
        const r = P(u, pv - 2.4, b);
        cone(k, a1[0] - 0.25 * s, a1[0] + 0.25 * s, a1[1] + 0.15 * s, r[0] - 2.2 * s, r[0] + 2.2 * s, r[1], t(0.12, 0.2), 0.3);
        k.light(a1[0], a1[1] + 0.4 * s, 1.6 * s, t(0.5, 0.7), 1.2 * s);
        k.oval(a1[0], a1[1] + 0.12 * s, 0.32 * s, 0.12 * s, 0, 'set');
        k.light(r[0], r[1], 3 * s, t(0.2, 0.45), 0.8 * s);
        shine(u, pv - 2.4, b + 7.5, Math.max(1.5, 0.3 * s), t(0.5, 0.8));
      }
      for (const w of wires) {
        let d = 'M' + P(4, pv + w, gnd(4) + ph - 0.6)[0] + ' ' + P(4, pv + w, gnd(4) + ph - 0.6)[1];
        let pu = 4;
        for (const u of poles) {
          const m = (pu + u) / 2, e = P(u, pv + w, gnd(u) + ph), c = P(m, pv + w, (gnd(pu) + gnd(u)) / 2 + ph - 1.3);
          d += ' Q' + c[0] + ' ' + c[1] + ' ' + e[0] + ' ' + e[1];
          pu = u;
        }
        const e = P(UH + 1, pv + w - 44, HW + ph - 0.4), c = P(UH, pv + w - 18, HW + ph - 1.6);
        k.stroke(d + ' Q' + c[0] + ' ' + c[1] + ' ' + e[0] + ' ' + e[1], 0.55, 0.9);
      }
      const a = P(62, pv - 1.2, gnd(62) + ph), b = P(52, VN, gnd(52) + 5.5), c = P(57, 8, gnd(57) + ph - 1.8);
      k.stroke('M' + a[0] + ' ' + a[1] + ' Q' + c[0] + ' ' + c[1] + ' ' + b[0] + ' ' + b[1], 0.5, 0.85); }

    // the drizzle, seen against the dark
    k.rain(rnd, 380, 0, 0, W, H, { tone: t(0.3, 0.4), len: 7, w: 0.5, slant: 0.12 });
    vignette(k, t(0.34, 0.46));
    edge(k);
  };

  // ---------------------------------------------------------------- faces
  //
  // A face the way Papers, Please builds them: the same head every time and the parts that make it
  // somebody (how broad, the jaw, where the eyes sit and how open, the nose, the mouth, the brows,
  // the hair or the hat, a beard, glasses, what they're wearing, what's in their hand, how the night
  // is sitting on them), from the character's `look:` in content/data/characters.yaml and a seed
  // from their name. Printed like the plates: lit from the left by the bar, the neon catching the
  // other edge in red. The marks that have to read at the size a face is shown (lids, pupils,
  // brows, the line of the mouth, nostrils) go down solid so the screen prints them clean.
  const FW = 120, FH = 150;
  // numbers into a path: pth('M', x, y, 'L', x, y)
  function pth() { let s = ''; for (let i = 0; i < arguments.length; i++) { const a = arguments[i]; s += (typeof a === 'number' ? Math.round(a * 100) / 100 : a) + ' '; } return s; }

  // how the night is sitting on them. lid: 0 open, 1 heavy. squint: the lower lid up. brow: the
  // inner ends up (worried, tired) or down (hard). smile: the corners up or down. open: the mouth.
  // asym: one corner more than the other. tilt: the head off true.
  const MOODS = {
    flat: { lid: 0.15, squint: 0.1, brow: 0, smile: 0 },
    tired: { lid: 0.5, squint: 0, brow: 0.55, smile: -0.45 },
    wary: { lid: 0, squint: 0.3, brow: -0.75, smile: -0.2 },
    hard: { lid: 0.15, squint: 0.35, brow: -0.55, smile: -0.35 },
    drunk: { lid: 0.62, squint: 0.2, brow: 0.35, smile: 0.55, open: 0.5, tilt: 1 },
    smile: { lid: 0.2, squint: 0.4, brow: 0.15, smile: 0.85 },
    knowing: { lid: 0.5, squint: 0.3, brow: -0.15, smile: 0.4, asym: 1 }
  };

  const LEAN = { warm: 'smile', cold: 'hard' };

  function planFace(id, look, r) {
    look = look || {};
    const n = function (a, b) { return a + (b - a) * r(); };
    const fem = look.sex === 'f', young = look.age === 'young', old = look.age === 'old';
    const big = look.build === 'big', slight = look.build === 'slight';
    const face = [].concat(look.face || []), extra = [].concat(look.extra || []);
    // how he stands with them can change the face they make at him (lean: warm | cold), never the face
    const mood = MOODS[look.lean ? look[look.lean] || LEAN[look.lean] : look.mood] || MOODS[look.mood] || MOODS.flat;
    const lean = r();
    const hw = (big ? 27.5 : slight ? 23.2 : 24.8) * (fem ? 0.93 : 1) * (young ? 0.97 : 1) * n(0.95, 1.05);
    const hh = (big ? 75 : 71) * (fem ? 0.96 : 1) * n(0.97, 1.03);
    const ty = n(15, 18) + (big ? -2 : 0) + (young ? 1 : 0), cx = 60 + n(-1.5, 1.5), turn = n(-0.35, 0.35);
    const p = {
      fem: fem, young: young, old: old || face.indexOf('lined') !== -1, grey: old, big: big, mood: mood,
      cx: cx, fx: cx + turn * hw * 0.16, turn: turn, ty: ty, cy: ty + hh, hw: hw, hh: hh,
      jw: hw * (fem ? n(0.6, 0.68) : big ? n(0.86, 0.94) : young ? n(0.72, 0.8) : n(0.74, 0.86)),
      cw: hw * (fem ? n(0.2, 0.26) : n(0.26, 0.36)),
      jowl: old ? n(1, 2.2) : 0,
      es: hw * n(0.36, 0.41), ew: hw * (fem ? n(0.31, 0.35) : young ? n(0.29, 0.33) : n(0.28, 0.32)),
      eo: young ? (fem ? n(2.7, 3.2) : n(2.5, 2.9)) : old ? n(1.9, 2.4) : n(2.3, 2.8), etilt: n(-0.8, 0.8), gaze: n(-0.6, 0.4),
      bags: old ? n(0.45, 0.62) : young ? 0 : n(0, 0.3),
      bt: fem ? n(1.2, 1.6) : old ? n(2.4, 3.2) : n(2, 2.8), barch: fem ? n(2, 2.8) : n(0.4, 1.6), btilt: n(-1, 1.2),
      nw: hw * (fem ? n(0.15, 0.18) : big ? n(0.23, 0.27) : n(0.18, 0.23)), nlen: n(0.95, 1.08), bulb: n(0.8, 1.4), hook: n(-0.6, 1),
      mw: hw * (fem ? n(0.27, 0.32) : n(0.26, 0.33)), lip: fem ? n(1.8, 2.4) : young ? n(1.4, 1.9) : old ? n(0.9, 1.3) : n(1.2, 1.8),
      ear: hh * n(0.15, 0.18), neck: hw * (big ? 0.66 : fem ? 0.4 : slight ? 0.46 : 0.52),
      sw: big ? 72 : slight ? 52 : fem ? 50 : 58,
      tilt: n(-0.04, 0.04) + (mood.tilt ? (lean < 0.5 ? -0.06 : 0.06) : 0),
      face: face, extra: extra, hair: look.hair || null, hat: look.hat || null, top: look.top || 'jacket',
      skin: n(0.06, 0.12) + (old ? 0.03 : 0),
      hairTone: old ? n(0.36, 0.5) : n(0.84, 0.95)
    };
    p.yE = ty + hh * n(0.47, 0.5);
    p.yB = p.yE - hh * n(0.085, 0.1);
    p.yN = p.yE + hh * n(0.19, 0.22) * p.nlen + (old ? 1 : 0);
    p.yM = p.yN + hh * n(0.1, 0.12);
    p.yJ = ty + hh * n(0.78, 0.82) + p.jowl;
    return p;
  }

  // the outline of the head at (cx, ty..cy), g grown outward
  function headPath(p, g) {
    g = g || 0;
    const cx = p.cx, hw = p.hw + g, jw = p.jw + g, cw = p.cw + g * 0.5, ty = p.ty - g, cy = p.cy + g, hh = p.hh, yE = p.yE, yJ = p.yJ;
    const side = function (s) {
      return [cx + s * hw * 0.64, ty, cx + s * hw * 0.98, ty + hh * 0.08, cx + s * hw * 0.97, ty + hh * 0.24,
        cx + s * hw * 1.02, ty + hh * 0.36, cx + s * hw * 1.02, yE - hh * 0.02, cx + s * hw, yE + hh * 0.08,
        cx + s * hw * 0.98, yE + hh * 0.2, cx + s * (jw + p.jowl) * 1.02, yJ - hh * 0.08, cx + s * (jw + p.jowl), yJ,
        cx + s * (jw * 0.94 + p.jowl * 0.6), yJ + hh * 0.08, cx + s * cw * 1.3, cy - hh * 0.03, cx + s * cw, cy - hh * 0.012];
    };
    const R = side(1), L = side(-1);
    return pth('M', cx, ty, 'C', R[0], R[1], R[2], R[3], R[4], R[5], 'C', R[6], R[7], R[8], R[9], R[10], R[11], 'C', R[12], R[13], R[14], R[15], R[16], R[17],
      'C', R[18], R[19], R[20], R[21], R[22], R[23], 'Q', cx + cw * 0.55, cy + 0.4, cx, cy, 'Q', cx - cw * 0.55, cy + 0.4, L[22], L[23],
      'C', L[20], L[21], L[18], L[19], L[16], L[17], 'C', L[14], L[15], L[12], L[13], L[10], L[11], 'C', L[8], L[9], L[6], L[7], L[4], L[5],
      'C', L[2], L[3], L[0], L[1], cx, ty, 'Z');
  }

  function withClip(j, d, fn) {
    const q = new Path2D(d);
    j.k.c.save(); j.r.c.save(); j.k.c.clip(q); j.r.c.clip(q);
    try { fn(); } finally { j.k.c.restore(); j.r.c.restore(); }
  }
  // the head's own lean, about the top of the neck
  function tilted(j, p, fn) {
    const px = p.cx, py = p.cy + p.hh * 0.12;
    for (const c of [j.k.c, j.r.c]) { c.save(); c.translate(px, py); c.rotate(p.tilt); c.translate(-px, -py); }
    try { fn(); } finally { j.k.c.restore(); j.r.c.restore(); }
  }
  // fill a path with a hole in it (even-odd)
  function fillEO(pen, d, tone, mode) {
    const c = pen.c, q = new Path2D(d);
    c.save();
    if (mode === 'set') { c.globalCompositeOperation = 'destination-out'; c.fillStyle = '#000'; c.fill(q, 'evenodd'); c.globalCompositeOperation = 'source-over'; }
    c.fillStyle = pen.style(tone); c.fill(q, 'evenodd'); c.restore();
  }
  // a soft oval of shade (or of light, erasing), fading out from the middle
  function soft(pen, x, y, rx, ry, a, rot, erase) {
    const c = pen.c;
    c.save(); c.translate(x, y); if (rot) c.rotate(rot); c.scale(1, ry / rx);
    if (erase) c.globalCompositeOperation = 'destination-out';
    c.fillStyle = pen.rad(0, 0, 0, rx, [[0, a], [0.5, a * 0.72], [1, 0]]);
    c.beginPath(); c.arc(0, 0, rx, 0, Math.PI * 2); c.fill(); c.restore();
  }

  // Everything that's the person goes into a silhouette as it's drawn; at the end the neon from
  // behind on the right lays a crescent of red down that side of all of it (the silhouette, less
  // itself shifted left), and lifts the black there.
  const SIL = {}, RIMC = {};
  function silStart(j) {
    if (!SIL.c || SIL.c.width !== j.w || SIL.c.height !== j.h) SIL.c = PR.canvas(j.w, j.h);
    const m = SIL.c.getContext('2d');
    m.setTransform(1, 0, 0, 1, 0, 0); m.globalCompositeOperation = 'source-over'; m.clearRect(0, 0, j.w, j.h);
  }
  function sil(j, d) {
    const m = SIL.c.getContext('2d');
    m.setTransform(j.k.c.getTransform()); m.fillStyle = '#000'; m.fill(new Path2D(d));
  }
  function silRim(j, dx, dy, red, lift) {
    if (!RIMC.c || RIMC.c.width !== j.w || RIMC.c.height !== j.h) RIMC.c = PR.canvas(j.w, j.h);
    const T = j.k.c.getTransform(), sc = Math.hypot(T.a, T.b), t = RIMC.c.getContext('2d');
    t.setTransform(1, 0, 0, 1, 0, 0); t.globalCompositeOperation = 'source-over'; t.clearRect(0, 0, j.w, j.h);
    t.drawImage(SIL.c, 0, 0);
    t.globalCompositeOperation = 'destination-out'; t.drawImage(SIL.c, -dx * sc, dy * sc);
    for (const pen of [j.k, j.r]) {
      const c = pen.c;
      c.save(); c.setTransform(1, 0, 0, 1, 0, 0);
      if (pen === j.k) { c.globalCompositeOperation = 'destination-out'; c.globalAlpha = lift; } else c.globalAlpha = red;
      c.drawImage(RIMC.c, 0, 0); c.restore();
    }
  }

  function paintBust(j, p, r) {
    const nb = p.cy + p.hh * 0.17;                // where the neck meets the shoulders
    silStart(j);
    tilted(j, p, function () { paintHair(j, p, r, 'back'); });
    paintBody(j, p, r, nb);
    tilted(j, p, function () {
      paintEars(j, p);
      paintHead(j, p, r);
      paintEye(j, p, -1); paintEye(j, p, 1);
      paintHair(j, p, r, 'front');
      paintFaceBits(j, p, r);
    });
    paintExtras(j, p, r, nb);
    if (p.flat) return;                           // an ID photo: the flash, not the neon
    silRim(j, 2.8, 0.5, 0.5, 0.42);
    silRim(j, 1.2, 0, 0.95, 0.8);
  }

  function paintBody(j, p, r, nb) {
    const k = j.k, cx = p.cx, sw = p.sw, ng = p.neck, hh = p.hh;
    const body = pth('M', cx - ng - 2, nb - 6, 'C', cx - ng - 12, nb - 1, cx - sw + 8, nb + 1, cx - sw, nb + 16, 'L', cx - sw - 8, FH + 2, 'L', cx + sw + 8, FH + 2, 'L', cx + sw, nb + 16,
      'C', cx + sw - 8, nb + 1, cx + ng + 12, nb - 1, cx + ng + 2, nb - 6, 'Z');
    sil(j, body);
    const cloth = { hivis: 0.82, apron: 0.9, whites: 0.22, flannel: 0.72, suit: 0.93, coat: 0.86, jacket: 0.86, tshirt: 0.7, cardigan: 0.6, hoodie: 0.84 }[p.top] || 0.86;
    k.path(body, k.lin(cx - sw, 0, cx + sw, 0, [[0, cloth - 0.3], [0.3, cloth - 0.2], [0.58, cloth], [1, Math.min(1, cloth + 0.06)]]), 'set');
    // the neck, the jaw's shadow across it, the dark side
    const neck = pth('M', cx - ng, p.yJ - 4, 'L', cx + ng, p.yJ - 4, 'L', cx + ng + 1.5, nb + 1, 'Q', cx, nb + 6, cx - ng - 1.5, nb + 1, 'Z');
    sil(j, neck);
    k.path(neck, k.lin(cx - ng, 0, cx + ng, 0, [[0, p.skin + 0.22], [0.4, p.skin + 0.32], [0.62, 0.64], [1, 0.72]]), 'set');
    k.path(pth('M', cx - ng - 1, p.cy - 10, 'Q', cx, p.cy + hh * 0.15, cx + ng + 1, p.cy - 10, 'L', cx + ng + 1, p.yJ - 4, 'L', cx - ng - 1, p.yJ - 4, 'Z'), 0.72);
    if (!p.fem && p.face.indexOf('beard') < 0) k.stroke(pth('M', cx - 1.5, p.cy + hh * 0.085, 'q', 1.6, 3, 1.2, 5.5), 0.9, 0.3);
    paintTop(j, p, r, body, nb);
  }

  function paintEars(j, p) {
    const k = j.k, cx = p.cx, hw = p.hw, eY = p.yE + p.hh * 0.06, eh = p.ear;
    for (const s of [-1, 1]) {
      const ex = cx + s * hw;
      const d = pth('M', ex - s * 1, eY - eh * 0.55, 'C', ex + s * 5.4, eY - eh * 0.8, ex + s * 5.6, eY + eh * 0.2, ex + s * 1.4, eY + eh * 0.58, 'L', ex - s * 1, eY + eh * 0.3, 'Z');
      sil(j, d);
      k.path(d, s < 0 ? p.skin + 0.12 : 0.52, 'set');
      k.stroke(pth('M', ex + s * 0.4, eY - eh * 0.38, 'C', ex + s * 3.9, eY - eh * 0.46, ex + s * 3.7, eY + eh * 0.14, ex + s * 0.9, eY + eh * 0.26), 0.9, s < 0 ? 0.55 : 0.9);
      k.oval(ex + s * 1.8, eY, 1.1, 1.8, s < 0 ? 0.5 : 0.9);
    }
  }

  // the head: skin lit from the left, going over into shadow just past the nose; the planes and
  // the hollows; the nose, the mouth, the lines the years have put in
  function paintHead(j, p, r) {
    const k = j.k, rd = j.r, cx = p.cx, fx = p.fx, hw = p.hw, hh = p.hh, m = p.mood;
    const hd = headPath(p);
    sil(j, hd);
    const X = function (x) { return Math.max(0, Math.min(1, (x - (cx - hw)) / (2 * hw))); };
    const xT = fx + hw * 0.2;
    k.path(hd, k.lin(cx - hw, 0, cx + hw, 0, [[0, p.skin + 0.16], [X(cx - hw * 0.78), p.skin + 0.02], [X(xT - 4), p.skin + 0.04], [X(xT), p.skin + 0.2],
      [X(xT + 4.5), 0.44], [X(cx + hw * 0.72), 0.52], [1, 0.47]]), 'set');
    withClip(j, hd, function () {
      // the crown going up into the dark, the jaw turning under
      k.rect(cx - hw - 2, p.ty - 1, 2 * hw + 4, hh + 3, k.lin(0, p.ty, 0, p.cy, [[0, 0.1], [0.2, 0], [0.64, 0], [0.9, 0.1], [1, 0.24]]));
      // the lit side's temple turning away; the cheekbone taking the light, the hollow under it
      soft(k, cx - hw * 0.92, p.yE - hh * 0.1, hw * 0.2, hh * 0.16, 0.16);
      soft(k, fx - p.es - 1, p.yE + hh * 0.13, hw * 0.24, hh * 0.065, 0.2, -0.2, true);
      soft(k, cx - hw * 0.62, p.yE + hh * 0.27, hw * 0.14, hh * 0.09, p.old ? 0.22 : 0.12, 0.35);
      // the sockets under the brow, the shadow side of the bridge, the ridge catching the light
      for (const s of [-1, 1]) { const e = eyeAt(p, s); soft(k, e.x + s * 0.6, p.yE - 0.8, e.w * 0.98, hh * 0.085, s < 0 ? 0.38 : 0.52); }
      soft(k, fx + hw * 0.15, p.yE - 0.5, 2.8, 4.2, 0.3);
      soft(k, fx - p.es, p.yB - 2.4, p.ew * 0.8, 1.6, 0.3, 0, true);
      if (m.brow < -0.4) { k.line(fx - 1.2, p.yB - 1, fx - 0.8, p.yB + 3, 0.6, 0.55); k.line(fx + 1.4, p.yB - 1, fx + 1.1, p.yB + 3, 0.6, 0.6); }
      // the nose: its shadow side from the brow down to the wing, the ridge and the ball of it in
      // the light, the near wing, the nostrils, the shadow it throws
      const nw = p.nw, yN = p.yN, yE = p.yE, tip = fx + p.turn * hw * 0.1;
      k.path(pth('M', fx + 1.2, yE - 1, 'C', fx + 2.6, yE + 5, tip + nw * 0.9, yN - 8 + p.hook, tip + nw * 1.08, yN - 1.8, 'Q', tip + nw * 0.8, yN + 1.2, tip + 0.6, yN + 0.8, 'L', fx + 0.6, yE + 2, 'Z'), 0.5);
      k.stroke(pth('M', fx - 0.6, yE + 1.5, 'Q', tip - 1.2 + p.hook * 0.4, (yE + yN) / 2, tip - 1, yN - 3.4), 1.4, 0.3, 'erase');
      soft(k, tip - 1, yN - 2.8, 2.6 * p.bulb, 2.1 * p.bulb, 0.5, 0, true);
      k.stroke(pth('M', tip - nw * 0.9, yN - 3.4, 'C', tip - nw * 1.3, yN - 1.2, tip - nw * 1.05, yN + 1.2, tip - nw * 0.4, yN + 1.1), 0.9, 0.72);
      k.oval(tip - nw * 0.45, yN + 0.5, nw * 0.3, 0.95, 1);
      k.oval(tip + nw * 0.5, yN + 0.5, nw * 0.28, 0.95, 1);
      soft(k, tip + nw * 0.4, yN + 3, nw * 1.25, 2.1, 0.5);
      // the folds from the nose past the mouth
      const fold = p.old ? 0.62 : 0.32, fwid = p.old ? 1.1 : 0.8;
      k.stroke(pth('M', tip - nw * 1.15, yN - 1.5, 'Q', fx - p.mw - 2.6, p.yM - 3, fx - p.mw - 2, p.yM + 3), fwid, fold);
      k.stroke(pth('M', tip + nw * 1.2, yN - 1.5, 'Q', fx + p.mw + 2.6, p.yM - 3, fx + p.mw + 2, p.yM + 3), fwid, fold + 0.2);
      // the mouth: the dip under the nose, the upper lip in its own shade, the line of it (open a
      // little on a drunk), the corners, the lower lip in the light and its shadow under
      const mw = p.mw, yM = p.yM, sm = m.smile, lp = p.lip, open = m.open || 0;
      const cL = [fx - mw, yM - sm * 1.4 + (m.asym ? 0.7 : 0)], cR = [fx + mw * (1 - p.turn * 0.2), yM - sm * 1.4 - (m.asym ? 0.9 : 0)];
      soft(k, fx + 0.6, (yN + yM) / 2 + 0.5, 1.5, 2.3, 0.24);
      k.path(pth('M', cL[0], cL[1], 'Q', fx - mw * 0.45, yM - lp - 0.6, fx - 1, yM - lp - 0.2, 'L', fx, yM - lp + 0.5, 'L', fx + 1, yM - lp - 0.2, 'Q', fx + mw * 0.45, yM - lp - 0.6, cR[0], cR[1], 'Q', fx, yM + 0.4, cL[0], cL[1], 'Z'),
        k.lin(fx - mw, 0, fx + mw, 0, [[0, 0.4], [0.5, 0.5], [1, 0.74]]));
      if (open) k.path(pth('M', cL[0], cL[1], 'Q', fx, yM - 0.2 - sm * 0.5, cR[0], cR[1], 'Q', fx, yM + open * 3.4 + 0.8 - sm * 0.5, cL[0], cL[1], 'Z'), 1);
      k.stroke(pth('M', cL[0] - 0.3, cL[1], 'Q', fx, yM + 0.9 - sm * 0.2, cR[0] + 0.3, cR[1]), 1.3, 1);
      k.oval(cL[0], cL[1] + 0.2, 0.9, 0.9, 0.9); k.oval(cR[0], cR[1] + 0.2, 0.9, 0.9, 0.95);
      soft(k, fx - 1.4, yM + lp * 0.8 + 1.2 + open * 2, mw * 0.45, 1, 0.4, 0, true);
      soft(k, fx + 0.6, yM + lp * 1.6 + 3.2 + open * 2, mw * 0.74, 1.8, 0.44);
      // the chin in the light on the near side
      soft(k, fx - 2.2, p.cy - hh * 0.07, 3.8, 2.6, 0.26, 0, true);
      if (p.old) {
        // the jowls, the lines from the corners of the mouth down, the forehead
        k.stroke(pth('M', cx + p.jw * 0.55, p.yJ + 1, 'Q', cx + p.cw * 1.5, p.cy - 2, cx + p.cw * 0.6, p.cy - 1), 0.8, 0.55);
        k.stroke(pth('M', cx - p.jw * 0.55, p.yJ + 1, 'Q', cx - p.cw * 1.5, p.cy - 2, cx - p.cw * 0.6, p.cy - 1), 0.8, 0.38);
        k.stroke(pth('M', cL[0] - 0.4, cL[1] + 1.2, 'q', -1, 2.4, -0.6, 4.4), 0.7, 0.45);
        k.stroke(pth('M', cR[0] + 0.4, cR[1] + 1.2, 'q', 1, 2.4, 0.6, 4.4), 0.7, 0.6);
        for (let i = 0; i < 2; i++) k.stroke(pth('M', cx - hw * 0.45 + i * 2, p.ty + hh * (0.2 + i * 0.05), 'q', hw * 0.45 - i * 2, -1.2, hw * 0.9 - i * 4, 0), 0.7, 0.4);
      }
      // the neon's red on the far side of the face
      if (!p.flat) rd.path(hd, rd.lin(cx - hw, 0, cx + hw, 0, [[0.72, 0], [0.9, 0.12], [1, 0.3]]));
    });
  }

  function eyeAt(p, s) {
    return { x: p.fx + s * p.es * (1 - s * p.turn * 0.22), w: p.ew * (1 - s * p.turn * 0.3) };
  }
  // an eye: the white that isn't white, the iris under the lid, one catchlight, the lid itself
  // solid and carried a little past the corner, the crease, the lower lid, and the brow
  function paintEye(j, p, s) {
    const k = j.k, m = p.mood, e = eyeAt(p, s), ex = e.x, w = e.w, y = p.yE, tl = p.etilt * s;
    const oU = p.eo * 1.5 * (1 - 0.5 * m.lid), oL = p.eo * 0.95 * (1 - 0.6 * m.squint);
    const inX = ex - s * w / 2, outX = ex + s * w / 2, inY = y + 0.2, outY = y - tl * 0.5;
    const upper = ['M', inX, inY, 'C', inX + s * w * 0.2, y - oU * 1.25, outX - s * w * 0.3, y - oU * 1.2 + m.lid * 0.6, outX, outY];
    const al = pth.apply(null, upper.concat(['Q', ex + s * w * 0.05, y + oL * 1.25, inX, inY, 'Z']));
    k.path(al, s < 0 ? 0.08 : 0.38, 'set');
    const ix = ex + p.gaze * (s < 0 ? 1 : 0.9), iy = y - 0.3 - p.eo * 0.1;
    k.c.save(); k.c.clip(new Path2D(al));
    k.oval(ix, iy, w * 0.23, w * 0.23, 1);
    k.rect(ex - w, y - oU * 2.2, w * 2, oU * 1.2 + 0.4, 0.45);
    k.c.restore();
    k.oval(ix - w * 0.07, iy - w * 0.08, 0.62, 0.62, s < 0 ? 1 : 0.6, 'erase');
    const flick = p.fem ? ['q', s * 1.6, -0.9, s * 2.1, -0.8] : ['q', s * 0.8, -0.2, s * 1, 0];
    k.stroke(pth.apply(null, upper.concat(flick)), p.fem ? 1.75 : 1.5, 1);
    k.stroke(pth('M', inX + s * w * 0.1, inY - oU * 0.9 - 1.3, 'Q', ex + s * w * 0.05, y - oU * 1.9 - 1.8 + m.lid * 1.2, outX + s * 0.3, outY - oU * 0.5 - 1), 0.55, s < 0 ? 0.55 : 0.4);
    k.stroke(pth('M', inX + s * 0.4, inY + 0.2, 'Q', ex + s * w * 0.05, y + oL * 1.25 + 0.4, outX, outY + 0.2), 0.55, 0.62);
    if (p.bags) k.stroke(pth('M', ex - w * 0.42, y + oL + 2, 'Q', ex, y + oL + 3.6, ex + w * 0.45, y + oL + 1.7), 0.75, p.bags);
    if (p.old) for (let i = 0; i < 2; i++) k.line(outX + s * 1.6, y - 1 + i * 2, outX + s * 4.4, y - 2.2 + i * 3, 0.6, 0.5);
    // the brow: thick at the inner end, out to a point
    const bi = p.fx + s * p.hw * 0.08, bo = ex + s * w * 0.8, biY = p.yB + 1 - m.brow * 1.8, boY = p.yB + p.btilt * 0.5 + 0.8, bt = p.bt;
    k.path(pth('M', bi, biY, 'Q', ex + s * 0.5, p.yB - p.barch - 0.5 - m.brow * 0.4, bo, boY, 'Q', ex + s * 0.5, p.yB - p.barch + bt - m.brow * 0.4, bi, biY + bt, 'Z'), p.grey ? 0.64 : 0.97);
  }

  function paintTop(j, p, r, body, nb) {
    const k = j.k, rd = j.r, cx = p.cx, sw = p.sw, tp = p.top, ng = p.neck;
    withClip(j, body, function () {
      if (tp === 'hivis') {
        // a dark work shirt under an orange vest, which prints in the red, and its silver bands
        for (const s of [-1, 1]) {
          const v = pth('M', cx + s * sw * 1.2, FH + 2, 'L', cx + s * (sw + 2), nb + 10, 'Q', cx + s * (ng + 10), nb - 5, cx + s * (ng + 2), nb - 5, 'L', cx + s * 7, FH + 2, 'Z');
          rd.path(v, 0.95); k.path(v, s < 0 ? 0.06 : 0.3, 'set');
          k.rect(Math.min(cx + s * 8, cx + s * (sw + 8)), nb + 22, Math.abs(sw), 5, 0.42, 'set');
          k.line(Math.min(cx + s * 8, cx + s * (sw + 8)), nb + 22.8, Math.max(cx + s * 8, cx + s * (sw + 8)), nb + 22.8, 0.7, 0.35, 'erase');
          k.line(cx + s * (ng + 6), nb - 3, cx + s * 16, FH + 2, 4.5, 0.42, 'set');
        }
        rd.rect(cx - sw - 8, nb + 22, 2 * sw + 16, 5, 0.15);
        k.rect(cx - 6.5, nb - 4, 13, FH, 0.92, 'set');
      } else if (tp === 'apron') {
        // a black shirt, the apron's bib over it and the strap round her neck, a pen in its pocket
        k.path(pth('M', cx - 16, FH + 2, 'L', cx - 15, nb + 14, 'L', cx + 15, nb + 14, 'L', cx + 16, FH + 2, 'Z'), k.lin(cx - 16, 0, cx + 16, 0, [[0, 0.3], [1, 0.66]]), 'set');
        k.line(cx - 15, nb + 14, cx - ng + 1, nb - 5, 1.8, 0.35, 'set'); k.line(cx + 15, nb + 14, cx + ng - 1, nb - 5, 1.8, 0.72, 'set');
        k.line(cx - 11, nb + 28, cx + 11, nb + 28, 0.6, 0.62);
        k.rect(cx + 4, nb + 22, 7, 8, 0.52, 'set');
        k.line(cx + 5.5, nb + 22, cx + 5.5, nb + 17, 0.9, 1); rd.line(cx + 8.5, nb + 22, cx + 9, nb + 17.5, 0.9, 0.9);
      } else if (tp === 'whites') {
        k.line(cx - 4, nb + 2, cx + 6, FH, 1, 0.5);
        for (let i = 0; i < 4; i++) k.oval(cx + 10, nb + 12 + i * 10, 1.4, 1.4, 0.8, 'set');
      } else if (tp === 'flannel') {
        // checks: bands both ways, the red in every other one, darker where they cross
        for (let x = cx - sw - 8, i = 0; x < cx + sw + 8; x += 10, i++) { k.rect(x, nb - 8, 3.6, FH, 0.34); if (i % 2) rd.rect(x + 5, nb - 8, 1.4, FH, 0.45); }
        for (let y = nb + 2, i = 0; y < FH; y += 10, i++) { k.rect(cx - sw - 8, y, 2 * sw + 16, 3.6, 0.34); if (i % 2) rd.rect(cx - sw - 8, y + 5, 2 * sw + 16, 1.4, 0.45); }
        k.path(pth('M', cx - ng - 2, nb - 6, 'L', cx - 1.5, nb + 11, 'L', cx - 13, nb + 3, 'Z'), 0.28, 'set');
        k.path(pth('M', cx + ng + 2, nb - 6, 'L', cx + 1.5, nb + 11, 'L', cx + 13, nb + 3, 'Z'), 0.85, 'set');
        k.path(pth('M', cx - 1.5, nb + 11, 'L', cx - ng + 1, nb - 5, 'L', cx + ng - 1, nb - 5, 'L', cx + 1.5, nb + 11, 'Z'), 0.62, 'set');
        k.line(cx, nb + 11, cx, FH, 0.9, 0.95);
        k.oval(cx - 1.6, nb + 20, 1, 1, 0.2, 'set'); k.oval(cx - 1.6, nb + 32, 1, 1, 0.2, 'set');
      } else if (tp === 'suit') {
        // a good white shirt, a tie in the red, the lapels
        k.path(pth('M', cx - 12, nb - 6, 'L', cx + 12, nb - 6, 'L', cx + 3, FH + 2, 'L', cx - 3, FH + 2, 'Z'), 0.06, 'set');
        const tie = pth('M', cx - 2.8, nb, 'L', cx + 2.8, nb, 'L', cx + 4.2, nb + 32, 'L', cx, nb + 38, 'L', cx - 4.2, nb + 32, 'Z');
        rd.path(tie, 0.95); k.path(tie, 0.3, 'set');
        k.path(pth('M', cx - 3.3, nb - 5, 'L', cx + 3.3, nb - 5, 'L', cx + 2.4, nb + 1, 'L', cx - 2.4, nb + 1, 'Z'), 0.6, 'set');
        k.path(pth('M', cx - 13, nb - 6, 'L', cx - 4, nb + 36, 'L', cx - 18, nb + 9, 'Z'), 0.58, 'set');
        k.path(pth('M', cx + 13, nb - 6, 'L', cx + 4, nb + 36, 'L', cx + 18, nb + 9, 'Z'), 0.97, 'set');
        k.line(cx - 13, nb - 6, cx - 4, nb + 36, 0.7, 0.35, 'erase');
      } else if (tp === 'hoodie') {
        if (p.hat !== 'hood') {
          // the hood down, bunched behind the neck
          k.path(pth('M', cx - 24, nb + 3, 'Q', cx, nb - 12, cx + 24, nb + 3, 'Q', cx, nb + 13, cx - 24, nb + 3, 'Z'), k.lin(cx - 24, 0, cx + 24, 0, [[0, 0.42], [1, 0.96]]), 'set');
          k.stroke(pth('M', cx - 24, nb + 3, 'Q', cx, nb + 13, cx + 24, nb + 3), 1.1, 0.95);
        }
        // the strings, and the pocket across the front
        k.line(cx - 5.5, nb + 6, cx - 7, nb + 34, 1.1, 0.12, 'set'); k.line(cx + 5.5, nb + 6, cx + 6.5, nb + 32, 1.1, 0.5, 'set');
        k.oval(cx - 7, nb + 34.8, 1, 1.6, 0.18, 'set'); k.oval(cx + 6.5, nb + 32.8, 1, 1.6, 0.55, 'set');
        k.stroke(pth('M', cx - 20, FH + 2, 'L', cx - 14, nb + 42, 'L', cx + 14, nb + 42, 'L', cx + 20, FH + 2), 0.8, 0.9);
      } else if (tp === 'coat' || tp === 'jacket') {
        // a jacket: the collar up at the back, the zip, the seams
        k.path(pth('M', cx - ng - 4, nb - 12, 'L', cx - 20, nb + 5, 'L', cx - 4, nb + 3, 'Z'), 0.4, 'set');
        k.path(pth('M', cx + ng + 4, nb - 12, 'L', cx + 20, nb + 5, 'L', cx + 4, nb + 3, 'Z'), 0.97, 'set');
        k.line(cx + 1, nb + 3, cx + 1.5, FH + 2, 1.1, 1);
        k.line(cx + 0.1, nb + 3, cx + 0.6, FH + 2, 0.45, 0.42, 'erase');
        k.stroke(pth('M', cx - sw + 9, nb + 14, 'Q', cx - 27, nb + 12, cx - 23, FH + 2), 0.8, 0.6);
        k.stroke(pth('M', cx + sw - 9, nb + 14, 'Q', cx + 27, nb + 12, cx + 23, FH + 2), 0.8, 1);
      } else if (tp === 'cardigan') {
        k.path(pth('M', cx - ng - 1, nb - 6, 'L', cx, nb + 22, 'L', cx + ng + 1, nb - 6, 'Z'), 0.16, 'set');
        k.stroke(pth('M', cx - ng + 2, nb - 5, 'Q', cx, nb + 2, cx + ng - 2, nb - 5), 1, 0.4);
        k.line(cx - ng - 1, nb - 6, cx, nb + 22, 2, 0.85); k.line(cx + ng + 1, nb - 6, cx, nb + 22, 2, 1);
        for (let i = 0; i < 3; i++) k.oval(cx + 0.6, nb + 27 + i * 8, 1.3, 1.3, 0.15, 'set');
        for (let y = nb + 4; y < FH; y += 2.3) k.line(cx - sw - 6, y, cx - 3, y, 0.35, 0.16);
      } else if (tp === 'tshirt') {
        k.stroke(pth('M', cx - ng - 1.5, nb - 5, 'Q', cx, nb + 6, cx + ng + 1.5, nb - 5), 1.8, 0.95);
        k.stroke(pth('M', cx - 34, nb + 12, 'q', 4, 10, 2, 30), 0.7, 0.4);
      }
    });
    // the bar's light along the top of the near shoulder
    k.stroke(pth('M', cx - p.neck - 5, nb - 3, 'C', cx - 22, nb - 2, cx - sw + 8, nb + 2, cx - sw + 0.5, nb + 15), 1.6, 0.5, 'erase');
  }

  function paintHair(j, p, r, layer) {
    const k = j.k, cx = p.cx, hw = p.hw, hh = p.hh, ty = p.ty, ht = p.hairTone, h = p.hair;
    const yT = ty + hh * 0.24;
    if (p.hat) { if (layer === 'front' || p.hat === 'hood') paintHat(j, p, r, layer); return; }
    // the mass of it over the skull, v higher at the crown, down to the hairline hl
    const cap = function (v, hl, dip, sides) {
      const sd = sides == null ? yT + 2 : sides;
      return pth('M', cx - hw - 1.2, sd, 'C', cx - hw * 1.1 - v * 0.3, ty + hh * 0.02 - v * 0.4, cx - hw * 0.62, ty - v, cx, ty - v,
        'C', cx + hw * 0.62, ty - v, cx + hw * 1.1 + v * 0.3, ty + hh * 0.02 - v * 0.4, cx + hw + 1.2, sd,
        'L', cx + hw * 0.96, yT - 1, 'Q', cx + hw * 0.72, hl - dip, cx + hw * 0.4, hl, 'Q', cx, hl - 1.5, cx - hw * 0.4, hl, 'Q', cx - hw * 0.72, hl - dip, cx - hw * 0.96, yT - 1, 'Z');
    };
    // lay it down dark, with the sheen of the bar's light on the near side of the crown
    const mass = function (d, tone) {
      sil(j, d);
      k.path(d, k.lin(cx - hw, 0, cx + hw, 0, [[0, tone - 0.08], [0.4, tone], [1, Math.min(1, tone + 0.04)]]), 'set');
      withClip(j, d, function () { soft(k, cx - hw * 0.42, ty + hh * 0.04, hw * 0.62, hh * 0.1, 0.36, -0.25, true); });
    };
    const strands = function (d, n, x0, x1, y0, len, a) {
      withClip(j, d, function () { for (let i = 0; i < n; i++) { const x = x0 + (x1 - x0) * r(), y = y0 + r() * 6; k.stroke(pth('M', x, y, 'q', 1 + r() * 2, len * 0.5, r() * 3 - 1, len), 0.5, a * (x < cx ? 1 : 0.35), 'erase'); } });
    };
    const burns = function (len, tone) {
      for (const s of [-1, 1]) { const x = cx + s * hw * 0.93; k.path(pth('M', x - s * 0.6, yT - 3, 'L', x + s * 1.8, yT - 3, 'L', x + s * 1.6, yT + len, 'L', x - s * 1.4, yT + len - 1.5, 'Z'), s < 0 ? tone - 0.1 : tone, 'set'); }
    };
    if (layer === 'back') {
      if (h === 'long') {
        for (const s of [-1, 1]) { const d = pth('M', cx + s * (hw + 1), yT, 'Q', cx + s * hw * 1.35, p.cy, cx + s * hw * 1.2, p.cy + 26, 'L', cx + s * hw * 0.62, p.cy + 22, 'Q', cx + s * hw * 0.98, p.cy - 2, cx + s * hw * 0.9, yT + 5, 'Z'); sil(j, d); k.path(d, s < 0 ? ht - 0.2 : ht, 'set'); }
      }
      if (h === 'ponytail') {
        const d = pth('M', cx + hw * 0.55, ty + 5, 'C', cx + hw * 1.5, ty - 2, cx + hw * 1.95, yT + 10, cx + hw * 1.5, p.cy + 24, 'Q', cx + hw * 1.3, p.cy + 30, cx + hw * 1.2, p.cy + 22,
          'C', cx + hw * 1.42, p.cy, cx + hw * 1.3, yT + 10, cx + hw * 0.9, yT + 2, 'Z');
        sil(j, d); k.path(d, k.lin(cx + hw, 0, cx + hw * 1.9, 0, [[0, ht - 0.1], [1, ht]]), 'set');
        withClip(j, d, function () { for (let i = 0; i < 9; i++) k.stroke(pth('M', cx + hw * (0.9 + i * 0.07), ty + 6 + i, 'Q', cx + hw * (1.5 + i * 0.03), yT + 8, cx + hw * (1.3 + i * 0.03), p.cy + 20), 0.5, 0.25, 'erase'); });
      }
      if (h === 'bun') {
        const bx = cx + hw * 0.18, by = ty - 5.5, d = pth('M', bx - 9.5, by, 'A', 9.5, 7.2, 0, 1, 1, bx + 9.5, by, 'A', 9.5, 7.2, 0, 1, 1, bx - 9.5, by, 'Z');
        sil(j, d); k.path(d, ht, 'set');
        withClip(j, d, function () {
          soft(k, bx - 3, by - 3, 6, 3.5, 0.3, -0.3, true);
          for (let i = 0; i < 7; i++) k.stroke(pth('M', bx - 8 + i * 1.4, by + 5, 'Q', bx - 4 + i, by - 8 + i * 0.4, bx + 3 + i * 0.6, by - 4 + i), 0.5, 0.3, 'erase');
        });
      }
      return;
    }
    if (h === 'short' || h === 'parted') {
      const v = p.young ? 4.5 : 3.2, hl = ty + hh * (p.old ? 0.19 : 0.145) + r() * 2, d = cap(v, hl, p.old ? 5 : 2);
      mass(d, ht);
      strands(d, 18, cx - hw, cx + hw * 0.3, ty - v, 8, 0.32);
      if (h === 'parted') {
        k.stroke(pth('M', cx - hw * 0.42, ty - v + 0.5, 'Q', cx - hw * 0.46, ty + 3, cx - hw * 0.38, hl - 1), 1, 0.5, 'erase');
        k.stroke(pth('M', cx - hw * 0.36, hl - 1, 'Q', cx + hw * 0.3, ty + 2, cx + hw * 0.98, hl + 3), 1.6, 0.97);
      }
      burns(p.hh * 0.14, ht);
    } else if (h === 'buzz') {
      const d = cap(1.5, ty + hh * 0.13, 3);
      sil(j, d);
      withClip(j, d, function () {
        k.rect(cx - hw - 3, ty - 4, 2 * hw + 6, hh * 0.4, k.lin(cx - hw, 0, cx + hw, 0, [[0, 0.3], [0.5, 0.45], [1, 0.8]]));
        for (let i = 0; i < 700; i++) { const x = cx - hw - 3 + r() * (2 * hw + 6), y = ty - 4 + r() * hh * 0.4; k.oval(x, y, 0.4, 0.4, x < cx ? 0.7 : 0.95); }
      });
      burns(p.hh * 0.1, 0.62);
    } else if (h === 'messy') {
      // not combed since whenever: a mop over the crown, clumps of it swept down over the forehead
      const ph = r() * 6, ph2 = r() * 6, top = ty - 8, base = yT + 7, N = 28;
      let d = '';
      for (let i = 0; i <= N; i++) {
        const a = Math.PI * (1 + i / N), wob = 1 + 0.05 * Math.sin(a * 5 + ph) + 0.035 * Math.sin(a * 11 + ph2);
        d += pth(i ? 'L' : 'M', cx + Math.cos(a) * (hw + 3.2) * wob, base + Math.sin(a) * (base - top) * wob);
      }
      d += pth('L', cx + hw * 0.95, yT + 1, 'Q', cx + hw * 0.5, ty + hh * 0.16, cx, ty + hh * 0.13, 'Q', cx - hw * 0.6, ty + hh * 0.1, cx - hw * 1.02, yT + 5, 'Z');
      mass(d, ht);
      for (let i = 0; i < 4; i++) {
        const rx = cx + hw * (-0.62 + i * 0.4) + (r() - 0.5) * 3, ry = ty + hh * 0.1, len = hh * (0.13 + r() * 0.06) + (i === 1 || i === 2 ? 3 : 0), wd = 4.2 + r() * 1.6, sw2 = 3 + r() * 3;
        const c = pth('M', rx - wd, ry, 'Q', rx - wd * 0.6, ry + len * 0.7, rx + sw2, ry + len, 'Q', rx + wd * 0.9, ry + len * 0.45, rx + wd, ry, 'Z');
        sil(j, c); k.path(c, k.lin(rx - wd, 0, rx + wd, 0, [[0, ht - 0.1], [1, ht]]), 'set');
        k.stroke(pth('M', rx - wd * 0.3, ry + 1, 'Q', rx - wd * 0.2, ry + len * 0.6, rx + sw2 * 0.8, ry + len - 1), 0.5, 0.3, 'erase');
      }
      strands(d, 22, cx - hw - 2, cx + hw * 0.5, ty - 8, 10, 0.36);
    } else if (h === 'long' || h === 'ponytail' || h === 'bun') {
      // pulled back off the face: the parting, the tie, the strands the night's worked loose
      const d = cap(2.4, ty + hh * 0.11, 1.5, yT + 6);
      mass(d, ht);
      withClip(j, d, function () {
        for (let i = 0; i < 18; i++) { const s = r() < 0.5 ? -1 : 1; k.stroke(pth('M', cx - 1.5, ty - 2, 'Q', cx + s * hw * (0.3 + r() * 0.5), ty + 1, cx + s * hw * (0.85 + r() * 0.2), yT + 4 + r() * 3), 0.5, s < 0 ? 0.4 : 0.14, 'erase'); }
      });
      k.line(cx - 1.5, ty - 2.2, cx - 1, ty + hh * 0.1, 0.9, 0.5, 'erase');
      if (p.old || h === 'bun') for (let i = 0; i < 3; i++) { const s = i ? 1 : -1; k.stroke(pth('M', cx + s * hw * (0.5 + i * 0.12), ty + hh * 0.14, 'q', s * 3, 7, s * 1, 16 + i * 3), 0.5, s < 0 ? 0.55 : 0.85); }
    } else if (h === 'bald' || h === 'thin') {
      const hd = headPath(p);
      withClip(j, hd, function () { soft(k, cx - hw * 0.34, ty + hh * 0.08, hw * 0.46, hh * 0.08, 0.3, -0.15, true); });
      for (const s of [-1, 1]) { const d = pth('M', cx + s * (hw + 1.4), yT + hh * 0.14, 'Q', cx + s * hw * 1.1, yT - 3, cx + s * hw * 0.8, yT - 6, 'L', cx + s * hw * 0.84, yT + 1, 'L', cx + s * hw * 0.93, yT + hh * 0.14, 'Z'); sil(j, d); k.path(d, s < 0 ? ht - 0.2 : ht, 'set'); }
      if (h === 'thin') for (let i = 0; i < 16; i++) { const x = cx - hw * 0.62 + r() * hw * 1.24; k.stroke(pth('M', x, ty + 1.5, 'q', 2 + r() * 2, -1.8, 5 + r() * 3, 1 + r() * 2), 0.45, p.grey ? 0.55 : 0.8); }
    }
  }

  function paintHat(j, p, r, layer) {
    const k = j.k, rd = j.r, cx = p.cx, hw = p.hw, hh = p.hh, ty = p.ty, h = p.hat, hd = headPath(p);
    const yT = ty + hh * 0.24;
    if (h === 'hood') {
      // up. Behind: the back of it and the dark inside it. In front: the fabric round the face,
      // its edge down over the brow and the ears, the sides down onto the chest, and the shadow
      // it puts over the eyes.
      const ho = hw + 5.5, top = ty - 5, low = p.cy + 10;
      const outer = pth('M', cx - ho - 7, low + 5, 'C', cx - ho - 2, p.yE + 10, cx - ho - 1, top + 12, cx - hw * 0.6, top + 1.5, 'Q', cx, top - 2, cx + hw * 0.6, top + 1.5,
        'C', cx + ho + 1, top + 12, cx + ho + 2, p.yE + 10, cx + ho + 7, low + 5, 'Q', cx, low + 12, cx - ho - 7, low + 5, 'Z');
      const oy0 = ty + hh * 0.2, ox = hw * 0.97;
      const open = pth('M', cx - 3, low + 3, 'C', cx - ox * 0.9, p.cy + 2, cx - ox * 1.1, oy0 + 12, cx - ox * 0.45, oy0 + 1, 'Q', cx, oy0 - 2.5, cx + ox * 0.45, oy0 + 1,
        'C', cx + ox * 1.1, oy0 + 12, cx + ox * 0.9, p.cy + 2, cx + 3, low + 3, 'Z');
      const fabric = k.lin(cx - ho, 0, cx + ho, 0, [[0, 0.46], [0.3, 0.56], [0.6, 0.84], [1, 0.9]]);
      if (layer === 'back') { sil(j, outer); k.path(outer, fabric, 'set'); k.path(open, 0.96, 'set'); return; }
      withClip(j, open, function () {
        k.rect(cx - hw - 2, oy0 - 2, 2 * hw + 4, p.yE - oy0 + 8, k.lin(0, oy0, 0, p.yE + 5, [[0, 0.72], [0.55, 0.4], [1, 0]]));
        k.stroke(open, 8, 0.36);
      });
      fillEO(k, outer + ' ' + open, fabric, 'set');
      // the rolled edge round the opening, lit on the near side; the seam over the top; folds
      k.stroke(open, 3.2, k.lin(cx - ho, 0, cx + ho, 0, [[0, 0.3], [0.45, 0.42], [0.7, 0.8], [1, 0.9]]));
      k.stroke(open, 0.8, 0.5, 'erase');
      k.stroke(pth('M', cx + 1, top - 1, 'Q', cx + 1.5, oy0 - 6, cx + 1, oy0 - 1), 0.8, 0.95);
      for (let i = 0; i < 3; i++) k.stroke(pth('M', cx - ho + 1 + i * 1.4, top + 16 + i * 11, 'q', 2.2, 5, 1.1, 10), 0.8, 0.4, 'erase');
      k.stroke(pth('M', cx + ho - 2.5, top + 20, 'q', 1.8, 9, 0, 20), 0.8, 0.45, 'erase');
    } else if (h === 'cap') {
      // a ball cap, the bill's shadow down over the eyes
      const cr = pth('M', cx - hw - 1.6, yT, 'C', cx - hw * 1.1, ty - 2, cx - hw * 0.6, ty - 6, cx, ty - 6, 'C', cx + hw * 0.6, ty - 6, cx + hw * 1.1, ty - 2, cx + hw + 1.6, yT, 'Z');
      withClip(j, hd, function () { k.rect(cx - hw, yT - 2, 2 * hw, p.yE - yT + 7, k.lin(0, yT - 2, 0, p.yE + 5, [[0, 0.66], [0.7, 0.44], [1, 0]])); });
      sil(j, cr);
      k.path(cr, k.lin(cx - hw, 0, cx + hw, 0, [[0, 0.5], [0.4, 0.74], [1, 0.95]]), 'set');
      k.stroke(pth('M', cx, ty - 6, 'L', cx, yT), 0.6, 0.35, 'erase');
      k.stroke(pth('M', cx - hw * 0.55, ty - 3.5, 'Q', cx - hw * 0.62, yT - 5, cx - hw * 0.66, yT), 0.5, 0.3, 'erase');
      k.oval(cx, ty - 5.6, 1.6, 0.9, 0.95, 'set');
      const bill = pth('M', cx - hw * 1.12, yT - 1.5, 'Q', cx, yT - 6, cx + hw * 1.12, yT - 1.5, 'Q', cx + hw * 0.92, yT + 6.5, cx, yT + 7, 'Q', cx - hw * 0.92, yT + 6.5, cx - hw * 1.12, yT - 1.5, 'Z');
      sil(j, bill); k.path(bill, 0.97, 'set');
      k.stroke(pth('M', cx - hw * 1.1, yT - 1.2, 'Q', cx, yT - 5.6, cx + hw * 0.2, yT - 4.4), 0.9, 0.5, 'erase');
    } else if (h === 'flatcap') {
      // a flat cap, tweed, the short brim low over the eyes
      const cr = pth('M', cx - hw - 2, yT - 2, 'C', cx - hw * 1.1, ty + 1, cx - hw * 0.5, ty - 5, cx + hw * 0.3, ty - 4.5, 'C', cx + hw * 1.1, ty - 3.5, cx + hw * 1.26, ty + 4, cx + hw + 2, yT - 2, 'Z');
      withClip(j, hd, function () { k.rect(cx - hw, yT - 3, 2 * hw, 12, k.lin(0, yT - 3, 0, yT + 9, [[0, 0.6], [1, 0]])); });
      sil(j, cr);
      k.path(cr, k.lin(cx - hw, 0, cx + hw, 0, [[0, 0.46], [0.45, 0.68], [1, 0.92]]), 'set');
      withClip(j, cr, function () { for (let i = 0; i < 260; i++) { const x = cx - hw - 2 + r() * (2 * hw + 4), y = ty - 6 + r() * 22; k.line(x, y, x + 1.3, y + 0.7, 0.4, r() < 0.5 ? 0.9 : 0.25, r() < 0.5 ? 'ink' : 'erase'); } });
      const brim = pth('M', cx - hw * 1.04, yT - 2, 'Q', cx, yT - 5, cx + hw * 1.04, yT - 2, 'Q', cx, yT + 3.6, cx - hw * 1.04, yT - 2, 'Z');
      sil(j, brim); k.path(brim, 0.96, 'set');
    } else if (h === 'beanie') {
      const cr = pth('M', cx - hw - 1.6, yT + 1, 'C', cx - hw * 1.1, ty - 7, cx - hw * 0.5, ty - 10, cx, ty - 10, 'C', cx + hw * 0.5, ty - 10, cx + hw * 1.1, ty - 7, cx + hw + 1.6, yT + 1, 'Z');
      sil(j, cr);
      k.path(cr, k.lin(cx - hw, 0, cx + hw, 0, [[0, 0.52], [1, 0.95]]), 'set');
      k.rect(cx - hw - 1.6, yT - 6, 2 * hw + 3.2, 7, k.lin(cx - hw, 0, cx + hw, 0, [[0, 0.42], [1, 0.97]]), 'set');
      for (let x = cx - hw; x < cx + hw; x += 2.4) k.line(x, yT - 6, x, yT + 1, 0.55, x < cx ? 0.8 : 0.3, x < cx ? 'ink' : 'erase');
    } else if (h === 'bandana') {
      const cr = pth('M', cx - hw - 1, yT, 'C', cx - hw * 1.06, ty + 2, cx - hw * 0.6, ty - 3, cx, ty - 3, 'C', cx + hw * 0.6, ty - 3, cx + hw * 1.06, ty + 2, cx + hw + 1, yT, 'Q', cx, ty + 9, cx - hw - 1, yT, 'Z');
      sil(j, cr);
      k.path(cr, 0.8, 'set'); rd.path(cr, 0.6);
      for (let i = 0; i < 40; i++) k.oval(cx - hw + r() * 2 * hw, ty - 2 + r() * 10, 0.6, 0.6, 0.3, 'erase');
    }
  }

  function paintFaceBits(j, p, r) {
    const k = j.k, rd = j.r, cx = p.cx, fx = p.fx, f = p.face, hw = p.hw, hh = p.hh;
    // the lower face, cheek to cheek under the nose, grown out by g, the mouth left out
    const lower = function (g, lipGap) {
      const cw = p.cw + g * 0.6, jw = p.jw + p.jowl + g;
      return pth('M', cx - hw * 0.97 - g * 0.5, p.yE + hh * 0.12, 'C', cx - hw * 0.98 - g, p.yE + hh * 0.22, cx - jw * 1.02, p.yJ - hh * 0.08, cx - jw, p.yJ,
        'C', cx - jw * 0.94, p.yJ + hh * 0.08, cx - cw * 1.3, p.cy - hh * 0.03 + g, cx - cw, p.cy - hh * 0.012 + g, 'Q', cx - cw * 0.55, p.cy + 0.4 + g, cx, p.cy + g,
        'Q', cx + cw * 0.55, p.cy + 0.4 + g, cx + cw, p.cy - hh * 0.012 + g, 'C', cx + cw * 1.3, p.cy - hh * 0.03 + g, cx + jw * 0.94, p.yJ + hh * 0.08, cx + jw, p.yJ,
        'C', cx + jw * 1.02, p.yJ - hh * 0.08, cx + hw * 0.98 + g, p.yE + hh * 0.22, cx + hw * 0.97 + g * 0.5, p.yE + hh * 0.12,
        'L', cx + hw * 0.82, p.yE + hh * 0.13, 'Q', fx + hw * 0.5, p.yN + 2, fx + p.mw + 2.4, p.yM - lipGap, 'Q', fx, p.yN + 1.4, fx - p.mw - 2.4, p.yM - lipGap, 'Q', fx - hw * 0.5, p.yN + 2, cx - hw * 0.82, p.yE + hh * 0.13, 'Z');
    };
    if (f.indexOf('beard') >= 0) {
      // full, up the cheeks to the ears and over the lip; the mouth a line in it
      const d = lower(3.5, 3.6);
      sil(j, d);
      k.path(d, k.lin(cx - hw, 0, cx + hw, 0, [[0, 0.56], [0.45, 0.76], [0.7, 0.95], [1, 0.97]]), 'set');
      withClip(j, d, function () {
        for (let i = 0; i < 220; i++) { const x = cx - hw - 2 + r() * (2 * hw + 4) * 0.7, y = p.yN - 2 + r() * (p.cy - p.yN + 6); k.stroke(pth('M', x, y, 'q', (r() - 0.5) * 2, 2.2, (r() - 0.5) * 2.4, 4.6), 0.45, 0.42, 'erase'); }
        for (let i = 0; i < 60; i++) { const x = cx + r() * hw, y = p.yN + r() * (p.cy - p.yN); k.stroke(pth('M', x, y, 'q', (r() - 0.5) * 2, 2, (r() - 0.5) * 2, 4), 0.4, 0.5); }
      });
      k.stroke(pth('M', fx - p.mw + 0.6, p.yM + 0.6 - p.mood.smile, 'Q', fx, p.yM + 1.8, fx + p.mw - 0.6, p.yM + 0.6 - p.mood.smile), 1.5, 1);
      soft(k, fx - 1.2, p.yM + 2.8, p.mw * 0.45, 1, 0.34, 0, true);
    } else if (f.indexOf('stubble') >= 0) {
      const d = lower(0.2, 2.4);
      withClip(j, d, function () {
        k.rect(cx - hw, p.yN - 4, 2 * hw, p.cy - p.yN + 6, 0.12);
        for (let i = 0; i < 900; i++) { const x = cx - hw + r() * 2 * hw, y = p.yN - 3 + r() * (p.cy - p.yN + 5); if (Math.abs(x - fx) < p.mw + 0.6 && Math.abs(y - p.yM - 0.5) < p.lip + 1) continue; k.oval(x, y, 0.34, 0.34, 0.8); }
      });
    }
    if (f.indexOf('moustache') >= 0) k.path(pth('M', fx - p.mw - 2, p.yM + 1.4, 'Q', fx - p.mw * 0.6, p.yN + 1.4, fx, p.yN + 2.8, 'Q', fx + p.mw * 0.6, p.yN + 1.4, fx + p.mw + 2, p.yM + 1.4, 'Q', fx, p.yM - 1.4, fx - p.mw - 2, p.yM + 1.4, 'Z'), p.grey ? 0.62 : 0.92, 'set');
    if (f.indexOf('glasses') >= 0) {
      for (const s of [-1, 1]) {
        const e = eyeAt(p, s), gw = e.w + 5.6, gh = hh * 0.13, gx = e.x - gw / 2, gy = p.yE - gh * 0.52;
        k.rect(gx, gy, gw, gh, 0.08, 'erase');
        k.stroke(pth('M', gx, gy + 1.2, 'Q', gx, gy, gx + 1.2, gy, 'L', gx + gw - 1.2, gy, 'Q', gx + gw, gy, gx + gw, gy + 1.2, 'L', gx + gw - 0.3, gy + gh - 1.6, 'Q', gx + gw - 0.8, gy + gh, gx + gw - 2.4, gy + gh,
          'L', gx + 2.4, gy + gh, 'Q', gx + 0.8, gy + gh, gx + 0.3, gy + gh - 1.6, 'Z'), 1.2, 0.97);
        k.line(gx + 2, gy + gh - 2, gx + 5.4, gy + 1.6, 0.8, s < 0 ? 0.75 : 0.4, 'erase');
        if (s > 0) rd.line(gx + gw - 0.4, gy + 1, gx + gw - 0.6, gy + gh - 1, 0.9, 0.85);
      }
      const eL = eyeAt(p, -1), eR = eyeAt(p, 1);
      k.stroke(pth('M', eL.x + eL.w / 2 + 2.8, p.yE - 2.6, 'Q', fx, p.yE - 4.6, eR.x - eR.w / 2 - 2.8, p.yE - 2.6), 1.1, 0.97);
      k.line(eL.x - eL.w / 2 - 2.8, p.yE - 2.8, cx - hw - 1.4, p.yE - 0.6, 1.1, 0.9); k.line(eR.x + eR.w / 2 + 2.8, p.yE - 2.8, cx + hw + 1.4, p.yE - 0.6, 1.1, 0.9);
    }
    if (f.indexOf('earbuds') >= 0) {
      // the white stem of one showing under the ear
      const ex = p.hat === 'hood' ? cx - hw * 0.86 : cx - hw - 1.2, ey = p.yE + hh * 0.08;
      k.path(pth('M', ex - 1.4, ey - 1.6, 'Q', ex, ey - 3.4, ex + 1.4, ey - 1.6, 'L', ex + 0.9, ey + 5.2, 'Q', ex, ey + 6, ex - 0.9, ey + 5.2, 'Z'), 0.02, 'set');
      k.stroke(pth('M', ex + 0.9, ey - 1, 'L', ex + 0.6, ey + 5), 0.5, 0.35);
    }
    if (f.indexOf('hearingaid') >= 0) { const hx = cx + hw + 3, hy = p.yE + hh * 0.02; k.stroke(pth('M', hx, hy, 'q', 3.4, 2.4, 1.6, 9.4), 1.8, 0.5); rd.stroke(pth('M', hx + 1, hy + 0.5, 'q', 2.8, 2.2, 1.2, 8.2), 0.7, 0.85); }
  }

  function paintExtras(j, p, r, nb) {
    const k = j.k, rd = j.r, cx = p.cx, x = p.extra;
    // a hand coming up at the bottom of the frame, knuckles toward you, lit from the left
    const hand = function (hx, hy, s, flip) {
      const f = flip ? -1 : 1;
      const d = pth('M', hx - 8 * s * f, FH + 2, 'L', hx - 8.5 * s * f, hy + 5 * s, 'Q', hx - 8 * s * f, hy - 3.5 * s, hx - 1.5 * s * f, hy - 4 * s,
        'L', hx + 5.5 * s * f, hy - 3 * s, 'Q', hx + 9 * s * f, hy - 1.4 * s, hx + 8.5 * s * f, hy + 3.5 * s, 'L', hx + 8 * s * f, FH + 2, 'Z');
      sil(j, d);
      k.path(d, k.lin(hx - 9 * s, 0, hx + 9 * s, 0, flip ? [[0, 0.78], [0.45, p.skin + 0.3], [1, p.skin + 0.1]] : [[0, p.skin + 0.1], [0.55, p.skin + 0.3], [1, 0.8]]), 'set');
      for (let i = 0; i < 3; i++) k.line(hx + (-4.4 + i * 3.8) * s * f, hy - 3 * s, hx + (-5 + i * 3.8) * s * f, hy + 3.4 * s, 0.6, 0.55);
    };
    if (x.indexOf('vape') >= 0) {
      // the thing in his hand, and what he's just breathed out hanging in the red
      hand(cx + 31, 138, 1.1);
      const v = pth('M', cx + 28.4, 135, 'L', cx + 30.2, 113, 'L', cx + 34.6, 113.4, 'L', cx + 33.2, 135.4, 'Z');
      sil(j, v); k.path(v, 0.92, 'set'); k.line(cx + 30.6, 115, cx + 29.6, 133, 0.7, 0.4, 'erase'); rd.oval(cx + 32.4, 115.4, 1.1, 1.1, 1);
      for (let i = 0; i < 8; i++) { const t = i / 7, x0 = p.fx + 7 + t * 36 + (r() - 0.5) * 6, y0 = p.yM + 3 - t * 34 + (r() - 0.5) * 5, rr = 5 + t * 9; k.light(x0, y0, rr, 0.5 - t * 0.2, rr * 0.7); rd.glow(x0, y0, rr, 0.2); }
    }
    if (x.indexOf('cigarette') >= 0) {
      k.line(p.fx + 2, p.yM + 1, p.fx + 15, p.yM + 4, 1.6, 0.05, 'set'); rd.oval(p.fx + 15.6, p.yM + 4.1, 1.2, 1.2, 1); rd.glow(p.fx + 15.6, p.yM + 4.1, 6, 0.6);
      for (let i = 0; i < 6; i++) k.light(p.fx + 17 + r() * 3, p.yM - 4 - i * 7, 4 + i, 0.14);
    }
    if (x.indexOf('phone') >= 0) {
      // held low, the screen on: its light up under the chin
      hand(cx - 27, 140, 1.1);
      const ph = pth('M', cx - 33, 126, 'L', cx - 20, 124, 'L', cx - 19, 142, 'L', cx - 32, 144, 'Z');
      sil(j, ph); k.path(ph, 1, 'set');
      k.path(pth('M', cx - 32, 127, 'L', cx - 21, 125.4, 'L', cx - 20.2, 141, 'L', cx - 31.2, 142.6, 'Z'), 0.06, 'set');
      k.rect(cx - 30, 130, 7, 5.5, 0.5, 'set'); k.rect(cx - 30, 137, 5, 1.1, 0.6, 'set');
      k.light(cx - 14, p.cy + 3, 20, 0.34, 10);
      k.light(p.fx - 6, p.yM + 5, 12, 0.18, 6);
    }
    if (x.indexOf('keys') >= 0) {
      hand(cx - 34, 140, 1.05);
      k.line(cx - 33, 134, cx - 33, 141, 0.9, 0.9);
      k.stroke(pth('M', cx - 35.8, 132.5, 'a', 2.8, 2.8, 0, 1, 0, 5.6, 0, 'a', 2.8, 2.8, 0, 1, 0, -5.6, 0), 0.8, 0.95);
      for (const kx of [[-38, 149], [-31, 150], [-34.5, 151]]) { k.line(cx - 33, 135, cx + kx[0], kx[1], 1.6, 0.45, 'set'); k.line(cx - 33.4, 135, cx + kx[0] - 0.4, kx[1], 0.5, 0.6, 'erase'); }
      rd.rect(cx - 29, 143, 5.5, 7, 0.9);
    }
    if (x.indexOf('knife') >= 0) {
      // the bar knife, for the limes, point up, a wedge of one stuck to the blade
      hand(cx + 33, 144, 1.1, true);
      const bl = pth('M', cx + 33, 137, 'L', cx + 31.4, 112, 'Q', cx + 33.8, 110, cx + 35.2, 113, 'L', cx + 35.2, 137, 'Z');
      sil(j, bl); k.path(bl, 0.1, 'set');
      k.line(cx + 34.6, 114, cx + 35, 136, 0.7, 0.62);
      k.rect(cx + 31.6, 137, 4.4, 6, 0.95, 'set');
      k.path(pth('M', cx + 31, 121, 'q', -6, 1.2, -7, 7, 'q', 6, 0, 7, -3.6, 'Z'), 0.5, 'set');
      k.stroke(pth('M', cx + 30.6, 121.6, 'q', -4.8, 1.2, -5.8, 5.6), 0.6, 0.2, 'erase');
    }
    if (p.face.indexOf('necktat') >= 0) {
      // a star on the side of his neck, and the script under it that goes round to the front
      const tx = cx - p.neck * 0.48, ty = (p.cy + nb) / 2 - 0.5, R = 5.8;
      let st = '';
      for (let i = 0; i < 10; i++) { const a = -Math.PI / 2 + i * Math.PI / 5, rr = i % 2 ? R * 0.42 : R; st += (i ? 'L' : 'M') + ' ' + (tx + Math.cos(a) * rr) + ' ' + (ty + Math.sin(a) * rr) + ' '; }
      k.path(st + 'Z', 0.94, 'set');
      k.stroke(pth('M', tx - 5, nb - 1.6, 'q', 2, -2.6, 3.4, 0, 'q', 1.4, 2.4, 3, -0.4, 'q', 1.6, -2.4, 3.2, 0.2, 'q', 1.2, 2, 3, -0.6), 1.5, 0.92);
    }
    if (x.indexOf('lanyard') >= 0) { k.stroke(pth('M', cx - 9, nb - 3, 'L', cx, nb + 24, 'L', cx + 9, nb - 3), 1, 0.9); k.rect(cx - 5, nb + 24, 10, 13, 0.1, 'set'); rd.rect(cx - 5, nb + 24, 10, 3, 0.9); }
  }

  // the room behind them: dark behind the lit side, the bar's lights out of focus and the sign's
  // glow behind the dark side
  function paintGround(j, r, plain) {
    const k = j.k, rd = j.r;
    if (plain) {
      // the backdrop they stand you against for a licence: flat and pale, the same for everybody.
      // It takes the same draws from r as the room would, so the face that follows is the same face.
      k.rect(0, 0, FW, FH, k.lin(0, 0, 0, FH, [[0, 0.14], [1, 0.24]]), 'set');
      for (let i = 0; i < 35; i++) r();
      return;
    }
    k.rect(0, 0, FW, FH, k.lin(0, 0, FW, 0, [[0, 0.93], [0.4, 0.87], [0.75, 0.72], [1, 0.64]]), 'set');
    k.rect(0, 0, FW, FH, k.lin(0, 0, 0, FH, [[0, 0.06], [0.6, 0], [1, 0.12]]));
    for (let i = 0; i < 7; i++) { const x = 70 + r() * 50, y = 6 + r() * 70, rr = 3 + r() * 6; k.light(x, y, rr, 0.1 + r() * 0.12); if (r() < 0.6) rd.glow(x, y, rr * 1.3, 0.35); }
    rd.glow(FW + 4, 40, 70, 0.66);
  }

  function faceVignette(k) {
    k.rect(0, 0, FW, FH, k.rad(FW * 0.46, FH * 0.42, FW * 0.42, FW * 0.98, [[0, 0], [1, 0.3]]));
    const c = k.c; c.save(); c.fillStyle = '#000'; c.beginPath(); c.rect(0, 0, FW, FH); c.rect(1.6, 1.6, FW - 3.2, FH - 3.2); c.fill('evenodd'); c.restore();
  }

  // look.ground 'plain' is an ID photo: the same person, against the pale backdrop, flat lit, no
  // mood on their face and nothing in their hands (content/data/props.yaml)
  function paintFace(j, id, look) {
    const r = rng(seedOf('face:' + id));
    const plain = !!(look && look.ground === 'plain');
    paintGround(j, r, plain);
    if (look && look.group) { paintTable(j, id, look, r); return; }
    const p = planFace(id, plain ? Object.assign({}, look, { mood: 'flat', lean: null, extra: [] }) : look, r);
    p.flat = plain;
    paintBust(j, p, r);
    if (!plain) faceVignette(j.k);
  }

  // table 28 as one: the five of them close in round the table, the glasses in front. Each one's
  // look comes from their own entry in characters.yaml; these are the fallbacks.
  const T28 = [
    ['cardigan', 27, 62, 0.56, { age: 'old', hair: 'parted', top: 'cardigan' }],
    ['hearing_aid', 94, 63, 0.56, { age: 'old', hair: 'bald', top: 'flannel', face: ['hearingaid'] }],
    ['scratch', 60, 55, 0.52, { age: 'old', hat: 'cap', top: 'coat', face: ['stubble'], mood: 'tired' }],
    ['team_jacket', 36, 92, 0.64, { age: 'old', hair: 'thin', top: 'jacket', mood: 'smile' }],
    ['glasses', 85, 93, 0.64, { age: 'old', hair: 'short', top: 'tshirt', face: ['glasses', 'moustache'], mood: 'drunk' }]
  ];
  function paintTable(j, id, look0, r) {
    const k = j.k, rd = j.r, C = (globalThis.BOUNCER_CONTENT && globalThis.BOUNCER_CONTENT.characters) || {};
    const dry = PR.job(FW, FH, j.scale);
    for (const m of T28) {
      const base = (C[m[0]] && C[m[0]].look) || m[4];
      const look = look0 && look0.lean ? Object.assign({}, base, { lean: look0.lean }) : base;
      // a dry run for the silhouette, to take the red out from under them; then for real
      for (const jj of [dry, j]) {
        const rr = rng(seedOf('face:' + m[0])), p = planFace(m[0], look, rr);
        for (const pen of [jj.k, jj.r]) { pen.c.save(); pen.c.translate(m[1], m[2]); pen.c.scale(m[3], m[3]); pen.c.translate(-60, -60); }
        try { paintBust(jj, p, rr); } finally { jj.k.c.restore(); jj.r.c.restore(); }
        if (jj === dry) { const c = rd.c; c.save(); c.setTransform(1, 0, 0, 1, 0, 0); c.globalCompositeOperation = 'destination-out'; c.drawImage(SIL.c, 0, 0); c.restore(); }
      }
    }
    // the table: its top in the light, the edge, the pints on it
    k.rect(0, 122, FW, FH - 122, k.lin(0, 122, 0, FH, [[0, 0.46], [0.3, 0.6], [0.34, 0.95], [1, 0.97]]), 'set');
    k.line(0, 122.4, FW, 122.4, 1, 0.3, 'erase');
    rd.rect(0, 122, FW, 10, rd.lin(0, 0, FW, 0, [[0.6, 0], [1, 0.3]]));
    for (const g of [[16, 0.3], [37, 0.7], [56, 0.15], [79, 0.55], [101, 0.4]]) {
      const x = g[0] + r() * 3, y = 136 + r() * 2, w = 5.6, h = 17, lvl = g[1];
      const glass = pth('M', x - w, y - h, 'L', x + w, y - h, 'L', x + w * 0.8, y, 'L', x - w * 0.8, y, 'Z');
      k.path(glass, 0.5, 'set');
      const top = y - h * lvl, bw = w * 0.8 + w * 0.2 * lvl;
      if (lvl > 0.1) {
        const beer = pth('M', x - bw, top, 'L', x + bw, top, 'L', x + w * 0.8, y, 'L', x - w * 0.8, y, 'Z');
        k.path(beer, 0.4, 'set'); rd.path(beer, 0.3);
        k.rect(x - bw, top - 1.2, bw * 2, 1.6, 0.06, 'set');
      }
      k.stroke(pth('M', x - w * 0.95, y - h * 0.9, 'L', x - w * 0.95, y - h * 0.97), 0.6, 0.4, 'erase');
      k.line(x - w * 0.68, y - h + 1.5, x - w * 0.56, y - 1.5, 1, 0.9, 'erase');
      k.line(x - w, y - h, x + w, y - h, 0.8, 0.9);
      k.oval(x + 1, y + 0.8, w * 1.1, 1.1, 0.55);
    }
    faceVignette(k);
  }

  // ---------------------------------------------------------------- the rest (see below)

  const CAPTIONS = {
    lot: 'The Sovereign Hotel', floor: 'The room', door: 'The front door', bar: 'The bar', t28: 'Table 28',
    pool: 'The pool table', hall: 'The back hall', kitchen: 'The kitchen', keg: 'The keg room', deck: 'The deck', upstairs: 'The room upstairs',
    office: 'Van Dusen Holdings', street: 'The main street'
  };

  // What each plate shows of the night, in steps, from Game._plateState. Plates with the same look
  // are the same picture.
  const LOOK = {
    // after close the sign's off and one window upstairs is lit; a truck is left if he kept the keys
    lot: function (st) { return (st.clock || 0) >= 1590 ? { closed: true, truck: !!st.keys } : {}; },
    floor: function (st) { return { crowd: clamp(Math.round(((st.n || 13) - 10) / 6), 0, 9), glasses: clamp((st.rounds || 3) + 2, 3, 12) }; },
    bar: function (st) { return { crowd: clamp(Math.round((st.n || 13) / 11), 0, 6) }; },
    t28: function (st) { return { glasses: clamp((st.rounds || 3) * 2, 4, 16), rat: st.walter !== 0 }; },
    pool: function (st) { return { watched: (st.heat || 0) >= 5 }; },
    keg: function (st) { return { eyes: clamp(1 + Math.floor(Math.log2(Math.max(30, st.rats || 30) / 30)), 1, 6) }; },
    kitchen: function (st) { return { open: st.kitchen !== false, cook: st.clock == null || st.clock < 1380 }; },
    deck: function (st) { return { open: st.deck !== false }; },
    hall: function (st) { return { open: st.hotel !== false }; },
    // the office goes from the grey of the afternoon to the lamp as the day goes out of the window
    office: function (st) { return (st.clock || 0) >= 990 ? { dusk: true } : {}; },
    // the street's in the last of the light till six, then it's the lamps
    street: function (st) { return (st.clock || 0) >= 1080 ? { night: true } : {}; }
  };
  // places whose light changes when the house lights come up and after close
  const LIT = { floor: 1, bar: 1, t28: 1, pool: 1, door: 1 };

  function lookOf(id, state, phase) {
    const look = LOOK[id] ? LOOK[id](state || {}) : {};
    if (LIT[id]) look.light = phase === 'lights' ? 'house' : phase === 'after' ? 'dark' : 'night';
    return look;
  }

  // ---------------------------------------------------------------- printing, and a queue so a
  // long night of plates doesn't hold the page up. Each picture is printed once, kept as a JPEG,
  // and every copy of it in the log (the plate, the small strip, the same face again) shares it.

  const urls = {};                                  // key -> image URL, once printed
  const waiting = {};                               // key -> <img>s to fill when it is
  const queue = [];                                 // jobs; the newest is printed first
  let busy = false, holdUntil = 0;

  function printPlace(id, look) {
    const j = PR.job(W, H, 2);
    PLACES[id](j, look, rng(seedOf('plate:' + id)));
    return PR.press(j, { cell: 4.6 });
  }

  function printFace(id, look, cell) {
    const j = PR.job(FW, FH, 2);
    paintFace(j, id, look);
    return PR.press(j, { cell: cell || 4.2 });
  }

  function toUrl(cv) {
    return new Promise(function (done) {
      const data = function () { try { done(cv.toDataURL('image/jpeg', 0.92)); } catch (e) { done(null); } };
      if (!cv.toBlob || !globalThis.URL || !URL.createObjectURL) { data(); return; }
      cv.toBlob(function (b) { if (b) done(URL.createObjectURL(b)); else data(); }, 'image/jpeg', 0.92);
    });
  }

  function fill(key, url) {
    if (url) urls[key] = url;
    for (const img of waiting[key] || []) {
      if (url) { img.src = url; img.classList.add('inked'); } else img.classList.add('blank');
    }
    delete waiting[key];
  }

  function pump() {
    if (busy || !queue.length) return;
    const wait = holdUntil - Date.now();
    if (wait > 0) { setTimeout(pump, Math.min(wait, 1000) + 30); return; }
    busy = true;
    const job = queue.pop();
    const next = function () { busy = false; if (queue.length) setTimeout(pump, 40); };
    const go = function () {
      let cv = null;
      try { cv = job.make(); } catch (e) { cv = null; }          // a print that fails stays paper
      if (!cv) { fill(job.key, null); next(); return; }
      toUrl(cv).then(function (url) { fill(job.key, url); next(); });
    };
    if (!pump.fontsOk) fontsReady().then(function () { pump.fontsOk = true; setTimeout(go, 0); }, function () { setTimeout(go, 0); });
    else setTimeout(go, 0);
  }

  // the signs are lettered in the page's own condensed faces
  function fontsReady() {
    const f = globalThis.document && document.fonts;
    if (!f || !f.load) return Promise.resolve();
    return Promise.all([f.load('600 20px "Barlow Condensed"'), f.load('700 20px "Big Shoulders Display"')]).catch(function () {});
  }

  // an <img> for a picture: filled at once if it's been printed, otherwise when its turn comes
  function order(key, make, img) {
    img = img || document.createElement('img');
    img.alt = img.alt || '';
    img.decoding = 'async';
    if (urls[key]) { img.src = urls[key]; img.classList.add('inked', 'kept'); return img; }
    (waiting[key] = waiting[key] || []).push(img);
    const at = queue.findIndex(function (q) { return q.key === key; });
    queue.push(at < 0 ? { key: key, make: make } : queue.splice(at, 1)[0]);
    pump();
    return img;
  }

  function placeKey(id, look) { return 'pl:' + id + JSON.stringify(look); }
  function faceKey(id, look) { return 'po:' + id + JSON.stringify(look || {}); }

  B.Plates = {
    places: Object.keys(PLACES),
    has: function (id) { return !!PLACES[id]; },
    caption: function (id) { return CAPTIONS[id] || ''; },
    // what a plate of the place shows now: the night's state, and the hour's light
    look: lookOf,
    // <img>s: a place as the night has it, a person from their look
    place: function (id, state, phase, img) {
      if (!PLACES[id]) return null;
      const look = lookOf(id, state, phase);
      return order(placeKey(id, look), function () { return printPlace(id, look); }, img);
    },
    portrait: function (id, look, img) {
      return order(faceKey(id, look), function () { return printFace(id, look || {}); }, img);
    },
    // print ahead, while nothing's happening (the first places of the night)
    prewarm: function (list) {
      for (const it of list || []) {
        const key = it.face ? faceKey(it.face, it.look) : placeKey(it.place, lookOf(it.place, it.state || {}, it.phase));
        if (urls[key] || waiting[key]) continue;
        waiting[key] = [];
        queue.unshift({ key: key, make: it.face ? function () { return printFace(it.face, it.look || {}); } : function () { return printPlace(it.place, lookOf(it.place, it.state || {}, it.phase)); } });
      }
      pump();
    },
    // hold the press while the dice are in the air (ms; 0 lets it go)
    hold: function (ms) { holdUntil = ms ? Date.now() + ms : 0; if (!ms) pump(); },
    // for tests and the bench: print now, no queue
    printNow: function (id, look) { return printPlace(id, look || {}); },
    printFaceNow: function (id, look, cell) { return printFace(id, look || {}, cell); },
    fontsReady: fontsReady,
    _PLACES: PLACES
  };
})(globalThis.Bouncer = globalThis.Bouncer || {});
