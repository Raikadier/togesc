/// Constantes de configuracion de audio.
library;

const int defaultSampleRate = 44100;
const double defaultDuration = 1.0;
const double fadeDuration = 0.05; // 50ms fade in/out
const double maxAmplitude = 0.5;

// Configuracion del cluster (sonido caotico)
const double clusterDuration = 3.0;
const double clusterMinFreq = 100.0;
const double clusterMaxFreq = 4000.0;
const int clusterNumTones = 50;

// Configuracion de octavas
const int minOctaveShift = 0;
const int maxOctaveShift = 1;
