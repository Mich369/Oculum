import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_coop.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';
import 'package:oculum_rl/services/oculum_lite_saves.dart';
import 'package:oculum_rl/widgets/oculum_lite_appearance.dart';

const _right = Point<double>(1, 0);

LiteRun _run({
  LiteHero hero = LiteHero.duplicatore,
  bool custom = true,
  LiteWeapon weapon = LiteWeapon.spadaScudo,
  int players = 1,
}) =>
    LiteRun(
        seed: 317,
        hero: hero,
        weapon: weapon,
        customAttributes: custom,
        playerCount: players,
      )
      ..enemies.clear()
      ..fauna.clear()
      ..obstacles.clear()
      ..position = const Point(9, 9);

LiteEnemy _target(LiteRun run, double away, double life) {
  final enemy = LiteEnemy(
    1001,
    LiteEnemyKind.slime,
    run.position + _right * away,
    life,
  )..stunned = 45;
  run.enemies.add(enemy);
  return enemy;
}

void main() {
  test('automatic styles distribute four points on every earned level', () {
    final tank = _run(hero: LiteHero.sentinella)..level = 2;
    final fighter = _run(hero: LiteHero.ashley)..level = 2;
    final assassin = _run(hero: LiteHero.assassino)..level = 2;
    final mage = _run(hero: LiteHero.pyrel)..level = 2;
    final base = _run(custom: false);
    for (final unit in [tank, fighter, assassin, mage]) {
      expect(unit.attributesOf().total - base.attributesOf().total, 4);
      expect(unit.freeAttributePoints(), 0);
      expect(unit.customAttributes, isFalse);
    }
    expect(tank.attributesOf().resilienza, 12);
    expect(fighter.attributesOf().volonta, 12);
    expect(assassin.attributesOf().materia, 12);
    expect(mage.attributesOf().oculum, 12);
    expect(tank.maxHp, 126);
    expect(assassin.maxHp, 59);
    expect(LiteRun.normalLifeAtFloor(0), 100);
    expect(
      LiteRun.normalLifeAtFloor(4),
      greaterThan(LiteRun.normalLifeAtFloor(2)),
    );
    tank.level = 4;
    for (final attribute in LiteAttribute.values) {
      expect(tank.attributesOf()[attribute], greaterThan(10));
    }
  });

  test(
    'custom earned points spend once and round trip without a full heal',
    () {
      final run = _run();
      expect(run.customAttributes, isTrue);
      expect(run.freeAttributePoints(), 0);
      expect(run.spendAttributePoint(LiteAttribute.resilienza), isFalse);
      run
        ..level = 2
        ..hp = 40
        ..oculum = 5;
      expect(run.freeAttributePoints(), 4);
      expect(run.spendAttributePoint(LiteAttribute.resilienza), isTrue);
      expect(run.hp, 48);
      expect(run.maxHp, 118);
      expect(run.spendAttributePoint(LiteAttribute.oculum), isTrue);
      expect(run.oculum, 6);
      expect(run.maxOculum, 13);
      final copy = LiteRun.fromJson(run.toJson(includeEffects: true));
      expect(copy.customAttributes, isTrue);
      expect(copy.attributesOf().oculum, 11);
      expect(copy.freeAttributePoints(), 2);
      expect(copy.spendAttributePoint(LiteAttribute.volonta), isTrue);
      expect(copy.spendAttributePoint(LiteAttribute.materia), isTrue);
      expect(copy.spendAttributePoint(LiteAttribute.materia), isFalse);
      copy.level++;
      expect(copy.freeAttributePoints(), 4);
    },
  );

  test(
    'the saved allocation is immutable and malformed stats cannot mint points',
    () {
      final run = _run()..level = 2;
      expect(run.spendAttributePoint(LiteAttribute.materia), isTrue);
      final untouched = run.toJson();
      expect(run.spendAttributePoint(LiteAttribute.oculum), isTrue);
      expect(LiteRun.fromJson(untouched).freeAttributePoints(), 3);

      final malformed = run.toJson()
        ..['attributeGrowth'] = {
          'profile': 'unknown',
          'spent': [-35, 300, 80, '5'],
        };
      final restored = LiteRun.fromJson(malformed);
      expect(restored.attributesOf().total, 44);
      expect(restored.attributesOf().resilienza, 10);
      expect(restored.freeAttributePoints(), 0);
      expect(restored.spendAttributePoint(LiteAttribute.resilienza), isFalse);
    },
  );

  test(
    'legacy custom Duplicator look migrates without converting preset slots',
    () {
      final world = _run(custom: false)
        ..level = 3
        ..hp = 43;
      String legacy(OculumLiteAppearance look, {bool? explicit}) => jsonEncode({
        'schema': 1,
        'name': 'Duplicatore',
        'attempt': 1,
        'run': world.toJson()
          ..remove('attributeGrowth')
          ..remove('customAttributes')
          ..addAll({if (explicit != null) 'customAttributes': explicit}),
        'look': look.toJson(),
      });
      final customLook = const OculumLiteAppearance(
        face: OculumLiteFace.strong,
      );
      final preset = OculumLiteSaveSlot.decode(
        legacy(const OculumLiteAppearance()),
      );
      final edited = OculumLiteSaveSlot.decode(legacy(customLook));
      final explicit = OculumLiteSaveSlot.decode(
        legacy(customLook, explicit: false),
      );
      expect(preset.run.customAttributes, isFalse);
      expect(preset.run.attributesOf().total, 48);
      expect(edited.run.customAttributes, isTrue);
      expect(edited.run.freeAttributePoints(), 8);
      expect(edited.run.hp, 43);
      expect(explicit.run.customAttributes, isFalse);
    },
  );

  test('normal kill still refills both resources and grants custom points', () {
    final run = _run()
      ..exp = 44
      ..hp = 25
      ..oculum = 2;
    _target(run, .8, 1);
    expect(run.attack(run.position + _right), isTrue);
    expect(run.level, 2);
    expect(run.hp, run.maxHp);
    expect(run.oculum, run.maxOculum);
    expect(run.freeAttributePoints(), 4);
  });

  test(
    'Volontà powers weapon damage and fire-time reach independently of Materia',
    () {
      final run = _run(weapon: LiteWeapon.arco)..level = 2;
      final before = run.weaponDamage;
      for (var index = 0; index < 4; index++) {
        expect(run.spendAttributePoint(LiteAttribute.volonta), isTrue);
      }
      expect(run.weaponDamage, before + 12);
      expect(run.attributeAttackSpeed(), 1);
      expect(run.attributeDodgeChance(), 0);
      expect(run.weaponReach(LiteWeapon.arco), closeTo(10.16, .0001));
      final foe = _target(run, 10.08, 100);
      expect(run.attack(run.position + _right), isTrue);
      for (var index = 0; index < 10; index++) {
        run.step(.10);
      }
      expect(foe.hp, lessThan(100));
    },
  );

  test('Materia changes personal windup and recovery only at attack start', () {
    final run = _run(weapon: LiteWeapon.guanti)..level = 8;
    final reach = run.weaponReach(LiteWeapon.guanti);
    final damage = run.weaponDamage;
    for (var index = 0; index < 26; index++) {
      expect(run.spendAttributePoint(LiteAttribute.materia), isTrue);
    }
    expect(run.attributeAttackSpeed(), closeTo(1.104, .0001));
    expect(run.attributeDodgeChance(), .25);
    expect(run.attack(run.position + _right), isTrue);
    expect(run.weaponWindup, closeTo(.32 / 1.104, .0001));
    expect(
      run.attackCooldown,
      closeTo(LiteWeapon.guanti.cooldown / 1.104, .0001),
    );
    expect(run.weaponDamage, damage);
    expect(run.weaponReach(LiteWeapon.guanti), reach);
    final startedWindup = run.weaponWindup;
    expect(run.spendAttributePoint(LiteAttribute.materia), isTrue);
    expect(run.weaponWindup, startedWindup);
  });

  test('single authoritative dodge survives a save and cannot reroll the same shot', () {
    final run = _run()
      ..level = 8
      ..stageClear = true;
    for (var index = 0; index < 25; index++) {
      run.spendAttributePoint(LiteAttribute.materia);
    }
    final restored = LiteRun.fromJson(run.toJson()..['rng'] = 1);
    final hp = restored.hp;
    LiteProjectile shot(LiteProjectileKind kind) => LiteProjectile(
      position: restored.position - _right * .35,
      direction: _right,
      speed: 2,
      remaining: 5,
      damage: 16,
      fromEnemy: true,
      kind: kind,
    );
    restored.projectiles.add(shot(LiteProjectileKind.normal));
    restored.step(.11);
    expect(restored.hp, hp);
    expect(restored.projectiles.single.hit, contains(-1));
    expect(
      restored.combatImpacts.where(
        (event) => event.target == LiteImpactTarget.materiaDodge,
      ),
      hasLength(1),
    );
    final copied = LiteRun.fromJson(restored.toJson(includeEffects: true));
    final rng = copied.toJson()['rng'];
    copied.step(.22);
    expect(copied.hp, hp);
    expect(copied.toJson()['rng'], rng);
    restored.projectiles
      ..clear()
      ..add(shot(LiteProjectileKind.cannon));
    restored.step(.08);
    expect(restored.hp, lessThan(hp));
  });

  test('the Master credits only the requesting custom guest and rejects duplicate input', () {
    final run = _run(weapon: LiteWeapon.guanti, players: 2);
    expect(
      run.addCoopFighter(
        'guest',
        'G',
        LiteHero.duplicatore,
        LiteWeapon.guanti,
        customAttributes: true,
      ),
      isTrue,
    );
    final guest = run.coopFighter('guest')!
      ..experience = 45
      ..cooldown = 0;
    final coop = OculumLiteCoop(
      runId: 'run',
      localAccount: 'host',
      authority: run,
      send: (_) async => true,
    );
    addTearDown(coop.dispose);
    void send(int input, int request, String name) => coop.receive(
      {
        'kind': 'playInput',
        'runId': 'run',
        'input': input,
        'stage': run.stage,
        'arena': run.inputArena,
        'move': [0.0, 0.0],
        'aim': [14, 10],
        'restAction': {'id': request, 'kind': 'attribute', 'item': name},
      },
      account: 'guest',
      sessionId: 'guest-live',
      verifiedMaster: false,
    );
    send(1, 1, 'materia');
    send(2, 1, 'materia');
    send(3, 2, 'nonexistent');
    send(4, 3, 'volonta');
    expect(run.attributesOf(guest).materia, 11);
    expect(run.attributesOf(guest).volonta, 11);
    expect(run.freeAttributePoints(guest), 2);
    expect(run.attributesOf().total, 40);
    final frame = LiteRun.fromJson(run.toJson(includeEffects: true));
    final copied = frame.coopFighter('guest')!;
    expect(copied.customAttributes, isTrue);
    expect(frame.freeAttributePoints(copied), 2);
    expect(frame.attributesOf(copied).volonta, 11);
  });
}
