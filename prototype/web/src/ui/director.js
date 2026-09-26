// Director mode. Hutch plays the night and directs it as it goes: taps a line to rewrite it, cut
// it, add a line after it or leave Claude a note; rewords a choice; answers a writing prompt where
// it comes up; steps back to try the other branch. Then sends the lot to Claude, who merges it
// into the Ink (tools/director.mjs) and republishes.
//
// Edits play in the game as soon as they're saved, director mode or not, so the night reads the
// new way before it's merged. Director mode shows the tools and the marks: what was rewritten,
// what was cut, what a choice changed.
(function (B) {
  'use strict';

  const esc = B.util.escapeHtml;
  const D = B.Director;
  const HIDE_VARS = { passed: true, crit: true };

  function el(tag, cls, text) {
    const n = document.createElement(tag);
    if (cls) n.className = cls;
    if (text != null) n.textContent = text;
    return n;
  }

  function DirectorUI(api) {
    const C = api.C;
    const model = new D(C);
    model.load(api.store.loadEdits());

    const ui = {
      model: model,
      on: false,
      open: null,          // {node, box}: the toolbar or editor on screen
      watching: false,
      desk: null           // redraws the desk while it's open
    };

    // ------------------------------------------------------------- keeping them

    function keep(changed) {
      api.store.saveEdits(model.all());
      if (changed && changed.length) api.store.pushEdits(changed);
      bar();
    }

    // The account copy: asked for the first time an edit is saved (a tap), quietly after that.
    async function ensureDb(ask) {
      const st = api.store;
      if (st.db) { watch(); return true; }
      if (st.cloudState === 'denied' || st.cloudState === 'none') return false;
      const on = await st.connect(!!ask);
      if (on) { watch(); st.pushEdits(model.all()); bar(); }
      return on;
    }

    function watch() {
      if (ui.watching || !api.store.db) return;
      ui.watching = api.store.watchEdits(function (docs) {
        const changed = model.mergeIn(docs);
        const there = {};
        for (const d of docs) there[d.id] = String(d.updated || '');
        const behind = model.all().filter(function (e) { return !(e.id in there) || there[e.id] < String(e.updated || ''); });
        if (behind.length) api.store.pushEdits(behind);
        if (changed.length) {
          api.store.saveEdits(model.all());
          bar();
          api.rerender();
          if (ui.desk) ui.desk();
        }
      });
    }

    function saved(changed, msg) {
      keep(changed);
      close();
      api.rerender();
      if (msg) api.toast(msg);
      if (ui.desk) ui.desk();
      ensureDb(true);
    }

    // ------------------------------------------------------------- where an edit was made

    function speakerOf(it) { return it.role === 'teller' ? 'narrator' : (it.speaker || ''); }

    function ctx(src) {
      const st = api.status();
      const c = { knot: (src && src.knot) || st.knot || '', clock: st.clock, here: st.here };
      if (src && src.knot2) c.knot2 = src.knot2;
      if (src && src.at) c.at = src.at;
      if (src && src.bark) c.bark = src.bark;
      return c;
    }

    // ------------------------------------------------------------- the toolbar and the editor

    function close() {
      if (!ui.open) return;
      if (ui.open.box && ui.open.box.parentNode) ui.open.box.remove();
      if (ui.open.node) ui.open.node.classList.remove('sel');
      if (ui.open.hide) ui.open.hide.hidden = false;
      ui.open = null;
    }

    function tool(label, fn, cls) {
      const b = el('button', 'dt' + (cls ? ' ' + cls : ''), label);
      b.type = 'button';
      b.addEventListener('click', function (e) { e.stopPropagation(); fn(); });
      return b;
    }

    // Tap a line (director mode): what can be done to it.
    function select(node) {
      if (ui.open && ui.open.node === node) { close(); return; }
      close();
      const disp = node._disp;
      if (!disp) return;
      const bar = el('div', 'dtools');
      bar.setAttribute('role', 'toolbar');
      bar.setAttribute('aria-label', 'Edit this line');
      if (disp.kind === 'chosen') {
        bar.append(tool('Reword', function () { rewordChosen(node); }), tool('Note', function () { note(node); }));
        if (disp.edit) bar.append(tool('Undo reword', function () { saved([model.withdraw(disp.edit)], 'Back to the old words.'); }));
      } else {
        bar.append(tool('Rewrite', function () { rewrite(node); }));
        if (disp.inserted) bar.append(tool('Remove', function () { saved([model.withdraw(disp.inserted)], 'Line removed.'); }));
        else if (disp.cut) bar.append(tool('Put back', function () { saved([model.withdraw(disp.cut)], 'Line put back.'); }));
        else bar.append(tool('Cut', function () { cut(node); }));
        if (disp.edit && !disp.inserted) bar.append(tool('Undo rewrite', function () { saved([model.withdraw(disp.edit)], 'Back to the old words.'); }));
        bar.append(tool('Add a line after', function () { addAfter(node); }), tool('Note', function () { note(node); }));
      }
      bar.append(tool('Close', close, 'dt-x'));
      node.classList.add('sel');
      node.after(bar);
      ui.open = { node: node, box: bar };
      const first = bar.querySelector('button');
      if (first) first.focus({ preventScroll: true });
    }

    function speakerSelect(value) {
      const s = el('select', 'ed-who');
      s.setAttribute('aria-label', 'Who says it');
      const add = function (v, label, group) {
        const o = el('option', null, label);
        o.value = v;
        (group || s).append(o);
      };
      add('', 'Narration');
      add('narrator', 'The teller, years later');
      const gv = document.createElement('optgroup');
      gv.label = 'Voices in his head';
      for (const id in C.voices) add(id, C.voices[id].label || id.toUpperCase(), gv);
      const gc = document.createElement('optgroup');
      gc.label = 'People';
      for (const id in C.characters) add(id, C.characters[id].label || C.characters[id].name || id, gc);
      s.append(gv, gc);
      s.value = value || '';
      if (s.value !== (value || '')) s.value = '';
      return s;
    }

    // o: {title, text, speaker (undefined: no speaker picker), was, placeholder, saveLabel, onSave(text, speaker)}
    function editor(o) {
      const box = el('div', 'ed');
      box.addEventListener('click', function (e) { e.stopPropagation(); });
      const h = el('div', 'ed-h');
      h.append(el('span', 'ed-t', o.title));
      let who = null;
      if (o.speaker !== undefined) { who = speakerSelect(o.speaker); h.append(who); }
      box.append(h);
      const ta = el('textarea', 'ed-text');
      ta.value = o.text || '';
      ta.rows = 2;
      ta.maxLength = 4000;
      ta.placeholder = o.placeholder || '';
      ta.setAttribute('aria-label', o.title);
      const fit = function () { ta.style.height = 'auto'; ta.style.height = Math.min(ta.scrollHeight + 2, 360) + 'px'; };
      ta.addEventListener('input', fit);
      box.append(ta);
      if (o.was) {
        const w = el('p', 'ed-was');
        w.append(el('b', null, 'Was: '), document.createTextNode(o.was));
        box.append(w);
      }
      const foot = el('div', 'ed-foot');
      const save = function () { o.onSave(ta.value.trim(), who ? who.value : undefined); };
      const ok = tool(o.saveLabel || 'Save', save, 'dt-primary');
      foot.append(ok, tool('Cancel', close));
      foot.append(el('span', 'ed-keys', 'Ctrl+Enter saves'));
      box.append(foot);
      ta.addEventListener('keydown', function (e) {
        if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) { e.preventDefault(); save(); }
        else if (e.key === 'Escape') { e.preventDefault(); e.stopPropagation(); close(); }
      });
      setTimeout(function () { fit(); ta.focus(); try { ta.setSelectionRange(ta.value.length, ta.value.length); } catch (e) { /* fine */ } }, 20);
      return box;
    }

    // An editor under a node (the node stays), or in place of it (hide: true).
    function openEditor(node, o, hide) {
      close();
      const box = editor(o);
      node.after(box);
      node.classList.add('sel');
      ui.open = { node: node, box: box, hide: hide ? node : null };
      if (hide) node.hidden = true;
      return box;
    }

    // ------------------------------------------------------------- the edits

    function rewrite(node) {
      const disp = node._disp, src = node._src;
      openEditor(node, {
        title: 'Rewrite', text: disp.text, speaker: speakerOf(disp), was: disp.orig || null,
        onSave: function (text, speaker) {
          if (!text) return api.toast('Nothing written. Use Cut to lose the line.');
          let e;
          if (disp.inserted) e = model.put({ id: disp.inserted, text: text, speaker: speaker });
          else {
            const same = D.norm(D.rawOf(speaker, text)) === D.norm(src.raw);
            const ex = disp.edit ? model.get(disp.edit) : null;
            if (same && ex) e = model.withdraw(ex.id);
            else if (same) return close();
            else if (ex && ex.kind === 'rewrite') e = model.put({ id: ex.id, text: text, speaker: speaker });
            else e = model.put(Object.assign({ kind: 'rewrite', orig: src.raw, text: text, speaker: speaker }, ctx(src)));
          }
          saved([e], 'Saved. The night reads the new way now.');
        }
      }, true);
    }

    function cut(node) {
      const src = node._src;
      const e = model.put(Object.assign({ kind: 'cut', orig: src.raw }, ctx(src)));
      saved([e], 'Cut. Tap it again to put it back.');
    }

    function addAfter(node) {
      const disp = node._disp, src = node._src;
      // after an added line, the new one hangs off the added one; after any other line, off the
      // line as the Ink has it
      const anchor = disp.inserted ? disp.raw : src.raw;
      openEditor(node, {
        title: 'Add a line after this one', text: '', speaker: speakerOf(disp), placeholder: 'The new line',
        onSave: function (text, speaker) {
          if (!text) return close();
          const e = model.put(Object.assign({ kind: 'insert', orig: anchor, text: text, speaker: speaker }, ctx(src)));
          saved([e], 'Line added.');
        }
      });
    }

    function note(node) {
      const disp = node._disp, src = node._src;
      const anchor = disp.kind === 'chosen' ? (disp.orig || disp.text) : (disp.inserted ? disp.raw : src.raw);
      openEditor(node, {
        title: 'Note to Claude', text: '', placeholder: 'What should change here, and why. Or the real version of it.',
        onSave: function (text) {
          if (!text) return close();
          const e = model.put(Object.assign({ kind: 'note', orig: anchor, text: text }, ctx(src)));
          saved([e], 'Note saved.');
        }
      });
    }

    function editNote(node) {
      const e = model.get(node._edit);
      if (!e) return;
      openEditor(node, {
        title: 'Note to Claude', text: e.text, saveLabel: 'Save note',
        onSave: function (text) {
          if (!text) { saved([model.withdraw(e.id)], 'Note removed.'); return; }
          saved([model.put({ id: e.id, text: text })], 'Note saved.');
        }
      }, true);
    }

    // a choice as it was chosen, in the log
    function rewordChosen(node) {
      const disp = node._disp, src = node._src;
      openEditor(node, {
        title: 'Reword the choice', text: disp.text, was: disp.orig || null,
        onSave: function (text) { rewordSave(src.text, src.knot, disp.edit, text); }
      }, true);
    }

    // a choice on offer now
    function rewordChoice(li, choice) {
      const ex = model.choiceEdit(choice);
      openEditor(li, {
        title: 'Reword the choice', text: ex ? ex.text : choice.text, was: ex ? choice.text : null,
        onSave: function (text) { rewordSave(choice.text, choice.knot, ex && ex.id, text); }
      }, true);
    }

    function rewordSave(orig, knot, exId, text) {
      if (!text) return api.toast('A choice needs words.');
      let e;
      if (D.norm(text) === D.norm(orig)) {
        if (!exId) return close();
        e = model.withdraw(exId);
      } else if (exId) e = model.put({ id: exId, text: text });
      else e = model.put(Object.assign({ kind: 'choice', orig: orig, text: text }, ctx({ knot: knot })));
      saved([e], 'Choice reworded.');
      api.renderChoices();
    }

    function answerPrompt(box, p) {
      const ex = model.promptEdit(p);
      openEditor(box, {
        title: 'Your answer', text: ex ? ex.text : '', placeholder: 'Write it the way it goes. Claude works it into the scene.',
        onSave: function (text) {
          let e;
          if (!text) { if (!ex) return close(); e = model.withdraw(ex.id); }
          else if (ex) e = model.put({ id: ex.id, text: text });
          else e = model.put(Object.assign({ kind: 'prompt', prompt: { text: p.text, loc: p.loc, knot: p.knot }, text: text }, ctx({ knot: p.knot })));
          saved([e], 'Answer saved.');
        }
      }, true);
    }

    // ------------------------------------------------------------- drawing

    // Called for every line and chosen node the page draws.
    function decorate(node, disp) {
      node._disp = disp;
      node._src = disp.src || disp;
      if (disp.edit || disp.inserted) {
        node.classList.add(disp.inserted ? 'ins' : 'edited');
        if (disp.orig && !disp.inserted) node.title = 'Was: ' + disp.orig;
      }
      if (disp.cut) node.classList.add('cut');
      node.setAttribute('data-dir', '');
    }

    function noteNode(item) {
      const n = el('div', 'dnote');
      n._edit = item.edit;
      n.setAttribute('data-dnote', '');
      n.append(el('span', 'dn-h', 'Note'), document.createTextNode(item.text));
      return n;
    }

    function diffNode(item) {
      const parts = [];
      for (const c of item.changes || []) {
        if (HIDE_VARS[c.name]) continue;
        if (c.name === 'clock') { const m = (c.to | 0) - (c.from | 0); parts.push('<b>' + (m >= 0 ? '+' : '') + m + ' min</b>'); continue; }
        if (c.add || c.del) {
          const bits = [];
          for (const a of c.add) bits.push('+' + esc(a));
          for (const d of c.del) bits.push('−' + esc(d));
          parts.push(esc(c.name) + ' ' + bits.join(' '));
          continue;
        }
        parts.push(esc(c.name) + ' ' + esc(String(c.from)) + '→' + esc(String(c.to)));
      }
      if (!parts.length) return null;
      const n = el('div', 'diff');
      n.innerHTML = '<span class="diff-h">Changed</span> ' + parts.join('<span class="sep"> · </span>');
      return n;
    }

    // Writing prompts, where the night first reaches them. Hutch can answer in place.
    function promptCard(list) {
      const d = el('div', 'prompt-card');
      const where = list[0].loc === 'here' ? 'here' : String(list[0].loc || '').replace(/^content\/ink\//, '').split(':')[0];
      d.append(el('span', 'pc-h', (list.length === 1 ? 'Writing prompt' : 'Writing prompts') + (where ? ', ' + where : '')));
      for (const p of list) d.append(promptItem(p));
      return d;
    }

    function promptItem(p) {
      const box = el('div', 'pc-item');
      box.append(el('p', 'pc-q', p.text));
      const ex = model.promptEdit(p);
      if (ex) {
        const a = el('p', 'pc-a');
        a.append(el('b', null, 'You wrote: '), document.createTextNode(ex.text));
        box.append(a);
        box.append(el('span', 'pc-st st-' + ex.status, D.STATUS_WORDS[ex.status] || ex.status));
      }
      const b = tool(ex ? 'Change it' : 'Write it', function () { answerPrompt(box, p); }, 'pc-write');
      box.append(b);
      return box;
    }

    function choiceTools(li, choice) {
      const b = el('button', 'ch-ed', 'Reword');
      b.type = 'button';
      b.title = 'Reword this choice without choosing it';
      b.addEventListener('click', function (e) { e.stopPropagation(); rewordChoice(li, choice); });
      li.append(b);
    }

    function choiceText(choice) {
      const e = model.choiceEdit(choice);
      return e ? e.text : choice.text;
    }

    // The strip at the top of the story while directing.
    function bar() {
      const b = document.getElementById('dir-bar');
      if (!b) return;
      b.hidden = !ui.on;
      if (!ui.on) return;
      const c = model.counts();
      const n = b.querySelector('[data-dir-count]');
      if (n) n.textContent = c.open ? c.open + (c.open === 1 ? ' edit open' : ' edits open') : 'No open edits';
      const back = b.querySelector('[data-act="dir-back"]');
      if (back) back.disabled = !api.canStepBack();
    }

    function setOn(on, quiet) {
      ui.on = !!on;
      document.getElementById('app').classList.toggle('directing', ui.on);
      close();
      bar();
      if (ui.on) ensureDb(false);
      api.renderChoices();
      if (!quiet) api.toast(ui.on ? 'Director mode. Tap any line to change it.' : 'Director mode off.');
    }

    // ------------------------------------------------------------- the desk

    function whereText(e) {
      const bits = [];
      if (e.clock) bits.push(api.fmtClock(e.clock));
      if (e.here && api.place(e.here)) bits.push(api.place(e.here).toLowerCase());
      return bits.join(', ');
    }

    function editCard(e) {
      const card = el('div', 'ecard k-' + e.kind + ' s-' + e.status);
      const h = el('div', 'ec-h');
      h.append(el('span', 'ec-kind', D.KIND_WORDS[e.kind] || e.kind));
      const w = whereText(e);
      if (w) h.append(el('span', 'ec-where', w));
      if (e.knot) h.append(el('code', 'ec-knot', e.knot));
      h.append(el('span', 'ec-st', model.merged.has(e.id) ? 'In the game' : (D.STATUS_WORDS[e.status] || e.status)));
      card.append(h);
      const row = function (label, text, cls) {
        const p = el('p', cls);
        p.append(el('b', null, label), document.createTextNode(text));
        card.append(p);
      };
      if (e.kind === 'rewrite') { row('Was: ', e.orig, 'ec-was'); row('Now: ', D.rawOf(e.speaker, e.text), 'ec-now'); }
      else if (e.kind === 'cut') row('Cut: ', e.orig, 'ec-was');
      else if (e.kind === 'insert') { row('After: ', e.orig, 'ec-was'); row('Added: ', D.rawOf(e.speaker, e.text), 'ec-now'); }
      else if (e.kind === 'choice') { row('Was: ', e.orig, 'ec-was'); row('Now: ', e.text, 'ec-now'); }
      else if (e.kind === 'note') { if (e.orig) row('At: ', e.orig, 'ec-was'); row('', e.text, 'ec-now'); }
      else if (e.kind === 'prompt') { row('Prompt: ', (e.prompt && e.prompt.text) || '', 'ec-was'); row('You wrote: ', e.text, 'ec-now'); }
      if (e.reply) row('Claude: ', e.reply, 'ec-reply');
      if (e.status !== 'withdrawn' && e.status !== 'merged') {
        const f = el('div', 'ec-foot');
        f.append(tool('Take it back', function () { keep([model.withdraw(e.id)]); api.rerender(); if (ui.desk) ui.desk(); }));
        card.append(f);
      } else if (e.status === 'withdrawn') {
        const f = el('div', 'ec-foot');
        f.append(tool('Restore it', function () { keep([model.put({ id: e.id, status: 'draft' })]); api.rerender(); if (ui.desk) ui.desk(); }));
        card.append(f);
      }
      return card;
    }

    function deskEdits(show) {
      const box = el('div', 'desk-edits');
      const all = model.all();
      const list = show === 'all' ? all : all.filter(function (e) { return model.isOpen(e); });
      const c = model.counts();
      const p = el('p', 'desk-sum');
      p.textContent = c.open
        ? c.open + (c.open === 1 ? ' edit' : ' edits') + ' not in the Ink yet. They play in the game already.'
        : 'Nothing waiting. Turn on director mode and tap a line to change it.';
      box.append(p);
      if (!list.length && show !== 'all') return box;
      for (const e of list.slice().reverse()) box.append(editCard(e));
      if (!list.length) box.append(el('p', 'desk-none', 'No edits yet.'));
      return box;
    }

    function deskPrompts() {
      const box = el('div', 'desk-prompts');
      const prompts = (C.meta && C.meta.prompts) || [];
      const answered = prompts.filter(function (p) { return model.promptEdit(p); }).length;
      box.append(el('p', 'desk-sum', prompts.length + ' writing prompts in the draft, ' + answered + ' answered. Answer one here, or play to it and answer it where it comes up.'));
      const knots = new Set((C.meta && C.meta.knots) || []);
      let file = null;
      for (const p of prompts) {
        const f = String(p.loc || '').replace(/^content\/ink\//, '').split(':')[0];
        if (f !== file) { file = f; box.append(el('h3', null, f)); }
        const item = promptItem(p);
        if (p.knot && knots.has(p.knot)) {
          item.append(tool('Play it', function () {
            api.closeDialog();
            api.jumpTo(p.knot);
          }, 'pc-go'));
        }
        box.append(item);
      }
      return box;
    }

    async function comments() {
      if (ui._comments !== undefined) return ui._comments;
      const c = globalThis.claude;
      if (!c || typeof c.use !== 'function') { ui._comments = null; return null; }
      try { ui._comments = await c.use('comments'); } catch (e) { ui._comments = null; }
      return ui._comments;
    }

    async function downloads() {
      if (ui._downloads !== undefined) return ui._downloads;
      const c = globalThis.claude;
      if (!c || typeof c.use !== 'function') { ui._downloads = null; return null; }
      try { ui._downloads = await c.use('downloads'); } catch (e) { ui._downloads = null; }
      return ui._downloads;
    }

    function blobDownload(blob, name) {
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = name;
      document.body.append(a);
      a.click();
      setTimeout(function () { URL.revokeObjectURL(url); a.remove(); }, 4000);
    }

    async function offerFile(name, data, type) {
      const dl = await downloads();
      if (dl) {
        try { await dl.save({ filename: name, data: data }); api.toast('Saved.'); return true; }
        catch (e) { if (!e || e.code !== 'declined') api.toast('It could not be saved from here.'); return false; }
      }
      blobDownload(data instanceof Blob ? data : new Blob([data], { type: type || 'application/octet-stream' }), name);
      return true;
    }

    function stamp() { return new Date().toISOString().slice(0, 16).replace('T', '-').replace(':', ''); }

    function exportEdits() {
      const json = JSON.stringify(model.exportData(), null, 1);
      return offerFile('bouncer-edits-' + stamp() + '.json', json, 'application/json');
    }

    function importEdits() {
      const inp = document.createElement('input');
      inp.type = 'file';
      inp.accept = '.json,application/json';
      inp.addEventListener('change', function () {
        const f = inp.files && inp.files[0];
        if (!f) return;
        const r = new FileReader();
        r.onload = function () {
          let list = null;
          try { list = D.readImport(JSON.parse(String(r.result))); } catch (e) { list = null; }
          if (!list) { api.toast('That is not a file of edits from this game.'); return; }
          const changed = model.mergeIn(list);
          keep(changed);
          api.rerender();
          if (ui.desk) ui.desk();
          api.toast(changed.length ? changed.length + (changed.length === 1 ? ' edit' : ' edits') + ' loaded.' : 'Nothing new in that file.');
        };
        r.readAsText(f);
      });
      inp.click();
    }

    async function saveOffline() {
      let blob = null;
      try {
        const res = await fetch('offline/The-Bouncer.html');
        if (res.ok) blob = await res.blob();
      } catch (e) { blob = null; }
      if (!blob || blob.size < 10000) { api.toast('The offline copy is not in this build.'); return; }
      offerFile('The-Bouncer.html', blob, 'text/html');
    }

    async function send(btn, out) {
      const c = await comments();
      const text = model.summary(api.fmtClock);
      btn.disabled = true;
      out.textContent = 'Sending...';
      await ensureDb(true);
      await api.store.flushEdits(8000);
      try {
        const target = document.querySelector('.story-inner') || document.body;
        const anchor = await c.anchorFor(target);
        await c.sendToClaude({ anchor: anchor, text: text });
        const now = new Date().toISOString();
        const sent = [];
        for (const e of model.all()) if (e.status === 'draft' && model.isOpen(e)) sent.push(model.put({ id: e.id, status: 'sent', sentAt: now }));
        keep(sent);
        out.textContent = 'Sent. Claude answers in this page\'s comments and on each edit here once it is merged.';
        if (ui.desk) setTimeout(ui.desk, 1200);
      } catch (e) {
        btn.disabled = false;
        const code = e && e.code;
        out.textContent = code === 'consent_required' ? 'Not sent: the page needs your OK to comment for you. Try again and allow it.'
          : code === 'forbidden' ? 'Commenting from the game is off for this page. Your edits are saved; tell Claude in the project.'
          : code === 'claude_unavailable' ? 'No Claude session could take it just now. Your edits are saved; tell Claude in the project.'
          : code === 'rate_limited' ? 'Too many sends at once. Wait a minute and try again.'
          : 'It did not go through. Your edits are saved; tell Claude in the project.';
      }
    }

    function deskSend(box) {
      const c = model.counts();
      const st = api.store;
      const where = st.db && st.editsSync !== 'failed' ? 'in this browser and with the game in your Claude account, where Claude can read them' : 'in this browser only';
      box.append(el('p', 'desk-sum', (c.open ? c.open + (c.open === 1 ? ' edit is' : ' edits are') + ' waiting.' : 'No edits are waiting.') + ' They are saved ' + where + '.'));

      const sendRow = el('div', 'desk-send');
      const out = el('p', 'desk-out');
      box.append(sendRow, out);
      (async function () {
        const cm = await comments();
        let can = 'off';
        if (cm) { try { can = await cm.canSendToClaude(); } catch (e) { can = 'off'; } }
        if (can === 'available') {
          const b = tool('Send to Claude', function () { send(b, out); }, 'dt-primary big');
          b.disabled = !c.open;
          sendRow.append(b);
          out.textContent = 'Claude gets a comment on this page listing the edits, merges them into the Ink and republishes. Its answers come back here, on each edit.';
        } else {
          const why = { writers_only: 'Only editors of this page can send to Claude from it.', no_session: 'No Claude session is watching this page right now.', off: '' }[can] || '';
          out.textContent = (why ? why + ' ' : '') + (st.db && st.editsSync !== 'failed'
            ? 'Your edits are saved with the game. In the project, tell Claude: "Merge my edits from the game."'
            : 'Save your edits as a file below and send the file to Claude in the project.');
        }
      })();

      box.append(el('h3', null, 'Files'));
      const files = el('div', 'btn-row');
      files.append(tool('Save my edits as a file', exportEdits), tool('Load edits from a file', importEdits));
      box.append(files);
      if (!(C.meta && C.meta.offline) && globalThis.claude) {
        box.append(el('h3', null, 'The game on your computer'));
        box.append(el('p', 'desk-hint', 'One file with the whole game in it, this build, edits and all. Double-click it to play without the internet. Your saves and edits there stay on that computer until you send the edits file.'));
        const r = el('div', 'btn-row');
        r.append(tool('Save a copy to play offline', saveOffline));
        box.append(r);
      }
    }

    function openDesk(tab) {
      let show = 'open';
      api.openDialog(function (dlg) {
        api.heading(dlg, 'Director’s desk');
        const tabs = el('div', 'tabs');
        tabs.setAttribute('role', 'tablist');
        const body = el('div', 'desk-body');
        const pages = {
          Edits: function () {
            const f = api.seg('Show', [['open', 'Waiting'], ['all', 'All']], show, function (v) { show = v; select('Edits'); });
            const top = el('div', 'desk-top');
            top.append(f);
            top.append(tool('Note about now', function () { sceneNote(); }));
            return [top, deskEdits(show)];
          },
          Prompts: function () { return [deskPrompts()]; },
          Send: function () { const b = el('div'); deskSend(b); return [b]; }
        };
        let current = tab && pages[tab] ? tab : 'Edits';
        const select = function (name) {
          current = name;
          for (const b of tabs.children) b.setAttribute('aria-selected', String(b.textContent === name));
          const y = body.scrollTop;
          body.innerHTML = '';
          for (const n of pages[name]()) body.append(n);
          body.scrollTop = y;
        };
        for (const n of Object.keys(pages)) {
          const b = el('button', null, n);
          b.type = 'button';
          b.setAttribute('role', 'tab');
          b.addEventListener('click', function () { select(n); });
          tabs.append(b);
        }
        dlg.append(tabs, body);
        select(current);
        ui.desk = function () { if (document.getElementById('dialog').contains(body)) select(current); else ui.desk = null; };
        api.foot(dlg, [
          tool(ui.on ? 'Director mode off' : 'Director mode on', function () { api.closeDialog(); setOn(!ui.on); }),
          tool('Close', api.closeDialog, 'dt-primary')
        ]);
      }, true);
    }

    // A note about the moment he's in, not tied to a line.
    function sceneNote() {
      api.openDialog(function (dlg) {
        api.heading(dlg, 'Note about now');
        const st = api.status();
        dlg.append(el('p', 'desk-hint', 'For Claude, about this moment in the night (' + api.fmtClock(st.clock) + (api.place(st.here) ? ', ' + api.place(st.here).toLowerCase() : '') + '): what should happen here, what is missing, what rings false.'));
        const ta = el('textarea', 'io');
        ta.id = 'scene-note';
        ta.maxLength = 4000;
        dlg.append(ta);
        api.foot(dlg, [
          tool('Cancel', function () { openDesk('Edits'); }),
          tool('Save note', function () {
            const t = ta.value.trim();
            if (!t) { openDesk('Edits'); return; }
            const e = model.put(Object.assign({ kind: 'note', text: t }, ctx(null)));
            keep([e]);
            ensureDb(true);
            openDesk('Edits');
            api.toast('Note saved.');
          }, 'dt-primary')
        ]);
        setTimeout(function () { ta.focus(); }, 30);
      });
    }

    // ------------------------------------------------------------- wiring

    // Taps in the story while directing.
    function onLogClick(e) {
      if (!ui.on) return false;
      if (e.target.closest('.dtools, .ed, button, a, select, textarea, input')) return false;
      const dn = e.target.closest('[data-dnote]');
      if (dn) { editNote(dn); return true; }
      const node = e.target.closest('[data-dir]');
      if (!node) { close(); return false; }
      select(node);
      return true;
    }

    ui.overlay = function (items) { return model.overlay(items); };
    ui.decorate = decorate;
    ui.noteNode = noteNode;
    ui.diffNode = diffNode;
    ui.promptCard = promptCard;
    ui.choiceTools = choiceTools;
    ui.choiceText = choiceText;
    ui.setOn = setOn;
    ui.bar = bar;
    ui.close = close;
    ui.openDesk = openDesk;
    ui.onLogClick = onLogClick;
    ui.ensureDb = ensureDb;
    ui.exportEdits = exportEdits;
    ui.hasEdits = function () { return model.all().length > 0; };
    return ui;
  }

  B.DirectorUI = DirectorUI;
})(globalThis.Bouncer = globalThis.Bouncer || {});
