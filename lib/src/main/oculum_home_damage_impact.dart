part of '../../main.dart';

({
  double criticalChance,
  double shieldChance,
  int normalShieldBonus,
  int oculumShieldBonus,
})
oculumMisfortuneProfile(String difficulty) {
  switch (difficulty.trim().toLowerCase()) {
    case 'difficile':
    case 'hard':
      return (
        criticalChance: 1,
        shieldChance: 2,
        normalShieldBonus: 50,
        oculumShieldBonus: 0,
      );
    case 'oculum':
      return (
        criticalChance: 3,
        shieldChance: 5,
        normalShieldBonus: 100,
        oculumShieldBonus: 100,
      );
    default:
      return (
        criticalChance: 0,
        shieldChance: 0,
        normalShieldBonus: 0,
        oculumShieldBonus: 0,
      );
  }
}

double oculumCurrentParryChancePercent({
  required int currentOculum,
  required String difficulty,
}) {
  var remaining = max(0, currentOculum);
  if (remaining <= 0) return 0;

  var tenths = min(5, remaining);
  remaining -= min(5, remaining);
  var pointsForNextTenth = 2;
  while (remaining >= pointsForNextTenth) {
    remaining -= pointsForNextTenth;
    tenths++;
    pointsForNextTenth++;
  }

  final difficultyMultiplier = switch (difficulty.trim().toLowerCase()) {
    'facile' || 'easy' => 1.5,
    'difficile' || 'hard' => 0.5,
    'oculum' => 0.2,
    _ => 1.0,
  };
  return double.parse((tenths * 0.1 * difficultyMultiplier).toStringAsFixed(3));
}

int oculumShieldEffectiveValueForDifficulty(int shield, String difficulty) {
  final safeShield = max(0, shield);
  switch (difficulty.trim().toLowerCase()) {
    case 'facile':
    case 'easy':
      return (safeShield * 3) ~/ 2;
    case 'difficile':
    case 'hard':
      return (safeShield + 1) ~/ 2;
    case 'oculum':
      return safeShield ~/ 5;
    default:
      return safeShield;
  }
}

int _oculumShieldPointsForRemainingEffectiveValue({
  required int maximumPoints,
  required int effectiveValue,
  required String difficulty,
}) {
  var low = 0;
  var high = max(0, maximumPoints);
  while (low < high) {
    final middle = (low + high + 1) ~/ 2;
    final value = oculumShieldEffectiveValueForDifficulty(middle, difficulty);
    if (value <= effectiveValue) {
      low = middle;
    } else {
      high = middle - 1;
    }
  }
  return low;
}

({int layer, int remaining, int absorbed}) oculumAbsorbDamageWithShield({
  required int layer,
  required int remaining,
  required int bonusPercent,
  required String difficulty,
}) {
  if (layer <= 0 || remaining <= 0) {
    return (layer: layer, remaining: remaining, absorbed: 0);
  }

  final effectiveCapacity = oculumShieldEffectiveValueForDifficulty(
    layer,
    difficulty,
  );
  if (effectiveCapacity <= 0) {
    return (layer: 0, remaining: remaining, absorbed: 0);
  }

  final effectiveDamage = bonusPercent <= 0
      ? remaining
      : max(1, (remaining * (100 + bonusPercent) / 100).ceil());
  final absorbedEffective = min(effectiveCapacity, effectiveDamage);
  final baseAbsorbed = bonusPercent <= 0
      ? min(remaining, absorbedEffective)
      : min(
          remaining,
          max(1, (absorbedEffective * 100 / (100 + bonusPercent)).ceil()),
        );
  final effectiveRemaining = effectiveCapacity - absorbedEffective;
  final pointsRemaining = effectiveRemaining <= 0
      ? 0
      : _oculumShieldPointsForRemainingEffectiveValue(
          maximumPoints: layer,
          effectiveValue: effectiveRemaining,
          difficulty: difficulty,
        );

  return (
    layer: pointsRemaining,
    remaining: remaining - baseAbsorbed,
    absorbed: layer - pointsRemaining,
  );
}

double oculumCurrentParryStrainChancePercent({
  required int currentOculum,
  required String difficulty,
}) {
  final safeBandPoints = min(20, max(0, currentOculum));
  final excessPoints = max(0, currentOculum - 20);
  final rates = switch (difficulty.trim().toLowerCase()) {
    'facile' || 'easy' => (safe: 0.10, excess: 0.25),
    'difficile' || 'hard' => (safe: 0.35, excess: 0.80),
    'oculum' => (safe: 0.50, excess: 1.00),
    _ => (safe: 0.20, excess: 0.50),
  };
  return (safeBandPoints * rates.safe + excessPoints * rates.excess)
      .clamp(0.0, 75.0)
      .toDouble();
}

({double chancePercent, int currentHpDivisor}) oculumBrokenCoreDamageProfile(
  String difficulty,
) {
  switch (difficulty.trim().toLowerCase()) {
    case 'facile':
    case 'easy':
      return (chancePercent: 20, currentHpDivisor: 5);
    case 'difficile':
    case 'hard':
      return (chancePercent: 50, currentHpDivisor: 2);
    case 'oculum':
      return (chancePercent: 66, currentHpDivisor: 2);
    default:
      return (chancePercent: 33, currentHpDivisor: 3);
  }
}

int oculumBrokenCoreCurrentHpDamage({
  required int currentHp,
  required String difficulty,
}) {
  final safeHp = max(0, currentHp);
  if (safeHp <= 0) return 0;
  final profile = oculumBrokenCoreDamageProfile(difficulty);
  return max(1, (safeHp / profile.currentHpDivisor).ceil());
}

bool oculumBrokenCoreCanRoll({
  required bool brokenCore,
  required int hpBeforeDamage,
  required int hpAfterDamage,
}) {
  return brokenCore && hpAfterDamage > 0 && hpAfterDamage < hpBeforeDamage;
}

extension _OculumHomeDamageImpact on _OculumHomePageState {
  int bonusDannoScudiPercentuale() {
    return max(0, leggiNumero(dannoBonusScudoPercentController));
  }

  ({int layer, int remaining, int absorbed}) assorbiDannoDaScudoConBonus({
    required int layer,
    required int remaining,
    required int bonusPercent,
  }) {
    return oculumAbsorbDamageWithShield(
      layer: layer,
      remaining: remaining,
      bonusPercent: bonusPercent,
      difficulty: normalizedCampaignDifficulty(),
    );
  }

  String applicaRecuperoSogliaExp(int soglie) {
    if (soglie <= 0) return '';
    final profile = oculumExperienceRecoveryProfile(
      normalizedCampaignDifficulty(),
    );
    final maximumHp = maxHp();
    final hpGain =
        max(1, (maximumHp / profile.milestoneHpDivisor).ceil()) * soglie;
    currentHpController.text = min(maximumHp, hpCorrenti() + hpGain).toString();

    final shieldMax = scudoOculumMax();
    final shieldGain = shieldMax <= 0
        ? 0
        : max(1, (shieldMax / profile.milestoneShieldDivisor).ceil()) * soglie;
    if (shieldGain > 0) {
      final before = scudoOculum();
      final after = min(shieldMax, before + shieldGain);
      scudoOculumController.text = after.toString();
      ripristinaScudoIntegritaOculum(after - before);
    }

    final maxOcu = max(0, oculumMassimoNaturale());
    final requestedOcuGain = maxOcu <= 0
        ? 0
        : max(1, (maxOcu / profile.milestoneOculumDivisor).ceil()) * soglie;
    final ocuGain = addOculum(
      requestedOcuGain,
      scheduleSave: false,
      deferDerivedCardNotifications: true,
    );

    return t(
      ' Soglia EXP 369 x$soglie (${campaignDifficultyLabel()}): recuperi fino a $hpGain HP, $shieldGain Scudo Oculum e $ocuGain Oculum.',
      ' EXP 369 threshold x$soglie (${campaignDifficultyLabel()}): recover up to $hpGain HP, $shieldGain Oculum Shield and $ocuGain Oculum.',
    );
  }

  String applicaRecuperoOgniCentoExp(int expGuadagnata) {
    final profile = oculumExperienceRecoveryProfile(
      normalizedCampaignDifficulty(),
    );
    final progress = oculumExperienceRecoveryProgress(
      previousRemainder: expHundredRegenRemainder,
      experienceGained: expGuadagnata,
      threshold: profile.periodicThreshold,
    );
    expHundredRegenRemainder = progress.remainder;
    if (progress.recoveries <= 0) return '';

    final hpGain = progress.recoveries * profile.periodicHp;
    final requestedOculumGain = progress.recoveries;
    final hpPrima = hpCorrenti();
    final maximumHp = maxHp();
    currentHpController.text = max(
      hpPrima,
      min(maximumHp, hpPrima + hpGain),
    ).toString();
    final oculumGain = addOculum(
      requestedOculumGain,
      scheduleSave: false,
      deferDerivedCardNotifications: true,
    );
    return t(
      ' Recupero EXP ${profile.periodicThreshold} x${progress.recoveries} (${campaignDifficultyLabel()}): fino a +$hpGain HP e +$oculumGain Oculum.',
      ' EXP ${profile.periodicThreshold} recovery x${progress.recoveries} (${campaignDifficultyLabel()}): up to +$hpGain HP and +$oculumGain Oculum.',
    );
  }

  bool risveglioParzialeMetaHpGiaTentato() {
    if (schedePersonaggio.isEmpty ||
        schedaCorrente < 0 ||
        schedaCorrente >= schedePersonaggio.length) {
      return false;
    }
    return readBoolValue(
      schedePersonaggio[schedaCorrente]['partialAwakeningHalfHpTriggered'],
    );
  }

  void segnaRisveglioParzialeMetaHpTentato() {
    if (schedePersonaggio.isEmpty ||
        schedaCorrente < 0 ||
        schedaCorrente >= schedePersonaggio.length) {
      return;
    }
    schedePersonaggio[schedaCorrente]['partialAwakeningHalfHpTriggered'] = true;
  }

  String applicaRisveglioParzialeMetaHpSeServe({
    required int hpBefore,
    required int hpAfter,
    bool oculumDodgeUsedToday = false,
  }) {
    if (hpAfter <= 0 ||
        maxHp() <= 0 ||
        hpAfter > (maxHp() / 2).ceil() ||
        risveglioParzialeMetaHpGiaTentato()) {
      return '';
    }
    segnaRisveglioParzialeMetaHpTentato();
    final roll = Random().nextInt(100);
    final maxOcu = max(0, oculumMassimo());
    final usedMostOculum =
        maxOcu > 0 && oculumTotale() <= (maxOcu * 0.25).floor();
    final canFatigue = usedMostOculum || oculumDodgeUsedToday;
    if (roll < 9) {
      aumentaStatBaseEAttuale('resilienza', 2);
      aumentaStatBaseEAttuale('oculum', 2);
      return t(
        '\nRisveglio Piccolo al 50% ($hpBefore -> $hpAfter HP): +2 Resilienza, +2 Oculum.',
        '\nSmall awakening at 50% HP ($hpBefore -> $hpAfter HP): +2 Resilience, +2 Oculum.',
      );
    }

    if (roll < 15) {
      aumentaStatBaseEAttuale('resilienza', 3);
      aumentaStatBaseEAttuale('oculum', 3);
      return t(
        '\nRisveglio Parziale al 50% ($hpBefore -> $hpAfter HP): +3 Resilienza, +3 Oculum.',
        '\nPartial awakening at 50% HP ($hpBefore -> $hpAfter HP): +3 Resilience, +3 Oculum.',
      );
    }

    if (roll < 18) {
      aumentaStatBaseEAttuale('resilienza', 5);
      aumentaStatBaseEAttuale('oculum', 5);
      aumentaStatBaseEAttuale('volonta', 5);
      aumentaStatBaseEAttuale('materia', 5);
      return t(
        '\nRisveglio Totale al 50% ($hpBefore -> $hpAfter HP): +5 a tutte le stats.',
        '\nTotal awakening at 50% HP ($hpBefore -> $hpAfter HP): +5 to all stats.',
      );
    }

    if (roll < 19 && canFatigue) {
      final svenimento = modificaCenereControllata(1);
      return t(
        '\nFatica al 50% ($hpBefore -> $hpAfter HP): +1 Cenere.${svenimento == null ? '' : '\n$svenimento'}',
        '\nFatigue at 50% HP ($hpBefore -> $hpAfter HP): +1 Ash.${svenimento == null ? '' : '\n$svenimento'}',
      );
    }
    return '';
  }

  String applicaRicompensaAscensionDustRisorsaBassa({
    required int before,
    required int after,
    required int maximum,
    required String resourceName,
  }) {
    if (maximum <= 0) return '';
    final threshold = (maximum * 0.25).floor();
    if (threshold <= 0) return '';
    if (before <= threshold || after > threshold) return '';
    final chance = oculumLowResourceDustChance(
      current: after,
      maximum: maximum,
    );
    if (chance <= 0 || Random().nextInt(100) >= chance) return '';

    final dust = Random().nextInt(2) + 1;
    ascensionDustController.text = (leggiNumero(ascensionDustController) + dust)
        .toString();
    return t(
      '\n$resourceName basso: +$dust Ascension Dust.',
      '\nLow $resourceName: +$dust Ascension Dust.',
    );
  }
}
