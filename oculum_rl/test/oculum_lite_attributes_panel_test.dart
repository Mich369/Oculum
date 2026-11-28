import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';
import 'package:oculum_rl/widgets/oculum_lite_attributes_panel.dart';

void main() {
  const scores = LiteAttributes(
    resilienza: 10,
    volonta: 10,
    materia: 10,
    oculum: 10,
  );

  testWidgets('the compact panel assigns only one available point', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final points = ValueNotifier(1);
    addTearDown(points.dispose);
    var assigned = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) => OculumLiteAttributesButton(
              freePoints: points.value,
              onPressed: () => showLiteAttributePanel(
                context,
                refresh: points,
                read: () => (
                  scores: LiteAttributes(
                    resilienza: 10,
                    volonta: 10 + assigned,
                    materia: 10,
                    oculum: 10,
                  ),
                  freePoints: points.value,
                  canSpend: true,
                ),
                onSpend: (attribute) {
                  expect(attribute, LiteAttribute.volonta);
                  assigned++;
                  points.value--;
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Caratteristiche · 1 punto libero'));
    await tester.pumpAndSettle();
    expect(find.text('1 punto libero'), findsOneWidget);
    for (final attribute in LiteAttribute.values) {
      expect(find.text(attribute.label), findsOneWidget);
    }
    final add = find.byTooltip('Aumenta Volontà');
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(assigned, 1);
    expect(find.text('11'), findsOneWidget);
    expect(find.text('0 punti liberi'), findsOneWidget);
    final addButton = find
        .widgetWithIcon(IconButton, Icons.add)
        .at(LiteAttribute.volonta.index);
    expect(tester.widget<IconButton>(addButton).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('preset shows the four effective characteristics read-only', (
    tester,
  ) async {
    final changes = ValueNotifier(0);
    addTearDown(changes.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) => OculumLiteAttributesButton(
              onPressed: () => showLiteAttributePanel(
                context,
                refresh: changes,
                read: () => (scores: scores, freePoints: null, canSpend: false),
                onSpend: (_) => fail('A preset has no allocation buttons'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Caratteristiche'));
    await tester.pumpAndSettle();
    for (final attribute in LiteAttribute.values) {
      expect(find.text(attribute.label), findsOneWidget);
      expect(find.byTooltip('Aumenta ${attribute.label}'), findsNothing);
    }
    expect(find.textContaining('punti liberi'), findsNothing);
  });
}
