import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';

void main() {
  test('snapshot keeps host and guest gait when their speeds overlap', () {
    final run =
        LiteRun(
            seed: 251,
            hero: LiteHero.luce,
            weapon: LiteWeapon.piccaOssidiana,
            playerCount: 2,
          )
          ..stageClear = true
          ..enemies.clear()
          ..obstacles.clear()
          ..fauna.clear()
          ..position = const Point(13, 6);
    expect(
      run.addCoopFighter(
        'ombra',
        'Ombra',
        LiteHero.ombra,
        LiteWeapon.doppieLame,
      ),
      isTrue,
    );
    run.coopFighters.single.position = const Point(16, 6);
    expect(
      run.setCoopControls(
        'ombra',
        const Point(1, 0),
        const Point(25, 6),
        attack: false,
      ),
      isTrue,
    );
    run.step(.16, move: const Point(1, 0), walk: true);
    final snapshot = run.toJson(includeEffects: true);
    final guest = (snapshot['fighters'] as List).single as Map<String, Object?>;
    expect(snapshot['strideWalking'], isTrue);
    expect(guest['strideWalking'], isFalse);
    final guestStride = guest['stride'] as List;
    guestStride[2] = run.stride.speed;
    final received = LiteRun.fromJson(snapshot);
    expect(received.stride.walking, isTrue);
    expect(received.coopFighters.single.stride.walking, isFalse);
    expect(received.coopFighters.single.stride.speed, received.stride.speed);

    snapshot.remove('strideWalking');
    guest.remove('strideWalking');
    final legacy = LiteRun.fromJson(snapshot);
    expect(legacy.stride.walking, isNull);
    expect(legacy.coopFighters.single.stride.walking, isNull);
    expect(legacy.stride.speed, greaterThan(0));
    expect(legacy.coopFighters.single.stride.speed, legacy.stride.speed);
  });
}
