// The director's edits: what Hutch changes while playing, before it is in the Ink.
//
// An edit is kept against the line exactly as the game printed it ("FATHER: Count them."), so
// it finds that line again wherever the night shows it, and tools/director.mjs can find the
// line in content/ink/ when Claude merges it. Until then the game lays the edits over the
// story as it plays: rewritten lines read the new way, cut lines drop out, added lines appear.
//
// No DOM here. The page (src/ui/director.js) draws and saves the edits; this file is the model.
//
//   kind      what it does                                  keyed on
//   rewrite   new words (and maybe a new speaker) for a line  the line
//   cut       the line goes                                   the line
//   insert    a new line after this one                       the line before it
//   choice    new words for a choice                          the choice
//   note      a note to Claude about this moment              the line (or nothing)
//   prompt    Hutch's answer to a writing prompt              the prompt
//
//   status    draft (saved here) -> sent (Claude has been told) -> merged (in the Ink)
//             asked (Claude answered with a question; the edit still plays)
//             withdrawn (Hutch took it back)
(function (B) {
  'use strict';

  const KINDS = ['rewrite', 'cut', 'insert', 'choice', 'note', 'prompt'];
  const KIND_WORDS = { rewrite: 'Rewrite', cut: 'Cut', insert: 'Added line', choice: 'Choice', note: 'Note', prompt: 'Prompt answer' };
  const STATUS_WORDS = { draft: 'Saved here', sent: 'Sent to Claude', merged: 'In the game', asked: 'Claude asked', withdrawn: 'Taken back' };
  const OPEN = { draft: true, sent: true, asked: true };
  const TEXT_MAX = 4000;

  // How the game and the merge tool compare a line: curly quotes made straight, runs of
  // whitespace made one space, trimmed.
  function norm(s) {
    return String(s == null ? '' : s)
      .replace(/[‘’]/g, "'").replace(/[“”]/g, '"')
      .replace(/\s+/g, ' ').trim();
  }

  function newId() {
    return 'e' + Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
  }

  // "FATHER: text" for a voice or character, "NARRATOR: text" for the teller, plain for narration.
  function rawOf(speaker, text) {
    const t = String(text || '').replace(/\s*\n\s*/g, ' ').trim();
    if (!speaker) return t;
    return String(speaker).toUpperCase() + ': ' + t;
  }

  class Director {
    // content: the game content (voices, characters, meta.build, meta.merged)
    constructor(content) {
      this.content = content || {};
      this.build = (this.content.meta && this.content.meta.build) || '';
      this.merged = new Set((this.content.meta && this.content.meta.merged) || []);
      this.edits = {};
      this._idx = null;
      this.speakers = { '': { role: 'narration', label: '' }, narrator: { role: 'teller', label: '' } };
      for (const id in (this.content.voices || {})) {
        const d = this.content.voices[id];
        this.speakers[id] = { role: 'voice', label: d.label || id.toUpperCase(), name: d.label || id };
      }
      for (const id in (this.content.characters || {})) {
        const d = this.content.characters[id];
        this.speakers[id] = { role: 'dialogue', label: d.label || d.name || id.toUpperCase(), name: d.label || d.name || id };
      }
    }

    // ---- the set -------------------------------------------------------

    load(list) {
      this.edits = {};
      for (const e of list || []) if (e && e.id && KINDS.indexOf(e.kind) !== -1) this.edits[e.id] = e;
      this._idx = null;
    }

    all() {
      return Object.keys(this.edits).map((k) => this.edits[k])
        .sort(function (a, b) { return String(a.created).localeCompare(String(b.created)); });
    }

    get(id) { return this.edits[id] || null; }

    // Live: shown in the game now. An edit Claude has merged is in this build's Ink already.
    live(e) { return !!e && e.status !== 'withdrawn' && !this.merged.has(e.id); }
    isOpen(e) { return !!e && !!OPEN[e.status] && !this.merged.has(e.id); }

    // Make or change an edit. Returns the stored edit.
    put(fields) {
      const now = new Date().toISOString();
      const old = fields.id ? this.edits[fields.id] : null;
      const e = Object.assign({}, old || { id: newId(), created: now, build: this.build, status: 'draft' }, fields);
      if (e.text != null) e.text = String(e.text).slice(0, TEXT_MAX);
      e.updated = now;
      // changing something already sent or merged sends it again
      if (old && fields.status === undefined && old.status !== 'draft') {
        e.status = 'draft';
        if (this.merged.has(e.id)) this.merged.delete(e.id);
      }
      this.edits[e.id] = e;
      this._idx = null;
      return e;
    }

    withdraw(id) {
      const e = this.edits[id];
      if (!e) return null;
      return this.put({ id: id, status: 'withdrawn' });
    }

    // Edits from elsewhere (the account's copy, an imported file). The newer of two copies wins.
    // Returns the edits that changed here.
    mergeIn(list) {
      const changed = [];
      for (const r of list || []) {
        if (!r || !r.id || KINDS.indexOf(r.kind) === -1) continue;
        const l = this.edits[r.id];
        if (!l || String(r.updated || '') > String(l.updated || '')) {
          this.edits[r.id] = Object.assign({}, r);
          changed.push(this.edits[r.id]);
        }
      }
      if (changed.length) this._idx = null;
      return changed;
    }

    counts() {
      const c = { open: 0, draft: 0, total: 0 };
      for (const k of KINDS) c[k] = 0;
      for (const e of this.all()) {
        if (e.status === 'withdrawn') continue;
        c.total++;
        if (this.isOpen(e)) { c.open++; c[e.kind]++; }
        if (e.status === 'draft') c.draft++;
      }
      return c;
    }

    // ---- lookups -------------------------------------------------------

    _index() {
      if (this._idx) return this._idx;
      const idx = { line: new Map(), ins: new Map(), note: new Map(), choice: new Map(), prompt: new Map() };
      const add = function (map, key, e) { if (!map.has(key)) map.set(key, []); map.get(key).push(e); };
      for (const e of this.all()) {
        if (!this.live(e)) continue;
        if (e.kind === 'rewrite' || e.kind === 'cut') add(idx.line, norm(e.orig), e);
        else if (e.kind === 'insert') add(idx.ins, norm(e.orig), e);
        else if (e.kind === 'note' && e.orig) add(idx.note, norm(e.orig), e);
        else if (e.kind === 'choice') add(idx.choice, norm(e.orig), e);
        else if (e.kind === 'prompt') idx.prompt.set(Director.promptKey(e.prompt || {}), e);
      }
      this._idx = idx;
      return idx;
    }

    // Of several edits on the same words, the one made in the same part of the Ink, else the newest.
    _pick(list, knot, knot2) {
      if (!list || !list.length) return null;
      for (const k of [knot, knot2]) {
        if (!k) continue;
        const here = list.filter(function (e) { return e.knot === k || e.knot2 === k; });
        if (here.length) return here[here.length - 1];
      }
      return list[list.length - 1];
    }

    // What the director has done to one line the game printed.
    // -> { rewrite, cut, inserts: [edit], notes: [edit] } (null fields when nothing)
    forLine(item) {
      const idx = this._index();
      const key = norm(item.raw != null ? item.raw : rawOf(item.speaker, item.text));
      const onLine = (idx.line.get(key) || []);
      const rewrite = this._pick(onLine.filter(function (e) { return e.kind === 'rewrite'; }), item.knot, item.knot2);
      const cut = this._pick(onLine.filter(function (e) { return e.kind === 'cut'; }), item.knot, item.knot2);
      // a choice written without [brackets] is printed again as a line: its rewrite follows
      const echo = !rewrite && !item.speaker ? this._pick(idx.choice.get(key), item.knot, item.knot2) : null;
      return {
        rewrite: rewrite || echo,
        cut: cut,
        inserts: (idx.ins.get(key) || []).slice(),
        notes: (idx.note.get(key) || []).slice()
      };
    }

    choiceEdit(choice) {
      return this._pick(this._index().choice.get(norm(choice.text)), choice.knot);
    }

    promptEdit(prompt) {
      return this._index().prompt.get(Director.promptKey(prompt)) || null;
    }

    // A line item as the edit has it: new words, and a new speaker if the edit changed it.
    lineAs(item, e) {
      const out = Object.assign({}, item);
      out.text = e.text;
      out.edit = e.id;
      out.orig = item.raw != null ? item.raw : item.text;
      if (e.speaker !== undefined && e.speaker !== null) {
        const sp = this.speakers[e.speaker] || this.speakers[''];
        out.speaker = e.speaker && e.speaker !== 'narrator' ? e.speaker : undefined;
        out.label = sp.label || undefined;
        out.role = sp.role;
      }
      out.raw = rawOf(e.speaker != null ? e.speaker : item.speaker, e.text);
      return out;
    }

    // An added line as the game would print it.
    insertedLine(e, anchor) {
      const sp = this.speakers[e.speaker || ''] || this.speakers[''];
      return {
        kind: 'line', role: sp.role, text: e.text,
        speaker: e.speaker && e.speaker !== 'narrator' ? e.speaker : undefined,
        label: sp.label || undefined,
        raw: rawOf(e.speaker, e.text),
        knot: anchor ? anchor.knot : e.knot,
        screen: anchor ? anchor.screen : null,
        inserted: e.id
      };
    }

    // The items of a batch with the edits laid over them. Cut lines stay in, marked, so the
    // page can show them struck through to the director and leave them out for everyone else.
    // Notes come back as {kind:'dnote'} items after their line.
    overlay(items) {
      if (!Object.keys(this.edits).length) return items;
      const out = [];
      const self = this;
      const lay = function (it, depth) {
        if (it.kind === 'chosen') {
          const ce = self.choiceEdit({ text: it.text, knot: it.knot });
          out.push(ce ? Object.assign({}, it, { text: ce.text, edit: ce.id, orig: it.text }) : it);
          return;
        }
        if (it.kind !== 'line' || it.role === 'system') { out.push(it); return; }
        const f = self.forLine(it);
        let shown = f.rewrite ? self.lineAs(it, f.rewrite) : it;
        if (f.cut) shown = Object.assign({}, shown, { cut: f.cut.id });
        if (shown !== it) shown.src = it;
        out.push(shown);
        for (const n of f.notes) out.push({ kind: 'dnote', edit: n.id, text: n.text, screen: it.screen });
        // added lines can have lines added after them; a loop of them stops at a depth of 20
        if (depth < 20) for (const e of f.inserts) lay(self.insertedLine(e, it), depth + 1);
      };
      for (const it of items) lay(it, 0);
      return out;
    }

    // ---- telling Claude ------------------------------------------------

    // Plain text for the comment that brings Claude in: a count, then the edits themselves until
    // the text runs to about 3,800 bytes. The whole set is in the game's database either way.
    summary(fmtClock) {
      const open = this.all().filter((e) => this.isOpen(e) && e.status !== 'asked');
      const c = {};
      for (const e of open) c[e.kind] = (c[e.kind] || 0) + 1;
      const parts = [];
      const plural = function (n, one, many) { return n + ' ' + (n === 1 ? one : many); };
      if (c.rewrite) parts.push(plural(c.rewrite, 'rewrite', 'rewrites'));
      if (c.cut) parts.push(plural(c.cut, 'cut', 'cuts'));
      if (c.insert) parts.push(plural(c.insert, 'added line', 'added lines'));
      if (c.choice) parts.push(plural(c.choice, 'choice reworded', 'choices reworded'));
      if (c.note) parts.push(plural(c.note, 'note', 'notes'));
      if (c.prompt) parts.push(plural(c.prompt, 'prompt answer', 'prompt answers'));
      const head = [
        'Director\'s edits from The Bouncer, build ' + this.build + ': ' + (parts.join(', ') || 'nothing new') + '.',
        'They are saved in the game (the "edits" collection). Please merge them into the Ink and republish.',
        ''
      ];
      const lines = [];
      const q = function (s) { return '"' + norm(s).slice(0, 220) + '"'; };
      open.forEach(function (e, i) {
        const when = e.clock && fmtClock ? fmtClock(e.clock) + ', ' : '';
        const where = when + (e.knot || 'no scene');
        let t;
        if (e.kind === 'rewrite') t = 'Rewrite (' + where + '): ' + q(e.orig) + ' -> ' + q(rawOf(e.speaker, e.text));
        else if (e.kind === 'cut') t = 'Cut (' + where + '): ' + q(e.orig);
        else if (e.kind === 'insert') t = 'Add after ' + q(e.orig) + ' (' + where + '): ' + q(rawOf(e.speaker, e.text));
        else if (e.kind === 'choice') t = 'Choice (' + where + '): ' + q(e.orig) + ' -> ' + q(e.text);
        else if (e.kind === 'note') t = 'Note (' + where + (e.orig ? ', at ' + q(e.orig) : '') + '): ' + q(e.text);
        else t = 'Prompt answer (' + ((e.prompt && e.prompt.loc) || where) + '): ' + q(e.text);
        lines.push((i + 1) + '. ' + t);
      });
      let text = head.join('\n');
      const enc = typeof TextEncoder !== 'undefined' ? new TextEncoder() : null;
      const size = function (s) { return enc ? enc.encode(s).length : s.length * 3; };
      let shown = 0;
      for (const l of lines) {
        if (size(text + l + '\n') > 3800) break;
        text += l + '\n';
        shown++;
      }
      if (shown < lines.length) text += '...and ' + (lines.length - shown) + ' more in the game.\n';
      return text.trim();
    }

    // ---- files ---------------------------------------------------------

    exportData() {
      return { game: 'the-bouncer', kind: 'director-edits', v: 1, build: this.build, exportedAt: new Date().toISOString(), edits: this.all() };
    }

    static readImport(obj) {
      if (Array.isArray(obj)) return obj;
      if (obj && obj.game === 'the-bouncer' && Array.isArray(obj.edits)) return obj.edits;
      return null;
    }

    static promptKey(p) { return norm((p.knot || '') + '|' + (p.text || '')); }
  }

  Director.KINDS = KINDS;
  Director.KIND_WORDS = KIND_WORDS;
  Director.STATUS_WORDS = STATUS_WORDS;
  Director.norm = norm;
  Director.rawOf = rawOf;
  B.Director = Director;
})(globalThis.Bouncer = globalThis.Bouncer || {});
