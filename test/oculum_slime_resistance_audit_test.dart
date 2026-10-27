import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

MonsterBookEntry creature(String name, String body, String element,
    {Map<String, String> overrides = const {}}) => MonsterBookEntry(
  id: 'test_${name.replaceAll(' ', '_')}', nameIt: name, nameEn: '',
  descIt: body, descEn: '', elementId: element, spriteAssetPath: '',
  isMiniBoss: false, isBoss: false, isNullFateless: false,
  damageResistancePresets: overrides,
);

void main() {
  test('physical protection follows anatomy, not the element of an attack', () {
    final swordsman = creature('Spadaccino', 'Una persona con una spada.', 'taglio');
    expect(swordsman.incomingDamageResistancePresets, isNot(contains('taglio')));
    final moss = creature('Fungo', 'Un fungo di legno vivo.', 'natura');
    expect(moss.incomingDamageResistancePresets['fuoco'], 'Fragilità');
    final machine = creature('Robot', 'Un robot metallico.', 'fulmine');
    expect(machine.incomingDamageResistancePresets['taglio'], 'Resistenza');
    final enchantedWood = creature('Albero incantato', 'Un albero di legno.', 'natura',
      overrides: {'fuoco': 'Immunità', 'natura': 'Normale'});
    final saved = MonsterBookEntry.fromJson(enchantedWood.toJson());
    expect(saved.incomingDamageResistancePresets['fuoco'], 'Immunità');
    expect(saved.incomingDamageResistancePresets['natura'], 'Normale');
    expect(saved.damageResistancePresets, enchantedWood.damageResistancePresets);
    // Spell descriptions must not turn an organic caster into a metal construct.
    final caster = creature('Evocatore', 'Un umano. Skill per il giocatore: evoca un golem di metallo.', 'oculum');
    expect(caster.incomingDamageResistancePresets, isNot(contains('taglio')));
  });

  testWidgets('half slime racial bonuses and weaknesses actually affect a sheet', (tester) async {
    final (state, p) = await fixtures.mountFight(tester);
    final race = oculumStarterRaces.singleWhere((r) => r.id == 'mezzo_slime');
    expect(race.materia, 2);
    final beforeReflex = p.subtraitValue('riflessi');
    final beforeControl = p.subtraitValue('controllo_corporeo');
    state.trattiRazziali.add(OculumTitle.fromJson({'nome': race.nome,
      'buff': race.descrizione, 'equipaggiato': true,
      'chiaveSistema': 'tutorial_race_${race.id}'}));
    p.invalidateDerivedCaches();
    expect(p.subtraitValue('riflessi'), beforeReflex + 2);
    expect(p.subtraitValue('controllo_corporeo'), beforeControl + 2);
    expect(p.incomingParserDamage(100, 'fuoco'), 125);
    expect(p.incomingParserDamage(100, 'esplosivo'), 125);
    expect(p.incomingParserDamage(100, 'gelo'), 100);
    final saved = p.snapshot();
    p.load(saved);
    expect(p.incomingParserDamage(100, 'fuoco'), 125);
    expect(p.subtraitValue('controllo_corporeo'), beforeControl + 2);
    expect(p.resistanceCommandMultiplier('debolezza'), 1.25);
    expect(p.resistanceCommandMultiplier('Bassa Fragilità'), 1.1);
    p.setIncomingDamagePreset('fuoco', 'debolezza');
    expect(p.incomingDamagePreset('fuoco'), 'Fragilità');
    await closeFixture(tester, p);
  });

  test('catalogue resistance audit records every creature without altering custom definitions', () {
    final rows = [for (final m in defaultMonsterBookEntries) {
      'id': m.id, 'name': m.nameIt, 'element': m.elementId,
      'authored': m.damageResistancePresets,
      'effective': m.incomingDamageResistancePresets,
    }];
    expect(rows.length, greaterThan(1100));
    for (final m in defaultMonsterBookEntries) {
      for (final e in m.damageResistancePresets.entries) {
        expect(m.incomingDamageResistancePresets[e.key], e.value, reason: m.id);
      }
    }
    File('build/oct27-creature-resistance-audit.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({'creatures': rows.length, 'entries': rows}));
  });
}
