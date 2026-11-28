import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

const carved = 'armadillo_corazzato_variante_placche_scolpite';
const broad = 'armadillo_corazzato_variante_scaglie_larghe';
const trapezoid = 'costrutto_minore_variante_trapezoidale';
const quick = 'costrutto_minore_variante_rapido';
const amethyst = 'mosca_campana_variante_oculum_ametista';
const greaterLarva = 'weak_horror_larva_variante_potenziata';
const venomLarva = 'weak_horror_larva_variante_velenosa';

MonsterBookEntry byId(String id) =>
    defaultMonsterBookEntries.singleWhere((entry) => entry.id == id);

Iterable<OculumStructuredEffect> formOne(MonsterBookEntry entry, String id) {
  final loadout = oculumMonsterBookLoadout(
    entry,
    random: Random(19),
    level: entry.stats['level'],
  );
  return [
    for (final skill in loadout.skills) ...skill.forme.first.effettiStrutturati,
    for (final skill in loadout.art?.skills ?? const <ArtSkill>[])
      ...skill.effettiEvoluzione(1),
  ].where((effect) => effect.id.startsWith(id));
}

void main() {
  test(
    'seven distinct entries keep the old species, drops and native loadouts',
    () {
      const expected = {
        carved: ('armadillo_corazzato', 'ink_armadillo_carved_guard'),
        broad: ('armadillo_corazzato', 'ink_armadillo_broad_impact'),
        trapezoid: ('costrutto_minore', 'ink_construct_trapezoid_brace'),
        quick: ('costrutto_minore', 'ink_construct_quick_springs'),
        amethyst: ('mosca_campana', 'ink_bell_amethyst_ray'),
        greaterLarva: ('weak_horror_larva', 'ink_larva_amber_twist'),
        venomLarva: ('weak_horror_larva', 'ink_larva_venom_filaments'),
      };
      for (final pair in expected.entries) {
        final base = byId(pair.value.$1);
        final entry = byId(pair.key);
        expect(entry.encounterRules['canonicalVariantOf'], base.id);
        expect(entry.dropIds, base.dropIds);
        expect(entry.planeIds, base.planeIds);
        expect(base.skillIds, isNot(contains(pair.value.$2)));
        expect(formOne(entry, pair.value.$2), isNotEmpty, reason: pair.key);
      }
      for (final id in [carved, broad, greaterLarva]) {
        final entry = byId(id);
        final base = byId(entry.encounterRules['canonicalVariantOf'] as String);
        final total = [
          'resilienza',
          'volonta',
          'materia',
          'oculum',
        ].fold(0, (sum, key) => sum + entry.stats[key]!);
        final baseTotal = [
          'resilienza',
          'volonta',
          'materia',
          'oculum',
        ].fold(0, (sum, key) => sum + base.stats[key]!);
        expect(total, greaterThan(baseTotal));
      }
      expect(
        byId(quick).stats['materia'],
        greaterThan(byId('costrutto_minore').stats['materia']!),
      );
      expect(
        formOne(byId(amethyst), 'ink_bell_amethyst_ray').single.elementType,
        'oculum',
      );
      expect(
        formOne(byId(amethyst), 'ink_bell_amethyst_refraction').single.type,
        'difesa',
      );
      expect(byId(amethyst).skillIds, isNot(contains('bell_fate_paralysis')));
    },
  );

  testWidgets(
    'Costrutto variants use the real CM, Resistenza, box and movement rules',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      final index = state.schedaCorrente as int;
      void select(String id, int level, int matter) {
        state.schedePersonaggio[index]['monsterBookSourceId'] = id;
        state.livelloController.text = level.toString();
        state.gradoController.text = '0';
        state.resilienzaController.text = '10';
        state.currentResilienzaController.text = '10';
        state.materiaController.text = matter.toString();
        state.currentMateriaController.text = matter.toString();
        state.currentHpController.text = '1000';
        probe.invalidateDerivedCaches();
      }

      for (final (level, bonus) in [
        (0, 0),
        (11, 0),
        (12, 3),
        (23, 3),
        (24, 6),
        (48, 12),
      ]) {
        select('costrutto_minore', level, 6);
        final cm = probe.defenseCm();
        final resistance = probe.subtraitValue('resistenza');
        select(trapezoid, level, 6);
        expect(probe.defenseCm() - cm, 6, reason: 'CM');
        expect(probe.subtraitValue('resistenza') - resistance, bonus);
      }
      select('costrutto_minore', 1, 6);
      final baseHp = probe.maximumHp();
      final baseMovement = probe.movement();
      select(quick, 1, 8);
      expect(probe.maximumHp(), lessThan(baseHp));
      expect(probe.movement(), lessThan(baseMovement));
      final snapshot = probe.snapshot();
      expect(oculumSheetHpMaximum(snapshot), probe.maximumHp());
      expect(
        oculumMonsterBaseMovement(monsterId: quick, level: 1, materia: 8),
        lessThan(oculumBaseMovement(level: 1, materia: 6)),
      );
      final parts = oculumReferenceCreaturePrecisionParts(
        const [],
        monsterId: quick,
        minorConstructCoreExposed: false,
      );
      expect(parts.map((part) => part['id']), contains('box'));
      expect(parts.map((part) => part['id']), isNot(contains('core')));
      final phase = formOne(byId(quick), 'ink_construct_quick_springs');
      expect(phase.single.target, 'reazione_veloce');
      final before = (probe.snapshot()['derivedReazioniVeloci'] as int?) ?? 0;
      probe.applyEffects(phase, spentResources: {'materia': 1});
      final fastEffects = (state.activeStructuredEffects as List).where(
        (e) => e['target'] == 'reazione_veloce',
      );
      expect(fastEffects.single['value'], 1);
      expect(probe.snapshot()['derivedReazioniVeloci'], before + 1);
      await closeFixture(tester, probe);
    },
  );

  testWidgets(
    'the paid poison technique queues canon; only a landed attack applies it once',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      final entry = byId(venomLarva);
      const skillId = 'ink_larva_venom_filaments';
      final technique = monsterBookConcreteTechnique(skillId)!;
      expect(technique.costResource, 'oculum');
      expect(technique.minimums, [1, 2, 3]);
      expect(technique.maximums, technique.minimums);
      final effects = formOne(entry, skillId);
      expect(effects.map((effect) => effect.type), ['danno', 'stato']);
      expect(effects.last.appliedState, 'avvelenato');

      state.oculumController.text = '4';
      state.currentOculumController.text = '4';
      state.livelloController.text = '3';
      state.gradoController.text = '0';
      state.resilienzaController.text = '30';
      state.currentResilienzaController.text = '30';
      state.currentHpController.text = '300';
      state.scudoController.text = '0';
      state.scudoOculumController.text = '0';
      probe.invalidateDerivedCaches();

      final paid = probe.spendArtResource(
        technique.costResource,
        technique.minimums.first,
      );
      expect(paid, 1);
      expect(state.currentOculumController.text, '3');
      probe.applyEffects(
        effects,
        spentResources: {technique.costResource: paid},
      );
      final queued = (state.activeStructuredEffects as List)
          .where((entry) => entry['type'] == 'pending_target')
          .map((entry) => entry['effect'] as Map)
          .toList();
      expect(queued.single['appliedState'], 'avvelenato');
      expect(probe.conditions, isEmpty, reason: 'Poison is for the opponent.');

      Map<String, dynamic> request(String id) => {
        'id': id,
        'status': 'pending',
        'sourceTag': 'ENEMY',
        'sourceName': entry.nameIt,
        'targetTag': probe.ownerTag(),
        'scope': probe.permissionScope,
        'encounterId': 'encounter_1',
        'choice': 'attacco',
        'natural': 10,
        'dieFaces': 20,
        'attack': 200,
        'damage': probe.defense() + 40,
        'element': 'veleno',
        'level': 1,
        'grade': 0,
        'effects': queued,
      };
      final avoided = request('avoided-venom');
      state.onlineCombatRequests[avoided['id']] = avoided;
      await probe.resolveCombatDefense(avoided, 'cm', 250, natural: 10);
      expect(probe.conditions, isEmpty);
      final landed = request('landed-venom');
      state.onlineCombatRequests[landed['id']] = landed;
      await probe.resolveCombatDefense(landed, 'cm', 10, natural: 10);
      expect(probe.conditions.single.conditionType, 'avvelenato');
      final poison = probe.conditions.single.toJson();
      await probe.resolveCombatDefense(landed, 'cm', 10, natural: 10);
      expect(probe.conditions.single.toJson(), poison);
      await closeFixture(tester, probe);
    },
  );
}
