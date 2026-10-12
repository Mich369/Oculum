import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'A skill with dice effects activates, spends once and keeps its rolls across turns',
    (tester) async {
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
      final form = CharacterSkillForm(
        nome: 'Forma I',
        oculumMinimoUtilizzabile: 1,
        oculumMassimoUtilizzabile: 1,
        aumentoMassimoOculumAttivo: false,
        cooldownStrutturato: OculumAbilityCooldown(amount: 3),
        effettiStrutturati: [
          OculumStructuredEffect(
            type: 'scudo',
            valueExpression: '',
            diceExpression: '1d6',
          ),
          OculumStructuredEffect(
            type: 'modifica_sottotratto',
            target: 'Riflessi',
            valueExpression: '1d6',
            duration: '1d4+2',
          ),
        ],
      );
      final skill = CharacterSkill(
        nome: 'Protezione dei dadi',
        tipo: 'Skill',
        costo: '1 Oculum',
        cooldown: '3 turni',
        descrizione: '',
        forme: [form],
        equipaggiata: true,
      );
      state.updateOculumHomeUi(() {
        state.tutorialCompletato = true;
        state.oculumController.text = '10';
        state.currentOculumController.text = '10';
        state.currentHpController.text = '30';
        state.scudoController.text = '0';
        state.skills
          ..clear()
          ..add(skill);
        state.activeStructuredEffects.clear();
      });
      final probe = OculumPerformanceProbe(state);
      final use = probe.useCharacterSkill(skill);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Conferma'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await use;
      expect(state.currentOculumController.text, '9');
      expect(
        int.parse(state.scudoController.text as String),
        inInclusiveRange(1, 6),
      );
      expect(form.cooldownStrutturato!.remaining, 3);
      final effects = state.activeStructuredEffects as List;
      expect(effects, hasLength(1));
      final value = effects.single['value'];
      final duration = effects.single['remaining'] as int;
      expect(value, inInclusiveRange(1, 6));
      expect(duration, inInclusiveRange(3, 6));
      expect(state.logEventi.join('\n'), contains('1d6'));
      expect(state.logEventi.join('\n'), contains('1d4'));
      expect(
        state.logEventi.join('\n'),
        isNot(contains('Effetto non applicato')),
      );
      probe.tickEffects('turni');
      expect(effects.single['value'], value);
      expect(effects.single['remaining'], duration - 1);

      // The same dice-only effect can also be saved through the player's editor.
      final editing = probe.editEffect(
        OculumStructuredEffect(
          type: 'scudo',
          valueExpression: '',
          diceExpression: '1d6',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Salva effetto'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      final saved = await editing;
      expect(saved, isNotNull);
      expect(saved!.valueExpression, '0');
      expect(saved.diceExpression, '1d6');
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
    },
  );
}
