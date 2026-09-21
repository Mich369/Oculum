import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/hero_path/hero_engine.dart';
import 'package:oculum/main.dart'
    show oculusAwardGrowth, oculusNormalizeCharacterData;

void main() {
  test('le cure preservano la Vita oltre il massimo dopo la rinascita', () {
    final run = HeroRun(seed: 1, name: 'Iris');
    run.player.hp = run.player.maxHp + 10;
    final before = run.player.hp;
    run.heal(2);
    expect(run.player.hp, before);
  });

  test('Ispirazione ripristina oggetti, arma e bonus del cibo', () {
    final run = HeroRun(seed: 42, name: 'Iris');
    run.encounter(forced: 'lupo');
    run.player.hp = 1000;
    run.enemies.first.hp = 1000;
    run.inventory['Corna dell’Alce Cieco'] = 1;
    expect(run.useItem('Corna dell’Alce Cieco'), true);
    expect(run.weaponBonus, greaterThan(0));
    expect(run.rewind(), true);
    expect(run.weaponBonus, 0);
    expect(run.inventory['Corna dell’Alce Cieco'], 1);
    run.inventory['Carne'] = 1;
    expect(run.useItem('Carne'), true);
    expect(run.foodBonuses['volonta'], 1);
    expect(run.rewind(), true);
    expect(run.foodBonuses, isEmpty);
    expect(run.inventory['Carne'], 1);
  });

  test('la crescita del boss non si duplica cambiando livello', () {
    final data = <String, dynamic>{'monsterRank': 'boss'};
    oculusAwardGrowth(data, 3);
    expect(data['unspentGrowth'], 21);
    expect(data['unspentDice'], 3);
    oculusAwardGrowth(data, 1);
    oculusAwardGrowth(data, 3);
    expect(data['unspentGrowth'], 21);
    oculusAwardGrowth(data, 6);
    expect(data['unspentGrowth'], 42);
    final legacy = oculusNormalizeCharacterData({'level': 6});
    oculusAwardGrowth(legacy, 6);
    expect(legacy['unspentGrowth'], 0);
    oculusAwardGrowth(legacy, 7);
    expect(legacy['unspentGrowth'], 3);
  });
}
