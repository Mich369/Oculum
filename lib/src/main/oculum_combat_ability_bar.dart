part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

enum OculumCombatAbilityRole { attack, defense, support }

final _oculumAbilityPlacementPattern = RegExp(
  r'\[pannello:(attacco|difesa|supporto)\]\s*',
  caseSensitive: false,
);
String oculumAbilityPlacement(String type) =>
    _oculumAbilityPlacementPattern.firstMatch(type)?.group(1)?.toLowerCase() ??
    '';
String oculumAbilityTypeWithPlacement(String type, String placement) {
  final content = type.replaceAll(_oculumAbilityPlacementPattern, '').trim();
  return placement.isEmpty ? content : '[pannello:$placement] $content'.trim();
}

bool oculumCombatTextHasUnresolvedRequirement(String text) =>
    RegExp(r'\[\s*Richiede\b[^\]]*\]', caseSensitive: false).hasMatch(text);

({String expression, int minimum, int maximum}) _combatFormulaDiceBounds(
  String raw,
) {
  var minimum = 0;
  var maximum = 0;
  final expression = raw.replaceAllMapped(RegExp(r'\b(\d*)\s*[dD]\s*(\d+)\b'), (
    match,
  ) {
    final count = int.tryParse(match.group(1) ?? '') ?? 1;
    final faces = int.tryParse(match.group(2) ?? '') ?? 1;
    minimum += count;
    maximum += count * faces;
    return '0';
  });
  return (expression: expression, minimum: minimum, maximum: maximum);
}

String _combatEffectPreview(
  OculumStructuredEffect effect, {
  required Map<String, num> variables,
  required Iterable<HiddenEyeStat> subtraits,
  required int level,
  required int grade,
}) {
  if (effect.target == 'total_power_burst' &&
      (variables['lettura_aura'] ?? 0) < 20) {
    return 'Potenza totale ai Danni di un solo colpo · Sfinimento 1d3 + Potenza/160';
  }
  final normalized = OculumStructuredEffect.fromJson(effect.toJson());
  final valueDice = _combatFormulaDiceBounds(
    oculumEffectFormulaExpression(effect.valueExpression, subtraits),
  );
  final extraDice = _combatFormulaDiceBounds(effect.diceExpression);
  normalized.valueExpression = valueDice.expression;
  normalized.diceExpression = '';
  normalized.includeLevel = false;
  normalized.includeGrade = false;
  final base = oculumEvaluateStructuredEffectValue(
    normalized,
    variables: variables,
    subtraits: subtraits,
  );
  final fixedBonus =
      (effect.includeLevel ? max(0, level) : 0) +
      (effect.includeGrade
          ? oculumRoundFormulaResult(max(0, grade) * effect.gradeValue)
          : 0);
  final diceMin =
      valueDice.minimum +
      (effect.diceDestination == 'durata' ? 0 : extraDice.minimum);
  final diceMax =
      valueDice.maximum +
      (effect.diceDestination == 'durata' ? 0 : extraDice.maximum);
  var low = base + fixedBonus + diceMin;
  var high = base + fixedBonus + diceMax;
  if (effect.diceDestination == 'moltiplicatore') {
    low = (base + fixedBonus) * extraDice.minimum;
    high = (base + fixedBonus) * extraDice.maximum;
  }
  final amount = low == high ? '$low' : '$low–$high';
  final duration = _combatFormulaDiceBounds(
    oculumEffectFormulaExpression(effect.duration, subtraits),
  );
  final durationBase = duration.expression.trim().isEmpty
      ? 0
      : oculumEvaluateStructuredEffectValue(
          OculumStructuredEffect(valueExpression: duration.expression),
          variables: variables,
          subtraits: subtraits,
        );
  final durationTotal =
      durationBase +
      (effect.diceDestination == 'durata'
          ? extraDice.minimum
          : duration.minimum);
  final durationMax =
      durationBase +
      (effect.diceDestination == 'durata'
          ? extraDice.maximum
          : duration.maximum);
  final durationText = durationTotal <= 0
      ? ''
      : ' · durata ${durationTotal == durationMax ? durationTotal : '$durationTotal–$durationMax'} ${effect.durationUnit}';
  final targetCount = effect.maximumTargets > 1
      ? ' · fino a ${effect.maximumTargets} bersagli'
      : '';
  final label = switch (effect.type) {
    'danno' => 'Danni',
    'danno_percentuale' => 'Danni',
    'cura' => 'Cura ${effect.resource}'.trim(),
    'scudo' => 'Scudo',
    'scudo_oculum' => 'Scudo Oculum',
    'hp_temporanei' => 'HP temporanei',
    'difesa' => 'Difesa',
    'modifica_statistica' || 'modifica_sottotratto' => 'Bonus ${effect.target}',
    'stato' => 'Condizione ${effect.appliedState}',
    'elemental_resistance' => 'Resistenza ${effect.elementType}',
    'evocazione' || 'costrutto' => 'Evocazione',
    _ =>
      effect.customDisplayText.trim().isEmpty
          ? effect.type
          : effect.customDisplayText,
  };
  final diceNote = [
    if (valueDice.minimum != 0 || valueDice.maximum != 0)
      valueDice.expression.trim(),
    if (extraDice.expression.trim().isNotEmpty) effect.diceExpression,
  ].where((value) => value.trim().isNotEmpty).join(' + ');
  return '$label: $amount${diceNote.isEmpty ? '' : ' · dadi $diceNote'}$durationText$targetCount';
}

Set<OculumCombatAbilityRole> oculumCombatAbilityRoles(
  Iterable<OculumStructuredEffect> effects, {
  String explicitType = '',
  Map<String, num> variables = const {},
}) {
  final active = effects.where((effect) => effect.enabled).toList();
  if (active.any(
    (e) =>
        e.type == 'planar' &&
        const {
          'mask_serious_punch',
          'mask_blue_volley',
          'mask_angelic_arrows',
          'mask_solar_arrows',
          'cycle_bear_spines',
          'cycle_lunar_stomp',
          'cycle_lunar_bite',
          'skeleton_giant_throw',
          'total_power_burst',
          'total_power_accuracy',
          'sand_tail_attack',
        }.contains(e.target),
  )) {
    return {OculumCombatAbilityRole.attack};
  }
  if (active.any((e) => e.target == 'mask_shadow_teleport')) {
    return {OculumCombatAbilityRole.attack, OculumCombatAbilityRole.defense};
  }
  final roles = <OculumCombatAbilityRole>{};
  final scores = <OculumCombatAbilityRole, int>{};
  for (final effect in active) {
    final target = oculumNormalizeText(effect.target);
    // Classification also runs before a target or spend amount exists. A
    // dynamic formula must not break the catalogue; execution still uses the
    // complete value context and validates its real result separately.
    var score = 1;
    try {
      score = max(
        1,
        oculumEvaluateStructuredEffectValue(effect, variables: variables).abs(),
      );
    } on FormatException {
      score = 1;
    }
    OculumCombatAbilityRole? role;
    if (const {'danno', 'danno_percentuale'}.contains(effect.type) ||
        const {'vc', 'attacco', 'danni'}.contains(target)) {
      role = OculumCombatAbilityRole.attack;
    } else if (const {
          'difesa',
          'scudo',
          'hp_temporanei',
          'costrutto',
          'elemental_resistance',
        }.contains(effect.type) ||
        const {
          'cm',
          'difesa',
          'scudo',
          'scudo_oculum',
          'hp_temp',
          'schivata_oculum',
        }.contains(target)) {
      role = OculumCombatAbilityRole.defense;
    }
    if (role != null) scores[role] = (scores[role] ?? 0) + score;
    final utility =
        !const {'danno', 'danno_percentuale'}.contains(effect.type) ||
        effect.recipient == 'se_stesso';
    if (utility) roles.add(OculumCombatAbilityRole.support);
  }
  final declared = oculumNormalizeText(explicitType);
  final manual = oculumAbilityPlacement(explicitType).isNotEmpty
      ? oculumAbilityPlacement(explicitType)
      : explicitType.trim().toLowerCase();
  final manualRole = switch (manual) {
    'attacco' => OculumCombatAbilityRole.attack,
    'difesa' => OculumCombatAbilityRole.defense,
    'supporto' => OculumCombatAbilityRole.support,
    _ => null,
  };
  if (manualRole != null) {
    return {
      manualRole,
      if (roles.contains(OculumCombatAbilityRole.support))
        OculumCombatAbilityRole.support,
    };
  }
  if (scores.isNotEmpty) {
    final strongest = scores.values.reduce(max);
    roles.addAll(
      scores.entries
          .where((entry) => entry.value == strongest)
          .map((entry) => entry.key),
    );
  } else if (declared.contains('attacc') ||
      active.any(
        (effect) =>
            effect.type == 'stato' &&
            effect.recipient != 'se_stesso' &&
            effect.recipient != 'alleato',
      )) {
    roles.add(OculumCombatAbilityRole.attack);
  } else if (declared.contains('difes')) {
    roles.add(OculumCombatAbilityRole.defense);
  }
  if (roles.isEmpty ||
      declared.contains('support') ||
      declared.contains('utilit') ||
      declared.contains('cura')) {
    roles.add(OculumCombatAbilityRole.support);
  }
  return roles;
}

OculumCombatAbilityRole oculumCombatAbilityRole(
  Iterable<OculumStructuredEffect> effects, {
  String explicitType = '',
}) {
  final declared = oculumNormalizeText(explicitType);
  if (declared.contains('support') || declared.contains('cura')) {
    return OculumCombatAbilityRole.support;
  }
  if (declared.contains('difes')) return OculumCombatAbilityRole.defense;
  if (declared.contains('attacc')) return OculumCombatAbilityRole.attack;
  final active = effects.where((e) => e.enabled).toList();
  if (active.any(
    (e) =>
        e.type == 'planar' &&
        const {
          'mask_serious_punch',
          'mask_blue_volley',
          'mask_angelic_arrows',
          'mask_solar_arrows',
          'cycle_bear_spines',
          'cycle_lunar_stomp',
          'cycle_lunar_bite',
          'skeleton_giant_throw',
          'total_power_burst',
          'total_power_accuracy',
          'sand_tail_attack',
        }.contains(e.target),
  )) {
    return OculumCombatAbilityRole.attack;
  }
  if (active.any((e) => e.recipient == 'alleato') &&
      active.every(
        (e) => e.recipient == 'alleato' || e.recipient == 'se_stesso',
      )) {
    return OculumCombatAbilityRole.support;
  }
  if (active.any(
    (e) =>
        const {'danno', 'danno_percentuale'}.contains(e.type) ||
        e.recipient != 'se_stesso' &&
            (e.type == 'stato' || e.mode == 'diminuzione'),
  )) {
    return OculumCombatAbilityRole.attack;
  }
  if (active.any(
    (e) =>
        const {'cura', 'hp_temporanei'}.contains(e.type) ||
        e.recipient == 'alleato',
  )) {
    return OculumCombatAbilityRole.support;
  }
  if (active.any((e) => e.type == 'evocazione')) {
    return OculumCombatAbilityRole.support;
  }
  return OculumCombatAbilityRole.defense;
}

Set<OculumCombatAbilityRole> oculumInventoryItemCombatRoles(
  InventoryItem item,
) {
  final scroll = item.craftData['scroll'];
  if (scroll is Map) {
    final data = Map<String, dynamic>.from(scroll);
    return oculumScrollCombatRoles(data, oculumScrollCombatEffects(data));
  }
  if (item.ability != null) {
    final effects = item.ability!.forme.expand((form) {
      return form.effettiStrutturati.isNotEmpty
          ? form.effettiStrutturati
          : oculumParseStructuredEffectsFromText(form.descrizione).effects;
    });
    return oculumCombatAbilityRoles(effects);
  }
  final description = oculumNormalizeText('${item.nome} ${item.note}');
  if (item.craftData['bomb'] != null ||
      item.craftData['bomba'] != null ||
      description.contains('bomba') ||
      description.contains('bomb')) {
    return {OculumCombatAbilityRole.attack};
  }
  if (item.protegge ||
      item.craftData['protective'] == true ||
      description.contains('scudo') ||
      description.contains('difesa') ||
      description.contains('barriera') ||
      description.contains('protezione')) {
    return {OculumCombatAbilityRole.defense};
  }
  return {OculumCombatAbilityRole.support};
}

extension _OculumCombatAbilityBar on _OculumHomePageState {
  Future<void> finishParsedAbilityTargets(
    String text, {
    int? attackTotal,
    int? natural,
  }) async {
    final origin = currentSheetScrollId();
    final limits = oculumAttackTargetLimits(text, oculumTotale());
    if (activeStructuredEffects.any(
      (effect) =>
          effect['type'] == 'pending_target' &&
          effect['effect'] is Map &&
          (effect['effect'] as Map)['recipient'] == 'alleato',
    )) {
      await deliverPendingSupport(
        minimum: limits.minimum,
        maximum: limits.maximum,
      );
    }
    if (!mounted || currentSheetScrollId() != origin) return;
    if (activeStructuredEffects.any(
          (effect) =>
              effect['type'] == 'pending_target' &&
              effect['effect'] is Map &&
              (effect['effect'] as Map)['recipient'] != 'alleato',
        ) &&
        onlineAttackTokens().isNotEmpty) {
      await planOnlineAttack(
        minimumTargets: limits.minimum,
        maximumTargets: limits.maximum,
        preparedAttackTotal: attackTotal,
        preparedAttackNatural: natural,
      );
    }
  }

  Future<bool> defendPendingCombat(String choice) async {
    if (realtimeService?.isConnected != true && !localMeccanioCombat) {
      return false;
    }
    final tag = sheetTagAt(schedaCorrente);
    final pending = onlineCombatRequests.values
        .where(
          (request) =>
              request['targetTag'] == tag &&
              request['status'] == 'pending' &&
              request['kind'] != 'help' &&
              request['kind'] != 'scout' &&
              request['scope'] == permissionScope &&
              request['encounterId'] == onlineCombatEncounterId,
        )
        .toList();
    if (pending.isEmpty) return false;
    Map<String, dynamic>? selected = pending.first;
    if (pending.length > 1) {
      selected = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialog) => SimpleDialog(
          title: const Text('Quale attacco vuoi difendere?'),
          children: [
            for (final request in pending)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialog, request),
                child: Text('${request['sourceName']} · ${request['attack']}'),
              ),
          ],
        ),
      );
    }
    if (mounted && selected != null && sheetTagAt(schedaCorrente) == tag) {
      await defendOnlineAttack(selected, choice);
    }
    return true;
  }

  Future<void> useCombatRoll(
    OculumCombatAbilityRole role, {
    HiddenEyeStat? stat,
  }) async {
    alignCombatEncounterForRoll();
    final origin = currentSheetScrollId();
    if (outsideFight && role != OculumCombatAbilityRole.support) {
      aggiungiLog('[FUORI FIGHT] Rientra in battaglia dalle Utility.');
      return;
    }
    if (role == OculumCombatAbilityRole.support && stat?.id == 'meccanica') {
      await repairMeccanio(stat!);
      return;
    }
    if (role == OculumCombatAbilityRole.support && stat?.id == 'medicina') {
      if (!await spendCombatRollResource()) return;
      await tiraSottotrattoOcchio(
        stat!,
        actionLabel: 'Medicina · cura',
        onResolved: (natural, total) {
          if (!mounted || currentSheetScrollId() != origin) return;
          final amount = max(0, total) * (natural == 20 ? 2 : 1);
          applyStructuredEffectsOnActivation([
            OculumStructuredEffect(
              type: 'cura',
              resource: 'vita',
              valueExpression: '$amount',
              recipient: 'alleato',
              duration: '0',
            ),
          ], source: 'Medicina${natural == 20 ? ' · cura doppia' : ''}');
        },
      );
      if (mounted && currentSheetScrollId() == origin) {
        await deliverPendingSupport();
      }
      return;
    }
    if (role == OculumCombatAbilityRole.attack &&
        (onlineCombatTokens().isNotEmpty || currentCombatIsActive())) {
      await planOnlineAttack(initialChoice: stat?.id ?? 'vc');
      return;
    }
    if (role == OculumCombatAbilityRole.defense &&
        await defendPendingCombat(stat?.id ?? 'cm')) {
      return;
    }
    if (!mounted || currentSheetScrollId() != origin) return;
    if (!await spendCombatRollResource()) return;
    if (stat != null) {
      await tiraSottotrattoOcchio(
        stat,
        resourceAlreadySpent: true,
        appliesAttackDamageBonus: role == OculumCombatAbilityRole.attack,
      );
    } else {
      await tiraValoreSpeciale(
        role == OculumCombatAbilityRole.attack ? 'VC' : 'CM',
        role == OculumCombatAbilityRole.attack ? vc() : cm(),
        applyGlobalRollModifier: false,
        resourceAlreadySpent: true,
      );
    }
  }

  Widget titleCombatRoleEditor(
    String value,
    ValueChanged<String> changed,
  ) => DropdownButtonFormField<String>(
    initialValue: const ['', 'attacco', 'difesa', 'supporto'].contains(value)
        ? value
        : '',
    decoration: const InputDecoration(
      labelText: 'Gruppo nella barra combattimento',
    ),
    items: const [
      DropdownMenuItem(value: '', child: Text('Automatico dagli effetti')),
      DropdownMenuItem(value: 'attacco', child: Text('Attacco')),
      DropdownMenuItem(value: 'difesa', child: Text('Difesa')),
      DropdownMenuItem(value: 'supporto', child: Text('Supporto e utilità')),
    ],
    onChanged: (value) {
      if (value != null) {
        setState(() => changed(value));
        programmaSalvataggio();
      }
    },
  );

  Widget combatPlacementTypeEditor({
    Key? fieldKey,
    required String label,
    required String initialValue,
    required ValueChanged<String> onChanged,
    String? helper,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      titleCombatRoleEditor(
        oculumAbilityPlacement(initialValue),
        (role) => onChanged(oculumAbilityTypeWithPlacement(initialValue, role)),
      ),
      ExpansionTile(
        title: Text('$label · dettagli avanzati'),
        children: [
          campoModello(
            fieldKey: fieldKey,
            label: label,
            initialValue: initialValue,
            onChanged: onChanged,
            helper: helper,
          ),
        ],
      ),
    ],
  );

  Color combatAbilityResourceColor(Iterable<String> resources) {
    final values = resources.map(oculumNormalizeText).toList();
    if (values.any((v) => v.contains('oculum'))) {
      return statFormulaColor('oculum');
    }
    if (values.any((v) => v.contains('vol'))) {
      return statFormulaColor('volonta');
    }
    if (values.any((v) => v.contains('materia'))) {
      return statFormulaColor('materia');
    }
    if (values.any((v) => v.contains('resilienza') || v.contains('hp'))) {
      return statFormulaColor('resilienza');
    }
    return Theme.of(context).colorScheme.onSurface;
  }

  bool combatAbilityCostAvailable(OculumSkillCost? cost, String text) {
    final parsed = oculumParseAbilityCost(text);
    final resource = cost?.resource ?? parsed?.resource ?? 'nessuna';
    if (oculumNormalizeEffectResource(resource) == 'nessuna') return true;
    final minimum = cost == null
        ? parsed?.minimum ?? 0
        : cost.variable
        ? max(0, cost.minimum)
        : max(
            0,
            oculumEvaluateStructuredEffectValue(
              OculumStructuredEffect(valueExpression: cost.amountExpression),
              variables: formulaValueContext(),
              subtraits: hiddenEyeStats,
            ),
          );
    return artSkillCostResourceAvailable(resource) >= minimum;
  }

  bool combatNaturalFormAvailable(CharacterSkillForm form) =>
      progressionRequirementsMet(form.unlockRequirements) &&
      leggiNumero(livelloController) >= (int.tryParse(form.livello) ?? 0) &&
      !form.tipo.toLowerCase().contains('passiv') &&
      (form.cooldownStrutturato?.ready ?? true) &&
      !oculumCombatTextHasUnresolvedRequirement(
        '${form.descrizione}\n${form.effetto}\n${form.buff}\n${form.danni}\n${form.cura}\n${form.difesa}',
      ) &&
      (form.effettiStrutturati.any((e) => e.id.startsWith('tear_')) &&
              oculumNormalizeEffectResource(form.costoStrutturato?.resource) ==
                  'obser'
          ? artSkillCostResourceAvailable('obser') + currentOculum() >=
                (form.costoStrutturato!.variable
                    ? form.costoStrutturato!.minimum
                    : readIntValue(form.costoStrutturato!.amountExpression))
          : combatAbilityCostAvailable(form.costoStrutturato, form.costo)) &&
      (!form.usaOculumConfigurabile ||
          currentOculum() >= form.oculumMinimoUtilizzabile);

  bool combatArtFormAvailable(CharacterArt art, ArtSkill skill, int form) =>
      progressionRequirementsMet(skill.unlockRequirementsPerLevel[form - 1]) &&
      !skill.tipoPerLivello(form).toLowerCase().contains('passiv') &&
      skill.cooldownPerLivello[form - 1].ready &&
      !oculumCombatTextHasUnresolvedRequirement(skill.testoEvoluzione(form)) &&
      leggiNumero(livelloController) >=
          (int.tryParse(
                RegExp(
                      r'Richiede livello\s+(\d+)',
                      caseSensitive: false,
                    ).firstMatch(skill.testoEvoluzione(form))?.group(1) ??
                    '',
              ) ??
              0) &&
      (artSkillCostResourceAvailable(
                effectiveArtCostResource(art, skill, form),
              ) +
              (skill
                          .effettiEvoluzione(form)
                          .any((e) => e.id.startsWith('tear_')) &&
                      effectiveArtCostResource(art, skill, form) == 'obser'
                  ? currentOculum()
                  : 0)) >=
          skill.oculumMinimoPerLivello(form);

  Future<void> chooseCombatAbilityForm({
    CharacterSkill? natural,
    CharacterArt? art,
    ArtSkill? artSkill,
  }) async {
    final origin = currentSheetScrollId();
    final count = natural?.forme.length ?? (art == null ? 0 : artMaxLevel(art));
    final chosen = await showDialog<int>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: Text(natural?.nome ?? artSkill?.nome ?? 'Abilità'),
        children: [
          for (var form = 0; form < count; form++)
            Builder(
              builder: (_) {
                final available = natural != null
                    ? combatNaturalFormAvailable(natural.forme[form])
                    : combatArtFormAvailable(art!, artSkill!, form + 1);
                if (!available) return const SizedBox.shrink();
                final effectForm = natural?.forme[form];
                final description = effectForm == null
                    ? artSkill!.testoEvoluzione(form + 1)
                    : '${effectForm.descrizione}\n${effectForm.effetto}\n${effectForm.buff}\n${effectForm.danni}\n${effectForm.cura}\n${effectForm.difesa}';
                final requirementLocked =
                    oculumCombatTextHasUnresolvedRequirement(description);
                final structured =
                    effectForm?.effettiStrutturati ??
                    artSkill?.effettiEvoluzione(form + 1) ??
                    const <OculumStructuredEffect>[];
                final cost =
                    effectForm?.costo ??
                    '${artSkill!.oculumMinimoPerLivello(form + 1)}/${artSkill.oculumMassimoPerLivello(form + 1)} ${artSkill.risorsaCostoPerLivello(form + 1)}';
                final timer =
                    effectForm?.cooldownStrutturato ??
                    artSkill?.cooldownPerLivello[form];
                return SimpleDialogOption(
                  onPressed: timer?.ready == false || requirementLocked
                      ? null
                      : () => Navigator.pop(dialog, form),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${artLevelRoman(form + 1)} · $cost${timer?.ready == false ? ' · recupero ${timer!.remaining} ${timer.unit}' : ''}${requirementLocked ? ' · requisito non soddisfatto' : ''}',
                            ),
                            Text(
                              description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Dettagli con i tuoi valori attuali',
                        icon: const Icon(Icons.info_outline),
                        onPressed: () => showCombatAbilityDetails(
                          name:
                              '${natural?.nome ?? artSkill?.nome ?? 'Abilità'} ${artLevelRoman(form + 1)}',
                          description: description,
                          color: eyePupilGlowColor,
                          effects: structured.isNotEmpty
                              ? structured
                              : oculumResolveAbilityEffects(
                                  const [],
                                  description,
                                  subtraits: hiddenEyeStats,
                                  investedOculum: true,
                                ),
                          cost: cost,
                          cooldown: timer?.ready == false
                              ? '${timer!.remaining} ${timer.unit}'
                              : '',
                          locked: requirementLocked,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
    if (!mounted || chosen == null || currentSheetScrollId() != origin) return;
    final description =
        natural?.forme[chosen].descrizione ??
        artSkill!.testoEvoluzione(chosen + 1);
    final oculumBefore = currentOculum();
    final beforeEffects = jsonEncode(activeStructuredEffects);
    final beforeMasked = jsonEncode(pendingMaskedAttack);
    final beforeSandTail = jsonEncode(pendingSandTailAttack);
    final beforeCycleAttack = cyclePreparedAttackSignature;
    final declaredEffects =
        natural?.forme[chosen].effettiStrutturati ??
        artSkill!.effettiEvoluzione(chosen + 1);
    final recognizedEffects = declaredEffects.isNotEmpty
        ? declaredEffects
        : oculumParseAbilityMechanics(
            description,
            subtraits: hiddenEyeStats,
            investedOculum: true,
          ).effects;
    combatSupportTargeting =
        oculumCombatAbilityRole(recognizedEffects) ==
        OculumCombatAbilityRole.support;
    try {
      if (natural != null && skills.contains(natural)) {
        await usaFormaSkill(natural, skills.indexOf(natural), chosen);
      } else if (art != null &&
          artSkill != null &&
          arti.contains(art) &&
          art.skills.contains(artSkill)) {
        await impostaLivelloSkillArt(
          artIndex: arti.indexOf(art),
          skillIndex: art.skills.indexOf(artSkill),
          nuovoLivello: chosen + 1,
          riutilizza: artSkill.livello == chosen + 1,
        );
      }
    } finally {
      combatSupportTargeting = false;
    }

    if (mounted &&
        currentSheetScrollId() == origin &&
        pendingSandTailAttack.isNotEmpty &&
        beforeSandTail != jsonEncode(pendingSandTailAttack) &&
        onlineAttackTokens().isNotEmpty) {
      await planOnlineAttack(maximumTargets: 1);
      return;
    }

    if (mounted &&
        currentSheetScrollId() == origin &&
        pendingMaskedAttack.isNotEmpty &&
        beforeMasked != jsonEncode(pendingMaskedAttack) &&
        onlineAttackTokens().isNotEmpty) {
      await planOnlineAttack();
      return;
    }

    if (mounted &&
        currentSheetScrollId() == origin &&
        beforeCycleAttack != cyclePreparedAttackSignature &&
        cycleHasPreparedAttack &&
        onlineAttackTokens().isNotEmpty) {
      await planOnlineAttack();
      return;
    }

    if (!mounted ||
        currentSheetScrollId() != origin ||
        beforeEffects == jsonEncode(activeStructuredEffects)) {
      return;
    }
    final spentOculum = max(0, oculumBefore - currentOculum());
    var targetLimits = oculumAttackTargetLimits(
      description,
      spentOculum > 0 ? spentOculum : oculumTotale(),
    );
    for (final pendingEffect in activeStructuredEffects.where(
      (e) => e['type'] == 'pending_target',
    )) {
      final configuredMinimum = readIntValue(pendingEffect['minimumTargets']);
      final configuredMaximum = readIntValue(pendingEffect['maximumTargets']);
      if (configuredMinimum > 0 || configuredMaximum > 0) {
        final low = max(1, configuredMinimum);
        targetLimits = (minimum: low, maximum: max(low, configuredMaximum));
      }
    }
    final pending = activeStructuredEffects
        .where(
          (e) =>
              e['type'] == 'pending_target' &&
              e['effect'] is Map &&
              (e['effect'] as Map)['recipient'] != 'alleato',
        )
        .toList();
    for (final effect in pending) {
      effect['minimumTargets'] = targetLimits.minimum;
      effect['maximumTargets'] = targetLimits.maximum;
    }
    if (activeStructuredEffects.any(
      (e) =>
          e['type'] == 'pending_target' &&
          e['effect'] is Map &&
          (e['effect'] as Map)['recipient'] == 'alleato',
    )) {
      await deliverPendingSupport(
        minimum: targetLimits.minimum,
        maximum: targetLimits.maximum,
      );
      if (!mounted || currentSheetScrollId() != origin) return;
    }
    if (pending.isNotEmpty && onlineAttackTokens().isNotEmpty) {
      await planOnlineAttack(
        minimumTargets: targetLimits.minimum,
        maximumTargets: targetLimits.maximum,
      );
    }
  }

  Future<void> showCombatAbilityDetails({
    required String name,
    required String description,
    required Color color,
    Iterable<OculumStructuredEffect> effects = const [],
    String cost = '',
    String cooldown = '',
    bool locked = false,
  }) async {
    final resolved = effects.where((effect) => effect.enabled).toList();
    await showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        scrollable: true,
        title: Row(
          children: [
            Icon(Icons.visibility_outlined, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(name)),
          ],
        ),
        content: SizedBox(
          width: min(620, max(0, MediaQuery.sizeOf(dialog).width - 48)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (locked)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Requisito non soddisfatto: questa voce non è considerata sbloccata.',
                    style: TextStyle(
                      color: Theme.of(dialog).colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (description.trim().isNotEmpty)
                SelectableText(description.trim()),
              if (cost.trim().isNotEmpty || cooldown.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (cost.trim().isNotEmpty)
                      Chip(label: Text('Costo · $cost')),
                    if (cooldown.trim().isNotEmpty)
                      Chip(label: Text('Ricarica · $cooldown')),
                  ],
                ),
              ],
              if (resolved.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Effetto stimato con i tuoi valori attuali',
                  style: Theme.of(dialog).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                for (final effect in resolved)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      '• ${_combatEffectPreview(effect, variables: formulaValueContext(), subtraits: hiddenEyeStats, level: leggiNumero(livelloController), grade: leggiNumero(gradoController))}',
                    ),
                  ),
              ],
              if (resolved.isEmpty && !locked)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Effetto narrativo o personalizzato: il testo completo resta visibile sopra e non viene interpretato come un tiro automatico.',
                    style: Theme.of(dialog).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                'Anteprima informativa: non tira dadi e non consuma risorse.',
                style: Theme.of(dialog).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: Text(t('Chiudi', 'Close')),
          ),
        ],
      ),
    );
  }

  Future<void> showCombatSubtraitDetails(
    HiddenEyeStat stat,
    OculumCombatAbilityRole role,
  ) => showCombatAbilityDetails(
    name: '${stat.nome} · ${hiddenEyeTotal(stat)}',
    description:
        'Tiro d20 con bonus attuale ${hiddenEyeTotal(stat)}. ${switch (role) {
          OculumCombatAbilityRole.attack => 'Puoi usarlo per attaccare: il bersaglio risolve la difesa e le protezioni in ordine.',
          OculumCombatAbilityRole.defense => 'Puoi usarlo per difenderti dall’attacco selezionato; il risultato determina se l’effetto viene evitato, ridotto o applicato.',
          OculumCombatAbilityRole.support => 'Tiro di supporto/utilità. Il bonus deriva dai valori attuali della scheda.',
        }}${stat.id == 'strategia' ? ' Con Strategia +5 è selezionabile anche in attacco; l’aiuto al tiro conserva il bonus configurato.' : ''}${stat.id == 'concentrazione' && hiddenEyeTotal(stat) >= 10 ? ' In fight, se il d20 supera 10, prepara il bonus previsto alla prossima azione.' : ''}${stat.id == 'adattamento' && hiddenEyeTotal(stat) >= 10 ? ' In fight, se il d20 supera 10, prepara la riduzione del prossimo danno.' : ''}',
    color: hiddenEyeStatIdentityColor(stat),
  );

  Widget defenseRollControls(StateSetter refresh, String origin) {
    final available = hiddenEyeStats
        .where(oculumCombatSubtraitSelectable)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Aggiungi tiro difensivo'),
          onPressed: available.any((s) => !combatDefenseRollIds.contains(s.id))
              ? () async {
                  final selected = await showDialog<String>(
                    context: context,
                    builder: (dialog) => SimpleDialog(
                      title: const Text('Aggiungi tiro difensivo'),
                      children: [
                        for (final stat in available.where(
                          (s) => !combatDefenseRollIds.contains(s.id),
                        ))
                          SimpleDialogOption(
                            onPressed: () => Navigator.pop(dialog, stat.id),
                            child: Text(
                              stat.nome,
                              style: TextStyle(
                                color: hiddenEyeStatIdentityColor(stat),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                  if (!mounted ||
                      currentSheetScrollId() != origin ||
                      selected == null) {
                    return;
                  }
                  refresh(() => combatDefenseRollIds.add(selected));
                  programmaSalvataggio();
                }
              : null,
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final stat in available.where(
              (s) => combatDefenseRollIds.contains(s.id),
            ))
              InputChip(
                label: Text(
                  stat.nome,
                  style: TextStyle(color: hiddenEyeStatIdentityColor(stat)),
                ),
                deleteIcon: Icon(
                  Icons.remove_circle_outline,
                  color: hiddenEyeStatIdentityColor(stat),
                  size: 18,
                ),
                deleteButtonTooltipMessage: 'Rimuovi ${stat.nome}',
                onDeleted: () {
                  refresh(() => combatDefenseRollIds.remove(stat.id));
                  programmaSalvataggio();
                },
              ),
          ],
        ),
      ],
    );
  }

  Future<void> showCombatActionPanel(OculumCombatAbilityRole role) async {
    alignCombatEncounterForRoll();
    if (parasiteOwnerLocked) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Controllo del parassita'),
          content: parasiteEscapePanel(),
        ),
      );
      return;
    }
    if (isLarvalParasite && role == OculumCombatAbilityRole.attack) {
      await planOnlineAttack();
      return;
    }
    final origin = currentSheetScrollId();
    final selected = await showDialog<VoidCallback>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          scrollable: true,
          title: Text(switch (role) {
            OculumCombatAbilityRole.attack => t('Attacco', 'Attack'),
            OculumCombatAbilityRole.defense => t('Difesa', 'Defense'),
            OculumCombatAbilityRole.support => t(
              'Supporto e utilità',
              'Help and utility',
            ),
          }),
          content: SizedBox(
            width: min(720, max(0, MediaQuery.sizeOf(dialog).width - 48)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLunarGuardianCoreCreature &&
                    role != OculumCombatAbilityRole.attack)
                  lunarGuardianCorePanel(),
                if (role == OculumCombatAbilityRole.support) ...[
                  totalPowerBurstStatus(),
                  provokerShieldStatus(),
                  guardianGoldificationControls(),
                  escapeUtilityControls(),
                  escapeRequestsPanel(),
                ],
                if (role == OculumCombatAbilityRole.defense)
                  for (final volley in maskedInterruptibleVolleys.toList())
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(dialog);
                        unawaited(interruptMaskedVolley(volley));
                      },
                      icon: const Icon(Icons.front_hand),
                      label: Text(
                        'Interrompi raffica · colpo ${readIntValue(volley['maskedHitIndex']) + 1} · serve critico',
                      ),
                    ),
                if (role == OculumCombatAbilityRole.support && isMountedInMecha)
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(dialog);
                      unawaited(exitMecha());
                    },
                    child: const Text('Esci dal mecha · Azione'),
                  ),
                if (role == OculumCombatAbilityRole.support &&
                    planarState['mechaExplosion'] is Map)
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(dialog);
                      unawaited(showMechaExplosionEscape());
                    },
                    child: const Text('Fuga dall’esplosione del mecha'),
                  ),
                if (readIntValue(planarState['scostuRifleAmmo']) > 0)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.gps_fixed),
                    label: Text(
                      '${planarState['scostuRifleHolstered'] == true ? 'Impugna' : 'Riponi'} fucile · ${planarState['scostuRifleAmmo']} colpi',
                    ),
                    onPressed: () {
                      setState(
                        () => planarState['scostuRifleHolstered'] =
                            planarState['scostuRifleHolstered'] != true,
                      );
                      Navigator.pop(dialog);
                      programmaSalvataggio();
                    },
                  ),
                if (rabbitHatReady &&
                    (role == OculumCombatAbilityRole.attack ||
                        role == OculumCombatAbilityRole.support)) ...[
                  Text(
                    'Cappello · ${const ['Instabile', 'Stabile', 'Perfetto'][readIntValue(planarState['rabbitHatStage']) - 1]}',
                  ),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(dialog);
                      unawaited(useRabbitHat(release: true));
                    },
                    child: const Text('Lancia · incluso nell’Azione'),
                  ),
                  if (readIntValue(planarState['rabbitHatStage']) < 3) ...[
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(dialog);
                        unawaited(useRabbitHat(charge: true));
                      },
                      child: const Text('Carica ancora · una Azione'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(dialog);
                        unawaited(useRabbitHat(charge: true, release: true));
                      },
                      child: const Text('Carica e lancia · una sola Azione'),
                    ),
                  ],
                ],
                if (planarState['rabbitChains'] == true &&
                    role == OculumCombatAbilityRole.support)
                  for (final id in ['forza', 'riflessi'])
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(dialog);
                        unawaited(escapeRabbitChains(id));
                      },
                      child: Text('Liberati dalle catene · $id'),
                    ),
                if (role == OculumCombatAbilityRole.support &&
                    readIntValue(planarState['oblivionMemoryStage']) > 0)
                  for (final stat in hiddenEyeStats.where(
                    (s) => const {
                      'resistenza',
                      'canalizzazione',
                      'memoria',
                      'controllo_corporeo',
                      'crepa',
                    }.contains(s.id),
                  ))
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(dialog);
                        unawaited(controlOblivionMemory(stat.id));
                      },
                      icon: const Icon(Icons.psychology),
                      label: Text(
                        'Controlla Oblio · ${stat.nome} · stadio ${planarState['oblivionMemoryStage']}/5',
                      ),
                    ),
                if (role == OculumCombatAbilityRole.support &&
                    ownsMeccanio(sheetTagAt(schedaCorrente)))
                  OutlinedButton.icon(
                    onPressed: canUseMeccanioEmpathy
                        ? () {
                            Navigator.pop(dialog);
                            unawaited(useMeccanioEmpathy());
                          }
                        : null,
                    icon: const Icon(Icons.favorite_outline),
                    label: Text(
                      canUseMeccanioEmpathy
                          ? 'Empatia · riduci il rifiuto comandi'
                          : 'Empatia · recupera con un riposo',
                    ),
                  ),
                if (role == OculumCombatAbilityRole.support &&
                    ownsMeccanio(sheetTagAt(schedaCorrente)))
                  OutlinedButton.icon(
                    onPressed: canUseMeccanioEmpathy
                        ? () {
                            Navigator.pop(dialog);
                            unawaited(useMeccanioEmpathy(deception: true));
                          }
                        : null,
                    icon: const Icon(Icons.theater_comedy_outlined),
                    label: const Text(
                      'Inganno · stesso uso di Empatia · dado <12: +10% rifiuto',
                    ),
                  ),
                if (role == OculumCombatAbilityRole.support &&
                    !ownsMeccanio(sheetTagAt(schedaCorrente)) &&
                    schedePersonaggio.any(
                      (s) =>
                          isMeccanioBookId(
                            '${s['monsterBookSourceId'] ?? ''}',
                          ) &&
                          '${s['meccanioOwnerTag'] ?? ''}'.isEmpty,
                    ))
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(dialog);
                      unawaited(tryTameMeccanio());
                    },
                    icon: const Icon(Icons.build_outlined),
                    label: const Text('Meccanica · addestra Meccanio'),
                  ),
                if (role == OculumCombatAbilityRole.support)
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(dialog);
                      unawaited(parasiteMedicineTreatment());
                    },
                    icon: const Icon(Icons.healing),
                    label: const Text('Medicina · cura infestazione'),
                  ),
                if (feralisFuryActive)
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(dialog);
                      stopFeralisFury();
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Termina Furia · gratuito'),
                  ),
                if (role == OculumCombatAbilityRole.support && haPermessiMaster)
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(dialog);
                      unawaited(createLavastrelloNest());
                    },
                    icon: const Icon(Icons.volcano_outlined),
                    label: const Text('Crea tana Lavastrello · 5 uscite'),
                  ),
                if (role == OculumCombatAbilityRole.support &&
                    knowsLavastrelloNest)
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(dialog);
                      unawaited(searchLavastrelloNest());
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('Cerca tana · Percezione con Vantaggio'),
                  ),
                combatAbilityQuickBar(
                  onlyRole: role,
                  onChoose: (action) => Navigator.pop(dialog, action),
                ),
                if (role == OculumCombatAbilityRole.defense)
                  defenseRollControls(refresh, origin),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: Text(t('Chiudi', 'Close')),
            ),
          ],
        ),
      ),
    );
    if (mounted && selected != null && currentSheetScrollId() == origin) {
      selected();
    }
  }

  Widget combatAbilityQuickBar({
    OculumCombatAbilityRole? onlyRole,
    ValueChanged<VoidCallback>? onChoose,
  }) {
    synchronizeFightStartCooldowns();
    Set<OculumCombatAbilityRole> rolesFor(
      Iterable<OculumStructuredEffect> effects, {
      String explicitType = '',
    }) => oculumCombatAbilityRoles(
      effects,
      explicitType: explicitType,
      variables: formulaValueContext(),
    );
    final entries =
        <
          ({
            String name,
            Set<OculumCombatAbilityRole> roles,
            bool enabled,
            Color color,
            String hint,
            VoidCallback use,
            VoidCallback? details,
          })
        >[];
    if (!currentCombatIsActive() &&
        namedStructuredCooldowns().any(
          (entry) =>
              !entry.cooldown.startsReady &&
              entry.cooldown.amount > 0 &&
              oculumTurnUnit(entry.cooldown.unit) == 'turni',
        )) {
      entries.add((
        name: 'Prepara ricariche iniziali',
        roles: {OculumCombatAbilityRole.support},
        color: eyePupilGlowColor,
        enabled: true,
        hint:
            'Seleziona le capacità da preparare fuori battaglia: 6 secondi per turno, con conto alla rovescia.',
        details: null,
        use: () => unawaited(showFightStartPreparations()),
      ));
    }
    if (onlyRole != null) {
      final attack = onlyRole == OculumCombatAbilityRole.attack;
      final support = onlyRole == OculumCombatAbilityRole.support;
      if (attack &&
          (onlineCombatTokens().isNotEmpty || currentCombatIsActive())) {
        entries.add((
          name: 'Bersaglio del fight',
          roles: {onlyRole},
          color: eyePupilGlowColor,
          enabled: true,
          hint: 'Scegli il bersaglio e il tiro nel fight della tua scheda.',
          details: null,
          use: () => unawaited(planOnlineAttack()),
        ));
      }
      entries.add((
        name: support
            ? t('Aiuta compagno', 'Help ally')
            : '${attack ? 'VC' : 'CM'} +${attack ? vc() : cm()}',
        roles: {onlyRole},
        color: support
            ? primaryColor
            : attack
            ? Colors.redAccent
            : Colors.blueAccent,
        enabled: true,
        hint: support ? 'Tiro di aiuto compagno' : 'Tiro ordinario',
        details: null,
        use: () {
          if (support) {
            unawaited(tiraAiutaCompagno());
          } else {
            unawaited(useCombatRoll(onlyRole));
          }
        },
      ));
      if (support) {
        entries.add((
          name: 'Cura · valore concordato',
          roles: {onlyRole},
          color: statFormulaColor('resilienza'),
          enabled: true,
          hint:
              'Applica una cura già determinata con il Master, senza un nuovo tiro.',
          details: null,
          use: () => unawaited(manualPartyHealing()),
        ));
      }
      final allowed = switch (onlyRole) {
        OculumCombatAbilityRole.attack => const {
          'schianto',
          'forza',
          'riflessi',
          'manifestazione_potere',
          'strategia',
          'precisione',
        },
        OculumCombatAbilityRole.defense => combatDefenseRollIds,
        OculumCombatAbilityRole.support => {
          if (!isMeccanio) 'medicina',
          if (meccanioRepairTargets().isNotEmpty) 'meccanica',
          if (currentCombatIsActive())
            for (final stat in hiddenEyeStats)
              if (const {'concentrazione', 'adattamento'}.contains(stat.id) &&
                  hiddenEyeTotal(stat) >= 10)
                stat.id,
        },
      };
      for (final stat in hiddenEyeStats.where(
        (s) => oculumCombatSubtraitSelectable(s) && allowed.contains(s.id),
      )) {
        entries.add((
          name:
              '${stat.nome} +${hiddenEyeTotal(stat) + hiddenEyeStatRollQuickBonus(stat) + tiroGlobaleBonus()}',
          roles: {onlyRole},
          color: hiddenEyeStatIdentityColor(stat),
          enabled: true,
          hint: const {'concentrazione', 'adattamento'}.contains(stat.id)
              ? 'Utility di combattimento: attiva il beneficio al prossimo momento utile.'
              : 'Tiro alternativo: descrivi e motiva come lo usi.',
          details: () => showCombatSubtraitDetails(stat, onlyRole),
          use: () => unawaited(useCombatRoll(onlyRole, stat: stat)),
        ));
      }
    }
    for (final title in {...titoli, ...trattiRazziali}) {
      void addTitleSkill(TitleExtraSkillEntry? extra) {
        final text = extra?.descrizione ?? title.skill;
        final configured = extra?.effects ?? title.skillEffects;
        if ((text.trim().isEmpty && configured.isEmpty) ||
            RegExp(r'^\s*passiva\b', caseSensitive: false).hasMatch(text)) {
          return;
        }
        final effects = configured.isNotEmpty
            ? configured
            : oculumParseAbilityMechanics(
                text,
                subtraits: hiddenEyeStats,
              ).effects;
        final cost = extra?.cost ?? title.skillCost;
        final cooldown =
            extra?.cooldown ?? (extra == null ? title.skillCooldown : null);
        if (onlyRole != null && cooldown?.ready == false) return;
        final name = extra == null
            ? title.nome
            : '${extra.nome.trim().isEmpty ? 'Skill extra' : extra.nome} · ${title.nome}';
        final unresolvedRequirement = oculumCombatTextHasUnresolvedRequirement(
          text,
        );
        entries.add((
          name: '$name · Titolo',
          roles: rolesFor(
            effects,
            explicitType: extra?.combatRole ?? title.skillCombatRole,
          ),
          color: combatAbilityResourceColor([
            cost?.resource ??
                oculumParseAbilityCost(text)?.resource ??
                'nessuna',
          ]),
          enabled:
              (cooldown?.ready ?? true) &&
              !unresolvedRequirement &&
              combatAbilityCostAvailable(cost, text),
          hint:
              '${extra?.descrizione ?? title.skill}${cooldown?.ready == false ? '\nRicarica: ${cooldown!.remaining} ${cooldown.unit}' : ''}',
          details: () => showCombatAbilityDetails(
            name: '$name · Titolo',
            description: text,
            color: combatAbilityResourceColor([
              cost?.resource ??
                  oculumParseAbilityCost(text)?.resource ??
                  'nessuna',
            ]),
            effects: effects,
            cost: cost == null
                ? ''
                : '${cost.minimum}/${cost.maximum} ${cost.resource}',
            cooldown: cooldown == null
                ? ''
                : '${cooldown.remaining} ${cooldown.unit}',
            locked: oculumCombatTextHasUnresolvedRequirement(text),
          ),
          use: () => usaSkillTitolo(title, skillExtra: extra),
        ));
      }

      addTitleSkill(null);
      for (final extra in title.skillExtra) {
        addTitleSkill(extra);
      }
      void addTitleOpen(TitleOpenEntry? extra) {
        if (extra?.usedSinceLongRest ?? title.openUsedSinceLongRest) return;
        final name = extra?.nome ?? title.openName;
        final description =
            '${extra?.descrizione ?? title.openDescription}\n${extra?.openBuff ?? title.openBuff}';
        final skill = extra?.openSkill ?? title.openSkill;
        final effects = extra?.effects ?? title.openEffects;
        if (name.trim().isEmpty &&
            description.trim().isEmpty &&
            skill.trim().isEmpty &&
            effects.isEmpty) {
          return;
        }
        final active = extra?.attiva ?? title.openAttiva;
        entries.add((
          name:
              '${active ? 'Chiudi' : 'Apri'} ${name.trim().isEmpty ? title.nome : name} · Titolo',
          roles: rolesFor(
            effects.isEmpty
                ? oculumParseAbilityMechanics(
                    '$description $skill',
                    subtraits: hiddenEyeStats,
                  ).effects
                : effects,
            explicitType: extra?.combatRole ?? title.openCombatRole,
          ),
          color: statFormulaColor('oculum'),
          enabled:
              title.evoluto &&
              !oculumCombatTextHasUnresolvedRequirement('$description\n$skill'),
          hint: '$description\n$skill',
          details: () => showCombatAbilityDetails(
            name: name,
            description: '$description\n$skill',
            color: eyePupilGlowColor,
            effects: effects.isEmpty
                ? oculumResolveAbilityEffects(
                    const [],
                    '$description\n$skill',
                    subtraits: hiddenEyeStats,
                  )
                : effects,
            locked: oculumCombatTextHasUnresolvedRequirement(
              '$description\n$skill',
            ),
          ),
          use: () => usaOpen(title, openExtra: extra),
        ));
      }

      addTitleOpen(null);
      for (final extra in title.openExtra) {
        addTitleOpen(extra);
      }
    }
    for (final skill in skills.where((s) => s.equipaggiata && !s.passiva)) {
      skill.ensureForms();
      final forms = skill.forme
          .where((f) => !f.tipo.toLowerCase().contains('passiv'))
          .toList();
      if (forms.isEmpty) continue;
      final levelForms = forms
          .where(
            (f) =>
                (int.tryParse(f.livello) ?? 0) <=
                leggiNumero(livelloController),
          )
          .toList();
      if (onlyRole != null &&
          levelForms.isNotEmpty &&
          levelForms.every((f) => f.cooldownStrutturato?.ready == false)) {
        continue;
      }
      final allFormsLocked = forms.every(
        (form) => oculumCombatTextHasUnresolvedRequirement(
          '${form.descrizione}\n${form.effetto}\n${form.buff}\n${form.danni}\n${form.cura}\n${form.difesa}',
        ),
      );
      final roles = <OculumCombatAbilityRole>{
        for (final form in forms)
          ...rolesFor(
            oculumResolveAbilityEffects(
              form.effettiStrutturati,
              '${form.descrizione}\n${form.effetto}\n${form.buff}\n${form.danni}\n${form.cura}\n${form.difesa}',
              subtraits: hiddenEyeStats,
              investedOculum: true,
            ),
            explicitType: form.tipo,
          ),
      };
      entries.add((
        name: skill.nome,
        roles: roles,
        color: combatAbilityResourceColor(
          forms.map(
            (f) =>
                f.costoStrutturato?.resource ??
                oculumParseAbilityCost(f.costo)?.resource ??
                f.costo,
          ),
        ),
        enabled: forms.any(combatNaturalFormAvailable),
        hint: 'Skill · scegli la forma e conferma il costo',
        details: () => showCombatAbilityDetails(
          name: skill.nome,
          description: forms
              .map(
                (form) =>
                    '${artLevelRoman(readIntValue(form.livello))} · ${form.descrizione}',
              )
              .join('\n\n'),
          color: combatAbilityResourceColor(
            forms.map((form) => form.costoStrutturato?.resource ?? form.costo),
          ),
          effects: forms.expand(
            (form) => oculumResolveAbilityEffects(
              form.effettiStrutturati,
              '${form.descrizione}\n${form.effetto}\n${form.buff}\n${form.danni}\n${form.cura}\n${form.difesa}',
              subtraits: hiddenEyeStats,
              investedOculum: true,
            ),
          ),
          locked: allFormsLocked,
        ),
        use: () => chooseCombatAbilityForm(natural: skill),
      ));
    }
    for (final art in arti) {
      for (final skill in art.skills) {
        final eligibleForms = [
          for (var f = 1; f <= artMaxLevel(art); f++)
            if (leggiNumero(livelloController) >=
                (int.tryParse(
                      RegExp(
                            r'Richiede livello\s+(\d+)',
                            caseSensitive: false,
                          ).firstMatch(skill.testoEvoluzione(f))?.group(1) ??
                          '',
                    ) ??
                    0))
              f,
        ];
        if (onlyRole != null &&
            eligibleForms.isNotEmpty &&
            eligibleForms.every(
              (f) => !skill.cooldownPerLivello[f - 1].ready,
            )) {
          continue;
        }
        if (skill.tipiPerLivello
            .take(3)
            .every((t) => t.toLowerCase().contains('passiv'))) {
          continue;
        }
        final roles = <OculumCombatAbilityRole>{
          for (var form = 1; form <= artMaxLevel(art); form++)
            ...rolesFor(
              oculumResolveAbilityEffects(
                skill.effettiEvoluzione(form),
                skill.testoEvoluzione(form),
                subtraits: hiddenEyeStats,
                investedOculum: true,
              ),
              explicitType: skill.tipoPerLivello(form),
            ),
        };
        final texts = [
          for (var form = 1; form <= artMaxLevel(art); form++)
            skill.testoEvoluzione(form),
        ];
        final allFormsLocked = texts.every(
          oculumCombatTextHasUnresolvedRequirement,
        );
        entries.add((
          name: '${skill.nome} · ${art.nome}',
          roles: roles,
          color: combatAbilityResourceColor([
            for (var form = 1; form <= artMaxLevel(art); form++)
              effectiveArtCostResource(art, skill, form),
          ]),
          enabled:
              art.sbloccata &&
              art.inUso &&
              List.generate(
                artMaxLevel(art),
                (i) => i + 1,
              ).any((form) => combatArtFormAvailable(art, skill, form)),
          hint: art.inUso
              ? 'Art · scegli la forma e conferma il costo'
              : 'Seleziona prima questa Art nella scheda',
          details: () => showCombatAbilityDetails(
            name: '${skill.nome} · ${art.nome}',
            description: [
              for (var form = 1; form <= artMaxLevel(art); form++)
                '${artLevelRoman(form)} · ${skill.testoEvoluzione(form)}',
            ].join('\n\n'),
            color: combatAbilityResourceColor([
              for (var form = 1; form <= artMaxLevel(art); form++)
                effectiveArtCostResource(art, skill, form),
            ]),
            effects: [
              for (var form = 1; form <= artMaxLevel(art); form++)
                ...oculumResolveAbilityEffects(
                  skill.effettiEvoluzione(form),
                  skill.testoEvoluzione(form),
                  subtraits: hiddenEyeStats,
                  investedOculum: true,
                ),
            ],
            locked: allFormsLocked,
          ),
          use: () => chooseCombatAbilityForm(art: art, artSkill: skill),
        ));
      }
      if (art.openName.trim().isNotEmpty) {
        final roles = rolesFor([
          ...oculumResolveAbilityEffects(
            art.openDescriptionEffects,
            art.openDescription,
            subtraits: hiddenEyeStats,
          ),
          ...oculumResolveAbilityEffects(
            art.openSkillEffects,
            art.openSkill,
            subtraits: hiddenEyeStats,
          ),
          ...oculumResolveAbilityEffects(
            art.openBuffEffects,
            art.openBuff,
            subtraits: hiddenEyeStats,
          ),
        ], explicitType: art.openSkillType);
        if (!art.openUsedSinceLongRest &&
            (onlyRole == null ||
                art.openAttiva ||
                ((art.openDescriptionCooldown?.ready ?? true) &&
                    (art.openBuffCooldown?.ready ?? true)))) {
          entries.add((
            name: '${art.openAttiva ? 'Chiudi' : 'Apri'} ${art.openName}',
            roles: roles,
            color: eyePupilGlowColor,
            enabled:
                artOpenSbloccata(art) &&
                art.inUso &&
                art.switchPhase.isEmpty &&
                (art.openDescriptionCooldown?.ready ?? true) &&
                (art.openBuffCooldown?.ready ?? true) &&
                (oculumRecognizedArtKind(art) == 'emblem' ||
                    oculumArtCanActivate(
                      art.integritaCorrente,
                      cost: artUseCost(oculumArtActivationCost),
                    )),
            hint: 'Open · usa requisiti e costi originali',
            use: () => usaOpenArt(arti.indexOf(art)),
            details: null,
          ));
        }
        if ((art.openSkill.trim().isNotEmpty ||
                art.openSkillEffects.isNotEmpty) &&
            (onlyRole == null || (art.openSkillCooldown?.ready ?? true))) {
          entries.add((
            name: '${art.openName} · Skill Open',
            roles: roles,
            color: eyePupilGlowColor,
            enabled:
                artOpenSbloccata(art) &&
                (art.openSkillCooldown?.ready ?? true) &&
                combatAbilityCostAvailable(null, art.openSkill),
            hint: 'Skill Open · cooldown originale',
            details: null,
            use: () => usaSkillOpenMostro(arti.indexOf(art)),
          ));
        }
      }
    }
    for (final item in inventario.where(
      (item) =>
          item.quantita > 0 &&
          item.craftData['scroll'] is! Map &&
          isMerchantConsumable(item),
    )) {
      entries.add((
        name: 'Item · ${item.nome} ×${item.quantita}',
        roles: oculumInventoryItemCombatRoles(item),
        color: statFormulaColor('resilienza'),
        enabled: canEquipInventoryItem(item),
        hint: '${item.note}\nConsumabile dall’inventario',
        details: item.craftData['summoningEmblem'] is Map
            ? () => editSummoningEmblem(item)
            : null,
        use: () => unawaited(useMerchantConsumable(item)),
      ));
    }
    for (final item in inventario.where(
      (item) => item.quantita > 0 && item.craftData['scroll'] is Map,
    )) {
      final scroll = Map<String, dynamic>.from(item.craftData['scroll'] as Map);
      final effects = oculumScrollCombatEffects(scroll);
      entries.add((
        name:
            'Item · ${scroll['name'] ?? item.nome} · Pergamena ×${item.quantita}',
        roles: oculumScrollCombatRoles(scroll, effects),
        color: statFormulaColor('volonta'),
        enabled:
            canEquipInventoryItem(item) &&
            artSkillCostResourceAvailable('volonta') >=
                oculumScrollWillCost(readIntValue(scroll['grade'])),
        hint:
            '${scroll['description'] ?? item.note}\nMonouso · costo ${oculumScrollWillCost(readIntValue(scroll['grade']))} Volontà',
        details: () => showCombatAbilityDetails(
          name: '${scroll['name'] ?? item.nome}',
          description: '${scroll['description'] ?? item.note}',
          color: statFormulaColor('volonta'),
          effects: effects,
          cost:
              '${oculumScrollWillCost(readIntValue(scroll['grade']))} Volontà',
        ),
        use: () => unawaited(useScrollAbility(scroll, item: item)),
      ));
    }
    for (final item in inventario.where(
      (i) =>
          i.equipaggiata &&
          i.quantita > 0 &&
          (i.ability != null || i.titleAbility != null),
    )) {
      for (final ability in oculumAllEquipmentAbilities(item)) {
        if (oculumItemTitleAbilities(item).contains(ability) &&
            !oculumItemTitleEvolutionReady(item)) {
          continue;
        }
        ability.ensureForms();
        for (final (index, form) in ability.forme.indexed) {
          if (onlyRole != null && form.cooldownStrutturato?.ready == false) {
            continue;
          }
          if (form.tipo.toLowerCase().contains('passiv')) continue;
          final effects = form.effettiStrutturati.isNotEmpty
              ? form.effettiStrutturati
              : oculumParseStructuredEffectsFromText(
                  form.descrizione,
                  subtraits: hiddenEyeStats,
                ).effects;
          final roles = rolesFor(effects, explicitType: form.tipo);
          final itemSkillLevelReady = oculumEquipmentSkillLevelAvailable(
            characterLevel: leggiNumero(livelloController),
            itemLevel: oculumEquipmentSkillItemLevel(item, form),
            formLevel: form.livello,
          );
          final requiredEquipmentLevel = oculumEquipmentRequiredSkillLevel(
            itemLevel: oculumEquipmentSkillItemLevel(item, form),
            formLevel: form.livello,
          );
          entries.add((
            name: '${ability.nome} ${index + 1} · ${item.nome}',
            roles: roles,
            color: combatAbilityResourceColor([
              form.costoStrutturato?.resource ?? form.costo,
            ]),
            enabled:
                canEquipInventoryItem(item) &&
                itemTitleFormAvailable(item, form) &&
                combatNaturalFormAvailable(form) &&
                (form.cooldownStrutturato?.ready ?? true) &&
                oculumEquipmentSkillLevelAvailable(
                  characterLevel: leggiNumero(livelloController),
                  itemLevel: oculumEquipmentSkillItemLevel(item, form),
                  formLevel: form.livello,
                ),
            hint:
                '${itemSkillLevelReady ? '' : 'Richiede livello $requiredEquipmentLevel dell’oggetto/personaggio.\n'}${item.titleAbility?.forme.contains(form) == true ? '${oculumItemTitleSummary(item)}\n' : ''}${form.descrizione}',
            details: () => showCombatAbilityDetails(
              name: '${ability.nome} ${index + 1}',
              description: form.descrizione,
              color: combatAbilityResourceColor([
                form.costoStrutturato?.resource ?? form.costo,
              ]),
              effects: effects,
              cost: form.costo,
              cooldown: form.cooldownStrutturato?.ready == false
                  ? '${form.cooldownStrutturato!.remaining} ${form.cooldownStrutturato!.unit}'
                  : '',
              locked:
                  !itemSkillLevelReady ||
                  oculumCombatTextHasUnresolvedRequirement(form.descrizione),
            ),
            use: () => unawaited(
              useEquipmentQuickAbility(
                item,
                form,
                onlyRole ??
                    oculumCombatAbilityRole(effects, explicitType: form.tipo),
              ),
            ),
          ));
        }
      }
    }
    final activeSheet =
        schedaCorrente >= 0 && schedaCorrente < schedePersonaggio.length
        ? schedePersonaggio[schedaCorrente]
        : const <String, dynamic>{};
    final hasPatalpaSummon =
        '${activeSheet['monsterBookSourceId'] ?? ''}' == 'patalpa_dolce' ||
        inventario.any(
          (item) =>
              item.nome.toLowerCase().contains('armatura del patalpa') &&
              item.quantita > 0,
        );
    if (hasPatalpaSummon) {
      final fightsRemaining = max(
        0,
        readIntValue(activeSheet['patalpaSummonCooldownFightsRemaining']),
      );
      entries.add((
        name: 'CD ripristinata',
        roles: {OculumCombatAbilityRole.support},
        color: eyePupilGlowColor,
        enabled: true,
        hint:
            'Richiamo del Patalpa · ${fightsRemaining == 0 ? 'pronto' : 'cooldown: $fightsRemaining fight'}. Premi fuori da uno scontro per ripristinare la CD. Disponibile online e offline.',
        details: null,
        use: restorePatalpaSummonCooldown,
      ));
    }
    if (entries.isEmpty) return const SizedBox.shrink();
    Widget buildOptions(BuildContext context, BoxConstraints constraints) {
      Widget group(OculumCombatAbilityRole role) {
        final subset = entries
            .where((e) => e.enabled && e.roles.contains(role))
            .toList();
        final color = switch (role) {
          OculumCombatAbilityRole.attack => eyePupilGlowColor,
          OculumCombatAbilityRole.defense => secondaryColor,
          OculumCombatAbilityRole.support => primaryColor,
        };
        final title = switch (role) {
          OculumCombatAbilityRole.attack => 'Attacco',
          OculumCombatAbilityRole.defense => 'Difesa',
          OculumCombatAbilityRole.support => 'Supporto e utilità',
        };
        final options = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in subset)
              Tooltip(
                message:
                    '${e.name}\n${e.hint}\nTieni premuto o clicca con il tasto destro per i dettagli.',
                child: GestureDetector(
                  onLongPress: () {
                    final detail = e.details;
                    if (detail != null) {
                      detail();
                      return;
                    }
                    showCombatAbilityDetails(
                      name: e.name,
                      description: e.hint,
                      color: e.color,
                      effects: oculumResolveAbilityEffects(
                        const [],
                        e.hint,
                        subtraits: hiddenEyeStats,
                        investedOculum: true,
                      ),
                      locked: oculumCombatTextHasUnresolvedRequirement(e.hint),
                    );
                  },
                  onSecondaryTap: () {
                    final detail = e.details;
                    if (detail != null) {
                      detail();
                      return;
                    }
                    showCombatAbilityDetails(
                      name: e.name,
                      description: e.hint,
                      color: e.color,
                      effects: oculumResolveAbilityEffects(
                        const [],
                        e.hint,
                        subtraits: hiddenEyeStats,
                        investedOculum: true,
                      ),
                      locked: oculumCombatTextHasUnresolvedRequirement(e.hint),
                    );
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 132,
                      maxWidth: 230,
                      minHeight: 48,
                    ),
                    child: OutlinedButton.icon(
                      onPressed: e.enabled
                          ? () {
                              if (onChoose != null) {
                                onChoose(e.use);
                              } else {
                                e.use();
                              }
                            }
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: e.color,
                        side: BorderSide(color: e.color.withValues(alpha: .55)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                      ),
                      icon: Icon(switch (role) {
                        OculumCombatAbilityRole.attack => Icons.casino_outlined,
                        OculumCombatAbilityRole.defense =>
                          Icons.shield_outlined,
                        OculumCombatAbilityRole.support =>
                          Icons.volunteer_activism_outlined,
                      }, size: 18),
                      label: Text(
                        e.name,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
        if (onlyRole != null) return options;
        return ExpansionTile(
          key: PageStorageKey('combat_abilities_${role.name}'),
          title: Text(
            '$title · ${subset.length}',
            style: TextStyle(color: color),
          ),
          childrenPadding: const EdgeInsets.all(8),
          children: [options],
        );
      }

      if (onlyRole != null) return group(onlyRole);
      if (constraints.maxWidth < 900) {
        return Column(
          children: [
            for (final role in OculumCombatAbilityRole.values) group(role),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final role in OculumCombatAbilityRole.values)
            Expanded(child: group(role)),
        ],
      );
    }

    if (onlyRole != null) return buildOptions(context, const BoxConstraints());
    return LayoutBuilder(builder: buildOptions);
  }
}
