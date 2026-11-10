# Especificación — Rediseño v2.1 «La sesión como instrumento», pulido

**Estado:** propuesta aprobada para implementar (2026-10-26).
**Base:** `docs/design_v2/SPEC_rediseno_v2.md` y `DESIGN.md` (v2). Esta ficha solo describe **lo que cambia**. Todo lo que no aparece aquí sigue igual que en v2.
**Referencia visual e interactiva:** `docs/design_v2_1/prototype/` (abrir `index.html` en un navegador). El prototipo es **referencia, no código a portar**: HTML/CSS/JS → widgets Flutter que reutilicen `DesignTokens`, `TogescColors` y los widgets existentes.

> Los datos del prototipo (precisiones, intentos, historial) son de demostración. En la app todo sale de providers reales (regla D10: no inventar métricas). Si un dato no existe, el elemento se oculta.

## Motivo del pulido
Feedback del propietario sobre v2: «se ve demasiado simple, falto de movimiento, falto de accesibilidad, poco intuitivo para un usuario común y demasiado genérico para una app gamificada».
Restricciones que se mantienen: Hanken Grotesk como única fuente, paleta v2, tono académico, **sin XP en el Home** (`PRODUCT.md`), un CTA dominante por pantalla, sesión en oscuro.

## 1. Elementos nuevos transversales

### 1.1 Mapa del oído (`EarMapWheel`) — firma visual
- Rueda de 12 segmentos en orden cromático, **C arriba** y sentido horario. Cada segmento ocupa 30° con un hueco de unos 2,5° a cada lado.
- **Pista:** sector anular completo entre `r0` y `r1`, relleno `surfaceContainer` (#F3ECF1 en claro, #241B2A en oscuro, blanco al 8 % sobre `hero`).
- **Relleno:** sector desde `r0` hasta `r0 + (r1 − r0) · max(0,06, pct/100)`, con el color de `DesignTokens.masteryColor(pct, srsLevel:)`. Es una barra radial: encoding de datos relleno, no solo contorno.
- **Etiqueta** de la nota fuera del anillo (`r ≈ 146/160` del viewBox de 320), 13/800, con la notación activa (C/D/E o Do/Re/Mi).
- **Centro:** por defecto la precisión global (Home) o «N/12 consolidadas» (Progreso). Al pasar el ratón o enfocar un segmento muestra «{nota} · nivel X/5» y su %.
- **Interacción:** cada segmento es enfocable (Tab) y se activa con Enter o Espacio.
  - Home: muestra una fila de detalle con el botón «Practicar».
  - Progreso: abre la hoja de detalle de nota.
- **Semantics** por segmento: «C sostenido, 42 %, crítica, nivel 1 de 5».
- **Animación de entrada:** escala 0,55 → 1 con curva spring y un desfase de 45 ms por segmento, más 120 ms iniciales. Con movimiento reducido no hay animación.
- **Proporciones** (viewBox de 320): `r0 = 64`, `r1 = 126`. Variante compacta: `r0 = 70`, `r1 = 132`.
- **Dónde va:** card «Mapa del oído» del Home, «Dominio por nota» de Progreso y el resumen de la sesión (variante sobre oscuro).

### 1.2 Movimiento (tokens nuevos en `DesignTokens`)
| Token | Valor | Uso |
|---|---|---|
| `easeOut` | `Cubic(.22, 1, .36, 1)` | Entradas y barras |
| `easeSpring` | `Cubic(.34, 1.56, .64, 1)` | Pop de tecla, segmentos, interruptores |
| `durationKey` | 90 ms | Hundimiento de tecla |
| `durationFast` | 120 ms | Hover y estados |
| `durationMedium` | 280 ms | Transiciones de fase |
| `staggerStep` | 60 ms (listas) / 45 ms (rueda) | Entradas escalonadas |

- **Entrada de pantalla:** cada bloque sube 12 px y aparece en 600 ms con `easeOut`, escalonado por bloque.
- **`CountUpText`:** los números grandes (precisión global, KPI del resumen) cuentan de 0 al valor en 900 ms con *ease-out cubic*.
- **Todo** respeta `UiPreferences.reduceAnimations` y `MediaQuery.disableAnimations`. Si cualquiera de los dos está activo, la duración pasa a 0 y no hay escalonado.

### 1.3 Accesibilidad (nuevo)
- **Texto más grande:** nueva preferencia `largeText` en `UiPreferences`. Aplica un `TextScaler.linear(1.125)` a toda la app, encima del escalado del sistema.
- **Piano más grande:** ya existe (`largePiano`). Valores: alto de 270 en móvil (230 normal), negras de 44×160. En escritorio, 250 de alto y negras de 58×150.
- **Foco visible:** anillo de 3 px en `primary` (claro) o `#DA9CFF` (oscuro), con 2 px de separación, en todo lo enfocable.
- **Esc** pausa la sesión. Los atajos A–G, ⇧, R y Espacio siguen igual que en v2.
- **Regiones vivas:** el resultado se anuncia («Correcto, C sostenido» / «Incorrecto. Era X, respondiste Y») y también el resumen final.
- **Color nunca como única señal** (igual que en v2), más el icono «pendiente» (`schedule`) en las celdas con repaso vencido.

## 2. Pantallas

### 2.1 Home — `prototype/home.html`
Mantiene una sola decisión (la sesión de hoy). Cambios:
1. **Hero:**
   - Punto pulsante junto a la overline «Sesión de hoy».
   - Las mini-cards foco muestran también el estado en texto («Crítica» / «En curso»).
   - **Nueva lista de 3 pasos** sobre el CTA: «1 · Escucha», «2 · Toca la tecla», «3 · El SRS ajusta tu repaso» (iconos `hearing`, `piano`, `trending_up` en #DA9CFF).
   - El copy se ajusta al número de notas foco: «El SRS priorizó tres notas…».
2. **Hoja «Ajustar enfoque y duración»** (antes era un enlace):
   - Duración segmentada: 6 rondas · 3 min / 12 · 6 min / 20 · 10 min.
   - Chips de las 12 notas con una muestra del color de dominio. Se eligen de 1 a 4 notas foco.
   - Botones Guardar y Cancelar. Guarda en `today_session_provider`.
3. **Card «Mapa del oído»:**
   - Rueda con la precisión global en el centro.
   - Leyenda con los rangos escritos.
   - **Meta de octava:** anillo pequeño con «N de 12 notas consolidadas» y debajo «Te faltan M para dominar la octava completa» (N = notas con ≥ 75 %).
   - Al tocar un segmento aparece una fila de detalle con el botón «Practicar», que abre la sesión de una sola nota con esa nota.
4. **Semana:** pasa a «Últimos 7 días» (el último es hoy).
   - La celda de hoy, si está pendiente, lleva un borde discontinuo con la etiqueta «HOY».
   - Debajo, una frase de estado: «Completa la sesión de hoy para llevar la racha a N días» o «Hoy ya practicaste. Llevas N días seguidos».
5. **Escritorio (≥ 1024):** dos columnas.
   - Izquierda (1,25 fr): hero, Retomar y Práctica libre.
   - Derecha (1 fr, *sticky*): Mapa del oído y semana.

### 2.2 Sesión — `prototype/session.html`
Sigue la máquina de estados de v2. Cambios:
1. **Estado «Preparado»**: es `SessionPhase.idle`, que ya existe para el gesto de audio (D4).
   - **Siempre** se muestra al entrar.
   - Anillo con el icono `headphones`, titular «Ponte los auriculares» y subtítulo «{N} rondas · 1 nota · foco en F♯, C♯, A♯».
   - CTA ámbar «Estoy listo» (también con Espacio) y botón de texto «Probar el sonido» (reproduce un La 4).
   - El teclado y los controles no aparecen hasta empezar.
2. **Anillo de fase con arco de progreso:**
   - En `listen`, el arco se llena de forma lineal durante 1,5 s con el color de la fase.
   - En `result`, el interior hace un halo (*glow*) de 1,2 s con el color del resultado.
3. **Resultado:**
   - El nombre de la nota aparece con pop (spring) dentro del anillo.
   - Con 3 o más aciertos seguidos, el titular pasa a «¡N seguidas!».
   - La píldora SRS aparece con una animación de subida.
4. **Teclas:** hundimiento de 2 px al pulsar y onda (*ripple*) en #DA9CFF.
   - Acierto: pop (subida de 4 px y escala 1,03).
   - Fallo: shake (±4 px).
   - El icono ✓/✗ aparece con escala spring.
5. **Hoja «Instrumento de esta sesión»:** botón con el icono `piano` en la barra superior, en todos los tamaños. Rejilla con los timbres de `InstrumentPreset` y una preescucha al elegir.
6. **Pausa** (botón, Esc o volver con la sesión en curso):
   - Hoja «Sesión en pausa» con «Ronda X de N · Y aciertos».
   - Acciones: Continuar (ámbar), Reiniciar la sesión y Salir sin guardar.
7. **Resumen al terminar (nuevo, sustituye la vuelta directa):**
   - Medalla según la precisión:
     - ≥ 75: `military_tech`, «Gran oído hoy».
     - ≥ 50: `workspace_premium`, «Vas por buen camino».
     - < 50: `self_improvement`, «Cada fallo afina el repaso».
   - KPI: Precisión (CountUp), Aciertos «X/N» y Tiempo medio de respuesta (real, medido).
   - «Cambios de nivel SRS»: una fila por nota que salió en la sesión, con el nivel antes → después, los puntos y una flecha arriba o abajo. Las filas entran escalonadas 90 ms.
   - Rueda del Mapa del oído (variante oscura) con los datos ya actualizados.
   - Acciones: «Volver al inicio» (ámbar) y «Ver mi progreso» (secundario).
   - Requiere guardar el nivel SRS de cada nota al empezar la sesión, para comparar al final.
8. **Escritorio:** el panel SRS resalta la nota de la ronda actual (fondo #DA9CFF al 10 %) y añade «Esc · Pausar» a los atajos.

### 2.3 Progreso — `prototype/progress.html`
1. **Pestañas «Resumen | Historial»** (segmentado con `role=tab` y flechas ← →).
2. **Cabecera:** la precisión global 52/800 cuenta al cargar. La barra de meta lleva degradado `primaryContainer → primary` y el texto «X % de la meta / Meta 90 %».
3. **KPI:** «Pendientes» (card `hero`) es ahora pulsable y abre la sesión de hoy.
4. **Dominio por nota:**
   - En móvil, un selector «Rueda | Rejilla» (la rueda por defecto).
   - En escritorio, las dos lado a lado.
   - Las celdas de la rejilla son botones, entran escalonadas 35 ms y llevan el icono `schedule` si están vencidas.
5. **Hoja de detalle de nota (nueva):**
   - Celda grande de 88 px y estado.
   - Precisión, intentos y latencia media (de `NoteProgressSummary`).
   - Pista de nivel SRS 1–5 y una frase pedagógica según el estado.
   - Botones «Escuchar» (secundario) y «Practicar esta nota» (primario).
6. **«Tus extremos» (Pro):** 3 notas más difíciles y 3 más fáciles.
7. **Historial:**
   - Gráfico de barras rellenas con la precisión por sesión (verde si ≥ 75 %) y su texto alternativo en `Semantics`.
   - Lista completa de sesiones.

### 2.4 Velocidad — `prototype/speed.html`
1. **Selección:**
   - Las 3 dificultades (Fácil 15 s, Pro 10 s, Elite 5 s) son tarjetas radio con un cuadro de segundos y la mejor racha guardada.
   - Card `hero` «Teclas negras» con un interruptor para incluirlas o no.
   - Card «Cómo funciona» con 3 pasos numerados.
2. **Juego (oscuro):**
   - Cuenta atrás 3-2-1 con pop y un clic sutil.
   - Temporizador en anillo de 168 px en #FF8A65. Pasa a #EF9A9A con latido cuando queda < 2 s o < 30 % del límite.
   - Destello de fondo verde o rojo con cada respuesta.
3. **Resumen:**
   - Píldora «Nuevo récord personal» si se supera la mejor racha.
   - KPI: Racha final, Mejor tiempo, Promedio y Respuestas.
   - Botones «Reintentar» (#FF8A65 con texto #2A0640) y «Menú».
4. **Regla de juego a confirmar con el propietario:** en el prototipo, un fallo o un tiempo agotado cierra la ráfaga, y cada acierto reduce el límite un 10 % hasta un mínimo de 1,5 s. **Mantener la regla actual de `speed_session_provider` si difiere** y solo ajustar el copy.

### 2.5 Perfil — `prototype/profile.html`
- **Cabecera** con un avatar de 64 px:
  - Sin cuenta: «Entrenando sin cuenta · Tu progreso vive en este dispositivo».
  - Con cuenta: el email.
- **«Tu oído en cifras»:** Días de racha, Notas consolidadas «N/12» y Sesiones.
- **Card `hero` del plan:** «Plan actual: Gratis», los 3 beneficios de Pro y el botón blanco «Ver TOGESC Pro» (clave `account-pro-entry`).
- **Sincronización:** el estado lleva icono y texto («Sincronizado» / «Sincronizando…»).
- **Recordatorios** y **Notación Do/Re/Mi** como interruptores en línea.
- **Exportar mi progreso** (JSON).
- **Hoja de login y registro:** selector Entrar / Crear cuenta y errores en línea con icono y `role=alert`. Los textos de error son los actuales de `account_screen`.
- **Eliminar cuenta:** confirmación en una hoja.

### 2.6 Paywall — `prototype/paywall.html`
- **Fondo `hero` a pantalla completa.**
  - Si se llega desde un candado (`?feature=`), aparece la píldora «Desbloquea {función}».
  - Titular «Pasa a TOGESC Pro» y 3 beneficios en tarjetas translúcidas.
- **Panel blanco «Gratis o Pro»** con una tabla comparativa (Sí/No con icono y etiqueta accesible).
  - Nota «14 días gratis. El precio se muestra en la tienda antes de confirmar.» **No mostrar precios inventados.**
  - CTA ámbar «Probar 14 días gratis», texto legal y botón «Restaurar compras».
- Mantener la lógica actual de monetización y los mensajes existentes.

### 2.7 Onboarding — `prototype/onboarding.html`
Son 4 pasos con indicador de progreso (pastilla alargada en el paso actual), «Saltar», Atrás y Siguiente. El paso actual se guarda.
1. **Bienvenida:** arte `hero` con un ecualizador animado y la etiqueta «SRS · variación · limpieza tonal».
2. **Cómo funciona:** las 3 tarjetas actuales (Algoritmo SRS, Timbre universal, Neutralidad tonal).
3. **Pruébalo (nuevo):**
   - Botón «Escuchar la nota» (La 4) y piano de sesión.
   - Feedback sobre la tecla y una tarjeta de estado con el texto del resultado.
   - Mientras no se pruebe, el botón dice «Seguir sin probar» en estilo secundario.
4. **Antes de empezar:** notación con vista previa, Reducir animaciones y Texto más grande. Botón «Entendido, empezar».

### 2.8 Ajustes — `prototype/settings.html`
Se reorganiza en 5 grupos con icono en la cabecera. En escritorio, en 2 columnas.
1. **Práctica y accesibilidad** (primero):
   - Reducir animaciones, Texto más grande, Piano más grande, Ocultar etiquetas y Notación.
   - **Vista previa del teclado en vivo**, que refleja el tamaño y las etiquetas.
2. **Sesión:** objetivo de rondas, continuar automáticamente, confirmar antes de enviar e intensidad SRS.
3. **Sonido:**
   - Rejilla de timbres con preescucha.
   - Volumen con valor numérico.
   - Variación de octavas, limpieza tonal y «Probar sonido».
4. **Apariencia:** Claro, Oscuro o Sistema, con la nota «La sesión siempre se muestra en oscuro».
5. **Más:** ver el tutorial y restablecer ajustes (no toca el progreso).

## 3. Fuera de alcance
- XP o niveles de usuario en el Home.
- Sesión en modo claro y Home sin card oscura (siguen pendientes, como en v2).
- Landing de marketing (proyecto aparte).
