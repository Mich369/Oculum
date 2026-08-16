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
              constraints: const BoxConstraints(minHeight: 24),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: tertiaryColor.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: tertiaryColor.withValues(alpha: .55)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt, size: 13, color: tertiaryColor),
                  const SizedBox(width: 2),
                  Text(
                    '${conditions.length + specialStates.length}',
                    style: TextStyle(
                      color: tertiaryColor,
                      fontSize: 10,
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
                content: TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: t('Turni o dado', 'Turns or die'),
                    hintText: '3 · 1d10 · 2d6+1 turni',
                    errorText: validationError,
                    helperText: t(
                      '0 = senza scadenza. I dadi applicano anche il modificatore critico dei dadi rapidi.',
                      '0 = no expiry. Dice also apply the quick-dice critical modifier.',
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(t('Annulla', 'Cancel')),
                  ),
                  FilledButton.icon(
                    icon: const Icon(Icons.casino),
                    onPressed: () {
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
    instance.durationType = OculumConditionDurationType.turns;
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
          if (override != null) ...override,
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

    final existing = getCondition(type);
    final int targetStage = existing == null
        ? stage.clamp(1, definition.maxStage).toInt()
        : definition.stackMode == OculumConditionStackMode.increaseStage
        ? min(definition.maxStage, existing.stage + max(1, stage)).toInt()
        : stage.clamp(1, definition.maxStage).toInt();
    final overrideFormula = duration == null
        ? conditionOverrideDurationFormula(type)
        : '';
    final overrideDuration = overrideFormula.isEmpty
        ? null
        : rollEffectDurationFormula(overrideFormula);
    final scaledDuration = oculumConditionScaledDuration(
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
          if (override != null) ...override,
          if (overrideFormula.isNotEmpty) 'durationFormula': overrideFormula,
          ...?metadata,
        },
      );
      activeConditions.add(instance);
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
            stage.clamp(1, definition.maxStage),
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

  void increaseConditionStage(OculumConditionInstance instance) {
    final definition = oculumConditionDefinition(instance.conditionType);
    final maxStage =
        definition?.maxStage ??
        max(1, readIntValue(instance.metadata['maxStage'], fallback: 1));
    if (instance.stage >= maxStage) return;
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
    return result.round();
  }

  int applyConditionIncomingDamage(int damage) {
    if (damage <= 0 || statoForzaRimuoveMalus()) return damage;
    final exposed = getCondition('esposto');
    final vulnerable = hasCondition('vulnerabile');
    final difficultyIncrease = getCondition('aumento_difficolta');
    if (exposed == null && !vulnerable && difficultyIncrease == null) {
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
    final increase = vulnerabilityIncrease + difficultyIncreaseDamage;
    if (exposed != null) removeCondition(exposed, force: true, expired: true);
    return damage + increase;
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

  void processConditionTick(OculumConditionTickTrigger trigger) {
    if (activeConditions.isEmpty) return;
    final snapshot = List<OculumConditionInstance>.from(activeConditions);
    var mutated = false;
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
          instance.conditionType == 'oculum_instabile') {
        onOculumInstabilityTriggered(instance);
      }
      if (instance.duration > 0 &&
          instance.durationType == OculumConditionDurationType.turns &&
          trigger == OculumConditionTickTrigger.endTurn) {
        instance.duration--;
        mutated = true;
        if (instance.duration <= 0) {
          removeCondition(instance, force: true, expired: true);
        }
      }
    }
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
      risultato = t(
        'Stato di Forza: ${definition.nameIt}. ${definition.descriptionIt}',
        'Force State: ${definition.nameEn}. ${definition.descriptionEn}',
      );
      if (immediate.isNotEmpty) risultato += '\n$immediate';
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
            for (final definition in statoForzaDefs())
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
    final color =
        (definition?.polarity ?? OculumConditionPolarity.neutral) ==
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
                        increaseConditionStage(instance);
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
