# Progreso — rediseño v2.1

Log en orden cronológico inverso. Hoja de ruta: `Plan/hoja_ruta_rediseno_v2_1.md`. Qué cambia: `docs/design_v2_1/SPEC_rediseno_v2_1.md`.

## 2026-10-26 · Lote 0: preparación · Claude Code
- **Cambios sin commitear de v2:** cuando empezó el lote ya no había ninguno. El propietario los había commiteado en `feat/rediseno-v2` (`48a3441` panel «Enfoque SRS» en vivo, `6386970` docs v2.1 y `f5a48db` .gitignore). No hubo que tocar nada.
- **Rama:** `feat/rediseno-v2.1`, creada desde `feat/rediseno-v2` (`f5a48db`) con el árbol limpio.
- **Docs:**
  - `DESIGN.md`: `version` pasa a 2.1, cambia `updated` a 2026-10-26 y se añade la sección «v2.1», que remite al SPEC.
  - `PRODUCT.md`: en «Notas» se registra la decisión del 2026-10-26. Se mantiene sin XP en el Home.
- **Código:** sin cambios.
- **Verificación:** `flutter analyze`: «No issues found!». `flutter test` completo: `+523 ~1: All tests passed!`.
