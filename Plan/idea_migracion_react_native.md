# Idea aparcada — migrar el front de Flutter a React Native

**Estado:** idea, no decisión. Anotada el 2026-11-10 a petición del propietario.
**Decisión actual:** no migrar ahora. Primero se termina el front en Flutter.

## La idea
Reescribir la app, hoy en Flutter (unas 29.000 líneas de Dart y 874 tests), en React Native.

## Por qué no ahora
- Producción se puso al día el 2026-11-10, por primera vez desde julio. Reescribir vuelve a parar las entregas durante meses.
- El problema del front no es el framework. La evaluación del 2026-11-09 da un 8 al cumplimiento del SPEC y un 4 a la experiencia: fallan el lenguaje, el primer resultado y el motivo para volver. Eso se reescribiría igual.
- `PRODUCT.md` fija «un solo front». Mantener dos durante la migración lo incumple.

## Cuándo se reabre
Se reabre si se cumple **al menos una** de estas condiciones, y no antes de haber probado la app con usuarios reales:

1. **La web es la plataforma principal.** Flutter web dibuja en un lienzo: `main.dart.js` pesa 4 MB, no hay HTML real y el lector de pantalla no ve la navegación. En ese caso la opción a comparar es React web con una app móvil después, no solo React Native.
2. **El propietario domina React y no Dart**, y eso frena cada cambio.
3. **Un bloqueo técnico de Flutter** que no tenga arreglo razonable: accesibilidad web, peso o tiempo de carga.

«Se ve genérico» no es motivo: es un problema de diseño, no de framework.

## Riesgos, de mayor a menor
| Riesgo | Por qué |
|---|---|
| Audio | La app sintetiza los tonos en el dispositivo con baja latencia (`flutter_soloud`). En React Native eso exige un módulo nativo o una librería de audio de bajo nivel. Es lo que puede tumbar la migración. |
| Piano y rueda | Están dibujados a mano. Hay que rehacerlos con SVG o Skia y recuperar su accesibilidad. |
| Tests | Los 874 tests no se portan. Hay que reescribir los que protegen el SRS y el flujo de la sesión. |
| Datos de los usuarios | El progreso está en `shared_preferences`. La app nueva tiene que leerlo o se pierde. |
| Dos fronts a la vez | Cualquier arreglo durante la migración se hace dos veces. |

Lo que se porta fácil: el SRS, la fusión del progreso, la selección de notas y los formatos. Son funciones puras.

## Hoja de ruta, si algún día se hace

### Fase 0 — Prueba de dos días (decide si se sigue)
- Una sola pantalla en Expo: la sesión de «Una nota» con el piano.
- **Se mide:**
  - Latencia entre tocar la tecla y oír el sonido, en un Android real. Objetivo: igual o mejor que la app actual.
  - Que la síntesis de un tono y del borrado de referencia no congele la interfaz.
  - En web: peso de la carga inicial y que el lector de pantalla lea las teclas.
- **Criterio de salida:** si el audio no cumple, la idea se cierra aquí.

### Fase 1 — Dominio en TypeScript
- Portar `srs_system`, `progress_merge`, `note_pool`, `today_session`, `session_summary` y `number_format`.
- Portar sus tests unitarios y comprobar que dan los mismos resultados que en Dart con los mismos datos de entrada.
- **Hecho cuando:** los mismos casos pasan en los dos lenguajes.

### Fase 2 — Esqueleto y sesión
- Navegación, tema con los tokens de `DESIGN.md` y la sesión completa: Preparado, escucha, respuesta, resultado y resumen.
- Lectura del progreso guardado por la app de Flutter.
- **Hecho cuando:** una sesión completa funciona en Android y en web, con el progreso anterior.

### Fase 3 — Resto de pantallas
- Home, Progreso, Velocidad, Perfil, Ajustes, onboarding y paywall, en ese orden.
- Sync con Supabase reutilizando las mismas tablas y funciones.

### Fase 4 — Cambio
- Probar con usuarios la versión nueva frente a la actual.
- Publicar la nueva y archivar el código de Flutter. No se mantienen las dos.

## Antes de reabrirla, comprobar
- ¿Hay usuarios reales que justifiquen el esfuerzo?
- ¿El motivo es uno de los tres de «Cuándo se reabre»?
- ¿Se ha hecho la Fase 0?

No hay estimación de plazo: depende de la Fase 0 y de cuánto del front se haya rediseñado para entonces.
