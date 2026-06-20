import 'dart:math';

import '../constants/notes.dart';
import '../constants/srs_constants.dart';
import '../models/note_data.dart';
import '../models/srs_intensity_profile.dart';
import 'progress_repository.dart';

/// Sistema de Repeticion Espaciada mejorado para entrenamiento de oido absoluto.
///
/// Implementa un algoritmo hibrido:
/// - Fase de aprendizaje: repeticiones frecuentes hasta 5 aciertos consecutivos
/// - Fase de consolidacion: intervalos crecientes basados en SM-2
/// - Priorizacion de notas vencidas que necesitan revision
class SRSSystem {
  final ProgressRepository? repository;
  final DateTime Function() _getNow;
  final Random _random;
  SrsIntensityProfile intensityProfile;

  Map<String, NoteData> _noteData = {};

  /// Acceso de solo lectura a los datos de las notas.
  Map<String, NoteData> get noteData => Map.unmodifiable(_noteData);

  SRSSystem({
    this.repository,
    this.intensityProfile = SrsIntensityProfile.balanced,
    DateTime Function()? clock,
    Random? random,
  })  : _getNow = clock ?? DateTime.now,
        _random = random ?? Random();

  /// Inicializa datos con valores por defecto para todas las notas.
  void _initializeData() {
    _noteData = {for (final note in notes.keys) note: NoteData()};
  }

  /// Carga progreso del repositorio. Si no hay, inicializa por defecto.
  Future<void> loadProgress() async {
    if (repository == null) {
      _initializeData();
      return;
    }

    final loaded = await repository!.load();
    if (loaded != null) {
      _noteData = loaded;
      // Asegurar que todas las notas existan
      for (final note in notes.keys) {
        _noteData.putIfAbsent(note, NoteData.new);
      }
    } else {
      _initializeData();
    }
  }

  /// Guarda progreso al repositorio.
  Future<void> saveProgress() async {
    if (repository == null) return;
    await repository!.save(_noteData, lastSession: _getNow().toIso8601String());
  }

  /// Obtiene notas que estan "vencidas" (necesitan revision).
  List<String> getOverdueNotes() {
    final now = _getNow();
    final overdue = <String>[];

    for (final entry in _noteData.entries) {
      final nextReview = _parseDateTime(entry.value.nextReview);
      if (nextReview == null || now.isAfter(nextReview) || now.isAtSameMomentAs(nextReview)) {
        overdue.add(entry.key);
      }
    }

    _shuffle(overdue);
    return overdue;
  }

  /// Obtiene notas en fase de aprendizaje.
  List<String> getLearningNotes() {
    final learning = _noteData.entries
        .where((e) => e.value.isLearning)
        .map((e) => e.key)
        .toList();
    _shuffle(learning);
    return learning;
  }

  /// Selecciona notas basadas en el sistema SRS mejorado.
  ///
  /// Prioridad: overdue -> learning -> weighted random.
  List<String> selectNotes(int numNotes, {List<String>? notePool}) {
    final pool = notePool?.toSet() ?? notes.keys.toSet();

    if (numNotes > pool.length) {
      throw ArgumentError(
        'No se pueden seleccionar $numNotes notas unicas de ${pool.length}',
      );
    }

    final selected = <String>[];

    // 1. Notas vencidas (filtradas al pool)
    final overdue = getOverdueNotes().where((n) => pool.contains(n));
    for (final note in overdue) {
      if (selected.length >= numNotes) break;
      if (!selected.contains(note)) selected.add(note);
    }

    // 2. Notas en fase de aprendizaje (filtradas al pool)
    if (selected.length < numNotes) {
      final learning = getLearningNotes().where((n) => pool.contains(n));
      for (final note in learning) {
        if (selected.length >= numNotes) break;
        if (!selected.contains(note)) selected.add(note);
      }
    }

    // 3. Muestreo ponderado por peso (fallback)
    if (selected.length < numNotes) {
      final available = _noteData.keys
          .where((n) => !selected.contains(n) && pool.contains(n))
          .toList();
      final weights = available.map((n) => _noteData[n]!.weight).toList();

      while (selected.length < numNotes && available.isNotEmpty) {
        final note = _weightedChoice(available, weights);
        selected.add(note);
        final idx = available.indexOf(note);
        available.removeAt(idx);
        weights.removeAt(idx);
      }
    }

    _shuffle(selected);
    return selected;
  }

  /// Actualiza el sistema SRS despues de una respuesta del usuario.
  Map<String, Map<String, dynamic>> updateAfterResponse({
    required List<String> notes,
    required List<String> correctNotes,
    Set<String>? wrongNotes,
    double responseTime = 0.0,
  }) {
    final changes = <String, Map<String, dynamic>>{};
    final now = _getNow();
    final wrongNotesSet = wrongNotes ?? <String>{};
    final correctNotesSet = correctNotes.toSet();

    for (final note in notes) {
      final data = _noteData[note]!;
      final wasCorrect = correctNotesSet.contains(note);

      // Contadores basicos
      data.timesSeen += 1;
      data.lastSeen = now.toIso8601String();

      final oldData = {
        'weight': data.weight,
        'ease_factor': data.easeFactor,
        'consecutive_correct': data.consecutiveCorrect,
        'interval_index': data.intervalIndex,
        'is_learning': data.isLearning,
      };

      if (wasCorrect) {
        data.timesCorrect += 1;
        data.consecutiveCorrect += 1;

        // Actualizar peso (sistema antiguo)
        final timeFactor = max(0.0, responseTime - fastResponseThreshold);
        final decreaseFactor = max(
          srsMinDecrease,
          srsDecreaseBase - (timeFactor * srsDecreaseFactor),
        );
        data.weight = max(minNoteWeight, data.weight * decreaseFactor);

        // Actualizar ease_factor (SM-2)
        if (responseTime < fastResponseThreshold) {
          data.easeFactor = min(maxEaseFactor, data.easeFactor + easeFactorBonus);
        }

        _scheduleNextReview(note, wasCorrect: true);
      } else {
        // Respuesta incorrecta - olvido
        data.consecutiveCorrect = 0;

        // Actualizar peso (sistema antiguo)
        data.weight = min(maxNoteWeight, data.weight * srsIncreaseFactor);

        // Penalizar ease_factor
        data.easeFactor = max(minEaseFactor, data.easeFactor - easeFactorPenalty);

        // Reiniciar fase de aprendizaje si es necesario
        if (!data.isLearning) {
          data.intervalIndex = max(0, data.intervalIndex - forgetPenaltySteps);
          if (data.intervalIndex < 2) {
            data.isLearning = true;
          }
        }

        _scheduleNextReview(note, wasCorrect: false);
      }

      // Verificar graduacion
      if (data.isLearning &&
          data.consecutiveCorrect >= intensityProfile.learningThreshold) {
        data.isLearning = false;
        data.intervalIndex = 0;
        _scheduleNextReview(note, wasCorrect: true);
      }

      changes[note] = {
        'was_correct': wasCorrect,
        'old': oldData,
        'new': {
          'weight': data.weight,
          'ease_factor': data.easeFactor,
          'consecutive_correct': data.consecutiveCorrect,
          'interval_index': data.intervalIndex,
          'is_learning': data.isLearning,
          'next_review': data.nextReview,
        },
      };
    }

    // Penalizar notas incorrectas mencionadas que no estaban en el ejercicio
    final notesSet = notes.toSet();
    for (final wrongNote in wrongNotesSet) {
      if (!notesSet.contains(wrongNote) && _noteData.containsKey(wrongNote)) {
        _noteData[wrongNote]!.weight = min(
          maxNoteWeight,
          _noteData[wrongNote]!.weight * srsWrongNoteFactor,
        );
      }
    }

    return changes;
  }

  /// Calcula y programa la proxima revision para una nota.
  void _scheduleNextReview(String note, {required bool wasCorrect}) {
    final data = _noteData[note]!;
    final now = _getNow();

    DateTime nextDate;

    if (data.isLearning) {
      if (data.consecutiveCorrect == 0) {
        nextDate = now.add(Duration(days: _scaleIntervalDays(intervalLearning1)));
      } else if (data.consecutiveCorrect == 1) {
        nextDate = now.add(Duration(days: _scaleIntervalDays(intervalLearning2)));
      } else {
        final days = data.consecutiveCorrect >= intensityProfile.learningThreshold
            ? reviewIntervals[0]
            : 7;
        nextDate = now.add(Duration(days: _scaleIntervalDays(days)));
      }
    } else {
      // Fase de consolidacion
      if (!wasCorrect) {
        data.intervalIndex = max(0, data.intervalIndex - forgetPenaltySteps);
      }

      final baseInterval = reviewIntervals[
          min(data.intervalIndex, reviewIntervals.length - 1)];
      final days = (baseInterval * data.easeFactor).toInt();
      nextDate = now.add(Duration(days: _scaleIntervalDays(days)));

      if (wasCorrect && data.intervalIndex < reviewIntervals.length - 1) {
        data.intervalIndex += 1;
      }
    }

    data.nextReview = nextDate.toIso8601String();
  }

  /// Obtiene recomendaciones sobre que notas practicar.
  Map<String, dynamic> getPracticeRecommendations() {
    final now = _getNow();
    final overdue = getOverdueNotes();
    final learning = getLearningNotes();

    // Tiempo desde ultima sesion
    DateTime? lastSession;
    for (final data in _noteData.values) {
      if (data.lastSeen != null) {
        final dt = _parseDateTime(data.lastSeen);
        if (dt != null && (lastSession == null || dt.isAfter(lastSession))) {
          lastSession = dt;
        }
      }
    }

    final daysSinceSession =
        lastSession != null ? now.difference(lastSession).inDays : 0;

    // Notas criticas (muy vencidas)
    final critical = <(String, int)>[];
    for (final note in overdue) {
      final nextReview = _parseDateTime(_noteData[note]!.nextReview);
      if (nextReview != null) {
        final daysOverdue = now.difference(nextReview).inDays;
        if (daysOverdue >= 3) {
          critical.add((note, daysOverdue));
        }
      }
    }

    return {
      'total_overdue': overdue.length,
      'critical_notes': critical,
      'learning_notes_count': learning.length,
      'days_since_last_session': daysSinceSession,
      'recommended_notes':
          overdue.isNotEmpty ? overdue.take(5).toList() : learning.take(5).toList(),
      'message': _generateRecommendationMessage(
        overdue.length,
        critical.length,
        daysSinceSession,
      ),
    };
  }

  String _generateRecommendationMessage(
    int overdueCount,
    int criticalCount,
    int daysSince,
  ) {
    if (criticalCount > 5) {
      return 'Tienes $criticalCount notas muy atrasadas. Es momento de una sesion de recuperacion!';
    } else if (overdueCount > 10) {
      return 'Tienes $overdueCount notas pendientes de revision.';
    } else if (daysSince >= 3) {
      return 'Han pasado $daysSince dias desde tu ultima sesion. Es el momento optimo para practicar!';
    } else if (overdueCount > 0) {
      return 'Tienes $overdueCount notas listas para revisar.';
    } else {
      return 'Estas al dia! Practica las notas en fase de aprendizaje para avanzar.';
    }
  }

  /// Obtiene estadisticas completas del sistema SRS.
  Map<String, dynamic> getStatistics() {
    final weightsList = _noteData.values.map((d) => d.weight).toList();

    final sortedByWeight = _noteData.entries.toList()
      ..sort((a, b) => b.value.weight.compareTo(a.value.weight));

    final learningCount = _noteData.values.where((d) => d.isLearning).length;
    final graduatedCount = _noteData.length - learningCount;

    final totalSeen = _noteData.values.fold<int>(0, (s, d) => s + d.timesSeen);
    final totalCorrect = _noteData.values.fold<int>(0, (s, d) => s + d.timesCorrect);
    final accuracy = totalSeen > 0 ? totalCorrect / totalSeen * 100 : 0.0;

    final overdue = getOverdueNotes();

    return {
      'total_notes': _noteData.length,
      'average_weight': weightsList.reduce((a, b) => a + b) / weightsList.length,
      'max_weight': weightsList.reduce(max),
      'min_weight': weightsList.reduce(min),
      'hardest_notes': sortedByWeight.take(3).map((e) => e.key).toList(),
      'easiest_notes': sortedByWeight.reversed.take(3).map((e) => e.key).toList(),
      'learning_phase': learningCount,
      'graduated': graduatedCount,
      'total_seen': totalSeen,
      'total_correct': totalCorrect,
      'accuracy_percentage': (accuracy * 10).round() / 10.0,
      'overdue_count': overdue.length,
      'overdue_notes': overdue.take(5).toList(),
    };
  }

  /// Reinicia todos los datos a valores por defecto.
  Future<void> resetProgress() async {
    _initializeData();
    await saveProgress();
  }

  // --- Helpers ---

  int _scaleIntervalDays(int days) {
    final scaled = (days * intensityProfile.intervalScale).round();
    return max(1, scaled);
  }

  DateTime? _parseDateTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return null;
    return DateTime.tryParse(isoString);
  }

  void _shuffle(List<String> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
  }

  String _weightedChoice(List<String> items, List<double> weights) {
    final total = weights.reduce((a, b) => a + b);
    var r = _random.nextDouble() * total;
    for (var i = 0; i < items.length; i++) {
      r -= weights[i];
      if (r <= 0) return items[i];
    }
    return items.last;
  }
}
