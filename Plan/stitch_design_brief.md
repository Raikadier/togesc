# TOGESC — Brief para Stitch (lista de pantallas)

**Producto:** Entrenador de Oído Absoluto (TOGESC)  
**Plataforma:** Flutter (móvil + web); diseñar pensando en móvil primero  
**Idioma UI:** español  
**Tono:** educativo, claro, sin gamificación excesiva  

**Qué es:** app de entrenamiento de oído absoluto. El usuario escucha nota(s) generadas en el dispositivo, responde con un piano táctil o texto, y un sistema SRS adapta la práctica. La cuenta y la nube son opcionales.

**Instrucción para Stitch:** define layout, jerarquía visual, tipografía y estilo. Este documento solo lista **qué pantallas existen**, **qué deben comunicar** y **qué controles funcionales** deben incluir.

**Entregables recibidos:** [stitch_deliverables.md](stitch_deliverables.md) — `stitch_togesc_design_system.zip` + `stitch_togesc_design_system_wave2.zip` (cobertura ~100 %)

---

## Prioridad de diseño

1. **Núcleo** — Home, sesión de juego (todos los estados), resultado de ronda  
2. **Velocidad** — selector de modo + sesión velocidad  
3. **Progreso** — estadísticas, recomendaciones en home  
4. **Cuenta y Pro** — cuenta/auth, paywall, suscripción  
5. **Resto** — onboarding, acerca de, privacidad, diálogos  

---

## 1. Onboarding — primera apertura

**ID:** `onboarding`  
**Objetivo:** explicar en 30 segundos por qué la app entrena distinto a un quiz de intervalos.

**Contenido:**
- Título: *Bienvenido al entrenador de oido absoluto*
- Intro breve: la app usa estrategias pedagógicas comprobadas; tres ideas clave
- Tres bloques informativos:
  1. **Repetición espaciada (SRS)** — repite más lo difícil, espacia lo dominado
  2. **Variación de octavas y timbres** — aprender clase de altura (Do, Re, Mi…), no Hz fijos
  3. **Limpieza tonal** — sonido caótico breve tras cada ejercicio para romper anclaje tonal

**Acción principal:** botón *Entendido, empezar*

---

## 2. Home — hub de práctica

**ID:** `home`  
**Objetivo:** punto de entrada diario; priorizar práctica según SRS y elegir modo.

**Contenido superior (condicional):**
- Tarjeta **Recomendaciones** cuando hay datos SRS: mensaje personalizado, notas pendientes, en aprendizaje, días desde última sesión, notas críticas (lista corta)

**Sección principal:** encabezado *Modos de Juego*

**Lista de 6 modos** (cada uno: título, subtítulo, indicador si es Pro, candado si bloqueado):

| Modo | Subtítulo |
|------|-----------|
| Una sola nota | Identifica notas individuales |
| Intervalo (2 notas) | Identifica dos notas simultaneas |
| Acorde (3 notas) | Identifica tres notas simultaneas — **Pro** |
| Aleatorio (1-5 notas) | Numero aleatorio de notas — **Pro** |
| Solo sostenidos | C#, D#, F#, G#, A# |
| Entrenamiento de velocidad | Responde antes de que se agote el tiempo — **Pro** |

**Barra superior:** título *Entrenador de Oido Absoluto*; accesos a Pro (si usuario free), Cuenta, Acerca de, Estadísticas.

---

## 3. Sesión de juego — modo estándar

Diseñar **5 estados** de la misma pantalla (mismo ID de flujo, distinto contenido central). El modo concreto aparece en el título (ej. *Una sola nota*, *Intervalo…*).

**ID base:** `game_session`  
**Acción AppBar:** alternar timbre (*Timbre aleatorio* ↔ *Onda senoidal*)

### 3a. Preparación (`game_idle`)
- Mensaje: *Preparate para escuchar*
- Botón principal: *Reproducir*

### 3b. Escuchando (`game_listening`)
- Mensaje: *Escucha atentamente... (N nota(s))*
- Estado de carga / reproducción en curso (sin interacción de respuesta aún)

### 3c. Respuesta (`game_answer`)
- Pregunta: *Que nota(s) escuchaste? (N)*
- **Piano interactivo:** 7 teclas blancas (C–B) + 5 negras (sostenidos); selección múltiple
- Chips de notas seleccionadas (eliminables)
- Botones: *Confirmar* (habilitado si hay selección), *Repetir* (volver a escuchar)
- **Entrada alternativa:** campo de texto + *Enviar* (placeholder tipo *C E G* o *Do Re Mi* según preferencia)
- Soporte notación letras o solfeo en etiquetas del piano

### 3d. Resultado (`game_result`)
- Piano en solo lectura con feedback correcto/incorrecto por tecla
- Tarjeta de resultado:
  - Éxito: *EXCELENTE!* + notas acertadas
  - Error: *INCORRECTO* + notas correctas
  - Tiempo de respuesta en segundos + comentario (*Rapido!* / *Buen tiempo* / *Tomate tu tiempo*)
  - Bloque *Progreso de notas:* por cada nota afectada, indicador aprendizaje (0–5) o *Consolidada*
- Botón fijo inferior: *Siguiente*

### 3e. Limpieza tonal (`game_cluster`)
- Mensaje: *Limpiando el oido...*
- Indicador de reproducción del cluster (~3 s); sin input del usuario

---

## 4. Selector — modo velocidad

**ID:** `speed_mode_select`  
**Objetivo:** elegir qué tipo de ejercicio practicar en modo velocidad.

**Contenido:**
- Título: *Velocidad - Elige modo*
- Pregunta: *Que modo quieres practicar?*
- Nota: *El tiempo limite disminuira con cada respuesta correcta.*
- Lista de 5 opciones (mismos títulos que modos estándar excepto velocidad): una nota, intervalo, acorde, aleatorio, solo sostenidos

---

## 5. Sesión de juego — modo velocidad

**ID:** `speed_session`  
**Objetivo:** misma mecánica de oír/responder con **countdown** y métricas de racha.

**Barra de métricas persistente:** Racha | Limite (segundos) | Promedio (si aplica)

**Estados a diseñar:**

| ID estado | Mensaje / foco | Acción principal |
|-----------|----------------|------------------|
| `speed_idle` | *Modo Velocidad*, tiempo inicial 10 s | *Comenzar* |
| `speed_listening` | *Escucha... (N nota(s))* | — |
| `speed_answer` | *Que nota(s)? (N)* + **temporizador visible** + piano + confirmar + texto | *Confirmar* |
| `speed_correct` | *CORRECTO!* + nuevo límite de tiempo | continuar |
| `speed_incorrect` | feedback de error | continuar |
| `speed_timeout` | tiempo agotado | continuar / reintentar |
| `speed_game_over` | fin de sesión (resumen racha/tiempos) | volver o reintentar |

---

## 6. Estadísticas

**ID:** `statistics`  
**Objetivo:** reflejar progreso del SRS sobre 12 notas.

**Bloque resumen:**
- Precisión global (%)
- Total de intentos
- En aprendizaje (N / 12)
- Consolidadas (N / 12)
- Pendientes de revisión (si > 0)

**Bloque progreso:** barra *N de 12 notas consolidadas*

**Variante usuario Free:**
- Card bloqueada: *Estadisticas avanzadas (Pro)* — notas más difíciles y más fáciles

**Variante usuario Pro:**
- Sección *Notas Mas Dificiles* (lista de notas)
- Sección *Notas Mas Faciles* (lista de notas)
- Botón *Exportar progreso (CSV)*

**Acción destructiva:** *Reiniciar progreso* (estilo de advertencia) → ver diálogo §14

---

## 7. Cuenta y sincronización

**ID:** `account`  
**Objetivo:** cuenta opcional; sync de progreso SRS entre dispositivos.

**Bloque fijo superior — Preferencias de práctica:**
- Switch *Notacion Do/Re/Mi* — solfeo en piano y respuestas
- Switch *Recordatorios de repaso* — notificación local si hay notas vencidas (solo móvil; en web deshabilitado con texto explicativo)

**Subvistas** (diseñar como estados o pantallas relacionadas):

### 7a. Sin backend (`account_offline`)
- *Sincronizacion no disponible*
- Texto: se puede entrenar con normalidad; progreso solo en dispositivo

### 7b. Iniciar sesión (`account_sign_in`)
- Título *Iniciar sesion*
- Texto: cuenta opcional; vincular progreso entre dispositivos; se puede entrenar sin cuenta
- Campos: email, contraseña
- *Entrar* | enlace *No tengo cuenta — registrarme* | *Olvide mi contrasena*

### 7c. Crear cuenta (`account_sign_up`)
- Título *Crear cuenta*
- Mismos campos; botón *Crear cuenta* | *Ya tengo cuenta — iniciar sesion*

### 7d. Recuperar contraseña (`account_forgot`)
- Título *Recuperar contrasena*
- Campo email | *Enviar enlace* | volver a login

### 7e. Nueva contraseña (`account_reset`)
- Título *Nueva contrasena* (llegada desde enlace email)
- Campo nueva contraseña | *Guardar contrasena*

### 7f. Sesión iniciada (`account_signed_in`)
- Cabecera: email del usuario + estado sync (*Progreso sincronizado en la nube* / *SRS local* / etc.)
- **Panel diagnóstico sync:** estado (*en sync* / pendiente), timestamps local y nube
- Banners contextuales (si aplican):
  - Email no verificado + *Reenviar*
  - Sync es función Pro + *Ver Pro*
  - Cambios locales pendientes + *Subir ahora*
- *Sincronizar ahora* | *Cerrar sesion*

---

## 8. Paywall — TOGESC Pro

**ID:** `paywall`  
**Objetivo:** convertir o informar del plan Pro.

**Contenido:**
- Título dinámico: *Desbloquea {feature}* o *Pasa a TOGESC Pro*
- Descripción: todos los modos, estadísticas avanzadas, sincronización entre dispositivos
- Lista de beneficios:
  - Acordes, aleatorio y modo velocidad
  - Sincronizacion SRS en la nube
  - Estadisticas avanzadas
- Acciones: *Suscribirme* (web: *Suscribirme (Stripe)*), *Probar 14 dias gratis*, *Restaurar compras*
- Cierre: botón cerrar / volver

**Variante monetización desactivada:** mensaje de que todos los modos están disponibles + *Continuar*

---

## 9. Gestión de suscripción

**ID:** `subscription`  
**Objetivo:** ver plan actual y gestionar facturación.

**Contenido:**
- Plan actual: *Gratis* o *Pro* (+ *Periodo de prueba activo* si aplica)
- Subtítulo según estado (*Modos basicos y SRS local* / *Acceso completo*)
- Si Free: *Ver planes Pro*
- Si Pro y con sesión: *Gestionar pago (Stripe)* en web o *Restaurar compras* en móvil
- Nota si sin sesión: iniciar sesión para sync de suscripción entre dispositivos

---

## 10. Acerca de

**ID:** `about`  
**Objetivo:** confianza y contexto pedagógico.

**Contenido:**
- Título *Entrenador de Oido Absoluto*
- Párrafo: TOGESC, código abierto, entrenamiento en dispositivo, cuenta opcional para sync
- Sección *Como entrena la app* — mismos 4 bloques que onboarding + modos de práctica
- Enlaces: *Suscripcion Pro*, *Cuenta y sincronizacion*, *Politica de privacidad*

---

## 11. Política de privacidad

**ID:** `privacy`  
**Objetivo:** cumplimiento legal; lectura larga.

**Contenido:** documento legal scrollable (datos locales, cuenta opcional, Supabase si aplica). Diseñar como pantalla de lectura cómoda; el texto legal lo aporta el equipo.

---

## 12. Diálogo — reiniciar progreso

**ID:** `dialog_reset_progress`  
**Tipo:** modal de confirmación

- Título: *Reiniciar progreso?*
- Cuerpo: *Se perderan todos los datos de entrenamiento. Esta accion no se puede deshacer.*
- *Cancelar* | *Reiniciar* (acción destructiva)

---

## 13. Diálogo — encuesta CSAT

**ID:** `dialog_csat`  
**Tipo:** modal (no dismissible por tap fuera)

- Título: *Como va tu experiencia?*
- Texto: calificación 1–5 para mejorar TOGESC
- Selector 5 estrellas
- Campo opcional: *Comentario (opcional)*
- *Ahora no* | *Enviar*

---

## 14. Componentes compartidos (referencia para consistencia)

Stitch puede tratarlos como **patrones** reutilizables, no pantallas independientes:

| Componente | Función |
|------------|---------|
| Piano 12 notas | Entrada principal; estados normal / correcto / incorrecto / deshabilitado |
| Campo notas + Enviar | Entrada texto alternativa |
| Tarjeta modo | Navegación a sesión; badge Pro; candado |
| Tarjeta recomendación | Consejo SRS en home |
| Tarjeta resultado ronda | Feedback + tiempo + progreso por nota |
| Temporizador countdown | Modo velocidad |
| Panel sync | Estado sincronización en cuenta |
| Snackbar / toast | Mensajes breves (éxito error, checkout, export) — no requiere mockup detallado |

---

## 15. Fuera de alcance Stitch (no diseñar como pantalla in-app)

- Checkout Stripe (navegador externo)
- Portal de facturación Stripe
- Cliente de correo (verificación / reset password)
- Diálogo de permiso de notificaciones del sistema operativo

---

## Resumen — entregables Stitch

| # | ID | Nombre corto |
|---|-----|--------------|
| 1 | `onboarding` | Onboarding |
| 2 | `home` | Home |
| 3a–e | `game_*` | Juego — 5 estados |
| 4 | `speed_mode_select` | Selector velocidad |
| 5 | `speed_*` | Velocidad — 7 estados |
| 6 | `statistics` | Estadísticas (+ variantes Free/Pro) |
| 7a–f | `account_*` | Cuenta — 6 subvistas |
| 8 | `paywall` | Paywall Pro |
| 9 | `subscription` | Suscripción |
| 10 | `about` | Acerca de |
| 11 | `privacy` | Privacidad |
| 12 | `dialog_reset_progress` | Diálogo reiniciar |
| 13 | `dialog_csat` | Diálogo CSAT |

**Total:** 11 pantallas de flujo + 12 estados de sesión + 6 subvistas cuenta + 2 diálogos ≈ **31 artboards** si se desglosa por estado; o menos si Stitch agrupa estados en un mismo frame con anotaciones.

---

*Derivado de `Plan/gui_information_architecture.md` y código en `TOGESC/togesc/lib/screens/`.*
