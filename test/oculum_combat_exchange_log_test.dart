import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('combat log explains helped defense and ties', () {
    final log = oculumCombatExchangeLog(
      attacker: 'Raudon',
      technique: 'Schianto',
      attack: 23,
      defenseChoice: 'Riflessi',
      defense: 23,
      defenseHelp: 4,
      avoided: true,
    );
    expect(log, contains('Raudon ti attacca con Schianto: 23'));
    expect(log, contains('Difesa Riflessi: 19'));
    expect(log, contains('Aiuto compagno alla difesa: +4'));
    expect(log, contains('Vince la difesa'));
  });
}
