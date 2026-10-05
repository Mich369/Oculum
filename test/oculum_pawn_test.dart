import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('Pawn starts at level zero with fixed stats and full health', () {
    final pawn = OculumPawnGuardian(id: 'pawn_test', ownerTag: 'sheet_a');

    expect(oculumPawnPrice, 100);
    expect(pawn.hp, 30);
    expect(pawn.shield, 0);
    expect(pawn.alive, isTrue);
    expect(pawn.targets, isEmpty);
    expect(oculumPawnDescription, contains('Resilienza 3'));
    expect(oculumPawnDescription, contains('Volontà 3'));
    expect(oculumPawnDescription, contains('Materia 5'));
    expect(oculumPawnDescription, contains('Oculum 0'));
  });

  test('Pawn intercepts target HP damage only after target shields', () {
    final pawn = OculumPawnGuardian(id: 'pawn_test', ownerTag: 'sheet_a');
    pawn.shield = 5;

    expect(pawn.intercept(8), 0);
    expect(pawn.shield, 0);
    expect(pawn.hp, 27);
  });

  test('Saving shield blocks overflow after Pawn shield is depleted', () {
    final pawn = OculumPawnGuardian(
      id: 'pawn_test',
      ownerTag: 'sheet_a',
      shield: 20,
      savingShield: true,
    );

    expect(pawn.intercept(25), 0);
    expect(pawn.shield, 0);
    expect(pawn.hp, 30);
    expect(pawn.savingShield, isFalse);
  });

  test('A Pawn heals ten per turn then gains shield and saving shield', () {
    final pawn = OculumPawnGuardian(
      id: 'pawn_test',
      ownerTag: 'sheet_a',
      hp: 15,
    );

    expect(pawn.advanceTo(1), isTrue);
    expect(pawn.hp, 25);
    expect(pawn.advanceTo(1), isFalse, reason: 'A turn cannot be repeated');
    expect(pawn.advanceTo(2), isTrue);
    expect(pawn.hp, 30);
    expect(pawn.shield, 0);
    expect(pawn.advanceTo(3), isTrue);
    expect(pawn.shield, 5);
    expect(pawn.advanceTo(6), isTrue);
    expect(pawn.shield, 20);
    expect(pawn.savingShield, isTrue);
  });

  test('Pawn earns levels at half standard XP with monster stat points', () {
    final pawn = OculumPawnGuardian(id: 'pawn_test', ownerTag: 'sheet_a');

    expect(oculumPawnExperienceForLevel('normale'), 500);
    expect(oculumPawnExperienceForLevel('oculum'), 685);
    expect(oculumPawnExperiencePerTurn, 25);
    expect(oculumPawnStatPointsPerLevel, 9);
    expect(pawn.advanceTo(19), isTrue);
    expect(pawn.experience, 475);
    expect(pawn.level, 0);
    expect(pawn.advanceTo(20), isTrue);
    expect(pawn.level, 1);
    expect(pawn.experience, 0);
    expect(pawn.unspentStatPoints, 9);
  });

  test('Allocating Pawn points grows stats and Resilience grows HP', () {
    final pawn = OculumPawnGuardian(
      id: 'pawn_test',
      ownerTag: 'sheet_a',
      hp: 20,
      unspentStatPoints: 9,
    );

    expect(
      pawn.allocateStatPoints({
        'resilienza': 2,
        'volonta': 2,
        'materia': 3,
        'oculum': 2,
      }),
      isTrue,
    );
    expect(pawn.stats, {
      'resilienza': 5,
      'volonta': 5,
      'materia': 8,
      'oculum': 2,
    });
    expect(pawn.maxHp, 50);
    expect(pawn.hp, 40);
    expect(pawn.unspentStatPoints, 0);
  });

  test('Dead or unregistered Pawns cannot intercept or advance', () {
    final unregistered = OculumPawnGuardian(
      id: 'pawn_pending',
      ownerTag: 'sheet_a',
      pendingRegistration: true,
    );
    expect(unregistered.intercept(7), 7);
    expect(unregistered.advanceTo(1), isFalse);

    final dead = OculumPawnGuardian(
      id: 'pawn_dead',
      ownerTag: 'sheet_a',
      hp: 0,
    );
    expect(dead.intercept(7), 7);
    expect(dead.advanceTo(1), isFalse);
  });

  test('Pawn campaign data survives serialization without changing stats', () {
    final original = OculumPawnGuardian(
      id: 'pawn_test',
      ownerTag: 'sheet_a',
      hp: 24,
      shield: 10,
      savingShield: true,
      turn: 3,
      targets: ['sheet_a', 'sheet_b'],
    );

    final restored = OculumPawnGuardian.fromJson(original.toJson());
    expect(restored.hp, 24);
    expect(restored.shield, 10);
    expect(restored.savingShield, isTrue);
    expect(restored.turn, 3);
    expect(restored.targets, ['sheet_a', 'sheet_b']);
    final grown = OculumPawnGuardian.fromJson({
      ...original.toJson(),
      'level': 2,
      'experience': 250,
      'unspentStatPoints': 4,
      'stats': {'resilienza': 4, 'volonta': 4, 'materia': 7, 'oculum': 1},
    });
    expect(grown.level, 2);
    expect(grown.experience, 250);
    expect(grown.unspentStatPoints, 4);
    expect(grown.stats['materia'], 7);
    expect(grown.maxHp, 40);
    final legacy = OculumPawnGuardian.fromJson({'id': 'old', 'ownerTag': 'a'});
    expect(legacy.stats, {
      'resilienza': 3,
      'volonta': 3,
      'materia': 5,
      'oculum': 0,
    });
    expect(legacy.level, 0);
  });
}
