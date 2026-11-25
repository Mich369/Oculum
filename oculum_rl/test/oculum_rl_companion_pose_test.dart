import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';

void main() {
  for (final (companion, weapon, range) in [
    (LiteCompanion.scheletroArco, LiteWeapon.arco, 5.0),
    (LiteCompanion.scheletroFalce, LiteWeapon.falceRunica, 1.65),
  ]) {
    test('companion frame keeps the pose for $weapon', () {
      const origin = Point<double>(14, 11);
      final run =
          LiteRun(
              seed: 251,
              hero: LiteHero.duplicatore,
              weapon: LiteWeapon.spadaScudo,
            )
            ..position = origin
            ..obstacles.clear()
            ..enemies.clear();
      final foe = LiteEnemy(
        890,
        LiteEnemyKind.scostubandito,
        origin + Point<double>(range, 0),
        500,
      )..stunned = 5;
      final skeleton = LiteClone(origin, 40, weapon, companion: companion)
        ..cooldown = .12;
      run.enemies.add(foe);
      run.clones.add(skeleton);

      run.step(.04);
      expect(skeleton.preparingPose, inExclusiveRange(0, 1));
      expect(skeleton.poseAim, const Point<double>(1, 0));
      expect(skeleton.swing, 0);
      expect(foe.hp, 500);
      expect(run.projectiles, isEmpty);

      final network = LiteRun.fromJson(run.toJson(includeEffects: true));
      expect(network.clones.single.preparingPose, skeleton.preparingPose);
      final save = LiteRun.fromJson(run.toJson());
      expect(save.clones.single.preparingPose, 0);

      skeleton.corrupted = true;
      expect(skeleton.preparingPose, 0);
      final corruptedFrame = LiteRun.fromJson(run.toJson(includeEffects: true));
      expect(corruptedFrame.clones.single.preparingPose, 0);
      skeleton.corrupted = false;

      run.step(.11);
      expect(skeleton.preparingPose, 0);
      expect(skeleton.swing, greaterThan(0));
      if (weapon == LiteWeapon.arco) {
        expect(run.projectiles.single.kind, LiteProjectileKind.normal);
      } else {
        expect(foe.hp, lessThan(500));
      }
    });
  }
}
