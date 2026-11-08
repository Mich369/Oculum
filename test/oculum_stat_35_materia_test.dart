import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('Wind Step uses a reachable adjacent point in map metres', () {
    Offset? land(double movement, {Iterable<Offset> occupied = const []}) =>
        oculumMateria35WindLanding(
          source: const Offset(.1, .5),
          target: const Offset(.4, .5),
          widthMeters: 40,
          heightMeters: 20,
          movement: movement,
          adjacency: 1,
          occupied: occupied,
        );

    expect(land(10.9), isNull);
    final reachable = land(11)!;
    expect(reachable.dx, closeTo(.375, .000001));
    expect(reachable.dy, closeTo(.5, .000001));
    final otherSide = land(12, occupied: [reachable]);
    expect(otherSide, isNotNull);
    expect(otherSide, isNot(reachable));
    expect(oculumMateria35WindStepDamage(17), 5);
    expect(oculumMateria35WindStepDamage(0), 0);
  });

  test(
    'Immateriale recognizes magical physical and explicit bypass damage',
    () {
      expect(
        oculumMateria35ImmaterialePercent(
          element: 'Fisico',
          magicalAttack: false,
        ),
        0,
      );
      expect(
        oculumMateria35ImmaterialePercent(
          element: 'Taglio',
          magicalAttack: true,
        ),
        75,
      );
      expect(
        oculumMateria35ImmaterialePercent(
          element: 'Fuoco',
          magicalAttack: false,
        ),
        75,
      );
      for (final element in ['Ombra', 'Spirituale', 'Perforante immateriale']) {
        expect(
          oculumMateria35ImmaterialePercent(
            element: element,
            magicalAttack: false,
          ),
          100,
        );
      }
      expect(
        oculumMateria35ImmaterialePercent(
          element: 'Perforante',
          magicalAttack: false,
        ),
        0,
      );
    },
  );
}
