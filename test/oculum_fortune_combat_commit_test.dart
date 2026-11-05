import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'package:oculum/widgets/oculum_attack_planner.dart';

import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

class _FortuneCombatTransport extends OculumRealtimeService {
  _FortuneCombatTransport()
    : super(
        roomId: 'fortune-commit',
        playerName: 'Defender',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      );

  @override
  bool get isConnected => true;

  final sent = <(String, Map<String, dynamic>)>[];

  @override
  Future<bool> sendCombatEvent(
    String event,
    Map<String, dynamic> payload,
  ) async {
    sent.add((event, Map<String, dynamic>.from(payload)));
    return true;
  }
}

Future<(dynamic, OculumPerformanceProbe, _FortuneCombatTransport)> _mount(
  WidgetTester tester,
) async {
  final (state, p) = await fixtures.mountFight(tester);
  state.fortuna = 3;
  state.proponiFortunaDopoTiro = true;
  state.modalitaMaster = false;
  state.isMasterHost = false;
  state.sonoCoMaster = false;
  state.livelloController.text = '0';
  state.oculumController.text = '0';
  state.currentOculumController.text = '0';
  state.activeStructuredEffects.clear();
  state.activeConditions.clear();
  state.titoli.clear();
  state.arti.clear();
  state.skills.clear();
  state.inventario.clear();
  p.invalidateDerivedCaches();
  final transport = _FortuneCombatTransport();
  state.realtimeService = transport;
  state.realtimeVisibleInitiativeSnapshot = <String, dynamic>{
    'encounterId': 'fortune-fight',
    'campaignId': state.activeCampaignId,
    'round': 1,
    'activeIndex': 0,
    'tokens': [
      <String, dynamic>{
        'id': p.ownerTag(),
        'sheetTag': p.ownerTag(),
        'name': 'Defender',
        'status': 'active',
        'currentHp': 100,
        'maxHp': 100,
        'actionUsed': false,
        'reactionMax': 1,
        'reactionUsed': 0,
      },
    ],
  };
  // The authenticated attacker is deliberately absent from the turn snapshot.
  state.realtimeUsers = <Map<String, dynamic>>[
    {
      'sessionId': 'late-attacker-session',
      'activeSheetTag': 'LATE-ATTACKER',
      'role': 'player',
    },
  ];
  return (state, p, transport);
}

Map<String, dynamic> _receiveAttack(
  dynamic state,
  OculumPerformanceProbe p,
  String id, {
  int attack = 10,
}) {
  p.receiveCombat('combat_attack', {
    'id': id,
    'scope': p.permissionScope,
    'campaignId': state.activeCampaignId,
    'encounterId': 'fortune-fight',
    'sessionId': 'late-attacker-session',
    'senderTag': 'LATE-ATTACKER',
    'senderRole': 'player',
    'sourceTag': 'LATE-ATTACKER',
    'sourceName': 'Late attacker',
    'targetTag': p.ownerTag(),
    'targetName': 'Defender',
    'choice': 'vc',
    'attack': attack,
    'natural': 10,
    'damage': 0,
    'element': 'fisico',
    'level': 0,
    'grade': 0,
    'difficulty': 'normale',
  });
  final request = state.onlineCombatRequests[id];
  expect(request, isNotNull, reason: 'Presence authenticates the late source.');
  return request as Map<String, dynamic>;
}

Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  // The Oculum background keeps animating. Wait for this dialog's contents,
  // rather than waiting for every scheduled frame in the application to stop.
  await tester.pump();
  for (var attempt = 0; attempt < 20 && finder.evaluate().isEmpty; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pump(const Duration(milliseconds: 400));
  expect(finder, findsOneWidget);
}

Future<void> _openCounterRoll(
  WidgetTester tester,
  dynamic state,
  OculumPerformanceProbe p,
) async {
  // Exercise the actual free-reaction control and planner, rather than a
  // prepared roll or a unit copy of the authorization predicate.
  showDialog<void>(
    context: state.context,
    builder: (_) => AlertDialog(
      content: SizedBox(
        width: 1000,
        height: 600,
        child: SingleChildScrollView(child: p.combatRequestsPanel()),
      ),
    ),
  );
  final reaction = find.widgetWithText(
    FilledButton,
    'Reazione gratuita · contrattacco critico',
  );
  await _waitFor(tester, reaction);
  await tester.ensureVisible(reaction);
  await tester.tap(reaction);
  await _waitFor(tester, find.byType(OculumAttackPlanner));
  await tester.tap(find.text('Dichiara e tira'));
  await _waitFor(tester, find.text('Continua senza spendere'));
}

Future<void> _confirmLuck(WidgetTester tester, int spend) async {
  for (var index = 0; index < spend; index++) {
    await tester.tap(find.byTooltip('Aumenta spesa'));
    await tester.pump();
  }
  await tester.tap(
    find.text(spend == 0 ? 'Continua senza spendere' : 'Spendi $spend'),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  for (final spend in [0, 1]) {
    testWidgets(
      'Luck confirmation keeps the authenticated late counter target ($spend spent)',
      (tester) async {
        final (state, p, transport) = await _mount(tester);
        final request = _receiveAttack(state, p, 'late-counter-$spend');
        await tester.runAsync(
          () => p.resolveCombatDefense(request, 'cm', 100, natural: 10),
        );
        expect(request['status'], 'resolved');
        expect(request['freeReaction'], true);
        expect(p.attackTargetTags(), isEmpty);
        transport.sent.clear();
        await _openCounterRoll(tester, state, p);
        expect(request['reactionUsed'], true);
        final claimedId = request['counterAttackId'];
        await _confirmLuck(tester, spend);

        final attacks = transport.sent.where((e) => e.$1 == 'combat_attack');
        expect(attacks, hasLength(1));
        expect(attacks.single.$2['id'], claimedId);
        expect(attacks.single.$2['targetTag'], 'LATE-ATTACKER');
        expect(attacks.single.$2['reactionOf'], request['id']);
        expect(attacks.single.$2['forcedCritical'], true);
        expect(state.fortuna, 3 - spend);
        final actor = state.realtimeVisibleInitiativeSnapshot['tokens'].single;
        expect(actor['actionUsed'], false);
        expect(actor['reactionUsed'], 0);
        await closeFixture(tester, p);
      },
    );
  }

  for (final revoked in [
    'removed',
    'replaced',
    'reaction revoked',
    'target fled',
  ]) {
    testWidgets(
      'Luck cannot commit a late counter whose authorization is $revoked',
      (tester) async {
        final (state, p, transport) = await _mount(tester);
        final request = _receiveAttack(state, p, 'revoked-counter');
        await tester.runAsync(
          () => p.resolveCombatDefense(request, 'cm', 100, natural: 10),
        );
        transport.sent.clear();
        await _openCounterRoll(tester, state, p);
        if (revoked == 'removed') {
          state.onlineCombatRequests.remove(request['id']);
        } else if (revoked == 'replaced') {
          state.onlineCombatRequests[request['id']] = Map<String, dynamic>.from(
            request,
          );
        } else if (revoked == 'reaction revoked') {
          request['freeReaction'] = false;
        } else {
          state.realtimeVisibleInitiativeSnapshot['tokens']
              .add(<String, dynamic>{
                'id': 'LATE-ATTACKER',
                'sheetTag': 'LATE-ATTACKER',
                'name': 'Late attacker',
                'status': 'fled',
              });
        }
        await _confirmLuck(tester, 1);

        expect(state.fortuna, 3);
        expect(transport.sent.where((e) => e.$1 == 'combat_attack'), isEmpty);
        expect(
          (state.logEventi as List).where(
            (event) => '$event'.contains('[FORTUNA MAGICA] Attacco'),
          ),
          isEmpty,
        );
        await closeFixture(tester, p);
      },
    );
  }

  for (final change in ['unchanged', 'removed', 'replaced']) {
    testWidgets(
      'defense Luck validates the exact pending request after the popup ($change)',
      (tester) async {
        final (state, p, transport) = await _mount(tester);
        // High attack and zero damage avoid unrelated critical rewards and
        // damage-layer randomness while retaining the real defense pipeline.
        final request = _receiveAttack(
          state,
          p,
          'defense-identity',
          attack: 10000000,
        );
        transport.sent.clear();
        final hpBefore = p.currentHp();
        final defending = p.defendCombat(request, 'cm');
        await _waitFor(tester, find.text('Continua senza spendere'));
        if (change == 'removed') {
          state.onlineCombatRequests.remove(request['id']);
        } else if (change == 'replaced') {
          state.onlineCombatRequests[request['id']] = Map<String, dynamic>.from(
            request,
          );
        }
        await _confirmLuck(tester, 1);
        await defending;

        expect(state.fortuna, change == 'unchanged' ? 2 : 3);
        expect(
          request['status'],
          change == 'unchanged' ? 'resolved' : 'pending',
        );
        expect(request['defense'], change == 'unchanged' ? isNotNull : isNull);
        expect(
          transport.sent.where((e) => e.$1 == 'combat_defense'),
          change == 'unchanged' ? hasLength(1) : isEmpty,
        );
        expect(p.currentHp(), hpBefore);
        if (change == 'replaced') {
          expect(
            state.onlineCombatRequests[request['id']]['status'],
            'pending',
          );
          expect(state.onlineCombatRequests[request['id']]['defense'], isNull);
        }
        await closeFixture(tester, p);
      },
    );
  }
}
