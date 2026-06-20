// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Entrenador de Oido Absoluto';

  @override
  String get srsIntensityTitle => 'Intensidad SRS';

  @override
  String get srsIntensitySubtitle =>
      'Ajusta la frecuencia de repaso entre sesiones.';

  @override
  String get microphoneModeTitle => 'Modo canto (experimental)';

  @override
  String get microphoneModeWebHint =>
      'Canta o tararea la nota. El audio no se sube a internet.';

  @override
  String get microphoneModeMobileHint =>
      'Disponible en web. En movil usa piano o texto por ahora.';

  @override
  String get microphoneListen => 'Escuchar nota';

  @override
  String get microphoneStop => 'Detener microfono';
}
