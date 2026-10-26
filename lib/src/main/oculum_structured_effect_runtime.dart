part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _OculumStructuredEffectRuntime on _OculumHomePageState {
  bool activateHeroicNurseBuffForCurrentBattle() {
    final pending = heroicNursePendingBattleBuff;
    if (pending == null || !readBoolValue(pending['pending'])) return false;
    if (!currentCombatIsActive()) return false;
    final difficulty = normalizedCampaignDifficulty();
    final rawDurations = pending['difficultyDurations'];
    final durations = rawDurations is Map
        ? Map<String, dynamic>.from(rawDurations)
        : const <String, dynamic>{};
    final duration = max(
      1,
      readIntValue(
        durations[difficulty],
        fallback: oculumNurseBuffDuration(difficulty),
      ),
    );
    final damagePercent = readIntValue(
      pending['damagePercent'],
    ).clamp(0, 100).toInt();
    final defensePercent = readIntValue(
      pending['defensePercent'],
    ).clamp(0, 100).toInt();
    final source = 'Infermiera Eroica · Refull';
    activeStructuredEffects.removeWhere(
      (effect) => '${effect['source'] ?? ''}' == source,
    );
    for (final entry in <({String type, String target, int value})>[
      (
        type: 'danno_percentuale',
        target: 'danni_percentuale',
        value: damagePercent,
      ),
      (
        type: 'difesa_percentuale',
        target: 'difesa_percentuale',
        value: defensePercent,
      ),
    ]) {
      if (entry.value <= 0) continue;
      activeStructuredEffects.add(<String, dynamic>{
        'id':
            'heroic_nurse_${entry.target}_${DateTime.now().microsecondsSinceEpoch}',
        'type': entry.type,
        'target': entry.target,
        'value': entry.value,
        'remaining': duration,
        'unit': 'turni',
        'source': source,
        'mode': 'temporaneo',
      });
    }
    heroicNursePendingBattleBuff = null;
    invalidateDerivedDataCaches(notifyHiddenEyeCards: false);
    aggiungiLog(
      '[INFERMIERA EROICA] Refull attivato per la prossima battaglia: +$damagePercent% Danni e +$defensePercent% Difesa per $duration turni (${campaignDifficultyLabel()}).',
    );
    programmaSalvataggio(invalidateCaches: false);
    if (mounted) unawaited(sendRealtimeActiveSheetToStaff());
    return true;
  }

  bool removeActiveStructuredEffectsForSourcePrefix(String rawPrefix) {
    final prefix = rawPrefix.trim();
    if (prefix.isEmpty) return false;
    final hpBeforeBuffRemoval = hpCorrenti();
    final before = activeStructuredEffects.length;
    activeStructuredEffects.removeWhere((effect) {
      final source = '${effect['source'] ?? ''}'.trim();
      final belongsToSource = source == prefix || source.startsWith('$prefix ');
      // Un effetto accumulabile e' l'unico che puo' sopravvivere allo
      // spegnimento della Skill: tutti gli altri bonus vengono rimossi.
      return belongsToSource && !readBoolValue(effect['stackable']);
    });
    if (activeStructuredEffects.length == before) return false;

    if (!activeStructuredEffects.any(
      (effect) =>
          '${effect['type'] ?? ''}' == 'stato' &&
          '${effect['target'] ?? ''}' == 'sotto_stress',
    )) {
      sottoStress = sottoStressManuale;
      if (!sottoStress) stressStatConsumptionProgress.clear();
    }
    invalidateDerivedDataCaches(notifyHiddenEyeCards: false);
    preserveLivingHpAfterBuffRemoval(hpBeforeBuffRemoval);
    scheduleHiddenEyeDerivedCardsRefresh();
    return true;
  }

  void preserveLivingHpAfterBuffRemoval(int hpBefore) {
    if (hpBefore <= 0) return;
    currentHpController.text = max(
      1,
      min(leggiNumero(currentHpController), maxHp()),
    ).toString();
  }

  String normalizedStructuredTarget(String raw) {
    final key = oculumDynamicFormulaKey(raw);
    return switch (key) {
      'res' || 'resilienza' => 'resilienza',
      'vol' || 'volonta' => 'volonta',
      'mat' || 'materia' => 'materia',
      'ocu' || 'oculum' => 'oculum',
      'danno' || 'danni' => 'danni',
      'dif' || 'difesa' => 'difesa',
      'velocita' || 'movimento' => 'movimento',
      'reazione' || 'reazioni' => 'reazione',
      'reazione_veloce' ||
      'reazioni_veloci' ||
      'reazioni_rapide' => 'reazione_veloce',
      _ => key,
    };
  }

  int activeStructuredEffectBonus(String target) {
    final normalized = normalizedStructuredTarget(target);
    var total = 0;
    for (final effect in activeStructuredEffects) {
      if (readIntValue(effect['remaining']) == 0) continue;
      if (oculumStructuredEffectFrequency(effect['frequency']) > 0 &&
          !readBoolValue(effect['periodicActive'])) {
        continue;
      }
      if (normalizedStructuredTarget('${effect['target'] ?? ''}') !=
          normalized) {
        continue;
      }
      total += wingAdjustedFlightBonus(
        readIntValue(effect['value']),
        '${effect['source']} ${effect['effectId']}',
      );
    }
    for (final effect in automaticMonsterPassiveEffects()) {
      if (!const {
        'danno',
        'danno_percentuale',
        'difesa',
        'difesa_percentuale',
        'modifica_statistica',
        'modifica_sottotratto',
        'velocita',
      }.contains(effect.type)) {
        continue;
      }
      if (normalizedStructuredTarget(oculumStructuredEffectTargetKey(effect)) !=
          normalized) {
        continue;
      }
      total += wingAdjustedFlightBonus(
        oculumEvaluateStructuredEffectValue(
          effect,
          variables: {
            'resilienza': currentResilienza(),
            'volonta': currentVolonta(),
            'materia': currentMateria(),
            'oculum': currentOculum(),
            'livello': leggiNumero(livelloController),
            'grado': leggiNumero(gradoController),
          },
          subtraits: hiddenEyeStats,
        ),
        effect.id,
      );
    }
    return total;
  }

  void applyStructuredHealing(String resource, int amount) {
    if (amount == 0) return;
    if (oculumNormalizeEffectResource(resource) == 'oculum') {
      if (amount > 0) {
        addOculum(amount, scheduleSave: false);
      } else {
        spendOculum(-amount, scheduleSave: false);
      }
      recordCurrentOculumProgress();
      return;
    }
    final effectiveAmount = amount > 0
        ? applyConditionHealingAmount(amount)
        : amount;
    currentHpController.text = (hpCorrenti() + effectiveAmount)
        .clamp(0, maxHp())
        .toString();
  }

  bool tickActiveStructuredEffects(String unit) {
    final hpBeforeBuffRemoval = hpCorrenti();
    final normalizedUnit = oculumTurnUnit(unit);
    var changed = false;
    final hadTimedStressEffect = activeStructuredEffects.any(
      (effect) =>
          '${effect['type'] ?? ''}' == 'stato' &&
          '${effect['target'] ?? ''}' == 'sotto_stress',
    );
    for (final effect in activeStructuredEffects) {
      if (effect['mode'] == 'prossima_azione') continue;
      if (oculumTurnUnit('${effect['unit'] ?? ''}') != normalizedUnit) {
        continue;
      }
      final remaining = readIntValue(effect['remaining']);
      if (remaining == 0) continue;
      final frequency = oculumStructuredEffectFrequency(effect['frequency']);
      final due = frequency <= 0
          ? true
          : oculumAdvanceStructuredEffectFrequency(effect, unit);
      if (frequency > 0) changed = true;
      if (due) {
        final value = readIntValue(effect['value']);
        switch ('${effect['type'] ?? ''}') {
          case 'rimuovi_vita':
            final before = hpCorrenti();
            currentHpController.text = max(0, before - value.abs()).toString();
            checkAutomaticAshFromHpLoss(
              before,
              hpCorrenti(),
              source: '${effect['source'] ?? 'Effetto periodico'}',
            );
            aggiungiLog(
              '[DANNO PERIODICO] ${effect['source']}: -${before - hpCorrenti()} Vita, oltre Difesa e Scudi.',
            );
            sendRealtimeHpChanged();
            break;
          case 'cura':
            applyStructuredHealing('${effect['resource'] ?? 'vita'}', value);
            break;
          case 'scudo':
            scudoController.text = max(
              0,
              leggiNumero(scudoController) + value,
            ).toString();
            break;
          case 'hp_temporanei':
            hpTempController.text = (leggiNumero(hpTempController) + value)
                .clamp(0, oculumTemporaryHpLimit)
                .toString();
            break;
        }
      }
      if (remaining > 0) effect['remaining'] = max(0, remaining - 1);
      changed = true;
    }
    activeStructuredEffects.removeWhere(
      (effect) => readIntValue(effect['remaining']) == 0,
    );
    if (hadTimedStressEffect &&
        !activeStructuredEffects.any(
          (effect) =>
              '${effect['type'] ?? ''}' == 'stato' &&
              '${effect['target'] ?? ''}' == 'sotto_stress',
        )) {
      sottoStress = sottoStressManuale;
      if (!sottoStress) stressStatConsumptionProgress.clear();
    }
    if (changed) {
      invalidateDerivedDataCaches(notifyHiddenEyeCards: false);
      preserveLivingHpAfterBuffRemoval(hpBeforeBuffRemoval);
      if ((statoForzaAttivo == 'ricordo_vitale' ||
              statoForzaAttivo == 'duecento_percento') &&
          !activeStructuredEffects.any(
            (e) => '${e['source']}'.startsWith('Stato di Forza:'),
          )) {
        terminaStatoForzaAttivo(applicaEsitoEsplosione: false);
      }
      scheduleHiddenEyeDerivedCardsRefresh();
    }
    return changed;
  }

  List<String> applyStructuredEffectsOnActivation(
    Iterable<OculumStructuredEffect> effects, {
    required String source,
    int? level,
    int? grade,
    Map<String, num> spentResources = const <String, num>{},
    bool applyFusionBonus = true,
  }) {
    if (applyFusionBonus) effects = dustFusionArtEffects(effects);
    final messages = <String>[];
    final variables = formulaValueContext();
    final resolvedVariables = <String, num>{
      ...variables,
      'hp_max': maxHp(),
      'hp_current': hpCorrenti(),
    };
    final resolvedLevel = max(0, level ?? activeCriticalLevel());
    final resolvedGrade = max(0, grade ?? activeCriticalGrade());
    int? slimeBounces;

    for (final effect in effects.where((item) => item.enabled)) {
      try {
        var resolvedEffect = effect;
        if (effect.id.startsWith('rock_slime_bounce_') &&
            effect.diceExpression == '1d3') {
          if (slimeBounces == null) {
            slimeBounces = Random().nextInt(3) + 1;
            messages.add(
              'Rimbalzo: 1d3 = $slimeBounces; lo stesso tiro determina Reazioni e bonus danni.',
            );
          }
          resolvedEffect = OculumStructuredEffect.fromJson(effect.toJson())
            ..diceExpression = ''
            ..diceDestination = 'valore'
            ..valueExpression = '(${effect.valueExpression})*$slimeBounces';
        }
        final isAreaDamage =
            effect.type == 'danno' &&
            effect.maximumTargets > 1 &&
            effect.maximumTargets >= effect.minimumTargets;
        final areaDamageParts = isAreaDamage
            ? oculumSplitAreaDamageExpression(effect.valueExpression)
            : (base: effect.valueExpression, perTargetBonus: '');
        final effectForRoll = isAreaDamage
            ? OculumStructuredEffect.fromJson(resolvedEffect.toJson())
            : resolvedEffect;
        if (isAreaDamage) {
          effectForRoll.valueExpression = areaDamageParts.base;
        }
        final effectVariables = isAreaDamage
            ? <String, num>{
                ...resolvedVariables,
                'danni': max(0, dannoTotaleBaseSenzaComandi()),
                if (effect.id.startsWith('goblin_kamikaze_explosion_'))
                  'hp': maxHp(),
              }
            : resolvedVariables;
        final roll = oculumResolveStructuredEffectRoll(
          effectForRoll,
          variables: effectVariables,
          subtraits: hiddenEyeStats,
          spentResources: spentResources,
          level: resolvedLevel,
          grade: resolvedGrade,
        );
        final negative =
            effect.mode == 'diminuzione' || effect.type.startsWith('rimuovi_');
        var value = negative ? -roll.value.abs() : roll.value;
        final duration = max(0, roll.baseDuration + roll.durationBonus);
        final effectTarget = oculumStructuredEffectTargetKey(effect);
        final target = effect.type == 'stato'
            ? (effect.appliedState.isEmpty
                  ? 'sotto_stress'
                  : effect.appliedState)
            : normalizedStructuredTarget(
                effectTarget.isNotEmpty ? effectTarget : effect.target,
              );
        if (totalPowerExhausted &&
            value > 0 &&
            const {'reazione', 'reazione_veloce'}.contains(target)) {
          messages.add(
            'Sfinimento: nessuna nuova Reazione ricevuta da $source.',
          );
          continue;
        }
        final corruptionOwnerTag =
            effect.resource.startsWith('corruption_mastery:')
            ? effect.resource.substring('corruption_mastery:'.length)
            : '';
        if (effect.type == 'stato' &&
            target == 'corruzione' &&
            effect.recipient == 'se_stesso') {
          final marker = effect.resource.split(':');
          final scrollGrade = marker.length > 1
              ? max(0, int.tryParse(marker[1]) ?? 0)
              : resolvedGrade;
          var chance = marker.first == 'corruption_scroll'
              ? oculumCorruptionScrollChance(
                  scrollGrade: scrollGrade,
                  targetGrade: activeCriticalGrade(),
                )
              : 100;
          final resistance = currentCorruptionResistancePercent();
          if (resistance > 0) {
            chance = oculumCorruptionChanceAfterResistance(
              chancePercent: chance,
              resistancePercent: resistance,
            );
          }
          final corruptionRoll = Random.secure().nextInt(100) + 1;
          if (corruptionRoll > chance) {
            messages.add(
              'Corruzione resistita: d100 $corruptionRoll > $chance%.',
            );
            continue;
          }
          value = 1;
          messages.add(
            'Corruzione: d100 $corruptionRoll ≤ $chance%${resistance > 0 ? ' dopo la resistenza totale $resistance%' : ''}.',
          );
        }
        final frequency = effect.mode == 'prossima_azione'
            ? 0
            : oculumStructuredEffectFrequency(effect.frequency);
        final isPeriodic = frequency > 0;
        final preparedAttackBonus =
            (effect.type == 'danno' ||
                effect.type == 'danno_percentuale' &&
                    effect.recipient == 'se_stesso') &&
            effect.mode == 'prossima_azione' &&
            !effect.bypassDefense &&
            !effect.bypassShields &&
            !effect.bypassResistance &&
            effect.shieldDamageBonusPercent == 0 &&
            !(isAreaDamage && effect.recipient == 'nemico');
        // Existing saved Arts, scrolls and relics already carry this authored
        // effect ID. Keep their customized damage/cost while enabling its bite rule.
        if (effect.type == 'danno' &&
            effect.id.split('/').last.startsWith('cycle_lunar_bite_forma_')) {
          planarState['cycleLunarBite'] = true;
        }
        final effectiveRecipient =
            combatSupportTargeting && effect.recipient == 'se_stesso'
            ? 'alleato'
            : effect.recipient;
        if (effectiveRecipient != 'se_stesso' && !preparedAttackBonus) {
          // Freeze caster formulas and dice now; retries and the defender must
          // never roll the same payload again or evaluate it on enemy stats.
          final frozen = OculumStructuredEffect.fromJson(effect.toJson())
            ..recipient = effectiveRecipient
            ..valueExpression = '$value'
            ..duration = '$duration'
            ..diceExpression = ''
            ..includeLevel = false
            ..includeGrade = false;
          if (effect.target == 'cycle_fate_gift') {
            frozen.resource = sheetTagAt(schedaCorrente);
          }
          if (effect.id.startsWith('corrosive_acid_spit_') &&
              effect.duration == '3') {
            frozen.duration =
                '${oculumAcidSpitDuration(normalizedCampaignDifficulty())}';
          }
          if (!effect.stackable) {
            activeStructuredEffects.removeWhere(
              (e) =>
                  e['effectId'] == effect.id && e['type'] == 'pending_target',
            );
          }
          activeStructuredEffects.add({
            'effectId': effect.id,
            'source': source,
            'type': 'pending_target',
            'mode': 'prossima_azione',
            'target': effect.target,
            'value': 0,
            'remaining': 1,
            'unit': 'azioni',
            'minimumTargets': effect.minimumTargets,
            'maximumTargets': effect.maximumTargets,
            if (isAreaDamage && areaDamageParts.perTargetBonus.isNotEmpty)
              'damageBonusPerTarget': oculumEvaluateStructuredEffectValue(
                OculumStructuredEffect(
                  valueExpression: areaDamageParts.perTargetBonus,
                ),
                variables: <String, num>{
                  ...variables,
                  'danni': max(0, dannoTotaleBaseSenzaComandi()),
                },
                subtraits: hiddenEyeStats,
                spentResources: spentResources,
              ),
            'effect': frozen.toJson(),
          });
          messages.add(
            '${oculumStructuredEffectDescription(effect, subtraits: hiddenEyeStats)} = $value · ${effectiveRecipient == 'alleato' ? 'pronto per il destinatario del supporto, senza attacco' : 'pronto sul bersaglio del prossimo attacco, dopo la difesa'}.',
          );
          continue;
        }
        if (effect.type == 'danno' &&
            effect.id.startsWith('rock_slime_ball_') &&
            effect.mode != 'prossima_azione') {
          messages.add(
            'Palla di Roccia Slime: $value danni al bersaglio dopo un attacco riuscito. Difesa e Scudi si applicano normalmente.',
          );
          continue;
        }

        switch (effect.type) {
          case 'meccanio':
            activateMeccanioTechnique(effect, value);
            break;
          case 'esperienza_dust':
            for (final key in ['resilienza', 'volonta', 'materia', 'oculum']) {
              esperienzaCriticaStatistiche[key] =
                  max(0, esperienzaCriticaStatistiche[key] ?? 0) +
                  max(0, value);
            }
            final eligible = dustExperienceHighestSubtraits();
            if (eligible.isNotEmpty) {
              oculusSubtraitMasteryApplyGain(eligible.first, max(0, value));
            }
            applicaEsperienzaFlat(
              max(0, readIntValue(effect.resource)),
              motivo: 'Espansione Ascension Dust',
            );
            notifyActiveSheetSummaryChanged();
            break;
          case 'evocazione':
            if (normalizedStructuredTarget(effect.target) ==
                'patalpa_compagno') {
              final summonIndex = createPatalpaCompanionSheet(source: source);
              if (summonIndex < 0) {
                messages.add(
                  'Il Patalpa non può essere richiamato: è già presente nello scontro o manca la scheda evocatrice.',
                );
              } else {
                messages.add(
                  'Un Patalpa del livello dell’evocatore si unisce al fight.',
                );
              }
              continue;
            }
            if (normalizedStructuredTarget(effect.target) ==
                'un_vecchio_amore') {
              final summonIndex = createDeadKnightOldLoveSheet(source: source);
              if (summonIndex < 0) {
                messages.add(
                  'Un vecchio amore non può essere richiamato: abilità già usata nello scontro o scheda del Cavaliere Morto assente.',
                );
              } else {
                messages.add(
                  'Un vecchio amore si erge dal terreno: ${schedePersonaggio[summonIndex]['nome']}.',
                );
              }
              continue;
            }
            if (normalizedStructuredTarget(effect.target) != 'clone_ombra') {
              messages.add('Evocazione non riconosciuta: ${effect.target}.');
              continue;
            }
            if (value <= 0 || duration <= 0) {
              messages.add(
                'Clone d’ombra non creato: servono Vita e durata maggiori di zero.',
              );
              continue;
            }
            final cloneIndex = createShadowCloneSheet(
              hp: value,
              duration: duration,
              source: source,
            );
            if (cloneIndex < 0) {
              messages.add(
                'Clone d’ombra non creato: scheda proprietaria assente.',
              );
              continue;
            }
            messages.add(
              'Clone d’ombra creato: ${schedePersonaggio[cloneIndex]['nome']} · $value Vita · $duration ${effect.durationUnit}.',
            );
            break;
          case 'costrutto':
            if (value <= 0) {
              messages.add(
                'Costrutto non creato: Vita deve essere maggiore di zero.',
              );
              continue;
            }
            if (effect.target.trim().toLowerCase() == 'piranha minore') {
              final created = createPiranhaMinion(hp: value, source: source);
              messages.add(
                created
                    ? 'Un Piranha minore entra in turnistica: $value Vita, 1 Resilienza, nessuna evocazione propria.'
                    : 'Limite raggiunto: possono restare al massimo due Piranha minori del gruppo.',
              );
              continue;
            }
            if (!effect.stackable) {
              activeStructuredEffects.removeWhere(
                (active) =>
                    active['effectId'] == effect.id ||
                    effect.mode == 'nidiata' &&
                        active['type'] == 'costrutto' &&
                        active['mode'] == 'nidiata',
              );
            }
            activeStructuredEffects.add(<String, dynamic>{
              'effectId': effect.id,
              'source': source,
              'type': 'costrutto',
              'mode': effect.mode,
              'target': effect.target.isEmpty ? 'Costrutto' : effect.target,
              'value': 0,
              'hp': value,
              'maxHp': value,
              'remaining': duration > 0 ? duration : -1,
              'unit': effect.durationUnit,
              'stackable': effect.stackable,
            });
            break;
          case 'preparazione':
            prepareConcentratedSkill(effect, value, source);
            break;
          case 'planar':
            activatePlanarEffect(effect, value, duration, source);
            break;
          case 'cura':
            if (!isPeriodic && effect.mode != 'rigenerazione') {
              applyStructuredHealing(effect.resource, value);
            }
            break;
          case 'scudo':
            if (!isPeriodic) {
              scudoController.text = max(
                0,
                leggiNumero(scudoController) + value,
              ).toString();
            }
            break;
          case 'hp_temporanei':
            if (!isPeriodic) {
              hpTempController.text = (leggiNumero(hpTempController) + value)
                  .clamp(0, oculumTemporaryHpLimit)
                  .toString();
            }
            break;
          case 'rimuovi_vita':
            if (isPeriodic) break;
            final hpBeforeRemoval = hpCorrenti();
            currentHpController.text = max(0, hpCorrenti() + value).toString();
            checkAutomaticAshFromHpLoss(
              hpBeforeRemoval,
              hpCorrenti(),
              source: source,
            );
            break;
          case 'rimuovi_oculum':
            final spent = spendOculum(value.abs(), scheduleSave: false);
            adjustRecordedStatSpentFromDelta('oculum', -spent);
            recordCurrentOculumProgress();
            scheduleRealtimeOculumChanged();
            break;
          case 'consumo_risorsa':
            final amount = roll.value.abs();
            final resource = oculumNormalizeEffectResource(effect.resource);
            if (resource == 'vita') {
              final hpBeforeRemoval = hpCorrenti();
              currentHpController.text = max(
                0,
                hpBeforeRemoval - amount,
              ).toString();
              checkAutomaticAshFromHpLoss(
                hpBeforeRemoval,
                hpCorrenti(),
                source: source,
              );
            } else if (resource == 'oculum') {
              final spent = spendOculum(amount, scheduleSave: false);
              adjustRecordedStatSpentFromDelta('oculum', -spent);
              recordCurrentOculumProgress();
              scheduleRealtimeOculumChanged();
            } else if (<String>{
              'resilienza',
              'volonta',
              'materia',
            }.contains(resource)) {
              spendArtSkillCostResource(resource, amount);
            }
            break;
          case 'conversione_risorsa':
            final amount = roll.value.abs();
            final sourceResource = oculumNormalizeEffectResource(
              effect.resource,
            );
            final targetResource = normalizedStructuredTarget(effect.target);
            if (amount <= 0 ||
                sourceResource == targetResource ||
                !const <String>{
                  'resilienza',
                  'volonta',
                  'materia',
                  'oculum',
                }.contains(sourceResource) ||
                !const <String>{
                  'resilienza',
                  'volonta',
                  'materia',
                  'oculum',
                }.contains(targetResource)) {
              break;
            }
            final spent = sourceResource == 'oculum'
                ? spendOculum(amount, scheduleSave: false)
                : spendArtSkillCostResource(sourceResource, amount);
            if (spent <= 0) break;
            if (sourceResource == 'oculum') {
              adjustRecordedStatSpentFromDelta('oculum', -spent);
              recordCurrentOculumProgress();
              scheduleRealtimeOculumChanged();
            }
            if (targetResource == 'oculum') {
              addOculum(spent, scheduleSave: false);
              recordCurrentOculumProgress();
              scheduleRealtimeOculumChanged();
            } else {
              modificaStatAttuale(targetResource, spent, silent: true);
            }
            break;
          case 'stato':
            if (target == 'sotto_stress') {
              sottoStress = true;
            } else {
              final applied = applyCondition(
                target,
                stage: target == 'corrosione_acida' ? 1 : max(1, value.abs()),
                duration: duration > 0 ? duration : null,
                durationType: switch (oculumTurnUnit(effect.durationUnit)) {
                  'tiri' => OculumConditionDurationType.rolls,
                  'azioni' => OculumConditionDurationType.actions,
                  'riposi_brevi' => OculumConditionDurationType.shortRest,
                  'riposi_lunghi' => OculumConditionDurationType.longRest,
                  _ => OculumConditionDurationType.turns,
                },
                source: source,
                metadata: target == 'corrosione_acida'
                    ? {'acidDamage': value.abs(), 'element': 'acido'}
                    : target == 'corruzione'
                    ? {
                        if (corruptionOwnerTag.isNotEmpty)
                          'corruptedByTag': corruptionOwnerTag,
                        'targetControlChancePercent':
                            oculumCorruptionMasteryTargetControlPercent,
                      }
                    : effect.resource == 'oculum_upkeep'
                    ? {
                        'oculumUpkeep': max(
                          1,
                          readIntValue(spentResources['oculum'], fallback: 1),
                        ),
                      }
                    : null,
              );
              if (!applied) {
                messages.add(
                  '${t('Stato non applicato', 'Condition not applied')}: $target',
                );
                continue;
              }
            }
            break;
        }

        final isOngoingBonus = <String>{
          'danno',
          'danno_percentuale',
          'difesa',
          'modifica_statistica',
          'modifica_sottotratto',
          'velocita',
          'forza',
          'stato',
          'rimuovi_reazioni',
          'rimuovi_reazioni_rapide',
          'aggiungi_reazioni',
          'aggiungi_reazioni_rapide',
          'elemental_resistance',
        }.contains(effect.type);
        final isRegeneration =
            effect.type == 'cura' && effect.mode == 'rigenerazione';
        final effectiveDuration = effect.mode == 'prossima_azione'
            ? 0
            : <String>{
                    'rimuovi_reazioni',
                    'rimuovi_reazioni_rapide',
                    'aggiungi_reazioni',
                    'aggiungi_reazioni_rapide',
                  }.contains(effect.type) &&
                  duration <= 0
            ? 1
            : duration;
        if (!(effect.type == 'stato' && target != 'sotto_stress') &&
            (isOngoingBonus || isRegeneration || isPeriodic) &&
            (effectiveDuration > 0 || isPeriodic || isOngoingBonus)) {
          if (!effect.stackable) {
            activeStructuredEffects.removeWhere(
              (active) =>
                  '${active['effectId'] ?? ''}' == effect.id ||
                  ('${active['source'] ?? ''}' == source &&
                      normalizedStructuredTarget('${active['target'] ?? ''}') ==
                          target),
            );
          }
          activeStructuredEffects.add(<String, dynamic>{
            'effectId': effect.id,
            'source': source,
            'type': effect.type,
            'mode': effect.mode,
            'target': target,
            'resource': effect.resource,
            if (effect.type == 'elemental_resistance') ...<String, dynamic>{
              'element': oculumNormalizeElementId(effect.elementType),
              'preset': canonicalDamageModifierName(effect.customDisplayText),
            },
            'value': value,
            'stackable': effect.stackable,
            // -1 rappresenta una periodicità senza scadenza. I vecchi
            // salvataggi continuano a usare soltanto durate positive.
            'remaining': effectiveDuration > 0 ? effectiveDuration : -1,
            'unit': effect.durationUnit,
            if (isPeriodic) ...<String, dynamic>{
              'frequency': frequency,
              'frequencyElapsed': 0,
              'periodicActive': false,
            },
          });
        }

        final diceText = roll.dice.rolls.isEmpty
            ? ''
            : ' [${roll.dice.expression}: ${roll.dice.rolls.join(', ')}'
                  '${roll.dice.modifier == 0 ? '' : ' ${roll.dice.modifier > 0 ? '+' : ''}${roll.dice.modifier}'}]';
        final durationText = effectiveDuration > 0
            ? ' - ${t('durata', 'duration')} $effectiveDuration ${effect.durationUnit}'
            : '';
        messages.add(
          '${oculumStructuredEffectDescription(effect, subtraits: hiddenEyeStats)}'
          ' = $value$diceText$durationText',
        );
      } on FormatException catch (error) {
        messages.add(
          '${t('Effetto non applicato', 'Effect not applied')}: ${error.message}',
        );
      }
    }

    if (messages.isNotEmpty) {
      invalidateDerivedDataCaches(notifyHiddenEyeCards: false);
      scheduleHiddenEyeDerivedCardsRefresh();
      programmaSalvataggio(invalidateCaches: false);
    }
    return messages;
  }

  int createShadowCloneSheet({
    required int hp,
    required int duration,
    required String source,
    String? displayName,
    bool asSummon = false,
    bool copyResilience = false,
    int? summonExpMultiplier,
    List<CharacterSkill> summonSkills = const [],
    String summonDescription = '',
    String summonKind = '',
  }) {
    if (schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length) {
      return -1;
    }
    salvaSchedaCorrenteInMemoria();
    final owner = Map<String, dynamic>.from(schedePersonaggio[schedaCorrente]);
    final ownerTag = sheetTagAt(schedaCorrente);
    final level = max(0, readIntValue(owner['livello']));
    final grade = max(0, readIntValue(owner['grado']));
    final clone = statoVuotoPersonaggio(
      nome:
          displayName ??
          'Clone d’ombra di ${nomeSchedaPersonaggio(schedaCorrente)}',
      tipo: 'Evocazione',
      livello: level,
      grado: grade,
    );
    const copiedStats = <String>[
      'volonta',
      'currentVolonta',
      'materia',
      'currentMateria',
      'oculum',
      'currentOculum',
      'maxOculum',
      'normalCurrentOculum',
      'temporaryOculum',
      'temporaryOculumRollsRemaining',
      'fortuna',
      'difficoltaTiro',
      'campaignDifficulty',
      'attaccoRapido',
      'vcRapido',
      'cmRapido',
      'difesaRapida',
      'hiddenEyeStats',
      'primaryColor',
      'secondaryColor',
      'tertiaryColor',
      'eyeUtilityColor',
      'backgroundTopColor',
      'colorPreset',
      'spriteAssetPath',
      'immaginePersonaggioBase64',
    ];
    for (final key in copiedStats) {
      if (owner.containsKey(key)) {
        clone[key] = oculumCopyJsonTree(owner[key]);
      }
    }
    // Resilience is intentionally independent. The explicit HP value is
    // preserved exactly through the ordinary HP calculation and JSON save.
    clone['resilienza'] = copyResilience ? '${owner['resilienza'] ?? 0}' : '1';
    clone['currentResilienza'] = copyResilience
        ? '${owner['currentResilienza'] ?? owner['resilienza'] ?? 0}'
        : '1';
    clone['tempResilienza'] = copyResilience
        ? readIntValue(owner['tempResilienza'])
        : 0;
    clone['currentHp'] = '$hp';
    clone['hpTemp'] = '0';
    clone['scudo'] = '0';
    clone['scudoOculum'] = '0';
    clone['manualHpMaximumAdjustment'] = hp - oculumHpMultiplierForGrade(grade);
    clone['derivedMaxHp'] = hp;
    clone['hpGradeMultiplier'] = oculumHpMultiplierForGrade(grade);
    clone['oculumShadowClone'] = !asSummon;
    clone['shadowCloneOwnerTag'] = ownerTag;
    clone['shadowCloneSource'] = source;
    clone['shadowCloneTurnsRemaining'] = duration;
    clone['shadowCloneExpired'] = false;
    if (asSummon) {
      final summonId = 'summon_${DateTime.now().microsecondsSinceEpoch}';
      clone
        ..['isSummon'] = true
        ..['summonInstanceId'] = summonId
        ..['summonerTag'] = ownerTag
        ..['summonExpMultiplier'] = (summonExpMultiplier ?? 1).clamp(1, 10)
        ..['summonEncounterId'] = onlineCombatEncounterId.isNotEmpty
            ? onlineCombatEncounterId
            : selectedMasterInitiativeGroupId
        ..['summonExpired'] = false
        ..['summonKind'] = summonKind
        ..['notePersonaggio'] = summonDescription
        ..['background'] = summonDescription
        ..['skills'] = summonSkills.map((skill) => skill.toJson()).toList();
      clone.remove('oculumShadowClone');
      clone.remove('shadowCloneTurnsRemaining');
      clone.remove('shadowCloneExpired');
    }
    clone['countsForPartyStats'] = false;
    clone['inMasterParty'] = true;
    if (!asSummon) clone['skills'] = <dynamic>[];
    clone['arti'] = <dynamic>[];
    clone['conditions'] = <Map<String, dynamic>>[];
    clone['activeStructuredEffects'] = <Map<String, dynamic>>[];

    final cloneTag = normalizeOculumFriendTag(
      '${clone['sheetTag'] ?? clone['id'] ?? ''}',
    );
    final index = schedePersonaggio.length;
    if (cloneTag.isNotEmpty &&
        schedePersonaggio.any(
          (sheet) =>
              normalizeOculumFriendTag('${sheet['sheetTag'] ?? sheet['id']}') ==
              cloneTag,
        )) {
      clone.remove('sheetTag');
      clone.remove('id');
    }
    schedePersonaggio.add(clone);
    assicuraTagSchede();
    final actualTag = sheetTagAt(index);
    final localOwnerInTurnOrder = masterInitiativeTokens.any(
      (token) =>
          normalizeOculumFriendTag(
            '${token['sheetTag'] ?? token['id'] ?? ''}',
          ).toUpperCase() ==
          ownerTag.toUpperCase(),
    );
    final sharedEncounters = realtimeEncounterSnapshots.isNotEmpty
        ? realtimeEncounterSnapshots
        : <Map<String, dynamic>>[
            if (realtimeVisibleInitiativeSnapshot.isNotEmpty)
              realtimeVisibleInitiativeSnapshot,
          ];
    final sharedEncounter = oculumSelectSharedEncounter(
      sharedEncounters,
      sheetTag: ownerTag,
      selectedId: realtimeSelectedEncounterId,
    );
    final sharedOwnerInTurnOrder =
        (sharedEncounter['tokens'] as List? ?? const <dynamic>[])
            .whereType<Map>()
            .any(
              (token) =>
                  normalizeOculumFriendTag(
                    '${token['sheetTag'] ?? token['id'] ?? ''}',
                  ).toUpperCase() ==
                  ownerTag.toUpperCase(),
            );
    if (currentCombatIsActive() &&
        (localOwnerInTurnOrder || sharedOwnerInTurnOrder)) {
      if (realtimeService?.isConnected != true || realtimeIsMasterRole) {
        scheduleMicrotask(() {
          if (!mounted || index >= schedePersonaggio.length) return;
          addSheetToMasterInitiative(index, rollInitiative: true);
          final token = masterInitiativeTokens.firstWhere(
            (item) => '${item['sheetTag'] ?? ''}' == actualTag,
            orElse: () => <String, dynamic>{},
          );
          if (token.isNotEmpty && !asSummon) {
            token['oculumShadowClone'] = true;
            token['shadowCloneTurnsRemaining'] = duration;
          }
          sendRealtimeInitiativeSnapshotIfPublished();
        });
      } else {
        if ('${sharedEncounter['encounterId'] ?? ''}'.isNotEmpty) {
          unawaited(_shareShadowCloneAndRequestTurn(index, sharedEncounter));
        }
      }
    }
    programmaSalvataggio();
    notifyActiveSheetSummaryChanged();
    unawaited(sendRealtimeActiveSheetToStaff());
    return index;
  }

  bool createPiranhaMinion({required int hp, required String source}) {
    final ownerTag = sheetTagAt(schedaCorrente);
    final existing = schedePersonaggio.where(
      (sheet) =>
          sheet['isSummon'] == true &&
          sheet['summonKind'] == 'piranha_minore' &&
          '${sheet['summonerTag'] ?? ''}' == ownerTag &&
          sheet['summonExpired'] != true,
    );
    if (existing.length >= 2) return false;
    final skill = CharacterSkill(
      nome: 'Morso minore',
      tipo: 'Attacco evocazione',
      costo: 'Nessun costo',
      cooldown: '1 turno',
      descrizione: '@Danni+1 Acqua',
      danni: 1,
      equipaggiata: true,
    );
    final summonIndex = createShadowCloneSheet(
      hp: hp,
      duration: 3,
      source: source,
      displayName: 'Piranha minore di ${nomeSchedaPersonaggio(schedaCorrente)}',
      asSummon: true,
      summonSkills: [skill],
      summonKind: 'piranha_minore',
      summonDescription:
          'Piccolo alleato acquatico. 1 Resilienza, 0 Volontà/Materia/Oculum; non può evocare altri Piranha.',
    );
    if (summonIndex < 0 || summonIndex >= schedePersonaggio.length) {
      return false;
    }
    final summon = schedePersonaggio[summonIndex];
    summon
      ..['livello'] = '0'
      ..['grado'] = '0'
      ..['resilienza'] = '1'
      ..['currentResilienza'] = '1'
      ..['volonta'] = '0'
      ..['currentVolonta'] = '0'
      ..['materia'] = '0'
      ..['currentMateria'] = '0'
      ..['oculum'] = '0'
      ..['currentOculum'] = '0'
      ..['manualHpMaximumAdjustment'] = hp - oculumHpMultiplierForGrade(0)
      ..['currentHp'] = '$hp'
      ..['derivedMaxHp'] = hp;
    programmaSalvataggio();
    return true;
  }

  int createDeadKnightOldLoveSheet({required String source}) {
    if (schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length) {
      return -1;
    }
    final owner = schedePersonaggio[schedaCorrente];
    if ('${owner['monsterBookSourceId'] ?? ''}' != 'cavaliere_morto') {
      return -1;
    }
    final ownerTag = sheetTagAt(schedaCorrente);
    final fightId = onlineCombatEncounterId.isNotEmpty
        ? onlineCombatEncounterId
        : selectedMasterInitiativeGroupId;
    final alreadyCalled =
        masterInitiativeTokens.any(
          (token) =>
              token['summonKind'] == 'un_vecchio_amore' &&
              '${token['summonerTag'] ?? ''}' == ownerTag,
        ) ||
        '${owner['deadKnightOldLoveSummonedFightId'] ?? ''}' == fightId;
    if (alreadyCalled) return -1;

    const hairColors = ['viola', 'argento', 'blu notte', 'rame', 'bianco'];
    final hair = hairColors[Random.secure().nextInt(hairColors.length)];
    final level = max(0, readIntValue(owner['livello']));
    final grade = max(0, readIntValue(owner['grado']));
    final bow = CharacterSkill(
      nome: 'Arco della promessa',
      tipo: 'Attacco evocazione',
      costo: '1 azione',
      cooldown: '1 turno',
      descrizione:
          'Scocca una freccia d’ombra contro un bersaglio. @Danni+${max(1, level + 5)} Ombra',
      danni: max(1, level + 5),
      equipaggiata: true,
    );
    final summonIndex = createShadowCloneSheet(
      hp: max(1, sheetMaxHpForDeathAt(schedaCorrente)),
      duration: 1,
      source: source,
      displayName: 'Un vecchio amore · capelli $hair',
      asSummon: true,
      copyResilience: true,
      summonExpMultiplier: 2,
      summonSkills: [bow],
      summonKind: 'un_vecchio_amore',
      summonDescription:
          'Donna scheletrica evocata dal terreno, capelli color $hair, armatura di pelle e arco. Summon del Cavaliere Morto, livello $level, Grado $grade. Vale il doppio dell’EXP massima di una Summon. La scheda e l’abilità restano modificabili.',
    );
    owner['deadKnightOldLoveSummonedFightId'] = fightId;
    if (summonIndex >= 0) {
      schedePersonaggio[summonIndex]['summonKind'] = 'un_vecchio_amore';
    }
    programmaSalvataggio();
    return summonIndex;
  }

  int createPatalpaCompanionSheet({required String source}) {
    if (schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length) {
      return -1;
    }
    final owner = schedePersonaggio[schedaCorrente];
    final cooldown = max(
      0,
      readIntValue(owner['patalpaSummonCooldownFightsRemaining']),
    );
    if (cooldown > 0) {
      risultato = 'Richiamo del Patalpa: cooldown di $cooldown fight.';
      aggiungiLog(risultato);
      notifyDiceResultChanged();
      return -1;
    }
    final ownerTag = sheetTagAt(schedaCorrente);
    final alreadyCalled = masterInitiativeTokens.any(
      (token) =>
          token['summonKind'] == 'patalpa_richiamo' &&
          '${token['summonerTag'] ?? ''}' == ownerTag,
    );
    if (alreadyCalled) return -1;
    final level = max(0, readIntValue(owner['livello']));
    final grade = max(0, readIntValue(owner['grado']));
    final attack = max(5, level + 5);
    final skill = CharacterSkill(
      nome: 'Palata del compagno',
      tipo: 'Attacco evocazione',
      costo: '1 azione',
      cooldown: '2 turni',
      descrizione:
          'Una palata di radici colpisce il bersaglio. @Danni+$attack Natura',
      danni: attack,
      equipaggiata: true,
    );
    final receivesNoOculumResilienceBonus = Random.secure().nextInt(100) >= 75;
    final summonIndex = createShadowCloneSheet(
      hp: max(1, sheetMaxHpForDeathAt(schedaCorrente)),
      duration: 1,
      source: source,
      displayName: 'Patalpa richiamato · Lv $level',
      asSummon: true,
      copyResilience: true,
      summonSkills: [skill],
      summonKind: 'patalpa_richiamo',
      summonDescription:
          'Patalpa evocato: livello $level, Grado $grade, alleato di ${nomeSchedaPersonaggio(schedaCorrente)} per il fight. Distribuzione base: 20% Resilienza, 50% Volontà, 30% Materia; nel 75% degli spawn non riceve il punto bonus di Resilienza per livello, nel 25% lo riceve. Il totale segue il budget di crescita del Patalpa. Il suo richiamo segue la regola EXP delle Summon: al massimo 5 + Grado per l’intero party; l’evocatore non riceve EXP salvo che il Fato renda la creatura realmente ostile.',
    );
    if (summonIndex >= 0 && summonIndex < schedePersonaggio.length) {
      final stats = oculumPatalpaSummonStats(
        level,
        receivesNoOculumResilienceBonus: receivesNoOculumResilienceBonus,
      );
      final summon = schedePersonaggio[summonIndex];
      summon
        ..['resilienza'] = '${stats['resilienza']}'
        ..['currentResilienza'] = '${stats['resilienza']}'
        ..['volonta'] = '${stats['volonta']}'
        ..['currentVolonta'] = '${stats['volonta']}'
        ..['materia'] = '${stats['materia']}'
        ..['currentMateria'] = '${stats['materia']}'
        ..['oculum'] = '0'
        ..['currentOculum'] = '0'
        ..['patalpaSummonStatDistribution'] = <String, dynamic>{
          'resiliencePercent': 20,
          'willPercent': 50,
          'matterPercent': 30,
          'noOculumResiliencePerLevel': 1,
          'resilienceBonusChancePercent': 25,
          'spawnedWithResilienceBonus': receivesNoOculumResilienceBonus,
          'level': level,
          'stats': stats,
        };
      owner['patalpaSummonCooldownFightsRemaining'] = 3;
      owner['patalpaSummonCooldownLastEncounterId'] = '';
      programmaSalvataggio();
    }
    return summonIndex;
  }

  Future<void> _shareShadowCloneAndRequestTurn(
    int index,
    Map<String, dynamic> encounter,
  ) async {
    // joinSharedMasterEncounter retries the full-sheet transfer with a Master
    // receipt before publishing the join request; avoid duplicate transfers.
    if (!mounted || index >= schedePersonaggio.length) return;
    await joinSharedMasterEncounter(encounter, sheetIndex: index);
  }

  String activeStructuredEffectTiming(Map<String, dynamic> effect) {
    if (effect['mode'] == 'prossima_azione') {
      return t('prossimo attacco', 'next attack');
    }
    final frequency = oculumStructuredEffectFrequency(effect['frequency']);
    final remaining = readIntValue(effect['remaining']);
    final unit = oculumTurnUnit('${effect['unit'] ?? 'turni'}');
    if (frequency > 0) {
      final elapsed = max(0, readIntValue(effect['frequencyElapsed']));
      final untilNext = max(1, frequency - elapsed);
      final expiry = remaining > 0 ? ' · durata $remaining $unit' : '';
      return 'ogni $frequency $unit · prossimo tra $untilNext$expiry';
    }
    return '$remaining $unit';
  }

  bool consumeNextAttackStructuredEffects() {
    final before = activeStructuredEffects.length;
    activeStructuredEffects.removeWhere(
      (effect) => effect['mode'] == 'prossima_azione',
    );
    if (before == activeStructuredEffects.length) return false;
    invalidateDerivedDataCaches(notifyHiddenEyeCards: false);
    scheduleHiddenEyeDerivedCardsRefresh();
    scheduleCombatRollSave();
    return true;
  }

  Widget activeStructuredEffectsCard() {
    if (activeStructuredEffects.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: primaryColor.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Effetti strutturati attivi', 'Active structured effects'),
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          for (var index = 0; index < activeStructuredEffects.length; index++)
            Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        activeStructuredEffects[index]['type'] ==
                                'pending_target'
                            ? '${activeStructuredEffects[index]['source']}: ${oculumStructuredEffectDescription(OculumStructuredEffect.fromJson(Map<String, dynamic>.from(activeStructuredEffects[index]['effect'] as Map)))} · da applicare al bersaglio'
                            : '${activeStructuredEffects[index]['source']}: '
                                  '${activeStructuredEffects[index]['target']} '
                                  '${activeStructuredEffects[index]['type'] == 'costrutto' ? '${activeStructuredEffects[index]['hp']}/${activeStructuredEffects[index]['maxHp']} Vita · ' : ''}'
                                  '${readIntValue(activeStructuredEffects[index]['value']) >= 0 ? '+' : ''}'
                                  '${activeStructuredEffects[index]['value']}'
                                  '${const {'danno_percentuale', 'difesa_percentuale'}.contains(activeStructuredEffects[index]['type']) ? '%' : ''} - '
                                  '${activeStructuredEffectTiming(activeStructuredEffects[index])}',
                      ),
                      if (activeStructuredEffects[index]['type'] ==
                              'costrutto' &&
                          activeStructuredEffects[index]['mode'] == 'nidiata')
                        Padding(
                          padding: const EdgeInsets.only(top: 4, right: 6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              key: ValueKey('larval_brood_effect_bar_$index'),
                              value:
                                  readIntValue(
                                        activeStructuredEffects[index]['maxHp'],
                                      ) <=
                                      0
                                  ? 0
                                  : (readIntValue(
                                              activeStructuredEffects[index]['hp'],
                                            ) /
                                            readIntValue(
                                              activeStructuredEffects[index]['maxHp'],
                                            ))
                                        .clamp(0.0, 1.0),
                              minHeight: 7,
                              color: const Color(0xFFE44D5E),
                              backgroundColor: const Color(0xFF4A1720),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (activeStructuredEffects[index]['type'] == 'pending_target')
                  IconButton(
                    tooltip:
                        (activeStructuredEffects[index]['effect']
                                as Map?)?['recipient'] ==
                            'alleato'
                        ? 'Scegli i destinatari del supporto'
                        : realtimeService?.isConnected == true
                        ? 'Dichiara un attacco nella turnistica'
                        : 'Applica a una scheda locale dopo la difesa',
                    icon: const Icon(Icons.gps_fixed),
                    onPressed:
                        (activeStructuredEffects[index]['effect']
                                as Map?)?['recipient'] ==
                            'alleato'
                        ? () => deliverPendingSupport()
                        : realtimeService?.isConnected == true
                        ? () => planOnlineAttack()
                        : () => applyPendingTargetEffectLocally(
                            activeStructuredEffects[index],
                          ),
                  ),
                if (activeStructuredEffects[index]['type'] == 'costrutto')
                  IconButton(
                    tooltip: t('Danni al costrutto', 'Damage to construct'),
                    icon: const Icon(Icons.heart_broken_outlined, size: 18),
                    onPressed: () => damageStructuredConstruct(
                      activeStructuredEffects[index],
                    ),
                  ),
                IconButton(
                  tooltip: t('Termina effetto', 'End effect'),
                  onPressed: () {
                    final removedEffect = activeStructuredEffects[index];
                    setState(() {
                      activeStructuredEffects.removeAt(index);
                      if ('${removedEffect['type'] ?? ''}' == 'stato' &&
                          '${removedEffect['target'] ?? ''}' ==
                              'sotto_stress' &&
                          !activeStructuredEffects.any(
                            (effect) =>
                                '${effect['type'] ?? ''}' == 'stato' &&
                                '${effect['target'] ?? ''}' == 'sotto_stress',
                          )) {
                        sottoStress = sottoStressManuale;
                        if (!sottoStress) {
                          stressStatConsumptionProgress.clear();
                        }
                      }
                    });
                    invalidateDerivedDataCaches();
                    programmaSalvataggio(invalidateCaches: false);
                  },
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> applyPendingTargetEffectLocally(
    Map<String, dynamic> pending, {
    int? selectedIndex,
  }) async {
    if (onlineMasterApprovalRequired || pending['effect'] is! Map) return;
    final source = schedaCorrente;
    final origin = currentSheetScrollId();
    final target =
        selectedIndex ??
        await showDialog<int>(
          context: context,
          builder: (dialog) => AlertDialog(
            title: const Text('Effetto · bersaglio locale'),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Seleziona la scheda su cui applicare l’effetto dopo aver risolto il tiro di difesa. Non modifica il Monster Book.',
                    ),
                    for (
                      var index = 0;
                      index < schedePersonaggio.length;
                      index++
                    )
                      ListTile(
                        title: Text(
                          '${schedePersonaggio[index]['nome'] ?? 'Scheda ${index + 1}'}',
                        ),
                        onTap: () => Navigator.pop(dialog, index),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog),
                child: const Text('Annulla'),
              ),
            ],
          ),
        );
    if (!mounted ||
        target == null ||
        target >= schedePersonaggio.length ||
        currentSheetScrollId() != origin ||
        !activeStructuredEffects.contains(pending) ||
        onlineMasterApprovalRequired) {
      return;
    }
    final effect = OculumStructuredEffect.fromJson(
      Map<String, dynamic>.from(pending['effect'] as Map),
    )..recipient = 'se_stesso';
    activeStructuredEffects.remove(pending);
    aggiungiLog(
      'Effetto ${pending['source']} assegnato a ${schedePersonaggio[target]['nome']}.',
    );
    salvaSchedaCorrenteInMemoria();
    final global = catturaImpostazioniGlobali();
    setState(() {
      schedaCorrente = target;
      caricaStatoDaJson(schedePersonaggio[target]);
      ripristinaImpostazioniGlobali(global);
    });
    try {
      if (effect.type == 'danno' || effect.type == 'danno_percentuale') {
        final amount = effect.type == 'danno_percentuale'
            ? oculumTargetPercentageDamage(
                percent: readIntValue(effect.valueExpression),
                hp: hpCorrenti(),
                temporaryHp: hpTemp(),
                shield: scudo(),
                oculumShield: scudoOculum(),
                bypassShields: effect.bypassShields,
              )
            : max(0, readIntValue(effect.valueExpression));
        await applicaDannoSubito(
          dannoEsplicito: amount,
          bypassDefense: effect.bypassDefense,
          bypassShields: effect.bypassShields,
          resistanceBypassDamage: effect.bypassResistance
              ? max(0, readIntValue(effect.valueExpression))
              : 0,
          shieldDamageBonusPercent: effect.shieldDamageBonusPercent,
        );
      } else {
        for (final message in applyStructuredEffectsOnActivation(
          [effect],
          source: '${pending['source']}',
          applyFusionBonus: false,
        )) {
          aggiungiLog(message);
        }
      }
      salvaSchedaCorrenteInMemoria();
    } finally {
      if (mounted &&
          schedaCorrente == target &&
          source < schedePersonaggio.length) {
        setState(() {
          schedaCorrente = source;
          caricaStatoDaJson(schedePersonaggio[source]);
          ripristinaImpostazioniGlobali(global);
        });
      }
      programmaSalvataggio();
    }
  }

  Future<void> damageStructuredConstruct(Map<String, dynamic> construct) async {
    final controller = TextEditingController();
    final damage = await oculumShowDialogUntilClosed<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${construct['target']} — ${t('Danni subiti', 'Damage taken')}',
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: t(
              'Danni alla Vita del costrutto',
              'Damage to construct HP',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('Annulla', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              max(0, int.tryParse(controller.text) ?? 0),
            ),
            child: Text(t('Applica', 'Apply')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted ||
        damage == null ||
        damage <= 0 ||
        !activeStructuredEffects.contains(construct)) {
      return;
    }
    final before = readIntValue(construct['hp']);
    final after = max(0, before - damage);
    setState(() {
      construct['hp'] = after;
      if (after == 0) activeStructuredEffects.remove(construct);
    });
    final message =
        '${construct['target']}: perde ${before - after} Vita ($before → $after/${construct['maxHp']}).${after == 0 ? ' Costrutto distrutto.' : ''}';
    aggiungiLog(message);
    sendRealtimeDiceRoll(
      label: message,
      roll: 0,
      bonus: 0,
      total: before - after,
      forceMasterVisible: true,
    );
    invalidateDerivedDataCaches();
    programmaSalvataggio(invalidateCaches: false);
  }
}
