part of 'monster_book.dart';

// Names explicitly selected in the complete gallery export on 19 November.
const _novemberGalleryMonsterNames = <String, ({String name, String previous})>{
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
  'bramble': (name: 'Bramriel', previous: 'Bramble'),
  'il_doppione': (name: 'Duploryn', previous: 'Il Doppione'),
  'mostro_sabbia': (name: 'Arenyryx', previous: 'Mostro di sabbia'),
  'nuvola_in_bottiglia': (name: 'Nubyvriel', previous: 'Nuvola in bottiglia'),
};

// A spoken name belongs to a specific species. Matching by spelling alone
// would also rename unrelated entries with the same name or a custom name.
const _pronouncedMonsterNames = <String, ({String name, String spelling})>{
  'base_caramella_05': (name: 'Mallyr', spelling: 'Rospo Marshmallow'),
  'lumin_gommoso_variante_corazzata': (
    name: 'Lumlorel',
    spelling: 'Lumin Gommoso Corazzata',
  ),
  'eiva_tassello_cupole': (name: 'Tessyrel', spelling: 'Tessyfin'),
  'gabli_caverne': (name: 'Gablyn', spelling: 'Gabli delle Caverne'),
  // BEGIN APPROVED-GALLERY-1205-NAMES-20261118
  'habitat_caramella_rospo_di_crema_variante_veterana': (
    name: 'Dulcryn',
    spelling: 'Rospo di crema Veterana',
  ),
  'habitat_oblio_divoratore_degli_ultimi_nomi_variante_errante': (
    name: 'Oblyraven',
    spelling: 'Divoratore degli ultimi nomi Errante',
  ),
  'mantide_sanguescatto': (name: 'Vyridryx', spelling: 'Mantide Sanguescatto'),
  'teschio_quattro_lame': (name: 'Quadryth', spelling: 'Teschio Quattro Lame'),
  'habitat_caramella_falena_di_zucchero_filato_variante_errante': (
    name: 'Vagaflyr',
    spelling: 'Falena di zucchero filato Errante',
  ),
  'habitat_isole_razza_del_cielo_basso_variante_corazzata': (
    name: 'Ventryss',
    spelling: 'Razza del cielo basso Corazzata',
  ),
  'base_postea_02': (name: 'Runykryx', spelling: 'Grillo a Molla'),
  'weak_horror_mastino': (name: 'Cynyskar', spelling: 'Mastino della Cripta'),
  'pellegrino_senza_volto_variante_errante': (
    name: 'Senvyrel',
    spelling: 'Pellegrino Senza Volto Errante',
  ),
  'manichino_spada': (name: 'Ensypeth', spelling: 'Manichino della Spada'),
  // END APPROVED-GALLERY-1205-NAMES-20261118
  'habitat_oblio_ragno_delle_ombre_cancellate_variante_veterana': (
    name: 'Abrasyrel',
    spelling: 'Ragno delle ombre cancellate Veterana',
  ),
  'habitat_morti_regina_delle_cripte_sommerse_variante_corazzata': (
    name: 'Funerys',
    spelling: 'Regina delle cripte sommerse Corazzata',
  ),
  'habitat_diabolico_re_dei_patti_consumati': (
    name: 'Scoryth',
    spelling: 'Re dei patti consumati',
  ),
  'habitat_vero_inferno_custode_del_cancello_senza_ritorno_variante_rituale': (
    name: 'Claustyr',
    spelling: 'Custode del cancello senza ritorno Rituale',
  ),
  'habitat_sotterraneo_talpa_dei_cristalli_ciechi': (
    name: 'Vibryn',
    spelling: 'Talpa dei cristalli ciechi',
  ),
  'habitat_nuvole_rocciose_serpente_del_cumulonembo_variante_corazzata': (
    name: 'Nymboryth',
    spelling: 'Serpente del cumulonembo Corazzata',
  ),
  'habitat_shadow_hell_regina_dello_specchio_dell_oblio_variante_veterana': (
    name: 'Umbreth',
    spelling: 'Regina dello specchio dell’Oblio Veterana',
  ),
  'habitat_isole_vipera_dei_parafulmini_variante_rituale': (
    name: 'Fulgryn',
    spelling: 'Vipera dei parafulmini Rituale',
  ),
  'habitat_postea_serpente_di_cavi_variante_veterana': (
    name: 'Funyrn',
    spelling: 'Serpente di cavi Veterana',
  ),
  'mosca_campana_variante_veterana': (
    name: 'Tynbell',
    spelling: 'Mosca Campana Veterana',
  ),
  'habitat_diabolico_re_dei_patti_consumati_variante_errante': (
    name: 'Foedryn',
    spelling: 'Re dei patti consumati Errante',
  ),
  'habitat_foresta_elementale_rospo_delle_spore_sonore_variante_veterana': (
    name: 'Sporym',
    spelling: 'Rospo delle spore sonore Veterana',
  ),
  'base_mezzano_04': (name: 'Fimbrarel', spelling: 'Rospo Vellutato'),
  'habitat_vero_inferno_segugio_delle_nove_fornaci': (
    name: 'Clibryx',
    spelling: 'Segugio delle nove fornaci',
  ),
  'uomo_maschera_rossa': (
    name: 'Voultyr',
    spelling: 'Uomo con la maschera rossa',
  ),
  'hero_path_diverso_lancia_variante_errante': (
    name: 'Vagryss',
    spelling: 'Diverso Portalance Errante',
  ),
  'habitat_nuvole_rocciose_riccio_delle_saette_corte_variante_corazzata': (
    name: 'Echynrel',
    spelling: 'Riccio delle saette corte Corazzata',
  ),
  'habitat_ghiaccio_drago_della_notte_polare_variante_veterana': (
    name: 'Polarith',
    spelling: 'Drago della notte polare Veterana',
  ),
  'habitat_caramella_volpe_di_gelatina_variante_veterana': (
    name: 'Gelyss',
    spelling: 'Volpe di gelatina Veterana',
  ),
  'habitat_nuvole_rocciose_rospo_della_pioggia_obliqua': (
    name: 'Imbryn',
    spelling: 'Rospo della pioggia obliqua',
  ),
  'gatto_ciotola_variante_corazzata': (
    name: 'Bowlyx',
    spelling: 'Gatto Ciotola Corazzata',
  ),
  'eiva_serracapo_mosaici_variante_fulmine': (
    name: 'Cuproth',
    spelling: 'Serracapo dei mosaici Denti di rame',
  ),
  'habitat_nuvole_rocciose_medusa_dei_fulmini_lenti': (
    name: 'Lapysrieth',
    spelling: 'Medusa dei fulmini lenti',
  ),
  'affogato_granchio_delle_cappelle_variante_ghiaccio': (
    name: 'Gelycryn',
    spelling: 'Granchio delle Cappelle di Gelo',
  ),
  'ragno_putrido_variante_corazzata': (
    name: 'Pustryth',
    spelling: 'Ragno Putrido Corazzata',
  ),
  'base_foresta_05': (name: 'Florel', spelling: 'Serpe dei Fiori Notturni'),
  'base_postea_03': (name: 'Talparel', spelling: 'Talpa Trivella'),
  'base_postea_04': (name: 'Gecuprkren', spelling: 'Gecko di Rame'),
  'affogato_faldavela_variante_ghiaccio': (
    name: 'Faldelryn',
    spelling: 'Faldavela di Gelo',
  ),
  'base_affogato_03': (name: 'Ruinyryx', spelling: 'Razza delle Rovine'),
  'base_sotterraneo_05': (name: 'Talpobreth', spelling: 'Talpa d’Ossidiana'),
  'costrutto_dei_tre_crani': (
    name: 'Tryasmorem',
    spelling: 'Costrutto dei Tre Crani',
  ),
  'habitat_caramella_vespa_di_miele_scuro': (
    name: 'Melyriel',
    spelling: 'Vespa di miele scuro',
  ),
  'habitat_postea_mantide_a_pistoni_variante_rituale': (
    name: 'Cyrketh',
    spelling: 'Mantide a pistoni Rituale',
  ),
  'hero_path_brace': (
    name: 'Umacenerys Errante',
    spelling: 'Sacrestano di Brace',
  ),
  'affogato_razziatore_delle_fronde_variante_veleno': (
    name: 'Toxyriel',
    spelling: 'Razziatore delle Fronde di Veleno',
  ),
  'affogato_sentinella_di_basalto_variante_fulmine': (
    name: 'Fulgeryx',
    spelling: 'Luxryf di Fulmine',
  ),
  'base_sotterraneo_07': (name: 'Lapyrith', spelling: 'Millepiedi di Quarzo'),
  'eiva_razza_cisterne_variante_roccia': (
    name: 'Tegylryn',
    spelling: 'Razza delle cisterne Di coccio',
  ),
  'eiva_spugna_salmastra_variante_acqua': (
    name: 'Salyfunnel',
    spelling: 'Spugna succhiasale dell’ansa',
  ),
  'forest_rune_golem_variante_veterana': (
    name: 'Visrune',
    spelling: 'Forest Rune Golem Veterana',
  ),
  'habitat_angelico_falena_del_canto_d_argento': (
    name: 'Argentymoth',
    spelling: 'Falena del canto d’argento',
  ),
  'habitat_diabolico_segugio_del_patto_di_ferro': (
    name: 'Ferryl',
    spelling: 'Segugio del patto di ferro',
  ),
  'habitat_foresta_elementale_antico_dei_venti_elementi': (
    name: 'Cortexward',
    spelling: 'Antico dei venti elementi',
  ),
  'habitat_foresta_elementale_ragno_della_linfa_acida_variante_errante': (
    name: 'Sapstalk',
    spelling: 'Ragno della linfa acida Errante',
  ),
  'habitat_foresta_elementale_salamandra_delle_felci_ardenti': (
    name: 'Cinderel',
    spelling: 'Salamandra delle felci ardenti',
  ),
  'habitat_foresta_elementale_serpente_del_muschio_psichico': (
    name: 'Muscuspair',
    spelling: 'Serpente del muschio psichico',
  ),
  'habitat_ghiaccio_falena_della_neve_nera_variante_errante': (
    name: 'Nivymoth',
    spelling: 'Falena della neve nera Errante',
  ),
  'habitat_isole_granchio_delle_navi_aeree_variante_corazzata': (
    name: 'Navyreth',
    spelling: 'Granchio delle navi aeree Corazzata',
  ),
  'habitat_morti_segugio_del_camposanto': (
    name: 'Funehound',
    spelling: 'Segugio del camposanto',
  ),
  'habitat_nuvole_rocciose_masticatore_degli_archi_celesti_variante_errante': (
    name: 'Vagusclasp',
    spelling: 'Masticatore degli archi celesti Errante',
  ),
  'habitat_nuvole_rocciose_rospo_della_pioggia_obliqua_variante_corazzata': (
    name: 'Imbryplate',
    spelling: 'Rospo della pioggia obliqua Corazzata',
  ),
  'habitat_postea_ragno_saldatore': (
    name: 'Ragno Saldatore',
    spelling: 'Ragno saldatore',
  ),
  'habitat_postea_segugio_dei_circuiti_runici_variante_veterana': (
    name: 'Visrunhound',
    spelling: 'Segugio dei circuiti runici Veterana',
  ),
  'habitat_sacro_giudice_dalle_sette_aureole': (
    name: 'Aurumjud',
    spelling: 'Giudice dalle sette aureole',
  ),
  'habitat_sotterraneo_maggiore_talpa_del_diamante_nero': (
    name: 'Talpyshard',
    spelling: 'Talpa del diamante nero',
  ),
  'habitat_sotterraneo_salamandra_della_ghiaia': (
    name: 'Glarynewt',
    spelling: 'Salamandra della ghiaia',
  ),
  'habitat_vero_inferno_sovrano_della_fiamma_originaria_variante_rituale': (
    name: 'Primyflare',
    spelling: 'Sovrano della fiamma originaria Rituale',
  ),
  'terrore_sotterranei_variante_rituale': (
    name: 'Mirusrend',
    spelling: 'Terrore dei Sotterranei Rituale',
  ),
  'affogato_custode_della_chiusa': (
    name: 'Constacuas',
    spelling: 'Custode della Chiusa',
  ),
  'affogato_vedetta_dei_canali': (
    name: 'Pysciwarden',
    spelling: 'Vedetta dei Canali',
  ),
  'affogato_palmatore_dei_nastri': (
    name: 'Pynnasway',
    spelling: 'Palmatore dei nastri',
  ),
  'affogato_palmatore_dei_nastri_variante_natura': (
    name: 'Pynnasway di Natura',
    spelling: 'Palmatore dei nastri di Natura',
  ),
  'affogato_palmatore_dei_nastri_variante_veleno': (
    name: 'Toxivryth',
    spelling: 'Palmatore dei nastri di Veleno',
  ),
  'affogato_sentinella_di_basalto': (
    name: 'Luxryf',
    spelling: 'Sentinella di basalto',
  ),
  'affogato_tessitore_della_corrente': (
    name: 'Undathread',
    spelling: 'Tessitore della corrente',
  ),
  'piranha_mortale': (name: 'Dentysnap', spelling: 'Piranha Mortale'),
  oculumPiovraSucchiasangueId: (
    name: 'Cruoryn',
    spelling: 'Piovra succhiasangue',
  ),
  'aberrazione_oro_marmo_intermedia_solare': (
    name: 'Aurystride',
    spelling: 'Sunwalker',
  ),
  'aberrazione_oro_marmo_superiore_angelica': (
    name: 'Aurybone',
    spelling: 'Aberrazione Superiore Angelica',
  ),
  'ammasso_carne_ossa_errante_variante_rituale': (
    name: 'Karnyrattle',
    spelling: 'Caro Ossis',
  ),
  'ammasso_pustoloso': (name: 'Ossyblayn', spelling: 'Caro Blisterhide'),
  'angelo_fustigatore_variante_rituale': (
    name: 'Miruslash',
    spelling: 'Flagellum Vow',
  ),
  'arcangelo_variante_errante': (
    name: 'Vagarwyngh',
    spelling: 'Ordinwing Wingstray',
  ),
  'arpia_base_variante_veterana': (name: 'Ventyclaw', spelling: 'Venticlaw'),
  'armaiolo_della_fila_lunga_variante_rituale': (
    name: 'Mirusforge',
    spelling: 'Armaiolo della Fila Lunga Rituale',
  ),
  'bandito_base_variante_veterana': (
    name: 'Bandita Veterana',
    spelling: 'Bandito Veterana',
  ),
  'baby_rock_rhino_variante_veterana': (name: 'Visrhyno', spelling: 'Visrhino'),
  'bambola_vapium_variante_veterana': (
    name: 'Visvapyr',
    spelling: 'Bambola di Vapium Veterana',
  ),
  'base_ghiaccio_05': (name: 'Nyveth', spelling: 'Gufo di Neve Blu'),
  'ferrugryp': (name: 'Ferrumhol', spelling: 'Ferrugrip'),
  'osycleiv': (name: 'Osycleiv', spelling: 'Osseocleave'),
  'errante_della_forza': (name: 'Rubrymhol', spelling: 'Rubrymaul'),
  'errante_della_resistenza': (name: 'Dyurahyd', spelling: 'Durahide'),
  'ciclo_cervo_radure_miti': (
    name: 'Cervyss',
    spelling: 'Cervo delle Radure Miti',
  ),
  'ciclo_falena_delirio': (name: 'Delyr', spelling: 'Falena del Delirio'),
  'ciclo_mantide_vampa': (name: 'Ignytis', spelling: 'Mantide della Vampa'),
  'ciclo_forest_demon_blu': (name: 'Nebulyveil', spelling: 'Nebulaveil'),
  'ciclo_rospo_gronde_marce': (
    name: 'Imbrytoad',
    spelling: 'Rospo delle Gronde Marce',
  ),
  'ciclo_scarabeo_sigillo_ardente': (
    name: 'Sygilscyel',
    spelling: 'Scarabeo del Sigillo Ardente',
  ),
  'ciclope_del_fato': (name: 'Fatomhol', spelling: 'Fatummaul'),
  'habitat_nuvole_rocciose_golem_delle_ghiaie_orbitanti': (
    name: 'Lapyrel',
    spelling: 'Golem delle ghiaie orbitanti',
  ),
  'bunnys_variante_veterana': (name: 'Visbunnys', spelling: 'Bunnys Veterana'),
  'fata_cacciatrice': (name: 'Ventybleyd', spelling: 'Ventyblade'),
  'crostaceo_corazzato': (name: 'Karyklaw', spelling: 'Karyclaw'),
  'cuore_lava_variante_corazzata': (
    name: 'Ignyshell',
    spelling: 'Armored Emberheart',
  ),
  'custode_campana_cieca': (name: 'Vesanybel', spelling: 'Vesanybell'),
  'larva_del_vespro': (name: 'Umbracryp', spelling: 'Umbracreep'),
  'larva_del_vespro_variante_errante': (
    name: 'Umbraskulk',
    spelling: 'Larva del Vespro Errante',
  ),
  'larva_lava_variante_corazzata': (
    name: 'Syntermoltys',
    spelling: 'Syntermoltis',
  ),
  'habitat_demoniaco_regina_delle_gole_vulcaniche': (
    name: 'Alaryft',
    spelling: 'Regina delle gole vulcaniche',
  ),
  'golem_runico_variante_veterana': (name: 'Viscuprum', spelling: 'Vis Cuprum'),
  'troll_base_variante_veterana': (name: 'Visbark', spelling: 'Troll Veterana'),
  'meccanio_ammaccato_variante_errante': (
    name: 'Vaghyuil',
    spelling: 'Meccanio Malconcio Errante',
  ),
  'sposa_marea_nera': (name: 'Nuptayd', spelling: 'Nuptatide'),
  oculumOblyvuardId: (name: 'Oblyvuard', spelling: 'Oblivuard'),
  'idra_base': (name: 'Tryjyr', spelling: 'Hydra'),
  'ragno_putrido': (name: 'Venereth', spelling: 'Ragno Putrido'),
  'graga_rana_azzurra_variante_corazzata': (
    name: 'Gragaloryx',
    spelling: 'Graga Rana Azzurra Corazzata',
  ),
  'habitat_foresta_elementale_lince_di_brina_verde_variante_corazzata': (
    name: 'Vyridfrost',
    spelling: 'Lince di brina verde Corazzata',
  ),
  'habitat_sotterraneo_regina_delle_miniere_mute_variante_rituale': (
    name: 'Tacyantel',
    spelling: 'Regina delle miniere mute Rituale',
  ),
  'habitat_morti_falena_del_sudario_variante_veterana': (
    name: 'Funerwing',
    spelling: 'Falena del sudario Veterana',
  ),
  'habitat_diabolico_scarabeo_dei_contratti_ardenti': (
    name: 'Pactycarapace',
    spelling: 'Scarabeo dei contratti ardenti',
  ),
  'mostricciattolo_di_carta_variante_rituale': (
    name: 'Mirusfold',
    spelling: 'Mostricciattolo di Carta Rituale',
  ),
  'hero_path_diverso_ascia_variante_corazzata': (
    name: 'Foryan',
    spelling: 'Diverso Spaccaporte Corazzata',
  ),
  'base_sotterraneo_06': (name: 'Turrysilk', spelling: 'Ragno Campanile'),
  'habitat_diabolico_segugio_del_patto_di_ferro_variante_errante': (
    name: 'Vaghound',
    spelling: 'Segugio del patto di ferro Errante',
  ),
  'habitat_ghiaccio_golem_del_ghiacciaio_cavo_variante_rituale': (
    name: 'Mirusrime',
    spelling: 'Golem del ghiacciaio cavo Rituale',
  ),
  'habitat_morti_vedova_delle_ossa_cucite_variante_corazzata': (
    name: 'Sutywidow',
    spelling: 'Vedova delle ossa cucite Corazzata',
  ),
  'inspired_rospaccio_rosso_variante_corazzata': (
    name: 'Rubrytoad',
    spelling: 'Rospaccio Rosso Corazzata',
  ),
  'lanterniere_osso_variante_errante': (
    name: 'Ossylight',
    spelling: 'Lanterniere d’Osso Errante',
  ),
  'larva_del_grimorio_variante_corazzata': (
    name: 'Larvascrybus',
    spelling: 'Larva del Grimorio Corazzata',
  ),
  'lightning_skull_variante_rituale': (
    name: 'Fulgurskull',
    spelling: 'Teschio di fulmine Rituale',
  ),
  'lumaca_assassina_variante_errante': (
    name: 'Clavytrail',
    spelling: 'Lumaca Assassina Errante',
  ),
  'mammut_corazzato_variante_corazzata': (
    name: 'Mammuth di Ferro Runico',
    spelling: 'Mammut Corazzato Corazzata',
  ),
  'santo_vuoto_piccolo_variante_corazzata': (
    name: 'Nyhlward',
    spelling: 'Santo Vuoto Piccolo Corazzata',
  ),
  'affogato_granchio_delle_cappelle_variante_roccia': (
    name: 'Sacrycrab',
    spelling: 'Granchio delle Cappelle di Roccia',
  ),
  'generated_normal_002_variante_errante': (
    name: 'Orcryst',
    spelling: 'Orco del Sottoscala Errante',
  ),
  'pesce_mutato_variante_corazzata': (
    name: 'Squamyscute',
    spelling: 'Pesce Mutato Corazzata',
  ),
  'lupo_delle_nevi': (name: 'Glayswuolf', spelling: 'Glacewolf'),
  'lupo_infernale_del_ghiaccio': (
    name: 'Gelyfang',
    spelling: 'Lupo Infernale del Ghiaccio',
  ),
  'solgaze': (name: 'Solgheiz', spelling: 'Solgaze'),
  'sanguifang': (name: 'Sanguifeng', spelling: 'Sanguifang'),
  'terramound': (name: 'Terramaund', spelling: 'Terramound'),
  'lignobark': (name: 'Lignoryt', spelling: 'Lignobark'),
  'durafur': (name: 'Ferryfur', spelling: 'Ferrifur'),
  'scheletro_bombarolo': (name: 'Ossyfling', spelling: 'Scheletro Bombarolo'),
  'sciamano_malizioso': (name: 'Dolyfern', spelling: 'Dolifern'),
  oculumSonoreyeId: (name: 'Sonorays', spelling: 'Sonoreye'),
  oculumCynervailId: (name: 'Cynerveil', spelling: 'Cinervail'),
  oculumMutantRatId: (name: 'Ratygrinh', spelling: 'Ratygreen'),
  'corvo_della_morte_evoluto': (
    name: 'Lunavyr',
    spelling: 'Corvo della Morte evoluto',
  ),
};

// Previous approved names remain aliases of their exact stable species ID.
// Do not infer a rename from a matching label or mutate historical votes.
const _legacyPronouncedMonsterNames = <String, List<String>>{
  'base_postea_03': ['Talpabor'],
  'base_postea_04': ['Gecko di Rame'],
  'habitat_postea_mantide_a_pistoni_variante_rituale': ['Miruscyrus'],
  'affogato_faldavela_variante_ghiaccio': ['Faldavela di Gelo'],
  'affogato_razziatore_delle_fronde_variante_veleno': ['Toxifern'],
  'affogato_sentinella_di_basalto_variante_fulmine': ['Fulgheryft'],
  'base_affogato_03': ['Razza delle Rovine'],
  'base_sotterraneo_05': ['Talpa d’Ossidiana'],
  'base_sotterraneo_07': ['Lapypede'],
  'eiva_razza_cisterne_variante_roccia': ['Tegylfin'],
  'habitat_nuvole_rocciose_medusa_dei_fulmini_lenti': [
    'Lapysurge',
    'Lapysriel',
  ],
  'ragno_putrido_variante_corazzata': ['Pustrysilk'],
  'base_foresta_05': ['Florycoil'],
  'piovra_succhiasangue': ['Octocruor'],
  'base_ghiaccio_05': ['Nyvowl'],
  'idra_base': ['Tryjaw'],
  'habitat_nuvole_rocciose_golem_delle_ghiaie_orbitanti': ['Lapyorbit'],
  'ciclo_cervo_radure_miti': ['Cervydew'],
  'ciclo_falena_delirio': ['Delyrmoth'],
  'mosca_campana_variante_veterana': ['Vistynbell'],
  'base_caramella_05': ['Rospo Marshmallow'],
  'gatto_ciotola_variante_corazzata': ['Bowlyward'],
  'habitat_caramella_volpe_di_gelatina_variante_veterana': ['Visgel'],
  'affogato_granchio_delle_cappelle_variante_ghiaccio': ['Gelycarapace'],
  'eiva_serracapo_mosaici_variante_fulmine': ['Cuprosajur'],
  'habitat_foresta_elementale_rospo_delle_spore_sonore_variante_veterana': [
    'Visporym',
  ],
  'habitat_vero_inferno_segugio_delle_nove_fornaci': ['Clibanfang'],
  'hero_path_diverso_lancia_variante_errante': ['Vaguspike'],
  'uomo_maschera_rossa': ['Voultyfist'],
  'habitat_diabolico_re_dei_patti_consumati_variante_errante': ['Foedryx'],
  'habitat_postea_serpente_di_cavi_variante_veterana': ['Visfunycord'],
  'base_postea_02': ['Runycrick'],
  'habitat_caramella_rospo_di_crema_variante_veterana': ['Dulcycrust'],
  'manichino_spada': ['Ensypuppet'],
  'habitat_caramella_falena_di_zucchero_filato_variante_errante': ['Vagafloss'],
  'habitat_isole_razza_del_cielo_basso_variante_corazzata': ['Ventyscute'],
  'pellegrino_senza_volto_variante_errante': ['Senza Volto Errante'],
  'teschio_quattro_lame': ['Quadrilame'],
  'weak_horror_mastino': ['Cynyscarn'],
  'habitat_oblio_divoratore_degli_ultimi_nomi_variante_errante': ['Oblyravyn'],
  'mantide_sanguescatto': ['Vyridblade'],
  'gabli_caverne': ['Gabli delle Caverne'],
  'habitat_diabolico_re_dei_patti_consumati': ['Scoryrex'],
  'habitat_morti_regina_delle_cripte_sommerse_variante_corazzata': [
    'Funeryshroud',
  ],
  'habitat_isole_vipera_dei_parafulmini_variante_rituale': ['Mirusfulgur'],
  'habitat_nuvole_rocciose_serpente_del_cumulonembo_variante_corazzata': [
    'Nymboscyte',
  ],
  'habitat_oblio_ragno_delle_ombre_cancellate_variante_veterana': ['Abrasyweb'],
  'habitat_vero_inferno_custode_del_cancello_senza_ritorno_variante_rituale': [
    'Mirusclaust',
  ],
  'habitat_sotterraneo_talpa_dei_cristalli_ciechi': ['Vibryclaw'],
  'habitat_shadow_hell_regina_dello_specchio_dell_oblio_variante_veterana': [
    'Umbracrown',
  ],
  'eiva_tassello_cupole': ['Tessyfin'],
  'habitat_caramella_vespa_di_miele_scuro': ['Melysting'],
  'habitat_foresta_elementale_salamandra_delle_felci_ardenti': ['Cindercoil'],
  'habitat_ghiaccio_drago_della_notte_polare_variante_veterana': [
    'Polaryscale',
  ],
  'habitat_isole_granchio_delle_navi_aeree_variante_corazzata': ['Navysnare'],
  'habitat_nuvole_rocciose_riccio_delle_saette_corte_variante_corazzata': [
    'Echynspark',
  ],
  'habitat_nuvole_rocciose_rospo_della_pioggia_obliqua': ['Imbrywing'],
  'hero_path_diverso_ascia_variante_corazzata': ['Forisplit'],
  'lumin_gommoso_variante_corazzata': ['Lumin Gommoso Corazzata'],
  'ragno_putrido': ['Venemuk'],
  'affogato_palmatore_dei_nastri_variante_veleno': ['Toxyvitta'],
  'base_mezzano_04': ['Fimbraglow'],
};

MonsterBookEntry _withPronouncedMonsterName(MonsterBookEntry entry) {
  final name =
      _novemberGalleryMonsterNames[entry.id]?.name ??
      _pronouncedMonsterNames[entry.id]?.name;
  if (name == null) return entry;
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

final _builtinMonsterNamesById = {
  for (final entry in _builtinMonsterBookEntriesIncludingLegacy)
    entry.id: entry,
};

/// An approved historical spoken name belongs to one exact species ID.
/// Generic species labels may also be inherited by its variants; callers can
/// prefer this explicit binding after checking current custom display names.
bool oculumMonsterNameIsApprovedLegacyAlias(
  MonsterBookEntry entry,
  String normalizedName, {
  required String Function(String) normalize,
}) {
  final previous = _novemberGalleryMonsterNames[entry.id]?.previous;
  return (previous != null && normalize(previous) == normalizedName) ||
      (_legacyPronouncedMonsterNames[entry.id] ?? const <String>[]).any(
        (name) => normalize(name) == normalizedName,
      );
}

/// Alternate spellings are available even if a Master changes the label.
/// The caller still decides whether the current user knows the creature.
Iterable<String> oculumMonsterNameSearchAliases(MonsterBookEntry entry) {
  final builtin = _builtinMonsterNamesById[entry.id];
  final pronounced = _pronouncedMonsterNames[entry.id];
  final revised = _novemberGalleryMonsterNames[entry.id];
  final acuagoblin = entry.id.startsWith('${oculumAcuagoblinId}_variante_');
  return <String>{
    entry.id,
    entry.nameIt,
    entry.nameEn,
    entry.speciesNameIt,
    entry.speciesNameEn,
    if (builtin != null) ...{
      builtin.nameIt,
      builtin.nameEn,
      builtin.speciesNameIt,
      builtin.speciesNameEn,
    },
    if (pronounced != null) ...{pronounced.name, pronounced.spelling},
    if (revised != null) ...{revised.name, revised.previous},
    ...(_legacyPronouncedMonsterNames[entry.id] ?? const <String>[]),
    if (entry.id == 'affogato_palmatore_dei_nastri_variante_veleno')
      'Pynnasway di Veleno',
    if (entry.id == oculumPredoneBoomerangId) ...{
      'Predone delle Nasse',
      'Predone del Boomerang',
    },
    if (entry.id.split('_variante_').first == 'eiva_serracapo_mosaici')
      'Serracapo dei mosaici',
    if (entry.id == 'eiva_tassello_cupole') 'Tassello delle cupole',
    if (entry.id.startsWith('eiva_tassello_cupole_variante_'))
      entry.nameIt.replaceFirst('Tessyfin', 'Tassello delle cupole'),
    if (entry.id.split('_variante_').first == 'affogato_vortice_delle_arcate')
      'Vortice delle Arcate',
    if (entry.id == '${oculumPredoneBoomerangId}_variante_buio')
      'Predone delle Nasse di Buio',
    if (entry.id == '${oculumPredoneBoomerangId}_variante_veleno')
      'Predone delle Nasse di Veleno',
    if (entry.id == 'aberrazione_oro_marmo_intermedia_solare') ...{
      'Auristride',
      'Aberrazione Intermedia d’Oro e Marmo · Solare',
    },
    if (entry.id == 'arcangelo_variante_errante') ...{'Vagawyng', 'Vagarwingh'},
    if (entry.id == 'arpia_base_variante_veterana') 'Veteran Harpy',
    if (entry.id == 'larva_lava_variante_corazzata') ...{
      'Armored Lava Larva',
      'Sintermoltys',
    },
    if (entry.id == 'cuore_lava_variante_corazzata') 'Cuore di Lava Corazzato',
    if (entry.id == 'golem_runico_variante_veterana') ...{
      'Golem Runico Veterano',
      'Veteran Runic Golem',
    },
    if (entry.id == 'durafur') 'Durafèr',
    if (entry.id == 'bunnys_variante_veterana') 'Bunnysveteranus',
    if (entry.id == 'baby_rock_rhino_variante_veterana') ...{
      'Baby Rock Rhino Veterana',
      'Veteran Baby Rock Rhino',
    },
    if (entry.id == oculumIntermediateRockRhynoId) ...{
      'Rock Rhino Intermedio',
      'Intermediate Rock Rhino',
    },
    if (entry.id == oculumOblyvuardId) 'Oblivward',
    if (entry.id == 'lignobark') 'Lignobarc',
    if (entry.id == 'ciclo_forest_demon_blu') 'Forest Demon Blu',
    if (entry.id == oculumCynervailId) 'Cynervail',
    if (entry.id == 'corvo_della_morte_evoluto') 'Evolved Death Raven',
    if (acuagoblin) ...{
      'Aquagoblin',
      entry.nameIt.replaceFirst('Acuagoblin', 'Aquagoblin'),
      entry.nameEn.replaceFirst('Acuagoblin', 'Aquagoblin'),
    },
  }..removeWhere((name) => name.trim().isEmpty);
}
