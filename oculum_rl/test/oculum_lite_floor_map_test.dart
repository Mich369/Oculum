import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';

LiteRun camp({LiteWeapon weapon = LiteWeapon.guanti}) => LiteRun(
  seed: 251,
  hero: LiteHero.duplicatore,
  weapon: weapon,
  biome: LiteBiome.campo,
  difficulty: LiteDifficulty.moltoFacile,
);

void go(LiteRun run, Point<double> point, {bool walk = false}) {
  for (var i = 0; i < 720; i++) {
    final delta = point - run.position;
    if (delta.magnitude < .08) return;
    run.step(1 / 120, move: delta, walk: walk);
  }
  fail('Cannot reach $point from ${run.position}.');
}

LiteRun restore(LiteRun run, {bool coop = false}) => LiteRun.fromJson(
  jsonDecode(jsonEncode(run.toJson(includeEffects: coop)))
      as Map<String, dynamic>,
);

void main() {
  test(
    'the first campaign has a different chamber defender on every floor',
    () {
      for (final hero in [LiteHero.duplicatore, LiteHero.eliteSolare]) {
        final run = LiteRun(
          seed: 251,
          hero: hero,
          weapon: LiteWeapon.spadaScudo,
          biome: LiteBiome.campo,
        );
        final names = <String>{};
        final defenders = <LiteEnemyKind>{};
        for (var plane = 0; plane <= LiteRun.finalStage; plane++) {
          expect(run.hasChamber, isTrue);
          expect(names.add(run.chamberTitle), isTrue, reason: 'piano $plane');
          if (!run.enemies.any((enemy) => enemy.chamberSeat != null)) {
            run.enemies.clear();
            run.step(.02);
          }
          final main = run.enemies.singleWhere(
            (enemy) => enemy.chamberSeat != null,
          );
          expect(
            defenders.add(main.kind),
            isTrue,
            reason: '$hero / $plane / ${main.kind}',
          );
          if (plane < LiteRun.finalStage) {
            run
              ..enemies.clear()
              ..stageClear = true
              ..position = run.portalPosition;
            expect(run.advance(LiteBiome.campo), isTrue);
          }
        }
        expect(defenders, hasLength(25));
      }
    },
  );

  test('champion warning keeps the exact shape and resolves after a save', () {
    final run = camp()
      ..enemies.clear()
      ..obstacles.clear();
    final champion = LiteEnemy(
      410,
      LiteEnemyKind.luce,
      const Point(27, 11),
      300,
    )..chamberSeat = 3;
    run
      ..position = const Point(23, 11)
      ..enemies.add(champion);
    run.step(.02);
    final cue = champion.chamberWarning!;
    expect(cue.pattern, LiteChamberPattern.croce);
    expect(cue.marks, contains(run.position));
    final loaded = restore(run, coop: true);
    expect(loaded.enemies.single.chamberWarning!.frame, cue.frame);
    for (var i = 0; i < 130; i++) {
      loaded.step(1 / 120);
    }
    expect(loaded.enemies.single.chamberWarning, isNull);
    expect(loaded.enemies.single.chamberCycle, 1);
    expect(
      loaded.combatImpacts.any(
        (hit) => hit.target == LiteImpactTarget.explosion,
      ),
      isTrue,
    );
  });

  test('the Campo pads catch a dash both ways and save the landing', () {
    final run = camp();
    final [near, far] = run.dashPads;
    for (var seed = 248; seed <= 255; seed++) {
      final room = LiteRun(
        seed: seed,
        hero: LiteHero.duplicatore,
        weapon: LiteWeapon.guanti,
        biome: LiteBiome.campo,
      );
      expect(room.dashPads, [near, far], reason: 'seed $seed');
      room.position = near;
      expect(room.dash(far), isTrue, reason: 'seed $seed');
    }
    run.position = near;
    for (var frame = 0; frame < 100; frame++) {
      run.step(1 / 120, move: const Point(1, 0));
    }
    expect(run.position.x, lessThan(25.75));
    run.position = near;
    final balance = run.obser;
    expect(run.dash(far), isTrue);
    for (var frame = 0; frame < 14; frame++) {
      run.step(1 / 120);
    }
    final resumed = restore(run);
    for (var frame = 0; frame < 145; frame++) {
      resumed.step(1 / 120);
    }
    expect(resumed.position, far);
    expect(resumed.obser, balance + 9);
    expect(resumed.dash(near), isTrue);
    for (var frame = 0; frame < 146; frame++) {
      resumed.step(1 / 120);
    }
    expect(resumed.position, near);
    expect(resumed.dash(far), isTrue);
    for (var frame = 0; frame < 50; frame++) {
      resumed.step(1 / 120);
    }
    expect(resumed.position, far);
    expect(resumed.obser, balance + 9);
  });

  test('the host restores the guest dash across the same chasm', () {
    final run = LiteRun(
      seed: 251,
      hero: LiteHero.duplicatore,
      weapon: LiteWeapon.guanti,
      biome: LiteBiome.campo,
      playerCount: 2,
    );
    final [near, far] = run.dashPads;
    expect(
      run.addCoopFighter('guest', 'Guest', LiteHero.ashley, LiteWeapon.guanti),
      isTrue,
    );
    final guest = run.coopFighter('guest')!..position = near;
    expect(
      run.setCoopControls(
        'guest',
        const Point(0, 0),
        far,
        attack: false,
        dash: true,
      ),
      isTrue,
    );
    for (var frame = 0; frame < 16; frame++) {
      run.step(1 / 120);
    }
    expect(guest.position.x, greaterThan(near.x));
    final resumed = restore(run, coop: true);
    for (var frame = 0; frame < 50; frame++) {
      resumed.step(1 / 120);
    }
    expect(resumed.coopFighter('guest')!.position, far);
  });

  test('Campo seed 251 has a real flank, an early shop and persistent map', () {
    expect(LiteBiome.offers(251), contains(LiteBiome.campo));
    final run = camp();
    expect(run.hasMapped(LiteMapSector.fianco), isFalse);
    expect(run.hasMapped(LiteMapSector.uscita), isFalse);
    go(run, const Point(5, 5), walk: true);
    expect(run.stageClear, isFalse);
    expect(run.canOpenShop, isTrue);
    expect(run.interact(), isTrue);
    expect(run.obser, 12);
    run.closeShop();
    expect(run.interact(), isTrue);
    expect(run.obser, 12);
    run.closeShop();
    go(run, const Point(7.5, 16.55), walk: true);
    go(run, const Point(10.55, 16.55), walk: true);
    expect(run.hasMapped(LiteMapSector.retro), isTrue);
    run.markMapPoint(const Point(10.55, 16.55));
    final saved = restore(run);
    expect(saved.mappedSectors, run.mappedSectors);
    expect(saved.mapWaypoint, run.mapWaypoint);
    expect(saved.hasMapped(LiteMapSector.uscita), isFalse);
  });

  test(
    'same Campo flank: walking reaches the sentry and force can kill quietly',
    () {
      for (final walk in [true, false]) {
        final run = camp();
        final sentry = run.enemies.first;
        expect(sentry.guard, isNotNull);
        go(run, const Point(7.5, 16.55), walk: walk);
        go(run, const Point(10.55, 16.55), walk: walk);
        if (!walk) {
          expect(sentry.guard!.mode, isNot(LiteGuardMode.ronda));
          continue;
        }
        go(run, const Point(10.85, 14.45), walk: true);
        expect(sentry.guard!.mode, LiteGuardMode.ronda);
        expect(run.attack(sentry.position), isTrue);
        for (var i = 0; i < 54; i++) {
          run.step(1 / 120, walk: true);
        }
        expect(sentry.hp, 0);
        expect(
          run.combatImpacts
              .singleWhere((it) => it.subjectId == sentry.id)
              .silent,
          isTrue,
        );
        final previousExp = run.exp;
        final previousLoot = run.loot.length;
        final resumed = restore(run, coop: true);
        expect(resumed.exp, previousExp);
        expect(resumed.loot.length, previousLoot);
        expect(
          resumed.enemies.where(
            (enemy) => enemy.id == sentry.id && enemy.hp > 0,
          ),
          isEmpty,
        );
        for (var i = 0; i < 50; i++) {
          resumed.step(1 / 120, walk: true);
        }
        expect(resumed.exp, previousExp);
      }
    },
  );

  test('a clone draws a sentry to the flank while its owner can leave', () {
    final run = camp();
    go(run, const Point(7.5, 16.55), walk: true);
    go(run, const Point(10.55, 16.55), walk: true);
    final sentry = run.enemies.first;
    expect(sentry.guard!.mode, LiteGuardMode.ronda);
    expect(run.special(const Point(10.55, 12)), isTrue);
    for (var i = 0; i < 40; i++) {
      run.step(1 / 120, walk: true);
    }
    expect(sentry.guard!.mode, isNot(LiteGuardMode.ronda));
    expect(sentry.guard!.target, isNot(run.position));
    go(run, const Point(7.5, 16.55), walk: true);
    go(run, const Point(5, 5), walk: true);
    expect(run.canOpenShop, isTrue);
  });

  test(
    'the underground shortcut only opens from inside and survives reload',
    () {
      final run = LiteRun(
        seed: 251,
        hero: LiteHero.duplicatore,
        weapon: LiteWeapon.guanti,
        biome: LiteBiome.dungeon,
      );
      final gate = run.obstacles.singleWhere((wall) => wall.mapShortcut);
      run.position = gate.center - const Point<double>(1.4, 0);
      expect(run.attack(gate.center), isTrue);
      for (var i = 0; i < 126; i++) {
        run.step(1 / 120);
      }
      expect(gate.hp, 17);
      run.position = gate.center + const Point<double>(1.4, 0);
      for (var hit = 0; hit < 3 && !run.mapShortcutOpen; hit++) {
        expect(run.attack(gate.center), isTrue);
        for (var i = 0; i < 126; i++) {
          run.step(1 / 120);
        }
      }
      expect(run.mapShortcutOpen, isTrue);
      expect(restore(run).mapShortcutOpen, isTrue);
    },
  );
}
