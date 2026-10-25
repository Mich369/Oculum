import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
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
