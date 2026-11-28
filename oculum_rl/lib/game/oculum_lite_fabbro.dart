part of 'oculum_lite_run.dart';

String _fabbroUnlockKey(String account) => 'fabbro-tempra:' + account;

extension _LiteFabbro on LiteRun {
  void _forgeQuake(
    Point<double> source,
    double damage,
    int? owner, {
    double radius = 5.15,
    double push = 5.8,
  }) {
    for (var index = 0; index < 8; index++) {
      final angle = index * pi / 4 + .17;
      final direction = Point(cos(angle), sin(angle));
      var end = source;
      for (var travelled = .18; travelled <= radius; travelled += .18) {
        final next = source + direction * travelled;
        if (_blocked(next, .12)) break;
        end = next;
      }
      if (end == source) continue;
      if (_combatImpacts.length >= 32) _combatImpacts.removeAt(0);
      _combatImpacts.add(
        LiteCombatImpact(
          LiteImpactTarget.fissure,
          _nextId++,
          source,
          time,
          end: end,
        ),
      );
    }
    for (final enemy in enemies) {
      final contact = enemy.closestHitboxPoint(source);
      if (!enemy.hitboxContains(source, extra: radius) ||
          _lineBlocked(source, contact))
        continue;
      _hitEnemy(
        enemy,
        damage,
        ownerCanHeal: owner == null,
        sourceCloneId: owner,
        impactFrom: source,
        forceImpact: true,
        launch: push,
      );
    }
    _recordImpact(LiteImpactTarget.explosion, _nextId++, source);
  }

  void _armory(Point<double> source, int ownerId, int grade) {
    const arsenal = [
      LiteWeapon.spadaScudo,
      LiteWeapon.falceRunica,
      LiteWeapon.piccaOssidiana,
      LiteWeapon.doppieLame,
      LiteWeapon.chakram,
      LiteWeapon.martelloForgia,
    ];
    final active = clones
        .where(
          (ally) => ally.hp > 0 && ally.forgedWeapon && ally.ownerId == ownerId,
        )
        .length;
    for (var index = active; index < 20; index++) {
      final bearing = index * 2 * pi / 20;
      final radius = index.isEven ? 1.33 : 2.48;
      final pos = _safePoint(
        source + Point(cos(bearing), sin(bearing)) * radius,
        .27,
        source,
      );
      clones.add(
        LiteClone(
          pos,
          7.0,
          arsenal[index % arsenal.length],
          ownerId: ownerId,
          summoned: true,
          forgedWeapon: true,
          forgedWard: 2,
          damageScale: 1 + .15 * grade,
          id: _nextId++,
        )..cooldown = .30 + .025 * (index % 8),
      );
    }
  }

  void _tickForgedWeapon(LiteClone arm, double elapsed) {
    final owner = _coopFighterById(arm.ownerId);
    if (owner?.connected == false) return;
    final at = owner?.position ?? position;
    final target = _companionTarget(arm, at);
    arm.cooldown = max(
      0,
      arm.cooldown - elapsed * _divoramituAllyAttack(arm.position),
    );
    if (target != null &&
        target.hitboxContains(arm.position, extra: 1.68) &&
        !_lineBlocked(arm.position, target.closestHitboxPoint(arm.position))) {
      if (arm.cooldown > 0) return;
      arm
        ..cooldown = .94
        .._poseAim = LiteRun._unit(target.position - arm.position)
        .._swing = .23;
      _hitEnemy(
        target,
        28 * arm.damageScale,
        ownerCanHeal: false,
        sourceCloneId: arm.id,
        impactFrom: arm.position,
      );
      return;
    }
    final angle = arm.id % 20 * 2 * pi / 20;
    final goal = target?.position ?? at + Point(cos(angle), sin(angle)) * 2.05;
    if (arm.position.distanceTo(goal) <= .55) return;
    arm.position = _chooseLane(
      arm.position,
      LiteRun._unit(goal - arm.position),
      elapsed * 5.7 * _divoramituAllyPace(arm.position),
      .27,
      rightFirst: arm.id.isEven,
    );
  }
}
