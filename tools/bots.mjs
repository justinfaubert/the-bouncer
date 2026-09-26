#!/usr/bin/env node
// Playthrough bots. They play Wednesday many times and report what broke.
//
//   node tools/bots.mjs                     300 runs, half random, half exploring
//   node tools/bots.mjs --runs 2000 --seed 7
//   node tools/bots.mjs --trace 42          print one full run (seed 42) as a transcript
//   node tools/bots.mjs --json out.json     also write the report as JSON
//
// It checks for: Ink errors and warnings, runs that end anywhere but the dawn ledger, runs
// that go round in circles without finishing, save and load (a save taken mid-run, loaded into
// a fresh game, has to play out identically), knots and stitches no run ever reached, and
// empty choices. Then it prints how the nights came out, so a writer can see what's common,
// what's rare, and what never happens.
//
// Run `node tools/build.mjs` first; the bots play data/build/content.json.

import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const P = (...a) => path.join(ROOT, ...a);

const inkjs = require(P('prototype', 'web', 'lib', 'ink.js'));
for (const f of ['util', 'rng', 'psyche', 'checks', 'barks', 'game']) require(P('prototype', 'web', 'src', 'core', f + '.js'));
const B = globalThis.Bouncer;

// ---------------------------------------------------------------- args

const argv = process.argv.slice(2);
const opt = (name, dflt) => {
  const i = argv.indexOf('--' + name);
  if (i === -1) return dflt;
  const v = argv[i + 1];
  return v === undefined || v.startsWith('--') ? true : v;
};
const RUNS = parseInt(opt('runs', 300), 10);
const SEED0 = parseInt(opt('seed', 1), 10);
const TRACE = opt('trace', null);
const JSON_OUT = opt('json', null);
const STEP_CAP = 3000;

const contentFile = P('data', 'build', 'content.json');
if (!fs.existsSync(contentFile)) {
  console.error('No build found. Run: node tools/build.mjs');
  process.exit(1);
}
const content = JSON.parse(fs.readFileSync(contentFile, 'utf8'));

// ---------------------------------------------------------------- policies

// Choice novelty across all runs, so "explore" bots go where nobody has been.
const seenChoice = new Map();
const choiceKey = (g, c) => (g.getVar('here') ? String(B.Game.inkValue(g.getVar('here'))) : '') + '|' + c.text;

function pickIndex(g, visible, policy, rng) {
  if (policy === 'explore') {
    let best = Infinity;
    let pool = [];
    visible.forEach((c, i) => {
      const n = seenChoice.get(choiceKey(g, c)) || 0;
      if (n < best) { best = n; pool = [i]; } else if (n === best) pool.push(i);
    });
    return pool[rng.int(0, pool.length - 1)];
  }
  if (policy === 'dawdle') {
    // Lingers: prefers staying put and leaving things alone. Finds what happens when he isn't there.
    const lazy = visible.map((c, i) => [c, i]).filter(([c]) => /^(Stay|Leave|Back|Let it|Say nothing|Sleep)/.test(c.text));
    if (lazy.length && rng.next() < 0.7) return lazy[rng.int(0, lazy.length - 1)][1];
  }
  return rng.int(0, visible.length - 1);
}

// ---------------------------------------------------------------- one run

function newGame() {
  return new B.Game(content, { ink: inkjs });
}

function visibleOf(res) { return res.choices.filter((c) => !c.hidden); }

function play(seed, policy, opts = {}) {
  const g = newGame();
  const rng = new B.Rng((seed * 7919 + 13) >>> 0);
  let res = g.newGame(seed);
  const transcript = [];
  const words = [];
  const record = (items) => {
    for (const it of items) if (it.kind === 'word') words.push(it.group + ' ' + it.way + (it.text ? '' : ' (nothing to say)'));
    if (opts.trace) for (const it of items) transcript.push(it);
  };
  record(res.items);
  const problems = [];
  const path = [];
  let steps = 0;
  let saveTest = null;
  const saveAt = opts.saveTest ? rng.int(10, 120) : -1;

  while (!res.ended && steps < STEP_CAP) {
    const vis = visibleOf(res);
    if (!vis.length) {
      problems.push({ kind: 'stuck', msg: 'choices exist but all are hidden', where: where(g) });
      break;
    }
    for (const c of vis) if (!c.text) problems.push({ kind: 'empty-choice', msg: 'a choice with no text', where: where(g) });
    if (steps === saveAt) saveTest = checkSaveLoad(g, res, rng.getState());
    const i = pickIndex(g, vis, policy, rng);
    const c = vis[i];
    seenChoice.set(choiceKey(g, c), (seenChoice.get(choiceKey(g, c)) || 0) + 1);
    path.push(i);
    if (opts.trace) transcript.push({ kind: 'pick', text: c.text, options: vis.map((v) => v.text + (v.check ? ` [${v.check.label} ${v.check.word}, ${v.check.oddsWord}]` : '')) });
    res = g.choose(i);
    record(res.items);
    steps++;
  }

  if (!res.ended) problems.push({ kind: 'no-end', msg: `still going after ${STEP_CAP} choices`, where: where(g) });
  const story = g.story;
  const visited = (p) => { try { return story.state.VisitCountAtPathString(p) > 0; } catch (e) { return false; } };
  if (res.ended && !visited('ledger')) problems.push({ kind: 'dead-end', msg: 'the story ended before the dawn ledger', where: where(g), last: g.log.slice(-4).map((l) => l.text) });
  for (const e of g.errors) problems.push({ kind: e.type === 1 ? 'ink-warning' : 'ink-error', msg: e.message, where: where(g) });
  if (saveTest && !saveTest.ok) problems.push({ kind: 'save-load', msg: saveTest.msg, where: saveTest.where });
  for (const w of words) if (w.endsWith('(nothing to say)')) problems.push({ kind: 'word', msg: 'the word on him ran out of lines: ' + w, where: where(g) });

  const v = g.vars();
  const knots = {};
  for (const k of content.meta.knots) if (visited(k)) knots[k] = 1;

  return {
    seed, policy, steps, problems, knots, transcript, path, words,
    outcome: outcomeOf(v, g),
    checks: g.checkHistory.map((c) => ({ voice: c.voice, success: c.success })),
  };
}

function where(g) {
  try {
    const p = g.story.state.currentPathString || (g.story.state.previousPointer && g.story.state.previousPointer.path && g.story.state.previousPointer.path.toString());
    return (p || '?') + ' @ ' + B.util.fmtClock(g.getVar('clock') | 0);
  } catch (e) { return '?'; }
}

// Play a copy from a save and make sure it goes exactly the same way.
function checkSaveLoad(g, res, rngState) {
  const save = JSON.parse(JSON.stringify(g.serialize()));
  const g2 = newGame();
  const r2 = g2.load(save);
  const sameChoices = JSON.stringify(visibleOf(res).map((c) => c.text)) === JSON.stringify(visibleOf(r2).map((c) => c.text));
  if (!sameChoices) return { ok: false, msg: 'choices differ right after loading a save', where: where(g) };
  // Drive both with the same picks for a while and compare everything they say.
  const probe = new B.Rng((rngState.state ^ 0x5bd1e995) >>> 0);
  const a = newGame(); a.load(JSON.parse(JSON.stringify(save)));
  let ra = { choices: a.choices, ended: a.ended };
  let rb = r2;
  for (let k = 0; k < 40 && !ra.ended && !rb.ended; k++) {
    const va = visibleOf(ra), vb = visibleOf(rb);
    if (!va.length || !vb.length) break;
    const i = probe.int(0, va.length - 1);
    ra = a.choose(i);
    rb = g2.choose(i);
    const ta = JSON.stringify(ra.items.map((x) => [x.kind, x.text || x.id || x.name || '', x.success]));
    const tb = JSON.stringify(rb.items.map((x) => [x.kind, x.text || x.id || x.name || '', x.success]));
    if (ta !== tb) return { ok: false, msg: `two copies of the same save played differently after ${k + 1} choices`, where: where(a) };
  }
  return { ok: true };
}

function outcomeOf(v, g) {
  const has = (list, item) => Array.isArray(list) && list.includes(item);
  const fam = v.fam || [];
  let family = 'unresolved';
  if (has(fam, 'dad_went')) family = has(fam, 'lot_scene') ? 'went, from the lot' : 'went with his kids';
  else if (has(fam, 'dad_drove')) family = 'drove home drunk';
  else if (has(fam, 'dad_ejected')) family = 'put out';
  else if (has(fam, 'lot_scene')) family = 'walked home without his keys';
  else if (has(fam, 'dad_stayed')) family = 'finished his game';
  const rats = (v.rats || [])[0] || '?';
  return {
    family,
    'family: pool fight': has(fam, 'pool_fight') ? 'yes' : 'no',
    'family: kids came in the back': has(fam, 'via_deck') ? 'yes' : 'no',
    'family: the kid talked': has(fam, 'kid_opened') ? 'yes' : 'no',
    rats,
    parley: ['never', 'talked', 'deal'][v.parley] || String(v.parley),
    walter: ['dead', 'alive', 'let go', 'ate the bait'][v.walter] || String(v.walter),
    'GOOD SHOES': (v.arrivals || []).includes('banned_out') ? 'kept out / put out' : ((v.arrivals || []).includes('banned_in') ? 'let in' : 'got in unseen and stayed'),
    verdict: { 2: "he'll do", 1: 'showed up', '-1': 'what she saw', 0: 'none' }[v.verdict],
    drinks: v.drinks >= 4 ? '4+' : String(v.drinks),
    hurt: String(v.hurt),
    'incidents logged straight': String((v.logged || []).length),
    'incidents left out': String((v.left_out || []).length),
    'new voice': g.psyche.seated.filter((s) => s === 'table' || s === 'kid').join('+') || 'none',
    'tension at dawn': String(g.psyche.tension()),
    'uncounted': String(v.uncounted),
    'ends at': B.util.fmtClock(v.clock | 0),
  };
}

// ---------------------------------------------------------------- trace mode

if (TRACE !== null) {
  const seed = parseInt(TRACE, 10) || 1;
  const r = play(seed, opt('policy', 'random'), { trace: true, saveTest: true });
  for (const it of r.transcript) {
    if (it.kind === 'pick') { console.log('\n  > ' + it.text + '\n'); continue; }
    if (it.kind === 'line') console.log((it.label ? it.label + ': ' : it.role === 'teller' ? '[teller] ' : '') + it.text);
    else if (it.kind === 'check') console.log(`  [${it.label} ${it.word}: rolled ${it.roll.d1}+${it.roll.d2} -> ${it.roll.total} vs ${it.target}, ${it.success ? 'success' : 'failure'}]`);
    else if (it.kind === 'task') console.log(`  [task ${it.op}: ${it.text}]`);
    else if (it.kind === 'psyche') console.log(`  [psyche: ${it.op} ${it.voice || (it.a + '/' + it.b)}]`);
    else if (it.kind === 'word') console.log(`  [${it.who} ${it.way}: "${it.text}"]`);
    else if (it.kind === 'screen') console.log(`  [screen: ${it.name}]`);
  }
  console.log('\n---\n', JSON.stringify(r.outcome, null, 1));
  if (r.problems.length) console.log('PROBLEMS:', r.problems);
  process.exit(r.problems.some((p) => p.kind !== 'ink-warning') ? 1 : 0);
}

// ---------------------------------------------------------------- many runs

const t0 = Date.now();
const results = [];
const policies = ['random', 'explore', 'dawdle', 'explore'];
for (let n = 0; n < RUNS; n++) {
  const seed = SEED0 + n;
  results.push(play(seed, policies[n % policies.length], { saveTest: n % 5 === 0 }));
}
const secs = ((Date.now() - t0) / 1000).toFixed(1);

// Problems, grouped
const byProblem = new Map();
for (const r of results) for (const p of r.problems) {
  const k = p.kind + ': ' + p.msg;
  if (!byProblem.has(k)) byProblem.set(k, { count: 0, seeds: [], where: p.where, last: p.last });
  const e = byProblem.get(k);
  e.count++;
  if (e.seeds.length < 5) e.seeds.push(r.seed);
}

// Coverage
const reached = new Set();
for (const r of results) for (const k in r.knots) reached.add(k);
const never = content.meta.knots.filter((k) => !reached.has(k));

// Outcomes
const hist = {};
for (const r of results) for (const [k, v] of Object.entries(r.outcome)) {
  hist[k] = hist[k] || {};
  hist[k][v] = (hist[k][v] || 0) + 1;
}

// Checks by voice
const checks = {};
for (const r of results) for (const c of r.checks) {
  checks[c.voice] = checks[c.voice] || { n: 0, pass: 0 };
  checks[c.voice].n++;
  if (c.success) checks[c.voice].pass++;
}

const steps = results.map((r) => r.steps).sort((a, b) => a - b);
console.log(`${RUNS} runs in ${secs}s. Choices per run: median ${steps[Math.floor(steps.length / 2)]}, min ${steps[0]}, max ${steps[steps.length - 1]}.`);
console.log(`Knots and stitches reached: ${reached.size} of ${content.meta.knots.length}.`);
if (never.length) console.log('Never reached:\n  ' + never.join('\n  '));

if (byProblem.size) {
  console.log('\nPROBLEMS');
  for (const [k, e] of byProblem) {
    console.log(`  ${e.count}x ${k}\n     at ${e.where}; seeds ${e.seeds.join(', ')}`);
    if (e.last) console.log('     last lines: ' + e.last.join(' / '));
  }
} else {
  console.log('\nNo problems.');
}

console.log('\nHOW THE NIGHTS CAME OUT');
for (const [k, vals] of Object.entries(hist)) {
  const parts = Object.entries(vals).sort((a, b) => b[1] - a[1]).map(([v, n]) => `${v} ${Math.round((100 * n) / RUNS)}%`);
  console.log(`  ${k.padEnd(32)} ${parts.join(', ')}`);
}
console.log('\nTHE WORD ON HIM (a night, on average)');
const wordTally = {};
for (const r of results) for (const w of r.words) wordTally[w] = (wordTally[w] || 0) + 1;
for (const [k, n] of Object.entries(wordTally).sort()) console.log(`  ${k.padEnd(32)} ${(n / RUNS).toFixed(1)}`);

console.log('\nCHECKS');
for (const [v, c] of Object.entries(checks)) console.log(`  ${v.padEnd(10)} ${c.n} rolled, ${Math.round((100 * c.pass) / c.n)}% passed`);

if (JSON_OUT) {
  fs.writeFileSync(JSON_OUT, JSON.stringify({ runs: RUNS, problems: [...byProblem.entries()], never, outcomes: hist, checks }, null, 1));
  console.log('\nWrote ' + JSON_OUT);
}
process.exit([...byProblem.keys()].some((k) => !k.startsWith('ink-warning')) ? 1 : 0);
