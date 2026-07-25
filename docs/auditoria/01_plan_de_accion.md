# Plan de acción — Backlog priorizado

Leyenda: **Severidad** CRÍTICO/ALTO/MEDIO/BAJO · **Esfuerzo** S (horas) / M (días) / L (semanas) · **Prioridad** P0 (bloquea release) / P1 / P2.

> Actualizado 2026-07-24. Los hallazgos de la auditoría original se conservan
> como historial, pero el estado operativo vigente está en
> [10_remediacion_2026-07-24.md](10_remediacion_2026-07-24.md).

## P0 — Bloqueante para lanzamiento

| ID | Tarea | Estado | Depende de |
|----|-------|--------|------------|
| SEC-003 | Entitlements server-owned y trial único | ✅ Aplicado (`20260724215043`) | — |
| SYNC-002 | Merge atómico por nota mediante RPC | ✅ Aplicado (`20260724215043`) | — |
| SEC-005 | Cerrar analytics y vistas de métricas | ✅ Aplicado (`…215043`, `…215232`) | — |
| DEPLOY-001 | Publicar build que usa `merge_user_progress` | ⏳ Bloquea el sync en la nube | — |
| SEC-004 | Activar candado Pro del sync | ✅ Aplicado (`20260724223000`) | Trial bootstrap a quien ya tenia progreso |
| SEC-006 | Crear Checkout Session Stripe server-side | ⏳ Pendiente | Edge Function + secretos |
| SEC-007 | Validar usuario en webhooks Stripe/RevenueCat | ⏳ Pendiente | Tests Deno |
| QA-001 | Sandbox pagos + sync web↔móvil | ⏳ Pendiente | DEPLOY-001 |

## P1 — Siguiente iteración

| ID | Tarea | Sev. | Esf. | Doc | Depende de |
|----|-------|------|------|-----|-----------|
| SEC-002 | Rate-limit + retención en `analytics_events` (anon) | ALTO | M | [10](10_remediacion_2026-07-24.md#sec-005--analytics-privados-y-acotados) | Allow-list ya aplicada |
| OBS-002 | Reportar errores manejados a Sentry | MEDIO | M | [10](10_remediacion_2026-07-24.md#p1) | — |
| TEST-002 | Tests SQL RLS/RPC + Deno webhooks | ALTO | M | [10](10_remediacion_2026-07-24.md#p0-antes-de-activar-pagos-reales) | Migración |
| FE-001 | Activar lint estricto gradualmente | MEDIO | S | [02](02_frontend.md#fe-001) | Baseline limpio |
| UX-001 | Completar tokens de tema oscuro faltantes | MEDIO | S | [05](05_ui_ux_accesibilidad.md#ux-001) | — |
| A11Y-002 | Respetar reduced-motion en piano y cluster | MEDIO | S | [08](08_performance_motion.md#a11y-002) | — |
| DEP-001 | Resolver 8 PRs Dependabot (majors) con verificación | MEDIO | M | [07](07_testing_ci_cd.md#dep-001) | FE-001 |

## P2 — Post-lanzamiento / pulido

| ID | Tarea | Sev. | Esf. | Doc |
|----|-------|------|------|-----|
| PROC-001 | Adoptar Conventional Commits + CONTRIBUTING.md | BAJO | S | [07](07_testing_ci_cd.md#proc-001) |
| FE-002 | `.gitignore` para `.tmp_stitch/`; commitear/limpiar sueltos | BAJO | S | [02](02_frontend.md#fe-002) |
| I18N-001 | Externalizar strings restantes + pseudo-localización | BAJO | M | [09](09_producto_cumplimiento_lanzamiento.md#i18n-001) |
| OBS-001 | Verificar Sentry en vivo + SLI/SLO documentados | BAJO | M | [06](06_arquitectura_system_design.md#obs-001) |

## Validaciones manuales pendientes (DoD de fases previas, aún abiertas)

- [x] Aplicar migración de hardening y verificar la matriz de privilegios.
- [ ] Desplegar la build que escribe mediante RPC (hasta entonces el sync falla).
- [ ] Sync mismo usuario web↔móvil ve las notas de ambos dispositivos.
- [ ] Compra sandbox iOS/Android + Stripe test mode.
- [ ] CI exitoso dispara exactamente un Deploy Web del mismo SHA.
- [ ] Lighthouse accesibilidad ≥ 90.
- [ ] Listing de stores + build iOS.

## Grafo de dependencias (resumen)

```
SEC-003 + SYNC-002 (aplicados) ──> DEPLOY-001 ──> QA-001
SEC-006 + SEC-007 ──────────────> sandbox pagos ──> SEC-004
TEST-002 ───────────────────────> release con pagos
```

## Lo que NO debe tocarse (evitar refactor innecesario)

- `srs_system.dart` — dominio puro, determinista, bien testeado.
- Migraciones SQL ya aplicadas — **inmutables**; cualquier cambio va en migración nueva.
- Estructura de capas y patrón Repository.
- Verificación de firma de Stripe (`constructEvent`) y uso de `service_role` solo en servidor.
