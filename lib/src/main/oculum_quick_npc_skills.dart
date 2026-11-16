part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

List<MonsterBookEntry>? _npcCatalogueSource;
final _npcElementChoices = <(String, bool), List<OculumCatalogueEntry>>{};

String oculumMasterSkillChoiceLabel(OculumCatalogueEntry entry) {
  final fantasy = oculumMonsterSkillDisplayName(entry.art.nome);
  return fantasy == null || fantasy == entry.art.nome
      ? entry.label
      : '$fantasy · ${entry.label}';
}

List<OculumCatalogueEntry> oculumRankMasterSkillChoices(
  Iterable<OculumCatalogueEntry> choices,
  String value, {
  Set<String> preferredElements = const {},
}) {
  final query = oculumNormalizeText(value);
  if (query.isEmpty) return choices.toList(growable: false);
  final nameQuery = OculumNameQuery(query);
  final maxDistance = query.length < 7 ? 1 : 2;

  bool matchesPreferredElement(OculumCatalogueEntry entry) {
    final natural = entry.natural;
    final elements =
        <String>{
              '${natural?.scrollData['element'] ?? ''}',
              for (final level in entry.art.effettiPerLivello)
                for (final effect in level)
                  if (effect.enabled) effect.elementType,
              for (final form in natural?.forme ?? const <CharacterSkillForm>[])
                for (final effect in form.effettiStrutturati)
                  if (effect.enabled) effect.elementType,
            }
            .map(oculumNormalizeElementId)
            .where(
              (element) =>
                  element.isNotEmpty &&
                  !const {
                    'sconosciuto',
                    'tutti',
                    'tuttiidanni',
                  }.contains(element),
            );
    if (elements.isNotEmpty) return elements.any(preferredElements.contains);
    final monster = monsterBookEntryById(entry.id.split(':').first);
    return monster != null &&
        preferredElements.contains(oculumNormalizeElementId(monster.elementId));
  }

  (int, bool, int) score(OculumCatalogueEntry entry) {
    if (oculumNormalizeText(entry.id) == query ||
        oculumNormalizeText(entry.natural?.id ?? '') == query) {
      return (1000, true, 0);
    }
    final skillNames = {
      entry.art.nome,
      if (entry.natural != null) entry.natural!.nome,
      ...oculumMonsterSkillSearchAliases(entry.art.nome),
    }.map(oculumNormalizeText).where((name) => name.isNotEmpty).toSet();
    final nameMatch = skillNames.fold(
      0,
      (best, name) => max(best, nameQuery.score(name)),
    );
    if (nameMatch == 1000) return (nameMatch, true, 0);

    final monster = monsterBookEntryById(entry.id.split(':').first);
    final sources = {
      entry.label,
      if (monster != null) ...oculumMonsterNameSearchAliases(monster),
    }.map(oculumNormalizeText);
    final sourceMatch = sources.fold(
      0,
      (best, name) => max(best, oculumNameMatchScore(query, name)),
    );
    final literalMatch = max(nameMatch, sourceMatch);
    if (literalMatch > 0) {
      return (literalMatch, literalMatch == nameMatch, 0);
    }

    if (query.length < 4) return (0, false, 0);
    var fuzzyMatch = 0;
    for (final name in skillNames) {
      if ((query.length - name.length).abs() <= maxDistance) {
        final distance = oculumLevenshtein(query, name);
        if (distance <= maxDistance) {
          fuzzyMatch = max(fuzzyMatch, maxDistance + 1 - distance);
        }
      }
    }
    return (0, false, fuzzyMatch);
  }

  final ranked =
      <
        ({
          OculumCatalogueEntry entry,
          int literalMatch,
          bool matchesSkillName,
          int fuzzyMatch,
          int index,
        })
      >[];
  for (final (index, entry) in choices.indexed) {
    final (literalMatch, matchesSkillName, fuzzyMatch) = score(entry);
    if (literalMatch > 0 || fuzzyMatch > 0) {
      ranked.add((
        entry: entry,
        literalMatch: nameQuery.rank(
          literalMatch,
          preferredElement:
              preferredElements.isNotEmpty &&
              literalMatch >= 520 &&
              matchesPreferredElement(entry),
        ),
        matchesSkillName: matchesSkillName,
        fuzzyMatch: fuzzyMatch,
        index: index,
      ));
    }
  }
  ranked.sort((a, b) {
    final byLiteral = b.literalMatch.compareTo(a.literalMatch);
    if (byLiteral != 0) return byLiteral;
    if (a.matchesSkillName != b.matchesSkillName) {
      return a.matchesSkillName ? -1 : 1;
    }
    final byFuzzy = b.fuzzyMatch.compareTo(a.fuzzyMatch);
    return byFuzzy != 0 ? byFuzzy : a.index.compareTo(b.index);
  });
  return ranked.map((match) => match.entry).toList(growable: false);
}

List<OculumCatalogueEntry> oculumQuickNpcSkillChoices(
  String element, {
  bool includeAdditionalMonsterArts = false,
}) {
  final normalized = oculumNormalizeElementId(element);
  if (!identical(_npcCatalogueSource, monsterBookEntries)) {
    _npcCatalogueSource = monsterBookEntries;
    _npcElementChoices.clear();
  }
  final cacheKey = (normalized, includeAdditionalMonsterArts);
  final cached = _npcElementChoices[cacheKey];
  if (cached != null) return cached;
  final known = <String>{};
  final entries =
      oculumAbilityCatalogueEntries(
            elementFilter: normalized,
            includeAdditionalMonsterArts: includeAdditionalMonsterArts,
          )
          .where(
            (e) =>
                oculumCatalogueElement(e) == normalized &&
                !e.art.tipoPerLivello(1).toLowerCase().contains('passiv') &&
                known.add(oculumNormalizeText(e.art.nome)),
          )
          .toList();
  for (final role in OculumCombatAbilityRole.values) {
    final physical = normalized == 'fisico';
    final name = physical
        ? (role == OculumCombatAbilityRole.attack
              ? 'Colpo di pressione'
              : role == OculumCombatAbilityRole.defense
              ? 'Guardia ferma'
              : 'Aiuto coordinato')
        : '${role == OculumCombatAbilityRole.attack
              ? 'Colpo'
              : role == OculumCombatAbilityRole.defense
              ? 'Riparo'
              : 'Sostegno'} di ${normalized.replaceAll('_', ' ')}';
    final skill = ArtSkill(
      nome: name,
      evo1:
          'I/Richiede livello 0. ${role == OculumCombatAbilityRole.attack
              ? 'Un impulso elementale accompagna il colpo.'
              : role == OculumCombatAbilityRole.defense
              ? 'Una barriera elementale protegge il corpo.'
              : 'L’elemento guida la prossima azione di un alleato.'}',
      evo2: 'II/Richiede livello 3. La tecnica diventa più efficace.',
      evo3:
          'III/Richiede livello 6. La tecnica raggiunge la sua forma completa.',
      risorseCostoPerLivello: List.filled(
        5,
        physical
            ? (role == OculumCombatAbilityRole.defense ? 'materia' : 'volonta')
            : 'oculum',
      ),
      oculumMinimiPerLivello: [1, 2, 3, 0, 0],
      oculumMassimiPerLivello: [1, 2, 3, 0, 0],
      effettiPerLivello: [
        for (var form = 0; form < 3; form++)
          [
            OculumStructuredEffect(
              id: 'npc_${normalized}_${role.name}_$form',
              type: role == OculumCombatAbilityRole.attack
                  ? 'danno'
                  : role == OculumCombatAbilityRole.defense
                  ? 'difesa'
                  : 'bonus_tiro',
              target: role == OculumCombatAbilityRole.attack
                  ? 'danni'
                  : role == OculumCombatAbilityRole.defense
                  ? 'difesa'
                  : 'tiri',
              valueExpression:
                  '${role == OculumCombatAbilityRole.support ? form + (physical ? 3 : 2) : (physical ? 4 : 3) * (form + 1)}',
              elementType: normalized,
              recipient: role == OculumCombatAbilityRole.attack
                  ? 'nemico'
                  : role == OculumCombatAbilityRole.support
                  ? 'alleato'
                  : 'se_stesso',
              mode: 'prossima_azione',
            ),
          ],
      ],
      cooldownPerLivello: [
        for (var i = 0; i < 3; i++)
          OculumAbilityCooldown(
            amount: role == OculumCombatAbilityRole.attack ? 2 : 3,
          ),
      ],
    );
    if (known.add(oculumNormalizeText(name))) {
      entries.add((
        id: 'npc:$normalized:${role.name}',
        label: name,
        art: skill,
        natural: null,
      ));
    }
  }
  entries.sort(
    (a, b) => oculumCatalogueRequiredLevel(
      a,
    ).compareTo(oculumCatalogueRequiredLevel(b)),
  );
  return _npcElementChoices[cacheKey] = List.unmodifiable(entries);
}

Map<OculumCombatAbilityRole, CharacterSkill> oculumQuickNpcDefaults(
  String element,
  int level,
) {
  final options = oculumQuickNpcSkillChoices(element);
  final selected = <OculumCombatAbilityRole, CharacterSkill>{};
  final used = <String>{};
  for (final role in OculumCombatAbilityRole.values) {
    final entry = options
        .where(
          (e) =>
              oculumCatalogueRequiredLevel(e) <= level &&
              !used.contains(oculumNormalizeText(e.art.nome)) &&
              oculumCombatAbilityRoles(
                e.art.effettiEvoluzione(1),
              ).contains(role),
        )
        .firstOrNull;
    if (entry == null) continue;
    used.add(oculumNormalizeText(entry.art.nome));
    selected[role] = entry.natural == null
        ? oculumEquipmentAbilityFromArt(entry.art)
        : CharacterSkill.fromJson(entry.natural!.toJson());
  }
  return selected;
}

extension _OculumQuickNpcSkills on _OculumHomePageState {
  void ensureQuickNpcSkills() {
    final element = oculumNormalizeElementId(
      quickSheetElementController.text.trim().isEmpty
          ? 'fisico'
          : quickSheetElementController.text,
    );
    if (quickNpcSkillElement == element && quickNpcSkills.length == 3) return;
    quickNpcSkillElement = element;
    quickNpcSkills = oculumQuickNpcDefaults(
      element,
      max(0, int.tryParse(quickSheetLevelController.text) ?? 0),
    );
  }

  Widget quickNpcSkillPanel() {
    ensureQuickNpcSkills();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: quickNpcSkillElement,
          isExpanded: true,
          decoration: fieldDecoration('Elemento delle skill NPC'),
          items: [
            for (final id in {...oculumDefaultElementIds, quickNpcSkillElement})
              DropdownMenuItem(value: id, child: Text(elementDisplayName(id))),
          ],
          onChanged: (id) {
            if (id == null) return;
            setState(() {
              quickSheetElementController.text = id;
              quickNpcSkillElement = '';
              ensureQuickNpcSkills();
            });
          },
        ),
        const SizedBox(height: 8),
        for (final entry in quickNpcSkills.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: OutlinedButton.icon(
              onPressed: () => showAbilityCatalogue(
                masterAssignment: true,
                choices: oculumQuickNpcSkillChoices(
                  quickNpcSkillElement,
                  includeAdditionalMonsterArts: true,
                ),
                initialRole: entry.key,
                initialElement: quickNpcSkillElement,
                catalogueLevel:
                    int.tryParse(quickSheetLevelController.text) ?? 0,
                excludedNames: {
                  for (final other in quickNpcSkills.entries)
                    if (other.key != entry.key)
                      oculumNormalizeText(other.value.nome),
                },
                onPicked: (skill) {
                  if (!mounted) return;
                  setState(() => quickNpcSkills[entry.key] = skill);
                },
              ),
              icon: Icon(
                entry.key == OculumCombatAbilityRole.attack
                    ? Icons.flash_on
                    : entry.key == OculumCombatAbilityRole.defense
                    ? Icons.shield_outlined
                    : Icons.volunteer_activism_outlined,
              ),
              label: Text(
                '${entry.key == OculumCombatAbilityRole.attack
                    ? 'Attacco'
                    : entry.key == OculumCombatAbilityRole.defense
                    ? 'Difesa'
                    : 'Supporto'} · ${entry.value.nome}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        const Text(
          'Tre skill distinte, modificabili nel catalogo. Le forme rispettano il livello dell’NPC.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
