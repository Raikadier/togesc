# Hoja de ruta — Rediseño v2.1 (para Claude Code)

**Qué es:** el plan de implementación en Flutter del pulido v2.1, diseñado en Open Design el 2026-10-26.
**Qué leer primero, en este orden:**
1. `docs/design_v2_1/SPEC_rediseno_v2_1.md`: qué cambia, pantalla por pantalla.
2. `docs/design_v2_1/prototype/`: la referencia visual e interactiva. Abre `index.html` en un navegador; cada pantalla es su propio HTML.
3. `DESIGN.md` y `PRODUCT.md`: el sistema y las restricciones que siguen vigentes.
4. `Plan/progreso_rediseno_v2.md`: cómo se registraron los lotes de v2 (mismo formato).

**Cómo se trabaja:** por lotes. **Un lote por sesión de Claude Code y un PR por lote.** No se empieza un lote hasta que el anterior esté en verde.

---

## Reglas para el agente (obligatorias)

1. **El prototipo es referencia, no código.** No portes CSS ni JS: traduce la composición, la jerarquía, los estados y el movimiento a widgets Flutter. Reutiliza lo que ya existe antes de crear nada:
   - `PianoKeyboard` (variante `session`) y `SessionPhaseRing`;
   - `SrsLevelPill`, `NoteMasteryGrid` y `SessionEvolutionChart`;
   - `TogescShell`, etc.
2. **Nada de hex sueltos en widgets.** Usa `DesignTokens`, `ColorScheme` o `TogescColors.of(context)`. Si falta un token, añádelo en `design_tokens.dart` y pasa su contraste por `contrastRatio` en `test/unit/design_tokens_v2_test.dart`.
3. **Sin datos inventados (D10).** Cada número del prototipo debe salir de un provider real. Si no existe, el elemento se oculta y se apunta en el log. Los datos del prototipo son de demostración.
4. **Todo movimiento respeta** `UiPreferences.reduceAnimations` y `MediaQuery.disableAnimations`.
5. **Accesibilidad:**
   - `Semantics` en cada control nuevo;
   - foco visible;
   - objetivos táctiles de 48 o más;
   - el color nunca como única señal.
6. **Copy en español con ortografía completa.** Usa los textos del prototipo o del SPEC; si chocan con los textos actuales de la app, gana el texto actual y se anota.
7. **Mantén las `ValueKey` existentes** (`today-start-cta`, `account-pro-entry`, `nav-*`, `free-tile-*`, etc.). Las claves nuevas usan los `data-od-id` del prototipo en kebab-case (`ear-map`, `session-start`, `session-summary`…).
8. **Al cerrar cada lote:**
   - `flutter analyze` sin issues (el CI trata los info como fatales);
   - `flutter test` completo en verde;
   - una entrada en `Plan/progreso_rediseno_v2_1.md` (créalo en el lote 0), con el mismo formato que `progreso_rediseno_v2.md`.
9. **Cambios mínimos fuera del alcance del lote.** Si encuentras un bug ajeno, anótalo en el log y no lo arregles salvo que bloquee.
10. **No hagas commit ni push sin que el propietario lo pida.**

Comandos (desde `TOGESC/togesc`):
```bash
flutter analyze
flutter test
flutter test integration_test -d flutter-tester
```

---

## Lote 0 · Preparación
- [ ] Hay cambios sin commitear en `feat/rediseno-v2`: `game_session_provider`, `speed_session_provider`, `srs_provider`, `game_screen` y sus tests. **Pregunta al propietario** si se commitean o se descartan antes de crear la rama. No los toques.
- [ ] Crea la rama `feat/rediseno-v2.1` desde la rama de v2 ya limpia.
- [ ] Crea `Plan/progreso_rediseno_v2_1.md` con su cabecera.
- [ ] Añade a `DESIGN.md` una sección «v2.1» que remita al SPEC. Sube `version` a 2.1 y cambia `updated` en el front-matter.
- [ ] Añade a `PRODUCT.md`, en «Notas», la decisión del 2026-10-26: pulido v2.1 por feedback de genericidad, movimiento, accesibilidad e intuición. **Se mantiene: sin XP en el Home.**

**Hecho cuando:** existe la rama, los docs están actualizados y `analyze` y `test` pasan en verde sin cambios de código.

## Lote 1 · Tokens y preferencias
- [ ] `design_tokens.dart`: añadir `easeOut`, `easeSpring`, `durationKey`, `durationFast`, `durationMedium`, `staggerStep`, `staggerWheel` y las medidas de la rueda (`earMapInner`, `earMapOuter`).
- [ ] Añadir un helper `motionDuration(context, d)` que devuelva `Duration.zero` si el movimiento está reducido.
- [ ] `TogescColors`: añadir el rol `earMapTrack` en claro, oscuro y sobre hero, y comprobar que la celda vacía en oscuro es #241B2A.
- [ ] `UiPreferences`: añadir `largeText` (bool, por defecto false) con persistencia, `copyWith` y tests en `ui_preferences_test.dart`.
- [ ] `main.dart` / `app.dart`: aplicar `TextScaler.linear(1.125)` cuando `largeText` esté activo, combinado con el escalado del sistema.

**Tests:** los tokens nuevos (contraste) en `design_tokens_v2_test.dart`, más los de `ui_preferences_test.dart`.

## Lote 2 · Componentes compartidos
- [ ] **`lib/widgets/ear_map/ear_map_wheel.dart`** (SPEC §1.1):
  - `CustomPainter` para los sectores, con `Semantics` y `Focus` por segmento (se puede superponer una capa de `Semantics` con su `Rect` o `Path`);
  - callbacks `onHover` y `onSelect`, y las variantes `onDark` y `compact`;
  - animación escalonada;
  - entrada de datos: `List<NoteProgressSummary>` o un modelo ligero `(pct, srsLevel)` por clase de altura.
- [ ] **`CountUpText`** (`lib/widgets/count_up_text.dart`).
- [ ] **`StaggeredEntrance`**, un wrapper para la subida de 12 px con *fade* y su índice.
- [ ] **`PianoKeyboard` (variante `session`):**
  - hundimiento de 2 px, onda y pop o shake en el resultado;
  - el icono ✓/✗ con escala spring;
  - modo `largePiano` con las medidas del SPEC §1.3;
  - nada de esto cambia la API pública si no hace falta.
- [ ] **`SessionPhaseRing`:** arco de progreso de `listen` (`AnimationController` de 1,5 s) y halo de resultado.

**Tests:**
- widget tests de cada componente: Semantics de los 12 segmentos, foco con Tab y activación con Enter, y que con `reduceAnimations` no queden animaciones pendientes;
- un golden opcional de la rueda en claro y oscuro.

## Lote 3 · Home
Referencia: `prototype/home.html` y SPEC §2.1.
- [ ] Hero: punto pulsante, estado en las mini-cards y lista de 3 pasos.
- [ ] Hoja «Ajustar enfoque y duración» (sustituye al enlace), conectada a `today_session_provider`: rondas 6/12/20 y de 1 a 4 notas foco.
- [ ] Card «Mapa del oído» con la meta de octava (N de 12 con ≥ 75 %) y la fila de detalle «Practicar», que abre `/game/:id` con la nota.
- [ ] Semana: «Últimos 7 días», celda de hoy con borde discontinuo y frase de racha (con `engagement_stats`).
- [ ] Layout de escritorio en dos columnas con la derecha *sticky*.

**Tests:** actualizar `home_screen_test.dart` y `home_v2_widgets_test.dart`, y añadir las claves `ear-map`, `today-adjust-sheet` y `octave-goal`.

## Lote 4 · Sesión (el más delicado)
Referencia: `prototype/session.html` y SPEC §2.2.
- [ ] **Estado «Preparado» siempre al entrar:** reutilizar `SessionPhase.idle` y `GameState.idle`. CTA «Estoy listo» (clave `session-start`), que llama a `captureUserGesture` y arranca; también con Espacio. Botón «Probar el sonido».
- [ ] **Snapshot SRS:** en `game_session_provider`, guardar al empezar el nivel y la precisión de cada nota, para poder comparar en el resumen.
- [ ] **Medir el tiempo de respuesta** por ronda (desde que empieza `answer` hasta el toque). Comprobar si ya existe en `RoundResult` antes de añadirlo.
- [ ] Mensaje «¡N seguidas!» con 3 o más aciertos seguidos.
- [ ] Hoja «Instrumento de esta sesión» en todos los tamaños. Revisar `session_instrument_sheet.dart`, que ya existe.
- [ ] Hoja de pausa (Continuar / Reiniciar / Salir sin guardar), con Esc y con el botón volver.
- [ ] **Resumen al terminar** (clave `session-summary`): medalla, KPI, cambios de nivel SRS, rueda oscura y acciones. Sustituye a la vuelta directa o al «Volver al inicio» actual de `game_screen.dart`.
- [ ] Panel SRS de escritorio: resaltar la nota de la ronda y añadir «Esc · Pausar».

**Tests que se van a romper (actualizarlos, no borrarlos):**
- `test/integration/full_game_flow_test.dart`: hoy espera la sesión **directamente en listen** tras `today-start-cta`. Hay que añadir el toque en `session-start` y, al final, verificar `session-summary` en lugar del texto anterior.
- `integration_test/app_journey_test.dart`: lo mismo en móvil y escritorio. Añadir las capturas `02a_session_ready` y `13_session_summary`.
- `test/widget/game_screen_test.dart` y `test/unit/session_v2_test.dart`: el estado inicial pasa a ser `idle` y hay un paso nuevo hasta el resumen.
- Añadir tests de la diferencia SRS antes/después y del tiempo medio.

## Lote 5 · Progreso
Referencia: `prototype/progress.html` y SPEC §2.3.
- [ ] Pestañas Resumen / Historial (accesibles, con flechas).
- [ ] La precisión global con `CountUpText` y la meta con degradado. El delta semanal **ya existe** en `global_accuracy_header.dart`: reutilizarlo.
- [ ] KPI «Pendientes» pulsable, que lleva a la sesión de hoy.
- [ ] Selector Rueda / Rejilla en móvil y las dos en escritorio. Icono `schedule` en las celdas vencidas (`isOverdue`).
- [ ] Hoja de detalle de nota con precisión, intentos, latencia (`avgResponseTimeSec`), nivel y las acciones Escuchar y Practicar.
- [ ] «Tus extremos» (Pro), con el *gating* actual de estadísticas avanzadas.
- [ ] Historial: barras rellenas reutilizando o adaptando `session_evolution_chart.dart`, con Semantics de resumen.

**Tests:** `statistics_screen_test.dart` y `note_progress_screen_test.dart`, más un test de la hoja de detalle.

## Lote 6 · Velocidad
Referencia: `prototype/speed.html` y SPEC §2.4.
- [ ] Tarjetas radio de dificultad con su mejor racha (persistir si no existe) y card hero «Teclas negras».
- [ ] Juego: cuenta atrás con pop, temporizador en anillo con estado bajo y destello verde o rojo.
- [ ] Resumen con «Nuevo récord personal».
- [ ] **No cambiar las reglas de `speed_session_provider`** sin confirmarlo con el propietario (SPEC §2.4.4).

**Tests:** `speed_screens_test.dart`.

## Lote 7 · Perfil, Paywall, Onboarding y Ajustes
Referencias: `prototype/profile.html`, `paywall.html`, `onboarding.html` y `settings.html`, y SPEC §2.5–2.8.
- [ ] **Perfil:** cabecera según haya cuenta o no, «Tu oído en cifras», card hero del plan, estado de sincronización con icono y texto, interruptores en línea y eliminar cuenta en una hoja.
- [ ] **Paywall:** layout hero con la tabla comparativa. **Sin precios inventados.** Mantener la lógica y los mensajes de monetización.
- [ ] **Onboarding:** 4 pasos con la ronda de prueba (paso 3) y las preferencias (paso 4, con «Texto más grande»).
- [ ] **Ajustes:** 5 grupos, accesibilidad primero, vista previa del piano en vivo y rejilla de timbres con preescucha.

**Tests:** `paywall_screen_test.dart`, `onboarding_screen_test.dart`, `router_onboarding_test.dart` y el de ajustes, si existe (si no, crearlo).

## Lote 8 · Cierre
- [ ] Pasar `docs/qa_checklist.md` completo, con TalkBack o VoiceOver, NVDA en la web y movimiento reducido.
- [ ] `integration_test` en Android y Chrome, comparando las capturas con el prototipo.
- [ ] Contraste del tema oscuro de las pantallas principales (`dark_theme_v2_test.dart`) con los widgets nuevos.
- [ ] Actualizar `DESIGN.md`, marcando como **Vigente** o **Sustituido** cada punto que cambió.
- [ ] PR final y preview en Vercel.

---

## Prompt de arranque para Claude Code
Copiar y pegar al empezar cada lote, cambiando el número:

```
Lee Plan/hoja_ruta_rediseno_v2_1.md (reglas y Lote N), docs/design_v2_1/SPEC_rediseno_v2_1.md
y el HTML del prototipo que corresponda en docs/design_v2_1/prototype/.
Implementa SOLO el Lote N siguiendo las reglas del agente. Antes de escribir código, dame un plan
corto con los archivos que vas a tocar. Al terminar: flutter analyze, flutter test, y añade la
entrada del lote en Plan/progreso_rediseno_v2_1.md. No hagas commit.
```
