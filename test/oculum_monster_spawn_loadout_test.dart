import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test(
    'catalogue gives ordinary monsters at least nine regular techniques',
    () {
      for (final monster in defaultMonsterBookEntries) {
        if (monster.isNpc || oculumMonsterHasFixedProgressionSkills(monster)) {
          continue;
        }
        final regular = monster.skillIds
            .where(
              (id) =>
                  !id.startsWith(oculumMonsterProgressionPrefix) ||
                  (int.tryParse(id.split('__').last) ?? 0) < 9,
            )
            .toSet();
        expect(regular.length, greaterThanOrEqualTo(9), reason: monster.id);
      }
    },
  );

  test(
    'ordinary spawn picks three distinct skills and one of two real Opens',
    () {
      final mimic = monsterById('mimic_base')!;
      final catalogue = oculumMonsterBookArt(mimic);
      final pool = oculumMonsterBookOpenPool(mimic, primary: catalogue);
      expect(pool, hasLength(2));
      final openNames = pool.map((art) => art.openName).toSet();
      expect(openNames, hasLength(2));
      expect(pool.last.openBuffEffects, isNotEmpty);
      expect(pool.last.openSkillEffects, isNotEmpty);
      expect(pool.last.openSkillCooldown?.amount, greaterThan(0));

      final choices = <String>{};
      final drawnOpens = <String>{};
      for (var seed = 0; seed < 16; seed++) {
        final loadout = oculumMonsterBookLoadout(
          mimic,
          random: Random(seed),
          level: 20,
        );
        final art = loadout.art!;
        final names = [
          for (final skill in loadout.skills)
            if (!skill.passiva) skill.nome,
          for (final skill in art.skills)
            if (!skill.tipoPerLivello(1).toLowerCase().contains('passiv'))
              skill.nome,
        ];
        expect(names, hasLength(3));
        expect(names.toSet(), hasLength(3));
        expect(names, everyElement(isIn(catalogue.skills.map((s) => s.nome))));
        expect(openNames, contains(art.openName));
        expect(CharacterArt.fromJson(art.toJson()).openName, art.openName);
        choices.add((names..sort()).join('|'));
        drawnOpens.add(art.openName);
      }
      expect(choices.length, greaterThan(1));
      expect(drawnOpens, openNames);
    },
  );

  test('catalogue moves remain aligned when only growth skills are present', () {
    final idrax = monsterById('idrax')!;
    final growth = idrax.skillIds
        .where((id) => id.startsWith(oculumMonsterProgressionPrefix))
        .toList();
    final art = oculumMonsterBookArt(idrax.copyWith(skillIds: growth));
    expect(
      art.skills.map((skill) => skill.nome),
      growth.map((id) => monsterBookConcreteTechnique(id)!.name),
    );
  });

  test('level-zero spawns prefer techniques usable at their level', () {
    final monster = monsterById('teschio_quattro_lame')!;
    final loadout = oculumMonsterBookLoadout(
      monster,
      random: Random(7),
      level: 0,
    );
    final active = loadout.skills.where((skill) => !skill.passiva);
    expect(active, hasLength(3));
    expect(active.map((skill) => skill.forme.first.livello), everyElement('0'));
  });

  test('a native multi-target technique has a slot when eligible', () {
    final monster = monsterById('teschio_quattro_lame')!;
    final loadout = oculumMonsterBookLoadout(
      monster,
      random: Random(11),
      level: 20,
    );
    final effects = [
      for (final skill in loadout.skills)
        ...skill.forme.first.effettiStrutturati,
      for (final skill in loadout.art?.skills ?? const <ArtSkill>[])
        ...skill.effettiEvoluzione(1),
    ];
    expect(effects.any((effect) => effect.maximumTargets == 4), isTrue);
  });

  test('explicit kits and personal entries keep their selected techniques', () {
    for (final id in ['nuvi', 'thunder_bot']) {
      final monster = monsterById(id)!;
      final result = oculumMonsterBookLoadout(monster, random: Random(1));
      expect(result.skills, hasLength(1), reason: id);
      expect(result.art, isNull, reason: id);
      expect(oculumMonsterBookOpenPool(monster), isEmpty, reason: id);
    }
    for (final id in [
      'coboldo_di_brina',
      'demonietto_bruciante',
      'demonietto_del_gelo',
    ]) {
      final monster = monsterById(id)!;
      final loadout = oculumMonsterBookLoadout(monster, random: Random(1));
      expect(loadout.skills, isEmpty, reason: id);
      expect(loadout.art, isNull, reason: id);
      expect(oculumMonsterBookOpenPool(monster), isEmpty, reason: id);
    }
    final collector = monsterById('collezionista_di_elementi')!;
    final collectorKit = oculumMonsterBookLoadout(collector, random: Random(1));
    expect(
      collectorKit.skills.length + (collectorKit.art?.skills.length ?? 0),
      1,
    );
    expect(oculumMonsterBookOpenPool(collector), isEmpty);
    final slime = monsterById('slime_roccioso')!;
    expect(
      oculumMonsterBookLoadout(slime, random: Random(1)).art?.openName,
      'Masso Slime',
    );
    final custom = monsterById(
      'mimic_base',
    )!.copyWith(skillIds: ['sticky_tongue']);
    final original = oculumMonsterBookSkills(custom).map((skill) => skill.nome);
    final chosen = oculumMonsterBookLoadout(custom, random: Random(11));
    expect(chosen.skills.map((skill) => skill.nome), original);
    expect(oculumMonsterBookOpenPool(custom), hasLength(1));
  });

  test('progression never gives the legless Idrax a limb attack', () {
    final idrax = monsterById('idrax')!;
    final ids = idrax.skillIds.where(
      (id) => id.startsWith(oculumMonsterProgressionPrefix),
    );
    expect(ids, hasLength(12));
    for (final id in ids) {
      final move = monsterBookConcreteTechnique(id)!;
      expect(move.element, idrax.elementId);
      expect(
        move.action.toLowerCase(),
        isNot(matches(RegExp(r'\b(?:braccia|braccio|gambe|zampe|ali|ala)\b'))),
        reason: id,
      );
    }
  });
}
