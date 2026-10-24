import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test('confirmed Fluttuare uses fixed two Oculum and three-turn cooldown', () {
    final skill = oculumPlanarTechnique('air_navigator_float')!;
    expect(skill.minimums, [2, 2, 2]);
    expect(skill.maximums, [2, 2, 2]);
    expect(skill.cooldowns, [3, 3, 3]);
  });
  test('244 authored entries, no duplicate ids or normalized names', () {
    expect(oculumPlanarMonsterEntries.length, 244);
    final ids = oculumPlanarMonsterEntries.map((e) => e.id).toSet();
    expect(ids.length, 244);
    final names = oculumPlanarMonsterEntries
        .map((e) => e.nameIt.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ''))
        .toSet();
    expect(names.length, 244);
    for (final e in oculumPlanarMonsterEntries) {
      expect(
        defaultMonsterBookEntries.where((m) => m.id == e.id).length,
        1,
        reason: e.id,
      );
      expect(e.weakPointIt, isNotEmpty);
      expect(e.planeIds, isNotEmpty);
      for (final id in e.skillIds) {
        expect(oculumPlanarTechnique(id), isNotNull, reason: id);
      }
    }
  });
  test('Piranha Mortale and Angelic Ray have distinct editable techniques', () {
    final piranha = monsterById('piranha_mortale')!;
    expect(piranha.planeIds, ['affogato']);
    expect(piranha.skillIds, [
      'piranha_morso',
      'piranha_sciame',
      'piranha_richiamo',
    ]);
    expect(piranha.encounterRules['swarmAttackerCount'], 2);
    expect(piranha.encounterRules['summon']['maxAlive'], 2);
    expect(
      oculumPlanarTechnique('piranha_morso')!.forms[1].last.target,
      'sanguinante',
    );
    expect(
      oculumPlanarTechnique('piranha_richiamo')!.forms[0].single.duration,
      '3',
    );
    final ray = oculumPlanarTechnique('raggio_angelico')!;
    expect(ray.element, 'angelico');
    expect(
      oculumAngelRayDamage(
        baseDamage: 10,
        attackerKarma: 4,
        targetKarma: -6,
        targetKind: 'Demone',
      ),
      40,
    );
    expect(
      oculumAngelRayDamage(
        baseDamage: 10,
        attackerKarma: 0,
        targetKarma: 8,
        targetKind: 'Diavolo',
      ),
      15,
    );
    expect(
      oculumAngelRayDamage(
        baseDamage: 10,
        attackerKarma: 0,
        targetKarma: 0,
        targetKind: 'Arcidiavolo',
      ),
      13,
    );
  });
  test('each microreality has at least twenty distinct base species', () {
    for (final plane in oculumMicroRealityIds) {
      final species = oculumPlanarMonsterEntries
          .where((e) => e.planeIds.contains(plane))
          .map((e) => e.id)
          .toSet();
      expect(species.length, greaterThanOrEqualTo(20), reason: plane);
    }
    for (final plane in oculumMonsterHabitats.keys) {
      expect(
        oculumPlanarMonsterEntries.any((e) => e.planeIds.contains(plane)),
        isTrue,
        reason: plane,
      );
    }
  });
  test('habitats and special rules survive JSON and custom overrides', () {
    final base = monsterBookEntryById('fire_shield')!;
    final restored = MonsterBookEntry.fromJson(base.toJson());
    expect(restored.planeIds, base.planeIds);
    expect(restored.encounterRules, base.encounterRules);
    configureMonsterBookEntries(
      customEntries: [
        base.copyWith(descIt: 'Personalizzato', stats: {'resilienza': 99}),
      ],
    );
    expect(monsterBookEntryById('fire_shield')!.stats['resilienza'], 99);
    resetMonsterBookEntries();
  });
  test('existing reference monsters are corrected, not duplicated', () {
    for (final id in ['sharp', 'ogle', 'topino_avventuroso', 'mosca_campana']) {
      expect(defaultMonsterBookEntries.where((e) => e.id == id).length, 1);
      expect(monsterBookEntryById(id)!.planeIds, isNotEmpty);
    }
    expect(monsterBookEntryById('sharp')!.stats['resilienza'], 2);
    expect(monsterBookEntryById('ogle')!.stats['volonta'], 0);
    expect(monsterBookEntryById('mosca_campana')!.stats['materia'], 5);
  });
  test('quest bonus is one exact mutually exclusive percentile draw', () {
    final counts = <String, int>{};
    for (var roll = 0; roll < 100; roll++) {
      final b = oculumQuestBonus(roll);
      final key = b.length == 4
          ? 'all'
          : b.isEmpty
          ? 'none'
          : b.keys.single;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    expect(counts, {
      'all': 1,
      'schivateOculumBonus': 3,
      'ispirazioniOculum': 5,
      'superIspirazioni': 10,
      'ispirazioni': 25,
      'none': 56,
    });
  });
  test(
    'short quests respect party baseline and never count lower level kills or summons',
    () {
      final quests = oculumCreatePartyQuests(
        plane: 'affogato',
        level: 2,
        grade: 0,
        veil: 6,
        sequence: 1,
        elements: ['acqua'],
      );
      expect(quests.length, 3);
      expect(quests[2]['target'], 9);
      expect(quests.first['target'], lessThanOrEqualTo(3));
      expect(
        oculumQuestAcceptsEnemy(quests[1], {
          'level': 2,
          'element': 'acqua',
        }, 'affogato'),
        isTrue,
      );
      expect(
        oculumQuestAcceptsEnemy(quests[1], {
          'level': 1,
          'element': 'acqua',
        }, 'affogato'),
        isFalse,
      );
      expect(
        oculumQuestAcceptsEnemy(quests[1], {
          'level': 2,
          'element': 'fuoco',
        }, 'affogato'),
        isFalse,
      );
      expect(
        oculumQuestAcceptsEnemy(quests[1], {
          'level': 2,
          'element': 'acqua',
          'isSummon': true,
        }, 'affogato'),
        isFalse,
      );
      expect(
        oculumQuestAcceptsEnemy(quests[1], {
          'level': 2,
          'element': 'acqua',
        }, 'mezzano'),
        isFalse,
      );
    },
  );
  test('Sharp rare scrolls depend on natural 18, not a large total', () {
    final monster = monsterBookEntryById('sharp')!;
    final low = oculumGenerateMonsterLoot(
      monster: monster,
      level: 0,
      grade: 0,
      random: Random(1),
      killId: 'a',
      naturalDropRoll: 17,
      dropTotal: 99,
    );
    expect(low.where((i) => i.craftData['scroll'] is Map), isEmpty);
    final high = oculumGenerateMonsterLoot(
      monster: monster,
      level: 0,
      grade: 0,
      random: Random(1),
      killId: 'b',
      naturalDropRoll: 18,
      dropTotal: 18,
    );
    expect(high.where((i) => i.craftData['scroll'] is Map).length, 2);
  });
  test('Topino precise skill levels and damage dice remain available', () {
    final t = monsterBookEntryById('topino_avventuroso')!;
    final art = oculumMonsterBookArt(t);
    final flame = art.skills.firstWhere((s) => s.nome == 'Fiaccolata');
    expect(
      flame.effettiPerLivello[0].any((e) => e.diceExpression == '1d6'),
      isTrue,
    );
    expect(flame.testoEvoluzione(1), contains('livello 1'));
    expect(flame.testoEvoluzione(2), contains('livello 4'));
    expect(flame.testoEvoluzione(3), contains('livello 7'));
  });
}
