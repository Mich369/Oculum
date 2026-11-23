import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/oculum_spectral_pair_rules.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  const pair = OculumSpectralPair(
    fightId: 'fight-a',
    albashardTag: 'alba-1',
    atrawispTag: 'atra-1',
  );

  test('The draft pair has distinct ring, eye and anchor targets', () {
    final [alba, atra] = oculumSpectralPairEntries;
    expect(alba.id, oculumAlbashardId);
    expect(atra.id, oculumAtrawispId);
    expect(alba.encounterRules['requiredCompanionMonsterId'], atra.id);
    expect(atra.encounterRules['requiredCompanionMonsterId'], alba.id);
    expect(
      oculumMonsterPrecisionAnatomy(alba).map((part) => part['id']),
      containsAll(['eyes', oculumAlbashardRingPart]),
    );
    expect(
      oculumMonsterPrecisionAnatomy(
        atra,
      ).where((part) => part['group'] == 'anchor').map((part) => part['id']),
      [oculumAtrawispFirstAnchorPart, oculumAtrawispSecondAnchorPart],
    );
    for (final monster in [alba, atra]) {
      expect(monsterBookEntryById(monster.id), isNull);
      expect(monster.skillIds, isEmpty);
    }
  });

  test('Scaglia can cover only Albashard or the paired Atrawisp', () {
    bool canProtect(
      String target, {
      String source = 'alba-1',
      String fight = 'fight-a',
    }) => pair.canUseScagliaDiVeglia(
      activeFightId: fight,
      sourceTag: source,
      targetTag: target,
    );

    expect(canProtect('alba-1'), isTrue);
    expect(canProtect('atra-1'), isTrue);
    expect(canProtect('atra-2'), isFalse);
    expect(canProtect('atra-1', source: 'alba-2'), isFalse);
    expect(canProtect('atra-1', fight: 'fight-b'), isFalse);
  });

  test('First confirmed death awards only the corresponding survivor', () {
    final whiteDies = pair.settleDeaths(
      activeFightId: 'fight-a',
      effectId: 'strike-a',
      confirmedDeadTags: {'alba-1'},
    );
    expect(whiteDies.bonus, (targetTag: 'atra-1', stat: 'volonta', amount: 6));
    final blackDies = pair.settleDeaths(
      activeFightId: 'fight-a',
      effectId: 'strike-b',
      confirmedDeadTags: {'atra-1'},
    );
    expect(blackDies.bonus, (targetTag: 'alba-1', stat: 'materia', amount: 6));
    for (final replayOrLater in ['strike-a', 'strike-b']) {
      expect(
        whiteDies.pair
            .settleDeaths(
              activeFightId: 'fight-a',
              effectId: replayOrLater,
              confirmedDeadTags: {'alba-1', 'atra-1'},
            )
            .bonus,
        isNull,
      );
    }
  });

  test('Simultaneous death settles the pair without a survivor bonus', () {
    final otherPair = pair.settleDeaths(
      activeFightId: 'fight-a',
      effectId: 'other-pair',
      confirmedDeadTags: {'alba-2', 'atra-2'},
    );
    expect(otherPair.pair, same(pair));
    final wrongFight = pair.settleDeaths(
      activeFightId: 'fight-b',
      effectId: 'wrong-fight',
      confirmedDeadTags: {'alba-1'},
    );
    expect(wrongFight.pair, same(pair));
    final both = pair.settleDeaths(
      activeFightId: 'fight-a',
      effectId: 'area-hit',
      confirmedDeadTags: {'alba-1', 'atra-1'},
    );
    expect(both.pair.firstDeathEffectId, 'area-hit');
    expect(both.bonus, isNull);
    expect(
      both.pair
          .settleDeaths(
            activeFightId: 'fight-a',
            effectId: 'replay',
            confirmedDeadTags: {'alba-1'},
          )
          .bonus,
      isNull,
    );
  });
}
