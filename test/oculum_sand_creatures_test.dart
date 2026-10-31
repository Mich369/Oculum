import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_attack_planner.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

Future<(dynamic, OculumPerformanceProbe)> _mount(
  WidgetTester tester, {
  String species = 'gigante_sabbia',
}) async {
  final (state, p) = await fixtures.mountFight(tester);
  state.schedePersonaggio[state.schedaCorrente]['monsterBookSourceId'] =
      species;
  // Isolate sand survival from the independent random awakening at half HP.
  state.schedePersonaggio[state
          .schedaCorrente]['partialAwakeningHalfHpTriggered'] =
      true;
  state.livelloController.text = '0';
  state.gradoController.text = '0';
  state.resilienzaController.text = '30';
  state.currentResilienzaController.text = '30';
  state.materiaController.text = '20';
  state.currentMateriaController.text = '20';
  state.oculumController.text = '0';
  state.currentOculumController.text = '0';
  state.incomingDamageElement = 'lava';
  state.arti.clear();
  state.skills.clear();
  state.titoli.clear();
  state.trattiRazziali.clear();
  state.inventario.clear();
  state.activeStructuredEffects.clear();
  state.activeConditions.clear();
  state.scudoController.text = '0';
  state.scudoOculumMaxController.text = '10000';
  state.scudoOculumController.text = '0';
  state.scudoCriticoController.text = '0';
  p.invalidateDerivedCaches();
  expect(p.maximumHp(), 180); // 30 RES ×6 at level zero, no overflow power.
  state.currentHpController.text = '${p.maximumHp()}';
  // The independent quarter-HP force-state lottery can restore HP even after
  // this hit. Keep it already spent so sand damage and kill credit are exact.
  state.statoForzaAttivo = '';
  state.statoForzaPronto = false;
  state.masterInitiativeActiveIndex = 1; // The enemy's turn.
  final token = state.masterInitiativeTokens.first as Map;
  token['actionUsed'] = true;
  token['reactionPoints'] = 0;
  token['fastReactionPoints'] = 0;
  token.addAll(<String, dynamic>{
    'actionTurnRound': state.masterInitiativeRound,
    'reactionPoolInitialized': true,
    'reactionPoolRound': state.masterInitiativeRound,
    'reactionNormalFirstRoundLocked': false,
    'reactionMax': 1,
    'reactionUsed': 1,
    'reactionUsedRound': state.masterInitiativeRound,
    'reactionFastMax': 1,
    'reactionFastUsed': 1,
  });
  p.recordCurrentEncounter();
  p.invalidateDerivedCaches();
  return (state, p);
}

Future<void> _pumpDialog(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _lava(
  OculumPerformanceProbe p, {
  required String id,
  int roll = 99,
  bool doubleCritical = true,
  bool shieldAlreadyBroken = false,
  int damage = 5,
}) => p.damageResolved(
  damage,
  critical: true,
  doubleCritical: doubleCritical,
  packetId: id,
  sandLavaPercentile: roll,
  criticalShieldAlreadyBroken: shieldAlreadyBroken,
  bypassDefense: true,
  resolvedResistance: true,
);

Map<String, dynamic> _incoming(
  OculumPerformanceProbe p,
  String id, {
  int damage = 100,
  int attack = 1,
  int natural = 1,
  String element = 'fisico',
}) => {
  'id': id,
  'scope': p.permissionScope,
  'encounterId': 'encounter_1',
  'status': 'pending',
  'sourceTag': 'ENEMY',
  'sourceName': 'Avversario',
  'targetTag': p.ownerTag(),
  'attack': attack,
  'damage': damage,
  'natural': natural,
  'choice': 'vc',
  'level': 0,
  'grade': 0,
  'element': element,
  'difficulty': 'normale',
};

void main() {
  test('sand species share tail techniques and keep different weak points', () {
    final beast = monsterById('mostro_sabbia')!;
    final giant = monsterById('gigante_sabbia')!;
    for (final entry in [beast, giant]) {
      expect(
        entry.skillIds,
        containsAll(['sand_tail_attack', 'sand_tail_parry']),
      );
      expect(monsterBookUsableSkillIds(entry).length, greaterThanOrEqualTo(16));
      expect(entry.spriteAssetPath, isEmpty);
      expect(entry.imageBase64, isEmpty);
    }
    expect(beast.weakPointIt, contains('nucleo'));
    expect(giant.weakPointIt, contains('Nessun punto debole anatomico'));
    expect(giant.incomingDamageResistancePresets['fuoco'], 'Fragilità');
    expect(giant.descIt, contains('petto è pieno'));
    final custom = CharacterArt.fromJson(
      jsonDecode(jsonEncode(oculumMonsterBookArt(giant).toJson())),
    );
    final parry = custom.skills.firstWhere(
      (s) => s.nome == 'Riparo della coda',
    );
    parry.effettiPerLivello[0].single.valueExpression = '72';
    parry.effettiPerLivello[0].single.duration = '4';
    final restored = CharacterArt.fromJson(
      custom.toJson(),
    ).skills.firstWhere((s) => s.nome == 'Riparo della coda');
    expect(restored.effettiEvoluzione(1).single.valueExpression, '72');
    expect(restored.effettiEvoluzione(1).single.duration, '4');
  });

  test('tail rounding and 50% boundaries are exact', () {
    expect(oculumSandTailReceivedDamage(100, 65), 65);
    expect(oculumSandTailReceivedDamage(1, 65), 1);
    expect(oculumSandTailReceivedDamage(0, 65), 0);
    expect(oculumSandVitrificationSucceeds(0, 50), true);
    expect(oculumSandVitrificationSucceeds(49, 50), true);
    expect(oculumSandVitrificationSucceeds(50, 50), false);
    expect(oculumSandVitrificationSucceeds(99, 50), false);
  });

  for (final species in ['mostro_sabbia', 'gigante_sabbia']) {
    testWidgets(
      'exhaustion blocks prepared and new free tail skills for $species',
      (tester) async {
        final (state, p) = await _mount(tester, species: species);
        expect(p.prepareSandTail('parry'), true);
        state.scudoController.text = '200';
        p.totalPowerBurst(80, 1);
        expect(p.exhausted(), true);
        expect(p.sandTailReady, false);
        expect(p.prepareSandTail('attack'), false);
        expect(p.prepareSandTail('parry'), false);
        final request = _incoming(p, 'tail-exhausted-$species');
        state.onlineCombatRequests[request['id']] = request;
        final hpBefore = p.currentHp();
        await tester.runAsync(() => p.defendCombat(request, 'coda_sabbia'));
        expect(request['status'], 'pending');
        expect(state.scudoController.text, '200');
        expect(p.currentHp(), hpBefore);
        await closeFixture(tester, p);
      },
    );
  }

  testWidgets(
    'actual tail attack outside turn spends no A/R/RV and shared charge recovers in two personal turns',
    (tester) async {
      final (state, p) = await _mount(tester);
      final token = state.masterInitiativeTokens.first as Map;
      final before = [
        token['actionUsed'],
        token['reactionPoints'],
        token['fastReactionPoints'],
      ];
      final turn = state.playerReportedTurn as int;
      final active = state.masterInitiativeActiveIndex;
      expect(p.combatTurnResources(), {
        'actions': 0,
        'reactions': 0,
        'fast': 0,
      });
      expect(p.prepareSandTail('attack'), true);
      final attack = p.planAttack(total: 20, natural: 10);
      await _pumpDialog(tester);
      final planner = find.byType(OculumAttackPlanner);
      expect(planner, findsOneWidget);
      Navigator.of(
        tester.element(planner),
      ).pop(const OculumAttackPlan('ENEMY', 'vc', 'Coda', element: 'terra'));
      await _pumpDialog(tester);
      await attack;
      expect(
        state.onlineCombatRequests.values.where(
          (r) => r['sandTailAttack'] == true,
        ),
        hasLength(1),
      );
      expect([
        token['actionUsed'],
        token['reactionPoints'],
        token['fastReactionPoints'],
      ], before);
      expect(state.masterInitiativeActiveIndex, active);
      expect(state.playerReportedTurn, turn);
      expect(p.combatTurnResources(), {
        'actions': 0,
        'reactions': 0,
        'fast': 0,
      });
      expect(p.prepareSandTail('parry'), false);
      p.reportedTurn(turn + 1);
      expect(p.sandTailReady, false);
      p.reportedTurn(turn + 2);
      expect(p.sandTailReady, true);
      expect(p.prepareSandTail('parry'), true);
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'tail intercepts only an already valid escape window with d16 and no remaining A R or RV',
    (tester) async {
      final (state, p) = await _mount(tester);
      final record = <String, dynamic>{
        'id': 'sand-escape',
        'kind': 'escape',
        'status': 'pending',
        'scope': p.permissionScope,
        'encounterId': 'encounter_1',
        'sourceTag': 'ENEMY',
        'targetTag': 'ENEMY',
        'sourceName': 'Fuggitivo',
        'sourceSide': 'enemy',
        'noticed': <String, dynamic>{p.ownerTag(): true},
        'answers': <String, dynamic>{},
        'movement': 3,
        'total': 20,
        'lastAggressor': 'OTHER',
      };
      state.onlineCombatRequests[record['id']] = record;
      expect(p.combatTurnResources(), {
        'actions': 0,
        'reactions': 0,
        'fast': 0,
      });
      expect(p.prepareSandTail('attack'), true);
      await p.answerEscape(record, 'attack'); // Not the last aggressor.
      expect(find.byType(OculumAttackPlanner), findsNothing);
      expect(p.sandTailReady, true);
      expect((record['answers'] as Map), isEmpty);
      record['lastAggressor'] = p.ownerTag();
      record['noticed'] = <String, dynamic>{p.ownerTag(): false};
      await p.answerEscape(record, 'attack'); // Did not perceive the escape.
      expect(p.sandTailReady, true);
      expect(find.byType(OculumAttackPlanner), findsNothing);
      record['noticed'] = <String, dynamic>{p.ownerTag(): true};
      state.ispirazioneOculumCriticoInAttesa = true;
      final turn = state.playerReportedTurn;
      final opening = p.answerEscape(record, 'attack');
      await _pumpDialog(tester);
      final planner = find.byType(OculumAttackPlanner);
      expect(planner, findsOneWidget);
      Navigator.of(
        tester.element(planner),
      ).pop(const OculumAttackPlan('ENEMY', 'vc', 'Coda contro Fuga'));
      await opening;
      await tester.pump();
      final packet = (state.onlineCombatRequests as Map).values
          .whereType<Map>()
          .singleWhere((r) => r['escapeReactionOf'] == record['id']);
      expect(packet['sandTailAttack'], true);
      expect(packet['dieFaces'], 16);
      expect(packet['natural'], isIn([1, 16]));
      expect('${packet['sandTailClaim']}', isNotEmpty);
      expect(p.sandTailReady, false);
      expect(p.prepareSandTail('parry'), false);
      expect(p.combatTurnResources(), {
        'actions': 0,
        'reactions': 0,
        'fast': 0,
      });
      expect(state.masterInitiativeActiveIndex, 1);
      expect(state.playerReportedTurn, turn);
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'cancelled attack does not consume tail and choosing parry replaces attack preparation',
    (tester) async {
      final (_, p) = await _mount(tester);
      expect(p.prepareSandTail('attack'), true);
      final attack = p.planAttack(total: 20, natural: 10);
      await _pumpDialog(tester);
      Navigator.of(tester.element(find.byType(OculumAttackPlanner))).pop();
      await _pumpDialog(tester);
      await attack;
      expect(p.sandTailReady, true);
      expect(p.prepareSandTail('parry'), true);
      expect((p.sandRuntime()['sandTail'] as Map)['mode'], 'parry');
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'real combat bar classifies tail as attack and its click opens the actual target planner',
    (tester) async {
      final (state, p) = await _mount(tester);
      final art = oculumMonsterBookArt(monsterById('gigante_sabbia')!)
        ..hasIntegrity = false;
      state.arti.add(art);
      final skill = art.skills.firstWhere(
        (s) => s.nome == 'Sferzata della coda',
      );
      expect(oculumCombatAbilityRoles(skill.effettiEvoluzione(1)), {
        OculumCombatAbilityRole.attack,
      });
      final opening = p.openCombatActionPanel(OculumCombatAbilityRole.attack);
      await _pumpDialog(tester);
      final entry = find.textContaining('Sferzata della coda ·');
      expect(entry, findsOneWidget);
      await tester.ensureVisible(entry);
      await tester.tap(entry);
      await _pumpDialog(tester);
      expect(find.byType(SimpleDialogOption), findsWidgets);
      await tester.tap(find.byType(SimpleDialogOption).first);
      await _pumpDialog(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Conferma').last);
      await _pumpDialog(tester);
      expect(find.byType(OculumAttackPlanner), findsOneWidget);
      Navigator.of(tester.element(find.byType(OculumAttackPlanner))).pop();
      await _pumpDialog(tester);
      await opening;
      expect(p.sandTailReady, true);
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'no-roll tail parry takes 65% after Defense before shields without unrelated random mitigation',
    (tester) async {
      final (state, p) = await _mount(tester, species: 'mostro_sabbia');
      // The independently rolled Luck/Resistance reduction can remove more
      // damage before shields. Cancel only those derived passives for this
      // exact layer-order assertion; their production behavior is unchanged.
      for (final id in ['fortuna', 'resistenza']) {
        final dynamic stat = (state.hiddenEyeStats as List).singleWhere(
          (dynamic entry) => entry.id == id,
        );
        stat.valore = (stat.valore as int) - p.subtraitValue(id);
        stat.unlocked = true;
      }
      p.invalidateDerivedCaches();
      expect(p.subtraitValue('fortuna'), 0);
      expect(p.subtraitValue('resistenza'), 0);
      state.scudoController.text = '200';
      final beforeHp = p.currentHp();
      final defense = p.defenseTotal();
      // A penalized attack below the passive reference must still land:
      // the no-roll tail parry mitigates damage rather than avoiding the hit.
      final request = _incoming(p, 'tail-packet', attack: -1);
      state.onlineCombatRequests[request['id']] = request;
      final turn = state.playerReportedTurn;
      final token = state.masterInitiativeTokens.first as Map;
      final resources = [
        token['actionUsed'],
        token['reactionPoints'],
        token['fastReactionPoints'],
      ];
      await tester.runAsync(() => p.defendCombat(request, 'coda_sabbia'));
      expect(request['status'], 'resolved');
      expect(request['defenseChoice'], 'coda_sabbia');
      expect(request['defenseNatural'], 0);
      expect(request['defense'], greaterThan(request['attack'] as int));
      expect(request['freeReaction'], false);
      final expected = oculumSandTailReceivedDamage(
        (100 - defense).clamp(1, 100).toInt(),
        65,
      );
      expect(p.currentHp(), beforeHp);
      expect(int.parse(state.scudoController.text as String), 200 - expected);
      expect(state.playerReportedTurn, turn);
      expect([
        token['actionUsed'],
        token['reactionPoints'],
        token['fastReactionPoints'],
      ], resources);
      final shield = state.scudoController.text;
      await tester.runAsync(() => p.defendCombat(request, 'coda_sabbia'));
      expect(state.scudoController.text, shield);
      expect(p.prepareSandTail('attack'), false);
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'tail percentage precedes even critical shield rounding: three damage becomes one',
    (tester) async {
      final (state, p) = await _mount(tester, species: 'mostro_sabbia');
      state.scudoCriticoController.text = '1';
      state.incomingDamageElement = 'fisico';
      state.fortuna = 0;
      expect(p.prepareSandTail('parry'), true);
      final hp = p.currentHp();
      await tester.runAsync(() => p.damageResolved(3, bypassDefense: true));
      expect(
        p.currentHp(),
        hp - 1,
      ); // ceil(ceil(3*.65)/2), not ceil(ceil(3/2)*.65).
      expect(p.sandTailReady, false);
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'Lava survivor halves effective Materia only and refreshes three personal turns without stacking',
    (tester) async {
      final (state, p) = await _mount(tester);
      final base = p.coreStats()['materia']!;
      final turn = state.playerReportedTurn as int;
      await tester.runAsync(() => _lava(p, id: 'lava-one'));
      expect(p.coreStats()['materia'], base ~/ 2);
      expect(p.resourceCurrent('materia'), 20);
      p.reportedTurn(turn + 2);
      await tester.runAsync(() => _lava(p, id: 'lava-two'));
      expect(p.coreStats()['materia'], base ~/ 2);
      p.reportedTurn(turn + 3);
      expect(p.coreStats()['materia'], base ~/ 2);
      p.reportedTurn(turn + 5);
      expect(p.coreStats()['materia'], base);
      expect(p.resourceCurrent('materia'), 20);
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'successful Lava roll kills via normal HP, persists its receipt and cannot replay damage after reload',
    (tester) async {
      final (state, p) = await _mount(tester);
      await tester.runAsync(() => _lava(p, id: 'lava-kill', roll: 49));
      expect(p.currentHp(), 0);
      expect(p.coreStats()['materia'], 20);
      expect(
        (p.sandRuntime()['sandLavaReceipts'] as Map)['lava-kill']['vitrified'],
        true,
      );
      final saved =
          jsonDecode(jsonEncode(p.snapshot())) as Map<String, dynamic>;
      p.load(saved);
      state.currentHpController.text =
          '80'; // A subsequent heal must survive ACK replay.
      await tester.runAsync(() => _lava(p, id: 'lava-kill', roll: 99));
      expect(p.currentHp(), 80);
      expect(p.coreStats()['materia'], 20);
      expect(
        (p.sandRuntime()['sandLavaReceipts'] as Map)['lava-kill']['roll'],
        49,
      );
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'safeHP saves the Lava victim and applies the survivor penalty only once',
    (tester) async {
      final (state, p) = await _mount(tester);
      state.buffMalusRapidiController.text = '@safehp';
      p.invalidateDerivedCaches();
      await tester.runAsync(() => _lava(p, id: 'lava-safe', roll: 0));
      expect(p.currentHp(), 1);
      expect(p.coreStats()['materia'], 10);
      expect(state.buffMalusRapidiController.text, isNot(contains('@safehp')));
      final receipt =
          (p.sandRuntime()['sandLavaReceipts'] as Map)['lava-safe'] as Map;
      expect(receipt['vitrified'], true);
      expect(receipt['survived'], true);
      expect(receipt['settled'], true);
      state.currentHpController.text = '80';
      await tester.runAsync(() => _lava(p, id: 'lava-safe', roll: 99));
      expect(p.currentHp(), 80);
      expect(p.coreStats()['materia'], 10);
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'failed Lava roll is persisted through JSON, without damage or RNG reroll on the same packet',
    (tester) async {
      final (_, p) = await _mount(tester);
      await tester.runAsync(() => _lava(p, id: 'lava-survived', roll: 50));
      final hp = p.currentHp();
      expect(hp, greaterThan(0));
      p.load(jsonDecode(jsonEncode(p.snapshot())) as Map<String, dynamic>);
      await tester.runAsync(() => _lava(p, id: 'lava-survived', roll: 0));
      expect(p.currentHp(), hp);
      expect(
        (p.sandRuntime()['sandLavaReceipts'] as Map)['lava-survived']['roll'],
        50,
      );
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'critical shield and a shield charge already broken by that hit both block special Lava effects',
    (tester) async {
      final (state, p) = await _mount(tester);
      state.scudoCriticoController.text = '1';
      await tester.runAsync(() => _lava(p, id: 'lava-protected', roll: 0));
      expect(p.currentHp(), greaterThan(0));
      expect(p.coreStats()['materia'], 20);
      state.scudoCriticoController.text = '0';
      await tester.runAsync(
        () => _lava(
          p,
          id: 'lava-shield-broken',
          roll: 0,
          shieldAlreadyBroken: true,
        ),
      );
      expect(p.currentHp(), greaterThan(0));
      expect(p.coreStats()['materia'], 20);
      final receipts = p.sandRuntime()['sandLavaReceipts'] as Map;
      expect(receipts['lava-protected']['eligible'], false);
      expect(receipts['lava-shield-broken']['eligible'], false);
      expect(receipts['lava-shield-broken']['roll'], isNull);
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'shield-only hit, ordinary critical, other element and already dead giant do not trigger Lava state',
    (tester) async {
      final (state, p) = await _mount(tester);
      state.scudoOculumController.text = '10000';
      final hp = p.currentHp();
      expect(hp, 180);
      await tester.runAsync(() => _lava(p, id: 'lava-no-hp', roll: 0));
      expect(p.currentHp(), hp);
      expect(p.coreStats()['materia'], 20);
      state.scudoOculumController.text = '0';
      await tester.runAsync(
        () => _lava(p, id: 'ordinary-critical', doubleCritical: false, roll: 0),
      );
      expect(p.currentHp(), greaterThan(0));
      state.incomingDamageElement = 'fuoco';
      await tester.runAsync(() => _lava(p, id: 'not-lava', roll: 0));
      expect(p.currentHp(), greaterThan(0));
      expect(p.coreStats()['materia'], 20);
      state.incomingDamageElement = 'lava';
      state.currentHpController.text = '0';
      await tester.runAsync(() => _lava(p, id: 'already-dead', roll: 0));
      expect(
        (p.sandRuntime()['sandLavaReceipts'] as Map)['already-dead']['roll'],
        isNull,
      );
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'the original sand beast and other species never receive giant Lava execution or Materia loss',
    (tester) async {
      final (state, p) = await _mount(tester, species: 'mostro_sabbia');
      await tester.runAsync(() => _lava(p, id: 'beast-lava', roll: 0));
      expect(p.currentHp(), greaterThan(0));
      expect(p.coreStats()['materia'], 20);
      state.schedePersonaggio[state.schedaCorrente]['monsterBookSourceId'] =
          'pawn';
      expect(p.prepareSandTail('attack'), false);
      await tester.runAsync(() => _lava(p, id: 'pawn-lava', roll: 0));
      expect(p.currentHp(), greaterThan(0));
      expect(p.coreStats()['materia'], 20);
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'owner defense forwards double critical Lava, uses passive Resistance and retains killer credit',
    (tester) async {
      final (state, p) = await _mount(tester);
      p.sandRuntime();
      state.schedePersonaggio[state
          .schedaCorrente]['planarRuntime']['sandRules'] = {
        'lavaKillPercent': 100,
      };
      final request = _incoming(
        p,
        'owner-lava',
        damage: 5,
        attack: 10000,
        natural: 20,
        element: 'lava',
      );
      final beforeHp = p.currentHp();
      expect(beforeHp, 180);
      state.onlineCombatRequests[request['id']] = request;
      await tester.runAsync(() => p.defendCombat(request, 'coda_sabbia'));
      expect(request['status'], 'resolved');
      expect(request['doubleCritical'], true);
      expect(request['defenseNatural'], 0);
      expect(request['defense'], p.subtraitValue('resistenza'));
      expect(p.currentHp(), 0);
      expect((request['damageReceipt'] as Map)['hpLost'], beforeHp);
      expect(
        state.schedePersonaggio[state.schedaCorrente]['lastDamageSourceTag'],
        'ENEMY',
      );
      expect(
        (p.sandRuntime()['sandLavaReceipts'] as Map)['owner-lava']['vitrified'],
        true,
      );
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'custom percentage, personal cooldown and Lava duration survive JSON and fight reset restores Materia',
    (tester) async {
      final (state, p) = await _mount(tester);
      p.sandRuntime();
      state.schedePersonaggio[state
          .schedaCorrente]['planarRuntime']['sandRules'] = {
        'lavaKillPercent': 0,
        'matterDurationTurns': 4,
        'matterDivisor': 4,
      };
      expect(p.prepareSandTail('parry', percent: 80, cooldown: 4), true);
      p.load(jsonDecode(jsonEncode(p.snapshot())) as Map<String, dynamic>);
      expect((p.sandRuntime()['sandTail'] as Map)['receivedDamagePercent'], 80);
      expect((p.sandRuntime()['sandTail'] as Map)['cooldownPersonalTurns'], 4);
      await tester.runAsync(() => _lava(p, id: 'custom-lava', roll: 0));
      expect(p.coreStats()['materia'], 5);
      expect(p.resourceCurrent('materia'), 20);
      p.finishPlanarFight();
      expect(p.coreStats()['materia'], 20);
      expect((p.sandRuntime()['sandRules'] as Map)['matterDurationTurns'], 4);
      expect(
        (p.sandRuntime()['sandLavaReceipts'] as Map).containsKey('custom-lava'),
        true,
      );
      await closeFixture(tester, p);
    },
  );
}
