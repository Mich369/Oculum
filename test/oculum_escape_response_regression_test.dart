import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/game/oculum_opposed_attack.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'package:oculum/widgets/oculum_attack_planner.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

class _EscapeTransport extends OculumRealtimeService {
  _EscapeTransport()
    : super(
        roomId: 'escape-replies',
        playerName: 'Eroe',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      ) {
    authenticatedRole = 'player';
  }
  final sent = <Map<String, dynamic>>[];
  @override
  bool get isConnected => true;
  @override
  Future<bool> sendCombatEvent(
    String event,
    Map<String, dynamic> payload,
  ) async {
    sent.add({'event': event, ...payload});
    return true;
  }
}

Future<
  (dynamic, OculumPerformanceProbe, _EscapeTransport?, Map<String, dynamic>)
>
prepareReply(WidgetTester tester, {required bool online}) async {
  final (state, p) = await fixtures.mountFight(tester);
  final ownTag = p.ownerTag();
  state.masterInitiativeRound = 2;
  state.masterInitiativeActiveIndex = 1;
  state.masterInitiativeTokens.first.addAll({
    'reactionPoolInitialized': true,
    'reactionPoolRound': 2,
    'reactionNormalFirstRoundLocked': false,
    'reactionMax': 1,
    'reactionUsed': 0,
    'reactionUsedRound': 2,
    'reactionFastMax': 0,
  });
  p.recordCurrentEncounter();
  final own = Map<String, dynamic>.from(p.combatTurnEncounter());
  own['tokens'] = (own['tokens'] as List)
      .map((t) => Map<String, dynamic>.from(t as Map))
      .toList();
  final other = <String, dynamic>{
    'id': 'unrelated',
    'encounterId': 'unrelated',
    'fightStarted': true,
    'round': 4,
    'activeIndex': 0,
    'tokens': [
      <String, dynamic>{
        'id': 'STRANGER',
        'sheetTag': 'STRANGER',
        'name': 'Estraneo',
        'status': 'active',
        'side': 'party',
      },
    ],
  };
  _EscapeTransport? transport;
  if (online) {
    transport = _EscapeTransport();
    state.modalitaMaster = false;
    state.isMasterHost = false;
    state.realtimeService = transport;
    state.realtimeEncounterSnapshots = <Map<String, dynamic>>[own, other];
    state.realtimeSelectedEncounterId = 'unrelated';
    state.realtimeVisibleInitiativeSnapshot = other;
  } else {
    state.masterInitiativeGroups.add(other);
    p.selectEncounter('unrelated');
  }
  final record = <String, dynamic>{
    'id': 'pending-escape',
    'kind': 'escape',
    'status': 'pending',
    'scope': p.permissionScope,
    'encounterId': own['encounterId'],
    'sourceTag': 'ENEMY',
    'targetTag': 'ENEMY',
    'sourceName': 'Fuggitivo',
    'sourceSide': 'enemy',
    'noticed': <String, dynamic>{ownTag: true},
    'answers': <String, dynamic>{},
    'movement': 3,
    'total': 20,
  };
  state.onlineCombatRequests[record['id']] = record;
  return (state, p, transport, record);
}

Future<OverlayEntry> showReplies(
  WidgetTester tester,
  OculumPerformanceProbe p,
) async {
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: 40,
      top: 80,
      width: 1000,
      child: Material(child: p.escapeRequests()),
    ),
  );
  Overlay.of(tester.element(find.byType(OculumHomePage))).insert(entry);
  await tester.pump();
  return entry;
}

void main() {
  for (final online in [false, true]) {
    for (final kind in ['block', 'help']) {
      testWidgets(
        'visible $kind reply selects the sheet fight and spends once ${online ? 'online' : 'offline'}',
        (tester) async {
          final (state, p, transport, record) = await prepareReply(
            tester,
            online: online,
          );
          final overlay = await showReplies(tester, p);
          final label = kind == 'block'
              ? 'Blocca · Azione/Reazione'
              : 'Aiuta · Azione/Reazione';
          expect(find.text(label), findsOneWidget);
          await tester.tap(find.text(label));
          await tester.pump();
          final encounter = p.combatTurnEncounter();
          expect(
            online
                ? state.realtimeSelectedEncounterId
                : state.selectedMasterInitiativeGroupId,
            'encounter_1',
          );
          final actor = (encounter['tokens'] as List).first as Map;
          expect(actor['reactionUsed'], 1);
          expect(encounter['activeIndex'], 1);
          expect(encounter['round'], 2);
          if (online) {
            final answer = transport!.sent.singleWhere(
              (e) => e['stage'] == 'answer',
            );
            expect(answer['answer'], kind);
            expect(answer['encounterId'], 'encounter_1');
            expect(answer['sourceTag'], p.ownerTag());
            expect((answer['turnResourceSpends'] as List), hasLength(1));
            expect(
              (answer['turnResourceSpends'] as List).single['sheetTag'],
              p.ownerTag(),
            );
          } else {
            final answer = (record['answers'] as Map)[p.ownerTag()] as Map;
            expect(answer['answer'], kind);
            if (kind == 'block') expect(answer['total'], isA<int>());
            await p.answerEscape(record, kind);
            expect(actor['reactionUsed'], 1);
          }
          if (kind == 'block') expect(state.dadoMostratoFacce, 20);
          overlay.remove();
          overlay.dispose();
          state.realtimeService = null;
          await closeFixture(tester, p);
        },
      );
    }
    testWidgets(
      'last aggressor blocks without spending or advancing ${online ? 'online' : 'offline'}',
      (tester) async {
        final (state, p, transport, record) = await prepareReply(
          tester,
          online: online,
        );
        record['lastAggressor'] = p.ownerTag();
        final overlay = await showReplies(tester, p);
        await tester.tap(find.text('Blocca · Reazione gratuita'));
        await tester.pump();
        final encounter = p.combatTurnEncounter();
        expect(encounter['activeIndex'], 1);
        expect(encounter['round'], 2);
        expect(((encounter['tokens'] as List).first as Map)['reactionUsed'], 0);
        if (online) {
          expect(transport!.sent.single['answer'], 'block');
          expect(transport.sent.single['turnResourceSpends'], isNull);
        } else {
          expect((record['answers'] as Map)[p.ownerTag()]['answer'], 'block');
        }
        overlay.remove();
        overlay.dispose();
        state.realtimeService = null;
        await closeFixture(tester, p);
      },
    );
    testWidgets(
      'free escape attack offers only the fleeing target ${online ? 'online' : 'offline'}',
      (tester) async {
        final (state, p, _, record) = await prepareReply(
          tester,
          online: online,
        );
        record['lastAggressor'] = p.ownerTag();
        final overlay = await showReplies(tester, p);
        await tester.tap(find.text('Colpisci · 1d16 · Reazione gratuita'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final planner = find.byType(OculumAttackPlanner);
        expect(planner, findsOneWidget);
        expect(
          find.descendant(of: planner, matching: find.text('Provocatore')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: planner, matching: find.text('Altro nemico')),
          findsNothing,
        );
        Navigator.of(tester.element(planner)).pop();
        await tester.pump(const Duration(milliseconds: 400));
        final encounter = p.combatTurnEncounter();
        expect(encounter['activeIndex'], 1);
        expect(((encounter['tokens'] as List).first as Map)['reactionUsed'], 0);
        expect(record['answers'], isEmpty);
        overlay.remove();
        overlay.dispose();
        state.realtimeService = null;
        await closeFixture(tester, p);
      },
    );
  }
  testWidgets('unavailable paid interception explains why and spends nothing', (
    tester,
  ) async {
    final (state, p, _, record) = await prepareReply(tester, online: false);
    final group = state.masterInitiativeGroups.first as Map;
    (group['tokens'] as List).first.addAll({
      'reactionUsed': 1,
      'reactionFastUsed': 1,
      'reactionFastTurnKey': '2',
    });
    final overlay = await showReplies(tester, p);
    await tester.tap(find.text('Blocca · Azione/Reazione'));
    await tester.pump();
    expect((record['answers'] as Map), isEmpty);
    expect(state.masterInitiativeActiveIndex, 1);
    expect(
      find.text(
        'Tiro non eseguito: controlla la partecipazione alla turnistica e le Azioni/Reazioni disponibili.',
      ),
      findsOneWidget,
    );
    overlay.remove();
    overlay.dispose();
    await closeFixture(tester, p);
  });
  testWidgets(
    'friendly last aggressor sees only valid help with the right cost',
    (tester) async {
      final (state, p, _, record) = await prepareReply(tester, online: false);
      record['sourceSide'] = 'party';
      record['lastAggressor'] = p.ownerTag();
      final overlay = await showReplies(tester, p);
      expect(find.text('Colpisci · 1d16 · Reazione gratuita'), findsNothing);
      expect(find.textContaining('Blocca ·'), findsNothing);
      expect(find.text('Aiuta · Azione/Reazione'), findsOneWidget);
      record['freeHelper'] = p.ownerTag();
      overlay.markNeedsBuild();
      await tester.pump();
      expect(find.text('Aiuta · Reazione gratuita'), findsOneWidget);
      await tester.tap(find.text('Aiuta · Reazione gratuita'));
      await tester.pump();
      final answer = (record['answers'] as Map)[p.ownerTag()] as Map;
      expect(answer['answer'], 'help');
      expect(answer['friendly'], isTrue);
      expect(answer['turnResourceSpends'], isNull);
      expect(state.masterInitiativeActiveIndex, 1);
      expect(state.masterInitiativeTokens.first['reactionUsed'], 0);
      overlay.remove();
      overlay.dispose();
      await closeFixture(tester, p);
    },
  );
  for (final online in [false, true]) {
    for (final choice in ['vc', 'riflessi']) {
      testWidgets(
        'escape $choice rolls real d16 with natural metadata ${online ? 'online' : 'offline'}',
        (tester) async {
          final (state, p, transport, record) = await prepareReply(
            tester,
            online: online,
          );
          record['lastAggressor'] = p.ownerTag();
          // Inspiration deterministically selects one of the die's two ends.
          // Either branch must retain the actual d16 natural and critical UI.
          state.ispirazioneOculumCriticoInAttesa = true;
          final opening = p.planAttack(escapeReactionOf: '${record['id']}');
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          final planner = find.byType(OculumAttackPlanner);
          expect(planner, findsOneWidget);
          Navigator.of(
            tester.element(planner),
          ).pop(OculumAttackPlan('ENEMY', choice, 'Intercettazione'));
          await opening;
          await tester.pump();
          final packet = (state.onlineCombatRequests as Map).values
              .whereType<Map>()
              .singleWhere((r) => r['escapeReactionOf'] == record['id']);
          expect(packet['dieFaces'], 16);
          expect(packet['natural'], isIn([1, 16]));
          expect(packet['natural'], inInclusiveRange(1, 16));
          expect(state.dadoMostratoFacce, 16);
          expect(state.tiroCriticoUno, packet['natural'] == 1);
          expect(state.tiroCriticoVenti, packet['natural'] == 16);
          expect(state.ispirazioneOculumCriticoInAttesa, isFalse);
          if (online) {
            final delivered = transport!.sent.singleWhere(
              (r) => r['event'] == 'combat_attack',
            );
            expect(delivered['dieFaces'], 16);
            expect(delivered['natural'], packet['natural']);
          }
          expect(p.combatTurnEncounter()['activeIndex'], 1);
          state.realtimeService = null;
          await closeFixture(tester, p);
        },
      );
    }
  }
  testWidgets(
    'ordinary attacks retain d20 and d16 boundaries use its own half',
    (tester) async {
      final (state, p, _, _) = await prepareReply(tester, online: false);
      state.livelloController.text = '3';
      state.gradoController.text = '1';
      expect(p.criticalModifier(16, 16), 8 + 3 + 6);
      expect(p.criticalModifier(1, 16), -(8 + 3 + 3));
      expect(p.criticalModifier(15, 16), 0);
      expect(p.criticalModifier(20, 20), 10 + 3 + 6);
      state.ispirazioneOculumCriticoInAttesa = true;
      final opening = p.planAttack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final planner = find.byType(OculumAttackPlanner);
      Navigator.of(
        tester.element(planner),
      ).pop(const OculumAttackPlan('ENEMY', 'vc', 'Attacco ordinario'));
      await opening;
      await tester.pump();
      final packet = (state.onlineCombatRequests as Map).values
          .whereType<Map>()
          .singleWhere((r) => r['kind'] != 'escape' && r['choice'] == 'vc');
      expect(packet['dieFaces'], 20);
      expect(packet['natural'], isIn([1, 20]));
      expect(state.dadoMostratoFacce, 20);
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'new d16 escape packets reject bad naturals but legacy d20 loads',
    (tester) async {
      final (_, p, _, record) = await prepareReply(tester, online: false);
      record['lastAggressor'] = p.ownerTag();
      p.selectEncounter('encounter_1');
      final packet = <String, dynamic>{
        'id': 'interception',
        'sourceTag': p.ownerTag(),
        'targetTag': 'ENEMY',
        'escapeReactionOf': record['id'],
        'dieFaces': 16,
        'natural': 16,
      };
      expect(p.escapeAttackAllowed(packet), isTrue);
      for (final bad in [0, 17, 20]) {
        expect(p.escapeAttackAllowed({...packet, 'natural': bad}), isFalse);
      }
      expect(p.escapeAttackAllowed({...packet, 'dieFaces': 20}), isFalse);
      final legacy = Map<String, dynamic>.from(packet)
        ..remove('dieFaces')
        ..['natural'] = 20;
      expect(p.escapeAttackAllowed(legacy), isTrue);
      expect(oculumAttackRollFaces(packet), 16);
      expect(oculumAttackRollFaces(legacy), 20);
      expect(oculumAttackRollFaces({'dieFaces': 16}), 20);
      await closeFixture(tester, p);
    },
  );
  test(
    'd16 double critical credits its real natural once and d20 stays default',
    () {
      final sheet = <String, dynamic>{'fortuna': 1};
      expect(
        oculumIsDoubleCritical(
          natural: 16,
          naturalMaximum: 16,
          total: 40,
          opposingTotal: 20,
        ),
        isTrue,
      );
      expect(
        oculumIsDoubleCritical(natural: 16, total: 40, opposingTotal: 20),
        isFalse,
      );
      for (final natural in [1, 15, 17, 20]) {
        expect(
          oculumIsDoubleCritical(
            natural: natural,
            naturalMaximum: 16,
            total: 40,
            opposingTotal: 20,
          ),
          isFalse,
        );
      }
      bool credit() => oculumGrantDoubleCriticalMagicalLuck(
        sheet,
        receiptId: 'd16-hit',
        natural: 16,
        naturalMaximum: 16,
        total: 40,
        opposingTotal: 20,
      );
      expect(credit(), isTrue);
      expect(credit(), isFalse);
      expect(sheet['fortuna'], 2);
    },
  );
  testWidgets(
    'd16 double critical is resolved as such and stops the real escape',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final escape = <String, dynamic>{
        'id': 'hero-escape',
        'kind': 'escape',
        'status': 'pending',
        'sourceTag': p.ownerTag(),
        'scope': p.permissionScope,
        'encounterId': 'encounter_1',
        'lastAggressor': 'ENEMY',
        'noticed': {'ENEMY': true},
        'answers': <String, dynamic>{},
        'total': 50,
      };
      final request = <String, dynamic>{
        'id': 'enemy-interception',
        'status': 'pending',
        'sourceTag': 'ENEMY',
        'sourceName': 'Nemico',
        'targetTag': p.ownerTag(),
        'scope': p.permissionScope,
        'encounterId': 'encounter_1',
        'escapeReactionOf': escape['id'],
        'choice': 'vc',
        'natural': 16,
        'dieFaces': 16,
        'attack': 40,
        'damage': 7,
        'element': 'fisico',
        'level': 3,
        'grade': 1,
        'effects': <Map<String, dynamic>>[],
      };
      state.onlineCombatRequests[escape['id']] = escape;
      state.onlineCombatRequests[request['id']] = request;
      await p.resolveCombatDefense(request, 'cm', 20);
      expect(request['doubleCritical'], isTrue);
      expect(request['status'], 'resolved');
      expect((escape['answers'] as Map)['ENEMY']['stops'], isTrue);
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'forged interception dice cannot consume authoritative turn resources',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final transport = _EscapeTransport()..authenticatedRole = 'master';
      state.realtimeService = transport;
      state.masterInitiativeRound = 2;
      final enemy = state.masterInitiativeTokens[1] as Map<String, dynamic>;
      enemy.addAll({
        'reactionPoolInitialized': true,
        'reactionPoolRound': 2,
        'reactionNormalFirstRoundLocked': false,
        'reactionMax': 1,
        'reactionUsed': 0,
        'reactionUsedRound': 2,
      });
      state.realtimeUsers.add(<String, dynamic>{
        'sessionId': 'enemy-session',
        'role': 'player',
        'localSheetTags': ['ENEMY'],
      });
      final escape = <String, dynamic>{
        'id': 'auth-escape',
        'kind': 'escape',
        'status': 'pending',
        'sourceTag': p.ownerTag(),
        'scope': p.permissionScope,
        'encounterId': 'encounter_1',
        'lastAggressor': 'ENEMY',
        'noticed': {'ENEMY': true},
        'answers': <String, dynamic>{},
      };
      state.onlineCombatRequests[escape['id']] = escape;
      Map<String, dynamic> packet(String id) => {
        'id': id,
        'scope': p.permissionScope,
        'campaignId': p.permissionCampaignId,
        'encounterId': 'encounter_1',
        'sourceTag': 'ENEMY',
        'senderTag': 'ENEMY',
        'senderRole': 'player',
        'sessionId': 'enemy-session',
        'targetTag': p.ownerTag(),
        'sourceName': 'Avversario',
        'escapeReactionOf': escape['id'],
        'dieFaces': 16,
        'natural': 17,
        'attack': 40,
        'damage': 7,
        'choice': 'vc',
        'element': 'fisico',
        'turnResourceSpends': [
          {'id': '$id:resource', 'sheetTag': 'ENEMY', 'resource': 'reazione'},
        ],
      };
      final forged = packet('bad-interception');
      p.receiveCombat('combat_attack', forged);
      expect(enemy['reactionUsed'], 0);
      expect(state.onlineCombatRequests.containsKey(forged['id']), isFalse);
      expect(escape['answers'], isEmpty);
      expect(state.masterInitiativeActiveIndex, 0);
      // The otherwise identical authenticated legacy packet is accepted and
      // mirrors one resource expenditure. This proves the forged case was not
      // merely dropped by a missing fixture permission or fight identity.
      final legacy = packet('legacy-interception')
        ..remove('dieFaces')
        ..['natural'] = 20;
      p.receiveCombat('combat_attack', legacy);
      expect(enemy['reactionUsed'], 1);
      expect(state.onlineCombatRequests.containsKey(legacy['id']), isTrue);
      expect(state.masterInitiativeActiveIndex, 0);
      state.realtimeService = null;
      await closeFixture(tester, p);
    },
  );
}
