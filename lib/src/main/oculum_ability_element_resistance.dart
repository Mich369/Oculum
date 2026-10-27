part of '../../main.dart';

/// Additive percentage points, capped only by the new rule. Existing immunity
/// or stronger protection is preserved, and healing is never converted to harm.
int oculumAbilityResistanceDamage({
  required int unmodifiedDamage,
  required int modifiedDamage,
  required int bonusPercent,
}) {
  if (unmodifiedDamage <= 0 || modifiedDamage <= 0 || bonusPercent <= 0) {
    return modifiedDamage;
  }
  final cap = max(1, (unmodifiedDamage * .10).ceil());
  if (modifiedDamage <= cap) return modifiedDamage;
  return max(cap,
    (modifiedDamage - unmodifiedDamage * min(90, bonusPercent) / 100).round());
}

extension _OculumAbilityElementResistance on _OculumHomePageState {
  Set<String> abilityDeclaredElements(
    Iterable<OculumStructuredEffect> effects,
    Iterable<String> texts,
  ) {
    final elements = <String>{};
    void add(String raw) {
      if (raw.trim().isEmpty) return;
      final id = oculumNormalizeElementId(raw);
      if (id != 'sconosciuto' && id != 'tutti' && id != 'tuttiidanni') {
        elements.add(id);
      }
    }
    for (final effect in effects) {
      if (effect.enabled) add(effect.elementType);
    }
    for (final text in texts) {
      // Read mechanics, never a narrative mention of an enemy or a weakness.
      for (final command in parseQuickCommandsDetailed(text)) {
        if (command.valid && const {'danni', 'difesa', 'scudo', 'scudo_oculum'}.contains(command.key)) {
          add(command.elementId);
        }
      }
      for (final match in RegExp(r'^(?:Elemento|Affinità)\s*:\s*([^\n.;]+)',
          multiLine: true, caseSensitive: false).allMatches(text)) {
        for (final raw in match.group(1)!.split(RegExp(r'[,/+]'))) { add(raw); }
      }
    }
    return elements;
  }

  List<({String source, Set<String> elements})> abilityElementResistanceSources() {
    final rows = <({String source, Set<String> elements})>[];
    void add(String source, Set<String> elements) {
      if (elements.isNotEmpty) rows.add((source: source, elements: elements));
    }
    Set<String> characterSkillElements(CharacterSkill skill) {
      final forms = skill.forme.where((form) =>
        leggiNumero(livelloController) >= readIntValue(form.livello) &&
        progressionRequirementsMet(form.unlockRequirements));
      return abilityDeclaredElements(
        forms.expand((f) => f.effettiStrutturati),
        forms.expand((f) => [f.buff, f.danni, f.difesa, f.descrizione]),
      );
    }
    for (final skill in skills) {
      if (skill.equipaggiata) add('Skill · ${skill.nome}', characterSkillElements(skill));
    }
    for (final art in arti) {
      if (!art.sbloccata || !art.inUso) continue;
      final artElements = abilityDeclaredElements(
        const [], [art.descrizione, if (art.openAttiva) art.openBuff]);
      for (final skill in art.skills) {
        final unlocked = [for (var i = 0; i < 3; i++)
          if (progressionRequirementsMet(skill.unlockRequirementsPerLevel[i]) &&
              leggiNumero(livelloController) >= readIntValue(RegExp(
                r'Richiede livello\s+(\d+)', caseSensitive: false,
              ).firstMatch(skill.testoEvoluzione(i + 1))?.group(1))) i];
        final elements = abilityDeclaredElements(
          unlocked.expand((i) => skill.effettiEvoluzione(i + 1)),
          unlocked.map((i) => skill.testoEvoluzione(i + 1)),
        );
        add('Skill · ${art.nome} / ${skill.nome}', elements);
        artElements.addAll(elements);
      }
      add('Art · ${art.nome}', artElements);
    }
    for (final title in [...titoli, ...trattiRazziali]) {
      if (!title.equipaggiato) continue;
      add('Titolo · ${title.nome}', abilityDeclaredElements(
        title.skillEffects, [title.buff, title.skill],
      ));
    }
    for (final item in inventario) {
      if (!item.equipaggiata || item.quantita <= 0 || !canEquipInventoryItem(item) ||
          item.craftData['titleItem'] != true) {
        continue;
      }
      add('Titolo Item · ${item.nome}', {oculumNormalizeElementId(item.elementoDanno)});
      // A normal item's skills are excluded along with the normal item.
      if (item.ability != null) add('Skill · ${item.nome}', characterSkillElements(item.ability!));
      if (oculumItemTitleEvolutionReady(item)) {
        for (final skill in [if (item.titleAbility != null) item.titleAbility!, ...item.titleExtraAbilities]) {
          add('Skill · ${item.nome} / ${skill.nome}', characterSkillElements(skill));
        }
      }
    }
    return rows;
  }

  int abilityElementResistancePercent(String element) {
    final id = oculumNormalizeElementId(element);
    return min(90, 3 * abilityElementResistanceSources().where((r) => r.elements.contains(id)).length);
  }
}
