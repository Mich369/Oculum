import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;
import 'oculum_protection_wear_test.dart' show prepareProtectionFixture;

InventoryItem posteaArmor() => InventoryItem(
  nome: 'Corazza reattiva di Postea',
  peso: 4,
  quantita: 1,
  note: '',
  protegge: true,
  livelloOggetto: 6,
  bonusScudo: 200,
  bonusDifesa: 20,
  craftData: {'wearProtectionKind': 'armor', 'posteaReactiveArmor': true},
);

void main() {
  test(
    'reactive bonuses reach 190% at half and keep normal broken residual',
    () {
      final armor = posteaArmor();
      expect(oculumEquipmentWearValue(armor, 200), 200);
      oculumSpendEquipmentWear(armor, 250);
      expect(oculumEquipmentWearValue(armor, 200), 290);
      oculumSpendEquipmentWear(armor, 250);
      expect(oculumEquipmentWearValue(armor, 200), 380);
      oculumSpendEquipmentWear(armor, 499);
      expect(oculumEquipmentWearValue(armor, 200), 380);
      oculumSpendEquipmentWear(armor, 1, rollBrokenPercent: () => 23);
      final loaded = InventoryItem.fromJson(armor.toJson());
      expect(oculumEquipmentWearValue(loaded, 200), 46);
    },
  );

  testWidgets('half durability restores only its own normal Shield once', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    prepareProtectionFixture(state, probe);
    state.resilienzaController.text = '30';
    probe.setResourceCurrent('resilienza', 30);
    probe.invalidateDerivedCaches();
    state.masterInitiativeTokens.removeWhere(
      (dynamic token) => token['side'] == 'enemy',
    );
    probe.recordCurrentEncounter();
    final armor = posteaArmor();
    state.inventario
      ..clear()
      ..add(armor);
    probe.equipItem(armor, true);
    expect(probe.shieldTotal(), 200);
    oculumSpendEquipmentWear(armor, 499);
    expect(oculumEquipmentUses(armor), 501);

    await probe.damageResolved(210, bypassDefense: true);
    expect(probe.currentHp(), 90);
    expect(oculumEquipmentUses(armor), 500);
    expect(probe.equipmentDefense(armor), 38);
    expect(probe.shieldTotal(), 50);
    expect(armor.scudoIntegritaCorrente, 50);

    await probe.damageResolved(60, bypassDefense: true);
    expect(probe.currentHp(), 80);
    expect(oculumEquipmentUses(armor), 499);
    expect(probe.shieldTotal(), 0);
    expect(armor.scudoIntegritaCorrente, 0);
    await closeFixture(tester, probe);
  });
}
