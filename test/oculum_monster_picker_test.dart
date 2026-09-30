import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_monster_picker.dart';

void main() {
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
}
