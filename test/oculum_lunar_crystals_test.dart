import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  for (final species in ['mostro_lunare', 'mostro_lunare_demoniaco']) {
    testWidgets(
      '$species crystals use successful hits, separate HP, linked shields and replay-safe JSON',
      (tester) async {
        final (state, p) = await fixtures.mountFight(tester);
        final sheet = p.snapshot()..['monsterBookSourceId'] = species;
        sheet['planarRuntime'] = <String, dynamic>{};
        state.schedePersonaggio[state.schedaCorrente] = sheet;
        p.load(sheet);
        state.scudoCriticoController.text = '0';
        expect(p.criticalShieldTotal(), 4);
        expect(p.shieldTotal(), 400);
        expect(
          p.precisionParts().where(
            (part) => oculumLunarCrystalIds.contains(part['id']),
          ),
          hasLength(4),
        );
        final beforeHp = p.currentHp();
        final initialVc = p.attackVc();
        final initialCm = p.defenseCm();
        Future<Map<String, dynamic>> hit(
          String id,
          String part, {
          int attack = 12,
          int defense = 10,
          int natural = 10,
          String? second,
        }) async {
          final request = <String, dynamic>{
            'id': id,
            'scope': p.permissionScope,
            'encounterId': 'encounter_1',
            'status': 'pending',
            'sourceTag': 'ENEMY',
            'sourceName': 'Avversario',
            'targetTag': p.ownerTag(),
            'attack': attack,
            'damage': 100,
            'natural': natural,
            'choice': 'precisione',
            'targetBodyPart': part,
            'level': 1,
            'grade': 0,
            'element': 'fisico',
            'difficulty': 'normale',
            'lunarSecondCrystal': ?second,
          };
          state.onlineCombatRequests[id] = request;
          await tester.runAsync(
            () => p.resolveCombatDefense(request, 'cm', defense),
          );
          expect(request['status'], 'resolved');
          expect(p.currentHp(), beforeHp);
          return request;
        }

        await hit('miss', 'lunar_crystal_forehead', defense: 20);
        expect(p.lunarCrystals()['lunar_crystal_forehead'], 3);
        for (var i = 0; i < 3; i++) {
          await hit('successful-$i', 'lunar_crystal_forehead');
          expect(p.lunarCrystals()['lunar_crystal_forehead'], 2 - i);
        }
        expect(p.criticalShieldTotal(), 3);
        expect(p.shieldTotal(), 300);
        expect(
          p.precisionParts().any(
            (part) => part['id'] == 'lunar_crystal_forehead',
          ),
          isFalse,
        );
        // Reusing a delivery ID, even after restoring JSON, cannot count another hit.
        final saved =
            jsonDecode(jsonEncode(p.snapshot())) as Map<String, dynamic>;
        state.schedePersonaggio[state.schedaCorrente] = saved;
        p.load(saved);
        await hit('successful-0', 'lunar_crystal_sternum');
        expect(p.lunarCrystals()['lunar_crystal_sternum'], 3);
        await hit('critical', 'lunar_crystal_sternum', attack: 40, defense: 15);
        expect(p.criticalShieldTotal(), 2);
        expect(p.shieldTotal(), 200);
        await hit(
          'double-critical',
          'lunar_crystal_rear',
          attack: 40,
          defense: 15,
          natural: 20,
          second: 'lunar_crystal_abdomen',
        );
        expect(p.criticalShieldTotal(), 0);
        expect(p.shieldTotal(), 0);
        expect(p.attackVc(), initialVc - 5);
        expect(p.defenseCm(), initialCm - 6);
        expect(
          p.precisionParts().where(
            (part) => oculumLunarCrystalIds.contains(part['id']),
          ),
          isEmpty,
        );
        await closeFixture(tester, p);
      },
    );
  }
  testWidgets(
    'a critical to the body cannot consume a crystal-linked critical shield',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      state.schedePersonaggio[state.schedaCorrente]['monsterBookSourceId'] =
          'mostro_lunare';
      state.scudoCriticoController.text = '0';
      final request = <String, dynamic>{
        'id': 'body-critical',
        'scope': p.permissionScope,
        'encounterId': 'encounter_1',
        'status': 'pending',
        'sourceTag': 'ENEMY',
        'sourceName': 'Avversario',
        'targetTag': p.ownerTag(),
        'attack': 40,
        'damage': 5,
        'natural': 10,
        'choice': 'vc',
        'level': 1,
        'grade': 0,
        'element': 'fisico',
        'difficulty': 'normale',
      };
      state.onlineCombatRequests[request['id']] = request;
      await tester.runAsync(() => p.resolveCombatDefense(request, 'cm', 15));
      expect(request['status'], 'resolved');
      expect(p.criticalShieldTotal(), 4);
      expect(p.lunarCrystals().values, everyElement(3));
      await closeFixture(tester, p);
    },
  );
  test(
    'both lunar variants retain exactly twelve editable techniques and the approved resistances',
    () {
      for (final id in ['mostro_lunare', 'mostro_lunare_demoniaco']) {
        final monster = defaultMonsterBookEntries.firstWhere(
          (entry) => entry.id == id,
        );
        expect(monster.skillIds, hasLength(12));
        expect(monster.incomingDamageResistancePresets['taglio'], 'Immunità');
        expect(
          monster.incomingDamageResistancePresets['solare'],
          'Alta Resistenza',
        );
      }
    },
  );
}
