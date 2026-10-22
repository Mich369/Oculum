import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/oculum_combat_scout_rules.dart';

void main() {
  test('only exact Percezione readings halve veil bonuses rounding down', () {
    final conditions = [
      {
        'conditionType': 'trasparenza',
        'metadata': {'veilBaseBonus': 6},
      },
      {
        'conditionType': 'invisibile',
        'metadata': {'veilBaseBonus': 18},
      },
    ];

    expect(oculumCombatScoutVeilBonus(conditions: conditions, level: 5), 23);
    expect(
      oculumCombatScoutVeilBonus(
        conditions: [conditions.first],
        level: 5,
        exactPerceptionReading: true,
      ),
      5,
    );
    expect(
      oculumCombatScoutVeilBonus(
        conditions: conditions,
        level: 5,
        exactPerceptionReading: true,
      ),
      11,
    );
  });

  test(
    'veil bonus preserves saved editor values and ignores other conditions',
    () {
      expect(
        oculumCombatScoutVeilBonus(
          conditions: [
            {
              'conditionType': 'invisibile',
              'metadata': {'veilBaseBonus': 9, 'veilAddLevel': false},
            },
            {'conditionType': 'corruzione'},
          ],
          level: 30,
          exactPerceptionReading: true,
        ),
        4,
      );
    },
  );

  test('Percezione reveals exact probabilities at level plus Velo', () {
    final read = oculumCombatScoutRead(
      rollTotal: 17,
      targetLevel: 12,
      targetVelo: 5,
      targetGrade: 3,
      targetCm: 24,
    );
    expect(read.reveal, OculumCombatScoutReveal.exact);
    expect(read.requirement, 17);
    expect(read.targetLevel, 12);
    expect(read.targetGrade, 3);
    expect(read.targetCm, 24);
    expect(read.showsProbabilities, isTrue);
  });

  test('approximate Percezione leaves Velo unchanged', () {
    expect(
      oculumCombatScoutVeilBonus(
        conditions: [
          {
            'conditionType': 'invisibile',
            'metadata': {'veilBaseBonus': 18},
          },
        ],
        level: 5,
      ),
      23,
    );
  });

  test('explicit saved resistance overrides anatomy only for its element', () {
    expect(
      oculumIncomingResistanceIsExplicit(
        elementId: 'acido',
        savedPresets: const {},
        savedPercentages: const {},
      ),
      isFalse,
    );
    expect(
      oculumIncomingResistanceIsExplicit(
        elementId: 'acido',
        savedPresets: const {'acido': 'Normale'},
        savedPercentages: const {},
      ),
      isTrue,
    );
    expect(
      oculumIncomingResistanceIsExplicit(
        elementId: 'acido',
        savedPresets: const {'fuoco': 'Resistenza'},
        savedPercentages: const {},
      ),
      isFalse,
    );
    expect(
      oculumIncomingResistanceIsExplicit(
        elementId: 'acido',
        savedPresets: const {},
        savedPercentages: const {'acido': '+25%'},
      ),
      isTrue,
    );
    expect(
      oculumIncomingResistanceIsExplicit(
        elementId: 'acido',
        savedPresets: const {},
        savedPercentages: const {},
        legacyPercentage: '-20%',
      ),
      isTrue,
    );
  });

  test('a Percezione miss within five shows lower level at same grade', () {
    final read = oculumCombatScoutRead(
      rollTotal: 14,
      targetLevel: 12,
      targetVelo: 5,
      targetGrade: 3,
      targetCm: 24,
    );
    expect(read.reveal, OculumCombatScoutReveal.approximate);
    expect(read.failure, 3);
    expect(read.targetLevel, 9);
    expect(read.targetGrade, 3);
    expect(read.targetCm, 21);
    expect(read.showsProbabilities, isTrue);
  });

  test('a Percezione miss greater than five exposes no chance data', () {
    final read = oculumCombatScoutRead(
      rollTotal: 11,
      targetLevel: 12,
      targetVelo: 5,
      targetGrade: 3,
      targetCm: 24,
    );
    expect(read.reveal, OculumCombatScoutReveal.insufficient);
    expect(read.targetLevel, isNull);
    expect(read.targetGrade, isNull);
    expect(read.targetCm, isNull);
    expect(read.showsProbabilities, isFalse);
  });
}
