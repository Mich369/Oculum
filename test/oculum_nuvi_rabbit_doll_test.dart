import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  test(
    'hat stages, repeated targets and independent adaptation boundaries',
    () {
      expect(oculumRabbitHatHits(['a', 'b', 'c'], 1), ['a']);
      expect(oculumRabbitHatHits(['a', 'b', 'c'], 2), ['a', 'b']);
      expect(oculumRabbitHatHits(['a', 'b'], 3), ['a', 'b', 'a']);
      expect(oculumRabbitHatHits(['a'], 3), ['a', 'a', 'a']);
      expect(oculumRabbitHatHits([], 3), isEmpty);
      expect(oculumRabbitHatDamage(20, 1, 0), 25);
      expect(oculumRabbitHatDamage(20, 2, 0), 30);
      expect(oculumRabbitHatDamage(20, 0, 1), 26);
      expect(oculumRabbitHatDamage(20, 0, 2), 32);
      expect(oculumRabbitHatDamage(20, 1, 1), 31);
      expect(
        [for (var i = 1; i <= 3; i++) oculumRabbitHatRollBonus(i)],
        [-2, 1, 5],
      );
      expect(
        [
          for (var i = 0; i < 100; i++) oculumRabbitHatAdapts(i),
        ].where((v) => v).length,
        60,
      );
      expect(
        oculumRabbitHatElement(
          {'fuoco': .5, 'gelo': 2, 'acqua': 1.5},
          'vento',
          59,
          random: Random(1),
        ),
        'gelo',
      );
      expect(oculumRabbitHatElement({'gelo': 2}, 'vento', 60), 'vento');
      expect(oculumRabbitHatElement({'gelo': .5}, 'vento', 0), 'vento');
    },
  );
  test(
    'six new species have unique names, drops, usable costed forms and coherent elements',
    () {
      final ids = [
        'nuvi',
        'coniglio_prestigiatore',
        'coniglio_plasma',
        'pupazzo_artigliato',
        'medusa_vetro',
        'nocciolo_corazzato',
      ];
      for (final id in ids) {
        final monster = defaultMonsterBookEntries.singleWhere(
          (m) => m.id == id,
        );
        expect(monster.dropIds, isNotEmpty);
        expect(monster.descIt.length, greaterThan(100));
        final art = oculumMonsterBookArt(monster);
        expect(art.skills.length, monster.skillIds.length);
        for (final skill in art.skills) {
          final saved = ArtSkill.fromJson(skill.toJson());
          expect(saved.effettiEvoluzione(1), isNotEmpty);
          for (var form = 1; form <= 3; form++) {
            expect(
              saved.oculumMinimoPerLivello(form),
              lessThanOrEqualTo(saved.oculumMassimoPerLivello(form)),
            );
            if (!saved.tipoPerLivello(form).toLowerCase().contains('passiv')) {
              expect(saved.cooldownPerLivello[form - 1].amount, greaterThan(0));
            }
          }
        }
        if (id == 'nuvi') {
          expect(oculumEnemyAbilityVariants(monster, seed: 19), isEmpty);
          expect(art.openName, isEmpty);
          expect(art.skills.single.nome, 'Volo naturale');
        }
        if (id == 'coniglio_plasma') {
          expect(monster.stats['oculum'], 0);
          final recharge = art.skills.singleWhere(
            (s) => s.nome == 'Ricarica di Materia',
          );
          expect(
            recharge.cooldownPerLivello.take(3).map((cd) => cd.amount),
            everyElement(4),
          );
          expect(
            recharge.effettiEvoluzione(1).single.target,
            'plasma_matter_recharge',
          );
        }
      }
      expect(
        defaultMonsterBookEntries.map((m) => m.id).toSet().length,
        defaultMonsterBookEntries.length,
      );
    },
  );
  testWidgets(
    'permanent flight, reactive shell, hat charge and chains survive the sheet JSON',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 1000),
      );
      final probe = OculumPerformanceProbe(state);
      state.datiCaricati = false;
      if (state.schedePersonaggio.isEmpty) {
        state.schedePersonaggio.add(
          Map<String, dynamic>.from(probe.snapshot())
            ..['sheetTag'] = 'CreaturesOcu:3690TEST'
            ..['id'] = 'CreaturesOcu:3690TEST',
        );
        state.schedaCorrente = 0;
      }
      final nuvi = defaultMonsterBookEntries.singleWhere((m) => m.id == 'nuvi');
      state.skills.clear();
      state.skills.addAll(oculumMonsterBookSkills(nuvi));
      expect(probe.activeEffectBonus('difesa'), 3);
      expect(probe.activeEffectBonus('movimento'), 3);
      probe.tickPlanar();
      probe.tickEffects('turni');
      expect(probe.activeEffectBonus('difesa'), 3);
      final nut = defaultMonsterBookEntries.singleWhere(
        (m) => m.id == 'nocciolo_corazzato',
      );
      state.skills.clear();
      state.skills.addAll(oculumMonsterBookSkills(nut));
      expect(probe.activeEffectBonus('incoming_reduction_percent'), 15);
      probe.applyEffects([
        OculumStructuredEffect(
          type: 'planar',
          target: 'rabbit_hat',
          valueExpression: '1',
        ),
      ]);
      expect(probe.planarStateSnapshot()['rabbitHatStage'], 1);
      await probe.chargeRabbitHat();
      expect(probe.planarStateSnapshot()['rabbitHatStage'], 2);
      await probe.chargeRabbitHat();
      expect(probe.planarStateSnapshot()['rabbitHatStage'], 3);
      expect((probe.snapshot()['planarRuntime'] as Map)['rabbitHatStage'], 3);
      probe.applyEffects([
        OculumStructuredEffect(
          type: 'planar',
          target: 'rabbit_chains',
          valueExpression: '1',
        ),
      ]);
      expect(probe.planarStateSnapshot()['rabbitChains'], true);
      expect(
        probe.conditions.any((c) => c.conditionType == 'immobilizzato'),
        true,
      );
      probe.tickPlanar();
      probe.tickEffects('turni');
      expect(
        probe.conditions.any((c) => c.conditionType == 'immobilizzato'),
        true,
      );
      expect(probe.dollSpring(89), true);
      expect(probe.dollSpring(90), false);
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );
}
