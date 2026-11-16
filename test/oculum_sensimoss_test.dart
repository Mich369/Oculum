import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/oculum_sensimoss_rules.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test('Sensimoss has four legs and preserves saved custom anatomy', () {
    final monster = monsterBookEntryById('sensimoss')!;
    expect(monster.generationSide, 'neutral');
    final anatomy = oculumMonsterPrecisionAnatomy(monster);
    final legs = anatomy.where((part) => part['group'] == 'legs');
    expect(legs.map((part) => part['id']).toSet(), {
      'legs_1',
      'legs_2',
      'legs_3',
      'legs_4',
    });
    expect(anatomy.where((part) => part['group'] == 'eyes'), hasLength(2));
    expect(anatomy.where((part) => part['group'] == 'ears'), hasLength(2));
    final custom = monster.copyWith(
      encounterRules: const {
        'precisionBodyParts': [
          {'id': 'body', 'group': 'body', 'label': 'Corpo'},
        ],
      },
    );
    expect(oculumMonsterPrecisionAnatomy(custom).single['id'], 'body');
    expect(monster.skillIds, isEmpty);
  });

  test(
    'Power is live, private, requires sight and expires next personal turn',
    () {
      const reading = OculumSensimossReading(
        fightId: 'fight-a',
        teamId: 'team:green',
        personalTurnId: 'turn-3',
      );
      var power = 52;
      var reads = 0;
      int? read({
        String fight = 'fight-a',
        String turn = 'turn-3',
        String source = 'team:green',
        String viewer = 'team:green',
        String target = 'team:red',
        bool visible = true,
      }) => reading.readCurrentPower(
        activeFightId: fight,
        activePersonalTurnId: turn,
        sensimossTeamId: source,
        viewerTeamId: viewer,
        targetTeamId: target,
        hasLineOfSight: visible,
        currentPower: () {
          reads++;
          return power;
        },
      );

      expect(read(), 52);
      power = 48;
      expect(read(), 48);
      expect(read(viewer: 'team:red'), isNull);
      expect(read(source: 'team:red'), isNull);
      expect(read(target: 'team:green'), isNull);
      expect(read(target: ''), isNull);
      expect(read(visible: false), isNull);
      expect(read(turn: 'turn-4'), isNull);
      expect(read(fight: 'fight-b'), isNull);
      expect(reads, 2);
    },
  );
}
