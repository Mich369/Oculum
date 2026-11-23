import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  testWidgets(
    'right click edits extra dodges without refunding spent charges',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      state.updateOculumHomeUi(() {
        state.schivateOculumBonus = 5;
        state.schivateOculumConsumate = 3;
      });
      probe.openDodgeResources();
      await tester.pumpAndSettle();
      await tester.tap(
        find.byTooltip('Tasto destro per impostare le Schivate extra'),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();
      expect(find.text('Schivate Oculum extra'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Quantità extra'),
        '2',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Salva'));
      await tester.pumpAndSettle();
      expect(state.schivateOculumBonus, 3);
      expect(state.schivateOculumConsumate, 3);
      expect(probe.snapshot()['schivateOculumConsumate'], 3);
      expect(tester.takeException(), isNull);
      await closeFixture(tester, probe);
    },
  );
}
