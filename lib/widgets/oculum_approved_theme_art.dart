// Approved desktop choices from SCELTE-TEMI-PLAYER-20261118.json and
// the Kingi and Iride cesellata receipts of 19 November. Stable saved IDs stay unchanged.
// Explicit theme artwork and custom layers retain their existing precedence.
// Desktop remains the existing fallback where no mobile scene is approved.
const oculumApprovedThemeStoryAssets = <String, String>{
  'abyssal_tide':
      'assets/oculum/theme_stories/webp/abyssal_tide_canon_20261118_d_dc86d375.webp',
  'benedict':
      'assets/oculum/theme_stories/webp/benedict_canon_20261118_a_8007de51.webp',
  'blood_court':
      'assets/oculum/theme_stories/webp/blood_court_canon_20261118_a_e614e427.webp',
  'bolted_black_iron':
      'assets/oculum/theme_stories/webp/bolted_black_iron_canon_20261118_d_d59878f7.webp',
  'bone_saint':
      'assets/oculum/theme_stories/webp/bone_saint_canon_20261118_a_45867a79.webp',
  'cell_crimson_run':
      'assets/oculum/theme_stories/webp/cell_crimson_run_canon_20261118_f_b398b69c.webp',
  'element_pack_acido':
      'assets/oculum/theme_stories/webp/element_pack_acido_canon_20261118_b_ac4df5ae.webp',
  'element_pack_angelico':
      'assets/oculum/theme_stories/webp/element_pack_angelico_canon_20261118_d_db1a1e09.webp',
  'element_pack_esplosivo':
      'assets/oculum/theme_stories/webp/element_pack_esplosivo_canon_20261118_d_8ccf2c04.webp',
  'element_pack_oculum':
      'assets/oculum/theme_stories/webp/element_pack_oculum_canon_20261119_c_1455481c.webp',
  'element_pack_postea':
      'assets/oculum/theme_stories/webp/element_pack_postea_canon_20261118_b_2ebd66f1.webp',
  'element_pack_proiettile':
      'assets/oculum/theme_stories/webp/element_pack_proiettile_canon_20261118_a_4e398923.webp',
  'element_pack_radiazione':
      'assets/oculum/theme_stories/webp/element_pack_radiazione_canon_20261118_d_21ace57d.webp',
  'element_pack_radice':
      'assets/oculum/theme_stories/webp/element_pack_radice_canon_20261118_d_2a24b130.webp',
  'element_pack_spazio':
      'assets/oculum/theme_stories/webp/element_pack_spazio_canon_20261118_d_a7620466.webp',
  'element_pack_tempo':
      'assets/oculum/theme_stories/webp/element_pack_tempo_canon_20261118_b_62c9fe85.webp',
  'element_pack_veleno':
      'assets/oculum/theme_stories/webp/element_pack_veleno_canon_20261118_b_a5cef015.webp',
  'home_canva_spirit_duelist':
      'assets/oculum/theme_stories/webp/home_canva_spirit_duelist_canon_20261118_b_89d19026.webp',
  'home_cathedral_eye':
      'assets/oculum/theme_stories/webp/home_cathedral_eye_canon_20261118_e_41839ab5.webp',
  'hoshy_cosmic_cat':
      'assets/oculum/theme_stories/webp/hoshy_cosmic_cat_canon_20261118_d_9802ff9d.webp',
  'karma_duality':
      'assets/oculum/theme_stories/webp/karma_duality_canon_20261118_b_b7cd5b14.webp',
  'kingi_wrong_future':
      'assets/oculum/theme_stories/webp/kingi_wrong_future_canon_20261119_f_cd1a4468.webp',
  'lunar_eclipse':
      'assets/oculum/theme_stories/webp/lunar_eclipse_canon_20261118_f_89c62655.webp',
  'meadow_sprite':
      'assets/oculum/theme_stories/webp/meadow_sprite_canon_20261118_b_20ad125a.webp',
  'moon_iron':
      'assets/oculum/theme_stories/webp/moon_iron_canon_20261118_e_4ab89f48.webp',
  'obsidian_sigil':
      'assets/oculum/theme_stories/webp/obsidian_sigil_canon_20261118_e_91693ee8.webp',
  'phobia_dark':
      'assets/oculum/theme_stories/webp/phobia_dark_canon_20261118_d_9fc04a9f.webp',
  'restyle_lume':
      'assets/oculum/theme_stories/webp/restyle_lume_canon_20261118_b_5200a706.webp',
  'restyle_sogno':
      'assets/oculum/theme_stories/webp/restyle_sogno_canon_20261118_a_f2f4d724.webp',
  'solar_reliquary':
      'assets/oculum/theme_stories/webp/solar_reliquary_canon_20261118_b_81f72337.webp',
  'vervain_gothic':
      'assets/oculum/theme_stories/webp/vervain_gothic_canon_20261118_b_97839b7a.webp',
  'void_liturgy':
      'assets/oculum/theme_stories/webp/void_liturgy_canon_20261118_b_65550dd8.webp',
  'deep_forest_demon':
      'assets/oculum/theme_stories/webp/deep_forest_demon_canon_20261128_e_f34986a4.webp',
  'eclipse_bonfire':
      'assets/oculum/theme_stories/webp/eclipse_bonfire_canon_20261128_f1_306c4289.webp',
  'element_pack_cenere':
      'assets/oculum/theme_stories/webp/element_pack_cenere_canon_20261128_d_55251b19.webp',
  'element_pack_gravita':
      'assets/oculum/theme_stories/webp/element_pack_gravita_canon_20261128_f_fa209101.webp',
  'element_pack_solare':
      'assets/oculum/theme_stories/webp/element_pack_solare_canon_20261128_f_af2883a0.webp',
  'element_pack_vapium':
      'assets/oculum/theme_stories/webp/element_pack_vapium_canon_20261128_a_0fd2c9cb.webp',
  'element_pack_vero':
      'assets/oculum/theme_stories/webp/element_pack_vero_canon_20261128_d_fc2e20ff.webp',
  'ember_rite':
      'assets/oculum/theme_stories/webp/ember_rite_canon_20261128_b_8a098210.webp',
  'monster_lantern':
      'assets/oculum/theme_stories/webp/monster_lantern_canon_20261128_b1_8a6a19c4.webp',
  'restyle_sangue':
      'assets/oculum/theme_stories/webp/restyle_sangue_canon_20261128_b_f79dd1e6.webp',
  'element_pack_nonmorto':
      'assets/oculum/theme_stories/webp/element_pack_nonmorto_canon_20261128_b_ca1a367b.webp',
  'cathedral_rose':
      'assets/oculum/theme_stories/webp/cathedral_rose_canon_20261128_c_dd6d45be.webp',
  'buried_herbarium':
      'assets/oculum/theme_stories/webp/buried_herbarium_canon_20261128_c_99e23d27.webp',
  'element_pack_acqua':
      'assets/oculum/theme_stories/webp/element_pack_acqua_canon_20261128_e_254e5233.webp',
  'slime_prince':
      'assets/oculum/theme_stories/webp/slime_prince_canon_20261128_c_78673aa3.webp',
  'element_pack_perforante':
      'assets/oculum/theme_stories/webp/element_pack_perforante_canon_20261128_c_0a0a315f.webp',
  'plane_postea':
      'assets/oculum/theme_stories/webp/plane_postea_canon_20261128_c1_86264e7e.webp',
  'element_pack_benedizione':
      'assets/oculum/theme_stories/webp/element_pack_benedizione_canon_20261128_c_a9b46941.webp',
  'restyle_natura':
      'assets/oculum/theme_stories/webp/restyle_natura_canon_20261128_c1_4e4bba45.webp',
  'element_pack_vento':
      'assets/oculum/theme_stories/webp/element_pack_vento_canon_20261128_b_b7e1fd83.webp',
  'vtt_obsidian_grid':
      'assets/oculum/theme_stories/webp/vtt_obsidian_grid_canon_20261128_f_77bc6eda.webp',
  'tidal_stained_glass':
      'assets/oculum/theme_stories/webp/tidal_stained_glass_canon_20261128_c_6189d08d.webp',
};

String? oculumApprovedThemeStoryAsset(String id) =>
    oculumApprovedThemeStoryAssets[id];

/// Independent votes for portrait scenes, keyed by the same saved theme ID.
const oculumApprovedThemePhoneStoryAssets = <String, String>{
  'element_pack_angelico':
      'assets/oculum/theme_stories/webp/element_pack_angelico_mobile_canon_20261124_f_b17b8d78.webp',
};

/// Only the three already selectable Home scenes included in this vote.
const oculumApprovedManualHomeStoryIds = <String>{
  'benedict',
  'home_cathedral_eye',
  'home_canva_spirit_duelist',
};

String? oculumApprovedHomeStoryAsset(String normalizedId) =>
    oculumApprovedManualHomeStoryIds.contains(normalizedId)
    ? oculumApprovedThemeStoryAsset(normalizedId)
    : null;
