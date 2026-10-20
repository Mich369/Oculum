import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/widgets/oculum_attack_planner.dart';

void main() {
  testWidgets('missing required hits repeat the only selected target', (
    tester,
  ) async {
    OculumAttackPlan? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            child: const Text('Apri'),
            onPressed: () async {
              result = await showDialog<OculumAttackPlan>(
                context: context,
                builder: (_) => OculumAttackPlanner(
                  targets: const {'enemy': 'Slime'},
                  minimumTargets: 3,
                  maximumTargets: 3,
                  choices: const [OculumAttackChoice('vc', 'VC', 3)],
                  chance: (_, _) => null,
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dichiara e tira'));
    await tester.pumpAndSettle();
    expect(result?.targetIds, ['enemy', 'enemy', 'enemy']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('attack element is visible and returned with the plan', (
    tester,
  ) async {
    OculumAttackPlan? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<OculumAttackPlan>(
                context: context,
                builder: (_) => OculumAttackPlanner(
                  targets: const {'enemy': 'Nemico'},
                  choices: const [OculumAttackChoice('vc', 'VC', 2)],
                  chance: (_, _) => null,
                  elements: const [
                    OculumCombatElement('fuoco', 'Fuoco', Colors.red),
                    OculumCombatElement('acqua', 'Acqua', Colors.blue),
                  ],
                  initialElement: 'fuoco',
                ),
              );
            },
            child: const Text('Apri'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();
    expect(find.text('Elemento · Fuoco'), findsOneWidget);
    await tester.tap(find.text('Elemento · Fuoco'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Acqua').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dichiara e tira'));
    await tester.pumpAndSettle();
    expect(result?.element, 'acqua');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'multiple targets enforce minimum and maximum independently of roll choice',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OculumAttackPlanner(
            targets: const {'a': 'Slime A', 'b': 'Slime B', 'c': 'Slime C'},
            minimumTargets: 2,
            maximumTargets: 2,
            choices: const [OculumAttackChoice('vc', 'VC', 3)],
            chance: (_, _) => null,
          ),
        ),
      );
      FilledButton submit() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Dichiara e tira'),
      );
      expect(submit().onPressed, isNotNull);
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Slime B'));
      await tester.pump();
      expect(submit().onPressed, isNotNull);
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'Slime C'),
            )
            .onChanged,
        isNull,
      );
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Slime B'));
      await tester.pump();
      expect(submit().onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('requested alternative is selected and visible on opening', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OculumAttackPlanner(
          targets: const {'enemy': 'Slime'},
          initialChoice: 'velo',
          choices: const [
            OculumAttackChoice('vc', 'VC', 4),
            OculumAttackChoice('velo', 'Velo', 5),
          ],
          chance: (_, _) => null,
        ),
      ),
    );
    expect(find.text('Velo +5'), findsOneWidget);
    expect(find.byKey(const ValueKey('attack-reason')), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Dichiara e tira'),
          )
          .onPressed,
      isNotNull,
    );
  });
  testWidgets('optional rolls can be added and removed without losing VC', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OculumAttackPlanner(
          targets: const {'enemy': 'Slime'},
          choices: const [
            OculumAttackChoice('vc', 'VC', 4, color: Colors.red),
            OculumAttackChoice('medicina', 'Medicina', 3, color: Colors.green),
          ],
          chance: (_, _) => null,
        ),
      ),
    );
    expect(find.text('Medicina +3'), findsNothing);
    await tester.tap(find.text('Aggiungi tiro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Medicina +3'));
    await tester.pumpAndSettle();
    expect(find.text('Medicina +3'), findsOneWidget);
    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Medicina +3'),
    );
    expect(button.style!.foregroundColor!.resolve({}), Colors.green);
    await tester.tap(find.text('Medicina +3'));
    await tester.pump();
    await tester.tap(find.byTooltip('Rimuovi Medicina'));
    await tester.pump();
    expect(find.text('Medicina +3'), findsNothing);
    expect(find.text('VC +4'), findsOneWidget);
    expect(find.byKey(const ValueKey('attack-reason')), findsNothing);
  });
  for (final size in [const Size(1440, 900), const Size(390, 844)]) {
    testWidgets(
      'planner allows verbal explanation for alternative attacks $size',
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
        expect(find.textContaining('difesa non condivisa'), findsNothing);
        await tester.tap(find.text('Forza +7'));
        await tester.pump();
        final submit = find.widgetWithText(FilledButton, 'Dichiara e tira');
        expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
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
