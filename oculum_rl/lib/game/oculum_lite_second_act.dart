part of 'oculum_lite_run.dart';

enum LiteRealm {
  inferno('Inferno', 'Quattro stirpi infernali. Spezza il patto del Diavolo.'),
  caramella(
    'Regno Caramella',
    'Segui gli avvallamenti. Divoramitù caccia sotto i savoiardi.',
  ),
  postea(
    'Postea',
    'Linea di montaggio runica. Droni e automi coprono angoli diversi.',
  );

  const LiteRealm(this.label, this.description);
  final String label, description;
}

enum LiteActRelic {
  fendente('Fendente', '+4% Danni. +3% se tocca Iride.'),
  iride('Iride', '+0,22 Oculum/s. +0,18 se tocca Fendente.'),
  custodia('Custodia', '−5% Danni subiti. −3% se tocca Iride.');

  const LiteActRelic(this.label, this.description);
  final String label, description;
}

class LiteBurrow {
  double delay = 1.25;
  double warning = 0;
  double leap = 0;
  Point<double> start = const Point(0, 0);
  Point<double> end = const Point(0, 0);
  final _hit = <int>{};
  bool get exposed => leap > 0;
  double get progress => (leap / .76).clamp(0, 1);
  Map<String, Object> get frame => {
    'delay': delay,
    'warning': warning,
    'leap': leap,
    'start': _savePoint(start),
    'end': _savePoint(end),
    'hit': _hit.toList(),
  };
  void restore(Object? raw) {
    if (raw is! Map) return;
    delay = _num(raw['delay']).clamp(0, 4);
    warning = _num(raw['warning']).clamp(0, 1);
    leap = _num(raw['leap']).clamp(0, .76);
    start = _point(raw['start']);
    end = _point(raw['end']);
    _hit.addAll(_list(raw['hit']).whereType<int>().take(12));
  }
}

extension LiteSecondAct on LiteRun {
  static const actTwoRooms = 4;
  bool get canChooseActTwo =>
      stage == LiteRun.secondActEntranceFloor &&
      restHub &&
      realm == null &&
      !inSolarDungeon &&
      !finished &&
      !hostDown &&
      hasPortalNearby;
  bool get inActTwo => realm != null;
  bool get nextActTwoRoom => inActTwo && stageClear && actRoom < actTwoRooms;
  bool get canClaimActRelic =>
      inActTwo &&
      stageClear &&
      actRoom < actTwoRooms &&
      _actRelicClaims < actRoom &&
      actRelics.length < 3;

  bool takeActRelic(LiteActRelic relic) {
    if (!canClaimActRelic) return false;
    actRelics.add(relic);
    _actRelicClaims = actRoom;
    return true;
  }

  bool moveActRelic(int index, int direction) {
    final next = index + direction;
    if (!stageClear ||
        direction.abs() != 1 ||
        index < 0 ||
        index >= actRelics.length ||
        next < 0 ||
        next >= actRelics.length) {
      return false;
    }
    final relic = actRelics.removeAt(index);
    actRelics.insert(next, relic);
    return true;
  }

  double _relicEffect(
    LiteActRelic type,
    LiteActRelic link,
    double base,
    double extra,
  ) {
    var total = 0.0;
    for (var index = 0; index < actRelics.length; index++) {
      if (actRelics[index] != type) continue;
      total += base;
      if ((index > 0 && actRelics[index - 1] == link) ||
          (index + 1 < actRelics.length && actRelics[index + 1] == link)) {
        total += extra;
      }
    }
    return total;
  }

  double get relicDamage =>
      _relicEffect(LiteActRelic.fendente, LiteActRelic.iride, .04, .03);
  double get relicMana =>
      _relicEffect(LiteActRelic.iride, LiteActRelic.fendente, .22, .18);
  double get relicProtection =>
      _relicEffect(LiteActRelic.custodia, LiteActRelic.iride, .05, .03);

  void _tickRelicMana(double elapsed, [LiteCoopFighter? fighter]) {
    if (actRelics.isEmpty || stageClear) return;
    final income = relicMana * elapsed;
    if (fighter == null) {
      oculum = min(maxOculum, oculum + income);
    } else {
      fighter.oculum = min(fighter.maxOculum, fighter.oculum + income);
    }
  }

  bool enterSecondAct(LiteRealm area) {
    if (!canChooseActTwo) return false;
    realm = area;
    actRoom = 1;
    _openActRoom();
    return true;
  }

  bool advanceActTwo() {
    if (!nextActTwoRoom || !hasPortalNearby || hostDown) return false;
    actRoom++;
    _openActRoom();
    return true;
  }

  void _openActRoom() {
    _arenaEventStart = time;
    _consumeMealForVisit();
    _dismissRoomWolves();
    _powerOffers.clear();
    stageClear = restHub = false;
    arenaTrial = null;
    loot.clear();
    projectiles.clear();
    groundShots.clear();
    _combatImpacts.clear();
    _burstTraces.clear();
    position = LiteRun._spawn;
    for (var i = 0; i < coopFighters.length; i++) {
      coopFighters[i].position = _coopSpawn(i);
    }
    for (final clone in clones) {
      clone.position = position + const Point(0, 1.55);
    }
    final shift = actRoom.isOdd ? 0.0 : 3.25;
    obstacles
      ..clear()
      ..addAll(switch (realm!) {
        LiteRealm.inferno => [
          LiteObstacle(9, 3.0 + shift, 2.5, 2.3, breakable: true),
          LiteObstacle(13.3, 14.2 - shift, 2.0, 3.5),
          LiteObstacle(21.0 + shift, 7.4, 2.3, 2.1, breakable: true),
        ],
        LiteRealm.caramella => [
          LiteObstacle(11.5, 6.5 + shift, 2.45, 1.8, breakable: true),
          LiteObstacle(14.4 + shift, 14.8, 3.6, 1.9),
          LiteObstacle(23.5, 4.2 + shift, 1.65, 3.2, breakable: true),
        ],
        LiteRealm.postea => [
          LiteObstacle(10.0, 3.4, 3.1, 3.8),
          LiteObstacle(10.0, 15.7, 3.1, 3.8),
          LiteObstacle(16.0 + shift, 7.4, 1.9, 1.85, breakable: true),
          LiteObstacle(22.0, 13.2 - shift, 2.45, 1.8, breakable: true),
        ],
      });
    _openFloorMap();
    _placeSecretRoom();
    final enemies = switch (realm!) {
      LiteRealm.inferno => switch (actRoom) {
        1 => [
          LiteEnemyKind.demoneMinore,
          LiteEnemyKind.demoneMinore,
          LiteEnemyKind.demoneIntermedio,
        ],
        2 => [
          LiteEnemyKind.demoneIntermedio,
          LiteEnemyKind.demoneMinore,
          LiteEnemyKind.demoneIntermedio,
          LiteEnemyKind.demoneMinore,
        ],
        3 => [
          LiteEnemyKind.demoneMaggiore,
          LiteEnemyKind.demoneMaggiore,
          LiteEnemyKind.demoneIntermedio,
        ],
        _ => [
          LiteEnemyKind.diavolo,
          LiteEnemyKind.demoneIntermedio,
          LiteEnemyKind.demoneMinore,
        ],
      },
      LiteRealm.caramella => switch (actRoom) {
        1 => [
          LiteEnemyKind.divoramitu,
          LiteEnemyKind.slime,
          LiteEnemyKind.slime,
        ],
        2 => [
          LiteEnemyKind.divoramitu,
          LiteEnemyKind.divoramitu,
          LiteEnemyKind.slime,
        ],
        3 => [
          LiteEnemyKind.divoramitu,
          LiteEnemyKind.divoramitu,
          LiteEnemyKind.orbryx,
        ],
        _ => [
          LiteEnemyKind.divoramituBoss,
          LiteEnemyKind.slime,
          LiteEnemyKind.slime,
        ],
      },
      LiteRealm.postea => switch (actRoom) {
        1 => [
          LiteEnemyKind.dronePostea,
          LiteEnemyKind.dronePostea,
          LiteEnemyKind.ragnoSaldatore,
        ],
        2 => [
          LiteEnemyKind.ragnoSaldatore,
          LiteEnemyKind.ragnoSaldatore,
          LiteEnemyKind.dronePostea,
        ],
        3 => [
          LiteEnemyKind.miruscyrus,
          LiteEnemyKind.dronePostea,
          LiteEnemyKind.ragnoSaldatore,
        ],
        _ => [
          LiteEnemyKind.miruscyrus,
          LiteEnemyKind.miruscyrus,
          LiteEnemyKind.dronePostea,
        ],
      },
    };
    quests
      ..clear()
      ..addAll([
        LiteQuest(
          'ii:${realm!.name}:$actRoom:ondata',
          'Supera la visitazione',
          enemies.length,
          4,
        ),
        LiteQuest(
          'ii:${realm!.name}:$actRoom:bottino',
          'Raccogli il bottino',
          2,
          6,
        ),
        LiteQuest(
          'ii:${realm!.name}:$actRoom:conquista',
          'Conquista la sala',
          1,
          0,
        ),
      ]);
    for (var i = 0; i < enemies.length; i++) {
      final kind = enemies[i];
      final x = kind.boss || kind.elite ? 25.5 : 17.7 + (i.isEven ? 0 : 3.4);
      final y = kind.boss ? 11.0 : 4.6 + i * 4.2;
      _spawnEnemy(kind, Point(x, y)).cooldown += i * .14;
    }
    message =
        'Atto II · ${realm!.label} · Visitazione $actRoom/$actTwoRooms'
        ' · ${arenaEventKind!.label}';
  }

  bool _completeActRoom() {
    if (!inActTwo || stageClear) return false;
    final finalRoom = actRoom == actTwoRooms;
    _progressQuest(2);
    _offerPowers();
    _awardPartyObser(finalRoom ? 62 : 24);
    for (final (kind, unlockedAt) in [
      (LiteHero.demoneMinore, 1),
      (LiteHero.demoneIntermedio, 2),
      (LiteHero.demoneMaggiore, 3),
      (LiteHero.diavolo, 4),
    ]) {
      if (realm == LiteRealm.inferno && actRoom == unlockedAt) {
        achievements.add(LiteRun.heroUnlockKey(kind));
      }
    }
    if (finalRoom) {
      final boon = switch (realm!) {
        LiteRealm.inferno => LiteRestItem.spirale,
        LiteRealm.caramella => LiteRestItem.stufato,
        LiteRealm.postea => LiteRestItem.bastione,
      };
      void boost(LiteCoopFighter? fighter) {
        final kit = fighter?.supply ?? supply;
        final rank = boon.evolution ? min(3, kit.rank(boon) + 1) : 1;
        _grantRestItem(boon, rank, kit, fighter, min(lastStage, stage + 2));
      }

      boost(null);
      for (final fighter in coopFighters) {
        boost(fighter);
      }
      achievements.add('atto-ii-${realm!.name}');
      message = '${realm!.label} superato · 62 Obser e ${boon.label}.';
    } else {
      message = 'Visitazione completata · +24 Obser. Raggiungi il portale.';
    }
    stageClear = true;
    return true;
  }

  void _tickBurrow(LiteEnemy beast, double elapsed) {
    final state = beast.burrow!;
    beast.hitFlash = max(0, beast.hitFlash - elapsed);
    if (state.leap > 0) {
      state.leap = min(.76, state.leap + elapsed);
      beast.position = state.start + (state.end - state.start) * state.progress;
      final damage =
          beast.kind.damage *
          difficulty.enemyStrength *
          (beast.kind.boss ? 1.15 : 1.0);
      if (!invulnerable &&
          !hostDown &&
          beast.hitboxContains(position, extra: .26) &&
          state._hit.add(0)) {
        _damagePlayer(damage);
      }
      for (final ally in _damageableAllies) {
        if (ally.hp <= 0 ||
            ally is LiteCoopFighter && ally.protected ||
            !beast.hitboxContains(ally.position, extra: .28) ||
            !state._hit.add(ally.id))
          continue;
        _hitAlly(ally, damage);
      }
      if (state.leap >= .76) {
        state.leap = 0;
        state.delay = beast.kind.boss
            ? (beast.hp < beast.maxHp * .5 ? .83 : 1.35)
            : 1.9;
        _recordImpact(LiteImpactTarget.explosion, _nextId++, beast.position);
      }
      return;
    }
    if (state.warning > 0) {
      state.warning = max(0, state.warning - elapsed);
      if (state.warning == 0) state.leap = elapsed;
      return;
    }
    state.delay -= elapsed;
    if (state.delay > 0) return;
    final target = _enemyAimFrom(beast.position);
    var heading = LiteRun._unit(target - beast.position);
    if (heading.magnitude == 0) heading = const Point(1, 0);
    final rawStart = target - heading * 3.5;
    final rawEnd = target + heading * 4.1;
    Point<double> bounds(Point<double> p) =>
        Point(p.x.clamp(1, width - 1), p.y.clamp(1, height - 1));
    state
      ..start = bounds(rawStart)
      ..end = bounds(rawEnd)
      ..warning = .82
      .._hit.clear();
    beast.position = state.start;
    beast.attackTarget = state.end;
  }

  void _infernalMove(
    LiteHero character,
    Point<double> at,
    Point<double> direction,
    LiteCoopFighter? fighter,
    int grade, {
    bool open = false,
  }) {
    final owner = fighter?.id;
    switch (character) {
      case LiteHero.demoneMinore:
        _playableShadowStep(
          at,
          direction,
          fighter,
          distance: open ? 4.2 : 2.5,
          protection: .22,
        );
        _melee(
          fighter?.position ?? position,
          direction,
          LiteWeapon.guanti,
          (open ? 18 : 11) + grade * 4.0,
          sourceCloneId: owner,
          ownerCanHeal: owner == null,
          reach: 2.4,
          minDot: .15,
        );
      case LiteHero.demoneIntermedio:
        if (open) {
          _openBurst(
            at,
            3.1 + grade * .27,
            21 + 8.0 * grade,
            owner ?? 0,
            push: 2.4,
          );
        } else {
          _fissure(at, direction, 6.8, 15 + grade * 4.0, owner);
        }
      case LiteHero.demoneMaggiore:
        _playableShadowStep(
          at,
          direction,
          fighter,
          distance: open ? 5.1 : 3.2,
          protection: .26,
        );
        final arrived = fighter?.position ?? position;
        _openBurst(
          arrived,
          2.1 + grade * .3,
          (open ? 23 : 12) + grade * 5.0,
          owner ?? 0,
          push: .75,
        );
        if (open) {
          if (fighter == null) {
            oculum = min(maxOculum, oculum + 2);
          } else {
            fighter.oculum = min(fighter.maxOculum, fighter.oculum + 2);
          }
        }
      case LiteHero.diavolo:
        final branches = open ? const [-.45, -.20, 0.0, .20, .45] : const [0.0];
        for (final arc in branches) {
          _launchFireball(
            at,
            _rotate(direction, arc),
            14 + grade * 4.0,
            1,
            owner,
          );
        }
      default:
        break;
    }
  }
}
