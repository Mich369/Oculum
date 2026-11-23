import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/oculum_lama_orbita_rules.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test('the three original Predone IDs equip the orbit Art and boomerang', () {
    for (final (suffix, alias) in const [
      ('', 'Predone delle Nasse'),
      ('_variante_buio', 'Predone delle Nasse di Buio'),
      ('_variante_veleno', 'Predone delle Nasse di Veleno'),
    ]) {
      final entry = monsterBookEntryById('$oculumPredoneBoomerangId$suffix')!;
      expect(entry.nameIt, startsWith('Falxyryn'));
      expect(oculumMonsterNameSearchAliases(entry), contains(alias));
      expect(entry.inventoryItems.map((item) => item['nome']), [
        'Lama Orbita',
        'Spada corta del Predone',
        'Guanto d’arme di Orbita',
      ]);
      expect(
        oculumMonsterPrecisionAnatomy(
          entry,
        ).singleWhere((part) => part['id'] == 'weighted_net')['label'],
        'Lama Orbita',
      );
      final art = oculumMonsterBookLoadout(entry, random: Random(7)).art!;
      final orbit = art.skills.singleWhere(
        (skill) => skill.nome == 'Orbita del Boomerang',
      );
      final effects = orbit.effettiEvoluzione(1);
      expect(
        effects.map(
          (effect) => [
            effect.target,
            effect.valueExpression,
            effect.duration,
            effect.durationUnit,
            effect.recipient,
          ],
        ),
        [
          [oculumPredoneCloseReduction, '12', '3', 'azioni', 'se_stesso'],
          [oculumPredoneRangedReduction, '6', '3', 'azioni', 'se_stesso'],
        ],
      );
      expect(oculumCombatAbilityRoles(effects), {
        OculumCombatAbilityRole.defense,
        OculumCombatAbilityRole.support,
      });
    }
  });

  test('damage reduction is flat and has a zero floor', () {
    expect(oculumPredoneOrbitReducedDamage(20, 12), 8);
    expect(oculumPredoneOrbitReducedDamage(20, 6), 14);
    expect(oculumPredoneOrbitReducedDamage(5, 12), 0);
    expect(oculumPredoneOrbitReducedDamage(5, -4), 5);
  });

  test(
    'a qualified Drop copies the exact equipment and independent scrolls',
    () {
      final predone = monsterBookEntryById(
        '${oculumPredoneBoomerangId}_variante_veleno',
      )!;
      List<InventoryItem> drops({
        int natural = 20,
        int total = 45,
        int percentile = 0,
        int choice = 0,
      }) => oculumGenerateMonsterLoot(
        monster: predone,
        level: 0,
        grade: 1,
        random: _PredoneDropRandom(percentile, choice),
        killId: 'real-predone-kill',
        naturalDropRoll: natural,
        dropTotal: total,
      );
      final owned = [
        for (var i = 0; i < 3; i++)
          drops(
            choice: i,
          ).singleWhere((item) => item.monsterLoot['material'] == false),
      ];
      expect(owned.map((item) => item.nome), [
        'Lama Orbita',
        'Spada corta del Predone',
        'Guanto d’arme di Orbita',
      ]);
      expect(owned.every((item) => !item.equipaggiata), isTrue);
      expect(owned.map((item) => item.monsterLoot['id']).toSet(), hasLength(3));
      expect(owned[1].bonusDanno, 3);
      expect(owned[1].ability?.nome, 'Venynedge');
      expect(owned[2].bonusDanno, 3);
      expect(owned[2].bonusDifesa, 4);
      expect(owned[2].bonusScudo, 10);
      expect(owned[2].ability?.nome, 'Orbita del Boomerang');
      expect(drops(percentile: 10), hasLength(2));
      expect(drops(total: 39), hasLength(2));
      expect(
        drops(natural: 18, percentile: 10).single.nome,
        contains('Orbita'),
      );
      expect(drops(natural: 17, percentile: 10), isEmpty);
      expect(
        drops(
          percentile: 10,
        ).map((item) => item.monsterLoot['sourceSkillId']).toSet(),
        (predone.encounterRules['predoneLootScrollIds'] as List).toSet(),
      );
    },
  );

  test('the first authentic owner gets one affinity adjustment per blade', () {
    InventoryItem blade() {
      final predone = monsterBookEntryById(oculumPredoneBoomerangId)!;
      return oculumGenerateMonsterLoot(
        monster: predone,
        level: 0,
        grade: 0,
        random: const _PredoneDropRandom(0, 0),
        killId: 'predone-receipt',
        naturalDropRoll: 17,
        dropTotal: 30,
      ).single;
    }

    for (final (owner, elements, expected) in const [
      ('KILLER', ['acqua', 'metallo', 'vento'], 5),
      ('killer', ['fuoco'], -5),
      ('ally', ['vento'], 10),
      ('ally', ['luce'], 0),
    ]) {
      final item = blade();
      expect(
        oculumBindEncounterLamaOrbita(
          item,
          ownerTag: owner,
          ownedElements: elements,
        ),
        isFalse,
      );
      item.monsterLoot['lamaOrbitaAcquisition'] = {
        'previousOwnerTag': 'PREVIOUS',
        'killerTag': 'KILLER',
      };
      expect(
        oculumBindEncounterLamaOrbita(
          item,
          ownerTag: owner,
          ownedElements: elements,
        ),
        isTrue,
      );
      final state = item.craftData[oculumLamaOrbitaId] as Map;
      expect(state['affinity'], expected);
      expect(state['ownerTag'], owner);
      expect(state['previousOwnerTag'], 'PREVIOUS');
      expect(state['physicalId'], item.monsterLoot['id']);
      final reloaded = InventoryItem.fromJson(item.toJson());
      expect(
        oculumBindEncounterLamaOrbita(
          reloaded,
          ownerTag: owner,
          ownedElements: ['vento'],
        ),
        isFalse,
      );
      expect(
        (reloaded.craftData[oculumLamaOrbitaId] as Map)['affinity'],
        expected,
      );
    }
  });
}

class _PredoneDropRandom implements Random {
  const _PredoneDropRandom(this.percentile, this.choice);
  final int percentile, choice;

  @override
  int nextInt(int max) => max == 100 ? percentile : choice;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}
