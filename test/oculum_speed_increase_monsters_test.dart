import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test(
    'three speed species import editable real costs, cooldowns and exact buffs',
    () {
      for (final config in <(String, String, List<int>)>[
        ('lepre_scattobrina', 'volonta', [1, 2, 3]),
        ('geco_turbina_postea', 'materia', [1, 2, 3]),
        ('mantide_sanguescatto', 'vita', [5, 8, 12]),
      ]) {
        final monster = defaultMonsterBookEntries.singleWhere(
          (m) => m.id == config.$1,
        );
        expect(monster.dropIds, isNotEmpty);
        final skill = oculumMonsterBookSkills(
          monster,
        ).singleWhere((s) => s.nome == 'Aumento di velocità');
        final restored = CharacterSkill.fromJson(skill.toJson());
        for (var form = 0; form < 3; form++) {
          final value = restored.forme[form];
          expect(value.costoStrutturato!.resource, config.$2);
          expect(value.costoStrutturato!.minimum, config.$3[form]);
          expect(value.cooldownStrutturato!.amount, [6, 4, 3][form]);
          expect(
            value.effettiStrutturati
                .singleWhere((e) => e.target == 'speed_increase')
                .valueExpression,
            '${form + 1}',
          );
          expect(
            value.effettiStrutturati
                .singleWhere((e) => e.target == 'iniziativa')
                .valueExpression,
            '${[1, 3, 6][form]}',
          );
          if (form > 0) {
            expect(
              value.effettiStrutturati
                  .singleWhere((e) => e.target == 'attacco_percentuale')
                  .valueExpression,
              '10',
            );
            expect(
              value.effettiStrutturati
                  .singleWhere((e) => e.target == 'difesa_percentuale')
                  .valueExpression,
              '10',
            );
          }
        }
      }
    },
  );
}
