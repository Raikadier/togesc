/// Perfil de intensidad del algoritmo SRS (Fase 7E-2).
enum SrsIntensityProfile {
  relaxed(
    'Relajado',
    'Intervalos mas largos; ideal para repaso ligero.',
    1.35,
    6,
  ),
  balanced(
    'Equilibrado',
    'Ritmo recomendado para la mayoria.',
    1.0,
    5,
  ),
  intense(
    'Intenso',
    'Revisiones mas frecuentes; maximo progreso.',
    0.75,
    4,
  );

  const SrsIntensityProfile(
    this.label,
    this.description,
    this.intervalScale,
    this.learningThreshold,
  );

  final String label;
  final String description;

  /// Multiplicador de dias entre revisiones (>1 = mas espaciado).
  final double intervalScale;

  /// Aciertos consecutivos para graduar de aprendizaje a consolidacion.
  final int learningThreshold;

  static SrsIntensityProfile fromId(String? raw) {
    return SrsIntensityProfile.values.firstWhere(
      (profile) => profile.name == raw,
      orElse: () => SrsIntensityProfile.balanced,
    );
  }
}
