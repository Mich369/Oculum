import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;
import 'oculum_protection_wear_test.dart' show prepareProtectionFixture;

void main() {
  testWidgets(
    'Gun Shield fires once at the parried attacker without a turn spend',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      prepareProtectionFixture(state, probe);
      final gunShield = InventoryItem(
        nome: 'Gun Shield',
        peso: 1,
        quantita: 1,
        note: '',
        arma: true,
        protegge: true,
        craftData: {
          'gunShield': true,
          'gunFollowupDamage': 15,
          'gunFollowupCooldown': 2,
        },
      );
      state.inventario.add(gunShield);
      probe.equipItem(gunShield, true);
      final attacker = probe.attackTargetTags().first;
      final encounter = probe.combatTurnEncounter()['encounterId'];

      Future<void> parry(String id, {int natural = 12}) async {
        final request = <String, dynamic>{
          'id': id,
          'sourceTag': attacker,
          'sourceName': 'Attaccante originale',
          'targetTag': probe.ownerTag(),
          'scope': probe.permissionScope,
          'encounterId': encounter,
          'attack': 20,
          'damage': 30,
          'element': 'fisico',
          'natural': 10,
          'status': 'pending',
          'effects': <Map<String, dynamic>>[],
        };
        state.onlineCombatRequests[id] = request;
        await probe.resolveCombatDefense(request, 'cm', 25, natural: natural);
        expect(request['outcome'], 'avoided');
      }

      Map? opportunity() =>
          (probe.snapshot()['planarRuntime'] as Map?)?['gunShieldFollowup']
              as Map?;
      List<Map> shots() => (state.onlineCombatRequests as Map).values
          .whereType<Map>()
          .where((request) => request['gunFollowup'] == true)
          .toList();

      await parry('negative-natural', natural: 1);
      expect(opportunity(), isNull);
      await parry('original-block');
      expect(opportunity()?['target'], attacker);
      expect(shots(), isEmpty);

      final home = tester.element(find.byType(OculumHomePage));
      unawaited(
        showDialog<void>(
          context: home,
          builder: (context) => Dialog(
            child: SizedBox(
              width: 1000,
              height: 500,
              child: SingleChildScrollView(child: probe.combatAbilityBar()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(
        find.byKey(const PageStorageKey('combat_abilities_defense')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      final fire = find.text('Gun Shield · Colpo gratuito');
      expect(fire, findsOneWidget);
      await tester.tap(fire);
      await tester.pump();
      if (fire.evaluate().isNotEmpty) await tester.tap(fire);
      await tester.pump();
      final shot = shots().single;
      expect(shot['gunFollowupOrigin'], 'original-block');
      expect(shot['targetTag'], attacker);
      expect(shot['damage'], 15);
      expect(shot.containsKey('turnResourceSpends'), false);
      expect(opportunity()?['target'], isNull);
      Navigator.of(home).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      final readyAt = opportunity()?['readyAtTurn'] as int;
      probe.reportedTurn(readyAt - 1);
      await parry('during-cooldown');
      expect(opportunity()?['target'], isNull);
      probe.reportedTurn(readyAt);
      await parry('after-cooldown');
      expect(opportunity()?['target'], attacker);
      await closeFixture(tester, probe);
    },
  );
}
