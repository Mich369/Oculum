import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;
import 'oculum_protection_wear_test.dart' show prepareProtectionFixture;

Map<String, dynamic> _pairedOffer(
  dynamic state,
  OculumPerformanceProbe probe, {
  String passengerTag = 'OTHER',
}) {
  final tokens = state.masterInitiativeTokens as List;
  final carrier = tokens.first as Map;
  final passenger = tokens[2] as Map;
  carrier['mapTokenId'] = 'carrier-map';
  passenger
    ..['id'] = passengerTag
    ..['sheetTag'] = passengerTag
    ..['side'] = carrier['side']
    ..['mapTokenId'] = 'passenger-map';
  tokens.add({
    'id': 'RESERVE',
    'sheetTag': 'RESERVE',
    'name': 'Riserva',
    'side': carrier['side'],
    'status': 'ready',
  });
  probe.recordCurrentEncounter();
  final offer = <String, dynamic>{
    'id': 'paired-wing-offer',
    'kind': 'escape',
    'status': 'pending',
    'sourceTag': probe.ownerTag(),
    'sourceSide': carrier['side'],
    'sourceName': 'Portatore',
    'scope': probe.permissionScope,
    'encounterId': 'encounter_1',
    'fightInstanceId': carrier['fightInstanceId'],
    'passengerTag': passengerTag,
    'passengerFightInstanceId': passenger['fightInstanceId'],
    'flightPassengerAuthorized': true,
    'natural': 20,
    'total': 40,
    'answers': <String, dynamic>{},
  };
  state.onlineCombatRequests[offer['id']] = offer;
  return offer;
}

Map<String, dynamic> _result(Map<String, dynamic> offer) => {
  'id': 'escape-result:${offer['id']}',
  'stage': 'result',
  'escapeId': offer['id'],
  'sourceTag': offer['sourceTag'],
  'targetTag': offer['sourceTag'],
  'scope': offer['scope'],
  'encounterId': offer['encounterId'],
  'passengerTag': offer['passengerTag'],
  'success': true,
  'critical': true,
};

void main() {
  testWidgets('unverified flight keeps the pair and retries the same offer', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    final offer = _pairedOffer(state, probe);
    state.onlineCombatRequests.remove(offer['id']);
    probe.escapeEvent({...offer, 'stage': 'offer'});
    final record = state.onlineCombatRequests[offer['id']] as Map;
    final carrier = (state.masterInitiativeTokens as List).first as Map;
    final action = carrier['actionUsed'];
    final reactions = carrier['reactionUsed'];

    expect(record['flightPassengerAuthorized'], isNot(true));
    expect(record['passengerTag'], 'OTHER');
    expect(record['noticed'], isEmpty);
    expect(record['noticeRevision'], 1);
    final solo = _result(offer)..remove('passengerTag');
    probe.escapeEvent(solo);
    expect(record['status'], 'pending');
    expect(carrier['outsideFight'], isNot(true));

    probe.escapeEvent({
      ...solo,
      'id': 'check-same-offer',
      'stage': 'flight_retry',
      'noticeRevision': 1,
    });
    expect(record['noticeRevision'], 2);
    expect(record['passengerTag'], 'OTHER');
    expect(carrier['actionUsed'], action);
    expect(carrier['reactionUsed'], reactions);
    await closeFixture(tester, probe);
  });

  testWidgets('paired escape checks the bound passenger and moves both once', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    final offer = _pairedOffer(state, probe);
    final result = _result(offer);
    final tokens = state.masterInitiativeTokens as List;
    probe.escapeEvent({...result, 'passengerTag': 'ENEMY'});
    expect(offer['status'], 'pending');
    expect(tokens.first['outsideFight'], isNot(true));
    probe.escapeEvent({...result, 'sourceTag': 'OTHER'});
    expect(offer['status'], 'pending');

    final passenger = tokens[2] as Map;
    final originalFight = passenger['fightInstanceId'];
    passenger['fightInstanceId'] = 'another-fight';
    probe.escapeEvent(result);
    expect(offer['status'], 'pending');
    passenger['fightInstanceId'] = originalFight;

    probe.escapeEvent(result);
    expect(offer['status'], 'escaped');
    expect(tokens.first['outsideFight'], isTrue);
    expect(tokens.first['outsideCritical'], isTrue);
    expect(passenger['outsideFight'], isTrue);
    expect(passenger['outsideCritical'], isFalse);
    passenger['outsideFirstPending'] = false;
    probe.escapeEvent(result);
    expect(passenger['outsideFirstPending'], isFalse);
    await closeFixture(tester, probe);
  });

  testWidgets(
    'a critical interception grounds both without a second wing fall',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      prepareProtectionFixture(state, probe);
      state.resilienzaController.text = '40';
      probe.setResourceCurrent('resilienza', 40);
      final carrier = probe.snapshot();
      state.schedePersonaggio[0]['planarRuntime'] = <String, dynamic>{
        ...Map<String, dynamic>.from(carrier['planarRuntime'] as Map),
        'lastWingFallInterceptionId': 'interception',
      };
      probe.saveSheet();
      expect(
        probe.planarStateSnapshot()['lastWingFallInterceptionId'],
        'interception',
      );
      final carrierHp = probe.currentHp();
      state.schedePersonaggio.add({
        ...carrier,
        'id': 'OTHER',
        'sheetTag': 'OTHER',
        'nome': 'Passeggero',
        'currentHp': '100',
        'partialAwakeningHalfHpTriggered': true,
        'planarRuntime': <String, dynamic>{},
      });
      probe.ensureSheetTags();
      final passengerTag = state.schedePersonaggio[1]['sheetTag'] as String;
      final offer = _pairedOffer(state, probe, passengerTag: passengerTag);
      final mapTokens = state.localMapTokens as List<Map<String, dynamic>>;
      final carrierMap = <String, dynamic>{
        'id': 'carrier-map',
        'x': .25,
        'y': .75,
        'elevationMeters': 8.0,
      };
      final passengerMap = <String, dynamic>{
        'id': 'passenger-map',
        'x': .4,
        'y': .6,
        'elevationMeters': 8.0,
      };
      mapTokens.addAll([carrierMap, passengerMap]);

      Map<String, dynamic> interception(String id, {required bool critical}) =>
          {
            'id': id,
            'sourceTag': 'ENEMY',
            'targetTag': offer['sourceTag'],
            'escapeReactionOf': offer['id'],
            'outcome': 'full',
            'forcedCritical': critical,
            'attack': critical ? 40 : 32,
            'defense': 20,
            'choice': critical ? 'vc' : 'precisione',
            'damageReceipt': {'hpLost': 4},
          };
      probe.escapeDamage(interception('precision', critical: false));
      expect((offer['answers'] as Map)['ENEMY']['stops'], isTrue);
      expect(
        (offer['answers'] as Map)['ENEMY']['criticalInterception'],
        isNull,
      );
      probe.escapeDamage({
        ...interception('protected', critical: true),
        'criticalShieldProtected': true,
      });
      expect((offer['answers'] as Map)['ENEMY']['stops'], isFalse);
      probe.escapeDamage(interception('interception', critical: true));
      expect(
        (offer['answers'] as Map)['ENEMY']['criticalInterception'],
        isTrue,
      );
      final normal = interception('regular-critical', critical: true)
        ..remove('escapeReactionOf')
        ..addAll({'scope': offer['scope'], 'encounterId': 'another-board'});
      probe.escapeDamage(normal);
      expect(offer['flightHostileCriticalId'], isNull);
      probe.escapeDamage({
        ...normal,
        'id': 'regular-critical-in-fight',
        'encounterId': offer['encounterId'],
      });
      expect(offer['flightHostileCriticalId'], 'regular-critical-in-fight');

      final result = {
        ..._result(offer),
        'success': false,
        'flightFallAttackId': 'interception',
        'flightFallCarrierRoll': 60,
        'flightFallPassengerRoll': 60,
      };
      state.pawnPendingDamage = <String, dynamic>{'requestId': 'previous-pawn'};
      probe.escapeEvent(result);
      await tester.pump(const Duration(milliseconds: 1));
      expect(offer['status'], 'failed');
      expect(
        (state.masterInitiativeTokens as List).first['outsideFight'],
        isNot(true),
      );
      expect(
        (state.masterInitiativeTokens as List)[2]['outsideFight'],
        isNot(true),
      );
      expect(carrierMap['elevationMeters'], 0.0);
      expect(passengerMap['elevationMeters'], 0.0);
      expect(passengerMap['x'], .25);
      expect(passengerMap['y'], .75);
      expect(probe.currentHp(), carrierHp);
      expect(state.schedePersonaggio[1]['currentHp'], '100');
      expect(probe.planarStateSnapshot()['wingEscapeFallReceipts'], isNull);
      expect(offer['wingEscapeFall']['rolls'], {
        offer['sourceTag']: 60,
        passengerTag: 60,
      });

      state.masterInitiativeGroups.add(<String, dynamic>{
        'id': 'another-board',
        'name': 'Altro scontro',
        'tokens': <Map<String, dynamic>>[],
      });
      probe.selectEncounter('another-board');
      state.pawnPendingDamage = <String, dynamic>{};
      probe.retryWingEscapeFalls();
      await tester.pump(const Duration(milliseconds: 1));
      expect(state.selectedMasterInitiativeGroupId, 'another-board');
      expect(probe.currentTag(), offer['sourceTag']);
      expect(probe.currentHp(), carrierHp);
      final passenger = state.schedePersonaggio[1] as Map;
      final passengerHp = int.parse('${passenger['currentHp']}');
      expect(
        passengerHp,
        lessThan(100),
        reason:
            'Tag ${passenger['sheetTag']}, coda '
            '${state.onlineCombatRequests[offer['id']]?['wingEscapeFall']}, '
            'ricevuta ${passenger['planarRuntime']?['wingEscapeFallReceipts']}, '
            'log ${(passenger['logEventi'] as List?)?.take(3).toList()}.',
      );
      expect(passenger['planarRuntime']['wingEscapeFallReceipts'], [
        result['id'],
      ]);
      expect(probe.planarStateSnapshot()['wingEscapeFallReceipts'], [
        result['id'],
      ]);
      probe.escapeEvent(result);
      await tester.pump();
      expect(probe.currentHp(), carrierHp);
      expect(
        int.parse('${state.schedePersonaggio[1]['currentHp']}'),
        passengerHp,
      );
      expect(probe.planarStateSnapshot()['wingEscapeFallReceipts'], [
        result['id'],
      ]);
      await closeFixture(tester, probe);
    },
  );
}
