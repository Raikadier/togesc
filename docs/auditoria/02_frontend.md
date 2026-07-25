# Frontend y calidad de código

Estándares: Clean Code, SOLID, inmutabilidad, separación UI/estado/servicios (qstd §2, §11, §12).

## Lo que está bien (no tocar)
- **Separación de capas** real: UI (`screens/`,`widgets/`) → providers Riverpod → services → models/constants. Sin lógica de negocio en `build()` revisados.
- **`SRSSystem`** ([srs_system.dart](../../TOGESC/togesc/lib/services/srs_system.dart)): dominio puro sin dependencia de Flutter, con inyección de `DateTime Function()` y `Random` → determinista y testeable. Ejemplar.
- **Repository pattern**: `ProgressRepository` interface con impl local/remoto/híbrido intercambiables (DIP correcto).
- `noteData` expuesto como `Map.unmodifiable` (inmutabilidad de lectura).
- Naming consistente: `*_provider.dart`, `*_screen.dart`, `*_service.dart`/`*_system.dart`, `*_card.dart`.
- Split por plataforma correcto (`*_io.dart`/`*_web.dart`/`*_stub.dart`) para micrófono, audio web y export.

---

## FE-001 — `analysis_options` sin reglas estrictas

- **Severidad:** MEDIO · **Esfuerzo:** S · **Prioridad:** P1
- **Evidencia:** [`analysis_options.yaml`](../../TOGESC/togesc/analysis_options.yaml) solo incluye `package:flutter_lints/flutter.yaml`; bloque `rules:` vacío.
- **Estándar:** qstd §12.3 / §12.6 (Effective Dart, lint estricto).

### Recomendación
```yaml
include: package:flutter_lints/flutter.yaml
linter:
  rules:
    prefer_const_constructors: true
    prefer_const_constructors_in_immutables: true
    prefer_final_locals: true
    require_trailing_commas: true
    avoid_dynamic_calls: true
    prefer_single_quotes: true
    unawaited_futures: true
    use_super_parameters: true
analyzer:
  language:
    strict-casts: true
    strict-raw-types: true
  errors:
    invalid_annotation_target: ignore
```
> Trade-off: activar lints estrictos sobre 142 archivos generará warnings iniciales; resolver en un PR dedicado (regla Boy Scout) y luego hacer CI bloqueante.

### Criterios de aceptación
- [ ] `analysis_options.yaml` estricto versionado.
- [ ] `flutter analyze` sin issues nuevos.
- [ ] CI bloquea merge ante warnings (ver [07_testing_ci_cd.md](07_testing_ci_cd.md)).

---

## FE-002 — Higiene del repositorio

- **Severidad:** BAJO · **Esfuerzo:** S · **Prioridad:** P2
- **Evidencia:** `git status` muestra `.tmp_stitch/` y `docs/quality_standards.txt` sin trackear; existe además `stitch_export/` con ~30 artboards.

### Recomendación
- Añadir a `.gitignore`: `.tmp_stitch/` (temporal de Stitch).
- Decidir si `stitch_export/` debe versionarse (assets de diseño) o moverse a un repo/almacén de diseño.
- Commitear `docs/quality_standards.txt` y los `docs/auditoria/*` de esta auditoría.

### Criterios de aceptación
- [ ] `git status` limpio salvo trabajo en curso.
- [ ] `.gitignore` cubre artefactos temporales.

---

## Observaciones de código (estilo / menores)
- `getStatistics()` ([srs_system.dart:356](../../TOGESC/togesc/lib/services/srs_system.dart#L356)) usa `weightsList.reduce(...)` que lanza si la lista está vacía; hoy siempre hay 12 notas, pero un `reduce` sobre colección potencialmente vacía es frágil — preferir `fold` con semilla.
- `updateAfterResponse` devuelve `Map<String, Map<String, dynamic>>` con claves string ('weight', 'ease_factor', ...). Funciona, pero un objeto tipado (`SrsChange`) sería más seguro y autodocumentado (DDD: value object). No urgente.
- `ProRouteGuard` y otros widgets podrían usar `ref.watch(...).select(...)` para reducir rebuilds (ver [08_performance_motion.md](08_performance_motion.md)).

## Pendiente de verificar
- Revisión de `dispose()` de controladores/streams en pantallas con timers (modo velocidad) — ver performance.
