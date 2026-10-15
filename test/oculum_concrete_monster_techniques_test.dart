import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
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
      if (!oculumMonsterHasOculumArt(monster)) expect(art, isNull);
      for (final skill in skills) {
        final restored = CharacterSkill.fromJson(skill.toJson());
        for (final form in restored.forme) {
          expect(form.usaOculumConfigurabile, isFalse, reason: monster.id);
          expect(form.costoStrutturato!.resource, isNot('oculum'));
          expect(
            form.effettiStrutturati.any(
              (e) => e.valueExpression.contains('oculum_spent'),
            ),
            isFalse,
          );
        }
      }
    }
  });
  test('a Goblin opening and an Orc charge have different tactical costs', () {
    final goblin = oculumMonsterBookSkills(monsterById('goblin_base')!);
    final orc = oculumMonsterBookSkills(monsterById('orco_base')!);
    expect(goblin, hasLength(3));
    expect(orc, hasLength(3));
    expect(
      goblin.first.forme.first.effettiStrutturati.map((e) => e.type),
      contains('modifica_statistica'),
    );
    expect(
      orc.first.forme.first.effettiStrutturati.map((e) => e.type),
      contains('danno_percentuale'),
    );
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
        expect(skill.oculumMinimiPerLivello.take(3), concrete.minimums);
        expect(skill.oculumMassimiPerLivello.take(3), concrete.maximums);
        expect(
          skill.cooldownPerLivello.take(3).map((timer) => timer.amount),
          concrete.cooldowns,
        );
        for (var form = 0; form < 3; form++) {
          final timer = skill.cooldownPerLivello[form];
          expect(timer.activate(), isTrue);
          expect(timer.activate(), isFalse);
          for (var turn = 0; turn < concrete.cooldowns[form]; turn++) {
            timer.tick('turni');
          }
          expect(timer.ready, isTrue);
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
      expect(frost.skillIds, hasLength(3));
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
    expect(low, hasLength(1));
    expect(low.single.nome, 'Roccia Slime');
    expect(low.single.peso, .25);
    final rare = loot(15, 15);
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
