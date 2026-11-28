import 'dart:math';

import 'package:oculum_rl/game/oculum_lite_run.dart';

const origin = Point<double>(0, 0);
const tick = 1 / 60;

Point<double> unit(Point<double> value) =>
    value.magnitude < .001 ? origin : value * (1 / value.magnitude);

bool open(LiteRun run, Point<double> point, [double radius = .47]) =>
    point.x > .42 &&
    point.y > .42 &&
    point.x < run.width - .42 &&
    point.y < run.height - .42 &&
    run.obstacles.every((wall) => !wall.visibleAt(point, radius));

bool sight(LiteRun run, Point<double> start, Point<double> end) {
  final delta = end - start;
  final sheltered = run.inExplorationAtrium(start);
  final slices = max(1, (delta.magnitude / .12).ceil());
  for (var index = 1; index <= slices; index++) {
    final at = start + delta * (index / slices);
    if (run.inExplorationAtrium(at) != sheltered ||
        run.obstacles.any((wall) => wall.visibleAt(at, .16))) {
      return false;
    }
  }
  return true;
}

Point<double> avoidAerovyr(
  LiteRun run,
  LiteStormWarning cue,
  Point<double> preferred,
) {
  if (cue.pattern == LiteStormPattern.corona &&
      run.position.distanceTo(cue.target) < cue.inner - .42)
    return origin;

  double clearance(Point<double> at) => switch (cue.pattern) {
    LiteStormPattern.corona => max(
      cue.inner - at.distanceTo(cue.target),
      at.distanceTo(cue.target) - cue.outer,
    ),
    LiteStormPattern.croce =>
      cue.marks.map((mark) => at.distanceTo(mark) - cue.radius).reduce(min),
    LiteStormPattern.ventaglio =>
      cue.spread
          .map((arc) {
            final delta = at - cue.origin;
            final angle = atan2(cue.direction.y, cue.direction.x);
            final axis = Point(cos(angle + arc), sin(angle + arc));
            final projection = max(0.0, delta.x * axis.x + delta.y * axis.y);
            return delta.distanceTo(axis * projection) - .68;
          })
          .reduce(min),
  };

  var optimum = -double.infinity;
  var movement = preferred;
  for (var seat = 0; seat < 17; seat++) {
    final axis = seat == 16
        ? origin
        : Point(cos(seat * pi / 8), sin(seat * pi / 8));
    final at = run.position + axis * 1.65;
    if (!walkable(run, run.position, at)) continue;
    final wall = min(min(at.x, run.width - at.x), min(at.y, run.height - at.y));
    final score =
        clearance(at) +
        min(3.0, wall) * .24 +
        (preferred.x * axis.x + preferred.y * axis.y) * .20;
    if (score <= optimum) continue;
    optimum = score;
    movement = axis;
  }
  if (cue.remaining < .19 &&
      clearance(run.position) < .38 &&
      movement != origin) {
    run.special(run.position + movement);
  }
  return movement;
}

Point<double> avoidGroundAttacks(LiteRun run, Point<double> preferred) {
  final hazards = [
    for (final enemy in run.enemies)
      if (enemy.hp > 0 && enemy.windup > 0) ...enemy.thirdGroundImpacts(),
  ];
  if (hazards.isEmpty) return preferred;
  double clearance(Point<double> point) => hazards
      .map((hit) => hit.center.distanceTo(point) - hit.radius)
      .reduce(min);

  if (clearance(run.position + preferred * 1.05) > .5 &&
      clearance(run.position) > .15) {
    return preferred;
  }
  var best = -double.infinity;
  var movement = preferred;
  for (var index = 0; index < 16; index++) {
    final angle = index * pi / 8;
    final step = Point(cos(angle), sin(angle));
    final next = run.position + step * 1.65;
    if (!walkable(run, run.position, next)) continue;
    final score =
        clearance(next) + .30 * (step.x * preferred.x + step.y * preferred.y);
    if (score <= best) continue;
    best = score;
    movement = step;
  }
  if (clearance(run.position) < .4) run.special(run.position + movement);
  return movement;
}

final _routes = <LiteRun, (String, Point<double>, List<Point<double>>)>{};

bool walkable(LiteRun run, Point<double> start, Point<double> finish) {
  final delta = finish - start;
  final slices = max(1, (delta.magnitude / .11).ceil());
  for (var i = 1; i <= slices; i++) {
    if (!open(run, start + delta * (i / slices), .42)) return false;
  }
  return true;
}

Point<double> follow(
  LiteRun run,
  Point<double> target, {
  bool firingLane = false,
}) {
  final at = run.position;
  final inside = Point<double>(
    at.x.clamp(.9, run.width - .9),
    at.y.clamp(.9, run.height - .9),
  );
  if (at.x <= .42 ||
      at.y <= .42 ||
      at.x >= run.width - .42 ||
      at.y >= run.height - .42) {
    return unit(inside - at);
  }
  if (!firingLane && walkable(run, at, target)) {
    _routes.remove(run);
    return unit(target - at);
  }
  final previous = _routes[run];
  if (previous != null &&
      previous.$1 == run.inputArena &&
      previous.$2.distanceTo(target) <= .75) {
    final path = previous.$3;
    while (path.isNotEmpty && at.distanceTo(path.first) < .19) {
      path.removeAt(0);
    }
    if (path.isNotEmpty && walkable(run, at, path.first)) {
      return unit(path.first - at);
    }
  }
  Point<double> world(Point<int> p) => Point(p.x * .5, p.y * .5);
  final start = Point((at.x * 2).round(), (at.y * 2).round());
  final parents = <Point<int>, Point<int>?>{};
  final queue = <Point<int>>[];
  for (var y = -1; y <= 1; y++) {
    for (var x = -1; x <= 1; x++) {
      final next = start + Point(x, y);
      if (open(run, world(next), .45) && walkable(run, at, world(next))) {
        queue.add(next);
        parents[next] = null;
      }
    }
  }
  Point<int>? best;
  var bestDistance = double.infinity;
  for (var i = 0; i < queue.length; i++) {
    final from = queue[i];
    final here = world(from);
    final distance = here.distanceTo(target);
    // An enemy's exact location can be too tight for the archer. Stop at
    // a reachable cell with room to shoot, even when it is farther away.
    if (firingLane && distance <= 8.8 && sight(run, here, target)) {
      best = from;
      break;
    }
    if (distance < bestDistance) {
      best = from;
      bestDistance = distance;
      if (!firingLane && distance < .51) break;
    }
    for (final delta in [
      const Point(1, 0),
      const Point(-1, 0),
      const Point(0, 1),
      const Point(0, -1),
      const Point(1, 1),
      const Point(-1, 1),
      const Point(1, -1),
      const Point(-1, -1),
    ]) {
      final next = from + delta;
      if (parents.containsKey(next) ||
          !open(run, world(next), .45) ||
          !walkable(run, here, world(next)))
        continue;
      parents[next] = from;
      queue.add(next);
    }
  }
  final path = <Point<double>>[];
  for (var cell = best; cell != null; cell = parents[cell]) {
    path.add(world(cell));
  }
  final forward = path.reversed.toList();
  while (forward.length > 1 && walkable(run, at, forward[1])) {
    forward.removeAt(0);
  }
  if (forward.isEmpty) return origin;
  _routes[run] = (run.inputArena, target, forward);
  return unit(forward.first - at);
}

LiteEnemy? priorityTarget(LiteRun run, {LiteEnemy? locked}) {
  LiteEnemy? preferred;
  var best = double.infinity;
  for (final enemy in run.enemies) {
    if (enemy.hp <= 0) continue;
    final priority = enemy.kind == LiteEnemyKind.minionVeyrth
        ? -40
        : enemy.kind == LiteEnemyKind.veyrth && !run.finalBossTangible
        ? 60
        : 0;
    // Keep two nearly equidistant enemies from alternating the planned route.
    final distance =
        enemy.position.distanceTo(run.position) +
        priority -
        (identical(enemy, locked) ? 1 : 0);
    if (distance < best) {
      best = distance;
      preferred = enemy;
    }
  }
  return preferred;
}

LitePowerUp pickPower(Iterable<LitePowerUp> options) {
  for (final priority in const [
    LitePowerUp.lama,
    LitePowerUp.cuore,
    LitePowerUp.pelleRunica,
    LitePowerUp.occhioLungo,
    LitePowerUp.passo,
  ]) {
    if (options.contains(priority)) return priority;
  }
  return options.first;
}

String play(
  LiteDifficulty difficulty,
  int seed,
  LiteRealm realm, {
  bool exploration = false,
}) {
  final run = LiteRun(
    seed: seed,
    hero: LiteHero.evasore,
    weapon: LiteWeapon.arco,
    difficulty: difficulty,
    explorationRoutes: exploration,
    biome: exploration ? LiteBiome.startingZone(seed) : LiteBiome.campo,
  );
  final completed = <int>[];
  final thirdCompleted = <int>[];
  final hubs = <int>[];
  final phases = <int>{};
  final finalAttacks = <LiteArchonAttack>{};
  final hardest = difficulty == LiteDifficulty.oculum;
  var shopping = false;
  var soughtExplorationSupply = false;
  LiteEnemy? locked;
  for (var frame = 0; frame < 80 * 60 * 60; frame++) {
    if (run.canEnterThirdAct) {
      completed.add(run.stage);
      if (!run.enterThirdAct())
        throw StateError('Ingresso Atto III non riuscito');
    }
    if (run.finished) break;
    if (run.stageClear) {
      if (run.inThirdAct && !thirdCompleted.contains(run.thirdRoom)) {
        thirdCompleted.add(run.thirdRoom);
        if (run.powerOffers.isNotEmpty) {
          final defensive = run.powerOffers
              .where(
                (power) =>
                    power == LitePowerUp.cuore ||
                    power == LitePowerUp.pelleRunica,
              )
              .firstOrNull;
          run.choosePowerUp(
            hardest
                ? pickPower(run.powerOffers)
                : defensive ?? run.powerOffers.first,
          );
        }
        final offers = run.powerWellOffers;
        if (offers.isNotEmpty && !hardest) {
          run.claimPowerWell(offers.first, arena: run.inputArena);
        }
        print(
          'seed=$seed attoIII=${run.thirdRoom} hp=${run.hp.ceil()} livello=${run.level}',
        );
      }
      if (!run.inThirdAct &&
          (completed.isEmpty || completed.last != run.stage)) {
        completed.add(run.stage);
        if (run.powerOffers.isNotEmpty) {
          run.choosePowerUp(
            hardest ? pickPower(run.powerOffers) : run.powerOffers.first,
          );
        }
        shopping = run.hp < run.maxHp * .80 && run.obser >= LiteRun.potionPrice;
        print(
          'seed=$seed stage=${run.stage} ${run.encounter.name} '
          'hp=${run.hp.ceil()} level=${run.level} time=${run.time.round()}',
        );
      }
      if (hardest && run.canClaimPowerWell && run.powerWellOffers.isNotEmpty) {
        if (!run.powerWellAt(run.position)) {
          final move = follow(run, run.powerWellPosition);
          if (move != origin) {
            run.advanceFrame(tick, move: move);
            continue;
          }
        } else {
          run.claimPowerWell(
            pickPower(run.powerWellOffers),
            arena: run.inputArena,
          );
        }
      }
      if (run.hasRest && !run.restUsed && run.hp < run.maxHp * .90) {
        if (run.canRest) {
          run.useRest();
        } else {
          run.advanceFrame(tick, move: follow(run, run.restPosition));
        }
        continue;
      }
      if (shopping && !run.usesSubArena) {
        if (run.canOpenShop) {
          run.interact();
          while (run.buyPotion()) {}
          run.closeShop();
          shopping = false;
        } else {
          run.advanceFrame(tick, move: follow(run, run.shopPosition));
          continue;
        }
      }
      if (run.hasPortalNearby) {
        if (run.inThirdAct) {
          if (!run.advanceThirdAct())
            throw StateError('Portale Atto III non accessibile');
        } else if (run.awaitsRestHub) {
          if (!run.enterRestHub())
            throw StateError('Ristoro non accessibile al piano ${run.stage}');
          hubs.add(run.stage);
          run.buyRestItem(LiteRestItem.token);
          if (hardest) {
            run.buyRestItem(LiteRestItem.artPlasma);
            run.buyRestItem(LiteRestItem.bastione);
          }
          run.buyRestItem(LiteRestItem.crosta);
          run.buyRestItem(LiteRestItem.spirale);
          if (difficulty == LiteDifficulty.oculum) {
            final reserve = LiteRun.potionPrice * 2;
            while (run.obser >= reserve + run.restPrice(LiteRestItem.tempra) &&
                run.buyRestItem(LiteRestItem.tempra)) {}
          } else {
            run.buyRestItem(LiteRestItem.tempra);
          }
        } else if (run.canChooseActTwo) {
          run.enterSecondAct(realm);
        } else if (run.nextActTwoRoom) {
          run.takeActRelic(LiteActRelic.values[(run.actRoom - 1) % 3]);
          run.advanceActTwo();
        } else {
          run.advance(
            exploration
                ? run.routeBiomes.first
                : LiteBiome.values[(run.stage + 1) % LiteBiome.values.length],
          );
        }
      } else {
        run.advanceFrame(tick, move: follow(run, run.portalPosition));
      }
      continue;
    }

    if (exploration && run.stage == 0 && !soughtExplorationSupply) {
      final supply = run.explorationLandmarks.firstWhere(
        (site) => site.site == LiteFloorSite.encounter,
      );
      if (run.position.distanceTo(supply.position) > .65) {
        run.advanceFrame(tick, move: follow(run, supply.position));
        continue;
      }
      soughtExplorationSupply = true;
    }
    final target = priorityTarget(run, locked: locked);
    locked = target;
    if (target == null) {
      run.advanceFrame(tick);
      continue;
    }
    if (target.kind == LiteEnemyKind.arconte) {
      phases.add(target.archonPhase);
      if (target.archonAttack case final attack?) finalAttacks.add(attack);
    }
    if (run.inExplorationAtrium(run.position)) {
      final north = target.position.y <= 11;
      final outside = Point<double>(16.25, north ? 5.65 : 16.25);
      run.advanceFrame(tick, move: follow(run, outside));
      continue;
    }
    final aimingPoint = target.burrow?.exposed == true
        ? target.closestHitboxPoint(run.position)
        : target.position;
    final offset = aimingPoint - run.position;
    final distance = offset.magnitude;
    final heading = unit(offset);
    final perpendicular = Point(-heading.y, heading.x);
    final aimed = sight(run, run.position, aimingPoint);
    Point<double> move;
    if (!aimed || distance > 8.7) {
      move = follow(run, aimingPoint, firingLane: true);
    } else {
      // Strafe along the enemy rather than backing into the outer wall.
      final keepDistance = target.kind.boss ? 6.3 : 4.5;
      move = distance < keepDistance
          ? unit(perpendicular + heading * -.8)
          : perpendicular;
      if (!open(run, run.position + move * .7)) move = perpendicular * -1;
      if (!open(run, run.position + move * .7)) move = origin;
    }
    if (target.chamberWarning case final cue? when cue.marks.isNotEmpty) {
      final radius = LiteChamberWarning.hitRadius;
      double separation(Point<double> candidate) =>
          cue.marks.map((mark) => candidate.distanceTo(mark)).reduce(min);
      if (separation(run.position + move) < radius + .56) {
        var best = -double.infinity;
        for (var option = 0; option < 12; option++) {
          final angle = option * pi / 6;
          final direction = Point(cos(angle), sin(angle));
          final safe = run.position + direction * 1.32;
          if (!walkable(run, run.position, safe)) continue;
          final value = separation(safe);
          if (value <= best) continue;
          best = value;
          move = direction;
        }
      }
    }
    final beam = run.activeBeam;
    if (beam != null) {
      final turn = Point(-beam.direction.y, beam.direction.x);
      final go = open(run, run.position + turn) ? turn : turn * -1;
      if (open(run, run.position + go)) move = go;
    }
    if (target.burrow case final track?
        when track.warning > 0 || track.exposed) {
      final line = unit(track.end - track.start);
      final start = track.start - line * target.hitboxHalfLength;
      final length =
          track.end.distanceTo(track.start) + 2 * target.hitboxHalfLength;
      double clearance(Point<double> point) {
        final offset = point - start;
        final projected = (offset.x * line.x + offset.y * line.y).clamp(
          0.0,
          length,
        );
        return offset.distanceTo(line * projected) - target.hitboxRadius;
      }

      if (clearance(run.position) < .70 ||
          clearance(run.position + move * 1.2) < .70) {
        var best = -double.infinity;
        for (var option = 0; option < 16; option++) {
          final angle = option * pi / 8;
          final direction = Point(cos(angle), sin(angle));
          for (final distance in [1.2, 2.6]) {
            final point = run.position + direction * distance;
            if (!walkable(run, run.position, point)) continue;
            final value = clearance(point);
            if (value <= best) continue;
            best = value;
            move = direction;
          }
        }
      }
      if (track.warning < .19 && clearance(run.position) < .28) {
        run.special(run.position + move);
      }
    }
    if (hardest && run.inThirdAct) move = avoidGroundAttacks(run, move);
    final storm = run.stormWarning(target);
    if (storm != null) {
      move = avoidAerovyr(run, storm, move);
    } else if (move == origin) {
      move = follow(run, const Point(16, 11));
    }
    if (run.projectiles.any(
          (item) =>
              item.fromEnemy && item.position.distanceTo(run.position) < 1.8,
        ) ||
        target.attacking && distance < 3) {
      run.special(run.position + move);
    }
    if (hardest && aimed && distance < 9) {
      if (target.kind.boss || run.hp < run.maxHp * .40) {
        run.useOpen(target.position);
      }
      run.useLearnedArt(target.position);
    }
    if (run.arrows == 0) {
      run.beginReload();
    } else if (aimed && distance < 9.85) {
      run.attack(aimingPoint);
    }
    run.advanceFrame(tick, move: move);
  }
  if (run.victorious && run.inThirdAct) thirdCompleted.add(run.thirdRoom);
  final summary =
      'seed=$seed ${difficulty.name}: won=${run.victorious} '
      'stage=${run.stage} act2=${realm.name} completed=${completed.join(",")} hubs=${hubs.join(",")} '
      'archonPhases=${phases.join(",")} attacks=${finalAttacks.map((a) => a.name).join(",")} '
      'attoIII=${thirdCompleted.join(",")}';
  if (!run.victorious ||
      completed.length != LiteRun.campaignRooms ||
      thirdCompleted.length != LiteThirdAct.rooms.length ||
      !run.achievements.contains('atto-iii-completato') ||
      phases.length != 3 ||
      finalAttacks.length != LiteArchonAttack.values.length ||
      hubs.join(',') != '5,11,17,23' ||
      !run.achievements.contains('atto-ii-${realm.name}')) {
    for (final enemy in run.enemies.where((enemy) => enemy.hp > 0)) {
      print(
        '${enemy.kind.name} at ${enemy.position}, '
        'HP=${enemy.hp}, clear aim=${sight(run, run.position, enemy.position)}',
      );
    }
    print(
      "position=${run.position} port=${run.portalPosition} available=${run.hasPortalNearby} shop=${run.shopOpen} dead=${run.dead} clock=${run.time} walls=${run.obstacles.map((wall) => [wall.left, wall.top, wall.width, wall.height]).toList()}",
    );
    throw StateError(summary);
  }
  return summary;
}

void main(List<String> args) {
  if (args.isNotEmpty) {
    if (args.length < 3 ||
        args.length > 4 ||
        (args.length == 4 && args[3] != '--esplorazione')) {
      throw ArgumentError(
        'Uso: verify_campaign.dart <difficolta> <seed> <reame> [--esplorazione]',
      );
    }
    print(
      play(
        LiteDifficulty.values.byName(args[0]),
        int.parse(args[1]),
        LiteRealm.values.byName(args[2]),
        exploration: args.length == 4,
      ),
    );
    return;
  }
  print(play(LiteDifficulty.moltoFacile, 20261123, LiteRealm.caramella));
  print(play(LiteDifficulty.medio, 20261124, LiteRealm.inferno));
  print(play(LiteDifficulty.medio, 20261125, LiteRealm.postea));
}
