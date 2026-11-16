import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/oculum_umbravex_rules.dart';

void main() {
  test('phase triggers once on a living crossing at or below half Life', () {
    ({int hpRestored, int temporaryHp, int oculumRestored})? crossing(
      int before,
      int after, {
      bool triggered = false,
    }) => oculumUmbravexPhaseGain(
      hpBefore: before,
      hpAfter: after,
      maxHp: 100,
      currentOculum: 10,
      maxOculum: 20,
      alreadyTriggered: triggered,
    );

    expect(crossing(55, 51), isNull);
    expect(crossing(50, 40), isNull);
    expect(crossing(55, 0), isNull);
    expect(crossing(55, 49, triggered: true), isNull);
    expect(crossing(55, 50), (
      hpRestored: 25,
      temporaryHp: 0,
      oculumRestored: 6,
    ));
  });

  test('Oculum overflow fills Life and becomes temporary Life at full', () {
    final gain = oculumUmbravexPhaseGain(
      hpBefore: 51,
      hpAfter: 49,
      maxHp: 100,
      currentOculum: 80,
      maxOculum: 90,
      alreadyTriggered: false,
    );

    expect(gain, (hpRestored: 51, temporaryHp: 15, oculumRestored: 10));
  });

  test('zero current Oculum gives no recovery or overflow', () {
    final gain = oculumUmbravexPhaseGain(
      hpBefore: 5,
      hpAfter: 4,
      maxHp: 9,
      currentOculum: 0,
      maxOculum: 80,
      alreadyTriggered: false,
    );

    expect(gain, (hpRestored: 2, temporaryHp: 0, oculumRestored: 0));
  });

  test('only immaterial targets receive the Shadow Dart damage bonus', () {
    expect(oculumUmbravexShadowDartDamage(21, immaterial: false), 21);
    expect(oculumUmbravexShadowDartDamage(21, immaterial: true), 31);
  });
}
