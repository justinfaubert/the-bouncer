// Small helpers shared by the engine and the UI. No DOM here: this file also runs in Node (tools/bots.mjs).
(function (B) {
  'use strict';

  // The shift clock counts minutes from the midnight *before* the shift starts,
  // so 7:40 pm is 1180 and 1:30 am is 1530. It never wraps.
  function clockParts(min) {
    const m = ((Math.round(min) % 1440) + 1440) % 1440;
    const h24 = Math.floor(m / 60);
    const mm = m % 60;
    const ampm = h24 < 12 ? 'am' : 'pm';
    let h = h24 % 12;
    if (h === 0) h = 12;
    return { h: h, m: mm, ampm: ampm, text: h + ':' + String(mm).padStart(2, '0') };
  }

  function fmtClock(min) {
    const p = clockParts(min);
    return p.text + ' ' + p.ampm;
  }

  function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }

  function escapeHtml(s) {
    return String(s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }

  // "key: value" tag parsing. A bare tag ("pause") has value true.
  function parseTag(tag) {
    const t = String(tag).trim();
    const i = t.indexOf(':');
    if (i === -1) return { key: t.toLowerCase(), value: true };
    return { key: t.slice(0, i).trim().toLowerCase(), value: t.slice(i + 1).trim() };
  }

  function deepClone(o) { return o == null ? o : JSON.parse(JSON.stringify(o)); }

  // FNV-1a, for seeding the hand's and the town's own random numbers (godot/engine/util.gd hash32)
  function hash32(str) {
    let h = 0x811c9dc5;
    for (let i = 0; i < str.length; i++) { h ^= str.charCodeAt(i); h = Math.imul(h, 0x01000193); }
    return h >>> 0;
  }

  B.util = { clockParts: clockParts, fmtClock: fmtClock, clamp: clamp, escapeHtml: escapeHtml, parseTag: parseTag, deepClone: deepClone, hash32: hash32 };
})(globalThis.Bouncer = globalThis.Bouncer || {});
