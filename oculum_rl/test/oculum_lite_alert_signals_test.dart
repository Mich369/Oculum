import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';

LiteRun _newRun() {
  final run = LiteRun(
    seed: 251,
    explorationRoutes: true,
    hero: LiteHero.evasore,
    weapon: LiteWeapon.guanti,
  );
  run
    ..position = const Point(6, 2)
    ..hp = 900;
  run.obstacles.clear();
  final first = run.enemies.first;
  final second = run.enemies[1];
  run.enemies
    ..clear()
    ..addAll([first, second]);
  first
    ..position = const Point(4, 2)
    ..cooldown = 20
    ..guard = (LiteGuard(const Point(4, 2))..facing = const Point(1, 0));
  second
    ..position = const Point(30, 20)
    ..cooldown = 20
    ..guard = (LiteGuard(const Point(30, 20))..facing = const Point(1, 0));
  return run;
}

void _tick(LiteRun run, int sixteenths) {
  for (var i = 0; i < sixteenths; i++) {
    run.step(1 / 16);
  }
}

void main() {
  test('each foe waits three seconds, the hero speaks only on group alert', () {
    final run = _newRun();
    _tick(run, 47);
    expect(run.alertCalls, isEmpty);
    _tick(run, 2);
    expect(run.alertCalls, hasLength(1));
    expect(run.alertCalls.single.enemy, run.enemies.first.kind);
    expect(run.alertCalls.single.viewerId, isNull);

    final other = run.enemies.last
      ..position = const Point(6, 4)
      ..guard = (LiteGuard(const Point(6, 4))..facing = const Point(0, -1));
    _tick(run, 47);
    expect(run.alertCalls.where((call) => call.viewerId == 0), isEmpty);
    _tick(run, 3);
    final cues = run.alertCalls.toList();
    expect(cues, hasLength(3));
    expect(cues[1].enemy, other.kind);
    expect(cues.last.hero, LiteHero.evasore);
    expect(cues.last.viewerId, 0);
    _tick(run, 8);
    expect(run.alertCalls.where((call) => call.viewerId == 0), hasLength(1));
  });

  test('a save preserves countdown; visual frame preserves cue identity', () {
    final run = _newRun();
    _tick(run, 30);
    final restored = LiteRun.fromJson(run.toJson());
    _tick(restored, 17);
    expect(restored.alertCalls, isEmpty);
    _tick(restored, 2);
    final cue = restored.alertCalls.single;
    final guestView = LiteRun.fromJson(restored.toJson(includeEffects: true));
    expect(guestView.alertCalls.single.sequence, cue.sequence);
    expect(guestView.alertCalls.single.enemy, cue.enemy);
    _tick(guestView, 5);
    expect(guestView.alertCalls, hasLength(1));
  });
}
