import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

import 'oculum_theme_effects_portrait_test.dart' as fixtures;

Iterable<Map<String, dynamic>> _stoneOffers(OculumPerformanceProbe probe) =>
    probe.shopOffers().where((offer) => offer['kind'] == 'resurrection_stone');

void main() {
  testWidgets(
    'resurrection stones have saved shop prices and enter inventory',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      probe.shopOffers();
      final mainShopId = state.merchantActiveProfileId as String;
      probe.shopType('alchimista');

      final alchemistOffer = _stoneOffers(probe).single;
      final alchemistPrice = probe.shopCost(alchemistOffer);
      expect(alchemistPrice, inInclusiveRange(160, 250));
      expect(alchemistPrice, alchemistOffer['cost']);

      probe.shopType('mercato_nero');
      final marketOffer = _stoneOffers(probe).single;
      final marketPrice = probe.shopCost(marketOffer);
      expect(marketPrice, inInclusiveRange(120, 160));
      expect(marketPrice, marketOffer['cost']);
      expect(marketOffer['id'], isNot(alchemistOffer['id']));

      state.obserController.text = '500';
      final inventory = (state.inventario as List).cast<InventoryItem>();
      inventory.clear();
      await probe.buyShopOffer(alchemistOffer);
      expect(state.obserController.text, '500');
      expect(inventory, isEmpty);
      await probe.buyShopOffer(marketOffer);
      expect(state.obserController.text, '${500 - marketPrice}');
      final restored = InventoryItem.fromJson(inventory.single.toJson());
      expect(restored.nome, 'Pietra della Resurrezione');
      expect(restored.craftData['resurrectionStone'], isTrue);
      expect(restored.craftData['rarity'], 'raro');
      expect(oculumInventoryCatalogCategories(restored), contains('consumable'));
      expect(
        probe.masterCatalogItems().where(
          (item) => item.craftData['resurrectionStone'] == true,
        ),
        hasLength(1),
      );

      probe.shopType('fabbro');
      expect(_stoneOffers(probe), isEmpty);
      probe.shopType('tutti');
      expect(_stoneOffers(probe), isEmpty);
      probe.shopType('alchimista');
      expect(probe.shopCost(_stoneOffers(probe).single), alchemistPrice);

      probe.createMerchantProfile();
      probe.shopType('mercato_nero');
      expect(probe.shopCost(_stoneOffers(probe).single), inInclusiveRange(120, 160));
      probe.switchMerchantProfile(mainShopId);
      expect(probe.shopCost(_stoneOffers(probe).single), alchemistPrice);
      probe.shopType('mercato_nero');
      expect(probe.shopCost(_stoneOffers(probe).single), marketPrice);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );
}
