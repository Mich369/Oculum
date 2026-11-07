import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

InventoryItem protection(
  String name, {
  String? kind,
  int shield = 0,
  int defense = 0,
  String buff = '',
  bool title = false,
}) => InventoryItem(
  nome: name,
  peso: 1,
  quantita: 1,
  note: '',
  protegge: true,
  livelloOggetto: 3,
  bonusScudo: shield,
  bonusDifesa: defense,
  buff: buff,
  craftData: {
    'wearProtectionKind': ?kind,
    if (title) 'titleItem': true,
  },
);

void prepareProtectionFixture(dynamic state, OculumPerformanceProbe probe) {
  state.campaignDifficulty = 'normale';
  state.karmaController.text = '0';
  state.fortuna = 0;
  state.livelloController.text = '0';
  state.gradoController.text = '0';
  state.currentHpController.text = '100';
  state.scudoController.text = '0';
  state.scudoOculumMaxController.text = '0';
  state.scudoOculumController.text = '0';
  state.scudoCriticoController.text = '0';
  state.hpTempController.text = '0';
  state.oculumController.text = '0';
  probe.setResourceCurrent('oculum', 0);
  for (final HiddenEyeStat stat in state.hiddenEyeStats) {
    if (stat.id == 'fortuna') stat.unlocked = false;
    if (stat.id == 'resistenza') stat.valore = -100;
  }
  probe.invalidateDerivedCaches();
}

void main() {
  test('protection subtype is explicit and survives a JSON round trip', () {
    final ambiguous = protection('Scudo in un vecchio salvataggio', shield: 8);
    expect(oculumWearProtectionKind(ambiguous), isNull);
    expect(
      oculumWearProtectionKind(
        protection('Titolo', kind: 'shield', title: true),
      ),
      isNull,
    );
    final typed = protection('Scudo', kind: 'shield', shield: 80);
    typed.craftData['wearUsesRemaining'] = 1;
    expect(oculumEquipmentWearValue(typed, 80), 24);
    expect(oculumSpendEquipmentWear(typed, 1, rollBrokenPercent: () => 25), 1);
    final loaded = InventoryItem.fromJson(typed.toJson());
    expect(oculumWearProtectionKind(loaded), OculumWearProtectionKind.shield);
    expect(oculumEquipmentBrokenPercent(loaded), 25);
    expect(oculumEquipmentWearValue(loaded, 80), 20);
  });

  testWidgets('only the equipped item that actually protects accrues wear', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    prepareProtectionFixture(state, probe);
    final armor = protection(
      'Corazza',
      kind: 'armor',
      defense: 20,
      buff: '@Difesa+10',
    );
    final shield = protection('Scudo', kind: 'shield', shield: 20);
    final ambiguous = protection('Scudo legacy', shield: 7);
    state.inventario.addAll([armor, shield, ambiguous]);
    probe.equipItem(armor, true);
    probe.equipItem(shield, true);
    probe.equipItem(ambiguous, true);
    expect(probe.shieldTotal(), 27);
    expect(shield.scudoIntegritaCorrente, 20);

    Future<void> hit(int damage) =>
        probe.damageResolved(damage, bypassDefense: true);
    await hit(5); // Absorbed by the still-unattributed shield pool.
    expect(probe.shieldTotal(), 22);
    expect(shield.scudoIntegritaCorrente, 20);
    expect(oculumEquipmentUses(shield), 1000);
    await hit(4); // Two untracked points and two points from the worn shield.
    expect(probe.shieldTotal(), 18);
    expect(shield.scudoIntegritaCorrente, 18);
    expect(oculumEquipmentUses(shield), 999);
    expect(oculumEquipmentUses(armor), 1000);
    expect(oculumEquipmentUses(ambiguous), 1000);
    expect(probe.itemShield(shield), 19);

    expect(probe.equipmentDefense(armor), 30);
    await hit(20); // The shield cannot stop the entire remainder.
    expect(probe.shieldTotal(), 0);
    expect(shield.scudoIntegritaCorrente, 0);
    expect(oculumEquipmentUses(shield), 999);
    expect(oculumEquipmentUses(armor), 999);
    expect(probe.equipmentDefense(armor), 29);

    final first = protection('Scudo anteriore', kind: 'shield', shield: 5);
    final last = protection('Scudo posteriore', kind: 'shield', shield: 12);
    state.inventario.addAll([first, last]);
    probe.equipItem(first, true);
    probe.equipItem(last, true);
    await hit(8);
    expect(first.scudoIntegritaCorrente, 0);
    expect(last.scudoIntegritaCorrente, 9);
    expect(probe.shieldTotal(), 9);
    expect(oculumEquipmentUses(first), 1000);
    expect(oculumEquipmentUses(last), 999);
    expect(oculumEquipmentUses(armor), 999);
    expect(tester.takeException(), isNull);
    await closeFixture(tester, probe);
  });

  testWidgets('hostile matchup aggravates wear on a defending monster', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    prepareProtectionFixture(state, probe);
    state.tipoSchedaController.text = 'Mostro';
    final armor = protection('Corazza', kind: 'armor', defense: 10);
    state.inventario.add(armor);
    probe.equipItem(armor, true);
    state.masterInitiativeTokens[0]['side'] = 'enemy';
    state.masterInitiativeTokens[1].addAll({
      'side': 'party',
      'type': 'Personaggio',
      'level': 4,
      'grade': 2,
    });
    state.onlineCombatRequests['wear-hit'] = <String, dynamic>{
      'sourceTag': 'ENEMY',
    };
    await probe.damageResolved(
      1,
      bypassDefense: true,
      bypassShields: true,
      packetId: 'wear-hit',
    );
    expect(oculumEquipmentUses(armor), 996);

    state.tipoSchedaController.text = 'Personaggio';
    state.onlineCombatRequests['wear-pvp'] = <String, dynamic>{
      'sourceTag': 'ENEMY',
    };
    await probe.damageResolved(1, bypassDefense: true, packetId: 'wear-pvp');
    expect(oculumEquipmentUses(armor), 995);
    await probe.damageResolved(1, bypassDefense: true);
    expect(oculumEquipmentUses(armor), 994);
    expect(tester.takeException(), isNull);
    await closeFixture(tester, probe);
  });
}
