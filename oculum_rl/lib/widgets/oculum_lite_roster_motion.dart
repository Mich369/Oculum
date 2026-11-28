part of 'oculum_lite_arena.dart';

enum _RosterMotion {
  luce,
  ombra,
  doppelganger,
  pyrel,
  lithra,
  vegliante,
  lapysrieth,
  sacrycrab,
  thalvyr;

  static _RosterMotion? forHero(LiteHero hero) => switch (hero) {
    LiteHero.luce => luce,
    LiteHero.ombra => ombra,
    LiteHero.doppelganger => doppelganger,
    LiteHero.pyrel => pyrel,
    LiteHero.lithra => lithra,
    _ => null,
  };

  static _RosterMotion? forEnemy(LiteEnemyKind kind) => switch (kind) {
    LiteEnemyKind.vegliante => vegliante,
    LiteEnemyKind.lapysrieth => lapysrieth,
    LiteEnemyKind.sacrycrab => sacrycrab,
    LiteEnemyKind.thalvyr => thalvyr,
    _ => null,
  };

  static const _columns = 9;
}

enum _RosterPose {
  idle,
  walkLeft,
  walkRight,
  runLeft,
  runRight,
  dash,
  windup,
  strike,
  down,
}

_RosterPose _rosterPose({
  required LiteStride? stride,
  required double lead,
  required double sprintSpeed,
  required bool down,
  required bool dashing,
  required bool charging,
  required bool striking,
}) {
  if (down) return _RosterPose.down;
  if (striking) return _RosterPose.strike;
  if (dashing) return _RosterPose.dash;
  if (charging) return _RosterPose.windup;
  if (stride == null || stride.speed < .10) return _RosterPose.idle;
  final walking = stride.walking ?? stride.speed < sprintSpeed;
  final distance = stride.distance + stride.speed * lead;
  final isLeft = (distance / (walking ? .72 : .98)).floor().isEven;
  return walking
      ? (isLeft ? _RosterPose.walkLeft : _RosterPose.walkRight)
      : (isLeft ? _RosterPose.runLeft : _RosterPose.runRight);
}

_RosterPose? _paintRosterMotion(
  Canvas canvas,
  ui.Image? atlas,
  _RosterMotion motion, {
  required double height,
  required LiteStride? stride,
  required double lead,
  required double sprintSpeed,
  required bool down,
  required bool dashing,
  required bool charging,
  required bool striking,
  double hurt = 0,
  bool phantom = false,
}) {
  if (atlas == null) return null;
  final pose = _rosterPose(
    stride: stride,
    lead: lead,
    sprintSpeed: sprintSpeed,
    down: down,
    dashing: dashing,
    charging: charging,
    striking: striking,
  );
  final frameWidth = atlas.width / _RosterMotion._columns;
  final frameHeight = atlas.height / _RosterMotion.values.length;
  final worldWidth = height * frameWidth / frameHeight;
  final recoil = down ? 0.0 : (hurt / .18).clamp(0.0, 1.0);
  final Paint ink = phantom
      ? (Paint()
          ..filterQuality = FilterQuality.medium
          ..color = const Color(0xc0ffffff))
      : _monsterSampler;
  canvas.drawImageRect(
    atlas,
    Rect.fromLTWH(
      pose.index * frameWidth,
      motion.index * frameHeight,
      frameWidth,
      frameHeight,
    ),
    Rect.fromLTWH(
      -worldWidth / 2 - .17 * recoil,
      -height * .955 - .045 * recoil,
      worldWidth,
      height,
    ),
    ink,
  );
  return pose;
}

bool _paintLegacyRosterCreature(
  Canvas canvas,
  _HeroSprites sprites,
  _RosterMotion motion, {
  required double height,
  required double time,
  required LiteStride? stride,
  required bool fallen,
  required bool charging,
  required double strike,
}) {
  final encounters = motion != _RosterMotion.thalvyr;
  final slot = switch (motion) {
    _RosterMotion.vegliante || _RosterMotion.thalvyr => 1,
    _RosterMotion.sacrycrab => 2,
    _RosterMotion.lapysrieth => 4,
    _ => null,
  };
  final atlas = encounters ? sprites.rosterFallback : sprites.third;
  if (atlas == null || slot == null) return false;
  _paintThirdActor(
    canvas,
    atlas,
    slot,
    height,
    time,
    stride?.strength ?? 0,
    charging: charging,
    strike: strike,
    fallen: fallen,
    encounterAtlas: encounters,
  );
  return true;
}
