# Auditoría técnica TOGESC — Índice maestro

- **Auditoría original:** 2026-06-24 (`8d4b6c0`)
- **Remediación:** 2026-07-24/25 ([10](10_remediacion_2026-07-24.md))
- **Estado pendiente:** 2026-07-26 ([11](11_estado_pendiente_2026-07-26.md))
- **Rúbrica:** [`docs/quality_standards.txt`](../quality_standards.txt)
- **Alcance auditado (evidencia real de código):** SRS, repositorios (local/híbrido/remoto), sync coordinator, edge functions (Stripe/RevenueCat), migraciones SQL, RLS, providers/guards de suscripción, `main.dart`, tema/design tokens, piano keyboard, configuración CI/CD (GitHub Actions), `vercel.json`, `pubspec.yaml`, `analysis_options.yaml`, inventario de tests.
- **No auditado por falta de material:** `Plan/system_design.md`, `gui_information_architecture.md`, manifests Android/iOS (permisos), Sentry en vivo, recorrido visual de motion en dispositivo. Ver [11](11_estado_pendiente_2026-07-26.md).

## Documentos

| Archivo | Contenido |
|---------|-----------|
| [01_plan_de_accion.md](01_plan_de_accion.md) | Backlog priorizado completo (P0→P2) con dependencias |
| [02_frontend.md](02_frontend.md) | Calidad de código Flutter/Riverpod, lint, estado |
| [03_backend_datos.md](03_backend_datos.md) | Supabase, RLS, migraciones, **sincronización**, webhooks |
| [04_seguridad.md](04_seguridad.md) | Entitlements, fail-open, idempotencia, abuso analytics |
| [05_ui_ux_accesibilidad.md](05_ui_ux_accesibilidad.md) | WCAG, piano, tokens, feedback, estados |
| [06_arquitectura_system_design.md](06_arquitectura_system_design.md) | Capas, patrones, resiliencia, observabilidad |
| [07_testing_ci_cd.md](07_testing_ci_cd.md) | Pirámide de tests, pipelines, Dependabot |
| [08_performance_motion.md](08_performance_motion.md) | Rebuilds, audio, motion, reduced-motion |
| [09_producto_cumplimiento_lanzamiento.md](09_producto_cumplimiento_lanzamiento.md) | i18n, GDPR, retención, distribución |
| [10_remediacion_2026-07-24.md](10_remediacion_2026-07-24.md) | Cambios aplicados 2026-07-24/25, validación SQL y deploy |
| [11_estado_pendiente_2026-07-26.md](11_estado_pendiente_2026-07-26.md) | **Qué falta hoy** (P0 pagos, P1 ops/a11y, P2 pulido) |

## Semáforo global por dimensión

| Dimensión | Estado | Comentario |
|-----------|:------:|------------|
| Arquitectura de software | 🟢 | Capas limpias, Repository, DI en SRS. No tocar. |
| Backend / datos / RLS | 🟢 | Merge atómico, entitlements y candado Pro del sync en producción. |
| Seguridad | 🟡 | Escalada Pro y métricas cerradas; falta Checkout/webhooks hardenizados. |
| Frontend / código | 🟢 | Bien estructurado; falta lint estricto. |
| UI/UX | 🟡 | Tokens dark y landing mejorados; estados en ajustes y contraste medido pendientes. |
| Accesibilidad | 🟡 | Piano + cluster con reduced motion; falta Lighthouse ≥ 90 y motion residual. |
| Testing | 🟡 | Suite Flutter sólida; faltan SQL/Deno webhooks y E2E reales. |
| CI/CD | 🟡 | Deploy publicado; falta observar CI→Deploy en push a `main` y pipeline iOS. |
| Performance / motion | 🟢 | Audio en capas; reduced-motion parcial verificado. |
| Producto / cumplimiento | 🟡 | GDPR (borrar/exportar) OK; retención analytics y privacidad exacta pendientes. |

🟢 sólido · 🟡 mejorable / con riesgos acotados · 🔴 bloqueante

## Definition of Done — "listo para mercado"

TOGESC se considera **listo para lanzamiento profesional** cuando:

- [x] **Sin pérdida de datos** por overwrite remoto (SYNC-002 + DEPLOY-001).
- [x] **Entitlements de escritura** bloqueados al cliente (SEC-003) y **sync Pro en servidor** (SEC-004).
- [ ] **Sandbox de pagos** + sync web↔móvil (QA-001).
- [ ] **Checkout + webhooks** hardenizados (SEC-006/007/008 + TEST-002).
- [ ] **Analytics** con rate-limit y retención (SEC-002).
- [ ] **Accesibilidad AA** medida (Lighthouse ≥ 90) y reduced-motion residual.
- [ ] **Pipelines**: CI→Deploy observado en push a `main`; iOS documentado o en pipeline.
- [ ] **Lint estricto** en CI; commits convencionales (FE-001, PROC-001).
- [ ] Dependencias al día (DEP-001).
- [ ] Política de privacidad + retención publicadas y exactas; permisos móviles justificados.

Detalle y criterios de cierre: [11_estado_pendiente_2026-07-26.md](11_estado_pendiente_2026-07-26.md).

## Resumen ejecutivo

Proyecto maduro. La remediación de julio de 2026 cerró en producción la
escalada Pro, la exposición de métricas, el merge atómico, el candado Pro del
sync (con trial bootstrap) y publicó la build web que escribe vía RPC. El
bloqueante restante para cobrar de verdad es el **camino de pagos**
(Checkout server-side, validación de webhooks, idempotencia atómica, sandbox)
más la validación operativa sync web↔móvil. Ver
[11_estado_pendiente_2026-07-26.md](11_estado_pendiente_2026-07-26.md).
