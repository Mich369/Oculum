part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

bool oculumSkillRequirementsMet(
  Map requirements, {
  required int level,
  required Map<String, int> subtraits,
  required int kills,
  required Map<String, int> elementalKills,
  required Map<String, int> skillCriticals,
  bool open = false,
  int grade = 0,
  Map<String, int> stats = const {},
  Map<String, int> speciesKills = const {},
  Map<String, int> namedNpcKills = const {},
}) {
  if (level < readIntValue(requirements['level'])) return false;
  if (grade < readIntValue(requirements['grade'])) return false;
  final stat = oculumStatKey('${requirements['stat'] ?? ''}');
  if (stat.isNotEmpty &&
      (stats[stat] ?? 0) < readIntValue(requirements['statValue'])) {
    return false;
  }
  final trait = '${requirements['subtrait'] ?? ''}';
  if (trait.isNotEmpty &&
      (subtraits[trait] ?? 0) < readIntValue(requirements['subtraitValue'])) {
    return false;
  }
  final anyKills = max(0, readIntValue(requirements['kills']));
  final element = '${requirements['element'] ?? ''}';
  final specific = max(0, readIntValue(requirements['elementKills']));
  final anyMet = kills >= anyKills;
  final specificMet = (elementalKills[element] ?? 0) >= specific;
  if (requirements['killsEither'] == true &&
      anyKills > 0 &&
      specific > 0 &&
      element.isNotEmpty) {
    if (!anyMet && !specificMet) return false;
  } else if (!anyMet || specific > 0 && !specificMet) {
    return false;
  }
  final criticalSkill = '${requirements['criticalSkill'] ?? ''}';
  if (requirements['namedNpcKills'] is Map) {
    for (final entry in (requirements['namedNpcKills'] as Map).entries) {
      if ((namedNpcKills['${entry.key}'] ?? 0) < readIntValue(entry.value)) {
        return false;
      }
    }
  }
  final species = '${requirements['species'] ?? ''}';
  if (requirements['speciesKills'] is Map) {
    for (final entry in (requirements['speciesKills'] as Map).entries) {
      if ((speciesKills['${entry.key}'] ?? 0) < readIntValue(entry.value)) {
        return false;
      }
    }
  } else if (species.isNotEmpty &&
      (speciesKills[species] ?? 0) <
          readIntValue(requirements['speciesKills'], fallback: 1)) {
    return false;
  }
  if (readIntValue(requirements['criticals']) > 0 &&
      (skillCriticals[criticalSkill] ?? 0) <
          readIntValue(requirements['criticals'])) {
    return false;
  }
  return requirements['open'] != true || open;
}

String oculumSkillRequirementDescription(Map r) => [
  if (readIntValue(r['level']) > 0) 'Livello ${r['level']}',
  if (readIntValue(r['grade']) > 0) 'Grado ${r['grade']}',
  if ('${r['stat'] ?? ''}'.isNotEmpty) '${r['stat']} ${r['statValue'] ?? 0}',
  if ('${r['subtrait'] ?? ''}'.isNotEmpty)
    '${r['subtrait']} +${r['subtraitValue'] ?? 0}',
  if (readIntValue(r['kills']) > 0 || readIntValue(r['elementKills']) > 0)
    [
      if (readIntValue(r['kills']) > 0) '${r['kills']} mostri sconfitti',
      if (readIntValue(r['elementKills']) > 0)
        '${r['elementKills']} mostri di ${r['element']}',
    ].join(r['killsEither'] == true ? ' oppure ' : ' e '),
  if (readIntValue(r['criticals']) > 0)
    '${r['criticals']} critici riusciti con ${r['criticalSkill']}',
  if (r['speciesKills'] is Map)
    for (final entry in (r['speciesKills'] as Map).entries)
      '${entry.value} ${entry.key} sconfitti validi per la tua Potenza',
  if (r['namedNpcKills'] is Map)
    for (final entry in (r['namedNpcKills'] as Map).entries)
      'Uccidi ${entry.value} ${entry.key == 'erik_i' ? 'Erik I' : entry.key} (identità specifica)',
  if ('${r['species'] ?? ''}'.isNotEmpty && r['speciesKills'] is! Map)
    '${readIntValue(r['speciesKills'], fallback: 1)} ${r['species']} sconfitti validi per la tua Potenza',
  if ('${r['material'] ?? ''}'.isNotEmpty)
    '${switch (r['materialKind']) {
      'collect' => 'Raccogli',
      'consume' => 'Consuma',
      _ => 'Possiedi',
    }} ${r['materialGrams']} g di ${r['material']}',
  if (r['open'] == true) 'Open attiva',
].join(' · ');

/// New catalogue choices receive requirements; existing saved definitions do not.
Map<String, dynamic> oculumProgressionRequirements(
  String id,
  int form,
  int level,
) {
  final slot = int.tryParse(id.split('__').last) ?? 0;
  return {
    'skillId': id,
    'level': level,
    if (slot >= 9) 'open': true,
    if (form > 0) ...{
      'subtrait': slot < 3 || slot == 9
          ? 'forza'
          : slot < 6 || slot == 10
          ? 'riflessi'
          : 'concentrazione',
      'subtraitValue': form * 3,
      'kills': form == 1 ? 8 : 20,
      'elementKills': form == 1 ? 3 : 8,
      'killsEither': true,
    },
  };
}

CharacterSkill oculumCharacterSkillFromArt(ArtSkill skill) => CharacterSkill(
  nome: skill.nome,
  tipo: 'Skill',
  costo: '',
  cooldown: '',
  descrizione: '',
  equipaggiata: true,
  forme: [
    for (var i = 0; i < 3; i++)
      CharacterSkillForm(
        nome: const ['I', 'II', 'III'][i],
        tipo: skill.tipoPerLivello(i + 1).isEmpty
            ? 'Skill'
            : skill.tipoPerLivello(i + 1),
        livello:
            '${readIntValue(RegExp(r'Richiede livello\s+(\d+)').firstMatch(skill.testoEvoluzione(i + 1))?.group(1))}',
        descrizione: skill.testoEvoluzione(i + 1),
        unlockRequirements: skill.unlockRequirementsPerLevel[i],
        costoStrutturato: OculumSkillCost(
          resource: skill.risorsaCostoPerLivello(i + 1),
          amountExpression: '${skill.oculumMinimoPerLivello(i + 1)}',
          minimum: skill.oculumMinimoPerLivello(i + 1),
          maximum: skill.oculumMassimoPerLivello(i + 1),
          variable:
              skill.oculumMinimoPerLivello(i + 1) !=
              skill.oculumMassimoPerLivello(i + 1),
        ),
        effettiStrutturati: skill.effettiPerLivello[i]
            .map((e) => OculumStructuredEffect.fromJson(e.toJson()))
            .toList(),
        cooldownStrutturato: OculumAbilityCooldown.fromJson(
          skill.cooldownPerLivello[i].toJson(),
        ),
      ),
  ],
);

ArtSkill oculumArtSkillFromCharacter(CharacterSkill skill) => ArtSkill(
  nome: skill.nome,
  evo1: skill.forme[0].descrizione,
  evo2: skill.forme[1].descrizione,
  evo3: skill.forme[2].descrizione,
  unlockRequirementsPerLevel: skill.forme
      .map((f) => f.unlockRequirements)
      .toList(),
  effettiPerLivello: skill.forme.map((f) => f.effettiStrutturati),
  cooldownPerLivello: skill.forme.map(
    (f) => f.cooldownStrutturato ?? OculumAbilityCooldown(),
  ),
  oculumMinimiPerLivello: skill.forme
      .map(
        (f) =>
            f.costoStrutturato?.minimum ??
            readIntValue(f.costoStrutturato?.amountExpression),
      )
      .toList(),
  oculumMassimiPerLivello: skill.forme
      .map(
        (f) =>
            f.costoStrutturato?.maximum ??
            readIntValue(f.costoStrutturato?.amountExpression),
      )
      .toList(),
  risorseCostoPerLivello: skill.forme
      .map((f) => f.costoStrutturato?.resource ?? 'nessuna')
      .toList(),
  tipiPerLivello: skill.forme.map((f) => f.tipo).toList(),
);

extension _OculumCreationProgression on _OculumHomePageState {
  String progressionMaterialKey(String value) =>
      oculumNormalizeText(value).trim();

  void recordProgressionMaterialCollection(
    String material,
    int grams,
    String receipt, {
    String name = '',
  }) {
    if (material.trim().isEmpty || grams <= 0 || receipt.isEmpty) return;
    final seen = (planarState['progressionCollectionReceipts'] as List? ?? [])
        .map((e) => '$e')
        .toSet();
    if (!seen.add(receipt)) return;
    final totals = Map<String, dynamic>.from(
      planarState['progressionCollectedMaterials'] as Map? ?? {},
    );
    for (final key in {
      progressionMaterialKey(material),
      if (name.isNotEmpty) progressionMaterialKey(name),
    }) {
      totals[key] = readIntValue(totals[key]) + grams;
    }
    planarState['progressionCollectedMaterials'] = totals;
    planarState['progressionCollectionReceipts'] = seen.toList();
  }

  List<InventoryItem> progressionMaterialStacks(String material) => inventario
      .where(
        (i) =>
            i.quantita > 0 &&
            !i.arma &&
            !i.protegge &&
            i.craftData['titleItem'] != true &&
            (progressionMaterialKey(i.nome) ==
                    progressionMaterialKey(material) ||
                progressionMaterialKey('${i.craftData['material'] ?? ''}') ==
                    progressionMaterialKey(material)),
      )
      .toList();

  int progressionMaterialUnitGrams(InventoryItem item) => max(
    0,
    readIntValue(item.craftData['grams'], fallback: (item.peso * 1000).round()),
  );

  String progressionConsumptionKey(Map r) => jsonEncode([
    '${r['consumptionKey'] ?? ''}',
    progressionMaterialKey('${r['material'] ?? ''}'),
    readIntValue(r['materialGrams']),
  ]);

  bool progressionMaterialRequirementMet(Map r) {
    final material = '${r['material'] ?? ''}';
    final grams = readIntValue(r['materialGrams']);
    if (material.isEmpty || grams <= 0) return true;
    if (r['materialKind'] == 'collect') {
      return readIntValue(
            (planarState['progressionCollectedMaterials']
                as Map?)?[progressionMaterialKey(material)],
          ) >=
          grams;
    }
    if (r['materialKind'] == 'consume') {
      return '${r['consumptionKey'] ?? ''}'.isNotEmpty &&
          (planarState['progressionConsumptionReceipts'] as List? ?? [])
              .contains(progressionConsumptionKey(r));
    }
    return progressionMaterialStacks(material).fold<int>(
          0,
          (n, i) => n + progressionMaterialUnitGrams(i) * i.quantita,
        ) >=
        grams;
  }

  bool consumeProgressionRequirement(Map r) {
    if (r['materialKind'] != 'consume' ||
        '${r['consumptionKey'] ?? ''}'.isEmpty) {
      return false;
    }
    if (progressionMaterialRequirementMet(r)) return true;
    final stacks = progressionMaterialStacks('${r['material'] ?? ''}');
    var remaining = readIntValue(r['materialGrams']);
    if (remaining <= 0 ||
        stacks.fold<int>(
              0,
              (n, i) => n + progressionMaterialUnitGrams(i) * i.quantita,
            ) <
            remaining) {
      return false;
    }
    for (final item in stacks) {
      if (remaining <= 0) break;
      final unit = progressionMaterialUnitGrams(item);
      if (unit <= 0) continue;
      final total = unit * item.quantita;
      final taken = min(total, remaining);
      remaining -= taken;
      final left = total - taken;
      // Material lots are saved by exact mass; split the stack without losing
      // the unconsumed remainder or rounding a gram into another full item.
      item.quantita = left > 0 ? 1 : 0;
      item.peso = left / 1000;
      item.craftData = {...item.craftData, 'grams': left};
      if (item.quantita == 0) inventario.remove(item);
    }
    planarState['progressionConsumptionReceipts'] = [
      ...(planarState['progressionConsumptionReceipts'] as List? ?? []),
      progressionConsumptionKey(r),
    ];
    aggiungiLog(
      '[SBLOCCO] Consumati ${r['materialGrams']} g di ${r['material']}; pagamento registrato una sola volta.',
    );
    programmaSalvataggio();
    return true;
  }

  /// Personal progress is deliberately separate from the public Monster Book.
  /// The Book remembers all party kills, including enemies too weak for this PG.
  void recordPersonalProgressionKills(
    Iterable<Map> enemies,
    String encounter, {
    int? ownerPower,
  }) {
    final power = ownerPower ?? scoutTotalPowerAt(schedaCorrente);
    planarState['progressionKills'] = oculumRecordPersonalProgressionKills(
      planarState['progressionKills'] as Map? ?? {},
      enemies,
      encounter,
      power,
    );
    planarState['progressionNamedNpcKills'] =
        oculumRecordNamedNpcProgressionKills(
          planarState['progressionNamedNpcKills'] as Map? ?? {},
          enemies,
          encounter,
          power,
        );
    refreshAuthoredTitleUnlocks();
  }

  void refreshAuthoredTitleUnlocks() {
    final ledger = planarState['progressionKills'] as Map? ?? {};
    final configured = Map<String, dynamic>.from(
      planarState['authoredTitleRequirements'] as Map? ?? {},
    );
    for (final title in titoli.where(
      (t) =>
          !t.evoluto && t.openEffects.any((e) => e.target == 'senka_moon_open'),
    )) {
      final key = title.chiaveSistema;
      final raw = configured.putIfAbsent(
        key,
        () => <String, dynamic>{
          'speciesAny': ['guardia_solare', 'guardia_solare_elite'],
          'kills': 3,
        },
      );
      if (raw is! Map) {
        continue;
      }
      final requirement = Map<String, dynamic>.from(raw);
      // Authored metadata is explicit. Unknown/empty custom goals never evolve
      // a title merely because an unrelated kill was delivered.
      if (requirement['speciesAny'] is! List &&
          requirement['speciesKills'] is! Map &&
          requirement['namedNpcKills'] is! Map) {
        continue;
      }
      final counts = <String, int>{};
      for (final entry in ledger.entries) {
        final amount = entry.value is Map
            ? max(0, readIntValue(entry.value['count']))
            : 0;
        final family = oculumPartyHuntSpeciesId('${entry.key}');
        counts[family] = (counts[family] ?? 0) + amount;
      }
      final selected = (requirement['speciesAny'] as List? ?? [])
          .map((v) => '$v')
          .toSet();
      final kills = counts.entries
          .where((e) => selected.isEmpty || selected.contains(e.key))
          .fold<int>(0, (n, e) => n + e.value);
      final permanent = permanentProgressionStats();
      if (!oculumSkillRequirementsMet(
        requirement,
        level: leggiNumero(livelloController),
        grade: leggiNumero(gradoController),
        stats: permanent,
        subtraits: permanentProgressionSubtraits(permanent),
        kills: kills,
        elementalKills: {},
        skillCriticals: {},
        speciesKills: counts,
        namedNpcKills: {
          for (final e
              in (planarState['progressionNamedNpcKills'] as Map? ?? {})
                  .entries)
            '${e.key}': e.value is Map ? readIntValue(e.value['count']) : 0,
        },
      )) {
        continue;
      }
      title.evoluto = true;
      aggiungiLog(
        '[SBLOCCO] ${title.nome}: requisito raggiunto, Open e Skill Open disponibili.',
      );
      invalidateDerivedDataCaches();
    }
    planarState['authoredTitleRequirements'] = configured;
  }

  void recordPersonalProgressionCritical(String receipt, String skill) {
    if (receipt.trim().isEmpty || skill.trim().isEmpty) return;
    final seen = (planarState['skillCriticalReceipts'] as List? ?? [])
        .map((e) => '$e')
        .toSet();
    if (!seen.add('$receipt:$skill')) return;
    final progress = Map<String, dynamic>.from(
      planarState['skillCriticalProgress'] as Map? ?? {},
    );
    progress[skill] = readIntValue(progress[skill]) + 1;
    planarState['skillCriticalProgress'] = progress;
    planarState['skillCriticalReceipts'] = seen.toList();
  }

  Map<String, int> permanentProgressionStats() {
    final values = <String, int>{
      'resilienza': max(0, leggiNumero(resilienzaController)),
      'volonta': max(0, leggiNumero(volontaController)),
      'materia': max(0, leggiNumero(materiaController)),
      'oculum': max(0, leggiNumero(oculumController)),
    };
    final context = <String, num>{
      ...values,
      'livello': leggiNumero(livelloController),
      'grado': leggiNumero(gradoController),
    };
    for (final title in titoliCalcolabili.where((t) => t.equipaggiato)) {
      final fields = {
        'resilienza': title.resilienza,
        'volonta': title.volonta,
        'materia': title.materia,
        'oculum': title.oculum,
      };
      for (final key in values.keys) {
        values[key] =
            values[key]! + fields[key]! + titleGradeStatBonus(title, key);
      }
      for (final command in oculumParseFormulaCommands(title.buff, context)) {
        if (command.valid &&
            command.triggerRaw.isEmpty &&
            values.containsKey(command.key)) {
          values[command.key] = values[command.key]! + command.value;
        }
      }
    }
    return values;
  }

  Map<String, int> permanentProgressionSubtraits(Map<String, int> stats) {
    final texts = titoliCalcolabili
        .where((t) => t.equipaggiato)
        .map((t) => t.buff)
        .toList();
    return {
      for (final s in hiddenEyeStats)
        s.id:
            s.valore +
            oculumHiddenEyeDerivedBonusFor(
              level: leggiNumero(livelloController),
              id: s.id,
              resilienza: stats['resilienza']!,
              volonta: stats['volonta']!,
              materia: stats['materia']!,
              oculum: stats['oculum']!,
              karma: leggiNumero(karmaController),
            ) +
            oculumDirectSubtraitQuickBonus(
              subtraitId: s.id,
              subtraitName: s.nome,
              texts: texts,
            ),
    };
  }

  Map<String, dynamic> get creationDraft {
    if (planarState['creationDraft'] is! Map<String, dynamic>) {
      planarState['creationDraft'] = Map<String, dynamic>.from(
        planarState['creationDraft'] as Map? ?? {},
      );
    }
    return planarState['creationDraft'] as Map<String, dynamic>;
  }

  bool progressionRequirementsMet(Map r) {
    refreshAuthoredTitleUnlocks();
    final ledger = planarState['progressionKills'] as Map? ?? {};
    var kills = 0;
    final elemental = <String, int>{};
    final species = <String, int>{};
    for (final entry in ledger.entries) {
      final count = entry.value is Map
          ? max(0, readIntValue(entry.value['count']))
          : 0;
      final monster = monsterBookEntryById('${entry.key}');
      kills += count;
      species['${entry.key}'] = (species['${entry.key}'] ?? 0) + count;
      final family = oculumPartyHuntSpeciesId('${entry.key}');
      if (family != '${entry.key}') {
        species[family] = (species[family] ?? 0) + count;
      }
      if (monster != null) {
        elemental[monster.elementId] =
            (elemental[monster.elementId] ?? 0) + count;
      }
    }
    final progress = planarState['skillCriticalProgress'] as Map? ?? {};
    final stats = permanentProgressionStats();
    final traits = permanentProgressionSubtraits(stats);
    final history = Map<String, dynamic>.from(
      planarState['progressionGrowth'] as Map? ?? {},
    );
    final previousStats = history['stats'] as Map? ?? {};
    final previousTraits = history['subtraits'] as Map? ?? {};
    final reachedStats = {
      for (final e in stats.entries)
        e.key: max(e.value, readIntValue(previousStats[e.key])),
    };
    final reachedTraits = {
      for (final e in traits.entries)
        e.key: max(e.value, readIntValue(previousTraits[e.key])),
    };
    final reachedLevel = max(
      leggiNumero(livelloController),
      readIntValue(history['level']),
    );
    final reachedGrade = max(
      leggiNumero(gradoController),
      readIntValue(history['grade']),
    );
    planarState['progressionGrowth'] = {
      'level': reachedLevel,
      'grade': reachedGrade,
      'stats': reachedStats,
      'subtraits': reachedTraits,
    };
    if (!progressionMaterialRequirementMet(r)) return false;
    return oculumSkillRequirementsMet(
      r,
      level: reachedLevel,
      grade: reachedGrade,
      stats: reachedStats,
      subtraits: reachedTraits,
      kills: kills,
      elementalKills: elemental,
      speciesKills: species,
      namedNpcKills: {
        for (final entry
            in (planarState['progressionNamedNpcKills'] as Map? ?? {}).entries)
          '${entry.key}': entry.value is Map
              ? max(0, readIntValue(entry.value['count']))
              : 0,
      },
      skillCriticals: {
        for (final e in progress.entries) '${e.key}': readIntValue(e.value),
      },
      open:
          arti.any((a) => a.openAttiva) ||
          [...titoli, ...trattiRazziali].any((t) => t.openAttiva) ||
          inventario.any(
            (i) =>
                i.quantita > 0 &&
                i.equipaggiata &&
                canEquipInventoryItem(i) &&
                i.craftData['titleOpenUsedSinceLongRest'] == true,
          ),
    );
  }

  List<CharacterSkill> tutorialSkillPool() {
    final monster = tutorialGeneraMostro && tutorialMonsterPresetId.isNotEmpty
        ? monsterBookEntryById(
            tutorialMonsterVariantId.isNotEmpty
                ? tutorialMonsterVariantId
                : tutorialMonsterPresetId,
          )
        : null;
    if (tutorialGeneraMostro) {
      if (monster == null) return [];
      final art = oculumMonsterBookArt(monster);
      final ids = monsterBookUsableSkillIds(monster);
      return [
        for (final (i, skill) in art.skills.indexed)
          _naturalMonsterSkill(monster, ids[i], skill),
      ];
    }
    final art = oculumStarterArtChoices().firstWhere(
      (a) => a.nome == tutorialArtName,
      orElse: oculumStarterWaterArt,
    );
    final element = '${creationDraft['element'] ?? 'acqua'}';
    final species = MonsterBookEntry(
      id: 'starter_$element',
      nameIt: 'Cammino di $element',
      nameEn: 'Path of $element',
      descIt:
          'Un personaggio che disciplina il proprio corpo e la propria affinità con $element.',
      descEn: '',
      elementId: element,
      spriteAssetPath: '',
      isMiniBoss: false,
      isBoss: false,
      isNullFateless: false,
      stats: {if (art.tipo != 'Martial Art') 'oculum': 1, 'materia': 1},
    );
    // Register an isolated starter pool without inserting a creature in the Book.
    final expanded = oculumRegisterProgressionPool(species);
    return [
      ...art.skills.map(oculumCharacterSkillFromArt),
      for (final id in expanded.skillIds)
        _naturalMonsterSkill(
          expanded,
          id,
          oculumProgressionArtSkill(expanded, id),
        ),
    ];
  }

  Set<String> get tutorialChosenSkills =>
      (creationDraft['skills'] as List? ?? []).map((e) => '$e').toSet();
  void setTutorialChosenSkills(Iterable<String> names) {
    creationDraft['skills'] = names.toSet().toList();
  }

  void generateTutorialDraft() {
    final random = Random.secure();
    if (!tutorialGeneraMostro) {
      final races = oculumStarterRaces.where((r) => !r.conMaster).toList();
      tutorialRaceId = races[random.nextInt(races.length)].id;
      const elements = [
        'acqua',
        'fuoco',
        'terra',
        'vento',
        'ghiaccio',
        'fulmine',
        'luce',
        'buio',
        'natura',
        'luna',
        'spirituale',
      ];
      creationDraft['element'] = elements[random.nextInt(elements.length)];
      tutorialArtName = tutorialElementArt('${creationDraft['element']}').nome;
      final backgrounds = oculumStarterBackgrounds
          .where((b) => !b.conMaster)
          .toList();
      tutorialBackgroundId = backgrounds[random.nextInt(backgrounds.length)].id;
      creationDraft['name'] = [
        'Neris',
        'Vel',
        'Iria',
        'Corven',
        'Mirai',
        'Aster',
      ][random.nextInt(6)];
    } else if (tutorialMonsterPresetId.isEmpty) {
      final monsters = monsterBookEntries
          .where(
            (m) =>
                m.presetType == tutorialMonsterTier &&
                !_isTutorialMonsterVariant(m),
          )
          .toList();
      if (monsters.isNotEmpty) {
        tutorialMonsterPresetId = monsters[random.nextInt(monsters.length)].id;
      }
      tutorialMonsterVariantId = tutorialMonsterPresetId;
    }
    final traits =
        hiddenEyeStats
            .where(
              (s) => const [
                'forza',
                'riflessi',
                'percezione',
                'concentrazione',
                'crafting',
                'alchimia',
              ].contains(s.id),
            )
            .toList()
          ..shuffle(random);
    tutorialSubtraitPoints.clear();
    for (final s in traits.take(3)) {
      tutorialSubtraitPoints[s.id] = 3;
    }
    if (tutorialSubtraitPoints.length < 3) {
      for (final s in hiddenEyeStats) {
        if (tutorialSubtraitPoints.length == 3) break;
        tutorialSubtraitPoints[s.id] = 3;
      }
    }
    final pool = tutorialSkillPool();
    final available = pool
        .where(
          (s) =>
              readIntValue(s.forme.first.livello) <=
                  leggiNumero(tutorialLevelController) &&
              s.forme.first.unlockRequirements['open'] != true,
        )
        .toList();
    final ranked = available
      ..sort((a, b) {
        int score(CharacterSkill s) => s.forme.first.effettiStrutturati.fold(
          0,
          (n, e) => n + (tutorialSubtraitPoints[e.target] ?? 0),
        );
        return score(b).compareTo(score(a));
      });
    setTutorialChosenSkills(ranked.take(3).map((s) => s.nome));
    creationDraft['guided'] = true;
  }

  CharacterArt tutorialElementArt(String element) => element == 'acqua'
      ? oculumStarterWaterArt()
      : element == 'roccia'
      ? oculumStarterRockArt()
      : oculumStarterElementArt(element);

  Widget tutorialIdentityPage(StateSetter update) {
    final monster = tutorialGeneraMostro
        ? monsterBookEntryById(
            tutorialMonsterVariantId.isNotEmpty
                ? tutorialMonsterVariantId
                : tutorialMonsterPresetId,
          )
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (monster != null) ...[
          Text(
            monster.nameIt,
            style: TextStyle(
              fontSize: 20,
              color: tertiaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Atteggiamento naturale',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(oculumMonsterNaturalAttitude(monster)),
          const Text(
            "ma esistono sempre l'eccezioni",
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),
          if (monster.id == 'scostubanditi')
            Transform.rotate(
              angle: -.045,
              child: const Text(
                'Oh merda, devo muovere il culo!',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFE3BD7B),
                  letterSpacing: .6,
                ),
              ),
            ),
        ],
        tutorialStartingWeapons(update),
        for (final field in const [
          ('name', 'Nome'),
          ('age', 'Età'),
          ('pronouns', 'Pronomi'),
          ('appearance', 'Aspetto personale'),
          ('personality', 'Carattere e atteggiamento scelti'),
          ('ideal', 'Ideale'),
          ('bond', 'Legame'),
          ('flaw', 'Difetto'),
          ('goal', 'Obiettivo'),
          ('voice', 'Voce e modi'),
          ('origin', 'Luogo d’origine'),
          ('story', 'Storia personale'),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextFormField(
              key: ValueKey('creation_${field.$1}'),
              initialValue:
                  '${creationDraft[field.$1] ?? (field.$1 == 'name' ? monster?.nameIt ?? nomeController.text : '')}',
              decoration: InputDecoration(labelText: field.$2),
              maxLines: field.$1 == 'story' || field.$1 == 'appearance' ? 3 : 1,
              onChanged: (v) => update(() => creationDraft[field.$1] = v),
            ),
          ),
      ],
    );
  }

  Widget tutorialSkillsPage(StateSetter update) {
    final pool = tutorialSkillPool();
    final selected = tutorialChosenSkills;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!tutorialGeneraMostro)
          DropdownButtonFormField<String>(
            key: ValueKey('creation_element_${creationDraft['element']}'),
            isExpanded: true,
            initialValue: '${creationDraft['element'] ?? 'acqua'}',
            decoration: const InputDecoration(
              labelText: 'Elemento del tuo cammino',
            ),
            items: [
              for (final e in const [
                'acqua',
                'fuoco',
                'terra',
                'roccia',
                'vento',
                'ghiaccio',
                'fulmine',
                'luce',
                'buio',
                'natura',
                'luna',
                'spirituale',
              ])
                DropdownMenuItem(value: e, child: Text(elementDisplayName(e))),
            ],
            onChanged: (v) => update(() {
              creationDraft['element'] = v ?? 'acqua';
              tutorialArtName = tutorialElementArt(v ?? 'acqua').nome;
              setTutorialChosenSkills([]);
            }),
          ),
        const SizedBox(height: 12),
        Text(
          'Scegli 3 Skill iniziali · ${selected.length}/3',
          style: TextStyle(color: tertiaryColor, fontWeight: FontWeight.bold),
        ),
        Text(
          tutorialGeneraMostro
              ? 'Solo tecniche della creatura scelta. Le altre restano nel suo pool di apprendimento.'
              : 'Le tue tre scelte diventano le Skill dell’Art. Le altre restano nel pool di apprendimento.',
        ),
        for (final skill in pool)
          Builder(
            builder: (_) {
              final form = skill.forme.first;
              final level = readIntValue(form.livello);
              final locked =
                  level > leggiNumero(tutorialLevelController) ||
                  form.unlockRequirements['open'] == true;
              final effects = form.effettiStrutturati;
              final roles = oculumCombatAbilityRoles(effects);
              return ExpansionTile(
                title: Row(
                  children: [
                    Checkbox(
                      value: selected.contains(skill.nome),
                      onChanged:
                          locked ||
                              !selected.contains(skill.nome) &&
                                  selected.length >= 3
                          ? null
                          : (v) => update(() {
                              final names = tutorialChosenSkills;
                              v == true
                                  ? names.add(skill.nome)
                                  : names.remove(skill.nome);
                              setTutorialChosenSkills(names);
                            }),
                    ),
                    Expanded(child: Text(skill.nome)),
                  ],
                ),
                subtitle: Text(
                  '${locked ? 'Da sbloccare · ' : ''}Livello $level · ${form.costo} · ${roles.map((r) => r.name).join(' / ')}',
                ),
                children: [
                  for (final (i, f) in skill.forme.indexed)
                    ListTile(
                      title: Text('Forma ${i + 1} · Livello ${f.livello}'),
                      subtitle: Text(
                        '${f.descrizione}\n${oculumSkillRequirementDescription(f.unlockRequirements)}',
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  static const tutorialPageNames = [
    'Cammino',
    'Identità',
    'Statistiche',
    'Sottotratti',
    'Origine',
    'Skill',
    'Riepilogo',
  ];

  int tutorialCompletionPercent() {
    final visited = (creationDraft['visited'] as List? ?? [])
        .map(readIntValue)
        .toSet();
    final tests = [
      visited.contains(0) &&
          (!tutorialGeneraMostro || tutorialMonsterPresetId.isNotEmpty),
      visited.contains(1) &&
          '${creationDraft['name'] ?? nomeController.text}'.trim().isNotEmpty,
      visited.contains(2),
      oculumStarterSubtraitAllocationValid(
        tutorialSubtraitPoints,
        hiddenEyeStats.map((s) => s.id),
      ),
      visited.contains(4),
      tutorialChosenSkills.length == 3,
      visited.contains(6),
    ];
    return (tests.where((v) => v).length * 100 ~/ tests.length);
  }

  Widget tutorialWizardHeader(StateSetter update) {
    final step = readIntValue(creationDraft['step']).clamp(0, 6);
    final percent = tutorialCompletionPercent();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$percent% completato · ${tutorialPageNames[step]}',
          key: const ValueKey('creation_completion'),
          style: TextStyle(color: tertiaryColor, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percent / 100,
          color: tertiaryColor,
          backgroundColor: primaryColor.withValues(alpha: .12),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final (i, name) in tutorialPageNames.indexed)
              ChoiceChip(
                label: Text('${i + 1}. $name'),
                selected: step == i,
                onSelected: (_) => update(() => tutorialGoToPage(i)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.auto_awesome_outlined),
          label: const Text('Genera un personaggio per me'),
          onPressed: () => update(() {
            generateTutorialDraft();
            tutorialGoToPage(1);
          }),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void tutorialGoToPage(int page) {
    final visited = (creationDraft['visited'] as List? ?? [])
        .map(readIntValue)
        .toSet();
    visited.add(readIntValue(creationDraft['step']));
    visited.add(page);
    creationDraft['visited'] = visited.toList();
    if (tutorialGeneraMostro &&
        tutorialMonsterPresetId.isNotEmpty &&
        tutorialMonsterVariantId.isEmpty &&
        page > 0) {
      tutorialMonsterVariantId =
          _resolveTutorialMonsterPreset()?.id ?? tutorialMonsterPresetId;
    }
    creationDraft['step'] = page.clamp(0, 6);
  }

  Widget tutorialWizardNavigation(StateSetter update, BuildContext dialog) {
    final step = readIntValue(creationDraft['step']);
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        if (step > 0)
          OutlinedButton.icon(
            onPressed: () => update(() => tutorialGoToPage(step - 1)),
            icon: const Icon(Icons.chevron_left),
            label: const Text('Indietro'),
          ),
        if (step < 6)
          FilledButton.icon(
            onPressed: () => update(() => tutorialGoToPage(step + 1)),
            icon: const Icon(Icons.chevron_right),
            label: const Text('Avanti'),
          )
        else
          FilledButton.icon(
            onPressed: () {
              if (applicaSettaggioTutorial()) {
                Navigator.pop(dialog);
              } else {
                ScaffoldMessenger.of(
                  dialog,
                ).showSnackBar(SnackBar(content: Text(risultato)));
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Crea il personaggio'),
          ),
      ],
    );
  }

  Widget tutorialReviewPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '${creationDraft['name'] ?? nomeController.text}',
        style: TextStyle(color: tertiaryColor, fontSize: 22),
      ),
      Text(
        tutorialGeneraMostro
            ? monsterBookEntryById(tutorialMonsterVariantId)?.nameIt ?? 'Mostro'
            : sceltaTutorial(oculumStarterRaces, tutorialRaceId).nome,
      ),
      Text(
        'Livello ${tutorialLevelController.text} · ${tutorialGeneraMostro ? 'Grado dal livello della creatura' : tutorialArtName}',
      ),
      Text('Skill scelte: ${tutorialChosenSkills.join(' · ')}'),
      for (final pair in const [
        ('personality', 'Carattere'),
        ('appearance', 'Aspetto'),
        ('ideal', 'Ideale'),
        ('bond', 'Legame'),
        ('flaw', 'Difetto'),
        ('goal', 'Obiettivo'),
      ])
        if ('${creationDraft[pair.$1] ?? ''}'.trim().isNotEmpty)
          Text('${pair.$2}: ${creationDraft[pair.$1]}'),
      const SizedBox(height: 12),
      const Text(
        'Nomi, descrizioni, requisiti, costi, effetti, forme e cooldown resteranno modificabili nella scheda.',
      ),
    ],
  );

  Widget tutorialStartingWeapons(StateSetter update) {
    final chosen = (creationDraft['weapons'] as List? ?? [])
        .map((e) => '$e')
        .toSet();
    return ExpansionTile(
      title: const Text('Armi iniziali · una o due armi'),
      subtitle: Text(
        chosen.isEmpty ? 'Nessuna arma scelta' : chosen.join(' + '),
      ),
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final name in const [
              'Spada',
              'Alabarda',
              'Boomerang',
              'Chakram',
              'Coltellino',
              'Falce',
              'Lancia',
              'Ascia',
              'Mazza',
              'Arco',
              'Bastone',
              'Pugnale',
            ])
              FilterChip(
                label: Text(name),
                selected: chosen.contains(name),
                onSelected: !chosen.contains(name) && chosen.length >= 2
                    ? null
                    : (v) => update(() {
                        v ? chosen.add(name) : chosen.remove(name);
                        creationDraft['weapons'] = chosen.toList();
                      }),
              ),
          ],
        ),
        const Text(
          'Puoi equipaggiare entrambe le armi. Le risorse di turno restano quelle della tua scheda; nomi, peso, danno, elemento e abilità sono modificabili nell’inventario.',
        ),
      ],
    );
  }

  void applyTutorialStartingWeapons() {
    final names = (creationDraft['weapons'] as List? ?? [])
        .map((e) => '$e')
        .toSet()
        .take(2);
    for (final name in names) {
      if (inventario.any((i) => i.craftData['creationStarterWeapon'] == name)) {
        continue;
      }
      inventario.add(
        InventoryItem(
          nome: name,
          peso:
              const {
                'Alabarda': 3.0,
                'Falce': 2.5,
                'Coltellino': .2,
                'Chakram': .6,
                'Boomerang': .5,
              }[name] ??
              1.5,
          quantita: 1,
          arma: true,
          equipaggiata: true,
          bonusDanno: 2,
          note:
              'Arma iniziale di Grado 0. Tutti i valori sono modificabili. Doppia arma consentita; nessuna Azione aggiuntiva automatica.',
          craftData: {'creationStarterWeapon': name},
        ),
      );
    }
  }

  Widget creationSkillLearningPanel() {
    final raw = planarState['creationSkillPool'];
    if (raw is! List || raw.isEmpty) return const SizedBox.shrink();
    final ownMonster = '${planarState['creationMonsterId'] ?? ''}';
    if (ownMonster.isNotEmpty && ownMonster != faunaCurrentMonsterId) {
      return const SizedBox.shrink();
    }
    final known = {
      for (final s in skills) s.nome,
      for (final a in arti) ...a.skills.map((s) => s.nome),
    };
    final pool = raw
        .whereType<Map>()
        .map((j) => CharacterSkill.fromJson(Map<String, dynamic>.from(j)))
        .where((s) => !known.contains(s.nome))
        .toList();
    if (pool.isEmpty) return const SizedBox.shrink();
    return ExpansionTile(
      title: const Text('Pool di apprendimento del personaggio'),
      subtitle: Text(
        '$ownMonster${ownMonster.isEmpty ? 'Cammino scelto' : ' · solo tecniche della tua creatura'} · ${pool.length} Skill',
      ),
      children: [
        for (final s in pool)
          Builder(
            builder: (_) {
              final first = s.forme.first;
              final requirements = {
                ...first.unlockRequirements,
                'level': max(
                  1,
                  max(
                    readIntValue(first.livello),
                    readIntValue(first.unlockRequirements['level']),
                  ),
                ),
                'kills': max(
                  2,
                  readIntValue(first.unlockRequirements['kills']),
                ),
              };
              final canLearn = progressionRequirementsMet(requirements);
              return ListTile(
                title: Text(s.nome),
                subtitle: Text(oculumSkillRequirementDescription(requirements)),
                trailing: IconButton(
                  tooltip: 'Apprendi Skill',
                  icon: const Icon(Icons.school_outlined),
                  onPressed: !canLearn
                      ? null
                      : () {
                          if (!progressionRequirementsMet(requirements) ||
                              skills.any((k) => k.nome == s.nome)) {
                            return;
                          }
                          setState(
                            () =>
                                skills.add(CharacterSkill.fromJson(s.toJson())),
                          );
                          programmaSalvataggio();
                        },
                ),
              );
            },
          ),
      ],
    );
  }

  Widget progressionRequirementsEditor(
    Map<String, dynamic> r, {
    required String storageId,
  }) => ExpansionTile(
    key: ValueKey('requirements_$storageId'),
    title: const Text('Requisiti di sblocco'),
    subtitle: Text(
      oculumSkillRequirementDescription(r).isEmpty
          ? 'Nessun requisito aggiuntivo'
          : oculumSkillRequirementDescription(r),
    ),
    children: [
      for (final pair in const [
        ('level', 'Livello minimo'),
        ('grade', 'Grado minimo'),
        ('statValue', 'Valore minimo della statistica permanente'),
        ('subtraitValue', 'Valore minimo del sottotratto'),
        ('kills', 'Mostri da sconfiggere'),
        ('elementKills', 'Mostri dell’elemento da sconfiggere'),
        ('criticals', 'Critici riusciti richiesti'),
        ('speciesKills', 'Uccisioni valide della specie'),
      ])
        campoModello(
          label: pair.$2,
          initialValue: '${readIntValue(r[pair.$1])}',
          keyboardType: TextInputType.number,
          onChanged: (v) {
            r[pair.$1] = max(0, readIntValue(v));
            programmaSalvataggio();
          },
        ),
      DropdownButtonFormField<String>(
        initialValue:
            const [
              'resilienza',
              'volonta',
              'materia',
              'oculum',
            ].contains(r['stat'])
            ? '${r['stat']}'
            : '',
        decoration: const InputDecoration(
          labelText: 'Statistica permanente richiesta',
        ),
        items: [
          const DropdownMenuItem(value: '', child: Text('Nessuna')),
          for (final key in const [
            'resilienza',
            'volonta',
            'materia',
            'oculum',
          ])
            DropdownMenuItem(value: key, child: Text(key)),
        ],
        onChanged: (v) {
          r['stat'] = v ?? '';
          programmaSalvataggio();
        },
      ),
      campoModello(
        label: 'Specie richiesta (ID Monster Book)',
        initialValue: '${r['species'] ?? ''}',
        onChanged: (v) {
          r['species'] = v.trim();
          programmaSalvataggio();
        },
      ),
      DropdownButtonFormField<String>(
        initialValue:
            const ['collect', 'possess', 'consume'].contains(r['materialKind'])
            ? '${r['materialKind']}'
            : 'possess',
        decoration: const InputDecoration(labelText: 'Requisito del materiale'),
        items: const [
          DropdownMenuItem(
            value: 'collect',
            child: Text('Raccogli: progresso storico'),
          ),
          DropdownMenuItem(
            value: 'possess',
            child: Text('Possiedi: inventario attuale'),
          ),
          DropdownMenuItem(
            value: 'consume',
            child: Text('Consuma: pagamento unico'),
          ),
        ],
        onChanged: (v) {
          r['materialKind'] = v;
          r['consumptionKey'] = storageId;
          programmaSalvataggio();
        },
      ),
      campoModello(
        label: 'Materiale richiesto: nome esatto o ID',
        initialValue: '${r['material'] ?? ''}',
        onChanged: (v) {
          r['material'] = v.trim();
          r['consumptionKey'] = storageId;
          programmaSalvataggio();
        },
      ),
      campoModello(
        label: 'Quantità richiesta (grammi)',
        initialValue: '${readIntValue(r['materialGrams'])}',
        keyboardType: TextInputType.number,
        onChanged: (v) {
          r['materialGrams'] = max(0, readIntValue(v));
          r['consumptionKey'] = storageId;
          programmaSalvataggio();
        },
      ),
      if (r['materialKind'] == 'consume')
        TextButton(
          onPressed: () => setState(() {
            r['consumptionKey'] = storageId;
            consumeProgressionRequirement(r);
          }),
          child: Text(
            progressionMaterialRequirementMet(r)
                ? 'Materiale già consumato per questo requisito'
                : 'Consuma il materiale richiesto per sbloccare',
          ),
        ),
      DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: hiddenEyeStats.any((s) => s.id == r['subtrait'])
            ? '${r['subtrait']}'
            : '',
        decoration: const InputDecoration(labelText: 'Sottotratto richiesto'),
        items: [
          const DropdownMenuItem(value: '', child: Text('Nessuno')),
          for (final s in hiddenEyeStats)
            DropdownMenuItem(value: s.id, child: Text(s.nome)),
        ],
        onChanged: (v) {
          r['subtrait'] = v ?? '';
          programmaSalvataggio();
        },
      ),
      campoModello(
        label: 'Elemento delle uccisioni (es. fuoco)',
        initialValue: '${r['element'] ?? ''}',
        onChanged: (v) {
          r['element'] = v.trim().toLowerCase();
          programmaSalvataggio();
        },
      ),
      campoModello(
        label: 'Skill con cui ottenere i critici (nome o ID)',
        initialValue: '${r['criticalSkill'] ?? ''}',
        onChanged: (v) {
          r['criticalSkill'] = v.trim();
          programmaSalvataggio();
        },
      ),
      SwitchListTile(
        title: const Text('Uccisioni generiche OPPURE dell’elemento'),
        value: r['killsEither'] == true,
        onChanged: (v) {
          setState(() => r['killsEither'] = v);
          programmaSalvataggio();
        },
      ),
      SwitchListTile(
        title: const Text('Richiede Open attiva'),
        value: r['open'] == true,
        onChanged: (v) {
          setState(() => r['open'] = v);
          programmaSalvataggio();
        },
      ),
    ],
  );
}
