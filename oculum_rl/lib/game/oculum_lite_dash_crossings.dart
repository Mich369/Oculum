part of 'oculum_lite_run.dart';

extension LiteDashCrossings on LiteRun {
  static const _nearPad = Point<double>(24.35, 2.28);
  static const _farPad = Point<double>(29.55, 2.28);
  static const _padDuration = .34;

  List<Point<double>> get dashPads => obstacles.any((wall) => wall.dashGap)
      ? const [_nearPad, _farPad]
      : const [];

  bool nearDashPad([LiteCoopFighter? fighter]) {
    final at = fighter?.position ?? position;
    return dashPads.any((pad) => pad.distanceTo(at) < 1.15);
  }

  void _placeCrossing() {
    if (!(campPatrols && stage == 0 ||
        realm == LiteRealm.postea && actRoom == 2))
      return;
    if (_blocked(_nearPad, LiteRun._playerRadius) ||
        _blocked(_farPad, LiteRun._playerRadius)) {
      return;
    }
    obstacles.addAll([
      LiteObstacle(25.75, 0, 2.15, 4.12, dashGap: true, fixedMap: true),
      LiteObstacle(27.9, 3.68, 4.10, .46, fixedMap: true),
      LiteObstacle(31.49, 0, .51, 4.12, fixedMap: true),
    ]);
  }

  bool _tryPadDash(Point<double> target, [LiteCoopFighter? fighter]) {
    if (dashPads.isEmpty || gripRemaining(fighter) > 0) return false;
    final at = fighter?.position ?? position;
    final entry = at.distanceTo(_nearPad) < 1.15
        ? _nearPad
        : at.distanceTo(_farPad) < 1.15
        ? _farPad
        : null;
    if (entry == null) return false;
    final exit = entry == _nearPad ? _farPad : _nearPad;
    if (_blocked(exit, LiteRun._playerRadius)) return false;
    final forward = LiteRun._unit(exit - at);
    final input = fighter?.movement ?? _lastMove;
    final aim = LiteRun._unit(target - at);
    final facing = max(
      aim.x * forward.x + aim.y * forward.y,
      input.x * forward.x + input.y * forward.y,
    );
    if (facing < .34) return false;
    final speed = at.distanceTo(exit) / _padDuration;
    _dashLandings[fighter?.id ?? 0] = exit;
    if (fighter == null) {
      _burstDirection = forward;
      _burstSpeed = speed;
      _burstTime = _padDuration;
      _dashCooldown = 1.1;
      _invulnerability = max(_invulnerability, _padDuration);
    } else {
      fighter
        .._dashDirection = forward
        .._dashSpeed = speed
        .._dashRemaining = _padDuration
        .._dashCooldown = 1.1
        .._protection = max(fighter._protection, _padDuration);
    }
    _beginBurstTrace(LiteBurstKind.phase, _padDuration, fighter: fighter);
    return true;
  }

  Point<double> _advancePadDash(
    Point<double> at,
    double remaining,
    double elapsed,
    int fighterId,
  ) {
    final landing = _dashLandings[fighterId]!;
    if (remaining > elapsed + 1e-9) {
      return at + (landing - at) * (elapsed / remaining);
    }
    _dashLandings.remove(fighterId);
    if (landing == _farPad &&
        achievements.add('passaggio-scatto-$inputArena')) {
      _awardPartyObser(9);
      message = 'Passaggio della pedana · +9 Obser.';
    }
    return landing;
  }

  List<Object?> get _padFrames => [
    for (final entry in _dashLandings.entries)
      [
        entry.key,
        _savePoint(entry.value),
        entry.key == 0
            ? _burstTime
            : _coopFighterById(entry.key)?._dashRemaining ?? 0,
      ],
  ];

  void _restorePadFrames(Object? data) {
    if (dashPads.isEmpty) return;
    for (final saved in _list(data)) {
      if (saved is! List || saved.length != 3) continue;
      final id = _int(saved[0], -1);
      final fighter = _coopFighterById(id);
      if (id != 0 && fighter == null) continue;
      final at = fighter?.position ?? position;
      final landing = _point(saved[1]);
      final duration = _num(saved[2]).clamp(0.0, _padDuration).toDouble();
      if (!dashPads.contains(landing) ||
          duration <= 0 ||
          at.distanceTo(landing) > 6.5 ||
          (at.y - landing.y).abs() > 1.2)
        continue;
      _dashLandings[id] = landing;
      if (fighter == null) {
        _burstTime = duration;
        _burstDirection = LiteRun._unit(landing - position);
        _invulnerability = max(_invulnerability, duration);
      } else {
        fighter
          .._dashRemaining = duration
          .._dashDirection = LiteRun._unit(landing - fighter.position)
          .._protection = max(fighter._protection, duration);
      }
    }
  }
}
