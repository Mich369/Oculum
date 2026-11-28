import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';

const _aim = Point<double>(26, 11);
const _origin = Point<double>(14, 11);

LiteRun _fixture(LiteWeapon weapon, {int players = 1}) =>
    LiteRun(
        seed: 251,
        hero: LiteHero.duplicatore,
        weapon: weapon,
        playerCount: players,
      )
      ..obstacles.clear()
      ..position = _origin
      ..enemies.clear();

void _advance(LiteRun run, int frames) {
  for (var i = 0; i < frames; i++) {
    run.step(.01);
  }
}

void main() {
  for (final weapon in [
    LiteWeapon.carabinaImpulsi,
    LiteWeapon.balestraRunica,
    LiteWeapon.piccaOssidiana,
    LiteWeapon.guanti,
  ]) {
    test('the pose releases after the exact windup for ${weapon.name}', () {
      final run = _fixture(weapon);
      final enemy = LiteEnemy(
        765,
        LiteEnemyKind.scostubandito,
        const Point<double>(16, 11),
        700,
      )..stunned = 5;
      run.enemies.add(enemy);
      expect(run.attack(_aim), isTrue);
      expect(run.weaponWindup, weapon.chargeSeconds);
      expect(run.weaponReleaseAge(run.time), isNull);
      _advance(run, (weapon.chargeSeconds * 100).round() - 1);
      expect(run.weaponWindup, greaterThan(0));
      expect(enemy.hp, 700);
      expect(run.projectiles, isEmpty);
      _advance(run, 2);
      expect(run.weaponWindup, 0);
      expect(run.weaponReleaseAge(run.time), inInclusiveRange(0, .011));
      expect(enemy.hp < 700 || run.projectiles.isNotEmpty, isTrue);
      final live = LiteRun.fromJson(run.toJson(includeEffects: true));
      expect(live.weaponReleaseAge(live.time), run.weaponReleaseAge(run.time));
      final saved = LiteRun.fromJson(run.toJson());
      expect(saved.weaponReleaseAge(saved.time), isNull);
      _advance(run, 33);
      expect(run.weaponReleaseAge(run.time), isNull);
    });
  }

  test('a cancelled guard windup produces no release or projectile', () {
    final run = _fixture(LiteWeapon.carabinaImpulsi);
    expect(run.attack(_aim), isTrue);
    _advance(run, 7);
    run.setBlocking(true);
    _advance(run, 46);
    expect(run.weaponWindup, 0);
    expect(run.weaponReleaseAge(run.time), isNull);
    expect(run.projectiles, isEmpty);
  });

  test('the second blade only animates when the second strike resolves', () {
    final cut = _fixture(LiteWeapon.doppieLame);
    expect(cut.attack(_aim), isTrue);
    expect(cut.weaponReleaseAge(cut.time), 0);
    expect(cut.secondBladeReleaseAge(cut.time), isNull);
    _advance(cut, 11);
    expect(cut.secondBladeReleaseAge(cut.time), closeTo(0, .006));
    final live = LiteRun.fromJson(cut.toJson(includeEffects: true));
    expect(
      live.secondBladeReleaseAge(live.time),
      cut.secondBladeReleaseAge(cut.time),
    );

    final blocked = _fixture(LiteWeapon.doppieLame);
    expect(blocked.attack(_aim), isTrue);
    blocked.setBlocking(true);
    _advance(blocked, 11);
    expect(blocked.secondBladeReleaseAge(blocked.time), isNull);
  });

  test('a guest receives a release for their own weapon', () {
    final run = _fixture(LiteWeapon.arco, players: 2);
    run.addCoopFighter(
      'guest',
      'Ospite',
      LiteHero.duplicatore,
      LiteWeapon.carabinaImpulsi,
    );
    final guest = run.coopFighter('guest')!..cooldown = 0;
    expect(
      run.setCoopControls('guest', const Point(0, 0), _aim, attack: true),
      isTrue,
    );
    _advance(run, 1);
    expect(guest.weaponWindup, closeTo(.43, .006));
    expect(guest.weaponReleaseAge(run.time), isNull);
    _advance(run, 44);
    expect(guest.weaponReleaseAge(run.time), inInclusiveRange(0, .02));
    expect(run.projectiles, hasLength(1));
    final frame = LiteRun.fromJson(run.toJson(includeEffects: true));
    expect(frame.weaponReleaseAge(frame.time), isNull);
    expect(
      frame.coopFighter('guest')!.weaponReleaseAge(frame.time),
      guest.weaponReleaseAge(run.time),
    );
  });

  test('a rescue animates the fighter that gets up', () {
    final run = _fixture(LiteWeapon.arco, players: 2);
    run.addCoopFighter('guest', 'Ospite', LiteHero.ashley, LiteWeapon.guanti);
    final guest = run.coopFighter('guest')!
      ..position = _origin + const Point<double>(.6, 0)
      ..hp = 0;
    run.setCoopControls('guest', const Point(0, 0), _aim, attack: false);
    expect(run.beginRescue(), isTrue);
    _advance(run, 65);
    run.setCoopControls('guest', const Point(0, 0), _aim, attack: false);
    _advance(run, (LiteRun.rescueDuration * 100).ceil() - 64);
    expect(guest.hp, greaterThan(0));
    expect(run.rescuedAge(run.time), isNull);
    expect(guest.rescuedAge(run.time), inInclusiveRange(0, .02));
    final frame = LiteRun.fromJson(run.toJson(includeEffects: true));
    expect(
      frame.coopFighter('guest')!.rescuedAge(frame.time),
      guest.rescuedAge(run.time),
    );
    _advance(run, 43);
    expect(guest.rescuedAge(run.time), isNull);
  });

  test('Ashley walk mode follows movement and is carried in live frames', () {
    const move = Point<double>(1, 0);
    final run =
        LiteRun(
            seed: 251,
            hero: LiteHero.ashley,
            weapon: LiteWeapon.arco,
            playerCount: 2,
          )
          ..position = _origin
          ..obstacles.clear()
          ..enemies.clear();
    run.addCoopFighter('ashley', 'Ospite', LiteHero.ashley, LiteWeapon.chakram);
    final guest = run.coopFighter('ashley')!
      ..position = _origin + const Point<double>(0, 2);
    expect(
      run.setCoopControls('ashley', move, _aim, attack: false, slow: false),
      isTrue,
    );
    run.step(.04, move: move, walk: true);
    expect(run.stride.walking, isTrue);
    expect(guest.stride.walking, isFalse);
    expect(run.stride.distance, greaterThan(0));
    expect(guest.stride.speed, greaterThan(run.stride.speed));
    final live = LiteRun.fromJson(run.toJson(includeEffects: true));
    expect(live.stride.walking, isTrue);
    expect(live.coopFighter('ashley')!.stride.walking, isFalse);
    final saved = LiteRun.fromJson(run.toJson());
    expect(saved.stride.walking, isNull);
    expect(saved.coopFighter('ashley')!.stride.walking, isNull);

    expect(
      run.setCoopControls('ashley', move, _aim, attack: false, slow: true),
      isTrue,
    );
    run.step(.04, move: move);
    expect(run.stride.walking, isFalse);
    expect(guest.stride.walking, isTrue);
    expect(run.dash(_aim), isTrue);
    run.step(.01, move: move, walk: true);
    expect(run.stride.walking, isFalse);
    expect(run.burstRemaining, greaterThan(0));
  });
}
