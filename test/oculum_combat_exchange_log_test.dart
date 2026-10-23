import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('combat log explains helped defense and ties', () {
    final log = oculumCombatExchangeLog(
      attacker: 'Raudon',
      defender: 'Mario',
      technique: 'Schianto',
      attack: 23,
      defenseChoice: 'Riflessi',
      defense: 23,
      defenseHelp: 4,
      avoided: true,
    );
    expect(log, contains('Raudon → Mario · Schianto 23'));
    expect(log, contains('Mario: Riflessi 19'));
    expect(log, contains('+ aiuto 4 = 23'));
    expect(log, contains('vince la difesa'));
  });
}
