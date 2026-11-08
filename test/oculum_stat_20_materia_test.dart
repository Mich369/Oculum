import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  test('Schivata Gratuita is limited to attacks with an open defense', () {
    expect(oculumMateria20CanDodgeAttack({'kind': 'attack'}), isTrue);
    for (final request in <Map<String, dynamic>>[
      {'kind': 'corruption'},
      {'oculumShieldBreakImpact': true},
      {'firstDefense': 10},
      {'cycleLunarStomp': 1},
      {
        'effects': [
          {'type': 'planar', 'target': 'lusier_derision'},
        ],
      },
    ]) {
      expect(oculumMateria20CanDodgeAttack(request), isFalse);
    }
  });

  testWidgets('Schivata Gratuita uses one saved charge and recovers on rest', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    state.materiaController.text = '20';
    probe.setResourceCurrent('materia', 20);
    final sheet = state.schedePersonaggio[state.schedaCorrente] as Map;
    final runtime = sheet['planarRuntime'] as Map;
    runtime['stat35'] = {
      'choices20': {'materia': 'matter_free_dodge'},
    };

    Map<String, dynamic> incoming(String id) {
      final request = <String, dynamic>{
        'id': id,
        'status': 'pending',
        'sourceTag': 'ENEMY',
        'sourceName': 'Avversario',
        'targetTag': probe.ownerTag(),
        'scope': probe.permissionScope,
        'encounterId': probe.activeCombatEncounterId,
        'choice': 'vc',
        'natural': 20,
        'attack': 100,
        'damage': 100,
        'element': 'fisico',
      };
      state.onlineCombatRequests[id] = request;
      return request;
    }

    Future<void> dodge(Map<String, dynamic> request) =>
        probe.resolveCombatDefense(request, 'matter_free_dodge', 0);

    final hp = probe.currentHp();
    final first = incoming('free-dodge-first');
    await dodge(first);
    expect(first['status'], 'resolved');
    expect(first['outcome'], 'avoided');
    expect(first['freeReaction'], isNot(true));
    expect(probe.currentHp(), hp);
    await dodge(first);
    final second = incoming('free-dodge-second');
    await dodge(second);
    expect(second['status'], 'pending');

    probe.shortRest();
    await dodge(second);
    expect(second['status'], 'pending');
    probe.shortRest();
    await dodge(second);
    expect(second['outcome'], 'avoided');

    probe.longRest(advanceWorldClock: false);
    final third = incoming('free-dodge-third');
    await dodge(third);
    expect(third['outcome'], 'avoided');
    await closeFixture(tester, probe);
  });
}
