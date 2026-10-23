import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/widgets/oculum_watching_eyes.dart';

void main() {
  testWidgets('Only Master selection reverses gaze in 400ms, reset at 600ms', (
    tester,
  ) async {
    Widget eyes(bool master) => MaterialApp(
      home: Scaffold(
        body: OculumWatchingEyes(
          animation: const AlwaysStoppedAnimation(0),
          reverseGaze: master,
        ),
      ),
    );
    await tester.pumpWidget(eyes(false));
    final dynamic state = tester.state(find.byType(OculumWatchingEyes));
    expect(state.reversal.value, 0);
    await tester.pumpWidget(eyes(true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(state.reversal.value, 1);
    await tester.pump(const Duration(milliseconds: 199));
    expect(state.reversal.value, 1);
    await tester.pump(const Duration(milliseconds: 1));
    expect(state.reversal.value, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

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
