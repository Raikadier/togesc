# Progreso — mejora v2.2

Log en orden cronológico inverso. Qué cambia: `docs/design_v2_2/SPEC_mejora_v2_2.md`. Por qué: `docs/auditoria/2026-11-09_evaluacion_rediseno_v2_1.md`.

## 2026-11-10 · Lote B: estados honestos del dominio · Claude Code
**Decisión aplicada:** D3 = 5 intentos mínimos antes de juzgar una nota (`masteryMinAttempts` en `constants/srs_constants.dart`).

- **Un solo estado por nota.** `MasteryStatus` y `masteryStatusOf` (`widgets/progress_v2/progress_metrics.dart`) son el único sitio donde se decide. Estados: sin datos, midiendo, a reforzar, en curso y consolidada.
  - Lo usan la rueda, la rejilla, el Mapa del oído del Home, las mini-cards del hero, la hoja de detalle, la hoja «Ajustar enfoque», el panel de la sesión y las filas del resumen.
  - «Crítica» desaparece de la interfaz: ahora es «A reforzar». «Dominada» pasa a «consolidada» también en los textos para lector de pantalla.
- **«Midiendo».** Con 1 a 4 intentos la nota no lleva rojo ni porcentaje: muestra «2/5» y un color neutro (`masteryMeasuringColor`, el primario atenuado sobre la superficie apagada).
  - En el hero del Home, la barra de la mini-card se llena con los intentos hechos.
  - En el resumen, la fila de una nota que aún se mide ya no sale en rojo con una flecha verde.
- **Rueda:**
  - Relleno mínimo del 18 % (antes 6 %), para que una nota al 0 % se lea.
  - Contorno de 1 px en `outlineVariant` en cada segmento, para separarla de la tarjeta en claro.
  - Las notas en «Midiendo» se rellenan en neutro según los intentos hechos.
- **Progreso:**
  - Con cero intentos solo se ve el estado vacío con su botón; el bloque «Dominio por nota» aparece con el primer intento.
  - El subtítulo cuenta los estados que tienen notas: «1 consolidada · 2 en curso · 3 midiendo · 6 sin datos» (`masterySubtitle`).
  - La leyenda de la rejilla añade «Midiendo».
- **Cierra el punto 9 del QA del front:** «Consolidadas» se contaba de dos formas en la misma card (precisión ≥ 75 % en el centro y notas graduadas por el SRS en el subtítulo). Ahora las dos salen del mismo estado. `MasteryOverview` y `NoteMasteryGrid` pierden los parámetros `consolidatedCount` e `inProgressCount`, y el test de QA correspondiente deja de estar en skip.
- **Tests:** `test/unit/mastery_status_test.dart` nuevo (9 tests): límites de 0, 1, 4 y 5 intentos y de 49,9, 50, 74,9 y 75 %, y el subtítulo. Actualizados 9 ficheros de test.
  - El test de contraste del tema oscuro siembra una nota practicada, porque la rejilla ya no aparece sin datos.
  - El control de movimiento reducido usa el onboarding en lugar de Progreso, por el mismo motivo.

**Verificación:** `flutter analyze` sin avisos y `flutter test` +884 ~45.

**Sin hacer en este lote:**
- No se ha visto en la app real: el color neutro y el contorno de la rueda hay que mirarlos en claro y en oscuro.
- «Tus extremos» (Pro) sigue ordenando por precisión sin exigir los 5 intentos.
- El panel de la sesión mantiene «A reforzar» para las notas muy atrasadas aunque tengan pocos intentos: ahí el criterio es el retraso, no la precisión.

## 2026-11-10 · Lote A: lenguaje y números · Claude Code
**Decisiones aplicadas** (las recomendadas en el SPEC; el propietario aprobó el plan sin cambiarlas): D1 «repaso inteligente», D2 «Consolidada», D5 «Medio».

- **Formateador único** (`lib/utils/number_format.dart`): `formatDecimalEs`, `formatPercentEs`, `formatSecondsEs` y `plural`.
  - Sustituye a tres funciones sueltas (`formatPercentEs` de `ear_map_card`, `formatSecondsEs` de `session_summary` y `formatSpeedSeconds`) y a los 18 `toStringAsFixed` de pantallas y widgets.
  - Quedan dos `toStringAsFixed` en `progress_export_service.dart`: son datos del fichero exportado, no texto de interfaz.
  - Todos los porcentajes llevan espacio antes de «%».
- **Glosario** (tabla en `DESIGN.md`, «Lenguaje y números»):
  - «SRS» sale de los 44 textos donde aparecía. Sigue en identificadores y comentarios.
  - «Latencia» pasa a «Tiempo de respuesta» («Respuesta» en las etiquetas estrechas).
  - «Limpieza tonal» y «Neutralidad tonal» pasan a «Borrado de referencia».
  - En Velocidad, «Racha» pasa a «Seguidas», «Mejor racha» a «Récord» y la dificultad «Pro» a «Medio».
  - «Dominada» pasa a «Consolidada». «37% de la meta (90%)» pasa a «Meta: 90 %».
- **Onboarding:**
  - El paso 1 abre con «Reconoce notas sin referencia» y «Unos 6 minutos al día…».
  - Las tres tarjetas del paso 2 se llaman «Repaso inteligente», «Distintos instrumentos» y «Borrado de referencia», cada una con una frase de beneficio.
- **Plurales y tildes:** «1 ronda», «1 intento», «1 sesión», «1 nota escuchada», «1/1 nota seleccionada»; «Violín», «Órgano», «más», «mayoría», «máximo», «Precisión» y «básicos».
- **Sin pagos activos:** la tarjeta de plan del Perfil dice «Acceso completo» y «Ver TOGESC Pro». «Suscribirme (Stripe)» y «Gestionar pago (Stripe)» pierden el paréntesis.
  - **Cambio frente al SPEC:** la tarjeta no se oculta. Su `ValueKey` `account-pro-entry` la usan cuatro tests e2e y es la entrada permanente a Pro (D8). El SPEC queda corregido.
  - El botón sigue llevando a la pantalla de suscripción, como comprueban los tests de D8. Esa pantalla no se ha revisado para el caso sin pagos.
- **Dos desbordes que introdujeron las etiquetas nuevas, corregidos:**
  - «Peso de repaso» en `note_srs_detail_card.dart`: la etiqueta va ahora en `Expanded`.
  - «Seguidas» en la barra de métricas de Velocidad (`togesc_ui.dart`): cada métrica encoge con `FittedBox`.
- **Tests:** `test/unit/number_format_test.dart` nuevo (4 tests). Actualizados los textos esperados en 13 ficheros de test; dos finders se acotaron a su widget porque «40 %» y «70 %» salen ahora con el mismo formato en dos sitios.

**Sin hacer en este lote:**
- No se ha visto en la app real. A 360 px hay que comprobar que «Respuesta · tiempo medio aprox.» y «Borrado de referencia» no cortan.
- «Crítica» sigue como etiqueta: se cambia en el lote B.
- Los textos legales de `privacy_policy_screen.dart` se tocaron solo para quitar «SRS».

**Verificación:** `flutter analyze` sin avisos y `flutter test` +874 ~46.
