import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

Future<(dynamic, OculumPerformanceProbe)> _mount(WidgetTester tester) async {
  final (state, probe) = await fixtures.mountFight(tester);
  state.schedePersonaggio[state.schedaCorrente]['monsterBookSourceId'] =
      'guardiano_lunare';
  state.gradoController.text = '0';
  state.livelloController.text = '3';
  state.resilienzaController.text = '30';
  state.currentResilienzaController.text = '30';
  // This suite isolates proportional core damage, not the independent random
  // half-HP awakening that can add RES and immediately restore body HP.
  state.schedePersonaggio[state
          .schedaCorrente]['partialAwakeningHalfHpTriggered'] =
      true;
  state.arti.clear();
  state.inventario.clear();
  state.activeStructuredEffects.clear();
  state.scudoController.text = '0';
  state.scudoOculumController.text = '0';
  state.scudoOculumMaxController.text = '100';
  probe.invalidateDerivedCaches();
  state.currentHpController.text = '${probe.maximumHp()}';
  // Isolate the exact shield/core transfer from independent random passive
  // mitigation and the quarter-HP force-state lottery. Their own suites keep
  // exercising those mechanics; the expected 20 core / 60 body HP stays exact.
  for (final dynamic stat in state.hiddenEyeStats) {
    if (const {'fortuna', 'resistenza', 'riflessi'}.contains(stat.id)) {
      stat.unlocked = false;
    }
  }
  state.statoForzaAttivo = '';
  state.statoForzaPronto = false;
  return (state, probe);
}

void main() {
  test(
    'armor uses five plus three grade aimed hits, two criticals or one double',
    () {
      for (var grade = 0; grade <= 12; grade++) {
        final maximum = oculumLunarGuardianArmorMaximum(grade);
        expect(maximum, 2 * (5 + 3 * grade));
        expect(oculumLunarGuardianArmorHitDamage(maximum), 2);
        expect(
          oculumLunarGuardianArmorHitDamage(maximum, critical: true),
          maximum ~/ 2,
        );
        expect(
          oculumLunarGuardianArmorHitDamage(maximum, doubleCritical: true),
          maximum,
        );
      }
    },
  );
  test(
    'Book anatomy cannot expose a hidden core, while other creatures retain theirs',
    () {
      const original = [
        {'id': 'body'},
        {'id': 'torso'},
        {'id': 'core', 'weak': true},
      ];
      final hidden = oculumLunarGuardianCorePrecisionParts(
        original,
        monsterId: 'guardiano_lunare',
      );
      expect(hidden.map((p) => p['id']), containsAll(['armor', 'chest']));
      expect(hidden.any((p) => p['id'] == 'core'), false);
      final exposed = oculumLunarGuardianCorePrecisionParts(
        original,
        monsterId: 'guardian_devil_moon',
        coreExposed: true,
      );
      expect(exposed.where((p) => p['id'] == 'core'), hasLength(1));
      expect(
        oculumLunarGuardianCorePrecisionParts(
          original,
          monsterId: 'altro',
        ).map((p) => p['id']),
        ['body', 'torso', 'core'],
      );
    },
  );
  test(
    'grave chest threshold and elemental core defenses are coherent, Devil has no fragility',
    () {
      expect(oculumLunarGuardianGraveChestDamage(20), 5);
      expect(oculumLunarGuardianGraveChestDamage(101), 11);
      expect(oculumLunarGuardianCoreDamagePercent('Buio'), 50);
      expect(oculumLunarGuardianCoreDamagePercent('Luna'), 75);
      expect(oculumLunarGuardianCoreDamagePercent('Solare'), 125);
      for (final element in ['Buio', 'Luna', 'Solare', 'Fuoco', 'Fisico']) {
        expect(
          oculumLunarGuardianCoreDamagePercent(element, infernal: true),
          lessThanOrEqualTo(100),
        );
      }
    },
  );
  test(
    'core transfers percentages from its fixed exposure snapshot with cumulative rounding',
    () {
      final state = <String, dynamic>{
        'coreMaximum': 33,
        'coreHp': 33,
        'bodyHpAtExposure': 100,
        'damageTransferred': 0,
      };
      expect(oculumLunarGuardianTransferCoreDamage(state, 11, 100), 34);
      expect(oculumLunarGuardianTransferCoreDamage(state, 11, 66), 33);
      expect(oculumLunarGuardianTransferCoreDamage(state, 11, 33), 33);
      expect(state['coreHp'], 0);
      expect(state['damageTransferred'], 100);
      expect(oculumLunarGuardianTransferCoreDamage(state, 50, 0), 0);
    },
  );
  testWidgets(
    'shields block armor damage; the hit that emptied them counts and replay cannot double it',
    (tester) async {
      final (state, p) = await _mount(tester);
      final armor = p.lunarGuardianCoreState();
      final request = <String, dynamic>{'id': 'one', 'targetBodyPart': 'armor'};
      state.scudoController.text = '1';
      p.lunarGuardianCoreHit(request, hpLost: 0);
      expect(armor['armorIntegrity'], 10);
      state.scudoController.text = '0';
      state.scudoOculumController.text = '1';
      p.lunarGuardianCoreHit(request, hpLost: 0);
      expect(armor['armorIntegrity'], 10);
      state.scudoOculumController.text = '0';
      p.lunarGuardianCoreHit(request, hpLost: 0);
      expect(armor['armorIntegrity'], 8);
      p.lunarGuardianCoreHit(request, hpLost: 0);
      expect(armor['armorIntegrity'], 8);
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'a critical halves armor, a double destroys it, a later grave chest hit exposes fixed core HP',
    (tester) async {
      final (state, p) = await _mount(tester);
      final armor = p.lunarGuardianCoreState();
      p.lunarGuardianCoreHit({
        'id': 'crit',
        'targetBodyPart': 'armor',
      }, critical: true);
      expect(armor['armorIntegrity'], 5);
      p.lunarGuardianCoreHit(
        {'id': 'double', 'targetBodyPart': 'chest'},
        doubleCritical: true,
        hpLost: p.maximumHp(),
      );
      expect(armor['armorIntegrity'], 0);
      expect(
        armor['coreExposed'],
        false,
        reason: 'the armor-breaking hit is not the subsequent grave hit',
      );
      p.lunarGuardianCoreHit({
        'id': 'minor',
        'targetBodyPart': 'chest',
      }, hpLost: 1);
      expect(armor['coreExposed'], false);
      state.currentHpController.text = '90';
      p.lunarGuardianCoreHit({
        'id': 'grave',
        'targetBodyPart': 'chest',
      }, hpLost: p.maximumHp());
      expect(armor['coreExposed'], true);
      expect(armor['coreMaximum'], 30);
      expect(armor['coreHp'], 30);
      expect(armor['bodyHpAtExposure'], 90);
      state.gradoController.text = '1';
      expect(p.lunarGuardianCoreState()['armorMaximum'], 16);
      expect(p.lunarGuardianCoreState()['armorIntegrity'], 0);
      expect(p.lunarGuardianCoreState()['coreMaximum'], 30);
      final saved =
          jsonDecode(jsonEncode(p.snapshot())) as Map<String, dynamic>;
      p.load(saved);
      expect(p.lunarGuardianCoreState()['coreMaximum'], 30);
      expect(p.lunarGuardianCoreState()['coreHp'], 30);
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'a protective critical shield does not allow a double critical to destroy the armor',
    (tester) async {
      final (_, p) = await _mount(tester);
      p.lunarGuardianCoreHit({
        'id': 'protected',
        'targetBodyPart': 'armor',
        'criticalShieldProtected': true,
      }, doubleCritical: true);
      expect(p.lunarGuardianCoreState()['armorIntegrity'], 8);
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'final core damage is idempotent and destruction yields immediate lethal body damage',
    (tester) async {
      final (state, p) = await _mount(tester);
      final core = p.lunarGuardianCoreState()
        ..['armorIntegrity'] = 0
        ..['coreExposed'] = true
        ..['coreMaximum'] = 30
        ..['coreHp'] = 30
        ..['bodyHpAtExposure'] = 90
        ..['damageTransferred'] = 0;
      state.currentHpController.text = '90';
      expect(p.lunarGuardianCoreDamage(10, requestId: 'core-one'), 30);
      expect(core['coreHp'], 20);
      expect(p.lunarGuardianCoreDamage(10, requestId: 'core-one'), 0);
      state.currentHpController.text = '60';
      expect(p.lunarGuardianCoreDamage(20, requestId: 'core-two'), 60);
      expect(core['coreHp'], 0);
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'production incoming damage crosses both shields before damaging only the exposed core and its proportional body share',
    (tester) async {
      final (state, p) = await _mount(tester);
      final core = p.lunarGuardianCoreState()
        ..['armorIntegrity'] = 0
        ..['coreExposed'] = true
        ..['coreMaximum'] = 30
        ..['coreHp'] = 30
        ..['bodyHpAtExposure'] = 90
        ..['damageTransferred'] = 0;
      state.currentHpController.text = '90';
      state.scudoOculumController.text = '10';
      state.scudoController.text = '5';
      final request = <String, dynamic>{
        'id': 'core-real-engine',
        'kind': 'attack',
        'sourceTag': 'ENEMY',
        'targetTag': p.ownerTag(),
        'sourceName': 'Avversario',
        'targetName': 'Guardiano',
        'scope': p.permissionScope,
        'encounterId': 'encounter_1',
        'status': 'pending',
        'choice': 'precisione',
        'targetBodyPart': 'core',
        'attack': 20,
        'natural': 10,
        'damage': 25,
        'element': 'fisico',
        'difficulty': 'normale',
        'level': 0,
        'grade': 0,
        'effects': [
          {'type': 'danno', 'bypassDefense': true, 'valueExpression': '0'},
        ],
      };
      state.onlineCombatRequests[request['id']] = request;
      final resilienceBefore = state.resilienzaController.text;
      await p.resolveCombatDefense(request, 'difesa', 15);
      expect(
        state.resilienzaController.text,
        resilienceBefore,
        reason:
            'The core damage fixture must not trigger unrelated awakening healing.',
      );
      expect(p.shieldTotal(), 0);
      expect(state.scudoOculumController.text, '0');
      expect(core['coreHp'], 20);
      expect(p.currentHp(), 60);
      expect((request['damageReceipt'] as Map)['hpLost'], 30);
      await p.resolveCombatDefense(request, 'difesa', 15);
      expect(core['coreHp'], 20);
      expect(p.currentHp(), 60);
      await closeFixture(tester, p);
    },
  );
}
