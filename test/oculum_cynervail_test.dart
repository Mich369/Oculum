import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  test(
    'Cynerveil keeps its two distinct manual skills and former spellings',
    () {
      final monster = monsterById(oculumCynervailId)!;
      expect(monster.nameIt, 'Cyneryx');
      expect(monster.elementId, 'spirituale');
      expect(oculumMonsterNameSearchAliases(monster), contains('Cinervail'));
      expect(oculumLookupMonsterId('Cinervail').exact?.id, monster.id);
      expect(oculumLookupMonsterId('Cynervail').exact?.id, monster.id);
      final loadout = oculumMonsterBookLoadout(monster, random: Random(1));
      expect(loadout.skills.map((skill) => skill.nome), [
        'Velo d’incenso',
        'Sigillo di cenere',
      ]);
      expect(
        loadout.skills.first.forme.first.descrizione,
        contains('prossimo attacco a distanza'),
      );
      expect(
        loadout.skills.last.forme.first.descrizione,
        contains('prossimo colpo di un alleato'),
      );
      for (final skill in loadout.skills) {
        expect(skill.forme.first.descrizione, contains('manuale del Master'));
        expect(skill.forme.first.effettiStrutturati.single.type, 'planar');
      }
    },
  );

  test('a distinct, damageable lantern retains its state across a save', () {
    final monster = monsterById(oculumCynervailId)!;
    final parts = oculumMonsterPrecisionAnatomy(monster);
    final lantern = parts.singleWhere((p) => p['id'] == oculumCynervailLantern);
    final rule = oculumAnatomicalPartRule(
      monsterId: monster.id,
      physicalDescription: monster.descIt,
      part: lantern,
      maximumBodyHp: 30,
    );
    expect(rule['material'], 'metal');
    expect(oculumCynervailLanternDestroyed({}), isFalse);
    final broken = oculumApplyAnatomicalPartHit(
      state: {},
      rule: rule,
      attackId: 'lantern-break',
      hpLost: rule['maximumHp'] as int,
      critical: false,
      criticalShieldProtected: false,
    );
    expect(broken.reachedZero, isTrue);
    expect(
      oculumCynervailLanternDestroyed(
        jsonDecode(jsonEncode(broken.state)) as Map,
      ),
      isTrue,
    );
  });

  test(
    'Cynervail repeats the 3-turn phase after each possible 1d3 cooldown',
    () {
      for (var roll = 1; roll <= 3; roll++) {
        var rolled = 0;
        int rollCooldown() {
          rolled++;
          return roll;
        }

        var phase = <String, dynamic>{'immaterial': true, 'remaining': 3};
        for (var turn = 1; turn <= 3; turn++) {
          phase = oculumCynervailAdvancePhase(
            phase,
            rollCooldown: rollCooldown,
          );
          if (turn < 3) {
            expect(phase, {'immaterial': true, 'remaining': 3 - turn});
            expect(rolled, 0);
          }
        }
        expect(phase, {'immaterial': false, 'remaining': roll});
        expect(rolled, 1);
        phase = Map<String, dynamic>.from(jsonDecode(jsonEncode(phase)) as Map);
        for (var turn = 1; turn <= roll; turn++) {
          phase = oculumCynervailAdvancePhase(
            phase,
            rollCooldown: rollCooldown,
          );
          if (turn < roll) {
            expect(phase, {'immaterial': false, 'remaining': roll - turn});
          }
        }
        expect(phase, {'immaterial': true, 'remaining': 3});
        expect(
          rolled,
          1,
          reason: 'Reading the saved cooldown must not reroll it',
        );
      }
    },
  );

  testWidgets(
    'Cynervail phases its body, while the lantern takes physical hits',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      state.schedePersonaggio[state.schedaCorrente]['monsterBookSourceId'] =
          oculumCynervailId;
      state.livelloController.text = '3';
      state.gradoController.text = '0';
      state.resilienzaController.text = '30';
      state.currentResilienzaController.text = '30';
      state.currentHpController.text = '250';
      state.scudoController.text = '0';
      state.scudoOculumController.text = '0';
      state.scudoCriticoController.text = '0';
      state.hpTempController.text = '0';
      p.invalidateDerivedCaches();

      Future<Map<String, dynamic>> physicalHit(
        String id, {
        String? part,
        bool canHitIntangible = false,
      }) async {
        final request = <String, dynamic>{
          'id': id,
          'status': 'pending',
          'sourceTag': 'ENEMY',
          'sourceName': 'Avversario',
          'targetTag': p.ownerTag(),
          'scope': p.permissionScope,
          'encounterId': 'encounter_1',
          'choice': part == null ? 'attacco' : 'precisione',
          'natural': 10,
          'dieFaces': 20,
          'attack': 100000,
          'damage': p.defense() + 60,
          'element': 'fisico',
          'level': 0,
          'grade': 0,
          if (canHitIntangible) 'canHitIntangible': true,
          'targetBodyPart': ?part,
          'effects': <Map<String, dynamic>>[],
        };
        state.onlineCombatRequests[id] = request;
        await p.resolveCombatDefense(request, 'cm', 20, natural: 10);
        return request;
      }

      final before = p.currentHp();
      expect(
        (await physicalHit('cynervail-body-before'))['cynervailBodyPhased'],
        isTrue,
      );
      expect(p.currentHp(), before);
      final bypassHit = await physicalHit(
        'cynervail-ethereal-piercing',
        canHitIntangible: true,
      );
      expect(bypassHit['cynervailBodyPhased'], isNull);
      expect(p.currentHp(), lessThan(before));
      final beforeLantern = p.currentHp();
      final hit = await physicalHit(
        'cynervail-lantern',
        part: oculumCynervailLantern,
      );
      expect(hit['cynervailBodyPhased'], isNull);
      expect(p.currentHp(), lessThan(beforeLantern));
      // Settle the rest of the part's structural HP through the real part path.
      await p.anatomicalTargetHit(
        {
          'id': 'cynervail-lantern-break',
          'sourceTag': 'ENEMY',
          'targetBodyPart': oculumCynervailLantern,
        },
        hpLost: 1000,
        critical: false,
      );
      expect(
        oculumCynervailLanternDestroyed(p.anatomicalPartsSnapshot()),
        isTrue,
      );
      final wounded = p.currentHp();
      expect(
        (await physicalHit('cynervail-body-after'))['cynervailBodyPhased'],
        isNull,
      );
      expect(p.currentHp(), lessThan(wounded));
      await closeFixture(tester, p);
    },
  );
}
