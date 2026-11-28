import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/oculum_opposed_attack.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'package:oculum/widgets/oculum_attack_planner.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  test('Aberion arrotonda ogni colpo e assegna solo Oculum pagato', () {
    expect([0, 1, 2, 7, 10, 11].map(oculumAberionDamageBonus), [
      0,
      1,
      3,
      10,
      15,
      15,
    ]);
    expect(oculumAberionAllocatePaidOculum([2, 10, 3], 11), [2, 9, 0]);
  });

  test('Chikar tira da quattro a nove chili solo dopo una morte valida', () {
    InventoryItem? drop({
      bool dead = true,
      bool training = false,
      bool summon = false,
      String id = oculumChikarMonsterId,
      int dieIndex = 0,
    }) => oculumChikarMeatDrop(
      monsterId: id,
      confirmedDeath: dead,
      training: training,
      summon: summon,
      killId: 'fight:enemy',
      grade: 2,
      random: _FixedDie(dieIndex),
    );

    expect(drop()!.peso, 4);
    expect(drop(dieIndex: 5)!.peso, 9);
    expect(drop()!.quantita, 1);
    expect(drop()!.monsterLoot, containsPair('quality', 'ottima'));
    expect(drop(dead: false), isNull);
    expect(drop(training: true), isNull);
    expect(drop(summon: true), isNull);
    expect(drop(id: 'ciclo_cinghiale_fango'), isNull);
  });

  for (final (powered, costResource) in [
    (false, ''),
    (false, 'materia'),
    (false, 'oculum'),
    (true, ''),
  ]) {
    final eligible = powered || costResource == 'oculum';
    testWidgets(
      powered
          ? 'Aberion paga ogni quota una sola volta e congela i due pacchetti'
          : costResource == 'oculum'
          ? 'Un colpo preparato pagando Oculum offre il potenziamento anche dall’attacco standard'
          : 'Aberion non propone il costo extra per ${costResource.isEmpty ? 'un attacco ordinario' : 'un colpo preparato pagando Materia'}',
      (tester) async {
        final (state, probe) = await mountFight(tester);
        state.realtimeRoomController.text = 'aberion-test';
        final sheet = <String, dynamic>{
          ...probe.snapshot(),
          'monsterBookSourceId': oculumAberionMonsterId,
          'materia': '12',
          'currentMateria': '9',
          'oculum': '12',
          'currentOculum': costResource == 'oculum' ? '10' : '9',
          'normalCurrentOculum': costResource == 'oculum' ? 10 : 9,
        };
        state.schedePersonaggio[0] = sheet;
        probe.load(sheet);
        state.currentHpController.text = '${probe.maximumHp()}';
        probe.recordCurrentEncounter();
        if (costResource.isNotEmpty) {
          final prepare = probe.useConfiguredForTest(
            CharacterSkillForm(
              costoStrutturato: OculumSkillCost(
                resource: costResource,
                amountExpression: '1',
              ),
              effettiStrutturati: [
                OculumStructuredEffect(
                  id: 'aberion-test-prepare',
                  type: 'danno',
                  mode: 'prossima_azione',
                  valueExpression: '4',
                ),
              ],
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          final confirm = find.widgetWithText(FilledButton, 'Conferma');
          expect(confirm, findsOneWidget);
          await tester.tap(confirm);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          expect(await prepare, isTrue);
          expect(state.currentOculumController.text, '9');
          expect(
            state.currentMateriaController.text,
            costResource == 'materia' ? '8' : '9',
          );
          expect(
            probe.structuredEffects().any(
              (effect) => effect['aberionOculumPrepared'] == true,
            ),
            eligible,
          );
        }
        final preparedBonus = costResource.isEmpty ? 0 : 4;
        final expectedBase = oculumDamagePerTarget(
          probe.damageTotal() - preparedBonus,
          2,
          flatBonusPerTarget: preparedBonus,
        );

        final attack = probe.planAttack(
          minimum: 2,
          maximum: 2,
          total: 30,
          natural: 10,
          oculumPowered: powered,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final planner = find.byType(OculumAttackPlanner);
        expect(planner, findsOneWidget);
        Navigator.of(tester.element(planner)).pop(
          OculumAttackPlan(
            'ENEMY',
            'vc',
            'Prova',
            additionalTargetIds: ['OTHER'],
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        final dialog = find.text('Aberion · Potenzia i colpi');
        if (eligible) {
          expect(dialog, findsOneWidget);
          Slider slider(int hit) =>
              tester.widget<Slider>(find.byKey(ValueKey('aberion-hit-$hit')));
          slider(0).onChanged!(2);
          await tester.pump();
          slider(1).onChanged!(10);
          await tester.pump();
          expect(slider(1).value, 7);
          expect(state.currentOculumController.text, '9');
          await tester.tap(find.text('Conferma potenziamento'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
        } else {
          expect(dialog, findsNothing);
        }
        await attack;

        List<Map> packets() => (state.onlineCombatRequests as Map).values
            .whereType<Map>()
            .where((packet) => packet['attackGroupId'] != null)
            .toList();
        final byTarget = {for (final p in packets()) p['targetTag']: p};
        expect(byTarget.keys, unorderedEquals(['ENEMY', 'OTHER']));
        expect(byTarget['ENEMY']!['damage'], expectedBase + (eligible ? 3 : 0));
        expect(
          byTarget['OTHER']!['damage'],
          expectedBase + (eligible ? 10 : 0),
        );
        expect(byTarget['ENEMY']!['aberionOculumSpent'], eligible ? 2 : null);
        expect(byTarget['OTHER']!['aberionOculumSpent'], eligible ? 7 : null);
        final reserveAfter = eligible ? '0' : '9';
        expect(state.currentOculumController.text, reserveAfter);
        if (powered) {
          List<Object?> attackDetails(Map packet) => [
            packet['id'],
            packet['damage'],
            packet['aberionOculumSpent'],
          ];
          final frozen = packets().map(attackDetails).toList();
          final transport = _AttackTransport();
          state.realtimeVisibleInitiativeSnapshot = <String, dynamic>{
            'encounterId': 'encounter_1',
            'campaignId': state.activeCampaignId,
            'fightStarted': true,
            'tokens': state.masterInitiativeTokens,
          };
          state.realtimeService = transport;
          for (var retry = 0; retry < 2; retry++) {
            transport.attacks.clear();
            await probe.retryCombat();
            expect(
              transport.attacks.map(attackDetails),
              unorderedEquals(frozen),
            );
            expect(state.currentOculumController.text, reserveAfter);
          }
          state.realtimeService = null;
        }
        await closeFixture(tester, probe);
      },
    );
  }

  for (final training in [false, true]) {
    testWidgets(
      training
          ? 'L’allenamento con Chikar non assegna la carne garantita'
          : 'Fine Fight ripartisce solo la carne del vero Chikar morto e non raddoppia al replay',
      (tester) async {
        final (state, probe) = await mountFight(tester);
        final hero = probe.ownerTag();
        final sheet = <String, dynamic>{
          ...probe.snapshot(),
          'livello': '1',
          'grado': '0',
          'resilienza': '3',
          'volonta': '3',
          'materia': '2',
          'oculum': '2',
          'inventario': <dynamic>[],
          'claimedEncounterRewardIds': <String>[],
        };
        state.schedePersonaggio[0] = sheet;
        probe.load(sheet);
        final enemy = <String, dynamic>{
          'name': 'Chikar',
          'side': 'enemy',
          'status': training ? 'downed' : 'dead',
          'currentHp': 0,
          'monsterBookId': oculumChikarMonsterId,
          'level': 5,
          'grade': 1,
          'statsTotal': 40,
          'resilienza': 10,
          'volonta': 10,
          'materia': 15,
          'oculum': 5,
          'fightInstanceId': 'chikar-runtime-test',
          'rewardDeathRound': 3,
        };
        state.masterInitiativeTokens
          ..clear()
          ..addAll([
            <String, dynamic>{
              'id': hero,
              'sheetTag': hero,
              'side': 'party',
              'status': 'active',
              'fightInstanceId': 'chikar-runtime-test',
            },
            {...enemy, 'id': 'CHIKAR-DEAD', 'sheetTag': 'CHIKAR-DEAD'},
            {
              ...enemy,
              'id': 'CHIKAR-DOWN',
              'sheetTag': 'CHIKAR-DOWN',
              'status': 'downed',
            },
            {
              ...enemy,
              'id': 'CHIKAR-SUMMON',
              'sheetTag': 'CHIKAR-SUMMON',
              'isSummon': true,
            },
          ]);
        state.masterInitiativeRound = 3;
        probe.recordCurrentEncounter();
        final group = state.masterInitiativeGroups.first as Map;
        group['trainingMode'] = training;
        final finish = probe.finishEncounter('encounter_1', random: Random(32));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        final finishButton = find.widgetWithText(
          FilledButton,
          'Termina, tira i Drop e assegna EXP',
        );
        expect(finishButton, findsOneWidget);
        expect(tester.widget<FilledButton>(finishButton).onPressed, isNotNull);
        await tester.tap(finishButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await finish;

        final activeGroup = state.masterInitiativeGroups.first as Map;
        expect(activeGroup['rewards'], isNotNull, reason: '${state.logEventi}');
        final reward = Map<String, dynamic>.from(
          (activeGroup['rewards'] as List).single as Map,
        );
        final loot = ((reward['lootByParticipant'] as Map)[hero] as List? ?? [])
            .whereType<Map>();
        final meat = loot.where(
          (item) =>
              (item['monsterLoot'] as Map?)?['catalogueDropId'] ==
              oculumChikarMeatId,
        );
        if (training) {
          expect(meat, isEmpty);
        } else {
          expect(meat, hasLength(1));
          final saved = InventoryItem.fromJson(
            Map<String, dynamic>.from(meat.single),
          );
          expect(saved.peso, inInclusiveRange(4, 9));
          expect(saved.quantita, 1);
          expect(saved.monsterLoot['id'], startsWith('CHIKAR-DEAD:'));
          expect(
            loot.where((item) => item['nome'] == 'Carne di mostro cruda'),
            isEmpty,
          );

          Iterable<Map> inventoryMeat() =>
              ((probe.snapshot()['inventario'] as List?) ?? [])
                  .whereType<Map>()
                  .where(
                    (item) =>
                        (item['monsterLoot'] as Map?)?['catalogueDropId'] ==
                        oculumChikarMeatId,
                  );
          expect(inventoryMeat(), hasLength(1));
          probe.encounterRewards([reward, reward]);
          expect(inventoryMeat(), hasLength(1));
          expect(inventoryMeat().single['quantita'], 1);
        }
        await closeFixture(tester, probe);
      },
    );
  }
}

class _FixedDie implements Random {
  _FixedDie(this.value);

  final int value;

  @override
  int nextInt(int max) => value;

  @override
  bool nextBool() => throw UnimplementedError();

  @override
  double nextDouble() => throw UnimplementedError();
}

class _AttackTransport extends OculumRealtimeService {
  _AttackTransport()
    : super(
        roomId: 'aberion-test',
        playerName: 'Aberion',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      );

  @override
  bool get isConnected => true;

  final attacks = <Map<String, dynamic>>[];

  @override
  Future<bool> sendCombatEvent(
    String kind,
    Map<String, dynamic> payload,
  ) async {
    if (kind == 'combat_attack') {
      attacks.add(Map<String, dynamic>.from(payload));
    }
    return true;
  }
}
