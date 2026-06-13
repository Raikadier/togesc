# Análisis Depurativo del Proyecto "Entrenador de Oído Absoluto"

## Resumen Ejecutivo

Este análisis identifica múltiples problemas en el proyecto que podrían causar errores en tiempo de ejecución, comportamientos inesperados o dificultades de mantenimiento. Los problemas van desde errores de importación críticos hasta inconsistencias lógicas en el algoritmo SRS.

---

## 🚨 Problemas Críticos

### 1. Error de Importación en main.py (Bloqueante)

**Ubicación**: [`main.py`](main.py:33)

**Problema**: La línea `from entrenador_oido.core.game import GameController` asume que el proyecto se ejecuta como un paquete con el nombre `entrenador_oido`, pero `main.py` está en la raíz del proyecto, no dentro de un directorio del paquete.

**Código problemático**:
```python
# Agregar directorio padre al path para imports
sys.path.insert(0, str(Path(__file__).parent.parent))
from entrenador_oido.core.game import GameController
```

**Impacto**: 
- Si se ejecuta `python main.py` directamente, fallará con `ModuleNotFoundError`
- El `sys.path.insert` apunta al directorio padre del proyecto, lo cual es incorrecto

**Solución recomendada**:
```python
# Usar imports relativos o ajustar la estructura
from core.game import GameController
```

---

### 2. Referencia a Constantes Inexistentes

**Ubicación**: [`ui/cli.py`](ui/cli.py:27)

**Problema**: Se importan constantes `RANDOM_MIN_NOTES` y `RANDOM_MAX_NOTES` que no existen en `constants.py`.

**Código problemático**:
```python
from ..constants import (
    ENHARMONICS,
    GameMode,
    RANDOM_MAX_NOTES,  # NO EXISTE
    RANDOM_MIN_NOTES,  # NO EXISTE
)
```

**Impacto**: ImportError al ejecutar la aplicación.

**Solución**: Reemplazar con los valores correctos del archivo constants.py:
```python
from ..constants import (
    ENHARMONICS,
    GameMode,
)
# Y en el código usar directamente los valores 1 y 5
```

---

## ⚠️ Problemas de Lógica y Diseño

### 3. Lógica Condicional Incorrecta en SRS

**Ubicación**: [`core/srs.py`](core/srs.py:376)

**Problema**: La condición `if note in wrong_notes and note not in notes:` nunca será verdadera porque `wrong_notes` ya es un subconjunto de `notes` evaluado anteriormente.

**Código problemático**:
```python
# Penalizar notas incorrectas mencionadas
if note in wrong_notes and note not in notes:
    data.weight = min(MAX_NOTE_WEIGHT, data.weight * SRS_WRONG_NOTE_FACTOR)
```

**Contexto**: Este código está dentro del bucle `for note in notes:`, por lo tanto `note` siempre está en `notes`, haciendo que la segunda condición sea siempre falsa.

**Solución**: Esta lógica debería estar fuera del bucle o reestructurarse completamente para penalizar notas incorrectas que el usuario mencionó pero que no estaban en el ejercicio.

---

### 4. Inconsistencia en el Cálculo de Respuesta Correcta

**Ubicación**: [`core/game.py`](core/game.py:141-146)

**Problema**: El sistema considera una respuesta correcta solo si el conjunto de notas coincide exactamente. Esto significa que si el usuario acierta algunas notas pero no todas, se considera incorrecto, pero el SRS actualiza las notas individualmente.

**Código**:
```python
answer_set = set(answer_notes)
is_correct = answer_set == correct_notes_set

# Calcular notas correctas identificadas y notas incorrectas mencionadas
correct_identified = list(answer_set & correct_notes_set)
wrong_notes = answer_set - correct_notes_set if not is_correct else set()
```

**Problema potencial**: Si el usuario acierta 2 de 3 notas, `is_correct` es False, pero las 2 notas correctas se procesan como "correctas" en el SRS, mientras que conceptualmente deberían marcarse como parcialmente correctas.

---

### 5. Problema en la Lógica de Tiempo de Respuesta

**Ubicación**: [`ui/cli.py`](ui/cli.py:108-136)

**Problema**: El método `get_input_with_timeout` tiene comportamiento inconsistente entre plataformas y el tiempo medido incluye el tiempo de impresión del prompt.

**Código problemático**:
```python
def get_input_with_timeout(self, prompt: str, timeout: Optional[float] = None) -> Tuple[str, float]:
    print(prompt, end="", flush=True)  # Esto está ANTES de medir el tiempo
    start_time = time.time()  # El tiempo incluye la impresión
```

**Impacto**: El tiempo de respuesta no es preciso, especialmente en sistemas lentos.

---

## 🐛 Problemas de Manejo de Errores

### 6. Excepción Silenciada en Limpieza de Buffer Unix

**Ubicación**: [`ui/cli.py`](ui/cli.py:102-103)

**Problema**: Los errores en la limpieza del buffer en Unix se capturan pero solo se registran con nivel DEBUG, lo que puede ocultar problemas reales.

**Código**:
```python
except Exception as e:
    logger.debug(f"No se pudo limpiar buffer en Unix: {e}")
```

**Problema**: Esto podría causar comportamientos extraños en la entrada del usuario sin que el desarrollador lo sepa.

---

### 7. Falta de Validación de Datos al Cargar Progreso

**Ubicación**: [`core/srs.py`](core/srs.py:122-159)

**Problema**: Al cargar datos del archivo JSON, no se valida que los valores sean del tipo correcto antes de usarlos. Un archivo corrupto podría causar errores difíciles de diagnosticar.

**Ejemplo de riesgo**:
```python
# Si el JSON tiene "weight": null, esto fallará silenciosamente
# o causará errores posteriores
weight=float(data.get("weight", DEFAULT_NOTE_WEIGHT)),
```

---

## 🔧 Problemas de Mantenibilidad

### 8. Duplicación de Código en Constantes

**Ubicación**: [`constants.py`](constants.py:42-51)

**Problema**: Existen dos sistemas de constantes SRS: el antiguo (líneas 42-51) y el nuevo basado en SM-2 (líneas 54-75). Esto causa confusión y mantenimiento dual.

**Recomendación**: Deprecar y eliminar las constantes del sistema antiguo si ya no se usan, o documentar claramente cuáles están en uso.

---

### 9. Imports Condicionales Sin Manejo de Fallback

**Ubicación**: [`audio/generator.py`](audio/generator.py:80-99)

**Problema**: Si `sounddevice` falla al inicializar, el sistema marca `audio_available = False`, pero no hay manera de reintentar o notificar al usuario más allá de un log.

**Mejora sugerida**: Agregar un método de diagnóstico más detallado.

---

## 📝 Problemas Menores

### 10. Docstring Desactualizado

**Ubicación**: [`main.py`](main.py:10)

**Problema**: El docstring menciona:
```python
"""
Uso:
    python -m entrenador_oido.main
"""
```

Pero esta forma de ejecutar no funcionará debido al problema de importación mencionado en el punto 1.

---

### 11. Inconsistencia en Nombres de Variables

**Ubicación**: [`core/srs.py`](core/srs.py:195-218)

**Problema**: La función `get_overdue_notes` devuelve una lista ordenada por prioridad, pero el nombre no refleja el ordenamiento. La tupla intermedia usa índices sin nombre:

```python
overdue.append((note, now, 0))  # ¿Qué significa cada valor?
```

**Mejora**: Usar una namedtuple o dataclass para claridad.

---

### 12. Lógica de Octavas Incompleta

**Ubicación**: [`audio/generator.py`](audio/generator.py:254-269)

**Problema**: La variación de octavas usa `random.randint(MIN_OCTAVE_SHIFT, MAX_OCTAVE_SHIFT)` donde ambos valores son 0 y 1 según [`constants.py`](constants.py:84-85):

```python
MIN_OCTAVE_SHIFT: Final[int] = 0
MAX_OCTAVE_SHIFT: Final[int] = 1
```

Esto significa que las notas solo se tocan en la octava 4 o 5, nunca en octavas inferiores.

**Nota**: Esto podría ser intencional para evitar frecuencias muy bajas, pero debería documentarse.

---

## 📊 Problemas de Rendimiento

### 13. Reordenamiento Ineficiente en `select_notes`

**Ubicación**: [`core/srs.py`](core/srs.py:277-282)

**Problema**: El uso de `random.choices` con `pop` en listas es O(n) por cada selección:

```python
while len(selected) < num_notes and available:
    note = random.choices(available, weights=weights, k=1)[0]
    selected.append(note)
    idx = available.index(note)  # Búsqueda O(n)
    available.pop(idx)           # Eliminación O(n)
    weights.pop(idx)             # Eliminación O(n)
```

**Impacto**: Para 12 notas, esto es negligible, pero la implementación no escala bien.

---

## 🔒 Problemas de Seguridad y Robustez

### 14. Ejecución de Comandos del Sistema sin Validación

**Ubicación**: [`ui/cli.py`](ui/cli.py:191)

**Problema**: Uso de `os.system()` para limpiar la pantalla:

```python
def clear_screen(self) -> None:
    os.system("cls" if sys.platform == "win32" else "clear")
```

**Riesgo**: Aunque en este caso es bajo porque el comando es fijo, `os.system` es generalmente inseguro y debería preferirse `subprocess.run` o una librería como `rich` que tiene soporte nativo para limpiar pantalla.

---

### 15. Exposición de Datos Internos

**Ubicación**: [`core/srs.py`](core/srs.py:114-115)

**Problema**: `note_data` es un diccionario mutable expuesto públicamente:

```python
self.note_data: Dict[str, NoteData] = {}
```

Cualquier código externo puede modificar directamente los datos del SRS sin pasar por los métodos de validación.

**Solución**: Hacerlo privado (`_note_data`) y exponer solo métodos de acceso controlado.

---

## 📋 Lista de Verificación de Correcciones

| # | Problema | Severidad | Archivo | Línea |
|---|----------|-----------|---------|-------|
| 1 | Importación incorrecta | Crítica | main.py | 33 |
| 2 | Constantes inexistentes | Crítica | ui/cli.py | 27 |
| 3 | Lógica condicional imposible | Alta | core/srs.py | 376 |
| 4 | Tiempo de respuesta impreciso | Media | ui/cli.py | 125 |
| 5 | Excepción silenciada | Media | ui/cli.py | 103 |
| 6 | Sin validación de datos de entrada | Media | core/srs.py | 136-151 |
| 7 | Duplicación de constantes | Baja | constants.py | 42-75 |
| 8 | Uso de os.system | Baja | ui/cli.py | 191 |
| 9 | Datos internos expuestos | Baja | core/srs.py | 115 |
| 10 | Algoritmo de selección ineficiente | Baja | core/srs.py | 277-282 |

---

## 🎯 Recomendaciones Prioritarias

1. **Corregir los problemas críticos 1 y 2** antes de cualquier ejecución
2. **Revisar y corregir la lógica del SRS** (problema 3) que actualmente nunca penaliza notas incorrectas
3. **Implementar validación de datos** al cargar el progreso
4. **Agregar tests unitarios** para el sistema SRS, especialmente para los casos de borde

---

## Diagrama de Dependencias Problemáticas

```
                    main.py
                      │
                      │ (import fallido)
                      ▼
            ┌─────────────────────┐
            │  entrenador_oido.*  │ ← No existe como paquete instalado
            └─────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
   core/game.py   ui/cli.py    audio/generator.py
        │             │                │
        └─────────────┴────────────────┘
                      │
                      ▼
              constants.py
                      │
                      ▼
            ┌─────────────────┐
            │  RANDOM_*_NOTES │ ← NO EXISTEN
            └─────────────────┘
```

---

*Análisis generado el: 2026-03-02*
*Versión del proyecto analizada: 2.0.0*
