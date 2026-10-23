// A Friday at the door, played by a simple policy, to check the waves, the line and the lines.
// node friday.mjs [seed] [policy: quick|slow|mixed] [--quiet]
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { load as loadYaml } from '/home/claude/the-bouncer/tools/vendor/js-yaml.mjs';
const R = '/home/claude/the-bouncer';
for (const f of ['util.js', 'rng.js', 'folk.js']) vm.runInThisContext(fs.readFileSync(path.join(R, 'prototype/web/src/core', f), 'utf8'), { filename: f });
const B = globalThis.Bouncer;
const chars = loadYaml(fs.readFileSync(path.join(R, 'content/data/characters.yaml'), 'utf8'));
const door = loadYaml(fs.readFileSync(path.join(R, 'content/rules/door.yaml'), 'utf8'));
door.tags.cast = Object.values(chars).map((c) => c.label).filter(Boolean);
const content = {
  people: loadYaml(fs.readFileSync(path.join(R, 'content/data/people.yaml'), 'utf8')),
  town: loadYaml(fs.readFileSync(path.join(R, 'content/data/town.yaml'), 'utf8')),
  props: { tonight: '2026-11-04' },
  door: door,
};
const seed = +(process.argv[2] || 12345);
const policy = process.argv[3] || 'mixed';
const quiet = process.argv.includes('--quiet');
const town = B.Folk.make(seed, content);
const mem = { met: {}, used: [] };
const say = (s) => { if (!quiet) console.log(s); };
const fmt = B.util.fmtClock;

function play(day, from, to) {
  const d = new B.Folk.Door(town, content, day, mem);
  const rng = new B.Rng(seed ^ 0x5eed);
  let clock = from;
  const stats = { wis: 4, gut: 4 };
  let lastLeft = 0, lastSlip = 0;
  say(`\n===== DAY ${day}: ${d.count('arrivals')} coming =====`);
  while (clock < to) {
    d.tick(clock, day === 1);
    const w = d.wave();
    if (w) say(`[${fmt(clock)}] ~~ the ${w} wave ~~`);
    if (d.n.left > lastLeft) { say(`[${fmt(clock)}]   (${d.n.left - lastLeft} left the line)`); lastLeft = d.n.left; }
    if (d.n.slipped > lastSlip) { say(`[${fmt(clock)}]   (${d.n.slipped - lastSlip} slipped past)`); lastSlip = d.n.slipped; }
    if (!d.next(clock)) { clock += 5; continue; }
    const id = d.cur, p = town.byId[id];
    const lab = () => d.label(id);
    say(`[${fmt(clock)}] line ${d.line.length} | ${id} ${p.given} ${p.surname} ${p.age}${p.teen ? ' TEEN/' + p.tries.kind : ''} ${d.reg(p)} drunk${d.info(id).drunk} ${d.info(id).wave}${d.st.why ? ' why:' + d.st.why : ''}`);
    say('    ' + d.say('arrive'));
    say(`    ${lab()}: ` + d.say(d.has('known') ? 'known' : 'greet'));
    if (d.st.why === 'card') {
      say(`    ${lab()}: ` + d.say('for_card'));
      d.act('give', { clock });
      d.act('admit', { clock });
      clock += 2;
      continue;
    }
    const slow = policy === 'slow' || (policy === 'mixed' && (p.age <= 25 || rng.next() < 0.15));
    if (!slow && (p.age >= 30 || policy === 'quick') && rng.next() < 0.7) {
      d.act('nod', { clock });
      say(`    -> nod. ${lab()}: ` + d.say('nod_in'));
      clock += 1;
      if (d.has('waiting') && d.line.length && d.groupOf(id) && d.groupOf(id).who.indexOf(d.line[0].id) !== -1) {}
      continue;
    }
    if (d.has('nocard')) {
      say(`    ${lab()}: ` + d.say('noid'));
      if (rng.next() < 0.5) { d.act('back', { clock }); say('    -> go get it'); }
      else { d.act('refuse', { clock }); say(`    -> refused. ${lab()}: ` + d.say('refused')); }
      clock += 1;
      continue;
    }
    if (d.has('phone')) {
      say('    ' + d.say('phone_out'));
      d.act('refuse', { clock });
      say(`    -> refused. ${lab()}: ` + d.say('refused'));
      clock += 1;
      continue;
    }
    say('    ' + d.say('card_out') + `  [${d.propId()}]`);
    if (!slow) {
      const r = d.act('glance', { clock, stats });
      if (r) { say(`    -> glance, in. ${lab()}: ` + d.say('in')); clock += 1; continue; }
      say('    -> glance CAUGHT: ' + d.say('caught'));
    }
    d.act('take', { clock });
    clock += 1;
    for (const q of ['birthday', 'sign', 'year']) {
      if (rng.next() < 0.6) {
        d.act('ask:' + q, { clock });
        say(`    "${q}?" ${lab()}: ` + d.say(q) + (d.has('wrong') ? '   <-- WRONG' : '') + (d.has('hes') ? ' (hes)' : ''));
        clock += 1;
      }
    }
    if (rng.next() < 0.5) { d.act('look', { clock }); say('    look: ' + d.say('look')); }
    if (rng.next() < 0.5) { const t = d.handle('tilt'); say('    tilt: ' + t); }
    if (rng.next() < 0.5) { d.act('scan', { clock }); say('    scan: ' + d.st.scanned); clock += 1; }
    if (rng.next() < 0.4) { const ok = rng.next() < 0.6; d.act('size', { clock, passed: ok }); say('    size: ' + d.say(ok ? 'size' : 'size_fail')); clock += 1; }
    if (rng.next() < 0.3) { d.act('chat', { clock }); say(`    chat. ${lab()}: ` + d.say('chat')); clock += 1; }
    const bad = d.has('wrong') || d.st.scanned === 'red' || d.st.scanned === 'real' || (d.st.looked && d.st.looked !== 'match') || d.st.tilted === 'still' || d.st.tilted === 'ridge';
    if (bad && p.teen && rng.next() < 0.5) { d.act('keep', { clock }); say(`    -> KEPT. ${lab()}: ` + d.say('kept')); }
    else if (bad) { d.act('refuse', { clock }); say(`    -> refused. ${lab()}: ` + d.say('refused')); }
    else { d.act('admit', { clock }); say(`    -> in. ${lab()}: ` + d.say('in')); }
    clock += 1;
    if (d.act('found', { clock }) || d.other) { const o = town.byId[d.other]; say(`    !! Paige found ${o.given} ${o.surname} (${o.age}) at the bar`); }
  }
  console.log(`DAY ${day} seed ${seed} ${policy}:`, JSON.stringify(d.n), 'minors_in', d.count('minors_in'), 'kept_out', d.count('kept_out'));
  return d;
}

play(1, 1180, 1530);
play(3, 1170, 1530);
console.log('lines used', mem.used.length, 'of', door.lines.filter((l) => !l.free).length);
