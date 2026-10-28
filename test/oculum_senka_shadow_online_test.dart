import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  testWidgets(
    'Senka clone uses its copied shadow form without inheriting mask protection',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final clone = p.senkaClone(20);
      expect(clone, greaterThanOrEqualTo(0));
      final sheet =
          Map<String, dynamic>.from(state.schedePersonaggio[clone] as Map)
            ..['id'] = p.ownerTag()
            ..['sheetTag'] = p.ownerTag();
      final runtime = sheet['planarRuntime'] as Map;
      runtime['senka'] = {'shadowUntilTurn': 100};
      state.schedePersonaggio[state.schedaCorrente] = sheet;
      p.load(sheet);
      expect(
        (state.inventario as List).cast<InventoryItem>().any(
          (item) => item.craftData['senkaMask'] == true,
        ),
        false,
      );
      final request = <String, dynamic>{
        'id': 'clone-shadow',
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
        'targetBodyPart': 'torso',
        'level': 1,
        'grade': 0,
        'element': 'fisico',
        'difficulty': 'normale',
        'effects': [
          {'type': 'danno', 'bypassDefense': true, 'bypassShields': true},
        ],
      };
      final hp = p.currentHp();
      expect(p.senkaShadowEvades(request), true);
      state.onlineCombatRequests[request['id']] = request;
      await tester.runAsync(() => p.resolveCombatDefense(request, 'cm', 10));
      expect(request['outcome'], 'avoided');
      expect(p.currentHp(), hp);
      expect(p.senkaShadowEvades({...request, 'element': 'spirituale'}), false);
      final ended = p.snapshot();
      (ended['planarRuntime'] as Map)['senka'] = {};
      p.load(ended);
      expect(
        p.senkaShadowEvades({...request, 'targetBodyPart': 'mask'}),
        false,
      );
      expect(p.senkaShadowEvades(request), false);
      final step = CharacterSkillForm(
        nome: 'Passo copiato',
        effettiStrutturati: [
          OculumStructuredEffect(
            type: 'planar',
            target: 'senka_shadow_step',
            recipient: 'nemico',
            resource: '6',
          ),
        ],
      );
      for (final incoming in [false, true]) {
        if (incoming) {
          final attack = <String, dynamic>{
            ...request,
            'id': 'clone-step-incoming',
            'status': 'pending',
          };
          state.onlineCombatRequests[attack['id']] = attack;
        }
        final useStep = p.useConfiguredForTest(step);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Passo nell’Ombra'), findsOneWidget);
        await tester.tap(find.widgetWithText(TextButton, 'Annulla').last);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(await useStep, false);
      }
      await closeFixture(tester, p);
    },
  );
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
