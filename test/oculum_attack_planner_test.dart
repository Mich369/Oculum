import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/widgets/oculum_attack_planner.dart';

void main() {
  for (final size in [const Size(1440, 900), const Size(390, 844)]) {
    testWidgets(
      'planner requires an explanation for alternative attacks $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OculumAttackPlanner(
                targets: const {'enemy': 'Slime Roccioso'},
                choices: const [
                  OculumAttackChoice('vc', 'VC', 4),
                  OculumAttackChoice('forza', 'Forza', 7),
                ],
                chance: (_, _) => null,
              ),
            ),
          ),
        );
        expect(find.textContaining('difesa non condivisa'), findsNWidgets(2));
        await tester.tap(find.text('Forza +7'));
        await tester.pump();
        final submit = find.widgetWithText(FilledButton, 'Dichiara e tira');
        expect(tester.widget<FilledButton>(submit).onPressed, isNull);
        await tester.enterText(
          find.byKey(const ValueKey('attack-reason')),
          'Spingo il masso contro la gamba',
        );
        await tester.pump();
        expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('empty encounters cannot submit an attack', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OculumAttackPlanner(
          targets: const {},
          choices: const [],
          chance: (_, _) => null,
        ),
      ),
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}
