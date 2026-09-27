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

    // A licence. mode: 'hand' (his hands), 'tiny' (in a photo on a phone), 'copy' (photocopied into
    // the binder). A card with no name (d.blank) is somebody's photocopied licence gone too dark to
    // read anything but the face.
    function cardEl(d, mode, face) {
      const card = h('div', 'lic lic-' + mode);
      if (d.wear) card.classList.add('lic-' + d.wear);
      const inner = h('div', 'lic-in');
      const front = h('div', 'lic-side lic-front');
      const band = h('div', 'lic-band');
      band.append(h('span', 'lic-title', "DRIVER'S LICENCE"), h('span', 'lic-cls', d.blank ? '' : 'CLASS ' + d['class']));
      const photo = h('div', 'lic-photo');
      photo.append(face || idPhoto(d.face, d.look));
      const f = h('div', 'lic-fields');
      if (d.blank) {
        for (const w of [62, 48, 70, 40, 56, 66, 34]) { const bar = h('i', 'lic-x'); bar.style.width = w + '%'; f.append(bar); }
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
      front.append(band, photo, f, ghost, h('div', 'lic-holo'), h('div', 'lic-glare'));
      if (d.wear === 'wet') front.append(h('div', 'lic-damp'));
      inner.append(front);
      if (mode === 'hand') {
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
      const at = item.propAt || { turn: api.turn(), clock: 0 };
      const fig = h('figure', 'prop prop-' + pr.kind);
      fig.dataset.prop = id;
      const s = { id: id, turn: at.turn | 0, el: fig, live: false, born: Date.now(), setLive: function () {} };
      if (pr.kind === 'card') buildCard(s, pr, item);
      else if (pr.kind === 'phone') buildPhone(s, pr, item, at);
      else if (pr.kind === 'binder') buildBinder(s, pr);
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
        if (last[s.id] === s) { try { live = s.turn === turn || api.waits(s.id).length > 0; } catch (e) { live = false; } }
        if (live !== s.live) { s.live = live; s.el.classList.toggle('live', live); s.el.classList.toggle('spent', !live); s.setLive(live); }
        if (s.el.isConnected) s.placed = true;
      }
    }

    function can(s) { return s.live && api.live(); }
    function play(id, what) { try { return api.play(id, what); } catch (e) { return false; } }
    function sfx(id, v) { if (api.audio) api.audio.sfx(id, v); }
    function hint(text) { return h('figcaption', 'prop-hint', text); }

    // ---------------------------------------------------------------- a licence in his hands

    function buildCard(s, pr, item) {
      const fig = s.el, card = cardEl(pr, 'hand');
      const whose = pr.sex === 'F' ? 'her' : 'his';
      card.tabIndex = 0;
      card.setAttribute('role', 'button');
      card.setAttribute('aria-label', "Driver's licence, " + pr.surname + ', ' + pr.given + '. Turn it over.');
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
        card.style.setProperty('--rx', rx.toFixed(2) + 'deg');
        card.style.setProperty('--ry', ry.toFixed(2) + 'deg');
        // the light across it, and how much of the hologram it catches
        card.style.setProperty('--gx', (50 + ry * 3).toFixed(1) + '%');
        card.style.setProperty('--gy', (50 - rx * 3).toFixed(1) + '%');
        card.style.setProperty('--holo', clamp((Math.abs(rx) + Math.abs(ry)) / (TILT * 1.1), 0, 1).toFixed(3));
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
        card.setAttribute('aria-label', "Driver's licence, " + pr.surname + ', ' + pr.given + (flipped ? '. The back. Turn it over.' : '. Turn it over.'));
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
