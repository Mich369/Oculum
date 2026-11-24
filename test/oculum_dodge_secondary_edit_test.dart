import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

final _amount = find.byKey(const ValueKey('dodge-available-amount'));

Future<void> _dialogFrame(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Salva'));
  await _dialogFrame(tester);
  expect(tester.takeException(), isNull);
}

Future<void> _showControl(
  WidgetTester tester,
  dynamic state,
  OculumPerformanceProbe probe, {
  bool quickTile = false,
}) async {
  unawaited(
    showDialog<void>(
      context: state.context as BuildContext,
      builder: (_) => AlertDialog(
        content: SizedBox(
          width: 240,
          child: quickTile
              ? probe.dodgeQuickStatTile()
              : probe.dodgeActionButton(),
        ),
      ),
    ),
  );
  await _dialogFrame(tester);
}

void main() {
  testWidgets(
    'quantity editor rejects a stale balance and an oversized input',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      state.schivateOculumBonus = 3;
      await _showControl(tester, state, probe);
      await tester.longPress(find.byKey(const ValueKey('mobile-dodge')).last);
      await _dialogFrame(tester);
      await tester.enterText(_amount, '9999999999999999999999999');
      await tester.pump();
      expect(find.text('Quantità fuori intervallo.'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Salva'))
            .onPressed,
        isNull,
      );
      await tester.enterText(_amount, '4');
      await tester.pump();
      state.schivateOculumConsumate = 1;
      await _save(tester);
      expect(probe.dodgeAvailable(), 2);
      expect(state.schivateOculumConsumate, 1);
      expect(find.textContaining('Le Schivate sono cambiate'), findsOneWidget);
      expect(_amount, findsOneWidget);
      await closeFixture(tester, probe);
    },
  );

  testWidgets('preparation cannot spend a charge on another sheet', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    state.schivateOculumBonus = 2;
    await _showControl(tester, state, probe);
    await tester.tap(find.byKey(const ValueKey('mobile-dodge')).last);
    await _dialogFrame(tester);
    final other = {...probe.snapshot(), 'id': 'OTHER', 'sheetTag': 'OTHER'};
    state.schedePersonaggio.add(other);
    state.schedaCorrente = 1;
    probe.load(other);
    await tester.tap(find.text('Inferiore'));
    await _dialogFrame(tester);
    expect(probe.dodgeAvailable(), 2);
    expect(state.schivataOculumRiduzionePronta, 0);
    expect(state.schivateOculumConsumate, 0);
    expect(tester.takeException(), isNull);
    await closeFixture(tester, probe);
  });

  testWidgets('preparation scrolls and spends once on a short screen', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    tester.view.physicalSize = const Size(320, 360);
    state.schivateOculumBonus = 2;
    await _showControl(tester, state, probe);
    await tester.tap(find.byKey(const ValueKey('mobile-dodge')).last);
    await _dialogFrame(tester);
    final lastOption = find.text('Impossibile');
    await tester.ensureVisible(lastOption);
    await _dialogFrame(tester);
    await tester.tap(lastOption);
    await _dialogFrame(tester);
    expect(probe.dodgeAvailable(), 1);
    expect(state.schivataOculumRiduzionePronta, 50);
    expect(state.schivateOculumConsumate, 1);
    expect(tester.takeException(), isNull);
    await closeFixture(tester, probe);
  });

  testWidgets('a missing or restricted sheet cannot open the editor', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    state.schedePersonaggio[0]['realtimeRestrictedByMaster'] = true;
    await _showControl(tester, state, probe);
    final button = find.byKey(const ValueKey('mobile-dodge')).last;
    await tester.longPress(button);
    await _dialogFrame(tester);
    expect(_amount, findsNothing);
    final before = probe.snapshot()['schivateOculumBonus'];
    probe.quickEditDodge(1);
    expect(probe.snapshot()['schivateOculumBonus'], before);
    state.schedePersonaggio.clear();
    state.schedaCorrente = 0;
    probe.quickEditDodge(1);
    expect(probe.snapshot()['schivateOculumBonus'], before);
    await closeFixture(tester, probe);
  });

  for (final size in [const Size(390, 844), const Size(1440, 1000)]) {
    testWidgets('actual sheet keeps dodge control usable at ${size.width}', (
      tester,
    ) async {
      final (state, probe) = await mountFight(tester);
      tester.view.physicalSize = size;
      state.updateOculumHomeUi(() {
        state.datiCaricati = true;
        state.gradoController.text = '3';
        state.paginaCorrente = 0;
        state.referenceSheetSection = 'general';
      });
      await _dialogFrame(tester);
      final control = find.byWidgetPredicate(
        (widget) =>
            widget is GestureDetector &&
            widget.key == const ValueKey('mobile-dodge'),
      );
      expect(control, findsOneWidget);
      await tester.ensureVisible(control);
      await _dialogFrame(tester);
      expect(
        find.descendant(of: control, matching: find.text('Schivata 1')),
        findsOneWidget,
      );
      await tester.longPress(control);
      await _dialogFrame(tester);
      expect(_amount, findsOneWidget);
      expect(state.schivateOculumConsumate, 0);
      await tester.enterText(_amount, '3');
      await _save(tester);
      expect(
        find.descendant(of: control, matching: find.text('Schivata 3')),
        findsOneWidget,
      );
      // An ordinary tap continues to prepare a dodge rather than editing it.
      await tester.tap(control);
      await _dialogFrame(tester);
      expect(find.text('Inferiore'), findsOneWidget);
      expect(_amount, findsNothing);
      await closeFixture(tester, probe);
    });
  }

  testWidgets(
    'resource right click sets available count and keeps spent charges',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      state.schivateOculumBonus = 5;
      state.schivateOculumConsumate = 3;
      probe.openDodgeResources();
      await _dialogFrame(tester);
      final counter = find.byTooltip(
        'Tieni premuto o usa il tasto destro per modificare le Schivate',
      );
      expect(
        find.descendant(of: counter, matching: find.text('2')),
        findsOneWidget,
      );
      expect(find.text('2/5'), findsNothing);
      await tester.tap(counter, buttons: kSecondaryMouseButton);
      await _dialogFrame(tester);
      expect(tester.widget<TextField>(_amount).controller!.text, '2');
      await tester.enterText(_amount, '7');
      await _save(tester);
      expect(probe.dodgeAvailable(), 7);
      expect(state.schivateOculumConsumate, 3);
      final saved = probe.snapshot();
      probe.load(saved);
      expect(probe.dodgeAvailable(), 7);
      expect(probe.snapshot()['schivateOculumConsumate'], 3);
      await closeFixture(tester, probe);
    },
  );

  for (final size in [const Size(390, 844), const Size(1440, 1000)]) {
    testWidgets('sheet button long press edits grade charge at ${size.width}', (
      tester,
    ) async {
      final (state, probe) = await mountFight(tester);
      tester.view.physicalSize = size;
      state.gradoController.text = '3';
      await _showControl(tester, state, probe);
      final button = find.byKey(const ValueKey('mobile-dodge')).last;
      expect(
        find.descendant(of: button, matching: find.text('Schivata 1')),
        findsOneWidget,
      );
      expect(find.text('Schivata 1/1'), findsNothing);
      await tester.longPress(button);
      await _dialogFrame(tester);
      await tester.tap(find.byKey(const ValueKey('dodge-minus-one')));
      await tester.pump();
      expect(tester.widget<TextField>(_amount).controller!.text, '0');
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('dodge-minus-one')),
            )
            .onPressed,
        isNull,
      );
      await _save(tester);
      expect(probe.dodgeAvailable(), 0);
      expect(state.schivateOculumConsumate, 0);
      final saved = probe.snapshot();
      probe.load(saved);
      expect(probe.dodgeAvailable(), 0);
      expect(probe.snapshot()['schivateOculumRimosseManualmente'], 1);
      state.gradoController.text = '6';
      expect(probe.dodgeAvailable(), 1);
      await closeFixture(tester, probe);
    });
  }

  for (final quickTile in [false, true]) {
    testWidgets(
      'right click and +1 work on ${quickTile ? 'stat tile' : 'sheet button'}',
      (tester) async {
        final (state, probe) = await mountFight(tester);
        state.schivateOculumConsumate = 5;
        await _showControl(tester, state, probe, quickTile: quickTile);
        await tester.tap(
          quickTile
              ? find.text('Schivata Oculum').last
              : find.text('Schivata 0').last,
          buttons: kSecondaryMouseButton,
        );
        await _dialogFrame(tester);
        await tester.tap(find.byKey(const ValueKey('dodge-plus-one')));
        await tester.pump();
        expect(tester.widget<TextField>(_amount).controller!.text, '1');
        await _save(tester);
        expect(probe.dodgeAvailable(), 1);
        expect(state.schivateOculumConsumate, 5);
        await closeFixture(tester, probe);
      },
    );
  }

  testWidgets('quick tile long press supports typing and cancelling', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    state.schivateOculumBonus = 4;
    await _showControl(tester, state, probe, quickTile: true);
    await tester.longPress(find.text('Schivata Oculum').last);
    await _dialogFrame(tester);
    await tester.enterText(_amount, '');
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Salva'))
          .onPressed,
      isNull,
    );
    await tester.enterText(_amount, '19');
    await tester.tap(find.widgetWithText(TextButton, 'Annulla'));
    await _dialogFrame(tester);
    expect(probe.dodgeAvailable(), 4);
    expect(tester.takeException(), isNull);
    await closeFixture(tester, probe);
  });

  for (final changed in ['sheet', 'campaign', 'room', 'permission']) {
    testWidgets('open editor cannot modify a changed $changed', (tester) async {
      final (state, probe) = await mountFight(tester);
      state.schivateOculumBonus = 2;
      await _showControl(tester, state, probe);
      await tester.longPress(find.byKey(const ValueKey('mobile-dodge')).last);
      await _dialogFrame(tester);
      await tester.enterText(_amount, '12');
      switch (changed) {
        case 'sheet':
          final other = {
            ...probe.snapshot(),
            'id': 'OTHER',
            'sheetTag': 'OTHER',
            'schivateOculumBonus': 8,
          };
          state.schedePersonaggio.add(other);
          state.schedaCorrente = 1;
          probe.load(other);
        case 'campaign':
          state.activeCampaignId = 'different-campaign';
        case 'room':
          state.realtimeRoomController.text = 'different-room';
        case 'permission':
          state.schedePersonaggio[0]['realtimeReadOnlyByMaster'] = true;
      }
      final before = probe.snapshot();
      await _save(tester);
      expect(
        find.text('La scheda attiva o i suoi permessi sono cambiati.'),
        findsOneWidget,
      );
      expect(
        probe.snapshot()['schivateOculumBonus'],
        before['schivateOculumBonus'],
      );
      expect(
        probe.snapshot()['schivateOculumConsumate'],
        before['schivateOculumConsumate'],
      );
      expect(
        probe.snapshot()['schivateOculumRimosseManualmente'],
        before['schivateOculumRimosseManualmente'],
      );
      await closeFixture(tester, probe);
    });
  }

  testWidgets(
    'quick corrections preserve legacy saves and cannot go below zero',
    (tester) async {
      final (_, probe) = await mountFight(tester);
      final oldSave = {
        ...probe.snapshot(),
        'grado': '6',
        'schivateOculumConsumate': 1,
      }..remove('schivateOculumRimosseManualmente');
      probe.load(oldSave);
      expect(probe.dodgeAvailable(), 1);
      probe.quickEditDodge(-1);
      expect(probe.dodgeAvailable(), 0);
      probe.quickEditDodge(-1);
      expect(probe.snapshot()['schivateOculumRimosseManualmente'], 1);
      probe.quickEditDodge(1);
      expect(probe.dodgeAvailable(), 1);
      expect(probe.snapshot()['schivateOculumConsumate'], 1);
      probe.load(oldSave);
      expect(probe.dodgeAvailable(), 1);
      expect(probe.snapshot()['schivateOculumRimosseManualmente'], 0);
      await closeFixture(tester, probe);
    },
  );
}
