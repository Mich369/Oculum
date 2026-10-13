import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  test(
    'Rock Slime retains identity and has authored costs and requirements',
    () {
      final monster = monsterById('slime_roccioso')!;
      final art = CharacterArt.fromJson(oculumMonsterBookArt(monster).toJson());
      expect(monster.dropIds, contains('roccia_slime'));
      expect(art.skills, hasLength(3));
      final minimums = [
        [1, 5, 11],
        [1, 4, 7],
        [1, 3, 5],
      ];
      final maximums = [
        [4, 10, 20],
        [3, 6, 10],
        [2, 4, 10],
      ];
      final levels = [
        [0, 5, 13],
        [1, 6, 12],
        [0, 3, 10],
      ];
      for (var skill = 0; skill < 3; skill++) {
        for (var form = 0; form < 3; form++) {
          expect(
            art.skills[skill].oculumMinimoPerLivello(form + 1),
            minimums[skill][form],
          );
          expect(
            art.skills[skill].oculumMassimoPerLivello(form + 1),
            maximums[skill][form],
          );
          expect(
            art.skills[skill].testoEvoluzione(form + 1),
            contains('Richiede livello ${levels[skill][form]}'),
          );
        }
      }
      expect(art.openDescription, contains('Richiede livello 15'));
      expect(art.openBuffEffects, hasLength(5));
      expect(art.openBuff, isNot(contains('@')));
      expect(
        art.skills.first.effettiPerLivello[0].single.mode,
        'prossima_azione',
      );
    },
  );

  testWidgets('Rock Slime block has persisted HP and one shared bounce roll', (
    tester,
  ) async {
    final state = await fixtures.mountSheet(tester, const Size(1440, 900));
    final probe = OculumPerformanceProbe(state);
    final before = probe.damageTotal();
    final attack = probe.applyEffects(
      oculumRockSlimeEffects('rock_slime_ball', 1),
      spentResources: {'oculum': 7},
    );
    expect(attack.join(' '), contains('= 10'));
    expect(
      probe.damageTotal(),
      before + 10,
      reason: 'The bonus applies to the next attack only',
    );
    expect(probe.consumeNextAttackEffects(), isTrue);
    expect(probe.damageTotal(), before, reason: 'The next attack consumes it');
    probe.applyEffects(
      oculumRockSlimeEffects('rock_slime_ball', 1, block: true),
      spentResources: {'oculum': 7},
    );
    final block = state.activeStructuredEffects.firstWhere(
      (dynamic effect) => effect['type'] == 'costrutto',
    );
    expect(block['hp'], 21);
    expect(block['maxHp'], 21);
    expect(block['value'], 0);
    state.activeStructuredEffects.clear();
    final messages = probe.applyEffects(
      oculumRockSlimeEffects('rock_slime_bounce', 2),
    );
    final reaction = state.activeStructuredEffects.firstWhere(
      (dynamic effect) => effect['type'] == 'aggiungi_reazioni',
    );
    final percentage = state.activeStructuredEffects.firstWhere(
      (dynamic effect) => effect['type'] == 'danno_percentuale',
    );
    expect(reaction['value'], inInclusiveRange(1, 3));
    expect(percentage['value'], reaction['value'] * 50);
    expect(
      messages.where((message) => message.contains('1d3 =')),
      hasLength(1),
    );
    probe.tickEffects('turni');
    expect(state.activeStructuredEffects, isEmpty);
    probe.applyEffects(
      oculumRockSlimeEffects('rock_slime_harden', 2),
      spentResources: {'oculum': 5},
    );
    expect(
      state.activeStructuredEffects.firstWhere(
        (dynamic effect) => effect['target'] == 'resilienza',
      )['value'],
      30,
    );
    expect(
      state.activeStructuredEffects.firstWhere(
        (dynamic effect) => effect['target'] == 'difesa',
      )['value'],
      20,
    );
    for (var turn = 0; turn < 6; turn++) {
      probe.tickEffects('turni');
    }
    expect(state.activeStructuredEffects, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 600));
  });
}
