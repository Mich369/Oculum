import 'dart:math' as math;

/// Returns the gains from Umbravex's first living crossing of its threshold.
/// Oculum above capacity becomes Life, then temporary Life if Life is full.
({int hpRestored, int temporaryHp, int oculumRestored})?
oculumUmbravexPhaseGain({
  required int hpBefore,
  required int hpAfter,
  required int maxHp,
  required int currentOculum,
  required int maxOculum,
  required bool alreadyTriggered,
  int lifeThresholdPercent = 50,
  int hpGainPercent = 50,
  int oculumGainPercent = 65,
}) {
  final threshold = lifeThresholdPercent.clamp(0, 100) * maxHp;
  if (alreadyTriggered ||
      maxHp <= 0 ||
      hpAfter <= 0 ||
      hpBefore * 100 <= threshold ||
      hpAfter * 100 > threshold) {
    return null;
  }
  final lifeGain = hpAfter * math.max(0, hpGainPercent) ~/ 100;
  final oculumGain =
      math.max(0, currentOculum) * math.max(0, oculumGainPercent) ~/ 100;
  final oculumRestored = math.min<int>(
    oculumGain,
    math.max<int>(0, maxOculum - math.max<int>(0, currentOculum)),
  );
  final lifeToDistribute = lifeGain + oculumGain - oculumRestored;
  final hpRestored = math.min<int>(maxHp - hpAfter, lifeToDistribute);
  return (
    hpRestored: hpRestored,
    temporaryHp: lifeToDistribute - hpRestored,
    oculumRestored: oculumRestored,
  );
}

int oculumUmbravexShadowDartDamage(
  int damage, {
  required bool immaterial,
  int immaterialBonusPercent = 50,
}) => immaterial
    ? damage + math.max(0, damage) * math.max(0, immaterialBonusPercent) ~/ 100
    : damage;
