part of 'oculum_lite_run.dart';

enum LiteChamberPattern { ventaglio, croce, fenditura, corona, morsa }

class LiteChamberWarning {
  LiteChamberWarning(this.pattern, this.origin, this.target, this.remaining);

  final LiteChamberPattern pattern;
  final Point<double> origin, target;
  double remaining;
  static const hitRadius = .98;

  late final List<Point<double>> marks = _createMarks();

  List<Point<double>> _createMarks() {
    final axis = LiteRun._unit(target - origin);
    final side = Point(-axis.y, axis.x);
    return switch (pattern) {
      LiteChamberPattern.ventaglio => const [],
      LiteChamberPattern.croce => [
        target,
        for (final direction in [axis, side, axis * -1, side * -1])
          target + direction * 1.65,
      ],
      LiteChamberPattern.fenditura => [
        for (final distance in [1.6, 3.2, 4.8, 6.4, 8.0])
          origin + axis * distance,
      ],
      LiteChamberPattern.corona => [
        for (var i = 0; i < 7; i++)
          target + Point(cos(i * 2 * pi / 7), sin(i * 2 * pi / 7)) * 2.15,
      ],
      LiteChamberPattern.morsa => [
        for (final along in [-1.6, 0.0, 1.6])
          for (final width in [-1.65, 1.65])
            target + axis * along + side * width,
      ],
    };
  }

  late final List<double> angles = _createAngles();

  List<double> _createAngles() {
    final heading = atan2(target.y - origin.y, target.x - origin.x);
    return [
      for (final spread in [-.46, -.23, 0.0, .23, .46]) heading + spread,
    ];
  }

  List<Object> get frame => [
    pattern.name,
    _savePoint(origin),
    _savePoint(target),
    remaining,
  ];

  static LiteChamberWarning? read(Object? value) {
    if (value is! List || value.length != 4) return null;
    final pattern = LiteChamberPattern.values
        .where((it) => it.name == value[0])
        .firstOrNull;
    final seconds = _num(value[3]);
    if (pattern == null || seconds <= 0 || seconds > 1.5) return null;
    return LiteChamberWarning(
      pattern,
      _point(value[1]),
      _point(value[2]),
      seconds,
    );
  }
}

extension LiteChambers on LiteRun {
  static const _draft = [
    LiteEnemyKind.scostubandito,
    LiteEnemyKind.babyForestDemon,
    LiteEnemyKind.slime,
    LiteEnemyKind.gablyn,
    LiteEnemyKind.ragnoSaldatore,
    LiteEnemyKind.dronePostea,
    LiteEnemyKind.orbryx,
    LiteEnemyKind.rasvyr,
    LiteEnemyKind.guardiaLunare,
    LiteEnemyKind.lupoLunare,
    LiteEnemyKind.aberrazioneSolare,
    LiteEnemyKind.corrottoRosso,
    LiteEnemyKind.demoneIntermedio,
    LiteEnemyKind.demoneMaggiore,
    LiteEnemyKind.costrutto,
    LiteEnemyKind.miruscyrus,
    LiteEnemyKind.forestDemon,
    LiteEnemyKind.granScostumato,
    LiteEnemyKind.divoramitu,
    LiteEnemyKind.demoneMinore,
    LiteEnemyKind.eliteLunare,
  ];

  static const _titles = [
    'Porta del comando',
    'Taglio nella cenere',
    'Coro delle fenditure',
    'Tribunale della Luce',
    'Argine di rame',
    'Cerchio senza centro',
    'Varco dei denti',
    'Passo dei tre ferri',
    'Corte delle sentinelle',
    'Camera dell’Ombra',
    'Ponte senza ringhiera',
    'Iride di scoria',
    'Morsa delle campane',
    'Cunicolo a due fronti',
    'Sala degli uncini',
    'Bocca della Cripta',
    'Galleria dei tre respiri',
    'Cappella del ferro vivo',
    'Bastione dell’Elité',
    'Arco di pece',
    'Forgia dei vetri ciechi',
    'Sala del Patto',
    'Chiostro dei fili spezzati',
    'Camera degli Echi',
    'Trono delle Fratture',
  ];

  String get chamberTitle => switch (thirdEncounter) {
    final room? => room.label,
    _ when inActTwo => '${realm!.label} · Visitazione $actRoom',
    _ => _titles[stage.clamp(0, _titles.length - 1)],
  };

  String get chamberGrade {
    if (thirdEncounter case final room?) {
      return room.enemies.any((kind) => kind.boss)
          ? 'Boss'
          : thirdRoom % 4 == 3
          ? 'Mini-boss'
          : 'Élite';
    }
    if (inActTwo)
      return actRoom == LiteSecondAct.actTwoRooms
          ? 'Boss'
          : actRoom == 3
          ? 'Mini-boss'
          : 'Élite';
    return switch (encounter) {
      LiteEncounter.finalBoss => 'Boss finale',
      LiteEncounter.boss => 'Boss',
      LiteEncounter.elite => 'Élite',
      LiteEncounter.ordinary => stage % 3 == 2 ? 'Mini-boss' : 'Élite',
    };
  }

  bool get hasChamber =>
      hasFloorMap && !restHub && !goblinCamp && !inSolarDungeon;
  Point<double> get chamberCenter => const Point(27.65, 11);
  bool canChamberStrike(Point<double> point) => !_blocked(point, .12);

  LiteEnemyKind _chamberKind(int floor) {
    if (solarCampaign && floor == 8) return LiteEnemyKind.custodeLunare;
    if (_encounterFor(floor) != LiteEncounter.ordinary)
      return _specialKind(floor);
    final reserved = {
      for (var i = 0; i <= lastStage; i++)
        if (_encounterFor(i) != LiteEncounter.ordinary) _specialKind(i),
      if (solarCampaign) LiteEnemyKind.custodeLunare,
    };
    final roster = _draft.where((kind) => !reserved.contains(kind)).toList();
    final slot = [
      for (var i = 0; i < floor; i++)
        if (_encounterFor(i) == LiteEncounter.ordinary &&
            !(solarCampaign && i == 8))
          i,
    ].length;
    return roster[(slot + _startingBiome.index * 2) % roster.length];
  }

  void _seatChampion(LiteEnemy enemy, {bool boost = true}) {
    final room = inThirdAct
        ? thirdRoom + 60
        : inActTwo
        ? 31 + actRoom + realm!.index * 4
        : stage;
    enemy
      ..chamberSeat = room
      ..chamberWait = 3.3
      ..chamberCycle = 0;
    final major = enemy.kind.boss;
    final upgrade =
        difficulty.index >= LiteDifficulty.difficile.index &&
        major &&
        (enemy.kind == LiteEnemyKind.veyrth ||
            enemy.kind == LiteEnemyKind.arconte ||
            enemy.kind == LiteEnemyKind.divoramituBoss ||
            enemy.kind == LiteEnemyKind.vesanybel ||
            enemy.kind == LiteEnemyKind.thalvyr ||
            enemy.kind == LiteEnemyKind.aerovyr);
    enemy.exalted = upgrade;
    if (boost && (upgrade || !major && !enemy.kind.elite)) {
      final factor = upgrade ? 1.28 : 1.34 + min(.22, stage / 110);
      enemy._maxHp *= factor;
      enemy.hp = enemy.maxHp;
    }
  }

  bool _tickChamber(LiteEnemy enemy, double elapsed) {
    final seat = enemy.chamberSeat;
    if (seat == null) return false;
    if (enemy.chamberWarning case final cue?) {
      cue.remaining -= elapsed;
      if (cue.remaining > 1e-9) return true;
      enemy.chamberWarning = null;
      enemy.chamberCycle++;
      final scale = enemy.exalted ? 1.19 : 1.0;
      final damage =
          min(32.0, 5 + .64 * enemy.kind.damage) *
          difficulty.enemyStrength *
          _floorDamageScale *
          scale;
      if (cue.pattern == LiteChamberPattern.ventaglio) {
        for (final angle in cue.angles) {
          projectiles.add(
            LiteProjectile(
              position: cue.origin,
              direction: Point(cos(angle), sin(angle)),
              speed: 11 + .55 * difficulty.index,
              remaining: 10,
              damage: damage,
              fromEnemy: true,
              magic: true,
              kind: enemy.kind == LiteEnemyKind.ombra
                  ? LiteProjectileKind.veyrthSphere
                  : LiteProjectileKind.lunarCrescent,
            ),
          );
        }
      } else {
        final axis = LiteRun._unit(cue.target - cue.origin);
        for (final point in cue.marks) {
          if (!canChamberStrike(point)) continue;
          if (_combatImpacts.length >= 32) _combatImpacts.removeAt(0);
          _combatImpacts.add(
            LiteCombatImpact(
              LiteImpactTarget.chamberStrike,
              _nextId++,
              point,
              time,
              life: cue.pattern.index.toDouble(),
              shield: enemy.exalted ? 1 : 0,
              end: point + axis,
              enemyKind: enemy.kind,
            ),
          );
          _astralImpact(
            point,
            LiteChamberWarning.hitRadius,
            damage,
            paint: false,
          );
        }
      }
      final danger = _chamberDanger(seat);
      enemy.chamberWait = max(2.6, (enemy.exalted ? 3.25 : 4.7) - danger);
      enemy.cooldown = max(.72, enemy.cooldown);
      enemy._strikePose = .22;
      return true;
    }
    enemy.chamberWait = max(0, enemy.chamberWait - elapsed);
    if (enemy.attacking || enemy.chamberWait > 0) return false;
    final aim = _enemyAimFrom(enemy.position);
    final distance = aim.distanceTo(enemy.position);
    if (distance > 10.6 || _lineBlocked(enemy.position, aim)) return false;
    if (enemy.kind == LiteEnemyKind.veyrth &&
        (!enemy.exalted ||
            !finalBossTangible ||
            _activeBeam != null ||
            enemy.cooldown < 1)) {
      return false;
    }
    final choices = LiteChamberPattern.values;
    final first = switch (enemy.kind) {
      LiteEnemyKind.luce => LiteChamberPattern.croce.index,
      LiteEnemyKind.ombra => LiteChamberPattern.morsa.index,
      _ => seat % choices.length,
    };
    final cycle = enemy.chamberCycle;
    final second = (first + 1 + (seat ~/ 5) % 4) % 5;
    final other = choices.where(
      (entry) => entry.index != first && entry.index != second,
    );
    final pattern = switch (cycle % (enemy.exalted ? 4 : 3)) {
      0 => choices[first],
      1 => choices[second],
      2 => other.elementAt((seat ~/ 20) % 3),
      _ => other.elementAt((seat ~/ 20 + 1) % 3),
    };
    final axis = LiteRun._unit(aim - enemy.position);
    final target = distance < .18 ? enemy.position + const Point(1, 0) : aim;
    final cueTarget = pattern == LiteChamberPattern.ventaglio
        ? enemy.position +
              (distance < .18 ? const Point<double>(1, 0) : axis) * 8
        : target;
    final charge = max(
      .66,
      (enemy.exalted ? .96 : 1.01) - _chamberDanger(seat) * .17,
    );
    enemy.chamberWarning = LiteChamberWarning(
      pattern,
      enemy.position,
      cueTarget,
      charge,
    );
    return true;
  }

  double _chamberDanger(int seat) =>
      min(.85, stage * .027 + max(0, seat - 60) * .036) +
      difficulty.index * .19;
}
