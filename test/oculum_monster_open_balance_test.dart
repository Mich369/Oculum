import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test(
    'monster catalogue Open buffs connect to ultimate and preserve cooldowns',
    () {
      for (final monster in defaultMonsterBookEntries.where(
        (m) => !m.isNpc && !m.id.startsWith('pawn_guardiano'),
      )) {
        final art = oculumMonsterBookArt(monster);
        if (monster.id == 'nuvi' ||
            monster.id == 'thunder_bot' ||
            monster.id.contains('meccanio') ||
            monster.id.contains('larva')) {
          continue;
        }
        expect(art.openName, isNotEmpty, reason: monster.id);
        expect(art.openBuffEffects, isNotEmpty, reason: monster.id);
        expect(art.openSkill, isNotEmpty, reason: monster.id);
        expect(
          art.openSkillCooldown?.amount ?? 0,
          greaterThan(0),
          reason: monster.id,
        );
        final restored = CharacterArt.fromJson(art.toJson());
        expect(
          restored.openBuffEffects.any((e) => e.target == 'monster_open_power'),
          true,
          reason: monster.id,
        );
      }
    },
  );
}
