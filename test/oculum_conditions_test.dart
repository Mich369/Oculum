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
    test('Vita Afona e registrata come condizione HP negativa', () {
      final vitaAfona = oculumConditionDefinition('vita_afona');
      expect(vitaAfona?.nameIt, 'Vita Afona');
      expect(vitaAfona?.affectedTargets, contains(OculumConditionTarget.hp));
      expect(vitaAfona?.defaultDuration, 3);
      expect(vitaAfona?.tickTrigger, OculumConditionTickTrigger.endTurn);
    });

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
    test('Ricordo Vitale aumenta il danno e rigenera a quarti', () {
      expect(oculumVitalMemoryIncomingDamage(4), 5);
      expect(oculumVitalMemoryIncomingDamage(1), 2);
      expect(oculumVitalMemoryRecoveryForDamage(5), (total: 2, perTick: 1));
      expect(oculumVitalMemoryRecoveryForDamage(10), (total: 4, perTick: 2));
      final vitalMemory = oculumConditionDefinition('ricordo_vitale')!;
      expect(vitalMemory.category, OculumConditionCategory.positive);
      expect(vitalMemory.tickTrigger, OculumConditionTickTrigger.endTurn);
      expect(vitalMemory.affectedTargets, contains(OculumConditionTarget.hp));
    });

    test('nuove condizioni hanno effetti percentuali e durate operative', () {
      expect(oculumElectrifiedDamage(100), 3);
      expect(oculumElectrifiedDamage(1), 1);
      expect(oculumRegenerationHealing(100, 1), 3);
      expect(oculumRegenerationHealing(100, 2), 5);
      expect(oculumRegenerationHealing(100, 3), 8);
      expect(oculumCursedHealing(100, 1), 80);
      expect(oculumCursedHealing(100, 2), 65);
      expect(oculumCursedHealing(100, 3), 50);
      expect(oculumCorrosionPercent(1), 10);
      expect(oculumCorrosionPercent(3), 30);

      for (final id in <String>[
        'corroso',
        'bagnato',
        'elettrizzato',
        'maledetto',
        'marchiato',
        'interferenza',
        'rigenerazione',
        'barriera_mentale',
        'ancorato',
      ]) {
        final definition = oculumConditionDefinition(id);
        expect(definition, isNotNull, reason: id);
      }

      final electrified = oculumConditionDefinition('elettrizzato')!;
      expect(electrified.tickTrigger, OculumConditionTickTrigger.endTurn);
      expect(electrified.defaultDuration, 3);
      expect(
        electrified.affectedTargets,
        containsAll(<OculumConditionTarget>[
          OculumConditionTarget.hp,
          OculumConditionTarget.recupero,
        ]),
      );

      final regeneration = oculumConditionDefinition('rigenerazione')!;
      expect(regeneration.basePercentByStage, <double>[3, 5, 8]);
      expect(regeneration.durationType, OculumConditionDurationType.turns);
      expect(regeneration.polarity, OculumConditionPolarity.positive);

      final interference = oculumConditionDefinition('interferenza')!;
      expect(interference.rollModifierByStage, <int>[-2, -4, -6]);
      expect(interference.maxStage, 3);
    });

    test(
      'Vero Bruciore richiede Resilienza in Fiamme allo stadio II o III',
      () {
        final stageOne = OculumConditionInstance(
          id: 'flame_i',
          conditionType: 'resilienza_in_fiamme',
          category: OculumConditionCategory.oculum,
          stage: 1,
        );
        final stageTwo = OculumConditionInstance(
          id: 'flame_ii',
          conditionType: 'resilienza_in_fiamme',
          category: OculumConditionCategory.oculum,
          stage: 2,
        );

        expect(
          oculumCanMaintainTrueSoulBurn(<OculumConditionInstance>[]),
          isFalse,
        );
        expect(
          oculumCanMaintainTrueSoulBurn(<OculumConditionInstance>[stageOne]),
          isFalse,
        );
        expect(
          oculumCanMaintainTrueSoulBurn(<OculumConditionInstance>[stageTwo]),
          isTrue,
        );
      },
    );

    test('le tre condizioni Oculum in Fiamme seguono costi e difficolta', () {
      expect(oculumFlameTurnCost(0), 0);
      expect(oculumFlameTurnCost(1), 1);
      expect(oculumFlameTurnCost(34), 1);
      expect(oculumFlameTurnCost(67), 2);
      expect(oculumFlameTurnPercent(1), 3);
      expect(oculumFlameTurnPercent(2), 4);
      expect(oculumFlameTurnPercent(3), 5);
      expect(oculumFlameTurnCost(100, stage: 2), 4);
      expect(oculumFlameTurnCost(100, stage: 3), 5);
      expect(
        oculumFlameEndsAtLowOculum(currentOculum: 15, maximumOculum: 100),
        isTrue,
      );
      expect(
        oculumFlameEndsAtLowOculum(currentOculum: 16, maximumOculum: 100),
        isFalse,
      );

      expect(oculumFlameRewardMultiplier('facile'), 2);
      expect(oculumFlameRewardMultiplier('normale'), 1.5);
      expect(oculumFlameRewardMultiplier('difficile'), 1.3);
      expect(oculumFlameRewardMultiplier('oculum'), 1);
      expect(oculumFlameReward(2, 'facile'), 4);
      expect(oculumFlameReward(2, 'normale'), 3);
      expect(oculumFlameReward(2, 'difficile'), 3);
      expect(oculumFlameReward(2, 'oculum'), 2);

      for (final id in <String>[
        'resilienza_in_fiamme',
        'volonta_in_fiamme',
        'materia_in_fiamme',
      ]) {
        final definition = oculumConditionDefinition(id);
        expect(definition, isNotNull);
        expect(definition!.tickTrigger, OculumConditionTickTrigger.endTurn);
        expect(definition.durationType, OculumConditionDurationType.permanent);
        expect(definition.maxStage, 3);
        expect(definition.stackMode, OculumConditionStackMode.increaseStage);
        expect(definition.basePercentByStage, <double>[3, 4, 5]);
        expect(
          definition.affectedTargets,
          contains(OculumConditionTarget.oculum),
        );
      }
      expect(
        oculumConditionDefinition('resilienza_in_fiamme')!.affectedTargets,
        containsAll(<OculumConditionTarget>[
          OculumConditionTarget.hp,
          OculumConditionTarget.recupero,
        ]),
      );
      expect(
        oculumConditionDefinition('volonta_in_fiamme')!.affectedTargets,
        containsAll(<OculumConditionTarget>[
          OculumConditionTarget.volonta,
          OculumConditionTarget.recupero,
        ]),
      );
      expect(
        oculumConditionDefinition('materia_in_fiamme')!.affectedTargets,
        containsAll(<OculumConditionTarget>[
          OculumConditionTarget.materia,
          OculumConditionTarget.recupero,
        ]),
      );
    });

    test('Oculum in Fiamme conserva tre fasi e conversione al 3 percento', () {
      expect(oculumVioletFlameThreePercentCost(0), 0);
      expect(oculumVioletFlameThreePercentCost(1), 1);
      expect(oculumVioletFlameThreePercentCost(100), 3);
      expect(oculumVioletFlameRegeneration(1), 1);
      expect(oculumVioletFlameRegeneration(30), 3);
      expect(oculumVioletFlameDiversionChance(1), 10);
      expect(oculumVioletFlameDiversionChance(2), 20);
      expect(oculumVioletFlameDiversionChance(3), 30);

      final violet = oculumConditionDefinition('oculum_in_fiamme_viola')!;
      expect(violet.maxStage, 3);
      expect(violet.tickTrigger, OculumConditionTickTrigger.endTurn);
      expect(violet.category, OculumConditionCategory.oculum);
      expect(
        violet.affectedTargets,
        containsAll(<OculumConditionTarget>[
          OculumConditionTarget.hp,
          OculumConditionTarget.oculum,
          OculumConditionTarget.volonta,
          OculumConditionTarget.materia,
          OculumConditionTarget.art,
        ]),
      );
    });

    test(
      'Massima Potenza usa il 25 percento di Oculum e il 15 percento Art',
      () {
        expect(oculumMaximumPowerOculumCost(0), 0);
        expect(oculumMaximumPowerOculumCost(1), 1);
        expect(oculumMaximumPowerOculumCost(100), 25);
        expect(oculumMaximumPowerHpFallbackHits(100), <int>[7, 6, 6, 6]);
        expect(
          oculumMaximumPowerHpFallbackHits(100).reduce((a, b) => a + b),
          25,
        );
        expect(oculumMaximumPowerIntegrityCost(0), 0);
        expect(oculumMaximumPowerIntegrityCost(1), 1);
        expect(oculumMaximumPowerIntegrityCost(100), 15);

        final maximumPower = oculumConditionDefinition('massima_potenza')!;
        expect(maximumPower.category, OculumConditionCategory.positive);
        expect(maximumPower.maxStage, 6);
        expect(
          maximumPower.durationType,
          OculumConditionDurationType.permanent,
        );
        expect(
          maximumPower.affectedTargets,
          containsAll(<OculumConditionTarget>[
            OculumConditionTarget.resilienza,
            OculumConditionTarget.volonta,
            OculumConditionTarget.materia,
            OculumConditionTarget.art,
          ]),
        );
      },
    );

    test('la cura standard conserva il valore oltre gli HP massimi', () {
      final healed = healOculumHp(
        current: 8,
        maximum: 10,
        temporary: 0,
        amount: 5,
      );

      expect(healed.current, 10);
      expect(healed.temporary, 3);
    });

    test(
      'Resilienza in Fiamme indica gli HP temporanei dagli stadi II e III',
      () {
        final resilienceAblaze = oculumConditionDefinition(
          'resilienza_in_fiamme',
        )!;

        expect(resilienceAblaze.descriptionIt, contains('stadi II e III'));
        expect(resilienceAblaze.descriptionEn, contains('stages II and III'));
      },
    );

    test('contiene tutte le famiglie definitive', () {
      expect(oculumConditionCatalog.length, greaterThanOrEqualTo(30));
      expect(
        oculumConditionCatalog.map((item) => item.id).toSet().length,
        oculumConditionCatalog.length,
      );
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

    test(
      'Rinsecchito e una condizione fisica e lascia un quarto della Difesa',
      () {
        final desiccated = oculumConditionDefinition('rinsecchito')!;
        expect(desiccated.category, OculumConditionCategory.physical);
        expect(desiccated.polarity, OculumConditionPolarity.negative);
        expect(desiccated.basePercentByStage, <double>[75]);
        expect(
          desiccated.affectedTargets,
          contains(OculumConditionTarget.difesa),
        );
      },
    );

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
        (condition) =>
            condition.basePercentByStage.isNotEmpty &&
            condition.polarity == OculumConditionPolarity.negative,
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
