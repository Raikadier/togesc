# Plan Impeccable — Mejora del front TOGESC

**Estado:** activo  
**Inicio:** 2026-07-26  
**Skill:** `.agents/skills/impeccable/` (v4.0.2)  
**Modo dominante:** Operate (app Flutter de práctica)  
**Identidad visual:** Harmonic Precision (refinement, no redesign)

Este documento es la hoja de ruta viva. El detalle de cada sprint vive en `Plan/impeccable_sN_*.md`. El backlog priorizado está en `Plan/impeccable_backlog.md`.

---

## Objetivo

Cerrar el gap entre mockups Stitch + design system Harmonic Precision y la UI Flutter real, subiendo craft, claridad y calidad nativa **sin** reemplazar la identidad visual ni tocar la lógica SRS/audio salvo lo necesario para UI.

## Principios de ejecución

1. Documentar **absolutamente todo** (planes, hallazgos, decisiones, comandos, evidencias).
2. Una superficie / un comando Impeccable → un lote de cambios → verificación acotada.
3. Variantes nativas (`audit.native`, `adapt.native`) para Flutter adaptive.
4. Stitch PNG = referencia de composición; `DESIGN.md` + tokens Dart = autoridad normativa.
5. No fabricar claims de marketing ausentes en producto.

## Artefactos canónicos Impeccable

| Artefacto | Ruta | Rol |
|-----------|------|-----|
| PRODUCT.md | `/PRODUCT.md` | Verdad de producto |
| DESIGN.md | `/DESIGN.md` | Sistema visual canónico |
| Tokens Flutter | `TOGESC/togesc/lib/app/design_tokens.dart` | Implementación |
| Briefs Stitch | `Plan/stitch_*.md` | Requisitos de pantalla |
| Mockups | `.tmp_stitch/stitch_togesc_design_system/` | Evidencia visual |
| Backlog | `Plan/impeccable_backlog.md` | Trabajo priorizado |
| Log S0 | `Plan/impeccable_s0_log.md` | Diario del sprint 0 |

## Fases / sprints

| Sprint | Nombre | Estado | Entregables |
|--------|--------|--------|-------------|
| **S0** | Fundación + diagnóstico | **Cerrado (2026-07-26)** | PRODUCT.md, DESIGN.md, critique, audit, backlog, docs |
| **S1** | Núcleo práctica | **Cerrado (2026-07-26)** | Home + sesión + harden/adapt + clarify ES |
| **Polish** | Refinement theming | **Cerrado (2026-07-26)** | Ver `impeccable_polish_log.md` |
| **S2** | Velocidad + stats | **Cerrado (2026-07-26)** | Ver `impeccable_s2_log.md` |
| **S3** | Cuenta / Pro / onboarding + polish | **Cerrado (2026-07-26)** | Ver `impeccable_s3_log.md` |

### Detalle S0 (fundación)

1. Instalar / verificar skill impeccable.
2. `context.mjs` + `init` → PRODUCT.md.
3. Fijar DESIGN.md canónico desde Harmonic Precision + código.
4. Critique (Assessment A) + Audit native (Assessment B).
5. Gap Stitch ↔ Flutter.
6. Backlog P0/P1/P2 con comandos sugeridos.
7. Documentación completa del sprint.

### Detalle S1–S3 (resumen)

Ver sección original del plan conversacional: Home/sesión → velocidad/stats → cuenta/onboarding/polish. Comandos típicos por síntoma: `distill`, `layout`, `clarify`, `quieter`, `harden`, `adapt`, `polish`, `animate`, `onboard`.

## Ritmo de trabajo en Cursor

```
/impeccable <comando> <superficie>
→ implementar solo ítems del backlog acordados
→ documentar en Plan/impeccable_sN_log.md
→ actualizar backlog (done / deferred)
```

## Criterios de hecho globales

- [ ] PRODUCT.md y DESIGN.md versionados y usados en pases siguientes
- [ ] Home y sesión alineados en jerarquía con Stitch (no pixel-perfect obligatorio)
- [ ] Touch ≥ 48, contraste light/dark, Semantics en controles clave
- [ ] Copy ES con ortografía completa
- [ ] Sin regresiones SRS/audio
- [ ] Cada sprint con log + backlog actualizado

## Decisiones de producto

1. **Cerrada 2026-07-26:** Home académico — críticas + CTA; racha label; sin XP en hub. Ver PRODUCT.md y `impeccable_s1_log.md`.
2. **Cerrada 2026-07-26 (S3):** Onboarding no adopta claims Stitch («estándar de oro» / Elite v4); brand TOGESC + pedagogía honest + hero local sin imagen remota.
3. **Abierta (menor):** glow Stitch / pixel-perfect PNG (explícitamente no adoptar glow).

S0–S3 + P2 restante cerrados. Ver `impeccable_p2_remaining_log.md`.

---

*Última actualización: 2026-07-26 (P2 restante).*
