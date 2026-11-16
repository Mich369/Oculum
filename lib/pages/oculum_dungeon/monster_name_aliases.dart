part of 'monster_book.dart';

// A spoken name belongs to a specific species. Matching by spelling alone
// would also rename unrelated entries with the same name or a custom name.
const _pronouncedMonsterNames = <String, ({String name, String spelling})>{
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
    name: 'Pynnasway di Veleno',
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
    name: 'Octocruor',
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
  'base_ghiaccio_05': (name: 'Nyvowl', spelling: 'Gufo di Neve Blu'),
  'ferrugryp': (name: 'Ferrumhol', spelling: 'Ferrugrip'),
  'osycleiv': (name: 'Osycleiv', spelling: 'Osseocleave'),
  'errante_della_forza': (name: 'Rubrymhol', spelling: 'Rubrymaul'),
  'errante_della_resistenza': (name: 'Dyurahyd', spelling: 'Durahide'),
  'ciclo_cervo_radure_miti': (
    name: 'Cervydew',
    spelling: 'Cervo delle Radure Miti',
  ),
  'ciclo_falena_delirio': (name: 'Delyrmoth', spelling: 'Falena del Delirio'),
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
    name: 'Lapyorbit',
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
  'idra_base': (name: 'Tryjaw', spelling: 'Hydra'),
  'ragno_putrido': (name: 'Venemuk', spelling: 'Ragno Putrido'),
  'hero_path_diverso_ascia_variante_corazzata': (
    name: 'Forisplit',
    spelling: 'Diverso Spaccaporte Corazzata',
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

MonsterBookEntry _withPronouncedMonsterName(MonsterBookEntry entry) {
  final pronounced = _pronouncedMonsterNames[entry.id];
  if (pronounced == null) return entry;
  return entry.copyWith(
    nameIt: pronounced.name,
    nameEn: pronounced.name,
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

/// Alternate spellings are available even if a Master changes the label.
/// The caller still decides whether the current user knows the creature.
Iterable<String> oculumMonsterNameSearchAliases(MonsterBookEntry entry) {
  final builtin = _builtinMonsterNamesById[entry.id];
  final pronounced = _pronouncedMonsterNames[entry.id];
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
    if (pronounced != null) pronounced.spelling,
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
