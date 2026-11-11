# Progreso — mejora v2.2

Log en orden cronológico inverso. Qué cambia: `docs/design_v2_2/SPEC_mejora_v2_2.md`. Por qué: `docs/auditoria/2026-11-09_evaluacion_rediseno_v2_1.md`.

## 2026-11-11 · Prueba de E y F en producción · Claude Code
Producción en `1ebc030`, 590×640, tema oscuro, solfeo, con los datos sembrados de la prueba de A–D.

**Bien:**
- Hero: «Próxima sesión: Si, Re y Do.» en solfeo y «64 % en curso» en minúscula.
- El anillo de foco aparece con Tab: lila, separado del botón «Practicar más» y visible sobre el hero.
- Velocidad: un solo título («Velocidad»). Botón de volver en «Listo» y en «Fin de sesión», y vuelve a la selección.
- Sesión: «Estoy listo» y «Continuar» de la pausa en el ámbar nuevo, que se lee bien sobre el fondo oscuro.
- El piano se anuncia «Do sostenido», «Re sostenido»…
- El resultado se anuncia «Incorrecto. Era Si, respondiste Do sostenido. La tecla correcta queda marcada en verde.»
- Progreso: pestañas «Resumen | Historial» más altas y selector «Rueda | Rejilla» nuevo.

**Hallazgo nuevo, corregido:** el resultado de Velocidad decía «Las notas eran: B» con la app en solfeo, porque ignoraba la notación.
- Ahora «Incorrecto» y «Tiempo agotado» usan `formatNoteLabel` con la notación del usuario, y los chips de notas elegidas también.
- Test nuevo en `speed_screens_test.dart`.

**No visto:**
- La fase de respuesta de Velocidad: cada acción del navegador tarda unos 25 s y el límite es de 10 s.
- El paywall a 620 px y el Home en dos columnas: el panel mide 590 px de ancho.
- El tema claro.

## 2026-11-11 · Lote F: accesibilidad pendiente · Claude Code
**Prueba del lote E en producción:** no hecha. Con la ventana de Claude oculta el navegador no dibuja y Flutter no arranca; la descarga del bundle salió cortada. El despliegue de `e298d53` terminó bien (CI y Deploy Web en verde).

**Punto de partida:** con `A11Y_RUN_KNOWN=true` fallaban 34 barreras conocidas de `test/qa/a11y_*`.

- **Anillo de foco global** (`widgets/focus_ring_layer.dart`, montado en `MaterialApp.builder`): 3 px a 2 px del control enfocado, solo con foco de teclado. Sigue al foco primario, así que cubre botones, teclas, tiles, chips, pestañas, la rueda y los interruptores sin tocar cada estilo.
  - Color: `primary` en claro y #DA9CFF en oscuro y en la sesión, según el tema del control enfocado.
  - Las zonas con fondo propio lo fijan con `FocusRingColor`: el hero del Home usa #DA9CFF (8,5:1 sobre el morado).
  - Quitadas las 12 barreras de foco visible.
- **Notas habladas:** `spokenNoteName` pasa a `constants/note_naming.dart`.
  - Las teclas del piano se anuncian «C sostenido» o «Do sostenido», según la notación, en lugar de «C#».
  - El resultado de la ronda anuncia la nota: «Correcto, Do sostenido. Bien identificada…» e «Incorrecto. Era C sostenido, respondiste D…». El texto visible no cambia.
- **Objetivos táctiles:** las pestañas «Resumen | Historial» y `TogescSegmented` pasan a 48 px de alto.
- **Tarjetas pulsables:** `TogescCard` con `onTap` es ahora un solo nodo con nombre y acción (`MergeSemantics`). Antes había un tap sin etiqueta en «Ajustes de práctica» y «Acerca de».
- **Desbordes con texto escalado a 360 dp**, en Home, Velocidad, Progreso, Onboarding y Juego:
  - Celda de la semana con alto mínimo en lugar de fijo.
  - La insignia Pro de la tile encoge con texto grande.
  - «Ver progreso» y la leyenda del mapa se ajustan al ancho.
  - Pestañas flexibles.
  - Fila «Repetir / Saltar» flexible.
  - Logo del onboarding flexible.
  - Vista «Listo» de Velocidad con scroll.
  - Cifra del temporizador ajustada al anillo.
  - Insignia y CTA del selector de Velocidad ajustados.
  - Quitadas las 13 barreras de texto escalado.
- **Movimiento:** `TogescCta` apaga su fundido de estado con movimiento reducido.
- **Navegación (punto 5):** ya estaba cubierta. El rail se llama «Navegación principal» con destinos seleccionables, las pestañas tienen rol `tabBar` y las tarjetas de dificultad son un grupo excluyente con estado.
- **Tests:**
  - 35 tests de `test/qa/a11y_*` salen del skip.
  - Nuevo test de los anuncios en `test/unit/session_v2_test.dart`.
  - El test de semántica del piano busca las teclas por su nombre hablado.
  - El test del paywall de escritorio se actualizó en el lote E.

**Verificación:** `flutter analyze` sin avisos y `flutter test` +952 ~10 (antes +916 ~45: 35 tests de `test/qa/a11y_*` salen del skip y pasan).
- Al cambiar el nombre hablado de las teclas se actualizaron `piano_keyboard_test.dart` y el helper `keySemantics` de `game_screen_test.dart`.

**Sin hacer en este lote:**
- Quedan 2 barreras conocidas:
  - Teclas blancas del piano de sesión de 44 px de ancho a 360 dp. Pasa WCAG 2.5.8 AA; llegar a 48 pide quitar casi todo el margen lateral.
  - Con «Reducir animaciones» de la app, el juego encadena 700 ms de animación tras responder. Con el ajuste del sistema no pasa. Falta localizar qué widget no lee la preferencia.
- Punto 6: los estados vacíos sin acción y los errores silenciosos no se han revisado.
- Velocidad no anuncia la nota en su resultado.
- No se ha probado con TalkBack ni VoiceOver.
- No se ha visto en la app real.

## 2026-11-11 · Lote E: coherencia visual · Claude Code
**Antes del lote: prueba de A–D en la app real** (producción, 751×640, datos sembrados en localStorage):
- Bien: copy del onboarding (A); «midiendo» y «a reforzar», Re al 40 % con 5 intentos en rojo (B); «Primera medición hecha», «Próxima sesión: …», hero «SESIÓN DE HOY HECHA» con «Practicar más», pasos ocultos tras la primera sesión y tira de días bajo el hero (C); píldoras «La, consolidada» y «Tu mejor sesión hasta hoy», «11/12 consolidadas», «🔥 4 Récord» y «Tus hitos» (D).
- Corregido en este lote:
  - El hero ignoraba la notación (salía «C#» con solfeo): ahora usa `formatNoteLabel`.
  - El estado de la mini-card iba con mayúscula tras la cifra («64 % En curso»).
  - El chip de racha del Home contaba un día de más antes de practicar hoy.
  - «15s» pasa a «15 s».
- Visto y sin corregir:
  - El nivel SRS de una nota baja a 0 mientras sigue «consolidada»; confunde.
  - El hero dice «notas naturales» y sonó un Do#.
  - A 640 px de alto, «Probar otra vez» del onboarding queda bajo el pliegue (se llega con scroll).
  - «33,3 %» en Progreso frente a «33 %» en el Home.
  - «12 rondas · 1 nota · foco en…» se lee ambiguo.
  - No se vieron el pop de la rueda ni el chip ⚡.

**Lote E:**
- **`TogescCta`** (`widgets/togesc_ui.dart`): ámbar #FFB300, 17/800, `ctaHeight` (o 48 en filas de acciones) y la sombra del prototipo (`DesignTokens.ctaShadow`). Lo usan «Empezar sesión» del hero, «Estoy listo», «Reanudar», «Confirmar», «Ver resumen», «Siguiente ronda», «Continuar» de la pausa, «Volver al inicio», «Entendido, empezar» y el CTA del paywall. Mantienen sus `ValueKey`.
  - La sesión pasa del ámbar claro (`sessionAmber`) al del Home; `sessionAmber` queda para iconos y chips.
  - «Practicar más» (sesión hecha) sigue translúcido a propósito.
- **`TogescSegmented`**: sustituye los 9 `SegmentedButton` (notación del onboarding, periodo de Estadísticas, Entrar/Crear cuenta, duración de «Ajustar», Rueda/Rejilla, timbre, duración del cluster y del tono, tema). Valor único en lugar de `Set`; anuncia «seleccionado» y grupo excluyente.
- **Anchos:** breakpoints únicos 600 y 840 en `DesignTokens`; `desktopBreakpoint` es ahora 840 (antes 1024), así que el rail, el Home en dos columnas y el layout de escritorio de la sesión empiezan en 840. Entre 600 y 840 el Home se limita a 640. Onboarding, «Preparado» y paywall a 620; onboarding y paywall se centran en vertical cuando caben.
  - El paywall pierde su versión en dos columnas (≥ 900): con 620 px va siempre apilado.
- **Velocidad:**
  - Botón de volver (`speed-back`) en todas las fases de la ráfaga; antes no había, porque se entra con `pushReplacement`.
  - Un solo título: la app bar dice «Velocidad» y la cabecera «Modo velocidad» desaparece.
  - En la respuesta, temporizador, botón y campo se limitan al ancho del piano (500, o 640 con piano grande).
- **Paywall:** el panel ya estaba en `surfaceContainerLowest`.
- **Tests:** 4 nuevos en `home_screen_test.dart` (columnas del Home a 360, 768, 840 y 1280). Actualizados el test QA de notación (`TogescSegmented`), el smoke e2e («Velocidad»), el del paywall en escritorio y los nombres de los tests de 1024 → 840.

**Verificación:** `flutter analyze` sin avisos y `flutter test` +916 ~45.
- La primera pasada dio 22 fallos: `TogescSegmented` desbordaba con texto grande en Ajustes y el onboarding (las opciones no encogían). Ahora cada opción va en `Flexible` y la etiqueta se reduce con el `FittedBox`.
- El test del paywall «lado a lado» pasa a comprobar la columna de 620 centrada.

**Sin hacer en este lote:**
- Escala de escritorio del prototipo (hero 52/32, arte 220, centro de rueda 34), fila de KPI destacada y limpieza de tokens (punto 8).
- Movimiento: `CountUpText` en el Home (el valor central de la rueda es texto, pide cambiar la API de `EarMapWheel`), entradas escalonadas y pop del resultado.
- Capturas en `docs/evidence/`: no hechas; hace falta un build web local o el despliegue de la rama.
- D4 (envío al tocar en Velocidad) sigue sin decidir.
- No se ha visto en la app real.

## 2026-11-11 · Lote D: hitos reales · Claude Code
- **Función pura** `utils/milestones.dart`: `sessionMilestones` recibe el estado de las notas al empezar y al acabar, y los récords anteriores; devuelve los hitos de la sesión.
  - **Nota consolidada:** la que pasa a «Consolidada» en esta sesión (con el mínimo de 5 intentos del lote B). Sin estado inicial no se declara ninguna.
  - **Octava completa:** al consolidarse la duodécima; no se repite si ya lo estaba.
  - **Mejor sesión:** precisión por encima de la mejor anterior del mismo modo, con ≥ 3 sesiones previas. Igualarla no cuenta.
  - **Racha récord:** desde 2 días y por encima de la mejor racha anterior.
- **Guardado** (`app_preferences.dart`): mejor precisión por modo, mejor racha de días y la lista de hitos con fecha (máximo 100). Los récords se guardan aparte porque el historial se corta en 50 sesiones (F9); para usuarios con historial previo se toma el mayor entre lo guardado y lo que da el historial. Lo actualiza `SessionHistoryNotifier.record`, que es donde ya se registra cada sesión.
- **Resumen:** píldoras «Do, consolidada», «Tu mejor sesión hasta hoy» y «Octava completa» (`session-summary-milestones`), también en la etiqueta semántica. El segmento de cada nota consolidada hace un pop en la rueda tras la entrada (sin animación con movimiento reducido). Si cambia el número de consolidadas, la rueda muestra «N/12 consolidadas».
- **Home:** el chip de racha añade «Récord» el día en que se bate.
- **Sesión:** el chip ⚡ aparece desde 2 seguidas, con tooltip y etiqueta «N seguidas».
- **Perfil:** bloque «Tus hitos» con cada hito y su fecha, del más reciente al más antiguo. Sin hitos no aparece (D10).
- **Tests:** `test/unit/milestones_test.dart` (10: cada hito, el caso sin hitos, la racha más larga, JSON) y `test/widget/milestones_ui_test.dart` (7: resumen con y sin hitos, chip ⚡, «Récord», «Tus hitos» y el guardado de récords en `record()`).

**Verificación:** `flutter analyze` sin avisos y `flutter test` +912 ~45.

**Sin hacer en este lote:**
- No se ha visto en la app real: el pop de la rueda y las píldoras hay que mirarlos en una sesión de verdad.
- El pop de la rueda no tiene test propio.
- La sesión de Velocidad no calcula hitos de notas ni de mejor sesión; sí cuenta para la racha récord.
- Los hitos se guardan en el dispositivo y no se sincronizan con Supabase.

## 2026-11-10 · Lote C: primera sesión y bucle diario · Claude Code
- **Resumen de la sesión** (`session_summary_view.dart`, funciones puras en `utils/session_summary.dart`):
  - Las tres primeras sesiones titulan «Primera/Segunda/Tercera medición hecha», con el icono de oído, sin valorar la precisión. Desde la cuarta vuelve la medalla.
  - Línea de recapitulación (`session-summary-recap`), solo con datos reales (D10): «5 puntos más que la última vez.» (frente a la sesión anterior del mismo modo), «Tu mejor racha: N seguidas.» (desde 3) y «Próxima sesión: Fa, La# y Si.». El mismo texto va en la etiqueta semántica del resumen.
- **Hero del Home con la sesión de hoy hecha** (`today_session_hero.dart`): icono de check en lugar del punto vivo, «SESIÓN DE HOY HECHA», «78 % de precisión en tu última sesión» y «Hecho por hoy. Próxima sesión: …». El CTA mantiene `today-start-cta`, pasa a «Practicar más» y pierde el ámbar, para que no parezca una tarea pendiente.
- **Pasos «1 · Escucha…»** solo hasta completar la primera sesión.
- **Móvil:** la tira de días sube bajo el hero; el mapa del oído cierra la página. Escritorio no cambia.
- **Resto de «latencia»** en el estado vacío de Progreso: «tu tiempo de respuesta».
- **Tests:** `test/unit/session_recap_test.dart` (8) y `test/widget/today_hero_done_test.dart` (3) nuevos; `game_screen_test.dart` actualizado al titular de primera medición.

**Verificación:** `flutter analyze` sin avisos y `flutter test` +895 ~45.

**Sin hacer en este lote:**
- No se ha visto en la app real (hero hecho en claro y oscuro, recap a 360 px).
- La sesión se registra al salir del juego, así que el número de sesión se calcula como historial + 1; si el registro cambia de momento, hay que revisarlo.
- «Próxima sesión» usa el foco recalculado en ese instante, no una predicción de mañana; por eso no dice «mañana».

## 2026-11-10 · Lote B: estados honestos del dominio · Claude Code
**Decisión aplicada:** D3 = 5 intentos mínimos antes de juzgar una nota (`masteryMinAttempts` en `constants/srs_constants.dart`).

- **Un solo estado por nota.** `MasteryStatus` y `masteryStatusOf` (`widgets/progress_v2/progress_metrics.dart`) son el único sitio donde se decide. Estados: sin datos, midiendo, a reforzar, en curso y consolidada.
  - Lo usan la rueda, la rejilla, el Mapa del oído del Home, las mini-cards del hero, la hoja de detalle, la hoja «Ajustar enfoque», el panel de la sesión y las filas del resumen.
  - «Crítica» desaparece de la interfaz: ahora es «A reforzar». «Dominada» pasa a «consolidada» también en los textos para lector de pantalla.
- **«Midiendo».** Con 1 a 4 intentos la nota no lleva rojo ni porcentaje: muestra «2/5» y un color neutro (`masteryMeasuringColor`, el primario atenuado sobre la superficie apagada).
  - En el hero del Home, la barra de la mini-card se llena con los intentos hechos.
  - En el resumen, la fila de una nota que aún se mide ya no sale en rojo con una flecha verde.
- **Rueda:**
  - Relleno mínimo del 18 % (antes 6 %), para que una nota al 0 % se lea.
  - Contorno de 1 px en `outlineVariant` en cada segmento, para separarla de la tarjeta en claro.
  - Las notas en «Midiendo» se rellenan en neutro según los intentos hechos.
- **Progreso:**
  - Con cero intentos solo se ve el estado vacío con su botón; el bloque «Dominio por nota» aparece con el primer intento.
  - El subtítulo cuenta los estados que tienen notas: «1 consolidada · 2 en curso · 3 midiendo · 6 sin datos» (`masterySubtitle`).
  - La leyenda de la rejilla añade «Midiendo».
- **Cierra el punto 9 del QA del front:** «Consolidadas» se contaba de dos formas en la misma card (precisión ≥ 75 % en el centro y notas graduadas por el SRS en el subtítulo). Ahora las dos salen del mismo estado. `MasteryOverview` y `NoteMasteryGrid` pierden los parámetros `consolidatedCount` e `inProgressCount`, y el test de QA correspondiente deja de estar en skip.
- **Tests:** `test/unit/mastery_status_test.dart` nuevo (9 tests): límites de 0, 1, 4 y 5 intentos y de 49,9, 50, 74,9 y 75 %, y el subtítulo. Actualizados 9 ficheros de test.
  - El test de contraste del tema oscuro siembra una nota practicada, porque la rejilla ya no aparece sin datos.
  - El control de movimiento reducido usa el onboarding en lugar de Progreso, por el mismo motivo.

**Verificación:** `flutter analyze` sin avisos y `flutter test` +884 ~45.

**Sin hacer en este lote:**
- No se ha visto en la app real: el color neutro y el contorno de la rueda hay que mirarlos en claro y en oscuro.
- «Tus extremos» (Pro) sigue ordenando por precisión sin exigir los 5 intentos.
- El panel de la sesión mantiene «A reforzar» para las notas muy atrasadas aunque tengan pocos intentos: ahí el criterio es el retraso, no la precisión.

## 2026-11-10 · Lote A: lenguaje y números · Claude Code
**Decisiones aplicadas** (las recomendadas en el SPEC; el propietario aprobó el plan sin cambiarlas): D1 «repaso inteligente», D2 «Consolidada», D5 «Medio».

- **Formateador único** (`lib/utils/number_format.dart`): `formatDecimalEs`, `formatPercentEs`, `formatSecondsEs` y `plural`.
  - Sustituye a tres funciones sueltas (`formatPercentEs` de `ear_map_card`, `formatSecondsEs` de `session_summary` y `formatSpeedSeconds`) y a los 18 `toStringAsFixed` de pantallas y widgets.
  - Quedan dos `toStringAsFixed` en `progress_export_service.dart`: son datos del fichero exportado, no texto de interfaz.
  - Todos los porcentajes llevan espacio antes de «%».
- **Glosario** (tabla en `DESIGN.md`, «Lenguaje y números»):
  - «SRS» sale de los 44 textos donde aparecía. Sigue en identificadores y comentarios.
  - «Latencia» pasa a «Tiempo de respuesta» («Respuesta» en las etiquetas estrechas).
  - «Limpieza tonal» y «Neutralidad tonal» pasan a «Borrado de referencia».
  - En Velocidad, «Racha» pasa a «Seguidas», «Mejor racha» a «Récord» y la dificultad «Pro» a «Medio».
  - «Dominada» pasa a «Consolidada». «37% de la meta (90%)» pasa a «Meta: 90 %».
- **Onboarding:**
  - El paso 1 abre con «Reconoce notas sin referencia» y «Unos 6 minutos al día…».
  - Las tres tarjetas del paso 2 se llaman «Repaso inteligente», «Distintos instrumentos» y «Borrado de referencia», cada una con una frase de beneficio.
- **Plurales y tildes:** «1 ronda», «1 intento», «1 sesión», «1 nota escuchada», «1/1 nota seleccionada»; «Violín», «Órgano», «más», «mayoría», «máximo», «Precisión» y «básicos».
- **Sin pagos activos:** la tarjeta de plan del Perfil dice «Acceso completo» y «Ver TOGESC Pro». «Suscribirme (Stripe)» y «Gestionar pago (Stripe)» pierden el paréntesis.
  - **Cambio frente al SPEC:** la tarjeta no se oculta. Su `ValueKey` `account-pro-entry` la usan cuatro tests e2e y es la entrada permanente a Pro (D8). El SPEC queda corregido.
  - El botón sigue llevando a la pantalla de suscripción, como comprueban los tests de D8. Esa pantalla no se ha revisado para el caso sin pagos.
- **Dos desbordes que introdujeron las etiquetas nuevas, corregidos:**
  - «Peso de repaso» en `note_srs_detail_card.dart`: la etiqueta va ahora en `Expanded`.
  - «Seguidas» en la barra de métricas de Velocidad (`togesc_ui.dart`): cada métrica encoge con `FittedBox`.
- **Tests:** `test/unit/number_format_test.dart` nuevo (4 tests). Actualizados los textos esperados en 13 ficheros de test; dos finders se acotaron a su widget porque «40 %» y «70 %» salen ahora con el mismo formato en dos sitios.

**Sin hacer en este lote:**
- No se ha visto en la app real. A 360 px hay que comprobar que «Respuesta · tiempo medio aprox.» y «Borrado de referencia» no cortan.
- «Crítica» sigue como etiqueta: se cambia en el lote B.
- Los textos legales de `privacy_policy_screen.dart` se tocaron solo para quitar «SRS».

**Verificación:** `flutter analyze` sin avisos y `flutter test` +874 ~46.
