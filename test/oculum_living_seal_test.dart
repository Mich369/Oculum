import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/widgets/oculum_living_seal.dart';

void main() {
  testWidgets('il sigillo mostra campagna e pagine e apre la mappa', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OculumLivingSeal(
            pageLabel: 'Diario',
            campaignLabel: 'Bosco Nero',
            sheetLabel: 'Hoshy',
            entryCount: 4,
            online: true,
            onPressed: () => opened = true,
          ),
        ),
      ),
    );

    expect(find.text('Bosco Nero'), findsOneWidget);
    expect(find.textContaining('4 pagine'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Bosco Nero · Hoshy · Diario')), findsWidgets);
    await tester.tap(find.text('Bosco Nero'));
    expect(opened, isTrue);
    semantics.dispose();
  });
}
