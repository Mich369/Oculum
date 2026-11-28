part of 'oculum_lite_arena.dart';

/// Rows of the supplemental sheet with staged anticipation and defeat art.
enum _RosterFinisher {
  solarGuard,
  solarElite,
  pysciwarden,
  aerovyr,
  archon;

  static _RosterFinisher? forEnemy(LiteEnemyKind kind) => switch (kind) {
    LiteEnemyKind.guardiaSolare => solarGuard,
    LiteEnemyKind.eliteSolare => solarElite,
    LiteEnemyKind.aerovyr => aerovyr,
    LiteEnemyKind.arconte => archon,
    _ => null,
  };

  static _RosterFinisher? forHero(LiteHero hero) => switch (hero) {
    LiteHero.guardiaSolare => solarGuard,
    LiteHero.eliteSolare => solarElite,
    LiteHero.pysciwarden => pysciwarden,
    LiteHero.aerovyr => aerovyr,
    _ => null,
  };

  double height({required bool hero}) => switch (this) {
    pysciwarden => 2.88,
    aerovyr => hero ? 3.10 : 3.15,
    archon => 3.30,
    solarGuard || solarElite => 2.72,
  };

  double? enemyCharge(LiteRun run, LiteEnemy enemy) {
    if (!enemy.attacking || enemy.strikePose > 0 || _enemyIsDashing(enemy)) {
      return null;
    }
    final duration = switch (this) {
      solarGuard => .34,
      solarElite => .66,
      aerovyr => run.stormWarning(enemy)?.duration ?? .62,
      archon => enemy.archonAttack?.windup ?? .76,
      pysciwarden => .28,
    };
    return 1 - enemy.windup / duration;
  }
}

double? _impactAge(LiteCombatImpact? impact, double time) =>
    impact == null ? null : time - impact.time;

bool _paintRosterFinish(
  Canvas canvas,
  ui.Image? atlas,
  _RosterFinisher kind, {
  required double height,
  required bool fallen,
  double? fallAge,
  double? charge,
}) {
  if (atlas == null || (!fallen && charge == null)) return false;
  final frame = fallen
      ? (fallAge != null && fallAge >= 0 && fallAge < .22 ? 2 : 3)
      : (charge! < .49 ? 0 : 1);
  _drawRosterFrame(
    canvas,
    atlas,
    row: kind.index,
    frame: frame,
    height: height,
  );
  return true;
}

bool _paintSolarMarch(
  Canvas canvas,
  ui.Image? atlas, {
  required bool elite,
  required LiteStride? stride,
  required double lead,
  required double sprintSpeed,
}) {
  if (atlas == null || stride == null || stride.speed <= .12) return false;
  final running = !(stride.walking ?? (stride.speed < sprintSpeed));
  final distance = stride.distance + stride.speed * lead;
  final left = (distance / (running ? 1.08 : .72)).floor().isOdd;
  _drawRosterFrame(
    canvas,
    atlas,
    row: elite ? 6 : 5,
    frame: (running ? 2 : 0) + (left ? 1 : 0),
    height: 2.72,
  );
  return true;
}

void _drawRosterFrame(
  Canvas canvas,
  ui.Image atlas, {
  required int row,
  required int frame,
  required double height,
}) {
  final width = atlas.width / 4;
  final cellHeight = atlas.height / 7;
  final wide = height * width / cellHeight;
  canvas.drawImageRect(
    atlas,
    Rect.fromLTWH(width * frame, cellHeight * row, width, cellHeight),
    Rect.fromLTWH(-wide / 2 + height * .01, -height * .944, wide, height),
    _monsterSampler,
  );
}
