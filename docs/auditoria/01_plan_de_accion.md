# Plan de acción — Backlog priorizado

Leyenda: **Severidad** CRÍTICO/ALTO/MEDIO/BAJO · **Esfuerzo** S (horas) / M (días) / L (semanas) · **Prioridad** P0 (bloquea release) / P1 / P2.

> Actualizado 2026-07-26. Estado operativo vigente:
> [11_estado_pendiente_2026-07-26.md](11_estado_pendiente_2026-07-26.md).
> Historial de remediación: [10_remediacion_2026-07-24.md](10_remediacion_2026-07-24.md).

## P0 — Bloqueante para cobrar / lanzamiento con pagos

| ID | Tarea | Estado | Depende de |
|----|-------|--------|------------|
| SEC-003 | Entitlements server-owned y trial único | ✅ Aplicado (`20260724215043`) | — |
| SYNC-002 | Merge atómico por nota mediante RPC | ✅ Aplicado (`20260724215043`) | — |
| SEC-005 | Cerrar analytics y vistas de métricas | ✅ Aplicado (`…215043`, `…215232`) | — |
| SEC-004 | Activar candado Pro del sync | ✅ Aplicado (`20260725033417`) | Trial bootstrap |
| DEPLOY-001 | Publicar build que usa `merge_user_progress` | ✅ `togesc.vercel.app` (`63eb776`) | — |
| SEC-006 | Crear Checkout Session Stripe server-side | ⏳ Pendiente | Edge Function + secretos |
| SEC-007 | Validar usuario en webhooks Stripe/RevenueCat | ⏳ Pendiente | Tests Deno |
| SEC-008 | Idempotencia atómica de webhooks | ⏳ Pendiente | SEC-007 |
| TEST-002 | Tests SQL RLS/RPC + Deno webhooks | ⏳ Pendiente | Migraciones aplicadas |
| QA-001 | Sandbox pagos + sync web↔móvil | ⏳ Pendiente | SEC-006/007 + DEPLOY-001 |

## P1 — Siguiente iteración

| ID | Tarea | Sev. | Esf. | Doc | Depende de |
|----|-------|------|------|-----|-----------|
| SEC-002 | Rate-limit + retención en `analytics_events` | ALTO | M | [11](11_estado_pendiente_2026-07-26.md#sec-002--rate-limit-y-retención-de-analytics) | Allow-list ya aplicada |
| AUTH-001 | Activar protección de contraseñas filtradas | MEDIO | S | [11](11_estado_pendiente_2026-07-26.md#auth-001--protección-de-contraseñas-filtradas) | Panel Auth |
| OBS-002 | Reportar errores manejados a Sentry | MEDIO | M | [11](11_estado_pendiente_2026-07-26.md#obs-002--errores-manejados-a-sentry) | — |
| UX-003 | Errores visibles en secciones de ajustes | MEDIO | S | [11](11_estado_pendiente_2026-07-26.md#ux-003--errores-invisibles-en-ajustes) | — |
| A11Y-002b | Reduced-motion residual (hover bento, etc.) | MEDIO | S | [11](11_estado_pendiente_2026-07-26.md#a11y-002b--reduced-motion-residual) | Piano/cluster OK |
| A11Y-003 | Contraste instrumental + Lighthouse ≥ 90 | MEDIO | M | [11](11_estado_pendiente_2026-07-26.md#a11y-003--contraste-instrumental--lighthouse) | — |
| TEST-003 | E2E reales Chrome/Android | ALTO | M | [11](11_estado_pendiente_2026-07-26.md#test-003--e2e-reales) | — |
| OPS-001 | Drill de restauración de backups | MEDIO | M | [11](11_estado_pendiente_2026-07-26.md#ops-001--backup-restore) | — |
| CI-003 | Observar CI→Deploy en push a `main` | MEDIO | S | [11](11_estado_pendiente_2026-07-26.md#ci-003--observar-ci--deploy-encadenado) | Config lista |
| FE-001 | Activar lint estricto gradualmente | MEDIO | S | [02](02_frontend.md) | Baseline limpio |
| DEP-001 | Resolver PRs Dependabot (majors) | MEDIO | M | [07](07_testing_ci_cd.md) | FE-001 |

## P2 — Post-lanzamiento / pulido

| ID | Tarea | Sev. | Esf. | Doc |
|----|-------|------|------|-----|
| PROC-001 | Conventional Commits + CONTRIBUTING.md | BAJO | S | [11](11_estado_pendiente_2026-07-26.md#p2--post-lanzamiento--pulido) |
| FE-002 | `.gitignore` para `.tmp_stitch/` | BAJO | S | [11](11_estado_pendiente_2026-07-26.md#p2--post-lanzamiento--pulido) |
| I18N-001 | Externalizar strings + ARB | BAJO | M | [09](09_producto_cumplimiento_lanzamiento.md) |
| PERF-003 | Presupuesto Lighthouse / bundle | BAJO | M | [11](11_estado_pendiente_2026-07-26.md#p2--post-lanzamiento--pulido) |
| INFRA-IOS | Pipeline de build iOS | BAJO | L | [11](11_estado_pendiente_2026-07-26.md#p2--post-lanzamiento--pulido) |
| WEB-001 | robots, sitemap, canonical | BAJO | S | [11](11_estado_pendiente_2026-07-26.md#p2--post-lanzamiento--pulido) |
| OBS-001 | Sentry en vivo + SLI/SLO | BAJO | M | [06](06_arquitectura_system_design.md) |
| PRIV-001 | Privacidad + retención exactas | MEDIO | M | [09](09_producto_cumplimiento_lanzamiento.md) |

## Validaciones manuales

- [x] Aplicar migración de hardening y verificar la matriz de privilegios.
- [x] Desplegar la build que escribe mediante RPC (`togesc.vercel.app`).
- [x] Activar candado Pro del sync (+ trial bootstrap).
- [ ] Sync mismo usuario web↔móvil ve las notas de ambos dispositivos.
- [ ] Compra sandbox iOS/Android + Stripe test mode.
- [ ] CI exitoso dispara exactamente un Deploy Web del mismo SHA (push a `main`).
- [ ] Lighthouse accesibilidad ≥ 90.
- [ ] Listing de stores + build iOS.

## Grafo de dependencias (resumen)

```
SEC-003 + SYNC-002 + SEC-004 + DEPLOY-001 (hechos)
SEC-006 + SEC-007 + SEC-008 ──> TEST-002 ──> QA-001 ──> release con pagos
SEC-002 + AUTH-001 ───────────> (paralelo, bajo riesgo de regresión)
CI-003 / A11Y-003 / TEST-003 ─> confianza operativa
```

## Lo que NO debe tocarse (evitar refactor innecesario)

- `srs_system.dart` — dominio puro, determinista, bien testeado.
- Migraciones SQL ya aplicadas — **inmutables**; cualquier cambio va en migración nueva.
- Estructura de capas y patrón Repository.
- Verificación de firma de Stripe (`constructEvent`) y uso de `service_role` solo en servidor.
- `has_cloud_sync_access` como único punto de decisión del sync — no duplicar lógica en políticas.
