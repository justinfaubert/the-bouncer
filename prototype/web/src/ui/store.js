// Saving. One slot, written after every choice (ironman: there's no going back to try again).
//
// The save lives in this browser's storage. If the page runs inside claude.ai and the player
// allows it, a copy also goes to their own private corner of the artifact's database
// (data/users/<their id>/save), so the night follows them to another device and Claude can
// read what they chose. Either can be missing; the game never waits on the cloud.
(function (B) {
  'use strict';

  const SAVE_KEY = 'bouncer.save.v1';
  const SETTINGS_KEY = 'bouncer.settings.v1';
  const MIN_GAP_MS = 1500;

  function lsGet(k) { try { return globalThis.localStorage.getItem(k); } catch (e) { return null; } }
  function lsSet(k, v) { try { globalThis.localStorage.setItem(k, v); return true; } catch (e) { return false; } }
  function lsDel(k) { try { globalThis.localStorage.removeItem(k); } catch (e) { /* storage blocked */ } }
  const wait = (ms) => new Promise((r) => setTimeout(r, ms));

  class Store {
    constructor() {
      this.db = null;
      this.uid = null;
      this.cloudState = 'off';   // off | on | denied | none
      this._job = null;
      this._busy = false;
      this._lastWrite = 0;
    }

    // ---- this browser --------------------------------------------------

    loadLocal() {
      const s = lsGet(SAVE_KEY);
      if (!s) return null;
      try { return JSON.parse(s); } catch (e) { return null; }
    }

    saveLocal(save) { return lsSet(SAVE_KEY, JSON.stringify(save)); }

    loadSettings(defaults) {
      const out = Object.assign({}, defaults);
      const s = lsGet(SETTINGS_KEY);
      if (s) { try { Object.assign(out, JSON.parse(s)); } catch (e) { /* ignore a bad value */ } }
      return out;
    }

    saveSettings(settings) { lsSet(SETTINGS_KEY, JSON.stringify(settings)); }

    // ---- both ----------------------------------------------------------

    save(save) {
      const ok = this.saveLocal(save);
      if (this.db) this._queue({ op: 'set', save: save });
      return ok;
    }

    clear() {
      lsDel(SAVE_KEY);
      if (this.db) this._queue({ op: 'delete' });
    }

    // ---- claude.ai -----------------------------------------------------

    // Resolves true when saves are going to the player's account. With ask=false it only
    // connects if permission was already given; with ask=true it may show the one dialog.
    async connect(ask) {
      if (this.db) return true;
      const c = globalThis.claude;
      if (!c || typeof c.use !== 'function') { this.cloudState = 'none'; return false; }
      let perms = null;
      try { perms = await c.use('permissions'); } catch (e) { perms = null; }
      if (perms) {
        let st = 'prompt';
        try { st = await perms.state('db'); } catch (e) { st = 'prompt'; }
        if (st === 'unavailable') { this.cloudState = 'none'; return false; }
        if (st === 'denied') { this.cloudState = 'denied'; return false; }
        if (st === 'prompt') {
          if (!ask) return false;
          let res = null;
          try { res = await perms.request(['db', 'user']); } catch (e) { res = null; }
          if (!res || res.db !== 'granted') { this.cloudState = 'denied'; return false; }
        }
      } else if (!ask) {
        return false;
      }
      let db = null, user = null, uid = null;
      try { db = await c.use('db'); } catch (e) { db = null; }
      try { user = await c.use('user'); } catch (e) { user = null; }
      if (!db || !user) { this.cloudState = 'none'; return false; }
      try { uid = await user.id(); } catch (e) { uid = null; }
      if (!uid) { this.cloudState = 'none'; return false; }
      this.db = db;
      this.uid = uid;
      this.cloudState = 'on';
      return true;
    }

    _ref() { return this.db.doc('data/users/' + this.uid + '/save'); }

    async loadCloud() {
      if (!this.db) return null;
      try {
        const snap = await this._ref().get();
        if (!snap.exists) return null;
        const d = snap.data();
        return d && d.save && d.save.game === 'the-bouncer' ? d.save : null;
      } catch (e) {
        return null;
      }
    }

    // One write at a time, only the newest save, and not more than one every MIN_GAP_MS.
    _queue(job) {
      this._job = job;
      if (!this._busy) this._drain();
    }

    async _drain() {
      this._busy = true;
      try {
        while (this._job && this.db) {
          const since = Date.now() - this._lastWrite;
          if (since < MIN_GAP_MS) await wait(MIN_GAP_MS - since);
          const job = this._job;
          this._job = null;
          try {
            if (job.op === 'delete') await this._ref().delete();
            else await this._ref().set({ savedAt: job.save.savedAt, build: job.save.build, turn: job.save.turn, save: job.save });
          } catch (e) {
            const code = e && e.code;
            if (code === 'unavailable' || code === 'resource_exhausted') {
              if (!this._job) this._job = job;
              await wait(4000);
            } else {
              // revoked, not granted, too big: keep playing on the local save
              this.db = null;
              this.cloudState = code === 'revoked' || code === 'not_granted' ? 'denied' : 'none';
            }
          }
          this._lastWrite = Date.now();
        }
      } finally {
        this._busy = false;
      }
    }
  }

  // Which of two saves is newer.
  Store.newer = function (a, b) {
    if (!a) return b || null;
    if (!b) return a;
    return String(b.savedAt || '') > String(a.savedAt || '') ? b : a;
  };

  B.Store = Store;
})(globalThis.Bouncer = globalThis.Bouncer || {});
