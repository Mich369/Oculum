import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

import 'oculum_october27_resources_test.dart' show closeFixture;
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  testWidgets('editing an element preserves only explicit resistances', (
    tester,
  ) async {
    final state = await fixtures.mountSheet(tester, const Size(1440, 1000));
    final probe = OculumPerformanceProbe(state);
    addTearDown(resetMonsterBookEntries);
    const id = 'armadillo_cristallo';
    final armadillo = monsterBookEntryById(id)!;
    expect(armadillo.incomingDamageResistancePresets['roccia'], isNotNull);

    unawaited(probe.editMonsterBookEntry(armadillo));
    await tester.pumpAndSettle();
    final element = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          const {'Elemento', 'Element'}.contains(widget.decoration?.labelText),
    );
    await tester.ensureVisible(element);
    await tester.enterText(element, 'acqua');
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();
    final edited = probe.lookup(id)!;
    final restored = MonsterBookEntry.fromJson(edited.toJson());
    final campaign = probe.campaignSnapshot();
    probe.loadCampaign(campaign);
    for (final entry in [edited, restored, probe.lookup(id)!]) {
      expect(entry.elementId, 'acqua');
      expect(entry.damageResistancePresets, armadillo.damageResistancePresets);
      expect(entry.incomingDamageResistancePresets['roccia'], isNull);
      expect(
        entry.incomingDamageResistancePresets['acqua'],
        'Resistenza Leggera',
      );
      expect(entry.incomingDamageResistancePresets['contundente'], 'Fragilità');
    }
    await closeFixture(tester, probe);
  });

  test(
    'saving legacy Idrax keeps absent modern stats and the derived base',
    () {
      final idrax = monsterById('idrax')!;
      final edited = oculumMonsterBookEditedStats(idrax.stats, {
        for (final key in const [
          'level',
          'resilienza',
          'volonta',
          'materia',
          'oculum',
          'hp',
          'atk',
          'def',
          'spd',
        ])
          key: idrax.stats[key]?.toString() ?? '',
      });
      expect(edited, idrax.stats);
      final saved = MonsterBookEntry.fromJson(
        idrax.copyWith(nameIt: 'Idrax della caverna', stats: edited).toJson(),
      );
      expect(
        oculumMonsterCreationStats(saved, 0),
        oculumMonsterCreationStats(idrax, 0),
      );
    },
  );

  test('explicit zero and a cleared legacy stat retain distinct meanings', () {
    expect(
      oculumMonsterBookEditedStats(
        {'hp': 70, 'spd': 17, 'criticalShield': 3},
        {'hp': '', 'resilienza': '0', 'oculum': '-1', 'spd': 'x'},
      ),
      {'resilienza': 0, 'oculum': 0, 'spd': 17, 'criticalShield': 3},
    );
  });

  test(
    'only a customized skill list switches an ordinary built-in to fixed',
    () {
      final original = monsterById('mimic_base')!;
      final renamed = MonsterBookEntry.fromJson(
        original
            .copyWith(nameIt: 'Mimic locale', descIt: 'Una cassa animata.')
            .toJson(),
      );
      final loadout = oculumMonsterBookLoadout(
        renamed,
        random: Random(7),
        level: 20,
      );
      expect(oculumMonsterBookOpenPool(renamed), hasLength(2));
      expect(loadout.weakOpen, isNotNull);
      expect([
        for (final skill in loadout.skills)
          if (!skill.passiva) skill.nome,
        for (final skill in loadout.art?.skills ?? const <ArtSkill>[])
          if (!skill.tipoPerLivello(1).toLowerCase().contains('passiv'))
            skill.nome,
      ], hasLength(3));

      final customized = renamed.copyWith(skillIds: ['sticky_tongue']);
      final fixed = oculumMonsterBookLoadout(customized, random: Random(7));
      expect(oculumMonsterBookOpenPool(customized), hasLength(1));
      expect(fixed.weakOpen, isNull);
      expect(
        fixed.skills.map((skill) => skill.nome),
        oculumMonsterBookSkills(customized).map((skill) => skill.nome),
      );
    },
  );
}
