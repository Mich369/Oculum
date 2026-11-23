import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/services/oculum_rebirth_rules.dart';
import 'package:oculum/services/oculum_roll_rescue.dart';

void main() {
  test(
    'Rebirth quota uses the previous level and rounds the final result up',
    () {
      for (final row in [
        (0, 0),
        (1, 1),
        (10, 5),
        (20, 10),
        (25, 13),
        (99, 50),
      ]) {
        expect(oculumRebirthKillQuota(row.$1), row.$2);
      }
    },
  );

  test('party Rebirth roll bonuses distinguish self and other members', () {
    expect(
      oculumRebirthPartyRollExperiencePercent(
        rebirthed: true,
        otherRebirthedMembers: 0,
      ),
      12,
    );
    expect(
      oculumRebirthPartyRollExperiencePercent(
        rebirthed: true,
        otherRebirthedMembers: 2,
      ),
      42,
    );
    expect(
      oculumRebirthPartyRollExperiencePercent(
        rebirthed: false,
        otherRebirthedMembers: 2,
      ),
      30,
    );
  });

  test(
    'party Rebirth roll bonus carries fractional EXP across saved rolls',
    () {
      var remainder = 0;
      var total = 0;
      for (var roll = 0; roll < 4; roll++) {
        final result = oculumRebirthPartyRollExperienceGain(
          baseGain: 9,
          bonusPercent: 27,
          previousRemainder: remainder,
        );
        total += result.gain;
        remainder = result.remainder;
      }
      expect(total, 45); // 36 base + floor(36 × 27%).
      expect(remainder, 72);
      final restored = jsonDecode(jsonEncode({'bar': remainder})) as Map;
      final continued = oculumRebirthPartyRollExperienceGain(
        baseGain: 9,
        bonusPercent: 27,
        previousRemainder: restored['bar'] as int,
      );
      expect(continued.gain, 12);
      expect(continued.remainder, 15);
    },
  );

  test(
    'one guaranteed critical per campaign day survives save and clock rewind',
    () {
      final source = {
        'custom': {'keep': 99},
      };
      expect(
        oculumRebirthCriticalAvailable(
          rebirthed: true,
          campaignDay: 'a:3',
          state: source,
        ),
        true,
      );
      final consumed = oculumConsumeRebirthCritical(source, 'a:3');
      final restored = jsonDecode(jsonEncode(consumed)) as Map;
      expect(
        oculumRebirthCriticalAvailable(
          rebirthed: true,
          campaignDay: 'a:3',
          state: restored,
        ),
        false,
      );
      expect(
        oculumRebirthCriticalAvailable(
          rebirthed: true,
          campaignDay: 'a:4',
          state: restored,
        ),
        true,
      );
      expect(
        oculumRebirthCriticalAvailable(
          rebirthed: false,
          campaignDay: 'a:4',
          state: restored,
        ),
        false,
      );
      final second = oculumConsumeRebirthCritical(restored, 'a:4');
      expect(
        oculumRebirthCriticalAvailable(
          rebirthed: true,
          campaignDay: 'a:3',
          state: second,
        ),
        false,
      );
      expect(second['custom'], {'keep': 99});
      expect(source.containsKey('rebirthCriticalDaysUsed'), false);
    },
  );

  test(
    'outside Fight the daily rescue targets a shown negative critical only',
    () {
      expect(
        oculumRollRescueOptions(
          failed: true,
          negativeCritical: true,
          rebirthAvailable: true,
        ),
        {OculumRollRescue.rebirth},
      );
      expect(
        oculumRollRescueOptions(
          failed: true,
          negativeCritical: false,
          rebirthAvailable: true,
        ),
        isEmpty,
      );
      expect(
        oculumRollRescueOptions(
          failed: true,
          negativeCritical: true,
          rebirthAvailable: false,
        ),
        isEmpty,
      );
    },
  );

  test(
    'stronger monster from any killer gives1.9 EXP and consumes one slot',
    () {
      final result = oculumRebirthMonsterExperienceBonus(
        rebirthed: true,
        ownerPower: 50,
        progress: {'remaining': 13, 'custom': 7},
        monsters: [
          {'id': 'fight:weak', 'power': 49, 'experience': 50},
          {'id': 'fight:equal', 'power': 50, 'experience': 50},
          {
            'id': 'fight:strong',
            'power': 80,
            'experience': 100,
            'killerTag': 'ALLY',
          },
          {'id': 'fight:npc', 'power': 100, 'experience': 100, 'isNpc': true},
          {
            'id': 'fight:summon',
            'power': 100,
            'experience': 100,
            'isSummon': true,
          },
        ],
      );
      expect(result.bonus, 90);
      expect(100 + result.bonus, 190);
      expect(result.consumed, 1);
      expect(result.progress['remaining'], 12);
      expect(result.progress['custom'], 7);
      final restored = jsonDecode(jsonEncode(result.progress)) as Map;
      final repeat = oculumRebirthMonsterExperienceBonus(
        rebirthed: true,
        ownerPower: 50,
        progress: restored,
        monsters: [
          {'id': 'fight:strong', 'power': 80, 'experience': 100},
        ],
      );
      expect(repeat.bonus, 0);
      expect(repeat.consumed, 0);
      expect(repeat.progress['remaining'], 12);
    },
  );

  test(
    'quota ending mid-batch never boosts a later monster or a normal sheet',
    () {
      final monsters = [
        {'id': 'f:a', 'power': 70, 'experience': 10},
        {'id': 'f:b', 'power': 90, 'experience': 100},
      ];
      final result = oculumRebirthMonsterExperienceBonus(
        rebirthed: true,
        ownerPower: 50,
        progress: {'remaining': 1},
        monsters: monsters,
      );
      expect(result.bonus, 9);
      expect(result.progress['remaining'], 0);
      final normal = oculumRebirthMonsterExperienceBonus(
        rebirthed: false,
        ownerPower: 50,
        progress: {'remaining': 1},
        monsters: monsters,
      );
      expect(normal.bonus, 0);
      expect(normal.progress['remaining'], 1);
    },
  );
}
