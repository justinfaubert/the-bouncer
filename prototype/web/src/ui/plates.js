// Plates: the places and the people, drawn the way the art direction proposes (bible/04_PRODUCTION.md,
// "a printed look"): as if run off in the bar's back room, linocut and halftone, one ink on cream
// stock plus the red of the sign. They're drawn here in code, from shapes, so they cost nothing and
// can be swapped for real prints later: a file in assets.yaml wins over the drawing.
//
// A plate shows the place as it is when he walks in: how full the room is, table 28's glasses,
// eyes in the keg-room wall as the rats double, which doors are propped (Game._plateState).
// The time of night is laid over it by the page (a wash per hour, style.css).
//
//   Plates.placeUrl(id, state)   an image of a place he goes (lot, door, floor, bar, t28, pool, hall,
//                                kitchen, keg, deck, upstairs); null for places with no plate
//   Plates.portraitUrl(id, look) a head-and-shoulders figure assembled from parts, the way Papers,
//                                Please builds its faces, from a character's `look:` in
//                                content/data/characters.yaml
//   Plates.place / .portrait     the same drawings as SVG text
//
// Each drawing is a whole SVG document with its own screens and inks, used as an <img>, so a long
// night of plates stays light on the page.
(function (B) {
  'use strict';

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
  const f = function (n) { return Math.round(n * 10) / 10; };

  // ---------------------------------------------------------------- primitives
  const R = function (x, y, w, h, c, more) { return '<rect x="' + f(x) + '" y="' + f(y) + '" width="' + f(w) + '" height="' + f(h) + '" class="' + c + '"' + (more || '') + '/>'; };
  const C = function (x, y, r, c) { return '<circle cx="' + f(x) + '" cy="' + f(y) + '" r="' + f(r) + '" class="' + c + '"/>'; };
  const E = function (x, y, rx, ry, c) { return '<ellipse cx="' + f(x) + '" cy="' + f(y) + '" rx="' + f(rx) + '" ry="' + f(ry) + '" class="' + c + '"/>'; };
  const Pth = function (d, c) { return '<path d="' + d + '" class="' + c + '"/>'; };
  const L = function (x1, y1, x2, y2, c) { return '<line x1="' + f(x1) + '" y1="' + f(y1) + '" x2="' + f(x2) + '" y2="' + f(y2) + '" class="' + c + '"/>'; };
  const T = function (x, y, s, c, anchor) { return '<text x="' + f(x) + '" y="' + f(y) + '" class="' + c + '" text-anchor="' + (anchor || 'middle') + '">' + s + '</text>'; };
  const poly = function (pts, c) { return '<polygon points="' + pts.map(function (p) { return f(p[0]) + ',' + f(p[1]); }).join(' ') + '" class="' + c + '"/>'; };

  // slanted rain, cut in paper over whatever's behind
  function rain(r, n, x0, y0, w, h, c) {
    let s = '';
    for (let i = 0; i < n; i++) {
      const x = x0 + r() * w, y = y0 + r() * h, l = 7 + r() * 15;
      s += L(x, y, x - l * 0.22, y + l, c || 'ps w1');
    }
    return s;
  }

  // the grain of cheap stock: flecks of ink, and a few gaps where the ink didn't take
  function grain(r, n) {
    let s = '';
    for (let i = 0; i < n; i++) s += C(r() * W, r() * H, 0.35 + r() * 0.8, i % 3 ? 'k fl' : 'pp fl');
    return s;
  }

  // A figure from behind or side-on: head, neck and shoulders, in ink. s is the scale (1 = head r 9).
  function bust(x, y, s, c, lean) {
    const hx = x + (lean || 0) * s;
    return C(hx, y - 30 * s, 9 * s, c) +
      Pth('M' + f(x - 22 * s) + ' ' + f(y + 20 * s) + ' C ' + f(x - 22 * s) + ' ' + f(y - 8 * s) + ' ' + f(x - 14 * s) + ' ' + f(y - 16 * s) + ' ' + f(hx - 5 * s) + ' ' + f(y - 20 * s) +
        ' L ' + f(hx + 5 * s) + ' ' + f(y - 20 * s) + ' C ' + f(x + 14 * s) + ' ' + f(y - 16 * s) + ' ' + f(x + 22 * s) + ' ' + f(y - 8 * s) + ' ' + f(x + 22 * s) + ' ' + f(y + 20 * s) + ' Z', c);
  }

  function standing(x, y, s, c, lean) {
    const hx = x + (lean || 0) * s;
    return C(hx, y - 88 * s, 9 * s, c) +
      Pth('M' + f(x - 17 * s) + ' ' + f(y - 40 * s) + ' C ' + f(x - 18 * s) + ' ' + f(y - 66 * s) + ' ' + f(x - 12 * s) + ' ' + f(y - 76 * s) + ' ' + f(hx - 4 * s) + ' ' + f(y - 78 * s) +
        ' L ' + f(hx + 4 * s) + ' ' + f(y - 78 * s) + ' C ' + f(x + 12 * s) + ' ' + f(y - 76 * s) + ' ' + f(x + 18 * s) + ' ' + f(y - 66 * s) + ' ' + f(x + 17 * s) + ' ' + f(y - 40 * s) +
        ' L ' + f(x + 12 * s) + ' ' + f(y - 36 * s) + ' L ' + f(x + 10 * s) + ' ' + f(y) + ' L ' + f(x + 2 * s) + ' ' + f(y) + ' L ' + f(x) + ' ' + f(y - 30 * s) +
        ' L ' + f(x - 2 * s) + ' ' + f(y) + ' L ' + f(x - 10 * s) + ' ' + f(y) + ' L ' + f(x - 12 * s) + ' ' + f(y - 36 * s) + ' Z', c);
  }

  function glass(x, y, s, full) {
    return poly([[x - 4 * s, y - 12 * s], [x + 4 * s, y - 12 * s], [x + 3 * s, y], [x - 3 * s, y]], 'pp') +
      (full ? poly([[x - 3.5 * s, y - 8 * s], [x + 3.5 * s, y - 8 * s], [x + 3 * s, y], [x - 3 * s, y]], 'ht2') : '') +
      Pth('M' + f(x - 4 * s) + ' ' + f(y - 12 * s) + ' L' + f(x - 3 * s) + ' ' + f(y) + ' L' + f(x + 3 * s) + ' ' + f(y) + ' L' + f(x + 4 * s) + ' ' + f(y - 12 * s), 'ks w1');
  }

  const INK = '#1C1A17', PAPER = '#E8E0CC', RED = '#C8281D';

  // The screens and the inks every plate carries with it. k scales the screens and the roughness:
  // 1 for the places, finer for the faces, which are small.
  function head(k) {
    const pat = function (id, cell, inner, rot) {
      return '<pattern id="' + id + '" width="' + f(cell * k) + '" height="' + f(cell * k) + '" patternUnits="userSpaceOnUse"' + (rot ? ' patternTransform="rotate(' + rot + ')"' : '') + '>' + inner + '</pattern>';
    };
    const c = function (x, r, cls) { return '<circle cx="' + f(x * k) + '" cy="' + f(x * k) + '" r="' + f(r * k) + '" class="' + cls + '"/>'; };
    return '<defs>' +
      pat('h1', 6, c(3, 1.15, 'k'), 28) +
      pat('h2', 5, c(2.5, 1.75, 'k'), 28) +
      pat('h3', 4, '<rect width="' + f(4 * k) + '" height="' + f(4 * k) + '" class="k"/>' + c(2, 1.05, 'pp'), 28) +
      pat('hh', 5, '<line x1="0" y1="0" x2="0" y2="' + f(5 * k) + '" class="ks" stroke-width="' + f(1.1 * k) + '"/>', 45) +
      pat('vh', 9, '<line x1="' + f(k) + '" y1="0" x2="' + f(k) + '" y2="' + f(9 * k) + '" class="ks" stroke-width="' + f(1.1 * k) + '"/><line x1="' + f(5 * k) + '" y1="0" x2="' + f(5 * k) + '" y2="' + f(9 * k) + '" class="ks" stroke-width="' + f(1.1 * k) + '" opacity=".45"/>', 0) +
      '<filter id="rough" x="-2%" y="-2%" width="104%" height="104%"><feTurbulence type="fractalNoise" baseFrequency="' + f(0.85 / k * 100) / 100 + '" numOctaves="2" seed="7" result="n"/><feDisplacementMap in="SourceGraphic" in2="n" scale="' + f(2.4 * k) + '" xChannelSelector="R" yChannelSelector="G"/></filter>' +
      '</defs><style>' +
      '.k{fill:' + INK + '}.pp{fill:' + PAPER + '}.rd{fill:' + RED + '}' +
      '.ht{fill:url(#h1)}.ht2{fill:url(#h2)}.ht3{fill:url(#h3)}.hh{fill:url(#hh)}.vh{fill:url(#vh)}' +
      '.ks{fill:none;stroke:' + INK + '}.ps{fill:none;stroke:' + PAPER + '}.rs{fill:none;stroke:' + RED + '}' +
      '.w1{stroke-width:1}.w2{stroke-width:2}.w3{stroke-width:3.2}.thin{stroke-width:.7;opacity:.7}' +
      '.dotted{stroke-dasharray:1 2.6;stroke-linecap:round}.fl{opacity:.55}.frame{fill:none}.smoke{stroke-dasharray:2 3;opacity:.6}' +
      'text{font-family:"Arial Narrow","Helvetica Neue",Helvetica,Arial,sans-serif;font-weight:700;font-stretch:condensed}' +
      '.pl-type{font-size:9px;letter-spacing:.06em}.small{font-size:6.4px}' +
      '.pl-sign{fill:' + RED + ';font-size:31px}.dead{fill:' + INK + ';stroke:' + RED + ';stroke-width:.6;stroke-opacity:.45}' +
      '</style>';
  }
  const HEADS = {};

  function svgDoc(w, h, body, extra, k) {
    k = k || 1;
    if (!HEADS[k]) HEADS[k] = head(k);
    return '<svg xmlns="http://www.w3.org/2000/svg" width="' + w + '" height="' + h + '" viewBox="0 0 ' + w + ' ' + h + '">' +
      HEADS[k] + body + (extra || '') + '</svg>';
  }

  function wrap(body, r) {
    return svgDoc(W, H, R(0, 0, W, H, 'pp') + '<g filter="url(#rough)">' + body + '</g>', grain(r, 170) + R(5, 5, W - 10, H - 10, 'ks w2 frame'));
  }

  const clamp = function (n, lo, hi) { return Math.max(lo, Math.min(hi, n)); };

  // ---------------------------------------------------------------- the places

  // What each plate shows of the night, in steps, from Game._plateState. Plates with the same look
  // are the same image.
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

  const PLACES = {
    // Arriving: the Sov from the lot, in the rain, the second E dead.
    lot: function (r) {
      let s = R(0, 0, W, 150, 'ht3') + R(0, 0, W, 60, 'k');
      // the building: three storeys of old wood
      s += R(110, 58, 420, 124, 'ht3') + R(110, 58, 420, 124, 'ks w2');
      s += R(110, 58, 420, 6, 'pp');
      for (let i = 0; i < 3; i++) s += L(110, 98 + i * 32, 530, 98 + i * 32, 'ks w2');
      for (let row = 0; row < 3; row++) {
        for (let i = 0; i < 9; i++) {
          const x = 130 + i * 44, y = 72 + row * 32;
          const lit = (row === 1 && (i === 2 || i === 6)) || (row === 0 && i === 7);
          s += R(x, y, 20, 18, lit ? 'pp' : 'k');
          if (lit) s += L(x + 10, y, x + 10, y + 18, 'ks w1') + L(x, y + 9, x + 20, y + 9, 'ks w1');
        }
      }
      // the cold beer and wine store at one end with its lights on
      s += R(452, 146, 64, 36, 'pp') + R(460, 152, 48, 6, 'k') + T(484, 176, 'COLD BEER', 'pl-type k', 'middle');
      // the pub door, lit
      s += R(160, 150, 26, 32, 'pp') + R(163, 153, 20, 12, 'ht');
      // the sign on the roof
      s += R(180, 16, 280, 34, 'k') + L(206, 50, 206, 58, 'ks w2') + L(434, 50, 434, 58, 'ks w2');
      const letters = 'SOVEREIGN';
      for (let i = 0; i < letters.length; i++) s += T(200 + i * 30, 44, letters[i], i === 5 ? 'pl-sign dead' : 'pl-sign');
      // the lot: wet, the sign lying in it
      s += R(0, 182, W, 38, 'k');
      for (let i = 0; i < 16; i++) s += L(20 + r() * 600, 188 + r() * 28, 60 + r() * 600, 188 + r() * 28, 'ps w1 thin');
      for (let i = 0; i < letters.length; i++) if (i !== 5) s += R(200 + i * 30 - 6, 192 + (i % 2) * 3, 12, 3, 'rd');
      // trucks, nose-in
      const truck1 = 'M28 196 L28 170 L50 166 L60 150 L98 150 L104 168 L118 170 L118 196 Z', truck2 = 'M540 196 L540 168 L556 166 L566 148 L604 148 L612 166 L628 168 L628 196 Z';
      s += Pth(truck1, 'k') + Pth(truck1, 'ps w1') + R(64, 154, 30, 12, 'ht2');
      s += Pth(truck2, 'k') + Pth(truck2, 'ps w1') + R(572, 152, 30, 12, 'ht2');
      s += C(44, 197, 9, 'k') + C(102, 197, 9, 'k') + C(556, 197, 9, 'k') + C(612, 197, 9, 'k');
      s += rain(r, 120, 0, 0, W, H);
      return s;
    },

    // The room, the first time he goes in.
    floor: function (r, look) {
      let s = R(0, 0, W, 132, 'vh') + R(0, 0, W, 14, 'k') + R(0, 132, W, 88, 'ht');
      // the bar down the left side, stools, the bottles lit from below
      s += R(18, 30, 150, 44, 'k');
      for (let i = 0; i < 14; i++) s += R(24 + i * 10, 38 + (i % 3), 5, 16 + (i % 4) * 3, 'pp');
      s += poly([[0, 108], [196, 96], [196, 116], [0, 136]], 'k') + L(0, 104, 196, 92, 'ps w2');
      for (let i = 0; i < 5; i++) { const x = 24 + i * 36; s += E(x, 134 - i * 2, 11, 4, 'k') + L(x, 136 - i * 2, x, 168 - i * 2, 'ks w3'); }
      // the pool table under its lamp
      s += poly([[330, 26], [360, 26], [396, 104], [294, 104]], 'pp') + R(326, 14, 38, 12, 'k');
      s += poly([[276, 110], [414, 110], [430, 146], [260, 146]], 'k') + poly([[284, 114], [406, 114], [418, 140], [272, 140]], 'ht2');
      s += C(330, 126, 3.2, 'pp') + C(352, 132, 3.2, 'pp') + C(372, 122, 3.2, 'pp');
      s += standing(250, 176, 0.92, 'k', 2) + standing(446, 176, 0.8, 'k', -2);
      // the crowd, filling in as the night goes
      const spots = [[520, 170, 0.78], [214, 182, 0.9], [482, 166, 0.7], [236, 150, 0.62], [556, 176, 0.84], [190, 160, 0.7], [420, 160, 0.66], [284, 186, 0.96], [506, 150, 0.6]];
      for (let i = 0; i < look.crowd; i++) { const p = spots[i]; s += standing(p[0], p[1], p[2], 'k', (i % 3) - 1) + standing(p[0], p[1], p[2], 'ps w1', (i % 3) - 1); }
      // the jukebox
      s += R(560, 44, 40, 70, 'k') + Pth('M562 60 Q580 40 598 60 L598 70 L562 70 Z', 'rd') + R(566, 78, 28, 26, 'ht');
      // table 28 in the front window
      s += R(470, 150, 170, 70, 'ht3') + L(470, 150, 640, 150, 'ks w3') + E(540, 178, 44, 10, 'pp') + E(540, 181, 44, 10, 'k');
      for (let i = 0; i < 5; i++) s += bust(488 + i * 26, 200, 0.62, 'k', (i - 2) * 1.5) + bust(488 + i * 26, 200, 0.62, 'ps w1', (i - 2) * 1.5);
      for (let i = 0; i < look.glasses; i++) s += glass(504 + i * (72 / look.glasses), 178, 0.6, i % 2);
      return s;
    },

    // The front door from the stool beside it.
    door: function (r) {
      let s = R(0, 0, W, H, 'vh') + R(0, 0, W, 16, 'k') + R(0, 196, W, 24, 'k');
      // the door: heavy, a wired-glass window, rain beyond, the sign's red on the glass
      s += R(232, 22, 176, 176, 'k') + R(244, 34, 152, 162, 'ht2');
      s += R(276, 48, 88, 64, 'k') + R(282, 54, 76, 52, 'ht3');
      s += rain(r, 40, 282, 54, 76, 52);
      for (let i = 1; i < 4; i++) s += L(282 + i * 19, 54, 282 + i * 19, 106, 'ks w1') + L(282, 54 + i * 13, 358, 54 + i * 13, 'ks w1');
      s += L(300, 62, 299, 92, 'rs w3') + L(307, 66, 306, 80, 'rs w2') + L(314, 60, 313, 100, 'rs w3') + L(322, 70, 322, 84, 'rs w1');
      s += R(370, 118, 10, 30, 'k') + R(366, 128, 20, 6, 'pp');
      s += R(262, 130, 116, 22, 'pp') + T(320, 146, 'MINORS PROHIBITED', 'pl-type k', 'middle');
      // the stool and the clicker on it
      s += E(148, 136, 30, 8, 'k') + L(128, 140, 120, 200, 'ks w3') + L(168, 140, 176, 200, 'ks w3') + L(126, 176, 170, 176, 'ks w2');
      s += R(140, 122, 16, 12, 'pp') + C(148, 120, 3, 'pp') + L(150, 118, 150, 110, 'ks w1');
      // coat hooks, a jacket nobody came back for
      s += R(460, 40, 120, 6, 'k');
      for (let i = 0; i < 4; i++) s += Pth('M' + (474 + i * 28) + ' 46 q0 8 6 8', 'ks w2');
      s += Pth('M500 48 L516 48 L532 60 L538 116 L528 118 L526 126 L490 126 L488 118 L478 116 L484 60 Z', 'k');
      s += L(508, 50, 508, 126, 'ps w1') + Pth('M500 48 L508 64 L516 48', 'ps w1') + L(488, 70, 489, 116, 'ps w1 thin') + L(528, 70, 527, 116, 'ps w1 thin');
      // the mat, and wet on it
      s += R(236, 198, 168, 10, 'ht3');
      return s;
    },

    // At the bar: taps, the till, limes.
    bar: function (r, look) {
      let s = R(0, 0, W, 120, 'vh') + R(0, 0, W, 12, 'k');
      // back bar: shelves of bottles, lit from under
      s += R(20, 26, 600, 4, 'k') + R(20, 64, 600, 4, 'k');
      for (let i = 0; i < 40; i++) {
        const x = 26 + i * 15, h = 22 + (i * 7) % 12;
        s += R(x, 64 - h, 9, h, i % 5 === 0 ? 'ht2' : 'k') + R(x + 3, 64 - h - 6, 3, 6, 'k');
      }
      s += R(20, 68, 600, 40, 'ht');
      // the till
      s += R(470, 70, 90, 40, 'k') + R(480, 76, 40, 14, 'pp') + T(500, 87, '8.50', 'pl-type k');
      // the bar top and the rail
      s += R(0, 120, W, 22, 'k') + L(0, 124, W, 124, 'ps w2') + R(0, 142, W, 78, 'hh') + L(0, 188, W, 188, 'ks w3');
      // taps
      for (let i = 0; i < 6; i++) {
        const x = 140 + i * 30;
        s += R(x - 3, 78, 6, 42, 'k') + Pth('M' + (x - 7) + ' 70 L' + (x + 7) + ' 70 L' + (x + 5) + ' 92 L' + (x - 5) + ' 92 Z', i === 2 ? 'rd' : 'k');
      }
      // the board and the limes, the knife
      s += R(360, 108, 90, 10, 'pp') + R(360, 118, 90, 3, 'k');
      for (let i = 0; i < 4; i++) s += Pth('M' + (372 + i * 18) + ' 108 a7 7 0 0 1 14 0 Z', 'ht2') + Pth('M' + (372 + i * 18) + ' 108 a7 7 0 0 1 14 0', 'ks w1');
      s += L(420, 104, 452, 96, 'ks w2') + R(448, 92, 14, 6, 'k');
      // a glass on the bar
      s += glass(60, 120, 1.6, true) + glass(96, 120, 1.6, false);
      // backs at the rail, more of them as it fills
      const at = [[540, 1.5], [110, 1.4], [320, 1.55], [214, 1.45], [430, 1.5], [612, 1.35]];
      for (let i = 0; i < look.crowd; i++) s += bust(at[i][0], 214, at[i][1], 'k', (i % 2 ? 2 : -2)) + bust(at[i][0], 214, at[i][1], 'ps w1', (i % 2 ? 2 : -2));
      return s;
    },

    // Table 28: five in the front window, the rain behind them, the glasses in front.
    t28: function (r, look) {
      let s = R(0, 0, W, H, 'ht3');
      // the window: big panes, rain, the lot's light
      s += R(40, 10, 560, 150, 'ht2');
      for (let i = 1; i < 4; i++) s += R(40 + i * 140 - 3, 10, 6, 150, 'k');
      s += R(40, 80, 560, 5, 'k');
      s += rain(r, 90, 44, 12, 552, 146);
      s += C(520, 44, 16, 'pp') + C(520, 44, 26, 'ht');
      // the five, and the table
      const five = [[250, 150, 1.15, 2], [392, 150, 1.15, -2], [320, 146, 1.1, 0], [170, 160, 1.25, -3], [470, 160, 1.25, 3]];
      for (const b of five) s += bust(b[0], b[1], b[2], 'k', b[3]) + bust(b[0], b[1], b[2], 'ps w1', b[3]);
      s += E(320, 178, 190, 26, 'k') + E(320, 172, 186, 22, 'pp') + E(320, 175, 186, 20, 'ht');
      const gap = 290 / Math.max(1, look.glasses - 1);
      for (let i = 0; i < look.glasses; i++) s += glass(176 + i * gap, 176 + (i % 3) * 3, 1.05, i % 3 !== 1);
      // the scratch tickets, and what's under the table
      s += R(412, 176, 20, 9, 'pp') + L(414, 180, 430, 180, 'ks w1');
      s += R(0, 196, W, 24, 'k');
      if (look.rat) s += Pth('M286 206 q10 -12 26 -4 q8 0 10 6 l4 1 l-4 2 q-12 5 -30 2 q-14 6 -22 2 q8 0 16 -9 Z', 'pp') + C(314, 204, 1.2, 'k');
      return s;
    },

    // The pool table under its lamp. The big man holds the cue in his left hand.
    pool: function (r, look) {
      let s = R(0, 0, W, H, 'ht2') + R(0, 0, W, 20, 'k');
      s += poly([[296, 30], [344, 30], [470, 172], [170, 172]], 'pp');
      s += R(290, 20, 60, 14, 'k') + L(320, 0, 320, 20, 'ks w2');
      // the table
      s += poly([[150, 140], [490, 140], [520, 196], [120, 196]], 'k') + poly([[164, 146], [476, 146], [500, 188], [140, 188]], 'ht2');
      s += C(250, 162, 5, 'pp') + C(262, 170, 5, 'pp') + C(250, 174, 5, 'k') + C(380, 158, 5, 'pp') + C(402, 176, 5, 'rd');
      // the big man, bent to the shot, cue in his left hand; the buddy watching
      s += Pth('M470 176 C470 140 488 112 520 104 C544 100 560 110 566 128 L574 196 L520 196 Z', 'k') + C(512, 96, 13, 'k');
      s += L(470 - 2, 150, 300, 166, 'ks w3') + L(560, 132, 470, 150, 'ks w3');
      s += standing(110, 196, 0.95, 'k', 2) + L(96, 60, 132, 196, 'ks w2');
      if (look.watched) s += standing(612, 196, 0.86, 'k', -3) + standing(40, 196, 0.8, 'k', 2) + standing(40, 196, 0.8, 'ps w1', 2);
      s += R(0, 196, W, 24, 'k');
      return s;
    },

    // The back hall: three washroom doors, the payphone, the hotel door at the end.
    hall: function (r, look) {
      let s = R(0, 0, W, H, 'ht');
      s += poly([[0, 0], [W, 0], [390, 70], [250, 70]], 'k');
      s += poly([[0, H], [W, H], [390, 150], [250, 150]], 'ht3');
      s += poly([[0, 0], [250, 70], [250, 150], [0, H]], 'vh') + poly([[W, 0], [390, 70], [390, 150], [W, H]], 'ht2');
      // the hotel door at the end, light around it
      if (look.open) s += R(282, 76, 76, 74, 'pp') + R(290, 82, 60, 68, 'k') + L(290, 82, 290, 150, 'ps w2');
      else s += R(282, 76, 76, 74, 'k') + R(290, 82, 60, 68, 'ht3') + L(340, 112, 346, 112, 'ps w2');
      s += R(300, 64, 40, 9, 'rd') + T(320, 71.5, 'EXIT', 'pl-type pp');
      // three doors on the left: MEN, WOMEN, SINGLE
      const doors = [[40, 'MEN'], [130, 'WOMEN'], [196, 'SINGLE']];
      for (const d of doors) {
        const x = d[0], k = (x / 250);
        s += poly([[x, 16 + k * 54], [x + 46 - k * 16, 30 + k * 50], [x + 46 - k * 16, 188 - k * 34], [x, 204 - k * 40]], 'k');
        const pw = 32 - k * 8;
        s += R(x + 6, 60 + k * 44, pw, 9, 'pp') + T(x + 6 + pw / 2, 67 + k * 44, d[1], 'pl-type k small');
      }
      // light under the single's door
      s += poly([[196, 162], [226, 156], [228, 160], [196, 166]], 'pp');
      // the payphone on the right wall
      s += poly([[500, 70], [540, 58], [540, 118], [500, 122]], 'k') + poly([[506, 78], [534, 70], [534, 90], [506, 96]], 'ht2');
      s += Pth('M512 100 q-10 30 8 46', 'ks w2');
      return s;
    },

    // The kitchen: the fryer, the steel, the back door propped for air.
    kitchen: function (r, look) {
      let s = R(0, 0, W, H, 'ht') + R(0, 0, W, 14, 'k');
      s += R(120, 16, 260, 7, 'pp') + R(116, 14, 268, 3, 'k');
      // the steel
      s += R(20, 110, 420, 16, 'k') + R(20, 126, 420, 94, 'hh') + L(20, 114, 440, 114, 'ps w1');
      // the fryer, baskets hanging
      s += R(250, 70, 110, 44, 'k') + R(258, 60, 40, 12, 'ht2') + R(306, 60, 40, 12, 'ht2') + L(278, 60, 278, 40, 'ks w2') + L(326, 60, 326, 40, 'ks w2');
      for (let i = 0; i < 5; i++) s += Pth('M' + (60 + i * 30) + ' 30 L' + (60 + i * 30) + ' 70 q0 12 -8 12', 'ks w2');
      // the back door propped with a milk crate, rain and the dark beyond
      s += R(470, 30, 120, 170, 'k');
      if (look.open) {
        s += poly([[476, 36], [560, 48], [560, 196], [476, 196]], 'ht3') + rain(r, 30, 478, 40, 80, 150);
        s += poly([[560, 48], [590, 30], [590, 200], [560, 196]], 'pp') + R(540, 176, 34, 22, 'hh') + R(540, 176, 34, 22, 'ks w1');
      } else {
        s += R(478, 38, 104, 158, 'ht2') + L(488, 118, 572, 118, 'ks w3') + R(478, 38, 104, 158, 'ks w2');
      }
      // a trap on the floor under the steel
      s += R(84, 196, 34, 10, 'pp') + L(88, 196, 114, 206, 'ks w2') + R(84, 196, 34, 10, 'ks w1');
      s += R(0, 206, W, 14, 'k');
      return s;
    },

    // The keg room: low beams, kegs, the lines going up, the hole in the wall.
    keg: function (r, look) {
      let s = R(0, 0, W, H, 'ht2');
      for (let i = 0; i < 4; i++) s += R(0, i * 18, W, 10, 'k');
      // the trapdoor, light coming down the ladder
      s += poly([[80, 0], [150, 0], [190, 200], [40, 200]], 'ht') + R(80, 0, 70, 10, 'pp');
      for (let i = 0; i < 7; i++) s += L(84 - i * 4, 20 + i * 26, 146 + i * 4, 20 + i * 26, 'ks w2');
      s += L(84, 0, 60, 200, 'ks w3') + L(146, 0, 170, 200, 'ks w3');
      // the kegs
      for (let i = 0; i < 6; i++) {
        const x = 230 + i * 58;
        s += R(x, 110, 46, 84, 'k') + L(x, 126, x + 46, 126, 'ps w2') + L(x, 178, x + 46, 178, 'ps w2') + E(x + 23, 110, 23, 5, 'ht') + C(x + 23, 108, 4, 'pp');
        s += Pth('M' + (x + 23) + ' 106 C ' + (x + 23) + ' 70 ' + (x + 40) + ' 60 ' + (x + 30 + i * 4) + ' 0', 'ks w2');
      }
      // the hole low in the wall, and two eyes in it
      s += E(200, 190, 22, 12, 'k');
      s += R(0, 200, W, 20, 'k');
      const eyes = [[198, 188], [160, 207], [232, 210], [120, 204], [206, 212], [262, 206]];
      for (let i = 0; i < look.eyes; i++) s += C(eyes[i][0] - 4.5, eyes[i][1], 1.6, 'pp') + C(eyes[i][0] + 4.5, eyes[i][1], 1.6, 'pp');
      return s;
    },

    // The deck, covered, on the water side. The coaster in the latch.
    deck: function (r, look) {
      let s = R(0, 0, W, H, 'ht2');
      s += R(0, 0, W, 26, 'k');
      // the far shore, the strait, a ferry going across
      s += R(0, 90, W, 6, 'k');
      for (let i = 0; i < 7; i++) s += C(40 + r() * 560, 92, 0.9, 'pp');
      s += R(0, 96, W, 42, 'ht3');
      for (let i = 0; i < 9; i++) s += L(r() * W, 100 + i * 4, r() * W + 60, 100 + i * 4, 'ps w1 thin');
      s += R(450, 90, 44, 6, 'pp') + C(456, 88, 1.5, 'pp') + C(488, 88, 1.5, 'rd');
      // rain off the roof edge in sheets
      for (let i = 0; i < 60; i++) { const x = r() * W; s += L(x, 26, x - 4, 26 + 30 + r() * 70, 'ks w1 thin'); }
      // posts and the rail
      for (let i = 0; i < 5; i++) s += R(20 + i * 150, 26, 10, 194, 'k');
      s += R(0, 138, W, 8, 'k');
      for (let i = 0; i < 32; i++) s += R(8 + i * 20, 146, 5, 50, 'k');
      s += R(0, 196, W, 24, 'k');
      // wet plastic chairs, stacked, and the coffee can full of butts
      for (let i = 0; i < 3; i++) s += Pth('M' + (150 + i * 3) + ' ' + (196 - i * 5) + ' L' + (155 + i * 3) + ' ' + (170 - i * 5) + ' L' + (180 + i * 3) + ' ' + (170 - i * 5) + ' L' + (184 + i * 3) + ' ' + (196 - i * 5) + ' M' + (155 + i * 3) + ' ' + (170 - i * 5) + ' L' + (152 + i * 3) + ' ' + (142 - i * 5) + ' L' + (177 + i * 3) + ' ' + (140 - i * 5) + ' L' + (180 + i * 3) + ' ' + (170 - i * 5), 'ps w2');
      s += R(248, 180, 14, 16, 'pp') + L(248, 184, 262, 184, 'ks w1') + L(253, 180, 251, 173, 'ps w2') + L(257, 180, 260, 175, 'ps w2');
      // a smoker at the rail, the ember
      s += standing(380, 196, 1.02, 'k', 3) + C(398, 108, 2.4, 'rd');
      // the door, and the coaster folded in the latch
      s += R(560, 30, 70, 166, 'k') + R(566, 36, 58, 70, 'ht2');
      if (look.open) s += R(556, 118, 10, 8, 'pp') + L(560, 30, 560, 196, 'ps w1');
      return s;
    },

    // His room: a bed, a chair, a sink, the window onto the lot and the water.
    upstairs: function (r) {
      let s = R(0, 0, W, H, 'ht3');
      s += R(330, 30, 150, 110, 'k') + R(338, 38, 134, 94, 'ht2') + L(405, 38, 405, 132, 'ks w3') + L(338, 85, 472, 85, 'ks w3');
      s += C(440, 60, 10, 'rd') + C(440, 60, 18, 'ht');
      s += rain(r, 30, 340, 40, 130, 90);
      // the bed
      s += R(30, 132, 250, 52, 'k') + R(40, 124, 230, 14, 'ht') + R(36, 110, 8, 90, 'k') + R(266, 118, 8, 82, 'k') + R(44, 118, 60, 16, 'pp');
      // the chair, with his jacket on it
      s += R(500, 128, 50, 8, 'k') + R(540, 70, 8, 130, 'k') + L(504, 136, 504, 200, 'ks w3') + Pth('M520 76 L548 72 L556 150 L532 154 Z', 'k');
      // the sink in the corner
      s += R(580, 100, 50, 18, 'k') + R(598, 76, 4, 26, 'k') + R(584, 118, 8, 82, 'k');
      s += R(0, 200, W, 20, 'k');
      return s;
    }
  };

  const CAPTIONS = {
    lot: 'The Sovereign Hotel', floor: 'The room', door: 'The front door', bar: 'The bar', t28: 'Table 28',
    pool: 'The pool table', hall: 'The back hall', kitchen: 'The kitchen', keg: 'The keg room', deck: 'The deck', upstairs: 'The room upstairs'
  };

  // ---------------------------------------------------------------- faces from parts
  //
  // look (content/data/characters.yaml):
  //   build   slight | medium | big
  //   hair    short | buzz | long | bun | ponytail | bald | thin | messy | parted
  //   hat     hood | cap | beanie | flatcap | bandana
  //   face    beard | stubble | moustache | glasses | earbuds | hearingaid | lined
  //   top     hoodie | hivis | apron | whites | flannel | suit | coat | jacket | tshirt | cardigan
  //   extra   vape | keys | cigarette | phone | knife | lanyard
  //   group   5 (a table's worth, as one)

  function portrait(id, look) {
    look = look || {};
    const r = rng(seedOf(id));
    const face = [].concat(look.face || []);
    const extra = [].concat(look.extra || []);
    const big = look.build === 'big' ? 1.18 : look.build === 'slight' ? 0.9 : 1;
    let s = R(0, 0, 120, 150, 'pp') + R(0, 0, 120, 150, 'ht');
    if (look.group) {
      // back row, then front, each cut out from the next
      for (const i of [1, 3, 0, 2, 4]) s += bust(16 + i * 22, 126 + (i % 2 ? -6 : 4), 0.86, 'k', (i - 2) * 1.2) + bust(16 + i * 22, 126 + (i % 2 ? -6 : 4), 0.86, 'ps w1', (i - 2) * 1.2);
      s += E(60, 144, 60, 10, 'k') + E(60, 141, 56, 6, 'ht2');
      return psvg(s, r);
    }
    const cx = 60, top = 150;
    s += '<g transform="translate(60 150) scale(1.2) translate(-60 -150)">';
    const sw = 44 * big;                       // shoulder half-width
    const hx = cx, hy = 66, hr = 17 * (look.build === 'big' ? 1.1 : 1);
    // shoulders and the top he wears
    const shoulders = 'M' + f(cx - sw) + ' ' + top + ' C ' + f(cx - sw) + ' 118 ' + f(cx - sw * 0.7) + ' 100 ' + f(cx - 12) + ' 94 L ' + f(cx + 12) + ' 94 C ' + f(cx + sw * 0.7) + ' 100 ' + f(cx + sw) + ' 118 ' + f(cx + sw) + ' ' + top + ' Z';
    s += Pth(shoulders, 'k');
    const tp = look.top;
    if (tp === 'hivis') {
      s += Pth('M' + f(cx - sw * 0.62) + ' 104 L' + f(cx - 8) + ' 150 L' + f(cx - 20) + ' 150 L' + f(cx - sw * 0.8) + ' 112 Z', 'pp');
      s += Pth('M' + f(cx + sw * 0.62) + ' 104 L' + f(cx + 8) + ' 150 L' + f(cx + 20) + ' 150 L' + f(cx + sw * 0.8) + ' 112 Z', 'pp');
      s += L(cx - sw + 6, 132, cx + sw - 6, 132, 'ps w3');
    } else if (tp === 'apron' || tp === 'whites') {
      s += Pth('M' + f(cx - 18) + ' 100 L' + f(cx + 18) + ' 100 L' + f(cx + 22) + ' 150 L' + f(cx - 22) + ' 150 Z', tp === 'whites' ? 'pp' : 'ht2');
      if (tp === 'whites') for (let i = 0; i < 3; i++) s += C(cx + 8, 112 + i * 12, 1.8, 'k');
      else s += L(cx - 18, 100, cx - 30, 94, 'ks w2') + L(cx + 18, 100, cx + 30, 94, 'ks w2');
    } else if (tp === 'suit') {
      s += poly([[cx - 10, 96], [cx + 10, 96], [cx, 140]], 'pp') + poly([[cx - 3, 102], [cx + 3, 102], [cx + 4, 132], [cx, 138], [cx - 4, 132]], 'rd');
      s += L(cx - 10, 96, cx - 4, 140, 'ks w1') + L(cx + 10, 96, cx + 4, 140, 'ks w1');
    } else if (tp === 'flannel') {
      for (let i = 0; i < 4; i++) s += L(cx - sw + 6 + i * 22 * big, 108, cx - sw + 6 + i * 22 * big, 150, 'ps w1');
      s += L(cx - sw + 4, 124, cx + sw - 4, 124, 'ps w1') + L(cx - sw + 4, 140, cx + sw - 4, 140, 'ps w1');
    } else if (tp === 'hoodie') {
      s += L(cx - 8, 100, cx - 10, 124, 'ps w2') + L(cx + 8, 100, cx + 10, 124, 'ps w2') + R(cx - 22, 132, 44, 18, 'ht2');
    } else if (tp === 'coat' || tp === 'jacket') {
      s += L(cx, 98, cx, 150, 'ps w2') + poly([[cx - 12, 94], [cx - 2, 96], [cx - 16, 118]], 'pp') + poly([[cx + 12, 94], [cx + 2, 96], [cx + 16, 118]], 'pp');
    } else if (tp === 'cardigan') {
      s += poly([[cx - 12, 96], [cx + 12, 96], [cx, 128]], 'ht2');
      for (let i = 0; i < 3; i++) s += C(cx - 4, 120 + i * 10, 1.6, 'pp');
    } else if (tp === 'tshirt') {
      s += Pth('M' + f(cx - 12) + ' 96 Q ' + cx + ' 108 ' + f(cx + 12) + ' 96', 'ps w2');
    }
    // neck and head: skin in half-tone, lit from the right, the shadow side cut in ink
    s += R(cx - 7, hy + 12, 14, 22, 'ht2') + R(cx - 7, hy + 12, 5, 22, 'k');
    s += E(hx, hy, hr * 0.86, hr, 'pp') + E(hx, hy, hr * 0.86, hr, 'ht2');
    s += Pth('M' + f(hx - 1) + ' ' + f(hy - hr) + ' Q ' + f(hx - hr * 1.28) + ' ' + f(hy) + ' ' + f(hx - 1) + ' ' + f(hy + hr) + ' Q ' + f(hx - hr * 0.5) + ' ' + f(hy) + ' ' + f(hx - 1) + ' ' + f(hy - hr) + ' Z', 'k');
    s += E(hx, hy, hr * 0.86, hr, 'ks w1');
    s += E(hx + hr * 0.84, hy + 2, 3.4, 5.5, 'ht2') + E(hx + hr * 0.84, hy + 2, 3.4, 5.5, 'ks w1');
    // the features, a little different on everyone
    const ey = hy - 1 + (r() - 0.5) * 3, sp = 5 + r() * 2.2, tilt = (r() - 0.5) * 2.4, mw = 3 + r() * 2.5, curve = (r() - 0.62) * 3;
    s += L(hx - sp - 2.3, ey, hx - sp + 2.3, ey, 'ps w2') + L(hx + sp - 2.3, ey, hx + sp + 2.3, ey, 'ks w2');
    s += L(hx - sp - 3, ey - 4 + tilt, hx - sp + 3, ey - 4.5, 'ps w1') + L(hx + sp - 3, ey - 4.5, hx + sp + 3, ey - 4 + tilt, 'ks w1');
    s += Pth('M' + f(hx + 1) + ' ' + f(ey + 1) + ' L' + f(hx + 3.6) + ' ' + f(ey + 7) + ' L' + f(hx) + ' ' + f(ey + 8), 'ks w1');
    s += Pth('M' + f(hx - mw) + ' ' + f(hy + 11) + ' Q ' + f(hx) + ' ' + f(hy + 11 + curve) + ' ' + f(hx + mw) + ' ' + f(hy + 11), 'ks w1');
    if (face.indexOf('lined') !== -1 || look.age === 'old') s += Pth('M' + f(hx - 5) + ' ' + f(hy - 9) + ' q5 -1.5 10 0 M' + f(hx - 4) + ' ' + f(hy - 12) + ' q4 -1.2 8 0', 'ks w1') + L(hx + sp + 3, ey + 2, hx + sp + 5, ey + 5, 'ks w1');
    if (face.indexOf('beard') !== -1) s += Pth('M' + f(hx - hr * 0.8) + ' ' + f(hy + 2) + ' Q ' + f(hx) + ' ' + f(hy + hr * 1.7) + ' ' + f(hx + hr * 0.8) + ' ' + f(hy + 2) + ' L ' + f(hx + hr * 0.6) + ' ' + f(hy + 8) + ' Q ' + hx + ' ' + f(hy + 13) + ' ' + f(hx - hr * 0.6) + ' ' + f(hy + 8) + ' Z', 'k') + Pth('M' + f(hx - 4) + ' ' + f(hy + 11) + ' q4 2 8 0', 'ps w1');
    if (face.indexOf('stubble') !== -1) s += Pth('M' + f(hx - hr * 0.7) + ' ' + f(hy + 4) + ' Q ' + hx + ' ' + f(hy + hr * 1.3) + ' ' + f(hx + hr * 0.7) + ' ' + f(hy + 4), 'ks w2 dotted');
    if (face.indexOf('moustache') !== -1) s += Pth('M' + f(hx - 6) + ' ' + f(hy + 9) + ' q6 -3.5 12 0 q-6 1.5 -12 0 Z', 'k');
    if (face.indexOf('glasses') !== -1) s += C(hx - sp, ey, 4.4, 'ps w1') + C(hx + sp, ey, 4.4, 'ks w1') + L(hx - sp + 4.4, ey, hx + sp - 4.4, ey, 'ks w1');
    if (face.indexOf('earbuds') !== -1) s += C(hx + hr * 0.86, hy + 3, 2.2, 'pp') + C(hx + hr * 0.86, hy + 3, 2.2, 'ks w1') + Pth('M' + f(hx + hr * 0.86) + ' ' + f(hy + 5) + ' Q ' + f(hx + hr) + ' ' + f(hy + 30) + ' ' + f(hx + 6) + ' 118', 'ps w1');
    if (face.indexOf('hearingaid') !== -1) s += Pth('M' + f(hx + hr * 0.8) + ' ' + f(hy - 4) + ' q6 2 3 9', 'ks w2');
    // hair or hat
    const hair = look.hair, hat = look.hat;
    const crown = 'M' + f(hx - hr * 0.9) + ' ' + f(hy - 1) + ' Q ' + f(hx - hr) + ' ' + f(hy - hr * 1.25) + ' ' + hx + ' ' + f(hy - hr * 1.1) + ' Q ' + f(hx + hr) + ' ' + f(hy - hr * 1.25) + ' ' + f(hx + hr * 0.9) + ' ' + f(hy - 1);
    if (hat === 'hood') {
      s += Pth('M' + f(hx - hr * 1.35) + ' ' + f(hy + 30) + ' Q ' + f(hx - hr * 1.5) + ' ' + f(hy - hr * 1.6) + ' ' + hx + ' ' + f(hy - hr * 1.5) + ' Q ' + f(hx + hr * 1.5) + ' ' + f(hy - hr * 1.6) + ' ' + f(hx + hr * 1.35) + ' ' + f(hy + 30) + ' L ' + f(hx + hr * 0.95) + ' ' + f(hy + 16) + ' Q ' + f(hx + hr) + ' ' + f(hy - hr * 1.1) + ' ' + hx + ' ' + f(hy - hr * 1.05) + ' Q ' + f(hx - hr) + ' ' + f(hy - hr * 1.1) + ' ' + f(hx - hr * 0.95) + ' ' + f(hy + 16) + ' Z', 'k');
      s += Pth('M' + f(hx - hr * 0.95) + ' ' + f(hy + 16) + ' Q ' + f(hx - hr) + ' ' + f(hy - hr * 1.1) + ' ' + hx + ' ' + f(hy - hr * 1.05), 'ps w1');
    } else if (hat === 'cap' || hat === 'beanie' || hat === 'flatcap' || hat === 'bandana') {
      if (hat === 'beanie') s += Pth(crown + ' Q ' + hx + ' ' + f(hy - hr * 1.9) + ' ' + f(hx - hr * 0.9) + ' ' + f(hy - 1) + ' Z', 'k') + L(hx - hr * 0.9, hy - 4, hx + hr * 0.9, hy - 4, 'ps w2');
      else if (hat === 'flatcap') s += Pth('M' + f(hx - hr * 1.05) + ' ' + f(hy - 6) + ' Q ' + hx + ' ' + f(hy - hr * 1.6) + ' ' + f(hx + hr * 1.5) + ' ' + f(hy - 8) + ' L ' + f(hx + hr * 0.2) + ' ' + f(hy - 4) + ' Z', 'k');
      else if (hat === 'bandana') s += Pth(crown + ' Q ' + hx + ' ' + f(hy - hr * 0.7) + ' ' + f(hx - hr * 0.9) + ' ' + f(hy - 1) + ' Z', 'ht3') + Pth(crown, 'ks w1') + Pth('M' + f(hx - hr * 0.9) + ' ' + f(hy - 3) + ' l-6 5 l3 1 Z', 'k');
      else s += Pth(crown + ' Q ' + hx + ' ' + f(hy - hr * 0.6) + ' ' + f(hx - hr * 0.9) + ' ' + f(hy - 1) + ' Z', 'k') + Pth('M' + f(hx + hr * 0.2) + ' ' + f(hy - 5) + ' L ' + f(hx + hr * 1.7) + ' ' + f(hy - 2) + ' L ' + f(hx + hr * 0.6) + ' ' + f(hy + 1) + ' Z', 'k') + (look.hatText ? '' : C(hx - 2, hy - hr * 0.9, 2, 'pp'));
    } else if (hair === 'long' || hair === 'ponytail' || hair === 'bun') {
      s += Pth(crown + ' Q ' + hx + ' ' + f(hy - hr * 0.7) + ' ' + f(hx - hr * 0.9) + ' ' + f(hy - 1) + ' Z', 'k') + Pth(crown, 'ps w1');
      if (hair === 'long') s += Pth('M' + f(hx - hr * 0.9) + ' ' + f(hy - 4) + ' Q ' + f(hx - hr * 1.3) + ' ' + f(hy + 30) + ' ' + f(hx - hr * 0.6) + ' ' + f(hy + 44) + ' L ' + f(hx - hr * 0.3) + ' ' + f(hy + 20) + ' Z', 'k');
      if (hair === 'ponytail') s += Pth('M' + f(hx - hr * 0.8) + ' ' + f(hy - 8) + ' Q ' + f(hx - hr * 1.8) + ' ' + f(hy + 6) + ' ' + f(hx - hr * 1.3) + ' ' + f(hy + 34) + ' Q ' + f(hx - hr * 1.1) + ' ' + f(hy + 10) + ' ' + f(hx - hr * 0.6) + ' ' + f(hy - 2) + ' Z', 'k');
      if (hair === 'bun') s += C(hx - hr * 0.5, hy - hr * 1.15, 7, 'k') + Pth('M' + f(hx - hr * 0.5 - 5) + ' ' + f(hy - hr * 1.15) + ' q5 -4 10 0', 'ps w1');
    } else if (hair === 'messy') {
      let d = 'M' + f(hx - hr * 0.95) + ' ' + f(hy - 2);
      for (let i = 0; i <= 8; i++) { const a = Math.PI + i * Math.PI / 8; d += ' L ' + f(hx + Math.cos(a) * (hr * (1.05 + (i % 2) * 0.28))) + ' ' + f(hy - 3 + Math.sin(a) * hr * (1.05 + (i % 2) * 0.3)); }
      s += Pth(d + ' Z', 'k');
    } else if (hair === 'short' || hair === 'buzz' || hair === 'parted') {
      s += Pth(crown + ' Q ' + hx + ' ' + f(hy - hr * 0.75) + ' ' + f(hx - hr * 0.9) + ' ' + f(hy - 1) + ' Z', 'k');
      if (hair === 'buzz') s += Pth(crown, 'ps w1 dotted');
      if (hair === 'parted') s += L(hx - 4, hy - hr * 1.1, hx - 7, hy - hr * 0.7, 'ps w1');
    } else if (hair === 'thin' || hair === 'bald') {
      s += Pth('M' + f(hx + 2) + ' ' + f(hy - hr * 0.92) + ' q6 1 9 6', 'ps w2');
      if (hair === 'thin') s += Pth('M' + f(hx - hr * 0.9) + ' ' + f(hy - 1) + ' q-2 -8 4 -12 M' + f(hx + hr * 0.9) + ' ' + f(hy - 1) + ' q2 -8 -4 -12', 'k w2 ks');
    }
    // what's in their hands
    if (extra.indexOf('vape') !== -1) s += R(cx + 24, 104, 5, 16, 'pp') + Pth('M' + (cx + 27) + ' 100 q6 -10 0 -18 q-6 -8 2 -16', 'ks w1 smoke');
    if (extra.indexOf('cigarette') !== -1) s += L(hx + 5, hy + 8, hx + 18, hy + 11, 'ps w2') + C(hx + 19, hy + 11, 1.6, 'rd');
    if (extra.indexOf('keys') !== -1) s += C(cx - 30, 128, 4, 'ps w1') + L(cx - 30, 132, cx - 30, 142, 'ps w2') + L(cx - 34, 132, cx - 38, 142, 'ps w2');
    if (extra.indexOf('phone') !== -1) s += R(cx + 22, 112, 12, 20, 'pp') + R(cx + 24, 115, 8, 13, 'ht2');
    if (extra.indexOf('knife') !== -1) s += L(cx - 34, 136, cx - 14, 124, 'ps w2') + R(cx - 38, 136, 6, 5, 'pp');
    if (extra.indexOf('lanyard') !== -1) s += Pth('M' + (cx - 8) + ' 98 L' + cx + ' 124 L' + (cx + 8) + ' 98', 'ps w1') + R(cx - 5, 124, 10, 13, 'pp');
    s += '</g>';
    return psvg(s, r);
  }

  function psvg(body, r) {
    let g = '';
    for (let i = 0; i < 40; i++) g += C(r() * 120, r() * 150, 0.4 + r() * 0.7, i % 3 ? 'k fl' : 'pp fl');
    return svgDoc(120, 150, '<g filter="url(#rough)">' + body + '</g>', g + R(3, 3, 114, 144, 'ks w2 frame'), 0.5);
  }

  // ---------------------------------------------------------------- the images

  function dataUrl(svg) { return 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(svg); }

  function lookOf(id, state) { return LOOK[id] ? LOOK[id](state || {}) : {}; }

  const cache = {};
  function place(id, state) {
    if (!PLACES[id]) return null;
    const look = lookOf(id, state);
    const k = 'pl:' + id + JSON.stringify(look);
    if (!cache[k]) cache[k] = wrap(PLACES[id](rng(seedOf('plate:' + id)), look), rng(seedOf('grain:' + id)));
    return cache[k];
  }
  function portraitSvg(id, look) {
    const k = 'po:' + id + JSON.stringify(look || {});
    if (!cache[k]) cache[k] = portrait(id, look);
    return cache[k];
  }
  const urls = {};
  function remember(k, make) { if (!urls[k]) urls[k] = dataUrl(make()); return urls[k]; }

  B.Plates = {
    places: Object.keys(PLACES),
    has: function (id) { return !!PLACES[id]; },
    caption: function (id) { return CAPTIONS[id] || ''; },
    look: lookOf,
    place: place,
    portrait: portraitSvg,
    placeUrl: function (id, state) {
      if (!PLACES[id]) return null;
      return remember('pl:' + id + JSON.stringify(lookOf(id, state)), function () { return place(id, state); });
    },
    portraitUrl: function (id, look) {
      return remember('po:' + id + JSON.stringify(look || {}), function () { return portraitSvg(id, look); });
    }
  };
})(globalThis.Bouncer = globalThis.Bouncer || {});
