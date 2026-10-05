import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_eye_memory_page.dart';
import 'package:oculum/services/oculum_diary_memory.dart';
import 'package:oculum/services/oculum_diary_roles.dart';

void main() {
  testWidgets('Right click changes saved crafting state and opens history', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const entry = DiaryEntity('crafting:guanto', 'Guanto goblin', 'crafting');
    final memory = DiaryMemory({entry.id: entry}, []);
    final ledger = DiaryRoleLedger();
    await tester.pumpWidget(
      MaterialApp(
        home: OculumEyeMemoryPage(
          memory: memory,
          author: 'Hoshy',
          statusOf: ledger.statusOf,
          statusHistory: ledger.statusHistoryFor,
          onStatusChanged: (entity, status) async {
            ledger.changeStatus(entity, status, DateTime(2026, 10, 5));
          },
        ),
      ),
    );
    final chip = find.widgetWithText(ActionChip, 'Guanto goblin');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      chip,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final mouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await mouse.down(tester.getCenter(chip));
    await mouse.up();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cambia stato'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Completato').last);
    await tester.pumpAndSettle();
    expect(ledger.statusOf(entry), 'completed');
    expect(ledger.statusHistoryFor(entry).length, 1);
    expect(find.text('Stato: Completato'), findsOneWidget);
    expect(find.text('Cronologia degli stati'), findsOneWidget);
    await mouse.down(tester.getCenter(chip));
    await mouse.up();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cronologia'));
    await tester.pumpAndSettle();
    expect(find.text('Suggerito → Completato').last, findsOneWidget);
    expect(tester.takeException(), isNull);
    await mouse.removePointer();
  });
}
