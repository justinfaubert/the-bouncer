// The hand: the voices in his head reach for the player.
//
// While the player's hand is on a choice (the pointer resting on it, a key on it, a press and hold
// on a phone), a voice may lean in on it before it's made: its words come up beside the choice in
// its own type and colour, with a breath of sound close to one ear, and its seat in the head panel
// lights. And they notice the player: sitting on the choices a long while (hand:wait), scrolling
// back up the night to read it again (hand:reread), coming back to the game after a while away
// (hand:back), choosing faster than anyone could read (hand:rush).
//
// What they say comes from the engine (Game.whisper and Game.murmur; the lines are the hand: rules
// in content/rules/barks.yaml). When a choice is made the page tells the engine which others the
// player had a hand on first (leave), so a voice can say so under the choice when he passed over
// something he was tempted by. Settings → The voices notice you turns all of it off.
(function (B) {
  'use strict';

  const HOVER_MS = 320;         // the pointer resting on a choice before a voice leans in
  const KEY_MS = 450;           // the same, for a choice reached with the keyboard
  const LOOK_MS = 700;          // long enough on a choice to count as having considered it
  const HOLD_MS = 420;          // a press and hold on a phone
  const REREAD_MS = 3500;       // back up the night, and staying there
  const AWAY_MS = 4 * 60e3;     // away from the game this long, and back
  const GAP = { wait: 5, reread: 10, rush: 8, back: 0 }; // choices between one murmur of a kind and the next

  // api: { game(), on(), busy(), after, story, inner, head, audio, style(id), reduced() }
  B.Hand = function (api) {
    let shownAt = 0;              // when these choices went up
    let chars = 0;                // how much there was to read before them
    const considered = new Set(); // the choices the player has had a hand on (visible indexes)
    let hoverBtn = null, hoverT = null, lookT = null, holdT = null, waitT = null, rereadT = null, fadeT = null;
    let tip = null;               // the voice on the page now: { el, btn, mode }
    let swallow = null;           // a hold used up the next click on this button
    let hold = null;              // { btn, x, y } while a finger is down on a choice
    let rushRun = 0, rushDue = false;
    const last = { wait: -99, reread: -99, rush: -99, back: -99 };
    let hiddenAt = 0;

    const now = function () { return Date.now(); };
    const game = function () { return api.game(); };
    const enabled = function () { return !!api.on(); };
    const turn = function () { const g = game(); return g ? g.turn : 0; };
    const index = function (b) { return Number(b.getAttribute('data-i')); };

    // ---------------------------------------------------------------- what the page tells it

    // new choices are up; n is how many characters of story came before them
    function attach(n) {
      stop();
      shownAt = now();
      chars = n | 0;
      considered.clear();
      if (!enabled()) return;
      if (rushDue && turn() - last.rush >= GAP.rush) {
        rushDue = false;
        const at = shownAt;
        setTimeout(function () { if (shownAt === at && !hoverBtn && murmur('rush', 'lead')) last.rush = turn(); }, 900);
      }
      // sitting on them a long while: a little longer than it takes to read what came before
      const wait = Math.max(22e3, Math.min(80e3, 14e3 + chars * 45));
      waitT = setTimeout(onWait, wait);
    }

    // a choice has been made: which others the player had a hand on first
    function leave(i) {
      const t = now() - shownAt;
      rushRun = chars > 160 && t < chars * 12 ? rushRun + 1 : 0;
      if (rushRun >= 4) { rushRun = 0; rushDue = true; }
      const out = Array.from(considered).filter(function (k) { return k !== i; });
      stop();
      return out;
    }

    function stop() {
      for (const t of [hoverT, lookT, holdT, waitT, rereadT]) clearTimeout(t);
      hoverT = lookT = holdT = waitT = rereadT = null;
      hoverBtn = null;
      hold = null;
      hide(true);
    }

    // ---------------------------------------------------------------- a hand on a choice

    function enter(b, delay) {
      if (!enabled() || api.busy()) return;
      clearTimeout(hoverT); clearTimeout(lookT);
      hoverBtn = b;
      const i = index(b);
      lookT = setTimeout(function () { if (hoverBtn === b) considered.add(i); }, LOOK_MS);
      hoverT = setTimeout(function () { if (hoverBtn === b) lean(b, 'point'); }, delay);
    }

    function out(b) {
      clearTimeout(hoverT); clearTimeout(lookT);
      if (hoverBtn === b) hoverBtn = null;
      if (tip && tip.btn === b && tip.mode !== 'inline') hide();
    }

    // how: 'point' (the pointer or a key) or 'hold' (a finger)
    function lean(b, how) {
      if (!b.isConnected) return;
      const g = game();
      const i = index(b);
      let w = null;
      try { w = g.whisper(i); } catch (e) { w = null; }
      considered.add(i);
      if (!w) {
        // held, and nobody in there has anything to say about it
        if (how === 'hold') { b.classList.remove('held'); void b.offsetWidth; b.classList.add('held'); }
        return;
      }
      show(w, b, how === 'hold' ? 'inline' : 'beside');
      if (how === 'hold' && globalThis.navigator && typeof navigator.vibrate === 'function') { try { navigator.vibrate(12); } catch (e) { /* not offered */ } }
    }

    // ---------------------------------------------------------------- the voices notice the player

    function onWait() {
      waitT = null;
      if (!enabled()) return;
      if (api.busy() || hoverBtn || hold || document.hidden) { waitT = setTimeout(onWait, 8e3); return; }
      if (turn() - last.wait < GAP.wait) return;
      if (murmur('wait', 'lead')) last.wait = turn();
    }

    function onScroll() {
      if (!enabled() || !api.after.firstChild) return;
      const s = api.story;
      const up = s.scrollHeight - s.scrollTop - s.clientHeight;
      if (up > s.clientHeight * 1.6) {
        if (!rereadT && turn() - last.reread >= GAP.reread) {
          rereadT = setTimeout(function () {
            rereadT = null;
            const still = s.scrollHeight - s.scrollTop - s.clientHeight > s.clientHeight * 1.6;
            if (!still || !enabled() || api.busy()) return;
            if (murmur('reread', 'float')) last.reread = turn();
          }, REREAD_MS);
        }
      } else if (rereadT) { clearTimeout(rereadT); rereadT = null; }
    }

    function onVisibility() {
      if (document.hidden) { hiddenAt = now(); return; }
      const away = hiddenAt ? now() - hiddenAt : 0;
      hiddenAt = 0;
      if (away < AWAY_MS || !enabled() || !api.after.firstChild) return;
      setTimeout(function () { if (!api.busy() && murmur('back', 'float')) last.back = turn(); }, 700);
    }

    // mode: 'lead' (over the choices) or 'float' (at the foot of the page, wherever it's scrolled to)
    function murmur(what, mode) {
      const g = game();
      if (!g || !g.story) return false;
      let w = null;
      try { w = g.murmur(what); } catch (e) { w = null; }
      if (!w) return false;
      if (mode === 'lead') {
        const first = api.after.querySelector('.choice');
        if (!first) return false;
        show(w, first, 'lead');
      } else show(w, null, 'float');
      return true;
    }

    // ---------------------------------------------------------------- on the page

    // mode: 'beside' (next to a choice the pointer's on), 'inline' (under a choice held on a
    // phone), 'lead' (over the choices), 'float' (at the foot of the page)
    function show(w, b, mode) {
      hide(true);
      const el = document.createElement('div');
      el.className = 'whisper v-' + api.style(w.speaker);
      el.setAttribute('role', 'status');
      const who = document.createElement('span');
      who.className = 'wh-who';
      who.textContent = w.label;
      const said = document.createElement('span');
      said.className = 'wh-said';
      // the words come one after another, the way someone leans in and says it
      String(w.text).split(/(\s+)/).forEach(function (part, k) {
        if (!part) return;
        if (/^\s+$/.test(part)) { said.append(document.createTextNode(part)); return; }
        const s = document.createElement('span');
        s.style.setProperty('--d', String(k >> 1));
        s.textContent = part;
        said.append(s);
      });
      el.append(who, said);

      let where = mode;
      if (mode === 'beside' || mode === 'lead') where = room() >= 170 ? 'gutter' : (mode === 'lead' ? 'lead' : 'scrap');
      el.classList.add(where);
      if (where === 'inline') {
        const host = b.closest('li') || b.closest('.ways');
        if (host && host.classList.contains('ways')) host.after(el); else if (host) host.append(el); else b.after(el);
      } else if (where === 'lead') {
        api.after.prepend(el);
      } else if (where === 'float') {
        document.body.append(el);
        const sr = api.story.getBoundingClientRect(), col = column();
        el.style.left = col.left + 'px';
        el.style.width = col.width + 'px';
        el.style.bottom = Math.max(12, globalThis.innerHeight - sr.bottom + 18) + 'px';
      } else {
        api.inner.append(el);
        placeBy(el, b, where);
      }
      tip = { el: el, btn: b, mode: where };
      requestAnimationFrame(function () { el.classList.add('on'); });
      clearTimeout(fadeT);
      if (where === 'float') fadeT = setTimeout(function () { hide(); }, 7000);
      else if (where === 'lead') fadeT = setTimeout(function () { hide(); }, 14000);
      pulse(w.speaker);
      if (api.audio) api.audio.sfx('whisper');
    }

    function hide(quick) {
      clearTimeout(fadeT);
      if (!tip) return;
      const el = tip.el;
      tip = null;
      if (quick || api.reduced()) { el.remove(); return; }
      el.classList.remove('on');
      el.classList.add('off');
      setTimeout(function () { el.remove(); }, 260);
    }

    // the reading column, on screen
    function column() {
      const ir = api.inner.getBoundingClientRect();
      const cs = getComputedStyle(api.inner);
      const l = parseFloat(cs.paddingLeft) || 0, r = parseFloat(cs.paddingRight) || 0;
      return { left: ir.left + l, right: ir.right - r, width: ir.width - l - r, top: ir.top, inner: ir, padR: r };
    }

    // room to the right of the reading column for a note in the margin
    function room() {
      const sr = api.story.getBoundingClientRect();
      return sr.right - column().right - 16 - 22;
    }

    function placeBy(el, b, where) {
      const col = column();
      const br = b.getBoundingClientRect();
      if (where === 'gutter') {
        const left = col.right - col.inner.left + 22;
        el.style.left = left + 'px';
        el.style.top = (br.top - col.inner.top + 3) + 'px';
        el.style.width = Math.min(250, room()) + 'px';
        // a hairline from the choice out to the note
        el.style.setProperty('--lead', Math.max(10, left - (br.right - col.inner.left) - 6) + 'px');
      } else {
        el.style.top = (br.bottom - col.inner.top - 5) + 'px';
        el.style.right = col.padR + 'px';
        el.style.maxWidth = Math.min(360, col.width * 0.88) + 'px';
      }
    }

    // the voice's seat in the head panel lights up while it speaks
    function pulse(id) {
      const n = api.head && api.head.querySelector('.voice-node[data-voice="' + id + '"]');
      if (!n) return;
      n.classList.remove('leans');
      void n.getBoundingClientRect();
      n.classList.add('leans');
      setTimeout(function () { n.classList.remove('leans'); }, 2600);
    }

    // ---------------------------------------------------------------- wiring

    const A = api.after;
    // A pointer moving onto a choice: not just one that's there when the choices change under a
    // still pointer, and not the mouse a phone makes up after a tap.
    let touchAt = 0;
    A.addEventListener('pointermove', function (e) {
      if (e.pointerType === 'touch') { touchAt = now(); return; }
      if (now() - touchAt < 1500) return;
      const b = e.target.closest && e.target.closest('.choice');
      if (b && b !== hoverBtn) enter(b, HOVER_MS);
    });
    A.addEventListener('pointerout', function (e) {
      if (e.pointerType === 'touch') return;
      const b = e.target.closest && e.target.closest('.choice');
      if (!b || (e.relatedTarget && b.contains(e.relatedTarget))) return;
      out(b);
    });
    A.addEventListener('focusin', function (e) {
      const b = e.target.closest && e.target.closest('.choice');
      if (b && b.matches(':focus-visible') && b !== hoverBtn) enter(b, KEY_MS);
    });
    A.addEventListener('focusout', function (e) {
      const b = e.target.closest && e.target.closest('.choice');
      if (b) out(b);
    });

    // a press and hold on a phone: the voices lean in, and the press doesn't choose
    A.addEventListener('pointerdown', function (e) {
      if (e.pointerType !== 'touch') return;
      touchAt = now();
      const b = e.target.closest && e.target.closest('.choice');
      if (tip && tip.mode === 'inline' && (!b || b !== tip.btn)) hide();
      if (!b || !enabled() || api.busy()) return;
      hold = { btn: b, x: e.clientX, y: e.clientY };
      clearTimeout(holdT);
      holdT = setTimeout(function () {
        holdT = null;
        if (!hold || hold.btn !== b) return;
        swallow = b;
        lean(b, 'hold');
      }, HOLD_MS);
    });
    A.addEventListener('pointermove', function (e) {
      if (!hold || e.pointerType !== 'touch') return;
      if (Math.abs(e.clientX - hold.x) > 10 || Math.abs(e.clientY - hold.y) > 10) { clearTimeout(holdT); holdT = null; hold = null; }
    });
    const lift = function (e) { if (e && e.pointerType === 'touch') touchAt = now(); clearTimeout(holdT); holdT = null; hold = null; };
    A.addEventListener('pointerup', lift);
    A.addEventListener('pointercancel', lift);
    A.addEventListener('contextmenu', function (e) { if (e.target.closest && e.target.closest('.choice')) e.preventDefault(); });
    // the click that ends a hold isn't a choice
    A.addEventListener('click', function (e) {
      const b = e.target.closest && e.target.closest('.choice');
      if (b && swallow === b) { swallow = null; e.preventDefault(); e.stopImmediatePropagation(); }
      else swallow = null;
    }, true);

    api.story.addEventListener('scroll', onScroll, { passive: true });
    document.addEventListener('visibilitychange', onVisibility);
    globalThis.addEventListener('resize', function () { if (tip && (tip.mode === 'gutter' || tip.mode === 'scrap')) hide(true); });

    return { attach: attach, leave: leave, stop: stop };
  };
})(globalThis.Bouncer = globalThis.Bouncer || {});
