import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/oculum_opposed_attack.dart';

void main() {
  test('area attack damage divides across every hit rounding up', () {
    expect(oculumDamagePerTarget(10, 3), 4);
    expect(oculumDamagePerTarget(10, 2), 5);
    expect(oculumDamagePerTarget(10, 1), 10);
    expect(oculumDamagePerTarget(30, 3, flatBonusPerTarget: 8), 18);
    expect(oculumDamagePerTarget(30, 1, flatBonusPerTarget: 8), 38);
    expect(oculumDamagePerTarget(0, 3), 1);
    expect(oculumDamagePerTarget(-4, 2), 1);
    expect(oculumDamagePerTarget(10, 0), 0);
  });

  test('flat additive damage stays on each area hit', () {
    expect(oculumSplitAreaDamageExpression('danni+8'), (
      base: 'danni',
      perTargetBonus: '8',
    ));
    expect(oculumSplitAreaDamageExpression('(danni*0.75)+8'), (
      base: '(danni*0.75)',
      perTargetBonus: '8',
    ));
    expect(oculumSplitAreaDamageExpression('danni-3'), (
      base: 'danni',
      perTargetBonus: '-(3)',
    ));
    expect(oculumSplitAreaDamageExpression('danni*0.75'), (
      base: 'danni*0.75',
      perTargetBonus: '',
    ));
  });

  test('declared ability damage is added to prepared base damage', () {
    expect(
      oculumAttackDamageWithAbilityBonus(
        preparedDamage: 51,
        fixedBonuses: 0,
        abilityDamageBonus: 20,
      ),
      71,
    );
    expect(
      oculumAttackDamageWithAbilityBonus(
        preparedDamage: 61,
        fixedBonuses: 10,
        abilityDamageBonus: 20,
      ),
      71,
    );
  });

  test('fixed skill bonus does not erase an already negative damage base', () {
    final base = oculumAttackDamageWithAbilityBonus(
      preparedDamage: 6,
      fixedBonuses: 8,
      abilityDamageBonus: 0,
    );
    expect(base, -2);
    expect(oculumDamagePerTarget(base, 1, flatBonusPerTarget: 8), 6);
  });

  test(
    'attack-roll damage parser adds only the matching subtrait fraction',
    () {
      expect(
        oculumAttackRollDamageBonus(
          sourceTexts: const ['@Danni+1/2dadoriflessi'],
          attackChoiceId: 'riflessi',
          rollTotal: 25,
        ),
        12,
      );
      expect(
        oculumAttackRollDamageBonus(
          sourceTexts: const ['1/3dadoforza ai danni'],
          attackChoiceId: 'forza',
          rollTotal: 25,
        ),
        8,
      );
      expect(
        oculumAttackRollDamageBonus(
          sourceTexts: const ['@Danni+1/5dadovelo'],
          attackChoiceId: 'velo',
          rollTotal: 29,
        ),
        5,
      );
      expect(
        oculumAttackRollDamageBonus(
          sourceTexts: const ['@Danni+1/4dadoprecisione'],
          attackChoiceId: 'precisione',
          rollTotal: 31,
        ),
        7,
      );
      expect(
        oculumAttackRollDamageBonus(
          sourceTexts: const ['@Danni+1/2dadoriflessi'],
          attackChoiceId: 'forza',
          rollTotal: 25,
        ),
        0,
      );
      expect(
        oculumAttackRollDamageBonus(
          sourceTexts: const ['@CM+1/2dadoriflessi'],
          attackChoiceId: 'riflessi',
          rollTotal: 25,
        ),
        0,
      );
    },
  );

  test(
    'boss adaptation starts after the first hit and is tracked by element',
    () {
      var state = <String, dynamic>{};
      final first = oculumPrepareMonsterElementalAdaptation(
        isMiniBoss: false,
        isBoss: true,
        incomingElement: 'Fuoco',
        previousState: state,
      );
      expect(first.resistanceBeforeHit, 0);
      expect(first.resistanceAfterHit, 6);
      state = Map<String, dynamic>.from(first.state);
      final second = oculumPrepareMonsterElementalAdaptation(
        isMiniBoss: false,
        isBoss: true,
        incomingElement: 'Fuoco',
        previousState: state,
      );
      expect(second.resistanceBeforeHit, 6);
      expect(second.resistanceAfterHit, 12);
      expect(
        oculumReduceIncomingDamage(
          100,
          (100 - second.resistanceBeforeHit) / 100,
        ),
        94,
      );
      final otherElement = oculumPrepareMonsterElementalAdaptation(
        isMiniBoss: false,
        isBoss: true,
        incomingElement: 'Acqua',
        previousState: second.state,
      );
      expect(otherElement.resistanceBeforeHit, 0);
      expect(
        oculumMonsterCollectedElements(otherElement.state),
        containsAll(['fuoco', 'acqua']),
      );
    },
  );

  test('mini-boss adaptation locks its first element and caps at sixty', () {
    var state = <String, dynamic>{};
    for (var hit = 0; hit < 21; hit++) {
      final result = oculumPrepareMonsterElementalAdaptation(
        isMiniBoss: true,
        isBoss: false,
        incomingElement: 'Gelo',
        previousState: state,
      );
      if (hit == 0) expect(result.resistanceBeforeHit, 0);
      state = Map<String, dynamic>.from(result.state);
    }
    final capped = oculumPrepareMonsterElementalAdaptation(
      isMiniBoss: true,
      isBoss: false,
      incomingElement: 'Gelo',
      previousState: state,
    );
    expect(capped.resistanceBeforeHit, 60);
    expect(capped.resistanceAfterHit, 60);
    final other = oculumPrepareMonsterElementalAdaptation(
      isMiniBoss: true,
      isBoss: false,
      incomingElement: 'Fuoco',
      previousState: capped.state,
    );
    expect(other.changed, isFalse);
    expect(other.lockedElement, 'gelo');
  });

  test('collector takes a same-element defense penalty only', () {
    expect(
      oculumElementCollectorDefensePenalty(
        sourceMonsterBookId: 'collezionista_di_elementi',
        incomingElement: 'Fuoco',
        defenseElement: 'fuoco',
      ),
      2,
    );
    expect(
      oculumElementCollectorDefensePenalty(
        sourceMonsterBookId: 'collezionista_di_elementi',
        incomingElement: 'Fuoco',
        defenseElement: 'Acqua',
      ),
      0,
    );
  });

  test(
    'Manifestazione consumes Oculum on exactly thirteen of one hundred outcomes',
    () {
      expect(
        [
          for (var roll = 0; roll < 100; roll++)
            if (oculumManifestationConsumesOculum(roll)) roll,
        ].length,
        13,
      );
      expect(oculumManifestationConsumesOculum(12), isTrue);
      expect(oculumManifestationConsumesOculum(13), isFalse);
      expect(() => oculumManifestationConsumesOculum(-1), throwsRangeError);
      expect(() => oculumManifestationConsumesOculum(100), throwsRangeError);
    },
  );
  test('ties avoid; ordinary failure band is one through five', () {
    expect(oculumAttackOutcome(20, 20), OculumAttackOutcome.avoided);
    expect(oculumAttackOutcome(20, 21), OculumAttackOutcome.avoided);
    expect(oculumAttackOutcome(21, 20), OculumAttackOutcome.reduced);
    expect(oculumAttackOutcome(25, 20), OculumAttackOutcome.reduced);
    expect(oculumAttackOutcome(26, 20), OculumAttackOutcome.full);
    expect(oculumOpposedDamage(51, 25, 20), 51);
    expect(oculumOpposedEffectDuration(1, OculumAttackOutcome.reduced), 0);
    expect(oculumOpposedEffectDuration(3, OculumAttackOutcome.reduced), 1);
    expect(oculumOpposedEffectDuration(6, OculumAttackOutcome.reduced), 3);
    expect(oculumOpposedDamage(51, 20, 20), 0);
  });
  test('double defense gives one free critical reaction, not a die bonus', () {
    expect(oculumDefenseGrantsFreeReaction(4, 8), isTrue);
    expect(oculumDefenseGrantsFreeReaction(4, 7), isFalse);
    expect(oculumDefenseGrantsFreeReaction(4, 4), isFalse);
    expect(oculumDefenseGrantsFreeReaction(0, 0), isFalse);
    expect(oculumDefenseGrantsFreeReaction(-4, -2), isFalse);
    expect(oculumAttackOutcome(4, 8), OculumAttackOutcome.avoided);
  });
  test('combat element defenses apply the Oculum matchup and HP rules', () {
    double defense(
      String incoming,
      String chosen, {
      int hp = 100,
      int max = 100,
    }) => oculumElementalDefenseMultiplier(
      incomingElement: incoming,
      defenseElement: chosen,
      currentHp: hp,
      maximumHp: max,
    );

    expect(defense('Fuoco', 'Acqua'), 0.75);
    expect(defense('Acqua', 'Fuoco'), 1);
    expect(defense('Luce', 'Buio'), 0.75);
    expect(defense('Lunare', 'Solare'), 0.75);
    expect(defense('Demoniaco', 'Angelico', hp: 30), 0.75);
    expect(defense('Angelico', 'Diabolico', hp: 29), 1);
    expect(defense('Sconosciuto', 'Acqua'), 1);
    expect(oculumReduceIncomingDamage(11, 0.75), 9);
    expect(oculumReduceIncomingDamage(1, 0.75), 1);
  });
  test('double attack is critical and overrides the ordinary reduced band', () {
    expect(oculumAttackIsCritical(8, 4), isTrue);
    expect(oculumAttackIsCritical(7, 4), isFalse);
    expect(oculumAttackOutcome(8, 4), OculumAttackOutcome.full);
    expect(oculumOpposedDamage(51, 8, 4), 51);
    expect(oculumOpposedDamage(51, 8, 4, criticalBonus: 6), 63);
    expect(
      oculumOpposedDamage(51, 21, 20, forcedCritical: true, criticalBonus: 6),
      63,
    );
    expect(oculumOpposedDamage(51, 19, 20, forcedCritical: true), 0);
    expect(oculumAttackIsCritical(0, 0), isFalse);
  });
  test('forecasts exhaust every pair and obey the same critical exception', () {
    final forecast = OculumAttackForecast.fromRolls([4, 8, 21, 26], [20]);
    expect(forecast.avoided, 50);
    expect(forecast.reduced, 25);
    expect(forecast.full, 25);
    final critical = OculumAttackForecast.fromRolls([8], [4]);
    expect(critical.full, 100);
    expect(critical.reduced, 0);
    expect(() => OculumAttackForecast.fromRolls([], [1]), throwsArgumentError);
  });
  test('partial bands follow difficulty but ties always favor defense', () {
    expect(
      oculumAttackOutcome(26, 20, difficulty: 'facile'),
      OculumAttackOutcome.reduced,
    );
    expect(
      oculumAttackOutcome(27, 20, difficulty: 'facile'),
      OculumAttackOutcome.full,
    );
    expect(
      oculumAttackOutcome(24, 20, difficulty: 'difficile'),
      OculumAttackOutcome.full,
    );
    expect(
      oculumAttackOutcome(23, 20, difficulty: 'difficile'),
      OculumAttackOutcome.reduced,
    );
    for (final attack in [9]) {
      expect(
        oculumAttackOutcome(attack, 10, difficulty: 'oculum'),
        OculumAttackOutcome.reduced,
      );
      expect(oculumOpposedDamage(51, attack, 10, difficulty: 'oculum'), 51);
    }
    for (final difficulty in ['facile', 'normale', 'difficile', 'oculum']) {
      expect(
        oculumAttackOutcome(10, 10, difficulty: difficulty),
        OculumAttackOutcome.avoided,
      );
      expect(oculumOpposedDamage(51, 10, 10, difficulty: difficulty), 0);
    }
    expect(
      oculumAttackOutcome(11, 10, difficulty: 'oculum'),
      OculumAttackOutcome.full,
    );
    expect(
      oculumAttackOutcome(8, 10, difficulty: 'oculum'),
      OculumAttackOutcome.avoided,
    );
  });
}
