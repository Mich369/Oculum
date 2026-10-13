import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<dynamic> mountSheet(WidgetTester tester, Size size) async {
  SharedPreferences.setMockInitialValues({});
  final directory = Directory(
    'build/theme-effect-test-${DateTime.now().microsecondsSinceEpoch}',
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
  tester.view.physicalSize = size;
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
  state.updateOculumHomeUi(() {
    state.tutorialCompletato = true;
    state.datiCaricati = true;
    state.volontaController.text = '12';
    state.currentVolontaController.text = '12';
    state.activeConditions.clear();
    state.activeStructuredEffects.clear();
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return state;
}

void main() {
  testWidgets(
    'monster techniques add only their bonus and expire after the attack',
    (tester) async {
      final state = await mountSheet(tester, const Size(1440, 900));
      final probe = OculumPerformanceProbe(state);
      final before = probe.damageTotal();
      final horror = oculumMonsterBookArt(
        monsterById('weak_horror_lacrimante')!,
      );
      probe.applyEffects(horror.skills.first.effettiEvoluzione(1));
      expect(probe.damageTotal(), before + 1);
      expect(probe.consumeNextAttackEffects(), isTrue);
      expect(probe.damageTotal(), before);
      expect(probe.consumeNextAttackEffects(), isFalse);
      final generated = defaultMonsterBookEntries.firstWhere(
        (entry) =>
            entry.id.startsWith('inspired_') &&
            oculumMonsterBookArt(entry).skills.any(
              (skill) => skill
                  .effettiEvoluzione(1)
                  .any((effect) => effect.type == 'danno'),
            ),
      );
      final attack = oculumMonsterBookArt(generated).skills.firstWhere(
        (skill) =>
            skill.effettiEvoluzione(1).any((effect) => effect.type == 'danno'),
      );
      probe.applyEffects(
        attack.effettiEvoluzione(1),
        spentResources: {'oculum': 4},
      );
      expect(probe.damageTotal(), before + 4);
      probe.consumeNextAttackEffects();
      expect(probe.damageTotal(), before);
    },
  );
  test(
    'damage percentage has defined rounding and cannot produce negative damage',
    () {
      expect(oculumDamageWithPercentage(27, 25), 34);
      expect(oculumDamageWithPercentage(27, 50), 41);
      expect(oculumDamageWithPercentage(27, -100), 0);
      expect(oculumDamageWithPercentage(27, -150), 0);
    },
  );
  testWidgets(
    'structured conditions use the condition engine and next-attack bonuses are consumed once',
    (tester) async {
      final state = await mountSheet(tester, const Size(1440, 900));
      final probe = OculumPerformanceProbe(state);
      probe.applyEffects([
        OculumStructuredEffect(
          type: 'stato',
          appliedState: 'immobilizzato',
          valueExpression: '1',
          duration: '2',
        ),
      ]);
      expect(
        probe.conditions.map((condition) => condition.conditionType),
        contains('immobilizzato'),
      );
      expect(probe.movement(), 0);
      state.conditionImmunities.add('gelo');
      final messages = probe.applyEffects([
        OculumStructuredEffect(
          type: 'stato',
          appliedState: 'gelo',
          valueExpression: '1',
          duration: '2',
        ),
      ]);
      expect(
        probe.conditions.map((condition) => condition.conditionType),
        isNot(contains('gelo')),
      );
      expect(messages.join(' '), contains('non applicato'));
      final before = probe.damageTotal();
      probe.applyEffects([
        OculumStructuredEffect(
          type: 'danno_percentuale',
          valueExpression: '100',
          mode: 'prossima_azione',
        ),
      ]);
      expect(probe.damageTotal(), before * 2);
      probe.tickEffects('turni');
      expect(probe.damageTotal(), before * 2);
      await probe.rollSpecial('CM', 0);
      expect(probe.damageTotal(), before * 2);
      await probe.rollSpecial('VC', 0);
      expect(probe.damageTotal(), before);
      expect(
        state.risultato,
        contains('Danno inflitto nell’azione precedente'),
      );
      expect(state.activeStructuredEffects, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final size in [const Size(1440, 900), const Size(390, 844)]) {
    testWidgets('square portrait has clickable full-size viewer at $size', (
      tester,
    ) async {
      final state = await mountSheet(tester, size);
      final frame = tester.widget<SizedBox>(
        find.byKey(const ValueKey('reference_portrait_frame')),
      );
      expect(frame.width, frame.height);
      expect(frame.width, lessThanOrEqualTo(104));
      await tester.tap(find.byKey(const ValueKey('portrait-enlarge')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(
        find.byKey(const ValueKey('portrait-enlarged-dialog')),
        findsOneWidget,
      );
      expect(find.byType(InteractiveViewer), findsOneWidget);
      await tester.tap(find.text('Chiudi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      final bytes = await tester.runAsync(
        () => File(
          'assets/themes/vervain_gothic/overlays/relic.png',
        ).readAsBytes(),
      );
      state.updateOculumHomeUi(() => state.immaginePersonaggio = bytes);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('portrait-enlarge')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      final image = tester.widget<Image>(
        find
            .descendant(
              of: find.byKey(const ValueKey('portrait-enlarged-dialog')),
              matching: find.byType(Image),
            )
            .first,
      );
      expect((image.image as MemoryImage).bytes, same(bytes));
      expect(state.immaginePersonaggio, same(bytes));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
