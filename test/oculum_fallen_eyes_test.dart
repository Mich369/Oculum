import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('rarity thresholds cover 60/25/10/5 without gaps', () {
    final random = Random(42);
    final counts = <String, int>{};
    for (var i = 0; i < 100000; i++) {
      final rarity = oculumFallenEyeRollRarity(random);
      counts[rarity] = (counts[rarity] ?? 0) + 1;
    }
    expect(counts['comune']!, closeTo(60000, 900));
    expect(counts['non_comune']!, closeTo(25000, 800));
    expect(counts['raro']!, closeTo(10000, 600));
    expect(counts['oculum']!, closeTo(5000, 450));
  });

  test(
    'rare Eye attribute has a 26 percent roll and one fixed chosen bonus',
    () {
      expect(oculumFallenEyeWinsRareAttributeRoll(0), isTrue);
      expect(oculumFallenEyeWinsRareAttributeRoll(25), isTrue);
      expect(oculumFallenEyeWinsRareAttributeRoll(26), isFalse);
      expect(oculumFallenEyeRareAttributeBonusFor('danno'), 50);
      expect(oculumFallenEyeRareAttributeBonusFor('difesa'), 35);
      expect(oculumFallenEyeRareAttributeBonusFor(''), 0);
    },
  );

  test('campaign loading never drops Eyes held by the active save block', () {
    final eyes = oculumFallenEyesMergeForCampaignLoad(
      campaignEyes: const <dynamic>[],
      activeEyes: <Map<String, dynamic>>[
        {
          'id': 'eye_active',
          'name': 'Occhio Custodito',
          'unknownFutureField': 'preserved',
        },
      ],
    );
    expect(eyes, hasLength(1));
    expect(eyes.single['id'], 'eye_active');
    expect(eyes.single['unknownFutureField'], 'preserved');
  });

  test(
    'campaign and active Eye snapshots merge by ID without dropping fields',
    () {
      final eyes = oculumFallenEyesMergeForCampaignLoad(
        campaignEyes: <Map<String, dynamic>>[
          {'id': 'eye_1', 'rarity': 'raro', 'campaignOnly': true},
        ],
        activeEyes: <Map<String, dynamic>>[
          {'id': 'eye_1', 'active': true, 'activeOnly': true},
          {'id': 'eye_2', 'name': 'Secondo'},
        ],
      );
      expect(eyes, hasLength(2));
      final first = eyes.firstWhere((eye) => eye['id'] == 'eye_1');
      expect(first['rarity'], 'raro');
      expect(first['campaignOnly'], isTrue);
      expect(first['active'], isTrue);
      expect(first['activeOnly'], isTrue);
    },
  );

  test('reforge table is centralized and strictly harder by target rarity', () {
    for (final difficulty in ['facile', 'medio', 'difficile', 'oculum']) {
      expect(
        oculumFallenEyeReforgeChance(difficulty, 'non_comune'),
        greaterThan(oculumFallenEyeReforgeChance(difficulty, 'raro')),
      );
      expect(
        oculumFallenEyeReforgeChance(difficulty, 'raro'),
        greaterThan(oculumFallenEyeReforgeChance(difficulty, 'oculum')),
      );
    }
    expect(oculumFallenEyeReforgeChance('oculum', 'oculum'), 15);
    expect(oculumFallenEyeReforgeChance('facile', 'non_comune'), 80);
  });

  test('each failed Reforge improves only the current stage chance', () {
    expect(oculumFallenEyeReforgeFailureBonus(0), 0);
    expect(oculumFallenEyeReforgeFailureBonus(3), 30);
    expect(
      oculumFallenEyeReforgeChanceWithFailures(
        difficulty: 'oculum',
        targetRarity: 'oculum',
        failureStreak: 3,
      ),
      45,
    );
    expect(
      oculumFallenEyeReforgeChanceWithFailures(
        difficulty: 'facile',
        targetRarity: 'non_comune',
        failureStreak: 99,
      ),
      100,
    );
  });

  test('rarity permissions obey the four progression tiers', () {
    expect(oculumFallenEyeArtLimit('comune'), 0);
    expect(oculumFallenEyeArtLimit('non_comune'), 1);
    expect(oculumFallenEyeArtLimit('raro'), 2);
    expect(oculumFallenEyeArtLimit('oculum'), 3);
    expect(oculumFallenEyeCanHaveTitles('oculum'), isTrue);
    expect(oculumFallenEyeCanHaveTitles('raro'), isFalse);
    expect(oculumFallenEyeNextRarity('oculum'), isNull);
    expect(oculumFallenEyeEpicReforgeXp, 100);
  });

  test('common Eye malus changes the real combat or base-stat field once', () {
    final cmSheet = <String, dynamic>{'cmRapido': '4'};
    oculumFallenEyeApplyCommonMalus(cmSheet, 'cm:-2');
    expect(cmSheet['cmRapido'], '2');

    final vcSheet = <String, dynamic>{'attaccoRapido': '3'};
    oculumFallenEyeApplyCommonMalus(vcSheet, 'vc:-1');
    expect(vcSheet['attaccoRapido'], '2');

    final statSheet = <String, dynamic>{'materia': '5'};
    oculumFallenEyeApplyCommonMalus(statSheet, 'stat:materia:-1');
    expect(statSheet['materia'], '4');
    oculumFallenEyeApplyCommonMalus(
      statSheet,
      'stat:materia:-1',
      multiplier: -1,
    );
    expect(statSheet['materia'], '5');
    expect(oculumFallenEyeCommonMalusLabel('stat:volonta:-1'), '-1 Volontà');
  });

  test(
    'Oculum Eye buffs use a saved low percentage on real creature stats',
    () {
      expect(
        oculumFallenEyeOculumBuffEffectForRoll(
          targetRoll: 2,
          percentageRoll: 0,
        ),
        'stat:resilienza:3',
      );
      expect(oculumFallenEyePercentageIncrease(100, 7), 7);
      expect(oculumFallenEyeOculumBuffLabel('hp:5'), '+5% Vita');

      final hpSheet = <String, dynamic>{'currentHp': '100'};
      oculumFallenEyeApplyOculumBuff(hpSheet, 'hp:5');
      expect(hpSheet['currentHp'], '105');

      final statSheet = <String, dynamic>{'resilienza': '40'};
      oculumFallenEyeApplyOculumBuff(statSheet, 'stat:resilienza:5');
      expect(statSheet['resilienza'], '42');
    },
  );

  test('summon XP uses owner difficulty as the single source', () {
    expect(oculumFallenEyeSummonXpForDifficulty('facile'), 150);
    expect(oculumFallenEyeSummonXpForDifficulty('medio'), 100);
    expect(oculumFallenEyeSummonXpForDifficulty('difficile'), 75);
    expect(oculumFallenEyeSummonXpForDifficulty('oculum'), 50);
    expect(oculumFallenEyeSummonXpForDifficulty('normale'), 100);
  });

  test('summon Oculum thresholds follow the selected difficulty', () {
    expect(oculumFallenEyeSummonCostForDifficulty('facile'), 1);
    expect(oculumFallenEyeSummonCostForDifficulty('normale'), 2);
    expect(oculumFallenEyeSummonCostForDifficulty('difficile'), 3);
    expect(oculumFallenEyeSummonCostForDifficulty('oculum'), 4);
  });

  test('a single Fallen Eye stays stable; pressure starts from the second', () {
    expect(oculumFallenEyeNeedsMaintenance(1), isFalse);
    expect(oculumFallenEyeNeedsMaintenance(2), isTrue);
    expect(
      oculumFallenEyeMaintenanceDifficulty(ownerEyeCount: 2, failureStreak: 0),
      18,
    );
    expect(
      oculumFallenEyeMaintenanceDifficulty(ownerEyeCount: 3, failureStreak: 2),
      25,
    );
  });

  test('Fallen Eye descriptions retain the monster source class', () {
    expect(
      oculumFallenEyeSourceClass(<String, dynamic>{
        'tipoScheda': 'Mostro Boss',
      }),
      'Boss',
    );
    expect(
      oculumFallenEyeSourceClass(<String, dynamic>{
        'tipoScheda': 'Mostro Mini Boss',
      }),
      'Mini-Boss',
    );
  });

  test('non-common Eyes regenerate half as much while disevoked', () {
    expect(
      oculumFallenEyeRestIntegrityRecoveredValue(
        current: 0,
        maximum: 100,
        longRest: true,
        rarity: 'non_comune',
      ),
      50,
    );
    expect(
      oculumFallenEyeRestIntegrityRecoveredValue(
        current: 0,
        maximum: 100,
        longRest: true,
        rarity: 'raro',
      ),
      100,
    );
  });

  test('will-paid Eyes require one check per ten lost HP', () {
    expect(
      oculumFallenEyeWillChecksDueForHpLoss(previousHp: 30, currentHp: 21),
      0,
    );
    expect(
      oculumFallenEyeWillChecksDueForHpLoss(previousHp: 30, currentHp: 20),
      1,
    );
    expect(
      oculumFallenEyeWillChecksDueForHpLoss(previousHp: 30, currentHp: 5),
      2,
    );
    expect(oculumFallenEyeCoreIntegrityLossForFailure(1), 0);
    expect(oculumFallenEyeCoreIntegrityLossForFailure(3), 2);
  });

  test('a permanently lost Fallen Eye can never be summoned again', () {
    expect(oculumFallenEyeIsDead({'perdutoPerSempre': true}), isTrue);
    expect(oculumFallenEyeIsDead({'deathWounds': 3, 'currentHp': 0}), isTrue);
    expect(oculumFallenEyeIsDead({'deathWounds': 2, 'currentHp': 0}), isFalse);
  });

  test('only a genuinely empty player sheet is used for the first summon', () {
    expect(
      oculumFallenEyeIsBlankSummonSheet({
        'nome': '???',
        'tipoScheda': 'Personaggio',
        'livello': '0',
      }),
      isTrue,
    );
    expect(
      oculumFallenEyeIsBlankSummonSheet({
        'nome': 'Giocatore',
        'tipoScheda': 'Personaggio',
        'livello': '0',
      }),
      isFalse,
    );
    expect(
      oculumFallenEyeIsBlankSummonSheet({
        'nome': '???',
        'tipoScheda': 'Personaggio',
        'livello': '0',
        'realtimeSharedSheet': true,
      }),
      isFalse,
    );
  });

  test('only a natural twenty on Drop opens Fallen Eye creation', () {
    expect(
      oculumFallenEyeDropCreatesOnNaturalTwenty(
        subtraitId: 'drop',
        naturalRoll: 20,
      ),
      isTrue,
    );
    expect(
      oculumFallenEyeDropCreatesOnNaturalTwenty(
        subtraitId: 'drop',
        naturalRoll: 19,
      ),
      isFalse,
    );
    expect(
      oculumFallenEyeDropCreatesOnNaturalTwenty(
        subtraitId: 'fortuna',
        naturalRoll: 20,
      ),
      isFalse,
    );
  });

  test('only a long rest restores all Fallen Eye integrity', () {
    expect(
      oculumFallenEyeRestIntegrityRecoveredValue(
        current: 2,
        maximum: 10,
        longRest: false,
      ),
      5,
    );
    expect(
      oculumFallenEyeRestIntegrityRecoveredValue(
        current: 2,
        maximum: 10,
        longRest: true,
      ),
      10,
    );
  });
}
