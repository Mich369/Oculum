import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';

void main() {
  test('Italian combat labels keep their typography', () {
    expect(
      LiteHero.evasore.openDescription,
      'Scatto intangibile pi\u00f9 lungo.',
    );
    expect(LiteHero.duplicatore.openDescription, contains('d\u2019inchiostro'));
    expect(LiteBiome.postea.label, 'Postea \u00b7 Fonderie runiche');

    final run = LiteRun(
      seed: 251,
      hero: LiteHero.evasore,
      weapon: LiteWeapon.arco,
    );
    expect(
      run.quests.map((quest) => quest.name),
      contains('Abbatti l\u2019\u00e9lite'),
    );

    final saved = run.toJson();
    final quests = (saved['quests'] as List).cast<Map<String, dynamic>>();
    final elite = quests.singleWhere(
      (quest) => quest['name'] == 'Abbatti l\u2019\u00e9lite',
    );
    final id = elite['id'];
    elite['name'] = 'Abbatti l\u00e2\u20ac\u2122\u00c3\u00a9lite';
    elite['current'] = 1;
    final restored = LiteRun.fromJson(saved).quests
        .singleWhere((quest) => quest.id == id);
    expect(restored.name, 'Abbatti l\u2019\u00e9lite');
    expect(restored.current, 1);
  });
}
