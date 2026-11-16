import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

import 'oculum_october27_resources_test.dart' show closeFixture;
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  test(
    'the whale has twenty separately selectable eyes and one of each shield',
    () {
      final whale = monsterBookEntryById(oculumBalenaMilleOcchiId)!;
      final eyes = oculumMonsterPrecisionAnatomy(
        whale,
      ).where((part) => part['group'] == 'eyes').toList();
      expect(eyes.map((part) => part['id']).toSet(), hasLength(20));
      expect(eyes.where((part) => part['side'] == 'right'), hasLength(10));
      expect(eyes.where((part) => part['side'] == 'left'), hasLength(10));
      expect(whale.encounterRules['criticalShields'], 1);
      expect(whale.encounterRules['oculumDodges'], 1);
      expect(whale.planeIds, ['affogato']);
    },
  );

  test('the whale uses one rank below the lowest opposing sheet', () {
    expect(oculumBalenaFightDifficulty(['oculum']), 'difficile');
    expect(oculumBalenaFightDifficulty(['oculum', 'difficile']), 'normale');
    expect(oculumBalenaFightDifficulty(['facile', 'difficile']), 'facile');
    expect(oculumBalenaFightDifficulty([null, 'oculum']), 'facile');
  });

  test(
    'living opponents determine whale difficulty across the whole fight',
    () {
      final tokens = <Map<String, dynamic>>[
        {'side': 'party', 'campaignDifficulty': 'oculum'},
        {
          'side': 'enemy',
          'fightTeamId': 'rivals',
          'campaignDifficulty': 'difficile',
          'untargetable': true,
        },
        {'side': 'enemy', 'campaignDifficulty': 'facile'},
        {'side': 'neutral', 'campaignDifficulty': 'facile'},
        {'side': 'party', 'campaignDifficulty': 'facile', 'status': 'dead'},
        {'side': 'party', 'campaignDifficulty': 'facile', 'status': 'fled'},
        {'side': 'party', 'campaignDifficulty': 'facile', 'status': 'expired'},
        {'side': 'party', 'campaignDifficulty': 'facile', 'outsideFight': true},
      ];
      expect(oculumBalenaRosterDifficulty(tokens, 'enemy'), 'normale');
      tokens.add({'side': 'ally'});
      expect(oculumBalenaRosterDifficulty(tokens, 'enemy'), 'facile');
    },
  );

  testWidgets('Master snapshot projects the latest known campaign profile', (
    tester,
  ) async {
    final state = await fixtures.mountSheet(tester, const Size(1440, 1000));
    final probe = OculumPerformanceProbe(state);
    final sheets = state.schedePersonaggio as List;
    final rival = <String, dynamic>{
      'nome': 'Rivale della Balena',
      'campaignDifficulty': 'Hard',
    };
    sheets.add(rival);
    probe.ensureSheetTags();
    final rivalTag = rival['sheetTag'];
    final fight = <String, dynamic>{
      'id': 'whale-fight',
      'tokens': [
        {
          'id': rivalTag,
          'sheetTag': rivalTag,
          'campaignDifficulty': 'facile',
        },
        {'id': 'legacy-rival'},
      ],
    };
    final published = probe.publicEncounter(fight)['tokens'] as List;
    expect((published.first as Map)['campaignDifficulty'], 'difficile');
    expect((published.last as Map).containsKey('campaignDifficulty'), isFalse);
    rival['campaignDifficulty'] = 'oculum';
    final refreshed = probe.publicEncounter(fight)['tokens'] as List;
    expect((refreshed.first as Map)['campaignDifficulty'], 'oculum');
    await closeFixture(tester, probe);
  });

  test('the editable ray bonus grows flat for at most five turns', () {
    expect(oculumBalenaChargeDamage(30, -1), 30);
    expect(oculumBalenaChargeDamage(30, 2), 90);
    expect(oculumBalenaChargeDamage(30, 9), 180);
    expect(oculumBalenaChargeDamage(40, 1), 70);
    expect(oculumBalenaRayBaseRange, 18);
    expect(oculumBalenaRayFocusedRange, 27);
    expect(oculumPlanarTechnique(oculumBalenaRaySkillId)!.minimums.first, 3);
    expect(oculumPlanarTechnique(oculumBalenaEyesSkillId)!.minimums.first, 5);
    expect(
      oculumPlanarTechnique(oculumBalenaTeleportSkillId)!.minimums.first,
      6,
    );
  });

  test('Dentysnap preserves its old name and splits the weak gills', () {
    final piranha = monsterBookEntryById('piranha_mortale')!;
    expect(piranha.nameIt, 'Dentysnap');
    expect(oculumLookupMonsterId('Piranha Mortale').exact?.id, piranha.id);
    expect(
      oculumMonsterPrecisionAnatomy(piranha)
          .where((part) => part['group'] == 'gills')
          .map((part) => [part['id'], part['label'], part['weak']]),
      [
        ['gills_1', 'Branchia destra', true],
        ['gills_2', 'Branchia sinistra', true],
      ],
    );
  });
}
