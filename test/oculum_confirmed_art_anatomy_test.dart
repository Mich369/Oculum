import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  List<Map<String, dynamic>> parts(String id) =>
      oculumMonsterPrecisionAnatomy(monsterBookEntryById(id)!);
  int count(String id, String group) =>
      parts(id).where((p) => p['group'] == group).length;

  test(
    'five newly approved designs keep their actual body counts and original weak-point rules',
    () {
      expect(count('mezzo_demone_cosciente', 'arms'), 2);
      expect(count('mezzo_demone_cosciente', 'legs'), 2);
      expect(count('mezzo_demone_cosciente', 'horns'), 2);
      expect(count('mezzo_demone_cosciente', 'eyes'), 2);
      expect(count('nuvola_in_bottiglia', 'eyes'), 1);
      expect(count('nuvola_in_bottiglia', 'hands'), 2);
      expect(count('nuvola_in_bottiglia', 'receivers'), 2);
      expect(count('nuvola_in_bottiglia', 'legs'), 0);
      expect(
        parts(
          'nuvola_in_bottiglia',
        ).singleWhere((p) => p['id'] == 'bottle')['weak'],
        true,
      );
      expect(count('il_doppione', 'head'), 1);
      expect(count('il_doppione', 'arms'), 2);
      expect(count('il_doppione', 'legs'), 2);
      expect(count('il_doppione', 'eyes'), 0);
      expect(
        parts('il_doppione').where((p) => p['weak'] == true).single['id'],
        'crest',
      );
      for (final id in [
        'aberrazione_metallica_angelica',
        'aberrazione_metallica_solare',
      ]) {
        expect(count(id, 'arms'), 2);
        expect(count(id, 'legs'), 2);
        expect(count(id, 'wings'), 0);
        expect(count(id, 'eyes'), 0);
        expect(parts(id).where((p) => p['weak'] == true).single['id'], 'joint');
      }
    },
  );

  test('an Azione in corso is not an orso with four legs', () {
    final cloud = monsterBookEntryById('nuvola_in_bottiglia')!.copyWith(
      id: 'regression_cloud_in_progress',
      nameIt: 'Nube di prova',
      nameEn: 'Test cloud',
      descIt:
          'Una nube compatta con un occhio e due mani vaporose. '
          'Interrompe una Azione in corso.',
      encounterRules: const {},
    );
    final actual = oculumMonsterPrecisionAnatomy(cloud);
    expect(
      actual.where((part) => part['group'] == 'legs'),
      isEmpty,
      reason: 'The word corso describes an action, not a bear anatomy.',
    );
  });

  test('a real catalogued orso retains its four quadruped legs', () {
    final bear = monsterBookEntryById('ciclo_orso_aculei')!;
    expect(oculumMonsterPhysicalDescription(bear), contains('un orso'));
    expect(
      oculumMonsterPrecisionAnatomy(
        bear,
      ).where((part) => part['group'] == 'legs'),
      hasLength(4),
    );
  });

  test('saved Master legs override a cloud without natural legs', () {
    final cloud = monsterBookEntryById('nuvola_in_bottiglia')!.copyWith(
      encounterRules: {
        'precisionBodyParts': [
          {
            'id': 'custom_support',
            'label': 'Appoggio personale',
            'group': 'legs',
            'weak': false,
            'editorNote': 'keep',
          },
        ],
      },
    );
    final actual = oculumMonsterPrecisionAnatomy(cloud);
    expect(actual, hasLength(1));
    expect(actual.single['id'], 'custom_support');
    expect(actual.single['group'], 'legs');
    expect(actual.single['editorNote'], 'keep');
    actual.single['label'] = 'Changed copy';
    expect(
      (cloud.encounterRules['precisionBodyParts'] as List).single['label'],
      'Appoggio personale',
    );
  });

  for (final name in ['lusier_iii', 'erik_i']) {
    testWidgets(
      '$name keeps exposed eyes instead of inheriting the generic solar helmet',
      (tester) async {
        final (state, p) = await fixtures.mountFight(tester);
        final sheet = name == 'lusier_iii'
            ? oculumBuildLusierSheet()
            : oculumBuildErikSheet();
        state.schedePersonaggio[0] = sheet;
        p.load(sheet);
        p.invalidateDerivedCaches();
        expect(
          p.precisionParts().where((part) => part['group'] == 'eyes'),
          hasLength(2),
        );
        expect(
          p.precisionParts().any((part) => part['id'] == 'helmet_visor'),
          false,
        );
        final saved = p.snapshot();
        expect((saved['faunaPublic'] as Map)['solarFaceUncovered'], true);
        p.load(saved);
        expect(
          p.precisionParts().where((part) => part['group'] == 'eyes'),
          hasLength(2),
        );
        expect(
          oculumSolarFaceUncovered({
            'canonicalNpc': name,
            'solarFaceUncovered': false,
          }),
          false,
        );
        await closeFixture(tester, p);
      },
    );
  }

  for (final id in ['guardiano_lunare', 'guardian_devil_moon']) {
    testWidgets('$id known page cannot manufacture a hidden core target', (
      tester,
    ) async {
      final (_, p) = await fixtures.mountFight(tester);
      p.rememberMonsterDiscovery(id, seen: true, weakPoint: true);
      final target = <String, dynamic>{
        'id': p.attackTargetTags().first,
        'monsterBookId': id,
        'monsterBookSourceId': id,
        'faunaPublic': {
          'lunarGuardianCore': {'coreExposed': false},
        },
      };
      expect(p.knowsCombatWeakPoint(target), false);
      expect(await p.selectPrecisionPart(target, weakOnly: true), isNull);
      target['faunaPublic'] = {
        'lunarGuardianCore': {'coreExposed': true},
      };
      expect(p.knowsCombatWeakPoint(target), true);
      await closeFixture(tester, p);
    });
  }

  testWidgets(
    'knowing the giant fire vulnerability cannot invent a weak-point target',
    (tester) async {
      final (_, p) = await fixtures.mountFight(tester);
      p.rememberMonsterDiscovery('gigante_sabbia', seen: true, weakPoint: true);
      final target = {
        'id': p.attackTargetTags().first,
        'monsterBookId': 'gigante_sabbia',
        'monsterBookSourceId': 'gigante_sabbia',
      };
      expect(p.knowsCombatWeakPoint(target), false);
      expect(await p.selectPrecisionPart(target, weakOnly: true), isNull);
      await closeFixture(tester, p);
    },
  );

  test(
    'Master can explicitly override the giant anatomical-weak-point rule',
    () {
      final giant = monsterBookEntryById('gigante_sabbia')!;
      expect(
        oculumMonsterHasAnatomicalWeakPoint(
          giant.copyWith(
            encounterRules: {
              ...giant.encounterRules,
              'hasAnatomicalWeakPoint': true,
            },
          ),
        ),
        true,
      );
      expect(
        oculumMonsterHasAnatomicalWeakPoint(
          giant.copyWith(
            encounterRules: {
              ...giant.encounterRules,
              'precisionBodyParts': [
                {'id': 'custom_point', 'group': 'joint', 'weak': true},
              ],
            },
          ),
        ),
        true,
      );
    },
  );

  test(
    'approved sand quadruped has four legs, horns and a tail, no human arms',
    () {
      expect(count('mostro_sabbia', 'legs'), 4);
      expect(count('mostro_sabbia', 'arms'), 0);
      expect(count('mostro_sabbia', 'horns'), 2);
      expect(count('mostro_sabbia', 'tail'), 1);
      expect(count('mostro_sabbia', 'head'), 1);
    },
  );
  test(
    'approved giant is humanoid without an anatomical weak point or core',
    () {
      expect(count('gigante_sabbia', 'arms'), 2);
      expect(count('gigante_sabbia', 'legs'), 2);
      expect(count('gigante_sabbia', 'tail'), 1);
      expect(parts('gigante_sabbia').where((p) => p['weak'] == true), isEmpty);
      expect(count('gigante_sabbia', 'core'), 0);
      expect(
        oculumMonsterHasAnatomicalWeakPoint(
          monsterBookEntryById('gigante_sabbia'),
        ),
        false,
      );
    },
  );
  for (final id in [
    'costrutto_minore',
    'funghetto_cappuccio_rosso',
    'topino_avventuroso',
  ]) {
    test('$id has two arms, two legs and two visible eyes', () {
      expect(count(id, 'arms'), 2);
      expect(count(id, 'legs'), 2);
      expect(count(id, 'eyes'), 2);
      final ids = parts(id).map((p) => p['id']).toList();
      expect(ids.toSet().length, ids.length);
    });
  }
  test('mouse has distinct ears/tail and mushroom a distinct cap', () {
    expect(count('topino_avventuroso', 'ears'), 2);
    expect(count('topino_avventuroso', 'tail'), 1);
    expect(count('funghetto_cappuccio_rosso', 'cap'), 1);
    expect(
      monsterBookEntryById('topino_avventuroso')!.descIt,
      contains('tortora'),
    );
  });
  test('Bell Fly has six legs, four wings and no detached head', () {
    expect(count('mosca_campana', 'legs'), 6);
    expect(count('mosca_campana', 'wings'), 4);
    expect(count('mosca_campana', 'eyes'), 2);
    expect(count('mosca_campana', 'head'), 0);
    expect(
      monsterBookEntryById('mosca_campana')!.descIt,
      contains('senza pupille'),
    );
  });
  test('Sharp has four small legs and eyes; Shadow Devil remains eyeless', () {
    expect(count('sharp', 'legs'), 4);
    expect(count('sharp', 'eyes'), 2);
    expect(count('shadow_devil', 'eyes'), 0);
    expect(count('shadow_devil', 'horns'), 2);
  });
  test(
    'solar helmets do not expose biological eyes; brothers retain custom anatomy',
    () {
      for (final id in [
        'guardia_solare',
        'guardia_solare_elite',
        'guardiano_solare',
      ]) {
        expect(count(id, 'eyes'), 0);
        final visor = parts(id).singleWhere((p) => p['id'] == 'helmet_visor');
        expect(visor['material'], 'metal');
        expect(visor['weak'], false);
      }
    },
  );
  test(
    'lunar blade arms and legs are separate; all four native crystals remain',
    () {
      for (final id in ['mostro_lunare', 'mostro_lunare_demoniaco']) {
        expect(count(id, 'arms'), 2);
        expect(count(id, 'legs'), 2);
        final crystals = parts(
          id,
        ).where((p) => '${p['id']}'.startsWith('lunar_crystal_'));
        expect(crystals.length, 4);
        for (final crystal in crystals) {
          expect(
            oculumAnatomicalPartIsNative(monsterId: id, part: crystal),
            true,
          );
        }
      }
    },
  );
  test('explicit saved Master anatomy wins over approved default facts', () {
    final original = monsterBookEntryById('mosca_campana')!;
    final custom = original.copyWith(
      encounterRules: {
        ...original.encounterRules,
        'precisionBodyParts': [
          {
            'id': 'custom_fin',
            'label': 'Pinna personale',
            'group': 'fins',
            'weak': false,
            'customField': 7,
          },
        ],
      },
    );
    final actual = oculumMonsterPrecisionAnatomy(custom);
    expect(actual.single['id'], 'custom_fin');
    expect(actual.single['customField'], 7);
    actual.single['label'] = 'Changed copy';
    expect(
      (custom.encounterRules['precisionBodyParts'] as List).single['label'],
      'Pinna personale',
    );
  });
  test(
    'part integrity respects sand/fungus/metal and explicit material overrides',
    () {
      for (final entry in {
        'mostro_sabbia': 'sand',
        'gigante_sabbia': 'sand',
        'funghetto_cappuccio_rosso': 'fiber',
        'costrutto_minore': 'metal',
      }.entries) {
        final monster = monsterBookEntryById(entry.key)!;
        final part = parts(entry.key).firstWhere((p) => p['group'] == 'legs');
        final rule = oculumAnatomicalPartRule(
          monsterId: entry.key,
          physicalDescription: oculumMonsterPhysicalDescription(monster),
          part: part,
          maximumBodyHp: 100,
        );
        expect(rule['material'], entry.value);
        expect(rule['legacyCriticalFracture'], false);
        expect(rule['maximumHp'], greaterThan(0));
        final custom = oculumAnatomicalPartRule(
          monsterId: entry.key,
          physicalDescription: '',
          part: part,
          maximumBodyHp: 100,
          overrides: {
            'material': 'crystal',
            'maximumHp': 73,
            'editorNote': 'keep',
          },
        );
        expect(custom['material'], 'crystal');
        expect(custom['maximumHp'], 73);
        expect(custom['editorNote'], 'keep');
      }
      expect(oculumAnatomicalInjuryLabel('sand'), 'Sabbia disgregata');
    },
  );
}
