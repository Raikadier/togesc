# Evaluación del estado de TOGESC: 2026-10-28

Equipo de 7 roles en modo solo lectura, liderado por Claude Code. Rama: `feat/rediseno-v2.1` (PR #9 abierto hacia `main`).

| Rol (agente) | Área |
|---|---|
| DevOps Automator | CI/CD, Vercel, Supabase, backups, ramas |
| Software Architect | Arquitectura, deuda técnica, SRS y audio, tests |
| UI Finish-Gate Reviewer | Rediseño v2.1 frente al SPEC y reglas de CLAUDE.md |
| Accessibility Auditor | WCAG 2.2 AA |
| Application Security Engineer | RLS, Edge Functions, secretos, cliente |
| Payments & Billing Engineer | Monetización y cumplimiento (RGPD, tiendas) |
| Mobile Release Engineer | Android, iOS, web y ficha de tienda |

La marca **✔ verificado** significa que Claude comprobó el hallazgo contra el código o el entorno; el resto viene de los informes de los agentes con evidencia `archivo:línea`.

## Veredicto

**La calidad del código es alta, pero la app NO está lista para el mercado. La infraestructura de producción está caída o abandonada.**

- Lo bueno ✔: `flutter analyze` no da ningún problema y `flutter test` da 680 OK, 1 omitido y 0 fallos (Flutter 3.47.7 en local). La CI del PR #9 también está en verde (Flutter 3.41.4). El rediseño v2.1 cumple lo esencial del SPEC. La accesibilidad está por encima de la media. No hay secretos en el repo.
- Lo malo: Supabase no existe en DNS. La web de producción lleva 95 días sin desplegarse. La monitorización y los backups están desactivados. No se puede cobrar. Android e iOS no se pueden publicar.

## P0: bloqueantes

### Infraestructura
1. **Supabase caído ✔.** `puetlvcsrntwweuxinee.supabase.co` devuelve NXDOMAIN en el DNS público de Cloudflare (`Status: 3`) y curl falla al resolver. Probablemente se ha vuelto a pausar por inactividad; también podría estar borrado. Sin él no funcionan las cuentas, la sync Pro, la analítica ni los webhooks. La app sigue funcionando en local gracias al offline-first.
2. **Monitorización y backups desactivados ✔.** `Supabase Backup` y `Web Uptime Check` aparecen como `disabled_inactivity` desde el 3 y 4 de octubre, y por eso nadie avisó de la caída. Solo queda **un artefacto de backup, de 4082 bytes** (sospechoso: parece solo el esquema), y **caduca el 2026-11-03**. El workflow de backup solo vuelca el esquema (PT-16).
3. **Producción web congelada.** Vercel sirve un despliegue del 2026-07-24 (≈63eb776): 16 commits por detrás de `main` y 36 por detrás de la rama. `deploy-web.yml:11-15` exige un `push` a `main` con la CI en verde, y la CI de `main` está en rojo desde el 2026-08-04. Vercel no construye desde Git (`vercel.json:4`, `ignoreCommand: exit 0`).

### Monetización (Stripe y RevenueCat)
4. **Paywall sin términos ni precio ✔.** No hay términos de uso ni EULA. El paywall dice «El precio se muestra en la tienda» (`paywall_screen.dart:248-251`) y no enlaza a términos ni privacidad. Incumple App Store 3.1.2 y las normas de Google Play para suscripciones.
5. **Sin configurar.** Faltan secretos en GitHub (`MONETIZATION_ENABLED`, `STRIPE_CHECKOUT_URL`, `STRIPE_PORTAL_URL`) y en Supabase (`STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `REVENUECAT_WEBHOOK_SECRET`). No hay productos, Payment Link ni entitlement configurados. `build-android.yml` no pasa ningún `--dart-define`.
6. **En móvil, RevenueCat pisa el estado de Supabase ✔** (`subscription_service.dart:52-58`). Quien paga en la web o tiene la prueba de servidor de 14 días aparece como Free en el móvil. El CTA «Probar 14 días gratis» no hace nada en móvil.
7. **SEC-006 abierto ✔.** El webhook acepta `client_reference_id` sin validarlo (`stripe-webhook/index.ts:113`). Un tercero puede asociar su pago a otra cuenta. SEC-007 está a medias: RevenueCat valida el formato UUID, pero no que el usuario exista; Stripe no valida nada.

### Publicación móvil
8. **La release de Android se firma con debug ✔** si falta `key.properties` (`android/app/build.gradle.kts:52-56`). No hay secretos `ANDROID_*`. El workflow AAB no se ejecuta desde el 2026-06-24 (falló entonces y los logs han caducado).
9. **iOS no se puede archivar.** No tiene `DEVELOPMENT_TEAM`, ni CI, ni Fastfile. Falta `PrivacyInfo.xcprivacy` (riesgo ITMS-91053 por `shared_preferences`).

## P1

### Lógica y comportamiento de la app
- **Bug del SRS: doble penalización al olvidar ✔** (`lib/services/srs_system.dart:207` y `:273`). En consolidación, un fallo resta `forgetPenaltySteps` dos veces: una nota con índice 4 cae a 0 y se queda con `isLearning=false`. El test solo cubre el índice 1 (`test/unit/srs_system_test.dart:256`).
- **El feedback de la ronda espera a la red.** Se hace `await saveProgress()` (3 llamadas) y `await analytics.roundCompleted` antes de mostrar el resultado (`game_session_provider.dart:304-307`). Con Supabase caído, el resultado se retrasa. Además, la respuesta **puede enviarse dos veces** (`game_screen.dart:375-388` no anula `_roundStartTime`, y el provider no comprueba la fase).

### Pagos y webhooks
- **SEC-008 abierto ✔.** La idempotencia de los webhooks primero consulta y luego inserta, sin atomicidad (TOCTOU) (`_shared/webhook_idempotency.ts:5-39`). Los eventos sin usuario se marcan como procesados y se pierden.
- **PT-04.** `checkout.session.completed` no comprueba `mode`, `payment_status` ni el price; una sesión sin suscripción deja `expires_at=null`, que equivale a Pro para siempre. **PT-05:** falla en abierto si no encuentra la fila, y falta `unique(stripe_customer_id)`.
- **Pagos en móvil.**
  - Sin `Purchases.logIn/logOut`: al cambiar de cuenta, las compras van al usuario anterior.
  - Sin conexión, quien paga pierde Pro, porque `lastKnown` se guarda pero no se lee.
  - Borrar la cuenta no cancela la suscripción.

### Privacidad y accesibilidad
- **Privacidad (RGPD).**
  - La política no identifica al responsable ni da email de contacto, base legal, plazos de conservación, transferencias internacionales ni la reclamación ante la AEPD.
  - La analítica está activa por defecto, sin consentimiento, y envía el `user_id` y el texto libre de la CSAT.
  - `google_fonts` se descarga en tiempo de ejecución (`app_theme.dart:575`), lo que supone una petición a Google y rompe el offline-first.
- **Accesibilidad.**
  - En iOS y escritorio, el modo Velocidad no anuncia los aciertos ni los fallos (falta `sendAnnouncement`), y el destello solo usa color (WCAG 4.1.3 y 1.4.1).
  - Falta el anillo de foco global que pide el SPEC v2.1 §1.3 ✔: `app_theme.dart` solo tiene `focusedBorder` en los campos de texto.

### Publicación
- **Android:** `INTERNET` no está declarado en el manifiesto `main`; hay que confirmar el manifiesto fusionado.
- **Política de privacidad:** solo existe como ruta `/#/privacy` (SPA); las tiendas piden una página estática.
- **Formularios de las tiendas:** no hay borrador de Data safety ni de App Privacy.

## P2 (resumen)

### CI y repositorio
- Flutter 3.41.4 en CI y 3.47.7 en local; Vercel no fija versión de Flutter.
- `main` no tiene protección de rama.
- 8 PR de dependabot abiertos, algunos con saltos de versión mayor (riverpod 3, soloud 4, purchases 10).

### UI y accesibilidad
- **Colores hex sueltos en widgets** (incumplen la regla de CLAUDE.md): `piano_keyboard.dart` (147, 153, 199, 209, 218-220, 485, 538, 544, 697), `today_session_hero.dart` (107, 274, 276, 295), `home_app_bar.dart:51`, `free_practice_tiles.dart:185,192`, `statistics_screen.dart:290`, `ear_map_wheel.dart:275`.
- **Contraste insuficiente:**
  - Los rellenos de la rueda sobre la pista no llegan a 3:1 (ámbar 1,55:1, rojo 2,95:1) y no tienen borde.
  - La selección del piano clásico en el tema claro da 1,79:1; habría que usar `selectionDeep`.
- **Sin animar** el pop de la nota en el anillo ni la subida de la píldora SRS (SPEC §2.2.3).
- **Riesgos de desbordamiento:** etiquetas del piano con `overflow: visible` y altura fija, y teclado de 336/352 dp de ancho mínimo en pantallas de 320 dp.

### Lógica y producto
- **Riesgos D10:** «Mejor tiempo» de Velocidad incluye respuestas falladas, y `mode_started` se emite en cada ronda (infla las métricas).
- **Diagnóstico de sync engañoso:** marca `remoteReachable: true` aunque haya un error.
- **Audio:** `playBuffer` puede colgarse (no tiene timeout) y no se gestionan las interrupciones ni `AVAudioSession`.
- **Seguridad del cliente:** contraseña mínima de 6 caracteres y los mensajes de error de auth permiten enumerar cuentas (PT-08); la analítica anónima no tiene rate limit (PT-09).

### Pagos
- `past_due` pasa a Free sin periodo de gracia.
- No se gestionan `charge.refunded` ni las disputas.
- Las dos fuentes de pago (Stripe y RevenueCat) comparten fila y una puede degradar a la otra.

### Documentación y tests
- `Plan/system_design.md` está desfasado: cita `result_card.dart`, que no existe, y le faltan rutas y la RPC `merge_user_progress`.
- Sin tests: `subscription_service`, `mobile_purchases_service`, `supabase_*_repository`, `sync_provider`, `auth_provider` y `analytics_service`.

## P3 (resumen)
- **Basura versionada ✔:** dos zips de Stitch (6,5 MB) y `debug_analysis.md` en la raíz.
- **Dependencias:**
  - `intl: any` no tiene versión fijada.
  - `cupertino_icons` y `mocktail` no se usan.
- **Código muerto:** `afterProgressSaveProvider`.
- **Android:**
  - El icono adaptativo se recorta.
  - El splash es blanco.
- **iOS:**
  - Falta `ITSAppUsesNonExemptEncryption`.
  - La descripción del micrófono no lleva tildes («microfono»).
- **`theme-color` distinto** entre `index.html` y el manifest.
- **Supply chain:** se instala `vercel@latest`, las Actions se fijan por tag y no por SHA, y no hay `deno.lock`.
- **Ayudas para hipoacusia:** no hay balance ni mono, ni aviso de auriculares.

## Lo que funciona
- **Arquitectura:** capas limpias (UI → providers → services → repositorio local, híbrido o Supabase) y offline-first real.
- **Tests y CI:** 680 tests en verde y analyze limpio; la CI del PR está en verde y se puede fusionar.
- **Rediseño v2.1:**
  - La sesión es el único CTA, la rueda es la firma visual y no hay XP en el Home.
  - Todo el movimiento pasa por `motionDuration`.
  - La ortografía es correcta.
- **Accesibilidad:** el piano y la rueda tienen semántica completa, los `IconButton` tienen tooltip y `largeText` se compone bien con el escalado del sistema.
- **Seguridad:**
  - RLS en todas las tablas, con escritura por RPC `SECURITY DEFINER` y `search_path=''`.
  - RevenueCat compara la firma en tiempo constante y aplica allowlists (PT-01 cerrado en código).
  - CSP y HSTS en `vercel.json`.
  - Sin secretos en el historial.

## No verificado
- Si Supabase está pausado o borrado, las migraciones aplicadas y el PITR. No hay CLI de `supabase` en esta máquina.
- El contenido real del backup de 4082 bytes.
- Si la CI de `main` pasará después de fusionar el PR #9.
- Si el AAB compila hoy y cómo queda el manifiesto fusionado de release.
- Cualquier build de iOS (no hay Mac).
- Pruebas con lectores de pantalla reales (TalkBack, VoiceOver, NVDA), renderizado al 200 % y capturas frente al prototipo.
- Los paneles de Stripe, RevenueCat, Play Console, App Store Connect y Vercel.
- La revisión legal de los textos.

## Orden recomendado

### Urgente: esta semana
1. **Reactivar Supabase** desde el panel (si está borrado, recrearlo desde las migraciones). **Descargar el backup del 10-04 antes del 2026-11-03.**
2. **Reactivar los workflows** de Backup y Uptime, y que el backup incluya los datos, no solo el esquema.

### Corto plazo
3. **Fusionar el PR #9** y comprobar que la CI de `main` pasa y que Deploy Web despliega.
4. **Corregir el bug de doble penalización del SRS**, con un test para índices ≥ 2. Quitar la red del camino crítico del feedback y evitar el doble envío.
5. **Proteger `main`** (exigir la CI en verde) y quitar los zips del repo.

### Antes de lanzar
6. Seguir con la fase R3 del plan de recuperación:
   - SEC-006/007/008, PT-04 y PT-05.
   - La lógica de fusión Supabase/RevenueCat.
   - Términos de uso y paywall con precio.
   - Secretos y productos.
   - Consentimiento de analítica.
7. **Publicación móvil:**
   - Hacer que el build de release falle si no hay keystore y configurar Play App Signing.
   - Pasar los `--dart-define` al AAB.
   - Añadir `PrivacyInfo.xcprivacy`, una página de privacidad estática y los borradores de Data safety y App Privacy.
8. **Pulido de UI y accesibilidad:**
   - Anillo de foco global y colores hex a tokens.
   - Contraste de la rueda y del borde de selección del piano.
   - Anuncios del modo Velocidad.
