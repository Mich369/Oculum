import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  testWidgets(
    'detail refreshes one second after the last edit and keeps focus',
    (tester) async {
      final changes = ValueNotifier<int>(0);
      final controller = TextEditingController();
      final focus = FocusNode();
      addTearDown(changes.dispose);
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      var value = 'prima';
      var builds = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OculumSettledDetail(
              changes: changes,
              builder: (_) {
                builds++;
                return Column(
                  children: [
                    Text(value),
                    TextField(controller: controller, focusNode: focus),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'testo conservato');
      final before = builds;
      value = 'seconda';
      changes.value++;
      await tester.pump(const Duration(milliseconds: 700));
      value = 'ultima';
      changes.value++;
      await tester.pump(const Duration(milliseconds: 999));
      expect(builds, before);
      expect(find.text('prima'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1));
      expect(builds, before + 1);
      expect(find.text('ultima'), findsOneWidget);
      expect(controller.text, 'testo conservato');
      expect(focus.hasFocus, isTrue);
      changes.value++;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    },
  );
}
