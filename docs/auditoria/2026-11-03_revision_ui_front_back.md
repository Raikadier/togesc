# Revisión UI/UX, front y back — 2026-11-03

Rama `feat/rediseno-v2.1`. Revisión de solo lectura hecha por tres agentes (UX Architect, Code Reviewer y Backend Architect). Los hallazgos marcados con ✔ los ha comprobado el revisor principal en el código. `flutter analyze`: sin incidencias. No se ejecutaron `flutter test`, la app ni un lector de pantalla.

## Estado de los hallazgos anteriores
| ID | Estado |
|---|---|
| SYNC-001 | Arreglado: la fusión por nota se hace en el cliente y en el RPC con `for update`. Queda un residuo: A2 y F4. |
| SEC-001 | Arreglado: se deduplica por `event.id`. |
| SEC-002 | A medias: falta el rate limit y la retención. |
| SEC-006 | Abierto: `stripe-webhook/index.ts:113` acepta `client_reference_id` del navegador. |
| SEC-008 | Abierto: la idempotencia no es atómica (`_shared/webhook_idempotency.ts:5-39`). |
| INFRA-001 / INFRA-002 | Cerrados. |
| MON-001 | El guard ya falla cerrado. Ahora el fallo es el contrario: un Pro sin red pasa a Free (F8). |
| A11Y-001 / UX-001 | Cerrados. |
| UX-003 / A11Y-003 | Abiertos (U7 y U15). |
| Doble penalización SRS | ✔ Sigue: `srs_system.dart:207` y otra vez en `:273` (`_scheduleNextReview`). |

## Back e infraestructura
- **B-C1 ✔ La sync en la nube no funciona para nadie en producción.** El cliente trata a todos como Pro si la monetización está apagada (`subscription_access.dart:19-21`). En cambio, el servidor exige un Pro vigente (`20260725033417_enable_pro_cloud_sync_gate.sql`), y las pruebas de 14 días caducaron hacia el 2026-08-08. Además, `load()` se traga el error y devuelve `null`. Arreglo: abrir el gate solo por propiedad mientras no se cobre, y distinguir «prohibido» de «sin datos».
- **B-C2 No hay ningún backup válido.** El dump es solo de esquema. El run del 2026-11-01 falló y el único artefacto caduca hoy. Además, el repo es público.
- **B-A1** El chequeo de Supabase en Uptime solo existe en esta rama. Los cron se ejecutan desde `main`, así que nada lo vigila.
- **B-A2 ✔** `lastSeen` se guarda en hora local sin offset (`srs_system.dart:158`), y `session_timestamp.dart` la trata como UTC. Con dispositivos en zonas horarias distintas, gana la práctica que no toca. Arreglo: `toUtc()`.
- **B-A3** El descarte de eventos «stale» compara solo `expires_at`. Así se pierden compras con una prueba más corta y bajas o reembolsos.
- **B-A4** SEC-006. **B-A5**: el webhook de Stripe no comprueba `mode`, `payment_status` ni el precio. `expires_at=null` cuenta como Pro para siempre, los errores de consulta se ignoran y falta `unique(stripe_customer_id)`.
- **B-A6** La CI de `main` está roja desde el 2026-08-04, así que producción sigue congelada. **B-A7**: el release de Android se firma con debug y sin `--dart-define`.
- **Medio:**
  - Forma del payload de Stripe según la versión de la API.
  - SEC-008 y `processed_webhook_events` sin purga.
  - `analytics_events` del rol anon sin límites; el comentario CSAT sobrevive al borrado de la cuenta.
  - El borrado de la cuenta no cancela Stripe ni RevenueCat.
  - Una sola fila de suscripción para dos fuentes.
  - Sin tests Deno ni SQL en la CI, y sin deploy de migraciones ni de functions.
  - `merge_user_progress` acepta fechas futuras y tipos inválidos.
- **Bajo:**
  - `revoke` incompleto a `anon` y `authenticated`.
  - La prueba se repite recreando la cuenta.
  - La configuración de Auth no está versionada.
  - La monetización se activa solo con que exista la URL.
  - Versiones sin fijar (`vercel@latest`).
  - RevenueCat local sustituye al servidor.

## Front (lógica)
- **F1 (latente, al activar pagos)** Bucle de refresco: `refresh()` emite `AsyncLoading`, `hasProAccess` pasa de false a true y `AuthSyncListener` vuelve a refrescar.
- **F2 (latente, al activar pagos)** `ProRouteGuard` muestra un spinner en cada recarga, se desmonta `GameScreen` y la sesión vuelve a la ronda 1.
- **F3** Doble envío de una ronda: `submitAnswer` no comprueba `waitingForAnswer`, así que dos toques rápidos se cuentan dos veces en el SRS.
- **F4** «Reiniciar progreso» se deshace con la sync, porque `lastSeen=null` pierde la fusión.
- **F5** Un pool de notas menor que las notas del modo hace que `selectNotes` lance `ArgumentError` y la pantalla se queda colgada.
- **F6 ✔** `setTargetMode` de Velocidad no reinicia el estado (`speed_session_provider.dart:112`) y `reset()` no se llama en ningún sitio. Resultado: rondas e historial duplicados y racha heredada.
- **F7** El timer de Velocidad sigue corriendo tras salir y penaliza el SRS.
- **F8** Un Pro sin conexión pasa a Free y la caché se sobrescribe. `lastKnown` es código muerto.
- **F9 ✔** El historial está limitado a 50 sesiones (`app_preferences.dart:319`) y alimenta la racha y el delta semanal. Con muchas sesiones diarias, las métricas son falsas (D10).
- **Medio:**
  - `setState` sin `mounted` en Velocidad.
  - Carrera al invalidar `srsSystemProvider`.
  - Al cambiar de cuenta, el progreso de A se sube a B.
  - Errores de red tratados como «sin datos».
  - Un historial corrupto se borra entero.
  - El cluster de audio se sintetiza en el hilo de UI.
  - La racha del chip y la de la tira no coinciden.
- **Bajo:**
  - Intervalos de aprendizaje invertidos (7 días frente a 2).
  - `nextGaussian` puede devolver infinito.
  - El audio no se puede detener ni liberar.
  - Las fechas no se recalculan a medianoche.

## UI/UX (veredicto: HOLD)
- **U1 ✔** «Consolidadas» significa dos cosas en la misma card (`mastery_overview.dart:72` frente a `:115`). Basta 1 acierto para contar una nota.
- **U2 ✔** El paywall no gestiona errores (`try/finally` sin `catch`) y `_startTrial` cierra aunque no se active.
- **U3 ✔** «Cerrar» del paywall hace `pop()` sin `canPop` (`paywall_screen.dart:169` y `:305`): es un callejón sin salida si se entra por deep link o por `replace`.
- **U4** Falta el anillo de foco global (SPEC §1.3).
- **U5 ✔** El piano fija un ancho mínimo de 352 (`piano_keyboard.dart:589`), así que a 360 dp las teclas negras salen descolocadas. Los tests usan 390 dp.
- **Medio:**
  - El paywall se muestra dentro del shell, con doble cabecera.
  - Ajustes se queda cargando para siempre si fallan las preferencias.
  - Se ignora el permiso denegado de recordatorios.
  - Saltar el onboarding sobrescribe la notación.
  - Sin `errorBuilder` en el router: la página 404 sale en inglés.
  - Fallos de audio silenciosos; el onboarding da por oída una nota que no sonó.
  - El l10n casi no se usa: 113 literales.
  - Contenedores fijos con texto escalable.
  - Contraste de la rueda < 3:1.
- **Bajo:**
  - 12 hex sueltos.
  - 9 `fontSize` literales.
  - Formato de porcentaje incoherente.
  - «Solo sostenidos» ignora Do/Re/Mi.
  - «Suscribirme (Stripe)».
  - Estados vacíos sin CTA.
  - Parpadeo al restaurar el paso del onboarding.

## Arreglado el 2026-11-03
- **Doble penalización SRS:** se quita la segunda resta en `_scheduleNextReview`.
- **F3:** `submitAnswer` del juego solo actúa en `waitingForAnswer` y con un cerrojo mientras guarda. Además, `startRound` no reabre una ronda saltada mientras sonaba (F10).
- **F5:** `resolvePracticeNotePool` recibe `numNotes` y usa todas las notas si el pool o el foco no llegan.
- **F6:** `setTargetMode` de Velocidad empieza una sesión nueva.
- **F7:** `stop()` en `deactivate` cancela la cuenta atrás, y un contador de generación impide arrancarla tras salir.
- **F11 y F12:** se añaden los `mounted` que faltaban en Velocidad, y Velocidad solo acepta una respuesta por ronda.
- **Tests:** 8 de regresión nuevos. `flutter analyze` sin incidencias; `flutter test` 688 OK.

## Orden sugerido
1. **Hoy:** hacer un backup con datos (B-C2), llevar el uptime de Supabase a `main` (B-A1) y abrir el gate de sync (B-C1).
2. **Bugs que corrompen datos ya:** F3, F6, F7, la doble penalización del SRS, F4, F5, B-A2 y U5.
3. **Confianza y UX:** U1, F9, U2, U3, U7 y la racha incoherente.
4. **Antes de cobrar:** F1, F2, F8, SEC-006, SEC-008, B-A3 y B-A5.
