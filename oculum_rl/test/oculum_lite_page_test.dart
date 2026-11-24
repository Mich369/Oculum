import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';
import 'package:oculum_rl/pages/oculum_lite_page.dart';
import 'package:oculum_rl/services/oculum_lite_saves.dart';
import 'package:oculum_rl/services/oculum_save_profile.dart';
import 'package:oculum_rl/widgets/oculum_lite_arena.dart';
import 'package:oculum_rl/widgets/oculum_lite_creator.dart';
import 'package:oculum_rl/widgets/oculum_lite_routes.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Sprite LOD queries the canvas transform once its atlas has finished loading.
class _ArenaRecordingCanvas extends TestRecordingCanvas {
  @override
  Float64List getTransform() => Matrix4.identity().storage;
}

class _BrowserLikePaths extends PathProviderPlatform {
  @override
  Future<String?> getApplicationSupportPath() async =>
      throw MissingPluginException();
}

void main() {
  setUp(() {
    final original = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _BrowserLikePaths();
    addTearDown(() => PathProviderPlatform.instance = original);
  });

  testWidgets('arena keeps rapid damage legible and groups nearby clashes', (
    tester,
  ) async {
    final source = LiteRun(
      seed: 49,
      hero: LiteHero.ashley,
      weapon: LiteWeapon.arco,
    )..position = const Point(13, 11);
    List<Object?> impact(
      LiteImpactTarget target,
      double x,
      double time, [
      double life = 0,
    ]) => [target.index, 20, x, 11, time, life, 0, false, null];
    final run = LiteRun.fromJson({
      ...source.toJson(),
      'time': 10,
      'impacts': [
        impact(LiteImpactTarget.clash, 12, 9.26),
        impact(LiteImpactTarget.enemy, 13, 9.55, 29),
        impact(LiteImpactTarget.clash, 18, 9.7),
        impact(LiteImpactTarget.clash, 13, 9.86),
        impact(LiteImpactTarget.enemy, 13, 9.96, 19),
      ],
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: OculumLiteArena(run: run)),
      ),
    );
    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(OculumLiteArena),
        matching: find.byType(CustomPaint),
      ),
    );

    for (final size in const [Size(800, 450), Size(390, 480)]) {
      final canvas = _ArenaRecordingCanvas();
      paint.painter!.paint(canvas, size);
      final labels = [
        for (final call in canvas.invocations)
          if (call.invocation.memberName == #drawRRect &&
              (call.invocation.positionalArguments[1] as Paint).color
                          .toARGB32() &
                      0x00ffffff ==
                  0x100d17)
            (call.invocation.positionalArguments[0] as RRect).outerRect,
      ];
      // Both hits stay visible and the separate clash is kept. Only the old
      // clash next to the new one is removed from the overlay.
      expect(labels, hasLength(4), reason: '$size');
      for (var i = 0; i < labels.length; i++) {
        expect((Offset.zero & size).contains(labels[i].topLeft), isTrue);
        expect((Offset.zero & size).contains(labels[i].bottomRight), isTrue);
        expect(labels.skip(i + 1).any(labels[i].overlaps), isFalse);
      }
    }
    expect(run.combatImpacts, hasLength(5));
  });

  testWidgets('the arena and HUD distinguish player, NPC and enemy life', (
    tester,
  ) async {
    final run =
        LiteRun(
            seed: 49,
            hero: LiteHero.evasore,
            weapon: LiteWeapon.guanti,
            playerCount: 2,
          )
          ..position = const Point(15, 11)
          ..enemies.clear()
          ..obstacles.clear()
          ..enemies.add(
            LiteEnemy(70, LiteEnemyKind.slime, const Point(17, 9), 30),
          )
          ..clones.add(
            LiteClone(
              const Point(12, 10),
              10,
              LiteWeapon.fucileScostubandito,
              companion: LiteCompanion.sentinella,
            ),
          );
    expect(
      run.addCoopFighter('qa', 'Ospite', LiteHero.ashley, LiteWeapon.guanti),
      isTrue,
    );
    run.coopFighter('qa')!.position = const Point(14, 12);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const OculumLitePlayerLifeBar(value: .42),
              Expanded(child: OculumLiteArena(run: run)),
            ],
          ),
        ),
      ),
    );
    final health = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(health.value, .42);
    expect(health.color, const Color(0xff79caff));
    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(OculumLiteArena),
        matching: find.byType(CustomPaint),
      ),
    );
    final canvas = _ArenaRecordingCanvas();
    paint.painter!.paint(canvas, const Size(800, 450));
    final fills = <int, int>{};
    for (final call in canvas.invocations) {
      final invocation = call.invocation;
      if (invocation.memberName != #drawRect) continue;
      final rect = invocation.positionalArguments[0] as Rect;
      if ((rect.height - .07).abs() > .0001) continue;
      final color = (invocation.positionalArguments[1] as Paint).color
          .toARGB32();
      fills.update(color, (count) => count + 1, ifAbsent: () => 1);
    }
    expect(fills[health.color!.toARGB32()], 2, reason: "$fills");
    expect(fills[0xff8bd78d], 1);
    expect(fills[0xffe27471], 1);
  });

  testWidgets('the permanent shop benefits a new Scostubandito using Space', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = OculumLiteSaveStore(prefs);
    await store.writeProgress(
      const OculumLiteProgress(
        bestClearedFloor: 6,
        scostubanditoUnlocked: true,
      ),
    );
    await tester.pumpWidget(const MaterialApp(home: OculumLitePage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Potenziamenti permanenti'));
    await tester.pumpAndSettle();
    final buyVita = find.descendant(
      of: find.widgetWithText(ListTile, 'Vita'),
      matching: find.text('1 Sigillo'),
    );
    await tester.tap(buyVita);
    await tester.pumpAndSettle();
    expect((await store.readProgress()).upgrades[LitePermanentUpgrade.vita], 1);
    await tester.tap(find.text('Chiudi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gioca subito'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Scostubandito'));
    await tester.pumpAndSettle();
    final start = find.byKey(const ValueKey('oculum-lite-start-run'));
    await tester.scrollUntilVisible(
      start,
      140,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(start);
    await tester.pumpAndSettle();
    await tester.tap(start);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final run = tester
        .widget<OculumLiteArena>(find.byType(OculumLiteArena))
        .run;
    expect(run.hero, LiteHero.scostubandito);
    expect(run.ownedWeapons, [LiteWeapon.fucileScostubandito]);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF);
    expect(run.blocking, isTrue);
    expect(run.banditRounds, 0);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF);
    expect(run.blocking, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
    expect(run.banditRounds, 4);
    expect(run.maxHp, 105);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(run.clones.single.companion, LiteCompanion.granScostumato);
    expect(run.oculum, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a recovered boss weapon opens inventory and can be saved', (
    tester,
  ) async {
    final key = oculumLiteSaveSlotKey(0);
    final run = LiteRun(
      seed: 42,
      hero: LiteHero.ashley,
      weapon: LiteWeapon.piccaOssidiana,
    );
    final backup = OculumLiteSaveSlot(
      run: run,
      name: 'Ashley',
      appearance: const OculumLiteAppearance(),
      attempt: 1,
      startingWeapon: LiteWeapon.arco,
      startingBiome: LiteBiome.campo,
    ).encode();
    SharedPreferences.setMockInitialValues({
      key: 'interrotto',
      '$key.backup': backup,
    });
    await tester.pumpWidget(const MaterialApp(home: OculumLitePage()));
    await tester.pumpAndSettle();
    expect(find.textContaining('Copia di sicurezza'), findsOneWidget);
    await tester.tap(find.text('Continua'));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byTooltip('Inventario e pausa'));
    await tester.pumpAndSettle();
    expect(find.text('In uso: Picca d’ossidiana'), findsOneWidget);
    final save = find.text('Salva ora');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Partita salvata.'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(
      OculumLiteSaveSlot.decode(prefs.getString(key)!).run.weapon,
      LiteWeapon.piccaOssidiana,
    );
  });

  testWidgets('a damaged profile or audio setting does not block run slots', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final slotKey = oculumLiteSaveSlotKey(0);
    final progressKey = oculumProfiledStorageKey('oculum_lite_progress');
    final original = OculumLiteSaveSlot(
      run: LiteRun(seed: 68, hero: LiteHero.evasore, weapon: LiteWeapon.arco)
        ..stage = 3
        ..dead = true,
      name: 'Evasore',
      appearance: OculumLiteAppearance.evasore,
      attempt: 2,
      startingWeapon: LiteWeapon.arco,
      startingBiome: LiteBiome.campo,
    ).encode();
    SharedPreferences.setMockInitialValues({
      slotKey: original,
      progressKey: 'profilo illeggibile',
      oculumProfiledStorageKey('oculum_lite_audio_musica'): 'vecchio valore',
      oculumProfiledStorageKey('oculum_lite_audio_muto'): 1,
    });
    await tester.pumpWidget(const MaterialApp(home: OculumLitePage()));
    await tester.pumpAndSettle();
    expect(
      find.text('Impossibile aprire i salvataggi di Oculum RL.'),
      findsNothing,
    );
    await tester.tap(find.text('Continua'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nuovo tentativo'));
    await tester.pumpAndSettle();
    expect(find.text('Tentativo 3 · Salvataggio 1'), findsOneWidget);
    final start = find.byKey(const ValueKey('oculum-lite-start-run'));
    await tester.scrollUntilVisible(
      start,
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Impossibile aggiornare il profilo'),
      findsOneWidget,
    );
    await tester.tap(start);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.byType(OculumLiteArena), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(OculumLiteSaveSlot.decode(prefs.getString(slotKey)!).attempt, 3);
    expect(prefs.getString('$slotKey.backup'), original);
    expect(prefs.getString(progressKey), 'profilo illeggibile');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'an old ended slot lets you choose another hero before retrying',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final key = oculumLiteSaveSlotKey(0);
      final oldRun = LiteRun(
        seed: 97,
        hero: LiteHero.evasore,
        weapon: LiteWeapon.arco,
      )..dead = true;
      final original = OculumLiteSaveSlot(
        run: oldRun,
        name: 'Evasore',
        appearance: OculumLiteAppearance.evasore,
        attempt: 4,
        startingWeapon: LiteWeapon.arco,
        startingBiome: LiteBiome.campo,
      ).encode();
      SharedPreferences.setMockInitialValues({key: original});
      await tester.pumpWidget(const MaterialApp(home: OculumLitePage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continua'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nuovo tentativo'));
      await tester.pumpAndSettle();
      expect(find.text('Tentativo 5 · Salvataggio 1'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Ashley'), findsOneWidget);
      await tester.tap(find.byTooltip('Annulla'));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(key), original);
      await tester.tap(find.text('Continua'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nuovo tentativo'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Ashley'));
      await tester.pumpAndSettle();
      final start = find.byKey(const ValueKey('oculum-lite-start-run'));
      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      final newSave = OculumLiteSaveSlot.decode(prefs.getString(key)!);
      expect(newSave.run.hero, LiteHero.ashley);
      expect(newSave.run.dead, isFalse);
      expect(newSave.run.seed, 97);
      expect(newSave.attempt, 5);
      expect(prefs.getString('$key.backup'), original);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('the portal shows rival, reward and rest on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final run = Iterable<int>.generate(100)
        .map(
          (seed) => LiteRun(
            seed: seed,
            hero: LiteHero.evasore,
            weapon: LiteWeapon.arco,
          )..stage = 2,
        )
        .firstWhere((run) => run.routeBiomes.contains(LiteBiome.postea));
    run.enemies.clear();
    run.step(.01);
    run.position = run.portalPosition;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                final route = await chooseOculumLiteRoute(context, run);
                if (route != null) run.advance(route);
              },
              child: const Text('Test del portale'),
            ),
          ),
        ),
      ),
    );
    final open = find.text('Test del portale');
    await tester.tap(open);
    await tester.pumpAndSettle();
    expect(find.text('Portale · Piano 3'), findsOneWidget);
    expect(find.text('Nemici · +15% Vita, +12% Danni'), findsOneWidget);
    expect(find.text('Boss · La tua Luce'), findsNWidgets(3));
    expect(find.textContaining('Ristoro 50% Vita'), findsWidgets);
    expect(find.textContaining('l’offerta scade'), findsOneWidget);
    await tester.tap(find.text('Resta qui'));
    await tester.pumpAndSettle();
    expect(run.stage, 2);
    expect(run.powerOffers, isNotEmpty);
    await tester.tap(open);
    await tester.pumpAndSettle();
    final postea = find.text(LiteBiome.postea.label, findRichText: true);
    await tester.ensureVisible(postea);
    await tester.pumpAndSettle();
    await tester.tap(postea);
    await tester.pumpAndSettle();
    expect(run.stage, 3);
    expect(run.biome, LiteBiome.postea);
    expect(run.floorLayout, LiteFloorLayout.montaggio);
    expect(run.powerOffers, isEmpty);
  });

  testWidgets(
    'the shared creator copies a saved look without changing the source',
    (tester) async {
      const originalLook = OculumLiteAppearance(
        lineage: OculumLiteLineage.goblin,
        body: OculumLiteBody.androgynous,
        outfit: OculumLiteOutfit.postea,
        headgear: OculumLiteHeadgear.goggles,
        emblem: OculumLiteEmblem.moon,
      );
      String save(String name, LiteHero hero) => OculumLiteSaveSlot(
        run: LiteRun(seed: 42, hero: hero, weapon: LiteWeapon.spadaScudo),
        name: name,
        attempt: 2,
        startingWeapon: LiteWeapon.spadaScudo,
        startingBiome: LiteBiome.campo,
        appearance: originalLook,
      ).encode();
      final first = oculumLiteSaveSlotKey(0);
      final original = save('Clonatore salvato', LiteHero.duplicatore);
      SharedPreferences.setMockInitialValues({
        first: 'dati illeggibili',
        '$first.backup': original,
        oculumLiteSaveSlotKey(1): save('Ashley salvata', LiteHero.ashley),
        oculumLiteSaveSlotKey(2): 'altro slot illeggibile',
      });
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      OculumLiteCreation? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await editOculumLiteAppearance(
                    context,
                    appearance: const OculumLiteAppearance(),
                    weapon: LiteWeapon.arco,
                    name: 'Prima',
                  );
                },
                child: const Text('Apri creatore'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Apri creatore'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Carica aspetto salvato'));
      await tester.pumpAndSettle();
      expect(find.text('Salvataggio 1'), findsOneWidget);
      expect(find.text('Ashley salvata'), findsNothing);
      expect(find.text('Salvataggio 3'), findsNothing);
      await tester.tap(find.text('Clonatore salvato'));
      await tester.pumpAndSettle();
      final preview = tester.widget<OculumLiteHeroPreview>(
        find.byType(OculumLiteHeroPreview),
      );
      expect(preview.appearance!.sameAs(originalLook), isTrue);
      expect(preview.weapon, LiteWeapon.arco);
      await tester.tap(find.byTooltip('Avvicina anteprima'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        1.45,
      );
      await tester.enterText(find.byType(TextField), 'Copia personalizzata');
      await tester.tap(find.text('Usa questo aspetto'));
      await tester.pumpAndSettle();
      expect(result!.name, 'Copia personalizzata');
      expect(result!.appearance.sameAs(originalLook), isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(first), 'dati illeggibili');
      expect(prefs.getString('$first.backup'), original);
    },
  );

  test('appearance maps keep all options and safely read legacy looks', () {
    final seen = <String>{};
    final random = Random(9823);
    for (var i = 0; i < 120; i++) {
      final look = OculumLiteAppearance.random(random);
      final saved = jsonEncode(look.toJson());
      expect(
        OculumLiteAppearance.fromJson(jsonDecode(saved)).sameAs(look),
        isTrue,
      );
      seen.add(saved);
    }
    expect(seen, hasLength(120));
    final legacy = OculumLiteAppearance.fromJson({
      'body': 'feminine',
      'lineage': 'goblin',
      'face': 'strong',
      'frame': .82,
      'ears': -1.0,
      'headgear': 'unsupported',
      'emblem': 42,
    });
    expect(legacy.body, OculumLiteBody.feminine);
    expect(legacy.lineage, OculumLiteLineage.goblin);
    expect(legacy.face, OculumLiteFace.strong);
    expect(legacy.frame, .82);
    expect(legacy.ears, 0.0);
    expect(legacy.headgear, OculumLiteHeadgear.none);
    expect(legacy.emblem, OculumLiteEmblem.none);
  });

  testWidgets(
    'Oculum RL creates and resumes a custom Duplicator in an isolated slot',
    (tester) async {
      const oldDungeonKey = 'oculum_dungeon_save';
      final firstKey = oculumProfiledStorageKey('oculum_lite_v1_1');
      final corruptKey = oculumProfiledStorageKey('oculum_lite_v1_2');
      SharedPreferences.setMockInitialValues({
        oldDungeonKey: 'salvataggio precedente',
        corruptKey: 'dati non leggibili',
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(430, 932);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: OculumLitePage()));
      await tester.pumpAndSettle();
      expect(find.text('Dati illeggibili. Slot preservato.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('oculum-lite-play')));
      await tester.pumpAndSettle();
      expect(find.text('Schivata intangibile'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Duplicatore'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Personalizza in 2D'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'Runa',
      );
      final goblin = find.widgetWithText(ChoiceChip, 'Goblin');
      await tester.ensureVisible(goblin);
      await tester.tap(goblin);
      await tester.pump();
      final feminine = find.widgetWithText(ChoiceChip, 'Femminile');
      await tester.ensureVisible(feminine);
      await tester.tap(feminine);
      await tester.pump();
      final face = find.widgetWithText(ChoiceChip, 'Marcati');
      await tester.ensureVisible(face);
      await tester.tap(face);
      await tester.pump();
      for (final caption in [
        'Treccia lunga',
        'Corna',
        'Cicatrice',
        'Postea',
        'Luna',
      ]) {
        final option = find.widgetWithText(ChoiceChip, caption);
        await tester.ensureVisible(option);
        await tester.tap(option);
        await tester.pump();
      }
      final buildSlider = find.byKey(const ValueKey('rl-corpo'));
      await tester.ensureVisible(buildSlider);
      await tester.drag(buildSlider, const Offset(42, 0));
      await tester.pump();
      final posePicker = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(DropdownButtonFormField<LiteWeapon>),
      );
      await tester.ensureVisible(posePicker);
      await tester.tap(posePicker);
      await tester.pumpAndSettle();
      await tester.tap(find.text(LiteWeapon.falceRunica.label).last);
      await tester.pumpAndSettle();
      final preview = tester.widget<OculumLiteHeroPreview>(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(OculumLiteHeroPreview),
        ),
      );
      expect(preview.weapon, LiteWeapon.falceRunica);
      expect(preview.appearance!.body, OculumLiteBody.feminine);
      expect(preview.appearance!.hairstyle, OculumLiteHair.longBraid);
      expect(preview.appearance!.lineage, OculumLiteLineage.goblin);
      expect(preview.appearance!.headgear, OculumLiteHeadgear.horns);
      expect(preview.appearance!.faceDetail, OculumLiteFaceDetail.scar);
      expect(preview.appearance!.outfit, OculumLiteOutfit.postea);
      expect(preview.appearance!.emblem, OculumLiteEmblem.moon);
      await tester.tap(find.text('Usa questo aspetto'));
      await tester.pumpAndSettle();
      final start = find.byKey(const ValueKey('oculum-lite-start-run'));
      await tester.scrollUntilVisible(
        start,
        140,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(start);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.textContaining('Runa · '), findsOneWidget);

      final arena = tester.widget<OculumLiteArena>(
        find.byType(OculumLiteArena),
      );
      expect(arena.appearance!.lineage, OculumLiteLineage.goblin);
      expect(arena.appearance!.body, OculumLiteBody.feminine);
      expect(arena.appearance!.hairstyle, OculumLiteHair.longBraid);
      expect(arena.appearance!.face, OculumLiteFace.strong);
      expect(arena.appearance!.sameAs(preview.appearance!), isTrue);
      expect(arena.appearance!.frame, greaterThan(.50));
      expect(arena.run.ownedWeapons, [LiteWeapon.arco]);
      expect(
        arena.run.special(arena.run.position + const Point<double>(1, 0)),
        isTrue,
      );
      expect(arena.run.clones.single.weapon, LiteWeapon.arco);
      arena.run.clones.clear();
      final initialPosition = arena.run.position;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyD);
      await tester.pump(const Duration(milliseconds: 20));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyD);
      expect(arena.run.position.x, greaterThan(initialPosition.x));
      await tester.tap(find.byTooltip('Inventario e pausa'));
      await tester.pumpAndSettle();
      final pausedPosition = arena.run.position;
      await tester.pump(const Duration(seconds: 2));
      expect(arena.run.position, pausedPosition);
      final saveAndReturn = find.text('Salva e torna ai salvataggi');
      await tester.ensureVisible(saveAndReturn);
      await tester.tap(saveAndReturn);
      await tester.pumpAndSettle();

      final preferences = await SharedPreferences.getInstance();
      final saved = jsonDecode(preferences.getString(firstKey)!) as Map;
      expect(saved['name'], 'Runa');
      expect((saved['run'] as Map)['hero'], 'duplicatore');
      expect((saved['run'] as Map)['weapon'], 'arco');
      expect((saved['look'] as Map)['lineage'], 'goblin');
      expect((saved['look'] as Map)['body'], 'feminine');
      expect((saved['look'] as Map)['face'], 'strong');
      expect((saved['look'] as Map)['frame'], greaterThan(.50));
      expect(preferences.getString(oldDungeonKey), 'salvataggio precedente');
      expect(preferences.getString(corruptKey), 'dati non leggibili');
      await tester.tap(find.text('Continua'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.textContaining('Runa · '), findsOneWidget);
      final resumed = tester
          .widget<OculumLiteArena>(find.byType(OculumLiteArena))
          .run;
      expect(
        tester
            .widget<OculumLiteArena>(find.byType(OculumLiteArena))
            .appearance!
            .lineage,
        OculumLiteLineage.goblin,
      );
      final look = tester
          .widget<OculumLiteArena>(find.byType(OculumLiteArena))
          .appearance!;
      expect(look.body, OculumLiteBody.feminine);
      expect(look.face, OculumLiteFace.strong);
      expect(look.sameAs(preview.appearance!), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Silenzia tutto'), findsOneWidget);
      expect(find.byType(Slider), findsNWidgets(2));
      await tester.tap(find.text('Riprendi'));
      await tester.pump();
      final ally = LiteClone(
        resumed.position + const Point<double>(0, 1),
        0,
        LiteWeapon.guanti,
        maxHp: 10,
      )..downRemaining = LiteRun.allyRescueWindow;
      resumed.clones.add(ally);
      expect(
        resumed.attack(resumed.position + const Point<double>(1, 0)),
        true,
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyR);
      await tester.pump(const Duration(milliseconds: 20));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyR);
      await tester.pump();
      expect(resumed.rescuing, isFalse);
      expect(ally.down, isTrue);
      expect(resumed.arrows, LiteRun.bowCapacity - 1);
      final action = find.text('Tieni R · Soccorri');
      expect(action, findsOneWidget);
      final touch = await tester.startGesture(tester.getCenter(action));
      for (var frame = 0; frame < 38; frame++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
      await touch.up();
      await tester.pump();
      expect(ally.hp, 3);
      expect(resumed.arrows, LiteRun.bowCapacity);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
}
