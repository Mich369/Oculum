import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  testWidgets('Horror home artwork stays renderable across screen shapes', (
    tester,
  ) async {
    final animation = AnimationController(
      vsync: tester,
      duration: const Duration(seconds: 30),
    )..repeat();
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in const <Size>[
      Size(1920, 1080),
      Size(1080, 1920),
      Size(834, 1194),
      Size(390, 844),
    ]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                OculumHomeHorrorArtwork(animation: animation),
                const Center(child: Text('Player · Master')),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 11));
      expect(find.text('Player · Master'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$size');
    }
    animation.dispose();
  });
}
