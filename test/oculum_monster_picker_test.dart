import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart' show oculumLookupMonsterId;
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_monster_picker.dart';

void main() {
  testWidgets('Master chooser shows the description for search and selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 680);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final source = monsterById('oculiath')!;
    final first = source.copyWith(
      id: 'first',
      nameEn: 'First',
      descEn: 'A strong flying creature with one eye.',
    );
    final second = source.copyWith(
      id: 'second',
      nameEn: 'Second',
      descEn: 'Small wings fold behind its shield.',
    );
    var selected = first.id;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, refresh) => OculumMonsterPicker(
              entries: [first, second],
              selectedId: selected,
              english: true,
              showDescriptions: true,
              allowClear: false,
              onSelected: (id) => refresh(() => selected = id),
            ),
          ),
        ),
      ),
    );
    expect(find.text(first.descEn), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tutorial_monster_picker')));
    await tester.pumpAndSettle();
    expect(find.text('Create a custom creature'), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('tutorial_monster_search')),
      second.nameEn,
    );
    await tester.pump();
    final details = find.text(second.descEn);
    expect(details, findsOneWidget);
    expect(tester.widget<Text>(details).maxLines, 2);
    await tester.tap(details);
    await tester.pumpAndSettle();
    expect(selected, second.id);
    expect(details, findsOneWidget);
    expect(find.text(first.descEn), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search, select, cancel and clear on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 680);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selectedId = '';
    final entries = defaultMonsterBookEntries
        .where((entry) => entry.presetType == 'Mostro')
        .toList();
    final chosen = entries.firstWhere(
      (entry) => entry.nameIt.toLowerCase() == 'snorlo',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => OculumMonsterPicker(
              entries: entries,
              selectedId: selectedId,
              onSelected: (id) => setState(() => selectedId = id),
            ),
          ),
        ),
      ),
    );
    final picker = find.byKey(const ValueKey('tutorial_monster_picker'));
    final search = find.byKey(const ValueKey('tutorial_monster_search'));
    await tester.tap(picker);
    await tester.pumpAndSettle();
    await tester.enterText(search, '  SNORLO  ');
    await tester.pump();
    await tester.tap(find.text(chosen.nameIt).last);
    await tester.pumpAndSettle();
    expect(selectedId, chosen.id);
    await tester.tap(picker);
    await tester.pumpAndSettle();
    await tester.enterText(search, 'missing-monster-xyz');
    await tester.pump();
    expect(find.text('Nessun mostro trovato'), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(selectedId, chosen.id);
    await tester.tap(picker);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crea una creatura libera'));
    await tester.pumpAndSettle();
    expect(selectedId, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'TAB completes a name and touch can select a spelling suggestion',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OculumMonsterIdField(
              controller: controller,
              lookup: oculumLookupMonsterId,
            ),
          ),
        ),
      );
      final input = find.byType(TextField);
      await tester.enterText(input, 'Remnath');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      const remnath = 'habitat_shadow_hell_caprone_della_memoria_bruciata';
      expect(controller.text, remnath);
      expect(find.text('Mostri simili'), findsNothing);

      await tester.enterText(input, 'Remnathh');
      await tester.tap(find.byTooltip('Trova ID del mostro'));
      await tester.pumpAndSettle();
      expect(find.text('Mostri simili'), findsOneWidget);
      expect(controller.text, 'Remnathh');
      expect(find.text(monsterById(remnath)!.descIt.trim()), findsWidgets);
      await tester.tap(find.text(remnath));
      await tester.pumpAndSettle();
      expect(controller.text, remnath);
    },
  );

  test('duplicate names remain explicit choices and exact IDs stay stable', () {
    const herald = 'habitat_morti_araldo_delle_tombe_aperte';
    const knight = 'habitat_morti_cavaliere_senza_epitaffio';
    final ambiguous = oculumLookupMonsterId('Tombwake');
    expect(ambiguous.exact, isNull);
    expect(
      ambiguous.suggestions.map((entry) => entry.id),
      containsAll([herald, knight]),
    );
    expect(oculumLookupMonsterId(knight).exact?.id, knight);
    expect(
      oculumLookupMonsterId('Cavaliere senza epitaffio').exact?.id,
      knight,
    );
  });

  testWidgets('partial monster names stay behind exact and prefix matches', (
    tester,
  ) async {
    final forest = monsterById('forest_demon')!;
    final exact = forest.copyWith(
      id: 'a_test_monster',
      nameIt: 'Demon',
      nameEn: 'Demon',
      encounterRules: const {},
    );
    final prefix = forest.copyWith(
      id: 'b_test_monster',
      nameIt: 'Demon Guard',
      nameEn: 'Demon Guard',
      encounterRules: const {},
    );
    final fragment = forest.copyWith(
      id: 'c_test_monster',
      nameIt: 'Eldemonix',
      nameEn: 'Eldemonix',
      encounterRules: const {},
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OculumMonsterPicker(
            entries: [fragment, forest, prefix, exact],
            selectedId: '',
            english: true,
            allowClear: false,
            onSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('tutorial_monster_picker')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('tutorial_monster_search')),
      'DeMoN',
    );
    await tester.pump();
    final positions = [
      exact,
      prefix,
      forest,
      fragment,
    ].map((entry) => tester.getTopLeft(find.text(entry.nameEn)).dy).toList();
    expect(positions, orderedEquals(positions.toList()..sort()));
  });

  testWidgets(
    'related monster names prefer the current element in the book picker',
    (tester) async {
      final base = monsterById('forest_demon')!;
      final first = base.copyWith(
        id: 'test_fire',
        nameIt: 'Sfera di Fuoco',
        nameEn: 'Sfera di Fuoco',
        elementId: 'fuoco',
        encounterRules: const {},
      );
      final second = base.copyWith(
        id: 'test_water',
        nameIt: 'Dardo di Acqua',
        nameEn: 'Dardo di Acqua',
        elementId: 'acqua',
        encounterRules: const {},
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OculumMonsterPicker(
              entries: [first, second],
              selectedId: '',
              allowClear: false,
              preferredElements: () => {'acqua'},
              onSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('tutorial_monster_picker')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('tutorial_monster_search')),
        'palla',
      );
      await tester.pump();
      expect(
        tester.getTopLeft(find.text(second.nameIt)).dy,
        lessThan(tester.getTopLeft(find.text(first.nameIt)).dy),
      );
      expect(
        find.descendant(
          of: find.byType(ListTile),
          matching: find.text('palla'),
        ),
        findsNothing,
      );
    },
  );
}
