# ECC assets — instalación local sin plugin

- **Origen:** paquete npm `ecc-universal@2.2.3`
- **Licencia:** MIT (ver `ECC-LICENSE.txt`)
- **Fecha de instalación:** 2026-10-20
- **Destino:** `D:\Github repos\togesc\.opencode\`
- **Motivo:** el plugin `ecc-universal` no carga en OpenCode 2.1.1 (V2). Depende de `@opencode-ai/plugin` (ausente) y usa la API V1 de plugins. El paquete además publica un `dist/index.js` que re-exporta `./plugins/index.js`, archivo que no existe en el tarball.

## Contenido

| Tipo | Cantidad | Ruta |
|---|---:|---|
| Skills | 293 ECC + 1 override | `.opencode/skills/<id>/SKILL.md` |
| Commands | 94 | `.opencode/commands/*.md` |
| Agents | 68 | `.opencode/agents/*.md` |
| Licencia | 1 | `.opencode/ECC-LICENSE.txt` |

Tamaño total: **5,21 MB** (750 archivos; 585 dentro de `skills/`, incluidos scripts, referencias y el override local).

## Transformaciones aplicadas

### Agents

- Se eliminó `model: sonnet|haiku|opus`. V2 exige `provider/model`; los agentes ahora heredan el modelo del padre.
- Se eliminó `tools:` (allowlist de V1) y se tradujo solo a denegaciones:
  - **40** agentes sin `Write`/`Edit` → `edit: deny`.
  - **15** agentes sin `Bash` → `shell: deny`.
  - **42** agentes tienen al menos una regla; **13** tienen ambas.
  - **26** agentes no tienen reglas (tenían `Write`, `Edit` y `Bash`).
- Se añadió `mode: subagent` a los 68 para que no aparezcan como agentes primarios.

**Limitación:** no se reproduce la allowlist completa de ECC. Las herramientas no listadas (`webfetch`, `websearch`, `subagent`, MCP) siguen permitidas por la política por defecto de V2. Si se necesita el confinamiento original, hay que añadir reglas explícitas.

**Limitación:** al quitar `model`, agentes que ECC asignaba a `opus` (por ejemplo, revisores de seguridad) heredan el modelo de la sesión. En una sesión con un modelo barato, eso degrada la calidad del agente.

### Commands

- Frontmatter reducido a los campos que V2 interpreta: `description`, `agent`, `model`, `subagent`.
- `subtask: true` → `subagent: true` (1 archivo).
- `agent: ecc:security-reviewer` → `agent: security-reviewer` (el ID con prefijo `ecc:` no existe; los agentes se cargan como `<nombre>.md`).
- Claves descartadas por no tener equivalente en V2:
  - `argument-hint` (12)
  - `name` (9)
  - `command` (8)
  - `allowed-tools` (2)
  - `disable-model-invocation` (2)

**Limitación:** `allowed-tools` restringía las herramientas del command. V2 no tiene ese campo: el command hereda los permisos del agente que lo ejecuta.

### Skills

- Copiadas literalmente, sin cambios, salvo el override local de `systematic-bug-debugger` (ver «Curación aplicada»).
- El ID es el nombre del directorio; el `name` del frontmatter es solo una etiqueta visible.
- **Catálogo real descubierto: 925 IDs únicos** (293 ECC + 659 en `~/.agents/skills` + 48 en `~/.claude/skills` + `impeccable` + built-ins). Antes de curar, sus descripciones sumaban **269.734 caracteres ≈ 67.400 tokens por step**. El problema no era ECC: el catálogo global ya era el doble de grande.
- **Curación aplicada:** allowlist project-scoped en `.opencode/opencode.json` (`skill: *` → `deny`, seguido de 20 reglas `allow`). Quedan visibles 19 skills de disco + `opencode` built-in: **6.922 caracteres ≈ 1.730 tokens**.
- **Agentes:** 30 ocultos con `hidden: true` y 38 visibles; los visibles suman 7.355 caracteres ≈ 1.838 tokens.
- **Coste fijo después de la curación: ~3.700 tokens por step**, frente a ~67.400 antes. Es una reducción del ~94,5 %.

## Curación aplicada (2026-10-20)

### Skills

La allowlist está en `.opencode/opencode.json`:

```json
"permissions": [
  { "action": "skill", "resource": "*", "effect": "deny" },
  { "action": "skill", "resource": "dart-flutter-patterns", "effect": "allow" },
  ...
]
```

Las reglas se evalúan en orden y gana la última que coincide. El `deny` inicial oculta **todas** las fuentes (ECC, `~/.agents`, `~/.claude`, built-ins) y las `allow` reabren solo estas 20:

`dart-flutter-patterns`, `flutter-dart-code-review`, `systematic-bug-debugger`, `verification-before-completion`, `incremental-change-surgeon`, `tdd-workflow`, `ai-regression-testing`, `code-review`, `architecture-decision-records`, `github-ops`, `ci-cd-pipeline-validator`, `supabase`, `supabase-postgres-best-practices`, `database-migrations`, `security-review`, `security-first`, `stripe-billing-scaffold`, `accessibility`, `impeccable`, `opencode`.

**Para reactivar una skill:** añadir su regla `allow` después del `deny` y reiniciar el servicio de OpenCode. No hace falta editar `SKILL.md`.
**Para ocultarla de nuevo:** borrar su regla `allow`. El `deny` vuelve a aplicar.
**No usar `metadata.opencode/autoinvoke: false`:** la allowlist ya cubre todas las fuentes y es reversible sin tocar 293 archivos.

### Agentes

Se ocultaron 30 agentes irrelevantes para el stack (Java, Kotlin, Swift, PHP, C#, Go, Rust, C++, Django, FastAPI, React, Vue, redes, health, MLE, GAN, etc.) con `hidden: true`. Los 38 visibles incluyen todos los que referencian los 94 commands copiados, para no romperlos: `flutter-reviewer`, `dart-build-resolver`, `security-reviewer`, `code-reviewer`, `tdd-guide`, etc.

**Para reactivar un agente:** eliminar `hidden: true` de su frontmatter. `hidden` solo lo quita del catálogo de subagentes; no cambia permisos ni borra el archivo.

### Override de `systematic-bug-debugger`

La copia global (`~/.agents/skills/systematic-bug-debugger/SKILL.md`) tiene YAML inválido: `description: Trigger: debug this...` contiene dos puntos sin comillas. Se creó `.opencode/skills/systematic-bug-debugger/SKILL.md` con la descripción entre comillas y el resto intacto. La precedencia project-local de `.opencode` hace que esta copia gane. Si se actualiza la global, hay que repetir el override.

## Referencias a Claude Code que V2 no tiene

Recuento sobre commands, agents y skills:

| Referencia | Apariciones |
|---|---:|
| `TodoWrite` | 4 |
| `AskUserQuestion` | 8 |
| `Task(` | 8 |
| `WebSearch` | 2 |

No es una dependencia masiva, pero algunas instrucciones piden herramientas que V2 no expone con ese nombre. El modelo tendrá que adaptarlas o fallarán llamadas concretas.

## Exclusiones

- `rules/` (122 `.md`), hooks, `plugins/`, `AGENTS.md` y `prompts/`: no aplicables o parte del plugin roto.
- `dist/`: artefacto roto del paquete; no se copió.

## Verificación realizada

- 293/293 skills con `SKILL.md` y `description`; 0 IDs duplicados; 584 archivos, idénticos en ruta y tamaño al origen.
- 94/94 commands con frontmatter válido, UTF-8 sin BOM.
- 68/68 agents con `mode: subagent`, sin `model:` ni `tools:`, UTF-8 sin BOM.
- 30/30 agentes ocultos con YAML válido; los 68 agents siguen parseando.
- La copia se reanudó tras un corte y se comparó archivo por archivo contra el origen (rutas + tamaños), no solo por existencia.
- `flutter analyze`: **No issues found** (2026-10-20, Flutter 3.47.7 / Dart 3.13.5).
- `flutter test --reporter expanded`: **519 passed, 1 skipped, 0 failed**. Los 16 fallos del plan del 2026-10-03 no reproducen en `feat/rediseno-v2`.
- **Riesgo abierto:** el CI fija Flutter 3.41.4 y la verificación local usó 3.47.7. Repetir con 3.41.4 (FVM) antes de cerrar R2.

## Desinstalación

```powershell
Remove-Item -Recurse -Force ".opencode\skills", ".opencode\commands", ".opencode\agents"
Remove-Item -Force ".opencode\ECC-LICENSE.txt", ".opencode\ECC-ASSETS.md"
```

No tocar `.opencode\opencode.json`: es la configuración MCP propia del proyecto.

## Nota sobre git

`.opencode/` está sin trackear y `.gitignore` no lo excluye. Son 5,21 MB de contenido de terceros (MIT). Dato comprobado: `.claude/` está en `.gitignore` y tiene **0 archivos trackeados**; el repo no vendoriza agentes. Por coherencia, la recomendación es no commitear los assets de ECC.

Commitear solo:

- `.opencode/opencode.json` (allowlist + MCP)
- `.opencode/ECC-ASSETS.md`
- `.opencode/ECC-LICENSE.txt`
- `.opencode/skills/systematic-bug-debugger/` (override local)

Y añadir a `.gitignore`:

```gitignore
.opencode/skills/*
!.opencode/skills/systematic-bug-debugger/
.opencode/commands/*
.opencode/agents/*
```

El patrón `.opencode/skills/*` (no `.opencode/skills/`) es necesario: Git no permite re-incluir un archivo si su directorio padre está excluido.

Cada clone tendrá que reinstalar ECC; la allowlist seguirá ocultando el catálogo global, pero las skills permitidas que solo existan en ECC no estarán disponibles hasta reinstalarlas. El manifiesto y la licencia quedan versionados para que la reinstalación sea reproducible.

**Otros directorios sin trackear que conviene decidir aparte:** `.agents/` (7,17 MB, biblioteca de agentes de terceros; no la descubre OpenCode salvo `impeccable`), `.tmp_stitch/` (2 MB, export temporal de Stitch), `.impeccable/` (1 archivo de superficie) y `skills-lock.json` (278 B, lock de `impeccable`). No los he tocado.

## Reinstalación reproducible

La ruta usada es la caché de npm (`...\ecc-universal@latest\...`), que puede desaparecer. Para fijar la versión:

```powershell
npm pack ecc-universal@2.2.3
```

Extraer el tarball y repetir la copia con las transformaciones de este documento.
