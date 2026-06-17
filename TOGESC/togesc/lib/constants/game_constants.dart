/// Constantes y modos de juego.
library;

import 'dart:math';

enum GameMode {
  singleNote(1, 'Una sola nota'),
  interval(2, 'Dos notas simultaneas (Intervalo)'),
  chord(3, 'Tres notas simultaneas (Acorde)'),
  random(4, 'Aleatorio (1 a 5 notas)'),
  sharpsOnly(5, 'Solo sostenidos (C#/Db, D#/Eb...)'),
  exit(6, 'Salir'),
  speedTraining(7, 'Entrenamiento de velocidad');

  const GameMode(this.id, this.displayName);

  final int id;
  final String displayName;

  static GameMode? fromId(int id) {
    for (final mode in values) {
      if (mode.id == id) return mode;
    }
    return null;
  }
}

// Limites para modo aleatorio
const int randomMinNotes = 1;
const int randomMaxNotes = 5;

/// Notas requeridas por modo fijo (null = aleatorio por ronda).
int? fixedNoteCountForMode(GameMode mode) {
  switch (mode) {
    case GameMode.singleNote:
    case GameMode.sharpsOnly:
      return 1;
    case GameMode.interval:
      return 2;
    case GameMode.chord:
      return 3;
    case GameMode.random:
      return null;
    default:
      return 1;
  }
}

/// Notas de una ronda segun modo (aleatorio elige en el momento).
int noteCountForGameMode(GameMode mode, {Random? random}) {
  final fixed = fixedNoteCountForMode(mode);
  if (fixed != null) return fixed;
  final rng = random ?? Random();
  return rng.nextInt(randomMaxNotes) + randomMinNotes;
}

// Configuracion del modo velocidad
const double speedInitialTime = 10.0;
const double speedMinTime = 3.0;
const double speedMaxTime = 15.0;
const double speedCorrectDecrease = 1.0;
const double speedWrongIncrease = 2.0;

// Archivo de persistencia
const String progressFile = 'progress.json';
