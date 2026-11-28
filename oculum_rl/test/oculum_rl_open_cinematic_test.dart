import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';
import 'package:oculum_rl/widgets/oculum_lite_appearance.dart';
import 'package:oculum_rl/widgets/oculum_lite_arena.dart';

const origin = Point<double>(14, 11);
const guestOrigin = Point<double>(14, 14);
const right = Point<double>(1, 0);
const target = Point<double>(16.2, 11);

LiteRun prepared(LiteHero hero, {int players = 1}) =>
    LiteRun(
        seed: 251,
        hero: hero,
        weapon: LiteWeapon.arco,
        playerCount: players,
      )
      ..position = origin
      ..aim = right
      ..obstacles.clear()
      ..fauna.clear()
      ..loot.clear()
      ..enemies.clear()
      ..enemies.add(
        LiteEnemy(60, LiteEnemyKind.costrutto, target, 900)..stunned = 15,
      );

LiteProjectile incoming(Point<double> at) => LiteProjectile(
  position: at - const Point(.14, 0),
  direction: right,
  speed: 24,
  remaining: 3,
  damage: 12,
  fromEnemy: true,
);

class _OpenCanvas extends TestRecordingCanvas {
  @override
  Float64List getTransform() => Matrix4.identity().storage;
}

_OpenCanvas paintedArena(WidgetTester tester) {
  final arena = find.byType(OculumLiteArena);
  final painter = tester
      .widget<CustomPaint>(
        find.descendant(of: arena, matching: find.byType(CustomPaint)),
      )
      .painter!;
  final canvas = _OpenCanvas();
  painter.paint(canvas, const Size(800, 600));
  return canvas;
}

void main() {
  for (final cooperative in [false, true]) {
    testWidgets('Pyrel uses charge, strike and rest Ink poses in the '
        '${cooperative ? "guest" : "solo"} Open', (tester) async {
      final run =
          LiteRun(
              seed: 251,
              hero: cooperative ? LiteHero.evasore : LiteHero.pyrel,
              weapon: LiteWeapon.scettro,
              playerCount: cooperative ? 2 : 1,
            )
            ..position = origin
            ..obstacles.clear()
            ..enemies.clear()
            ..fauna.clear();
      if (cooperative) {
        expect(
          run.addCoopFighter(
            'pyrel',
            'Pyrel',
            LiteHero.pyrel,
            LiteWeapon.scettro,
          ),
          isTrue,
        );
        run.coopFighter('pyrel')!.position = guestOrigin;
      }
      await tester.pumpWidget(MaterialApp(home: OculumLiteArena(run: run)));
      final arena = tester.element(find.byType(OculumLiteArena));
      await tester.runAsync(
        () => precacheImage(OculumLiteArena.rosterMotion, arena),
      );
      await tester.pumpAndSettle();

      int vignettePose() {
        final paint = paintedArena(tester);
        final draws = paint.invocations.where((call) {
          if (call.invocation.memberName != #drawImageRect) return false;
          final source = call.invocation.positionalArguments[1] as Rect;
          final image = call.invocation.positionalArguments[0] as ui.Image;
          return source.width * 9 == image.width &&
              source.height * 9 == image.height &&
              source.top / source.height == 3;
        }).toList();
        expect(draws.length, greaterThanOrEqualTo(2));
        final source = draws.last.invocation.positionalArguments[1] as Rect;
        return (source.left / source.width).round();
      }

      if (cooperative) {
        expect(
          run.setCoopControls(
            'pyrel',
            right,
            target,
            attack: false,
            open: true,
          ),
          isTrue,
        );
      } else {
        expect(run.useOpen(target), isTrue);
      }
      expect(run.openScene?.hero, LiteHero.pyrel);
      run.advanceFrame(.14);
      expect(vignettePose(), 6);
      run.advanceFrame(.21);
      expect(vignettePose(), 7);
      run.advanceFrame(.24);
      expect(vignettePose(), 0);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('the Shadow Open vignette shows the copied guest in Shadow ink', (
    tester,
  ) async {
    const guestSkin = Color(0xffcb8177);
    const guestAccent = Color(0xff10a664);
    const shadowAccent = Color(0xffbc7fb1);
    final run = prepared(LiteHero.pyrel, players: 2)..enemies.clear();
    expect(
      run.addCoopFighter(
        'evasore',
        'Ospite',
        LiteHero.evasore,
        LiteWeapon.guanti,
      ),
      isTrue,
    );
    final guest = run.coopFighter('evasore')!..position = guestOrigin;
    final mirror = LiteEnemy(74, LiteEnemyKind.ombra, target, 900)
      ..mirror =
          (LiteMirrorBuild(
              hero: LiteHero.evasore,
              weapon: LiteWeapon.guanti,
              slots: [],
              quantities: [],
              learned: {},
              oculum: 40,
              damage: 12,
              shield: 0,
              playerId: guest.id,
            )
            ..openCooldown = 0
            ..signatureCooldown = 12)
      ..cooldown = 0;
    run.enemies.add(mirror);
    await tester.pumpWidget(
      MaterialApp(
        home: OculumLiteArena(
          run: run,
          guestAppearances: const {
            'evasore': OculumLiteAppearance(
              skin: guestSkin,
              accent: guestAccent,
            ),
          },
        ),
      ),
    );
    run.advanceFrame(.04);
    expect(run.openScene?.enemyId, mirror.id);
    expect(run.openScene?.actorId, guest.id);
    run.advanceFrame(.19);
    final frames = paintedArena(tester).invocations;
    final vignette = frames.lastIndexWhere((call) {
      if (call.invocation.memberName != #saveLayer) return false;
      final bounds = call.invocation.positionalArguments[0];
      return bounds is Rect && (bounds.width - 193.8).abs() < .0001;
    });
    expect(vignette, isNonNegative);
    final fills = frames.skip(vignette).expand((call) {
      return call.invocation.positionalArguments.whereType<Paint>().map(
        (paint) => paint.color.toARGB32(),
      );
    });
    expect(fills, containsAll([guestSkin.toARGB32(), shadowAccent.toARGB32()]));
    expect(fills, isNot(contains(guestAccent.toARGB32())));
    await tester.pumpWidget(const SizedBox());
  });

  test('all playable Opens pause the entire solo simulation exactly once', () {
    for (final hero in LiteHero.values) {
      final run = prepared(hero);
      if (hero == LiteHero.doppelganger) {
        expect(run.useOpen(target), isFalse);
        expect(run.openScene, isNull);
        expect(run.special(target), isTrue);
      }
      expect(run.useOpen(target), isTrue, reason: hero.name);
      expect(run.openScene?.title, hero.openName);
      expect(run.invulnerable, isTrue);
      expect(run.useOpen(target), isFalse);
      final world = run.toJson();
      final ammo = run.oculum;
      for (var i = 0; i < 5; i++) {
        run.advanceFrame(LiteOpenScene.duration / 6, move: right);
        expect(
          run.toJson(),
          world,
          reason: 'solo simulation moved for ${hero.name}',
        );
        expect(run.invulnerable, isTrue);
      }
      expect(run.openScene!.progress(), closeTo(5 / 6, .0001));
      expect(LiteRun.fromJson(world).openScene, isNull);
      run.advanceFrame(LiteOpenScene.duration / 6, move: right);
      expect(run.openScene, isNull);
      expect(run.oculum, ammo);
      final t = run.time;
      run.advanceFrame(.03, move: right);
      expect(run.time, greaterThan(t));
    }
  });

  test('co-op time slows for everyone and only the caster is protected', () {
    final run = prepared(LiteHero.ashley, players: 2);
    run.addCoopFighter('guest', 'Ospite', LiteHero.ashley, LiteWeapon.arco);
    final guest = run.coopFighter('guest')!..position = guestOrigin;
    expect(run.useOpen(target), isTrue);
    expect(run.openTimeScale, LiteOpenScene.coopTimeScale);
    expect(run.openProtects(guest.id), isFalse);
    expect(run.invulnerable, isTrue);
    expect(
      run.setCoopControls('guest', right, guestOrigin + right, attack: false),
      isTrue,
    );
    run.projectiles.addAll([incoming(origin), incoming(guestOrigin)]);
    final hp = run.hp;
    final guestHp = guest.hp;
    run.advanceFrame(.16, move: right);
    expect(run.hp, hp);
    expect(guest.hp, lessThan(guestHp));
    expect(
      run.time,
      closeTo(.16 * run.arenaSpeed * LiteOpenScene.coopTimeScale, .0001),
    );
    expect(run.position.x - origin.x, inInclusiveRange(.12, .33));
    expect(guest.position.x, greaterThan(guestOrigin.x));
    final replica = LiteRun.fromJson(run.toJson(includeEffects: true));
    expect(replica.openScene!.title, LiteHero.ashley.openName);
    expect(replica.openScene!.remaining, closeTo(.56, .0001));
    expect(replica.openProtects(0), isTrue);
    expect(replica.openProtects(guest.id), isFalse);
    for (var i = 0; i < 6; i++) {
      run.advanceFrame(.10);
    }
    expect(run.openTimeScale, 1);
    expect(run.invulnerable, isFalse);
    run.projectiles.add(incoming(run.position));
    run.advanceFrame(.05);
    expect(run.hp, lessThan(hp));
  });

  test('Open from a non-host protects the corresponding member', () {
    final run = prepared(LiteHero.ashley, players: 6);
    run.addCoopFighter('guest', 'Ospite', LiteHero.pyrel, LiteWeapon.guanti);
    final guest = run.coopFighter('guest')!..position = guestOrigin;
    expect(
      run.setCoopControls(
        'guest',
        right,
        guestOrigin + right,
        attack: false,
        open: true,
      ),
      isTrue,
    );
    expect(run.openScene?.hero, LiteHero.pyrel);
    expect(run.openProtects(guest.id), isTrue);
    expect(run.invulnerable, isFalse);
    final hp = run.hp;
    final guestHp = guest.hp;
    run.projectiles.addAll([incoming(origin), incoming(guestOrigin)]);
    run.advanceFrame(.16);
    expect(run.hp, lessThan(hp));
    expect(guest.hp, guestHp);
  });

  test('simultaneous co-op Opens do not stack the time scale', () {
    final run = prepared(LiteHero.ashley, players: 2);
    run.addCoopFighter('guest', 'Ospite', LiteHero.pyrel, LiteWeapon.guanti);
    final guest = run.coopFighter('guest')!..position = guestOrigin;
    expect(run.useOpen(target), isTrue);
    run.advanceFrame(.40);
    expect(
      run.setCoopControls(
        'guest',
        right,
        guestOrigin + right,
        attack: false,
        open: true,
      ),
      isTrue,
    );
    expect(run.openProtects(0), isTrue);
    expect(run.openProtects(guest.id), isTrue);
    final replica = LiteRun.fromJson(run.toJson(includeEffects: true));
    expect(replica.openSceneFor(guest.id)?.hero, LiteHero.pyrel);
    final time = run.time;
    run.advanceFrame(.33);
    expect(run.openProtects(0), isFalse);
    expect(run.openProtects(guest.id), isTrue);
    expect(
      run.time - time,
      closeTo(.33 * run.arenaSpeed * LiteOpenScene.coopTimeScale, .0001),
    );
  });

  test('co-op moves the team at 26 percent and enemies at 24 percent', () {
    LiteRun world() {
      final run = prepared(LiteHero.ashley, players: 2);
      run.addCoopFighter('guest', 'Ospite', LiteHero.pyrel, LiteWeapon.guanti);
      run.coopFighter('guest')!.position = guestOrigin;
      run.setCoopControls('guest', right, guestOrigin + right, attack: false);
      run.enemies
        ..clear()
        ..add(LiteEnemy(80, LiteEnemyKind.costrutto, const Point(22, 11), 900));
      run.clones.add(
        LiteClone(
          const Point(12, 11),
          100,
          LiteWeapon.guanti,
          id: 60,
          companion: LiteCompanion.vedetta,
        ),
      );
      return run;
    }

    final normal = world();
    final slowed = world();
    expect(slowed.useOpen(target), isTrue);
    final allyAt = slowed.clones.single.position;
    final enemyAt = slowed.enemies.single.position;
    normal.advanceFrame(.12, move: right);
    slowed.advanceFrame(.12, move: right);

    void check(
      Point<double> start,
      Point<double> fast,
      Point<double> slow,
      double factor,
    ) {
      final motion = start.distanceTo(fast);
      expect(motion, greaterThan(.03));
      expect(start.distanceTo(slow) / motion, closeTo(factor, .004));
    }

    check(origin, normal.position, slowed.position, .26);
    check(
      guestOrigin,
      normal.coopFighter('guest')!.position,
      slowed.coopFighter('guest')!.position,
      .26,
    );
    check(
      allyAt,
      normal.clones.single.position,
      slowed.clones.single.position,
      .26,
    );
    check(
      enemyAt,
      normal.enemies.single.position,
      slowed.enemies.single.position,
      .24,
    );
  });

  for (final shadow in [false, true]) {
    test('the ${shadow ? "Shadow" : "Light"} Open pauses at activation', () {
      final run = prepared(LiteHero.pyrel)..enemies.clear();
      final enemy =
          LiteEnemy(
              73,
              shadow ? LiteEnemyKind.ombra : LiteEnemyKind.luce,
              target,
              900,
            )
            ..mirror =
                (LiteMirrorBuild(
                    hero: LiteHero.pyrel,
                    weapon: LiteWeapon.guanti,
                    slots: [],
                    quantities: [],
                    learned: {},
                    oculum: 40,
                    damage: 12,
                    shield: 0,
                  )
                  ..openCooldown = 0
                  ..signatureCooldown = 12)
            ..cooldown = 0;
      run.enemies.add(enemy);
      run.advanceFrame(.04);
      expect(run.openScene!.enemyId, enemy.id);
      expect(run.openScene!.shadow, shadow);
      expect(enemy.mirror!.openUses, 1);
      final stamp = run.time;
      final bolt = run.projectiles.first;
      run.advanceFrame(.10);
      expect(run.time, stamp);
      expect(bolt.age, 0);
    });
  }
}
