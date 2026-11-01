import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  final expected = <String, Map<String, int>>{
    'deadly_sins': {'head': 1, 'arms': 2, 'legs': 2, 'horns': 2, 'eyes': 0},
    'rascalume': {
      'head': 1,
      'legs': 4,
      'arms': 0,
      'eyes': 2,
      'ears': 2,
      'tail': 1,
      'root': 0,
    },
    'mirula': {
      'head': 1,
      'legs': 4,
      'arms': 0,
      'eyes': 2,
      'tail': 1,
      'gills': 1,
      'root': 0,
    },
    'colosso_prismarite': {
      'head': 1,
      'arms': 2,
      'legs': 2,
      'eyes': 0,
      'joint': 1,
    },
    'brumilio': {
      'head': 1,
      'legs': 2,
      'arms': 0,
      'wings': 2,
      'eyes': 2,
      'tail': 1,
    },
    'vendulo': {'head': 1, 'legs': 4, 'arms': 0, 'eyes': 2},
    'obliterated_devil': {
      'head': 1,
      'arms': 2,
      'legs': 2,
      'eyes': 3,
      'horns': 2,
      'fold': 0,
    },
  };
  for (final row in expected.entries) {
    test('${row.key} matches approved anatomy on base and variants', () {
      final base = monsterBookEntryById(row.key)!;
      for (final entry in [base, base.copyWith(id: '${base.id}_variante_qa')]) {
        final parts = oculumMonsterPrecisionAnatomy(entry);
        expect(parts.map((p) => p['id']).toSet(), hasLength(parts.length));
        for (final count in row.value.entries) {
          expect(
            parts.where((p) => p['group'] == count.key),
            hasLength(count.value),
            reason: '${entry.id}/${count.key}',
          );
        }
      }
    });
  }
  test(
    'named weaknesses remain specific instead of affecting adjacent limbs',
    () {
      final weakIds = <String, Set<String>>{
        'deadly_sins': {'weapon_chain'},
        'rascalume': {'whiskers'},
        'mirula': {'gills'},
        'colosso_prismarite': {'joint'},
        'brumilio': {'torso'},
        'vendulo': {'facial_skin'},
        'obliterated_devil': {'third_eye'},
        'golem_runico': {'core'},
        'rock_cloud_golem': {'core'},
        'costrutto_prismatico': {'core'},
        'pupazzo_artigliato': {'leg_springs'},
        'rock_shield': {'belly', 'wound'},
      };
      for (final row in weakIds.entries) {
        final parts = oculumMonsterPrecisionAnatomy(
          monsterBookEntryById(row.key)!,
        );
        expect(
          parts.where((p) => p['weak'] == true).map((p) => p['id']).toSet(),
          row.value,
          reason: row.key,
        );
      }
      final goblin = oculumMonsterPrecisionAnatomy(
        monsterBookEntryById('goblin_kamikaze')!,
      );
      expect(
        goblin.singleWhere((p) => p['id'] == 'belly')['label'],
        contains('Innesco'),
      );
    },
  );
  test('materials follow the confirmed rock body and metal attachments', () {
    final colossus = oculumMonsterPrecisionAnatomy(
      monsterBookEntryById('colosso_prismarite')!,
    );
    expect(colossus.every((p) => p['material'] == 'stone'), isTrue);
    for (final pair in [
      ('deadly_sins', 'weapon_chain'),
      ('pupazzo_artigliato', 'leg_springs'),
    ]) {
      final parts = oculumMonsterPrecisionAnatomy(
        monsterBookEntryById(pair.$1)!,
      );
      expect(parts.singleWhere((p) => p['id'] == pair.$2)['material'], 'metal');
    }
  });
  test(
    'explicit Master anatomy and edited weak-point text keep precedence',
    () {
      for (final id in expected.keys) {
        final base = monsterBookEntryById(id)!;
        final personal = base.copyWith(
          encounterRules: {
            ...base.encounterRules,
            'precisionBodyParts': [
              {
                'id': 'personal',
                'group': 'custom',
                'weak': true,
                'maximumHp': 7,
                'privateNote': 'kept',
              },
            ],
          },
        );
        final parts = oculumMonsterPrecisionAnatomy(personal);
        expect(parts, hasLength(1));
        expect(parts.single['maximumHp'], 7);
        expect(parts.single['privateNote'], 'kept');
      }
      for (final pair in [
        ('deadly_sins', 'La testa.'),
        ('vendulo', 'Il corpo.'),
        ('obliterated_devil', 'Le corna.'),
      ]) {
        final edited = monsterBookEntryById(
          pair.$1,
        )!.copyWith(weakPointIt: pair.$2);
        final weak = oculumMonsterPrecisionAnatomy(
          edited,
        ).where((p) => p['weak'] == true).map((p) => p['group']).toSet();
        expect(
          weak,
          contains(
            pair.$1 == 'deadly_sins'
                ? 'head'
                : pair.$1 == 'vendulo'
                ? 'body'
                : 'horns',
          ),
        );
      }
    },
  );
  test('ordinary words cannot invent a torso, sac, heart, core or antennae', () {
    final entry = monsterBookEntryById('goblin_kamikaze')!.copyWith(
      id: 'qa_word_boundaries',
      descIt:
          'Un goblin dall’aspetto quieto. Mantenne rancuore; porta una bisacca, due corna piegate e piccole ancore.',
      weakPointIt: 'Un dettaglio ignoto.',
      encounterRules: const {},
    );
    final groups = oculumMonsterPrecisionAnatomy(
      entry,
    ).map((p) => p['group']).toSet();
    for (final absent in [
      'torso',
      'sac',
      'heart',
      'core',
      'antennae',
      'fold',
    ]) {
      expect(groups, isNot(contains(absent)), reason: absent);
    }
  });
  test('real named details and plural joints are still recognized', () {
    final entry = monsterBookEntryById('goblin_kamikaze')!.copyWith(
      id: 'qa_real_details',
      descIt:
          'Un essere con torace, sacca, cuore, nucleo, antenne, pieghe e giunture.',
      weakPointIt: 'Le giunture.',
      encounterRules: const {},
    );
    final parts = oculumMonsterPrecisionAnatomy(entry);
    for (final group in [
      'torso',
      'sac',
      'heart',
      'core',
      'antennae',
      'fold',
      'joint',
    ]) {
      expect(parts.any((p) => p['group'] == group), isTrue, reason: group);
    }
    expect(parts.singleWhere((p) => p['group'] == 'joint')['weak'], isTrue);
  });
}
