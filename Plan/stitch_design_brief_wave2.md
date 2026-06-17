# TOGESC — Brief Stitch · Oleada 2 (pantallas faltantes)

**Producto:** Entrenador de Oído Absoluto (TOGESC)  
**Idioma UI:** español  
**Plataforma:** móvil primero (Flutter); coherencia con oleada 1  

---

## Contexto para Stitch

Ya existe un zip previo (`stitch_togesc_design_system.zip`) con el tema **Harmonic Precision** (Material 3, Hanken Grotesk, púrpura `#6A1B9A`, fondo `#FFF7FC`).  

**Esta oleada debe:**
- Reutilizar **exactamente** el mismo design system (`Plan/stitch_harmonic_precision_DESIGN.md`)
- Mantener coherencia visual con: `home_premium_practice_hub`, `game_session_premium_response`, `game_session_premium_result`, `account_premium_sync_settings`
- No rediseñar lo ya entregado; solo completar el flujo

**Instrucción:** define layout y estilo. Este documento indica **qué pantallas faltan**, **contenido funcional** y **nombres de exportación**.

---

## Prompt sugerido (copiar en Stitch)

```
Diseña las pantallas faltantes de TOGESC (Entrenador de Oído Absoluto), app educativa de entrenamiento de oído absoluto con SRS. Idioma: español. Móvil primero.

Usa el design system Harmonic Precision ya definido (Material 3, Hanken Grotesk, primary #6A1B9A, background #FFF7FC, piano feedback green/red/amber). Mantén coherencia con las pantallas ya generadas: home_premium_practice_hub, game_session_premium_response, game_session_premium_result, account_premium_sync_settings.

No gamificación excesiva. Tono educativo y profesional. Touch targets mínimo 48dp. Radio 12px en cards y botones.

Genera cada pantalla listada abajo con screen.png + code.html. Nombra carpetas según la columna "Carpeta export".
```

---

## Prioridad 1 — Completar flujo de juego estándar

Misma estructura de AppBar que `game_session_premium_response` (título del modo + acción timbre).

### 1. `game_session_premium_idle`
**ID:** `game_idle`  
**Objetivo:** momento previo a escuchar; el usuario inicia la ronda.

| Elemento | Texto / comportamiento |
|----------|------------------------|
| Mensaje principal | *Preparate para escuchar* |
| Iconografía | Auriculares / escucha (coherente con oleada 1) |
| CTA principal | *Reproducir* |
| Sin piano ni campo de texto aún |

---

### 2. `game_session_premium_listening`
**ID:** `game_listening`  
**Objetivo:** el audio está sonando; no se puede responder todavía.

| Elemento | Texto / comportamiento |
|----------|------------------------|
| Mensaje | *Escucha atentamente... (2 nota(s))* — usar "1 nota" como ejemplo |
| Estado | Indicador de reproducción / carga (sin piano interactivo) |
| Sin botones de confirmación |

---

### 3. `game_session_premium_cluster`
**ID:** `game_cluster`  
**Objetivo:** limpieza tonal post-ejercicio (~3 s); transición automática.

| Elemento | Texto / comportamiento |
|----------|------------------------|
| Mensaje | *Limpiando el oido...* |
| Visual | Ondas / audio caótico (abstracto, no literal) |
| Indicador de progreso |
| Sin input del usuario |

---

## Prioridad 1 — Sesión modo velocidad (7 pantallas)

Barra de métricas persistente en todas (como header fijo): **Racha** | **Limite** (ej. 8.0s) | **Promedio** (ej. 1.42s)

Coherencia con `selector_premium_speed_mode` y `game_session_premium_response`.

### 4. `speed_session_premium_idle`
**ID:** `speed_idle`  
- Título área: *Modo Velocidad*  
- Subtexto: *Tiempo inicial: 10s*  
- CTA: *Comenzar* (acento de urgencia respecto al juego normal, sin ser agresivo)

### 5. `speed_session_premium_listening`
**ID:** `speed_listening`  
- *Escucha... (2 nota(s))*  
- Indicador reproducción  
- Métricas visibles arriba

### 6. `speed_session_premium_answer`
**ID:** `speed_answer`  
- **Temporizador countdown prominente** (barra o anillo; tiempo restante visible)  
- *Que nota(s)? (2)*  
- Piano interactivo + chips selección + *Confirmar*  
- Campo texto alternativo + *Enviar*  
- Métricas arriba

### 7. `speed_session_premium_correct`
**ID:** `speed_correct`  
- *CORRECTO!* (refuerzo positivo)  
- *Tiempo limite: 7.0s* (ejemplo de límite reducido)  
- CTA para continuar siguiente ronda

### 8. `speed_session_premium_incorrect`
**ID:** `speed_incorrect`  
- Feedback de error (no punitivo)  
- Mostrar notas correctas  
- CTA continuar

### 9. `speed_session_premium_timeout`
**ID:** `speed_timeout`  
- Tiempo agotado  
- Mensaje claro; mostrar respuesta correcta  
- CTA continuar

### 10. `speed_session_premium_game_over`
**ID:** `speed_game_over`  
- Fin de sesión  
- Resumen: racha final, promedio de tiempo, rondas completadas  
- CTAs: reintentar / volver al hub

---

## Prioridad 2 — Cuenta (auth)

Misma card superior de **Preferencias de práctica** que `account_premium_sync_settings` puede omitirse en subvistas auth (solo en sesión iniciada). Diseño de formularios coherente con cuenta existente.

### 11. `account_premium_sign_in`
**ID:** `account_sign_in`  
- Título: *Iniciar sesion*  
- Texto: cuenta opcional; vincular progreso entre dispositivos; se puede entrenar sin cuenta  
- Campos: Email, Contraseña  
- *Entrar*  
- Enlaces: *No tengo cuenta — registrarme* | *Olvide mi contrasena*

### 12. `account_premium_sign_up`
**ID:** `account_sign_up`  
- Título: *Crear cuenta*  
- Mismos campos  
- *Crear cuenta*  
- Enlace: *Ya tengo cuenta — iniciar sesion*

### 13. `account_premium_forgot_password`
**ID:** `account_forgot`  
- Título: *Recuperar contrasena*  
- Campo email  
- *Enviar enlace*  
- *Volver al inicio de sesion*

### 14. `account_premium_reset_password`
**ID:** `account_reset`  
- Título: *Nueva contrasena*  
- Campo nueva contraseña  
- *Guardar contrasena*

### 15. `account_premium_offline`
**ID:** `account_offline`  
- Icono nube desactivada  
- Título: *Sincronizacion no disponible*  
- Texto: este despliegue no tiene nube; el progreso se guarda en el dispositivo; se puede entrenar con normalidad

---

## Prioridad 2 — Monetización

### 16. `paywall_premium_pro`
**ID:** `paywall`  
- Cierre (X) en AppBar  
- Título ejemplo: *Desbloquea Acordes* (soportar variante genérica *Pasa a TOGESC Pro*)  
- Descripción: todos los modos, estadísticas avanzadas, sincronización entre dispositivos  
- Lista beneficios:
  - Acordes, aleatorio y modo velocidad
  - Sincronizacion SRS en la nube
  - Estadisticas avanzadas
- *Suscribirme* | *Probar 14 dias gratis* | *Restaurar compras*

### 17. `subscription_premium_manage`
**ID:** `subscription`  
- Título AppBar: *Suscripcion*  
- Estado ejemplo Pro: *Plan Pro* — *Acceso completo* o *Periodo de prueba activo*  
- Variante Free: *Plan Gratis* — *Modos basicos y SRS local* + *Ver planes Pro*  
- Si Pro: *Gestionar pago (Stripe)* o *Restaurar compras*  
- Nota si sin sesión: iniciar sesión para sync de suscripción

### 18. `statistics_premium_free`
**ID:** `statistics_free`  
- Misma estructura que `statistics_premium_pro_dashboard` pero:
  - Resumen básico visible (precisión, intentos, aprendizaje, consolidadas)
  - Card bloqueada: *Estadisticas avanzadas (Pro)* — *Notas mas dificiles y mas faciles con TOGESC Pro* + candado / chevron
  - Sin secciones de notas difíciles/fáciles ni export CSV
  - Mantener *Reiniciar progreso* (acción destructiva)

---

## Prioridad 3 — Información y diálogos

### 19. `about_premium_info`
**ID:** `about`  
- Título: *Acerca de TOGESC*  
- H1: *Entrenador de Oido Absoluto*  
- Párrafo: TOGESC, código abierto, entrenamiento en dispositivo, cuenta opcional  
- Sección *Como entrena la app*: SRS, octavas/timbres, limpieza tonal, modos de práctica (4 bloques informativos)  
- Enlaces tipo list tile: *Suscripcion Pro*, *Cuenta y sincronizacion*, *Politica de privacidad*

### 20. `privacy_premium_policy`
**ID:** `privacy`  
- Título: *Politica de privacidad*  
- Pantalla de lectura larga scrollable  
- Placeholder de párrafos legales (lorem estructurado en secciones: datos locales, cuenta opcional, Supabase, analytics)  
- Diseñar legibilidad; el texto final lo aporta el equipo

### 21. `dialog_premium_reset_confirm`
**ID:** `dialog_reset_progress`  
**Tipo:** modal centrado sobre estadísticas  
- Título: *Reiniciar progreso?*  
- Cuerpo: *Se perderan todos los datos de entrenamiento. Esta accion no se puede deshacer.*  
- *Cancelar* | *Reiniciar* (destructivo)

### 22. `dialog_premium_csat`
**ID:** `dialog_csat`  
**Tipo:** modal  
- Título: *Como va tu experiencia?*  
- Texto: calificación 1–5 para mejorar TOGESC  
- 5 estrellas seleccionables  
- Campo opcional: *Comentario (opcional)*  
- *Ahora no* | *Enviar*

---

## Checklist de entrega

| # | Carpeta export | Prioridad |
|---|----------------|-----------|
| 1 | `game_session_premium_idle` | P1 |
| 2 | `game_session_premium_listening` | P1 |
| 3 | `game_session_premium_cluster` | P1 |
| 4 | `speed_session_premium_idle` | P1 |
| 5 | `speed_session_premium_listening` | P1 |
| 6 | `speed_session_premium_answer` | P1 |
| 7 | `speed_session_premium_correct` | P1 |
| 8 | `speed_session_premium_incorrect` | P1 |
| 9 | `speed_session_premium_timeout` | P1 |
| 10 | `speed_session_premium_game_over` | P1 |
| 11 | `account_premium_sign_in` | P2 |
| 12 | `account_premium_sign_up` | P2 |
| 13 | `account_premium_forgot_password` | P2 |
| 14 | `account_premium_reset_password` | P2 |
| 15 | `account_premium_offline` | P2 |
| 16 | `paywall_premium_pro` | P2 |
| 17 | `subscription_premium_manage` | P2 |
| 18 | `statistics_premium_free` | P2 |
| 19 | `about_premium_info` | P3 |
| 20 | `privacy_premium_policy` | P3 |
| 21 | `dialog_premium_reset_confirm` | P3 |
| 22 | `dialog_premium_csat` | P3 |

**Total oleada 2:** 22 artboards

---

## Referencias visuales (oleada 1)

Al generar, usar como referencia de estilo las capturas ya exportadas:

- Hub y navegación → `home_premium_practice_hub`
- Piano + respuesta → `game_session_premium_response`
- Tarjeta resultado SRS → `game_session_premium_result`
- Formularios / sync → `account_premium_sync_settings`
- Stats Pro → `statistics_premium_pro_dashboard`
- Lista modos velocidad → `selector_premium_speed_mode`

---

## Después de exportar

1. ~~Añadir carpetas al zip~~ → **`stitch_togesc_design_system_wave2.zip`** en raíz ✅  
2. ~~Actualizar `Plan/stitch_deliverables.md`~~ ✅  
3. Cobertura: **~100 %** del [stitch_design_brief.md](stitch_design_brief.md) — ver [stitch_deliverables.md](stitch_deliverables.md)

---

*Oleada 2 — pantallas faltantes tras `stitch_togesc_design_system.zip`*
