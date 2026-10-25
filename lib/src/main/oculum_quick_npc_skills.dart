part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

List<MonsterBookEntry>? _npcCatalogueSource;
final _npcElementChoices = <String, List<OculumCatalogueEntry>>{};

List<OculumCatalogueEntry> oculumQuickNpcSkillChoices(String element) {
  final normalized = oculumNormalizeElementId(element);
  if (!identical(_npcCatalogueSource, monsterBookEntries)) {
    _npcCatalogueSource = monsterBookEntries;
    _npcElementChoices.clear();
  }
  if (_npcElementChoices.containsKey(normalized)) {
    return _npcElementChoices[normalized]!;
  }
  final known = <String>{};
  final entries = oculumAbilityCatalogueEntries(elementFilter: normalized)
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
  return _npcElementChoices[normalized] = List.unmodifiable(entries);
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
                choices: oculumQuickNpcSkillChoices(quickNpcSkillElement),
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
