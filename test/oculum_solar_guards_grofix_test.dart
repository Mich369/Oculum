import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test(
    'solar guards have exact level-zero powers and retain grade/level growth',
    () {
      for (final entry in {
        'guardia_solare': 13,
        'guardia_solare_elite': 56,
        'guardiano_solare': 126,
      }.entries) {
        final monster = monsterById(entry.key)!;
        final base = oculumMonsterCreationStats(monster, 0);
        expect(base.values.fold(0, (int a, int b) => a + b), entry.value);
        final grown = oculumMonsterCreationStats(monster, 10);
        expect(
          grown.values.fold(0, (int a, int b) => a + b),
          entry.value + oculumGeneratedMonsterBudget(monster.presetType, 10),
        );
        expect(
          monsterBookUsableSkillIds(monster).length,
          greaterThanOrEqualTo(16),
        );
        expect(
          oculumCelestialAllegiance({'monsterBookSourceId': monster.id}),
          'solare',
        );
        expect(monster.imageBase64, isEmpty);
        expect(monster.spriteAssetPath, isEmpty);
      }
      expect(monsterById('guardia_solare')!.stats['resilienza'], 1);
      expect(
        monsterById('guardiano_solare')!.encounterRules['slowColossus'],
        isTrue,
      );
    },
  );
  test('new seraphs have six wings; Grofix is independently encounterable', () {
    for (final id in ['serafino_solare', 'serafino_angelico']) {
      final monster = monsterById(id)!;
      expect(monster.isMiniBoss, isTrue);
      expect(monster.encounterRules['wingCount'], 6);
      expect(
        monster.stats.entries
            .where(
              (e) => [
                'resilienza',
                'volonta',
                'materia',
                'oculum',
              ].contains(e.key),
            )
            .fold(0, (int a, e) => a + e.value),
        greaterThan(126),
      );
      expect(
        oculumMonsterBookArt(monster).skills.length,
        greaterThanOrEqualTo(16),
      );
    }
    final grofix = monsterById('grofix')!;
    expect(grofix.encounterRules['canEncounterAlreadyAwake'], isTrue);
    expect(grofix.encounterRules['harvestAwakeningNatural'], 1);
    expect(grofix.planeIds, contains('sotterraneo'));
    expect(
      oculumMonsterBookArt(grofix).skills.length,
      greaterThanOrEqualTo(16),
    );
  });
}
