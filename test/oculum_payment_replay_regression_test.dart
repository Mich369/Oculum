import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

class _PaymentReplayMaster extends OculumRealtimeService {
  _PaymentReplayMaster()
    : super(
        roomId: 'payment-replay',
        playerName: 'Master',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      ) {
    authenticatedRole = 'master';
  }
  @override
  bool get isConnected => true;
  @override
  Future<bool> sendCombatEvent(
    String event,
    Map<String, dynamic> payload,
  ) async => true;
}

void _cleanCosts(dynamic state) {
  state.titoli.clear();
  state.arti.clear();
  state.skills.clear();
  state.inventario.clear();
  state.activeStructuredEffects.clear();
  state.buffMalusRapidiController.text = '';
  state.livelloController.text = '3';
  state.gradoController.text = '0';
  state.resilienzaController.text = '20';
  state.currentResilienzaController.text = '20';
  state.materiaController.text = '3';
  state.currentMateriaController.text = '3';
  state.oculumController.text = '3';
  state.currentOculumController.text = '3';
  state.currentHpController.text = '150';
  for (final token in state.masterInitiativeTokens as List) {
    token['fightInstanceId'] = 'payment-fight';
  }
}

Map<String, int> _resourceXp(OculumPerformanceProbe p) => p.resourceFightXp(
  encounterId: 'encounter_1',
  fightInstanceId: 'payment-fight',
);

void main() {
  testWidgets(
    'payment dialog disables an overlapping unaffordable cost before spending its Action',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      _cleanCosts(state);
      final form = CharacterSkillForm(
        costoStrutturato: OculumSkillCost(
          resource: 'materia+oculum',
          amountExpression: '2',
          additionalCosts: [
            OculumSkillCost(resource: 'materia', amountExpression: '2'),
          ],
        ),
        effettiStrutturati: [
          OculumStructuredEffect(
            type: 'difesa',
            valueExpression: '1',
            duration: '1',
          ),
        ],
      );
      final pending = p.useConfiguredForTest(form);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      final confirm = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Conferma'),
      );
      expect(confirm.onPressed, isNull);
      await tester.tap(find.text('Annulla').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(await pending, false);
      expect(state.currentMateriaController.text, '3');
      expect(state.currentOculumController.text, '3');
      expect(state.masterInitiativeTokens.first['actionUsed'], isNot(true));
      expect(_resourceXp(p)['statsSpent'], 0);
      await closeFixture(tester, p);
    },
  );
  test(
    'resource syntax preserves composite aliases and inventory names through JSON',
    () {
      expect(
        oculumNormalizeArtSkillCostResource(' MAT + OCU '),
        'materia+oculum',
      );
      expect(
        oculumNormalizeArtSkillCostResource('Item: Pietra Lunare'),
        'item:pietralunare',
      );
      expect(
        oculumNormalizeEffectResource('material: Ferro Scuro'),
        'material:ferroscuro',
      );
      final cost = OculumSkillCost(
        resource: 'Materia + Oculum',
        amountExpression: '2',
      );
      expect(cost.isValid(), true);
      expect(
        OculumSkillCost.fromJson(cost.toJson()).resource,
        'Materia + Oculum',
      );
    },
  );
  testWidgets(
    'named inventory and material costs consume the selected objects instead of Oculum',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      _cleanCosts(state);
      state.inventario.add(
        InventoryItem(nome: 'Pietra Lunare', peso: .2, quantita: 2, note: ''),
      );
      state.inventario.add(
        InventoryItem(nome: 'Ferro Scuro', peso: .5, quantita: 1, note: ''),
      );
      expect(p.spendArtResource('item: Pietra Lunare', 1), 1);
      expect(p.spendArtResource('material: Ferro Scuro', 100), 100);
      expect(p.availableArtResource('item: Pietra Lunare'), 1);
      expect(p.availableArtResource('material: Ferro Scuro'), 400);
      expect(state.currentOculumController.text, '3');
      expect(_resourceXp(p)['statsSpent'], 0);
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'overlapping mixed costs and sealed Oculum never partially spend or award XP',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      _cleanCosts(state);
      p.normalizeInitiative();
      final before = p.coreStats();
      final xpBefore = _resourceXp(p);
      expect(p.payArtResources({'materia+oculum': 2, 'materia': 2}), false);
      expect(p.coreStats(), before);
      expect(_resourceXp(p), xpBefore);
      state.activeConditions.add(
        OculumConditionInstance.fromJson({
          'id': 'sealed-payment',
          'conditionType': 'oculum_sigillato',
          'category': 'negative',
          'duration': 3,
        }),
      );
      expect(p.availableArtResource('oculum'), 0);
      expect(p.payArtResources({'materia': 1, 'oculum': 1}), false);
      expect(p.coreStats(), before);
      expect(_resourceXp(p), xpBefore);
      expect(state.masterInitiativeTokens.first['actionUsed'], isNot(true));
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'RES plus HP checks the reduced maximum before any cost or ledger mutation',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      _cleanCosts(state);
      p.normalizeInitiative();
      expect(p.maximumHp(), 200);
      final before = p.coreStats();
      final xpBefore = _resourceXp(p);
      expect(p.payArtResources({'resilienza': 6, 'hp': 150}), false);
      expect(state.currentHpController.text, '150');
      expect(p.coreStats(), before);
      expect(p.maximumHp(), 200);
      expect(_resourceXp(p), xpBefore);
      // The feasible payment is independent of the editor's insertion order.
      expect(p.payArtResources({'hp': 10, 'resilienza': 6}), true);
      expect(state.currentResilienzaController.text, '14');
      expect(state.currentHpController.text, '130');
      expect(_resourceXp(p)['statsSpent'], 6);
      expect(_resourceXp(p)['hpLost'], 0);
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'a replayed resolved attack cannot inflate the next personal turn PT maximum',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      state.realtimeService = _PaymentReplayMaster();
      final enemy = state.masterInitiativeTokens[1] as Map<String, dynamic>;
      enemy.addAll({'fightInstanceId': 'replay-power', 'totalPower': 100});
      state.realtimeUsers.add(<String, dynamic>{
        'sessionId': 'enemy-session',
        'role': 'player',
        'localSheetTags': ['ENEMY'],
      });
      p.beginRewardPowerTurn(enemy);
      final packet = <String, dynamic>{
        'id': 'old-power-attack',
        'scope': p.permissionScope,
        'campaignId': p.permissionCampaignId,
        'encounterId': 'encounter_1',
        'sourceTag': 'ENEMY',
        'senderTag': 'ENEMY',
        'senderRole': 'player',
        'sessionId': 'enemy-session',
        'targetTag': p.ownerTag(),
        'sourceName': 'Nemico',
        'attack': 20,
        'damage': 7,
        'natural': 10,
        'choice': 'vc',
        'element': 'fisico',
        'sourceRewardTotalPower': 100,
      };
      p.receiveCombat('combat_attack', packet);
      expect(state.onlineCombatRequests.containsKey(packet['id']), true);
      state.onlineCombatRequests[packet['id']]['status'] = 'resolved';
      state.masterInitiativeRound = 1;
      enemy['totalPower'] = 30;
      p.beginRewardPowerTurn(enemy);
      expect(oculumFightRewardAverageTotalPower(enemy), 65);
      p.receiveCombat('combat_attack', packet);
      expect((enemy['rewardPowerTurnMaxima'] as Map)['1'], 30);
      expect(oculumFightRewardAverageTotalPower(enemy), 65);
      state.realtimeService = null;
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'manual enemy quest power includes the HP contribution without changing an explicit override',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      state.masterInitiativeTokens.removeLast();
      final enemy = state.masterInitiativeTokens[1] as Map<String, dynamic>;
      enemy.addAll({
        'statsTotal': 40,
        'level': 13,
        'grade': 1,
        'status': 'dead',
      });
      p.recordCurrentEncounter();
      final end = p.finishEncounter('encounter_1');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('Termina, tira i Drop e assegna EXP'));
      await tester.pump();
      await end;
      final reward =
          (state.masterInitiativeGroups.first['rewards'] as List).single as Map;
      expect((reward['defeated'] as List).single['totalPower'], 59);
      await closeFixture(tester, p);
    },
  );
}
