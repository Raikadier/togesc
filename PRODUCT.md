# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

Personas que quieren **adquirir** oído absoluto (audiencia principal) y personas que ya lo tienen y quieren **mantener** precisión, velocidad y generalización (timbres, octavas, contextos polifónicos).

Situación típica: práctica diaria o frecuente en móvil (o web), a menudo con auriculares, en sesiones cortas enfocadas en identificación de clases de altura — no en teoría musical genérica ni en quizzes de intervalos relativos.

## Product Purpose

**TOGESC** (nombre técnico) / **Entrenador de Oído Absoluto** (nombre de producto) entrena y consolida el oído absoluto con estrategias pedagógicas comprobadas: repetición espaciada (SRS), variación de estímulos y progresión real.

Éxito del producto: el usuario mejora de forma medible la identificación de las 12 clases de altura bajo variación de octava y timbre, con progreso que no se pierde al cerrar la app (persistencia local obligatoria; sync en nube opcional cuando hay cuenta).

## Positioning

No es un quiz genérico de intervalos. Es un **motor de entrenamiento** con SRS adaptativo, limpieza tonal entre ejercicios (cluster) y audio sintetizado en el dispositivo — la lógica pedagógica y el audio viven en el cliente para latencia baja.

## Operating Context

- Flujo de ronda: idle → escuchar tono(s) → seleccionar notas (piano / texto / mic según preferencias) → confirmar → resultado → cluster de limpieza → idle; SRS actualizado.
- Modos: una nota, intervalo, acorde (Pro), aleatorio (Pro), solo sostenidos, entrenamiento de velocidad (Pro).
- Idioma de UI: **español**.
- Plataformas: Flutter único para Android, iOS, web (y escritorio opcional).
- Cuenta y sync (Supabase) y suscripción Pro son capas de producto, no requisitos para practicar el núcleo free.

## Capabilities and Constraints

**Confirmado (código + `Plan/project_context.txt`):**
- Stack: Flutter + Riverpod + flutter_soloud + shared_preferences; SRS/audio/validación en Dart en el cliente.
- Design system incumbente: **Harmonic Precision** (Material 3, Hanken Grotesk, tokens en `TOGESC/togesc/lib/app/design_tokens.dart`).
- Mockups Stitch de referencia en `.tmp_stitch/stitch_togesc_design_system/` y briefs en `Plan/stitch_*.md`.
- Touch targets objetivo ≥ 48 dp; feedback semántico correct/incorrect/selection en piano.
- Preferencia `reduceAnimations` existe (impacto parcial en sesión).
- **Hub Home (decisión 2026-07-26):** enfoque académico. Daily Focus = notas críticas + CTA; racha solo como label secundario; **XP no se muestra en Home** (puede vivir en Stats/export más adelante). Tono coach, no alarma arcade. Modos: free visibles por defecto; Pro vía «Ver todos».

**Restricciones duraderas:**
- No reintroducir Python ni backend REST para lógica de juego/audio.
- No duplicar fronts (React + Flutter).
- Cambios de UI deben preservar identidad Harmonic Precision salvo decisión explícita de rediseño (Impeccable: refinement, no replacement).
- No reintroducir XP hero / cards de “racha y nivel” en el hub sin decisión explícita nueva.

**Abierto / no decidido:**
- Alcance de alineación pixel-perfect con PNG Stitch vs alineación de jerarquía/composición.

## Brand Commitments

- Nombre producto: Entrenador de Oído Absoluto; marca técnica TOGESC.
- Tono: educativo, claro, profesional; **sin gamificación excesiva** (brief Stitch / Harmonic Precision).
- Identidad visual vinculante: Harmonic Precision (púrpura musical `#6A1B9A` / primary `#4E0078`, fondo `#FFF7FC`, Hanken Grotesk). Documentada en `DESIGN.md`.
- UI en español (ortografía completa esperada: tildes, etc.).

## Evidence on Hand

- `Plan/project_context.txt`, `Plan/plan_fases.txt`, `Plan/stitch_design_brief.md`, `Plan/stitch_harmonic_precision_DESIGN.md`
- Implementación Flutter: `TOGESC/togesc/`
- Entregables Stitch (PNG + HTML): `.tmp_stitch/stitch_togesc_design_system/`
- No fabricar testimonios, rankings (“top 12%”) u otras claims de marketing Stitch si no existen en producto real.

## Product Principles

1. **La práctica primero** — cada pantalla Operate debe reducir fricción hacia escuchar y responder.
2. **Pedagogía visible** — SRS, variación y limpieza tonal deben sentirse serios, no arcade.
3. **Offline-first del núcleo** — el entrenamiento funciona sin cuenta; la nube mejora, no bloquea.
4. **Una identidad** — Harmonic Precision es la autoridad visual; Stitch informa composición, no inventa un segundo sistema.
5. **Latencia y claridad** — feedback auditivo/visual inmediato; copy en español preciso.

## Accessibility & Inclusion

- Objetivos de producto: targets ≥ 48 dp; contraste usable en light/dark; soporte a reducir animaciones; Semantics en controles críticos (piano ya avanzado).
- Estándar formal WCAG no fijado por escrito; tratar Material / buenas prácticas Flutter como piso mínimo.

---

### Notas de init (S0)

Escrito el 2026-07-26 a partir de evidencia del repositorio. El 2026-07-26 (S1) se cerró la decisión de hub académico (ver Capabilities).

### Notas S1 Home

Implementado: Daily Focus solo críticas; `PracticeStreakLabel`; XP oculto en Home; ModeBento con play visible y Semantics. Detalle en `Plan/impeccable_s1_log.md`.
