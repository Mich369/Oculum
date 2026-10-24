import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('Chaos gathers 1.8x materials and Collector remains grade-limited', () {
    expect(
      oculumGatherOutputGrams(
        baseGrams: 1001,
        resourceGrade: 12,
        chaosIdentity: true,
      ),
      1802,
    );
    expect(
      oculumGatherOutputGrams(
        baseGrams: 1000,
        resourceGrade: 3,
        collectorGrade: 2,
      ),
      1000,
    );
    expect(
      oculumGatherOutputGrams(
        baseGrams: 1000,
        resourceGrade: 2,
        collectorGrade: 2,
      ),
      2000,
    );
    expect(
      oculumGatherOutputGrams(
        baseGrams: 1000,
        resourceGrade: 2,
        collectorGrade: 12,
        chaosIdentity: true,
      ),
      1800,
      reason: 'Chaos bonus does not stack with the Raccoglitore.',
    );
  });
}
