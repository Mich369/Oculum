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
  test('389 authored entries, including Baghest and the two Caproni', () {
    const goats = {'caprone_d_ossa', 'caprone_scheletrico_nero'};
    expect(oculumPlanarMonsterEntries.length, 389);
    final ids = oculumPlanarMonsterEntries.map((e) => e.id).toSet();
    expect(ids.length, 389);
    expect(ids, containsAll({'manichino_baghest', ...goats}));
    final names = oculumPlanarMonsterEntries
        .map((e) => e.nameIt.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ''))
        .toSet();
    expect(names.length, 389);
    for (final e in oculumPlanarMonsterEntries) {
      final retired = oculumIsRetiredMonsterId(e.id);
      expect(
        defaultMonsterBookEntries.where((m) => m.id == e.id).length,
        retired ? 0 : 1,
        reason: e.id,
      );
      if (retired) expect(oculumSavedMonsterBookEntryById(e.id)?.id, e.id);
      if (goats.contains(e.id)) {
        expect(e.weakPointIt, isEmpty, reason: e.id);
        expect(e.skillIds, [oculumBoneGoatChargeId], reason: e.id);
      } else {
        expect(e.weakPointIt, isNotEmpty, reason: e.id);
      }
      expect(e.planeIds, isNotEmpty);
      for (final id in e.skillIds) {
        expect(oculumPlanarTechnique(id), isNotNull, reason: id);
      }
    }
  });
  test('six Ice creatures keep distinct skills and aimable anatomy', () {
    const weakParts = {
      'costrutto_dei_tre_crani': 'neck',
      'scheletro_delle_lame_di_brina': 'ribs',
      'cacciatore_della_cresta_glaciale': 'throat',
      'arciere_del_gelo_cavo': 'drawing_wrist',
      'gigante_della_clava_polarnotte': 'forward_knee',
      'ice_shield': 'shield_elbow',
    };
    final skillIds = <String>{};
    for (final MapEntry(key: id, value: weakPart) in weakParts.entries) {
      final monster = monsterById(id)!;
      expect(monster.elementId, 'ghiaccio', reason: id);
      expect(monster.planeIds, ['ghiaccio'], reason: id);
      expect(monster.spriteAssetPath, isEmpty, reason: id);
      final anatomy = oculumMonsterPrecisionAnatomy(monster);
      expect(anatomy.where((part) => part['group'] == 'arms'), hasLength(2));
      expect(anatomy.where((part) => part['group'] == 'legs'), hasLength(2));
      expect(
        anatomy.where((part) => part['weak'] == true).single['id'],
        weakPart,
      );
      expect(monster.skillIds.take(2).toSet(), hasLength(2));
      for (final skillId in monster.skillIds.take(2)) {
        expect(skillIds.add(skillId), isTrue, reason: skillId);
        final skill = monsterBookConcreteTechnique(skillId)!;
        expect(skill.forms, hasLength(3));
        expect(skill.minimums, [1, 2, 3]);
        expect(skill.costResource, 'volonta');
      }
    }
    final shield = monsterBookConcreteTechnique('ice_shield_plates')!;
    expect(monsterById('ice_shield')!.nameIt, 'Ice Shield');
    expect(shield.forms.map((form) => form.single.type), everyElement('scudo'));
  });
  test('Idrax and its glacial variant have the same limbless anatomy', () {
    final base = monsterById('idrax')!;
    final glacial = monsterById('idrax_glaciale')!;
    expect(glacial.encounterRules['canonicalVariantOf'], base.id);
    expect(glacial.elementId, 'ghiaccio');
    expect(glacial.planeIds, ['ghiaccio']);
    expect(glacial.stats, base.stats);
    expect(glacial.skillIds.take(3), base.skillIds.take(3));
    expect(glacial.dropIds, base.dropIds);
    for (final monster in [
      base,
      glacial,
      monsterById('idrax_variante_errante')!,
    ]) {
      final anatomy = oculumMonsterPrecisionAnatomy(monster);
      expect(anatomy.map((part) => part['id']), [
        'body',
        'head',
        'eyes_1',
        'eyes_2',
        'throat',
        'tail',
      ]);
      expect(
        anatomy.where((part) => part['weak'] == true).single['id'],
        'throat',
      );
    }
  });
  test('Piranha Mortale and Angelic Ray have distinct editable techniques', () {
    final piranha = monsterById('piranha_mortale')!;
    expect(piranha.planeIds, ['affogato']);
    expect(piranha.skillIds.take(3), [
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
    // These six realms have their full legacy bestiary. The four newly
    // announced realms are explicitly still under construction.
    const completedMicroRealities = {
      'postea',
      'caramella',
      'foresta_elementale',
      'morti',
      'ghiaccio',
      'nuvole_rocciose',
    };
    for (final plane in completedMicroRealities) {
      final species = oculumPlanarMonsterEntries
          .where((e) => e.planeIds.contains(plane))
          .map((e) => e.id)
          .toSet();
      expect(species.length, greaterThanOrEqualTo(20), reason: plane);
    }
    for (final plane in oculumMonsterHabitats.keys.where(
      (id) => !const {
        'deserto_divoratore',
        'reame_cristallo',
        'orea_zalira',
        'carne_viva',
      }.contains(id),
    )) {
      expect(
        oculumPlanarMonsterEntries.any((e) => e.planeIds.contains(plane)),
        isTrue,
        reason: plane,
      );
    }
  });
  test('Gambio is a single neutral monster from Orea Zalira', () {
    final entry = defaultMonsterBookEntries.singleWhere(
      (entry) => entry.id == 'orea_gambio',
    );
    expect(entry.nameIt, 'Gambio');
    expect(entry.presetType, 'Mostro');
    expect(entry.planeIds, ['orea_zalira']);
    expect(entry.generationSide, 'neutral');
    expect(entry.stats['level'], 1);
    expect(oculumMonsterNaturalAttitude(entry), contains('pacifico'));
    expect(entry.skillIds, contains('realm_orea_gambio_0'));
    expect(
      oculumMonsterPrecisionAnatomy(entry).map((part) => part['id']),
      isNot(contains('fold')),
    );
    for (var seed = 0; seed < 6; seed++) {
      final loadout = oculumMonsterBookLoadout(entry, random: Random(seed));
      expect([
        ...loadout.skills.map((skill) => skill.nome),
        ...?loadout.art?.skills.map((skill) => skill.nome),
      ], contains('Spintarella di Gambio'));
    }
    expect(
      oculumPlanarTechnique('realm_orea_gambio_0')?.costResource,
      'volonta',
    );
    final restored = MonsterBookEntry.fromJson(entry.toJson());
    expect(restored.planeIds, entry.planeIds);
    expect(restored.generationSide, entry.generationSide);
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
