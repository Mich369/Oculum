part of '../../main.dart';

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
}) {
  var text = monster.descIt.split('\n\nSkill per il giocatore:').first.trim();
  if (!weakPointKnown) {
    text = text.replaceAll(
      RegExp(r'Punto debole\s*:[^\n.!?]*(?:[.!?]|$)', caseSensitive: false),
      '',
    );
  }
  return text.trim();
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
  }) {
    final text = oculumMonsterOverview(monster, weakPointKnown: weakPointKnown);
    final pieces = text.split(RegExp(r'(?<=[.!?])\s+(?=[A-ZÀ-Ü])'));
    final appearance = pieces.isEmpty ? text : pieces.first;
    final behaviour = pieces.skip(1).join(' ').trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        monsterReadingHeading('Aspetto', Icons.visibility_outlined),
        SelectableText(oculumMonsterReadableProse(appearance)),
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

  Widget monsterReadingAbilities(MonsterBookEntry monster) {
    final art = oculumMonsterBookArt(monster);
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
        if (art.openName.trim().isNotEmpty) ...[
          monsterReadingHeading('Open · ${art.openName}', Icons.flare_outlined),
          if (art.openDescription.trim().isNotEmpty)
            SelectableText(oculumMonsterReadableProse(art.openDescription)),
          monsterReadingOpenPart(
            'Buff Open',
            art.openBuff,
            art.openBuffEffects,
            art.openBuffCooldown,
          ),
          monsterReadingOpenPart(
            'Skill Open',
            art.openSkill,
            art.openSkillEffects,
            art.openSkillCooldown,
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
                      '${oculumMonsterDropName(id)}${monster.dropChances.containsKey(id) ? ' · ${monster.dropChances[id]}%' : ''}',
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 5),
          smallInfoText(
            'La prova Drop, le scroll e i premi speciali seguono le condizioni della creatura. Questi materiali non sono assegnati automaticamente solo consultando la pagina.',
          ),
        ],
      ],
    );
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
