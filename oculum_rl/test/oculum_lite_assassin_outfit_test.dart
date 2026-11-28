import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';
import 'package:oculum_rl/pages/oculum_lite_page.dart';
import 'package:oculum_rl/services/oculum_lite_saves.dart';
import 'package:oculum_rl/services/oculum_save_profile.dart';
import 'package:oculum_rl/widgets/oculum_lite_arena.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _right = Point<double>(1, 0);
const _pistol = LiteWeapon.pistolaRicognitore;

class _PreferencesOnlyPaths extends PathProviderPlatform {
  @override
  Future<String?> getApplicationSupportPath() async =>
      throw MissingPluginException();
}

LiteRun _run({bool tactical = true, int players = 1}) =>
    LiteRun(
        seed: 68,
        hero: LiteHero.assassino,
        weapon: LiteWeapon.arco,
        assassinTactical: tactical,
        playerCount: players,
      )
      ..enemies.clear()
      ..fauna.clear()
      ..obstacles.clear()
      ..position = const Point(8, 9);

void main() {
  test('only the tactical Assassin starts with the special pistol', () {
    final tactical = _run();
    final canon = _run(tactical: false);
    expect(tactical.assassinTactical, isTrue);
    expect(tactical.weapon, _pistol);
    expect(tactical.ownedWeapons, {_pistol});
    expect(tactical.hp, 50);
    expect(canon.weapon, LiteWeapon.doppieLame);
    final other = LiteRun(
      seed: 68,
      hero: LiteHero.evasore,
      weapon: _pistol,
      assassinTactical: true,
    );
    expect(other.assassinTactical, isFalse);
    expect(other.weapon, LiteWeapon.arco);

    final altered = tactical.toJson()..['weapon'] = 'doppieLame';
    expect(LiteRun.fromJson(altered).weapon, _pistol);
    final invalid = canon.toJson()..['weapon'] = _pistol.name;
    expect(LiteRun.fromJson(invalid).weapon, LiteWeapon.doppieLame);
  });

  test(
    'normal fire and Punto cieco make one shot; blades stay on Right and Open',
    () {
      final run = _run();
      final aim = run.position + _right;
      expect(run.attack(aim), isTrue);
      final shot = run.projectiles.single;
      expect(shot.remaining, closeTo(7.8, .001));
      expect(shot.kind, LiteProjectileKind.rifleBullet);
      expect(shot.damage, run.weaponDamage);
      expect(run.attack(aim), isFalse);
      expect(run.weaponArtLabel(), 'Punto cieco');
      expect(run.useWeaponArt(aim), isTrue);
      expect(run.projectiles, hasLength(2));
      expect(run.projectiles.last.damage, greaterThan(shot.damage));

      final front = LiteEnemy(
        801,
        LiteEnemyKind.slime,
        run.position + _right,
        240,
      );
      final behind = LiteEnemy(
        802,
        LiteEnemyKind.slime,
        run.position - _right,
        240,
      );
      run.enemies.addAll([front, behind]);
      expect(run.special(aim), isTrue);
      expect(front.hp, lessThan(240));
      expect(behind.hp, lessThan(240));
      expect(run.projectiles, hasLength(2));
      expect(run.useOpen(aim), isTrue);
      expect(run.weapon, _pistol);
      expect(run.clones, hasLength(2));
      expect(
        run.clones.map((copy) => copy.weapon),
        everyElement(LiteWeapon.doppieLame),
      );
    },
  );

  test('the host creates a tactical guest and preserves it in its frames', () {
    final run = _run(tactical: false, players: 2);
    expect(
      run.addCoopFighter(
        'guest',
        'G',
        LiteHero.assassino,
        LiteWeapon.arco,
        assassinTactical: true,
      ),
      isTrue,
    );
    final guest = run.coopFighter('guest')!
      ..position = const Point(13, 9)
      ..cooldown = 0;
    expect(guest.assassinTactical, isTrue);
    expect(guest.weapon, _pistol);
    expect(run.weapon, LiteWeapon.doppieLame);
    expect(
      run.setCoopControls(
        'guest',
        const Point(0, 0),
        guest.position + _right,
        attack: true,
      ),
      isTrue,
    );
    run.step(.02);
    expect(run.projectiles.single.sourceCloneId, guest.id);
    expect(run.projectiles.single.kind, LiteProjectileKind.rifleBullet);

    final frame = LiteRun.fromJson(run.toJson(includeEffects: true));
    final restored = frame.coopFighter('guest')!;
    expect(restored.assassinTactical, isTrue);
    expect(restored.weapon, _pistol);
    expect(restored.ownedWeapons, {_pistol});
    expect(frame.weapon, LiteWeapon.doppieLame);
  });

  test('only the current look can define the primary; fusion keeps it', () {
    final run = _run()
      ..restHub = true
      ..obser = 500;
    run.ownedWeapons.add(LiteWeapon.doppieLame);
    expect(run.equipFromForge(LiteWeapon.doppieLame), isFalse);
    expect(run.fuseWeapons(LiteWeapon.doppieLame, _pistol), isFalse);
    expect(run.fuseWeapons(_pistol, LiteWeapon.doppieLame), isTrue);
    expect(run.weapon, _pistol);
    expect(run.fusedWeapon(), LiteWeapon.doppieLame);
    final original = LiteRun.fromJson(run.toJson());
    expect(original.fusedWeapon(), LiteWeapon.doppieLame);
  });

  test('slot migration keeps the cosmetic and its weapon in agreement', () {
    final source = OculumLiteSaveSlot(
      run: _run(),
      name: 'Assassino',
      appearance: const OculumLiteAppearance(),
      attempt: 1,
      startingWeapon: LiteWeapon.doppieLame,
      startingBiome: LiteBiome.campo,
    );
    final restored = OculumLiteSaveSlot.decode(source.encode());
    expect(restored.appearance.inkFinish, LiteInkFinish.tattica);
    expect(restored.startingWeapon, _pistol);

    final data = jsonDecode(source.encode()) as Map<String, dynamic>;
    (data['run'] as Map).remove('assassinTactical');
    data['look'] = {'inkFinish': 'tattica'};
    final legacy = OculumLiteSaveSlot.decode(jsonEncode(data));
    expect(legacy.run.assassinTactical, isTrue);
    expect(legacy.run.weapon, _pistol);
    (data['run'] as Map)['assassinTactical'] = false;
    final canonical = OculumLiteSaveSlot.decode(jsonEncode(data));
    expect(canonical.run.weapon, LiteWeapon.doppieLame);
    expect(canonical.appearance.inkFinish, LiteInkFinish.canonica);
  });

  testWidgets(
    'Ricognitore appears for an unlocked Assassin and starts the first arena with its pistol',
    (tester) async {
      final originalPaths = PathProviderPlatform.instance;
      PathProviderPlatform.instance = _PreferencesOnlyPaths();
      addTearDown(() => PathProviderPlatform.instance = originalPaths);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(500, 960);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      SharedPreferences.setMockInitialValues({
        oculumProfiledStorageKey(
          'oculum_lite_progress',
        ): const OculumLiteProgress(unlockedHeroes: {LiteHero.assassino})
            .encode(),
      });
      await tester.pumpWidget(const MaterialApp(home: OculumLitePage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('oculum-lite-play')));
      await tester.pumpAndSettle();
      final tactical = find.widgetWithText(ChoiceChip, 'Ricognitore di cenere');
      expect(tactical, findsNothing);
      final assassin = find.widgetWithText(ChoiceChip, 'Assassino');
      await tester.ensureVisible(assassin);
      await tester.tap(assassin);
      await tester.pumpAndSettle();
      await tester.ensureVisible(tactical);
      await tester.tap(tactical);
      await tester.pumpAndSettle();
      final previewFinder = find.byType(OculumLiteHeroPreview);
      await tester.scrollUntilVisible(
        previewFinder,
        -140,
        scrollable: find.byType(Scrollable).first,
      );
      final preview = tester.widget<OculumLiteHeroPreview>(previewFinder);
      expect(preview.weapon, _pistol);
      expect(preview.appearance!.inkFinish, LiteInkFinish.tattica);

      final play = find.byKey(const ValueKey('oculum-lite-start-run'));
      await tester.ensureVisible(play);
      await tester.tap(play);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final arena = tester.widget<OculumLiteArena>(
        find.byType(OculumLiteArena),
      );
      expect(arena.run.stage, 0);
      expect(arena.run.weapon, _pistol);
      expect(arena.run.assassinTactical, isTrue);
      expect(arena.appearance!.inkFinish, LiteInkFinish.tattica);
    },
  );
}
