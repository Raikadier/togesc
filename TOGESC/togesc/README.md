# TOGESC — Entrenador de Oído Absoluto

App Flutter para practicar identificación de notas con SRS adaptativo.

## Ejecutar

```bash
flutter pub get
flutter run
```

## Tests

```bash
flutter analyze
flutter test
flutter test test/unit/
flutter test test/widget/
flutter test test/integration/
flutter test test/e2e/
```

## Arquitectura (`lib/`)

| Carpeta | Contenido |
|---------|-----------|
| `constants/` | Notas, SRS, audio, modos de juego |
| `models/` | NoteData, InstrumentPreset |
| `services/` | SRS, audio, parser, persistencia |
| `providers/` | Riverpod — sesión, SRS, audio |
| `screens/` | Home, juego, velocidad, estadísticas |
| `widgets/` | Piano, resultados, recomendaciones |

Documentación del proyecto: [../../Plan/project_context.txt](../../Plan/project_context.txt)
