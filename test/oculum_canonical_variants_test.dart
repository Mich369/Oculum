import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  test(
    'new base roster is complete and the Monster Book has no duplicate IDs',
    () {
      resetMonsterBookEntries();
      final entries = defaultMonsterBookEntries;
      final ids = entries.map((entry) => entry.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      final baseCreatures = entries
          .where((entry) => entry.id.startsWith('base_'))
          .toList();
      expect(baseCreatures, hasLength(80));
      for (final creature in baseCreatures) {
        expect(creature.nameIt, isNotEmpty);
        expect(creature.dropIds, hasLength(1), reason: creature.id);
        expect(creature.skillIds, hasLength(14), reason: creature.id);
        expect(creature.stats['resilienza'] ?? 0, inInclusiveRange(1, 6));
        expect(creature.stats['volonta'] ?? 0, inInclusiveRange(1, 3));
        expect(creature.stats['materia'] ?? 0, inInclusiveRange(2, 6));
        expect(creature.stats['oculum'] ?? 0, inInclusiveRange(0, 2));
        final skills = oculumMonsterBookSkills(creature);
        expect(skills, hasLength(14), reason: creature.id);
        // Preserve the original pair's exact rules; the twelve added growth
        // techniques have their own costs and catalogue-wide validation.
        for (final skill in skills.take(2)) {
          for (final form in skill.forme) {
            expect(form.costoStrutturato, isNotNull);
            expect(form.costoStrutturato!.isValid(), isTrue);
            expect(
              form.costoStrutturato!.resource,
              anyOf('volonta', 'materia'),
            );
            expect(form.cooldownStrutturato!.amount, greaterThan(0));
          }
        }
      }
    },
  );

  testWidgets(
    'Thunder Bot blasts more than 100 opponents offline and dies only after dispatch',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      probe.saveSheet();
      state.modalitaMaster = true;
      state.schedePersonaggio[0]['monsterBookSourceId'] = 'thunder_bot';
      state.currentHpController.text = '12';
      state.oculumController.text = '100';
      final tag = probe.currentTag();
      probe.saveSheet();
      expect(probe.defense(), 0);
      expect(probe.coreStats()['oculum'], 0);
      state.masterInitiativeTokens.clear();
      state.masterInitiativeTokens.add({
        'id': 'BOT',
        'sheetTag': tag,
        'name': 'Thunder Bot',
        'side': 'enemy',
        'status': 'ready',
        'type': 'Mostro',
        'actionUsed': false,
      });
      for (var i = 0; i < 101; i++) {
        state.masterInitiativeTokens.add(<String, dynamic>{
          'id': 'TARGET_$i',
          'sheetTag': 'TARGET_$i',
          'name': 'Bersaglio $i',
          'side': 'party',
          'status': 'ready',
          'type': 'Personaggio',
        });
      }
      await probe.planAttack(total: 30, natural: 15);
      final requests = (state.onlineCombatRequests as Map).values
          .whereType<Map>()
          .where((r) => r['sourceTag'] == tag)
          .toList();
      expect(requests, hasLength(101));
      expect(
        requests.every(
          (r) =>
              r['damage'] == requests.first['damage'] &&
              r['element'] == 'fulmine',
        ),
        isTrue,
      );
      expect(probe.currentHp(), 0);
      probe.cancelPendingSave();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );
  const ids = [
    'lupo_delle_nevi',
    'lupo_ombra_oblio',
    'lupo_runico_postea',
    'goblin_assassino',
    'goblin_arciere',
    'lupo_base',
    'coboldo_minatore',
    'coboldo_runico_postea',
    'gnoll_delle_nevi',
    'gnoll_diabolico',
    'goblin_incendiario',
    'segugio_runico_sentinella',
    'ragno_saldatore_recuperatore',
    'marshmallow',
    'marshmallow_incenerito',
  ];
  test(
    'canonical variants have distinct roles, skills and preserved identities',
    () {
      resetMonsterBookEntries();
      final skillIds = <String>{};
      for (final id in ids) {
        final monster = monsterById(id)!;
        expect(monster.descIt.length, greaterThan(150));
        expect(monster.weakPointIt, isNotEmpty);
        expect(monster.encounterRules['authoredCanonical'], isTrue);
        expect(
          defaultMonsterBookEntries.where(
            (m) => m.id.startsWith('${id}_variante_'),
          ),
          isEmpty,
        );
        final parent = monster.encounterRules['canonicalVariantOf'];
        if (parent != null) {
          expect(monsterById('$parent'), isNotNull, reason: '$id -> $parent');
        }
        final restored = MonsterBookEntry.fromJson(monster.toJson());
        expect(restored.encounterRules, monster.encounterRules);
        expect(monster.skillIds, hasLength(14));
        expect(monster.dropIds, isNotEmpty);
        final skills = oculumMonsterBookArt(monster).skills;
        expect(skills, hasLength(14));
        for (final skill in skills) {
          expect(skill.effettiPerLivello, hasLength(5));
          for (var form = 0; form < 3; form++) {
            expect(skill.effettiPerLivello[form], isNotEmpty);
          }
        }
        if (const {
          'lupo_base',
          'coboldo_minatore',
          'coboldo_runico_postea',
          'gnoll_delle_nevi',
          'gnoll_diabolico',
          'goblin_incendiario',
        }.contains(id)) {
          final naturalSkills = oculumMonsterBookSkills(monster);
          expect(naturalSkills, hasLength(14), reason: id);
          for (final skill in naturalSkills.take(2)) {
            for (final form in skill.forme) {
              expect(
                form.costoStrutturato!.resource,
                anyOf('volonta', 'materia'),
                reason: '$id: ${skill.nome}, forma ${form.nome}',
              );
              expect(
                int.parse(form.costoStrutturato!.amountExpression),
                greaterThan(0),
              );
              expect(form.cooldownStrutturato!.amount, greaterThan(0));
            }
          }
        }
        for (final key in monster.skillIds) {
          expect(skillIds.add(key), isTrue);
        }
      }
      expect(monsterById('goblin_arciere')!.planeIds, contains('mezzano'));
      expect(monsterById('kobold_base')!.nameIt, 'Coboldo');
      expect(monsterById('lupo_base')!.nameIt, 'Lupo');
      expect(monsterById('gnoll_base')!.nameIt, 'Gnoll');
      expect(monsterById('goblin_base')!.nameIt, 'Goblin');
      expect(
        monsterById('gnoll_delle_nevi')!.encounterRules['canonicalVariantOf'],
        'gnoll_base',
      );
      expect(
        monsterById('gnoll_diabolico')!.encounterRules['canonicalVariantOf'],
        'gnoll_base',
      );
      expect(
        monsterById('coboldo_minatore')!.encounterRules['canonicalVariantOf'],
        'kobold_base',
      );
      expect(monsterById('segugio_runico_sentinella')!.planeIds, ['postea']);
      expect(monsterById('marshmallow_incenerito')!.planeIds, ['caramella']);
      expect(
        oculumPlanarTechnique('canonical_charred_shards')!.forms[1].last.target,
        'bruciatura',
      );
    },
  );
  test(
    'Thunder Bot retains its free suicide skill beside the twelve new techniques',
    () {
      final bot = monsterById('thunder_bot')!;
      expect(bot.stats['oculum'], 0);
      expect(bot.skillIds.first, 'thunder_bot_explosion');
      expect(bot.skillIds, hasLength(13));
      expect(oculumMonsterBookImportArt(bot), isNull);
      final skills = oculumMonsterBookSkills(bot);
      expect(skills, hasLength(13));
      for (final form in skills.first.forme) {
        expect(form.costoStrutturato!.resource, 'nessuna');
        final effect = form.effettiStrutturati.single;
        expect(effect.killSource, isTrue);
        expect(effect.allOpponents, isTrue);
        expect(effect.damagePerTarget, isTrue);
        expect(effect.valueExpression, contains('hp_current'));
        expect(effect.elementType, 'fulmine');
        expect(effect.maximumTargets, greaterThanOrEqualTo(100));
      }
      expect(oculumThunderBotExplosionDamage(12, 7), 19);
      expect(oculumThunderBotExplosionDamage(1, 7), 8);
      expect(oculumThunderBotExplosionDamage(-3, 7), 7);
    },
  );
  test(
    'wolf variants form one unlockable species family with distinct drops',
    () {
      resetMonsterBookEntries();
      final snow = monsterById('lupo_delle_nevi')!;
      final infernal = monsterById('lupo_infernale_del_ghiaccio')!;
      final shadow = monsterById('lupo_ombra_oblio')!;
      final runic = monsterById('lupo_runico_postea')!;
      expect(infernal.encounterRules['canonicalVariantOf'], 'lupo_delle_nevi');
      expect(shadow.planeIds, ['oblio', 'shadow_hell']);
      expect(runic.planeIds, ['postea']);
      for (final variant in [snow, infernal, shadow, runic]) {
        expect(oculumPartyHuntSpeciesId(variant.id), 'lupo_delle_nevi');
        expect(variant.skillIds, hasLength(14));
        for (final id in variant.skillIds.take(2)) {
          final technique = oculumPlanarTechnique(id)!;
          expect(technique.requiredLevel, greaterThan(0));
          expect(
            technique.text(),
            anyOf(contains('Volontà'), contains('Oculum')),
          );
          expect(technique.text(), contains('CD'));
        }
      }
      expect(
        infernal.skillIds.toSet().intersection(snow.skillIds.toSet()),
        isEmpty,
      );
      expect(
        shadow.skillIds.toSet().intersection(snow.skillIds.toSet()),
        isEmpty,
      );
      expect(
        runic.skillIds.toSet().intersection(snow.skillIds.toSet()),
        isEmpty,
      );

      final rewards = <InventoryItem>[];
      for (final variant in [snow, infernal, shadow, runic]) {
        rewards.addAll(
          oculumGenerateMonsterLoot(
            monster: variant,
            level: variant.stats['level'] ?? 0,
            grade: 0,
            random: Random(17),
            killId: 'wolf:${variant.id}',
            naturalDropRoll: 20,
            dropTotal: 50,
          ),
        );
      }
      expect(rewards.where((i) => i.craftData['scroll'] is Map), hasLength(56));
      final equipment = rewards.where(
        (i) => i.craftData['wolfFamily'] == 'lupo_delle_nevi',
      );
      expect(equipment, hasLength(4));
      for (final item in equipment) {
        expect(item.arma, isTrue);
        expect(item.ability, isNotNull);
        expect(item.craftData['skillLevelRequired'], greaterThan(0));
        expect(item.monsterLoot['rareMonsterEquipment'], isTrue);
      }
    },
  );
}
