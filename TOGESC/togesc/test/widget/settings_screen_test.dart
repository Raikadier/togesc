import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:togesc/models/audio_preferences.dart';
import 'package:togesc/providers/audio_provider.dart';
import 'package:togesc/screens/settings_screen.dart';
import 'package:togesc/services/app_preferences.dart';
import 'package:togesc/services/audio_generator.dart';
import 'package:togesc/services/audio_player_service.dart';
import 'package:togesc/widgets/piano_keyboard.dart';

/// El AudioPlayerService real no termina en tests: este no suena.
class _SilentAudio extends AudioPlayerService {
  _SilentAudio() : super(generator: AudioGenerator(random: Random(3)));

  int plays = 0;

  @override
  bool get isInitialized => true;

  @override
  void captureUserGesture() {}

  @override
  Future<bool> waitUntilReady() async => true;

  @override
  Future<void> playBuffer(Float64List samples, {int? sampleRate}) async {
    plays++;
  }
}

Future<_SilentAudio> _pump(WidgetTester tester, {Size? size}) async {
  await tester.binding.setSurfaceSize(size ?? const Size(420, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final audio = _SilentAudio();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [audioPlayerServiceProvider.overrideWithValue(audio)],
      child: const MaterialApp(home: SettingsScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return audio;
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<AppPreferences> _prefs() async =>
    AppPreferences(await SharedPreferences.getInstance());

/// Ajustes v2.1 (SPEC §2.8): 5 grupos, accesibilidad primero.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('5 grupos en orden, con la accesibilidad primero', (
    tester,
  ) async {
    await _pump(tester);

    const order = [
      'settings-a11y',
      'settings-session',
      'settings-sound',
      'settings-appearance',
      'settings-more',
    ];
    final tops = [
      for (final k in order) tester.getTopLeft(find.byKey(ValueKey(k))).dy,
    ];
    for (var i = 1; i < tops.length; i++) {
      expect(tops[i], greaterThan(tops[i - 1]), reason: order[i]);
    }
    expect(find.text('Práctica y accesibilidad'), findsOneWidget);
  });

  testWidgets('en escritorio los grupos van en 2 columnas', (tester) async {
    await _pump(tester, size: const Size(1280, 1000));

    final a11y = tester.getTopLeft(find.byKey(const ValueKey('settings-a11y')));
    final sound = tester.getTopLeft(
      find.byKey(const ValueKey('settings-sound')),
    );
    expect(sound.dx, greaterThan(a11y.dx));
    expect(sound.dy, closeTo(a11y.dy, 1));
  });

  testWidgets('«Texto más grande» se guarda', (tester) async {
    await _pump(tester);
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('settings-large-text')),
    );

    expect((await _prefs()).uiPreferences.largeText, isTrue);
  });

  testWidgets('la vista previa del piano refleja «Ocultar etiquetas» en vivo', (
    tester,
  ) async {
    await _pump(tester);
    final preview = find.byKey(const ValueKey('settings-piano-preview'));
    PianoKeyboard piano() => tester.widget<PianoKeyboard>(
      find.descendant(of: preview, matching: find.byType(PianoKeyboard)),
    );
    expect(piano().hideLabels, isFalse);

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('settings-hide-labels')),
    );
    expect(piano().hideLabels, isTrue);

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('settings-large-piano')),
    );
    expect(piano().large, isTrue);
  });

  testWidgets('elegir un timbre lo fija y suena una preescucha', (
    tester,
  ) async {
    final audio = await _pump(tester);
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('settings-timbre-violin')),
    );

    final audioPrefs = (await _prefs()).audioPreferences;
    expect(audioPrefs.instrumentMode, InstrumentMode.fixed);
    expect(audioPrefs.fixedInstrumentId, 'violin');
    expect(audio.plays, 1);
  });

  testWidgets('el volumen muestra su valor en texto', (tester) async {
    await _pump(tester);
    final value = find.byKey(const ValueKey('settings-volume-value'));
    await tester.ensureVisible(value);
    expect(tester.widget<Text>(value).data, endsWith('%'));
  });

  testWidgets('«Restablecer ajustes» pide confirmación en una hoja', (
    tester,
  ) async {
    await _pump(tester);
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('settings-large-text')),
    );
    expect((await _prefs()).uiPreferences.largeText, isTrue);

    await _tapVisible(tester, find.byKey(const ValueKey('settings-reset')));
    expect(find.byKey(const ValueKey('settings-reset-sheet')), findsOneWidget);
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('settings-reset-confirm')),
    );

    expect((await _prefs()).uiPreferences.largeText, isFalse);
    expect(find.text('Ajustes restablecidos.'), findsOneWidget);
  });
}
