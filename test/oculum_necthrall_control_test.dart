import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  for (final (dt, scenario) in [
    (0, 'resisted default activation'),
    (100, 'control ends at the next personal turn'),
    (100, 'the real spindle part releases control'),
    (100, 'configured payment from the Skill card'),
    (0, 'configured payment from the Fight shortcut'),
    (100, 'cancelled payment'),
    (100, 'replacement target during selection'),
    (100, 'replacement target during payment'),
    (100, 'interrupted action'),
  ]) {
    testWidgets(scenario, (tester) async {
      final breakSpindle = scenario == 'the real spindle part releases control';
      final shortcut = scenario == 'configured payment from the Fight shortcut';
      final cancel = scenario == 'cancelled payment';
      final replacedBeforePayment =
          scenario == 'replacement target during selection';
      final replacedDuringPayment =
          scenario == 'replacement target during payment';
      final interrupted = scenario == 'interrupted action';
      final hasCost =
          scenario.startsWith('configured payment') ||
          cancel ||
          replacedBeforePayment ||
          replacedDuringPayment ||
          interrupted;
      final stopsBeforeBinding =
          cancel ||
          replacedBeforePayment ||
          replacedDuringPayment ||
          interrupted;
      final (state, probe) = await mountFight(tester);
      final bossTag = probe.ownerTag();
      const targetTag = 'MarionettaOcu:3690TEST';
      final bossSheet = state.schedePersonaggio.first as Map;
      bossSheet['monsterBookSourceId'] = 'marionettista_boss';
      bossSheet['planarRuntime'] = <String, dynamic>{
        'encounterRules': {'necthrallControlDt': dt},
      };
      state.schedePersonaggio.add(
        probe.snapshot()
          ..remove('monsterBookSourceId')
          ..['id'] = targetTag
          ..['sheetTag'] = targetTag
          ..['nome'] = 'Marionetta di prova'
          ..['currentVolonta'] = '1'
          ..['volonta'] = '1',
      );
      final tokens = (state.masterInitiativeTokens as List)
          .cast<Map<String, dynamic>>();
      final boss = tokens.first;
      boss
        ..['id'] = bossTag
        ..['sheetTag'] = bossTag
        ..['side'] = 'enemy'
        ..['monsterBookId'] = 'marionettista_boss'
        ..['fightInstanceId'] = 'necthrall-test-fight';
      tokens
        ..removeRange(1, tokens.length)
        ..add({
          'id': targetTag,
          'sheetTag': targetTag,
          'name': 'Marionetta di prova',
          'side': 'party',
          'status': 'ready',
          'fightInstanceId': 'necthrall-test-fight',
        });
      probe.recordCurrentEncounter();
      state.currentMateriaController.text = '8';
      final configuredBind = CharacterSkill(
        nome: 'Necthbind',
        tipo: 'attiva',
        equipaggiata: true,
        costo: '',
        cooldown: '',
        descrizione: '',
        forme: [
          CharacterSkillForm(
            nome: 'I',
            livello: '0',
            costo: hasCost ? '2 Materia' : '',
            costoStrutturato: hasCost
                ? OculumSkillCost(resource: 'materia', amountExpression: '2')
                : null,
            cooldownStrutturato: hasCost
                ? OculumAbilityCooldown(amount: 3, unit: 'azioni')
                : null,
            effettiStrutturati: [
              OculumStructuredEffect(
                type: 'planar',
                valueExpression: '0',
                target: 'necthrall_bind',
              ),
            ],
          ),
        ],
      );
      final bind = CharacterSkill.fromJson(configuredBind.toJson());
      state.skills.add(bind);

      final applying = shortcut
          ? probe.openCombatActionPanel(OculumCombatAbilityRole.support)
          : probe.useCharacterSkill(bind);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      if (shortcut) {
        final action = find.text('Necthbind · Controlla nemico');
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.text('I · 2 Materia'), findsOneWidget);
        await tester.tap(find.text('I · 2 Materia'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
      }
      expect(find.text('Necthbind · Prova di Volontà'), findsOneWidget);
      if (replacedBeforePayment) {
        tokens.last['fightInstanceId'] = 'replacement-fight';
      }
      await tester.tap(find.text('Marionetta di prova').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      if (hasCost && !replacedBeforePayment) {
        expect(find.text('Necthbind / I'), findsOneWidget);
        if (replacedDuringPayment) {
          tokens.last['fightInstanceId'] = 'replacement-fight';
        }
        if (interrupted) {
          tokens.first['bottledCloudPendingActions'] = 1;
        }
        await tester.tap(
          cancel
              ? find.widgetWithText(TextButton, 'Annulla').last
              : find.widgetWithText(FilledButton, 'Conferma').last,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
      }
      await applying;
      final activeBoss = tokens.singleWhere(
        (token) => token['sheetTag'] == bossTag,
      );
      if (hasCost) {
        expect(
          state.currentMateriaController.text,
          stopsBeforeBinding ? '8' : '6',
        );
        expect(
          bind.forme.single.cooldownStrutturato!.remaining,
          stopsBeforeBinding ? 0 : 3,
        );
      }
      if (stopsBeforeBinding) {
        expect(activeBoss['actionUsed'] == true, interrupted);
        expect(activeBoss['necthrallControl'], isNull);
        await closeFixture(tester, probe);
        return;
      }
      expect(activeBoss['actionUsed'], isTrue);
      final binding = activeBoss['necthrallControl'];
      if (dt == 100) {
        expect((binding as Map)['targetTag'], targetTag);
        expect(binding['dt'], 100);
        if (breakSpindle) {
          final puppet = tokens.singleWhere(
            (token) => token['sheetTag'] == targetTag,
          );
          puppet
            ..['reactionMax'] = 1
            ..['reactionUsed'] = 0
            ..['reactionUsedRound'] = probe.masterRound()
            ..['reactionPoolInitialized'] = true
            ..['reactionPoolRound'] = probe.masterRound()
            ..['reactionNormalFirstRoundLocked'] = false
            ..['reactionFastMax'] = 1
            ..['reactionFastUsed'] = 0;
          final request = <String, dynamic>{
            'id': 'test-attack',
            'targetTag': bossTag,
            'sourceTag': targetTag,
            'targetBodyPart': 'necthrall_spindle',
            'encounterId': probe.activeCombatEncounterId,
            'status': 'pending',
          };
          expect(probe.spendNecthrallDefense(request), 3);
          expect(puppet['reactionUsed'], 1);
          expect(puppet['reactionFastUsed'], 0);
          expect(
            probe.spendNecthrallDefense(
              {...request, 'id': 'second-attack'}..remove('necthrallDefenseCm'),
            ),
            0,
          );
          expect(puppet['reactionFastUsed'], 0);
          await probe.resolveAnatomicalHit(request, hpLost: 100000);
        } else {
          probe.turn();
        }
        expect(
          tokens.singleWhere(
            (token) => token['sheetTag'] == bossTag,
          )['necthrallControl'],
          isNull,
        );
      } else {
        expect(binding, isNull);
      }
      await closeFixture(tester, probe);
    });
  }
}
