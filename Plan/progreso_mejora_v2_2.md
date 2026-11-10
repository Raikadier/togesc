# Progreso — mejora v2.2

Log en orden cronológico inverso. Qué cambia: `docs/design_v2_2/SPEC_mejora_v2_2.md`. Por qué: `docs/auditoria/2026-11-09_evaluacion_rediseno_v2_1.md`.

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
