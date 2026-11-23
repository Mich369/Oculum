import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart' show oculumLookupMonsterId;
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

// Expectations from the complete gallery export, independent of the catalogue.
const _renames = <String, ({String name, String previous})>{
  'eiva_spugna_salmastra_variante_acqua': (
    name: 'Salyryn',
    previous: 'Salyfunnel',
  ),
  'forest_rune_golem_variante_veterana': (
    name: 'Runvisrith',
    previous: 'Visrune',
  ),
  'habitat_angelico_falena_del_canto_d_argento': (
    name: 'Argentriel',
    previous: 'Argentymoth',
  ),
  'habitat_diabolico_segugio_del_patto_di_ferro': (
    name: 'Ferhex',
    previous: 'Ferryl',
  ),
  'habitat_foresta_elementale_antico_dei_venti_elementi': (
    name: 'Cortexnys',
    previous: 'Cortexward',
  ),
  'habitat_foresta_elementale_ragno_della_linfa_acida_variante_errante': (
    name: 'Sapryn',
    previous: 'Sapstalk',
  ),
  'habitat_foresta_elementale_serpente_del_muschio_psichico': (
    name: 'Muscyreth',
    previous: 'Muscuspair',
  ),
  'habitat_ghiaccio_falena_della_neve_nera_variante_errante': (
    name: 'Nivyryn',
    previous: 'Nivymoth',
  ),
  'habitat_morti_segugio_del_camposanto': (
    name: 'Funeyryn',
    previous: 'Funehound',
  ),
  'habitat_nuvole_rocciose_masticatore_degli_archi_celesti_variante_errante': (
    name: 'Vagusreth',
    previous: 'Vagusclasp',
  ),
  'habitat_nuvole_rocciose_rospo_della_pioggia_obliqua_variante_corazzata': (
    name: 'Pluvyryx',
    previous: 'Imbryplate',
  ),
  'habitat_postea_ragno_saldatore': (
    name: 'Saldarith',
    previous: 'Ragno Saldatore',
  ),
  'habitat_postea_segugio_dei_circuiti_runici_variante_veterana': (
    name: 'Runhynrel',
    previous: 'Visrunhound',
  ),
  'habitat_sacro_giudice_dalle_sette_aureole': (
    name: 'Aurumreth',
    previous: 'Aurumjud',
  ),
  'habitat_sotterraneo_maggiore_talpa_del_diamante_nero': (
    name: 'Talpyryn',
    previous: 'Talpyshard',
  ),
  'habitat_sotterraneo_salamandra_della_ghiaia': (
    name: 'Glaryx',
    previous: 'Glarynewt',
  ),
  'habitat_vero_inferno_sovrano_della_fiamma_originaria_variante_rituale': (
    name: 'Primykrath',
    previous: 'Primyflare',
  ),
  'ice_shield': (name: 'Gelyrdryx', previous: 'Ice Shield'),
  'terrore_sotterranei_variante_rituale': (
    name: 'Rendryx',
    previous: 'Mirusrend',
  ),
  'uomo_maschera': (name: 'Material', previous: 'Uomo con la maschera'),
  'affogato_granchio_delle_cappelle_variante_roccia': (
    name: 'Sacrith',
    previous: 'Sacrycrab',
  ),
  'generated_normal_002_variante_errante': (
    name: 'Orcryx',
    previous: 'Orcryst',
  ),
  'pesce_mutato_variante_corazzata': (
    name: 'Squamyryx',
    previous: 'Squamyscute',
  ),
  'base_sotterraneo_06': (name: 'Turith', previous: 'Turrysilk'),
  'habitat_diabolico_segugio_del_patto_di_ferro_variante_errante': (
    name: 'Vagrym',
    previous: 'Vaghound',
  ),
  'habitat_ghiaccio_golem_del_ghiacciaio_cavo_variante_rituale': (
    name: 'Rimykrel',
    previous: 'Mirusrime',
  ),
  'habitat_morti_vedova_delle_ossa_cucite_variante_corazzata': (
    name: 'Sutyryn',
    previous: 'Sutywidow',
  ),
  'inspired_rospaccio_rosso_variante_corazzata': (
    name: 'Rubreth',
    previous: 'Rubrytoad',
  ),
  'lanterniere_osso_variante_errante': (
    name: 'Ossyrith',
    previous: 'Ossylight',
  ),
  'larva_del_grimorio_variante_corazzata': (
    name: 'Scrybreth',
    previous: 'Larvascrybus',
  ),
  'lightning_skull_variante_rituale': (
    name: 'Fulguryn',
    previous: 'Fulgurskull',
  ),
  'lumaca_assassina_variante_errante': (
    name: 'Clavyrel',
    previous: 'Clavytrail',
  ),
  'mammut_corazzato_variante_corazzata': (
    name: 'Mamfereth',
    previous: 'Mammuth di Ferro Runico',
  ),
  'santo_vuoto_piccolo_variante_corazzata': (
    name: 'Nyhlryx',
    previous: 'Nyhlward',
  ),
  'gigante_sabbia': (name: 'Arenmarith', previous: 'Gigante di sabbia'),
  'habitat_diabolico_scarabeo_dei_contratti_ardenti': (
    name: 'Pactykrath',
    previous: 'Pactycarapace',
  ),
  'habitat_morti_falena_del_sudario_variante_veterana': (
    name: 'Funewryn',
    previous: 'Funerwing',
  ),
  'mostricciattolo_di_carta_variante_rituale': (
    name: 'Foldyryx',
    previous: 'Mirusfold',
  ),
  'habitat_sotterraneo_regina_delle_miniere_mute_variante_rituale': (
    name: 'Tacyrel',
    previous: 'Tacyantel',
  ),
  'habitat_foresta_elementale_lince_di_brina_verde_variante_corazzata': (
    name: 'Vyridyriel',
    previous: 'Vyridfrost',
  ),
  'graga_rana_azzurra_variante_corazzata': (
    name: 'Gragaryx',
    previous: 'Gragaloryx',
  ),
  'ciclo_mantide_vampa': (name: 'Ignykrath', previous: 'Ignytis'),
  'habitat_caramella_medusa_di_confettura': (
    name: 'Dulmedryn',
    previous: 'Medusa di confettura',
  ),
  'affogato_vortice_delle_arcate': (
    name: 'Corallriel',
    previous: 'Corallwhirl',
  ),
  'eiva_serracapo_mosaici': (name: 'Malleyryn', previous: 'Malleysaw'),
  'affogato_predone_delle_nasse': (name: 'Falxyryn', previous: 'Falxfin'),
  'affogato_palmatore_dei_nastri': (name: 'Pynnaryth', previous: 'Pynnasway'),
  'affogato_faldavela': (name: 'Faldarith', previous: 'Faldavela'),
  'affogato_tessitore_della_corrente': (
    name: 'Undariel',
    previous: 'Undathread',
  ),
  'affogato_sentinella_di_basalto': (name: 'Luxryn', previous: 'Luxryf'),
  'piranha_mortale': (name: 'Dentyreth', previous: 'Dentysnap'),
  'affogato_custode_della_chiusa': (name: 'Constarith', previous: 'Constacuas'),
  'affogato_vedetta_dei_canali': (name: 'Pysciriel', previous: 'Pysciwarden'),
  'base_affogato_08': (name: 'Vitribryn', previous: 'Medusa del Vetro Blu'),
  'pesce_mutato': (name: 'Mutpycrith', previous: 'Pesce Mutato'),
  'ciclo_rospo_gronde_marce': (name: 'Imbrytrel', previous: 'Imbrytoad'),
  'ciclo_scarabeo_sigillo_ardente': (name: 'Sygilreth', previous: 'Sygilscyel'),
  'aberrazione_oro_marmo_superiore_angelica': (
    name: 'Auriosryx',
    previous: 'Aurybone',
  ),
  'armaiolo_della_fila_lunga_variante_rituale': (
    name: 'Forgyreth',
    previous: 'Mirusforge',
  ),
  'bambola_vapium_variante_veterana': (name: 'Vapryx', previous: 'Visvapyr'),
  'demone_glaciale_minore': (
    name: 'Gelydkrath',
    previous: 'Demone Glaciale Minore',
  ),
  'larva_del_vespro_variante_errante': (name: 'Umbryn', previous: 'Umbraskulk'),
  'lupo_infernale_del_ghiaccio': (name: 'Gelyfkrath', previous: 'Gelyfang'),
  'mammuth_in_decomposizione': (
    name: 'Putmymreth',
    previous: 'Mammuth in decomposizione',
  ),
  'marionettista_boss': (name: 'Necthryx', previous: 'Necthrall'),
  'scheletro_bombarolo': (name: 'Ossyflryx', previous: 'Ossyfling'),
  'cuore_lava_variante_corazzata': (name: 'Ignyshryn', previous: 'Ignyshell'),
  'habitat_foresta_elementale_ragno_della_linfa_acida': (
    name: 'Saparyx',
    previous: 'Ragno della linfa acida',
  ),
  'habitat_nuvole_rocciose_cinghiale_delle_creste_volanti_variante_errante': (
    name: 'Cloudryx',
    previous: 'Cloudtusk',
  ),
  'troll_base_variante_veterana': (name: 'Barkrith', previous: 'Visbark'),
  'habitat_demoniaco_regina_delle_gole_vulcaniche': (
    name: 'Alakrath',
    previous: 'Alaryft',
  ),
  'aberrazione_oro_marmo_intermedia_angelica': (
    name: 'Auryel',
    previous: 'Aberrazione d\'Oro',
  ),
  'aberrazione_oro_marmo_intermedia_solare': (
    name: 'Aurygrel',
    previous: 'Aurystride',
  ),
  'arpia_base_variante_veterana': (name: 'Ventycryth', previous: 'Ventyclaw'),
  'golem_runico_variante_veterana': (name: 'Cuprith', previous: 'Viscuprum'),
  'larva_lava_variante_corazzata': (
    name: 'Syntereth',
    previous: 'Syntermoltys',
  ),
  'arcangelo_variante_errante': (name: 'Vagariel', previous: 'Vagarwyngh'),
  'angelo_fustigatore_variante_rituale': (
    name: 'Lashyrel',
    previous: 'Miruslash',
  ),
  'agla_variante_corazzata': (name: 'Loryel', previous: 'Lorica Gleaner'),
  'ammasso_pustoloso': (name: 'Ossyblreth', previous: 'Ossyblayn'),
  'ammasso_carne_ossa_errante_variante_rituale': (
    name: 'Karnyreth',
    previous: 'Karnyrattle',
  ),
  'sciamano_malizioso': (name: 'Dolynys', previous: 'Dolyfern'),
  'ciclope_del_fato': (name: 'Fatorith', previous: 'Fatomhol'),
  'sensimoss': (name: 'Sensiriel', previous: 'Sensimoss'),
  'durafur': (name: 'Ferrypryx', previous: 'Ferryfur'),
  'lupo_delle_nevi': (name: 'Glaysryx', previous: 'Glayswuolf'),
  'custode_campana_cieca': (name: 'Vesanyrith', previous: 'Vesanybel'),
  'aculotide': (name: 'Aculoryx', previous: 'Aculotide'),
  'crostaceo_corazzato': (name: 'Karyax', previous: 'Karyklaw'),
  'fata_cacciatrice': (name: 'Ventybrel', previous: 'Ventybleyd'),
  'errante_della_resistenza': (name: 'Dyuraryn', previous: 'Dyurahyd'),
  'sposa_marea_nera': (name: 'Nuptariel', previous: 'Nuptayd'),
  'errante_della_forza': (name: 'Rubrymrith', previous: 'Rubrymhol'),
  'osycleiv': (name: 'Osyrith', previous: 'Osycleiv'),
  'larva_del_vespro': (name: 'Umbracryx', previous: 'Umbracryp'),
  'ferrugryp': (name: 'Ferrumryx', previous: 'Ferrumhol'),
  'cynervail': (name: 'Cyneryx', previous: 'Cynerveil'),
  'sonoreye': (name: 'Sonoryn', previous: 'Sonorays'),
  'corvo_della_morte_evoluto': (name: 'Lunaryn', previous: 'Lunavyr'),
  'lignobark': (name: 'Lignynys', previous: 'Lignoryt'),
  'oblyvuard': (name: 'Oblyvreth', previous: 'Oblyvuard'),
  'topo_mutante': (name: 'Ratyrith', previous: 'Ratygrinh'),
  'angelo_palpebra_sporca_variante_veterana': (
    name: 'Iudexrith',
    previous: 'Iudex Blight',
  ),
  'angelo_protettore_variante_corazzata': (
    name: 'Angloriel',
    previous: 'Angelo Protettore Corazzata',
  ),
  'araldo_raggio_angelico_variante_errante': (
    name: 'Azuryx',
    previous: 'Azurictus Bluecross',
  ),
  'base_affogato_01': (name: 'Palloryn', previous: 'Pallor Current'),
  'solgaze': (name: 'Solrel', previous: 'Solgheiz'),
  'solgaze_variante_muschiosa': (
    name: 'Solacurel',
    previous: 'Solgheiz del Santuario Allagato',
  ),
  'terramound': (name: 'Terrarith', previous: 'Terramaund'),
  'ciclope_del_tempo': (name: 'Chronyreth', previous: 'Il Ciclope del Tempo'),
  'osservatore_del_tempo': (
    name: 'Chronoreth',
    previous: 'Osservatore del Tempo',
  ),
  'bramble': (name: 'Bramriel', previous: 'Bramble'),
  'il_doppione': (name: 'Duploryn', previous: 'Il Doppione'),
  'mostro_sabbia': (name: 'Arenyryx', previous: 'Mostro di sabbia'),
  'nuvola_in_bottiglia': (name: 'Nubyvriel', previous: 'Nuvola in bottiglia'),
};
const _kept = <String, String>{
  'tappo_con_zampe': 'Tappo con Zampe',
  'strana_presenza': 'Strana Presenza',
  'balena_dai_mille_occhi': 'Balena Dai Mille Occhi',
  'sempre_verde': 'Sempre verde',
  'pawn_guardiano': 'Pawn',
  'pinepine': 'Pinepine',
  'snorlo': 'Snorlo',
  'meccanio_ammaccato_variante_errante': 'Vaghyuil',
  'air_navigator': 'Navigatore dell’Aria',
  'ombra_ignota': 'L’Ombra Ignota',
  'baby_rock_rhino_variante_intermedia': 'RockRhyno',
  'distruttor_caramella': 'Distruttor Caramella',
  'baby_rock_rhino_variante_veterana': 'Visrhyno',
  'divoramitu_elite': 'Divoramitù Elité',
  'baby_rock_rhino': 'Baby Rock Rhino',
  'divoramitu': 'Divoramitù',
  'armadillo_legno': 'Armadillo di Legno',
  'snorlo_variante_corazzata': 'Snorlo Corazzata',
  'grofix': 'Grofix',
  'armadillo_cristallo': 'Armadillo di Cristallo',
  'armadillo_sabbia': 'Armadillo della Sabbia',
  'bandito_base_variante_veterana': 'Bandita Veterana',
  'guardia_solare': 'Guardia Solare',
  'guardiano_solare': 'Guardiano Solare',
  'guardia_solare_elite': 'Guardia Solare élite',
  'bunnys_variante_veterana': 'Visbunnys',
  'acuagoblin_variante_curioso': 'Acuagoblin Curioso',
  'acuagoblin_variante_predatore': 'Acuagoblin Predatore',
  'bunnys': 'Bunnys',
  'sanguifang': 'Sanguifeng',
  'acuagoblin_variante_territoriale': 'Acuagoblin Territoriale',
  'soul_fighter_variante_elite': 'Combattente dell’Anima Elité',
  'oculiath_minore': 'Oculiath minore',
  'aberrazione_oro_marmo_maggiore_angelica': 'Angel Feather',
  'aberrazione_oro_marmo_maggiore_solare': 'Angel Feather Elité',
  'aberrazione_oro_marmo_minore_angelica': 'Aberrazione Minore Angelica',
  'aberrazione_oro_marmo_minore_solare': 'Aberrazione Minore Solare',
  'aberrazione_oro_marmo_superiore_solare': 'Aberrazione Superiore Sole',
  'arcangelo': 'Arcangelo',
  'armaiolo_della_fila_lunga': 'Armaiolo della spada e scudo',
  'frutibush': 'Frutibush',
  'goblin_king': 'Re Goblin',
  'oculiath': 'Oculiath',
  'oculiath_maggiore': 'Oculiath Maggiore',
  'soul_fighter': 'Combattente dell’Anima',
  'armadillo_corazzato': 'Armadillo Corazzato',
  'firerose': 'Firerose',
  'icerose': 'Icerose',
  'maledizione_chaos': 'Maledizione di Chaos',
  'maledizione_di_legno': 'Maledizione di Legno',
  'maledizione_maggiore': 'Maledizione Maggiore',
  'mezzo_demone_massiccio': 'Mezzo Demone Massiccio',
  'aberrazione_metallica_angelica': 'Aberrazione metallica · Angelica',
  'aberrazione_metallica_solare': 'Aberrazione metallica · Solare',
  'costrutto_minore': 'Costrutto Minore',
  'funghetto_cappuccio_rosso': 'Funghetto Cappuccio Rosso',
  'guardia_infernale_ik': 'Guardia Infernale Ik',
  'guardia_infernale_ik_elite': 'Guardia Infernale Ik Elité',
  'guardia_lunare': 'Guardia Lunare',
  'guardia_lunare_elite': 'Guardia Lunare Elité',
  'guardian_devil_moon': 'Guardian Devil Moon',
  'guardiano_lunare': 'Guardiano Lunare',
  'mezzo_demone_cosciente': 'Mezzo demone cosciente',
  'mosca_campana': 'Mosca Campana',
  'ogle': 'Ogle',
  'shadow_devil': 'Shadow Devil',
  'sharp': 'Sharp',
  'topino_avventuroso': 'Topino Avventuroso',
};

void main() {
  tearDown(resetMonsterBookEntries);

  test(
    'All 183 new gallery decisions resolve to their exact catalogue IDs',
    () {
      final entries = {
        ..._kept,
        for (final MapEntry(:key, :value) in _renames.entries) key: value.name,
      };
      expect(entries, hasLength(183));
      for (final MapEntry(key: id, value: name) in entries.entries) {
        const historical = {
          'firerose',
          'icerose',
          'maledizione_chaos',
          'maledizione_di_legno',
          'maledizione_maggiore',
          'osservatore_del_tempo',
        };
        if (historical.contains(id)) {
          expect(
            defaultMonsterBookEntries.any((entry) => entry.id == id),
            isFalse,
          );
          continue;
        }
        final entry = monsterBookEntryById(id);
        expect(entry, isNotNull, reason: id);
        expect(entry!.nameIt, name, reason: id);
        if (_renames.containsKey(id)) {
          expect(entry.nameEn, name, reason: id);
          expect(
            oculumMonsterNameSearchAliases(entry),
            contains(_renames[id]!.previous),
            reason: id,
          );
        }
      }
    },
  );

  test(
    'Material and the masked creature keep independent IDs and abilities',
    () {
      final masked = monsterBookEntryById('uomo_maschera')!;
      final lineage = monsterBookEntryById('material')!;
      expect(masked.nameIt, 'Material');
      expect(lineage.nameIt, 'Material');
      expect(masked.skillIds, contains('masked_base_strike'));
      expect(lineage.skillIds, contains('material_sparizione'));
      expect(oculumLookupMonsterId('Material').exact?.id, lineage.id);
      expect(
        oculumLookupMonsterId('Uomo con la maschera').exact?.id,
        masked.id,
      );
    },
  );

  test(
    'Renaming the stock creature leaves a saved custom definition intact',
    () {
      final stock = monsterBookEntryById('affogato_vortice_delle_arcate')!;
      final custom = stock.copyWith(
        nameIt: 'Nome personale',
        descIt: 'Descrizione personale',
      );
      final saved = custom.toJson();
      configureMonsterBookEntries(
        customEntries: [MonsterBookEntry.fromJson(saved)],
      );
      final loaded = monsterBookEntryById(stock.id)!;
      expect(loaded.toJson(), saved);
      expect(
        oculumMonsterNameSearchAliases(loaded),
        containsAll(['Corallwhirl', 'Corallriel']),
      );
    },
  );
}
