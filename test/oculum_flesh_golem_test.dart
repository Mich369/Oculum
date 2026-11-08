import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;
import 'oculum_protection_wear_test.dart' show prepareProtectionFixture;

void main() {
  test('Flesh Golem is a hostile creature of Carne Viva', () {
    final golem = monsterBookEntryById('golem_carne')!;
    expect(golem.planeIds, contains('carne_viva'));
    expect(golem.generationSide, 'enemy');
    expect(golem.encounterRules['hostileToMonsters'], isTrue);
    expect(
      golem.skillIds.where((id) => id.startsWith('realm_golem_carne_')),
      unorderedEquals(List.generate(4, (index) => 'realm_golem_carne_$index')),
    );
    expect(
      oculumFleshGolemLifeLossBonus(10, lifeLost: 150, maximumLife: 100),
      25,
    );
  });

  testWidgets('only cumulative actual Life loss raises Damage and Defense', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    prepareProtectionFixture(state, probe);
    final sheet = state.schedePersonaggio[state.schedaCorrente] as Map;
    sheet['monsterBookSourceId'] = 'golem_carne';
    state.resilienzaController.text = '20';
    probe.setResourceCurrent('resilienza', 20);
    state.volontaController.text = '12';
    probe.setResourceCurrent('volonta', 12);
    state.materiaController.text = '12';
    probe.setResourceCurrent('materia', 12);
    probe.invalidateDerivedCaches();
    final startingLife = probe.currentHp();
    final maximumLife = probe.maximumHp();
    final damage = probe.damageTotal();
    final defense = probe.defenseTotal();

    state.scudoController.text = '10';
    await probe.damageResolved(5, bypassDefense: true);
    expect(probe.currentHp(), startingLife);
    expect(probe.damageTotal(), damage);

    state.scudoController.text = '0';
    state.hpTempController.text = '5';
    await probe.damageResolved(5, bypassDefense: true);
    expect(probe.currentHp(), startingLife);
    expect(probe.defenseTotal(), defense);

    await probe.damageResolved(20, bypassDefense: true, bypassShields: true);
    expect(probe.currentHp(), startingLife - 20);
    final runtime = sheet['planarRuntime'] as Map;
    expect((runtime['fleshGolemFight'] as Map)['maximumLife'], maximumLife);
    expect((runtime['fleshGolemFight'] as Map)['lifeLost'], 20);
    expect(probe.damageTotal(), (damage * (1 + 20 / maximumLife)).round());
    expect(probe.defenseTotal(), (defense * (1 + 20 / maximumLife)).round());

    state.currentHpController.text = '$startingLife';
    state.resilienzaController.text = '25';
    probe.setResourceCurrent('resilienza', 25);
    await probe.damageResolved(20, bypassDefense: true, bypassShields: true);
    final saved = probe.snapshot()['planarRuntime'] as Map;
    expect((saved['fleshGolemFight'] as Map)['lifeLost'], 40);
    expect((saved['fleshGolemFight'] as Map)['maximumLife'], maximumLife);

    probe.finishPlanarFight();
    expect(
      (probe.snapshot()['planarRuntime'] as Map)['fleshGolemFight'],
      isNull,
    );
    await closeFixture(tester, probe);
  });
}
