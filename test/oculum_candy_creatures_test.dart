import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/oculum_opposed_attack.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_monster_theme.dart';

void main() {
  test('Schianto di Volontà keeps all the Will on each selected target', () {
    expect(
      List.generate(5, (index) => oculumCandyWillSlamDamage(60, 12, index + 1)),
      [72, 72, 52, 42, 36],
    );
    final destroyer = monsterBookEntryById('distruttor_caramella')!;
    final art = oculumMonsterBookArt(destroyer);
    final skill = art.skills.singleWhere(
      (item) => item.nome == 'Schianto di Volontà',
    );
    final effect = skill.effettiEvoluzione(1).single;
    expect(effect.target, 'candy_will_slam');
    expect(effect.recipient, 'nemico');
    expect(effect.maximumTargets, greaterThan(5));
  });

  test('approved desktop themes keep the two Divoramitù apart', () {
    final base = monsterBookEntryById('divoramitu')!;
    final elite = monsterBookEntryById('divoramitu_elite')!;
    expect(base.encounterRules['canonicalVariantOf'], 'idrax');
    expect(elite.encounterRules['canonicalVariantOf'], 'divoramitu');
    expect(elite.nameIt, 'Divoramitù Elité');
    final assets = [
      base.id,
      elite.id,
      'distruttor_caramella',
    ].map(OculumMonsterTheme.desktopIllustrationForId);
    expect(assets.toSet(), hasLength(3));
    expect(assets, everyElement(isNotNull));
  });
}
