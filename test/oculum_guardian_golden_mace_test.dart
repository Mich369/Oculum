import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

const _maceId = 'guardiano_solare_mazza_oro';

ArtSkill _mace() => oculumMonsterBookArt(
  monsterById('guardiano_solare')!,
).skills.singleWhere((skill) => skill.nome == 'Mazza d’oro');

void main() {
  test(
    'Guardian gains an additional golden mace with exact editable forms',
    () {
      final guardian = monsterById('guardiano_solare')!;
      expect(guardian.skillIds, contains(_maceId));
      expect(guardian.skillIds, contains('guardiano_solare_tech_0'));
      final mace = _mace();
      final saved = ArtSkill.fromJson(mace.toJson());
      for (var form = 1; form <= 3; form++) {
        final effect = saved.effettiEvoluzione(form).single;
        expect(effect.type, 'danno_percentuale');
        expect(effect.valueExpression, ['20', '30', '50'][form - 1]);
        expect(effect.duration, ['1d3', '1d3+2', '1d3+3'][form - 1]);
        expect(effect.mode, 'finche_attivo');
        expect(effect.stackable, isFalse);
        expect(saved.risorsaCostoPerLivello(form), 'oculum');
        expect(saved.oculumMinimoPerLivello(form), [2, 4, 6][form - 1]);
        expect(saved.oculumMassimoPerLivello(form), [2, 4, 6][form - 1]);
        expect(saved.cooldownPerLivello[form - 1].amount, [4, 6, 8][form - 1]);
      }
      expect(
        monsterBookSkillText(_maceId),
        contains('+30% Danni per 1d3+2 turni'),
      );
      expect(
        monsterBookSkillText(_maceId),
        isNot(contains('al prossimo attacco')),
      );
      expect(guardian.dropIds, isNot(contains(_maceId)));
    },
  );

  test(
    'mace duration die is rolled once and stays within each confirmed range',
    () {
      final forms = _mace().effettiPerLivello;
      for (var form = 0; form < 3; form++) {
        final seen = <int>{};
        for (var seed = 0; seed < 100; seed++) {
          final resolved = oculumResolveStructuredEffectRoll(
            forms[form].single,
            variables: const {},
            random: Random(seed),
          );
          seen.add(resolved.baseDuration);
          expect(resolved.dice.rolls, hasLength(1));
          expect(resolved.value, [20, 30, 50][form]);
        }
        final offset = [0, 2, 3][form];
        expect(seen, {1 + offset, 2 + offset, 3 + offset});
        expect(forms[form].single.duration, ['1d3', '1d3+2', '1d3+3'][form]);
      }
    },
  );

  test(
    'saved personal mace tuning is independent from new catalog definitions',
    () {
      final custom = ArtSkill.fromJson(_mace().toJson());
      custom.effettiPerLivello[1].single.valueExpression = '37';
      custom.effettiPerLivello[1].single.duration = '1d3+5';
      custom.oculumMinimiPerLivello[1] = 7;
      custom.oculumMassimiPerLivello[1] = 7;
      final restored = ArtSkill.fromJson(custom.toJson());
      expect(restored.effettiEvoluzione(2).single.valueExpression, '37');
      expect(restored.effettiEvoluzione(2).single.duration, '1d3+5');
      expect(restored.oculumMinimoPerLivello(2), 7);
      expect(_mace().effettiEvoluzione(2).single.valueExpression, '30');
      expect(_mace().effettiEvoluzione(2).single.duration, '1d3+2');
    },
  );

  testWidgets(
    'actual mace activation pays Oculum and A/R/RV once, with cooldown blocking repeats',
    (tester) async {
      for (var form = 1; form <= 3; form++) {
        final (state, probe) = await fixtures.mountFight(tester);
        final sheet = probe.snapshot()
          ..['livello'] = '9'
          ..['grado'] = '0'
          ..['oculum'] = '40'
          ..['currentOculum'] = '40'
          ..['normalCurrentOculum'] = 40
          ..['maxOculum'] = 40;
        probe.load(sheet);
        final art = oculumMonsterBookArt(monsterById('guardiano_solare')!)
          ..hasIntegrity = false;
        final skillIndex = art.skills.indexWhere(
          (skill) => skill.nome == 'Mazza d’oro',
        );
        final mace = art.skills[skillIndex];
        state.arti
          ..clear()
          ..add(art);
        state.skills.clear();
        state.activeStructuredEffects.clear();
        state.masterInitiativeRound = 2;
        state.masterInitiativeActiveIndex = form == 1 ? 0 : 1;
        final token = state.masterInitiativeTokens.first as Map;
        token['actionUsed'] = false;
        token['reactionPoolInitialized'] = true;
        token['reactionPoolRound'] = 2;
        token['reactionNormalFirstRoundLocked'] = false;
        token['reactionMax'] = 1;
        token['reactionUsed'] = form == 3 ? 1 : 0;
        token['reactionUsedRound'] = 2;
        token['initialFastReactionExpired'] = false;
        token['reactionFastMax'] = 1;
        token['reactionFastUsed'] = 0;
        token['reactionFastTurnKey'] = '2';
        probe.recordCurrentEncounter();
        final initialIndex = state.masterInitiativeActiveIndex;
        final initialResources = probe.combatTurnResources();
        expect(initialResources['actions'], form == 1 ? 1 : 0);
        expect(initialResources['reactions'], form == 3 ? 0 : 1);
        expect(initialResources['fast'], 1);
        final initialOculum = probe.availableArtResource('oculum');
        final initialDamage = probe.damageTotal();
        final activation = probe.useArtSkill(0, skillIndex, form);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(AlertDialog), findsOneWidget);
        final confirm = find.widgetWithText(FilledButton, 'Conferma').last;
        expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
        await tester.tap(confirm);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await activation;
        expect(mace.livello, form);
        expect(
          probe.availableArtResource('oculum'),
          initialOculum - [2, 4, 6][form - 1],
        );
        expect(
          mace.cooldownPerLivello[form - 1].remaining,
          [4, 6, 8][form - 1],
        );
        expect(
          probe.damageTotal(),
          oculumDamageWithPercentage(initialDamage, [20, 30, 50][form - 1]),
        );
        final resources = probe.combatTurnResources();
        if (form == 1) {
          expect(token['actionUsed'], isTrue);
        } else {
          expect(state.masterInitiativeActiveIndex, initialIndex);
          expect(state.masterInitiativeRound, 2);
          final key = form == 2 ? 'reactions' : 'fast';
          expect(resources[key], initialResources[key]! - 1);
        }
        final oculumAfter = probe.availableArtResource('oculum');
        final resourcesAfter = probe.combatTurnResources();
        await probe.useArtSkill(0, skillIndex, form, again: true);
        await tester.pump();
        expect(find.byType(AlertDialog), findsNothing);
        expect(probe.availableArtResource('oculum'), oculumAfter);
        expect(probe.combatTurnResources(), resourcesAfter);
        expect(
          probe.structuredEffects().where(
            (effect) => '${effect['source']}'.contains('Mazza d’oro'),
          ),
          hasLength(1),
        );
        await closeFixture(tester, probe);
      }
    },
  );

  testWidgets(
    'mace buffs real damage for personal turns and survives save reload',
    (tester) async {
      final (state, probe) = await fixtures.mountFight(tester);
      state.activeStructuredEffects.clear();
      final before = probe.damageTotal();
      expect(before, greaterThan(0));
      final effect = _mace().effettiEvoluzione(2).single;
      final log = probe.applyEffects([effect], source: 'Mazza d’oro');
      expect(log.join(' '), contains('durata'));
      final active = probe.structuredEffects().singleWhere(
        (row) => row['source'] == 'Mazza d’oro',
      );
      final turns = readIntValue(active['remaining']);
      expect(turns, inInclusiveRange(3, 5));
      expect(active['value'], 30);
      expect(probe.damageTotal(), oculumDamageWithPercentage(before, 30));
      expect(probe.consumeNextAttackEffects(), isFalse);
      expect(probe.damageTotal(), oculumDamageWithPercentage(before, 30));

      probe.load(probe.snapshot());
      expect(probe.damageTotal(), oculumDamageWithPercentage(before, 30));
      expect(
        probe.structuredEffects().singleWhere(
          (row) => row['source'] == 'Mazza d’oro',
        )['remaining'],
        turns,
      );
      for (var turn = 1; turn < turns; turn++) {
        probe.tickEffects('turni');
        expect(probe.damageTotal(), oculumDamageWithPercentage(before, 30));
      }
      probe.tickEffects('turni');
      expect(probe.damageTotal(), before);
      expect(
        probe.structuredEffects().where(
          (row) => row['source'] == 'Mazza d’oro',
        ),
        isEmpty,
      );
      await closeFixture(tester, probe);
    },
  );

  testWidgets('changing mace form replaces its bonus instead of stacking it', (
    tester,
  ) async {
    final (state, probe) = await fixtures.mountFight(tester);
    state.activeStructuredEffects.clear();
    final before = probe.damageTotal();
    final mace = _mace();
    probe.applyEffects(mace.effettiEvoluzione(1), source: 'Mazza d’oro');
    expect(probe.damageTotal(), oculumDamageWithPercentage(before, 20));
    probe.applyEffects(mace.effettiEvoluzione(3), source: 'Mazza d’oro');
    expect(probe.damageTotal(), oculumDamageWithPercentage(before, 50));
    expect(
      probe.structuredEffects().where((row) => row['source'] == 'Mazza d’oro'),
      hasLength(1),
    );
    expect(
      probe.structuredEffects().singleWhere(
        (row) => row['source'] == 'Mazza d’oro',
      )['remaining'],
      inInclusiveRange(4, 6),
    );
    await closeFixture(tester, probe);
  });
}
