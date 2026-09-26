#!/usr/bin/env node
// Merge the director's edits into the Ink.
//
// Hutch makes the edits in the game (director mode, src/ui/director.js). They come here as a file:
// the game's "Save my edits as a file", or the artifact's "edits" collection as Claude reads it.
//
//   node tools/director.mjs <edits.json>            dry run: what would change, what needs a hand
//   node tools/director.mjs <edits.json> --apply    change content/ink/ (and barks.yaml), record the
//                                                   merged edits in content/director/merged.json and
//                                                   keep the batch in content/director/inbox/
//   node tools/director.mjs <edits.json> --json out.json
//                                                   also write the result (applied, needs a hand,
//                                                   notes, prompt answers) as JSON
//   node tools/director.mjs --mark e1,e2 --note "why" [--apply]
//                                                   record edits Claude merged by hand
//
// What it does by itself: rewrites, cuts, added lines and reworded choices on lines whose words are
// fixed in the Ink. What it leaves for Claude, with the places to look: lines built from logic
// ({...}), lines the words match in more than one place, notes, and answers to writing prompts.
// Rebuild afterwards (node tools/build.mjs) and play the changed scenes; the bots catch breakage.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const P = (...a) => path.join(ROOT, ...a);
const rel = (f) => path.relative(ROOT, f);

// ---------------------------------------------------------------- matching, as the game does it

export function norm(s) {
  return String(s == null ? '' : s)
    .replace(/[‘’]/g, "'").replace(/[“”]/g, '"')
    .replace(/\s+/g, ' ').trim();
}

export function rawOf(speaker, text) {
  const t = String(text || '').replace(/\s*\n\s*/g, ' ').trim();
  return speaker ? String(speaker).toUpperCase() + ': ' + t : t;
}

// ---------------------------------------------------------------- reading an Ink line

// Split one line of Ink into the parts an edit can touch.
//   lead   indentation, choice or gather bullets, a (label), a {condition} on a choice
//   body   the words (for a choice, everything up to the tags or divert)
//   tail   tags, divert, comment
// kind: 'content', 'choice', or null for lines that are logic, structure or comment.
export function parseLine(line) {
  const m = /^(\s*)(.*)$/.exec(line);
  const indent = m[1];
  let rest = m[2];
  if (!rest || /^(\/\/|\/\*|\*\/|~|VAR\b|CONST\b|LIST\b|INCLUDE\b|EXTERNAL\b|={1,}|->|<-|#|\}|TODO)/.test(rest)) return { kind: null };
  let lead = indent;
  let kind = 'content';
  let gather = false;
  // bullets: * + for choices, - for gathers and alternatives
  const bm = /^((?:[*+]\s*)+)/.exec(rest);
  if (bm) { kind = 'choice'; lead += bm[1]; rest = rest.slice(bm[1].length); }
  else {
    const gm = /^((?:-(?!>)\s*)+)/.exec(rest);
    if (gm) { gather = true; lead += gm[1]; rest = rest.slice(gm[1].length); }
  }
  const lm = /^(\([A-Za-z0-9_]+\)\s*)/.exec(rest);
  if (lm) { lead += lm[1]; rest = rest.slice(lm[1].length); }
  if (kind === 'choice') {
    // conditions on a choice: {a} {b}
    let cm;
    while ((cm = /^(\{[^{}]*\}\s*)/.exec(rest))) { lead += cm[1]; rest = rest.slice(cm[1].length); }
  } else if (gather && (/^[^{}"]*:\s*(->.*)?$/.test(rest) || /^else\s*:/.test(rest))) {
    return { kind: null };  // "- cond:" inside a conditional block
  }
  // tail: comment, then divert, then tags (tags inside a choice's [brackets] stay in the body)
  let tail = '';
  const cmt = rest.indexOf('//');
  if (cmt !== -1) { tail = rest.slice(cmt) + tail; rest = rest.slice(0, cmt); }
  const dv = indexOutside(rest, '->');
  if (dv !== -1) { tail = rest.slice(dv) + tail; rest = rest.slice(0, dv); }
  const tg = indexOutside(rest, '#', kind === 'choice');
  if (tg !== -1) { tail = rest.slice(tg) + tail; rest = rest.slice(0, tg); }
  const trail = /\s*$/.exec(rest)[0];
  const body = rest.slice(0, rest.length - trail.length);
  tail = trail + tail;
  if (!body.trim() && kind !== 'choice') return { kind: null };
  return { kind, lead, body, tail, dynamic: /[{}]/.test(body) };
}

// First index of `tok` not inside {braces} (and, for a choice, not inside [brackets]).
function indexOutside(s, tok, skipBrackets) {
  let brace = 0, bracket = 0;
  for (let i = 0; i < s.length; i++) {
    const c = s[i];
    if (c === '{') brace++;
    else if (c === '}') brace = Math.max(0, brace - 1);
    else if (skipBrackets && c === '[') bracket++;
    else if (skipBrackets && c === ']') bracket = Math.max(0, bracket - 1);
    else if (!brace && !bracket && s.startsWith(tok, i)) return i;
  }
  return -1;
}

// A choice's words as the player sees them, and as the game prints them after it's taken.
//   * [shown]         shown: "shown", printed: ""
//   * both            shown: "both", printed: "both"
//   * a[b]c           shown: "ab", printed: "ac"
export function choiceParts(body) {
  const strip = (s) => s.replace(/#[^\]]*$/, '').replace(/\s*#.*$/, '');
  const o = body.indexOf('['), c = body.lastIndexOf(']');
  if (o === -1 || c < o) return { shown: body.trim(), printed: body.trim(), form: 'plain' };
  const a = body.slice(0, o), b = strip(body.slice(o + 1, c)), z = body.slice(c + 1);
  const form = !a.trim() && !z.trim() ? 'bracket' : 'mixed';
  return { shown: (a + b).trim(), printed: (a + z).trim(), form, a, b, z };
}

// A line with {logic} in it matches if its fixed words appear, in order, in what the game printed.
function dynamicMatcher(body) {
  const pieces = [];
  let depth = 0, cur = '';
  for (const ch of body) {
    if (ch === '{') { if (depth === 0) { pieces.push(cur); cur = ''; } depth++; continue; }
    if (ch === '}') { depth = Math.max(0, depth - 1); continue; }
    if (depth === 0) cur += ch;
  }
  pieces.push(cur);
  const fixed = pieces.map(norm).filter(Boolean);
  if (fixed.join('').length < 12) return null;   // too little fixed text to go on
  const re = new RegExp('^' + pieces.map((p) => norm(p).replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join('.*?') + '$');
  return (text) => re.test(norm(text));
}

// ---------------------------------------------------------------- the source

export class Source {
  constructor(root) {
    this.root = root || ROOT;
    this.files = new Map();   // path -> {lines, dirty}
    const dir = path.join(this.root, 'content', 'ink');
    for (const f of fs.readdirSync(dir).filter((f) => f.endsWith('.ink')).sort()) {
      this.files.set(path.join(dir, f), { lines: fs.readFileSync(path.join(dir, f), 'utf8').split('\n'), dirty: false });
    }
    this.barksFile = path.join(this.root, 'content', 'rules', 'barks.yaml');
    this.index();
  }

  index() {
    this.entries = [];
    for (const [file, f] of this.files) {
      let knot = '', inBlock = false;
      f.lines.forEach((line, i) => {
        if (inBlock) { if (line.includes('*/')) inBlock = false; return; }
        if (/^\s*\/\*/.test(line) && !line.includes('*/')) { inBlock = true; return; }
        const km = /^\s*={2,}\s*(function\s+)?([A-Za-z0-9_]+)/.exec(line);
        if (km) { knot = km[1] ? '' : km[2]; return; }
        const p = parseLine(line);
        if (!p.kind) return;
        const e = { file, i, knot, ...p };
        if (p.kind === 'choice') {
          const cp = choiceParts(p.body);
          e.shown = cp.shown; e.printed = cp.printed; e.form = cp.form;
        }
        this.entries.push(e);
      });
    }
  }

  // Lines the game could have printed as `raw`.
  findLine(raw) {
    const want = norm(raw);
    const out = [];
    for (const e of this.entries) {
      const text = e.kind === 'choice' ? e.printed : e.body;
      if (!text) continue;
      if (!e.dynamic || (e.kind === 'choice' && !/[{}]/.test(text))) {
        if (norm(text) === want) out.push({ e, exact: true });
      } else {
        const m = dynamicMatcher(text);
        if (m && m(want)) out.push({ e, exact: false });
      }
    }
    return out;
  }

  // Choices the game could have offered as `shown`.
  findChoice(shown) {
    const want = norm(shown);
    const out = [];
    for (const e of this.entries) {
      if (e.kind !== 'choice') continue;
      if (!/[{}]/.test(e.shown)) { if (norm(e.shown) === want) out.push({ e, exact: true }); }
      else { const m = dynamicMatcher(e.shown); if (m && m(want)) out.push({ e, exact: false }); }
    }
    return out;
  }

  set(e, text) {
    const f = this.files.get(e.file);
    f.lines[e.i] = text;
    f.dirty = true;
  }

  insertAfter(e, text) {
    const f = this.files.get(e.file);
    f.lines.splice(e.i + 1, 0, text);
    f.dirty = true;
  }

  remove(e) {
    const f = this.files.get(e.file);
    f.lines.splice(e.i, 1);
    f.dirty = true;
  }

  where(e) { return rel(e.file) + ':' + (e.i + 1); }

  write() {
    const changed = [];
    for (const [file, f] of this.files) if (f.dirty) { fs.writeFileSync(file, f.lines.join('\n')); changed.push(rel(file)); f.dirty = false; }
    return changed;
  }
}

// Of several places, the ones in the knot the game said the line came from.
function narrow(cands, edit) {
  if (cands.length <= 1) return cands;
  for (const k of [edit.knot, edit.knot2]) {
    if (!k) continue;
    const here = cands.filter((c) => c.e.knot === k);
    if (here.length) return here;
  }
  return cands;
}

// ---------------------------------------------------------------- applying

export function readEdits(obj) {
  let list = Array.isArray(obj) ? obj : obj && Array.isArray(obj.edits) ? obj.edits : obj && Array.isArray(obj.docs) ? obj.docs : null;
  if (!list) throw new Error('not a file of director edits');
  // the artifact database lists documents as {id, data}
  return list.map((d) => (d && d.data && !d.kind ? { id: d.id, ...d.data } : d)).filter((d) => d && d.id && d.kind);
}

export function merge(edits, src, merged) {
  const res = { applied: [], manual: [], notes: [], prompts: [], skipped: [] };
  const open = edits
    .filter((e) => (e.status === 'draft' || e.status === 'sent') && !(merged && merged[e.id]))
    .sort((a, b) => String(a.created).localeCompare(String(b.created)));
  for (const e of edits) if (!open.includes(e)) res.skipped.push({ id: e.id, kind: e.kind, why: merged && merged[e.id] ? 'already merged' : 'status ' + e.status });
  // a line rewritten in this batch can be the anchor of a line added in it
  const rewritten = new Map();
  for (const e of open) if (e.kind === 'rewrite') rewritten.set(norm(e.orig), rawOf(e.speaker, e.text));

  const hand = (e, why, cands) => res.manual.push({ id: e.id, kind: e.kind, why, places: (cands || []).map((c) => src.where(c.e)), edit: e });

  // inserts first (their anchors are the old words), then the rest in the order Hutch made them
  const order = open.filter((e) => e.kind === 'insert').concat(open.filter((e) => e.kind !== 'insert'));
  for (const e of order) {
    if (e.kind === 'note') { res.notes.push(e); continue; }
    if (e.kind === 'prompt') { res.prompts.push(e); continue; }
    if (e.bark) { applyBark(e, src, res); continue; }
    if (e.kind === 'choice') {
      const cands = narrow(src.findChoice(e.orig), e);
      if (cands.length !== 1) { hand(e, cands.length ? 'the choice matches in more than one place' : 'the choice is not in the Ink as printed', cands); continue; }
      const c = cands[0].e;
      if (!cands[0].exact || c.form === 'mixed') { hand(e, 'the choice is built from logic or split text', cands); continue; }
      const line = src.files.get(c.file).lines[c.i];
      let next;
      if (c.form === 'bracket') {
        const o = c.body.indexOf('['), z = c.body.lastIndexOf(']');
        const inner = c.body.slice(o + 1, z);
        const tags = /\s*#.*$/.exec(inner);
        next = c.lead + c.body.slice(0, o + 1) + e.text + (tags ? tags[0] : '') + c.body.slice(z) + c.tail;
      } else {
        next = c.lead + e.text + c.tail;
      }
      src.set(c, next);
      res.applied.push({ id: e.id, kind: e.kind, at: src.where(c), before: line, after: next });
      src.index();
      continue;
    }
    let anchorRaw = e.orig;
    let cands = narrow(src.findLine(anchorRaw), e);
    if (!cands.length && e.kind === 'insert' && rewritten.has(norm(anchorRaw))) cands = narrow(src.findLine(rewritten.get(norm(anchorRaw))), e);
    if (cands.length !== 1) { hand(e, cands.length ? 'the words match in ' + cands.length + ' places' : 'the line is not in the Ink as printed (built from logic, or changed since)', cands); continue; }
    const c = cands[0].e;
    const line = src.files.get(c.file).lines[c.i];
    if (!cands[0].exact) { hand(e, 'the line is built from logic ({...}), so it needs a hand', cands); continue; }
    if (c.kind === 'choice' && e.kind !== 'insert') { hand(e, 'the line is the printed half of a choice', cands); continue; }
    if (e.kind === 'rewrite') {
      const next = c.lead + rawOf(e.speaker, e.text) + c.tail;
      src.set(c, next);
      res.applied.push({ id: e.id, kind: e.kind, at: src.where(c), before: line, after: next });
    } else if (e.kind === 'cut') {
      const keep = (c.lead.trim() ? c.lead : '') + c.tail.trim();
      if (!keep.trim()) {
        src.remove(c);
        res.applied.push({ id: e.id, kind: e.kind, at: src.where(c), before: line, after: null });
      } else {
        const next = (c.lead.trim() ? c.lead : /^\s*/.exec(c.lead)[0]) + c.tail.trim();
        src.set(c, next);
        res.applied.push({ id: e.id, kind: e.kind, at: src.where(c), before: line, after: next, note: c.tail.includes('#') ? 'its tags now sit on their own line and attach to the next line' : '' });
      }
    } else if (e.kind === 'insert') {
      const indent = /^\s*/.exec(c.lead)[0] + (c.lead.trim() ? '    ' : '');
      const add = rawOf(e.speaker, e.text);
      // a divert at the end of the anchor moves to the end of the new line, so the new line is reached
      const dv = c.tail.indexOf('->');
      const cm = c.tail.indexOf('//');
      if (dv !== -1 && (cm === -1 || dv < cm)) {
        const divert = c.tail.slice(dv).trim();
        const before = c.lead + c.body + c.tail.slice(0, dv).replace(/\s+$/, '');
        src.set(c, before);
        src.insertAfter(c, indent + add + ' ' + divert);
        res.applied.push({ id: e.id, kind: e.kind, at: src.where(c), before: line, after: before + '\n' + indent + add + ' ' + divert });
      } else {
        src.insertAfter(c, indent + add);
        res.applied.push({ id: e.id, kind: e.kind, at: src.where(c), before: line, after: line + '\n' + indent + add });
      }
    }
    src.index();
  }
  return res;
}

// A bark is a line from content/rules/barks.yaml, found by its id.
function applyBark(e, src, res) {
  if (e.kind !== 'rewrite') { res.manual.push({ id: e.id, kind: e.kind, why: 'a ' + e.kind + ' on a bark (barks.yaml ' + e.bark + ') needs a hand', places: [rel(src.barksFile)], edit: e }); return; }
  const lines = (src.barks = src.barks || fs.readFileSync(src.barksFile, 'utf8').split('\n'));
  const start = lines.findIndex((l) => new RegExp('^-\\s+id:\\s*' + e.bark + '\\s*$').test(l));
  if (start === -1) { res.manual.push({ id: e.id, kind: e.kind, why: 'bark ' + e.bark + ' is not in barks.yaml', places: [], edit: e }); return; }
  let i = start + 1;
  while (i < lines.length && !/^-\s/.test(lines[i]) && !/^\s*text:/.test(lines[i])) i++;
  if (i >= lines.length || !/^\s*text:/.test(lines[i])) { res.manual.push({ id: e.id, kind: e.kind, why: 'bark ' + e.bark + ' has no one-line text', places: [rel(src.barksFile) + ':' + (start + 1)], edit: e }); return; }
  const sp = e.speaker && e.speaker !== 'narrator' ? e.speaker : null;
  const before = lines[i];
  const t = String(e.text).replace(/\s+/g, ' ').trim();
  const safe = /^[^'"&*!|>%@`#{\[]/.test(t) && !/:\s|\s#/.test(t) ? t : JSON.stringify(t);
  lines[i] = before.replace(/text:.*$/, 'text: ' + safe);
  if (sp) {
    for (let j = start + 1; j < i; j++) if (/^\s*speaker:/.test(lines[j])) lines[j] = lines[j].replace(/speaker:.*$/, 'speaker: ' + sp);
  }
  src.barksDirty = true;
  res.applied.push({ id: e.id, kind: e.kind, at: rel(src.barksFile) + ':' + (i + 1), before, after: lines[i] });
}

// ---------------------------------------------------------------- the command

function main() {
  const argv = process.argv.slice(2);
  const opt = (n) => { const i = argv.indexOf('--' + n); return i === -1 ? null : (argv[i + 1] && !argv[i + 1].startsWith('--') ? argv[i + 1] : true); };
  const apply = argv.includes('--apply');
  const mergedFile = P('content', 'director', 'merged.json');
  const merged = fs.existsSync(mergedFile) ? JSON.parse(fs.readFileSync(mergedFile, 'utf8')) : {};
  const now = new Date().toISOString();

  if (opt('mark')) {
    const ids = String(opt('mark')).split(',').map((s) => s.trim()).filter(Boolean);
    for (const id of ids) merged[id] = { at: now, by: 'hand', note: typeof opt('note') === 'string' ? opt('note') : '' };
    if (apply) { fs.mkdirSync(path.dirname(mergedFile), { recursive: true }); fs.writeFileSync(mergedFile, JSON.stringify(merged, null, 1) + '\n'); }
    console.log((apply ? 'Marked merged: ' : 'Would mark merged (add --apply): ') + ids.join(', '));
    return;
  }

  const file = argv.find((a) => !a.startsWith('--') && a !== opt('json') && a !== opt('note'));
  if (!file) { console.log('usage: node tools/director.mjs <edits.json> [--apply] [--json out.json]'); process.exit(2); }
  const edits = readEdits(JSON.parse(fs.readFileSync(file, 'utf8')));
  const src = new Source(ROOT);
  const res = merge(edits, src, merged);

  const show = (s) => (s == null ? '(line removed)' : s.trim());
  console.log(`${edits.length} edits read: ${res.applied.length} merge by themselves, ${res.manual.length} need a hand, ${res.notes.length} notes, ${res.prompts.length} prompt answers, ${res.skipped.length} skipped.`);
  if (res.applied.length) {
    console.log('\nMERGED' + (apply ? '' : ' (dry run)'));
    for (const a of res.applied) console.log(`  ${a.id} ${a.kind} at ${a.at}\n    - ${show(a.before)}\n    + ${show(a.after).replace(/\n/g, '\n    + ')}${a.note ? '\n    (' + a.note + ')' : ''}`);
  }
  if (res.manual.length) {
    console.log('\nNEEDS A HAND');
    for (const m of res.manual) console.log(`  ${m.id} ${m.kind}: ${m.why}${m.places.length ? '\n    look at ' + m.places.join(', ') : ''}\n    was: ${norm(m.edit.orig || '')}\n    now: ${m.edit.kind === 'cut' ? '(cut)' : rawOf(m.edit.speaker, m.edit.text)}`);
  }
  if (res.notes.length) {
    console.log('\nNOTES');
    for (const n of res.notes) console.log(`  ${n.id} (${n.knot || 'no scene'}${n.orig ? ', at "' + norm(n.orig).slice(0, 80) + '"' : ''}): ${n.text}`);
  }
  if (res.prompts.length) {
    console.log('\nPROMPT ANSWERS');
    for (const p of res.prompts) console.log(`  ${p.id} ${(p.prompt && p.prompt.loc) || p.knot}: ${(p.prompt && p.prompt.text) || ''}\n    Hutch: ${p.text}`);
  }

  if (apply) {
    const changed = src.write();
    if (src.barksDirty) { fs.writeFileSync(src.barksFile, src.barks.join('\n')); changed.push(rel(src.barksFile)); }
    for (const a of res.applied) merged[a.id] = { at: now, where: a.at };
    fs.mkdirSync(path.dirname(mergedFile), { recursive: true });
    fs.writeFileSync(mergedFile, JSON.stringify(merged, null, 1) + '\n');
    const inbox = P('content', 'director', 'inbox');
    fs.mkdirSync(inbox, { recursive: true });
    fs.writeFileSync(path.join(inbox, now.slice(0, 19).replace(/[:T]/g, '-') + '.json'), JSON.stringify({ receivedAt: now, edits }, null, 1) + '\n');
    console.log(`\nWrote ${changed.join(', ') || 'no Ink changes'}; recorded ${res.applied.length} in content/director/merged.json. Now: node tools/build.mjs && node tools/bots.mjs`);
  }
  const jsonOut = opt('json');
  if (typeof jsonOut === 'string') fs.writeFileSync(jsonOut, JSON.stringify({ at: now, applied: res.applied, manual: res.manual.map(({ edit, ...m }) => m), notes: res.notes.map((n) => n.id), prompts: res.prompts.map((p) => p.id), skipped: res.skipped }, null, 1));
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main();
