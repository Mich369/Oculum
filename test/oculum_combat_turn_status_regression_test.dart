import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  Map<String, dynamic> fight() => {
    'encounterId': 'merged-fight',
    'mergedEncounterIds': ['original-fight'],
    'fightOrdinal': 4,
    'activeIndex': 0,
    'tokens': [
      {'id': 'LEADER', 'name': 'Lusier', 'status': 'active'},
      {'id': 'SENKA', 'name': 'Senka', 'status': 'ready'},
    ],
  };
  Map<String, dynamic> rolling({String fightId = 'original-fight'}) => {
    'encounterId': fightId,
    'sheetTag': 'senka',
    'resource': 'reazione',
    'activityResource': 'reazione_veloce',
  };

  test(
    'rolling fast reaction survives a shared fight merge without moving the active turn',
    () {
      final encounter = fight();
      expect(
        oculumCombatTurnStatus(encounter, rollingSpends: [rolling()]),
        'Fight IV | Reazione Veloce Senka | turno di Lusier',
      );
      expect(encounter['activeIndex'], 0);
      expect(
        oculumCombatTurnStatus(
          encounter,
          rollingSpends: [rolling(fightId: 'unrelated')],
        ),
        'Fight IV | Azione Lusier',
      );
    },
  );

  test('completed fight clears a still visible rolling reaction', () {
    final encounter = fight()..['combatEnded'] = true;
    expect(
      oculumCombatTurnStatus(
        encounter,
        rollingSpends: [rolling(fightId: 'merged-fight')],
      ),
      'Fight IV | Azione Lusier',
    );
  });

  test('completed spends do not replace the current acting participant', () {
    final encounter = fight();
    expect(
      oculumCombatTurnStatus(
        encounter,
        rollingSpends: [rolling()..['activityComplete'] = true],
      ),
      'Fight IV | Azione Lusier',
    );
  });
}
