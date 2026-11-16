import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test('new monster relics retain their mechanics and distinctive visuals', () {
    const designs = {
      'goblin_king': ('Regiscut', 'Vespermail', 'Crownward', 'corona'),
      'soul_fighter': ('Animablade', 'Velumshade', 'Ossawatch', 'giada'),
      'oculiath': ('Iriscross', 'Membraneward', 'Oculusguard', 'iride'),
      'oculiath_maggiore': (
        'Pentaray',
        'Basaltshroud',
        'Carapaxguard',
        'quattro',
      ),
      'solgaze': ('Solbrand', 'Solvelum', 'Solscutum', 'otto raggi'),
      'sanguifang': ('Sanguident', 'Olivafang', 'Vesperiris', 'zanna'),
    };
    for (final (id, design) in designs.entries.map((e) => (e.key, e.value))) {
      final entry = monsterById(id)!;
      final relics = oculumMonsterEquipmentCatalogue(
        source: entry,
        level: 4,
        grade: 2,
      );
      expect(
        relics.map((item) => item.monsterLoot['id']).toSet(),
        hasLength(relics.length),
      );
      for (final (family, name) in [
        ('weapon', design.$1),
        ('armor', design.$2),
        ('shield', design.$3),
      ]) {
        final original = relics.singleWhere(
          (item) => item.monsterLoot['id'] == 'monster-relic:$id:0:$family',
        );
        final item = InventoryItem.fromJson(
          jsonDecode(jsonEncode(original.toJson())),
        );
        expect(item.nome, name);
        final appearance = item.craftData['equipmentAppearance'] as String;
        expect(item.note, startsWith(appearance));
        expect(item.ability?.nome, original.ability?.nome);
        expect(
          item.craftData['sourceSkill'],
          original.craftData['sourceSkill'],
        );
        expect(item.livelloOggetto, 4);
        expect(item.gradoOggetto, 2);
        expect(item.bonusDanno, family == 'weapon' ? 10 : 0);
        expect(item.bonusDifesa, switch (family) {
          'weapon' => 0,
          'shield' => 5,
          _ => 6,
        });
        if (family == 'weapon') {
          expect(item.craftData['weaponAppearance'], contains(design.$4));
        }
      }
    }
  });
}
