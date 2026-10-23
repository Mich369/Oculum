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
CharacterSkill oculumEquipmentAbility(String name, int grade) {
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
            elementType: frost ? 'ghiaccio' : 'perforante',
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

CharacterSkill oculumEquipmentAbilityFromArt(ArtSkill skill) => CharacterSkill(
  nome: skill.nome,
  tipo: 'Skill equipaggiamento',
  costo: '',
  cooldown: '',
  descrizione: skill.evo1,
  forme: [
    for (var i = 0; i < 3; i++)
      CharacterSkillForm(
        nome: const ['I', 'II', 'III'][i],
        tipo: skill.tipoPerLivello(i + 1),
        descrizione: skill.testoEvoluzione(i + 1),
        livello:
            RegExp(
              r'(?:Richiede\s+)?livello\s+(\d+)',
              caseSensitive: false,
            ).firstMatch(skill.testoEvoluzione(i + 1))?.group(1) ??
            '0',
        costoStrutturato: OculumSkillCost(
          resource: skill.risorsaCostoPerLivello(i + 1),
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
  Future<void> useEquipmentQuickAbility(
    InventoryItem item,
    CharacterSkillForm form,
    OculumCombatAbilityRole role,
  ) async {
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
      request['posteaCmBonus'] = 3;
      form.cooldownStrutturato?.activate();
      aggiungiLog(
        '[POSTEA] Reroll CM +3 gratuito: non usa Azione, Reazione o veloce. CD ${form.cooldownStrutturato?.amount ?? 5} turni.',
      );
      await defendOnlineAttack(request, 'cm');
      programmaSalvataggio();
      return;
    }
    final origin = currentSheetScrollId();
    final effects = form.effettiStrutturati.isNotEmpty
        ? form.effettiStrutturati
        : oculumParseStructuredEffectsFromText(
            form.descrizione,
            subtraits: hiddenEyeStats,
          ).effects;
    final previousSupport = combatSupportTargeting;
    final before = activeStructuredEffects
        .where((e) => e['type'] == 'pending_target')
        .toSet();
    var used = false;
    try {
      combatSupportTargeting = role == OculumCombatAbilityRole.support;
      used = await useConfiguredAbility(
        source: '${item.nome} · ${item.ability?.nome}',
        effects: effects,
        cost: form.costoStrutturato,
        cooldown: form.cooldownStrutturato,
        valid: () =>
            inventario.contains(item) &&
            item.quantita > 0 &&
            item.equipaggiata &&
            canEquipInventoryItem(item) &&
            oculumEquipmentSkillLevelAvailable(
              characterLevel: leggiNumero(livelloController),
              itemLevel: item.livelloOggetto,
              formLevel: form.livello,
            ),
      );
    } finally {
      combatSupportTargeting = previousSupport;
    }
    if (!mounted || !used || currentSheetScrollId() != origin) return;
    final pending = activeStructuredEffects
        .where((e) => e['type'] == 'pending_target' && !before.contains(e))
        .toList();
    if (pending.isEmpty) return;
    if (role == OculumCombatAbilityRole.support) {
      await deliverPendingSupport();
    } else if (role == OculumCombatAbilityRole.attack &&
        onlineAttackTokens().isNotEmpty) {
      await planOnlineAttack();
    }
  }

  Iterable<OculumStructuredEffect> automaticMonsterPassiveEffects() sync* {
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
      yield* effects.where((e) => e.enabled && e.recipient == 'se_stesso');
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
  }) async {
    if (skillOculumUseDialogOpen || !mounted || (valid != null && !valid())) {
      return false;
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
    final options = effects
        .where((e) => e.enabled && e.activationOption.trim().isNotEmpty)
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
    final input = TextEditingController(text: '$minimum');
    final origin = currentSheetScrollId();
    skillOculumUseDialogOpen = true;
    int? paid;
    try {
      paid = await showDialog<int>(
        context: context,
        builder: (dialog) => StatefulBuilder(
          builder: (dialog, refresh) {
            final selected = int.tryParse(input.text);
            final available = resource == 'nessuna'
                ? 1 << 30
                : artSkillCostResourceAvailable(resource);
            final accepted =
                selected != null &&
                selected >= minimum &&
                selected <= maximum &&
                selected <= available;
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
                    if (resolved.variable)
                      TextField(
                        controller: input,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantità da spendere',
                        ),
                        onChanged: (_) => refresh(() {}),
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
                      ? () => Navigator.pop(dialog, selected)
                      : null,
                  child: const Text('Conferma'),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      skillOculumUseDialogOpen = false;
      input.dispose();
    }
    if (!mounted ||
        paid == null ||
        origin != currentSheetScrollId() ||
        (valid != null && !valid()) ||
        (cooldown != null && !cooldown.ready)) {
      return false;
    }
    if (resource != 'nessuna' &&
        (artSkillCostResourceAvailable(resource) < paid ||
            spendArtSkillCostResource(resource, paid) != paid)) {
      return false;
    }
    // Consume existing one-action conditions before adding new self effects.
    // A condition just granted by this ability starts with its full duration.
    processConditionTick(OculumConditionTickTrigger.action);
    final messages = applyStructuredEffectsOnActivation(
      effects,
      source: source,
      spentResources: {resource: paid},
    );
    cooldown?.activate();
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

  Widget equipmentAbilityEditor(InventoryItem item) {
    final ability = item.ability;
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
                        !oculumEquipmentSkillLevelAvailable(
                          characterLevel: leggiNumero(livelloController),
                          itemLevel: item.livelloOggetto,
                          formLevel: form.livello,
                        )
                    ? null
                    : () => useConfiguredAbility(
                        source: '${item.nome} / ${ability.nome} ${i + 1}',
                        effects: form.effettiStrutturati,
                        cost: form.costoStrutturato,
                        cooldown: form.cooldownStrutturato,
                        valid: () =>
                            inventario.contains(item) &&
                            item.quantita > 0 &&
                            item.equipaggiata &&
                            canEquipInventoryItem(item) &&
                            oculumEquipmentSkillLevelAvailable(
                              characterLevel: leggiNumero(livelloController),
                              itemLevel: item.livelloOggetto,
                              formLevel: form.livello,
                            ),
                      ),
              ),
            ],
          ),
      ],
    );
  }
}
