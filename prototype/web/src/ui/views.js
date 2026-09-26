// Drawings: the floor sketch, the room in his head, dice, the clicker, portraits.
// Plain functions that return SVG or DOM. No game logic.
(function (B) {
  'use strict';

  const esc = function (s) { return B.util.escapeHtml(s); };

  // ---------------------------------------------------------------- the floor of the Sov

  // Where each place is on the sketch, and where its label goes.
  const SPOTS = {
    door:    { x: 40,  y: 222, lx: 40,  ly: 207, anchor: 'middle', label: 'Door' },
    floor:   { x: 112, y: 168, lx: 112, ly: 186, anchor: 'middle', label: 'Count' },
    t28:     { x: 186, y: 206, r: 22, label: '' },
    pool:    { x: 186, y: 123, lx: 186, ly: 158, anchor: 'middle', label: 'Pool' },
    bar:     { x: 29,  y: 170, lx: 59,  ly: 174, anchor: 'start', label: 'Bar' },
    keg:     { x: 29,  y: 88,  lx: 46,  ly: 92,  anchor: 'start', label: 'Keg room' },
    kitchen: { x: 55,  y: 30,  lx: 55,  ly: 50,  anchor: 'middle', label: 'Kitchen' },
    hall:    { x: 160, y: 47,  lx: 176, ly: 51,  anchor: 'start', label: 'Washrooms' },
    deck:    { x: 330, y: 186, lx: 330, ly: 226, anchor: 'middle', label: 'Deck' },
    lot:     { x: 262, y: 264, lx: 262, ly: 284, anchor: 'middle', label: 'Lot' }
  };

  function mapSVG() {
    const p = [];
    p.push('<svg viewBox="0 0 360 312" role="group" aria-label="Floor sketch of the Sov">');
    // outside: the lot, the highway, the water past it
    p.push('<rect x="292" y="254" width="40" height="18" rx="3" class="fix"/>');
    p.push('<text x="312" y="250" class="lbl" text-anchor="middle" style="font-size:8.5px">pickup</text>');
    p.push('<line x1="0" y1="296" x2="360" y2="296" class="dash"/>');
    p.push('<text x="6" y="309" class="lbl" style="font-size:9px">Highway</text>');
    p.push('<text x="354" y="309" class="lbl" text-anchor="end" style="font-size:9px">the strait</text>');
    // the deck, covered, on the water side
    p.push('<rect x="314" y="140" width="34" height="96" class="dash"/>');
    // walls
    p.push('<rect x="10" y="10" width="300" height="230" class="wall"/>');
    p.push('<line x1="10" y1="58" x2="310" y2="58" class="thin"/>');
    p.push('<line x1="100" y1="10" x2="100" y2="58" class="thin"/>');
    p.push('<line x1="130" y1="10" x2="130" y2="36" class="thin"/>');
    p.push('<line x1="172" y1="10" x2="172" y2="36" class="thin"/>');
    p.push('<line x1="214" y1="10" x2="214" y2="36" class="thin"/>');
    p.push('<line x1="256" y1="10" x2="256" y2="36" class="thin"/>');
    p.push('<line x1="130" y1="36" x2="256" y2="36" class="thin"/>');
    // doorways (painted over the walls)
    p.push('<line x1="28" y1="240" x2="52" y2="240" class="gap"/>');     // main door
    p.push('<line x1="310" y1="176" x2="310" y2="198" class="gap"/>');   // deck door
    p.push('<line x1="310" y1="39" x2="310" y2="55" class="gap"/>');     // hotel door
    p.push('<line x1="62" y1="58" x2="80" y2="58" class="gap"/>');       // kitchen swing door
    p.push('<line x1="120" y1="58" x2="142" y2="58" class="gap"/>');     // into the back hall
    p.push('<line x1="144" y1="36" x2="158" y2="36" class="gap"/>');
    p.push('<line x1="186" y1="36" x2="200" y2="36" class="gap"/>');
    p.push('<line x1="228" y1="36" x2="242" y2="36" class="gap"/>');
    p.push('<text x="151" y="27" class="lbl" text-anchor="middle" style="font-size:8.5px">Men</text>');
    p.push('<text x="193" y="27" class="lbl" text-anchor="middle" style="font-size:8.5px">Women</text>');
    p.push('<text x="235" y="27" class="lbl" text-anchor="middle" style="font-size:8.5px">Single</text>');
    p.push('<rect x="266" y="12" width="8" height="10" class="fix"/>');  // the payphone
    p.push('<text x="316" y="51" class="lbl" style="font-size:8.5px">Hotel</text>');
    // front window
    p.push('<line x1="120" y1="235" x2="252" y2="235" class="thin"/>');
    // the bar, the stools, the trapdoor at the far end
    p.push('<rect x="18" y="76" width="22" height="122" class="fix"/>');
    p.push('<rect x="24" y="82" width="10" height="10" class="thin"/><path d="M24 82 L34 92 M34 82 L24 92" class="thin"/>');
    for (let y = 104; y <= 184; y += 20) p.push('<circle cx="50" cy="' + y + '" r="3.2" class="thin"/>');
    // the stool at the door
    p.push('<circle cx="40" cy="226" r="4.5" class="fix"/>');
    // pool table and the jukebox
    p.push('<rect x="150" y="104" width="72" height="38" rx="2" class="fix"/>');
    p.push('<rect x="250" y="72" width="16" height="16" class="fix"/>');
    p.push('<text x="258" y="100" class="lbl" text-anchor="middle" style="font-size:8.5px">Jukebox</text>');
    // sturdy tables
    for (const t of [[84, 132], [248, 140], [104, 206], [252, 204]]) p.push('<rect x="' + t[0] + '" y="' + t[1] + '" width="14" height="14" class="thin"/>');
    // table 28, in the front window
    p.push('<circle cx="186" cy="206" r="15" class="fix"/>');
    p.push('<text x="186" y="211.5" class="big" text-anchor="middle">28</text>');
    // the places he can go
    for (const id in SPOTS) {
      const s = SPOTS[id];
      const r = s.r || 10;
      p.push('<g class="spot" data-loc="' + id + '" role="button" aria-disabled="true" aria-label="' + esc(id === 't28' ? 'Table 28' : s.label) + '">');
      p.push('<circle class="ring" cx="' + s.x + '" cy="' + s.y + '" r="' + r + '"/>');
      if (id !== 't28') p.push('<circle class="dot" cx="' + s.x + '" cy="' + s.y + '" r="2.6"/>');
      if (s.label) p.push('<text class="spot-lbl" x="' + s.lx + '" y="' + s.ly + '" text-anchor="' + s.anchor + '">' + esc(s.label) + '</text>');
      p.push('</g>');
    }
    p.push('<circle class="him" id="him" cx="-20" cy="-20" r="5.5"/>');
    p.push('</svg>');
    return p.join('');
  }

  // open: {loc: visibleIndex}; here: the location id
  function updateMap(root, here, open) {
    const spots = root.querySelectorAll('.spot');
    for (const g of spots) {
      const loc = g.getAttribute('data-loc');
      const isOpen = Object.prototype.hasOwnProperty.call(open, loc);
      g.classList.toggle('open', isOpen);
      g.setAttribute('aria-disabled', isOpen ? 'false' : 'true');
      if (isOpen) g.setAttribute('tabindex', '0'); else g.removeAttribute('tabindex');
    }
    const him = root.querySelector('#him');
    const at = SPOTS[here] || (here === 'upstairs' ? null : SPOTS.floor);
    if (him) {
      if (at) {
        const dx = here === 't28' ? 20 : 12;
        him.setAttribute('cx', at.x + dx);
        him.setAttribute('cy', at.y - 10);
      } else {
        him.setAttribute('cx', -20);
        him.setAttribute('cy', -20);
      }
    }
  }

  // ---------------------------------------------------------------- the room in his head

  const SEAT_ANGLES = [-90, -18, 54, 126, 198];

  function shortLabel(def, id) {
    return String((def && def.label) || id).replace(/^THE\s+/i, '');
  }

  function psycheSVG(psyche, defs) {
    const cx = 120, cy = 96, R = 62;
    const pts = SEAT_ANGLES.map(function (a) {
      const r = a * Math.PI / 180;
      return { x: cx + R * Math.cos(r), y: cy + R * Math.sin(r), a: a };
    });
    const seated = psyche.seated.slice(0, 5);
    const p = [];
    p.push('<svg viewBox="0 0 240 196" role="img" aria-label="The voices in his head and how they get on">');
    // edges first
    for (let i = 0; i < seated.length; i++) {
      for (let j = i + 1; j < seated.length; j++) {
        const odds = psyche.getRel(seated[i], seated[j]) < 0;
        p.push('<line x1="' + pts[i].x.toFixed(1) + '" y1="' + pts[i].y.toFixed(1) + '" x2="' + pts[j].x.toFixed(1) + '" y2="' + pts[j].y.toFixed(1) + '" class="' + (odds ? 'edge-odds' : 'edge-ally') + '"/>');
      }
    }
    for (let i = 0; i < 5; i++) {
      const pt = pts[i];
      const id = seated[i];
      if (!id) {
        p.push('<circle cx="' + pt.x.toFixed(1) + '" cy="' + pt.y.toFixed(1) + '" r="12" class="seat-empty"/>');
        continue;
      }
      const def = defs[id] || {};
      const rad = pt.a * Math.PI / 180;
      const lx = cx + (R + 30) * Math.cos(rad), ly = cy + (R + 24) * Math.sin(rad) + 4;
      const anchor = Math.abs(Math.cos(rad)) < 0.3 ? 'middle' : (Math.cos(rad) > 0 ? 'start' : 'end');
      const lxAdj = anchor === 'start' ? lx - 12 : anchor === 'end' ? lx + 12 : lx;
      p.push('<g class="voice-node v-' + esc(def.style || id) + '" data-voice="' + esc(id) + '" tabindex="0" role="button" aria-label="' + esc(def.label || id) + '">');
      p.push('<circle cx="' + pt.x.toFixed(1) + '" cy="' + pt.y.toFixed(1) + '" r="13" style="fill:var(--vc)"/>');
      p.push('<text x="' + lxAdj.toFixed(1) + '" y="' + ly.toFixed(1) + '" text-anchor="' + anchor + '" style="fill:var(--vc)">' + esc(shortLabel(def, id)) + '</text>');
      p.push('</g>');
    }
    p.push('</svg>');
    return p.join('');
  }

  const TENSION_WORDS = ['Settled', 'Uneasy', 'Arguing', 'Shouting', 'At war'];

  function tensionHTML(t) {
    t = Math.max(0, Math.min(4, t | 0));
    let ticks = '';
    for (let i = 1; i <= 4; i++) ticks += '<i class="' + (i <= t ? 'on' : '') + '"></i>';
    return '<div class="tension"><span class="tension-word">' + TENSION_WORDS[t] + '</span><span class="tension-ticks" aria-label="Tension ' + t + ' of 4">' + ticks + '</span></div>' +
      '<p class="tension-note">' + (t === 0 ? 'The voices agree. Checks go the way the odds say.' : 'The louder the room in his head, the wider his checks swing, both ways.') + '</p>';
  }

  // ---------------------------------------------------------------- small things

  const PIPS = {
    1: [[10, 10]], 2: [[5.5, 5.5], [14.5, 14.5]], 3: [[5.5, 5.5], [10, 10], [14.5, 14.5]],
    4: [[5.5, 5.5], [14.5, 5.5], [5.5, 14.5], [14.5, 14.5]],
    5: [[5.5, 5.5], [14.5, 5.5], [10, 10], [5.5, 14.5], [14.5, 14.5]],
    6: [[5.5, 5], [14.5, 5], [5.5, 10], [14.5, 10], [5.5, 15], [14.5, 15]]
  };

  function dieSVG(n) {
    const pips = (PIPS[n] || []).map(function (q) { return '<circle cx="' + q[0] + '" cy="' + q[1] + '" r="1.7" class="pip"/>'; }).join('');
    return '<svg viewBox="0 0 20 20" aria-hidden="true"><rect x="1" y="1" width="18" height="18" rx="3.5" class="die"/>' + pips + '</svg>';
  }

  function clickerHTML(n) {
    const s = String(Math.max(0, n | 0)).padStart(4, '0').slice(-4);
    let d = '';
    for (const ch of s) d += '<span>' + ch + '</span>';
    return '<span class="clicker"><span class="clicker-window" aria-label="Clicker: ' + (n | 0) + ' in">' + d + '</span><span class="clicker-label">Clicker</span></span>';
  }

  function tallyHTML(n) {
    n = Math.max(0, n | 0);
    if (!n) return '<span class="tally">none</span>';
    let out = '';
    const fives = Math.floor(n / 5), rest = n % 5;
    for (let i = 0; i < fives; i++) out += '<span class="five">||||</span> ';
    out += '|'.repeat(rest);
    return '<span class="tally" aria-label="' + n + '">' + out.trim() + '</span>';
  }

  function initials(label) {
    const words = String(label || '?').replace(/^THE\s+/i, '').split(/[\s\-]+/).filter(Boolean);
    if (words.length === 1) return words[0].slice(0, 2);
    return (words[0][0] + words[1][0]);
  }

  B.Views = {
    SPOTS: SPOTS,
    mapSVG: mapSVG,
    updateMap: updateMap,
    psycheSVG: psycheSVG,
    tensionHTML: tensionHTML,
    shortLabel: shortLabel,
    dieSVG: dieSVG,
    clickerHTML: clickerHTML,
    tallyHTML: tallyHTML,
    initials: initials
  };
})(globalThis.Bouncer = globalThis.Bouncer || {});
