import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  test(
    'generic parser preserves full-target damage and sacrifice for any entity',
    () {
      final parsed = oculumParseAbilityMechanics(
        'Danni pari alla Vita massima a tutti gli avversari, sacrificio della fonte.',
      );
      final damage = parsed.effects.singleWhere(
        (effect) => effect.type == 'danno',
      );
      expect(damage.valueExpression, 'hp_max');
      expect(damage.damagePerTarget, isTrue);
      expect(damage.allOpponents, isTrue);
      expect(damage.killSource, isTrue);
      final restored = OculumStructuredEffect.fromJson(damage.toJson());
      expect(restored.killSource, isTrue);
      expect(restored.damagePerTarget, isTrue);
      expect(restored.allOpponents, isTrue);
    },
  );
  testWidgets(
    'Transparency and Invisibility add level-scaled Veil without changing saved base',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      state.datiCaricati = false;
      state.livelloController.text = '4';
      state.hiddenEyeStats.add(
        HiddenEyeStat(id: 'velo', nome: 'Velo', descrizione: 'Test Velo'),
      );
      final before = probe.subtraitValue('velo');
      probe.addCondition('trasparenza');
      expect(probe.subtraitValue('velo'), before + 10);
      state.activeConditions.clear();
      probe.addCondition('invisibile');
      expect(probe.subtraitValue('velo'), before + 22);
      probe.cancelPendingSave();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );
  test(
    'Kamikaze has only its explosion, initial two-turn cooldown and editable HP formula',
    () {
      final monster = monsterById('goblin_kamikaze')!;
      expect(monster.skillIds, ['goblin_kamikaze_explosion']);
      final skill = oculumMonsterBookSkills(monster).single;
      for (final form in skill.forme) {
        expect(form.cooldownStrutturato!.remaining, 2);
        expect(form.cooldownStrutturato!.tick('turni'), isTrue);
        expect(form.cooldownStrutturato!.ready, isFalse);
        form.cooldownStrutturato!.tick('turni');
        expect(form.cooldownStrutturato!.ready, isTrue);
        final effect = form.effettiStrutturati.single;
        expect(effect.valueExpression, 'hp');
        expect(effect.shieldDamageBonusPercent, 50);
        expect(effect.maximumTargets, 100);
        expect(
          OculumStructuredEffect.fromJson(effect.toJson()).valueExpression,
          'hp',
        );
      }
    },
  );
  test(
    'Runic Golem retains base stats and free scaling passives without artwork',
    () {
      final monster = monsterById('golem_runico')!;
      expect(monster.spriteAssetPath, isEmpty);
      expect(monster.stats['resilienza'], 10);
      expect(monster.stats['volonta'], 3);
      expect(monster.stats['materia'], 6);
      expect(monster.stats['oculum'], 0);
      final skills = oculumMonsterBookSkills(monster);
      expect(skills, hasLength(3));
      expect(skills.every((s) => s.passiva), isTrue);
      final art = oculumMonsterBookArt(monster);
      expect(
        art.openSkillEffects.single.valueExpression,
        '(hp_current)+monster_open_bonus',
      );
    },
  );
  testWidgets(
    'acid corrosion is elemental and ticks HP without using shields',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      state.datiCaricati = false;
      state.currentHpController.text = '100';
      final before = probe.currentHp();
      probe.applyEffects([
        OculumStructuredEffect(
          type: 'stato',
          appliedState: 'corrosione_acida',
          valueExpression: '6',
          duration: '3',
        ),
      ]);
      final condition = probe.conditions.singleWhere(
        (c) => c.conditionType == 'corrosione_acida',
      );
      expect(condition.category, OculumConditionCategory.elemental);
      expect(probe.currentHp(), before);
      probe.tickConditions(OculumConditionTickTrigger.endTurn);
      await tester.pump();
      expect(probe.currentHp(), before - 6);
      expect(condition.duration, 2);
      probe.cancelPendingSave();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );
}
