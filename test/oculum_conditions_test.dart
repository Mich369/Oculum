import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  group('Profili difficolta condizioni', () {
    test('i quattro profili hanno la progressione richiesta', () {
      expect(
        oculumConditionDifficultyProfile('facile').periodicDamageMultiplier,
        .75,
      );
      expect(
        oculumConditionDifficultyProfile('medio').periodicDamageMultiplier,
        1,
      );
      expect(
        oculumConditionDifficultyProfile('normale').periodicDamageMultiplier,
        1,
      );
      expect(
        oculumConditionDifficultyProfile('difficile').periodicDamageMultiplier,
        1.25,
      );
      expect(
        oculumConditionDifficultyProfile('oculum').periodicDamageMultiplier,
        1.5,
      );
      expect(oculumConditionDifficultyProfile('facile').rollPenaltyCap, 6);
      expect(oculumConditionDifficultyProfile('medio').rollPenaltyCap, 8);
      expect(oculumConditionDifficultyProfile('difficile').rollPenaltyCap, 10);
      expect(oculumConditionDifficultyProfile('oculum').rollPenaltyCap, 12);
      expect(
        oculumConditionDifficultyProfile('medio').periodicDamageCapPercent,
        25,
      );
      expect(
        oculumConditionDifficultyProfile('oculum').periodicDamageCapPercent,
        49,
      );
    });

    test('la durata cresce senza moltiplicatore globale sui malus', () {
      expect(oculumConditionScaledDuration(base: 4, difficulty: 'facile'), 3);
      expect(oculumConditionScaledDuration(base: 4, difficulty: 'medio'), 4);
      expect(
        oculumConditionScaledDuration(base: 4, difficulty: 'difficile'),
        5,
      );
      expect(oculumConditionScaledDuration(base: 4, difficulty: 'oculum'), 6);
      expect(oculumConditionDefinition('putrido')!.rollModifierByStage, <int>[
        -2,
        -3,
        -4,
        -5,
        -6,
      ]);
    });

    test('anti chain-control resta sempre presente', () {
      for (final difficulty in <String>[
        'facile',
        'medio',
        'difficile',
        'oculum',
      ]) {
        expect(
          oculumConditionDifficultyProfile(difficulty).controlProtectionTurns,
          greaterThan(0),
        );
      }
      expect(
        oculumConditionDifficultyProfile('facile').controlProtectionTurns,
        2,
      );
    });
  });

  group('Percentuale minimo cap e rounding', () {
    test('Veleno Putrido scala sulle quattro difficolta', () {
      expect(
        oculumConditionScaledValue(
          referenceValue: 1000,
          basePercent: 1,
          minimum: 1,
          difficulty: 'facile',
        ),
        7,
      );
      expect(
        oculumConditionScaledValue(
          referenceValue: 1000,
          basePercent: 1,
          minimum: 1,
          difficulty: 'medio',
        ),
        10,
      );
      expect(
        oculumConditionScaledValue(
          referenceValue: 1000,
          basePercent: 1,
          minimum: 1,
          difficulty: 'difficile',
        ),
        12,
      );
      expect(
        oculumConditionScaledValue(
          referenceValue: 1000,
          basePercent: 1,
          minimum: 1,
          difficulty: 'oculum',
        ),
        15,
      );
    });

    test('HP bassissimi rispettano il minimo', () {
      for (final difficulty in <String>[
        'facile',
        'medio',
        'difficile',
        'oculum',
      ]) {
        expect(
          oculumConditionScaledValue(
            referenceValue: 1,
            basePercent: 1,
            minimum: 1,
            difficulty: difficulty,
          ),
          1,
        );
      }
    });

    test('rounding e per difetto prima del minimo', () {
      expect(
        oculumConditionScaledValue(
          referenceValue: 67,
          basePercent: 4,
          minimum: 2,
          difficulty: 'medio',
        ),
        2,
      );
      expect(
        oculumConditionScaledValue(
          referenceValue: 80,
          basePercent: 4,
          minimum: 2,
          difficulty: 'difficile',
        ),
        4,
      );
    });

    test('il cap limita valori alti', () {
      expect(
        oculumConditionScaledValue(
          referenceValue: 10000,
          basePercent: 6,
          minimum: 2,
          maximum: 100,
          difficulty: 'oculum',
        ),
        100,
      );
    });

    test('gli stack non superano il 25% degli HP MAX per tick', () {
      expect(
        oculumConditionStackedEffect(
          baseEffect: 100,
          stacks: 99,
          referenceValue: 1000,
        ),
        250,
      );
      expect(
        oculumConditionStackedEffect(
          baseEffect: 10,
          stacks: 5,
          referenceValue: 1000,
        ),
        50,
      );
    });

    test('a difficolta Oculum il cap resta mortale ma sotto meta HP', () {
      expect(
        oculumConditionStackedEffect(
          baseEffect: 100,
          stacks: 99,
          referenceValue: 1000,
          maximumPercentPerTick: 49,
        ),
        490,
      );
    });

    test('i buff non scalano con difficulty', () {
      for (final id in <String>[
        'vulnerabile',
        'indebolito',
        'fortificato',
        'accelerato',
        'potenziato',
        'concentrato',
        'vigile',
      ]) {
        expect(
          oculumConditionDefinition(id)!.difficultyScaling,
          OculumConditionDifficultyScaling.none,
        );
      }
    });
  });

  group('Catalogo e progressione', () {
    test('contiene tutte le famiglie definitive', () {
      expect(oculumConditionCatalog.length, greaterThanOrEqualTo(30));
      expect(
        oculumConditionCatalog.map((item) => item.category).toSet(),
        containsAll(OculumConditionCategory.values),
      );
    });

    test('Sanguinamento ha quattro stadi e valori ufficiali', () {
      final bleeding = oculumConditionDefinition('sanguinamento')!;
      expect(bleeding.maxStage, 4);
      expect(bleeding.basePercentByStage, <double>[1, 2, 4, 6]);
      expect(bleeding.minimumByStage, <int>[1, 1, 2, 2]);
      expect(bleeding.stackMode, OculumConditionStackMode.increaseStage);
    });

    test('Putrido arriva a V e non supera -6', () {
      final rot = oculumConditionDefinition('putrido')!;
      expect(rot.maxStage, 5);
      expect(rot.rollModifierForStage(1), -2);
      expect(rot.rollModifierForStage(5), -6);
      expect(rot.rollModifierForStage(99), -6);
    });

    test('Gelo richiede quattro applicazioni fino a Ibernato', () {
      final frost = oculumConditionDefinition('gelo')!;
      expect(frost.maxStage, 4);
      expect(frost.stackMode, OculumConditionStackMode.increaseStage);
      expect(frost.control, isTrue);
    });

    test('Stordito dura un turno anche a difficolta estrema', () {
      final stun = oculumConditionDefinition('stordito')!;
      expect(stun.defaultDuration, 1);
      expect(stun.difficultyScaling, OculumConditionDifficultyScaling.none);
      expect(stun.control, isTrue);
    });

    test('Aumento difficolta e una condizione a turni con scala custom', () {
      final increase = oculumConditionDefinition('aumento_difficolta')!;
      expect(increase.durationType, OculumConditionDurationType.turns);
      expect(increase.tickTrigger, OculumConditionTickTrigger.endTurn);
      expect(
        increase.difficultyScaling,
        OculumConditionDifficultyScaling.custom,
      );
      expect(increase.defaultDuration, 0);
    });

    test('Frattura ed Esaurimento non sono staccabili', () {
      expect(oculumConditionDefinition('frattura')!.removable, isFalse);
      expect(oculumConditionDefinition('esaurimento')!.removable, isFalse);
    });

    test('Veleno Putrido e Sanguinamento fanno Tick a fine turno', () {
      expect(
        oculumConditionDefinition('veleno_putrido')!.tickTrigger,
        OculumConditionTickTrigger.endTurn,
      );
      expect(
        oculumConditionDefinition('sanguinamento')!.tickTrigger,
        OculumConditionTickTrigger.endTurn,
      );
      final rotPoison = oculumConditionDefinition('veleno_putrido')!;
      expect(rotPoison.stackMode, OculumConditionStackMode.increaseStage);
      expect(rotPoison.maxStage, 9);
      expect(rotPoison.basePercentByStage, <double>[
        1,
        2,
        4,
        6,
        9,
        13,
        18,
        25,
        33,
      ]);
      expect(rotPoison.durationByStage, <int>[3, 4, 5, 6, 7, 8, 9, 10, 12]);
      expect(rotPoison.durationForStage(1), 3);
      expect(rotPoison.durationForStage(9), 12);
      expect(rotPoison.percentForStage(9), 33);
      expect(
        rotPoison.difficultyScaling,
        OculumConditionDifficultyScaling.damageAndDuration,
      );
    });

    test('stack identici non sono increaseStacks per i buff', () {
      for (final id in <String>['vulnerabile', 'fortificato', 'potenziato']) {
        expect(
          oculumConditionDefinition(id)!.stackMode,
          OculumConditionStackMode.refreshDuration,
        );
      }
    });

    test('ogni condizione automatica dannosa mantiene una via di fuga', () {
      final damaging = oculumConditionCatalog.where(
        (condition) => condition.basePercentByStage.isNotEmpty,
      );
      expect(damaging, isNotEmpty);
      for (final condition in damaging) {
        expect(condition.removable, isTrue, reason: condition.id);
        expect(condition.defaultDuration, greaterThan(0), reason: condition.id);
        expect(
          condition.tickTrigger,
          isNot(OculumConditionTickTrigger.none),
          reason: condition.id,
        );
      }
    });

    test('nessuna condizione del catalogo usa più stack numerici', () {
      final stacked = oculumConditionCatalog.where(
        (condition) =>
            condition.stackMode == OculumConditionStackMode.increaseStacks,
      );
      expect(stacked, isEmpty);
    });

    test('i numeri romani arrivano fino a IX', () {
      expect(
        List<String>.generate(9, (index) => oculumRomanStage(index + 1)),
        <String>['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX'],
      );
    });
  });

  group('Persistenza retrocompatibile', () {
    test(
      'ConditionInstance conserva identita stadio stack durata e metadati',
      () {
        final original = OculumConditionInstance(
          id: 'bleed-1',
          conditionType: 'sanguinamento',
          category: OculumConditionCategory.physical,
          stage: 3,
          stacks: 1,
          duration: 4,
          tickTrigger: OculumConditionTickTrigger.endTurn,
          removable: true,
          source: 'Morso del Divoratore',
          metadata: <String, dynamic>{'scope': 'physical'},
        );
        final restored = OculumConditionInstance.fromJson(
          jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
        );
        expect(restored.id, original.id);
        expect(restored.conditionType, original.conditionType);
        expect(restored.stage, 3);
        expect(restored.duration, 4);
        expect(restored.source, 'Morso del Divoratore');
        expect(restored.metadata['scope'], 'physical');
      },
    );

    test('vecchi dati minimi ricevono default sicuri', () {
      final restored = OculumConditionInstance.fromJson(<String, dynamic>{
        'type': 'putrido',
      });
      expect(restored.conditionType, 'putrido');
      expect(restored.stage, 1);
      expect(restored.stacks, 1);
      expect(restored.duration, 0);
      expect(restored.removable, isTrue);
    });

    test('condizione custom non scala per default', () {
      final restored = OculumConditionInstance.fromJson(<String, dynamic>{
        'conditionType': 'custom_nebbia',
        'metadata': <String, dynamic>{'name': 'Nebbia', 'percent': 5},
      });
      expect(restored.metadata['difficultyScaling'], isNull);
    });

    test('condizione custom puo dichiarare scaling esplicito', () {
      final restored = OculumConditionInstance.fromJson(<String, dynamic>{
        'conditionType': 'custom_acido',
        'metadata': <String, dynamic>{'difficultyScaling': 'damageAndDuration'},
      });
      expect(restored.metadata['difficultyScaling'], 'damageAndDuration');
    });

    test('cambio difficolta non muta la condizione serializzata', () {
      final condition = OculumConditionInstance(
        id: 'same',
        conditionType: 'sanguinamento',
        category: OculumConditionCategory.physical,
        stage: 2,
        duration: 3,
      );
      final before = jsonEncode(condition.toJson());
      oculumConditionDifficultyProfile('oculum');
      expect(jsonEncode(condition.toJson()), before);
    });
  });

  group('Azzeramento delle vulnerabilita', () {
    test('rimuove condizioni negative e conserva positive e neutrali', () {
      final conditions = <OculumConditionInstance>[
        OculumConditionInstance(
          id: 'poison',
          conditionType: 'veleno_putrido',
          category: OculumConditionCategory.physical,
        ),
        OculumConditionInstance(
          id: 'fracture',
          conditionType: 'frattura',
          category: OculumConditionCategory.physical,
          removable: false,
        ),
        OculumConditionInstance(
          id: 'fortified',
          conditionType: 'fortificato',
          category: OculumConditionCategory.positive,
        ),
        OculumConditionInstance(
          id: 'overload',
          conditionType: 'sovraccarico',
          category: OculumConditionCategory.oculum,
        ),
      ];

      expect(oculumRemoveNegativeConditions(conditions), 2);
      expect(conditions.map((condition) => condition.conditionType), <String>[
        'fortificato',
        'sovraccarico',
      ]);
    });

    test('riconosce anche condizioni personalizzate negative', () {
      final conditions = <OculumConditionInstance>[
        OculumConditionInstance(
          id: 'custom-negative',
          conditionType: 'custom_maledizione',
          category: OculumConditionCategory.special,
          metadata: <String, dynamic>{'polarity': 'negative'},
        ),
        OculumConditionInstance(
          id: 'custom-positive',
          conditionType: 'custom_benedizione',
          category: OculumConditionCategory.special,
          metadata: <String, dynamic>{'polarity': 'positive'},
        ),
      ];

      expect(oculumRemoveNegativeConditions(conditions), 1);
      expect(conditions.single.id, 'custom-positive');
    });
  });

  group('Target granulari e differenza Fight', () {
    test('ogni condizione di catalogo dichiara almeno un target', () {
      for (final definition in oculumConditionCatalog) {
        expect(
          definition.affectedTargets,
          isNotEmpty,
          reason: '${definition.id} deve notificare soltanto sezioni note',
        );
      }
    });

    test('i buff positivi sono piu forti alle difficolta basse', () {
      final easy = oculumPositiveConditionMultiplier('facile');
      final normal = oculumPositiveConditionMultiplier('normale');
      final hard = oculumPositiveConditionMultiplier('difficile');
      final oculum = oculumPositiveConditionMultiplier('oculum');
      expect(easy, greaterThan(normal));
      expect(normal, greaterThan(hard));
      expect(hard, greaterThan(oculum));
      expect(oculum, 1);
    });

    test('aumento difficolta usa uno stadio per livello di differenza', () {
      expect(
        oculumDifficultyIncreaseStages(
          characterDifficulty: 'oculum',
          enemyDifficulty: 'facile',
        ),
        3,
      );
      expect(
        oculumDifficultyIncreaseStages(
          characterDifficulty: 'difficile',
          enemyDifficulty: 'normale',
        ),
        1,
      );
      expect(
        oculumDifficultyIncreaseStages(
          characterDifficulty: 'facile',
          enemyDifficulty: 'oculum',
        ),
        0,
      );
    });

    test('lo stato Fight dichiara HP Difesa e Combattimento', () {
      final definition = oculumConditionDefinition('aumento_difficolta')!;
      expect(definition.maxStage, 3);
      expect(
        definition.affectedTargets,
        containsAll(<OculumConditionTarget>{
          OculumConditionTarget.hp,
          OculumConditionTarget.difesa,
          OculumConditionTarget.vc,
          OculumConditionTarget.cm,
          OculumConditionTarget.tiri,
          OculumConditionTarget.scudo,
          OculumConditionTarget.scudoOculum,
          OculumConditionTarget.combattimento,
        }),
      );
    });

    test('penalita e danno crescono di tre per livello', () {
      expect(oculumDifficultyIncreaseFightPenalty(0), 0);
      expect(oculumDifficultyIncreaseFightPenalty(1), -3);
      expect(oculumDifficultyIncreaseFightPenalty(3), -9);
      expect(oculumDifficultyIncreaseIncomingDamageBonus(100, 1), 3);
      expect(oculumDifficultyIncreaseIncomingDamageBonus(100, 3), 9);
    });

    test('i pacchetti Fight rispettano le quattro modalita', () {
      final easy = oculumDifficultyIncreaseFightProfile('facile');
      final normal = oculumDifficultyIncreaseFightProfile('normale');
      final hard = oculumDifficultyIncreaseFightProfile('difficile');
      final oculum = oculumDifficultyIncreaseFightProfile('oculum');

      expect(easy.fortunaPercent, 6);
      expect(easy.fortunaUntilHpLoss, isTrue);
      expect(normal.beyondDefenseChance, 5);
      expect(normal.beyondShieldChance, 10);
      expect(normal.fortunaPercent, 5);
      expect(hard.shieldDivisor, 4);
      expect(hard.fortunaPercent, 10);
      expect(hard.inspirationType, 'super');
      expect(oculum.shieldDivisor, 6);
      expect(oculum.usesOculumShield, isTrue);
      expect(oculum.beyondDefenseChance, 30);
      expect(oculum.beyondShieldChance, 50);
      expect(oculum.fortunaPercent, 15);
      expect(oculum.oculumDodgeBonus, 1);
      expect(oculum.inspirationType, 'oculum');
    });

    test('la durata accetta turni fissi e dadi con critico rapido', () {
      final fixed = oculumRollConditionDuration(
        '7 turni',
        nextInt: (_) => 0,
        criticalModifier: (_, _) => 0,
      )!;
      expect(fixed.turns, 7);
      expect(fixed.formula, isEmpty);

      final criticalMax = oculumRollConditionDuration(
        '1d10 turni',
        nextInt: (_) => 9,
        criticalModifier: (roll, faces) => roll == faces ? 5 : 0,
      )!;
      expect(criticalMax.turns, 15);
      expect(criticalMax.criticalMax, isTrue);
      expect(criticalMax.formula, contains('10+5'));

      final criticalOne = oculumRollConditionDuration(
        '1d10',
        nextInt: (_) => 0,
        criticalModifier: (roll, _) => roll == 1 ? -5 : 0,
      )!;
      expect(criticalOne.turns, 0);
      expect(criticalOne.criticalOne, isTrue);
      expect(
        oculumRollConditionDuration(
          'non valido',
          nextInt: (_) => 0,
          criticalModifier: (_, _) => 0,
        ),
        isNull,
      );
    });

    test('il parser @effetto legge durata fissa o a dadi con segno', () {
      final commands = oculumParseEffectCommands(
        '@effetto:Confusione(1d10+2) '
        '@effetto:"Occhio velato" 2d6-1 turni',
      );
      expect(commands, hasLength(2));
      expect(commands[0].name, 'Confusione');
      expect(commands[0].durationFormula, '1d10+2');
      expect(commands[1].name, 'Occhio velato');
      expect(commands[1].durationFormula, '2d6-1');
    });

    test('il parser @effetto accetta un effetto senza durata', () {
      final commands = oculumParseEffectCommands('@effetto:Brucia');
      expect(commands.single.name, 'Brucia');
      expect(commands.single.durationFormula, isEmpty);
    });

    test('il parser @effetto funziona dentro JSON e mappe serializzate', () {
      final commands = oculumParseEffectCommands(
        '{buff: @effetto:Confusione(1d10+2), tipo: Skill}',
      );
      expect(commands.single.name, 'Confusione');
      expect(commands.single.durationFormula, '1d10+2');
    });
  });
}
