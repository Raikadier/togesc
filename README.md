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

- **Contexto del proyecto:** [Plan/project_context.txt](Plan/project_context.txt)
- **Plan de fases:** [Plan/plan_fases.txt](Plan/plan_fases.txt)

## Stack

| Capa | Tecnología |
|------|------------|
| Cliente | Flutter + Riverpod |
| Audio | flutter_soloud (nativo) / Web Audio API (web) |
| Persistencia | shared_preferences |
| Backend (futuro) | Supabase — solo cuando haya cuentas/sync |
| CI | GitHub Actions |
| Deploy web | Vercel |

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
