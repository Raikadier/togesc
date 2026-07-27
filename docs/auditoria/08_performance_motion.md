# Performance y motion

> **Actualización 2026-07-26:** piano y cluster respetan reduced motion.
> Residual (hover bento, Lighthouse):
> [11_estado_pendiente_2026-07-26.md](11_estado_pendiente_2026-07-26.md).

Estándares: Core Web Vitals, 60 fps, GPU-friendly motion, prefers-reduced-motion (qstd §2.5, §9.5, §11.7).

## Lo que está bien (no tocar)
- **Síntesis/playback de audio en capas** separadas (`audio_generator.dart` puro + `audio_player_service.dart`), fuera del árbol de UI — evita jank por generación de buffers.
- Animaciones de tecla con `AnimatedContainer` a 50 ms y `transform` (GPU-friendly) en [piano_keyboard.dart:176](../../TOGESC/togesc/lib/widgets/piano_keyboard.dart#L176).
- `const` constructors en buena parte de los widgets.

## Hallazgos

### A11Y-002 — Reduced motion no aplicado a piano/cluster
- **Severidad:** MEDIO · **Esfuerzo:** S · **Prioridad:** P1
- **Evidencia:** [`piano_keyboard.dart`](../../TOGESC/togesc/lib/widgets/piano_keyboard.dart) consulta `MediaQuery.disableAnimationsOf`.
- **Estándar:** WCAG 2.2 — 2.3.1 (≤3 flashes/s), 2.2.1; qstd §9.5.3.
- **Estado 2026-07-24:** el piano atenúa duración de tecla y press delay cuando
  el sistema pide reduced motion. Pendiente: cluster de limpieza saltable y
  hover de bento.
- **Criterios de aceptación:**
  - [x] Piano respeta `disableAnimations` del sistema.
  - [ ] El cluster es saltable.
  - [ ] Hover/bento y demás motion no esencial respetan la preferencia.

> Nota: el plan 7D-4 ("reducir animaciones") sugiere que existe una preferencia; **verificar que está cableada al piano y al cluster**, no solo declarada.

### PERF-001 — Rebuilds: usar selectores
- **Severidad:** BAJO · **Esfuerzo:** S · **Prioridad:** P2
- **Evidencia:** widgets que hacen `ref.watch(provider)` del objeto completo (p. ej. estado de sesión) en lugar de `.select(...)`.
- **Estándar:** qstd §11.7 (rebuilds controlados).
- **Recomendación:** `ref.watch(gameSessionProvider.select((s) => s.phase))` donde solo se necesita una parte; `RepaintBoundary` alrededor de `piano_keyboard` y `result_card` (qstd §9.5.5).

### PERF-002 — Timers y dispose
- **Estado:** verificado 2026-07-24.
- `SpeedSessionNotifier.build()` registra
  `ref.onDispose(() => _countdownTimer?.cancel())`; las transiciones principales
  cancelan el timer antes de crear otro.
- **Criterios de aceptación:**
  - [x] Timer cancelado al abandonar el provider.
  - [ ] Perfilar buffers de audio en dispositivo real.

## Web / Core Web Vitals
- El sitio responde 200 pero el `time_total` medido fue ~7.5 s en frío (Flutter web + CanvasKit es pesado). **Pendiente de verificar** con Lighthouse: LCP/CLS reales, tamaño de bundle, y si conviene `--web-renderer html` o caché de `canvaskit`.
- Recomendación: medir Core Web Vitals y fijar un presupuesto en el deploy (qstd §2.5).

## Pendiente de verificar
- Medición real de fps en dispositivo con audio activo durante el cluster.
- Lighthouse performance en producción.
