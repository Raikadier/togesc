# Seguridad

Estándares: OWASP Mobile Top 10, deny-by-default, tokens cortos + refresh, no service_role en cliente, validación server-side (qstd §3.3, §13.3).

> **Actualización 2026-07-24:** esta página conserva el hallazgo original.
> MON-001 quedó corregido y se descubrió un problema más grave: las políticas
> permitían que el cliente escribiera su propio entitlement. La solución vigente
> está en [10_remediacion_2026-07-24.md](10_remediacion_2026-07-24.md).

## Lo que está bien (no tocar)
- **PKCE** en `Supabase.initialize` ([`main.dart:43`](../../TOGESC/togesc/lib/main.dart#L43)).
- `service_role` **solo** en Edge Functions (`Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")`); el cliente usa `anonKey` publishable. Correcto.
- Verificación de firma Stripe con `stripe.webhooks.constructEvent`. Correcto.
- RLS como autorización primaria (ver [03_backend_datos.md](03_backend_datos.md)).

---

## MON-001 — `ProRouteGuard` falla-abierto — CORREGIDO

- **Severidad:** ALTO · **Esfuerzo:** S · **Prioridad:** P0
- **Evidencia:** [`pro_route_guard.dart:30`](../../TOGESC/togesc/lib/widgets/pro_route_guard.dart#L30): `error: (_, _) => child`.
- **Estándar:** deny-by-default (qstd §3.3, §10.6).

### Estado actual
El guard falla-cerrado con estado Free y `SubscriptionNotifier.refresh()` no
convierte la caché local en autorización. La autorización del cloud sync se
repite además en PostgreSQL.

### Por qué importa
La monetización depende de este guard. Fail-open convierte el paywall en opcional. Aunque los datos del usuario siguen protegidos por RLS, el *gating de features* (valor de negocio) se evade trivialmente.

### Criterios de aceptación
- [x] Con el provider en `error` → redirige a paywall.
- [x] La caché manipulable no concede acceso.
- [ ] Diseñar entitlement offline firmado si el producto lo requiere.

### Observación complementaria (no bloqueante)
`SubscriptionAccess` sigue siendo presentación cliente. La nueva
`merge_user_progress()` exige Pro activo en servidor, por lo que el flag local
no concede acceso a datos remotos.

## SEC-003 — Escalada de privilegios Pro — CORREGIDO EN MIGRACIÓN

La auditoría del 2026-07-24 confirmó que `authenticated` tenía `INSERT` y
`UPDATE` sobre `user_subscriptions`. Un usuario podía enviar `plan='pro'`
directamente a PostgREST. La migración de hardening revoca esos privilegios y
traslada el trial a `start_subscription_trial()`.

La corrección no está activa en producción hasta aplicar la migración.

---

## SEC-001 / SEC-002
Tratados en [03_backend_datos.md](03_backend_datos.md) (idempotencia de webhooks y abuso/retención de `analytics_events`).

## Observaciones menores
- **RevenueCat webhook**: la comparación `authHeader !== \`Bearer ${webhookSecret}\`` no es de tiempo constante (timing attack teórico). Riesgo bajo; opcional usar comparación constante.
- **Secrets**: confirmados en GitHub (`SUPABASE_*`, `SENTRY_DSN`, `VERCEL_TOKEN`). **Faltan** `ANDROID_KEYSTORE_*` (esperado, móvil diferido) y claves Stripe/RevenueCat para activar pagos (esperado).
- **No loguear PII**: los `console.error` en webhooks vuelcan el objeto `error` de Supabase; revisar que no incluya datos sensibles en logs persistentes.

## Pendiente de verificar
- Permisos móviles mínimos (micrófono por `record`, notificaciones) justificados en `AndroidManifest.xml` / `Info.plist`.
- Headers de seguridad web (CSP, HSTS, X-Frame-Options) en Vercel.
