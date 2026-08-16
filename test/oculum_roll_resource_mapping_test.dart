import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  group('risorsa consumata dai tiri', () {
    test('riconosce statistiche base e abbreviazioni', () {
      expect(oculumRollConsumedStatKey('Resilienza'), 'resilienza');
      expect(oculumRollConsumedStatKey('VC'), 'volonta');
      expect(oculumRollConsumedStatKey('CM'), 'materia');
      expect(oculumRollConsumedStatKey('Iniziativa'), 'materia');
    });

    test('Riflessi usa Materia e Percezione usa Oculum', () {
      expect(oculumRollConsumedStatKey('Riflessi'), 'materia');
      expect(oculumRollConsumedStatKey('Percezione'), 'oculum');
    });

    test('il gruppo del sottotratto ha precedenza sul nome', () {
      expect(
        oculumRollConsumedStatKey('Qualsiasi', subtraitGroup: 'volonta'),
        'volonta',
      );
      expect(
        oculumRollConsumedStatKey('Qualsiasi', subtraitGroup: 'altro'),
        'oculum',
      );
    });

    test('i minimi restano compatibili con le regole', () {
      expect(oculumCurrentStatRollMinimum('resilienza'), 1);
      expect(oculumCurrentStatRollMinimum('volonta'), 1);
      expect(oculumCurrentStatRollMinimum('materia'), 0);
      expect(oculumCurrentStatRollMinimum('oculum'), 0);
    });

    test('i tiri normali non consumano statistiche', () {
      expect(
        oculumShouldConsumeRollStat(
          highConsumption: false,
          statKey: 'resilienza',
        ),
        isFalse,
      );
      expect(
        oculumShouldConsumeRollStat(highConsumption: false, statKey: 'oculum'),
        isFalse,
      );
    });

    test('Consumo elevato consuma solo con una risorsa collegata', () {
      expect(
        oculumShouldConsumeRollStat(highConsumption: true, statKey: 'materia'),
        isTrue,
      );
      expect(
        oculumShouldConsumeRollStat(highConsumption: true, statKey: ''),
        isFalse,
      );
    });
  });
}
