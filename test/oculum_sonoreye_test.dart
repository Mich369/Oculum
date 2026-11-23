import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  test('Sonoreye has an editable high-form floor and a destructible bell', () {
    final monster = monsterBookEntryById(oculumSonoreyeId)!;
    expect(monster.stats['oculum'], 13);
    expect(monster.skillIds, [
      oculumSonoreyeEchoSkill,
      oculumSonoreyeBellSkill,
    ]);
    final echo = oculumPlanarTechnique(oculumSonoreyeEchoSkill)!;
    expect(
      echo.forms[0].any((e) => e.target == oculumSonoreyeEchoMinimumEffect),
      isFalse,
    );
    for (final form in echo.forms.skip(1)) {
      expect(
        form
            .singleWhere((e) => e.target == oculumSonoreyeEchoMinimumEffect)
            .formula,
        '50',
      );
    }
    final bell = oculumMonsterPrecisionAnatomy(
      monster,
    ).singleWhere((part) => part['id'] == oculumSonoreyeBellPart);
    expect(bell['material'], 'metal');
    Map<String, dynamic> anatomy(int damage) => {
      'parts': {
        oculumSonoreyeBellPart: {'maximumHp': 10, 'damageTaken': damage},
      },
    };
    expect(oculumSonoreyeBellIsBroken(anatomy(9)), isFalse);
    expect(oculumSonoreyeBellIsBroken(anatomy(10)), isTrue);
    expect(oculumSonoreyeEchoDamageFloor(61, 50), 31);
  });

  testWidgets('a broken bell blocks Art activation before Oculum payment', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    final monster = monsterById(oculumSonoreyeId)!;
    final art = oculumMonsterBookImportArt(monster)!;
    final bellIndex = art.skills.indexWhere(
      (skill) => skill
          .effettiEvoluzione(1)
          .any((effect) => oculumIsSonoreyeBellEffect(effect.id)),
    );
    expect(bellIndex, isNonNegative);
    final sheet = <String, dynamic>{
      ...probe.snapshot(),
      'monsterBookSourceId': monster.id,
      'oculum': '13',
      'currentOculum': '13',
      'normalCurrentOculum': 13,
      'temporaryOculum': 0,
      'arti': [art.toJson()],
      'planarRuntime': {
        'anatomicalParts': {
          'parts': {
            oculumSonoreyeBellPart: {'maximumHp': 10, 'damageTaken': 10},
          },
        },
      },
    };
    state.schedePersonaggio[0] = sheet;
    probe.load(sheet);
    final before = state.currentOculumController.text;
    expect(before, '13');
    final activation = probe.useArtSkill(0, bellIndex, 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(AlertDialog), findsNothing);
    await activation;
    expect(state.currentOculumController.text, before);
    expect(state.logEventi, contains(contains('campana è rotta')));
    await closeFixture(tester, probe);
  });

  testWidgets('a successful defense leaves Echo damage for the shield', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    state.resilienzaController.text = '20';
    state.currentResilienzaController.text = '20';
    state.currentHpController.text = '100';
    state.scudoController.text = '200';
    probe.invalidateDerivedCaches();
    probe.saveSheet();
    final target = probe.ownerTag();

    Future<Map<String, dynamic>> defend(
      String id, {
      required bool echo,
      int natural = 10,
    }) async {
      final packet = <String, dynamic>{
        'id': id,
        'sourceTag': 'ENEMY',
        'sourceName': 'Sonoreye',
        'sourceMonsterBookId': oculumSonoreyeId,
        'targetTag': target,
        'targetName': 'Eroe',
        'scope': probe.permissionScope,
        'encounterId': probe.activeCombatEncounterId,
        'status': 'pending',
        'kind': 'attack',
        'attack': 20,
        'natural': natural,
        'damage': 61,
        'choice': 'vc',
        'element': 'sonoro',
        'level': 1,
        'grade': 0,
        'difficulty': 'normale',
        if (echo)
          'effects': [
            {
              'id': '${oculumSonoreyeEchoSkill}_forma_2_1',
              'type': 'planar',
              'target': oculumSonoreyeEchoMinimumEffect,
              'valueExpression': '50',
            },
          ],
      };
      state.onlineCombatRequests[id] = packet;
      await tester.runAsync(() => probe.resolveCombatDefense(packet, 'cm', 30));
      expect(packet['status'], 'resolved');
      return packet;
    }

    final normal = await defend('sonoreye-normal', echo: false);
    expect(normal['minimumDamageBeforeProtections'], isNull);
    final missed = await defend('sonoreye-natural-1', echo: true, natural: 1);
    expect(missed['minimumDamageBeforeProtections'], isNull);
    final partial = await defend('sonoreye-echo', echo: true);
    expect(partial['outcome'], 'avoided');
    expect(partial['minimumDamageBeforeProtections'], 31);
    expect((partial['damageReceipt'] as Map)['hpLost'], 0);
    expect((partial['damageReceipt'] as Map)['shieldLost'], greaterThan(0));
    final shieldAfter = probe.shieldTotal();
    await tester.runAsync(() => probe.resolveCombatDefense(partial, 'cm', 30));
    expect(probe.shieldTotal(), shieldAfter);
    await closeFixture(tester, probe);
  });
}
