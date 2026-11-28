import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_audio.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';

const _enemyAt = Point<double>(24, 7);
const _heroAt = Point<double>(20, 7);

LiteRun _run(LiteBiome biome, {int players = 1}) =>
    LiteRun(
        seed: 41119,
        hero: LiteHero.evasore,
        weapon: LiteWeapon.spadaScudo,
        playerCount: players,
        explorationRoutes: true,
        biome: biome,
      )
      ..enemies.clear()
      ..fauna.clear()
      ..obstacles.clear()
      ..position = _heroAt;

LiteEnemy _patrol(LiteEnemyKind kind) => LiteEnemy(6100, kind, _enemyAt, 120)
  ..guard = (LiteGuard(_enemyAt)..facing = const Point(-1, 0))
  ..cooldown = 80;

void _tick(LiteRun run, double seconds) {
  while (seconds > 1e-8) {
    final elapsed = min(.1, seconds);
    run.step(elapsed);
    seconds -= elapsed;
  }
}

void main() {
  test('each area changes from exploration to combat and back', () {
    for (final area in LiteBiome.values) {
      final director = LiteAdaptiveSoundtrack();
      final patrol = _patrol(LiteEnemyKind.scostubandito);
      final run = _run(area)..enemies.add(patrol);
      expect(director.cue(run).track, 'quiete-${area.name}');
      patrol.guard!.mode = LiteGuardMode.indaga;
      expect(director.cue(run).track, 'quiete-${area.name}');

      run.step(.02);
      expect(director.cue(run).track, 'scontro-${area.name}');
      final replica = LiteRun.fromJson(run.toJson(includeEffects: true));
      expect(director.cue(replica).track, 'scontro-${area.name}');

      run.position = const Point(3, 21);
      _tick(run, 3.2);
      expect(director.cue(run).track, 'quiete-${area.name}');
    }
  });

  test(
    'boss cue waits for real sight and stays unique across co-op frames',
    () {
      final director = LiteAdaptiveSoundtrack();
      final boss = _patrol(LiteEnemyKind.granScostumato);
      final run = _run(LiteBiome.deserto, players: 2)..enemies.add(boss);
      boss.guard!
        ..mode = LiteGuardMode.allerta
        ..attention = 12;
      run.obstacles.add(LiteObstacle(21.8, 6, .5, 2, fixedMap: true));
      run.step(.1);
      expect(director.cue(run), (track: 'quiete-deserto', banditIntro: false));

      run.obstacles.clear();
      run.step(.02);
      final firstFrame = LiteRun.fromJson(run.toJson(includeEffects: true));
      expect(director.cue(firstFrame), (
        track: 'boss-banda',
        banditIntro: true,
      ));
      expect(director.cue(LiteRun.fromJson(run.toJson(includeEffects: true))), (
        track: 'boss-banda',
        banditIntro: false,
      ));

      run.position = const Point(3, 21);
      _tick(run, 3.2);
      expect(director.cue(run).track, 'quiete-deserto');

      boss
        ..position = _enemyAt
        ..guard!.facing = const Point(-1, 0);
      run.position = _heroAt;
      run.step(.02);
      expect(director.cue(run), (track: 'boss-banda', banditIntro: false));
      director.reset();
      expect(director.cue(run), (track: 'boss-banda', banditIntro: true));
    },
  );

  test('dedicated boss themes win over combat and ordinary elites', () {
    final director = LiteAdaptiveSoundtrack();
    final run = _run(LiteBiome.orea)
      ..enemies.addAll([
        LiteEnemy(6101, LiteEnemyKind.forestDemon, _enemyAt, 120)
          ..attackTarget = _heroAt,
        LiteEnemy(6102, LiteEnemyKind.ombra, _enemyAt, 120)
          ..attackTarget = _heroAt,
        LiteEnemy(6103, LiteEnemyKind.veyrth, _enemyAt, 120),
      ]);
    expect(director.cue(run).track, 'ombra');
    run.enemies.last.attackTarget = _heroAt;
    expect(director.cue(run).track, 'veyrth');
    run.enemies[1].hp = run.enemies[2].hp = 0;
    expect(director.cue(run).track, 'elite');
    run.enemies[0].hp = 0;
    expect(director.cue(run).track, 'quiete-orea');
  });
}
