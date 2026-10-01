import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test('creature forms stay separate from elemental identity', () {
    expect(MonsterBookEntry(id: 'forest_demon', nameIt: 'Forest Demon', nameEn: '', descIt: '', descEn: '', elementId: 'terra', spriteAssetPath: '', isMiniBoss: false, isBoss: false, isNullFateless: false).formTags.first, 'Rettile gigante');
    expect(MonsterBookEntry(id: 'demone_glaciale', nameIt: 'Demone Glaciale Minore', nameEn: '', descIt: '', descEn: '', elementId: 'gelo', spriteAssetPath: '', isMiniBoss: false, isBoss: false, isNullFateless: false).formTags.first, 'Demone');
    expect(MonsterBookEntry(id: 'angelo', nameIt: 'Angelo Protettore', nameEn: '', descIt: '', descEn: '', elementId: 'solare', spriteAssetPath: '', isMiniBoss: false, isBoss: false, isNullFateless: false).formTags.first, 'Angelo');
  });

  test('humanoid roles distribute the same budget and grant nine-point packages', () {
    final tank = oculumHumanoidRoleStats('Tank', 100);
    expect(tank.values.reduce((a, b) => a + b), 100);
    expect(oculumRoleSubtraitBonuses('Assassino', 0).values.reduce((a, b) => a + b), 9);
    expect(oculumRoleSubtraitBonuses('Assassino', 3).values.reduce((a, b) => a + b), 18);
  });
}
