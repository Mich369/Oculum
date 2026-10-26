import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/widgets/oculum_attack_planner.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

Future<(dynamic, OculumPerformanceProbe)> mountFight(
  WidgetTester tester,
) async {
  final dynamic state = await fixtures.mountSheet(
    tester,
    const Size(1440, 1000),
  );
  state.datiCaricati = false;
  final p = OculumPerformanceProbe(state);
  final sheet = p.snapshot()..['planarRuntime'] = <String, dynamic>{};
  sheet['id'] = sheet['sheetTag'] = 'HERO';
  state.schedePersonaggio
    ..clear()
    ..add(sheet);
  state.schedaCorrente = 0;
  p.load(sheet);
  state.modalitaMaster = true;
  state.masterInitiativeGroups.clear();
  state.masterInitiativeTokens
    ..clear()
    ..addAll([
      <String, dynamic>{
        'id': 'HERO',
        'sheetTag': 'HERO',
        'name': 'Eroe',
        'side': 'party',
        'status': 'active',
      },
      <String, dynamic>{
        'id': 'ENEMY',
        'sheetTag': 'ENEMY',
        'name': 'Provocatore',
        'side': 'enemy',
        'status': 'ready',
      },
      <String, dynamic>{
        'id': 'OTHER',
        'sheetTag': 'OTHER',
        'name': 'Altro nemico',
        'side': 'enemy',
        'status': 'ready',
      },
    ]);
  state.selectedMasterInitiativeGroupId = 'encounter_1';
  p.ensureEncounters();
  p.ensureSheetTags();
  state.masterInitiativeTokens.first['id'] = p.ownerTag();
  state.masterInitiativeTokens.first['sheetTag'] = p.ownerTag();
  p.recordCurrentEncounter();
  state.masterInitiativeGroups.first['fightStarted'] = true;
  return (state, p);
}

void main() {
  test(
    'escape ties, precise interception and HP-only experience follow confirmations',
    () {
      expect(oculumEscapeWins(30, 30, 10, 9), true);
      expect(oculumEscapeWins(30, 30, 10, 10), true);
      expect(oculumEscapeWins(30, 30, 9, 10), false);
      expect(oculumEscapePrecisionStops(23, 30), false);
      expect(oculumEscapePrecisionStops(24, 30), true);
      expect(oculumEscapeExperience(300, 3, 25, 20), 75);
      expect(oculumEscapeExperience(300, 3, 25, 90), 90);
      expect(oculumEscapeExperience(0, 0, 100, 0), 0);
      final tokens = oculumBoardAfterFight([
        {'id': 'a', 'side': 'party', 'status': 'fled', 'outsideFight': true},
        {'id': 'legacy', 'side': 'party', 'status': 'fled'},
        {'id': 'enemy', 'side': 'enemy', 'status': 'ready'},
      ]);
      expect(tokens.map((t) => t['id']), ['a']);
    },
  );

  test(
    'provoker catalogue has three editable forms and independent saved definitions',
    () {
      final skill = oculumProvokerShieldSkill();
      expect(
        oculumAbilityCatalogueEntries().where((e) => e.id == 'provoker_shield'),
        hasLength(1),
      );
      for (var form = 1; form <= 3; form++) {
        expect(skill.oculumMinimoPerLivello(form), [5, 10, 20][form - 1]);
        expect(skill.cooldownPerLivello[form - 1].amount, 3);
        expect(
          skill.effettiEvoluzione(form).every((e) => e.duration == '3'),
          true,
        );
      }
      final custom = ArtSkill.fromJson(skill.toJson());
      custom.effettiPerLivello[0][0].valueExpression = '99*livello';
      custom.effettiPerLivello[0][1].valueExpression = '83';
      expect(
        ArtSkill.fromJson(
          custom.toJson(),
        ).effettiPerLivello[0][0].valueExpression,
        '99*livello',
      );
      expect(
        oculumProvokerShieldSkill().effettiPerLivello[0][0].valueExpression,
        '30*livello',
      );
      expect(oculumProvokerReflection(20, 40, 50), 30);
      expect(oculumProvokerReflection(20, 40, 75), 45);
      expect(oculumProvokerReflection(20, 40, 100), 60);
    },
  );

  testWidgets(
    'outside turns refresh resources and replayed returns cannot add reactions',
    (tester) async {
      final (state, p) = await mountFight(tester);
      final token = <String, dynamic>{
        'outsideFight': true,
        'outsideFirstPending': true,
        'outsideCritical': true,
      };
      p.escapeTurn(token, 99);
      expect(token['outsideFast'], 3);
      expect(token['outsideNormal'], 0);
      p.escapeTurn(token, 49);
      expect(token['outsideFast'], 1);
      expect(token['outsideNormal'], 1);
      p.escapeTurn(token, 50);
      expect(token['outsideFast'], 0);
      expect(token['outsideNormal'], 2);
      state.masterInitiativeTokens.first['outsideFight'] = true;
      final event = <String, dynamic>{
        'id': 'return-1',
        'stage': 'return',
        'sourceTag': p.ownerTag(),
        'scope': p.permissionScope,
        'encounterId': 'encounter_1',
        'mode': 'riflessi',
      };
      p.escapeEvent(event);
      p.escapeEvent(event);
      expect(state.masterInitiativeTokens.first['extraFastReactionCurrent'], 1);
      p.escapeTurn(
        state.masterInitiativeTokens.first as Map<String, dynamic>,
        0,
      );
      expect(state.masterInitiativeTokens.first['extraFastReactionCurrent'], 2);
      expect(state.masterInitiativeTokens.first['escapeReturnFastTurns'], 0);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'stealth return compares passive perception once for each target',
    (tester) async {
      final (_, p) = await mountFight(tester);
      final request = <String, dynamic>{
        'attack': 20,
        'damage': 40,
        'escapeReturn': {'veil': 10000, 'total': 10020},
      };
      p.escapeReturnBonus(request);
      p.escapeReturnBonus(request);
      expect(request['attack'], 23);
      expect(request['damage'], 10040);
      final source = <String, dynamic>{
        'attack': 20,
        'escapeReturn': {'veil': 10000},
      };
      p.escapeReturnReply(source, request);
      p.escapeReturnReply(source, request);
      expect(source['attack'], 23);
      final seen = <String, dynamic>{
        'attack': 20,
        'damage': 40,
        'escapeReturn': {'veil': -10000, 'total': 10020},
      };
      p.escapeReturnBonus(seen);
      expect(seen['attack'], 20);
      expect(seen['damage'], 40);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'provoker absorbs only its own remaining shield and reflects once on break',
    (tester) async {
      final (state, p) = await mountFight(tester);
      state.livelloController.text = '2';
      final skill = oculumProvokerShieldSkill();
      final before = p.defense();
      p.applyEffects(skill.effettiEvoluzione(1), source: skill.nome);
      expect(p.planarStateSnapshot()['provokerShield'], 60);
      expect(p.defense(), before + 5);
      expect(p.provokerAbsorb(40, bypass: true), 40);
      expect(p.provokerAbsorb(40), 0);
      expect(p.planarStateSnapshot()['provokerShield'], 20);
      expect(p.planarStateSnapshot()['provokerPendingReflection'], isNull);
      final damage = p.damageTotal();
      expect(p.provokerAbsorb(25), 5);
      expect(
        p.planarStateSnapshot()['provokerPendingReflection'],
        oculumProvokerReflection(20, damage, 50),
      );
      final reflected = p.planarStateSnapshot()['provokerPendingReflection'];
      expect(p.provokerAbsorb(25), 25);
      expect(p.planarStateSnapshot()['provokerPendingReflection'], reflected);
      p.applyEffects(skill.effettiEvoluzione(1), source: skill.nome);
      p.tickPlanar();
      p.tickPlanar();
      p.tickPlanar();
      expect(p.provokerAbsorb(25), 25);
      expect(p.planarStateSnapshot()['provokerShield'], 0);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'taunt respects percentile boundary, original targets and expired shields',
    (tester) async {
      final (state, p) = await mountFight(tester);
      state.masterInitiativeTokens[1].addAll({
        'provokerChance': 60,
        'provokerShield': 100,
        'provokerTurns': 3,
      });
      const plan = OculumAttackPlan('OTHER', 'vc', '', additionalTargetIds: []);
      expect(p.provoke(plan, 59).targetId, 'ENEMY');
      expect(p.provoke(plan, 60).targetId, 'OTHER');
      state.masterInitiativeTokens[1]['provokerShield'] = 0;
      expect(p.provoke(plan, 0).targetId, 'OTHER');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'escape reward ledger counts real HP once and Role keeps all party members',
    (tester) async {
      final (state, p) = await mountFight(tester);
      final own = p.ownerTag();
      final dealt = <String, dynamic>{
        'id': 'hit-1',
        'sourceTag': own,
        'targetTag': 'ENEMY',
        'sourceHelpers': ['assistant'],
        'damageReceipt': {'hpLost': 300, 'shieldLost': 1000},
      };
      p.escapeDamage(dealt);
      p.escapeDamage(dealt);
      p.escapeDamage({
        'id': 'hit-2',
        'sourceTag': 'ENEMY',
        'targetTag': own,
        'damageReceipt': {'hpLost': 20},
      });
      expect((p.escapeLedger()['damage'] as Map).length, 2);
      expect(
        p.escapeExperience()[own],
        oculumEscapeExperience(300, 1, p.damageTotal(), 20),
      );
      final group = state.masterInitiativeGroups.first as Map<String, dynamic>;
      group['roleName'] = 'Rifugio';
      p.moveToRole(
        'encounter_1',
        state.masterInitiativeTokens.first as Map<String, dynamic>,
      );
      expect(state.masterInitiativeTokens.first['outsideFight'], true);
      expect((p.roleFolder(group) as ExpansionTile).title, isA<Text>());
      expect(((group['tokens'] as List).first as Map)['outsideFight'], true);
      p.recordCurrentEncounter();
      final saved = p.snapshot();
      p.load(saved);
      expect(state.masterInitiativeGroups.first['roleName'], 'Rifugio');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
