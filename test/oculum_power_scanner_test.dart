import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/oculum_combat_scout_rules.dart';
import 'package:oculum/main.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  test('total power includes grade, threshold and chance caps', () {
    expect(oculumScoutPower(12, [10, 20, 30, 40], grade: 3), 121);
    expect(oculumExactPowerChance(40, success: true), 0);
    expect(oculumExactPowerChance(41, success: true), 5);
    expect(oculumExactPowerChance(59, success: true), 95);
    expect(oculumExactPowerChance(61, success: true), 100);
    expect(oculumExactPowerChance(70, success: false), 0);
  });
  test(
    'scanner never reveals out-of-range power and estimates stay within ten percent',
    () {
      final random = Random(42);
      expect(oculumPowerScannerLimit(0), 50);
      expect(oculumPowerScannerLimit(5), 200);
      expect(oculumPowerScannerRead(201, 5, random), {
        'scannerOutOfRange': true,
      });
      for (final power in [0, 1, 9, 50, 200]) {
        for (var i = 0; i < 100; i++) {
          final read = oculumPowerScannerRead(power, 5, random);
          expect(read.keys, ['scannerEstimate']);
          expect(
            read['scannerEstimate'],
            inInclusiveRange((power * .9).ceil(), (power * 1.1).floor()),
          );
        }
      }
      final magic = {
        for (var i = 0; i < 1000; i++) oculumPowerScannerUses(random),
      };
      final cyber = {
        for (var i = 0; i < 1000; i++)
          oculumPowerScannerUses(random, postea: true),
      };
      expect(magic, {for (var i = 7; i <= 15; i++) i});
      expect(cyber, {for (var i = 13; i <= 35; i++) i});
      expect(
        oculumPowerScannerPrice(5, postea: true),
        oculumPowerScannerPrice(5) * 6,
      );
    },
  );
  testWidgets(
    'purchase rolls once; uses and edited level survive JSON without shop refresh',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 1000),
      );
      state.datiCaricati = false;
      state.livelloController.text = '5';
      final p = OculumPerformanceProbe(state);
      p.ensurePowerScanners();
      final List offers = state.merchantStock
          .where((dynamic o) => o['kind'] == 'postea_power_scanner')
          .toList();
      expect(offers.length, 3);
      final InventoryItem item = p.scannerFromOffer(
        Map<String, dynamic>.from(offers.first),
      );
      expect(item.livelloOggetto, 5);
      final uses = item.craftData['scannerUses'] as int;
      expect(uses, inInclusiveRange(13, 35));
      item.craftData['scannerUses'] = uses - 1;
      item.livelloOggetto = 8;
      final restored = InventoryItem.fromJson(
        jsonDecode(jsonEncode(item.toJson())) as Map<String, dynamic>,
      );
      p.ensurePowerScanners();
      expect(restored.craftData['scannerUses'], uses - 1);
      expect(restored.livelloOggetto, 8);
      expect(p.usableMerchantItem(restored), true);
      state.schedePersonaggio
        ..clear()
        ..add(p.snapshot());
      state.schedaCorrente = 0;
      final npc = p.snapshot()..['tipoScheda'] = 'NPC';
      npc.addAll({
        'grado': 2,
        'livello': 10,
        'derivedResilienzaTotal': 20,
        'derivedVolontaTotal': 20,
        'derivedMateriaTotal': 20,
        'derivedOculumTotal': 20,
      });
      state.schedePersonaggio.add(npc);
      final targetIndex = state.schedePersonaggio.length - 1 as int;
      expect(p.totalPower(targetIndex), 96);
      expect(p.powerReading(targetIndex, 60)['exactPower'], 96);
      expect(
        p
            .powerReading(targetIndex, 60, success: false)
            .containsKey('exactPower'),
        false,
      );
      expect(
        p
            .powerReading(targetIndex, 60, perception: false)
            .containsKey('exactPower'),
        false,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
