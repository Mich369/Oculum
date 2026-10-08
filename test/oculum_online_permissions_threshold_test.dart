import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionTestService extends OculumRealtimeService {
  PermissionTestService()
    : super(
        roomId: 'permission_test',
        playerName: 'Rose',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      );
  bool sendSucceeds = true;
  final sent = <Map<String, dynamic>>[];
  @override
  bool get isConnected => true;
  @override
  Future<bool> sendPermissionEvent(
    String event,
    Map<String, dynamic> payload,
  ) async {
    sent.add({'event': event, ...payload});
    return sendSucceeds;
  }
}

class _FixedThresholdRandom implements Random {
  const _FixedThresholdRandom(this.value);

  final int value;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => value.clamp(0, max - 1).toInt();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Only online players require approval; every threshold skill has an explicit cost and cooldown',
    () {
      final temporaryGrant = healOculumHp(
        current: 20,
        maximum: 20,
        temporary: 0,
        amount: 50,
        temporaryLimit: oculumTemporaryHpLimit + 50,
      );
      expect(temporaryGrant.temporary, 50);
      for (final online in [false, true]) {
        for (final staff in [false, true]) {
          expect(
            oculumActionNeedsApproval(online: online, staff: staff),
            online && !staff,
          );
        }
      }
      expect(oculumFirstThresholdStat({'volonta': 5, 'resilienza': 3}), isNull);
      expect(
        oculumFirstThresholdStat({'volonta': 6, 'resilienza': 3}),
        'volonta',
      );
      expect(
        oculumCreateThresholdSkill(
          'resilienza',
          0,
          random: const _FixedThresholdRandom(0),
        ).thresholdData['longRestsRemaining'],
        4,
      );
      expect(
        oculumCreateThresholdSkill(
          'resilienza',
          0,
          random: const _FixedThresholdRandom(8),
        ).thresholdData['longRestsRemaining'],
        12,
      );
      for (final stat in oculumStatThresholdSkills.keys) {
        for (var variant = 0; variant < 3; variant++) {
          final skill = oculumCreateThresholdSkill(stat, variant);
          expect(
            skill.forme.single.cooldownStrutturato!.amount,
            greaterThan(0),
          );
          expect(
            skill.forme.single.costoStrutturato!.resource,
            stat == 'resilienza' && variant == 0 ? 'oculum' : stat,
          );
          expect(CharacterSkill.fromJson(skill.toJson()).nome, skill.nome);
          if (stat == 'volonta') {
            expect(skill.volonta, 3);
            expect(skill.danni, inInclusiveRange(16, 25));
            expect(skill.equipaggiata, isTrue);
          } else if (stat == 'materia') {
            expect(skill.materia, 3);
            expect(skill.difesa, inInclusiveRange(15, 20));
          } else if (stat == 'resilienza') {
            expect(skill.resilienza, 3);
            expect(skill.thresholdData['temporaryHpRemaining'], 50);
            expect(
              skill.thresholdData['longRestsRemaining'],
              inInclusiveRange(4, 12),
            );
            final restored = CharacterSkill.fromJson(skill.toJson());
            expect(
              restored.thresholdData['longRestsGranted'],
              skill.thresholdData['longRestsGranted'],
            );
          }
        }
      }
    },
  );

  testWidgets(
    'Permissions validate the sender, log decisions, and remain pending on failed sends',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final directory = Directory(
        'build/permission-test-${DateTime.now().microsecondsSinceEpoch}',
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
      tester.view.physicalSize = const Size(1440, 900);
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
      final probe = OculumPerformanceProbe(state);
      if (state.schedePersonaggio.isEmpty) {
        state.schedePersonaggio.add(<String, dynamic>{
          'id': 'ROSE-1234',
          'sheetTag': 'ROSE-1234',
          'nome': 'Rose',
        });
        state.schedaCorrente = 0;
      }
      final tag = '${probe.snapshot()['sheetTag']}';
      state.updateOculumHomeUi(() {
        state.datiCaricati = true;
        state.tutorialCompletato = true;
        state.modalitaMaster = false;
        state.sonoCoMaster = false;
        state.resilienzaController.text = '3';
        state.volontaController.text = '5';
        state.materiaController.text = '0';
        state.oculumController.text = '1';
        state.tempVolonta = 999;
      });
      expect(probe.canActWithoutApproval, isTrue);
      expect(probe.grantThreshold(variant: 0), isFalse);
      state.datiCaricati = false;
      state.volontaController.text = '6';
      state.datiCaricati = true;
      expect(
        probe.grantThreshold(stat: 'volonta', variant: 0),
        isTrue,
        reason:
            'reward=${state.statThresholdReward}, sheets=${state.schedePersonaggio.length}, selected=${state.schedaCorrente}, loading=${state.loadingThresholdSheet}',
      );
      expect(state.skills.last.nome, 'Schianto distruttivo');
      state.resilienzaController.text = '6';
      expect(probe.grantThreshold(stat: 'resilienza', variant: 0), isFalse);
      expect(
        probe.snapshot()['statThresholdReward'],
        'volonta:Schianto distruttivo',
      );

      final service = PermissionTestService();
      state.realtimeService = service;
      expect(probe.canActWithoutApproval, isFalse);
      probe.requestAction('monster_entry', 'Ingresso Riccio Aculeo');
      expect(state.onlinePermissionRequests.length, 1);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('online_permission_button')),
        findsNothing,
      );
      final request = Map<String, dynamic>.from(
        state.onlinePermissionRequests.values.single as Map,
      );
      state.realtimeUsers = <Map<String, dynamic>>[
        {
          'sessionId': 'master_session',
          'campaignId': state.activeCampaignId,
          'activeSheetTag': 'MASTER',
          'role': 'master',
        },
        {
          'sessionId': 'co_session',
          'campaignId': state.activeCampaignId,
          'activeSheetTag': 'CO',
          'role': 'coMaster',
        },
      ];
      final role = <String, dynamic>{
        'scope': probe.permissionScope,
        'campaignId': state.activeCampaignId,
        'sessionId': 'co_session',
        'senderTag': 'CO',
        'senderRole': 'coMaster',
        'targetTag': tag,
        'coMaster': true,
        'trusted': true,
        'sentAt': DateTime.now().toIso8601String(),
      };
      probe.receiveRole(role);
      expect(
        state.sonoCoMaster,
        isFalse,
        reason: 'An untrusted Co-Master cannot promote',
      );
      probe.receiveRole({
        ...role,
        'sessionId': 'master_session',
        'senderTag': 'MASTER',
        'senderRole': 'master',
      });
      expect(state.sonoCoMaster, isTrue);
      expect(state.coMasterCanSetCoMaster, isTrue);
      expect(probe.masterPermissions, isTrue);
      state.updateOculumHomeUi(() {});
      await tester.pump();
      expect(
        find.byKey(const ValueKey('online_permission_button')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('online_permission_button')));
      await tester.pumpAndSettle();
      expect(find.text('Consenti'), findsOneWidget);
      expect(find.text('Rifiuta'), findsOneWidget);
      service.sendSucceeds = false;
      await probe.decideRequest(request, false);
      expect(
        state.onlinePermissionRequests[request['id']]['status'],
        'pending',
      );
      service.sendSucceeds = true;
      await probe.decideRequest(request, false);
      await tester.pump();
      expect(
        state.onlinePermissionRequests[request['id']]['status'],
        'rejected',
      );
      expect(find.text('Rifiutato'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
