import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

const _forms = <String, (String, String)>{
  'ciclo_cinghiale_fango_variante_chikar': (
    'ciclo_cinghiale_fango',
    'cycle_chikar_furrow',
  ),
  'ciclo_uomo_cactus_variante_aberion_blu': (
    'ciclo_uomo_cactus',
    'cycle_aberion_blue_thorns',
  ),
  'ciclo_uomo_cactus_variante_aberion': (
    'ciclo_uomo_cactus',
    'cycle_aberion_grasping_roots',
  ),
  'ciclo_airone_guado_quieto_variante_colorato': (
    'ciclo_airone_guado_quieto',
    'cycle_colored_heron_fan',
  ),
  'ciclo_airone_guado_quieto_variante_lunare': (
    'ciclo_airone_guado_quieto',
    'cycle_lunar_heron_shelter',
  ),
  'ciclo_tartaruga_pioggia_chiara_variante_solida': (
    'ciclo_tartaruga_pioggia_chiara',
    'cycle_solid_turtle_guard',
  ),
  'ciclo_tartaruga_pioggia_chiara_variante_incantatrice': (
    'ciclo_tartaruga_pioggia_chiara',
    'cycle_water_turtle_weave',
  ),
};

MonsterBookEntry _catalogue(String id) =>
    defaultMonsterBookEntries.singleWhere((entry) => entry.id == id);

void main() {
  test(
    'seven authored forms join the active catalogue and preserve the original roster',
    () {
      expect(
        oculumCycleArtVariantEntries.map((entry) => entry.id),
        unorderedEquals(_forms.keys),
      );
      expect(oculumCycleMonsterEntries.length, 35);
      for (final selection in _forms.entries) {
        final base = oculumSavedMonsterBookEntryById(selection.value.$1)!;
        final entry = _catalogue(selection.key);
        expect(
          oculumSavedMonsterBookEntryById(selection.key)?.id,
          selection.key,
        );
        expect(entry.encounterRules['canonicalVariantOf'], base.id);
        expect(entry.encounterRules['signatureSkillId'], selection.value.$2);
        expect(oculumMonsterCyclePhase(entry), oculumMonsterCyclePhase(base));
        expect(entry.dropIds, base.dropIds);
        expect(
          entry.skillIds.every((id) => oculumPlanarTechnique(id) != null),
          isTrue,
        );
        expect(entry.spriteAssetPath, isEmpty);
        expect(
          MonsterBookEntry.fromJson(entry.toJson()).skillIds,
          entry.skillIds,
        );
        expect(base.skillIds, isNot(contains(selection.value.$2)));
      }
    },
  );

  test(
    'signature moves become editable sheets with all three forms and costs',
    () {
      for (final selection in _forms.entries) {
        final entry = _catalogue(selection.key);
        final signature = selection.value.$2;
        final technique = oculumPlanarTechnique(signature)!;
        final art = oculumMonsterBookArt(entry);
        expect(art.skills, hasLength(entry.skillIds.length));
        final index = entry.skillIds.indexOf(signature);
        final skill = art.skills[index];
        for (var form = 1; form <= 3; form++) {
          expect(skill.effettiEvoluzione(form), isNotEmpty);
          expect(skill.risorsaCostoPerLivello(form), technique.costResource);
          expect(skill.oculumMinimoPerLivello(form), form);
          expect(skill.cooldownPerLivello[form - 1].amount, greaterThan(0));
        }
        skill.impostaLimitiOculumPerLivello(1, minimo: 7, massimo: 7);
        expect(
          CharacterArt.fromJson(
            art.toJson(),
          ).skills[index].oculumMinimoPerLivello(1),
          7,
        );
        expect(
          oculumMonsterBookArt(entry).skills[index].oculumMinimoPerLivello(1),
          1,
        );
      }
    },
  );

  test(
    'stronger Chikar, blue Aberion and solid turtle keep the selected roles',
    () {
      final chikar = _catalogue('ciclo_cinghiale_fango_variante_chikar');
      expect(
        chikar.stats['resilienza'],
        greaterThan(_catalogue('ciclo_cinghiale_fango').stats['resilienza']!),
      );
      expect(
        chikar.skillIds
            .map((id) => oculumPlanarTechnique(id)!.element)
            .join('/'),
        'fango/terra/roccia',
      );
      final cactus = _catalogue('ciclo_uomo_cactus');
      final blue = _catalogue('ciclo_uomo_cactus_variante_aberion_blu');
      expect(blue.stats['materia'], greaterThan(cactus.stats['materia']!));
      expect(
        oculumPlanarTechnique(blue.skillIds.first)!.forms.first.first.formula,
        '8',
      );
      expect(
        oculumPlanarTechnique(cactus.skillIds.first)!.forms.first.first.formula,
        '6',
      );
      final solid = _catalogue(
        'ciclo_tartaruga_pioggia_chiara_variante_solida',
      );
      expect(
        solid.stats['resilienza'],
        greaterThan(
          _catalogue('ciclo_tartaruga_pioggia_chiara').stats['resilienza']!,
        ),
      );
      expect(
        oculumPlanarTechnique(
          solid.skillIds.first,
        )!.forms.first.map((effect) => effect.type),
        ['scudo', 'difesa'],
      );
    },
  );

  test(
    'Aberion separates its Materia roots from Oculum, water and wing support target allies',
    () {
      final aberion = _catalogue('ciclo_uomo_cactus_variante_aberion');
      final inheritedStrike = oculumPlanarTechnique(aberion.skillIds.first)!;
      final roots = oculumPlanarTechnique('cycle_aberion_grasping_roots')!;
      expect(inheritedStrike.costResource, 'oculum');
      expect(roots.costResource, 'materia');
      expect(roots.forms.first.single.recipient, 'nemico');
      expect(roots.forms.first.single.target, 'movimento');
      expect(roots.forms.first.single.formula, '2');
      expect(roots.forms.first.single.mode, 'diminuzione');
      final water = oculumPlanarTechnique('cycle_water_turtle_weave')!;
      expect(water.element, 'acqua');
      expect(
        water.forms.first.map((effect) => (effect.type, effect.recipient)),
        [('cura', 'alleato'), ('scudo', 'alleato')],
      );
      final wing = oculumPlanarTechnique('cycle_lunar_heron_shelter')!;
      expect(wing.element, 'lunare');
      expect(wing.forms.first.single.recipient, 'alleato');
    },
  );
}
