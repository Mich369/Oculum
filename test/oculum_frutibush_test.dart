import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  test('Polline vigile uses the registered initiative type and keeps its forms', () {
    final monster = monsterBookEntryById(oculumFrutibushId)!;
    final technique = monsterBookConcreteTechnique('frutibush_polline')!;
    final source = oculumMonsterBookSkills(monster)
        .singleWhere((skill) => skill.nome == 'Polline vigile');
    final restored = CharacterSkill.fromJson(source.toJson());
    expect(technique.minimums, [1, 2, 3]);
    expect(technique.maximums, [1, 2, 3]);
    expect(technique.cooldowns, [2, 3, 4]);
    expect(restored.forme, hasLength(3));
    for (var form = 0; form < 3; form++) {
      final effect = restored.forme[form].effettiStrutturati.single;
      expect(oculumStructuredEffectTypes, contains(effect.type));
      expect(effect.type, 'modifica_statistica');
      expect(effect.target, 'iniziativa');
      expect(oculumStructuredEffectTargetKey(effect), 'iniziativa');
      expect(effect.valueExpression, '${form + 1}');
      expect(effect.mode, 'temporaneo');
      expect(effect.duration, '1');
      expect(effect.durationUnit, 'turni');
      expect(effect.recipient, 'alleato');
      expect(effect.maximumTargets, form + 2);
    }
  });

  test('Frutibush gets two fixed abilities and one of seven Nature skills', () {
    final monster = monsterBookEntryById(oculumFrutibushId)!;
    expect(monster.elementId, 'natura');
    expect(monster.skillIds.toSet(), hasLength(9));
    final assorted = <String>{};
    for (var seed = 0; seed < 100; seed++) {
      final result = oculumMonsterBookLoadout(monster, random: Random(seed));
      expect(result.skills, hasLength(3));
      final names = result.skills.map((skill) => skill.nome).toSet();
      expect(names, containsAll(['Cura', 'Foglie Lama']));
      assorted.add(names.difference({'Cura', 'Foglie Lama'}).single);
    }
    expect(assorted, hasLength(7));
  });

  test(
    'Foglie Lama stores 3/6/12 caps and remains separate from Sempre Verde',
    () {
      final monster = monsterBookEntryById(oculumFrutibushId)!;
      final skill = oculumMonsterBookSkills(
        monster,
      ).singleWhere((skill) => skill.nome == 'Foglie Lama');
      final restored = CharacterSkill.fromJson(skill.toJson());
      expect(
        restored.forme.map(
          (form) => form.effettiStrutturati.single.maximumTargets,
        ),
        [3, 6, 12],
      );
      expect(
        restored.forme
            .map((form) => form.effettiStrutturati.single.target)
            .toSet(),
        {oculumFrutibushLeafSkill},
      );
      expect(oculumEvergreenLeafDamage(20, 4), 48);
    },
  );

  test('Leaves share the base and add 10 once per distinct target', () {
    List<int> damage(List<String> tags, {int grade = 0, int form = 1}) =>
        oculumFrutibushLeafDamage(
          totalDamage: 40,
          grade: grade,
          form: form,
          enemyTags: tags,
        );
    expect(damage(['a']), [55]);
    expect(damage(['a', 'a', 'a']), [25, 15, 15]);
    expect(damage(['a', 'b', 'a']), [25, 25, 15]);
    expect(damage(['a', 'b', 'c'], grade: 2), [40, 40, 40]);
    expect(damage(List.filled(12, 'a'), form: 3), [
      14,
      ...List.filled(8, 4),
      ...List.filled(3, 3),
    ]);
    expect(damage(['a', 'b']), [33, 32]);
    expect(damage(List.filled(4, 'a')), isEmpty);
    expect(damage(['']), isEmpty);
  });

  testWidgets('Fight planner concentrates three leaves into one enemy', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    final damage = probe.damageTotal();
    final leaf = oculumMonsterBookSkills(
      monsterBookEntryById(oculumFrutibushId)!,
    ).singleWhere((skill) => skill.nome == 'Foglie Lama');
    probe.applyEffects(leaf.forme.first.effettiStrutturati);
    final plan = probe.planAttack(total: 30, natural: 10);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.ensureVisible(find.text('Dichiara e tira'));
    await tester.tap(find.text('Dichiara e tira'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('3 foglie'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.runAsync(() async => await plan);

    final volley = (state.onlineCombatRequests.values as Iterable)
        .whereType<Map>()
        .singleWhere((request) => request['kind'] == 'masked_volley');
    final packets = (volley['packets'] as List).cast<Map>();
    expect(packets, hasLength(3));
    expect(packets.map((packet) => packet['element']).toSet(), {'natura'});
    expect(packets.map((packet) => packet['targetTag']).toSet(), {'ENEMY'});
    expect(packets.map((packet) => packet['id']).toSet(), hasLength(3));
    expect(
      packets.fold<int>(0, (sum, packet) => sum + (packet['damage'] as int)),
      damage + 15,
    );
    expect(probe.structuredEffects(), isEmpty);
    await closeFixture(tester, probe);
  });
}
