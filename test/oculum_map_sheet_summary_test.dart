import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  testWidgets(
    'map summary displays legacy HP without reviving a downed sheet',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      final legacy = <String, dynamic>{
        'sheetTag': 'LEGACYMAP',
        'nome': 'Scheda locale di prova',
        'tipoScheda': 'NPC',
        'derivedMaxHp': 64,
        'resilienza': 4,
        'volonta': 5,
      };
      final downed = <String, dynamic>{
        ...legacy,
        'sheetTag': 'SHAREDMAP',
        'nome': 'Scheda condivisa di prova',
        'personaggioCaduto': true,
      };
      final recordedZero = <String, dynamic>{
        ...legacy,
        'sheetTag': 'ZEROMAP',
        'nome': 'Scheda con Vita zero',
        'currentHp': '0',
        'volonta': 6,
      };
      final sharedLegacy = <String, dynamic>{
        ...legacy,
        'sheetTag': 'SHAREDLEGACY',
        'nome': 'Scheda condivisa senza Vita corrente',
        'volonta': 7,
      };
      state.updateOculumHomeUi(() {
        state.datiCaricati = true;
        state.modalitaDesktop = true;
        state.modalitaMaster = true;
        state.schedePersonaggio.addAll([legacy, recordedZero]);
        probe.ensureSheetTags();
        state.realtimeSharedSheets.addAll(<Map<String, dynamic>>[
          for (final sheet in [downed, sharedLegacy])
            {
              'key': sheet['sheetTag'],
              'ownerName': 'Partecipante di prova',
              'sheetName': sheet['nome'],
              'sheet': sheet,
            },
        ]);
        state.mapSplitPanelCount = 4;
        state.mapSplitPanels = <Map<String, dynamic>>[
          {'kind': 'sheet', 'sheetTag': legacy['sheetTag']},
          {'kind': 'shared', 'sheetTag': 'SHAREDMAP'},
          {'kind': 'sheet', 'sheetTag': recordedZero['sheetTag']},
          {'kind': 'shared', 'sheetTag': 'SHAREDLEGACY'},
        ];
        state.paginaCorrente = 10;
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      try {
        final maximum = oculumSheetHpMaximum(legacy);
        final mapList = find.byWidgetPredicate(
          (widget) =>
              widget is ListView &&
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>).value.endsWith('_map'),
        );
        await tester.scrollUntilVisible(
          find.text('Riquadri Mappa — 4/4'),
          400,
          scrollable: find
              .descendant(of: mapList, matching: find.byType(Scrollable))
              .first,
        );
        final localHp = find.text('HP $maximum • RES 4 • VOL 5');
        final summaryTexts = tester
            .widgetList<Text>(find.byType(Text, skipOffstage: false))
            .map((text) => text.data)
            .whereType<String>()
            .where((text) => text.startsWith('HP ') || text.contains('Scheda'));
        expect(localHp, findsOneWidget, reason: summaryTexts.join('\n'));
        expect(find.text('HP 0 • RES 4 • VOL 5'), findsOneWidget);
        expect(find.text('HP 0 • RES 4 • VOL 6'), findsOneWidget);
        expect(find.text('HP $maximum • RES 4 • VOL 7'), findsOneWidget);
        expect(legacy.containsKey('currentHp'), isFalse);
        expect(downed.containsKey('currentHp'), isFalse);
        state.updateOculumHomeUi(() {
          downed.remove('personaggioCaduto');
          downed['feriteMorte'] = 3;
        });
        await tester.pumpAndSettle();
        expect(find.text('HP 0 • RES 4 • VOL 5'), findsOneWidget);
      } finally {
        await closeFixture(tester, probe);
      }
    },
  );
}
