import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  testWidgets('a scroll is consumed without automatically learning its skill', (
    tester,
  ) async {
    final dynamic state = await fixtures.mountSheet(
      tester,
      const Size(1440, 900),
    );
    final probe = OculumPerformanceProbe(state);
    final item = oculumScrollItem('luce', 'Luce', 12, 'ward');
    state.masterInitiativeTokens.clear();
    state.volontaController.text = '5';
    state.currentVolontaController.text = '10';
    state.oculumController.text = '0';
    state.currentOculumController.text = '0';
    state.inventario.add(item);
    final countBefore = (state.skills as List).length;
    final use = probe.useScroll(item);
    await tester.pump();
    expect(
      find.textContaining('Possibilità di apprendimento:'),
      findsOneWidget,
    );
    await tester.tap(find.text('Usa e tira'));
    await tester.pump();
    await tester.runAsync(() => use);
    expect(state.inventario.contains(item), isFalse);
    expect(item.quantita, 0);
    expect((state.skills as List).length, countBefore);
    expect(
      (state.logEventi as List).join('\n'),
      contains('Pergamena consumata:'),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });
}
