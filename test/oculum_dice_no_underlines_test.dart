import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final faces in [4, 6, 8, 10, 12, 20, 100]) {
    testWidgets('d$faces result text has no underline and keeps its die', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: D20Widget(
                text: '8+3=11',
                fillColor: const Color(0xFF17141C),
                textColor: const Color(0xFFE6D8BD),
                glow: false,
                tertiaryColor: const Color(0xFF8F1D2C),
                faces: faces,
              ),
            ),
          ),
        ),
      );

      final die = tester.widget<D20Widget>(find.byType(D20Widget));
      final resultText = tester.widget<Text>(find.text('8+3=11'));
      expect(die.faces, faces);
      expect(resultText.style!.decoration, TextDecoration.none);
      expect(tester.takeException(), isNull);
    });
  }
}
