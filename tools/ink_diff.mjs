#!/usr/bin/env node
// Plays the raw Ink with inkjs exactly as godot/tests/ink_run.gd does in Godot (same seeded
// chooser, same save and load mid-night), then compares the two transcripts line for line.
//   node tools/ink_diff.mjs --from 1 --to 50 --godot /tmp/ink
// --start knot.stitch plays each night from there, the same as ink_run.gd's --start.
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
const ROOT = process.env.BOUNCER_ROOT || path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const inkjs = require(path.join(ROOT, 'prototype', 'web', 'lib', 'ink.js'));
const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf('--' + n); return i === -1 ? d : argv[i + 1]; };
const FROM = parseInt(opt('from', 1), 10), TO = parseInt(opt('to', 10), 10);
const GDIR = opt('godot', '/tmp/ink');
const START = opt('start', '');
const storyJson = fs.readFileSync(path.join(ROOT, 'data', 'build', 'story.json'), 'utf8');

const esc = (s) => String(s).replace(/\\/g, '\\\\').replace(/\n/g, '\\n').replace(/\|/g, '\\p');

function night(seed) {
  const lines = [];
  let story = new inkjs.Story(storyJson);
  story.allowExternalFunctionFallbacks = true;
  const onError = (msg, type) => lines.push(`E|${type}|${esc(msg)}`);
  story.onError = onError;
  story.state.storySeed = seed % 2147483647;
  if (START) story.ChoosePathString(START);
  let rng = seed, steps = 0, stateJson = null;
  const saveAt = 20 + (seed % 60);
  for (;;) {
    while (story.canContinue) {
      const text = story.Continue();
      lines.push(`T|${esc(text)}|${esc(story.currentTags.join('#'))}`);
    }
    const ch = story.currentChoices;
    if (!ch.length) break;
    for (const c of ch) lines.push(`C|${c.index}|${esc(c.text)}|${esc((c.tags || []).join('#'))}`);
    if (steps === saveAt) {
      stateJson = story.state.ToJson();
      const fresh = new inkjs.Story(storyJson);
      fresh.allowExternalFunctionFallbacks = true;
      fresh.onError = onError;
      fresh.state.LoadJson(stateJson);
      story = fresh;
      lines.push(`S|${steps}`);
    }
    rng = (rng * 48271) % 2147483647;
    const pick = rng % ch.length;
    lines.push(`P|${pick}`);
    story.ChooseChoiceIndex(pick);
    steps++;
    if (steps > 3000) { lines.push('CAP'); break; }
  }
  lines.push(`END|${steps}|${story.state.VisitCountAtPathString('ledger')}`);
  return { lines, stateJson };
}

// Deep compare of two save states, ignoring key order (Godot writes 1.0 where JS writes 1).
function deepDiff(a, b, where = '$') {
  if (typeof a === 'number' && typeof b === 'number') return a === b ? null : `${where}: ${a} vs ${b}`;
  if (a === null || b === null || typeof a !== 'object' || typeof b !== 'object') return a === b ? null : `${where}: ${JSON.stringify(a)} vs ${JSON.stringify(b)}`;
  if (Array.isArray(a) !== Array.isArray(b)) return `${where}: array vs object`;
  if (Array.isArray(a)) {
    if (a.length !== b.length) return `${where}: length ${a.length} vs ${b.length}`;
    for (let i = 0; i < a.length; i++) { const d = deepDiff(a[i], b[i], `${where}[${i}]`); if (d) return d; }
    return null;
  }
  const ka = Object.keys(a).sort(), kb = Object.keys(b).sort();
  if (ka.join() !== kb.join()) return `${where}: keys ${ka.filter((k) => !kb.includes(k))} vs ${kb.filter((k) => !ka.includes(k))}`;
  for (const k of ka) { const d = deepDiff(a[k], b[k], `${where}.${k}`); if (d) return d; }
  return null;
}

let same = 0, differ = 0, stateSame = 0, stateDiffer = 0, missing = 0;
for (let seed = FROM; seed <= TO; seed++) {
  const js = night(seed);
  const gFile = path.join(GDIR, `g_${seed}.txt`);
  if (!fs.existsSync(gFile)) { missing++; continue; }
  const g = fs.readFileSync(gFile, 'utf8').replace(/\n$/, '').split('\n');
  const j = js.lines;
  let at = -1;
  for (let i = 0; i < Math.max(g.length, j.length); i++) if (g[i] !== j[i]) { at = i; break; }
  if (at === -1) same++;
  else {
    differ++;
    if (differ <= 5) {
      console.log(`seed ${seed}: first difference at line ${at + 1}`);
      for (let i = Math.max(0, at - 3); i <= at; i++) console.log('   ' + (i === at ? '>' : ' ') + ' js:    ' + (j[i] ?? '(none)'));
      console.log('    > godot: ' + (g[at] ?? '(none)'));
    }
  }
  const gState = path.join(GDIR, `g_${seed}.state.json`);
  if (js.stateJson && fs.existsSync(gState)) {
    const d = deepDiff(JSON.parse(js.stateJson), JSON.parse(fs.readFileSync(gState, 'utf8')));
    if (d) { stateDiffer++; if (stateDiffer <= 5) console.log(`seed ${seed}: saved state differs at ${d}`); } else stateSame++;
  }
}
console.log(`${same} nights identical, ${differ} differ, ${missing} missing; saved states: ${stateSame} identical, ${stateDiffer} differ`);
process.exit(differ || stateDiffer ? 1 : 0);
