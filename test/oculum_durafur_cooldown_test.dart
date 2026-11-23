import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test('Durafur has one three-form skill and a partial opening cooldown', () {
    final monster = monsterBookEntryById('durafur')!;
    final skill = oculumMonsterBookSkills(monster).single;
    expect(monster.skillIds, ['durafur_fur_fury']);
    expect(
      skill.forme.map((form) => form.effettiStrutturati.single.valueExpression),
      ['30', '40', '60'],
    );
    for (final form in skill.forme) {
      expect(form.effettiStrutturati.single.duration, '3');
      final cooldown = form.cooldownStrutturato!;
      expect(cooldown.enterCombat('fight-1'), true);
      expect(cooldown.remaining, 2);
      expect(cooldown.tick('turni'), true);
      expect(cooldown.tick('turni'), true);
      expect(cooldown.activate(), true);
      expect(cooldown.remaining, 5);
      final restored = OculumAbilityCooldown.fromJson(cooldown.toJson());
      expect(restored.enterCombat('fight-1'), false);
      expect(restored.remaining, 5);
      expect(restored.enterCombat('fight-2'), true);
      expect(restored.remaining, 2);
    }
  });

  test('old unavailable cooldowns still begin with the full delay', () {
    final cooldown = OculumAbilityCooldown.fromJson({
      'amount': 4,
      'startsReady': false,
    });
    expect(cooldown.enterCombat('fight-1'), true);
    expect(cooldown.remaining, 4);
    expect(cooldown.toJson(), isNot(contains('initialRemaining')));
  });
}
