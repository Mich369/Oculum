import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

Map<String, dynamic> _whaleDeath(
  String id, {
  String killer = 'hero',
  String? plane,
  bool confirmed = true,
  bool summoned = false,
}) => {
  'id': id,
  'monsterBookId': oculumBalenaMilleOcchiId,
  'balenaDeathConfirmed': confirmed,
  'killerTag': killer,
  'grade': 6,
  'deathPlaneId': ?plane,
  if (summoned) 'isSummon': true,
};

Map<String, List<Map<String, dynamic>>> _participantLoot() => {
  'Hero': [],
  'Other': [],
};

Iterable<String> _skillIds(Iterable<Map> items) => items
    .map((item) => (item['monsterLoot'] as Map?)?['sourceSkillId'])
    .whereType<String>();

void main() {
  final whale = monsterById(oculumBalenaMilleOcchiId)!;

  test('actual natural 20 alone grants the Form I whale ray scroll', () {
    List<InventoryItem> roll(int natural, int total) =>
        oculumGenerateMonsterLoot(
          monster: whale,
          level: 29,
          grade: 6,
          random: Random(0),
          killId: 'whale:fight',
          naturalDropRoll: natural,
          dropTotal: total,
        );
    final item = roll(20, 1).singleWhere(
      (item) => item.monsterLoot['sourceSkillId'] == oculumBalenaRaySkillId,
    );
    expect(item.nome, endsWith('Forma I'));
    expect(item.gradoOggetto, 6);
    expect(item.monsterLoot['naturalDropRoll'], 20);
    final scroll = item.craftData['scroll'] as Map;
    expect(scroll['skillLevel'], 0);
    expect(scroll['maxForm'], 1);
    expect(
      roll(19, 999).where(
        (item) => item.monsterLoot['sourceSkillId'] == oculumBalenaRaySkillId,
      ),
      isEmpty,
    );
  });

  test(
    'the fifth distinct whale and the first verified Affogato death reward only the killer',
    () {
      var records = <String, dynamic>{};
      final loot = _participantLoot();
      bool settle(String id, List<Map> defeated) =>
          oculumAwardBalenaKillScrolls(
            monster: whale,
            records: records,
            lootByParticipant: loot,
            defeated: defeated,
            settlementId: id,
          );
      for (var number = 1; number <= 4; number++) {
        final death = _whaleDeath('Whale $number', killer: 'h e r o');
        expect(settle('fight-$number', [death]), isTrue);
        expect(
          settle('fight-$number', [
            {...death, 'id': 'whale$number', 'killerTag': 'Other'},
          ]),
          isFalse,
        );
      }
      expect(loot.values.expand((items) => items), isEmpty);
      records = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(records)) as Map,
      );
      final fifth = _whaleDeath('Whale 5', plane: 'affogato');
      expect(settle('fight-5', [fifth, fifth]), isTrue);
      expect(_skillIds(loot['Hero']!), [
        oculumBalenaEyesSkillId,
        oculumBalenaTeleportSkillId,
      ]);
      expect(loot['Other'], isEmpty);
      expect(
        loot['Hero']!.map(
          (item) => ((item['craftData'] as Map)['scroll'] as Map)['maxForm'],
        ),
        everyElement(1),
      );
      expect(settle('fight-5', [fifth]), isFalse);
      expect(
        settle('fight-6', [_whaleDeath('Whale 6', plane: 'affogato')]),
        isTrue,
      );
      expect(loot['Hero'], hasLength(2));
      expect((records['HERO'] as Map)['killIds'], hasLength(6));
    },
  );

  test(
    'no progression for KO, summons or uncredited kills, and no guess at the plane',
    () {
      final records = <String, dynamic>{};
      final loot = _participantLoot();
      expect(
        oculumAwardBalenaKillScrolls(
          monster: whale,
          records: records,
          lootByParticipant: loot,
          defeated: [
            _whaleDeath('KO', plane: 'affogato', confirmed: false),
            _whaleDeath('Summon', summoned: true, plane: 'affogato'),
            _whaleDeath('Uncredited', killer: ''),
            _whaleDeath('Outside party', killer: 'NPC'),
          ],
          settlementId: 'resolving-whales',
        ),
        isFalse,
      );
      expect(records, isEmpty);
      expect(
        oculumAwardBalenaKillScrolls(
          monster: whale,
          records: records,
          lootByParticipant: loot,
          defeated: [
            {..._whaleDeath('Unknown plane'), 'selectedPlaneId': 'affogato'},
            _whaleDeath('Wrong plane', plane: 'mezzano'),
          ],
          settlementId: 'some-whales',
        ),
        isTrue,
      );
      expect((records['HERO'] as Map)['killIds'], hasLength(2));
      expect(loot['Hero'], isEmpty);
    },
  );

  testWidgets('fight settlement delivers the three whale scrolls once', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    final tag = probe.ownerTag();
    final player = <String, dynamic>{
      ...probe.snapshot(),
      'id': tag,
      'sheetTag': tag,
      'livello': '1',
      'grado': '0',
      'resilienza': '6',
      'volonta': '5',
      'materia': '4',
      'oculum': '3',
      'currentHp': '31',
      'inventario': <dynamic>[],
    };
    state.schedePersonaggio[0] = player;
    probe.load(player);
    const fightId = 'balena-real-encounter';
    state.masterInitiativeTokens
      ..clear()
      ..addAll([
        <String, dynamic>{
          'id': tag,
          'sheetTag': tag,
          'side': 'party',
          'status': 'active',
          'fightInstanceId': fightId,
        },
        for (var i = 0; i < 6; i++)
          <String, dynamic>{
            'id': 'whale-$i',
            'sheetTag': 'whale-$i',
            'name': whale.nameIt,
            'monsterBookId': whale.id,
            'side': 'enemy',
            'status': 'dead',
            'level': 12,
            'grade': 1,
            'resilienza': 14,
            'volonta': 11,
            'materia': 10,
            'oculum': 16,
            'rewardDeathRound': 3,
            'rewardLastDamageRequestId': 'attack-$i',
            'rewardFinalAttackId': 'attack-$i',
            'rewardLastDamageSourceTag': tag,
            'fightInstanceId': fightId,
            if (i == 0) 'isSummon': true,
            if (i == 1) 'deathPlaneId': 'affogato',
          },
      ]);
    state.masterInitiativeRound = 3;
    probe.recordCurrentEncounter();
    final finish = probe.finishEncounter(
      'encounter_1',
      random: _FirstCritical(),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Termina, tira i Drop e assegna EXP'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await finish;
    final group = state.masterInitiativeGroups.first as Map;
    final reward = (group['rewards'] as List).single as Map;
    final items = ((reward['lootByParticipant'] as Map)[tag] as List)
        .whereType<Map>();
    expect(
      _skillIds(items),
      unorderedEquals([
        oculumBalenaRaySkillId,
        oculumBalenaEyesSkillId,
        oculumBalenaTeleportSkillId,
      ]),
    );
    final ledger = probe.partyChestSnapshot()['balenaKillRewards'] as Map;
    final receipt = ledger.values.single as Map;
    expect(receipt['killIds'], hasLength(5));
    await probe.finishEncounter('encounter_1', random: _FirstCritical());
    expect(group['rewards'], hasLength(1));
    await closeFixture(tester, probe);
  });
}

class _FirstCritical implements Random {
  var _rolled = false;

  @override
  int nextInt(int max) {
    if (max != 20 || _rolled) return 0;
    _rolled = true;
    return 19;
  }

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}
