import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_fate_pact.dart';

void main() {
  test('Chaos uses the exact four inspiration chances and game intervals', () {
    final counts = <String?, int>{};
    for (var percentile = 0; percentile < 100; percentile++) {
      counts.update(
        oculumChaosInspirationType(percentile),
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    expect(counts, {null: 20, 'base': 50, 'super': 20, 'oculum': 10});
    expect(oculumChaosInspirationIntervals(800, 900), 0);
    expect(oculumChaosInspirationIntervals(32_499, 100), 0);
    expect(oculumChaosInspirationIntervals(32_500, 100), 1);
    expect(oculumChaosInspirationIntervals(65_500, 100), 2);
  });

  test('pact gives exactly 20 critical choices and 80 super inspirations', () {
    var choices = 0;
    var supers = 0;
    for (var roll = 0; roll < 100; roll++) {
      final result = oculumFatePactOutcome(
        negativeCritical: true,
        percentile: roll,
      );
      if (result == OculumFatePactOutcome.oculumChoice) choices++;
      if (result == OculumFatePactOutcome.superInspiration) supers++;
      expect(
        oculumFatePactOutcome(negativeCritical: false, percentile: roll),
        OculumFatePactOutcome.base,
      );
    }
    expect(choices, 20);
    expect(supers, 80);
  });
}
