# Backlog Impeccable — TOGESC UI

**Fuente:** S0 critique ([Assessment A](12141dd9-9d7b-4578-b168-cbe8dfc6159f)) + audit native ([Assessment B](0e6dc5ec-0cf3-40cc-bbe5-e1b1839e4283))  
**Actualizado:** 2026-07-26 (S3)  
**Scores baseline:** Critique heurísticas **25/40** · Audit native **12/20**

Leyenda: `todo` · `doing` · `done` · `deferred` · `wontfix`

---

## P0 — Bloquea claridad de práctica

| ID | Estado | Hallazgo | Superficie | Comando S1+ | Evidencia |
|----|--------|----------|------------|-------------|-----------|
| P0-01 | done | Home: jerarquía académica + progressive disclosure modos | Home | — | S1 2026-07-26 |

---

## P1 — Alto impacto (S1 prioritario)

| ID | Estado | Hallazgo | Superficie | Comando | Evidencia |
|----|--------|----------|------------|---------|-----------|
| P1-01 | done | «Ver todos (N)» / «Ver menos»; colapsado = free only | Home | `layout home` | S1 2026-07-26 |
| P1-02 | done | XP fuera del hub; racha label; tono coach; sin casino/rayo | Home | `quieter home` | S1 2026-07-26 |
| P1-03 | done | Copy ES: tildes + sin FEEDBACK/Go Premium en superficies clave | Global | `clarify` | S1 2026-07-26 |
| P1-04 | done | Sesión respuesta: pausa/saltar a AppBar; CTAs Repetir/Confirmar; guía dual-input | Game | `distill game` | S1 2026-07-26 |
| P1-05 | done | Dual-input: guidance + texto marcado opcional; hint ES | Game | `clarify answer` | S1 2026-07-26 |
| P1-06 | done | `reduceAnimations` → MediaQuery.disableAnimations + TickerMode global | Global | `harden` | `main.dart` S1 |
| P1-07 | done | Semantics en ModeBento (locked+unlocked) y HomeModeOptionCard | Global | `harden` | S1 |
| P1-08 | done | Chip remove con IconButton 48dp | Game | `harden` | S1 2026-07-26 |
| P1-09 | done | SafeArea en shell + TogescScaffold + account/paywall/stats/home | Global | `adapt` | S1 |
| P1-10 | done | ModeBento: play siempre visible + Semantics + reduce motion | Home | `adapt` | S1 2026-07-26 |
| P1-11 | done | contentMaxWidth vía TogescScaffold + PageBody en account/paywall/subscription | Global | `adapt` | S1 |

---

## P2 — Mejora / alineación Stitch

| ID | Estado | Hallazgo | Superficie | Comando | Evidencia |
|----|--------|----------|------------|---------|-----------|
| P2-01 | done | Resultado: pills SRS + reporte + CTA Siguiente round | Game result | `polish result` | 2026-07-26 |
| P2-02 | done | Speed selector bento Chaos/Teclas negras + Fácil/Pro/Elite | Speed | `layout speed select` | S2 2026-07-26 |
| P2-03 | done | Onboarding brand-first + bento + hero visual (sin claims Elite) | Onboarding | `onboard` | S3 2026-07-26 |
| P2-04 | done | Stats: filtro 7d/30d/Todo + densificación Pro | Stats | `layout statistics` | S2 2026-07-26 |
| P2-05 | done | Colores tema vía ColorScheme/TogescColors (radar, mic, account, stats) | Varios | `polish` | 2026-07-26 |
| P2-06 | done | Breakpoints: ModeBento/`shellBreakpoint`; daily focus single column | Global | `adapt` | S1+polish |
| P2-07 | done | Wide: NavigationRail M3 (sustituye TextButton links) | Shell | `adapt` | 2026-07-26 |
| P2-08 | done | ModeBento sin GridView shrinkWrap; cache chart semanal home | Home | `optimize` | 2026-07-26 |
| P2-09 | done | Landscape sesión: split controles ∥ piano | Game | `adapt` | 2026-07-26 |
| P2-10 | done | Sombras con `scheme.shadow` (input, piano) | Widgets | `polish` | 2026-07-26 |

---

## Gap Stitch ↔ Flutter (mapa)

| Stitch folder | Flutter | Gap resumido | IDs |
|---------------|---------|--------------|-----|
| `home_premium_practice_hub` | `home_screen` + hub widgets | Radar editorial, Ver todos, densidad, Continuar extra | P0-01, P1-01, P1-02 |
| `game_session_premium_response` | `game_screen` + session views | Composición más limpia en Stitch; Flutter densifica | P1-04, P1-05 |
| `game_session_premium_result` | `result_card` | Pills + reporte + CTA alineados | P2-01 done |
| `statistics_premium_pro_dashboard` | `statistics_screen` | Filtro periodo + densificación Pro | P2-04 done |
| `onboarding_premium_welcome` | `onboarding_screen` | Brand + bento + hero local aplicados | P2-03 done |
| `selector_premium_speed_mode` | `speed_mode_select_*` | Chaos/Teclas negras/dificultad aplicados | P2-02 done |
| `account_premium_sync_settings` | `account_screen` + sync | Prefs inline + hub reorder | S3 done |
| `togesc_landing_page_pro` | (fuera app / futuro) | Persuade; no bloquea Operate | deferred |

**Tokens:** Flutter ≈ brief técnico Harmonic Precision. Algunos PNG Stitch usan más sombra/glow — **no** adoptar glow si contradice DESIGN.md (capas tonales).

---

## Orden propuesto post-S0 (S1)

1. **Decisión producto** sobre P1-02 (XP/racha) — preguntar al usuario.
2. `distill` + `layout` Home (P0-01, P1-01).
3. `clarify` copy ES global (P1-03) — puede ir en paralelo temprano.
4. `distill` / `clarify` sesión juego (P1-04, P1-05).
5. `harden` + `adapt` transversal (P1-06…P1-11) en el mismo sprint si cabe, o S1.5.

---

## Hecho en S0

| Ítem | Estado |
|------|--------|
| Skill impeccable instalada | done |
| PRODUCT.md | done |
| DESIGN.md canónico | done |
| Critique Assessment A | done |
| Audit native Assessment B | done |
| Plan + log + backlog documentados | done |
