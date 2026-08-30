import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('Forza usa sempre meta della Volonta e resta serializzabile', () {
    expect(
      oculumHiddenEyeDerivedBonusFor(
        id: 'forza',
        resilienza: 99,
        volonta: 11,
        materia: 80,
        oculum: 70,
        karma: 60,
      ),
      5,
    );
    expect(
      oculumHiddenEyeDerivedBonusFor(
        id: 'forza',
        resilienza: 0,
        volonta: 12,
        materia: 0,
        oculum: 0,
        karma: 0,
      ),
      6,
    );

    final restored = HiddenEyeStat.fromJson(
      HiddenEyeStat(
        id: 'forza',
        nome: 'Forza',
        descrizione: 'Bonus base: Volonta/2.',
        valore: 3,
        masteryProgress: 17,
      ).toJson(),
    );
    expect(restored.id, 'forza');
    expect(restored.valore, 3);
    expect(restored.masteryProgress, 17);
  });

  test('Nodo usa tutto il Karma ricevuto, inclusi i buff dei titoli', () {
    expect(
      oculumHiddenEyeDerivedBonusFor(
        id: 'nodo',
        resilienza: 99,
        volonta: 99,
        materia: 99,
        oculum: 99,
        karma: 17,
      ),
      17,
    );
    expect(
      oculumHiddenEyeDerivedBonusFor(
        id: 'nodo',
        resilienza: 0,
        volonta: 0,
        materia: 0,
        oculum: 0,
        karma: -8,
      ),
      -8,
    );
  });

  test('calcola soglia e guadagno maestria dei sottotratti Oculus', () {
    const expectedTargets = <int>[
      33,
      36,
      63,
      69,
      96,
      100,
      120,
      160,
      236,
      296,
      300,
      369,
      396,
      436,
      469,
      536,
      596,
      639,
      663,
      669,
      693,
      700,
      703,
      736,
      769,
      836,
      869,
      896,
      900,
      903,
      906,
      909,
    ];
    for (var grade = 0; grade < expectedTargets.length; grade++) {
      expect(
        oculusSubtraitMasteryTargetForGrade(grade),
        expectedTargets[grade],
        reason: 'soglia Base $grade -> ${grade + 1}',
      );
    }
    const lateDigits = <int>[3, 6, 9];
    var grade = expectedTargets.length;
    for (var decade = 91; decade <= 99; decade++) {
      for (final digit in lateDigits) {
        expect(
          oculusSubtraitMasteryTargetForGrade(grade),
          decade * 10 + digit,
          reason: 'soglia Base $grade -> ${grade + 1}',
        );
        grade++;
      }
    }
    expect(oculusSubtraitMasteryTargetForGrade(58), 999);
    expect(oculusSubtraitMasteryTargetForGrade(59), 1000);
    expect(oculusSubtraitMasteryTargetForGrade(99), 1000);
    expect(oculusSubtraitMasteryTargetForGrade(-1), 33);

    expect(oculusSubtraitMasteryGainForDie(14), 0);
    expect(oculusSubtraitMasteryGainForDie(15), 15);
    expect(oculusSubtraitMasteryGainForDie(19), 19);
    expect(oculusSubtraitMasteryGainForDie(20), 60);

    expect(oculusSubtraitMasteryGainForDieAndGrade(14, 5), 0);
    expect(oculusSubtraitMasteryGainForDieAndGrade(15, 0), 15);
    expect(oculusSubtraitMasteryGainForDieAndGrade(15, 1), 35);
    expect(oculusSubtraitMasteryGainForDieAndGrade(19, 3), 79);
    expect(oculusSubtraitMasteryGainForDieAndGrade(20, 5), 160);
    expect(oculusSubtraitMasteryGainForDieAndGrade(20, -3), 60);
  });

  test('mantiene avanzo quando la barra maestria si completa', () {
    final stat = HiddenEyeStat(
      id: 'velo',
      nome: 'Velo',
      descrizione: 'Test',
      valore: 0,
      masteryProgress: 30,
    );

    final completed = oculusSubtraitMasteryApplyGain(stat, 60);

    expect(completed, 2);
    expect(stat.valore, 2);
    expect(stat.masteryProgress, 21);
    expect(
      oculusSubtraitMasteryFraction(
        progress: stat.masteryProgress,
        grade: stat.valore,
      ),
      closeTo(21 / 63, 0.0001),
    );
  });

  test('salva il progresso maestria senza perdere il sottotratto', () {
    final stat = HiddenEyeStat(
      id: 'velo',
      nome: 'Velo',
      descrizione: 'Test',
      valore: 2,
      masteryProgress: 600,
    );

    final restored = HiddenEyeStat.fromJson(stat.toJson());

    expect(restored.id, 'velo');
    expect(restored.valore, 2);
    expect(restored.masteryProgress, 600);
    expect(
      oculusSubtraitMasteryFraction(progress: 18, grade: 0),
      closeTo(18 / 33, 0.0001),
    );
  });

  test('carica il vecchio campo maestria dei salvataggi legacy', () {
    final restored = HiddenEyeStat.fromJson({
      'id': 'velo',
      'nome': 'Velo',
      'descrizione': 'Test',
      'valore': 3,
      'unlocked': true,
      'maestria': 42,
    });

    expect(restored.id, 'velo');
    expect(restored.valore, 3);
    expect(restored.masteryProgress, 42);
    expect(restored.toJson()['oculusSubtraitMasteryProgress'], 42);
  });

  test('non serializza cache o stato UI volatile nei sottotratti', () {
    final stat = HiddenEyeStat(
      id: 'velo',
      nome: 'Velo',
      descrizione: 'Test',
      valore: 4,
      masteryProgress: 99,
    );

    final json = stat.toJson();

    expect(
      json.keys,
      containsAll(<String>[
        'id',
        'nome',
        'descrizione',
        'valore',
        'unlocked',
        'oculusSubtraitMasteryProgress',
      ]),
    );
    expect(
      json.keys.any((key) => key.toLowerCase().contains('cache')),
      isFalse,
    );
    expect(
      json.keys.any((key) => key.toLowerCase().contains('revision')),
      isFalse,
    );
  });

  test('gestisce guadagni rapidi ripetuti senza perdere avanzo', () {
    final stat = HiddenEyeStat(
      id: 'velo',
      nome: 'Velo',
      descrizione: 'Test',
      valore: 0,
    );

    var completed = 0;
    for (var i = 0; i < 40; i++) {
      completed += oculusSubtraitMasteryApplyGain(stat, 60);
      final target = oculusSubtraitMasteryTargetForValue(stat.valore);
      expect(stat.masteryProgress, inInclusiveRange(0, target - 1));
    }

    expect(completed, greaterThan(1));
    expect(stat.valore, completed);
  });

  test('accoda gli effetti remoti senza perdere eventi', () async {
    final queue = OculumActionQueue();
    final firstGate = Completer<void>();
    final started = <int>[];

    final first = queue.enqueue('dice', () async {
      started.add(1);
      await firstGate.future;
    });
    final second = queue.enqueue('dice', () async {
      started.add(2);
    });

    await Future<void>.delayed(Duration.zero);
    expect(started, <int>[1]);

    firstGate.complete();
    await Future.wait(<Future<void>>[first, second]);
    expect(started, <int>[1, 2]);
  });

  test(
    'accorpa i salvataggi in corso, conserva l ultimo stato e non sovrappone scritture',
    () async {
      final queue = OculumSaveRequestQueue();
      final firstGate = Completer<void>();
      final writtenStates = <int>[];
      final writeModes = <bool>[];
      var currentState = 1;
      var concurrentWrites = 0;
      var maxConcurrentWrites = 0;

      Future<void> write(bool soloLocal) async {
        concurrentWrites++;
        maxConcurrentWrites = max(maxConcurrentWrites, concurrentWrites);
        writtenStates.add(currentState);
        writeModes.add(soloLocal);
        if (writtenStates.length == 1) await firstGate.future;
        concurrentWrites--;
      }

      final first = queue.enqueue(soloLocal: true, write: write);
      await Future<void>.delayed(Duration.zero);
      currentState = 2;
      final second = queue.enqueue(soloLocal: true, write: write);
      currentState = 3;
      final third = queue.enqueue(soloLocal: false, write: write);

      expect(writtenStates, <int>[1]);
      firstGate.complete();
      await Future.wait(<Future<void>>[first, second, third]);

      expect(writtenStates, <int>[1, 3]);
      expect(writeModes, <bool>[true, false]);
      expect(maxConcurrentWrites, 1);
      expect(queue.isRunning, isFalse);
    },
  );

  test('assegna i nuovi sottotratti alle categorie e usa divisione intera', () {
    expect(oculumHiddenEyeStaticGroupFor('fermezza'), 'volonta');
    expect(oculumHiddenEyeStaticGroupFor('resistenza'), 'resilienza');
    expect(oculumHiddenEyeStaticGroupFor('adattamento'), 'resilienza');
    for (final id in <String>[
      'precisione',
      'meccanica',
      'alchimia',
      'controllo_corporeo',
    ]) {
      expect(oculumHiddenEyeStaticGroupFor(id), 'materia');
      expect(
        oculumHiddenEyeDerivedBonusFor(
          id: id,
          resilienza: 0,
          volonta: 0,
          materia: 11,
          oculum: 0,
          karma: 0,
        ),
        5,
      );
    }
    expect(oculumHiddenEyeStaticGroupFor('canalizzazione'), 'oculum');
    expect(oculumHiddenEyeStaticGroupFor('nodo'), 'altro');
    expect(oculumHiddenEyeStaticGroupFor('fortuna'), 'altro');
    expect(
      oculumHiddenEyeDerivedBonusFor(
        id: 'concentrazione',
        resilienza: 0,
        volonta: 11,
        materia: 0,
        oculum: 0,
        karma: 0,
      ),
      5,
    );

    for (final id in <String>['empatia', 'addestramento', 'performance']) {
      expect(oculumHiddenEyeStaticGroupFor(id), 'volonta');
      expect(
        oculumHiddenEyeDerivedBonusFor(
          id: id,
          resilienza: 0,
          volonta: 11,
          materia: 0,
          oculum: 0,
          karma: 0,
        ),
        5,
      );
    }
    for (final id in <String>['pilotaggio', 'demolizioni', 'valutazione']) {
      expect(oculumHiddenEyeStaticGroupFor(id), 'materia');
      expect(
        oculumHiddenEyeDerivedBonusFor(
          id: id,
          resilienza: 0,
          volonta: 0,
          materia: 11,
          oculum: 0,
          karma: 0,
        ),
        5,
      );
    }
    for (final id in <String>[
      'occultismo',
      'presagio',
      'lettura_aura',
      'sincronia',
      'memoria',
    ]) {
      expect(oculumHiddenEyeStaticGroupFor(id), 'oculum');
      expect(
        oculumHiddenEyeDerivedBonusFor(
          id: id,
          resilienza: 0,
          volonta: 0,
          materia: 0,
          oculum: 11,
          karma: 0,
        ),
        5,
      );
    }
    expect(oculumHiddenEyeStaticGroupFor('investigazione'), 'altro');
    expect(
      oculumHiddenEyeDerivedBonusFor(
        id: 'investigazione',
        resilienza: 0,
        volonta: 9,
        materia: 13,
        oculum: 0,
        karma: 0,
      ),
      6,
    );
    expect(
      oculumHiddenEyeDerivedBonusFor(
        id: 'investigazione',
        resilienza: 0,
        volonta: 15,
        materia: 13,
        oculum: 0,
        karma: 0,
      ),
      7,
    );
    expect(
      oculumInvestigationEffectiveStat(materia: 13, volonta: 9),
      'materia',
    );
    expect(
      oculumInvestigationEffectiveStat(materia: 9, volonta: 15),
      'volonta',
    );
    expect(
      oculumInvestigationEffectiveStat(materia: 10, volonta: 10),
      'materia',
    );
    for (final excluded in <String>['acrobazia', 'comando', 'ritualistica']) {
      expect(oculumHiddenEyeStaticGroupFor(excluded), isNull);
    }
  });

  test(
    'Fortuna calcola dadi, schivata e attenuazione senza superare i limiti',
    () {
      expect(oculumLuckDieSides(1), 2);
      expect(oculumLuckDieSides(3), 4);
      expect(oculumLuckDieSides(110), 120);
      expect(oculumLuckDodgeChancePercent(reflexes: 12, luck: 12), 2);
      expect(oculumLuckMitigationChancePercent(resistance: 20, luck: 30), 5);
      expect(oculumDamageAfterPassiveReduction(damage: 4, reduction: 100), 1);
    },
  );

  test('Fortuna protegge il Nucleo in base al livello Skill', () {
    expect(oculumCoreProtectionChancePercent(luck: 30, skillLevel: 1), 1.5);
    expect(
      oculumCoreProtectionChancePercent(luck: 30, skillLevel: 2),
      closeTo(0.9, 0.000001),
    );
    expect(
      oculumCoreProtectionChancePercent(luck: 30, skillLevel: 3),
      closeTo(0.3, 0.000001),
    );
  });

  test(
    'Concentrazione sceglie il gruppo meno popolato e la parita va a Volonta',
    () {
      expect(
        oculumConcentrationGroupForStatIds(<String>['eco', 'furbizia']),
        'volonta',
      );
      expect(
        oculumConcentrationGroupForStatIds(<String>[
          'eco',
          'forza',
          'furbizia',
        ]),
        'resilienza',
      );
      expect(
        oculumConcentrationGroupForStatIds(<String>[
          'eco',
          'furbizia',
          'strategia',
        ]),
        'volonta',
      );
      expect(
        oculumConcentrationGroupForStatIds(<String>[
          'eco',
          'forza',
          'crepa',
          'pressione',
          'fermezza',
          'furbizia',
          'strategia',
          'sopravvivenza',
          'medicina',
          'resistenza',
          'adattamento',
          'concentrazione',
        ]),
        'volonta',
      );
    },
  );

  test(
    'un vecchio salvataggio mantiene valori e riceve nuovi default a zero',
    () {
      final oldForza = HiddenEyeStat(
        id: 'forza',
        nome: 'Forza',
        descrizione: 'Potenza fisica. Bonus base: Volonta/2.',
        valore: 7,
        masteryProgress: 23,
      );
      final custom = HiddenEyeStat(
        id: 'custom_legacy',
        nome: 'Personalizzato',
        descrizione: 'Da conservare',
        valore: 4,
      );
      final merged = oculumMergeHiddenEyeStatsWithDefaults(
        existing: <HiddenEyeStat>[oldForza, custom],
        defaults: <HiddenEyeStat>[
          HiddenEyeStat(
            id: 'forza',
            nome: 'Forza',
            descrizione: 'Descrizione funzionale. Bonus: Volonta/2.',
          ),
          HiddenEyeStat(
            id: 'adattamento',
            nome: 'Adattamento',
            descrizione: 'Descrizione funzionale. Bonus: Resilienza/2.',
          ),
        ],
      );

      final forza = merged.singleWhere((stat) => stat.id == 'forza');
      final adattamento = merged.singleWhere(
        (stat) => stat.id == 'adattamento',
      );
      expect(forza.valore, 7);
      expect(forza.masteryProgress, 23);
      expect(forza.descrizione, startsWith('Descrizione funzionale'));
      expect(adattamento.valore, 0);
      expect(adattamento.masteryProgress, 0);
      expect(merged.singleWhere((stat) => stat.id == 'custom_legacy'), custom);
    },
  );

  test('il critico di Adattamento usa solo il 20 naturale e non duplica', () {
    final effects = <OculumTemporaryResistanceEffect>[];

    final totalTwentyWithoutNaturalTwenty = oculumApplyAdaptationCritical(
      naturalRoll: 15,
      combatActive: true,
      ownerSheetId: 'SHEET-A',
      effects: effects,
    );
    expect(totalTwentyWithoutNaturalTwenty.isNaturalCritical, isFalse);
    expect(effects, isEmpty);

    final first = oculumApplyAdaptationCritical(
      naturalRoll: 20,
      combatActive: true,
      ownerSheetId: 'SHEET-A',
      effects: effects,
    );
    expect(first.applied, isTrue);
    expect(effects, hasLength(1));
    expect(effects.single.isAdaptationAllDamageCurrentCombat, isTrue);

    final second = oculumApplyAdaptationCritical(
      naturalRoll: 20,
      combatActive: true,
      ownerSheetId: 'SHEET-A',
      effects: effects,
    );
    expect(second.alreadyActive, isTrue);
    expect(effects, hasLength(1));

    oculumApplyAdaptationCritical(
      naturalRoll: 20,
      combatActive: true,
      ownerSheetId: 'SHEET-B',
      effects: effects,
    );
    expect(effects, hasLength(2));
  });

  test(
    'Adattamento fuori fight non applica effetti e la fine fight li rimuove',
    () {
      final effects = <OculumTemporaryResistanceEffect>[];
      final outsideCombat = oculumApplyAdaptationCritical(
        naturalRoll: 20,
        combatActive: false,
        ownerSheetId: 'SHEET-A',
        effects: effects,
      );
      expect(outsideCombat.isNaturalCritical, isTrue);
      expect(outsideCombat.applied, isFalse);
      expect(effects, isEmpty);

      oculumApplyAdaptationCritical(
        naturalRoll: 20,
        combatActive: true,
        ownerSheetId: 'SHEET-A',
        effects: effects,
      );
      expect(oculumRemoveCurrentCombatTemporaryEffects(effects), 1);
      expect(effects, isEmpty);
    },
  );

  test('serializza lo stato temporaneo solo con metadati di combattimento', () {
    final effects = <OculumTemporaryResistanceEffect>[];
    oculumApplyAdaptationCritical(
      naturalRoll: 20,
      combatActive: true,
      ownerSheetId: 'SHEET-A',
      effects: effects,
    );
    final json = effects.single.toJson();
    final restored = OculumTemporaryResistanceEffect.fromJson(json);

    expect(restored.id, oculumAdaptationResistanceEffectId);
    expect(restored.ownerSheetId, 'SHEET-A');
    expect(restored.origin, 'Adattamento');
    expect(restored.type, 'temporaneo');
    expect(restored.duration, 'combattimento_corrente');
    expect(restored.coverage, 'tutti_i_tipi_di_danno');
    expect(restored.isAdaptationAllDamageCurrentCombat, isTrue);
  });
}
