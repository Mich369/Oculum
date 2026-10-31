import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

Future<(dynamic, OculumPerformanceProbe)> cleanFight(
  WidgetTester tester,
) async {
  final (s, p) = await fixtures.mountFight(tester);
  s.titoli.clear();
  s.arti.clear();
  s.skills.clear();
  s.trattiRazziali.clear();
  s.inventario.clear();
  s.activeStructuredEffects.clear();
  s.activeConditions.clear();
  s.buffMalusRapidiController.clear();
  s.resilienzaController.text = '100';
  s.currentResilienzaController.text = '100';
  s.volontaController.text = '0';
  s.currentVolontaController.text = '0';
  s.materiaController.text = '0';
  s.currentMateriaController.text = '0';
  // No independent random Oculum parry in exact HP arithmetic assertions.
  s.oculumController.text = '0';
  s.currentOculumController.text = '0';
  s.livelloController.text = '0';
  s.gradoController.text = '0';
  s.scudoController.text = '0';
  s.hpTempController.text = '0';
  s.scudoOculumController.text = '0';
  s.scudoOculumMaxController.text = '100';
  s.scudoCriticoController.text = '0';
  s.dannoOltreDifesa = false;
  s.dannoOltreScudi = false;
  s.statoForzaPronto = false;
  s.statoForzaAttivo = '';
  s.incomingDamagePresets.clear();
  s.modificatoreDannoSelezionato = 'Normale';
  s.schedePersonaggio[s.schedaCorrente]['partialAwakeningHalfHpTriggered'] =
      true;
  for (final dynamic stat in s.hiddenEyeStats) {
    if (const {'fortuna', 'riflessi', 'resistenza'}.contains(stat.id)) {
      // Defaults can unlock a required subtrait again during incoming damage.
      // Offset the derived RES/2 as well; otherwise this exact arithmetic test
      // randomly receives the unrelated 50-point passive resistance reduction.
      stat.valore = stat.id == 'resistenza' ? -50 : -100;
      stat.unlocked = true;
    }
  }
  p.invalidateDerivedCaches();
  s.currentHpController.text = '500';
  return (s, p);
}

void main() {
  test('Infernal Ice Wolf is glacial while legacy technique IDs stay usable', () {
    final wolf = monsterBookEntryById('lupo_infernale_del_ghiaccio')!;
    expect(wolf.elementId, 'ghiaccio');
    expect(wolf.damageResistancePresets, {'ghiaccio': 'resistenza'});
    expect(wolf.skillIds.take(2), [
      'infernal_wolf_ember_bite',
      'infernal_wolf_ash_charge',
    ]);
    final bite = monsterBookConcreteTechnique(wolf.skillIds.first)!;
    final charge = monsterBookConcreteTechnique(wolf.skillIds[1])!;
    expect(bite.element, 'ghiaccio');
    expect(charge.element, 'ghiaccio');
    expect(bite.name, 'Morso glaciale infernale');
    expect(charge.name, 'Carica della brina infernale');
    expect(bite.forms.first.any((e) => e.type == 'stato'), false);
    for (final form in bite.forms.skip(1)) {
      expect(form.singleWhere((e) => e.type == 'stato').target, 'rallentato');
      expect(form.any((e) => e.target == 'bruciatura'), false);
    }
    expect(bite.forms.map((f) => f.first.formula), ['9', '15', '22']);
    expect(charge.forms.map((f) => f.first.formula), ['8', '14', '20']);
    expect(bite.minimums, [1, 2, 3]);
    expect(bite.cooldowns, [2, 2, 3]);
  });
  test('percent HP input uses current real HP and existing formula safety', () {
    for (final current in [0, 1, 100, 175, 500]) {
      expect(
        oculumEvaluateDamageHealingInput('25%', {
          'hp': 9999,
        }, currentHp: current),
        oculumRoundFormulaResult(current * .25),
      );
    }
    expect(oculumEvaluateDamageHealingInput('12,5%', {}, currentHp: 200), 25);
    expect(
      oculumEvaluateDamageHealingInput(
        '25%Tot',
        {},
        currentHp: 100,
        maximumHp: 200,
      ),
      50,
    );
    expect(
      oculumEvaluateDamageHealingInput('25%tot', {'hp': 400}, currentHp: 100),
      100,
    );
    expect(oculumEvaluateDamageHealingInput('10+100-20', {}, currentHp: 1), 90);
    expect(
      oculumEvaluateDamageHealingInput('danni+PT', {
        'danni': 4,
        'pt': 20,
      }, currentHp: 1),
      24,
    );
    expect(
      () => oculumEvaluateDamageHealingInput('10000000%', {}, currentHp: 500),
      throwsFormatException,
    );
    expect(
      () => oculumEvaluateDamageHealingInput('25%%', {}, currentHp: 500),
      throwsFormatException,
    );
  });
  test(
    'readable ranged costs agree and conflicting resources stay invalid',
    () {
      for (final raw in [
        'Materia da 1 a 10',
        'Costo: da 1 a 10 Materia',
        'Spendi tra 1 e 10 MAT',
        'da 1 a 10 Materia',
      ]) {
        expect(oculumParseAbilityCost(raw), (
          minimum: 1,
          maximum: 10,
          resource: 'materia',
        ), reason: raw);
      }
      expect(oculumParseAbilityCost('Materia da 1 a 10 Oculum'), isNull);
      expect(oculumParseAbilityCost('Costo: da 10 a 1 Materia'), isNull);
      expect(oculumParseAbilityCost('Materia 1'), (
        minimum: 1,
        maximum: 1,
        resource: 'materia',
      ));
      expect(oculumParseAbilityCost('@mat-1'), (
        minimum: 1,
        maximum: 1,
        resource: 'materia',
      ));
    },
  );
  test('critical and HP gates survive JSON and conditional parsing', () {
    final parsed = oculumParseAbilityMechanics(
      'Con un critico che danneggia la Vita, il nemico perde 3 Materia per 2 turni',
    );
    expect(parsed.effects, hasLength(1));
    final effect = OculumStructuredEffect.fromJson(
      jsonDecode(jsonEncode(parsed.effects.single.toJson())),
    );
    expect(effect.criticalOnly, true);
    expect(effect.requiresHpDamage, true);
    expect(effect.recipient, anyOf('nemico', 'bersaglio'));
    expect(effect.type, 'modifica_statistica');
    expect(
      oculumCombatAbilityRoles([effect]),
      contains(OculumCombatAbilityRole.attack),
    );
    final cm = OculumStructuredEffect(
      type: 'modifica_statistica',
      target: 'cm',
      valueExpression: '3',
      mode: 'diminuzione',
      recipient: 'nemico',
      criticalOnly: true,
    );
    expect(
      oculumCombatAbilityRoles([cm]),
      contains(OculumCombatAbilityRole.attack),
    );
    expect(
      oculumCombatAbilityRoles([cm]),
      isNot(contains(OculumCombatAbilityRole.defense)),
    );
    expect(
      oculumCombatAbilityRole([
        OculumStructuredEffect(type: 'planar', target: 'oblivion_forget_next'),
      ]),
      OculumCombatAbilityRole.attack,
    );
    expect(
      oculumParseAbilityMechanics('Con un critico, ottieni +10 Danni').effects,
      isEmpty,
    );
    expect(
      OculumStructuredEffect.fromJson({'type': 'stato'}).requiresHpDamage,
      false,
    );
    final heal = oculumParseAbilityMechanics(
      'Cura 25% della Vita attuale',
    ).effects.single;
    expect(heal.type, 'cura');
    expect(heal.valueExpression, 'hp_current*25/100');
  });
  test('Oblivion keeps legacy ID and gains an editable three-form Flame', () {
    final monster = monsterBookEntryById('famelico_oblio')!;
    expect(monster.nameIt, 'Oblivion Shield');
    final art = oculumMonsterBookArt(monster);
    final flame = art.skills.singleWhere(
      (s) => s.nome == 'Fiammata del non ricordo',
    );
    for (final effects in flame.effettiPerLivello.take(3)) {
      final secondary = effects.singleWhere(
        (e) => e.target == 'oblivion_forget_next',
      );
      expect(secondary.criticalOnly, true);
      expect(secondary.requiresHpDamage, true);
    }
    expect(
      oculumOblivionForgetResistance(memoria: 20, fortuna: 15, fate: true),
      35,
    );
    expect(
      oculumOblivionForgetResistance(memoria: 20, fortuna: 15, fate: false),
      20,
    );
    expect(
      oculumOblivionForgetResistance(memoria: 99, fortuna: 99, fate: true),
      100,
    );
    expect(
      oculumOblivionForgetResistance(memoria: -5, fortuna: 0, fate: false),
      0,
    );
  });
  testWidgets(
    'manual HP percentages respect protections; explicit automatic damage stays numeric',
    (tester) async {
      final (s, p) = await cleanFight(tester);
      s.scudoController.text = '10';
      s.scudoOculumController.text = '10';
      final defense = p.defense();
      expect(p.readDamageHealingInput('25%'), 125);
      await p.applyDamageInput('25%');
      expect(
        p.currentHp(),
        500 - (125 - defense - 20).clamp(0, 500),
        reason: '${s.risultato}',
      );
      s.currentHpController.text = '400';
      s.dannoOltreDifesa = true;
      s.dannoOltreScudi = true;
      s.scudoController.text = '10';
      s.scudoOculumController.text = '10';
      await p.applyDamageInput('25%');
      expect(p.currentHp(), 300);
      expect(p.shieldTotal(), 10);
      expect(s.scudoOculumController.text, '10');
      p.applyHealInput('25%');
      expect(p.currentHp(), 375);
      final totalHealing = oculumRoundFormulaResult(p.maximumHp() * .25);
      p.applyHealInput('25%Tot');
      expect(p.currentHp(), 375 + totalHealing);
      s.currentHpController.text = '375';
      // A queued percentage in the text field must not override an automatic packet.
      p.readDamageHealingInput('90%');
      await p.damageResolved(20, bypassDefense: true, bypassShields: true);
      expect(p.currentHp(), 355);
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'a lost turn resource cancels activity without stat costs or extra turns',
    (tester) async {
      final (s, p) = await cleanFight(tester);
      final runtime =
          s.schedePersonaggio[s.schedaCorrente]['planarRuntime'] as Map;
      runtime['oblivionForgetPending'] = 1;
      s.masterInitiativeActiveIndex = 0;
      s.masterInitiativeTokens.first['actionUsed'] = false;
      final before = s.currentOculumController.text;
      expect(await p.spendCombatRoll(), false);
      expect(runtime['oblivionForgetPending'], 0);
      expect(s.currentOculumController.text, before);
      expect(s.masterInitiativeTokens.first['actionUsed'], true);
      expect(p.consumeForget('reazione'), false);
      runtime['oblivionForgetPending'] = 1;
      final active = s.masterInitiativeActiveIndex;
      expect(p.consumeForget('speed_grant_fast'), false);
      expect(p.consumeForget('reazione_veloce'), true);
      expect(s.masterInitiativeActiveIndex, active);
      final saved = jsonDecode(jsonEncode(p.snapshot())) as Map;
      expect((saved['planarRuntime'] as Map)['oblivionForgetPending'], 0);
      await closeFixture(tester, p);
    },
  );
  testWidgets('Flame resistance and repeat delivery resolve once per hit', (
    tester,
  ) async {
    final (s, p) = await cleanFight(tester);
    final runtime =
        s.schedePersonaggio[s.schedaCorrente]['planarRuntime'] as Map;
    runtime['identityFateChaos'] = 'Chaos';
    for (final dynamic stat in s.hiddenEyeStats) {
      if (stat.id == 'memoria') {
        stat.valore = 0;
        stat.unlocked = false;
      }
    }
    p.invalidateDerivedCaches();
    p.forgetFlame({'id': 'one'}, percentile: 99);
    p.forgetFlame({'id': 'one'}, percentile: 99);
    expect(runtime['oblivionForgetPending'], 1);
    await closeFixture(tester, p);
  });

  testWidgets('activating the Flame queues its gated secondary for the real hit', (
    tester,
  ) async {
    final (s, p) = await cleanFight(tester);
    final art = oculumMonsterBookArt(monsterBookEntryById('famelico_oblio')!);
    final flame = art.skills.singleWhere(
      (skill) => skill.nome == 'Fiammata del non ricordo',
    );
    p.applyEffects(flame.effettiPerLivello.first);
    final pending = (s.activeStructuredEffects as List).whereType<Map>().singleWhere(
      (entry) => entry['type'] == 'pending_target' &&
          (entry['effect'] as Map?)?['target'] == 'oblivion_forget_next',
    );
    final effect = OculumStructuredEffect.fromJson(
      Map<String, dynamic>.from(pending['effect'] as Map),
    );
    expect(effect.criticalOnly, true);
    expect(effect.requiresHpDamage, true);
    expect(p.planarStateSnapshot()['oblivionForgetPending'], isNull);
    expect(p.conditions, isEmpty);
    await closeFixture(tester, p);
  });

  testWidgets(
    'real Flame packets require critical HP damage and respect a winning defense',
    (tester) async {
      final (s, p) = await cleanFight(tester);
      final runtime =
          s.schedePersonaggio[s.schedaCorrente]['planarRuntime'] as Map;
      runtime['identityFateChaos'] = 'Chaos';
      for (final dynamic stat in s.hiddenEyeStats) {
        if (stat.id == 'memoria') {
          stat.valore = -100;
          stat.unlocked = false;
        }
      }
      p.invalidateDerivedCaches();
      final effect = OculumStructuredEffect(
        type: 'planar',
        target: 'oblivion_forget_next',
        recipient: 'nemico',
        valueExpression: '1',
        criticalOnly: true,
        requiresHpDamage: true,
      );
      for (final scenario in [
        'ordinary',
        'shielded',
        'critical-shield',
        'counter-wins',
        'critical-hp',
      ]) {
        runtime['oblivionForgetPending'] = 0;
        s.currentHpController.text = '500';
        s.hpTempController.text = '0';
        s.scudoCriticoController.text = scenario == 'critical-shield'
            ? '1'
            : '0';
        s.scudoController.text = scenario == 'shielded' ? '9999' : '0';
        s.scudoOculumController.text = '0';
        final request = <String, dynamic>{
          'id': 'flame-$scenario',
          'kind': 'attack',
          'sourceTag': 'ENEMY',
          'targetTag': p.ownerTag(),
          'sourceName': 'Oblivion Shield',
          'targetName': 'Eroe',
          'scope': p.permissionScope,
          'encounterId': 'encounter_1',
          'status': 'pending',
          'choice': 'volonta',
          'attack': 12,
          'natural': scenario == 'ordinary' ? 10 : 20,
          'damage': 20,
          'element': 'oblio',
          'difficulty': 'normale',
          'level': 0,
          'grade': 0,
          'effects': [effect.toJson()],
        };
        s.onlineCombatRequests[request['id']] = request;
        await p.resolveCombatDefense(
          request,
          'difesa',
          scenario == 'counter-wins' ? 100 : 10,
        );
        final expected = scenario == 'critical-hp' ? 1 : 0;
        expect(runtime['oblivionForgetPending'], expected, reason: scenario);
        await p.resolveCombatDefense(request, 'difesa', 10);
        expect(
          runtime['oblivionForgetPending'],
          expected,
          reason: 'duplicate $scenario',
        );
      }
      await closeFixture(tester, p);
    },
  );
  testWidgets('common effect editor accepts legacy enemy and exposes HP gate', (
    tester,
  ) async {
    final (_, p) = await cleanFight(tester);
    final pending = p.editEffect(
      OculumStructuredEffect(
        type: 'planar',
        target: 'oblivion_forget_next',
        recipient: 'nemico',
        valueExpression: '1',
        criticalOnly: true,
        requiresHpDamage: true,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(tester.takeException(), isNull);
    expect(find.text('Richiede Danni alla Vita'), findsOneWidget);
    final cancel = find.text('Annulla').last;
    await tester.ensureVisible(cancel);
    await tester.tap(cancel);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await pending;
    await closeFixture(tester, p);
  });
}
