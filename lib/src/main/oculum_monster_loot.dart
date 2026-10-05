part of '../../main.dart';

/// Generated once for a confirmed kill; no loot is awarded for a mere KO.
List<InventoryItem> oculumGenerateMonsterLoot({
  required MonsterBookEntry monster,
  required int level,
  required int grade,
  required Random random,
  required String killId,
}) {
  final safeGrade = grade.clamp(0, 12).toInt();
  final safeLevel = max(0, level);
  final art = oculumMonsterBookArt(monster);
  final selectedSkill = art.skills.isEmpty
      ? null
      : art.skills[random.nextInt(art.skills.length)];
  ArtSkill? forEquipment(String type) {
    if (art.skills.isEmpty) return null;
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
    final matches = art.skills
        .where((skill) => patterns.hasMatch('${skill.nome} ${skill.evo1}'))
        .toList();
    if (monster.id.startsWith('mammuth_in_decomposizione')) {
      return art.skills[type == 'weapon'
          ? 2
          : type == 'armor'
          ? 1
          : 0];
    }
    return matches.isEmpty ? art.skills.first : matches.first;
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
      : monster.dropIds.map((id) => id.replaceAll('_', ' ')).toList();
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
  if (selectedSkill != null) {
    final weapon = random.nextBool();
    drops.add(
      InventoryItem(
        nome: '${weapon ? 'Zanna' : 'Reliquia'} di ${monster.nameIt}',
        peso: 0,
        quantita: 1,
        arma: weapon,
        protegge: !weapon,
        gradoOggetto: safeGrade,
        gradoRichiesto: safeGrade,
        bonusDanno: weapon ? max(1, safeLevel + safeGrade) : 0,
        bonusDifesa: weapon ? 0 : max(1, safeGrade),
        note:
            'Generato all’uccisione. Skill ereditata: ${selectedSkill.nome}.\n${selectedSkill.evo1}\n${selectedSkill.evo2}\n${selectedSkill.evo3}',
        monsterLoot: {...metadata, 'id': '$killId:relic', 'material': false},
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
    if (!modalitaMaster && !isMasterHost && !realtimeIsMasterRole) return;
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
