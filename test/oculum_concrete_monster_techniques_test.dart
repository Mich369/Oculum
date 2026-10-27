import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
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
          dropTotal: 25 + grade * 2,
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
      final items = oculumGenerateMonsterLoot(
        monster: monsterById('slime_blu')!,
        level: 4,
        grade: 1,
        random: Random(10),
        killId: 'slime-blue-test',
        naturalDropRoll: 20,
        dropTotal: 32,
      );
      final relic = items.singleWhere(
        (item) => item.nome == 'Elmetto-scudo di melma blu',
      );
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
      expect(
        skills.length + (art?.skills.length ?? 0),
        monsterBookUsableSkillIds(monster).length,
        reason: monster.id,
      );
      if (!oculumMonsterHasOculumArt(monster)) {
        expect(art?.skills ?? <ArtSkill>[], isEmpty, reason: monster.id);
        if (art != null) expect(art.openName, isNotEmpty, reason: monster.id);
      }
      for (final skill in skills) {
        final restored = CharacterSkill.fromJson(skill.toJson());
        for (final form in restored.forme) {
          final resource = form.costoStrutturato!.resource;
          final usesOculum = resource == 'oculum';
          expect(
            form.usaOculumConfigurabile,
            usesOculum,
            reason:
                '${monster.id} resource $resource; '
                '${form.descrizione}',
          );
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
        final matches = art.skills
            .where((skill) => skill.nome == concrete.name)
            .toList();
        expect(
          matches,
          hasLength(1),
          reason: '${monster.id}: $id duplicates ${concrete.name}',
        );
        final skill = matches.single;
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
          expect(timer.activate(), isTrue);
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
