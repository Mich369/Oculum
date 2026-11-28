import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';

void main() {
  test(
    'a companion in a guard cone stays quiet and follows a concealed owner',
    () {
      final run =
          LiteRun(
              seed: 41119,
              hero: LiteHero.evasore,
              weapon: LiteWeapon.arco,
              explorationRoutes: true,
              biome: LiteBiome.deserto,
            )
            ..position = const Point(16, 5)
            ..enemies.clear()
            ..obstacles.clear();
      final patrol = LiteEnemy(
        1900,
        LiteEnemyKind.scostubandito,
        const Point(21, 5),
        230,
      )..guard = (LiteGuard(const Point(21, 5))..facing = const Point(-1, 0));
      final ally = LiteClone(
        const Point(18.7, 5),
        65,
        LiteWeapon.scettro,
        id: 1901,
        companion: LiteCompanion.errato,
      )..cooldown = 0;
      run.enemies.add(patrol);
      run.clones.add(ally);
      run.obstacles.add(LiteObstacle(17.35, 4, .5, 2));
      final distance = run.position.distanceTo(ally.position);

      run.step(.10, walk: true);
      expect(run.companionConcealed(ally), isTrue);
      expect(run.position.distanceTo(ally.position), lessThan(distance));
      expect(patrol.guard!.mode, isNot(LiteGuardMode.allerta));
      expect(run.projectiles.where((shot) => !shot.fromEnemy), isEmpty);

      run.obstacles.clear();
      run.position = const Point(16, 5);
      ally.position = const Point(17.7, 5);
      patrol.guard!.facing = const Point(-1, 0);
      run.step(.10);
      expect(patrol.guard!.mode, LiteGuardMode.allerta);
      expect(run.companionConcealed(ally), isFalse);
      expect(
        run.combatImpacts
            .where((impact) => impact.target == LiteImpactTarget.banditSpotted)
            .single
            .subjectId,
        0,
      );
      expect(run.projectiles.where((shot) => !shot.fromEnemy), isNotEmpty);
    },
  );
}
