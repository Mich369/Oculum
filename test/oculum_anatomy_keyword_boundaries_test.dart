import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  final goblin = monsterBookEntryById('goblin_kamikaze')!;

  List<Map<String, dynamic>> parts(MonsterBookEntry entry, String group) =>
      oculumMonsterPrecisionAnatomy(
        entry,
      ).where((part) => part['group'] == group).toList();

  MonsterBookEntry custom(String weakPoint, {bool winged = false}) =>
      goblin.copyWith(
        id: 'qa_anatomy_word_boundaries',
        descIt: winged
            ? 'Un goblin alato con due braccia, due gambe e due ali.'
            : 'Un goblin con due braccia e due gambe.',
        weakPointIt: weakPoint,
        encounterRules: const {},
      );

  test('Goblin fuse text does not turn arms into additional weak points', () {
    expect(goblin.weakPointDescriptionIt, contains('partono'));
    expect(parts(goblin, 'arms'), hasLength(2));
    expect(
      parts(goblin, 'arms').every((part) => part['weak'] == false),
      isTrue,
    );
    expect(goblin.weakPointDescriptionIt, contains('innesco'));
  });

  test(
    'arm weak-point keywords match whole words, not unrelated substrings',
    () {
      for (final phrase in [
        'Il nodo da cui partono le micce.',
        'Il cuore del torso umano.',
        'La manopola al centro del torace.',
      ]) {
        final arms = parts(custom(phrase), 'arms');
        expect(arms, hasLength(2));
        expect(
          arms.every((part) => part['weak'] == false),
          isTrue,
          reason: phrase,
        );
      }
      for (final phrase in [
        'Il braccio.',
        'Le braccia.',
        'Il gomito.',
        'Il polso.',
        'La mano.',
        'Le mani.',
        'Un arto.',
      ]) {
        final arms = parts(custom(phrase), 'arms');
        expect(arms, hasLength(2));
        expect(
          arms.every((part) => part['weak'] == true),
          isTrue,
          reason: phrase,
        );
      }
    },
  );

  test('palate does not create wings or mark real wings as weak', () {
    expect(parts(custom('Il palato del muso.'), 'wings'), isEmpty);
    final realWings = parts(
      custom('Il palato del muso.', winged: true),
      'wings',
    );
    expect(realWings, hasLength(2));
    expect(realWings.every((part) => part['weak'] == false), isTrue);
    for (final phrase in ['La base delle ali.', 'La giuntura alare.']) {
      final wings = parts(custom(phrase), 'wings');
      expect(wings, hasLength(2));
      expect(
        wings.every((part) => part['weak'] == true),
        isTrue,
        reason: phrase,
      );
    }
  });
}
