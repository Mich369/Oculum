import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/oculum_mutant_rat_rules.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  test('Ratygrinh and the old spellings find the same mutant rat ID', () {
    final rat = monsterBookEntryById(oculumMutantRatId)!;
    expect(rat.nameIt, 'Ratyrith');
    expect(rat.speciesNameIt, 'Topo Mutante');
    for (final name in [
      'Ratygrinh',
      'Ratygreen',
      'Topo Mutante',
      'Mutant Rat',
    ]) {
      expect(oculumLookupMonsterId(name).exact?.id, rat.id, reason: name);
    }
  });

  test('each form uses its own dice and adds its fixed pup count', () {
    final rat = monsterBookEntryById(oculumMutantRatId)!;
    final skill = oculumMonsterBookArt(rat).skills.single;
    final random = Random(31);
    for (var form = 1; form <= 3; form++) {
      final effect = skill.effettiEvoluzione(form).single;
      expect(effect.type, 'evocazione');
      expect(effect.target, oculumMutantRatSummon);
      expect(effect.valueExpression, ['1d4', '1d6+1', '1d9+3'][form - 1]);
      final counts = {
        for (var i = 0; i < 200; i++)
          oculumResolveStructuredEffectRoll(
            effect,
            variables: const {},
            random: random,
          ).value,
      };
      expect(counts.reduce(min), [1, 2, 4][form - 1]);
      expect(counts.reduce(max), [4, 7, 12][form - 1]);
    }
  });

  test('last eligible attacker takes priority over the random choice', () {
    expect(
      oculumMutantRatBiteTarget(['a', 'b'], 'b', (_) => fail('No draw')),
      'b',
    );
    expect(
      oculumMutantRatBiteTarget(['a', '', 'a', 'b'], 'departed', (size) {
        expect(size, 2);
        return 1;
      }),
      'b',
    );
    expect(
      oculumMutantRatBiteTarget([], 'departed', (_) => fail('No draw')),
      isNull,
    );
  });

  testWidgets(
    'two calls coexist and the active pup spends one bite through Defense',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      final hero = probe.ownerTag();
      final rats = (state.masterInitiativeTokens as List).cast<Map>();
      final owner = rats.singleWhere((token) => token['sheetTag'] == 'ENEMY');
      owner['monsterBookId'] = oculumMutantRatId;
      state.scudoController.text = '15';
      final hpBefore = int.parse(state.currentHpController.text as String);

      final rat = monsterBookEntryById(oculumMutantRatId)!;
      final summon = oculumMonsterBookArt(
        rat,
      ).skills.single.effettiEvoluzione(1).single..valueExpression = '1';
      expect(probe.applyEffects([summon]).single, contains('Un topolino'));
      expect(probe.applyEffects([summon]).single, contains('Un topolino'));
      await tester.pump();
      final pups = rats
          .where((token) => token['summonKind'] == oculumMutantRatPup)
          .toList();
      expect(pups, hasLength(2));
      expect(
        pups.map((token) => token['summonInstanceId']).toSet(),
        hasLength(2),
      );
      final first = pups.first;
      first['summonerTag'] = owner['sheetTag'];
      for (final pup in pups) {
        pup['side'] = 'enemy';
      }
      final other = rats.singleWhere((token) => token['sheetTag'] == 'OTHER');
      other['side'] = 'ally';
      final heroToken = rats.singleWhere((token) => token['sheetTag'] == hero);
      heroToken['monsterBookId'] = oculumMutantRatId;
      probe.recordMutantRatAttempt({
        'id': 'missed-by-other',
        'kind': 'attack',
        'status': 'pending',
        'sourceTag': 'OTHER',
        'targetTag': hero,
        'encounterId': probe.activeCombatEncounterId,
        'scope': probe.permissionScope,
        'attack': -50,
      });
      expect(heroToken['mutantRatLastAggressor'], isNull);
      probe.recordMutantRatAttempt({
        'id': 'missed-by-enemy',
        'kind': 'attack',
        'status': 'pending',
        'sourceTag': 'ENEMY',
        'targetTag': hero,
        'encounterId': probe.activeCombatEncounterId,
        'scope': probe.permissionScope,
        'attack': -50,
      });
      expect(heroToken['mutantRatLastAggressor'], 'ENEMY');
      other['side'] = 'enemy';
      // The first pup's automatic turn advances once to the ordinary hero.
      // Rolling initiative for both summons must not make this assertion
      // depend on whether the two summons happen to be adjacent.
      state.masterInitiativeManualOrder = true;
      rats
        ..remove(heroToken)
        ..insert(rats.indexOf(first) + 1, heroToken);
      for (final (i, token) in rats.indexed) {
        token['manualOrder'] = i;
      }
      final index = rats.indexOf(first);
      expect(first['currentHp'], 1);
      expect(first['reactionMax'], 1);
      expect(first['reactionFastMax'], 0);
      expect(first['actionUsed'], true);
      expect(rats.any((token) => token['sheetTag'] == hero), isTrue);
      await tester.runAsync(() async {
        probe.setTurn(round: 1, activeIndex: index);
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();
      expect(first['mutantRatBiteTarget'], hero);
      expect(first['status'], 'expired');
      expect(first['reactionUsed'], 1);
      expect(pups.last['status'], isNot('expired'));
      expect(int.parse(state.currentHpController.text as String), hpBefore);
      expect(int.parse(state.scudoController.text as String), 5);
      await closeFixture(tester, probe);
    },
  );
}
