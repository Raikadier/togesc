import 'package:flutter/widgets.dart';

/// Factor de «Texto más grande» (SPEC v2.1 §1.3).
const double largeTextScaleFactor = 1.125;

/// Escalado efectivo: el del sistema [base] y, si [largeText], ×1,125 encima.
///
/// No se usa `TextScaler.linear(base.textScaleFactor * 1.125)` porque el
/// escalado del sistema puede ser no lineal (Android 14) y se perdería.
TextScaler applyLargeText(TextScaler base, {required bool largeText}) {
  if (!largeText) return base;
  return _LargeTextScaler(base);
}

@immutable
class _LargeTextScaler extends TextScaler {
  const _LargeTextScaler(this.base);

  final TextScaler base;

  @override
  double scale(double fontSize) => base.scale(fontSize) * largeTextScaleFactor;

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => base.textScaleFactor * largeTextScaleFactor;

  @override
  bool operator ==(Object other) =>
      other is _LargeTextScaler && other.base == base;

  @override
  int get hashCode => Object.hash(_LargeTextScaler, base);

  @override
  String toString() => 'largeText($base)';
}
