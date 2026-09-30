import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/services/oculum_diary_memory.dart';

void main() {
  const demon = DiaryEntity('demon', 'Forest Demon', 'creature');
  DiaryMemory read(String text) => DiaryMemoryBuilder().build(
    [
      DiaryDocument(
        id: 'page',
        author: 'Hoshy',
        diary: 'Ricordi',
        title: 'Bosco',
        text: text,
        day: 1,
      ),
    ],
    [demon],
  );
  Set<String> states(DiaryMemory memory) => memory.relations
      .where((r) => r.from == 'character:hoshy' && r.to == 'demon')
      .map((r) => r.state)
      .toSet();
  final cases = <String, String>{
    'Il Forest Demon è fuggito.': 'escaped',
    'Abbiamo dovuto scappare dal Forest Demon.': 'we_escaped',
    'Ho sconfitto il Forest Demon.': 'defeated',
    'Ho ucciso il Forest Demon.': 'killed',
    'Ho incontrato un Forest Demon ma non abbiamo combattuto.': 'met',
    'Il Forest Demon ci ha sconfitti.': 'defeated_us',
    'Non so se il Forest Demon sia morto.': 'uncertain',
  };
  for (final entry in cases.entries) {
    test(entry.key, () {
      final result = states(read(entry.key));
      expect(result, contains(entry.value));
      if (!['defeated', 'killed'].contains(entry.value)) {
        expect(result.intersection({'defeated', 'felled', 'killed'}), isEmpty);
      }
      if (entry.value == 'met') expect(result, isNot(contains('fought')));
    });
  }
  test('fundamental example tracks location and the unambiguous pronoun', () {
    const text =
        'Oggi nel Bosco Nero ho affrontato un Forest Demon. Dopo un combattimento lunghissimo sono riuscito ad abbatterlo.';
    final memory = read(text);
    expect(states(memory), containsAll(['fought', 'felled']));
    expect(memory.entities.values.map((e) => e.name), contains('Bosco Nero'));
    expect(
      memory.relations.map((r) => r.state),
      containsAll(['visited', 'observed_at']),
    );
    for (final relation in memory.relations) {
      expect(
        text.substring(relation.evidence.start, relation.evidence.end),
        relation.evidence.quote,
      );
    }
  });
  test('negated and hypothetical outcomes cannot become victories', () {
    for (final text in [
      'Non ho ucciso il Forest Demon.',
      'Forse abbiamo sconfitto il Forest Demon.',
      'Vorrei ucciderlo, il Forest Demon.',
    ]) {
      expect(
        states(read(text)).intersection({'defeated', 'felled', 'killed'}),
        isEmpty,
      );
    }
  });
  test('rebuilding after correction removes stale outcomes', () {
    expect(states(read('Ho ucciso il Forest Demon.')), contains('killed'));
    expect(
      states(read('Il Forest Demon è fuggito.')),
      isNot(contains('killed')),
    );
  });
  test('typed links and resonances preserve independent evidence', () {
    final memory = DiaryMemoryBuilder().build([
      const DiaryDocument(
        id: 'a',
        author: 'Hoshy',
        diary: 'Ricordi',
        title: 'A',
        text: 'Ho parlato con [[png:Arven]].',
        day: 1,
      ),
      const DiaryDocument(
        id: 'b',
        author: 'Hoshy',
        diary: 'Segreti',
        title: 'B',
        text: '[[png:Arven]] ci ha traditi.',
        day: 2,
      ),
    ], []);
    expect(memory.entities['npc:arven']!.kind, 'npc');
    expect(memory.diariesFor('npc:arven'), hasLength(2));
    expect(
      memory.backlinks('npc:arven').map((r) => r.evidence.document.id).toSet(),
      {'a', 'b'},
    );
  });
  test(
    'unknown names require a link, multiple actors do not receive invented kills',
    () {
      expect(
        read('Ho ucciso qualcuno.').entities.containsKey('demon'),
        isFalse,
      );
      final memory = DiaryMemoryBuilder().build(
        [
          const DiaryDocument(
            id: 'a',
            author: 'Hoshy',
            diary: 'D',
            title: 'A',
            text: 'Forest Demon ha ucciso [[png:Arven]].',
            day: 1,
          ),
        ],
        [demon],
      );
      expect(states(memory), isNot(contains('killed')));
    },
  );
}
