import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

class _PlayerTransport extends OculumRealtimeService {
  _PlayerTransport()
    : super(
        roomId: 'own-power',
        playerName: 'Player',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      ) {
    authenticatedRole = 'player';
  }
  @override
  bool get isConnected => true;
  @override
  Future<bool> sendCombatEvent(
    String event,
    Map<String, dynamic> payload,
  ) async => true;
}

void _player(dynamic state) {
  state.modalitaMaster = false;
  state.isMasterHost = false;
  state.sonoCoMaster = false;
}

void main() {
  testWidgets(
    'own PT preference stays independent through real sheet switches and exported JSON reload',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      _player(state);
      final other =
          Map<String, dynamic>.from(jsonDecode(jsonEncode(p.snapshot())) as Map)
            ..['id'] = 'SecondOcu:3690PWR2'
            ..['sheetTag'] = 'SecondOcu:3690PWR2'
            ..['nome'] = 'Secondo'
            ..['planarRuntime'] = <String, dynamic>{};
      state.schedePersonaggio.add(other);
      expect(p.ownPowerVisible, false);
      p.showOwnPower(true);
      final exported = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(p.snapshot())) as Map,
      );
      expect((exported['planarRuntime'] as Map)['showOwnTotalPower'], true);
      await p.switchOwnedSheet(1);
      expect(p.ownPowerVisible, false);
      p.showOwnPower(false);
      await p.switchOwnedSheet(0);
      expect(p.ownPowerVisible, true);
      p.showOwnPower(false);
      state.schedePersonaggio[state.schedaCorrente] = Map<String, dynamic>.from(
        exported,
      );
      p.load(exported);
      expect(p.ownPowerVisible, true);
      expect(p.knownPower('ENEMY'), isEmpty);
      expect(p.planarStateSnapshot()['knownOwnPower'], isNull);
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'player own toggle never reveals enemy or shared-profile PT even with a local Master flag',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      _player(state);
      state.realtimeService = _PlayerTransport();
      state.modalitaMaster = true;
      state.masterInitiativeTokens[1]['totalPower'] = 987;
      p.recordCurrentEncounter();
      p.showOwnPower(true);
      final ownValue = p.totalPower(state.schedaCorrente);
      final widgets = [p.powerBadge(p.ownerTag()), p.powerBadge('ENEMY')];
      expect(p.knownPower('ENEMY'), isEmpty);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Column(children: widgets)),
        ),
      );
      expect(find.text('Potenza $ownValue'), findsOneWidget);
      expect(find.text('Potenza 987'), findsNothing);
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'Master bypasses personal visibility and party PT marks unknown linked profiles as partial',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      p.showOwnPower(false);
      state.modalitaMaster = true;
      state.schedePersonaggio[0]['inMasterParty'] = true;
      state.schedePersonaggio[0]['countsForPartyStats'] = true;
      final unknown =
          Map<String, dynamic>.from(jsonDecode(jsonEncode(p.snapshot())) as Map)
            ..['id'] = 'UnknownOcu:3690PWR3'
            ..['sheetTag'] = 'UnknownOcu:3690PWR3'
            ..['inMasterParty'] = true
            ..['countsForPartyStats'] = true
            ..['resilienza'] = '?'
            ..['volonta'] = '?'
            ..['materia'] = '?'
            ..['oculum'] = '?';
      for (final key in [
        'totalPower',
        'derivedTotalPower',
        'derivedRewardTotalPower',
        'statsTotal',
        'rewardPermanentCoreStats',
        'derivedCoreStats',
        'derivedResilienzaTotal',
        'derivedVolontaTotal',
        'derivedMateriaTotal',
        'derivedOculumTotal',
      ]) {
        unknown.remove(key);
      }
      state.schedePersonaggio.add(unknown);
      state.masterInitiativeTokens[1]['totalPower'] = 987;
      p.recordCurrentEncounter();
      final knownPower = p.totalPower(0);
      final summary = p.partyDisplayPower();
      expect(summary.total, knownPower);
      expect(summary.known, 1);
      expect(summary.unknown, 1);
      final widgets = [
        p.powerBadge(p.ownerTag()),
        p.powerBadge('ENEMY'),
        p.partyDisplayPowerSummary(),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Column(children: widgets)),
        ),
      );
      expect(find.text('Potenza $knownPower'), findsOneWidget);
      expect(find.text('Potenza 987'), findsOneWidget);
      expect(find.textContaining('parziale'), findsOneWidget);
      await closeFixture(tester, p);
    },
  );
}
