import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

const _lookout = 'affogato_vedetta_dei_canali';
const _guardian = 'affogato_custode_della_chiusa';

void main() {
  test(
    'Affogato fish humanoids use ordinary encounter and progression data',
    () {
      final lookout = monsterBookEntryById(_lookout)!;
      final guardian = monsterBookEntryById(_guardian)!;
      for (final entry in [lookout, guardian]) {
        expect(entry.planeIds, ['affogato']);
        expect(entry.elementId, 'acqua');
        expect(entry.presetType, 'Mostro');
        expect(entry.classificationTags, contains('Umanoide'));
        expect(entry.descIt, contains('Eiva'));
        expect(entry.dropIds, hasLength(1));
        expect(entry.dropChances[entry.dropIds.single], 50);
        expect(entry.skillIds, hasLength(13));
        expect(
          entry.encounterRules['additionalProgressionSkills'],
          hasLength(12),
        );

        final anatomy = oculumMonsterPrecisionAnatomy(entry);
        expect(anatomy.map((part) => part['id']), [
          'body',
          'head',
          'eyes_1',
          'eyes_2',
          'gills_1',
          'gills_2',
          'arms_1',
          'arms_2',
          'legs_1',
          'legs_2',
        ]);
        expect(
          anatomy
              .where((part) => part['group'] == 'gills')
              .map((part) => part['side']),
          ['right', 'left'],
        );
        expect(
          anatomy
              .where((part) => part['weak'] == true)
              .map((part) => part['id']),
          ['gills_1', 'gills_2'],
        );
      }
      expect(lookout.stats['level'], 2);
      expect(guardian.stats['level'], 3);
      final spear = InventoryItem.fromJson(lookout.inventoryItems.single);
      expect(spear.nome, 'Lancia di canna');
      expect(spear.arma, isTrue);
      expect(spear.equipaggiata, isTrue);
      expect(guardian.inventoryItems, isEmpty);
    },
  );

  test('attack and guard keep their separate editable effects and costs', () {
    ArtSkill artForm(String monsterId, String name) {
      final entry = monsterBookEntryById(monsterId)!;
      final skill = oculumMonsterBookArt(
        entry,
      ).skills.singleWhere((skill) => skill.nome == name);
      return ArtSkill.fromJson(skill.toJson());
    }

    final attack = artForm(_lookout, 'Canalstryke');
    final guard = artForm(_guardian, 'Valvaguard');
    for (var form = 1; form <= 3; form++) {
      final damage = attack.effettiEvoluzione(form).single;
      expect(damage.type, 'danno');
      expect(damage.valueExpression, '${form * 3}');
      expect(damage.mode, 'prossima_azione');
      expect(damage.recipient, 'nemico');
      expect(attack.risorsaCostoPerLivello(form), 'materia');
      expect(attack.oculumMinimoPerLivello(form), form);
      expect(attack.oculumMassimoPerLivello(form), form);
      expect(attack.cooldownPerLivello[form - 1].amount, [2, 3, 3][form - 1]);

      final defense = guard.effettiEvoluzione(form).single;
      expect(defense.type, 'difesa');
      expect(defense.valueExpression, '${1 + 2 * form}');
      expect(defense.mode, 'temporaneo');
      expect(defense.duration, '1');
      expect(defense.recipient, 'se_stesso');
      expect(guard.risorsaCostoPerLivello(form), 'volonta');
      expect(guard.oculumMinimoPerLivello(form), form);
      expect(guard.oculumMassimoPerLivello(form), form);
      expect(guard.cooldownPerLivello[form - 1].amount, [3, 3, 4][form - 1]);
    }
  });

  test('spawn keeps its signature among three skills and one Open', () {
    for (final (monsterId, signature) in [
      (_lookout, 'Canalstryke'),
      (_guardian, 'Valvaguard'),
    ]) {
      final entry = monsterBookEntryById(monsterId)!;
      final opens = oculumMonsterBookOpenPool(entry).map((art) => art.openName);
      expect(opens, hasLength(2));
      for (var seed = 0; seed < 8; seed++) {
        final kit = oculumMonsterBookLoadout(entry, random: Random(seed));
        final art = kit.art!;
        final skills = [
          for (final skill in kit.skills)
            if (!skill.passiva) skill.nome,
          for (final skill in art.skills)
            if (!skill.tipoPerLivello(1).toLowerCase().contains('passiv'))
              skill.nome,
        ];
        expect(skills.toSet(), hasLength(3));
        expect(skills, contains(signature));
        expect(opens, contains(art.openName));
      }
    }
  });

  test('confirmed Fluttuare uses fixed two Oculum and three-turn cooldown', () {
    final skill = oculumPlanarTechnique('air_navigator_float')!;
    expect(skill.minimums, [2, 2, 2]);
    expect(skill.maximums, [2, 2, 2]);
    expect(skill.cooldowns, [3, 3, 3]);
  });
  test('452 authored entries have distinct IDs, names and techniques', () {
    const goats = {'caprone_d_ossa', 'caprone_scheletrico_nero'};
    expect(oculumPlanarMonsterEntries.length, 452);
    final ids = oculumPlanarMonsterEntries.map((e) => e.id).toSet();
    expect(ids.length, 452);
    expect(
      ids,
      containsAll({'manichino_baghest', ...goats, _lookout, _guardian}),
    );
    final names = oculumPlanarMonsterEntries
        .map((e) => e.nameIt.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ''))
        .toSet();
    expect(names.length, 452);
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
      final growthIds = e.skillIds
          .where((id) => id.startsWith(oculumMonsterProgressionPrefix))
          .toList();
      if (growthIds.isNotEmpty) {
        // The Octocruor family deliberately uses seven species-owned growth
        // techniques in its nine-choice Art pool. They resolve through the
        // same combined catalogue resolver used by the app, not the planar map.
        expect(
          e.encounterRules[oculumEivaFamilyIdRule],
          oculumPiovraSucchiasangueId,
          reason: e.id,
        );
        expect(e.encounterRules['authoredSkillPool'], isTrue, reason: e.id);
        final natural = oculumPiovraNaturalSkillIds(e);
        expect(natural, hasLength(2), reason: e.id);
        expect(e.skillIds, containsAll(natural), reason: e.id);
        expect(growthIds, <String>[
          for (var slot = 0; slot < 7; slot++)
            '$oculumMonsterProgressionPrefix${e.id}__$slot',
        ], reason: e.id);
        final candidates = e.skillIds
            .where((id) => !natural.contains(id))
            .toList();
        expect(candidates, hasLength(9), reason: e.id);
        expect(
          candidates.where((id) => !growthIds.contains(id)),
          hasLength(2),
          reason: e.id,
        );
      }
      for (final id in e.skillIds) {
        if (!id.startsWith(oculumMonsterProgressionPrefix)) {
          expect(oculumPlanarTechnique(id), isNotNull, reason: id);
          continue;
        }
        final technique = monsterBookConcreteTechnique(id);
        expect(technique, isNotNull, reason: id);
        final resolved = technique!;
        final slot = int.parse(id.split('__').last);
        expect(resolved.name.trim(), isNotEmpty, reason: id);
        expect(resolved.element, e.elementId, reason: id);
        expect(resolved.costResource, 'oculum', reason: id);
        expect(resolved.requiredLevel, (slot % 3) * 2, reason: id);
        expect(resolved.minimums, [1, 2, 3], reason: id);
        expect(resolved.maximums, [1, 2, 3], reason: id);
        expect(resolved.cooldowns, [2, 3, 4], reason: id);
        expect(resolved.forms, hasLength(3), reason: id);
        expect(
          resolved.forms.every((form) => form.isNotEmpty),
          isTrue,
          reason: id,
        );
        expect(monsterBookSkillText(id), resolved.text(), reason: id);
        expect(
          resolved.text(),
          isNot(contains('attacco tematico')),
          reason: id,
        );
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
    expect(monsterById('ice_shield')!.nameIt, 'Gelyrdryx');
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
