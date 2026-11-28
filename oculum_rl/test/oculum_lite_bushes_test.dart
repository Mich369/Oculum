import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';

LiteRun _run(LiteBiome biome, {bool exploration = true}) => LiteRun(
  seed: 251,
  explorationRoutes: exploration,
  biome: biome,
  hero: LiteHero.evasore,
  weapon: LiteWeapon.arco,
);

void main() {
  test(
    'sight from outside stops at the bush even when the target is behind it',
    () {
      final run = _run(LiteBiome.campo);
      final bush = run.concealmentBushes.first;
      final start = bush.center - Point(bush.radiusX + .7, 0);
      final behind = bush.center + Point(bush.radiusX + .8, 0);
      final side = Point<double>(0, bush.radiusY + .5);
      expect(run.bushAt(start), isNull);
      expect(run.bushAt(bush.center), bush.id);
      expect(run.bushAt(behind), isNull);
      expect(run.bushBlocksSight(start, bush.center), isTrue);
      expect(run.bushBlocksSight(start, behind), isTrue);
      expect(run.bushBlocksSight(start + side, behind + side), isFalse);
      expect(
        run.bushBlocksSight(start, bush.center, ignoreBush: bush.id),
        isFalse,
      );
      expect(run.bushBlocksSight(bush.center, behind), isFalse);
      expect(run.bushSightFraction(start, behind), inExclusiveRange(0, .5));
    },
  );

  test('concealment has the same footprint after serialization', () {
    final run = _run(LiteBiome.foresta);
    final before = run.concealmentBushes;
    final after = LiteRun.fromJson(run.toJson()).concealmentBushes;
    expect(
      after.map((bush) => (bush.id, bush.kind, bush.center)),
      before.map((bush) => (bush.id, bush.kind, bush.center)),
    );
    expect(
      _run(LiteBiome.foresta, exploration: false).concealmentBushes,
      isEmpty,
    );
    run.restHub = true;
    expect(run.concealmentBushes, isEmpty);
  });

  test('the realm of sweets uses actual marshmallow bushes', () {
    final run = _run(LiteBiome.orea)..realm = LiteRealm.caramella;
    expect(run.concealmentBushes, hasLength(3));
    expect(run.concealmentBushes.map((bush) => bush.kind).toSet(), {
      LiteBushKind.marshmallow,
    });
    expect(
      _run(LiteBiome.deserto).concealmentBushes.first.kind,
      LiteBushKind.cristalli,
    );
    expect(
      _run(LiteBiome.postea).concealmentBushes.first.kind,
      LiteBushKind.vapori,
    );
  });

  test('concealment neither blocks movement nor stops an arrow', () {
    final run = _run(LiteBiome.orea);
    final bush = run.concealmentBushes.first;
    final start = bush.center - Point(bush.radiusX + .5, 0);
    final target = bush.center + Point(bush.radiusX + 1.2, 0);
    run.obstacles.clear();
    final enemy = run.enemies.first;
    run.enemies
      ..clear()
      ..add(enemy);
    enemy.position = target;
    enemy.cooldown = 5;
    enemy.stunned = .9;
    run.position = start;
    expect(run.attack(target), isTrue);
    for (var i = 0; i < 34; i++) {
      run.step(1 / 60, walk: true);
    }
    expect(enemy.hp, lessThan(enemy.maxHp));
    run.position = start;
    for (var i = 0; i < 24; i++) {
      run.step(1 / 60, move: const Point(1, 0));
    }
    expect(run.position.x, greaterThan(start.x + .5));
  });

  test('some rooms station one patrol inside without adding an encounter', () {
    var roomsWithAmbush = 0;
    for (var seed = 101; seed <= 120; seed++) {
      final run = LiteRun(
        seed: seed,
        explorationRoutes: true,
        biome: LiteBiome.foresta,
        hero: LiteHero.evasore,
        weapon: LiteWeapon.guanti,
      );
      expect(
        run.enemies.where(
          (enemy) => run.concealmentBushes.any(
            (bush) => bush.center == enemy.position,
          ),
        ),
        isEmpty,
        reason: 'first room should be readable',
      );
      run
        ..stageClear = true
        ..position = run.portalPosition;
      expect(run.advance(LiteBiome.foresta), isTrue);
      final hidden = run.enemies
          .where((enemy) => run.bushAt(enemy.position) != null)
          .where(
            (enemy) => run.concealmentBushes.any(
              (bush) => enemy.position == bush.center,
            ),
          )
          .toList();
      expect(hidden.length, lessThanOrEqualTo(1));
      if (hidden.isEmpty) continue;
      roomsWithAmbush++;
      final enemy = hidden.single;
      expect(enemy.guard!.mode, LiteGuardMode.ronda);
      expect(enemy.guard!.post, enemy.position);
      expect(enemy.kind.boss || enemy.kind.elite, isFalse);
      expect(run.bushBlocksSight(run.position, enemy.position), isTrue);
      expect(run.bushBlocksSight(enemy.position, enemy.position), isFalse);
      expect(
        LiteRun.fromJson(run.toJson()).enemies.any(
          (unit) => unit.id == enemy.id && unit.position == enemy.position,
        ),
        isTrue,
      );
    }
    expect(roomsWithAmbush, greaterThan(0));
    expect(roomsWithAmbush, lessThan(20));
  });
}
