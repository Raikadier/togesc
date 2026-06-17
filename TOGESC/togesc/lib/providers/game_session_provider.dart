import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/game_constants.dart';
import '../constants/notes.dart';
import '../models/audio_preferences.dart';
import '../models/last_practice_session.dart';
import 'analytics_provider.dart';
import 'audio_preferences_provider.dart';
import 'audio_provider.dart';
import 'last_practice_provider.dart';
import 'practice_focus_provider.dart';
import 'srs_provider.dart';

/// Estados posibles de la sesion de juego.
enum GameState { idle, listening, waitingForAnswer, showingResult, playingCluster }

/// Datos del resultado de una ronda.
class RoundResult {
  final bool isCorrect;
  final Set<String> correctNotes;
  final double responseTime;
  final Map<String, Map<String, dynamic>> srsChanges;

  const RoundResult({
    required this.isCorrect,
    required this.correctNotes,
    required this.responseTime,
    required this.srsChanges,
  });
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

  const GameSessionState({
    this.state = GameState.idle,
    this.mode = GameMode.singleNote,
    this.currentNotes = const [],
    this.numNotes = 1,
    this.sessionInstrumentOverride,
    this.lastInstrument,
    this.lastResult,
  });

  GameSessionState copyWith({
    GameState? state,
    GameMode? mode,
    List<String>? currentNotes,
    int? numNotes,
    String? sessionInstrumentOverride,
    bool clearSessionInstrumentOverride = false,
    String? lastInstrument,
    RoundResult? lastResult,
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
      lastResult: lastResult ?? this.lastResult,
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

    final numNotes = _getNumNotes(state.mode);
    final focusNote = ref.read(practiceFocusNoteProvider);
    List<String>? notePool;
    if (state.mode == GameMode.sharpsOnly) {
      notePool = sharpNotes;
    } else if (focusNote != null && notes.containsKey(focusNote)) {
      notePool = [focusNote];
    }
    final selectedNotes = srs.selectNotes(numNotes, notePool: notePool);

    state = state.copyWith(
      state: GameState.listening,
      currentNotes: selectedNotes,
      numNotes: numNotes,
      lastResult: null,
    );

    await ref.read(analyticsServiceProvider).modeStarted(
          state.mode.id.toString(),
          state.mode.displayName,
        );

    // Reproducir audio
    final audioService = ref.read(audioPlayerServiceProvider);
    final audioGen = ref.read(audioGeneratorProvider);
    final (frequencies, _) = audioGen.getNoteFrequencies(selectedNotes);

    final audioPrefs = await _readAudioPreferences();
    _applyMasterVolume(audioPrefs);
    final instrument = audioPrefs.playbackInstrument(
      sessionOverrideKey: state.sessionInstrumentOverride,
    );
    final instUsed = await audioService.playTones(
      frequencies,
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

    // Auto-save
    await ref.read(srsSystemProvider.notifier).saveProgress();

    final analytics = ref.read(analyticsServiceProvider);
    await analytics.roundCompleted(
      modeId: state.mode.id.toString(),
      correct: isCorrect,
    );

    state = state.copyWith(
      state: GameState.showingResult,
      lastResult: RoundResult(
        isCorrect: isCorrect,
        correctNotes: correctNotesSet,
        responseTime: responseTime,
        srsChanges: changes,
      ),
    );
  }

  /// Reproduce cluster de limpieza y vuelve a idle.
  Future<void> playCluster() async {
    final audioPrefs = await _readAudioPreferences();
    if (!audioPrefs.clusterEnabled) {
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
