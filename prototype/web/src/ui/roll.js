// The roll. A check is two dice, and the page takes its time with them: a rattle in the hand,
// the dice thrown onto the bar mat, the first one stopping, the page saying what the second one
// needs, the second one rolling on (when it matters, it rides up onto an edge and hangs there),
// then the result stamped. The room goes quiet while they're in the air. A tap, space or enter
// skips to the stamp. A check drawn again later (a reload, an edit) is drawn at rest.
//
// Thrown by hand (opts.hand): the dice wait at the end of the mat until the player picks them
// up. Press and hold to shake them, let go to throw. How long they're shaken changes nothing;
// the dice were decided when the choice was made. A voice may say something while they're
// shaken (opts.murmur('shake'), the hand:shake lines in barks.yaml).
//
// B.Roll.card(item, opts) -> { node, play(onDone), finish(), cancel(), inHand(), grip(), letGo() }
//   item: the check item from the Game ({voice, label, stat, statLabel, target, word, mods, roll, success, turn})
//   opts: { voiceClass, odds (text for the head), audio, speed: 'full'|'quick', still: bool,
//           hand: bool, murmur(what) -> {speaker, label, text} | null, styleOf(voice),
//           pulse(what): 'hand' (waiting in the hand), 'throw', 'stamp', 'stop' (his heart, src/ui/skin.js) }
(function (B) {
  'use strict';

  const PIPS = {
    1: [[10, 10]], 2: [[5.5, 5.5], [14.5, 14.5]], 3: [[5.5, 5.5], [10, 10], [14.5, 14.5]],
    4: [[5.5, 5.5], [14.5, 5.5], [5.5, 14.5], [14.5, 14.5]],
    5: [[5.5, 5.5], [14.5, 5.5], [10, 10], [5.5, 14.5], [14.5, 14.5]],
    6: [[5.5, 5], [14.5, 5], [5.5, 10], [14.5, 10], [5.5, 15], [14.5, 15]]
  };
  const WORD = ['', 'one', 'two', 'three', 'four', 'five', 'six'];

  // The cube: which way each face points (CSS axes: x right, y down, z toward the eye; the dice
  // lie on a plane tipped back a little, so z is "up" off the mat), and the turn,
  // rotateX(a) rotateY(b), that brings each face to the top.
  const NORMAL = { 1: [0, 0, 1], 6: [0, 0, -1], 2: [1, 0, 0], 5: [-1, 0, 0], 3: [0, -1, 0], 4: [0, 1, 0] };
  const FRONT = { 1: [0, 0], 6: [0, 180], 2: [0, -90], 5: [0, 90], 3: [-90, 0], 4: [90, 0] };
  // the extra turn [rx, ry] that brings a face lying that way (after FRONT) to the top
  const TURN = { 'x-': [0, 90], 'x+': [0, -90], 'y-': [-90, 0], 'y+': [90, 0] };

  const FULL = { shake: 500, d1: 720, n1: 4, d2: 1380, n2: 6, perT: 120, needs: 140, ring: 160, stamp: 400, after: 420 };
  const RATTLE_MS = 150;        // a rattle of the dice in the fist, over and over while held
  const SPEAK_MS = 1300;        // held this long, a voice may say something
  const QUICK = { shake: 150, d1: 380, n1: 3, d2: 560, n2: 3, perT: 0, needs: 40, ring: 60, stamp: 150, after: 160 };
  const STILL = { d1: 380, needs: 120, d2: 1150, ring: 150, stamp: 380, after: 380 };

  function rotX(v, deg) {
    const a = deg * Math.PI / 180, c = Math.cos(a), s = Math.sin(a);
    return [v[0], c * v[1] - s * v[2], s * v[1] + c * v[2]];
  }
  function rotY(v, deg) {
    const a = deg * Math.PI / 180, c = Math.cos(a), s = Math.sin(a);
    return [c * v[0] + s * v[2], v[1], -s * v[0] + c * v[2]];
  }

  // which way a face lies once `top` is up: 'x+', 'x-', 'y+', 'y-', or null (top or bottom)
  function lie(top, face) {
    const b = FRONT[top];
    const v = rotX(rotY(NORMAL[face], b[1]), b[0]);
    if (Math.abs(v[0]) > 0.5) return v[0] > 0 ? 'x+' : 'x-';
    if (Math.abs(v[1]) > 0.5) return v[1] > 0 ? 'y+' : 'y-';
    return null;
  }

  function seeded(seed) {
    let s = (seed >>> 0) || 1;
    return function () { s = (Math.imul(s, 1664525) + 1013904223) >>> 0; return s / 4294967296; };
  }

  function faceSVG(n) {
    let s = '<svg viewBox="0 0 20 20" aria-hidden="true">';
    for (const p of PIPS[n]) s += '<circle cx="' + p[0] + '" cy="' + p[1] + '" r="' + (n === 1 ? 2.8 : 1.8) + '" class="pip' + (n === 1 ? ' one' : '') + '"/>';
    return s + '</svg>';
  }

  function miniSVG(n) {
    let s = '<svg viewBox="0 0 20 20" aria-hidden="true"><rect x="1" y="1" width="18" height="18" rx="3.5" class="mf-b"/>';
    for (const p of PIPS[n]) s += '<circle cx="' + p[0] + '" cy="' + p[1] + '" r="1.7" class="mf-p"/>';
    return s + '</svg>';
  }

  function cubeHTML() {
    let h = '<div class="rl-shadow"></div><div class="rl-cube">';
    h += '<div class="rl-core cx"></div><div class="rl-core cy"></div><div class="rl-core cz"></div>';
    for (let f = 1; f <= 6; f++) h += '<div class="rl-face f' + f + '">' + faceSVG(f) + '</div>';
    return h + '</div>';
  }

  // What the second die has to show, once the first is down. The dice's stretch and the
  // modifiers are in it already, so it's the honest answer.
  function needs(r) {
    const pass = [];
    for (let b = 1; b <= 6; b++) pass.push(B.Checks.resolve(r.d1, b, r.target, r.mod, r.tension).success);
    const n = pass.filter(Boolean).length;
    const low = pass.indexOf(true) + 1;
    let text;
    if (n === 6) text = 'Any second die will do.';
    else if (n === 0) text = 'No second die can save it.';
    else if (low === 6) text = 'Needs a six on the second die.';
    else if (low === 2) text = 'Anything but a one on the second die.';
    else text = 'Needs ' + WORD[low] + ' or better on the second die.';
    return { pass: pass, n: n, text: text };
  }

  function sumText(item) {
    const r = item.roll;
    let s = r.d1 + ' + ' + r.d2 + ' = ' + r.natural;
    const swung = 7 + Math.round((r.natural - 7) * B.Checks.volatility(r.tension));
    if (swung !== r.natural) s += ', his head swings it to ' + swung;
    const bits = [s];
    for (const m of item.mods || []) bits.push((m.value > 0 ? '+' : '−') + Math.abs(m.value) + ' ' + m.label);
    bits.push(r.total + ' against ' + r.target);
    return bits.join(' · ');
  }

  function tf(s, top) {
    const b = FRONT[top];
    return 'translate3d(' + s.x.toFixed(1) + 'px,' + s.y.toFixed(1) + 'px,' + s.z.toFixed(1) + 'px) rotateZ(' + s.yaw.toFixed(1) +
      'deg) rotateX(' + s.rx.toFixed(1) + 'deg) rotateY(' + s.ry.toFixed(1) + 'deg) rotateX(' + b[0] + 'deg) rotateY(' + b[1] + 'deg)';
  }
  function shadowOf(s) {
    return {
      transform: 'translate(' + (s.x + 2 + s.z * 0.45).toFixed(1) + 'px,' + (s.y + 4 + s.z * 0.6).toFixed(1) + 'px) scale(' + (1 + s.z * 0.014).toFixed(3) + ')',
      opacity: Math.max(0.12, 0.62 - s.z * 0.014).toFixed(2)
    };
  }

  // A die's way across the mat: thrown in from the left, spinning, bouncing, then rolling over
  // its edges to a stop with `top` up (or with the turn `end` still to go). Frames are
  // {t (ms from the throw), x, y, z, yaw, rx, ry, ease, hit (a corner or face meets the mat)}.
  function path(o, rand) {
    const n = o.n;
    const w = [], dist = [];
    let sw = 0, sd = 0;
    for (let i = 0; i < n; i++) {
      const v = Math.pow(1.24, i) * (i === 0 ? 1.35 : 1);
      w.push(v); sw += v;
      const d = i === 0 ? 2.4 : Math.pow(0.6, i);
      dist.push(d); sd += d;
    }
    // the turns, worked back from where it has to finish
    const turns = [];
    let lastAxis = rand() < 0.5 ? 0 : 1;
    for (let i = 0; i < n; i++) {
      const axis = (i === 0 || rand() < 0.7) ? 1 - lastAxis : lastAxis;
      lastAxis = axis;
      const q = (i < 2 ? 180 : 90) * (rand() < 0.5 ? -1 : 1);
      const other = i === 0 ? 90 * (rand() < 0.5 ? -1 : 1) : 0;
      turns.push(axis === 0 ? [q, other] : [other, q]);
    }
    const rot = [o.end.slice()];
    for (let i = n - 1; i >= 0; i--) rot.unshift([rot[0][0] - turns[i][0], rot[0][1] - turns[i][1]]);
    const yaw0 = o.yaw + (rand() < 0.5 ? -1 : 1) * (50 + rand() * 70);
    const lift = o.ds * 0.21;                  // a cube's middle rises this much going over an edge
    const hops = [0, o.ds * 0.42, o.ds * 0.14];
    const frames = [{ t: 0, x: o.from.x, y: o.from.y, z: o.air, yaw: yaw0, rx: rot[0][0], ry: rot[0][1], ease: 'cubic-bezier(.5,0,.9,.6)' }];
    let t = 0, covered = 0;
    for (let i = 0; i < n; i++) {
      const d = o.dur * w[i] / sw;
      const was = covered;
      covered += dist[i] / sd;
      const at = function (f) {
        const c = was + (covered - was) * f;
        return { x: o.from.x * (1 - c), y: o.from.y * (1 - c), yaw: o.yaw + (yaw0 - o.yaw) * Math.pow(1 - c, 1.3) };
      };
      if (i > 0) {
        const m = at(0.5);
        const h = i < hops.length ? Math.max(hops[i], lift) : lift;
        frames.push({ t: t + d * 0.5, x: m.x, y: m.y, z: h, yaw: m.yaw, rx: (rot[i][0] + rot[i + 1][0]) / 2, ry: (rot[i][1] + rot[i + 1][1]) / 2, ease: 'ease-in' });
      }
      t += d;
      const e = at(1);
      // off each face it tips up slowing to the balance point (ease-out), then falls onto the next (ease-in)
      frames.push({ t: t, x: e.x, y: e.y, z: 0, yaw: e.yaw, rx: rot[i + 1][0], ry: rot[i + 1][1], ease: 'ease-out', hit: i });
    }
    return frames;
  }

  function card(item, opts) {
    opts = opts || {};
    const r = item.roll || {};
    const need = needs(r);
    const rand = seeded(((item.turn | 0) * 7919) ^ (r.d1 * 131 + r.d2 * 17 + (item.clock | 0)));
    const yaws = [(rand() - 0.5) * 30, (rand() - 0.5) * 30];
    const drift = [(rand() - 0.5) * 10, (rand() - 0.5) * 10];
    const crit = r.crit === 'success' ? 'Double six' : r.crit === 'fail' ? 'Double one' : '';

    const node = document.createElement('div');
    node.className = 'roll ' + (opts.voiceClass || '') + (item.success ? ' ok' : ' no') + (crit ? ' crit' : '');
    node.setAttribute('role', 'group');
    node.setAttribute('aria-label', 'Check: ' + (item.label || '') + ', ' + item.word + ' ' + item.target);
    let faces = '';
    for (let b = 1; b <= 6; b++) faces += '<span class="mf ' + (need.pass[b - 1] ? 'yes' : 'no') + '" data-f="' + b + '">' + miniSVG(b) + '</span>';
    node.innerHTML =
      '<div class="rl-head"><span class="rl-who">' + esc(item.label || '') + '</span>' + (item.statLabel ? '<span class="rl-stat">' + esc(item.statLabel) + '</span>' : '') + '<span class="rl-target">' + esc(item.word) + ' ' + item.target + '</span>' +
        (opts.odds ? '<span class="rl-odds">' + esc(opts.odds) + '</span>' : '') + '</div>' +
      '<div class="rl-body">' +
        '<div class="rl-mat" aria-hidden="true"><div class="rl-plane">' +
          '<div class="rl-die d1">' + cubeHTML() + '</div><div class="rl-die d2">' + cubeHTML() + '</div>' +
        '</div></div>' +
        '<div class="rl-stampbox"><div class="rl-stamp"><b>' + (item.success ? 'Success' : 'Failure') + '</b>' + (crit ? '<small>' + crit + '</small>' : '') + '</div>' +
          '<div class="rl-hint" aria-hidden="true">Hold to shake them.<br>Let go to throw.</div></div>' +
      '</div>' +
      '<div class="rl-voice" aria-live="polite"></div>' +
      '<div class="rl-needs"><span class="rl-faces" aria-hidden="true">' + faces + '</span><span class="rl-nt">' + esc(need.text) + '</span></div>' +
      '<div class="rl-sum">' + esc(sumText(item)) + '</div>' +
      '<span class="sr rl-sr"></span>';

    const dieEls = node.querySelectorAll('.rl-die');
    const cubes = [dieEls[0].querySelector('.rl-cube'), dieEls[1].querySelector('.rl-cube')];
    const shadows = [dieEls[0].querySelector('.rl-shadow'), dieEls[1].querySelector('.rl-shadow')];
    const tops = [r.d1, r.d2];
    const rest = function (k) { return { x: drift[k], y: drift[1 - k] * 0.6, z: 0, yaw: yaws[k], rx: 0, ry: 0 }; };

    let timers = [], anims = [], done = null, over = false, stamped = false;
    // in the hand: waiting to be picked up, then shaken; `held` is where each die sits meanwhile
    let hand = null, held = null;

    function atRest(k) {
      const s = rest(k);
      cubes[k].style.transform = tf(s, tops[k]);
      const sh = shadowOf(s);
      shadows[k].style.transform = sh.transform;
      shadows[k].style.opacity = sh.opacity;
      cubes[k].classList.add('rest');
      const f = cubes[k].querySelector('.f' + tops[k]);
      if (f) f.classList.add('top');
      dieEls[k].classList.add('in');
    }
    function showNeeds() { node.classList.add('needs-in'); }
    function ring() {
      const m = node.querySelector('.mf[data-f="' + r.d2 + '"]');
      if (m) m.classList.add('hit');
    }
    function stamp(sound) {
      if (stamped) return;
      stamped = true;
      pulse('stamp');
      node.classList.add('stamped');
      node.querySelector('.rl-sr').textContent = 'Rolled ' + r.d1 + ' and ' + r.d2 + '. ' + (item.success ? 'Success' : 'Failure') + (crit ? ', ' + crit.toLowerCase() : '') + '.';
      if (opts.audio) {
        if (sound) opts.audio.sfx('stamp');
        opts.audio.duck(false);
      }
      buzz(22);
    }
    function settle() {
      for (const a of anims) { try { a.cancel(); } catch (e) { /* gone */ } }
      anims = [];
      for (const t of timers) clearTimeout(t);
      timers = [];
      atRest(0); atRest(1);
      showNeeds(); ring();
      node.classList.remove('playing');
    }

    // at rest from the start: a check drawn again, or dice set to "at once"
    function still() { settle(); stamped = true; node.classList.add('stamped'); node.querySelector('.rl-sr').textContent = 'Rolled ' + r.d1 + ' and ' + r.d2 + '. ' + (item.success ? 'Success' : 'Failure') + '.'; }

    function at(ms, fn) { timers.push(setTimeout(function () { if (!over) fn(); }, ms)); }
    function pulse(what) { if (opts.pulse) { try { opts.pulse(what); } catch (e) { /* not worth the roll */ } } }

    // ---- thrown by hand ----------------------------------------------------

    // where the dice lie at the near end of the mat before they're thrown: loose, one against the other
    function heldPose(k, lift) {
      const W = (node.querySelector('.rl-mat') || {}).offsetWidth || 300;
      const ds = dieEls[0].offsetWidth || 40;
      const lefts = [0.3 * W, 0.66 * W];
      return {
        x: ds * (0.85 + k * 1.12) - lefts[k], y: (k ? 0.2 : -0.25) * ds, z: lift || 0,
        yaw: (k ? 34 : -21) + yaws[k] * 0.5, rx: k ? -13 : 9, ry: k ? 17 : -8
      };
    }
    function pose(k, s) {
      cubes[k].style.transform = tf(s, tops[k]);
      const sh = shadowOf(s);
      shadows[k].style.transform = sh.transform;
      shadows[k].style.opacity = sh.opacity;
    }

    function waitInHand() {
      node.classList.add('in-hand');
      held = [heldPose(0), heldPose(1)];
      for (let k = 0; k < 2; k++) { pose(k, held[k]); dieEls[k].classList.add('in'); }
      hand = { shaking: false, t0: 0, raf: 0, rattle: 0, spoke: false, jig: seeded(((item.turn | 0) * 131) ^ 77) };
      node.addEventListener('pointerdown', onDown);
      node.addEventListener('contextmenu', noMenu);
      globalThis.addEventListener('pointerup', onUp);
      globalThis.addEventListener('pointercancel', onUp);
    }
    function noMenu(e) { e.preventDefault(); }
    function onDown(e) { if (e.button > 0) return; e.preventDefault(); grip(); }
    function onUp() { if (hand && hand.shaking) letGo(); }

    // picked up: the dice rattle in the fist, and jump about in it
    function grip() {
      if (!hand || hand.shaking || over) return;
      hand.shaking = true;
      hand.t0 = Date.now();
      node.classList.add('shaking');
      const a = opts.audio;
      if (a) a.sfx('dice_shake', 0.55);
      hand.rattle = setInterval(function () { if (a) a.sfx('dice_shake', 0.45 + hand.jig() * 0.35); }, RATTLE_MS * 3);
      const jiggle = function () {
        if (!hand || !hand.shaking) return;
        const r = hand.jig, lift = 7 + r() * 9;
        for (let k = 0; k < 2; k++) {
          const b = heldPose(k, lift);
          pose(k, { x: b.x + (r() - 0.5) * 9, y: b.y + (r() - 0.5) * 7, z: lift + r() * 5, yaw: b.yaw + (r() - 0.5) * 70, rx: b.rx + (r() - 0.5) * 120, ry: b.ry + (r() - 0.5) * 120 });
        }
        if (!hand.spoke && Date.now() - hand.t0 > SPEAK_MS) { hand.spoke = true; speak(); }
        hand.raf = setTimeout(jiggle, 55 + r() * 35);
      };
      jiggle();
      buzz(10);
    }

    // a voice, while they're being shaken
    function speak() {
      const w = opts.murmur ? opts.murmur('shake') : null;
      if (!w) return;
      const box = node.querySelector('.rl-voice');
      box.className = 'rl-voice v-' + ((opts.styleOf && opts.styleOf(w.speaker)) || w.speaker);
      box.innerHTML = '<span class="rv-who">' + esc(w.label) + '</span> ' + esc(w.text);
      box.classList.add('said');
      if (opts.audio) opts.audio.sfx('whisper', 0.8);
    }

    // let go: thrown from where they were in the fist
    function letGo() {
      if (!hand || over) return;
      const shook = hand.shaking ? Date.now() - hand.t0 : 0;
      clearTimeout(hand.raf);
      clearInterval(hand.rattle);
      unhand();
      node.classList.remove('in-hand', 'shaking');
      node.classList.add('thrown');
      throwIt(shook);
    }
    function unhand() {
      if (!hand) return;
      clearTimeout(hand.raf);
      clearInterval(hand.rattle);
      node.removeEventListener('pointerdown', onDown);
      node.removeEventListener('contextmenu', noMenu);
      globalThis.removeEventListener('pointerup', onUp);
      globalThis.removeEventListener('pointercancel', onUp);
      hand = null;
    }

    function play(onDone) {
      done = onDone || null;
      node.classList.add('playing');
      if (opts.hand && !opts.still && opts.speed !== 'quick') {
        if (B.Plates && B.Plates.hold) B.Plates.hold(60000);
        if (opts.audio) opts.audio.duck(true);
        waitInHand();
        pulse('hand');
        return;
      }
      throwIt(-1);
    }

    // shook: how long they were shaken in the hand (-1: not thrown by hand)
    function throwIt(shook) {
      const byHand = shook >= 0;
      if (B.Plates && B.Plates.hold) B.Plates.hold(8000);     // nothing off the press while they're in the air
      pulse('throw');
      const a = opts.audio;
      if (a) a.duck(true);
      // (a click that let go of the dice isn't a click to skip them)
      setTimeout(function () { if (!over) node.addEventListener('click', finish); }, byHand ? 250 : 0);

      if (opts.still) {
        // no movement: the same beats, the dice simply there
        const T = STILL;
        if (a) a.sfx('dice_shake', 0.7);
        at(T.d1, function () { atRest(0); if (a) a.sfx('die_land', 0.8); });
        at(T.d1 + T.needs, showNeeds);
        at(T.d2, function () { atRest(1); if (a) a.sfx('die_land', 0.8); });
        at(T.d2 + T.ring, ring);
        at(T.d2 + T.stamp, function () { stamp(true); });
        at(T.d2 + T.stamp + T.after, finish);
        return;
      }

      const T = Object.assign({}, opts.speed === 'quick' ? QUICK : FULL);
      if (byHand) T.shake = shook > 250 ? 0 : 120;      // shaken already; a quick tap gets a short rattle
      const tension = Math.max(0, r.tension | 0);
      const mat = node.querySelector('.rl-mat');
      const W = (mat && mat.offsetWidth) || 300;
      const ds = dieEls[0].offsetWidth || 40;
      const lefts = [0.3 * W, 0.66 * W];
      // suspense only where the second die decides it
      const split = need.n > 0 && need.n < 6;
      const hang = split && opts.speed !== 'quick';

      // die 2: where it finishes its tumble, and how it gets from there onto its last face
      let end2 = [0, 0], tail = [];
      if (hang) {
        const want = !item.success;                 // a face of the other outcome, next to the real one
        const near = [];
        for (let f = 1; f <= 6; f++) {
          const way = lie(r.d2, f);
          if (way && need.pass[f - 1] === want) near.push({ f: f, way: way });
        }
        let pick = near.length ? near[Math.floor(rand() * near.length)] : null;
        if (!pick) {
          for (let f = 1; f <= 6; f++) { const way = lie(r.d2, f); if (way) { pick = { f: f, way: way }; break; } }
        }
        const full = TURN[pick.way];
        const half = [full[0] / 2, full[1] / 2];
        const hold = 480 + 90 * Math.min(tension, 4);
        const lift = ds * 0.21;
        const s0 = rest(1);
        const edge = function (dt, k, ease, z) { return { dt: dt, x: s0.x, y: s0.y, z: z == null ? lift : z, yaw: s0.yaw, rx: half[0] * k, ry: half[1] * k, ease: ease }; };
        if (rand() < 0.5) {
          // it comes over the other face, rides up onto the edge, and hangs there
          end2 = full.slice();
          tail = [edge(300, 1, 'linear'), edge(hold * 0.35, 1.16, 'ease-in-out'), edge(hold * 0.35, 0.9, 'ease-in-out'), edge(hold * 0.3, 1.02, 'ease-in')];
        } else {
          // it lands on the real face, rolls on up onto the edge, and hangs there
          tail = [edge(340, 1, 'linear'), edge(hold * 0.35, 1.14, 'ease-in-out'), edge(hold * 0.35, 0.9, 'ease-in-out'), edge(hold * 0.3, 1.02, 'ease-in')];
        }
        tail.push({ dt: 200, x: s0.x, y: s0.y, z: 0, yaw: s0.yaw, rx: 0, ry: 0, ease: 'ease-out', hit: 'land' });
        tail.push({ dt: 70, x: s0.x, y: s0.y, z: ds * 0.02, yaw: s0.yaw, rx: -half[0] * 0.09, ry: -half[1] * 0.09, ease: 'ease-in' });
        tail.push({ dt: 90, x: s0.x, y: s0.y, z: 0, yaw: s0.yaw, rx: 0, ry: 0, ease: 'linear' });
      }

      // the louder his head, the longer the second die takes
      const d1 = T.d1, d2 = T.d2 + T.perT * Math.min(tension, 4) - (hang || opts.speed === 'quick' ? 0 : 260);
      // thrown from the fist at the near end of the mat, or in from off the edge of it
      const from = byHand
        ? [heldPose(0), heldPose(1)].map(function (h, k) { const r0 = rest(k); return { x: h.x - r0.x, y: h.y - r0.y }; })
        : [{ x: -(lefts[0] + ds * 1.3), y: -ds * 0.5 }, { x: -(lefts[1] + ds * 1.6), y: ds * 0.4 }];
      const plans = [
        path({ n: T.n1, dur: d1, from: from[0], air: ds * (byHand ? 1.2 : 0.9), yaw: yaws[0], end: [0, 0], ds: ds }, rand),
        path({ n: T.n2 + (hang ? Math.min(tension, 3) : 0), dur: d2, from: from[1], air: ds * (byHand ? 1.4 : 1.1), yaw: yaws[1], end: end2, ds: ds }, rand)
      ];
      // shift the tumbles onto their resting spots
      for (let k = 0; k < 2; k++) {
        const s = rest(k);
        for (const f of plans[k]) { f.x += s.x; f.y += s.y; }
      }
      // die 2's hang, after its tumble
      let t2 = plans[1][plans[1].length - 1].t;
      for (const f of tail) { t2 += f.dt; f.t = t2; plans[1].push(f); }

      const lands = [];
      for (let k = 0; k < 2; k++) {
        const fr = plans[k];
        const total = fr[fr.length - 1].t;
        lands.push(T.shake + total);
        const keys = [], skeys = [];
        for (const f of fr) {
          const off = total ? f.t / total : 1;
          keys.push({ offset: off, transform: tf(f, tops[k]), easing: f.ease || 'linear' });
          const sh = shadowOf(f);
          skeys.push({ offset: off, transform: sh.transform, opacity: sh.opacity, easing: f.ease || 'linear' });
        }
        dieEls[k].classList.add('in');
        try {
          anims.push(cubes[k].animate(keys, { duration: total, delay: T.shake, fill: 'both' }));
          anims.push(shadows[k].animate(skeys, { duration: total, delay: T.shake, fill: 'both' }));
        } catch (e) { /* no animation here: the timers still run the beats */ }
        // the sound of each contact, quieter as it slows
        let v = 1;
        fr.forEach(function (f, i) {
          if (f.hit == null) return;
          const last = i === fr.length - 1 || f.hit === 'land';
          const vol = v;
          at(T.shake + f.t, function () {
            if (a) a.sfx(last ? 'die_land' : 'die_tick', last ? 0.9 : vol);
            if (last) buzz(8);
          });
          v *= 0.72;
        });
        at(lands[k], function () {
          cubes[k].classList.add('rest');
          const f = cubes[k].querySelector('.f' + tops[k]);
          if (f) f.classList.add('top');
        });
      }
      if (a && !(byHand && T.shake === 0)) a.sfx('dice_shake', 1);
      at(lands[0] + T.needs, showNeeds);
      const land2 = Math.max(lands[1], lands[0] + T.needs + 200);
      at(land2 + T.ring, ring);
      at(land2 + T.stamp, function () { stamp(true); });
      at(land2 + T.stamp + T.after, finish);
    }

    // skip to the end (or it got there); tells the page once
    function finish() {
      if (over) return;
      const soundNow = !stamped;
      unhand();
      node.classList.remove('in-hand', 'shaking');
      settle();
      stamp(soundNow);
      over = true;
      node.removeEventListener('click', finish);
      if (B.Plates && B.Plates.hold) B.Plates.hold(0);
      const cb = done;
      done = null;
      if (cb) cb();
    }

    function cancel() {
      if (over) return;
      over = true;
      done = null;
      unhand();
      for (const a of anims) { try { a.cancel(); } catch (e) { /* gone */ } }
      for (const t of timers) clearTimeout(t);
      if (opts.audio) opts.audio.duck(false);
      node.removeEventListener('click', finish);
      if (B.Plates && B.Plates.hold) B.Plates.hold(0);
      pulse('stop');
    }

    return {
      node: node, play: play, finish: finish, cancel: cancel, still: still,
      inHand: function () { return !!hand; },
      grip: grip,
      letGo: function () { if (hand && hand.shaking) letGo(); else if (hand) { grip(); letGo(); } }
    };
  }

  function buzz(ms) {
    try { if (navigator.vibrate) navigator.vibrate(ms); } catch (e) { /* not here */ }
  }

  function esc(s) { return B.util.escapeHtml(String(s)); }

  B.Roll = { card: card, needs: needs, sumText: sumText, lie: lie };
})(globalThis.Bouncer = globalThis.Bouncer || {});
