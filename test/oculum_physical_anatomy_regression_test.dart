import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  MonsterBookEntry entry(String id) => monsterBookEntryById(id)!;
  List<Map<String, dynamic>> parts(MonsterBookEntry value, String group) =>
      oculumMonsterPrecisionAnatomy(
        value,
      ).where((part) => part['group'] == group).toList();

  test('a grooved wheel does not create wings for Meccanio', () {
    for (final id in ['meccanio', 'meccanio_ammaccato']) {
      expect(parts(entry(id), 'wings'), isEmpty, reason: id);
    }
    for (final adjective in ['scanalata', 'scanalato', 'incanalato']) {
      final custom = entry('meccanio').copyWith(
        id: 'qa_wheel',
        nameIt: 'Ruota',
        descIt: 'Una creatura con una ruota $adjective e due braccia.',
      );
      expect(parts(custom, 'wings'), isEmpty, reason: adjective);
    }
    final winged = entry('meccanio').copyWith(
      id: 'qa_winged',
      nameIt: 'Creatura alata',
      descIt: 'Creatura alata con due ali e due occhi.',
    );
    expect(parts(winged, 'wings'), hasLength(2));
  });

  test('singular articles and pairs count the actual number of eyes', () {
    expect(parts(entry('observers_tear'), 'eyes'), hasLength(1));
    expect(parts(entry('obser_sunshine'), 'eyes'), hasLength(1));
    for (final phrase in ['un occhio', 'un grande occhio', 'una lente']) {
      final custom = entry(
        'obser_sunshine',
      ).copyWith(id: 'qa_single_eye', descIt: 'Disco di pietra con $phrase.');
      expect(parts(custom, 'eyes'), hasLength(1), reason: phrase);
    }
    final paired = entry('obser_sunshine').copyWith(
      id: 'qa_eye_pair',
      descIt: 'Disco di pietra con un paio di occhi.',
    );
    expect(parts(paired, 'eyes'), hasLength(2));
  });

  test('roots in the habitat are not targetable organs of an animal', () {
    for (final id in ['rascalume', 'mirula']) {
      expect(parts(entry(id), 'root'), isEmpty, reason: id);
    }
    expect(entry('rascalume').weakPointDescriptionIt, contains('baffi'));
    expect(entry('mirula').weakPointDescriptionIt, contains('branchie'));
    expect(parts(entry('mirula'), 'gills'), hasLength(1));
    expect(parts(entry('pianta_divoratrice_vetro'), 'root'), hasLength(1));
    expect(parts(entry('grofix'), 'root'), hasLength(1));
  });

  test('organic bandits and their empathic variants are not Postea robots', () {
    for (final id in [
      'scostubanditi',
      'granscostumato',
      'scostubanditi_empatico',
      'granscostumato_empatico',
    ]) {
      expect(entry(id).formTags, isNot(contains('Costrutto')), reason: id);
      expect(entry(id).formTags, isNot(contains('Robot')), reason: id);
    }
    expect(entry('meccanio').formTags, contains('Robot'));
    expect(entry('pupazzo_robotico_postea').formTags, contains('Robot'));
  });

  test('explicit saved anatomy and classification survive catalogue fixes', () {
    final custom = entry('scostubanditi_empatico').copyWith(
      classificationTags: ['Classificazione personale'],
      encounterRules: {
        'precisionBodyParts': [
          {'id': 'custom_root', 'group': 'root', 'weak': true},
          {'id': 'custom_wing', 'group': 'wings', 'weak': false},
        ],
      },
    );
    final restored = MonsterBookEntry.fromJson(custom.toJson());
    expect(restored.formTags, ['Classificazione personale']);
    expect(parts(restored, 'root').single['id'], 'custom_root');
    expect(parts(restored, 'wings').single['id'], 'custom_wing');
  });

  test('FireShield follows the confirmed five metre biped anatomy', () {
    final fire = entry('fire_shield');
    expect(fire.descIt, contains('cinque metri'));
    expect(fire.descIt, isNot(contains('sei arti')));
    expect(parts(fire, 'arms'), hasLength(2));
    expect(parts(fire, 'legs'), hasLength(2));
    expect(parts(fire, 'head'), hasLength(1));
    expect(parts(fire, 'eyes'), hasLength(2));
    expect(parts(fire, 'horns'), hasLength(2));
    expect(parts(fire, 'wings'), isEmpty);
    final variant = fire.copyWith(id: 'fire_shield_variante_corazzata');
    expect(parts(variant, 'arms'), hasLength(2));
    expect(parts(variant, 'legs'), hasLength(2));
  });
}
