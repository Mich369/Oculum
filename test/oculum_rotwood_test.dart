import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test('Rotwood has the three-stage Desiccated skill', () {
    final monster = defaultMonsterBookEntries.singleWhere(
      (entry) => entry.id == 'legno_marcio',
    );
    expect(monster.descIt, contains('immune a Rinsecchito'));
    expect(monster.skillIds, contains('legno_marcio_rami_secchi'));

    final art = oculumMonsterBookArt(monster);
    expect(art.skills, hasLength(1));
    expect(art.skills.single.livello, 0);
    expect(art.skills.single.evo1, contains('metà Danni'));
    expect(art.skills.single.evo1, contains('Rinsecchito I'));
    expect(art.skills.single.evo3, contains('Rinsecchito a III'));
  });

  test('Rotwood damage and status advance only on successful rolls', () {
    final rinsecchito = oculumConditionDefinition('rinsecchito')!;
    expect(rinsecchito.maxStage, 3);
    expect(rinsecchito.percentForStage(1), 25);
    expect(rinsecchito.percentForStage(2), 50);
    expect(rinsecchito.percentForStage(3), 75);
    expect(oculumRotwoodSkillDamage(9, rollSucceeded: false), 4);
    expect(oculumRotwoodSkillDamage(9, rollSucceeded: true), 9);
    expect(oculumRotwoodSkillStage(0, rollSucceeded: false), 0);
    expect(oculumRotwoodSkillStage(0, rollSucceeded: true), 1);
    expect(oculumRotwoodSkillStage(1, rollSucceeded: true), 2);
    expect(oculumRotwoodSkillStage(2, rollSucceeded: true), 3);
    expect(oculumRotwoodSkillStage(3, rollSucceeded: true), 3);
    expect(oculumRotwoodSkillStage(2, rollSucceeded: false), 2);
  });
}
