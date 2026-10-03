import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/services/oculum_diary_memory.dart';
import 'package:oculum/services/oculum_memory_inspiration.dart';

class _FailUntilGuaranteed implements Random {
  @override
  int nextInt(int max) => max - 1;
  @override
  double nextDouble() => .99;
  @override
  bool nextBool() => false;
}

void main() {
  test(
    'mentions accumulate chance, source replay never grants more rewards',
    () {
      final document = DiaryDocument(
        id: 'stable',
        author: 'Hoshy',
        diary: 'D',
        title: 'S',
        text: List.filled(30, 'Quercia').join(' '),
        day: 1,
      );
      final memory = DiaryMemory(
        {'tree': const DiaryEntity('tree', 'Quercia', 'item')},
        List.generate(
          3,
          (i) => DiaryRelation(
            'author',
            'tree',
            'mentioned',
            DiaryEvidence(document, 0, document.text.length),
          ),
        ),
      );
      final ledger = OculumMemoryInspiration();
      expect(ledger.observe(memory, random: _FailUntilGuaranteed()), 1);
      expect(ledger.chance, 10);
      expect(ledger.observe(memory, random: _FailUntilGuaranteed()), 0);
      final restored = OculumMemoryInspiration.fromJson(ledger.toJson());
      expect(restored.observe(memory, random: _FailUntilGuaranteed()), 0);
    },
  );
}
