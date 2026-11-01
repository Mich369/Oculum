import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

Future<(dynamic, OculumPerformanceProbe)> mountRunicGolem(
  WidgetTester tester,
) async {
  final (state, probe) = await fixtures.mountFight(tester);
  state.arti.clear();
  state.skills.clear();
  state.titoli.clear();
  state.trattiRazziali.clear();
  state.inventario.clear();
  state.activeConditions.clear();
  state.activeStructuredEffects.clear();
  state.schedePersonaggio[state.schedaCorrente]['monsterBookSourceId'] =
      'golem_runico';
  state.schedePersonaggio[state.schedaCorrente]['planarRuntime'] =
      <String, dynamic>{
        'constructCore': <String, dynamic>{'used': true},
        'anatomicalPartRules': <String, dynamic>{
          'chest_plates': <String, dynamic>{'maximumHp': 20},
        },
      };
  state.resilienzaController.text = '20';
  state.currentResilienzaController.text = '20';
  state.livelloController.text = '3';
  state.gradoController.text = '0';
  state.currentHpController.text = '200';
  state.scudoController.text = '0';
  state.scudoOculumController.text = '0';
  state.scudoCriticoController.text = '0';
  state.hpTempController.text = '0';
  state.scudoSalvataggioAttivo = false;
  state.modificatoreDannoSelezionato = 'Normale';
  probe.invalidateDerivedCaches();
  probe.recordCurrentEncounter();
  return (state, probe);
}

Map<String, dynamic> hit(OculumPerformanceProbe p, String id) => {
  'id': id,
  'sourceTag': 'ENEMY',
  'sourceName': 'Avversario',
  'targetTag': p.ownerTag(),
  'scope': p.permissionScope,
  'encounterId': 'encounter_1',
  'targetBodyPart': 'chest_plates',
};

void main() {
  test('a hidden runic core never makes the entire chest a weak point', () {
    final full = oculumMonsterPrecisionAnatomy(
      monsterBookEntryById('golem_runico')!,
    );
    final closed = oculumReferenceCreaturePrecisionParts(
      full,
      monsterId: 'golem_runico',
    );
    expect(closed.where((p) => p['weak'] == true), isEmpty);
    final exposed = oculumReferenceCreaturePrecisionParts(
      full,
      monsterId: 'golem_runico',
      runicGolemCoreExposed: true,
    );
    expect(exposed.where((p) => p['weak'] == true).map((p) => p['id']), [
      'core',
    ]);
  });
  test('runic plates hide the core and preserve explicit Master anatomy', () {
    final original = <Map<String, dynamic>>[
      {'id': 'body', 'group': 'body', 'weak': false},
      {'id': 'core', 'group': 'core', 'weak': true},
    ];
    for (final id in ['golem_runico', 'golem_runico_variante_antico']) {
      final intact = oculumReferenceCreaturePrecisionParts(
        original,
        monsterId: id,
      );
      expect(intact.any((p) => p['id'] == 'chest_plates'), isTrue);
      expect(intact.any((p) => p['id'] == 'core'), isFalse);
      final exposed = oculumReferenceCreaturePrecisionParts(
        original,
        monsterId: id,
        runicGolemCoreExposed: true,
      );
      expect(exposed.singleWhere((p) => p['id'] == 'core')['weak'], isTrue);
      expect(
        oculumReferenceCreaturePrecisionParts(
          original,
          monsterId: id,
          explicitMasterAnatomy: true,
        ),
        original,
      );
    }
    expect(original, hasLength(2));
    expect(
      oculumReferenceCreaturePrecisionParts(
        original,
        monsterId: 'golem_roccia',
      ),
      original,
    );
  });

  test('exposure requires zero plate integrity and its own editable rules', () {
    expect(oculumRunicGolemPlatesBroken({}), isFalse);
    final state = <String, dynamic>{
      'anatomicalParts': {
        'parts': {
          'box': {'maximumHp': 20, 'damageTaken': 20},
          'chest_plates': {'maximumHp': 20, 'damageTaken': 10, 'injured': true},
        },
      },
      'pagePurchased': true,
      'weakPoint': true,
    };
    expect(oculumRunicGolemPlatesBroken(state), isFalse);
    ((state['anatomicalParts'] as Map)['parts'] as Map)['chest_plates'] = {
      'maximumHp': 20,
      'damageTaken': 20,
    };
    expect(oculumRunicGolemPlatesBroken(jsonDecode(jsonEncode(state))), isTrue);
    state['runicGolemPlateRules'] = {'coreExposed': false};
    expect(oculumRunicGolemPlatesBroken(state), isFalse);
    state['runicGolemPlateRules'] = {'coreExposed': true};
    expect(oculumRunicGolemPlatesBroken(state), isTrue);
    final rules =
        monsterBookEntryById(
              'golem_runico',
            )!.encounterRules['anatomicalPartRules']
            as Map;
    expect((rules['chest_plates'] as Map)['maximumHpFraction'], .35);
    expect((rules['chest_plates'] as Map)['criticalCanInjure'], isFalse);
  });

  testWidgets(
    'local and remote core access follows plates, not Book knowledge',
    (tester) async {
      final (_, p) = await mountRunicGolem(tester);
      expect(p.anatomicalTargetAvailable('core'), isFalse);
      final remote = <String, dynamic>{
        'id': 'ENEMY',
        'sheetTag': 'ENEMY',
        'monsterBookId': 'golem_runico',
        'pagePurchased': true,
        'weakPointKnown': true,
        'faunaPublic': {'runicGolemCoreExposed': false},
        'precisionBodyParts': [
          {'id': 'core', 'label': 'Nucleo'},
        ],
      };
      expect(
        p.anatomicalPartsForTarget(remote).any((part) => part['id'] == 'core'),
        isFalse,
      );
      remote['faunaPublic'] = {'runicGolemCoreExposed': true};
      expect(
        p.anatomicalPartsForTarget(remote).any((part) => part['id'] == 'core'),
        isTrue,
      );
      expect(p.anatomicalTargetAvailable('core'), isFalse);
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'actual damage breaks plates once; reload and repair stay coherent',
    (tester) async {
      final (_, p) = await mountRunicGolem(tester);
      final bodyHp = p.currentHp();
      await p.anatomicalTargetHit(
        hit(p, 'shield-only'),
        hpLost: 0,
        critical: true,
      );
      await p.anatomicalTargetHit(
        hit(p, 'critical-partial'),
        hpLost: 7,
        critical: true,
      );
      expect(p.anatomicalTargetAvailable('core'), isFalse);
      final plates =
          (p.anatomicalPartsSnapshot()['parts'] as Map)['chest_plates'] as Map;
      expect(plates['damageTaken'], 7);
      expect(plates['injured'], isFalse);
      await p.anatomicalTargetHit(
        hit(p, 'finishing-hit'),
        hpLost: 13,
        critical: false,
      );
      expect(p.anatomicalTargetAvailable('core'), isTrue);
      final saved = p.snapshot();
      expect((saved['faunaPublic'] as Map)['runicGolemCoreExposed'], isTrue);
      p.load(saved);
      await p.anatomicalTargetHit(
        hit(p, 'finishing-hit'),
        hpLost: 13,
        critical: false,
      );
      expect(
        ((p.anatomicalPartsSnapshot()['parts'] as Map)['chest_plates']
            as Map)['damageTaken'],
        20,
      );
      expect(
        p.currentHp(),
        bodyHp,
        reason: 'The anatomy seam must not damage the body twice',
      );
      p.repairAnatomicalParts('master_repair');
      expect(p.anatomicalTargetAvailable('core'), isFalse);
      await closeFixture(tester, p);
    },
  );

  testWidgets('foreign scopes and encounters cannot break the owned plates', (
    tester,
  ) async {
    final (_, p) = await mountRunicGolem(tester);
    for (final forged in [
      {...hit(p, 'foreign-target'), 'targetTag': 'OTHER'},
      {...hit(p, 'foreign-scope'), 'scope': 'OTHER'},
      {...hit(p, 'foreign-encounter'), 'encounterId': 'OTHER'},
    ]) {
      await p.anatomicalTargetHit(forged, hpLost: 100, critical: true);
    }
    expect(p.anatomicalTargetAvailable('core'), isFalse);
    expect(
      p.anatomicalPartsSnapshot()['parts'],
      isNot(contains('chest_plates')),
    );
    await closeFixture(tester, p);
  });
}
