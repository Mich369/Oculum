import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/oculum_anatomical_parts.dart';
import 'package:oculum/game/oculum_ferrugryp_rules.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test(
    'Ferrugryp and Osycleiv have their authored anatomy and normal pools',
    () {
      final ferrugryp = monsterBookEntryById('ferrugryp')!;
      final osycleiv = monsterBookEntryById('osycleiv')!;
      expect(ferrugryp.elementId, 'metallo');
      expect(osycleiv.elementId, 'necrotico');
      for (final creature in [ferrugryp, osycleiv]) {
        expect(creature.skillIds, isNotEmpty);
        expect(
          creature.skillIds.any(
            (id) => id.startsWith(oculumMonsterProgressionPrefix),
          ),
          isTrue,
        );
        expect(
          creature.skillIds
              .map(monsterBookConcreteTechnique)
              .whereType<MonsterConcreteTechnique>()
              .map((skill) => skill.name),
          isNot(contains(anyOf('Battipalo', 'Richiamo del maglio'))),
        );
      }
      final winch = oculumMonsterPrecisionAnatomy(
        ferrugryp,
      ).singleWhere((part) => part['id'] == oculumFerrugrypWinchPart);
      expect(winch['material'], 'metal');
      expect(
        oculumAnatomicalPartIsNative(monsterId: ferrugryp.id, part: winch),
        isFalse,
      );
      final anatomy = oculumMonsterPrecisionAnatomy(osycleiv);
      final arms = anatomy.where((part) => part['group'] == 'arms');
      expect(arms, hasLength(2));
      expect(
        anatomy
            .where((part) => '${part['label']}'.contains('lama'))
            .single['id'],
        'arms_2',
      );
      expect(anatomy.any((part) => part['group'] == 'eyes'), isFalse);
    },
  );

  test('recall is lost at zero winch integrity, even without a critical', () {
    const winch = {'id': oculumFerrugrypWinchPart, 'maximumHp': 10};
    final first = oculumApplyAnatomicalPartHit(
      state: const {},
      rule: winch,
      attackId: 'hit-1',
      hpLost: 9,
      critical: true,
      criticalShieldProtected: false,
    );
    expect(first.becameInjured, isTrue);
    expect(oculumFerrugrypCanRecallMaglio(first.state), isTrue);
    final second = oculumApplyAnatomicalPartHit(
      state: first.state,
      rule: winch,
      attackId: 'hit-2',
      hpLost: 1,
      critical: false,
      criticalShieldProtected: false,
    );
    expect(second.reachedZero, isTrue);
    expect(oculumFerrugrypCanRecallMaglio(second.state), isFalse);
  });

  const fight = 'fight-1';
  const turn = 'turn-5';

  OculumFerrugrypBattipalo start() => OculumFerrugrypBattipalo.start(
    fightId: fight,
    personalTurnId: turn,
    sweepPacketIds: ['hit-a', 'hit-b'],
  );

  test('Battipalo needs completed sweep and reactions, then claims once', () {
    var state = start().settleSweepHit(packetId: 'hit-a', damage: 24);
    expect(state.openReactionWindow(['reaction-a']), same(state));
    expect(state.settleSweepHit(packetId: 'hit-a', damage: 99), same(state));
    expect(state.settleSweepHit(packetId: 'other', damage: 99), same(state));
    state = state.settleSweepHit(packetId: 'hit-b', damage: 0);
    expect(state.settledSweepDamage, {'hit-a': 24, 'hit-b': 0});
    state = state.openReactionWindow(['reaction-a', 'reaction-b']);
    state = state.settleReaction(
      reactionId: 'reaction-a',
      stoppedByCritical: false,
    );
    expect(state.canFollowUp(fightId: fight, personalTurnId: turn), isFalse);
    state = state.settleReaction(
      reactionId: 'reaction-b',
      stoppedByCritical: false,
    );
    expect(
      state.canFollowUp(fightId: 'fight-2', personalTurnId: turn),
      isFalse,
    );
    expect(
      state.canFollowUp(fightId: fight, personalTurnId: 'turn-6'),
      isFalse,
    );
    expect(state.canFollowUp(fightId: fight, personalTurnId: turn), isTrue);
    state = state.claimFollowUp(fightId: fight, personalTurnId: turn)!;
    expect(state.claimFollowUp(fightId: fight, personalTurnId: turn), isNull);
  });

  test('stopping critical preserves sweep and prevents the follow-up', () {
    final state = start()
        .settleSweepHit(packetId: 'hit-a', damage: 24)
        .settleSweepHit(packetId: 'hit-b', damage: 9)
        .openReactionWindow(['critical', 'ordinary'])
        .settleReaction(reactionId: 'critical', stoppedByCritical: true)
        .settleReaction(reactionId: 'ordinary', stoppedByCritical: false);
    expect(state.stoppedByCritical, isTrue);
    expect(state.settledSweepDamage, {'hit-a': 24, 'hit-b': 9});
    expect(state.claimFollowUp(fightId: fight, personalTurnId: turn), isNull);
    expect(state.openReactionWindow([]), same(state));
  });
}
