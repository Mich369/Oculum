import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';
import 'package:oculum_rl/services/oculum_lite_grimoire.dart';
import 'package:oculum_rl/services/oculum_lite_saves.dart';
import 'package:oculum_rl/services/oculum_save_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const first = 'duplicatore-originale';
  const second = 'personaggio-creato-in-seguito';
  const hero = LiteHero.duplicatore;

  test('a legacy profile keeps its original actions and other progress', () {
    final encoded = jsonEncode({
      'schema': 1,
      'floor': 6,
      'scostubandito': true,
      'upgrades': {'portata': 1},
    });
    final profile = OculumLiteProgress.decode(encoded);
    expect(profile.grimoire.learnedArts, isEmpty);
    expect(profile.bestClearedFloor, 6);
    expect(profile.canPlay(LiteHero.scostubandito), isTrue);
    expect(profile.upgrades[LitePermanentUpgrade.portata], 1);
    expect(profile.grimoire.loadoutFor(first, hero).actions, [
      const LiteGrimoireAction.weapon(),
      const LiteGrimoireAction.talent(),
      const LiteGrimoireAction.scroll(),
      null,
      null,
      null,
    ]);
    expect(jsonDecode(profile.encode()).containsKey('grimoire'), isFalse);
  });

  test(
    'all six slots independently accept learned Art including weapon and Q',
    () {
      const sixArts = [
        LiteLearnedArt.plasma,
        LiteLearnedArt.falci,
        LiteLearnedArt.linfa,
        LiteLearnedArt.brace,
        LiteLearnedArt.basalto,
        LiteLearnedArt.ecoVelata,
      ];
      var profile = const OculumLiteProgress();
      for (final (slot, art) in sixArts.indexed) {
        final selected = LiteGrimoireAction.art(art);
        profile = profile
            .learnArt(art)
            .equipGrimoire(first, hero, slot, selected);
      }
      final loaded = OculumLiteProgress.decode(profile.encode());
      expect(loaded.grimoire.learnedArts, sixArts.toSet());
      expect(
        loaded.grimoire.loadoutFor(first, hero).actions,
        sixArts.map(LiteGrimoireAction.art).toList(),
      );
      expect(loaded.grimoire.equippableArts(hero), sixArts.toSet());

      const newSlot = LiteGrimoireAction.art(LiteLearnedArt.ecoVelata);
      final other = loaded.equipGrimoire(second, hero, 0, newSlot);
      final respecified = other.equipGrimoire(first, hero, 0, null);
      expect(
        respecified.grimoire.loadoutFor(first, hero).actions.first,
        isNull,
      );
      expect(
        respecified.grimoire.loadoutFor(second, hero).actions.first,
        newSlot,
      );
      expect(respecified.grimoire.learnedArts, sixArts.toSet());
    },
  );

  test('rejects locked Art, invalid slots and cross-hero fixed skills', () {
    const empty = OculumLiteProgress();
    const availableNotLearned = LiteGrimoireAction.art(LiteLearnedArt.linfa);
    const fixedArt = LiteGrimoireAction.art(LiteLearnedArt.pattuglia);
    const guard = LiteHero.guardiaSolare;

    expect(
      empty.equipGrimoire(first, hero, 4, availableNotLearned),
      same(empty),
    );
    expect(empty.equipGrimoire(first, hero, 0, fixedArt), same(empty));
    expect(empty.learnArt(LiteLearnedArt.pattuglia), same(empty));
    expect(empty.equipGrimoire(first, guard, 6, fixedArt), same(empty));
    expect(empty.equipGrimoire(first, guard, -1, fixedArt), same(empty));
    expect(empty.equipGrimoire('', guard, 5, fixedArt), same(empty));

    final assigned = empty.equipGrimoire(second, guard, 5, fixedArt);
    final loaded = OculumLiteProgress.decode(assigned.encode());
    expect(loaded.grimoire.learnedArts, isEmpty);
    expect(loaded.grimoire.equippableArts(guard), {LiteLearnedArt.pattuglia});
    expect(loaded.grimoire.equippableArts(hero), isEmpty);
    expect(loaded.grimoire.loadoutFor(second, guard).actions.last, fixedArt);
    expect(loaded.grimoire.loadoutFor(second, hero).actions.last, isNull);
  });

  test('bad or obsolete nested entries preserve valid slot positions', () {
    final profile = OculumLiteProgress.decode(
      jsonEncode({
        'schema': 1,
        'floor': 0,
        'grimoire': {
          'schema': 1,
          'learned': ['pattuglia', 'linfa', 'missing', 'linfa'],
          'characters': {
            first: {
              'hero': hero.name,
              'slots': [
                'art:linfa',
                'art:pattuglia',
                'later',
                'scroll',
                null,
                9,
              ],
            },
            'obsoleteCharacter': {
              'hero': 'later',
              'slots': List.filled(6, null),
            },
            second: {
              'hero': hero.name,
              'slots': ['art:linfa'],
            },
          },
        },
      }),
    );
    expect(profile.bestClearedFloor, 0);
    expect(profile.grimoire.learnedArts, {LiteLearnedArt.linfa});
    expect(profile.grimoire.loadoutFor(first, hero).actions, [
      const LiteGrimoireAction.art(LiteLearnedArt.linfa),
      null,
      null,
      const LiteGrimoireAction.scroll(),
      null,
      null,
    ]);
    expect(
      profile.grimoire.loadoutFor(second, hero).actions.first,
      const LiteGrimoireAction.weapon(),
    );
  });

  test(
    'the same save store persists, keeps upgrades and recovers the grimoire',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = OculumLiteSaveStore(prefs);
      final start = (await store.readProgress())
          .record(6, {LiteHero.scostubandito})
          .learnArt(LiteLearnedArt.filoOmbra)
          .equipGrimoire(
            first,
            hero,
            0,
            const LiteGrimoireAction.art(LiteLearnedArt.filoOmbra),
          );
      await store.writeProgress(start);
      final loaded = await store.readProgressWithSlots();
      final freshRun = LiteRun(seed: 574, hero: hero, weapon: LiteWeapon.arco)
        ..stage = 7
        ..stageClear = true;
      final advanced = loaded
          .recordRun(freshRun)
          .buy(LitePermanentUpgrade.portata)!;
      await store.writeProgress(advanced);
      expect((await store.readProgress()).bestClearedFloor, 7);
      expect((await store.readProgress()).grimoire.learnedArts, {
        LiteLearnedArt.filoOmbra,
      });
      await prefs.setString(
        oculumProfiledStorageKey('oculum_lite_progress'),
        '{',
      );
      final recovered = await store.readProgress();
      expect(recovered.bestClearedFloor, 6);
      expect(
        recovered.grimoire.loadoutFor(first, hero).actions.first,
        const LiteGrimoireAction.art(LiteLearnedArt.filoOmbra),
      );
    },
  );
}
