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
        expect(
          art.openBuffEffects.isNotEmpty || art.openBuff.trim().isNotEmpty,
          true,
          reason: monster.id,
        );
        expect(art.openSkill, isNotEmpty, reason: monster.id);
        expect(
          art.openSkillCooldown?.amount ?? 0,
          greaterThan(0),
          reason: monster.id,
        );
        final restored = CharacterArt.fromJson(art.toJson());
        expect(
          restored.openSkillCooldown?.amount,
          art.openSkillCooldown?.amount,
          reason: monster.id,
        );
        expect(restored.openBuff, art.openBuff, reason: monster.id);
        final gold = oculumGuardianGoldArt(restored);
        final lunar = oculumLunarGuardianArt(restored);
        if (gold || lunar) {
          // These authored Opens use parsed, editable Buff commands and their
          // own mechanics, rather than the generic monster_open_power effect.
          final commands = oculumParseFormulaCommands(restored.openBuff, const {
            'livello': 8,
            'grado': 1,
          }).where((command) => command.valid);
          expect(
            commands.singleWhere((c) => c.key == 'danni').value,
            gold ? 15 : 20,
            reason: monster.id,
          );
          expect(
            commands.singleWhere((c) => c.key == 'difesa').value,
            gold ? 10 : 15,
            reason: monster.id,
          );
          expect(
            restored.openDescriptionEffects.any(
              (e) =>
                  e.target ==
                  (gold ? 'guardian_gold_open' : 'lunar_guardian_stones'),
            ),
            true,
            reason: monster.id,
          );
          expect(
            restored.openSkillEffects.any(
              (e) =>
                  e.target ==
                  (gold ? 'guardian_gold_wall' : 'lunar_guardian_shadow_crest'),
            ),
            true,
            reason: monster.id,
          );
        } else {
          expect(
            restored.openBuffEffects.any(
              (e) => e.target == 'monster_open_power',
            ),
            true,
            reason: monster.id,
          );
        }
      }
    },
  );
}
