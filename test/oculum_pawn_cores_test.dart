import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('Core tiers and market prices match the requested bands', () {
    expect(oculumCoreTiers.map((b) => (b.$2, b.$3)), [
      (0, 2),
      (3, 5),
      (6, 8),
      (9, 12),
    ]);
    expect(oculumCreatureCoreOffers().map((o) => o['cost']), [
      200,
      500,
      800,
      1200,
    ]);
  });

  test(
    'Mechanics threshold distinguishes broken, normal, conscious and scraps',
    () {
      expect(oculumCoreRepairDifficulty(10), 25);
      expect(
        oculumCoreRepairOutcome(natural: 10, total: 24, level: 10),
        'broken',
      );
      expect(
        oculumCoreRepairOutcome(natural: 10, total: 25, level: 10),
        'normal',
      );
      expect(
        oculumCoreRepairOutcome(natural: 15, total: 15, level: 0),
        'conscious',
      );
      expect(
        oculumCoreRepairOutcome(natural: 1, total: 200, level: 0),
        'scraps',
      );
      expect(
        oculumCoreRepairOutcome(natural: 20, total: 115, level: 200),
        'broken',
      );
    },
  );

  test('Broken core preserves the original Pawn identity', () {
    final pawn = OculumPawnGuardian(
      id: 'original',
      ownerTag: 'rose',
      level: 10,
      hp: 0,
      conscious: true,
    );
    final saved = InventoryItem.fromJson(
      oculumCreatureCore(0, source: pawn.toJson(), broken: true).toJson(),
    );
    expect(saved.craftData['brokenCore'], true);
    expect((saved.craftData['coreSource'] as Map)['id'], 'original');
    expect(OculumPawnGuardian.fromJson(pawn.toJson()).conscious, true);
  });
}
