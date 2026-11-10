import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:togesc/models/ui_preferences.dart';
import 'package:togesc/providers/audio_provider.dart';
import 'package:togesc/providers/ui_preferences_provider.dart';
import 'package:togesc/screens/settings_screen.dart';

import 'qa_support.dart';

/// Preferencias de interfaz que no se pueden leer (disco corrupto, etc.).
class _FailingUiPreferences extends UiPreferencesNotifier {
  @override
  Future<UiPreferences> build() async => throw StateError('prefs corruptas');
}

Future<void> _pumpSettings(WidgetTester tester, {required bool failing}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.binding.setSurfaceSize(const Size(420, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        audioPlayerServiceProvider.overrideWithValue(QaSilentAudio()),
        if (failing)
          uiPreferencesProvider.overrideWith(() => _FailingUiPreferences()),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    ),
  );
  // Sin pumpAndSettle: un LinearProgressIndicator indeterminado no termina.
  await qaPumpFor(tester, const Duration(seconds: 2));
}

void main() {
  testWidgets('con preferencias sanas no queda ningún indicador de carga '
      '(control)', (tester) async {
    await _pumpSettings(tester, failing: false);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byKey(const ValueKey('settings-a11y')), findsOneWidget);
  });

  testWidgets('con el provider de preferencias en error no se queda en un '
      'LinearProgressIndicator infinito [BUG: settings_groups.dart:139 (y '
      '267, 564) trata el error como carga con valueOrNull == null]', (
    tester,
  ) async {
    await _pumpSettings(tester, failing: true);
    expect(tester.takeException(), isNull);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  }, skip: qaSkipBug);
}
