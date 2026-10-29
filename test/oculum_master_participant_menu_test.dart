import 'dart:async';
import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'package:oculum/widgets/oculum_encounter_stage.dart';

import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

class _ParticipantTransport extends OculumRealtimeService {
  _ParticipantTransport(String role)
    : super(
        roomId: 'participant-menu',
        playerName: 'Staff',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      ) {
    authenticatedRole = role;
  }
  final messages = <Map<String, dynamic>>[];
  @override
  bool get isConnected => true;
  @override
  Future<bool> sendCombatEvent(
    String event,
    Map<String, dynamic> payload,
  ) async {
    messages.add({'event': event, ...payload});
    return true;
  }
}

Future<void> _choose(WidgetTester tester, String label) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  final entry = find
      .ancestor(
        of: find.text(label).last,
        matching: find.byWidgetPredicate(
          (widget) => widget is PopupMenuItem<String>,
        ),
      )
      .last;
  await tester.ensureVisible(entry);
  await tester.tap(entry);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  for (final width in [320.0, 1440.0]) {
    testWidgets('stage right click and long press preserve turn at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final seen = <String>[];
      var turns = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OculumEncounterStage(
                tokens: [
                  {'id': 'hero', 'name': 'Eroe', 'side': 'party'},
                  {'id': 'npc', 'name': 'Nemico', 'side': 'enemy'},
                ],
                activeIndex: 0,
                accent: Colors.amber,
                portraitBuilder: (_) => const Icon(Icons.person),
                onNextTurn: () => turns++,
                onParticipantMenu: (token, position) =>
                    seen.add('${token['id']}'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('encounter-avatar-npc')),
        buttons: kSecondaryMouseButton,
      );
      await tester.pump();
      await tester.longPress(
        find.byKey(const ValueKey('encounter-avatar-hero')),
      );
      await tester.pump();
      expect(seen, ['npc', 'hero']);
      expect(turns, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('readonly stage exposes no participant command affordance', (
    tester,
  ) async {
    var roles = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OculumEncounterStage(
            tokens: [
              {'id': 'hero', 'name': 'Eroe'},
            ],
            activeIndex: 0,
            accent: Colors.amber,
            portraitBuilder: (_) => const Icon(Icons.person),
          ),
        ),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey('encounter-avatar-hero')),
      buttons: kSecondaryMouseButton,
    );
    await tester.longPress(find.byKey(const ValueKey('encounter-avatar-hero')));
    expect(find.byTooltip('Gestisci partecipante'), findsNothing);
    // The existing Role callback remains the fallback for older callers.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OculumEncounterStage(
            tokens: [
              {'id': 'hero', 'name': 'Eroe'},
            ],
            activeIndex: 0,
            accent: Colors.amber,
            portraitBuilder: (_) => const Icon(Icons.person),
            onMoveToRole: (_) => roles++,
          ),
        ),
      ),
    );
    await tester.longPress(find.byKey(const ValueKey('encounter-avatar-hero')));
    expect(roles, 1);
  });

  testWidgets(
    'real Master context toggles hostile and restores the original party side',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final hero = state.masterInitiativeTokens.first as Map<String, dynamic>;
      // A real route keeps the stage below popup routes. Inserting a raw
      // OverlayEntry above Navigator routes would cover the popup hit region.
      final navigator = Navigator.of(
        tester.element(find.byType(OculumHomePage)),
      );
      unawaited(
        navigator.push<void>(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(body: p.masterEncounterStage()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      final avatar = find.byKey(ValueKey('encounter-avatar-${hero['id']}'));
      await tester.tap(avatar, buttons: kSecondaryMouseButton);
      await _choose(tester, 'Cattivo · Nemico');
      expect(hero['side'], 'enemy');
      expect(hero['masterSideBeforeEnemy'], 'party');
      await tester.longPress(avatar);
      await _choose(tester, 'Cattivo · Nemico');
      expect(hero['side'], 'party');
      expect(state.masterInitiativeActiveIndex, 0);
      navigator.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'manual death survives campaign JSON reload and shared snapshot without reducing HP',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final hero = state.masterInitiativeTokens.first as Map<String, dynamic>;
      final beforeHp = p.currentHp();
      hero['currentHp'] = 70;
      hero['maxHp'] = 100;
      hero['fightInstanceId'] = 'fight-current';
      await p.participantCommand('encounter_1', hero, 'toggleDead');
      expect(hero['status'], 'dead');
      expect(hero['automaticDeath'], false);
      expect(hero['currentHp'], 70);
      expect(hero['rewardDeathFightInstanceId'], 'fight-current');
      expect(p.currentHp(), beforeHp);
      p.recordCurrentEncounter();
      final saved = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(p.campaignSnapshot())) as Map,
      );
      state.masterInitiativeTokens.clear();
      state.masterInitiativeGroups.clear();
      p.loadCampaign(saved);
      final restored =
          state.masterInitiativeTokens.first as Map<String, dynamic>;
      expect(restored['status'], 'dead');
      expect(restored['automaticDeath'], false);
      final shared = p.publicEncounter(
        state.masterInitiativeGroups.first as Map<String, dynamic>,
      );
      expect((shared['tokens'] as List).first['status'], 'dead');
      await p.participantCommand('encounter_1', restored, 'toggleDead');
      expect(restored['status'], 'ready');
      expect(p.currentHp(), beforeHp);
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'an open menu follows token identity when initiative order changes',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final original = state.masterInitiativeTokens[1] as Map<String, dynamic>;
      final operation = p.participantMenu('encounter_1', original);
      await tester.pump();
      state.masterInitiativeTokens.insert(
        1,
        state.masterInitiativeTokens.removeAt(2),
      );
      await _choose(tester, 'Morto');
      await operation;
      expect(original['status'], 'dead');
      expect(state.masterInitiativeTokens[1]['status'], 'ready');
      await closeFixture(tester, p);
    },
  );

  for (final change in ['encounter', 'sheet', 'role', 'fight']) {
    testWidgets('an open participant menu is cancelled after $change changes', (
      tester,
    ) async {
      final (state, p) = await fixtures.mountFight(tester);
      final original = state.masterInitiativeTokens[1] as Map<String, dynamic>;
      final operation = p.participantMenu('encounter_1', original);
      await tester.pump();
      if (change == 'encounter') p.selectEncounter('encounter_2');
      if (change == 'role') {
        state.modalitaMaster = false;
        state.isMasterHost = false;
        state.sonoCoMaster = false;
      }
      if (change == 'sheet') {
        final other = p.snapshot()..['sheetTag'] = 'OtherOcu:3690ABCD';
        other['id'] = other['sheetTag'];
        state.schedePersonaggio.add(other);
        state.schedaCorrente = state.schedePersonaggio.length - 1;
      }
      if (change == 'fight') {
        state.masterInitiativeTokens.first['fightInstanceId'] = 'new-fight';
      }
      await _choose(tester, 'Morto');
      await operation;
      expect(original['status'], 'ready');
      if (change == 'encounter') {
        expect(
          (state.masterInitiativeGroups.first['tokens'] as List)[1]['status'],
          'ready',
        );
        expect(state.masterInitiativeTokens, isEmpty);
      }
      await closeFixture(tester, p);
    });
  }

  testWidgets(
    'manual NPC editor saves explicit permanent stats level grade and known power',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final npc = state.masterInitiativeTokens[1] as Map<String, dynamic>;
      final sheetBefore = jsonEncode(p.snapshot()['resilienza']);
      final operation = p.participantCommand('encounter_1', npc, 'levelGrade');
      await tester.pump();
      final fields = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      expect(fields, findsNWidgets(7));
      for (var i = 0; i < 7; i++) {
        await tester.enterText(
          fields.at(i),
          ['8', '1', '26', '37', '38', '21', '130'][i],
        );
      }
      await tester.tap(find.widgetWithText(FilledButton, 'Salva'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await operation;
      expect(npc['level'], 8);
      expect(npc['grade'], 1);
      expect(npc['manualLevelGradeOverride'], true);
      expect(npc['statsTotal'], {
        'resilienza': 26,
        'volonta': 37,
        'materia': 38,
        'oculum': 21,
      });
      expect(npc['resilienza'], 26);
      expect(npc['totalPower'], 130);
      expect(jsonEncode(p.snapshot()['resilienza']), sheetBefore);
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'authenticated Player cannot mutate participants through stale Master mode',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final npc = state.masterInitiativeTokens[1] as Map<String, dynamic>;
      state.realtimeService = _ParticipantTransport('player');
      expect(p.masterPermissions, false);
      await p.participantCommand('encounter_1', npc, 'toggleDead');
      await p.participantMenu('encounter_1', npc);
      expect(npc['status'], 'ready');
      expect(find.text('Cattivo · Nemico'), findsNothing);
      state.realtimeService = null;
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'Co-Master sends the stable participant command without optimistic mutation',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final group = state.masterInitiativeGroups.first as Map<String, dynamic>;
      final snapshot = p.publicEncounter(group);
      final service = _ParticipantTransport('coMaster');
      state.realtimeService = service;
      state.realtimeEncounterSnapshots = <Map<String, dynamic>>[snapshot];
      state.realtimeVisibleInitiativeSnapshot = snapshot;
      state.realtimeSelectedEncounterId = 'encounter_1';
      final npc = (snapshot['tokens'] as List)[1] as Map<String, dynamic>;
      await p.participantCommand('encounter_1', npc, 'toggleDead');
      expect(npc['status'], 'ready');
      final sent = service.messages.single;
      expect(sent['event'], 'initiative_control');
      expect(sent['participantCommand'], 'toggleDead');
      expect(sent['encounterId'], 'encounter_1');
      expect(sent['participantId'], npc['id']);
      state.realtimeService = null;
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'Master validates staff role generation and duplicate participant commands',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final npc = state.masterInitiativeTokens[1] as Map<String, dynamic>;
      state.masterInitiativeGroups.first['published'] = true;
      final sender = 'StaffOcu:3690AAAA';
      state.realtimeUsers = <Map<String, dynamic>>[
        {
          'sessionId': 'staff-session',
          'role': 'coMaster',
          'activeSheetTag': sender,
        },
      ];
      final packet = <String, dynamic>{
        'id': 'participant:one',
        'scope': p.permissionScope,
        'campaignId': p.permissionCampaignId,
        'senderRole': 'coMaster',
        'senderTag': sender,
        'sessionId': 'staff-session',
        'encounterId': 'encounter_1',
        'participantId': npc['id'],
        'expectedFightId': '',
        'participantCommand': 'toggleDead',
        'participantValues': {'expectedStatus': 'ready'},
      };
      await p.receiveParticipantControl({...packet, 'senderRole': 'player'});
      expect(npc['status'], 'ready');
      await p.receiveParticipantControl({
        ...packet,
        'expectedFightId': 'old-fight',
      });
      expect(npc['status'], 'ready');
      await p.receiveParticipantControl(packet);
      expect(npc['status'], 'dead');
      await p.receiveParticipantControl(packet);
      expect(
        npc['status'],
        'dead',
        reason: 'a redelivered toggle cannot resurrect the target',
      );
      await closeFixture(tester, p);
    },
  );
}
