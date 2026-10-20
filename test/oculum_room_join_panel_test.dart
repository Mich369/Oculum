import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _PendingRoomService extends OculumRealtimeService {
  _PendingRoomService()
    : super(
        roomId: 'test',
        playerName: 'Player',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      );
  @override
  bool get isConnecting => true;
  @override
  bool get isAwaitingApproval => true;
  @override
  bool get masterRoleUnavailable => true;
}

void main() {
  testWidgets(
    'pending room shows cancel instead of another Connect and keeps password out of saves',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final directory = Directory(
        'build/room-panel-${DateTime.now().microsecondsSinceEpoch}',
      )..createSync(recursive: true);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => directory.absolute.path,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        (_) async => ['none'],
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
        (_) async => null,
      );
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(theme: ThemeData.dark(), home: const OculumHomePage()),
      );
      final dynamic state = tester.state(find.byType(OculumHomePage));
      state.tutorialDialogPending = true;
      await tester.runAsync(() async {
        for (var i = 0; i < 100 && !state.datiCaricati; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      });
      state.updateOculumHomeUi(() {
        state.tutorialCompletato = true;
        state.datiCaricati = true;
        state.paginaCorrente = 12;
        state.modalitaMaster = true;
        state.realtimeConnecting = true;
        state.realtimeService = _PendingRoomService();
        state.realtimeRoomPasswordController.text = 'private-room-secret';
      });
      unawaited(state.vaiAllaFunzione(page: 12));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.scrollUntilVisible(
        find.text('Realtime Oculum'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      final waiting = find.widgetWithText(
        ElevatedButton,
        'In attesa del Master',
      );
      expect(waiting, findsOneWidget);
      expect(tester.widget<ElevatedButton>(waiting).onPressed, isNull);
      final cancel = find.widgetWithText(ElevatedButton, 'Annulla ingresso');
      expect(tester.widget<ElevatedButton>(cancel).onPressed, isNotNull);
      expect(
        find.textContaining('La stanza appartiene a un altro account'),
        findsOneWidget,
      );
      expect(find.text('Crea nuova stanza'), findsOneWidget);
      expect(find.text('Password stanza (opzionale)'), findsOneWidget);
      final probe = OculumPerformanceProbe(state);
      expect('${probe.snapshot()}', isNot(contains('private-room-secret')));
      probe.receivePermission('permission_request', {
        'id': 'sheet_identity:authenticated-player:OLD-TAG',
        'action': 'sheet_identity_conflict',
        'authenticatedUserId': 'authenticated-player',
        'authenticatedRole': 'player',
        'requestedSheetTag': 'OLD-TAG',
        'requesterName': 'Rose',
      });
      expect(
        state
            .onlinePermissionRequests['sheet_identity:authenticated-player:OLD-TAG']['unread'],
        isTrue,
      );
      expect(
        state
            .onlinePermissionRequests['sheet_identity:authenticated-player:OLD-TAG']['status'],
        'pending',
      );
      probe.receivePermission('permission_request', {
        'id': 'forged',
        'action': 'sheet_identity_conflict',
        'requestedSheetTag': 'OTHER-TAG',
      });
      expect(state.onlinePermissionRequests.containsKey('forged'), isFalse);
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('online_permission_button')).first,
      );
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Rose'), findsOneWidget);
      expect(find.text('Ricevuto'), findsOneWidget);
      await tester.tap(find.text('Ricevuto'));
      await tester.pump();
      expect(
        state
            .onlinePermissionRequests['sheet_identity:authenticated-player:OLD-TAG']['status'],
        'reviewed',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );
}

