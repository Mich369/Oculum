part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member, unused_element

extension _OculumHomeQuickConditions on _OculumHomePageState {
  Set<OculumConditionTarget> conditionTargetsFor(
    OculumConditionInstance instance,
  ) {
    final targets = <OculumConditionTarget>{
      ...?oculumConditionDefinition(instance.conditionType)?.affectedTargets,
    };
    final savedTargets = instance.metadata['affectedTargets'];
    if (savedTargets is Iterable) {
      for (final raw in savedTargets) {
        final name = '$raw';
        for (final target in OculumConditionTarget.values) {
          if (target.name == name) targets.add(target);
        }
      }
    }
    return targets;
  }

  Set<OculumConditionTarget> allActiveConditionTargets() =>
      activeConditions.fold<Set<OculumConditionTarget>>(
        <OculumConditionTarget>{},
        (targets, instance) => targets..addAll(conditionTargetsFor(instance)),
      );

  void notifyConditionsChanged([
    Iterable<OculumConditionTarget>? affectedTargets,
  ]) {
    conditionsRevision.value++;
    final targets = affectedTargets?.toSet() ?? allActiveConditionTargets();
    for (final target in targets) {
      final notifier = conditionTargetRevisions[target];
      if (notifier != null) notifier.value++;
    }
  }

  ValueNotifier<int> conditionRevisionFor(OculumConditionTarget target) =>
      conditionTargetRevisions[target]!;

  String conditionName(OculumConditionInstance instance) {
    final definition = oculumConditionDefinition(instance.conditionType);
    final override = conditionDefinitionOverrides[instance.conditionType];
    final overrideName = t(
      '${override?['nameIt'] ?? ''}',
      '${override?['nameEn'] ?? override?['nameIt'] ?? ''}',
    ).trim();
    if (overrideName.isNotEmpty) return overrideName;
    return definition == null
        ? '${instance.metadata['nameIt'] ?? instance.metadata['name'] ?? t('Personalizzata', 'Custom')}'
        : t(definition.nameIt, definition.nameEn);
  }

  String conditionLabel(OculumConditionInstance instance) {
    final definition = oculumConditionDefinition(instance.conditionType);
    final suffix = (definition?.maxStage ?? 1) > 1
        ? ' ${oculumRomanStage(instance.stage)}'
        : '';
    return '${conditionName(instance)}$suffix';
  }

  List<OculumConditionInstance> conditionsAffecting(
    OculumConditionTarget target,
  ) => activeConditions
      .where((instance) => conditionTargetsFor(instance).contains(target))
      .toList(growable: false);

  List<String> activeSpecialStatesAffecting(OculumConditionTarget target) {
    final entries = <String>[];
    final statOrRoll = <OculumConditionTarget>{
      OculumConditionTarget.resilienza,
      OculumConditionTarget.volonta,
      OculumConditionTarget.materia,
      OculumConditionTarget.oculum,
      OculumConditionTarget.tiri,
    }.contains(target);
    if (sottoStress && statOrRoll) {
      entries.add(
        t(
          'Sotto stress: consumo ripetuto della statistica puo generare Cenere.',
          'Under stress: repeated stat spending can generate Ash.',
        ),
      );
    }
    if (consumoElevato && statOrRoll) {
      entries.add(
        t(
          'Consumo elevato: ogni tiro valido consuma 1 punto della statistica associata.',
          'High consumption: each valid roll spends 1 point from its linked stat.',
        ),
      );
    }
    if (oculumAddormentato &&
        (target == OculumConditionTarget.oculum ||
            target == OculumConditionTarget.recupero)) {
      entries.add(
        t(
          'Oculum addormentato: recuperi dimezzati per difetto.',
          'Sleeping Oculum: recovery is halved, rounded down.',
        ),
      );
    }
    return entries;
  }

  String conditionTargetLabel(OculumConditionTarget target) => switch (target) {
    OculumConditionTarget.resilienza => t('Resilienza', 'Resilience'),
    OculumConditionTarget.volonta => t('Volonta', 'Will'),
    OculumConditionTarget.materia => 'Materia',
    OculumConditionTarget.oculum => 'Oculum',
    OculumConditionTarget.hp => 'HP',
    OculumConditionTarget.scudo => t('Scudo', 'Shield'),
    OculumConditionTarget.scudoOculum => 'Scudo Oculum',
    OculumConditionTarget.danno => t('Danno', 'Damage'),
    OculumConditionTarget.difesa => t('Difesa', 'Defense'),
    OculumConditionTarget.vc => 'VC',
    OculumConditionTarget.cm => 'CM',
    OculumConditionTarget.iniziativa => t('Iniziativa', 'Initiative'),
    OculumConditionTarget.movimento => t('Movimento', 'Movement'),
    OculumConditionTarget.tiri => t('Tiri', 'Rolls'),
    OculumConditionTarget.reazioni => t('Reazioni', 'Reactions'),
    OculumConditionTarget.recupero => t('Recupero', 'Recovery'),
    OculumConditionTarget.skill => 'Skill',
    OculumConditionTarget.art => 'Art',
    OculumConditionTarget.titoli => t('Titoli', 'Titles'),
    OculumConditionTarget.combattimento => t('Combattimento', 'Combat'),
  };

  OculumConditionTarget? conditionTargetForUiLabel(String rawLabel) {
    final label = cleanUiText(rawLabel).toLowerCase();
    if (label.contains('resilien')) return OculumConditionTarget.resilienza;
    if (label.contains('volont') || label == 'will') {
      return OculumConditionTarget.volonta;
    }
    if (label.contains('materia')) return OculumConditionTarget.materia;
    if (label.contains('schivata oculum') || label.contains('oculum dodge')) {
      return OculumConditionTarget.combattimento;
    }
    if (label.contains('scudo oculum')) {
      return OculumConditionTarget.scudoOculum;
    }
    if (label.contains('oculum')) return OculumConditionTarget.oculum;
    if (label == 'hp' || label.contains('vita')) {
      return OculumConditionTarget.hp;
    }
    if (label.contains('scudo') || label.contains('shield')) {
      return OculumConditionTarget.scudo;
    }
    if (label.contains('danno') || label.contains('damage')) {
      return OculumConditionTarget.danno;
    }
    if (label.contains('difesa') || label.contains('defense')) {
      return OculumConditionTarget.difesa;
    }
    if (label == 'vc' || label.contains('volonta combattiva')) {
      return OculumConditionTarget.vc;
    }
    if (label == 'cm' || label.contains('cerchio magico')) {
      return OculumConditionTarget.cm;
    }
    if (label.contains('iniziativa') || label.contains('initiative')) {
      return OculumConditionTarget.iniziativa;
    }
    if (label.contains('movimento') || label.contains('movement')) {
      return OculumConditionTarget.movimento;
    }
    if (label.contains('reazion') || label.contains('reaction')) {
      return OculumConditionTarget.reazioni;
    }
    if (label.contains('skill')) return OculumConditionTarget.skill;
    if (label == 'art' || label.contains(' arti')) {
      return OculumConditionTarget.art;
    }
    if (label.contains('titol') || label.contains('title')) {
      return OculumConditionTarget.titoli;
    }
    return null;
  }

  String currentConditionTargetValue(
    OculumConditionTarget target,
    String fallback,
  ) => switch (target) {
    OculumConditionTarget.resilienza => '${resilienzaTotale()}',
    OculumConditionTarget.volonta => '${volontaTotale()}',
    OculumConditionTarget.materia => '${materiaTotale()}',
    OculumConditionTarget.oculum => '${oculumTotale()}/${oculumMassimo()}',
    OculumConditionTarget.hp => '${hpCorrenti()}/${maxHp()}',
    OculumConditionTarget.scudo => '${scudo()}',
    OculumConditionTarget.scudoOculum => '${scudoOculum()}',
    OculumConditionTarget.danno => '${dannoTotale()}',
    OculumConditionTarget.difesa => '${difesa()}',
    OculumConditionTarget.vc => '${vc()}',
    OculumConditionTarget.cm => '${cm()}',
    OculumConditionTarget.iniziativa => '${iniziativa()}',
    OculumConditionTarget.movimento => '${movimento()}',
    OculumConditionTarget.reazioni => '${reazioniTotali()}',
    _ => fallback,
  };

  String conciseConditionEffect(
    OculumConditionInstance instance,
    OculumConditionTarget target,
  ) {
    final definition = oculumConditionDefinition(instance.conditionType);
    final positiveMultiplier = oculumPositiveConditionMultiplier(
      normalizedCampaignDifficulty(),
    );
    final rollModifier = definition?.rollModifierForStage(instance.stage) ?? 0;
    if (rollModifier != 0 &&
        <OculumConditionTarget>{
          OculumConditionTarget.resilienza,
          OculumConditionTarget.volonta,
          OculumConditionTarget.materia,
          OculumConditionTarget.oculum,
          OculumConditionTarget.tiri,
        }.contains(target)) {
      return '${rollModifier > 0 ? '+' : ''}$rollModifier ${t('al tiro', 'to roll')}';
    }
    switch (instance.conditionType) {
      case 'aumento_difficolta':
        if (target == OculumConditionTarget.vc ||
            target == OculumConditionTarget.cm) {
          return '${instance.stage * -3}';
        }
        if (target == OculumConditionTarget.scudo ||
            target == OculumConditionTarget.scudoOculum) {
          return '${t('Ricompensa Fight', 'Fight reward')}: ${instance.metadata['shieldReward'] ?? 0}';
        }
        return '+${instance.stage * 3}% ${t('danni ricevuti', 'incoming damage')}';
      case 'fortificato':
        return '+${(15 * positiveMultiplier).round()}% ${t('Difesa', 'Defense')}';
      case 'potenziato':
        return '+${(15 * positiveMultiplier).round()}% ${t('Danno', 'Damage')}';
      case 'indebolito':
        return '-20% ${t('Danno', 'Damage')}';
      case 'accelerato':
        return '+${(20 * positiveMultiplier).round()}% ${t('Movimento', 'Movement')}';
      case 'rallentato':
        return '-25% ${t('Movimento', 'Movement')}';
      case 'immobilizzato':
      case 'afferrato':
        return '${t('Movimento', 'Movement')} 0';
      case 'privo_reazioni':
        return '${t('Reazioni', 'Reactions')} 0';
      case 'stordito':
        if (target == OculumConditionTarget.reazioni) return '-1 Reazione';
      case 'veleno_putrido':
      case 'sanguinamento':
      case 'bruciatura':
        return '-${calculateConditionEffect(instance)} HP / tick';
    }
    final modifierMap = instance.metadata['modifiers'];
    if (modifierMap is Map && modifierMap[target.name] != null) {
      final value = readDoubleValue(modifierMap[target.name]);
      return '${value > 0 ? '+' : ''}${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}';
    }
    return '';
  }

  Widget conditionImpactIndicator({
    required OculumConditionTarget target,
    String? baseValue,
    String? permanentValue,
    String? temporaryValue,
    String? finalValue,
  }) {
    return ValueListenableBuilder<int>(
      valueListenable: conditionRevisionFor(target),
      builder: (context, revision, child) {
        final conditions = conditionsAffecting(target);
        final specialStates = activeSpecialStatesAffecting(target);
        if (conditions.isEmpty && specialStates.isEmpty) {
          return const SizedBox.shrink();
        }
        final tooltip = <String>[
          ...conditions.map((item) {
            final effect = conciseConditionEffect(item, target);
            return '${conditionLabel(item)}${effect.isEmpty ? '' : ': $effect'}';
          }),
          ...specialStates,
        ].join('\n');
        final badge = Tooltip(
          message: tooltip,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => showConditionImpactDialog(
              target: target,
              baseValue: baseValue,
              permanentValue: permanentValue,
              temporaryValue: temporaryValue,
              finalValue: finalValue,
            ),
            child: Container(
              constraints: const BoxConstraints(minHeight: 30),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tertiaryColor.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: tertiaryColor.withValues(alpha: .55)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt, size: 15, color: tertiaryColor),
                  const SizedBox(width: 3),
                  Text(
                    '${conditions.length + specialStates.length}',
                    style: TextStyle(
                      color: tertiaryColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onSecondaryTapDown: (_) =>
              showConditionDurationPickerForTarget(target),
          onLongPress: () => showConditionDurationPickerForTarget(target),
          child: badge,
        );
      },
    );
  }

  Future<void> showConditionDurationPickerForTarget(
    OculumConditionTarget target,
  ) async {
    final conditions = conditionsAffecting(target);
    if (conditions.isEmpty) return;
    OculumConditionInstance? selected;
    if (conditions.length == 1) {
      selected = conditions.single;
    } else {
      selected = await showDialog<OculumConditionInstance>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          title: Text(t('Scegli effetto', 'Choose effect')),
          children: [
            for (final instance in conditions)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, instance),
                child: ListTile(
                  leading: Icon(
                    oculumConditionDefinition(instance.conditionType)?.icon ??
                        Icons.tune,
                    color: tertiaryColor,
                  ),
                  title: Text(conditionLabel(instance)),
                  subtitle: Text(
                    instance.duration > 0
                        ? '${t('Turni', 'Turns')}: ${instance.duration}'
                        : t('Senza scadenza', 'No expiry'),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    if (selected != null && mounted) {
      await showConditionDurationEditor(selected);
    }
  }

  Future<void> showConditionDurationEditor(
    OculumConditionInstance instance,
  ) async {
    final controller = TextEditingController(text: '${instance.duration}');
    var durationType = instance.durationType;
    String? validationError;
    final result =
        await showDialog<
          ({
            int turns,
            String formula,
            int faces,
            bool criticalOne,
            bool criticalMax,
          })
        >(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(
                  '${conditionLabel(instance)} · ${t('Durata', 'Duration')}',
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<OculumConditionDurationType>(
                      initialValue: durationType,
                      items: const [
                        DropdownMenuItem(
                          value: OculumConditionDurationType.turns,
                          child: Text('Turni'),
                        ),
                        DropdownMenuItem(
                          value: OculumConditionDurationType.shortRest,
                          child: Text('Riposo breve'),
                        ),
                        DropdownMenuItem(
                          value: OculumConditionDurationType.longRest,
                          child: Text('Riposo lungo'),
                        ),
                        DropdownMenuItem(
                          value: OculumConditionDurationType.meal,
                          child: Text('Dopo pasto'),
                        ),
                        DropdownMenuItem(
                          value: OculumConditionDurationType.permanent,
                          child: Text('Senza scadenza'),
                        ),
                      ],
                      onChanged: (value) => setDialogState(
                        () => durationType = value ?? durationType,
                      ),
                    ),
                    if (durationType == OculumConditionDurationType.turns)
                      TextField(
                        controller: controller,
                        autofocus: true,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: t('Turni o dado', 'Turns or die'),
                          hintText: '3 · 1d10 · 2d6+1 turni',
                          errorText: validationError,
                        ),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(t('Annulla', 'Cancel')),
                  ),
                  FilledButton.icon(
                    icon: const Icon(Icons.casino),
                    onPressed: () {
                      if (durationType != OculumConditionDurationType.turns) {
                        Navigator.pop(dialogContext, (
                          turns: 1,
                          formula: '',
                          faces: 0,
                          criticalOne: false,
                          criticalMax: false,
                        ));
                        return;
                      }
                      final parsed = rollConditionDuration(controller.text);
                      if (parsed == null) {
                        setDialogState(() {
                          validationError = t(
                            'Usa un numero o un dado, es. 1d10.',
                            'Use a number or die, e.g. 1d10.',
                          );
                        });
                        return;
                      }
                      Navigator.pop(dialogContext, parsed);
                    },
                    label: Text(t('Applica', 'Apply')),
                  ),
                ],
              );
            },
          ),
        );
    controller.dispose();
    if (result == null) return;
    instance.duration = result.turns;
    instance.durationType = durationType;
    if (result.formula.isNotEmpty) {
      risultato = t(
        'Durata ${conditionLabel(instance)}: ${result.formula} = ${result.turns} turni.',
        '${conditionLabel(instance)} duration: ${result.formula} = ${result.turns} turns.',
      );
      aggiungiLog(risultato);
      mostraDadoCentrale(
        valore: '${result.turns}',
        criticoUno: result.criticalOne,
        criticoVenti: result.criticalMax,
        facce: result.faces,
      );
    }
    notifyConditionsChanged(conditionTargetsFor(instance));
    programmaSalvataggio(invalidateCaches: false);
  }

  ({int turns, String formula, int faces, bool criticalOne, bool criticalMax})?
  rollConditionDuration(String raw, {Random? random}) {
    final roller = random ?? Random.secure();
    return oculumRollConditionDuration(
      raw,
      nextInt: roller.nextInt,
      criticalModifier: criticalDieModifier,
    );
  }

  Widget conditionTargetScope({
    required OculumConditionTarget target,
    required Widget Function() builder,
  }) {
    return ValueListenableBuilder<int>(
      valueListenable: conditionRevisionFor(target),
      builder: (context, revision, child) => builder(),
    );
  }

  Future<void> showConditionImpactDialog({
    required OculumConditionTarget target,
    String? baseValue,
    String? permanentValue,
    String? temporaryValue,
    String? finalValue,
  }) async {
    final conditions = conditionsAffecting(target);
    final specialStates = activeSpecialStatesAffecting(target);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.bolt, color: tertiaryColor),
            const SizedBox(width: 8),
            Expanded(child: Text(conditionTargetLabel(target))),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (baseValue != null) Text('${t('Base', 'Base')}: $baseValue'),
                if (permanentValue != null)
                  Text('${t('Permanenti', 'Permanent')}: $permanentValue'),
                if (temporaryValue != null)
                  Text('${t('Temporanei', 'Temporary')}: $temporaryValue'),
                if (finalValue != null)
                  Text(
                    '${t('Finale usato', 'Effective final')}: $finalValue',
                    style: TextStyle(
                      color: tertiaryColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                if (baseValue != null || finalValue != null)
                  const Divider(height: 22),
                for (final instance in conditions) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      oculumConditionDefinition(instance.conditionType)?.icon ??
                          Icons.tune,
                      color: tertiaryColor,
                    ),
                    title: Text(conditionLabel(instance)),
                    subtitle: Text(
                      [
                        conciseConditionEffect(instance, target),
                        t(
                          oculumConditionDefinition(
                                instance.conditionType,
                              )?.descriptionIt ??
                              '${instance.metadata['description'] ?? ''}',
                          oculumConditionDefinition(
                                instance.conditionType,
                              )?.descriptionEn ??
                              '${instance.metadata['description'] ?? ''}',
                        ),
                      ].where((text) => text.trim().isNotEmpty).join('\n'),
                    ),
                  ),
                ],
                for (final state in specialStates)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.tune, color: tertiaryColor),
                    title: Text(state.split(':').first),
                    subtitle: Text(state),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              vaiAllaFunzione(
                page: _OculumHomePageState.quickConditionsPageIndex,
                logTitle: t('Condizioni veloci', 'Quick Conditions'),
              );
            },
            child: Text(t('Gestisci condizioni', 'Manage conditions')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t('Chiudi', 'Close')),
          ),
        ],
      ),
    );
  }

  OculumConditionInstance? getCondition(String type) {
    for (final condition in activeConditions) {
      if (condition.conditionType == type) return condition;
    }
    return null;
  }

  Map<String, dynamic>? conditionOverrideFor(String type) =>
      conditionDefinitionOverrides[type];

  OculumConditionDefinition? conditionDefinitionByVisibleName(String name) {
    final wanted = oculumNormalizeText(name).replaceAll(' ', '');
    for (final definition in oculumConditionCatalog) {
      final override = conditionOverrideFor(definition.id);
      final candidates = <String>{
        definition.id,
        definition.nameIt,
        definition.nameEn,
        '${override?['nameIt'] ?? ''}',
        '${override?['nameEn'] ?? ''}',
      };
      if (candidates.any(
        (candidate) =>
            oculumNormalizeText(candidate).replaceAll(' ', '') == wanted,
      )) {
        return definition;
      }
    }
    return null;
  }

  String conditionOverrideDurationFormula(String type, {String fallback = ''}) {
    final override = conditionOverrideFor(type);
    final byDifficulty = override?['durationByDifficulty'];
    if (byDifficulty is Map) {
      final exact = '${byDifficulty[normalizedCampaignDifficulty()] ?? ''}'
          .trim();
      if (exact.isNotEmpty) return exact;
    }
    final base = '${override?['durationFormula'] ?? ''}'.trim();
    return base.isEmpty ? fallback : base;
  }

  int? rollEffectDurationFormula(String formula) {
    if (formula.trim().isEmpty) return null;
    final rolled = rollConditionDuration(formula);
    if (rolled == null) return null;
    mostraDadoCentrale(
      valore: '${rolled.turns}',
      criticoUno: rolled.criticalOne,
      criticoVenti: rolled.criticalMax,
      facce: rolled.faces,
    );
    if (rolled.formula.isNotEmpty) {
      aggiungiLog(
        t(
          'Durata effetto ${rolled.formula} = ${rolled.turns} turni.',
          'Effect duration ${rolled.formula} = ${rolled.turns} turns.',
        ),
      );
    }
    return rolled.turns;
  }

  bool applyEffectCommand(
    OculumParsedEffectCommand command, {
    String source = '@effetto',
  }) {
    final definition = conditionDefinitionByVisibleName(command.name);
    if (definition != null) {
      final override = conditionOverrideFor(definition.id);
      final formula = command.durationFormula.trim().isNotEmpty
          ? command.durationFormula
          : conditionOverrideDurationFormula(definition.id);
      final rolledDuration = rollEffectDurationFormula(formula);
      return applyCondition(
        definition.id,
        duration: rolledDuration,
        source: source,
        metadata: <String, dynamic>{
          if (formula.isNotEmpty) 'durationFormula': formula,
          ...?override,
        },
      );
    }

    final wanted = oculumNormalizeText(command.name).replaceAll(' ', '');
    MapEntry<String, Map<String, dynamic>>? customEntry;
    for (final entry in conditionDefinitionOverrides.entries) {
      if (oculumConditionDefinition(entry.key) != null) continue;
      final visibleName = '${entry.value['nameIt'] ?? entry.key}';
      if (oculumNormalizeText(visibleName).replaceAll(' ', '') == wanted) {
        customEntry = entry;
        break;
      }
    }
    if (customEntry == null) return false;
    final template = customEntry.value;
    final formula = command.durationFormula.trim().isNotEmpty
        ? command.durationFormula
        : conditionOverrideDurationFormula(customEntry.key, fallback: '3');
    final duration = rollEffectDurationFormula(formula) ?? 3;
    applyCustomCondition(
      OculumConditionInstance(
        id: '${customEntry.key}_${DateTime.now().microsecondsSinceEpoch}',
        conditionType: customEntry.key,
        category: OculumConditionCategory.special,
        duration: duration,
        tickTrigger: OculumConditionTickTrigger.endTurn,
        source: source,
        metadata: <String, dynamic>{
          ...template,
          'custom': true,
          'durationFormula': formula,
        },
      ),
    );
    return true;
  }

  List<String> applyEffectCommandsFromText(
    String text, {
    String source = '@effetto',
  }) {
    final applied = <String>[];
    for (final command in oculumParseEffectCommands(text)) {
      if (applyEffectCommand(command, source: source)) {
        applied.add(command.name);
      }
    }
    return applied;
  }

  void removeConditionsFromSource(String source) {
    final normalized = source.trim();
    if (normalized.isEmpty) return;
    final matching = activeConditions
        .where((condition) => condition.source == normalized)
        .toList(growable: false);
    for (final condition in matching) {
      removeCondition(condition, force: true);
    }
  }

  bool hasCondition(String type) => getCondition(type) != null;

  int removeNegativeConditionsForVulnerabilityReset() {
    final affected = activeConditions
        .where(oculumConditionIsNegative)
        .expand(conditionTargetsFor)
        .toSet();
    final removed = oculumRemoveNegativeConditions(activeConditions);
    if (removed <= 0) return 0;
    notifyConditionsChanged(affected);
    return removed;
  }

  bool canApplyControlCondition(
    OculumConditionDefinition definition, {
    String source = '',
    bool ignoreProtection = false,
  }) {
    if (!definition.control || ignoreProtection) return true;
    final key = '${definition.id}|${source.trim().toLowerCase()}';
    return playerReportedTurn >=
        (conditionControlProtectionUntilTurn[key] ?? 0);
  }

  bool applyCondition(
    String type, {
    int stage = 1,
    int? duration,
    String source = '',
    bool? removable,
    OculumConditionTickTrigger? tickTrigger,
    Map<String, dynamic>? metadata,
    bool ignoreControlProtection = false,
  }) {
    final definition = oculumConditionDefinition(type);
    if (definition == null) return false;
    final mentalBarrier = getCondition('barriera_mentale');
    if (mentalBarrier != null &&
        definition.category == OculumConditionCategory.mental &&
        definition.polarity == OculumConditionPolarity.negative) {
      removeCondition(mentalBarrier, force: true, expired: true);
      final message = t(
        'Barriera Mentale annulla ${definition.nameIt}.',
        'Mental Barrier negates ${definition.nameEn}.',
      );
      risultato = message;
      aggiungiLog(message);
      return false;
    }
    if (hasCondition('ancorato') &&
        (type == 'atterrato' || type == 'afferrato')) {
      final message = t(
        'Ancorato impedisce ${definition.nameIt}.',
        'Anchored prevents ${definition.nameEn}.',
      );
      risultato = message;
      aggiungiLog(message);
      return false;
    }
    final wet = getCondition('bagnato');
    if (wet != null && type == 'bruciatura') {
      removeCondition(wet, force: true, expired: true);
      final message = t(
        'Bagnato spegne Bruciatura e viene consumato.',
        'Wet extinguishes Burning and is consumed.',
      );
      risultato = message;
      aggiungiLog(message);
      return false;
    }
    final effectiveStage = wet != null && type == 'gelo'
        ? max(1, stage) + 1
        : stage;
    final existing = getCondition(type);
    final override = conditionOverrideFor(type);
    if (!canApplyControlCondition(
      definition,
      source: source,
      ignoreProtection: ignoreControlProtection,
    )) {
      aggiungiLog(
        t(
          '${definition.nameIt} non applicato: protezione temporanea dalla stessa fonte.',
          '${definition.nameEn} not applied: temporary protection from the same source.',
        ),
      );
      return false;
    }

    final int targetStage = existing == null
        ? effectiveStage.clamp(1, definition.maxStage).toInt()
        : definition.stackMode == OculumConditionStackMode.increaseStage
        ? min(
            definition.maxStage,
            existing.stage + max(1, effectiveStage),
          ).toInt()
        : effectiveStage.clamp(1, definition.maxStage).toInt();
    final overrideFormula = duration == null
        ? conditionOverrideDurationFormula(type)
        : '';
    final overrideDuration = overrideFormula.isEmpty
        ? null
        : rollEffectDurationFormula(overrideFormula);
    final vitaAfonaDuration = switch (normalizedCampaignDifficulty()) {
      'facile' => 1,
      'difficile' => 4,
      'oculum' => 5,
      _ => 3,
    };
    final scaledDuration = type == 'vita_afona' && duration == null
        ? vitaAfonaDuration
        : oculumConditionScaledDuration(
            base:
                duration ??
                overrideDuration ??
                definition.durationForStage(targetStage),
            difficulty: normalizedCampaignDifficulty(),
            scale:
                definition.difficultyScaling ==
                    OculumConditionDifficultyScaling.duration ||
                definition.difficultyScaling ==
                    OculumConditionDifficultyScaling.damageAndDuration,
          );
    String message;
    if (existing == null) {
      final instance = OculumConditionInstance(
        id: '${type}_${DateTime.now().microsecondsSinceEpoch}',
        conditionType: type,
        category: definition.category,
        stage: targetStage,
        duration: scaledDuration,
        durationType: definition.durationType,
        tickTrigger: tickTrigger ?? definition.tickTrigger,
        removable: removable ?? definition.removable,
        source: source,
        metadata: <String, dynamic>{
          ...?override,
          if (overrideFormula.isNotEmpty) 'durationFormula': overrideFormula,
          ...?metadata,
        },
      );
      activeConditions.add(instance);
      if (type == 'massima_potenza' &&
          !investMaximumPower(instance, forced: false)) {
        activeConditions.remove(instance);
        return false;
      }
      message = t(
        '${nomeController.text} ottiene ${conditionLabel(instance)}.',
        '${nomeController.text} gains ${conditionLabel(instance)}.',
      );
    } else {
      final beforeStage = existing.stage;
      switch (definition.stackMode) {
        case OculumConditionStackMode.none:
          break;
        case OculumConditionStackMode.refreshDuration:
          existing.duration = max(existing.duration, scaledDuration);
        case OculumConditionStackMode.increaseStage:
          existing.stage = targetStage;
          existing.duration = max(existing.duration, scaledDuration);
        case OculumConditionStackMode.increaseStacks:
          existing.stacks = min(
            definition.maxStacks,
            existing.stacks + max(1, stage),
          );
          existing.duration += scaledDuration;
        case OculumConditionStackMode.replaceIfStronger:
          existing.stage = max(
            existing.stage,
            effectiveStage.clamp(1, definition.maxStage),
          );
          existing.duration = max(existing.duration, scaledDuration);
      }
      if (source.trim().isNotEmpty) existing.source = source.trim();
      if (metadata != null) existing.metadata.addAll(metadata);
      message = definition.stackMode == OculumConditionStackMode.increaseStacks
          ? t(
              '${definition.nameIt}: ${existing.stacks} stack, durata ${existing.duration}.',
              '${definition.nameEn}: ${existing.stacks} stacks, duration ${existing.duration}.',
            )
          : beforeStage == existing.stage
          ? t(
              '${definition.nameIt}: durata rinnovata.',
              '${definition.nameEn}: duration refreshed.',
            )
          : t(
              '${definition.nameIt} aumenta: ${oculumRomanStage(beforeStage)} -> ${oculumRomanStage(existing.stage)}.',
              '${definition.nameEn} increases: ${oculumRomanStage(beforeStage)} -> ${oculumRomanStage(existing.stage)}.',
            );
    }
    risultato = message;
    ultimoEventoRiposo = message;
    aggiungiLog(message);
    final appliedInstance = getCondition(type);
    if (type == 'aumento_difficolta' && appliedInstance != null) {
      grantDifficultyIncreaseFightRewards(appliedInstance);
    }
    if (type == 'bagnato') {
      final burning = getCondition('bruciatura');
      if (burning != null) removeCondition(burning, force: true, expired: true);
    }
    if (type == 'gelo' && wet != null && activeConditions.contains(wet)) {
      removeCondition(wet, force: true, expired: true);
    }
    notifyConditionsChanged(definition.affectedTargets);
    programmaSalvataggio(invalidateCaches: false);
    return true;
  }

  void applyCustomCondition(OculumConditionInstance instance) {
    final same = activeConditions
        .where((item) => item.conditionType == instance.conditionType)
        .firstOrNull;
    if (same == null) {
      activeConditions.add(instance);
      aggiungiLog(
        t(
          '${nomeController.text} ottiene ${conditionLabel(instance)}.',
          '${nomeController.text} gains ${conditionLabel(instance)}.',
        ),
      );
    } else {
      final modeName = '${instance.metadata['stackMode'] ?? 'refreshDuration'}';
      final mode = OculumConditionStackMode.values.firstWhere(
        (value) => value.name == modeName,
        orElse: () => OculumConditionStackMode.refreshDuration,
      );
      switch (mode) {
        case OculumConditionStackMode.none:
          break;
        case OculumConditionStackMode.refreshDuration:
          same.duration = max(same.duration, instance.duration);
        case OculumConditionStackMode.increaseStage:
          final maxStage = max(
            1,
            readIntValue(instance.metadata['maxStage'], fallback: 1),
          );
          same.stage = min(maxStage, same.stage + 1);
        case OculumConditionStackMode.increaseStacks:
          final maxStacks = max(
            1,
            readIntValue(instance.metadata['maxStacks'], fallback: 5),
          );
          same.stacks = min(maxStacks, same.stacks + 1);
          same.duration += instance.duration;
        case OculumConditionStackMode.replaceIfStronger:
          if (instance.stage > same.stage) same.stage = instance.stage;
      }
      aggiungiLog(
        t(
          '${conditionName(same)} aggiornato.',
          '${conditionName(same)} updated.',
        ),
      );
    }
    notifyConditionsChanged(conditionTargetsFor(instance));
    programmaSalvataggio(invalidateCaches: false);
  }

  bool removeCondition(
    OculumConditionInstance instance, {
    bool force = false,
    bool expired = false,
  }) {
    if (!force && !instance.removable) return false;
    final definition = oculumConditionDefinition(instance.conditionType);
    final affectedTargets = conditionTargetsFor(instance);
    if (!activeConditions.remove(instance)) return false;
    if (instance.conditionType == 'massima_potenza') {
      removeMaximumPowerBonuses(instance);
    }
    if (statoForzaAttivo == 'vero_bruciore_anima' &&
        !oculumCanMaintainTrueSoulBurn(activeConditions)) {
      final ended = terminaStatoForzaAttivo(applicaEsitoEsplosione: false);
      if (ended.isNotEmpty) aggiungiLog(ended);
    }
    if (definition?.control ?? false) {
      final profile = oculumConditionDifficultyProfile(
        normalizedCampaignDifficulty(),
      );
      final key =
          '${instance.conditionType}|${instance.source.trim().toLowerCase()}';
      conditionControlProtectionUntilTurn[key] =
          playerReportedTurn + profile.controlProtectionTurns + 1;
    }
    final message = expired
        ? t(
            '${conditionName(instance)} termina.',
            '${conditionName(instance)} ends.',
          )
        : t(
            '${conditionName(instance)} rimosso.',
            '${conditionName(instance)} removed.',
          );
    risultato = message;
    aggiungiLog(message);
    notifyConditionsChanged(affectedTargets);
    programmaSalvataggio(invalidateCaches: false);
    return true;
  }

  void applyMaximumPowerBonus(OculumConditionInstance instance, int bonus) {
    if (bonus == 0) return;
    tempResilienza += bonus;
    tempVolonta += bonus;
    tempMateria += bonus;
    rimarginaHpDaAumentoResilienza(bonus);
    instance.metadata['grantedBonus'] =
        readIntValue(instance.metadata['grantedBonus']) + bonus;
    invalidateDerivedDataCaches();
    notifyOculumResourceChanged();
  }

  void removeMaximumPowerBonuses(OculumConditionInstance instance) {
    final granted = readIntValue(instance.metadata['grantedBonus']);
    final fiftyPercentResilience = readIntValue(
      instance.metadata['fiftyPercentResilience'],
    );
    final fiftyPercentWill = readIntValue(
      instance.metadata['fiftyPercentWill'],
    );
    final fiftyPercentMatter = readIntValue(
      instance.metadata['fiftyPercentMatter'],
    );
    final fiftyPercentOculum = readIntValue(
      instance.metadata['fiftyPercentOculum'],
    );
    tempResilienza -= granted + fiftyPercentResilience;
    tempVolonta -= granted + fiftyPercentWill;
    tempMateria -= granted + fiftyPercentMatter;
    tempOculum -= fiftyPercentOculum;
    rimarginaHpDaAumentoResilienza(-(granted + fiftyPercentResilience));
    instance.metadata['grantedBonus'] = 0;
    invalidateDerivedDataCaches();
    notifyOculumResourceChanged();
  }

  void applyMaximumPowerFiftyPercentBuff(OculumConditionInstance instance) {
    if (readBoolValue(instance.metadata['fiftyPercentApplied'])) return;
    final resilience = max(1, (statMassimo('resilienza') * .5).floor());
    final will = max(1, (statMassimo('volonta') * .5).floor());
    final matter = max(1, (statMassimo('materia') * .5).floor());
    final oculum = max(1, (oculumMassimo() * .5).floor());
    tempResilienza += resilience;
    tempVolonta += will;
    tempMateria += matter;
    tempOculum += oculum;
    rimarginaHpDaAumentoResilienza(resilience);
    instance.metadata.addAll(<String, dynamic>{
      'fiftyPercentApplied': true,
      'fiftyPercentResilience': resilience,
      'fiftyPercentWill': will,
      'fiftyPercentMatter': matter,
      'fiftyPercentOculum': oculum,
    });
    invalidateDerivedDataCaches();
    notifyOculumResourceChanged();
  }

  bool investMaximumPower(
    OculumConditionInstance instance, {
    required bool forced,
  }) {
    final requestedOculum = oculumMaximumPowerOculumCost(oculumTotale());
    var spentOculum = spendOculum(requestedOculum, scheduleSave: false);
    var hpFallbackDamage = 0;
    final hpHits = <int>[];
    if (spentOculum <= 0) {
      for (final requestedHit in oculumMaximumPowerHpFallbackHits(
        hpCorrenti(),
      )) {
        if (requestedHit <= 0 || hpCorrenti() <= 0) continue;
        final beforeHp = hpCorrenti();
        final afterHp = max(0, beforeHp - requestedHit);
        final hit = beforeHp - afterHp;
        if (hit <= 0) continue;
        currentHpController.text = '$afterHp';
        hpFallbackDamage += hit;
        hpHits.add(hit);
        checkAutomaticAshFromHpLoss(
          beforeHp,
          afterHp,
          source: t('Massima Potenza', 'Maximum Power'),
        );
      }
      if (hpFallbackDamage > 0) {
        sendRealtimeHpChanged();
        controllaStatoForzaDopoHp();
      }
    }
    if (spentOculum <= 0 && hpFallbackDamage <= 0) {
      risultato = t(
        'Massima Potenza richiede Oculum attuale o HP da suddividere in quattro danni.',
        'Maximum Power requires current Oculum or HP to split into four hits.',
      );
      aggiungiLog(risultato);
      return false;
    }
    if (spentOculum > 0) {
      adjustRecordedStatSpentFromDelta('oculum', -spentOculum);
    }

    var spentIntegrity = 0;
    final changedArts = <int>[];
    if (forced) {
      for (var index = 0; index < arti.length; index++) {
        final art = arti[index];
        if (!art.sbloccata) continue;
        ensureArtIntegrityValue(index);
        final current = max(0, art.integritaCorrente);
        final integrityCost = oculumMaximumPowerIntegrityCost(current);
        if (integrityCost <= 0) continue;
        setArtIntegrityValue(index, current - integrityCost);
        spentIntegrity += integrityCost;
        changedArts.add(index);
      }
    }

    final invested = spentOculum > 0 ? spentOculum : hpFallbackDamage;
    applyMaximumPowerBonus(instance, invested);
    applyMaximumPowerFiftyPercentBuff(instance);
    instance.metadata.addAll(<String, dynamic>{
      'lastOculumSpent': spentOculum,
      'lastHpFallbackDamage': hpFallbackDamage,
      'lastHpFallbackHits': hpHits,
      'lastIntegritySpent': spentIntegrity,
      'forcedStages':
          readIntValue(instance.metadata['forcedStages']) + (forced ? 1 : 0),
    });
    if (changedArts.isNotEmpty) scheduleArtIntegritySave(changedArts);
    risultato = forced
        ? t(
            'Massima Potenza forzata: ${spentOculum > 0 ? '-$spentOculum Oculum' : '-$hpFallbackDamage HP in ${hpHits.length} danni'} e -$spentIntegrity Integrita Art, +$invested temporaneo a RES, VOL e MAT.',
            'Maximum Power forced: ${spentOculum > 0 ? '-$spentOculum Oculum' : '-$hpFallbackDamage HP in ${hpHits.length} hits'} and -$spentIntegrity Art Integrity, +$invested temporary RES, WIL and MAT.',
          )
        : t(
            'Massima Potenza: ${spentOculum > 0 ? '-$spentOculum Oculum' : '-$hpFallbackDamage HP in ${hpHits.length} danni'}, +$invested temporaneo a RES, VOL e MAT e +50% a RES, VOL, MAT e OCU per la durata.',
            'Maximum Power: ${spentOculum > 0 ? '-$spentOculum Oculum' : '-$hpFallbackDamage HP in ${hpHits.length} hits'}, +$invested temporary RES, WIL and MAT and +50% RES, WIL, MAT and OCU for the duration.',
          );
    aggiungiLog(risultato);
    return true;
  }

  void increaseConditionStage(OculumConditionInstance instance) {
    final definition = oculumConditionDefinition(instance.conditionType);
    final maxStage =
        definition?.maxStage ??
        max(1, readIntValue(instance.metadata['maxStage'], fallback: 1));
    if (instance.stage >= maxStage) return;
    if (instance.conditionType == 'massima_potenza' &&
        !investMaximumPower(instance, forced: true)) {
      return;
    }
    final before = instance.stage;
    instance.stage++;
    if (definition != null && definition.durationByStage.isNotEmpty) {
      final scaledDuration = oculumConditionScaledDuration(
        base: definition.durationForStage(instance.stage),
        difficulty: normalizedCampaignDifficulty(),
        scale:
            definition.difficultyScaling ==
                OculumConditionDifficultyScaling.duration ||
            definition.difficultyScaling ==
                OculumConditionDifficultyScaling.damageAndDuration,
      );
      instance.duration = max(instance.duration, scaledDuration);
    }
    aggiungiLog(
      t(
        '${conditionName(instance)} aumenta: ${oculumRomanStage(before)} -> ${oculumRomanStage(instance.stage)}.',
        '${conditionName(instance)} increases: ${oculumRomanStage(before)} -> ${oculumRomanStage(instance.stage)}.',
      ),
    );
    notifyConditionsChanged(conditionTargetsFor(instance));
    programmaSalvataggio(invalidateCaches: false);
  }

  void decreaseConditionStage(
    OculumConditionInstance instance, {
    int amount = 1,
  }) {
    if (instance.stage <= amount) {
      removeCondition(instance, force: true);
      return;
    }
    final before = instance.stage;
    instance.stage = max(1, instance.stage - amount);
    aggiungiLog(
      t(
        '${conditionName(instance)} diminuisce: ${oculumRomanStage(before)} -> ${oculumRomanStage(instance.stage)}.',
        '${conditionName(instance)} decreases: ${oculumRomanStage(before)} -> ${oculumRomanStage(instance.stage)}.',
      ),
    );
    notifyConditionsChanged(conditionTargetsFor(instance));
    programmaSalvataggio(invalidateCaches: false);
  }

  void refreshConditionDuration(
    OculumConditionInstance instance,
    int duration,
  ) {
    instance.duration = max(instance.duration, duration);
    notifyConditionsChanged(conditionTargetsFor(instance));
    programmaSalvataggio(invalidateCaches: false);
  }

  int calculateConditionEffect(
    OculumConditionInstance instance, {
    int? referenceValue,
  }) {
    final definition = oculumConditionDefinition(instance.conditionType);
    final basePercent =
        definition?.percentForStage(instance.stage) ??
        readDoubleValue(instance.metadata['percent']);
    final minimum =
        definition?.minimumForStage(instance.stage) ??
        readIntValue(instance.metadata['minimum']);
    final maxValue = readIntValue(instance.metadata['maximum']);
    final scaling =
        definition?.difficultyScaling.name ??
        '${instance.metadata['difficultyScaling'] ?? 'none'}';
    final value = oculumConditionScaledValue(
      referenceValue: referenceValue ?? maxHp(),
      basePercent: basePercent,
      minimum: minimum,
      difficulty: normalizedCampaignDifficulty(),
      maximum: maxValue <= 0
          ? max(1, ((referenceValue ?? maxHp()) * .10).floor())
          : maxValue,
      scaleWithDifficulty:
          scaling == 'damage' ||
          scaling == 'damageAndDuration' ||
          scaling == 'custom',
    );
    return oculumConditionStackedEffect(
      baseEffect: value,
      stacks: max(1, instance.stacks),
      referenceValue: referenceValue ?? maxHp(),
      maximumPercentPerTick: oculumConditionDifficultyProfile(
        normalizedCampaignDifficulty(),
      ).periodicDamageCapPercent,
    );
  }

  int conditionGlobalRollModifier() {
    if (statoForzaRimuoveMalus()) return 0;
    final rawPenalty = activeConditions.fold<int>(0, (total, instance) {
      final definition = oculumConditionDefinition(instance.conditionType);
      if (definition == null ||
          definition.polarity != OculumConditionPolarity.negative) {
        return total;
      }
      return total + definition.rollModifierForStage(instance.stage);
    });
    if (rawPenalty >= 0) return rawPenalty;
    final multiplier = oculumConditionDifficultyProfile(
      normalizedCampaignDifficulty(),
    ).rollPenaltyMultiplier;
    final scaled = (rawPenalty.abs() * multiplier).ceil();
    final cap = oculumConditionDifficultyProfile(
      normalizedCampaignDifficulty(),
    ).rollPenaltyCap;
    return min(cap, scaled) * -1;
  }

  int applyConditionDerivedValue(OculumConditionTarget target, int baseValue) {
    if (baseValue <= 0) return max(0, baseValue);
    var percent = 0.0;
    final positiveMultiplier = oculumPositiveConditionMultiplier(
      normalizedCampaignDifficulty(),
    );
    final flatModifier = conditionFlatModifier(target);
    if (target == OculumConditionTarget.difesa && hasCondition('fortificato')) {
      percent += 15 * positiveMultiplier;
    }
    if (target == OculumConditionTarget.difesa && !statoForzaRimuoveMalus()) {
      final corrosion = getCondition('corroso');
      if (corrosion != null) {
        percent -= oculumCorrosionPercent(corrosion.stage);
      }
      if (hasCondition('marchiato')) percent -= 20;
      if (hasCondition('rinsecchito')) percent -= 75;
    }
    if (target == OculumConditionTarget.danno) {
      if (hasCondition('potenziato')) percent += 15 * positiveMultiplier;
      if (!statoForzaRimuoveMalus() && hasCondition('indebolito')) {
        percent -= 20;
      }
    }
    if (target == OculumConditionTarget.movimento) {
      if (!statoForzaRimuoveMalus() &&
          (hasCondition('immobilizzato') || hasCondition('afferrato'))) {
        return 0;
      }
      if (hasCondition('accelerato')) percent += 20 * positiveMultiplier;
      if (hasCondition('ancorato')) percent -= 25;
      if (!statoForzaRimuoveMalus() && hasCondition('rallentato')) {
        percent -= 25;
      }
    }
    if (percent == 0) return max(0, baseValue + flatModifier);
    final delta = (baseValue * percent.abs() / 100).floor();
    final effectiveDelta = max(1, delta);
    return max(
      0,
      baseValue +
          (percent > 0 ? effectiveDelta : -effectiveDelta) +
          flatModifier,
    );
  }

  int conditionFlatModifier(OculumConditionTarget target) {
    var result = 0.0;
    for (final instance in activeConditions) {
      final modifiers = instance.metadata['modifiers'];
      if (modifiers is! Map || modifiers[target.name] == null) continue;
      var value = readDoubleValue(modifiers[target.name]);
      final definition = oculumConditionDefinition(instance.conditionType);
      final positive =
          definition?.polarity == OculumConditionPolarity.positive ||
          '${instance.metadata['polarity']}' ==
              OculumConditionPolarity.positive.name;
      if (positive) {
        value *= oculumPositiveConditionMultiplier(
          normalizedCampaignDifficulty(),
        );
      } else if (statoForzaRimuoveMalus() && value < 0) {
        value = 0;
      }
      result += value;
    }
    if (target == OculumConditionTarget.iniziativa &&
        !statoForzaRimuoveMalus() &&
        hasCondition('elettrizzato')) {
      result -= 3;
    }
    return result.round();
  }

  int conditionShieldDamageBonusPercent() {
    if (statoForzaRimuoveMalus()) return 0;
    final corrosion = getCondition('corroso');
    return corrosion == null ? 0 : oculumCorrosionPercent(corrosion.stage);
  }

  int applyConditionHealingAmount(int requested) {
    if (requested <= 0) return 0;
    final cursed = getCondition('maledetto');
    if (cursed == null || statoForzaRimuoveMalus()) return requested;
    return oculumCursedHealing(requested, cursed.stage);
  }

  int applyConditionIncomingDamage(int damage) {
    if (damage <= 0) return damage;
    final exposed = getCondition('esposto');
    final vulnerable = hasCondition('vulnerabile');
    final difficultyIncrease = getCondition('aumento_difficolta');
    final vitalMemory = hasCondition('ricordo_vitale');
    final marked = getCondition('marchiato');
    if (statoForzaRimuoveMalus() && !vitalMemory) return damage;
    if (exposed == null &&
        !vulnerable &&
        difficultyIncrease == null &&
        !vitalMemory &&
        marked == null) {
      return damage;
    }
    final vulnerabilityIncrease = exposed != null || vulnerable
        ? max(1, (damage * .20).floor())
        : 0;
    final difficultyIncreaseDamage =
        oculumDifficultyIncreaseIncomingDamageBonus(
          damage,
          difficultyIncrease?.stage ?? 0,
        );
    final vitalMemoryIncrease = vitalMemory
        ? oculumVitalMemoryIncomingDamage(damage) - damage
        : 0;
    final increase =
        vulnerabilityIncrease + difficultyIncreaseDamage + vitalMemoryIncrease;
    if (exposed != null) removeCondition(exposed, force: true, expired: true);
    if (marked != null) removeCondition(marked, force: true, expired: true);
    return damage + increase;
  }

  void registerVitalMemoryDamage(int hpDamage) {
    final instance = getCondition('ricordo_vitale');
    if (instance == null || hpDamage <= 0) return;
    final recovery = oculumVitalMemoryRecoveryForDamage(hpDamage);
    instance.metadata.addAll(<String, dynamic>{
      'pendingHealing': recovery.total,
      'healingChunk': recovery.perTick,
      'sourceDamage': hpDamage,
    });
    notifyConditionsChanged(conditionTargetsFor(instance));
  }

  int vitalMemoryPendingHealing() => max(
    0,
    readIntValue(getCondition('ricordo_vitale')?.metadata['pendingHealing']),
  );

  void applyVitalMemoryTick(OculumConditionInstance instance) {
    final pending = readIntValue(instance.metadata['pendingHealing']);
    if (pending <= 0) return;
    if (hasCondition('elettrizzato')) {
      final message = t(
        'Elettrizzato impedisce il recupero HP di Ricordo Vitale.',
        'Electrified prevents Vital Memory HP recovery.',
      );
      risultato = message;
      aggiungiLog(message);
      notifyConditionsChanged(conditionTargetsFor(instance));
      return;
    }
    final chunk = max(1, readIntValue(instance.metadata['healingChunk']));
    final rawRequested = min(pending, chunk);
    final requested = applyConditionHealingAmount(rawRequested);
    final before = hpCorrenti();
    final after = min(maxHp(), before + requested);
    final restored = after - before;
    instance.metadata['pendingHealing'] = max(0, pending - rawRequested);
    currentHpController.text = '$after';
    if (restored > 0) sendRealtimeHpChanged();
    final message = t(
      'Ricordo Vitale: +$restored HP, ${instance.metadata['pendingHealing']} da recuperare.',
      'Vital Memory: +$restored HP, ${instance.metadata['pendingHealing']} left to recover.',
    );
    risultato = message;
    aggiungiLog(message);
    notifyConditionsChanged(conditionTargetsFor(instance));
  }

  void setFightEnemyDifficulty(String enemyDifficulty) {
    final normalizedEnemy = normalizeTemporaryOculumDifficulty(enemyDifficulty);
    final stages = oculumDifficultyIncreaseStages(
      characterDifficulty: normalizedCampaignDifficulty(),
      enemyDifficulty: normalizedEnemy,
    );
    final existing = getCondition('aumento_difficolta');
    if (stages <= 0) {
      if (existing != null) removeCondition(existing, force: true);
      return;
    }
    if (existing == null) {
      applyCondition(
        'aumento_difficolta',
        stage: stages,
        duration: 0,
        source: t('Differenza difficolta Fight', 'Fight difficulty gap'),
        metadata: <String, dynamic>{
          'enemyDifficulty': normalizedEnemy,
          'characterDifficulty': normalizedCampaignDifficulty(),
        },
      );
      return;
    }
    existing.stage = stages;
    existing.metadata['enemyDifficulty'] = normalizedEnemy;
    existing.metadata['characterDifficulty'] = normalizedCampaignDifficulty();
    notifyConditionsChanged(conditionTargetsFor(existing));
    programmaSalvataggio(invalidateCaches: false);
  }

  String difficultyIncreaseFightDescription() {
    final profile = oculumDifficultyIncreaseFightProfile(
      normalizedCampaignDifficulty(),
    );
    final instance = getCondition('aumento_difficolta');
    final stage = instance?.stage ?? 0;
    final hasEnemyDifficulty =
        instance?.metadata.containsKey('enemyDifficulty') ?? false;
    final enemyDifficulty = '${instance?.metadata['enemyDifficulty'] ?? ''}';
    final matchupIt = hasEnemyDifficulty
        ? 'Personaggio ${campaignDifficultyLabel()} · Mostro ${campaignDifficultyLabel(enemyDifficulty)}. '
        : 'Personaggio ${campaignDifficultyLabel()} · Stadio manuale ${oculumRomanStage(max(1, stage))}. ';
    final matchupEn = hasEnemyDifficulty
        ? 'Character ${campaignDifficultyLabel()} · Enemy ${campaignDifficultyLabel(enemyDifficulty)}. '
        : 'Character ${campaignDifficultyLabel()} · Manual stage ${oculumRomanStage(max(1, stage))}. ';
    return t(
      '$matchupIt${stage > 0 ? "+${stage * 3}% danni ricevuti e ${stage * -3} VC/CM. " : "Nessuna differenza attiva. "}'
          'Per ogni danno: ${profile.beyondDefenseChance}% Oltre Difesa, ${profile.beyondShieldChance}% Oltre Scudo. '
          'Ricompensa: 1/${profile.shieldDivisor} Vita in ${profile.usesOculumShield ? "Scudo Oculum permanente" : "Scudo"}, '
          '+${profile.fortunaPercent}% Fortuna temporanea, 1 ${profile.inspirationType == "super"
              ? "Super Ispirazione"
              : profile.inspirationType == "oculum"
              ? "Ispirazione Oculum"
              : "Ispirazione"}'
          '${profile.oculumDodgeBonus > 0 ? ", +1 Schivata Oculum" : ""}.',
      '$matchupEn${stage > 0 ? "+${stage * 3}% incoming damage and ${stage * -3} VC/CM. " : "No active gap. "}'
          'Per damage: ${profile.beyondDefenseChance}% Beyond Defense, ${profile.beyondShieldChance}% Beyond Shield. '
          'Reward: 1/${profile.shieldDivisor} Life as ${profile.usesOculumShield ? "permanent Oculum Shield" : "Shield"}, '
          '+${profile.fortunaPercent}% temporary Luck, 1 ${profile.inspirationType == "super"
              ? "Super Inspiration"
              : profile.inspirationType == "oculum"
              ? "Oculum Inspiration"
              : "Inspiration"}'
          '${profile.oculumDodgeBonus > 0 ? ", +1 Oculum Dodge" : ""}.',
    );
  }

  int difficultyIncreaseFightPenalty() {
    return oculumDifficultyIncreaseFightPenalty(
      getCondition('aumento_difficolta')?.stage ?? 0,
    );
  }

  int difficultyIncreaseOculumDodgeBonus() {
    final instance = getCondition('aumento_difficolta');
    if (instance == null ||
        !readBoolValue(instance.metadata['rewardGranted'])) {
      return 0;
    }
    return oculumDifficultyIncreaseFightProfile(
      normalizedCampaignDifficulty(),
    ).oculumDodgeBonus;
  }

  int difficultyIncreaseFortunaBonus(int baseFortuna) {
    final instance = getCondition('aumento_difficolta');
    if (instance == null || baseFortuna <= 0) return 0;
    final available = instance.metadata.containsKey('fortunaAvailable')
        ? readBoolValue(instance.metadata['fortunaAvailable'])
        : readIntValue(instance.metadata['fortunaPercent']) > 0;
    if (!available) return 0;
    final percent = oculumDifficultyIncreaseFightProfile(
      normalizedCampaignDifficulty(),
    ).fortunaPercent;
    if (percent <= 0) return 0;
    return max(1, (baseFortuna * percent / 100).ceil());
  }

  void grantDifficultyIncreaseFightRewards(OculumConditionInstance instance) {
    if (readBoolValue(instance.metadata['rewardGranted'])) return;
    final profile = oculumDifficultyIncreaseFightProfile(
      normalizedCampaignDifficulty(),
    );
    final shieldReward = max(1, (maxHp() / profile.shieldDivisor).ceil());
    if (profile.usesOculumShield) {
      final newMaximum = scudoOculumMax() + shieldReward;
      scudoOculumMaxController.text = '$newMaximum';
      scudoOculumController.text = '${scudoOculum() + shieldReward}';
      notifyOculumResourceChanged();
    } else {
      impostaScudoTotale(scudo() + shieldReward);
    }
    final rewardLog = <String>[];
    grantInspirationWithCap(profile.inspirationType, 1, rewardLog);
    instance.metadata.addAll(<String, dynamic>{
      'rewardGranted': true,
      'shieldReward': shieldReward,
      'shieldType': profile.usesOculumShield ? 'oculum' : 'normal',
      'oculumDodgeBonus': profile.oculumDodgeBonus,
      'fortunaAvailable': true,
      'fortunaPercent': profile.fortunaPercent,
      'fortunaUntilHpLoss': profile.fortunaUntilHpLoss,
      'beyondDefenseChance': profile.beyondDefenseChance,
      'beyondShieldChance': profile.beyondShieldChance,
    });
    invalidateDerivedDataCaches();
    aggiungiLog(
      t(
        'Aumento difficolta: +$shieldReward ${profile.usesOculumShield ? "Scudo Oculum massimo e attuale" : "Scudo"}, '
            '+${profile.fortunaPercent}% Fortuna temporanea, '
            '${profile.oculumDodgeBonus > 0 ? "+1 Schivata Oculum, " : ""}'
            '${rewardLog.isEmpty ? "ispirazione assegnata" : rewardLog.join(", ")}.',
        'Difficulty increase: +$shieldReward ${profile.usesOculumShield ? "maximum and current Oculum Shield" : "Shield"}, '
            '+${profile.fortunaPercent}% temporary Luck, '
            '${profile.oculumDodgeBonus > 0 ? "+1 Oculum Dodge, " : ""}'
            '${rewardLog.isEmpty ? "inspiration granted" : rewardLog.join(", ")}.',
      ),
    );
  }

  ({bool beyondDefense, bool beyondShield})
  rollDifficultyIncreaseDamageBypasses({Random? random}) {
    final instance = getCondition('aumento_difficolta');
    if (instance == null) {
      return (beyondDefense: false, beyondShield: false);
    }
    final profile = oculumDifficultyIncreaseFightProfile(
      normalizedCampaignDifficulty(),
    );
    final roller = random ?? Random.secure();
    return (
      beyondDefense:
          profile.beyondDefenseChance > 0 &&
          roller.nextInt(100) < profile.beyondDefenseChance,
      beyondShield:
          profile.beyondShieldChance > 0 &&
          roller.nextInt(100) < profile.beyondShieldChance,
    );
  }

  void consumeDifficultyIncreaseFortunaBonus({required bool hpLost}) {
    final instance = getCondition('aumento_difficolta');
    if (instance == null) return;
    final available = instance.metadata.containsKey('fortunaAvailable')
        ? readBoolValue(instance.metadata['fortunaAvailable'])
        : readIntValue(instance.metadata['fortunaPercent']) > 0;
    if (!available) return;
    final untilHpLoss = oculumDifficultyIncreaseFightProfile(
      normalizedCampaignDifficulty(),
    ).fortunaUntilHpLoss;
    if (untilHpLoss && !hpLost) return;
    instance.metadata['fortunaAvailable'] = false;
    instance.metadata['fortunaPercent'] = 0;
    invalidateDerivedDataCaches();
    notifyConditionsChanged(<OculumConditionTarget>{
      OculumConditionTarget.tiri,
      OculumConditionTarget.combattimento,
    });
  }

  void applyDirectConditionDamage(
    OculumConditionInstance instance,
    int amount,
  ) {
    if (amount <= 0) return;
    final before = hpCorrenti();
    final after = max(0, before - amount);
    currentHpController.text = after.toString();
    final message = t(
      '${conditionName(instance)} infligge $amount danni diretti (ignora Scudo e Difesa).',
      '${conditionName(instance)} deals $amount direct damage (ignores Shield and Defense).',
    );
    risultato = message;
    aggiungiLog(message);
    checkAutomaticAshFromHpLoss(before, after, source: conditionName(instance));
    notifyConditionsChanged(<OculumConditionTarget>{
      OculumConditionTarget.hp,
      OculumConditionTarget.combattimento,
    });
    programmaSalvataggio(invalidateCaches: false);
    sendRealtimeHpChanged();
    controllaStatoForzaDopoHp();
  }

  void applyRegenerationTick(OculumConditionInstance instance) {
    final rawHealing = oculumRegenerationHealing(maxHp(), instance.stage);
    final requested = applyConditionHealingAmount(rawHealing);
    final beforeHp = hpCorrenti();
    final beforeTemporary = hpTemp();
    final healed = healOculumHp(
      current: beforeHp,
      maximum: maxHp(),
      temporary: beforeTemporary,
      amount: requested,
    );
    final restored = healed.current - beforeHp;
    final temporary = healed.temporary - beforeTemporary;
    currentHpController.text = '${healed.current}';
    impostaHpTempTotali(healed.temporary);
    final message = t(
      'Rigenerazione: +$restored HP${temporary > 0 ? ', +$temporary HP temporanei' : ''} (${oculumRegenerationHealing(maxHp(), instance.stage)} richiesti).',
      'Regeneration: +$restored HP${temporary > 0 ? ', +$temporary temporary HP' : ''} (${oculumRegenerationHealing(maxHp(), instance.stage)} requested).',
    );
    risultato = message;
    aggiungiLog(message);
    if (restored > 0 || temporary > 0) sendRealtimeHpChanged();
    controllaStatoForzaDopoHp();
    notifyConditionsChanged(conditionTargetsFor(instance));
  }

  void applyOculumFlameTick(OculumConditionInstance instance) {
    final availableBefore = oculumTotale();
    final requestedCost = oculumFlameTurnCost(
      availableBefore,
      stage: instance.stage,
    );
    final spent = spendOculum(requestedCost, scheduleSave: false);
    if (spent <= 0) {
      final message = t(
        '${conditionName(instance)} non trova Oculum attuale da convertire.',
        '${conditionName(instance)} finds no current Oculum to convert.',
      );
      risultato = message;
      aggiungiLog(message);
      return;
    }

    adjustRecordedStatSpentFromDelta('oculum', -spent);
    final multiplier = oculumFlameRewardMultiplier(
      normalizedCampaignDifficulty(),
    );
    final reward = oculumFlameReward(spent, normalizedCampaignDifficulty());
    var restored = 0;
    var temporary = 0;
    String rewardLabel;

    if (instance.conditionType == 'resilienza_in_fiamme') {
      final hpReward = applyConditionHealingAmount(reward);
      final beforeHp = hpCorrenti();
      final beforeTemporaryHp = hpTemp();
      final afterHp = min(maxHp(), beforeHp + hpReward);
      restored = afterHp - beforeHp;
      currentHpController.text = '$afterHp';
      if (instance.stage >= 2) {
        final afterTemporaryHp = min(
          oculumTemporaryHpLimit,
          beforeTemporaryHp + hpReward,
        );
        temporary = afterTemporaryHp - beforeTemporaryHp;
        if (temporary > 0) impostaHpTempTotali(afterTemporaryHp);
      }
      rewardLabel = 'HP';
      if (restored > 0) sendRealtimeHpChanged();
      controllaStatoForzaDopoHp();
    } else {
      final key = instance.conditionType == 'volonta_in_fiamme'
          ? 'volonta'
          : 'materia';
      final current = currentStatValue(key);
      final maximum = statMassimo(key);
      restored = min(reward, max(0, maximum - current));
      if (restored > 0) {
        setCurrentStatFromVisibleInput(
          key,
          '${current + restored}',
          trackConsumption: false,
        );
      }
      temporary = reward - restored;
      if (temporary > 0) {
        if (key == 'volonta') {
          tempVolonta += temporary;
        } else {
          tempMateria += temporary;
        }
        invalidateDerivedDataCaches();
      }
      rewardLabel = key == 'volonta' ? t('Volonta', 'Will') : 'Materia';
    }

    instance.metadata.addAll(<String, dynamic>{
      'lastOculumSpent': spent,
      'lastReward': reward,
      'lastRestored': restored,
      'lastTemporary': temporary,
      'lastMultiplier': multiplier,
    });
    final message = t(
      '${conditionName(instance)}: -$spent Oculum attuale (${oculumFlameTurnPercent(instance.stage)}%), $rewardLabel +$restored (x$multiplier${temporary > 0 ? ', +$temporary temporaneo' : ''}).',
      '${conditionName(instance)}: -$spent current Oculum (${oculumFlameTurnPercent(instance.stage)}%), $rewardLabel +$restored (x$multiplier${temporary > 0 ? ', +$temporary temporary' : ''}).',
    );
    risultato = message;
    aggiungiLog(message);
    notifyConditionsChanged(conditionTargetsFor(instance));
    notifyOculumResourceChanged();
  }

  int repairLowestIntegrityArtFromVioletFlame(int amount) {
    if (amount <= 0) return 0;
    var selectedIndex = -1;
    var selectedIntegrity = 1 << 30;
    for (var index = 0; index < arti.length; index++) {
      if (!arti[index].sbloccata) continue;
      ensureArtIntegrityValue(index);
      final current = max(0, arti[index].integritaCorrente);
      if (current < selectedIntegrity && current < artIntegrityMaximum()) {
        selectedIndex = index;
        selectedIntegrity = current;
      }
    }
    if (selectedIndex < 0) return 0;
    final repaired = min(amount, artIntegrityMaximum() - selectedIntegrity);
    setArtIntegrityValue(selectedIndex, selectedIntegrity + repaired);
    return repaired;
  }

  int restoreVioletFlameStat(String key, int amount) {
    if (amount <= 0) return 0;
    final current = currentStatValue(key);
    final restored = min(amount, max(0, statMassimo(key) - current));
    if (restored > 0) {
      setCurrentStatFromVisibleInput(
        key,
        '${current + restored}',
        trackConsumption: false,
      );
    }
    final overflow = amount - restored;
    if (overflow > 0) {
      if (key == 'volonta') {
        tempVolonta += overflow;
      } else {
        tempMateria += overflow;
      }
      invalidateDerivedDataCaches();
    }
    return restored + overflow;
  }

  void applyVioletOculumFlameTick(OculumConditionInstance instance) {
    final selectedResource = oculumNormalizeEffectResource(
      instance.metadata['nextSpendResource'] ?? 'vita',
    );
    final usesSelectedResource = <String>{
      'oculum',
      'volonta',
      'materia',
    }.contains(selectedResource);
    var lostHp = 0;
    var spentResource = 0;

    if (usesSelectedResource) {
      final available = selectedResource == 'oculum'
          ? oculumTotale()
          : currentSpendableStatValue(selectedResource);
      final cost = oculumVioletFlameThreePercentCost(available);
      spentResource = selectedResource == 'oculum'
          ? spendOculum(cost, scheduleSave: false)
          : spendArtSkillCostResource(selectedResource, cost);
      if (selectedResource == 'oculum' && spentResource > 0) {
        adjustRecordedStatSpentFromDelta('oculum', -spentResource);
        recordCurrentOculumProgress();
      }
      if (spentResource <= 0) {
        instance.metadata['nextSpendResource'] = 'vita';
        risultato = t(
          'Oculum in Fiamme: nessuna $selectedResource attuale spendibile; al prossimo turno torna agli HP.',
          'Oculum Ablaze (Violet): no spendable current $selectedResource; it returns to HP next turn.',
        );
        aggiungiLog(risultato);
        notifyConditionsChanged(conditionTargetsFor(instance));
        return;
      }
      // The alternate payment retains the HP-based conversion scale without
      // damaging HP, then doubles the resulting Oculum recovery.
      lostHp = oculumVioletFlameThreePercentCost(hpCorrenti());
    } else {
      final beforeHp = hpCorrenti();
      final cost = oculumVioletFlameThreePercentCost(beforeHp);
      final afterHp = max(0, beforeHp - cost);
      lostHp = beforeHp - afterHp;
      currentHpController.text = '$afterHp';
      if (lostHp > 0) {
        checkAutomaticAshFromHpLoss(
          beforeHp,
          afterHp,
          source: conditionName(instance),
        );
        sendRealtimeHpChanged();
        controllaStatoForzaDopoHp();
      }
    }

    final baseRecovery = oculumVioletFlameRegeneration(lostHp);
    final recovery = usesSelectedResource ? baseRecovery * 2 : baseRecovery;
    var target = 'oculum';
    var restored = 0;
    var repaired = 0;
    if (usesSelectedResource) {
      restored = addOculum(recovery, scheduleSave: false);
      if (restored > 0) {
        recordCurrentOculumProgress();
        repaired = repairLowestIntegrityArtFromVioletFlame(restored);
      }
    } else if (Random.secure().nextInt(100) <
        oculumVioletFlameDiversionChance(instance.stage)) {
      target = Random.secure().nextBool() ? 'volonta' : 'materia';
      restored = restoreVioletFlameStat(target, recovery);
    } else {
      restored = addOculum(recovery, scheduleSave: false);
      if (restored > 0) recordCurrentOculumProgress();
    }
    instance.metadata.addAll(<String, dynamic>{
      'nextSpendResource': 'vita',
      'lastHpLost': lostHp,
      'lastResourceSpent': spentResource,
      'lastTarget': target,
      'lastRecovery': restored,
      'lastCoreRepair': repaired,
    });
    risultato = usesSelectedResource
        ? t(
            'Oculum in Fiamme: -$spentResource $selectedResource, Oculum +$restored doppio${repaired > 0 ? ', Integrita Art +$repaired' : ''}.',
            'Oculum Ablaze (Violet): -$spentResource $selectedResource, double Oculum +$restored${repaired > 0 ? ', Art Integrity +$repaired' : ''}.',
          )
        : t(
            'Oculum in Fiamme: -$lostHp HP, $target +$restored (stadio ${oculumRomanStage(instance.stage)}).',
            'Oculum Ablaze (Violet): -$lostHp HP, $target +$restored (stage ${oculumRomanStage(instance.stage)}).',
          );
    aggiungiLog(risultato);
    notifyConditionsChanged(conditionTargetsFor(instance));
    notifyOculumResourceChanged();
  }

  bool removeOculumFlamesAtSafetyThreshold() {
    if (!oculumFlameEndsAtLowOculum(
      currentOculum: oculumTotale(),
      maximumOculum: oculumMassimo(),
    )) {
      return false;
    }
    final flames = activeConditions
        .where(
          (item) => const <String>{
            'resilienza_in_fiamme',
            'volonta_in_fiamme',
            'materia_in_fiamme',
          }.contains(item.conditionType),
        )
        .toList(growable: false);
    for (final flame in flames) {
      removeCondition(flame, force: true, expired: true);
    }
    if (statoForzaAttivo == 'vero_bruciore_anima') {
      final ended = terminaStatoForzaAttivo(applicaEsitoEsplosione: false);
      if (ended.isNotEmpty) aggiungiLog(ended);
    }
    if (flames.isNotEmpty) {
      final message = t(
        'Le Fiamme terminano: l Oculum è al 15% o meno del massimo.',
        'The Flames end: Oculum is at 15% or less of its maximum.',
      );
      risultato = message;
      aggiungiLog(message);
    }
    return flames.isNotEmpty;
  }

  void applyTrueSoulBurnTick() {
    final beforeOculum = oculumTotale();
    final spentOculum = spendOculum(
      oculumFlameTurnCost(beforeOculum, stage: 3),
      scheduleSave: false,
    );
    if (spentOculum <= 0) {
      removeOculumFlamesAtSafetyThreshold();
      return;
    }
    adjustRecordedStatSpentFromDelta('oculum', -spentOculum);

    var spentIntegrity = 0;
    final changedArts = <int>[];
    for (var index = 0; index < arti.length; index++) {
      final art = arti[index];
      if (!art.sbloccata) continue;
      ensureArtIntegrityValue(index);
      final current = max(0, art.integritaCorrente);
      if (current <= 0) continue;
      final cost = max(1, (current * .05).floor());
      setArtIntegrityValue(index, current - cost);
      spentIntegrity += cost;
      changedArts.add(index);
    }

    final multiplier = oculumFlameRewardMultiplier(
      normalizedCampaignDifficulty(),
    );
    final reward = oculumFlameReward(
      spentOculum + spentIntegrity,
      normalizedCampaignDifficulty(),
    );
    final hpBefore = hpCorrenti();
    final hpTemporaryBefore = hpTemp();
    final hpReward = applyConditionHealingAmount(reward);
    final hpAfter = min(maxHp(), hpBefore + hpReward);
    final healed = hpAfter - hpBefore;
    final hpTemporaryAfter = min(
      oculumTemporaryHpLimit,
      hpTemporaryBefore + hpReward,
    );
    final hpTemporary = hpTemporaryAfter - hpTemporaryBefore;
    currentHpController.text = '$hpAfter';
    if (hpTemporary > 0) impostaHpTempTotali(hpTemporaryAfter);

    var temporaryWill = 0;
    var temporaryMatter = 0;
    for (final key in const <String>['volonta', 'materia']) {
      final current = currentStatValue(key);
      final restored = min(reward, max(0, statMassimo(key) - current));
      if (restored > 0) {
        setCurrentStatFromVisibleInput(
          key,
          '${current + restored}',
          trackConsumption: false,
        );
      }
      final overflow = reward - restored;
      if (key == 'volonta') {
        temporaryWill = overflow;
        tempVolonta += overflow;
      } else {
        temporaryMatter = overflow;
        tempMateria += overflow;
      }
    }
    invalidateDerivedDataCaches();
    if (healed > 0) sendRealtimeHpChanged();
    if (changedArts.isNotEmpty) scheduleArtIntegritySave(changedArts);
    controllaStatoForzaDopoHp();
    final message = t(
      'Vero Bruciore dell Anima: -$spentOculum Oculum e -$spentIntegrity Integrità Art (5%). HP, Volontà e Materia +$reward (x$multiplier); HP temporanei +$hpTemporary, Volontà temporanea +$temporaryWill, Materia temporanea +$temporaryMatter.',
      'True Soul Burn: -$spentOculum Oculum and -$spentIntegrity Art Integrity (5%). HP, Will and Matter +$reward (x$multiplier); temporary HP +$hpTemporary, temporary Will +$temporaryWill, temporary Matter +$temporaryMatter.',
    );
    risultato = message;
    aggiungiLog(message);
    notifyConditionsChanged(<OculumConditionTarget>{
      OculumConditionTarget.oculum,
      OculumConditionTarget.hp,
      OculumConditionTarget.volonta,
      OculumConditionTarget.materia,
      OculumConditionTarget.art,
      OculumConditionTarget.recupero,
    });
    notifyOculumResourceChanged();
    removeOculumFlamesAtSafetyThreshold();
  }

  void grantTrueSoulBurnSpendBenefits({
    required int spent,
    required String source,
  }) {
    if (statoForzaAttivo != 'vero_bruciore_anima' || spent <= 0) return;
    final multiplier = oculumFlameRewardMultiplier(
      normalizedCampaignDifficulty(),
    );
    // This return intentionally rounds down, so spending Skills and Arts is
    // rewarding but less efficient than the dedicated end-turn conversion.
    final bonus = max(1, (spent * multiplier).floor());
    tempResilienza += bonus;
    tempVolonta += bonus;
    tempMateria += bonus;
    tempOculum += bonus;
    rimarginaHpDaAumentoResilienza(bonus);
    invalidateDerivedDataCaches();
    notifyOculumResourceChanged();
    final message = t(
      'Vero Bruciore dell Anima: $source ha speso $spent e dona +$bonus temporaneo a RES, VOL, MAT e OCU (x$multiplier per difetto).',
      'True Soul Burn: $source spent $spent and grants +$bonus temporary RES, WIL, MAT and OCU (x$multiplier rounded down).',
    );
    risultato = message;
    aggiungiLog(message);
  }

  void processConditionTick(OculumConditionTickTrigger trigger) {
    if (activeConditions.isEmpty) return;
    final snapshot = List<OculumConditionInstance>.from(activeConditions);
    var mutated = false;
    final trueSoulBurn =
        trigger == OculumConditionTickTrigger.endTurn &&
        statoForzaAttivo == 'vero_bruciore_anima';
    for (final instance in snapshot) {
      if (!activeConditions.contains(instance)) continue;
      if (trigger == OculumConditionTickTrigger.startTurn &&
          instance.conditionType == 'putrido') {
        final turnsWithoutApplication =
            readIntValue(instance.metadata['turnsWithoutApplication']) + 1;
        instance.metadata['turnsWithoutApplication'] = turnsWithoutApplication;
        final profile = oculumConditionDifficultyProfile(
          normalizedCampaignDifficulty(),
        );
        final blockedAtAdvancedOculum =
            profile.id == 'oculum' && instance.stage >= 3;
        if (!blockedAtAdvancedOculum &&
            turnsWithoutApplication >= profile.naturalDecayTurns) {
          instance.metadata['turnsWithoutApplication'] = 0;
          decreaseConditionStage(instance);
        }
      }
      if (instance.tickTrigger == trigger &&
          (instance.conditionType == 'veleno_putrido' ||
              instance.conditionType == 'sanguinamento' ||
              instance.conditionType == 'bruciatura')) {
        applyDirectConditionDamage(
          instance,
          calculateConditionEffect(instance),
        );
      }
      if (instance.tickTrigger == trigger &&
          instance.conditionType == 'elettrizzato') {
        applyDirectConditionDamage(instance, oculumElectrifiedDamage(maxHp()));
      }
      if (instance.tickTrigger == trigger &&
          instance.conditionType == 'rigenerazione') {
        applyRegenerationTick(instance);
      }
      if (instance.tickTrigger == trigger &&
          instance.conditionType == 'oculum_instabile') {
        onOculumInstabilityTriggered(instance);
      }
      if (instance.tickTrigger == trigger &&
          instance.conditionType == 'ricordo_vitale') {
        applyVitalMemoryTick(instance);
      }
      if (instance.tickTrigger == trigger &&
          instance.conditionType == 'oculum_in_fiamme_viola') {
        applyVioletOculumFlameTick(instance);
      }
      if (instance.tickTrigger == trigger &&
          <String>{
            'resilienza_in_fiamme',
            'volonta_in_fiamme',
            'materia_in_fiamme',
          }.contains(instance.conditionType) &&
          !trueSoulBurn) {
        applyOculumFlameTick(instance);
        if (removeOculumFlamesAtSafetyThreshold()) break;
      }
      final expiresForTrigger =
          (instance.durationType == OculumConditionDurationType.turns &&
              trigger == OculumConditionTickTrigger.endTurn) ||
          (instance.durationType == OculumConditionDurationType.shortRest &&
              trigger == OculumConditionTickTrigger.shortRest) ||
          (instance.durationType == OculumConditionDurationType.longRest &&
              trigger == OculumConditionTickTrigger.longRest) ||
          (instance.durationType == OculumConditionDurationType.meal &&
              trigger == OculumConditionTickTrigger.specificEvent);
      if (instance.duration > 0 && expiresForTrigger) {
        instance.duration--;
        mutated = true;
        if (instance.duration <= 0) {
          removeCondition(instance, force: true, expired: true);
        }
      }
    }
    if (trueSoulBurn) applyTrueSoulBurnTick();
    if (mutated) {
      notifyConditionsChanged(snapshot.expand(conditionTargetsFor));
      programmaSalvataggio(invalidateCaches: false);
    }
  }

  void advanceConditionTurn() {
    final previous = playerReportedTurn;
    playerReportedTurn++;
    final tag = sheetTagAt(schedaCorrente);
    final localTokenIndex = masterInitiativeTokens.indexWhere(
      (token) => '${token['sheetTag'] ?? token['id'] ?? ''}'.trim() == tag,
    );
    if (localTokenIndex >= 0) {
      masterInitiativeTokens[localTokenIndex]['reportedTurn'] =
          playerReportedTurn;
    }
    processConditionTick(OculumConditionTickTrigger.endTurn);
    processConditionTick(OculumConditionTickTrigger.startTurn);
    tickStructuredAbilityCooldowns('turni', scheduleSave: false);
    applyAutomaticAshForTurnProgress(previous, playerReportedTurn);
    conditionsRevision.value++;
    programmaSalvataggio(invalidateCaches: false);
    sendRealtimeReportedTurn(
      sheetTag: tag,
      turn: playerReportedTurn,
      senderRole: realtimeIsMasterRole ? 'master' : 'player',
    );
    if (realtimeIsMasterRole) sendRealtimeInitiativeSnapshotIfPublished();
  }

  void processConditionRoll() {
    final stunned = getCondition('stordito');
    if (stunned != null) {
      aggiungiLog(
        t(
          'Stordito applica -3 a questo tiro valido e viene consumato.',
          'Stunned applies -3 to this valid roll and is consumed.',
        ),
      );
      removeCondition(stunned, force: true, expired: true);
    }
    processConditionTick(OculumConditionTickTrigger.roll);
  }

  void onOculumInstabilityTriggered(OculumConditionInstance instance) {
    final chance = instance.stage * 5;
    if (Random.secure().nextInt(100) >= chance) return;
    aggiungiLog(
      t(
        'Oculum Instabile si attiva ($chance%): hook registrato, nessuna conseguenza permanente automatica.',
        'Unstable Oculum triggers ($chance%): hook recorded, no automatic permanent consequence.',
      ),
    );
  }

  Future<void> confirmRemoveManualConditions() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('Disattiva condizioni', 'Disable conditions')),
        content: Text(
          t(
            'Rimuovere tutte le condizioni che possono essere disattivate manualmente?',
            'Remove every condition that can be manually disabled?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('Annulla', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('Rimuovi', 'Remove')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final removable = activeConditions
        .where((item) => item.removable)
        .toList(growable: false);
    if (removable.isEmpty) return;
    final affectedTargets = removable.expand(conditionTargetsFor).toSet();
    activeConditions.removeWhere((item) => item.removable);
    aggiungiLog(
      t(
        '${removable.length} condizioni manualmente rimovibili disattivate.',
        '${removable.length} manually removable conditions disabled.',
      ),
    );
    notifyConditionsChanged(affectedTargets);
    programmaSalvataggio(invalidateCaches: false);
  }

  Future<void> applyForceStateFromQuickConditions(
    _StatoForzaDef definition,
  ) async {
    if (definition.id == 'vero_bruciore_anima' &&
        !puoAttivareVeroBrucioreAnima()) {
      final message = t(
        'Vero Bruciore dell Anima richiede Resilienza in Fiamme allo stadio II o III.',
        'True Soul Burn requires Resilience Ablaze at stage II or III.',
      );
      setState(() => risultato = message);
      aggiungiLog(message);
      return;
    }
    if (statoForzaAttivo.isNotEmpty && statoForzaAttivo != definition.id) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(t('Sostituisci Stato di Forza', 'Replace Force State')),
          content: Text(
            t(
              'Sostituire ${statoForzaNomeAttivo()} con ${t(definition.nameIt, definition.nameEn)}?',
              'Replace ${statoForzaNomeAttivo()} with ${t(definition.nameIt, definition.nameEn)}?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t('Annulla', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(t('Sostituisci', 'Replace')),
            ),
          ],
        ),
      );
      if (replace != true) return;
      terminaStatoForzaAttivo(applicaEsitoEsplosione: false);
    }
    setState(() {
      statoForzaPronto = false;
      statoForzaAttivo = definition.id == 'niente' ? '' : definition.id;
      statoForzaTiriRimanenti = definition.id == 'esplosione_oculum' ? 9 : 0;
      final immediate = applicaEffettoImmediatoStatoForza(definition.id);
      risultato = definition.id == 'vero_bruciore_anima'
          ? immediate
          : t(
              'Stato di Forza: ${definition.nameIt}. ${definition.descriptionIt}',
              'Force State: ${definition.nameEn}. ${definition.descriptionEn}',
            );
      if (definition.id != 'vero_bruciore_anima' && immediate.isNotEmpty) {
        risultato += '\n$immediate';
      }
      aggiungiLog(risultato);
    });
    programmaSalvataggio(invalidateCaches: false);
    sendRealtimeHpChanged();
  }

  Future<void> showForceStatePicker() async {
    final selected = await showModalBottomSheet<_StatoForzaDef>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              t('Scegli Stato di Forza', 'Choose Force State'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            for (final definition in statoForzaDefs().where(
              (definition) =>
                  definition.id != 'vero_bruciore_anima' ||
                  puoAttivareVeroBrucioreAnima(),
            ))
              ListTile(
                leading: const Icon(Icons.bolt),
                title: Text(t(definition.nameIt, definition.nameEn)),
                subtitle: Text(
                  t(definition.descriptionIt, definition.descriptionEn),
                ),
                onTap: () => Navigator.pop(context, definition),
              ),
          ],
        ),
      ),
    );
    if (selected != null) await applyForceStateFromQuickConditions(selected);
  }

  Future<void> showAddConditionSheet() async {
    var category = OculumConditionCategory.physical;
    var query = '';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final filtered = oculumConditionCatalog
              .where((definition) {
                final matchesCategory = definition.category == category;
                final text =
                    '${definition.nameIt} ${definition.nameEn} ${definition.descriptionIt}'
                        .toLowerCase();
                return matchesCategory && text.contains(query.toLowerCase());
              })
              .toList(growable: false);
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * .82,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        labelText: t('Cerca condizione', 'Search condition'),
                      ),
                      onChanged: (value) => setSheetState(() => query = value),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        for (final value in OculumConditionCategory.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(conditionCategoryLabel(value)),
                              selected: category == value,
                              onSelected: (_) =>
                                  setSheetState(() => category = value),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final definition = filtered[index];
                        return ListTile(
                          leading: Icon(definition.icon),
                          title: Text(t(definition.nameIt, definition.nameEn)),
                          subtitle: Text(
                            t(
                              definition.descriptionIt,
                              definition.descriptionEn,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (definition.maxStage > 1)
                                Text(
                                  'I-${oculumRomanStage(definition.maxStage)}',
                                ),
                              if (modalitaMaster)
                                IconButton(
                                  tooltip: t(
                                    'Modifica effetto base',
                                    'Edit base effect',
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    showConditionMasterEditor(
                                      type: definition.id,
                                    );
                                  },
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            applyCondition(definition.id);
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          showCustomConditionDialog();
                        },
                        icon: const Icon(Icons.tune),
                        label: Text(
                          t('Condizione personalizzata', 'Custom condition'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> showCustomConditionDialog() async {
    final name = TextEditingController();
    final description = TextEditingController();
    final source = TextEditingController();
    final duration = TextEditingController(text: '3');
    final maxStage = TextEditingController(text: '1');
    final percent = TextEditingController(text: '0');
    final minimum = TextEditingController(text: '0');
    final maximum = TextEditingController(text: '0');
    final modifier = TextEditingController(text: '0');
    var category = OculumConditionCategory.special;
    var polarity = OculumConditionPolarity.neutral;
    var trigger = OculumConditionTickTrigger.none;
    var stackMode = OculumConditionStackMode.refreshDuration;
    var scaling = OculumConditionDifficultyScaling.none;
    var removable = true;
    final affectedTargets = <OculumConditionTarget>{};
    final created = await showDialog<OculumConditionInstance>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(t('Condizione personalizzata', 'Custom condition')),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: name,
                    decoration: InputDecoration(labelText: t('Nome', 'Name')),
                  ),
                  TextField(
                    controller: description,
                    decoration: InputDecoration(
                      labelText: t('Descrizione', 'Description'),
                    ),
                  ),
                  TextField(
                    controller: source,
                    decoration: InputDecoration(
                      labelText: t('Fonte', 'Source'),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: maxStage,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: t('Stadio massimo', 'Maximum stage'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: duration,
                          decoration: InputDecoration(
                            labelText: t('Durata', 'Duration'),
                            helperText: '3 / 1d10 / 2d6+1 / 1d8-1',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      t('Valori influenzati', 'Affected values'),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final target in OculumConditionTarget.values)
                        FilterChip(
                          selected: affectedTargets.contains(target),
                          label: Text(conditionTargetLabel(target)),
                          onSelected: (selected) => setDialogState(() {
                            if (selected) {
                              affectedTargets.add(target);
                            } else {
                              affectedTargets.remove(target);
                            }
                          }),
                        ),
                    ],
                  ),
                  TextField(
                    controller: modifier,
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: t(
                        'Modificatore per i valori selezionati',
                        'Modifier for selected values',
                      ),
                      helperText: t(
                        'Il valore base non viene mai modificato.',
                        'The base value is never changed.',
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: percent,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Percentuale',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: minimum,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Minimo',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: maximum,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Massimo',
                          ),
                        ),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<OculumConditionCategory>(
                    initialValue: category,
                    decoration: InputDecoration(
                      labelText: t('Categoria', 'Category'),
                    ),
                    items: OculumConditionCategory.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(conditionCategoryLabel(value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => category = value ?? category),
                  ),
                  DropdownButtonFormField<OculumConditionPolarity>(
                    initialValue: polarity,
                    decoration: InputDecoration(labelText: t('Tipo', 'Type')),
                    items: OculumConditionPolarity.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => polarity = value ?? polarity),
                  ),
                  DropdownButtonFormField<OculumConditionTickTrigger>(
                    initialValue: trigger,
                    decoration: const InputDecoration(labelText: 'Tick'),
                    items: OculumConditionTickTrigger.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => trigger = value ?? trigger),
                  ),
                  DropdownButtonFormField<OculumConditionStackMode>(
                    initialValue: stackMode,
                    decoration: const InputDecoration(labelText: 'Stack mode'),
                    items: OculumConditionStackMode.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => stackMode = value ?? stackMode),
                  ),
                  DropdownButtonFormField<OculumConditionDifficultyScaling>(
                    initialValue: scaling,
                    decoration: InputDecoration(
                      labelText: t(
                        'Scala con difficolta',
                        'Scale with difficulty',
                      ),
                    ),
                    items: OculumConditionDifficultyScaling.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => scaling = value ?? scaling),
                  ),
                  SwitchListTile(
                    value: removable,
                    title: Text(t('Staccabile', 'Removable')),
                    onChanged: (value) =>
                        setDialogState(() => removable = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('Annulla', 'Cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isEmpty) return;
                final id =
                    'custom_${name.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';
                Navigator.pop(
                  context,
                  OculumConditionInstance(
                    id: '${id}_${DateTime.now().microsecondsSinceEpoch}',
                    conditionType: id,
                    category: category,
                    duration:
                        rollEffectDurationFormula(duration.text) ??
                        max(0, int.tryParse(duration.text) ?? 0),
                    tickTrigger: trigger,
                    removable: removable,
                    source: source.text.trim(),
                    metadata: <String, dynamic>{
                      'name': name.text.trim(),
                      'description': description.text.trim(),
                      'nameIt': name.text.trim(),
                      'nameEn': name.text.trim(),
                      'descriptionIt': description.text.trim(),
                      'descriptionEn': description.text.trim(),
                      'durationFormula': duration.text.trim(),
                      'polarity': polarity.name,
                      'maxStage': max(1, int.tryParse(maxStage.text) ?? 1),
                      'stackMode': stackMode.name,
                      'percent':
                          double.tryParse(percent.text.replaceAll(',', '.')) ??
                          0,
                      'minimum': int.tryParse(minimum.text) ?? 0,
                      'maximum': int.tryParse(maximum.text) ?? 0,
                      'difficultyScaling': scaling.name,
                      'affectedTargets': affectedTargets
                          .map((target) => target.name)
                          .toList(growable: false),
                      'modifiers': <String, double>{
                        for (final target in affectedTargets)
                          target.name:
                              double.tryParse(
                                modifier.text.replaceAll(',', '.'),
                              ) ??
                              0,
                      },
                    },
                  ),
                );
              },
              child: Text(t('Aggiungi', 'Add')),
            ),
          ],
        ),
      ),
    );
    for (final controller in <TextEditingController>[
      name,
      description,
      source,
      duration,
      maxStage,
      percent,
      minimum,
      maximum,
      modifier,
    ]) {
      controller.dispose();
    }
    if (created != null) {
      if (modalitaMaster) {
        conditionDefinitionOverrides[created.conditionType] =
            Map<String, dynamic>.from(created.metadata);
      }
      applyCustomCondition(created);
    }
  }

  Future<void> showConditionMasterEditor({
    required String type,
    OculumConditionInstance? instance,
  }) async {
    final definition = oculumConditionDefinition(type);
    final current = conditionDefinitionOverrides[type] ?? <String, dynamic>{};
    final name = TextEditingController(
      text:
          '${current['nameIt'] ?? definition?.nameIt ?? instance?.metadata['nameIt'] ?? instance?.metadata['name'] ?? ''}',
    );
    final description = TextEditingController(
      text:
          '${current['descriptionIt'] ?? definition?.descriptionIt ?? instance?.metadata['description'] ?? ''}',
    );
    final baseDuration = TextEditingController(
      text:
          '${current['durationFormula'] ?? instance?.metadata['durationFormula'] ?? definition?.defaultDuration ?? 3}',
    );
    final difficultyRaw = current['durationByDifficulty'];
    final difficultyMap = difficultyRaw is Map
        ? Map<String, dynamic>.from(difficultyRaw)
        : <String, dynamic>{};
    final difficultyControllers = <String, TextEditingController>{
      for (final difficulty in const <String>[
        'facile',
        'normale',
        'difficile',
        'oculum',
      ])
        difficulty: TextEditingController(
          text: '${difficultyMap[difficulty] ?? ''}',
        ),
    };
    final modifier = TextEditingController(
      text:
          '${(current['modifiers'] is Map ? (current['modifiers'] as Map).values.firstOrNull : null) ?? 0}',
    );
    final affectedTargets = <OculumConditionTarget>{
      ...?definition?.affectedTargets,
    };
    if (instance != null) {
      affectedTargets.addAll(conditionTargetsFor(instance));
    }
    final saved = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            definition == null
                ? t('Modifica effetto Homebrew', 'Edit Homebrew effect')
                : t('Modifica effetto base', 'Edit base effect'),
          ),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: name,
                    decoration: InputDecoration(labelText: t('Nome', 'Name')),
                  ),
                  TextField(
                    controller: description,
                    minLines: 2,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: t('Spiegazione completa', 'Full explanation'),
                    ),
                  ),
                  TextField(
                    controller: baseDuration,
                    decoration: InputDecoration(
                      labelText: t('Durata base', 'Base duration'),
                      helperText: '3 / 1d10 / 2d6+1 / 1d8-1',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      t('Durata per difficolta', 'Duration by difficulty'),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final difficulty in difficultyControllers.keys)
                        SizedBox(
                          width: 132,
                          child: TextField(
                            controller: difficultyControllers[difficulty],
                            decoration: InputDecoration(
                              labelText: campaignDifficultyLabel(difficulty),
                              hintText: baseDuration.text,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      t('Valori influenzati', 'Affected values'),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final target in OculumConditionTarget.values)
                        FilterChip(
                          selected: affectedTargets.contains(target),
                          label: Text(conditionTargetLabel(target)),
                          onSelected: (selected) => setDialogState(() {
                            if (selected) {
                              affectedTargets.add(target);
                            } else {
                              affectedTargets.remove(target);
                            }
                          }),
                        ),
                    ],
                  ),
                  TextField(
                    controller: modifier,
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: t(
                        'Modificatore sui valori scelti',
                        'Modifier on chosen values',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('Annulla', 'Cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isEmpty) return;
                final parsedModifier =
                    double.tryParse(modifier.text.replaceAll(',', '.')) ?? 0;
                Navigator.pop(context, <String, dynamic>{
                  'nameIt': name.text.trim(),
                  'nameEn': name.text.trim(),
                  'descriptionIt': description.text.trim(),
                  'descriptionEn': description.text.trim(),
                  'durationFormula': baseDuration.text.trim(),
                  'durationByDifficulty': <String, String>{
                    for (final entry in difficultyControllers.entries)
                      if (entry.value.text.trim().isNotEmpty)
                        entry.key: entry.value.text.trim(),
                  },
                  'affectedTargets': affectedTargets
                      .map((target) => target.name)
                      .toList(growable: false),
                  'modifiers': <String, double>{
                    for (final target in affectedTargets)
                      target.name: parsedModifier,
                  },
                  if (definition == null) 'custom': true,
                });
              },
              child: Text(t('Salva modifica', 'Save change')),
            ),
          ],
        ),
      ),
    );
    for (final controller in <TextEditingController>[
      name,
      description,
      baseDuration,
      modifier,
      ...difficultyControllers.values,
    ]) {
      controller.dispose();
    }
    if (saved == null) return;
    conditionDefinitionOverrides[type] = saved;
    if (instance != null) instance.metadata.addAll(saved);
    notifyConditionsChanged(
      instance == null
          ? definition?.affectedTargets
          : conditionTargetsFor(instance),
    );
    programmaSalvataggio(invalidateCaches: false);
  }

  void resetConditionDefinition(
    String type, {
    OculumConditionInstance? instance,
  }) {
    final removed = conditionDefinitionOverrides.remove(type);
    if (removed == null) return;
    if (instance != null) {
      for (final key in removed.keys) {
        instance.metadata.remove(key);
      }
    }
    notifyConditionsChanged(
      instance == null
          ? oculumConditionDefinition(type)?.affectedTargets
          : conditionTargetsFor(instance),
    );
    programmaSalvataggio(invalidateCaches: false);
  }

  Future<void> showConditionContextMenu(
    OculumConditionInstance instance,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: Text(t('Durata fissa o a dadi', 'Fixed or dice duration')),
              subtitle: const Text('3 / 1d10 / 2d6+1 / 1d8-1'),
              onTap: () {
                Navigator.pop(context);
                showConditionDurationEditor(instance);
              },
            ),
            if (modalitaMaster)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(t('Modifica questo effetto', 'Edit this effect')),
                onTap: () {
                  Navigator.pop(context);
                  showConditionMasterEditor(
                    type: instance.conditionType,
                    instance: instance,
                  );
                },
              ),
            if (modalitaMaster &&
                conditionDefinitionOverrides.containsKey(
                  instance.conditionType,
                ))
              ListTile(
                leading: const Icon(Icons.restore),
                title: Text(t('Ripristina predefinito', 'Restore default')),
                onTap: () {
                  Navigator.pop(context);
                  resetConditionDefinition(
                    instance.conditionType,
                    instance: instance,
                  );
                },
              ),
            if (instance.removable || modalitaMaster)
              ListTile(
                leading: Icon(
                  instance.removable
                      ? Icons.close
                      : Icons.admin_panel_settings_outlined,
                ),
                title: Text(
                  instance.removable
                      ? t('Rimuovi condizione', 'Remove condition')
                      : t(
                          'Rimozione forzata Master',
                          'Game Master forced removal',
                        ),
                ),
                subtitle: !instance.removable
                    ? Text(
                        t(
                          'Ignora il blocco di rimozione previsto dalla condizione.',
                          'Ignores the removal lock defined by the condition.',
                        ),
                      )
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  removeCondition(instance, force: modalitaMaster);
                },
              ),
          ],
        ),
      ),
    );
  }

  String conditionCategoryLabel(OculumConditionCategory category) {
    return switch (category) {
      OculumConditionCategory.physical => t('Fisiche', 'Physical'),
      OculumConditionCategory.mental => t('Mentali', 'Mental'),
      OculumConditionCategory.elemental => t('Elementali', 'Elemental'),
      OculumConditionCategory.oculum => 'Oculum',
      OculumConditionCategory.positive => t('Positive', 'Positive'),
      OculumConditionCategory.special => t('Speciali', 'Special'),
    };
  }

  String conditionTriggerLabel(OculumConditionTickTrigger trigger) =>
      switch (trigger) {
        OculumConditionTickTrigger.startTurn => t(
          'inizio turno',
          'start of turn',
        ),
        OculumConditionTickTrigger.endTurn => t('fine turno', 'end of turn'),
        OculumConditionTickTrigger.roll => t('tiro', 'roll'),
        OculumConditionTickTrigger.action => t('azione', 'action'),
        OculumConditionTickTrigger.damageReceived => t(
          'danno ricevuto',
          'damage received',
        ),
        OculumConditionTickTrigger.damageDealt => t(
          'danno inflitto',
          'damage dealt',
        ),
        OculumConditionTickTrigger.shortRest => t('riposo breve', 'short rest'),
        OculumConditionTickTrigger.longRest => t('riposo lungo', 'long rest'),
        OculumConditionTickTrigger.specificEvent => t(
          'evento specifico',
          'specific event',
        ),
        OculumConditionTickTrigger.none => t('nessuno', 'none'),
      };

  Widget quickConditionCard(OculumConditionInstance instance) {
    final definition = oculumConditionDefinition(instance.conditionType);
    final override = conditionDefinitionOverrides[instance.conditionType];
    final maxStage =
        definition?.maxStage ??
        max(1, readIntValue(instance.metadata['maxStage'], fallback: 1));
    final color = instance.conditionType == 'oculum_in_fiamme_viola'
        ? Colors.deepPurpleAccent
        : (definition?.polarity ?? OculumConditionPolarity.neutral) ==
              OculumConditionPolarity.positive
        ? Colors.greenAccent
        : Colors.redAccent;
    final overrideDescription = t(
      '${override?['descriptionIt'] ?? ''}',
      '${override?['descriptionEn'] ?? override?['descriptionIt'] ?? ''}',
    ).trim();
    final description = instance.conditionType == 'aumento_difficolta'
        ? difficultyIncreaseFightDescription()
        : overrideDescription.isNotEmpty
        ? overrideDescription
        : definition == null
        ? '${instance.metadata['descriptionIt'] ?? instance.metadata['description'] ?? ''}'
        : t(definition.descriptionIt, definition.descriptionEn);
    final effective = calculateConditionEffect(instance);
    final card = gothicPanel(
      borderColor: color.withValues(alpha: .7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(definition?.icon ?? Icons.tune, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  conditionLabel(instance).toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              if (modalitaMaster)
                IconButton(
                  tooltip: t('Modifica effetto', 'Edit effect'),
                  onPressed: () => showConditionMasterEditor(
                    type: instance.conditionType,
                    instance: instance,
                  ),
                  icon: const Icon(Icons.edit_outlined),
                ),
              if (instance.removable)
                IconButton(
                  tooltip: t('Rimuovi', 'Remove'),
                  onPressed: () => removeCondition(instance),
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
          Text(description),
          if (maxStage > 1) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  onPressed: () => decreaseConditionStage(instance),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Expanded(
                  child: SegmentedButton<int>(
                    style: ButtonStyle(
                      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
                        EdgeInsets.symmetric(horizontal: 6),
                      ),
                      minimumSize: const WidgetStatePropertyAll<Size>(
                        Size(32, 38),
                      ),
                      textStyle: const WidgetStatePropertyAll<TextStyle>(
                        TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ),
                    segments: [
                      for (var i = 1; i <= maxStage; i++)
                        ButtonSegment<int>(
                          value: i,
                          label: Text(oculumRomanStage(i)),
                        ),
                    ],
                    selected: <int>{instance.stage},
                    showSelectedIcon: false,
                    onSelectionChanged: (value) {
                      final next = value.first;
                      while (instance.stage < next) {
                        final before = instance.stage;
                        increaseConditionStage(instance);
                        if (instance.stage == before) break;
                      }
                      while (instance.stage > next) {
                        decreaseConditionStage(instance);
                      }
                    },
                  ),
                ),
                IconButton(
                  onPressed: instance.stage < maxStage
                      ? () => increaseConditionStage(instance)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (instance.duration > 0)
                Chip(
                  label: Text(
                    '${t('Durata', 'Duration')}: ${instance.duration}',
                  ),
                ),
              if (instance.stacks > 1)
                Chip(
                  label: Text('${t('Stack', 'Stacks')}: ${instance.stacks}'),
                ),
              if (instance.tickTrigger != OculumConditionTickTrigger.none)
                Chip(
                  label: Text(
                    'Tick: ${conditionTriggerLabel(instance.tickTrigger)}',
                  ),
                ),
              if (instance.source.trim().isNotEmpty)
                Chip(
                  label: Text('${t('Fonte', 'Source')}: ${instance.source}'),
                ),
              if (effective > 0)
                Chip(
                  label: Text(
                    '${t('Effetto attuale', 'Current effect')}: $effective',
                  ),
                ),
            ],
          ),
          if ((definition?.contextActionIt ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => decreaseConditionStage(
                instance,
                amount: normalizedCampaignDifficulty() == 'facile'
                    ? maxStage
                    : min(2, maxStage),
              ),
              icon: const Icon(Icons.water_drop),
              label: Text(
                t(definition!.contextActionIt, definition.contextActionEn),
              ),
            ),
          ],
          if (instance.conditionType == 'aumento_difficolta') ...[
            const SizedBox(height: 10),
            Text(
              t('Difficoltà del mostro', 'Enemy difficulty'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final difficulty in const <String>[
                  'facile',
                  'normale',
                  'difficile',
                  'oculum',
                ])
                  ChoiceChip(
                    selected:
                        '${instance.metadata['enemyDifficulty'] ?? ''}' ==
                        difficulty,
                    label: Text(campaignDifficultyLabel(difficulty)),
                    onSelected: (_) => setFightEnemyDifficulty(difficulty),
                  ),
              ],
            ),
          ],
          if (instance.conditionType == 'oculum_in_fiamme_viola') ...[
            const SizedBox(height: 10),
            Text(
              t('Costo del prossimo turno', 'Next turn cost'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final resource in const <String>[
                  'oculum',
                  'volonta',
                  'materia',
                ])
                  ChoiceChip(
                    selected:
                        '${instance.metadata['nextSpendResource'] ?? 'vita'}' ==
                        resource,
                    label: Text(structuredEffectResourceLabel(resource)),
                    onSelected: (_) {
                      instance.metadata['nextSpendResource'] = resource;
                      notifyConditionsChanged(conditionTargetsFor(instance));
                      programmaSalvataggio(invalidateCaches: false);
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onSecondaryTapDown: (_) => showConditionContextMenu(instance),
      onLongPress: () => showConditionContextMenu(instance),
      child: card,
    );
  }

  Widget quickSpecialStateCard({
    required Color color,
    required IconData icon,
    required String title,
    required String description,
    required bool active,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    Widget? footer,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14),
        child: gothicPanel(
          borderColor: active ? color : color.withValues(alpha: .4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  if (active) Chip(label: Text(t('ATTIVO', 'ACTIVE'))),
                ],
              ),
              const SizedBox(height: 8),
              Text(description),
              if (footer != null) ...[const SizedBox(height: 10), footer],
            ],
          ),
        ),
      ),
    );
  }

  Widget quickOculumFlameConditionCard(String type) {
    final definition = oculumConditionDefinition(type)!;
    final instance = getCondition(type);
    final active = instance != null;
    final stage = instance?.stage ?? 1;
    final multiplier = oculumFlameRewardMultiplier(
      normalizedCampaignDifficulty(),
    );
    final color = switch (type) {
      'resilienza_in_fiamme' => Colors.greenAccent,
      'volonta_in_fiamme' => Colors.redAccent,
      'oculum_in_fiamme_viola' => Colors.deepPurpleAccent,
      _ => Colors.lightBlueAccent,
    };
    final target = switch (type) {
      'resilienza_in_fiamme' => t('cura gli HP', 'heals HP'),
      'volonta_in_fiamme' => t(
        'ripristina Volonta e l eccesso e temporaneo',
        'restores Will and makes overflow temporary',
      ),
      'oculum_in_fiamme_viola' => t(
        'consuma il 3% degli HP e rigenera Oculum; i tasti della condizione impostano una spesa alternativa per il prossimo turno',
        'spends 3% HP and regenerates Oculum; its condition buttons set an alternate cost for the next turn',
      ),
      _ => t(
        'ripristina Materia e l eccesso e temporaneo',
        'restores Matter and makes overflow temporary',
      ),
    };
    return quickSpecialStateCard(
      color: color,
      icon: definition.icon,
      title: t(definition.nameIt, definition.nameEn),
      active: active,
      description: type == 'oculum_in_fiamme_viola'
          ? t(
              'Stadio ${oculumRomanStage(stage)}: $target. Deviazione Volonta/Materia: ${oculumVioletFlameDiversionChance(stage)}%.',
              'Stage ${oculumRomanStage(stage)}: $target. Will/Matter diversion: ${oculumVioletFlameDiversionChance(stage)}%.',
            )
          : t(
              'Stadio ${oculumRomanStage(stage)}: ogni turno -${oculumFlameTurnPercent(stage)}% Oculum attuale (min 1), poi $target pari alla spesa x$multiplier. Si spegne al 15% Oculum o meno.',
              'Stage ${oculumRomanStage(stage)}: every turn -${oculumFlameTurnPercent(stage)}% current Oculum (min 1), then $target equal to spent Oculum x$multiplier. It ends at 15% Oculum or less.',
            ),
      onTap: () {
        final existing = getCondition(type);
        if (existing != null) {
          removeCondition(existing, force: true);
        } else {
          applyCondition(
            type,
            duration: 0,
            source: t('Condizioni veloci', 'Quick conditions'),
          );
        }
      },
    );
  }

  Widget quickConditionsPage() {
    return ValueListenableBuilder<int>(
      valueListenable: conditionsRevision,
      builder: (context, revision, child) {
        final profile = oculumConditionDifficultyProfile(
          normalizedCampaignDifficulty(),
        );
        final specialCount =
            (sottoStress ? 1 : 0) +
            (oculumAddormentato ? 1 : 0) +
            (consumoElevato ? 1 : 0);
        final hasRemovableConditions = activeConditions.any(
          (condition) => condition.removable,
        );
        return responsivePageList(
          pageKey: 'quick_conditions',
          maxColumns: 2,
          minColumnWidth: 350,
          masonryColumns: true,
          fullWidthIndexes: const <int>{0, 5},
          children: [
            gothicPanel(
              borderColor: tertiaryColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${t('Condizioni attive', 'Active conditions')}: ${activeConditions.length}'
                          '${specialCount > 0 ? ' · ${t('stati speciali', 'special states')}: $specialCount' : ''}',
                          style: TextStyle(
                            color: tertiaryColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: t('Guida', 'Guide'),
                        onPressed: showConditionsGuide,
                        icon: const Icon(Icons.menu_book),
                      ),
                      FilledButton.icon(
                        onPressed: advanceConditionTurn,
                        icon: const Icon(Icons.add),
                        label: Text(
                          '${t('Turno', 'Turn')} ${playerReportedTurn + 1}',
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final condition in activeConditions)
                        Chip(label: Text(conditionLabel(condition))),
                      if (oculumAddormentato)
                        Chip(
                          label: Text(
                            t('Oculum addormentato', 'Sleeping Oculum'),
                          ),
                        ),
                      if (sottoStress)
                        Chip(label: Text(t('Sotto stress', 'Under stress'))),
                      if (consumoElevato)
                        Chip(
                          label: Text(t('Consumo elevato', 'High consumption')),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${t('Difficolta', 'Difficulty')}: ${profile.id.toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(t(profile.descriptionIt, profile.descriptionEn)),
                  Text(
                    '${t('Stato di Forza', 'Force State')}: ${statoForzaNomeAttivo()}',
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: hasRemovableConditions
                        ? confirmRemoveManualConditions
                        : null,
                    icon: const Icon(Icons.layers_clear),
                    label: Text(
                      t(
                        'Rimuovi condizioni rimovibili',
                        'Remove removable conditions',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            quickSpecialStateCard(
              color: Colors.orangeAccent,
              icon: Icons.psychology_alt,
              title: t('Sotto stress', 'Under stress'),
              active: sottoStress,
              description: t(
                '+15% probabilita di Cenere. Ogni Livello + 1 punti consumati sulla stessa statistica genera 1 Cenere.',
                '+15% Ash chance. Every Level + 1 points spent on the same stat generates 1 Ash.',
              ),
              onTap: () {
                sottoStress = !sottoStress;
                sottoStressManuale = sottoStress;
                if (!sottoStress) stressStatConsumptionProgress.clear();
                aggiungiLog(
                  t(
                    sottoStress
                        ? 'Stato applicato: Sotto stress.'
                        : 'Stato rimosso: Sotto stress.',
                    sottoStress
                        ? 'Condition applied: Under stress.'
                        : 'Condition removed: Under stress.',
                  ),
                );
                notifyConditionsChanged(<OculumConditionTarget>{
                  OculumConditionTarget.resilienza,
                  OculumConditionTarget.volonta,
                  OculumConditionTarget.materia,
                  OculumConditionTarget.oculum,
                  OculumConditionTarget.tiri,
                });
                programmaSalvataggio(invalidateCaches: false);
              },
              footer: Wrap(
                spacing: 6,
                children: [
                  for (final key in <String>[
                    'resilienza',
                    'volonta',
                    'materia',
                    'oculum',
                  ])
                    Chip(
                      label: Text(
                        '${key.substring(0, 3).toUpperCase()} ${stressStatConsumptionProgress[key] ?? 0} / ${max(1, leggiNumero(livelloController) + 1)}',
                      ),
                    ),
                ],
              ),
            ),
            quickSpecialStateCard(
              color: Colors.indigoAccent,
              icon: Icons.visibility_off,
              title: t('Oculum addormentato', 'Sleeping Oculum'),
              active: oculumAddormentato,
              description: oculumAddormentato
                  ? t(
                      'OCULUM ADDORMENTATO - Brevi $oculumAddormentatoRiposiBrevi/2 - Lunghi $oculumAddormentatoRiposiLunghi/2. Tutti i recuperi sono dimezzati per difetto.',
                      'SLEEPING OCULUM - Short $oculumAddormentatoRiposiBrevi/2 - Long $oculumAddormentatoRiposiLunghi/2. All recovery is halved, rounded down.',
                    )
                  : t(
                      'Addormenta Oculum: azzera immediatamente Oculum attuale e temporaneo.',
                      'Put Oculum to sleep: immediately clears current and temporary Oculum.',
                    ),
              onTap: oculumAddormentato
                  ? confermaRisvegliaOculum
                  : attivaOculumAddormentato,
            ),
            quickOculumFlameConditionCard('resilienza_in_fiamme'),
            quickOculumFlameConditionCard('volonta_in_fiamme'),
            quickOculumFlameConditionCard('materia_in_fiamme'),
            quickOculumFlameConditionCard('oculum_in_fiamme_viola'),
            quickSpecialStateCard(
              color: Colors.deepOrangeAccent,
              icon: Icons.local_fire_department,
              title: t('Consumo elevato', 'High consumption'),
              active: consumoElevato,
              description: t(
                'Ogni tiro valido consuma 1 punto della statistica associata. RES/VOL minimo 1, MAT/OCU minimo 0. Fortuna e Nodo mantengono le loro regole.',
                'Every valid roll spends 1 point from the linked stat. RES/WIL minimum 1, MAT/OCU minimum 0. Luck and Node retain their rules.',
              ),
              onTap: () {
                consumoElevato = !consumoElevato;
                aggiungiLog(
                  t(
                    consumoElevato
                        ? 'Consumo elevato attivato.'
                        : 'Consumo elevato disattivato.',
                    consumoElevato
                        ? 'High consumption activated.'
                        : 'High consumption disabled.',
                  ),
                );
                notifyConditionsChanged(<OculumConditionTarget>{
                  OculumConditionTarget.resilienza,
                  OculumConditionTarget.volonta,
                  OculumConditionTarget.materia,
                  OculumConditionTarget.oculum,
                  OculumConditionTarget.tiri,
                });
                programmaSalvataggio(invalidateCaches: false);
              },
            ),
            quickSpecialStateCard(
              color: Colors.amberAccent,
              icon: Icons.bolt,
              title: t('Stato di Forza', 'Force State'),
              active: statoForzaAttivo.isNotEmpty,
              description:
                  '${statoForzaNomeAttivo()}\n${statoForzaDescrizioneAttiva()}\nHP ${hpCorrenti()} / ${maxHp()} - ${t('Soglia', 'Threshold')}: ${sogliaStatoForzaHp()} HP${statoForzaTiriRimanenti > 0 ? ' - ${t('Tiri', 'Rolls')}: $statoForzaTiriRimanenti' : ''}',
              onTap: () =>
                  applyForceStateFromQuickConditions(pescaStatoForza()),
              onLongPress: showForceStatePicker,
              footer: statoForzaAttivo.isEmpty
                  ? null
                  : OutlinedButton(
                      onPressed: () {
                        setState(() {
                          final ending = terminaStatoForzaAttivo();
                          if (ending.isNotEmpty) aggiungiLog(ending);
                        });
                        programmaSalvataggio(invalidateCaches: false);
                      },
                      child: Text(
                        t('Reset Stato di Forza', 'Reset Force State'),
                      ),
                    ),
            ),
            Row(
              children: [
                Expanded(child: sectionTitle(t('Condizioni', 'Conditions'))),
                FilledButton.icon(
                  onPressed: showAddConditionSheet,
                  icon: const Icon(Icons.add),
                  label: Text(t('Aggiungi condizione', 'Add condition')),
                ),
              ],
            ),
            if (activeConditions.isEmpty)
              gothicPanel(
                borderColor: tertiaryColor.withValues(alpha: .4),
                child: Text(
                  t(
                    'Nessuna condizione attiva. Usa + Aggiungi condizione per applicarne una.',
                    'No active condition. Use + Add condition to apply one.',
                  ),
                ),
              )
            else
              for (final condition in activeConditions)
                quickConditionCard(condition),
          ],
        );
      },
    );
  }

  Future<void> showConditionsGuide() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('Guida alle Condizioni', 'Conditions Guide')),
        content: SingleChildScrollView(
          child: Text(
            t(
              'Una condizione e un effetto persistente. Lo stadio indica la gravita e il Tick l evento reale che la fa reagire. Premi a lungo o usa il click destro sull effetto o sul suo indicatore per impostare durata, modifica Master o ripristino. Il parser accetta @effetto:Confusione(1d10+2), anche con durata fissa o 2d6-1. Il pulsante + Turno avanza il turno reale e riduce le durate. Gli indicatori con icona Material mostrano gli effetti direttamente su statistiche, risorse, Skill, Art, Titoli e combattimento. I buff positivi sono piu forti alle difficolta personaggio basse. Aumento difficolta Fight confronta la difficolta personaggio con quella del mostro e centralizza penalita, probabilita e ricompense senza cambiare i valori base.',
              'A condition is a persistent effect. Stage shows severity and Tick is the real event that triggers it. Long-press or right-click an effect or indicator to set duration, edit it as Master, or restore defaults. The parser accepts @effetto:Confusione(1d10+2), fixed durations, and formulas such as 2d6-1. + Turn advances the real turn and reduces durations. Material-icon indicators show effects directly where they apply. Positive buffs are stronger at lower character difficulties. Fight Difficulty Increase centralizes penalties, chances and rewards without changing base values.',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('Chiudi', 'Close')),
          ),
        ],
      ),
    );
  }
}
