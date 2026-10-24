import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('negative resource quick commands parse as costs', () {
    expect(oculumParseAbilityCost('@mat-1'), (
      minimum: 1,
      maximum: 1,
      resource: 'materia',
    ));
    expect(oculumParseAbilityCost('@Oculum-3'), (
      minimum: 3,
      maximum: 3,
      resource: 'oculum',
    ));
    expect(oculumParseAbilityCost('@vol-3'), (
      minimum: 3,
      maximum: 3,
      resource: 'volonta',
    ));
    expect(oculumParseAbilityCost('@mat+1'), isNull);
    expect(oculumParseAbilityCost('@res-30%'), isNull);
    expect(
      oculumParseAbilityCost(
        'Impone il Titolo Malanno @res-30% per tre Riposi Lunghi. (3/3 Oculum, costo fisso).',
      ),
      (minimum: 3, maximum: 3, resource: 'oculum'),
    );
  });

  test('bracketed Richiede markers keep a skill locked until resolved', () {
    expect(
      oculumCombatTextHasUnresolvedRequirement(
        '[Richiede: il Master deve assegnare il titolo]',
      ),
      isTrue,
    );
    expect(
      oculumCombatTextHasUnresolvedRequirement(
        'I — Attacco normale. Richiede livello 0.',
      ),
      isFalse,
    );
    expect(
      oculumCombatTextHasUnresolvedRequirement(
        'Effetto libero senza requisito',
      ),
      isFalse,
    );
  });

  test('free-text shadow summons become executable sheet effects', () {
    final defaultDuration = oculumParseAbilityMechanics(
      'Evoca un tuo clone d’ombra che dura Oculum turni.',
    ).effects.single;
    expect(defaultDuration.type, 'evocazione');
    expect(defaultDuration.target, 'clone_ombra');
    expect(defaultDuration.valueExpression, '10');
    expect(defaultDuration.duration, 'oculum');
    expect(defaultDuration.durationUnit, 'turni');
    expect(defaultDuration.recipient, 'se_stesso');

    final customDuration = oculumParseAbilityMechanics(
      'Crea un clone d\'ombra per 4 turni.',
    ).effects.single;
    expect(customDuration.type, 'evocazione');
    expect(customDuration.valueExpression, '10');
    expect(customDuration.duration, '4');
  });

  test('Chaos sign has exact point probabilities and stable shop offers', () {
    final counts = <int, int>{};
    for (var roll = 0; roll < 100; roll++) {
      final points = oculumChaosSignPoints(roll);
      counts[points] = (counts[points] ?? 0) + 1;
    }
    expect(counts, {0: 3, 1: 75, 2: 13, 3: 9});
    for (var i = 0; i < 100; i++) {
      final offer = oculumFateSignOffer('shop-$i');
      expect(offer['cost'], inInclusiveRange(50, 120));
      expect(offer['remaining'], 1);
      expect(offer, oculumFateSignOffer('shop-$i'));
      expect(
        oculumChaosSignOffer('shop-$i')['cost'],
        inInclusiveRange(60, 120),
      );
    }
  });

  test(
    'Fate Sign probabilities increase with the paid cost and sum to 100',
    () {
      expect(oculumFateSignChances(50), (
        normal: 70,
        superInspiration: 20,
        oculum: 10,
      ));
      expect(oculumFateSignChances(120), (
        normal: 30,
        superInspiration: 40,
        oculum: 30,
      ));
      var previousSuper = 0, previousOculum = 0;
      for (var cost = 50; cost <= 120; cost++) {
        final chance = oculumFateSignChances(cost);
        expect(chance.normal + chance.superInspiration + chance.oculum, 100);
        expect(chance.superInspiration, greaterThanOrEqualTo(previousSuper));
        expect(chance.oculum, greaterThanOrEqualTo(previousOculum));
        previousSuper = chance.superInspiration;
        previousOculum = chance.oculum;
      }
      expect(oculumFateSignOutcome(50, 69), 'normal');
      expect(oculumFateSignOutcome(50, 70), 'super');
      expect(oculumFateSignOutcome(50, 90), 'oculum');
      expect(oculumFateSignOutcome(120, 30), 'super');
      expect(oculumFateSignOutcome(120, 70), 'oculum');
    },
  );
  test('inventory scrolls classify and target their executable effects', () {
    final heal = oculumScrollCombatEffects({'kind': 'heal', 'grade': 2});
    expect(heal.single.valueExpression, '16');
    expect(heal.single.recipient, 'alleato');
    expect(
      oculumCombatAbilityRoles(heal),
      contains(OculumCombatAbilityRole.support),
    );
    final attack = oculumScrollCombatEffects({
      'kind': 'attack',
      'grade': 1,
      'element': 'fuoco',
    }, resolvedDamage: 42);
    expect(attack.single.valueExpression, '42');
    expect(attack.single.recipient, 'bersaglio');
    expect(oculumCombatAbilityRoles(attack), {OculumCombatAbilityRole.attack});
    final state = oculumScrollCombatEffects({'kind': 'stun', 'grade': 1});
    expect(
      oculumCombatAbilityRoles(state),
      containsAll([
        OculumCombatAbilityRole.attack,
        OculumCombatAbilityRole.support,
      ]),
    );
  });
  test(
    'text-only effects keep manual overrides and execute command aliases',
    () {
      final configured = OculumStructuredEffect(
        type: 'cura',
        valueExpression: '99',
      );
      expect(
        oculumResolveAbilityEffects([configured], 'cura 7 Vita').single,
        same(configured),
      );
      final heal = oculumResolveAbilityEffects([], '**@Cura+7** a 2 alleati');
      expect(heal.single.type, 'cura');
      expect(heal.single.recipient, 'alleato');
      expect(heal.single.valueExpression, '7');
      final condition = oculumResolveAbilityEffects(
        [],
        '@Stato: Bruciatura II al bersaglio per 2 turni',
      );
      expect(condition.single.appliedState, 'bruciatura');
      expect(condition.single.valueExpression, '2');
      expect(condition.single.duration, '2');
      expect(
        oculumResolveAbilityEffects([], '@VC+8', legacyQuickCommands: true),
        isEmpty,
      );
      expect(
        oculumResolveAbilityEffects(
          [],
          'Infliggi 8 danni Fuoco',
        ).single.recipient,
        'bersaglio',
      );
    },
  );
  test('mixed bonuses use the stronger role and utility remains visible', () {
    Set<OculumCombatAbilityRole> roles(String text) =>
        oculumCombatAbilityRoles(oculumResolveAbilityEffects([], text));
    expect(roles('@CM+8; @VC+8'), containsAll(OculumCombatAbilityRole.values));
    expect(roles('@CM+9; @VC+5'), {
      OculumCombatAbilityRole.defense,
      OculumCombatAbilityRole.support,
    });
    expect(roles('@Danni+12; @Difesa+5'), {
      OculumCombatAbilityRole.attack,
      OculumCombatAbilityRole.support,
    });
    expect(
      roles('Applica Bruciatura al bersaglio per 2 turni'),
      contains(OculumCombatAbilityRole.support),
    );
  });
  test('defensive protection effects appear in defense and utility', () {
    for (final effect in <OculumStructuredEffect>[
      OculumStructuredEffect(type: 'scudo', valueExpression: '8'),
      OculumStructuredEffect(type: 'hp_temporanei', valueExpression: '8'),
      OculumStructuredEffect(
        type: 'elemental_resistance',
        elementType: 'fuoco',
        customDisplayText: 'Alta Resistenza',
      ),
      OculumStructuredEffect(type: 'difesa', target: 'scudo_oculum'),
    ]) {
      expect(
        oculumCombatAbilityRoles([effect]),
        containsAll([
          OculumCombatAbilityRole.defense,
          OculumCombatAbilityRole.support,
        ]),
        reason: effect.type,
      );
    }
  });
  test('explicit target ranges survive copying and JSON', () {
    final effect = OculumStructuredEffect(
      type: 'cura',
      recipient: 'alleato',
      valueExpression: '7',
      minimumTargets: 2,
      maximumTargets: 4,
    );
    final restored = effect.copyForNextForm();
    expect(restored.minimumTargets, 2);
    expect(restored.maximumTargets, 4);
    expect(restored.recipient, 'alleato');
    final legacy = OculumStructuredEffect.fromJson({
      'type': 'cura',
      'valueExpression': '7',
    });
    expect(legacy.minimumTargets, 0);
    expect(legacy.maximumTargets, 0);
    final parsed = oculumParseAbilityMechanics('Cura 7 Vita a 2 alleati');
    expect(parsed.effects, isNotEmpty);
    expect(parsed.effects.first.recipient, 'alleato');
    expect(parsed.effects.first.minimumTargets, 2);
    expect(parsed.effects.first.maximumTargets, 2);
  });
  test('inline cost does not swallow executable bonuses', () {
    final result = oculumParseAbilityMechanics(
      'Costo: 2 Oculum; @VC+3 per 2 turni',
    );
    expect(result.effects.single.target, 'VC');
    expect(result.effects.single.valueExpression, '3');
    expect(result.effects.single.duration, '2');
  });
  test('conditional and negated clauses stay manual', () {
    for (final text in [
      'Se colpisci ottieni +5 Materia',
      'Quando perdi Vita ottieni +2 Volontà',
      'Non ottieni +3 Resilienza',
    ]) {
      final result = oculumParseAbilityMechanics(text);
      expect(result.effects, isEmpty, reason: text);
      expect(result.unrecognizedText, contains(text));
    }
  });
  test('semantic matching preserves timing differences and ignores IDs', () {
    final first = oculumParseAbilityMechanics(
      '@VC+3 per 2 turni',
    ).effects.single;
    final copy = OculumStructuredEffect.fromJson({
      ...first.toJson(),
      'id': 'another',
    });
    expect(
      oculumStructuredEffectSemanticKey(copy),
      oculumStructuredEffectSemanticKey(first),
    );
    copy.durationUnit = 'azioni';
    expect(
      oculumStructuredEffectSemanticKey(copy),
      isNot(oculumStructuredEffectSemanticKey(first)),
    );
  });
  test('resource costs distinguish fixed, variable and free use', () {
    expect(oculumParseAbilityCost('costo 1 Volontà')?.resource, 'volonta');
    expect(oculumParseAbilityCost('(2/6 Oculum)')?.maximum, 6);
    expect(oculumParseAbilityCost('Nessun costo')?.resource, 'nessuna');
    expect(oculumParseAbilityCost('recuperi 1/4 della Vita'), isNull);
  });
  test('ability parser separates requirements, costs and real bonuses', () {
    final parsed = oculumParseAbilityMechanics(
      'Richiede livello 24. Costo: 5/5 Oculum.\n@VC+2 e +34 danni per 2 turni',
    );
    expect(parsed.effects, hasLength(2));
    expect(parsed.effects.first.target, 'VC');
    expect(parsed.effects.first.valueExpression, '2');
    expect(parsed.effects.last.valueExpression, '34');
    expect(parsed.effects.last.duration, '2');
  });
  test('ability parser keeps invested Oculum, dice and healing resources', () {
    final heal = oculumParseAbilityMechanics('recuperi 1d6 + Medicina Vita');
    expect(heal.effects.single.type, 'cura');
    expect(heal.effects.single.resource, 'vita');
    expect(heal.effects.single.valueExpression, '1d6 + Medicina');
    final damage = oculumParseAbilityMechanics(
      '+5 + Oculum danni',
      investedOculum: true,
    );
    expect(damage.effects.single.valueExpression, '5 + oculum_spent');
  });
  test('ability parser never turns costs or unknown prose into a bonus', () {
    final parsed = oculumParseAbilityMechanics(
      'Richiede livello 15. Costo: 11/30 Oculum.\nOsservi il cielo.',
    );
    expect(parsed.effects, isEmpty);
    expect(parsed.unrecognizedText, contains('Osservi il cielo'));
    expect(oculumParseAbilityCost('(11/30 Oculum)')?.maximum, 30);
    expect(oculumParseAbilityCost('spendi 2 Oculum')?.minimum, 2);
    expect(oculumParseAbilityCost('(8/2 Oculum)'), isNull);
  });
  test('critical bonus follows difficulty and only that bonus doubles', () {
    for (final entry in {
      'facile': 30,
      'normale': 20,
      'difficile': 10,
      'oculum': 5,
    }.entries) {
      final bonus = oculumCriticalDamageBonusForDifficulty(entry.key, 10);
      expect(bonus, entry.value);
      expect(
        oculumCriticalDamageBonusForDifficulty(entry.key, 10) * 2 + 51,
        51 + entry.value * 2,
      );
    }
    expect(oculumParseAbilityCost('costa 3 Oculum')?.minimum, 3);
    expect(
      oculumParseAbilityMechanics(
        'recuperi Vita massima/3 Vita',
      ).effects.single.valueExpression,
      'hp/3',
    );
  });
}
