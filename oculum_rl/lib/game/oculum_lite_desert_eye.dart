part of 'oculum_lite_run.dart';

enum LiteDesertEyeOutcome {
  negativoEccezionale('Dimensione negativa eccezionale', 4, 8),
  negativo('Dimensione negativa', 2, 5),
  positivo('Dimensione positiva', 0, 15),
  positivoEccezionale('Dimensione positiva eccezionale', 0, 30);

  const LiteDesertEyeOutcome(this.label, this.guardians, this.obser);
  final String label;
  final int guardians;
  final int obser;
  bool get positive => guardians == 0;

  static LiteDesertEyeOutcome fromRoll(int natural) {
    RangeError.checkValueInInterval(natural, 1, 20, 'Fortuna');
    if (natural == 1) return negativoEccezionale;
    if (natural <= 10) return negativo;
    if (natural < 20) return positivo;
    return positivoEccezionale;
  }
}

class _LiteDesertEye {
  const _LiteDesertEye(this.roll, this.cut, this.enteredAt, this.origin);

  final int roll, cut;
  final double enteredAt;
  final Map<String, dynamic> origin;
  LiteDesertEyeOutcome get outcome => LiteDesertEyeOutcome.fromRoll(roll);

  Map<String, dynamic> get frame => {
    'roll': roll,
    if (cut > 0) 'cut': cut,
    'enteredAt': enteredAt,
    'origin': origin,
  };

  static _LiteDesertEye? read(Object? value) {
    if (value is! Map ||
        value['roll'] is! int ||
        value['origin'] is! Map ||
        value['enteredAt'] is! num)
      return null;
    final roll = value['roll'] as int;
    final source = Map<String, dynamic>.from(value['origin'] as Map);
    if (roll < 1 || roll > 20 || _list(source['quests']).length != 3)
      return null;
    return _LiteDesertEye(
      roll,
      _int(value['cut']).clamp(0, 12),
      _num(value['enteredAt']),
      source,
    );
  }
}

extension LiteDesertEye on LiteRun {
  static const _arrival = Point<double>(4, 11);
  static const _entrance = Point<double>(5.2, 11);
  static const _triggerRadius = .9;
  static const _returnRadius = 1.75;

  bool get inDesertEye => _desertEye != null;
  LiteDesertEyeOutcome? get desertEyeOutcome => _desertEye?.outcome;
  int? get desertEyeFortune => _desertEye?.roll;
  int? get desertEyeCut {
    final cut = _desertEye?.cut ?? 0;
    return cut > 0 ? cut : null;
  }

  String get desertEyeCutLabel =>
      desertEyeCut == null ? '' : ' · Taglio 1d12: $desertEyeCut';

  String get _desertEyeKey => 'occhio-divoratore:$stage';

  Point<double>? get desertEyePosition {
    if (!usesExplorableFloor ||
        biome != LiteBiome.deserto ||
        finished ||
        baghestFight ||
        achievements.contains(_desertEyeKey))
      return null;
    if (seed != 41119 || stage != 0) {
      final odds = _LiteRandom(seed ^ ((stage + 1) * 93479))
        ..nextDouble()
        ..nextDouble();
      if (odds.nextInt(4) != 0) return null;
    }
    return _entrance;
  }

  bool _tickDesertEyeEntrance() {
    final eye = desertEyePosition;
    if (eye == null) return false;
    if (!hostDown && position.distanceTo(eye) <= _triggerRadius) {
      _enterDesertEye(null);
      return true;
    }
    final falling = coopFighters
        .where(
          (guest) =>
              guest.connected &&
              guest.hp > 0 &&
              guest.position.distanceTo(eye) <= _triggerRadius,
        )
        .firstOrNull;
    if (falling == null) return false;
    _enterDesertEye(falling);
    return true;
  }

  void _enterDesertEye(LiteCoopFighter? falling) {
    // Resolve contact before resetting controls. Block and Open protections
    // are still in effect in the room where the fighter first hit the edge.
    final blade = _LiteRandom(seed ^ ((stage + 1) * 28477) ^ 0x7339)
      ..nextDouble()
      ..nextDouble();
    final cut = blade.nextInt(12) + 1;
    final beforeLife = falling?.hp ?? hp;
    final beforeShield = falling?.shield ?? shield;
    if (falling == null) {
      _damagePlayer(cut.toDouble());
    } else {
      _hitAlly(falling, cut.toDouble());
    }
    if (finished || hostDown && coopFighters.every((guest) => guest.hp <= 0)) {
      dead = true;
      message = 'Il gruppo è caduto nella fenditura · Taglio 1d12: $cut.';
      return;
    }
    final lifeLost = max(0.0, beforeLife - (falling?.hp ?? hp));
    final shieldLost = max(0.0, beforeShield - (falling?.shield ?? shield));
    final natural = _LiteRandom(seed ^ ((stage + 1) * 58331) ^ 0x5981)
      ..nextDouble()
      ..nextDouble();
    _desertEye = _LiteDesertEye(natural.nextInt(20) + 1, cut, time, {
      'position': _savePoint(position),
      'enemy': enemies.map((enemy) => enemy._json()).toList(),
      'fauna': fauna.map((animal) => animal._json()).toList(),
      'obstacles': obstacles.map((wall) => wall._json()).toList(),
      'loot': loot.map((drop) => drop._json()).toList(),
      'quests': quests.map((quest) => quest._json()).toList(),
      'optional': _optionalMissions.map((quest) => quest._json()).toList(),
      'mappedSectors': _mappedSectors,
      if (_mappedFloor case final discovered?) 'map': discovered,
      if (_mapWaypoint case final pin?) 'pin': _savePoint(pin),
      if (_arenaEventStart case final start?) 'event': start,
      'trial': arenaTrial?.name,
      'trialStart': _trialStart,
      'stageClear': stageClear,
      'eliteDefeated': eliteDefeated,
      'eliteReleased': _eliteReleased,
      'well': _claimedWell,
      'powers': _powerOffers.map((power) => power.name).toList(),
      'allies': {
        for (final ally in [...clones, ...coopFighters])
          '${ally.id}': _savePoint(ally.position),
      },
    });

    achievements.add(_desertEyeKey);
    _clearDesertEyeSpace();
    _mappedFloor = null;
    _mappedSectors = 0;
    _mapWaypoint = null;
    _arenaEventStart = null;
    arenaTrial = null;
    stageClear = eliteDefeated = false;
    _eliteReleased = true;
    position = _arrival;
    stride._reset();
    for (final (i, fighter) in coopFighters.indexed) {
      fighter.position = _coopSpawn(i);
      fighter.stride._reset();
    }
    for (final clone in clones) {
      clone.position = _arrival + const Point(0, 1.4);
      clone.stride._reset();
    }
    _recordImpact(
      falling == null ? LiteImpactTarget.player : LiteImpactTarget.ally,
      falling?.id ?? 0,
      falling?.position ?? position,
      life: lifeLost,
      shield: shieldLost,
    );
    final eye = _desertEye!;
    final outcome = eye.outcome;
    obstacles.addAll([
      LiteObstacle(13, 4.1, 1.7, 3.2, fixedMap: true),
      LiteObstacle(12.0, 14.2, 2, 3.4, fixedMap: true),
      LiteObstacle(22, 7, 2.1, 2.3, breakable: true),
      LiteObstacle(23.5, 13.4, 2.3, 1.5, breakable: true),
    ]);
    for (var i = 0; i < outcome.guardians; i++) {
      _spawnEnemy(
        outcome == LiteDesertEyeOutcome.negativoEccezionale && i == 3
            ? LiteEnemyKind.vegliante
            : LiteEnemyKind.rasvyr,
        Point(23 + (i % 2) * 3.5, 4.6 + i * 3.8),
      );
    }
    quests.addAll([
      LiteQuest(
        'occhio:$stage:guardiani',
        'Abbatti i guardiani',
        outcome.guardians,
        0,
      ),
      LiteQuest('occhio:$stage:scorta', 'Raccogli un bottino', 1, 0),
      LiteQuest('occhio:$stage:varco', 'Apri il varco di ritorno', 1, 0),
    ]);
    if (outcome.positive) {
      _completeDesertEye();
    } else {
      message =
          'Fortuna ${eye.roll}/20 · ${outcome.label}. Sconfiggi i guardiani per aprire il ritorno.';
    }
  }

  void _clearDesertEyeSpace() {
    _clearArenaActions();
    _activeBeam = null;
    _redGrips.clear();
    _chickenTrial.clear();
    projectiles.clear();
    groundShots.clear();
    _combatImpacts.clear();
    enemies.clear();
    fauna.clear();
    obstacles.clear();
    loot.clear();
    quests.clear();
    _optionalMissions.clear();
    _powerOffers.clear();
  }

  void _completeDesertEye() {
    final eye = _desertEye;
    if (eye == null || stageClear || enemies.isNotEmpty) return;
    stageClear = true;
    _progressQuest(2);
    final outcome = eye.outcome;
    obser += outcome.obser;
    for (final fighter in coopFighters) {
      fighter.obser += outcome.obser;
    }
    if (outcome == LiteDesertEyeOutcome.positivoEccezionale) {
      if (!hostDown) _healFighter(maxHp * .25);
      for (final fighter in coopFighters.where((guest) => guest.hp > 0)) {
        _healFighter(fighter.maxHp * .25, fighter);
      }
    }
    message =
        'Fortuna ${eye.roll}/20 · ${outcome.label} · +${outcome.obser} Obser. Varco di ritorno aperto.';
  }

  bool _leaveDesertEye() {
    final eye = _desertEye;
    if (eye == null || !stageClear || finished) return false;
    final source = eye.origin;
    _clearDesertEyeSpace();
    _desertEye = null;
    void restore<T>(
      List<T> items,
      String key,
      T Function(Map<String, dynamic>) read,
    ) {
      items.addAll(
        _list(source[key])
            .whereType<Map>()
            .map((data) => read(Map<String, dynamic>.from(data))),
      );
    }

    restore(enemies, 'enemy', LiteEnemy._read);
    restore(fauna, 'fauna', LiteEnemy._read);
    restore(obstacles, 'obstacles', LiteObstacle._read);
    restore(loot, 'loot', LiteLoot._read);
    restore(quests, 'quests', LiteQuest._read);
    restore(_optionalMissions, 'optional', LiteQuest._read);
    final pause = max(0.0, time - eye.enteredAt);
    _mappedFloor = source['map'] as String?;
    _mappedSectors = _int(source['mappedSectors']).clamp(0, 31);
    _mapWaypoint = source['pin'] is List ? _point(source['pin']) : null;
    _arenaEventStart = source['event'] is num
        ? _num(source['event']) + pause
        : null;
    _trialStart = _num(source['trialStart']) + pause;
    arenaTrial = LiteArenaTrial.values
        .where((trial) => trial.name == source['trial'])
        .firstOrNull;
    stageClear = source['stageClear'] == true;
    eliteDefeated = source['eliteDefeated'] == true;
    _eliteReleased = source['eliteReleased'] == true;
    _claimedWell = source['well'] as String?;
    _powerOffers.addAll(
      LitePowerUp.values.where(
        (power) => _list(source['powers']).contains(power.name),
      ),
    );
    position = _desertEyeReturn(_point(source['position']));
    stride._reset();
    final slots = source['allies'];
    for (final ally in [...clones, ...coopFighters]) {
      final saved = slots is Map ? slots['${ally.id}'] : null;
      ally.position = _desertEyeReturn(
        saved is List ? _point(saved) : position,
      );
      ally.stride._reset();
    }
    message = 'Il gruppo è tornato nel Deserto Divoratore.';
    return true;
  }

  Point<double> _desertEyeReturn(Point<double> at) {
    final preferred = at.distanceTo(_entrance) > _returnRadius
        ? at
        : _entrance + const Point(_returnRadius, 0);
    return _safePoint(preferred, LiteRun._playerRadius, preferred);
  }
}
