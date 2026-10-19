import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  testWidgets(
    'defense rolls can be added, saved and removed while CM stays available',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      state.hiddenEyeStats.clear();
      state.hiddenEyeStats.add(
        HiddenEyeStat(id: 'forza', nome: 'Forza', descrizione: ''),
      );
      final opening = probe.openCombatActionPanel(
        OculumCombatAbilityRole.defense,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.textContaining('Forza +'), findsNothing);
      await tester.tap(
        find.widgetWithText(TextButton, 'Aggiungi tiro difensivo'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.widgetWithText(SimpleDialogOption, 'Forza'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.textContaining('Forza +'), findsOneWidget);
      expect(probe.snapshot()['combatDefenseRollIds'], contains('forza'));
      await tester.tap(find.byTooltip('Rimuovi Forza'));
      await tester.pump();
      expect(find.textContaining('Forza +'), findsNothing);
      expect(find.textContaining('CM +'), findsOneWidget);
      expect(
        probe.snapshot()['combatDefenseRollIds'],
        isNot(contains('forza')),
      );
      await tester.tap(find.text('Chiudi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await opening;
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );
  for (final size in [const Size(1440, 900), const Size(390, 844)]) {
    testWidgets('combat panels separate rolls and abilities at $size', (
      tester,
    ) async {
      final dynamic state = await fixtures.mountSheet(tester, size);
      final probe = OculumPerformanceProbe(state);
      state.skills.clear();
      state.arti.clear();
      state.titoli.clear();
      state.trattiRazziali.clear();
      state.hiddenEyeStats.clear();
      state.hiddenEyeStats.addAll([
        HiddenEyeStat(id: 'forza', nome: 'Forza', descrizione: ''),
        HiddenEyeStat(id: 'resistenza', nome: 'Resistenza', descrizione: ''),
        HiddenEyeStat(id: 'medicina', nome: 'Medicina', descrizione: ''),
        HiddenEyeStat(
          id: 'riflessi',
          nome: 'Riflessi',
          descrizione: '',
          unlocked: false,
        ),
      ]);
      for (final role in OculumCombatAbilityRole.values) {
        final opened = probe.openCombatActionPanel(role);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        final panel = find.byType(AlertDialog).last;
        final texts = tester
            .widgetList<Text>(
              find.descendant(of: panel, matching: find.byType(Text)),
            )
            .map((t) => t.data ?? '')
            .join('\n');
        if (role == OculumCombatAbilityRole.attack) {
          expect(texts, contains('VC +'));
          expect(texts, contains('Forza'));
          expect(texts, isNot(contains('CM +')));
          expect(texts, isNot(contains('Medicina')));
        } else if (role == OculumCombatAbilityRole.defense) {
          expect(texts, contains('CM +'));
          expect(texts, contains('Resistenza'));
          expect(texts, isNot(contains('VC +')));
        } else {
          expect(texts, contains('Aiuta compagno'));
          expect(texts, contains('Medicina'));
          expect(texts, isNot(contains('VC +')));
        }
        expect(texts, isNot(contains('Riflessi')));
        expect(tester.takeException(), isNull);
        await tester.tap(
          find.descendant(of: panel, matching: find.text('Chiudi')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await opened;
      }
      final help = size.width < 500;
      final attackPanel = probe.openCombatActionPanel(
        help ? OculumCombatAbilityRole.support : OculumCombatAbilityRole.attack,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(
        help
            ? find.text('Aiuta compagno').last
            : find.textContaining('VC +').last,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await attackPanel;
      expect(find.byType(AlertDialog), findsNothing);
      expect(state.mostraOverlayDado, isTrue);
      expect(state.dadoMostratoFacce, help ? 10 : 20);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    });
  }
}
