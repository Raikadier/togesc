# Backend, datos y persistencia

Estándares: 3FN/JSONB, RFC 3339 (UTC), migraciones inmutables, idempotencia (qstd §5.3, §10).

> **Actualización 2026-07-26:** SYNC-001 (merge atómico), entitlements y
> candado Pro del sync están aplicados en producción. Pendientes de pagos y
> sandbox: [11_estado_pendiente_2026-07-26.md](11_estado_pendiente_2026-07-26.md).
> Historial: [10_remediacion_2026-07-24.md](10_remediacion_2026-07-24.md).

## Lo que está bien (no tocar)

- **RLS por propietario** en el esquema original. La migración de hardening
  corrige grants excesivos en suscripciones, progreso y analytics.
- Triggers `set_*_updated_at` con `security invoker` + `set search_path = public`. Correcto.
- `delete_own_account()` `security definer` con `revoke all from public` + grant solo a `authenticated` (y revoke a `anon` en migración posterior). Buen patrón GDPR.
- Timestamps `timestamptz` en UTC; índices por `user_id` y columnas de consulta. Correcto.
- Migraciones numeradas `YYYYMMDDHHMMSS_*.sql`, inmutables.
- Escritura de progreso solo vía `merge_user_progress()`; lectura condicionada
  a `has_cloud_sync_access()`.

---

## SYNC-001 — La sincronización pierde datos — CORREGIDO

- **Severidad:** CRÍTICO · **Esfuerzo:** M · **Prioridad:** P0
- **Evidencia:** [`hybrid_progress_repository.dart:29-52`](../../TOGESC/togesc/lib/services/hybrid_progress_repository.dart#L29) (`load`) y [`:107-146`](../../TOGESC/togesc/lib/services/hybrid_progress_repository.dart#L107) (`mergeOnSignIn`).
- **Estándar:** ISO/IEC 25010 (Fiabilidad — recuperabilidad); ADR-004 (no perder progreso SRS).

### Problema (HECHO OBSERVADO)
La decisión de sincronización es `SessionTimestamp.isRemoteNewer(localSession, remoteSession)` y según el resultado se hace `save(remoteData)` **o** `save(localData)` — el **blob completo** de las 12 notas. No hay fusión por nota. `mergeOnSignIn` está mal nombrado: es un *last-write-wins* a nivel sesión global.

**Escenario de pérdida:** usuario practica en móvil (offline, avanza notas C/D/E), luego en web (avanza F/G). Al sincronizar, gana el `last_session` más reciente y **se descarta** el avance del otro dispositivo por completo.

### Por qué importa
El SRS es el único activo del usuario y la propuesta de valor central. Perderlo silenciosamente al usar dos dispositivos contradice directamente la razón de existir de la Fase 4 (sync) y rompe el DoD "mismo usuario ve mismo progreso".

### Recomendación
Fusionar a nivel `NoteData` por clave de nota, no por sesión global:

```dart
// ANTES (hybrid_progress_repository.dart, simplificado)
if (SessionTimestamp.isRemoteNewer(localSession, remoteSession)) {
  await _local.save(remoteData, lastSession: remoteSession); // gana remoto entero
} else {
  await remote.save(localData, lastSession: localSession);    // gana local entero
}

// DESPUÉS — merge por nota
Map<String, NoteData> mergeProgress(
  Map<String, NoteData> local,
  Map<String, NoteData> remote,
) {
  final keys = {...local.keys, ...remote.keys};
  return {
    for (final k in keys)
      k: _pickNewer(local[k], remote[k]), // por lastSeen / timesSeen mayor
  };
}
// _pickNewer: si una es null devuelve la otra; si ambas, la de lastSeen más
// reciente (empate -> mayor timesSeen). Persistir merge en ambos lados.
```

### Criterios de aceptación
- [x] Test multi-dispositivo conserva avances no solapados.
- [x] Empates resueltos determinísticamente por `lastSeen`/`timesSeen`.
- [x] Merge local compartido por load/sign-in/flush.
- [x] RPC server-side con bloqueo de fila para merge atómico.
- [ ] Prueba manual web↔móvil con cuenta real pasa.

### Trade-offs
Merge por nota es más complejo y requiere que `NoteData` tenga un timestamp por nota fiable (`lastSeen` ya existe). Alternativa más simple pero peor: CRDT/versionado — sobredimensionado para 12 notas. El merge por `lastSeen` es el punto óptimo coste/beneficio.

---

## SEC-001 — Webhooks sin idempotencia — CORREGIDO

- **Severidad:** ALTO · **Esfuerzo:** M · **Prioridad:** P0
- **Evidencia:** [`stripe-webhook/index.ts`](../../supabase/functions/stripe-webhook/index.ts), [`revenuecat-webhook/index.ts`](../../supabase/functions/revenuecat-webhook/index.ts).
- **Estándar:** qstd §5.3 / §10.3 (idempotencia en webhooks).

### Problema
Stripe verifica firma ✅ pero procesa `event` haciendo `upsert` sin registrar el `event.id`. Stripe y RevenueCat **reintegran** entregas ante timeout/5xx. Un reintento puede reprocesar un cambio de estado obsoleto (p. ej. reaplicar `canceled` tras un `active` posterior si llegan desordenados).

### Recomendación
```sql
-- nueva migración
create table public.processed_webhook_events (
  event_id text primary key,
  source text not null,
  processed_at timestamptz not null default now()
);
```
```ts
// al inicio del handler, tras verificar firma:
const { error: dupe } = await supabase
  .from("processed_webhook_events")
  .insert({ event_id: event.id, source: "stripe" });
if (dupe?.code === "23505") return jsonResponse({ received: true, duplicate: true });
```

### Criterios de aceptación
- [x] Reenviar el mismo `event.id` no altera el estado dos veces.
- [x] Eventos antiguos se descartan por fecha de expiración.
- [ ] Convertir el claim de idempotencia en operación atómica antes de procesar.

---

## SEC-002 — `analytics_events`: insert anónimo sin rate-limit ni retención

- **Severidad:** MEDIO · **Esfuerzo:** M · **Prioridad:** P1
- **Evidencia:** [`20260623194029_analytics_anon_insert.sql`](../../supabase/migrations/20260623194029_analytics_anon_insert.sql) — política `analytics_events_insert_anon` permite a `anon` insertar con `user_id is null`.
- **Estándar:** OWASP (abuso de API), GDPR (minimización/retención).

### Problema
Cualquiera con la `anon key` (embebida en el cliente web, públicamente visible) puede insertar filas ilimitadas → inflado de costes y contaminación de métricas. No hay política de retención: la tabla crece sin límite.

### Recomendación
- Limitar inserts anónimos: validar `event_name` contra una allow-list en un `with check` o función `RPC`, y/o mover analytics anónimas a una Edge Function con rate-limit por IP.
- Job de retención (cron Supabase / GitHub Action): `delete from analytics_events where created_at < now() - interval '180 days'`.
- Documentar el periodo de retención en la política de privacidad.

### Criterios de aceptación
- [x] Inserts restringidos a allow-list y propiedades ≤4 KiB.
- [ ] Retención automatizada y documentada.
- [ ] Rate-limit real en Edge Function/gateway.

---

## Pendiente de verificar
- ¿Backups Supabase con prueba de restauración real (no solo workflow que corre)?
- Índice compuesto `user_progress(user_id, last_session)` sugerido en qstd §10.9 — `user_id` es PK; evaluar si `last_session` se consulta.
