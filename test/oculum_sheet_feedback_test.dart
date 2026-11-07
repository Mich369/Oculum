import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/widgets/oculum_goth_ornaments.dart';
import 'package:oculum/widgets/oculum_sheet_feedback.dart';
import 'package:oculum/widgets/oculum_theme_presentation.dart';

import 'oculum_october27_resources_test.dart' show closeFixture;
import 'oculum_theme_effects_portrait_test.dart' show mountSheet;

void main() {
  testWidgets('applied damage separates shield impacts, breaks and Life', (
    tester,
  ) async {
    final previous = oculumGraphicsEnabled.value;
    final previousPresentation = oculumThemePresentation.value;
    addTearDown(() {
      oculumGraphicsEnabled.value = previous;
      oculumThemePresentation.value = previousPresentation;
    });
    oculumGraphicsEnabled.value = true;
    oculumThemePresentation.value = const OculumThemePresentation();
    final state = await mountSheet(tester, const Size(1440, 1000));
    final probe = OculumPerformanceProbe(state);
    final sheet = probe.snapshot()
      ..['id'] = 'FEEDBACK'
      ..['sheetTag'] = 'FEEDBACK'
      ..['partialAwakeningHalfHpTriggered'] = true;
    state.updateOculumHomeUi(() {
      state.schedePersonaggio
        ..clear()
        ..add(sheet);
      state.schedaCorrente = 0;
      probe.ensureSheetTags();
      state.paginaCorrente = 0;
      state.modalitaLeggera = false;
      state.modalitaVeloce = false;
      state.campaignDifficulty = 'normale';
      // Fortuna is derived from karma, Magical Luck and level.
      state.karmaController.text = '0';
      state.fortuna = 0;
      state.livelloController.text = '0';
      state.gradoController.text = '0';
      for (final HiddenEyeStat stat in state.hiddenEyeStats) {
        if (stat.id == 'resistenza') {
          // Offset derived Resilience instead of locking a required subtrait.
          stat.valore = -100;
        }
      }
      state.resilienzaController.text = '10';
      state.currentResilienzaController.text = '10';
      state.currentHpController.text = '40';
      state.currentOculumController.text = '0';
      state.scudoCriticoController.text = '0';
      state.scudoController.text = '9';
      state.scudoOculumMaxController.text = '30';
      state.scudoOculumController.text = '6';
      state.hpTempController.text = '0';
    });
    probe.invalidateDerivedCaches();
    await tester.pump();
    final events = state.sheetFeedback as ValueNotifier<OculumSheetFeedback?>;
    final kinds = <OculumFeedbackKind>[];
    events.addListener(() {
      final event = events.value;
      if (event != null) kinds.add(event.kind);
    });
    final layer = find.byType(OculumSheetFeedbackLayer);
    expect(layer, findsOneWidget);
    expect(tester.getSize(layer), const Size(1440, 1000));
    final lifeBefore = probe.currentHp();
    Future<void> hit(int amount) =>
        probe.damageResolved(amount, bypassDefense: true);
    await hit(3);
    expect(kinds, [OculumFeedbackKind.oculumShield]);
    expect(
      state.scudoOculumController.text,
      '3',
      reason: '${state.risultato} · effetto ${events.value?.amount}',
    );
    expect(probe.currentHp(), lifeBefore);
    await hit(6);
    expect(kinds, [
      OculumFeedbackKind.oculumShield,
      OculumFeedbackKind.oculumShieldBroken,
      OculumFeedbackKind.shield,
    ], reason: '${state.risultato}');
    expect(probe.currentHp(), lifeBefore);
    await hit(8);
    expect(kinds.skip(3), [
      OculumFeedbackKind.shieldBroken,
      OculumFeedbackKind.lifeDamage,
    ]);
    expect(probe.currentHp(), lifeBefore - 2);
    expect(events.value?.showSkulls, isFalse);
    expect(
      events.value?.target,
      tester.widget<OculumSheetFeedbackLayer>(layer).target,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    expect(
      find.descendant(of: layer, matching: find.byType(Image)),
      findsOneWidget,
    );
    probe.applyHealing(2);
    expect(kinds.last, OculumFeedbackKind.heal);

    oculumThemePresentation.value = const OculumThemePresentation(
      motion: OculumThemeMotion.reduced,
    );
    await tester.pump();
    expect(layer, findsNothing);
    final count = kinds.length;
    await hit(1);
    expect(probe.currentHp(), lifeBefore - 1);
    expect(kinds, hasLength(count));
    oculumThemePresentation.value = const OculumThemePresentation();
    await tester.pump();
    expect(layer, findsOneWidget);
    expect(
      find.descendant(of: layer, matching: find.byType(Image)),
      findsNothing,
    );
    probe.load(probe.snapshot());
    await tester.pump();
    expect(kinds, hasLength(count), reason: 'A restore is not a combat event');

    // Exact HP assertions isolate the feedback threshold from unrelated
    // random awakenings and Force States that can immediately restore Life.
    state.schedePersonaggio[state
            .schedaCorrente]['partialAwakeningHalfHpTriggered'] =
        true;
    state.statoForzaPronto = false;
    state.statoForzaAttivo = '';
    state.manualHpMaximumAdjustment += (4 - probe.maximumHp() % 4) % 4;
    probe.invalidateDerivedCaches();
    final quarter = probe.maximumHp() ~/ 4;
    state.currentHpController.text = '${quarter + 2}';
    await hit(2);
    expect(probe.currentHp(), quarter);
    expect(events.value?.kind, OculumFeedbackKind.lifeDamage);
    expect(events.value?.showSkulls, isFalse);
    await hit(1);
    expect(probe.currentHp(), quarter - 1);
    expect(events.value?.showSkulls, isTrue);

    for (final (karma, tint) in const [
      (-1, Color(0xFF430E24)),
      (0, Color(0xFFD04751)),
      (1, Color(0xFF941836)),
    ]) {
      state.karmaController.text = '$karma';
      probe.applyEffects([
        OculumStructuredEffect(
          type: 'modifica_statistica',
          target: 'volonta',
          valueExpression: '2',
          duration: '2',
        ),
      ]);
      expect(events.value?.kind, OculumFeedbackKind.will);
      expect(events.value?.tint, tint);
    }
    final lastGain = events.value;
    probe.applyEffects([
      OculumStructuredEffect(
        type: 'modifica_statistica',
        target: 'volonta',
        valueExpression: '2',
        mode: 'diminuzione',
        duration: '2',
      ),
    ]);
    expect(events.value, same(lastGain));
    await closeFixture(tester, probe);
  });

  testWidgets('feedback fills the viewport without blocking controls', (
    tester,
  ) async {
    const hero = (scope: 'campaign', sheet: 'hero');
    const other = (scope: 'campaign', sheet: 'other');
    final events = ValueNotifier<OculumSheetFeedback?>(null);
    final frameKey = GlobalKey();
    var presses = 0;

    Widget view(OculumFeedbackTarget target, {Color? accent}) => MaterialApp(
      theme: ThemeData(
        extensions: [
          if (accent != null)
            OculumGothOrnaments(
              family: OculumGothFamily.none,
              ink: accent,
              accent: accent,
              opacity: .3,
            ),
        ],
      ),
      home: Scaffold(
        body: Stack(
          children: [
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                onPressed: () => presses++,
                child: const Text('Azioni'),
              ),
            ),
            Positioned.fill(
              child: RepaintBoundary(
                key: frameKey,
                child: OculumSheetFeedbackLayer(events: events, target: target),
              ),
            ),
          ],
        ),
      ),
    );
    Future<List<({int red, int blue, int alpha})>> readFrame(Size size) async {
      final boundary =
          frameKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      expect(boundary.size, size);
      return (await tester.runAsync(() async {
        final image = await boundary.toImage();
        try {
          final pixels = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          final w = image.width;
          final h = image.height;
          ({int red, int blue, int alpha}) sample(int x, int y) {
            final index = (y * w + x) * 4;
            return (
              red: pixels.getUint8(index),
              blue: pixels.getUint8(index + 2),
              alpha: pixels.getUint8(index + 3),
            );
          }

          return [
            sample(w ~/ 2, 2),
            sample(w - 3, h ~/ 2),
            sample(w ~/ 2, h - 3),
            sample(2, h ~/ 2),
            sample(w ~/ 2, h ~/ 2),
          ];
        } finally {
          image.dispose();
        }
      }))!;
    }

    await tester.pumpWidget(view(hero));
    final effects = find.descendant(
      of: find.byType(OculumSheetFeedbackLayer),
      matching: find.byType(TweenAnimationBuilder<double>),
    );
    events.value = const OculumSheetFeedback(OculumFeedbackKind.matter, other);
    await tester.pump();
    expect(effects, findsNothing);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final size in const [
      Size(1440, 900),
      Size(820, 1180),
      Size(360, 800),
    ]) {
      tester.view.physicalSize = size;
      events.value = OculumSheetFeedback(OculumFeedbackKind.matter, hero);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(effects, findsOneWidget);
      final samples = await readFrame(size);
      for (final sample in samples.take(4)) {
        expect(sample.alpha, inInclusiveRange(1, 254), reason: '$size');
        expect(sample.blue, greaterThan(sample.red), reason: '$size');
      }
      expect(samples.last.alpha, 0, reason: '$size');
      await tester.tap(find.text('Azioni'));
    }
    expect(presses, 3);
    await tester.pumpWidget(view(other));
    expect(effects, findsNothing);
    await tester.pumpWidget(view(hero));
    expect(effects, findsNothing);
    events.value = const OculumSheetFeedback(OculumFeedbackKind.heal, hero);
    await tester.pump();
    expect(effects, findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(effects, findsNothing);

    Future<int> damageRed(Color accent) async {
      await tester.pumpWidget(view(hero, accent: accent));
      events.value = OculumSheetFeedback(OculumFeedbackKind.lifeDamage, hero);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      final top = (await readFrame(const Size(360, 800))).first;
      expect(top.red, greaterThan(top.blue));
      return top.red;
    }

    final againstRed = await damageRed(const Color(0xFFDC2842));
    final againstGreen = await damageRed(const Color(0xFF23814B));
    expect(againstGreen, greaterThan(againstRed));
    await tester.pumpWidget(const SizedBox.shrink());
    events.dispose();
  });
}
