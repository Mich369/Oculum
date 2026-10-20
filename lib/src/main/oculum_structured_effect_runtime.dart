part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _OculumStructuredEffectRuntime on _OculumHomePageState {
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
      total += readIntValue(effect['value']);
    }
    for (final effect in automaticMonsterPassiveEffects()) {
      if (!const {
        'danno',
        'danno_percentuale',
        'difesa',
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
      total += oculumEvaluateStructuredEffectValue(
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
  }) {
    final messages = <String>[];
    final variables = formulaValueContext();
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
                ...variables,
                'danni': max(0, dannoTotaleBaseSenzaComandi()),
              }
            : variables;
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
        final value = negative ? -roll.value.abs() : roll.value;
        final duration = max(0, roll.baseDuration + roll.durationBonus);
        final effectTarget = oculumStructuredEffectTargetKey(effect);
        final target = effect.type == 'stato'
            ? (effect.appliedState.isEmpty
                  ? 'sotto_stress'
                  : effect.appliedState)
            : normalizedStructuredTarget(
                effectTarget.isNotEmpty ? effectTarget : effect.target,
              );
        final frequency = effect.mode == 'prossima_azione'
            ? 0
            : oculumStructuredEffectFrequency(effect.frequency);
        final isPeriodic = frequency > 0;
        final preparedAttackBonus =
            const {'danno', 'danno_percentuale'}.contains(effect.type) &&
            effect.mode == 'prossima_azione' &&
            !(isAreaDamage && effect.recipient == 'nemico');
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
            '${oculumStructuredEffectDescription(effect, subtraits: hiddenEyeStats)} = $value · pronto sul bersaglio del prossimo attacco, dopo la difesa.',
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
          case 'evocazione':
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
                stage: max(1, value.abs()),
                duration: duration > 0 ? duration : null,
                durationType: switch (oculumTurnUnit(effect.durationUnit)) {
                  'tiri' => OculumConditionDurationType.rolls,
                  'azioni' => OculumConditionDurationType.actions,
                  'riposi_brevi' => OculumConditionDurationType.shortRest,
                  'riposi_lunghi' => OculumConditionDurationType.longRest,
                  _ => OculumConditionDurationType.turns,
                },
                source: source,
                metadata: effect.resource == 'oculum_upkeep'
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
      nome: 'Clone d’ombra di ${nomeSchedaPersonaggio(schedaCorrente)}',
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
    clone['resilienza'] = '1';
    clone['currentResilienza'] = '1';
    clone['tempResilienza'] = 0;
    clone['currentHp'] = '$hp';
    clone['hpTemp'] = '0';
    clone['scudo'] = '0';
    clone['scudoOculum'] = '0';
    clone['manualHpMaximumAdjustment'] = hp - oculumHpMultiplierForGrade(grade);
    clone['derivedMaxHp'] = hp;
    clone['hpGradeMultiplier'] = oculumHpMultiplierForGrade(grade);
    clone['oculumShadowClone'] = true;
    clone['shadowCloneOwnerTag'] = ownerTag;
    clone['shadowCloneSource'] = source;
    clone['shadowCloneTurnsRemaining'] = duration;
    clone['shadowCloneExpired'] = false;
    clone['countsForPartyStats'] = false;
    clone['inMasterParty'] = true;
    clone['skills'] = <dynamic>[];
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
          if (token.isNotEmpty) {
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
    return index;
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
                                  '${activeStructuredEffects[index]['type'] == 'danno_percentuale' ? '%' : ''} - '
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
      if (effect.type == 'danno') {
        await applicaDannoSubito(
          dannoEsplicito: max(0, readIntValue(effect.valueExpression)),
        );
      } else {
        for (final message in applyStructuredEffectsOnActivation([
          effect,
        ], source: '${pending['source']}')) {
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
