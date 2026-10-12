import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final resource in ['oculum', 'nessuna']) {
    testWidgets('Art dice stat effect opens confirmation with $resource cost', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final directory = Directory(
        'build/art-dice-${DateTime.now().microsecondsSinceEpoch}',
      )..createSync(recursive: true);
      for (final channel in [
        'plugins.flutter.io/path_provider',
        'dev.fluttercommunity.plus/connectivity',
        'dev.fluttercommunity.plus/connectivity_status',
      ]) {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          MethodChannel(channel),
          (_) async => channel.contains('path_provider')
              ? directory.absolute.path
              : channel.endsWith('connectivity')
              ? ['none']
              : null,
        );
      }
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
      var skill = ArtSkill(
        nome: 'Vampata di Oculum',
        oculumMinimiPerLivello: [1, 1, 1],
        oculumMassimiPerLivello: [1, 1, 1],
        risorseCostoPerLivello: [resource, resource, resource],
        effettiPerLivello: [
          [
            OculumStructuredEffect(
              type: 'modifica_statistica',
              target: 'Oculum',
              valueExpression: '',
              diceExpression: '1d15',
              includeLevel: true,
              includeGrade: true,
              gradeValue: 1.5,
            ),
          ],
        ],
      );
      final art = CharacterArt(
        nome: 'Art della Vampata',
        tipo: 'Oculum Art',
        descrizione: '',
        skills: [skill],
        integritaCorrente: 30,
      );
      state.updateOculumHomeUi(() {
        state.tutorialCompletato = true;
        state.oculumController.text = '10';
        state.currentOculumController.text = '10';
        state.skills.clear();
        state.arti
          ..clear()
          ..add(art);
        state.activeStructuredEffects.clear();
      });
      final probe = OculumPerformanceProbe(state);
      final activation = probe.useArtSkill(0, 0, 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(
        find.byType(AlertDialog),
        findsOneWidget,
        reason: '${state.risultato}',
      );
      final confirm = find.text(
        resource == 'oculum' ? 'Attiva e spendi' : 'Conferma',
      );
      expect(confirm, findsOneWidget);
      await tester.tap(confirm);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await activation;
      expect(skill.livello, 1);
      expect(state.activeStructuredEffects, hasLength(1));
      final previousValue = state.activeStructuredEffects.single['value'];
      final previousCurrent = state.currentOculumController.text;
      final retry = probe.useArtSkill(0, 0, 1, again: true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Annulla'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await retry;
      expect(state.currentOculumController.text, previousCurrent);
      expect(state.activeStructuredEffects.single['value'], previousValue);
      expect(skill.activeTurnsRemaining, 6);
      final value = state.activeStructuredEffects.single['value'];
      final restored = ArtSkill.fromJson(skill.toJson());
      expect(restored.activeTurnsRemaining, 6);
      for (var turn = 1; turn < 6; turn++) {
        probe.reportedTurn(turn);
        expect(skill.livello, 1);
        expect(skill.activeTurnsRemaining, 6 - turn);
        expect(state.activeStructuredEffects.single['value'], value);
        probe.reportedTurn(turn);
        expect(skill.activeTurnsRemaining, 6 - turn);
        if (turn == 3) {
          expect(ArtSkill.fromJson(skill.toJson()).activeTurnsRemaining, 3);
        }
      }
      probe.reportedTurn(6);
      expect(skill.livello, 0);
      expect(skill.activeTurnsRemaining, 0);
      expect(state.activeStructuredEffects, isEmpty);
      skill.tipiPerLivello[0] = 'Passiva';
      skill.livello = 1;
      skill.activeTurnsRemaining = 6;
      probe.reportedTurn(12);
      expect(skill.livello, 1);
      expect(state.logEventi.join('\n'), contains('1d15'));
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
