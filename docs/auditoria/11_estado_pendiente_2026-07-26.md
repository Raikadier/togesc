# Estado pendiente — 2026-07-26

Documento de seguimiento tras la remediación del 2026-07-24/25
([10_remediacion_2026-07-24.md](10_remediacion_2026-07-24.md)) y el despliegue
en producción (`63eb776` → [togesc.vercel.app](https://togesc.vercel.app)).

No sustituye los hallazgos históricos de 02–09: consolida **qué ya no es
problema** y **qué sigue abierto**, con prioridad y criterio de cierre.

---

## Ya cerrado (no reabrir como P0)

| ID | Qué | Evidencia |
|----|-----|-----------|
| SEC-003 | Entitlements server-owned; trial único vía RPC | Migración `20260724215043` |
| SEC-004 | Candado Pro del sync (`has_cloud_sync_access`) | Migración `20260725033417` + trial bootstrap 14 días a quien ya tenía progreso |
| SEC-005 | Analytics sin SELECT cliente; vistas `security_invoker`; allow-list y límite 4 KiB | `…215043`, `…215232` |
| SYNC-002 | Merge atómico por nota (`merge_user_progress`) | RPC en producción + cliente |
| DEPLOY-001 | Build web con RPC publicada | Deploy Web `30142644096` → `togesc.vercel.app` |
| UX-001 (parcial) | Tokens semánticos dark vía `TogescColors` | `togesc_colors.dart` + consumidores |
| A11Y-002 (parcial) | Piano y cluster respetan reduced motion | `piano_keyboard`, `game_session_provider` |
| UI-landing | Landing sin emojis, hero de producto, `prefers-reduced-motion` | `web/landing.html` / `landing.css` |
| CI-002 (config) | Deploy condicionado a CI + Flutter pin `3.41.4` | workflows + `vercel.json` ignore |

---

## P0 — Bloqueante para cobrar de verdad

### SEC-006 — Checkout Session Stripe creada en el servidor

- **Problema:** el cliente no debe construir ni confiar en
  `client_reference_id` / URLs de checkout manipulables.
- **Qué falta:** Edge Function (o backend) que cree la Session con
  `customer`/`client_reference_id` ligados a `auth.uid()`, y secretos solo en
  servidor.
- **Criterio de cierre:** compra test mode sin que el navegador pueda asociar
  el pago a otro `user_id`.
- **Doc relacionada:** [04_seguridad.md](04_seguridad.md)

### SEC-007 — Validar identidad en webhooks Stripe / RevenueCat

- **Problema:** el webhook debe rechazar eventos cuyo usuario no exista o no
  coincida con el entitlement esperado.
- **Qué falta:** validar `app_user_id` / customer contra `auth.users` (y
  mapping Stripe); tests Deno.
- **Criterio de cierre:** evento con usuario inventado no concede Pro.
- **Doc relacionada:** [03_backend_datos.md](03_backend_datos.md),
  [04_seguridad.md](04_seguridad.md)

### SEC-008 — Idempotencia atómica de webhooks

- **Problema:** la tabla `processed_webhook_events` existe, pero el flujo debe
  ser insert-before-side-effect (o equivalente) sin ventana de doble
  aplicación bajo reintentos concurrentes.
- **Qué falta:** revisar Edge Functions y tests de carrera.
- **Criterio de cierre:** el mismo `event.id` aplicado en paralelo solo ejecuta
  el side-effect una vez.

### TEST-002 — Tests SQL RLS/RPC + Deno webhooks

- **Problema:** la matriz de privilegios se validó a mano; no hay suite
  automatizada que impida regresiones.
- **Qué falta:** tests de políticas (anon/authenticated/service_role), RPC
  trial/merge, y Deno para firmas + rechazo de identidad inválida.
- **Criterio de cierre:** CI o job dedicado falla si se reabre INSERT en
  `user_subscriptions` o si el merge acepta payload inválido.

### QA-001 — Sandbox pagos + sync web↔móvil

- **Problema:** DEPLOY-001 ya publicó el cliente, pero no hay evidencia de
  extremo a extremo con dinero de prueba y dos dispositivos.
- **Qué falta:**
  - [ ] Stripe test mode + portal
  - [ ] RevenueCat sandbox iOS/Android
  - [ ] Mismo usuario: nota creada en web aparece en móvil y viceversa
  - [ ] Usuario free no sincroniza; Pro/trial sí
- **Criterio de cierre:** checklist anterior firmada con capturas/logs.

---

## P1 — Siguiente iteración (calidad / ops / a11y)

### SEC-002 — Rate-limit y retención de analytics

- Allow-list y tamaño de payload ya están. Falta límite por IP/identidad en
  borde y política de borrado/agregación temporal.
- Criterio: abuso de `INSERT` anon no satura la tabla; retención documentada
  en privacidad.

### AUTH-001 — Protección de contraseñas filtradas

- Aviso Supabase Auth: HaveIBeenPwned desactivado.
- Criterio: activado en el panel del proyecto.

### OBS-002 — Errores manejados a Sentry

- Sync, audio y pagos aún pueden fallar en silencio o solo con SnackBar.
- Criterio: `Sentry.captureException` (o equivalente) en catch críticos con
  tags de dominio.

### UX-003 — Errores invisibles en ajustes

- Varias secciones usan `SizedBox.shrink()` / hide en `error:`.
- Criterio: mensaje + reintento coherente con Estadísticas / Progreso.

### A11Y-002b — Reduced motion residual

- Piano y cluster ya saltan/atenúan. Falta hover de bento y demás motion no
  esencial.
- Criterio: con `disableAnimations` / preferencia de usuario, no hay
  animaciones decorativas.

### A11Y-003 — Contraste instrumental + Lighthouse

- Tokens dark definidos; no medidos con herramienta.
- Criterio: pares AA documentados; Lighthouse Accessibility ≥ 90 en
  producción / promo.

### TEST-003 — E2E reales

- Chrome (web) y Android: login, una ronda, sync, paywall smoke.
- Criterio: al menos un job E2E en CI o nightly.

### OPS-001 — Backup restore

- Verificar restauración de copia de seguridad Supabase (drill).
- Criterio: restore a staging documentado.

### CI-003 — Observar CI → Deploy encadenado

- Configuración lista; el deploy del 2026-07-25 fue por `workflow_dispatch`.
- Criterio: un push a `main` con CI verde dispara exactamente un Deploy del
  mismo SHA.

---

## P2 — Post-lanzamiento / pulido

| ID | Tarea |
|----|-------|
| I18N-001 | Migración progresiva de strings a ARB + pseudo-localización |
| PERF-003 | Presupuesto de rendimiento (Lighthouse Performance / bundle) |
| INFRA-IOS | Pipeline de build iOS |
| PROC-001 | `CONTRIBUTING.md` + Conventional Commits |
| WEB-001 | `robots.txt`, sitemap, canonical |
| FE-001 | Lint estricto gradual en CI |
| DEP-001 | Resolver PRs Dependabot majors con verificación |
| FE-002 | Ignorar / limpiar `.tmp_stitch/` |
| OBS-001 | Verificar Sentry en vivo + SLI/SLO |
| PRIV-001 | Política de privacidad + retención exactas; permisos móviles justificados |

---

## Riesgos que NO deben declararse resueltos

- Pagos reales sin Checkout server-side ni sandbox pasado.
- Entitlement offline firmado (fail-closed actual puede bloquear Pro sin red).
- Rate-limit efectivo de analytics.
- Contraste AA medido píxel a píxel.
- Pipeline iOS y E2E de micrófono/audio/compras en dispositivo real.
- CI→Deploy observado en un push ordinario a `main` (solo `workflow_dispatch`
  verificado el 2026-07-25).

---

## Definition of Done — mercado (actualizado)

TOGESC se considera listo para lanzamiento profesional cuando:

- [x] Sin pérdida de datos por overwrite remoto (SYNC-002 + DEPLOY-001).
- [x] Escritura de suscripciones bloqueada al cliente (SEC-003).
- [x] Sync en la nube exige Pro en servidor (SEC-004).
- [ ] Sandbox de pagos + sync web↔móvil (QA-001).
- [ ] Checkout y webhooks hardenizados (SEC-006/007/008 + TEST-002).
- [ ] Analytics con rate-limit y retención (SEC-002).
- [ ] Accesibilidad AA medida (A11Y-003) y reduced-motion residual (A11Y-002b).
- [ ] Pipelines verdes observados CI→Deploy (CI-003); iOS al menos documentado.
- [ ] Privacidad / retención publicadas y exactas (PRIV-001).

---

## Próximo paso recomendado

Orden práctico para desbloquear cobros:

```
SEC-006 + SEC-007 + SEC-008 ──> TEST-002 ──> QA-001 ──> release con pagos
SEC-002 + AUTH-001 en paralelo (bajo riesgo)
```
