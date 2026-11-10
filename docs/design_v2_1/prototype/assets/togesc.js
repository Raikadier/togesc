/* TOGESC v2.1 — utilidades compartidas: prefs, datos de demo, shell, audio, piano, rueda. */
(function () {
  const LS = 'togesc.v21.';
  const store = {
    get(k, d) { try { const v = localStorage.getItem(LS + k); return v == null ? d : JSON.parse(v); } catch { return d; } },
    set(k, v) { try { localStorage.setItem(LS + k, JSON.stringify(v)); } catch {} },
  };

  /* ---------- Preferencias ---------- */
  const DEFAULT_PREFS = {
    reduceMotion: false, largeText: false, largePiano: false, hideLabels: false,
    notation: 'letters', autoAdvance: true, confirm: false, timbre: 'piano',
    volume: 70, octaveVar: true, cluster: true, roundGoal: 12, srsIntensity: 'normal',
    reminders: true, theme: 'light',
  };
  const prefs = Object.assign({}, DEFAULT_PREFS, store.get('prefs', {}));
  function setPref(k, v) { prefs[k] = v; store.set('prefs', prefs); applyPrefs(); }
  function applyPrefs() {
    const h = document.documentElement;
    h.classList.toggle('rm', !!prefs.reduceMotion);
    h.classList.toggle('lg-text', !!prefs.largeText);
    h.classList.toggle('lg-piano', !!prefs.largePiano);
    h.classList.toggle('theme-session', prefs.theme === 'dark' || (prefs.theme === 'system' && matchMedia('(prefers-color-scheme: dark)').matches));
  }
  const reduced = () => prefs.reduceMotion || matchMedia('(prefers-reduced-motion: reduce)').matches;
  applyPrefs();

  /* ---------- Notas ---------- */
  const LETTERS = ['C', 'C♯', 'D', 'D♯', 'E', 'F', 'F♯', 'G', 'G♯', 'A', 'A♯', 'B'];
  const SOLFEGE = ['Do', 'Do♯', 'Re', 'Re♯', 'Mi', 'Fa', 'Fa♯', 'Sol', 'Sol♯', 'La', 'La♯', 'Si'];
  const isBlack = i => [1, 3, 6, 8, 10].includes(i);
  const name = i => (prefs.notation === 'solfege' ? SOLFEGE : LETTERS)[i];
  const spoken = i => name(i).replace('♯', ' sostenido');

  /* ---------- Datos de demostración (sustituir por SRS real) ---------- */
  const NOTES = [
    { pct: 92, lvl: 5, att: 118, lat: 1.9 }, { pct: 42, lvl: 1, att: 96, lat: 3.9, due: true },
    { pct: 81, lvl: 4, att: 110, lat: 2.3 }, { pct: 58, lvl: 2, att: 101, lat: 3.2, due: true },
    { pct: 88, lvl: 5, att: 114, lat: 2.0 }, { pct: 74, lvl: 3, att: 108, lat: 2.6 },
    { pct: 38, lvl: 1, att: 99, lat: 4.1, due: true }, { pct: 90, lvl: 5, att: 116, lat: 1.8 },
    { pct: 64, lvl: 2, att: 104, lat: 3.0, due: true }, { pct: 79, lvl: 4, att: 112, lat: 2.4 },
    { pct: 47, lvl: 1, att: 98, lat: 3.7, due: true }, { pct: 71, lvl: 3, att: 108, lat: 2.7 },
  ];
  const saved = store.get('notes', null);
  if (saved && saved.length === 12) saved.forEach((n, i) => Object.assign(NOTES[i], n));
  const saveNotes = () => store.set('notes', NOTES.map(({ pct, lvl, att }) => ({ pct, lvl, att })));

  const totalAttempts = () => NOTES.reduce((s, n) => s + n.att, 0);
  const globalPct = () => NOTES.reduce((s, n) => s + n.pct * n.att, 0) / totalAttempts();
  const avgLatency = () => NOTES.reduce((s, n) => s + n.lat * n.att, 0) / totalAttempts();
  const state = pct => (pct < 50 ? 'critical' : pct < 75 ? 'progress' : 'solid');
  const STATE_LABEL = { critical: 'Crítica', progress: 'En curso', solid: 'Consolidada' };
  const focusNotes = (k = 3) => NOTES.map((n, i) => ({ i, ...n })).sort((a, b) => a.pct - b.pct).slice(0, k);

  function mClass(pct, lvl) {
    if (pct == null) return 'm-empty';
    if (pct < 35) return 'm-red-d';
    if (pct < 50) return 'm-red-l';
    if (pct < 63) return 'm-amb-l';
    if (pct < 75) return 'm-amb-d';
    return lvl >= 5 ? 'm-grn-3' : lvl === 4 ? 'm-grn-2' : 'm-grn-1';
  }
  const M_HEX = { 'm-red-d': '#C62828', 'm-red-l': '#FF8A8A', 'm-amb-l': '#FFC94D', 'm-amb-d': '#FFB300', 'm-grn-1': '#4E9A52', 'm-grn-2': '#38853C', 'm-grn-3': '#2E7D32', 'm-empty': '#F3ECF1' };
  const mHex = (p, l) => M_HEX[mClass(p, l)];
  const barOnDark = p => (p < 50 ? '#FF8A8A' : p < 75 ? '#FFC46B' : '#81C784');

  const HISTORY = [
    { mode: 'Una sola nota', icon: 'music_note', rounds: 8, hits: 6, when: 'Hace 2 h' },
    { mode: 'Sesión de hoy', icon: 'today', rounds: 12, hits: 9, when: 'Ayer · 20:14' },
    { mode: 'Velocidad · Pro', icon: 'bolt', rounds: 20, hits: 15, when: 'Ayer · 08:40' },
    { mode: 'Sesión de hoy', icon: 'today', rounds: 12, hits: 10, when: 'Hace 2 días' },
    { mode: 'Intervalo', icon: 'queue_music', rounds: 10, hits: 6, when: 'Hace 3 días' },
    { mode: 'Sesión de hoy', icon: 'today', rounds: 12, hits: 8, when: 'Hace 4 días' },
  ];
  const extra = store.get('history', []);
  const history = () => extra.concat(HISTORY);
  function logSession(s) { extra.unshift(s); store.set('history', extra.slice(0, 10)); }

  // Últimos 7 días, el último es hoy.
  const WEEK = ['missed', 'done', 'partial', 'done', 'done', 'done', 'today'];
  function week() {
    const days = WEEK.slice();
    const today = new Date().toDateString();
    if (store.get('doneOn', '') === today) days[6] = 'done';
    const d0 = new Date(); d0.setDate(d0.getDate() - 6);
    return days.map((s, k) => { const d = new Date(d0); d.setDate(d0.getDate() + k); return { s, d }; });
  }
  const practicedDays = () => week().filter(x => x.s === 'done' || x.s === 'partial').length;
  function streak() { const w = week(); let n = 0; for (let k = w[6].s === 'done' ? 6 : 5; k >= 0; k--) { if (w[k].s === 'done' || w[k].s === 'partial') n++; else break; } return n; }

  /* ---------- Shell ---------- */
  const DEST = [
    { id: 'home', href: 'home.html', icon: 'music_note', label: 'Práctica' },
    { id: 'progress', href: 'progress.html', icon: 'insights', label: 'Progreso' },
    { id: 'speed', href: 'speed.html', icon: 'bolt', label: 'Velocidad' },
    { id: 'profile', href: 'profile.html', icon: 'person', label: 'Perfil' },
  ];
  function shell(active) {
    const nb = document.getElementById('navbar'), rail = document.getElementById('rail');
    if (nb) nb.innerHTML = DEST.map(d => `<a class="nav-item" href="${d.href}" data-od-id="nav-${d.id}" ${d.id === active ? 'aria-current="page"' : ''}><span class="pill"><span class="ms ${d.id === active ? '' : 'o'}" aria-hidden="true">${d.icon}</span></span>${d.label}</a>`).join('');
    if (rail) rail.innerHTML = `<a class="rail-logo" href="home.html" aria-label="TOGESC, inicio">TG</a>` + DEST.map(d => `<a class="rail-item" href="${d.href}" data-od-id="rail-${d.id}" aria-label="${d.label}" ${d.id === active ? 'aria-current="page"' : ''}><span class="ms ${d.id === active ? '' : 'o'}" aria-hidden="true">${d.icon}</span><span class="tip" aria-hidden="true">${d.label}</span></a>`).join('') + `<span class="grow"></span><a class="rail-item" href="settings.html" aria-label="Ajustes"><span class="ms o" aria-hidden="true">settings</span><span class="tip" aria-hidden="true">Ajustes</span></a>`;
  }

  /* ---------- Feedback ---------- */
  function announce(msg, assertive) {
    let r = document.getElementById(assertive ? 'tg-live-a' : 'tg-live');
    if (!r) { r = document.createElement('div'); r.id = assertive ? 'tg-live-a' : 'tg-live'; r.className = 'sr-only'; r.setAttribute('aria-live', assertive ? 'assertive' : 'polite'); document.body.appendChild(r); }
    r.textContent = ''; setTimeout(() => { r.textContent = msg; }, 30);
  }
  let toastT;
  function toast(msg, icon = 'check_circle') {
    let t = document.getElementById('tg-toast');
    if (!t) { t = document.createElement('div'); t.id = 'tg-toast'; t.className = 'toast'; t.setAttribute('role', 'status'); document.body.appendChild(t); }
    t.innerHTML = `<span class="ms sm" aria-hidden="true">${icon}</span><span></span>`; t.lastChild.textContent = msg;
    t.classList.add('show'); clearTimeout(toastT); toastT = setTimeout(() => t.classList.remove('show'), 2600);
  }
  function countUp(el, to, dec = 0, suffix = '') {
    const fmt = v => v.toLocaleString('es-ES', { minimumFractionDigits: dec, maximumFractionDigits: dec }) + suffix;
    if (reduced()) { el.textContent = fmt(to); return; }
    const t0 = performance.now(), D = 900;
    (function f(t) { const p = Math.min(1, (t - t0) / D), e = 1 - Math.pow(1 - p, 3); el.textContent = fmt(to * e); if (p < 1) requestAnimationFrame(f); })(t0);
  }

  /* ---------- Audio (Web Audio, síntesis en cliente) ---------- */
  let ctx, master;
  function ac() {
    if (!ctx) { ctx = new (window.AudioContext || window.webkitAudioContext)(); master = ctx.createGain(); master.connect(ctx.destination); }
    if (ctx.state === 'suspended') ctx.resume();
    master.gain.value = (prefs.volume / 100) * 0.55;
    return ctx;
  }
  const TIMBRES = {
    piano: { label: 'Piano', parts: [1, .45, .22, .12, .06, .03], type: 'sine', decay: 1.6 },
    sine: { label: 'Sinusoidal', parts: [1], type: 'sine', decay: 0 },
    organ: { label: 'Órgano', parts: [1, .7, 0, .45, 0, .25], type: 'sine', decay: 0 },
    flute: { label: 'Flauta', parts: [1, .18, .05], type: 'sine', decay: 0, vib: 4.5 },
    violin: { label: 'Violín', parts: [1], type: 'sawtooth', decay: 0, vib: 5.5, lp: 2600 },
    guitar: { label: 'Guitarra', parts: [1, .5, .3], type: 'triangle', decay: .9 },
    trumpet: { label: 'Trompeta', parts: [1], type: 'square', decay: 0, lp: 1900 },
  };
  function playNote(midi, opts = {}) {
    const c = ac(), T = TIMBRES[opts.timbre || prefs.timbre] || TIMBRES.piano;
    const f0 = 440 * Math.pow(2, (midi - 69) / 12), t = c.currentTime + (opts.delay || 0), dur = opts.dur || 1.2;
    const g = c.createGain(); g.gain.setValueAtTime(0, t);
    g.gain.linearRampToValueAtTime(opts.gain || .9, t + .012);
    if (T.decay) g.gain.exponentialRampToValueAtTime(.0008, t + T.decay * dur);
    else { g.gain.setValueAtTime(opts.gain || .9, t + dur - .12); g.gain.linearRampToValueAtTime(0, t + dur); }
    let out = g;
    if (T.lp) { const f = c.createBiquadFilter(); f.type = 'lowpass'; f.frequency.value = T.lp; g.connect(f); out = f; }
    out.connect(master);
    const norm = 1 / T.parts.reduce((a, b) => a + b, 0);
    T.parts.forEach((amp, k) => {
      if (!amp) return;
      const o = c.createOscillator(), og = c.createGain();
      o.type = T.type; o.frequency.value = f0 * (k + 1); og.gain.value = amp * norm * (T.type === 'sine' ? 1 : .35);
      if (T.vib) { const l = c.createOscillator(), lg = c.createGain(); l.frequency.value = T.vib; lg.gain.value = f0 * .006; l.connect(lg).connect(o.frequency); l.start(t + .2); l.stop(t + dur + .1); }
      o.connect(og).connect(g); o.start(t); o.stop(t + (T.decay ? T.decay * dur : dur) + .05);
    });
    return dur;
  }
  function playCluster() {
    for (let k = 0; k < 9; k++) playNote(48 + Math.floor(Math.random() * 36), { timbre: 'sine', dur: .5, gain: .25, delay: k * .018 });
  }
  const midiFor = (i, octave = 4) => 12 * (octave + 1) + i;

  /* ---------- Piano ---------- */
  function piano(el, { onPress, start = 0 } = {}) {
    el.classList.add('piano');
    el.setAttribute('role', 'group'); el.setAttribute('aria-label', 'Teclado de una octava');
    const W = [0, 2, 4, 5, 7, 9, 11], B = [[1, 1], [3, 2], [6, 4], [8, 5], [10, 6]];
    const keys = {};
    const mk = (i, cls) => { const b = document.createElement('button'); b.type = 'button'; b.className = 'k ' + cls; b.dataset.note = i; b.innerHTML = `<span class="ms fb" aria-hidden="true"></span><span class="lbl">${name(i)}</span>`; b.setAttribute('aria-label', spoken(i)); keys[i] = b; return b; };
    W.forEach(i => el.appendChild(mk(i, 'w')));
    B.forEach(([i, pos]) => { const b = mk(i, 'b'); b.style.left = `calc(10px + (100% - 20px) * ${pos} / 7)`; el.appendChild(b); });
    function press(i, fromKeyboard) {
      const k = keys[i]; if (!k || k.disabled) return;
      k.classList.add('is-down'); setTimeout(() => k.classList.remove('is-down'), 140);
      if (!reduced()) { const r = document.createElement('span'); r.className = 'ripple'; k.appendChild(r); setTimeout(() => r.remove(), 600); }
      onPress && onPress(i, fromKeyboard);
    }
    el.addEventListener('click', e => { const k = e.target.closest('.k'); if (k) press(+k.dataset.note); });
    const api = {
      keys, press,
      set(i, cls, icon) { const k = keys[i]; k.classList.add(cls); if (icon) k.querySelector('.fb').textContent = icon; if (cls === 'is-correct' || cls === 'is-wrong') k.setAttribute('aria-label', spoken(i) + (cls === 'is-correct' ? ', correcta' : ', tu respuesta, incorrecta')); },
      reset() { Object.entries(keys).forEach(([i, k]) => { k.className = k.className.split(' ').filter(c => c === 'k' || c === 'w' || c === 'b').join(' '); k.querySelector('.fb').textContent = ''; k.setAttribute('aria-label', spoken(+i)); }); },
      dimExcept(list) { Object.entries(keys).forEach(([i, k]) => { if (!list.includes(+i)) k.classList.add('is-dim'); }); },
      disable(v) { Object.values(keys).forEach(k => { k.disabled = v; }); },
      relabel() { Object.entries(keys).forEach(([i, k]) => { k.querySelector('.lbl').textContent = name(+i); k.setAttribute('aria-label', spoken(+i)); }); },
    };
    el.classList.toggle('hide-labels', !!prefs.hideLabels);
    return api;
  }
  // Atajos A–G (+⇧ sostenido) → índice
  function keyToNote(e) {
    if (e.ctrlKey || e.altKey || e.metaKey) return null;
    if (e.target.closest('input, textarea, select')) return null;
    const base = { c: 0, d: 2, e: 4, f: 5, g: 7, a: 9, b: 11 }[e.key.toLowerCase()];
    if (base == null) return null;
    if (e.shiftKey) { if (base === 4 || base === 11) return null; return base + 1; }
    return base;
  }

  /* ---------- Rueda «Mapa del oído» ---------- */
  function sector(cx, cy, r0, r1, a0, a1) {
    const p = (r, a) => [cx + r * Math.sin(a), cy - r * Math.cos(a)];
    const [x0, y0] = p(r1, a0), [x1, y1] = p(r1, a1), [x2, y2] = p(r0, a1), [x3, y3] = p(r0, a0);
    const lg = a1 - a0 > Math.PI ? 1 : 0;
    return `M${x0.toFixed(2)} ${y0.toFixed(2)}A${r1} ${r1} 0 ${lg} 1 ${x1.toFixed(2)} ${y1.toFixed(2)}L${x2.toFixed(2)} ${y2.toFixed(2)}A${r0} ${r0} 0 ${lg} 0 ${x3.toFixed(2)} ${y3.toFixed(2)}Z`;
  }
  function wheel(host, { dark = false, onSelect, onHover, compact = false } = {}) {
    const S = 320, c = 160, r0 = compact ? 70 : 64, r1 = compact ? 132 : 126, rl = compact ? 148 : 146, step = Math.PI / 6, gap = .045;
    let html = `<svg class="wheel ${dark ? 'on-dark' : ''}" viewBox="-14 -14 ${S + 28} ${S + 28}" role="group" aria-label="Mapa del oído: dominio de las 12 notas">`;
    NOTES.forEach((n, i) => {
      const a0 = i * step - step / 2 + gap, a1 = (i + 1) * step - step / 2 - gap, am = i * step;
      const rf = r0 + (r1 - r0) * Math.max(.06, n.pct / 100);
      const lx = c + rl * Math.sin(am), ly = c - rl * Math.cos(am);
      html += `<g class="seg" data-note="${i}" tabindex="0" role="button" aria-label="${spoken(i)}, ${n.pct} %, ${STATE_LABEL[state(n.pct)].toLowerCase()}, nivel ${n.lvl} de 5" style="--i:${i}">
        <path class="seg-track" d="${sector(c, c, r0, r1, a0, a1)}"/>
        <path class="seg-fill" d="${sector(c, c, r0, rf, a0, a1)}" fill="${mHex(n.pct, n.lvl)}"/>
        <text class="seg-label" x="${lx.toFixed(1)}" y="${(ly + 4.5).toFixed(1)}" text-anchor="middle">${name(i)}</text>
      </g>`;
    });
    html += `</svg>`;
    host.innerHTML = html;
    host.querySelectorAll('.seg').forEach(g => {
      const i = +g.dataset.note;
      const act = () => { host.querySelectorAll('.seg').forEach(x => x.classList.toggle('is-active', x === g)); onSelect && onSelect(i); };
      g.addEventListener('click', act);
      g.addEventListener('keydown', e => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); act(); } });
      g.addEventListener('mouseenter', () => onHover && onHover(i));
      g.addEventListener('focus', () => onHover && onHover(i));
      g.addEventListener('mouseleave', () => onHover && onHover(null));
      g.addEventListener('blur', () => onHover && onHover(null));
    });
  }

  const dotsHTML = (lvl, max = 5) => `<span class="dots" aria-hidden="true">${Array.from({ length: max }, (_, k) => `<i class="${k < lvl ? 'on' : ''}"></i>`).join('')}</span>`;
  const fmtDate = d => d.toLocaleDateString('es-ES', { weekday: 'long', day: 'numeric', month: 'long' }).replace(/^./, s => s.toUpperCase());

  window.TG = { store, prefs, setPref, applyPrefs, reduced, LETTERS, SOLFEGE, isBlack, name, spoken, NOTES, saveNotes, totalAttempts, globalPct, avgLatency, state, STATE_LABEL, focusNotes, mClass, mHex, barOnDark, history, logSession, week, practicedDays, streak, shell, announce, toast, countUp, ac, TIMBRES, playNote, playCluster, midiFor, piano, keyToNote, wheel, dotsHTML, fmtDate };
})();
