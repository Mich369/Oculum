import 'dart:math';

/// Shared attack/defense rule, including the explicit Oculum tie exception.
enum OculumAttackOutcome {
  avoided('Evitato'),
  reduced('Ridotto'),
  full('Pieno');

  const OculumAttackOutcome(this.label);
  final String label;
}

OculumAttackOutcome oculumAttackOutcome(
  int attack,
  int defense, {
  String difficulty = 'normale',
}) {
  final margin = attack - defense;
  if (difficulty.trim().toLowerCase() == 'oculum') {
    if (margin == 0 || margin == -1) return OculumAttackOutcome.reduced;
    return margin > 0 ? OculumAttackOutcome.full : OculumAttackOutcome.avoided;
  }
  if (margin <= 0) return OculumAttackOutcome.avoided;
  if (oculumAttackIsCritical(attack, defense)) return OculumAttackOutcome.full;
  final band = switch (difficulty.trim().toLowerCase()) {
    'facile' || 'easy' => 6,
    'difficile' || 'hard' => 3,
    _ => 5,
  };
  if (margin <= band) return OculumAttackOutcome.reduced;
  return OculumAttackOutcome.full;
}

/// Divides one declared damage packet among each selected hit. Rounding up is
/// intentional: every target receives at least its equal share, as confirmed
/// for multi-target attacks.
int oculumDamagePerTarget(
  int baseDamage,
  int targetCount, {
  int flatBonusPerTarget = 0,
}) {
  if (targetCount <= 0) return 0;
  final base = max(0, baseDamage);
  final share = (base + targetCount - 1) ~/ targetCount;
  return max(0, share + flatBonusPerTarget);
}

/// Keeps an additive tail such as `danni+8` outside the divided area packet.
/// The tail is evaluated once on activation and added to every hit.
({String base, String perTargetBonus}) oculumSplitAreaDamageExpression(
  String expression,
) {
  var depth = 0;
  for (var index = 0; index < expression.length; index++) {
    final char = expression[index];
    if (char == '(') depth++;
    if (char == ')') depth = max(0, depth - 1);
    if (depth != 0 || (char != '+' && char != '-')) continue;
    if (index == 0 || index == expression.length - 1) continue;
    final left = expression.substring(0, index).trim();
    final right = expression.substring(index + 1).trim();
    if (left.isEmpty ||
        right.isEmpty ||
        !RegExp(r'danni', caseSensitive: false).hasMatch(left)) {
      continue;
    }
    return (base: left, perTargetBonus: char == '-' ? '-($right)' : right);
  }
  return (base: expression, perTargetBonus: '');
}

/// Zero/negative totals do not grant an unearned critical reaction.
bool oculumDefenseGrantsFreeReaction(int attack, int defense) =>
    defense > 0 && defense > attack && defense >= (attack > 0 ? attack * 2 : 2);

bool oculumAttackIsCritical(int attack, int defense) =>
    attack > 0 && attack > defense && attack >= (defense > 0 ? defense * 2 : 2);

bool oculumManifestationConsumesOculum(int rollOutOf100) {
  if (rollOutOf100 < 0 || rollOutOf100 >= 100) {
    throw RangeError.range(rollOutOf100, 0, 99);
  }
  return rollOutOf100 < 13;
}

int oculumOpposedDamage(
  int damage,
  int attack,
  int defense, {
  bool forcedCritical = false,
  int criticalBonus = 0,
  String difficulty = 'normale',
}) {
  if (damage <= 0) return 0;
  final outcome = oculumAttackOutcome(attack, defense, difficulty: difficulty);
  if (outcome == OculumAttackOutcome.avoided) return 0;
  final critical = forcedCritical || oculumAttackIsCritical(attack, defense);
  final amount =
      damage + (critical && criticalBonus > 0 ? criticalBonus * 2 : 0);
  return amount;
}

int oculumOpposedEffectDuration(int duration, OculumAttackOutcome outcome) =>
    outcome == OculumAttackOutcome.avoided
    ? 0
    : outcome == OculumAttackOutcome.reduced
    ? (duration > 0 ? duration ~/ 2 : 0)
    : duration;

/// Forecasts enumerate supplied totals, without assuming access to enemy stats.
class OculumAttackForecast {
  const OculumAttackForecast(this.avoided, this.reduced, this.full);
  final double avoided, reduced, full;

  factory OculumAttackForecast.fromRolls(
    List<int> attack,
    List<int> defense, {
    String difficulty = 'normale',
  }) {
    if (attack.isEmpty || defense.isEmpty) {
      throw ArgumentError('Roll lists must not be empty');
    }
    final counts = [0, 0, 0];
    for (final a in attack) {
      for (final d in defense) {
        counts[oculumAttackOutcome(a, d, difficulty: difficulty).index]++;
      }
    }
    final pairs = attack.length * defense.length;
    return OculumAttackForecast(
      counts[0] * 100 / pairs,
      counts[1] * 100 / pairs,
      counts[2] * 100 / pairs,
    );
  }
}
