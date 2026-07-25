# Auditoría técnica TOGESC — Índice maestro

- **Auditoría original:** 2026-06-24 (`8d4b6c0`)
- **Revisión y remediación:** 2026-07-24
- **Rúbrica:** [`docs/quality_standards.txt`](../quality_standards.txt)
- **Alcance auditado (evidencia real de código):** SRS, repositorios (local/híbrido/remoto), sync coordinator, edge functions (Stripe/RevenueCat), migraciones SQL, RLS, providers/guards de suscripción, `main.dart`, tema/design tokens, piano keyboard, configuración CI/CD (GitHub Actions), `vercel.json`, `pubspec.yaml`, `analysis_options.yaml`, inventario de tests.
- **No auditado por falta de material:** `Plan/system_design.md`, `gui_information_architecture.md`, manifests Android/iOS (permisos), Sentry en vivo, recorrido visual de motion en dispositivo. Ver sección "Pendiente de verificar".

## Documentos

| Archivo | Contenido |
|---------|-----------|
| [01_plan_de_accion.md](01_plan_de_accion.md) | Backlog priorizado completo (P0→P2) con dependencias |
| [02_frontend.md](02_frontend.md) | Calidad de código Flutter/Riverpod, lint, estado |
| [03_backend_datos.md](03_backend_datos.md) | Supabase, RLS, migraciones, **sincronización**, webhooks |
| [04_seguridad.md](04_seguridad.md) | Entitlements, fail-open, idempotencia, abuso analytics |
| [05_ui_ux_accesibilidad.md](05_ui_ux_accesibilidad.md) | WCAG, piano, tokens, feedback, estados |
| [06_arquitectura_system_design.md](06_arquitectura_system_design.md) | Capas, patrones, resiliencia, observabilidad |
| [07_testing_ci_cd.md](07_testing_ci_cd.md) | Pirámide de tests, pipelines rotos, Dependabot |
| [08_performance_motion.md](08_performance_motion.md) | Rebuilds, audio, motion, reduced-motion |
| [09_producto_cumplimiento_lanzamiento.md](09_producto_cumplimiento_lanzamiento.md) | i18n, GDPR, retención, distribución |
| [10_remediacion_2026-07-24.md](10_remediacion_2026-07-24.md) | Estado actual, cambios aplicados, despliegue y pendientes |

## Semáforo global por dimensión

| Dimensión | Estado | Comentario |
|-----------|:------:|------------|
| Arquitectura de software | 🟢 | Capas limpias, Repository, DI en SRS. No tocar. |
| Backend / datos / RLS | 🟢 | Merge atómico y escrituras vía RPC aplicados en producción. |
| Seguridad | 🟡 | Escalada Pro y métricas ya cerradas en el servidor; falta hardening de Checkout. |
| Frontend / código | 🟢 | Bien estructurado; falta lint estricto. |
| UI/UX | 🟡 | Design system coherente; estados y feedback mejorables. |
| Accesibilidad | 🟡 | Piano ya tiene Semantics, foco, teclado e iconos; quedan gaps fuera del piano. |
| Testing | 🟢 | 47 archivos y 309 tests; cobertura se genera en CI, falta umbral. |
| CI/CD | 🟡 | Deploy ya depende de CI; falta validar workflow y pipeline iOS. |
| Performance / motion | 🟢 | Audio en capas; reduced-motion a verificar. |
| Producto / cumplimiento | 🟡 | GDPR (borrar/exportar) OK; retención analytics sin definir. |

🟢 sólido · 🟡 mejorable / con riesgos acotados · 🔴 bloqueante

## Definition of Done — "listo para mercado"

TOGESC se considera **listo para lanzamiento profesional** cuando:

- [ ] **Sin pérdida de datos**: merge atómico aplicado en servidor; falta desplegar la build y probar web↔móvil (SYNC-002).
- [ ] **Accesibilidad AA**: piano corregido; falta Lighthouse ≥ 90 y reduced-motion completo.
- [ ] **Entitlements robustos**: escritura de suscripciones ya bloqueada en servidor; falta sandbox de pagos y activar el candado Pro (SEC-003/004).
- [ ] **Pipelines verdes**: configuración corregida; falta observar una ejecución completa CI→Deploy.
- [ ] **Analytics protegido**: lectura cerrada y payload acotado; faltan rate-limit y retención.
- [ ] **Lint estricto** en CI bloqueando merge; commits convencionales (FE-001, PROC-001).
- [ ] Dependencias al día (Dependabot resuelto) sin regresiones (DEP-001).
- [ ] Política de privacidad + retención publicadas y exactas; permisos móviles justificados.

## Resumen ejecutivo

Proyecto maduro y bien diseñado. La remediación del 2026-07-24 cerró en el
servidor la escalada de privilegios Pro y la exposición de métricas, y llevó la
fusión de progreso a una función atómica. El candado Pro del sync quedó
preparado en un único punto pero sin activar, porque hoy no existe ninguna
suscripción y habría dejado sin nube al único usuario con progreso. El paso
inmediato es desplegar la build que escribe mediante RPC. Ver
[10_remediacion_2026-07-24.md](10_remediacion_2026-07-24.md).
