import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/widgets/oculum_attack_planner.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  test('opposed theft is capped by real reserve and loses a tie', () {
    expect(oculumTheftDebit(3, 11, 25, 24), 3);
    expect(oculumTheftDebit(20, 11, 25, 24), 11);
    expect(oculumTheftDebit(20, 11, 25, 25), 0);
    expect(oculumTheftDebit(0, 11, 25, 24), 0);
  });

  test('recharge uses only stolen Oculum within max plus five', () {
    expect(oculumTheftGain(1, 10, 5), 1);
    expect(oculumTheftGain(11, 10, 14), 1);
    expect(oculumTheftGain(11, 10, 17), 0);
    expect(oculumTheftGain(11, 10, 0, unmaskedCurrent: 14), 1);
    expect(oculumTheftGain(11, 10, 0, unmaskedCurrent: 15), 0);
  });

  test('late receipts cannot restart the original personal-turn window', () {
    expect(oculumTheftBuffRemaining(3, 7, 7), 3);
    expect(oculumTheftBuffRemaining(3, 7, 9), 1);
    expect(oculumTheftBuffRemaining(3, 7, 10), 0);
  });

  testWidgets(
    'learned Forma I declares one roll and two targets at zero Oculum',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      state.masterInitiativeActiveIndex = 0;
      state.oculumController.text = '0';
      state.currentOculumController.text = '0';
      state.volontaController.text = '6';
      state.currentVolontaController.text = '6';
      state.consumoElevato = true;
      state.fortuna = 0;
      probe.invalidateDerivedCaches();
      final skill = oculumOculumTheftSkill();
      state.skills.add(skill);
      final unlocked = skill.forme.where(
        (form) => oculumSkillRequirementsMet(
          form.unlockRequirements,
          level: 0,
          subtraits: const {},
          kills: 0,
          elementalKills: const {},
          skillCriticals: const {},
        ),
      );
      expect(unlocked.map((form) => form.nome), ['Forma I']);

      int spentActions() => (state.logEventi as List<String>)
          .where((line) => line.contains('[TURNISTICA] Azione usata da'))
          .length;
      final priorActions = spentActions();
      final cast = probe.useCharacterSkill(skill);
      Future<void> settleDialog() async {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
      }

      await settleDialog();
      await tester.tap(find.text('Ricarica Oculum · fino al massimo +5'));
      await settleDialog();
      final planner = find.byType(OculumAttackPlanner);
      final declare = find.widgetWithText(FilledButton, 'Dichiara e tira');
      expect(tester.widget<FilledButton>(declare).onPressed, isNull);
      expect(find.byTooltip('Ripeti sul bersaglio'), findsNothing);
      final secondTarget = find.descendant(
        of: planner,
        matching: find.byType(CheckboxListTile),
      );
      expect(secondTarget, findsOneWidget);
      await tester.ensureVisible(secondTarget);
      await tester.tap(secondTarget);
      await tester.pump();
      expect(tester.widget<FilledButton>(declare).onPressed, isNotNull);
      await tester.tap(declare);
      await settleDialog();
      await cast;

      final packets = (state.onlineCombatRequests as Map).values
          .whereType<Map>()
          .where((packet) => packet['kind'] == oculumOculumTheftKind)
          .toList();
      expect(packets, hasLength(2));
      expect(packets.map((packet) => packet['id']).toSet(), hasLength(2));
      expect(packets.map((packet) => packet['targetTag']).toSet(), {
        'ENEMY',
        'OTHER',
      });
      expect(
        packets.map((packet) => packet['attackGroupId']).toSet(),
        hasLength(1),
      );
      expect(packets.map((packet) => packet['attack']).toSet(), hasLength(1));
      expect(packets.map((packet) => packet['theftLimit']).toSet(), {3});
      expect(spentActions() - priorActions, 1);
      expect(state.currentOculumController.text, '0');
      expect(state.currentVolontaController.text, '6');
      final runtime =
          state.schedePersonaggio[state.schedaCorrente]['planarRuntime'] as Map;
      expect(runtime[oculumTheftUsesRequirement], 1);
      expect(
        skill.forme.map((form) => form.cooldownStrutturato?.remaining).toSet(),
        {3},
      );
      await closeFixture(tester, probe);
    },
  );

  testWidgets(
    'the defender loses actual Oculum once and only to Canalizzazione',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      state.oculumController.text = '12';
      state.currentOculumController.text = '8';
      state.masterInitiativeTokens[1]['fightInstanceId'] = 'theft-test-fight';
      probe.invalidateDerivedCaches();
      final request = <String, dynamic>{
        'id': 'theft:enemy:1',
        'attackGroupId': 'enemy:1',
        'status': 'pending',
        'kind': oculumOculumTheftKind,
        'scope': probe.permissionScope,
        'encounterId': probe.activeCombatEncounterId,
        'sourceTag': 'ENEMY',
        'targetTag': probe.ownerTag(),
        'attack': 23,
        'choice': 'manifestazione_potere',
        'damage': 0,
        'abilityName': 'Sfera Predatrice',
        'theftFight': 'theft-test-fight',
        'theftMode': 'buff',
        'theftLimit': 11,
        'theftBuff': 3,
        'theftTurns': 3,
        'theftTargets': 2,
      };
      state.onlineCombatRequests[request['id']] = request;
      await probe.resolveCombatDefense(request, 'cm', 0);
      expect(request['status'], 'pending');
      await probe.resolveCombatDefense(request, 'canalizzazione', 20);
      expect(request['theftStolen'], 8);
      expect(state.currentOculumController.text, '0');
      final duplicate = {
        ...request,
        'id': 'theft:enemy:replay',
        'status': 'pending',
      };
      state.currentOculumController.text = '4';
      state.onlineCombatRequests[duplicate['id']] = duplicate;
      await probe.resolveCombatDefense(duplicate, 'canalizzazione', 20);
      expect(duplicate['status'], 'resolved');
      expect(duplicate['theftStolen'], 0);
      expect(state.currentOculumController.text, '4');

      final noLongerHostile = {
        ...request,
        'id': 'theft:enemy:2',
        'attackGroupId': 'enemy:2',
        'status': 'pending',
      };
      state.masterInitiativeTokens[1]['side'] = 'party';
      state.onlineCombatRequests[noLongerHostile['id']] = noLongerHostile;
      await probe.resolveCombatDefense(noLongerHostile, 'canalizzazione', 20);
      expect(noLongerHostile['status'], 'resolved');
      expect(noLongerHostile['theftStolen'], 0);
      expect(state.currentOculumController.text, '4');
      await closeFixture(tester, probe);
    },
  );
}
