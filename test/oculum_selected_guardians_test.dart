import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

const _habitats = <String, String>{
  'ferrynox': 'postea',
  'ferrynox_variante_dune_vetro': 'deserto_divoratore',
  'ferrynox_variante_foresta_scoria': 'foresta_elementale',
  'anfravyre': 'sotterraneo',
  'anfravyre_variante_gallerie_indaco': 'sotterraneo',
  'anfravyre_variante_pietra_nera': 'sotterraneo',
};

MonsterBookEntry _entry(String id) => monsterBookEntryById(id)!;

void main() {
  test(
    'all six selected guardians resolve from the live book and habit filters',
    () {
      for (final entry in _habitats.entries) {
        final monster = _entry(entry.key);
        expect(
          defaultMonsterBookEntries.where((row) => row.id == entry.key),
          hasLength(1),
        );
        expect(oculumSavedMonsterBookEntryById(entry.key)?.id, entry.key);
        expect(oculumMonsterHabitats.containsKey(entry.value), isTrue);
        expect(oculumMonsterMatchesHabitatFilter(monster, entry.value), isTrue);
        expect(monster.skillIds, hasLength(2));
        expect(monster.encounterRules['authoredSkillPool'], isTrue);
        expect(monster.spriteAssetPath, isEmpty);
        if (entry.key.contains('_variante_')) {
          expect(
            monster.encounterRules['canonicalVariantOf'],
            entry.key.split('_variante_').first,
          );
        }
        expect(
          MonsterBookEntry.fromJson(monster.toJson()).skillIds,
          monster.skillIds,
        );
      }
    },
  );

  test('precision targeting sees six Ferrynox legs and Anfravyre wings', () {
    for (final id in _habitats.keys) {
      final parts = oculumMonsterPrecisionAnatomy(_entry(id));
      final ferrynox = id.startsWith('ferrynox');
      expect(
        parts.where((part) => part['group'] == 'legs'),
        hasLength(ferrynox ? 6 : 4),
      );
      expect(
        parts.where((part) => part['group'] == 'wings'),
        hasLength(ferrynox ? 0 : 2),
      );
      expect(parts.map((part) => part['id']).toSet(), hasLength(parts.length));
    }
  });

  test(
    'spawn resolves the twelve authored techniques in three editable forms',
    () {
      final sourceIds = <String>{};
      for (final id in _habitats.keys) {
        final monster = _entry(id);
        final declared = [
          for (final skill in monster.skillIds) oculumPlanarTechnique(skill)!,
        ];
        sourceIds.addAll(monster.skillIds);
        for (final seed in [0, 1, 7, 15]) {
          final loadout = oculumMonsterBookLoadout(
            monster,
            random: Random(seed),
            level: monster.stats['level'],
          );
          final art = loadout.art!;
          expect(
            art.skills.map((skill) => skill.nome),
            unorderedEquals(declared.map((move) => move.name)),
          );
          final restored = CharacterArt.fromJson(art.toJson());
          for (final move in declared) {
            final skill = restored.skills.singleWhere(
              (skill) => skill.nome == move.name,
            );
            for (var form = 1; form <= 3; form++) {
              expect(skill.effettiEvoluzione(form), hasLength(1));
              expect(skill.risorsaCostoPerLivello(form), move.costResource);
              expect(skill.oculumMinimoPerLivello(form), form + 1);
              expect(skill.cooldownPerLivello[form - 1].amount, greaterThan(0));
            }
            skill.impostaLimitiOculumPerLivello(1, minimo: 6, massimo: 6);
            expect(
              CharacterArt.fromJson(restored.toJson()).skills
                  .singleWhere((skill) => skill.nome == move.name)
                  .oculumMinimoPerLivello(1),
              6,
            );
          }
        }
      }
      expect(sourceIds, hasLength(12));
    },
  );

  test(
    'imported effects prime the wielder, apply shield and use one-turn modes',
    () {
      final ferrynox = oculumMonsterBookArt(_entry('ferrynox'));
      final strike = ferrynox.skills.first.effettiEvoluzione(1).single;
      expect(strike.type, 'danno');
      expect(strike.elementType, 'metallo');
      expect(strike.recipient, 'se_stesso');
      expect(strike.mode, 'prossima_azione');
      final shield = ferrynox.skills.last.effettiEvoluzione(1).single;
      expect(shield.type, 'scudo');
      expect(shield.valueExpression, '8');
      expect(shield.mode, 'immediato');
      final defence = oculumMonsterBookArt(
        _entry('ferrynox_variante_foresta_scoria'),
      ).skills.last.effettiEvoluzione(1).single;
      expect(defence.type, 'difesa');
      expect(defence.mode, 'temporaneo');
      expect(defence.duration, '1');
    },
  );
}
