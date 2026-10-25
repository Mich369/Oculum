import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_monster_theme.dart';

import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final monster = monsterBookEntryById('bramble')!;

  test(
    'Bramble has unique identity, editable costs, a passive and a powered Open',
    () {
      expect(
        defaultMonsterBookEntries.where((e) => e.id == 'bramble'),
        hasLength(1),
      );
      expect(monster.planeIds, contains('foresta_elementale'));
      expect(monster.damageResistancePresets['fuoco'], 'debolezza');
      final shield = oculumPlanarTechnique('bramble_thorn_shield')!;
      expect(shield.minimums, [2, 3, 4]);
      expect(shield.maximums, [2, 3, 4]);
      expect(shield.cooldowns, [3, 3, 3]);
      final passive = oculumMonsterBookSkills(
        monster,
      ).firstWhere((s) => s.nome == 'Sfida Ardua');
      expect(passive.passiva, isTrue);
      expect(
        passive.forme.every(
          (f) =>
              f.costoStrutturato == null ||
              f.costoStrutturato!.resource == 'nessuna',
        ),
        isTrue,
      );
      final art = oculumMonsterBookArt(monster);
      expect(art.openName, 'Cuore del roveto');
      expect(art.openBuffEffects.any((e) => e.target == 'resilienza'), isTrue);
      expect(
        art.openBuffEffects.any((e) => e.target == 'monster_open_power'),
        isTrue,
      );
      expect(
        art.openSkillEffects.single.valueExpression,
        contains('monster_open_bonus'),
      );
      expect(art.openSkillCooldown?.amount, 3);
    },
  );

  test(
    'natural drops use exact ranges and require a water finisher for Sfida Ardua',
    () {
      for (var die = 1; die <= 20; die++) {
        for (final element in ['acqua', 'fuoco', '']) {
          final loot = oculumGenerateMonsterLoot(
            monster: monster,
            level: 3,
            grade: 0,
            random: Random(1),
            killId: 'bramble:$die:$element',
            naturalDropRoll: die,
            dropTotal: die + 80,
            finishingElement: element,
          );
          final scrolls = loot
              .where((i) => i.monsterLoot.containsKey('sourceSkillId'))
              .toList();
          expect(scrolls.map((i) => i.monsterLoot['sourceSkillId']), [
            if (die == 20) 'bramble_thorn_shield',
            if (element == 'acqua' && die >= 10 && die <= 19)
              'bramble_arduous_challenge',
          ]);
          expect(
            loot.where((i) => i.monsterLoot['material'] == true).length,
            die >= 8 ? 1 : 0,
          );
        }
      }
    },
  );

  test('shield ignores heat and ranged hits do not retaliate', () {
    for (final element in ['fuoco', 'lava', 'plasma']) {
      expect(oculumBrambleHeatBypasses(element), isTrue);
    }
    expect(oculumBrambleHeatBypasses('acqua'), isFalse);
    expect(oculumBrambleMelee({'choice': 'schianto'}), isTrue);
    expect(oculumBrambleMelee({'choice': 'vc', 'ranged': true}), isFalse);
    expect(oculumBrambleMelee({'choice': 'precisione', 'melee': true}), isTrue);
    expect(oculumBrambleChallengeMatch(.5), 'resistenza');
    expect(oculumBrambleChallengeMatch(2), 'fragilita');
    for (final normal in [0.0, 1.0, -1.0, double.nan]) {
      expect(oculumBrambleChallengeMatch(normal), isEmpty);
    }
  });

  testWidgets(
    'barrier consumes only eligible damage and critical rewards expire at fight end',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 1000),
      );
      final probe = OculumPerformanceProbe(state);
      state.datiCaricati = false;
      if (state.schedePersonaggio.isEmpty) {
        final sheet = probe.snapshot()
          ..['sheetTag'] = 'BrambleTesterOcu:3690AAAA'
          ..['id'] = 'BrambleTesterOcu:3690AAAA';
        state.schedePersonaggio.add(sheet);
        state.schedaCorrente = 0;
        probe.load(sheet);
      }
      state.skills.add(
        oculumMonsterBookSkills(
          monster,
        ).firstWhere((s) => s.nome == 'Sfida Ardua')..equipaggiata = true,
      );
      final shield = oculumMonsterBookArt(
        monster,
      ).skills.firstWhere((s) => s.nome == 'Scudo di rovi');
      probe.applyEffects(shield.effettiEvoluzione(1));
      expect(probe.brambleAbsorb(9, 'fuoco'), 9);
      expect(probe.brambleAbsorb(9, 'lava'), 9);
      expect(probe.brambleAbsorb(9, 'plasma'), 9);
      expect(probe.brambleAbsorb(9, 'fisico', bypassShields: true), 9);
      expect(probe.brambleAbsorb(10, 'fisico'), 0);
      expect(probe.brambleAbsorb(10, 'fisico'), 8);
      final before = probe.coreStats();
      final attack = <String, dynamic>{
        'id': 'critical-1',
        'natural': 20,
        'attack': 28,
        'defense': 20,
        'brambleTargetMultiplier': .5,
      };
      expect(probe.brambleCritical(attack), isTrue);
      expect(probe.coreStats()['resilienza'], before['resilienza']! + 1);
      expect(probe.coreStats()['oculum'], before['oculum']! + 1);
      expect(probe.brambleCritical(attack), isFalse);
      expect(probe.brambleCritical({...attack, 'id': 'critical-2'}), isTrue);
      expect(probe.coreStats()['resilienza'], before['resilienza']! + 2);
      expect(
        probe.brambleCritical({
          ...attack,
          'id': 'fragile',
          'brambleTargetMultiplier': 2,
        }),
        isTrue,
      );
      final condition = state.activeConditions.firstWhere(
        (dynamic c) => c.conditionType == 'ricordo_vitale',
      );
      expect(condition.duration, 6);
      probe.finishPlanarFight();
      expect(probe.coreStats()['resilienza'], before['resilienza']);
      expect(probe.coreStats()['oculum'], before['oculum']);
      expect(probe.brambleAbsorb(10, 'fisico'), 10);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    },
  );

  test('Bramble theme illustration is bundled and relic is coherent', () async {
    final colors = oculumMonsterColors(monster);
    expect(colors.fold(0, (int n, c) => n + c.weight), 100);
    final theme = OculumMonsterTheme(monster, colors.first);
    expect(theme.shape, 'root');
    final data = await rootBundle.load(theme.illustration!);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    expect(frame.image.width, greaterThanOrEqualTo(1280));
    expect(frame.image.height, greaterThanOrEqualTo(700));
    frame.image.dispose();
    codec.dispose();
    expect(oculumMonsterThemeById(theme.id)?.name, theme.name);
  });
}
