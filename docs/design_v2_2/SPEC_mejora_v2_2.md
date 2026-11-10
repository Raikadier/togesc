# Especificación — Mejora v2.2 «Que se entienda y apetezca volver»

**Estado:** aprobada por el propietario el 2026-11-10. Progreso en `Plan/progreso_mejora_v2_2.md`.
**Base:** `docs/design_v2_1/SPEC_rediseno_v2_1.md` y `DESIGN.md`. Esta ficha solo describe lo que cambia.
**Por qué:** `docs/auditoria/2026-11-09_evaluacion_rediseno_v2_1.md`. El rediseño v2.1 obtuvo un 5,5/10: cumplió el SPEC (8), pero la experiencia de un usuario común (4) y la gamificación (3) siguen bajas.

## Objetivo
v2.1 añadió componentes y movimiento. v2.2 no añade pantallas: cambia **lo que la app dice y cuándo lo dice**. Meta: que un músico aficionado, en móvil, entienda su primer resultado sin leer ayuda y tenga un motivo para volver al día siguiente.

Restricciones que se mantienen (`PRODUCT.md`): sin XP en el Home, sin métricas inventadas (D10), un botón dominante por pantalla, Hanken Grotesk, paleta v2 y sesión en oscuro. Todo lo nuevo usa datos que ya existen en los providers.

## Principios
1. **Una palabra por concepto.** El mismo estado se llama igual en todas las pantallas.
2. **No juzgar sin datos.** Con pocos intentos no hay rojo ni porcentaje.
3. **Cada pantalla responde a «¿y ahora qué?».** El resumen dice qué toca mañana; el Home dice si hoy ya está hecho.
4. **Celebrar solo hechos reales.** Los hitos salen del historial, no de puntos.
5. **Un componente por función.** Un botón principal, un selector segmentado y un formateador de números.

## Decisiones del propietario
Hay que cerrarlas antes de empezar el lote indicado. Entre paréntesis, la recomendación.

| # | Decisión | Lote |
|---|---|---|
| D1 | Nombre llano de «SRS» en la interfaz («repaso inteligente»). | A |
| D2 | Término único para ≥ 75 %: «Consolidada» o «Dominada» («Consolidada»). | A |
| D3 | Intentos mínimos antes de mostrar color y porcentaje de una nota (5). | B |
| D4 | Velocidad: enviar al tocar la tecla, como la sesión normal, o mantener «Confirmar» (enviar al tocar). | E |
| D5 | Renombrar la dificultad «Pro» de Velocidad para no confundirla con el plan («Medio»). | A |
| D6 | «Teclas negras» de Velocidad: modo o interruptor. Sigue abierta desde v2.1 §2.4. | E |

## Lote A — Lenguaje y números
El de mayor impacto por coste: solo cambia textos y formato.

**Qué**
1. **Glosario único**, en `DESIGN.md` y aplicado en toda la app:

   | Hoy | Pasa a |
   |---|---|
   | SRS, Algoritmo SRS, Intensidad SRS | Repaso inteligente, Intensidad del repaso (D1) |
   | Consolidada / Dominada | Un solo término (D2) |
   | Latencia media, Tiempo medio | Tiempo de respuesta |
   | Limpieza tonal (cluster), Neutralidad tonal | Borrado de referencia: «Un sonido entre rondas para que no compares con la nota anterior» |
   | Racha (aciertos seguidos) | Seguidas. «Racha» queda solo para días |
   | Dificultad «Pro» de Velocidad | Medio (D5) |
   | «37% de la meta (90%)» | «Meta: 90 %» con la barra |

2. **Onboarding:** el paso 1 abre con la promesa («Reconoce notas sin referencia. 6 minutos al día») y no con la etiqueta «SRS · variación · limpieza tonal». El paso 2 explica cada tarjeta con una frase de beneficio.
3. **Un formateador de números es-ES:** coma decimal y espacio antes de «%» y de «s». Sustituye los 20 `toStringAsFixed` de `lib/`.
4. **Plurales y tildes:** los 7 plurales rotos («1 intentos», «1 rondas») y las tildes pendientes («Violin», «Organo», «mas», «mayoria», «Precision», «maximo»).
5. **Textos que no aplican cuando no se cobra:** si `SubscriptionConfig.isActive` es falso, la tarjeta de plan del Perfil dice «Acceso completo» en vez de «TOGESC Pro» y «Gestionar». La tarjeta no se oculta: su `ValueKey` `account-pro-entry` la usan los tests e2e y es la entrada permanente a Pro (D8). «Suscribirme (Stripe)» pasa a «Suscribirme».

**Cómo**
- Nuevo `lib/utils/number_format.dart` con `formatPercent`, `formatSeconds` y `plural(n, uno, varios)`. Usa `intl`, que ya es dependencia.
- Los textos se cambian donde están hoy. No se migra a l10n en este lote.
- Ficheros con más cambios: `widgets/onboarding_views.dart`, `widgets/settings_groups.dart`, `models/audio_preferences.dart`, `models/srs_intensity_profile.dart`, `widgets/progress_v2/*`, `utils/session_summary.dart`, `screens/speed_mode_select_screen.dart`, `widgets/profile_views.dart`, `screens/paywall_screen.dart`.

**Hecho cuando**
- `grep -rn "SRS" lib` no devuelve ningún texto visible; identificadores y comentarios sí pueden quedar.
- No queda ningún `toStringAsFixed` en widgets ni pantallas.
- Un test por función del formateador, con los valores 0, 1 y 33,333.

## Lote B — Estados honestos del dominio
**Qué**
1. **Un solo estado por nota**, calculado en un sitio y usado por la rueda, la rejilla, las mini-cards del Home, el panel de sesión, la hoja de detalle y el resumen:

   | Estado | Regla | Color | Texto |
   |---|---|---|---|
   | Sin datos | 0 intentos | `muted` | «Sin datos» |
   | Midiendo | de 1 a N−1 intentos (D3) | neutro (`primary` al 40 %) | «Midiendo · 2 de 5» |
   | A reforzar | ≥ N intentos y < 50 % | rojo | «A reforzar» |
   | En curso | 50–74 % | ámbar | «En curso» |
   | Consolidada | ≥ 75 % | verde | término de D2 |

   «Crítica» desaparece como etiqueta para el usuario. Esto resuelve además que «Consolidadas» se cuente de dos formas (QA del front, punto 9).
2. **Rueda legible con pocos datos:**
   - Relleno mínimo del 18 % en vez del 6 %.
   - La pista lleva un contorno de 1 px en `outlineVariant`, para que se separe de la tarjeta en claro.
   - Las notas en «Midiendo» se rellenan con el color neutro en proporción a los intentos hechos. Así la primera sesión deja la rueda con forma, sin rojo.
3. **Progreso vacío:** con 0 intentos se muestra solo el estado vacío con su botón. El bloque «Dominio por nota» aparece con el primer intento.
4. **Subtítulo de «Dominio por nota»:** cuenta los cinco estados que tengan notas, por ejemplo «2 en curso · 3 midiendo · 7 sin datos».

**Cómo**
- Nuevo `enum NoteMastery` y la función pura `noteMastery(timesSeen, pct)` junto a `masteryColor` en `app/design_tokens.dart`. `masteryColor` pasa a recibir el estado.
- Sustituir las reglas locales: `home_v2/today_session_hero.dart:58`, `session_v2/session_srs_panel.dart:10`, `progress_v2/note_mastery_grid.dart:259`, `home_v2/ear_map_card.dart:176` y `widgets/progress_v2/mastery_overview.dart:71` y `:115`.
- `ear_map/ear_map_wheel.dart`: nuevo mínimo y contorno de la pista.

**Hecho cuando**
- Tests de `noteMastery` en los límites: 0, 1, N−1 y N intentos; 49,9, 50, 74,9 y 75 %.
- Tras una sesión con un solo intento por nota, ninguna pantalla muestra rojo ni «0 %». Hay un test de widget del Home que lo comprueba.
- La leyenda es la misma en la rueda y en la rejilla.

## Lote C — Primera sesión y bucle diario
**Qué**
1. **Resumen de sesión:**
   - **Titular según lo ocurrido, no solo según la precisión.** En las tres primeras sesiones: «Primera medición hecha» (o «Segunda», «Tercera»), con el icono `hearing` y sin medalla. Después siguen las medallas de v2.1.
   - **Comparación con la sesión anterior del mismo modo**, si existe: «5 puntos más que la última vez» o «Igual que la última vez». Si no existe, no se muestra.
   - **Filas de cambio de nivel:** el color del cuadro es el estado de la nota (lote B). La flecha se mantiene. Una nota en «Midiendo» que sube de nivel ya no sale en rojo con flecha verde.
   - **Línea «Mañana»:** «Mañana repasas Fa y La#», a partir de las notas con repaso pendiente. Si no hay ninguna: «Mañana, notas nuevas».
   - **Seguidas:** el máximo de aciertos consecutivos de la sesión como cuarta KPI, si es ≥ 3.
2. **Home después de practicar:**
   - El hero cambia a «Sesión de hoy hecha», con la precisión de esa sesión y la línea «Mañana».
   - El botón dominante pasa a ser «Practicar más» en estilo secundario claro: sigue siendo la única acción principal, pero ya no parece una tarea pendiente.
   - Los pasos «1 · Escucha, 2 · Toca la tecla, 3 · …» solo se muestran hasta completar la primera sesión.
3. **Orden en móvil:** la tira «Últimos 7 días» sube y queda justo debajo del hero, antes de «Retomar» y «Práctica libre». En escritorio no cambia.
4. **Mini-cards del hero:** la barra se pinta con el color del estado (lote B) y el texto es el del estado.

**Cómo**
- `utils/session_summary.dart`: nuevos campos `sessionNumber`, `deltaVsPrevious`, `dueTomorrow` y `bestStreak`, calculados a partir de `practice_session_log` y de `SRSSystem`.
- `widgets/home_v2/today_session_hero.dart`: variante `completedToday`. El dato ya existe: es el que usa la tira semanal para «Hoy ya practicaste».
- `screens/home_screen.dart:177`: orden de los bloques en móvil.

**Hecho cuando**
- Tests de `session_summary` para la primera sesión, para una sesión con anterior y para una sin notas pendientes.
- Test de widget: el Home con una sesión hecha hoy muestra «Sesión de hoy hecha» y no «Empezar sesión».
- Las `ValueKey` existentes (`today-start-cta`, `session-start`) se mantienen.

## Lote D — Hitos reales
Gamificación sin XP: se celebran hechos que el historial puede demostrar.

**Qué**
1. **Cuatro hitos:**

   | Hito | Regla | Dónde se ve |
   |---|---|---|
   | Primera nota consolidada, y cada nueva | una nota pasa a «Consolidada» en esta sesión | Resumen: su segmento de la rueda hace el pop y aparece la píldora «Do, consolidada» |
   | Mejor sesión | la precisión supera la mejor anterior del mismo modo, con ≥ 3 sesiones previas | Resumen: píldora «Tu mejor sesión hasta hoy» |
   | Racha récord | la racha de días supera la mejor guardada | Home: el chip de racha muestra «Récord» ese día |
   | Octava completa | 12 de 12 consolidadas | Resumen y Perfil |

2. **Meta de octava visible:** el anillo «N de 12» del Home ya existe. Se añade al resumen cuando cambia N.
3. **Chip «⚡ N» de la sesión:** lleva `Tooltip` y `Semantics` «N seguidas», y solo aparece desde 2.
4. **Perfil, «Tus hitos»:** lista de los hitos conseguidos con su fecha. Si no hay ninguno, el bloque se oculta (D10).

**Cómo**
- Nuevo `utils/milestones.dart`: función pura que recibe el estado SRS de antes y de después y el historial, y devuelve los hitos de la sesión.
- Se guardan en `app_preferences` la mejor racha de días y la lista de hitos con fecha.
- **Dependencia:** el historial está limitado a 50 sesiones (`services/app_preferences.dart:319`, hallazgo F9). «Mejor sesión» necesita guardar el récord aparte, no recalcularlo del historial.
- Las celebraciones reutilizan `easeSpring` y respetan el movimiento reducido.

**Hecho cuando**
- Tests de `milestones` para cada hito y para el caso sin hitos.
- Ningún hito se muestra sin el dato que lo respalda.

## Lote E — Coherencia visual
**Qué**
1. **Un botón principal:** nuevo `TogescCta` con el estilo del Home (#FFB300, 17/800, alto `ctaHeight`, sombra del prototipo). Lo usan Home, «Estoy listo», el resumen, el onboarding y el paywall.
2. **Un selector segmentado:** `TogescSegmented`, con el estilo de «Resumen | Historial». Sustituye al `SegmentedButton` de Material en «Rueda | Rejilla», timbre, tema, duración y dificultad.
3. **Anchos:**
   - El contenido de onboarding, «Preparado» y paywall se limita a 620 px y se centra en vertical.
   - Dos columnas en el Home desde 840 px, no desde 1024. Entre 600 y 840, el contenido se limita a 640 px.
   - Un solo par de breakpoints en `DesignTokens`: 600 y 840.
4. **Escala del prototipo en escritorio:** número del hero a 52 y padding de 32; arte del onboarding a 220; valor central de la rueda a 34.
5. **Velocidad:**
   - Botón de volver en todas las fases.
   - Un solo título.
   - El piano ocupa el mismo ancho que el resto de controles.
   - Envío al tocar si se aprueba D4.
6. **Paywall:** panel `surfaceContainerLowest`, como pide v2.1 §2.6.
7. **Fila de KPI:** en cada pantalla, la KPI principal va destacada (card `hero`) y las demás son secundarias.
8. **Tokens:** espaciados de 10, 20 y 24; mover a tokens los 12 hex, los 15 `fontSize`, los 6 radios y las duraciones y curvas literales.
9. **Movimiento que faltó en v2.1:** entrada escalonada en Velocidad, Perfil, Ajustes y la pestaña Historial; `CountUpText` en la precisión del Home; pop del nombre de la nota y subida de la píldora en el resultado.

**Cómo**
- `TogescCta` y `TogescSegmented` van en `widgets/togesc_ui.dart`, junto a los demás componentes propios.
- La lista de ficheros y líneas fuera de tokens está en la evaluación, punto 18.

**Hecho cuando**
- No queda ningún `FilledButton.styleFrom` con ámbar fuera de `TogescCta` ni ningún `SegmentedButton` en `lib/`.
- Un test por ancho (360, 768, 840 y 1280) comprueba el número de columnas del Home.
- Capturas nuevas de Home, sesión, Progreso y Velocidad a 360, 768 y 1280, en claro y oscuro, en `docs/evidence/`.

## Lote F — Accesibilidad pendiente
**Qué**
1. **Anillo de foco global:** 3 px con 2 px de separación, en `primary` (claro) y #DA9CFF (oscuro), definido en el tema para botones, teclas, tarjetas pulsables, chips e interruptores (v2.1 §1.3).
2. **Anuncio del acierto con la nota:** «Correcto, Do sostenido».
3. **Etiquetas habladas:** «Do sostenido» en vez de «C#» o «Do#», en todas las `Semantics`.
4. **Desbordes con texto escalado** a 360 dp en Progreso, Home, Juego, Velocidad y Onboarding (QA del front, punto 7).
5. **Navegación con semántica:** barra lateral, pestañas y tarjetas de dificultad.
6. **Estados vacíos y errores:** los 6 estados vacíos llevan una acción y los 4 errores silenciosos muestran un mensaje.

**Hecho cuando**
- Los tests en skip de `test/qa/a11y_*` que cubren estos puntos pasan sin skip.
- Comprobado a mano con TalkBack o VoiceOver en una sesión completa. Esto sigue sin hacerse desde v2.1.

## Orden y resultado esperado
| Orden | Lote | Coste | Sube sobre todo |
|---|---|---|---|
| 1 | A · Lenguaje y números | Bajo | Claridad, primera vez |
| 2 | B · Estados honestos | Medio | Comprensión del progreso, primera vez |
| 3 | C · Primera sesión y bucle diario | Medio | Bucle diario |
| 4 | F · Accesibilidad pendiente | Medio | Accesibilidad |
| 5 | D · Hitos reales | Medio | Gamificación |
| 6 | E · Coherencia visual | Alto | Calidad visual, acabado |

A, B y C van primero porque atacan las dos notas más bajas con el menor coste. E es el más grande y el que menos cambia la experiencia, así que va el último.

Reglas de trabajo, las mismas de `Plan/hoja_ruta_rediseno_v2_1.md`: un lote por sesión, `flutter analyze` y `flutter test` en verde antes de cerrar, `ValueKey` existentes intactas y nada de hex sueltos.

**Cómo se mide:** repetir la evaluación del 2026-11-09 con los mismos criterios al cerrar C y al cerrar E. Objetivo: experiencia de un usuario común ≥ 7, gamificación ≥ 6 y nota global ≥ 7,5. Para validar de verdad «intuitivo para un usuario común» hace falta probarlo con tres o cuatro personas que no conozcan la app; ningún agente sustituye eso.

## Fuera de alcance
- XP o niveles de usuario en el Home.
- Pantallas nuevas.
- Migrar los textos a l10n.
- Sesión en modo claro.
- Los bugs funcionales y de back, que tienen sus propios informes.
