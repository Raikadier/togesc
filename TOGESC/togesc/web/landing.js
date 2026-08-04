(() => {
  const piano = document.getElementById('hero-piano');
  const promptText = document.getElementById('prompt-text');
  const promptEl = document.getElementById('session-prompt');
  const listenBtn = document.getElementById('demo-listen');
  const nextBtn = document.getElementById('demo-next');
  const hint = document.getElementById('demo-hint');
  if (!piano || !promptText || !listenBtn || !nextBtn) return;

  const keys = [...piano.querySelectorAll('.key-w')];
  const labels = {
    C: 'Do',
    D: 'Re',
    E: 'Mi',
    F: 'Fa',
    G: 'Sol',
    A: 'La',
    B: 'Si',
  };

  let audioCtx = null;
  let targetKey = null;
  let phase = 'idle'; // idle | listening | answered
  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  function pitchClass(note) {
    return String(note || '').replace(/[0-9]/g, '');
  }

  function ensureAudio() {
    if (!audioCtx) {
      const Ctx = window.AudioContext || window.webkitAudioContext;
      if (!Ctx) return null;
      audioCtx = new Ctx();
    }
    if (audioCtx.state === 'suspended') audioCtx.resume();
    return audioCtx;
  }

  function playTone(freq) {
    const ctx = ensureAudio();
    if (!ctx) return;
    const now = ctx.currentTime;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(Number(freq), now);
    gain.gain.setValueAtTime(0.0001, now);
    gain.gain.exponentialRampToValueAtTime(0.12, now + 0.02);
    gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.55);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start(now);
    osc.stop(now + 0.6);
  }

  function clearKeyStates() {
    keys.forEach((k) => {
      k.classList.remove('is-selected', 'is-correct', 'is-wrong');
      k.setAttribute('aria-pressed', 'false');
    });
    promptEl?.classList.remove('is-correct', 'is-wrong');
  }

  function pickTarget() {
    targetKey = keys[Math.floor(Math.random() * keys.length)];
  }

  function setPhase(next) {
    phase = next;
    const answering = phase === 'listening';
    keys.forEach((k) => {
      k.disabled = !answering;
    });
    listenBtn.hidden = phase === 'answered';
    nextBtn.hidden = phase !== 'answered';
    if (phase === 'idle') {
      listenBtn.textContent = 'Escuchar';
      promptText.textContent = 'Escucha la nota y elige en el piano';
      if (hint) {
        hint.textContent = 'Pulsa Escuchar, luego toca la tecla que creas correcta.';
      }
    }
  }

  function startRound() {
    clearKeyStates();
    pickTarget();
    setPhase('listening');
    promptText.textContent = '¿Qué nota escuchaste?';
    if (hint) hint.textContent = 'Puedes pulsar Escuchar de nuevo si lo necesitas.';
    listenBtn.textContent = 'Repetir';
    if (targetKey) playTone(targetKey.dataset.freq);
  }

  function answerWith(key) {
    if (phase !== 'listening' || !targetKey) return;
    const ok = pitchClass(key.dataset.note) === pitchClass(targetKey.dataset.note);
    clearKeyStates();
    key.classList.add(ok ? 'is-correct' : 'is-wrong');
    key.setAttribute('aria-pressed', 'true');
    targetKey.classList.add('is-correct');
    const name = labels[pitchClass(targetKey.dataset.note)] || targetKey.dataset.note;
    promptText.textContent = ok ? `Correcto — ${name}` : `Incorrecto — era ${name}`;
    promptEl?.classList.add(ok ? 'is-correct' : 'is-wrong');
    if (hint) {
      hint.textContent = ok
        ? 'Buena lectura. Prueba otra ronda o entra a entrenar de verdad.'
        : 'La clase de altura importa más que la octava. Siguiente ronda cuando quieras.';
    }
    playTone(key.dataset.freq);
    setPhase('answered');
  }

  listenBtn.addEventListener('click', () => {
    if (phase === 'answered') return;
    if (phase === 'idle') startRound();
    else if (targetKey) playTone(targetKey.dataset.freq);
  });

  nextBtn.addEventListener('click', () => startRound());

  keys.forEach((key) => {
    key.addEventListener('click', () => answerWith(key));
  });

  document.querySelectorAll('a[href="#demo"]').forEach((link) => {
    link.addEventListener('click', () => {
      window.setTimeout(() => {
        if (phase === 'idle') startRound();
      }, reduceMotion ? 0 : 280);
    });
  });

  setPhase('idle');
})();
