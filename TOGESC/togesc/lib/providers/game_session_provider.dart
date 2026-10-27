import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/game_constants.dart';
import '../models/audio_preferences.dart';
import '../models/last_practice_session.dart';
import 'analytics_provider.dart';
import 'audio_preferences_provider.dart';
import 'audio_provider.dart';
import 'last_practice_provider.dart';
import 'practice_focus_provider.dart';
import 'srs_provider.dart';
import 'today_session_provider.dart';
import '../utils/note_pool.dart';
import '../utils/session_summary.dart';
import 'app_preferences_provider.dart';
import 'ui_preferences_provider.dart';

/// Estados posibles de la sesion de juego.
enum GameState { idle, listening, waitingForAnswer, showingResult, playingCluster }

/// Datos del resultado de una ronda.
class RoundResult {
  final bool isCorrect;
  final Set<String> correctNotes;
  final double responseTime;
  final Map<String, Map<String, dynamic>> srsChanges;

  /// Notas que respondió el usuario, en el orden enviado (rediseño v2).
  /// Permite «Era X, respondiste Y» y pintar en rojo la tecla errónea sin
  /// depender del estado de selección de la pantalla.
  final List<String> answerNotes;

  const RoundResult({
    required this.isCorrect,
    required this.correctNotes,
    required this.responseTime,
    required this.srsChanges,
    this.answerNotes = const [],
  });

  /// Notas respondidas que no estaban en la ronda (teclas en rojo).
  Set<String> get wrongNotes => answerNotes.toSet().difference(correctNotes);

  /// Notas de la ronda que el usuario no marcó.
  Set<String> get missedNotes => correctNotes.difference(answerNotes.toSet());
}

/// Estado completo de la sesion de juego.
class GameSessionState {
  final GameState state;
  final GameMode mode;
  final List<String> currentNotes;
  final int numNotes;
  /// null = preferencias globales; [AudioPreferences.sessionOverrideRandom] o id fijo.
  final String? sessionInstrumentOverride;
  final String? lastInstrument;
  final RoundResult? lastResult;
  final int roundsCompleted;
  final int correctRounds;
  final bool isPaused;
  final bool goalReached;

  /// Aciertos consecutivos en la sesión actual (chip «⚡ racha»).
  /// Sube con cada ronda correcta y vuelve a 0 con un fallo.
  final int currentStreak;

  /// Mejor racha de aciertos consecutivos de la sesión actual.
  final int bestStreak;

  /// Estado SRS de cada nota al empezar la sesión (resumen v2.1). `null`
  /// hasta la primera ronda con el SRS cargado.
  final Map<String, NoteSrsSnapshot>? srsSnapshot;

  /// Tiempo de respuesta medido de cada ronda respondida, en segundos
  /// (desde que empieza `answer` hasta el envío, sin pausas).
  final List<double> responseTimes;

  /// Notas que sonaron en las rondas respondidas.
  final Set<String> sessionNotes;

  const GameSessionState({
    this.state = GameState.idle,
    this.mode = GameMode.singleNote,
    this.currentNotes = const [],
    this.numNotes = 1,
    this.sessionInstrumentOverride,
    this.lastInstrument,
    this.lastResult,
    this.roundsCompleted = 0,
    this.correctRounds = 0,
    this.isPaused = false,
    this.goalReached = false,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.srsSnapshot,
    this.responseTimes = const [],
    this.sessionNotes = const {},
  });

  /// Tiempo medio de respuesta de la sesión; `null` sin respuestas medidas.
  double? get meanResponseTimeSec => averageResponseTimeSec(responseTimes);

  /// Precisión de la sesión en % (rondas acertadas / jugadas); `null` sin
  /// rondas jugadas.
  double? get sessionAccuracyPercent =>
      roundsCompleted > 0 ? (correctRounds / roundsCompleted) * 100 : null;

  GameSessionState copyWith({
    GameState? state,
    GameMode? mode,
    List<String>? currentNotes,
    int? numNotes,
    String? sessionInstrumentOverride,
    bool clearSessionInstrumentOverride = false,
    String? lastInstrument,
    RoundResult? lastResult,
    int? roundsCompleted,
    int? correctRounds,
    bool? isPaused,
    bool? goalReached,
    int? currentStreak,
    int? bestStreak,
    Map<String, NoteSrsSnapshot>? srsSnapshot,
    bool clearSrsSnapshot = false,
    List<double>? responseTimes,
    Set<String>? sessionNotes,
    bool clearLastResult = false,
  }) {
    return GameSessionState(
      state: state ?? this.state,
      mode: mode ?? this.mode,
      currentNotes: currentNotes ?? this.currentNotes,
      numNotes: numNotes ?? this.numNotes,
      sessionInstrumentOverride: clearSessionInstrumentOverride
          ? null
          : (sessionInstrumentOverride ?? this.sessionInstrumentOverride),
      lastInstrument: lastInstrument ?? this.lastInstrument,
      lastResult: clearLastResult ? null : (lastResult ?? this.lastResult),
      roundsCompleted: roundsCompleted ?? this.roundsCompleted,
      correctRounds: correctRounds ?? this.correctRounds,
      isPaused: isPaused ?? this.isPaused,
      goalReached: goalReached ?? this.goalReached,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      srsSnapshot:
          clearSrsSnapshot ? null : (srsSnapshot ?? this.srsSnapshot),
      responseTimes: responseTimes ?? this.responseTimes,
      sessionNotes: sessionNotes ?? this.sessionNotes,
    );
  }
}

/// Provider para la sesion de juego.
final gameSessionProvider =
    NotifierProvider<GameSessionNotifier, GameSessionState>(
        GameSessionNotifier.new);

class GameSessionNotifier extends Notifier<GameSessionState> {
  @override
  GameSessionState build() => const GameSessionState();

  void setMode(GameMode mode) {
    final fixed = fixedNoteCountForMode(mode);
    state = state.copyWith(
      mode: mode,
      state: GameState.idle,
      numNotes: fixed ?? randomMinNotes,
      roundsCompleted: 0,
      correctRounds: 0,
      goalReached: false,
      isPaused: false,
      currentStreak: 0,
      bestStreak: 0,
      clearLastResult: true,
      clearSrsSnapshot: true,
      responseTimes: const [],
      sessionNotes: const {},
    );
    ref.read(lastPracticeSessionProvider.notifier).record(
          mode: mode,
          kind: PracticeKind.game,
        );
  }

  void setSessionInstrumentOverride(String? overrideKey) {
    state = state.copyWith(
      sessionInstrumentOverride: overrideKey,
      clearSessionInstrumentOverride: overrideKey == null,
    );
  }

  Future<AudioPreferences> _readAudioPreferences() async {
    return ref.read(audioPreferencesProvider.future);
  }

  void _applyMasterVolume(AudioPreferences prefs) {
    ref.read(audioPlayerServiceProvider).setMasterVolume(prefs.masterVolume);
  }

  /// Calcula cuantas notas reproducir segun el modo.
  int _getNumNotes(GameMode mode) => noteCountForGameMode(mode);

  /// Inicia una nueva ronda: selecciona notas y reproduce audio.
  Future<void> startRound() async {
    final srsAsync = ref.read(srsSystemProvider);
    final srs = srsAsync.valueOrNull;
    if (srs == null) return;

    // Instantánea SRS de la sesión (una vez, antes de la primera ronda).
    if (state.srsSnapshot == null) {
      state = state.copyWith(
        srsSnapshot: snapshotSrs(
          ref.read(noteProgressSummariesProvider),
          learningThreshold: ref.read(srsLearningThresholdProvider),
        ),
      );
    }

    final numNotes = _getNumNotes(state.mode);
    final focusNote = ref.read(practiceFocusNoteProvider);
    final focusNotes = ref.read(practiceFocusNotesProvider);
    final appPrefs = await ref.read(appPreferencesProvider.future);
    // Nota única («practicar esta nota») restringe el pool; las notas de foco
    // de la sesión de hoy (D11) solo lo priorizan en parte de las rondas.
    final notePool = focusNote != null
        ? resolvePracticeNotePool(
            mode: state.mode,
            configuredPool: appPrefs.practiceNotePool,
            focusNote: focusNote,
          )
        : resolveFocusRoundPool(
            mode: state.mode,
            configuredPool: appPrefs.practiceNotePool,
            focusNotes: focusNotes,
            numNotes: numNotes,
            random: ref.read(practiceFocusRandomProvider),
          );
    final selectedNotes = srs.selectNotes(numNotes, notePool: notePool);

    state = state.copyWith(
      state: GameState.listening,
      currentNotes: selectedNotes,
      numNotes: numNotes,
      lastResult: null,
      isPaused: false,
      clearLastResult: true,
    );

    await ref.read(analyticsServiceProvider).modeStarted(
          state.mode.id.toString(),
          state.mode.displayName,
        );

    // Reproducir audio
    final audioService = ref.read(audioPlayerServiceProvider);
    final audioGen = ref.read(audioGeneratorProvider);
    final audioPrefs = await _readAudioPreferences();
    _applyMasterVolume(audioPrefs);
    final (frequencies, _) = audioGen.getNoteFrequencies(
      selectedNotes,
      varyOctaves: audioPrefs.octaveVariationEnabled,
    );
    final instrument = audioPrefs.playbackInstrument(
      sessionOverrideKey: state.sessionInstrumentOverride,
    );
    final instUsed = await audioService.playTones(
      frequencies,
      duration: audioPrefs.toneDurationSec,
      instrument: instrument,
    );

    state = state.copyWith(
      state: GameState.waitingForAnswer,
      lastInstrument: instUsed,
    );
  }

  /// Procesa la respuesta del usuario.
  Future<void> submitAnswer(List<String> answerNotes, double responseTime) async {
    final srsAsync = ref.read(srsSystemProvider);
    final srs = srsAsync.valueOrNull;
    if (srs == null) return;

    final correctNotesSet = state.currentNotes.toSet();
    final answerSet = answerNotes.toSet();
    final isCorrect = answerSet.length == correctNotesSet.length &&
        answerSet.containsAll(correctNotesSet);

    final correctIdentified = answerSet.intersection(correctNotesSet).toList();
    final wrongNotes = isCorrect ? <String>{} : answerSet.difference(correctNotesSet);

    final changes = srs.updateAfterResponse(
      notes: state.currentNotes,
      correctNotes: correctIdentified,
      wrongNotes: wrongNotes,
      responseTime: responseTime,
    );
    // El panel «Enfoque SRS» (1d) refleja la ronda al momento.
    markSrsChanged(ref);

    // Auto-save
    await ref.read(srsSystemProvider.notifier).saveProgress();

    final analytics = ref.read(analyticsServiceProvider);
    await analytics.roundCompleted(
      modeId: state.mode.id.toString(),
      correct: isCorrect,
    );

    final nextRounds = state.roundsCompleted + 1;
    final nextCorrect = state.correctRounds + (isCorrect ? 1 : 0);
    final appPrefs = await ref.read(appPreferencesProvider.future);
    final goal = appPrefs.practiceSessionPreferences.targetRounds;
    final reachedGoal = goal > 0 && nextRounds >= goal;
    final nextStreak = isCorrect ? state.currentStreak + 1 : 0;
    final nextBest =
        nextStreak > state.bestStreak ? nextStreak : state.bestStreak;

    state = state.copyWith(
      state: GameState.showingResult,
      roundsCompleted: nextRounds,
      correctRounds: nextCorrect,
      isPaused: false,
      goalReached: reachedGoal,
      currentStreak: nextStreak,
      bestStreak: nextBest,
      responseTimes: List.unmodifiable([...state.responseTimes, responseTime]),
      sessionNotes: Set.unmodifiable({
        ...state.sessionNotes,
        ...state.currentNotes,
      }),
      lastResult: RoundResult(
        isCorrect: isCorrect,
        correctNotes: correctNotesSet,
        responseTime: responseTime,
        srsChanges: changes,
        answerNotes: List.unmodifiable(answerNotes),
      ),
    );
  }

  void pauseRound() {
    if (state.state != GameState.waitingForAnswer || state.isPaused) return;
    state = state.copyWith(isPaused: true);
  }

  void resumeRound() {
    if (!state.isPaused) return;
    state = state.copyWith(isPaused: false);
  }

  /// Salta la ronda actual sin actualizar SRS.
  void skipRound() {
    if (state.state != GameState.waitingForAnswer &&
        state.state != GameState.listening) {
      return;
    }
    state = state.copyWith(
      state: GameState.idle,
      currentNotes: const [],
      isPaused: false,
      clearLastResult: true,
    );
  }

  /// Reproduce cluster de limpieza y vuelve a idle.
  Future<void> playCluster() async {
    final audioPrefs = await _readAudioPreferences();
    final reduceUi =
        ref.read(uiPreferencesProvider).valueOrNull?.reduceAnimations ?? false;
    final reduceSystem =
        PlatformDispatcher.instance.accessibilityFeatures.disableAnimations;
    // Reduced motion: salta el cluster (audio caotico + animacion).
    if (!audioPrefs.clusterEnabled || reduceUi || reduceSystem) {
      state = state.copyWith(state: GameState.idle);
      return;
    }

    state = state.copyWith(state: GameState.playingCluster);

    _applyMasterVolume(audioPrefs);
    final audioService = ref.read(audioPlayerServiceProvider);
    await audioService.playCluster(duration: audioPrefs.clusterDurationSec);

    state = state.copyWith(state: GameState.idle);
  }

  void reset() {
    state = const GameSessionState();
  }
}
