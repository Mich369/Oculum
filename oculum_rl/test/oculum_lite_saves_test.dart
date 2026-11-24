import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';
import 'package:oculum_rl/services/oculum_lite_save_files_native.dart';
import 'package:oculum_rl/services/oculum_lite_saves.dart';
import 'package:oculum_rl/widgets/oculum_lite_appearance.dart';
import 'package:shared_preferences/shared_preferences.dart';

OculumLiteSaveSlot _slot() {
  final run = LiteRun(
    seed: 29,
    hero: LiteHero.duplicatore,
    weapon: LiteWeapon.piccaOssidiana,
    biome: LiteBiome.postea,
  );
  run.clones.addAll([
    LiteClone(const Point(6, 11), 4, LiteWeapon.arco, id: 70),
    LiteClone(
      const Point(7, 11),
      0,
      LiteWeapon.balestraRunica,
      companion: LiteCompanion.drone,
      id: 71,
      maxHp: 38,
    )..downRemaining = 6.5,
  ]);
  return OculumLiteSaveSlot(
    run: run,
    name: 'Clonatrice',
    appearance: const OculumLiteAppearance(
      body: OculumLiteBody.feminine,
      lineage: OculumLiteLineage.goblin,
    ),
    attempt: 2,
    startingWeapon: LiteWeapon.arco,
    startingBiome: LiteBiome.postea,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a legacy slot can restore a missing look and its original arena', () {
    final source = jsonDecode(_slot().encode()) as Map<String, dynamic>;
    source.remove('look');
    source.remove('startingBiome');
    source.remove('startingWeapon');
    final arena = source['run'] as Map<String, dynamic>;
    arena['biome'] = LiteBiome.dungeon.name;
    final save = OculumLiteSaveSlot.decode(jsonEncode(source));
    expect(save.appearance.toJson(), const OculumLiteAppearance().toJson());
    expect(save.run.biome, LiteBiome.dungeon);
    expect(save.startingBiome, LiteBiome.postea);
    expect(save.startingWeapon, LiteWeapon.piccaOssidiana);
  });

  test('Gran Scostumato is granted for a won Scostubandito run only', () {
    final bandit = LiteRun(
      seed: 29,
      hero: LiteHero.scostubandito,
      weapon: LiteWeapon.arco,
    )..stage = LiteRun.finalStage;
    final other =
        LiteRun(seed: 29, hero: LiteHero.ashley, weapon: LiteWeapon.arco)
          ..stage = LiteRun.finalStage
          ..victorious = true;
    const empty = OculumLiteProgress();
    expect(empty.recordRun(bandit).canPlay(LiteHero.granScostumato), isFalse);
    expect(empty.recordRun(other).canPlay(LiteHero.granScostumato), isFalse);
    bandit.victorious = true;
    final progress = OculumLiteProgress.decode(
      empty.recordRun(bandit).encode(),
    );
    expect(progress.canPlay(LiteHero.granScostumato), isTrue);
    expect(progress.recordRun(other).canPlay(LiteHero.granScostumato), isTrue);
  });

  test(
    'native slots import legacy data and recover their own backup',
    () async {
      final slot = _slot();
      final key = oculumLiteSaveSlotKey(0);
      final legacy = slot.encode();
      SharedPreferences.setMockInitialValues({key: legacy});
      final prefs = await SharedPreferences.getInstance();
      final directory = await Directory.systemTemp.createTemp(
        'oculum-rl-save-',
      );
      final main = File.fromUri(directory.uri.resolve('$key.json'));
      final backup = File.fromUri(directory.uri.resolve('$key.backup.json'));
      addTearDown(() async {
        for (final file in [main, backup]) {
          if (await file.exists()) await file.delete();
        }
        await directory.delete();
      });
      final native = OculumLiteNativeSaveFiles(directory);
      final store = OculumLiteSaveStore(prefs, native);
      expect((await store.read(0)).encoded, legacy);
      expect(await main.exists(), isFalse);
      slot.run.obser = 36;
      final progress = slot.encode();
      await store.write(0, progress);
      expect(await main.readAsString(), progress);
      expect(await backup.readAsString(), legacy);
      expect(prefs.getString(key), legacy);

      slot.run.obser = 43;
      await store.write(0, slot.encode());
      expect(await backup.readAsString(), progress);
      await main.writeAsString('{"schema":1,"run":');
      final resumed = await OculumLiteSaveStore(null, native).read(0);
      expect(resumed.recovered, isTrue);
      expect(resumed.save!.run.obser, 36);
      expect(resumed.save!.run.weapon, LiteWeapon.piccaOssidiana);
      expect(resumed.save!.run.clones.first.hp, 4);
      expect(resumed.save!.run.clones.last.companion, LiteCompanion.drone);
      expect(resumed.save!.run.clones.last.downRemaining, 6.5);
      expect(resumed.save!.appearance.body, OculumLiteBody.feminine);
      await store.write(0, resumed.encoded!);
      expect((await store.read(0)).recovered, isFalse);
      expect(await backup.readAsString(), progress);
      expect((await store.read(1)).save, isNull);
    },
  );

  test(
    'browser preferences do not overwrite an entirely unreadable slot',
    () async {
      final key = oculumLiteSaveSlotKey(1);
      SharedPreferences.setMockInitialValues({
        key: 'interrotto',
        '$key.backup': 'danneggiato',
      });
      final prefs = await SharedPreferences.getInstance();
      final store = OculumLiteSaveStore(prefs);
      expect((await store.read(1)).unreadable, isTrue);
      await expectLater(store.write(1, _slot().encode()), throwsStateError);
      expect(prefs.getString(key), 'interrotto');
      expect(prefs.getString('$key.backup'), 'danneggiato');
      expect((await store.read(0)).unreadable, isFalse);
    },
  );

  test(
    'profile spends only earned sigils and freezes upgrades in each run',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = OculumLiteSaveStore(prefs);
      final cleared = _slot().run
        ..stage = 3
        ..stageClear = true
        ..achievements.add(LiteRun.unlockScostubandito);
      final progress = const OculumLiteProgress().recordRun(cleared);
      expect(progress.unspent, 2);
      expect(progress.recordRun(cleared), same(progress));
      final purchased = progress
          .buy(LitePermanentUpgrade.vita)!
          .buy(LitePermanentUpgrade.danni)!;
      expect(purchased.buy(LitePermanentUpgrade.oculum), isNull);
      await store.writeProgress(purchased);
      final reopened = await OculumLiteSaveStore(prefs).readProgress();
      expect(reopened.scostubanditoUnlocked, isTrue);
      expect(reopened.unspent, 0);
      final next = LiteRun(
        seed: 31,
        hero: LiteHero.scostubandito,
        weapon: LiteWeapon.arco,
        upgrades: reopened.upgrades,
      );
      expect(next.hp, 105);
      expect(next.weapon, LiteWeapon.fucileScostubandito);
      expect(next.weaponDamage, 14);
      expect(cleared.maxHp, 100);
      expect(LiteRun.fromJson(next.toJson()).maxHp, 105);
    },
  );
}
