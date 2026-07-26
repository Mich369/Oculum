part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _OculumStructuredEffectRuntime on _OculumHomePageState {
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
    currentHpController.text = (hpCorrenti() + amount)
        .clamp(0, maxHp())
        .toString();
  }

  bool tickActiveStructuredEffects(String unit) {
    final normalizedUnit = oculumNormalizeText(unit);
    var changed = false;
    final hadTimedStressEffect = activeStructuredEffects.any(
      (effect) =>
          '${effect['type'] ?? ''}' == 'stato' &&
          '${effect['target'] ?? ''}' == 'sotto_stress',
    );
    for (final effect in activeStructuredEffects) {
      if (oculumNormalizeText('${effect['unit'] ?? ''}') != normalizedUnit) {
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

    for (final effect in effects.where((item) => item.enabled)) {
      try {
        final roll = oculumResolveStructuredEffectRoll(
          effect,
          variables: variables,
          subtraits: hiddenEyeStats,
          spentResources: spentResources,
          level: resolvedLevel,
          grade: resolvedGrade,
        );
        final negative =
            effect.mode == 'diminuzione' || effect.type.startsWith('rimuovi_');
        final value = negative ? -roll.value.abs() : roll.value;
        final durationEffect = OculumStructuredEffect(
          valueExpression: effect.duration.trim().isEmpty
              ? '0'
              : effect.duration,
        );
        final baseDuration = effect.duration.trim().isEmpty
            ? 0
            : oculumEvaluateStructuredEffectValue(
                durationEffect,
                variables: variables,
                subtraits: hiddenEyeStats,
                spentResources: spentResources,
              );
        final duration = max(0, baseDuration + roll.durationBonus);
        final effectTarget = oculumStructuredEffectTargetKey(effect);
        final target = effect.type == 'stato'
            ? (effect.appliedState.isEmpty
                  ? 'sotto_stress'
                  : effect.appliedState)
            : normalizedStructuredTarget(
                effectTarget.isNotEmpty ? effectTarget : effect.target,
              );
        final frequency = oculumStructuredEffectFrequency(effect.frequency);
        final isPeriodic = frequency > 0;

        switch (effect.type) {
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
          case 'stato':
            if (target == 'sotto_stress') sottoStress = true;
            break;
        }

        final isOngoingBonus = <String>{
          'danno',
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
        }.contains(effect.type);
        final isRegeneration =
            effect.type == 'cura' && effect.mode == 'rigenerazione';
        final effectiveDuration =
            <String>{
                  'rimuovi_reazioni',
                  'rimuovi_reazioni_rapide',
                  'aggiungi_reazioni',
                  'aggiungi_reazioni_rapide',
                }.contains(effect.type) &&
                duration <= 0
            ? 1
            : duration;
        if ((isOngoingBonus || isRegeneration || isPeriodic) &&
            (effectiveDuration > 0 || isPeriodic)) {
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
            'value': value,
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
        } else if (isOngoingBonus && duration == 0) {
          final fixedKey = normalizedStructuredTarget(effect.target);
          if (<String>{
            'resilienza',
            'volonta',
            'materia',
            'oculum',
          }.contains(fixedKey)) {
            modificaBuffTemporaneo(fixedKey, value, salva: false);
          }
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

  String activeStructuredEffectTiming(Map<String, dynamic> effect) {
    final frequency = oculumStructuredEffectFrequency(effect['frequency']);
    final remaining = readIntValue(effect['remaining']);
    final unit = '${effect['unit'] ?? 'turni'}';
    if (frequency > 0) {
      final elapsed = max(0, readIntValue(effect['frequencyElapsed']));
      final untilNext = max(1, frequency - elapsed);
      final expiry = remaining > 0 ? ' · durata $remaining $unit' : '';
      return 'ogni $frequency $unit · prossimo tra $untilNext$expiry';
    }
    return '$remaining $unit';
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
                  child: Text(
                    '${activeStructuredEffects[index]['source']}: '
                    '${activeStructuredEffects[index]['target']} '
                    '${readIntValue(activeStructuredEffects[index]['value']) >= 0 ? '+' : ''}'
                    '${activeStructuredEffects[index]['value']} - '
                    '${activeStructuredEffectTiming(activeStructuredEffects[index])}',
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
}
