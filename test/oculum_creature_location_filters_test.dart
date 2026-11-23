import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test('realm and microreality groups use authored memberships', () {
    for (final entry in monsterBookEntries) {
      expect(oculumMonsterMatchesHabitatFilter(entry, ''), true);
      expect(
        oculumMonsterMatchesHabitatFilter(entry, 'kind:microrealities'),
        entry.planeIds.any(oculumMicroRealityIds.contains),
        reason: entry.id,
      );
      expect(
        oculumMonsterMatchesHabitatFilter(entry, 'kind:realms'),
        entry.planeIds.any(
          (id) =>
              oculumMonsterHabitats.containsKey(id) &&
              !oculumMicroRealityIds.contains(id),
        ),
        reason: entry.id,
      );
    }
  });
  test(
    'a specific location does not pull creatures from another dimension',
    () {
      final postea = monsterBookEntries.firstWhere(
        (entry) => entry.planeIds.contains('postea'),
      );
      expect(oculumMonsterMatchesHabitatFilter(postea, 'postea'), true);
      if (!postea.planeIds.contains('affogato')) {
        expect(oculumMonsterMatchesHabitatFilter(postea, 'affogato'), false);
      }
      final unspecified = postea.copyWith(planeIds: []);
      expect(oculumMonsterMatchesHabitatFilter(unspecified, ''), true);
      expect(
        oculumMonsterMatchesHabitatFilter(unspecified, 'kind:realms'),
        false,
      );
      expect(
        oculumMonsterMatchesHabitatFilter(unspecified, 'kind:microrealities'),
        false,
      );
    },
  );
}
