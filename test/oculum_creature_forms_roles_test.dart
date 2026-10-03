import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test('creature forms stay separate from elemental identity', () {
    expect(
      MonsterBookEntry(
        id: 'forest_demon',
        nameIt: 'Forest Demon',
        nameEn: '',
        descIt: '',
        descEn: '',
        elementId: 'terra',
        spriteAssetPath: '',
        isMiniBoss: false,
        isBoss: false,
        isNullFateless: false,
      ).formTags.first,
      'Rettile gigante',
    );
    expect(
      MonsterBookEntry(
        id: 'demone_glaciale',
        nameIt: 'Demone Glaciale Minore',
        nameEn: '',
        descIt: '',
        descEn: '',
        elementId: 'gelo',
        spriteAssetPath: '',
        isMiniBoss: false,
        isBoss: false,
        isNullFateless: false,
      ).formTags.first,
      'Demone',
    );
    expect(
      MonsterBookEntry(
        id: 'angelo',
        nameIt: 'Angelo Protettore',
        nameEn: '',
        descIt: '',
        descEn: '',
        elementId: 'solare',
        spriteAssetPath: '',
        isMiniBoss: false,
        isBoss: false,
        isNullFateless: false,
      ).formTags.first,
      'Angelo',
    );
  });

  test(
    'humanoid roles distribute the same budget and grant nine-point packages',
    () {
      final tank = oculumHumanoidRoleStats('Tank', 100);
      expect(tank.values.reduce((a, b) => a + b), 100);
      expect(
        oculumRoleSubtraitBonuses(
          'Assassino',
          0,
        ).values.reduce((a, b) => a + b),
        9,
      );
      expect(
        oculumRoleSubtraitBonuses(
          'Assassino',
          3,
        ).values.reduce((a, b) => a + b),
        18,
      );
    },
  );
  test('NPC and humanoid enemy creation retain explicit choices', () {
    const choice = OculumHumanoidChoice(
      'Support',
      2,
      1,
      name: 'Elyra',
      level: 7,
      artMode: 'illness',
    );
    expect(choice.name, 'Elyra');
    expect(choice.level, 7);
    expect(oculumIsHumanoid('NPC', '', null), isTrue);
    expect(oculumIsHumanoid('Nemico', 'soldato', null), isTrue);
    expect(oculumIsHumanoid('Nemico', 'slime non umanoide', null), isFalse);
  });
  test('balanced Arts retain fixed costs, tiers and authored glacial Open', () {
    for (final mode in ['oculum', 'martial', 'emblem', 'defiled', 'illness']) {
      final original = oculumBalancedHumanoidArt(
        mode: mode,
        role: 'Controllore',
        element: 'gelo',
      );
      final art = CharacterArt.fromJson(original.toJson());
      expect(art.skills.length, 3);
      for (final skill in art.skills) {
        expect(skill.evo1, contains('Richiede livello 0'));
        expect(skill.evo2, contains('Richiede livello 3'));
        expect(skill.evo3, contains('Richiede livello 6'));
        if (mode == 'defiled')
          expect(skill.evo5, contains('Richiede livello 12'));
      }
      expect(art.openDescription, contains('1d100'));
      expect(art.openSkill, contains('1d30'));
      expect(art.openSkill, contains('su critico'));
      expect(art.openBuff, '@Stats+5');
      expect(art.openSkillCooldown!.amount, 2);
      expect(art.openDescriptionCooldown!.unit, 'turni');
      expect(
        art.skills.first.risorsaCostoPerLivello(1),
        mode == 'illness'
            ? 'follia'
            : mode == 'defiled'
            ? 'obser'
            : mode == 'oculum'
            ? 'oculum'
            : 'nessuna',
      );
      expect(art.skills.first.oculumMinimoPerLivello(3), 9);
    }
    expect(
      oculumHumanoidFateTitle('Controllore', 0),
      isNot(oculumHumanoidFateTitle('Controllore', 1)),
    );
  });
}
