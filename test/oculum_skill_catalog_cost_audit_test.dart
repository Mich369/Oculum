import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

Map<String, dynamic> auditCost(OculumSkillCost cost) {
  final resource = oculumNormalizeArtSkillCostResource(cost.resource);
  final expression = cost.amountExpression.trim();
  final fixedAmount = int.tryParse(expression);
  return {
    'resource': resource,
    if (cost.variable) ...{
      'minimum': cost.minimum,
      'maximum': cost.maximum,
    } else if (fixedAmount != null)
      'amount': fixedAmount
    else
      'expression': expression,
    if (cost.perTurn) 'perTurn': true,
  };
}

List<Map<String, dynamic>> auditCosts(OculumSkillCost? cost) => [
  if (cost != null)
    for (final component in [cost, ...cost.additionalCosts])
      if (oculumNormalizeArtSkillCostResource(component.resource) != 'nessuna')
        auditCost(component),
];

List<Map<String, dynamic>> auditEffects(
  Iterable<OculumStructuredEffect> effects,
) => [
  for (final effect in effects.where((effect) => effect.enabled))
    effect.toJson()
      ..remove('id')
      ..remove('narrativeText')
      ..remove('customDisplayText'),
];

Map<String, dynamic> auditCharacterForm(CharacterSkillForm form) => {
  'name': form.nome,
  'type': form.tipo,
  'level': form.livello,
  'requirements': form.unlockRequirements,
  'costText': form.costo,
  'costs': auditCosts(oculumCharacterSkillFormCost(form)),
  'cooldownText': form.cooldown,
  'cooldown': form.cooldownStrutturato?.toJson(),
  'effects': auditEffects(form.effettiStrutturati),
};

Map<String, dynamic> auditArtForm(ArtSkill skill, int form) => {
  'form': form,
  'type': skill.tipoPerLivello(form),
  'requirements': skill.unlockRequirementsPerLevel[form - 1],
  'costs': auditCosts(
    OculumSkillCost(
      resource: skill.risorsaCostoPerLivello(form),
      amountExpression: '${skill.oculumMinimoPerLivello(form)}',
      minimum: skill.oculumMinimoPerLivello(form),
      maximum: skill.oculumMassimoPerLivello(form),
      variable:
          skill.oculumMinimoPerLivello(form) !=
          skill.oculumMassimoPerLivello(form),
      additionalCosts: skill.additionalCostsPerLevel[form - 1],
    ),
  ),
  'cooldown': skill.cooldownPerLivello[form - 1].toJson(),
  'effects': auditEffects(skill.effettiEvoluzione(form)),
  'text': skill.testoEvoluzione(form),
};

void main() {
  test(
    'every monster keeps its cost across Book, Art, natural skills and equipment',
    () {
      final problems = <String>[];
      final rows = <Map<String, dynamic>>[];
      var forms = 0;
      var checkedClawForms = 0;
      for (final monster in defaultMonsterBookEntries) {
        final art = oculumMonsterBookArt(monster);
        final natural = oculumMonsterBookSkills(monster);
        final ids = monsterBookUsableSkillIds(monster);
        for (
          var index = 0;
          index < ids.length && index < art.skills.length;
          index++
        ) {
          final skill = art.skills[index];
          final naturalSkill = natural
              .where((candidate) => candidate.nome == skill.nome)
              .firstOrNull;
          final transferred = oculumEquipmentAbilityFromArt(skill);
          for (var form = 0; form < 3; form++) {
            final artResource = oculumNormalizeArtSkillCostResource(
              skill.risorsaCostoPerLivello(form + 1),
            );
            final naturalCost = naturalSkill?.forme[form].costoStrutturato;
            final equipmentCost = transferred.forme[form].costoStrutturato;
            final key = '${monster.id}/${ids[index]}/${form + 1}';
            if (equipmentCost == null ||
                naturalSkill != null && naturalCost == null) {
              problems.add('$key: missing structured cost');
              continue;
            }
            final naturalResource = oculumNormalizeArtSkillCostResource(
              naturalCost?.resource ?? artResource,
            );
            if (naturalResource != artResource) {
              problems.add('$key: natural=$naturalResource Art=$artResource');
            }
            if (skill.oculumMinimoPerLivello(form + 1) !=
                    equipmentCost.minimum ||
                skill.oculumMassimoPerLivello(form + 1) !=
                    equipmentCost.maximum ||
                naturalCost != null &&
                    (naturalCost.minimum != equipmentCost.minimum ||
                        naturalCost.maximum != equipmentCost.maximum) ||
                naturalResource !=
                    oculumNormalizeArtSkillCostResource(
                      equipmentCost.resource,
                    )) {
              problems.add('$key: equipment differs from natural skill');
            }
            rows.add({
              'monster': monster.id,
              'skill': ids[index],
              'form': form + 1,
              'resource': artResource,
              'minimum': equipmentCost.minimum,
              'maximum': equipmentCost.maximum,
              'naturalMinimum': naturalCost?.minimum,
              'naturalMaximum': naturalCost?.maximum,
              'naturalResource': naturalResource,
              'costs': auditCosts(equipmentCost),
              'cooldown': skill.cooldownPerLivello[form].toJson(),
              'passive':
                  oculumMonsterBookSkillIsPassive(ids[index]) ||
                  skill
                      .tipoPerLivello(form + 1)
                      .toLowerCase()
                      .contains('passiv'),
              'effects': auditEffects(skill.effettiEvoluzione(form + 1)),
            });
            if (monster.id == 'teschio_mostruoso' &&
                ids[index] == 'bone_monster_claws') {
              checkedClawForms++;
              expect(artResource, 'materia', reason: key);
              expect(equipmentCost.minimum, form + 1, reason: key);
              expect(equipmentCost.maximum, form + 1, reason: key);
            }
            forms++;
          }
        }
      }
      Directory('build').createSync(recursive: true);
      File('build/monster-catalog-cost-audit.json').writeAsStringSync(
        jsonEncode({
          'monsters': defaultMonsterBookEntries.length,
          'forms': forms,
          'mismatches': problems,
          'rows': rows,
        }),
      );
      expect(problems, isEmpty, reason: problems.take(25).join('\n'));
      expect(forms, greaterThan(defaultMonsterBookEntries.length));
      expect(checkedClawForms, 3);
    },
  );

  test('export built-in player, equipment and scroll form costs', () {
    final skills = <Map<String, dynamic>>[
      for (final art in oculumStarterArtChoices())
        for (final skill in art.skills)
          {
            'source': 'starter_art',
            'art': art.nome,
            'skill': skill.nome,
            'forms': [
              for (var form = 1; form <= 5; form++)
                if (skill.testoEvoluzione(form).trim().isNotEmpty &&
                    skill.testoEvoluzione(form) != '???')
                  auditArtForm(skill, form),
            ],
          },
      for (final (source, skill) in [
        ('learned_scroll', oculumOculumTheftSkill()),
        for (final entry in oculumStatThresholdSkills.entries)
          for (var option = 0; option < entry.value.length; option++)
            ('threshold', oculumCreateThresholdSkill(entry.key, option)),
        ('equipment', oculumPosteaBootsAbility()),
        ('equipment', oculumPosteaMitraAbility(5)),
        ('equipment', oculumForestDemonArmorAbility(0)),
        for (final name in [
          'Corno Forest Demon',
          'Arco',
          'Corazza',
          'Spada di ghiaccio',
          'Spada',
        ])
          ('equipment', oculumEquipmentAbility(name, 0)),
      ])
        {
          'source': source,
          'skill': skill.nome,
          'forms': skill.forme.map(auditCharacterForm).toList(),
        },
    ];
    Directory('build').createSync(recursive: true);
    File('build/player-catalog-cost-audit.json').writeAsStringSync(
      jsonEncode({
        'skills': skills,
        'techniqueScrollProfiles': oculumTechniqueScrolls.length,
        'techniqueScrollGradeCosts': [
          for (var grade = 0; grade <= 12; grade++)
            {
              'grade': grade,
              'willCost': oculumScrollWillCost(grade),
              'cooldown': oculumScrollCooldown(grade),
              'uses': 1,
            },
        ],
      }),
    );
    final sfera = oculumOculumTheftSkill();
    expect(sfera.forme, hasLength(5));
    for (final form in sfera.forme) {
      expect(auditCosts(oculumCharacterSkillFormCost(form)), isEmpty);
      expect(form.costo, '1 Azione');
      expect(form.cooldownStrutturato?.amount, 3);
    }
  });
}
