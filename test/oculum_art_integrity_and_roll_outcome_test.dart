import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  group('integrita Art', () {
    test('Min e Max supportano tutte le quattro statistiche', () {
      expect(
        oculumArtSkillCostResourceKeys,
        containsAll(<String>['resilienza', 'volonta', 'materia', 'oculum']),
      );
      for (final resource in <String>[
        'resilienza',
        'volonta',
        'materia',
        'oculum',
      ]) {
        expect(oculumNormalizeArtSkillCostResource(resource), resource);
      }
    });

    test('il massimo segue livello e grado senza valori negativi', () {
      expect(oculumArtMaximumValue(level: 0, grade: 0), 100);
      expect(oculumArtMaximumValue(level: 3, grade: 2), 360);
      expect(oculumArtMaximumValue(level: -4, grade: -2), 100);
    });

    test('il riposo lungo recupera un quarto arrotondato una sola volta', () {
      expect(oculumArtLongRestRecovery(100), 25);
      expect(oculumArtLongRestRecovery(101), 26);
      expect(oculumArtLongRestRecovery(103), 26);
      expect(oculumArtRecoveredValue(current: 90, maximum: 101), 101);
    });

    test('il primo riposo dopo esaurimento recupera 10 percento', () {
      expect(
        oculumArtLongRestRecovery(100, limitedAfterFullExhaustion: true),
        10,
      );
      final firstRest = oculumArtRecoveredValue(
        current: 0,
        maximum: 100,
        limitedAfterFullExhaustion: true,
      );
      expect(firstRest, 10);
      expect(oculumArtRecoveredValue(current: firstRest, maximum: 100), 35);
    });

    test('il costo raddoppia una sola volta da Difficile in poi', () {
      expect(oculumArtUseCostForDifficulty(10, 'facile'), 10);
      expect(oculumArtUseCostForDifficulty(10, 'normale'), 10);
      expect(oculumArtUseCostForDifficulty(10, 'difficile'), 20);
      expect(oculumArtUseCostForDifficulty(10, 'hard'), 20);
      expect(oculumArtUseCostForDifficulty(10, 'oculum'), 20);
      expect(oculumArtUseCostForDifficulty(30, 'difficile'), 60);
      expect(oculumArtUseCostForDifficulty(30, 'oculum'), 60);
    });

    test('le probabilita DT cambiano per difficolta senza sommarsi', () {
      final normal = oculumArtLowIntegrityDebuffChances('normale');
      expect(normal.plusOneDt, 10);
      expect(normal.plusThreeDt, 5);

      final hard = oculumArtLowIntegrityDebuffChances('difficile');
      expect(hard.plusOneDt, 15);
      expect(hard.plusThreeDt, 10);

      final oculum = oculumArtLowIntegrityDebuffChances('oculum');
      expect(oculum.plusOneDt, 20);
      expect(oculum.plusThreeDt, 15);
    });

    test('gli esiti DT sono esclusivi e rispettano i confini', () {
      expect(oculumArtLowIntegrityDtForRoll(roll: 9, difficulty: 'normale'), 1);
      expect(
        oculumArtLowIntegrityDtForRoll(roll: 10, difficulty: 'normale'),
        3,
      );
      expect(
        oculumArtLowIntegrityDtForRoll(roll: 14, difficulty: 'normale'),
        3,
      );
      expect(
        oculumArtLowIntegrityDtForRoll(roll: 15, difficulty: 'normale'),
        0,
      );
      expect(oculumArtLowIntegrityDtForRoll(roll: 19, difficulty: 'oculum'), 1);
      expect(oculumArtLowIntegrityDtForRoll(roll: 20, difficulty: 'oculum'), 3);
      expect(oculumArtLowIntegrityDtForRoll(roll: 34, difficulty: 'oculum'), 3);
      expect(oculumArtLowIntegrityDtForRoll(roll: 35, difficulty: 'oculum'), 0);
    });

    test('il controllo DT si attiva solo al 25 percento o meno', () {
      expect(
        oculumArtIsAtOrBelowLowIntegrity(current: 26, maximum: 100),
        isFalse,
      );
      expect(
        oculumArtIsAtOrBelowLowIntegrity(current: 25, maximum: 100),
        isTrue,
      );
      expect(
        oculumArtIsAtOrBelowLowIntegrity(current: 0, maximum: 100),
        isTrue,
      );
    });

    test('i costi Skill seguono la distanza fra le forme attive', () {
      int cost(int previous, int next) => oculumArtSkillLevelChangeCost(
        previousLevel: previous,
        nextLevel: next,
      );

      expect(cost(0, 1), 10);
      expect(cost(0, 2), 20);
      expect(cost(1, 2), 10);
      expect(cost(0, 3), 30);
      expect(cost(1, 3), 20);
      expect(cost(2, 3), 10);
      expect(cost(3, 2), 10);
      expect(cost(2, 1), 10);
      expect(cost(3, 1), 20);
      expect(cost(1, 0), 0);
    });

    test('l integrita Art sottrae il costo progressivo richiesto', () {
      expect(oculumArtValueAfterActivation(100, cost: 30), 70);
      expect(oculumArtValueAfterActivation(20, cost: 20), 0);
      expect(oculumArtValueAfterActivation(19, cost: 20), 19);
      expect(oculumArtValueAfterActivation(4), 4);
    });

    test('l Art resta bloccata finche non ha i 10 punti richiesti', () {
      expect(oculumArtCanActivate(9), isFalse);
      expect(oculumArtCanActivate(10), isTrue);
      expect(oculumArtCanActivate(11), isTrue);
      expect(oculumArtCanActivate(19, cost: 20), isFalse);
      expect(oculumArtCanActivate(20, cost: 20), isTrue);
      expect(oculumArtCanActivate(29, cost: 30), isFalse);
      expect(oculumArtCanActivate(30, cost: 30), isTrue);
    });

    test('le Skill nuove e legacy senza livello partono disattivate', () {
      final newSkill = ArtSkill(nome: 'Nuova Skill');
      final legacySkill = ArtSkill.fromJson(<String, dynamic>{
        'nome': 'Skill legacy',
      });
      expect(newSkill.livello, 0);
      expect(legacySkill.livello, 0);
      expect(legacySkill.oculumMinimiPerLivello, <int>[0, 0, 0, 0, 0]);
      expect(legacySkill.oculumMassimiPerLivello, <int>[0, 0, 0, 0, 0]);
      expect(legacySkill.oculumMassimiInizialiPerLivello, <int>[0, 0, 0, 0, 0]);
      expect(legacySkill.costoOculumDisabilitatoPerLivello, <bool>[
        false,
        false,
        false,
        false,
        false,
      ]);
      expect(legacySkill.risorseCostoPerLivello, <String>[
        'oculum',
        'oculum',
        'oculum',
        'oculum',
        'oculum',
      ]);
    });

    test('ogni evoluzione conserva il costo Oculum disabilitato', () {
      final skill = ArtSkill(
        nome: 'Evoluzioni gratuite',
        costoOculumDisabilitatoPerLivello: <bool>[
          false,
          true,
          false,
          true,
          true,
        ],
      );

      final restored = ArtSkill.fromJson(skill.toJson());
      expect(restored.costoOculumDisabilitato(1), isFalse);
      expect(restored.costoOculumDisabilitato(2), isTrue);
      expect(restored.costoOculumDisabilitato(3), isFalse);
      expect(restored.costoOculumDisabilitato(4), isTrue);
      expect(restored.costoOculumDisabilitato(5), isTrue);

      restored.impostaCostoOculumDisabilitato(3, true);
      expect(restored.costoOculumDisabilitato(3), isTrue);
      expect(restored.costoOculumDisabilitato(2), isTrue);
      expect(restored.risorsaCostoPerLivello(2), 'nessuna');
      expect(restored.risorsaCostoPerLivello(3), 'nessuna');
    });

    test('ogni evoluzione conserva la statistica consumata', () {
      final skill = ArtSkill(
        nome: 'Via marziale',
        risorseCostoPerLivello: <String>[
          'materia',
          'volonta',
          'resilienza',
          'nessuna',
          'oculum',
        ],
      );

      final restored = ArtSkill.fromJson(skill.toJson());
      expect(restored.risorseCostoPerLivello, <String>[
        'materia',
        'volonta',
        'resilienza',
        'nessuna',
        'oculum',
      ]);
      expect(restored.costoOculumDisabilitatoPerLivello, <bool>[
        true,
        true,
        true,
        true,
        false,
      ]);

      restored.impostaRisorsaCostoPerLivello(1, 'Volontà');
      expect(restored.risorsaCostoPerLivello(1), 'volonta');
      expect(restored.costoOculumDisabilitato(1), isTrue);
      restored.impostaRisorsaCostoPerLivello(1, 'Oculum');
      expect(restored.risorsaCostoPerLivello(1), 'oculum');
      expect(restored.costoOculumDisabilitato(1), isFalse);
    });

    test('ogni livello Art conserva limiti Oculum indipendenti', () {
      final skill = ArtSkill(
        nome: 'Forma mobile',
        oculumMinimiPerLivello: <int>[1, 2, 4, 6, 8],
        oculumMassimiPerLivello: <int>[3, 6, 10, 14, 18],
      );
      skill.oculumMassimiPerLivello[1] = 7;

      final restored = ArtSkill.fromJson(skill.toJson());
      expect(restored.oculumMinimoPerLivello(1), 1);
      expect(restored.oculumMinimoPerLivello(3), 4);
      expect(restored.oculumMassimoPerLivello(2), 7);
      expect(restored.oculumMassimoInizialePerLivello(2), 6);
      expect(restored.oculumMassimoPerLivello(5), 18);
    });

    test('le evoluzioni Art leggono i limiti dalla fine del testo', () {
      final skill = ArtSkill.fromJson(<String, dynamic>{
        'nome': 'Forma testuale',
        'evo1': 'Effetto I (1 / 5)\n',
        'evo2': 'Effetto II (2/8)',
        'evo3': 'Il valore (3/9) non e finale. Altro testo',
      });

      expect(skill.oculumMinimoPerLivello(1), 1);
      expect(skill.oculumMassimoPerLivello(1), 5);
      expect(skill.oculumMassimoInizialePerLivello(1), 5);
      expect(skill.oculumMinimoPerLivello(2), 2);
      expect(skill.oculumMassimoPerLivello(2), 8);
      expect(skill.oculumMassimoPerLivello(3), 0);
    });

    test('la Maestria Art rilegge il costo non zero della forma seguente', () {
      final skill = ArtSkill(
        nome: 'Forma testuale',
        evo1: 'Effetto I (1 4)',
        evo2: 'Effetto II (2 9)',
      );

      expect(oculumArtSkillMasteryGrowthLimit(skill, 1, maxLevel: 3), 9);
    });

    test('i limiti manuali Art hanno precedenza sul testo', () {
      final skill = ArtSkill(
        nome: 'Manuale',
        evo1: 'Testo (1/5)',
        oculumMinimiPerLivello: <int>[3],
        oculumMassimiPerLivello: <int>[9],
      );

      expect(skill.oculumMinimoPerLivello(1), 3);
      expect(skill.oculumMassimoPerLivello(1), 9);
      expect(skill.oculumLimitiManualiPerLivello.first, isTrue);
    });

    test('la Maestria normale usa solo tre stadi', () {
      final skill = ArtSkill(
        nome: 'Oculum Art',
        oculumMassimiPerLivello: <int>[3, 7, 11, 40, 50],
      );

      expect(oculumArtSkillMasteryGrowthLimit(skill, 1, maxLevel: 3), 7);
      expect(oculumArtSkillMasteryGrowthLimit(skill, 2, maxLevel: 3), 11);
      expect(oculumArtSkillMasteryGrowthLimit(skill, 3, maxLevel: 3), 21);
      expect(oculumArtSkillMasteryGrowthLimit(skill, 4, maxLevel: 3), 0);
    });

    test('solo la Maestria Defiled prosegue fino al quinto stadio', () {
      final skill = ArtSkill(
        nome: 'Defiled',
        oculumMassimiPerLivello: <int>[3, 7, 11, 16, 22],
      );

      expect(oculumArtSkillMasteryGrowthLimit(skill, 3, maxLevel: 5), 16);
      expect(oculumArtSkillMasteryGrowthLimit(skill, 4, maxLevel: 5), 22);
      expect(oculumArtSkillMasteryGrowthLimit(skill, 5, maxLevel: 5), 32);
    });

    test('correggere minimo e massimo aggiorna solo il livello scelto', () {
      final skill = ArtSkill(
        nome: 'Controllo',
        oculumMinimiPerLivello: <int>[1, 2, 3],
        oculumMassimiPerLivello: <int>[4, 8, 12],
      );
      skill.impostaLimitiOculumPerLivello(2, minimo: 5, massimo: 9);

      expect(skill.oculumMinimiPerLivello.take(3), <int>[1, 5, 3]);
      expect(skill.oculumMassimiPerLivello.take(3), <int>[4, 9, 12]);
      expect(skill.oculumMassimiInizialiPerLivello.take(3), <int>[4, 9, 12]);
    });

    test('il nuovo valore resta compatibile con i vecchi JSON', () {
      final legacy = CharacterArt.fromJson(<String, dynamic>{
        'nome': 'Prima Art',
        'tipo': 'Oculum Art',
        'descrizione': '',
        'skills': <Map<String, dynamic>>[],
        'sbloccata': true,
      });
      expect(legacy.integritaCorrente, -1);
      expect(legacy.esaurimentoCompleto, isFalse);

      legacy.integritaCorrente = 73;
      legacy.esaurimentoCompleto = true;
      final restored = CharacterArt.fromJson(legacy.toJson());
      expect(restored.integritaCorrente, 73);
      expect(restored.esaurimentoCompleto, isTrue);
    });
  });

  group('parser e risultato DT', () {
    test('ripara il mojibake ripetuto nei testi delle evoluzioni Art', () {
      const original =
          'I — Potenzia braccia e gambe: ×1,2 danni e velocità raddoppiata.';
      String corrupt(String value) => String.fromCharCodes(utf8.encode(value));
      final corruptedTwice = corrupt(corrupt(original));

      expect(oculumCleanMojibakeText(corruptedTwice), original);

      final art = CharacterArt.fromJson(<String, dynamic>{
        'nome': corrupt('Art d’Acciaio'),
        'tipo': 'Oculum Art',
        'descrizione': '',
        'skills': <Map<String, dynamic>>[
          <String, dynamic>{'nome': 'Boost', 'evo1': corruptedTwice},
        ],
      });
      expect(art.nome, 'Art d’Acciaio');
      expect(art.skills.single.evo1, original);
    });

    test('riconosce nomi dinamici di sottotratti come target e variabile', () {
      final vars = <String, num>{
        'velo': 7,
        'manifestazione_del_potere': 11,
        'danni': 4,
      };

      final target = oculumParseFormulaCommands('@Velo+2', vars).single;
      expect(target.valid, isTrue);
      expect(target.key, 'velo');
      expect(target.value, 2);

      final expression = oculumParseFormulaCommands(
        '@Danni+Manifestazione_del_Potere',
        vars,
      ).single;
      expect(expression.valid, isTrue);
      expect(expression.value, 11);
    });

    test('Riesci ma appare solo sullo zero finale con DT', () {
      expect(
        oculumRollZeroOutcomeText(total: 0, difficulty: 8),
        '\nRiesci ma...',
      );
      expect(oculumRollZeroOutcomeText(total: 1, difficulty: 8), isEmpty);
      expect(oculumRollZeroOutcomeText(total: -1, difficulty: 8), isEmpty);
      expect(oculumRollZeroOutcomeText(total: 0, difficulty: 0), isEmpty);
    });
  });
}
