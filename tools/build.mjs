#!/usr/bin/env node
// Build the game's content.
//
//   node tools/build.mjs          compile the Ink, load the YAML data, validate it all,
//                                 list the writing prompts, and write the bundle the
//                                 browser build loads (prototype/web/content.js)
//   node tools/build.mjs --offline
//                                 also write releases/The-Bouncer-<build>.html: the whole game
//                                 in one file (fonts, art and sound inlined) that plays from a
//                                 hard drive with a double-click, no server and no network
//   node tools/build.mjs --dist   also assemble prototype/web/dist/, a self-contained copy
//                                 for publishing (index.html for local use, artifact.html
//                                 for the claude.ai Artifact). Implies --offline: the offline
//                                 file rides along as dist/offline/The-Bouncer.html, which the
//                                 game offers as "Save a copy to play offline".
//
// content/director/merged.json lists the director's edits already merged into the Ink
// (tools/director.mjs writes it); the game stops laying those over the story.
//
// No npm install needed: the Ink compiler and the YAML parser are vendored in tools/vendor/.

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { load as loadYaml } from './vendor/js-yaml.mjs';

const require = createRequire(import.meta.url);
const inkjs = require('./vendor/ink-full.js');

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const P = (...a) => path.join(ROOT, ...a);
const rel = (f) => path.relative(ROOT, f);
const args = new Set(process.argv.slice(2));

const problems = { errors: [], warnings: [] };
const err = (m) => problems.errors.push(m);
const warn = (m) => problems.warnings.push(m);

// ---------------------------------------------------------------- Ink

const INK_DIR = P('content', 'ink');
const INK_MAIN = path.join(INK_DIR, 'main.ink');

function inkFiles(entry) {
  // main.ink plus everything it INCLUDEs, in order
  const seen = [];
  (function walk(f) {
    if (seen.includes(f)) return;
    seen.push(f);
    const src = fs.readFileSync(f, 'utf8');
    for (const m of src.matchAll(/^\s*INCLUDE\s+(.+?)\s*$/gm)) walk(path.resolve(path.dirname(f), m[1]));
  })(entry);
  return seen;
}

function compileInk() {
  const fileHandler = {
    ResolveInkFilename: (name) => path.resolve(INK_DIR, name),
    LoadInkFileContents: (full) => fs.readFileSync(full, 'utf8'),
  };
  const messages = [];
  const opts = new inkjs.CompilerOptions(INK_MAIN, [], true, (msg, type) => messages.push({ msg, type }), fileHandler);
  const compiler = new inkjs.Compiler(fs.readFileSync(INK_MAIN, 'utf8'), opts);
  let story = null;
  try {
    story = compiler.Compile();
  } catch (e) {
    if (!messages.length) messages.push({ msg: 'Compiler crashed: ' + (e && e.message || e), type: 2 });
  }
  for (const { msg, type } of messages) {
    if (type === 2) err('ink: ' + msg);
    else if (type === 1) warn('ink: ' + msg);
  }
  if (!story || problems.errors.length) return null;
  return JSON.parse(story.ToJson());
}

// ---------------------------------------------------------------- YAML

function yaml(file, fallback) {
  const f = P(file);
  if (!fs.existsSync(f)) { warn('missing ' + file); return fallback; }
  try { return loadYaml(fs.readFileSync(f, 'utf8')) ?? fallback; } catch (e) { err(file + ': ' + e.message); return fallback; }
}

// ---------------------------------------------------------------- scan the Ink source

function scanInk(files) {
  const speakers = new Map();   // LABEL -> [loc]
  const checks = [];            // {voice, stat, loc}
  const fx = [];                // {type, id, loc}
  const prompts = [];           // {text, loc, knot, kind}
  const words = { total: 0, byFile: {} };
  const knots = [];             // "knot" and "knot.stitch", not functions
  const markRefs = [];          // {spec, loc}: #mark: tags
  const propRefs = [];          // {id, loc}: #prop: tags
  const toyRefs = [];           // {id, what, loc}: #toy: tags on choices
  const readRefs = [];          // {voice, thing, loc}: #read: tags on choices
  for (const f of files) {
    const lines = fs.readFileSync(f, 'utf8').split('\n');
    let knot = '(top)';
    let inBlockComment = false;
    let w = 0;
    lines.forEach((line, i) => {
      const loc = rel(f) + ':' + (i + 1);
      if (inBlockComment) { if (line.includes('*/')) inBlockComment = false; return; }
      if (/^\s*\/\*/.test(line) && !line.includes('*/')) { inBlockComment = true; return; }
      const km = /^\s*={2,}\s*(function\s+)?([A-Za-z0-9_]+)/.exec(line);
      if (km) { knot = km[2]; if (!km[1]) knots.push(knot); }
      const stm = /^\s*=\s*([A-Za-z0-9_]+)\s*$/.exec(line);
      if (stm && !km) knots.push(knot + '.' + stm[1]);
      const hutch = /(?<!`)\/\/\s*HUTCH:\s*(.+)$/.exec(line);   // not one quoted in `backticks`
      if (hutch) prompts.push({ kind: 'comment', text: hutch[1].trim(), loc, knot });
      const code = line.replace(/\/\/.*$/, '');
      for (const m of code.matchAll(/#\s*prompt:\s*([^#]+)/g)) prompts.push({ kind: 'tag', text: m[1].trim(), loc, knot });
      for (const m of code.matchAll(/#\s*check:\s*([a-z_]+)(?::([a-z_]*))?/gi)) checks.push({ voice: m[1].toLowerCase(), stat: m[2] === undefined ? null : m[2].toLowerCase(), loc });
      for (const m of code.matchAll(/#\s*mark:\s*([^#]+)/gi)) markRefs.push({ spec: m[1].trim(), loc });
      for (const m of code.matchAll(/#\s*prop:\s*([^#\s\]]*)/gi)) propRefs.push({ id: m[1], loc });
      for (const m of code.matchAll(/#\s*toy:\s*([^#\]]*)/gi)) { const w = m[1].trim().split(/\s+/); toyRefs.push({ id: w[0] || '', what: w[1] || '', loc }); }
      for (const m of code.matchAll(/#\s*read:\s*([^#\]]*)/gi)) { const w = m[1].trim().split(/\s+/); readRefs.push({ voice: (w[0] || '').toLowerCase(), thing: w[1] || '', loc }); }
      for (const m of code.matchAll(/#\s*(sfx|music|amb|portrait):\s*([a-z0-9_]+)/gi)) fx.push({ type: m[1].toLowerCase(), id: m[2], loc });
      // a speaker label at the start of a content line (after choice bullets / gathers)
      const body = code.replace(/^\s*(?:[*+\-]\s*)*(?:\([a-z0-9_]+\)\s*)?(?:\{[^}]*:\s*)?/i, '');
      const sm = /^([A-Z][A-Z0-9_]*):\s+\S/.exec(body);
      if (sm) {
        if (!speakers.has(sm[1])) speakers.set(sm[1], []);
        speakers.get(sm[1]).push(loc);
      }
      if (!/^\s*(~|VAR|CONST|LIST|INCLUDE|EXTERNAL|={2,}|->)/.test(code)) {
        const plain = code.replace(/#[^#]*/g, '').replace(/\{[^}]*\}/g, ' ').replace(/[\[\]*+\-]/g, ' ');
        w += (plain.match(/[A-Za-z']+/g) || []).length;
      }
    });
    words.byFile[rel(f)] = w;
    words.total += w;
  }
  return { speakers, checks, fx, prompts, words, knots, markRefs, propRefs, toyRefs, readRefs };
}

// ---------------------------------------------------------------- main

const files = inkFiles(INK_MAIN);
const story = compileInk();

const voices = yaml('content/data/voices.yaml', {});
const characters = yaml('content/data/characters.yaml', {});
const assets = yaml('content/data/assets.yaml', {});
const barks = yaml('content/rules/barks.yaml', []);
const word = yaml('content/rules/word.yaml', {});
const marks = yaml('content/data/marks.yaml', {});
const props = yaml('content/data/props.yaml', {});
const things = yaml('content/data/things.yaml', {});
const psycheAll = JSON.parse(fs.readFileSync(P('data', 'psyche_states.json'), 'utf8'));
const psyche = {
  classes: psycheAll.classes.map((c) => ({ class: c.class, tension: c.tension, states: c.states, share: c.share, mirror: c.mirror })),
  states: psycheAll.states.map((s) => ({ id: s.id, class: s.class, tension: s.tension, conflicts: s.conflicts, mirror: s.mirror, note: s.note || '' })),
};

const scan = scanInk(files);
const mergedFile = P('content', 'director', 'merged.json');
let merged = [];
if (fs.existsSync(mergedFile)) {
  try { merged = Object.keys(JSON.parse(fs.readFileSync(mergedFile, 'utf8'))); } catch (e) { err('content/director/merged.json: ' + e.message); }
}

// Validate speakers, checks, effects, barks against the data.
const voiceIds = new Set(Object.keys(voices || {}));
const charIds = new Set(Object.keys(characters || {}));
for (const id of voiceIds) if (charIds.has(id)) err(`id "${id}" is both a voice and a character`);
for (const [label, locs] of scan.speakers) {
  const id = label.toLowerCase();
  if (label === 'NARRATOR' || voiceIds.has(id) || charIds.has(id)) continue;
  if (label.length <= 2) continue;
  warn(`speaker ${label} is not in voices.yaml or characters.yaml (${locs[0]}${locs.length > 1 ? ' and ' + (locs.length - 1) + ' more' : ''}); it will show as plain narration`);
}
// His seven stats (prototype/web/src/core/checks.js): a check rolls on the one it names after the
// voice ("#check: father:cha 12"), or on the voice's first.
const STAT_KEYS = ['str', 'con', 'dex', 'int', 'wis', 'cha', 'gut'];
for (const [id, v] of Object.entries(voices || {})) {
  if (!v || v.whose) continue;
  const st = v.stats;
  if (!Array.isArray(st) || !st.length) err(`voices.yaml: ${id} lends no stats (stats: [...])`);
  else for (const k of st) if (!STAT_KEYS.includes(k)) err(`voices.yaml: ${id} lends to "${k}", which isn't one of his seven (${STAT_KEYS.join(' ')})`);
}
for (const c of scan.checks) {
  if (!voiceIds.has(c.voice)) err(`check by unknown voice "${c.voice}" at ${c.loc}`);
  else if (voices[c.voice].whose) err(`check by ${c.voice} at ${c.loc}, whose voice is ${voices[c.voice].whose}'s, not his`);
  if (c.stat !== null && !STAT_KEYS.includes(c.stat)) err(`check at ${c.loc} rolls on "${c.stat}", which isn't one of his seven (${STAT_KEYS.join(' ')})`);
}
const assetIndex = { sfx: assets.sfx || {}, music: assets.music || {}, amb: assets.ambience || {}, portrait: assets.portraits || {} };
for (const f of scan.fx) if (f.id !== 'none' && (!assetIndex[f.type] || !assetIndex[f.type][f.id])) warn(`${f.type} "${f.id}" is not in assets.yaml (${f.loc})`);
// Which slots have their file yet. The game uses a file only when it's marked present, so a
// missing file means the placeholder, never a broken request.
const assetFiles = [];
for (const group of Object.values(assetIndex)) {
  for (const [id, slot] of Object.entries(group)) {
    if (!slot || !slot.file) continue;
    slot.present = fs.existsSync(P(slot.file));
    if (slot.present) assetFiles.push(slot.file);
  }
}

let inkGlobals = [];
if (story) {
  const g = new inkjs.Story(story);
  inkGlobals = Array.from(g.variablesState._globalVariables.keys());
  for (const need of ['clock', 'cash', 'drinks', 'count_in', 'hurt', 'here', 'passed', 'crit', 'day', 'ate', 'stats_set', 'stat_str', 'stat_con', 'stat_dex', 'stat_int', 'stat_wis', 'stat_cha', 'stat_gut']) {
    if (!inkGlobals.includes(need)) err(`the engine reads VAR ${need}, but the Ink doesn't declare it`);
  }
}
if (globalThis.Bouncer === undefined) {
  require(P('prototype', 'web', 'src', 'core', 'util.js'));
  require(P('prototype', 'web', 'src', 'core', 'barks.js'));
}
const B = globalThis.Bouncer;
const barkSet = new B.Barks(barks || []);
for (const bad of barkSet.badCriteria()) err('barks.yaml: cannot read criterion ' + bad);
for (const v of barkSet.variables()) if (story && !inkGlobals.includes(v)) err(`barks.yaml uses "${v}", which is not an Ink VAR`);
for (const r of barkSet.rules) {
  if (!voiceIds.has(r.speaker)) err(`barks.yaml: ${r.id} is spoken by "${r.speaker}", which is not a voice`);
  if (!r.on) err(`barks.yaml: ${r.id} has no "on" event`);
  if (!r.text) err(`barks.yaml: ${r.id} has no text`);
}
// Marks: every spot a line marks is on a picture, and every spot has somewhere to show and something to draw
const SHAPES = { ring: 4, box: 4, line: 4, arrow: 4, cross: 3, tally: 3 };
for (const [place, spots] of Object.entries(marks || {})) {
  for (const [id, sp] of Object.entries(spots || {})) {
    const at = place + '.' + id;
    if (!Array.isArray(sp.crop) || sp.crop.length !== 4) err(`marks.yaml: ${at} needs crop: [x, y, w, h]`);
    const shapes = Object.keys(sp).filter((k) => SHAPES[k]);
    if (!shapes.length) err(`marks.yaml: ${at} has nothing to draw (ring, box, line, arrow, cross or tally)`);
    for (const k of shapes) if (!Array.isArray(sp[k]) || sp[k].length !== SHAPES[k]) err(`marks.yaml: ${at} ${k} needs ${SHAPES[k]} numbers`);
  }
}
const checkMark = (spec, where) => {
  for (const part of String(spec).split(';')) {
    const at = part.trim().split(/\s+/)[0];
    if (!at) continue;
    const [place, id] = at.split('.');
    if (!marks || !marks[place] || !marks[place][id]) err(`${where} marks "${at}", which is not a spot in marks.yaml`);
  }
};
for (const r of barkSet.rules) if (r.mark) checkMark(r.mark, 'barks.yaml: ' + r.id);
for (const m of scan.markRefs) checkMark(m.spec, m.loc);
// Props: every thing a line hands over is in props.yaml, and every choice that waits for a thing
// waits for something it can be done with (src/ui/props.js)
const PROP_KINDS = { card: ['flip', 'tilt', 'look'], phone: ['look', 'swipe'], binder: ['page', 'all'], body: ['walk', 'ran'], thing: ['turn', 'look'] };
// what a thing (kind: thing) can be made as, in the Godot build's hands and on the browser's page
const THING_SHAPES = ['flashlight', 'key', 'shirt', 'bill', 'straw', 'keys', 'glass', 'bag', 'mat', 'tickets', 'book', 'jacket'];
const propThings = Object.entries(props || {}).filter(([id]) => id !== 'tonight');
if (props && props.tonight && isNaN(Date.parse(props.tonight))) err(`props.yaml: tonight "${props.tonight}" isn't a date (YYYY-MM-DD)`);
for (const [id, pr] of propThings) {
  if (!pr || !PROP_KINDS[pr.kind]) { err(`props.yaml: ${id} needs a kind (${Object.keys(PROP_KINDS).join(', ')})`); continue; }
  if (pr.kind === 'card') {
    // a driver's licence carries a name, a birthday and a class; a security worker's licence (type:
    // security) a role and an expiry, and the name is never printed (it's Hutch's)
    const need = pr.type === 'security' ? ['role', 'expires', 'number'] : ['surname', 'given', 'born', 'class'];
    for (const k of need) if (!pr[k]) err(`props.yaml: ${id} (a card) has no ${k}`);
    if (pr.type && pr.type !== 'security') err(`props.yaml: ${id} has type "${pr.type}"; a card is a driver's licence, or type: security`);
    if (pr.born && isNaN(Date.parse(pr.born))) err(`props.yaml: ${id} born "${pr.born}" isn't a date`);
    if (pr.face && !charIds.has(pr.face)) err(`props.yaml: ${id} shows the face of "${pr.face}", who isn't in characters.yaml`);
  }
  if (pr.kind === 'phone' && (!Array.isArray(pr.photos) || !pr.photos.length)) err(`props.yaml: ${id} (a phone) has no photos`);
  if (pr.kind === 'thing') {
    if (!THING_SHAPES.includes(pr.shape)) err(`props.yaml: ${id} (a thing) needs a shape (${THING_SHAPES.join(', ')})`);
    if (!pr.name) err(`props.yaml: ${id} (a thing) has no name`);
    for (const side of ['front', 'back']) if (pr[side] !== undefined && !Array.isArray(pr[side])) err(`props.yaml: ${id}'s ${side} should be a list of lines`);
  }
  if (pr.kind === 'binder') {
    if (!(pr.pages > 0)) err(`props.yaml: ${id} (a binder) needs pages: <how many>`);
    for (const [n, pg] of Object.entries(pr.sleeves || {})) {
      if (!(+n >= 1 && +n <= pr.pages)) err(`props.yaml: ${id} sleeve ${n} is past the last page`);
      if (pg && pg.card && !(props[pg.card] && props[pg.card].kind === 'card')) err(`props.yaml: ${id} sleeve ${n} copies card "${pg.card}", which isn't a card`);
      if (pg && pg.face && !charIds.has(pg.face)) err(`props.yaml: ${id} sleeve ${n} shows "${pg.face}", who isn't in characters.yaml`);
    }
  }
}
for (const r of scan.propRefs) if (!props || !props[r.id] || r.id === 'tonight') err(`#prop: "${r.id}" at ${r.loc} is not in props.yaml`);
// Reads (content/ink/hand.ink): a voice of his, reading a thing he can hold, and one read a voice a thing
const readSeen = new Map();
for (const r of scan.readRefs) {
  if (!voiceIds.has(r.voice)) err(`#read: unknown voice "${r.voice}" at ${r.loc}`);
  else if (voices[r.voice].whose) err(`#read: ${r.voice} at ${r.loc} is ${voices[r.voice].whose}'s voice, not his`);
  if (!r.thing || !props || !props[r.thing] || r.thing === 'tonight') err(`#read: ${r.voice} reads "${r.thing}" at ${r.loc}, which isn't a thing in props.yaml`);
  const key = r.voice + ' ' + r.thing;
  if (readSeen.has(key)) err(`#read: ${key} at ${r.loc} again (first at ${readSeen.get(key)}): one read a voice a thing`);
  else readSeen.set(key, r.loc);
}
for (const t of scan.toyRefs) {
  const pr = props && props[t.id];
  if (!pr || t.id === 'tonight') { err(`#toy: "${t.id}" at ${t.loc} is not in props.yaml`); continue; }
  const can = PROP_KINDS[pr.kind] || [];
  if (!can.includes(t.what) && !(pr.kind === 'binder' && /^page\d+$/.test(t.what))) err(`#toy: ${t.id} ${t.what} at ${t.loc}: a ${pr.kind} can be ${can.join(', ')}${pr.kind === 'binder' ? ', or page<n>' : ''}`);
}
for (const r of barkSet.rules) {
  const tm = /^toy:([a-z0-9_]+):/.exec(r.on || '');
  if (tm && !PROP_KINDS[tm[1]] && !(props && props[tm[1]]) && !(things && things[tm[1]])) err(`barks.yaml: ${r.id} answers a thing, "${tm[1]}", that isn't in props.yaml or things.yaml or a kind of thing (${Object.keys(PROP_KINDS).join(', ')})`);
  if (tm && things && things[tm[1]] && !/:look$/.test(r.on)) err(`barks.yaml: ${r.id} answers ${r.on}, but a thing in the building (things.yaml) is only looked at: toy:${tm[1]}:look`);
}
// Things in the building he can look at: each has its words and its place in the room, and the Ink
// says what he sees (content/ink/things.ink)
const inkText = files.map((f) => fs.readFileSync(f, 'utf8')).join('\n');
for (const [id, th] of Object.entries(things || {})) {
  if (!/^[a-z0-9_]+$/.test(id)) err(`things.yaml: "${id}" should be lower case, digits and _`);
  if (props && props[id]) err(`things.yaml: "${id}" is a thing he's handed too (props.yaml); call one of them something else`);
  if (!th || !th.name) err(`things.yaml: ${id} has no name`);
  if (!th || !/^(a:[a-z0-9_]+|p:-?[\d.]+,-?[\d.]+,-?[\d.]+)$/.test(th.at || '')) err(`things.yaml: ${id} needs at: a:<anchor> or p:x,y,z`);
  if (!new RegExp('^===\\s*function\\s+toy_' + id + '\\s*\\(', 'm').test(inkText)) err(`things.yaml: ${id} has nothing to say: write === function toy_${id}(what) in content/ink/things.ink`);
  // where it's looked at from: the places he can be, by the names main.ink's where list gives them, or room
  const places = ((inkText.match(/^LIST where = (.*)$/m) || [])[1] || '').split(',').map((w) => w.trim());
  if (th && th.from !== undefined && (!Array.isArray(th.from) || th.from.some((f) => f !== 'room' && !places.includes(f))))
    err(`things.yaml: ${id}'s from should be a list of places he can be (room, ${places.join(', ')})`);
}
const wordSet = new B.Word(word || {});
const GROUPS = ['t28', 'kids', 'staff', 'owner', 'cook'];
for (const bad of wordSet.badCriteria()) err('word.yaml: cannot read criterion ' + bad);
for (const v of wordSet.variables()) if (story && !inkGlobals.includes(v)) err(`word.yaml uses "${v}", which is not an Ink VAR`);
const wordIds = new Set();
for (const r of wordSet.rules) {
  if (wordIds.has(r.id)) err(`word.yaml: ${r.id} is there twice`);
  wordIds.add(r.id);
  if (!GROUPS.includes(r.group)) err(`word.yaml: ${r.id} is for "${r.group}", which isn't one of ${GROUPS.join(', ')}`);
  if (r.way !== 'up' && r.way !== 'down') err(`word.yaml: ${r.id} has way "${r.way}"; it should be up or down`);
  if (!r.text) err(`word.yaml: ${r.id} has no text`);
}
for (const g of GROUPS) {
  if (story && !inkGlobals.includes('rep_' + g)) err(`word.yaml: the Ink has no VAR rep_${g}`);
  for (const way of ['up', 'down']) if (!wordSet.rules.some((r) => r.group === g && r.way === way && !r.once && !r.when.length)) warn(`word.yaml: nothing for ${g} ${way} can come round again (once: false), so a long night can run out of lines`);
}
for (const [id, c] of Object.entries(characters || {})) if (c && c.standing && !GROUPS.includes(c.standing)) err(`characters.yaml: ${id} has standing "${c.standing}", which isn't one of ${GROUPS.join(', ')}`);

// Writing prompts for Hutch
const promptMd = [
  '# Writing prompts',
  '',
  '*Generated by `node tools/build.mjs` from `// HUTCH:` comments and `#prompt:` tags in `content/ink/`. Don\'t edit this file; edit the Ink.*',
  '',
  'Each prompt marks a place where the draft needs your material or your voice. Rewrite the lines under it in the `.ink` file, then delete the `// HUTCH:` comment (or the `#prompt:` tag) so it drops off this list. In the game, **Settings → Show writing prompts** (on by default) puts a card in the story the first time the night reaches a scene with prompts.',
  '',
];
const byKnot = new Map();
for (const p of scan.prompts) {
  const key = p.loc.split(':')[0];
  if (!byKnot.has(key)) byKnot.set(key, []);
  byKnot.get(key).push(p);
}
let n = 0;
for (const [file, list] of byKnot) {
  promptMd.push('## ' + file, '');
  for (const p of list) promptMd.push(`${++n}. **${p.knot}** (\`${p.loc}\`): ${p.text}`);
  promptMd.push('');
}
if (!scan.prompts.length) promptMd.push('No open prompts.');

// ---------------------------------------------------------------- report

const hash = crypto.createHash('sha1').update(JSON.stringify([story, voices, characters, assets, barks, word, marks, props, things, merged])).digest('hex').slice(0, 8);
const stamp = new Date().toISOString().replace(/\.\d+Z$/, 'Z');
const build = stamp.slice(0, 10) + '-' + hash;

for (const w of problems.warnings) console.log('warning: ' + w);
for (const e of problems.errors) console.log('ERROR:   ' + e);
if (problems.errors.length) {
  console.log(`\nBuild failed with ${problems.errors.length} error(s).`);
  process.exit(1);
}

fs.mkdirSync(P('data', 'build'), { recursive: true });
fs.writeFileSync(P('data', 'build', 'story.json'), JSON.stringify(story));
// assetBase is where asset paths (relative to the project root) resolve from the page:
// prototype/web/index.html reaches them two folders up; dist/ carries its own copies.
const content = {
  meta: { build, builtAt: stamp, words: scan.words.total, knots: scan.knots, prompts: scan.prompts, merged, assetBase: '../../' },
  story, voices, characters, assets, barks, word, marks, props, things, psyche,
};
const contentJs = (c) =>
  '// Generated by tools/build.mjs. Do not edit; edit content/ and rebuild.\n' +
  'globalThis.BOUNCER_CONTENT = ' + JSON.stringify(c) + ';\n';
fs.writeFileSync(P('data', 'build', 'content.json'), JSON.stringify(content));
fs.writeFileSync(P('prototype', 'web', 'content.js'), contentJs(content));
// the Godot build reads the same content (godot/README.md)
if (fs.existsSync(P('godot', 'project.godot'))) {
  fs.mkdirSync(P('godot', 'data'), { recursive: true });
  fs.writeFileSync(P('godot', 'data', 'content.json'), JSON.stringify(content));
}
fs.writeFileSync(P('content', 'WRITING_PROMPTS.md'), promptMd.join('\n') + '\n');

console.log(`Built ${build}: ${files.length} Ink files, ${scan.words.total.toLocaleString()} words, ${Object.keys(voices).length} voices, ${Object.keys(characters).length} characters, ${barkSet.rules.length} barks, ${wordSet.rules.length} lines of the word on him, ${scan.prompts.length} writing prompts, ${assetFiles.length} art and sound files.`);
for (const [f, w] of Object.entries(scan.words.byFile)) console.log(`  ${f.padEnd(34)} ${String(w).padStart(6)} words`);
if (problems.warnings.length) console.log(`${problems.warnings.length} warning(s).`);

// The local files a stylesheet loads. Each url(...) is read whole, quotes and all, so a data: URI
// with a url() inside it (an SVG filter) is passed over rather than taken apart, and so is a
// reference to something in the page itself (url(#slip1), a filter src/ui/skin.js puts there).
const CSS_URL = /url\(\s*(?:"([^"]*)"|'([^']*)'|([^)'"\s]+))\s*\)/g;
const localUrl = (m) => {
  const u = m[1] != null ? m[1] : m[2] != null ? m[2] : m[3];
  return /^(?:https?:|data:|#)/.test(u) ? null : u;
};

// ---------------------------------------------------------------- offline: one file

let offlineFile = null;
if (args.has('--offline') || args.has('--dist')) {
  const WEB = P('prototype', 'web');
  const html = fs.readFileSync(path.join(WEB, 'index.html'), 'utf8');
  const MIME = { '.woff2': 'font/woff2', '.woff': 'font/woff', '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.webp': 'image/webp', '.ogg': 'audio/ogg', '.mp3': 'audio/mpeg', '.wav': 'audio/wav' };
  const dataUri = (file) => 'data:' + (MIME[path.extname(file).toLowerCase()] || 'application/octet-stream') + ';base64,' + fs.readFileSync(file).toString('base64');
  // Assets the Ink uses, inlined, so the file carries its own art and sound.
  const offAssets = JSON.parse(JSON.stringify(assets));
  for (const group of ['sfx', 'music', 'ambience', 'portraits']) {
    for (const slot of Object.values(offAssets[group] || {})) {
      if (slot && slot.file && slot.present) slot.file = dataUri(P(slot.file));
    }
  }
  const offContent = contentJs({ ...content, assets: offAssets, meta: { ...content.meta, assetBase: '', offline: true } });
  const inlineCss = (ref) => {
    const file = path.join(WEB, ref);
    return fs.readFileSync(file, 'utf8').replace(CSS_URL, function (all) {
      const u = localUrl(arguments);
      return u ? 'url(' + dataUri(path.join(path.dirname(file), u)) + ')' : all;
    });
  };
  const safeJs = (js) => js.replace(/<\/script/gi, '<\\/script');
  let out = html
    .replace(/<link rel="stylesheet" href="(?!https?:)([^"]+)">/g, (all, ref) => '<style>\n' + inlineCss(ref) + '\n</style>')
    .replace(/<script src="(?!https?:)([^"]+)"><\/script>/g, (all, ref) =>
      '<script>\n' + safeJs(ref === 'content.js' ? offContent : fs.readFileSync(path.join(WEB, ref), 'utf8')) + '\n</script>');
  if (/<(?:script|link)[^>]+(?:src|href)="(?!https?:|data:)/.test(out)) err('offline: a local file was left un-inlined');
  const REL = P('releases');
  fs.mkdirSync(REL, { recursive: true });
  const name = 'The-Bouncer-' + build + '.html';
  fs.writeFileSync(path.join(REL, name), out);
  fs.copyFileSync(path.join(REL, name), path.join(REL, 'The-Bouncer.html'));
  offlineFile = path.join(REL, 'The-Bouncer.html');
  console.log(`offline: releases/${name} (${(out.length / 1024 / 1024).toFixed(2)} MB), also releases/The-Bouncer.html`);
}

// ---------------------------------------------------------------- dist

if (args.has('--dist')) {
  const WEB = P('prototype', 'web');
  const DIST = path.join(WEB, 'dist');
  fs.rmSync(DIST, { recursive: true, force: true });
  fs.mkdirSync(DIST, { recursive: true });
  const html = fs.readFileSync(path.join(WEB, 'index.html'), 'utf8');
  // Every <script src> and <link rel=stylesheet href> that points at a local file is copied.
  const localRefs = [...html.matchAll(/(?:src|href)="(?!https?:|data:)([^"]+)"/g)].map((m) => m[1]);
  // and whatever those stylesheets load (the bundled fonts)
  for (const ref of localRefs.slice()) {
    if (!ref.endsWith('.css')) continue;
    const css = fs.readFileSync(path.join(WEB, ref), 'utf8');
    for (const m of css.matchAll(CSS_URL)) {
      const u = localUrl(m);
      if (!u) continue;
      const sub = path.posix.join(path.posix.dirname(ref), u);
      if (!localRefs.includes(sub)) localRefs.push(sub);
    }
  }
  for (const ref of localRefs) {
    const from = path.join(WEB, ref);
    if (!fs.existsSync(from)) { console.log('dist: missing ' + ref); continue; }
    const to = path.join(DIST, ref);
    fs.mkdirSync(path.dirname(to), { recursive: true });
    fs.copyFileSync(from, to);
  }
  // content.js again, with asset paths resolving inside dist/, and the asset files themselves
  fs.writeFileSync(path.join(DIST, 'content.js'), contentJs({ ...content, meta: { ...content.meta, assetBase: '' } }));
  for (const f of assetFiles) {
    const to = path.join(DIST, f);
    fs.mkdirSync(path.dirname(to), { recursive: true });
    fs.copyFileSync(P(f), to);
    localRefs.push(f);
  }
  // the one-file offline copy, for the game's "Save a copy to play offline"
  if (offlineFile) {
    fs.mkdirSync(path.join(DIST, 'offline'), { recursive: true });
    fs.copyFileSync(offlineFile, path.join(DIST, 'offline', 'The-Bouncer.html'));
    localRefs.push('offline/The-Bouncer.html');
  }
  fs.writeFileSync(path.join(DIST, 'index.html'), html);
  // The Artifact host wraps the page in its own <!doctype><html><head><body>, so the
  // artifact copy is the inside of <head> and <body> with those tags removed.
  const head = (/<head>([\s\S]*?)<\/head>/i.exec(html) || [, ''])[1]
    .replace(/<meta charset[^>]*>\s*/i, '')
    .replace(/<meta name="viewport"[^>]*>\s*/i, '');
  const body = (/<body[^>]*>([\s\S]*?)<\/body>/i.exec(html) || [, ''])[1];
  fs.writeFileSync(path.join(DIST, 'artifact.html'), head.trim() + '\n' + body.trim() + '\n');
  fs.writeFileSync(path.join(DIST, 'files.json'), JSON.stringify(localRefs, null, 1));
  console.log(`dist: ${localRefs.length} files in ${rel(DIST)}`);
}
