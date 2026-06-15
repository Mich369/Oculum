import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  group('Osservato punti extra livello', () {
    test('calcola punti teorici retroattivi per livello', () {
      expect(oculumObservationTheoreticalPoints(observed: true, level: 0), 0);
      expect(oculumObservationTheoreticalPoints(observed: true, level: 1), 1);
      expect(oculumObservationTheoreticalPoints(observed: true, level: 8), 8);
      expect(oculumObservationTheoreticalPoints(observed: true, level: 12), 12);
      expect(oculumObservationTheoreticalPoints(observed: false, level: 12), 0);
      expect(oculumObservationTheoreticalPoints(observed: true, level: -4), 0);
    });

    test('disponibili = teorici meno assegnati con clamp a zero', () {
      final assigned = oculumNormalizeObservationAssignedCounts({
        'resilienza': 1,
        'volonta': 2,
      });

      expect(
        oculumObservationAvailablePoints(
          observed: true,
          level: 8,
          assigned: assigned,
        ),
        5,
      );
      expect(
        oculumObservationAvailablePoints(
          observed: true,
          level: 2,
          assigned: assigned,
        ),
        0,
      );
      expect(
        oculumObservationAvailablePoints(
          observed: false,
          level: 8,
          assigned: assigned,
        ),
        0,
      );
    });

    test('salire da 12 a 13 aggiunge solo un disponibile', () {
      final assigned = oculumNormalizeObservationAssignedCounts({
        'materia': 12,
      });

      expect(
        oculumObservationAvailablePoints(
          observed: true,
          level: 12,
          assigned: assigned,
        ),
        0,
      );
      expect(
        oculumObservationAvailablePoints(
          observed: true,
          level: 13,
          assigned: assigned,
        ),
        1,
      );
    });

    test('normalizza vecchi salvataggi con un solo punto assegnato', () {
      final assigned = oculumNormalizeObservationAssignedCounts(
        null,
        legacyAssigned: 'Oculum',
      );

      expect(assigned['oculum'], 1);
      expect(oculumObservationAssignedTotal(assigned), 1);
      expect(
        oculumObservationAvailablePoints(
          observed: true,
          level: 8,
          assigned: assigned,
        ),
        7,
      );
    });

    test('toggle off e on non cambia il conteggio assegnato', () {
      final assigned = oculumNormalizeObservationAssignedCounts({
        'resilienza': 2,
        'materia': 1,
      });
      final before = oculumObservationAssignedTotal(assigned);
      final offAvailable = oculumObservationAvailablePoints(
        observed: false,
        level: 8,
        assigned: assigned,
      );
      final onAvailable = oculumObservationAvailablePoints(
        observed: true,
        level: 8,
        assigned: assigned,
      );

      expect(before, 3);
      expect(offAvailable, 0);
      expect(onAvailable, 5);
      expect(oculumObservationAssignedTotal(assigned), before);
    });
  });
}
