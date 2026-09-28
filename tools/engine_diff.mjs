#!/usr/bin/env node
// Plays whole nights through the browser build's engine exactly as godot/tests/engine_run.gd does
// in Godot, then compares the two canonical transcripts line for line.
//   node tools/engine_diff.mjs --from 1 --to 20 --godot /tmp/eng
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
const ROOT = process.env.BOUNCER_ROOT || path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const inkjs = require(path.join(ROOT, 'prototype', 'web', 'lib', 'ink.js'));
for (const f of ['util', 'rng', 'psyche', 'checks', 'barks', 'game']) require(path.join(ROOT, 'prototype', 'web', 'src', 'core', f + '.js'));
const B = globalThis.Bouncer;
const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf('--' + n); return i === -1 ? d : argv[i + 1]; };
const FROM = parseInt(opt('from', 1), 10), TO = parseInt(opt('to', 5), 10);
const GDIR = opt('godot', '/tmp/eng');
const content = JSON.parse(fs.readFileSync(path.join(ROOT, 'data', 'build', 'content.json'), 'utf8'));

function quote(s) {
  let out = '"';
  for (const ch of String(s)) {
    const c = ch.codePointAt(0);
    if (c === 34) out += '\\"';
    else if (c === 92) out += '\\\\';
    else if (c === 10) out += '\\n';
    else if (c === 13) out += '\\r';
    else if (c === 9) out += '\\t';
    else if (c < 32) out += '\\u' + c.toString(16).padStart(4, '0');
    else out += ch;
  }
  return out + '"';
}
function canon(v) {
  if (v === null || v === undefined) return 'null';
  if (typeof v === 'boolean') return v ? 'true' : 'false';
  if (typeof v === 'number') {
    if (Number.isNaN(v)) return 'NaN';
    if (Number.isInteger(v) && Math.abs(v) < 1e15) return String(v === 0 ? 0 : v);
    return v.toFixed(6);
  }
  if (typeof v === 'string') return quote(v);
  if (Array.isArray(v)) return '[' + v.map(canon).join(',') + ']';
  if (typeof v === 'object') {
    if (v instanceof Map) return '"<object>"';
    const keys = Object.keys(v).filter((k) => v[k] !== null && v[k] !== undefined).sort();
    return '{' + keys.map((k) => quote(k) + ':' + canon(v[k])).join(',') + '}';
  }
  return '"<object>"';
}

function play(night) {
  const lines = [];
  let rs = night;
  const rnd = () => (rs = (rs * 48271) % 2147483647);
  let g = new B.Game(content, { ink: inkjs });
  let res = g.newGame(night);
  lines.push('N ' + canon(res));
  let steps = 0;
  const saveAt = 15 + (night % 50);
  while (!res.ended && steps < 3000) {
    if (steps === saveAt) {
      const s = g.serialize();
      delete s.savedAt;
      const text = JSON.stringify(s);
      g = new B.Game(content, { ink: inkjs });
      res = g.load(JSON.parse(text));
      lines.push('S ' + canon(res));
    }
    const vis = g.choices.filter((c) => !c.hidden);
    if (!vis.length) { lines.push('STUCK'); break; }
    if (g.clickerInHand() && rnd() % 9 === 0) lines.push('K ' + canon(g.toy('clicker', 'click') || {}));
    const handled = res.choices.filter((c) => c.toy && c.unlisted && g.toyChoice(c.toy.id, c.toy.what) === c);
    if (handled.length && rnd() % 3 === 0) {
      const hc = handled[rnd() % handled.length];
      res = g.toy(hc.toy.id, hc.toy.what);
      lines.push('H ' + canon(res));
      steps++;
      continue;
    }
    lines.push('W ' + canon(g.whisper(rnd() % vis.length)));
    if (steps % 7 === 3) lines.push('M ' + canon(g.murmur('wait')));
    const pick = rnd() % vis.length;
    const considered = [rnd() % vis.length];
    res = g.choose(pick, { considered });
    lines.push('C ' + canon(res));
    lines.push('T ' + canon(g.status()));
    steps++;
  }
  lines.push('END ' + canon({ steps, ended: res.ended, errors: g.errors, sketch: g.sketch, tasks: g.tasks, said: g.said }));
  return lines;
}

// the first place two canonical lines part, with a little of each around it
function where(a, b) {
  let i = 0;
  while (i < a.length && i < b.length && a[i] === b[i]) i++;
  return i;
}

let same = 0, differ = 0, missing = 0;
const t0 = Date.now();
for (let night = FROM; night <= TO; night++) {
  const j = play(night);
  const gFile = path.join(GDIR, `g_${night}.txt`);
  if (!fs.existsSync(gFile)) { missing++; continue; }
  const g = fs.readFileSync(gFile, 'utf8').replace(/\n$/, '').split('\n');
  let at = -1;
  for (let i = 0; i < Math.max(g.length, j.length); i++) if (g[i] !== j[i]) { at = i; break; }
  if (at === -1) { same++; continue; }
  differ++;
  if (differ <= 4) {
    const a = j[at] || '(none)', b = g[at] || '(none)';
    const k = where(a, b);
    console.log(`night ${night}: line ${at + 1} differs at char ${k}`);
    console.log('   js:    ...' + a.slice(Math.max(0, k - 160), k + 200));
    console.log('   godot: ...' + b.slice(Math.max(0, k - 160), k + 200));
  }
}
console.log(`${same} nights identical, ${differ} differ, ${missing} missing (js ${((Date.now() - t0) / 1000).toFixed(1)} s)`);
process.exit(differ ? 1 : 0);
