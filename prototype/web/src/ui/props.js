// Props: things he's handed, or picks up, that the player handles with their own hands
// (content/data/props.yaml; a line in the Ink hands one over with #prop:, drawn under that line).
//
//   a licence   tap it and it turns over. Tip it (the pointer moving across it, or a finger
//               dragging it about) and the light slides over the hologram. Lift it (drag it up, or
//               "Hold it up by his face") and it goes up beside the face of whoever handed it over,
//               for the player to compare.
//   a phone     tap it to look closer; swipe it for the next photo. A swipe only goes through when
//               the story is waiting for one; otherwise the hand holding it holds on.
//   the binder  open it and leaf through the sleeves (the arrows, a swipe, the arrow keys). Stay on
//               a page and he's looking at that page; get to the back and he's been through them all.
//   a thing     the rest (kind: thing): tap it to turn it over; "Look closer" brings it up.
//
// Every handling goes to the game (api.play(id, what), Game.toy): if a choice is waiting for it,
// that choice is made; otherwise a voice may say something. A thing is in his hands while the
// choices it came with are on offer, or while a choice on offer is waiting for it. After that it's a
// picture of how it was, and it doesn't move.
//
// B.Props(api) -> { node(item) -> <figure> | null, refresh() }
//   api: { content, play(id, what) -> 'chose' | 'said' | false, live() -> can he handle things now,
//          turn() -> the game's turn, waits(id) -> what a choice on offer waits for ['look', ...],
//          face(charId) -> <img> of them as they look tonight, or null, plates() -> draw pictures,
//          audio, reduced() -> less motion }
(function (B) {
  'use strict';

  const DWELL_MS = 3000;          // staying on a page this long is looking at it
  const LAST_MS = 700;            // at the last sleeve, a moment before he's been through them all
  const TILT = 16;                // degrees, at most
  const TILT_SEEN = 40;           // degrees of tipping, all told, before he's looked at the hologram
  // the lamp the hologram catches, up and to the left of the card: the foil's wide awake at this
  // tip (degrees, as --rx and --ry), and sleeps a tip of the wrist (WAKE, in radians) either side
  const SWEET = [8, -6];
  const WAKE = 0.2;
  const MONTHS = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];

  function h(tag, cls, text) {
    const e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text != null) e.textContent = text;
    return e;
  }
  function clamp(v, a, b) { return Math.max(a, Math.min(b, v)); }
  function hash(s) { let x = 2166136261; for (const ch of String(s)) { x ^= ch.charCodeAt(0); x = Math.imul(x, 16777619); } return x >>> 0; }
  function rng(seed) {
    let a = hash(seed) || 1;
    return function () {
      a |= 0; a = (a + 0x6D2B79F5) | 0;
      let t = Math.imul(a ^ (a >>> 15), 1 | a);
      t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }
  function pick(r, a) { return a[Math.floor(r() * a.length)]; }
  // "2026-10-17" as she writes it in marker: OCT 17/26
  function handDate(iso) {
    const m = /^(\d{4})-(\d\d)-(\d\d)/.exec(String(iso || ''));
    return m ? MONTHS[+m[2] - 1] + ' ' + (+m[3]) + '/' + m[1].slice(2) : '';
  }
  // the phone's clock: minutes since the morning the night began
  function clockStr(min) {
    const m = ((min | 0) % 1440 + 1440) % 1440, hr = Math.floor(m / 60) % 12 || 12;
    return hr + ':' + String(m % 60).padStart(2, '0');
  }
  function buzz(ms) { try { if (navigator.vibrate) navigator.vibrate(ms); } catch (e) { /* not here */ } }
  const SVGNS = 'http://www.w3.org/2000/svg';
  function svg(w, hgt, inner, cls) {
    const s = document.createElementNS(SVGNS, 'svg');
    s.setAttribute('viewBox', '0 0 ' + w + ' ' + hgt);
    s.setAttribute('preserveAspectRatio', 'none');
    s.setAttribute('aria-hidden', 'true');
    if (cls) s.setAttribute('class', cls);
    s.innerHTML = inner;
    return s;
  }

  function Props(api) {
    const C = api.content || {};
    const P = C.props || {};
    const chars = C.characters || {};
    const shown = [];             // every thing drawn: { id, turn, el, live, setLive(bool) }

    // ---------------------------------------------------------------- pictures

    // a face, straight on against the pale backdrop, the way they take them for a licence. who is
    // someone in characters.yaml (their own face, younger or older), or an id of its own for a face
    // nobody in the story has
    function idPhoto(who, look, own) {
      const c = chars[who];
      const pid = c ? (c.portrait || who) : who;
      const base = c && c.look ? { sex: c.look.sex, age: c.look.age, build: c.look.build } : {};
      const lk = Object.assign({}, base, look || {}, own ? {} : { ground: 'plain' });
      if (api.plates() && B.Plates) return B.Plates.portrait(pid, lk);
      const ph = h('span', 'pr-noface');
      ph.textContent = c && c.label ? c.label.replace(/^THE /, '').slice(0, 1) : '';
      return ph;
    }

    // his name in his own hand, near enough: loops along a line, and the tail back under it
    function signature(name) {
      const r = rng('sig:' + name);
      let d = 'M 3 ' + (15 + r() * 3).toFixed(1), x = 3;
      const n = 5 + Math.floor(r() * 4);
      for (let i = 0; i < n; i++) {
        const w = 7 + r() * 9, up = 4 + r() * 9, dn = r() * 4;
        d += ' c ' + (w * 0.15).toFixed(1) + ' ' + (-up).toFixed(1) + ' ' + (w * 0.75).toFixed(1) + ' ' + (-up).toFixed(1) + ' ' + (w * 0.45).toFixed(1) + ' ' + (-0.5).toFixed(1);
        d += ' s ' + (-w * 0.35).toFixed(1) + ' ' + (up * 0.7 + dn).toFixed(1) + ' ' + (w * 0.55).toFixed(1) + ' ' + (dn * 0.4).toFixed(1);
        x += w;
      }
      d += ' q ' + (-x * 0.35).toFixed(1) + ' ' + (5 + r() * 3).toFixed(1) + ' ' + (-x * 0.75).toFixed(1) + ' ' + (1 + r() * 2).toFixed(1);
      return svg(x + 8, 26, '<path d="' + d + '" fill="none" stroke="currentColor" stroke-width="1.1" stroke-linecap="round" stroke-linejoin="round"/>', 'lic-sig');
    }

    // the stacked barcode on the back: rows of bars between a start and a stop
    function barcode(seed) {
      const r = rng('bar:' + seed), rows = 13, W = 96;
      let out = '';
      for (let y = 0; y < rows; y++) {
        let x = 0;
        const put = function (w, on) { if (on) out += '<rect x="' + x + '" y="' + (y * 3) + '" width="' + w + '" height="3"/>'; x += w; };
        [7, 1, 1, 1, 1, 1, 1, 3].forEach(function (w, i) { put(w, i % 2 === 0); });
        let on = true;
        while (x < W - 10) { put(1 + Math.floor(r() * 3), on); on = !on; }
        x = W - 9;
        [6, 1, 1, 1].forEach(function (w, i) { put(w, i % 2 === 0); });
      }
      return svg(W, rows * 3, '<g fill="currentColor">' + out + '</g>', 'lic-bar');
    }

    // The hologram under the laminate, the same foil as the Godot build's (godot/look/licence.gdshader):
    // a field of waves; the seal over the corner of the photo, its rings and the sun coming up out of
    // three waves; and the birthday along the foot in print too small to read. Each part is a layer
    // masked to its own lines, so only the foil lights, never the card between them, and pose() in
    // buildCard lights each part at its own point in the tip. Away from the lamp it's a pale outline
    // in the laminate, and that outline is all a photo of a licence keeps (on the phone); a
    // photocopy keeps none of it (the binder).
    const SEAL = [262, 372];                 // on the card's 856 by 540
    function holoMask(inner) {
      return 'url("data:image/svg+xml,' + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 856 540" preserveAspectRatio="none">' + inner + '</svg>') + '")';
    }
    function holoParts(d) {
      const g = ' fill="none" stroke="#fff" stroke-linecap="round" stroke-linejoin="round"';
      const line = function (pts, w) { return '<path d="M ' + pts.map(function (p) { return p[0].toFixed(1) + ' ' + p[1].toFixed(1); }).join(' L ') + '"' + g + ' stroke-width="' + w + '"/>'; };
      let waves = '';
      for (let row = 0; row < 12; row++) {
        const pts = [], y0 = 22 + row * 45;
        for (let x = -12; x <= 872; x += 8) pts.push([x, y0 + Math.sin(x * 0.038 + row * 1.1) * 9]);
        waves += line(pts, 6);
      }
      const cx = SEAL[0], cy = SEAL[1];
      const rings = [0, 1, 2, 3].map(function (k) { return '<circle cx="' + cx + '" cy="' + cy + '" r="' + (94 - k * 13) + '"' + g + ' stroke-width="' + (k ? 5.5 : 8) + '"/>'; });
      const arc = [];
      for (let i = 0; i <= 32; i++) { const a = Math.PI + Math.PI * i / 32; arc.push([cx + Math.cos(a) * 28, cy + 8 + Math.sin(a) * 28]); }
      let sun = line(arc, 6);
      for (let i = 0; i < 9; i++) {
        const a = Math.PI + Math.PI * (i + 0.5) / 9;
        sun += line([[cx + Math.cos(a) * 36, cy + 8 + Math.sin(a) * 36], [cx + Math.cos(a) * 56, cy + 8 + Math.sin(a) * 56]], 5);
      }
      for (let w = 0; w < 3; w++) {
        const pts = [];
        for (let i = 0; i <= 24; i++) pts.push([cx - 50 + i * 100 / 24, cy + 22 + w * 14 + Math.sin(i * 0.9 + w) * 5]);
        sun += line(pts, 5.5);
      }
      // the birthday, small, along a wave at the foot (a licence with no birthday on it: its number)
      const m = /^(\d{4})-(\d\d)-(\d\d)/.exec(String(d.born || ''));
      const day = m ? (+m[3]) + ' ' + MONTHS[+m[2] - 1] + ' ' + m[1] : String(d.number || '');
      let micro = '';
      for (let x = 30; x < 830 && day; x += 138) {
        const y = 520 + Math.sin(x * 0.012) * 5;
        micro += '<text x="' + x + '" y="' + y.toFixed(1) + '" transform="rotate(' + (Math.cos(x * 0.012) * 3.4).toFixed(2) + ' ' + x + ' ' + y.toFixed(1) + ')" font-family="monospace" font-size="15" letter-spacing="1" fill="#fff">' + day + '</text>';
      }
      return { waves: waves, rings: rings, sun: sun, micro: micro };
    }
    function holoEl(d, mode) {
      const el = h('div', 'lic-holo');
      if (mode === 'copy') return el;           // a photocopier doesn't see foil
      const parts = holoParts(d);
      const layer = function (cls, inner) {
        const l = h('div', 'lh ' + cls);
        const url = holoMask(inner);
        l.style.webkitMaskImage = url;
        l.style.maskImage = url;
        el.append(l);
      };
      layer('lh-out', parts.waves + parts.rings.join('') + parts.sun + parts.micro);
      if (mode === 'hand') {
        layer('lh-waves', parts.waves);
        parts.rings.forEach(function (r, k) { layer('lh-ring lh-r' + k, r); });
        layer('lh-sun', parts.sun);
        layer('lh-micro', parts.micro);
      }
      return el;
    }

    // A licence. mode: 'hand' (his hands), 'tiny' (in a photo on a phone), 'copy' (photocopied into
    // the binder). A card with no name (d.blank) is somebody's photocopied licence gone too dark to
    // read anything but the face. A security worker licence (type: security) is his own, the one
    // Gary holds up in the office: its role, a number and the dates, and his name as worn bars,
    // because his name is Hutch's to give.
    function cardEl(d, mode, face) {
      const sec = d.type === 'security';
      const card = h('div', 'lic lic-' + mode + (sec ? ' lic-sec' : ''));
      if (d.wear) card.classList.add('lic-' + d.wear);
      const inner = h('div', 'lic-in');
      const front = h('div', 'lic-side lic-front');
      const band = h('div', 'lic-band');
      band.append(h('span', 'lic-title', sec ? d.role || 'SECURITY WORKER' : "DRIVER'S LICENCE"), h('span', 'lic-cls', d.blank || sec ? '' : 'CLASS ' + d['class']));
      const photo = h('div', 'lic-photo');
      photo.append(face || idPhoto(d.face, d.look));
      const f = h('div', 'lic-fields');
      if (d.blank) {
        for (const w of [62, 48, 70, 40, 56, 66, 34]) { const bar = h('i', 'lic-x'); bar.style.width = w + '%'; f.append(bar); }
      } else if (sec) {
        for (const w of [80, 60]) { const bar = h('i', 'lic-x lic-name'); bar.style.width = w + '%'; f.append(bar); }
        const dl = h('dl', 'lic-dl lic-dl1');
        for (const kv of [['LIC', d.number], ['ISS', d.issued], ['EXP', d.expires]]) {
          const cell = h('div');
          cell.append(h('dt', null, kv[0]), h('dd', null, kv[1]));
          dl.append(cell);
        }
        f.append(dl, h('div', 'lic-seal'));
      } else {
        f.append(h('div', 'lic-sur', d.surname), h('div', 'lic-given', d.given));
        const addr = h('div', 'lic-addr');          // worn past reading, like every address on every licence
        addr.append(h('i'), h('i'));
        f.append(addr);
        const dl = h('dl', 'lic-dl');
        for (const kv of [['DOB', d.born], ['EXP', d.expires], ['ISS', d.issued], ['SEX', d.sex], ['HGT', d.height + ' cm'], ['WGT', d.weight + ' kg'], ['EYES', d.eyes], ['HAIR', d.hair]]) {
          const cell = h('div');
          cell.append(h('dt', null, kv[0]), h('dd', null, kv[1]));
          dl.append(cell);
        }
        f.append(dl, h('div', 'lic-no', 'DL ' + d.number), signature(d.given + ' ' + d.surname));
      }
      const ghost = h('div', 'lic-ghost');
      if (mode === 'hand') ghost.append(idPhoto(d.face, d.look));
      front.append(band, photo, f, ghost, holoEl(d, mode), h('div', 'lic-glare'));
      if (d.wear === 'wet') front.append(h('div', 'lic-damp'));
      inner.append(front);
      if (mode === 'hand' && sec) {
        const back = h('div', 'lic-side lic-back');
        back.append(barcode(d.number),
          h('div', 'lic-bl', 'CARRY THIS LICENCE WHILE WORKING AND SHOW IT ON REQUEST.'),
          h('div', 'lic-bl dim', 'NOT TRANSFERABLE.'),
          h('div', 'lic-edge', String(d.number || '').replace(/ /g, '') + '  ' + (d.issued || '').replace(/-/g, '')));
        inner.append(back);
      } else if (mode === 'hand') {
        const back = h('div', 'lic-side lic-back');
        const cls = String(d['class'] || '');
        back.append(barcode(d.number || d.surname),
          h('div', 'lic-bl', /N$/.test(cls) ? 'CLASS ' + cls.replace(/N$/, '') + ' · NEW DRIVER · DISPLAY N' : 'CLASS ' + cls),
          h('div', 'lic-bl dim', 'RESTRICTIONS: NONE · ENDORSEMENTS: NONE'),
          h('div', 'lic-edge', String(d.number || '').split('').reverse().join('') + '  ' + (d.issued || '').replace(/-/g, '')));
        inner.append(back);
      }
      card.append(inner);
      return card;
    }

    // ---------------------------------------------------------------- a thing in the log

    function node(item) {
      const id = item && item.prop;
      const pr = id && P[id];
      if (!pr || !pr.kind) return null;
      // #prop: hoodie_card back: he gives it back; nothing new to draw, and the last one's spent
      if (item.propHow === 'back') {
        for (const s of shown) if (s.id === id) s.back = true;
        refresh();
        return null;
      }
      const at = item.propAt || { turn: api.turn(), clock: 0 };
      const fig = h('figure', 'prop prop-' + pr.kind);
      fig.dataset.prop = id;
      const s = { id: id, turn: at.turn | 0, el: fig, live: false, born: Date.now(), setLive: function () {} };
      if (pr.kind === 'card') buildCard(s, pr, item);
      else if (pr.kind === 'phone') buildPhone(s, pr, item, at);
      else if (pr.kind === 'binder') buildBinder(s, pr);
      else if (pr.kind === 'thing' && thingPic(pr, true)) buildThing(s, pr);
      else return null;
      shown.push(s);
      refresh();
      return fig;
    }

    // who's handling it now, and who isn't: the last of each thing drawn, while its choices are on
    // offer or a choice is waiting for it
    function refresh() {
      const now = Date.now();
      for (let i = shown.length - 1; i >= 0; i--) if (!shown[i].el.isConnected && (shown[i].placed || now - shown[i].born > 2000)) shown.splice(i, 1);
      const turn = api.turn(), last = {};
      for (const s of shown) last[s.id] = s;
      for (const s of shown) {
        let live = false;
        if (last[s.id] === s && !s.back) { try { live = s.turn === turn || api.waits(s.id).length > 0; } catch (e) { live = false; } }
        if (live !== s.live) { s.live = live; s.el.classList.toggle('live', live); s.el.classList.toggle('spent', !live); s.setLive(live); }
        if (s.el.isConnected) s.placed = true;
      }
    }

    function can(s) { return s.live && api.live(); }
    function play(id, what) { try { return api.play(id, what); } catch (e) { return false; } }
    function sfx(id, v) { if (api.audio) api.audio.sfx(id, v); }
    function hint(text) { return h('figcaption', 'prop-hint', text); }

    // ---------------------------------------------------------------- a licence in his hands

    function cardName(pr) {
      return pr.type === 'security' ? 'Security worker licence, ' + pr.number : "Driver's licence, " + pr.surname + ', ' + pr.given;
    }

    function buildCard(s, pr, item) {
      const fig = s.el, card = cardEl(pr, 'hand');
      const whose = pr.sex === 'F' ? 'her' : 'his';
      card.tabIndex = 0;
      card.setAttribute('role', 'button');
      card.setAttribute('aria-label', cardName(pr) + '. Turn it over.');
      const thing = h('div', 'prop-thing');
      thing.append(card);
      const lift = h('button', 'prop-act', 'Hold it up by ' + whose + ' face');
      lift.type = 'button';
      const acts = h('div', 'prop-acts');
      acts.append(lift);
      fig.append(thing, acts, hint('Tap it to turn it over. Tip it to the light.'));
      let flipped = false, rx = 0, ry = 0, tipped = 0, tiltSaid = false, down = null, compared = null;

      function pose(x, y) {
        rx = clamp(x, -TILT, TILT); ry = clamp(y, -TILT, TILT);
        const st = card.style;
        st.setProperty('--rx', rx.toFixed(2) + 'deg');
        st.setProperty('--ry', ry.toFixed(2) + 'deg');
        // the light across it
        st.setProperty('--gx', (50 + ry * 3).toFixed(1) + '%');
        st.setProperty('--gy', (50 - rx * 3).toFixed(1) + '%');
        // the foil: awake as the card comes round to the lamp, give or take a tip of the wrist;
        // each part catches at its own point in the tip, so the rings come up one after another,
        // the colours slide down the waves, and the light runs round the seal as the tip turns
        const dx = (ry - SWEET[1]) * Math.PI / 180, dy = (rx - SWEET[0]) * Math.PI / 180;
        const wake = Math.exp(-(dx * dx + dy * dy) / (WAKE * WAKE)), far = Math.hypot(dx, dy);
        const kin = function (along, at) { return 0.35 + 0.65 * (0.5 + 0.5 * Math.cos(2 * Math.PI * (along * 2.4 - at))); };
        st.setProperty('--hw', wake.toFixed(3));
        st.setProperty('--hang', (Math.atan2(dy, dx) * 180 / Math.PI).toFixed(1) + 'deg');
        st.setProperty('--hs', (50 + dy * 300).toFixed(1) + '%');
        st.setProperty('--hm', (50 + dx * 300).toFixed(1) + '%');
        st.setProperty('--hkw', kin(dy, 0.4).toFixed(3));
        for (let k = 0; k < 4; k++) st.setProperty('--hk' + k, kin(far, 0.25 * k).toFixed(3));
        st.setProperty('--hks', kin(far, 0.55).toFixed(3));
        st.setProperty('--hkm', kin(dx, 0.33).toFixed(3));
      }
      function tip(x, y) {
        if (api.reduced()) return;
        const was = [rx, ry];
        pose(x, y);
        tipped += Math.abs(rx - was[0]) + Math.abs(ry - was[1]);
        if (!tiltSaid && tipped > TILT_SEEN && can(s)) { tiltSaid = true; play(s.id, 'tilt'); }
      }
      function rest() { card.classList.add('settle'); pose(0, 0); setTimeout(function () { card.classList.remove('settle'); }, 420); }
      function flip() {
        if (!can(s)) return;
        flipped = !flipped;
        card.classList.add('turning');
        clearTimeout(card._turnT);
        card._turnT = setTimeout(function () { card.classList.remove('turning'); }, 560);
        card.classList.toggle('flipped', flipped);
        card.setAttribute('aria-label', cardName(pr) + (flipped ? '. The back. Turn it over.' : '. Turn it over.'));
        sfx('card');
        buzz(5);
        play(s.id, 'flip');
      }
      function look() {
        if (!can(s)) return;
        card.classList.remove('lifted'); void card.offsetWidth; card.classList.add('lifted');
        sfx('card', 0.7);
        if (!compared) {
          // up beside the face: tonight, and on the card
          compared = h('div', 'lic-compare');
          const now = h('figure', 'lc-face');
          const tonight = api.face(pr.face);
          now.append(tonight || idPhoto(pr.face, null, true), h('figcaption', null, 'Tonight'));
          const then = h('figure', 'lc-face lc-card');
          then.append(idPhoto(pr.face, pr.look), h('figcaption', null, 'On the card'));
          compared.append(now, then);
          thing.append(compared);
        } else {
          compared.classList.remove('again'); void compared.offsetWidth; compared.classList.add('again');
        }
        if (flipped) { flipped = false; card.classList.add('turning'); card.classList.remove('flipped'); setTimeout(function () { card.classList.remove('turning'); }, 560); }
        play(s.id, 'look');
      }

      card.addEventListener('pointerdown', function (e) {
        if (!s.live) return;
        down = { x: e.clientX, y: e.clientY, t: Date.now(), id: e.pointerId, moved: 0, lifted: false, touch: e.pointerType !== 'mouse' };
        try { card.setPointerCapture(e.pointerId); } catch (err) { /* fine */ }
      });
      card.addEventListener('pointermove', function (e) {
        if (!s.live) return;
        if (down && e.pointerId === down.id) {
          const dx = e.clientX - down.x, dy = e.clientY - down.y;
          down.moved = Math.max(down.moved, Math.hypot(dx, dy));
          if (!down.touch && !down.lifted && dy < -60 && Math.abs(dx) < 50) { down.lifted = true; rest(); look(); return; }
          tip(-dy / 4, dx / 4);
          return;
        }
        if (e.pointerType === 'mouse') {
          const r = card.getBoundingClientRect();
          tip(((e.clientY - r.top) / r.height - 0.5) * -2 * TILT, ((e.clientX - r.left) / r.width - 0.5) * 2 * TILT);
        }
      });
      const up = function (e) {
        if (!down || e.pointerId !== down.id) return;
        const d = down;
        down = null;
        if (!d.lifted && d.moved < 7 && Date.now() - d.t < 600) flip();
        if (d.touch || d.moved >= 7) rest();
      };
      card.addEventListener('pointerup', up);
      card.addEventListener('pointercancel', function (e) { if (down && e.pointerId === down.id) { down = null; rest(); } });
      card.addEventListener('dragstart', function (e) { e.preventDefault(); });
      card.addEventListener('pointerleave', function (e) { if (e.pointerType === 'mouse' && !down) rest(); });
      card.addEventListener('keydown', function (e) {
        if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); flip(); }
        else if (e.key === 'ArrowUp') { e.preventDefault(); look(); }
        else if (e.key === 'ArrowLeft' || e.key === 'ArrowRight') { e.preventDefault(); tip(rx, ry + (e.key === 'ArrowLeft' ? -8 : 8)); setTimeout(rest, 500); }
      });
      lift.addEventListener('click', look);
      s.setLive = function (live) {
        lift.disabled = !live;
        card.tabIndex = live ? 0 : -1;
        if (!live) { down = null; rest(); }
      };
      pose(0, 0);
    }

    // ---------------------------------------------------------------- a thing in his hand

    // The things he handles that aren't a licence, a phone or the binder (content/data/props.yaml,
    // kind: thing), drawn the way the Godot build prints them (godot/game/things.gd): what's printed
    // on each side, and what's been pencilled on it. Tap it to turn it over; "Look closer" brings it
    // up. The game hears both (Game.toy: "turn", "look").
    const PENCIL = '#4a4a50';
    const TF = {
      ui: "'Barlow Condensed',sans-serif;font-weight:600", hand: 'Kalam,cursive', mono: "'IBM Plex Mono',monospace",
      anton: 'Anton,Impact,sans-serif', disp: "'Big Shoulders Display','Barlow Condensed',sans-serif;font-weight:300",
      rec: "'Courier Prime',monospace", plain: "'Barlow Condensed',sans-serif"
    };
    function xe(s) { return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;'); }
    function tx(x, y, s, size, font, fill, more) {
      return '<text x="' + x + '" y="' + y + '" fill="' + fill + '" style="font-family:' + font + ';font-size:' + size + 'px' + (more || '') + '">' + xe(s) + '</text>';
    }
    function mid(x, y, s, size, font, fill, more) { return tx(x, y, s, size, font, fill, ';text-anchor:middle' + (more || '')); }
    function pts(a) { return a.map(function (p) { return p[0].toFixed(1) + ',' + p[1].toFixed(1); }).join(' '); }
    function line(a, col, w, more) { return '<polyline points="' + pts(a) + '" fill="none" stroke="' + col + '" stroke-width="' + w + '" stroke-linecap="round" stroke-linejoin="round"' + (more || '') + '/>'; }
    // a line of the yaml's front: or back: list, and whether it's in pencil ("~ ...") or printed
    function sides(pr, side) {
      return (pr[side] || []).map(function (l) { const s = String(l); return [s.replace(/^~/, '').trim(), /^~/.test(s)]; });
    }
    // a ring gone round in pencil, never quite closing
    function pencilRing(cx, cy, rx, ry, r, w) {
      const a = [];
      for (let i = 0; i <= 52; i++) {
        const t = Math.PI * 2 * i / 48, k = 1 + (r() - 0.5) * 0.1;
        a.push([cx + Math.cos(t) * rx * k, cy + Math.sin(t) * ry * k]);
      }
      return line(a, PENCIL, w || 2.4, ' opacity=".9"');
    }
    // the knot as he drew it: a ring of rats, heads out, each one shaded in, the tails run in to the
    // middle and tied there, gone over and over
    function knot(cx, cy, rad, r) {
      let s = '';
      const n = 9;
      for (let i = 0; i < n; i++) {
        const a = Math.PI * 2 * (i + 0.5) / n - Math.PI / 2 + (r() - 0.5) * 0.12;
        const d = [Math.cos(a), Math.sin(a)], sd = [-d[1], d[0]];
        const at = function (along, across) { return [cx + d[0] * (rad + along) + sd[0] * across, cy + d[1] * (rad + along) + sd[1] * across]; };
        const deg = (a * 180 / Math.PI).toFixed(1);
        const b = at(13, 0), hd = at(33, 0);
        s += '<ellipse cx="' + b[0].toFixed(1) + '" cy="' + b[1].toFixed(1) + '" rx="17" ry="10.5" transform="rotate(' + deg + ' ' + b[0].toFixed(1) + ' ' + b[1].toFixed(1) + ')" fill="' + PENCIL + '" fill-opacity=".42" stroke="' + PENCIL + '" stroke-width="2"/>';
        s += '<ellipse cx="' + hd[0].toFixed(1) + '" cy="' + hd[1].toFixed(1) + '" rx="11" ry="6.5" transform="rotate(' + deg + ' ' + hd[0].toFixed(1) + ' ' + hd[1].toFixed(1) + ')" fill="' + PENCIL + '" fill-opacity=".42"/>';
        s += line([at(39, 4), at(45, 0), at(39, -4)], PENCIL, 2);
        for (const e of [-1, 1]) {
          const ear = at(27, e * 8.5);
          s += '<circle cx="' + ear[0].toFixed(1) + '" cy="' + ear[1].toFixed(1) + '" r="4.2" fill="none" stroke="' + PENCIL + '" stroke-width="1.6"/>';
          s += line([at(20, e * 9), at(24, e * 15)], PENCIL, 1.6, ' opacity=".75"');
          s += line([at(4, e * 9), at(1, e * 15)], PENCIL, 1.6, ' opacity=".75"');
        }
        const tail = [];
        for (let k = 0; k <= 10; k++) { const t = k / 10; tail.push(at(-(4 + t * (rad - 16)), Math.sin(t * Math.PI * 1.4) * 8)); }
        s += line(tail, PENCIL, 1.8, ' opacity=".85"');
      }
      s += '<ellipse cx="' + cx + '" cy="' + cy + '" rx="12" ry="10" fill="' + PENCIL + '" fill-opacity=".55"/>';
      for (let k = 0; k < 12; k++) {
        s += '<ellipse cx="' + (cx + (r() - 0.5) * 12).toFixed(1) + '" cy="' + (cy + (r() - 0.5) * 12).toFixed(1) + '" rx="' + (8 + r() * 9).toFixed(1) + '" ry="' + (6 + r() * 8).toFixed(1) + '" fill="none" stroke="' + PENCIL + '" stroke-width="1.8" opacity=".8"/>';
      }
      return s;
    }

    // each thing's picture, one side of it: [width, height, svg inside]
    function thingPic(pr, front) {
      const shape = String(pr.shape || '');
      const r = rng(shape + ':' + front);
      const fl = sides(pr, 'front'), bl = sides(pr, 'back');
      let s = '';
      switch (shape) {
        case 'flashlight': {
          // two D cells in steel: the head and its lens, the body, the knurled grip, the switch
          s += '<rect x="72" y="44" width="420" height="52" rx="10" fill="#1d1e22"/>';
          s += '<rect x="300" y="40" width="150" height="60" rx="8" fill="#16171a"/>';
          for (let x = 306; x < 446; x += 6) s += '<rect x="' + x + '" y="42" width="2" height="56" fill="#2a2b30"/>';
          s += '<path d="M 18 28 L 92 42 L 92 98 L 18 112 Z" fill="#26272c"/><rect x="10" y="28" width="12" height="84" rx="4" fill="#e9e4cf"/>';
          s += '<rect x="488" y="46" width="24" height="48" rx="7" fill="#26272c"/>';
          if (front) s += '<rect x="182" y="35" width="34" height="11" rx="3" fill="#3a3b40"/>';
          s += '<rect x="80" y="50" width="404" height="5" rx="2" fill="#fff" opacity=".1"/>';
          return [520, 140, s];
        }
        case 'key': {
          // the key to twelve on its fob: a long diamond of green plastic, the number in gold, and
          // on the back what every hotel fob used to say; the key hangs off the narrow end
          const fx = front ? 116 : 4, gold = '#c9a44c', hole = front ? 52 : 388, hx = fx + hole;
          s += '<g transform="translate(' + fx + ',4)"><polygon points="8,120 220,8 432,120 220,232" fill="#2f4a3c"/>';
          s += '<polygon points="26,120 220,20 414,120 220,220" fill="none" stroke="' + gold + '" stroke-opacity=".55" stroke-width="2.5"/>';
          s += '<circle cx="' + hole + '" cy="120" r="11" fill="#101512"/>';
          if (front) {
            s += mid(220, 64, 'THE SOVEREIGN', 14, TF.ui, gold, ';letter-spacing:2px;opacity:.85');
            s += mid(220, 154, fl.length ? fl[0][0] : '', 84, TF.anton, gold);
            s += mid(220, 188, 'HOTEL', 14, TF.ui, gold, ';letter-spacing:4px;opacity:.85');
          } else {
            s += mid(220, 106, 'DROP IN ANY MAILBOX', 21, TF.ui, gold, ';letter-spacing:2px');
            s += mid(220, 134, 'POSTAGE GUARANTEED', 21, TF.ui, gold, ';letter-spacing:2px');
            s += mid(220, 160, 'THE SOVEREIGN HOTEL', 15, TF.mono, gold, ';opacity:.8');
          }
          s += '</g><circle cx="' + hx + '" cy="124" r="20" fill="none" stroke="#b39550" stroke-width="5"/>';
          s += '<g fill="#b39550" transform="translate(' + (front ? hx - 8 : hx + 8) + ',124)' + (front ? ' scale(-1,1)' : '') + '">';
          s += '<path fill-rule="evenodd" d="M 0 0 a 18 18 0 1 0 36 0 a 18 18 0 1 0 -36 0 Z M 6 0 a 6 6 0 1 0 12 0 a 6 6 0 1 0 -12 0 Z"/>';
          s += '<rect x="34" y="-8" width="10" height="16"/><rect x="42" y="-6" width="68" height="12"/>';
          s += '<path d="M 52 6 h 8 v 7 h -8 Z M 66 6 h 7 v 5 h -7 Z M 78 6 h 9 v 8 h -9 Z M 92 6 h 6 v 4 h -6 Z"/></g>';
          return [560, 250, s];
        }
        case 'keys': {
          // the big man's keys: the ring, his truck's key, his house key, a rabbit's foot gone grey
          s += '<g' + (front ? '' : ' transform="translate(400,0) scale(-1,1)"') + '>';
          s += '<circle cx="200" cy="70" r="34" fill="none" stroke="#c9ccd0" stroke-width="6"/>';
          s += '<g transform="rotate(-28 200 104)"><rect x="174" y="104" width="52" height="70" rx="14" fill="#18181a"/><rect x="193" y="172" width="14" height="80" fill="#c9ccd0"/><path d="M 207 196 h 7 v 8 h -7 Z M 207 216 h 5 v 8 h -5 Z" fill="#c9ccd0"/></g>';
          s += '<g transform="rotate(24 200 104)"><circle cx="200" cy="128" r="24" fill="#b39550"/><circle cx="200" cy="118" r="6" fill="#20232a"/><rect x="193" y="150" width="14" height="72" fill="#b39550"/><path d="M 193 176 h -8 v 8 h 8 Z M 193 196 h -6 v 8 h 6 Z" fill="#b39550"/></g>';
          s += '<rect x="196" y="102" width="8" height="20" fill="#c9ccd0"/><ellipse cx="200" cy="168" rx="23" ry="50" fill="#8f8b84"/>';
          for (let i = 0; i < 26; i++) { const y = 124 + r() * 88, x = 200 + (r() - 0.5) * 34; s += line([[x, y], [x + (r() - 0.5) * 6, y + 6 + r() * 6]], '#a9a59d', 1.4, ' opacity=".7"'); }
          s += '</g>';
          return [400, 260, s];
        }
        case 'straw':
          // two inches of straw, cut square at both ends
          s += '<g transform="rotate(-8 150 45)"><rect x="40" y="36" width="220" height="18" fill="#ebe8e0" stroke="#a9a59b" stroke-width="1.5"/>';
          s += '<rect x="42" y="39" width="216" height="3" fill="#fff" opacity=".7"/><ellipse cx="260" cy="45" rx="4" ry="9" fill="#bdb9ae"/></g>';
          return [300, 90, s];
        case 'glass':
          // a pint of the red, pulled behind her bar: the glass, the beer, the head on it
          s += '<path d="M 40 30 L 260 30 L 236 400 Q 150 412 64 400 Z" fill="#9a5a22"/>';
          s += '<path d="M 40 30 L 260 30 L 256 84 Q 150 96 44 84 Z" fill="#efe6d2"/>';
          s += '<path d="M 40 30 L 260 30 L 236 400 Q 150 412 64 400 Z" fill="none" stroke="#d9d4c6" stroke-width="5" opacity=".8"/>';
          s += '<rect x="70" y="100" width="12" height="280" rx="6" fill="#fff" opacity=".16"/>';
          for (let i = 0; i < 18; i++) s += '<circle cx="' + (80 + r() * 140).toFixed(1) + '" cy="' + (110 + r() * 280).toFixed(1) + '" r="' + (1 + r() * 1.6).toFixed(1) + '" fill="#e8c890" opacity=".5"/>';
          return [300, 420, s];
        case 'shirt': {
          // Gary's shirt, folded out of its box: black, and turned over, what it says across his back
          s += '<rect width="600" height="650" fill="#222327"/><rect x="93" width="6" height="650" fill="#2d2f34"/><rect x="501" width="6" height="650" fill="#2d2f34"/><rect y="410" width="600" height="5" fill="#2d2f34"/>';
          for (let i = 0; i < 40; i++) s += '<rect x="' + (r() * 600).toFixed(0) + '" y="' + (r() * 650).toFixed(0) + '" width="' + (30 + r() * 90).toFixed(0) + '" height="1.5" fill="#fff" opacity=".025"/>';
          if (front) s += '<path d="M 208 14 A 92 58 0 0 0 392 14" fill="none" stroke="#18191c" stroke-width="22"/><path d="M 208 14 A 92 58 0 0 0 392 14" fill="none" stroke="#34363b" stroke-width="2"/>';
          else s += mid(300, 250, bl.length ? bl[0][0] : 'SECURITY', 74, TF.ui, '#e8e6df', ';letter-spacing:8px');
          return [600, 650, s];
        }
        case 'bill': {
          // a fifty folded small, in the press's inks and not the note's own, which is red, and red is
          // the sign's and blood's
          const ink = '#4e5a4a', ink2 = '#7a6a52', num = (front ? fl : bl).length ? (front ? fl : bl)[0][0] : '50';
          s += '<rect width="760" height="340" fill="#d9d3bd"/>';
          for (let i = 0; i < 22; i++) {
            const a = [];
            for (let x = 0; x <= 770; x += 14) a.push([x, 20 + i * 15 + Math.sin(x * 0.024 + i * 0.8) * 7 + Math.sin(x * 0.009 + i) * 4]);
            s += line(a, ink2, 1.3, ' opacity=".28"');
          }
          if (front) {
            for (let k = 0; k < 9; k++) s += '<ellipse cx="200" cy="170" rx="' + (96 - k * 7) + '" ry="' + (122 - k * 8) + '" fill="none" stroke="' + ink + '" stroke-width="1.6" opacity="' + (0.5 - k * 0.04).toFixed(2) + '"/>';
            s += tx(470, 222, num, 210, TF.disp, ink, ';opacity:.92') + tx(486, 296, 'FIFTY', 26, TF.ui, ink2, ';letter-spacing:6px');
          } else {
            for (let i = 0; i < 12; i++) s += '<rect x="' + (330 + i * 26) + '" y="' + (120 - (i % 3) * 14) + '" width="12" height="' + (140 + (i % 3) * 14) + '" fill="' + ink + '" opacity=".35"/>';
            s += tx(40, 196, num, 170, TF.disp, ink) + tx(40, 298, 'CINQUANTE', 24, TF.ui, ink2, ';letter-spacing:5px');
          }
          s += '<rect y="168" width="760" height="3" fill="#333326" opacity=".25"/><rect x="378" width="3" height="340" fill="#333326" opacity=".2"/>';
          return [760, 340, s];
        }
        case 'mat': {
          // the last doorman's beer mat: the Sov's, printed on the front; on the back, in his pencil,
          // his count of them, doubling, the knot as he drew it, and where
          s += '<rect x="4" y="4" width="504" height="504" rx="46" fill="' + (front ? '#e6dfca' : '#ddd5bf') + '"/>';
          s += '<circle cx="300" cy="290" r="150" fill="none" stroke="#73522e" stroke-width="14" opacity=".09"/>';
          if (front) {
            const navy = '#2a3550';
            s += '<circle cx="256" cy="256" r="222" fill="none" stroke="' + navy + '" stroke-width="6"/><circle cx="256" cy="256" r="208" fill="none" stroke="' + navy + '" stroke-width="2"/>';
            const look = [[190, 42, TF.ui, 4], [292, 86, TF.disp, 2], [356, 30, TF.ui, 4]];
            fl.forEach(function (l, i) { const k = look[Math.min(i, 2)]; s += mid(256, k[0], l[0], k[1], k[2], navy, ';letter-spacing:' + k[3] + 'px'); });
            for (const sx of [-1, 1]) {
              const c = [256 + sx * 150, 120];
              s += '<polygon points="' + pts([[0, -12], [4, -3], [13, -3], [6, 3], [9, 12], [0, 6], [-9, 12], [-6, 3], [-13, -3], [-4, -3]].map(function (p) { return [c[0] + p[0], c[1] + p[1]]; })) + '" fill="' + navy + '"/>';
            }
          } else {
            let y = 70;
            for (const l of bl) {
              const t = l[0];
              if (/^\(/.test(t)) { s += knot(256, y + 64, 60, r); y += 214; continue; }
              if (/^BEHIND/.test(t)) {
                s += tx(70, y + 10, t, 50, TF.hand, PENCIL, ';letter-spacing:1px');
                s += line([[66, y + 24], [326, y + 20]], PENCIL, 2.6) + line([[80, y + 31], [316, y + 28]], PENCIL, 1.8, ' opacity=".7"');
                continue;
              }
              // the date, and the count in a column of its own
              const m = /^(.*?)\s{2,}(\S+)$/.exec(t);
              const tilt = ' transform="rotate(' + ((r() - 0.6) * 2.6).toFixed(2) + ' 70 ' + y + ')"';
              s += '<g' + tilt + '>' + tx(70, y, m ? m[1] : t, 38, TF.hand, PENCIL);
              if (m) {
                s += tx(300, y, m[2], 38, TF.hand, PENCIL, ';text-anchor:end');
                if (m[2] === '35') s += pencilRing(281, y - 14, 34, 25, r);
              }
              s += '</g>';
              y += 44;
            }
          }
          return [512, 512, s];
        }
        case 'tickets': {
          // two from the machine at the terminal, one behind the other, neither torn
          const ink = '#1d2430';
          const one = function (dx, dy, behind) {
            let t = '<g transform="translate(' + dx + ',' + dy + ')"><rect width="860" height="540" fill="' + (behind ? '#e0dbcd' : '#ece8dc') + '" stroke="#000" stroke-opacity=".12"/>';
            if (front) {
              t += '<rect width="860" height="96" fill="#2d3a48"/>';
              if (!behind) {
                if (fl.length) t += tx(36, 66, fl[0][0], 46, TF.ui, '#ece8dc', ';letter-spacing:4px');
                for (let i = 1; i < fl.length; i++) t += tx(40, 166 + (i - 1) * 66, fl[i][0], i < 3 ? 46 : 52, TF.mono, ink, ';white-space:pre');
                let bx = 40, on = true;
                while (bx < 600) { const w = 3 + Math.floor(r() * 7); if (on) t += '<rect x="' + bx + '" y="440" width="' + w + '" height="70" fill="' + ink + '"/>'; bx += w; on = !on; }
                t += tx(640, 462, 'NOT VALID WITHOUT', 18, TF.mono, ink, ';opacity:.6') + tx(640, 488, 'A SAILING TIME', 18, TF.mono, ink, ';opacity:.6');
              }
            } else {
              t += '<rect y="70" width="860" height="90" fill="#3a2e24"/>';
              if (!behind) ['VALID ONLY FOR THE SAILING SHOWN.', 'NOT TRANSFERABLE. NO REFUNDS AFTER DEPARTURE.', 'KEEP THIS TICKET UNTIL YOU DISEMBARK.'].forEach(function (l, i) { t += tx(40, 244 + i * 40, l, 24, TF.mono, ink, ';opacity:.7'); });
            }
            return t + '</g>';
          };
          s += one(26, 20, true) + one(0, 0, false);
          return [888, 562, s];
        }
        case 'bag': {
          // the door float, out of the jacket's right pocket: the money in its clear bag, the till tape
          // round it; turned over, his pencil on the back of the tape
          s += '<rect width="900" height="480" rx="10" fill="#2a2c31"/>';
          for (let k = 0; k < 5; k++) s += '<rect x="' + (170 + (r() - 0.5) * 20).toFixed(0) + '" y="' + (110 + (r() - 0.5) * 16).toFixed(0) + '" width="560" height="260" rx="6" fill="#bfc2a8" style="filter:brightness(' + (1 - 0.05 * (4 - k)).toFixed(2) + ')"/>';
          const ink = '#4f5b4c';
          s += '<rect x="184" y="124" width="532" height="232" rx="4" fill="' + ink + '" opacity=".12"/>' + tx(198, 196, '20', 78, TF.disp, ink) + tx(620, 350, '20', 78, TF.disp, ink);
          for (let k = 0; k < 7; k++) s += '<ellipse cx="550" cy="240" rx="' + (70 - k * 6) + '" ry="' + (90 - k * 7) + '" fill="none" stroke="' + ink + '" stroke-width="1.4" opacity=".3"/>';
          s += '<rect x="392" y="70" width="116" height="340" fill="#f1eee4"/>';
          if (front) ['THE SOV', 'DOOR', 'FLOAT', '--------', '400.00'].forEach(function (l, i) { s += tx(402, 118 + i * 42, l, 22, TF.rec, '#262626', ';opacity:.75'); });
          else {
            bl.forEach(function (l, i) { s += tx(397, 116 + i * 64, l[0].replace(/\s{2,}/g, ' '), 18, TF.hand, PENCIL); });
            s += '<rect x="400" y="280" width="100" height="2" fill="' + PENCIL + '"/>';
          }
          s += '<rect width="900" height="46" fill="#1b2130"/>';
          for (let x = 10; x < 900; x += 16) s += '<rect x="' + x + '" y="18" width="8" height="10" fill="#6c7380"/>';
          if (front) {
            s += '<rect x="40" y="390" width="250" height="66" rx="3" fill="#e4e1d6"/>' + tx(52, 416, 'AMOUNT', 16, TF.ui, '#3d4250', ';letter-spacing:2px');
            if (fl.length) s += tx(150, 440, fl[0][0], 40, TF.hand, PENCIL);
          }
          return [900, 480, s];
        }
        case 'book': {
          // the paperback under the glove, its cover half off: two men in white, one thrown over his
          // own wrist, head first, by the other; a price sticker from a yard sale
          const white = '#ece8dc', blue = '#23303f';
          s += '<rect width="440" height="712" fill="' + blue + '"/>';
          if (front) {
            const cv = function (p) { return [220 + (p[0] - 220) * 0.9, 640 + (p[1] - 604) * 0.9]; };
            const limb = function (a, w) { return line(a.map(cv), white, w * 0.9); };
            const add = function (p, d) { return [p[0] + d[0], p[1] + d[1]]; };
            s += tx(40, 112, fl.length ? fl[0][0] : '', 84, TF.anton, '#e0b52e', ';letter-spacing:6px');
            s += tx(44, 154, "A BEGINNER'S GUIDE", 18, TF.ui, white, ';letter-spacing:4px;opacity:.8');
            s += line([[40, 604], [400, 604]].map(cv), '#3a485a', 3);
            const hip = [160, 470], sh = [172, 384];
            s += '<polygon points="' + pts([[-24, -8], [24, -8], [60, 130], [-56, 130]].map(function (d) { return cv(add(hip, d)); })) + '" fill="' + white + '"/>';
            s += '<polygon points="' + pts([[-2, 50], [4, 50], [6, 130], [-4, 130]].map(function (d) { return cv(add(hip, d)); })) + '" fill="' + blue + '"/>';
            s += limb([hip, sh], 44);
            s += '<polygon points="' + pts([[-26, -12], [26, -12], [26, -2], [-26, -2]].map(function (d) { return cv(add(hip, d)); })) + '" fill="#101418"/>';
            const h1 = cv(add(sh, [9, -50]));
            s += '<circle cx="' + h1[0].toFixed(1) + '" cy="' + h1[1].toFixed(1) + '" r="20.7" fill="' + white + '"/>';
            s += limb([add(sh, [12, 2]), [226, 352], [270, 318]], 17) + limb([add(sh, [4, 14]), [206, 428], [252, 418]], 17);
            const uh = [322, 250], us = [346, 352], ul = Math.hypot(us[0] - uh[0], us[1] - uh[1]);
            s += limb([uh, us], 40);
            const h2 = cv([us[0] + (us[0] - uh[0]) / ul * 46, us[1] + (us[1] - uh[1]) / ul * 46]);
            s += '<circle cx="' + h2[0].toFixed(1) + '" cy="' + h2[1].toFixed(1) + '" r="18.9" fill="' + white + '"/>';
            s += limb([add(us, [-10, -6]), [300, 328], [272, 318]], 15) + limb([add(us, [12, 6]), [388, 404], [402, 446]], 15);
            s += limb([uh, [284, 196], [300, 146]], 20) + limb([uh, [350, 202], [392, 186]], 20);
            s += '<polygon points="300,0 440,0 440,250 420,200 400,214 392,150 366,136 360,90 328,64 322,30" fill="#efe9da"/>';
            s += '<circle cx="380" cy="676" r="30" fill="#e08a2e"/>' + mid(380, 686, '$1', 28, TF.ui, '#2a1d10');
          } else {
            for (let i = 0; i < 9; i++) s += '<rect x="50" y="' + (120 + i * 34) + '" width="' + (340 - (i % 3) * 40) + '" height="12" rx="4" fill="' + white + '" opacity=".35"/>';
            s += '<rect x="250" y="560" width="150" height="100" fill="#ece8dc"/>';
            let x = 262;
            while (x < 388) { const w = 2 + Math.floor(r() * 4); s += '<rect x="' + x + '" y="572" width="' + w + '" height="64" fill="#101418"/>'; x += w + 2 + Math.floor(r() * 3); }
          }
          return [440, 712, s];
        }
        case 'remote': {
          // the TV remote from under her bar rag: black, the numbers, the round pad with its middle
          // worn to the plastic, the channel and the volume; on the back the battery door, and her
          // tape across it with what it's for in marker (the back: line)
          const key = '#3a3c42', label = '#a9acb3';
          s += '<rect x="6" y="6" width="248" height="928" rx="44" fill="#1c1d21"/>';
          if (front) {
            s += '<rect x="96" y="50" width="68" height="40" rx="16" fill="' + key + '"/>';
            let n = 1;
            for (let row = 0; row < 4; row++) {
              for (let col = 0; col < 3; col++) {
                if (row === 3 && col !== 1) continue;
                const x = 38 + col * 66, y = 140 + row * 74;
                s += '<rect x="' + x + '" y="' + y + '" width="52" height="50" rx="12" fill="' + key + '"/>';
                s += mid(x + 26, y + 36, row < 3 ? String(n % 10) : '0', 28, TF.ui, label, ';opacity:.85');
                n++;
              }
            }
            s += '<circle cx="130" cy="560" r="88" fill="' + key + '"/><circle cx="130" cy="560" r="34" fill="#4c4f56"/>';
            for (const x of [52, 160]) {
              s += '<rect x="' + x + '" y="690" width="48" height="150" rx="22" fill="' + key + '"/>';
              s += mid(x + 24, 728, '+', 34, TF.ui, label) + mid(x + 24, 826, '-', 34, TF.ui, label);
            }
            s += mid(76, 872, 'CH', 20, TF.ui, label, ';letter-spacing:2px') + mid(184, 872, 'VOL', 20, TF.ui, label, ';letter-spacing:2px');
          } else {
            s += '<rect x="40" y="560" width="180" height="300" rx="10" fill="#17181b"/><rect x="104" y="836" width="52" height="10" rx="4" fill="#2c2e33"/>';
            s += '<g transform="rotate(-3 130 296)"><rect x="30" y="250" width="200" height="92" rx="3" fill="#ddd3b4"/>';
            if (bl.length) s += mid(130, 318, bl[0][0], 64, TF.hand, '#22252c');
            s += '</g>';
          }
          return [260, 940, s];
        }
        case 'phone': {
          // the big man's phone out of his jacket, lit: the lock screen, his daughter's name and the
          // missed calls, and her messages one on top of the next, the newest on top (the front:
          // lines); turned over, the case, with the corner gone where it's been dropped on concrete
          s += '<rect x="4" y="4" width="392" height="812" rx="46" fill="#0c0d10"/>';
          if (front) {
            const white = '#eef1f4', who = fl.length ? fl[0][0] : '', calls = fl.length > 1 ? fl[1][0] : '';
            s += '<rect x="18" y="18" width="364" height="784" rx="34" fill="#1b2633"/><rect x="160" y="34" width="80" height="22" rx="11" fill="#0c0d10"/>';
            let y = 92;
            s += '<rect x="34" y="' + y + '" width="332" height="84" rx="18" fill="' + white + '" fill-opacity=".16"/>';
            s += tx(52, y + 30, who, 22, TF.ui, white, ';letter-spacing:2px') + tx(52, y + 66, calls, 24, TF.plain, white);
            y += 100;
            for (let i = 2; i < fl.length; i++) {
              // her sentence wrapped to the card, a line to every thirty-odd letters
              const rows = [];
              let row = '';
              for (const w of fl[i][0].split(' ')) {
                if (row && (row + ' ' + w).length > 30) { rows.push(row); row = w; } else row = row ? row + ' ' + w : w;
              }
              if (row) rows.push(row);
              const hgt = 66 + 30 * rows.length;
              s += '<rect x="34" y="' + y + '" width="332" height="' + hgt + '" rx="18" fill="' + white + '" fill-opacity=".16"/>';
              s += tx(52, y + 28, who, 20, TF.ui, white, ';letter-spacing:2px');
              rows.forEach(function (t, k) { s += tx(52, y + 62 + k * 30, t, 23, TF.plain, white); });
              y += hgt + 14;
            }
            s += '<rect x="140" y="780" width="120" height="8" rx="4" fill="' + white + '" fill-opacity=".7"/>';
          } else {
            s += '<rect x="14" y="14" width="372" height="792" rx="38" fill="#18191c"/>';
            s += '<rect x="250" y="40" width="112" height="112" rx="28" fill="#0f1012"/><circle cx="282" cy="72" r="20" fill="#26282d"/><circle cx="282" cy="120" r="20" fill="#26282d"/><circle cx="332" cy="72" r="7" fill="#3a3c42"/>';
            for (let i = 0; i < 40; i++) { const x = 30 + r() * 340, y = 40 + r() * 740; s += line([[x, y], [x + (r() - 0.5) * 30, y + (r() - 0.5) * 8]], '#2e3036', 1.4, ' opacity=".6"'); }
            s += '<path d="M 14 760 L 14 806 L 60 806 Q 40 792 30 776 Z" fill="#3a3c42"/>';
          }
          return [400, 820, s];
        }
        case 'wallet': {
          // GOOD SHOES's wallet, shut: brown, good leather worn pale along the fold, the stitching
          // round its edge; on the back the same, and the curve his hip's put in it
          const leather = '#5a3a26', stitch = '#a07a58';
          s += '<rect x="6" y="6" width="548" height="428" rx="26" fill="' + leather + '"/>';
          for (let i = 0; i < 160; i++) { const w = 8 + r() * 32; s += '<rect x="' + (10 + r() * (534 - w)).toFixed(0) + '" y="' + (10 + r() * 410).toFixed(0) + '" width="' + w.toFixed(0) + '" height="1.4" fill="#000" opacity=".08"/>'; }
          s += '<rect x="6" y="6" width="46" height="428" rx="20" fill="#887163" opacity=".8"/>';
          for (let d = 30; d < 410; d += 22) s += '<rect x="522" y="' + d + '" width="3" height="12" fill="' + stitch + '"/><rect x="70" y="' + d + '" width="3" height="12" fill="' + stitch + '"/>';
          for (let d = 76; d < 520; d += 22) s += '<rect x="' + d + '" y="24" width="12" height="3" fill="' + stitch + '"/><rect x="' + d + '" y="412" width="12" height="3" fill="' + stitch + '"/>';
          if (!front) s += '<rect x="140" y="120" width="300" height="200" rx="80" fill="#000" opacity=".1"/>';
          return [560, 440, s];
        }
        case 'jacket': {
          // a jacket folded: the last doorman's at the bottom of the drawer, or the big man's off its
          // hook (its cloth:): canvas, a corduroy collar, the flaps of its two outside pockets, the
          // stitching gone pale
          const canvas = pr.cloth ? '#' + pr.cloth : '#6e5d3e';
          s += '<rect width="840" height="680" fill="' + canvas + '"/>';
          for (let i = 0; i < 160; i++) s += '<rect x="' + (r() * 840).toFixed(0) + '" y="' + (r() * 680).toFixed(0) + '" width="' + (20 + r() * 70).toFixed(0) + '" height="1.2" fill="#000" opacity=".06"/>';
          for (const x of [0, 690]) s += '<rect x="' + x + '" width="150" height="680" fill="#000" opacity=".08"/><rect x="' + (x + 30) + '" y="300" width="90" height="120" rx="30" fill="#a39374" opacity=".55"/>';
          s += '<path d="M 220 0 A 200 110 0 0 0 620 0" fill="none" stroke="#4a3b28" stroke-width="48"/>';
          s += '<rect x="416" y="110" width="8" height="570" fill="#000" opacity=".25"/>';
          for (const y of [180, 300, 420, 540]) s += '<circle cx="446" cy="' + y + '" r="9" fill="#8d8d8d"/>';
          for (const x of [200, 480]) {
            s += '<rect x="' + x + '" y="420" width="170" height="70" rx="4" fill="#000" opacity=".12"/>';
            for (let d = x + 8; d < x + 160; d += 15) s += '<rect x="' + d + '" y="478" width="9" height="2" fill="#a08c62"/>';
          }
          return [840, 680, s];
        }
      }
      return null;
    }

    function buildThing(s, pr) {
      const fig = s.el, shape = String(pr.shape || '');
      const two = shape !== 'jacket';                 // the jacket lies folded; it has the one side
      const f = thingPic(pr, true);
      const el = h('div', 'thing thing-' + shape);
      el.tabIndex = 0;
      el.setAttribute('role', 'button');
      const name = pr.name || s.id;
      el.setAttribute('aria-label', name + (two ? '. Turn it over.' : '.'));
      const inner = h('div', 'th-in');
      const front = h('div', 'th-face th-front');
      if (f) front.append(svg(f[0], f[1], f[2]));
      inner.append(front);
      if (two) {
        const b = thingPic(pr, false), back = h('div', 'th-face th-back');
        if (b) back.append(svg(b[0], b[1], b[2]));
        inner.append(back);
      }
      el.append(inner);
      const thing = h('div', 'prop-thing');
      thing.append(el);
      const closer = h('button', 'prop-act', 'Look closer');
      closer.type = 'button';
      const acts = h('div', 'prop-acts');
      acts.append(closer);
      fig.append(thing, acts, hint(two ? 'Tap it to turn it over.' : ''));
      let flipped = false;
      function turn() {
        if (!can(s) || !two) return;
        flipped = !flipped;
        el.classList.toggle('flipped', flipped);
        el.setAttribute('aria-label', name + (flipped ? '. The back. Turn it over.' : '. Turn it over.'));
        sfx('card', 0.5);
        buzz(5);
        play(s.id, 'turn');
      }
      function look() {
        if (!can(s)) return;
        const near = !el.classList.contains('closer');
        el.classList.toggle('closer', near);
        closer.textContent = near ? 'Not so close' : 'Look closer';
        sfx('card', 0.6);
        if (near) play(s.id, 'look');
      }
      el.addEventListener('click', turn);
      el.addEventListener('keydown', function (e) {
        if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); turn(); }
        else if (e.key === 'ArrowUp') { e.preventDefault(); look(); }
      });
      closer.addEventListener('click', look);
      s.setLive = function (live) {
        closer.disabled = !live;
        el.tabIndex = live ? 0 : -1;
        if (!live && el.classList.contains('closer')) { el.classList.remove('closer'); closer.textContent = 'Look closer'; }
      };
    }

    // ---------------------------------------------------------------- the phone

    function buildPhone(s, pr, item, at) {
      const fig = s.el, held = item.propHow === 'held';
      if (held) fig.classList.add('held');
      const phone = h('div', 'phone');
      phone.tabIndex = 0;
      phone.setAttribute('role', 'button');
      phone.setAttribute('aria-label', 'His phone, a photo on the screen. Tap to look closer; swipe for the next photo.');
      const bar = h('div', 'ph-bar');
      const bat = h('span', 'ph-bat' + (pr.battery <= 15 ? ' low' : ''));
      const cell = h('i');
      cell.style.setProperty('--lvl', clamp(pr.battery | 0, 3, 100) + '%');
      bat.append(cell, document.createTextNode(pr.battery + '%'));
      bar.append(h('span', 'ph-time', clockStr(at.clock)), h('span', 'ph-sig'), bat);
      const screen = h('div', 'ph-screen');
      const track = h('div', 'ph-track');
      const slides = (pr.photos || []).map(function (ph) {
        const sl = h('div', 'ph-slide');
        if (ph.card && P[ph.card]) {
          // a licence on a kitchen table, under the flash
          sl.classList.add('ph-table');
          const c = cardEl(P[ph.card], 'tiny');
          sl.append(c, h('i', 'ph-flash'));
        } else if (ph.place) {
          // a place, from outside, through wet glass
          sl.classList.add('ph-window');
          if (api.plates() && B.Plates && B.Plates.has(ph.place)) sl.append(B.Plates.place(ph.place, {}, 'night'));
          sl.append(rainOn(s.id + ':' + ph.place), h('i', 'ph-glass'));
        }
        return sl;
      });
      for (const sl of slides) track.append(sl);
      screen.append(track);
      const strip = h('div', 'ph-strip');
      for (let i = 0; i < 7; i++) strip.append(h('i', i < slides.length ? 'real' : ''));
      phone.append(bar, screen, strip);
      const thing = h('div', 'prop-thing');
      thing.append(phone);
      fig.append(thing, hint(held ? 'Swipe for the next one.' : 'Tap to look. Swipe for the next one.'));
      let at0 = 0, down = null;

      function go(i) {
        at0 = i;
        track.style.setProperty('--at', i);
        const ts = strip.children;
        for (let k = 0; k < ts.length; k++) ts[k].classList.toggle('on', k === i);
      }
      function look() {
        if (!can(s)) return;
        phone.classList.toggle('zoom');
        sfx('swipe', 0.6);
        play(s.id, 'look');
      }
      function swipe(dir) {
        if (!can(s)) { spring(); return; }
        if (dir < 0) { spring(); return; }           // back a photo: nothing he hasn't seen
        if (at0 >= slides.length - 1) { spring(); return; }
        const r = play(s.id, 'swipe');
        if (r === 'chose') { sfx('swipe'); buzz(6); go(at0 + 1); }
        else { held0(); }
      }
      // the hand holding it holds on
      function held0() {
        phone.classList.remove('tug'); void phone.offsetWidth; phone.classList.add('tug');
        spring();
      }
      function spring() { track.classList.add('springing'); track.style.setProperty('--drag', '0px'); setTimeout(function () { track.classList.remove('springing'); }, 380); }

      screen.addEventListener('pointerdown', function (e) {
        if (!s.live) return;
        down = { x: e.clientX, y: e.clientY, id: e.pointerId, t: Date.now(), dx: 0 };
        try { screen.setPointerCapture(e.pointerId); } catch (err) { /* fine */ }
      });
      screen.addEventListener('pointermove', function (e) {
        if (!down || e.pointerId !== down.id) return;
        down.dx = e.clientX - down.x;
        // it follows the finger a little way, then it's up to him
        track.style.setProperty('--drag', clamp(down.dx * 0.5, -60, 30) + 'px');
      });
      screen.addEventListener('pointerup', function (e) {
        if (!down || e.pointerId !== down.id) return;
        const d = down; down = null;
        if (Math.abs(d.dx) < 8 && Date.now() - d.t < 600) { spring(); look(); return; }
        if (d.dx < -40) swipe(1);
        else if (d.dx > 40) swipe(-1);
        else spring();
      });
      screen.addEventListener('pointercancel', function () { down = null; spring(); });
      screen.addEventListener('dragstart', function (e) { e.preventDefault(); });
      phone.addEventListener('keydown', function (e) {
        if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); look(); }
        else if (e.key === 'ArrowRight') { e.preventDefault(); swipe(1); }
        else if (e.key === 'ArrowLeft') { e.preventDefault(); swipe(-1); }
      });
      s.setLive = function (live) { phone.tabIndex = live ? 0 : -1; if (!live) { down = null; spring(); } };
      if (held) phone.classList.add('zoom');
      go(0);
    }

    // what the copier leaves: specks of toner, and the line down the glass nobody's cleaned
    function toner(key) {
      const r = rng(key);
      let d = '';
      for (let i = 0; i < 70; i++) d += '<circle cx="' + (r() * 100).toFixed(1) + '" cy="' + (r() * 100).toFixed(1) + '" r="' + (0.12 + r() * r() * 0.6).toFixed(2) + '"/>';
      const lx = (8 + r() * 84).toFixed(1);
      d += '<rect x="' + lx + '" y="0" width="' + (0.15 + r() * 0.3).toFixed(2) + '" height="100" opacity=".45"/>';
      return svg(100, 100, '<g fill="#111">' + d + '</g>', 'bd-toner');
    }

    // rain on the glass between the phone and what it's looking at: drops, and a few running down
    function rainOn(key) {
      const r = rng('rain:' + key);
      let d = '';
      for (let i = 0; i < 44; i++) {
        const x = (r() * 100).toFixed(1), y = (r() * 100).toFixed(1), q = 0.5 + r() * r() * 2.4;
        d += '<ellipse cx="' + x + '" cy="' + y + '" rx="' + (q * 0.75).toFixed(2) + '" ry="' + q.toFixed(2) + '" fill="rgba(255,255,255,.06)" stroke="rgba(255,255,255,.42)" stroke-width=".3"/>';
      }
      for (let i = 0; i < 3; i++) {
        // one that's let go and run, wandering, a bead at the bottom of it
        const x = r() * 100, y = r() * 60, len = 10 + r() * 16;
        let dd = 'M' + x.toFixed(1) + ' ' + y.toFixed(1), yy = y, xx = x;
        for (let k = 0; k < 4; k++) { const nx = xx + (r() - 0.5) * 2.4, ny = yy + len / 4; dd += ' Q ' + ((xx + nx) / 2 + (r() - 0.5) * 1.6).toFixed(1) + ' ' + ((yy + ny) / 2).toFixed(1) + ' ' + nx.toFixed(1) + ' ' + ny.toFixed(1); xx = nx; yy = ny; }
        d += '<path d="' + dd + '" stroke="rgba(255,255,255,.26)" stroke-width=".5" fill="none"/>';
        d += '<ellipse cx="' + xx.toFixed(1) + '" cy="' + yy.toFixed(1) + '" rx="1" ry="1.3" fill="rgba(255,255,255,.08)" stroke="rgba(255,255,255,.45)" stroke-width=".3"/>';
      }
      return svg(100, 100, d, 'ph-rain');
    }

    // ---------------------------------------------------------------- the binder

    // a sleeve nobody wrote out: made up from its page number, the same every time. Behind the
    // ones she keeps at the front it goes back years.
    function madeUp(n) {
      const r = rng('binder:' + n);
      const f = r() < 0.22, age = r() < 0.3 ? 'young' : (r() < 0.28 ? 'old' : undefined);
      const face = [];
      if (!f && r() < 0.3) face.push('stubble'); else if (!f && r() < 0.2) face.push('beard');
      if (!f && r() < 0.08) face.push('moustache');
      if (r() < 0.12) face.push('glasses');
      if (age === 'old') face.push('lined');
      const who = {
        sex: f ? 'f' : undefined, age: age, build: r() < 0.22 ? 'big' : (r() < 0.15 ? 'slight' : undefined),
        hair: f ? pick(r, ['long', 'ponytail', 'short', 'bun', 'messy']) : pick(r, ['short', 'buzz', 'messy', 'parted', 'thin', 'bald', 'short', 'buzz']),
        hat: r() < 0.18 ? pick(r, ['cap', 'beanie', 'hood', 'cap']) : undefined,
        face: face, top: pick(r, ['hoodie', 'jacket', 'tshirt', 'flannel', 'hivis', 'coat', 'jacket', 'tshirt']),
        mood: pick(r, ['flat', 'hard', 'drunk', 'smile', 'wary', 'tired', 'drunk'])
      };
      const photo = r() < 0.5 ? 'photocopy' : (r() < 0.7 ? 'printout' : 'photograph');
      const tonight = Date.parse(P.tonight || '2026-11-04') || Date.now();
      const years = 1 + (n - 12) * 0.55 + r() * 0.9;
      const date = new Date(tonight - years * 365.25 * 864e5).toISOString().slice(0, 10);
      const length = pick(r, ['THREE MONTHS', 'SIX MONTHS', 'SIX MONTHS', 'ONE YEAR', 'ONE YEAR', 'ONE YEAR', 'TWO YEARS', 'LIFE']);
      return { photo: photo, who: who, date: date, length: length };
    }

    function sleeve(pr, n) {
      const pg = (pr.sleeves && pr.sleeves[n]) || madeUp(n);
      const page = h('div', 'bd-page');
      const r = rng('sleeve:' + n);
      const pic = h('div', 'bd-pic bd-' + (pg.photo || 'photocopy'));
      const fid = 'binder' + n;
      if (pg.card && P[pg.card]) pic.append(cardEl(P[pg.card], 'copy'));
      else if (pg.photo === 'photocopy') pic.append(cardEl({ blank: true }, 'copy', idPhoto(pg.face || fid, pg.who)));
      else pic.append(idPhoto(pg.face || fid, pg.who, true));
      if ((pg.photo || 'photocopy') === 'photocopy') pic.append(toner('copy:' + n));
      pic.style.setProperty('--rot', ((r() - 0.5) * 3.2).toFixed(2) + 'deg');
      const hand = h('div', 'bd-hand');
      if (pg.words) hand.append(h('b', 'bd-words', pg.words));
      else {
        if (pg.date) hand.append(h('span', 'bd-date', handDate(pg.date)));
        if (pg.reason) hand.append(h('span', 'bd-reason', pg.reason));
        if (pg.length) hand.append(h('span', 'bd-len', pg.length));
      }
      hand.style.setProperty('--rot', ((r() - 0.5) * 4).toFixed(2) + 'deg');
      page.append(pic, hand, h('span', 'bd-tab', String(n)), h('i', 'bd-cloud'));
      return page;
    }

    function buildBinder(s, pr) {
      const fig = s.el, last = pr.pages | 0 || 1;
      const binder = h('div', 'binder shut');
      const cover = h('button', 'bd-cover');
      cover.type = 'button';
      cover.setAttribute('aria-label', 'The binder. Open it.');
      cover.append(h('span', 'bd-tape', '86'), h('i', 'bd-rings'));
      const open = h('div', 'bd-open');
      const leaf = h('div', 'bd-leaf');
      const nav = h('div', 'bd-nav');
      const prev = h('button', 'bd-prev', '‹');
      const next = h('button', 'bd-next', '›');
      prev.type = next.type = 'button';
      prev.setAttribute('aria-label', 'Back a page');
      next.setAttribute('aria-label', 'Next page');
      const where = h('span', 'bd-where');
      nav.append(prev, where, next);
      open.append(h('i', 'bd-spine'), leaf, nav);
      binder.append(cover, open);
      binder.tabIndex = -1;
      const thing = h('div', 'prop-thing');
      thing.append(binder);
      const tip = hint('Open it.');
      fig.append(thing, tip);
      let n = 0, dwell = 0, lastT = 0, down = null;
      const stayed = {};

      function show(k, dir) {
        k = clamp(k, 1, last);
        if (k === n) return;
        const was = leaf.firstChild;
        const pg = sleeve(pr, k);
        if (was && dir && !api.reduced()) {
          pg.classList.add(dir > 0 ? 'in-r' : 'in-l');
          was.classList.add(dir > 0 ? 'out-l' : 'out-r');
          setTimeout(function () { if (was.parentNode) was.remove(); }, 260);
          leaf.append(pg);
        } else { leaf.textContent = ''; leaf.append(pg); }
        n = k;
        where.textContent = n + ' / ' + last;
        prev.disabled = n <= 1;
        next.disabled = n >= last;
        if (dir) sfx('page');
        clearTimeout(dwell); clearTimeout(lastT);
        if (!can(s)) return;
        // stay on a page and he's looking at it; at the back, he's been through them all
        dwell = setTimeout(function () {
          if (n !== k || stayed[k] || !can(s)) return;
          stayed[k] = true;
          play(s.id, 'page' + k);
        }, DWELL_MS);
        if (k === last) lastT = setTimeout(function () { if (n === last && can(s) && !stayed.all) { stayed.all = true; play(s.id, 'all'); } }, LAST_MS);
      }
      function openIt() {
        if (!can(s) || !binder.classList.contains('shut')) return;
        binder.classList.remove('shut');
        sfx('rings');
        tip.textContent = 'Swipe, or the arrows, to leaf through it.';
        show(1, 0);
        binder.tabIndex = 0;
        try { binder.focus({ preventScroll: true }); } catch (e) { /* fine */ }
      }
      function shut() {
        clearTimeout(dwell); clearTimeout(lastT);
        binder.classList.add('shut');
        binder.tabIndex = -1;
      }
      cover.addEventListener('click', openIt);
      prev.addEventListener('click', function () { if (can(s)) show(n - 1, -1); });
      next.addEventListener('click', function () { if (can(s)) show(n + 1, 1); });
      binder.addEventListener('keydown', function (e) {
        if (!can(s) || binder.classList.contains('shut')) return;
        if (e.key === 'ArrowRight' || e.key === 'PageDown') { e.preventDefault(); show(n + 1, 1); }
        else if (e.key === 'ArrowLeft' || e.key === 'PageUp') { e.preventDefault(); show(n - 1, -1); }
        else if (e.key === 'End') { e.preventDefault(); show(last, 1); }
        else if (e.key === 'Home') { e.preventDefault(); show(1, -1); }
      });
      leaf.addEventListener('pointerdown', function (e) {
        if (!can(s)) return;
        down = { x: e.clientX, id: e.pointerId };
        try { leaf.setPointerCapture(e.pointerId); } catch (err) { /* fine */ }
      });
      leaf.addEventListener('dragstart', function (e) { e.preventDefault(); });
      leaf.addEventListener('pointerup', function (e) {
        if (!down || e.pointerId !== down.id) return;
        const dx = e.clientX - down.x; down = null;
        if (dx < -40) show(n + 1, 1); else if (dx > 40) show(n - 1, -1);
      });
      leaf.addEventListener('pointercancel', function () { down = null; });
      s.setLive = function (live) {
        cover.disabled = !live;
        if (!live) { shut(); tip.textContent = ''; }
      };
    }

    return { node: node, refresh: refresh };
  }

  B.Props = Props;
})(globalThis.Bouncer = globalThis.Bouncer || {});
