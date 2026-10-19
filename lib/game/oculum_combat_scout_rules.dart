import 'dart:math';

/// What a Percezione/Investigazione roll is allowed to reveal about a target.
///
/// The target resolves this locally before it publishes any values, so private
/// level, Velo and CM never have to be sent to another client before the roll.
enum OculumCombatScoutReveal { exact, approximate, insufficient }

class OculumCombatScoutRead {
  const OculumCombatScoutRead({
    required this.reveal,
    required this.requirement,
    required this.targetLevel,
    required this.targetGrade,
    required this.targetCm,
    required this.failure,
  });

  final OculumCombatScoutReveal reveal;
  final int requirement;
  final int? targetLevel;
  final int? targetGrade;
  final int? targetCm;
  final int failure;

  bool get showsProbabilities =>
      reveal == OculumCombatScoutReveal.exact ||
      reveal == OculumCombatScoutReveal.approximate;
  bool get isExact => reveal == OculumCombatScoutReveal.exact;
}

/// Resolves the confirmed Percezione threshold.
///
/// Exact information requires `level + Velo`. A miss of at most five returns
/// a deliberately lower level and defensive estimate while retaining the
/// target grade. A larger miss exposes no combat probability information.
OculumCombatScoutRead oculumCombatScoutRead({
  required int rollTotal,
  required int targetLevel,
  required int targetVelo,
  required int targetGrade,
  required int targetCm,
}) {
  final level = max(0, targetLevel);
  final velo = max(0, targetVelo);
  final grade = max(0, targetGrade);
  final cm = max(0, targetCm);
  final requirement = level + velo;
  final failure = max(0, requirement - rollTotal);
  if (failure == 0) {
    return OculumCombatScoutRead(
      reveal: OculumCombatScoutReveal.exact,
      requirement: requirement,
      targetLevel: level,
      targetGrade: grade,
      targetCm: cm,
      failure: 0,
    );
  }
  if (failure <= 5) {
    return OculumCombatScoutRead(
      reveal: OculumCombatScoutReveal.approximate,
      requirement: requirement,
      targetLevel: max(0, level - max(1, failure)),
      targetGrade: grade,
      targetCm: max(0, cm - max(1, failure)),
      failure: failure,
    );
  }
  return OculumCombatScoutRead(
    reveal: OculumCombatScoutReveal.insufficient,
    requirement: requirement,
    targetLevel: null,
    targetGrade: null,
    targetCm: null,
    failure: failure,
  );
}
