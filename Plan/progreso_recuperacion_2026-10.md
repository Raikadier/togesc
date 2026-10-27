# Progreso — plan de recuperación oct 2026

Plan: `Plan/plan_recuperacion_2026-10.md`. Log en orden cronológico inverso: lo último, arriba.
Cada entrada indica qué se hizo, quién lo hizo (usuario, Claude o el agente con su rol) y la evidencia.

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
