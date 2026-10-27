# Progreso — rediseño v2.1

Log en orden cronológico inverso. Hoja de ruta: `Plan/hoja_ruta_rediseno_v2_1.md`. Qué cambia: `docs/design_v2_1/SPEC_rediseno_v2_1.md`.

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
