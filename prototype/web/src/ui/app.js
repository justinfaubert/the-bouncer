// The page: title, story, choices, the rail (floor sketch, the room in his head, notes), menus.
// Everything the night is made of comes from the Game (src/core/game.js); this file only
// draws it and passes clicks back.
(function () {
  'use strict';

  const B = globalThis.Bouncer;
  const C = globalThis.BOUNCER_CONTENT;
  const V = B.Views;
  const esc = B.util.escapeHtml;
  const $ = function (sel, root) { return (root || document).querySelector(sel); };

  const CLOSE_TIME = 1560;   // 2:00 am on the shift clock
  const BUSY_FROM = 1350;    // 10:30 pm: the room gets loud
  const DAY_NAMES = { 1: 'Wednesday', 2: 'Thursday', 3: 'Friday' };
  const HURT_WORDS = ['', 'Knocked about', 'Hurt', 'Badly hurt'];
  const PLACE = {
    door: 'On the door', floor: 'On the floor', t28: 'At table 28', pool: 'By the pool table', bar: 'At the bar',
    hall: 'In the back hall', kitchen: 'In the kitchen', keg: 'In the keg room', deck: 'Out on the deck',
    lot: 'Out in the lot', upstairs: 'Upstairs'
  };
  const DEFAULTS = {
    size: 'm', reveal: 'lines', odds: 'words', prompts: true,
    sound: true, master: 0.8, amb: 0.6, sfx: 0.8, music: 0.6, cloud: false,
    director: false
  };
  const SNAPS = 80;          // how many choices director mode can step back through
  const SIZES = { s: 15, m: 16, l: 17.5 };

  const app = {
    game: null, store: null, audio: null, settings: null, dir: null,
    inGame: false, booted: false,
    snaps: [],                   // director mode: the night before each choice, to step back to
    block: null, blockScreen: undefined,
    pending: null,               // items waiting behind a #pause
    shownKnots: new Set(),
    inkAmb: null,
    lastFocus: null,
    rainStop: null
  };

  // ---------------------------------------------------------------- boot

  function boot(hotData) {
    if (app.booted) return;
    app.booted = true;
    if (!C || !C.story) { document.body.textContent = 'The game content did not load (content.js).'; return; }

    app.store = new B.Store();
    app.settings = app.store.loadSettings(DEFAULTS);
    app.store.cloudSaves = !!app.settings.cloud;
    app.game = new B.Game(C);
    app.audio = new B.Audio(C.assets, (C.meta && C.meta.assetBase) || '');
    app.dir = B.DirectorUI(directorApi());
    applySettings();

    $('#map').innerHTML = V.mapSVG();
    $('#build-id').textContent = 'Build ' + ((C.meta && C.meta.build) || 'dev');
    wire();
    renderTitle();
    startRain();
    if (app.settings.director) app.dir.setOn(true, true);

    // saves and edits already allowed into the account come back quietly; nothing asks here
    if (app.settings.cloud || app.settings.director || app.dir.hasEdits()) {
      app.store.connect(false).then(function (on) {
        if (!on) return;
        app.dir.ensureDb(false);
        renderTitle();
      });
    }

    if (hotData && hotData.inGame) {
      const save = app.store.loadLocal();
      if (save) resume(save, true);
    }
  }

  // ---------------------------------------------------------------- settings

  function applySettings() {
    const s = app.settings;
    document.documentElement.style.fontSize = (SIZES[s.size] || 16) + 'px';
    app.audio.setLevels({ master: s.master, amb: s.amb, sfx: s.sfx, music: s.music }, s.sound);
  }

  function saveSettings() {
    app.store.saveSettings(app.settings);
    applySettings();
  }

  function setDirector(on, quiet) {
    app.settings.director = !!on;
    app.store.saveSettings(app.settings);
    app.dir.setOn(!!on, quiet);
  }

  // ---------------------------------------------------------------- the title

  function saveMeta(save) {
    if (!save) return '';
    const m = /"clock"\s*:\s*(\d+)/.exec(String(save.ink || ''));
    const clock = m ? parseInt(m[1], 10) : 0;
    const n = (save.path && save.path.length) || save.turn || 0;
    if (save.ended) return 'The shift is over. See how it ended.';
    return (clock ? B.util.fmtClock(clock) + ', ' : '') + n + (n === 1 ? ' choice' : ' choices') + ' in';
  }

  async function bestSave() {
    const local = app.store.loadLocal();
    if (!app.store.db || !app.store.cloudSaves) return local;
    const cloud = await app.store.loadCloud();
    return B.Store.newer(local, cloud);
  }

  async function renderTitle() {
    const menu = $('#title-menu');
    const save = await bestSave();
    const mine = save && save.game === 'the-bouncer' ? save : null;
    menu.innerHTML = '';
    if (mine) {
      menu.append(button(mine.ended ? 'See how it ended' : 'Continue the shift', 'btn primary', function () { unlockAudio(); resume(mine); }));
      const meta = document.createElement('div');
      meta.className = 'meta';
      meta.textContent = saveMeta(mine);
      menu.append(meta);
      menu.append(button('Start Wednesday over', 'btn', function () { confirmTitleRestart(); }));
    } else {
      menu.append(button('Start the shift', 'btn primary', function () { unlockAudio(); startNew(); }));
    }
    menu.append(button('How it plays', 'btn', function () { openHelp(); }));
    menu.append(button('Settings', 'btn', function () { openSettings(); }));
    $('#title-note').textContent = app.store.db && app.store.cloudSaves
      ? 'One save, written after every choice, in this browser and in your Claude account.'
      : 'One save, written after every choice. There is no going back to try it again.';
  }

  function confirmTitleRestart() {
    const menu = $('#title-menu');
    menu.innerHTML = '';
    const box = document.createElement('div');
    box.className = 'confirm-inline';
    box.textContent = 'Start Wednesday over? The night you have now is gone for good.';
    menu.append(box);
    menu.append(button('Start over', 'btn primary', function () { unlockAudio(); app.store.clear(); startNew(); }));
    menu.append(button('Keep my night', 'btn', function () { renderTitle(); }));
  }

  function showTitle() {
    closeDialog();
    closeRail();
    app.inGame = false;
    app.audio.stopAll();
    document.getElementById('app').setAttribute('data-state', 'title');
    renderTitle();
    startRain();
  }

  function hideTitle() {
    document.getElementById('app').setAttribute('data-state', 'game');
    if (app.rainStop) { app.rainStop(); app.rainStop = null; }
  }

  // rain on the glass, behind the sign
  function startRain() {
    if (app.rainStop) return;
    const cv = $('#rain');
    if (!cv || !cv.getContext) return;
    const ctx = cv.getContext('2d');
    const still = globalThis.matchMedia && globalThis.matchMedia('(prefers-reduced-motion: reduce)').matches;
    let w = 0, h = 0, drops = [], raf = 0, alive = true;
    function size() {
      const r = cv.getBoundingClientRect();
      const d = Math.min(2, globalThis.devicePixelRatio || 1);
      w = Math.max(1, r.width); h = Math.max(1, r.height);
      cv.width = Math.round(w * d); cv.height = Math.round(h * d);
      ctx.setTransform(d, 0, 0, d, 0, 0);
      const n = Math.round(w * h / 9000);
      drops = [];
      for (let i = 0; i < n; i++) drops.push({ x: Math.random() * w, y: Math.random() * h, l: 8 + Math.random() * 18, v: 5 + Math.random() * 7 });
    }
    function draw() {
      ctx.clearRect(0, 0, w, h);
      ctx.strokeStyle = 'rgba(200, 190, 185, 0.35)';
      ctx.lineWidth = 1;
      ctx.beginPath();
      for (const d of drops) {
        ctx.moveTo(d.x, d.y);
        ctx.lineTo(d.x - d.l * 0.18, d.y + d.l);
        if (!still) { d.y += d.v; d.x -= d.v * 0.18; if (d.y > h) { d.y = -d.l; d.x = Math.random() * (w + 40); } }
      }
      ctx.stroke();
      if (!still && alive) raf = requestAnimationFrame(draw);
    }
    size();
    draw();
    const onResize = function () { size(); if (still) draw(); };
    globalThis.addEventListener('resize', onResize);
    app.rainStop = function () { alive = false; cancelAnimationFrame(raf); globalThis.removeEventListener('resize', onResize); };
  }

  // ---------------------------------------------------------------- starting and resuming

  function unlockAudio() { app.audio.unlock(); }

  function resetStory() {
    $('#log').innerHTML = '';
    $('#after').innerHTML = '';
    app.block = null;
    app.blockScreen = undefined;
    app.pending = null;
    app.shownKnots = new Set();
    app.inkAmb = null;
    app.snaps = [];
    if (app.dir) app.dir.close();
  }

  function startNew() {
    resetStory();
    hideTitle();
    app.inGame = true;
    const res = app.game.newGame();
    persist();
    show(res, true);
    $('#story').scrollTop = 0;
  }

  function resume(save, quiet) {
    try {
      app.game.load(save);
    } catch (e) {
      toast('That save could not be read. Starting fresh.');
      startNew();
      return;
    }
    resetStory();
    hideTitle();
    app.inGame = true;
    if (!quiet) unlockAudio();
    const earlier = app.game.log.slice();
    renderItems(earlier, false);
    if (earlier.length) {
      const note = document.createElement('p');
      note.className = 'aside';
      note.innerHTML = '<b>Picked up where you left off.</b>';
      appendNode(note);
    }
    after({ choices: app.game.choices, ended: app.game.ended }, false);
    const story = $('#story');
    story.scrollTop = story.scrollHeight;
    // sound for where he is now
    syncAmbience();
  }

  function persist() {
    if (!app.game.story) return;
    const ok = app.store.save(app.game.serialize());
    if (!ok && !app._warnedStorage) {
      app._warnedStorage = true;
      toast('This browser is not keeping saves. The night will be lost if you close it.');
    }
  }

  // ---------------------------------------------------------------- playing

  function choose(visibleIndex) {
    if (!app.inGame || app.pending) return;
    const list = app.game.choices.filter(function (c) { return !c.hidden; });
    if (!list[visibleIndex]) return;
    snapshot();
    let res;
    try {
      res = app.game.choose(visibleIndex);
    } catch (e) {
      toast('Something went wrong with that choice.');
      return;
    }
    persist();
    show(res, true);
  }

  function show(res, live) {
    $('#after').innerHTML = '';
    const first = renderItems(res.items, live);
    if (!app.pending) after(res, live);
    else renderRail();
    if (live && first) scrollToNode(first);
  }

  function after(res, live) {
    renderChoices(res.choices, res.ended);
    renderRail();
    app.dir.bar();
    if (live) syncAmbience();
  }

  // ---------------------------------------------------------------- director mode: back and forth

  // The night as it stands, before a choice. Kept in memory for this visit only.
  function snapshot() {
    const g = app.game;
    if (!g.story) return;
    const save = g.serialize();
    save.log = [];
    app.snaps.push({ save: save, log: g.log.slice(), shown: Array.from(app.shownKnots) });
    if (app.snaps.length > SNAPS) app.snaps.shift();
  }

  // Undo the last choice: for trying the other branch while directing. The ironman save moves
  // back with it.
  function stepBack() {
    const s = app.snaps.pop();
    if (!s) { toast('Nothing to step back to.'); return; }
    try { app.game.load(s.save); } catch (e) { toast('Could not step back.'); return; }
    app.game.log = s.log.slice();
    persist();
    const keep = app.snaps;
    resetStory();
    app.snaps = keep;
    rerenderLog(null, true);
    after({ choices: app.game.choices, ended: app.game.ended }, true);
    const story = $('#story');
    story.scrollTop = story.scrollHeight;
    toast('Stepped back one choice.');
  }

  // Go straight to a part of the Ink (a writing prompt's scene). Step back undoes it.
  function jumpTo(knot) {
    if (!app.inGame) { unlockAudio(); startNew(); }
    snapshot();
    let res;
    try { res = app.game.jump(knot); } catch (e) { app.snaps.pop(); toast('Could not go to ' + knot + '.'); return; }
    persist();
    const aside = asideNode('<b>Jumped to ' + esc(knot) + '.</b> Everything in between was skipped, so the night may not add up. Step back to return.');
    appendNode(aside);
    show(res, true);
    scrollToNode(aside);
  }

  // Draw the whole log again (after an edit), keeping what's on screen where it was.
  function rerenderLog(keepNode, noAnchor) {
    const story = $('#story');
    let anchor = null, top = 0;
    if (!noAnchor) {
      const probe = keepNode || firstVisible();
      if (probe) { anchor = probe._src || null; top = probe.getBoundingClientRect().top; }
    }
    $('#log').innerHTML = '';
    app.block = null;
    app.blockScreen = undefined;
    app.shownKnots = new Set();
    const log = app.game.log;
    const hold = app.pending ? app.pending.filter(function (it) { return it.kind !== 'fx' && it.kind !== 'pause'; }).length : 0;
    renderItems(hold ? log.slice(0, log.length - hold) : log, false);
    if (app.pending) appendNode(pauseButton());
    if (anchor) {
      const nodes = $('#log').querySelectorAll('[data-dir]');
      for (const n of nodes) {
        if (n._src === anchor) { story.scrollTop += n.getBoundingClientRect().top - top; break; }
      }
    }
  }

  function firstVisible() {
    const top = $('#story').getBoundingClientRect().top;
    for (const n of $('#log').querySelectorAll('[data-dir]')) {
      if (n.getBoundingClientRect().bottom > top + 8) return n;
    }
    return null;
  }

  function directorApi() {
    return {
      C: C, store: app.store,
      status: function () {
        const st = app.game.story ? app.game.status() : { clock: 0, here: '' };
        const last = app.game.log.length ? app.game.log[app.game.log.length - 1] : null;
        st.knot = (last && last.knot) || '';
        return st;
      },
      toast: toast, openDialog: openDialog, closeDialog: closeDialog, heading: heading, foot: foot, seg: seg,
      rerender: function () { if (app.inGame) rerenderLog(); },
      renderChoices: function () { if (app.inGame && !app.pending) renderChoices(app.game.choices, app.game.ended); },
      canStepBack: function () { return app.inGame && app.snaps.length > 0; },
      jumpTo: jumpTo,
      fmtClock: B.util.fmtClock,
      place: function (here) { return PLACE[here] || ''; }
    };
  }

  function scrollToNode(node) {
    const story = $('#story');
    const top = node.getBoundingClientRect().top - story.getBoundingClientRect().top + story.scrollTop - 18;
    story.scrollTop = Math.max(0, top);
  }

  // ---------------------------------------------------------------- the log

  function voiceStyle(id) { return (C.voices[id] && C.voices[id].style) || id; }
  function voiceLabel(id) { return (C.voices[id] && C.voices[id].label) || String(id).toUpperCase(); }

  function ensureBlock(screen) {
    const s = screen || null;
    if (app.block && app.blockScreen === s) return app.block;
    const b = document.createElement('div');
    b.className = 'blk' + (s ? ' blk-' + s : '');
    $('#log').append(b);
    app.block = b;
    app.blockScreen = s;
    return b;
  }

  function appendNode(node, screen) {
    const b = ensureBlock(screen === undefined ? app.blockScreen : screen);
    b.append(node);
    return node;
  }

  function isCaps(t) { return /[A-Z]/.test(t) && t === t.toUpperCase() && t.length > 3; }

  function lineNode(item) {
    const p = document.createElement('p');
    p.className = 'ln ' + (item.role || 'narration');
    if (item.cls) p.classList.add(String(item.cls));
    if (item.role === 'voice' || item.role === 'dialogue') {
      if (item.role === 'voice') p.classList.add('v-' + voiceStyle(item.speaker));
      const who = document.createElement('span');
      who.className = 'who';
      who.textContent = item.label;
      const said = document.createElement('span');
      said.className = 'said';
      said.textContent = item.text;
      p.append(who, said);
    } else {
      p.textContent = item.text;
    }
    if (item.screen === 'ledger' && isCaps(item.text)) p.classList.add('caps');
    return p;
  }

  function chosenNode(item) {
    const p = document.createElement('p');
    p.className = 'ln chosen';
    const t = document.createElement('span');
    if (item.check) {
      p.classList.add('v-' + voiceStyle(item.check.voice));
      const ck = document.createElement('span');
      ck.className = 'ck';
      ck.textContent = '[' + voiceLabel(item.check.voice) + ']';
      t.append(ck);
    }
    t.append(document.createTextNode(item.text));
    p.append(t);
    return p;
  }

  function checkNode(item) {
    const d = document.createElement('div');
    d.className = 'check ' + (item.success ? 'ok' : 'no') + ' v-' + voiceStyle(item.voice);
    const r = item.roll || {};
    const crit = r.crit === 'success' ? 'Double six' : r.crit === 'fail' ? 'Double one' : '';
    d.innerHTML =
      '<span class="ck-who">' + esc(item.label) + '</span>' +
      '<span class="dice" aria-label="Rolled ' + r.d1 + ' and ' + r.d2 + '">' + V.dieSVG(r.d1) + V.dieSVG(r.d2) + '</span>' +
      '<span class="sum">' + esc(item.word) + ' ' + item.target + ', got ' + r.total + (crit ? ', ' + crit.toLowerCase() : '') + '</span>' +
      '<span class="res">' + (item.success ? 'Success' : 'Failure') + '</span>';
    d.title = checkDetail(item);
    return d;
  }

  function checkDetail(item) {
    const r = item.roll || {};
    const parts = (item.mods || []).map(function (m) { return (m.value > 0 ? '+' : '') + m.value + ' ' + m.label; });
    return 'Dice ' + r.d1 + ' + ' + r.d2 + (r.tension ? ', stretched by tension ' + r.tension : '') + (parts.length ? ', ' + parts.join(', ') : '') + ' = ' + r.total + ' against ' + item.target;
  }

  function asideNode(html) {
    const p = document.createElement('p');
    p.className = 'aside';
    p.innerHTML = html;
    return p;
  }

  function psycheText(it) {
    if (it.op === 'seat') return '<b>' + esc(voiceLabel(it.voice)) + '</b> has a seat in his head now.';
    if (it.op === 'unseat') return '<b>' + esc(voiceLabel(it.voice)) + '</b> is out of his head.';
    if (it.op === 'bond') return '<b>' + esc(voiceLabel(it.a)) + '</b> and <b>' + esc(voiceLabel(it.b)) + '</b> come round to each other.';
    if (it.op === 'rift') return '<b>' + esc(voiceLabel(it.a)) + '</b> and <b>' + esc(voiceLabel(it.b)) + '</b> fall out.';
    return '';
  }

  function portraitNode(id) {
    let label = id;
    for (const k in C.characters) if (C.characters[k].portrait === id) { label = C.characters[k].label || k; break; }
    const slot = (C.assets.portraits || {})[id] || {};
    const fig = document.createElement('div');
    fig.className = 'portrait';
    if (slot.file && slot.present) {
      const img = document.createElement('img');
      img.src = ((C.meta && C.meta.assetBase) || '') + slot.file;
      img.alt = label;
      fig.append(img);
    } else {
      const ph = document.createElement('div');
      ph.className = 'ph';
      ph.setAttribute('aria-hidden', 'true');
      ph.textContent = V.initials(label).toUpperCase();
      fig.append(ph);
    }
    const cap = document.createElement('span');
    cap.className = 'cap';
    cap.textContent = label;
    fig.append(cap);
    return fig;
  }

  // prompts for Hutch, the first time the night passes through a part of the Ink that has them
  const PROMPTS = (function () {
    const m = {};
    for (const p of (C.meta && C.meta.prompts) || []) (m[p.knot] = m[p.knot] || []).push(p);
    return m;
  })();

  // Draw items into the log. Returns the first node drawn. Live items fade in one after another.
  // The director's edits are laid over each item as it's drawn (src/ui/director.js).
  function renderItems(items, live) {
    let first = null, n = 0;
    const animate = live && app.settings.reveal === 'lines' && !reducedMotion();
    const add = function (node, screen) {
      appendNode(node, screen);
      if (animate) { node.classList.add('fresh'); node.style.animationDelay = Math.min(n * 70, 1400) + 'ms'; }
      n++;
      if (!first) first = node;
      return node;
    };
    const prompts = function (it) {
      if (!app.settings.prompts) return;
      if (it.knot && PROMPTS[it.knot] && !app.shownKnots.has(it.knot)) {
        app.shownKnots.add(it.knot);
        add(app.dir.promptCard(PROMPTS[it.knot]), it.screen || null);
      }
      if (it.prompt) add(app.dir.promptCard([{ loc: 'here', text: it.prompt, knot: it.knot || '' }]), it.screen || null);
    };
    for (let i = 0; i < items.length; i++) {
      const src = items[i];
      const shown = (src.kind === 'line' || src.kind === 'chosen') ? app.dir.overlay([src]) : [src];
      for (const it of shown) {
        switch (it.kind) {
          case 'line': {
            const node = add(lineNode(it), it.screen || null);
            app.dir.decorate(node, it);
            if (!it.inserted) prompts(it.src || it);
            break;
          }
          case 'chosen': app.dir.decorate(add(chosenNode(it)), it); break;
          case 'dnote': add(app.dir.noteNode(it), it.screen || null); break;
          case 'diff': { const d = app.dir.diffNode(it); if (d) add(d); break; }
          case 'check': add(checkNode(it)); break;
          case 'task':
            add(asideNode((it.op === 'add' ? '<b>Noted.</b> ' : '<b>Done.</b> ') + esc(it.text)));
            break;
          case 'psyche': {
            const t = psycheText(it);
            if (t) add(asideNode(t));
            break;
          }
          case 'screen':
            ensureBlock(it.name || null);
            break;
          case 'fx':
            if (live) fx(it, add);
            break;
          case 'pause':
            if (live) {
              app.pending = items.slice(i + 1);
              const go = add(pauseButton());
              setTimeout(function () { go.focus(); }, 50);
              return first;
            }
            break;
        }
      }
    }
    return first;
  }

  // "Go on": the rest of the batch waits behind a #pause in the Ink
  function pauseButton() {
    const go = button('Go on', 'btn pause-go', function () {
      go.remove();
      const r = app.pending;
      app.pending = null;
      const f = renderItems(r, true);
      after({ choices: app.game.choices, ended: app.game.ended }, true);
      if (f) scrollToNode(f);
    });
    return go;
  }

  function fx(it, add) {
    if (it.type === 'sfx') app.audio.sfx(it.id);
    else if (it.type === 'music') app.audio.track(it.id);
    else if (it.type === 'amb') app.inkAmb = { id: it.id === 'none' ? null : it.id, here: null };
    else if (it.type === 'portrait') add(portraitNode(it.id));
  }

  // Ambience follows where he is, unless the Ink named one for the place he's in now.
  function syncAmbience() {
    const st = app.game.status();
    if (app.inkAmb && app.inkAmb.here === null) app.inkAmb.here = st.here;
    let want;
    if (app.inkAmb && app.inkAmb.here === st.here) want = app.inkAmb.id;
    else {
      app.inkAmb = null;
      if (st.here === 'deck') want = 'deck';
      else if (st.here === 'lot') want = 'rain_lot';
      else if (st.here === 'keg') want = 'keg_room';
      else if (st.here === 'upstairs') want = null;
      else if (st.clock >= CLOSE_TIME) want = 'empty_bar';
      else want = st.clock >= BUSY_FROM ? 'room_busy' : 'room_quiet';
    }
    app.audio.ambience(want);
  }

  // ---------------------------------------------------------------- choices

  function renderChoices(choices, ended) {
    const box = $('#after');
    box.innerHTML = '';
    if (ended) { box.append(endCard()); return; }
    const list = choices.filter(function (c) { return !c.hidden; });
    const ol = document.createElement('ol');
    ol.className = 'choices';
    list.forEach(function (c, i) {
      const li = document.createElement('li');
      const b = document.createElement('button');
      b.type = 'button';
      b.className = 'choice';
      b.setAttribute('data-i', String(i));
      const n = document.createElement('span');
      n.className = 'n';
      n.textContent = (i + 1) + '.';
      const body = document.createElement('span');
      if (c.check) {
        b.classList.add('v-' + voiceStyle(c.check.voice));
        const ck = document.createElement('span');
        ck.className = 'ck';
        const odds = app.settings.odds === 'numbers' ? Math.round(c.check.odds * 100) + '%' : c.check.oddsWord;
        ck.innerHTML = '[' + esc(c.check.label) + ' &middot; ' + esc(c.check.word) + ' ' + c.check.target + '] <span class="odds">' + esc(odds) + '</span>';
        ck.title = (c.check.mods || []).map(function (m) { return (m.value > 0 ? '+' : '') + m.value + ' ' + m.label; }).join(', ');
        body.append(ck);
      }
      const words = app.dir.choiceText(c);
      body.append(document.createTextNode(words));
      if (words !== c.text) b.classList.add('edited');
      b.append(n, body);
      b.addEventListener('click', function () { choose(i); });
      li.append(b);
      if (app.dir.on) app.dir.choiceTools(li, c);
      ol.append(li);
    });
    box.append(ol);
  }

  function endCard() {
    const d = document.createElement('div');
    d.className = 'end-card';
    const h = document.createElement('h2');
    h.textContent = 'End of the test shift';
    const p = document.createElement('p');
    p.textContent = 'Friday comes next, and it is not written yet. This night stays saved the way it ended until you start Wednesday over.';
    const row = document.createElement('div');
    row.className = 'btn-row';
    row.append(
      button('Copy the night', 'btn primary', copyNight),
      button('Start Wednesday over', 'btn', confirmRestart),
      button('Back to the title', 'btn quiet', showTitle)
    );
    d.append(h, p, row);
    return d;
  }

  // ---------------------------------------------------------------- the rail

  function statusHTML(st) {
    const cp = B.util.clockParts(st.clock);
    const day = DAY_NAMES[st.day] || ('Day ' + st.day);
    return '<div class="st-day">' + esc(day) + ', the test shift</div>' +
      '<div class="st-clock">' + cp.text + '<small>' + cp.ampm + '</small></div>' +
      V.clickerHTML(st.count) +
      '<div class="st-where">' + esc(PLACE[st.here] || '') + '</div>' +
      '<div class="st-row">' +
        '<span class="st-item"><span class="st-k">Pocket</span><span class="st-v">$' + st.cash + '</span></span>' +
        '<span class="st-item"><span class="st-k">Drinks</span><span class="st-v">' + V.tallyHTML(st.drinks) + '</span></span>' +
        (st.hurt ? '<span class="st-item st-hurt"><span class="st-k">Hurt</span><span class="st-v">' + esc(HURT_WORDS[st.hurt] || 'Hurt') + '</span></span>' : '') +
      '</div>';
  }

  function renderRail() {
    const g = app.game;
    if (!g.story) return;
    const st = g.status();
    const html = statusHTML(st);
    for (const el of document.querySelectorAll('[data-status]')) el.innerHTML = html;

    // the map: every choice that goes somewhere lights its spot
    const open = {};
    g.choices.filter(function (c) { return !c.hidden; }).forEach(function (c, i) { if (c.loc && !(c.loc in open)) open[c.loc] = i; });
    app.mapOpen = open;
    V.updateMap($('#map'), st.here, open);

    // the room in his head
    $('#head').innerHTML = V.psycheSVG(g.psyche, C.voices) + V.tensionHTML(st.tension);
    if (app.voiceOpen) showVoice(app.voiceOpen);

    // notes
    const notes = $('#notes');
    notes.innerHTML = '';
    const tasks = Object.keys(g.tasks).map(function (id) { return Object.assign({ id: id }, g.tasks[id]); });
    tasks.sort(function (a, b) { return (a.done - b.done) || (a.turn - b.turn); });
    if (!tasks.length) {
      const li = document.createElement('li');
      li.className = 'none';
      li.textContent = 'Nothing yet.';
      notes.append(li);
    }
    for (const t of tasks) {
      const li = document.createElement('li');
      if (t.done) li.className = 'done';
      li.textContent = t.text;
      notes.append(li);
    }
  }

  function showVoice(id) {
    const box = $('#voice-info');
    const def = C.voices[id];
    if (!def) { box.hidden = true; app.voiceOpen = null; return; }
    app.voiceOpen = id;
    const g = app.game;
    const st = g.status();
    const mods = B.Checks.modifiers(def, { drinks: st.drinks, hurt: st.hurt }, 0);
    const modText = mods.parts.length ? mods.parts.map(function (m) { return (m.value > 0 ? '+' : '') + m.value + ' ' + m.label; }).join(', ') : 'nothing either way';
    const others = g.psyche.seated.filter(function (v) { return v !== id; });
    const allies = others.filter(function (v) { return g.psyche.getRel(id, v) > 0; }).map(voiceLabel);
    const odds = others.filter(function (v) { return g.psyche.getRel(id, v) < 0; }).map(voiceLabel);
    box.className = 'voice-info v-' + voiceStyle(id);
    box.innerHTML =
      '<h3>' + esc(def.label || id) + '</h3>' +
      '<p>' + esc(def.from || '') + '</p>' +
      '<p class="vi-k">Its checks tonight: ' + esc(modText) + '.</p>' +
      (allies.length ? '<p class="vi-k">Gets on with ' + esc(allies.join(', ')) + '.</p>' : '') +
      (odds.length ? '<p class="vi-k">At odds with ' + esc(odds.join(', ')) + '.</p>' : '');
    box.hidden = false;
  }

  function openRail(sectionId) {
    const rail = $('#rail');
    rail.classList.add('open');
    document.getElementById('app').classList.add('rail-open');
    const sec = sectionId && document.getElementById(sectionId);
    if (sec) setTimeout(function () { sec.scrollIntoView({ block: 'start' }); }, 30);
  }

  function closeRail() {
    $('#rail').classList.remove('open');
    document.getElementById('app').classList.remove('rail-open');
  }

  // ---------------------------------------------------------------- dialogs

  function button(label, cls, fn) {
    const b = document.createElement('button');
    b.type = 'button';
    b.className = cls || 'btn';
    b.textContent = label;
    b.addEventListener('click', fn);
    return b;
  }

  function openDialog(build, wide) {
    const ov = $('#overlay');
    const dlg = $('#dialog');
    app.lastFocus = document.activeElement;
    dlg.className = 'dialog' + (wide ? ' wide' : '');
    dlg.innerHTML = '';
    build(dlg);
    ov.hidden = false;
    const f = dlg.querySelector('button, input, textarea');
    if (f) f.focus();
  }

  function closeDialog() {
    const ov = $('#overlay');
    if (ov.hidden) return;
    ov.hidden = true;
    $('#dialog').innerHTML = '';
    if (app.lastFocus && app.lastFocus.focus) { try { app.lastFocus.focus(); } catch (e) { /* gone */ } }
  }

  function heading(dlg, text) {
    const h = document.createElement('h2');
    h.id = 'dialog-h';
    h.textContent = text;
    dlg.append(h);
  }

  function foot(dlg, buttons) {
    const f = document.createElement('div');
    f.className = 'dialog-foot';
    for (const b of buttons) f.append(b);
    dlg.append(f);
  }

  function openMenu() {
    if (!app.inGame) return;
    closeRail();
    openDialog(function (dlg) {
      heading(dlg, 'Menu');
      const list = document.createElement('div');
      list.className = 'menu-list';
      list.append(
        button('Back to the night', 'btn primary', closeDialog),
        button(app.dir.on ? 'Director mode: on' : 'Director mode: off', 'btn', function () { closeDialog(); setDirector(!app.dir.on); }),
        button('Director\u2019s desk', 'btn', function () { app.dir.openDesk(); }),
        button('Settings', 'btn', openSettings),
        button('How it plays', 'btn', openHelp),
        button('Copy the night', 'btn', copyNight),
        button('Inspector', 'btn', openInspector),
        button('Start Wednesday over', 'btn', confirmRestart),
        button('Back to the title', 'btn quiet', showTitle)
      );
      dlg.append(list);
      const p = document.createElement('p');
      p.className = 'tension-note';
      p.style.marginTop = '14px';
      p.textContent = app.store.db && app.store.cloudSaves ? 'Saved after every choice, here and in your Claude account.' : 'Saved in this browser after every choice.';
      dlg.append(p);
    });
  }

  function confirmRestart() {
    openDialog(function (dlg) {
      heading(dlg, 'Start over?');
      const p = document.createElement('p');
      p.textContent = 'Wednesday starts again from the lot. The night you have now is gone for good.';
      dlg.append(p);
      foot(dlg, [
        button('Keep my night', 'btn', closeDialog),
        button('Start over', 'btn primary', function () { closeDialog(); app.store.clear(); startNew(); })
      ]);
    });
  }

  function seg(name, options, value, onPick) {
    const wrap = document.createElement('span');
    wrap.className = 'seg';
    wrap.setAttribute('role', 'group');
    wrap.setAttribute('aria-label', name);
    for (const o of options) {
      const b = document.createElement('button');
      b.type = 'button';
      b.textContent = o[1];
      b.setAttribute('aria-pressed', String(o[0] === value));
      b.addEventListener('click', function () {
        for (const x of wrap.children) x.setAttribute('aria-pressed', 'false');
        b.setAttribute('aria-pressed', 'true');
        onPick(o[0]);
      });
      wrap.append(b);
    }
    return wrap;
  }

  function field(label, hint, control, forId) {
    const row = document.createElement('div');
    row.className = 'field';
    const l = document.createElement(forId ? 'label' : 'span');
    if (forId) l.htmlFor = forId; else l.className = 'lbl';
    l.textContent = label;
    if (hint) { const s = document.createElement('small'); s.textContent = hint; l.append(s); }
    row.append(l, control);
    return row;
  }

  function toggle(id, checked, onChange) {
    const i = document.createElement('input');
    i.type = 'checkbox';
    i.className = 'switch';
    i.id = id;
    i.checked = !!checked;
    i.addEventListener('change', function () { onChange(i.checked); });
    return i;
  }

  function slider(id, value, onChange) {
    const i = document.createElement('input');
    i.type = 'range';
    i.id = id;
    i.min = '0'; i.max = '1'; i.step = '0.05';
    i.value = String(value);
    i.addEventListener('input', function () { onChange(parseFloat(i.value)); });
    return i;
  }

  function openSettings() {
    const s = app.settings;
    openDialog(function (dlg) {
      heading(dlg, 'Settings');
      dlg.append(
        field('Text size', null, seg('Text size', [['s', 'Small'], ['m', 'Medium'], ['l', 'Large']], s.size, function (v) { s.size = v; saveSettings(); })),
        field('New lines', 'One after another, or all at once.', seg('New lines', [['lines', 'One by one'], ['all', 'At once']], s.reveal, function (v) { s.reveal = v; saveSettings(); })),
        field('Odds on checks', 'How the chance on a check is shown.', seg('Odds on checks', [['words', 'Words'], ['numbers', 'Numbers']], s.odds, function (v) { s.odds = v; saveSettings(); if (app.inGame) renderChoices(app.game.choices, app.game.ended); })),
        field('Show writing prompts', 'Marks the places where the draft needs your material.', toggle('set-prompts', s.prompts, function (v) { s.prompts = v; saveSettings(); if (app.inGame) rerenderLog(); }), 'set-prompts'),
        field('Director mode', 'Tap any line to rewrite, cut or add to it. Key: D.', toggle('set-director', app.dir.on, function (v) { setDirector(v, true); }), 'set-director'),
        field('Sound', null, toggle('set-sound', s.sound, function (v) { s.sound = v; saveSettings(); if (v) app.audio.unlock(); }), 'set-sound'),
        field('Volume', null, slider('set-master', s.master, function (v) { s.master = v; saveSettings(); }), 'set-master'),
        field('The room', 'Rain, the cooler, the bar at night.', slider('set-amb', s.amb, function (v) { s.amb = v; saveSettings(); }), 'set-amb'),
        field('Effects', 'The clicker, the bell, the door.', slider('set-sfx', s.sfx, function (v) { s.sfx = v; saveSettings(); app.audio.unlock(); app.audio.sfx('clicker'); }), 'set-sfx'),
        field('Music', 'Silent until the music is added.', slider('set-music', s.music, function (v) { s.music = v; saveSettings(); }), 'set-music')
      );
      dlg.append(cloudField());
      foot(dlg, [button('Done', 'btn primary', function () { if (app.inGame) closeDialog(); else { closeDialog(); renderTitle(); } })]);
    });
  }

  function cloudField() {
    const st = app.store;
    let ctl;
    const hint = 'Keeps the save with you on any device, and lets Claude read how your night went.';
    if (st.db && st.cloudSaves) {
      ctl = document.createElement('span');
      ctl.className = 'lbl';
      ctl.textContent = 'On';
    } else if (st.cloudState === 'none') {
      ctl = document.createElement('span');
      ctl.className = 'lbl';
      ctl.textContent = 'Not available here';
    } else if (st.cloudState === 'denied') {
      ctl = document.createElement('span');
      ctl.className = 'lbl';
      ctl.textContent = 'Not allowed';
    } else {
      ctl = button('Turn on', 'btn', async function () {
        ctl.disabled = true;
        const on = await st.connect(true);
        app.settings.cloud = on;
        st.cloudSaves = on;
        app.store.saveSettings(app.settings);
        if (on) app.dir.ensureDb(false);
        if (on) {
          toast('Saving to your Claude account.');
          if (app.inGame) persist();
        } else {
          toast('Saves stay in this browser.');
        }
        const row = ctl.closest('.field');
        if (row) row.replaceWith(cloudField());
      });
    }
    return field('Save to my Claude account', hint, ctl);
  }

  function openHelp() {
    openDialog(function (dlg) {
      heading(dlg, 'How it plays');
      const d = document.createElement('div');
      d.className = 'help';
      d.innerHTML =
        '<p>You are the new doorman at the Sovereign Hotel, on the east coast of the island. It is Wednesday, your test shift, from 7:40 until they lock up.</p>' +
        '<p>Every choice costs minutes. The room keeps going while you are somewhere else: people come in past an empty stool, the pool table heats up, table 28 keeps drinking.</p>' +
        '<p>There are voices in your head, people and books and stories you picked up at other doors. They talk over the scene, and they lend you checks. A check is two dice against a number. What moves the odds is how reliable the voice is, how much you have had to drink, and how loud the room in your head has got. The louder it is, the wider the dice swing, both ways.</p>' +
        '<p>There is one save, written after every choice. There is no going back to try it again.</p>' +
        '<h3>Keys</h3>' +
        '<dl><dt>1 to 9</dt><dd>Pick a choice</dd><dt>D</dt><dd>Director mode on or off</dd><dt>B</dt><dd>Step back one choice (director mode)</dd><dt>Esc</dt><dd>Menu</dd></dl>' +
        '<h3>The draft</h3>' +
        '<p>This is a draft of day one. Writing prompts mark the places where it needs Hutch\'s own material. Art and music drop in later; until then the sounds are stand-ins and the people are lettered cards.</p>' +
        '<h3>Director mode</h3>' +
        '<p>For writing the game while you play it. Tap any line to rewrite it, cut it, add a line after it, or leave Claude a note. Reword a choice without choosing it. Answer a writing prompt where it comes up. Step back to try the other branch. Your edits play in the game straight away.</p>' +
        '<p>When you have a batch, open the Director\'s desk and send them to Claude, who works them into the story files and puts up a new build. Each edit shows what became of it.</p>';
      dlg.append(d);
      foot(dlg, [button('Done', 'btn primary', closeDialog)]);
    });
  }

  // ---------------------------------------------------------------- the inspector

  function openInspector() {
    const g = app.game;
    openDialog(function (dlg) {
      heading(dlg, 'Inspector');
      const tabs = document.createElement('div');
      tabs.className = 'tabs';
      tabs.setAttribute('role', 'tablist');
      const body = document.createElement('div');
      const pages = {
        State: function () {
          const f = document.createElement('input');
          f.className = 'insp-filter';
          f.id = 'insp-filter';
          f.placeholder = 'Filter by name';
          const box = document.createElement('div');
          box.className = 'scroll-x';
          const draw = function () {
            const v = g.vars();
            const q = f.value.trim().toLowerCase();
            let rows = '';
            for (const k of Object.keys(v).sort()) {
              if (q && k.toLowerCase().indexOf(q) === -1) continue;
              const val = Array.isArray(v[k]) ? (v[k].length ? v[k].join(', ') : '()') : String(v[k]);
              rows += '<tr><th>' + esc(k) + '</th><td class="v">' + esc(val) + '</td></tr>';
            }
            box.innerHTML = '<table class="kv"><tbody>' + rows + '</tbody></table>';
          };
          f.addEventListener('input', draw);
          draw();
          return [f, box];
        },
        Checks: function () {
          const box = document.createElement('div');
          box.className = 'scroll-x';
          let rows = '';
          for (const c of g.checkHistory.slice().reverse()) {
            rows += '<tr><td>' + esc(B.util.fmtClock(c.clock)) + '</td><td>' + esc(c.label) + '</td><td>' + esc(c.word) + ' ' + c.target + '</td><td class="v">' + c.roll.d1 + '+' + c.roll.d2 + (c.roll.tension ? ' ×' + B.Checks.volatility(c.roll.tension).toFixed(2) : '') + ' → ' + c.roll.total + '</td><td>' + (c.success ? 'pass' : 'fail') + '</td></tr>';
          }
          box.innerHTML = rows ? '<table class="kv"><thead><tr><th>When</th><th>Voice</th><th>Target</th><th>Roll</th><th></th></tr></thead><tbody>' + rows + '</tbody></table>' : '<p>No checks yet.</p>';
          return [box];
        },
        Head: function () {
          const p = g.psyche;
          const box = document.createElement('div');
          const st = p.state();
          let h = '<p>Seated: ' + esc(p.seated.map(voiceLabel).join(', ') || 'nobody') + '. Tension ' + st.tension + (st.id ? ', state ' + esc(st.id) + ' (' + esc(st.cls) + ')' : '') + '.</p>';
          h += '<p>Known: ' + esc(p.learned.map(voiceLabel).join(', ')) + '.</p>';
          let rows = '';
          for (let i = 0; i < p.seated.length; i++) for (let j = i + 1; j < p.seated.length; j++) {
            rows += '<tr><td>' + esc(voiceLabel(p.seated[i])) + '</td><td>' + esc(voiceLabel(p.seated[j])) + '</td><td>' + (p.getRel(p.seated[i], p.seated[j]) < 0 ? 'at odds' : 'allied') + '</td></tr>';
          }
          if (rows) h += '<div class="scroll-x"><table class="kv"><tbody>' + rows + '</tbody></table></div>';
          h += '<h3>Tension over the night</h3><p>' + esc(p.history.map(function (x) { return B.util.fmtClock(x.clock) + ': ' + x.t; }).join(' · ') || 'No change yet.') + '</p>';
          box.innerHTML = h;
          return [box];
        },
        Night: function () {
          const box = document.createElement('div');
          box.className = 'scroll-x';
          let rows = '';
          for (const s of g.path) rows += '<tr><td>' + esc(B.util.fmtClock(s.c)) + '</td><td>' + esc(s.x) + (s.k ? ' <span class="v">[' + esc(voiceLabel(s.k.v)) + ' ' + s.k.n + '/' + s.k.of + (s.k.ok ? ' pass' : ' fail') + ']</span>' : '') + '</td></tr>';
          box.innerHTML = rows ? '<table class="kv"><tbody>' + rows + '</tbody></table>' : '<p>No choices yet.</p>';
          return [box];
        },
        Jump: function () {
          const p = document.createElement('p');
          p.textContent = 'For testing a scene. Jumping skips everything in between, so the night stops making sense. Start Wednesday over afterwards.';
          const list = document.createElement('div');
          list.className = 'jump-list';
          for (const k of (C.meta && C.meta.knots) || []) {
            list.append(button(k, '', function () {
              closeDialog();
              try { const res = g.jump(k); persist(); show(res, true); } catch (e) { toast('Could not jump to ' + k + '.'); }
            }));
          }
          return [p, list];
        },
        Save: function () {
          const p = document.createElement('p');
          p.textContent = 'The whole save as text. Copy it to keep a night, or paste one in and load it.';
          const ta = document.createElement('textarea');
          ta.className = 'io';
          ta.id = 'insp-save';
          ta.value = JSON.stringify(g.serialize());
          const row = document.createElement('div');
          row.className = 'btn-row';
          row.append(
            button('Copy', 'btn', function () { copyText(ta.value, ta); }),
            button('Load what is pasted here', 'btn', function () {
              let s = null;
              try { s = JSON.parse(ta.value); } catch (e) { toast('That is not a save.'); return; }
              try { g.load(s); } catch (e) { toast('That is not a save from this game.'); return; }
              closeDialog();
              persist();
              resume(s);
            })
          );
          return [p, ta, row];
        }
      };
      const names = Object.keys(pages);
      const select = function (name) {
        for (const b of tabs.children) b.setAttribute('aria-selected', String(b.textContent === name));
        body.innerHTML = '';
        for (const n of pages[name]()) body.append(n);
      };
      for (const n of names) {
        const b = document.createElement('button');
        b.type = 'button';
        b.setAttribute('role', 'tab');
        b.textContent = n;
        b.addEventListener('click', function () { select(n); });
        tabs.append(b);
      }
      dlg.append(tabs, body);
      select('State');
      foot(dlg, [button('Close', 'btn primary', closeDialog)]);
    }, true);
  }

  // ---------------------------------------------------------------- copying the night

  function nightText() {
    const g = app.game;
    const out = ['THE BOUNCER. Wednesday, the test shift.', 'Build ' + ((C.meta && C.meta.build) || 'dev'), ''];
    for (const s of g.path) {
      out.push(B.util.fmtClock(s.c).padStart(8) + '  ' + s.x + (s.k ? '  [' + voiceLabel(s.k.v) + ': ' + s.k.n + ' against ' + s.k.of + ', ' + (s.k.ok ? 'passed' : 'failed') + ']' : ''));
    }
    const ledger = g.log.filter(function (it) { return it.kind === 'line' && it.screen === 'ledger'; });
    if (ledger.length) {
      out.push('');
      for (const it of ledger) out.push((it.label ? it.label + ': ' : '') + it.text);
    }
    return out.join('\n');
  }

  function copyNight() {
    copyText(nightText());
  }

  function copyText(text, fallbackArea) {
    const done = function () { toast('Copied.'); };
    const fail = function () {
      if (fallbackArea) { fallbackArea.focus(); fallbackArea.select(); toast('Select all and copy.'); return; }
      openDialog(function (dlg) {
        heading(dlg, 'Copy the night');
        const ta = document.createElement('textarea');
        ta.className = 'io';
        ta.id = 'copy-area';
        ta.value = text;
        dlg.append(ta);
        foot(dlg, [button('Done', 'btn primary', closeDialog)]);
        setTimeout(function () { ta.focus(); ta.select(); }, 30);
      });
    };
    try {
      if (navigator.clipboard && navigator.clipboard.writeText) navigator.clipboard.writeText(text).then(done, fail);
      else fail();
    } catch (e) { fail(); }
  }

  // ---------------------------------------------------------------- odds and ends

  let toastTimer = null;
  function toast(msg) {
    const t = $('#toast');
    t.textContent = msg;
    t.hidden = false;
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () { t.hidden = true; }, 2600);
  }

  function reducedMotion() {
    return !!(globalThis.matchMedia && globalThis.matchMedia('(prefers-reduced-motion: reduce)').matches);
  }

  function wire() {
    document.addEventListener('click', function (e) {
      const t = e.target.closest('[data-act]');
      if (!t) {
        if (e.target === document.getElementById('app') && $('#rail').classList.contains('open')) closeRail();
        return;
      }
      const act = t.getAttribute('data-act');
      if (act === 'menu') { if (app.inGame) openMenu(); }
      else if (act === 'rail') openRail(t.getAttribute('data-sec'));
      else if (act === 'close-rail') closeRail();
    });

    $('#overlay').addEventListener('click', function (e) { if (e.target === e.currentTarget) closeDialog(); });

    // director mode: tap a line to change it
    $('#log').addEventListener('click', function (e) { app.dir.onLogClick(e); });
    $('#dir-bar').addEventListener('click', function (e) {
      const t = e.target.closest('[data-act]');
      if (!t) return;
      const act = t.getAttribute('data-act');
      if (act === 'dir-desk') app.dir.openDesk();
      else if (act === 'dir-back') stepBack();
      else if (act === 'dir-off') setDirector(false);
    });

    // the floor sketch: a lit spot is a choice
    const map = $('#map');
    const pick = function (g) {
      const loc = g && g.getAttribute('data-loc');
      if (!loc || !app.mapOpen || !(loc in app.mapOpen)) return;
      closeRail();
      choose(app.mapOpen[loc]);
    };
    map.addEventListener('click', function (e) { pick(e.target.closest('.spot')); });
    map.addEventListener('keydown', function (e) {
      if (e.key === 'Enter' || e.key === ' ') { const g = e.target.closest('.spot'); if (g) { e.preventDefault(); pick(g); } }
    });

    // the room in his head: tap a voice to read about it
    const head = $('#head');
    const pickVoice = function (node) {
      if (!node) return;
      const id = node.getAttribute('data-voice');
      if (app.voiceOpen === id) { app.voiceOpen = null; $('#voice-info').hidden = true; } else showVoice(id);
    };
    head.addEventListener('click', function (e) { pickVoice(e.target.closest('.voice-node')); });
    head.addEventListener('keydown', function (e) {
      if (e.key === 'Enter' || e.key === ' ') { const n = e.target.closest('.voice-node'); if (n) { e.preventDefault(); pickVoice(n); } }
    });

    document.addEventListener('keydown', function (e) {
      if (e.defaultPrevented || e.altKey || e.ctrlKey || e.metaKey) return;
      const tag = (e.target && e.target.tagName) || '';
      if (tag === 'INPUT' || tag === 'TEXTAREA') { if (e.key === 'Escape') closeDialog(); return; }
      const dialogOpen = !$('#overlay').hidden;
      if (e.key === 'Escape') {
        if (dialogOpen) closeDialog();
        else if ($('#rail').classList.contains('open')) closeRail();
        else if (app.inGame) openMenu();
        return;
      }
      if (dialogOpen || !app.inGame) return;
      if (e.key === 'd' || e.key === 'D') { e.preventDefault(); setDirector(!app.dir.on); return; }
      if ((e.key === 'b' || e.key === 'B') && app.dir.on) { e.preventDefault(); stepBack(); return; }
      if (/^[1-9]$/.test(e.key)) {
        const i = parseInt(e.key, 10) - 1;
        const b = document.querySelector('.choices .choice[data-i="' + i + '"]');
        if (b) { e.preventDefault(); b.click(); }
      }
    });

    // a republish or reload brings the player straight back into the night
    const hot = globalThis.claude && globalThis.claude.hot;
    if (hot && typeof hot.snapshot === 'function') {
      try { hot.snapshot(function () { return { inGame: app.inGame }; }); } catch (e) { /* not offered here */ }
    }
  }

  // ---------------------------------------------------------------- go

  function start() {
    const hot = globalThis.claude && globalThis.claude.hot;
    if (hot && typeof hot.ready === 'function') {
      let called = false;
      const go = function (data) { if (called) return; called = true; boot(data || {}); };
      try { hot.ready(go); } catch (e) { go({}); }
      setTimeout(function () { go((hot && hot.data) || {}); }, 1500);
    } else {
      boot((hot && hot.data) || {});
    }
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start);
  else start();
})();
