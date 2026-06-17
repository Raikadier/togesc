import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:togesc/app/design_tokens.dart';

void main() {
  group('DesignTokens', () {
    test('primaryContainer matches marca Stitch', () {
      expect(DesignTokens.primaryContainer, const Color(0xFF6A1B9A));
    });

    test('background matches Harmonic Precision', () {
      expect(DesignTokens.background, const Color(0xFFFFF7FC));
    });

    test('feedback colors match piano semantics', () {
      expect(DesignTokens.correct, const Color(0xFF2E7D32));
      expect(DesignTokens.incorrect, const Color(0xFFC62828));
      expect(DesignTokens.selection, const Color(0xFFFFB300));
    });

    test('touch target and radius match design system', () {
      expect(DesignTokens.touchTargetMin, 48);
      expect(DesignTokens.radiusMd, 12);
    });
  });
}
