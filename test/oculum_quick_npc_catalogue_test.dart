import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  OculumCatalogueEntry choice(
    String id,
    String name, {
    String source = 'Origine',
  }) => (
    id: id,
    label: '$name · $source',
    art: ArtSkill(nome: name),
    natural: null,
  );

  test('Master Skill search accepts exact aliases and ranks near names', () {
    final candidate = choice('sonoreye:0', 'Eco intracranica');
    final similar = choice('other:1', 'Sonoryft maggiore');
    final unrelated = choice('other:2', 'Colpo di pressione');
    final choices = [similar, unrelated, candidate];

    for (final query in ['SONORYFT', 'Intracranial Echo', 'Eco intracranica']) {
      expect(
        oculumRankMasterSkillChoices(choices, query).first.id,
        candidate.id,
      );
    }
    expect(
      oculumRankMasterSkillChoices(choices, 'Sonoryfzt').first.id,
      candidate.id,
    );
    expect(oculumRankMasterSkillChoices(choices, 'non corrisponde'), isEmpty);
    expect(oculumRankMasterSkillChoices(choices, ''), choices);
    expect(
      oculumMasterSkillChoiceLabel(candidate),
      'Sonoryft · Eco intracranica · Origine',
    );
    expect(candidate.art.nome, 'Eco intracranica');
    expect(candidate.id, 'sonoreye:0');
  });

  test('Master Skill lookup searches only the eligible catalogue choices', () {
    final aquaChoices = oculumQuickNpcSkillChoices('acqua');
    final result = oculumRankMasterSkillChoices(aquaChoices, 'Aquaspyte').first;
    expect(result.art.nome, 'Getto d’Acqua');
    expect(oculumCatalogueElement(result), 'acqua');
    expect(
      oculumRankMasterSkillChoices(
        oculumQuickNpcSkillChoices('fuoco'),
        'Aquaspyte',
      ),
      isEmpty,
    );
  });

  test('Skill fragments follow exact names, prefixes, and complete words', () {
    final exact = choice('exact', 'Demon');
    final prefix = choice('leading', 'Demonico');
    final word = choice('word', 'Taglio Demon');
    final source = choice('forest_demon:0', 'Frana', source: 'Forest Demon');
    final wordPrefix = choice('word-prefix', 'Taglio Demonico');
    final fragment = choice('fragment', 'Taglio Semidemonico');
    final sameFragment = choice('same-fragment', 'Calcio Semidemonico');
    final typo = choice('typo', 'Deemon');
    final unrelated = choice('unrelated', 'Muro di ghiaccio');
    expect(
      oculumRankMasterSkillChoices([
        typo,
        unrelated,
        fragment,
        wordPrefix,
        source,
        sameFragment,
        word,
        prefix,
        exact,
      ], ' dÉmOn ').map((entry) => entry.id),
      [
        exact,
        prefix,
        word,
        source,
        wordPrefix,
        fragment,
        sameFragment,
        typo,
      ].map((entry) => entry.id),
    );
  });

  test('related projectile names prefer the current sheet elements', () {
    OculumCatalogueEntry attack(String id, String name, String element) => (
      id: id,
      label: name,
      art: ArtSkill(nome: name),
      natural: CharacterSkill(
        nome: name,
        tipo: 'Attacco',
        costo: '',
        cooldown: '',
        descrizione: '',
        scrollData: {'element': element},
      ),
    );
    final fire = attack('projectile_fire', 'Sfera di Fuoco', 'fuoco');
    final water = attack('projectile_water', 'Dardo di Acqua', 'acqua');
    final other = attack('other_water', 'Muro di Acqua', 'acqua');
    expect(
      oculumRankMasterSkillChoices(
        [fire, water, other],
        'sfera',
        preferredElements: {'acqua'},
      ).take(2),
      [water, fire],
    );
    expect(
      oculumRankMasterSkillChoices([
        fire,
        water,
        other,
      ], 'sparo energetico acqua'),
      [water],
    );
    expect(
      oculumRankMasterSkillChoices(
        [fire, water],
        'sfera',
        preferredElements: {'fuoco'},
      ).first,
      fire,
    );
    expect(water.art.nome, 'Dardo di Acqua');
  });

  test(
    'quick NPCs receive one distinct active technique per role with real costs',
    () {
      for (final element in [
        'fisico',
        'fuoco',
        'acqua',
        'gelo',
        'oculum',
        'angelico',
      ]) {
        final skills = oculumQuickNpcDefaults(element, 5);
        expect(
          skills.keys.toSet(),
          OculumCombatAbilityRole.values.toSet(),
          reason: element,
        );
        expect(
          skills.values.map((s) => s.nome).toSet().length,
          3,
          reason: element,
        );
        for (final entry in skills.entries) {
          expect(
            oculumCombatAbilityRoles(
              entry.value.forme.first.effettiStrutturati,
            ).contains(entry.key),
            true,
            reason: entry.value.nome,
          );
          expect(entry.value.forme.first.costoStrutturato, isNotNull);
          expect(entry.value.forme.first.cooldownStrutturato, isNotNull);
          final copy = CharacterSkill.fromJson(entry.value.toJson());
          expect(
            copy.forme.first.costoStrutturato!.toJson(),
            entry.value.forme.first.costoStrutturato!.toJson(),
          );
        }
      }
    },
  );
  test(
    'catalogue uses learning levels, stable order and an explicit next evolution',
    () {
      final entries = oculumAbilityCatalogueEntries();
      for (var i = 1; i < entries.length; i++) {
        expect(
          oculumCatalogueRequiredLevel(entries[i]),
          greaterThanOrEqualTo(oculumCatalogueRequiredLevel(entries[i - 1])),
        );
      }
      final art = ArtSkill(
        nome: 'Prova',
        evo1: 'I/Richiede livello 3.',
        evo2: 'II/Richiede livello 6.',
        evo3: 'III/Richiede livello 9.',
      );
      final entry = (
        id: 'test',
        label: 'Prova',
        art: art,
        natural: null as CharacterSkill?,
      );
      expect(oculumCatalogueProgressLabel(entry, 5), 'I · prossima II, lvl 6');
      expect(
        oculumCatalogueProgressLabel(entry, 6),
        'II · prossima III, lvl 9',
      );
      expect(oculumCatalogueProgressLabel(entry, 0), 'Livello richiesto 3');
    },
  );
}
