import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  test('Strange Presence accepts either confirmed condition independently', () {
    expect(oculumCanAttackStrangePresence(madness: 2, days: 0), isTrue);
    expect(oculumCanAttackStrangePresence(madness: 0, days: 37), isTrue);
    expect(oculumCanAttackStrangePresence(madness: 1, days: 36), isFalse);
  });
  test(
    'mantle wear already weakens the current critical and cannot be negative',
    () {
      expect(
        oculumMantleProtection(
          initial: 90,
          wear: 0,
          critical: true,
          doubleCritical: true,
        ),
        70,
      );
      expect(
        oculumMantleProtection(
          initial: 90,
          wear: 20,
          critical: true,
          doubleCritical: false,
        ),
        65,
      );
      expect(
        oculumMantleProtection(
          initial: 45,
          wear: 40,
          critical: true,
          doubleCritical: true,
        ),
        0,
      );
      expect(
        oculumMagicShieldAbsorption(
          attack: 21,
          defense: 20,
          doubleCritical: false,
        ),
        greaterThan(
          oculumMagicShieldAbsorption(
            attack: 29,
            defense: 20,
            doubleCritical: false,
          ),
        ),
      );
      expect(
        oculumMagicShieldAbsorption(
          attack: 40,
          defense: 20,
          doubleCritical: true,
        ),
        25,
      );
    },
  );
  test(
    'Redcap corpse is cooked by fire and excluded on Fallen Eye natural 20',
    () {
      final mushroom = monsterBookEntryById('funghetto_cappuccio_rosso')!;
      List<InventoryItem> loot(int natural, String element) =>
          oculumGenerateMonsterLoot(
            monster: mushroom,
            level: 1,
            grade: 0,
            random: Random(5),
            killId: 'mushroom:$natural:$element',
            naturalDropRoll: natural,
            finishingElement: element,
          );
      expect(loot(1, 'taglio').single.craftData['cooked'], isFalse);
      expect(loot(1, 'fuoco').single.craftData['cooked'], isTrue);
      expect(loot(20, 'fuoco'), isEmpty);
      final saved = InventoryItem.fromJson(loot(1, 'fuoco').single.toJson());
      expect(saved.craftData['redcapBody'], isTrue);
    },
  );
  test(
    'Minor Construct scroll uses the normal Drop threshold, gear favors Shield',
    () {
      final construct = monsterBookEntryById('costrutto_minore')!;
      final threshold = oculumMonsterDropDifficulty(level: 2, grade: 0);
      List<InventoryItem> loot(int total) => oculumGenerateMonsterLoot(
        monster: construct,
        level: 2,
        grade: 0,
        random: Random(2),
        killId: 'construct:$total',
        naturalDropRoll: 12,
        dropTotal: total,
      );
      expect(
        loot(threshold - 1).where(
          (i) => i.monsterLoot['sourceSkillId'] == 'minor_construct_summon',
        ),
        isEmpty,
      );
      expect(
        loot(threshold).where(
          (i) => i.monsterLoot['sourceSkillId'] == 'minor_construct_summon',
        ),
        hasLength(1),
      );
      final equipment = oculumMonsterEquipmentCatalogue(
        source: construct,
        level: 2,
      );
      expect(equipment, isNotEmpty);
      expect(
        equipment.every(
          (i) => i.bonusScudo >= 60 && i.bonusDanno <= 1 && i.bonusDifesa <= 1,
        ),
        isTrue,
      );
      expect(
        equipment.where((i) => i.arma).every((i) => i.buff.contains('@cm+1')),
        isTrue,
      );
    },
  );
  testWidgets(
    'Construct kill Shield persists once through JSON and does not reward summons',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final before = p.shieldTotal();
      final enemy = {
        'id': 'construct-1',
        'monsterSheetTag': 'construct-1',
        'monsterBookId': 'costrutto_minore',
        'killerTag': p.ownerTag(),
        'level': 3,
      };
      p.settleMonsterRewards([enemy], 'construct-fight', [p.ownerTag()]);
      expect(p.shieldTotal(), before + 90);
      p.load(p.snapshot());
      p.settleMonsterRewards([enemy], 'construct-fight', [p.ownerTag()]);
      expect(p.shieldTotal(), before + 90);
      p.settleMonsterRewards(
        [
          {
            ...enemy,
            'id': 'summoned',
            'monsterSheetTag': 'summoned',
            'isSummon': true,
          },
        ],
        'construct-fight',
        [p.ownerTag()],
      );
      expect(p.shieldTotal(), before + 90);
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'minor shaman curses end at short rest without clearing stronger curses',
    (tester) async {
      final (_, p) = await fixtures.mountFight(tester);
      final before = p.coreStats();
      p.applyEffects([
        OculumStructuredEffect(
          id: 'strong-curse',
          type: 'planar',
          target: 'malicious_shaman_drain',
          resource: 'STRONG',
          valueExpression: '2',
        ),
      ]);
      p.applyEffects([
        OculumStructuredEffect(
          id: 'weak-curse',
          type: 'planar',
          target: 'minor_malicious_shaman_drain',
          resource: 'WEAK',
          valueExpression: '1',
        ),
      ]);
      expect(
        p.coreStats()['volonta'],
        (before['volonta']! - 3).clamp(0, 99999),
      );
      p.referenceRest(long: false);
      expect(
        p.coreStats()['volonta'],
        (before['volonta']! - 2).clamp(0, 99999),
      );
      p.referenceRest();
      expect(p.coreStats()['volonta'], before['volonta']);
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'magical shield consumes its HP and cannot absorb beyond its remaining life',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final snapshot = p.snapshot();
      snapshot['planarRuntime'] = {
        'wrongBanditShieldActive': true,
        'wrongBanditShieldHp': 10,
      };
      state.schedePersonaggio[state.schedaCorrente] = snapshot;
      p.load(snapshot);
      expect(p.referenceAbsorb(100, shield: 90), 90);
      expect(p.planarStateSnapshot()['wrongBanditShieldActive'], isFalse);
      expect(p.referenceAbsorb(100, mantle: 70), 30);
      await closeFixture(tester, p);
    },
  );
}
