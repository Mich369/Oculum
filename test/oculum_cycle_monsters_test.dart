import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_monster_picker.dart';

void main() {
  test(
    'cycle scroll drops keep real authored skill data and custom thresholds',
    () {
      for (final monster in oculumCycleMonsterEntries) {
        List<InventoryItem> loot(
          int natural, {
          MonsterBookEntry? custom,
          int bonus = 0,
        }) => oculumGenerateMonsterLoot(
          monster: custom ?? monster,
          level: monster.stats['level']!,
          grade: 0,
          random: Random(7),
          killId: 'cycle:${monster.id}:$natural',
          naturalDropRoll: natural,
          dropTotal: natural + bonus,
        );
        final low = loot(17);
        expect(low.where((i) => i.craftData['scroll'] != null), isEmpty);
        final scrolls = loot(
          20,
        ).where((i) => i.craftData['scroll'] != null).toList();
        expect(scrolls, hasLength(2), reason: monster.id);
        for (final natural in [18, 19, 20]) {
          for (final bonus in [0, 100]) {
            final selected = loot(
              natural,
              bonus: bonus,
            ).where((item) => item.craftData['scroll'] != null).toList();
            expect(
              selected,
              hasLength(natural == 20 ? 2 : 1),
              reason: '${monster.id}/$natural/+$bonus',
            );
            expect(
              selected.map((item) => item.monsterLoot['sourceSkillId']).toSet(),
              hasLength(selected.length),
            );
          }
        }
        for (final item in scrolls) {
          final scroll = item.craftData['scroll'] as Map;
          expect(scroll['authoredSkill'], isA<Map>());
          expect(scroll['effects'], isNotEmpty);
          expect(item.monsterLoot['sourceSkillId'], isIn(monster.skillIds));
          expect(
            InventoryItem.fromJson(item.toJson()).craftData['scroll'],
            scroll,
          );
        }
        final custom = monster.copyWith(
          encounterRules: {
            ...monster.encounterRules,
            'cycleScrollNaturalMinimum': 20,
          },
        );
        expect(
          loot(18, custom: custom).where((i) => i.craftData['scroll'] != null),
          isEmpty,
        );
        expect(
          loot(
            18,
            custom: custom,
            bonus: 100,
          ).where((i) => i.craftData['scroll'] != null),
          isEmpty,
        );
      }
    },
  );
  test('all twelve calendar phases have two unique imported species', () {
    expect(oculumCycleMonsterPhaseNames.length, 12);
    expect(oculumCycleMonsterEntries.length, 24);
    final skills = <String>{};
    final materials = <String>{};
    for (final phase in oculumCycleMonsterPhaseNames.keys) {
      expect(
        oculumCycleMonsterEntries.where(
          (m) => oculumMonsterCyclePhase(m) == phase,
        ),
        hasLength(2),
        reason: phase,
      );
    }
    for (final monster in oculumCycleMonsterEntries) {
      expect(
        defaultMonsterBookEntries.where((m) => m.id == monster.id),
        hasLength(1),
      );
      expect(
        defaultMonsterBookEntries.where((m) => m.nameIt == monster.nameIt),
        hasLength(1),
      );
      expect(monster.weakPointDescriptionIt, isNotEmpty);
      expect(monster.planeIds, isNotEmpty);
      expect(monster.spriteAssetPath, isEmpty);
      expect(monster.dropIds, hasLength(1));
      materials.addAll(monster.dropIds);
      skills.addAll(monster.skillIds);
      final restored = MonsterBookEntry.fromJson(monster.toJson());
      expect(
        oculumMonsterCyclePhase(restored),
        oculumMonsterCyclePhase(monster),
      );
      expect(restored.dropIds, monster.dropIds);
    }
    expect(materials, hasLength(24));
    expect(skills, hasLength(48));
  });

  test(
    'imported skill forms retain executable effects, costs and level gates',
    () {
      for (final monster in oculumCycleMonsterEntries) {
        final art = oculumMonsterBookArt(monster);
        expect(art.skills, hasLength(2), reason: monster.id);
        expect(art.openName, monster.encounterRules['cycleOpenName']);
        expect(
          art.openBuffEffects.any((e) => e.target == 'monster_open_power'),
          isTrue,
        );
        expect(
          art.openSkillEffects.single.valueExpression,
          contains('monster_open_bonus'),
        );
        expect(art.openSkillCooldown!.amount, 4);
        for (var index = 0; index < 2; index++) {
          final technique = oculumPlanarTechnique(monster.skillIds[index])!;
          final skill = art.skills[index];
          for (var form = 1; form <= 3; form++) {
            expect(
              skill.effettiEvoluzione(form),
              isNotEmpty,
              reason: '${monster.id}/$form',
            );
            expect(skill.risorsaCostoPerLivello(form), 'oculum');
            expect(skill.oculumMinimoPerLivello(form), form);
            expect(skill.oculumMassimoPerLivello(form), form);
            expect(skill.cooldownPerLivello[form - 1].amount, greaterThan(0));
            expect(
              technique.text(),
              contains(
                'Richiede livello ${monster.stats['level']! + (form - 1) * 3}',
              ),
            );
          }
        }
        final restored = CharacterArt.fromJson(art.toJson());
        expect(
          restored.openSkillEffects.single.valueExpression,
          art.openSkillEffects.single.valueExpression,
        );
        restored.skills.first.impostaLimitiOculumPerLivello(
          1,
          minimo: 7,
          massimo: 7,
        );
        expect(
          CharacterArt.fromJson(
            restored.toJson(),
          ).skills.first.oculumMinimoPerLivello(1),
          7,
        );
        expect(
          oculumMonsterBookArt(monster).skills.first.oculumMinimoPerLivello(1),
          1,
        );
      }
    },
  );

  test(
    'Safe Monster species stay peaceful and have no offensive skill or Open',
    () {
      for (final monster in oculumCycleMonsterEntries.where(
        (m) => oculumMonsterCyclePhase(m) == 'safe_monster',
      )) {
        expect(monster.encounterRules['dispositions'], contains('pacifico'));
        final art = oculumMonsterBookArt(monster);
        expect(
          art.skills
              .expand((s) => s.effettiPerLivello)
              .expand((effects) => effects)
              .any((e) => e.type == 'danno'),
          isFalse,
        );
        expect(art.openSkillEffects.single.type, 'cura');
        expect(art.openSkillEffects.single.recipient, 'alleato');
      }
    },
  );

  testWidgets(
    'phase filtering works on phone without changing a cancelled choice',
    (tester) async {
      tester.view.physicalSize = const Size(390, 680);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var selected = oculumCycleMonsterEntries.first.id;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OculumMonsterPicker(
              entries: oculumCycleMonsterEntries,
              selectedId: selected,
              onSelected: (id) => selected = id,
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('tutorial_monster_picker')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('monster_cycle_phase_filter')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('The Moon').last);
      await tester.pumpAndSettle();
      expect(find.text('Cerbiatto dei Voti Lunari'), findsOneWidget);
      expect(find.text('Gufo delle Stelle Alleate'), findsOneWidget);
      expect(find.text('Falena del Delirio'), findsNothing);
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();
      expect(selected, oculumCycleMonsterEntries.first.id);
      expect(tester.takeException(), isNull);
    },
  );
}
