import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  test('both Lost Town districts belong to the Middle Realm', () {
    expect(oculumCityMerchantPlaneId('merchant_lost_town'), 'mezzano');
    expect(oculumCityMerchantPlaneId('merchant_lost_town_upper'), 'mezzano');
    expect(oculumCityMerchantPlaneId('merchant_vaitern'), 'mezzano');
    expect(oculumCityMerchantPlaneId('merchant_custom'), isNull);
    expect(oculumMerchantCanBarterAt('solar'), isFalse);
    expect(oculumLostTownMerchantPrice(100), 125);
  });
  testWidgets('city shops cannot be opened in another realm and retain stock', (
    tester,
  ) async {
    final dynamic state = await fixtures.mountSheet(
      tester,
      const Size(1440, 900),
    );
    final probe = OculumPerformanceProbe(state);
    if (state.schedePersonaggio.isEmpty) {
      state.schedePersonaggio.add(<String, dynamic>{'id': 'qa-city-realm'});
      state.schedaCorrente = 0;
    }
    final Map<String, dynamic> sheet =
        state.schedePersonaggio[state.schedaCorrente];
    final cityStock = <Map<String, dynamic>>[
      {
        'id': 'qa_city_unique_item',
        'kind': 'gear',
        'name': 'Oggetto personalizzato',
        'remaining': 1,
        'cost': 11,
        'custom': {'retained': true},
      },
    ];
    state.merchantProfiles.clear();
    state.merchantProfiles.addAll(<Map<String, dynamic>>[
      {
        'id': 'merchant_default',
        'name': 'Mercante ordinario',
        'pricePercent': 100,
        'stock': <Map<String, dynamic>>[],
      },
      {
        'id': 'merchant_lost_town',
        'name': 'Lost Town',
        'pricePercent': 100,
        'stock': cityStock,
      },
      {
        'id': 'merchant_lost_town_upper',
        'name': 'Lost Town alta',
        'location': 'solar',
        'pricePercent': 100,
        'stock': <Map<String, dynamic>>[],
      },
    ]);
    state.merchantActiveProfileId = 'merchant_default';
    for (final plane in ['sacro', 'affogato', 'postea']) {
      sheet['selectedPlaneId'] = plane;
      probe.switchMerchantProfile('merchant_lost_town');
      expect(state.merchantActiveProfileId, 'merchant_default');
      probe.switchMerchantProfile('merchant_lost_town_upper');
      expect(state.merchantActiveProfileId, 'merchant_default');
    }
    sheet['selectedPlaneId'] = 'mezzano';
    probe.switchMerchantProfile('merchant_lost_town');
    expect(state.merchantActiveProfileId, 'merchant_lost_town');
    final profile = (state.merchantProfiles as List).cast<Map>().firstWhere(
      (e) => e['id'] == 'merchant_lost_town',
    );
    expect(profile['planeId'], 'mezzano');
    sheet['selectedPlaneId'] = 'postea';
    probe.merchantOfferIds();
    expect(state.merchantActiveProfileId, 'merchant_default');
    final retained = (profile['stock'] as List).cast<Map>().firstWhere(
      (e) => e['id'] == 'qa_city_unique_item',
    );
    expect(retained['custom'], {'retained': true});
    expect(retained['cost'], 11);
    expect(retained['remaining'], 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
