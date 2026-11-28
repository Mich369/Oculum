part of 'oculum_lite_run.dart';

/// An Open is resolved once, then its presentation runs on the real clock.
class LiteOpenScene {
  LiteOpenScene._(
    this.hero,
    this.at,
    this.direction,
    this.actorId, {
    this.enemyId,
    this.shadow = false,
    double remaining = duration,
  }) : _remaining = remaining;

  static const duration = .72;
  static const coopTimeScale = .24;
  static const coopAllyMovementScale = .26;

  final LiteHero hero;
  final Point<double> at, direction;
  final int actorId;
  final int? enemyId;
  final bool shadow;
  double _remaining;
  double get remaining => _remaining;
  bool get hostile => enemyId != null;
  String get title => hostile
      ? '${shadow ? 'Ombra' : 'Luce'} · ${hero.openName}'
      : hero.openName;

  double progress({double lead = 0}) =>
      (1 - (remaining - lead) / duration).clamp(0.0, 1.0);

  List<Object?> _frame() => [
    hero.name,
    _savePoint(at),
    _savePoint(direction),
    actorId,
    enemyId,
    shadow,
    remaining,
  ];

  static LiteOpenScene? _read(Object? value) {
    if (value is! List || value.length != 7) return null;
    final hero = LiteHero.values
        .where((entry) => entry.name == value[0])
        .firstOrNull;
    final remaining = _num(value[6]).clamp(0.0, duration);
    if (hero == null || !remaining.isFinite || remaining <= 0) return null;
    return LiteOpenScene._(
      hero,
      _point(value[1]),
      _point(value[2]),
      max(0, _int(value[3])),
      enemyId: value[4] is int ? value[4] as int : null,
      shadow: value[5] == true,
      remaining: remaining,
    );
  }
}
