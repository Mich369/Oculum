import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/oculum_elemental_sphere_rules.dart';

OculumElementalSphereAcidPlan? plan({
  bool doubleCritical = true,
  int hpLost = 1,
  int casterGrade = 0,
  int targetGrade = 0,
  int? durationTurns,
}) => oculumPlanElementalSphereAcid(
  doubleCritical: doubleCritical,
  hpLost: hpLost,
  casterGrade: casterGrade,
  targetGrade: targetGrade,
  durationTurns: durationTurns ?? oculumElementalSphereAcidDefaultTurns,
);

OculumElementalSphereLightningPlan? lightning({
  bool doubleCritical = true,
  int hpLost = 1,
  int resolvedDamage = 101,
  String primary = 'primary',
  List<String> selected = const [],
  bool hasOthers = true,
  int secondaryPercentPerTarget = 75,
  int soloBonusPercent = 50,
}) => oculumPlanElementalSphereLightning(
  doubleCritical: doubleCritical,
  hpLost: hpLost,
  resolvedDamage: resolvedDamage,
  primaryTargetId: primary,
  additionalTargetIds: selected,
  hasAvailableAdditionalTargets: hasOthers,
  secondaryPercentPerTarget: secondaryPercentPerTarget,
  soloBonusPercent: soloBonusPercent,
);

void main() {
  test('sphere critical tracks life lost at impact before immediate healing', () {
    bool triggers(int? impact, int net) => oculumElementalSphereCriticalTriggers(
      doubleCritical: true,
      hpLost: oculumElementalSphereLifeLost(impactLifeLost: impact, netLifeLost: net),
    );
    expect(triggers(1, 0), isTrue);
    expect(triggers(0, 0), isFalse);
    expect(triggers(0, 1), isFalse);
    expect(triggers(null, 1), isTrue);
  });
  test('Acid requires a double critical that removes at least one Life', () {
    expect(plan(doubleCritical: false, hpLost: 20), isNull);
    expect(plan(hpLost: 0), isNull);
    expect(plan(hpLost: -1), isNull);
    expect(plan(), isNotNull);
  });

  test('Acid uses the Grade difference with a minimum multiplier of one', () {
    expect(plan()!.gradeMultiplier, 1);
    expect(plan(casterGrade: 5, targetGrade: 5)!.gradeMultiplier, 1);
    expect(plan(casterGrade: 5, targetGrade: 2)!.gradeMultiplier, 1);
    expect(plan(casterGrade: 2, targetGrade: 3)!.gradeMultiplier, 1);
    expect(plan(casterGrade: 2, targetGrade: 5)!.gradeMultiplier, 3);
  });

  test('each d30 result splits shield erosion from ordinary damage', () {
    final acid = plan(casterGrade: 2, targetGrade: 5)!;
    expect(acid.tick(30), (shieldPoints: 45, normalDamage: 45));
    expect(acid.tick(5), (shieldPoints: 7, normalDamage: 8));
    expect(plan()!.tick(1), (shieldPoints: 0, normalDamage: 1));
    expect(() => acid.tick(0), throwsRangeError);
    expect(() => acid.tick(31), throwsRangeError);
    expect(oculumElementalSphereAcidTick(5, gradeMultiplier: 3), acid.tick(5));
  });

  test('three personal turns by default with an editable duration', () {
    expect(plan()!.durationTurns, 3);
    expect(plan(durationTurns: 5)!.durationTurns, 5);
    expect(plan(durationTurns: 0)!.durationTurns, 1);
  });

  test('only an actual gain of at least one Life ends Acid', () {
    expect(oculumElementalSphereAcidEndsOnHealing(0), isFalse);
    expect(oculumElementalSphereAcidEndsOnHealing(-1), isFalse);
    expect(oculumElementalSphereAcidEndsOnHealing(1), isTrue);
    expect(oculumElementalSphereAcidEndsOnHealing(50), isTrue);
  });

  test('Lightning requires a double critical and actual Life loss', () {
    expect(lightning(doubleCritical: false), isNull);
    expect(lightning(hpLost: 0), isNull);
    expect(lightning(resolvedDamage: 0), isNull);
    expect(lightning(), isNotNull);
  });

  test('Lightning adds 50% to the primary only when it is alone', () {
    final solo = lightning(hasOthers: false)!;
    expect(solo.primaryBonusDamage, 50);
    expect(solo.secondaryDamage, isEmpty);
    final skipped = lightning()!;
    expect(skipped.primaryBonusDamage, 0);
    expect(skipped.secondaryDamage, isEmpty);
    expect(
      lightning(
        resolvedDamage: 101,
        hasOthers: false,
        soloBonusPercent: 30,
      )!.primaryBonusDamage,
      30,
    );
  });

  test(
    'Lightning preserves the secondary pool with one, two or three targets',
    () {
      expect(lightning(selected: ['a'])!.secondaryDamage, {'a': 227});
      expect(lightning(selected: ['a', 'b'])!.secondaryDamage, {
        'a': 114,
        'b': 113,
      });
      final three = lightning(selected: ['a', 'b', 'c'])!;
      expect(three.primaryBonusDamage, 0);
      expect(three.secondaryDamage, {'a': 76, 'b': 76, 'c': 75});
      expect(
        lightning(
          resolvedDamage: 100,
          selected: ['a', 'b', 'c'],
        )!.secondaryDamage,
        {'a': 75, 'b': 75, 'c': 75},
      );
      expect(
        lightning(
          resolvedDamage: 100,
          selected: ['a', 'b'],
          secondaryPercentPerTarget: 50,
        )!.secondaryDamage,
        {'a': 75, 'b': 75},
      );
    },
  );

  test('Lightning rejects malformed or repeated additional target IDs', () {
    expect(lightning(selected: ['a', 'b', 'c', 'd']), isNull);
    expect(lightning(selected: ['a', ' a ']), isNull);
    expect(lightning(selected: ['a', 'primary']), isNull);
    expect(lightning(selected: [' ']), isNull);
    expect(lightning(selected: ['a'], hasOthers: false), isNull);
    expect(lightning(primary: ''), isNull);
  });
}
