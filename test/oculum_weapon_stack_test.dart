import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

InventoryItem weapon(String name, int damage, int level, int grade) =>
    InventoryItem(
      nome: name,
      note: '',
      peso: 1,
      quantita: 1,
      arma: true,
      equipaggiata: true,
      bonusDanno: damage,
      livelloOggetto: level,
      gradoOggetto: grade,
    );

void main() {
  test('weapon capacity grows with grade', () {
    expect(oculumWeaponLimit(0), 3);
    expect(oculumWeaponLimit(1), 8);
    expect(oculumWeaponLimit(12), 63);
  });

  test('each secondary rounds independently by its level or grade', () {
    final main = weapon('Principale', 30, 10, 2); // 40 damage
    final inferior = weapon('Inferiore', 3, 9, 1); // 8 / 3 -> 2
    final equalLevel = weapon('Livello pari', 3, 10, 1); // 8 / 3 -> 3
    final equalGrade = weapon('Grado pari', 1, 1, 2); // 11 / 3 -> 4
    expect(
      oculumWeaponStackDamage([inferior, equalLevel, main, equalGrade]),
      49,
    );
    expect(oculumWeaponStackDamage([main]), 40);
    expect(oculumWeaponStackDamage([]), 0);
    expect(main.bonusDanno, 30);
    expect(inferior.equipaggiata, isTrue);
  });
}
