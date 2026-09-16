import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_dungeon/fallen_companion.dart';
void main() {
  test('capture chance is twenty percent', () {
    expect(List.generate(100, dungeonFallenCaptureSucceeds).where((v) => v).length, 20);
  });
  test('companions keep death bond and rebirths across reloads', () {
    var eye = DungeonFallenCompanion(id: '1', name: 'Snorlo', maxHp: 50, hp: 50, damage: 8, defense: 2, level: 5);
    eye.summon('fight1'); eye.summon('fight1'); expect(eye.bond, 15);
    eye.hp = 0; expect(eye.ownerLongRest('rest1'), false); eye.bond = 650;
    eye = DungeonFallenCompanion.fromJson(jsonDecode(jsonEncode(eye.toJson())) as Map<String, dynamic>);
    expect(eye.dead, true); expect(eye.ownerLongRest('rest2'), true);
    expect(eye.hp, 5); expect(eye.rebirthsUsed, 1); expect(eye.bond, 650);
    eye.hp = 0; expect(eye.ownerLongRest('rest2'), false); expect(eye.ownerLongRest('rest3'), true);
  });
  test('awakened companions wait for each distinct rest without consuming charges', () {
    final eye = DungeonFallenCompanion(id: '2', name: 'Boss', maxHp: 100, hp: 0, damage: 10, defense: 4, level: 10, oculumRarity: true)..bond = 1000;
    for (var i=0; i<100; i++) {eye.hp=0; expect(eye.ownerLongRest('$i'), true); expect(eye.hp,10);}
    expect(eye.rebirthsUsed, 0);
  });
}
