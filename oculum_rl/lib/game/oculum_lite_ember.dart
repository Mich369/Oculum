part of 'oculum_lite_run.dart';

extension LiteEmberSentinel on LiteRun {
  bool hasEmberSentinel([LiteCoopFighter? fighter]) =>
      (fighter?.hero ?? hero) == LiteHero.pyrel &&
      !(fighter?.supply ?? supply).emberSpent &&
      (fighter?.hp ?? hp) > 0;

  Point<double> emberPosition([LiteCoopFighter? fighter]) =>
      (fighter?.position ?? position) - (fighter?.aim ?? aim) * 1.2;

  void _tickEmber(double elapsed, [LiteCoopFighter? fighter]) {
    if (!hasEmberSentinel(fighter) ||
        restHub ||
        fighter != null && !fighter.connected)
      return;
    final kit = fighter?.supply ?? supply;
    kit.emberCooldown = max(0, kit.emberCooldown - elapsed);
    if (kit.emberCooldown > 0) return;
    final at = emberPosition(fighter);
    final target = _nearestEnemy(at);
    if (target == null ||
        at.distanceTo(target.position) > 9 ||
        _lineBlocked(at, target.position))
      return;
    _launchFireball(
      at,
      LiteRun._unit(target.position - at),
      8 + (fighter?.level ?? level) * 2.0,
      0,
      fighter?.id,
    );
    kit.emberCooldown = 1.45;
  }

  bool _emberRebirth([LiteCoopFighter? fighter]) {
    final kit = fighter?.supply ?? supply;
    if ((fighter?.hero ?? hero) != LiteHero.pyrel ||
        kit.emberSpent ||
        (fighter?.hp ?? hp) > 0)
      return false;
    kit.emberSpent = true;
    final at = fighter?.position ?? position;
    if (fighter == null) {
      hp = maxHp * .35;
      _invulnerability = max(_invulnerability, 1.4);
      _block.held = false;
    } else {
      fighter.hp = fighter.maxHp * .35;
      fighter._protection = max(fighter._protection, 1.4);
      fighter._block.held = false;
    }
    endRescue(fighter);
    if (_combatImpacts.length >= 32) _combatImpacts.removeAt(0);
    _combatImpacts.add(
      LiteCombatImpact(
        LiteImpactTarget.emberRebirth,
        fighter?.id ?? 0,
        emberPosition(fighter),
        time,
        end: at,
      ),
    );
    _openBurst(
      at,
      4.4,
      24 + 6.0 * (fighter?.level ?? level),
      fighter?.id ?? 0,
      push: 2.7,
    );
    message = 'Fiammela di Pyrel · Rinascita di brace · 35% Vita.';
    return true;
  }
}
