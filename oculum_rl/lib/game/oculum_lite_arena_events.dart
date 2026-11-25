part of 'oculum_lite_run.dart';

enum LiteArenaEventKind {
  pressa('Pressa runica', 8.4, 1.25, .36, 9),
  braci('Braci affioranti', 8.8, 1.15, .72, 8),
  sciroppo('Sciroppo viscoso', 7.5, 1.1, 2.4, 0),
  sigillo('Sigillo instabile', 9.1, 1.35, .49, 7);

  const LiteArenaEventKind(
    this.label,
    this.period,
    this.warning,
    this.active,
    this.damage,
  );
  final String label;
  final double period, warning, active, damage;
}

/// A visible combat lane or disc. Its phase follows the authoritative run clock.
class LiteArenaEvent {
  const LiteArenaEvent._(
    this.kind,
    this.center,
    this.xRadius,
    this.yRadius,
    this.phase,
    this.active,
  );

  final LiteArenaEventKind kind;
  final Point<double> center;
  final double xRadius, yRadius, phase;
  final bool active;

  bool get isLane => kind == LiteArenaEventKind.pressa;
  String get notice =>
      '${kind.label} · ${active ? 'Attivo' : 'Zona in pericolo'}';
  bool contains(Point<double> point) {
    final dx = (point.x - center.x).abs() / xRadius;
    final dy = (point.y - center.y).abs() / yRadius;
    return isLane ? dx <= 1 && dy <= 1 : dx * dx + dy * dy <= 1;
  }
}

extension LiteArenaEvents on LiteRun {
  LiteArenaEventKind? get arenaEventKind {
    if (restHub || inSolarDungeon || goblinCamp || inThirdAct) return null;
    if (realm case final area?) {
      return switch (area) {
        LiteRealm.postea => LiteArenaEventKind.pressa,
        LiteRealm.inferno => LiteArenaEventKind.braci,
        LiteRealm.caramella => LiteArenaEventKind.sciroppo,
      };
    }
    if (stage < 3 ||
        stage >= LiteRun.lateStage ||
        encounter != LiteEncounter.ordinary)
      return null;
    return switch (biome) {
      LiteBiome.postea => LiteArenaEventKind.pressa,
      LiteBiome.dungeon => LiteArenaEventKind.sigillo,
      _ => null,
    };
  }

  LiteArenaEvent? get arenaEvent => _arenaEventAt(time);

  LiteArenaEvent? _arenaEventAt(double now) {
    final start = _arenaEventStart;
    final kind = arenaEventKind;
    if (start == null || kind == null || finished || stageClear) return null;
    final elapsed = now - start;
    if (elapsed < 4.8) return null;
    final cycle = ((elapsed - 4.8) / kind.period).floor();
    final phase = (elapsed - 4.8) % kind.period;
    if (phase >= kind.warning + kind.active) return null;
    final lane = ((seed % 3) + stage + actRoom + cycle) % 3;
    final y = const [5.4, 11.0, 16.6][lane];
    final active = phase >= kind.warning;
    final progress = active
        ? (phase - kind.warning) / kind.active
        : phase / kind.warning;
    final (x, rx, ry) = switch (kind) {
      LiteArenaEventKind.pressa => (19.0, 6.8, .86),
      LiteArenaEventKind.braci => (19.0, 2.8, 2.25),
      LiteArenaEventKind.sciroppo => (14.5, 3.6, 2.55),
      LiteArenaEventKind.sigillo => (15.0, 2.1, 2.1),
    };
    return LiteArenaEvent._(kind, Point(x, y), rx, ry, progress, active);
  }

  void _tickArenaEvent(double elapsed) {
    final event = arenaEvent;
    if (enemies.isEmpty || event == null) return;
    if (!event.active ||
        event.kind.damage == 0 ||
        (_arenaEventAt(time - elapsed)?.active ?? false))
      return;
    final damage = event.kind.damage * difficulty.enemyStrength;
    _recordImpact(LiteImpactTarget.explosion, _nextId++, event.center);
    if (event.contains(position)) _damagePlayer(damage);
    for (final ally in _damageableAllies) {
      if (ally.hp <= 0 ||
          !event.contains(ally.position) ||
          ally is LiteCoopFighter && ally.protected)
        continue;
      _hitAlly(ally, damage);
    }
  }

  double _arenaTerrainSpeedAt(Point<double> at) {
    if (realm != LiteRealm.caramella) return 1;
    final event = arenaEvent;
    if (event == null ||
        !event.active ||
        event.kind != LiteArenaEventKind.sciroppo ||
        !event.contains(at)) {
      return 1;
    }
    return .68;
  }
}
