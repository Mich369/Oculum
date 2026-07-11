part of '../../main.dart';

extension _OculumHomeDamageImpact on _OculumHomePageState {
  int bonusDannoScudiPercentuale() {
    return max(0, leggiNumero(dannoBonusScudoPercentController));
  }

  ({int layer, int remaining, int absorbed}) assorbiDannoDaScudoConBonus({
    required int layer,
    required int remaining,
    required int bonusPercent,
  }) {
    if (layer <= 0 || remaining <= 0) {
      return (layer: layer, remaining: remaining, absorbed: 0);
    }
    if (bonusPercent <= 0) {
      final absorbed = min(layer, remaining);
      return (
        layer: layer - absorbed,
        remaining: remaining - absorbed,
        absorbed: absorbed,
      );
    }

    final effectiveDamage = max(
      1,
      (remaining * (100 + bonusPercent) / 100).ceil(),
    );
    final absorbed = min(layer, effectiveDamage);
    final baseConsumed = min(
      remaining,
      max(1, (absorbed * 100 / (100 + bonusPercent)).ceil()),
    );
    return (
      layer: layer - absorbed,
      remaining: remaining - baseConsumed,
      absorbed: absorbed,
    );
  }

  String applicaRecuperoSogliaExp(int soglie) {
    if (soglie <= 0) return '';
    final hpGain = max(1, (maxHp() / 4).ceil()) * soglie;
    currentHpController.text = min(maxHp(), hpCorrenti() + hpGain).toString();
    ricaricaScudoOculum();

    final maxOcu = max(0, oculumMassimo());
    final ocuGain = maxOcu <= 0 ? 0 : max(1, (maxOcu / 3).ceil()) * soglie;
    if (ocuGain > 0) {
      currentOculumController.text = min(
        maxOcu,
        currentOculum() + ocuGain,
      ).toString();
      invalidateHiddenEyeDerivedCaches();
    }

    return t(
      ' Soglia EXP 369 x$soglie: recuperi fino a $hpGain HP, Scudo Oculum e $ocuGain Oculum.',
      ' EXP 369 threshold x$soglie: recover up to $hpGain HP, Oculum Shield and $ocuGain Oculum.',
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
        maxOcu > 0 && currentOculum() <= (maxOcu * 0.25).floor();
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
}
