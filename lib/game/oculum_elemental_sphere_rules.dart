import 'dart:math';

const oculumElementalSphereAcidDieFaces = 30;
const oculumElementalSphereAcidDefaultTurns = 3;
const oculumElementalSphereLightningMaxAdditionalTargets = 3;

/// A hit can remove Life even when a subsequent recovery restores its balance.
int oculumElementalSphereLifeLost({int? impactLifeLost, required int netLifeLost}) =>
    max(0, impactLifeLost ?? netLifeLost);

({int powerPercent, int turns}) oculumElementalSphereDifficulty(String value) =>
    switch (value.trim().toLowerCase()) {
      'facile' => (powerPercent: 80, turns: -1),
      'difficile' => (powerPercent: 120, turns: 1),
      'oculum' => (powerPercent: 135, turns: 2),
      _ => (powerPercent: 100, turns: 0),
    };

/// Use the result of the opposed roll and the actual loss of Life from its hit.
bool oculumElementalSphereCriticalTriggers({
  required bool doubleCritical,
  required int hpLost,
}) => doubleCritical && hpLost >= 1;

/// The shield portion is applied separately from normal damage protections.
typedef OculumElementalSphereAcidTick = ({int shieldPoints, int normalDamage});

/// The persisted DoT can apply this split without the original attack packet.
OculumElementalSphereAcidTick oculumElementalSphereAcidTick(
  int natural, {
  required int gradeMultiplier,
  int powerPercent = 100,
}) {
  RangeError.checkValueInInterval(
    natural,
    1,
    oculumElementalSphereAcidDieFaces,
    'natural',
  );
  final total = max(1, max(1, gradeMultiplier) * natural * powerPercent ~/ 100);
  final shieldPoints = total ~/ 2;
  return (shieldPoints: shieldPoints, normalDamage: total - shieldPoints);
}

class OculumElementalSphereAcidPlan {
  const OculumElementalSphereAcidPlan._({
    required this.gradeMultiplier,
    required this.durationTurns,
    required this.powerPercent,
  });

  final int gradeMultiplier;
  final int durationTurns;
  final int powerPercent;

  /// A fresh d30 result is supplied by each personal turn that ticks.
  OculumElementalSphereAcidTick tick(int natural) =>
      oculumElementalSphereAcidTick(
        natural,
        gradeMultiplier: gradeMultiplier,
        powerPercent: powerPercent,
      );
}

OculumElementalSphereAcidPlan? oculumPlanElementalSphereAcid({
  required bool doubleCritical,
  required int hpLost,
  required int casterGrade,
  required int targetGrade,
  int durationTurns = oculumElementalSphereAcidDefaultTurns,
  String difficulty = 'normale',
}) {
  if (!oculumElementalSphereCriticalTriggers(
    doubleCritical: doubleCritical,
    hpLost: hpLost,
  )) {
    return null;
  }
  final profile = oculumElementalSphereDifficulty(difficulty);
  return OculumElementalSphereAcidPlan._(
    gradeMultiplier: max(1, targetGrade - casterGrade),
    durationTurns: max(1, durationTurns + profile.turns),
    powerPercent: profile.powerPercent,
  );
}

/// Call with Life actually restored after healing modifiers and maximum Life.
bool oculumElementalSphereAcidEndsOnHealing(int hpRestored) => hpRestored >= 1;

typedef OculumElementalSphereLightningPlan = ({
  int primaryBonusDamage,
  Map<String, int> secondaryDamage,
});

/// The caller checks Fight membership, hostility and target availability.
/// The secondary pool uses offensive damage, before the original target's
/// protections, and is divided once in selection order.
OculumElementalSphereLightningPlan? oculumPlanElementalSphereLightning({
  required bool doubleCritical,
  required int hpLost,
  required int resolvedDamage,
  required String primaryTargetId,
  required Iterable<String> additionalTargetIds,
  required bool hasAvailableAdditionalTargets,
  int secondaryPercentPerTarget = 75,
  int soloBonusPercent = 50,
}) {
  if (!oculumElementalSphereCriticalTriggers(
        doubleCritical: doubleCritical,
        hpLost: hpLost,
      ) ||
      resolvedDamage <= 0 ||
      primaryTargetId.trim().isEmpty) {
    return null;
  }
  final targets = additionalTargetIds.map((id) => id.trim()).toList();
  if (targets.length > oculumElementalSphereLightningMaxAdditionalTargets ||
      targets.contains('') ||
      targets.contains(primaryTargetId.trim()) ||
      targets.toSet().length != targets.length ||
      (!hasAvailableAdditionalTargets && targets.isNotEmpty)) {
    return null;
  }
  if (targets.isEmpty) {
    return (
      primaryBonusDamage: hasAvailableAdditionalTargets
          ? 0
          : resolvedDamage * max(0, soloBonusPercent) ~/ 100,
      secondaryDamage: const {},
    );
  }
  final pool =
      resolvedDamage *
      (max(0, secondaryPercentPerTarget) *
          oculumElementalSphereLightningMaxAdditionalTargets) ~/
      100;
  final perTarget = pool ~/ targets.length;
  final remainder = pool % targets.length;
  return (
    primaryBonusDamage: 0,
    secondaryDamage: {
      for (var index = 0; index < targets.length; index++)
        targets[index]: perTarget + (index < remainder ? 1 : 0),
    },
  );
}
