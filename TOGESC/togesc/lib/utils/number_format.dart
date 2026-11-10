/// Formato de números y plurales para la UI en español (es-ES).
///
/// Único sitio donde se formatean decimales: coma decimal y espacio antes de
/// la unidad («33,3 %», «2,4 s»). No uses `toStringAsFixed` en widgets.
library;

/// «2,4» con coma decimal. Con [trimZeros], «3,0» → «3» y «1,50» → «1,5».
String formatDecimalEs(
  double value, {
  int decimals = 1,
  bool trimZeros = false,
}) {
  var text = value.toStringAsFixed(decimals);
  if (trimZeros && text.contains('.')) {
    text = text.replaceFirst(RegExp(r'\.?0+$'), '');
  }
  return text.replaceAll('.', ',');
}

/// «68,5 %» y «33 %»: un decimal como máximo y sin «,0».
String formatPercentEs(double value) =>
    '${formatDecimalEs(value, trimZeros: true)} %';

/// «2,4 s». Con [trimZeros], «3 s» en lugar de «3,0 s».
String formatSecondsEs(
  double seconds, {
  int decimals = 1,
  bool trimZeros = false,
}) => '${formatDecimalEs(seconds, decimals: decimals, trimZeros: trimZeros)} s';

/// «1 ronda» / «3 rondas». [many] se usa también para el cero.
String plural(int n, String one, String many) => '$n ${n == 1 ? one : many}';
