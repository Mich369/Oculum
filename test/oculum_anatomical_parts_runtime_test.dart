// Prepared integration checks. Promote this file to test/ only with the runtime
// patch and new part library. These are not a claim of completed verification.
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
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
