# Arquitectura de software y system design

Estándares: Clean/Hexagonal, DDD, patrones GoF, KISS/YAGNI, C4, resiliencia, observabilidad (qstd §4, §5, §10).

## Lo que está bien (no tocar)
- **Capas con dependencias correctas**: UI → navegación (GoRouter) → providers → services → dominio. Infraestructura implementa interfaces internas (DIP).
- **Patrones aplicados correctamente**:
  - *Repository*: `ProgressRepository` (local / Supabase / híbrido).
  - *Adapter*: `AudioPlayerService` envuelve `flutter_soloud`; split `*_io/_web/_stub`.
  - *State*: máquina de estados de sesión (idle/listening/answer/result/cluster).
  - *Strategy*: `SrsIntensityProfile`, resolución de instrumento.
- **Offline-first** sin bloquear el juego: `save()` persiste local primero y marca pendiente si el remoto falla ([hybrid_progress_repository.dart:67](../../TOGESC/togesc/lib/services/hybrid_progress_repository.dart#L67)). Resiliencia correcta a nivel "no romper UX".
- BaaS monolítico (Supabase) adecuado a la escala; sin microservicios prematuros (YAGNI respetado).

## Hallazgos

### ARCH-001 — Resiliencia de sync sin backoff ni reintento programado
- **Severidad:** MEDIO · **Esfuerzo:** M · **Prioridad:** P1
- **Evidencia:** `flushPendingSync` ([:84](../../TOGESC/togesc/lib/services/hybrid_progress_repository.dart#L84)) solo se ejecuta en disparadores explícitos (`afterLocalSave`, login, botón). El `catch (_)` descarta el error sin reintento con backoff.
- **Estándar:** qstd §5.3 (retry con backoff exponencial), §10.3.
- **Problema:** si el push falla, queda "pending" hasta el próximo disparador manual; no hay reintento automático al recuperar conectividad.
- **Recomendación:** suscribirse a cambios de conectividad y reintentar con backoff; o reintentar en `resume` de la app. Documentar la política.
- **Criterios de aceptación:**
  - [ ] Tras fallo de red, el progreso pendiente se sube automáticamente al reconectar.
  - [ ] Reintentos con backoff acotado (evitar tormenta).

### ARCH-002 — Eventos de dominio implícitos
- **Severidad:** BAJO · **Esfuerzo:** M · **Prioridad:** P2
- **Evidencia:** analytics y sync se invocan imperativamente desde providers/listeners.
- **Estándar:** DDD (eventos de dominio `NoteReviewed`/`SessionCompleted`, qstd §4.2).
- **Recomendación:** considerar un bus de eventos de dominio para desacoplar analytics/sync del flujo de juego. Mejora testabilidad y evita acoplar el provider de juego a Sentry/analytics. No urgente.

### OBS-001 — Observabilidad: verificar extremo a extremo
- **Severidad:** BAJO · **Esfuerzo:** M · **Prioridad:** P2
- **Evidencia:** [`main.dart:21`](../../TOGESC/togesc/lib/main.dart#L21) inicializa Sentry con `tracesSampleRate=0.2`, release `togesc@1.0.0` fijo. Hay vistas `metrics_daily`/`metrics_csat_daily`.
- **Problema/observaciones:**
  - `options.release = 'togesc@1.0.0'` está **hardcodeado**: no rastreará releases futuras correctamente. Derivarlo de `pubspec`/`--dart-define`.
  - No hay SLI/SLO documentados pese a que qstd §5.5 los define como objetivo.
- **Recomendación:** release dinámica; documentar SLI/SLO (disponibilidad ≥99.9% en `/`, error <0.1% en webhooks) y un runbook básico de incidentes (sync caído, webhook duplicado).
- **Criterios de aceptación:**
  - [ ] `options.release` refleja la versión real del build.
  - [ ] SLI/SLO y runbooks en `docs/`.

## Diagramas C4 (recomendación de proceso)
qstd §5.1 los pide; no existen en el repo. Sugerido añadir al menos Context + Container en `Plan/system_design.md` (Flutter web/móvil ↔ Supabase ↔ Stripe/RevenueCat ↔ Vercel ↔ Sentry).

## Pendiente de verificar
- `Plan/system_design.md` real (no leído) — puede ya cubrir parte de C4/secuencias.
- Comportamiento de `SpeedSessionProvider` con `Timer.periodic` respecto a fugas (ver [08_performance_motion.md](08_performance_motion.md)).
