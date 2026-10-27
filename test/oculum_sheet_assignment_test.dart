import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

class _AssignmentTransport extends OculumRealtimeService {
  _AssignmentTransport(this.user, {bool master = false})
    : super(
        roomId: 'assignment-test',
        playerName: 'Test',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      ) {
    authenticatedRole = master ? 'master' : 'player';
  }
  final String user;
  @override
  bool get isConnected => true;
  @override
  String get authenticatedUserId => user;
}

Map<String, dynamic> receipt(String tag) => {
  'room_id': 'room',
  'transfer_id': '00000000-0000-4000-8000-000000000001',
  'sheet_tag': tag.toUpperCase(),
  'source_user_id': 'master-user',
  'target_user_id': 'player-user',
  'source_name': 'Master',
  'target_name': 'Player',
  'sheet_name': 'Gift',
  'campaign_id': 'c',
  'campaign_name': 'Campaign',
  'created_at': '2026-10-27T12:00:00Z',
};

void main() {
  Future<bool?> applyAndPump(
    WidgetTester tester,
    Future<bool> Function() action,
  ) async {
    bool? result;
    Object? error;
    var done = false;
    unawaited(
      action().then(
        (value) {
          result = value;
          done = true;
        },
        onError: (Object e) {
          error = e;
          done = true;
        },
      ),
    );
    final watch = Stopwatch()..start();
    while (!done && watch.elapsed < const Duration(seconds: 10)) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 20));
    }
    if (error != null) throw error!;
    expect(
      done,
      isTrue,
      reason:
          'Assignment save did not finish while native I/O and UI microtasks were pumped.',
    );
    return result;
  }

  Future<void> prepareSave(WidgetTester tester, dynamic state) async {
    final p = OculumPerformanceProbe(state);
    final original = p.snapshot();
    p.cancelPendingSave();
    await applyAndPump(tester, () => p.initialSheetLoad().then((_) => true));
    await tester.runAsync(() async {
      final prefs = await SharedPreferences.getInstance();
      final directory = Directory(
        'build/assignment-save-${DateTime.now().microsecondsSinceEpoch}',
      )..createSync(recursive: true);
      state.sharedPreferencesFuture = Future<SharedPreferences>.value(prefs);
      state.saveBlobDirectoryFuture = Future<Directory>.value(directory);
    });
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    state.schedePersonaggio
      ..clear()
      ..add(original);
    state.schedaCorrente = 0;
    p.load(original);
    state.datiCaricati = true;
  }

  test(
    'local assignment preserves identity, customized rules, images and reward receipts',
    () {
      final raw = <String, dynamic>{
        'id': 'Gift-1',
        'sheetTag': 'Gift-1',
        'nome': 'Gift',
        'realtimeSharedSheet': true,
        'realtimeOwnerName': 'Old owner',
        'imageBase64': 'unchanged-pixels',
        'claimedEncounterRewardIds': ['fight-once'],
        'magicalLuckCriticalIds': ['crit-once'],
        'customData': {
          'cost': '2 Resilienza',
          'duration': 4,
          'minimum': 1,
          'maximum': 6,
        },
      };
      final copy = oculumAssignedLocalSheet(receipt('Gift-1'), raw);
      expect(copy['id'], 'Gift-1');
      expect(copy['sheetTag'], 'Gift-1');
      expect(copy['imageBase64'], raw['imageBase64']);
      expect(copy['customData'], raw['customData']);
      expect(
        copy['claimedEncounterRewardIds'],
        raw['claimedEncounterRewardIds'],
      );
      expect(copy['magicalLuckCriticalIds'], raw['magicalLuckCriticalIds']);
      expect(copy.keys.any((key) => key.startsWith('realtime')), isFalse);
      expect(copy['sheetAssignmentOwnerUserId'], 'player-user');
      expect(raw['realtimeSharedSheet'], isTrue);
      expect(
        () => oculumAssignedLocalSheet(receipt('OTHER'), raw),
        throwsFormatException,
      );
    },
  );
  testWidgets(
    'every sheet starts unchecked and confirmation needs both a recipient and a selection',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      await prepareSave(tester, state);
      final transport = _AssignmentTransport('master-user', master: true);
      state.realtimeService = transport;
      state.realtimeUsers = <Map<String, dynamic>>[
        {
          'userId': 'player-user',
          'role': 'player',
          'playerName': 'Recipient',
          'sheetAssignmentVersion': 1,
        },
      ];
      Future<void> open() async {
        unawaited(p.showAssignSheets());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
      }

      await open();
      expect(
        tester.widgetList<CheckboxListTile>(find.byType(CheckboxListTile)),
        everyElement(
          isA<CheckboxListTile>().having((box) => box.value, 'selected', false),
        ),
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('confirm_assign_sheets')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('assignment_recipient')));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text('Recipient').last);
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('confirm_assign_sheets')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('confirm_assign_sheets')),
            )
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.widgetWithText(TextButton, 'Chiudi').last);
      await tester.pump(const Duration(milliseconds: 250));
      await open();
      expect(
        tester.widgetList<CheckboxListTile>(find.byType(CheckboxListTile)),
        everyElement(
          isA<CheckboxListTile>().having((box) => box.value, 'selected', false),
        ),
      );
      await tester.tap(find.widgetWithText(TextButton, 'Chiudi').last);
      await tester.pump(const Duration(milliseconds: 250));
      state.realtimeService = null;
      await transport.dispose();
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'recipient saves a local sheet once; a refused conflicting import preserves existing data',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final transport = _AssignmentTransport('player-user');
      state.realtimeService = transport;
      await prepareSave(tester, state);
      final body = p.snapshot()
        ..['id'] = 'GiftOcu:3690TEST'
        ..['sheetTag'] = 'GiftOcu:3690TEST'
        ..['nome'] = 'Gift';
      body['claimedEncounterRewardIds'] = ['previous-award'];
      final item = receipt('GiftOcu:3690TEST');
      expect(
        await applyAndPump(tester, () => p.applyAssignment(item, body)),
        isTrue,
      );
      final gifts = (state.schedePersonaggio as List)
          .where((s) => s['sheetTag'] == 'GiftOcu:3690TEST')
          .toList();
      expect(gifts, hasLength(1));
      expect(gifts.single['realtimeSharedSheet'], isNot(true));
      expect(gifts.single['claimedEncounterRewardIds'], ['previous-award']);
      final saved = await tester.runAsync(p.savedRaw);
      expect(saved, contains(oculumSheetAssignmentReceipt(item, local: true)));
      expect(
        await applyAndPump(tester, () => p.applyAssignment(item, body)),
        isTrue,
      );
      expect(
        (state.schedePersonaggio as List).where(
          (s) => s['sheetTag'] == 'GiftOcu:3690TEST',
        ),
        hasLength(1),
      );
      final collision = {
        ...receipt(p.ownerTag()),
        'transfer_id': 'another-transfer',
      };
      final before = jsonEncode(p.snapshot());
      final count = (state.schedePersonaggio as List).length;
      expect(
        await applyAndPump(
          tester,
          () => p.applyAssignment(collision, p.snapshot(), preserveCopy: false),
        ),
        isFalse,
      );
      expect((state.schedePersonaggio as List).length, count);
      expect(jsonEncode(p.snapshot()), before);
      state.realtimeService = null;
      await transport.dispose();
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'Master moves the given sheet into Online only after verified saving',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final transport = _AssignmentTransport('master-user', master: true);
      state.realtimeService = transport;
      await prepareSave(tester, state);
      final tag = p.ownerTag();
      final item = receipt(tag);
      final body = p.assignmentBody(0);
      expect(
        await applyAndPump(
          tester,
          () => p.applyAssignment(item, body, preserveCopy: false),
        ),
        isTrue,
      );
      expect((state.schedePersonaggio as List), hasLength(1));
      expect(state.schedePersonaggio[0]['realtimeSharedSheet'], isTrue);
      expect(state.schedePersonaggio[0]['realtimeSourceSheetTag'], tag);
      expect(
        state.sheetSidebarPlacements[tag]['folder'],
        'oculum_received_online_sheets',
      );
      expect((state.realtimeSharedSheets as List), hasLength(1));
      final saved = await tester.runAsync(p.savedRaw);
      expect(saved, contains(oculumSheetAssignmentReceipt(item, local: false)));
      state.realtimeService = null;
      await transport.dispose();
      await closeFixture(tester, p);
    },
  );
}
