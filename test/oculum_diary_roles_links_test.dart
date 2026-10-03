import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:oculum/widgets/oculum_memory_eye.dart';
import 'package:oculum/pages/oculum_eye_memory_page.dart';
import 'package:oculum/services/oculum_diary_links.dart';
import 'package:oculum/services/oculum_diary_memory.dart';
import 'package:oculum/services/oculum_diary_roles.dart';

void main() {
  testWidgets(
    'Eye icon choices are usable on desktop and mobile without changing a death record',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 1100);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final font = await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
      await (FontLoader('Roboto')..addFont(Future.value(font))).load();
      final icons = File(
        'build/unit_test_assets/fonts/MaterialIcons-Regular.otf',
      );
      if (icons.existsSync()) {
        await (FontLoader('MaterialIcons')..addFont(
              Future.value(ByteData.sublistView(icons.readAsBytesSync())),
            ))
            .load();
      }
      final memory = DiaryMemoryBuilder().build([
        const DiaryDocument(
          id: 'demo',
          author: 'Hoshy',
          diary: 'Diario',
          title: 'Sessione 3',
          text:
              'Ho combattuto [[Nemico:Quercia Sepolta]] nel [[Luogo:Bosco Nero]].',
          day: 3,
        ),
      ], const []);
      final enemy = memory.entities.values.firstWhere(
        (e) => e.name == 'Quercia Sepolta',
      );
      final ledger = DiaryRoleLedger();
      ledger.change(
        enemy,
        'dead',
        DateTime(2026, 10, 1),
        note: 'Ucciso da [[Hoshy]] nel [[Luogo:Bosco Nero]].',
        noteAuthor: 'Master',
      );
      ledger.apply(memory);
      final capture = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: RepaintBoundary(
            key: capture,
            child: OculumEyeMemoryPage(
              memory: memory,
              author: 'Hoshy',
              eyeRole: ledger.eyeOf,
              roleHistory: ledger.historyFor,
              onEyeChanged: (entity, role) async {
                ledger.changeEye(entity, role);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ActionChip, 'Quercia Sepolta'));
      await tester.pumpAndSettle();
      Future<void> photo(String name) async {
        const label = String.fromEnvironment(
          'OculumBenchmarkLabel',
          defaultValue: 'eye-notes-preview',
        );
        await tester.runAsync(() async {
          final boundary =
              capture.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final directory = Directory('output/ui/$label')
            ..createSync(recursive: true);
          File(
            '${directory.path}/$name.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await photo('eye-death-desktop');
      for (final width in [1440.0, 390.0]) {
        tester.view.physicalSize = Size(width, width > 700 ? 1100 : 844);
        await tester.pumpAndSettle();
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Scegli occhio'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Scegli occhio'));
        await tester.pumpAndSettle();
        expect(find.text('Occhio dell’Oblio'), findsOneWidget);
        // Dialogs are painted in the navigator overlay, outside the page boundary.
        await tester.tap(find.text('Occhio dell’Oblio'));
        await tester.pumpAndSettle();
        expect(ledger.eyeOf(enemy), 'obliterated');
        expect(memory.entities[enemy.id]!.kind, 'dead');
        expect(
          find.byWidgetPredicate(
            (w) => w is OculumMemoryEye && w.role == 'obliterated',
          ),
          findsWidgets,
        );
        expect(tester.takeException(), isNull);
        await photo(width > 700 ? 'eye-custom-desktop' : 'eye-custom-mobile');
      }
      await tester.tap(find.text('Scegli occhio'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Automatico dal ruolo'));
      await tester.pumpAndSettle();
      expect(ledger.eyeOf(enemy), 'dead');
      expect(ledger.historyFor(enemy).single['note'], contains('Hoshy'));
    },
  );
  test(
    'a custom eye survives saving and role changes independently, with automatic reset',
    () {
      const entity = DiaryEntity('npc:arven', 'Arven', 'npc');
      final ledger = DiaryRoleLedger();
      expect(ledger.changeEye(entity, 'obliterated'), isTrue);
      expect(ledger.roleOf(entity), 'npc');
      ledger.change(entity, 'dead', DateTime(2026));
      final restored = DiaryRoleLedger.fromJson(
        jsonDecode(jsonEncode(ledger.toJson())),
      );
      expect(restored.eyeOf(entity), 'obliterated');
      expect(restored.roleOf(entity), 'dead');
      expect(restored.changeEye(entity, null), isTrue);
      expect(restored.eyeOf(entity), 'dead');
      expect(restored.changeEye(entity, 'invalid'), isFalse);
    },
  );
  test(
    'death notes connect the actual killer, retain evidence and survive reload without duplicates',
    () {
      const diary = DiaryDocument(
        id: 'original',
        author: 'Elyra',
        diary: 'Diario',
        title: 'Bosco',
        text: 'Ho incontrato [[Nemico:Quercia Sepolta]].',
        day: 3,
      );
      const hoshy = DiaryEntity('pg:hoshy', 'Hoshy', 'party');
      final memory = DiaryMemoryBuilder().build([diary], const []);
      final enemy = memory.entities.values.firstWhere(
        (e) => e.name == 'Quercia Sepolta',
      );
      final ledger = DiaryRoleLedger();
      ledger.change(
        enemy,
        'dead',
        DateTime(2026, 10, 1),
        note: 'Ucciso da [[Hoshy]] nel [[Luogo:Bosco Nero]].',
        noteAuthor: 'Master',
      );
      ledger.apply(memory, catalogue: [hoshy]);
      final kill = memory.relations.singleWhere((r) => r.state == 'killed');
      expect(kill.from, hoshy.id);
      expect(kill.to, enemy.id);
      expect(
        kill.evidence.quote,
        'Ucciso da [[Hoshy]] nel [[Luogo:Bosco Nero]].',
      );
      expect(kill.evidence.document.author, 'Master');
      expect(
        memory.relations.any(
          (r) => r.from == enemy.id && r.to == 'place:bosco nero',
        ),
        isTrue,
      );
      expect(diary.text, 'Ho incontrato [[Nemico:Quercia Sepolta]].');
      final count = memory.relations.length;
      ledger.apply(memory, catalogue: [hoshy]);
      expect(memory.relations.length, count);
      final restored = DiaryRoleLedger.fromJson(
        jsonDecode(jsonEncode(ledger.toJson())),
      );
      final reopened = DiaryMemoryBuilder().build([diary], const []);
      restored.apply(reopened, catalogue: [hoshy]);
      expect(
        reopened.relations.where((r) => r.state == 'killed'),
        hasLength(1),
      );
      expect(reopened.entities[enemy.id]!.kind, 'dead');
      expect(reopened.backlinks(hoshy.id), isNotEmpty);
    },
  );
  test(
    'uncertain or negated death attribution never confirms an invented killer',
    () {
      for (final note in [
        'Forse ucciso da Hoshy.',
        'Non è stato ucciso da Hoshy.',
        'Hoshy lo ha ucciso.',
        'Hoshy era presente.',
        'Hoshy ha ucciso Arven.',
        'Arven è stato ucciso da Hoshy.',
      ]) {
        const enemy = DiaryEntity('enemy:one', 'Nemico', 'enemy');
        const hoshy = DiaryEntity('party:one', 'Hoshy', 'party');
        final memory = DiaryMemory({enemy.id: enemy}, []);
        final ledger = DiaryRoleLedger();
        ledger.change(enemy, 'dead', DateTime(2026), note: note);
        ledger.apply(memory, catalogue: [hoshy]);
        expect(
          memory.relations.where((r) => r.state == 'killed').length,
          note == 'Hoshy lo ha ucciso.' ? 1 : 0,
        );
        if (note.startsWith('Forse')) {
          expect(
            memory.relations.where((r) => r.state == 'uncertain'),
            hasLength(1),
          );
        }
      }
    },
  );
  testWidgets(
    'the Eye changes a role while keeping the same central node and sources',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 1200);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final memory = DiaryMemoryBuilder().build([
        const DiaryDocument(
          id: 'one',
          author: 'Hoshy',
          diary: 'Diario',
          title: 'Sessione',
          text: '[[Alleato:Soldato Forte]] ci ha aiutato.',
          day: 1,
        ),
      ], const []);
      final ledger = DiaryRoleLedger();
      final entity = memory.entities.values.firstWhere(
        (e) => e.name == 'Soldato Forte',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: OculumEyeMemoryPage(
            memory: memory,
            author: 'Hoshy',
            roleHistory: ledger.historyFor,
            onRoleChangedWithNote: (entity, role, note) async {
              ledger.change(entity, role, DateTime(2026, 10, 1), note: note);
              ledger.apply(memory);
            },
          ),
        ),
      );
      await tester.tap(find.widgetWithText(ActionChip, 'Soldato Forte'));
      await tester.pump();
      await tester.tap(find.text('Cambia ruolo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nemico'));
      await tester.pumpAndSettle();
      expect(memory.entities[entity.id]!.kind, 'party');
      await tester.enterText(
        find.byType(TextFormField),
        'Ha tradito il party al ponte.',
      );
      await tester.tap(find.text('Conferma cambiamento'));
      await tester.pumpAndSettle();
      expect(memory.entities[entity.id]!.kind, 'enemy');
      expect(find.text('Soldato Forte · Nemico'), findsOneWidget);
      expect(find.text('Evoluzione del ruolo'), findsOneWidget);
      expect(memory.backlinks(entity.id), isNotEmpty);
      expect(
        ledger.historyFor(memory.entities[entity.id]!).last['note'],
        'Ha tradito il party al ponte.',
      );
      final restored = DiaryRoleLedger.fromJson(
        jsonDecode(jsonEncode(ledger.toJson())),
      );
      expect(
        restored.historyFor(memory.entities[entity.id]!).last['note'],
        'Ha tradito il party al ponte.',
      );
      await tester.tap(find.text('Evoluzione del ruolo'));
      await tester.pumpAndSettle();
      expect(find.text('Ha tradito il party al ponte.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'past explicit links suggest their original type and name from partial text',
    () {
      final catalogue = diaryEntitiesFromLinks([
        'Ho incontrato [[Nemico:Quercia Sepolta]].',
        '[[Alleato:Soldato Forte]] mi ha aiutato.',
      ]);
      const text = 'Oggi [[querci';
      expect(
        diaryLinkCompletions(text, text.length, catalogue),
        contains('[[Nemico:Quercia Sepolta]]'),
      );
      expect(catalogue.last.kind, 'party');
      final persisted = jsonDecode(
        jsonEncode({
          'journalEntries': [
            {'description': '[[Nemico:Quercia Sepolta]]'},
          ],
        }),
      );
      final restored = diaryEntitiesFromLinks([
        persisted['journalEntries'][0]['description'] as String,
      ]);
      expect(
        diaryLinkCompletions(text, text.length, restored),
        contains('[[Nemico:Quercia Sepolta]]'),
      );
    },
  );

  test(
    'new untyped names offer every classification without changing the text',
    () {
      for (final text in [
        '[[Soldato Forte',
        '[[Soldato Forte]]',
        '[[Soldato Forte[]]',
      ]) {
        final suggestions = diaryLinkCompletions(
          text,
          text.length,
          const [],
          limit: 1,
        );
        for (final type in diaryCreationLinkTypes) {
          expect(suggestions, contains('[[$type:Soldato Forte]]'));
        }
        final inserted = diaryInsertLink(
          text,
          text.length,
          '[[Party:Soldato Forte]]',
        );
        expect(inserted?.text, '[[Party:Soldato Forte]]');
      }
      const text = '[[Soldato Forte]]';
      final learned = diaryEntitiesFromLinks([text]);
      expect(
        diaryLinkCompletions(text, text.length, learned),
        contains('[[NPC:Soldato Forte]]'),
      );
    },
  );

  test(
    'single bracket still suggests after earlier closed links and preserves suffix',
    () {
      const text = '[[NPC:Arven]] e [quer seguito';
      final cursor = text.indexOf(' seguito');
      final catalogue = diaryEntitiesFromLinks(['[[Nemico:Quercia Sepolta]]']);
      expect(
        diaryLinkCompletions(text, cursor, catalogue),
        contains('[[Nemico:Quercia Sepolta]]'),
      );
      expect(
        diaryInsertLink(text, cursor, '[[Nemico:Quercia Sepolta]]')?.text,
        '[[NPC:Arven]] e [[Nemico:Quercia Sepolta]] seguito',
      );
      expect(diaryLinkCompletions('Quercia', 7, catalogue), isEmpty);
    },
  );

  test(
    'changing role retains identity, every source and durable evolution history',
    () {
      const source =
          '[[Alleato:Soldato Forte]] ha incontrato [[Mostro:Quercia Sepolta]].';
      const document = DiaryDocument(
        id: 'one',
        author: 'Hoshy',
        diary: 'Diario',
        title: 'Sessione',
        text: source,
        day: 3,
      );
      final memory = DiaryMemoryBuilder().build([document], const []);
      final original = memory.entities.values.firstWhere(
        (e) => e.name == 'Soldato Forte',
      );
      expect(original.kind, 'party');
      final relations = [...memory.relations];
      final ledger = DiaryRoleLedger.fromJson(null);
      final now = DateTime(2026, 10, 1);
      for (final role in ['enemy', 'dead', 'creature', 'fallen_eye']) {
        expect(ledger.change(memory.entities[original.id]!, role, now), isTrue);
        ledger.apply(memory);
        expect(memory.entities[original.id]!.kind, role);
        expect(memory.relations, relations);
        expect(memory.backlinks(original.id), isNotEmpty);
        expect(document.text, source);
      }
      expect(ledger.historyFor(original), hasLength(4));
      expect(ledger.change(original, 'fallen_eye', now), isFalse);
      expect(ledger.change(original, 'invalid', now), isFalse);
      final restored = DiaryRoleLedger.fromJson(
        jsonDecode(jsonEncode(ledger.toJson())),
      );
      final rebuilt = DiaryMemoryBuilder().build([document], const []);
      restored.apply(rebuilt);
      expect(rebuilt.entities[original.id]!.kind, 'fallen_eye');
      expect(restored.historyFor(original), hasLength(4));
    },
  );

  test(
    'explicit role aliases update memory classification without splitting a known identity',
    () {
      final memory = DiaryMemoryBuilder().build(
        [
          const DiaryDocument(
            id: 'one',
            author: 'Hoshy',
            diary: 'Diario',
            title: 'Sessione',
            text: '[[Alleato:Soldato Forte]]. Poi [[Nemico:Soldato Forte]].',
            day: 1,
          ),
        ],
        const [DiaryEntity('original-id', 'Soldato Forte', 'npc')],
      );
      expect(memory.entities['original-id']!.kind, 'enemy');
      expect(
        memory.entities.values.where((e) => e.name == 'Soldato Forte'),
        hasLength(1),
      );
    },
  );
}
