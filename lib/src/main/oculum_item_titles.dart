part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _OculumTitleManifestation on _OculumHomePageState {
  bool setTitleItemManifested(InventoryItem item, bool manifested) {
    if (!inventario.contains(item) ||
        item.quantita <= 0 ||
        item.craftData['titleItem'] != true) {
      return false;
    }
    if (item.equipaggiata == manifested) return true;
    if (manifested &&
        (!canEquipInventoryItem(item) || weaponEquipLimitReached(item))) {
      aggiungiLog(
        '${item.nome}: non puoi evocarlo con i requisiti o gli slot attuali.',
      );
      return false;
    }
    setState(() {
      applicaScudoItemAttuale(item, manifested ? 1 : -1);
      item.equipaggiata = manifested;
      invalidateDerivedDataCaches();
    });
    if (!manifested) removeConditionsFromSource(item.nome);
    aggiungiLog(
      '${item.nome}: ${manifested ? 'evocato' : 'disevocato'}, senza Azioni o Reazioni.',
    );
    programmaSalvataggio();
    notifyActiveSheetSummaryChanged();
    return true;
  }
}

// A title augments one physical item. It never replaces its authored skill,
// scroll metadata, material properties, or custom text.
bool oculumEquipmentCanBecomeTitle(InventoryItem item) =>
    item.arma || item.protegge || item.craftData['clothing'] == true;

Map<String, dynamic> oculumItemTitleEvolution(InventoryItem item) =>
    Map<String, dynamic>.from(item.craftData['titleEvolution'] as Map? ?? {});

List<CharacterSkill> oculumItemTitleAbilities(InventoryItem item) => [
  if (item.titleAbility != null) item.titleAbility!,
  ...item.titleExtraAbilities,
];
CharacterSkill? oculumItemTitleAbilityForForm(
  InventoryItem item,
  CharacterSkillForm form,
) => oculumItemTitleAbilities(
  item,
).where((s) => s.forme.contains(form)).firstOrNull;

bool oculumItemTitleOpenIsActive(InventoryItem item, CharacterSkill ability) {
  final index = oculumItemTitleAbilities(item).indexOf(ability);
  return index >= 0 &&
      ((item.craftData['titleOpenUsedStages'] as List? ?? []).contains(index) ||
          index == 0 && item.craftData['titleOpenUsedSinceLongRest'] == true);
}

/// A reforge adds a separate saved Open; earlier Open definitions are retained.
/// Its newly evolved form raises flat power while slightly reducing variance.
bool oculumReforgeItemTitle(InventoryItem item, {required int ownerPower}) {
  if (!oculumItemTitleEvolutionReady(item) || item.titleAbility == null) {
    return false;
  }
  final previous = oculumItemTitleAbilities(item).last;
  final count = readIntValue(item.craftData['titleReforgeCount']) + 1;
  final next = CharacterSkill.fromJson(
    oculumCopyJsonTree(previous.toJson()) as Map<String, dynamic>,
  );
  next.nome = '${item.nome} · Reforge $count';
  for (final (i, form) in next.forme.indexed) {
    form.nome = '${i == 0 ? 'Open' : 'Skill Open'} · Reforge $count';
    form.cooldownStrutturato = form.cooldownStrutturato == null
        ? null
        : OculumAbilityCooldown(
            amount: form.cooldownStrutturato!.amount,
            unit: form.cooldownStrutturato!.unit,
            startsReady: true,
          );
    for (final effect in form.effettiStrutturati) {
      effect.id = '${effect.id}_reforge_$count';
      if (effect.mode == 'prossima_azione' ||
          const {'scudo', 'difesa', 'cura'}.contains(effect.type)) {
        final die = RegExp(r'^1d(\d+)$').firstMatch(effect.diceExpression);
        if (die != null) {
          final oldFaces = int.parse(die.group(1)!);
          final faces = max(4, (oldFaces * .9).floor());
          effect.diceExpression = '1d$faces';
          effect.valueExpression =
              '(${effect.valueExpression})*1.25+${max(3, ((oldFaces + 1) * .125 + (oldFaces - faces) / 2).ceil())}';
        } else {
          effect.valueExpression = '(${effect.valueExpression})*1.25+1';
        }
      } else if (effect.type == 'modifica_statistica') {
        effect.valueExpression = '(${effect.valueExpression})+1';
      }
    }
    form.descrizione =
        'Reforge $count: versione coerente più potente, con bonus fisso maggiore e dado leggermente minore ove presente. ${form.descrizione}';
  }
  item.titleExtraAbilities = [...item.titleExtraAbilities, next];
  final quest = oculumItemTitleEvolution(item);
  final required = max(1, readIntValue(quest['requiredKills'], fallback: 5));
  item.craftData = {
    ...item.craftData,
    'titleReforgeCount': count,
    'titleEvolutionUpgradeApplied': false,
    'titleEvolution': {
      ...quest,
      'requiredKills': required + max(2, (required * .3).ceil()),
      'progress': 0,
      'minimumPower': max(0, ownerPower),
      'killReceipts': <String>[],
      'description':
          '${quest['description']} Nuovo ciclo $count: bersagli con Potenza Totale almeno pari alla tua; requisito quantitativo aumentato.',
    },
  };
  return true;
}

bool oculumItemTitleEvolutionReady(InventoryItem item) {
  final quest = oculumItemTitleEvolution(item);
  return item.craftData['titleItem'] == true &&
      quest.isNotEmpty &&
      readIntValue(quest['progress']) >=
          max(1, readIntValue(quest['requiredKills'], fallback: 5));
}

/// Editable initial balance, not a replacement for an authored item rule.
void oculumInitializeItemTitle(InventoryItem item) {
  if (readIntValue(item.craftData['titleItemVersion']) >= 1) return;
  final level = max(0, item.livelloOggetto);
  final grade = max(0, item.gradoOggetto);
  final damage = item.arma
      ? max(2, (max(0, item.bonusDanno) * .25).ceil() + level ~/ 3 + grade)
      : 0;
  final defense = item.protegge
      ? max(2, (max(0, item.bonusDifesa) * .25).ceil() + level ~/ 5 + grade)
      : 0;
  final shield = item.protegge || item.bonusScudo > 0
      ? max(5, (max(0, item.bonusScudo) * .25).ceil() + level)
      : 0;
  final oculumShield = item.bonusScudoOculum > 0
      ? max(1, (item.bonusScudoOculum * .25).ceil())
      : 0;
  final source =
      '${item.craftData['monsterId'] ?? item.monsterLoot['monsterId'] ?? ''}';
  final species = source.isEmpty ? '' : oculumPartyHuntSpeciesId(source);
  final element = oculumNormalizeElementId(
    '${item.craftData['element'] ?? item.elementoDanno}',
  );
  final speciesName = monsterBookEntryById(species)?.nameIt ?? species;
  final requirement = species.isNotEmpty
      ? 'Uccidi 5 $speciesName ${item.arma ? 'usando quest’arma' : 'mentre indossi questo equipaggiamento'}.'
      : 'Uccidi 5 nemici di elemento $element ${item.arma ? 'usando quest’arma' : 'mentre indossi questo equipaggiamento'}.';
  item.bonusDanno += damage;
  item.bonusDifesa += defense;
  item.bonusScudo += shield;
  item.bonusScudoOculum += oculumShield;
  // Do not repair a broken or partly spent shield as a side effect of conversion.
  item.craftData = {
    ...item.craftData,
    'titleItem': true,
    'evolvable': true,
    'titleItemVersion': 1,
    'titleItemId':
        '${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 30)}',
    'conversionDustCost': 3,
    'titleOpenSkillBoostPercent': 25,
    'titleUpgrade': {
      'damage': damage,
      'defense': defense,
      'shield': shield,
      'oculumShield': oculumShield,
    },
    if (item.craftData['titleEvolution'] is! Map)
      'titleEvolution': {
        'requiredKills': 5,
        'progress': 0,
        'species': species,
        'element': species.isEmpty ? element : '',
        'description': requirement,
        'killReceipts': <String>[],
      },
  };
  item.note += '\nTitolo Item · ${oculumItemTitleSummary(item)}';
  item.ability ??= oculumEquipmentAbility(
    item.nome,
    item.gradoOggetto,
    element: item.elementoDanno,
  );
  item.titleAbility ??= oculumItemTitleOpen(item);
}

({int faces, int flat}) oculumItemTitleOpenPower(int grade) =>
    switch (max(0, grade)) {
      0 => (faces: 50, flat: 20),
      1 => (faces: 100, flat: 45),
      2 => (faces: 150, flat: 0),
      3 => (faces: 200, flat: 0),
      _ => (faces: 250, flat: 0),
    };

CharacterSkill oculumItemTitleOpen(InventoryItem item) {
  final power = oculumItemTitleOpenPower(item.gradoOggetto);
  final element = oculumNormalizeElementId(item.elementoDanno);
  final weapon = item.arma;
  final forms = <CharacterSkillForm>[
    CharacterSkillForm(
      nome: 'Open · Risveglio di ${item.nome}',
      tipo: weapon ? 'Attacco' : 'Difesa',
      livello: '${item.livelloOggetto}',
      costo: 'Gratuito · una volta per Riposo Lungo',
      costoStrutturato: OculumSkillCost(
        resource: 'nessuna',
        amountExpression: '0',
      ),
      descrizione: weapon
          ? 'Risveglia il potere $element: il prossimo attacco aggiunge 1d${power.faces}+${power.flat} Danni. Buff: +${2 + max(0, item.gradoOggetto)} Materia fino al Riposo Lungo. Sblocca la Skill Open.'
          : 'Risveglia il potere $element: ottieni 1d${power.faces}+${power.flat} Scudo e +${2 + max(0, item.gradoOggetto)} Difesa fino al Riposo Lungo. Sblocca la Skill Open.',
      effettiStrutturati: [
        OculumStructuredEffect(
          type: weapon ? 'danno' : 'scudo',
          valueExpression: '${power.flat}',
          diceExpression: '1d${power.faces}',
          mode: weapon ? 'prossima_azione' : 'immediato',
          elementType: element,
        ),
        OculumStructuredEffect(
          type: weapon ? 'modifica_statistica' : 'difesa',
          target: weapon ? 'materia' : '',
          valueExpression: '${2 + max(0, item.gradoOggetto)}',
          mode: 'finche_attivo',
          duration: '1',
          durationUnit: 'riposi_lunghi',
        ),
      ],
      oculumLimitiConfiguratiManualmente: true,
    ),
    CharacterSkillForm(
      nome: 'Skill Open · Eco di ${item.nome}',
      tipo: weapon ? 'Attacco' : 'Difesa',
      livello: '${item.livelloOggetto}',
      costo: '1 Volontà',
      oculumMinimoUtilizzabile: 1,
      oculumMassimoUtilizzabile: 1,
      costoStrutturato: OculumSkillCost(
        resource: 'volonta',
        amountExpression: '1',
        minimum: 1,
        maximum: 1,
      ),
      cooldown: '3 turni',
      cooldownStrutturato: OculumAbilityCooldown(amount: 3, startsReady: true),
      descrizione:
          'Versione ridotta: ${weapon ? 'aggiungi al prossimo attacco' : 'ottieni come Scudo'} 1d${max(6, power.faces ~/ 5)}+${power.flat ~/ 4}. Il Buff Open ne aumenta il valore del 25%. Recupero autonomo: 3 turni.',
      effettiStrutturati: [
        OculumStructuredEffect(
          type: weapon ? 'danno' : 'scudo',
          valueExpression: '${power.flat ~/ 4}',
          diceExpression: '1d${max(6, power.faces ~/ 5)}',
          mode: weapon ? 'prossima_azione' : 'immediato',
          elementType: element,
        ),
      ],
      oculumLimitiConfiguratiManualmente: true,
    ),
  ];
  return CharacterSkill(
    nome: 'Evoluzione · ${item.nome}',
    tipo: 'Skill equipaggiamento',
    costo: forms.first.costo,
    cooldown: '',
    descrizione:
        'Open evolutiva legata al Titolo Item. Requisiti, effetti, dadi, costi e recupero modificabili.',
    forme: forms,
  );
}

String oculumItemTitleSummary(InventoryItem item) {
  final bonus = item.craftData['titleUpgrade'] as Map? ?? {};
  final labels = <String>[
    if (readIntValue(bonus['damage']) != 0) '+${bonus['damage']} Danni',
    if (readIntValue(bonus['defense']) != 0) '+${bonus['defense']} Difesa',
    if (readIntValue(bonus['shield']) != 0) '+${bonus['shield']} Scudo',
    if (readIntValue(bonus['oculumShield']) != 0)
      '+${bonus['oculumShield']} Scudo Oculum',
  ];
  final quest = oculumItemTitleEvolution(item);
  return '${labels.join(' · ')}. Richiede: ${quest['description'] ?? ''} '
      '${readIntValue(quest['progress'])}/${max(1, readIntValue(quest['requiredKills'], fallback: 5))}.';
}

/// Only confirmed enemy deaths with this item's attribution advance the quest.
/// The receipt survives saves and retries and no summoned creature counts.
bool oculumAdvanceItemTitleKills(
  InventoryItem item,
  Iterable<Map> enemies,
  String encounter,
  String ownerTag,
) {
  if (item.craftData['titleItem'] != true) return false;
  final quest = oculumItemTitleEvolution(item);
  final id = '${item.craftData['titleItemId'] ?? ''}';
  if (quest.isEmpty || id.isEmpty) return false;
  final receipts = (quest['killReceipts'] as List? ?? [])
      .map((e) => '$e')
      .toSet();
  var progress = max(0, readIntValue(quest['progress']));
  final before = progress;
  for (final enemy in enemies) {
    if (oculumEncounterEnemyIsSummon(enemy) ||
        '${enemy['killerTag'] ?? ''}' != ownerTag) {
      continue;
    }
    if (!(enemy['titleItemIds'] as List? ?? []).contains(id)) continue;
    final enemyPower = readIntValue(enemy['totalPower'], fallback: -1);
    final ownerPower = readIntValue(enemy['killerTotalPower'], fallback: -1);
    if (enemyPower < 0 ||
        ownerPower < 0 ||
        enemyPower < ownerPower ||
        enemyPower < readIntValue(quest['minimumPower'])) {
      continue;
    }
    final species = '${quest['species'] ?? ''}';
    if (species.isNotEmpty &&
        oculumPartyHuntSpeciesId('${enemy['monsterBookId'] ?? ''}') !=
            oculumPartyHuntSpeciesId(species)) {
      continue;
    }
    final element = '${quest['element'] ?? ''}';
    if (element.isNotEmpty &&
        oculumNormalizeElementId('${enemy['element'] ?? ''}') !=
            oculumNormalizeElementId(element)) {
      continue;
    }
    final enemyId = '${enemy['monsterSheetTag'] ?? ''}'.isNotEmpty
        ? '${enemy['monsterSheetTag']}'
        : '${enemy['id'] ?? ''}';
    if (enemyId.isEmpty || !receipts.add('$encounter:$enemyId')) continue;
    progress++;
  }
  if (before == progress) return false;
  item.craftData = {
    ...item.craftData,
    'titleEvolution': {
      ...quest,
      'progress': progress,
      'killReceipts': receipts.toList(),
    },
  };
  oculumApplyItemTitleEvolutionUpgrade(item);
  return true;
}

void oculumApplyItemTitleEvolutionUpgrade(InventoryItem item) {
  if (!oculumItemTitleEvolutionReady(item) ||
      item.craftData['titleEvolutionUpgradeApplied'] == true) {
    return;
  }
  final damage = item.arma ? max(2, (max(0, item.bonusDanno) * .2).ceil()) : 0;
  final defense = item.protegge
      ? max(2, (max(0, item.bonusDifesa) * .2).ceil())
      : 0;
  final shield = item.protegge
      ? max(5, (max(0, item.bonusScudo) * .2).ceil())
      : 0;
  item.bonusDanno += damage;
  item.bonusDifesa += defense;
  item.bonusScudo += shield;
  item.craftData = {
    ...item.craftData,
    'titleEvolutionUpgradeApplied': true,
    'titleEvolutionUpgrade': {
      'damage': damage,
      'defense': defense,
      'shield': shield,
    },
  };
}

extension _OculumItemTitles on _OculumHomePageState {
  Widget itemTitleEvolutionEditor(InventoryItem item) {
    final quest = oculumItemTitleEvolution(item);
    void setQuest(String key, dynamic value) {
      item.craftData = {
        ...item.craftData,
        'titleEvolution': {...oculumItemTitleEvolution(item), key: value},
      };
      oculumApplyItemTitleEvolutionUpgrade(item);
      programmaSalvataggio();
      setState(() {});
    }

    return ExpansionTile(
      title: const Text('Requisito di evoluzione · modificabile'),
      children: [
        campoModello(
          label: 'Richiede / descrizione',
          initialValue: '${quest['description'] ?? ''}',
          onChanged: (v) => setQuest('description', v),
        ),
        campoModello(
          label: 'Specie (ID del Monster Book; vuoto per usare l’elemento)',
          initialValue: '${quest['species'] ?? ''}',
          onChanged: (v) => setQuest('species', v.trim()),
        ),
        campoModello(
          label: 'Elemento richiesto (se non scegli una specie)',
          initialValue: '${quest['element'] ?? ''}',
          onChanged: (v) => setQuest('element', v.trim()),
        ),
        campoModello(
          label: 'Uccisioni richieste',
          initialValue: '${readIntValue(quest['requiredKills'], fallback: 5)}',
          onChanged: (v) =>
              setQuest('requiredKills', max(1, readIntValue(v, fallback: 5))),
        ),
        campoModello(
          label: 'Progresso verificato / rettifica del Master',
          initialValue: '${readIntValue(quest['progress'])}',
          onChanged: (v) => setQuest('progress', max(0, readIntValue(v))),
        ),
        campoModello(
          label: 'Buff Open · potenziamento Skill Open (%)',
          initialValue:
              '${readIntValue(item.craftData['titleOpenSkillBoostPercent'], fallback: 25)}',
          onChanged: (v) {
            item.craftData = {
              ...item.craftData,
              'titleOpenSkillBoostPercent': max(
                0,
                readIntValue(v, fallback: 25),
              ),
            };
            programmaSalvataggio();
          },
        ),
      ],
    );
  }

  bool itemTitleFormAvailable(InventoryItem item, CharacterSkillForm form) {
    final ability = oculumItemTitleAbilityForForm(item, form);
    if (ability == null) return true;
    if (!oculumItemTitleEvolutionReady(item)) return false;
    return ability.forme.indexOf(form) == 0
        ? !oculumItemTitleOpenIsActive(item, ability)
        : true;
  }

  void repairConvertedItemTitles() {
    for (final item in inventario) {
      if (item.craftData['titleItem'] == true &&
          item.craftData.containsKey('conversionDustCost') &&
          readIntValue(item.craftData['titleItemVersion']) == 0 &&
          oculumEquipmentCanBecomeTitle(item)) {
        oculumInitializeItemTitle(item);
      }
    }
  }

  List<String> equippedItemTitleIds() => [
    for (final item in inventario)
      if (item.quantita > 0 &&
          item.equipaggiata &&
          canEquipInventoryItem(item) &&
          item.craftData['titleItem'] == true &&
          '${item.craftData['titleItemId'] ?? ''}'.isNotEmpty)
        '${item.craftData['titleItemId']}',
  ];

  void advanceOwnedItemTitles(Iterable<Map> enemies, String encounter) {
    final owner = sheetTagAt(schedaCorrente);
    for (final item in inventario) {
      if (oculumAdvanceItemTitleKills(item, enemies, encounter, owner)) {
        aggiungiLog(
          '[TITOLO ITEM] ${item.nome}: ${oculumItemTitleSummary(item)}',
        );
      }
    }
  }
}
