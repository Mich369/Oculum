import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_dungeon/run_evolution.dart';

void main() {
  test('choice every three rooms, saved offers and no duplicate grants', () {
    var progress = DungeonEvolutionProgress();
    for (var room = 0; room < 72; room++) {
      if (room > 0 && room % 3 == 0) {
        expect(progress.due(room), true);
        progress.prepare(room, Random(room));
        final offered = List<String>.of(progress.offers);
        expect(offered.length, 3);
        expect(offered.toSet().length, 3);
        progress = DungeonEvolutionProgress.fromJson(jsonDecode(jsonEncode(progress.toJson())));
        progress.prepare(room, Random(999));
        expect(progress.offers, offered);
        expect(progress.choose('not-an-offer'), false);
        expect(progress.choose(offered.first), true);
        expect(progress.choose(offered.first), false);
        expect(progress.due(room), false);
      } else { expect(progress.due(room), false); }
    }
    expect(progress.history.length, 23);
    for (final choice in dungeonEvolutions) { expect(progress.rank(choice.id), lessThanOrEqualTo(3)); }
  });
  test('legacy checkpoints continue without granting missed upgrades', () {
    final progress = DungeonEvolutionProgress.fromJson(null, legacyRoom: 34);
    expect(progress.completed, 11);
    expect(progress.history, isEmpty);
    expect(progress.due(35), false);
    expect(progress.due(36), true);
  });
  test('new runs start empty and family synergy needs three picks', () {
    final progress = DungeonEvolutionProgress();
    progress.history.addAll(['fury', 'duelist']);
    expect(progress.synergy('assalto'), false);
    progress.history.add('last_spark');
    expect(progress.synergy('assalto'), true);
    expect(DungeonEvolutionProgress().history, isEmpty);
  });
}
