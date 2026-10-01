import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  int bonus(String id, int level) => oculumHiddenEyeDerivedBonusFor(
    id: id,
    level: level,
    resilienza: 20,
    volonta: 31,
    materia: 40,
    oculum: 50,
    karma: -3,
  );

  test('Livello si aggiunge una volta a ogni gruppo, anche homebrew', () {
    for (final id in [
      'forza',
      'schianto',
      'velo',
      'medicina',
      'percezione',
      'nodo',
      'investigazione',
      'manifestazione_potere',
      'custom_azione',
    ]) {
      expect(bonus(id, 50) - bonus(id, 0), 50, reason: id);
      expect(bonus(id, -5), bonus(id, 0));
    }
    expect(bonus('fortuna', 50), bonus('fortuna', 0));
    expect(bonus('schianto', 50), 65);
    expect(oculumHiddenEyeStaticGroupFor('schianto'), 'volonta');
  });

  test('Migrazione aggiunge Schianto conservando base e maestria', () {
    final original = HiddenEyeStat(
      id: 'forza',
      nome: 'Forza',
      descrizione: 'Nota personale',
      valore: 3,
      masteryProgress: 17,
    );
    final merged = oculumMergeHiddenEyeStatsWithDefaults(
      existing: [HiddenEyeStat.fromJson(original.toJson())],
      defaults: [
        HiddenEyeStat(id: 'forza', nome: 'Forza', descrizione: 'Default'),
        HiddenEyeStat(
          id: 'schianto',
          nome: 'Schianto',
          descrizione: 'Volonta/2',
        ),
      ],
    );
    expect(merged.first.valore, 3);
    expect(merged.first.masteryProgress, 17);
    expect(merged.first.descrizione, 'Nota personale');
    expect(merged.last.id, 'schianto');
    expect(merged.last.valore, 0);
    expect(
      oculumMergeHiddenEyeStatsWithDefaults(
        existing: merged,
        defaults: merged,
      ).length,
      2,
    );
  });
}
