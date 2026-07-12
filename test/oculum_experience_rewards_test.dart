import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  group('EXP delle Open', () {
    test('segue i totali 25, 125 e 175 senza sommare due volte', () {
      expect(oculumTitleOpenExperienceTarget(0), 0);
      expect(oculumTitleOpenExperienceTarget(1), 25);
      expect(oculumTitleOpenExperienceTarget(2), 125);
      expect(oculumTitleOpenExperienceTarget(3), 175);
      expect(oculumTitleOpenExperienceTarget(4), 225);
    });

    test('i vecchi titoli evoluti risultano gia premiati', () {
      final restored = OculumTitle.fromJson({
        'nome': 'Titolo esistente',
        'tipo': 'Titolo',
        'ottenimento': '',
        'buff': '',
        'puntoCieco': '',
        'skill': '',
        'richiede': '',
        'evoluto': true,
        'openExtra': [
          {
            'nome': 'Seconda Open',
            'descrizione': '',
            'openBuff': '',
            'openSkill': '',
            'attiva': false,
            'conditionalBuffs': <dynamic>[],
          },
        ],
      });

      expect(restored.openExperienceClaimed, 125);
      expect(
        OculumTitle.fromJson(restored.toJson()).openExperienceClaimed,
        125,
      );
    });
  });

  group('EXP dei tiri', () {
    test('premia solo d20 superati con naturale almeno 18', () {
      expect(
        oculumRollExperienceGain(
          naturalRoll: 17,
          faces: 20,
          rollSucceeded: true,
        ),
        0,
      );
      expect(
        oculumRollExperienceGain(
          naturalRoll: 18,
          faces: 20,
          rollSucceeded: true,
        ),
        9,
      );
      expect(
        oculumRollExperienceGain(
          naturalRoll: 19,
          faces: 20,
          rollSucceeded: false,
        ),
        0,
      );
      expect(
        oculumRollExperienceGain(
          naturalRoll: 20,
          faces: 20,
          rollSucceeded: true,
        ),
        15,
      );
    });

    test('esclude il lanciatore separato d2-d120', () {
      for (final faces in <int>[2, 4, 6, 8, 10, 12, 30, 50, 100, 120]) {
        expect(
          oculumRollExperienceGain(
            naturalRoll: faces,
            faces: faces,
            rollSucceeded: true,
          ),
          0,
        );
      }
    });
  });

  group('recupero ogni 100 EXP', () {
    test('accumula guadagni piccoli senza perdere il resto', () {
      final first = oculumExperienceHundredProgress(
        previousRemainder: 0,
        experienceGained: 30,
      );
      expect(first, (recoveries: 0, remainder: 30));

      final second = oculumExperienceHundredProgress(
        previousRemainder: first.remainder,
        experienceGained: 175,
      );
      expect(second, (recoveries: 2, remainder: 5));
    });

    test('gestisce piu soglie in un singolo guadagno', () {
      expect(
        oculumExperienceHundredProgress(
          previousRemainder: 99,
          experienceGained: 301,
        ),
        (recoveries: 4, remainder: 0),
      );
    });
  });
}
