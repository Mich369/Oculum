import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final role in ['player', 'master', 'co-master', 'pawn']) {
    testWidgets('Monster Book Madness permission after 35 sheets: $role', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final directory = Directory(
        'build/dice-effects-${DateTime.now().microsecondsSinceEpoch}',
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
        MaterialApp(
          theme: oculumBaseTheme,
          builder: (_, child) => OculumThemeScope(child: child!),
          home: const OculumHomePage(),
        ),
      );
      final dynamic state = tester.state(find.byType(OculumHomePage));
      state.tutorialDialogPending = true;
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      final probe = OculumPerformanceProbe(state);
      final seed = probe.snapshot();
      state.updateOculumHomeUi(() {
        state.tutorialCompletato = true;
        state.modalitaMaster = role == 'master' || role == 'pawn';
        state.sonoCoMaster = role == 'co-master';
        state.schedePersonaggio
          ..clear()
          ..addAll(
            List<Map<String, dynamic>>.generate(
              35,
              (i) => {
                ...seed,
                'id': 'PG${i.toString().padLeft(5, '0')}',
                'sheetTag': 'PG${i.toString().padLeft(5, '0')}',
                'nome': 'PG $i',
              },
            ),
          );
        state.schedaCorrente = 0;
      });
      final spawning = probe.spawnBookCreature(
        role == 'pawn' ? 'pawn_guardiano' : 'giullare_ossa_filo',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      final generate = find.widgetWithText(
        FilledButton,
        'Genera nella mia scheda',
      );
      if (role == 'player') {
        expect(tester.widget<FilledButton>(generate).onPressed, isNull);
        expect(
          find.textContaining('Master e co-Master possono'),
          findsOneWidget,
        );
        await tester.tap(find.widgetWithText(TextButton, 'Annulla'));
      } else {
        expect(tester.widget<FilledButton>(generate).onPressed, isNotNull);
        await tester.tap(generate);
      }
      for (var i = 0; i < 80; i++) {
        await tester.runAsync(
          () async => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 50));
        if (find.byType(AlertDialog).evaluate().isEmpty) break;
      }
      await spawning;
      expect(state.schedePersonaggio.length, role == 'player' ? 35 : 36);
      if (role == 'pawn') {
        final pawn = probe.pawns.single;
        expect(pawn.stats, {
          'resilienza': 3,
          'volonta': 3,
          'materia': 5,
          'oculum': 0,
        });
        expect(pawn.creatureSheetTag, isNotEmpty);
        expect(pawn.hp, 30);
        expect(pawn.defense, probe.defense());
        final restored = OculumPawnGuardian.fromJson(pawn.toJson());
        expect(restored.creatureSheetTag, pawn.creatureSheetTag);
        expect(restored.maxHp, pawn.maxHp);
        state.scudoController.text = '0';
        pawn.targets = ['PG00000'];
        final hpBefore = int.parse(state.currentHpController.text);
        expect(probe.interceptPawnDamage('PG00000', 7 + pawn.defense), 0);
        expect(pawn.hp, hpBefore - 7);
        expect(int.parse(state.currentHpController.text), pawn.hp);
        await probe.advancePawn(pawn.id, 1);
        expect(pawn.hp, hpBefore);
        expect(int.parse(state.currentHpController.text), hpBefore);
        expect(pawn.experience, 25);
        expect(
          probe.interceptPawnDamage('PG00000', pawn.hp + pawn.defense + 1),
          1,
        );
        expect(int.parse(state.currentHpController.text), 0);
        expect(state.schedePersonaggio[0]['pawnCoreClaims'], hasLength(1));
        expect(probe.interceptPawnDamage('PG00000', 1), 1);
        expect(state.schedePersonaggio[0]['pawnCoreClaims'], hasLength(1));
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 400));
      oculumActiveTheme.value = null;
      for (final channel in [
        'plugins.flutter.io/path_provider',
        'dev.fluttercommunity.plus/connectivity',
        'dev.fluttercommunity.plus/connectivity_status',
      ]) {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          MethodChannel(channel),
          null,
        );
      }
    });
  }
}
