import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('il riposo lungo porta gli HP al 75 percento del massimale', () {
    expect(oculumLongRestHpTarget(currentHp: 0, maxHp: 100), 75);
    expect(oculumLongRestHpTarget(currentHp: 20, maxHp: 101), 76);
  });

  test('il riposo lungo non riduce gli HP gia sopra il 75 percento', () {
    expect(oculumLongRestHpTarget(currentHp: 90, maxHp: 100), 90);
    expect(oculumLongRestHpTarget(currentHp: 150, maxHp: 100), 100);
  });
}
