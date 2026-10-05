import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/services/oculum_diary_memory.dart';
import 'package:oculum/services/oculum_memory_inspiration.dart';

class Rolls implements Random {
  Rolls(this.values);
  final List<int> values;
  @override
  int nextInt(int max) => values.removeAt(0);
  @override
  double nextDouble() => throw UnimplementedError();
  @override
  bool nextBool() => throw UnimplementedError();
}

DiaryMemory marked(int count) {
  final doc = DiaryDocument(
    id: 'stable',
    author: 'Hoshy',
    diary: 'D',
    title: 'S',
    text: List.filled(count, '[[Skill:Dardo]]').join(' '),
    day: 1,
  );
  return DiaryMemory(
    {'skill:dardo': const DiaryEntity('skill:dardo', 'Dardo', 'skill')},
    [
      DiaryRelation(
        'author',
        'skill:dardo',
        'mentioned',
        DiaryEvidence(doc, 0, doc.text.length),
      ),
    ],
  );
}

void main() {
  test(
    'Ten marks, failure bonus, persistence, cap and reset after success',
    () {
      final ledger = OculumMemoryInspiration();
      expect(ledger.observeRewards(marked(9), random: Rolls([])), isEmpty);
      expect(ledger.observeRewards(marked(10), random: Rolls([99])), isEmpty);
      expect(ledger.chance, 50);
      ledger.observeRewards(marked(11), random: Rolls([]));
      expect(ledger.chance, 55);
      ledger.observeRewards(marked(15), random: Rolls([]));
      expect(ledger.chance, 75);
      final restored = OculumMemoryInspiration.fromJson(ledger.toJson());
      expect(restored.observeRewards(marked(15), random: Rolls([])), isEmpty);
      expect(restored.observeRewards(marked(20), random: Rolls([74, 90])), [
        'oculum',
      ]);
      expect(restored.chance, 50);
      expect(restored.failed, isFalse);
      expect(restored.observeRewards(marked(20), random: Rolls([])), isEmpty);
    },
  );
  test('Difficulty changes starting probability and cap', () {
    for (final pair in {
      'facile': [50, 95],
      'normale': [50, 75],
      'difficile': [50, 60],
      'oculum': [25, 50],
    }.entries) {
      final ledger = OculumMemoryInspiration();
      ledger.observeRewards(
        marked(10),
        random: Rolls([99]),
        difficulty: pair.key,
      );
      expect(ledger.chance, pair.value.first);
      ledger.observeRewards(
        marked(19),
        random: Rolls([]),
        difficulty: pair.key,
      );
      expect(ledger.chance, pair.value.last);
      expect(
        ledger.observeRewards(
          marked(20),
          random: Rolls([0, 69]),
          difficulty: pair.key,
        ),
        ['base'],
      );
      expect(ledger.chance, pair.value.first);
    }
  });
  test('Tier boundaries are 70/20/10 and each block can yield only one', () {
    for (final tier in {
      69: 'base',
      70: 'super',
      89: 'super',
      90: 'oculum',
      99: 'oculum',
    }.entries) {
      expect(
        OculumMemoryInspiration().observeRewards(
          marked(10),
          random: Rolls([0, tier.key]),
        ),
        [tier.value],
      );
    }
  });
  test(
    'Unclassified names, role notes and source replay do not grant rewards',
    () {
      final memory = marked(0);
      expect(
        OculumMemoryInspiration().observeRewards(memory, random: Rolls([])),
        isEmpty,
      );
      final ledger = OculumMemoryInspiration();
      ledger.observeRewards(marked(10), random: Rolls([0, 0]));
      ledger.observeRewards(marked(2), random: Rolls([]));
      expect(ledger.observeRewards(marked(10), random: Rolls([])), isEmpty);
    },
  );
}
