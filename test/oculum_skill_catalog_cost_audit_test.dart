import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test(
    'every monster keeps its cost across Book, Art, natural skills and equipment',
    () {
      final problems = <String>[];
      final rows = <Map<String, dynamic>>[];
      var forms = 0;
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
            if (naturalResource != artResource)
              problems.add('$key: natural=$naturalResource Art=$artResource');
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
            });
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
    },
  );
}
