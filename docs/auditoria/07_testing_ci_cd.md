# Testing y CI/CD

Estándares: pirámide de tests, cobertura por capa, CI bloqueante, Conventional Commits, SemVer (qstd §2.6, §13.2).

> **Actualización 2026-07-26:** Deploy Web publicado en producción
> (`workflow_dispatch`). Falta observar CI→Deploy en push a `main`, tests
> SQL/Deno y E2E:
> [11_estado_pendiente_2026-07-26.md](11_estado_pendiente_2026-07-26.md).
>
> **Nota 2026-07-24:** Flutter fijado a 3.41.4, CI con cobertura, Deploy
> condicionado a CI. Ver [10_remediacion_2026-07-24.md](10_remediacion_2026-07-24.md).

## Lo que está bien (no tocar)
- **47 archivos de test** en pirámide real; 309+ tests en la última corrida local relevante.
- CI ejecuta `flutter analyze` y `flutter test --coverage`.
- Uptime check horario, backup Supabase semanal, Dependabot activos.
- Deploy Web a Vercel con artefacto prebuilt (run `30142644096`, alias
  `togesc.vercel.app`).

---

## INFRA-001 — `build-android.yml` inválido — CORREGIDO

- **Severidad:** ALTO · **Esfuerzo:** S · **Prioridad:** P0
- **Evidencia:** [`.github/workflows/build-android.yml:30`](../../.github/workflows/build-android.yml#L30): `if: ${{ secrets.ANDROID_KEYSTORE_BASE64 != '' }}`.
- **Estándar:** CI/CD reproducible.

### Problema (HECHO OBSERVADO)
El contexto `secrets` **no está disponible en expresiones `if`** de GitHub Actions. Esto invalida el workflow → la ejecución falla en 0s con "this run likely failed because of a workflow file issue". Además los secrets `ANDROID_KEYSTORE_*` no existen aún.

### Recomendación
Promover el secret a `env` a nivel job y condicionar sobre `env`:
```yaml
jobs:
  build-aab:
    env:
      HAS_KEYSTORE: ${{ secrets.ANDROID_KEYSTORE_BASE64 != '' }}
    steps:
      - name: Decode keystore
        if: ${{ env.HAS_KEYSTORE == 'true' }}
        run: ...
```

### Criterios de aceptación
- [x] La condición usa `env.HAS_KEYSTORE`.
- [ ] Observar una ejecución manual real.
- [ ] Documentado en `docs/mobile_release.md` qué secrets añadir para firmar.

---

## INFRA-002 — Doble build Vercel — CORREGIDO EN REPO

- **Severidad:** ALTO · **Esfuerzo:** S · **Prioridad:** P0
- **Evidencia:** [`vercel.json`](../../vercel.json) `buildCommand`: `./flutter/bin/flutter build web --release --no-wasm-dry-run --directory=TOGESC/togesc`. Log de Vercel: `Could not find an option named "--directory". ... exited with 64`.
- **Estándar:** deploy reproducible.

### Problema
`flutter build web` **no** acepta `--directory` (ese flag es de `flutter pub get`). Cada build nativo de Vercel falla (~48s) — visible como deploys "Error" alternados con los "Ready" (3s) que publica GitHub Actions con prebuilt. Producción funciona por el camino de GitHub Actions, pero el camino Vercel genera ruido y es una bomba de tiempo si se elimina el deploy por Actions.

### Recomendación (elegir una)
**A) Arreglar el build nativo:**
```json
"buildCommand": "cd TOGESC/togesc && ../../flutter/bin/flutter build web --release --no-wasm-dry-run",
"outputDirectory": "TOGESC/togesc/build/web"
```
**B) Desacoplar:** dejar solo el deploy por GitHub Actions (prebuilt) y desactivar el auto-build de Vercel (Git → "Ignored Build Step" o `vercel deploy --prebuilt`). Una sola ruta de verdad.

> Recomendado: **B** (menos superficie, ya funciona) salvo que se quiera redundancia.

### Criterios de aceptación
- [x] `vercel.json` ignora builds Git automáticos.
- [x] GitHub prebuilt es la ruta documentada.
- [x] Deploy depende de CI exitoso y usa el mismo SHA.
- [ ] Confirmar comportamiento en el dashboard de Vercel.

---

## DEP-001 — 8 PRs Dependabot major sin revisar

- **Severidad:** MEDIO · **Esfuerzo:** M · **Prioridad:** P1
- **Evidencia:** PRs #1–#8 abiertos desde 2026-06-16. `pubspec.yaml` fija majors antiguos: `flutter_riverpod ^2.5` (PR a 3.x), `flutter_soloud ^2.0` (PR a 4.x), `go_router ^14.0` (a 17.x), `purchases_flutter ^8.1` (a 10.x).

### Problema
Riverpod 2→3, SoLoud 2→4 y go_router 14→17 son **majors con breaking changes**. Mantenerlos sin resolver acumula deuda y riesgo de seguridad; mergearlos a ciegas rompería el build.

### Recomendación
- Resolver de menor a mayor riesgo: primero los de Actions (#1–#3) y `mocktail` (#4), luego go_router, luego Riverpod y SoLoud cada uno en su PR con su guía de migración y la suite verde.
- Hacerlo **después** de FE-001 (lint estricto) para detectar usos deprecados.

### Criterios de aceptación
- [ ] Cada bump major mergeado con tests verdes y revisión de migración.
- [ ] `pubspec.lock` actualizado; build web y (cuando aplique) Android OK.

---

## PROC-001 — Conventional Commits + CONTRIBUTING

- **Severidad:** BAJO · **Esfuerzo:** S · **Prioridad:** P2
- **Evidencia:** commits recientes en español narrativo ("Documenta Site URL...", "Corrige estado de sync...") — no siguen `feat:`/`fix:`/`docs:`.
- **Estándar:** Conventional Commits, SemVer (qstd §2.1, §12.5).

### Recomendación
- Adoptar `feat|fix|docs|refactor|test|chore|ci(scope): mensaje`.
- `CONTRIBUTING.md` con: cómo correr tests, lint, convención de ramas/commits, DoR/DoD del plan de fases.
- Opcional: commitlint en CI.

## Cobertura
CI genera y conserva `coverage/lcov.info` durante 14 días. Falta publicar el
porcentaje y aplicar umbrales: lógica crítica ≥80%, servicios ≥70%, widgets
core ≥60%.

## Pendiente de verificar
- ¿La rama `main` tiene branch protection exigiendo CI verde antes de merge? (no auditable sin settings del repo).
