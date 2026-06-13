import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/game_constants.dart';
import '../constants/notes.dart';
import 'audio_provider.dart';
import 'srs_provider.dart';

/// Estados de la sesion de velocidad.
enum SpeedState { idle, playing, waitingForAnswer, correct, incorrect, timeout, gameOver }

/// Estado de la sesion de velocidad.
class SpeedSessionState {
  final SpeedState state;
  final GameMode targetMode;
  final double currentTimeLimit;
  final double remainingTime;
  final List<String> currentNotes;
  final int numNotes;
  final int consecutiveCorrect;
  final List<double> responseTimes;
  final bool useRandomInstrument;

  const SpeedSessionState({
    this.state = SpeedState.idle,
    this.targetMode = GameMode.singleNote,
    this.currentTimeLimit = speedInitialTime,
    this.remainingTime = speedInitialTime,
    this.currentNotes = const [],
    this.numNotes = 1,
    this.consecutiveCorrect = 0,
    this.responseTimes = const [],
    this.useRandomInstrument = true,
  });

  double get averageTime =>
      responseTimes.isEmpty ? 0 : responseTimes.reduce((a, b) => a + b) / responseTimes.length;

  double get bestTime =>
      responseTimes.isEmpty ? 0 : responseTimes.reduce(min);

  SpeedSessionState copyWith({
    SpeedState? state,
    GameMode? targetMode,
    double? currentTimeLimit,
    double? remainingTime,
    List<String>? currentNotes,
    int? numNotes,
    int? consecutiveCorrect,
    List<double>? responseTimes,
    bool? useRandomInstrument,
  }) {
    return SpeedSessionState(
      state: state ?? this.state,
      targetMode: targetMode ?? this.targetMode,
      currentTimeLimit: currentTimeLimit ?? this.currentTimeLimit,
      remainingTime: remainingTime ?? this.remainingTime,
      currentNotes: currentNotes ?? this.currentNotes,
      numNotes: numNotes ?? this.numNotes,
      consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
      responseTimes: responseTimes ?? this.responseTimes,
      useRandomInstrument: useRandomInstrument ?? this.useRandomInstrument,
    );
  }
}

/// Provider para la sesion de velocidad.
final speedSessionProvider =
    NotifierProvider<SpeedSessionNotifier, SpeedSessionState>(
        SpeedSessionNotifier.new);

class SpeedSessionNotifier extends Notifier<SpeedSessionState> {
  Timer? _countdownTimer;

  @override
  SpeedSessionState build() {
    ref.onDispose(() => _countdownTimer?.cancel());
    return const SpeedSessionState();
  }

  void setTargetMode(GameMode mode) {
    state = state.copyWith(targetMode: mode);
  }

  int _getNumNotes(GameMode mode) {
    switch (mode) {
      case GameMode.singleNote:
        return 1;
      case GameMode.interval:
        return 2;
      case GameMode.chord:
        return 3;
      case GameMode.random:
        return Random().nextInt(randomMaxNotes) + randomMinNotes;
      case GameMode.sharpsOnly:
        return 1;
      default:
        return 1;
    }
  }

  /// Inicia una ronda de velocidad.
  Future<void> startRound() async {
    final srsAsync = ref.read(srsSystemProvider);
    final srs = srsAsync.valueOrNull;
    if (srs == null) return;

    final numNotes = _getNumNotes(state.targetMode);
    final notePool = state.targetMode == GameMode.sharpsOnly ? sharpNotes : null;
    final selectedNotes = srs.selectNotes(numNotes, notePool: notePool);

    state = state.copyWith(
      state: SpeedState.playing,
      currentNotes: selectedNotes,
      numNotes: numNotes,
      remainingTime: state.currentTimeLimit,
    );

    // Reproducir audio
    final audioService = ref.read(audioPlayerServiceProvider);
    final audioGen = ref.read(audioGeneratorProvider);
    final (frequencies, _) = audioGen.getNoteFrequencies(selectedNotes);
    final instrument = state.useRandomInstrument ? null : 'sine';
    await audioService.playTones(frequencies, instrument: instrument);

    // Iniciar countdown
    state = state.copyWith(state: SpeedState.waitingForAnswer);
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    final startTime = DateTime.now();

    _countdownTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds / 1000;
      final remaining = state.currentTimeLimit - elapsed;

      if (remaining <= 0) {
        timer.cancel();
        state = state.copyWith(
          state: SpeedState.timeout,
          remainingTime: 0,
        );
        return;
      }

      state = state.copyWith(remainingTime: remaining);
    });
  }

  /// Procesa respuesta en modo velocidad.
  void submitAnswer(List<String> answerNotes, double responseTime) {
    _countdownTimer?.cancel();

    if (state.state == SpeedState.timeout) return;

    final correctNotesSet = state.currentNotes.toSet();
    final answerSet = answerNotes.toSet();
    final isCorrect = answerSet.length == correctNotesSet.length &&
        answerSet.containsAll(correctNotesSet);

    final newTimes = [...state.responseTimes, responseTime];

    if (isCorrect) {
      final newLimit = (state.currentTimeLimit - speedCorrectDecrease)
          .clamp(speedMinTime, speedMaxTime);
      state = state.copyWith(
        state: SpeedState.correct,
        consecutiveCorrect: state.consecutiveCorrect + 1,
        currentTimeLimit: newLimit,
        responseTimes: newTimes,
      );
    } else {
      state = state.copyWith(
        state: SpeedState.incorrect,
        responseTimes: newTimes,
      );
    }
  }

  /// Reinicia la sesion para reintentar.
  void retry() {
    _countdownTimer?.cancel();
    state = state.copyWith(
      state: SpeedState.idle,
      currentTimeLimit: speedInitialTime,
      remainingTime: speedInitialTime,
      consecutiveCorrect: 0,
      responseTimes: const [],
    );
  }

  void reset() {
    _countdownTimer?.cancel();
    state = const SpeedSessionState();
  }
}
