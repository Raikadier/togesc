---
name: Harmonic Precision
description: Design system de TOGESC — entrenamiento de oído absoluto, Material 3, tono académico.
colors:
  background: '#FFF7FC'
  on-background: '#1E1B1E'
  surface: '#FFF7FC'
  on-surface: '#1E1B1E'
  on-surface-variant: '#4D4351'
  surface-container-low: '#F9F1F6'
  surface-container: '#F3ECF1'
  surface-container-high: '#EEE6EB'
  surface-container-highest: '#E8E0E5'
  surface-container-lowest: '#FFFFFF'
  outline: '#7F7383'
  outline-variant: '#D0C2D3'
  primary: '#4E0078'
  on-primary: '#FFFFFF'
  primary-container: '#6A1B9A'
  on-primary-container: '#DA9CFF'
  secondary: '#9A25AE'
  on-secondary: '#FFFFFF'
  secondary-container: '#ED76FD'
  on-secondary-container: '#69007A'
  tertiary: '#402747'
  on-tertiary: '#FFFFFF'
  tertiary-container: '#573D5F'
  on-tertiary-container: '#CBAAD2'
  error: '#BA1A1A'
  on-error: '#FFFFFF'
  error-container: '#FFDAD6'
  on-error-container: '#93000A'
  correct: '#2E7D32'
  incorrect: '#C62828'
  selection: '#FFB300'
  piano-white: '#FFFFFF'
  piano-black: '#212121'
  dark-background: '#141018'
  dark-on-background: '#ECE0E8'
  dark-surface: '#141018'
  dark-primary: '#DA9CFF'
  dark-primary-container: '#6A1B9A'
typography:
  font-family: Hanken Grotesk
  headline-lg:
    fontFamily: Hanken Grotesk
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: '-0.02em'
  headline-lg-mobile:
    fontFamily: Hanken Grotesk
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
  headline-md:
    fontFamily: Hanken Grotesk
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  title-lg:
    fontFamily: Hanken Grotesk
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Hanken Grotesk
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 26px
  body-md:
    fontFamily: Hanken Grotesk
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-lg:
    fontFamily: Hanken Grotesk
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
  label-md:
    fontFamily: Hanken Grotesk
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 4px
  md: 12px
  xl: 16px
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 12px
  lg: 16px
  margin-mobile: 16px
  margin-desktop: 24px
  touch-target-min: 48px
  shell-breakpoint: 600px
  content-max-width: 1200px
components:
  button-primary:
    backgroundColor: '{colors.primary-container}'
    textColor: '{colors.on-primary}'
    rounded: '{rounded.md}'
    height: 48px
  button-secondary:
    backgroundColor: '{colors.surface-container-lowest}'
    textColor: '{colors.primary}'
    rounded: '{rounded.md}'
    height: 48px
  card:
    backgroundColor: '{colors.surface-container-lowest}'
    rounded: '{rounded.md}'
    padding: 16px
---

## Overview

**Harmonic Precision** es el design system de TOGESC: educativo, limpio y profesional. Prioriza claridad cognitiva durante el entrenamiento auditivo frente a gamificación ruidosa. Inspiración Material 3: capas tonales, outlines suaves, movimiento con propósito.

**Autoridad de implementación:** `TOGESC/togesc/lib/app/design_tokens.dart` + `app_theme.dart` (+ extensión `TogescColors`).  
**Autoridad de brief:** `Plan/stitch_harmonic_precision_DESIGN.md` y mockups en `.tmp_stitch/stitch_togesc_design_system/`.  
**Modo de superficie por defecto (app):** Operate. Landing/marketing (si existe) es Persuade y no inventa claims no respaldadas.

Este archivo es el **DESIGN.md canónico** del repo (S0 Impeccable, 2026-07-26). Refinar UI = alinear Flutter a esta identidad; no sustituir el mundo visual sin mandato explícito.

## Colors

Paleta anclada en púrpura musical (`primary-container` `#6A1B9A`, `primary` `#4E0078`) sobre fondo cálido desaturado `#FFF7FC`.

- **Primary / containers:** acciones clave, branding, progreso.
- **Correct / Incorrect / Selection:** feedback de piano y resultados (verde / rojo / ámbar). No sustituir por primary genérico.
- **Piano:** `piano-white` / `piano-black` para mapeo tradicional; overlays semánticos encima.
- **Dark:** tokens `dark-*` y `TogescColors.dark` son first-class; evitar `DesignTokens.incorrect` u otros estáticos light en widgets dark.

Jerarquía por **capas tonales** y `outlineVariant` 1px, no por sombras pesadas tipo “premium glow”.

## Typography

**Hanken Grotesk** exclusiva (vía `google_fonts` en `AppTheme`).

- Headlines: ancla de pantalla; tracking ligeramente negativo en lg.
- Body: lectura de instrucciones y pedagogía.
- Labels: botones, chips, nav.
- Nombres de nota (C#, Do…): elevar a title/headline para que sean el foco en sesión.

UI copy siempre en **español con ortografía completa**.

## Layout

Móvil primero; reflow fluido.

- **&lt;600px:** una columna; márgenes 16px; piano usable con scroll/ancho prioritario.
- **≥600px (`shellBreakpoint`):** shell con nav adaptativa; márgenes 24px.
- **Contenido:** centrar interacción primaria con `contentMaxWidth` 1200px (`TogescPageBody` u equivalente) en **todas** las rutas relevantes, no solo home/stats.
- Ritmo: baseline 4px; gaps típicos 12–16px.
- Touch: mínimo **48×48** en todo control interactivo.

## Elevation & Depth

Estética “partitura”: separación por tintes de superficie y bordes 1px `outlineVariant`. Sombras solo en hojas temporales (sheets, snackbars), suaves y de baja opacidad. Estado activo: borde 2px ámbar (`selection`) preferible a elevación.

## Shapes

Radio canónico **12px** (`radiusMd`) en botones, cards y modales. Chips: 12px o pill. Teclas del piano: base casi afilada (0–4px) dentro de contenedor 12px.

## Components

- **Botón primary:** filled primary-container, texto on-primary, min-height 48.
- **Botón secondary:** outlined / surface, texto primary.
- **Piano:** componente crítico; Semantics + targets ≥48; selection ámbar; feedback verde/rojo.
- **Cards (SRS / resultado):** outline 1px, padding 16px; metadatos SRS en label-md.
- **Input notas:** Outlined M3, radio 12px.
- **Mode cards / bento:** affordances visibles **sin depender de hover** (móvil first).
- **Progress:** linear fino, primary sobre track terciario suave.

## Do's and Don'ts

**Do**
- Preservar Harmonic Precision y tokens semánticos musicales.
- Una jerarquía clara hacia “practicar ahora” en Operate.
- Copy ES correcto; feedback de resultado legible en light y dark.
- Respetar `reduceAnimations` / Reduce Motion en todos los motion paths.
- Usar `ColorScheme` / `TogescColors.of(context)` en widgets, no hex sueltos.

**Don't**
- Introducir un segundo design system o “rediseño purple glow” que contradiga capas tonales.
- Sobrecargar el Home con &gt;4 decisiones simultáneas sin progressive disclosure.
- Mezclar inglés de UI (`Go Premium`, `FEEDBACK`) sin decisión de marca.
- Fabricar métricas sociales o rankings en analytics si el producto no los tiene.
- Tratar Stitch PNG como licencia para gamificación arcade si el brief académico lo prohíbe — Stitch informa layout; el brief de tono gana en conflicto.
