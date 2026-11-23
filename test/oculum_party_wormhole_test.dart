import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  test('confirmed wormhole thresholds cover the whole natural die', () {
    expect(oculumWormholeOutcome(1), 'negativa_eccezionale');
    for (var die = 2; die <= 10; die++) {
      expect(oculumWormholeOutcome(die), 'negativa');
    }
    for (var die = 11; die <= 19; die++) {
      expect(oculumWormholeOutcome(die), 'positiva');
    }
    expect(oculumWormholeOutcome(20), 'positiva_eccezionale');
  });

  testWidgets(
    'one shared destination includes the party and survives saved JSON without rerolling',
    (tester) async {
      final (state, probe) = await fixtures.mountFight(tester);
      state.schedePersonaggio[0]['selectedPlaneId'] = 'deserto_divoratore';
      state.schedePersonaggio[0]['inMasterParty'] = true;
      final patient =
          jsonDecode(jsonEncode(probe.snapshot())) as Map<String, dynamic>;
      state.schedePersonaggio.add({
        ...patient,
        'id': 'ALLY',
        'sheetTag': 'ALLY',
        'inMasterParty': true,
      });
      state.partyChestCampaigns.clear();
      expect(probe.enterPartyWormhole(20), isTrue);
      final transit = probe.partyWormhole!;
      expect(transit['participants'], hasLength(2));
      expect(transit['participants'], contains(probe.ownerTag()));
      expect(transit['outcome'], 'positiva_eccezionale');
      expect(probe.enterPartyWormhole(1), isFalse);
      expect(probe.partyWormhole!['dimensionId'], transit['dimensionId']);
      final restored =
          jsonDecode(jsonEncode(state.partyChestCampaigns))
              as Map<String, dynamic>;
      state.partyChestCampaigns.clear();
      state.partyChestCampaigns.addAll(
        restored.map(
          (key, value) =>
              MapEntry(key, Map<String, dynamic>.from(value as Map)),
        ),
      );
      state.schedaCorrente = 1;
      expect(transit['participants'], contains(probe.ownerTag()));
      expect(probe.partyWormhole!['dimensionId'], transit['dimensionId']);
      expect(probe.partyWormhole!['outcome'], 'positiva_eccezionale');
      probe.finishPartyWormhole();
      expect(probe.partyWormhole, isNull);
      await closeFixture(tester, probe);
    },
  );
}
