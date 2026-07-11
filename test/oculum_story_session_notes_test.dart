import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

OculumSessionNote _note(String id, DateTime createdAt) {
  return OculumSessionNote(
    id: id,
    author: 'Giocatore',
    authorTag: 'OCULUM-TEST',
    message: 'Messaggio $id',
    createdAt: createdAt,
  );
}

void main() {
  group('Oculum session notes', () {
    test('JSON round trip preserves author, message and UTC timestamp', () {
      final original = OculumSessionNote(
        id: 'note-round-trip',
        author: 'Michy',
        authorTag: 'OCULUM-MICHY',
        message: 'La porta a nord era sigillata.',
        createdAt: DateTime.utc(2026, 7, 10, 9, 5, 12),
      );

      final restored = OculumSessionNote.tryParse(original.toJson());

      expect(restored, isNotNull);
      expect(restored!.id, original.id);
      expect(restored.author, original.author);
      expect(restored.authorTag, original.authorTag);
      expect(restored.message, original.message);
      expect(restored.createdAt, original.createdAt);
      expect(restored.toJson()['createdAt'], '2026-07-10T09:05:12.000Z');
    });

    test(
      'legacy payload gets a deterministic id and empty notes are ignored',
      () {
        final legacy = <String, dynamic>{
          'playerName': 'Archivista',
          'senderTag': 'OLD-TAG',
          'text': 'Indizio importato',
          'sentAt': '2025-02-03T04:05:00Z',
        };

        final first = OculumSessionNote.tryParse(legacy);
        final second = OculumSessionNote.tryParse(legacy);

        expect(first, isNotNull);
        expect(first!.id, startsWith('legacy_'));
        expect(second!.id, first.id);
        expect(first.createdAt, DateTime.utc(2025, 2, 3, 4, 5));
        expect(
          OculumSessionNote.tryParse(<String, dynamic>{'message': '  '}),
          isNull,
        );
      },
    );

    test('sanitizes NUL characters and enforces the message limit', () {
      final sanitized = OculumSessionNote.tryParse(<String, dynamic>{
        'id': 'nul-note',
        'message': 'prima\u0000dopo',
        'createdAt': '2026-07-10T09:05:00Z',
      });
      final limited = OculumSessionNote.tryParse(<String, dynamic>{
        'id': 'long-note',
        'message': 'x' * (oculumSessionNoteMaxLength + 50),
        'createdAt': '2026-07-10T09:05:00Z',
      });

      expect(sanitized!.message, 'primadopo');
      expect(limited!.message.length, oculumSessionNoteMaxLength);
    });

    test('merge deduplicates by id and keeps chronological order', () {
      final early = _note('early', DateTime.utc(2026, 7, 10, 8));
      final late = _note('late', DateTime.utc(2026, 7, 10, 10));
      final duplicateLate = OculumSessionNote(
        id: late.id,
        author: 'Altro',
        authorTag: 'OTHER',
        message: 'Duplicato',
        createdAt: DateTime.utc(2026, 7, 10, 11),
      );
      final target = <OculumSessionNote>[late];

      final added = oculumMergeSessionNotes(target, <OculumSessionNote>[
        early,
        duplicateLate,
      ]);

      expect(added, 1);
      expect(target.map((note) => note.id), <String>['early', 'late']);
      expect(target.last.message, late.message);
    });

    test('snapshot serialization uses bounded chunks without data loss', () {
      final notes = <OculumSessionNote>[
        for (var i = 0; i < 5; i++)
          _note('note-$i', DateTime.utc(2026, 7, 10, 8, i)),
      ];

      final chunks = oculumSessionNoteJsonChunks(notes, chunkSize: 2);

      expect(chunks.map((chunk) => chunk.length), <int>[2, 2, 1]);
      expect(
        chunks.expand((chunk) => chunk).map((json) => json['id']),
        notes.map((note) => note.id),
      );
    });

    test('day and time labels always include the requested minute', () {
      final local = DateTime(2000, 7, 10, 9, 5);

      expect(oculumSessionNoteDayKey(local), '2000-07-10');
      expect(oculumSessionNoteDayLabel(local, english: false), '10/07/2000');
      expect(oculumSessionNoteTimeLabel(local), '09:05');
    });
  });
}
