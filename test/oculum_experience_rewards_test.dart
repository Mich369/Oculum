import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test(
    'Fallen Eye drops are unique per monster and strongest goes to lowest stats',
    () {
      final distributed = oculumDistributeFallenEyes(
        eyes: [
          {
            'id': 'eye-goblin',
            'sourceKillId': 'kill-goblin',
            'sourcePower': 100,
          },
          {
            'id': 'eye-goblin-duplicate',
            'sourceKillId': 'kill-goblin',
            'sourcePower': 100,
          },
          {
            'id': 'eye-knight',
            'sourceKillId': 'kill-knight',
            'sourcePower': 500,
          },
        ],
        participantStatTotals: {'strong': 40, 'weak': 12, 'mid': 24},
        random: Random(4),
      );
      final assigned = distributed.values.expand((eyes) => eyes).toList();
      expect(assigned, hasLength(2));
      expect(
        assigned.where((eye) => eye['sourceKillId'] == 'kill-goblin'),
        hasLength(1),
      );
      expect(distributed['weak']!.single['sourceKillId'], 'kill-knight');
    },
  );

  test(
    'Summon EXP is one party pool, level-gated, and owner-gated by Fate',
    () {
      final summon = <String, dynamic>{
        'id': 'summon-token-1',
        'summonInstanceId': 'summon-1',
        'isSummon': true,
        'source': 'Evocazione',
        'level': 4,
        'grade': 1,
        'statsTotal': 500,
      };
      final pool = [
        summon,
        {...summon, 'id': 'duplicate-summon-token'},
      ];
      const participantLevels = {'owner': 2, 'ally': 4, 'overlevelled': 5};
      int xpFor(String tag, int level) => oculumEncounterExperienceForEnemies(
        pool,
        characterGrade: 0,
        rebirth: false,
        difficulty: 'normale',
        characterTag: tag,
        characterLevel: level,
        participantLevels: participantLevels,
      );

      expect(
        xpFor('owner', 2) + xpFor('ally', 4) + xpFor('overlevelled', 5),
        6,
      );
      expect(xpFor('overlevelled', 5), 0);
      expect(
        oculumSummonExperienceShares(
          enemy: {...summon, 'summonerTag': 'owner'},
          participantLevels: participantLevels,
        ),
        {'ally': 6},
      );
      expect(
        oculumSummonExperienceShares(
          enemy: {...summon, 'summonerTag': 'owner', 'fateAllowsExp': true},
          participantLevels: participantLevels,
        ).values.fold<int>(0, (sum, share) => sum + share),
        6,
      );
    },
  );

  test('health labels and actual death remain separate after a revival', () {
    expect(oculumCombatHealthLabel(61, 100), '');
    expect(oculumCombatHealthLabel(60, 100), 'Ferito');
    expect(oculumCombatHealthLabel(31, 100), 'Ferito');
    expect(oculumCombatHealthLabel(30, 100), 'Morente');
    expect(oculumCombatHealthLabel(0, 100), '');
    expect(oculumCombatConfirmedDeath(hp: 0, deathWounds: 0), isFalse);
    expect(oculumCombatConfirmedDeath(hp: 0, deathWounds: 3), isTrue);
    expect(oculumCombatConfirmedDeath(hp: 75, deathWounds: 3), isFalse);
    expect(
      oculumCombatTokenHealthLabel({
        'status': 'ready',
        'healthLabel': 'Ferito',
      }),
      'Ferito',
    );
    expect(
      oculumCombatTokenHealthLabel({
        'status': 'fled',
        'healthLabel': 'Morente',
      }),
      '',
    );
  });
  test('Dust favors missing resources and never grants Oculum at zero', () {
    expect(
      oculumDustDeficientStat(
        {'resilienza': 10, 'volonta': 10, 'materia': 10, 'oculum': 10},
        {'resilienza': 10, 'volonta': 2, 'materia': 8, 'oculum': 0},
      ),
      'volonta',
    );
    expect(
      oculumDustDeficientStat(
        {'resilienza': 10, 'volonta': 5, 'materia': 8, 'oculum': 0},
        {'resilienza': 10, 'volonta': 5, 'materia': 8, 'oculum': 0},
      ),
      'volonta',
    );
  });
  test('Dust chances shift at every twenty-five excess enemy stats', () {
    expect(oculumDustTemporaryBonusChances(100, 100), [10, 60, 20, 10]);
    expect(oculumDustTemporaryBonusChances(124, 100), [10, 60, 20, 10]);
    expect(oculumDustTemporaryBonusChances(125, 100), [9.5, 58, 21.5, 11]);
    for (var excess = 0; excess <= 10000; excess += 25) {
      final chances = oculumDustTemporaryBonusChances(100 + excess, 100);
      expect(chances.every((chance) => chance >= 0 && chance <= 100), isTrue);
      expect(chances.reduce((a, b) => a + b), closeTo(100, .000001));
    }
    expect(oculumDustTemporaryBonusForRoll(100, 100, 0), 0);
    expect(oculumDustTemporaryBonusForRoll(100, 100, 10), 1);
    expect(oculumDustTemporaryBonusForRoll(100, 100, 70), 2);
    expect(oculumDustTemporaryBonusForRoll(100, 100, 90), 3);
  });
  test('elite Dust limits override the ordinary three-per-fight cap', () {
    for (final roll in [0, 9, 10, 69, 70, 99]) {
      expect(
        oculumEncounterResourcesForEnemies(
          [
            {'level': 1, 'grade': 1, 'statsTotal': 11, 'source': 'Mostro'},
          ],
          characterGrade: 0,
          characterStats: 10,
          percentileRoll: () => roll,
        ).dust,
        roll < 10
            ? 1
            : roll < 70
            ? 2
            : 3,
      );
    }
    for (final entry in [('Mini Boss', 4), ('Boss', 5)]) {
      expect(
        oculumEncounterResourcesForEnemies(
          [
            {'level': 1, 'grade': 1, 'statsTotal': 11, 'source': entry.$1},
          ],
          characterGrade: 0,
          characterStats: 10,
        ).dust,
        entry.$2,
      );
    }
  });
  test('Dust party shares twenty percent base and fifty percent additions', () {
    expect(
      oculumDustPartyExperienceShare(
        baseExperience: 100,
        additionalExperience: 60,
      ),
      50,
    );
    expect(
      oculumDustPartyExperienceShare(
        baseExperience: 100,
        additionalExperience: 0,
      ),
      20,
    );
    expect(
      oculumDustPartyExperienceShare(
        baseExperience: 0,
        additionalExperience: 60,
      ),
      30,
    );
    expect(
      oculumDustPartyExperienceShare(
        baseExperience: -10,
        additionalExperience: -20,
      ),
      0,
    );
  });
  test('kill resources are personal, grade scaled and capped per fight', () {
    expect(
      oculumEncounterEnemyKilled({
        'side': 'enemy',
        'status': 'downed',
        'currentHp': 0,
      }),
      isFalse,
    );
    expect(
      oculumEncounterEnemyKilled({'side': 'enemy', 'status': 'dead'}),
      isTrue,
    );
    final enemies = [
      {'level': 2, 'grade': 0, 'statsTotal': 11},
      {'level': 5, 'grade': 2, 'statsTotal': 12},
      {'level': 1, 'grade': 12, 'statsTotal': 100},
    ];
    expect(
      oculumEncounterResourcesForEnemies(
        enemies,
        characterGrade: 0,
        characterStats: 10,
      ),
      (obser: 50, dust: 3),
    );
    expect(
      oculumEncounterResourcesForEnemies(
        enemies,
        characterGrade: 1,
        characterStats: 100,
      ),
      (obser: 50, dust: 0),
    );
    expect(
      oculumEncounterResourcesForEnemies(
        enemies.take(1),
        characterGrade: 0,
        characterStats: 10,
      ),
      (obser: 2, dust: 1),
    );
  });
  test('Dust experience uses one die and adds sixty per character grade', () {
    expect(oculumDustExperienceReward(die: 1, grade: 0, totalStats: 10), (
      common: 21,
      personal: 26,
    ));
    expect(oculumDustExperienceReward(die: 90, grade: 2, totalStats: 20), (
      common: 230,
      personal: 240,
    ));
  });
  test(
    'encounter rewards compare each enemy grade with the recipient grade',
    () {
      expect(oculumExperienceGradeMultiplier(1, 1), 1);
      expect(oculumExperienceGradeMultiplier(1, 0), closeTo(1.2, 0.000001));
      expect(oculumExperienceGradeMultiplier(0, 1), 1);
      expect(oculumExperienceGradeLabel(0), '0');
      expect(oculumExperienceGradeLabel(12), 'XII');
      final enemies = <Map<String, dynamic>>[
        {'level': 2, 'statsTotal': 10, 'grade': 0, 'source': 'Mostro'},
        {'level': 5, 'statsTotal': 15, 'grade': 1, 'source': 'Mostro'},
      ];
      expect(
        oculumEncounterExperienceForEnemies(
          enemies,
          characterGrade: 0,
          rebirth: false,
          difficulty: 'normale',
        ),
        136,
      );
      expect(
        oculumEncounterExperienceForEnemies(
          enemies,
          characterGrade: 1,
          rebirth: false,
          difficulty: 'normale',
        ),
        132,
      );
      for (final source in ['Mostro', 'Mini Boss', 'Boss']) {
        final sourceId = source == 'Mostro'
            ? 'normale'
            : source == 'Boss'
            ? 'boss'
            : 'miniboss';
        final expected =
            (20 *
                        oculumEnemyExpMultiplier(
                          source: sourceId,
                          difficulty: 'normale',
                        ) *
                        1.2 +
                    oculumGradeExperienceBonus(
                      enemyGrade: 1,
                      rebirth: false,
                      difficulty: 'normale',
                    ))
                .round();
        expect(
          oculumEncounterExperienceForEnemies(
            [
              {'level': 5, 'statsTotal': 15, 'grade': 1, 'source': source},
            ],
            characterGrade: 0,
            rebirth: false,
            difficulty: 'normale',
          ),
          expected,
        );
      }
    },
  );
  test('attack limits use explicit creature counts and Oculum limits', () {
    expect(oculumAttackTargetLimits('uno o due avversari', 9), (
      minimum: 1,
      maximum: 2,
    ));
    expect(oculumAttackTargetLimits('colpisci da 2 a 4 avversari', 9), (
      minimum: 2,
      maximum: 4,
    ));
    expect(oculumAttackTargetLimits('fino a Oculum nemici', 7), (
      minimum: 1,
      maximum: 7,
    ));
    expect(oculumAttackTargetLimits('fino a 3 bersagli', 7), (
      minimum: 1,
      maximum: 3,
    ));
    expect(oculumAttackTargetLimits('colpisci 2 creature', 7), (
      minimum: 2,
      maximum: 2,
    ));
    expect(oculumAttackTargetLimits('danno +20, costo 5/10', 7), (
      minimum: 1,
      maximum: 1,
    ));
  });
  group('Soglia EXP dei tiri VC e CM', () {
    test('soglie crescenti sui punti guadagnati, fino a mille', () {
      for (final difficulty in ['facile', 'normale', 'difficile', 'oculum']) {
        for (final key in ['vc', 'cm', 'iniziativa', 'aiuta_compagno']) {
          final expected = key == 'iniziativa'
              ? [200, 400, 600, 800, 1000, 1000]
              : [250, 500, 750, 1000, 1000, 1000];
          for (var i = 0; i < expected.length; i++) {
            expect(
              oculumCoreRollExperienceTarget(
                key: key,
                difficulty: difficulty,
                earnedPoints: i,
              ),
              expected[i],
            );
          }
        }
        expect(
          oculumCoreRollExperienceTarget(
            key: 'resilienza',
            difficulty: difficulty,
          ),
          1000,
        );
      }
    });

    test('VC e CM ricevono la stessa EXP dei tiri delle statistiche', () {
      for (final difficulty in ['facile', 'normale', 'difficile', 'oculum']) {
        for (final roll in [18, 19, 20]) {
          final gain = oculumCoreRollExperienceGain(
            naturalRoll: roll,
            faces: 20,
            rollSucceeded: true,
            difficulty: difficulty,
          );
          expect(
            gain,
            greaterThan(0),
            reason: '$difficulty con $roll naturale',
          );
        }
      }
      expect(
        oculumCoreRollExperienceGain(
          naturalRoll: 20,
          faces: 20,
          rollSucceeded: true,
          difficulty: 'normale',
        ),
        100,
      );
      expect(
        oculumCoreRollExperienceGain(
          naturalRoll: 20,
          faces: 20,
          rollSucceeded: true,
          difficulty: 'difficile',
        ),
        50,
      );
      expect(
        oculumCoreRollExperienceGain(
          naturalRoll: 20,
          faces: 20,
          rollSucceeded: true,
          difficulty: 'oculum',
        ),
        33,
      );
    });
  });

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

  group('bonus EXP per grado', () {
    test('usa 100 per grado con il profilo di difficolta', () {
      expect(
        oculumGradeExperienceBonus(
          enemyGrade: 3,
          rebirth: false,
          difficulty: 'facile',
        ),
        225,
      );
      expect(
        oculumGradeExperienceBonus(
          enemyGrade: 3,
          rebirth: false,
          difficulty: 'normale',
        ),
        300,
      );
      expect(
        oculumGradeExperienceBonus(
          enemyGrade: 3,
          rebirth: false,
          difficulty: 'difficile',
        ),
        375,
      );
      expect(
        oculumGradeExperienceBonus(
          enemyGrade: 3,
          rebirth: false,
          difficulty: 'oculum',
        ),
        450,
      );
    });

    test('Rebirth usa 200 per grado e garantisce almeno 5 EXP', () {
      expect(
        oculumGradeExperienceBonus(
          enemyGrade: 0,
          rebirth: true,
          difficulty: 'facile',
        ),
        5,
      );
      expect(
        oculumGradeExperienceBonus(
          enemyGrade: 2,
          rebirth: true,
          difficulty: 'normale',
        ),
        400,
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
