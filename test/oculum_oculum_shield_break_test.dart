import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

class _ImpactTransport extends OculumRealtimeService {
  _ImpactTransport()
    : super(
        roomId: 'shield-impact-test',
        playerName: 'Player',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      ) {
    authenticatedRole = 'player';
  }

  final attacks = <Map<String, dynamic>>[];

  @override
  bool get isConnected => true;

  @override
  Future<bool> sendCombatEvent(
    String event,
    Map<String, dynamic> payload,
  ) async {
    if (event == 'combat_attack') attacks.add(Map.of(payload));
    return true;
  }
}

void _setShield(dynamic state, OculumPerformanceProbe probe, int value) {
  state.campaignDifficulty = 'normale';
  state.karmaController.text = '0';
  state.fortuna = 0;
  state.oculumController.text = '0';
  probe.setResourceCurrent('oculum', 0);
  for (final stat in state.hiddenEyeStats) {
    if (stat.id == 'fortuna') stat.unlocked = false;
    if (stat.id == 'resistenza') stat.valore = -100;
  }
  state.scudoOculumMaxController.text = '$value';
  state.scudoOculumController.text = '$value';
  state.scudoController.text = '0';
  state.scudoCriticoController.text = '0';
  state.hpTempController.text = '0';
  state.currentHpController.text = '100';
  probe.invalidateDerivedCaches();
}

bool _penaltyPending(OculumPerformanceProbe probe) =>
    (probe.snapshot()['planarRuntime']
        as Map?)?['oculumShieldBreakDefensePending'] ==
    true;

Future<void> _hitShield(OculumPerformanceProbe probe, int damage) =>
    probe.damageResolved(damage, bypassDefense: true);

void main() {
  testWidgets('partial shield damage and bypass do not arm defense penalty', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    state.masterInitiativeTokens.clear();
    state.masterInitiativeGroups.clear();
    _setShield(state, probe, 5);
    await _hitShield(probe, 2);
    expect(state.scudoOculumController.text, '3');
    expect(_penaltyPending(probe), isFalse);

    await probe.damageResolved(8, bypassDefense: true, bypassShields: true);
    expect(state.scudoOculumController.text, '3');
    expect(_penaltyPending(probe), isFalse);

    await _hitShield(probe, 3);
    expect(state.scudoOculumController.text, '0');
    expect(_penaltyPending(probe), isTrue);
    final saved =
        jsonDecode(jsonEncode(probe.snapshot())) as Map<String, dynamic>;
    state.schedePersonaggio[0] = saved;
    probe.load(saved);
    expect(_penaltyPending(probe), isTrue);

    await probe.rollSpecial('VC', 10, onResolved: (_, _) {});
    expect(_penaltyPending(probe), isTrue);
    Future<int> rollDefense() async {
      var effectiveBonus = 0;
      await probe.rollSpecial(
        'CM',
        10,
        onResolved: (natural, total) {
          effectiveBonus = total - probe.rollTotal(natural, 20, const [0]);
        },
      );
      return effectiveBonus;
    }

    final broken = await rollDefense();
    expect(_penaltyPending(probe), isFalse);
    expect(await rollDefense(), broken + 3);
    await _hitShield(probe, 1);
    expect(_penaltyPending(probe), isFalse);
    expect(tester.takeException(), isNull);
    await closeFixture(tester, probe);
  });

  testWidgets(
    'impact selects a non-ally and applies authenticated Oculum damage once',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      final source = probe.ownerTag();
      final transport = _ImpactTransport();
      state.realtimeService = transport;
      state.modalitaMaster = false;
      state.livelloController.text = '3';
      _setShield(state, probe, 5);
      state.realtimeVisibleInitiativeSnapshot = <String, dynamic>{
        'encounterId': 'shield-fight',
        'campaignId': state.activeCampaignId,
        'fightStarted': true,
        'activeIndex': 0,
        'round': 1,
        'tokens': <Map<String, dynamic>>[
          {
            'id': source,
            'name': 'Portatore',
            'side': 'party',
            'status': 'ready',
          },
          {'id': 'ALLY', 'name': 'Compagno', 'side': 'ally', 'status': 'ready'},
          {
            'id': '001-ENMY',
            'name': 'Nemico vicino',
            'side': 'enemy',
            'status': 'ready',
          },
          {
            'id': 'OTHER',
            'name': 'Nemico lontano',
            'side': 'enemy',
            'status': 'ready',
          },
        ],
      };
      await _hitShield(probe, 5);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(_penaltyPending(probe), isTrue);
      expect(find.widgetWithText(CheckboxListTile, 'Compagno'), findsNothing);
      expect(
        find.widgetWithText(CheckboxListTile, 'Nemico vicino'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(CheckboxListTile, 'Nemico lontano'),
        findsOneWidget,
      );
      expect(transport.attacks, isEmpty);
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Nemico vicino'));
      await tester.pump();
      await tester.tap(find.text('Applica ai selezionati'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      final attack = transport.attacks.single;
      expect(attack['oculumShieldBreakImpact'], isTrue);
      expect(attack['targetTag'], '001-ENMY');
      expect(attack['element'], 'oculum');
      expect(attack['damage'], 25);
      expect(attack['turnResourceSpends'], isNull);

      // Replay the packet on the recipient profile without editing a shared copy.
      final recipient = <String, dynamic>{
        ...probe.snapshot(),
        'id': '001-ENMY',
        'sheetTag': '001-ENMY',
        'nome': 'Nemico vicino',
        'planarRuntime': <String, dynamic>{},
      };
      state.schedePersonaggio[0] = recipient;
      probe.load(recipient);
      expect(probe.ownerTag(), '001-ENMY');
      _setShield(state, probe, 4);
      state.realtimeUsers = <Map<String, dynamic>>[
        {
          'sessionId': 'bearer-session',
          'activeSheetTag': source,
          'role': 'player',
        },
      ];
      state.onlineCombatRequests.clear();
      state.incomingDamagePresets['oculum'] = 'Immunità';
      final packet = {...attack, 'sessionId': 'bearer-session'};
      probe.receiveCombat('combat_attack', {...packet, 'sessionId': 'forged'});
      expect(state.onlineCombatRequests, isEmpty);
      probe.receiveCombat('combat_attack', packet);
      await tester.pump();
      expect(state.scudoOculumController.text, '4');
      expect(_penaltyPending(probe), isFalse);
      expect(state.onlineCombatRequests[packet['id']]['outcome'], 'full');

      state.incomingDamagePresets.clear();
      final hit = {...packet, 'id': 'valid-second-impact'};
      probe.receiveCombat('combat_attack', hit);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(state.scudoOculumController.text, '0');
      expect(_penaltyPending(probe), isTrue);
      final hp = state.currentHpController.text;
      probe.receiveCombat('combat_attack', hit);
      await tester.pump();
      expect(state.currentHpController.text, hp);
      expect(_penaltyPending(probe), isTrue);
      expect(find.text('Nessuno'), findsOneWidget);
      await tester.tap(find.text('Nessuno'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      final incoming = <String, dynamic>{
        'id': 'defend-after-impact',
        'scope': probe.permissionScope,
        'campaignId': state.activeCampaignId,
        'encounterId': 'shield-fight',
        'sessionId': 'bearer-session',
        'senderTag': source,
        'senderRole': 'player',
        'sourceTag': source,
        'sourceName': 'Portatore',
        'targetTag': '001-ENMY',
        'attack': -1000,
        'damage': 1,
        'choice': 'vc',
        'element': 'fisico',
        'difficulty': 'normale',
      };
      probe.receiveCombat('combat_attack', incoming);
      final request =
          state.onlineCombatRequests[incoming['id']] as Map<String, dynamic>;
      await probe.defendCombat(request, 'cm');
      final natural = request['defenseNatural'] as int;
      expect(
        request['defense'],
        probe.rollTotal(natural, 20, [probe.defenseCm() - 3]),
      );
      expect(_penaltyPending(probe), isFalse);
      expect(tester.takeException(), isNull);
      state.realtimeService = null;
      await transport.dispose();
      await closeFixture(tester, probe);
    },
  );
}
