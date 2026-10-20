import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test(
    'aberration tiers keep identity, rank, radiant targets and editable forms',
    () {
      final entries = defaultMonsterBookEntries
          .where(
            (m) =>
                m.id.startsWith('aberrazione_oro_marmo_') &&
                !m.id.contains('_variante_'),
          )
          .toList();
      expect(entries, hasLength(8));
      for (final monster in entries) {
        final lesser = monster.formTags.contains('Minore');
        final intermediate = monster.formTags.contains('Intermedia');
        final superior = monster.formTags.contains('Superiore');
        expect(monster.isMiniBoss, intermediate);
        expect(monster.isBoss, !lesser && !intermediate);
        expect(monster.stats['combatPhases'], superior ? 3 : 2);
        expect(
          monster.elementId,
          monster.formTags.contains('Solare') ? 'solare' : 'luce',
        );
        final rays = oculumEnemyAbilityVariants(
          monster,
          seed: 81,
        ).singleWhere((s) => s.nome.startsWith('Raggi del'));
        final restored = CharacterSkill.fromJson(rays.toJson());
        expect(restored.forme, hasLength(3));
        for (final form in restored.forme) {
          expect(
            form.effettiStrutturati.single.minimumTargets,
            lesser
                ? 2
                : intermediate
                ? 3
                : 6,
          );
          expect(form.effettiStrutturati.single.recipient, 'nemico');
        }
      }
    },
  );
  test(
    'piercing and shield-break variants are targeted, bounded and have cooldown',
    () {
      final monster = defaultMonsterBookEntries.firstWhere(
        (m) => m.id == 'goblin_base',
      );
      var foundPiercing = false, foundShield = false;
      for (var seed = 0; seed < 150; seed++) {
        for (final skill in oculumEnemyAbilityVariants(monster, seed: seed)) {
          for (final form in skill.forme) {
            for (final effect in form.effettiStrutturati) {
              if (!effect.bypassDefense &&
                  !effect.bypassShields &&
                  effect.shieldDamageBonusPercent == 0) {
                continue;
              }
              expect(effect.recipient, 'nemico');
              expect(form.cooldownStrutturato!.amount, inInclusiveRange(2, 5));
              if (effect.bypassDefense) {
                foundPiercing = true;
                if (form.cooldownStrutturato!.amount == 2) {
                  expect(form.cooldownStrutturato!.ready, isFalse);
                }
              }
              foundShield |= effect.shieldDamageBonusPercent > 0;
              final restored = OculumStructuredEffect.fromJson(effect.toJson());
              expect(restored.bypassDefense, effect.bypassDefense);
              expect(
                restored.shieldDamageBonusPercent,
                effect.shieldDamageBonusPercent,
              );
            }
          }
        }
      }
      expect(foundPiercing && foundShield, isTrue);
    },
  );
  test(
    'text penetration reaches the target effect and preserves shield percentage',
    () {
      final parsed = oculumParseAbilityMechanics(
        '+4 danni oltre Difesa, oltre Scudi e +25% danni agli Scudi',
      );
      final damage = parsed.effects.firstWhere((e) => e.type == 'danno');
      expect(damage.bypassDefense && damage.bypassShields, isTrue);
      expect(damage.shieldDamageBonusPercent, 25);
      expect(damage.recipient, 'nemico');
      expect(damage.mode, 'prossima_azione');
      expect(
        parsed.effects.where((e) => e.type == 'danno_percentuale'),
        isEmpty,
      );
      // Stable data remain fully editable rather than a special monster-only path.
      damage.valueExpression = '${max(1, 2)}';
      expect(
        OculumStructuredEffect.fromJson(damage.toJson()).valueExpression,
        '2',
      );
    },
  );
}
