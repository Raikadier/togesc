/// Constantes del sistema SRS (Spaced Repetition System).
/// Sistema hibrido: pesos para priorizacion + SM-2 para intervalos.
library;

// Sistema de pesos (seleccion ponderada de notas)
const double defaultNoteWeight = 10.0;
const double minNoteWeight = 1.0;
const double maxNoteWeight = 50.0;
const double srsDecreaseBase = 1.0;
const double srsDecreaseFactor = 0.1;
const double srsMinDecrease = 0.2;
const double srsIncreaseFactor = 2.0;
const double srsWrongNoteFactor = 1.5;
const double fastResponseThreshold = 2.0; // segundos

// Sistema SM-2 (calculo de intervalos de repeticion)
// Fase de aprendizaje
const int learningPhaseThreshold = 5; // Aciertos consecutivos para graduacion

// Factores de facilidad (ease factor)
const double initialEaseFactor = 2.5;
const double minEaseFactor = 1.3;
const double maxEaseFactor = 2.5;
const double easeFactorBonus = 0.15;
const double easeFactorPenalty = 0.2;

// Intervalos base (en dias)
const int intervalLearning1 = 1; // Primer intervalo en fase de aprendizaje
const int intervalLearning2 = 3; // Segundo intervalo en fase de aprendizaje

// Intervalos de revision para fase de consolidacion (en dias)
const List<int> reviewIntervals = [1, 3, 7, 14, 30, 60, 120];

// Umbral para considerar una nota "vencida"
const double overdueThreshold = 1.5; // 150% del intervalo = vencida

// Penalizacion por olvido (reinicio de fase)
const int forgetPenaltySteps = 2; // Retroceder N intervalos al olvidar
