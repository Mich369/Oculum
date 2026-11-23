import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test('three Acuagoblin variants share habitat and targetable anatomy', () {
    final species = monsterBookEntries
        .where(
          (entry) => entry.encounterRules['speciesId'] == oculumAcuagoblinId,
        )
        .toList();
    expect(species.map((entry) => entry.id), [
      'acuagoblin_variante_territoriale',
      'acuagoblin_variante_predatore',
      'acuagoblin_variante_curioso',
    ]);
    expect(species.map((entry) => entry.generationSide), [
      'neutral',
      'enemy',
      'neutral',
    ]);
    expect(species.map(oculumMonsterNaturalAttitude).toSet(), hasLength(3));
    for (final entry in species) {
      expect(entry.planeIds, ['affogato']);
      expect(oculumMonsterNameSearchAliases(entry), contains('Aquagoblin'));
      final parts = oculumMonsterPrecisionAnatomy(entry);
      final gills = parts.where((part) => part['group'] == 'gills');
      expect(gills.map((part) => part['id']).toSet(), {'gills_1', 'gills_2'});
      expect(gills.map((part) => part['side']).toSet(), {'right', 'left'});
      expect(entry.skillIds, contains(oculumAcuagoblinDodgeSkill));
      expect(entry.skillIds, contains(oculumAcuagoblinWaterJetSkill));
      expect(
        entry.skillIds.any(
          (id) => id.startsWith(oculumMonsterProgressionPrefix),
        ),
        isTrue,
      );
    }
  });

  test(
    'the authored skills keep the editable three-metre and critical rules',
    () {
      final entry = monsterBookEntryById('acuagoblin_variante_predatore')!;
      final art = oculumMonsterBookArt(entry);
      final dash = art.skills.singleWhere((skill) => skill.nome == 'Guizzo');
      final jet = art.skills.singleWhere(
        (skill) => skill.nome == 'Getto d’Acqua',
      );
      for (var form = 1; form <= 3; form++) {
        final move = dash.effettiEvoluzione(form).single;
        expect(move.target, oculumAcuagoblinDodgeEffect);
        expect(move.valueExpression, '3');
        final slow = jet
            .effettiEvoluzione(form)
            .singleWhere((e) => e.type == 'stato');
        expect(slow.criticalOnly, isTrue);
        expect(slow.appliedState, 'rallentato');
        expect(slow.recipient, 'nemico');
        expect(jet.oculumMinimoPerLivello(form), form);
        expect(
          ArtSkill.fromJson(jet.toJson())
              .effettiEvoluzione(form)
              .singleWhere((e) => e.type == 'stato')
              .criticalOnly,
          isTrue,
        );
      }
    },
  );

  test(
    'dash is limited to a successful defense and valid aquatic distance',
    () {
      bool allowed(double distance, {bool water = true, bool success = true}) =>
          oculumCanAcuagoblinDash(
            inWater: water,
            defenseSucceeded: success,
            distanceMeters: distance,
            maximumMeters: 3,
          );
      expect(allowed(3), isTrue);
      expect(allowed(3.01), isFalse);
      expect(allowed(0), isFalse);
      expect(allowed(double.nan), isFalse);
      expect(allowed(2, water: false), isFalse);
      expect(allowed(2, success: false), isFalse);
    },
  );
}
