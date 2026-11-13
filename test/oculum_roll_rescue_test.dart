import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/services/oculum_roll_rescue.dart';

void main() {
  test('ordinary failures never offer Oculum Inspiration', () {
    expect(
      oculumRollRescueOptions(
        failed: true,
        negativeCritical: false,
        base: 1,
        superInspiration: 1,
        oculum: 1,
        fortune: 2,
        fortuneCanHelp: true,
        pactAvailable: true,
      ),
      {
        OculumRollRescue.base,
        OculumRollRescue.superInspiration,
        OculumRollRescue.fortune,
        OculumRollRescue.pact,
      },
    );
  });

  test('a failed negative critical offers only applicable owned resources', () {
    expect(
      oculumRollRescueOptions(
        failed: true,
        negativeCritical: true,
        base: 5,
        superInspiration: 1,
        oculum: 1,
        fortune: 3,
        pactAvailable: true,
        chainedFate: true,
      ),
      {
        OculumRollRescue.superInspiration,
        OculumRollRescue.oculum,
        OculumRollRescue.pact,
      },
    );
    expect(
      oculumRollRescueOptions(failed: true, negativeCritical: true),
      isEmpty,
    );
  });

  test('an ordinary Chained Fate rescue needs two base or one Super', () {
    expect(oculumBaseInspirationCost(chainedFate: false), 1);
    expect(oculumBaseInspirationCost(chainedFate: true), 2);
    expect(
      oculumRollRescueOptions(
        failed: true,
        negativeCritical: false,
        base: 1,
        superInspiration: 1,
        chainedFate: true,
      ),
      {OculumRollRescue.superInspiration},
    );
    expect(
      oculumRollRescueOptions(
        failed: true,
        negativeCritical: false,
        base: 2,
        chainedFate: true,
      ),
      {OculumRollRescue.base},
    );
  });

  test('a spent Inspiration removes every Inspiration from the same roll', () {
    expect(
      oculumRollRescueOptions(
        failed: true,
        negativeCritical: true,
        base: 3,
        superInspiration: 2,
        oculum: 1,
        pactAvailable: true,
        inspirationUsed: true,
      ),
      {OculumRollRescue.pact},
    );
  });

  test('successful rolls do not offer rescue options', () {
    expect(
      oculumRollRescueOptions(
        failed: false,
        negativeCritical: false,
        base: 3,
        superInspiration: 2,
        oculum: 1,
        fortune: 3,
        fortuneCanHelp: true,
        pactAvailable: true,
      ),
      isEmpty,
    );
  });

  test('Oculum splits the possible percentiles evenly between criticals', () {
    final naturals = [
      for (var percentile = 0; percentile < 100; percentile++)
        oculumInspirationCriticalNatural(faces: 16, percentile: percentile),
    ];
    expect(naturals.where((natural) => natural == 16), hasLength(50));
    expect(naturals.where((natural) => natural == 1), hasLength(50));
  });
}
