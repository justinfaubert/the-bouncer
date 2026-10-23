// wave sizes and timings across seeds
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { load as loadYaml } from '/home/claude/the-bouncer/tools/vendor/js-yaml.mjs';
const R = '/home/claude/the-bouncer';
for (const f of ['util.js', 'rng.js', 'folk.js']) vm.runInThisContext(fs.readFileSync(path.join(R, 'prototype/web/src/core', f), 'utf8'), { filename: f });
const B = globalThis.Bouncer;
const door = loadYaml(fs.readFileSync(path.join(R, 'content/rules/door.yaml'), 'utf8'));
const content = { people: loadYaml(fs.readFileSync(path.join(R, 'content/data/people.yaml'), 'utf8')), town: loadYaml(fs.readFileSync(path.join(R, 'content/data/town.yaml'), 'utf8')), props: { tonight: '2026-11-04' }, door };
const N = +(process.argv[2] || 200);
for (const day of [1, 3]) {
  const tot = {}; let people = 0, minors = 0, groups = 0, big = 0;
  for (let s = 1; s <= N; s++) {
    const t = B.Folk.make(s, content);
    const n = B.Folk.night(t, content, day);
    for (const a of n.arrivals) { groups++; if (a.who.length >= 3) big++; for (const id of a.who) { people++; tot[a.wave] = (tot[a.wave] || 0) + 1; if (t.byId[id].teen) minors++; } }
  }
  const avg = {}; for (const k in tot) avg[k] = (tot[k] / N).toFixed(1);
  console.log('day', day, 'people', (people / N).toFixed(1), 'minors', (minors / N).toFixed(2), 'groups', (groups / N).toFixed(1), 'groups3+', (big / N).toFixed(1), JSON.stringify(avg));
}
