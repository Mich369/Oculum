import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

class _FixedPercentile implements Random {
  _FixedPercentile(this.percentile);

  final int percentile;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => percentile / 100;

  @override
  int nextInt(int max) => max == 100 ? percentile : 0;
}

void main() {
  test('Petryguard loot requires ordinary Drop success before its percentile', () {
    const expectedRates = {
      oculumBabyRockRhinoId: 6,
      oculumIntermediateRockRhynoId: 9,
      oculumVeteranBabyRockRhinoId: 12,
    };
    for (final entry in expectedRates.entries) {
      final monster = monsterById(entry.key)!;
      expect(monster.dropChances[oculumRhinoStoneguardDropId], entry.value);
      expect(monster.encounterRules['startingStoneShieldPercent'], 25);

      List<InventoryItem> scrolls(int total, int percentile) =>
          oculumGenerateMonsterLoot(
            monster: monster,
            level: 2,
            grade: 1,
            random: _FixedPercentile(percentile),
            killId: 'rhino-$percentile',
            naturalDropRoll: 11,
            dropTotal: total,
          ).where((item) =>
            item.monsterLoot['catalogueDropId'] == oculumRhinoStoneguardDropId,
          ).toList();

      expect(scrolls(24, 0), isEmpty);
      expect(scrolls(25, entry.value), isEmpty);
      final scroll = scrolls(25, entry.value - 1).single;
      expect(scroll.monsterLoot['sourceMonsterBookId'], entry.key);
      expect(scroll.monsterLoot['dropDifficulty'], 25);
      expect(scroll.monsterLoot['material'], isNot(true));
      expect(scroll.nome, oculumMonsterDropName(oculumRhinoStoneguardDropId));
    }
    final middle = monsterById(oculumIntermediateRockRhynoId)!;
    expect(middle.nameIt, 'RockRhyno');
    expect(middle.stats['hp'], greaterThan(monsterById(oculumBabyRockRhinoId)!.stats['hp']!));
    expect(middle.stats['hp'], lessThan(monsterById(oculumVeteranBabyRockRhinoId)!.stats['hp']!));
  });

  test('the rare scroll is searchable and encodes an editable passive', () {
    final original = oculumRhinoStoneguardScroll();
    final item = InventoryItem.fromJson(original.toJson());
    final scroll = Map<String, dynamic>.from(item.craftData['scroll'] as Map);
    final index = OculumInventorySearchIndex([item]);

    expect(item.craftData['rarity'], 'raro');
    expect(index.search(query: 'Petryguard', category: 'scroll'), [item]);
    expect(index.search(query: 'Stoneguard'), [item]);
    expect(index.search(query: 'Guardia di pietra del Rinoceronte'), [item]);
    expect(oculumScrollCombatEffects(scroll), isEmpty);
    expect(oculumScrollCombatRoles(scroll, const []), isEmpty);

    final passive = CharacterSkill.fromJson({
      ...Map<String, dynamic>.from(scroll['authoredSkill'] as Map),
      'scrollData': {...scroll, 'learned': true},
    });
    expect(passive.nome, 'Petryguard');
    expect(passive.id, oculumRhinoStoneguardPassiveId);
    expect(passive.passiva, isTrue);
    expect(passive.equipaggiata, isTrue);
    expect(passive.costo, '0');
    expect(passive.scrollData['startingShieldPercent'], 25);
    passive.scrollData['startingShieldPercent'] = 30;
    expect(
      CharacterSkill.fromJson(passive.toJson()).scrollData['startingShieldPercent'],
      30,
    );
  });
}
