# Producto, cumplimiento y lanzamiento

Estándares: HEART, GDPR/COPPA, i18n, SemVer, documentación viva (qstd §1.1, §13.5, §13.7).

## Lo que está bien (no tocar)
- **GDPR — derechos del usuario implementados**: borrar cuenta (`delete_own_account()` SQL + UI), export de datos (`user_data_export_service`, `progress_export_service`), política de privacidad en app (`privacy_policy_screen`).
- **Analytics de producto** con base para HEART (`analytics_events`, CSAT en Fase 6, vistas `metrics_daily`/`metrics_csat_daily`).
- Versionado SemVer iniciado (`v1.0.0`, tag en git, release publicado).
- Onboarding pedagógico + "Acerca de" con replay del tutorial.

## Hallazgos

### I18N-001 — Locale fijo y posibles strings hardcodeadas
- **Severidad:** BAJO · **Esfuerzo:** M · **Prioridad:** P2
- **Evidencia:** [`main.dart:81`](../../TOGESC/togesc/lib/main.dart#L81) `locale: const Locale('es')` fuerza español ignorando el locale del sistema; hay mensajes en código (p. ej. `_generateRecommendationMessage` en [srs_system.dart:336](../../TOGESC/togesc/lib/services/srs_system.dart#L336) devuelve texto en español desde el dominio).
- **Estándar:** qstd §13.7 (i18n sin strings hardcodeadas).
- **Problema:** strings de UI en la capa de dominio acoplan presentación y lógica; el locale fijo impide crecer a otros idiomas pese a tener ARB.
- **Recomendación:**
  - Mover textos de recomendación fuera del dominio (devolver un enum/código y traducir en UI vía ARB).
  - Permitir locale del sistema con fallback a `es`.
  - Pseudo-localización en debug para detectar hardcodings.
- **Criterios de aceptación:**
  - [ ] El dominio no devuelve cadenas de UI traducibles.
  - [ ] Strings de usuario en ARB; añadir un segundo idioma es solo traducir.

### PROD-001 — Retención de datos sin política explícita
- **Severidad:** MEDIO · **Esfuerzo:** S · **Prioridad:** P1 (cumplimiento)
- **Evidencia:** no hay job de retención para `analytics_events` (ver [04_seguridad.md](04_seguridad.md#sec-002)); la política de privacidad debe declarar plazos.
- **Estándar:** GDPR (minimización/retención), qstd §13.5.
- **Recomendación:** definir y documentar retención por tipo de dato (progreso: hasta borrado de cuenta; analytics: p. ej. 180 días; logs: alineado con observabilidad) y automatizar la purga.
- **Criterios de aceptación:**
  - [ ] Política de retención publicada y exacta respecto al comportamiento real.
  - [ ] Purga automatizada de analytics.

### PROD-002 — Distribución móvil incompleta
- **Severidad:** MEDIO · **Esfuerzo:** L · **Prioridad:** P1 (si se quiere stores)
- **Evidencia:** pipeline Android roto (INFRA-001), sin secrets de firma, iOS/TestFlight pendiente, listing de stores diferido.
- **Estándar:** qstd §13.4 (releases/stores).
- **Recomendación:** tras INFRA-001, añadir secrets de keystore, generar AAB firmado, preparar listing (descripción, capturas, icono adaptativo separado foreground/background — ver qstd §8.5), y flujo iOS si hay Mac.
- **Criterios de aceptación:**
  - [ ] AAB firmado reproducible en CI.
  - [ ] Icono adaptativo Android con foreground transparente + background sólido.
  - [ ] Listing y permisos mínimos justificados.

## Coherencia plan ↔ código (HECHO OBSERVADO)
El plan de fases marca Fases 0–7 como COMPLETADAS. La auditoría confirma que el **código existe y es coherente** con lo declarado, pero varios **DoD siguen abiertos** y dependen de los hallazgos P0: sync real (SYNC-001), sandbox de pagos (MON-001/SEC-001), accesibilidad (A11Y-001). Es decir: "código completo" ✅, "validado y listo para mercado" ⏳.

## Pendiente de verificar
- Texto real de la política de privacidad vs comportamiento (datos recogidos, terceros: Supabase/Sentry/Stripe/RevenueCat).
- Si el público puede incluir menores (COPPA) — decisión de producto.
- `Plan/gui_information_architecture.md` para auditar arquitectura de información y etiquetado.
