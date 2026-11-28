import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_audio.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';

void _step(LiteRun run, double seconds) {
  while (seconds > 1e-8) {
    final frame = min(.20, seconds);
    run.step(frame);
    seconds -= frame;
  }
}

LiteRun _caught(int seed, {LiteHero hero = LiteHero.evasore}) {
  final run =
      LiteRun(
          seed: seed,
          hero: hero,
          weapon: LiteWeapon.arco,
          difficulty: LiteDifficulty.medio,
          explorationRoutes: true,
          biome: LiteBiome.campo,
        )
        ..stage = 2
        ..position = const Point(6, 11)
        ..enemies.clear()
        ..obstacles.clear()
        ..obser = 100
        ..shield = 0
        ..hp = 1;
  run.supply.scrolls[LiteScroll.velo] = 4;
  run.supply.scrolls[LiteScroll.dardo] = 6;
  run.projectiles.add(
    LiteProjectile(
      position: run.position,
      direction: const Point(1, 0),
      speed: 6,
      remaining: 3,
      damage: 20,
      fromEnemy: true,
      banditCapture: true,
    ),
  );
  run.step(.025);
  return run;
}

String? _rescuer(LiteRun run) =>
    (run.toJson()['banditEscape'] as Map)['rescuer'] as String?;

LiteRun _withRescuer(String? kind) => Iterable.generate(
  160,
  (i) => _caught(i + 1),
).firstWhere((run) => _rescuer(run) == kind);

void _reachBoss(LiteRun run) {
  while (run.banditRopes() > 0) {
    expect(run.interact(), isTrue);
  }
  for (var i = 0; i < 2; i++) {
    expect(run.enemies.any((enemy) => enemy.hp > 0), isTrue);
    run.position = run.portalPosition;
    expect(run.advance(), isTrue);
  }
  expect(run.banditEscapeRoom, 3);
}

void _kill(LiteRun run, LiteEnemy enemy) {
  run.projectiles.add(
    LiteProjectile(
      position: enemy.position,
      direction: const Point(1, 0),
      speed: .001,
      remaining: 1,
      damage: 9000,
    ),
  );
  run.step(.02);
  expect(enemy.hp, 0);
  run.projectiles.clear();
}

void main() {
  test('the escape warden owns the dedicated music and one-shot', () {
    final soundtrack = LiteAdaptiveSoundtrack();
    final run = _withRescuer(null);
    _reachBoss(run);
    final warden = run.enemies.singleWhere((enemy) => enemy.banditWarden);
    final guard = run.enemies.firstWhere(
      (enemy) =>
          enemy.kind == LiteEnemyKind.granScostumato && !enemy.banditWarden,
    );
    guard.attackTarget = run.position;
    expect(soundtrack.cue(run).banditIntro, isFalse);
    expect(soundtrack.cue(run).track, isNot('boss-banda'));

    _step(run, 1.5);
    final replica = LiteRun.fromJson(run.toJson(includeEffects: true));
    expect(soundtrack.cue(replica), (track: 'boss-banda', banditIntro: true));
    expect(soundtrack.cue(run), (track: 'boss-banda', banditIntro: false));
    _kill(run, warden);
    expect(soundtrack.cue(run).track, isNot('boss-banda'));
  });

  test('co-op keeps the other player active until a wipe then saves both ropes', () {
    final run =
        LiteRun(
            seed: 19,
            hero: LiteHero.evasore,
            weapon: LiteWeapon.arco,
            difficulty: LiteDifficulty.medio,
            explorationRoutes: true,
            playerCount: 2,
            biome: LiteBiome.campo,
          )
          ..stageClear = true
          ..stage = 2
          ..enemies.clear()
          ..obstacles.clear()
          ..position = const Point(6, 11)
          ..hp = 1
          ..shield = 0;
    expect(
      run.addCoopFighter(
        'guest',
        'Ospite',
        LiteHero.scostubandito,
        LiteWeapon.fucileScostubandito,
      ),
      isTrue,
    );
    run.stageClear = false;
    run.enemies.add(
      LiteEnemy(9101, LiteEnemyKind.scostubandito, const Point(23, 15), 190)
        ..stunned = 8,
    );
    final guest = run.coopFighter('guest')!
      ..position = const Point(9, 10)
      ..hp = 1
      ..shield = 0
      ..obser = 100;
    expect(
      run.setCoopControls(
        'guest',
        const Point(0, 0),
        const Point(9, 11),
        attack: false,
      ),
      isTrue,
    );
    void hit(Point<double> at) {
      run.projectiles.add(
        LiteProjectile(
          position: at,
          direction: const Point(1, 0),
          speed: 6,
          remaining: 3,
          damage: 20,
          fromEnemy: true,
          kind: LiteProjectileKind.cannon,
          banditCapture: true,
        ),
      );
      run.step(.025);
    }

    hit(run.position);
    expect(run.hostDown, isTrue);
    expect(run.inBanditEscape, isFalse);
    hit(guest.position);
    expect(
      run.inBanditEscape,
      isTrue,
      reason:
          'hp:${guest.hp} alive:${guest.connected} host:${run.hp} ${run.message}',
    );
    expect(run.hostDown, isFalse);
    expect(guest.hp, guest.maxHp / 4);
    expect(guest.obser, 100);
    expect(run.banditRopes(guest), 1);
    final loaded = LiteRun.fromJson(run.toJson(includeEffects: true));
    final visitor = loaded.coopFighter('guest')!;
    loaded.setCoopControls(
      'guest',
      const Point(0, 0),
      visitor.position,
      attack: false,
    );
    expect(loaded.fightBanditRopes(visitor), isTrue);
    expect(loaded.banditEscapeRoom, 0);
    while (loaded.banditRopes() > 0) {
      expect(loaded.fightBanditRopes(), isTrue);
    }
    expect(loaded.banditEscapeRoom, 1);
  });

  test(
    'fatal bandit shot takes 60 percent once and restores exactly a fourth',
    () {
      var run = _withRescuer(null);
      expect(run.dead, isFalse);
      expect(run.inBanditEscape, isTrue);
      expect(run.hp, closeTo(run.maxHp / 4, 1e-7));
      expect(run.obser, 40);
      expect(run.supply.scrolls.values.reduce((a, b) => a + b), 4);
      expect(run.banditRopes(), 5);
      final position = run.position;
      run.step(.2, move: const Point(1, 0));
      expect(run.position, position);
      expect(run.attack(position + const Point(1, 0)), isFalse);
      expect(run.interact(), isTrue);
      run = LiteRun.fromJson(run.toJson());
      expect(run.banditRopes(), 4);
      expect(run.obser, 40);
      expect(run.supply.scrolls.values.reduce((a, b) => a + b), 4);
    },
  );

  for (final hero in [LiteHero.scostubandito, LiteHero.granScostumato]) {
    test('$hero opens the ropes with one R and keeps the packs', () {
      final run = _caught(12, hero: hero);
      expect(run.inBanditEscape, isTrue);
      expect(run.obser, 100);
      expect(run.supply.scrolls.values.reduce((a, b) => a + b), 10);
      expect(run.banditRopes(), 1);
      expect(run.interact(), isTrue);
      expect(run.banditEscapeRoom, 1);
    });
  }

  test('rescuer chance is exclusive and encountering the veteran unlocks a single hero', () {
    expect(LiteErrato.rescueRoll(0), LiteErrato.veterano);
    expect(LiteErrato.rescueRoll(4), LiteErrato.veterano);
    expect(LiteErrato.rescueRoll(5), LiteErrato.normale);
    expect(LiteErrato.rescueRoll(29), LiteErrato.normale);
    expect(LiteErrato.rescueRoll(30), isNull);
    final run = _withRescuer('veterano');
    final veteran = LiteRun.heroUnlockKey(LiteHero.scostubanditoVeteranoErrato);
    final ordinary = LiteRun.heroUnlockKey(LiteHero.scostubanditoErrato);
    expect(run.achievements, contains(veteran));
    expect(run.achievements, isNot(contains(ordinary)));
    expect(
      run.clones.any((ally) => ally.companion == LiteCompanion.erratoVeterano),
      isTrue,
    );
    expect(run.interact(), isTrue);
    expect(
      run.enemies.where((enemy) => enemy.errato == LiteErrato.normale),
      hasLength(2),
    );
    run.position = const Point(7, 8.1);
    run.step(.025);
    expect(run.achievements, contains(ordinary));
    final regularRun = _withRescuer('normale');
    expect(regularRun.achievements, contains(ordinary));
    expect(regularRun.achievements, isNot(contains(veteran)));
  });

  test(
    'rooms can be passed, only the Elite opens the way, first Gran stays down',
    () {
      var run = _withRescuer(null);
      _reachBoss(run);
      run.hp = run.maxHp;
      run.shield = 30000;
      final adds = run.enemies.where((enemy) => !enemy.banditWarden).toList();
      expect(
        adds.where((enemy) => enemy.kind == LiteEnemyKind.scostubandito),
        hasLength(6),
      );
      final grandees = adds
          .where((enemy) => enemy.kind == LiteEnemyKind.granScostumato)
          .toList();
      expect(grandees, hasLength(2));
      _kill(run, grandees.last);
      _kill(run, grandees.first);
      _kill(run, adds.first);
      expect(run.banditEscapeExit, isFalse);
      run = LiteRun.fromJson(run.toJson());
      _step(run, 60.1);
      final guards = run.enemies.where(
        (enemy) => !enemy.banditWarden && enemy.hp > 0,
      );
      expect(
        guards.where((enemy) => enemy.kind == LiteEnemyKind.scostubandito),
        hasLength(6),
      );
      expect(
        guards.where((enemy) => enemy.kind == LiteEnemyKind.granScostumato),
        hasLength(1),
      );
      expect(guards.any((enemy) => enemy.id == grandees.first.id), isFalse);
      final boss = run.enemies.singleWhere((enemy) => enemy.banditWarden);
      _kill(run, boss);
      expect(run.banditEscapeExit, isTrue);
      expect(run.enemies.any((enemy) => enemy.hp > 0), isTrue);
      final before = run.stage;
      run.position = run.portalPosition;
      expect(run.advance(), isTrue);
      expect(run.stage, before + 1);
      expect(run.inBanditEscape, isFalse);
    },
  );

  test(
    'the Warden fires three marked blasts, swings, hurls and shatters cover',
    () {
      final run = _withRescuer(null);
      _reachBoss(run);
      run.shield = 9999;
      final warden = run.enemies.singleWhere((enemy) => enemy.banditWarden);
      run.enemies.removeWhere((enemy) => !enemy.banditWarden);
      run.position = warden.position - const Point(3.6, 0);
      expect(
        warden.hitboxContains(warden.position + const Point(2.4, 0)),
        isTrue,
      );
      final strikes = <double>{};
      for (var i = 0; i < 80 && strikes.length < 3; i++) {
        run.step(.08);
        for (final impact in run.combatImpacts) {
          if (impact.target == LiteImpactTarget.wardenCannon)
            strikes.add(impact.time);
        }
      }
      expect(strikes, hasLength(3));
      run.obstacles.clear();
      final barrier = LiteObstacle(
        run.position.x - 2.1,
        9.6,
        .5,
        2.8,
        breakable: true,
      );
      run.obstacles.add(barrier);
      final starting = run.position;
      for (var i = 0; i < 55 && run.obstacles.contains(barrier); i++) {
        run.step(.08);
      }
      expect(run.position.x, lessThan(starting.x));
      expect(run.obstacles, isNot(contains(barrier)));
    },
  );
}
