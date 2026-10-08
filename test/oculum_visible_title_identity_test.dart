import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final size in [const Size(1440, 900), const Size(390, 844)]) {
    testWidgets('Visible title identity remains linked at $size', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final font = await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
      for (final family in ['Poppins', 'Roboto', 'serif', 'Georgia']) {
        await (FontLoader(family)..addFont(Future.value(font))).load();
      }
      final directory = Directory(
        'build/current-screen-dice-${DateTime.now().microsecondsSinceEpoch}',
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
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const OculumHomePage(),
        ),
      );
      final dynamic state = tester.state(find.byType(OculumHomePage));
      state.tutorialDialogPending = true;
      await tester.runAsync(() async {
        for (var i = 0; i < 100 && !state.datiCaricati; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      });
      final title = OculumTitle.fromJson({
        'nome': 'Uccidi Bunnys',
        'leggenda': 'Leggenda originale',
        'equipaggiato': true,
        'evoluto': true,
      });
      state.updateOculumHomeUi(() {
        state.tutorialCompletato = true;
        state.datiCaricati = true;
        state.paginaCorrente = 0;
        state.nuovoDesignOculum = 'cattedrale';
        state.temiOldSchool = false;
        state.nomeController.text = 'Rose';
        state.titoli.clear();
        state.trattiRazziali.clear();
        state.titoli.add(title);
      });
      await tester.pump(const Duration(seconds: 1));
      final heading = find.text('Rose | Uccidi Bunnys');
      expect(heading, findsOneWidget);
      await tester.ensureVisible(heading);
      await tester.longPress(heading);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Leggenda'), findsOneWidget);
      expect(find.text('Bonus'), findsNothing);
      final fields = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      expect(fields, findsNWidgets(2));
      await tester.enterText(fields.first, 'Nuovo titolo');
      await tester.enterText(fields.last, 'Nuova leggenda');
      await tester.tap(find.text('Chiudi'));
      await tester.pumpAndSettle();
      expect(title.nome, 'Nuovo titolo');
      expect(title.leggenda, 'Nuova leggenda');
      expect(find.text('Rose | Nuovo titolo'), findsOneWidget);
      expect(title.sempreVisibile, isTrue);
      state.updateOculumHomeUi(() {
        state.scudoController.text = '9999';
        state.scudoOculumController.text = '0';
      });
      await tester.pumpAndSettle();
      expect(find.text('Vita e scudo'), findsWidgets);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(const ValueKey('reference_shield_bar')),
            )
            .value,
        1,
      );
      expect(tester.takeException(), isNull);
      final probe = OculumPerformanceProbe(state);
      final tag = '${probe.snapshot()['sheetTag']}';
      final pawn = OculumPawnGuardian(
        id: 'damage_test_pawn',
        ownerTag: tag,
        targets: [tag],
      );
      state.updateOculumHomeUi(() {
        state.currentHpController.text = '5000';
        state.scudoController.text = '10';
        state.scudoOculumMaxController.text = '5';
        state.scudoOculumController.text = '5';
        state.pawnGuardians.add(pawn);
      });
      await probe.damageResolved(1000, critical: true);
      await tester.pump();
      expect(
        pawn.hp,
        0,
        reason: 'Pawn must receive the HP overflow from a critical hit',
      );
      expect(int.parse(state.currentHpController.text), lessThan(5000));
      expect(int.parse(state.scudoOculumController.text), 0);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
