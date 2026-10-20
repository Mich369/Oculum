import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/widgets/oculum_watching_eyes.dart';

void main() {
  testWidgets('startup eyes keep receiving pointer input over role buttons', (
    tester,
  ) async {
    final gazeEvents = <Offset>[];
    var playerPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OculumWatchingEyes(
            animation: const AlwaysStoppedAnimation(0),
            onGazeChanged: gazeEvents.add,
            child: Center(
              child: ElevatedButton(
                onPressed: () => playerPressed = true,
                child: const Text('Player'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Player'));
    await tester.pump();

    expect(playerPressed, isTrue);
    expect(gazeEvents, isNotEmpty);
    expect(gazeEvents.any((point) => point.dx >= 0 && point.dy >= 0), isTrue);
  });
}
