import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/oculum_combat_scout_rules.dart';

void main() {
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
