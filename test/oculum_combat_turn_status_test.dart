import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

class _SharedFightTransport extends OculumRealtimeService {
  _SharedFightTransport()
    : super(
        roomId: 'shared-status',
        playerName: 'Player',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      ) {
    authenticatedRole = 'player';
  }
  @override
  bool get isConnected => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final regular = await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
    for (final family in [
      'Poppins',
      'Roboto',
      'serif',
      'Segoe UI',
      'Georgia',
    ]) {
      await (FontLoader(family)..addFont(Future.value(regular))).load();
    }
    final icons = File(
      'build/unit_test_assets/fonts/MaterialIcons-Regular.otf',
    );
    if (icons.existsSync()) {
      await (FontLoader('MaterialIcons')..addFont(
            Future.value(ByteData.sublistView(icons.readAsBytesSync())),
          ))
          .load();
    }
  });
  Map<String, dynamic> encounter() => {
    'encounterId': 'fight-b',
    'fightOrdinal': 2,
    'round': 3,
    'activeIndex': 1,
    'tokens': [
      {'id': 'a', 'name': 'Iris', 'status': 'ready'},
      {'id': 'b', 'name': 'Leo', 'status': 'active'},
    ],
  };
  Map<String, dynamic> reaction({
    String status = 'pending',
    String fight = 'fight-b',
    bool fast = false,
  }) => {
    'id': 'hit',
    'status': status,
    'encounterId': fight,
    'turnResourceSpends': [
      {
        'sheetTag': 'a',
        'resource': 'reazione',
        'activityResource': fast ? 'reazione_veloce' : 'reazione',
      },
    ],
  };
  test(
    'reaction labels use the actual resource and preserve the turn owner',
    () {
      final fight = encounter();
      expect(oculumCombatTurnStatus(fight), 'Fight II | Azione Leo');
      expect(
        oculumCombatTurnStatus(fight, requests: [reaction()]),
        'Fight II | Reazione Iris | turno di Leo',
      );
      expect(
        oculumCombatTurnStatus(fight, requests: [reaction(fast: true)]),
        'Fight II | Reazione Veloce Iris | turno di Leo',
      );
      expect(fight['activeIndex'], 1);
      expect(
        oculumCombatTurnStatus(
          fight,
          requests: [
            {
              ...reaction(),
              'turnResourceSpends': [
                {'sheetTag': 'b', 'resource': 'azione'},
              ],
            },
          ],
        ),
        'Fight II | Azione Leo | turno di Leo',
      );
      expect(
        oculumCombatTurnStatus(fight, requests: [reaction(), reaction()]),
        'Fight II | Reazione Iris | turno di Leo',
      );
      for (final status in ['resolved', 'cancelled', 'rejected', 'expired']) {
        expect(
          oculumCombatTurnStatus(fight, requests: [reaction(status: status)]),
          'Fight II | Azione Leo',
        );
      }
      expect(
        oculumCombatTurnStatus(fight, requests: [reaction(fight: 'fight-a')]),
        'Fight II | Azione Leo',
      );
      fight['mergedEncounterIds'] = ['old-fight'];
      expect(
        oculumCombatTurnStatus(
          fight,
          requests: [reaction(fight: 'old-fight', fast: true)],
        ),
        'Fight II | Reazione Veloce Iris | turno di Leo',
      );
      fight['activeIndex'] = -1;
      expect(oculumCombatTurnStatus(fight), 'Fight II | Nessun turno attivo');
    },
  );
  testWidgets(
    'actual fast and normal reaction spends never advance initiative; action does',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      state.masterInitiativeActiveIndex = 1;
      state.masterInitiativeRound = 2;
      final token = state.masterInitiativeTokens.first;
      token['reactionPoolInitialized'] = true;
      token['reactionPoolRound'] = 2;
      token['reactionNormalFirstRoundLocked'] = false;
      token['reactionMax'] = 1;
      token['reactionUsed'] = 0;
      token['reactionUsedRound'] = 2;
      token['reactionFastMax'] = 1;
      token['reactionFastUsed'] = 0;
      token['reactionFastTurnKey'] = '2';
      state.masterInitiativeActiveIndex = 0;
      token['actionUsed'] = false;
      token['kiExtraActions'] = 2;
      expect(p.combatTurnResources(), {
        'actions': 3,
        'reactions': 1,
        'fast': 1,
      });
      token['kiExtraActions'] = 0;
      state.masterInitiativeActiveIndex = 1;
      expect(p.combatTurnResources(), {
        'actions': 0,
        'reactions': 1,
        'fast': 1,
      });
      expect(await p.utilitySpend('reazione'), isTrue);
      expect(p.combatTurnResources(), {
        'actions': 0,
        'reactions': 0,
        'fast': 1,
      });
      expect(state.masterInitiativeActiveIndex, 1);
      expect(state.masterInitiativeRound, 2);
      final normal = p.turnResourceTestPacket('normal');
      state.onlineCombatRequests['normal'] = {...normal, 'status': 'pending'};
      expect(
        p.combatTurnStatus(),
        'Fight I | Reazione Eroe | turno di Provocatore',
      );
      state.onlineCombatRequests['normal']['status'] = 'resolved';
      expect(p.combatTurnStatus(), 'Fight I | Azione Provocatore');
      expect(await p.utilitySpend('reazione'), isTrue);
      expect(p.combatTurnResources(), {
        'actions': 0,
        'reactions': 0,
        'fast': 0,
      });
      expect(state.masterInitiativeActiveIndex, 1);
      expect(state.masterInitiativeRound, 2);
      final fast = p.turnResourceTestPacket('fast');
      expect(
        (fast['turnResourceSpends'] as List).last['activityResource'],
        'reazione_veloce',
      );
      expect((fast['turnResourceSpends'] as List).last['resource'], 'reazione');
      state.onlineCombatRequests['fast'] = {...fast, 'status': 'pending'};
      expect(
        p.combatTurnStatus(),
        'Fight I | Reazione Veloce Eroe | turno di Provocatore',
      );
      state.onlineCombatRequests['fast']['status'] = 'resolved';
      state.onlineCombatRequests['free-counter'] = <String, dynamic>{
        'freeReaction': true,
        'targetTag': p.ownerTag(),
        'reactionUsed': false,
      };
      final usedNormal = token['reactionUsed'];
      final usedFast = token['reactionFastUsed'];
      expect(await p.utilitySpend('reazione'), isTrue);
      expect(state.masterInitiativeActiveIndex, 1);
      expect(state.masterInitiativeRound, 2);
      final free = p.turnResourceTestPacket('free');
      expect(
        (free['turnResourceSpends'] as List).single['resource'],
        'free-counter',
      );
      expect(
        (free['turnResourceSpends'] as List).single['activityResource'],
        'reazione',
      );
      expect(token['reactionUsed'], usedNormal);
      expect(token['reactionFastUsed'], usedFast);
      state.masterInitiativeActiveIndex = 0;
      token['actionUsed'] = false;
      token['actionTurnRound'] = 2;
      expect(await p.utilitySpend('azione'), isTrue);
      expect(state.masterInitiativeActiveIndex, 1);
      await closeFixture(tester, p);
    },
  );
  testWidgets('status follows the current sheet fight and fits 320px', (
    tester,
  ) async {
    final (state, p) = await fixtures.mountFight(tester);
    final tag = p.ownerTag();
    state.masterInitiativeTokens.removeAt(0);
    state.masterInitiativeGroups[1]['tokens'] = <Map<String, dynamic>>[
      {
        'id': tag,
        'sheetTag': tag,
        'name': 'Personaggio con nome molto lungo',
        'status': 'ready',
      },
      {
        'id': 'npc',
        'name': 'Avversario con nome molto lungo',
        'status': 'active',
      },
    ];
    state.masterInitiativeGroups[1]['activeIndex'] = 1;
    state.masterInitiativeGroups[1]['round'] = 4;
    state.onlineCombatRequests['other-fight'] = {
      'status': 'pending',
      'encounterId': 'encounter_2',
      'turnResourceSpends': [
        {'sheetTag': tag, 'resource': 'reazione_veloce'},
      ],
    };
    expect(p.combatTurnEncounter()['encounterId'], 'encounter_2');
    expect(p.combatTurnStatus(), startsWith('Fight II | Reazione Veloce'));
    expect(p.combatTurnResources(), {'actions': 0, 'reactions': 0, 'fast': 1});
    tester.view.physicalSize = const Size(320, 700);
    p.cancelPendingSave();
    final captureKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: oculumBaseTheme,
        home: Scaffold(
          body: RepaintBoundary(
            key: captureKey,
            child: p.combatTurnStatusBar(),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('A0 / R0 / RV1'), findsOneWidget);
    expect(
      find.textContaining('turno di Avversario con nome molto lungo'),
      findsOneWidget,
    );
    await tester.runAsync(() async {
      final boundary =
          captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      await File(
        'build/turn-status-320.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
    });
    // Unmounting the full app destroys its state; this widget still verifies
    // the final text and narrow layout produced before that boundary.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 4));
  });
  testWidgets(
    'shared fights follow sheet membership and Master turn snapshots including merges',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final transport = _SharedFightTransport();
      state.realtimeService = transport;
      final tag = p.ownerTag();
      final shared = <String, dynamic>{
        'encounterId': 'shared-party',
        'fightOrdinal': 3,
        'activeIndex': 1,
        'round': 7,
        'mergedEncounterIds': ['old-party'],
        'tokens': <Map<String, dynamic>>[
          {'id': tag, 'name': 'Eroe', 'status': 'ready'},
          {'id': 'ALLY', 'name': 'Compagno', 'status': 'active'},
        ],
      };
      state.realtimeSelectedEncounterId = 'another-fight';
      state.realtimeEncounterSnapshots
        ..clear()
        ..addAll([
          <String, dynamic>{
            'encounterId': 'another-fight',
            'tokens': [
              <String, dynamic>{'id': 'OUTSIDER'},
            ],
          },
          shared,
        ]);
      state.realtimeVisibleInitiativeSnapshot = shared;
      expect(p.combatTurnStatus(), 'Fight III | Azione Compagno');
      state.onlineCombatRequests['reacting'] = <String, dynamic>{
        'id': 'reacting',
        'encounterId': 'old-party',
        'status': 'pending',
        'turnResourceSpends': [
          <String, dynamic>{
            'sheetTag': tag.toUpperCase(),
            'resource': 'reazione_veloce',
          },
        ],
      };
      expect(
        p.combatTurnStatus(),
        'Fight III | Reazione Veloce Eroe | turno di Compagno',
      );
      expect(shared['activeIndex'], 1);
      state.onlineCombatRequests['reacting']['status'] = 'resolved';
      shared['activeIndex'] = 0;
      expect(p.combatTurnStatus(), 'Fight III | Azione Eroe');
      state.realtimeService = null;
      await transport.dispose();
      await closeFixture(tester, p);
    },
  );
}
