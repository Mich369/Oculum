import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';

LiteRun arena(LiteHero hero, {int players = 1}) =>
    LiteRun(
        seed: 49,
        hero: hero,
        weapon: LiteWeapon.guanti,
        biome: LiteBiome.foresta,
        playerCount: players,
      )
      ..position = const Point(12, 11)
      ..obstacles.clear()
      ..enemies.clear();

void main() {
  test('Shift leaves a trace on the travelled side of cover and fades', () {
    final run = arena(LiteHero.evasore);
    run.obstacles.add(LiteObstacle(13.4, 9, 1, 4));
    expect(run.dash(const Point(19, 11)), isTrue);
    expect(run.intangible, isFalse);
    expect(run.dash(const Point(19, 11)), isFalse);
    run.step(.21);
    final trace = run.burstTraces.single;
    expect(trace.kind, LiteBurstKind.dash);
    expect(trace.origin, const Point(12, 11));
    expect(trace.end.distanceTo(run.position), lessThanOrEqualTo(.01));
    expect(trace.end.x, lessThan(13.4));
    expect(trace.finished, isTrue);
    expect(run.toJson().containsKey('burstTraces'), isFalse);
    final frame = LiteRun.fromJson(run.toJson(includeEffects: true));
    expect(frame.burstTraces.single.end, trace.end);
    run.step(.25);
    expect(run.burstTraces, isEmpty);
  });

  test(
    'Open keeps recent samples and never links a distant origin to the trail',
    () {
      final run = arena(LiteHero.evasore);
      run.oculum = 50;
      expect(run.useOpen(const Point(25, 11)), isTrue);
      run.step(.25);
      run.step(.25);
      final trace = run.burstTraces.single;
      expect(trace.kind, LiteBurstKind.open);
      expect(trace.pointCount, lessThanOrEqualTo(14));
      expect(trace.pointAt(0).distanceTo(trace.origin), greaterThan(2));
      for (var i = 1; i < trace.pointCount; i++) {
        expect(trace.pointAt(i).distanceTo(trace.pointAt(i - 1)), lessThan(.4));
      }
      expect(trace.finished, isTrue);
    },
  );

  test('host and guest use different visual profiles in the same frame', () {
    final host = arena(LiteHero.evasore, players: 2);
    expect(
      host.addCoopFighter('qa', 'Prova', LiteHero.slimeBlu, LiteWeapon.guanti),
      isTrue,
    );
    final guest = host.coopFighter('qa')!;
    guest.position = const Point(12, 13);
    expect(host.special(const Point(20, 11)), isTrue);
    expect(host.intangible, isTrue);
    host.setCoopControls(
      'qa',
      const Point(0, 0),
      const Point(20, 13),
      attack: false,
      rifleSkill: true,
    );
    host.step(.16);
    final frame = LiteRun.fromJson(host.toJson(includeEffects: true));
    expect(frame.burstTraceFor(0)?.kind, LiteBurstKind.phase);
    expect(frame.burstTraceFor(guest.id)?.kind, LiteBurstKind.veil);
    expect(frame.burstTraceFor(guest.id)?.origin, const Point(12, 13));
  });
}
