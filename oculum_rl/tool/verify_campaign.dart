import 'dart:math';

import 'package:oculum_rl/game/oculum_lite_run.dart';

const origin = Point<double>(0, 0);
const tick = 1 / 30;

Point<double> unit(Point<double> value) =>
    value.magnitude < .001 ? origin : value * (1 / value.magnitude);

bool open(LiteRun run, Point<double> point, [double radius = .47]) =>
    point.x > .7 &&
    point.y > .7 &&
    point.x < run.width - .7 &&
    point.y < run.height - .7 &&
    run.obstacles.every((wall) => !wall.visibleAt(point, radius));

bool sight(LiteRun run, Point<double> start, Point<double> end) {
  for (var t = .08; t < 1; t += .07) {
    final at = start + (end - start) * t;
    if (run.obstacles.any((wall) => wall.visibleAt(at, .13))) return false;
  }
  return true;
}

final _routes = <LiteRun, (int, Point<double>, List<Point<double>>)>{};

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
  if (at.x <= .7 ||
      at.y <= .7 ||
      at.x >= run.width - .7 ||
      at.y >= run.height - .7) {
    return unit(inside - at);
  }
  if (!firingLane && walkable(run, at, target)) {
    _routes.remove(run);
    return unit(target - at);
  }
  final previous = _routes[run];
  if (previous != null &&
      previous.$1 == run.stage &&
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
  _routes[run] = (run.stage, target, forward);
  return unit(forward.first - at);
}

LiteEnemy? priorityTarget(LiteRun run) {
  LiteEnemy? preferred;
  var best = double.infinity;
  for (final enemy in run.enemies) {
    if (enemy.hp <= 0) continue;
    final priority = enemy.kind == LiteEnemyKind.minionVeyrth
        ? -40
        : enemy.kind == LiteEnemyKind.veyrth && !run.finalBossTangible
        ? 60
        : 0;
    final distance = enemy.position.distanceTo(run.position) + priority;
    if (distance < best) {
      best = distance;
      preferred = enemy;
    }
  }
  return preferred;
}

String play(LiteDifficulty difficulty, int seed, LiteRealm realm) {
  final run = LiteRun(
    seed: seed,
    hero: LiteHero.evasore,
    weapon: LiteWeapon.arco,
    difficulty: difficulty,
  );
  final completed = <int>[];
  var shopping = false;
  for (var frame = 0; frame < 80 * 60 * 30 && !run.finished; frame++) {
    if (run.stageClear) {
      if (completed.isEmpty || completed.last != run.stage) {
        completed.add(run.stage);
        if (run.powerOffers.isNotEmpty) {
          run.choosePowerUp(run.powerOffers.first);
        }
        shopping = run.hp < run.maxHp * .80 && run.obser >= LiteRun.potionPrice;
        print(
          'seed=$seed stage=${run.stage} ${run.encounter.name} '
          'hp=${run.hp.ceil()} level=${run.level} time=${run.time.round()}',
        );
      }
      if (shopping) {
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
        if (run.awaitsRestHub) {
          run.enterRestHub();
          run.buyRestItem(LiteRestItem.token);
          run.buyRestItem(LiteRestItem.crosta);
          run.buyRestItem(LiteRestItem.spirale);
        } else if (run.canChooseActTwo) {
          run.enterSecondAct(realm);
        } else if (run.nextActTwoRoom) {
          run.takeActRelic(LiteActRelic.values[(run.actRoom - 1) % 3]);
          run.advanceActTwo();
        } else {
          run.advance(
            LiteBiome.values[(run.stage + 1) % LiteBiome.values.length],
          );
        }
      } else {
        run.advanceFrame(tick, move: follow(run, run.portalPosition));
      }
      continue;
    }

    final target = priorityTarget(run);
    if (target == null) {
      run.advanceFrame(tick);
      continue;
    }
    final offset = target.position - run.position;
    final distance = offset.magnitude;
    final heading = unit(offset);
    final perpendicular = Point(-heading.y, heading.x);
    final aimed = sight(run, run.position, target.position);
    Point<double> move;
    if (!aimed || distance > 8.7) {
      move = follow(run, target.position, firingLane: true);
    } else {
      move = distance < 4.5 ? heading * -1 : perpendicular;
      if (!open(run, run.position + move * .7)) move = perpendicular * -1;
      if (!open(run, run.position + move * .7)) move = origin;
    }
    final beam = run.activeBeam;
    if (beam != null) {
      final turn = Point(-beam.direction.y, beam.direction.x);
      final go = open(run, run.position + turn) ? turn : turn * -1;
      if (open(run, run.position + go)) move = go;
    }
    if (target.burrow case final track? when track.warning > 0) {
      final line = unit(track.end - track.start);
      final side = Point(-line.y, line.x);
      move = open(run, run.position + side) ? side : side * -1.0;
      if (track.warning < .30) run.special(run.position + move);
    }
    if (move == origin) move = follow(run, const Point(16, 11));
    if (run.projectiles.any(
          (item) =>
              item.fromEnemy && item.position.distanceTo(run.position) < 1.8,
        ) ||
        target.attacking && distance < 3) {
      run.special(run.position + move);
    }
    if (run.arrows == 0) {
      run.beginReload();
    } else if (aimed && distance < 9.85) {
      run.attack(target.position);
    }
    run.advanceFrame(tick, move: move);
  }
  if (run.victorious) completed.add(LiteRun.finalStage);
  final summary =
      'seed=$seed ${difficulty.name}: won=${run.victorious} '
      'stage=${run.stage} act2=${realm.name} completed=${completed.join(",")}';
  if (!run.victorious ||
      completed.length != LiteRun.finalStage + 1 ||
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

void main() {
  print(play(LiteDifficulty.moltoFacile, 20261123, LiteRealm.caramella));
  print(play(LiteDifficulty.medio, 20261124, LiteRealm.inferno));
}
