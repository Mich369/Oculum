part of '../../main.dart';

String oculumMonsterDropName(String id) => switch (id) {
  'zanne_goblin' => 'Zanne di goblin',
  'pelle_mostro' => 'Pelle di mostro',
  'corno_forest_demon' || 'heavy_horn' => 'Corno di Forest Demon',
  'metallo_runico' => 'Metallo runico',
  'artigli_lupo' => 'Artigli di lupo',
  'carapace_scarabeo' => 'Carapace di scarabeo gigante',
  'denti_troll' => 'Denti di troll',
  'piume_arpia' => 'Piume di arpia',
  'occhio_basilisco' => 'Occhio di basilisco',
  'membrana_pipistrello' => 'Membrana di pipistrello gigante',
  _ =>
    id
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' '),
};

/// Generated once for a confirmed kill; no loot is awarded for a mere KO.
List<InventoryItem> oculumGenerateMonsterLoot({
  required MonsterBookEntry monster,
  required int level,
  required int grade,
  required Random random,
  required String killId,
  int? naturalDropRoll,
  int? dropTotal,
}) {
  final safeGrade = grade.clamp(0, 12).toInt();
  final safeLevel = max(0, level);
  final art = oculumMonsterBookArt(monster);
  if (monster.id == 'costrutto_rinsecchito') {
    final core = oculumCreatureCore(0, broken: true, maximumGrade: 3)
      ..nome = 'Nucleo rotto debole'
      ..note =
          'Nucleo del Costrutto Rinsecchito, fascia Grado 0–III. Riparabile con Meccanica secondo le regole dei nuclei.';
    return [
      core,
      InventoryItem(
        nome: 'Rami rinsecchiti',
        peso: .25,
        quantita: 1,
        note: 'Materiale del Costrutto Rinsecchito.',
        monsterLoot: {
          'id': '$killId:branches',
          'monsterId': monster.id,
          'material': true,
        },
      ),
      if (random.nextInt(100) <
          (monster.dropChances['cuore_rami_rinsecchiti'] ?? 3))
        InventoryItem(
          nome: 'Cuore di rami rinsecchiti',
          peso: .2,
          quantita: 1,
          note:
              'Consumabile: recupera il 90% della Vita massima entro il massimo; Ricordo Vitale per 1d9 turni, senza mantenimento.',
          craftData: {'witheredHeart': true},
          monsterLoot: {'id': '$killId:heart', 'monsterId': monster.id},
        ),
    ];
  }
  if (monster.id == 'larva_bianca') {
    final natural = naturalDropRoll ?? random.nextInt(20) + 1;
    if (natural < 1 || natural > 20) {
      throw ArgumentError.value(natural, 'naturalDropRoll');
    }
    final form = (safeLevel ~/ 3).clamp(0, 2);
    final scrollRank = safeGrade.clamp(0, 8);
    const romanRanks = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX'];
    final rankName = romanRanks[scrollRank];
    final scrollEffect = oculumLarvalBroodScrollEffect(scrollRank);
    return [
      if (natural == 20)
        InventoryItem(
          nome: 'Scroll Nidiata $rankName',
          peso: .05,
          quantita: 1,
          gradoOggetto: safeGrade,
          gradoRichiesto: safeGrade,
          note:
              'Monouso. Usa Infestazione nella forma del mostro; apprendimento raro secondo difficoltà, 20 naturale e DT di apprendimento.',
          craftData: {
            'scroll': {
              'id': 'white_larva_brood_rank_${scrollRank + 1}',
              'name': 'Nidiata $rankName',
              'kind': 'technique',
              'grade': safeGrade,
              'element': 'fisico',
              'description': oculumWitheredLarvaSkillText('white_larva_brood'),
              'willCost': 0,
              'cooldownTurns': oculumWitheredLarvaCooldown(
                'white_larva_brood',
                form,
              ),
              'effects': [scrollEffect.toJson()],
            },
          },
          monsterLoot: {
            'id': '$killId:brood-scroll',
            'monsterId': monster.id,
            'naturalDropRoll': natural,
            'form': scrollRank + 1,
            'monsterForm': form + 1,
          },
        ),
    ];
  }
  if (monster.id == 'slime_roccioso' ||
      monster.id.startsWith('slime_roccioso_variante_')) {
    final natural = naturalDropRoll ?? random.nextInt(20) + 1;
    if (natural < 1 || natural > 20) {
      throw ArgumentError.value(natural, 'naturalDropRoll');
    }
    final total = dropTotal ?? natural;
    return [
      InventoryItem(
        nome: 'Roccia Slime',
        peso: .25,
        quantita: 1,
        gradoOggetto: safeGrade,
        gradoRichiesto: safeGrade,
        note: 'Materiale — Roccia Slime, 250 g. Drop dello Slime Roccioso.',
        monsterLoot: {
          'id': '$killId:rock',
          'monsterId': monster.id,
          'material': true,
          'naturalDropRoll': natural,
          'dropTotal': total,
        },
      ),
      for (final skill in art.skills.where(
        (skill) =>
            (skill.nome == 'Indurimento' && (total >= 15 || natural == 20)) ||
            (skill.nome == 'Rimbalzo' && natural == 20),
      ))
        InventoryItem(
          nome: 'Tecnica dello Slime — ${skill.nome}',
          peso: 0,
          quantita: 1,
          gradoOggetto: safeGrade,
          gradoRichiesto: safeGrade,
          note:
              'Skill apprendibile: ${skill.nome}. Conserva le tre forme, i costi e i livelli del mostro. Tiro Drop $natural naturale, totale $total.',
          monsterLoot: {
            'id': '$killId:skill:${skill.nome}',
            'monsterId': monster.id,
            'learnableMonsterSkill': true,
            'skill': skill.toJson(),
            'naturalDropRoll': natural,
            'dropTotal': total,
          },
        ),
    ];
  }
  final activeSkills = art.skills
      .where(
        (skill) =>
            !skill.tipoPerLivello(1).toLowerCase().contains('passiv') &&
            !skill.evo1.toLowerCase().contains('passiva automatica'),
      )
      .toList();
  final selectedSkill = activeSkills.isEmpty
      ? null
      : activeSkills[random.nextInt(activeSkills.length)];
  ArtSkill? forEquipment(String type) {
    if (activeSkills.isEmpty) return null;
    final patterns = type == 'weapon'
        ? RegExp('carica|spadata|colp|attacc|danni|lacer', caseSensitive: false)
        : type == 'armor'
        ? RegExp(
            'cura|recuper|vita|rigener|difesa|corazz',
            caseSensitive: false,
          )
        : RegExp(
            'ossa|svantaggio|stun|scudo|immobil|presa',
            caseSensitive: false,
          );
    final matches = activeSkills
        .where((skill) => patterns.hasMatch('${skill.nome} ${skill.evo1}'))
        .toList();
    if (monster.id.startsWith('mammuth_in_decomposizione')) {
      return art.skills[type == 'weapon'
          ? 2
          : type == 'armor'
          ? 1
          : 0];
    }
    return matches.isEmpty ? null : matches.first;
  }

  final metadata = <String, dynamic>{
    'id': killId,
    'monsterId': monster.id,
    'monsterName': monster.nameIt,
    'monsterLevel': safeLevel,
    'monsterGrade': safeGrade,
    if (selectedSkill != null) 'skill': selectedSkill.toJson(),
    'skillsByEquipment': {
      for (final type in ['weapon', 'armor', 'shield'])
        if (forEquipment(type) != null) type: forEquipment(type)!.toJson(),
    },
  };
  final material = monster.id.startsWith('mammuth_in_decomposizione');
  final dropNames = material
      ? ['Ossa di mammuth putrido']
      : [
          for (final id in monster.dropIds)
            if (random.nextInt(100) <
                (monster.dropChances[id]?.clamp(0, 100) ?? 100))
              oculumMonsterDropName(id),
        ];
  final drops = <InventoryItem>[
    for (var i = 0; i < dropNames.length; i++)
      InventoryItem(
        nome: dropNames[i],
        peso: 0,
        quantita: 1,
        gradoOggetto: safeGrade,
        gradoRichiesto: safeGrade,
        note: material
            ? 'Materiale — Mammuth livello $safeLevel, grado $safeGrade. Arma: +$safeLevel Danni; armatura: +$safeGrade Difesa. La combinazione porta l’equipaggiamento almeno al grado del materiale, anche dal fabbro. Non puoi combinarlo da solo se il tuo grado è inferiore.'
            : 'Drop ottenuto all’uccisione di ${monster.nameIt}, livello $safeLevel, grado $safeGrade.',
        monsterLoot: {
          ...metadata,
          'id': '$killId:material:$i',
          'material': true,
          'weaponBonus': safeLevel,
          'armorBonus': safeGrade,
        },
      ),
  ];
  final natural = naturalDropRoll ?? random.nextInt(20) + 1;
  if (natural < 1 || natural > 20) {
    throw ArgumentError.value(natural, 'naturalDropRoll');
  }
  if (selectedSkill != null && (dropTotal ?? natural) >= 18) {
    final weapon = random.nextBool();
    final inherited = forEquipment(weapon ? 'weapon' : 'armor');
    if (inherited == null) return drops;
    final forestHorn = monster.id == 'forest_demon' && weapon;
    drops.add(
      InventoryItem(
        nome: forestHorn
            ? 'Corno Affilato del Forest Demon'
            : '${weapon ? 'Arma ricavata da' : 'Protezione ricavata da'} ${monster.nameIt}',
        peso: 0,
        quantita: 1,
        arma: weapon,
        protegge: !weapon,
        gradoOggetto: safeGrade,
        gradoRichiesto: safeGrade,
        bonusDanno: forestHorn
            ? 10
            : weapon
            ? max(1, safeLevel + safeGrade)
            : 0,
        buff: forestHorn ? '@Schianto+2' : '',
        ability: forestHorn
            ? oculumEquipmentAbility(
                'Corno Affilato del Forest Demon',
                safeGrade,
              )
            : oculumEquipmentAbilityFromArt(inherited),
        bonusDifesa: weapon ? 0 : max(1, safeGrade),
        note:
            'Drop raro (tiro Drop almeno 18). Skill ereditata: ${forestHorn ? "Carica del corno" : inherited.nome}.\n${forestHorn ? "150% danni per il turno, costo fisso 1 Volontà, CD 6." : inherited.evo1}',
        monsterLoot: {
          ...metadata,
          'id': '$killId:relic',
          'material': false,
          'skill': inherited.toJson(),
          'naturalDropRoll': natural,
          'dropTotal': dropTotal ?? natural,
        },
      ),
    );
  }
  return drops;
}

bool oculumCombineMonsterMaterial({
  required InventoryItem material,
  required InventoryItem equipment,
  required int characterGrade,
  bool blacksmith = false,
}) {
  if (identical(material, equipment) ||
      material.quantita <= 0 ||
      material.monsterLoot['material'] != true ||
      (!equipment.arma && !equipment.protegge) ||
      equipment.quantita != 1) {
    return false;
  }
  final grade = max(material.gradoOggetto, material.gradoRichiesto);
  if (!blacksmith && characterGrade < grade) return false;
  equipment.gradoOggetto = max(equipment.gradoOggetto, grade);
  equipment.gradoRichiesto = max(equipment.gradoRichiesto, grade);
  if (equipment.arma) {
    equipment.bonusDanno += readIntValue(material.monsterLoot['weaponBonus']);
  }
  if (equipment.protegge) {
    equipment.bonusDifesa += readIntValue(material.monsterLoot['armorBonus']);
  }
  final isShield =
      equipment.protegge &&
      (equipment.bonusScudo > 0 ||
          equipment.nome.toLowerCase().contains('scudo'));
  final type = isShield
      ? 'shield'
      : equipment.arma
      ? 'weapon'
      : 'armor';
  final roleSkills = material.monsterLoot['skillsByEquipment'];
  if (roleSkills is Map && roleSkills[type] is Map) {
    equipment.monsterLoot = {
      ...material.monsterLoot,
      'id': '${material.monsterLoot['id']}:$type:${equipment.nome}',
      'material': false,
      'skill': Map<String, dynamic>.from(roleSkills[type]),
    };
  }
  equipment.note =
      '${equipment.note}\nCombinato con ${material.nome} (grado $grade).';
  if (characterGrade < equipment.gradoRichiesto) equipment.equipaggiata = false;
  material.quantita--;
  return true;
}

extension _OculumMonsterLoot on _OculumHomePageState {
  MonsterBookEntry? monsterLootSourceForSheet(Map<String, dynamic> sheet) {
    final id = '${sheet['monsterBookSourceId'] ?? ''}';
    if (id.isNotEmpty) return monsterBookEntryById(id);
    if (!'${sheet['tipoScheda'] ?? ''}'.toLowerCase().contains('mostro')) {
      return null;
    }
    final name = '${sheet['nome'] ?? ''}'.trim().toLowerCase();
    final matches = monsterBookEntries
        .where((m) => m.nameIt.toLowerCase() == name)
        .toList();
    return matches.length == 1 ? matches.single : null;
  }

  void generateMonsterLootForDeath(int index) {
    if (index < 0 || index >= schedePersonaggio.length) return;
    final sheet = schedePersonaggio[index];
    if (sheet['monsterLootGenerated'] == true) return;
    final monster = monsterLootSourceForSheet(sheet);
    if (monster == null || monster.isNpc) return;
    final items = oculumGenerateMonsterLoot(
      monster: monster,
      level: readIntValue(sheet['livello']),
      grade: readIntValue(sheet['grado']),
      random: Random(),
      killId: '${sheetTagAt(index)}:${DateTime.now().microsecondsSinceEpoch}',
    );
    sheet['monsterLootGenerated'] = true;
    sheet['monsterLootGeneratedAt'] = DateTime.now().toIso8601String();
    if (index == schedaCorrente) {
      inventario.addAll(items);
    } else {
      final inventory = List<dynamic>.from(
        sheet['inventario'] as List? ?? const [],
      );
      inventory.addAll(items.map((item) => item.toJson()));
      sheet['inventario'] = inventory;
    }
    aggiungiLog(
      'Drop di ${monster.nameIt}: ${items.map((item) => item.nome).join(', ')}. Conservati nell’inventario della creatura per la distribuzione.',
    );
  }

  Future<void> confirmMonsterKill(int tokenIndex) async {
    if (!canActWithoutMasterApproval) return;
    final token = masterInitiativeTokens[tokenIndex];
    final index = masterInitiativeSheetIndexForToken(token);
    if (index < 0 ||
        monsterLootSourceForSheet(schedePersonaggio[index]) == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Conferma uccisione di ${token['name']}'),
        content: const Text(
          'Segna la morte e genera il bottino una sola volta. Un incontro, una fuga o un KO non generano drop.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ucciso: genera drop'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    refreshOculumHome(() {
      token['status'] = 'dead';
      token['downed'] = false;
      token['deathWounds'] = 3;
      token['currentHp'] = 0;
      applyMasterInitiativeTokenVitalsToSource(token);
      generateMonsterLootForDeath(index);
      salvaSchedaCorrenteInMemoria();
    });
    await forzaSalvataggioImmediato(soloLocale: true);
    sendRealtimeInitiativeSnapshotIfPublished();
  }

  Future<void> combineMonsterMaterial(InventoryItem material) async {
    final choices = inventario
        .where(
          (item) =>
              !identical(item, material) &&
              (item.arma || item.protegge) &&
              item.quantita == 1,
        )
        .toList();
    InventoryItem? equipment;
    var blacksmith = false;
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: const Text('Combina materiale del mostro'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${material.nome} — grado ${material.gradoOggetto}. Il risultato conserva almeno questo grado, anche dal fabbro.',
                ),
                DropdownButtonFormField<InventoryItem>(
                  items: choices
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.nome),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => refresh(() => equipment = value),
                  decoration: const InputDecoration(
                    labelText: 'Arma o armatura (una unità)',
                  ),
                ),
                CheckboxListTile(
                  value: blacksmith,
                  onChanged: (value) =>
                      refresh(() => blacksmith = value ?? false),
                  title: const Text('Lavorazione presso un fabbro'),
                ),
                if (leggiNumero(gradoController) < material.gradoOggetto)
                  const Text(
                    'Grado insufficiente: serve un fabbro. Il risultato non sarà equipaggiabile finché non raggiungi quel grado.',
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed:
                  equipment == null ||
                      (!blacksmith &&
                          leggiNumero(gradoController) < material.gradoOggetto)
                  ? null
                  : () => Navigator.pop(context, true),
              child: const Text('Combina'),
            ),
          ],
        ),
      ),
    );
    if (!mounted ||
        approved != true ||
        equipment == null ||
        !inventario.contains(material) ||
        !inventario.contains(equipment)) {
      return;
    }
    refreshOculumHome(() {
      if (oculumCombineMonsterMaterial(
        material: material,
        equipment: equipment!,
        characterGrade: leggiNumero(gradoController),
        blacksmith: blacksmith,
      )) {
        if (material.quantita == 0) inventario.remove(material);
        aggiungiLog(
          'Combinazione: ${equipment!.nome}, grado ${equipment!.gradoOggetto}.',
        );
      }
    });
    programmaSalvataggio();
  }

  bool monsterLootArtCanUse(CharacterArt art) {
    if (!art.tipo.startsWith('Art Oggetto Drop:')) return true;
    final id = art.tipo.substring('Art Oggetto Drop:'.length);
    return inventario.any(
      (item) =>
          item.monsterLoot['id'] == id &&
          item.equipaggiata &&
          item.quantita > 0 &&
          canEquipInventoryItem(item),
    );
  }

  void openMonsterLootSkill(InventoryItem item) {
    if (item.monsterLoot['skill'] is! Map) return;
    if (item.monsterLoot['learnableMonsterSkill'] == true) {
      if (!inventario.contains(item) || item.quantita <= 0) return;
      final skill = ArtSkill.fromJson(
        Map<String, dynamic>.from(item.monsterLoot['skill']),
      );
      if (arti.any(
        (art) => art.skills.any((known) => known.nome == skill.nome),
      )) {
        aggiungiLog(
          'Tecnica già conosciuta: ${skill.nome}; il drop non viene consumato.',
        );
        return;
      }
      refreshOculumHome(() {
        arti.add(
          CharacterArt(
            nome: 'Tecnica appresa — ${skill.nome}',
            tipo: 'Tecnica mostro appresa',
            hasIntegrity: false,
            descrizione:
                'Tecnica appresa dal drop dello Slime Roccioso: mantiene forme, costi e livelli originali.',
            skills: [skill],
          ),
        );
        item.quantita--;
        if (item.quantita == 0) inventario.remove(item);
        risultato =
            'Appresa ${skill.nome} dal drop dello Slime Roccioso. Disponibile nelle Art, con i livelli e i costi originali.';
        aggiungiLog(risultato);
      });
      programmaSalvataggio();
      notifyDiceResultChanged();
      return;
    }
    final type = 'Art Oggetto Drop:${item.monsterLoot['id']}';
    if (!arti.any((art) => art.tipo == type)) {
      refreshOculumHome(
        () => arti.add(
          CharacterArt(
            nome: 'Skill — ${item.nome}',
            tipo: type,
            hasIntegrity: false,
            descrizione:
                'Skill dell’oggetto. Richiede questo oggetto equipaggiato e il grado ${item.gradoRichiesto}.',
            skills: [
              ArtSkill.fromJson(
                Map<String, dynamic>.from(item.monsterLoot['skill']),
              ),
            ],
          ),
        ),
      );
      programmaSalvataggio();
    }
    risultato =
        'Skill disponibile nelle Art: equipaggia ${item.nome} per usarla. I livelli e i costi originali del mostro restano validi.';
    aggiungiLog(risultato);
    notifyDiceResultChanged();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(risultato)));
  }
}
