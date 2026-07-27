# UI/UX y accesibilidad

> **Actualización 2026-07-26:** UX-001 (tokens dark semánticos) y A11Y-002
> parcial (piano + cluster) cerrados en código. Pendiente contraste medido,
> Lighthouse y motion residual:
> [11_estado_pendiente_2026-07-26.md](11_estado_pendiente_2026-07-26.md).

Estándares: WCAG 2.2 AA, WAI-ARIA, Material Design 3, NN/g, leyes de Fitts/Hick (qstd §1, §2.4, §11.6).

> **Nota 2026-07-24:** A11Y-001 quedó corregido después de la
> auditoría original. El piano actual incluye Semantics, foco, teclado,
> indicadores ✓/✗ y área táctil negra de 48 dp.

## Lo que está bien (no tocar)
- Design system "Harmonic Precision" centralizado en [`design_tokens.dart`](../../TOGESC/togesc/lib/app/design_tokens.dart) + tema claro/oscuro.
- `touchTargetMin = 48` definido y aplicado al área táctil del piano.
- Feedback táctil de tecla en 80 ms ([`piano_keyboard.dart:130`](../../TOGESC/togesc/lib/widgets/piano_keyboard.dart#L130)) — dentro del rango de microfeedback.
- Espaciado en escala de 4/8 px; radios y breakpoints tokenizados.

---

## A11Y-001 — Accesibilidad del piano — CORREGIDO

- **Severidad:** ALTO · **Esfuerzo:** M · **Prioridad:** P0
- **Evidencia:** [`piano_keyboard.dart`](../../TOGESC/togesc/lib/widgets/piano_keyboard.dart) completo.
- **Estándar:** WCAG 2.2 AA — 1.4.1 (uso del color), 2.5.8 (tamaño de objetivo), 4.1.2 (nombre/rol/valor); WAI-ARIA.

### Estado actual

El widget implementa nombre/rol/estado semántico, interacción por
Enter/Espacio, foco visible e indicadores no cromáticos. Los tests widget
comprueban rol de botón y hints de resultado.

### Criterios de aceptación
- [x] Semantics anuncia nombre, selección y resultado.
- [x] Estado correcto/incorrecto incluye icono.
- [x] Área táctil de teclas negras ≥48dp.
- [x] Navegable por teclado y con foco.
- [ ] Lighthouse accesibilidad ≥ 90.

---

## UX-001 — Tokens de tema oscuro incompletos — CORREGIDO (2026-07-24)

- **Severidad:** MEDIO · **Esfuerzo:** S · **Prioridad:** P1
- **Evidencia:** [`togesc_colors.dart`](../../TOGESC/togesc/lib/app/togesc_colors.dart) + registro en [`app_theme.dart`](../../TOGESC/togesc/lib/app/app_theme.dart).
- **Estándar:** Material Design 3 (roles semánticos completos), WCAG AA contraste.

### Estado actual
Los colores de feedback musical y modo velocidad viven en el
`ThemeExtension` `TogescColors` (light/dark). Piano, resultados, countdown,
SRS indicator, chips de error y acentos de velocidad resuelven vía
`TogescColors.of(context)`. El hub/stats usan `TogescPageBody` con
`contentMaxWidth = 1200` y `marginDesktop = 24`.

### Criterios de aceptación
- [x] Colores semánticos tienen variante oscura (`correct`, `incorrect`,
  `selection`, `speed*`, contenedores).
- [ ] Captura del piano en modo oscuro muestra feedback legible (manual).
- [ ] Contraste medido con herramienta (pendiente).

---

## Observaciones de UX (estilo / no bloqueantes)
- **Estados loading**: `ProRouteGuard` y otros usan `CircularProgressIndicator` centrado; qstd §11.7 recomienda skeletons para datos locales (que son instantáneos) — evitar spinner para estado que en realidad no carga.
- **Heurística NN/g #1 (visibilidad de estado)**: el panel de diagnóstico de sync y banners offline existen (`sync_diagnostics_card`, `auth_sync_listener`) — bien.
- **Consistencia (#4)**: verificar que los 7 estados de Game y 7 de Speed usen las mismas transiciones (fade through, ver [08_performance_motion.md](08_performance_motion.md)).

## Pendiente de verificar
- Contraste real de cada par token/fondo con herramienta (no auditado pixel a pixel).
- Recorrido de usabilidad / card sorting (qstd §1.4) — no hay evidencia de pruebas con usuarios.
