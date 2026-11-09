part of 'monster_book.dart';

// Scelte della galleria soprannomi e Skill dell'8 novembre 2026.
const _november8MonsterNames = <String, String>{
  'habitat_shadow_hell_caprone_della_memoria_bruciata': 'Remnath',
  'habitat_shadow_hell_caprone_della_memoria_bruciata_variante_corazzata':
      'Ferravak',
  'habitat_demoniaco_caprone_delle_fornaci': 'Braskarn',
  'habitat_demoniaco_caprone_delle_fornaci_variante_errante': 'Ramblehorn',
  'cavaliere_morto_variante_errante': 'Hollowguard',
  'habitat_morti_cavaliere_senza_epitaffio': 'Tombwake',
  'habitat_morti_cavaliere_senza_epitaffio_variante_errante': 'Grave Strider',
  'base_affogato_06': 'Seahold',
  'habitat_postea_centauro_monorotaia': 'Axlehoof',
  'habitat_postea_centauro_monorotaia_variante_errante': 'Switchhoof',
  'habitat_sotterraneo_maggiore_centopiedi_del_quarzo_profondo': 'Veinrunner',
  'habitat_sotterraneo_maggiore_centopiedi_del_quarzo_profondo_variante_rituale':
      'Quartz Hex',
  'habitat_sotterraneo_centopiedi_della_selce': 'Spark Crawler',
  'habitat_sotterraneo_centopiedi_della_selce_variante_corazzata': 'Flintplate',
  'hero_path_cervello': 'Cerevorn',
  'hero_path_cervello_variante_corazzata': 'Mindplate',
  'cervo_candela': 'Wax Antler',
  'cervo_carne_aperta': 'Rawhart',
  'habitat_morti_cervo_del_corteo_funebre': 'Lastvitalis',
  'habitat_morti_cervo_del_corteo_funebre_variante_rituale': 'Mournhart',
  'habitat_nuvole_rocciose_cervo_del_vento_minerale': 'Windshard',
  'habitat_nuvole_rocciose_cervo_del_vento_minerale_variante_errante':
      'Shardhorn',
  'habitat_ghiaccio_cervo_delle_corna_di_vetro': 'Rime Antler',
  'habitat_ghiaccio_cervo_delle_corna_di_vetro_variante_veterana': 'Frostcrown',
  'habitat_affogato_cervo_delle_foreste_marine': 'Reef Stag',
  'habitat_affogato_cervo_delle_foreste_marine_variante_errante': 'Kelproam',
  'habitat_foresta_elementale_cervo_delle_sorgenti': 'Springhart',
  'habitat_foresta_elementale_cervo_delle_sorgenti_variante_errante':
      'Brookhorn',
  'base_caramella_06': 'Biscuit Horn',
  'habitat_caramella_cervo_di_candy_cane': 'Sugarhart',
  'habitat_caramella_cervo_di_candy_cane_variante_errante': 'Broken Candy',
  'habitat_postea_chimera_di_ricambi': 'Scrap Chimera',
  'habitat_postea_chimera_di_ricambi_variante_rituale': 'Runeweld',
  'ciclope_non_morto_variante_corazzata': 'Iron Ossor',
  'habitat_nuvole_rocciose_cinghiale_delle_creste_volanti_variante_errante':
      'Cloudtusk',
  'habitat_postea_cinghiale_delle_discariche': 'Rustsnout',
  'habitat_postea_cinghiale_delle_discariche_variante_rituale': 'Spark Tusk',
  'habitat_ghiaccio_cinghiale_delle_stalattiti': 'Frosttusk',
  'habitat_ghiaccio_cinghiale_delle_stalattiti_variante_corazzata':
      'Frostplate Boar',
  'habitat_caramella_cinghiale_di_croccante': 'Crunchboar',
  'habitat_caramella_cinghiale_di_croccante_variante_rituale': 'Caramel Tusk',
  'base_postea_05': 'Coil Owl',
  'kobold_base_variante_corazzata': 'Iron Kobold',
  'coboldo_di_brina_variante_corazzata': 'Frostscale',
  'base_caramella_04': 'Jellybug',
  'base_foresta_06': 'Jadebug',
  'habitat_foresta_elementale_colibri_del_temporale': 'Thunderbill',
  'habitat_foresta_elementale_colibri_del_temporale_variante_rituale':
      'Stormchant Hummer',
  'collezionista_di_elementi': 'Element Hoarder',
  'collezionista_di_elementi_variante_rituale': 'Element Seal',
  'habitat_angelico_colomba_delle_lame_bianche': 'Cutfeather',
  'habitat_angelico_colomba_delle_lame_bianche_variante_rituale':
      'Deadly Plumes',
  'habitat_postea_colosso_della_sirena': 'Foundry Howl',
  'habitat_postea_colosso_della_sirena_variante_veterana': 'Siren Bastion',
  'coro_facce_spezzate': 'Broken Faces',
  'coro_facce_spezzate_variante_corazzata': 'Faceplate Chorus',
  'hero_path_rosso': 'Baghest Slave',
  'hero_path_rosso_variante_veterana': 'Baghest Slave Elité',
  'inspired_corvo_becco_orologio': 'Tick Crow',
  'inspired_corvo_becco_orologio_variante_rituale': 'Crooked Hour',
  'habitat_nuvole_rocciose_corvo_del_magnete_celeste': 'Cloud Raven',
  'habitat_nuvole_rocciose_corvo_del_magnete_celeste_variante_veterana':
      'Bent Compass',
  'habitat_ghiaccio_corvo_del_vento_bianco': 'Rimewing',
  'habitat_ghiaccio_corvo_del_vento_bianco_variante_corazzata':
      'Ice Armor Crow',
  'habitat_morti_corvo_delle_lapidi': 'Stone Epitaph',
  'habitat_morti_corvo_delle_lapidi_variante_rituale': 'Vigil Wing',
  'habitat_caramella_corvo_di_cacao': 'Cocoa Crow',
  'habitat_caramella_corvo_di_cacao_variante_errante': 'Cacao Rover',
  'base_foresta_08': 'Barkbeak',
  'base_caramella_09': 'Licorice Raven',
  'costrutto_rinsecchito_variante_corazzata': 'Witherplate',
  'crosty': 'Crustkin',
  'cultist_of_purple_eyes_variante_errante': 'Dòminus Oculum',
  'cuore_lava_variante_corazzata': 'Armored Emberheart',
  'habitat_postea_custode_dei_terminali': 'Cableward',
  'habitat_postea_custode_dei_terminali_variante_veterana': 'Cable Bastion',
  'habitat_angelico_custode_del_coro_perduto': 'Ivory Choir',
  'habitat_angelico_custode_del_coro_perduto_variante_errante':
      'Wandering Hymn',
  'habitat_sotterraneo_maggiore_custode_del_cuore_sotterraneo': 'Clayclaw',
  'habitat_sotterraneo_maggiore_custode_del_cuore_sotterraneo_variante_errante':
      'Deep Wanderer',
  'habitat_ghiaccio_custode_del_passo_sepolto': 'Rime Pass',
  'habitat_ghiaccio_custode_del_passo_sepolto_variante_veterana':
      'Glacier Warden',
  'habitat_mezzano_custode_del_ponte_muschioso': 'Mosswarden',
  'habitat_mezzano_custode_del_ponte_muschioso_variante_errante': 'Fernpath',
  'habitat_sotterraneo_custode_del_pozzo_di_basalto': 'Black Stone Guard',
  'habitat_sotterraneo_custode_del_pozzo_di_basalto_variante_rituale':
      'Basalt Rune',
  'habitat_oblio_custode_del_pozzo_muto': 'Mute Keeper',
  'habitat_oblio_custode_del_pozzo_muto_variante_errante': 'Silence Warden',
  'habitat_sacro_custode_del_vetro_consacrato': 'Vitrael',
  'habitat_sacro_custode_del_vetro_consacrato_variante_corazzata':
      'Hallowed Bastion',
  'custode_campana_cieca_variante_veterana': 'Blind Bell',
  'habitat_diabolico_custode_della_catena_diabolica': 'Chainwarden',
  'habitat_diabolico_custode_della_catena_diabolica_variante_veterana':
      'Chain Bastion',
  'habitat_affogato_custode_della_diga_di_perle': 'Pearl Warden',
  'habitat_affogato_custode_della_diga_di_perle_variante_corazzata':
      'Reef Bastion',
  'habitat_caramella_custode_della_fontana_fondente': 'Meltwell',
  'habitat_caramella_custode_della_fontana_fondente_variante_corazzata':
      'Sugarplate',
  'habitat_angelico_custode_delle_piume_cucite': 'Stitchwing',
  'habitat_angelico_custode_delle_piume_cucite_variante_errante':
      'Needle Pinion',
  'dalatro': 'Dalàtro',
  'dalatro_variante_veterana': 'Dalàtro Veterana',
  'base_affogato_09': 'Stillfin',
  'demone_glaciale_intermedio_variante_errante': 'Nivrak',
  'demone_glaciale_maggiore_variante_veterana': 'Cryzath',
  'demone_glaciale_minore_variante_rituale': 'Nivrask',
  'demone_minore_variante_corazzata': 'Ashdrak',
  'demonietto_bruciante': 'Embrakk',
  'demonietto_bruciante_variante_errante': 'Cindrath',
  'demonietto_del_gelo': 'Nivrokk',
  'demonietto_del_gelo_variante_rituale': 'Cryorath',
  'obliterated_devil_variante_rituale': 'Voidhark',
};

const _november8HiddenMonsterBookIds = <String>{
  'habitat_demoniaco_custode_dei_chiodi_roventi',
  'habitat_demoniaco_custode_dei_chiodi_roventi_variante_veterana',
  'habitat_mezzano_corvo_delle_monete_false',
  'habitat_mezzano_corvo_delle_monete_false_variante_rituale',
};

/// Exact desktop votes, including entries hidden from the manual.
final oculumNovember8VotedMonsterIds = Set<String>.unmodifiable({
  ..._november8MonsterNames.keys,
  ..._november8HiddenMonsterBookIds,
});

// These confirmations include names whose desktop vote is still pending.
const _november9MonsterNames = <String, String>{
  'habitat_sacro_aberrazione_del_coro_diviso_variante_errante': 'Schisma',
  'aberrazione_oro_marmo_intermedia_angelica': "Aberrazione d'Oro",
  'aberrazione_oro_marmo_intermedia_solare': 'Sunwalker',
  'aberrazione_oro_marmo_maggiore_angelica': 'Angel Feather',
  'aberrazione_oro_marmo_maggiore_solare': 'Angel Feather Elité',
  'aberrazione_oro_marmo_minore_angelica': 'Aberrazione Minore Angelica',
  'aberrazione_oro_marmo_minore_solare': 'Aberrazione Minore Solare',
  'aberrazione_oro_marmo_superiore_angelica': 'Aberrazione Superiore Angelica',
  'aberrazione_oro_marmo_superiore_solare': 'Aberrazione Superiore Sole',
  'agla_variante_corazzata': 'Lorica Gleaner',
  'habitat_isole_airone_delle_correnti_inverse': 'Ardea Upstream',
  'habitat_isole_airone_delle_correnti_inverse_variante_rituale':
      'Ardea Upstream Elité',
  'ammasso_carne_ossa_errante_variante_rituale': 'Caro Ossis',
  'ammasso_pustoloso': 'Caro Blisterhide',
  'angelo_fustigatore_variante_rituale': 'Flagellum Vow',
  'angelo_palpebra_sporca_variante_veterana': 'Iudex Blight',
  'habitat_postea_anguilla_del_trasformatore_variante_errante': 'Runa Rivet',
  'base_affogato_01': 'Pallor Current',
  'habitat_affogato_anguilla_delle_campane_sommerse_variante_rituale':
      'Pallor Current Elité',
  'habitat_foresta_elementale_antico_dei_venti_elementi_variante_errante':
      'Viginti Ward',
  'araldo_raggio_angelico_variante_errante': 'Azurictus Bluecross',
  'habitat_oblio_araldo_del_silenzio_assoluto': 'Nullivox Echoend',
  'habitat_oblio_araldo_del_silenzio_assoluto_variante_errante':
      'Mutavest Shadecross',
  'habitat_sacro_araldo_del_sole_ferito': 'Soliscind Gildscar',
  'habitat_sacro_araldo_del_sole_ferito_variante_errante':
      'Soliscind Riftstride',
  'habitat_vero_inferno_araldo_della_cenere_eterna_variante_rituale':
      'Mostro Infernale',
  'habitat_shadow_hell_araldo_della_fenditura_nera': 'Hollowgaze',
  'habitat_shadow_hell_araldo_della_fenditura_nera_variante_veterana':
      'Dark Beast',
  'habitat_angelico_araldo_della_scala_luminosa': 'Scalalume Ivoryrise',
  'habitat_angelico_araldo_della_scala_luminosa_variante_veterana':
      'Scalalume Ivoryrise Elité',
  'habitat_demoniaco_araldo_delle_cicatrici_ardenti': 'Cicathorn Firescar',
  'habitat_demoniaco_araldo_delle_cicatrici_ardenti_variante_rituale':
      'Cicathorn Brandrite',
  'habitat_diabolico_araldo_delle_corone_fuse': 'Regnoth Crownsmelt',
  'habitat_diabolico_araldo_delle_corone_fuse_variante_errante':
      'Regnoth Thronewake',
  'habitat_morti_araldo_delle_tombe_aperte': 'Tombwake',
  'arcangelo_variante_errante': 'Ordinwing Wingstray',
  'habitat_postea_archivista_della_citt_errante_variante_corazzata':
      'Custos Relay',
  'habitat_angelico_ariete_delle_porte_celesti': 'Ebur Ward',
  'habitat_angelico_ariete_delle_porte_celesti_variante_corazzata':
      'Lamella Bastion',
  'baby_forest_demon_variante_rituale': 'Silvarkrath',
  'habitat_morti_bambola_di_ceneri': 'Cinerstitch',
  'habitat_morti_bambola_di_ceneri_variante_corazzata': 'Little CinerShield',
  'habitat_morti_becchino_dalle_mani_lunghe_variante_errante': 'Gravemanus',
  'bestia_invisibile_del_vantaggio': 'Occulthunt',
};

MonsterBookEntry _withVotedMonsterName(MonsterBookEntry entry) {
  final name =
      _november9MonsterNames[entry.id] ?? _november8MonsterNames[entry.id];
  if (name == null || name == entry.nameIt) return entry;
  return entry.copyWith(
    nameIt: name,
    nameEn: name,
    encounterRules: {
      ...entry.encounterRules,
      'speciesNameIt': entry.speciesNameIt,
      'speciesNameEn': entry.speciesNameEn,
    },
  );
}
