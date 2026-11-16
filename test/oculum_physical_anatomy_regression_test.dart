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

  test('Ombra Ignota has one default weak eye and keeps Master anatomy', () {
    final shadow = entry('ombra_ignota');
    final eye = parts(shadow, 'eyes').single;
    expect(eye['id'], 'eyes');
    expect(eye['label'], 'Occhio');
    expect(eye['weak'], isTrue);
    final shortened = shadow.copyWith(
      descIt: 'Figura con un solo occhio viola.',
    );
    expect(parts(shortened, 'eyes').single['id'], 'eyes');
    final legacyVariant = shortened.copyWith(id: 'ombra_ignota_variante_A');
    expect(oculumHasDefaultOmbraIgnotaEye(legacyVariant), isFalse);
    expect(parts(legacyVariant, 'eyes').map((part) => part['id']), [
      'eyes_1',
      'eyes_2',
    ]);
    final custom = shadow.copyWith(
      encounterRules: {
        ...shadow.encounterRules,
        'precisionBodyParts': [
          {'id': 'eyes_1', 'group': 'eyes', 'label': 'Primo occhio'},
          {'id': 'eyes_2', 'group': 'eyes', 'label': 'Secondo occhio'},
        ],
      },
    );
    expect(oculumHasDefaultOmbraIgnotaEye(custom), isFalse);
    expect(parts(custom, 'eyes').map((part) => part['id']), [
      'eyes_1',
      'eyes_2',
    ]);
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

  test('Armored Snorlo has independently targetable head, eyes and legs', () {
    final armored = entry('snorlo_variante_corazzata');
    expect(parts(armored, 'head').single['id'], 'head');
    expect(parts(armored, 'eyes').map((part) => part['id']), [
      'eyes_1',
      'eyes_2',
    ]);
    expect(parts(armored, 'legs').map((part) => part['id']), [
      'legs_1',
      'legs_2',
    ]);
    expect(parts(armored, 'arms'), hasLength(4));
    expect(parts(armored, 'joint'), hasLength(1));
    expect(parts(entry('snorlo'), 'eyes'), isEmpty);
  });

  test('Alaryft adds individual limbs and horns to the ventral targets', () {
    final queen = entry('habitat_demoniaco_regina_delle_gole_vulcaniche');
    expect(queen.nameIt, 'Alaryft');
    expect(
      oculumMonsterNameSearchAliases(queen),
      contains('Regina delle gole vulcaniche'),
    );
    final anatomy = oculumMonsterPrecisionAnatomy(queen);
    expect(
      anatomy.map((part) => part['id']),
      unorderedEquals([
        'body',
        'eyes_1',
        'eyes_2',
        'wings_1',
        'wings_2',
        'joint',
        'rim',
        'legs_1',
        'legs_2',
        'legs_3',
        'legs_4',
        'horns_1',
        'horns_2',
      ]),
    );
    expect(
      anatomy.where((part) => part['weak'] == true).map((part) => part['id']),
      unorderedEquals(['joint', 'rim']),
    );
    expect(queen.hasNaturalFlight, isFalse);
  });

  test('Tryjaw has three separate heads, four legs and one tail', () {
    final hydra = entry('idra_base');
    expect(parts(hydra, 'head').map((part) => part['id']), [
      'head_1',
      'head_2',
      'head_3',
    ]);
    expect(parts(hydra, 'legs'), hasLength(4));
    expect(parts(hydra, 'tail').single['id'], 'tail');
    expect(parts(hydra, 'body').single['id'], 'body');
    expect(
      oculumMonsterPrecisionAnatomy(hydra).map((part) => part['label']),
      contains('Piega del corpo'),
    );
  });

  test('the acid-sap spider retains its sensory node and has eight legs', () {
    final spider = entry('habitat_foresta_elementale_ragno_della_linfa_acida');
    expect(parts(spider, 'legs').map((part) => part['id']), [
      for (var index = 1; index <= 8; index++) 'legs_$index',
    ]);
    expect(
      oculumMonsterPrecisionAnatomy(spider).map((part) => part['label']),
      containsAll(['Corpo', 'Testa', 'Nodo sensoriale']),
    );
  });

  test('Necthrall is a Spirit Boss with a separate spindle', () {
    final boss = entry(oculumNecthrallId);
    expect(boss.nameIt, 'Necthrall');
    expect(boss.isBoss, isTrue);
    expect(boss.elementId, 'spirituale');
    expect(parts(boss, 'spindle').single['id'], oculumNecthrallSpindle);
    expect(oculumPlanarTechnique(oculumNecthrallBind)?.name, 'Necthbind');
    expect(oculumMonsterNameSearchAliases(boss), contains('Marionettista'));
  });
}
