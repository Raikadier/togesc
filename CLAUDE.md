# TOGESC — guía para Claude Code

App Flutter (Riverpod + flutter_soloud + Supabase opcional) para entrenar el oído absoluto con SRS. La app está en `TOGESC/togesc/`. La UI está en español, con ortografía completa.

## Trabajo en curso
**Rediseño v2.1.** Sigue `Plan/hoja_ruta_rediseno_v2_1.md`: reglas, lotes y prompt de arranque. Implementa un lote por sesión.
- Qué cambia: `docs/design_v2_1/SPEC_rediseno_v2_1.md`
- Referencia visual: `docs/design_v2_1/prototype/` (HTML; es referencia, no código a portar)

## Fuentes de verdad
- `DESIGN.md`: sistema visual (tokens en `lib/app/design_tokens.dart`, `togesc_colors.dart` y `app_theme.dart`).
- `PRODUCT.md`: producto y restricciones. Sin XP en el Home, sin métricas inventadas (D10) y un solo front Flutter.
- `Plan/system_design.md`: arquitectura.

## Reglas rápidas
- Nada de hex sueltos en widgets: usar `DesignTokens`, `ColorScheme` o `TogescColors.of(context)`.
- Respetar `reduceAnimations` y `MediaQuery.disableAnimations` en todo el movimiento.
- Mantener las `ValueKey` existentes, porque los tests e2e dependen de ellas.
- Antes de cerrar un cambio, ejecutar en `TOGESC/togesc`: `flutter analyze` (los info son fatales en el CI) y `flutter test`.
- No hacer commit ni push sin que el propietario lo pida.
