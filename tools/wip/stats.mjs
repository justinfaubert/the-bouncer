import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { load as loadYaml } from '/home/claude/the-bouncer/tools/vendor/js-yaml.mjs';
const R = '/home/claude/the-bouncer';
for (const f of ['util.js', 'rng.js', 'folk.js']) vm.runInThisContext(fs.readFileSync(path.join(R, 'prototype/web/src/core', f), 'utf8'), { filename: f });
const B = globalThis.Bouncer;
const content = {
  people: loadYaml(fs.readFileSync(path.join(R, 'content/data/people.yaml'), 'utf8')),
  town: loadYaml(fs.readFileSync(path.join(R, 'content/data/town.yaml'), 'utf8')),
  props: { tonight: '2026-11-04' },
};
const N = +(process.argv[2] || 200);
const agg = {};
const add = (k, v = 1) => { agg[k] = (agg[k] || 0) + v; };
let t0 = Date.now();
for (let s = 1; s <= N; s++) {
  const t = B.Folk.make(s * 7919, content);
  add('people', t.people.length); add('teens', t.people.filter(p => p.teen).length); add('hh', t.households.length);
  for (const p of t.people) {
    if (p.tries) { add('tries'); add('try:' + p.tries.kind); add('tryage:' + p.age); if (p.tries.kind === 'phone' && !p.tries.from) add('phone-nofrom'); }
    if (p.card && p.card.expired) add('expired');
    if (p.card && p.card.type === 'id') add('idcard');
    if (p.card && p.card.address.old) add('oldaddr');
    if (!p.card) add(p.teen ? 'nocard-teen' : 'nocard-adult');
    if (p.castTie) add('cast:' + p.castTie.cast);
    if (!p.teen && p.siblings) add('adult-with-sibs');
    if (p.teen && (p.siblings || []).some(id => !t.byId[id].teen)) add('teen-with-grown-sib');
    if (!p.teen && p.regular) add('reg:' + p.regular);
  }
}
console.log('ms', Date.now() - t0);
for (const k of Object.keys(agg).sort()) console.log(k, (agg[k] / N).toFixed(2));
