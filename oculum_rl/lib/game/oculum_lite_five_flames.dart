part of 'oculum_lite_run.dart';

extension on LiteRun {
  void _syncInfernalPact() {
    final lunar = hero.lunar
        ? null
        : coopFighters.where((fighter) => fighter.hero.lunar).firstOrNull;
    if (!hero.lunar && lunar == null) return;
    final willing = enemies
        .where(
          (enemy) =>
              enemy.kind == LiteEnemyKind.diavolo &&
              !enemy.fiveFlames &&
              enemy.hp > 0,
        )
        .toList();
    if (willing.isEmpty) return;
    for (final devil in willing) {
      enemies.remove(devil);
      clones.add(
        LiteClone(
          devil.position,
          devil.hp,
          LiteCompanion.diavoloAlleato.weapon,
          id: devil.id,
          maxHp: devil.maxHp,
          ownerId: lunar?.id ?? 0,
          companion: LiteCompanion.diavoloAlleato,
        ),
      );
      _progressQuest(0);
    }
    message = 'I diavoli onorano il patto con la Luna.';
  }

  void _tickFiveFlames(LiteEnemy devil, double elapsed) {
    devil.summonIn = max(0, devil.summonIn - elapsed);
    if (devil.summonIn > 0 ||
        devil.position.distanceTo(_enemyAimFrom(devil.position)) >= 14)
      return;
    devil.summonIn = 6.2;
    final existing = enemies
        .where((enemy) => enemy.demonSummoned && enemy.hp > 0)
        .length;
    if (existing >= 4) return;
    final flank = Point<double>(0, devil.combatCycle.isEven ? -1.6 : 1.6);
    final lesser = _spawnEnemy(
      LiteEnemyKind.demoneMinore,
      devil.position + flank,
    )..demonSummoned = true;
    if (existing <= 2) {
      _spawnEnemy(LiteEnemyKind.demoneIntermedio, devil.position - flank)
        ..demonSummoned = true;
    }
    _recordImpact(LiteImpactTarget.explosion, lesser.id, lesser.position);
    _combatImpacts.add(
      LiteCombatImpact(
        LiteImpactTarget.fiveFlames,
        -devil.id,
        devil.position,
        time,
      ),
    );
  }

  void _openFiveFlames(
    Point<double> at,
    Point<double> direction,
    LiteCoopFighter? fighter,
    int grade,
  ) {
    final owner = fighter?.id ?? 0;
    for (final angle in const [-.66, -.33, 0.0, .33, .66]) {
      projectiles.add(
        LiteProjectile(
          position: at + _rotate(direction, angle) * .36,
          direction: _rotate(direction, angle),
          speed: 17,
          remaining: 14,
          damage: (17 + grade * 5) * LiteRun.openPower,
          magic: true,
          kind: LiteProjectileKind.pattoFiamma,
          ownerCanHeal: fighter == null,
          sourceCloneId: fighter?.id,
        ),
      );
    }
    for (final (kind, maximum) in [
      (LiteCompanion.demoneMinoreEvocato, 3),
      (LiteCompanion.demoneIntermedioEvocato, 1),
    ]) {
      final existing = clones
          .where(
            (ally) =>
                ally.ownerId == owner &&
                ally.companion == kind &&
                (ally.hp > 0 || ally.down),
          )
          .length;
      for (var i = existing; i < maximum; i++) {
        final beside =
            at +
            _rotate(direction, (i - 1) * .95) *
                (kind == LiteCompanion.demoneMinoreEvocato ? 1.25 : 2.15);
        final clone = LiteClone(
          _safePoint(beside, .35, at),
          kind.life * (1 + .20 * grade),
          kind.weapon,
          companion: kind,
          summoned: true,
          id: _nextId++,
          damageScale: LiteRun.openPower,
          ownerId: owner,
        );
        clones.add(clone);
        _recordImpact(LiteImpactTarget.explosion, clone.id, clone.position);
      }
    }
    if (_combatImpacts.length >= 32) _combatImpacts.removeAt(0);
    _combatImpacts.add(
      LiteCombatImpact(
        LiteImpactTarget.fiveFlames,
        owner,
        at,
        time,
        end: at + direction,
      ),
    );
  }

  void _dismissOwnerlessDemons() {
    clones.removeWhere((ally) {
      if (ally.companion?.isFlameDemon != true) return false;
      if (ally.ownerId == 0) return dead;
      final fighter = _coopFighterById(ally.ownerId);
      return fighter == null || fighter.hp <= 0;
    });
  }
}
