import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/oculum_oculiath_rules.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_monster_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'the lesser variant uses the same range with weaker editable damage',
    () async {
      final entry = monsterById(oculumLesserOculiathId)!;
      expect(entry.hasNaturalFlight, isTrue);
      expect(entry.skillIds, [oculumLesserOculiathRayTechnique]);
      expect(oculumMonsterHasFixedProgressionSkills(entry), isTrue);
      expect(oculumMonsterHasOculumArt(entry), isTrue);
      final technique = oculumPlanarTechnique(entry.skillIds.single)!;
      for (var i = 0; i < 3; i++) {
        expect(technique.forms[i].first.formula, '${[2, 6, 20][i]}');
        expect(technique.forms[i].last.formula, '${[16, 25, 30][i]}');
        expect(technique.forms[i].last.target, oculumOculiathRayRule);
      }
      final asset = OculumMonsterTheme.desktopIllustrationForId(entry.id)!;
      expect((await rootBundle.load(asset)).lengthInBytes, greaterThan(0));
      expect(oculumOculiathHealthFromResilience(entry.id, 123), 73);
      expect(oculumOculiathHealthFromResilience(entry.id, 1), 1);
      expect(oculumOculiathHealthFromResilience(oculumOculiathId, 123), 123);
    },
  );

  test('each lost greater eye disables its own ray only', () async {
    final entry = monsterById(oculumGreaterOculiathId)!;
    final asset = OculumMonsterTheme.desktopIllustrationForId(entry.id)!;
    expect((await rootBundle.load(asset)).lengthInBytes, greaterThan(0));
    expect(oculumGreaterOculiathWorkingEyes(null), [1, 2, 3, 4, 5]);
    expect(
      oculumGreaterOculiathWorkingEyes({
        'eyes_1': {'maximumHp': 10, 'damageTaken': 10},
        'eyes_2': {'maximumHp': 10, 'damageTaken': 9},
        'eyes_4': {'maximumHp': 10, 'damageTaken': 10},
      }),
      [2, 3, 5],
    );
  });

  test(
    'base Oculiath uses the approved theme and keeps the book portrait empty',
    () async {
      final base = monsterById(oculumOculiathId)!;
      final asset = OculumMonsterTheme.desktopIllustrationForId(base.id)!;
      expect(asset, endsWith('theme_oculiath_canon_20261114.webp'));
      expect((await rootBundle.load(asset)).lengthInBytes, greaterThan(0));
      expect(base.spriteAssetPath, isEmpty);
    },
  );

  test('both Oculiath keep a single editable attack in generated sheets', () {
    for (final (index, (id, rule, bonuses)) in [
      (oculumOculiathId, oculumOculiathRayRule, [5, 12, 40]),
      (oculumGreaterOculiathId, oculumGreaterOculiathRayRule, [10, 24, 60]),
    ].indexed) {
      final entry = monsterById(id)!;
      expect(entry.hasNaturalFlight, isTrue);
      expect(entry.skillIds, [rule]);
      expect(oculumMonsterHasFixedProgressionSkills(entry), isTrue);
      expect(oculumMonsterHasOculumArt(entry), isTrue);
      expect(entry.stats['oculum'], greaterThanOrEqualTo(index == 0 ? 1 : 3));
      expect(entry.encounterRules['levitationWithoutFall'] == true, index == 1);
      final technique = oculumPlanarTechnique(rule)!;
      for (var i = 0; i < 3; i++) {
        expect(technique.forms[i].first.formula, '${bonuses[i]}');
        expect(technique.forms[i].last.formula, '${[16, 25, 30][i]}');
        expect(technique.forms[i].last.maximumTargets, index == 0 ? 1 : 5);
        if (index == 1) {
          expect(technique.forms[i].last.duration, '${[10, 6, 3][i]}');
        }
      }
    }
  });

  test('range includes its exact 3D boundary and excludes vertical excess', () {
    for (final range in oculumOculiathRayRanges) {
      bool inRange(double dx, double dz) => oculumOculiathWithinRange(
        dxMeters: dx,
        dyMeters: 0,
        dzMeters: dz,
        range: range,
      );
      expect(inRange(range.toDouble(), 0), isTrue);
      expect(inRange(0, range.toDouble()), isTrue);
      expect(inRange(range.toDouble(), .001), isFalse);
      expect(inRange(double.infinity, 0), isFalse);
      expect(inRange(double.nan, 0), isFalse);
    }
  });

  test('secondary rays reduce the full primary damage independently', () {
    expect(oculumOculiathRayDamage(113), 113);
    expect(oculumOculiathRayDamage(113, reduction: 10), 101);
    expect(oculumOculiathRayDamage(113, reduction: 6), 106);
    expect(oculumOculiathRayDamage(113, reduction: 3), 109);
    expect(oculumOculiathRayDamage(113, reduction: 100), 0);
  });
}
