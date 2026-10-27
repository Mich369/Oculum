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
}) {
  if (level < readIntValue(requirements['level'])) return false;
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
  if (readIntValue(requirements['criticals']) > 0 &&
      (skillCriticals[criticalSkill] ?? 0) <
          readIntValue(requirements['criticals'])) {
    return false;
  }
  return requirements['open'] != true || open;
}

String oculumSkillRequirementDescription(Map r) => [
  if (readIntValue(r['level']) > 0) 'Livello ${r['level']}',
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
  Map<String, dynamic> get creationDraft {
    if (planarState['creationDraft'] is! Map<String, dynamic>) {
      planarState['creationDraft'] = Map<String, dynamic>.from(
        planarState['creationDraft'] as Map? ?? {},
      );
    }
    return planarState['creationDraft'] as Map<String, dynamic>;
  }

  bool progressionRequirementsMet(Map r) {
    final ledger = partyChest['monsterKillCounts'] as Map? ?? {};
    var kills = 0;
    final elemental = <String, int>{};
    for (final entry in ledger.entries) {
      final count = entry.value is Map ? readIntValue(entry.value['count']) : 0;
      final monster = monsterBookEntryById('${entry.key}');
      kills += count;
      if (monster != null) {
        elemental[monster.elementId] =
            (elemental[monster.elementId] ?? 0) + count;
      }
    }
    final progress = planarState['skillCriticalProgress'] as Map? ?? {};
    return oculumSkillRequirementsMet(
      r,
      level: leggiNumero(livelloController),
      subtraits: {for (final s in hiddenEyeStats) s.id: hiddenEyeTotal(s)},
      kills: kills,
      elementalKills: elemental,
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
        ('subtraitValue', 'Valore minimo del sottotratto'),
        ('kills', 'Mostri da sconfiggere'),
        ('elementKills', 'Mostri dell’elemento da sconfiggere'),
        ('criticals', 'Critici riusciti richiesti'),
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
