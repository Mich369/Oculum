import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';

const _right = Point<double>(1, 0);
const _still = Point<double>(0, 0);

LiteRun _run({bool guest = false}) =>
    LiteRun(
        seed: 187,
        hero: guest ? LiteHero.evasore : LiteHero.assassino,
        weapon: LiteWeapon.arco,
        playerCount: guest ? 2 : 1,
      )
      ..enemies.clear()
      ..fauna.clear()
      ..obstacles.clear()
      ..position = const Point(8, 9);

LiteEnemy _target(LiteRun run, Point<double> at, int id) {
  final enemy = LiteEnemy(id, LiteEnemyKind.slime, at, 180)..stunned = 90;
  run.enemies.add(enemy);
  return enemy;
}

void _step(LiteRun run, int frames) {
  for (var index = 0; index < frames; index++) {
    run.step(.10);
  }
}

void _shot(LiteRun run, Point<double> at) {
  run.projectiles.add(
    LiteProjectile(
      position: at - _right * 2.2,
      direction: _right,
      remaining: 5.5,
      speed: 15,
      damage: 10,
      fromEnemy: true,
    ),
  );
}

bool _partyControls(
  LiteRun run, {
  bool attack = false,
  bool special = false,
  bool open = false,
}) {
  final fighter = run.coopFighter('assassin')!;
  return run.setCoopControls(
    fighter.account,
    _still,
    fighter.position + _right,
    attack: attack,
    dodge: special,
    open: open,
  );
}

LiteCoopFighter _guest(LiteRun run) {
  expect(
    run.addCoopFighter(
      'assassin',
      'Assassino',
      LiteHero.assassino,
      LiteWeapon.arco,
    ),
    isTrue,
  );
  return run.coopFighter('assassin')!..position = const Point(11, 9);
}

void main() {
  test(
    'Assassino starts with half Life and keeps paired blades when reloaded',
    () {
      final solo = _run();
      expect(solo.maxHp, 50);
      expect(solo.hp, solo.maxHp);
      expect(solo.weapon, LiteWeapon.doppieLame);
      expect(solo.weaponDamage, closeTo(19.2, .001));
      final saved = solo.toJson()..['weapon'] = 'arco';
      final loaded = LiteRun.fromJson(saved);
      expect(loaded.weapon, LiteWeapon.doppieLame);
      expect(loaded.maxHp, 50);
      expect(loaded.hp, 50);

      final coop = _run(guest: true);
      final guest = _guest(coop);
      expect(guest.hp, guest.maxHp);
      expect(guest.maxHp, 50);
      expect(guest.weapon, LiteWeapon.doppieLame);

      final shared = coop.toJson(includeEffects: true);
      final participants = shared['fighters'] as List;
      (participants.single as Map)['weapon'] = 'arco';
      final rejoined = LiteRun.fromJson(shared).coopFighter(guest.account)!;
      expect(rejoined.weapon, LiteWeapon.doppieLame);
      expect(rejoined.maxHp, 50);
      expect(rejoined.hp, 50);
    },
  );

  test(
    'solo restores Life only after the recovery delay and preserves it on save',
    () {
      final run = _run();
      _shot(run, run.position);
      run.step(.20);
      final wounded = run.hp;
      expect(wounded, lessThan(run.maxHp));
      _step(run, 34);
      expect(run.hp, wounded);
      final saved = LiteRun.fromJson(run.toJson());
      _step(saved, 3);
      expect(saved.hp, wounded);
      _step(saved, 9);
      expect(saved.hp, greaterThan(wounded));
      expect(saved.hp, lessThanOrEqualTo(saved.maxHp));
    },
  );

  test('guest receives the same regeneration and two-hit blade rules', () {
    final run = _run(guest: true);
    final guest = _guest(run)..cooldown = 0;
    final front = _target(run, guest.position + _right * 1.7, 1801);
    final back = _target(run, guest.position - _right * .8, 1802);
    expect(_partyControls(run, attack: true), isTrue);
    run.step(.03);
    expect(front.hp, lessThan(180));
    final initial = front.hp;
    expect(back.hp, 180);
    run.step(.15);
    expect(front.hp, lessThan(initial));
    expect(back.hp, lessThan(180));

    _shot(run, guest.position);
    run.step(.20);
    final wounded = guest.hp;
    expect(wounded, lessThan(guest.maxHp));
    for (var index = 0; index < 45; index++) {
      expect(_partyControls(run), isTrue);
      run.step(.10);
      if (index == 30) expect(guest.hp, wounded);
    }
    expect(guest.hp, greaterThan(wounded));
  });

  test(
    'Open hits forward and behind, binds both decoys to their owner and scene',
    () {
      final run = _run();
      final start = run.position;
      final front = _target(run, start + _right * 2.65, 1901);
      final back = _target(run, start - _right * 2.65, 1902);
      final distant = _target(run, start + _right * 7.5, 1903);
      expect(run.useOpen(start + _right), isTrue);
      expect(front.hp, lessThan(110));
      expect(back.hp, lessThan(110));
      expect(distant.hp, 180);
      expect(run.useOpen(start + _right), isFalse);
      final decoys = run.clones.where((clone) => clone.assassinDecoy).toList();
      expect(decoys, hasLength(2));
      expect(
        decoys.every(
          (clone) =>
              !clone.canBeRevived && clone.ownerId == 0 && clone.hp == 10,
        ),
        isTrue,
      );

      final frame = LiteRun.fromJson(run.toJson(includeEffects: true));
      expect(frame.clones.where((clone) => clone.assassinDecoy), hasLength(2));
      final cue = frame.combatImpacts.singleWhere(
        (event) => event.target == LiteImpactTarget.assassinSlash,
      );
      expect(cue.end, isNotNull);
      expect(cue.shield, 1);
      final threatened = decoys.first;
      final before = threatened.position;
      _shot(run, before);
      run.step(.21);
      expect((threatened.position.y - before.y).abs(), greaterThan(.2));
      expect(threatened.hp, 10);

      run.enemies.clear();
      run.step(.05);
      // The first clear seats the champion for the starting floor.
      run.enemies.clear();
      run.step(.05);
      run.position = run.portalPosition;
      expect(run.advance(), isTrue);
      expect(run.clones.where((clone) => clone.assassinDecoy), isEmpty);
    },
  );

  test('the forge accepts Assassin blades as primary and keeps sidearms', () {
    final host = _run()
      ..restHub = true
      ..obser = 500;
    host.ownedWeapons.add(LiteWeapon.chakram);
    expect(host.equipFromForge(LiteWeapon.chakram), isFalse);
    expect(
      host.fuseWeapons(LiteWeapon.chakram, LiteWeapon.doppieLame),
      isFalse,
    );
    expect(host.fuseWeapons(LiteWeapon.doppieLame, LiteWeapon.chakram), isTrue);
    expect(host.weapon, LiteWeapon.doppieLame);
    expect(host.fusedWeapon(), LiteWeapon.chakram);

    final coop = _run(guest: true);
    final guest = _guest(coop)..obser = 500;
    coop.restHub = true;
    guest.ownedWeapons.add(LiteWeapon.chakram);
    expect(coop.equipFromForge(LiteWeapon.chakram, guest), isFalse);
    expect(
      coop.fuseWeapons(LiteWeapon.doppieLame, LiteWeapon.chakram, guest),
      isTrue,
    );
    expect(guest.weapon, LiteWeapon.doppieLame);
    expect(coop.fusedWeapon(guest), LiteWeapon.chakram);
  });

  test('Taglio radente cuts and repositions without spending Open', () {
    final run = _run();
    final start = run.position;
    final foe = _target(run, start + _right * 2, 1903);
    expect(run.special(start + _right), isTrue);
    expect(foe.hp, lessThan(180));
    expect(run.special(start + _right), isFalse);
    expect(run.openRoomsRemaining(), 0);
    run.step(.18);
    expect((run.position.y - start.y).abs(), greaterThan(.8));
  });
}
