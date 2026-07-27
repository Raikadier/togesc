# Log S2 — Velocidad + estadísticas

**Sprint:** S2  
**Fecha:** 2026-07-26  
**Comandos Impeccable:** `layout speed select` + `layout statistics`  
**Estado:** cerrado (código + docs)

---

## 1. Alcance

| Superficie | Ítem backlog | Resultado |
|------------|--------------|-----------|
| Selector velocidad | P2-02 | Bento Stitch: Chaos / Teclas negras / Fácil·Pro·Elite |
| Estadísticas | P2-04 | Filtro 7d / 30d / Todo + densificación Pro |

---

## 2. Velocidad — decisiones

| Tema | Decisión |
|------|----------|
| Modo Chaos | Visual Stitch sobre `GameMode.random` (no modo nuevo) |
| Teclas negras | Visual oscuro sobre `GameMode.sharpsOnly` |
| Fácil / Pro / Elite | Tiempo inicial **15 / 10 / 5** s (`SpeedDifficulty`) |
| Persistencia dificultad | `speedDifficultyProvider` (sesión; no prefs) |
| Pedagogía | Misma lógica SRS/audio; solo cambia `sessionInitialTime` |

### Archivos

| Archivo | Cambio |
|---------|--------|
| `game_constants.dart` | `SpeedDifficulty`; tildes en displayName |
| `speed_difficulty_provider.dart` | **nuevo** StateProvider |
| `speed_session_provider.dart` | `sessionInitialTime`; `setTargetMode(initialTime)`; retry respeta inicio |
| `speed_mode_select_screen.dart` | Bento 2+3 wide / columna mobile |
| `speed_mode_select_views.dart` | `SpeedDifficultySelector` |
| `speed_session_views.dart` | Variantes card chaos/dark; idle muestra tiempo real |
| `speed_game_screen.dart` | Lee dificultad al configurar sesión |

---

## 3. Estadísticas — decisiones

| Tema | Decisión |
|------|----------|
| Filtro temporal | Aplica a **evolución** + **historial** |
| Precisión / intentos SRS | Siguen siendo **acumulados** (SRS no es serie temporal) |
| Copy | Hint bajo el SegmentedButton explica el alcance |
| Layout Pro | Dificultad alta ∥ Mayor dominio en ≥640px |
| Gestión de datos | Sección con título (Exportar / Reiniciar) |
| Meta precisión | Label «Progreso hacia meta (90%)» + % bajo barra |

### Archivos

| Archivo | Cambio |
|---------|--------|
| `session_history_stats.dart` | `StatsPeriod`, `filterHistoryByPeriod`, `buildPracticeSummariesForPeriod` |
| `statistics_screen.dart` | Stateful + SegmentedButton + layout |
| `session_history_card.dart` | `entries` opcional filtrado |
| `stats_bento_grid.dart` | PRECISIÓN + progreso meta |
| `session_history_stats_test.dart` | Tests periodo |

---

## 4. Aplazado (fuera S2)

- P2-01 resultado sesión Stitch  
- P2-03 onboarding hero  
- P2-07 NavigationRail  
- Glow premium Stitch (contradice DESIGN.md capas tonales)

---

## 5. Verificación

- [x] `dart analyze` en archivos tocados  
- [x] Tests unitarios periodo historial  
- [ ] Smoke manual: selector → Elite → sesión idle muestra 5s  
- [ ] Smoke manual: stats filtro 7/30/Todo cambia gráfico/historial  
