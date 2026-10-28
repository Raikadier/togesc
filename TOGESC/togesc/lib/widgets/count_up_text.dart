import 'package:flutter/material.dart';

import '../app/design_tokens.dart';

/// Número que cuenta de 0 a [value] (SPEC v2.1 §1.2): 900 ms con
/// *ease-out cubic*. Con movimiento reducido muestra el valor final.
///
/// [format] convierte el valor intermedio en texto («68 %», «12/20»). Si
/// [value] cambia, cuenta desde el valor mostrado hasta el nuevo.
/// [semanticsLabel] (si se da) se lee en lugar del número; si no, el lector
/// lee siempre el valor final, nunca los intermedios.
class CountUpText extends StatelessWidget {
  const CountUpText({
    super.key,
    required this.value,
    this.format = _defaultFormat,
    this.style,
    this.textAlign,
    this.duration = defaultDuration,
    this.semanticsLabel,
  });

  final double value;
  final String Function(double value) format;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Duration duration;
  final String? semanticsLabel;

  static const Duration defaultDuration = Duration(milliseconds: 900);

  static String _defaultFormat(double v) => v.round().toString();

  @override
  Widget build(BuildContext context) {
    final finalText = format(value);
    return Semantics(
      label: semanticsLabel ?? finalText,
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: motionDuration(context, duration),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) =>
            Text(format(v), style: style, textAlign: textAlign),
      ),
    );
  }
}
