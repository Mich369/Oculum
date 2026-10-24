import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/meccanio_rules.dart';

void main() {
  test(
    'wild variants have distinct shield, defence and skill power profiles',
    () {
      final normal = meccanioVariantProfile('meccanio');
      final damaged = meccanioVariantProfile('meccanio_ammaccato');
      final primitive = meccanioVariantProfile('meccanio_primordiale');
      final elite = meccanioVariantProfile('meccanio_elite');
      expect(
        damaged['initialShieldPercent']! * 2,
        normal['initialShieldPercent'],
      );
      expect(
        damaged['skillPowerPercent'],
        lessThan(normal['skillPowerPercent']!),
      );
      expect(
        elite['skillPowerPercent'],
        greaterThan(normal['skillPowerPercent']!),
      );
      expect(primitive['defenseBonus'], greaterThan(normal['defenseBonus']!));
      expect(
        primitive['initialShieldPercent'],
        lessThan(normal['initialShieldPercent']!),
      );
      expect(primitive['oculumShieldPercent'], 10);
      expect(
        meccanioRepair(
          hp: 20,
          hpMaximum: 20,
          shield: 15,
          amount: 99,
          shieldLimitPercent: damaged['repairShieldPercentI'],
        ).shield,
        16,
      );
    },
  );
  test('empathy and rests remove percentage points with a zero floor', () {
    expect(meccanioDisobedienceAfterEmpathy(60, 17), 43);
    expect(meccanioDisobedienceAfterEmpathy(60, -4), 60);
    expect(meccanioDisobedienceAfterEmpathy(60, 80), 0);
    expect(meccanioDisobedienceAfterRest(60, longRest: false), 40);
    expect(meccanioDisobedienceAfterRest(60, longRest: true), 10);
    expect(meccanioDisobedienceAfterRest(10, longRest: false), 0);
    expect(meccanioTamingDifficulty(3, 2), 22);
    expect(meccanioDisobedienceAfterDeception(60, 11, 25), 70);
    expect(meccanioDisobedienceAfterDeception(60, 12, 25), 35);
    expect(meccanioDisobedienceAfterDeception(95, 1, -5), 100);
    expect(meccanioFailedProtectionReward(0, 100), 2);
    expect(meccanioFailedProtectionReward(50, 100), 21);
    expect(meccanioFailedProtectionReward(100, 100), 40);
    expect(meccanioFailedProtectionReward(200, 100), 40);
  });
  test(
    'purchases keep three distinct skills, an attack, and one separate Open',
    () {
      var rare = 0;
      for (var seed = 0; seed < 2000; seed++) {
        final data = meccanioRollLoadout(Random(seed));
        final skills = (data['skills'] as List).cast<String>();
        expect(skills.length, 3);
        expect(skills.toSet().length, 3);
        expect(skills.any(meccanioOffensiveTechniques.contains), isTrue);
        expect(data['emergency'], isTrue);
        expect(['missile', 'automatic'], contains(data['open']));
        if (skills.contains('rays')) rare++;
      }
      expect(rare, inInclusiveRange(1, 170));
    },
  );
  test('repairs fill HP or Shield without reducing an existing Shield', () {
    expect(meccanioRepair(hp: 5, hpMaximum: 20, shield: 30, amount: 100), (
      hp: 20,
      shield: 30,
      healed: 15,
      shieldAdded: 0,
    ));
    expect(meccanioRepair(hp: 20, hpMaximum: 20, shield: 36, amount: 100), (
      hp: 20,
      shield: 36,
      healed: 0,
      shieldAdded: 0,
    ));
    expect(
      meccanioRepair(hp: 20, hpMaximum: 20, shield: 30, amount: 100, form: 2),
      (hp: 20, shield: 38, healed: 0, shieldAdded: 8),
    );
  });
  test(
    'growth doubles Will and Matter, caps at owner and never grants Oculum',
    () {
      final result = meccanioRegenerationBonuses(
        base: {'resilienza': 4, 'volonta': 2, 'materia': 4},
        previous: {'resilienza': 3, 'volonta': 3, 'materia': 0},
        owner: {'resilienza': 6, 'volonta': 5, 'materia': 10},
      );
      expect(result, {'resilienza': 2, 'volonta': 3, 'materia': 2});
      expect(result.containsKey('oculum'), isFalse);
    },
  );
  test('critical lightning uses one exclusive ticket and only hit targets', () {
    final counts = <int, int>{};
    for (var ticket = 0; ticket < 100; ticket++) {
      final n = meccanioElectrocutionCount(ticket, 3);
      counts[n] = (counts[n] ?? 0) + 1;
    }
    expect(counts, {3: 15, 2: 25, 1: 30, 0: 30});
    expect(meccanioElectrocutionCount(20, 1), 1);
    expect(meccanioElectrocutionCount(0, 0), 0);
    for (final level in [0, 10, 20, 30]) {
      expect(meccanioElementPercent(level), 25 + 25 * (level ~/ 10));
    }
    expect(meccanioShoulderDamage(bullets: 7, targets: 3), 4);
  });
}
