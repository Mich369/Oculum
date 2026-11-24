import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';

const _right = Point<double>(12, 11);

void _tick(LiteRun run, double seconds) {
  for (var i = 0; i < (seconds * 120).round(); i++) {
    run.step(1 / 120);
  }
}

LiteRun _run({
  int seed = 242,
  LiteHero hero = LiteHero.evasore,
  LiteDifficulty difficulty = LiteDifficulty.medio,
}) => LiteRun(
  seed: seed,
  hero: hero,
  weapon: LiteWeapon.guanti,
  difficulty: difficulty,
);

void _clear(LiteRun run) {
  run.enemies.clear();
  _tick(run, .02);
  if (!run.stageClear) {
    run.enemies.clear();
    _tick(run, .02);
  }
  expect(run.stageClear, isTrue);
}

void main() {
  test(
    'a quiet sixth room enters the hub and keeps unique purchases in a save',
    () {
      final run = _run()..stage = 5;
      _clear(run);
      run.position = run.portalPosition;
      expect(run.enterRestHub(), isTrue);
      expect(run.enterRestHub(), isFalse);
      expect(run.fauna, isEmpty);
      run.obser = 600;
      expect(run.rememberRestItem(LiteRestItem.chakram), isFalse);
      expect(run.buyRestItem(LiteRestItem.chakram), isTrue);
      expect(run.weapon, LiteWeapon.chakram);
      expect(run.buyRestItem(LiteRestItem.chakram), isFalse);
      expect(run.buyRestItem(LiteRestItem.spirale), isTrue);
      expect(run.buyRestItem(LiteRestItem.spirale), isTrue);
      expect(run.rememberRestItem(LiteRestItem.spirale), isTrue);
      final reloaded = LiteRun.fromJson(run.toJson());
      expect(reloaded.restHub, isTrue);
      expect(reloaded.supply.promised!.rank, 2);
      final next = _run();
      expect(next.carryRestMemory(reloaded.supply.promised!), isTrue);
      expect(next.carryRestMemory(reloaded.supply.promised!), isFalse);
      expect(next.supply.rank(LiteRestItem.spirale), 2);
    },
  );

  test('the Vaitern symbol pays exactly three pieces of sixty Obser', () {
    final run = _run()..shopOpen = true;
    run.supply.lunarPieces = 3;
    final starting = run.obser;
    for (var i = 0; i < 3; i++) {
      expect(run.exchangeLunarPiece(), isTrue);
    }
    expect(run.exchangeLunarPiece(), isFalse);
    expect(run.obser - starting, 180);
    expect(LiteRun.lunarDropChance(LiteEnemyKind.guardiaSolare), 1);
    expect(LiteRun.lunarDropChance(LiteEnemyKind.eliteSolare), 6);
    expect(LiteRun.lunarDropChance(LiteEnemyKind.guardianoSolare), 12);
  });

  test('evading animals become hostile on the room after the sixth attack', () {
    var run = _run();
    for (var i = 0; i < 6; i++) {
      _clear(run);
      final animal = run.fauna.first;
      final at = animal.position;
      run.position = at - const Point<double>(.6, 0);
      run.obstacles.clear();
      expect(run.attack(at), isTrue);
      _tick(run, .4);
      expect(run.provokedFaunaRooms, i + 1);
      expect(run.faunaAggressive, isFalse);
      run = LiteRun.fromJson(run.toJson());
      run.position = run.portalPosition;
      expect(run.advance(LiteBiome.campo), isTrue);
    }
    expect(run.stage, 6);
    expect(run.faunaAggressive, isTrue);
    expect(run.achievements, contains('fauna-in-allarme'));
    expect(LiteRun.fromJson(run.toJson()).faunaAggressive, isTrue);
  });

  test(
    'sparing wildlife unlocks playable animals through ordinary portals',
    () {
      final run = _run();
      for (final destination in [
        LiteBiome.orea,
        LiteBiome.dungeon,
        LiteBiome.foresta,
        LiteBiome.postea,
        LiteBiome.campo,
      ]) {
        _clear(run);
        run.position = run.portalPosition;
        expect(run.advance(destination), isTrue);
      }
      expect(run.sparedFaunaRooms, 5);
      expect(
        run.unlockedHeroesFor(run.hero),
        containsAll([LiteHero.pollo, LiteHero.raganella, LiteHero.pipistrello]),
      );
    },
  );

  test('three eggs travel backwards and their ground fuses survive a save', () {
    final run = _run(hero: LiteHero.pollo)
      ..position = const Point<double>(10, 11)
      ..oculum = 20;
    run.enemies.clear();
    run.fauna.clear();
    run.obstacles.clear();
    expect(run.useOpen(_right), isTrue);
    expect(run.projectiles.length, 3);
    expect(run.projectiles.every((shot) => shot.direction.x < 0), isTrue);
    _tick(run, .40);
    expect(run.projectiles.every((shot) => shot.eggFuse != null), isTrue);
    final snapshot = LiteRun.fromJson(run.toJson());
    _tick(snapshot, .75);
    expect(snapshot.projectiles.length, 3);
    _tick(snapshot, .18);
    expect(
      snapshot.projectiles.where((shot) => shot.kind == LiteProjectileKind.egg),
      isEmpty,
    );
  });

  test(
    'animal loss can unlock Doppelganger and rescales life by difficulty',
    () {
      for (final (difficulty, ratio) in [
        (LiteDifficulty.medio, .65),
        (LiteDifficulty.difficile, .30),
      ]) {
        var changed = 0;
        for (var seed = 200; seed < 290; seed++) {
          final run = _run(
            seed: seed,
            hero: LiteHero.pollo,
            difficulty: difficulty,
          );
          run.enemies.clear();
          run.obstacles.clear();
          run.shield = 0;
          run.projectiles.add(
            LiteProjectile(
              position: run.position,
              direction: const Point<double>(0, 0),
              speed: 1,
              remaining: 1,
              damage: 10000,
              fromEnemy: true,
            ),
          );
          _tick(run, .02);
          if (run.hero != LiteHero.doppelganger) continue;
          changed++;
          expect(run.hp, closeTo(run.maxHp * ratio, .00001));
          expect(
            run.unlockedHeroesFor(run.hero),
            contains(LiteHero.doppelganger),
          );
        }
        expect(changed, inInclusiveRange(3, 22));
      }
    },
  );

  test('solar stairs, four companions, rest and boss keep their state', () {
    var run = _run(seed: 240);
    for (var i = 0; i < 2; i++) {
      _clear(run);
      run.position = run.portalPosition;
      expect(run.advance(LiteBiome.dungeon), isTrue);
    }
    _clear(run);
    final gate = run.obstacles.singleWhere((wall) => wall.solarGate);
    gate.hp = 1;
    run.position = gate.center - const Point<double>(1, 0);
    expect(run.attack(gate.center), isTrue);
    _tick(run, .4);
    expect(run.solarStairs, gate.center);
    expect(run.enterSolarDungeon(), isTrue);
    expect(run.solarPhase, LiteSolarPhase.courtyard);
    run.enemies.clear();
    _tick(run, .02);
    expect(
      run.enemies.map((enemy) => enemy.kind),
      unorderedEquals([
        LiteEnemyKind.eliteSolare,
        LiteEnemyKind.guardiaSolare,
        LiteEnemyKind.guardiaSolare,
        LiteEnemyKind.aberrazioneSolare,
      ]),
    );
    final gold = run.obser;
    run.enemies.clear();
    _tick(run, .02);
    expect(run.obser, gold + 72);
    run = LiteRun.fromJson(run.toJson());
    expect(run.solarBossWaiting && run.restHub, isTrue);
    _tick(run, 1);
    expect(run.obser, gold + 72);
    run.position = run.portalPosition;
    expect(run.enterSolarBoss(), isTrue);
    expect(run.enemies.single.kind, LiteEnemyKind.guardianoSolare);
    expect(run.enterSolarBoss(), isFalse);
    run.enemies.clear();
    _tick(run, .02);
    expect(run.obser, gold + 72 + 96);
    expect(run.solarPhase, LiteSolarPhase.cleared);
    expect(run.unlockedHeroesFor(run.hero), contains(LiteHero.guardianoSolare));
  });

  test('a solar hero faces the exact lunar formation in room nine', () {
    final run = _run(hero: LiteHero.guardiaSolare);
    expect(
      run.enemies.every(
        (enemy) =>
            enemy.kind == LiteEnemyKind.guardiaLunare ||
            enemy.kind == LiteEnemyKind.lupoLunare,
      ),
      isTrue,
    );
    for (var i = 0; i < 8; i++) {
      _clear(run);
      run.position = run.portalPosition;
      expect(run.advance(), isTrue);
    }
    expect(run.stage, 8);
    expect(
      run.enemies.map((actor) => actor.kind),
      unorderedEquals([
        LiteEnemyKind.custodeLunare,
        LiteEnemyKind.eliteLunare,
        LiteEnemyKind.eliteLunare,
        LiteEnemyKind.guardiaLunare,
        LiteEnemyKind.guardiaLunare,
        LiteEnemyKind.guardiaLunare,
      ]),
    );
  });

  test('the second act survives reloads and grants each room reward once', () {
    var run = _run()..stage = 11;
    _clear(run);
    run.position = run.portalPosition;
    expect(run.enterRestHub(), isTrue);
    run.position = run.portalPosition;
    expect(run.enterSecondAct(LiteRealm.inferno), isTrue);
    expect(run.enterSecondAct(LiteRealm.inferno), isFalse);
    final start = run.obser;
    for (var visit = 1; visit <= LiteSecondAct.actTwoRooms; visit++) {
      _clear(run);
      expect(run.actRoom, visit);
      final cleared = run.obser;
      run = LiteRun.fromJson(run.toJson());
      expect(run.realm, LiteRealm.inferno);
      _tick(run, .2);
      expect(run.obser, cleared);
      if (visit == LiteSecondAct.actTwoRooms) break;
      expect(
        run.takeActRelic(
          [
            LiteActRelic.fendente,
            LiteActRelic.custodia,
            LiteActRelic.iride,
          ][visit - 1],
        ),
        isTrue,
      );
      expect(run.takeActRelic(LiteActRelic.fendente), isFalse);
      run.position = run.portalPosition;
      expect(run.advanceActTwo(), isTrue);
    }
    expect(run.obser, start + 3 * 24 + 62);
    expect(run.relicDamage, closeTo(.04, .0001));
    expect(run.moveActRelic(2, -1), isTrue);
    expect(run.relicDamage, closeTo(.07, .0001));
    expect(run.relicMana, closeTo(.40, .0001));
    expect(run.relicProtection, closeTo(.08, .0001));
    expect(
      run.unlockedHeroesFor(run.hero),
      containsAll([
        LiteHero.demoneMinore,
        LiteHero.demoneIntermedio,
        LiteHero.demoneMaggiore,
        LiteHero.diavolo,
      ]),
    );
    run.position = run.portalPosition;
    expect(run.advance(), isTrue);
    expect(run.stage, 12);
    expect(run.inActTwo, isFalse);
    expect(run.actRelics, hasLength(3));
  });

  test('Divoramitu only accepts hits during its leap', () {
    final run = _run();
    final beast = LiteEnemy(
      800,
      LiteEnemyKind.divoramitu,
      const Point<double>(16, 11),
      280,
    );
    run.obstacles.clear();
    run.enemies
      ..clear()
      ..add(beast);
    void shoot() {
      run.projectiles.add(
        LiteProjectile(
          position: beast.position,
          direction: const Point(0, 0),
          speed: 1,
          remaining: .21,
          damage: 25,
          magic: true,
        ),
      );
    }

    shoot();
    _tick(run, .3);
    expect(beast.hp, beast.maxHp);
    for (var i = 0; i < 360 && !beast.burrow!.exposed; i++) {
      _tick(run, 1 / 120);
    }
    expect(beast.burrow!.exposed, isTrue);
    shoot();
    _tick(run, .035);
    expect(beast.hp, lessThan(beast.maxHp));
  });
}
