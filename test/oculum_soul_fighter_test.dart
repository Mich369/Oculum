import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_monster_theme.dart';

void main() {
  test('the spiritual cut uses only current Health and floors the amount', () {
    expect(oculumSoulFighterDamage(currentHp: 87, percent: 20), 17);
    expect(oculumSoulFighterDamage(currentHp: 4, percent: 20), 0);
    expect(oculumSoulFighterDamage(currentHp: 0, percent: 20), 0);
  });

  test('the Soul Fighter keeps both Arts and the approved theme', () {
    final monster = monsterBookEntryById(oculumSoulFighterId)!;
    final first = oculumMonsterBookImportArt(monster)!;
    final second = oculumMonsterBookAdditionalArts(monster).single;
    final effect = first.skills.single.effettiEvoluzione(1).single;
    expect(effect.elementType, 'spirituale');
    expect(effect.bypassShields, false);
    expect(effect.bypassResistance, false);
    expect(second.skills, hasLength(2));
    expect(
      OculumMonsterTheme.desktopIllustrationForId(monster.id),
      endsWith('theme_soul_fighter_canon_20261114_v2.webp'),
    );
  });

  test(
    'the elite illustration is distinct and the base arts are inherited',
    () {
      final base = monsterBookEntryById(oculumSoulFighterId)!;
      final elite = monsterBookEntryById(oculumSoulFighterEliteId)!;
      expect(elite.skillIds, base.skillIds);
      expect(oculumMonsterBookImportArt(elite)!.skills, hasLength(1));
      final additional = oculumMonsterBookAdditionalArts(elite);
      expect(additional.map((art) => art.nome), [
        oculumMonsterBookAdditionalArts(base).single.nome,
        'Anymareap',
      ]);
      expect(additional.first.skills, hasLength(2));
      final anymareap = additional.last.skills.single;
      final effect = anymareap.effettiEvoluzione(1).single;
      expect(effect.id, oculumAnymareapEffect);
      expect(effect.elementType, 'spirituale');
      expect(effect.minimumTargets, 1);
      expect(effect.maximumTargets, 3);
      expect(anymareap.oculumMinimoPerLivello(1), 4);
      expect(anymareap.oculumMassimoPerLivello(1), 4);
      expect(anymareap.cooldownPerLivello.first.amount, 4);
      expect(elite.spriteAssetPath, isEmpty);
      expect(
        OculumMonsterTheme.desktopIllustrationForId(elite.id),
        endsWith('theme_soul_fighter_variante_elite_canon_20261114.webp'),
      );
    },
  );

  test(
    'the Master can pick both skills from Veglia with their authored data',
    () {
      final defaults = oculumQuickNpcSkillChoices('spirituale');
      final choices = oculumQuickNpcSkillChoices(
        'spirituale',
        includeAdditionalMonsterArts: true,
      );
      for (final name in ['Mano della Veglia', 'Marchio dei Senza Nome']) {
        expect(defaults.where((entry) => entry.art.nome == name), isEmpty);
        final entry = oculumRankMasterSkillChoices(choices, name).first;
        expect(entry.art.nome, name);
        expect(entry.art.oculumMinimoPerLivello(1), 2);
        expect(entry.art.cooldownPerLivello.first.amount, 3);
        final assigned = oculumEquipmentAbilityFromArt(entry.art);
        final restored = CharacterSkill.fromJson(assigned.toJson());
        expect(
          restored.forme.first.effettiStrutturati.single.toJson(),
          entry.art.effettiEvoluzione(1).single.toJson(),
        );
      }
      expect(oculumQuickNpcSkillChoices('spirituale'), same(defaults));
    },
  );

  test('Anymareap is searchable by its Italian and English aliases', () {
    final choices = oculumQuickNpcSkillChoices(
      'spirituale',
      includeAdditionalMonsterArts: true,
    );
    for (final query in ['Anymareap', 'Falce dell’Anima', 'Soul Reap']) {
      final result = oculumRankMasterSkillChoices(choices, query).first;
      expect(result.art.nome, 'Anymareap');
      expect(result.id, startsWith('$oculumSoulFighterEliteId:'));
    }
  });
}
