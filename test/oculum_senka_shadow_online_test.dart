import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  for (final part in ['mask', 'torso']) {
    testWidgets(
      'Senka $part intangibility avoids real damage, shields and replayed packets',
      (tester) async {
        final (state, p) = await fixtures.mountFight(tester);
        final sheet =
            Map<String, dynamic>.from(
                jsonDecode(
                      File(
                        'output/characters/senka_kamaria/Senka_Kamaria.json',
                      ).readAsStringSync(),
                    )
                    as Map,
              )
              ..['id'] = p.ownerTag()
              ..['sheetTag'] = p.ownerTag();
        p.load(sheet);
        final mask = (state.inventario as List)
            .cast<InventoryItem>()
            .singleWhere((i) => i.craftData['senkaMask'] == true);
        p.manifestSenkaMask(mask, true);
        if (part == 'torso') {
          final active = p.snapshot();
          final runtime = active['planarRuntime'] as Map;
          (runtime['senka'] as Map)['shadowUntilTurn'] = 100;
          p.load(active);
        }
        final beforeHp = p.currentHp();
        final normal = state.scudoController.text;
        final oculum = state.scudoOculumController.text;
        final request = <String, dynamic>{
          'id': 'shadow-$part',
          'scope': p.permissionScope,
          'encounterId': 'encounter_1',
          'status': 'pending',
          'sourceTag': 'ENEMY',
          'sourceName': 'Colpo fisico',
          'targetTag': p.ownerTag(),
          'attack': 30,
          'damage': 40,
          'natural': 10,
          'choice': 'precisione',
          'targetBodyPart': part,
          'level': 1,
          'grade': 0,
          'element': 'fisico',
          'difficulty': 'normale',
          'effects': [
            {'type': 'danno', 'bypassDefense': true, 'bypassShields': true},
          ],
        };
        state.onlineCombatRequests[request['id']] = request;
        await tester.runAsync(() => p.resolveCombatDefense(request, 'cm', 10));
        expect(request['status'], 'resolved');
        expect(request['outcome'], 'avoided');
        expect(request['senkaShadowAvoided'], true);
        expect(p.currentHp(), beforeHp);
        expect(state.scudoController.text, normal);
        expect(state.scudoOculumController.text, oculum);
        final receipt = request['damageReceipt'] as Map;
        expect(receipt['hpLost'], 0);
        expect(receipt['shieldLost'], 0);
        expect(receipt['oculumShieldLost'], 0);
        expect(receipt['temporaryHpLost'], 0);
        await tester.runAsync(() => p.resolveCombatDefense(request, 'cm', 10));
        expect(p.currentHp(), beforeHp);
        // The body is vulnerable after the shadow form ends; only the mask keeps
        // its narrowly targeted passive protection.
        final ended = p.snapshot();
        (ended['planarRuntime'] as Map)['senka'] = {};
        p.load(ended);
        final body = <String, dynamic>{
          ...request,
          'id': 'solid-$part',
          'status': 'pending',
          'targetBodyPart': 'torso',
          'senkaShadowAvoided': false,
        };
        body.remove('damageReceipt');
        state.onlineCombatRequests[body['id']] = body;
        await tester.runAsync(() => p.resolveCombatDefense(body, 'cm', 10));
        expect(body['outcome'], isNot('avoided'));
        expect((body['damageReceipt'] as Map)['hpLost'], greaterThan(0));
        await closeFixture(tester, p);
      },
    );
  }
}
