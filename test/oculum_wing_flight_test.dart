import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

Future<OverlayEntry> mountWingControls(
  WidgetTester tester,
  OculumPerformanceProbe probe,
) async {
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
  return entry;
}

Future<void> tapWingControl(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(OutlinedButton, label));
  await tester.pump();
}

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
    expect(probe.flightBonus(4), 0);
    await tap('Manifesta ali');
    expect(probe.flightBonus(4), 4);
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

  testWidgets('innate Nuvì wings can retract and restore flight', (tester) async {
    final (state, probe) = await mountFight(tester);
    state.schedePersonaggio[0]['monsterBookSourceId'] = 'nuvi';
    final entry = await mountWingControls(tester, probe);
    final wings = probe.precisionParts().where(
      (part) => part['group'] == 'wings',
    );
    expect(wings, hasLength(4));
    bool takeoffEnabled() => tester
        .widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Prendi il volo'),
        )
        .enabled;

    expect(takeoffEnabled(), isTrue);
    expect(probe.flightBonus(3), 3);
    await tapWingControl(tester, 'Ritrai ali');
    expect(takeoffEnabled(), isFalse);
    expect(probe.flightBonus(3), 0);
    for (final wing in wings) {
      expect(probe.anatomicalTargetAvailable(wing['id'] as String), isFalse);
    }
    await tapWingControl(tester, 'Manifesta ali');
    expect(takeoffEnabled(), isTrue);
    expect(probe.flightBonus(3), 3);
    for (final wing in wings) {
      expect(probe.anatomicalTargetAvailable(wing['id'] as String), isTrue);
    }

    entry.remove();
    entry.dispose();
    await closeFixture(tester, probe);
  });

  testWidgets('retracting Angelica wings refunds the originating timed cooldown', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    state.schedePersonaggio[0]['monsterBookSourceId'] =
        'aberrazione_oro_marmo_intermedia_angelica';
    final entry = await mountWingControls(tester, probe);
    final wings = probe
        .precisionParts()
        .where((part) => part['group'] == 'wings')
        .map((part) => part['id'] as String)
        .toList();
    expect(wings, ['wings_1', 'wings_2']);
    expect(wings.every(probe.anatomicalTargetAvailable), isTrue);

    List<CharacterSkill> skills() =>
        (state.skills as List).cast<CharacterSkill>();
    for (final id in ['flight', 'other']) {
      skills().add(
        CharacterSkill(
          id: id,
          nome: 'Ali temporanee',
          tipo: 'supporto',
          costo: '',
          cooldown: '',
          descrizione: '',
          forme: [
            CharacterSkillForm(
              nome: 'Forma 1',
              cooldownStrutturato: OculumAbilityCooldown(amount: 5),
            ),
          ],
        ),
      );
    }
    OculumAbilityCooldown cooldown(String id) =>
        skills()
            .firstWhere((skill) => skill.id == id)
            .forme
            .first
            .cooldownStrutturato!;

    void activateTimedWings(int duration) {
      final sourceCooldown = cooldown('flight');
      sourceCooldown.remaining = 0;
      probe.applyEffects(
        [
          OculumStructuredEffect(
            id: 'temporary_wings',
            type: 'planar',
            target: 'flight',
            valueExpression: '3',
            duration: '$duration',
          ),
        ],
        source: 'Ali temporanee',
        sourceCooldown: sourceCooldown,
      );
      expect(sourceCooldown.activate(), isTrue);
    }

    cooldown('other').remaining = 5;
    activateTimedWings(2);
    probe.load(probe.snapshot());
    await tester.pump();
    await tapWingControl(tester, 'Ritrai ali');
    expect(cooldown('flight').remaining, 3);
    expect(cooldown('other').remaining, 5);
    expect(probe.planarStateSnapshot()['flightTurns'], isNull);
    expect(wings.any(probe.anatomicalTargetAvailable), isFalse);
    final projection = probe.snapshot()['faunaPublic'] as Map;
    expect(projection['wingFlightWingsVisible'], isFalse);

    await tapWingControl(tester, 'Manifesta ali');
    expect(wings.every(probe.anatomicalTargetAvailable), isTrue);
    activateTimedWings(8);
    await tapWingControl(tester, 'Ritrai ali');
    expect(cooldown('flight').remaining, 0);

    await tapWingControl(tester, 'Manifesta ali');
    activateTimedWings(1);
    probe.tickPlanar();
    expect(probe.planarStateSnapshot()['flightTurns'], isNull);
    await tapWingControl(tester, 'Ritrai ali');
    expect(cooldown('flight').remaining, 5);

    entry.remove();
    entry.dispose();
    await closeFixture(tester, probe);
  });
}
