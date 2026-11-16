import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart'
    show oculumMonsterBookImportArt, oculumMonsterBookLoadout;
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test('selected Eiva names retain their previous search names', () {
    final octocruor = monsterBookEntryById(oculumPiovraSucchiasangueId)!;
    final pynnasway = monsterBookEntryById('affogato_palmatore_dei_nastri')!;
    expect(octocruor.nameIt, 'Octocruor');
    expect(
      oculumMonsterNameSearchAliases(octocruor),
      contains('Piovra succhiasangue'),
    );
    expect(pynnasway.nameIt, 'Pynnasway');
    expect(
      oculumMonsterNameSearchAliases(pynnasway),
      contains('Palmatore dei nastri'),
    );
    final malleysaw = monsterBookEntryById('eiva_serracapo_mosaici')!;
    expect(malleysaw.nameIt, 'Malleysaw');
    expect(
      oculumMonsterNameSearchAliases(malleysaw),
      contains('Serracapo dei mosaici'),
    );
    final corallwhirl = monsterBookEntryById('affogato_vortice_delle_arcate')!;
    expect(corallwhirl.nameIt, 'Corallwhirl');
    expect(
      oculumMonsterNameSearchAliases(corallwhirl),
      contains('Vortice delle Arcate'),
    );
  });

  test('each Piovra keeps two innate moves and draws three Arts from nine', () {
    for (final id in const [
      oculumPiovraSucchiasangueId,
      'piovra_succhiasangue_variante_buio',
      'piovra_succhiasangue_variante_spirituale',
    ]) {
      final entry = monsterBookEntryById(id)!;
      final artPool = oculumMonsterBookImportArt(entry)!.skills;
      expect(artPool, hasLength(9), reason: id);
      final poolNames = artPool.map((skill) => skill.nome).toSet();
      for (final level in [0, 3, 6, 12]) {
        final result = oculumMonsterBookLoadout(
          entry,
          random: Random(level),
          level: level,
        );
        expect(result.skills.map((skill) => skill.nome), [
          'Morso succhiasangue',
          'Presa succhiasangue',
        ], reason: '$id al livello $level');
        final drawn = result.art!.skills.map((skill) => skill.nome).toSet();
        expect(drawn, hasLength(3));
        expect(poolNames, containsAll(drawn));
      }
    }
  });

  test(
    'the Eiva expansion has twenty hostile families with three forms each',
    () {
      final entries = oculumPlanarMonsterEntries
          .where(
            (entry) => entry.encounterRules.containsKey(oculumEivaFamilyIdRule),
          )
          .toList();
      expect(entries, hasLength(60));
      expect(entries.map((entry) => entry.id).toSet(), hasLength(60));
      final families = <String, List<MonsterBookEntry>>{};
      for (final entry in entries) {
        final rules = entry.encounterRules;
        final familyId = rules[oculumEivaFamilyIdRule] as String;
        (families[familyId] ??= []).add(entry);
        expect(entry.planeIds, ['affogato']);
        expect(entry.generationSide, 'enemy');
        expect(entry.isNpc, isFalse);
        expect(entry.stats['level'], 0);
        expect(rules['eivaAreaId'], anyOf('corallo_cavo', 'fronde_eiva'));
        expect(entry.descIt, contains(rules['naturalAttitude'] as String));
        expect(
          oculumMonsterPrecisionAnatomy(entry).any((p) => p['weak'] == true),
          isTrue,
        );
        expect(
          monsterBookEntryById(entry.id)!.skillIds.length,
          greaterThanOrEqualTo(9),
        );
      }

      expect(families, hasLength(20));
      final skillIds = <String>{};
      for (final MapEntry(key: id, value: forms) in families.entries) {
        expect(forms, hasLength(3), reason: id);
        expect(
          forms.map((entry) => entry.elementId).toSet(),
          hasLength(3),
          reason: id,
        );
        final base = forms.singleWhere((entry) => entry.id == id);
        expect(base.encounterRules['proposedNames'], hasLength(2), reason: id);
        for (final form in forms) {
          if (form.id != id) {
            expect(form.id, '${id}_variante_${form.elementId}');
            expect(form.encounterRules['canonicalVariantOf'], id);
          }
          expect(
            form.skillIds.length,
            greaterThanOrEqualTo(2),
            reason: form.id,
          );
          for (final skillId in form.skillIds) {
            expect(skillIds.add(skillId), isTrue, reason: skillId);
            final skill = monsterBookConcreteTechnique(skillId)!;
            expect(skill.element, form.elementId);
            expect(skill.forms, hasLength(3));
            expect(skill.minimums, skill.maximums);
          }
        }
        final mechanics = forms.map((entry) {
          final moves = entry.skillIds.map((id) {
            final technique = monsterBookConcreteTechnique(id)!;
            return technique.forms.first
                .map(
                  (effect) =>
                      '${effect.type}:${effect.target}:${effect.criticalOnly}',
                )
                .join(',');
          }).toList()..sort();
          return moves.join('|');
        });
        expect(mechanics.toSet(), hasLength(3), reason: id);
      }
    },
  );

  test(
    'Piovra and the two fish humanoids keep distinct anatomy and weapons',
    () {
      final octopus = monsterBookEntryById('piovra_succhiasangue')!;
      final parts = oculumMonsterPrecisionAnatomy(octopus);
      expect(parts.where((part) => part['group'] == 'arms'), hasLength(8));
      expect(
        parts.singleWhere((part) => part['id'] == 'feeding_ring')['weak'],
        isTrue,
      );
      expect(octopus.inventoryItems, isEmpty);
      expect(
        octopus.skillIds
            .map(oculumPlanarTechnique)
            .whereType<MonsterConcreteTechnique>()
            .expand((skill) => skill.forms.first)
            .where((effect) => effect.target == 'vampirismo'),
        hasLength(1),
      );

      final hammerhead = monsterBookEntryById('eiva_serracapo_mosaici')!;
      final lionfish = monsterBookEntryById('eiva_pteroi_delle_fronde')!;
      expect(hammerhead.descIt, contains('squalo martello'));
      expect(lionfish.descIt, contains('Pesce scorpione'));
      final realWeapons = <String>{};
      for (final fish in [hammerhead, lionfish]) {
        expect(fish.canWieldWeapons, isTrue);
        final item = fish.inventoryItems.single;
        expect(item['arma'], isTrue);
        expect(item['equipaggiata'], isTrue);
        realWeapons.add((item['craftData'] as Map)['eivaWeaponId'] as String);
        expect(
          oculumMonsterPrecisionAnatomy(fish).map((part) => part['id']),
          contains(fish.encounterRules['eivaWeaponPartId']),
        );
      }
      expect(realWeapons, {
        'sega_due_mani_conchiglia',
        'stocco_guardia_ventaglio',
      });
    },
  );
}
