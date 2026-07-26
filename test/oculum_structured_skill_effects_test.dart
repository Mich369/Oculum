import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  final velo = HiddenEyeStat(
    id: 'velo',
    nome: 'Velo',
    descrizione: 'Velo',
    valore: 4,
  );
  final subtraits = <HiddenEyeStat>[velo];
  final variables = <String, num>{
    'resilienza': 6,
    'velo': 4,
    'oculum_spent': 5,
    'vita': 20,
  };

  group('riferimenti ai sottotratti', () {
    test('@Res, +1 e -1 sono valutati senza modificare il sottotratto', () {
      int value(String expression) => oculumEvaluateStructuredEffectValue(
        OculumStructuredEffect(valueExpression: expression),
        variables: variables,
        subtraits: subtraits,
      );

      expect(value('@Res'), 6);
      expect(value('@Res+1'), 7);
      expect(value('@Res-1'), 5);
    });

    test('normalizza spazi e maiuscole usando il nome ufficiale', () {
      expect(
        oculumNormalizeSubtraitReferences('@ Res + 1', subtraits),
        '@Res+1',
      );
      expect(oculumNormalizeSubtraitReferences('@res +1', subtraits), '@Res+1');
    });

    test('funziona allo stesso modo in danno, difesa, cura e scudo', () {
      for (final type in <String>['danno', 'difesa', 'cura', 'scudo']) {
        final effect = OculumStructuredEffect(
          type: type,
          valueExpression: '@Velo+2',
        );
        expect(
          oculumEvaluateStructuredEffectValue(
            effect,
            variables: variables,
            subtraits: subtraits,
          ),
          6,
        );
      }
    });

    test('un sottotratto non può mai essere una risorsa consumabile', () {
      expect(
        oculumIsConsumableEffectResource('Velo', subtraits: subtraits),
        isFalse,
      );
      expect(
        OculumSkillCost(resource: 'Velo').isValid(subtraits: subtraits),
        isFalse,
      );
      expect(OculumSkillCost(resource: 'Res').resource, 'resilienza');
      expect(
        OculumSkillCost(resource: 'oculum').isValid(subtraits: subtraits),
        isTrue,
      );
    });
  });

  group('dadi, livello, grado e durata', () {
    test('i dadi si tirano in attivazione e non durante i tick', () {
      final effect = OculumStructuredEffect(
        valueExpression: '2',
        diceExpression: '1d6',
        includeLevel: true,
        includeGrade: true,
        gradeValue: 2.5,
      );
      final activation = oculumResolveStructuredEffectRoll(
        effect,
        variables: variables,
        level: 3,
        grade: 2,
        random: Random(7),
      );
      final tick = oculumResolveStructuredEffectRoll(
        effect,
        variables: variables,
        level: 3,
        grade: 2,
        isTick: true,
        random: Random(7),
      );

      expect(activation.dice.rolls, hasLength(1));
      expect(activation.value, inInclusiveRange(11, 16));
      expect(tick.dice.rolls, isEmpty);
      expect(tick.value, 10);
    });

    test('il dado può aumentare la durata invece del valore', () {
      final effect = OculumStructuredEffect(
        valueExpression: '5',
        duration: '2',
        durationUnit: 'tiri',
        diceExpression: '1d4',
        diceDestination: 'durata',
      );
      final resolved = oculumResolveStructuredEffectRoll(
        effect,
        variables: variables,
        random: Random(3),
      );
      expect(resolved.value, 5);
      expect(resolved.durationBonus, inInclusiveRange(1, 4));
      expect(effect.durationUnit, 'tiri');
    });

    test('nella cura il dado aumenta la cura stessa', () {
      final effect = OculumStructuredEffect(
        type: 'cura',
        resource: 'vita',
        valueExpression: '4',
        diceExpression: '1d8',
        diceDestination: 'valore',
      );
      final resolved = oculumResolveStructuredEffectRoll(
        effect,
        variables: variables,
        random: Random(12),
      );
      expect(resolved.value, inInclusiveRange(5, 12));
    });

    test('il cooldown può partire non carico e scala solo nella sua unità', () {
      final cooldown = OculumAbilityCooldown(
        amount: 3,
        unit: 'turni',
        startsReady: false,
      );
      expect(cooldown.ready, isFalse);
      expect(cooldown.remaining, 3);
      expect(cooldown.tick('tiri'), isFalse);
      expect(cooldown.remaining, 3);
      expect(cooldown.tick('turni'), isTrue);
      expect(cooldown.remaining, 2);
    });

    test('la Cenere aggiunge 2 turni sicuri ogni 6 livelli', () {
      expect(oculumAutomaticAshFreeTurns(0), 6);
      expect(oculumAutomaticAshFreeTurns(5), 6);
      expect(oculumAutomaticAshFreeTurns(6), 8);
      expect(oculumAutomaticAshFreeTurns(12), 10);
      for (final difficulty in <String>[
        'facile',
        'normale',
        'difficile',
        'oculum',
      ]) {
        expect(
          oculumAutomaticAshChancePercent(turn: 6, difficulty: difficulty),
          0,
        );
      }
      expect(oculumAutomaticAshChancePercent(turn: 7, difficulty: 'facile'), 5);
      expect(
        oculumAutomaticAshChancePercent(
          turn: 8,
          difficulty: 'facile',
          level: 6,
        ),
        0,
      );
      expect(
        oculumAutomaticAshChancePercent(
          turn: 9,
          difficulty: 'facile',
          level: 6,
        ),
        5,
      );
      expect(
        oculumAutomaticAshChancePercent(turn: 8, difficulty: 'normale'),
        17,
      );
      expect(
        oculumAutomaticAshChancePercent(turn: 8, difficulty: 'difficile'),
        25,
      );
      expect(
        oculumAutomaticAshChancePercent(turn: 20, difficulty: 'oculum'),
        100,
      );
      expect(
        oculumAutomaticAshChancePercent(
          turn: 7,
          difficulty: 'normale',
          underStress: true,
        ),
        25,
      );
    });

    test('il consumo sotto stress assegna Cenere ogni Livello + 1 punti', () {
      final levelZero = oculumStressConsumptionProgress(
        current: 0,
        consumed: 1,
        level: 0,
        underStress: true,
      );
      expect(levelZero.awards, 1);
      expect(levelZero.remainder, 0);

      final levelOne = oculumStressConsumptionProgress(
        current: 0,
        consumed: 2,
        level: 1,
        underStress: true,
      );
      expect(levelOne.awards, 1);
      expect(levelOne.remainder, 0);

      final first = oculumStressConsumptionProgress(
        current: 0,
        consumed: 4,
        level: 6,
        underStress: true,
      );
      expect(first.awards, 0);
      expect(first.remainder, 4);

      final second = oculumStressConsumptionProgress(
        current: first.remainder,
        consumed: 9,
        level: 6,
        underStress: true,
      );
      expect(second.awards, 1);
      expect(second.remainder, 6);

      final ignored = oculumStressConsumptionProgress(
        current: 0,
        consumed: 20,
        level: 6,
        underStress: false,
      );
      expect(ignored.awards, 0);
    });

    test('le soglie Vita sono 75, 50, 25 e 0 percento', () {
      expect(
        oculumCrossedHpQuarterThresholds(before: 100, after: 49, maximum: 100),
        <int>[75, 50],
      );
      expect(
        oculumCrossedHpQuarterThresholds(before: 26, after: 0, maximum: 100),
        <int>[25, 0],
      );
      expect(
        oculumHpLossAshChancePercent(
          remainingPercent: 75,
          difficulty: 'facile',
        ),
        5,
      );
      expect(
        oculumHpLossAshChancePercent(
          remainingPercent: 0,
          difficulty: 'oculum',
          underStress: true,
        ),
        75,
      );
      expect(oculumArtIntegrityBreakAshChancePercent, 50);
    });
  });

  group('liste, parser e compatibilità', () {
    test('più effetti mantengono ordine e stato nel JSON', () {
      final form = CharacterSkillForm(
        nome: 'Forma 1',
        effettiStrutturati: <OculumStructuredEffect>[
          OculumStructuredEffect(type: 'danno', valueExpression: '5'),
          OculumStructuredEffect(
            type: 'difesa',
            valueExpression: '@Res+1',
            enabled: false,
          ),
          OculumStructuredEffect(type: 'cura', valueExpression: '2'),
        ],
      );
      final restored = CharacterSkillForm.fromJson(form.toJson());
      expect(restored.effettiStrutturati.map((effect) => effect.type), <String>[
        'danno',
        'difesa',
        'cura',
      ]);
      expect(restored.effettiStrutturati[1].enabled, isFalse);
    });

    test('il parser crea più effetti e conserva il testo non riconosciuto', () {
      final parsed = oculumParseStructuredEffectsFromText(
        'Danni + OculumSpeso x 1.3 e Difesa + @ Res + 1 e vola',
        subtraits: subtraits,
      );
      expect(parsed.effects, hasLength(2));
      expect(parsed.effects[0].type, 'danno');
      expect(parsed.effects[1].valueExpression, '@Res+1');
      expect(parsed.unrecognizedText, contains('vola'));
      expect(
        oculumEvaluateStructuredEffectValue(
          parsed.effects.first,
          variables: variables,
          spentResources: const <String, num>{'oculum': 5},
        ),
        7,
      );
    });

    test(
      'riconosce un muro basato su Oculum immesso e conserva i limiti 1/4',
      () {
        const text =
            'Innalza un muro che sottrae ai danni in arrivo una quantità pari '
            'a Oculum immesso ×2 +3; il muro crolla quando ha assorbito '
            'interamente tale quantità. (1/4)';
        final parsed = oculumParseStructuredEffectsFromText(text);
        final wall = parsed.effects.single;

        expect(wall.type, 'scudo');
        expect(wall.valueExpression, 'OculumSpeso*2+3');
        expect(
          oculumEvaluateStructuredEffectValue(
            wall,
            variables: variables,
            spentResources: const <String, num>{'oculum': 4},
          ),
          11,
        );
        final limits = oculumSkillTextLimitsAtEnd(text);
        expect(limits?.minimum, 1);
        expect(limits?.maximum, 4);
      },
    );

    test('Oculum immesso e utilizzato sono alias di Oculum speso', () {
      for (final formula in <String>[
        'Oculum immesso ×2 +3',
        'Oculum utilizzato x2 +3',
        'OculumSpeso*2+3',
      ]) {
        final effect = OculumStructuredEffect(valueExpression: formula);
        expect(
          oculumEvaluateStructuredEffectValue(
            effect,
            variables: variables,
            spentResources: const <String, num>{'oculum': 4},
          ),
          11,
          reason: formula,
        );
      }
    });

    test('gli effetti generici ogni N turni conservano valore e frequenza', () {
      final parsed = oculumParseStructuredEffectsFromText(
        'Scudo + 3 ogni 2 turni e Cura 4 ogni 3 turni',
      );
      expect(parsed.effects, hasLength(2));
      expect(parsed.effects[0].type, 'scudo');
      expect(parsed.effects[0].valueExpression, '3');
      expect(parsed.effects[0].frequency, '2');
      expect(parsed.effects[1].type, 'cura');
      expect(parsed.effects[1].valueExpression, '4');
      expect(parsed.effects[1].frequency, '3');
      expect(
        oculumStructuredEffectDescription(parsed.effects[0]),
        contains('ogni 2 turni'),
      );
    });

    test(
      'il contatore periodico agisce solo ogni N tick ed è persistibile',
      () {
        final state = <String, dynamic>{
          'frequency': 3,
          'frequencyElapsed': 0,
          'periodicActive': false,
          'unit': 'turni',
          'remaining': -1,
        };
        expect(oculumAdvanceStructuredEffectFrequency(state, 'turni'), isFalse);
        expect(state['frequencyElapsed'], 1);
        expect(oculumAdvanceStructuredEffectFrequency(state, 'tiri'), isFalse);
        expect(state['frequencyElapsed'], 1);
        expect(oculumAdvanceStructuredEffectFrequency(state, 'turni'), isFalse);
        expect(oculumAdvanceStructuredEffectFrequency(state, 'turni'), isTrue);
        expect(state['frequencyElapsed'], 0);
        expect(state['periodicActive'], isTrue);
        expect(oculumAdvanceStructuredEffectFrequency(state, 'turni'), isFalse);
        expect(state['periodicActive'], isFalse);
        expect(oculumShouldRestoreActiveStructuredEffect(state), isTrue);
        expect(
          oculumShouldRestoreActiveStructuredEffect(<String, dynamic>{
            'remaining': -1,
          }),
          isFalse,
        );
        expect(
          oculumShouldRestoreActiveStructuredEffect(<String, dynamic>{
            'remaining': 2,
          }),
          isTrue,
        );
      },
    );

    test('le evoluzioni Art sono indipendenti e copiabili', () {
      final skill = ArtSkill(
        nome: 'Eco',
        effettiPerLivello: <List<OculumStructuredEffect>>[
          <OculumStructuredEffect>[
            OculumStructuredEffect(type: 'danno', valueExpression: '1'),
          ],
        ],
      );
      skill.copiaEffettiDaLivelloPrecedente(2);
      skill.effettiPerLivello[1].first.valueExpression = '2';

      expect(skill.effettiPerLivello[0].first.valueExpression, '1');
      expect(skill.effettiPerLivello[1].first.valueExpression, '2');
      expect(ArtSkill.fromJson(skill.toJson()).effettiPerLivello, hasLength(5));
    });

    test('vecchi salvataggi restano validi senza nuove chiavi', () {
      final oldSkill = CharacterSkill.fromJson(<String, dynamic>{
        'nome': 'Vecchia Skill',
        'descrizione': 'testo libero',
      });
      final oldArt = CharacterArt.fromJson(<String, dynamic>{
        'nome': 'Vecchia Art',
        'tipo': 'Normale',
        'descrizione': 'testo',
        'skills': <dynamic>[],
      });
      expect(oldSkill.forme.first.effettiStrutturati, isEmpty);
      expect(oldSkill.forme.first.cooldownStrutturato, isNull);
      expect(oldArt.openDescriptionEffects, isEmpty);
      expect(oldArt.openDescriptionCooldown, isNull);
    });

    test('Open Description, Open Skill e Open Buff salvano separatamente', () {
      final art = CharacterArt(
        nome: 'Sogno',
        tipo: 'Normale',
        descrizione: '',
        skills: <ArtSkill>[],
        openDescriptionEffects: <OculumStructuredEffect>[
          OculumStructuredEffect(type: 'cura', valueExpression: '1'),
        ],
        openSkillEffects: <OculumStructuredEffect>[
          OculumStructuredEffect(type: 'danno', valueExpression: '2'),
        ],
        openBuffEffects: <OculumStructuredEffect>[
          OculumStructuredEffect(type: 'difesa', valueExpression: '3'),
        ],
      );
      final restored = CharacterArt.fromJson(art.toJson());
      expect(restored.openDescriptionEffects.single.type, 'cura');
      expect(restored.openSkillEffects.single.type, 'danno');
      expect(restored.openBuffEffects.single.type, 'difesa');
    });

    test('le Open dei Titoli conservano gli effetti guidati', () {
      final title = OculumTitle(
        nome: 'Titolo del Chaos',
        tipo: 'Chaos',
        ottenimento: '',
        buff: '',
        puntoCieco: '',
        skill: '',
        richiede: '',
        openEffects: <OculumStructuredEffect>[
          OculumStructuredEffect(type: 'danno', valueExpression: '30'),
        ],
        openExtra: <TitleOpenEntry>[
          TitleOpenEntry(
            nome: 'Punizione del Fato',
            effects: <OculumStructuredEffect>[
              OculumStructuredEffect(
                type: 'modifica_statistica',
                target: 'Oculum',
                valueExpression: '9',
              ),
            ],
          ),
        ],
      );
      final restored = OculumTitle.fromJson(title.toJson());
      expect(restored.openEffects.single.valueExpression, '30');
      expect(restored.openExtra.single.effects.single.target, 'Oculum');
    });

    test('riconosce il testo naturale del Titolo del Chaos', () {
      final parsed = oculumParseStructuredEffectsFromText(
        '+9 danni ogni 3 turni\n'
        'ti trasformi in un mezzo mostro, stats+oculum speso\n'
        'gli anti Fato subiscono danno letale dai prossimi 5 colpi\n'
        '+9 a tutte le stats\n'
        'puoi aumentare il tuo danno di 30 per un turno',
      );
      expect(
        parsed.effects.where(
          (effect) =>
              effect.type == 'danno' &&
              effect.valueExpression == '9' &&
              effect.frequency == '3',
        ),
        hasLength(1),
      );
      expect(
        parsed.effects.where(
          (effect) => effect.valueExpression == 'OculumSpeso',
        ),
        hasLength(4),
      );
      expect(
        parsed.effects.where(
          (effect) =>
              effect.type == 'stato' &&
              effect.duration == '5' &&
              effect.durationUnit == 'tiri',
        ),
        hasLength(1),
      );
      expect(
        parsed.effects.where(
          (effect) =>
              effect.type == 'danno' &&
              effect.valueExpression == '30' &&
              effect.duration == '1',
        ),
        hasLength(1),
      );
    });

    test('tipo elemento e stato Sotto stress restano nel salvataggio', () {
      final effect = OculumStructuredEffect(
        type: 'stato',
        appliedState: 'sotto_stress',
        elementType: 'Ghiaccio',
        duration: '3',
      );
      final restored = OculumStructuredEffect.fromJson(effect.toJson());
      expect(restored.appliedState, 'sotto_stress');
      expect(restored.elementType, 'Ghiaccio');
      expect(restored.duration, '3');
    });

    test('il danno conserva oltre Difesa e oltre Scudi', () {
      final effect = OculumStructuredEffect(
        type: 'danno',
        valueExpression: '8',
        elementType: 'Ghiaccio',
        bypassDefense: true,
        bypassShields: true,
      );
      final restored = OculumStructuredEffect.fromJson(effect.toJson());
      expect(restored.bypassDefense, isTrue);
      expect(restored.bypassShields, isTrue);
      expect(
        oculumStructuredEffectDescription(restored),
        allOf(contains('oltre Difesa'), contains('oltre Scudi')),
      );
    });

    test('ogni forma Art e ogni Open conservano il proprio tipo', () {
      final skill = ArtSkill(
        nome: 'Cristallo',
        tipiPerLivello: <String>['Ghiaccio', 'Ghiaccio oscuro'],
      );
      final art = CharacterArt(
        nome: 'Art Gelida',
        tipo: 'Ghiaccio',
        descrizione: '',
        skills: <ArtSkill>[skill],
        openDescriptionType: 'Ghiaccio',
        openSkillType: 'Perforante',
        openBuffType: 'Freddo',
      );
      final restored = CharacterArt.fromJson(art.toJson());
      expect(restored.skills.single.tipoPerLivello(1), 'Ghiaccio');
      expect(restored.skills.single.tipoPerLivello(2), 'Ghiaccio oscuro');
      expect(restored.openDescriptionType, 'Ghiaccio');
      expect(restored.openSkillType, 'Perforante');
      expect(restored.openBuffType, 'Freddo');
    });

    test(
      'la guardia impedisce doppia applicazione nella stessa attivazione',
      () {
        final guard = OculumEffectApplicationGuard();
        final effect = OculumStructuredEffect(valueExpression: '1');
        expect(guard.tryApply('use-1', effect), isTrue);
        expect(guard.tryApply('use-1', effect), isFalse);
        expect(guard.tryApply('use-2', effect), isTrue);
      },
    );
  });
}
