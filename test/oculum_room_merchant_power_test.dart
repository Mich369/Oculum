import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';

void main() {
  test(
    'empty room never silently connects to test or initializes authentication',
    () async {
      final statuses = <String>[];
      final service = OculumRealtimeService(
        roomId: '  ',
        playerName: 'Synthetic',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: statuses.add,
      );
      await service.connect();
      expect(service.normalizedRoomId, '');
      expect(service.requiresUserAction, true);
      expect(service.isConnected, false);
      expect(statuses.last, contains('codice stanza'));
      await service.disconnect();
      final codes = List.generate(
        1000,
        (_) => oculumFreshRoomCode(Random.secure()),
      );
      expect(codes.toSet(), hasLength(1000));
      expect(
        codes.every((c) => RegExp(r'^oculum_[a-f0-9]{16}$').hasMatch(c)),
        true,
      );
    },
  );

  test(
    'merchant power suitability changes recommendations without mutating stock or prices',
    () {
      final offers = <Map<String, dynamic>>[
        {
          'id': 'low',
          'kind': 'weapon',
          'name': 'Low',
          'recommendedPower': 40,
          'damage': 40,
          'cost': 100,
        },
        {
          'id': 'high',
          'kind': 'weapon',
          'name': 'High',
          'recommendedPower': 400,
          'damage': 400,
          'cost': 100,
        },
      ];
      int pick(int power) {
        var high = 0;
        final random = Random(2468);
        for (var i = 0; i < 2000; i++) {
          final result = oculumSelectMerchantOffers(
            offers,
            characterLevel: 5,
            characterTotalPower: power,
            budget: 500,
            count: 1,
            random: random,
          );
          if (result.single['id'] == 'high') high++;
        }
        return high;
      }

      expect(pick(40), lessThan(500));
      expect(pick(400), greaterThan(1500));
      expect(offers.map((o) => o['cost']), [100, 100]);
      expect(offers.map((o) => o['damage']), [40, 400]);
      expect(oculumMerchantPowerFit({'name': 'Bandage'}, 100), 1);
    },
  );
}
