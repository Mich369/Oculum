import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  testWidgets('L’Ombra blocks physical damage before direct shield effects', (
    tester,
  ) async {
    final (state, probe) = await fixtures.mountFight(tester);
    final sheet = state.schedePersonaggio[state.schedaCorrente] as Map;
    sheet['monsterBookSourceId'] = 'ombra_ignota';
    final runtime = sheet['planarRuntime'] as Map;
    runtime['brambleShield'] = 20;
    runtime['brambleShieldTurns'] = 2;
    state.currentHpController.text = '300';
    state.scudoController.text = '12';
    state.scudoOculumController.text = '8';
    state.scudoCriticoController.text = '2';
    state.hpTempController.text = '4';
    state.incomingDamageElement = 'Fisico perforante';
    probe.invalidateDerivedCaches();
    final hp = probe.currentHp();
    probe.maskedPower('mask_shadow_form', 3);

    await probe.damageResolved(100, critical: true, bypassDefense: true);

    expect(probe.currentHp(), hp);
    expect(state.scudoController.text, '12');
    expect(state.scudoOculumController.text, '8');
    expect(state.scudoCriticoController.text, '2');
    expect(state.hpTempController.text, '4');
    expect(runtime['brambleShield'], 20);
    expect(probe.planarIncoming(30, element: 'taglio'), 0);
    expect(runtime['brambleShield'], 20);
    await closeFixture(tester, probe);
  });

  testWidgets('L’Ombra keeps the eye targetable by nonphysical attacks', (
    tester,
  ) async {
    final (state, probe) = await fixtures.mountFight(tester);
    final sheet = state.schedePersonaggio[state.schedaCorrente] as Map;
    sheet['monsterBookSourceId'] = 'ombra_ignota';
    (sheet['planarRuntime'] as Map)['anatomicalPartRules'] = {
      'eyes': {'maximumHp': 1000},
    };
    state.resilienzaController.text = '100';
    state.currentResilienzaController.text = '100';
    // Isolate targeted damage from the independent below-half-HP awakening
    // and the random passive mitigations of a normal character.
    sheet['partialAwakeningHalfHpTriggered'] = true;
    state.campaignDifficulty = 'normale';
    state.fortuna = 0;
    state.karmaController.text =
        '-${readIntValue(state.livelloController.text) ~/ 2}';
    state.oculumController.text = '0';
    state.currentOculumController.text = '0';
    for (final dynamic stat in state.hiddenEyeStats) {
      if (const {'resistenza', 'riflessi'}.contains(stat.id)) {
        stat.valore = -50;
      }
    }
    state.currentHpController.text = '300';
    state.scudoController.text = '12';
    state.scudoOculumController.text = '8';
    state.scudoCriticoController.text = '2';
    state.hpTempController.text = '4';
    probe.invalidateDerivedCaches();
    final hp = probe.currentHp();
    expect(hp, 300);
    expect(probe.subtraitValue('fortuna'), lessThanOrEqualTo(0));
    expect(probe.subtraitValue('resistenza'), lessThanOrEqualTo(0));
    final partsBefore = probe.anatomicalPartsSnapshot();

    Map<String, dynamic> attack(String id, String element) {
      final request = <String, dynamic>{
        'id': id,
        'scope': probe.permissionScope,
        'encounterId': 'encounter_1',
        'status': 'pending',
        'sourceTag': 'ENEMY',
        'sourceName': 'Avversario',
        'targetTag': probe.ownerTag(),
        'choice': 'precisione',
        'targetBodyPart': 'eyes',
        'natural': 10,
        'dieFaces': 20,
        'attack': 1000,
        'damage': probe.defense() + 30,
        'element': element,
        'difficulty': 'normale',
        'level': 0,
        'grade': 0,
      };
      state.onlineCombatRequests[id] = request;
      return request;
    }

    // The defender changes form after the physical attack was queued.
    final physical = attack('masked-physical', 'piercing')
      ..['granCannon'] = true
      ..['natural'] = 20;
    probe.maskedPower('mask_shadow_form', 3);
    await probe.resolveCombatDefense(physical, 'cm', 10, natural: 10);

    expect(physical['status'], 'resolved');
    expect(physical['outcome'], 'avoided');
    expect(physical['maskedShadowAvoided'], isTrue);
    expect(physical['granCriticalShieldBroken'], isNull);
    final receipt = physical['damageReceipt'] as Map;
    for (final key in [
      'shieldLost',
      'oculumShieldLost',
      'temporaryHpLost',
      'hpLost',
    ]) {
      expect(receipt[key], 0, reason: key);
    }
    expect(probe.currentHp(), hp);
    expect(state.scudoController.text, '12');
    expect(state.scudoOculumController.text, '8');
    expect(state.scudoCriticoController.text, '2');
    expect(state.hpTempController.text, '4');
    expect(probe.anatomicalPartsSnapshot(), partsBefore);
    await probe.resolveCombatDefense(physical, 'cm', 10, natural: 10);
    expect(probe.currentHp(), hp);

    state.scudoController.text = '0';
    state.scudoOculumController.text = '0';
    state.scudoCriticoController.text = '0';
    state.hpTempController.text = '0';
    probe.invalidateDerivedCaches();
    final target = Map<String, dynamic>.from(
      state.masterInitiativeTokens.first as Map,
    );
    final eye = probe
        .anatomicalPartsForTarget(target)
        .singleWhere((part) => part['group'] == 'eyes');
    expect(eye['id'], 'eyes');
    var eyeDamage = 0;
    for (final element in ['spirituale', 'fuoco']) {
      expect(probe.maskedShadow(), isTrue);
      state.currentHpController.text = '$hp';
      probe.invalidateDerivedCaches();
      final strike = attack('masked-$element', element)
        ..['targetBodyPart'] = eye['id'];
      await probe.resolveCombatDefense(strike, 'cm', 10, natural: 10);

      expect(strike['status'], 'resolved');
      expect(strike['outcome'], isNot('avoided'));
      expect(strike['maskedShadowAvoided'], isNull);
      expect(strike['targetWeakPointPrecision'], isTrue);
      final structural = strike['structuralDamageReceipt'] as Map;
      expect(structural['id'], strike['id']);
      final hpLost = readIntValue(structural['hpLost']);
      expect(hpLost, greaterThan(0), reason: element);
      expect((strike['damageReceipt'] as Map)['hpLost'], hpLost);
      eyeDamage += hpLost;
      final anatomy = probe.anatomicalPartsSnapshot();
      expect((anatomy['parts'] as Map)['eyes']['damageTaken'], eyeDamage);
      final strikeReceipt = oculumAnatomicalAttackReceiptId(
        sourceTag: 'ENEMY',
        targetTag: probe.ownerTag(),
        attackId: '${strike['id']}',
      );
      expect((anatomy['receipts'] as Map)[strikeReceipt], 'eyes');
    }

    // A physical attack queued during L’Ombra checks the form again at impact.
    state.currentHpController.text = '$hp';
    probe.invalidateDerivedCaches();
    final solid = attack('masked-solid', 'taglio');
    state.playerReportedTurn++;
    expect(probe.maskedShadow(), isFalse);
    await probe.resolveCombatDefense(solid, 'cm', 10, natural: 10);
    expect(solid['outcome'], isNot('avoided'));
    expect(solid['maskedShadowAvoided'], isNull);
    expect(
      (solid['damageReceipt'] as Map)['hpLost'],
      greaterThan(0),
      reason: '${solid['damageReceipt']}',
    );
    await closeFixture(tester, probe);
  });

  testWidgets('Fight accepts the owner’s shadow receipt for physical damage', (
    tester,
  ) async {
    final (state, probe) = await fixtures.mountFight(tester);
    state.realtimeUsers = <Map<String, dynamic>>[
      {
        'sessionId': 'enemy-session',
        'activeSheetTag': 'ENEMY',
        'role': 'player',
      },
    ];

    for (final (element, outcome) in [
      ('fisico', 'avoided'),
      ('spirituale', 'full'),
    ]) {
      final id = 'shadow-receipt-$element';
      final request = <String, dynamic>{
        'id': id,
        'scope': probe.permissionScope,
        'encounterId': 'encounter_1',
        'sourceTag': probe.ownerTag(),
        'targetTag': 'ENEMY',
        'sourceName': 'Eroe',
        'targetName': 'Ombra',
        'status': 'pending',
        'choice': 'precisione',
        'attack': 60,
        'damage': 10,
        'natural': 10,
        'element': element,
        'difficulty': 'normale',
      };
      state.onlineCombatRequests[id] = request;
      probe.receiveCombat('combat_defense', {
        ...request,
        'campaignId': probe.permissionCampaignId,
        'senderTag': 'ENEMY',
        'senderRole': 'player',
        'sessionId': 'enemy-session',
        'defense': 10,
        'defenseChoice': 'cm',
        'maskedShadowAvoided': true,
      });

      expect(request['status'], 'resolved');
      expect(request['outcome'], outcome);
    }
    await closeFixture(tester, probe);
  });
}
