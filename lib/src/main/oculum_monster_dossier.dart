part of '../../main.dart';

int oculumMonsterBookPower(MonsterBookEntry entry) => oculumScoutPower(
  entry.stats['level'] ?? 0,
  [
    for (final key in const ['resilienza', 'volonta', 'materia', 'oculum'])
      entry.stats[key] ?? 0,
  ],
  grade: entry.stats['grade'] ?? oculumGradeForLevel(entry.stats['level'] ?? 0),
);

int oculumCompareMonsterBookPower(MonsterBookEntry a, MonsterBookEntry b) {
  for (final difference in [
    oculumMonsterBookPower(a).compareTo(oculumMonsterBookPower(b)),
    (a.stats['level'] ?? 0).compareTo(b.stats['level'] ?? 0),
    (a.stats['grade'] ?? oculumGradeForLevel(a.stats['level'] ?? 0)).compareTo(
      b.stats['grade'] ?? oculumGradeForLevel(b.stats['level'] ?? 0),
    ),
    a.nameIt.toLowerCase().compareTo(b.nameIt.toLowerCase()),
    a.id.compareTo(b.id),
  ]) {
    if (difference != 0) return difference;
  }
  return 0;
}

/// Presentation only: authored prose, formula values and saved JSON stay intact.
String oculumMonsterReadableProse(String raw) => raw
    .replaceAll('oculum_spent', 'Oculum investito')
    .replaceAll('stats_skill_spent', 'statistiche investite')
    .replaceAll('hp_current', 'Vita attuale')
    .replaceAll('hp_max', 'Vita massima')
    .replaceAll('monster_open_bonus', 'Potenziamento della Skill Open')
    .replaceAll('runic_reflection_percent', 'Percentuale di danni riflessi')
    .replaceAllMapped(
      RegExp(r'@\s*(res|vol|mat|ocu|danni|difesa)\b', caseSensitive: false),
      (m) => const {
        'res': 'Resilienza',
        'vol': 'Volontà',
        'mat': 'Materia',
        'ocu': 'Oculum',
        'danni': 'Danni',
        'difesa': 'Difesa',
      }[m[1]!.toLowerCase()]!,
    )
    .replaceAll(RegExp(r'^\s*(?:III|II|I)/\s*', multiLine: true), '')
    .replaceAll(
      RegExp(r'\(0/0\s+nessun costo,\s*costo fisso\)', caseSensitive: false),
      '(nessun costo statistico)',
    )
    .trim();

String oculumMonsterOverview(
  MonsterBookEntry monster, {
  bool weakPointKnown = true,
  Set<String>? knownDropIds,
}) {
  var text = monster.descIt.split('\n\nSkill per il giocatore:').first.trim();
  if (!weakPointKnown) {
    text = text.replaceAll(
      RegExp(r'Punto debole\s*:[^\n.!?]*(?:[.!?]|$)', caseSensitive: false),
      '',
    );
  }
  if (knownDropIds != null) {
    text = text.replaceAll(
      RegExp(
        r'\b(?:Drop|Bottino)[^\n.!?]{0,32}\s*:[^\n.!?]*(?:[.!?]|$)',
        caseSensitive: false,
      ),
      '',
    );
    for (final id in monster.dropIds) {
      if (knownDropIds.contains(id)) continue;
      final name = oculumMonsterDropName(id);
      if (name.isNotEmpty) {
        text = text.replaceAll(
          RegExp('\\b${RegExp.escape(name)}\\b', caseSensitive: false),
          '???',
        );
      }
    }
  }
  return text.trim();
}

String oculumMonsterBookDropLabel(
  MonsterBookEntry monster,
  String dropId, {
  Set<String>? knownDropIds,
  int? dropBonus,
}) {
  if (knownDropIds != null && !knownDropIds.contains(dropId)) return '???';
  final odds = _monsterBookDropOdds(monster, dropId, dropBonus: dropBonus);
  return '${oculumMonsterDropName(dropId)} · $odds';
}

/// Drop modifier read from the roller's saved sheet.
int oculumEncounterDropBonus(Map sheet, {bool includeSavedDifficulty = true}) {
  final stats = sheet['hiddenEyeStats'];
  final drop = stats is List
      ? stats.whereType<Map>().where((stat) => stat['id'] == 'drop').firstOrNull
      : null;
  return readIntValue(drop?['valore']) +
      oculumHiddenEyeDerivedBonusFor(
        id: 'drop',
        level: readIntValue(sheet['livello']),
        resilienza: readIntValue(sheet['resilienza']),
        volonta: readIntValue(sheet['volonta']),
        materia: readIntValue(sheet['materia']),
        oculum: readIntValue(sheet['oculum']),
        karma: readIntValue(sheet['karma']),
      ) -
      (includeSavedDifficulty ? readIntValue(sheet['difficoltaTiro']) : 0);
}

// The generic percentage is conditional on the Drop check. Authored reward
// routes that return before that check must not inherit the catalogue default.
String _monsterBookDropOdds(
  MonsterBookEntry monster,
  String dropId, {
  int? dropBonus,
}) {
  const special = 'Regola Drop speciale';
  const guaranteed = 'Garantito';
  String afterDifficulty(int percent, {int minimumTotal = 0, String? rule}) {
    final conditional = percent.clamp(0, 100).toInt();
    final bonus = dropBonus;
    if (bonus == null) return rule ?? '$conditional% a DT Drop raggiunta';
    final level = monster.stats['level'] ?? 0;
    final grade = monster.stats['grade'] ?? oculumGradeForLevel(level);
    final threshold = max(
      minimumTotal,
      oculumMonsterDropDifficulty(level: level, grade: grade),
    );
    final eligible = (21 - max(1, threshold - bonus)).clamp(0, 20);
    if (conditional == 0) return 'Impossibile (0%)';
    if (eligible == 0) return 'Impossibile senza critico (0%)';
    final chance = eligible * conditional / 20;
    final formatted = chance
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'\.?0+$'), '')
        .replaceAll('.', ',');
    return '≈$formatted%';
  }

  String naturalAtLeast(int minimum) =>
      minimum == 1 ? guaranteed : '${(21 - minimum) * 5}% ($minimum+ naturale)';

  final id = monster.id;
  final species = oculumPartyHuntSpeciesId(id);
  if (id == 'funghetto_cappuccio_rosso') {
    return dropId == id ? '95% (1–19 naturale)' : special;
  }
  if (id == 'pupazzo_robotico_postea') {
    return dropId == 'scarti_robotici_pupazzo' ? guaranteed : special;
  }
  if (id == 'fata_cacciatrice') {
    return dropId == 'mezza_ala_fata'
        ? afterDifficulty(
            100,
            minimumTotal: 50,
            rule: 'Garantito con totale Drop ≥50 e DT raggiunta',
          )
        : special;
  }
  if (id == 'costrutto_rinsecchito') {
    return switch (dropId) {
      'nucleo_rotto_debole' || 'rami_rinsecchiti' => afterDifficulty(
        100,
        rule: 'Garantito a DT Drop raggiunta',
      ),
      'cuore_rami_rinsecchiti' => afterDifficulty(
        monster.dropChances[dropId] ?? 3,
      ),
      _ => special,
    };
  }
  if (id == 'larva_bianca') return special;
  if (id == 'slime_roccioso' || id.startsWith('slime_roccioso_variante_')) {
    return dropId == 'roccia_slime' ? guaranteed : special;
  }
  if (id.startsWith('mammuth_in_decomposizione')) {
    return dropId == 'ossa_mammuth_putrido' ? afterDifficulty(35) : special;
  }

  if (const {
    'fuocherelli',
    'feralis',
    'granscostumato',
    'sempre_verde',
    'lavastrello',
    'teschio_monaco',
    'teschio_quattro_lame',
    'ogor',
    'teirak',
    'teschio_mostruoso',
    'adoratore_bestia',
    'laer',
    'torretta_oculum',
    'manichino_spada',
    'deadly_sins',
    'zombie_acido',
    'cavaliere_non_ritorno',
  }.contains(id)) {
    final material = monster.dropChances.keys.firstOrNull ?? 'frammento_$id';
    return dropId == material ? naturalAtLeast(8) : special;
  }
  const planarMaterials = {
    'bramble': 'fibra_rovo_bramble',
    'thunderbird': 'piuma_conduttrice_thunderbird',
    'scostubanditi': 'ottone_fucile_scostubanditi',
    'observers_tear': 'scheggia_occhio_viola',
    'obser_sunshine': 'frammento_occhio_solare',
    'saltalungo_maculato': 'tendine_elastico_maculato',
    'famelico_oblio': 'zanna_ricordo_vuoto',
    'nuvi': 'piuma_nuvi',
    'coniglio_prestigiatore': 'fodera_cappello_incantato',
    'coniglio_plasma': 'bobina_plasma_coniglio',
    'pupazzo_artigliato': 'molla_pupazzo',
    'medusa_vetro': 'filamento_medusa_vetro',
    'nocciolo_corazzato': 'guscio_nocciolo',
  };
  final planarMaterial = planarMaterials[id];
  if (planarMaterial != null) {
    return dropId == planarMaterial ? naturalAtLeast(8) : special;
  }
  if (species == 'sharp') {
    return switch (dropId) {
      'scarti_metallici' => naturalAtLeast(8),
      'dente_sharp' => naturalAtLeast(12),
      _ => special,
    };
  }
  if (species == 'lupo_delle_nevi') {
    final material = switch (id) {
      'lupo_delle_nevi' => 'zanna_brinata',
      'lupo_infernale_del_ghiaccio' => 'scheggia_brace_lupo',
      'lupo_ombra_oblio' => 'filo_ululante_oblio',
      'lupo_runico_postea' => 'dente_circuito_lupo',
      _ => 'artigli_lupo',
    };
    return dropId == material ? naturalAtLeast(8) : special;
  }
  if (species == 'topino_avventuroso') {
    return switch (dropId) {
      'fiaccola' => guaranteed,
      'scroll_coltello_avvelenato' => naturalAtLeast(20),
      _ => special,
    };
  }
  if (species == 'mosca_campana') return special;
  return afterDifficulty(monster.dropChances[dropId] ?? 35);
}

String oculumMonsterReadingCost(ArtSkill skill, int form) {
  final resource = skill.risorsaCostoPerLivello(form);
  final low = skill.oculumMinimoPerLivello(form);
  final high = skill.oculumMassimoPerLivello(form);
  final costs = <String>[
    if (resource != 'nessuna' && high > 0)
      '${low == high ? '$low' : '$low–$high'} ${oculumArtSkillCostResourceLabel(resource)}',
    for (final extra in skill.additionalCostsPerLevel[form - 1])
      '${extra.variable ? '${extra.minimum}–${extra.maximum}' : extra.amountExpression} ${oculumArtSkillCostResourceLabel(extra.resource)}',
  ];
  return costs.isEmpty
      ? 'Nessun costo statistico'
      : oculumMonsterReadableProse(costs.join(' + '));
}

extension _OculumMonsterDossier on _OculumHomePageState {
  Widget monsterReadingHeading(String title, IconData icon) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 7),
    child: Row(
      children: [
        Icon(icon, size: 17, color: tertiaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(color: tertiaryColor, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );

  Widget monsterReadingOverview(
    MonsterBookEntry monster, {
    bool weakPointKnown = true,
    Set<String>? knownDropIds,
  }) {
    final text = oculumMonsterOverview(
      monster,
      weakPointKnown: weakPointKnown,
      knownDropIds: knownDropIds,
    );
    final pieces = text.split(RegExp(r'(?<=[.!?])\s+(?=[A-ZÀ-Ü])'));
    final appearance = pieces.isEmpty ? text : pieces.first;
    final behaviour = pieces.skip(1).join(' ').trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        monsterReadingHeading('Aspetto', Icons.visibility_outlined),
        SelectableText(oculumMonsterReadableProse(appearance)),
        monsterReadingHeading(
          'Atteggiamento naturale',
          Icons.psychology_outlined,
        ),
        SelectableText(
          '${oculumMonsterNaturalAttitude(monster)}\nma esistono sempre l’eccezioni',
        ),
        if (behaviour.isNotEmpty) ...[
          monsterReadingHeading(
            'Comportamento e particolarità',
            Icons.pets_outlined,
          ),
          SelectableText(oculumMonsterReadableProse(behaviour)),
        ],
        if (monster.planeIds.isNotEmpty) ...[
          monsterReadingHeading('Habitat', Icons.landscape_outlined),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final id in monster.planeIds)
                Chip(
                  label: Text(
                    oculumMonsterHabitats[id] ?? systemMonsterReadableId(id),
                  ),
                ),
            ],
          ),
        ],
        if (oculumMonsterCyclePhaseName(monster).isNotEmpty) ...[
          monsterReadingHeading(
            'Fase del ciclo',
            Icons.calendar_month_outlined,
          ),
          Text(oculumMonsterCyclePhaseName(monster)),
        ],
      ],
    );
  }

  Widget monsterReadingAbilities(
    MonsterBookEntry monster, {
    Set<String>? knownDropIds,
  }) {
    final art = oculumMonsterBookArt(monster);
    final dropBonus =
        monster.dropIds.any(
          (id) => knownDropIds == null || knownDropIds.contains(id),
        )
        ? _monsterBookActiveDropBonus()
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          monsterKillCountLabel(monster.id),
          style: TextStyle(color: tertiaryColor),
        ),
        monsterReadingHeading('Abilità', Icons.auto_awesome_outlined),
        for (final indexed in art.skills.indexed)
          monsterReadingSkill(monster, indexed.$2, indexed.$1),
        for (final open in oculumMonsterBookOpenPool(
          monster,
          primary: art,
        )) ...[
          monsterReadingHeading(
            'Open · ${open.openName}',
            Icons.flare_outlined,
          ),
          if (open.openDescription.trim().isNotEmpty)
            SelectableText(oculumMonsterReadableProse(open.openDescription)),
          monsterReadingOpenPart(
            'Buff Open',
            open.openBuff,
            open.openBuffEffects,
            open.openBuffCooldown,
          ),
          monsterReadingOpenPart(
            'Skill Open',
            open.openSkill,
            open.openSkillEffects,
            open.openSkillCooldown,
          ),
        ],
        monsterReadingHeading('Drop e ricompense', Icons.inventory_2_outlined),
        if (monster.dropIds.isEmpty)
          const Text('Nessun materiale specifico registrato.')
        else ...[
          for (final id in monster.dropIds)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.diamond_outlined, size: 16, color: tertiaryColor),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      oculumMonsterBookDropLabel(
                        monster,
                        id,
                        knownDropIds: knownDropIds,
                        dropBonus: dropBonus,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 5),
          smallInfoText(
            'La stima usa il dado naturale da 1 a 20, il tuo bonus Drop e il Livello e Grado della voce di catalogo. Un critico può raggiungere soglie più alte. I premi legati al naturale seguono la propria regola.',
          ),
        ],
      ],
    );
  }

  int _monsterBookActiveDropBonus() {
    final drop = hiddenEyeStats.where((stat) => stat.id == 'drop').firstOrNull;
    return oculumEncounterDropBonus({
      'hiddenEyeStats': [
        if (drop != null) {'id': 'drop', 'valore': drop.valore},
      ],
      'livello': livelloController.text,
      'resilienza': resilienzaController.text,
      'volonta': volontaController.text,
      'materia': materiaController.text,
      'oculum': oculumController.text,
      'karma': karmaController.text,
      'difficoltaTiro': difficoltaTiroController.text,
    });
  }

  Widget monsterReadingOpenPart(
    String title,
    String prose,
    List<OculumStructuredEffect> effects,
    OculumAbilityCooldown? cooldown,
  ) {
    final lines = effects
        .where((e) => e.enabled)
        .map(oculumStructuredEffectDescription)
        .map(oculumMonsterReadableProse)
        .where((line) => line.isNotEmpty && !prose.contains(line))
        .toSet();
    if (prose.trim().isEmpty && lines.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                color: tertiaryColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (cooldown != null && cooldown.amount > 0)
              smallInfoText('Cooldown: ${cooldown.amount} ${cooldown.unit}'),
            if (prose.trim().isNotEmpty)
              SelectableText(oculumMonsterReadableProse(prose)),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text('• $line'),
              ),
          ],
        ),
      ),
    );
  }

  Widget monsterReadingSkill(
    MonsterBookEntry monster,
    ArtSkill skill,
    int index,
  ) {
    final effects = skill.effettiEvoluzione(1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: abilityColorFrame(
        cost: oculumMonsterReadingCost(skill, 1),
        effects: effects,
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          key: ValueKey('monster-reading-${monster.id}-$index'),
          title: Text(
            skill.nome,
            style: TextStyle(
              color: abilityBenefitColor(effects),
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(oculumMonsterReadingCost(skill, 1)),
          children: [
            for (var form = 1; form <= 3; form++)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                child: monsterReadingForm(monster, skill, index, form),
              ),
          ],
        ),
      ),
    );
  }

  Widget monsterReadingForm(
    MonsterBookEntry monster,
    ArtSkill skill,
    int index,
    int form,
  ) {
    final text = skill.testoEvoluzione(form);
    final effects = skill
        .effettiEvoluzione(form)
        .where((e) => e.enabled)
        .toList();
    final level =
        RegExp(
          r'Richiede livello\s+(\d+)',
          caseSensitive: false,
        ).firstMatch(text)?[1] ??
        '${monsterBookSkillRequiredLevel(monster, index) + (form - 1) * 3}';
    final cd = skill.cooldownPerLivello[form - 1];
    final passive = skill.tipoPerLivello(form).toLowerCase().contains('passiv');
    final free = effects.any(
      (e) =>
          e.type == 'planar' &&
          const {'speed_increase', 'mask_serious_punch'}.contains(e.target),
    );
    final targets = effects
        .where((e) => e.maximumTargets > 0)
        .map((e) => e.maximumTargets)
        .fold<int>(0, max);
    final prose = oculumMonsterReadableProse(text);
    final lines = effects
        .map(oculumStructuredEffectDescription)
        .map(oculumMonsterReadableProse)
        .where((line) => line.isNotEmpty && !prose.contains(line))
        .toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        Text(
          'Forma ${artLevelRoman(form)}',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            Chip(label: Text('Livello $level')),
            Chip(
              label: Text('Costo: ${oculumMonsterReadingCost(skill, form)}'),
            ),
            Chip(
              label: Text(
                cd.amount > 0
                    ? 'CD ${cd.amount} ${cd.unit}'
                    : 'Nessun cooldown',
              ),
            ),
            if (targets > 0)
              Chip(
                label: Text(
                  targets >= 999
                      ? 'Bersagli: tutti quelli ammessi'
                      : 'Bersagli: fino a $targets',
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Text(
            passive
                ? 'Passiva · sempre attiva quando equipaggiata'
                : free
                ? 'Attivazione libera · nessuna Azione o Reazione'
                : 'Attiva · rispetta le risorse di turno e la preparazione descritta',
          ),
        ),
        SelectableText(prose),
        if (lines.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Effetti applicati',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('• $line'),
            ),
        ],
      ],
    );
  }

  Widget monsterReadingDossier(MonsterBookEntry monster) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      monsterReadingOverview(monster),
      monsterReadingHeading('Statistiche base', Icons.bar_chart),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final entry in monster.stats.entries)
            Chip(
              label: Text(
                '${systemMonsterReadableId(entry.key)}: ${entry.value}',
              ),
            ),
        ],
      ),
      monsterReadingHeading('Punto debole', Icons.gps_fixed),
      SelectableText(monster.weakPointDescriptionIt),
      monsterReadingHeading(
        'Resistenze e vulnerabilità',
        Icons.shield_outlined,
      ),
      Text(
        monster.incomingDamageResistancePresets.isEmpty
            ? 'Nessuna resistenza anatomica particolare.'
            : monster.incomingDamageResistancePresets.entries
                  .map((e) => '${elementDisplayName(e.key)}: ${e.value}')
                  .join('\n'),
      ),
      monsterReadingAbilities(monster),
    ],
  );
}
