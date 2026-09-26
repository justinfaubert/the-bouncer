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
  const checks = [];            // {voice, loc}
  const fx = [];                // {type, id, loc}
  const prompts = [];           // {text, loc, knot, kind}
  const words = { total: 0, byFile: {} };
  const knots = [];             // "knot" and "knot.stitch", not functions
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
      for (const m of code.matchAll(/#\s*check:\s*([a-z_]+)/gi)) checks.push({ voice: m[1].toLowerCase(), loc });
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
  return { speakers, checks, fx, prompts, words, knots };
}

// ---------------------------------------------------------------- main

const files = inkFiles(INK_MAIN);
const story = compileInk();

const voices = yaml('content/data/voices.yaml', {});
const characters = yaml('content/data/characters.yaml', {});
const assets = yaml('content/data/assets.yaml', {});
const barks = yaml('content/rules/barks.yaml', []);
const word = yaml('content/rules/word.yaml', {});
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
for (const c of scan.checks) if (!voiceIds.has(c.voice)) err(`check by unknown voice "${c.voice}" at ${c.loc}`);
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
  for (const need of ['clock', 'cash', 'drinks', 'count_in', 'hurt', 'here', 'passed', 'crit', 'day']) {
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

const hash = crypto.createHash('sha1').update(JSON.stringify([story, voices, characters, assets, barks, word, merged])).digest('hex').slice(0, 8);
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
  story, voices, characters, assets, barks, word, psyche,
};
const contentJs = (c) =>
  '// Generated by tools/build.mjs. Do not edit; edit content/ and rebuild.\n' +
  'globalThis.BOUNCER_CONTENT = ' + JSON.stringify(c) + ';\n';
fs.writeFileSync(P('data', 'build', 'content.json'), JSON.stringify(content));
fs.writeFileSync(P('prototype', 'web', 'content.js'), contentJs(content));
fs.writeFileSync(P('content', 'WRITING_PROMPTS.md'), promptMd.join('\n') + '\n');

console.log(`Built ${build}: ${files.length} Ink files, ${scan.words.total.toLocaleString()} words, ${Object.keys(voices).length} voices, ${Object.keys(characters).length} characters, ${barkSet.rules.length} barks, ${wordSet.rules.length} lines of the word on him, ${scan.prompts.length} writing prompts, ${assetFiles.length} art and sound files.`);
for (const [f, w] of Object.entries(scan.words.byFile)) console.log(`  ${f.padEnd(34)} ${String(w).padStart(6)} words`);
if (problems.warnings.length) console.log(`${problems.warnings.length} warning(s).`);

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
    return fs.readFileSync(file, 'utf8').replace(/url\((?!['"]?(?:https?:|data:))['"]?([^)'"]+)['"]?\)/g,
      (all, u) => 'url(' + dataUri(path.join(path.dirname(file), u)) + ')');
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
    for (const m of css.matchAll(/url\((?!['"]?(?:https?:|data:))['"]?([^)'"]+)['"]?\)/g)) {
      const sub = path.posix.join(path.posix.dirname(ref), m[1]);
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
