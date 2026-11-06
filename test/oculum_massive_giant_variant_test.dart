import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/oculum_opposed_attack.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_attack_planner.dart';

import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  tearDown(resetMonsterBookEntries);

  test('massive giant is additive, sturdier and keeps common giant anatomy', () {
    final base = monsterById('gigante_comune')!;
    final variant = monsterById(oculumMassiveGiantMonsterId)!;
    expect(base.stats, containsPair('level', 4));
    expect(base.stats['resilienza'], 11);
    expect(base.stats['volonta'], 9);
    expect(base.stats['materia'], 8);
    expect(base.stats['oculum'], 5);
    expect(variant.stats['level'], 6);
    expect(variant.stats['resilienza'], 18);
    expect(variant.stats['volonta'], 10);
    expect(variant.stats['materia'], 10);
    expect(variant.stats['oculum'], 5);
    expect(variant.encounterRules['canonicalVariantOf'], base.id);
    expect(
      defaultMonsterBookEntries.where((m) => m.id == variant.id),
      hasLength(1),
    );
    expect(
      defaultMonsterBookEntries.where(
        (m) => m.id.startsWith('${variant.id}_variante_'),
      ),
      isEmpty,
    );
    final anatomy = oculumMonsterPrecisionAnatomy(variant);
    expect(anatomy.where((p) => p['group'] == 'arms'), hasLength(2));
    expect(anatomy.where((p) => p['group'] == 'legs'), hasLength(2));
    expect(variant.weakPointIt, base.weakPointIt);
    expect(
      variant.incomingDamageResistancePresets,
      base.incomingDamageResistancePresets,
    );
    expect(oculumPartyHuntSpeciesId(variant.id), base.id);
    expect(oculumIsCommonGiantFamily(variant.id), isTrue);
    expect(oculumIsCommonGiantFamily('gigante_scheletro'), isFalse);
    expect(oculumIsCommonGiantFamily('gigante_sabbia'), isFalse);

    final generated = <String, Map<String, int>>{};
    final hp = <String, int>{};
    for (final entry in [base, variant]) {
      final level = entry.stats['level']!;
      final stats = oculumMonsterCreationStats(entry, level);
      generated[entry.id] = stats;
      hp[entry.id] =
          stats['resilienza']! *
          oculumHpMultiplierForGrade(oculumGradeForLevel(level), level: level);
      expect(
        stats.values.fold<int>(0, (sum, value) => sum + value),
        [
              'resilienza',
              'volonta',
              'materia',
              'oculum',
            ].fold<int>(0, (sum, key) => sum + entry.stats[key]!) +
            oculumGeneratedMonsterBudget(entry.presetType, level),
      );
    }
    expect(
      generated[variant.id]!['resilienza'],
      greaterThan(generated[base.id]!['resilienza']!),
    );
    expect(hp[variant.id], greaterThan(hp[base.id]!));
    expect(
      oculumMonsterBookPower(variant),
      greaterThan(oculumMonsterBookPower(base)),
    );
    // Measured through the current generator, not confused with catalogue bases.
    debugPrint(
      'GIANT_BALANCE ${jsonEncode({
        'stats': generated,
        'hp': hp,
        'cataloguePower': {base.id: oculumMonsterBookPower(base), variant.id: oculumMonsterBookPower(variant)},
      })}',
    );
  });

  test('variant overrides and edited abilities survive JSON independently', () {
    final base = monsterById('gigante_comune')!;
    final variant = monsterById(oculumMassiveGiantMonsterId)!;
    final baseJson = jsonEncode(base.toJson());
    final edited = variant.copyWith(
      nameIt: 'Gigante personale',
      stats: {...variant.stats, 'resilienza': 27, 'level': 8},
      weakPointIt: 'Punto debole personalizzato',
      damageResistancePresets: {'taglio': 'resistenza'},
      skillIds: [variant.skillIds.first],
    );
    final restored = MonsterBookEntry.fromJson(
      jsonDecode(jsonEncode(edited.toJson())) as Map<String, dynamic>,
    );
    configureMonsterBookEntries(customEntries: [restored]);
    expect(monsterById(variant.id)!.toJson(), restored.toJson());
    expect(monsterById('gigante_comune')!.toJson(), base.toJson());
    expect(jsonEncode(base.toJson()), baseJson);

    final art = oculumMonsterBookArt(variant);
    final custom = CharacterArt.fromJson(
      jsonDecode(jsonEncode(art.toJson())) as Map<String, dynamic>,
    );
    custom.skills.first.effettiPerLivello.first.first.valueExpression = '37';
    final roundTrip = CharacterArt.fromJson(custom.toJson());
    expect(
      roundTrip.skills.first.effettiPerLivello.first.first.valueExpression,
      '37',
    );
    expect(
      oculumMonsterBookArt(
        base,
      ).skills.first.effettiPerLivello.first.first.valueExpression,
      isNot('37'),
    );
  });

  test(
    'massive giant has ordinary skill and Open pools with saved choices',
    () {
      final variant = monsterById(oculumMassiveGiantMonsterId)!;
      final art = oculumMonsterBookArt(variant);
      expect(art.skills.length, greaterThanOrEqualTo(9));
      expect(
        oculumMonsterBookOpenPool(variant).length,
        greaterThanOrEqualTo(2),
      );
      expect(
        variant.skillIds,
        containsAll(['giant_sweeping_club', 'giant_heavy_guard']),
      );
      for (var seed = 0; seed < 4; seed++) {
        final loadout = oculumMonsterBookLoadout(
          variant,
          random: Random(seed),
          level: variant.stats['level'],
        );
        final chosen = [
          for (final skill in loadout.skills)
            if (!skill.passiva) skill.nome,
          for (final skill in loadout.art?.skills ?? const <ArtSkill>[])
            if (!skill.tipoPerLivello(1).toLowerCase().contains('passiv'))
              skill.nome,
        ];
        expect(chosen.toSet(), hasLength(3));
        expect(loadout.art!.openName, art.openName);
        final restored = CharacterArt.fromJson(loadout.art!.toJson());
        expect(restored.openName, loadout.art!.openName);
        expect(
          restored.skills.map((s) => s.nome),
          loadout.art!.skills.map((s) => s.nome),
        );
      }
    },
  );

  for (final species in ['gigante_comune', oculumMassiveGiantMonsterId]) {
    for (final targetCount in [1, 3]) {
      testWidgets('$species keeps full per-target bonus against $targetCount', (
        tester,
      ) async {
        final (state, p) = await fixtures.mountFight(tester);
        state.schedePersonaggio[state.schedaCorrente]['monsterBookSourceId'] =
            species;
        state.fortuna = 0;
        state.livelloController.text = '6';
        state.gradoController.text = '0';
        state.arti.clear();
        state.skills.clear();
        state.titoli.clear();
        state.trattiRazziali.clear();
        state.inventario.clear();
        state.activeStructuredEffects.clear();
        state.activeConditions.clear();
        state.masterInitiativeTokens.add(<String, dynamic>{
          'id': 'THIRD',
          'sheetTag': 'THIRD',
          'name': 'Terzo nemico',
          'side': 'enemy',
          'status': 'ready',
        });
        p.recordCurrentEncounter();
        p.invalidateDerivedCaches();
        state.currentHpController.text = '${p.maximumHp()}';
        final expected = oculumDamagePerTarget(
          p.damageTotal(),
          targetCount,
          flatBonusPerTarget: 15 + 5 * 6,
        );
        final attack = p.planAttack(total: 30, natural: 10);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final planner = find.byType(OculumAttackPlanner);
        expect(planner, findsOneWidget);
        expect(tester.widget<OculumAttackPlanner>(planner).maximumTargets, 3);
        Navigator.of(tester.element(planner)).pop(
          OculumAttackPlan(
            'ENEMY',
            'vc',
            'Colpo della trave',
            additionalTargetIds: targetCount == 3 ? ['OTHER', 'THIRD'] : [],
            element: 'contundente',
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await attack;
        final requests = (state.onlineCombatRequests as Map).values
            .whereType<Map>()
            .where((r) => r['sourceTag'] == p.ownerTag())
            .toList();
        expect(requests, hasLength(targetCount));
        expect(requests.map((r) => r['damage']), everyElement(expected));
        await closeFixture(tester, p);
      });
    }
  }
}
