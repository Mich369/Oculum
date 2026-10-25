import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  testWidgets(
    'initial fast expires only on second personal turn; bonuses consumed separately; anticipated action stays spent',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      state.datiCaricati = false;
      state.resilienzaController.text = '100';
      state.currentResilienzaController.text = '100';
      state.modalitaMaster = true;
      state.isMasterHost = true;
      if (state.schedePersonaggio.isEmpty) {
        state.schedePersonaggio.add(
          Map<String, dynamic>.from(probe.snapshot())
            ..['id'] = 'DefenderOcu:3690FD5G'
            ..['sheetTag'] = 'DefenderOcu:3690FD5G',
        );
        state.schedaCorrente = 0;
      }
      final tag = probe.ownerTag();
      probe.ensureEncounters();
      state.masterInitiativeRound = 0;
      state.masterInitiativeActiveIndex = 1;
      final own = <String, dynamic>{
        'id': tag,
        'sheetTag': tag,
        'name': 'Defender',
        'status': 'active',
        'currentHp': 100,
        'maxHp': 100,
        'actionUsed': false,
        'actionTurnRound': -1,
        'reactionMax': 1,
        'reactionUsed': 0,
        'reactionUsedRound': 0,
        'reactionPoolInitialized': true,
        'reactionPoolRound': 0,
        'reactionNormalFirstRoundLocked': true,
        'reactionFastMax': 1,
        'reactionFastUsed': 0,
        'reactionFastTurnKey': '0',
      };
      state.masterInitiativeTokens.clear();
      state.masterInitiativeTokens.addAll(<Map<String, dynamic>>[
        {
          'id': 'enemy',
          'sheetTag': 'enemy',
          'name': 'Enemy',
          'status': 'ready',
          'currentHp': 100,
          'maxHp': 100,
        },
        own,
      ]);
      probe.refreshEncounterResources(own);
      expect(own['pendingReactionRollBonus'] ?? 0, 0);
      expect(own['reactionFastUsed'], 0);
      expect(own['initialFastReactionExpired'] ?? false, false);
      state.masterInitiativeRound = 1;
      probe.refreshEncounterResources(own);
      expect(own['pendingReactionRollBonus'], 9);
      expect(own['pendingFastReactionConsequenceBonus'], 5);
      expect(own['initialFastReactionExpired'], true);
      expect(probe.takeReactionRollBonus(), 9);
      expect(
        own['pendingFastReactionConsequenceBonus'],
        5,
        reason: 'Utility/perception must leave damage/defense bonus intact',
      );
      expect(probe.takeReactionConsequenceBonus(), 5);
      expect(probe.takeReactionConsequenceBonus(), 0);
      probe.refreshEncounterResources(own);
      expect(
        probe.takeReactionRollBonus(),
        0,
        reason: 'Refreshing same turn cannot grant twice',
      );

      state.masterInitiativeRound = 2;
      state.masterInitiativeActiveIndex = 0;
      own['status'] = 'ready';
      expect(await probe.spendCounterAttack(), true);
      expect(own['actionAnticipatedRound'], 2);
      expect(
        own['reactionUsed'],
        0,
        reason: 'Anticipating action must not also consume a reaction',
      );
      state.masterInitiativeActiveIndex = 1;
      probe.refreshEncounterResources(own);
      expect(own['actionUsed'], true);
      expect(await probe.utilitySpend('reazione'), true);
      expect(
        await probe.utilitySpend('reazione'),
        false,
        reason: 'Initial fast reaction cannot regenerate',
      );
      probe.applyEffects([
        OculumStructuredEffect(
          type: 'planar',
          target: 'speed_increase',
          valueExpression: '3',
          mode: 'immediato',
        ),
      ]);
      await tester.pump();
      expect(
        await probe.utilitySpend('reazione_veloce'),
        true,
        reason:
            'Explicit free skill grants a usable fast reaction even after initial expiry',
      );
      expect(probe.takeReactionRollBonus(), greaterThanOrEqualTo(3));
      expect(await probe.utilitySpend('reazione_veloce'), false);
      probe.applyEffects([
        OculumStructuredEffect(
          type: 'planar',
          target: 'speed_increase',
          valueExpression: '1',
          mode: 'immediato',
        ),
      ]);
      await tester.pump();
      expect(own['extraNormalReactionQueued'], 1);
      state.masterInitiativeRound = 3;
      probe.refreshEncounterResources(own);
      expect(own['extraNormalReactionCurrent'], 1);
      expect(await probe.utilitySpend('reazione'), true);
      expect(await probe.utilitySpend('reazione'), true);
      expect(await probe.utilitySpend('reazione'), false);
      final sourceTag = 'AttackerOcu:3690FD5G';
      final source = Map<String, dynamic>.from(probe.snapshot())
        ..['id'] = sourceTag
        ..['sheetTag'] = sourceTag
        ..['nome'] = 'Attacker'
        ..['currentHp'] = '1000'
        ..['resilienza'] = '100'
        ..['currentResilienza'] = '100';
      state.schedePersonaggio.add(source);
      state.masterInitiativeTokens[0]['sheetTag'] = sourceTag;
      state.masterInitiativeTokens[0]['id'] = sourceTag;
      state.currentHpController.text = '1000';
      state.scudoController.text = '0';
      final encounter = '${state.selectedMasterInitiativeGroupId}';
      final incoming = <String, dynamic>{
        'id': 'counter-integration',
        'sourceTag': sourceTag,
        'sourceName': 'Attacker',
        'targetTag': tag,
        'targetName': 'Defender',
        'scope': probe.permissionScope,
        'encounterId': encounter,
        'status': 'pending',
        'attack': 20,
        'natural': 10,
        'damage': 40,
        'choice': 'vc',
        'element': 'fisico',
        'level': 0,
        'grade': 0,
        'difficulty': 'normale',
        'effects': [
          {'type': 'danno', 'bypassDefense': true, 'bypassShields': true},
        ],
        'counterAttackResponse': {
          'id': 'counter:counter-integration',
          'sourceTag': tag,
          'sourceName': 'Defender',
          'targetTag': sourceTag,
          'targetName': 'Attacker',
          'scope': probe.permissionScope,
          'encounterId': encounter,
          'status': 'pending',
          'attack': 20,
          'natural': 10,
          'damage': 20,
          'choice': 'vc',
          'element': 'fisico',
          'level': 0,
          'grade': 0,
          'difficulty': 'normale',
          'effects': [
            {'type': 'danno', 'bypassDefense': true, 'bypassShields': true},
          ],
        },
      };
      state.onlineCombatRequests['counter-integration'] = incoming;
      await tester.runAsync(
        () => probe.resolveCombatDefense(incoming, 'controattacco', 20),
      );
      expect(incoming['status'], 'resolved');
      expect(incoming['freeReaction'], false);
      expect(incoming['damageReceipt']['hpLost'], 20);
      expect(
        incoming['counterDamageReceipt'],
        isNotNull,
        reason: '${state.onlineCombatRequests} LOG ${state.logEventi}',
      );
      expect(incoming['counterDamageReceipt']['hpLost'], 10);
      final hpAfter = probe.currentHp();
      await tester.runAsync(
        () => probe.resolveCombatDefense(incoming, 'controattacco', 20),
      );
      expect(
        probe.currentHp(),
        hpAfter,
        reason: 'Duplicate resolution must never repeat either packet',
      );
      probe.cancelPendingSave();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );
}
