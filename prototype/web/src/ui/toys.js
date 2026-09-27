// Toys: things the player can play with between choices (content/ink/toys.ink, Game.toy).
//
// The clicker in the status: press it and it clicks, and the count goes on with nobody coming in;
// press and hold the knob on its side and it turns the count back to nothing. Its wheels roll
// whenever the number changes, whoever changed it.
//
// Things he's handed or picks up (a licence at the door, the binder under the till) are drawn
// under the line that hands them over, from content/data/props.yaml (src/ui/props.js). Handling
// one the way a choice on offer is waiting for makes that choice.
//
// B.Toys(api) -> { afterRail(count), stop() }
//   api: { play(id, what) -> true if the game took it, live() -> can he play right now, audio }
(function (B) {
  'use strict';

  const KNOB_MS = 950;          // holding the knob that long turns it all the way
  const NOTCH_MS = 75;

  function Toys(api) {
    let shown = null;           // the clicker's four digits as last drawn
    let knob = null;            // the knob being turned: { el, t0, timer, notch }

    function digits(n) { return String(Math.max(0, n | 0)).padStart(4, '0').slice(-4); }

    // after the status is drawn again: roll the wheels that changed
    function afterRail(count) {
      const now = digits(count);
      if (shown != null && shown !== now) {
        const back = parseInt(now, 10) < parseInt(shown, 10);
        for (const w of document.querySelectorAll('.clicker-window')) {
          const ds = w.querySelectorAll('.ck-d');
          for (let i = 0; i < ds.length; i++) {
            if (shown[i] === now[i]) continue;
            ds[i].classList.add(back ? 'ck-back' : 'ck-up');
            ds[i].style.setProperty('--i', back ? (3 - i) : 0);
          }
        }
      }
      shown = now;
    }

    // the button on top
    document.addEventListener('click', function (e) {
      const b = e.target.closest('.ck-body');
      if (!b || b.disabled || !api.live()) return;
      if (api.play('clicker', 'click')) {
        if (api.audio) api.audio.sfx('clicker');
        buzz(6);
      }
    });

    // the knob: it's stiff; it has to be held all the way round
    function turnStart(el) {
      if (knob || el.disabled || !api.live()) return;
      knob = { el: el, t0: Date.now(), timer: 0, notch: 0 };
      el.classList.add('turning');
      el.style.setProperty('--turn', KNOB_MS + 'ms');
      knob.notch = setInterval(function () { if (api.audio) api.audio.sfx('knob', 0.8); }, NOTCH_MS);
      knob.timer = setTimeout(function () {
        const k = knob;
        turnEnd(false);
        if (!k) return;
        if (api.play('clicker', 'zero')) {
          if (api.audio) api.audio.sfx('zero');
          buzz(18);
        }
      }, KNOB_MS);
    }
    function turnEnd(letGo) {
      if (!knob) return;
      clearTimeout(knob.timer);
      clearInterval(knob.notch);
      const el = knob.el;
      el.classList.remove('turning');
      if (letGo) {
        // it springs back
        el.classList.add('back');
        setTimeout(function () { el.classList.remove('back'); }, 260);
      }
      knob = null;
    }
    document.addEventListener('pointerdown', function (e) {
      const k = e.target.closest('.ck-knob');
      if (!k) return;
      e.preventDefault();
      turnStart(k);
    });
    for (const ev of ['pointerup', 'pointercancel']) document.addEventListener(ev, function () { turnEnd(true); });
    document.addEventListener('pointerout', function (e) { if (knob && e.target === knob.el && !knob.el.contains(e.relatedTarget)) turnEnd(true); });
    document.addEventListener('keydown', function (e) {
      if ((e.key === 'Enter' || e.key === ' ') && e.target.closest && e.target.closest('.ck-knob')) {
        e.preventDefault();
        if (!e.repeat) turnStart(e.target.closest('.ck-knob'));
      }
    });
    document.addEventListener('keyup', function (e) {
      if ((e.key === 'Enter' || e.key === ' ') && knob) turnEnd(true);
    });
    document.addEventListener('contextmenu', function (e) { if (e.target.closest && e.target.closest('.clicker')) e.preventDefault(); });

    function stop() { turnEnd(false); }

    return { afterRail: afterRail, stop: stop };
  }

  function buzz(ms) {
    try { if (navigator.vibrate) navigator.vibrate(ms); } catch (e) { /* not here */ }
  }

  B.Toys = Toys;
})(globalThis.Bouncer = globalThis.Bouncer || {});
