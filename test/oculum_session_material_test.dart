import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';

import 'oculum_october27_resources_test.dart' show closeFixture;
import 'oculum_theme_effects_portrait_test.dart' show mountSheet;

class _SessionTransport extends OculumRealtimeService {
  _SessionTransport()
    : super(
        roomId: 'session-material-test',
        playerName: 'Master',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      ) {
    authenticatedRole = 'master';
  }

  String? userId = 'master-one';
  final snapshots = <Map<String, dynamic>>[];

  @override
  bool get isConnected => true;

  @override
  String? get authenticatedUserId => userId;

  @override
  Future<void> sendInitiativeSnapshot({
    required Map<String, dynamic> snapshot,
    required String campaignId,
    required String campaignName,
    required bool closed,
  }) async {
    snapshots.add(snapshot);
  }

  @override
  Future<bool> sendSharedSheetConfirmed({
    required Map<String, dynamic> sheet,
    required String campaignId,
    required String campaignName,
    required String sheetId,
    required String sheetName,
    required String ownerTag,
    required String senderRole,
    required String targetAudience,
    required bool fromMaster,
    required bool masterParty,
    List<String> targetTags = const [],
    List<String> allowClearFields = const [],
    String deliveryId = '',
  }) async => true;
}

Future<void> _openMaterialPage(WidgetTester tester, dynamic state) async {
  state.updateOculumHomeUi(() {
    state.paginaCorrente = 9;
    state.modalitaMaster = true;
    state.masterCategory = 'session-material';
    state.masterQuery = '';
  });
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder.hitTestable());
  await tester.pumpAndSettle();
}

void main() {
  test('cloud queue only receives session material owned by its account', () {
    final ownPlan = {
      'materials': ['own'],
    };
    final otherPlan = {
      'materials': ['other'],
    };
    final first = {
      'id': 'first',
      'sessionMaterialByMaster': {
        'account:master-one': ownPlan,
        'account:master-two': otherPlan,
      },
    };
    final second = {
      'id': 'second',
      'sessionMaterialByMaster': {'local-master': otherPlan},
    };
    final payload = <String, dynamic>{
      'campaigns': [first, second],
    };
    final filtered = oculumSessionMaterialCloudSaveForMaster(
      payload,
      'master-one',
    );
    expect(filtered['campaigns'], [
      {
        'id': 'first',
        'sessionMaterialByMaster': {'account:master-one': ownPlan},
      },
      {'id': 'second'},
    ]);
    expect(payload['campaigns'], [first, second]);
    expect(first['sessionMaterialByMaster'], hasLength(2));
    expect(
      oculumSessionMaterialCloudSaveForMaster(filtered, 'master-one'),
      same(filtered),
    );
  });

  testWidgets(
    'five material slots persist per campaign and authenticated Master',
    (tester) async {
      final state = await mountSheet(tester, const Size(320, 1000));
      final probe = OculumPerformanceProbe(state);
      final transport = _SessionTransport();
      state.realtimeService = transport;
      state.activeCampaignId = 'session-one';
      await _openMaterialPage(tester, state);

      final slot = find.byKey(const ValueKey('session-material-slot-0'));
      final toggle = find.byKey(const ValueKey('session-material-co-master'));
      for (var i = 0; i < 5; i++) {
        expect(
          find.byKey(ValueKey('session-material-slot-$i')),
          findsOneWidget,
        );
      }
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      await _tap(tester, slot);
      await tester.enterText(
        find.byKey(const ValueKey('session-material-name')),
        'Quarzo di Postea',
      );
      await tester.enterText(
        find.byKey(const ValueKey('session-material-difficulty')),
        '17',
      );
      await _tap(tester, find.text('Minerale o cristallo estraibile'));
      await tester.enterText(
        find.byKey(const ValueKey('session-material-grade')),
        '2',
      );
      await _tap(tester, find.widgetWithText(FilledButton, 'Salva'));
      await _tap(tester, toggle);

      final saved =
          jsonDecode(jsonEncode(probe.campaignSnapshot()))
              as Map<String, dynamic>;
      final plan = saved['sessionMaterialByMaster']['account:master-one'];
      expect(plan['allowCoMaster'], isTrue);
      expect(plan['materials'], [
        {
          'name': 'Quarzo di Postea',
          'check': 'percezione',
          'difficulty': 17,
          'extractionGrade': 2,
        },
        null,
        null,
        null,
        null,
      ]);
      expect(transport.snapshots, isEmpty);

      final otherCampaign = {...saved, 'id': 'session-two'}
        ..remove('sessionMaterialByMaster');
      state.updateOculumHomeUi(() => probe.loadCampaign(otherCampaign));
      await tester.pumpAndSettle();
      expect(find.text('Quarzo di Postea'), findsNothing);
      state.updateOculumHomeUi(() => probe.loadCampaign(saved));
      await tester.pumpAndSettle();
      expect(find.text('Quarzo di Postea'), findsOneWidget);

      state.updateOculumHomeUi(() => transport.userId = 'master-two');
      await tester.pumpAndSettle();
      expect(find.text('Quarzo di Postea'), findsNothing);
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      for (final role in ['coMaster', 'player', null]) {
        state.updateOculumHomeUi(() {
          transport.userId = 'master-one';
          transport.authenticatedRole = role;
        });
        await tester.pumpAndSettle();
        expect(
          toggle,
          findsNothing,
          reason: '$role cannot open this local plan',
        );
      }
      expect(tester.takeException(), isNull);
      state.realtimeService = null;
      await closeFixture(tester, probe);
    },
  );

  testWidgets(
    'prepared battle stays private until its roster is started once',
    (tester) async {
      final state = await mountSheet(tester, const Size(1440, 1000));
      final probe = OculumPerformanceProbe(state);
      final transport = _SessionTransport();
      state.realtimeService = transport;
      final initial = probe.campaignSnapshot();
      final sheet = probe.snapshot();
      probe.loadCampaign({
        ...initial,
        'id': 'session-battle',
        'schedePersonaggio': [
          sheet,
          {...sheet}
            ..remove('sheetTag')
            ..remove('id'),
        ],
      });
      await _openMaterialPage(tester, state);
      final groupCount = (state.masterInitiativeGroups as List).length;
      final tag = probe.ownerTag();
      final participant = find.byKey(
        ValueKey('session-material-participant-$tag'),
      );
      await _tap(
        tester,
        find.byKey(const ValueKey('session-material-prepare')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('session-material-battle-name')),
        'Agguato nella miniera',
      );
      await _tap(tester, participant);
      await _tap(tester, find.widgetWithText(FilledButton, 'Salva bozza'));
      expect((state.masterInitiativeGroups as List).length, groupCount);
      expect(transport.snapshots, isEmpty);
      final saved = probe.campaignSnapshot();
      final plan = saved['sessionMaterialByMaster']['account:master-one'];
      final draft = (plan['battles'] as List).single;
      expect(draft['participantTags'], [tag]);
      expect(draft, isNot(contains('startedEncounterId')));

      state.updateOculumHomeUi(() => probe.loadCampaign(saved));
      await tester.pumpAndSettle();
      final start = find.byKey(
        ValueKey('session-material-start-${draft['id']}'),
      );
      final activate = tester.widget<IconButton>(start).onPressed!;
      await _tap(tester, start);
      final encounterId = state.selectedMasterInitiativeGroupId;
      expect((state.masterInitiativeGroups as List).length, groupCount + 1);
      final encounter = (state.masterInitiativeGroups as List).singleWhere(
        (g) => g['id'] == encounterId,
      );
      expect(encounter['name'], 'Agguato nella miniera');
      expect(encounter['fightStarted'], isTrue);
      expect((encounter['tokens'] as List).single['sheetTag'], tag);
      expect(transport.snapshots, isNotEmpty);
      expect(
        transport.snapshots.every(
          (data) => !jsonEncode(data).contains('sessionMaterialByMaster'),
        ),
        isTrue,
      );

      activate();
      await tester.pumpAndSettle();
      expect((state.masterInitiativeGroups as List).length, groupCount + 1);
      expect(find.text('Avviata'), findsOneWidget);
      expect(tester.takeException(), isNull);
      state.realtimeService = null;
      await closeFixture(tester, probe);
    },
  );
}
