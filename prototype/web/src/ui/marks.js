// Marks: a voice's pen on a printed picture.
//
// When a line carries a mark (`mark` on a line item: from barks.yaml, or a #mark: tag in the Ink),
// the page pulls that part of the place's picture out under the line, zoomed in, and the voice
// marks it in its own hand, drawn on as you watch: the Fighter's fast ring that runs past where it
// started, the Father's steady one and his double underline, the Manual's ruled box with its label
// in capitals, the Wrong Man's broken ring that never quite closes, the Table's big loose loops,
// the Kid's small careful one. The spots are in content/data/marks.yaml.
//
//   Marks.node(mark, style, opts)   a <figure>: the detail and the marks. opts: { phase, draw,
//                                   delay (ms before the pen starts), audio }
(function (B) {
  'use strict';

  const NS = 'http://www.w3.org/2000/svg';
  const W = 640, H = 220;

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
  const f1 = function (n) { return Math.round(n * 10) / 10; };

  // How each voice holds the pen. w: stroke width in screen pixels; turns: how far round a ring
  // goes (past 1 overshoots, under 1 leaves it open); wob: how much the line wanders; dots: a
  // broken line; ruled: straight edges; ms: how long the stroke takes; tilt: how the detail sits.
  const HAND = {
    father:   { w: 2.3, turns: 1.08, wob: 0.035, ms: 760, tilt: -0.7, under: 2 },
    fighter:  { w: 3.4, turns: 1.24, wob: 0.075, ms: 360, tilt: -1.6 },
    manual:   { w: 1.6, turns: 1, wob: 0, ms: 950, tilt: 0.2, ruled: true },
    wrongman: { w: 2, turns: 0.86, wob: 0.06, ms: 1250, tilt: 1.2, dots: true },
    table:    { w: 3.8, turns: 1.45, wob: 0.1, ms: 520, tilt: -2.3 },
    kid:      { w: 1.4, turns: 1.02, wob: 0.03, ms: 900, tilt: 0.8 }
  };

  // smooth wandering, the same every time for the same mark
  function wander(r, amt) {
    const p1 = r() * 6.28, p2 = r() * 6.28, p3 = r() * 6.28;
    return function (a) { return 1 + amt * (Math.sin(a * 2 + p1) * 0.55 + Math.sin(a * 3 + p2) * 0.3 + Math.sin(a * 7 + p3) * 0.15); };
  }

  function pts2d(pts) {
    let d = '';
    pts.forEach(function (p, i) { d += (i ? ' L' : 'M') + f1(p[0]) + ' ' + f1(p[1]); });
    return d;
  }

  // a broken line: every other stretch of the path, as its own short stroke
  function broken(pts, on, off) {
    let d = '', run = 0, drawing = true, prev = null;
    for (const p of pts) {
      if (prev) {
        const seg = Math.hypot(p[0] - prev[0], p[1] - prev[1]);
        run += seg;
        if (drawing) d += ' L' + f1(p[0]) + ' ' + f1(p[1]);
        if (run >= (drawing ? on : off)) { run = 0; drawing = !drawing; if (drawing) d += ' M' + f1(p[0]) + ' ' + f1(p[1]); }
      } else d += 'M' + f1(p[0]) + ' ' + f1(p[1]);
      prev = p;
    }
    return d;
  }

  function ring(v, h, r) {
    const cx = v[0], cy = v[1], rx = v[2], ry = v[3];
    if (h.ruled) return box([cx - rx, cy - ry, rx * 2, ry * 2], h, r);
    const wob = wander(r, h.wob);
    const start = -Math.PI * (0.55 + r() * 0.35);
    const n = Math.round(56 * h.turns);
    const pts = [];
    for (let i = 0; i <= n; i++) {
      const t = i / n, a = start + t * h.turns * Math.PI * 2;
      const grow = 1 + (t - 0.5) * Math.max(0, h.turns - 1) * 0.45;
      const k = wob(a) * grow;
      pts.push([cx + Math.cos(a) * rx * k, cy + Math.sin(a) * ry * k]);
    }
    return h.dots ? broken(pts, Math.max(3, rx * 0.16), Math.max(2.5, rx * 0.11)) : pts2d(pts);
  }

  function box(v, h, r) {
    const x = v[0], y = v[1], w = v[2], hh = v[3];
    if (h.ruled) {
      // ruled, the corners run a little past
      const o = 3;
      return 'M' + f1(x - o) + ' ' + f1(y) + ' H' + f1(x + w) + ' M' + f1(x + w) + ' ' + f1(y - o) + ' V' + f1(y + hh) + ' M' + f1(x + w + o) + ' ' + f1(y + hh) + ' H' + f1(x) + ' M' + f1(x) + ' ' + f1(y + hh + o) + ' V' + f1(y);
    }
    const j = function (s) { return (r() - 0.5) * s * (h.wob * 40); };
    const pts = [[x + j(3), y + j(3)], [x + w + j(3), y + j(3)], [x + w + j(3), y + hh + j(3)], [x + j(3), y + hh + j(3)], [x + j(3) + w * 0.12, y + j(2) - 1]];
    const fine = [];
    for (let i = 0; i < pts.length - 1; i++) for (let s = 0; s < 8; s++) { const t = s / 8; fine.push([pts[i][0] + (pts[i + 1][0] - pts[i][0]) * t, pts[i][1] + (pts[i + 1][1] - pts[i][1]) * t]); }
    fine.push(pts[pts.length - 1]);
    return h.dots ? broken(fine, 4, 3) : pts2d(fine);
  }

  function line(v, h, r) {
    const x1 = v[0], y1 = v[1], x2 = v[2], y2 = v[3];
    const mk = function (dy) {
      const pts = [];
      const bow = (r() - 0.5) * 4 * (h.ruled ? 0 : 1);
      for (let i = 0; i <= 12; i++) { const t = i / 12; pts.push([x1 + (x2 - x1) * t, y1 + (y2 - y1) * t + dy + Math.sin(t * Math.PI) * bow]); }
      return h.dots ? broken(pts, 5, 4) : pts2d(pts);
    };
    let d = mk(0);
    if (h.under === 2) d += ' ' + mk(4.5);
    return d;
  }

  function arrow(v, h, r) {
    const x1 = v[0], y1 = v[1], x2 = v[2], y2 = v[3];
    const a = Math.atan2(y2 - y1, x2 - x1), L = 9;
    const bend = h.ruled ? 0 : (r() - 0.5) * 14;
    const mx = (x1 + x2) / 2 - Math.sin(a) * bend, my = (y1 + y2) / 2 + Math.cos(a) * bend;
    return 'M' + f1(x1) + ' ' + f1(y1) + ' Q' + f1(mx) + ' ' + f1(my) + ' ' + f1(x2) + ' ' + f1(y2) +
      ' M' + f1(x2 - L * Math.cos(a - 0.45)) + ' ' + f1(y2 - L * Math.sin(a - 0.45)) + ' L' + f1(x2) + ' ' + f1(y2) + ' L' + f1(x2 - L * Math.cos(a + 0.45)) + ' ' + f1(y2 - L * Math.sin(a + 0.45));
  }

  function cross(v, h, r) {
    const cx = v[0], cy = v[1], s = v[2];
    const j = function () { return (r() - 0.5) * s * 0.25; };
    return 'M' + f1(cx - s + j()) + ' ' + f1(cy - s + j()) + ' L' + f1(cx + s + j()) + ' ' + f1(cy + s + j()) +
      ' M' + f1(cx + s + j()) + ' ' + f1(cy - s + j()) + ' L' + f1(cx - s + j()) + ' ' + f1(cy + s + j());
  }

  function tally(v, h, r) {
    const x = v[0], y = v[1], n = Math.max(1, Math.min(12, v[2] | 0));
    let d = '';
    for (let i = 0; i < n; i++) {
      const g = Math.floor(i / 5), k = i % 5, gx = x + g * 34;
      if (k === 4) d += ' M' + f1(gx - 3) + ' ' + f1(y + 13) + ' L' + f1(gx + 26) + ' ' + f1(y + 3);
      else d += ' M' + f1(gx + k * 6.5 + (r() - 0.5)) + ' ' + f1(y) + ' L' + f1(gx + k * 6.5 + (r() - 0.5) * 2) + ' ' + f1(y + 16);
    }
    return d.trim();
  }

  const DRAW = { ring: ring, box: box, line: line, arrow: arrow, cross: cross, tally: tally };

  function bounds(sp) {
    let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
    const take = function (x, y) { x0 = Math.min(x0, x); y0 = Math.min(y0, y); x1 = Math.max(x1, x); y1 = Math.max(y1, y); };
    if (sp.ring) { take(sp.ring[0] - sp.ring[2], sp.ring[1] - sp.ring[3]); take(sp.ring[0] + sp.ring[2], sp.ring[1] + sp.ring[3]); }
    if (sp.box) { take(sp.box[0], sp.box[1]); take(sp.box[0] + sp.box[2], sp.box[1] + sp.box[3]); }
    for (const k of ['line', 'arrow']) if (sp[k]) { take(sp[k][0], sp[k][1]); take(sp[k][2], sp[k][3]); }
    if (sp.cross) { take(sp.cross[0] - sp.cross[2], sp.cross[1] - sp.cross[2]); take(sp.cross[0] + sp.cross[2], sp.cross[1] + sp.cross[2]); }
    if (sp.tally) { take(sp.tally[0], sp.tally[1]); take(sp.tally[0] + 30, sp.tally[1] + 16); }
    return { x0: x0, y0: y0, x1: x1, y1: y1 };
  }

  // the part of the picture to show: the spots' crops together, kept inside the picture
  function cropOf(spots) {
    let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
    for (const s of spots) { const c = s.def.crop; x0 = Math.min(x0, c[0]); y0 = Math.min(y0, c[1]); x1 = Math.max(x1, c[0] + c[2]); y1 = Math.max(y1, c[1] + c[3]); }
    x0 = Math.max(0, x0); y0 = Math.max(0, y0); x1 = Math.min(W, x1); y1 = Math.min(H, y1);
    return { x: x0, y: y0, w: x1 - x0, h: y1 - y0 };
  }

  function svgEl(name, attrs) {
    const el = document.createElementNS(NS, name);
    for (const k in attrs) el.setAttribute(k, attrs[k]);
    return el;
  }

  // mark: { spots: [{at, note}], state, clock }; style: the voice's style id (voices.yaml)
  function node(mark, style, opts) {
    opts = opts || {};
    const spec = (globalThis.BOUNCER_CONTENT && globalThis.BOUNCER_CONTENT.marks) || {};
    const spots = [];
    let place = null;
    for (const s of (mark && mark.spots) || []) {
      const parts = String(s.at).split('.');
      const def = spec[parts[0]] && spec[parts[0]][parts[1]];
      if (!def || (place && parts[0] !== place)) continue;
      place = parts[0];
      spots.push({ at: s.at, note: s.note || '', def: def });
    }
    if (!spots.length || !B.Plates || !B.Plates.has(place)) return null;
    const h = HAND[style] || HAND.father;
    const crop = cropOf(spots);
    const r = rng(seedOf(style + '|' + spots.map(function (s) { return s.at; }).join(',')));

    const fig = document.createElement('figure');
    fig.className = 'mark v-' + style + ' mk-' + style;
    fig.setAttribute('data-place', place);
    fig.style.setProperty('--tilt', h.tilt + 'deg');
    const box = document.createElement('div');
    box.className = 'mk-crop';
    box.style.aspectRatio = crop.w + ' / ' + crop.h;
    const img = B.Plates.place(place, mark.state || {}, opts.phase || 'busy');
    img.className = (img.className ? img.className + ' ' : '') + 'mk-img';
    img.style.width = (W / crop.w * 100) + '%';
    img.style.height = (H / crop.h * 100) + '%';
    img.style.left = (-crop.x / crop.w * 100) + '%';
    img.style.top = (-crop.y / crop.h * 100) + '%';
    box.append(img);

    const svg = svgEl('svg', { viewBox: crop.x + ' ' + crop.y + ' ' + crop.w + ' ' + crop.h, preserveAspectRatio: 'none', 'aria-hidden': 'true' });
    let at = 0;
    const notes = [];
    for (const s of spots) {
      for (const kind of Object.keys(DRAW)) {
        if (!s.def[kind]) continue;
        const d = DRAW[kind](s.def[kind], h, r);
        const dur = h.ms * (kind === 'tally' ? 1.4 : 1);
        for (const cls of ['mk-under', 'mk-ink']) {
          const p = svgEl('path', { d: d, pathLength: '1', class: cls, 'vector-effect': 'non-scaling-stroke' });
          p.style.setProperty('--w', String(h.w));
          p.style.setProperty('--dur', dur + 'ms');
          p.style.setProperty('--at', at + 'ms');
          svg.append(p);
        }
        at += dur * 0.85;
      }
      if (s.note) {
        const b = bounds(s.def);
        const nx = s.def.note ? s.def.note[0] : b.x1 + 4, ny = s.def.note ? s.def.note[1] : b.y0 - 2;
        const n = document.createElement('span');
        n.className = 'mk-note';
        n.textContent = s.note;
        n.style.left = ((nx - crop.x) / crop.w * 100) + '%';
        n.style.top = ((ny - crop.y) / crop.h * 100) + '%';
        n.style.setProperty('--at', at + 'ms');
        notes.push(n);
        at += 380;
      }
    }
    box.append(svg);
    for (const n of notes) box.append(n);
    fig.append(box);

    if (opts.draw) {
      fig.classList.add('drawing');
      fig.style.setProperty('--delay', (opts.delay || 0) + 'ms');
      if (opts.audio) {
        const a = opts.audio;
        setTimeout(function () { a.sfx('pen', style === 'fighter' ? 1 : style === 'manual' ? 0.6 : 0.8); }, (opts.delay || 0) + 260);
      }
    }
    return fig;
  }

  B.Marks = { node: node, HAND: HAND };
})(globalThis.Bouncer = globalThis.Bouncer || {});
