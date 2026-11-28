part of 'oculum_lite_run.dart';

class _LiteAssassinStealth {
  static const floorMask = 0x0f;
  static const finalFloor = 3;
  static const veilDuration = 3.0;
  static const recovery = 6.0;
  static const host = '';

  final floors = <String, int>{};
  int ambushFloors = 0;
  double cooldown = 0;

  bool get hasState => floors.isNotEmpty || ambushFloors != 0 || cooldown > 0;

  Map<String, Object> get frame => {
    if (floors.isNotEmpty) 'floors': Map<String, int>.of(floors),
    if (ambushFloors != 0) 'ambush': ambushFloors,
    if (cooldown > 0) 'cooldown': cooldown,
  };

  void restore(Object? raw, Iterable<LiteCoopFighter> guests) {
    if (raw is! Map) return;
    cooldown = _num(raw['cooldown']).clamp(0.0, recovery);
    ambushFloors = _int(raw['ambush']).clamp(0, floorMask);
    if (raw['floors'] case final Map progress) {
      for (final account in [host, ...guests.map((guest) => guest.account)]) {
        final earned = _int(progress[account]).clamp(0, floorMask);
        if (earned != 0) floors[account] = earned;
      }
    }
  }
}

class _LiteAssassinBox {
  bool active = false;
  final witnesses = <int>{};

  void open() {
    active = false;
    witnesses.clear();
  }

  void restore(Object? data) {
    if (data is! List) return;
    active = true;
    witnesses.addAll(data.whereType<int>().where((id) => id > 0).take(80));
  }
}

String _assassinGuestUnlockKey(String account) =>
    'assassino-personale-$account';

extension LiteAssassinStealth on LiteRun {
  double get assassinVeilRemaining =>
      max(0, _assassinStealth.cooldown - _LiteAssassinStealth.veilDuration);

  /// Seconds until another Assassin Shift can conceal the party.
  double get assassinVeilCooldown => _assassinStealth.cooldown;

  bool get _assassinVeiled => assassinVeilRemaining > 1e-9;

  bool get assassinBoxActive =>
      hero == LiteHero.assassino && hp > 0 && _assassinBox.active;

  _LiteAssassinBox? _boxForHuman(int id) {
    if (id == 0) return assassinBoxActive ? _assassinBox : null;
    final guest = coopFighters.where((fighter) => fighter.id == id).firstOrNull;
    return guest?.assassinBoxActive == true ? guest!._assassinBox : null;
  }

  bool _boxHiddenFrom(int human, int enemy) {
    final box = _boxForHuman(human);
    return box != null && !box.witnesses.contains(enemy);
  }

  bool toggleAssassinBox([LiteCoopFighter? fighter]) {
    if ((fighter?.hero ?? hero) != LiteHero.assassino ||
        (fighter?.hp ?? hp) <= 0 ||
        fighter?.connected == false ||
        finished ||
        shopOpen) {
      return false;
    }
    final box = fighter?._assassinBox ?? _assassinBox;
    if (box.active) {
      box.open();
      return true;
    }
    if (gripRemaining(fighter) > 0 ||
        (fighter?._night ?? _night).stun > 0 ||
        (fighter?._windup ?? _windup) > 0 ||
        (fighter?._dashRemaining ?? _burstTime) > 0 ||
        (fighter?._rescue ?? (fighter == null ? _rescue : null)) != null ||
        (fighter?.blocking ?? blocking) ||
        _shadowRays.containsKey((false, fighter?.id ?? 0))) {
      return false;
    }
    final at = fighter?.position ?? position;
    final id = fighter?.id ?? 0;
    if (!_assassinVeiled && !inExplorationAtrium(at)) {
      for (final enemy in enemies) {
        if (enemy.hp <= 0 || enemy.kind.echo) continue;
        final mind = _sightStateFor(enemy);
        if (enemy.attackTarget case final target? when enemy.guard == null) {
          final heading = LiteRun._unit(target - enemy.position);
          if (heading.magnitude > 0) mind.facing = heading;
        }
        if (_observerSees(
          enemy,
          mind,
          at,
          fighter == null ? _walking : fighter._slow,
          ignoreBush: mind._bushEntries[id],
        )) {
          box.witnesses.add(enemy.id);
        }
      }
    }
    box.active = true;
    return true;
  }

  void _openAssassinBox([LiteCoopFighter? fighter]) {
    final box = fighter?._assassinBox ?? _assassinBox;
    if (box.active) box.open();
  }

  bool get _isAssassinTrialFloor =>
      stage >= 0 &&
      stage <= _LiteAssassinStealth.finalFloor &&
      !usesSubArena &&
      !baghestFight;

  void _noteAssassinAmbush() {
    if (_isAssassinTrialFloor) _assassinStealth.ambushFloors |= 1 << stage;
  }

  void _creditAssassinKill(LiteEnemy enemy, String account) {
    if (!_isAssassinTrialFloor ||
        stageClear ||
        _immediateObserver(enemy) ||
        enemy.kind.echo ||
        !enemies.contains(enemy)) {
      return;
    }
    final floor = 1 << stage;
    if (_assassinStealth.ambushFloors & floor != 0) return;
    _assassinStealth.floors.update(
      account,
      (earned) => earned | floor,
      ifAbsent: () => floor,
    );
  }

  void _completeAssassinTrial() {
    if (stage != _LiteAssassinStealth.finalFloor || !_isAssassinTrialFloor) {
      return;
    }
    final requiredFloors =
        _LiteAssassinStealth.floorMask & ~_assassinStealth.ambushFloors;
    for (final entry in _assassinStealth.floors.entries) {
      if (entry.value & requiredFloors != requiredFloors) continue;
      achievements.add(
        entry.key == _LiteAssassinStealth.host
            ? LiteRun.heroUnlockKey(LiteHero.assassino)
            : _assassinGuestUnlockKey(entry.key),
      );
    }
  }

  void _activateAssassinVeil([LiteCoopFighter? fighter]) {
    if ((fighter?.hero ?? hero) != LiteHero.assassino ||
        _assassinStealth.cooldown > 0) {
      return;
    }
    _assassinStealth.cooldown = _LiteAssassinStealth.recovery;
  }

  void _tickAssassinVeil(double seconds) {
    final remaining = _assassinStealth.cooldown - seconds;
    _assassinStealth.cooldown = remaining > 1e-9 ? remaining : 0;
  }
}
