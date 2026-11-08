import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

InventoryItem _weapon({int level = 0}) => InventoryItem(
  nome: 'Lama infusa',
  peso: 1,
  quantita: 1,
  note: '',
  arma: true,
  livelloOggetto: level,
);

void main() {
  const offense = OculumDustInfusionMode.offense;
  const defense = OculumDustInfusionMode.defense;
  const both = OculumDustInfusionMode.both;

  test('infusions preserve level tiers and stack on the same item', () {
    expect(
      [
        for (final level in [0, 1, 2, 3, 6]) defense.shieldAt(level),
      ],
      [6, 10, 10, 40, 70],
    );
    expect(
      [
        for (final level in [0, 1, 2, 3, 6]) both.shieldAt(level),
      ],
      [3, 6, 6, 36, 66],
    );
    final item = _weapon(level: 3);
    expect(oculumDustInfusionBonuses(item), (attack: 0, defense: 0, shield: 0));
    expect(oculumApplyDustInfusion(item, offense, crystal: true), isTrue);
    expect(oculumApplyDustInfusion(item, defense, crystal: true), isTrue);
    expect(oculumApplyDustInfusion(item, both, crystal: true), isTrue);
    expect(oculumDustInfusionBonuses(item), (
      attack: 2,
      defense: 2,
      shield: 76,
    ));
  });

  test('medium and large crystals equal six and nine pure Dust doses', () {
    for (final (size, units) in [('medio', 2), ('grande', 3)]) {
      for (final mode in OculumDustInfusionMode.values) {
        final crystal = _weapon(level: 3);
        final pure = _weapon(level: 3);
        expect(
          oculumApplyDustInfusion(
            crystal,
            mode,
            crystal: true,
            crystalSize: size,
          ),
          isTrue,
        );
        for (var dose = 0; dose < units * 3; dose++) {
          expect(oculumApplyDustInfusion(pure, mode, crystal: false), isTrue);
        }
        expect(oculumPendingDustInfusion(crystal).doses, 0);
        expect(
          oculumDustInfusionBonuses(crystal),
          oculumDustInfusionBonuses(pure),
        );
      }
    }
  });

  test('larger crystals preserve existing modes and pending doses in JSON', () {
    final item = _weapon();
    expect(oculumApplyDustInfusion(item, defense, crystal: true), isTrue);
    expect(oculumApplyDustInfusion(item, both, crystal: false), isTrue);
    expect(
      oculumApplyDustInfusion(
        item,
        offense,
        crystal: true,
        crystalSize: 'medio',
      ),
      isTrue,
    );
    expect(
      oculumApplyDustInfusion(item, both, crystal: true, crystalSize: 'grande'),
      isTrue,
    );
    final restored = InventoryItem.fromJson(
      jsonDecode(jsonEncode(item.toJson())) as Map<String, dynamic>,
    );
    expect(oculumPendingDustInfusion(restored), (mode: both, doses: 1));
    expect(oculumDustInfusionBonuses(restored), (
      attack: 6,
      defense: 5,
      shield: 18,
    ));
    expect(oculumExpireDustInfusion(restored), isTrue);
    expect(oculumDustInfusionBonuses(restored), (
      attack: 5,
      defense: 4,
      shield: 15,
    ));
  });

  test('three matching doses promote to one permanent infusion', () {
    final item = _weapon();
    expect(oculumApplyDustInfusion(item, both, crystal: false), isTrue);
    expect(oculumApplyDustInfusion(item, defense, crystal: false), isFalse);
    expect(oculumApplyDustInfusion(item, defense, crystal: true), isTrue);
    expect(oculumApplyDustInfusion(item, both, crystal: false), isTrue);
    final saved = jsonDecode(jsonEncode(item.toJson())) as Map<String, dynamic>;
    final restored = InventoryItem.fromJson(saved);
    expect(oculumPendingDustInfusion(restored), (mode: both, doses: 2));
    expect(oculumDustInfusionBonuses(restored), (
      attack: 2,
      defense: 3,
      shield: 12,
    ));
    expect(oculumApplyDustInfusion(restored, both, crystal: false), isTrue);
    expect(oculumPendingDustInfusion(restored), (mode: null, doses: 0));
    expect(oculumDustInfusionBonuses(restored), (
      attack: 1,
      defense: 2,
      shield: 9,
    ));
    expect(oculumApplyDustInfusion(restored, offense, crystal: false), isTrue);
    expect(oculumExpireDustInfusion(restored), isTrue);
    expect(oculumExpireDustInfusion(restored), isFalse);
    expect(oculumDustInfusionBonuses(restored), (
      attack: 1,
      defense: 2,
      shield: 9,
    ));
  });

  testWidgets('infused weapon keeps its depleted shield when re-equipped', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    state.masterInitiativeTokens.clear();
    state.masterInitiativeGroups.clear();
    state.campaignDifficulty = 'normale';
    state.scudoOculumMaxController.text = '0';
    state.scudoOculumController.text = '0';
    state.scudoController.text = '0';
    state.scudoCriticoController.text = '0';
    state.hpTempController.text = '0';
    state.currentHpController.text = '100';
    final item = _weapon();
    expect(oculumApplyDustInfusion(item, defense, crystal: true), isTrue);
    state.inventario.add(item);
    probe.invalidateDerivedCaches();

    probe.equipItem(item, true);
    expect(state.scudoOculumController.text, '6');
    await probe.damageResolved(2, bypassDefense: true);
    expect(state.scudoOculumController.text, '4');
    expect(item.scudoIntegritaOculumCorrente, 4);

    probe.equipItem(item, false);
    expect(state.scudoOculumController.text, '0');
    probe.equipItem(item, true);
    expect(state.scudoOculumController.text, '4');
    expect(item.scudoIntegritaOculumCorrente, 4);
    expect(tester.takeException(), isNull);
    await closeFixture(tester, probe);
  });

  testWidgets('only Oculum-powered attacks receive the equipped roll bonus', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    state.masterInitiativeTokens.clear();
    state.masterInitiativeGroups.clear();
    state.karmaController.text = '0';
    state.fortuna = 0;
    state.livelloController.text = '3';
    state.oculumController.text = '10';
    probe.setResourceCurrent('oculum', 10);
    for (final stat in state.hiddenEyeStats) {
      if (stat.id == 'fortuna') stat.unlocked = false;
    }
    final item = _weapon();
    oculumApplyDustInfusion(item, offense, crystal: true);
    state.inventario.add(item);
    probe.invalidateDerivedCaches();

    Future<int> attackBonus({required bool spend}) async {
      state.oculumTiroController.text = spend ? '1' : '0';
      var effective = 0;
      await probe.rollSpecial(
        'VC',
        10,
        onResolved: (natural, total) {
          effective = total - probe.rollTotal(natural, 20, const [0]);
        },
      );
      return effective;
    }

    final plain = await attackBonus(spend: false);
    final empowered = await attackBonus(spend: true);
    probe.equipItem(item, true);
    expect(await attackBonus(spend: false), plain);
    expect(await attackBonus(spend: true), empowered + 1);
    expect(tester.takeException(), isNull);
    await closeFixture(tester, probe);
  });
}
