import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  test(
    'celestial allegiance survives JSON and only applies the authored matchup',
    () {
      expect(oculumCelestialAllegiance({'razza': 'Mhunan'}), 'lunare');
      expect(oculumCelestialAllegiance({'razza': 'Elfo'}), 'nessuna');
      expect(
        oculumCelestialAllegiance({
          'razza': 'Mhunan',
          'planarRuntime': {'identityCelestial': 'solare'},
        }),
        'solare',
      );
      expect(
        oculumCelestialAllegiance({
          'monsterBookSourceId': 'ciclo_solare_siccita',
        }),
        'solare',
      );
      expect(
        oculumCycleCelestialDamage(
          100,
          source: 'solare',
          target: 'lunare',
          sourceSolarPercent: 50,
        ),
        150,
      );
      expect(
        oculumCycleCelestialDamage(
          100,
          source: 'lunare',
          target: 'solare',
          targetSolarPercent: 50,
        ),
        150,
      );
      expect(
        oculumCycleCelestialDamage(
          100,
          source: 'solare',
          target: 'solare',
          sourceSolarPercent: 50,
        ),
        100,
      );
      expect(
        oculumCycleCelestialDamage(100, source: 'solare', target: 'lunare'),
        100,
      );
    },
  );

  test(
    'spines count successful earlier hits and throw thresholds are distinct',
    () {
      expect(oculumCycleSpineDamage(100, [], 'a'), 100);
      expect(oculumCycleSpineDamage(100, ['a'], 'a'), 105);
      expect(oculumCycleSpineDamage(100, ['a', 'b', 'b'], 'a'), 125);
      expect(oculumSkeletonThrowMetres(17, 30, 20), 8);
      expect(oculumSkeletonThrowMetres(18, 30, 20), 10);
      expect(oculumSkeletonThrowMetres(20, 10, 20), 0);
      expect(oculumSkeletonThrowRecovered(17, 30, 8, 30), false);
      expect(oculumSkeletonThrowRecovered(17, 30, 8, 31), true);
      expect(oculumSkeletonThrowRecovered(18, 30, 10, 24), true);
      expect(oculumSkeletonThrowRecovered(19, 30, 10, 26), false);
      expect(oculumSkeletonThrowRecovered(19, 30, 10, 27), true);
      expect(oculumSkeletonThrowRecovered(20, 30, 10, 59), false);
      expect(oculumSkeletonThrowRecovered(20, 30, 10, 60), true);
    },
  );

  test(
    'giants are unique, have their own anatomy and usable Open and costs',
    () {
      for (final id in ['gigante_comune', 'gigante_scheletro']) {
        final monster = monsterBookEntryById(id)!;
        expect(
          defaultMonsterBookEntries.where((m) => m.id == id),
          hasLength(1),
        );
        expect(oculumMonsterCyclePhase(monster), isEmpty);
        final parts = oculumMonsterPrecisionAnatomy(monster);
        expect(parts.where((p) => p['group'] == 'arms'), hasLength(2));
        expect(parts.where((p) => p['group'] == 'legs'), hasLength(2));
        final art = oculumMonsterBookArt(monster);
        expect(
          art.openSkillEffects.single.valueExpression,
          contains('monster_open_bonus'),
        );
        expect(art.openSkillCooldown!.amount, greaterThan(0));
        for (final skill in art.skills) {
          expect(skill.effettiEvoluzione(1), isNotEmpty);
          expect(skill.oculumMinimoPerLivello(1), 1);
        }
      }
      final boar = monsterBookEntryById('ciclo_cinghiale_fango')!;
      expect(boar.skillIds.map((id) => oculumPlanarTechnique(id)!.element), [
        'fango',
        'terra',
        'roccia',
      ]);
    },
  );

  testWidgets(
    'three distinct Fate gifts stack up to six and expire with their phase',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 1000),
      );
      state.datiCaricati = false;
      final p = OculumPerformanceProbe(state);
      final sheet = p.snapshot()..['planarRuntime'] = <String, dynamic>{};
      state.schedePersonaggio.clear();
      state.schedePersonaggio.add(sheet);
      state.schedaCorrente = 0;
      p.load(sheet);
      p.chooseChaos(false);
      p.cycleDay(190);
      final before = p.coreStats();
      expect(p.cycleGift('donor-a', 0), true);
      expect(p.cycleGift('donor-a', 0), false);
      expect(p.cycleGift('donor-b', 24), true);
      expect(p.cycleGift('donor-c', 0), true);
      expect(p.cycleGift('donor-d', 0), false);
      expect(p.cycleGiftBonus(), 6);
      for (final key in before.keys) {
        expect(p.coreStats()[key], before[key]! + 6, reason: key);
      }
      final restored = p.snapshot();
      p.load(restored);
      expect(p.cycleGift('donor-a', 0), false);
      p.cycleDay(226);
      expect(p.cycleGiftBonus(), 0);
      expect(p.planarStateSnapshot()['cycleFateDonors'], isNull);
      p.cycleDay(190);
      expect(p.cycleGift('donor-a', 99), true);
      expect(p.cycleGiftBonus(), 1);
      p.chooseChaos(true);
      expect(p.cycleGift('donor-e', 0), false);
      expect(p.cycleGiftBonus(), 0);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'cloud checks are stable and critical shields block authored debuffs',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 1000),
      );
      state.datiCaricati = false;
      final p = OculumPerformanceProbe(state);
      final sheet = p.snapshot()..['planarRuntime'] = <String, dynamic>{};
      state.schedePersonaggio.clear();
      state.schedePersonaggio.add(sheet);
      state.schedaCorrente = 0;
      p.load(sheet);
      state.scudoCriticoController.text = '0';
      p.cycleCritical({
        'id': 'shielded',
        'sourceMonsterBookId': 'ciclo_forest_demon_blu',
        'cycleCriticalCount': 19,
        'criticalShieldProtected': true,
      });
      expect(p.planarStateSnapshot()['cycleCloudChance'], isNull);
      p.cycleCritical({
        'id': 'cloud',
        'sourceMonsterBookId': 'ciclo_forest_demon_blu',
        'cycleCriticalCount': 1,
      });
      expect(p.planarStateSnapshot()['cycleCloudChance'], 10);
      final request = <String, dynamic>{'sourceName': 'Nemico'};
      expect(p.cycleCloud(request, 9), true);
      expect(p.cycleCloud(request, 99), true);
      expect(p.cycleCloud({'sourceName': 'Altro'}, 99), false);
      p.cycleCritical({
        'id': 'cloud',
        'sourceMonsterBookId': 'ciclo_forest_demon_blu',
        'cycleCriticalCount': 100,
      });
      expect(p.planarStateSnapshot()['cycleCloudChance'], 10);
      p.cycleCritical({
        'id': 'cloud-max',
        'sourceMonsterBookId': 'ciclo_forest_demon_blu',
        'cycleCriticalCount': 100,
      });
      expect(p.planarStateSnapshot()['cycleCloudChance'], 100);
      final madnessBefore = int.tryParse('${state.folliaController.text}') ?? 0;
      p.cycleCritical({
        'id': 'madness',
        'sourceMonsterBookId': 'ciclo_la_follia',
      });
      p.cycleCritical({
        'id': 'madness',
        'sourceMonsterBookId': 'ciclo_la_follia',
      });
      expect(int.parse('${state.folliaController.text}'), madnessBefore + 1);
      p.finishPlanarFight();
      expect(p.cycleCloud({'sourceName': 'Dopo'}, 0), false);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
