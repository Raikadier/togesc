# Checklist de QA manual — TOGESC v1.0

Usar antes de cada release (web o móvil). Marcar cada ítem en una sesión de ~45–60 min.

## Automatizado (ejecutar primero)

```powershell
cd "D:\Github repos\togesc"
.\scripts\validate-production.ps1
```

Debe pasar: `flutter analyze`, `flutter test` (285+).

---

## Rediseño v2.1: cierre (lote 8, 2026-10-28)

Las secciones 0–8 son de v1.0 y algunas ya no describen la app (XP en el Home, rejilla bento de modos, pestaña Pro). Esta sección las sustituye para v2.1. Leyenda: **[auto]** lo cubre un test automático (se indica cuál) y **[manual]** pide un dispositivo real y un lector de pantalla.

### Automático (pasado el 2026-10-28)
- [x] [auto] `flutter analyze` sin avisos y `flutter test` completo.
- [x] [auto] `integration_test` en `flutter-tester`: viaje completo en móvil y en escritorio (rail, panel SRS y atajos).
- [x] [auto] Contraste AA de cada texto e icono en Home, Progreso, Perfil, Ajustes, Paywall, Velocidad, Suscripción, Acerca de y Privacidad, en claro y oscuro, móvil y escritorio, más los 4 pasos del onboarding y la hoja de restablecer (`dark_theme_v2_test.dart`).
- [x] [auto] Movimiento reducido con `disableAnimations`: ecualizador del onboarding, latido y destello de velocidad, mapa del oído, hoja de detalle de nota y componentes compartidos (`motion_widgets_test.dart`).
- [x] [auto] Objetivos de 48 px en la barra y el rail, el piano, la velocidad y la entrada a Pro del Perfil. Regiones vivas en la prueba del onboarding.

### Manual con lector de pantalla (pendiente)
- [ ] [manual] **TalkBack (Android)** o **VoiceOver (iOS):** onboarding completo, una sesión de 6 rondas (se anuncia cada resultado y el resumen), detalle de nota en Progreso y Perfil.
- [ ] [manual] **NVDA + Chrome (web):** el mismo recorrido con teclado. Tab recorre el mapa del oído en orden cromático, las pestañas de Progreso cambian con ← →, Esc abre la pausa y A–G responden.
- [ ] [manual] **Movimiento reducido del sistema** (Android «Quitar animaciones», iOS «Reducir movimiento» y `prefers-reduced-motion` en web): nada pulsa ni se desliza.
- [ ] [manual] **Texto más grande** (×1,125) junto al 200 % del sistema: sin cortes en Home, sesión y Ajustes.
- [ ] [manual] **Capturas frente al prototipo** (`docs/design_v2_1/prototype/`) en Android y Chrome con `flutter drive` (ver la cabecera de `integration_test/app_journey_test.dart`).

---

## 0. Navegacion shell (Stitch)

- [x] Header **TOGESC** visible en Home, Stats, Pro y Perfil
- [x] Bottom nav movil: Practica / Stats / Pro / Perfil cambia de tab sin crash
- [x] Juego y velocidad abren **sin** bottom bar (pantalla inmersiva)
- [x] Desktop (>=600px): enlaces Entrenamiento / Estadisticas / Pro en header

## 1. Primera apertura y onboarding

- [x] App nueva muestra **Cómo funciona** (onboarding)
- [x] Toggle **Do/Re/Mi** muestra vista previa correcta
- [x] **Test de audio** suena en el dispositivo
- [x] **Entendido, empezar** lleva a Home
- [x] Acerca de → **Ver tutorial de nuevo** vuelve al onboarding

## 2. Práctica core (modo Una nota)

- [x] Reproducir → escuchar → responder (piano) → resultado → cluster → siguiente ronda
- [x] Sin crashes ni pantalla congelada
- [x] Progreso SRS persiste tras cerrar y reabrir la app

## 3. Home y engagement

- [x] **Enfoque diario**: notas criticas + racha/XP tras 2+ sesiones
- [x] Modos en **grid bento** (no solo lista)
- [x] **Practicar ahora** abre modo una nota
- [x] Mini grafico semanal si hay historial

## 4. Ajustes

- [x] Home → icono **tune** → Ajustes
- [x] Sonido: timbre, volumen, cluster, octavas, duración del tono
- [x] Pool de notas (multi-select)
- [x] Intensidad SRS (relajado / equilibrado / intenso)
- [x] Modo canto / tarareo en **Juego y accesibilidad**
- [x] Tema claro / oscuro / sistema

## 5. Estadisticas Pro dashboard

- [x] Bento superior: precision, intentos, pendientes + **Repasar ahora**
- [x] Radar 12 notas (usuario Pro)
- [x] Filas de dificultad muestran latencia si hay datos

## 6. Modo canto (experimental)

- [x] Web: permiso micrófono → detecta nota al cantar
- [x] Android/iOS: permiso micrófono → detecta nota (entorno silencioso)
- [ ] El audio **no** se sube (verificar sin red si es posible)

## 5. Estadísticas y reflexión

- [x] Resumen SRS carga correctamente
- [x] Tras 2+ sesiones: **Evolución 7 días** muestra barras
- [x] **Historial reciente** lista sesiones
- [x] **Ver progreso por nota (12)** abre detalle
- [x] Reiniciar progreso pide confirmación y funciona

## 6. Cuenta y datos (GDPR)

- [ ] Exportar JSON (web: descarga; móvil: portapapeles)
- [ ] Crear cuenta / iniciar sesión (Supabase configurado)
- [ ] **Sincronizar ahora** sube progreso
- [ ] Segundo dispositivo/navegador: mismo SRS tras sync
- [ ] Eliminar cuenta (con sesión iniciada) borra usuario en nube

## 7. Monetización (si `MONETIZATION_ENABLED=true`)

- [ ] Modo Pro bloqueado muestra paywall
- [ ] Stripe sandbox (web): checkout → `?checkout=success` → Pro activo
- [ ] RevenueCat sandbox (móvil): compra / restaurar

## 8. Regresión web

- [x] [https://togesc.vercel.app](https://togesc.vercel.app) carga tras deploy
- [ ] Audio funciona tras un gesto del usuario (política autoplay)
- [x] Sin errores en consola del navegador (críticos)

---

## Criterio de salida

- **0 crashes** en la sesión
- **0 regresiones** en flujo práctica → SRS
- Sync y pagos validados al menos una vez en sandbox antes de producción

