import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('Outcome logs show final totals without formula or DT', () {
    expect(
      oculumResolvedRollLog(label: 'Attacco', total: 27, opposingTotal: 15),
      'Attacco · Riuscito: 27 contro 15.',
    );
    expect(
      oculumResolvedRollLog(label: 'Difesa', total: 15, opposingTotal: 27),
      'Difesa · Fallito: 15 contro 27.',
    );
    expect(
      oculumResolvedRollLog(label: 'Tiro', total: 27),
      'Tiro · Riuscito: 27.',
    );
  });
  test(
    'Initial cooldown preparation persists and is consumed by one encounter',
    () {
      final cooldown = OculumAbilityCooldown(amount: 2, startsReady: false);
      expect(cooldown.ready, isFalse);
      expect(
        cooldown.prepareOutsideCombat(
          now: DateTime.now().subtract(const Duration(seconds: 13)),
        ),
        isTrue,
      );
      expect(cooldown.ready, isTrue);
      final saved = OculumAbilityCooldown.fromJson(cooldown.toJson());
      expect(saved.ready, isTrue);
      saved.enterCombat('fight:1');
      expect(saved.ready, isTrue);
      saved.activate();
      expect(saved.remaining, 2);
      saved.enterCombat('fight:1');
      expect(saved.remaining, 2);
      saved.tick('turni');
      expect(saved.remaining, 1);
      saved.tick('turni');
      expect(saved.ready, isTrue);
      saved.enterCombat('fight:2');
      expect(saved.remaining, 2);
    },
  );

  test('Preparation counts seconds and cannot restart on repeated clicks', () {
    final now = DateTime.now();
    final cooldown = OculumAbilityCooldown(amount: 2, startsReady: false);
    cooldown.prepareOutsideCombat(now: now);
    expect(
      cooldown.secondsRemaining(now: now.add(const Duration(seconds: 5))),
      7,
    );
    expect(
      cooldown.prepareOutsideCombat(now: now.add(const Duration(seconds: 5))),
      isFalse,
    );
    expect(
      cooldown.secondsRemaining(now: now.add(const Duration(seconds: 12))),
      0,
    );
    expect(OculumAbilityCooldown(amount: 2).prepareOutsideCombat(), isFalse);
    expect(
      OculumAbilityCooldown(
        amount: 2,
        unit: 'riposi_lunghi',
        startsReady: false,
      ).prepareOutsideCombat(),
      isFalse,
    );
  });

  test(
    'Confirmed Boss XP and fragility arithmetic preserve difficulty modifiers',
    () {
      expect(
        oculumEnemyExpMultiplier(source: 'boss', difficulty: 'normale'),
        2,
      );
      expect(
        oculumEnemyExpMultiplier(source: 'boss', difficulty: 'facile'),
        2.1,
      );
      expect(
        oculumEnemyExpMultiplier(source: 'boss', difficulty: 'difficile'),
        1.9,
      );
      expect(oculumEnemyExpMultiplier(source: 'boss', difficulty: 'oculum'), 2);
      expect(
        oculumEnemyExpMultiplier(source: 'miniboss', difficulty: 'normale'),
        1.3,
      );
    },
  );
}
