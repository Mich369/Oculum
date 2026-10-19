import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oculum/widgets/oculum_custom_theme.dart';

void main() {
  tearDown(() => oculumCustomArtwork.value = {});
  test('portable theme preserves layers and all four stat colors', () async {
    final value = <String, dynamic>{
      'version': 1,
      'enabled': true,
      'layers': [
        {
          'image': base64Encode([1, 2, 3]),
          'x': .3,
          'y': .8,
          'size': .2,
          'opacity': .3,
          'rotation': .5,
        },
      ],
      'colors': {
        'resilienza': 0xff112233,
        'volonta': 0xff223344,
        'materia': 0xff334455,
        'oculum': 0xff445566,
      },
    };
    final code = encodeOculumArtwork(value);
    expect(decodeOculumArtwork(code), value);
    SharedPreferences.setMockInitialValues({'oculum.customArtwork.v1': code});
    await loadOculumCustomArtwork();
    expect(oculumCustomStatColor('volonta'), const Color(0xff223344));
    expect(oculumCustomStatColor('resilienza'), const Color(0xff112233));
  });
  test('invalid theme is rejected without replacing active artwork', () {
    expect(() => decodeOculumArtwork('invalid'), throwsFormatException);
    expect(
      () => decodeOculumArtwork(
        encodeOculumArtwork({'version': 2, 'layers': []}),
      ),
      throwsFormatException,
    );
  });
  testWidgets('decoration layer does not intercept controls', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: FilledButton(
                  onPressed: () => pressed = true,
                  child: const Text('Usa'),
                ),
              ),
              const Positioned.fill(child: OculumCustomArtworkLayer()),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Usa'));
    expect(pressed, isTrue);
  });
  testWidgets('RGB slider and HEX stay synchronized', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OculumStatColorPicker(
            initial: Color(0xff112233),
            label: 'Volontà',
          ),
        ),
      ),
    );
    final red = tester.widget<Slider>(find.byType(Slider).at(3));
    red.onChanged!(200);
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'C82233');
    await tester.enterText(find.byType(TextField), '00FF00');
    await tester.pump();
    final green = tester.widget<Slider>(find.byType(Slider).at(4));
    expect(green.value.round(), 255);
  });
}
