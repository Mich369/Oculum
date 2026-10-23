import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oculum/main.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

void main() {
  testWidgets(
    'planar rules resolve on production activation damage and rest paths',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final regular = await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
      for (final family in [
        'Poppins',
        'Roboto',
        'serif',
        'Segoe UI',
        'Garamond',
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
      final directory = Directory('build/layout-test-data')
        ..createSync(recursive: true);
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
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final capture = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: RepaintBoundary(key: capture, child: const OculumHomePage()),
        ),
      );
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pump(const Duration(seconds: 1));
      final dynamic state = tester.state(find.byType(OculumHomePage));
      final probe = OculumPerformanceProbe(state);

      if (state.schedePersonaggio.isEmpty) {
        state.schedePersonaggio.add(<String, dynamic>{
          'id': 'PLANAR_TEST',
          'sheetTag': 'PLANAR_TEST',
          'nome': 'Prova',
          'inMasterParty': true,
        });
        state.schedaCorrente = 0;
      }
      final inspirationBefore = int.parse(
        state.ispirazioniController.text as String,
      );
      probe.fateGrade(0, 1, 6);
      expect(
        int.parse(state.ispirazioniController.text as String),
        inspirationBefore + 1,
      );
      probe.fateGrade(0, 1, 99);
      expect(
        int.parse(state.ispirazioniController.text as String),
        inspirationBefore + 1,
      );
      probe.chooseChaos(true);
      probe.fateGrade(1, 2, 99);
      probe.chooseChaos(false);
      probe.fateGrade(1, 2, 99);
      expect(
        int.parse(state.ispirazioniController.text as String),
        inspirationBefore + 1,
      );
      probe.chooseChaos(true);
      probe.chaosStats([-3, 0, 3, 1]);
      expect(probe.planarStateSnapshot()['chaosStats'], {
        'resilienza': -3,
        'volonta': 0,
        'materia': 3,
        'oculum': 1,
      });
      probe.finishPlanarFight();
      expect(probe.planarStateSnapshot().containsKey('chaosStats'), false);
      expect(probe.planarStateSnapshot()['identityRewardMaxGrade'], 2);
      probe.chooseChaos(false);
      state.resilienzaController.text = '10';
      state.currentResilienzaController.text = '10';
      state.currentHpController.text = '100';
      final normalHp = probe.maximumHp();
      probe.applyEffects([
        OculumStructuredEffect(
          type: 'planar',
          target: 'annihilation',
          valueExpression: '30',
          duration: '3',
        ),
      ]);
      expect(
        state.titoli.any(
          (dynamic t) => t.chiaveSistema == 'planar_annihilation',
        ),
        isTrue,
      );
      expect(probe.maximumHp(), lessThan(normalHp));
      probe.restPlanar();
      probe.restPlanar();
      expect(
        state.titoli.any(
          (dynamic t) => t.chiaveSistema == 'planar_annihilation',
        ),
        isTrue,
      );
      probe.restPlanar();
      expect(
        state.titoli.any(
          (dynamic t) => t.chiaveSistema == 'planar_annihilation',
        ),
        isFalse,
      );
      probe.applyEffects([
        OculumStructuredEffect(
          type: 'planar',
          target: 'super_armor',
          valueExpression: '1',
          duration: '3',
        ),
      ]);
      for (var i = 0; i < 3; i++) {
        expect(probe.planarIncoming(101), 51);
      }
      expect(probe.planarIncoming(101), 101);
      probe.applyEffects([
        OculumStructuredEffect(
          type: 'planar',
          target: 'vanish',
          valueExpression: '1',
          duration: '1',
        ),
      ]);
      expect(probe.planarIncoming(100), 0);
      expect(probe.planarIncoming(100, element: 'fuoco'), 100);
      probe.tickPlanar();
      expect(probe.planarIncoming(100), 100);
      probe.applyEffects([
        OculumStructuredEffect(
          type: 'planar',
          target: 'rock_scales',
          valueExpression: '1',
          duration: '2',
        ),
      ]);
      expect(probe.planarIncoming(100, element: 'taglio'), 0);
      expect(
        probe.planarIncoming(100, element: 'contundente', kind: 'schianto'),
        100,
      );
      expect(probe.planarIncoming(100, element: 'taglio', magical: true), 50);
      probe.finishPlanarFight();
      final before = probe.maximumHp();
      probe.applyEffects([
        OculumStructuredEffect(
          type: 'planar',
          target: 'max_power',
          valueExpression: '1',
          duration: '1',
        ),
      ]);
      expect(probe.maximumHp(), before * 2);
      probe.finishPlanarFight();
      expect(probe.maximumHp(), before);
      probe.applyEffects([
        OculumStructuredEffect(
          type: 'planar',
          target: 'lightning_charge',
          valueExpression: '3',
        ),
      ]);
      expect(probe.planarStateSnapshot()['chargeNeeded'], 2);
      probe.planarIncoming(10, element: 'fuoco');
      expect(probe.planarStateSnapshot()['chargePower'], isNull);
      state.livelloController.text = '3';
      state.gradoController.text = '0';
      state.oculumController.text = '10';
      state.currentOculumController.text = '10';
      final empowering = probe.empowermentDialog();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(
        find.byKey(const ValueKey('fight_roll_empowerment_amount')),
        '2',
      );
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('fight_roll_empowerment_confirm')),
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(
        find.byKey(const ValueKey('fight_roll_empowerment_amount')),
        '1',
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('fight_roll_empowerment_confirm')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await empowering;
      expect(probe.preparedRollAmount(), 1);
      final spent = probe.consumeRollEmpowerment();
      expect(spent.spent, 1);
      expect(spent.bonus, 3);
      expect(spent.damageBonus, 2);
      expect(probe.preparedRollAmount(), 0);
      state.currentOculumController.text = '10';
      state.oculumController.text = '10';
      probe.applyEffects([
        OculumStructuredEffect(
          type: 'preparazione',
          target: 'attacco',
          activationOption: 'concentrazione',
          valueExpression: '40',
          chargeOculumPerTurn: 1,
          chargeDamageSteps: [40, 80, 120, 180],
        ),
      ]);
      for (var step = 1; step <= 3; step++) {
        state.playerReportedTurn += 1;
        await probe.growCharge();
        expect(
          (probe.planarStateSnapshot()['preparedSkill'] as Map)['power'],
          [40, 80, 120, 180][step],
        );
      }
      expect(probe.releasePrepared('attacco')['power'], 180);
      final oldDefense = probe.defense();
      final oldMovement = probe.movement();
      probe.applyEffects([
        OculumStructuredEffect(
          type: 'planar',
          target: 'flight',
          valueExpression: '3',
          duration: '2',
        ),
      ]);
      expect(probe.defense(), oldDefense + 3);
      expect(probe.movement(), oldMovement + 3);
      probe.tickPlanar();
      expect(probe.movement(), oldMovement + 3);
      probe.tickPlanar();
      expect(probe.defense(), oldDefense);
      expect(probe.movement(), oldMovement);
      probe.applyEffects([
        OculumStructuredEffect(
          type: 'preparazione',
          target: 'attacco',
          valueExpression: '100',
          sourceScrollGrade: 2,
          activationOption: 'concentrazione',
        ),
      ]);
      expect(probe.planarStateSnapshot()['preparedSkill'], isA<Map>());
      expect(
        probe.interruptPrepared(attackerGrade: 12, percentile: 99),
        isTrue,
      );
      expect(probe.planarStateSnapshot()['preparedSkill'], isNull);
      final effectsPanel = probe.effectsEditor([
        OculumStructuredEffect(
          id: 'windows_damage',
          type: 'danno',
          valueExpression: '4+oculum_spent',
          mode: 'prossima_azione',
        ),
        OculumStructuredEffect(
          id: 'windows_defense',
          type: 'difesa',
          valueExpression: '3',
          duration: '1',
        ),
      ]);
      final panels = [
        for (final width in [320.0, 390.0, 768.0])
          SizedBox(width: width, child: probe.vitalsHud()),
      ];
      for (var i = 0; i < panels.length; i++) {
        final width = [320, 390, 768][i];
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: Center(child: panels[i])),
          ),
        );
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Vitals at width $width',
        );
      }
      final effectsCapture = GlobalKey();
      tester.view.physicalSize = const Size(800, 900);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: RepaintBoundary(key: effectsCapture, child: effectsPanel),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Impostazioni avanzate · effetti'));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsAtLeastNWidgets(2));
      expect(find.byType(ReorderableListView), findsNothing);
      expect(tester.takeException(), isNull);
      final boundary =
          effectsCapture.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      expect(boundary.size.height, lessThan(650));
      await tester.runAsync(() async {
        final captureImage = await boundary.toImage(pixelRatio: 1);
        final captureBytes = await captureImage.toByteData(
          format: ui.ImageByteFormat.png,
        );
        File(
          'build/windows-effects-editor-fixed.png',
        ).writeAsBytesSync(captureBytes!.buffer.asUint8List());
        captureImage.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
