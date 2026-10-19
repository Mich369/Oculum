import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/oculum_opposed_attack.dart';

void main() {
  test('area attack damage divides across every hit rounding up', () {
    expect(oculumDamagePerTarget(10, 3), 4);
    expect(oculumDamagePerTarget(10, 2), 5);
    expect(oculumDamagePerTarget(10, 1), 10);
    expect(oculumDamagePerTarget(30, 3, flatBonusPerTarget: 8), 18);
    expect(oculumDamagePerTarget(30, 1, flatBonusPerTarget: 8), 38);
    expect(oculumDamagePerTarget(0, 3), 0);
    expect(oculumDamagePerTarget(-4, 2), 0);
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
  test(
    'partial hit bands follow campaign difficulty including Oculum ties',
    () {
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
      for (final attack in [9, 10]) {
        expect(
          oculumAttackOutcome(attack, 10, difficulty: 'oculum'),
          OculumAttackOutcome.reduced,
        );
        expect(oculumOpposedDamage(51, attack, 10, difficulty: 'oculum'), 51);
      }
      expect(
        oculumAttackOutcome(11, 10, difficulty: 'oculum'),
        OculumAttackOutcome.full,
      );
      expect(
        oculumAttackOutcome(8, 10, difficulty: 'oculum'),
        OculumAttackOutcome.avoided,
      );
    },
  );
}
