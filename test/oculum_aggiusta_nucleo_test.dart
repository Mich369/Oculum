import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  group('Aggiusta nucleo', () {
    test('arrotonda il totale finale alla decina con 5 verso il basso', () {
      expect(oculumAggiustaNucleoRoundedTotal(0), 10);
      expect(oculumAggiustaNucleoRoundedTotal(5), 10);
      expect(oculumAggiustaNucleoRoundedTotal(6), 10);
      expect(oculumAggiustaNucleoRoundedTotal(10), 10);
      expect(oculumAggiustaNucleoRoundedTotal(15), 10);
      expect(oculumAggiustaNucleoRoundedTotal(16), 20);
      expect(oculumAggiustaNucleoRoundedTotal(25), 20);
      expect(oculumAggiustaNucleoRoundedTotal(26), 30);
    });

    test('applica arrotondamento dopo la somma di d10 e Medicina', () {
      const d10 = 8;
      const medicina = 8;
      final total = d10 + medicina;

      expect(total, 16);
      expect(oculumAggiustaNucleoRoundedTotal(total), 20);
    });

    test('il minimo è 10 ma non recupera oltre il massimale della Art', () {
      expect(oculumAggiustaNucleoRoundedTotal(1), 10);
      expect(
        oculumAggiustaNucleoEffectiveRecovery(
          current: 96,
          maximum: 100,
          roundedTotal: oculumAggiustaNucleoRoundedTotal(1),
        ),
        4,
      );
      expect(
        oculumAggiustaNucleoEffectiveRecovery(
          current: 92,
          maximum: 100,
          roundedTotal: 20,
        ),
        8,
      );
      expect(
        oculumAggiustaNucleoEffectiveRecovery(
          current: 100,
          maximum: 100,
          roundedTotal: 20,
        ),
        0,
      );
    });

    test('non produce recuperi negativi', () {
      expect(oculumAggiustaNucleoRoundedTotal(-4), 10);
      expect(
        oculumAggiustaNucleoEffectiveRecovery(
          current: 40,
          maximum: 100,
          roundedTotal: -10,
        ),
        0,
      );
    });

    test('ogni 10 Integrità massima oltre 100 aggiunge 5 recupero', () {
      expect(oculumRepairCoreMaximumIntegrityBonus(90), 0);
      expect(oculumRepairCoreMaximumIntegrityBonus(100), 0);
      expect(oculumRepairCoreMaximumIntegrityBonus(109), 0);
      expect(oculumRepairCoreMaximumIntegrityBonus(110), 5);
      expect(oculumRepairCoreMaximumIntegrityBonus(130), 15);
      expect(oculumRepairCoreMaximumIntegrityBonus(175), 35);
    });
  });
}
