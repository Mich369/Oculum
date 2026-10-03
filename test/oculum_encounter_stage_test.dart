import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/widgets/oculum_encounter_stage.dart';

void main() {
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
