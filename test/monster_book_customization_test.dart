import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/main.dart' show oculumStarterRaces;

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

  test('default monsters are visual descriptions without imposed images', () {
    for (final entry in defaultMonsterBookEntries) {
      expect(entry.spriteAssetPath, isEmpty, reason: entry.id);
      expect(entry.imageBase64, isEmpty, reason: entry.id);
      expect(entry.descIt.trim(), isNotEmpty, reason: entry.id);
    }
    expect(monsterById('papera_ranocchio')?.imageBase64, isEmpty);
  });

  test('monster Art requirements scale with the creature power', () {
    final weak = monsterById('topo_con_mani')!;
    final strong = monsterById('demone_maggiore')!;
    expect(monsterBookSkillRequiredLevel(weak, 0), greaterThanOrEqualTo(0));
    expect(
      monsterBookSkillRequiredLevel(strong, 2),
      greaterThan(monsterBookSkillRequiredLevel(weak, 2)),
    );
    expect(strong.descIt, contains('Livello richiesto'));
  });

  test('Hideniano remains available in tutorial races', () {
    final hideniano = oculumStarterRaces.firstWhere(
      (race) => race.id == 'hideniano',
    );
    expect(hideniano.descrizione, contains('+2 Difesa Fuoco'));
    expect(hideniano.puntoCieco, contains('x2 danni'));
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
    final lesserDemon = monsterById('demone_minore');
    final intermediateDemon = monsterById('demone_intermedio');
    final greaterDemon = monsterById('demone_maggiore');
    expect(lesserDemon?.presetType, 'Mostro Mini Boss');
    expect(lesserDemon?.stats['level'], 0);
    expect(lesserDemon?.stats['defense'], 120);
    expect(intermediateDemon?.presetType, 'Mostro Boss');
    expect(intermediateDemon?.stats['defense'], 200);
    expect(greaterDemon?.presetType, 'Mostro Boss');
    expect(greaterDemon?.stats['resilienza'], 10);
    expect(greaterDemon?.stats['shield'], 120);
    expect(greaterDemon?.stats['defense'], 300);
    expect(monsterById('scheletro_bombarolo')?.stats['resilienza'], 1);
    expect(monsterById('scheletro_bombarolo')?.stats['volonta'], 5);
    expect(monsterById('osservatore_bianco')?.presetType, 'Mostro Mini Boss');
    expect(monsterById('osservatore_bianco')?.stats['oculum'], 30);
    expect(monsterById('immortale')?.stats['resilienza'], 20);
    expect(monsterBookSkillText('immortal_life_harvest'), contains('Vita'));
    expect(monsterById('angelo_fustigatore')?.stats['criticalShield'], 1);
    expect(monsterById('angelo_fustigatore')?.stats['resilienza'], 10);
    expect(monsterById('angelo_protettore')?.stats['materia'], 40);
    expect(monsterById('serafino')?.presetType, 'Mostro Boss');
    expect(monsterById('serafino')?.stats['oculum'], 30);
    expect(monsterById('arcangelo')?.presetType, 'Mostro Boss');
    expect(monsterById('pinepine')?.stats['resistancePercent'], 50);
    expect(monsterById('goblin_killer')?.stats['materia'], 10);
    expect(monsterById('demone_glaciale_intermedio')?.stats['oculum'], 13);
    expect(monsterById('demone_glaciale_maggiore')?.stats['materia'], 50);
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
    final putridSpider = monsterById('ragno_putrido');
    expect(putridSpider?.presetType, 'Mostro Mini Boss');
    expect(putridSpider?.stats, {
      'level': 0,
      'resilienza': 10,
      'volonta': 10,
      'materia': 0,
      'oculum': 10,
    });
    expect(putridSpider?.skillIds, contains('rot_poison_escalation'));
    final assassinSnail = monsterById('lumaca_assassina');
    expect(assassinSnail?.stats['level'], 1);
    expect(assassinSnail?.skillIds, contains('assassin_snail_memory'));
    expect(
      monsterBookSkillText('assassin_snail_slime'),
      contains('Senza Reazioni'),
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

  test('every base monster has a stable combat variant', () {
    final bases = defaultMonsterBookEntries
        .where((entry) => !entry.id.contains('_variante_'))
        .toList(growable: false);
    for (final base in bases) {
      expect(
        monsterById('${base.id}_variante_errante') ??
            monsterById('${base.id}_variante_corazzata') ??
            monsterById('${base.id}_variante_rituale') ??
            monsterById('${base.id}_variante_veterana'),
        isNotNull,
        reason: base.id,
      );
    }
  });

  test('Papero Ranocchio groups its base form and selectable variants', () {
    const baseId = 'papera_ranocchio';
    final forms = monsterBookEntries
        .where(
          (entry) =>
              entry.id == baseId || entry.id.startsWith('${baseId}_variante_'),
        )
        .toList(growable: false);

    expect(forms.first.id, baseId);
    expect(forms.length, greaterThan(1));
    expect(
      forms
          .skip(1)
          .every((entry) => entry.id.startsWith('${baseId}_variante_')),
      isTrue,
    );
  });

  test('starter smalllings stay weak and intentionally have no Art', () {
    for (final id in const <String>[
      'mostricciattolo_di_carta',
      'mostricciattolo_di_sugo',
      'mostricciattolo_del_tubo',
      'mostricciattolo_con_un_dente',
      'mostricciattolo_di_lana',
    ]) {
      final entry = monsterById(id)!;
      expect(entry.stats['hp'], inInclusiveRange(5, 10), reason: id);
      expect(entry.stats['atk'], inInclusiveRange(4, 6), reason: id);
      expect(entry.stats['def'], inInclusiveRange(3, 4), reason: id);
      expect(entry.skillIds, isEmpty, reason: id);
    }
  });

  test('armed humanoids retain their real inventory through the Book', () {
    final hammerMan = monsterById('uomo_del_martello_lungo');
    final commander = monsterById('armaiolo_della_fila_lunga');
    expect(hammerMan?.stats['level'], 100);
    expect(
      hammerMan?.inventoryItems.firstWhere(
        (item) => item['nome'] == 'Martello Lungo',
      )['bonusDanno'],
      90,
    );
    expect(commander?.isBoss, isTrue);
    expect(
      commander?.inventoryItems
          .map((item) => item['nome'])
          .contains('Guanti d arme enormi'),
      isTrue,
    );
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

  test(
    'Putrid Spider escalates the shared Rot Poison condition to rank IX',
    () {
      expect(
        monsterBookSkillText('rot_poison_escalation'),
        contains('Veleno Putrido IX'),
      );
      expect(
        monsterBookSkillText('rot_poison_escalation'),
        contains('ignora Scudo e Difesa'),
      );
    },
  );

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
