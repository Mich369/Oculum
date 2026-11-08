import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/widgets/oculum_encounter_stage.dart';

void main() {
  testWidgets('the encounter stage shows a companion wound and team tint', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OculumEncounterStage(
            tokens: const [
              {
                'id': 'ally',
                'name': 'Compagno',
                'side': 'ally',
                'status': 'active',
                'healthLabel': 'Gravemente ferito',
              },
              {
                'id': 'other',
                'name': 'Altro',
                'side': 'rivals',
                'status': 'downed',
              },
            ],
            activeIndex: 0,
            accent: Colors.blue,
            portraitBuilder: (_) => const Icon(Icons.visibility),
            participantColor: (token) => token['side'] == 'ally'
                ? Colors.greenAccent
                : Colors.purpleAccent,
            healthLabel: (token) => '${token['healthLabel'] ?? ''}',
          ),
        ),
      ),
    );
    expect(find.textContaining('Gravemente ferito'), findsOneWidget);
    expect(
      find.byTooltip('Compagno · In combattimento · Gravemente ferito'),
      findsOneWidget,
    );
    Color ring(String id) {
      final frame = tester.widget<AnimatedContainer>(
        find
            .descendant(
              of: find.byKey(ValueKey('encounter-avatar-$id')),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      return ((frame.decoration! as BoxDecoration).border! as Border).top.color;
    }

    expect(ring('ally'), Colors.greenAccent.withValues(alpha: .55));
    expect(ring('other'), Colors.purpleAccent.withValues(alpha: .55));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(
      tester.getCenter(find.byKey(const ValueKey('encounter-avatar-ally'))),
    );
    await tester.pump(const Duration(milliseconds: 1299));
    expect(ring('ally'), Colors.greenAccent.withValues(alpha: .55));
    await tester.pump(const Duration(milliseconds: 1));
    expect(ring('ally'), Colors.greenAccent.withValues(alpha: 1));
    await mouse.removePointer();
    await tester.tap(find.byKey(const ValueKey('encounter-avatar-other')));
    await tester.pumpAndSettle();
    expect(find.textContaining('A terra'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Browsing a large encounter on a phone preserves the active turn',
    (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var turns = 0;
      final tokens = List.generate(
        300,
        (i) => <String, dynamic>{
          'id': '$i',
          'name': 'Partecipante $i',
          'level': i,
          'discoveredBlindSpot': 'Una lunga descrizione del punto scoperto',
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OculumEncounterStage(
                tokens: tokens,
                activeIndex: 0,
                accent: Colors.blue,
                portraitBuilder: (_) => const Icon(Icons.visibility),
                onNextTurn: () => turns++,
                onReveal: (_) {},
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Partecipante 299'), findsNothing);
      await tester.drag(find.byType(PageView), const Offset(-280, 0));
      await tester.pumpAndSettle();
      expect(find.text('Partecipante 1'), findsWidgets);
      expect(turns, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
