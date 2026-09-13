import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test('Explosion uses remaining Life plus current Damage', () {
    expect(oculumPinepineExplosionDamage(remainingHp: 30, damage: 12), 42);
    expect(oculumPinepineExplosionDamage(remainingHp: 7, damage: 12), 19);
    expect(oculumPinepineExplosionDamage(remainingHp: 0, damage: 12), 12);
    expect(oculumPinepineExplosionDamage(remainingHp: -5, damage: -2), 0);
  });

  test('Every Pinepine form explains remaining Life plus Damage', () {
    final monster = defaultMonsterBookEntries.firstWhere(
      (m) => m.id == 'pinepine',
    );
    final art = oculumMonsterBookArt(monster);
    final skin = art.skills.single;
    for (final form in [skin.evo1, skin.evo2, skin.evo3]) {
      expect(form, contains('Vita rimanente + Danni'));
    }
    expect(skin.livello, 0);
  });
}
