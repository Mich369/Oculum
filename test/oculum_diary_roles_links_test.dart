import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:oculum/pages/oculum_eye_memory_page.dart';
import 'package:oculum/services/oculum_diary_links.dart';
import 'package:oculum/services/oculum_diary_memory.dart';
import 'package:oculum/services/oculum_diary_roles.dart';

void main() {
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
            onRoleChanged: (entity, role) async {
              ledger.change(entity, role, DateTime(2026, 10, 1));
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
      expect(memory.entities[entity.id]!.kind, 'enemy');
      expect(find.text('Soldato Forte · Nemico'), findsOneWidget);
      expect(find.text('Evoluzione del ruolo'), findsOneWidget);
      expect(memory.backlinks(entity.id), isNotEmpty);
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
