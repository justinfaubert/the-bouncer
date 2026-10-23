// quick look at a generated town
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { load as loadYaml } from '/home/claude/the-bouncer/tools/vendor/js-yaml.mjs';
const R = '/home/claude/the-bouncer';
for (const f of ['util.js', 'rng.js', 'folk.js']) vm.runInThisContext(fs.readFileSync(path.join(R, 'prototype/web/src/core', f), 'utf8'), { filename: f });
const B = globalThis.Bouncer;
// util.hash32 lives where?
if (!B.util.hash32) console.log('no util.hash32!');
const content = {
  people: loadYaml(fs.readFileSync(path.join(R, 'content/data/people.yaml'), 'utf8')),
  town: loadYaml(fs.readFileSync(path.join(R, 'content/data/town.yaml'), 'utf8')),
  props: { tonight: '2026-11-04' },
};
const seed = +(process.argv[2] || 12345);
const t = B.Folk.make(seed, content);
const st = {}; for (const s of content.town.streets) st[s.id] = s;
const name = (p) => p.given + ' ' + p.surname;
const out = [];
for (const h of t.households) {
  const s = st[h.street];
  out.push(`${h.id} ${h.kind} ${h.home} ${h.unit ? h.unit + '-' : ''}${h.number} ${s.name}`);
  for (const id of h.members) {
    const p = t.byId[id];
    const c = p.card;
    out.push(`   ${p.id} ${name(p)} (${p.middle}) ${p.sex} ${p.age} b.${p.born} ${p.bg} ${p.teen ? 'TEEN ' : ''}${p.work}${p.shift ? '/' + p.shift : ''}${p.retiredFrom ? '<' + p.retiredFrom : ''} drink:${p.drink} reg:${p.regular} grp:${p.group} det:${p.detail}`
      + (p.partner ? ` partner:${p.partner}` : '') + (p.kidOf ? ` kidOf:${p.kidOf}` : '') + (p.siblings ? ` sibs:${p.siblings}` : '') + (p.ex ? ` ex:${p.ex}` : '') + (p.friends ? ` friends:${p.friends}` : ''));
    out.push(`      look ${JSON.stringify(p.look)} ${p.height}cm ${p.weight}kg ${p.eyes} ${p.hairCode}`);
    if (c) out.push(`      card ${c.type} ${c.cls} #${c.number} ${c.surname}, ${c.given} iss ${c.issued} exp ${c.expires}${c.expired ? ' EXPIRED' : ''} addr ${c.address.number} ${c.address.street}${c.address.old ? ' (OLD)' : ''} photo ${JSON.stringify(c.photo)}`);
    else out.push('      no card');
    if (p.tries) out.push(`      TRIES ${JSON.stringify(p.tries)}`);
    for (const k of ['debt', 'grudge', 'secret']) if (p[k]) out.push(`      ${k}: ${p[k].text.replace(/\{other\}/g, p[k].other ? name(t.byId[p[k].other]) : '?')}`);
    if (p.castTie) out.push(`      CAST ${p.castTie.cast}: ${p.castTie.text}`);
  }
}
fs.writeFileSync(path.join(path.dirname(new URL(import.meta.url).pathname), 'town-' + seed + '.txt'), out.join('\n'));
const ppl = t.people;
const count = (f) => { const m = {}; for (const p of ppl) { const k = f(p); m[k] = (m[k] || 0) + 1; } return m; };
console.log('households', t.households.length, 'people', ppl.length, 'adults', t.adults().length, 'teens', ppl.filter(p => p.teen).length);
console.log('work', JSON.stringify(count(p => p.work)));
console.log('regular', JSON.stringify(count(p => p.regular)));
console.log('drink', JSON.stringify(count(p => p.drink)));
console.log('bg', JSON.stringify(count(p => p.bg)));
console.log('area', JSON.stringify(count(p => p.area)));
console.log('tries', JSON.stringify(ppl.filter(p => p.tries).map(p => p.age + ':' + p.tries.kind)));
console.log('cast', JSON.stringify(ppl.filter(p => p.castTie).map(p => p.castTie.cast)));
console.log('rng calls', 'ok');
