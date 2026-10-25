import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/widgets/oculum_hex_color_field.dart';

void main() {
  test('HEX tags preserve RGB, alpha, shorthand and case', () {
    for (final value in ['#7B61FF', '7b61ff', '0xFF7B61FF']) {
      expect(oculumColorFromHex(value), const Color(0xff7b61ff));
    }
    expect(oculumColorFromHex(' #A3F '), const Color(0xffaa33ff));
    expect(oculumColorFromHex('0x887B61FF'), const Color(0x887b61ff));
    expect(
      oculumColorFromHex(oculumColorHex(const Color(0x887b61ff))),
      const Color(0x887b61ff),
    );
    for (final value in [
      '',
      '#',
      'not-a-colour',
      '#12',
      '#12345',
      '#ZZZZZZ',
      '0x123456789',
    ]) {
      expect(oculumColorFromHex(value), isNull, reason: value);
    }
  });
  testWidgets(
    'pasting a tag applies once; invalid input leaves the previous colour',
    (tester) async {
      Color color = Colors.blue;
      var changes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OculumHexColorField(
              value: color,
              onChanged: (next) {
                color = next;
                changes++;
              },
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '#7B61FF');
      expect(changes, 0);
      await tester.tap(find.byTooltip('Applica colore HEX'));
      expect(color, const Color(0xff7b61ff));
      expect(changes, 1);
      await tester.enterText(find.byType(TextField), '#QQQQQQ');
      await tester.tap(find.byTooltip('Applica colore HEX'));
      await tester.pump();
      expect(changes, 1);
      expect(find.text('Usa #RRGGBB, #RGB o 0xAARRGGBB'), findsOneWidget);
    },
  );
}
