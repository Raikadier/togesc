# Progreso — rediseño v2

Log en orden cronológico inverso.

## 2026-10-09 · Lote 0B: dominio, providers y preferencias · Senior Developer (Flutter)
- **Estado:** pendiente de compilar. En esta máquina no hay Flutter: falta pasar `flutter analyze` y `flutter test`. Cada símbolo del proyecto se verificó con grep.
- **Decisiones aplicadas:**
  - **D1, D2 y D6:** `confirmBeforeSubmit=false`, `inputMode=pianoOnly`, `autoAdvanceAfterResult=true` y `resultAutoAdvanceDelay` de 2200 ms (400 ms con movimiento reducido). Las tres siguen siendo configurables.
  - **D3:** `SessionRoundGoal.twelve`, que es el valor por defecto. La duración estimada sale de rondas × `estimatedSecondsPerRound` (30 s) y está marcada como estimación.
  - **D11:** lista de foco de hasta 3 notas. Las notas de foco ocupan el 60 % de las rondas (`focusRoundShare`); el resto de rondas usa el pool configurado.
- **Migración de preferencias:**
  - Las claves nuevas terminan en `_v2`; las legacy solo se leen como respaldo.
  - Un valor legacy distinto del default antiguo se considera elegido por el usuario y se conserva. Un valor igual al default antiguo, o la ausencia de valor, recibe el default nuevo.
  - Motivo: `setUiPreferences` y `setPracticeSessionPreferences` escribían todos los campos a la vez, así que no se puede distinguir «nunca lo tocó» de «eligió el default». En la práctica, quien había desactivado «confirmar» o activado el avance conserva lo que tenía. Quien había elegido «Sin límite» pasa a 12 rondas, porque ese caso es indistinguible.
- **Archivos modificados:**
  - `TOGESC/togesc/lib/models/ui_preferences.dart`
  - `TOGESC/togesc/lib/models/practice_session_preferences.dart`
  - `TOGESC/togesc/lib/models/note_progress_summary.dart`: nuevo campo `intervalIndex`, opcional y no persistido.
  - `TOGESC/togesc/lib/services/app_preferences.dart`
  - `TOGESC/togesc/lib/providers/game_session_provider.dart`
  - `TOGESC/togesc/lib/providers/practice_focus_provider.dart`
  - `TOGESC/togesc/lib/utils/note_pool.dart`
- **Archivos nuevos:**
  - `TOGESC/togesc/lib/utils/srs_level.dart`, `lib/utils/calendar_week.dart`, `lib/utils/relative_time.dart` y `lib/utils/today_session.dart`.
  - `TOGESC/togesc/lib/providers/clock_provider.dart` y `lib/providers/today_session_provider.dart`.
- **Tests:**
  - Nuevos: `srs_level_test`, `calendar_week_test`, `relative_time_test`, `today_session_test` y `today_session_provider_test`.
  - Ampliados: `ui_preferences_test`, `practice_session_preferences_test`, `note_pool_test` y `game_session_provider_test`.
  - `last_practice_session_test` no cambia: los defaults no le afectan. Solo se rompería si el lote 1A cambia los labels.
- **Umbral de la semana L–D:** la meta diaria es la meta de rondas del usuario, o 12 si no tiene. Cumplido: rondas ≥ meta. Parcial: entre 1 y meta − 1. Fallado: día pasado sin rondas posterior a la primera práctica registrada. Sin práctica: hoy, días futuros y días anteriores a la primera práctica.
- **Delta semanal:** precisión por rondas de los últimos 7 días frente a los 7 anteriores. No usa la base de la precisión global del SRS, así que la UI debe rotularlo como «precisión de rondas».
- **Para 1D (no se tocó la pantalla):** `game_screen.dart:521` calcula `incorrectSet` a partir de `_selectedNotes`, que `_submitNotes` vacía en la línea 145. Hay que sustituirlo por `session.lastResult!.wrongNotes`, que ya trae los datos del provider. `_autoAdvanceDelay` (`:46`) debe usar `resultAutoAdvanceDelay` y `resultAutoAdvanceDelayReducedMotion`.
- **Tests que romperán los nuevos defaults (los dueños son 1D y el lote 3):**
  - `test/widget/game_screen_test.dart`: «Confirmar» en `:107` y `TextField` en `:147`.
  - `test/integration/full_game_flow_test.dart`: «Confirmar», `TextField` y «Siguiente».
- **No hecho:** `lib/utils/last_practice_navigation.dart`. Mover los helpers de `continue_practice_card.dart` se deja para 1A, para no duplicar código sin consumidores.

## 2026-10-09 · Lote 0A: tokens y tema · UI Designer
- **Estado:** pendiente de compilar. En esta máquina no hay Flutter: falta pasar `flutter analyze` y `flutter test`.
- **Archivos:**
  - `TOGESC/togesc/lib/app/design_tokens.dart`: tokens v2 y funciones `masteryColor`, `masteryOnColor`, `masteryOnColorFor`, `masteryBarColorOnDark` y `contrastRatio`.
  - `TOGESC/togesc/lib/app/togesc_colors.dart`: 8 gradientes de piano con valor por defecto y `TogescColors.session`.
  - `TOGESC/togesc/lib/app/app_theme.dart`: `AppTheme.session`; NavigationBar de 76 con el destino activo en `primary` y negrita; fondo de la barra clara `#FFFDFE`.
  - Nuevo: `TOGESC/togesc/test/unit/design_tokens_v2_test.dart`.
- **Ajustes AA:**
  - `outline`/`textTertiary`: `#7F7383` pasa a `#726876`, con el mismo tono HSL. Contraste: 5,04:1 sobre `#FFF7FC` y 4,57:1 sobre `#F3ECF1`.
  - Verde medio de la rejilla: `#3B8C3F` pasa a `#38853C`. Con blanco encima da 4,58:1; con el valor original no llegaba ni con blanco (4,19) ni con texto oscuro (4,07).
  - Texto por celda:
    - `#1E1B1E` sobre `#4E9A52` (4,93) y sobre `#FF8A8A` (7,5).
    - `#3A2B00` sobre los ámbar (7,7 y 9,0).
    - Blanco sobre `#38853C`, `#2E7D32` (5,1) y `#C62828` (5,6).
- **Sin `@Deprecated`:** `pianoWhite`, `pianoBlack` y `radiusXl` siguen en uso fuera de `lib/app`, y `flutter analyze` trata los avisos info como fatales. Se deprecan cuando el lote 1 deje de usarlos.
- **Pendiente (fuera de alcance):** actualizar `DESIGN.md` y `test/unit/app_theme_test.dart`. Los estilos de texto quedaron en `DesignTokens`, sin crear `togesc_text_styles.dart`.
