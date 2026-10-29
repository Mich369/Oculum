import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  test(
    'explicit manual totals are known reward power without invented core stats',
    () {
      const npc = {'statsTotal': 20, 'level': 2, 'grade': 1};
      expect(oculumEncounterHasKnownCoreStats(npc), false);
      expect(oculumEncounterHasKnownRewardPower(npc), true);
      // Grade I: HP ×14 contributes floor(14/5) = 2 PT.
      expect(oculumEncounterInstantRewardTotalPower(npc), 27);
      expect(
        oculumEncounterInstantRewardTotalPower({...npc, 'totalPower': 29}),
        29,
      );
      expect(oculumEncounterHasKnownRewardPower({'level': 2}), false);
    },
  );
  test('last confirmed damage receipt wins over a stale mirrored killer', () {
    final token = {
      'rewardFinalAttackId': 'last',
      'rewardLastDamageRequestId': 'last',
      'rewardLastDamageSourceTag': 'NEW',
      'lastDamageSourceTag': 'OLD',
    };
    expect(
      oculumEncounterFinalKillerTag(
        token,
        sheet: {'lastDamageSourceTag': 'STALE'},
      ),
      'NEW',
    );
    expect(
      oculumEncounterFinalKillerTag({
        ...token,
        'rewardFinalAttackId': 'different',
      }),
      'OLD',
    );
    expect(
      oculumEncounterFinalKillerTag({'lastDamageSourceTag': 'LEGACY'}),
      'LEGACY',
    );
    expect(oculumEncounterFinalKillerTag({}), isEmpty);
  });
  test(
    'new common budget subtracts own permanent stats and level only once',
    () {
      const enemies = [
        {'statsTotal': 100, 'level': 10, 'grade': 2, 'source': 'Boss'},
        {'statsTotal': 20, 'level': 3, 'grade': 0},
      ];
      expect(
        oculumEncounterDifferenceExperience(
          enemies,
          characterStats: 40,
          characterLevel: 5,
          characterGrade: 0,
        ),
        // (100+10+6+3) × 1.2², rounded, plus (20+3+1), minus (40+5+1).
        149,
      );
      expect(
        oculumEncounterDifferenceExperience(
          enemies,
          characterStats: 200,
          characterLevel: 5,
          characterGrade: 0,
        ),
        0,
      );
      expect(
        oculumEncounterDifferenceExperience(
          const [],
          characterStats: 40,
          characterLevel: 5,
          characterGrade: 0,
        ),
        0,
      );
      expect(
        oculumEncounterRewardMethod(null),
        oculumEncounterRewardMethodDifference,
      );
      expect(
        oculumEncounterRewardMethod('legacy'),
        oculumEncounterRewardMethodLegacy,
      );
    },
  );

  test(
    'exported character PT includes fixed gear and public titles, excludes transformations',
    () {
      for (final example in [
        ('senka_kamaria', 'Senka_Kamaria', 36),
        ('lusier_iii', 'Lusier_III', 301),
        ('erik_i', 'Erik_I', 131),
      ]) {
        final sheet = Map<String, dynamic>.from(
          jsonDecode(
                File(
                  'output/characters/${example.$1}/${example.$2}.json',
                ).readAsStringSync(),
              )
              as Map,
        );
        expect(
          oculumEncounterPermanentTotalPower(sheet),
          example.$3,
          reason: example.$2,
        );
        if (example.$1 == 'senka_kamaria') {
          for (final item in (sheet['inventario'] as List).whereType<Map>()) {
            if ((item['craftData'] as Map?)?['senkaMask'] == true) {
              item['equipaggiata'] = true;
            }
          }
          sheet['tempResilienza'] = 900;
          sheet['planarRuntime'] = {'senkaMoonActive': true};
          expect(oculumEncounterPermanentTotalPower(sheet), example.$3);
        }
      }
    },
  );

  test(
    'PT finishing and help shares never stack roles, clamp weaker enemies',
    () {
      final enemy = {
        'id': 'E',
        'sheetTag': 'E',
        'totalPower': 100,
        'deathRound': 5,
        'killerTag': 'K',
        'killerTotalPower': 40,
      };
      final help = {
        'id': 'H1',
        'helperTag': 'H',
        'enemyTag': 'E',
        'kind': 'attack',
        'round': 5,
        'helperTotalPower': 40,
        'finalAttack': true,
      };
      expect(
        oculumEncounterFinishingExperience(
          [enemy],
          characterTag: 'K',
          characterTotalPower: 40,
        ),
        60,
      );
      expect(
        oculumEncounterAssistanceExperience(
          [enemy],
          history: [help],
          characterTag: 'H',
          characterTotalPower: 40,
        ),
        15,
      );
      expect(
        oculumEncounterAssistanceExperience(
          [enemy],
          history: [
            {...help, 'finalAttack': false},
          ],
          characterTag: 'H',
          characterTotalPower: 40,
        ),
        6,
      );
      expect(
        oculumEncounterAssistanceExperience(
          [enemy],
          history: [
            {...help, 'decisive': true},
          ],
          characterTag: 'H',
          characterTotalPower: 40,
        ),
        30,
      );
      expect(
        oculumEncounterAssistanceExperience(
          [enemy],
          history: [
            {...help, 'helperTag': 'K', 'decisive': true},
          ],
          characterTag: 'K',
          characterTotalPower: 40,
        ),
        0,
      );
      expect(
        oculumEncounterFinishingExperience(
          [
            {...enemy, 'totalPower': 20},
          ],
          characterTag: 'K',
          characterTotalPower: 40,
        ),
        0,
      );
      expect(
        oculumEncounterAssistanceExperience(
          [enemy],
          history: [
            {...help, 'round': 2},
          ],
          characterTag: 'H',
          characterTotalPower: 40,
        ),
        0,
      );
    },
  );

  test(
    'three-round support requires real low-health healing and uses strongest role',
    () {
      final enemy = {
        'id': 'E',
        'totalPower': 100,
        'deathRound': 5,
        'killerTag': 'K',
      };
      final heal = {
        'id': 'heal',
        'helperTag': 'H',
        'beneficiaryTag': 'K',
        'enemyTag': 'E',
        'kind': 'heal',
        'round': 3,
        'helperTotalPower': 40,
        'amount': 10,
        'hpBefore': 50,
        'hpMax': 100,
      };
      int xp(Iterable<Map> history) => oculumEncounterAssistanceExperience(
        [enemy],
        history: history,
        characterTag: 'H',
        characterTotalPower: 40,
      );
      expect(xp([heal]), 15);
      expect(
        xp([
          {...heal, 'kind': 'damage'},
        ]),
        6,
      );
      expect(
        xp([
          {...heal, 'kind': 'debuff'},
        ]),
        6,
      );
      expect(
        xp([
          {...heal, 'hpBefore': 51},
        ]),
        0,
      );
      expect(
        xp([
          {...heal, 'amount': 0},
        ]),
        0,
      );
      expect(
        xp([
          heal,
          {...heal, 'id': 'defense', 'kind': 'defense'},
        ]),
        15,
      );
      expect(
        xp([
          heal,
          {
            ...heal,
            'id': 'atk',
            'kind': 'attack',
            'finalAttack': true,
            'decisive': true,
          },
        ]),
        30,
      );
    },
  );

  test('single fight trait factor counts unique aids and assisted kills', () {
    const enemies = [
      {'id': 'A', 'deathRound': 5},
      {'id': 'B', 'deathRound': 5},
    ];
    final old = {
      'id': 'old',
      'helperTag': 'H',
      'enemyTag': 'A',
      'round': 1,
      'kind': 'attack',
    };
    final first = {
      'id': 'one',
      'helperTag': 'H',
      'enemyTag': 'A',
      'round': 3,
      'kind': 'attack',
      'finalAttack': true,
    };
    final second = {...first, 'id': 'two', 'enemyTag': 'B', 'round': 4};
    double factor(Iterable<Map> h) =>
        oculumEncounterSubtraitExperienceMultiplier(
          enemies,
          history: h,
          characterTag: 'H',
        );
    expect(factor([]), 1.3);
    expect(
      factor([
        {...old, 'kind': 'damage'},
      ]),
      1.3,
    );
    expect(factor([old]), 1.2);
    expect(factor([old, first, second, second]), 1.9);
  });

  test(
    'resource EXP requires a dead qualifying enemy and sums real costs once',
    () {
      expect(
        oculumEncounterResourceExperienceEligible(
          [
            {'level': 7, 'grade': 0},
          ],
          characterLevel: 5,
          characterGrade: 0,
        ),
        false,
      );
      expect(
        oculumEncounterResourceExperienceEligible(
          [
            {'level': 8, 'grade': 0},
          ],
          characterLevel: 5,
          characterGrade: 0,
        ),
        true,
      );
      expect(
        oculumEncounterResourceExperienceEligible(
          [
            {'level': 0, 'grade': 1},
          ],
          characterLevel: 5,
          characterGrade: 0,
        ),
        true,
      );
      expect(
        oculumEncounterResourceExperienceEligible(
          [
            {'level': 50, 'grade': 6, 'isSummon': true},
          ],
          characterLevel: 5,
          characterGrade: 0,
        ),
        false,
      );
      expect(oculumEncounterResourceExperience(oculumSpent: 14, hpLost: 12), 5);
      expect(oculumEncounterWeakestParticipants({'A': 40, 'B': 40, 'C': 100}), {
        'A',
        'B',
      });
    },
  );

  test(
    'six personal turn maxima use their mean for common EXP, finisher and personal Obser',
    () {
      final own = oculumFightRewardAverageTotalPower({
        'rewardPowerTurnMaxima': {
          '0': 26,
          '1': 26,
          '2': 36,
          '3': 36,
          '4': 26,
          '5': 26,
        },
      });
      expect(own, 29);
      final enemy = {
        'id': 'E',
        'rewardAverageTotalPower': 37,
        'grade': 0,
        'level': 1,
        'killerTag': 'H',
        'killerAverageTotalPower': own,
        'confirmedMonster': true,
      };
      final common = oculumEncounterDifferenceExperience(
        [enemy],
        characterStats: 26,
        characterLevel: 0,
        characterGrade: 0,
        characterAverageTotalPower: own,
      );
      final finisher = oculumEncounterFinishingExperience(
        [enemy],
        characterTag: 'H',
        characterTotalPower: own,
      );
      expect(common, 8);
      expect(finisher, 8);
      expect(common + finisher + (common + finisher) ~/ 5, 19);
      expect(
        oculumEncounterFinishingObser(
          [enemy],
          characterTag: 'H',
          characterAverageTotalPower: own,
        ),
        8,
      );
      expect(
        oculumEncounterResourceExperienceEligible(
          [enemy],
          characterLevel: 0,
          characterGrade: 0,
        ),
        false,
      );
    },
  );
  test(
    'party crystal thresholds choose exactly one size, no automatic Dust conversion',
    () {
      expect(
        oculumEncounterPartyCrystalSize(deadMonsterPower: 174, partyPower: 100),
        isNull,
      );
      expect(
        oculumEncounterPartyCrystalSize(deadMonsterPower: 175, partyPower: 100),
        'piccolo',
      );
      expect(
        oculumEncounterPartyCrystalSize(deadMonsterPower: 220, partyPower: 100),
        'medio',
      );
      expect(
        oculumEncounterPartyCrystalSize(deadMonsterPower: 300, partyPower: 100),
        'grande',
      );
      final item = oculumDustCrystal('grande');
      expect(item.craftData['dustCrystal'], 'grande');
      expect(item.quantita, 1);
    },
  );
  test(
    'one multishot aid counts once but can assist two distinct final kills',
    () {
      final history = [
        for (final id in ['A', 'B'])
          {
            'id': 'aid:$id',
            'helpReceiptId': 'one-aid',
            'helperTag': 'H',
            'enemyTag': id,
            'kind': 'attack',
            'round': 3,
            'finalAttack': true,
          },
      ];
      expect(
        oculumEncounterSubtraitExperienceMultiplier(
          [
            {'id': 'A', 'deathRound': 3},
            {'id': 'B', 'deathRound': 3},
          ],
          history: history,
          characterTag: 'H',
        ),
        1.7,
      );
    },
  );

  Future<(dynamic, OculumPerformanceProbe)> mount(
    WidgetTester tester, {
    bool escaped = false,
  }) async {
    final (state, p) = await fixtures.mountFight(tester);
    final hero = p.ownerTag();
    final sheet = <String, dynamic>{
      ...p.snapshot(),
      'id': hero,
      'sheetTag': hero,
      'livello': '1',
      'grado': '0',
      'resilienza': '3',
      'volonta': '3',
      'materia': '2',
      'oculum': '2',
      'currentResilienza': '3',
      'currentVolonta': '3',
      'currentMateria': '2',
      'currentOculum': '2',
      'normalCurrentOculum': 2,
      'skills': <dynamic>[],
      'arti': <dynamic>[],
      'titoli': <dynamic>[],
      'trattiRazziali': <dynamic>[],
      'inventario': <dynamic>[],
      'exp': '0',
      'claimedEncounterRewardIds': <String>[],
      'planarRuntime': <String, dynamic>{},
    };
    state.schedePersonaggio[0] = sheet;
    p.load(sheet);
    state.masterInitiativeTokens
      ..clear()
      ..addAll([
        <String, dynamic>{
          'id': hero,
          'sheetTag': hero,
          'side': 'party',
          'status': escaped ? 'fled' : 'active',
          'outsideFight': escaped,
          'fightInstanceId': 'reward-unique',
        },
        <String, dynamic>{
          'id': 'E',
          'sheetTag': 'E',
          'name': 'NPC manuale',
          'side': 'enemy',
          'status': 'dead',
          'currentHp': 99,
          'level': 4,
          'grade': 0,
          'resilienza': 10,
          'volonta': 10,
          'materia': 10,
          'oculum': 10,
          'statsTotal': 40,
          'totalPower': 44,
          'rewardDeathRound': 3,
          'fightInstanceId': 'reward-unique',
        },
      ]);
    state.masterInitiativeRound = 3;
    p.recordCurrentEncounter();
    return (state, p);
  }

  Future<void> confirm(WidgetTester tester, Future<void> finish) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Termina, tira i Drop e assegna EXP'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await finish;
  }

  testWidgets(
    'manual allied NPC with an explicit core total receives its own end-fight budget',
    (tester) async {
      final (state, p) = await mount(tester);
      state.masterInitiativeTokens.add(<String, dynamic>{
        'id': 'NPCALLY',
        'sheetTag': 'NPCALLY',
        'name': 'Alleato manuale',
        'side': 'party',
        'status': 'ready',
        'npc': true,
        'level': 2,
        'grade': 0,
        'statsTotal': 20,
        'manualLevelGradeOverride': true,
        'fightInstanceId': 'reward-unique',
      });
      p.recordCurrentEncounter();
      await confirm(
        tester,
        p.finishEncounter('encounter_1', random: Random(9)),
      );
      final group = state.masterInitiativeGroups.first as Map;
      final reward = (group['rewards'] as List).single as Map;
      expect((reward['participantPowers'] as Map)['NPCALLY'], 22);
      expect((reward['commonExperienceByParticipant'] as Map)['NPCALLY'], 23);
      expect((reward['experienceByParticipant'] as Map)['NPCALLY'], 23);
      expect(reward['weakestParticipantTags'], isNot(contains('NPCALLY')));
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'final settlement pays fled participant and manual dead NPC, replay/reload cannot duplicate',
    (tester) async {
      final (state, p) = await mount(tester, escaped: true);
      final first = p.finishEncounter('encounter_1', random: Random(9));
      final concurrent = p.finishEncounter('encounter_1', random: Random(9));
      await confirm(tester, first);
      await concurrent;
      final group = state.masterInitiativeGroups.first as Map;
      final reward = (group['rewards'] as List).single as Map;
      expect(reward['defeated'], hasLength(1));
      expect((reward['defeated'] as List).single['name'], 'NPC manuale');
      expect(reward['outcome'], 'escape');
      expect((reward['experienceByParticipant'] as Map)[p.ownerTag()], 34);
      final request =
          state.onlineCombatRequests.values
                  .where((r) => r['kind'] == 'encounter_reward')
                  .single
              as Map;
      expect(request['awardedExperience'], 34);
      expect(request['weakestExperienceBonus'], 0);
      expect(
        state.occhiCaduti,
        isEmpty,
        reason: 'manual NPC cannot invent an eye/anatomical drop',
      );
      final saved = p.snapshot();
      await p.finishEncounter('encounter_1');
      p.load(saved);
      await p.finishEncounter('encounter_1');
      expect(group['rewards'], hasLength(1));
      expect(
        state.onlineCombatRequests.values.where(
          (r) => r['kind'] == 'encounter_reward',
        ),
        hasLength(1),
      );
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'victory adds weakest 20 percent after common award without changing base payload',
    (tester) async {
      final (state, p) = await mount(tester);
      await confirm(tester, p.finishEncounter('encounter_1'));
      final reward =
          state.onlineCombatRequests.values
                  .where((r) => r['kind'] == 'encounter_reward')
                  .single
              as Map;
      expect(reward['amount'], 34);
      expect(reward['weakestExperienceBonus'], 6);
      expect(reward['awardedExperience'], 40);
      await closeFixture(tester, p);
    },
  );

  testWidgets('fight changed behind confirmation never settles stale enemies', (
    tester,
  ) async {
    final (state, p) = await mount(tester);
    final finish = p.finishEncounter('encounter_1');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    state.masterInitiativeTokens.last['status'] = 'ready';
    await tester.tap(find.text('Termina, tira i Drop e assegna EXP'));
    await tester.pump();
    await finish;
    expect(state.masterInitiativeGroups.first['rewards'] ?? const [], isEmpty);
    expect(
      state.onlineCombatRequests.values.where(
        (r) => r['kind'] == 'encounter_reward',
      ),
      isEmpty,
    );
    await closeFixture(tester, p);
  });

  testWidgets(
    'unknown manual stats require input or an explicit legacy choice',
    (tester) async {
      final (state, p) = await mount(tester);
      for (final key in [
        'resilienza',
        'volonta',
        'materia',
        'oculum',
        'statsTotal',
      ]) {
        state.masterInitiativeTokens.last.remove(key);
      }
      p.recordCurrentEncounter();
      final finish = p.finishEncounter('encounter_1');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Termina, tira i Drop e assegna EXP'),
      );
      expect(button.onPressed, isNull);
      expect(
        find.textContaining('Statistiche permanenti mancanti:'),
        findsOneWidget,
      );
      await tester.tap(find.text('Annulla'));
      await tester.pump();
      await finish;
      expect(
        state.masterInitiativeGroups.first['rewards'] ?? const [],
        isEmpty,
      );
      await closeFixture(tester, p);
    },
  );
}
