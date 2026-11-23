import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart' show oculumMonsterCreationStats;
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  MonsterBookEntry monster(String id) => monsterBookEntryById(id)!;

  List<Map<String, dynamic>> anatomy(String id) =>
      oculumMonsterPrecisionAnatomy(monster(id));

  Iterable<Map<String, dynamic>> group(
    List<Map<String, dynamic>> parts,
    String id,
  ) => parts.where((part) => part['group'] == id);

  Iterable<String> weakIds(List<Map<String, dynamic>> parts) => parts
      .where((part) => part['weak'] == true)
      .map((part) => part['id'] as String);

  test('winged eyes have two separately targetable wings', () {
    for (final id in ['oculiath', 'solgaze', 'sanguifang']) {
      final parts = anatomy(id);
      expect(group(parts, 'eyes'), hasLength(1), reason: id);
      final wings = group(parts, 'wings');
      expect(wings, hasLength(2), reason: id);
      expect(wings.map((part) => part['side']).toSet(), {
        'left',
        'right',
      }, reason: id);
    }
    expect(weakIds(anatomy('solgaze')), ['eyes']);
    expect(anatomy('solgaze').map((part) => part['id']), [
      'body',
      'eyes',
      'wings_1',
      'wings_2',
    ]);
  });

  test('Oculiath has one independently targetable ventral hook', () {
    final hook = group(anatomy('oculiath'), 'arms').single;
    expect(hook['id'], 'hook');
  });

  test('Greater Oculiath has five eye targets and no flight limbs', () {
    final parts = anatomy('oculiath_maggiore');
    expect(monster('oculiath_maggiore').hasNaturalFlight, isTrue);
    expect(
      monster('oculiath_maggiore').encounterRules['levitationWithoutFall'],
      isTrue,
    );
    expect(group(parts, 'eyes').map((part) => part['id']), [
      'eyes_1',
      'eyes_2',
      'eyes_3',
      'eyes_4',
      'eyes_5',
    ]);
    expect(parts.map((part) => part['group']).toSet(), {'body', 'eyes'});
  });

  test('ravens keep the same two wings, two legs and bone mask', () {
    for (final id in ['corvo_della_morte', 'corvo_della_morte_evoluto']) {
      final parts = anatomy(id);
      expect(monster(id).hasNaturalFlight, isTrue);
      expect(group(parts, 'wings'), hasLength(2));
      expect(group(parts, 'legs'), hasLength(2));
      expect(group(parts, 'head'), hasLength(1));
      expect(group(parts, 'beak'), hasLength(1));
      expect(group(parts, 'mask').single['material'], 'bone');
    }
  });

  test(
    'Forest Demon family anatomy and Forsaken growth match the catalogue',
    () {
      const baby = 'baby_forest_demon';
      const adult = 'forest_demon';
      for (final id in [baby, adult, '${baby}_errato', '${adult}_errato']) {
        final parts = anatomy(id);
        expect(group(parts, 'arms'), isEmpty, reason: id);
        expect(group(parts, 'legs'), hasLength(4), reason: id);
        expect(group(parts, 'eyes'), hasLength(2), reason: id);
        expect(group(parts, 'horns'), hasLength(3), reason: id);
        expect(group(parts, 'tail'), hasLength(1), reason: id);
        expect(monster(id).fightsAlone, id.endsWith('_errato'));
      }
      for (final level in [0, 10, 30]) {
        int power(String id) => oculumMonsterCreationStats(
          monster(id),
          level,
        ).values.reduce((sum, value) => sum + value);
        expect(power('${baby}_errato'), greaterThan(power(baby)));
        expect(power('${baby}_errato'), lessThan(power(adult)));
        expect(power('${adult}_errato'), greaterThan(power(adult)));
      }
      expect(
        MonsterBookEntry.fromJson(
          monster('${baby}_errato').toJson(),
        ).fightsAlone,
        isTrue,
      );
    },
  );

  test('the crustacean has exactly one weak target at the dorsal membrane', () {
    final parts = anatomy('crostaceo_corazzato');
    expect(group(parts, 'arms').map((part) => part['id']), [
      'left_claw',
      'right_claw',
    ]);
    expect(group(parts, 'head'), hasLength(1));
    final legs = group(parts, 'legs');
    expect(legs.map((part) => part['id']).toSet(), hasLength(8));
    expect(legs.where((part) => part['side'] == 'left'), hasLength(4));
    expect(legs.where((part) => part['side'] == 'right'), hasLength(4));
    expect(weakIds(parts), ['dorsal_membrane']);
    expect(
      parts.singleWhere((part) => part['id'] == 'dorsal_membrane')['label'],
      contains('verde'),
    );
    expect(
      parts.singleWhere((part) => part['id'] == 'body')['material'],
      'chitin',
    );
  });

  test('Tenaglia remains available with either claw intact', () {
    const broken = {'maximumHp': 15, 'damageTaken': 15};
    const injured = {'maximumHp': 15, 'damageTaken': 14, 'injured': true};
    bool available(Map<String, dynamic> parts) =>
        oculumArmouredCrustaceanCanUsePincers({'parts': parts});

    expect(oculumArmouredCrustaceanCanUsePincers({}), isTrue);
    expect(available({'left_claw': broken}), isTrue);
    expect(available({'right_claw': broken}), isTrue);
    expect(available({'left_claw': broken, 'right_claw': injured}), isTrue);
    expect(available({'left_claw': broken, 'right_claw': broken}), isFalse);
  });

  test(
    'golem materials are anatomical and explicit Master data still wins',
    () {
      for (final (id, material) in [
        ('terramound', 'stone'),
        ('lignobark', 'wood'),
      ]) {
        final entry = monster(id);
        final parts = anatomy(id);
        expect(group(parts, 'arms'), hasLength(2));
        expect(group(parts, 'legs'), hasLength(2));
        expect(parts.map((part) => part['material']).toSet(), {material});
        expect(weakIds(parts), isEmpty);
        expect(oculumMonsterHasAnatomicalWeakPoint(entry), isFalse);
        final custom = entry.copyWith(
          encounterRules: {
            ...entry.encounterRules,
            'precisionBodyParts': [
              {
                'id': 'joint',
                'group': 'joint',
                'label': 'Giuntura',
                'weak': true,
              },
            ],
          },
        );
        expect(weakIds(oculumMonsterPrecisionAnatomy(custom)), ['joint']);
        expect(oculumMonsterHasAnatomicalWeakPoint(custom), isTrue);
      }
    },
  );
}
