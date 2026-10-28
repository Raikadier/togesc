---
name: TOGESC v2 «La sesión como instrumento»
description: Design system de TOGESC. Es la evolución v2 de Harmonic Precision para entrenar el oído absoluto, con Material 3 y un tono académico.
version: 2.1
updated: 2026-10-28
source: docs/design_v2/SPEC_rediseno_v2.md
source_v2_1: docs/design_v2_1/SPEC_rediseno_v2_1.md
colors:
  # Claro (pantallas del shell)
  background: '#FFF7FC'
  surface: '#FFF7FC'
  surface-container: '#F3ECF1'        # chip, celda sin datos
  surface-container-lowest: '#FFFFFF' # panel/card
  outline-variant: '#D0C2D3'          # borde de card
  divider: '#EEE6EB'
  nav-bar: '#FFFDFE'
  text-primary: '#1E1B1E'
  text-secondary: '#4D4351'
  text-tertiary: '#726876'            # v2 pide #7F7383; oscurecido para AA
  primary: '#4E0078'
  primary-container: '#6A1B9A'
  hero: '#2A0640'                     # card hero de Home, «Pendientes», plan Pro
  on-hero: '#FFFFFF'
  on-hero-accent: '#DA9CFF'
  cta-amber: '#FFB300'
  on-cta-amber: '#2A0640'
  warning: '#FFB300'
  warning-light: '#FFC94D'
  on-warning: '#3A2B00'
  pro: '#9A25AE'
  correct: '#2E7D32'
  incorrect: '#C62828'
  selection: '#FFB300'
  speed-accent: '#BF360C'             # antes #E64A19 (no AA)
  speed-container: '#FFEBE6'
  # Oscuro de sesión (forzado en AppTheme.session)
  session-background: '#141018'
  session-surface: '#1A121E'          # teclado y panel SRS
  session-chip: '#241B2A'             # chips, divisor, borde del rail
  session-button: '#1E1622'
  session-border: '#3A2E42'
  session-border-subtle: '#2E2433'
  session-text-primary: '#ECE0E8'
  session-text-secondary: '#9C8FA3'
  session-text-label: '#CFC3CD'
  session-accent: '#DA9CFF'
  session-amber: '#FFD54F'
  session-success: '#81C784'
  session-error: '#EF9A9A'
  session-warning: '#FFC46B'
  speed-accent-on-dark: '#FF8A65'
  # Rejilla de dominio
  mastery-red: ['#FF8A8A', '#C62828']
  mastery-amber: ['#FFC94D', '#FFB300']
  mastery-green: ['#4E9A52', '#38853C', '#2E7D32']  # v2 pide #3B8C3F; oscurecido para AA
  mastery-empty: '#F3ECF1'
typography:
  font-family: Hanken Grotesk
  logo: { fontSize: 15px, fontWeight: '800', letterSpacing: 2.4px }
  overline: { fontSize: 12px, fontWeight: '700', letterSpacing: 1.5px, transform: uppercase }
  overline-lg: { fontSize: 13px, fontWeight: '700', letterSpacing: 1.6px, transform: uppercase }
  big-number: { fontSize: 44px, fontWeight: '800', letterSpacing: -1.32px, features: tnum }
  big-number-lg: { fontSize: 52px, fontWeight: '800', letterSpacing: -1.56px, features: tnum }
  headline-lg: { fontSize: 28px, fontWeight: '700', lineHeight: 36px }
  headline-md: { fontSize: 24px, fontWeight: '600', lineHeight: 32px }
  title-lg: { fontSize: 20px, fontWeight: '600', lineHeight: 28px }
  body-lg: { fontSize: 18px, fontWeight: '400', lineHeight: 26px }
  body-md: { fontSize: 16px, fontWeight: '400', lineHeight: 24px }
  label-lg: { fontSize: 14px, fontWeight: '500', lineHeight: 20px }
  label-md: { fontSize: 12px, fontWeight: '500', lineHeight: 16px }
rounded:
  cell: 12px      # celdas de nota, iconos en caja, botones estándar (radiusMd)
  card: 14px
  cta: 15px
  hero: 20px
  piano: 16px
  pill: 999px
sizes:
  app-bar: 56px
  nav-bar: 76px
  rail: 76px
  cta: 58px
  touch-target-min: 48px
  desktop-breakpoint: 1024px
  session-ring: 150px          # 170px en escritorio
  session-srs-panel: 300px
  piano-session: 230px         # 210px en escritorio (sessionWide)
  piano-black-key: 38x140      # 52x126 en escritorio
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 12px
  lg: 16px
  margin-mobile: 16px
  margin-desktop: 24px
motion:
  key-press: 90ms
  fast: 120ms
  medium: 280ms
  session-listen: 1500ms
  session-result: 2200ms        # 400ms con movimiento reducido; x2 con lector de pantalla
---

# TOGESC v2: la sesión como instrumento

**Fuente de verdad del diseño:** `docs/design_v2/SPEC_rediseno_v2.md` (Claude Design, sincronizado el 2026-09-10). Decisión del usuario del 2026-10-09: **v2 sustituye todo lo anterior**. Si este archivo choca con el spec, gana el spec y este archivo se corrige.

**Autoridad de implementación:**
- `TOGESC/togesc/lib/app/design_tokens.dart`: tokens, `masteryColor`, `masteryOnColor` y `contrastRatio`.
- `app_theme.dart`: temas `light`, `dark` y `session`.
- `togesc_colors.dart`: `ThemeExtension` con el feedback musical, la velocidad y los gradientes del piano.
- Los ratios de contraste los verifica `test/unit/design_tokens_v2_test.dart`. Ningún widget usa hex sueltos: se usan `DesignTokens`, `ColorScheme` o `TogescColors.of(context)`.

## v2.1: pulido

Aprobado el 2026-10-26 a partir del feedback del propietario sobre v2: se veía genérica y le faltaban movimiento, accesibilidad e intuición. **Lo que cambia está en `docs/design_v2_1/SPEC_rediseno_v2_1.md`**. Todo lo que el SPEC no menciona sigue como se describe en este archivo. La referencia visual es `docs/design_v2_1/prototype/`: sirve de referencia, no es código a portar.
- **Novedades:** el mapa del oído (`EarMapWheel`) y los tokens de movimiento, entre otras.
- **Restricciones que se mantienen:** Hanken Grotesk, la paleta v2, el tono académico, sin XP en el Home, un CTA dominante por pantalla y la sesión en oscuro.
- **Plan de implementación por lotes:** `Plan/hoja_ruta_rediseno_v2_1.md`. Progreso: `Plan/progreso_rediseno_v2_1.md`.
- Cuando un lote implementa un cambio del SPEC, la sección correspondiente de este archivo se actualiza en ese mismo lote.

### Movimiento y accesibilidad v2.1 (lote 1)
- **Tokens en `DesignTokens`:**
  - Curvas: `easeOut` `Cubic(.22, 1, .36, 1)` y `easeSpring` `Cubic(.34, 1.56, .64, 1)`.
  - Duraciones: `durationKey` 90 ms, `durationFast` 120 ms y `durationMedium` 280 ms (alias de los `motion*` de v2).
  - Escalonado: `staggerStep` 60 ms y `staggerWheel` 45 ms.
- **`motionDuration(context, d)`:** cualquier animación nueva pasa su duración por aquí. Devuelve `Duration.zero` si `MediaQuery.disableAnimations` está activo, y `TogescApp` ya vuelca ahí `reduceAnimations`.
- **Mapa del oído:**
  - Medidas: `earMapInner` 64 y `earMapOuter` 126 (compacta: 70 y 132), sobre un viewBox de 320.
  - Pista: `TogescColors.earMapTrack` (#F3ECF1 en claro, #241B2A en oscuro y sesión) y `earMapTrackOnHero` (blanco al 8 %).
- **Texto más grande:** `UiPreferences.largeText` aplica ×1,125 encima del escalado del sistema (`applyLargeText`, en `lib/app/large_text_scaler.dart`).

### Componentes compartidos v2.1 (lote 2)
- **`EarMapWheel`** (`lib/widgets/ear_map/`): mapa del oído del SPEC §1.1. Tab va en orden cromático, Enter o Espacio activan, y cada segmento tiene `Semantics`. Variantes `onDark` y `compact`.
- **`CountUpText`** y **`StaggeredEntrance`**: el conteo de números grandes y la entrada escalonada de bloques.
- **`PianoKeyboard` de sesión:** hundimiento de 2 px, onda #DA9CFF, pop y shake en el resultado, icono ✓/✗ con spring y `large` («Piano más grande»: 270/44×160 en móvil, 250/58×150 en escritorio).
- **`SessionPhaseRing`:** arco de `listen` de 1,5 s y halo de `result` de 1,2 s.
- Todos respetan `motionDuration`.

### Home v2.1 (lote 3)
- **Hero:** punto pulsante (dos pulsos y quieto, por WCAG 2.2.2), estado en texto en las mini-cards y los 3 pasos «Escucha / Toca la tecla / El SRS ajusta tu repaso». «Ajustar enfoque y duración» abre una hoja: 6, 12 o 20 rondas y de 1 a 4 notas foco, solo para hoy.
- **Mapa del oído:** precisión global en el centro, leyenda, meta de octava (N de 12 con ≥ 75 %) y fila de detalle con «Practicar».
- **Últimos 7 días:** hoy se rotula «HOY» y, si está pendiente, lleva borde discontinuo. Debajo, la frase de racha.
- **Escritorio:** dos columnas (1,25 / 1). La derecha queda fija porque cada columna tiene su propio scroll.

### Sesión v2.1 (lote 4)
- **«Preparado» siempre al entrar:** auriculares, rondas, notas y foco reales, «Estoy listo» (también con Espacio) y «Probar el sonido». El teclado aparece al empezar. Sustituye al idle mínimo de v2 (D4): el gesto lo da siempre «Estoy listo».
- **Resultado:** «¡N seguidas!» desde 3 aciertos seguidos.
- **Pausa:** botón, Esc o volver abren «Sesión en pausa» (Continuar, Reiniciar la sesión, Salir sin guardar). El cronómetro se detiene.
- **Instrumento:** hoja con la rejilla de timbres y una preescucha.
- **Resumen** al cumplir la meta: medalla, precisión, aciertos, tiempo medio medido, cambios de nivel SRS frente a la instantánea del inicio y la rueda actualizada.
- **Escritorio:** el panel SRS resalta la nota de la ronda solo en el resultado.

### Progreso v2.1 (lote 5)
- **Pestañas «Resumen | Historial»:** semántica de pestañas y flechas ← →.
- **Resumen:**
  - La precisión global cuenta al cargar y la meta lleva degradado.
  - «Pendientes» abre la sesión de hoy.
  - Dominio por nota: rueda o rejilla en móvil (rueda por defecto) y las dos lado a lado en escritorio. Icono `schedule` en las vencidas.
  - «Tus extremos» (Pro) y últimas sesiones.
- **Detalle de nota:** hoja con celda de 88 px, precisión, intentos, latencia, nivel 1–5, una frase por estado, «Escuchar» y «Practicar esta nota».
- **Historial (Pro):** barras rellenas de precisión por sesión (verde a partir del 75 %) con texto alternativo, evolución por periodo, exportación y lista completa.

### Velocidad v2.1 (lote 6)
- **Selección:**
  - Las dificultades Fácil, Pro y Elite son tarjetas radio con un cuadro de segundos de 64 px y la mejor racha guardada («—» si no hay).
  - Después vienen los modos («Teclas negras» sigue como card `hero`) y «Cómo funciona», con 3 pasos que salen de las constantes de juego.
- **Juego (oscuro):**
  - Cuenta atrás 3-2-1 con pop y un clic sutil.
  - Anillo de 168 px en #FF8A65 que pasa a #EF9A9A, con «¡Rápido!» y latido, cuando queda menos de 2 s o menos del 30 % del límite.
  - Destello verde o rojo en cada respuesta.
  - Sin latido ni destello con movimiento reducido.
- **Resumen:** píldora «Nuevo récord personal», KPI 2×2 (Racha final, Mejor tiempo, Promedio y Respuestas) y los botones «Reintentar» (#FF8A65 con texto #2A0640) y «Menú».

### Perfil, paywall, onboarding y ajustes v2.1 (lote 7)
- **Perfil:**
  - Cabecera con avatar de 64 px. Sin cuenta: «Entrenando sin cuenta · Tu progreso vive en este dispositivo» y «Entrar o crear cuenta». Con cuenta: el email.
  - «Tu oído en cifras»: racha, notas consolidadas N/12 y sesiones. Solo datos reales.
  - Card `hero` del plan con «Plan actual», los 3 beneficios y un botón blanco (#FFFFFF sobre #2A0640).
  - Estado de sincronización con icono y texto. El ámbar pendiente usa `selectionDeep` en claro.
  - Notación y recordatorios como interruptores en línea, y «Exportar mi progreso (JSON)».
  - El acceso es una hoja con selector Entrar / Crear cuenta y errores en línea (icono + región viva). Borrar la cuenta también se confirma en una hoja.
- **Paywall:**
  - Fondo `hero` a pantalla completa: pitch con los 3 beneficios a la izquierda y panel claro «Gratis o Pro» a la derecha (debajo en móvil).
  - Tabla con check o guion por celda y una frase accesible por fila.
  - CTA ámbar de prueba. Sin precios: el precio lo muestra la tienda.
  - Texto secundario sobre `hero`: `onHeroMuted` #E9DDF0 (13,4:1).
- **Onboarding:**
  - 4 pasos con indicador de puntos («Paso N de 4») y «Saltar».
  - Paso 1: ecualizador de 3 ciclos, quieto con movimiento reducido.
  - Paso 2: el bento «Cómo funciona».
  - Paso 3: ronda de prueba con La 440 Hz y piano oscuro.
  - Paso 4: notación, «Reducir animaciones» y «Texto más grande».
  - El paso actual se guarda.
- **Ajustes:**
  - 5 grupos en cards: accesibilidad primero, luego sesión, sonido, apariencia y «Más». En escritorio van en 2 columnas.
  - La vista previa del piano refleja al momento piano grande, etiquetas y notación.
  - Rejilla de timbres con preescucha y volumen con su valor en %.
  - «Restablecer ajustes» se confirma en una hoja.

## Qué cambió de v2 a v2.1 (cierre, lote 8)

| Punto de v2 | Estado en v2.1 |
|---|---|
| Paleta, Hanken Grotesk, radios, sesión oscura, sin XP en el Home y un CTA dominante | **Vigente** |
| Rejilla de dominio con el % visible | **Vigente**. Convive con el mapa del oído (`EarMapWheel`): rueda por defecto en móvil y las dos en escritorio |
| Duraciones `motion*` sueltas | **Sustituido** por los tokens de movimiento y `motionDuration` (lote 1); `motion*` quedan como alias |
| Idle mínimo de la sesión (D4) | **Sustituido** por «Preparado» con «Estoy listo» (lote 4) |
| Sesión sin pausa | **Sustituido** por la pausa con Esc o volver (lote 4) |
| Home con hero y rejilla de 12 | **Sustituido** por el hero con 3 pasos y hoja de ajuste, el mapa del oído y los últimos 7 días (lote 3) |
| Progreso en una sola vista | **Sustituido** por las pestañas «Resumen \| Historial» y la hoja de detalle de nota (lote 5) |
| Velocidad con la estructura de v1 | **Sustituido** por las tarjetas de dificultad, la cuenta atrás y el anillo de 168 px (lote 6) |
| Paywall, cuenta, onboarding y ajustes «con tokens v2 y la estructura antigua» | **Sustituido** por el rediseño del lote 7. La sección «Pantallas fuera de v2» queda solo como historia |
| Onboarding de una pantalla | **Sustituido** por 4 pasos con el paso guardado (lote 7) |
| Confirmaciones en diálogo (borrar cuenta, restablecer) | **Sustituido** por hojas inferiores (lote 7) |
| Contraste comprobado por pares de tokens (`design_tokens_v2_test.dart`) | **Vigente**, y se suma la auditoría de cada texto e icono de cada pantalla frente a su fondo real (`test/helpers/contrast_audit.dart`, en `dark_theme_v2_test.dart`) |

## Qué queda de Harmonic Precision

| Elemento | Estado |
|---|---|
| Hanken Grotesk como única fuente | **Vigente** |
| Púrpura #4E0078 / #6A1B9A, fondo cálido #FFF7FC | **Vigente** |
| Semántica musical: verde correcto, rojo incorrecto, ámbar de selección | **Vigente** (en la sesión, con las variantes claras #81C784 / #EF9A9A / #FFD54F) |
| Jerarquía por capas tonales y bordes de 1 px, sin sombras pesadas | **Vigente** |
| Objetivos táctiles de 48×48, copy en español con ortografía completa | **Vigente** |
| Respetar `reduceAnimations` / Reduce Motion | **Vigente** |
| Radio único de 12 px en todo | **Sustituido** por la escala cell 12 / card 14 / CTA 15 / hero 20 / pill. `radiusXl` (16) se borró en el lote 3 |
| `outline` #7F7383 como texto | **Sustituido** por #726876 (AA) |
| Home con rejilla de 6 modos | **Sustituido** por «una sola decisión» (sesión de hoy) |
| Sesión en tema claro con card de resultado y segundo teclado | **Sustituido** por la sesión oscura con el feedback sobre la tecla |
| Nav adaptativa a partir de 600 px con pestaña Pro | **Sustituido** por la barra inferior de 4 destinos y el rail a partir de 1024 px. Pro se abre desde Perfil y desde los candados |
| Piano clásico (`pianoWhite` / `pianoBlack`) | **Residual:** solo lo usa `PianoKeyboardVariant.classic`, que ya no monta ninguna pantalla. Sesión y velocidad usan la variante `session` |
| Gradiente de velocidad y gradiente Pro | **Borrados** (sin uso) |

## Tres principios de v2

1. **Una decisión por pantalla.** El Home propone la sesión de hoy (12 rondas, unos 6 min estimados y 3 notas foco). Todo lo demás es secundario.
2. **La sesión es un instrumento.** La práctica se hace en oscuro y el teclado es el protagonista. El resultado aparece **sobre la tecla**, no en una card aparte, y se responde con un solo toque.
3. **El progreso se lee de un vistazo.** Una rejilla de 12 notas coloreadas por dominio, siempre con el % visible.

## Color

### Claro (pantallas del shell)
- Fondo #FFF7FC, panel #FFFFFF con borde #D0C2D3 y chip #F3ECF1.
- Texto: principal #1E1B1E (16,2:1), secundario #4D4351 (8,9:1) y terciario #726876 (5,0:1).
- **Hero #2A0640.** Se usa en la card de Home, en el KPI «Pendientes», en el plan Pro, en la insignia de cuenta y en la card «Teclas negras» de velocidad. Encima va texto blanco (17,5:1) o el acento #DA9CFF (8,5:1).
- **CTA ámbar #FFB300.** El texto siempre va en #2A0640 (9,8:1); nunca en blanco (1,8:1).
- **PRO #9A25AE.** Es la marca de la insignia, con texto blanco (6,5:1).
- **Velocidad #BF360C** sobre el contenedor #FFEBE6. Es el mismo tono que el #E64A19 anterior, más profundo para llegar a AA: 5,6:1 con blanco encima y 4,9:1 sobre el contenedor. `TogescColors.onSpeedAccent` da el color del texto sobre el relleno.

### Oscuro de sesión (`AppTheme.session`)
Se fuerza en la sesión (`game_screen`) y en la sesión de velocidad (`speed_game_screen`), sea cual sea la preferencia de tema del usuario.
- Fondo #141018, superficie #1A121E (teclado y panel SRS), chip #241B2A y botón #1E1622 con borde #3A2E42.
- Texto: principal #ECE0E8 (14,7:1), secundario #9C8FA3 (6,2:1) y etiqueta #CFC3CD (11,1:1).
- **Color de cada fase:**
  - Escuchando: acento #DA9CFF.
  - Responde: ámbar #FFD54F.
  - Correcto: #81C784.
  - Incorrecto: #EF9A9A.
- Velocidad en oscuro: #FF8A65 (8,1:1), con #2A0640 encima.
- En este tema `outline` / `outlineVariant` son **bordes**. Nunca se usan como color de texto.

### Tema oscuro de la app (`AppTheme.dark`)
Sigue disponible como preferencia para las pantallas del shell, con los tokens `dark*` y `TogescColors.dark`. Lo que debe verse igual en los dos temas (hero, PRO, plan Pro) usa los tokens fijos `hero`/`onHero`, no `primaryContainer`/`onPrimary`: en oscuro esa pareja daba morado sobre morado.

## Rejilla de dominio
- Umbrales: **< 50 % rojo**, **50–74 % ámbar** y **≥ 75 % verde**. Dentro del verde, el tono depende del nivel SRS: ≤ 3 → #4E9A52, 4 → #38853C y 5 → #2E7D32.
- `masteryColor(pct, srsLevel:)` da el fondo y `masteryOnColor` el texto AA:
  - #1E1B1E sobre rojo claro y verde claro.
  - #3A2B00 sobre los ámbar.
  - Blanco sobre rojo, verde medio y verde profundo.
- Una nota nunca vista es «—» sobre #F3ECF1.
- **A11y:** el color nunca es la única señal. El % siempre está visible y la leyenda lleva los rangos en texto. Cada celda tiene su Semantics («A sostenido, 42 %, crítica, nivel 1 de 5»).
- La misma escala se aplica a la semana L–D del Home (verde cumplido, ámbar parcial, rojo fallado y #F3ECF1 sin práctica), siempre con un icono además del color.
- Barras sobre fondo oscuro (`masteryBarColorOnDark`): #FF8A8A, #FFC46B y #81C784.

## Tipografía
- **Hanken Grotesk** en todos los textos.
- **Logo** 15/800 con letter-spacing 2,4 (`DesignTokens.logo`).
- **Overline** 12/700 con ls 1,5, o 13/700 con ls 1,6. Va en mayúsculas mediante `.toUpperCase()`, porque Flutter no tiene `text-transform`. Se usa en las cabeceras de sección, la fase de la sesión, las etiquetas de métricas y las insignias.
- **Números grandes** 44/800 y 52/800 con letter-spacing negativo y **cifras tabulares**.
- Cualquier número que cambie en pantalla (chips «3 / 12», «78 %», tiempos de velocidad, contadores) lleva `DesignTokens.tabularNumbers` para que no baile.

## Forma y medidas
- Radios: celda 12, card 14 (también en `cardTheme`), CTA 15, hero 20, teclado 16 y chips/píldoras 999.
- App bar de 56, barra inferior de 76, rail de 76, CTA de 58 y objetivo táctil mínimo de 48. Las teclas negras de la sesión miden 38 de ancho, pero su zona táctil es de 48.

## La sesión (1b móvil / 1d escritorio)
- **Máquina de estados:** `listen` (mínimo 1,5 s) → `answer` → toque → `result` (2,2 s) → siguiente ronda.
  - Con movimiento reducido, el resultado dura 400 ms.
  - Con lector de pantalla, el tiempo se duplica para que dé tiempo a oír el anuncio.
  - En Ajustes se pueden reactivar «Confirmar» y el avance manual.
- **Barra superior:** volver, chips «ronda / 12», «✓ %» y «⚡ racha», y pausa. Debajo, la barra de progreso de 3 px en #DA9CFF.
- **Anillo de fase:** 150 px (170 px en escritorio). En `listen` muestra 5 barras animadas, que respetan el movimiento reducido. Encima del anillo, la píldora SRS «nota SRS 3/5 → 4/5».
- **Teclado:**
  - Móvil: 230 de alto, sobre un contenedor #1A121E con radio 16.
  - Escritorio: 210 de alto, con negras de 52×126.
  - Feedback sobre la tecla: correcta en verde y errónea en rojo, con un icono ✓/✗ además del color. El resto de teclas se atenúa.
  - Selección múltiple (velocidad, acordes): borde ámbar de 3 px.
- **Escritorio (≥ 1024):** a la derecha, el panel «Enfoque SRS de la sesión» (300 px) con los estados Crítica / En curso / Consolidando y los atajos al pie.
- **Velocidad:** hereda el mismo tema oscuro y la variante `session` del teclado, y conserva su propio flujo (countdown, confirmar y entrada de texto).

## Navegación
- **Por debajo de 1024:** barra inferior de 76 con Práctica / Progreso / Velocidad / Perfil.
  - El destino activo va en `primary`, con icono relleno y en negrita.
  - Los inactivos van con icono de contorno en `textSecondary`.
- **A partir de 1024:** rail de 76 con «TG» y 4 destinos de 48 que solo muestran el icono, cada uno con tooltip y Semantics.
  - El activo lleva fondo `hero` e icono #DA9CFF (8,5:1).
  - Se recorre con Tab y se activa con Enter o Espacio.
- La sesión (`/game/:id`, `/speed/game/:id`) se abre a pantalla completa, sin barra ni rail.

## Atajos de teclado (sesión)
| Tecla | Acción |
|---|---|
| `A`–`G` | Responder esa nota |
| `⇧` + letra | Sostenido (se ignoran ⇧E y ⇧B) |
| `R` | Repetir la misma ronda |
| `Espacio` | Siguiente ronda o saltar |

- Se ignoran si se pulsa Ctrl, Alt o Meta, para no pisar Ctrl+R, y cuando un campo de texto tiene el foco.
- Espacio solo actúa si ningún control tiene el foco: una tecla del piano enfocada consume su propio Enter/Espacio.

## Accesibilidad (WCAG 2.2 AA)
- **Contraste:** `auditContrast` (`test/helpers/contrast_audit.dart`) recorre en los tests cada texto e icono frente a su fondo real. Los controles desactivados y los iconos decorativos dentro de `ExcludeSemantics` quedan exentos, pero la explicación de un control desactivado («Disponible en Android e iOS.») lleva color AA explícito. El texto normal llega a 4,5:1 y los iconos y bordes informativos a 3:1. Cuando el spec daba un valor por debajo, el token se oscureció manteniendo el tono, y el valor original queda documentado en el código: `outline`, el verde medio y el acento de velocidad. Nada de texto con opacidad reducida: para el texto terciario se usa `outline`.
- **El color nunca es la única señal:**
  - Rejilla: % visible.
  - Semana: icono por estado.
  - Teclas: ✓/✗.
  - Estado de sync: icono y texto.
- **Regiones vivas:** el resultado de la ronda va en `Semantics(liveRegion)`. En iOS y escritorio se anuncia además con `SemanticsService`.
- **Objetivos táctiles** de 48 o más, foco visible y orden de foco lógico.
- **Movimiento:** se respetan `reduceAnimations` y `disableAnimations` en barras, transiciones y pulsos.
- **Lector de pantalla:** cada tecla del piano tiene su Semantics («C sostenido, correcta»), y las cabeceras de sección se marcan con `header: true`.

## Pantallas fuera de v2 (**Sustituido** en v2.1)
Esta sección describe el estado de v2. En v2.1 el lote 7 rediseñó paywall, cuenta (Perfil), onboarding y ajustes. Siguen con la estructura de v2 suscripción, acerca de y privacidad.

Onboarding, velocidad, paywall, suscripción, ajustes, acerca de, privacidad y cuenta **adoptan los tokens de v2 sin cambiar de estructura** (lote 3). Eso cubre:
- Radios card, hero, CTA y píldora.
- Cabeceras en overline.
- Pro y la insignia de cuenta sobre `hero`/`pro`.
- Cifras tabulares en las métricas de velocidad.
- Las mismas reglas de contraste AA.

El paywall y la cuenta ya están rediseñados (lote 7). La versión clara de la sesión y el Home sin card oscura siguen pendientes.

## Hacer y no hacer
**Hacer**
- Leer los colores de `DesignTokens`, `ColorScheme` o `TogescColors.of(context)`.
- Usar un único CTA dominante por pantalla.
- Dar a cada número que cambia cifras tabulares, y a cada estado de color un texto o un icono.
- Pasar los ratios nuevos por `contrastRatio` y añadirlos al test de tokens.

**No hacer**
- Escribir hex sueltos en los widgets o usar `primaryContainer` como color de texto o icono, porque en la sesión es #2A0640.
- Poner texto blanco sobre ámbar o sobre verde claro.
- Volver a poner una card de resultado o un segundo teclado en la sesión.
- Añadir `@Deprecated` a tokens que siguen en uso: `flutter analyze` del CI trata los avisos info como fatales.
- Inventar métricas que no existen (D10): el copy se ajusta a los datos reales.
