import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_diary_memory.dart';

void main() {
  testWidgets(
    'long diary typing preserves calculations, cursor and source text',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final regular = await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
      for (final family in [
        'Poppins',
        'Roboto',
        'serif',
        'Segoe UI',
        'Garamond',
        'Georgia',
      ]) {
        await (FontLoader(family)..addFont(Future.value(regular))).load();
      }
      final icons = File(
        'build/unit_test_assets/fonts/MaterialIcons-Regular.otf',
      );
      if (icons.existsSync()) {
        await (FontLoader('MaterialIcons')..addFont(
              Future.value(ByteData.sublistView(icons.readAsBytesSync())),
            ))
            .load();
      }
      final directory = Directory('build/layout-test-data')
        ..createSync(recursive: true);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => directory.absolute.path,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        (_) async => ['none'],
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
        (_) async => null,
      );
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final capture = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: RepaintBoundary(key: capture, child: const OculumHomePage()),
        ),
      );
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pump(const Duration(seconds: 1));
      final dynamic state = tester.state(find.byType(OculumHomePage));
      final probe = OculumPerformanceProbe(state);
      final sheet = probe.snapshot();
      state.schedePersonaggio
        ..clear()
        ..addAll(
          List.generate(
            300,
            (i) => <String, dynamic>{
              ...sheet,
              'nome': 'Scheda $i',
              'sheetTag':
                  'TypingOcu:${i < 3 ? 3690 : 410 + i}X${i.toString().padLeft(3, '0')}',
            },
          ),
        );
      state.schedaCorrente = 0;
      probe.load(state.schedePersonaggio.first);

      state.journalEntries.add(
        JournalEntry(
          title: 'Scrittura fluida',
          description: '',
          cycleDay: 1,
          phase: 'Notte',
          location: '',
        ),
      );
      state.journalEntries.add(
        JournalEntry(
          title: 'Ricordo precedente',
          description: '[[Nemico:Quercia Sepolta]]',
          cycleDay: 0,
          phase: '',
          location: '',
        ),
      );
      showDialog<void>(
        context: tester.element(find.byType(OculumHomePage)),
        builder: (_) => Dialog(
          child: SizedBox(
            width: 650,
            height: 700,
            child: SingleChildScrollView(child: probe.diaryEntryTile(0)),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Scrittura fluida'));
      await tester.pump(const Duration(milliseconds: 500));
      final field = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Testo diario',
      );
      expect(field, findsOneWidget);
      final controller = tester.widget<TextField>(field).controller!;
      final revision = state.derivedDataRevision;
      final prefix = List.filled(
        500,
        'Nel Bosco Nero abbiamo incontrato un Forest Demon. ',
      ).join();
      for (var i = 1; i <= 12; i++) {
        await tester.enterText(field, '$prefix${'a' * i}');
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          state.derivedDataRevision,
          revision,
          reason: 'Diary typing must not invalidate character calculations',
        );
        expect(tester.widget<TextField>(field).controller, same(controller));
        expect(controller.selection.baseOffset, controller.text.length);
      }
      expect(state.journalEntries.first.description, controller.text);
      expect(state.schedePersonaggio.length, 300);
      await tester.pump(const Duration(milliseconds: 350));
      expect(state.derivedDataRevision, revision);
      expect(
        probe.snapshot()['journalEntries'][0]['description'],
        controller.text,
      );
      await tester.enterText(field, 'Ora [[querci');
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('[[Nemico:Quercia Sepolta]]'), findsOneWidget);
      await tester.tap(find.text('[[Nemico:Quercia Sepolta]]'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(controller.text, 'Ora [[Nemico:Quercia Sepolta]]');
      await tester.enterText(field, '[[Alleato:Soldato Forte]] e [[sold');
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('[[Alleato:Soldato Forte]]'), findsOneWidget);
      await tester.enterText(field, '[[Soldato Nuovo');
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('[[Party:Soldato Nuovo]]'), findsOneWidget);
      expect(find.text('[[Armatura:Soldato Nuovo]]'), findsOneWidget);
      const entity = DiaryEntity(
        'party:soldato forte',
        'Soldato Forte',
        'party',
      );
      state.diaryRoleLedger.change(entity, 'enemy', DateTime(2026, 10, 1));
      final saved = probe.snapshot();
      probe.load(saved);
      expect(state.diaryRoleLedger.roleOf(entity), 'enemy');
      expect(state.diaryRoleLedger.historyFor(entity), hasLength(1));
      expect(
        probe.snapshot()['journalEntries'][0]['description'],
        '[[Soldato Nuovo',
      );
      probe.cancelPendingSave();
      Navigator.of(tester.element(field)).pop();
      await tester.pump(const Duration(milliseconds: 500));
      state.journalEntries.first.description =
          'Nel [[Luogo:Bosco Nero]] ho incontrato [[NPC:Arven]].';
      showDialog<void>(
        context: tester.element(find.byType(OculumHomePage)),
        builder: (_) => Dialog(
          child: SizedBox(width: 900, height: 700, child: probe.storyPage()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Costellazione degli Occhi'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('story_eye_constellation')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('story_eye_constellation')));
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('MAPPA DEGLI OCCHI'), findsOneWidget);
      for (
        var attempt = 0;
        attempt < 40 &&
            find
                .text('Le parole restano. Gli Occhi ricordano.')
                .evaluate()
                .isEmpty;
        attempt++
      ) {
        await tester.runAsync(
          () async => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(
        find.text('Le parole restano. Gli Occhi ricordano.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}
