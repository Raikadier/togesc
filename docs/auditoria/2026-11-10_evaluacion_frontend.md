# Evaluación del frontend por capas — 2026-11-10

Objetivo del propietario: terminar el frontend. Este informe evalúa cada capa del front actual contra los estándares que el propio proyecto fijó en `docs/quality_standards.txt`, compara cómo funciona cada opción con cómo debería funcionar y cierra con una definición de «frontend terminado».

**Estado evaluado:** `main` en el commit `86384ef`, que es lo que está en producción desde el 2026-11-10.

**Cómo se hizo:** lectura del código y trazado de cada preferencia desde el interruptor hasta donde se usa. Se apoya en el QA del front (2026-11-03), la evaluación del rediseño (2026-11-09) y la auditoría integral (2026-11-10), y no repite su detalle. No se ejecutó la app.

**Marcas:** ✔ = comprobado en el código en esta evaluación. «Sin verificar» = deducido, hay que comprobarlo ejecutando.

## Nota por capa

| Capa | Estándar de referencia | Nota |
|---|---|---|
| Arquitectura del front | §2.1, §2.2 y §4 (capas, SOLID, máquina de estados) | 5 |
| Arquitectura de la información | §1.4 (organización, etiquetado, navegación) | 6 |
| Diseño de interfaz | §1.2, §1.5 y §2.3 (Material 3, sistema de diseño) | 5 |
| Diseño de experiencia | §1.1 (Nielsen, HEART) | 4 |
| Accesibilidad | §1.3 y §2.4 (WCAG 2.2 AA) | 5 |
| Rendimiento | §2.5 (Core Web Vitals, 60 fps, audio) | 4 |
| Pruebas | §2.6 (pirámide, cobertura) | 6 |
| Opciones: lo que hacen frente a lo que dicen | §1.1 (consistencia, control) | 5 |

**Global: 5 / 10.** El front funciona y está desplegado, pero ninguna capa llega al nivel que el proyecto se puso como objetivo.

## 1. Arquitectura del front — 5

**Lo que el estándar pide:** capas UI → estado → servicios → modelos; la sesión como máquina de estados fuera de la interfaz; funciones pequeñas; sin código muerto.

**Lo que hay:**
- **La sesión se orquesta dentro de la pantalla.** ✔ `screens/game_screen.dart` tiene 1.273 líneas, 15 `setState`, 19 temporizadores o esperas y 34 `ref.read`. El avance automático, la pausa, el modo confirmar y el resumen se deciden en el widget. Por eso es difícil de probar y de cambiar.
- **Dos bucles de juego.** ✔ `game_session_provider` y `speed_session_provider` implementan por separado la misma ronda. Velocidad no hereda nada de lo que sabe hacer el juego normal (ver §8).
- **La interfaz llama a la infraestructura.** ✔ 15 ficheros de `widgets/` y `screens/` importan servicios directamente, y 4 importan Supabase (`account_screen.dart`, `account_auth_sheet.dart`, `account_data_section.dart` y `auth_sync_listener.dart`).
- **`account_screen.dart` tiene 23 `setState`:** es otra máquina de estados escrita a mano dentro de un widget.
- **Reglas de negocio en la interfaz.** El estado de dominio de una nota se calcula en cinco sitios.
- **Restos de versiones anteriores.** ✔
  - `GameMode.exit(6, 'Salir')`: una opción de menú de la antigua versión de consola, dentro del modelo de dominio.
  - La pantalla `/statistics/notes` (`note_progress_screen.dart`) existe y tiene ruta, pero ningún enlace lleva a ella.
  - El XP se calcula, se guarda y se exporta, y no se muestra.
  - Carpetas `home_v2`, `progress_v2` y `session_v2` junto a widgets anteriores que siguen en uso.
- **Lo que está bien:** los modelos son inmutables, el repositorio de progreso está detrás de una interfaz con implementación local, remota e híbrida, y la lógica del SRS es pura y está probada.

**Qué debería ser:** un motor de sesión único (provider) que exponga la fase, y pantallas que solo pinten esa fase. La pantalla de juego, por debajo de 400 líneas.

## 2. Arquitectura de la información — 6

**Lo que el estándar pide:** organización orientada a tareas, etiquetas consistentes y navegación global, local y contextual.

**Lo que hay:** cuatro destinos (Práctica, Progreso, Velocidad y Perfil), con la sesión fuera de la barra. La base es correcta: una tarea principal y un botón dominante.

**Problemas:**
- **Velocidad está en dos sitios.** ✔ Es una pestaña principal y a la vez un modo de «Práctica libre». Además está declarada como modo Pro (`subscription_constants.dart`), así que con los pagos activos una pestaña principal llevaría a un paywall.
- **Ajustes está escondido.** ✔ Solo se llega desde Perfil. Las opciones que cambian la sesión (tamaño del piano, etiquetas, confirmar) no se pueden tocar desde la propia sesión, salvo el instrumento.
- **Lo mismo se configura en dos sitios:**
  - Duración: «Objetivo de rondas» en Ajustes y «Ajustar enfoque y duración» en el Home.
  - Instrumento: en Ajustes y en la hoja de la sesión.
  - Notación y recordatorios: en Perfil y en Ajustes.
- **«Perfil» mezcla cuatro cosas:** cuenta, plan, datos y la entrada a Ajustes.
- **Una pantalla huérfana** (`/statistics/notes`) y dos destinos a tres niveles de profundidad (Acerca de y Privacidad).
- **Etiquetas:** arregladas en parte con el lote A. Sigue «Crítica» y sigue habiendo dos nombres para el mismo lugar: la pestaña se llama «Práctica» y la ruta y el código, «Home».
- **Nunca se ha validado con usuarios.** El estándar pide card sorting o análisis de tareas; no hay ninguno.

**Qué debería ser:** Velocidad como modo dentro de Práctica o como pestaña, no las dos cosas. Cada ajuste en un solo sitio, con un acceso rápido a los de la sesión desde la propia sesión.

## 3. Diseño de interfaz — 5
Detalle en la evaluación del 2026-11-09. Lo que sigue abierto:
- El botón principal y el selector segmentado no son un único componente.
- 768 px es un móvil estirado; el onboarding, «Preparado» y el paywall pierden escala frente al prototipo.
- La rueda no se lee con pocos datos.
- Fuera de tokens: 12 hex, 15 `fontSize`, 6 radios, 18 duraciones y 8 curvas.
- El estándar pide que cada componente defina sus estados (normal, foco, deshabilitado, carga, error, vacío y éxito). Hay 6 estados vacíos sin acción y no existe un estado de foco común.

**Resuelto con el lote A:** el formato de los números y el vocabulario.

## 4. Diseño de experiencia — 4
Contra las diez heurísticas de Nielsen que cita el estándar:

| Heurística | Estado | Motivo |
|---|---|---|
| 1. Visibilidad del estado | Falla | El Home no dice que la sesión de hoy ya está hecha. |
| 2. Lenguaje del usuario | Mejorado | El lote A quitó la jerga. Queda «Crítica». |
| 3. Control y libertad | A medias | Hay pausa y salida en la sesión. Velocidad no tiene botón de volver. |
| 4. Consistencia | Falla | La sesión y Velocidad responden de forma distinta (ver §8). |
| 5. Prevención de errores | A medias | «Reiniciar progreso» dice «todos los datos» y borra una parte. |
| 6. Reconocer antes que recordar | Bien | El piano y las notas foco están a la vista. |
| 7. Flexibilidad | Bien | Atajos de teclado y cuatro formas de responder. |
| 8. Minimalismo | A medias | El hero apila seis elementos antes del botón. |
| 9. Diagnóstico de errores | Falla | Cuatro errores silenciosos; el fallo de audio no se avisa. |
| 10. Ayuda | A medias | El tutorial se puede repetir, pero al hacerlo cambia la notación. |

Contra HEART: no se mide ninguna de las cinco métricas. Hay 24 eventos de analítica en total.

Lo más grave sigue siendo el arco de la primera sesión: un solo fallo pinta la nota de rojo con «0 % Crítica», y el resumen no dice qué toca mañana.

## 5. Accesibilidad — 5
- **Hecho:** un nodo por tecla del piano, regiones vivas en el resultado y el resumen, texto y piano grandes, y movimiento reducido respetado.
- **Falta:**
  - Anillo de foco global.
  - Desbordes con texto escalado a 360 dp en Progreso, Home, Juego, Velocidad y Onboarding.
  - Navegación sin semántica en web.
  - Etiquetas habladas: «C#» en lugar de «Do sostenido».
  - El acierto se anuncia sin la nota.
- **Nunca se ha probado** con un lector de pantalla real. El estándar del proyecto es WCAG 2.2 AA y hoy no se puede afirmar que se cumpla.

## 6. Rendimiento — 4
- **Sin medir:** no hay ninguna medición de Core Web Vitals ni de Lighthouse, y el estándar pide 90 o más.
- **Carga:** `main.dart.js` pesa 4 MB ✔, las fuentes se descargan al arrancar y no hay indicador de carga inicial.
- **Fluidez:** el borrado de referencia congela la interfaz de 0,4 a 0,7 s por ronda en web. El temporizador de Velocidad reconstruye toda la pantalla cada 100 ms.
- **Lo que está bien:** el SRS y el historial responden en menos de 3 ms.

## 7. Pruebas — 6
- **Hecho:** 874 tests, con la pirámide que pide el estándar (unitarios, de widget, de integración y un smoke e2e). La CI pasa.
- **Falta:**
  - La cobertura se genera en la CI y nadie la mira: no hay umbral. El estándar pide 80 % en la lógica crítica y 60 % en los widgets principales.
  - 46 tests en skip por bugs conocidos.
  - Los tests buscan por texto: cambiar el vocabulario rompió 42.
  - Ninguna prueba en dispositivo real. `integration_test` no corre en la CI.

## 8. Opciones: cómo funcionan y cómo deberían

Cada opción se trazó desde su interruptor hasta el código que la usa. La columna «Dónde aplica» es lo comprobado en el código.

### Práctica y accesibilidad
| Opción | Dónde aplica hoy | Debería |
|---|---|---|
| Reducir animaciones | Toda la app. Quedan fundidos de color de 200 ms en los botones del resultado. | Correcto. Falta verlo en la app real. |
| Texto más grande | Toda la app, ×1,125. Desborda en cinco pantallas a 360 dp. | No desbordar en ninguna. |
| Piano más grande | Juego y Velocidad. No en el piano del onboarding. ✔ | Todos los pianos. |
| Ocultar etiquetas del piano | Solo el Juego. Velocidad las muestra siempre. ✔ | Todos los pianos. |
| Notación Do/Re/Mi | Piano del Juego. La ignoran las tarjetas de «hoy», Velocidad y el piano del onboarding. Repetir el tutorial la sobrescribe. | Una sola función que dé el nombre de la nota, usada en toda la app. El tutorial no debe tocarla salvo que el usuario la cambie. |

### Sesión
| Opción | Dónde aplica hoy | Debería |
|---|---|---|
| Objetivo de rondas | Práctica libre. La sesión de hoy usa otra duración, la de «Ajustar enfoque y duración». | Un solo ajuste de duración, o dejar claro en cada sitio a qué afecta. |
| Continuar automáticamente | Solo el Juego. ✔ | Correcto; en Velocidad no tiene sentido. |
| Confirmar antes de enviar | Solo el Juego. Velocidad pide «Confirmar» siempre, aunque esté desactivado. ✔ | Velocidad debe respetar la opción, o enviar siempre al tocar. Decisión D4 del plan v2.2. |
| Forma de responder (Ambos, Solo piano, Solo texto, Canto) | Solo el Juego. Velocidad siempre usa el piano. ✔ «Canto / tarareo» se ofrece como «experimental» a cualquier usuario. | Velocidad debe respetarla o avisar. «Canto» fuera, o en un apartado «Avanzado». |
| Intensidad del repaso | El SRS y la sesión de hoy. | Correcto. Sin verificar qué pasa al cambiarla con progreso ya hecho. |
| Recordatorios | Solo Android e iOS. En web, el interruptor sale desactivado con una nota. Si el usuario deniega el permiso, no se le avisa. | Avisar cuando el permiso está denegado y ofrecer abrir los ajustes del sistema. |

### Sonido
| Opción | Dónde aplica hoy | Debería |
|---|---|---|
| Timbre (aleatorio o fijo) | Juego y Velocidad. La hoja de la sesión lo cambia solo para esa sesión. | Correcto, pero la hoja debe decir que el cambio es solo para esa sesión. |
| Volumen | Juego, Velocidad, onboarding y «Escuchar» de Progreso. | Correcto. |
| Variación de octavas | Juego y Velocidad. ✔ | Correcto. |
| Borrado de referencia | Solo el Juego. Velocidad no lo usa. ✔ | Razonable, pero el texto de la opción debe decirlo. |
| Duración del tono y del borrado | Se guardan, se usan y se exportan, pero **no hay ningún control para cambiarlas**. ✔ | O se ofrecen en «Avanzado», o se convierten en constantes y se borran de las preferencias. |

### Apariencia y más
| Opción | Dónde aplica hoy | Debería |
|---|---|---|
| Tema claro, oscuro o del sistema | Toda la app, salvo la sesión, que es siempre oscura. | Correcto; ya lleva una nota que lo explica. |
| Ver el tutorial | Reabre el onboarding y sobrescribe la notación. | No cambiar ninguna preferencia sin que el usuario lo pida. |
| Restablecer ajustes | Devuelve los ajustes a su valor inicial; no toca el progreso. | Correcto. |
| Reiniciar progreso | Borra el progreso por nota. Deja el historial, la racha y el XP, y la sync puede deshacerlo. | Borrar todo lo que el diálogo promete, también en la nube. |
| Exportar mi progreso | Descarga un JSON, que incluye el XP que la app no muestra. | Exportar lo que el usuario ve. |

### Otras
| Elemento | Hoy | Debería |
|---|---|---|
| Dificultad de Velocidad | No se recuerda entre visitas. | Recordar la última. |
| «Saltar» y «Repetir» en la sesión | Solo el Juego. | Sin verificar si «Saltar» cuenta la ronda como hecha. |
| Tarjeta de plan del Perfil | Sin pagos dice «Acceso completo», pero lleva a la pantalla de suscripción. | Llevar a una pantalla que explique que todo está abierto. |
| Pantalla de progreso detallado por nota | Existe y nadie puede llegar. | Enlazarla desde Progreso o borrarla. |

**Patrón que se repite:** cinco opciones solo funcionan en el Juego y Velocidad las ignora: ocultar etiquetas, confirmar antes de enviar, forma de responder, continuar automáticamente y borrado de referencia. Es la consecuencia directa de tener dos bucles de juego (§1).

## Frontend terminado: definición
Propongo dar el front por terminado cuando se cumplan estos puntos. Cada uno se puede comprobar.

**Funciona como dice**
1. Cada opción de Ajustes hace lo mismo en el Juego, en Velocidad y en el onboarding, o dice dónde no aplica.
2. No queda ninguna preferencia sin control ni ninguna pantalla sin enlace.
3. «Reiniciar progreso» y «Ver el tutorial» hacen exactamente lo que anuncian.
4. Los 46 tests en skip pasan o su bug se ha descartado por escrito.

**Se entiende**
5. Lotes B y C de v2.2: sin rojo antes de tener datos, resumen con «qué toca mañana» y Home que reconoce la sesión hecha.
6. Cinco personas ajenas completan su primera sesión sin ayuda.

**Está bien construido**
7. Un solo motor de sesión para el Juego y Velocidad. `game_screen.dart` por debajo de 400 líneas.
8. Ningún widget importa Supabase ni servicios: pasan por providers.
9. Sin `GameMode.exit`, sin XP y sin carpetas `_v2`.

**Cumple sus propios estándares**
10. Anillo de foco global y ningún desborde con texto escalado a 360 dp.
11. Una sesión completa hecha con TalkBack o VoiceOver.
12. Lighthouse medido en producción, con un objetivo acordado.
13. Cobertura medida, con umbral en la CI para la lógica crítica.

## Orden propuesto
| Orden | Trabajo | Cierra los puntos |
|---|---|---|
| 1 | Lote B de v2.2: estados honestos | 5 |
| 2 | Lote C de v2.2: primera sesión y bucle diario | 5 |
| 3 | Opciones coherentes: notación única, etiquetas y tamaño en todos los pianos, preferencias sin control, pantalla huérfana, reinicio y tutorial | 1, 2, 3 |
| 4 | Motor de sesión único | 1, 7, 8 |
| 5 | Lote F de v2.2: accesibilidad pendiente | 4, 10, 11 |
| 6 | Limpieza: `GameMode.exit`, XP y carpetas `_v2` | 9 |
| 7 | Medición: Lighthouse y cobertura | 12, 13 |
| 8 | Prueba con cinco personas | 6 |

El paso 4 es el más grande. Conviene hacerlo después del 3, para que el motor nuevo nazca ya con las opciones bien definidas, y antes del 5, para no arreglar la accesibilidad dos veces.

Los lotes D (hitos) y E (coherencia visual) de v2.2 quedan fuera de esta definición: mejoran el front, pero no hacen falta para darlo por terminado.

## Límites
- No se ejecutó la app: lo marcado como «sin verificar» hay que comprobarlo a mano.
- El trazado de opciones es por búsqueda en el código. Una opción puede aplicarse por una vía que la búsqueda no encontró.
- No hay cifras de cobertura ni de rendimiento: nadie las ha medido todavía.
