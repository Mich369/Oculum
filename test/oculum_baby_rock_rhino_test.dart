import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

Future<(dynamic, OculumPerformanceProbe)> mountStoneguard(
  WidgetTester tester, {
  String? monsterId = 'baby_rock_rhino',
  int? learnedPercent,
}) async {
  final (state, p) = await fixtures.mountFight(tester);
  state.arti.clear();
  state.skills.clear();
  state.titoli.clear();
  state.trattiRazziali.clear();
  state.inventario.clear();
  state.activeConditions.clear();
  state.activeStructuredEffects.clear();
  final sheet = state.schedePersonaggio[state.schedaCorrente] as Map;
  if (monsterId == null) {
    sheet.remove('monsterBookSourceId');
  } else {
    sheet['monsterBookSourceId'] = monsterId;
  }
  sheet['planarRuntime'] = <String, dynamic>{};
  if (learnedPercent != null) {
    state.skills.add(
      CharacterSkill(
        nome: 'Guardia di pietra',
        tipo: 'Passiva',
        costo: '0',
        cooldown: '0',
        descrizione: 'Scudo normale a inizio Fight.',
        scrollData: {
          'passiveId': 'rhino_stoneguard_passive',
          'startingShieldPercent': learnedPercent,
        },
      ),
    );
  }
  // Exact shield depletion must not depend on random passive mitigation.
  state.campaignDifficulty = 'normale';
  state.fortuna = 0;
  state.karmaController.text =
      '-${readIntValue(state.livelloController.text) ~/ 2}';
  state.oculumController.text = '0';
  state.currentOculumController.text = '0';
  for (final dynamic stat in state.hiddenEyeStats) {
    if (const {'resistenza', 'riflessi'}.contains(stat.id)) {
      stat.valore = -50;
    }
  }
  state.currentHpController.text = '75';
  state.scudoController.text = '7';
  state.scudoOculumController.text = '0';
  state.scudoCriticoController.text = '0';
  state.hpTempController.text = '0';
  state.scudoSalvataggioAttivo = false;
  state.modificatoreDannoSelezionato = 'Normale';
  p.invalidateDerivedCaches();
  expect(p.subtraitValue('fortuna'), lessThanOrEqualTo(0));
  expect(p.subtraitValue('resistenza'), lessThanOrEqualTo(0));
  p.recordCurrentEncounter();
  return (state, p);
}

void main() {
  test(
    'Rhino starting shield rounds up and its limbs have separate targets',
    () {
      expect(oculumStoneguardStartingShield(75, 25), 19);
      expect(oculumStoneguardStartingShield(4, 25), 1);
      expect(oculumStoneguardStartingShield(5, 25), 2);
      expect(oculumStoneguardStartingShield(75, 0), 0);
      for (final id in oculumRhinoStoneguardMonsterIds) {
        final rhino = monsterBookEntryById(id)!;
        final parts = oculumMonsterPrecisionAnatomy(rhino);
        expect(parts.where((p) => p['group'] == 'horns'), hasLength(1));
        final legs = parts.where((p) => p['group'] == 'legs');
        expect(legs.map((p) => p['id']).toSet(), hasLength(4));
      }
    },
  );

  testWidgets('Fight start grants one buffer; exposure survives reload', (
    tester,
  ) async {
    final (state, p) = await mountStoneguard(tester);
    final base = p.shieldTotal();
    final granted = oculumStoneguardStartingShield(p.maximumHp(), 25);
    final hp = p.currentHp();
    expect(p.anatomicalTargetAvailable('core'), isFalse);
    p.startFight('encounter_1');
    expect(p.shieldTotal(), base + granted);
    expect(p.anatomicalTargetAvailable('core'), isFalse);

    await p.stoneguardDamageForTest(1, part: 'core', bypassShields: true);
    expect(p.currentHp(), hp);
    expect(p.shieldTotal(), base + granted);
    await p.stoneguardDamageForTest(granted - 1);
    expect(p.shieldTotal(), base + 1);
    expect(p.anatomicalTargetAvailable('core'), isFalse);
    await p.stoneguardDamageForTest(1);
    expect(p.shieldTotal(), base);
    expect(p.currentHp(), hp);
    expect(p.anatomicalTargetAvailable('core'), isTrue);

    final saved = jsonDecode(jsonEncode(p.snapshot())) as Map<String, dynamic>;
    state.schedePersonaggio[state.schedaCorrente] = saved;
    p.load(saved);
    expect(p.shieldTotal(), base);
    expect(p.anatomicalTargetAvailable('core'), isTrue);
    p.startFight('encounter_1');
    expect(p.shieldTotal(), base + granted);
    expect(p.anatomicalTargetAvailable('core'), isFalse);
    await closeFixture(tester, p);
  });

  testWidgets('remote exposure only applies to the current token Fight', (
    tester,
  ) async {
    final (_, p) = await mountStoneguard(tester);
    final token = <String, dynamic>{
      'id': 'REMOTE-RHINO',
      'sheetTag': 'REMOTE-RHINO',
      'monsterBookId': 'baby_rock_rhino',
      'fightInstanceId': 'new',
      'status': 'ready',
      'faunaPublic': {
        'babyRockRhinoCore': {'fightInstanceId': 'old', 'exposed': true},
      },
    };
    bool visible() =>
        p.anatomicalPartsForTarget(token).any((p) => p['id'] == 'core');
    expect(visible(), isFalse);
    token['faunaPublic'] = {
      'babyRockRhinoCore': {'fightInstanceId': 'new', 'exposed': true},
    };
    expect(visible(), isTrue);
    token['outsideFight'] = true;
    expect(visible(), isFalse);
    await closeFixture(tester, p);
  });

  testWidgets(
    'Visrhyno receives Stoneguard and preserves its saved percentage',
    (tester) async {
      final (state, p) = await mountStoneguard(
        tester,
        monsterId: 'baby_rock_rhino_variante_veterana',
      );
      final base = p.shieldTotal();
      final granted = oculumStoneguardStartingShield(p.maximumHp(), 25);
      p.startFight('encounter_1');
      expect(p.shieldTotal(), base + granted);
      expect(p.anatomicalTargetAvailable('core'), isFalse);
      await p.stoneguardDamageForTest(granted);
      expect(p.shieldTotal(), base);
      expect(p.anatomicalTargetAvailable('core'), isTrue);

      final runtime =
          state.schedePersonaggio[state.schedaCorrente]['planarRuntime'];
      runtime['startingStoneShieldPercent'] = 40;
      p.startFight('encounter_1');
      expect(
        p.shieldTotal(),
        base + oculumStoneguardStartingShield(p.maximumHp(), 40),
      );
      expect(p.anatomicalTargetAvailable('core'), isFalse);
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'learned passive uses its saved percentage without a Rhino core',
    (tester) async {
      final (_, p) = await mountStoneguard(
        tester,
        monsterId: null,
        learnedPercent: 40,
      );
      final base = p.shieldTotal();
      p.startFight('encounter_1');
      expect(
        p.shieldTotal(),
        base + oculumStoneguardStartingShield(p.maximumHp(), 40),
      );
      expect(
        p.anatomicalPartsForCurrentSheet().any((part) => part['id'] == 'core'),
        isFalse,
      );
      await closeFixture(tester, p);
    },
  );
}
