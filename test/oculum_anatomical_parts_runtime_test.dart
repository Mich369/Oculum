// Prepared integration checks. Promote this file to test/ only with the runtime
// patch and new part library. These are not a claim of completed verification.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  testWidgets('Ombra Ignota keeps prior wounds, repairs and receipts', (
    tester,
  ) async {
    final (state, p) = await fixtures.mountFight(tester);
    final sheet = state.schedePersonaggio[state.schedaCorrente] as Map;
    sheet['monsterBookSourceId'] = 'ombra_ignota';
    final priorHit = oculumAnatomicalAttackReceiptId(
      sourceTag: 'ENEMY',
      targetTag: p.ownerTag(),
      attackId: 'prior-eye-hit',
    );
    final legacy = <String, dynamic>{
      'eyes_1': {
        'maximumHp': 10,
        'damageTaken': 6,
        'injured': true,
        'rollPenalty': 1,
        'affectedRolls': ['attacco'],
      },
      'eyes_2': {
        'maximumHp': 20,
        'damageTaken': 10,
        'injured': true,
        'rollPenalty': 1,
        'affectedRolls': ['attacco'],
      },
    };
    final runtime = sheet['planarRuntime'] as Map;
    runtime['anatomicalParts'] = {
      'parts': legacy,
      'receipts': {priorHit: 'eyes_2'},
      'repairReceipts': {'previous-repair': 'eyes_1'},
    };
    runtime['anatomicalPartRules'] = {
      'eyes_2': {'maximumHp': 20},
    };
    p.invalidateDerivedCaches();

    final eye = p.anatomicalPartsForCurrentSheet().singleWhere(
      (part) => part['group'] == 'eyes',
    );
    expect(eye['id'], 'eyes');
    final projected = p.anatomicalPartsSnapshot();
    final active = projected['parts'] as Map;
    expect(active.keys, ['eyes']);
    expect(active['eyes']['damageTaken'], 6);
    expect(active['eyes']['maximumHp'], 10);
    expect(oculumAnatomicalPartRollPenalty(projected, 'attacco'), 1);
    expect((runtime['anatomicalParts'] as Map)['parts'], legacy);

    final request = <String, dynamic>{
      'id': 'prior-eye-hit',
      'sourceTag': 'ENEMY',
      'targetTag': p.ownerTag(),
      'targetBodyPart': 'eyes_2',
    };
    await p.anatomicalTargetHit(request, hpLost: 7, critical: false);
    expect(p.anatomicalPartsSnapshot(), projected);

    p.repairAnatomicalParts('master_repair');
    final snapshot =
        jsonDecode(jsonEncode(p.snapshot())) as Map<String, dynamic>;
    p.load(snapshot);
    final repaired = p.anatomicalPartsSnapshot();
    expect((repaired['parts'] as Map).keys, ['eyes']);
    expect((repaired['parts'] as Map)['eyes']['damageTaken'], 0);
    expect(oculumAnatomicalPartRollPenalty(repaired, 'attacco'), 0);
    expect(repaired['legacyOmbraEyeParts'], legacy);
    expect(repaired['receipts'], {priorHit: 'eyes_2'});
    expect((repaired['repairReceipts'] as Map)['previous-repair'], 'eyes_1');

    state.currentHpController.text = '300';
    state.scudoController.text = '0';
    state.scudoOculumController.text = '0';
    state.scudoCriticoController.text = '0';
    state.hpTempController.text = '0';
    p.invalidateDerivedCaches();
    final pending = <String, dynamic>{
      ...request,
      'id': 'unsettled-old-eye-hit',
      'status': 'pending',
      'sourceName': 'Avversario',
      'scope': p.permissionScope,
      'encounterId': 'encounter_1',
      'choice': 'precisione',
      'natural': 10,
      'dieFaces': 20,
      'attack': 100000,
      'damage': p.defense() + 4,
      'element': 'fisico',
      'level': 0,
      'grade': 0,
      'effects': <Map<String, dynamic>>[],
    };
    state.onlineCombatRequests[pending['id']] = pending;
    await p.resolveCombatDefense(pending, 'cm', 20, natural: 10);
    expect(pending['targetWeakPointPrecision'], isTrue);
    final hpLost = readIntValue((pending['damageReceipt'] as Map)['hpLost']);
    expect(hpLost, greaterThan(0));
    final hit = p.anatomicalPartsSnapshot();
    expect((hit['parts'] as Map).keys, ['eyes']);
    expect((hit['parts'] as Map)['eyes']['maximumHp'], 20);
    expect((hit['parts'] as Map)['eyes']['damageTaken'], hpLost.clamp(0, 20));
    expect(hit['legacyOmbraEyeParts'], legacy);
    await closeFixture(tester, p);
  });

  testWidgets('real defender receipt damages targeted part and body once', (
    tester,
  ) async {
    final (state, p) = await fixtures.mountFight(tester);
    state.schedePersonaggio[state.schedaCorrente]['monsterBookSourceId'] =
        'teschio_quattro_lame';
    state.livelloController.text = '3';
    state.gradoController.text = '0';
    state.resilienzaController.text = '30';
    state.currentResilienzaController.text = '30';
    state.currentHpController.text = '300';
    state.scudoController.text = '11';
    state.scudoOculumController.text = '0';
    state.scudoCriticoController.text = '0';
    state.hpTempController.text = '0';
    p.invalidateDerivedCaches();
    final before = p.currentHp();
    final request = <String, dynamic>{
      'id': 'real-targeted-hit',
      'status': 'pending',
      'sourceTag': 'ENEMY',
      'sourceName': 'Avversario',
      'targetTag': p.ownerTag(),
      'scope': p.permissionScope,
      'encounterId': 'encounter_1',
      'choice': 'precisione',
      'natural': 10,
      'dieFaces': 20,
      'attack': 100000,
      'damage': p.defense() + 40,
      'element': 'fisico',
      'level': 0,
      'grade': 0,
      'targetBodyPart': 'arms_1',
      'effects': <Map<String, dynamic>>[],
    };
    state.onlineCombatRequests[request['id']] = request;
    await p.resolveCombatDefense(request, 'cm', 20, natural: 10);
    final receipt = request['damageReceipt'] as Map;
    final hpLost = readIntValue(receipt['hpLost']);
    expect(hpLost, greaterThan(0));
    expect(readIntValue(receipt['shieldLost']), greaterThan(0));
    expect(p.currentHp(), before - hpLost);
    final parts = p.anatomicalPartsSnapshot()['parts'] as Map;
    expect(
      (parts['arms_1'] as Map)['damageTaken'],
      hpLost,
      reason: 'Use only the actual body-HP damage after Defense and Shields',
    );
    final settled = p.anatomicalPartsSnapshot();
    await p.resolveCombatDefense(request, 'cm', 20, natural: 10);
    expect(p.currentHp(), before - hpLost);
    expect(
      p.anatomicalPartsSnapshot(),
      settled,
      reason: 'A repeated online result must not apply either damage twice',
    );
    await closeFixture(tester, p);
  });

  testWidgets('Bramble walking roots are not bone fractures', (tester) async {
    final (state, p) = await fixtures.mountFight(tester);
    state.schedePersonaggio[state.schedaCorrente]['monsterBookSourceId'] =
        'bramble';
    state.scudoCriticoController.text = '0';
    p.invalidateDerivedCaches();
    final roots = p.anatomicalPartsForCurrentSheet().where(
      (p) => p['group'] == 'tendrils' && p['locomotor'] == true,
    );
    expect(roots, hasLength(4));
    expect(
      p.anatomicalPartsForCurrentSheet().where((p) => p['group'] == 'arms'),
      hasLength(2),
    );
    await p.anatomicalTargetHit(
      {
        'id': 'root-critical',
        'sourceTag': 'ENEMY',
        'targetBodyPart': roots.first['id'],
      },
      hpLost: 1,
      critical: true,
    );
    final part =
        (p.anatomicalPartsSnapshot()['parts'] as Map)[roots.first['id']] as Map;
    expect(part['material'], 'wood');
    expect(part['injuryLabel'], 'Fibre lacerate');
    expect(p.fracturePenalty('movimento'), 1);
    expect(p.fracturePenalty('forza'), 0);
    expect(
      (state.activeConditions as List).any(
        (dynamic condition) => condition.conditionType == 'frattura',
      ),
      false,
    );
    final wounded = p.anatomicalPartsSnapshot();
    p.repairAnatomicalParts('short_rest');
    expect(p.anatomicalPartsSnapshot(), wounded);
    p.repairAnatomicalParts('master_repair');
    expect(p.fracturePenalty('movimento'), 0);
    await closeFixture(tester, p);
  });

  testWidgets('A hit on one of Tacyantel’s six legs stays on that leg', (
    tester,
  ) async {
    final (state, p) = await fixtures.mountFight(tester);
    state.schedePersonaggio[state.schedaCorrente]['monsterBookSourceId'] =
        'habitat_sotterraneo_regina_delle_miniere_mute_variante_rituale';
    state.scudoCriticoController.text = '0';
    p.invalidateDerivedCaches();
    expect(
      p.anatomicalPartsForCurrentSheet().where((part) => part['group'] == 'legs'),
      hasLength(6),
    );
    await p.anatomicalTargetHit(
      {'id': 'leg-hit', 'sourceTag': 'ENEMY', 'targetBodyPart': 'legs_6'},
      hpLost: 1,
      critical: true,
    );
    final parts = p.anatomicalPartsSnapshot()['parts'] as Map;
    expect(parts.keys.where((id) => '$id'.startsWith('legs_')), ['legs_6']);
    await closeFixture(tester, p);
  });

  testWidgets('Pawn exposes two separate floating hands, never invented arms', (
    tester,
  ) async {
    final (state, p) = await fixtures.mountFight(tester);
    state.schedePersonaggio[state.schedaCorrente]['monsterBookSourceId'] =
        'pawn_guardiano';
    state.scudoCriticoController.text = '0';
    p.invalidateDerivedCaches();
    final anatomy = p.anatomicalPartsForCurrentSheet();
    expect(anatomy.where((part) => part['group'] == 'hands'), hasLength(2));
    expect(anatomy.where((part) => part['group'] == 'arms'), isEmpty);
    await p.anatomicalTargetHit(
      {'id': 'hand-hit', 'sourceTag': 'ENEMY', 'targetBodyPart': 'hands_1'},
      hpLost: 1,
      critical: true,
    );
    final hand =
        (p.anatomicalPartsSnapshot()['parts'] as Map)['hands_1'] as Map;
    expect(hand['injuryLabel'], 'Meccanismo danneggiato');
    expect(hand['legacyCriticalFracture'], false);
    await p.anatomicalTargetHit(
      {'id': 'native-core', 'sourceTag': 'ENEMY', 'targetBodyPart': 'core'},
      hpLost: 1000,
      critical: true,
    );
    expect(
      (p.anatomicalPartsSnapshot()['parts'] as Map).containsKey('core'),
      false,
    );
    await closeFixture(tester, p);
  });
}
