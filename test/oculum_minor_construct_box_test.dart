import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

Future<(dynamic, OculumPerformanceProbe)> _mount(WidgetTester tester) async {
  final (state, p) = await fixtures.mountFight(tester);
  state.arti.clear();
  state.skills.clear();
  state.titoli.clear();
  state.trattiRazziali.clear();
  state.inventario.clear();
  state.activeConditions.clear();
  state.activeStructuredEffects.clear();
  state.schedePersonaggio[state.schedaCorrente]['monsterBookSourceId'] =
      'costrutto_minore';
  state.schedePersonaggio[state.schedaCorrente]['planarRuntime'] =
      <String, dynamic>{
        'constructCore': <String, dynamic>{'used': true},
        'anatomicalPartRules': <String, dynamic>{
          'box': <String, dynamic>{'maximumHp': 20},
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
  p.invalidateDerivedCaches();
  p.recordCurrentEncounter();
  return (state, p);
}

Map<String, dynamic> _hit(OculumPerformanceProbe p, String id, String part) => {
  'id': id,
  'sourceTag': 'ENEMY',
  'sourceName': 'Avversario',
  'targetTag': p.ownerTag(),
  'scope': p.permissionScope,
  'encounterId': 'encounter_1',
  'targetBodyPart': part,
};

void main() {
  test(
    'reference filters hide intact core and vanished bottle without mutating anatomy',
    () {
      final original = <Map<String, dynamic>>[
        {'id': 'body', 'group': 'body', 'label': 'Corpo', 'weak': false},
        {'id': 'core', 'group': 'core', 'label': 'Nucleo', 'weak': true},
      ];
      final hidden = oculumReferenceCreaturePrecisionParts(
        original,
        monsterId: 'costrutto_minore',
      );
      expect(hidden.any((p) => p['id'] == 'box'), isTrue);
      expect(hidden.any((p) => p['id'] == 'core'), isFalse);
      final exposed = oculumReferenceCreaturePrecisionParts(
        original,
        monsterId: 'costrutto_minore',
        minorConstructCoreExposed: true,
      );
      expect(exposed.singleWhere((p) => p['id'] == 'core')['weak'], isTrue);
      expect(original, hasLength(2));
      final custom = oculumReferenceCreaturePrecisionParts(
        original,
        monsterId: 'costrutto_minore',
        explicitMasterAnatomy: true,
      );
      expect(custom, original);
      final cloud = <Map<String, dynamic>>[
        {'id': 'bottle', 'group': 'bottle', 'weak': true},
        {'id': 'body', 'group': 'body', 'weak': false},
      ];
      expect(
        oculumReferenceCreaturePrecisionParts(
          cloud,
          monsterId: 'nuvola_in_bottiglia',
          bottledCloudPhase: 2,
        ),
        hasLength(1),
      );
      expect(cloud, hasLength(2));
    },
  );

  test(
    'box exposure needs zero integrity, not a critical injury or Book knowledge',
    () {
      expect(oculumMinorConstructBoxBroken({}), isFalse);
      expect(
        oculumMinorConstructBoxBroken({
          'anatomicalParts': {
            'parts': {
              'box': {'maximumHp': 20, 'damageTaken': 10, 'injured': true},
            },
          },
          'pagePurchased': true,
          'weakPoint': true,
        }),
        isFalse,
      );
      final state = <String, dynamic>{
        'anatomicalParts': {
          'parts': {
            'box': {'maximumHp': 20, 'damageTaken': 20},
          },
        },
      };
      expect(oculumMinorConstructBoxBroken(state), isTrue);
      expect(
        oculumMinorConstructBoxBroken(jsonDecode(jsonEncode(state))),
        isTrue,
      );
      state['minorConstructBoxRules'] = {'coreExposed': false};
      expect(oculumMinorConstructBoxBroken(state), isFalse);
      state['minorConstructBoxRules'] = {'coreExposed': true};
      expect(oculumMinorConstructBoxBroken(state), isTrue);
      final rule =
          monsterBookEntryById(
                'costrutto_minore',
              )!.encounterRules['anatomicalPartRules']
              as Map;
      expect((rule['box'] as Map)['maximumHpFraction'], .35);
      expect((rule['box'] as Map)['minimumHp'], 3);
    },
  );

  testWidgets(
    'core remains inaccessible locally and on remote purchased-page tokens until box breaks',
    (tester) async {
      final (state, p) = await _mount(tester);
      expect(p.precisionParts().any((part) => part['id'] == 'box'), isTrue);
      expect(p.anatomicalTargetAvailable('core'), isFalse);
      final remote = <String, dynamic>{
        'id': 'ENEMY',
        'sheetTag': 'ENEMY',
        'monsterBookId': 'costrutto_minore',
        'pagePurchased': true,
        'weakPointKnown': true,
        'faunaPublic': {'minorConstructCoreExposed': false},
        'precisionBodyParts': [
          {'id': 'core', 'label': 'Nucleo'},
        ],
      };
      expect(
        p.anatomicalPartsForTarget(remote).any((part) => part['id'] == 'core'),
        isFalse,
      );
      remote['faunaPublic'] = {'minorConstructCoreExposed': true};
      expect(
        p.anatomicalPartsForTarget(remote).any((part) => part['id'] == 'core'),
        isTrue,
      );
      expect(
        p.anatomicalTargetAvailable('core'),
        isFalse,
        reason: 'Remote public data cannot open this owned defender core',
      );
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'box uses only actual HP loss, exposes at zero once and survives JSON reload',
    (tester) async {
      final (state, p) = await _mount(tester);
      final initialBody = p.currentHp();
      await p.anatomicalTargetHit(
        _hit(p, 'shield-only', 'box'),
        hpLost: 0,
        critical: true,
      );
      expect(p.anatomicalTargetAvailable('core'), isFalse);
      await p.anatomicalTargetHit(
        _hit(p, 'first', 'box'),
        hpLost: 7,
        critical: true,
      );
      expect(p.anatomicalTargetAvailable('core'), isFalse);
      final box = (p.anatomicalPartsSnapshot()['parts'] as Map)['box'] as Map;
      expect(box['maximumHp'], 20);
      expect(box['damageTaken'], 7);
      expect(box['injured'], isFalse);
      await p.anatomicalTargetHit(
        _hit(p, 'second', 'box'),
        hpLost: 13,
        critical: false,
      );
      expect(p.anatomicalTargetAvailable('core'), isTrue);
      expect(
        p.currentHp(),
        initialBody,
        reason: 'The post-receipt anatomy seam cannot apply body damage twice',
      );
      final saved = p.snapshot();
      expect(
        (saved['faunaPublic'] as Map)['minorConstructCoreExposed'],
        isTrue,
      );
      p.load(saved);
      await p.anatomicalTargetHit(
        _hit(p, 'second', 'box'),
        hpLost: 13,
        critical: false,
      );
      expect(
        ((p.anatomicalPartsSnapshot()['parts'] as Map)['box']
            as Map)['damageTaken'],
        20,
      );
      expect(p.anatomicalTargetAvailable('core'), isTrue);
      p.repairAnatomicalParts('master_repair');
      expect(p.anatomicalTargetAvailable('core'), isFalse);
      expect(p.currentHp(), initialBody);
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'stale core packets cannot damage body, shields or core through an intact box',
    (tester) async {
      final (state, p) = await _mount(tester);
      state.scudoController.text = '50';
      final beforeCore = p.constructCoreHp;
      final packet = _hit(p, 'forged-core', 'core')
        ..addAll({
          'status': 'pending',
          'attack': 100000,
          'choice': 'precisione_punto_debole',
          'natural': 20,
          'dieFaces': 20,
          'damage': 1000,
          'element': 'fisico',
          'level': 0,
          'grade': 0,
          'effects': <Map<String, dynamic>>[],
        });
      state.onlineCombatRequests[packet['id']] = packet;
      await p.resolveCombatDefense(packet, 'cm', 20, natural: 10);
      expect(packet['referenceAnatomicalTargetUnavailable'], isTrue);
      expect(readIntValue((packet['damageReceipt'] as Map)['hpLost']), 0);
      expect(p.currentHp(), 200);
      expect(p.shieldTotal(), 50);
      expect(p.constructCoreHp, beforeCore);
      await p.damageConstructCore(1000);
      expect(
        p.constructCoreHp,
        beforeCore,
        reason: 'The ordinary direct damage entry point has the same guard',
      );
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'real box hit damages body once and a different campaign cannot expose it',
    (tester) async {
      final (state, p) = await _mount(tester);
      final foreign = _hit(p, 'foreign', 'box')..['scope'] = 'other-room';
      await p.anatomicalTargetHit(foreign, hpLost: 100, critical: false);
      expect(p.anatomicalPartsSnapshot()['parts'], isNull);
      final packet = _hit(p, 'real-box', 'box')
        ..addAll({
          'status': 'pending',
          'attack': 100000,
          'choice': 'precisione',
          'natural': 10,
          'dieFaces': 20,
          'damage': p.defense() + 40,
          'element': 'fisico',
          'level': 0,
          'grade': 0,
          'effects': <Map<String, dynamic>>[],
        });
      state.onlineCombatRequests[packet['id']] = packet;
      await p.resolveCombatDefense(packet, 'cm', 20, natural: 10);
      final lost = readIntValue((packet['damageReceipt'] as Map)['hpLost']);
      expect(lost, greaterThanOrEqualTo(20));
      expect(p.currentHp(), 200 - lost);
      expect(p.anatomicalTargetAvailable('core'), isTrue);
      expect(
        ((p.anatomicalPartsSnapshot()['parts'] as Map)['box']
            as Map)['damageTaken'],
        20,
      );
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'cloud phase two removes bottle from local and public targeting and stale attacks cannot restore it',
    (tester) async {
      final (state, p) = await _mount(tester);
      state.schedePersonaggio[state.schedaCorrente]['monsterBookSourceId'] =
          'nuvola_in_bottiglia';
      state.currentHpController.text = '50';
      expect(p.anatomicalTargetAvailable('bottle'), isTrue);
      final hit = _hit(p, 'bottle', 'bottle')
        ..['damageReceipt'] = {'hpLost': 1};
      p.bottledCloudPhase(hit, critical: true);
      expect(p.bottledCloudPhaseNumber(), 2);
      expect(p.anatomicalTargetAvailable('bottle'), isFalse);
      final public = p.snapshot()['precisionBodyParts'] as List;
      expect(
        public.whereType<Map>().any((part) => part['id'] == 'bottle'),
        isFalse,
      );
      final before = p.currentHp();
      final stale = _hit(p, 'old-bottle', 'bottle')
        ..addAll({
          'status': 'pending',
          'attack': 100000,
          'choice': 'precisione',
          'natural': 20,
          'dieFaces': 20,
          'damage': 1000,
          'element': 'fisico',
          'level': 0,
          'grade': 0,
          'effects': <Map<String, dynamic>>[],
        });
      state.onlineCombatRequests[stale['id']] = stale;
      await p.resolveCombatDefense(stale, 'cm', 20, natural: 10);
      expect(stale['referenceAnatomicalTargetUnavailable'], isTrue);
      expect(p.currentHp(), before);
      expect(p.bottledCloudPhaseNumber(), 2);
      final remote = <String, dynamic>{
        'id': 'ENEMY',
        'sheetTag': 'ENEMY',
        'monsterBookId': 'nuvola_in_bottiglia',
        'pagePurchased': true,
        'weakPointKnown': true,
        'faunaPublic': {'bottledCloudPhase': 2},
      };
      expect(
        p
            .anatomicalPartsForTarget(remote)
            .any((part) => part['id'] == 'bottle'),
        isFalse,
      );
      expect(p.anatomicalWeakPointAccessible(remote), isFalse);
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'Ultime forze does not erase the actual box damage or change the net reward receipt',
    (tester) async {
      final (state, p) = await _mount(tester);
      final runtime =
          state.schedePersonaggio[state.schedaCorrente]['planarRuntime'] as Map;
      (runtime['constructCore'] as Map)['used'] = false;
      ((runtime['anatomicalPartRules'] as Map)['box'] as Map)['maximumHp'] = 5;
      state.currentHpController.text = '10';
      final packet = _hit(p, 'last-strength-box', 'box')
        ..addAll({
          'status': 'pending',
          'attack': 100000,
          'choice': 'precisione',
          'natural': 10,
          'dieFaces': 20,
          'damage': p.defense() + 40,
          'element': 'fisico',
          'level': 0,
          'grade': 0,
          'effects': <Map<String, dynamic>>[],
        });
      state.onlineCombatRequests[packet['id']] = packet;
      await p.resolveCombatDefense(packet, 'cm', 20, natural: 10);
      expect(p.constructCore['used'], isTrue);
      expect(p.currentHp(), greaterThan(10));
      expect(
        readIntValue((packet['damageReceipt'] as Map)['hpLost']),
        0,
        reason: 'Keep the existing net-HP EXP/reward semantics unchanged',
      );
      expect(
        readIntValue((packet['structuralDamageReceipt'] as Map)['hpLost']),
        10,
      );
      expect(
        ((p.anatomicalPartsSnapshot()['parts'] as Map)['box']
            as Map)['damageTaken'],
        5,
      );
      expect(p.anatomicalTargetAvailable('core'), isTrue);
      final after = p.currentHp();
      await p.resolveCombatDefense(packet, 'cm', 20, natural: 10);
      expect(p.currentHp(), after);
      expect(
        ((p.anatomicalPartsSnapshot()['parts'] as Map)['box']
            as Map)['damageTaken'],
        5,
      );
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'structural receipts are once-only, campaign keyed, JSON stable and bounded',
    (tester) async {
      final (_, p) = await _mount(tester);
      p.recordStructuralDamage('fixed', 10, 0);
      p.recordStructuralDamage('fixed', 90, 0);
      var ledger = p.planarStateSnapshot()['structuralDamageReceipts'] as Map;
      expect((ledger.values.single as Map)['hpLost'], 10);
      final saved = p.snapshot();
      p.load(saved);
      p.recordStructuralDamage('fixed', 80, 0);
      ledger = p.planarStateSnapshot()['structuralDamageReceipts'] as Map;
      expect((ledger.values.single as Map)['hpLost'], 10);
      for (var i = 0; i < 140; i++) {
        p.recordStructuralDamage('packet-$i', 3, 1);
      }
      ledger = p.planarStateSnapshot()['structuralDamageReceipts'] as Map;
      expect(ledger, hasLength(128));
      expect(
        ledger.values.whereType<Map>().every(
          (r) => r['targetTag'] == p.ownerTag(),
        ),
        isTrue,
      );
      expect(
        ledger.values.whereType<Map>().every(
          (r) => r['scope'] == p.permissionScope,
        ),
        isTrue,
      );
      await closeFixture(tester, p);
    },
  );
}
