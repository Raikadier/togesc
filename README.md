# Entrenador de Oído Absoluto (TOGESC)

Aplicación multiplataforma en **Flutter** para entrenar el oído absoluto con repetición espaciada (SRS), variación de octavas y timbres, y limpieza tonal entre ejercicios.

## Inicio rápido

```bash
cd TOGESC/togesc
flutter pub get
flutter run
```

Plataformas soportadas: Android, iOS, Web, Windows, Linux, macOS.

## Tests

```bash
cd TOGESC/togesc
flutter analyze
flutter test
```

## Estructura del repositorio

```
togesc/
├── Plan/
│   ├── project_context.txt   # Contexto y decisiones del proyecto
│   ├── plan_fases.txt        # Roadmap por fases
│   └── contexto.txt          # Plan histórico de migración a Flutter
└── TOGESC/togesc/            # Código de la aplicación (Flutter)
    ├── lib/                  # UI, providers, servicios, modelos
    └── test/                 # unit, widget, integration, e2e
```

## Características

- Modos: una nota, intervalo, acorde, aleatorio, velocidad
- SRS híbrido (pesos + SM-2) con persistencia local
- Síntesis de audio en cliente (`flutter_soloud`)
- Piano interactivo + entrada por texto
- Estadísticas y recomendaciones de práctica

## Documentación

- **System design:** [Plan/system_design.md](Plan/system_design.md)
- **IA y vistas GUI:** [Plan/gui_information_architecture.md](Plan/gui_information_architecture.md)
- **Contexto del proyecto:** [Plan/project_context.txt](Plan/project_context.txt)
- **Plan de fases:** [Plan/plan_fases.txt](Plan/plan_fases.txt)
- **Supabase (Fase 4):** [docs/supabase_setup.md](docs/supabase_setup.md)
- **QA manual:** [docs/qa_checklist.md](docs/qa_checklist.md)
- **Release móvil:** [docs/mobile_release.md](docs/mobile_release.md)

## Stack

| Capa | Tecnología |
|------|------------|
| Cliente | Flutter + Riverpod |
| Audio | flutter_soloud (nativo) / Web Audio API (web) |
| Persistencia | shared_preferences (+ sync opcional Supabase) |
| Backend (opcional) | Supabase Auth + Postgres (RLS) — ver docs/supabase_setup.md |
| CI | GitHub Actions |
| Deploy web | Vercel |

## Versión actual

**v1.0.0** — [Lanzamiento web](https://github.com/Raikadier/togesc/releases/tag/v1.0.0) · **App:** https://togesc.vercel.app

Gratis. Entrena sin cuenta; la sincronización en la nube es opcional (proyecto Supabase `togesc`).

## Deploy web (Vercel)

**Producción:** https://togesc.vercel.app

El repo incluye:
- `.github/workflows/ci.yml` — `flutter analyze` + `flutter test` en cada push/PR
- `.github/workflows/deploy-web.yml` — build web + deploy a Vercel en push a `main` (requiere secret `VERCEL_TOKEN` en GitHub)
- `vercel.json` — build remoto alternativo (clone Flutter + `flutter build web`)

Preview local:

```bash
cd TOGESC/togesc
flutter build web --release
```

## Licencia

Proyecto educativo de código abierto.
