# TOGESC — Entregables Stitch

**Design system:** tema **Harmonic Precision** — `harmonic_precision/DESIGN.md` (en cualquier zip)  
**Brief oleada 1:** [stitch_design_brief.md](stitch_design_brief.md)  
**Brief oleada 2:** [stitch_design_brief_wave2.md](stitch_design_brief_wave2.md)

| Zip | Contenido |
|-----|-----------|
| `stitch_togesc_design_system.zip` | Oleada 1 — hub, onboarding, juego (answer/result), stats Pro, cuenta sync, selector velocidad |
| `stitch_togesc_design_system_wave2.zip` | Oleada 2 — 22 pantallas faltantes (juego, velocidad, auth, Pro, about, diálogos) |

Cada pantalla incluye al menos `screen.png`. Algunas traen también `code.html` (HTML + Tailwind; referencia visual, no producción Flutter).

---

## Inventario completo (30 artboards app + 1 landing)

### Oleada 1 — `stitch_togesc_design_system.zip` (8 app)

| Carpeta Stitch | ID brief | Notas |
|----------------|----------|-------|
| `onboarding_premium_welcome` | `onboarding` | png + html |
| `home_premium_practice_hub` | `home` | png + html |
| `game_session_premium_response` | `game_answer` | png + html |
| `game_session_premium_result` | `game_result` | png + html |
| `selector_premium_speed_mode` | `speed_mode_select` | png + html |
| `statistics_premium_pro_dashboard` | `statistics` | vista Pro, png + html |
| `account_premium_sync_settings` | `account_signed_in` | png + html |
| `togesc_landing_page_pro` | — | extra web promocional, png + html |
| `harmonic_precision/DESIGN.md` | — | tokens M3 |

### Oleada 2 — `stitch_togesc_design_system_wave2.zip` (22 app)

| Carpeta Stitch | ID brief | Nombre esperado brief | html |
|----------------|----------|----------------------|------|
| `game_session_premium_idle` | `game_idle` | ✅ | solo png |
| `game_session_premium_listening` | `game_listening` | ✅ | solo png |
| `game_session_premium_cluster` | `game_cluster` | ✅ | solo png |
| `speed_session_premium_idle` | `speed_idle` | ✅ | solo png |
| `speed_session_premium_listening` | `speed_listening` | ✅ | solo png |
| `speed_session_premium_answer` | `speed_answer` | ✅ | solo png |
| `speed_session_premium_correct` | `speed_correct` | ✅ | solo png |
| `speed_session_premium_incorrect` | `speed_incorrect` | ✅ | solo png |
| `speed_session_premium_timeout` | `speed_timeout` | ✅ | solo png |
| `speed_session_premium_game_over` | `speed_game_over` | ✅ | solo png |
| `account_premium_sign_in` | `account_sign_in` | ✅ | solo png |
| `account_premium_sign_up` | `account_sign_up` | ✅ | solo png |
| `account_premium_forgot_password` | `account_forgot` | ✅ | solo png |
| `account_premium_reset_password` | `account_reset` | ✅ | solo png |
| `account_premium_offline_mode` | `account_offline` | ⚠️ sufijo `_mode` | solo png |
| `paywall_premium_pro_access` | `paywall` | ⚠️ sufijo `_access` | solo png |
| `subscription_premium_management` | `subscription` | ⚠️ `_management` | png + html |
| `statistics_premium_free_mode` | `statistics_free` | ⚠️ sufijo `_mode` | png + html |
| `about_premium_info_hub` | `about` | ⚠️ sufijo `_hub` | png + html |
| `privacy_premium_policy` | `privacy` | ✅ | png + html |
| `dialog_premium_reset_confirm` | `dialog_reset_progress` | ✅ | png + html |
| `dialog_premium_csat_survey` | `dialog_csat` | ⚠️ sufijo `_survey` | png + html |

**Extras en wave2 (ignorar al implementar):**
- `togesc_landing_page_pro/` — duplicado de oleada 1
- `stitch_togesc_design_system (1)/` — carpeta anidada vacía (artefacto export Stitch)
- `harmonic_precision/DESIGN.md` — copia del design system

---

## Cobertura vs brief

| Flujo | Estados brief | En zip |
|-------|---------------|--------|
| Juego estándar | idle, listening, answer, result, cluster | ✅ 5/5 |
| Modo velocidad | selector + 7 estados sesión | ✅ 8/8 |
| Cuenta | signed_in + auth (4) + offline | ✅ 6/6 |
| Estadísticas | Pro + Free | ✅ 2/2 |
| Monetización | paywall + subscription | ✅ 2/2 |
| Info | about + privacy | ✅ 2/2 |
| Diálogos | reset + CSAT | ✅ 2/2 |
| Hub / onboarding | home + onboarding | ✅ 2/2 |

| Métrica | Valor |
|---------|-------|
| Pantallas app con mockup | **30** |
| Landing marketing (extra) | 1 |
| Cobertura brief | **~100 %** |
| Pantallas sin `code.html` | 15 (oleada 2, mayoría juego/velocidad/auth/paywall) |

---

## Design system — Harmonic Precision (resumen)

| Token | Valor |
|-------|-------|
| Tema | Material 3, tono educativo/profesional |
| Tipografía | Hanken Grotesk |
| Primary | `#6A1B9A` |
| Background | `#FFF7FC` |
| Correcto piano | `#2E7D32` |
| Incorrecto | `#C62828` |
| Selección piano | `#FFB300` |
| Radio | 12px |
| Touch target | 48dp mínimo |

Copia local del design system: [stitch_harmonic_precision_DESIGN.md](stitch_harmonic_precision_DESIGN.md)

**Próximo paso Flutter:** mapear tokens → `app_theme.dart` + Google Fonts Hanken Grotesk; implementar pantallas siguiendo mockups por ruta.

---

## Cómo usar los zips

```powershell
# Oleada 1
Expand-Archive -Path stitch_togesc_design_system.zip -DestinationPath stitch_export/wave1 -Force

# Oleada 2
Expand-Archive -Path stitch_togesc_design_system_wave2.zip -DestinationPath stitch_export/wave2 -Force

# Ver un mockup
start stitch_export\wave2\*\game_session_premium_idle\screen.png
```

No commitear `stitch_export/` (está en `.gitignore`); los zips en raíz bastan como artefacto.

---

*Actualizado tras recepción de `stitch_togesc_design_system_wave2.zip` (jun 2026).*
