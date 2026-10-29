import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/game/oculum_combat_scout_rules.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  testWidgets(
    'unknown manual NPC power is never recorded as a zero peak before stats are supplied',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final enemy = state.masterInitiativeTokens[1] as Map<String, dynamic>;
      enemy['fightInstanceId'] = 'manual-unknown';
      p.normalizeInitiative();
      expect(enemy['rewardPowerTurnMaxima'], isNull);
      enemy.addAll({
        'resilienza': 10,
        'volonta': 10,
        'materia': 10,
        'oculum': 10,
        'level': 13,
        'grade': 1,
      });
      p.normalizeInitiative();
      expect(oculumFightRewardAverageTotalPower(enemy), 59);
      await closeFixture(tester, p);
    },
  );
  test(
    'HP multiplier contributes to display PT and exactly once inside turn averages',
    () {
      expect(oculumHpTotalPowerBonusForGrade(0, level: 2), 0);
      expect(oculumHpTotalPowerBonusForGrade(0, level: 3), 1);
      expect(oculumHpTotalPowerBonusForGrade(1, level: 13), 3);
      expect(oculumHpTotalPowerBonusForGrade(2, level: 23), 4);
      final low = oculumScoutPower(2, [10, 10, 10, 10]);
      final high = oculumScoutPower(3, [10, 10, 10, 10]);
      expect(low, 42);
      expect(high, 44);
      expect(
        oculumEncounterPermanentTotalPower({
          'resilienza': 10,
          'volonta': 10,
          'materia': 10,
          'oculum': 10,
          'livello': 13,
          'grado': 1,
        }),
        59,
      );
      expect(
        oculumTokenDisplayTotalPower({
          'resilienza': 10,
          'volonta': 10,
          'materia': 10,
          'oculum': 10,
          'level': 13,
          'grade': 1,
        }),
        59,
      );
      final token = <String, dynamic>{};
      oculumBeginFightRewardPowerTurn(token, low, fightInstanceId: 'hp-pt');
      oculumBeginFightRewardPowerTurn(token, high, fightInstanceId: 'hp-pt');
      expect(oculumFightRewardAverageTotalPower(token), 43);
      final generated = oculumWorldTravelCreatureBuild(
        defaultMonsterBookEntries.first,
        200,
      );
      expect(generated['power'], 200);
      expect(
        oculumScoutPower(
          readIntValue(generated['level']),
          (generated['stats'] as Map).values.map(readIntValue),
          grade: readIntValue(generated['grade']),
        ),
        200,
      );
    },
  );

  testWidgets(
    'escaped and dead actors keep their historical PT while outside turns continue',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final token = state.masterInitiativeTokens.first as Map<String, dynamic>;
      token['fightInstanceId'] = 'escape-history';
      p.rewardPowerSample(p.ownerTag(), 50);
      token['outsideFight'] = true;
      token['status'] = 'fled';
      p.rewardPowerSample(p.ownerTag(), 500);
      p.beginRewardPowerTurn(token);
      p.normalizeInitiative();
      expect(oculumFightRewardAverageTotalPower(token), 50);
      expect((token['rewardPowerTurnMaxima'] as Map), hasLength(1));
      token['outsideFight'] = false;
      token['status'] = 'dead';
      p.rewardPowerSample(p.ownerTag(), 700);
      p.beginRewardPowerTurn(token);
      expect(oculumFightRewardAverageTotalPower(token), 50);
      token['status'] = 'ready';
      p.rewardPowerSample(p.ownerTag(), 80);
      expect(oculumFightRewardAverageTotalPower(token), 80);
      await closeFixture(tester, p);
    },
  );
  test('wound thresholds are strict and affect the whole initiative total', () {
    for (final hp in [100, 50]) {
      expect(oculumWoundedMovement(40, hp: hp, maxHp: 100), 40);
      expect(oculumWoundedInitiative(40, hp: hp, maxHp: 100), 40);
    }
    for (final hp in [49, 10]) {
      expect(oculumWoundedMovement(40, hp: hp, maxHp: 100), 30);
      expect(oculumWoundedInitiative(40, hp: hp, maxHp: 100), 30);
    }
    expect(oculumWoundedMovement(40, hp: 9, maxHp: 100), 20);
    expect(oculumWoundedInitiative(40, hp: 9, maxHp: 100), 24);
    expect(oculumWoundedInitiative(-10, hp: 9, maxHp: 100), -10);
    expect(oculumWoundedInitiative(40, hp: 1, maxHp: 0), 40);
  });

  test(
    'stored raw initiative prevents compounding through reload and healing',
    () {
      var token = <String, dynamic>{'initiativeTotal': 40};
      refreshEncounterWoundedInitiative(token, hp: 49, maxHp: 100);
      expect(token['initiativeTotal'], 30);
      for (var n = 0; n < 5; n++) {
        token = Map<String, dynamic>.from(jsonDecode(jsonEncode(token)) as Map);
        refreshEncounterWoundedInitiative(token, hp: 49, maxHp: 100);
        expect(token['initiativeTotal'], 30);
      }
      refreshEncounterWoundedInitiative(token, hp: 9, maxHp: 100);
      expect(token['initiativeTotal'], 24);
      refreshEncounterWoundedInitiative(token, hp: 100, maxHp: 100);
      expect(token['initiativeTotal'], 40);
    },
  );

  test('reward PT averages turn maxima, never samples or reactions', () {
    final token = <String, dynamic>{};
    oculumRecordFightRewardPowerSample(token, 50, fightInstanceId: 'one');
    oculumBeginFightRewardPowerTurn(token, 50, fightInstanceId: 'one');
    for (final sample in [70, 60, 65, 70, 51]) {
      oculumRecordFightRewardPowerSample(token, sample, fightInstanceId: 'one');
    }
    expect(oculumFightRewardAverageTotalPower(token), 70);
    oculumBeginFightRewardPowerTurn(token, 30, fightInstanceId: 'one');
    oculumRecordFightRewardPowerSample(token, 50, fightInstanceId: 'one');
    expect(oculumFightRewardAverageTotalPower(token), 60);
    oculumBeginFightRewardPowerTurn(token, 90, fightInstanceId: 'one');
    expect(oculumFightRewardAverageTotalPower(token), 70);
    final restored = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(token)) as Map,
    );
    expect(oculumFightRewardAverageTotalPower(restored), 70);
    oculumRecordFightRewardPowerSample(restored, 10, fightInstanceId: 'two');
    expect(oculumFightRewardAverageTotalPower(restored), 10);
    expect(restored['rewardPowerHasPersonalTurn'], false);
    expect(oculumFightRewardAverageTotalPower({}, fallback: 19), 19);
  });

  test(
    'personal turn receipts survive reload and do not add buckets on replay',
    () {
      var token = <String, dynamic>{};
      oculumBeginFightRewardPowerTurn(
        token,
        50,
        fightInstanceId: 'fight',
        turnReceipt: '0:owner',
      );
      oculumBeginFightRewardPowerTurn(
        token,
        30,
        fightInstanceId: 'fight',
        turnReceipt: '1:owner',
      );
      token = Map<String, dynamic>.from(jsonDecode(jsonEncode(token)) as Map);
      oculumBeginFightRewardPowerTurn(
        token,
        20,
        fightInstanceId: 'fight',
        turnReceipt: '0:owner',
      );
      expect((token['rewardPowerTurnMaxima'] as Map), hasLength(2));
      expect(oculumFightRewardAverageTotalPower(token), 40);
      oculumBeginFightRewardPowerTurn(
        token,
        60,
        fightInstanceId: 'next-fight',
        turnReceipt: '0:owner',
      );
      expect((token['rewardPowerTurnMaxima'] as Map), hasLength(1));
    },
  );

  testWidgets(
    'manual new round opens one personal bucket, resetting and replaying it does not',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      for (final token in state.masterInitiativeTokens as List) {
        token['fightInstanceId'] = 'manual-rounds';
      }
      final token = state.masterInitiativeTokens.first as Map<String, dynamic>;
      p.beginRewardPowerTurn(token);
      expect((token['rewardPowerTurnMaxima'] as Map), hasLength(1));
      p.resetEncounter(increment: true);
      expect((token['rewardPowerTurnMaxima'] as Map), hasLength(2));
      p.resetEncounter();
      p.resetEncounter(increment: true);
      expect((token['rewardPowerTurnMaxima'] as Map), hasLength(2));
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'live NPC damage keeps current turn and reorders only the next round',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final hero = p.ownerTag();
      final tokens = state.masterInitiativeTokens as List;
      for (var n = 0; n < tokens.length; n++) {
        tokens[n].addAll({
          'initiativeTotal': [50, 40, 30][n],
          'initiativeUnwoundedTotal': [50, 40, 30][n],
          'currentHp': 100,
          'maxHp': 100,
          'fightInstanceId': 'wound-fight',
          'totalPower': 50,
          'status': n == 0 ? 'active' : 'ready',
        });
      }
      p.normalizeInitiative();
      tokens[1]['currentHp'] = 9;
      p.normalizeInitiative();
      expect(tokens[1]['initiativeTotal'], 24);
      expect(tokens.map((token) => token['id']), [hero, 'ENEMY', 'OTHER']);
      expect(state.masterInitiativeActiveIndex, 0);
      p.sortInitiative();
      expect(tokens.map((token) => token['id']), [hero, 'ENEMY', 'OTHER']);
      p.turn();
      expect(tokens[state.masterInitiativeActiveIndex]['id'], 'ENEMY');
      p.turn();
      p.turn();
      expect(tokens.map((token) => token['id']), [hero, 'OTHER', 'ENEMY']);
      expect(tokens[state.masterInitiativeActiveIndex]['id'], hero);
      final enemy =
          tokens.singleWhere((token) => token['id'] == 'ENEMY') as Map;
      enemy['currentHp'] = 100;
      p.normalizeInitiative();
      expect(enemy['initiativeTotal'], 40);
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'tracker keeps per-turn PT ledger and saves the exclusion snapshot',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final token =
          (state.masterInitiativeTokens as List).first as Map<String, dynamic>;
      token['fightInstanceId'] = '';
      state.masterInitiativeGroups.first['rewardFightInstanceId'] =
          'reward-test';
      p.rewardPowerSample(p.ownerTag().toUpperCase(), 50);
      p.rewardPowerSample(p.ownerTag(), 90);
      expect(oculumFightRewardAverageTotalPower(token), 90);
      expect(token['rewardPowerFightInstanceId'], 'reward-test');
      expect(p.snapshot()['derivedRewardTotalPower'], isA<int>());
      expect(p.snapshot()['derivedUnwoundedIniziativa'], p.rawInitiative());
      await closeFixture(tester, p);
    },
  );
}
