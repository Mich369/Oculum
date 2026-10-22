import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'Master snapshot enables purchased weak points without sharing monster sheets',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final directory = Directory(
        'build/online-monster-knowledge-${DateTime.now().microsecondsSinceEpoch}',
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
      await tester.pumpWidget(const MaterialApp(home: OculumHomePage()));
      final dynamic state = tester.state(find.byType(OculumHomePage));
      state.tutorialDialogPending = true;
      final probe = OculumPerformanceProbe(state);
      await tester.runAsync(() async {
        state.saveBlobDirectoryFuture = Future<Directory>.value(directory);
        state.sharedPreferencesFuture = Future<SharedPreferences>.value(
          await SharedPreferences.getInstance(),
        );
        await probe.reloadSave();
      });
      state.datiCaricati = false;
      state.schedePersonaggio
        ..clear()
        ..addAll(<Map<String, dynamic>>[
          {'id': 'PLAYER', 'sheetTag': 'PLAYER', 'nome': 'Esploratore'},
          {
            'id': 'GOLEM',
            'sheetTag': 'GOLEM',
            'nome': 'Golem Runico',
            'tipoScheda': 'Mostro',
            'monsterBookSourceId': 'golem_runico',
            'currentHp': '60',
          },
        ]);
      state.schedaCorrente = 0;
      final group = <String, dynamic>{
        'id': 'knowledge-fight',
        'name': 'Rovine',
        'round': 1,
        'activeIndex': 0,
        'tokens': [
          {
            'id': 'GOLEM',
            'sheetTag': 'GOLEM',
            'name': 'Golem Runico',
            'type': 'Mostro',
            'side': 'enemy',
            'currentHp': 60,
            'maxHp': 60,
          },
        ],
      };
      final snapshot = probe.publicEncounter(group);
      final token = Map<String, dynamic>.from(
        (snapshot['tokens'] as List).single as Map,
      );
      expect(token['monsterBookId'], 'golem_runico');
      expect(token['name'], '???');
      expect(token, isNot(contains('monsterBookSourceId')));
      expect(token, isNot(contains('stats')));
      expect(token, isNot(contains('conditions')));

      // The player only has the public snapshot. The Master's private creature
      // sheet must not be necessary for the real weak-point availability check.
      state.schedePersonaggio.removeAt(1);
      state.modalitaMaster = false;
      state.sonoCoMaster = false;
      state.realtimeVisibleInitiativeSnapshot = snapshot;
      expect(probe.knowsCombatWeakPoint(token), isFalse);
      state.realtimeUsers = <Map<String, dynamic>>[
        {
          'sessionId': 'master-session',
          'role': 'master',
          'localSheetTags': <String>['MASTER'],
          'activeSheetTag': 'MASTER',
        },
      ];
      probe.receiveMonsterBookDiscoverySnapshot(<String, dynamic>{
        'monsterBookDiscoverySnapshot': true,
        'scope': probe.permissionScope,
        'campaignId': probe.permissionCampaignId,
        'senderTag': 'MASTER',
        'senderRole': 'master',
        'sessionId': 'master-session',
        'discoveries': <Map<String, dynamic>>[
          {
            'monsterBookId': 'golem_runico',
            'seen': true,
            'nameKnown': true,
            'weakPoint': true,
            'pagePurchased': true,
          },
        ],
      });
      expect(probe.knowsCombatWeakPoint(token), isTrue);
      expect(probe.partyKnowsMonsterName('golem_runico'), isTrue);
      expect(
        probe.monsterBookDiscoverySnapshotEntries(),
        contains(containsPair('monsterBookId', 'golem_runico')),
      );
      state.monsterBookPartyDiscoveries.clear();
      probe.receiveMonsterBookDiscoverySnapshot(<String, dynamic>{
        'monsterBookDiscoverySnapshot': true,
        'scope': probe.permissionScope,
        'campaignId': probe.permissionCampaignId,
        'senderTag': 'MASTER',
        'senderRole': 'master',
        'sessionId': 'offline-or-forged-session',
        'discoveries': <Map<String, dynamic>>[
          {'monsterBookId': 'golem_runico', 'weakPoint': true},
        ],
      });
      expect(probe.knowsCombatWeakPoint(token), isFalse);
      probe.rememberMonsterPage('golem_runico');
      expect(probe.knowsCombatWeakPoint(token), isTrue);
      expect(
        token['name'],
        '???',
        reason: 'Knowledge does not mutate a snapshot',
      );

      final legacyGroup = {
        ...group,
        'tokens': [
          {...token, 'monsterBookId': 'golem_runico'},
        ],
      };
      expect(
        ((probe.publicEncounter(legacyGroup)['tokens'] as List).single
            as Map)['monsterBookId'],
        'golem_runico',
        reason: 'Already identified tokens retain their stable catalog ID',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );
}
