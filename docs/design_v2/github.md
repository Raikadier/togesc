repo: Raikadier/togesc
branch: main
path: TOGESC/togesc/lib

## Last sync

date: 2026-09-10T23:24:00Z

### Updated in this project
- Recreación fiel del diseño actual (Home, sesión, resultado, estadísticas, velocidad, onboarding) desde los tokens Harmonic Precision.
- Rediseño propuesto centrado en la sesión de juego (feedback in-situ sobre el mismo teclado).

## Screen map

| Pantalla del proyecto | Archivos del repo |
|---|---|
| Home / hub | lib/screens/home_screen.dart, lib/widgets/home_hub_views.dart, lib/widgets/daily_focus_section.dart, lib/widgets/continue_practice_card.dart, lib/widgets/mode_bento_card.dart, lib/widgets/togesc_shell.dart |
| Sesión de juego | lib/screens/game_screen.dart, lib/widgets/game_session_views.dart, lib/widgets/piano_keyboard.dart, lib/widgets/togesc_ui.dart |
| Resultado de ronda | lib/widgets/result_card.dart, lib/widgets/piano_keyboard.dart |
| Estadísticas | lib/screens/statistics_screen.dart, lib/widgets/stats_bento_grid.dart, lib/widgets/stats_free_dashboard.dart, lib/widgets/session_evolution_chart.dart, lib/widgets/session_history_card.dart |
| Modo velocidad | lib/screens/speed_mode_select_screen.dart, lib/widgets/speed_session_views.dart |
| Onboarding | lib/screens/onboarding_screen.dart, lib/widgets/onboarding_views.dart |
| Tokens / tema | lib/app/design_tokens.dart, lib/app/app_theme.dart, lib/app/togesc_colors.dart, DESIGN.md |
