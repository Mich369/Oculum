import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  group('EXP minima per difficolta', () {
    test('Facile garantisce almeno 1 EXP se il guadagno era positivo', () {
      expect(
        oculumExperienceAfterStatTax(
          difficulty: 'facile',
          calculatedExperience: 5,
          statTax: 99,
        ),
        1,
      );
      expect(
        oculumExperienceAfterStatTax(
          difficulty: 'easy',
          calculatedExperience: 1,
          statTax: 1,
        ),
        1,
      );
    });

    test('Facile non crea EXP da un guadagno originario nullo', () {
      expect(
        oculumExperienceAfterStatTax(
          difficulty: 'facile',
          calculatedExperience: 0,
          statTax: 0,
        ),
        0,
      );
    });

    test('le altre difficolta mantengono la sottrazione normale', () {
      expect(
        oculumExperienceAfterStatTax(
          difficulty: 'normale',
          calculatedExperience: 5,
          statTax: 8,
        ),
        0,
      );
    });
  });

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
          naturalRoll: 19,
          faces: 20,
          rollSucceeded: true,
        ),
        10,
      );
      expect(
        oculumRollExperienceGain(
          naturalRoll: 20,
          faces: 20,
          rollSucceeded: true,
        ),
        30,
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

  group('recupero EXP per difficolta', () {
    test('Facile usa il vecchio ritmo ma con recuperi ridotti', () {
      final profile = oculumExperienceRecoveryProfile('facile');
      expect(profile.periodicThreshold, 100);
      expect(profile.periodicHp, 4);
      expect(profile.milestoneHpDivisor, 5);
      expect(profile.milestoneOculumDivisor, 4);
      expect(profile.milestoneShieldDivisor, 10);
    });

    test('le difficolta aumentano la soglia e riducono i recuperi', () {
      final normal = oculumExperienceRecoveryProfile('normale');
      final hard = oculumExperienceRecoveryProfile('difficile');
      final oculum = oculumExperienceRecoveryProfile('oculum');

      expect(normal.periodicThreshold, 150);
      expect(hard.periodicThreshold, 200);
      expect(oculum.periodicThreshold, 300);
      expect(normal.periodicHp, 3);
      expect(hard.periodicHp, 2);
      expect(oculum.periodicHp, 1);
      expect(normal.milestoneShieldDivisor, 15);
      expect(hard.milestoneShieldDivisor, 20);
      expect(oculum.milestoneShieldDivisor, 30);
    });

    test('il resto usa la soglia della difficolta senza perdere EXP', () {
      final first = oculumExperienceRecoveryProgress(
        previousRemainder: 0,
        experienceGained: 175,
        threshold: 150,
      );
      final second = oculumExperienceRecoveryProgress(
        previousRemainder: first.remainder,
        experienceGained: 125,
        threshold: 150,
      );

      expect(first, (recoveries: 1, remainder: 25));
      expect(second, (recoveries: 1, remainder: 0));
    });

    test('cambiare difficolta non cancella il progresso gia accumulato', () {
      final progress = oculumExperienceRecoveryProgress(
        previousRemainder: 299,
        experienceGained: 1,
        threshold: 100,
      );

      expect(progress, (recoveries: 3, remainder: 0));
    });

    test('calcola grandi aggiunte EXP senza iterare sulle singole soglie', () {
      final progress = oculumExperienceRecoveryProgress(
        previousRemainder: 149,
        experienceGained: 999999,
        threshold: 150,
      );

      expect(progress, (recoveries: 6667, remainder: 98));
    });
  });
}
