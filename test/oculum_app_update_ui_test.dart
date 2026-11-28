import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart' show oculumConfirmAppUpdate;

const _openDialog = 'Apri aggiornamento';

Future<bool? Function()> _mountUpdateDialog(
  WidgetTester tester, {
  bool incremental = false,
  String? windowsFullSize,
}) async {
  bool? confirmed;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              confirmed = await oculumConfirmAppUpdate(
                context,
                description: 'Versione verificata per la prova.',
                incremental: incremental,
                windowsFullSize: windowsFullSize,
              );
            },
            child: const Text(_openDialog),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text(_openDialog));
  await tester.pumpAndSettle();
  return () => confirmed;
}

void main() {
  testWidgets('Windows with a plan only offers the incremental update', (
    tester,
  ) async {
    final decision = await _mountUpdateDialog(tester, incremental: true);
    expect(find.text('Dopo'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Scarica le modifiche'),
      findsOneWidget,
    );
    expect(find.textContaining('Pacchetto intero'), findsNothing);
    expect(find.text('Aggiorna ora'), findsNothing);

    await tester.tap(find.text('Scarica le modifiche'));
    await tester.pumpAndSettle();
    expect(decision(), isTrue);
  });

  testWidgets(
    'Windows without a plan defaults to later, with an explicit ZIP',
    (tester) async {
      final decision = await _mountUpdateDialog(
        tester,
        windowsFullSize: '320.50 MB',
      );
      const fullLabel = 'Pacchetto intero (320.50 MB)';
      final later = find.widgetWithText(TextButton, 'Dopo');
      final full = find.widgetWithText(TextButton, fullLabel);
      expect(later, findsOneWidget);
      expect(full, findsOneWidget);
      expect(tester.widget<TextButton>(later).autofocus, isTrue);
      expect(tester.widget<TextButton>(full).autofocus, isFalse);
      expect(find.byType(FilledButton), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(decision(), isFalse);

      await tester.tap(find.text(_openDialog));
      await tester.pumpAndSettle();
      await tester.tap(full);
      await tester.pumpAndSettle();
      expect(decision(), isTrue);
    },
  );

  testWidgets('other platforms keep their normal confirmation', (tester) async {
    final decision = await _mountUpdateDialog(tester);
    expect(find.widgetWithText(FilledButton, 'Aggiorna ora'), findsOneWidget);
    expect(find.textContaining('Pacchetto intero'), findsNothing);
    await tester.tap(find.text('Dopo'));
    await tester.pumpAndSettle();
    expect(decision(), isFalse);
  });
}
