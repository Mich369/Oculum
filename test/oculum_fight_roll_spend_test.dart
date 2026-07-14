import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('Oculum nei tiri fight scala subito la risorsa attuale', () {
    final result = oculumFightRollSpendResult(
      currentOculum: 11,
      spentOculum: 3,
    );

    expect(result.remainingOculum, 8);
    expect(result.bonus, 9);
  });

  test('il consumo fight non porta mai Oculum sotto zero', () {
    final result = oculumFightRollSpendResult(currentOculum: 2, spentOculum: 7);

    expect(result.remainingOculum, 0);
    expect(result.bonus, 6);
  });
}
