import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

Set<String> _effectTechniqueOrigins(Iterable<OculumStructuredEffect> effects) {
  final pattern = RegExp(r'^(.+)_forma_\d+_\d+$');
  return <String>{
    for (final effect in effects)
      if (pattern.firstMatch(effect.id)?.group(1) case final String source)
        source,
  };
}

ArtSkill _catalogueTechniqueForSource(
  MonsterBookEntry monster,
  CharacterArt art,
  String sourceId,
) {
  final ids = monsterBookUsableSkillIds(monster);
  expect(ids.where((id) => id == sourceId), hasLength(1), reason: sourceId);
  expect(art.skills, hasLength(ids.length), reason: monster.id);
  final skill = art.skills[ids.indexOf(sourceId)];
  final origins = _effectTechniqueOrigins(
    skill.effettiPerLivello.expand((effects) => effects),
  );
  if (origins.isNotEmpty) {
    expect(
      origins,
      contains(oculumMonsterBookSkillBaseId(sourceId)),
      reason: '${monster.id}/$sourceId effect provenance',
    );
  }
  return skill;
}

void _expectAuthoredSoulFighterCatalogue(MonsterBookEntry monster) {
  final arts = <CharacterArt>[
    ?oculumMonsterBookImportArt(monster),
    ...oculumMonsterBookAdditionalArts(monster),
  ];
  final ids = <String>[
    ...monsterBookUsableSkillIds(monster),
    if (monster.id == oculumSoulFighterEliteId) oculumAnymareapEffect,
  ];
  expect(
    arts,
    hasLength(monster.id == oculumSoulFighterEliteId ? 3 : 2),
    reason: monster.id,
  );
  final skills = arts.expand((art) => art.skills).toList();
  expect(skills, hasLength(ids.length), reason: monster.id);
  expect(ids.toSet(), hasLength(ids.length), reason: monster.id);
  for (final id in ids) {
    final expected = switch (id) {
      'soul_fighter_cut' => (
        name: 'Taglio dell’Ultimo Respiro',
        effectId: oculumSoulFighterCutEffect,
        type: 'danno_percentuale',
        value: '20',
        cost: 3,
        cooldown: 4,
        minimumTargets: 1,
        maximumTargets: 1,
        recipient: 'nemico',
        element: 'spirituale',
      ),
      'soul_fighter_guard' => (
        name: 'Mano della Veglia',
        effectId: 'soul_fighter_guard',
        type: 'scudo',
        value: '12',
        cost: 2,
        cooldown: 3,
        minimumTargets: 1,
        maximumTargets: 1,
        recipient: 'alleato',
        element: '',
      ),
      'soul_fighter_skull' => (
        name: 'Marchio dei Senza Nome',
        effectId: 'soul_fighter_skull',
        type: 'difesa',
        value: '-3',
        cost: 2,
        cooldown: 3,
        minimumTargets: 1,
        maximumTargets: 1,
        recipient: 'nemico',
        element: 'spirituale',
      ),
      oculumAnymareapEffect => (
        name: 'Anymareap',
        effectId: oculumAnymareapEffect,
        type: 'danno',
        value: '0',
        cost: 4,
        cooldown: 4,
        minimumTargets: 1,
        maximumTargets: 3,
        recipient: 'nemico',
        element: 'spirituale',
      ),
      _ => throw StateError('Unknown authored Soulfighter technique: $id'),
    };
    final matches = skills
        .where((skill) => skill.nome == expected.name)
        .toList();
    expect(matches, hasLength(1), reason: '${monster.id}/$id');
    final skill = ArtSkill.fromJson(matches.single.toJson());
    if (id != oculumAnymareapEffect) {
      final prose = monsterBookSkillText(id);
      expect(prose, startsWith('${expected.name} — I/'), reason: id);
      expect(prose, contains(skill.evo1), reason: id);
      expect(prose, contains('Costo: ${expected.cost} Oculum.'), reason: id);
      expect(prose, contains('CD ${expected.cooldown} turni.'), reason: id);
      expect(prose, contains('Una sola forma.'), reason: id);
      expect(monsterBookSkillText('${id}_variante_elite'), prose);
    }
    expect(skill.evo1, isNot(contains('attacco tematico')), reason: id);
    expect(skill.evo1, isNot(contains('canalizzi il tema')), reason: id);
    expect(skill.evo2, '???', reason: id);
    expect(skill.evo3, '???', reason: id);
    expect(skill.risorsaCostoPerLivello(1), 'oculum', reason: id);
    expect(skill.oculumMinimoPerLivello(1), expected.cost, reason: id);
    expect(skill.oculumMassimoPerLivello(1), expected.cost, reason: id);
    expect(
      skill.cooldownPerLivello.first.amount,
      expected.cooldown,
      reason: id,
    );
    expect(skill.effettiEvoluzione(1), hasLength(1), reason: id);
    expect(skill.effettiEvoluzione(2), isEmpty, reason: id);
    expect(skill.effettiEvoluzione(3), isEmpty, reason: id);
    final effect = skill.effettiEvoluzione(1).single;
    expect(oculumStructuredEffectTypes, contains(effect.type), reason: id);
    expect(effect.id, expected.effectId, reason: id);
    expect(effect.type, expected.type, reason: id);
    expect(effect.valueExpression, expected.value, reason: id);
    expect(effect.minimumTargets, expected.minimumTargets, reason: id);
    expect(effect.maximumTargets, expected.maximumTargets, reason: id);
    expect(effect.recipient, expected.recipient, reason: id);
    expect(effect.elementType, expected.element, reason: id);
  }
}

// Only these two paths replace the raw catalogue factory before generic
// technique construction. The other fixed progression kits still use the
// generic contracts below; fixed progression alone is not an exemption.
bool _expectExplicitAuthoredFactoryCatalogue(MonsterBookEntry monster) {
  if (oculumIsSoulFighter(monster.id)) {
    _expectAuthoredSoulFighterCatalogue(monster);
    return true;
  }
  if (monster.id != 'durafur') return false;
  expect(oculumMonsterHasFixedProgressionSkills(monster), isTrue);
  expect(monster.skillIds, ['durafur_fur_fury']);
  final source = oculumMonsterBookArt(monster);
  final sourceSnapshot = jsonEncode(source.toJson());
  final art = CharacterArt.fromJson(
    jsonDecode(sourceSnapshot) as Map<String, dynamic>,
  );
  expect(art.toJson(), source.toJson());
  expect(art.skills, hasLength(1));
  final skill = art.skills.single;
  expect(skill.nome, 'Furia del Pelo Ferrigno');
  expect(skill.livello, 1);
  expect(skill.unlockRequirementsPerLevel.every((r) => r.isEmpty), isTrue);
  expect(oculumMonsterBookImportArt(monster), isNull);
  final natural = oculumMonsterBookSkills(monster);
  expect(natural, hasLength(1));
  final restoredNatural = CharacterSkill.fromJson(natural.single.toJson());
  expect(restoredNatural.toJson(), natural.single.toJson());
  expect(restoredNatural.nome, skill.nome);
  expect(restoredNatural.forme, hasLength(3));
  final prose = monsterBookSkillText('durafur_fur_fury');
  expect(prose, startsWith('Furia del Pelo Ferrigno — I/'));
  expect(prose, contains('Nessun costo.'));
  expect(
    prose,
    contains('CD 5 turni; a inizio Fight deve recuperare 2 turni.'),
  );
  expect(monsterBookSkillText('durafur_fur_fury_variante_veterana'), prose);
  const bonuses = [30, 40, 60];
  for (var index = 0; index < bonuses.length; index++) {
    final form = index + 1;
    final bonus = bonuses[index];
    expect(skill.testoEvoluzione(form), '+$bonus Danni per 3 turni.');
    expect(prose, contains('+$bonus Danni per 3 turni'));
    expect(skill.tipoPerLivello(form), 'Supporto');
    expect(skill.risorsaCostoPerLivello(form), 'nessuna');
    expect(skill.oculumMinimoPerLivello(form), 0);
    expect(skill.oculumMassimoPerLivello(form), 0);
    final effect = skill.effettiEvoluzione(form).single;
    expect(effect.id, 'durafur_fur_fury_$bonus');
    expect(effect.type, 'modifica_statistica');
    expect(effect.target, 'danni');
    expect(effect.valueExpression, '$bonus');
    expect(effect.mode, 'temporaneo');
    expect(effect.duration, '3');
    expect(effect.recipient, 'se_stesso');
    final cooldown = skill.cooldownPerLivello[index];
    expect(cooldown.amount, 5);
    expect(cooldown.startsReady, isFalse);
    expect(cooldown.initialRemaining, 2);
    expect(cooldown.enterCombat('durafur-concrete-fixture'), isTrue);
    expect(cooldown.remaining, 2);
    final inherited = restoredNatural.forme[index];
    expect(inherited.costoStrutturato!.resource, 'nessuna');
    expect(inherited.costoStrutturato!.minimum, 0);
    expect(inherited.costoStrutturato!.maximum, 0);
    expect(inherited.descrizione, '+$bonus Danni per 3 turni.');
    expect(inherited.effettiStrutturati.single.toJson(), effect.toJson());
    expect(inherited.cooldownStrutturato!.amount, 5);
    expect(inherited.cooldownStrutturato!.startsReady, isFalse);
    expect(inherited.cooldownStrutturato!.initialRemaining, 2);
  }
  expect(jsonEncode(source.toJson()), sourceSnapshot);
  return true;
}

void main() {
  test(
    'Crostaceo omonime remain distinct source choices without changing data',
    () {
      final monster = monsterBookEntryById('crostaceo_corazzato')!;
      const pair = <String>{
        'crostaceo_corazzato_acqua_strike',
        'crostaceo_corazzato_acqua_guard',
      };
      final catalogue = oculumMonsterBookArt(monster);
      final sourceById = <String, ArtSkill>{
        for (final id in pair)
          id: _catalogueTechniqueForSource(monster, catalogue, id),
      };
      // Keep the existing display labels and effects, including this collision.
      // Independent selection comes from the two source IDs, not a rename.
      expect(
        sourceById.values.map((skill) => skill.nome).toSet(),
        hasLength(1),
      );
      final restored = CharacterArt.fromJson(catalogue.toJson());
      for (final id in pair) {
        expect(
          _catalogueTechniqueForSource(monster, restored, id).toJson(),
          sourceById[id]!.toJson(),
          reason: id,
        );
      }
      final seen = <String>{};
      for (var seed = 0; seed < 256; seed++) {
        final kit = oculumMonsterBookLoadout(
          monster,
          random: Random(seed),
          level: 12,
        );
        final selected = <Set<String>>[
          for (final skill in kit.skills.where((skill) => !skill.passiva))
            _effectTechniqueOrigins(
              skill.forme.expand((form) => form.effettiStrutturati),
            ),
          for (final skill in kit.art?.skills ?? const <ArtSkill>[])
            if (!skill.tipoPerLivello(1).toLowerCase().contains('passiv'))
              _effectTechniqueOrigins(
                skill.effettiPerLivello.expand((effects) => effects),
              ),
        ];
        expect(selected, hasLength(3), reason: 'seed $seed');
        expect(
          selected.every((ids) => ids.length == 1),
          isTrue,
          reason: 'seed $seed',
        );
        expect(
          selected.expand((ids) => ids).toSet(),
          hasLength(3),
          reason: 'seed $seed',
        );
        seen.addAll(selected.expand((ids) => ids).where(pair.contains));
        for (final skill in kit.art?.skills ?? const <ArtSkill>[]) {
          final origins = _effectTechniqueOrigins(
            skill.effettiPerLivello.expand((effects) => effects),
          );
          for (final id in origins.where(pair.contains)) {
            expect(skill.nome, sourceById[id]!.nome);
            expect(
              skill.oculumMinimiPerLivello,
              sourceById[id]!.oculumMinimiPerLivello,
            );
            expect(
              skill.oculumMassimiPerLivello,
              sourceById[id]!.oculumMassimiPerLivello,
            );
            expect(
              skill.cooldownPerLivello.map((timer) => timer.toJson()),
              sourceById[id]!.cooldownPerLivello.map((timer) => timer.toJson()),
            );
            expect(
              skill.effettiPerLivello.map(
                (effects) => effects.map((e) => e.toJson()).toList(),
              ),
              sourceById[id]!.effettiPerLivello.map(
                (effects) => effects.map((e) => e.toJson()).toList(),
              ),
            );
          }
        }
      }
      expect(
        seen,
        pair,
        reason: 'Both source IDs must be independently selectable',
      );
    },
  );

  test(
    'legacy custom kits and edited names costs survive source-ID selection',
    () {
      final builtin = monsterBookEntryById('crostaceo_corazzato')!;
      const strike = 'crostaceo_corazzato_acqua_strike';
      const guard = 'crostaceo_corazzato_acqua_guard';
      final art = oculumMonsterBookArt(builtin);
      final edited = _catalogueTechniqueForSource(builtin, art, guard);
      final legacyName = edited.nome;
      edited.nome = 'La mia guardia della conchiglia';
      edited.oculumMinimiPerLivello[0] = 17;
      edited.oculumMassimiPerLivello[0] = 19;
      edited.oculumMassimiInizialiPerLivello[0] = 19;
      edited.oculumLimitiManualiPerLivello[0] = true;
      edited.cooldownPerLivello.first.amount = 11;
      final customRaw = builtin.toJson()
        ..['nameIt'] = 'Karyklaw personale'
        ..['skillIds'] = <String>[guard, strike]
        ..['encounterRules'] = <String, dynamic>{
          ...builtin.encounterRules,
          'loadoutPolicy': 'legacy_saved_custom',
          'signatureSkillId': legacyName,
          'fixedSkillIds': <String>[legacyName],
        };
      final snapshot =
          jsonDecode(
                jsonEncode(<String, dynamic>{
                  'monster': customRaw,
                  'art': art.toJson(),
                }),
              )
              as Map<String, dynamic>;
      final custom = MonsterBookEntry.fromJson(
        Map<String, dynamic>.from(snapshot['monster'] as Map),
      );
      final savedArt = CharacterArt.fromJson(
        Map<String, dynamic>.from(snapshot['art'] as Map),
      );
      final beforeMonster = jsonEncode(custom.toJson());
      final beforeArt = jsonEncode(savedArt.toJson());
      for (var seed = 0; seed < 8; seed++) {
        final kit = oculumMonsterBookLoadout(
          custom,
          random: Random(seed),
          level: 12,
        );
        final sources = <String>{
          for (final skill in kit.skills)
            ..._effectTechniqueOrigins(
              skill.forme.expand((form) => form.effettiStrutturati),
            ),
          for (final skill in kit.art?.skills ?? const <ArtSkill>[])
            ..._effectTechniqueOrigins(
              skill.effettiPerLivello.expand((effects) => effects),
            ),
        };
        expect(sources, {strike, guard});
        expect(kit.skills.length + (kit.art?.skills.length ?? 0), 2);
      }
      expect(jsonEncode(custom.toJson()), beforeMonster);
      expect(jsonEncode(savedArt.toJson()), beforeArt);
      expect(custom.encounterRules['signatureSkillId'], legacyName);
      final restored = _catalogueTechniqueForSource(builtin, savedArt, guard);
      expect(restored.nome, 'La mia guardia della conchiglia');
      expect(restored.oculumMinimoPerLivello(1), 17);
      expect(restored.oculumMassimoPerLivello(1), 19);
      expect(restored.cooldownPerLivello.first.amount, 11);
    },
  );

  test('monster relic affixes can buff a subtrait or a core stat', () {
    final subtrait = oculumRollMonsterRelicFoundBuff(_SequenceRandom([20, 4]))!;
    expect(subtrait['kind'], 'subtrait');
    expect(subtrait['amount'], 1);
    expect(subtrait['command'], startsWith('@Adattamento+1'));

    final rareStat = oculumRollMonsterRelicFoundBuff(_AlwaysZeroRandom())!;
    expect(rareStat['kind'], 'stat');
    expect(rareStat['amount'], 2);
    expect(rareStat['command'], '@Resilienza+2');
  });

  test('Patalpa armor Shield scales by item level and Grade', () {
    InventoryItem patalpaArmor(int level, int grade) =>
        oculumGenerateMonsterLoot(
          monster: monsterById('patalpa_dolce')!,
          level: level,
          grade: grade,
          random: _AlwaysZeroRandom(),
          killId: 'patalpa-$level-$grade',
          naturalDropRoll: 20,
          dropTotal: 30 + grade * 10,
        ).firstWhere((item) => item.nome == 'Armatura del Patalpa');

    final base = patalpaArmor(0, 0);
    expect(base.bonusDifesa, 5);
    expect(base.bonusScudo, 6);
    expect(base.craftData['manualPriceObser'], greaterThan(0));
    expect(base.craftData['foundBuffChancePercent'], 20);
    expect(base.craftData['foundRareBuffChancePercent'], 5);
    expect(patalpaArmor(3, 0).bonusScudo, 24);
    expect(patalpaArmor(3, 1).bonusScudo, 36);
    expect(patalpaArmor(3, 1).craftData['shieldScaling'], {
      'base': 6,
      'perItemLevel': 6,
      'perGradePerItemLevel': 4,
      'formula': '6 + 6*itemLevel + 4*grade*itemLevel',
    });
  });

  test('Drop DT scales by defeated level and grade', () {
    expect(
      List.generate(13, oculumMonsterRelicDropThreshold),
      List.generate(13, (grade) => 30 + grade * 10),
    );
    expect(oculumMonsterDropDifficulty(level: 0, grade: 0), 20);
    expect(oculumMonsterDropDifficulty(level: 5, grade: 0), 25);
    expect(oculumMonsterDropDifficulty(level: 5, grade: 2), 31);
    expect(
      oculumGenerateMonsterLoot(
        monster: monsterById('costrutto_rinsecchito')!,
        level: 2,
        grade: 1,
        random: Random(1),
        killId: 'failed-drop-check',
        naturalDropRoll: 20,
        dropTotal: 24,
      ),
      isEmpty,
    );
  });
  test(
    'Forest Demon level-three armor has editable defense shield and skill',
    () {
      InventoryItem? armor;
      for (var seed = 0; seed < 100 && armor == null; seed++) {
        final items = oculumGenerateMonsterLoot(
          monster: monsterById('forest_demon')!,
          level: 3,
          grade: 0,
          random: Random(seed),
          killId: 'forest-$seed',
          naturalDropRoll: 20,
          dropTotal: 32,
        );
        for (final item in items) {
          if (item.nome == 'Corazza scheletrica del Forest Demon') armor = item;
        }
      }
      expect(armor, isNotNull);
      final restored = InventoryItem.fromJson(armor!.toJson());
      expect(restored.livelloOggetto, 3);
      expect(restored.bonusDifesa, 6);
      expect(restored.bonusScudo, 60);
      expect(
        restored.ability!.forme.single.effettiStrutturati.single.duration,
        '1',
      );
    },
  );
  test(
    'Forest Demon armor skill keeps one-turn Will and level gate in JSON',
    () {
      final skill = CharacterSkill.fromJson(
        oculumForestDemonArmorAbility(3).toJson(),
      );
      final form = skill.forme.single;
      expect(form.livello, '3');
      expect(form.cooldownStrutturato!.amount, 3);
      expect(form.cooldownStrutturato!.ready, isTrue);
      final effect = form.effettiStrutturati.single;
      expect(effect.type, 'modifica_statistica');
      expect(effect.target, 'volonta');
      expect(effect.valueExpression, '5');
      expect(effect.duration, '1');
      expect(effect.durationUnit, 'turni');
      expect(
        oculumEquipmentSkillLevelAvailable(
          characterLevel: 2,
          itemLevel: 3,
          formLevel: form.livello,
        ),
        isFalse,
      );
      expect(
        oculumEquipmentSkillLevelAvailable(
          characterLevel: 3,
          itemLevel: 3,
          formLevel: form.livello,
        ),
        isTrue,
      );
    },
  );
  test(
    'Blue Slime shield scales Oculum shield by level and uses Slime element',
    () {
      List<InventoryItem> lootAt(int total) => oculumGenerateMonsterLoot(
        monster: monsterById('slime_blu')!,
        level: 4,
        grade: 1,
        random: Random(10),
        killId: 'slime-blue-test',
        naturalDropRoll: 20,
        dropTotal: total,
      );
      bool isRelic(InventoryItem item) =>
          item.nome == 'Elmetto-scudo di melma blu';
      expect(lootAt(39).where(isRelic), isEmpty);
      final relic = lootAt(40).singleWhere(isRelic);
      expect(relic.arma, isTrue);
      expect(relic.protegge, isTrue);
      expect(relic.livelloOggetto, 4);
      expect(relic.gradoRichiesto, 1);
      expect(relic.elementoDanno, 'Slime');
      expect(relic.bonusDanno, 4);
      expect(relic.bonusDifesa, 4);
      expect(relic.bonusScudoOculum, 14);
      expect(relic.craftData['manualPriceObser'], greaterThan(0));
      expect(relic.craftData['foundBuffChancePercent'], 20);
      expect(InventoryItem.fromJson(relic.toJson()).bonusScudoOculum, 14);
    },
  );
  test(
    'Drop total includes its bonus and guarantees both fairy wing halves at 50',
    () {
      const bonus = 30;
      const total = 20 + bonus;
      expect(total, 50);
      final items = oculumGenerateMonsterLoot(
        monster: monsterById('fata_cacciatrice')!,
        level: 3,
        grade: 1,
        random: Random(0),
        killId: 'fairy-drop-32',
        naturalDropRoll: 20,
        dropTotal: total,
      );
      expect(items, hasLength(2));
      expect(items.map((item) => item.nome), everyElement('Mezza ala di fata'));
      expect(
        items.every((item) => item.monsterLoot['dropTotal'] == total),
        isTrue,
      );
      expect(
        items.every((item) => item.monsterLoot['guaranteedAtDropTotal'] == 50),
        isTrue,
      );
    },
  );
  test('fairy wing halves do not drop below the high Drop threshold', () {
    final items = oculumGenerateMonsterLoot(
      monster: monsterById('fata_cacciatrice')!,
      level: 3,
      grade: 1,
      random: Random(99),
      killId: 'fairy-drop-49',
      naturalDropRoll: 20,
      dropTotal: 49,
    );
    expect(items, isEmpty);
  });
  test('monster relic catalogue contains 500 plus skill-linked equipment', () {
    final items = oculumMonsterEquipmentCatalogue();
    expect(items.length, greaterThanOrEqualTo(500));
    expect(
      items.any(
        (item) => item.craftData['itemFamily'] == 'weapon' && item.arma,
      ),
      isTrue,
    );
    expect(
      items.any(
        (item) => item.craftData['itemFamily'] == 'armor' && item.protegge,
      ),
      isTrue,
    );
    expect(
      items.any(
        (item) => item.craftData['itemFamily'] == 'shield' && item.protegge,
      ),
      isTrue,
    );
    expect(items.every((item) => item.ability != null), isTrue);
    expect(items.every((item) => item.craftData['sourceSkill'] is Map), isTrue);
    expect(items.every((item) => item.puntiStatPerLivello >= 1), isTrue);
    expect(
      items.every((item) => item.craftData['monsterRelicMarketPrice'] is int),
      isTrue,
    );
  });
  test('every imported technique has exactly one home in Skills or Art', () {
    for (final monster in defaultMonsterBookEntries) {
      if (monster.id.startsWith('pawn_guardiano')) continue;
      final skills = oculumMonsterBookSkills(monster);
      final art = oculumMonsterBookImportArt(monster);
      final additionalArts = oculumIsSoulFighter(monster.id)
          ? oculumMonsterBookAdditionalArts(monster)
          : const <CharacterArt>[];
      if (oculumIsSoulFighter(monster.id)) {
        const canonicalNames = <String, String>{
          'soul_fighter_cut': 'Taglio dell’Ultimo Respiro',
          'soul_fighter_guard': 'Mano della Veglia',
          'soul_fighter_skull': 'Marchio dei Senza Nome',
        };
        final authoritativeArts = <CharacterArt>[?art, ...additionalArts];
        final expectedNames = <String>[
          for (final id in monsterBookUsableSkillIds(monster))
            canonicalNames[id]!,
          if (monster.id == oculumSoulFighterEliteId) 'Anymareap',
        ];
        expect(skills, isEmpty, reason: monster.id);
        expect(
          authoritativeArts,
          hasLength(monster.id == oculumSoulFighterEliteId ? 3 : 2),
        );
        expect(
          authoritativeArts
              .expand((entry) => entry.skills)
              .map((skill) => skill.nome),
          unorderedEquals(expectedNames),
          reason: monster.id,
        );
        for (final entry in authoritativeArts) {
          expect(
            CharacterArt.fromJson(
              entry.toJson(),
            ).skills.map((skill) => skill.nome),
            entry.skills.map((skill) => skill.nome),
            reason: monster.id,
          );
        }
      } else {
        expect(
          skills.length + (art?.skills.length ?? 0),
          monsterBookUsableSkillIds(monster).length,
          reason: monster.id,
        );
      }
      if (!oculumMonsterHasOculumArt(monster)) {
        expect(art?.skills ?? <ArtSkill>[], isEmpty, reason: monster.id);
        if (art != null) expect(art.openName, isNotEmpty, reason: monster.id);
      }
      for (final skill in skills) {
        final restored = CharacterSkill.fromJson(skill.toJson());
        for (final form in restored.forme) {
          final resource = form.costoStrutturato!.resource;
          final usesOculum = resource == 'oculum';
          final targetLevelHeal = form.effettiStrutturati.any(
            (effect) =>
                effect.type == 'planar' &&
                effect.target == oculumBunnysHealSkill,
          );
          if (targetLevelHeal) {
            // The target's level imposes this cost after target selection;
            // a numeric picker must not turn it into a manually chosen amount.
            expect(
              skill.nome,
              monsterBookConcreteTechnique(oculumBunnysHealSkill)!.name,
            );
            expect(resource, 'oculum', reason: monster.id);
            expect(form.costo, 'Oculum pari al livello del bersaglio');
            expect(
              form.descrizione,
              contains('Costo Oculum pari al livello del bersaglio.'),
            );
            expect(form.costoStrutturato!.minimum, 0);
            expect(form.costoStrutturato!.maximum, 0);
            expect(form.costoStrutturato!.variable, isFalse);
            expect(form.usaOculumConfigurabile, isFalse);
            final healing = form.effettiStrutturati.singleWhere(
              (effect) => effect.target == oculumBunnysHealSkill,
            );
            expect(healing.valueExpression, '25');
            expect(healing.maximumTargets, 1);
            expect(healing.recipient, 'nemico');
          } else {
            expect(
              form.usaOculumConfigurabile,
              usesOculum,
              reason:
                  '${monster.id} resource $resource; '
                  '${form.descrizione}',
            );
          }
          expect(resource, isNotEmpty);
          if (resource != 'oculum' && monster.id != 'observers_tear') {
            expect(
              form.effettiStrutturati.any(
                (e) => e.valueExpression.contains('oculum_spent'),
              ),
              isFalse,
            );
          }
        }
      }
    }
  });
  test('a Goblin opening and an Orc charge have different tactical costs', () {
    final goblin = oculumMonsterBookSkills(monsterById('goblin_base')!);
    final orc = oculumMonsterBookSkills(monsterById('orco_base')!);
    expect(goblin, hasLength(15));
    expect(orc, hasLength(15));
    expect(
      goblin.first.forme.first.effettiStrutturati.map((e) => e.type),
      contains('modifica_statistica'),
    );
    expect(
      orc.first.forme.first.effettiStrutturati.map((e) => e.type),
      contains('danno_percentuale'),
    );
  });
  test('base Lupo lateral step retains its Volontà cost in the Book Art', () {
    final technique = oculumPlanarTechnique('common_wolf_flank')!;
    expect(technique.costResource, 'volonta');
    final art = oculumMonsterBookArt(monsterById('lupo_base')!);
    final skill = art.skills.singleWhere(
      (candidate) => candidate.nome == 'Passo laterale',
    );
    expect(
      skill.risorsaCostoPerLivello(1),
      'volonta',
      reason:
          'ids ${monsterBookUsableSkillIds(monsterById('lupo_base')!)}; '
          'raw ${skill.risorseCostoPerLivello}; passive ${oculumMonsterBookSkillIsPassive('common_wolf_flank')}; '
          '${skill.evo1}',
    );
    expect(skill.oculumMinimoPerLivello(1), 1);
  });
  test('catalogue never exposes a thematic attack placeholder', () {
    for (final monster in defaultMonsterBookEntries) {
      if (_expectExplicitAuthoredFactoryCatalogue(monster)) continue;
      for (final id in monsterBookUsableSkillIds(monster)) {
        final text = monsterBookSkillText(id);
        expect(
          text,
          isNot(contains('attacco tematico')),
          reason: '${monster.id}/$id',
        );
        expect(
          text,
          isNot(contains('canalizzi il tema')),
          reason: '${monster.id}/$id',
        );
        final concrete = monsterBookConcreteTechnique(id);
        if (concrete == null || concrete.text() != text) continue;
        final art = oculumMonsterBookArt(monster);
        final skill = _catalogueTechniqueForSource(monster, art, id);
        expect(skill.nome, concrete.name, reason: '${monster.id}/$id');
        final passive = oculumMonsterBookSkillIsPassive(id);
        if (passive) {
          expect(skill.risorsaCostoPerLivello(1), 'nessuna');
          continue; // The dedicated passive fixtures verify always-on effects.
        }
        expect(
          skill.oculumMinimiPerLivello.take(3),
          passive ? [0, 0, 0] : concrete.minimums,
          reason:
              '${monster.id}/$id resource ${skill.risorsaCostoPerLivello(1)}',
        );
        // A selectable cost is meaningful only when spending more changes an
        // effect. Fixed techniques now retain their original minimum cost.
        for (var form = 0; form < 3; form++) {
          final scalesWithSpend =
              concrete.forms[form].any(
                (effect) => effect.formula.contains('oculum_spent'),
              ) ||
              skill.effettiPerLivello[form].any(
                (effect) => effect.valueExpression.contains('oculum_spent'),
              );
          expect(
            skill.oculumMassimoPerLivello(form + 1),
            passive
                ? 0
                : scalesWithSpend
                ? concrete.maximums[form]
                : concrete.minimums[form],
            reason: '${monster.id}/${concrete.name} form ${form + 1}',
          );
        }
        expect(
          skill.cooldownPerLivello.take(3).map((timer) => timer.amount),
          concrete.cooldowns,
        );
        for (var form = 0; form < 3; form++) {
          final timer = skill.cooldownPerLivello[form];
          final selfDestruct = concrete.forms[form].any(
            (effect) =>
                effect.type == 'danno' && effect.formula == 'hp_current',
          );
          if (selfDestruct) {
            expect(
              timer.amount,
              0,
              reason: '${monster.id}/$id is consumed on use',
            );
            continue;
          }
          final timerReason = '${monster.id}/$id form ${form + 1}';
          expect(timer.startsReady, concrete.startsReady, reason: timerReason);
          // ConcreteTechnique has no partial opening-delay field. Explicit
          // factory exceptions such as Durafur are checked above instead.
          expect(timer.initialRemaining, isNull, reason: timerReason);
          final openingDelay = concrete.startsReady
              ? 0
              : concrete.cooldowns[form];
          expect(timer.openingDelay, openingDelay, reason: timerReason);
          expect(timer.remaining, openingDelay, reason: timerReason);
          if (timer.amount > 0) {
            expect(
              timer.enterCombat('concrete:$id:$form'),
              isTrue,
              reason: timerReason,
            );
            expect(timer.remaining, openingDelay, reason: timerReason);
          }
          if (openingDelay > 0) {
            expect(
              timer.activate(),
              isFalse,
              reason: '$timerReason starts charging',
            );
            for (var turn = 0; turn < openingDelay; turn++) {
              expect(
                timer.ready,
                isFalse,
                reason: '$timerReason opening turn $turn',
              );
              expect(timer.tick(timer.unit), isTrue, reason: timerReason);
              expect(
                timer.remaining,
                openingDelay - turn - 1,
                reason: timerReason,
              );
            }
          }
          expect(timer.ready, isTrue, reason: '$timerReason opening complete');
          expect(timer.activate(), isTrue, reason: timerReason);
          if (timer.amount == 0) {
            expect(timer.activate(), isTrue, reason: '$id has no cooldown');
            continue;
          }
          expect(
            timer.activate(),
            isFalse,
            reason: '${monster.id}/$id form $form cooldown ${timer.amount}',
          );
          for (var turn = 0; turn < concrete.cooldowns[form]; turn++) {
            timer.tick(timer.unit);
          }
          expect(timer.ready, isTrue);
          if (oculumPlanarTechnique(id) != null) {
            expect(
              skill.effettiPerLivello[form],
              isNotEmpty,
              reason: '$id form $form',
            );
            expect(
              skill.effettiPerLivello[form].every(
                (e) => oculumStructuredEffectTypes.contains(e.type),
              ),
              isTrue,
              reason: id,
            );
            continue; // Planar callbacks add duration/receipt rules beyond the raw damage forms.
          }
          expect(
            skill.effettiPerLivello[form],
            hasLength(concrete.forms[form].length),
          );
          for (var i = 0; i < concrete.forms[form].length; i++) {
            expect(
              skill.effettiPerLivello[form][i].type,
              concrete.forms[form][i].type,
            );
            expect(
              skill.effettiPerLivello[form][i].valueExpression,
              concrete.forms[form][i].formula,
            );
            expect(
              oculumEvaluateStructuredEffectValue(
                skill.effettiPerLivello[form][i],
                variables: const {},
                spentResources: const {'oculum': 4},
              ),
              greaterThan(0),
            );
          }
        }
      }
    }
  });
  test('six demon identities retain stats and have the right passive', () {
    for (final grade in ['minore', 'intermedio', 'maggiore']) {
      final fire = monsterById('demone_$grade')!;
      final frost = monsterById('demone_glaciale_$grade')!;
      expect(fire.skillIds, contains('inferno_in_corpo'));
      expect(frost.skillIds, contains('inverno_in_corpo'));
      expect(frost.skillIds, hasLength(15));
      final passive = oculumMonsterBookArt(frost).skills.first;
      expect(passive.risorsaCostoPerLivello(1), 'nessuna');
      expect(
        passive.effettiPerLivello[0]
            .where((e) => e.type == 'elemental_resistance')
            .map((e) => e.elementType),
        contains('gelo'),
      );
      expect(fire.stats, isNot(equals(frost.stats)));
    }
  });
  test('Rock Slime awards authored skill drops at their actual thresholds', () {
    final slime = monsterById('slime_roccioso')!;
    List<InventoryItem> loot(int natural, int total) =>
        oculumGenerateMonsterLoot(
          monster: slime,
          level: 0,
          grade: 0,
          random: Random(1),
          killId: 'slime-$natural',
          naturalDropRoll: natural,
          dropTotal: total,
        );
    final low = loot(1, 14);
    expect(low.first.nome, 'Roccia Slime');
    expect(low.first.peso, .25);
    expect(
      low.where((item) => item.monsterLoot['learnableMonsterSkill'] == true),
      isEmpty,
    );
    final rare = loot(1, 15);
    expect(rare, hasLength(2));
    expect(rare.last.monsterLoot['learnableMonsterSkill'], isTrue);
    final critical = loot(20, 20);
    expect(critical, hasLength(3));
    expect(
      critical.map((i) => i.nome),
      contains('Tecnica dello Slime — Rimbalzo'),
    );
  });
}

class _AlwaysZeroRandom implements Random {
  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => 0;
}

class _SequenceRandom implements Random {
  _SequenceRandom(this.values);
  final List<int> values;
  int index = 0;

  @override
  bool nextBool() => nextInt(2) == 1;

  @override
  double nextDouble() => nextInt(1000) / 1000;

  @override
  int nextInt(int max) => values[index++ % values.length] % max;
}
