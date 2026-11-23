import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  test('Master assignment can find the passive by Italian or English name', () {
    final entries = oculumAbilityCatalogueEntries(includeMasterPassives: true);
    for (final query in ['Fili della Marionettista', 'Puppeteer Bond']) {
      final results = oculumRankMasterSkillChoices(entries, query);
      expect(results.first.natural?.id, oculumMarionettistaHelpPassiveId);
      expect(
        oculumCatalogueProgressLabel(results.first, 24),
        'III · prossima IV, lvl 25',
      );
      expect(oculumCatalogueProgressLabel(results.first, 25), 'IV');
    }
    expect(
      oculumQuickNpcSkillChoices(
        'spirituale',
        includeAdditionalMonsterArts: true,
      ).any((entry) => entry.natural?.id == oculumMarionettistaHelpPassiveId),
      isFalse,
    );
  });

  test('Necthrall passive has editable level bands and uses the maximum', () {
    final skill = oculumMarionettistaHelpPassive();
    final restored = CharacterSkill.fromJson(skill.toJson());
    expect(restored.id, oculumMarionettistaHelpPassiveId);
    expect(restored.passiva, isTrue);
    expect(
      [
        for (final level in [0, 2, 3, 9, 10, 24, 25, 100])
          oculumMarionettistaHelpValue(restored, level),
      ],
      [1, 1, 3, 3, 9, 9, 12, 12],
    );
    restored.forme.last.effettiStrutturati.single.valueExpression = '17';
    expect(oculumMarionettistaHelpValue(restored, 25), 17);
    expect(
      oculumMarionettistaCombinedHelpBonus(rollerBonus: 12, helperBonuses: []),
      0,
    );
    expect(
      oculumMarionettistaCombinedHelpBonus(
        rollerBonus: 3,
        helperBonuses: [12, 9, 12, 0],
      ),
      12,
    );
  });

  testWidgets('a confirmed victory grants the reward once to each winner', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    state.skills.clear();
    final active = probe.ownerTag();
    const winner = 'VincitoreOcu:3690TEST';
    const absent = 'AssenteOcu:3690TEST';
    for (final tag in [winner, absent]) {
      state.schedePersonaggio.add(
        probe.snapshot()
          ..['id'] = tag
          ..['sheetTag'] = tag
          ..['livello'] = '25',
      );
    }
    Map<String, dynamic> settlement(
      String id, {
      bool summon = false,
      bool killed = true,
      String outcome = 'victory',
    }) => {
      'id': id,
      'name': 'Necthrall',
      'endedEncounterId': 'necthrall-$id',
      'outcome': outcome,
      'won': outcome == 'victory',
      if (killed) 'marionettistaKilled': true,
      'participants': [active, winner],
      'defeated': [
        {'monsterBookId': 'marionettista_boss', 'isSummon': summon},
      ],
    };
    probe.encounterRewards([
      settlement('flight', outcome: 'escape'),
      settlement('summon', summon: true),
      settlement('survived', killed: false),
    ]);
    expect(state.skills, isEmpty);
    probe.encounterRewards([settlement('won'), settlement('won')]);
    expect(probe.snapshot()['necthrallHelpGranted'], isTrue);
    final skills = state.skills as List<CharacterSkill>;
    expect(
      skills.where((s) => s.id == oculumMarionettistaHelpPassiveId),
      hasLength(1),
    );
    final helper = state.schedePersonaggio[1] as Map;
    expect(
      (helper['skills'] as List).single['id'],
      oculumMarionettistaHelpPassiveId,
    );
    expect((helper['faunaPublic'] as Map)['necthrallHelpBonus'], 12);
    expect((state.schedePersonaggio[2]['skills'] as List), isEmpty);
    skills.single.nome = 'Versione personalizzata';
    probe.encounterRewards([settlement('repeat-win')]);
    expect(skills.single.nome, 'Versione personalizzata');
    await closeFixture(tester, probe);
  });

  testWidgets(
    'signed ordinary Help is summed with one strongest actual passive',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      state.skills
        ..clear()
        ..add(oculumMarionettistaHelpPassive());
      state.livelloController.text = '3';
      state.activeStructuredEffects.clear();
      final active = state.schedePersonaggio[0] as Map;
      const a = 'AiutanteOcu:3690TEST';
      const b = 'AiutanteDueOcu:3690TEST';
      const remote = 'RemotoOcu:3690TEST';
      for (final (tag, level) in [(a, 10), (b, 25)]) {
        state.schedePersonaggio.add(
          probe.snapshot()
            ..['id'] = tag
            ..['sheetTag'] = tag
            ..['livello'] = '$level',
        );
      }

      void queue(int base, List<String> sources) {
        active['combatHelpPending'] = base;
        active['combatHelpPendingSources'] = sources;
        active['combatHelpPendingContributions'] = [
          for (final (index, tag) in sources.indexed)
            {
              'id': 'help-$index',
              'sourceTag': tag,
              'necthrallHelpBonus': 999999,
            },
        ];
      }

      queue(7, [a, b, a]);
      expect(probe.consumeHelp(), 19);
      expect(probe.consumeHelp(), 0);
      queue(5, []);
      expect(probe.consumeHelp(), 5, reason: 'No real helper means no passive');
      queue(-5, [remote]);
      expect(
        probe.consumeHelp(),
        -2,
        reason: 'Only the roller has the passive',
      );
      queue(-12, [b]);
      expect(probe.consumeHelp(), 0);
      expect(
        probe.consumeHelp(),
        0,
        reason: 'An exactly cancelled sum is consumed',
      );
      await closeFixture(tester, probe);
    },
  );
}
