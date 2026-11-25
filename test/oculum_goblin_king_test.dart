import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/oculum_goblin_king_rules.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  test('the king has three distinct authored and editable skills', () {
    final king = monsterBookEntryById(oculumGoblinKingId)!;
    expect(
      [
        king.stats['resilienza'],
        king.stats['volonta'],
        king.stats['materia'],
        king.stats['oculum'],
      ],
      [6, 9, 4, 9],
    );
    final art = oculumMonsterBookArt(king);
    expect(art.skills.map((skill) => skill.nome), [
      'Richiamo della guardia',
      'Sparizione del Re',
      'Colpo regale',
    ]);
    final guard = art.skills[0], vanish = art.skills[1], strike = art.skills[2];
    expect(guard.cooldownPerLivello.take(3).map((cd) => cd.amount), [5, 4, 3]);
    expect(vanish.cooldownPerLivello.take(3).map((cd) => cd.amount), [2, 2, 2]);
    expect(strike.cooldownPerLivello.take(3).map((cd) => cd.amount), [5, 5, 5]);
    for (var form = 1; form <= 3; form++) {
      expect(guard.oculumMinimoPerLivello(form), [2, 3, 4][form - 1]);
      expect(
        vanish.effettiEvoluzione(form).single.valueExpression,
        ['12', '13', '15'][form - 1],
      );
    }
    vanish.effettiEvoluzione(1).single.valueExpression = '18';
    expect(
      ArtSkill.fromJson(
        vanish.toJson(),
      ).effettiEvoluzione(1).single.valueExpression,
      '18',
    );
  });

  test('royal damage floors current Power and guardian stats scale', () {
    expect(oculumGoblinRegalStrikeBonus(31), 7);
    expect(oculumGoblinRegalStrikeBonus(0), 0);
    expect(oculumGoblinRegalStrikeBonus(-9), 0);
    expect(oculumGoblinRegalStrikeBonus(31, percent: 50), 15);
    final first = oculumGoblinGuardianStats(form: 1, level: 3, grade: 0);
    final last = oculumGoblinGuardianStats(form: 3, level: 3, grade: 0);
    expect(last.resilience, greaterThan(first.resilience));
    expect(last.will, greaterThan(first.will));
    expect(last.matter, greaterThan(first.matter));
  });

  testWidgets('a summoned guard absorbs only once in its reaction pool', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    state.livelloController.text = '0';
    state.gradoController.text = '0';
    final tag = probe.ownerTag();
    final kingHp = int.parse(state.currentHpController.text as String);
    final king = monsterBookEntryById(oculumGoblinKingId)!;
    final skill = oculumMonsterBookArt(king).skills.first;
    final activation = probe.applyEffects(skill.effettiEvoluzione(1));
    expect(activation.single, contains('si unisce'));
    await tester.pump();
    final guard = (state.schedePersonaggio as List).last as Map;
    expect(guard['summonerTag'], tag);
    // The guard must take the hit here so the test can check damage replay.
    guard['fortuna'] = 0;
    guard['karma'] = '0';
    guard['statoForzaPronto'] = false;
    final guardTag = guard['sheetTag'];
    final tokens = state.masterInitiativeTokens as List;
    final guardToken = tokens.whereType<Map>().singleWhere(
      (token) => token['sheetTag'] == guardTag,
    );
    expect(guardToken['reactionMax'], 1);
    expect(guardToken['reactionFastMax'], 0);
    expect(guardToken['actionUsed'], true);
    final guardHp = int.parse('${guard['currentHp']}');
    Map<String, dynamic> attack(String id) => {
      'id': id,
      'status': 'pending',
      'kind': 'attack',
      'sourceTag': 'ENEMY',
      'sourceName': 'Provocatore',
      'targetTag': tag,
      'targetName': 'Re Goblin',
      'scope': probe.permissionScope,
      'encounterId': probe.activeCombatEncounterId,
      'damage': 200,
      'attack': 100,
      'natural': 10,
      'choice': 'vc',
      'element': 'fisico',
    };

    final first = attack('guard-first');
    state.onlineCombatRequests['guard-first'] = first;
    await tester.runAsync(() => probe.resolveCombatDefense(first, 'cm', 0));
    expect(first['goblinGuardianIntercepted'], guardTag);
    expect(int.parse(state.currentHpController.text as String), kingHp);
    expect(guardToken['reactionUsed'], 1);
    final after = int.parse(
      '${(state.schedePersonaggio as List).last['currentHp']}',
    );
    expect(after, lessThan(guardHp));
    await tester.runAsync(() => probe.resolveCombatDefense(first, 'cm', 0));
    expect(
      int.parse('${(state.schedePersonaggio as List).last['currentHp']}'),
      after,
    );
    final second = attack('guard-second');
    state.onlineCombatRequests['guard-second'] = second;
    await tester.runAsync(() => probe.resolveCombatDefense(second, 'cm', 0));
    expect(second['goblinGuardianIntercepted'], isNull);
    await closeFixture(tester, probe);
  });
}
