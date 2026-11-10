# Evaluación del Rediseño v2.1 — 2026-11-09

Rama `feat/rediseno-v2.1`. Evalúa el trabajo de UI/UX cerrado en 8 lotes (`Plan/hoja_ruta_rediseno_v2_1.md`) contra lo que pidió el propietario: «se ve demasiado simple, falto de movimiento, falto de accesibilidad, poco intuitivo para un usuario común y demasiado genérico para una app gamificada».

El plan de mejora que sale de aquí está en `docs/design_v2_2/SPEC_mejora_v2_2.md`.

## Cómo se hizo
Tres agentes de solo lectura, más la verificación del revisor principal:
- **UI Designer:** calidad visual frente al prototipo y a `DESIGN.md`. Vio 20 capturas y el código.
- **UX Researcher:** recorrido de un usuario común. Vio 31 capturas y el código.
- **UI Finish-Gate Reviewer:** cumplimiento del SPEC punto por punto y acabado, solo en código.

Capturas: `docs/evidence/qa_2026-11-03/` (se citan por número). Los bugs funcionales están en `2026-11-03_qa_front.md` y no se repiten aquí.

**Límites:** no se ejecutó la app. El movimiento, el sonido y el lector de pantalla no están evaluados: las capturas son estáticas. Casi todas son de escritorio; de móvil solo hay Home, Juego, Progreso y Velocidad.

**Marcas:** ✔ = el revisor principal lo comprobó en la captura o en el código.

## Nota global: 5,5 / 10

| Dimensión | Nota | Por qué |
|---|---|---|
| Cumplimiento del SPEC | 8 | 56 requisitos hechos, 8 parciales y ninguno sin hacer. |
| Acabado | 6 | Movimiento reducido y semántica sólidos; quedan erratas, plurales rotos y valores fuera de tokens. |
| Calidad visual | 5 | El Home tiene foco; el resto pierde escala frente al prototipo y 768 px es un móvil estirado. |
| Accesibilidad | 5 | Sin anillo de foco global y con desbordes al escalar el texto. |
| Experiencia de un usuario común | 4 | Jerga, primer resultado en rojo, y el Home no cambia tras la sesión. |
| Gamificación | 3 | Solo hay racha diaria y un récord en Velocidad. |

La nota global pondera más la experiencia y la gamificación, porque eran el motivo del rediseño.

### Contra las cinco quejas del propietario
| Queja | ¿Resuelta? | Nota |
|---|---|---|
| «Demasiado simple» | A medias. Hay rueda, resumen y hojas nuevas, pero la misma fila de tres KPI se repite en cuatro pantallas. | 6 |
| «Falto de movimiento» | Probablemente sí en Home, sesión y Progreso. Velocidad, Perfil, Ajustes y Paywall entran sin animación. Sin verificar en ejecución. | 6 |
| «Falto de accesibilidad» | A medias. Hay texto grande, piano grande y regiones vivas; falta el foco visible. | 5 |
| «Poco intuitivo para un usuario común» | No. El rediseño no tocó el lenguaje ni el sentido de los números. | 4 |
| «Demasiado genérico para una app gamificada» | No. La rueda es propia, pero no hay mecánicas nuevas. | 3 |

## Diagnóstico
El rediseño se ejecutó bien, pero apuntó a la superficie. El SPEC pedía componentes, animaciones y hojas, y eso se entregó. No pedía lo que hace que un usuario común entienda la app y vuelva: un lenguaje llano, un primer resultado que no castigue, un Home que reconozca que ya practicaste, y números que cuenten una sola historia. Por eso el cumplimiento es alto y la experiencia sigue baja.

## Qué hace mal

### Experiencia (lo más grave)
1. **✔ El primer resultado castiga y se contradice.** En el resumen, Do aparece en rojo con una flecha verde «Nivel 0 → 1», bajo el titular «Cada fallo afina el repaso». No dice qué hacer mañana ni compara con la sesión anterior. Captura 24.
2. **✔ Un solo fallo basta para «0 % Crítica» en rojo.** La etiqueta sale del porcentaje, sin un mínimo de intentos (`home_v2/today_session_hero.dart:58`, `app/design_tokens.dart:429`). Capturas 25 y 43.
3. **✔ El Home no cambia después de practicar.** El héroe vuelve a decir «Empezar sesión · 12 rondas» mientras la tira semanal dice «Hoy ya practicaste». Captura 25.
4. **Jerga sin traducir.** «SRS» aparece en 44 líneas de `lib/` con texto, y al menos 17 son visibles. El onboarding habla de «limpieza tonal», «neutralidad tonal» y «anclaje relativo». Capturas 01, 02 y 04.
5. **✔ El progreso cuenta tres historias.**
   - «Consolidada» en la rueda frente a «Dominada ≥75%» en la rejilla (`home_v2/ear_map_card.dart:176`, `progress_v2/note_mastery_grid.dart:259`).
   - «0 consolidadas · 12 en curso» junto a cinco casillas «Crítica» y siete sin datos.
   - «Latencia media 6.0s» en Progreso y «Tiempo medio 5,0 s» en el resumen.
   - «37% de la meta (90%)»: un porcentaje de un porcentaje.
   Capturas 24 y 26.
6. **Velocidad juega con otras reglas.** Hay que pulsar «Confirmar» contra el reloj, cuando la sesión normal envía al tocar. No hay botón de volver. La dificultad «Pro» se confunde con el plan de pago, y «racha» significa aciertos aquí y días en el Home. Capturas 28, 29, 32 y 47.
7. **Gamificación decorativa.** Existen la racha diaria, la mejor racha de Velocidad y una medalla que es un icono con una frase. No hay récord de precisión, hito al consolidar una nota ni explicación del chip «⚡ 0» de la sesión.
8. **Textos que no aplican a este build.** «Plan actual: TOGESC Pro», «Cancela cuando quieras» y «Suscribirme (Stripe)» (`screens/paywall_screen.dart:292`). Capturas 34 y 39.

### Visual
9. **✔ La rueda no funciona como firma con pocos datos.** Es un anillo gris, y una nota al 0 % es un hilo rojo casi invisible. Viene del propio SPEC, que fija el relleno mínimo en el 6 %. Capturas 24, 25 y 26.
10. **✔ 768 px es un móvil estirado.** Una sola columna, un botón de unos 650 px y la rueda bajo el pliegue. El shell cambia a 600 y el Home a 1024 (`app/design_tokens.dart:78` y `:356`). Captura 49.
11. **✔ El botón principal no es el mismo en todas partes.** El de «Preparado» usa otro ámbar, otro tamaño y otro peso que el del Home (`screens/game_screen.dart:800`). Captura 17.
12. **Onboarding y hero pierden escala frente al prototipo.** El paso 1 se estira a todo el ancho con el arte a 180; el hero usa el número a 44 en vez de 52 (`home_v2/today_session_hero.dart:229`). Captura 01.
13. **Dos selectores segmentados distintos.** «Resumen | Historial» es propio; «Rueda | Rejilla», timbre y tema son el de Material en magenta. Capturas 09, 41 y 46.
14. **✔ Números con formato mezclado.** «33,3 %» y «33.3%», «5,0 s» y «6.0s». Hay 20 `toStringAsFixed` y solo 2 usos de un formateador.
15. **En móvil, lo que motiva queda abajo.** A 360 px se ven el hero y «Retomar»; la rueda y la tira semanal van después de «Práctica libre» (`screens/home_screen.dart:177`). Captura 43.

### Acabado
16. **Requisitos del SPEC a medias (8):**
    - Entrada escalonada solo en Home, Progreso y resumen.
    - `CountUpText` no se usa en la precisión del Home (`home_v2/ear_map_card.dart:143`).
    - Anillo de foco solo en la rueda y en las pestañas de Progreso.
    - El acierto se anuncia sin la nota (`session_v2/session_phase.dart:150`). ✔
    - Faltan el pop del nombre de la nota y la subida de la píldora SRS.
    - La cabecera de Progreso mantiene el texto de v2.
    - «Teclas negras» sigue siendo un modo, sin interruptor. Está pendiente de decisión del propietario.
    - No existe el estado «Sincronizando…».
17. **Textos:** 6 tildes que faltan y 7 plurales rotos («1 intentos», «1 rondas»).
18. **Fuera de tokens:** 12 hex sueltos, 15 `fontSize` literales, 6 radios, 18 duraciones y 8 curvas. Faltan tokens de espaciado de 10, 20 y 24.
19. **Estados vacíos sin acción (6) y errores silenciosos (4).** Por ejemplo `screens/statistics_screen.dart:94` y `widgets/account_sync_views.dart:31`.

## Qué hace bien
- La rueda con datos, el hero del Home y el piano son propios y reconocibles.
- Todas las animaciones nuevas consultan el movimiento reducido.
- La rueda es navegable con teclado y tiene semántica por segmento.
- El Home tiene una sola decisión y un botón dominante, como pide `PRODUCT.md`.
- El estado «Preparado», la pausa y el resumen existen y funcionan.
- No se inventan métricas (D10).
