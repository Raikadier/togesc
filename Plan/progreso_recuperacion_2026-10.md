# Progreso — plan de recuperación oct 2026

Plan: `Plan/plan_recuperacion_2026-10.md`. Log en orden cronológico inverso: lo último, arriba.
Cada entrada indica qué se hizo, quién lo hizo (usuario, Claude o el agente con su rol) y la evidencia.

---

## 2026-11-10 — Supabase reactivado, vigilancia en verde y sync abierta en producción

Hecho por Claude Code a petición del propietario, que reactivó el proyecto y conectó el MCP de Supabase.

- **Supabase responde.** Auth y la API de la base de datos contestan, y la Edge Function `stripe-webhook` está desplegada.
- **Vigilancia en `main`** (PR #10, mergeado el 2026-11-09): `Web Uptime Check` (run 42819981900) y `Supabase Keepalive` (run 42819987794) pasan, con HTTP 200 en la web, en la salud de Auth y en la consulta a `user_progress`.
- **Migración aplicada en producción** por MCP: `open_cloud_sync_while_free`, versión `20261110131953`. El fichero del repo se renombró a esa versión para que el historial coincida.
  - Comprobado en una transacción revertida, con el rol `authenticated` y el usuario de la única fila de progreso: ve su fila, `has_cloud_sync_access` da verdadero para sí mismo y falso para otro usuario, y `anon` no puede ejecutar la función.
  - Antes de aplicarla había 0 usuarios Pro vigentes, así que nadie podía sincronizar. La última sincronización era del 2026-06-24.
- **Estado de los datos:** 2 usuarios, 1 fila de progreso, 1 suscripción y 24 eventos de analítica.
- **Avisos de seguridad de Supabase:** la protección contra contraseñas filtradas está desactivada. `public.rls_auto_enable()` no está en las migraciones del repo: es un disparador que activa RLS en las tablas nuevas, creado desde el panel.

- **Producción al día (fase R2 cerrada).** El PR #9 se mergeó en `main` (commit `86384ef`) con la CI en verde. La CI de `main` pasó (run 42859327813) y Deploy Web publicó (run 42860132903), los dos con Flutter 3.47.7.
  - Comprobado: https://togesc.vercel.app responde 200, `main.dart.js` es del 2026-11-10 y contiene los textos del lote A y ninguno de los antiguos. La web abre en el onboarding nuevo sin errores en la consola.
  - Producción llevaba en la versión del 2026-07-24.

**Pendiente del propietario:**
1. Crear el secret `BACKUP_PASSPHRASE` en GitHub Actions. Sigue sin existir, así que no hay ningún backup con datos.
2. Lanzar «Supabase Backup» a mano y descargar el artefacto.
3. Activar la protección contra contraseñas filtradas en Auth.

**Sin comprobar:** la sync desde la app real con un usuario que inicie sesión. El cliente que distingue errores de red de «sin datos» sigue solo en `feat/rediseno-v2.1`.

## 2026-11-03 — Backup con datos, keepalive y sync abierta mientras no se cobra

Hecho por Claude Code a petición del propietario. Nada desplegado: los workflows programados se ejecutan desde `main`, y la migración hay que aplicarla con Supabase reactivado.

- **Supabase sigue pausado.** El backup del 2026-11-01 (run 41299662672) falló con «project is paused». El uptime de `main` sale en verde porque solo comprueba la web.
- **Backup** (`supabase-backup.yml`): vuelca roles, esquema y datos de `public` y `auth`, y los cifra con gpg (secret `BACKUP_PASSPHRASE`). Falla si falta el secret o si el volcado de datos sale vacío. Retención de 90 días. Restauración documentada en `docs/supabase_setup.md` §8, sin ensayar.
- **Keepalive** (`supabase-keepalive.yml`): consulta ligera a PostgREST cada 3 días.
- **Sync** (migración `20261110131953_open_cloud_sync_while_free.sql`): `has_cloud_sync_access` comprueba solo que la fila sea del usuario. Las pruebas Pro de 14 días caducaron hacia el 2026-08-08 y desde entonces la nube no guardaba ni devolvía progreso para nadie. Al activar los pagos hay que recuperar la comprobación Pro.
- **Cliente:** `SupabaseProgressRepository.load()` y `loadLastSessionIso()` ya no convierten los errores en «sin datos». El repositorio híbrido sigue con lo local y deja la subida pendiente, y el diagnóstico de sync ya no da la nube por alcanzable cuando no lo está. Dos tests nuevos.

**Pendiente del propietario:**
1. Reactivar el proyecto en el panel de Supabase.
2. Crear el secret `BACKUP_PASSPHRASE` y guardar la frase fuera de GitHub.
3. Llevar los workflows a `main` y aplicar la migración (`supabase db push`).
4. Lanzar el backup a mano y descargar el artefacto.

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
