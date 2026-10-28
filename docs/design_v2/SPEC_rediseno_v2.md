# Especificación — Rediseño v2 «La sesión como instrumento»

Fuente: Claude Design, proyecto `4511c73b-8a4b-49e5-a509-4163d13dfe25`, archivo `TOGESC - Rediseño.dc.html` (sincronizado el 2026-09-10). Esta ficha extrae del HTML todo lo que se puede implementar; el HTML original se lee con DesignSync (`get_file`).
Decisión del usuario (2026-10-09): **v2 reemplaza todo**. Si choca con `DESIGN.md` u otra decisión de diseño anterior, gana v2, y `DESIGN.md` se actualiza.

## Tres cambios de fondo
1. El Home propone **una sola decisión** (sesión de hoy) en vez de seis.
2. La sesión pasa a **modo interpretación en oscuro**. El teclado es el protagonista y el feedback aparece **sobre la misma tecla**. Desaparecen la card de resultado (`result_card.dart`) y el segundo teclado duplicado.
3. Las estadísticas se resumen en una **rejilla de 12 notas** legible de un vistazo.

Se mantienen la paleta y la tipografía Harmonic Precision: Hanken Grotesk, púrpura #4E0078/#6A1B9A, ámbar de selección y verde/rojo de feedback. Iconos: Material Symbols Rounded, rellenos (FILL 1); la variante `o` usa FILL 0 (contorno).

## Tokens nuevos o confirmados
| Uso | Claro | Oscuro (sesión) |
|---|---|---|
| Fondo | #FFF7FC | #141018 |
| Superficie / chip | #F3ECF1 | #241B2A |
| Superficie de panel | #FFFFFF (borde #D0C2D3) | #1A121E (borde #3A2E42 / #2E2433) |
| Botón secundario | — | #1E1622, borde #3A2E42 |
| Texto principal | #1E1B1E | #ECE0E8 |
| Texto secundario | #4D4351 | #9C8FA3 |
| Texto terciario / etiquetas | #7F7383 | #CFC3CD |
| Divisor | #EEE6EB | #241B2A |
| Primario | #4E0078 | acento #DA9CFF |
| Hero oscuro (card de Home y «Pendientes») | #2A0640 | — |
| CTA ámbar | #FFB300, texto #2A0640 | ámbar de fase #FFD54F |
| Éxito | #2E7D32 (escala #3B8C3F, #4E9A52) | #81C784 |
| Error | #C62828 | #EF9A9A |
| Aviso | #FFB300 / #FFC94D (texto #3A2B00) | #FFC46B |
| PRO | #9A25AE | — |
| Barra de nav. inferior | #FFFDFE, borde superior #EEE6EB | rail 76px, borde #241B2A |

Radios: card hero 20, cards 14, celdas de nota 12, CTA 15, chips 999. Tipografía: logo 15/800 con letter-spacing 2.4; overline 12–13/700, mayúsculas, letter-spacing 1.4–1.6; números grandes 44–52/800 con letter-spacing negativo y `tabular-nums`.

## 1a — Home: una sola decisión (móvil 390×844)
- App bar de 56: «TOGESC» en #4E0078; chip de racha (icono fuego #FFB300 y número); avatar de 32 (fondo rgba(106,27,154,.15)).
- Fecha como overline: «Jueves 10 de septiembre».
- **Card hero #2A0640** con la marca de agua `graphic_eq` de 150px:
  - Overline «Sesión de hoy» (#DA9CFF); «12» a 44/800 seguido de «rondas · 6 min».
  - Texto: «El SRS priorizó tres notas que perdieron precisión esta semana.»
  - 3 mini-cards de las notas foco (nombre, barra de precisión de 3px y %). Color de barra: <50 → #FF8A8A, 50–74 → #FFC46B.
  - CTA de 58 en ámbar «▶ Empezar sesión»; debajo, el enlace «Ajustar enfoque y duración».
- Fila «Retomar «Una sola nota»» con borde discontinuo, «8 rondas · hace 2 h» y chevron.
- Sección «Práctica libre» con «Ver todos»: 3 tiles (Una nota, Intervalo y Acorde con PRO y candado). Cada tile lleva una barra de progreso y «86% · 24 ses.».
- Sección «Esta semana · 5 de 7 días»: 7 celdas de 44 de alto (L–D). Colores: verde = cumplido, ámbar = parcial, rojo = fallado, #F3ECF1 = sin práctica.
- Nav inferior de 76 con Práctica / Progreso / Velocidad / Perfil. El destino activo se pinta en #4E0078, relleno y en negrita.

## 1b — Sesión interactiva, oscura (móvil)
Máquina de estados: `listen` (1,5 s) → `answer` → (tap) → `result` (2,2 s) → siguiente ronda.
- Barra superior: volver, chips «{ronda} / 12», «✓ {precisión}%», «⚡ {racha}» y pausa. Debajo, la barra de progreso de 3px en #DA9CFF.
- Centro: overline de fase coloreado y anillo de 150px:
  - `listen`: «Escuchando», #DA9CFF, 5 barras animadas (keyframe scaleY entre .3 y 1, 1 s, desfase de .15 s). Titular «Escucha con atención»; subtítulo «Piano · octava 4 · 1 nota».
  - `answer`: «Responde», #FFD54F, icono `hearing`. Titular «¿Qué nota escuchaste?»; subtítulo «Toca la tecla — se envía al instante, sin confirmar.»
  - `result` acierto: «Correcto», #81C784, nombre de la nota en grande. Titular «Bien identificada»; subtítulo «Siguiente ronda en un momento…»
  - `result` fallo: «Incorrecto», #EF9A9A. Titular «Era {X}, respondiste {Y}»; subtítulo «La tecla correcta queda marcada en verde.»
- En `result` aparece la píldora SRS «{nota} SRS 3/5 → 4/5» (o «→ 1/5» si falla) con 5 puntos.
- Encima del teclado van «↻ Repetir» (vuelve a `listen`), el texto «Toca la tecla que escuchaste» y «Saltar ⏭».
- **Teclado** de 230 de alto (contenedor #1A121E con radio 16):
  - 7 teclas blancas en flex, gradiente #FAF6F8→#E4DBE6.
  - 5 negras de 38×140 en las posiciones C#:1/7, D#:2/7, F#:4/7, G#:5/7 y A#:6/7, gradiente #2A2230→#17121B.
- Feedback **sobre la tecla**:
  - Correcta: verde (blanca #A5D6A7→#6FBF73; negra #3BA34A→#1B5E20).
  - Elegida errónea: roja (blanca #F2B4B4→#E08A8A; negra #C0504F→#7A1010).
  - El resto se atenúa.
- Responder es un solo toque, sin botón de confirmar.

## 1c — Progreso: rejilla de 12 notas (móvil)
- «Precisión global» en 52/800 #4E0078 («72.4%»), «+4.1 pts vs. semana pasada» y una barra de meta («80% de la meta (90%)»).
- 3 tarjetas KPI: Latencia media (2.8s), Intentos (1 284) y Pendientes (5, card #2A0640).
- «Dominio por nota · 5 consolidadas · 7 en curso»: rejilla de 4×3 con nombre de nota y %.
  - Rojo <50%; ámbar 50–74% (#FFB300 o #FFC94D); verde ≥75% (#4E9A52, #3B8C3F o #2E7D32 según el nivel). Leyenda debajo.
  - **A11y:** el color no puede ser la única señal; el % va siempre visible y la celda necesita una etiqueta semántica.
- «Últimas sesiones» con «Historial»: filas con modo, «N rondas · M aciertos», % coloreado y fecha.
- Nav inferior con «Progreso» activo.

## 1d — Escritorio / web (1120×700, oscuro)
- Rail izquierdo de 76 con «TG» y 4 destinos de 48. El activo lleva fondo #2A0640 e icono #DA9CFF.
- Cabecera: nombre del modo, chips «Ronda 3 / 12» y «✓ 78%», y los botones «Piano» (instrumento) y «Pausar».
- Centro en dos columnas: el anillo de 170 de la sesión y un **panel «Enfoque SRS de la sesión»** de 300 de ancho. El panel lista notas con estado (Crítica / En curso / Consolidando), % y 5 puntos de nivel SRS, y al pie los atajos:
  - **Atajos de teclado:** `A–G` notas · `⇧` sostenido · `R` repetir · `espacio` siguiente.
- Teclado ancho de 210 con teclas negras de 52×126.

## Pendientes señalados por el propio diseño (fuera de alcance de v2)
- Pasar 1b también a modo claro.
- Versión de 1a sin la card oscura.
- Rediseñar paywall y cuenta.
Las pantallas no cubiertas por v2 (onboarding, velocidad, paywall, cuenta, ajustes) adoptan los tokens de v2 sin cambiar de estructura.
