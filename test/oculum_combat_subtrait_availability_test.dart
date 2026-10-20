import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('combat subtraits remain usable regardless of legacy unlock flag', () {
    final stat = HiddenEyeStat(
      id: 'strategia',
      nome: 'Strategia',
      descrizione: '',
      unlocked: false,
    );

    expect(oculumCombatSubtraitSelectable(stat), isTrue);
  });

  test('non-roll special tracks are not offered as combat subtraits', () {
    for (final id in ['nodo', 'fortuna', 'drop']) {
      expect(
        oculumCombatSubtraitSelectable(
          HiddenEyeStat(id: id, nome: id, descrizione: ''),
        ),
        isFalse,
      );
    }
  });

  test('Manifestazione attack bonus starts at +6 and scales per level', () {
    expect(
      oculumManifestationAttackDamageBonus(manifestationTotal: 5, level: 12),
      0,
    );
    expect(
      oculumManifestationAttackDamageBonus(manifestationTotal: 6, level: 12),
      36,
    );
    expect(
      oculumManifestationAttackDamageBonus(manifestationTotal: 8, level: 12),
      36,
    );
  });

  test('Precisione distributes one, two, and three Fragilita stages', () {
    expect(
      oculumPrecisionHitResult(
        precisionTotal: 6,
        percentileRoll: 0,
      ).fragilityStages,
      1,
    );
    expect(
      oculumPrecisionHitResult(
        precisionTotal: 6,
        percentileRoll: 79,
      ).fragilityStages,
      1,
    );
    expect(
      oculumPrecisionHitResult(
        precisionTotal: 6,
        percentileRoll: 80,
      ).fragilityStages,
      2,
    );
    expect(
      oculumPrecisionHitResult(
        precisionTotal: 6,
        percentileRoll: 95,
      ).fragilityStages,
      3,
    );
    expect(
      oculumPrecisionHitResult(
        precisionTotal: 36,
        percentileRoll: 44,
      ).fragilityStages,
      1,
    );
    expect(
      oculumPrecisionHitResult(
        precisionTotal: 36,
        percentileRoll: 45,
      ).fragilityStages,
      0,
    );
    expect(
      oculumPrecisionHitResult(
        precisionTotal: 36,
        percentileRoll: 50,
      ).fragilityStages,
      2,
    );
    expect(
      oculumPrecisionHitResult(
        precisionTotal: 41,
        percentileRoll: 95,
      ).fragilityStages,
      3,
    );
  });

  test('Precisione +20 carves out a 5% custom damage result', () {
    final special = oculumPrecisionHitResult(
      precisionTotal: 20,
      percentileRoll: 61,
      customDamagePercent: 350,
    );
    expect(special.fragilityStages, 0);
    expect(special.receivedDamagePercent, 350);
    expect(
      oculumPrecisionHitResult(
        precisionTotal: 20,
        percentileRoll: 60,
      ).fragilityStages,
      1,
    );
    expect(
      oculumPrecisionHitResult(
        precisionTotal: 20,
        percentileRoll: 66,
      ).fragilityStages,
      2,
    );
  });

  test('precision fragility advances only this hit and caps at Letale', () {
    const scale = <String>[
      'Normale',
      'Bassa Fragilità',
      'Fragilità',
      'Fragilità Semi Letale',
      'Fragilità Letale',
    ];
    expect(oculumAdvanceDamagePreset('Normale', 2, scale), 'Fragilità');
    expect(
      oculumAdvanceDamagePreset('Fragilità Semi Letale', 3, scale),
      'Fragilità Letale',
    );
  });
}
