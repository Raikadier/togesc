# Progreso — rediseño v2.1

Log en orden cronológico inverso. Hoja de ruta: `Plan/hoja_ruta_rediseno_v2_1.md`. Qué cambia: `docs/design_v2_1/SPEC_rediseno_v2_1.md`.

## 2026-10-27 · Lote 3: Home · Claude Code
- **Hero** (`today_session_hero.dart`):
  - `HeroLiveDot` junto a «Sesión de hoy»: escala 1 → 1,6 con fade, 1,8 s por pulso. **Late solo dos veces y se queda quieto** (3,6 s). El prototipo lo deja en bucle, pero eso superaría los 5 s de movimiento automático de WCAG 2.2.2 y colgaría los `pumpAndSettle` de los tests y del e2e. Con movimiento reducido, quieto.
  - Las mini-cards muestran el % y el estado en texto (`focusNoteStateLabel`: Nueva, Crítica, En curso o Consolidada, según los umbrales de dominio). El estado también va en Semantics.
  - `HeroSteps`: «1 · Escucha», «2 · Toca la tecla» y «3 · El SRS ajusta tu repaso», con los iconos `hearing`, `piano` y `trending_up` en #DA9CFF.
  - Copy según el número de notas (la nota, dos, tres o cuatro, con concordancia en singular) y copy propio cuando el foco se elige a mano («Elegiste N notas foco para hoy; el resto sigue el repaso SRS normal.»).
  - **Se mantiene el copy actual frente al del prototipo** (regla 6 y D10). «Que perdieron precisión esta semana» es una afirmación que los datos no respaldan.
- **Hoja «Ajustar la sesión de hoy»** (`today_adjust_sheet.dart`, clave `today-adjust-sheet`). El enlace `today-adjust-link` la abre en lugar de ir a Ajustes.
  - Duración segmentada: 6 · 3 min, 12 · 6 min y 20 · 10 min.
  - Chips de las 12 notas con muestra de dominio y Semantics «C sostenido, 42 %».
  - De 1 a 4 notas foco. La quinta muestra un aviso en una región viva y no se deja quitar la última.
  - Guardar y Cancelar, y un SnackBar «Sesión de hoy actualizada».
  - **Al guardar:**
    - La duración va a `practiceSessionPreferences.roundGoal`, persistida. Es la misma meta que en Ajustes y se añade `SessionRoundGoal.six`.
    - Las notas van a `todayFocusOverrideProvider`. Es un estado nuevo en `today_session_provider`, **en memoria y solo para ese día**: se pierde al reiniciar y al cambiar de día vuelve la propuesta del SRS. Si se quiere persistido, haría falta una clave en `AppPreferences`; queda anotado.
  - `maxPracticeFocusNotes` pasa de 3 a 4 (v2 D11 → SPEC v2.1). El plan automático sigue proponiendo 3.
- **Card «Mapa del oído»** (`ear_map_card.dart`):
  - `EarMapWheel` con la precisión global en el centro. Se calcula con `globalAccuracyFromSummaries`, con la misma fórmula que `accuracy_percentage` del SRS, y muestra «—» sin datos.
  - Leyenda con los rangos escritos y enlace «Ver progreso».
  - **Meta de octava** (`octave-goal`): anillo y «N de 12 notas consolidadas», con N = notas vistas con ≥ 75 %, y «Te faltan M…» o «Dominas la octava completa».
  - Al tocar un segmento aparece una fila de detalle (`ear-map-detail`, región viva) con celda, estado, «% · intentos · nivel» y **Practicar** (`ear-map-practice`). Practicar abre `/game/1` con `practiceFocusNoteProvider` = nota y el foco de hoy vacío.
- **Últimos 7 días** (`week_strip.dart`):
  - `buildRecentDays` (de hace 6 días a hoy) y `recentDaysProvider`. `calendarWeekProvider` (L–D) se queda: lo usa `today_session_provider_test`.
  - La celda de hoy se rotula «HOY». Si la meta está pendiente, lleva superficie de tile y borde discontinuo de acento (`week-today-pending`).
  - **Frase de racha** (`week-streak-copy`) con `homeStreakStatusProvider`. Como `computeStreakDays` da 0 si hoy no se ha practicado, «llevar la racha a N» usa la racha hasta ayer + 1.
- **Escritorio (≥ 1024):** dos columnas, 1,25 fr / 1 fr, con un máximo de 1120 (`homeDesktopMaxWidth`).
  - Izquierda: hero, Retomar y Práctica libre. Derecha: mapa y días.
  - El efecto *sticky* se consigue con un scroll independiente en cada columna: la derecha no se mueve al desplazar la izquierda. Lo cubre un test.
  - En móvil, el orden es el del prototipo.
- **Entrada escalonada:** `StaggeredEntrance` en cada bloque.
- **Tests:**
  - `home_screen_test`: hoja (guardar, límite de 4, cancelar), hero (punto, estados, pasos), mapa (70 %, meta 2 de 12, Semantics del segmento, detalle y Practicar), últimos 7 días con racha pendiente y cumplida, y escritorio en dos columnas con la derecha fija.
  - `home_v2_widgets_test`: copy por número de notas y a mano, estado de la mini-card, «HOY» y borde discontinuo, `buildRecentDays`, `weekStreakCopy` y `HomeStreakStatus.fromHistory`.
  - Ajustados: `dark_theme_v2_test` (hoy pendiente va sobre tile con borde discontinuo) y `game_session_provider_test` (límite de foco de 4).
- **No incluido:** `CountUpText` en el centro de la rueda, porque `EarMapWheel` recibe el valor como texto. Habría que aceptar un widget en el centro; queda para el lote de Progreso.
- **Verificación:**
  - `flutter analyze`: «No issues found!».
  - `flutter test`: `+572 ~1: All tests passed!` (antes 558).
  - `flutter test integration_test -d flutter-tester`: `+2: All tests passed!`.
  - **No revisado a ojo en un navegador.**

## 2026-10-27 · Lote 2: componentes compartidos · Claude Code
- **`lib/widgets/ear_map/ear_map_wheel.dart` (`EarMapWheel`, clave `ear-map`):**
  - Entrada: `List<NoteProgressSummary>`, colocados por nota. Las que faltan cuentan como «sin datos».
  - Un `CustomPainter` dibuja pista, relleno (`masteryColor` y mínimo 6 %), resaltado al pasar el ratón o con foco (primario al 14 %), anillo de foco de 3 px y contorno de la nota seleccionada (`selectedNote`).
  - Etiquetas a r = 146 (148 en la compacta) con la notación activa. Centro: `centerValue` y `centerCaption`, o «{nota} · nivel X/5» con su % al pasar el ratón o con foco.
  - Cada segmento tiene `Semantics` propio (`ear-map-segment-{nota}`, con la etiqueta de `NoteMasteryCell.semanticsLabelFor`) y es un `Focus` con Enter, Espacio, toque y clic. Las zonas táctiles se recortan con `ClipPath` al sector, que se amplía hasta la etiqueta para superar los 48 px.
  - Tab va en orden cromático gracias a `WidgetOrderTraversalPolicy`. Sin ella, el orden era geométrico y empezaba por A#; lo detectó el test.
  - Callbacks `onSelect` y `onHover`. Variantes `onDark` (pista blanca al 8 % y texto claro) y `compact`.
  - Entrada escalonada: escala .55 → 1 con `easeSpring` y fade, 900 ms por segmento, 45 ms de desfase y 120 ms iniciales. Con movimiento reducido no hay animación.
- **`CountUpText`** (`lib/widgets/count_up_text.dart`): cuenta de 0 al valor en 900 ms con `easeOutCubic`. Con movimiento reducido muestra el valor final. El lector lee solo el valor final o `semanticsLabel`.
- **`StaggeredEntrance`** (`lib/widgets/staggered_entrance.dart`): sube 12 px con fade en 600 ms con `easeOut`, con un retardo de `index × staggerStep`. Con movimiento reducido no anima.
- **`PianoKeyboard` (variantes de sesión), sin cambios en la API pública:**
  - Hundimiento de 2 px (antes 3) en `durationKey`, y onda #DA9CFF al 50 %.
  - `_KeyFeedbackMotion`: pop (−4 px y ×1,03, 450 ms) al pasar a correcta y shake (±4 px, 400 ms) al pasar a errónea.
  - Icono ✓/✗ con escala .4 → 1 y `easeSpring`.
  - `large` aplica «Piano más grande»: 270 y negras de 44×160 en móvil, 250 y 58×150 en escritorio (tokens nuevos `pianoSessionLarge*` y `pianoSessionWideLarge*`).
  - Se mantienen `piano-key-*` y `piano-session-container`.
- **Fuera del componente (mínimo):** `game_screen` pasa `large: ui.largePiano` al teclado. Antes la preferencia «Piano más grande» no hacía nada en la sesión v2. La pantalla de velocidad sigue sin pasarla; queda para su lote.
- **`SessionPhaseRing`:** pasa a `StatefulWidget` con la misma API, más `listenDuration` (1,5 s por defecto).
  - Un arco de progreso lineal se pinta sobre el borde en `listen`.
  - Halo de 1,2 s al entrar en `result`: `BoxShadow` de 0 a 26 px que se desvanece.
  - Sin arco ni halo con movimiento reducido.
- **Tests (+23):**
  - `ear_map_wheel_test.dart` (10): Semantics de los 12 segmentos, «sin datos», notación Do/Re/Mi, Tab en orden cromático más Enter y Espacio, centro con foco, toque, sin `onSelect` no hay botones, un solo frame con movimiento reducido, la entrada termina, y las variantes oscura y compacta.
  - `motion_widgets_test.dart` (13): `CountUpText`, `StaggeredEntrance`, medidas del piano grande, pop, shake y reposo, sin animación con movimiento reducido, y halo y arco del anillo.
- **No incluido:**
  - El golden opcional de la rueda. Las fuentes en Windows y en el CI de Linux difieren y daría falsos fallos; mejor hacerlo cuando haya un entorno de goldens fijo.
  - El borde de 1 px del relleno para el contraste (ver lote 1). Queda pendiente para cuando la rueda se monte en Home y Progreso.
- **Bug ajeno anotado (no se arregla):** fuera de `TogescApp`, con `disableAnimations` y `PianoKeyboard` de sesión, al llegar el resultado queda una animación implícita de unos 200 ms que no es nuestra (ya pasaba en HEAD; parece de `Material`). En la app no se nota porque `TickerMode` está desactivado con «Reducir animaciones». Solo afecta a `disableAnimations` del sistema.
- **Verificación:** `flutter analyze`: «No issues found!». `flutter test` completo: `+558 ~1: All tests passed!` (antes 535).

## 2026-10-27 · Lote 1: tokens y preferencias · Claude Code
- **`design_tokens.dart`:**
  - Tokens nuevos: `easeOut`, `easeSpring`, `durationKey`, `durationFast`, `durationMedium` (alias de `motionKeyPress`, `motionFast` y `motionMedium` para no tocar los widgets v2), `staggerStep`, `staggerWheel`, `earMapViewBox`, `earMapInner`, `earMapOuter`, `earMapInnerCompact`, `earMapOuterCompact` y `earMapTrackOnHero` (#14FFFFFF).
  - Helper `motionDuration(context, d)`: devuelve `Duration.zero` si `MediaQuery.disableAnimations` está activo. Basta con leer `MediaQuery`, porque `TogescApp` ya combina ahí `reduceAnimations`. Sin `MediaQuery` arriba, devuelve `d`.
- **`TogescColors`:** roles `earMapTrack` (claro #F3ECF1, oscuro y sesión #241B2A) y `earMapTrackOnHero`, con `copyWith` y `lerp`. Se comprueba que la celda vacía (`muted`) en oscuro es #241B2A, y lo es.
- **`UiPreferences.largeText`:**
  - Bool, `false` por defecto. Se persiste con la clave `togesc_large_text` y tiene `copyWith`, `setLargeText` en el notifier y salida en el export JSON (`ui.large_text`).
  - Aún no tiene interruptor en Ajustes (lote de Ajustes/Onboarding).
- **`main.dart`:** `TogescApp` aplica `applyLargeText(media.textScaler, largeText:)`, de `lib/app/large_text_scaler.dart`.
  - Envuelve el escalado del sistema y multiplica ×1,125 en `scale()`, en lugar de usar `TextScaler.linear(factor·1,125)`, para no perder un escalado del sistema no lineal (Android 14).
- **Tests (+12):**
  - `design_tokens_v2_test.dart`: valores de movimiento, que `easeSpring` rebasa 1, medidas de la rueda, pista por tema, celda vacía en oscuro, contraste del texto sobre la pista ≥ 4,5:1 en claro, oscuro, sesión y hero (con `_wcagRatio` y `contrastRatio`), y `motionDuration` con y sin movimiento reducido.
  - `ui_preferences_test.dart`: default, `copyWith`, persistencia de `largeText` y `applyLargeText` (sin activar, lineal y no lineal).
- **Para el lote de `EarMapWheel` (sin arreglar aquí):** el contraste de los rellenos sobre la pista no llega a 3:1 en todos los casos. Ámbar sobre la pista clara da 1,55:1, rojo sobre la pista oscura 2,95:1 y sobre hero 2,58:1. No bloquea, porque cada segmento lleva etiqueta y % (el color no es la única señal), pero conviene valorar un borde de 1 px en el relleno.
- **Incidencia:** `dart format` reformateaba archivos que no siguen su estilo. Se deshizo y solo se dejaron las líneas nuevas.
- **Verificación:** `flutter analyze`: «No issues found!». `flutter test` completo: `+535 ~1: All tests passed!` (antes 523).

## 2026-10-26 · Lote 0: preparación · Claude Code
- **Cambios sin commitear de v2:** cuando empezó el lote ya no había ninguno. El propietario los había commiteado en `feat/rediseno-v2` (`48a3441` panel «Enfoque SRS» en vivo, `6386970` docs v2.1 y `f5a48db` .gitignore). No hubo que tocar nada.
- **Rama:** `feat/rediseno-v2.1`, creada desde `feat/rediseno-v2` (`f5a48db`) con el árbol limpio.
- **Docs:**
  - `DESIGN.md`: `version` pasa a 2.1, cambia `updated` a 2026-10-26 y se añade la sección «v2.1», que remite al SPEC.
  - `PRODUCT.md`: en «Notas» se registra la decisión del 2026-10-26. Se mantiene sin XP en el Home.
- **Código:** sin cambios.
- **Verificación:** `flutter analyze`: «No issues found!». `flutter test` completo: `+523 ~1: All tests passed!`.
