import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';
import 'package:oculum_rl/widgets/oculum_lite_arena.dart';

class _RecordingArenaCanvas extends TestRecordingCanvas {
  @override
  Float64List getTransform() => Matrix4.identity().storage;
}

void main() {
  testWidgets('natural fighters do not hold the weapon from their loadout', (
    tester,
  ) async {
    final capture = GlobalKey();
    Future<Uint8List> render(
      LiteHero hero,
      LiteWeapon weapon,
      AssetImage figure,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: RepaintBoundary(
              key: capture,
              child: SizedBox(
                width: 240,
                height: 200,
                child: OculumLiteHeroPreview(hero: hero, weapon: weapon),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        final context = tester.element(find.byType(OculumLiteHeroPreview));
        await precacheImage(figure, context);
        if (OculumLiteArena.weaponArt(weapon) case final art?) {
          await precacheImage(art, context);
        }
      });
      await tester.pumpAndSettle();
      final pixels = await tester.runAsync(() async {
        final boundary =
            capture.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        return data!.buffer.asUint8List();
      });
      return pixels!;
    }

    for (final (hero, figure) in [
      (LiteHero.sentinella, OculumLiteArena.golemGait),
      (LiteHero.rasvyr, OculumLiteArena.newActors),
      (LiteHero.pollo, OculumLiteArena.faunaArt),
      (LiteHero.doppelganger, OculumLiteArena.newActors),
    ]) {
      final baseline = await render(hero, LiteWeapon.spadaScudo, figure);
      final staff = await render(hero, LiteWeapon.scettro, figure);
      expect(listEquals(baseline, staff), isTrue, reason: hero.name);
    }

    final spear = await render(
      LiteHero.gablyn,
      LiteWeapon.beccoCaverna,
      OculumLiteArena.nightActors,
    );
    final coil = await render(
      LiteHero.gablyn,
      LiteWeapon.bobinaPostea,
      OculumLiteArena.nightActors,
    );
    expect(listEquals(spear, coil), isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a guest echo keeps the body of the creature that cast it', (
    tester,
  ) async {
    final world = LiteRun(
      seed: 72241,
      hero: LiteHero.evasore,
      weapon: LiteWeapon.arco,
      playerCount: 2,
    );
    expect(
      world.addCoopFighter(
        'ospite',
        'Ragno',
        LiteHero.ragnoSaldatore,
        LiteWeapon.balestraRunica,
      ),
      isTrue,
    );
    world.enemies.clear();
    world.fauna.clear();
    final echo = LiteClone(
      const Point(9, 11),
      22,
      LiteWeapon.spadaScudo,
      ownerId: world.coopFighter('ospite')!.id,
      id: 57,
    );
    world.clones.add(echo);
    final view = ValueNotifier(0);
    await tester.pumpWidget(
      MaterialApp(
        home: OculumLiteArena(run: world, view: view),
      ),
    );
    await tester.runAsync(() async {
      final context = tester.element(find.byType(OculumLiteArena));
      await precacheImage(OculumLiteArena.posteaGaits, context);
      await precacheImage(OculumLiteArena.duplicatorWeaponPoses, context);
    });
    await tester.pumpAndSettle();

    final arenaPaint = tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byType(OculumLiteArena),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter!;

    List<(int, int, Rect, Rect)> drawImages() {
      final canvas = _RecordingArenaCanvas();
      arenaPaint.paint(canvas, const Size(800, 600));
      return [
        for (final call in canvas.invocations)
          if (call.invocation.memberName == #drawImageRect)
            (
              (call.invocation.positionalArguments[0] as ui.Image).width,
              (call.invocation.positionalArguments[0] as ui.Image).height,
              call.invocation.positionalArguments[1] as Rect,
              call.invocation.positionalArguments[2] as Rect,
            ),
      ];
    }

    final sword = drawImages();
    echo.weapon = LiteWeapon.scettro;
    final staff = drawImages();
    expect(staff, sword);

    await tester.pumpWidget(const SizedBox());
    view.dispose();
  });
}
