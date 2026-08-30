import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  tearDown(resetMonsterBookEntries);

  test('Monster Book custom entry keeps names, image, category and drops', () {
    const entry = MonsterBookEntry(
      id: 'custom_keeper',
      nameIt: 'Custode Personalizzato',
      nameEn: 'Custom Keeper',
      descIt: 'Descrizione modificabile.',
      descEn: 'Editable description.',
      elementId: 'ombra',
      spriteAssetPath: 'assets/custom.png',
      imageBase64: 'aW1hZ2U=',
      isMiniBoss: false,
      isBoss: false,
      isNpc: true,
      isNullFateless: false,
      dropIds: ['chiave_ombra', 'occhio_vetro'],
    );

    final restored = MonsterBookEntry.fromJson(entry.toJson());

    expect(restored.nameIt, entry.nameIt);
    expect(restored.imageBase64, entry.imageBase64);
    expect(restored.presetType, 'NPC');
    expect(restored.dropIds, entry.dropIds);
  });

  test('Monster Book overrides built-ins and hides removed presets', () {
    final original = defaultMonsterBookEntries.first;
    final renamed = original.copyWith(nameIt: 'Nome Rispettato');

    configureMonsterBookEntries(
      customEntries: [renamed],
      removedIds: [defaultMonsterBookEntries[1].id],
    );

    expect(monsterById(original.id)?.nameIt, 'Nome Rispettato');
    expect(monsterById(defaultMonsterBookEntries[1].id), isNull);
  });

  test('manual monsters are present and generated creatures vary by role', () {
    expect(monsterById('fate_golem')?.skillIds, contains('fate_fairy_awaken'));
    expect(
      monsterById('patalpa_dolce')?.dropIds,
      contains('pala_patalpa_dolce'),
    );
    expect(
      monsterById('psycho_funginius')?.skillIds,
      contains('mix_illusioni'),
    );
    expect(monsterById('paffer_axolotl')?.nameIt, contains('Paffer'));
    expect(
      monsterById('baby_forest_demon')?.skillIds,
      contains('immaterial_dash_i'),
    );
    expect(
      monsterById('mistificatore_runico_natura')?.skillIds,
      contains('riproduzione_animalesca'),
    );

    final generated = defaultMonsterBookEntries
        .where((entry) => entry.id.startsWith('generated_normal_'))
        .take(2)
        .toList();
    expect(generated, hasLength(2));
    expect(generated.first.skillIds, isNot(generated.last.skillIds));
  });

  test('default roster keeps unique ids after manual additions', () {
    final ids = defaultMonsterBookEntries.map((entry) => entry.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  test(
    'legacy creatures receive distinct scene roles without changing ids',
    () {
      final rhino = monsterById('rock_rhino');
      final slime = monsterById('slime_blu');
      expect(rhino?.descIt, contains('Ruolo in scena:'));
      expect(slime?.descIt, contains('Ruolo in scena:'));
      expect(rhino?.descIt, isNot(slime?.descIt));
    },
  );

  test('Monster Book skill text speaks directly to the player', () {
    expect(
      monsterBookSkillText('fire_charge'),
      startsWith('fire charge — I/carichi'),
    );
    expect(monsterBookSkillText('poison_tongue'), contains('I/colpisci'));
    expect(
      monsterById('rock_rhino')?.descIt,
      contains('Skill per il giocatore:'),
    );
  });

  test('Ushrin techniques explain their distinct effects and consequences', () {
    final ushrin = monsterById('ushrin');

    expect(
      ushrin?.descIt,
      contains(
        'Ruolo in scena: opportunista: alterna pressione e difesa, cercando di non ripetere la stessa azione due turni di fila.',
      ),
    );
    expect(
      ushrin?.descIt,
      contains('solar swarm — I/dirigi un piccolo sciame'),
    );
    expect(ushrin?.descIt, contains('golden pin — I/lanci una spina'));
    expect(ushrin?.descIt, contains('wing flash — I/apri le ali dorate'));
    expect(monsterBookSkillText('solar_swarm'), contains('resta esposto'));
    expect(monsterBookSkillText('golden_pin'), contains('può essere spezzata'));
    expect(
      monsterBookSkillText('wing_flash'),
      contains('rivela con chiarezza la tua posizione'),
    );
    expect(ushrin?.dropIds, ['sun_pin', 'black_gold_chip']);
  });

  test('every default monster has a scene role and explained techniques', () {
    for (final monster in defaultMonsterBookEntries) {
      expect(monster.descIt, contains('Ruolo in scena:'), reason: monster.id);
      for (final skillId in monster.skillIds) {
        final text = monsterBookSkillText(skillId);
        expect(text, contains('I/'), reason: '$skillId I');
        expect(text, contains('II/'), reason: '$skillId II');
        expect(text, contains('III/'), reason: '$skillId III');
        expect(text, isNot(contains('usi la tecnica contro')), reason: skillId);
      }
    }
  });
}
