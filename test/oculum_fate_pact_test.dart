import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/services/oculum_fate_pact.dart';

void main() {
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
