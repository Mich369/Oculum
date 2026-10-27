import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/widgets/oculum_settings_navigation.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  testWidgets(
    'shared navigation preserves independent search and phone selection',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var selected = 'combat';
      var query = '';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, update) => OculumSettingsNavigation(
                keyPrefix: 'master',
                searchLabel: 'Cerca negli strumenti Master',
                categories: const [
                  OculumSettingsCategory(
                    'combat',
                    'Combattimento',
                    Icons.shield,
                  ),
                  OculumSettingsCategory('party', 'Party', Icons.groups),
                ],
                selected: selected,
                query: query,
                onSearch: (value) => update(() => query = value),
                onSelect: (value) => update(() {
                  selected = value;
                  query = '';
                }),
              ),
            ),
          ),
        ),
      );
      final search = find.byKey(const ValueKey('master-search'));
      await tester.enterText(search, 'turni');
      await tester.pump();
      expect(query, 'turni');
      expect(tester.testTextInput.isVisible, isTrue);
      await tester.tap(find.byTooltip('Cancella ricerca'));
      await tester.pump();
      expect(query, isEmpty);
      await tester.tap(find.byKey(const ValueKey('master-category-combat')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Party').last);
      await tester.pumpAndSettle();
      expect(selected, 'party');
      expect(
        find.byKey(const ValueKey('master-category-party')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('settings-search')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Master categories search and permissions survive desktop and phone layouts',
    (tester) async {
      final errorHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        FlutterError.dumpErrorToConsole(details, forceReport: true);
        errorHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = errorHandler);
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 1000),
      );
      final probe = OculumPerformanceProbe(state);
      state.updateOculumHomeUi(() {
        state.modalitaMaster = true;
        state.paginaCorrente = 9;
      });
      for (final width in [1440.0, 320.0]) {
        tester.view.physicalSize = Size(width, 1000);
        for (final category in [
          'overview',
          'combat',
          'party',
          'creatures',
          'rewards',
          'session',
        ]) {
          state.updateOculumHomeUi(() {
            state.masterCategory = category;
            state.masterQuery = '';
          });
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$category at $width');
          expect(find.byKey(const ValueKey('master-search')), findsOneWidget);
        }
      }
      final search = find.byKey(const ValueKey('master-search'));
      await tester.ensureVisible(search);
      await tester.enterText(search, 'assegna schede');
      await tester.pumpAndSettle();
      expect(find.text('Regia'), findsWidgets);
      expect(tester.testTextInput.isVisible, isTrue);
      expect(state.settingsQuery, isEmpty);
      await tester.enterText(search, 'strumento inesistente xyz');
      await tester.pumpAndSettle();
      expect(find.textContaining('Nessuno strumento trovato'), findsOneWidget);
      await tester.tap(find.byTooltip('Cancella ricerca'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(search).controller!.text, isEmpty);
      state.updateOculumHomeUi(() {
        state.modalitaMaster = false;
        state.masterCategory = 'rewards';
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      probe.cancelPendingSave();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    },
  );
}
