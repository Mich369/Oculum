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
  });
}
