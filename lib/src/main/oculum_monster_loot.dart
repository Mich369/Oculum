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

/// Builds the codex of monster relics from authored monster Arts/Skills. The
/// creature's base statistics are deliberately not copied onto the item.
List<InventoryItem> oculumMonsterEquipmentCatalogue({
  MonsterBookEntry? source,
  int? level,
  int? grade,
}) {
  final entries = source == null ? defaultMonsterBookEntries : [source];
  final result = <InventoryItem>[];
  const equipment = <String, String>{
    'weapon': 'Spada',
    'armor': 'Armatura',
    'shield': 'Scudo',
  };
  for (final monster in entries) {
    if (monster.isNpc || monster.id.startsWith('pawn_guardiano')) continue;
    final art = oculumMonsterBookArt(monster);
    final postea = monster.planeIds.contains('postea');
    final sweet = monster.planeIds.contains('caramella');
    final style = postea
        ? 'Tecnologia runica: piastre composite, circuiti incisi e innesti riparabili.'
        : sweet
        ? 'Manifattura dolciaria: caramello temprato, zucchero cristallino e cacao compatto.'
        : monster.planeIds.contains('morti')
        ? 'Manifattura antica: osso inciso, cuoio rituale e metallo funerario.'
        : 'Manifattura del suo habitat: materiali e segni riconoscibili della creatura.';
    final skills = art.skills
        .where(
          (skill) =>
              !skill.tipoPerLivello(1).toLowerCase().contains('passiv') &&
              !skill.evo1.toLowerCase().contains('passiva automatica'),
        )
        .toList();
    if (skills.isEmpty) continue;
    final itemLevel = max(0, level ?? readIntValue(monster.stats['level']));
    final itemGrade = (grade ?? readIntValue(monster.stats['grade']))
        .clamp(0, 12)
        .toInt();
    for (var skillIndex = 0; skillIndex < skills.length; skillIndex++) {
      final skill = skills[skillIndex];
      for (final type in equipment.keys) {
        final weapon = type == 'weapon';
        final armor = type == 'armor';
        final damage = max(1, 2 + itemLevel + itemGrade * 2);
        final defense = max(1, 1 + itemLevel ~/ 2 + itemGrade);
        final itemId = 'monster-relic:${monster.id}:$skillIndex:$type';
        final weapons = postea
            ? [
                'Lama al plasma',
                'Fucile runico',
                'Mazza a impulso',
                'Lancia elettrica',
              ]
            : sweet
            ? [
                'Lancia di candy cane',
                'Lama di zucchero',
                'Martello di caramello',
                'Arco di liquirizia',
              ]
            : ['Spada', 'Lancia', 'Ascia', 'Arco', 'Pugnale', 'Mazza'];
        final familyName = weapon
            ? weapons[(oculumMonsterArtSeed(monster.id) + skillIndex) %
                  weapons.length]
            : armor
            ? (postea
                  ? 'Armatura cyberpunk'
                  : sweet
                  ? 'Corazza di cacao'
                  : 'Armatura antica')
            : postea
            ? 'Scudo a piastre runiche'
            : sweet
            ? 'Scudo di caramello'
            : equipment[type];
        final name = '$familyName di ${monster.nameIt} · ${skill.nome}';
        result.add(
          InventoryItem(
            nome: name,
            peso: weapon
                ? 1.2
                : armor
                ? 2.0
                : 1.0,
            quantita: 1,
            note:
                'Reliquia rara di ${monster.nameIt}. $style Riprende la Skill ${skill.nome} e il suo elemento ${monster.elementId}; non copia le statistiche base della creatura. Grado $itemGrade, livello $itemLevel. Richiede il livello $itemLevel per usare la Skill.',
            arma: weapon,
            protegge: !weapon,
            bonusDanno: weapon ? damage : 0,
            bonusDifesa: weapon
                ? 0
                : type == 'shield'
                ? defense
                : defense + 1,
            bonusScudo: type == 'shield' ? 10 + itemLevel * 3 : 0,
            bonusScudoOculum: type == 'shield' ? 3 + itemGrade : 0,
            gradoOggetto: itemGrade,
            gradoRichiesto: itemGrade,
            livelloOggetto: itemLevel,
            puntiStatPerLivello: 1 + skillIndex % 3,
            statCrescita: weapon
                ? 'forza'
                : armor
                ? 'resilienza'
                : 'materia',
            elementoDanno: monster.elementId,
            ability: oculumEquipmentAbilityFromArt(skill),
            craftData: {
              'monsterRelic': true,
              'monsterRelicMarketPrice': oculumMonsterRelicMarketPrice(
                level: itemLevel,
                grade: itemGrade,
              ),
              'manualPriceObser': oculumMonsterRelicMarketPrice(
                level: itemLevel,
                grade: itemGrade,
              ),
              'foundBuffChancePercent': 20,
              'foundRareBuffChancePercent': 5,
              'foundBuffOptions': ['four_stats', 'combat_subtraits'],
              'monsterId': monster.id,
              'itemFamily': type,
              'element': monster.elementId,
              'skillLevelRequired': itemLevel,
              'sourceSkillId': skill.nome,
              'sourceSkill': skill.toJson(),
            },
            monsterLoot: {
              'id': itemId,
              'monsterId': monster.id,
              'monsterName': monster.nameIt,
              'itemFamily': type,
              'rareMonsterEquipment': true,
              'skill': skill.toJson(),
            },
          ),
        );
      }
    }
  }
  return result;
}

int oculumMonsterRelicDropThreshold(int grade) =>
    25 + 2 * grade.clamp(0, 12).toInt();

int oculumMonsterDropDifficulty({required int level, required int grade}) =>
    20 + max(0, level).toInt() + 3 * grade.clamp(0, 12).toInt();

int oculumMonsterRelicMarketPrice({required int level, required int grade}) {
  final safeGrade = grade.clamp(0, 12).toInt();
  return oculumMerchantEquipmentMinimumPrice(safeGrade) +
      max(0, level - safeGrade * 5) * 10;
}

List<InventoryItem> _withManualDropPrices(
  List<InventoryItem> items, {
  required int level,
  required int grade,
}) {
  for (final item in items) {
    final relicPrice = item.arma || item.protegge
        ? oculumMonsterRelicMarketPrice(level: level, grade: grade)
        : max(1, level ~/ 2 + grade * 3 + 1);
    item.craftData = {
      ...item.craftData,
      'manualPriceObser': readIntValue(item.craftData['manualPriceObser']) > 0
          ? readIntValue(item.craftData['manualPriceObser'])
          : relicPrice,
    };
  }
  return items;
}

const _monsterRelicStatBuffs = <String>[
  'Resilienza',
  'Volontà',
  'Materia',
  'Oculum',
];

const _monsterRelicSubtraitBuffs = <String>[
  'Adattamento',
  'Canalizzazione',
  'Concentrazione',
  'Forza',
  'Fortuna',
  'Furbizia',
  'Investigazione',
  'Manifestazione del Potere',
  'Movimento',
  'Percezione',
  'Precisione',
  'Resistenza',
  'Riflessi',
  'Schianto',
  'Valutazione',
  'Velo',
];

/// A rare optional affix can improve one core stat or combat subtrait.
/// Probabilities and the rolled value are persisted with the generated item.
Map<String, dynamic>? oculumRollMonsterRelicFoundBuff(Random random) {
  final roll = random.nextInt(100);
  final amount = roll < 5
      ? 2
      : roll < 25
      ? 1
      : 0;
  if (amount == 0) return null;
  final targets = <String>[
    ..._monsterRelicStatBuffs,
    ..._monsterRelicSubtraitBuffs,
  ];
  final target = targets[random.nextInt(targets.length)];
  return {
    'target': target,
    'amount': amount,
    'kind': _monsterRelicStatBuffs.contains(target) ? 'stat' : 'subtrait',
    'command': '@$target+$amount',
    'probabilityPercent': amount == 2 ? 5 : 20,
  };
}

/// Generated once for a confirmed kill; no loot is awarded for a mere KO.
List<InventoryItem> oculumGenerateMonsterLoot({
  required MonsterBookEntry monster,
  required int level,
  required int grade,
  required Random random,
  required String killId,
  int? naturalDropRoll,
  int? dropTotal,
  String finishingElement = '',
  String finishingSkillId = '',
  Map combatHistory = const {},
}) {
  final safeGrade = grade.clamp(0, 12).toInt();
  final safeLevel = max(0, level);
  final natural = naturalDropRoll ?? random.nextInt(20) + 1;
  if (natural < 1 || natural > 20) {
    throw ArgumentError.value(natural, 'naturalDropRoll');
  }
  final resolvedDropTotal = dropTotal ?? natural;
  final dropDifficulty = oculumMonsterDropDifficulty(
    level: safeLevel,
    grade: safeGrade,
  );
  if (monster.id == 'pupazzo_robotico_postea') {
    return [oculumDollRobotScraps(monster, safeLevel, safeGrade, killId)];
  }
  final planarDrops = oculumPlanarNaturalDrops(
    monster,
    safeLevel,
    safeGrade,
    natural,
    killId,
    finishingElement: finishingElement,
    finishingSkillId: finishingSkillId,
    combatHistory: combatHistory,
    dropTotal: resolvedDropTotal,
  );
  if (planarDrops != null) {
    return _withManualDropPrices(
      [
        ...planarDrops,
        if (!planarDrops.any((i) => i.arma || i.protegge) &&
            resolvedDropTotal >= oculumMonsterRelicDropThreshold(safeGrade) &&
            random.nextInt(100) < 10)
          ...((oculumMonsterEquipmentCatalogue(
            source: monster,
            level: safeLevel,
            grade: safeGrade,
          )..shuffle(random)).take(1)),
        if (monster.id == 'pupazzo_artigliato' && resolvedDropTotal >= 43)
          oculumDollCostume(monster, safeLevel, safeGrade, killId, random),
      ],
      level: safeLevel,
      grade: safeGrade,
    );
  }
  final cycleScrollDrops = <InventoryItem>[];
  if (oculumMonsterCyclePhase(monster).isNotEmpty &&
      monster.skillIds.isNotEmpty) {
    final minimum = readIntValue(
      monster.encounterRules['cycleScrollNaturalMinimum'],
      fallback: 18,
    ).clamp(1, 20);
    if (natural >= minimum) {
      final skillIds = natural == 20
          ? monster.skillIds
          : [monster.skillIds[(natural - minimum) % monster.skillIds.length]];
      for (final id in skillIds) {
        cycleScrollDrops.add(
          oculumPlanarTechniqueScroll(
            monster,
            id,
            receipt: '$killId:$id',
            level: safeLevel,
            grade: safeGrade,
          ),
        );
      }
    }
  }
  // Authored Slime drops use their own threshold (Indurimento at 15).
  final isRockSlime =
      monster.id == 'slime_roccioso' ||
      monster.id.startsWith('slime_roccioso_variante_');
  if (resolvedDropTotal < dropDifficulty && !isRockSlime) {
    return _withManualDropPrices(
      cycleScrollDrops,
      level: safeLevel,
      grade: safeGrade,
    );
  }
  final art = oculumMonsterBookArt(monster);
  if (monster.id == 'costrutto_rinsecchito') {
    final core = oculumCreatureCore(0, broken: true, maximumGrade: 3)
      ..nome = 'Nucleo rotto debole'
      ..note =
          'Nucleo del Costrutto Rinsecchito, fascia Grado 0–III. Riparabile con Meccanica secondo le regole dei nuclei.';
    return _withManualDropPrices(
      [
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
      ],
      level: safeLevel,
      grade: safeGrade,
    );
  }
  if (monster.id == 'larva_bianca') {
    final form = (safeLevel ~/ 3).clamp(0, 2);
    final scrollRank = safeGrade.clamp(0, 8);
    const romanRanks = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX'];
    final rankName = romanRanks[scrollRank];
    final scrollEffect = oculumLarvalBroodScrollEffect(scrollRank);
    return _withManualDropPrices(
      [
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
                'description': oculumWitheredLarvaSkillText(
                  'white_larva_brood',
                ),
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
      ],
      level: safeLevel,
      grade: safeGrade,
    );
  }
  if (isRockSlime) {
    final total = resolvedDropTotal;
    return _withManualDropPrices(
      [
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
            'dropDifficulty': dropDifficulty,
          },
        ),
        for (final skill in art.skills.where(
          (skill) =>
              (skill.nome == 'Indurimento' && total >= 15) ||
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
              'dropDifficulty': dropDifficulty,
            },
          ),
      ],
      level: safeLevel,
      grade: safeGrade,
    );
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
  final specialDrops = <InventoryItem>[...cycleScrollDrops];
  if (monster.id == 'fata_cacciatrice') {
    final natural = naturalDropRoll ?? random.nextInt(20) + 1;
    if (natural < 1 || natural > 20) {
      throw ArgumentError.value(natural, 'naturalDropRoll');
    }
    final total = dropTotal ?? natural;
    final guaranteedWings = total >= 50;
    return _withManualDropPrices(
      [
        for (var i = 0; i < 2; i++)
          if (guaranteedWings)
            InventoryItem(
              nome: 'Mezza ala di fata',
              peso: .05,
              quantita: 1,
              gradoOggetto: safeGrade,
              gradoRichiesto: safeGrade,
              livelloOggetto: safeLevel,
              note: guaranteedWings
                  ? 'Componente per forgiare le Ali del Fato. Tiro Drop totale $total: le due mezze ali sono garantite.'
                  : 'Componente raro per forgiare le Ali del Fato: servono due mezze ali. Tiro Drop totale $total.',
              monsterLoot: {
                ...metadata,
                'id': '$killId:fairy-wing:$i',
                'material': true,
                'naturalDropRoll': natural,
                'dropTotal': total,
                'dropDifficulty': dropDifficulty,
                'guaranteedAtDropTotal': 50,
              },
            ),
      ],
      level: safeLevel,
      grade: safeGrade,
    );
  }
  if (monster.id == 'patalpa_dolce' &&
      resolvedDropTotal >= oculumMonsterRelicDropThreshold(safeGrade) &&
      random.nextInt(100) < 10) {
    final armorShield = 6 + 6 * safeLevel + 4 * safeGrade * safeLevel;
    final summonAbility = CharacterSkill(
      nome: 'Richiamo del Patalpa',
      tipo: 'Evocazione',
      costo: '1 azione',
      cooldown: '1 uso ogni 3 fight',
      descrizione:
          'Richiama un Patalpa del tuo livello che combatte con te per tutto il fight. Distribuisce il suo budget 20% Resilienza, 50% Volontà e 30% Materia; nel 75% degli spawn non riceve il bonus +1 Resilienza per livello, nel 25% lo riceve. È una Summon: se sconfitta, dà al massimo 5 + Grado EXP una sola volta al party; chi la evoca non riceve EXP, salvo che il Fato la renda realmente ostile.',
      equipaggiata: true,
    );
    specialDrops.add(
      InventoryItem(
        nome: 'Armatura del Patalpa',
        peso: 2.2,
        quantita: 1,
        note:
            'Ha un ottimo sapore per quanto difenda poco e un buon odore. +2 Materia, +1 Volontà, +1 Resilienza; +5 Difesa e $armorShield Scudo (6 base +6 per livello dell’oggetto +4 × livello per ogni Grado). Richiede Grado $safeGrade e livello $safeLevel per la skill. Richiamo: evoca un Patalpa del tuo livello con 20% Resilienza, 50% Volontà e 30% Materia; nel 75% degli spawn manca il bonus +1 Resilienza/livello, nel 25% è presente. Drop raro: totale (dado + bonus) almeno ${oculumMonsterRelicDropThreshold(safeGrade)} e 10% di possibilità.',
        buff: '@Materia+2 @Volontà+1 @Resilienza+1',
        protegge: true,
        bonusDifesa: 5,
        bonusScudo: armorShield,
        bonusScudoIncludeGrado: true,
        gradoOggetto: safeGrade,
        gradoRichiesto: safeGrade,
        livelloOggetto: safeLevel,
        puntiStatPerLivello: 1,
        statCrescita: 'resilienza',
        elementoDanno: 'Natura',
        ability: summonAbility,
        craftData: {
          'monsterRelic': true,
          'monsterRelicMarketPrice': oculumMonsterRelicMarketPrice(
            level: safeLevel,
            grade: safeGrade,
          ),
          'skillLevelRequired': safeLevel,
          'shieldScaling': {
            'base': 6,
            'perItemLevel': 6,
            'perGradePerItemLevel': 4,
            'formula': '6 + 6*itemLevel + 4*grade*itemLevel',
          },
          'summon': {
            'kind': 'patalpa_richiamo',
            'duration': 'fight',
            'level': 'wearer',
            'expPool': '5+grade',
          },
        },
        monsterLoot: {
          ...metadata,
          'id': '$killId:patalpa-armor',
          'material': false,
          'relicFamily': 'patalpa_armor',
          'naturalDropRoll': natural,
          'dropTotal': resolvedDropTotal,
          'dropThreshold': oculumMonsterRelicDropThreshold(safeGrade),
          'dropDifficulty': dropDifficulty,
        },
      ),
    );
  }
  final material = monster.id.startsWith('mammuth_in_decomposizione');
  final dropNames = material
      ? (random.nextInt(100) < 35 ? ['Ossa di mammuth putrido'] : <String>[])
      : [
          for (final id in monster.dropIds)
            if (random.nextInt(100) <
                (monster.dropChances[id]?.clamp(0, 100) ?? 35))
              oculumMonsterDropName(id),
        ];
  final drops = <InventoryItem>[
    ...specialDrops,
    if (!monster.isNpc &&
        !RegExp(
          r'costrutto|construct|golem|automata|morto vivente|undead',
        ).hasMatch('${monster.id} ${monster.nameIt}'.toLowerCase()) &&
        random.nextInt(100) < 45)
      InventoryItem(
        nome: 'Carne di mostro cruda',
        peso: .3 + safeGrade * .05,
        quantita: 1,
        gradoOggetto: safeGrade,
        note:
            'Cibo da cuocere, ricavato da ${monster.nameIt}. Non consumare cruda: crea una ricetta di cucina con cottura e ingredienti compatibili.',
        putrefazioneSessioni: 2,
        monsterLoot: {
          ...metadata,
          'id': '$killId:raw-monster-meat',
          'material': false,
          'foodIngredient': true,
          'raw': true,
        },
      ),
    for (var i = 0; i < dropNames.length; i++)
      InventoryItem(
        nome: dropNames[i],
        peso: oculumMonsterCyclePhase(monster).isNotEmpty ? .15 : 0,
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
  if ((monster.id == 'slime_blu' ||
          monster.id == 'slime_blu_helmeted' ||
          monster.id == 'slime_blu_corazzato') &&
      resolvedDropTotal >= oculumMonsterRelicDropThreshold(safeGrade)) {
    final levelBonus = max(1, safeLevel);
    drops.add(
      InventoryItem(
        nome: 'Elmetto-scudo di melma blu',
        peso: .8,
        quantita: 1,
        arma: true,
        protegge: true,
        gradoOggetto: safeGrade,
        gradoRichiesto: safeGrade,
        livelloOggetto: safeLevel,
        puntiStatPerLivello: 1 + random.nextInt(3),
        statCrescita: 'resilienza',
        bonusDanno: levelBonus,
        bonusDifesa: levelBonus,
        bonusScudoOculum: 10 + safeLevel,
        elementoDanno: 'Slime',
        ability: oculumEquipmentAbility(
          'Elmetto-scudo dello Slime Blu',
          safeGrade,
        ),
        note:
            'Relitto elementale dello Slime Blu, livello $safeLevel, grado $safeGrade: +$levelBonus Danni Slime, +$levelBonus Difesa, +${10 + safeLevel} Scudo Oculum. Richiede grado $safeGrade; la skill richiede livello $safeLevel. Drop raro: totale (dado + bonus) almeno ${oculumMonsterRelicDropThreshold(safeGrade)}; DT Drop $dropDifficulty.',
        craftData: {
          'monsterRelic': true,
          'monsterRelicMarketPrice': oculumMonsterRelicMarketPrice(
            level: safeLevel,
            grade: safeGrade,
          ),
        },
        monsterLoot: {
          ...metadata,
          'id': '$killId:blue-slime-helm-shield',
          'material': false,
          'relicFamily': 'slime_element_helm_shield',
          'naturalDropRoll': natural,
          'dropTotal': resolvedDropTotal,
        },
      ),
    );
  }
  final relicThreshold = oculumMonsterRelicDropThreshold(safeGrade);
  if (selectedSkill != null && resolvedDropTotal >= relicThreshold) {
    final options = oculumMonsterEquipmentCatalogue(
      source: monster,
      level: safeLevel,
      grade: safeGrade,
    );
    if (options.isNotEmpty) {
      final relic = InventoryItem.fromJson(
        options[random.nextInt(options.length)].toJson(),
      );
      relic.monsterLoot = {
        ...relic.monsterLoot,
        ...metadata,
        'id': '$killId:relic:${relic.craftData['itemFamily']}',
        'naturalDropRoll': natural,
        'dropTotal': resolvedDropTotal,
        'dropThreshold': relicThreshold,
        'dropDifficulty': dropDifficulty,
      };
      relic.craftData = {
        ...relic.craftData,
        'monsterRelicMarketPrice': oculumMonsterRelicMarketPrice(
          level: safeLevel,
          grade: safeGrade,
        ),
      };
      if (monster.id == 'forest_demon' && relic.nome.startsWith('Armatura')) {
        relic
          ..nome = 'Corazza scheletrica del Forest Demon'
          ..bonusDifesa = max(1, safeLevel * 2)
          ..bonusScudo = safeLevel * 20
          ..ability = oculumForestDemonArmorAbility(safeLevel)
          ..note =
              'Livello $safeLevel. +${max(1, safeLevel * 2)} Difesa, +${safeLevel * 20} Scudo. Skill: +5 Volontà per 1 turno; pronta a inizio fight, CD 3 turni. Richiede livello $safeLevel.';
      }
      final foundBuff = oculumRollMonsterRelicFoundBuff(random);
      relic.craftData = {
        ...relic.craftData,
        'manualPriceObser': oculumMonsterRelicMarketPrice(
          level: safeLevel,
          grade: safeGrade,
        ),
        'foundBuffChancePercent': 20,
        'foundRareBuffChancePercent': 5,
        if (foundBuff != null) ...{'foundBuff': foundBuff},
      };
      if (foundBuff != null) {
        final command = '${foundBuff['command']}';
        relic.buff = [
          relic.buff,
          command,
        ].where((text) => text.trim().isNotEmpty).join(' ');
        relic.note = '${relic.note}\nAffisso trovato: $command.';
      }
      relic.note =
          '${relic.note}\nDrop raro, totale $resolvedDropTotal (dado + bonus). Skill e statistiche dell’oggetto restano modificabili.';
      drops.add(relic);
    }
  }
  for (final item in drops) {
    if (!item.arma && !item.protegge) {
      item.craftData = {
        ...item.craftData,
        'manualPriceObser': readIntValue(item.craftData['manualPriceObser']) > 0
            ? readIntValue(item.craftData['manualPriceObser'])
            : max(1, safeLevel ~/ 2 + safeGrade * 3 + 1),
      };
      continue;
    }
    final price = oculumMonsterRelicMarketPrice(
      level: safeLevel,
      grade: safeGrade,
    );
    if (item.craftData['foundBuffChancePercent'] == null) {
      final foundBuff = oculumRollMonsterRelicFoundBuff(random);
      item.craftData = {
        ...item.craftData,
        'monsterRelicMarketPrice': price,
        'manualPriceObser': price,
        'foundBuffChancePercent': 20,
        'foundRareBuffChancePercent': 5,
        if (foundBuff != null) ...{'foundBuff': foundBuff},
      };
      if (foundBuff != null) {
        final command = '${foundBuff['command']}';
        item.buff = [
          item.buff,
          command,
        ].where((text) => text.trim().isNotEmpty).join(' ');
        item.note = '${item.note}\nAffisso trovato: $command.';
      }
    }
  }
  return _withManualDropPrices(drops, level: safeLevel, grade: safeGrade);
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
  Widget pendingMonsterLootPanel() {
    final pending = <Map<String, dynamic>>[];
    final seen = <String>{};
    for (final token in masterInitiativeTokens) {
      if (!oculumEncounterEnemyKilled(token) ||
          masterInitiativeTokenIsTemporary(token)) {
        continue;
      }
      final sourceTag = publicInitiativeSourceTag(token);
      if (sourceTag.isNotEmpty && !seen.add(sourceTag)) continue;
      final sheetIndex = masterInitiativeSheetIndexForToken(token);
      final monster = sheetIndex >= 0
          ? monsterLootSourceForSheet(schedePersonaggio[sheetIndex])
          : monsterBookEntryById('${token['monsterBookId'] ?? ''}');
      if (monster == null || monster.isNpc) continue;
      pending.add(token);
    }
    if (pending.isEmpty || !canActWithoutMasterApproval) {
      return const SizedBox.shrink();
    }
    return Card(
      child: ExpansionTile(
        title: Text('Drop di fine scontro · ${pending.length}'),
        leading: const Icon(Icons.casino_outlined),
        subtitle: const Text(
          'Tiri e distribuzione si completano quando termini lo scontro.',
        ),
        children: [
          for (final token in pending)
            ListTile(
              title: Text('${token['name'] ?? 'Mostro'}'),
              subtitle: const Text('Il drop verrà tirato a fine scontro.'),
              trailing: const Icon(Icons.schedule),
            ),
        ],
      ),
    );
  }

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
    if (sheet['monsterLootPending'] == true) return;
    sheet['monsterLootPending'] = true;
    sheet['monsterLootDefeatedLevel'] = readIntValue(sheet['livello']);
    sheet['monsterLootDefeatedGrade'] = readIntValue(sheet['grado']);
    faunaConfirmedKills([
      {
        'id': sheetTagAt(index),
        'monsterSheetTag': sheetTagAt(index),
        'killerTag': sheet['lastDamageSourceTag'],
        'monsterBookId': monster.id,
        'level': readIntValue(sheet['livello']),
        'finisher': sheet['lastPlanarFinisher'] ?? const {},
      },
    ], onlineCombatEncounterId);
    if (canManagePartyQuests) {
      partyChest['revision'] = readIntValue(partyChest['revision']) + 1;
      unawaited(sendPartyChestState());
    }
    aggiungiLog('Morte confermata di ${monster.nameIt}: tiro Drop in attesa.');
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
          'Segna la morte. Il tiro Drop del mostro verrà effettuato una sola volta al termine dello scontro. Un incontro, una fuga o un KO non generano drop.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ucciso: registra drop di fine scontro'),
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
