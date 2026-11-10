# Plan de recuperación y salida a mercado — oct 2026

Fecha: 2026-10-03 · Base: revisión multi-rol (PM, Mobile, DevOps/SRE, Reality Checker)
Progreso: `Plan/progreso_recuperacion_2026-10.md` (log vivo)
Referencias: `docs/auditoria/11_estado_pendiente_2026-07-26.md`, `docs/qa_checklist.md`, `Plan/plan_fases.txt`

Regla: no se avanza de fase sin cumplir el DoD de la anterior. Etiqueta de responsable:
**[TÚ]** acción manual en dashboards o dispositivos · **[CLAUDE]** código, CI y docs.

---

## Fase R0 — Restaurar el backend (hoy)

Objetivo: volver a tener Supabase operativo y un backup válido.

- [ ] **[TÚ]** Reactivar el proyecto `puetlvcsrntwweuxinee` en el dashboard de Supabase.
- [ ] **[TÚ]** En Stripe y RevenueCat, revisar los webhooks fallidos desde el 2026-09-06 y reenviarlos.
- [ ] **[TÚ]** Lanzar a mano el workflow "Supabase Backup" (`workflow_dispatch`) y descargar el artefacto en local.
- [ ] **[TÚ]** Ejecutar `scripts/validate-production.ps1` y comprobar que login, sync y analytics responden.

DoD: el host de Supabase resuelve, el backup está en verde con su artefacto guardado fuera de GitHub y el login funciona en https://togesc.vercel.app.

## Fase R1 — Que no vuelva a pasar (1–2 días)

- [ ] **[CLAUDE]** Workflow `supabase-keepalive.yml`: una consulta ligera cada 3 días para evitar la pausa del plan free.
- [ ] **[CLAUDE]** `uptime-check.yml` debe comprobar también `/auth/v1/health` y la Edge Function de health, no solo la web estática.
- [ ] **[CLAUDE]** `supabase-backup.yml`: retención de 90 días. Documentar en `docs/supabase_setup.md` cómo hacer una copia externa.
- [ ] **[TÚ]** Decidir si pasar a Supabase Pro, que evita la pausa e incluye backups diarios.
- [ ] **[CLAUDE + TÚ]** Ensayar la restauración de un backup en un proyecto de staging (OPS-001).

DoD: el uptime check falla si Supabase cae, hay una ejecución de keepalive en verde y existe evidencia de una restauración real.

## Fase R2 — CI en verde y producción al día (2–3 días)

> **Actualización 2026-10-20:** los 16 fallos de `ProviderContainer` ya no reproducen en `feat/rediseno-v2`; `flutter analyze` está limpio y `flutter test` da 519 OK + 1 skip en local con Flutter 3.47.7. Queda verificar con 3.41.4, pushear la rama y ejecutar el AAB. Ver `progreso_recuperacion_2026-10.md`.

Diagnóstico original (2026-10-03): 297 tests pasan, 16 fallan y 1 se salta. Todos los fallos dicen `Bad state: Tried to read a provider from a ProviderContainer that was already disposed`, al construir `_FocusInheritedScope`. Algún `ref.read` en un callback de foco se ejecuta después de que el widget se haya desmontado; probablemente entró con el craft "Partitura viva" (db0634f…1ecc63c).

- [ ] **[TÚ]** Instalar o añadir al PATH Flutter 3.41.4 (la versión fijada en CI) para poder ejecutar los tests en local.
- [ ] **[CLAUDE]** Reproducir con `flutter test`, localizar el callback (`game_screen`, `togesc_shell`, `note_input_field`) y protegerlo con `mounted` o capturar el notifier antes de usarlo.
- [ ] **[CLAUDE]** Volver a tener `flutter analyze` sin issues y `flutter test` en verde. Arreglar el smoke e2e `full_game_flow_test`.
- [ ] **[CLAUDE]** Diagnosticar "Build Android AAB", que está en rojo desde el 2026-06-23.
- [ ] **[CLAUDE]** Mergear los PRs de Dependabot de Actions de bajo riesgo: #2 checkout, #1 upload-artifact, #3 setup-cli, #4 mocktail.
- [ ] Push a `main` y observar que se encadenan CI y Deploy Web (CI-003).

DoD: CI en verde, producción en el último commit (ya no en 63eb776) y AAB generado en CI.

## Fase R3 — Pagos seguros (1 semana) — bloqueante para cobrar

- [ ] **[CLAUDE]** SEC-006: crear el checkout de Stripe en el servidor (Edge Function `create-checkout`) con `metadata.supabase_user_id`. El webhook dejará de fiarse de `client_reference_id`, que hoy pone el cliente (`subscription_service.dart:94`, `stripe-webhook/index.ts:113`).
- [ ] **[CLAUDE]** Los eventos que lleguen fuera de orden no deben marcarse como procesados si se descartan (`stripe-webhook/index.ts:186-204`).
- [ ] **[CLAUDE]** SEC-008: idempotencia atómica, con un `insert … on conflict do nothing` al principio y no un SELECT seguido de un INSERT (`_shared/webhook_idempotency.ts`).
- [ ] **[CLAUDE]** SEC-007: RevenueCat debe respetar `expiration_at` en `CANCELLATION` y `BILLING_ISSUE` (periodo de gracia) y responder 200 sin reintento cuando el `app_user_id` sea anónimo o desconocido.
- [ ] **[CLAUDE]** Móvil: llamar a `Purchases.logIn`/`logOut` al cambiar de sesión (`mobile_purchases_service.dart`).
- [ ] **[CLAUDE]** Al borrar la cuenta hay que cancelar o avisar de la suscripción activa (`delete_own_account`).
- [ ] **[CLAUDE]** TEST-002: tests de RLS/RPC y de webhooks (eventos duplicados y fuera de orden) en CI.

DoD: tests de webhooks en verde en CI y revisión de seguridad sin hallazgos altos.

## Fase R4 — Cumplimiento (3–4 días)

- [ ] **[CLAUDE]** La política de privacidad debe reflejar la analítica, Sentry, Stripe y RevenueCat, con responsable, contacto y retención (`privacy_policy_screen.dart`). Además, poner la analítica detrás de consentimiento o desactivarla por defecto.
- [ ] **[CLAUDE]** SEC-002: rate limit y purga programada de `analytics_events`.
- [ ] **[TÚ]** Activar la protección de contraseñas filtradas en Supabase Auth (AUTH-001).
- [ ] **[TÚ]** Revisión legal de la política y los términos.

## Fase R5 — QA manual y validación (1 semana)

- [ ] **[TÚ]** Los 10 ítems pendientes de `docs/qa_checklist.md`, con capturas: Stripe en modo test, RevenueCat en sandbox, sync con dos dispositivos, borrado de cuenta y autoplay de audio.
- [ ] **[CLAUDE]** Lighthouse de accesibilidad ≥ 90, contraste AA medido (A11Y-003) y reduced motion residual (A11Y-002b).
- [ ] **[TÚ]** Validación táctil de "Partitura viva" en un dispositivo físico.

DoD: checklist de QA completa y los 9 criterios de salida a mercado de `11_estado_pendiente…` cerrados.

## Fase R6 — Tiendas (posterior)

- [ ] **[CLAUDE]** Que el build de release falle si no hay `key.properties`, en lugar de firmar con la clave de debug (`android/app/build.gradle.kts:52-55`).
- [ ] **[TÚ]** Generar la clave de upload, subir a una pista interna de Play y rellenar Data Safety.
- [ ] **[CLAUDE]** Pipeline de iOS, `PrivacyInfo.xcprivacy` y TestFlight.

## Backlog técnico (en paralelo, sin bloquear)

- Upgrades major de uno en uno, con la CI en verde entre cada uno: flutter_soloud 4 → go_router 17 → purchases_flutter 10 (va con R3) → riverpod 3. Riverpod 3 es el de más riesgo: 55 usos de `valueOrNull` y hay que revalidar MON-001.
- FE-001: lint estricto (`strict-casts`, `strict-inference`) y acotar `intl: any`.

---

## Orden recomendado

R0 (tú, hoy) ∥ R2 (Claude, en cuanto haya Flutter en local) → R1 → R3 → R4 → R5 → R6

Primer paso para Claude: R2, arreglar los 16 tests rotos.
