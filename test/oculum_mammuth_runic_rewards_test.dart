import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('only the confirmed final killer of the exact Mammuth is eligible', () {
    const participants = ['Helper', 'Killer'];
    const enemy = {
      'monsterBookId': 'mammut_corazzato_variante_corazzata',
      'mammuthRunicDeathConfirmed': true,
      'killerTag': 'killer',
    };
    expect(oculumMammuthRunicKillerTag(enemy, participants), 'Killer');
    for (final ineligible in [
      {'monsterBookId': 'mammut_corazzato'},
      {'mammuthRunicDeathConfirmed': false},
      {'isSummon': true},
      {'killerTag': 'missing'},
      {'killerTag': ''},
    ]) {
      expect(
        oculumMammuthRunicKillerTag({...enemy, ...ineligible}, participants),
        isNull,
      );
    }
  });

  test('the next reward unlocks after six campaign days', () {
    const earned = 32;
    const sixDays = 6 * 9 * 60 * 60;
    bool ready(int now, int? previous) => oculumMammuthRunicRewardReady(
      campaignSeconds: now,
      previousRewardSeconds: previous,
    );

    expect(ready(0, null), isTrue);
    expect(ready(0, 0), isFalse);
    expect(ready(earned - 1, earned), isFalse);
    expect(ready(earned + sixDays - 1, earned), isFalse);
    expect(ready(earned + sixDays, earned), isTrue);
  });

  test('a depleted reserve still owns Oculum and can recover a point', () {
    final gain = oculumMammuthRunicStatReward(
      normalCurrentOculum: 0,
      maximumOculum: 7,
    );

    expect(gain, OculumMammuthRunicStatReward.currentOculum);
    expect(gain.amount, 1);
  });

  test('full Oculum earns a maximum point and zero capacity earns Materia', () {
    final full = oculumMammuthRunicStatReward(
      normalCurrentOculum: 7,
      maximumOculum: 7,
    );
    final noOculum = oculumMammuthRunicStatReward(
      normalCurrentOculum: 0,
      maximumOculum: 0,
    );

    expect(full, OculumMammuthRunicStatReward.maximumOculum);
    expect(full.amount, 1);
    expect(noOculum, OculumMammuthRunicStatReward.materia);
    expect(noOculum.amount, 2);
  });
}
