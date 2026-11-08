import 'package:flutter_test/flutter_test.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;
import 'oculum_protection_wear_test.dart' show prepareProtectionFixture;

void main() {
  testWidgets('Pietra che Ricorda heals each Life hit with the Open inactive', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    prepareProtectionFixture(state, probe);
    state.livelloController.text = '50';
    state.resilienzaController.text = '35';
    state.masterInitiativeActiveIndex = 0;
    probe.invalidateDerivedCaches();
    final runtime =
        state.schedePersonaggio[state.schedaCorrente]['planarRuntime'] as Map;
    runtime['stat35'] = {
      'choices20': {'resilienza': 'res_vital_wake'},
      'choices': {'resilienza': 'res_immunity'},
    };
    final before = probe.currentHp();
    await probe.useStatOpenResilience();
    await probe.damageResolved(12, bypassDefense: true, bypassShields: true);
    expect(probe.currentHp(), before);
    probe.addCondition('maledetto', stage: 3);
    await probe.damageResolved(9, bypassDefense: true, bypassShields: true);
    expect(probe.currentHp(), before);
    await closeFixture(tester, probe);
  });

  testWidgets('Cavalieri Rossi dispatch four distinct defenses from one roll', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    state.livelloController.text = '50';
    state.volontaController.text = '35';
    state.masterInitiativeActiveIndex = 0;
    final runtime =
        state.schedePersonaggio[state.schedaCorrente]['planarRuntime'] as Map;
    runtime['stat35'] = {
      'choices20': {'volonta': 'will_heavy_slam'},
      'choices': {'volonta': 'will_pressure'},
    };
    final damage = probe.damageTotal() * 35 ~/ 100;
    final action = probe.useStatOpenKnights('ENEMY');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Dichiara e tira'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await action;

    final requests = (state.onlineCombatRequests as Map).values
        .whereType<Map>()
        .where(
          (packet) => (packet['abilityName'] as String? ?? '').startsWith(
            'Cavalieri Rossi',
          ),
        )
        .toList();
    expect(requests, hasLength(4));
    expect(requests.map((packet) => packet['id']).toSet(), hasLength(4));
    expect(requests.map((packet) => packet['attack']).toSet(), hasLength(1));
    expect(
      requests.map((packet) => packet['attackGroupId']).toSet(),
      hasLength(1),
    );
    expect(requests.map((packet) => packet['damage']).toSet(), {damage});
    expect((runtime['stat35'] as Map)['cooldowns']['will_knights_50'], 4);
    await closeFixture(tester, probe);
  });

  testWidgets('Cavalieri Rossi redistribute strikes within one enemy', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    state.livelloController.text = '100';
    state.volontaController.text = '35';
    state.masterInitiativeActiveIndex = 0;
    final runtime =
        state.schedePersonaggio[state.schedaCorrente]['planarRuntime'] as Map;
    runtime['stat35'] = {
      'choices20': {'volonta': 'will_heavy_slam'},
      'choices': {'volonta': 'will_pressure'},
    };
    final action = probe.useStatOpenKnights('ENEMY', level: 100);
    Future<void> settleDialog() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
    }

    await settleDialog();
    await tester.tap(find.text('Dichiara e tira'));
    await settleDialog();
    await tester.tap(find.byTooltip('Rimuovi un colpo dal gruppo 1'));
    await tester.pump();
    await tester.tap(find.byTooltip('Aggiungi un colpo al gruppo 2'));
    await tester.pump();
    await tester.tap(find.text('Conferma gruppi'));
    await settleDialog();
    await action;

    final requests = (state.onlineCombatRequests as Map).values
        .whereType<Map>()
        .where((packet) => packet['statOpenId'] == 'will_knights_100')
        .toList();
    expect(requests.map((packet) => packet['statOpenGroupHits']), [1, 3, 2, 2]);
    expect(requests.map((packet) => packet['targetTag']).toSet(), {'ENEMY'});
    expect(requests.map((packet) => packet['attack']).toSet(), hasLength(1));
    expect((runtime['stat35'] as Map)['cooldowns']['will_knights_50'], 5);
    await closeFixture(tester, probe);
  });

  testWidgets('one defense resolves all strikes in the group once', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    prepareProtectionFixture(state, probe);
    final beforeHp = probe.currentHp();
    state.scudoController.text = '300';
    Future<Map<String, dynamic>> receiveGroup(String id, int hits) async {
      final request = <String, dynamic>{
        'id': id,
        'status': 'pending',
        'kind': 'attack',
        'scope': probe.permissionScope,
        'encounterId': probe.activeCombatEncounterId,
        'sourceTag': 'ENEMY',
        'targetTag': probe.ownerTag(),
        'attack': 100,
        'natural': 12,
        'damage': 20,
        'element': 'fisico',
        'level': 0,
        'grade': 0,
        'difficulty': 'normale',
        'statOpenId': 'will_knights_100',
        'statOpenGroupHits': hits,
      };
      state.onlineCombatRequests[id] = request;
      await probe.resolveCombatDefense(request, 'cm', 0, natural: 5);
      return request;
    }

    final beforeShield = probe.shieldTotal();
    final group = await receiveGroup('three-strikes', 3);
    final receipt = group['damageReceipt'] as Map;
    expect(receipt['landedStrikes'], 3);
    final shield = probe.shieldTotal();
    expect(shield, lessThan(beforeShield));
    expect(receipt['shieldLost'], beforeShield - shield);
    await probe.resolveCombatDefense(group, 'cm', 0, natural: 5);
    expect(probe.shieldTotal(), shield);
    expect(probe.currentHp(), beforeHp);
    await closeFixture(tester, probe);
  });

  testWidgets('an unselected local sheet advances its own Open effects', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    final owner = probe.ownerTag();
    final other = probe.snapshot()
      ..['id'] = 'OTHER'
      ..['sheetTag'] = 'OTHER'
      ..['oculum'] = '35'
      ..['currentOculum'] = '1'
      ..['planarRuntime'] = {
        'stat35': {
          'cooldowns': {'will_knights_50': 3, 'will_knights_100': 5},
          'opens': {
            'oculum_meridian_50': {
              'id': 'stat_open:oculum_meridian_50',
              'used': true,
              'buffActive': true,
              'skillEmpowered': true,
            },
          },
        },
      };
    state.schedePersonaggio.add(other);
    probe.ensureSheetTags();
    state.masterInitiativeTokens[2]['sheetTag'] = other['sheetTag'];

    probe.completeParticipantTurn(2);

    final saved = state.schedePersonaggio[1] as Map;
    final runtime = saved['planarRuntime'] as Map;
    expect(runtime['stat35']['cooldowns'], {'will_knights_50': 4});
    expect('${saved['currentOculum']}', '2');
    expect(probe.ownerTag(), owner);
    expect(state.schedaCorrente, 0);
    await closeFixture(tester, probe);
  });

  testWidgets('Meridiano uses real Oculum with its Open inactive', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    state.livelloController.text = '50';
    state.oculumController.text = '35';
    state.masterInitiativeActiveIndex = 0;
    probe.invalidateDerivedCaches();
    final runtime =
        state.schedePersonaggio[state.schedaCorrente]['planarRuntime'] as Map;
    runtime['stat35'] = {
      'choices20': {'oculum': 'oculum_sphere'},
      'choices': {'oculum': 'oculum_blast'},
    };
    const id = 'oculum_meridian_50';
    probe.setResourceCurrent('oculum', 5);
    await probe.useStatOpenAttack(id, 'ENEMY');
    expect(probe.visibleResourceCurrent('oculum'), 5);
    expect(find.text('Dichiara e tira'), findsNothing);

    probe.setResourceCurrent('oculum', 12);
    final damage = probe.damageTotal() + 3 * 50;
    final action = probe.useStatOpenAttack(id, 'ENEMY');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Dichiara e tira'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await action;

    final request = (state.onlineCombatRequests as Map).values
        .whereType<Map>()
        .singleWhere((request) => request['statOpenId'] == id);
    expect(request['damage'], damage);
    expect(probe.visibleResourceCurrent('oculum'), 6);
    expect((runtime['stat35'] as Map)['cooldowns'][id], 4);
    await closeFixture(tester, probe);
  });
}
