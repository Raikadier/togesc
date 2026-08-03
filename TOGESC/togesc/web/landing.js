(() => {
  const piano = document.getElementById('hero-piano');
  const promptText = document.getElementById('prompt-text');
  if (!piano || !promptText) return;

  const keys = [...piano.querySelectorAll('.key-w')];
  const labels = {
    C: 'Do',
    D: 'Re',
    E: 'Mi',
    F: 'Fa',
    G: 'Sol',
    A: 'La',
    B: 'Si',
    C2: 'Do',
    D2: 'Re',
    E2: 'Mi',
    F2: 'Fa',
    G2: 'Sol',
    A2: 'La',
    B2: 'Si',
  };

  let audioCtx = null;
  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

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

  function selectKey(key) {
    keys.forEach((k) => {
      const on = k === key;
      k.classList.toggle('is-selected', on);
      k.setAttribute('aria-pressed', on ? 'true' : 'false');
    });
    const note = key.dataset.note || '';
    const name = labels[note] || note;
    promptText.textContent = name ? `¿Era ${name}?` : '¿Qué nota escuchaste?';
    playTone(key.dataset.freq);
  }

  keys.forEach((key) => {
    key.addEventListener('click', () => selectKey(key));
  });

  if (!reduceMotion && 'IntersectionObserver' in window) {
    let i = keys.findIndex((k) => k.classList.contains('is-selected'));
    if (i < 0) i = 2;
    const stage = piano.closest('.session-stage');
    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return;
          i = (i + 1) % keys.length;
          keys.forEach((k, idx) => {
            const on = idx === i;
            k.classList.toggle('is-selected', on);
            k.setAttribute('aria-pressed', on ? 'true' : 'false');
          });
        });
      },
      { threshold: [0.35, 0.7] }
    );
    if (stage) io.observe(stage);
  }
})();
