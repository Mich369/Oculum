import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:io';

void main() {
  testWidgets('offline effects stay manual and do not debuff their caster', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final directory = Directory(
      'build/offline-target-${DateTime.now().microsecondsSinceEpoch}',
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
    await tester.pumpWidget(
      MaterialApp(theme: ThemeData.dark(), home: const OculumHomePage()),
    );
    final dynamic state = tester.state(find.byType(OculumHomePage));
    state.tutorialDialogPending = true;
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    state.datiCaricati = true;
    state.tutorialCompletato = true;
    state.activeConditions.clear();
    state.activeStructuredEffects.clear();
    final probe = OculumPerformanceProbe(state);
    if (state.schedePersonaggio.isEmpty) {
      state.schedePersonaggio.add(
        Map<String, dynamic>.from(probe.snapshot())
          ..['id'] = 'CASTER'
          ..['sheetTag'] = 'CASTER',
      );
      state.schedaCorrente = 0;
    }
    final before = probe.defenseCm();
    state.onlineCombatRequests['history'] = <String, dynamic>{
      'id': 'history',
      'status': 'resolved',
    };
    state.onlinePermissionRequests['approval'] = <String, dynamic>{
      'id': 'approval',
      'status': 'pending',
    };
    state.realtimeSelectedEncounterId = 'shared-fight';
    state.realtimeVisibleInitiativeSnapshot = <String, dynamic>{
      'encounterId': 'shared-fight',
      'round': 7,
      'activeIndex': 1,
      'tokens': <Map<String, dynamic>>[
        {'id': 'CASTER', 'actionUsed': true, 'reactionUsed': 1},
      ],
    };
    state.realtimeEncounterSnapshots = <Map<String, dynamic>>[
      Map<String, dynamic>.from(state.realtimeVisibleInitiativeSnapshot as Map),
    ];
    probe.applyEffects([
      OculumStructuredEffect(
        type: 'modifica_statistica',
        target: 'cm',
        mode: 'diminuzione',
        valueExpression: '4',
        duration: '2',
        recipient: 'bersaglio',
      ),
    ]);
    expect(probe.defenseCm(), before);
    probe.ensureEncounters();
    state.masterInitiativePublished = true;
    state.masterInitiativeTokens.clear();
    state.masterInitiativeTokens.add(<String, dynamic>{
      'id': 'manual-combatant',
      'name': 'Custode',
      'status': 'active',
      'actionUsed': true,
      'reactionMax': 1,
      'reactionUsed': 1,
    });
    final publicFight = probe.initiativeSnapshot();
    final publicToken = (publicFight['tokens'] as List).single as Map;
    expect(publicToken['actionUsed'], isTrue);
    expect(publicToken['reactionMax'], 1);
    expect(publicToken['reactionUsed'], 1);
    expect(publicToken['reactionAvailable'], 0);
    final token = state.masterInitiativeTokens.single as Map<String, dynamic>;
    probe.refreshEncounterResources(token);
    expect(token['reactionUsed'], 0);
    expect(token['reactionMax'], 1);
    expect(token['actionUsed'], isFalse);
    probe.refreshEncounterResources(token);
    expect(
      token['reactionMax'],
      1,
      reason: 'Refreshing never accumulates reactions',
    );
    final otherFight = probe.publicEncounter({
      'id': 'other-fight',
      'round': 99,
      'activeIndex': 0,
      'tokens': [
        {
          'id': 'other-actor',
          'reactionMax': 1,
          'reactionUsedRound': 99,
          'reactionFastMax': 2,
          'reactionFastUsed': 2,
          'reactionFastTurnKey': '99:other-actor',
        },
      ],
    });
    final otherToken = (otherFight['tokens'] as List).single as Map;
    expect(otherToken['reactionUsed'], 1);
    expect(
      otherToken['reactionAvailable'],
      0,
      reason:
          'Each published encounter uses its own round and active participant',
    );
    expect(state.activeStructuredEffects.single['type'], 'pending_target');
    final source = state.schedaCorrente as int;
    final target = Map<String, dynamic>.from(probe.snapshot())
      ..['nome'] = 'Bersaglio locale'
      ..['sheetTag'] = 'LOCAL-TARGET'
      ..['id'] = 'LOCAL-TARGET'
      ..['activeStructuredEffects'] = <dynamic>[];
    state.schedePersonaggio.add(target);
    final index = state.schedePersonaggio.length - 1;
    final pending = Map<String, dynamic>.from(
      state.activeStructuredEffects.single as Map,
    );
    // Use the actual pending instance, as the UI does.
    final future = probe.applyLocalTargetEffect(
      state.activeStructuredEffects.single as Map<String, dynamic>,
    );
    await tester.pump();
    await tester.tap(find.text('Bersaglio locale'));
    var completed = false;
    future.then((_) => completed = true);
    for (var attempt = 0; attempt < 100 && !completed; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
    }
    expect(
      completed,
      isTrue,
      reason:
          'Manual target transfer must complete: selected=${state.schedaCorrente}, log=${state.logEventi}',
    );
    await tester.pump();
    expect(state.schedaCorrente, source);
    expect(state.onlineCombatRequests.containsKey('history'), isTrue);
    expect(state.onlinePermissionRequests.containsKey('approval'), isTrue);
    expect(state.realtimeSelectedEncounterId, 'shared-fight');
    expect(state.realtimeVisibleInitiativeSnapshot['round'], 7);
    expect(state.realtimeVisibleInitiativeSnapshot['activeIndex'], 1);
    expect(
      state.realtimeVisibleInitiativeSnapshot['tokens'][0]['actionUsed'],
      isTrue,
    );
    expect(
      state.realtimeEncounterSnapshots.single['encounterId'],
      'shared-fight',
    );
    expect(
      (state.schedePersonaggio[index]['activeStructuredEffects'] as List).any(
        (e) => e['value'] == -4 && e['target'] == 'cm',
      ),
      isTrue,
      reason: '$pending',
    );
    expect(probe.defenseCm(), before);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });
}
