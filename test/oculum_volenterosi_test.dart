import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;
import 'oculum_protection_wear_test.dart' show prepareProtectionFixture;

void main() {
  for (final speciesId in [
    oculumVolenterosiId,
    oculumResiliumId,
    oculumMaterialId,
  ]) {
    test('$speciesId keeps three selected skills and the authored Open levels', () {
      final monster = monsterBookEntryById(speciesId)!;
      expect(monster.skillIds.length, greaterThanOrEqualTo(9));
      final authored = (monster.encounterRules['authoredUltimateIds'] as List)
          .cast<String>();
      final opens = oculumMonsterBookOpenPool(monster);
      expect(opens, hasLength(3));
      for (final (index, level) in [3, 9, 15].indexed) {
        final open = opens[index];
        final id = authored[index];
        final technique = monsterBookConcreteTechnique(id)!;
        expect(open.openName, technique.name);
        expect(open.openDescription, startsWith('Richiede livello $level.'));
        expect(
          open.openDescriptionEffects.single.id,
          'monster_open_ultimate_$id',
        );
        expect(
          open.openSkillEffects.map((effect) => effect.valueExpression),
          technique.forms.first.map((effect) => effect.formula),
        );
        expect(open.openSkillCooldown?.amount, technique.cooldowns.first);
      }
      final selected = oculumMonsterBookLoadout(monster, random: Random(91));
      expect(selected.art?.openName, opens.first.openName);
      expect(selected.art!.skills.length + selected.skills.length, 3);
      if (speciesId == oculumVolenterosiId) {
        expect(selected.art?.skills, hasLength(3));
      }
      if (speciesId == oculumMaterialId) {
        expect(
          [
            for (final skill in selected.art!.skills)
              ...skill.effettiEvoluzione(1),
            for (final skill in selected.skills)
              ...skill.forme.first.effettiStrutturati,
          ].any((effect) => effect.appliedState == 'invisibile'),
          isTrue,
        );
      }
      expect(selected.weakOpen, isNull);
      final restored = CharacterArt.fromJson(selected.art!.toJson());
      expect(
        restored.openSkillEffects.map((effect) => effect.id),
        opens.first.openSkillEffects.map((effect) => effect.id),
      );
    });
  }

  testWidgets('Volenterosi uses one editable duration and spends only its own Shield', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    prepareProtectionFixture(state, probe);
    state.resilienzaController.text = '20';
    state.volontaController.text = '20';
    state.materiaController.text = '20';
    probe.setResourceCurrent('resilienza', 20);
    probe.setResourceCurrent('volonta', 20);
    probe.setResourceCurrent('materia', 20);
    state.scudoController.text = '25';
    final ordinaryShield = probe.shieldTotal();
    final will = probe.visibleResourceCurrent('volonta');
    final matter = probe.visibleResourceCurrent('materia');
    final hp = probe.currentHp();

    expect(probe.volenterosiAttackWillBonus(), 0);
    state.schedePersonaggio[0]['monsterBookSourceId'] = oculumVolenterosiId;
    expect(probe.volenterosiAttackWillBonus(), will);

    final effects = <OculumStructuredEffect>[
      OculumStructuredEffect(
        id: 'edited_will',
        type: 'modifica_statistica',
        target: 'volonta',
        valueExpression: '11',
        duration: '100',
        mode: 'finche_attivo',
      ),
      OculumStructuredEffect(
        id: 'edited_anchor',
        type: 'planar',
        target: oculumVolenterosiTransformation,
        valueExpression: '17',
        duration: '1d3+1',
      ),
      OculumStructuredEffect(
        id: 'edited_matter',
        type: 'modifica_statistica',
        target: 'materia',
        valueExpression: '7',
        mode: 'finche_attivo',
      ),
    ];
    probe.applyEffects(effects, source: 'Forma del Voto');
    expect(probe.shieldTotal(), ordinaryShield + 17);
    expect(probe.visibleResourceCurrent('volonta'), will + 11);
    expect(probe.visibleResourceCurrent('materia'), matter + 7);
    expect(probe.resourceCurrent('volonta'), 20);
    expect(probe.volenterosiAttackWillBonus(), will + 11);

    final saved = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(probe.snapshot())) as Map,
    );
    final bundle = (saved['activeStructuredEffects'] as List)
        .whereType<Map>()
        .where((effect) => effect['volenterosiTransformation'] == true)
        .toList();
    final duration = bundle.first['remaining'] as int;
    expect(duration, inInclusiveRange(2, 4));
    expect(bundle.map((effect) => effect['remaining']), [duration, duration, duration]);
    state.schedePersonaggio[0] = saved;
    probe.load(saved);
    expect(probe.shieldTotal(), ordinaryShield + 17);

    await probe.damageResolved(8, bypassDefense: true);
    expect(probe.currentHp(), hp);
    expect(probe.shieldTotal(), ordinaryShield + 9);
    for (var turn = 1; turn < duration; turn++) {
      probe.tickEffects('turni');
      expect(probe.shieldTotal(), ordinaryShield + 9);
    }
    probe.tickEffects('turni');
    expect(probe.shieldTotal(), ordinaryShield);
    expect(probe.visibleResourceCurrent('volonta'), will);
    expect(probe.visibleResourceCurrent('materia'), matter);
    expect(probe.volenterosiAttackWillBonus(), will);

    probe.applyEffects(effects, source: 'Forma del Voto');
    probe.applyEffects(effects, source: 'Forma del Voto II');
    expect(probe.shieldTotal(), ordinaryShield + 17);
    expect(probe.volenterosiAttackWillBonus(), will + 11);
    probe.finishPlanarFight();
    expect(probe.shieldTotal(), ordinaryShield);
    expect(probe.volenterosiAttackWillBonus(), will);
    await closeFixture(tester, probe);
  });
}
