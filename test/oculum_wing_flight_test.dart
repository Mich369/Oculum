import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  testWidgets('closing one board lands only its own winged participants', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    final sheets = state.schedePersonaggio as List;
    final participant = sheets.first as Map<String, dynamic>;
    final other = Map<String, dynamic>.from(participant)
      ..['id'] = 'OTHER-WINGED-SHEET'
      ..['sheetTag'] = 'OTHER-WINGED-SHEET'
      ..['planarRuntime'] = {
        'wingFlight': {
          'airborne': true,
          'usedTurns': 1,
          'encounterId': 'encounter_2',
        },
      };
    participant['planarRuntime'] = <String, dynamic>{
      'wingFlight': {
        'airborne': true,
        'usedTurns': 2,
        'paidThisTurn': true,
        'encounterId': state.selectedMasterInitiativeGroupId,
      },
    };
    sheets.add(other);

    probe.clearMasterBoardForTest();
    final ownFlight =
        ((sheets[0] as Map)['planarRuntime'] as Map)['wingFlight'] as Map;
    final otherFlight =
        ((sheets[1] as Map)['planarRuntime'] as Map)['wingFlight'] as Map;
    expect(ownFlight['airborne'], isNull);
    expect(ownFlight['usedTurns'], 2);
    expect(otherFlight, {
      'airborne': true,
      'usedTurns': 1,
      'encounterId': 'encounter_2',
    });

    await closeFixture(tester, probe);
  });

  test('effective Riflessi 50 is the expert threshold', () {
    expect(oculumWingFlightIsExpert(49), isFalse);
    expect(oculumWingFlightIsExpert(50), isTrue);
    final exhausted = <String, dynamic>{'usedTurns': 3};
    expect(oculumPayWingFlightTurn(exhausted, unlimited: false), isFalse);
    expect(oculumPayWingFlightTurn(exhausted, unlimited: true), isTrue);
    expect(exhausted['usedTurns'], 3);
  });

  testWidgets('manifestation and a new fight cannot refill paid flight turns', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    state.schedePersonaggio[0]['monsterBookSourceId'] = 'arcangelo';
    final entry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: Material(
          child: Align(
            alignment: Alignment.topCenter,
            child: probe.wingFlightControls(),
          ),
        ),
      ),
    );
    Overlay.of(tester.element(find.byType(OculumHomePage))).insert(entry);
    await tester.pump();
    Map flight() =>
        ((state.schedePersonaggio[0]['planarRuntime'] as Map)['wingFlight']
            as Map);
    Future<void> tap(String label) async {
      await tester.tap(find.widgetWithText(OutlinedButton, label));
      await tester.pump();
    }

    await tap('Prendi il volo');
    expect(flight()['usedTurns'], 1);
    final token = (state.masterInitiativeTokens as List).first as Map;
    expect(token['actionUsed'], isNot(true));
    final wing =
        probe.precisionParts().firstWhere(
              (part) => part['group'] == 'wings',
            )['id']
            as String;
    expect(probe.anatomicalTargetAvailable(wing), isTrue);
    await tap('Ritrai ali');
    expect(flight()['airborne'], isNull);
    expect(probe.anatomicalTargetAvailable(wing), isFalse);
    await probe.wingHit({'id': 'already-aimed', 'targetBodyPart': wing});
    expect(probe.flightBonus(4), 4);
    await tap('Manifesta ali');
    await tap('Prendi il volo');
    expect(flight()['usedTurns'], 1);

    probe.tickPlanar();
    probe.tickPlanar();
    expect(flight()['usedTurns'], 3);
    expect(flight()['airborne'], isTrue);
    probe.tickPlanar();
    expect(flight()['airborne'], isNull);
    probe.finishPlanarFight();
    expect(flight()['usedTurns'], 3);
    probe.referenceRest(long: false);
    expect(flight()['usedTurns'], isNull);

    entry.remove();
    entry.dispose();
    await closeFixture(tester, probe);
  });
}
