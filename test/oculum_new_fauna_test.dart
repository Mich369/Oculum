import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

const added = [
  'zombie_acido',
  'cavaliere_non_ritorno',
  'deadly_sins',
  'feralis_ancestrale',
  'scostubanditi_empatico',
  'granscostumato_empatico',
  'bramble',
  'thunderbird',
  'scostubanditi',
  'fuocherelli',
  'feralis',
  'granscostumato',
  'sempre_verde',
  'lavastrello',
  'adoratore_bestia',
  'teschio_monaco',
  'teschio_quattro_lame',
  'teschio_mostruoso',
  'ogor',
  'teirak',
  'laer',
  'torretta_oculum',
  'manichino_spada',
];
void main() {
  test(
    'acid zombie and non-return knight keep their distinct combat and drops',
    () {
      final zombie = monsterBookEntryById('zombie_acido')!;
      final knight = monsterBookEntryById('cavaliere_non_ritorno')!;
      expect(zombie.planeIds, contains('morti'));
      expect(knight.stats['criticalShield'], 3);
      expect(knight.stats['oculumDodge'], 2);
      expect(knight.encounterRules['criticalShields'], 3);
      expect(knight.weaponTags, contains('spadone'));
      for (final m in [zombie, knight]) {
        final anatomy = oculumMonsterPrecisionAnatomy(m);
        expect(anatomy.where((p) => p['group'] == 'arms'), hasLength(2));
        expect(anatomy.where((p) => p['group'] == 'legs'), hasLength(2));
        expect(anatomy.where((p) => p['weak'] == true), hasLength(1));
      }
      final knightAnatomy = oculumMonsterPrecisionAnatomy(knight);
      expect(knightAnatomy.where((p) => p['group'] == 'eyes'), isEmpty);
      expect(
        knightAnatomy.singleWhere((p) => p['weak'] == true)['id'],
        'chest_eye',
      );
      final acid = oculumPlanarTechnique('zombie_acid_vomit')!;
      expect(acid.costResource, 'materia');
      expect(acid.forms.first.any((e) => e.target == 'corrosione_acida'), true);
      for (final m in [zombie, knight]) {
        final drops = oculumPlanarNaturalDrops(
          m,
          5,
          0,
          20,
          'drop:${m.id}',
          dropTotal: 40,
        )!;
        expect(drops.any((i) => i.craftData['scroll'] != null), true);
        final art = oculumMonsterBookArt(m);
        expect(
          art.openSkillEffects.single.valueExpression,
          contains('monster_open_bonus'),
        );
        expect(art.openSkillCooldown!.amount, 4);
      }
    },
  );
  test(
    'empathic variants keep nonlethal rules and DeadlySins starts with enough Oculum',
    () {
      for (final id in ['scostubanditi_empatico', 'granscostumato_empatico']) {
        final m = monsterBookEntryById(id)!;
        expect(m.encounterRules['nonLethal'], isTrue);
        expect(
          m.encounterRules['initiativeName'].toString(),
          isNot(contains('Empatico')),
        );
        expect(m.encounterRules['robberyPercent'], 50);
        expect(m.encounterRules['empathyBonus'], 6);
      }
      final deadly = monsterBookEntryById('deadly_sins')!;
      expect(deadly.stats['level'], 0);
      expect(deadly.stats['oculum'], 13);
      final power = oculumPlanarTechnique('deadly_empowered')!;
      expect(power.minimums, [9, 13, 16]);
      expect(power.cooldowns, [9, 9, 9]);
      expect(oculumScostuRobbedObser(101, percent: 50), 50);
    },
  );
  testWidgets(
    'empathic death deducts personal Obser once and keeps vendetta until rest',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 1000),
      );
      state.datiCaricati = false;
      final p = OculumPerformanceProbe(state);
      final sheet = p.snapshot()
        ..['id'] = 'KillerOcu:3690AAAA'
        ..['sheetTag'] = 'KillerOcu:3690AAAA'
        ..['obser'] = '100'
        ..['planarRuntime'] = <String, dynamic>{};
      state.schedePersonaggio.clear();
      state.schedePersonaggio.add(sheet);
      state.schedaCorrente = 0;
      p.load(sheet);
      const enemy = {
        'id': 'empathic-death',
        'monsterSheetTag': 'EnemyOcu:3690BBBB',
        'killerTag': 'KillerOcu:3690AAAA',
        'monsterBookId': 'granscostumato_empatico',
        'level': 5,
      };
      p.confirmFaunaKills([enemy]);
      expect(state.obserController.text, '75');
      expect(p.snapshot()['planarRuntime']['banditVendetta'], isTrue);
      p.confirmFaunaKills([enemy]);
      expect(state.obserController.text, '75');
      p.faunaLongRest();
      expect(p.snapshot()['planarRuntime']['banditVendetta'], isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
  test(
    'all authored creatures have owned editable techniques with valid costs and Open',
    () {
      for (final id in added) {
        final m = monsterBookEntryById(id)!;
        expect(
          m.spriteAssetPath,
          isEmpty,
          reason: 'reference is description only: $id',
        );
        expect(m.descIt.length, greaterThan(140));
        expect(
          defaultMonsterBookEntries.where((e) => e.id == id),
          hasLength(1),
        );
        final art = oculumMonsterBookArt(m);
        expect(art.openName, isNotEmpty, reason: id);
        expect(art.openSkillEffects, isNotEmpty, reason: id);
        expect(art.openBuffEffects, isNotEmpty, reason: id);
        final skills = oculumMonsterBookSkills(m);
        for (final move in m.skillIds) {
          final t = oculumPlanarTechnique(move)!;
          expect(
            [...skills.map((s) => s.nome), ...art.skills.map((s) => s.nome)],
            contains(t.name),
            reason: '$id owns $move',
          );
          for (var i = 0; i < 3; i++) {
            for (final effect in t.forms[i]) {
              expect(
                oculumStructuredEffectTypes,
                contains(effect.type),
                reason: '$move uses supported native effects',
              );
            }
            expect(t.minimums[i], greaterThanOrEqualTo(0), reason: move);
            expect(
              t.maximums[i],
              greaterThanOrEqualTo(t.minimums[i]),
              reason: move,
            );
            expect(t.cooldowns[i], greaterThanOrEqualTo(0), reason: move);
          }
          if (!oculumMonsterBookSkillIsPassive(move)) {
            expect(t.cooldowns.any((n) => n > 0), isTrue, reason: move);
          }
        }
      }
      expect(monsterBookEntryById('teschio_mostruoso')!.stats['oculum'], 0);
      expect(monsterBookEntryById('feralis')!.isMiniBoss, isTrue);
      expect(
        monsterBookEntryById('teschio_quattro_lame')!.skillIds,
        contains('bone_ground_spikes'),
      );
    },
  );
  test(
    'exact total thresholds and intact or broken body gate special loot',
    () {
      List<InventoryItem> loot(
        String id,
        int total, {
        Map history = const {},
        int die = 12,
      }) => oculumGenerateMonsterLoot(
        monster: monsterBookEntryById(id)!,
        level: 5,
        grade: 1,
        random: Random(9),
        killId: 'test:$id:$total',
        dropTotal: total,
        naturalDropRoll: die,
        combatHistory: history,
      );
      for (final r in [
        ('sempre_verde', 36, 'evergreen_leaves'),
        ('teschio_monaco', 39, 'monk_dragon'),
        ('teschio_quattro_lame', 40, 'bone_four_slash'),
        ('ogor', 46, 'ogor_ray'),
      ]) {
        expect(
          loot(
            r.$1,
            r.$2 - 1,
          ).any((i) => i.monsterLoot['sourceSkillId'] == r.$3),
          isFalse,
        );
        expect(
          loot(r.$1, r.$2).any((i) => i.monsterLoot['sourceSkillId'] == r.$3),
          isTrue,
        );
      }
      expect(loot('ogor', 10).any((i) => i.nome == 'Nucleo di Oculum'), isTrue);
      expect(
        loot(
          'ogor',
          10,
          history: {'ogorCoreHits': 1},
        ).any((i) => i.nome == 'Nucleo di Oculum'),
        isFalse,
      );
      expect(
        loot(
          'teschio_quattro_lame',
          10,
          history: {'boneBrokenArms': 3},
        ).any((i) => i.nome == 'Spada Osso'),
        isFalse,
      );
      expect(
        loot(
          'teschio_quattro_lame',
          10,
          history: {'boneBrokenArms': 4},
        ).any((i) => i.nome == 'Spada Osso'),
        isTrue,
      );
      expect(
        loot(
          'sempre_verde',
          10,
          history: {'soulOnly': true},
        ).any((i) => i.nome == 'Costume dei Sempre Verde'),
        isTrue,
      );
    },
  );
  test(
    'kill counter survives species reward and deduplicates exact bodies',
    () {
      const enemy = {
        'id': 'a',
        'monsterBookId': 'lavastrello',
        'monsterSheetTag': 'batA',
      };
      final one = oculumRecordMonsterKills({}, [enemy], 'fight');
      expect(one['lavastrello']['count'], 1);
      expect(
        oculumRecordMonsterKills(one, [enemy], 'fight')['lavastrello']['count'],
        1,
      );
      expect(
        oculumRecordMonsterKills(one, [
          {...enemy, 'id': 'b', 'monsterSheetTag': 'batB'},
        ], 'fight')['lavastrello']['count'],
        2,
      );
    },
  );
  test(
    'Ki progression, leaf packets, fury and nests obey confirmed boundaries',
    () {
      expect(oculumMortalKiAmount(35, 6), 5);
      expect(oculumMortalKiAmount(35, 3), 11);
      expect(
        [for (var die = 1; die <= 10; die++) oculumMortalKiHuntBonus(die)],
        [5, 5, 5, 5, 5, 10, 10, 10, 10, 10],
      );
      expect(oculumEvergreenLeafDamage(20, 40), 120);
      expect(oculumFeralisDamage(20, 2, true), 50);
      expect(oculumFeralisDamage(20, 2, false), 20);
      expect(oculumLavastrelloNestHp(3), 45);
      expect(
        oculumLavastrelloNestCanSpawn({
          'currentHp': 1,
          'lavastrelloSpawned': 4,
        }),
        isTrue,
      );
      expect(
        oculumLavastrelloNestCanSpawn({
          'currentHp': 1,
          'lavastrelloSpawned': 5,
        }),
        isFalse,
      );
      expect(
        oculumLavastrelloNestCanSpawn({
          'currentHp': 0,
          'lavastrelloSpawned': 0,
        }),
        isFalse,
      );
      expect(oculumFuocherelliRevivalHp(100), 20);
      expect(oculumFuocherelliRevivalHp(10), 10);
    },
  );
  testWidgets('green Ki pool is saved, spent and sealed without losing it', (
    tester,
  ) async {
    final dynamic state = await fixtures.mountSheet(
      tester,
      const Size(1440, 1000),
    );
    final p = OculumPerformanceProbe(state);
    state.datiCaricati = false;
    if (state.schedePersonaggio.isEmpty) {
      final s = p.snapshot()..['sheetTag'] = 'KiTesterOcu:3690AAAA';
      state.schedePersonaggio.add(s);
      state.schedaCorrente = 0;
      p.load(s);
    }
    final s = p.snapshot()
      ..['currentOculum'] = '60'
      ..['oculum'] = '60'
      ..['planarRuntime'] = <String, dynamic>{
        'mortalKi': 12,
        'mortalKiMaximum': 12,
      };
    state.schedePersonaggio[state.schedaCorrente] = s;
    p.load(s);
    expect(p.kiAmount(), 12);
    expect(p.spendKi(5), 5);
    expect(p.kiAmount(), 7);
    final saved = p.snapshot();
    state.schedePersonaggio[state.schedaCorrente] = saved;
    p.load(saved);
    expect(p.kiAmount(), 7);
    final sealed = <String, dynamic>{
      ...saved,
      'planarRuntime': {'mortalKi': 7, 'mortalKiLock': 1},
    };
    state.schedePersonaggio[state.schedaCorrente] = sealed;
    p.load(sealed);
    expect(p.spendKi(1), 0);
    expect(p.kiAmount(), 7);
    p.tickPlanar();
    expect(p.spendKi(1), 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
