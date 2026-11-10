# Rediseño v2: análisis de brechas

Fecha: 2026-10-09 · Autor: arquitecto UX (análisis de solo lectura; no se tocó código ni se compiló).
Fuentes: `docs/design_v2/SPEC_rediseno_v2.md`, `docs/design_v2/github.md`, `DESIGN.md`, `.agents/skills/design/design-ux-architect.md`, `.agents/skills/impeccable/SKILL.md`.
Regla: si v2 choca con `DESIGN.md`, gana v2. Rutas relativas a `TOGESC/togesc/`.

---

## 0. Decisiones previas (bloquean la implementación)

Hay que cerrarlas antes del lote 1. Cada una es una contradicción entre v2 y el comportamiento actual.

| # | Tema | Conflicto | Propuesta |
|---|---|---|---|
| D1 | Confirmar respuesta | v2 pide «un toque, sin confirmar». Hoy `confirmBeforeSubmit` vale `true` por defecto (`models/ui_preferences.dart:99`) y existe el botón «Confirmar» (`screens/game_screen.dart:450-470`). | Quitar el botón y el ajuste. En intervalo y acorde se envía al completar N teclas, con la lógica que ya existe en `_maybeAutoSubmit` (`game_screen.dart:116`). |
| D2 | Avance automático | v2: `result` dura 2,2 s y pasa sola a la siguiente ronda. Hoy `autoAdvanceAfterResult=false` (`models/practice_session_preferences.dart:29`) y el retardo es de 1800/400 ms (`game_screen.dart:49`). | Avance automático siempre; 2200 ms, o 400 ms con movimiento reducido. Eliminar el ajuste. |
| D3 | Sesión de 12 rondas | `SessionRoundGoal` solo admite 0/5/10/20 (`practice_session_preferences.dart:2-6`) y por defecto es «Sin límite». | Añadir 12 y hacerlo el valor por defecto de la «Sesión de hoy». Los minutos estimados («6 min») no se pueden medir porque no se registra duración: usar `rondas × 30 s` como constante declarada o quitar los minutos. |
| D4 | Fase `idle` | v2 entra directamente en `listen`. Hoy hay una vista idle con «Reproducir» (`widgets/game_session_views.dart:348`). En web el audio necesita un gesto del usuario. | Arrancar en `listen` cuando se llega desde un CTA, que ya captura el gesto con `captureUserGesture`. Mantener un idle mínimo («Toca para empezar») para enlace directo o recarga en web. |
| D5 | Cluster de limpieza | v2 no lo dibuja (`GameState.playingCluster`). | Mantenerlo como subfase dentro del anillo, con la overline «Limpiando», y sin vista propia. |
| D6 | Entrada por texto o micrófono | v2 solo muestra el piano. Hoy `inputMode=both` por defecto (`ui_preferences.dart:98`) muestra un TextField. | Por defecto `pianoOnly`. Texto y micrófono siguen como modos opcionales, debajo del teclado. |
| D7 | Rejilla de 12 notas para Free | Hoy la precisión por nota solo la ve Pro (`screens/statistics_screen.dart:64,157`). v2 la muestra a todos. | Decisión de producto. Recomiendo rejilla para todos y dejar Pro para exportar, el historial completo y la evolución. |
| D8 | Nav: «Velocidad» sustituye a «Pro» | Hoy: Práctica / Estadísticas / Pro / Perfil (`widgets/togesc_shell.dart:37-58`). Velocidad es Pro (`router.dart:75`). | Pro sale de la nav y se llega a él por los tiles con PRO y por Perfil. Si el usuario no es Pro, la pestaña Velocidad muestra el paywall, como hoy con `ProRouteGuard`. |
| D9 | Iconos Material Symbols | No está la dependencia `material_symbols_icons` (pubspec). | Usar `Icons.*_rounded` (equivale a FILL 1) e `Icons.*_outlined` (FILL 0). No añadir paquete; `graphic_eq` y `hearing` existen. |
| D10 | Copy del hero | «perdieron precisión esta semana» no se puede calcular: no hay historial de precisión por nota en el tiempo. | Copy veraz derivado del SRS, por ejemplo «El SRS priorizó tres notas atrasadas o con menor precisión.» |
| D11 | Foco de 3 notas | `practiceFocusNoteProvider` guarda una sola nota (`providers/practice_focus_provider.dart:4`) y con ella el pool queda en `[nota]` (`utils/note_pool.dart:11`). Un pool de 3 notas es fácil de adivinar. | Lista de foco más el resto del pool configurado con peso SRS, o bien solo las 3 notas. Lo decide pedagogía. |

---

## 1. Tokens y tema

**Qué existe**
- `lib/app/design_tokens.dart:4-106`: paleta Harmonic Precision, radios 12/16, motion y `speed*`.
- `lib/app/togesc_colors.dart:10-75`: extensión con `correct/incorrect/selection(+Deep, Container)` en claro y oscuro.
- `lib/app/app_theme.dart:11` (`light`), `:170` (`dark`), `:327` (NavigationBar con 80 de alto) y `:353` (TextTheme con Hanken Grotesk).
- Tema global por preferencia: `AppThemePreference` (`models/ui_preferences.dart:23`). No existe un tema forzado para la sesión.

**Qué falta o cambia**
- Tokens nuevos: `hero #2A0640`, `ctaAmber #FFB300` con texto `#2A0640`, `phaseAmber #FFD54F`, escala de éxito `#3B8C3F/#4E9A52`, aviso `#FFC94D` con texto `#3A2B00` y `#FFC46B`, barra crítica `#FF8A8A`, `navBar #FFFDFE`, divisor `#EEE6EB`.
- Tokens oscuros de sesión: chip `#241B2A` (hoy `darkSurfaceContainer` vale `#281F2C`), borde `#3A2E42`, texto secundario `#9C8FA3` y etiquetas `#CFC3CD` (hoy `darkOnSurfaceVariant` vale `#CFC3CD`; el texto secundario es nuevo).
- Gradientes de piano, como tokens en `TogescColors`, que hoy no tiene ninguno de los seis:
  - Teclas por defecto: blanca `#FAF6F8→#E4DBE6`, negra `#2A2230→#17121B`.
  - Correcta: blanca `#A5D6A7→#6FBF73`, negra `#3BA34A→#1B5E20`.
  - Errónea: blanca `#F2B4B4→#E08A8A`, negra `#C0504F→#7A1010`.
- Radios: `radiusHero 20`, `radiusCard 14`, `radiusCell 12` (se mantiene), `radiusCta 15` y `radiusPill 999`. `DESIGN.md` fija 12 como radio canónico; v2 manda.
- Tipografía: estilos `overline` (12–13/700, mayúsculas, letter-spacing 1.4–1.6), `logo` (15/800, ls 2.4) y `bigNumber` (44–52/800, ls negativo, `FontFeature.tabularFigures()`). Hoy no se usa `tabularFigures` en ningún sitio.
- Nuevo `AppTheme.session`, oscuro y fijo, aplicado con `Theme(data: …)` en la ruta de sesión sea cual sea la preferencia del usuario. La NavigationBar pasa a 76 de alto y el estado activo se pinta en `#4E0078`, relleno y en negrita (hoy usa `primaryContainer`).
- `DESIGN.md`: reescribir la portada YAML y las secciones Shapes, Components y Do/Don't según v2.

**Tests afectados:** `test/unit/app_theme_test.dart`. Solo se rompe si cambian `radiusMd`, `correct`, `incorrect`, `selection` o `background`; v2 los conserva.

---

## 2. Pantalla 1a: Home

**Qué existe**
- `lib/screens/home_screen.dart:22-232`:
  - Título «TOGESC» y «Entrenador de oído absoluto» (`:140-156`), duplicado con el header del shell.
  - `PracticeStreakLabel` (`:157`), `DailyFocusSection` (`:159`), `ContinuePracticeCard` (`:161`) y la sección «Modos de entrenamiento» con «Ver todos (N)» y `ModeBentoGrid` de 6 modos (`:176-225`).
- `lib/widgets/daily_focus_section.dart`: `DailyFocusSection` (`:17`) con fecha dd/mm/aaaa (`:31`), `_CriticalNotesCard` que muestra 2 notas (`:147`), «Practicar ahora» (`:214`) y `PracticeStreakLabel` (`:99`).
- `lib/widgets/continue_practice_card.dart`: `ContinuePracticeCard` (`:14`), `canOpenLastPracticeSession` (`:76`) y `openLastPracticeSession` (`:93`). Las dos funciones se reutilizan.
- `lib/widgets/mode_bento_card.dart`: `ModeBentoCard` (`:10`), `_MasteryBadge` (`:198`) y `ModeBentoGrid` (`:256`).
- `lib/widgets/home_hub_views.dart`: `HomeSectionHeader` (`:7`) y `HomeModeOptionCard` (`:62`, código muerto). `lib/widgets/recommendation_card.dart` también está muerto, sin usos.
- Header del shell: `_TogescShellHeader` (`widgets/togesc_shell.dart:152`) con el título, un icono Pro y el avatar.

**Qué falta o cambia**
- Crear:
  - `widgets/home/today_session_hero.dart`: card #2A0640, marca de agua `graphic_eq` de 150 px, overline, «12 rondas · N min», copy (D10), 3 mini-cards de nota con barra de 3 px y %, CTA ámbar de 58 «Empezar sesión» y el enlace «Ajustar enfoque y duración», que lleva a `/settings`.
  - `widgets/home/resume_row.dart`: fila con borde discontinuo, «Retomar «{modo}»», «N rondas · hace X» y chevron.
  - `widgets/home/free_practice_tiles.dart`: 3 tiles con barra de progreso y «86% · 24 ses.». «Ver todos» abre la lista completa, en un sheet o una ruta, con aleatorio y sostenidos.
  - `widgets/home/week_strip.dart`: 7 celdas L–D de 44 de alto.
  - `widgets/home/home_date_overline.dart`: «Jueves 10 de septiembre». `intl` está en pubspec, pero `DateFormat` no se usa ni se inicializa el locale; conviene un mapeo manual como `weekdayShortLabel` (`utils/session_history_stats.dart:59`).
- Modificar:
  - `home_screen.dart`: reescribirla con 4 bloques y quitar el título duplicado.
  - `togesc_shell.dart`: app bar de 56 con logo 15/800, chip de racha y avatar; sin icono Pro.
- Borrar: `daily_focus_section.dart`, `continue_practice_card.dart` (mover las dos funciones `*LastPracticeSession` a `utils/last_practice_navigation.dart`), `home_hub_views.dart` (o dejar solo `HomeSectionHeader`), `recommendation_card.dart` y `mode_bento_card.dart`, si los tiles lo sustituyen.

**Datos**

| Dato v2 | Estado | Fuente o derivación |
|---|---|---|
| Notas foco con % | Existe a medias | `practiceRecommendationsProvider` (`providers/srs_provider.dart:241`) → `recommended_notes` (máx. 5, atrasadas o en aprendizaje) y `critical_notes` (≥3 días de atraso, `services/srs_system.dart:310-323`). El % sale de `noteProgressSummariesProvider` (`srs_provider.dart:251`) `.accuracyPercent`. **Derivar:** `todayFocusNotesProvider` con las 3 primeras (críticas, luego atrasadas, luego menor precisión) y un fallback cuando aún no hay datos. |
| Número de rondas y minutos | No existe | D3. |
| Retomar: modo y hora | Existe | `lastPracticeSessionProvider` (`providers/last_practice_provider.dart:7`). Ojo: `practicedAt` se graba al **entrar** (`game_session_provider.dart:119`), no al terminar. |
| Retomar: «8 rondas» | Derivable | La última entrada de `sessionHistoryProvider` (`providers/session_history_provider.dart:8`) con el mismo `modeId` y `kind`, campo `roundsCompleted`. |
| «hace 2 h» | No existe | Crear un formateador de tiempo relativo en `utils/relative_time.dart`. |
| Tiles: «86% · 24 ses.» | Existe | `engagementStatsProvider.masteryFor(mode)` (`models/engagement_stats.dart:47`): `accuracyPercent` y `sessionsCount`. |
| Racha (chip) | Existe | `EngagementStats.currentStreakDays` (`services/engagement_stats_service.dart:11`). |
| Semana L–D con estado | Derivable a medias | `buildDailyPracticeSummaries` (`utils/session_history_stats.dart:24`) usa los **últimos 7 días móviles**, no la semana natural L–D. **Crear** `buildCalendarWeek(history, now, dailyGoal)`. El verde, el ámbar y el rojo necesitan una **meta diaria**, que hoy no existe. Propuesta: cumplido si las rondas del día ≥ la meta de la sesión de hoy (12); parcial si hay entre 1 y 11; fallado si es un día pasado sin práctica; sin práctica si es hoy sin rondas o un día futuro. Texto «5 de 7 días» = días con práctica. |
| PRO y candado en tiles | Existe | `SubscriptionAccess.canPlayMode` (`home_screen.dart:79`). |

---

## 3. Pantalla 1b: sesión móvil oscura

**Qué existe**
- `lib/screens/game_screen.dart` (653 líneas): `TogescScaffold` claro con el título del modo (`:249`), `GameSessionProgressBar` con «Ronda N de M» (`:279`) y un `AnimatedSwitcher` por estado (`:289`).
  - Respuesta: cabecera, chips de selección, micrófono, texto, piano, «Repetir» y «Confirmar» (`:350-514`).
  - **Resultado:** `ResultCard` más un **segundo `PianoKeyboard`** deshabilitado bajo «Visualización de respuesta» (`:516-599`), y el botón «Siguiente ronda» o «Volver al inicio» (`:601-652`).
- `lib/widgets/result_card.dart` (411 líneas): `ResultCard` (`:10`), `_MetricTile`, `_SrsNoteRow` y `_LearningPills`.
- `lib/widgets/game_session_views.dart`:
  - `GameSessionPhaseLayout` (`:11`), que también usan `speed_session_views.dart` y `account_monetization_views.dart` (**no romper**).
  - `GameSessionProgressBar` (`:160`) y `GameSessionRoundControls` (`:202`, muerto).
  - `GameSessionRoundAppBarActions` (`:251`), `GameSessionPausedOverlay` (`:289`), `GameSessionGoalCompleteBanner` (`:310`) y las vistas `Idle`, `Listening` y `Cluster` (`:348-411`).
  - `GameSessionAnswerHeader` (`:437`), `GameSelectionChips` (`:480`) y `GameInstrumentToggleAction` (`:570`).
- `lib/widgets/piano_keyboard.dart` (418 líneas): 7 blancas en un Row y 5 negras con zona táctil de 48 (`:259`) y ancho visual `0.6·w` (`:257`).
  - Feedback por alfa del color (`:53-127`) y badges ✓/✗ (`:150-172`).
  - Semantics con etiqueta y hint (`:210-215`).
  - También lo usa `screens/speed_game_screen.dart:239`, así que **la API tiene que seguir siendo compatible**.
- `lib/providers/game_session_provider.dart`: `GameState` (`:19`) y `RoundResult` (`:22`), **sin las notas respondidas**.
  - **Bug latente:** `game_screen.dart:145` vacía `_selectedNotes` al enviar, así que `incorrectSet` (`:521`) siempre queda vacío y la tecla errónea nunca se pinta.

**Qué falta o cambia**
- Borrar `widgets/result_card.dart`, `_buildResultView`, `_buildResultActions`, `GameSessionResultSectionLabel` y `GameSessionRoundControls` (muerto). El piano de resultado desaparece: un solo `PianoKeyboard` persiste entre `answer` y `result`.
- Crear en `widgets/session/`:
  - `session_top_bar.dart`: volver, chips «r / 12», «✓ %» y «⚡ racha», pausa y la barra de 3 px `#DA9CFF`.
  - `session_phase_ring.dart`: anillo de 150 (170 en escritorio), overline de fase coloreada, 5 barras animadas, icono `hearing` o la nota grande, titular y subtítulo. Debe respetar `reduceAnimations` y `MediaQuery.disableAnimations`.
  - `srs_level_pill.dart`: «{nota} SRS 3/5 → 4/5» con 5 puntos.
  - `session_key_actions.dart`: «↻ Repetir», «Toca la tecla que escuchaste» y «Saltar ⏭».
- Modificar:
  - `piano_keyboard.dart`: añadir `variant: light|session|sessionWide` (230 de alto, contenedor `#1A121E` con radio 16, negras de 38×140 o 52×126), gradientes de v2, `dimOthers` para atenuar las teclas sin feedback y `revealCorrect`. Mantener los parámetros actuales.
  - `game_screen.dart`: reescribir el árbol con `Theme(AppTheme.session)`, fases `listen/answer/result` y el temporizador de 2,2 s. Quitar el AnimatedSwitcher de vistas completas: solo cambia el anillo.
- `GameSessionGoalCompleteBanner`: v2 no define el fin de sesión. Recomiendo una hoja de cierre breve (pendiente de diseño).

**Datos**

| Dato v2 | Estado | Derivación |
|---|---|---|
| Ronda r / 12 | Existe | `roundsCompleted`; meta según D3. |
| Precisión % | Derivable | `correctRounds / roundsCompleted` (`GameSessionState`, `:46-47`). |
| ⚡ racha de sesión | **No existe** | Añadir `currentStreak` a `GameSessionState`: sube con cada acierto y vuelve a 0 con un fallo. |
| «Era X, respondiste Y» | **No existe** | Añadir `answerNotes` a `RoundResult` (`game_session_provider.dart:22`) y dejar de depender de `_selectedNotes`. |
| SRS 3/5 → 4/5 | Derivable | `srsChanges[note].old/new` ya trae `consecutive_correct`, `interval_index` e `is_learning` (`srs_system.dart:169-232`). **Crear** `utils/srs_level.dart`, función pura `srsLevel(isLearning, consecutiveCorrect, intervalIndex, learningThreshold)` de 0 a 5. Propuesta: aprendizaje → `floor(3·cc/threshold)` acotado a 0–2; consolidada → `3 + min(intervalIndex, 2)`. El umbral sale de `SrsIntensityProfile.learningThreshold` (`models/srs_intensity_profile.dart:36`). |
| Subtítulo «Piano · octava 4 · 1 nota» | Parcial | `lastInstrument` existe. La octava no se expone: `getNoteFrequencies` la calcula con `varyOctaves`. Mostrar la octava solo si está fija, o quitarla. |

---

## 4. Pantalla 1c: Progreso

**Qué existe**
- `lib/screens/statistics_screen.dart:27-312`:
  - `StatsDashboardHeader`, `SegmentedButton` de 7/30/Todo y `StatsBentoHeader` con precisión, meta del 90 %, intentos, pendientes y «Repasar ahora» (`widgets/stats_bento_grid.dart:81`; meta fija en `:99`).
  - «Estado del dominio» con aprendizaje y dominadas, y el radar solo para Pro (`NoteAccuracyRadarChart`).
  - Upsell, `SessionEvolutionChart`, `SessionHistoryCard` (`widgets/session_history_card.dart:11`), el botón «Ver progreso por nota (12)», «Notas a reforzar» (Pro) y «Gestión de datos».
- `lib/screens/note_progress_screen.dart`: lista detallada por nota. Se mantiene como vista «Historial» o de detalle.
- No hay test de `StatisticsScreen`.

**Qué falta o cambia**
- Crear:
  - `widgets/progress/global_accuracy_header.dart`: número 52/800, delta frente a la semana pasada y barra de meta.
  - `widgets/progress/kpi_row.dart`: Latencia, Intentos y Pendientes, esta última en una card #2A0640.
  - `widgets/progress/note_mastery_grid.dart`: 4×3 con leyenda y Semantics por celda.
  - `widgets/progress/recent_sessions_list.dart`: o adaptar `SessionHistoryCard`.
- Modificar: `statistics_screen.dart` con el orden de v2. El selector de periodo, el radar, el gráfico de evolución y la gestión de datos pasan a «Historial» o Ajustes. **Renombrar** la pestaña a «Progreso».
- Borrar o reubicar: `stats_bento_grid.dart` (`StatsBentoHeader` lo sustituye `global_accuracy_header`), `_DomainStatBox`, y `note_accuracy_radar_chart.dart` si nadie más lo usa.

**Datos**

| Dato v2 | Estado | Derivación |
|---|---|---|
| Precisión global 72.4 % | Existe | `srsStatisticsProvider['accuracy_percentage']` (`srs_system.dart:381`). Es por **nota vista**, no por ronda. |
| «+4.1 pts vs. semana pasada» | **No existe** | El SRS no guarda serie temporal. Derivable del historial de sesiones (`PracticeSessionLog` con rondas, aciertos y `endedAt`): precisión por ronda de los últimos 7 días frente a los 7 anteriores. **Inconsistencia:** compara una métrica por ronda con una global por nota. Propuesta: el número grande y el delta usan la misma base (rondas del historial), o el delta dice explícitamente «precisión de rondas». |
| Meta 90 % | Constante | Mover el valor fijo de `stats_bento_grid.dart:99` a `DesignTokens` o a las preferencias. |
| Latencia media 2.8 s | Derivable con matiz | `NoteData.avgResponseTimeSec` es una **EMA por nota** (`srs_system.dart:160-166`). Global = media ponderada por `timesSeen`, ignorando notas con valor 0. Rotularla «aprox.», o guardar la latencia por sesión en `PracticeSessionLog` (cambio de esquema). |
| Intentos 1 284 | Existe | `total_seen`: son notas vistas; en acorde cuentan 3 por ronda. Usar la suma de `roundsCompleted` si debe significar «rondas». |
| Pendientes 5 | Existe | `overdue_count` (`srs_system.dart:382`). |
| «5 consolidadas · 7 en curso» | Existe | `graduated` y `learning_phase` (`srs_system.dart:375-376`). |
| % por nota y nivel de color | Existe | `NoteProgressSummary.accuracyPercent` (`models/note_progress_summary.dart:28`). Umbrales <50, 50–74 y ≥75. Los 3 verdes «según nivel» salen de `srsLevel` (3, 4 o 5). |
| Últimas sesiones | Existe | `sessionHistoryProvider` → `PracticeSessionLog.modeLabel`, `roundsCompleted`, `correctRounds`, `accuracyPercent` y `endedAt`. |

---

## 5. Pantalla 1d: sesión en escritorio y web

**Qué existe**
- La ruta `/game/:modeId` está **fuera** del `ShellRoute` (`app/router.dart:82` frente a `:111`), por lo que hoy no muestra rail en sesión.
- El shell usa un `NavigationRail` a partir de 600 px (`togesc_shell.dart:64-118`).
- Existen el botón de instrumento (`GameInstrumentToggleAction`, `game_session_views.dart:570`) y la pausa (`:251`).
- Hay landscape de dos columnas en `game_screen.dart:474,546`.

**Qué falta o cambia**
- Crear:
  - `widgets/session/session_desktop_layout.dart`: rail de 76 con «TG», 4 destinos de 48 y el activo con fondo #2A0640 e icono `#DA9CFF`; cabecera con el modo, chips, «Piano» y «Pausar»; anillo de 170 y panel de 300.
  - `widgets/session/session_srs_panel.dart`: notas con estado, % y 5 puntos, y la leyenda de atajos.
  - `widgets/session/session_shortcuts.dart`.
- Breakpoint propuesto: ≥1024 px usa el layout de escritorio; entre 600 y 1023, la versión móvil centrada. Hoy solo existe `shellBreakpoint=600`, así que hay que añadir `desktopBreakpoint=1024`.
- **Datos del panel:** no hay estados con esos nombres. Derivación propuesta:
  - Crítica: en `critical_notes` o con precisión <50.
  - Consolidando: `!isLearning`.
  - En curso: el resto.
  - Fuente: `noteProgressSummariesProvider` más `practiceRecommendationsProvider`. ¿Qué notas se listan? Las de foco de la sesión (D11) o, si no hay foco, las 5 de `recommended_notes`.

---

## 6. Atajos de teclado (web)

**Qué existe:** solo Enter o Espacio sobre la tecla **enfocada** del piano (`piano_keyboard.dart:188-201`). En `lib/` no hay `Shortcuts`, `CallbackShortcuts`, `HardwareKeyboard` ni `LogicalKeyboardKey` fuera de esa función.

**Qué falta**

| Tecla | Acción | Notas |
|---|---|---|
| A–G | Responder la nota natural | Con nombres en solfeo (`NoteNamingMode.solfege`) se mantienen las letras inglesas; la leyenda lo aclara. |
| ⇧ + letra | Sostenido | Mayús+E y Mayús+B se ignoran (no hay E# ni B#). En `sharpsOnly` la letra sola podría equivaler a sostenido; mejor no hacerlo. |
| R | Repetir: vuelve a `listen` | Reutiliza `_startRound`. |
| Espacio | Siguiente: salta la espera de `result` | **Conflicto:** hoy Espacio activa la tecla enfocada. Si los atajos están activos, el foco del piano no debe consumir Espacio, o el foco pasa al contenedor de la sesión. |

Implementación: `CallbackShortcuts` y `Focus(autofocus)` en la raíz de la sesión. Se desactivan cuando el `NoteInputField` tiene el foco, para que el texto no dispare respuestas. Hacen falta tests de widget con `sendKeyEvent`.

---

## 7. Tests que se romperán

| Archivo | Qué busca y desaparece o cambia |
|---|---|
| `test/widget/home_screen_test.dart` | «Entrenador de oído absoluto» y «Modos de entrenamiento» (`:46-47`); los títulos de modo con paréntesis y «Ver todos» (`:54-63`); «Estadísticas» (`:75`); «Continuar práctica» y «Continuar» (`:96,110`); «Reproducir» (`:113,123`). |
| `test/widget/game_screen_test.dart` | «Preparate para escuchar»: **ya falla hoy**, porque el código dice «Prepárate» (`game_session_views.dart:358`). También «Reproducir» (`:80,102…`), «Confirmar» (`:107`), «Repetir» (puede seguir si el texto se conserva), `TextField` por defecto (`:147`) y el título del modo en el appbar (`:87`). |
| `test/widget/piano_keyboard_test.dart` | `Icons.check_circle` (`:109`), si se quitan los badges; los labels `find.text` si cambian el estilo o la posición. Hay que conservar las Semantics. |
| `test/widget/togesc_shell_test.dart` | El tap en «Estadísticas» (`:42,60`), que pasa a ser «Progreso»; `NavigationBar` (`:40`) si se usa una nav propia. |
| `test/e2e/app_smoke_test.dart` | «Modos de entrenamiento» (`:92`), «Ver todos» (`:120,145`), el tile «Entrenamiento de velocidad» (`:148`), «Reproducir» (`:114,128`) y «Estadísticas» (`:164`). |
| `test/integration/full_game_flow_test.dart` | «Modos de entrenamiento» (`:77`), «Reproducir» (`:82,95`), «Confirmar» (`:101`), `TextField` (`:104`), «Siguiente» (`:109`) y «Estadísticas» (`:125`). |
| `test/unit/ui_preferences_test.dart` | Valores por defecto `inputMode: both` y `confirmBeforeSubmit: true` (`:13-14`), según D1 y D6. |
| `test/unit/practice_session_preferences_test.dart` | Defaults `unlimited` y `autoAdvance` falso (`:22-24`), y `fromRounds` (`:10-14`) si se añade 12; depende de D2 y D3. |
| `test/unit/last_practice_session_test.dart` | `label` (`:17,27`), si los títulos de modo pierden el paréntesis («Intervalo»). |
| `test/unit/app_theme_test.dart` | Bajo riesgo: solo se rompe si se tocan los tokens que comprueba. |
| `test/widget/note_progress_screen_test.dart` | Bajo riesgo, si la pantalla se conserva. |

Tests nuevos: `srs_level_test`, `calendar_week_test`, `weekly_accuracy_delta_test`, `today_focus_notes_test`, `relative_time_test`, `statistics_screen_test` (rejilla y Semantics), `session_shortcuts_test` y `game_screen_test` (flujo de un toque, la tecla errónea en rojo y la correcta en verde).

---

## 8. Riesgos de accesibilidad

1. **Color como única señal:**
   - Semana L–D: la celda debe llevar un icono o patrón (✓, medio, ✗, vacío) y Semantics «lunes, cumplido, 14 rondas».
   - Rejilla de 12 notas: el % siempre visible; Semantics «Do sostenido, 63 por ciento, en curso, nivel 3 de 5».
   - Teclas: mantener los badges ✓/✗ actuales (`piano_keyboard.dart:150`) aunque v2 solo dibuje colores.
   - Píldora SRS: los puntos necesitan el texto «3/5».
2. **Teclas negras de 38 px:** el ancho visual puede ser de 38, pero la **zona táctil se queda en 48** (patrón actual, `piano_keyboard.dart:259,345`). En 390 px cada blanca mide unos 51 px y la zona de 48 centrada en el borde no tapa las blancas por debajo de 140 px. Por debajo de 336 px de ancho hay desbordamiento (`minWidth` en `:253`); hace falta un test a 320 px.
3. **Contraste** (cálculo manual):
   - Etiquetas `#7F7383` sobre `#FFF7FC` ≈ **4,3:1**: no llega a AA para texto de 12–13 px. Usar `#6E6272` o `#4D4351`.
   - Texto blanco sobre el verde `#4E9A52` ≈ 3,5:1 y sobre el ámbar `#FFB300` ≈ 1,9:1: no cumple. En esas celdas, texto oscuro (`#1E1B1E` o `#3A2B00`).
   - `#9C8FA3` sobre `#141018` ≈ 6:1: cumple.
4. **Semantics y anuncios:** no hay ningún `liveRegion` en `lib/`. Hacen falta para la overline o titular de fase («Responde», «Correcto, era Do», «Incorrecto, era Re, respondiste Mi»), con `SemanticsService.announce` o `Semantics(liveRegion: true)`. El avance automático de 2,2 s puede no dar tiempo al lector de pantalla; con un lector activo (`MediaQuery.accessibleNavigation`) conviene ampliarlo o pedir un toque.
5. **Movimiento:** las barras animadas de `listen` y el cambio de fase deben respetar `reduceAnimations` y `disableAnimations`, igual que el retardo actual (`game_screen.dart:47`).
6. **Tema oscuro forzado:** el usuario no puede elegir tema en la sesión (v2 lo deja pendiente). Hay que documentarlo y comprobar el contraste de todos los textos con los tokens de sesión.

---

## 9. Plan de implementación por lotes

Regla: ningún archivo aparece en dos lotes paralelos a la vez. «→» indica dependencia.

### Lote 0: base (dos desarrolladores en paralelo)
- **0A Tokens y tema** (dev 1):
  - `lib/app/design_tokens.dart`, `lib/app/togesc_colors.dart` y `lib/app/app_theme.dart` (añadir `AppTheme.session` y NavigationBar de 76).
  - Nuevo `lib/app/togesc_text_styles.dart` (overline, bigNumber, logo).
  - `test/unit/app_theme_test.dart` y `DESIGN.md`.
- **0B Dominio y preferencias** (dev 2):
  - Nuevos `lib/utils/srs_level.dart`, `lib/utils/calendar_week.dart` (semana L–D y delta semanal), `lib/utils/relative_time.dart`, `lib/utils/last_practice_navigation.dart` (helpers sacados de `continue_practice_card.dart`, solo copiados de momento) y `lib/providers/today_session_provider.dart` (notas foco, rondas y retomar).
  - Modificar `lib/providers/game_session_provider.dart` (`answerNotes`, `currentStreak`), `lib/providers/practice_focus_provider.dart` (lista), `lib/utils/note_pool.dart`, `lib/models/ui_preferences.dart` y `lib/models/practice_session_preferences.dart` (D1–D3, D6).
  - Tests unitarios nuevos más `test/unit/ui_preferences_test.dart`, `practice_session_preferences_test.dart`, `game_session_provider_test.dart` y `note_pool_test.dart`.

### Lote 1: pantallas (cuatro desarrolladores en paralelo) → depende de 0A y 0B
- **1A Home:**
  - `lib/screens/home_screen.dart` y nuevos `lib/widgets/home/*`.
  - Borrar `daily_focus_section.dart`, `continue_practice_card.dart`, `home_hub_views.dart`, `recommendation_card.dart` y `mode_bento_card.dart`.
  - `test/widget/home_screen_test.dart` y `test/unit/last_practice_session_test.dart` (más `lib/models/last_practice_session.dart` si cambia el label).
- **1B Shell y nav:** `lib/widgets/togesc_shell.dart` (app bar de 56 con racha y avatar; Práctica / Progreso / Velocidad / Perfil), `lib/app/router.dart` y `test/widget/togesc_shell_test.dart`.
- **1C Piano:**
  - `lib/widgets/piano_keyboard.dart` (variantes `session` y `sessionWide`, gradientes v2, `dimOthers`; API compatible con speed) y `test/widget/piano_keyboard_test.dart`.
  - El contrato de parámetros se publica antes de que empiece 1D.
- **1D Sesión móvil:**
  - `lib/screens/game_screen.dart` y nuevos `lib/widgets/session/{session_top_bar, session_phase_ring, srs_level_pill, session_key_actions}.dart`.
  - Borrar `lib/widgets/result_card.dart`.
  - En `lib/widgets/game_session_views.dart`, quitar solo lo muerto o lo sustituido **sin tocar `GameSessionPhaseLayout`**.
  - `test/widget/game_screen_test.dart`.
- **1E Progreso** (puede ir en paralelo con 1A–1D):
  - `lib/screens/statistics_screen.dart`, nuevos `lib/widgets/progress/*` y `lib/widgets/session_history_card.dart`.
  - Borrar `stats_bento_grid.dart` y, si procede, `note_accuracy_radar_chart.dart`.
  - Mover `stats_free_dashboard.dart` según D7.
  - Nuevo `test/widget/statistics_screen_test.dart`.

### Lote 2: escritorio y atajos → depende de 1C y 1D (lo hace el mismo desarrollador de 1D o va después)
- Nuevos `lib/widgets/session/{session_desktop_layout, session_srs_panel, session_shortcuts}.dart`.
- Modificar `lib/screens/game_screen.dart` (montaje del layout y los atajos).
- Nuevo `test/widget/session_shortcuts_test.dart`.
- En paralelo con 2, ajustes: `lib/widgets/gameplay_settings_section.dart` y `lib/widgets/session_settings_section.dart` (retirar «Confirmar» y el avance automático; añadir 12 rondas y el «enfoque»).

### Lote 3: integración y cierre → depende de todo lo anterior
- `test/e2e/app_smoke_test.dart`, `test/integration/full_game_flow_test.dart` y `test/integration/game_srs_integration_test.dart` (revisión).
- Adopción de tokens sin cambio de estructura en `speed_game_screen.dart`, `speed_session_views.dart`, `onboarding_views.dart`, paywall y cuenta.
- `docs/design_v2/github.md` (mapa actualizado) y `Plan/progreso_recuperacion_2026-10.md`.
- Verificación: analyze, test y revisión de a11y; requiere Flutter instalado.
