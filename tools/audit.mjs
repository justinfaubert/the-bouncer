#!/usr/bin/env node
// The consequence audit: does every choice change something the night reads later?
//
//   node tools/audit.mjs                 the report (choices that change nothing, state nothing reads)
//   node tools/audit.mjs --map           and the whole map, choice by choice, to content/CONSEQUENCES.md
//   node tools/audit.mjs --strict        exit 1 if any choice changes nothing (for the build)
//
// The design's minimum rule (bible/02_SYSTEMS.md): every choice changes something someone says or
// does later. This reads the Ink as written (not the compiled story), choice by choice, and works out
// what each one changes: a VAR or LIST item that something else reads (a condition, a line, a bark or
// a word in content/rules/, the engine), a labelled choice or a stitch whose visit count is read, a
// task in his notes, a check, or a different scene. Time alone (pass()) doesn't count, and neither
// does a line said there and then.
//
// It's a reader's tool, not a proof: it can't follow a function's side effects past the ones listed
// in EFFECTS below, and it takes a divert to a stitch that offers its own choices to be a different
// scene. When it calls a choice inert, read the choice.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const P = (...a) => path.join(ROOT, ...a);
const args = new Set(process.argv.slice(2));

// ---------------------------------------------------------------- the files

const INK_DIR = P('content', 'ink');
const files = [];
(function walk(f) {
  if (files.includes(f)) return;
  files.push(f);
  const src = fs.readFileSync(f, 'utf8');
  for (const m of src.matchAll(/^\s*INCLUDE\s+(.+?)\s*$/gm)) walk(path.resolve(INK_DIR, m[1]));
})(path.join(INK_DIR, 'main.ink'));

const lines = [];   // {file, n, text}
for (const f of files) {
  const src = fs.readFileSync(f, 'utf8').split('\n');
  src.forEach((t, i) => lines.push({ file: path.basename(f), n: i + 1, text: stripComment(t) }));
}

function stripComment(t) {
  // // comments, but not inside a URL; the Ink has none
  const i = t.indexOf('//');
  return i >= 0 ? t.slice(0, i) : t;
}

// other readers of the Ink's state
const rules = ['barks.yaml', 'word.yaml'].map((f) => fs.readFileSync(P('content', 'rules', f), 'utf8')).join('\n');
const engine = ['game.js', 'barks.js', 'psyche.js', 'checks.js'].map((f) => {
  try { return fs.readFileSync(P('prototype', 'web', 'src', 'core', f), 'utf8'); } catch (e) { return ''; }
}).join('\n');
const ui = (() => {
  const dir = P('prototype', 'web', 'src', 'ui');
  try { return fs.readdirSync(dir).map((f) => fs.readFileSync(path.join(dir, f), 'utf8')).join('\n'); } catch (e) { return ''; }
})();
const godot = (() => {
  const out = [];
  for (const d of ['game', 'world', 'engine']) {
    const dir = P('godot', d);
    try { for (const f of fs.readdirSync(dir)) if (f.endsWith('.gd')) out.push(fs.readFileSync(path.join(dir, f), 'utf8')); } catch (e) { /* none */ }
  }
  return out.join('\n');
})();

// ---------------------------------------------------------------- names

const vars = new Map();      // name -> {list: bool, items?}
const items = new Map();     // list item -> list name
const knots = new Map();     // knot -> {file, n, fn: bool}
const stitches = new Map();  // "knot.stitch" -> {file, n}
const labels = new Map();    // "knot.stitch.label" or "knot.label" -> {file, n, kind}

{
  let knot = '', stitch = '';
  for (const L of lines) {
    const t = L.text;
    let m;
    if ((m = t.match(/^\s*VAR\s+([A-Za-z_]\w*)\s*=/))) vars.set(m[1], { list: false });
    else if ((m = t.match(/^\s*CONST\s+([A-Za-z_]\w*)\s*=/))) vars.set(m[1], { list: false, constant: true });
    else if ((m = t.match(/^\s*LIST\s+([A-Za-z_]\w*)\s*=\s*(.*)$/))) {
      const its = m[2].split(',').map((s) => s.replace(/[()]/g, '').replace(/=\s*\d+/, '').trim()).filter(Boolean);
      vars.set(m[1], { list: true, items: its });
      for (const it of its) items.set(it, m[1]);
    } else if ((m = t.match(/^\s*===\s*(function\s+)?([A-Za-z_]\w*)/))) {
      knot = m[2]; stitch = '';
      knots.set(knot, { file: L.file, n: L.n, fn: !!m[1] });
    } else if ((m = t.match(/^\s*=\s*([A-Za-z_]\w*)/)) && !t.match(/^\s*==/)) {
      stitch = m[1];
      stitches.set(knot + '.' + stitch, { file: L.file, n: L.n });
    }
    L.knot = knot; L.stitch = stitch;
    const lab = t.match(/^\s*(?:[*+]\s*)+\(([A-Za-z_]\w*)\)/) || t.match(/^\s*(?:-\s*)+\(([A-Za-z_]\w*)\)/);
    if (lab) labels.set(lab[1], { file: L.file, n: L.n, knot, stitch, kind: /^\s*[*+]/.test(t) ? 'choice' : 'gather' });
  }
}

// ---------------------------------------------------------------- reads and writes of state

// side effects of the Ink's own functions that the audit can see through
const EFFECTS = {
  'drink': ['drinks', 'incident:inc_drinking'],
  'tip': ['cash'],
  'heat': ['pool_heat', 'heat()'],   // the clock heats the pool table too, but a choice that does it on purpose has a consequence
  'go_to_war': ['rats'],
  'pass': [],
  'seat': ['psyche'],
  'unseat': ['psyche'],
  'learn': ['psyche'],
  'bond': ['psyche'],
};
const TIME = new Set(['clock', 'door_away', 'walk_ins', 'uncounted', 'room_count', 't28_rounds', 'pool_heat', 'pool_mins', 'last_room_line']);

function writesOf(t) {
  // what a line of Ink writes: ["var", "list:item", ...]
  const out = [];
  let m;
  const stmt = t.match(/^\s*(?:-\s*)*~\s*(.*)$/);
  if (stmt) {
    const s = stmt[1];
    if ((m = s.match(/^(?:temp\s+)?([A-Za-z_]\w*)\s*(\+\+|--|\+=|-=|=)\s*(.*)$/)) && !s.startsWith('temp')) {
      const v = m[1];
      const its = m[3].replace(/[()]/g, '').split(/[,\s]+/).filter((it) => items.has(it));
      if (vars.has(v) && (m[2] === '+=' || m[2] === '-=') && its.length) {
        for (const it of its) out.push(v + ':' + it + (m[2] === '-=' ? ':-' : ''));
      } else if (vars.has(v)) out.push(v);
    }
    for (const call of s.matchAll(/([A-Za-z_]\w*)\s*\(([^)]*)\)/g)) {
      const fn = call[1];
      if (fn === 'rep') {
        const v = call[2].split(',')[0].trim();
        const n = Number(call[2].split(',')[1]);
        if (n !== 0) out.push(v);
      } else if (fn === 'move') {
        // move(ref who, to): who stands where (sim.ink)
        const [v, to] = call[2].split(',').map((x) => x.trim());
        if (vars.has(v)) out.push(v);
        if (items.has(to)) out.push(items.get(to) + ':' + to);
      } else if (EFFECTS[fn]) out.push(...EFFECTS[fn]);
    }
  }
  return out;
}

// every place an identifier is read in the Ink: anywhere but the left of an assignment
const reads = new Map();     // id -> [{file, n}]
function addRead(id, L) {
  if (!reads.has(id)) reads.set(id, []);
  reads.get(id).push(L ? { file: L.file, n: L.n } : { file: 'rules' });
}
for (const L of lines) {
  let t = L.text;
  if (/^\s*(VAR|CONST|LIST)\s/.test(t)) continue;
  const stmt = t.match(/^\s*(?:-\s*)*~\s*(?:temp\s+\w+\s*=\s*)?(.*)$/);
  if (stmt) {
    // the right-hand side, and any function arguments, are reads
    let s = stmt[1];
    const asg = s.match(/^([A-Za-z_]\w*)\s*(\+\+|--|\+=|-=|=)\s*(.*)$/);
    if (asg) {
      if (asg[2] === '+=' && vars.get(asg[1])?.list) s = '';            // adding to a list doesn't read it
      else if (asg[2] === '=' ) s = asg[3];
      else if (asg[2] === '+=' || asg[2] === '-=') s = asg[3];
      else s = '';
    }
    for (const id of s.matchAll(/[A-Za-z_][\w.]*/g)) mark(id[0], L, s);
    continue;
  }
  // the condition (or expression) at the head of every {...} on a line is a read
  for (const head of braceHeads(t)) for (const id of head.matchAll(/[A-Za-z_][\w.]*/g)) mark(id[0], L, head);
  // multi-line conditions: "{ cond:" opening, or "- cond:" inside a block
  const open = t.match(/^\s*\{\s*([^{}]*):\s*$/) || t.match(/^\s*-\s*([^:{}]+):\s*/);
  if (open) for (const id of open[1].matchAll(/[A-Za-z_][\w.]*/g)) mark(id[0], L, open[1]);
  // functions return values that are reads
  const ret = t.match(/^\s*~\s*return\s+(.*)$/);
  if (ret) for (const id of ret[1].matchAll(/[A-Za-z_][\w.]*/g)) mark(id[0], L, ret[1]);
}
// the head of each {...}: up to its first top-level ':' or '|' (or all of it, for a printed value)
function braceHeads(t) {
  const heads = [];
  const stack = [];
  for (let i = 0; i < t.length; i++) {
    const c = t[i];
    if (c === '{') stack.push({ start: i + 1, head: null });
    else if (c === '|' && (t[i + 1] === '|' || t[i - 1] === '|')) continue;
    else if ((c === ':' || c === '|') && stack.length && stack[stack.length - 1].head === null) {
      const top = stack[stack.length - 1];
      top.head = t.slice(top.start, i);
    } else if (c === '}' && stack.length) {
      const top = stack.pop();
      heads.push(top.head === null ? t.slice(top.start, i) : top.head);
    }
  }
  for (const top of stack) heads.push(top.head === null ? t.slice(top.start) : top.head);
  return heads.filter((h) => !/^\s*(shuffle|stopping|once|cycle)\s*$/.test(h));
}
function mark(id, L, ctx) {
  const parts = id.split('.');
  addRead(id, L);
  if (parts.length > 1) addRead(parts[parts.length - 1], L);
}
// the rules read state by name (when: criteria), and the engines read a few by name
for (const [id] of [...vars, ...items]) {
  const re = new RegExp('\\b' + id + '\\b');
  if (re.test(rules)) addRead(id, null);
  if (new RegExp("['\"]" + id + "['\"]").test(engine) || new RegExp("['\"]" + id + "['\"]").test(ui) || new RegExp("\"" + id + "\"").test(godot)) addRead(id, { file: 'engine' });
}

const isRead = (id) => (reads.get(id) || []).length > 0;

// a write is live when something reads what it wrote: the VAR, or for a list, that item or the list as a whole
function live(w) {
  const [v, it] = w.split(':');
  if (v === 'psyche' || v === 'heat()') return true;
  if (it) return isRead(it) || listReadWhole(v);
  return isRead(v);
}
const wholeListReads = new Set();
for (const L of lines) {
  for (const m of L.text.matchAll(/LIST_COUNT\(\s*\(?([A-Za-z_]\w*)/g)) wholeListReads.add(m[1]);
  for (const m of L.text.matchAll(/LIST_MIN\(\s*([A-Za-z_]\w*)/g)) wholeListReads.add(m[1]);
  for (const m of L.text.matchAll(/temp\s+\w+\s*=\s*([A-Za-z_]\w*)\s*-/g)) wholeListReads.add(m[1]);
  for (const m of L.text.matchAll(/\(\s*([A-Za-z_]\w*)\s*\+\s*[A-Za-z_]\w*\s*\)\s*\^/g)) wholeListReads.add(m[1]);
}
function listReadWhole(v) { return wholeListReads.has(v); }

// ---------------------------------------------------------------- choices

const choices = [];
{
  let depth = 0;    // multi-line { } depth
  for (let i = 0; i < lines.length; i++) {
    const L = lines[i];
    const t = L.text;
    const cm = t.match(/^(\s*)((?:[*+]\s*)+)(.*)$/);
    if (cm && depth >= 0) {
      const level = (cm[2].match(/[*+]/g) || []).length;
      const sticky = cm[2].trim().startsWith('+');
      const rest = cm[3];
      const label = (rest.match(/^\(([A-Za-z_]\w*)\)/) || [])[1] || '';
      const words = (rest.match(/\[([^\]]*)\]/) || [, rest.replace(/^\([^)]*\)\s*/, '').replace(/\{[^}]*\}\s*/g, '')])[1];
      const tags = words.match(/#.*/) ? words.slice(words.indexOf('#')) : '';
      const text = words.replace(/#.*$/, '').trim();
      // the body: until a choice or gather at this level or above, a knot or stitch, or the end of the block it's in
      const body = [];
      let d = 0;
      let j = i + 1;
      // the line itself can carry content after the brackets
      const after = rest.replace(/^\([^)]*\)\s*/, '').replace(/^(\{[^}]*\}\s*)*/, '').replace(/\[[^\]]*\]/, '');
      if (after.trim()) body.push({ ...L, text: after });
      for (; j < lines.length; j++) {
        const u = lines[j].text;
        if (/^\s*===?\s*[A-Za-z_]/.test(u) && !/^\s*==?\s*$/.test(u)) break;
        if (d === 0) {
          const c2 = u.match(/^\s*((?:[*+]\s*)+)/);
          if (c2 && (c2[1].match(/[*+]/g) || []).length <= level) break;
          const g2 = u.match(/^\s*((?:-\s*)+)(?!>)/);
          if (g2 && !/^\s*-\s*>/.test(u) && (g2[1].match(/-/g) || []).length <= level) break;
        }
        const opens = (u.match(/\{/g) || []).length;
        const closes = (u.match(/\}/g) || []).length;
        if (d + opens - closes < 0) break;          // the block the choice is in has closed
        d += opens - closes;
        body.push(lines[j]);
      }
      const ch = { file: L.file, n: L.n, knot: L.knot, stitch: L.stitch, level, sticky, label, text, tags, body, sub: false };
      // nested choices inside the body
      ch.sub = body.some((b) => /^\s*(?:[*+]\s*){2,}/.test(b.text) && ((b.text.match(/^\s*((?:[*+]\s*)+)/)[1].match(/[*+]/g) || []).length > level));
      choices.push(ch);
    }
    const opens = (t.match(/\{/g) || []).length;
    const closes = (t.match(/\}/g) || []).length;
    depth += opens - closes;
    if (/^\s*===?\s*[A-Za-z_]/.test(t)) depth = 0;
  }
}

// what a choice changes
const MENUS = new Set(['hub', 'DONE', 'END']);
for (const ch of choices) {
  const w = [];
  const dv = [];
  const said = [];
  let check = (ch.tags.match(/#check:\s*([a-z]+)\s+(\d+)/) || []);
  for (const b of ch.body) {
    // stop at nested choices: they're their own entries
    if (/^\s*(?:[*+]\s*){2,}/.test(b.text) && ch.level === 1) break;
    w.push(...writesOf(b.text));
    for (const m of b.text.matchAll(/->\s*([A-Za-z_][\w.]*)/g)) dv.push(m[1]);
    if (/#\s*task:|#\s*done:/.test(b.text)) w.push('task');
    if (/^\s*[A-Z][A-Z0-9_]+:/.test(b.text)) said.push(b.text.trim());
  }
  ch.writes = [...new Set(w)];
  ch.live = ch.writes.filter((x) => x === 'task' || live(x));
  ch.dead = ch.writes.filter((x) => x !== 'task' && !live(x));
  ch.diverts = [...new Set(dv)];
  ch.check = check.length ? check[1] + ' ' + check[2] : '';
  ch.labelRead = ch.label ? isRead(ch.label) || isRead(ch.stitch ? ch.knot + '.' + ch.stitch + '.' + ch.label : ch.knot + '.' + ch.label) : false;
  // a divert to another scene: a knot or stitch that isn't the menu the choice came from
  const home = new Set([ch.stitch, ch.knot, ...labelsIn(ch.knot)]);
  ch.scene = ch.diverts.filter((d) => !MENUS.has(d) && !home.has(d.split('.').pop()) && !d.endsWith('_opts') && d !== 'opts');
  ch.timeOnly = ch.writes.every((x) => TIME.has(x)) && !ch.live.some((x) => !TIME.has(x));
  ch.inert = !ch.sub && !ch.check && !ch.labelRead && ch.scene.length === 0 && ch.live.filter((x) => !TIME.has(x)).length === 0;
}
function labelsIn(knot) {
  const out = [];
  for (const [name, l] of labels) if (l.knot === knot) out.push(name);
  return out;
}

// ---------------------------------------------------------------- state nobody reads, and reads nobody writes

const writtenAnywhere = new Set();
for (const L of lines) for (const x of writesOf(L.text)) writtenAnywhere.add(x.split(':')[0]), x.includes(':') && writtenAnywhere.add(x.split(':')[1]);
const deadState = [];
for (const [v, def] of vars) {
  if (def.constant) continue;
  if (def.list) {
    for (const it of def.items) if (writtenAnywhere.has(it) && !isRead(it) && !listReadWhole(v)) deadState.push(v + ' ? ' + it);
  } else if (writtenAnywhere.has(v) && !isRead(v)) deadState.push(v);
}
const neverWritten = [];
const ENGINE_SET = new Set(['day', 'passed', 'crit']);   // the engine sets these (game.js, checks.js)
for (const [v, def] of vars) {
  if (def.constant || def.list || ENGINE_SET.has(v)) continue;
  if (!writtenAnywhere.has(v) && isRead(v)) neverWritten.push(v);
}
for (const [it, v] of items) {
  if (isRead(it) && !writtenAnywhere.has(it) && v !== 'where' && v !== 'rat_way') neverWritten.push(v + ' ? ' + it);
}

// ---------------------------------------------------------------- the report

// Ways out: leaving a place or a conversation and going back to the room. What they change is the
// clock, and the clock is the night's (sim.ink): whatever he isn't attending to happens without him.
const WAY_OUT = /^(The floor|That's enough|Leave (him|her|them) to|Out of the|Go back( in)?\.?$|Get up|Never mind)/;
const waysOut = choices.filter((c) => c.inert && WAY_OUT.test(c.text) && c.scene.length === 0);
const inert = choices.filter((c) => c.inert && !waysOut.includes(c));
const weak = choices.filter((c) => !c.inert && !c.sub && !c.check && !c.labelRead && c.scene.length === 0 && c.dead.length > 0 && c.live.filter((x) => !TIME.has(x)).length === 0);

const where = (c) => `${c.file}:${c.n}`;
const out = [];
out.push(`The consequence audit: ${choices.length} choices in ${files.length} files.`);
out.push('');
out.push(`Choices that change nothing the night reads later (${inert.length}):`);
for (const c of inert) out.push(`  ${where(c).padEnd(18)} ${c.knot}${c.stitch ? '.' + c.stitch : ''}  [${c.text}]${c.writes.length ? '  (writes ' + c.writes.join(', ') + ')' : ''}`);
out.push('');
out.push(`Ways out, which change only the clock (${waysOut.length}): ${waysOut.map((c) => '[' + c.text + ']').join(' ') || 'none'}`);
out.push('');
out.push(`Choices whose only changes nobody reads (${weak.length}):`);
for (const c of weak) out.push(`  ${where(c).padEnd(18)} [${c.text}]  writes ${c.dead.join(', ')}`);
out.push('');
out.push(`State written but never read (${deadState.length}): ${deadState.join(', ') || 'none'}`);
out.push(`State read but never written (${neverWritten.length}): ${neverWritten.join(', ') || 'none'}`);
console.log(out.join('\n'));

if (args.has('--map')) {
  const md = [];
  md.push('# What every choice changes');
  md.push('');
  md.push('Written by `node tools/audit.mjs --map` from the Ink. Each choice, where it is, and what it changes that the night reads later: state (a VAR, or a LIST item), a labelled choice whose visit count is read, a task in his notes, a check, or a different scene. "time" is pass() and what the clock moves with it. Nothing here is hand-written; rebuild it after changing the Ink.');
  md.push('');
  let lastFile = '';
  for (const c of choices) {
    if (c.file !== lastFile) { md.push('', '## ' + c.file, '', '| Line | Where | Choice | Changes |', '|---|---|---|---|'); lastFile = c.file; }
    const bits = [];
    if (c.check) bits.push('check ' + c.check);
    if (c.sub) bits.push('more choices');
    if (c.scene.length) bits.push('to ' + c.scene.join(', '));
    const lv = c.live.filter((x) => !TIME.has(x));
    if (lv.length) bits.push(lv.join(', '));
    if (c.labelRead) bits.push('(' + c.label + ') is read');
    if (!bits.length && waysOut.includes(c)) bits.push('a way out: the clock');
    if (!bits.length) bits.push(c.writes.some((x) => TIME.has(x)) || c.body.some((b) => /pass\(/.test(b.text)) ? '**time only**' : '**nothing**');
    md.push(`| ${c.n} | ${c.knot}${c.stitch ? '.' + c.stitch : ''} | ${c.text.replace(/\|/g, '/') || '(fallback)'} | ${bits.join('; ').replace(/\|/g, '/')} |`);
  }
  fs.writeFileSync(P('content', 'CONSEQUENCES.md'), md.join('\n') + '\n');
  console.log('\nWrote content/CONSEQUENCES.md');
}

if (args.has('--strict') && inert.length) process.exit(1);
