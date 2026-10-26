import 'package:flutter/material.dart';
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/services/oculum_room_activity.dart';
import 'package:oculum/widgets/oculum_room_activity_surface.dart';

void main() {
  final start = DateTime.utc(2026, 10, 26);
  test(
    'room warning follows human activity and gives a full sixty seconds',
    () {
      final room = OculumRoomActivity(start);
      expect(
        room.shouldWarn(start.add(const Duration(minutes: 29, seconds: 59))),
        false,
      );
      final warning = start.add(const Duration(minutes: 30));
      expect(room.shouldWarn(warning), true);
      room.warn(warning);
      expect(room.shouldClose(warning.add(const Duration(seconds: 59))), false);
      expect(room.shouldClose(warning.add(const Duration(seconds: 60))), true);
    },
  );
  test(
    'any player activity cancels warning but repeated heartbeats do not',
    () {
      final room = OculumRoomActivity(start);
      final user = {
        'sessionId': 'player',
        'userActivityAt': start.toIso8601String(),
      };
      room.observe([user], start);
      final warning = start.add(const Duration(minutes: 30));
      room.warn(warning);
      room.observe([user], warning.add(const Duration(seconds: 30)));
      expect(room.shouldClose(warning.add(const Duration(seconds: 60))), true);
      room.observe([
        {
          'sessionId': 'player',
          'userActivityAt': warning
              .add(const Duration(seconds: 59))
              .toIso8601String(),
        },
      ], warning.add(const Duration(seconds: 59)));
      expect(room.warningAt, isNull);
      expect(room.shouldClose(warning.add(const Duration(seconds: 60))), false);
    },
  );
  test('legacy sessions keep a room alive only when first observed', () {
    final room = OculumRoomActivity(start);
    room.observe([
      {'sessionId': 'old-client'},
    ], start.add(const Duration(minutes: 10)));
    expect(room.latestActivity, start.add(const Duration(minutes: 10)));
    room.observe([
      {'sessionId': 'old-client'},
    ], start.add(const Duration(minutes: 40)));
    expect(room.shouldWarn(start.add(const Duration(minutes: 40))), true);
  });
  testWidgets('pointer activity passes through to real controls', (
    tester,
  ) async {
    var activity = 0, clicked = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: OculumRoomActivitySurface(
          onActivity: () => activity++,
          child: Scaffold(
            body: TextButton(
              onPressed: () => clicked++,
              child: const Text('Azione'),
            ),
          ),
        ),
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(find.text('Azione')));
    await tester.tap(find.text('Azione'));
    expect(activity, greaterThan(0));
    expect(clicked, 1);
    await mouse.removePointer();
  });
}
