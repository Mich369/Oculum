import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('Open split assigns the full remainder in selection order', () {
    expect(
      [for (var i = 0; i < 4; i++) oculumStatOpenDamageShare(103, 4, i)],
      [26, 26, 26, 25],
    );
    expect(
      [for (var i = 0; i < 4; i++) oculumStatOpenDamageShare(2, 4, i)],
      [1, 1, 0, 0],
    );
    expect(oculumStatOpenDamageShare(103, 4, 4), 0);
    expect(oculumStatOpenDamageShare(103, 0, 0), 0);
  });
}
