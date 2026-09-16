import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

Map<String, dynamic> eye({
  int bond = 300,
  bool dead = true,
  String rarity = 'raro',
}) => {
  'id': 'eye',
  'ownerSheetId': 'owner',
  'rarity': rarity,
  'originalRarity': rarity,
  'bond': bond,
  'rebirthsUsed': 0,
  'perdutoPerSempre': dead,
  'deathWounds': dead ? 3 : 0,
  'currentHp': dead ? 0 : 200,
  'sheetData': {
    'currentHp': dead ? '0' : '200',
    'feriteMorte': dead ? 3 : 0,
    'livello': 5,
  },
};
bool rest(
  Map<String, dynamic> e, {
  String owner = 'owner',
  String event = 'rest1',
}) => oculumFallenEyeRebirthOnOwnerRest(
  e,
  ownerSheetId: owner,
  restEventId: event,
  maximumHp: 200,
);
void kill(Map<String, dynamic> e) {
  e['perdutoPerSempre'] = true;
  e['currentHp'] = 0;
  e['deathWounds'] = 3;
}

void main() {
  test('living and zero-charge eyes do not revive', () {
    final alive = eye(dead: false);
    expect(rest(alive), false);
    expect(alive['currentHp'], 200);
    final dead = eye(bond: 299);
    expect(rest(dead), false);
    expect(oculumFallenEyeIsDead(dead), true);
  });
  test(
    'death waits for owner rest, consumes one charge and preserves bond',
    () {
      final e = eye(bond: 650);
      expect(oculumFallenEyeIsDead(e), true);
      expect(rest(e, owner: 'another'), false);
      expect(rest(e), true);
      expect(e['currentHp'], 20);
      expect(e['rebirthsUsed'], 1);
      expect(e['bond'], 650);
      expect(oculumFallenEyeRebirthsAvailable(e), 1);
      expect(rest(e), false);
      kill(e);
      expect(rest(e), false);
      expect(rest(e, event: 'rest2'), true);
      expect(e['rebirthsUsed'], 2);
      kill(e);
      expect(rest(e, event: 'rest3'), false);
    },
  );
  test('awakened cycles remain unlimited and always wait for owner rest', () {
    final e = eye(bond: 1000, rarity: 'oculum')..['rebirthsUsed'] = 3;
    for (var i = 0; i < 100; i++) {
      kill(e);
      expect(oculumFallenEyeIsDead(e), true);
      expect(rest(e, owner: 'another', event: '$i'), false);
      expect(rest(e, event: '$i'), true);
      expect(e['currentHp'], 20);
      expect(e['rebirthsUsed'], 3);
      expect(e['bond'], 1000);
    }
    kill(e);
    expect(rest(e, event: '0'), false);
    expect(rest(e, event: 'next'), true);
  });
  test('save/reload and export/import preserve death and charges', () {
    var e = eye(bond: 650);
    rest(e);
    kill(e);
    for (var i = 0; i < 3; i++) {
      e = Map<String, dynamic>.from(jsonDecode(jsonEncode(e)) as Map);
      expect(oculumFallenEyeIsDead(e), true);
      expect(e['rebirthsUsed'], 1);
      expect(e['lastRebirthRestId'], 'rest1');
    }
    expect(rest(e), false);
    expect(rest(e, event: 'rest2'), true);
  });
  test('thresholds, summon gain, cap and original rarity', () {
    for (final row in [
      [0, 0],
      [299, 0],
      [300, 1],
      [599, 1],
      [600, 2],
      [899, 2],
      [900, 3],
      [999, 3],
      [1000, 3],
    ]) {
      expect(oculumFallenEyeRebirthsAvailable(eye(bond: row[0])), row[1]);
    }
    final e = eye(dead: false, bond: 990, rarity: 'oculum');
    oculumFallenEyeGrantSummonBond(e);
    expect(e['bond'], 1000);
    expect(oculumFallenEyeAwakened(e), true);
    final normal = eye(dead: false, bond: 0);
    oculumFallenEyeGrantSummonBond(normal);
    expect(normal['bond'], 15);
    normal['bond'] = 1000;
    normal['rarity'] = 'oculum';
    expect(oculumFallenEyeAwakened(normal), false);
  });
  test('natural awakening is one outcome in 1000 only after Oculum rarity', () {
    expect(
      List.generate(
        1000,
        (roll) => oculumFallenEyeNaturalAwakening('oculum', roll),
      ).where((v) => v).length,
      1,
    );
    expect(oculumFallenEyeNaturalAwakening('raro', 0), false);
    final legacy = eye(bond: 1000, rarity: 'oculum')..remove('originalRarity');
    legacy['reforgeHistory'] = [
      {'from': 'comune', 'to': 'non_comune'},
    ];
    expect(oculumFallenEyeAwakened(legacy), false);
  });
}
