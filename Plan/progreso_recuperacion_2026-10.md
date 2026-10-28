# Progreso — plan de recuperación oct 2026

Plan: `Plan/plan_recuperacion_2026-10.md`. Log en orden cronológico inverso: lo último, arriba.
Cada entrada indica qué se hizo, quién lo hizo (usuario, Claude o el agente con su rol) y la evidencia.

---

## 2026-10-28 — Rescate del backup y reactivación de la monitorización

Hecho por Claude Code a petición del propietario.

**Backup**
- Se descargó el artefacto `supabase-backup` de la ejecución 37195161960 (2026-10-04), que caducaba el 2026-11-03.
- Copia en `D:\Github repos\togesc-backups\2026-10-04\togesc-20261004.sql`, fuera del repo. Pesa 19.755 bytes y su sha256 es `6b93d992…a9fb`.
- **El backup solo contiene el esquema.** Tiene las 4 tablas, las funciones y RLS, pero ni una fila de datos. `supabase db dump` sin `--data-only` no vuelca datos, así que **ningún backup de GitHub ha guardado nunca datos de usuarios**.
- **No se ha cambiado el workflow para volcar datos.** El repo es público y cualquier usuario con sesión iniciada en GitHub podría descargar el artefacto. Volcar datos exige cifrado (por ejemplo, gpg simétrico con el secret `BACKUP_PASSPHRASE`) o usar las copias del propio Supabase. Está pendiente de que decida el propietario.

**Workflows**
- `gh workflow enable` reactivó `Supabase Backup` y `Web Uptime Check`, que estaban en `disabled_inactivity`.
- Uptime se lanzó a mano (run 40714307128) y terminó en `success`: togesc.vercel.app responde 200.
- El backup seguirá fallando cada domingo hasta que vuelva Supabase. Así, al menos, avisa.

**Hueco detectado**
- El uptime solo comprueba Vercel, no Supabase, y por eso no habría detectado esta caída aunque hubiera estado activo.
- GitHub vuelve a desactivar los cron de un repo público tras 60 días sin actividad.

**Pendiente del propietario:** restaurar el proyecto Supabase desde el panel.

**Uptime de Supabase (cambio sin commitear)**
- Hay un paso nuevo en `.github/workflows/uptime-check.yml`: hace un GET a `$SUPABASE_URL/auth/v1/health` con `apikey` (secrets que ya existen) y exige un 200.
- Se ejecuta aunque falle la comprobación de la web (`!cancelled()`).
- El YAML parsea bien. No se ha probado en Actions, porque los cron solo leen el workflow de la rama por defecto: entra en vigor al llegar a `main`.
- Mientras Supabase siga caído, fallará cada hora (por diseño: es la alerta).

---

## 2026-10-28 — Evaluación completa del estado (equipo de 7 roles)

Hecho por Claude Code como líder con 7 agentes en solo lectura. Informe: `Plan/evaluacion_estado_2026-10-28.md`.

**Verificado por Claude:**
- `flutter analyze` sin problemas y `flutter test` 680 OK / 1 omitido / 0 fallos (3.47.7).
- Supabase vuelve a dar NXDOMAIN.
- Los workflows Backup y Uptime están en `disabled_inactivity`.
- El único backup (4 KB) caduca el 2026-11-03.
- Hay un bug de doble penalización en el SRS (`srs_system.dart:207,273`).
- SEC-006 y SEC-008 siguen abiertos.
- La release de Android se firma con debug.
- El paywall no muestra precio ni términos.

**Veredicto:** NO LISTO para el mercado. Lo urgente es reactivar Supabase y rescatar el backup.

---

## 2026-10-20 — R2 verificado en local; premisa de CI corregida

Hecho por OpenCode (agente) contra el árbol de trabajo; no se ha pusheado nada.

- `flutter analyze`: **No issues found** (Flutter 3.47.7 / Dart 3.13.5). Se corrigieron los 3 avisos de `test/widget/paywall_feature_spoofing_test.dart:54` usando `\u202E`/`\u202C` y interpolación.
- `flutter test --reporter expanded`: **519 passed, 1 skipped, 0 failed**. Los 16 fallos de `ProviderContainer already disposed` del 2026-10-03 **no reproducen** en `feat/rediseno-v2` (4 commits por delante de `main`).
- `node --experimental-strip-types --test supabase/functions/revenuecat-webhook/logic_node_test.ts`: **17/17 OK** (Node 24.14.0). Deno no está instalado, así que `logic_test.ts` no se ha ejecutado en local.
- ECC curado: allowlist de 20 skills en `.opencode/opencode.json`; 30 agentes ocultos. El catálogo anunciado baja de ~925 skills / ~67.400 tokens por step a ~3.700 tokens.
- **No verificado:** CI con Flutter 3.41.4 (local usa 3.47.7); AAB Android (no hay Android SDK local y la rama no está en `origin`, así que no se puede lanzar el workflow). Los fallos de AAB del 2026-06-23/24 son anteriores al commit `c76f6de`, que corrigió el workflow; no hay runs posteriores.
- **Bloqueo de proceso:** `feat/rediseno-v2` no tiene upstream. Para ejecutar CI y el workflow AAB hay que pushear la rama y abrir un PR a `main`, o instalar Android SDK + Flutter 3.41.4 en local.

---

## 2026-10-03 — R0 iniciada

- `supabase projects list` muestra el proyecto `togesc` (`puetlvcsrntwweuxinee`) en estado `ACTIVE_HEALTHY`: ya está reactivado.
- El host `puetlvcsrntwweuxinee.supabase.co` vuelve a resolver: `/auth/v1/health` y `/rest/v1/` devuelven 401 sin API key, que es lo esperado. Las Edge Functions `stripe-webhook` y `revenuecat-webhook` están `ACTIVE` (v2).
- **Webhooks perdidos: N/A.** La monetización nunca se ha activado en producción. Hecho por el agente de pagos (`engineering-payments-billing-engineer`) y verificado por Claude:
  - `gh secret list` solo tiene SENTRY_DSN, SUPABASE_* y VERCEL_TOKEN; no están `MONETIZATION_ENABLED` ni `STRIPE_CHECKOUT_URL`.
  - `supabase secrets list` solo tiene SUPABASE_*; faltan `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET` y `REVENUECAT_WEBHOOK_SECRET`, así que las funciones responderían 500 "Missing env configuration".
  - `supabase inspect db table-stats` estima 0 filas en `processed_webhook_events` y ninguna `stripe_subscription_id` en `user_subscriptions`.
  - Confirmación opcional del usuario: en Stripe, Workbench → Webhooks, y en RevenueCat, Integrations → Webhooks, no debería haber ni endpoint ni eventos fallidos.
  - Nota para R3: antes de activar la monetización hay que configurar esos secretos de Supabase y los de GitHub.
- Pendiente: backup manual (lo está haciendo el agente SRE) y `scripts/validate-production.ps1`, que necesita Flutter en el PATH.

## 2026-10-03 — Revisión de estado (equipo de 4 roles)

Roles: PM (`project-manager-senior`), Mobile (`engineering-mobile-app-builder`), DevOps/SRE y Reality Checker. Conclusiones verificadas por Claude:
- Supabase estaba pausado y los backups fallaban desde el 2026-09-06; en GitHub no quedaba ningún artefacto de backup.
- CI roja desde el 2026-08-04: 297 tests OK, 16 fallan y 1 se salta (`ProviderContainer already disposed` en `_FocusInheritedScope`). Deploy Web se salta, así que producción sigue en 63eb776. Build Android AAB en rojo desde el 2026-06-23.
- SEC-006, SEC-007 y SEC-008 siguen abiertos. La política de privacidad no coincide con la analítica real.
- Veredicto: NO LISTO para mercado. De ahí sale el plan R0–R6.
