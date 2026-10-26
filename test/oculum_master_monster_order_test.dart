import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  test(
    'Master book sorts every species and variant by total power, then stable ties',
    () {
      final original = defaultMonsterBookEntries.map((m) => m.id).toList();
      final sorted = defaultMonsterBookEntries.toList()
        ..sort(oculumCompareMonsterBookPower);
      for (var i = 1; i < sorted.length; i++) {
        expect(
          oculumMonsterBookPower(sorted[i]),
          greaterThanOrEqualTo(oculumMonsterBookPower(sorted[i - 1])),
        );
      }
      expect(sorted.map((m) => m.id).toSet(), original.toSet());
      expect(defaultMonsterBookEntries.map((m) => m.id).toList(), original);
      final sample = sorted.first.copyWith(
        stats: {
          'level': 10,
          'grade': 2,
          'resilienza': 1,
          'volonta': 2,
          'materia': 3,
          'oculum': 4,
        },
      );
      expect(oculumMonsterBookPower(sample), 26);
      final ties = [
        sample.copyWith(id: 'z', nameIt: 'Zeta'),
        sample.copyWith(id: 'a', nameIt: 'Alfa'),
      ]..sort(oculumCompareMonsterBookPower);
      expect(ties.first.id, 'a');
    },
  );

  testWidgets('Master panel renders the filtered cycle species weakest first', (
    tester,
  ) async {
    final dynamic state = await fixtures.mountSheet(
      tester,
      const Size(1440, 1000),
    );
    state.datiCaricati = false;
    state.monsterBookSearchController.text = 'ciclo_';
    state.monsterBookTierFilter = 'Tutti';
    state.monsterBookHabitatFilter = '';
    final p = OculumPerformanceProbe(state);
    final panel = p.masterMonsterBook();
    final expected =
        defaultMonsterBookEntries.where((m) => m.id.contains('ciclo_')).toList()
          ..sort(oculumCompareMonsterBookPower);
    await tester.pumpWidget(
      MaterialApp(
        theme: oculumBaseTheme,
        home: Scaffold(body: SingleChildScrollView(child: panel)),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text(expected.first.nameIt), findsOneWidget);
    expect(find.text(expected[1].nameIt), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(expected.first.nameIt)).dy,
      lessThan(tester.getTopLeft(find.text(expected[1].nameIt)).dy),
    );
    expect(find.textContaining('Potenza totale crescente'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
