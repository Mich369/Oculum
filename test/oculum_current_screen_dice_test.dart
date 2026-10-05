import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final size in [const Size(1440, 900), const Size(390, 844)]) {
    testWidgets('Dice stay on the current screen at $size', (tester) async {
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
      state.updateOculumHomeUi(() {
        state.tutorialCompletato = true;
        state.datiCaricati = true;
        state.paginaCorrente = 8;
        state.diceAmountController.text = '2';
        state.diceModifierController.text = '3';
        state.difficoltaTiroController.text = '0';
        state.hiddenEyeStats.add(
          HiddenEyeStat(id: 'nodo', nome: 'Karma', descrizione: 'Test'),
        );
      });
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byKey(const ValueKey('current_screen_dice')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final panel = find.byKey(const ValueKey('current_screen_dice_panel'));
      expect(panel, findsOneWidget);
      expect(state.paginaCorrente, 8);
      final die = find.descendant(of: panel, matching: find.text('d4'));
      final list = find.descendant(of: panel, matching: find.byType(ListView));
      for (var i = 0; i < 10 && die.hitTestable().evaluate().isEmpty; i++) {
        await tester.drag(list, const Offset(0, -200));
        await tester.pump(const Duration(milliseconds: 150));
      }
      expect(die.hitTestable(), findsOneWidget);
      final spinSeedBeforeRoll = state.dadoOverlaySpinSeed as int;
      await tester.tap(die);
      await tester.pump(const Duration(seconds: 1));
      expect(state.risultato, contains('2d4'));
      expect(
        find.descendant(of: panel, matching: find.text(state.risultato)),
        findsOneWidget,
      );
      expect(state.paginaCorrente, 8);
      expect(state.mostraOverlayDado, isTrue);
      expect(state.dadoOverlaySpinSeed, spinSeedBeforeRoll + 1);
      final overlay = find.byKey(const ValueKey('current_route_dice_overlay'));
      final rotation = tester.widget<AnimatedRotation>(
        find
            .descendant(of: overlay, matching: find.byType(AnimatedRotation))
            .first,
      );
      expect(rotation.turns, (spinSeedBeforeRoll + 1).toDouble());
      await tester.tapAt(tester.getCenter(panel));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.byKey(const ValueKey('close_current_screen_dice')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(panel, findsNothing);
      expect(state.paginaCorrente, 8);
      expect(state.mostraOverlayDado, isFalse);
      // The quick-dice link must use the same panel, not a detail page.
      OculumPerformanceProbe(state).openDice();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(panel, findsOneWidget);
      expect(state.referenceDetailRouteActive, isFalse);
      expect(state.paginaCorrente, 8);
      await tester.tap(find.byKey(const ValueKey('close_current_screen_dice')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final probe = OculumPerformanceProbe(state);
      probe.openSubtraits();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(state.referenceDetailRouteActive, isTrue);
      await probe.rollSubtrait('nodo');
      await tester.pump(const Duration(seconds: 1));
      expect(overlay.hitTestable(), findsOneWidget);
      expect(state.referenceDetailRouteActive, isTrue);
      await tester.tapAt(tester.getCenter(overlay));
      await tester.pump(const Duration(milliseconds: 250));
      expect(overlay, findsNothing);
      // Rolls also appear above a dialog, which has its own Navigator route.
      showDialog<void>(
        context: state.context,
        builder: (_) => const AlertDialog(title: Text('Test tiro nel dialogo')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await probe.rollSubtrait('nodo');
      await tester.pump(const Duration(seconds: 1));
      expect(overlay.hitTestable(), findsOneWidget);
      await tester.tapAt(tester.getCenter(overlay));
      await tester.pump(const Duration(milliseconds: 250));
      Navigator.of(state.context).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      Navigator.of(state.context).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      probe.openResistances();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final search = find.byKey(const ValueKey('resistance_element_search'));
      final statsBeforeSearch = probe.coreStats();
      final inventoryBeforeSearch = probe.snapshot()['inventario'];
      await tester.enterText(search, 'fuoco');
      await tester.pump();
      expect(
        find.byKey(const ValueKey('resistance_element_fuoco')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('resistance_element_gelo')),
        findsNothing,
      );
      await tester.enterText(search, 'nessun-elemento-123');
      await tester.pump();
      expect(find.text('Nessun elemento trovato.'), findsOneWidget);
      await tester.tap(find.byTooltip('Cancella ricerca'));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('resistance_element_gelo')),
        findsOneWidget,
      );
      expect(probe.coreStats(), statsBeforeSearch);
      expect(probe.snapshot()['inventario'], inventoryBeforeSearch);
      final scroll = oculumScrollItem('gelo', 'Ghiaccio', 0, 'ward')
        ..quantita = 2;
      state.inventario.add(scroll);
      state.difficoltaTiroController.text = '-100';
      final coreBeforeScroll = probe.coreStats();
      final defenseBeforeScroll = probe.defense();
      final cancelUse = probe.useScroll(scroll);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Annulla').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await cancelUse;
      expect(scroll.quantita, 2);
      final use = probe.useScroll(scroll);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Usa e tira'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await use;
      expect(scroll.quantita, 1);
      expect(state.dadoMostrato, state.dadoOverlay);
      expect(state.tiroCriticoUno, state.overlayCriticoUno);
      expect(state.tiroCriticoVenti, state.overlayCriticoVenti);
      expect(probe.coreStats(), coreBeforeScroll);
      expect(
        probe.defense(),
        defenseBeforeScroll + (state.overlayCriticoUno ? 0 : 3),
      );
      expect(overlay.hitTestable(), findsOneWidget);
      await tester.tapAt(tester.getCenter(overlay));
      await tester.pump(const Duration(milliseconds: 250));
      final turn = state.playerReportedTurn as int;
      probe.reportedTurn(turn + 1);
      probe.reportedTurn(turn + 2);
      expect(probe.defense(), defenseBeforeScroll);
      expect(probe.coreStats(), coreBeforeScroll);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    });
  }
}
