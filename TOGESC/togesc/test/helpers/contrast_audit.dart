import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:togesc/app/design_tokens.dart';

/// Recorre cada texto e icono pintado bajo [root] y devuelve los que no
/// llegan a WCAG 2.2 AA frente al fondo opaco que tienen detrás.
///
/// - Texto normal: 4,5:1. Texto grande (≥ 24 px, o ≥ 18,66 px en negrita) e
///   iconos: 3:1.
/// - El fondo es el primer `Material`, `ColoredBox`, `DecoratedBox` o `Ink`
///   con color; los translúcidos se mezclan con lo que hay debajo.
/// - Se saltan los textos invisibles (opacidad 0 u `Offstage`), los que
///   están sobre un degradado (su fondo no se puede leer así), los de
///   controles desactivados (WCAG 1.4.3 los exime) y los iconos decorativos
///   dentro de `ExcludeSemantics`.
List<String> auditContrast(WidgetTester tester, {Finder? root}) {
  final failures = <String>[];
  final paragraphs = find.descendant(
    of: root ?? find.byType(MaterialApp),
    matching: find.byType(RichText),
  );
  for (final element in paragraphs.evaluate()) {
    final render = element.renderObject;
    if (render is! RenderParagraph || !render.hasSize) continue;
    final style = render.text.style;
    final text = render.text.toPlainText().trim();
    if (style?.color == null || text.isEmpty) continue;

    final isIcon = style!.fontFamily == 'MaterialIcons';
    final layers = <Color>[];
    var opacity = 1.0;
    var skip = false;
    element.visitAncestorElements((ancestor) {
      final widget = ancestor.widget;
      if (widget is Offstage && widget.offstage) skip = true;
      if (isIcon && widget is ExcludeSemantics && widget.excluding) {
        skip = true;
      }
      if (widget is ButtonStyleButton && !widget.enabled) skip = true;
      if (widget is ListTile && !widget.enabled) skip = true;
      if (widget is Opacity) opacity *= widget.opacity;
      if (widget is FadeTransition) opacity *= widget.opacity.value;
      final color = _backgroundOf(widget, () => skip = true);
      if (color != null) layers.add(color);
      return !skip && (layers.isEmpty || layers.last.a < 1);
    });
    if (skip || opacity == 0 || layers.isEmpty) continue;

    var background = layers.last;
    for (final layer in layers.reversed.skip(1)) {
      background = Color.alphaBlend(layer, background);
    }
    final fg = Color.alphaBlend(
      style.color!.withValues(alpha: style.color!.a * opacity),
      background,
    );
    final size = style.fontSize ?? 14;
    final bold = (style.fontWeight?.value ?? 400) >= 700;
    final large = size >= 24 || (size >= 18.66 && bold);
    final min = isIcon || large ? 3.0 : 4.5;
    final ratio = contrastRatio(fg, background);
    if (ratio < min) {
      final label = isIcon
          ? 'icono U+${text.runes.first.toRadixString(16)}'
          : '«$text»';
      failures.add(
        '$label ${ratio.toStringAsFixed(2)}:1 < $min '
        '(${_hex(fg)} sobre ${_hex(background)})',
      );
    }
  }
  return failures;
}

Color? _backgroundOf(Widget widget, VoidCallback onGradient) {
  Color? fromDecoration(Decoration? d) {
    if (d is BoxDecoration) {
      if (d.gradient != null) onGradient();
      return d.color;
    }
    if (d is ShapeDecoration) {
      if (d.gradient != null) onGradient();
      return d.color;
    }
    return null;
  }

  return switch (widget) {
    Material(:final type, :final color)
        when type != MaterialType.transparency && color != null =>
      color,
    ColoredBox(:final color) => color,
    DecoratedBox(:final decoration, :final position)
        when position == DecorationPosition.background =>
      fromDecoration(decoration),
    Ink(:final decoration) => fromDecoration(decoration),
    _ => null,
  };
}

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
