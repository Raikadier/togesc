import 'package:flutter_test/flutter_test.dart';
import 'package:togesc/constants/game_constants.dart';
import 'package:togesc/utils/piano_note_selection.dart';

void main() {
  group('togglePianoNoteSelection', () {
    test('modo una nota reemplaza la seleccion anterior', () {
      var selected = togglePianoNoteSelection(
        current: {'C'},
        note: 'E',
        maxNotes: 1,
      );
      expect(selected, {'E'});

      selected = togglePianoNoteSelection(
        current: selected,
        note: 'E',
        maxNotes: 1,
      );
      expect(selected, isEmpty);
    });

    test('modo intervalo permite hasta dos notas', () {
      var selected = togglePianoNoteSelection(
        current: {},
        note: 'C',
        maxNotes: 2,
      );
      expect(selected, {'C'});

      selected = togglePianoNoteSelection(
        current: selected,
        note: 'E',
        maxNotes: 2,
      );
      expect(selected, {'C', 'E'});

      selected = togglePianoNoteSelection(
        current: selected,
        note: 'G',
        maxNotes: 2,
      );
      expect(selected, {'E', 'G'});
    });

    test('modo acorde permite hasta tres notas', () {
      var selected = {'C', 'E', 'G'};
      selected = togglePianoNoteSelection(
        current: selected,
        note: 'A',
        maxNotes: 3,
      );
      expect(selected, {'E', 'G', 'A'});
    });
  });

  group('canConfirmPianoSelection', () {
    test('requiere el numero exacto de notas del modo', () {
      expect(canConfirmPianoSelection({'C'}, 1), isTrue);
      expect(canConfirmPianoSelection({'C', 'E'}, 1), isFalse);
      expect(canConfirmPianoSelection({'C', 'E'}, 2), isTrue);
    });
  });

  group('selectableNoteCount', () {
    test('intervalo siempre permite 2 aunque la sesion diga 1', () {
      expect(
        selectableNoteCount(
          screenMode: GameMode.interval,
          sessionNumNotes: 1,
        ),
        2,
      );
    });

    test('aleatorio usa notas de la ronda', () {
      expect(
        selectableNoteCount(
          screenMode: GameMode.random,
          sessionNumNotes: 4,
        ),
        4,
      );
    });
  });

  group('pianoSelectionRequiredMessage', () {
    test('mensaje para intervalo', () {
      expect(
        pianoSelectionRequiredMessage(2),
        'Debes seleccionar exactamente 2 notas para confirmar.',
      );
    });
  });
}
