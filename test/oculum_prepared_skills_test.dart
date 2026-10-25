import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test(
    'Parasite medicine thresholds and accumulating penalties match confirmed rules',
    () {
      expect(
        [
          for (var reflex = 9; reflex <= 15; reflex++)
            oculumParasiteMedicineThreshold(reflex),
        ],
        [14, 14, 15, 15, 16, 17, 18],
      );
      expect(
        [
          for (var turn = 0; turn < 5; turn++)
            oculumParasiteEscapePenalty(turn),
        ],
        [0, 3, 6, 9, 9],
      );
    },
  );

  test('Dust crystals gate drop, exact single draw and independent loot', () {
    final counts = <String, int>{};
    for (var roll = 0; roll < 100; roll++) {
      final item = oculumDustCrystalDrop(
        monsterLevel: 3,
        monsterGrade: 0,
        rollerLevel: 0,
        dropTotal: 23,
        percentile: roll,
        killId: 'enemy',
      );
      final key = item == null ? 'none' : '${item.craftData['dustCrystal']}';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    expect(counts, {'piccolo': 25, 'medio': 15, 'grande': 6, 'none': 54});
    expect(
      oculumDustCrystalDrop(
        monsterLevel: 2,
        monsterGrade: 0,
        rollerLevel: 0,
        dropTotal: 100,
        percentile: 0,
        killId: 'x',
      ),
      isNull,
    );
    expect(
      oculumDustCrystalDrop(
        monsterLevel: 3,
        monsterGrade: 1,
        rollerLevel: 0,
        dropTotal: 24,
        percentile: 0,
        killId: 'x',
      ),
      isNull,
    );
    expect(oculumDustCrystalYield('piccolo', 3), 3);
    expect(oculumDustCrystalYield('medio', 6), 8);
    expect(oculumDustCrystalYield('grande', 10), 12);
    final allies = oculumBoardAfterFight([
      {'id': 'party'},
      {'id': 'npc', 'side': 'ally'},
      {'id': 'enemy', 'side': 'enemy'},
    ]);
    expect(allies.map((e) => e['id']), ['party', 'npc']);
  });

  test('Fato uses exact 6/14/30/40/9/1 buckets and rounds shields up', () {
    final buckets = <String, int>{};
    for (var roll = 0; roll < 100; roll++) {
      final reward = oculumFateGradeReward(roll, currentHp: 101);
      final key = reward.keys.join(',');
      buckets[key] = (buckets[key] ?? 0) + 1;
    }
    expect(buckets.values.toList(), [6, 14, 30, 40, 9, 1]);
    expect(oculumFateGradeReward(5), isEmpty);
    expect(oculumFateGradeReward(6), {'ispirazioni': 1});
    expect(oculumFateGradeReward(19), {'ispirazioni': 1});
    final jackpot = oculumFateGradeReward(99, currentHp: 101);
    expect(jackpot['scudo'], 21);
    expect(jackpot['scudoOculum'], 6);
    expect(jackpot['schivateOculumBonus'], 1);
  });

  test(
    'Only selected skills charge, and their charge schedule survives JSON',
    () {
      final profiles = oculumPreparedScrollProfiles();
      expect(profiles.length, 6);
      expect(
        profiles.where((p) => p.effects.single.chargeOculumPerTurn > 0).length,
        2,
      );
      for (final profile in profiles.where(
        (p) => p.effects.single.chargeOculumPerTurn > 0,
      )) {
        final effect = OculumStructuredEffect.fromJson(
          profile.effects.single.toJson(),
        );
        expect(effect.chargeOculumPerTurn, 1);
        expect(effect.chargeDamageSteps, [40, 80, 120, 180]);
      }
    },
  );
  test(
    'Concentration uses percentage points, scroll-only grade and higher-grade pressure',
    () {
      expect(oculumPreparedKeepChance(concentration: 3), 3);
      expect(
        oculumPreparedKeepChance(concentration: 100, attackerGrade: 2),
        90,
      );
      expect(
        oculumPreparedKeepChance(concentration: 100, attackerGrade: 3),
        80,
      );
      expect(oculumPreparedKeepChance(concentration: 2, attackerGrade: 12), 0);
      expect(oculumPreparedKeepChance(concentration: 99, scrollGrade: 12), 100);
      final profile = oculumPreparedScrollProfiles().first;
      final scroll =
          oculumTechniqueScrollItem(profile, 3).craftData['scroll'] as Map;
      final data = Map<String, dynamic>.from(scroll);
      expect(oculumScrollCombatEffects(data).single.sourceScrollGrade, 3);
      expect(
        oculumScrollCombatEffects({
          ...data,
          'learned': true,
        }).single.sourceScrollGrade,
        0,
      );
      final copy = OculumStructuredEffect.fromJson(
        OculumStructuredEffect(
          type: 'preparazione',
          sourceScrollGrade: 4,
        ).toJson(),
      );
      expect(copy.sourceScrollGrade, 4);
    },
  );
  test(
    'Stat-paid positive effects are slightly stronger, penalties and durations unchanged',
    () {
      final boosted = oculumStatPaidEffect(
        OculumStructuredEffect(type: 'danno', valueExpression: '4'),
        'volonta',
      );
      expect(oculumEvaluateStructuredEffectValue(boosted, variables: {}), 5);
      final penalty = oculumStatPaidEffect(
        OculumStructuredEffect(
          type: 'difesa',
          valueExpression: '-2',
          duration: '1',
        ),
        'materia',
      );
      expect(penalty.valueExpression, '-2');
      expect(penalty.duration, '1');
    },
  );
  test(
    'Imported monster costs remain visible and parseable, including legacy blank text',
    () {
      for (final monster in defaultMonsterBookEntries) {
        final art = oculumMonsterBookArt(monster);
        for (final skill in art.skills) {
          final converted = oculumEquipmentAbilityFromArt(skill);
          for (var i = 0; i < 3; i++) {
            final form = converted.forme[i];
            expect(
              form.costo,
              isNotEmpty,
              reason: '${monster.id}/${skill.nome}',
            );
            expect(
              form.costoStrutturato!.resource,
              oculumNormalizeEffectResource(
                skill.risorsaCostoPerLivello(i + 1),
              ),
            );
            final restored = CharacterSkillForm.fromJson({
              ...form.toJson(),
              'costo': '',
            });
            expect(restored.costo, isNotEmpty);
            final custom = CharacterSkillForm.fromJson({
              ...form.toJson(),
              'costo': 'Costo personalizzato',
            });
            expect(custom.costo, 'Costo personalizzato');
          }
        }
      }
    },
  );
}
