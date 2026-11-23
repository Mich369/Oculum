import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/oculum_fight_creator_rules.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

class _SequenceRandom implements Random {
  _SequenceRandom(this.values);
  final List<int> values;
  int calls = 0;

  @override
  int nextInt(int max) {
    final value = values[calls++];
    expect(value, inInclusiveRange(0, max - 1));
    return value;
  }

  @override
  bool nextBool() => throw UnsupportedError('Only integer rolls are expected');

  @override
  double nextDouble() =>
      throw UnsupportedError('Only integer rolls are expected');
}

void main() {
  test('exactly twenty of one hundred creation outcomes are wounded', () {
    var wounded = 0;
    for (var roll = 0; roll < 100; roll++) {
      final random = _SequenceRandom([roll, 0]);
      final health = oculumFightCreatorInitialHealth(100, random: random);
      if (health.percent < 100) wounded++;
      expect(health.hp, roll < 20 ? 25 : 100);
      expect(random.calls, roll < 20 ? 2 : 1);
    }
    expect(wounded, 20);
  });

  test('inclusive 25–75 percent, rounding up, tiny and zero maximum Life', () {
    for (var roll = 0; roll <= 50; roll++) {
      final health = oculumFightCreatorInitialHealth(
        101,
        random: _SequenceRandom([0, roll]),
      );
      expect(health.percent, 25 + roll);
      expect(health.hp, (101 * (25 + roll) / 100).ceil());
    }
    expect(
      oculumFightCreatorInitialHealth(1, random: _SequenceRandom([0, 0])).hp,
      1,
    );
    final unused = _SequenceRandom([]);
    expect(oculumFightCreatorInitialHealth(0, random: unused).hp, 0);
    expect(unused.calls, 0);
  });

  testWidgets(
    'distinct enemy copies retain their wounds through JSON and Fight preparation',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      final source = monsterBookEntryById('piranha_mortale')!;
      final canonical = jsonEncode(source.toJson());
      final before = state.schedePersonaggio.length as int;
      final random = _SequenceRandom([0, 0, 19, 50, 20]);
      state.quickSheetCountController.text = '3';
      await probe.generateBookCreatureFromSource(
        source,
        level: 0,
        forFightCreator: true,
        woundRandom: random,
      );
      final created = (state.schedePersonaggio as List)
          .skip(before)
          .cast<Map>()
          .toList();
      expect(created, hasLength(3));
      expect(created.map((sheet) => sheet['sheetTag']).toSet(), hasLength(3));
      expect(random.calls, 5);
      for (var i = 0; i < created.length; i++) {
        final sheet = created[i];
        final receipt = sheet['fightCreatorInitialHealth'] as Map;
        expect(receipt['remainingHpPercent'], [25, 75, 100][i]);
        final maximum = readIntValue(receipt['maximumHpAtCreation']);
        final expected = (maximum * [25, 75, 100][i] / 100).ceil();
        expect(readIntValue(sheet['currentHp']), expected);
        expect(sheet['masterOnlyDraft'], isTrue);
        expect(receipt['initialHp'], expected);
        final saved = Map<String, dynamic>.from(
          jsonDecode(jsonEncode(sheet)) as Map,
        );
        probe.load(saved);
        expect(readIntValue(probe.snapshot()['currentHp']), expected);
        expect(probe.maximumHp(), maximum);
      }
      expect(
        probe.prepareFightCreator(
          assignments: {
            for (final sheet in created) '${sheet['sheetTag']}': 'enemy',
          },
        ),
        isTrue,
      );
      expect(
        random.calls,
        5,
        reason: 'Preparing the Fight must not reroll Life',
      );
      probe.startFight(state.selectedMasterInitiativeGroupId as String);
      for (final original in created) {
        final saved = (state.schedePersonaggio as List).cast<Map>().firstWhere(
          (sheet) => sheet['sheetTag'] == original['sheetTag'],
        );
        expect(
          readIntValue(saved['currentHp']),
          (saved['fightCreatorInitialHealth'] as Map)['initialHp'],
          reason: 'Starting the Fight must preserve the generated wounds',
        );
      }
      expect(random.calls, 5);
      expect(jsonEncode(source.toJson()), canonical);
      expect((state.masterInitiativeGroups.last as Map)['rewards'], isNull);
      await closeFixture(tester, probe);
    },
  );

  testWidgets(
    'ordinary generation and allied Creator sheets stay at full Life',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      final source = monsterBookEntryById('piranha_mortale')!;
      for (final creator in [false, true]) {
        final unused = _SequenceRandom([]);
        state.quickSheetCountController.text = '1';
        await probe.generateBookCreatureFromSource(
          source,
          forFightCreator: creator,
          sideOverride: creator ? 'ally' : 'enemy',
          woundRandom: unused,
        );
        expect(unused.calls, 0);
        expect(readIntValue(probe.snapshot()['currentHp']), probe.maximumHp());
        expect(
          state.schedePersonaggio.last['fightCreatorInitialHealth'],
          isNull,
        );
      }
      await closeFixture(tester, probe);
    },
  );
}
