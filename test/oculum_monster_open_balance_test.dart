import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

// Complete fixed-progression kits from monster_progression_pool.dart, apart
// from Soul Fighter and Durafur whose forms are checked in detail below.
// These are the authored ability sets, not ordinary pools missing an Open.
// Sources: goblin_king.dart; mutant_rat.dart; oculiath.dart; sonoreye.dart;
// cynervail.dart; aculotide.dart; elemental_collector.dart; earth_wood_wanderers;
// and canonical_monster_variants.dart (Nuvi/Thunder Bot). The confirmed-rules
// sections describe each kit. Sensimoss's private reading remains deferred.
const _fixedNoOpenTechniqueKits = <String, List<String>>{
  'nuvi': ['nuvi_flight'],
  'thunder_bot': ['thunder_bot_explosion'],
  'collezionista_di_elementi': ['collettore_martello_elementale'],
  'demonietto_bruciante': [],
  'demonietto_del_gelo': [],
  'coboldo_di_brina': [],
  'goblin_king': [
    'goblin_king_guardian',
    'goblin_king_vanish',
    'goblin_king_regal_strike',
  ],
  'topo_mutante': ['mutant_rat_summon'],
  'oculiath': ['oculiath_ray'],
  'oculiath_minore': ['oculiath_lesser_ray'],
  'oculiath_maggiore': ['oculiath_greater_ray'],
  'sonoreye': ['sonoreye_eco_intracranica', 'sonoreye_rintocco_arresto'],
  'cynervail': ['cynervail_velo_incenso', 'cynervail_sigillo'],
  'aculotide': ['aculotide_guizzo', 'aculotide_corona'],
  'sensimoss': [],
};

void _expectFixedNoOpenTechniqueKit(
  MonsterBookEntry monster,
  CharacterArt art,
  List<String> expectedIds,
) {
  expect(oculumMonsterHasFixedProgressionSkills(monster), isTrue);
  expect(
    monster.skillIds.map(oculumMonsterBookSkillBaseId),
    expectedIds,
    reason: monster.id,
  );
  expect(art.skills, hasLength(expectedIds.length), reason: monster.id);
  expect(art.openName, isEmpty, reason: monster.id);
  expect(art.openBuff, isEmpty, reason: monster.id);
  expect(art.openBuffEffects, isEmpty, reason: monster.id);
  expect(art.openDescriptionEffects, isEmpty, reason: monster.id);
  expect(art.openSkill, isEmpty, reason: monster.id);
  expect(art.openSkillEffects, isEmpty, reason: monster.id);
  expect(art.openSkillCooldown?.amount ?? 0, 0, reason: monster.id);
  expect(
    oculumMonsterBookOpenPool(monster, primary: art),
    isEmpty,
    reason: monster.id,
  );
  expect(oculumMonsterBookWeakOpen(monster, art), isNull, reason: monster.id);
  expect(CharacterArt.fromJson(art.toJson()).toJson(), art.toJson());

  if (monster.id == 'topo_mutante') {
    // Confirmed rules, Topo Mutante: one summon, three authored forms. Its
    // one-Reaction rat pups do not authorize a second attack or generic Open.
    expect(oculumMonsterHasOculumArt(monster), isTrue);
    final skill = art.skills.single;
    expect(skill.nome, 'Richiamo dalla grata');
    for (var form = 1; form <= 3; form++) {
      expect(skill.risorsaCostoPerLivello(form), 'oculum');
      expect(skill.oculumMinimoPerLivello(form), [3, 5, 7][form - 1]);
      expect(skill.oculumMassimoPerLivello(form), [3, 5, 7][form - 1]);
      expect(skill.cooldownPerLivello[form - 1].amount, 4);
      final effect = skill.effettiEvoluzione(form).single;
      expect(effect.type, 'evocazione');
      expect(effect.target, 'mutant_rat_summon');
      expect(effect.valueExpression, ['1d4', '1d6+1', '1d9+3'][form - 1]);
    }
  }
}

void _expectNoOpenAuthoredKit(MonsterBookEntry monster, CharacterArt primary) {
  void expectNoOpen(CharacterArt art) {
    expect(art.openName, isEmpty, reason: monster.id);
    expect(art.openBuff, isEmpty, reason: monster.id);
    expect(art.openBuffEffects, isEmpty, reason: monster.id);
    expect(art.openDescriptionEffects, isEmpty, reason: monster.id);
    expect(art.openSkill, isEmpty, reason: monster.id);
    expect(art.openSkillEffects, isEmpty, reason: monster.id);
    expect(art.openSkillCooldown?.amount ?? 0, 0, reason: monster.id);
  }

  expectNoOpen(primary);
  if (oculumIsSoulFighter(monster.id)) {
    expect(monster.skillIds, [
      'soul_fighter_cut',
      'soul_fighter_guard',
      'soul_fighter_skull',
    ]);
    final arts = <CharacterArt>[
      primary,
      ...oculumMonsterBookAdditionalArts(monster),
    ];
    final elite = monster.id == oculumSoulFighterEliteId;
    expect(arts.map((art) => art.nome), [
      'Filo dell’Ultimo Respiro',
      'Veglia delle Anime Senza Nome',
      if (elite) 'Anymareap',
    ]);
    final expected = [
      (
        name: 'Taglio dell’Ultimo Respiro',
        cost: 3,
        cooldown: 4,
        effectId: oculumSoulFighterCutEffect,
        value: '20',
        type: 'danno_percentuale',
      ),
      (
        name: 'Mano della Veglia',
        cost: 2,
        cooldown: 3,
        effectId: 'soul_fighter_guard',
        value: '12',
        type: 'scudo',
      ),
      (
        name: 'Marchio dei Senza Nome',
        cost: 2,
        cooldown: 3,
        effectId: 'soul_fighter_skull',
        value: '-3',
        type: 'difesa',
      ),
      if (elite)
        (
          name: 'Anymareap',
          cost: 4,
          cooldown: 4,
          effectId: oculumAnymareapEffect,
          value: '0',
          type: 'danno',
        ),
    ];
    final skills = arts.expand((art) => art.skills).toList();
    expect(
      skills.map((skill) => skill.nome),
      unorderedEquals(expected.map((value) => value.name)),
      reason: monster.id,
    );
    for (final art in arts) {
      expectNoOpen(art);
      expect(CharacterArt.fromJson(art.toJson()).toJson(), art.toJson());
    }
    for (final value in expected) {
      final skill = ArtSkill.fromJson(
        skills.singleWhere((skill) => skill.nome == value.name).toJson(),
      );
      expect(skill.risorsaCostoPerLivello(1), 'oculum');
      expect(skill.oculumMinimoPerLivello(1), value.cost);
      expect(skill.oculumMassimoPerLivello(1), value.cost);
      expect(skill.cooldownPerLivello.first.amount, value.cooldown);
      final effect = skill.effettiEvoluzione(1).single;
      expect(effect.id, value.effectId);
      expect(effect.type, value.type);
      expect(effect.valueExpression, value.value);
    }
    return;
  }
  expect(monster.id, 'durafur', reason: 'Unknown authored no-Open kit');
  expect(monster.skillIds, ['durafur_fur_fury']);
  final restored = CharacterArt.fromJson(primary.toJson());
  expect(restored.toJson(), primary.toJson());
  expect(restored.skills, hasLength(1));
  final skill = restored.skills.single;
  expect(skill.nome, 'Furia del Pelo Ferrigno');
  for (var index = 0; index < 3; index++) {
    final form = index + 1;
    expect(skill.risorsaCostoPerLivello(form), 'nessuna');
    expect(skill.oculumMinimoPerLivello(form), 0);
    expect(skill.oculumMassimoPerLivello(form), 0);
    expect(skill.cooldownPerLivello[index].amount, 5);
    expect(skill.cooldownPerLivello[index].toJson()['initialRemaining'], 2);
    final effect = skill.effettiEvoluzione(form).single;
    expect(effect.type, 'modifica_statistica');
    expect(effect.target, 'danni');
    expect(effect.valueExpression, ['30', '40', '60'][index]);
    expect(effect.mode, 'temporaneo');
    expect(effect.duration, '3');
  }
}

void _expectAuthoredLineageUltimates(
  MonsterBookEntry monster,
  CharacterArt art,
) {
  final baseId = monster.id.split('_variante_').first;
  expect({oculumResiliumId, oculumMaterialId}, contains(baseId));
  final expected = baseId == oculumResiliumId
      ? const [
          (
            id: 'resilium_battito_rinnovato',
            name: 'Battito Rinnovato',
            level: 3,
            type: 'cura',
            target: '',
            cooldown: 5,
            values: ['3+livello', '5+livello', '7+livello'],
            mode: 'finche_attivo',
            duration: '1',
          ),
          (
            id: 'resilium_baluardo_vivente',
            name: 'Baluardo Vivente',
            level: 9,
            type: 'scudo',
            target: '',
            cooldown: 6,
            values: ['20+livello*2', '30+livello*2', '40+livello*2'],
            mode: 'finche_attivo',
            duration: '1',
          ),
          (
            id: 'resilium_rinascita_verde',
            name: 'Rinascita Verde',
            level: 15,
            type: 'cura',
            target: '',
            cooldown: 7,
            values: ['10+livello', '15+livello', '20+livello'],
            mode: 'rigenerazione',
            duration: '3',
          ),
        ]
      : const [
          (
            id: 'material_passo_inesistente',
            name: 'Passo Inesistente',
            level: 3,
            type: 'modifica_sottotratto',
            target: 'riflessi',
            cooldown: 5,
            values: ['2+livello/3', '3+livello/3', '4+livello/3'],
            mode: 'finche_attivo',
            duration: '1',
          ),
          (
            id: 'material_eclissi_azzurra',
            name: 'Eclissi Azzurra',
            level: 9,
            type: 'stato',
            target: 'invisibile',
            cooldown: 6,
            values: ['1', '1', '1'],
            mode: 'finche_attivo',
            duration: '2',
          ),
          (
            id: 'material_assenza_profonda',
            name: 'Assenza Profonda',
            level: 15,
            type: 'stato',
            target: 'invisibile',
            cooldown: 7,
            values: ['1', '1', '1'],
            mode: 'finche_attivo',
            duration: '3',
          ),
        ];
  final declaredIds = (monster.encounterRules['authoredUltimateIds'] as List)
      .cast<String>();
  expect(declaredIds, expected.map((value) => value.id), reason: monster.id);
  expect(declaredIds.toSet(), hasLength(3), reason: monster.id);
  expect(
    monster.skillIds.where(
      (id) => !id.startsWith(oculumMonsterProgressionPrefix),
    ),
    hasLength(9),
    reason: monster.id,
  );
  final pool = oculumMonsterBookOpenPool(monster);
  expect(pool, hasLength(3), reason: monster.id);
  expect(
    pool.map((open) => open.openName),
    expected.map((value) => value.name),
  );
  expect(art.openName, expected.first.name, reason: monster.id);
  expect(oculumMonsterBookWeakOpen(monster, art), isNull, reason: monster.id);
  for (var index = 0; index < expected.length; index++) {
    final value = expected[index];
    final technique = monsterBookConcreteTechnique(value.id)!;
    expect(technique.name, value.name);
    expect(technique.requiredLevel, value.level);
    expect(technique.costResource, 'oculum');
    expect(technique.minimums, [1, 2, 3]);
    expect(technique.maximums, [1, 2, 3]);
    expect(technique.cooldowns, [
      value.cooldown,
      value.cooldown + 1,
      value.cooldown + 2,
    ]);
    expect(technique.forms.map((form) => form.single.formula), value.values);
    final open = CharacterArt.fromJson(pool[index].toJson());
    expect(open.openName, value.name);
    expect(open.openDescription, contains('Richiede livello ${value.level}.'));
    expect(open.openBuff, isEmpty);
    expect(open.openBuffEffects, isEmpty);
    expect(open.openSkill, contains(technique.action));
    expect(open.openSkill, contains('Costo: 1/1 Oculum.'));
    expect(open.openSkillType, value.type);
    expect(open.openSkillCooldown?.amount, value.cooldown);
    final marker = open.openDescriptionEffects.single;
    expect(marker.id, 'monster_open_ultimate_${value.id}');
    expect(marker.type, 'modifica_statistica');
    expect(marker.target, 'monster_open_marker');
    expect(marker.valueExpression, '0');
    expect(marker.mode, 'finche_attivo');
    final effect = open.openSkillEffects.single;
    expect(oculumStructuredEffectTypes, contains(effect.type));
    expect(effect.type, value.type);
    expect(effect.target, value.target);
    expect(effect.valueExpression, value.values.first);
    expect(effect.mode, value.mode);
    expect(effect.duration, value.duration);
    expect(effect.recipient, 'se_stesso');
    expect(
      open.openSkillEffects.any(
        (effect) => effect.target == 'monster_open_power',
      ),
      isFalse,
    );
    expect(
      open.openSkillCooldown?.toJson(),
      pool[index].openSkillCooldown?.toJson(),
    );
  }
  // The first authored Ultimate is the weak, level-3 option that scales with
  // level. Vital Memory is a separate Resilium passive, not a damage Open buff.
  expect(expected.first.level, 3);
  expect(
    expected.first.values.every((formula) => formula.contains('livello')),
    isTrue,
  );
}

void main() {
  test(
    'every fixed progression kit has an explicit authored Open contract',
    () {
      final seen = <String>{};
      for (final monster in defaultMonsterBookEntries.where(
        oculumMonsterHasFixedProgressionSkills,
      )) {
        final baseId = monster.id.split('_variante_').first;
        if (_fixedNoOpenTechniqueKits.containsKey(baseId) ||
            const {'soul_fighter', 'durafur'}.contains(baseId)) {
          seen.add(baseId);
          continue;
        }
        expect(
          monster.formTags.contains('Creatura Minore') &&
              monster.skillIds.isEmpty,
          isTrue,
          reason: 'Unreviewed fixed kit: ${monster.id}',
        );
      }
      expect(seen, containsAll(_fixedNoOpenTechniqueKits.keys));
    },
  );

  test(
    'monster catalogue Open buffs connect to ultimate and preserve cooldowns',
    () {
      for (final monster in defaultMonsterBookEntries.where(
        (m) => !m.isNpc && !m.id.startsWith('pawn_guardiano'),
      )) {
        final art = oculumMonsterBookArt(monster);
        final baseId = monster.id.split('_variante_').first;
        if (oculumIsSoulFighter(monster.id) || monster.id == 'durafur') {
          _expectNoOpenAuthoredKit(monster, art);
          continue;
        }
        if (const {oculumResiliumId, oculumMaterialId}.contains(baseId)) {
          _expectAuthoredLineageUltimates(monster, art);
          continue;
        }
        final fixedKit = _fixedNoOpenTechniqueKits[baseId];
        if (fixedKit != null) {
          _expectFixedNoOpenTechniqueKit(monster, art, fixedKit);
          continue;
        }
        if (const {
          'koboldo_delle_braci',
          'fuoco_fatuo_affamato',
          'strige_del_fienile',
          'larva_del_grimorio',
        }.contains(baseId)) {
          expect(art.openName, isEmpty, reason: monster.id);
          expect(
            oculumMonsterBookImportArt(monster),
            isNull,
            reason: monster.id,
          );
          continue;
        }
        if (monster.id.contains('meccanio') || monster.id.contains('larva')) {
          continue;
        }
        expect(art.openName, isNotEmpty, reason: monster.id);
        expect(
          art.openBuffEffects.isNotEmpty || art.openBuff.trim().isNotEmpty,
          true,
          reason: monster.id,
        );
        expect(art.openSkill, isNotEmpty, reason: monster.id);
        expect(
          art.openSkillCooldown?.amount ?? 0,
          greaterThan(0),
          reason: monster.id,
        );
        final restored = CharacterArt.fromJson(art.toJson());
        expect(
          restored.openSkillCooldown?.amount,
          art.openSkillCooldown?.amount,
          reason: monster.id,
        );
        expect(restored.openBuff, art.openBuff, reason: monster.id);
        final gold = oculumGuardianGoldArt(restored);
        final lunar = oculumLunarGuardianArt(restored);
        if (gold || lunar) {
          // These authored Opens use parsed, editable Buff commands and their
          // own mechanics, rather than the generic monster_open_power effect.
          final commands = oculumParseFormulaCommands(restored.openBuff, const {
            'livello': 8,
            'grado': 1,
          }).where((command) => command.valid);
          expect(
            commands.singleWhere((c) => c.key == 'danni').value,
            gold ? 15 : 20,
            reason: monster.id,
          );
          expect(
            commands.singleWhere((c) => c.key == 'difesa').value,
            gold ? 10 : 15,
            reason: monster.id,
          );
          expect(
            restored.openDescriptionEffects.any(
              (e) =>
                  e.target ==
                  (gold ? 'guardian_gold_open' : 'lunar_guardian_stones'),
            ),
            true,
            reason: monster.id,
          );
          expect(
            restored.openSkillEffects.any(
              (e) =>
                  e.target ==
                  (gold ? 'guardian_gold_wall' : 'lunar_guardian_shadow_crest'),
            ),
            true,
            reason: monster.id,
          );
        } else if (monster.id == 'nuvola_in_bottiglia') {
          // The authored cloud Open grants a fast reaction, not the generic
          // monster damage buff. Its own Open alone empowers the Stop skill.
          expect(oculumBottledCloudArt(restored), isTrue);
          final open = restored.openDescriptionEffects.singleWhere(
            (effect) => effect.target == 'bottled_cloud_open',
          );
          expect(open.diceExpression, '2d50');
          expect(open.valueExpression, 'danni+25');
          expect(open.maximumTargets, 12);
          expect(open.resource, '15');
          final buff = restored.openBuffEffects.singleWhere(
            (effect) => effect.target == 'bottled_cloud_fast_reaction',
          );
          expect(buff.valueExpression, '1');
          expect(buff.mode, 'finche_attivo');
          expect(
            restored.openBuffEffects.any(
              (effect) => effect.target == 'monster_open_power',
            ),
            isFalse,
          );
          final stop = restored.openSkillEffects.singleWhere(
            (effect) => effect.target == 'bottled_cloud_stop',
          );
          expect(stop.valueExpression, '25');
          expect(stop.resource, '20');
          expect(
            oculumBottledCloudEffectData(stop.narrativeText),
            containsPair('empoweredChancePercent', 60),
          );
          expect(
            oculumBottledCloudEffectData(stop.narrativeText),
            containsPair('empoweredDamagePercent', 50),
          );
          expect(restored.openSkillCooldown?.amount, 3);
        } else {
          expect(
            restored.openBuffEffects.any(
              (e) => e.target == 'monster_open_power',
            ),
            true,
            reason: monster.id,
          );
        }
      }
    },
  );
}
