import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;

List<MonsterBookEntry> addedMonsters() => [
  ...oculumCycleMonsterEntries,
  monsterBookEntryById('gigante_comune')!,
  monsterBookEntryById('gigante_scheletro')!,
];

void main() {
  test(
    'every added species has weapons, armor and shields with original executable skill forms',
    () {
      final rows = <Map<String, dynamic>>[];
      final techniqueIds = <String>{};
      var totalItems = 0;
      var totalForms = 0;
      final effectTypes = <String>{};
      for (final monster in addedMonsters()) {
        final art = oculumMonsterBookArt(monster);
        final items = oculumMonsterEquipmentCatalogue(source: monster);
        expect(items, isNotEmpty, reason: monster.id);
        expect(
          items.map((i) => i.monsterLoot['id']).toSet(),
          hasLength(items.length),
        );
        final counts = <String, int>{};
        for (final kind in ['weapon', 'armor', 'shield']) {
          counts[kind] = items
              .where((i) => i.craftData['itemFamily'] == kind)
              .length;
          expect(counts[kind], greaterThan(0), reason: '${monster.id}/$kind');
        }
        for (final item in items) {
          final source = ArtSkill.fromJson(
            Map<String, dynamic>.from(item.craftData['sourceSkill'] as Map),
          );
          final restored = InventoryItem.fromJson(
            jsonDecode(jsonEncode(item.toJson())),
          );
          expect(restored.ability, isNotNull, reason: item.nome);
          expect(restored.ability!.forme, hasLength(3), reason: item.nome);
          expect(restored.monsterLoot['monsterId'], monster.id);
          for (var form = 1; form <= 3; form++) {
            final derived = restored.ability!.forme[form - 1];
            expect(
              derived.effettiStrutturati.map((e) => e.toJson()).toList(),
              source.effettiEvoluzione(form).map((e) => e.toJson()).toList(),
              reason: '${item.nome}/$form',
            );
            expect(
              derived.costoStrutturato?.minimum,
              source.oculumMinimoPerLivello(form),
            );
            expect(
              derived.costoStrutturato?.maximum,
              source.oculumMassimoPerLivello(form),
            );
            expect(
              derived.cooldownStrutturato!.toJson(),
              source.cooldownPerLivello[form - 1].toJson(),
            );
          }
          if (item.arma) expect(item.bonusDanno, greaterThan(0));
          if (item.protegge) expect(item.bonusDifesa, greaterThan(0));
          if (item.craftData['itemFamily'] == 'shield') {
            expect(item.bonusScudo, greaterThan(0));
          }
        }
        final skills = <Map<String, dynamic>>[];
        for (var index = 0; index < monster.skillIds.length; index++) {
          final id = monster.skillIds[index];
          techniqueIds.add(id);
          final skill = art.skills[index];
          final forms = <Map<String, dynamic>>[];
          for (var form = 1; form <= 3; form++) {
            final effects = skill.effettiEvoluzione(form);
            if (const {
              'cycle_bear_spines',
              'cycle_lunar_stomp',
              'cycle_lunar_bite',
              'skeleton_giant_throw',
            }.contains(id)) {
              expect(
                oculumCombatAbilityRoles(effects),
                contains(OculumCombatAbilityRole.attack),
                reason: id,
              );
              expect(
                oculumCombatAbilityRole(effects),
                OculumCombatAbilityRole.attack,
                reason: id,
              );
            }
            expect(effects, isNotEmpty, reason: '$id/$form');
            effectTypes.addAll(effects.map((e) => '${e.type}:${e.target}'));
            forms.add({
              'form': form,
              'cost': skill.oculumMinimoPerLivello(form),
              'cooldown': skill.cooldownPerLivello[form - 1].amount,
              'effects': effects.map((e) => e.toJson()).toList(),
            });
            totalForms++;
          }
          skills.add({'id': id, 'name': skill.nome, 'forms': forms});
        }
        expect(art.openSkillEffects, isNotEmpty, reason: monster.id);
        expect(
          art.openSkillCooldown!.amount,
          greaterThan(0),
          reason: monster.id,
        );
        totalItems += items.length;
        rows.add({
          'id': monster.id,
          'name': monster.nameIt,
          'materials': monster.dropIds,
          'derivedEquipment': counts,
          'skills': skills,
          'open': art.openName,
        });
      }
      expect(rows, hasLength(37));
      expect(techniqueIds, hasLength(77));
      final addedIds = addedMonsters().map((m) => m.id).toSet();
      final includingVariants = defaultMonsterBookEntries
          .where(
            (m) =>
                addedIds.contains(m.id) ||
                addedIds.contains(m.encounterRules['canonicalVariantOf']) ||
                addedIds.any((id) => m.id.startsWith('${id}_variante_')),
          )
          .toList();
      final report = {
        'baseline': 'b917217d98d16861a5bbaf1706d78825d883c970',
        'allBookEntriesIncludingVariants': defaultMonsterBookEntries.length,
        'addedEntriesIncludingVariants': includingVariants.length,
        'species': rows.length,
        'techniques': techniqueIds.length,
        'forms': totalForms,
        'derivedItems': totalItems,
        'effectTargets': effectTypes.toList()..sort(),
        'monsters': rows,
      };
      File(
        'build/added-monsters-completeness.json',
      ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
      // ignore: avoid_print
      print(
        'ADDED_MONSTERS_AUDIT book=${defaultMonsterBookEntries.length} addedIncludingVariants=${includingVariants.length} species=${rows.length} techniques=${techniqueIds.length} forms=$totalForms derivedItems=$totalItems effects=${effectTypes.toList()..sort()}',
      );
    },
  );

  testWidgets(
    'saved Lunar Bite without a planar marker keeps customized damage and enables adaptation',
    (tester) async {
      final (_, p) = await fixtures.mountFight(tester);
      final skill = oculumMonsterBookArt(
        monsterBookEntryById('ciclo_lupo_lunare')!,
      ).skills.last;
      final effect = OculumStructuredEffect.fromJson(
        skill.effettiEvoluzione(1).first.toJson(),
      )..valueExpression = '97';
      p.applyEffects([effect]);
      expect(p.planarStateSnapshot()['cycleLunarBite'], true);
      expect(
        p
            .structuredEffects()
            .where((e) => e['effectId'] == effect.id)
            .single['value'],
        97,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'all 231 added skill forms execute through the application effect runtime',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final base = p.snapshot();
      final results = <Map<String, dynamic>>[];
      for (final monster in addedMonsters()) {
        final art = oculumMonsterBookArt(monster);
        for (var skillIndex = 0; skillIndex < art.skills.length; skillIndex++) {
          for (var form = 1; form <= 3; form++) {
            final json = Map<String, dynamic>.from(
              jsonDecode(jsonEncode(base)) as Map,
            );
            json['planarRuntime'] = <String, dynamic>{};
            json['activeStructuredEffects'] = <dynamic>[];
            json['monsterBookSourceId'] = monster.id;
            json['currentHp'] = 1;
            p.load(json);
            p.chooseChaos(false);
            p.cycleDay(190);
            final skill = art.skills[skillIndex];
            final effects = skill.effettiEvoluzione(form);
            final messages = p.applyEffects(
              effects,
              source: '${monster.nameIt}/${skill.nome}/$form',
            );
            expect(
              messages,
              isNotEmpty,
              reason: '${monster.id}/${skill.nome}/$form',
            );
            expect(
              messages.any((m) => m.toLowerCase().contains('non supportat')),
              false,
            );
            if (effects.any((e) => e.recipient == 'alleato')) {
              await p.deliverSupport([p.ownerTag()]);
            }
            for (final effect in effects) {
              final context =
                  '${monster.id}/${skill.nome}/$form/${effect.type}';
              if (const {
                'danno',
                'difesa',
                'modifica_sottotratto',
                'costrutto',
              }.contains(effect.type)) {
                expect(
                  p.structuredEffects().any(
                    (e) =>
                        e['effectId'] == effect.id &&
                        e['type'] != 'pending_target',
                  ),
                  true,
                  reason: context,
                );
              } else if (effect.type == 'scudo') {
                expect(
                  int.tryParse(state.scudoController.text),
                  greaterThan(0),
                  reason: context,
                );
              } else if (effect.type == 'cura') {
                expect(p.currentHp(), greaterThan(1), reason: context);
              } else if (effect.type == 'planar') {
                final runtime = p.planarStateSnapshot();
                switch (effect.target) {
                  case 'cycle_bear_spines':
                    expect(
                      runtime['cycleSpines'],
                      inInclusiveRange(3, 10),
                      reason: context,
                    );
                    break;
                  case 'cycle_lunar_stomp':
                    expect(runtime['cycleLunarStomp'], 6, reason: context);
                    break;
                  case 'skeleton_giant_throw':
                    expect(
                      runtime['cycleSkeletonThrow'],
                      true,
                      reason: context,
                    );
                    break;
                  case 'cycle_fate_gift':
                    expect(
                      runtime['cycleFateGiftBonus'],
                      inInclusiveRange(1, 2),
                      reason: context,
                    );
                    break;
                }
              }
              if (monster.skillIds[skillIndex] == 'cycle_lunar_bite') {
                expect(
                  p.planarStateSnapshot()['cycleLunarBite'],
                  true,
                  reason: context,
                );
              }
            }
            final evaluated = <Map<String, dynamic>>[];
            for (final effect in effects) {
              final roll = oculumResolveStructuredEffectRoll(
                effect,
                variables: p.formulaContext(),
                subtraits: state.hiddenEyeStats,
                spentResources: const {},
                level: 10,
                grade: 1,
              );
              evaluated.add({
                'type': effect.type,
                'target': effect.target,
                'value': roll.value,
                'duration': roll.baseDuration + roll.durationBonus,
              });
            }
            results.add({
              'monster': monster.id,
              'skill': monster.skillIds[skillIndex],
              'form': form,
              'evaluated': evaluated,
              'runtimeMessages': messages,
            });
            expect(
              tester.takeException(),
              isNull,
              reason: '${monster.id}/${skill.nome}/$form',
            );
          }
        }
      }
      expect(results, hasLength(231));
      File(
        'build/added-monster-skill-runtime.json',
      ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(results));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
