# Remediación integral — 2026-07-24

## Alcance

Esta iteración parte de una segunda auditoría completa del código real de
Flutter, Supabase, CI/CD y documentación. No sustituye el historial de los
documentos 02–09: registra qué afirmaciones quedaron obsoletas, qué se corrigió
y qué requiere todavía validación operativa.

Estado de referencia antes de los cambios:

- Flutter + Riverpod + Supabase, 309 tests aprobados y 1 omitido.
- El cliente podía insertar y actualizar su propia fila de
  `user_subscriptions`.
- Las vistas de métricas globales eran legibles por cualquier usuario
  autenticado.
- `HybridProgressRepository.save()` podía sobrescribir progreso remoto.
- Deploy Web y CI se ejecutaban en paralelo.
- Estadísticas confundía error, carga y ausencia de datos.

## Decisión de alcance sobre la base de datos

Antes de aplicar nada se midió el impacto real sobre producción:

| Comprobación | Valor |
|---|---|
| Usuarios registrados | 2 |
| Filas en `user_progress` | 1 |
| Filas en `user_subscriptions` | 0 |
| Suscripciones Pro vigentes | 0 |

Exigir Pro para sincronizar habría dejado sin acceso al progreso en la nube al
único usuario que lo tiene, porque no existe ninguna suscripción registrada. Se
decidió por tanto **dividir la remediación**: aplicar de inmediato el cierre de
la vulnerabilidad y la corrección de concurrencia, y diferir el candado Pro
hasta que se activen los cobros.

Para que ese cambio futuro sea trivial, la autorización del sync se concentró en
una única función conmutadora, `public.has_cloud_sync_access(uuid)`, que hoy
solo comprueba la propiedad del dato. Las políticas y la lógica de fusión ya la
consultan, así que activar el modelo de pago no requerirá tocarlas.

Decisión de producto confirmada: **la sincronización en la nube será exclusiva
de Pro desde el lanzamiento.**

## Migraciones aplicadas en producción

Ambas se validaron primero en una transacción revertida y después se aplicaron
sobre el proyecto `puetlvcsrntwweuxinee`.

| Versión | Nombre | Contenido |
|---|---|---|
| `20260724215043` | `harden_subscriptions_and_analytics` | Entitlements server-owned, trial único, fusión atómica, cierre de analytics |
| `20260724215232` | `metrics_views_security_invoker` | Vistas de métricas dejan de saltarse RLS |

### Fallo detectado durante la validación

La primera versión de la migración usaba `jsonb_object_length()`, que **no
existe en PostgreSQL**. La producción corre PostgreSQL 17.6 y el catálogo
confirmó su ausencia, de modo que la migración habría fallado al ejecutarse. Se
sustituyó por un recuento sobre `jsonb_object_keys()`.

Este es el argumento a favor de validar antes de aplicar: el error no era
detectable leyendo el SQL ni ejecutando las pruebas de Flutter.

## Cambios implementados

### SEC-003 — Entitlements server-owned

**Estado:** aplicado en producción.

- Se eliminaron las políticas `INSERT` y `UPDATE` de `user_subscriptions`.
- Se revocaron esas escrituras a `authenticated`; el cliente conserva
  únicamente `SELECT` de su fila.
- Se añadió `trial_started_at`.
- Se añadió `start_subscription_trial()`, `security definer`, con identidad
  derivada de `auth.uid()`, duración fija de 14 días, bloqueo de fila, máximo de
  un trial por cuenta y protección para no degradar una suscripción vigente.
- `SubscriptionService` dejó de persistir estados recibidos del SDK móvil.
  RevenueCat y Stripe deben confirmar el estado mediante webhook.
- `SupabaseSubscriptionRepository` ya no expone `upsert`.

El cliente ya no puede enviar `plan=pro`, `status=active` ni una fecha
arbitraria.

### SYNC-002 — Merge atómico por nota

**Estado:** aplicado en producción.

- El cliente fusiona remoto y local antes de guardar.
- Se revocaron `INSERT` y `UPDATE` directos sobre `user_progress`.
- La escritura pasa por `merge_user_progress(jsonb, timestamptz)`, que bloquea
  la fila y fusiona nota a nota por `last_seen`, rompiendo empates con
  `times_seen`.
- La función valida autenticación, autorización, número de notas, nombres
  permitidos y estructura del payload.
- Se añadió el test unitario “save conserva notas creadas por otro
  dispositivo”.

Esto cierra la ventana de lectura-fusión-escritura entre dispositivos.

### SEC-004 — Autorización del cloud sync

**Estado:** preparado, deliberadamente sin activar.

`has_cloud_sync_access()` hoy devuelve verdadero para el propietario del dato.
Cuando se activen los cobros, basta redefinirla:

```sql
create or replace function public.has_cloud_sync_access(target_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select target_user_id is not null
     and target_user_id = auth.uid()
     and exists (
       select 1
         from public.user_subscriptions s
        where s.user_id = target_user_id
          and s.plan = 'pro'
          and s.status in ('active', 'trialing')
          and (s.expires_at is null or s.expires_at > now())
     );
$$;
```

No hay que modificar políticas ni la función de fusión.

### SEC-005 — Analytics privados y acotados

**Estado:** aplicado en producción.

- Se eliminó la lectura de `analytics_events` por parte del cliente.
- Se revocó el acceso autenticado a `metrics_daily` y `metrics_csat_daily`.
- Se añadió una lista de nombres de evento permitidos.
- El JSON de propiedades quedó limitado a 4 KiB.
- Las vistas pasaron a `security_invoker`, de modo que ya no ignoran RLS.

Los 23 eventos existentes se comprobaron antes de aplicar las restricciones:
todos usan nombres permitidos y el mayor ocupa 46 bytes.

Pendiente: rate-limit por IP en Edge Function o gateway, y retención
automatizada.

### MON-002 — Fail-closed sin caché manipulable

**Estado:** implementado en cliente.

`ProRouteGuard` usa estado Free ante error y `SubscriptionNotifier.refresh()` ya
no convierte una caché local en autorización válida.

Compromiso aceptado: sin red, un usuario Pro puede perder temporalmente el
acceso a funciones Pro locales. Un modo offline correcto exigirá un entitlement
firmado y con expiración, no un JSON en `SharedPreferences`.

### GAME-001 — Coherencia del modo velocidad

**Estado:** implementado.

Las respuestas y los tiempos agotados actualizan el SRS y solicitan
persistencia. Un fallo aumenta el límite con `speedWrongIncrease` y los aciertos
lo reducen con `speedCorrectDecrease`.

### SRS-001 — Umbral visual dinámico

**Estado:** implementado.

`SrsProgressIndicator` recibe el umbral del perfil activo: 4 en intenso, 5 en
equilibrado y 6 en relajado. La interfaz ya no muestra siempre `/5`.

### UX-002 — Errores recuperables del progreso

**Estado:** implementado en Estadísticas y Progreso por nota.

Carga, error y ausencia de datos son estados distintos, y el error ofrece
explicación y botón de reintento. Queda extender el mismo patrón a las secciones
de ajustes que aún ocultan el fallo con `SizedBox.shrink()`.

### ROUTER-001 — Parámetros defensivos

**Estado:** implementado.

`/game/:modeId` y `/speed/game/:modeId` usan `int.tryParse` y vuelven a una
pantalla segura si el parámetro es inválido.

### CI-002 — Deploy condicionado por CI

**Estado:** implementado en workflows; pendiente observar una ejecución real.

Deploy Web se dispara mediante `workflow_run` solo si CI termina en éxito para
un push a `main`, y hace checkout del `head_sha` validado. Flutter quedó fijado
a `3.41.4` en los tres workflows, los tests generan cobertura y `vercel.json`
ignora el build automático para dejar una única ruta de publicación.

### OBS-002 — Release de Sentry

**Estado:** implementado.

Sentry usa `APP_VERSION` en lugar de una cadena fija.

## Validación ejecutada

En el cliente:

- `flutter analyze`: 0 incidencias.
- `flutter test`: 310 aprobados, 1 omitido.
- `git diff --check`: sin errores de espaciado.

En la base de datos:

- Ensayo completo de la migración dentro de una transacción revertida, con
  verificación posterior de que no quedó ningún rastro.
- Matriz de privilegios comprobada tras aplicar: `user_subscriptions` sin
  `INSERT` ni `UPDATE` y con `SELECT`; `user_progress` sin escrituras directas y
  con lectura; `analytics_events` sin `SELECT` y con `INSERT`; vistas de
  métricas sin acceso para `authenticated`.
- Linter de seguridad de Supabase: los dos errores de vistas `SECURITY DEFINER`
  quedaron resueltos.

### Prueba de extremo a extremo suplantando a un usuario real

Ejecutada sobre producción con el rol `authenticated` y un `sub` de usuario
real, dentro de una transacción revertida. Se comprobó después que los datos
quedaron intactos.

| Caso | Resultado |
|---|---|
| `UPDATE` directo a `user_progress` | Bloqueado: permission denied |
| Auto-concederse plan Pro | Bloqueado: permission denied |
| Leer métricas globales | Bloqueado: permission denied |
| Leer `analytics_events` | Bloqueado: permission denied |
| Fusionar progreso de un segundo dispositivo | Conserva la nota previa y añade la nueva |
| Fusionar con un nombre de nota inválido | Bloqueado: `invalid_note_payload` |
| Iniciar trial | Devuelve `pro/trialing` |
| Repetir trial | Bloqueado: `trial_already_used` |

Sin sesión, `merge_user_progress()` y `start_subscription_trial()` responden
`authentication_required`.

Esta es la comprobación que faltaba en las iteraciones anteriores: hasta ahora
la matriz RLS se había razonado, no ejercitado.

## Avisos restantes del linter

| Aviso | Nivel | Valoración |
|---|---|---|
| `rls_auto_enable()` ejecutable por `anon` | WARN | Falso positivo. Es una función de disparador de eventos que activa RLS en tablas nuevas; PostgreSQL impide invocarla desde la API. Se comprobó: devuelve `trigger functions can only be called as triggers`. |
| `delete_own_account`, `start_subscription_trial`, `merge_user_progress`, `has_cloud_sync_access` ejecutables por usuarios autenticados | WARN | Intencionado. Son precisamente las funciones que sustituyen a la escritura directa y validan identidad internamente. |
| `processed_webhook_events` con RLS y sin políticas | INFO | Intencionado: solo debe accederla `service_role`. Sin políticas, el acceso de clientes queda denegado. |
| Protección de contraseñas filtradas desactivada | WARN | Pendiente: activar en el panel de Auth. |

## Coordinación de despliegue

La aplicación desplegada actualmente escribe `user_progress` mediante `upsert`
directo, y esa vía ya está revocada. **Hasta que se publique la nueva build, la
sincronización en la nube devolverá error de permisos.** El progreso local del
usuario no corre riesgo y ningún dato se ha borrado.

Pasos para completar:

1. Desplegar la build de Flutter que usa `merge_user_progress`.
2. Comprobar el inicio de sesión y una ronda con sincronización.
3. Verificar los webhooks de Stripe y RevenueCat en modo prueba.

## Higiene del repositorio

El archivo local `20260624180000_processed_webhook_events.sql` no coincidía con
la versión registrada en el servidor, `20260624215255`. Se renombró para que
`supabase db push` no intente reaplicarlo. Las diez migraciones locales
coinciden ahora exactamente con el historial remoto.

`supabase/config.toml` declara `major_version = 15`, pero producción corre
PostgreSQL 17.6. Conviene alinearlo para que el entorno local reproduzca el
comportamiento real.

## Remediación UI/UX (misma fecha)

Cierre del gap visual priorizado tras la auditoría de diseño:

| Cambio | Archivos |
|---|---|
| `ThemeExtension` `TogescColors` light/dark | `togesc_colors.dart`, `app_theme.dart` |
| Feedback musical y speed resuelven por tema | piano, result, countdown, SRS, chips, speed |
| `SrsProgressIndicator` sin `Colors.*` Material | `srs_progress_indicator.dart` |
| Layout `maxWidth` 1200 + margen desktop | `TogescPageBody`, home, stats, onboarding, notas |
| Reduced motion en piano | `MediaQuery.disableAnimationsOf` |
| Nav "Stats" → "Estadisticas" | `togesc_shell.dart` |

### UI/UX follow-up (misma fecha, segundo pase)

- Cluster saltable con reduced motion (preferencia + sistema).
- `account_*` / `sync_diagnostics_card` migrados a `TogescColors`.
- Landing sin emojis, hero de producto, `prefers-reduced-motion`.
- Candado Pro del sync activado (`20260725033417`); usuarios con progreso
  previo recibieron trial de 14 dias.
- Build web publicada en [togesc.vercel.app](https://togesc.vercel.app)
  (`63eb776`, Deploy Web `30142644096`).

Inventario de lo que **sigue abierto**: 
[11_estado_pendiente_2026-07-26.md](11_estado_pendiente_2026-07-26.md).

## Pendientes priorizados

> Inventario vigente y criterios de cierre:
> [11_estado_pendiente_2026-07-26.md](11_estado_pendiente_2026-07-26.md).

### P0 antes de activar pagos reales

- Crear la Checkout Session de Stripe en el servidor; no aceptar
  `client_reference_id` construido por el navegador (SEC-006).
- Validar `app_user_id` de RevenueCat / customer Stripe contra `auth.users`
  (SEC-007).
- Convertir el control de idempotencia de webhooks en una operación atómica
  (SEC-008).
- Añadir pruebas SQL de RLS y RPC, y pruebas Deno de webhooks (TEST-002).
- Sandbox de pagos + sync web↔móvil (QA-001).
- ~~Desplegar build Flutter con RPC de merge (DEPLOY-001).~~ ✅ 2026-07-25

### P1

- Rate-limit y retención de analytics (SEC-002).
- Protección de contraseñas filtradas en Auth (AUTH-001).
- Reportar a Sentry los errores manejados de sincronización, audio y pagos.
- Sustituir los errores invisibles en las secciones de ajustes (UX-003).
- Pruebas E2E reales en Chrome y Android (TEST-003).
- Verificar la restauración de copias de seguridad (OPS-001).
- Reduced motion residual (hover bento) y contraste medido / Lighthouse ≥ 90.
- Observar CI→Deploy en un push ordinario a `main` (CI-003).

### P2

- Migración progresiva de textos a ARB.
- Medición de Lighthouse performance y presupuesto de bundle.
- Pipeline de iOS.
- `CONTRIBUTING.md` y política de commits.
- Robots, sitemap y canonical de la web.

## Riesgos que no deben declararse resueltos

- ~~La nueva build de Flutter todavía no está desplegada.~~ ✅ publicada.
- El workflow encadenado CI→Deploy **en push a `main`** no se ha observado
  (sí hubo Deploy por `workflow_dispatch`).
- No hay rate-limit efectivo de analytics.
- No existe entitlement offline firmado.
- No se ha medido Lighthouse ni el rendimiento en dispositivo.
- Pagos reales sin Checkout server-side ni sandbox pasado.
