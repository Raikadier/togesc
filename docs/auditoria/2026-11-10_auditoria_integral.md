# Auditoría integral de TOGESC — 2026-11-10

Encargo del propietario: encontrar las malas decisiones y los errores que aún no conoce, en todas las áreas. Este informe no repite el detalle de los informes anteriores; los resume y añade lo que ninguno había mirado: estrategia, proceso, arquitectura de datos, legal y la forma de trabajar.

**Informes en los que se apoya:**
- `2026-11-03_revision_ui_front_back.md`: bugs de front y back.
- `2026-11-03_qa_front.md`: pruebas del front.
- `2026-11-09_evaluacion_rediseno_v2_1.md`: UI/UX, nota 5,5/10.
- `Plan/progreso_recuperacion_2026-10.md`: estado de Supabase.

**Cómo se hizo:** lectura del repo, la CI, la configuración y la base de datos de producción (por MCP, el 2026-11-10). No se ejecutó la app.

**Marcas:** ✔ = comprobado en esta auditoría. «Inferido» = deducido, sin comprobar.

## Veredicto
El proyecto tiene buena ingeniería y casi ningún usuario. En cinco meses se han hecho tres ciclos de rediseño, un sistema de pagos con dos proveedores y 874 tests, y la base de datos de producción tiene **2 usuarios registrados y 24 eventos de uso**. Lo que usan esos usuarios es la versión del 24 de julio: nada de lo construido desde entonces ha salido.

El problema principal no es técnico. Es el orden: se ha pulido y ampliado un producto que nadie ha probado. Casi todo lo demás de este informe es consecuencia de eso.

## Las decisiones que hay que corregir, por orden

### 1. Construir antes de validar ✔
- **Evidencia:** 2 usuarios, 1 fila de progreso, última sincronización el 2026-06-24, 24 eventos de analítica en total.
- **Lo construido sin usuarios:** paywall, pruebas de 14 días, Stripe, RevenueCat, candado Pro en la sync, exportación de datos, recordatorios, entrada por micrófono, seis modos de juego y seis plataformas.
- **Los rediseños** (Stitch, Impeccable, Partitura viva, v2, v2.1 y ahora v2.2) se han juzgado con el gusto del propietario y con agentes de IA. Ninguna persona ajena al proyecto ha usado la app delante de alguien que observe.
- **Corrección:** congelar funciones nuevas. Poner la app delante de 5 a 10 músicos aficionados y mirar cómo hacen su primera sesión. Lo que salga de ahí manda sobre cualquier plan escrito, incluido el v2.2.

### 2. Todo el trabajo vive en una rama que no se despliega ✔
- **Evidencia:** `feat/rediseno-v2.1` lleva 304 ficheros, +33.913 y −7.054 líneas frente a `main`, en un solo PR (#9) abierto desde el 2026-10-28. La CI de `main` está roja desde el 2026-08-04 y producción es del 2026-07-24.
- **Por qué es grave:** cada día que pasa el merge es más arriesgado, y los arreglos de bugs que corrompen datos (commit 993e977) no llegan a nadie.
- **Corrección:** poner la CI en verde, mergear y desplegar antes de escribir una línea más de producto. A partir de ahí, ramas de días, no de meses.

### 3. La CI y el equipo local usan versiones distintas de Flutter ✔
- **Evidencia:** la CI fijaba Flutter 3.41.4 y en local se usa 3.47.7. Todo lo hecho desde el 2026-10-28 (tres commits y el lote A) solo se ha probado en local.
- **Corrección a la primera versión de este informe:** los 16 tests que fallan en la CI son del código viejo de `main`, no de la diferencia de versión. El PR #9 pasa la CI en su último commit subido (run 40717271354). `main` se pone en verde al mergearlo.
- **Lo que sí es cierto:** se ha normalizado mergear en rojo. El PR #10 se mergeó así.
- **Hecho el 2026-11-10:** los tres workflows pasan a 3.47.7 y la regla queda en `CLAUDE.md`. Falta subir la rama para comprobarlo en la CI.

### 4. Repo público con informes de vulnerabilidades y sin licencia ✔
- **Evidencia:** el repo es `PUBLIC`. Están versionados `docs/auditoria/04_seguridad.md`, `12_pentest_rediseno_v2_2026-10.md` y `13_pentest_dinamico_local_2026-10.md`, junto a la referencia del proyecto de Supabase y las vulnerabilidades abiertas (SEC-006 y SEC-008). No hay fichero `LICENSE`.
- **Por qué es una mala decisión:** se publica el mapa de lo que está sin arreglar. Y sin licencia, nadie puede usar el código legalmente, así que el repo público no aporta nada a cambio.
- **Corrección:** hacer el repo privado. Si algún día se quiere abrir, elegir licencia y sacar antes los informes de seguridad.

### 5. La identidad del producto no está decidida ✔
- **Evidencia:** `PRODUCT.md` dice «tono académico», «sin gamificación excesiva» y «no arcade». La queja del propietario que motivó v2.1 es que la app resulta «demasiado genérica para una app gamificada».
- **Consecuencia:** cada rediseño tira hacia un lado distinto. Esta contradicción es la causa de los ciclos de rediseño, no la falta de pulido.
- **Corrección:** decidirlo en una frase y escribirlo en `PRODUCT.md`. Por ejemplo: «entrenador serio con recompensas discretas». Mientras no se decida, no encargar más diseño.

### 6. La promesa del producto no está respaldada
- **Evidencia:** `PRODUCT.md` promete «adquirir oído absoluto» con «estrategias pedagógicas comprobadas». La app no tiene ninguna medida que demuestre que el usuario mejora más allá de su porcentaje de aciertos dentro de la propia app.
- **Riesgo:** que un adulto adquiera oído absoluto con entrenamiento es una cuestión discutida en la investigación. Prometerlo en una ficha de tienda expone a reseñas negativas y a reclamaciones. No soy experto en la materia: conviene contrastarlo antes de publicar.
- **Corrección:** prometer lo que la app sí puede demostrar, como «reconoce notas sin referencia», y definir una medida de resultado: por ejemplo, una prueba fija de 24 notas cada dos semanas.

### 7. Los pagos se construyeron demasiado pronto y están a medias ✔
- **Evidencia:** la Edge Function `stripe-webhook` está desplegada y responde, con SEC-006 abierto (se fía de un dato que pone el navegador). El candado Pro de la sync dejó sin nube a todos los usuarios durante tres meses sin que nadie lo notara.
- **Corrección:** no arreglar los pagos ahora; apagarlos. Retirar las dos Edge Functions de producción hasta que haya demanda, y fijar un umbral para retomarlos (por ejemplo, 100 usuarios activos por semana).

### 8. Demasiado alcance para una persona
- **Evidencia:** seis plataformas declaradas (`README.md`), seis modos, cuatro formas de responder, dos pasarelas de pago, micrófono, notificaciones y exportación.
- **Consecuencia:** ninguna parte está terminada. Android se firma con la clave de debug si falta el keystore (`android/app/build.gradle`, líneas 52 a 55) en lugar de fallar. iOS, Windows, macOS y Linux no tienen evidencia de haberse probado nunca (inferido).
- **Corrección:** una plataforma principal (web o Android) y dos modos («Una nota» y Velocidad) hasta tener usuarios. Lo demás se oculta, no se borra.

## Arquitectura

### El modelo de datos es el punto débil ✔
- **Qué hay:** el progreso es un bloque JSON en `shared_preferences`, y en la nube otro bloque JSON en una fila por usuario. El historial de sesiones, la racha y el XP solo viven en el dispositivo.
- **Problemas que salen de ahí:**
  - El historial se corta a 50 sesiones, y de él se calculan la racha y el delta semanal.
  - Cambiar de dispositivo conserva el progreso por nota y pierde el historial y la racha.
  - «Reiniciar progreso» borra una parte y la sync lo deshace.
  - Las fechas se guardan en hora local sin zona.
  - No se puede responder a «¿mejora el usuario con el tiempo?», porque no se guarda cada intento.
- **Corrección:** un registro de intentos solo de añadir (nota, respuesta, tiempo, fecha en UTC) como fuente de verdad, en local y en la nube. El progreso, la racha, el historial y los hitos se calculan a partir de él. Es el cambio de arquitectura con más retorno, y conviene hacerlo antes de tener datos de muchos usuarios que migrar.

### Dos bucles de juego para un mismo juego ✔
- **Evidencia:** `game_session_provider` con `game_screen.dart` (1.273 líneas) y `speed_session_provider` con `speed_game_screen.dart` (525 líneas) implementan por separado «sonar, esperar respuesta, evaluar, siguiente».
- **Consecuencia:** el doble envío y los temporizadores que siguen vivos al salir se encontraron y se arreglaron dos veces, una en cada bucle. Y las dos pantallas se comportan distinto: una envía al tocar y la otra pide «Confirmar».
- **Corrección:** un solo motor de ronda con el temporizador como opción. `game_screen.dart` debería quedar por debajo de 400 líneas, solo con interfaz.

### Reglas de negocio repartidas por los widgets ✔
- El estado de dominio de una nota se calcula en cinco sitios (lista en `docs/design_v2_2/SPEC_mejora_v2_2.md`, lote B).
- «Quién es Pro» se decide en el cliente (`subscription_access.dart`) y otra vez en el servidor, con reglas distintas. De esa diferencia salió el bloqueo de la sync.
- **Corrección:** cada regla en una función pura, con tests, y los widgets solo la consultan. El permiso lo decide el servidor y el cliente lo lee.

### Código viejo y nuevo conviviendo ✔
- Hay carpetas `home_v2`, `progress_v2` y `session_v2` junto a widgets anteriores que siguen en uso (`note_srs_detail_card.dart`, `session_history_card.dart`, `togesc_ui.dart`).
- El XP se sigue calculando, guardando y exportando en cinco ficheros, y no se muestra en ninguna pantalla.
- El andamiaje de traducciones (`lib/l10n`) existe y casi no se usa: los textos están escritos en los widgets.
- **Corrección:** al mergear, quitar el sufijo `_v2`, borrar lo sustituido y el XP, y decidir si hay traducciones: o se usan o se borra el andamiaje.

### Dependencias atrasadas ✔
- Ocho PR de Dependabot abiertos desde el 2026-06-16, sin atender.
- Saltos mayores pendientes: `flutter_riverpod` 2 → 3, `go_router` 14 → 17, `flutter_soloud` 2 → 4 y `purchases_flutter` 8 → 10.
- `intl: any` acepta cualquier versión.
- `version: 1.0.0+1` no se ha movido nunca, así que no hay forma de saber qué versión tiene un usuario.
- **Corrección:** mergear los cuatro de bajo riesgo ya; planificar los mayores uno a uno después del merge grande; subir la versión en cada despliegue.

### Rendimiento
- El audio se sintetiza en el hilo de la interfaz y la congela de 0,4 a 0,7 s por ronda en web (medido en el QA del front).
- Las fuentes se descargan de Google al arrancar (`google_fonts`), en vez de ir dentro de la app. Afecta a la carga, al uso sin red y a la privacidad.

## Seguridad y operación
Lo ya conocido sigue abierto: SEC-006, SEC-008 y el webhook de Stripe que no valida el pago. Nuevo en esta auditoría:

- **Sigue sin haber un backup con datos.** ✔ Falta el secret `BACKUP_PASSPHRASE`.
- **Cualquiera puede llenar la tabla de analítica.** El rol anónimo puede insertar sin límite. Con el plan gratuito, eso puede agotar la cuota.
- **Las migraciones se aplican a mano y hay cosas hechas desde el panel.** ✔ La función `rls_auto_enable` existe en producción y no está en el repo. No hay entorno de pruebas: todo se aplica directamente en producción.
- **El MCP de Supabase está conectado con permiso de escritura sobre producción.** Es cómodo y peligroso. Para el día a día conviene el modo de solo lectura.
- **La protección contra contraseñas filtradas está desactivada.** ✔
- **Vercel tiene dos caminos de build.** `vercel.json` clona Flutter `stable` sin fijar versión, aunque hoy no se usa porque `ignoreCommand` lo salta. Conviene borrarlo para que no engañe.
- **Borrar la cuenta no cancela la suscripción.**

## Legal y privacidad
No soy abogado; estos puntos son para revisarlos con uno antes de publicar en tiendas.

- **Analítica sin consentimiento.** La app envía `app_open`, `mode_started` y `round_completed` con el identificador del usuario desde el arranque, sin pedir permiso ni ofrecer desactivarlo. Con interfaz en español, es razonable esperar usuarios en la UE.
- **Fuentes de Google en tiempo de ejecución.** Cada arranque envía la IP del usuario a Google. Incluir las fuentes en la app lo evita.
- **Términos de uso.** Existe una política de privacidad dentro de la app; no encontré términos de uso ni condiciones de la suscripción (inferido: no lo busqué a fondo).
- **Textos de suscripción.** El paywall habla de «14 días gratis» y de cancelar. Las tiendas exigen textos concretos sobre precio y renovación.

## Diseño y UX
El detalle está en la evaluación del 2026-11-09 (5,5/10). Las tres decisiones de fondo:

- **Se diseña desde el prototipo y no desde el usuario.** El flujo ha sido: prototipo HTML, especificación, implementación fiel. El cumplimiento del SPEC es de 8/10 y la experiencia de un usuario común, de 4/10. Eso indica que el fallo está en lo que se pide, no en cómo se ejecuta.
- **El primer resultado castiga.** Un solo fallo pinta una nota de rojo con «0 % Crítica». Es el momento en que un usuario nuevo decide si vuelve.
- **No hay motivo para volver.** El Home no cambia después de practicar y no hay hitos. Los recordatorios, que son el mecanismo principal de retorno, no existen en web.

## Calidad y pruebas
- **874 tests no han evitado bugs graves.** ✔ Con «Reducir animaciones» activado, las pantallas quedaban invisibles, y eso pasó con 680 tests en verde. Los tests comprueban piezas; nadie comprueba la app entera en un dispositivo.
- **Los tests están atados a los textos.** ✔ Cambiar el vocabulario en el lote A rompió 42 tests. Conviene buscar por clave y no por texto.
- **46 tests en skip** documentan bugs conocidos sin arreglar. Está bien como registro, pero es deuda.
- **Nunca se ha probado** con un lector de pantalla, en un móvil real ni con audio real.
- **La CI no comprueba** el formato, la cobertura mínima, que la web compile, las migraciones ni las Edge Functions.

## La forma de trabajar
Este es el hallazgo más incómodo, y me incluye.

- **Hay más documentos que producto entregado.** ✔ 29 ficheros en `Plan/` y 17 informes en `docs/auditoria/`, con planes que se solapan: `plan_fases`, `plan_recuperacion`, las hojas de ruta de v2 y v2.1, `impeccable_*`, `partitura_viva_*`, `stitch_*` y ahora v2.2. No hay un único sitio que diga qué va primero.
- **El ciclo se repite:** auditoría, plan, arreglo parcial, nueva auditoría. Solo en esta sesión se han escrito seis documentos más, este incluido. Auditar es más cómodo que publicar, y da sensación de avance.
- **Los agentes de IA producen mucho y muy deprisa.** Eso hace barato construir y documentar, y por eso mismo es fácil construir de más. Ningún agente sustituye a un usuario real.
- **Corrección:** un solo `ROADMAP.md` con un máximo de cinco líneas activas. Los demás planes pasan a un archivo. Regla: no se abre una auditoría nueva hasta cerrar los puntos críticos de la anterior.

## Plan propuesto

### Primero: que lo hecho llegue a alguien
1. Crear `BACKUP_PASSPHRASE` y hacer el primer backup con datos.
2. Hacer el repo privado.
3. Fijar una sola versión de Flutter y poner la CI en verde.
4. Mergear el PR #9 y desplegar.
5. Retirar las Edge Functions de pago de producción.

### Después: aprender de usuarios reales
6. Decidir la identidad del producto en una frase.
7. Hacer los lotes B y C de v2.2 (estados honestos y primera sesión). Son los que cambian la primera impresión.
8. Probar la app con 5 a 10 músicos aficionados, observando sin ayudar.
9. Medir si vuelven: cuántos abren la app al día siguiente y a la semana.

### Más adelante: solo si los usuarios vuelven
10. Registro de intentos como fuente de verdad.
11. Un solo motor de ronda.
12. Dependencias mayores.
13. Pagos, con las vulnerabilidades cerradas, cuando haya demanda.

**Qué no hacer ahora:** más rediseño visual (lote E), más plataformas, más modos, más auditorías.

## Límites de esta auditoría
- No se ejecutó la app ni se probó en ningún dispositivo.
- La configuración nativa de iOS y Android se miró por encima.
- Los puntos legales y la afirmación sobre el oído absoluto necesitan a un especialista.
- Los datos de uso son los de la base de datos el 2026-11-10. Puede haber usuarios que practican sin cuenta y sin analítica, y esos no se ven.
- Las líneas marcadas como «inferido» no están comprobadas.
