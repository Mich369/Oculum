import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/services/oculum_diary_knowledge_sync.dart';
import 'package:oculum/services/oculum_diary_memory.dart';
import 'package:oculum/services/oculum_diary_roles.dart';

void main() {
  const entity = DiaryEntity('arven', 'Arven', 'npc');
  DiaryKnowledgeSync queued() => DiaryKnowledgeSync()
    ..enqueue(
      room: 'campaign',
      senderTag: 'master',
      recipients: ['player'],
      entity: entity,
      originalName: 'Arven',
      role: 'dead',
    );

  test('Solo il destinatario apre la comunicazione cifrata e autenticata', () {
    final master = queued(),
        player = DiaryKnowledgeSync(),
        outsider = DiaryKnowledgeSync();
    final envelope = master.seal(master.outbox.single, player.publicKey);
    expect(envelope.toString(), isNot(contains('Morto')));
    expect(player.open(envelope, master.publicKey)?['role'], 'dead');
    expect(outsider.open(envelope, master.publicKey), isNull);
    expect(
      player.open({...envelope, 'recipientTag': 'other'}, master.publicKey),
      isNull,
    );
    expect(player.open(envelope, outsider.publicKey), isNull);
    expect(
      player.open({...envelope, 'ciphertext': 'x' * 22001}, master.publicKey),
      isNull,
    );
  });

  test(
    'Coda persistente: solo ACK del destinatario elimina, senza resurrezione',
    () {
      final master = queued();
      final stale = DiaryKnowledgeSync.fromJson(master.toJson());
      final restored = DiaryKnowledgeSync.fromJson(master.toJson());
      expect(restored.publicKey, master.publicKey);
      final id = restored.outbox.single['id'] as String;
      expect(restored.acknowledge(id, 'outsider'), isFalse);
      expect(restored.outbox, hasLength(1));
      expect(restored.acknowledge(id, 'player'), isTrue);
      restored.mergeFrom(stale);
      expect(restored.outbox, isEmpty);
      expect(
        DiaryKnowledgeSync.fromJson(restored.toJson()).acknowledged,
        contains(id),
      );
    },
  );

  test(
    'Ricezione conserva provenienza, duplica nessun evento e rispetta i campi scelti',
    () {
      final master = queued(), player = DiaryKnowledgeSync();
      final command = master.outbox.single;
      expect(command['displayName'], isNull);
      expect(player.accept(command), isTrue);
      expect(player.accept(command), isFalse);
      final restored = DiaryKnowledgeSync.fromJson(player.toJson());
      expect(
        restored.documentsFor('campaign', 'player').single.text,
        contains('Morto'),
      );
      expect(restored.documentsFor('campaign', 'outsider'), isEmpty);
      final memory = DiaryMemory({'arven': entity}, []);
      restored.apply(memory, room: 'campaign', recipientTag: 'player');
      expect(memory.entities['arven']!.kind, 'dead');
      expect(memory.entities['arven']!.name, 'Arven');
      expect(
        player.accept({...command, 'id': 'invalid', 'revision': 'bad'}),
        isFalse,
      );
      expect(
        DiaryKnowledgeSync.fromJson({
          'received': [
            {'id': 'broken'},
          ],
        }).received,
        isEmpty,
      );
    },
  );

  test(
    'Rinomina privata conserva identità, alias, ruoli e diario originale',
    () {
      final ledger = DiaryRoleLedger();
      expect(ledger.rename(entity, 'Arven il Custode', DateTime(2026)), isTrue);
      expect(ledger.change(entity, 'enemy', DateTime(2026, 2)), isTrue);
      final restored = DiaryRoleLedger.fromJson(ledger.toJson());
      final memory = DiaryMemory({'arven': entity}, []);
      restored.apply(memory);
      expect(memory.entities['arven']!.id, 'arven');
      expect(memory.entities['arven']!.name, 'Arven il Custode');
      expect(memory.entities['arven']!.aliases, contains('Arven'));
      expect(memory.entities['arven']!.kind, 'enemy');
      expect(restored.originalNameOf(memory.entities['arven']!), 'Arven');
      expect(restored.nameHistoryFor(entity), hasLength(1));
      expect(restored.historyFor(entity), hasLength(1));
      expect(entity.name, 'Arven');
      expect(
        diaryPublicSheet({
          'hp': 30,
          'diaryEntityRoles': ledger.toJson(),
          'diaryKnowledgeSync': queued().toJson(),
        }),
        {'hp': 30},
      );
    },
  );
}
