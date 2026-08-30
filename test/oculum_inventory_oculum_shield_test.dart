import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  group('Scudo Oculum degli oggetti difensivi', () {
    test('nuovi campi restano compatibili con i vecchi salvataggi', () {
      final legacy = InventoryItem.fromJson(<String, dynamic>{
        'nome': 'Vecchio scudo',
        'peso': 2,
        'quantita': 1,
        'note': 'legacy',
        'protegge': true,
        'bonusScudo': 8,
      });

      expect(legacy.bonusScudoOculum, 0);
      expect(legacy.scudoIntegritaOculumCorrente, -1);
      expect(legacy.toJson()['bonusScudoOculum'], 0);
    });

    test('salva bonus, integrita e parser dello Scudo Oculum', () {
      final source = InventoryItem(
        nome: 'Egida Oculum',
        peso: 3,
        quantita: 1,
        note: '',
        protegge: true,
        equipaggiata: true,
        bonusScudoOculum: 12,
        effettoIntegritaScudo: '@Difesa+3',
        scudoIntegritaOculumCorrente: 4,
      );

      final restored = InventoryItem.fromJson(source.toJson());

      expect(restored.bonusScudoOculum, 12);
      expect(restored.scudoIntegritaOculumCorrente, 4);
      expect(restored.effettoIntegritaScudo, '@Difesa+3');
    });

    test('il buff si spegne alla rottura e torna con la ricarica', () {
      final item = InventoryItem(
        nome: 'Egida Oculum',
        peso: 3,
        quantita: 1,
        note: '',
        protegge: true,
        equipaggiata: true,
        bonusScudoOculum: 12,
        effettoIntegritaScudo: '@Difesa+3',
        scudoIntegritaCorrente: 0,
        scudoIntegritaOculumCorrente: 0,
      );

      expect(
        oculumInventoryIntegrityEffectActive(
          item,
          normalMaximum: 0,
          oculumMaximum: 12,
        ),
        isFalse,
      );

      oculumRechargeInventoryOculumIntegrity(item, maximum: 12);

      expect(item.scudoIntegritaOculumCorrente, 12);
      expect(
        oculumInventoryIntegrityEffectActive(
          item,
          normalMaximum: 0,
          oculumMaximum: 12,
        ),
        isTrue,
      );
    });

    test('se resta uno dei due scudi il buff resta attivo', () {
      final item = InventoryItem(
        nome: 'Scudo doppio',
        peso: 4,
        quantita: 1,
        note: '',
        protegge: true,
        bonusScudo: 5,
        bonusScudoOculum: 5,
        effettoIntegritaScudo: '@Resilienza+1',
        scudoIntegritaCorrente: 2,
        scudoIntegritaOculumCorrente: 0,
      );

      expect(
        oculumInventoryIntegrityEffectActive(
          item,
          normalMaximum: 5,
          oculumMaximum: 5,
        ),
        isTrue,
      );
    });

    test('il controllo integrita non ricalcola i parser dello scudo', () {
      final source = File(
        'lib/src/main/oculum_home_calculations.dart',
      ).readAsStringSync();
      final start = source.indexOf('bool itemIntegrityEffectActive');
      final end = source.indexOf('bool canEquipInventoryItem', start);
      final method = source.substring(start, end);

      expect(method, contains('leggiNumero(scudoController)'));
      expect(method, contains('leggiNumero(scudoOculumController)'));
      expect(method, isNot(contains('normalAvailable: scudo()')));
      expect(method, isNot(contains('oculumAvailable: scudoOculum()')));
    });
  });

  group('Valore dello Scudo per difficoltà', () {
    test('Facile vale 1.5 arrotondato per difetto', () {
      expect(oculumShieldEffectiveValueForDifficulty(1, 'facile'), 1);
      expect(oculumShieldEffectiveValueForDifficulty(2, 'facile'), 3);
      expect(oculumShieldEffectiveValueForDifficulty(3, 'facile'), 4);
    });

    test('Medio vale uno per punto', () {
      expect(oculumShieldEffectiveValueForDifficulty(7, 'normale'), 7);
      expect(oculumShieldEffectiveValueForDifficulty(7, 'medio'), 7);
    });

    test('Difficile vale 0.5 arrotondato per eccesso', () {
      expect(oculumShieldEffectiveValueForDifficulty(1, 'difficile'), 1);
      expect(oculumShieldEffectiveValueForDifficulty(2, 'difficile'), 1);
      expect(oculumShieldEffectiveValueForDifficulty(3, 'difficile'), 2);
    });

    test('Oculum vale 0.2 arrotondato per difetto', () {
      expect(oculumShieldEffectiveValueForDifficulty(4, 'oculum'), 0);
      expect(oculumShieldEffectiveValueForDifficulty(5, 'oculum'), 1);
      expect(oculumShieldEffectiveValueForDifficulty(10, 'oculum'), 2);
    });

    test(
      'l assorbimento usa il valore senza cambiare il danno residuo male',
      () {
        final easy = oculumAbsorbDamageWithShield(
          layer: 2,
          remaining: 3,
          bonusPercent: 0,
          difficulty: 'facile',
        );
        final hard = oculumAbsorbDamageWithShield(
          layer: 2,
          remaining: 3,
          bonusPercent: 0,
          difficulty: 'difficile',
        );
        final oculum = oculumAbsorbDamageWithShield(
          layer: 5,
          remaining: 3,
          bonusPercent: 0,
          difficulty: 'oculum',
        );

        expect((easy.layer, easy.remaining), (0, 0));
        expect((hard.layer, hard.remaining), (0, 2));
        expect((oculum.layer, oculum.remaining), (0, 2));
      },
    );
  });

  group('Risorse iniziali e Sfortuna', () {
    test('ogni nuova scheda usa 3, 2 e 1 ispirazioni', () {
      expect(oculumNewSheetInspirations, 3);
      expect(oculumNewSheetSuperInspirations, 2);
      expect(oculumNewSheetInspirationsOculum, 1);
    });

    test('Facile assegna 5 Scudo soltanto la prima volta', () {
      final first = oculumFirstEasyShieldReward(
        difficulty: 'facile',
        alreadyClaimed: false,
        currentShield: 4,
      );
      final repeated = oculumFirstEasyShieldReward(
        difficulty: 'facile',
        alreadyClaimed: first.claimed,
        currentShield: first.shield,
      );

      expect((first.shield, first.claimed, first.granted), (9, true, true));
      expect(
        (repeated.shield, repeated.claimed, repeated.granted),
        (9, true, false),
      );
    });

    test('Difficile ha Sfortuna 1%, 2% e +50% solo Scudo', () {
      final profile = oculumMisfortuneProfile('difficile');

      expect(profile.criticalChance, 1);
      expect(profile.shieldChance, 2);
      expect(profile.normalShieldBonus, 50);
      expect(profile.oculumShieldBonus, 0);
      expect(
        oculumPercentRollSucceeds(
          chancePercent: profile.criticalChance,
          rollBasisPoints: 99,
        ),
        isTrue,
      );
      expect(
        oculumPercentRollSucceeds(
          chancePercent: profile.criticalChance,
          rollBasisPoints: 100,
        ),
        isFalse,
      );
    });

    test('Oculum ha Sfortuna 3%, 5% e +100% su entrambi', () {
      final profile = oculumMisfortuneProfile('oculum');

      expect(profile.criticalChance, 3);
      expect(profile.shieldChance, 5);
      expect(profile.normalShieldBonus, 100);
      expect(profile.oculumShieldBonus, 100);
    });

    test('la parata Oculum normale vale 0.1 per punto fino a 5', () {
      expect(
        oculumCurrentParryChancePercent(
          currentOculum: 1,
          difficulty: 'normale',
        ),
        0.1,
      );
      expect(
        oculumCurrentParryChancePercent(
          currentOculum: 5,
          difficulty: 'normale',
        ),
        0.5,
      );
    });

    test('dopo 5 ogni decimo richiede progressivamente più punti', () {
      expect(
        oculumCurrentParryChancePercent(
          currentOculum: 6,
          difficulty: 'normale',
        ),
        0.5,
      );
      expect(
        oculumCurrentParryChancePercent(
          currentOculum: 7,
          difficulty: 'normale',
        ),
        0.6,
      );
      expect(
        oculumCurrentParryChancePercent(
          currentOculum: 10,
          difficulty: 'normale',
        ),
        0.7,
      );
      expect(
        oculumCurrentParryChancePercent(
          currentOculum: 14,
          difficulty: 'normale',
        ),
        0.8,
      );
    });

    test('la difficoltà scala progressivamente la parata', () {
      expect(
        oculumCurrentParryChancePercent(currentOculum: 5, difficulty: 'facile'),
        0.75,
      );
      expect(
        oculumCurrentParryChancePercent(
          currentOculum: 5,
          difficulty: 'difficile',
        ),
        0.25,
      );
      expect(
        oculumCurrentParryChancePercent(currentOculum: 5, difficulty: 'oculum'),
        0.1,
      );
    });

    test('la soglia percentuale usa correttamente i basis point', () {
      const chance = 0.1;
      expect(
        oculumPercentRollSucceeds(chancePercent: chance, rollBasisPoints: 9),
        isTrue,
      );
      expect(
        oculumPercentRollSucceeds(chancePercent: chance, rollBasisPoints: 10),
        isFalse,
      );
    });

    test('la dispersione resta leggera nei primi 20 Oculum', () {
      expect(
        oculumCurrentParryStrainChancePercent(
          currentOculum: 20,
          difficulty: 'facile',
        ),
        2,
      );
      expect(
        oculumCurrentParryStrainChancePercent(
          currentOculum: 20,
          difficulty: 'normale',
        ),
        4,
      );
      expect(
        oculumCurrentParryStrainChancePercent(
          currentOculum: 20,
          difficulty: 'difficile',
        ),
        7,
      );
      expect(
        oculumCurrentParryStrainChancePercent(
          currentOculum: 20,
          difficulty: 'oculum',
        ),
        10,
      );
    });

    test('oltre 20 la dispersione cresce ma non supera 75%', () {
      expect(
        oculumCurrentParryStrainChancePercent(
          currentOculum: 40,
          difficulty: 'normale',
        ),
        14,
      );
      expect(
        oculumCurrentParryStrainChancePercent(
          currentOculum: 40,
          difficulty: 'difficile',
        ),
        23,
      );
      expect(
        oculumCurrentParryStrainChancePercent(
          currentOculum: 999,
          difficulty: 'oculum',
        ),
        75,
      );
    });
  });
}
