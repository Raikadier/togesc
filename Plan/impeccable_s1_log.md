# Log S1 — Home académico (distill + quieter)

**Sprint:** S1 (parcial — Home hub)  
**Fecha:** 2026-07-26  
**Comandos Impeccable:** `distill home` + `quieter home` + fragmento `clarify` / `adapt` en ModeBento  
**Estado:** lotes Home aplicados; resto S1 (sesión juego, clarify global) pendiente

---

## 1. Decisión de producto (cerrada)

Usuario aprobó la recomendación híbrida académica:

| Elemento | Decisión |
|----------|----------|
| Daily Focus | Solo notas críticas + CTA «Practicar ahora» |
| Racha | Label secundario (`labelMedium`), sin card hero |
| XP | **Oculto en Home** (modelo/prefs pueden seguir existiendo) |
| Tono | Coach («Conviene repasar»), no «ATENCIÓN REQUERIDA» / rayos / casino |

Registrado en `PRODUCT.md` y backlog.

---

## 2. Cambios de código

| Archivo | Cambio |
|---------|--------|
| `lib/widgets/daily_focus_section.dart` | Eliminada `_StreakXpCard`; `PracticeStreakLabel`; copy coach; `TogescColors` para incorrect |
| `lib/screens/home_screen.dart` | Orden: título → racha → enfoque → continuar → modos → chart; tildes; icono shuffle |
| `lib/widgets/mode_bento_card.dart` | Play siempre visible; Semantics; Reduce Motion; «Desbloquear con Pro»; breakpoint `shellBreakpoint` |
| `lib/widgets/continue_practice_card.dart` | «Continuar práctica» |

Sin cambios SRS/audio. XP sigue calculándose en prefs/engagement; solo deja de mostrarse en hub.

---

## 3. Jerarquía Home resultante

1. Título producto  
2. Racha (si days > 0)  
3. Enfoque diario (solo si hay notas críticas)  
4. Continuar práctica (si hay última sesión)  
5. Modos de juego  
6. Evolución semanal (si hay actividad)

---

## 4. Backlog tocado

Ver `Plan/impeccable_backlog.md` — P0-01 parcial, P1-02 done, P1-03 parcial (home), P1-10 done, P2-06 parcial (bento).

---

## 5. Pendiente S1

- ~~Progressive disclosure modos («Ver todos») — P1-01~~ **hecho**
- ~~Distill sesión juego — P1-04 / P1-05~~ **hecho**
- ~~Harden/adapt — P1-06/07/09/11~~ **hecho**
- ~~Clarify ES global — P1-03~~ **hecho**

### Lote clarify ES

Barrido de copy visible (no comentarios de código exhaustivos):

| Área | Ejemplos |
|------|----------|
| Resultado | FEEDBACK→RITMO; Rápido / Tómate |
| Onboarding / About | Cómo funciona, repetición, variación, oído… |
| Cuenta / Pro / Paywall | sesión, contraseña, suscripción, sincronización |
| Velocidad | desafío, ráfagas, límite, Menú, ¡CORRECTO! |
| Stats / ajustes | Distribución de precisión, práctica, automáticamente |
| Privacidad | Política, analítica, móvil… |

S1 núcleo Impeccable **cerrado**. Siguiente sprint natural: S2 (velocidad layout Stitch / stats densos) o polish global.

### Lote harden / adapt

| Cambio | Detalle |
|--------|---------|
| Motion global | `MaterialApp.builder`: `MediaQuery.disableAnimations` \|\| preferencia + `TickerMode` |
| Copy ajuste | Subtitle «Reducir animaciones» actualizado |
| Semantics | ModeBento locked/unlocked; `HomeModeOptionCard` |
| SafeArea | `TogescShell` (bottom solo wide), `TogescScaffold`, home/stats/account/paywall/subscription |
| Max width | `TogescScaffold` ConstrainedBox 1200; PageBody en account/paywall/subscription |

Archivos clave: `main.dart`, `togesc_ui.dart`, `togesc_shell.dart`, pantallas shell, `mode_bento_card.dart`, `home_hub_views.dart`.

### Lote «Ver todos» (mismo día)

- `ModeBentoGrid` stateful: colapsado = modos `!isPro`; expandido = free + Pro.
- Header con `TextButton` «Ver todos (N)» / «Ver menos».
- `HomeSectionHeader.trailing` para el enlace Stitch-like.

### Lote sesión de juego (`distill` + `clarify`)

**Thesis:** una tarea = responder; Pausar/Saltar no deben competir con Repetir/Confirmar.

| Cambio | Detalle |
|--------|---------|
| AppBar | `GameSessionRoundAppBarActions` (pausa/saltar) en listening + waiting |
| Answer layout | header+guía → chips → texto opcional → piano → Repetir/Confirmar |
| Dual-input | guidance italic; label «Campo de texto (opcional)» en modo ambos |
| Copy ES | tildes en fases idle/listening/cluster/answer/result |
| NoteInputField | sin «INPUT»; botón Enviar |
| Chip remove | IconButton 48dp |
| Shell | SafeArea + `TogescPageBody` en game |

Archivos: `game_screen.dart`, `game_session_views.dart`, `note_input_field.dart`, `ui_preferences.dart`.

---

## 6. Verificación

- [x] `dart analyze` archivos Home tocados  
- [ ] Revisión visual en dispositivo/emulador (usuario)  
