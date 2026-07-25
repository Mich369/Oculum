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
      _ => key,
    };
  }

  int activeStructuredEffectBonus(String target) {
    final normalized = normalizedStructuredTarget(target);
    var total = 0;
    for (final effect in activeStructuredEffects) {
      if (readIntValue(effect['remaining']) <= 0) continue;
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
      currentOculumController.text = (currentOculum() + amount)
          .clamp(0, oculumMassimo())
          .toString();
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
      if (remaining <= 0) continue;
      if ('${effect['mode'] ?? ''}' == 'rigenerazione') {
        applyStructuredHealing(
          '${effect['resource'] ?? 'vita'}',
          readIntValue(effect['value']),
        );
      }
      effect['remaining'] = max(0, remaining - 1);
      changed = true;
    }
    activeStructuredEffects.removeWhere(
      (effect) => readIntValue(effect['remaining']) <= 0,
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

        switch (effect.type) {
          case 'cura':
            if (effect.mode != 'rigenerazione') {
              applyStructuredHealing(effect.resource, value);
            }
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
            currentOculumController.text = max(
              0,
              currentOculum() + value,
            ).toString();
            recordCurrentOculumProgress();
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
        }.contains(effect.type);
        final isRegeneration =
            effect.type == 'cura' && effect.mode == 'rigenerazione';
        if ((isOngoingBonus || isRegeneration) && duration > 0) {
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
            'remaining': duration,
            'unit': effect.durationUnit,
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
        final durationText = duration > 0
            ? ' - ${t('durata', 'duration')} $duration ${effect.durationUnit}'
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
                    '${activeStructuredEffects[index]['remaining']} '
                    '${activeStructuredEffects[index]['unit']}',
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
