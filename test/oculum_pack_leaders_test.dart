import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test('Six pack leaders retain their original skills and drops', () {
    final leaders = defaultMonsterBookEntries
        .where((monster) => monster.id.startsWith('pack_leader_'))
        .toList();
    expect(leaders, hasLength(6));
    for (final leader in leaders) {
      final base = monsterBookEntryById(
        leader.id.substring('pack_leader_'.length),
      )!;
      expect(leader.skillIds, base.skillIds);
      expect(leader.dropIds, base.dropIds);
      expect(leader.isMiniBoss, true);
      expect(leader.descIt, contains('Ricordo vitale'));
    }
  });
  test(
    'Half-life phase grants one shield, survives save and does not revive dead leaders',
    () {
      final sheet = <String, dynamic>{
        'monsterBookSourceId': 'pack_leader_papera_ranocchio',
        'resilienza': '8',
        'volonta': '5',
        'materia': '5',
        'oculum': '5',
        'currentHp': '41',
        'scudo': '2',
      };
      expect(oculumApplyPackLeaderPhase(sheet, maximumHp: 80), false);
      sheet['currentHp'] = '40';
      expect(oculumApplyPackLeaderPhase(sheet, maximumHp: 80), true);
      expect(sheet['scudo'], '10');
      expect(sheet['currentHp'], '80');
      expect(
        (sheet['activeStructuredEffects'] as List).where(
          (effect) => effect['remaining'] == 3,
        ),
        hasLength(4),
      );
      final restored = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(sheet)) as Map,
      );
      restored['currentHp'] = '30';
      expect(oculumApplyPackLeaderPhase(restored, maximumHp: 80), false);
      expect(restored['scudo'], '10');
      restored['packLeaderPhaseTriggered'] = false;
      restored['currentHp'] = '0';
      expect(oculumApplyPackLeaderPhase(restored, maximumHp: 80), false);
    },
  );
  test(
    'Native monster Art remains usable in a common Fallen Eye with identical cooldowns',
    () {
      final monster = monsterBookEntryById('pack_leader_weak_horror_mastino')!;
      final original = oculumMonsterBookArt(monster).toJson();
      final eye = <String, dynamic>{
        'sourceMonsterId': monster.id,
        'rarity': 'comune',
        'originalArts': [original],
        'sheetData': <String, dynamic>{'arti': []},
      };
      oculumFallenEyeApplyInheritedPowers(eye);
      expect(oculumFallenEyeEffectiveArtLimit(eye), 1);
      final body = eye['sheetData'] as Map;
      expect((body['arti'] as List).first['sbloccata'], true);
      expect(body['skills'], hasLength(2));
      expect((body['arti'] as List).first['skills'], original['skills']);
    },
  );
  testWidgets(
    'Leader phase works on an active sheet and its Fallen Eye body keeps the source',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const MaterialApp(home: OculumHomePage()));
      await tester.pump(const Duration(milliseconds: 700));
      final probe = OculumPerformanceProbe(
        tester.state(find.byType(OculumHomePage)),
      );
      final dynamic state = tester.state(find.byType(OculumHomePage));
      if ((state.schedePersonaggio as List).isEmpty) {
        state.schedePersonaggio.add(probe.snapshot());
        state.schedaCorrente = 0;
      }
      state.schedePersonaggio[state.schedaCorrente]['monsterBookSourceId'] =
          'pack_leader_papera_ranocchio';
      state.currentHpController.text = '1';
      expect(probe.triggerPackLeaderPhase(), true);
      final snapshot = probe.snapshot();
      expect(snapshot['packLeaderPhaseTriggered'], true);
      expect(probe.triggerPackLeaderPhase(), false);
      final body = probe.fallenEyeBodyFromSource(snapshot);
      expect(body['monsterBookSourceId'], 'pack_leader_papera_ranocchio');
      expect(body['packLeaderPhaseTriggered'], true);
      expect(
        (body['activeStructuredEffects'] as List).where(
          (effect) => effect['source'] == 'Capobranco: 200%',
        ),
        hasLength(4),
      );
    },
  );
}
