import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

// Keep the Home State mounted: it owns the search controller used by the
// real Master panel. Replacing the app with an extracted panel disposes it.
Future<VoidCallback> _showMasterPanel(WidgetTester tester, Widget panel) async {
  final overlay = Overlay.of(tester.element(find.byType(OculumHomePage)));
  final entry = OverlayEntry(
    builder: (_) => Positioned.fill(
      child: Material(
        child: Scaffold(body: SingleChildScrollView(child: panel)),
      ),
    ),
  );
  var closed = false;
  void close() {
    if (closed) return;
    closed = true;
    entry.remove();
    entry.dispose();
  }

  overlay.insert(entry);
  addTearDown(close);
  await tester.pump();
  return close;
}

void main() {
  test('purchased Monster Book page can show base power at level zero', () {
    final entry = monsterBookEntries.first.copyWith(
      stats: const {
        'level': 12,
        'grade': 4,
        'resilienza': 3,
        'volonta': 5,
        'materia': 7,
        'oculum': 11,
      },
    );

    expect(oculumMonsterBookBasePowerAtLevelZero(entry), 26);
    expect(oculumMonsterBookPower(entry), greaterThan(26));
  });

  for (final size in [const Size(1920, 1080), const Size(390, 844)]) {
    testWidgets('Master dashboard opens Fight Creator at $size', (
      tester,
    ) async {
      final dynamic state = await fixtures.mountSheet(tester, size);
      state.updateOculumHomeUi(() {
        state.modalitaMaster = true;
        state.paginaCorrente = 9;
        state.masterCategory = 'overview';
      });
      await tester.pumpAndSettle();
      final button = find.byKey(const ValueKey('fight-creator-open'));
      expect(button.hitTestable(), findsOneWidget);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Fight Creator · Solo Master'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Chiudi').hitTestable());
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }

  testWidgets('Master catalogue shows the fallback creature illustration', (
    tester,
  ) async {
    final dynamic state = await fixtures.mountSheet(
      tester,
      const Size(1440, 1000),
    );
    state.datiCaricati = false;
    state.modalitaMaster = true;
    final entry = monsterBookEntryById(
      'mammuth_in_decomposizione_variante_rituale',
    )!;
    state.monsterBookSearchController.text = entry.nameIt;
    final closePanel = await _showMasterPanel(
      tester,
      OculumPerformanceProbe(state).masterMonsterBook(),
    );
    await tester.ensureVisible(
      find.byKey(const PageStorageKey<String>('master_monster_book_list')),
    );
    await tester.pump();
    expect(
      find.byKey(ValueKey('creature-recognition-${entry.id}')),
      findsOneWidget,
    );
    expect(find.text('Forma base'), findsWidgets);
    await tester.tap(find.byKey(ValueKey('enlarge-creature-${entry.id}')));
    await tester.pumpAndSettle();
    final viewer = find.byKey(const ValueKey('enlarged-creature-artwork'));
    expect(viewer, findsOneWidget);
    closePanel();
    await tester.pump();
    final image = find.descendant(
      of: viewer,
      matching: find.byType(InteractiveViewer),
    );
    final controller = tester
        .widget<InteractiveViewer>(image)
        .transformationController!;
    Future<void> doubleTap() async {
      await tester.tap(image);
      await tester.pump(const Duration(milliseconds: 70));
      await tester.tap(image);
      await tester.pump(const Duration(milliseconds: 350));
    }

    await doubleTap();
    expect(controller.value.getMaxScaleOnAxis(), greaterThan(1));
    await doubleTap();
    expect(controller.value.getMaxScaleOnAxis(), closeTo(1, .001));
    final center = tester.getCenter(image);
    await tester.sendEventToBinding(
      PointerScrollEvent(position: center, scrollDelta: const Offset(0, -120)),
    );
    await tester.pump();
    expect(controller.value.getMaxScaleOnAxis(), greaterThan(1));
    expect(
      find.descendant(
        of: viewer,
        matching: find.text('${entry.nameIt} · Forma base'),
      ),
      findsOneWidget,
    );
    Navigator.of(tester.element(viewer)).pop();
    await tester.pumpAndSettle();
    expect(viewer, findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

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
      expect(
        oculumMonsterBookPower(sample),
        29,
      ); // Includes floor(16 / 5) HP power.
      final ties = [
        sample.copyWith(id: 'z', nameIt: 'Zeta'),
        sample.copyWith(id: 'a', nameIt: 'Alfa'),
      ]..sort(oculumCompareMonsterBookPower);
      expect(ties.first.id, 'a');
    },
  );

  testWidgets('Master panel renders a habitat filter weakest first', (
    tester,
  ) async {
    final dynamic state = await fixtures.mountSheet(
      tester,
      const Size(1440, 1000),
    );
    state.datiCaricati = false;
    state.modalitaMaster = true;
    // A name query now sorts by relevance before power. Use the habitat
    // filter to exercise weakest-first ordering without name-score ties.
    state.monsterBookSearchController.clear();
    state.monsterBookFinishedOnly = false;
    state.monsterBookTierFilter = 'Tutti';
    state.monsterBookHabitatFilter = 'affogato';
    state.monsterBookKnowledgeFilter = 'all';
    final p = OculumPerformanceProbe(state);
    final panel = p.masterMonsterBook();
    final expected =
        defaultMonsterBookEntries
            .where(
              (m) => m.visibleInMonsterBook && m.planeIds.contains('affogato'),
            )
            .toList()
          ..sort(oculumCompareMonsterBookPower);
    expect(expected.length, greaterThanOrEqualTo(2));
    final closePanel = await _showMasterPanel(tester, panel);
    expect(state.mounted, isTrue);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(
      find.byKey(const PageStorageKey<String>('master_monster_book_list')),
    );
    await tester.pump();
    final tiles = find.descendant(
      of: find.byKey(const PageStorageKey<String>('master_monster_book_list')),
      matching: find.byType(ListTile),
    );
    expect(tiles.evaluate().length, greaterThanOrEqualTo(2));
    for (var index = 0; index < 2; index++) {
      final tile = tester.widget<ListTile>(tiles.at(index));
      expect((tile.title! as Text).data, expected[index].nameIt);
      expect(
        (tile.subtitle! as Text).data,
        startsWith('Potenza ${oculumMonsterBookPower(expected[index])} '),
      );
    }
    expect(
      tester.getTopLeft(tiles.at(0)).dy,
      lessThan(tester.getTopLeft(tiles.at(1)).dy),
    );
    expect(find.textContaining('Potenza totale crescente'), findsOneWidget);
    closePanel();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Master name search retains partial matches after closer names', (
    tester,
  ) async {
    final dynamic state = await fixtures.mountSheet(
      tester,
      const Size(1440, 1000),
    );
    state.datiCaricati = false;
    state.modalitaMaster = true;
    state.monsterBookSearchController.text = 'demon';
    state.monsterBookTierFilter = 'Tutti';
    state.monsterBookHabitatFilter = '';
    state.monsterBookKnowledgeFilter = 'all';
    state.monsterBookFinishedOnly = false;
    final panel = OculumPerformanceProbe(state).masterMonsterBook();
    final closePanel = await _showMasterPanel(tester, panel);
    expect(state.mounted, isTrue);
    expect(tester.takeException(), isNull);

    final results = List<MonsterBookEntry>.from(state.monsterBookFilterCache);
    final ids = results.map((entry) => entry.id).toList();
    expect(ids, contains('demone_minore'));
    expect(ids, contains('forest_demon'));
    expect(ids.indexOf('demone_minore'), lessThan(ids.indexOf('forest_demon')));

    final list = find.byKey(
      const PageStorageKey<String>('master_monster_book_list'),
    );
    await tester.ensureVisible(list);
    await tester.pump();
    final tiles = find.descendant(of: list, matching: find.byType(ListTile));
    expect(
      (tester.widget<ListTile>(tiles.first).title! as Text).data,
      results.first.nameIt,
    );
    final forest = results.singleWhere((entry) => entry.id == 'forest_demon');
    await tester.scrollUntilVisible(
      find.text(forest.nameIt),
      288,
      scrollable: find.descendant(of: list, matching: find.byType(Scrollable)),
    );
    expect(find.text(forest.nameIt), findsOneWidget);
    expect(tester.takeException(), isNull);
    closePanel();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
