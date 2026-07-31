part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member, unused_element

class _OculumCalendarPhase {
  const _OculumCalendarPhase({
    required this.id,
    required this.nameIt,
    required this.nameEn,
    required this.startDay,
    required this.duration,
    required this.descriptionIt,
    required this.descriptionEn,
  });

  final String id;
  final String nameIt;
  final String nameEn;
  final int startDay;
  final int duration;
  final String descriptionIt;
  final String descriptionEn;

  int get endDay => startDay + duration - 1;
}

int oculumLongRestHpTarget({required int currentHp, required int maxHp}) {
  final safeMax = max(1, maxHp);
  final safeCurrent = currentHp.clamp(0, safeMax).toInt();
  final seventyFivePercent = (safeMax * 3 / 4).ceil();
  return max(safeCurrent, seventyFivePercent);
}

int oculumArtMaximumValue({required int level, required int grade}) {
  return 100 + max(0, level) * 20 + max(0, grade) * 100;
}

int oculumArtLongRestRecovery(
  int maximum, {
  bool limitedAfterFullExhaustion = false,
}) {
  final safeMaximum = max(0, maximum);
  return limitedAfterFullExhaustion
      ? (safeMaximum / 10).ceil()
      : (safeMaximum / 4).ceil();
}

int oculumArtRecoveredValue({
  required int current,
  required int maximum,
  bool limitedAfterFullExhaustion = false,
}) {
  final safeMaximum = max(0, maximum);
  return (max(0, current) +
          oculumArtLongRestRecovery(
            safeMaximum,
            limitedAfterFullExhaustion: limitedAfterFullExhaustion,
          ))
      .clamp(0, safeMaximum)
      .toInt();
}

const int oculumArtActivationCost = 10;

int oculumArtUseCostForDifficulty(int baseCost, String difficulty) {
  final safeCost = max(0, baseCost);
  final normalized = difficulty.trim().toLowerCase();
  return normalized == 'difficile' ||
          normalized == 'hard' ||
          normalized == 'oculum'
      ? safeCost * 2
      : safeCost;
}

({int plusOneDt, int plusThreeDt}) oculumArtLowIntegrityDebuffChances(
  String difficulty,
) {
  final normalized = difficulty.trim().toLowerCase();
  if (normalized == 'oculum') return (plusOneDt: 20, plusThreeDt: 15);
  if (normalized == 'difficile' || normalized == 'hard') {
    return (plusOneDt: 15, plusThreeDt: 10);
  }
  return (plusOneDt: 10, plusThreeDt: 5);
}

bool oculumArtIsAtOrBelowLowIntegrity({
  required int current,
  required int maximum,
}) {
  final safeMaximum = max(0, maximum);
  if (safeMaximum <= 0) return false;
  return max(0, current) * 4 <= safeMaximum;
}

int oculumArtLowIntegrityDtForRoll({
  required int roll,
  required String difficulty,
}) {
  final safeRoll = roll.clamp(0, 99).toInt();
  final chances = oculumArtLowIntegrityDebuffChances(difficulty);
  if (safeRoll < chances.plusOneDt) return 1;
  if (safeRoll < chances.plusOneDt + chances.plusThreeDt) return 3;
  return 0;
}

int oculumArtSkillLevelChangeCost({
  required int previousLevel,
  required int nextLevel,
  int stepCost = oculumArtActivationCost,
}) {
  final safePrevious = max(0, previousLevel);
  final safeNext = max(0, nextLevel);
  final safeStepCost = max(0, stepCost);
  if (safeNext == 0 || safeNext == safePrevious) return 0;
  if (safePrevious == 0) return safeNext * safeStepCost;
  return (safeNext - safePrevious).abs() * safeStepCost;
}

bool oculumArtCanActivate(int current, {int cost = oculumArtActivationCost}) {
  return max(0, current) >= max(0, cost);
}

int oculumArtValueAfterActivation(
  int current, {
  int cost = oculumArtActivationCost,
}) {
  final safeCurrent = max(0, current);
  final safeCost = max(0, cost);
  return oculumArtCanActivate(safeCurrent, cost: safeCost)
      ? safeCurrent - safeCost
      : safeCurrent;
}

int oculumAggiustaNucleoRoundedTotal(int total) {
  final safeTotal = max(0, total);
  final units = safeTotal % 10;
  final rounded = units <= 5 ? safeTotal - units : safeTotal + (10 - units);
  return max(10, rounded);
}

int oculumAggiustaNucleoEffectiveRecovery({
  required int current,
  required int maximum,
  required int roundedTotal,
}) {
  final safeMaximum = max(0, maximum);
  final safeCurrent = current.clamp(0, safeMaximum).toInt();
  return min(max(0, roundedTotal), safeMaximum - safeCurrent);
}

class OculumAggiustaNucleoResult {
  const OculumAggiustaNucleoResult({
    required this.message,
    required this.artName,
    required this.d10,
    required this.medicine,
    required this.rawTotal,
    required this.roundedTotal,
    required this.effectiveRecovery,
    required this.lostRecovery,
    required this.integrityBefore,
    required this.integrityAfter,
    required this.integrityMaximum,
  });

  final String message;
  final String artName;
  final int d10;
  final int medicine;
  final int rawTotal;
  final int roundedTotal;
  final int effectiveRecovery;
  final int lostRecovery;
  final int integrityBefore;
  final int integrityAfter;
  final int integrityMaximum;
}

extension _OculumHomeResourcesRestTitlesData on _OculumHomePageState {
  // RISORSE / ISPIRAZIONI / KARMA
  // =====================================================

  void modificaRisorsa(TextEditingController controller, int delta) {
    final valoreAttuale = leggiNumero(controller);
    final nuovoValore = max(0, valoreAttuale + delta);

    setState(() {
      controller.text = nuovoValore.toString();

      aggiungiLog(
        'Risorsa modificata: ${delta >= 0 ? '+' : ''}$delta → $nuovoValore.',
      );
    });

    programmaSalvataggio();
  }

  void modificaFortuna(int delta) {
    setState(() {
      fortuna = max(0, fortuna + delta);
      invalidateHiddenEyeDerivedCaches();
      risultato = t('Fortuna aggiornata: $fortuna.', 'Luck updated: $fortuna.');
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void usaFortunaRapida() {
    if (fortuna <= 0) {
      setState(() {
        risultato = t('Nessuna Fortuna disponibile.', 'No Luck available.');
        aggiungiLog(risultato);
      });
      return;
    }

    setState(() => fortuna = max(0, fortuna - 1));

    final bonusTargets = <({String rawKey, String label})>[
      (rawKey: 'TiroStats', label: t('Tiri stats', 'Stat rolls')),
      (rawKey: 'TiroAttacco', label: t('Tiri attacco', 'Attack rolls')),
      (rawKey: 'TiroDifesa', label: t('Tiri difesa', 'Defense rolls')),
      (rawKey: 'Iniziativa', label: t('Iniziativa', 'Initiative')),
    ];

    for (final target in bonusTargets) {
      modificaBuffMalusRapido(
        rawKey: target.rawKey,
        label: target.label,
        delta: 1,
        log: false,
        save: false,
      );
    }

    setState(() {
      risultato = t(
        'Fortuna consumata: +1 a stats, attacco, difesa e iniziativa tramite bonus rapidi. Fortuna rimasta: $fortuna.',
        'Luck consumed: +1 to stats, attack, defense and initiative through quick bonuses. Luck left: $fortuna.',
      );
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void modificaKarmaBase(int delta) {
    setState(() {
      karmaController.text = (leggiNumero(karmaController) + delta).toString();
      syncReputationsWithKarma();

      risultato = t(
        'Karma modificato: ${karmaController.text}.',
        'Karma changed: ${karmaController.text}.',
      );

      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void modificaKarmaTitolo(TextEditingController controller, int valore) {
    setState(() {
      controller.text = clampKarmaTitolo(valore).toString();
    });

    programmaSalvataggio();
  }

  void usaIspirazioneBase() {
    final valore = leggiNumero(ispirazioniController);

    if (valore <= 0) {
      setState(() {
        risultato = t(
          'Non hai Ispirazioni base da usare.',
          'You have no base Inspirations to use.',
        );
      });

      return;
    }

    setState(() {
      ispirazioniController.text = (valore - 1).toString();
      final cancelled = cancelPreviousRollForInspiration();

      risultato = t(
        '$cancelled\nIspirazione usata: il tiro precedente non vale e puoi ritirare un tiro non critico.',
        '$cancelled\nInspiration used: the previous roll does not count and you may reroll a non-critical roll.',
      );

      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void usaSuperIspirazione() {
    final valore = leggiNumero(superIspirazioniController);

    if (valore <= 0) {
      setState(() {
        risultato = t(
          'Non hai Super Ispirazioni da usare.',
          'You have no Super Inspirations to use.',
        );
      });

      return;
    }

    setState(() {
      superIspirazioniController.text = (valore - 1).toString();
      final cancelled = cancelPreviousRollForInspiration();

      risultato = t(
        '$cancelled\nSuper Ispirazione usata: il tiro precedente non vale e puoi ritirare anche un critico.',
        '$cancelled\nSuper Inspiration used: the previous roll does not count and you may reroll even a critical roll.',
      );

      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void usaIspirazioneOculum() {
    final valore = leggiNumero(ispirazioniOculumController);

    if (valore <= 0) {
      setState(() {
        risultato = t(
          'Non hai Ispirazioni Oculum da usare.',
          'You have no Oculum Inspirations to use.',
        );
      });

      return;
    }

    setState(() {
      ispirazioniOculumController.text = (valore - 1).toString();
      final cancelled = cancelPreviousRollForInspiration();

      risultato = t(
        '$cancelled\nIspirazione Oculum usata: il tiro precedente non vale e puoi ritirare un critico mantenendolo critico.',
        '$cancelled\nOculum Inspiration used: the previous roll does not count and you may reroll a critical roll while keeping it critical.',
      );

      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void convertiIspirazioneOculum() {
    final valore = leggiNumero(ispirazioniOculumController);

    if (valore <= 0) {
      setState(() {
        risultato = t(
          'Non hai Ispirazioni Oculum da convertire.',
          'You have no Oculum Inspirations to convert.',
        );
      });

      return;
    }

    setState(() {
      ispirazioniOculumController.text = (valore - 1).toString();

      ispirazioniController.text = (leggiNumero(ispirazioniController) + 2)
          .toString();

      risultato = t(
        'Ispirazione Oculum convertita in 2 Ispirazioni base.',
        'Oculum Inspiration converted into 2 base Inspirations.',
      );

      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  String normalizedCampaignDifficulty([String? value]) {
    return normalizeTemporaryOculumDifficulty(value ?? campaignDifficulty);
  }

  String campaignDifficultyLabel([String? value]) {
    switch (normalizedCampaignDifficulty(value)) {
      case 'facile':
        return t('Facile', 'Easy');
      case 'difficile':
        return t('Difficile', 'Hard');
      case 'oculum':
        return 'Oculum';
      default:
        return t('Normale', 'Normal');
    }
  }

  int inspirationCap(String type) {
    final diff = normalizedCampaignDifficulty();
    switch (type) {
      case 'super':
        if (diff == 'oculum') return 3;
        if (diff == 'facile') return 9;
        return 6;
      case 'oculum':
        if (diff == 'oculum') return 1;
        if (diff == 'difficile') return 3;
        return 6;
      default:
        if (diff == 'oculum') return 6;
        if (diff == 'difficile') return 9;
        if (diff == 'facile') return 12;
        return 10;
    }
  }

  ({int obser, int dust, int luck}) inspirationOverflowReward(String type) {
    final diff = normalizedCampaignDifficulty();
    switch (type) {
      case 'super':
        if (diff == 'oculum') return (obser: 10, dust: 1, luck: 2);
        if (diff == 'difficile') return (obser: 20, dust: 1, luck: 2);
        if (diff == 'facile') return (obser: 50, dust: 2, luck: 2);
        return (obser: 50, dust: 1, luck: 2);
      case 'oculum':
        if (diff == 'facile') return (obser: 100, dust: 6, luck: 3);
        if (diff == 'normale') return (obser: 80, dust: 5, luck: 3);
        return (obser: 69, dust: 3, luck: 3);
      default:
        if (diff == 'oculum') return (obser: 3, dust: 0, luck: 1);
        if (diff == 'difficile') return (obser: 5, dust: 0, luck: 1);
        if (diff == 'facile') return (obser: 25, dust: 0, luck: 1);
        return (obser: 10, dust: 0, luck: 1);
    }
  }

  void grantInspirationWithCap(
    String type,
    int amount,
    List<String> rewardLog,
  ) {
    final controller = switch (type) {
      'super' => superIspirazioniController,
      'oculum' => ispirazioniOculumController,
      _ => ispirazioniController,
    };
    final label = switch (type) {
      'super' => 'Super Ispirazione',
      'oculum' => 'Ispirazione Oculum',
      _ => 'Ispirazione',
    };
    final cap = inspirationCap(type);
    for (var i = 0; i < amount; i++) {
      final current = leggiNumero(controller);
      if (current < cap) {
        controller.text = (current + 1).toString();
        rewardLog.add('+$label');
      } else {
        final overflow = inspirationOverflowReward(type);
        if (overflow.obser > 0) {
          obserController.text = (leggiNumero(obserController) + overflow.obser)
              .toString();
        }
        if (overflow.dust > 0) {
          ascensionDustController.text =
              (leggiNumero(ascensionDustController) + overflow.dust).toString();
        }
        fortuna += overflow.luck;
        rewardLog.add(
          '$label piena: +${overflow.obser} Obser'
          '${overflow.dust > 0 ? ', +${overflow.dust} Ascension Dust' : ''}, +${overflow.luck} Fortuna',
        );
      }
    }
  }

  TextEditingController inspirationControllerForType(String type) {
    return switch (type) {
      'super' => superIspirazioniController,
      'oculum' => ispirazioniOculumController,
      _ => ispirazioniController,
    };
  }

  String inspirationLabelForType(String type) {
    return switch (type) {
      'super' => t('Super Ispirazione', 'Super Inspiration'),
      'oculum' => t('Ispirazione Oculum', 'Oculum Inspiration'),
      _ => t('Ispirazione', 'Inspiration'),
    };
  }

  void normalizeInspirationOverflow({bool silent = false}) {
    final rewardLog = <String>[];
    for (final type in const ['base', 'super', 'oculum']) {
      final controller = inspirationControllerForType(type);
      final cap = inspirationCap(type);
      var current = leggiNumero(controller);
      while (current > cap) {
        controller.text = cap.toString();
        current--;
        final reward = inspirationOverflowReward(type);
        obserController.text = (leggiNumero(obserController) + reward.obser)
            .toString();
        ascensionDustController.text =
            (leggiNumero(ascensionDustController) + reward.dust).toString();
        fortuna += reward.luck;
        rewardLog.add(
          '${inspirationLabelForType(type)} extra: +${reward.obser} Obser'
          '${reward.dust > 0 ? ', +${reward.dust} Ascension Dust' : ''}, +${reward.luck} Fortuna',
        );
      }
    }
    if (rewardLog.isEmpty) return;
    setState(() {
      risultato = rewardLog.join('\n');
      if (!silent) aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  void convertiIspirazioneInRicompense(String type, {int amount = 1}) {
    final controller = inspirationControllerForType(type);
    final available = leggiNumero(controller);
    final converted = min(max(0, amount), available);
    if (converted <= 0) {
      setState(() {
        risultato = t(
          'Nessuna ${inspirationLabelForType(type)} da convertire.',
          'No ${inspirationLabelForType(type)} to convert.',
        );
        aggiungiLog(risultato);
      });
      return;
    }

    final reward = inspirationOverflowReward(type);
    setState(() {
      controller.text = (available - converted).toString();
      obserController.text =
          (leggiNumero(obserController) + reward.obser * converted).toString();
      ascensionDustController.text =
          (leggiNumero(ascensionDustController) + reward.dust * converted)
              .toString();
      fortuna += reward.luck * converted;
      risultato =
          '${inspirationLabelForType(type)} convertite: $converted -> +${reward.obser * converted} Obser'
          '${reward.dust > 0 ? ', +${reward.dust * converted} Ascension Dust' : ''}, +${reward.luck * converted} Fortuna.';
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  void ensureCampaignStarterRewards(List<String> rewardLog) {
    if (campaignDifficultyStarterClaimed) return;
    final diff = normalizedCampaignDifficulty();
    campaignDifficultyStarterClaimed = true;
    if (diff == 'difficile') {
      grantInspirationWithCap('base', 1, rewardLog);
    } else if (diff == 'normale') {
      grantInspirationWithCap('base', 1, rewardLog);
      grantInspirationWithCap('super', 1, rewardLog);
    } else if (diff == 'facile') {
      grantInspirationWithCap('base', 1, rewardLog);
      grantInspirationWithCap('super', 1, rewardLog);
      grantInspirationWithCap('oculum', 1, rewardLog);
    }
  }

  void grantDiaryRewardsByCampaign(int diaryNumber, List<String> rewardLog) {
    final diff = normalizedCampaignDifficulty();
    if (diff == 'facile') {
      grantInspirationWithCap('base', 1, rewardLog);
      if (diaryNumber % 2 == 0) {
        grantInspirationWithCap('super', 1, rewardLog);
      }
      if (diaryNumber % 9 == 0) {
        grantInspirationWithCap('oculum', 1, rewardLog);
      }
      return;
    }
    if (diff == 'normale') {
      grantInspirationWithCap('base', 1, rewardLog);
      return;
    }
    if (diaryNumber % 2 == 0) {
      grantInspirationWithCap('base', 1, rewardLog);
    }
  }

  // =====================================================
  // RIPOSO / BISOGNI / CENERE
  // =====================================================

  int recuperoPercentuale(int valore, double percentuale, int minimo) {
    if (valore <= 0) return 0;

    final recupero = (valore * percentuale).ceil();

    return max(minimo, recupero);
  }

  List<_OculumCalendarPhase> oculumCalendarPhases() => const [
    _OculumCalendarPhase(
      id: 'safe_monster',
      nameIt: 'Safe Monster',
      nameEn: 'Safe Monster',
      startDay: 1,
      duration: 36,
      descriptionIt:
          'I mostri poco organizzati perdono il grado, dimenticano tutto e diventano pacifici. Ucciderli di solito dona karma negativo e i drop restano solo base o rari.',
      descriptionEn:
          'Poorly organized monsters lose grade, forget everything and become peaceful. Killing them usually gives negative karma and drops stay basic or rare.',
    ),
    _OculumCalendarPhase(
      id: 'illness',
      nameIt: 'Illness',
      nameEn: 'Illness',
      startDay: 37,
      duration: 36,
      descriptionIt:
          'La Follia ricevuta raddoppia, gli altri diventano visibili a tutti ed e possibile ottenere Illness Art.',
      descriptionEn:
          'Madness received is doubled, the others become visible to everyone and Illness Art can be obtained.',
    ),
    _OculumCalendarPhase(
      id: 'little_breath',
      nameIt: 'Little Breath',
      nameEn: 'Little Breath',
      startDay: 73,
      duration: 36,
      descriptionIt:
          'Il Fato concede piu titoli, soprattutto ai rebirthati. Gli effetti climatici sono indeboliti e il sentore delle aree si percepisce meno.',
      descriptionEn:
          'Fate grants more titles, especially to reborn characters. Weather effects are weakened and area pressure is harder to feel.',
    ),
    _OculumCalendarPhase(
      id: 'piogge_fertilizzanti',
      nameIt: 'Piogge Fertilizzanti',
      nameEn: 'Fertilizing Rains',
      startDay: 109,
      duration: 36,
      descriptionIt:
          'Piove fango fertilizzante nauseante. Malanni e Nausea sono piu comuni; i maiali di fango diventano una fonte rischiosa ma utile contro le malattie.',
      descriptionEn:
          'Nauseating fertilizing mud rains from the sky. Sickness and Nausea are more common; mud pigs become a risky but useful source against illness.',
    ),
    _OculumCalendarPhase(
      id: 'the_sun',
      nameIt: 'The Sun',
      nameEn: 'The Sun',
      startDay: 145,
      duration: 6,
      descriptionIt:
          'I Solari ricevono +25% alle stats, non piove e il cibo sotto grado VI diventa putrefatto entro massimo due giorni.',
      descriptionEn:
          'Solar beings gain +25% stats, rain stops and food below grade VI rots within at most two days.',
    ),
    _OculumCalendarPhase(
      id: 'mezzo_ciclo',
      nameIt: 'Mezzo Ciclo',
      nameEn: 'Half Cycle',
      startDay: 151,
      duration: 33,
      descriptionIt:
          'Il meteo torna reggibile quasi ovunque e le piogge sono principalmente non magiche.',
      descriptionEn:
          'Weather becomes bearable almost everywhere and rain is mostly non-magical.',
    ),
    _OculumCalendarPhase(
      id: 'the_moon',
      nameIt: 'The Moon',
      nameEn: 'The Moon',
      startDay: 184,
      duration: 6,
      descriptionIt:
          'Si festeggia accettando ogni razza; i Lunari ricevono +10%.',
      descriptionEn:
          'People celebrate by accepting every race; Lunar beings gain +10%.',
    ),
    _OculumCalendarPhase(
      id: 'the_fate',
      nameIt: 'The Fate',
      nameEn: 'The Fate',
      startDay: 190,
      duration: 36,
      descriptionIt:
          'Chi possiede un Fato e potenziato contro chi non ne possiede uno.',
      descriptionEn:
          'Those who have a Fate are empowered against those who do not.',
    ),
    _OculumCalendarPhase(
      id: 'caldo_infernale',
      nameIt: 'Caldo Infernale',
      nameEn: 'Infernal Heat',
      startDay: 226,
      duration: 36,
      descriptionIt:
          'Il caldo pesa molto di piu. Senza bere ogni ora subisci debuff a Volonta in base alla fatica: 1/3/6/9/12.',
      descriptionEn:
          'Heat is much harsher. Without drinking every hour, Will is debuffed by exertion: 1/3/6/9/12.',
    ),
    _OculumCalendarPhase(
      id: 'the_null',
      nameIt: 'The Null',
      nameEn: 'The Null',
      startDay: 262,
      duration: 36,
      descriptionIt:
          'Il vuoto prende parte dei caduti e li fa rinascere Senza Fato, privi di ricordi o con ricordi falsati.',
      descriptionEn:
          'The void takes some of the fallen and returns them Fate-less, without memories or with false memories.',
    ),
    _OculumCalendarPhase(
      id: 'ghiaccio_imponente',
      nameIt: 'Ghiaccio Imponente',
      nameEn: 'Overwhelming Ice',
      startDay: 298,
      duration: 36,
      descriptionIt:
          'Il freddo pesa molto di piu. Senza calore per oltre mezz ora subisci debuff a Materia: 1/3/6/9/12.',
      descriptionEn:
          'Cold is much harsher. Without heat for more than half an hour, Materia is debuffed: 1/3/6/9/12.',
    ),
    _OculumCalendarPhase(
      id: 'ultimo_ciclo',
      nameIt: 'Ultimo Ciclo',
      nameEn: 'Last Cycle',
      startDay: 334,
      duration: 36,
      descriptionIt:
          'Si festeggia il ciclo passato. Non ci sono peculiarita meccaniche.',
      descriptionEn:
          'The past cycle is celebrated. There are no special mechanics.',
    ),
  ];

  int normalizzaGiornoOculum(int day) {
    return ((day - 1) % 369) + 1;
  }

  int oculumCurrentDay() {
    final raw = leggiNumero(oculumCurrentDayController);
    if (raw <= 0) return 1;
    return normalizzaGiornoOculum(raw);
  }

  _OculumCalendarPhase oculumPhaseForDay(int day) {
    final normalized = normalizzaGiornoOculum(day);
    return oculumCalendarPhases().firstWhere(
      (phase) => normalized >= phase.startDay && normalized <= phase.endDay,
      orElse: () => oculumCalendarPhases().first,
    );
  }

  int oculumDayInPhase(int day) {
    final phase = oculumPhaseForDay(day);
    return normalizzaGiornoOculum(day) - phase.startDay + 1;
  }

  int oculumTremanaDay(int day) => ((normalizzaGiornoOculum(day) - 1) % 3) + 1;

  int oculumSemanaDay(int day) => ((normalizzaGiornoOculum(day) - 1) % 6) + 1;

  int oculumDodemanaDay(int day) =>
      ((normalizzaGiornoOculum(day) - 1) % 12) + 1;

  int oculumDayDistance(int startDay, int currentDay) {
    final start = normalizzaGiornoOculum(startDay);
    final current = normalizzaGiornoOculum(currentDay);
    if (current >= start) return current - start;
    return (369 - start) + current;
  }

  String oculumCurrentPhaseLabel() {
    final day = oculumCurrentDay();
    final phase = oculumPhaseForDay(day);
    return '${t(phase.nameIt, phase.nameEn)} ${oculumDayInPhase(day)}/${phase.duration} - ${t('Ciclo giorno', 'Cycle day')} $day';
  }

  void impostaGiornoOculum(int day, {bool annuncia = true}) {
    final normalized = normalizzaGiornoOculum(day);
    setState(() {
      oculumCurrentDayController.text = normalized.toString();
      final marciti = aggiornaPutrefazioneInventarioPerGiorno(normalized);
      final phase = oculumPhaseForDay(normalized);
      final base = t(
        'Giorno Oculum impostato: ${t(phase.nameIt, phase.nameEn)} ${oculumDayInPhase(normalized)}/${phase.duration}, ciclo $normalized.',
        'Oculum day set: ${t(phase.nameIt, phase.nameEn)} ${oculumDayInPhase(normalized)}/${phase.duration}, cycle $normalized.',
      );
      risultato = marciti.isEmpty
          ? base
          : '$base\n${t('Putrefazione aggiornata', 'Rot updated')}: ${marciti.join(', ')}.';
      if (annuncia) {
        ultimoEventoRiposo = risultato;
        aggiungiLog(risultato);
      }
    });

    programmaSalvataggio();
  }

  void avanzaGiorniOculum(int delta) {
    if (delta == 0) return;
    final before = oculumCurrentDay();
    final after = normalizzaGiornoOculum(before + delta);
    setState(() {
      oculumCurrentDayController.text = after.toString();
      final marciti = aggiornaPutrefazioneInventarioPerGiorno(after);
      final phase = oculumPhaseForDay(after);
      final direction = delta > 0 ? '+$delta' : '$delta';
      risultato = t(
        'Giorni passati: $direction. Ora sei in ${t(phase.nameIt, phase.nameEn)} ${oculumDayInPhase(after)}/${phase.duration}, ciclo $after.',
        'Days passed: $direction. You are now in ${t(phase.nameIt, phase.nameEn)} ${oculumDayInPhase(after)}/${phase.duration}, cycle $after.',
      );
      if (marciti.isNotEmpty) {
        risultato +=
            '\n${t('Putrefazione aggiornata', 'Rot updated')}: ${marciti.join(', ')}.';
      }
      ultimoEventoRiposo = risultato;
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void segnaSessioneSenzaBisogni() {
    final giorni = leggiNumero(sessioniSenzaBisogniController) + 1;
    final nuovoGiorno = normalizzaGiornoOculum(oculumCurrentDay() + 1);

    setState(() {
      sessioniSenzaBisogniController.text = giorni.toString();
      oculumCurrentDayController.text = nuovoGiorno.toString();
      final marciti = aggiornaPutrefazioneInventarioPerGiorno(nuovoGiorno);

      if (giorni >= 3) {
        tempResilienza -= 1;
        rimarginaHpDaAumentoResilienza(-1);
        tempOculum -= 1;
        sessioniSenzaBisogniController.text = '0';

        ultimoEventoRiposo = t(
          'Tre giorni senza mangiare, bere o dormire: -1 Resilienza temporanea e -1 Oculum temporaneo.',
          'Three days without eating, drinking or sleeping: -1 temporary Resilience and -1 temporary Oculum.',
        );
      } else {
        ultimoEventoRiposo = t(
          'Giorno senza bisogni segnato: $giorni/3. Al terzo giorno subisci -1 Resilienza e -1 Oculum temporanei.',
          'Day without needs marked: $giorni/3. On the third day you suffer -1 temporary Resilience and -1 temporary Oculum.',
        );
      }

      if (marciti.isNotEmpty) {
        ultimoEventoRiposo +=
            '\n${t('Putrefazione aggiornata', 'Rot updated')}: ${marciti.join(', ')}.';
      }

      risultato = ultimoEventoRiposo;
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void segnaGiornoSenzaCiboAcqua() {
    final stat = Random().nextInt(4);

    setState(() {
      giorniSenzaCiboAcquaController.text =
          (leggiNumero(giorniSenzaCiboAcquaController) + 1).toString();

      if (stat == 0) {
        tempResilienza -= 1;
        rimarginaHpDaAumentoResilienza(-1);
      } else if (stat == 1) {
        tempVolonta -= 1;
      } else if (stat == 2) {
        tempMateria -= 1;
      } else {
        tempOculum -= 1;
      }

      final svenimento = modificaCenereControllata(3);

      final statNome = [
        t('Resilienza', 'Resilience'),
        t('Volontà', 'Will'),
        'Materia',
        'Oculum',
      ][stat];

      ultimoEventoRiposo = t(
        'Giorno senza cibo o acqua: -1 temporaneo a $statNome e +3 Cenere.',
        'Day without food or water: -1 temporary to $statNome and +3 Ash.',
      );

      if (svenimento != null) ultimoEventoRiposo += '\n$svenimento';
      risultato = ultimoEventoRiposo;
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void mangiaEBevi() {
    setState(() {
      modificaBuffTemporaneo('resilienza', 2, salva: false);

      modificaCenereControllata(-1, controllaSvenimento: false);

      sessioniSenzaBisogniController.text = '0';

      ultimoEventoRiposo = t(
        'Hai mangiato e bevuto a sufficienza: +2 Resilienza temporanea per il giorno, -1 Cenere e reset giorni senza bisogni.',
        'You ate and drank enough: +2 temporary Resilience for the day, -1 Ash and reset days without needs.',
      );

      risultato = ultimoEventoRiposo;
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void modificaBuffTemporaneo(String key, int delta, {bool salva = true}) {
    if (delta == 0) return;

    switch (key) {
      case 'resilienza':
        tempResilienza += delta;
        rimarginaHpDaAumentoResilienza(delta);
        break;
      case 'volonta':
        tempVolonta += delta;
        break;
      case 'materia':
        tempMateria += delta;
        break;
      case 'oculum':
        tempOculum += delta;
        break;
    }

    risultato =
        '${t('Buff temporaneo', 'Temporary buff')} ${key.toUpperCase()} ${delta > 0 ? '+' : ''}$delta.';
    ultimoEventoRiposo = risultato;
    aggiungiLog(risultato);

    if (salva) programmaSalvataggio();
  }

  void impostaBuffTemporaneo(String key, int value) {
    final current = switch (key) {
      'resilienza' => tempResilienza,
      'volonta' => tempVolonta,
      'materia' => tempMateria,
      'oculum' => tempOculum,
      _ => 0,
    };

    setState(() {
      modificaBuffTemporaneo(key, value - current, salva: false);
    });
    programmaSalvataggio();
  }

  Future<void> mostraPotenziaAscensionDust() async {
    final disponibile = max(0, leggiNumero(ascensionDustController));
    if (disponibile <= 0) {
      setState(() {
        risultato = t(
          'Non hai Ascension Dust da spendere.',
          'You have no Ascension Dust to spend.',
        );
        aggiungiLog(risultato);
      });
      return;
    }

    final controller = TextEditingController(text: '1');
    final quantita = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF10121A),
        title: Text(t('Potenzia', 'Empower')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t(
                'Disponibili: $disponibile. Ogni Dust non multipla di 3 dona +1 temporaneo a una statistica casuale fino al riposo lungo. Ogni terza Dust cumulata nel giorno prepara invece +1 permanente casuale, rivelato al riposo lungo.',
                'Available: $disponibile. Every Dust that is not a multiple of 3 grants +1 temporary to a random stat until long rest. Every third Dust accumulated during the day instead prepares a random permanent +1, revealed at long rest.',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: fieldDecoration(t('Quantità', 'Amount')),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t('Annulla', 'Cancel')),
          ),
          FilledButton(
            onPressed: () {
              final value = readIntValue(controller.text).clamp(1, disponibile);
              Navigator.pop(dialogContext, value);
            },
            child: Text(t('Potenzia', 'Empower')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (quantita == null || quantita <= 0 || !mounted) return;

    final random = Random.secure();
    var temporanei = 0;
    var permanenti = 0;
    setState(() {
      ascensionDustController.text = (disponibile - quantita).toString();
      for (var i = 0; i < quantita; i++) {
        ascensionDustUsataOggi++;
        if (ascensionDustUsataOggi % 3 == 0) {
          ascensionDustPermanentiInAttesa++;
          permanenti++;
          continue;
        }
        switch (random.nextInt(4)) {
          case 0:
            ascensionDustTempResilienza++;
            break;
          case 1:
            ascensionDustTempVolonta++;
            break;
          case 2:
            ascensionDustTempMateria++;
            break;
          default:
            ascensionDustTempOculum++;
        }
        temporanei++;
      }
      risultato = t(
        'Potenzia: spese $quantita Ascension Dust. +$temporanei punti temporanei casuali fino al riposo lungo'
            '${permanenti > 0 ? '; $permanenti aumento/i permanente/i nascosto/i sarà/saranno rivelato/i al riposo lungo' : ''}. Progressione giornaliera: $ascensionDustUsataOggi.',
        'Empower: spent $quantita Ascension Dust. +$temporanei random temporary points until long rest'
            '${permanenti > 0 ? '; $permanenti hidden permanent increase(s) will be revealed at long rest' : ''}. Daily progress: $ascensionDustUsataOggi.',
      );
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  Future<int?> _scegliQuantitaAscensionDust(int disponibile) async {
    final controller = TextEditingController(text: '1');
    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF10121A),
        title: Text(t('Quantità Dust', 'Dust amount')),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: fieldDecoration(
            t('Massimo $disponibile', 'Max $disponibile'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t('Annulla', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              readIntValue(controller.text).clamp(1, disponibile),
            ),
            child: Text(t('Conferma', 'Confirm')),
          ),
        ],
      ),
    );
    controller.dispose();
    return value;
  }

  Future<void> mostraPotenziaOculusAscensionDust() async {
    final disponibile = max(0, leggiNumero(ascensionDustController));
    if (disponibile <= 0) {
      setState(
        () => risultato = t(
          'Non hai Ascension Dust da spendere.',
          'You have no Ascension Dust to spend.',
        ),
      );
      return;
    }
    final tipo = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF10121A),
        title: Text(t('Potenzia Oculus', 'Empower Oculus')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: Text(t('Integrità Art', 'Art Integrity')),
              subtitle: Text(
                t(
                  '+10 recupero; ogni terza Dust +10 al massimo.',
                  '+10 recovery; every third Dust +10 maximum.',
                ),
              ),
              onTap: () => Navigator.pop(dialogContext, 'integrita'),
            ),
            ListTile(
              leading: const Icon(Icons.account_tree_outlined),
              title: Text(t('Sottotratti', 'Subtraits')),
              subtitle: Text(
                t(
                  '+1 temporaneo a tutto il tipo; ogni terza Dust dà 20 + Livello×2 EXP a un sottotratto casuale.',
                  '+1 temporary to the whole type; every third Dust gives 20 + Level×2 XP to a random subtrait.',
                ),
              ),
              onTap: () => Navigator.pop(dialogContext, 'sottotratti'),
            ),
          ],
        ),
      ),
    );
    if (tipo == null || !mounted) return;

    var gruppo = 'resilienza';
    var artIndex = max(0, arti.indexWhere((art) => art.sbloccata));
    if (tipo == 'integrita') {
      if (arti.isEmpty) return;
      final selected = await showDialog<int>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          backgroundColor: const Color(0xFF10121A),
          title: const Text('Art'),
          children: [
            for (var i = 0; i < arti.length; i++)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, i),
                child: Text(arti[i].nome),
              ),
          ],
        ),
      );
      if (selected == null) return;
      artIndex = selected;
    } else {
      final selected = await showDialog<String>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          backgroundColor: const Color(0xFF10121A),
          title: Text(t('Tipo di sottotratti', 'Subtrait type')),
          children: [
            for (final entry in const <String, String>{
              'resilienza': 'Resilienza',
              'volonta': 'Volontà',
              'materia': 'Materia',
              'oculum': 'Oculum',
              'altro': 'Altro',
            }.entries)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, entry.key),
                child: Text(entry.value),
              ),
          ],
        ),
      );
      if (selected == null) return;
      gruppo = selected;
    }

    final quantita = await _scegliQuantitaAscensionDust(disponibile);
    if (quantita == null || !mounted) return;
    final random = Random.secure();
    var effettiTerzi = 0;
    setState(() {
      ascensionDustController.text = (disponibile - quantita).toString();
      for (var i = 0; i < quantita; i++) {
        ascensionDustUsataOggi++;
        if (ascensionDustUsataOggi % 3 == 0) {
          if (tipo == 'integrita') {
            ascensionDustIntegritaMassimaBonus += 10;
          } else {
            final stats = hiddenEyeStatsForGroup(
              gruppo,
            ).where((stat) => stat.unlocked).toList(growable: false);
            if (stats.isNotEmpty) {
              oculusSubtraitMasteryApplyGain(
                stats[random.nextInt(stats.length)],
                20 + max(0, leggiNumero(livelloController)) * 2,
              );
            }
          }
          effettiTerzi++;
          continue;
        }
        if (tipo == 'integrita') {
          ensureArtIntegrityValue(artIndex);
          arti[artIndex].integritaCorrente = min(
            artIntegrityMaximum(),
            arti[artIndex].integritaCorrente + 10,
          );
        } else {
          ascensionDustSottotrattiTemporanei.update(
            gruppo,
            (value) => value + 1,
            ifAbsent: () => 1,
          );
        }
      }
      if (tipo == 'integrita') notifyArtIntegrityChanged(artIndex);
      if (tipo == 'sottotratti') {
        invalidateHiddenEyeDerivedCaches();
      }
      risultato = t(
        'Spese $quantita Dust su $tipo. Effetti permanenti ogni tre: $effettiTerzi. Totale giornaliero: $ascensionDustUsataOggi.',
        'Spent $quantita Dust on $tipo. Every-third permanent effects: $effettiTerzi. Daily total: $ascensionDustUsataOggi.',
      );
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  void modificaConsumoRegistrato(String key, int delta) {
    setState(() {
      switch (key) {
        case 'resilienza':
          raccoltaResilienzaSpesa = max(0, raccoltaResilienzaSpesa + delta);
          break;
        case 'volonta':
          raccoltaVolontaSpesa = max(0, raccoltaVolontaSpesa + delta);
          break;
        case 'materia':
          raccoltaMateriaSpesa = max(0, raccoltaMateriaSpesa + delta);
          break;
        case 'oculum':
          raccoltaOculumSpesa = max(0, raccoltaOculumSpesa + delta);
          break;
      }

      ultimoEventoRiposo = t(
        'Consumo registrato modificato manualmente.',
        'Recorded consumption edited manually.',
      );
      risultato = ultimoEventoRiposo;
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void impostaConsumoRegistrato(String key, int value) {
    final current = switch (key) {
      'resilienza' => raccoltaResilienzaSpesa,
      'volonta' => raccoltaVolontaSpesa,
      'materia' => raccoltaMateriaSpesa,
      'oculum' => raccoltaOculumSpesa,
      _ => 0,
    };

    modificaConsumoRegistrato(key, value - current);
  }

  void riposoBreve() {
    setState(() {
      final cenere = leggiNumero(cenereController);
      final rimuoveMalusEsplosione = malusTiriOculumPostEsplosione < 0;
      final hpPrima = hpCorrenti();
      final tiroCuraHp = Random.secure().nextInt(100) + 1;

      impostaCenereControllata(
        max(0, cenere - recuperoPercentuale(cenere, 0.25, 1)),
        precedente: cenere,
        controllaSvenimento: false,
      );

      // I modificatori temporanei terminano al riposo breve. La loro rimozione
      // non deve essere trattata come danno e quindi non sottrae mai HP.
      tempResilienza = 0;
      tempVolonta = 0;
      tempMateria = 0;
      tempOculum = 0;

      recuperaStatsAttualiConRiposoBreve();
      currentHpController.text = oculumShortRestHpAfter(
        current: hpPrima,
        maximum: maxHp(),
        d100: tiroCuraHp,
      ).toString();
      final hpRecuperati = hpCorrenti() - hpPrima;
      ricaricaScudoOculum();

      raccoltaResilienzaSpesa = max(0, raccoltaResilienzaSpesa ~/ 2);
      raccoltaVolontaSpesa = max(0, raccoltaVolontaSpesa ~/ 2);
      raccoltaMateriaSpesa = max(0, raccoltaMateriaSpesa ~/ 2);
      raccoltaOculumSpesa = max(0, raccoltaOculumSpesa ~/ 2);
      final presaMassima = presaMaterialiMassimoGrammi();
      final recuperoPresa = presaMassima <= 0
          ? 0
          : max(500, (presaMassima / 4).ceil());
      presaMaterialiGrammi = min(
        presaMassima,
        presaMaterialiGrammi + recuperoPresa,
      );
      malusTiriOculumPostEsplosione = 0;

      ultimoEventoRiposo = t(
        'Riposo breve: buff e debuff temporanei rimossi senza perdere HP; recuperato 1/4 delle stats attuali mancanti, 25% di Cenere minimo 1 e $tiroCuraHp su 1d100 HP (+$hpRecuperati effettivi).',
        'Short rest: temporary buffs and debuffs removed without losing HP; recovered 1/4 of missing current stats, 25% Ash minimum 1 and $tiroCuraHp on 1d100 HP (+$hpRecuperati effective).',
      );
      if (recuperoPresa > 0) {
        ultimoEventoRiposo += t(
          '\nPresa materiali recuperata: ${formatoPesoMateriali(recuperoPresa)} (massimo ${formatoPesoMateriali(presaMassima)}).',
          '\nMaterial capacity recovered: ${formatoPesoMateriali(recuperoPresa)} (maximum ${formatoPesoMateriali(presaMassima)}).',
        );
      }
      if (rimuoveMalusEsplosione) {
        ultimoEventoRiposo += t(
          '\nMalus Esplosione di Oculum rimosso.',
          '\nOculum Burst penalty removed.',
        );
      }

      risultato = ultimoEventoRiposo;
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void riposoLungo() {
    if (longRestInProgress) return;
    longRestInProgress = true;
    final changedArtIndexes = <int>[];
    var limitedArtRecoveries = 0;
    final aggiustaNucleoEraUsato = aggiustaNucleoUsato;
    final potenziamentiPermanentiRivelati = <String>[];
    setState(() {
      final cenere = leggiNumero(cenereController);
      final rimuoveMalusEsplosione = malusTiriOculumPostEsplosione < 0;

      impostaCenereControllata(
        max(0, cenere - recuperoPercentuale(cenere, 0.50, 3)),
        precedente: cenere,
        controllaSvenimento: false,
      );

      final deficitRes = tempResilienza < 0 ? -tempResilienza : 0;
      final recuperoRes = (deficitRes / 2).ceil();
      tempResilienza += recuperoRes;
      rimarginaHpDaAumentoResilienza(recuperoRes);

      if (tempOculum < 0) {
        tempOculum = 0;
      }

      final random = Random.secure();
      for (var i = 0; i < ascensionDustPermanentiInAttesa; i++) {
        switch (random.nextInt(4)) {
          case 0:
            resilienzaController.text = (leggiNumero(resilienzaController) + 1)
                .toString();
            potenziamentiPermanentiRivelati.add('Resilienza');
            break;
          case 1:
            volontaController.text = (leggiNumero(volontaController) + 1)
                .toString();
            potenziamentiPermanentiRivelati.add(t('Volontà', 'Will'));
            break;
          case 2:
            materiaController.text = (leggiNumero(materiaController) + 1)
                .toString();
            potenziamentiPermanentiRivelati.add('Materia');
            break;
          default:
            oculumController.text = (leggiNumero(oculumController) + 1)
                .toString();
            potenziamentiPermanentiRivelati.add('Oculum');
        }
      }
      ascensionDustTempResilienza = 0;
      ascensionDustTempVolonta = 0;
      ascensionDustTempMateria = 0;
      ascensionDustTempOculum = 0;
      ascensionDustSottotrattiTemporanei.clear();
      invalidateHiddenEyeDerivedCaches();
      ascensionDustUsataOggi = 0;
      ascensionDustPermanentiInAttesa = 0;

      refullaStatsAttuali();
      ricaricaScudoOculum();

      raccoltaResilienzaSpesa = 0;
      raccoltaVolontaSpesa = 0;
      raccoltaMateriaSpesa = 0;
      raccoltaOculumSpesa = 0;
      presaMaterialiBonusTemporaneoGrammi = 0;
      presaMaterialiGrammi = presaMaterialiMassimoBaseGrammi();

      sessioniSenzaBisogniController.text = '0';

      currentHpController.text = oculumLongRestHpTarget(
        currentHp: hpCorrenti(),
        maxHp: maxHp(),
      ).toString();
      malusTiriOculumPostEsplosione = 0;
      aggiustaNucleoUsato = false;
      scannerRiposiLunghi = min(3, scannerRiposiLunghi + 1);

      for (var i = 0; i < arti.length; i++) {
        final art = arti[i];
        if (!art.sbloccata) continue;
        ensureArtIntegrityValue(i);
        final maximum = artIntegrityMaximum();
        final limitedRecovery = art.esaurimentoCompleto;
        final recovered = oculumArtRecoveredValue(
          current: art.integritaCorrente,
          maximum: maximum,
          limitedAfterFullExhaustion: limitedRecovery,
        );
        var artChanged = false;
        if (recovered != art.integritaCorrente) {
          art.integritaCorrente = recovered;
          artChanged = true;
        }
        if (limitedRecovery) {
          art.esaurimentoCompleto = false;
          limitedArtRecoveries++;
          artChanged = true;
        }
        if (artChanged) changedArtIndexes.add(i);
      }

      ultimoEventoRiposo = t(
        'Riposo lungo completato: dura 1 ora e mezza. Recupera metà Resilienza negativa, tutto Oculum negativo, tutte le stats attuali, 50% di Cenere minimo 3 e porta gli HP ad almeno il 75% del massimale.',
        'Long rest completed: it lasts 1.5 hours. It recovers half negative Resilience, all negative Oculum, all current stats, 50% Ash minimum 3 and brings HP to at least 75% of maximum.',
      );
      ultimoEventoRiposo += t(
        '\nPresa materiali ricaricata al massimo: ${formatoPesoMateriali(presaMaterialiGrammi)}; bonus temporanei rimossi.',
        '\nMaterial capacity refilled: ${formatoPesoMateriali(presaMaterialiGrammi)}; temporary bonuses removed.',
      );
      if (potenziamentiPermanentiRivelati.isNotEmpty) {
        ultimoEventoRiposo += t(
          '\nAscension Dust rivelata: +1 permanente a ${potenziamentiPermanentiRivelati.join(', ')}.',
          '\nAscension Dust revealed: permanent +1 to ${potenziamentiPermanentiRivelati.join(', ')}.',
        );
      }
      if (rimuoveMalusEsplosione) {
        ultimoEventoRiposo += t(
          '\nMalus Esplosione di Oculum rimosso.',
          '\nOculum Burst penalty removed.',
        );
      }
      if (limitedArtRecoveries > 0) {
        ultimoEventoRiposo += t(
          '\n$limitedArtRecoveries Art completamente esaurite hanno recuperato solo il 10%; dai prossimi riposi torneranno al recupero normale.',
          '\n$limitedArtRecoveries fully exhausted Arts recovered only 10%; normal recovery resumes from the next rests.',
        );
      }
      if (aggiustaNucleoEraUsato) {
        ultimoEventoRiposo += t(
          '\nAggiusta nucleo è di nuovo disponibile: scegli un’Art per usarlo.',
          '\nRepair core is available again: choose an Art to use it.',
        );
      }

      risultato = ultimoEventoRiposo;
      aggiungiLog(risultato);
    });

    for (final index in changedArtIndexes) {
      notifyArtIntegrityChanged(index);
    }
    notifyAggiustaNucleoDisponibilitaChanged();

    Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      longRestInProgress = false;
    });

    if (changedArtIndexes.isNotEmpty) {
      scheduleArtIntegritySave(changedArtIndexes, immediate: true);
    }
    recordAggiustaNucleoProgress(immediate: true);
    programmaSalvataggio();
  }

  void attivitaRaccoltaPescaCaccia() {
    setState(() {
      setCurrentStatFromVisibleInput(
        'volonta',
        max(0, volontaTotale() - 1).toString(),
        trackConsumption: false,
      );
      raccoltaVolontaSpesa += 1;

      final svenimento = modificaCenereControllata(1);

      ultimoEventoRiposo = t(
        'Raccolta / Pesca / Caccia: -1 Volontà attuale e +1 Cenere.',
        'Gathering / Fishing / Hunting: -1 current Will and +1 Ash.',
      );

      if (svenimento != null) ultimoEventoRiposo += '\n$svenimento';
      risultato = ultimoEventoRiposo;
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void forgiaturaConMateria() {
    setState(() {
      setCurrentStatFromVisibleInput(
        'materia',
        max(0, materiaTotale() - 1).toString(),
        trackConsumption: false,
      );
      raccoltaMateriaSpesa += 1;

      final svenimento = modificaCenereControllata(1);

      ultimoEventoRiposo = t(
        'Forgiatura: -1 Materia attuale usata per la creazione e +1 Cenere.',
        'Forging: -1 current Materia used for crafting and +1 Ash.',
      );

      if (svenimento != null) ultimoEventoRiposo += '\n$svenimento';
      risultato = ultimoEventoRiposo;
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void forgiaturaConOculum() {
    setState(() {
      setCurrentStatFromVisibleInput(
        'oculum',
        max(0, oculumTotale() - 1).toString(),
        trackConsumption: false,
      );
      raccoltaOculumSpesa += 1;

      final svenimento = modificaCenereControllata(1);

      ultimoEventoRiposo = t(
        'Forgiatura: -1 Oculum attuale usato come alternativa alla Materia e +1 Cenere.',
        'Forging: -1 current Oculum used as an alternative to Materia and +1 Ash.',
      );

      if (svenimento != null) ultimoEventoRiposo += '\n$svenimento';
      risultato = ultimoEventoRiposo;
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void resetBuffDebuffTemporanei() {
    setState(() {
      tempResilienza = 0;
      tempVolonta = 0;
      tempMateria = 0;
      tempOculum = 0;

      raccoltaResilienzaSpesa = 0;
      raccoltaVolontaSpesa = 0;
      raccoltaMateriaSpesa = 0;
      raccoltaOculumSpesa = 0;
      presaMaterialiBonusTemporaneoGrammi = 0;
      presaMaterialiGrammi = presaMaterialiMassimoBaseGrammi();

      sessioniSenzaBisogniController.text = '0';
      giorniSenzaCiboAcquaController.text = '0';

      ultimoEventoRiposo = t(
        'Buff e debuff temporanei resettati. La Cenere non è stata azzerata.',
        'Temporary buffs and debuffs reset. Ash was not cleared.',
      );

      risultato = ultimoEventoRiposo;
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  // =====================================================
  // TITOLI DEL FATO / ARTI
  // =====================================================

  bool titoloEsistePerChiave(String chiave) {
    return titoli.any((titolo) => titolo.chiaveSistema == chiave);
  }

  bool creaTitoloApprendimentoAutomatico({
    required String chiaveSistema,
    required String skillName,
    required String formName,
  }) {
    if (titoloEsistePerChiave(chiaveSistema)) return false;
    final safeSkill = skillName.trim().isEmpty
        ? t('Skill senza nome', 'Unnamed Skill')
        : skillName.trim();
    final safeForm = formName.trim().isEmpty
        ? t('forma successiva', 'next form')
        : formName.trim();
    titoli.add(
      OculumTitle(
        nome: t('Apprendimento di $safeSkill', 'Learning of $safeSkill'),
        tipo: t('Titolo d’Apprendimento', 'Learning Title'),
        ottenimento: t(
          'Ottenuto raggiungendo il massimo Oculum richiesto per $safeForm.',
          'Earned by reaching the Oculum maximum required for $safeForm.',
        ),
        leggenda: t(
          'La padronanza della Skill ha lasciato un segno permanente e modificabile.',
          'Mastering the Skill left a permanent, editable mark.',
        ),
        buff: '',
        puntoCieco: '',
        skill: safeSkill,
        richiede: t(
          'Può essere modificato liberamente dalla sezione Titoli.',
          'It can be freely edited in the Titles section.',
        ),
        chiaveSistema: chiaveSistema,
      ),
    );
    return true;
  }

  String rimuoviBuffFatoPredefiniti(String text) {
    var clean = text;
    for (final tag in const [
      '@VC+5',
      '@Danni+5',
      '@Damage+5',
      '@VC+10',
      '@Difesa+10',
      '@Defense+10',
      '@VC+15',
      '@Danni+15',
      '@Damage+15',
      '@Difesa+15',
      '@Defense+15',
    ]) {
      clean = clean.replaceAll(tag, '');
    }
    return clean.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }

  void assicuraTagTitoloDelFato(String chiaveSistema, String quickTags) {
    for (final titolo in titoli) {
      if (titolo.chiaveSistema != chiaveSistema) continue;
      if (quickTags.trim().isEmpty) {
        titolo.buff = rimuoviBuffFatoPredefiniti(titolo.buff);
        return;
      }
      if (titolo.buff.contains('@')) return;
      titolo.buff = '${titolo.buff} $quickTags'.trim();
      return;
    }
  }

  void creaTitoloDelFatoAutomatico({
    required String chiaveSistema,
    required String nome,
    required String ottenimento,
    required String buff,
    required String skill,
  }) {
    if (titoloEsistePerChiave(chiaveSistema)) return;

    titoli.add(
      OculumTitle(
        nome: nome,
        tipo: 'Titolo del Fato',
        ottenimento: ottenimento,
        buff: rimuoviBuffFatoPredefiniti(buff),
        puntoCieco: t(
          'Il Fato pretende coerenza: se il personaggio tradisce il significato profondo del Titolo, il Master può trasformarne il dono in una condanna narrativa.',
          'Fate demands coherence: if the character betrays the deep meaning of the Title, the Master may turn its gift into a narrative curse.',
        ),
        skill: skill,
        richiede: t(
          'Evolve tramite azioni coerenti con l’Art, scelte importanti, sacrifici, rivelazioni o momenti in cui l’Oculum reagisce alla storia.',
          'Evolves through actions coherent with the Art, important choices, sacrifices, revelations or moments where the Oculum reacts to the story.',
        ),
        karma: 1,
        evoluto: false,
        chiaveSistema: chiaveSistema,
      ),
    );
  }

  void controllaTitoliDelFatoAutomatici({
    bool silenzioso = false,
    bool salva = true,
  }) {
    if (arti.isEmpty || arti.first.skills.length < 3) {
      if (!silenzioso) {
        setState(() {
          risultato = t(
            'Non ci sono abbastanza Skill nella prima Art per controllare i Titoli del Fato.',
            'There are not enough Skills in the first Art to check Fate Titles.',
          );

          aggiungiLog(risultato);
        });

        if (salva) programmaSalvataggio();
      }

      return;
    }

    int creati = 0;

    void runCheck() {
      final primaArt = arti.first;
      final primaSkill = primaArt.skills[0];
      final secondaSkill = primaArt.skills[1];
      final terzaSkill = primaArt.skills[2];

      if (primaSkill.livello >= 1 &&
          !titoloEsistePerChiave('fate_title_1_first_art_skill_1_lvl_1')) {
        creaTitoloDelFatoAutomatico(
          chiaveSistema: 'fate_title_1_first_art_skill_1_lvl_1',
          nome: t('Primo Titolo del Fato', 'First Fate Title'),
          ottenimento: t(
            'Ottenuto quando la prima Skill della prima Art raggiunge il livello 1. Non dipende dal livello del personaggio.',
            'Gained when the first Skill of the first Art reaches level 1. It does not depend on the character level.',
          ),
          buff: t(
            'Il Fato ha iniziato a osservarti. Questo Titolo rappresenta la prima vera risposta dell’Oculum alla tua identità.',
            'Fate has begun to watch you. This Title represents the first true answer of the Oculum to your identity.',
          ),
          skill: t(
            'Collegato alla prima Skill della prima Art: ${primaSkill.nome}.',
            'Linked to the first Skill of the first Art: ${primaSkill.nome}.',
          ),
        );

        creati++;
      }

      if (secondaSkill.livello >= 2 &&
          !titoloEsistePerChiave('fate_title_2_first_art_skill_2_lvl_2')) {
        creaTitoloDelFatoAutomatico(
          chiaveSistema: 'fate_title_2_first_art_skill_2_lvl_2',
          nome: t('Secondo Titolo del Fato', 'Second Fate Title'),
          ottenimento: t(
            'Ottenuto quando la seconda Skill della prima Art raggiunge il livello 2. Rappresenta una crescita più consapevole del potere.',
            'Gained when the second Skill of the first Art reaches level 2. It represents a more conscious growth of power.',
          ),
          buff: t(
            'Il Fato non ti guarda soltanto: ora ti riconosce. Questo Titolo lega il personaggio a una seconda forma della sua Art.',
            'Fate does not merely watch you: it now recognizes you. This Title binds the character to a second form of their Art.',
          ),
          skill: t(
            'Collegato alla seconda Skill della prima Art: ${secondaSkill.nome}.',
            'Linked to the second Skill of the first Art: ${secondaSkill.nome}.',
          ),
        );

        creati++;
      }

      if (terzaSkill.livello >= 3 &&
          !titoloEsistePerChiave('fate_title_3_first_art_skill_3_lvl_3')) {
        creaTitoloDelFatoAutomatico(
          chiaveSistema: 'fate_title_3_first_art_skill_3_lvl_3',
          nome: t('Terzo Titolo del Fato', 'Third Fate Title'),
          ottenimento: t(
            'Ottenuto quando la terza Skill della prima Art raggiunge il livello 3. È una soglia alta: il personaggio non sta solo usando l’Art, la sta incarnando.',
            'Gained when the third Skill of the first Art reaches level 3. This is a high threshold: the character is not only using the Art, they are embodying it.',
          ),
          buff: t(
            'Il Fato ha inciso un segno profondo. Questo Titolo rappresenta la terza dichiarazione della tua identità davanti all’Oculum.',
            'Fate has carved a deep mark. This Title represents the third declaration of your identity before the Oculum.',
          ),
          skill: t(
            'Collegato alla terza Skill della prima Art: ${terzaSkill.nome}.',
            'Linked to the third Skill of the first Art: ${terzaSkill.nome}.',
          ),
        );

        creati++;
      }

      assicuraTagTitoloDelFato('fate_title_1_first_art_skill_1_lvl_1', '');
      assicuraTagTitoloDelFato('fate_title_2_first_art_skill_2_lvl_2', '');
      assicuraTagTitoloDelFato('fate_title_3_first_art_skill_3_lvl_3', '');

      if (!silenzioso) {
        risultato = creati == 0
            ? t(
                'Controllo completato: nessun nuovo Titolo del Fato da creare.',
                'Check completed: no new Fate Title to create.',
              )
            : t(
                'Controllo completato: creati $creati Titoli del Fato.',
                'Check completed: created $creati Fate Titles.',
              );

        aggiungiLog(risultato);
      }
    }

    if (silenzioso) {
      runCheck();
    } else {
      setState(runCheck);
    }

    if (salva) programmaSalvataggio();
  }

  void creaPrimoTitoloDelFato() {
    final nome = primoTitoloFatoNomeController.text.trim().isEmpty
        ? 'Primo Titolo del Fato'
        : primoTitoloFatoNomeController.text.trim();

    final descrizione = primoTitoloFatoDescrizioneController.text.trim();

    final giaEsiste = titoli.any((titolo) => titolo.nome == nome);

    if (giaEsiste) {
      setState(() {
        risultato = t(
          'Questo Titolo del Fato esiste già.',
          'This Fate Title already exists.',
        );
      });

      return;
    }

    setState(() {
      titoli.add(
        OculumTitle(
          nome: nome,
          tipo: 'Titolo del Fato',
          ottenimento:
              'Fato 1 — ottenuto quando la prima Skill della prima Art raggiunge il livello 1. Non dipende dal livello del personaggio.',
          buff: descrizione.isEmpty
              ? 'Il Fato ha iniziato a osservarti perché la tua prima Skill della prima Art ha raggiunto il livello 1.'
              : descrizione,
          puntoCieco:
              'Il Fato pretende coerenza: tradire il significato del titolo può trasformarlo in condanna.',
          skill:
              'Collegato alla prima Skill della prima Art. Non è un premio di livello personaggio.',
          richiede:
              'Evolve tramite azioni coerenti con il destino del personaggio.',
          karma: 1,
          evoluto: false,
          chiaveSistema: 'fate_title_1_manual',
        ),
      );

      risultato = t(
        'Titolo del Fato creato: [$nome].',
        'Fate Title created: [$nome].',
      );

      aggiungiLog('Creato Titolo del Fato: [$nome].');
    });

    programmaSalvataggio();
  }

  void modificaLivelloSkillArt(ArtSkill skill, int delta) {
    setState(() {
      skill.livello = max(0, skill.livello + delta);

      risultato = t(
        'Livello Skill aggiornato: ${skill.nome} livello ${skill.livello}.',
        'Skill level updated: ${skill.nome} level ${skill.livello}.',
      );

      aggiungiLog(risultato);
    });

    controllaTitoliDelFatoAutomatici(silenzioso: true);
    programmaSalvataggio();
  }
  // =====================================================
  // DIARIO / SKILL / TITOLI / INVENTARIO
  // =====================================================

  void aggiungiPaginaDiario() {
    final numero = diarioPagine.length + 1;

    setState(() {
      final rewardLog = <String>[];
      ensureCampaignStarterRewards(rewardLog);
      diarioRewardClaimedCount = max(diarioRewardClaimedCount, numero);
      grantDiaryRewardsByCampaign(numero, rewardLog);
      final testoIniziale =
          'Pagina $numero - Scrivi qui memoria, sogni, colpe, legami, scoperte o ferite della sessione.';
      diarioPagine.add(testoIniziale);
      journalEntries.add(
        JournalEntry(
          title: 'Pagina Diario $numero',
          description: testoIniziale,
          cycleDay: 0,
          phase: '',
          location: '',
          legacyPageIndex: numero - 1,
        ),
      );

      risultato = t(
        'Nuova pagina diario aggiunta (${campaignDifficultyLabel()}). Ricompense: ${rewardLog.isEmpty ? "nessuna ora" : rewardLog.join(", ")}.',
        'New diary page added (${campaignDifficultyLabel()}). Rewards: ${rewardLog.isEmpty ? "none now" : rewardLog.join(", ")}.',
      );

      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void assicuraDatabaseDiariCompleto() {
    final indiciGiaCollegati = journalEntries
        .map((entry) => entry.legacyPageIndex)
        .whereType<int>()
        .toSet();
    for (int i = 0; i < diarioPagine.length; i++) {
      if (indiciGiaCollegati.contains(i)) continue;
      journalEntries.add(
        JournalEntry(
          title: 'Pagina Diario ${i + 1}',
          description: diarioPagine[i],
          cycleDay: 0,
          phase: '',
          location: '',
          legacyPageIndex: i,
        ),
      );
    }
  }

  void aggiungiVoceDatabaseDiario() {
    setState(() {
      journalEntries.add(
        JournalEntry(
          title: t('Nuova voce diario', 'New diary entry'),
          description: '',
          cycleDay: 0,
          phase: '',
          location: '',
        ),
      );
    });
    programmaSalvataggio();
  }

  void eliminaPaginaDiario(int index) {
    if (index < 0 || index >= diarioPagine.length) return;

    setState(() {
      risultato = t(
        'Le pagine diario non vengono eliminate: restano memoria permanente della scheda.',
        'Diary pages are not deleted: they remain permanent sheet memory.',
      );
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  OculumTitle titoloDaCampiCorrenti({
    required String nome,
    required String fallbackTipo,
  }) {
    final tipo = titoloTipoController.text.trim();
    return OculumTitle(
      nome: nome,
      tipo: tipo.isEmpty ? fallbackTipo : tipo,
      ottenimento: titoloOttenimentoController.text.trim(),
      leggenda: titoloLeggendaController.text.trim(),
      buff: titoloBuffController.text.trim(),
      puntoCieco: titoloPuntoCiecoController.text.trim(),
      skill: titoloSkillController.text.trim(),
      richiede: titoloRichiedeController.text.trim(),
      resilienza: leggiNumero(titoloResController),
      volonta: leggiNumero(titoloVolController),
      materia: leggiNumero(titoloMatController),
      oculum: leggiNumero(titoloOcuController),
      karma: leggiKarmaTitolo(titoloKarmaController),
      evoluto: nuovoTitoloEvoluto,
      openName: titoloOpenNameController.text.trim(),
      openDescription: titoloOpenDescriptionController.text.trim(),
      openBuff: titoloOpenBuffController.text.trim(),
      openSkill: titoloOpenSkillController.text.trim(),
    );
  }

  bool tipoTitoloVaNeiTrattiRazziali([String? value]) {
    final normalized = oculumNormalizeText(cleanUiText(value ?? ''));
    if (normalized.isEmpty) return false;

    final words = normalized.split(' ').where((x) => x.isNotEmpty).toSet();
    return normalized.contains('tratto razziale') ||
        normalized.contains('tratti razziali') ||
        normalized.contains('racial trait') ||
        normalized.contains('racial traits') ||
        normalized.contains('sottorazza') ||
        normalized.contains('sottorazze') ||
        normalized.contains('subrace') ||
        normalized.contains('subraces') ||
        words.contains('razza') ||
        words.contains('razze') ||
        words.contains('race') ||
        words.contains('races');
  }

  void pulisciCampiTitolo() {
    titoloNomeController.clear();
    titoloOttenimentoController.clear();
    titoloLeggendaController.clear();
    titoloBuffController.clear();
    titoloPuntoCiecoController.clear();
    titoloSkillController.clear();
    titoloRichiedeController.text = '???';
    titoloResController.text = '0';
    titoloVolController.text = '0';
    titoloMatController.text = '0';
    titoloOcuController.text = '0';
    titoloKarmaController.text = '0';
    titoloOpenNameController.clear();
    titoloOpenDescriptionController.clear();
    titoloOpenBuffController.clear();
    titoloOpenSkillController.clear();
    nuovoTitoloEvoluto = false;
  }

  String assegnaEsperienzaOpenTitolo(OculumTitle titolo) {
    final openSbloccate = titolo.evoluto ? 1 + titolo.openExtra.length : 0;
    final target = oculumTitleOpenExperienceTarget(openSbloccate);
    final guadagno = max(0, target - titolo.openExperienceClaimed);
    titolo.openExperienceClaimed = max(titolo.openExperienceClaimed, target);
    if (guadagno == 0) return '';
    return applicaEsperienzaFlat(
      guadagno,
      motivo: t(
        'Evoluzione Open di ${titolo.nome}',
        'Open evolution of ${titolo.nome}',
      ),
    );
  }

  void creaTitolo() {
    final nome = titoloNomeController.text.trim();

    if (nome.isEmpty) return;

    if (tipoTitoloVaNeiTrattiRazziali(titoloTipoController.text)) {
      creaTrattoRazziale();
      return;
    }

    final nuovoTitolo = titoloDaCampiCorrenti(
      nome: nome,
      fallbackTipo: t('Titolo', 'Title'),
    );
    setState(() {
      titoli.add(nuovoTitolo);
      final expText = assegnaEsperienzaOpenTitolo(nuovoTitolo);

      pulisciCampiTitolo();

      risultato = '${t('Titolo creato.', 'Title created.')}$expText';
      aggiungiLog('Titolo creato: [$nome].$expText');
    });

    programmaSalvataggio();
  }

  void creaTrattoRazziale() {
    final nome = titoloNomeController.text.trim();
    if (nome.isEmpty) return;

    if (trattiRazziali.length >= 13) {
      setState(() {
        risultato = t(
          'Slot Tratti Razziali pieni: massimo 13 tra razze e sottorazze.',
          'Racial Trait slots full: max 13 between races and subraces.',
        );
      });
      return;
    }

    final nuovoTratto = titoloDaCampiCorrenti(
      nome: nome,
      fallbackTipo: t('Tratto Razziale / Sottorazza', 'Racial Trait / Subrace'),
    )..equipaggiato = true;
    setState(() {
      trattiRazziali.add(nuovoTratto);
      final expText = assegnaEsperienzaOpenTitolo(nuovoTratto);

      if (razzaController.text.trim().isEmpty) {
        razzaController.text = nome;
      }

      pulisciCampiTitolo();

      risultato =
          '${t('Tratto razziale creato.', 'Racial trait created.')}$expText';
      aggiungiLog('Tratto razziale creato: [$nome].$expText');
    });

    programmaSalvataggio();
  }

  void usaOpen(OculumTitle titolo, {TitleOpenEntry? openExtra}) {
    List<OculumStructuredEffect> effectsToActivate =
        const <OculumStructuredEffect>[];
    var effectSource = '';
    setState(() {
      if (!titolo.evoluto) return;

      if (openExtra != null) {
        if (openExtra.attiva) {
          if (titolo.equipaggiato) {
            rimarginaHpDaAumentoResilienza(
              -extraOpenRuntimeResilienzaBonus(openExtra),
            );
          }
          openExtra.attiva = false;
        } else {
          disattivaTutteLeOpen(exceptTitle: titolo, exceptOpenExtra: openExtra);
          equipaggiaTitoloPerOpen(titolo);
          openExtra.attiva = true;
          effectsToActivate = List<OculumStructuredEffect>.from(
            openExtra.effects,
          );
          effectSource = openExtra.nome.trim().isEmpty
              ? titolo.nome
              : openExtra.nome.trim();
          if (titolo.equipaggiato) {
            rimarginaHpDaAumentoResilienza(
              extraOpenRuntimeResilienzaBonus(openExtra),
            );
          }
        }

        risultato = openExtra.attiva
            ? '${t('Open attivata', 'Open activated')}: ${openExtra.nome.isEmpty ? titolo.nome : openExtra.nome}'
            : '${t('Open disattivata', 'Open deactivated')}: ${openExtra.nome.isEmpty ? titolo.nome : openExtra.nome}';

        aggiungiLog(risultato);
        return;
      }

      if (titolo.openAttiva) {
        if (titolo.equipaggiato) {
          rimarginaHpDaAumentoResilienza(
            -titleOpenRuntimeResilienzaBonus(titolo),
          );
        }
        titolo.openAttiva = false;
      } else {
        disattivaTutteLeOpen(exceptTitle: titolo);
        equipaggiaTitoloPerOpen(titolo);
        titolo.openAttiva = true;
        effectsToActivate = List<OculumStructuredEffect>.from(
          titolo.openEffects,
        );
        effectSource = titolo.openName.trim().isEmpty
            ? titolo.nome
            : titolo.openName.trim();
        if (titolo.equipaggiato) {
          rimarginaHpDaAumentoResilienza(
            titleOpenRuntimeResilienzaBonus(titolo),
          );
        }
      }

      risultato = titolo.openAttiva
          ? '${t('Open attivata', 'Open activated')}: ${titolo.openName.isEmpty ? titolo.nome : titolo.openName}'
          : '${t('Open disattivata', 'Open deactivated')}: ${titolo.openName.isEmpty ? titolo.nome : titolo.openName}';

      aggiungiLog(risultato);
    });

    if (effectsToActivate.isNotEmpty) {
      final messages = applyStructuredEffectsOnActivation(
        effectsToActivate,
        source: effectSource,
      );
      if (messages.isNotEmpty) {
        setState(() {
          risultato +=
              '\n${t('Effetti Open attivati', 'Activated Open effects')}:\n'
              '${messages.join('\n')}';
          aggiungiLog(
            '${t('Effetti Open attivati', 'Activated Open effects')} '
            '[$effectSource]: ${messages.join(' | ')}',
          );
        });
      }
    }
    scheduleRealtimeOculumChanged();
    programmaSalvataggio();
  }

  void aggiungiOpenExtra(OculumTitle titolo) {
    if (titolo.openExtra.length >= 12) {
      setState(() {
        risultato = t(
          'Questo titolo ha già 12 Open extra. Limite massimo raggiunto.',
          'This title already has 12 extra Opens. Maximum limit reached.',
        );
      });

      return;
    }

    setState(() {
      titolo.evoluto = true;

      titolo.openExtra.add(
        TitleOpenEntry(
          nome: '${t('Nuova Open', 'New Open')} ${titolo.openExtra.length + 1}',
        ),
      );

      final expText = assegnaEsperienzaOpenTitolo(titolo);

      risultato = t(
        'Nuova Open aggiunta al titolo: ${titolo.nome} (${titolo.openExtra.length}/12)$expText',
        'New Open added to title: ${titolo.nome} (${titolo.openExtra.length}/12)$expText',
      );

      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void aggiungiSkillExtraTitolo(OculumTitle titolo) {
    setState(() {
      titolo.evoluto = true;

      titolo.skillExtra.add(
        TitleExtraSkillEntry(
          nome: t('Nuova Skill del Titolo', 'New Title Skill'),
          descrizione: '',
        ),
      );

      risultato = t(
        'Nuova Skill aggiunta al titolo: ${titolo.nome}',
        'New Skill added to title: ${titolo.nome}',
      );

      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void creaItem() {
    final nome = itemNomeController.text.trim();

    if (nome.isEmpty) return;

    final peso = leggiDouble(itemPesoController);
    final quantita = leggiNumero(itemQuantitaController);

    setState(() {
      final item = InventoryItem(
        nome: nome,
        peso: peso,
        quantita: quantita <= 0 ? 1 : quantita,
        note: itemNoteController.text.trim(),
        buff: itemBuffController.text.trim(),
        arma: nuovoItemArma,
        protegge: nuovoItemProtegge,
        equipaggiata: nuovoItemEquipaggiato,
        bonusDanno: leggiNumero(itemBonusDannoController),
        bonusDifesa: leggiNumero(itemBonusDifesaController),
        bonusScudo: leggiNumero(itemBonusScudoController),
        gradoOggetto: leggiNumero(
          itemGradoOggettoController,
        ).clamp(0, 12).toInt(),
        gradoRichiesto: leggiNumero(
          itemGradoRichiestoController,
        ).clamp(0, 12).toInt(),
        elementoDanno: itemElementoDannoController.text.trim().isEmpty
            ? 'Fisico'
            : itemElementoDannoController.text.trim(),
        putrefazioneSessioni: max(
          0,
          leggiNumero(itemPutrefazioneSessioniController),
        ),
        putrefazioneGiornoInizio: oculumCurrentDay(),
      );
      if (item.equipaggiata && !canEquipInventoryItem(item)) {
        item.equipaggiata = false;
        risultato = t(
          'Oggetto creato ma non equipaggiato: richiede Grado ${requiredItemGrade(item)}.',
          'Item created but not equipped: requires Grade ${requiredItemGrade(item)}.',
        );
        aggiungiLog(risultato);
      }
      inventario.add(item);
      if (item.equipaggiata) applicaScudoItemAttuale(item, 1);

      itemNomeController.clear();
      itemPesoController.text = '0';
      itemQuantitaController.text = '1';
      itemPutrefazioneSessioniController.text = '0';
      itemNoteController.clear();
      itemBuffController.clear();
      itemBonusDannoController.text = '0';
      itemBonusDifesaController.text = '0';
      itemBonusScudoController.text = '0';
      itemGradoOggettoController.text = '0';
      itemGradoRichiestoController.text = '0';
      itemElementoDannoController.text = 'Fisico';

      nuovoItemArma = false;
      nuovoItemProtegge = false;
      nuovoItemEquipaggiato = false;

      risultato = t('Oggetto aggiunto: $nome.', 'Item added: $nome.');
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  String nomeItemPutrefatto(InventoryItem item) {
    final nome = item.nome.trim().toLowerCase();
    if (nome.contains('slime')) return 'Slime putrefatto';
    if (nome.contains('carne') ||
        nome.contains('meat') ||
        nome.contains('cibo') ||
        nome.contains('food')) {
      return 'Carne marcia';
    }
    if (nome.contains('materiale') ||
        nome.contains('material') ||
        nome.contains('metallo') ||
        nome.contains('metal') ||
        nome.contains('pietra') ||
        nome.contains('stone') ||
        nome.contains('legno') ||
        nome.contains('wood') ||
        nome.contains('stoffa') ||
        nome.contains('osso') ||
        nome.contains('bone') ||
        nome.contains('cristallo') ||
        nome.contains('runico') ||
        nome.contains('postea')) {
      return 'Materiale putrefatto';
    }
    return 'Oggetto putrefatto';
  }

  bool itemGiaPutrefatto(InventoryItem item) {
    final nome = item.nome.trim().toLowerCase();
    return nome == 'oggetto putrefatto' ||
        nome == 'slime putrefatto' ||
        nome == 'carne marcia' ||
        nome == 'materiale putrefatto';
  }

  void trasformaItemInPutrefatto(InventoryItem item) {
    final nomeOriginale = item.nome.trim().isEmpty
        ? 'Oggetto'
        : item.nome.trim();
    if (item.equipaggiata) applicaScudoItemAttuale(item, -1);
    final nomePutrefatto = nomeItemPutrefatto(item);
    item.nome = nomePutrefatto;
    item.arma = false;
    item.protegge = false;
    item.equipaggiata = false;
    item.bonusDanno = 0;
    item.bonusDifesa = 0;
    item.bonusScudo = 0;
    item.buff = '';
    item.elementoDanno = nomePutrefatto == 'Slime putrefatto'
        ? 'Acido'
        : 'Putrefatto';
    item.putrefazioneSessioni = 0;
    item.sessioniSegnate = 0;
    item.putrefazioneGiornoInizio = 0;
    final nota = t(
      'Putrefatto da $nomeOriginale.',
      'Rotted from $nomeOriginale.',
    );
    item.note = item.note.trim().isEmpty ? nota : '${item.note.trim()}\n$nota';
  }

  void unisciItemPutrefatti() {
    final visti = <String, InventoryItem>{};
    final daRimuovere = <InventoryItem>[];

    for (final item in inventario) {
      if (!itemGiaPutrefatto(item)) continue;
      final key = item.nome.trim().toLowerCase();
      final esistente = visti[key];
      if (esistente == null) {
        visti[key] = item;
        continue;
      }

      final quantitaEsistente = max(1, esistente.quantita);
      final quantitaAggiunta = max(1, item.quantita);
      final totale = quantitaEsistente + quantitaAggiunta;
      esistente.peso =
          ((esistente.peso * quantitaEsistente) +
              (item.peso * quantitaAggiunta)) /
          totale;
      esistente.quantita = totale;
      final nota = item.note.trim();
      if (nota.isNotEmpty && !esistente.note.contains(nota)) {
        esistente.note = esistente.note.trim().isEmpty
            ? nota
            : '${esistente.note.trim()}\n$nota';
      }
      daRimuovere.add(item);
    }

    if (daRimuovere.isEmpty) return;
    inventario.removeWhere(
      (item) => daRimuovere.any((rimosso) => identical(rimosso, item)),
    );
  }

  List<String> aggiornaPutrefazioneInventarioPerGiorno(int currentDay) {
    final marciti = <String>[];
    final day = normalizzaGiornoOculum(currentDay);

    for (final item in inventario) {
      if (item.putrefazioneSessioni <= 0 || itemGiaPutrefatto(item)) continue;

      if (item.putrefazioneGiornoInizio <= 0) {
        final giorniGiaSegnati = max(0, item.sessioniSegnate);
        item.putrefazioneGiornoInizio = giorniGiaSegnati == 0
            ? day
            : normalizzaGiornoOculum(day - giorniGiaSegnati);
      }

      final trascorsi = oculumDayDistance(item.putrefazioneGiornoInizio, day);
      item.sessioniSegnate = min(item.putrefazioneSessioni, trascorsi);

      if (trascorsi >= item.putrefazioneSessioni) {
        final nome = item.nome.trim().isEmpty ? 'Oggetto' : item.nome.trim();
        trasformaItemInPutrefatto(item);
        marciti.add('$nome -> ${item.nome}');
      }
    }

    if (marciti.isNotEmpty) unisciItemPutrefatti();
    return marciti;
  }

  void segnaSessioneInventario() {
    if (inventario.isEmpty) return;

    setState(() {
      final nuovoGiorno = normalizzaGiornoOculum(oculumCurrentDay() + 1);
      oculumCurrentDayController.text = nuovoGiorno.toString();
      final marciti = aggiornaPutrefazioneInventarioPerGiorno(nuovoGiorno);
      final aggiornati = inventario
          .where(
            (item) => item.putrefazioneSessioni > 0 && !itemGiaPutrefatto(item),
          )
          .length;

      if (marciti.isNotEmpty) {
        risultato = t(
          'Giorno inventario segnato: ${marciti.join(', ')}.',
          'Inventory day marked: ${marciti.join(', ')}.',
        );
      } else if (aggiornati == 0) {
        risultato = t(
          'Giorno inventario segnato: nessun oggetto con putrefazione attiva.',
          'Inventory day marked: no item has active rot tracking.',
        );
      } else if (marciti.isEmpty) {
        risultato = t(
          'Giorno inventario segnato: $aggiornati oggetti deperibili controllati.',
          'Inventory day marked: $aggiornati perishable items checked.',
        );
      }
      ultimoEventoRiposo = risultato;
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void creaSkill() {
    final nome = skillNomeController.text.trim();

    if (nome.isEmpty) return;

    setState(() {
      skills.add(
        CharacterSkill(
          nome: nome,
          tipo: skillTipoController.text.trim(),
          costo: skillCostoController.text.trim(),
          cooldown: skillCooldownController.text.trim(),
          descrizione: skillDescrizioneController.text.trim(),
          resilienza: leggiNumero(skillResController),
          volonta: leggiNumero(skillVolController),
          materia: leggiNumero(skillMatController),
          oculum: leggiNumero(skillOcuController),
          danni: leggiNumero(skillDanniController),
          difesa: leggiNumero(skillDifesaController),
        ),
      );

      skillNomeController.clear();
      skillTipoController.text = 'Cerchio Magico';
      skillCostoController.text = '0';
      skillCooldownController.text = 'Nessuno';
      skillDescrizioneController.clear();
      skillResController.text = '0';
      skillVolController.text = '0';
      skillMatController.text = '0';
      skillOcuController.text = '0';
      skillDanniController.text = '0';
      skillDifesaController.text = '0';

      risultato = t('Skill creata: $nome.', 'Skill created: $nome.');
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  // =====================================================
}
