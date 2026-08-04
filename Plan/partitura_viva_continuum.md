# Partitura viva — continuum

## Cerrado

| Commit | Fase |
|--------|------|
| `db0634f`…`6324b2c` | Landing signature, Mk.2, residuales, scroll progress |
| `96bac51`…`1dcc1d0` | Copy ES + demo ronda |
| (QA) | pointer-events demo; BoxDecoration; speed/account sentence-case; tests Home |

## Hallazgos QA

- Desktop: `.hero-plane { pointer-events: none }` bloqueaba Escuchar/piano → `auto` en controles.
- Tipografía: `Decorations` → `BoxDecoration` (rompía compilación).
- Tests Home alineados a copy Partitura viva.

## Operativa

- Autonomía: commit + push sin pedir confirmación.
- No trackear `.agents/`, `.tmp_stitch/`, `skills-lock.json` salvo mandato.
