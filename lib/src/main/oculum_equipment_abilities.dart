part of '../../main.dart';

CharacterSkill oculumPosteaBootsAbility() {
  final form = CharacterSkillForm(
    nome: 'I',
    tipo: 'Difesa',
    livello: '0',
    costo: 'Gratuito · nessuna Azione o Reazione',
    costoStrutturato: OculumSkillCost(
      resource: 'nessuna',
      amountExpression: '0',
    ),
    cooldown: '5 turni',
    cooldownStrutturato: OculumAbilityCooldown(amount: 5),
    descrizione:
        'Fuori fight: doppio salto gratuito. In fight: reroll CM +3 dopo la prima CM fallita. CD 5 turni, senza Azioni o Reazioni.',
    effettiStrutturati: [
      OculumStructuredEffect(type: 'difesa', valueExpression: '3'),
    ],
    oculumLimitiConfiguratiManualmente: true,
  );
  return CharacterSkill(
    nome: 'Doppio salto / Reroll CM gratuito',
    costo: form.costo,
    cooldown: form.cooldown,
    tipo: 'Difesa',
    descrizione: form.descrizione,
    forme: [form],
  );
}

CharacterSkill oculumPosteaMitraAbility(int damage) {
  final form = CharacterSkillForm(
    nome: 'I',
    tipo: 'Attacco',
    livello: '0',
    costo: 'Gratuito',
    costoStrutturato: OculumSkillCost(
      resource: 'nessuna',
      amountExpression: '0',
    ),
    descrizione:
        '+$damage danni soltanto usando il Mitra: solo questo bonus ignora le resistenze. Difesa e Scudi si applicano.',
    effettiStrutturati: [
      OculumStructuredEffect(
        id: 'postea_mitra_damage',
        type: 'danno',
        recipient: 'nemico',
        valueExpression: '$damage',
        mode: 'prossima_azione',
        bypassResistance: true,
      ),
    ],
    oculumLimitiConfiguratiManualmente: true,
  );
  return CharacterSkill(
    nome: 'Mitra runico Postea',
    costo: form.costo,
    cooldown: form.cooldown,
    tipo: 'Attacco',
    descrizione: form.descrizione,
    forme: [form],
  );
}

CharacterSkill oculumForestDemonArmorAbility(int level) {
  final form = CharacterSkillForm(
    nome: 'I',
    tipo: 'Skill equipaggiamento',
    livello: '${max(0, level)}',
    costo: '',
    cooldown: '3 turni',
    cooldownStrutturato: OculumAbilityCooldown(amount: 3, startsReady: true),
    descrizione: '+5 Volontà per 1 turno.',
    effettiStrutturati: [
      OculumStructuredEffect(
        id: 'forest_demon_armor_will',
        type: 'modifica_statistica',
        target: 'volonta',
        valueExpression: '5',
        mode: 'finche_attivo',
        duration: '1',
        durationUnit: 'turni',
        recipient: 'se_stesso',
      ),
    ],
    oculumLimitiConfiguratiManualmente: true,
  );
  return CharacterSkill(
    nome: 'Volontà del bosco scheletrico',
    tipo: 'Skill equipaggiamento',
    costo: '',
    cooldown: form.cooldown,
    descrizione: form.descrizione,
    forme: [form],
  );
}

// ignore_for_file: invalid_use_of_protected_member

int oculumEquipmentRequiredSkillLevel({
  required int itemLevel,
  required String formLevel,
}) => max(max(0, itemLevel), max(0, int.tryParse(formLevel.trim()) ?? 0));

bool oculumEquipmentSkillLevelAvailable({
  required int characterLevel,
  required int itemLevel,
  required String formLevel,
}) =>
    max(0, characterLevel) >=
    oculumEquipmentRequiredSkillLevel(
      itemLevel: itemLevel,
      formLevel: formLevel,
    );

/// Fixed-cost physical techniques never advertise a variable Oculum range.
CharacterSkill oculumEquipmentAbility(
  String name,
  int grade, {
  String? element,
}) {
  final lower = name.toLowerCase();
  final horn = lower.contains('forest demon') && lower.contains('corno');
  final bow = lower.contains('arco') || lower.contains('balestra');
  final armor =
      lower.contains('corazza') ||
      lower.contains('armatura') ||
      lower.contains('veste') ||
      lower.contains('vesti ') ||
      lower.contains('guanto') ||
      lower.contains('guanti') ||
      lower.contains('scudo') ||
      lower.contains('mantello');
  final frost = lower.contains('ghiaccio') || lower.contains('glaciale');
  final title = horn
      ? 'Carica del corno'
      : bow
      ? 'Piuma che trova il varco'
      : armor
      ? 'Serrata della corazza'
      : frost
      ? 'Incisione del gelo'
      : lower.contains('goblin')
      ? 'Rastrello di zanne'
      : 'Affondo di $name';
  final forms = <CharacterSkillForm>[
    for (var form = 0; form < 3; form++)
      CharacterSkillForm(
        nome: const ['I', 'II', 'III'][form],
        tipo: 'Skill equipaggiamento',
        livello: '${form * 5}',
        costo: '${form + 1}/${form + 1} Volontà',
        costoStrutturato: OculumSkillCost(
          resource: 'volonta',
          amountExpression: '${form + 1}',
        ),
        cooldown:
            '${horn
                ? 6
                : armor
                ? 4
                : 3} turni',
        cooldownStrutturato: OculumAbilityCooldown(
          amount: horn
              ? 6
              : armor
              ? 4
              : 3,
        ),
        descrizione: horn
            ? 'Ti lanci con il corno: ${150 + form * 25}% dei tuoi danni per il turno. Costo fisso ${form + 1} Volontà.'
            : bow
            ? 'Tendi le piume dell’arco: +${3 + form * 2} Precisione per il prossimo attacco.'
            : armor
            ? 'Chiudi le placche: +${5 + form * 5 + grade} Difesa per un turno.'
            : frost
            ? 'La lama incide un solco freddo: +${5 + form * 5 + grade} danni Ghiaccio al prossimo attacco.'
            : 'Le zanne o il filo entrano nella guardia: +${5 + form * 5 + grade} danni Perforanti al prossimo attacco.',
        effettiStrutturati: [
          OculumStructuredEffect(
            id: 'gear_${monsterSpriteStableSeed(name)}_$form',
            type: horn
                ? 'danno_percentuale'
                : bow
                ? 'modifica_sottotratto'
                : armor
                ? 'difesa'
                : 'danno',
            target: bow ? 'Precisione' : '',
            valueExpression:
                '${horn
                    ? 50 + form * 25
                    : bow
                    ? 3 + form * 2
                    : 5 + form * 5 + grade}',
            mode: horn || armor ? 'finche_attivo' : 'prossima_azione',
            duration: horn || armor ? '1' : '',
            elementType: element ?? (frost ? 'ghiaccio' : 'perforante'),
          ),
        ],
        oculumLimitiConfiguratiManualmente: true,
      ),
  ];
  return CharacterSkill(
    nome: title,
    tipo: 'Skill equipaggiamento',
    costo: forms.first.costo,
    descrizione: forms.first.descrizione,
    cooldown: forms.first.cooldown,
    forme: forms,
  );
}

OculumSkillCost? oculumStructuredCostFromText(String text) {
  final parsed = oculumParseAbilityCost(text);
  if (parsed == null) return null;
  return OculumSkillCost(
    resource: parsed.resource,
    amountExpression: '${parsed.minimum}',
    minimum: parsed.minimum,
    maximum: parsed.maximum,
    variable: parsed.minimum != parsed.maximum,
  );
}

OculumSkillCost? oculumCharacterSkillFormCost(CharacterSkillForm form) {
  final declared =
      form.costoStrutturato ?? oculumStructuredCostFromText(form.costo);
  if (declared == null || declared.resource == 'nessuna') return declared;
  if (!form.oculumLimitiConfiguratiManualmente) return declared;
  final minimum = max(0, form.oculumMinimoUtilizzabile);
  final maximum = max(minimum, form.oculumMassimoUtilizzabile);
  final result = OculumSkillCost.fromJson(declared.toJson());
  result
    ..minimum = minimum
    ..maximum = maximum
    ..amountExpression = '$minimum'
    ..variable = minimum != maximum;
  return result;
}

/// The text field and the guided resource selector share the same quantities.
/// Explicit numbers in a new text replace stale quantities; a resource-only
/// spelling keeps the separately edited minimum and maximum.
void oculumSetCharacterSkillCostText(CharacterSkillForm form, String text) {
  final guided = form.costoStrutturato != null;
  final previousExtras =
      form.costoStrutturato?.additionalCosts ?? const <OculumSkillCost>[];
  form.costo = text;
  final parsed = oculumStructuredCostFromText(text);
  if (parsed == null) {
    form.costoStrutturato = null;
    return;
  }
  if (parsed.maximum > 0 || parsed.resource == 'nessuna') {
    form.oculumMinimoUtilizzabile = parsed.minimum;
    form.oculumMassimoUtilizzabile = parsed.maximum;
    form.oculumMassimoMaestriaIniziale = parsed.maximum;
    form.oculumLimitiConfiguratiManualmente = true;
  }
  if (guided) {
    parsed.additionalCosts.addAll(previousExtras);
    form.costoStrutturato = parsed;
  }
}

OculumStructuredEffect oculumStatPaidEffect(
  OculumStructuredEffect original,
  String resource,
) {
  final effect = OculumStructuredEffect.fromJson(original.toJson());
  final positive =
      const {
        'danno',
        'danno_percentuale',
        'difesa',
        'difesa_percentuale',
        'cura',
        'scudo',
        'hp_temporanei',
        'modifica_statistica',
        'modifica_sottotratto',
        'velocita',
        'forza',
      }.contains(effect.type) &&
      effect.mode != 'diminuzione' &&
      !effect.valueExpression.trimLeft().startsWith('-');
  if (const {'volonta', 'materia'}.contains(resource) &&
      positive &&
      effect.valueExpression.trim() != 'hp') {
    effect.valueExpression = 'ceil((${effect.valueExpression})*1.2)';
  }
  return effect;
}

String oculumArtSkillCostText(ArtSkill skill, int form) {
  final resource = skill.risorsaCostoPerLivello(form);
  if (resource == 'nessuna') return 'Nessun costo';
  final minimum = skill.oculumMinimoPerLivello(form);
  final maximum = skill.oculumMassimoPerLivello(form);
  return '$minimum/$maximum $resource';
}

/// Whole units only; the majority currency receives rounding remainders.
({int obser, int oculum}) oculumMixedCurrencySplit(
  int total,
  int obserQuarter, {
  bool? tieToObser,
}) {
  final safe = max(0, total);
  final share = obserQuarter.clamp(0, 4);
  var obser = safe * share ~/ 4;
  var oculum = safe * (4 - share) ~/ 4;
  final remainder = safe - obser - oculum;
  if (share > 2 || share == 2 && (tieToObser ?? Random.secure().nextBool())) {
    obser += remainder;
  } else {
    oculum += remainder;
  }
  return (obser: obser, oculum: oculum);
}

CharacterSkill oculumEquipmentAbilityFromArt(ArtSkill skill) => CharacterSkill(
  nome: skill.nome,
  tipo: skill.tipoPerLivello(1).toLowerCase().contains('passiv')
      ? 'Passiva'
      : 'Skill equipaggiamento',
  costo: oculumArtSkillCostText(skill, 1),
  cooldown: '',
  descrizione: skill.evo1,
  forme: [
    for (var i = 0; i < 3; i++)
      CharacterSkillForm(
        nome: const ['I', 'II', 'III'][i],
        tipo: skill.tipoPerLivello(i + 1),
        descrizione: skill.testoEvoluzione(i + 1),
        costo: oculumArtSkillCostText(skill, i + 1),
        cooldown: '${skill.cooldownPerLivello[i].amount} turni',
        livello:
            RegExp(
              r'(?:Richiede\s+)?livello\s+(\d+)',
              caseSensitive: false,
            ).firstMatch(skill.testoEvoluzione(i + 1))?.group(1) ??
            '0',
        unlockRequirements: Map<String, dynamic>.from(
          skill.unlockRequirementsPerLevel[i],
        ),
        oculumMinimoUtilizzabile: skill.oculumMinimoPerLivello(i + 1),
        oculumMassimoUtilizzabile: skill.oculumMassimoPerLivello(i + 1),
        costoStrutturato: OculumSkillCost(
          resource: skill.risorsaCostoPerLivello(i + 1),
          additionalCosts: skill.additionalCostsPerLevel[i]
              .map((cost) => OculumSkillCost.fromJson(cost.toJson()))
              .toList(),
          variable:
              skill.oculumMinimoPerLivello(i + 1) !=
              skill.oculumMassimoPerLivello(i + 1),
          amountExpression: '${skill.oculumMinimoPerLivello(i + 1)}',
          minimum: skill.oculumMinimoPerLivello(i + 1),
          maximum: skill.oculumMassimoPerLivello(i + 1),
        ),
        cooldownStrutturato: OculumAbilityCooldown.fromJson(
          skill.cooldownPerLivello[i].toJson(),
        ),
        effettiStrutturati: [
          for (final e in skill.effettiEvoluzione(i + 1))
            OculumStructuredEffect.fromJson(e.toJson()),
        ],
        oculumLimitiConfiguratiManualmente: true,
      ),
  ],
);

extension _OculumEquipmentAbilities on _OculumHomePageState {
  Future<void> editEquipmentTitleForms(InventoryItem item) async {
    item.ability ??= CharacterSkill(
      nome: item.nome,
      tipo: 'Skill equipaggiamento',
      costo: '',
      cooldown: '',
      descrizione: item.note,
      forme: [
        CharacterSkillForm(
          nome: 'I',
          tipo: 'Skill equipaggiamento',
          descrizione: item.note,
        ),
      ],
    );
    await showDialog<void>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text('Forme · ${item.nome}'),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final form in item.ability!.forme)
                    ExpansionTile(
                      title: Text(form.nome),
                      children: [
                        TextFormField(
                          initialValue: form.nome,
                          decoration: const InputDecoration(
                            labelText: 'Nome forma',
                          ),
                          onChanged: (v) => form.nome = v,
                        ),
                        TextFormField(
                          initialValue: form.livello,
                          decoration: const InputDecoration(
                            labelText: 'Livello richiesto',
                          ),
                          onChanged: (v) => form.livello = v,
                        ),
                        TextFormField(
                          initialValue: form.descrizione,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Descrizione',
                          ),
                          onChanged: (v) => form.descrizione = v,
                        ),
                        structuredEffectsEditor(
                          effects: form.effettiStrutturati,
                          onChanged: () {
                            update(() {});
                            programmaSalvataggio();
                          },
                        ),
                      ],
                    ),
                  if (item.craftData['titleItem'] == true &&
                      item.ability!.forme.length < 12)
                    TextButton(
                      onPressed: () => update(() {
                        final previous = item.ability!.forme.last;
                        item.ability!.forme.add(
                          CharacterSkillForm.fromJson(previous.toJson())
                            ..nome = 'Forma ${item.ability!.forme.length + 1}'
                            ..livello = '${readIntValue(previous.livello) + 3}',
                        );
                      }),
                      child: const Text(
                        'Aggiungi evoluzione (effetti da configurare)',
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                programmaSalvataggio();
                Navigator.pop(dialog);
              },
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
    programmaSalvataggio();
  }

  Future<void> useEquipmentQuickAbility(
    InventoryItem item,
    CharacterSkillForm form,
    OculumCombatAbilityRole role,
  ) async {
    if (form.tipo.toLowerCase().contains('passiv')) return;
    form.costoStrutturato ??= oculumStructuredCostFromText(form.costo);
    if (form.costoStrutturato == null &&
        form.costo.trim().isNotEmpty &&
        !RegExp(
          r'gratuit|nessun|free|passiv',
          caseSensitive: false,
        ).hasMatch(form.costo)) {
      aggiungiLog(
        '[EQUIPAGGIAMENTO] Costo non riconosciuto per ${item.nome}: configura il costo nell’editor. Nessuna risorsa consumata.',
      );
      return;
    }
    final legacyCooldown = RegExp(
      r'^\s*(\d+)\s*(turni?|riposi?\s+(?:brevi?|lunghi?))\s*$',
      caseSensitive: false,
    ).firstMatch(form.cooldown);
    if (form.cooldownStrutturato == null && legacyCooldown != null) {
      form.cooldownStrutturato = OculumAbilityCooldown(
        amount: int.parse(legacyCooldown.group(1)!),
        unit: oculumTurnUnit(legacyCooldown.group(2)!),
      );
    }
    if (!inventario.contains(item) ||
        item.quantita <= 0 ||
        !item.equipaggiata ||
        !canEquipInventoryItem(item) ||
        !oculumEquipmentSkillLevelAvailable(
          characterLevel: leggiNumero(livelloController),
          itemLevel: oculumEquipmentSkillItemLevel(item, form),
          formLevel: form.livello,
        ) ||
        !progressionRequirementsMet(form.unlockRequirements) ||
        !itemTitleFormAvailable(item, form) ||
        !oculumAllEquipmentAbilities(item).any((s) => s.forme.contains(form))) {
      return;
    }
    if (item.craftData.containsKey('posteaUses') &&
        readIntValue(item.craftData['posteaUses']) <= 0) {
      aggiungiLog('[POSTEA] Runa esaurita: nessun utilizzo rimasto.');
      return;
    }
    if (item.craftData['posteaGloves'] == true) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Guanti da combattimento'),
          content: const Text('Usi questo bonus con un attacco corpo a corpo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Corpo a corpo'),
            ),
          ],
        ),
      );
      if (!mounted || accepted != true) return;
    }
    if (item.craftData['necromancyKind'] != null) {
      await useNecromancyEquipment(item);
      return;
    }
    if (item.craftData['posteaBoots'] == true) {
      if (!inventario.contains(item) ||
          !item.equipaggiata ||
          item.quantita <= 0) {
        return;
      }
      if (!currentCombatIsActive()) {
        aggiungiLog(
          '[POSTEA] Doppio salto gratuito: nessuna Azione o Reazione consumata.',
        );
        programmaSalvataggio();
        return;
      }
      if (form.cooldownStrutturato?.ready == false) return;
      final request = onlineCombatRequests.values
          .where(
            (r) =>
                r['targetTag'] == sheetTagAt(schedaCorrente) &&
                r['status'] == 'pending' &&
                r['firstDefenseChoice'] == 'cm' &&
                r['firstDefense'] != null &&
                r['defenseRetryUsed'] != true,
          )
          .firstOrNull;
      if (request == null) {
        aggiungiLog(
          '[POSTEA] Reroll disponibile dopo una prima difesa CM non riuscita. Nessuna risorsa consumata.',
        );
        return;
      }
      if (onlineCombatResolving.contains('${request['id']}')) return;
      request['defenseRetryUsed'] = true;
      request['defenseRetryApproved'] = true;
      request['posteaCmBonus'] = form.effettiStrutturati.isEmpty
          ? 3
          : max(
              0,
              readIntValue(
                form.effettiStrutturati.first.valueExpression,
                fallback: 3,
              ),
            );
      form.cooldownStrutturato?.activate();
      aggiungiLog(
        '[POSTEA] Reroll CM +3 gratuito: non usa Azione, Reazione o veloce. CD ${form.cooldownStrutturato?.amount ?? 5} turni.',
      );
      await defendOnlineAttack(request, 'cm');
      programmaSalvataggio();
      return;
    }
    final origin = currentSheetScrollId();
    var effects = form.effettiStrutturati.isNotEmpty
        ? form.effettiStrutturati
        : oculumParseStructuredEffectsFromText(
            form.descrizione,
            subtraits: hiddenEyeStats,
          ).effects;
    final titleOwner = oculumItemTitleAbilityForForm(item, form);
    if (titleOwner != null &&
        titleOwner.forme.firstOrNull != form &&
        oculumItemTitleOpenIsActive(item, titleOwner)) {
      final percent = max(
        0,
        readIntValue(
          item.craftData['titleOpenSkillBoostPercent'],
          fallback: 25,
        ),
      );
      effects = [
        for (final effect in effects)
          if (const {
                'danno',
                'difesa',
                'scudo',
                'cura',
              }.contains(effect.type) &&
              effect.diceDestination == 'valore')
            OculumStructuredEffect.fromJson(effect.toJson())
              ..valueExpression =
                  '((${effect.valueExpression})${effect.diceExpression.isEmpty ? '' : '+(${effect.diceExpression})'})*(100+$percent)/100'
              ..diceExpression = ''
          else
            effect,
      ];
    }
    final previousSupport = combatSupportTargeting;
    final beforeCycleAttack = cyclePreparedAttackSignature;
    final before = activeStructuredEffects
        .where((e) => e['type'] == 'pending_target')
        .toSet();
    var used = false;
    try {
      combatSupportTargeting = role == OculumCombatAbilityRole.support;
      used = await useConfiguredAbility(
        source: '${item.nome} · ${form.nome}',
        effects: effects,
        cost: form.costoStrutturato,
        cooldown: form.cooldownStrutturato,
        valid: () =>
            inventario.contains(item) &&
            item.quantita > 0 &&
            item.equipaggiata &&
            canEquipInventoryItem(item) &&
            progressionRequirementsMet(form.unlockRequirements) &&
            itemTitleFormAvailable(item, form) &&
            oculumEquipmentSkillLevelAvailable(
              characterLevel: leggiNumero(livelloController),
              itemLevel: oculumEquipmentSkillItemLevel(item, form),
              formLevel: form.livello,
            ),
      );
    } finally {
      combatSupportTargeting = previousSupport;
    }
    if (!mounted || !used || currentSheetScrollId() != origin) return;
    if (titleOwner?.forme.firstOrNull == form) {
      final index = oculumItemTitleAbilities(item).indexOf(titleOwner!);
      item.craftData = {
        ...item.craftData,
        if (index == 0) 'titleOpenUsedSinceLongRest': true,
        'titleOpenUsedStages': {
          ...(item.craftData['titleOpenUsedStages'] as List? ?? []),
          index,
        }.toList(),
      };
      programmaSalvataggio();
    }
    if (item.craftData.containsKey('posteaUses')) {
      item.craftData = {
        ...item.craftData,
        'posteaUses': max(0, readIntValue(item.craftData['posteaUses']) - 1),
      };
      aggiungiLog(
        '[POSTEA] ${item.nome}: ${item.craftData['posteaUses']} utilizzi rimasti.',
      );
      programmaSalvataggio();
    }
    final pending = activeStructuredEffects
        .where((e) => e['type'] == 'pending_target' && !before.contains(e))
        .toList();
    if (role == OculumCombatAbilityRole.attack &&
        beforeCycleAttack != cyclePreparedAttackSignature &&
        cycleHasPreparedAttack &&
        onlineAttackTokens().isNotEmpty) {
      await planOnlineAttack();
      return;
    }
    if (pending.isEmpty) return;
    if (role == OculumCombatAbilityRole.support) {
      await deliverPendingSupport();
    } else if (role == OculumCombatAbilityRole.attack &&
        onlineAttackTokens().isNotEmpty) {
      await planOnlineAttack();
    }
  }

  Iterable<OculumStructuredEffect> automaticMonsterPassiveEffects() sync* {
    for (final item in inventario.where(
      (i) => i.quantita > 0 && i.equipaggiata && canEquipInventoryItem(i),
    )) {
      for (final ability in item.materialAbilities) {
        for (final form in ability.forme.where(
          (f) => f.tipo.toLowerCase().contains('passiv'),
        )) {
          if (leggiNumero(livelloController) >= readIntValue(form.livello) &&
              progressionRequirementsMet(form.unlockRequirements)) {
            yield* form.effettiStrutturati.where(
              (e) =>
                  e.enabled &&
                  e.recipient == 'se_stesso' &&
                  !oculumFormulaUsesTotalPower(
                    '${e.valueExpression} ${e.duration}',
                  ),
            );
          }
        }
      }
    }
    final level = max(0, leggiNumero(livelloController));
    for (final skill in skills.where((s) => s.passiva && s.equipaggiata)) {
      CharacterSkillForm? selected;
      for (final form in skill.forme) {
        final requiredLevel = int.tryParse(form.livello) ?? 0;
        if (requiredLevel <= level &&
            form.descrizione.trim().isNotEmpty &&
            form.descrizione != '???') {
          selected = form;
        }
      }
      if (selected == null) continue;
      final effects = selected.effettiStrutturati.isEmpty
          ? oculumParseStructuredEffectsFromText(
              selected.descrizione,
              subtraits: hiddenEyeStats,
            ).effects
          : selected.effettiStrutturati;
      yield* effects.where(
        (e) =>
            e.enabled &&
            e.recipient == 'se_stesso' &&
            !oculumFormulaUsesTotalPower('${e.valueExpression} ${e.duration}'),
      );
    }
  }

  void tickMonsterPassiveHealing() {
    if (hpCorrenti() <= 0) return;
    for (final effect in automaticMonsterPassiveEffects().where(
      (e) => e.type == 'cura',
    )) {
      final roll = oculumResolveStructuredEffectRoll(
        effect,
        variables: formulaValueContext(),
        subtraits: hiddenEyeStats,
        spentResources: const {},
        level: leggiNumero(livelloController),
        grade: leggiNumero(gradoController),
      );
      final before = hpCorrenti();
      applyStructuredHealing(
        effect.resource.isEmpty ? 'vita' : effect.resource,
        max(0, roll.value),
      );
      if (hpCorrenti() != before) {
        aggiungiLog(
          'Passiva del mostro: recuperati ${hpCorrenti() - before} HP (${hpCorrenti()}/${maxHp()}).',
        );
      }
    }
  }

  Future<bool> useConfiguredAbility({
    required String source,
    required List<OculumStructuredEffect> effects,
    OculumSkillCost? cost,
    OculumAbilityCooldown? cooldown,
    bool Function()? valid,
    bool paymentOnly = false,
    String? turnResourceOverride,
    void Function(Map<String, int>)? onPaid,
  }) async {
    if (skillOculumUseDialogOpen || !mounted || (valid != null && !valid())) {
      return false;
    }
    if (!meccanioSkillAllowed(effects)) return false;
    if (effects.any((e) => e.target == 'senka_shadow_step')) {
      if (!senkaMaskActive || cooldown?.ready == false) return false;
      final incoming = onlineCombatRequests.values
          .where(
            (r) =>
                r['targetTag'] == sheetTagAt(schedaCorrente) &&
                r['status'] == 'pending' &&
                r['encounterId'] == onlineCombatEncounterId &&
                r['kind'] != 'help' &&
                r['kind'] != 'scout',
          )
          .firstOrNull;
      if (incoming != null) {
        return defendSenkaStep(incoming, effects, cost, cooldown);
      }
      final step = effects.firstWhere((e) => e.target == 'senka_shadow_step');
      if (!await confirmSenkaStepEnvironment(
            max(1, readIntValue(step.resource, fallback: 6)),
          ) ||
          !mounted) {
        return false;
      }
    }
    final lusierEffects = prepareLusierTitleEffects(effects);
    if (lusierEffects == null) return false;
    effects = lusierEffects;
    final senkaEffects = prepareSenkaEffects(effects);
    if (senkaEffects == null) return false;
    effects = senkaEffects;
    if (effects.any((e) => e.target == 'explosive_cards_damage')) {
      final selected = await prepareExplosiveCards(effects);
      if (selected == null) return false;
      effects = selected;
    }
    if (effects.any((e) => e.target == 'senka_shadow_clone') &&
        !senkaCanCreateClone) {
      aggiungiLog(
        'Clone non disponibile: limite totale del fight raggiunto, nessun fight attivo oppure sei già un clone.',
      );
      return false;
    }
    if (effects.any((e) => e.target.startsWith('senka_')) &&
        !senkaMaskActive &&
        !senkaIsClone) {
      aggiungiLog('Manifesta prima la maschera di Senka.');
      return false;
    }
    if (!celestialAbilityAllowed(effects)) return false;
    if (outsideFight &&
        effects.any(
          (e) =>
              e.recipient != 'se_stesso' && e.recipient != 'alleato' ||
              e.type == 'danno' ||
              e.type == 'evocazione',
        )) {
      aggiungiLog(
        '[FUORI FIGHT] Puoi curarti, ripararti o usare utilità su di te.',
      );
      return false;
    }
    if (wingsGrounded && wingFlightSource(source)) {
      aggiungiLog(
        '[ALI] Volo indisponibile fino al Riposo Lungo o alla riparazione del Master.',
      );
      return false;
    }
    if (effects.any((e) => e.target == 'deadly_regen') &&
        (planarState['deadlyLastHpDamage'] is! Map ||
            (planarState['deadlyLastHpDamage'] as Map)['claimed'] == true ||
            hpCorrenti() <= 0)) {
      return false;
    }
    if (source.contains('Raggio di Oculum') &&
        readIntValue(planarState['ogorCoreHits']) >= 3) {
      aggiungiLog(
        '[NUCLEO ROTTO] Ripara il nucleo prima di usare Raggio Oculum.',
      );
      return false;
    }
    if (effects.any((e) => e.target == 'ogor_restore') &&
        planarState['ogorRestoreUsed'] == true) {
      return false;
    }
    if (isScostubanditi &&
        hasCondition('disarmato') &&
        source.toLowerCase().contains('fucile')) {
      aggiungiLog(
        '[DISARMATO] Riprendi il fucile prima di sparare; i colpi senza arma infliggono metà Danni.',
      );
      return false;
    }
    if (effects.any((e) => e.target == 'feralis_fury') &&
        (hpCorrenti() <= 0 ||
            hpCorrenti() * 2 > maxHp() ||
            feralisFuryActive)) {
      aggiungiLog(
        '[FURIA] Richiede metà Vita o meno e nessuna trasformazione già attiva.',
      );
      return false;
    }
    if (readIntValue(planarState['fuocherelliWaterSuppressedActions']) > 0 &&
        effects.any((e) => e.elementType == 'fuoco')) {
      aggiungiLog('[ACQUA] Skill Fuoco bloccate per una propria Azione.');
      return false;
    }
    if (effects.any((e) => e.target == 'fuocherelli_reanimate')) {
      if (cooldown?.ready == false || !await prepareFaunaReanimation()) {
        return false;
      }
    }
    if (rabbitHatReady && effects.any((e) => e.target == 'rabbit_hat')) {
      aggiungiLog(
        '[CAPPELLO] Una carica è già pronta: continua o lancia prima di riattivare.',
      );
      return false;
    }

    if (planarCharging &&
        !effects.any(
          (e) => e.type == 'planar' && e.target == 'lightning_charge',
        )) {
      aggiungiLog('Carica in corso: non puoi usare altre abilità.');
      return false;
    }
    if (effects.any(
          (e) => e.type == 'planar' && e.target == 'lightning_charge',
        ) &&
        readIntValue(planarState['chargePower']) > 0) {
      return continuePlanarCharge();
    }
    final isPatalpaSummon =
        effects.any(
          (effect) =>
              effect.type == 'evocazione' &&
              effect.target.trim().toLowerCase() == 'patalpa_compagno',
        ) ||
        (source.toLowerCase().contains('patalpa') &&
            source.toLowerCase().contains('richiamo'));
    final patalpaCooldown =
        schedaCorrente >= 0 && schedaCorrente < schedePersonaggio.length
        ? max(
            0,
            readIntValue(
              schedePersonaggio[schedaCorrente]['patalpaSummonCooldownFightsRemaining'],
            ),
          )
        : 0;
    if (isPatalpaSummon && patalpaCooldown > 0) {
      aggiungiLog('Richiamo del Patalpa: cooldown di $patalpaCooldown fight.');
      notifyDiceResultChanged();
      return false;
    }
    if (cooldown != null && !cooldown.ready) {
      aggiungiLog('$source: cooldown ${cooldown.remaining} ${cooldown.unit}.');
      return false;
    }
    if (!mounted) return false;
    final options = effects
        .where(
          (e) =>
              e.enabled &&
              e.type != 'preparazione' &&
              e.activationOption.trim().isNotEmpty,
        )
        .map((e) => e.activationOption.trim())
        .toSet()
        .toList();
    if (options.isNotEmpty) {
      final selected = await showDialog<String>(
        context: context,
        builder: (dialog) => SimpleDialog(
          title: Text('Come usi $source?'),
          children: [
            for (final option in options)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialog, option),
                child: Text(option),
              ),
          ],
        ),
      );
      if (!mounted || selected == null) return false;
      effects = effects
          .where(
            (e) =>
                e.type == 'preparazione' ||
                e.activationOption.trim().isEmpty ||
                e.activationOption.trim() == selected,
          )
          .toList();
    }
    final resolved = cost ?? OculumSkillCost(resource: 'nessuna');
    if (!resolved.isValid(subtraits: hiddenEyeStats)) {
      aggiungiLog('$source: costo non valido.');
      return false;
    }
    final resource = oculumNormalizeEffectResource(resolved.resource);
    final fixed = resource == 'nessuna'
        ? 0
        : max(
            0,
            oculumEvaluateStructuredEffectValue(
              OculumStructuredEffect(
                valueExpression: resolved.amountExpression,
              ),
              variables: formulaValueContext(),
              subtraits: hiddenEyeStats,
            ),
          );
    final minimum = resolved.variable ? max(0, resolved.minimum) : fixed;
    final maximum = resolved.variable ? max(minimum, resolved.maximum) : fixed;
    final extraCosts = resolved.additionalCosts;
    final extraInputs = [
      for (final extra in extraCosts)
        TextEditingController(
          text:
              '${extra.variable ? extra.minimum : max(0, oculumEvaluateStructuredEffectValue(
                      OculumStructuredEffect(valueExpression: extra.amountExpression),
                      variables: formulaValueContext(),
                      subtraits: hiddenEyeStats,
                    ))}',
        ),
    ];
    Map<String, int> selectedPayments = {};
    final mixedPayment =
        resource == 'obser' && effects.any((e) => e.id.startsWith('tear_'));
    final oculumInput = TextEditingController(text: '0');
    var oculumPaid = 0;
    var useMortalKi = false;
    final splitTieToObser = Random.secure().nextBool();
    final input = TextEditingController(text: '$minimum');
    final origin = currentSheetScrollId();
    skillOculumUseDialogOpen = true;
    int? paid;
    DialogRoute<int>? costDialogRoute;
    if (!mounted) return false;
    try {
      costDialogRoute = DialogRoute<int>(
        context: context,
        builder: (dialog) => StatefulBuilder(
          builder: (dialog, refresh) {
            final selected = int.tryParse(input.text);
            final available = resource == 'nessuna'
                ? 1 << 30
                : artSkillCostResourceAvailable(
                    useMortalKi ? 'ki_mortale' : resource,
                  );
            final oculumPart = mixedPayment
                ? int.tryParse(oculumInput.text)
                : 0;
            final total = (selected ?? -1000000) + (oculumPart ?? -1000000);
            final payments = <String, int>{
              if (resource != 'nessuna')
                (useMortalKi ? 'ki_mortale' : resource): selected ?? 0,
            };
            if (mixedPayment) {
              payments['oculum'] =
                  (payments['oculum'] ?? 0) + (oculumPart ?? 0);
            }
            var extrasValid = true;
            for (var i = 0; i < extraCosts.length; i++) {
              final extra = extraCosts[i];
              final value = int.tryParse(extraInputs[i].text);
              final minimum = extra.variable
                  ? extra.minimum
                  : max(
                      0,
                      oculumEvaluateStructuredEffectValue(
                        OculumStructuredEffect(
                          valueExpression: extra.amountExpression,
                        ),
                        variables: formulaValueContext(),
                        subtraits: hiddenEyeStats,
                      ),
                    );
              final maximum = extra.variable ? extra.maximum : minimum;
              extrasValid &=
                  value != null && value >= max(0, minimum) && value <= maximum;
              payments[oculumNormalizeEffectResource(extra.resource)] =
                  (payments[oculumNormalizeEffectResource(extra.resource)] ??
                      0) +
                  (value ?? 0);
            }
            final allAvailable =
                extrasValid &&
                payments.entries.every(
                  (entry) =>
                      entry.value >= 0 &&
                      artSkillCostResourceAvailable(entry.key) >= entry.value,
                );
            final accepted =
                allAvailable &&
                selected != null &&
                selected >= 0 &&
                oculumPart != null &&
                oculumPart >= 0 &&
                total >= minimum &&
                total <= maximum &&
                selected <= available &&
                oculumPart <=
                    (mixedPayment
                        ? artSkillCostResourceAvailable('oculum')
                        : 0);
            return AlertDialog(
              title: Text(source),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Costo ${resolved.variable ? "$minimum/$maximum" : "$fixed/$fixed"} $resource · disponibili ${resource == "nessuna" ? "—" : available}',
                    ),
                    if (resource == 'oculum' && mortalKi > 0)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Usa Ki Mortale ($mortalKi disponibili)'),
                        value: useMortalKi,
                        onChanged: (v) =>
                            refresh(() => useMortalKi = v == true),
                      ),
                    if (resolved.variable || mixedPayment)
                      TextField(
                        controller: input,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: mixedPayment
                              ? 'Obser da spendere'
                              : 'Quantità da spendere',
                        ),
                        onChanged: (_) => refresh(() {}),
                      ),
                    if (mixedPayment)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (var share = 0; share <= 4; share++)
                              Builder(
                                builder: (context) {
                                  final split = oculumMixedCurrencySplit(
                                    total.clamp(minimum, maximum),
                                    share,
                                    tieToObser: splitTieToObser,
                                  );
                                  final enough =
                                      split.obser <= available &&
                                      split.oculum <=
                                          artSkillCostResourceAvailable(
                                            'oculum',
                                          );
                                  final tooltipKey = GlobalKey<TooltipState>();
                                  return RawGestureDetector(
                                    gestures: {
                                      LongPressGestureRecognizer:
                                          GestureRecognizerFactoryWithHandlers<
                                            LongPressGestureRecognizer
                                          >(
                                            () => LongPressGestureRecognizer(
                                              duration: const Duration(
                                                milliseconds: 800,
                                              ),
                                            ),
                                            (
                                              recognizer,
                                            ) => recognizer.onLongPress = () =>
                                                tooltipKey.currentState
                                                    ?.ensureTooltipVisible(),
                                          ),
                                    },
                                    child: Tooltip(
                                      key: tooltipKey,
                                      triggerMode: TooltipTriggerMode.manual,
                                      waitDuration: const Duration(
                                        milliseconds: 800,
                                      ),
                                      message:
                                          '${split.obser} Obser · ${split.oculum} Oculum${enough ? '' : ' · risorse insufficienti'}',
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                          ),
                                          minimumSize: const Size(0, 32),
                                          visualDensity: VisualDensity.compact,
                                          textStyle: const TextStyle(
                                            fontSize: 11,
                                          ),
                                          foregroundColor: share == 0
                                              ? const Color(0xFFB68CFF)
                                              : const Color(0xFFADB1BA),
                                        ),
                                        onPressed: enough
                                            ? () => refresh(() {
                                                input.text = '${split.obser}';
                                                oculumInput.text =
                                                    '${split.oculum}';
                                              })
                                            : null,
                                        child: Text(
                                          const [
                                            'Oculum',
                                            '¼ Obser',
                                            '½ Obser',
                                            '¾ Obser',
                                            'Obser',
                                          ][share],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    if (mixedPayment) ...[
                      Text(
                        'Pagamento libero: Obser + Oculum = $minimum${minimum == maximum ? '' : '–$maximum'}. Oculum disponibili: ${artSkillCostResourceAvailable('oculum')}.',
                      ),
                      TextField(
                        controller: oculumInput,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Oculum da spendere',
                        ),
                        onChanged: (_) => refresh(() {}),
                      ),
                    ],
                    for (var i = 0; i < extraCosts.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TextField(
                          controller: extraInputs[i],
                          keyboardType: TextInputType.number,
                          readOnly: !extraCosts[i].variable,
                          decoration: InputDecoration(
                            labelText: structuredEffectResourceLabel(
                              extraCosts[i].resource,
                            ),
                            helperText:
                                'Min ${extraCosts[i].variable ? extraCosts[i].minimum : extraInputs[i].text} · Max ${extraCosts[i].variable ? extraCosts[i].maximum : extraInputs[i].text} · disponibili ${artSkillCostResourceAvailable(extraCosts[i].resource)}',
                          ),
                          onChanged: (_) => refresh(() {}),
                        ),
                      ),
                    for (final effect in effects.where((e) => e.enabled))
                      Text(oculumStructuredEffectDescription(effect)),
                    const Text(
                      'I dadi degli effetti vengono tirati alla conferma.',
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialog),
                  child: const Text('Annulla'),
                ),
                FilledButton(
                  onPressed: accepted
                      ? () {
                          selectedPayments = Map.of(payments);
                          oculumPaid = mixedPayment
                              ? int.parse(oculumInput.text)
                              : 0;
                          Navigator.pop(dialog, selected + oculumPaid);
                        }
                      : null,
                  child: const Text('Conferma'),
                ),
              ],
            );
          },
        ),
      );
      paid = await Navigator.of(
        context,
        rootNavigator: true,
      ).push<int>(costDialogRoute);
    } finally {
      skillOculumUseDialogOpen = false;
      void disposeInputs() {
        input.dispose();
        oculumInput.dispose();
        for (final controller in extraInputs) {
          controller.dispose();
        }
      }

      // The pop result arrives before the closing transition unmounts fields.
      // Clone creation can rebuild them immediately after payment.
      final route = costDialogRoute;
      if (route == null) {
        disposeInputs();
      } else {
        unawaited(route.completed.then((_) => disposeInputs()));
      }
    }
    if (!mounted ||
        paid == null ||
        origin != currentSheetScrollId() ||
        (valid != null && !valid()) ||
        (cooldown != null && !cooldown.ready)) {
      return false;
    }
    final robotTechnique = effects
        .where((e) => e.type == 'meccanio')
        .firstOrNull;
    final preparesAttack =
        effects.any((e) => e.id.startsWith('senka_grapple_')) ||
        effects.any(
          (e) =>
              e.type == 'planar' &&
              const {
                'bone_four_slash',
                'gran_leave',
                'gran_cannon',
                'evergreen_leaves',
                'evergreen_dodge',
                'laer_sword',
                'laer_twist',
                'cycle_bear_spines',
                'cycle_lunar_stomp',
                'cycle_lunar_bite',
                'skeleton_giant_throw',
                'total_power_burst',
                'total_power_accuracy',
                'explosive_cards_damage',
                'lusier_derision',
                'lusier_regal_strike',
                'lusier_open_ray',
                'lusier_thin_ray',
                'senka_thousand_cuts',
                'senka_moon_cuts',
                'senka_shadow_step',
              }.contains(e.target),
        ) ||
        robotTechnique != null &&
            !const {'drones', 'sphere'}.contains(robotTechnique.target) ||
        effects.any(
          (e) =>
              const {'danno', 'danno_percentuale'}.contains(e.type) &&
              e.mode == 'prossima_azione',
        );
    final freeSpeedIncrease = effects.any(
      (effect) =>
          effect.type == 'planar' &&
          const {
            'speed_increase',
            'mask_serious_punch',
            'mask_blue_volley',
            'mask_angelic_arrows',
            'mask_solar_arrows',
            'mask_shadow_teleport',
            'gran_unstun',
            'monk_ki',
          }.contains(effect.target),
    );
    if (!paymentOnly &&
        !preparesAttack &&
        !freeSpeedIncrease &&
        currentTurnTrackerIsActive()) {
      final combatTokens = onlineCombatTokens();
      final token = combatTokens
          .where((t) => onlineCombatTokenTag(t) == sheetTagAt(schedaCorrente))
          .firstOrNull;
      final ownTurn =
          token != null &&
          combatTokens.indexOf(token) ==
              (_usesLocalMasterInitiative
                  ? masterInitiativeActiveIndex
                  : readIntValue(
                      realtimeVisibleInitiativeSnapshot['activeIndex'],
                    ));
      if (effects.any(
            (e) =>
                e.type == 'preparazione' ||
                const {
                  'rabbit_hat',
                  'deadly_regen',
                  'senka_shadow_fusion',
                }.contains(e.target),
          ) &&
          !ownTurn) {
        aggiungiLog('Preparazione: serve la tua Azione nel tuo turno.');
        return false;
      }
      if (!await requestUtilitySpend(
        turnResourceOverride ??
            (isMeccanio
                ? 'reazione'
                : ownTurn
                ? 'azione'
                : 'reazione'),
        preferFreeReaction: !effects.any((e) => e.target == 'rabbit_hat'),
      )) {
        return false;
      }
    }
    if (selectedPayments.isEmpty && resource != 'nessuna') {
      selectedPayments = {
        resource: paid - oculumPaid,
        if (oculumPaid > 0) 'oculum': oculumPaid,
      };
    }
    if (!selectedPayments.entries.every(
      (entry) => artSkillCostResourceAvailable(entry.key) >= entry.value,
    )) {
      return false;
    }
    // Synchronous preflight above makes this one transaction on the UI isolate.
    for (final entry in selectedPayments.entries) {
      if (spendArtSkillCostResource(entry.key, entry.value) != entry.value) {
        return false;
      }
    }
    onPaid?.call(selectedPayments);
    if (paymentOnly) return true;
    // Consume existing one-action conditions before adding new self effects.
    // A condition just granted by this ability starts with its full duration.
    processConditionTick(OculumConditionTickTrigger.action);
    referenceBeforeMagic(effects);
    final messages = applyStructuredEffectsOnActivation(
      effects,
      source: source,
      spentResources: {
        ...selectedPayments,
        if (useMortalKi) 'oculum': selectedPayments['ki_mortale'] ?? 0,
      },
    );
    cooldown?.activate();
    if (cooldown != null &&
        cooldown.amount == 3 &&
        cooldown.unit == 'turni' &&
        senkaMoonOpenActive &&
        effects.any((e) => e.target == 'senka_moon_cuts')) {
      cooldown.remaining = 2;
    }
    activateSharedFaunaCooldown(effects, cooldown);
    if (effects.any((e) => e.id.startsWith('planar:party_heal:'))) {
      final ownSide = combatScoutSide(sheetTagAt(schedaCorrente));
      final targets = realtimeService?.isConnected == true
          ? onlineCombatTokens()
                .where(
                  (t) =>
                      combatScoutSide(onlineCombatTokenTag(t)) == ownSide &&
                      !const {'dead', 'fled', 'expired'}.contains(t['status']),
                )
                .map(onlineCombatTokenTag)
                .toList()
          : questPartyIndices().map(sheetTagAt).toList();
      await deliverPendingSupport(
        minimum: 1,
        maximum: max(1, targets.length),
        selectedTags: targets,
        sourcePrefix: source,
      );
    }
    setState(() {
      risultato = '$source · spesi $paid $resource.\n${messages.join("\n")}';
      aggiungiLog(risultato);
      invalidateDerivedDataCaches();
    });
    scheduleRealtimeOculumChanged();
    programmaSalvataggio();
    notifyDiceResultChanged();
    for (final effect in effects.where(
      (e) => e.enabled && e.type == 'tiro_sottotratto',
    )) {
      final stat = hiddenEyeStats
          .where((s) => s.id == effect.target)
          .firstOrNull;
      if (stat != null) await tiraSottotrattoOcchio(stat, actionLabel: source);
    }
    if (!preparesAttack) finishArtWeakPointAction();
    return true;
  }

  void restorePatalpaSummonCooldown() {
    if (schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length) {
      return;
    }
    if (currentCombatIsActive()) {
      risultato = 'Ripristina la CD fuori da uno scontro attivo.';
      aggiungiLog(risultato);
      notifyDiceResultChanged();
      return;
    }
    final sheet = schedePersonaggio[schedaCorrente];
    sheet['patalpaSummonCooldownFightsRemaining'] = 0;
    sheet['patalpaSummonCooldownLastEncounterId'] = '';
    risultato = 'CD ripristinata: Richiamo del Patalpa è pronto.';
    aggiungiLog(risultato);
    programmaSalvataggio();
    if (realtimeService?.isConnected == true) {
      sendRealtimeCurrentSheetToStaff(immediate: true);
    }
    notifyDiceResultChanged();
  }

  Widget equipmentAbilityEditor(
    InventoryItem item, {
    bool title = false,
    CharacterSkill? abilityOverride,
  }) {
    final ability =
        abilityOverride ?? (title ? item.titleAbility : item.ability);
    if (ability == null) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.auto_fix_high),
        label: const Text('Aggiungi skill dell’oggetto'),
        onPressed: () {
          setState(
            () => item.ability = item.monsterLoot['skill'] is Map
                ? oculumEquipmentAbilityFromArt(
                    ArtSkill.fromJson(
                      Map<String, dynamic>.from(item.monsterLoot['skill']),
                    ),
                  )
                : oculumEquipmentAbility(item.nome, item.gradoOggetto),
          );
          programmaSalvataggio();
        },
      );
    }
    void changed() {
      invalidateDerivedDataCaches();
      programmaSalvataggio();
    }

    return ExpansionTile(
      title: Text('Skill dell’oggetto · ${ability.nome}'),
      children: [
        if (!title &&
            abilityOverride == null &&
            item.craftData['titleItem'] == true) ...[
          Text(oculumItemTitleSummary(item)),
          itemTitleEvolutionEditor(item),
          if (item.titleAbility != null)
            equipmentAbilityEditor(item, title: true),
          for (final extra in item.titleExtraAbilities)
            equipmentAbilityEditor(item, title: true, abilityOverride: extra),
        ],
        if (!title && abilityOverride == null)
          for (final material in item.materialAbilities)
            equipmentAbilityEditor(item, abilityOverride: material),
        campoModello(
          label: 'Nome della skill',
          initialValue: ability.nome,
          onChanged: (v) {
            ability.nome = v;
            changed();
          },
        ),
        for (final (i, form) in ability.forme.indexed)
          ExpansionTile(
            title: Text('Forma ${i + 1}'),
            children: [
              progressionRequirementsEditor(
                form.unlockRequirements,
                storageId: 'gear_requirements_${identityHashCode(form)}',
              ),
              campoModello(
                label: 'Descrizione',
                initialValue: form.descrizione,
                maxLines: 3,
                onChanged: (v) {
                  form.descrizione = v;
                  changed();
                },
              ),
              campoModello(
                label: 'Livello richiesto',
                initialValue: form.livello,
                onChanged: (v) {
                  form.livello = v;
                  changed();
                },
              ),
              structuredCostEditor(
                cost: form.costoStrutturato,
                storageId: 'gear_${identityHashCode(item)}_$i',
                onChanged: (v) {
                  setState(() => form.costoStrutturato = v);
                  changed();
                },
              ),
              structuredCooldownEditor(
                cooldown: form.cooldownStrutturato,
                storageId: 'gear_${identityHashCode(item)}_$i',
                onChanged: (v) {
                  setState(() => form.cooldownStrutturato = v);
                  changed();
                },
              ),
              structuredEffectsEditor(
                effects: form.effettiStrutturati,
                freeText: form.descrizione,
                storageId: 'gear_${identityHashCode(item)}_$i',
                onChanged: changed,
              ),
              FilledButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Usa skill dell’oggetto'),
                onPressed:
                    !item.equipaggiata ||
                        !canEquipInventoryItem(item) ||
                        !progressionRequirementsMet(form.unlockRequirements) ||
                        !itemTitleFormAvailable(item, form) ||
                        !oculumEquipmentSkillLevelAvailable(
                          characterLevel: leggiNumero(livelloController),
                          itemLevel: oculumEquipmentSkillItemLevel(item, form),
                          formLevel: form.livello,
                        )
                    ? null
                    : () => useEquipmentQuickAbility(
                        item,
                        form,
                        oculumCombatAbilityRole(
                          form.effettiStrutturati,
                          explicitType: form.tipo,
                        ),
                      ),
              ),
            ],
          ),
      ],
    );
  }
}
