import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/game/oculum_combat_scout_rules.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_goth_ornaments.dart';
import 'package:oculum/widgets/oculum_monster_theme.dart';
import 'package:oculum/widgets/oculum_narrative_background.dart';
import 'package:oculum/widgets/oculum_theme_presentation.dart';
import 'package:oculum/widgets/oculum_theme_asset_packs.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

// Later name revisions leave the original plate/name votes above intact.
const _latestNameById = <String, String>{
  'eiva_spugna_salmastra_variante_acqua': 'Salyryn',
  'forest_rune_golem_variante_veterana': 'Runvisrith',
  'habitat_angelico_falena_del_canto_d_argento': 'Argentriel',
  'habitat_diabolico_segugio_del_patto_di_ferro': 'Ferhex',
  'habitat_foresta_elementale_antico_dei_venti_elementi': 'Cortexnys',
  'habitat_foresta_elementale_ragno_della_linfa_acida_variante_errante':
      'Sapryn',
  'habitat_foresta_elementale_serpente_del_muschio_psichico': 'Muscyreth',
  'habitat_ghiaccio_falena_della_neve_nera_variante_errante': 'Nivyryn',
  'habitat_morti_segugio_del_camposanto': 'Funeyryn',
  'habitat_nuvole_rocciose_masticatore_degli_archi_celesti_variante_errante':
      'Vagusreth',
  'habitat_nuvole_rocciose_rospo_della_pioggia_obliqua_variante_corazzata':
      'Pluvyryx',
  'habitat_postea_ragno_saldatore': 'Saldarith',
  'habitat_postea_segugio_dei_circuiti_runici_variante_veterana': 'Runhynrel',
  'habitat_sacro_giudice_dalle_sette_aureole': 'Aurumreth',
  'habitat_sotterraneo_maggiore_talpa_del_diamante_nero': 'Talpyryn',
  'habitat_sotterraneo_salamandra_della_ghiaia': 'Glaryx',
  'habitat_vero_inferno_sovrano_della_fiamma_originaria_variante_rituale':
      'Primykrath',
  'terrore_sotterranei_variante_rituale': 'Rendryx',
  'affogato_granchio_delle_cappelle_variante_roccia': 'Sacrith',
  'generated_normal_002_variante_errante': 'Orcryx',
  'pesce_mutato_variante_corazzata': 'Squamyryx',
  'base_sotterraneo_06': 'Turith',
  'habitat_diabolico_segugio_del_patto_di_ferro_variante_errante': 'Vagrym',
  'habitat_ghiaccio_golem_del_ghiacciaio_cavo_variante_rituale': 'Rimykrel',
  'habitat_morti_vedova_delle_ossa_cucite_variante_corazzata': 'Sutyryn',
  'inspired_rospaccio_rosso_variante_corazzata': 'Rubreth',
  'lanterniere_osso_variante_errante': 'Ossyrith',
  'larva_del_grimorio_variante_corazzata': 'Scrybreth',
  'lightning_skull_variante_rituale': 'Fulguryn',
  'lumaca_assassina_variante_errante': 'Clavyrel',
  'mammut_corazzato_variante_corazzata': 'Mamfereth',
  'santo_vuoto_piccolo_variante_corazzata': 'Nyhlryx',
  'cuore_lava_variante_corazzata': 'Ignyshryn',
  'troll_base_variante_veterana': 'Barkrith',
  'aberrazione_oro_marmo_intermedia_solare': 'Aurygrel',
  'arpia_base_variante_veterana': 'Ventycryth',
  'golem_runico_variante_veterana': 'Cuprith',
  'larva_lava_variante_corazzata': 'Syntereth',
  'arcangelo_variante_errante': 'Vagariel',
  'angelo_fustigatore_variante_rituale': 'Lashyrel',
  'agla_variante_corazzata': 'Loryel',
  'ammasso_pustoloso': 'Ossyblreth',
  'base_postea_03': 'Talparel',
  'habitat_postea_mantide_a_pistoni_variante_rituale': 'Cyrketh',
  'affogato_razziatore_delle_fronde_variante_veleno': 'Toxyriel',
  'affogato_sentinella_di_basalto_variante_fulmine': 'Fulgeryx',
  'base_sotterraneo_07': 'Lapyrith',
  'eiva_razza_cisterne_variante_roccia': 'Tegylryn',
  'habitat_nuvole_rocciose_medusa_dei_fulmini_lenti': 'Lapysrieth',
  'ragno_putrido_variante_corazzata': 'Pustryth',
  'base_foresta_05': 'Florel',
  'piovra_succhiasangue': 'Cruoryn',
  'base_ghiaccio_05': 'Nyveth',
  'idra_base': 'Tryjyr',
  'habitat_nuvole_rocciose_golem_delle_ghiaie_orbitanti': 'Lapyrel',
  'ciclo_cervo_radure_miti': 'Cervyss',
  'ciclo_falena_delirio': 'Delyr',
  'mosca_campana_variante_veterana': 'Tynbell',
  'base_caramella_05': 'Mallyr',
  'gatto_ciotola_variante_corazzata': 'Bowlyx',
  'habitat_caramella_volpe_di_gelatina_variante_veterana': 'Gelyss',
  'affogato_granchio_delle_cappelle_variante_ghiaccio': 'Gelycryn',
  'eiva_serracapo_mosaici_variante_fulmine': 'Cuproth',
  'habitat_foresta_elementale_rospo_delle_spore_sonore_variante_veterana':
      'Sporym',
  'habitat_vero_inferno_segugio_delle_nove_fornaci': 'Clibryx',
  'hero_path_diverso_lancia_variante_errante': 'Vagryss',
  'uomo_maschera_rossa': 'Voultyr',
  'habitat_diabolico_re_dei_patti_consumati_variante_errante': 'Foedryn',
  'habitat_postea_serpente_di_cavi_variante_veterana': 'Funyrn',
  'habitat_caramella_vespa_di_miele_scuro': 'Melyriel',
  'habitat_foresta_elementale_salamandra_delle_felci_ardenti': 'Cinderel',
  'habitat_ghiaccio_drago_della_notte_polare_variante_veterana': 'Polarith',
  'habitat_isole_granchio_delle_navi_aeree_variante_corazzata': 'Navyreth',
  'habitat_nuvole_rocciose_riccio_delle_saette_corte_variante_corazzata':
      'Echynrel',
  'habitat_nuvole_rocciose_rospo_della_pioggia_obliqua': 'Imbryn',
  'affogato_palmatore_dei_nastri_variante_veleno': 'Toxivryth',
  'base_mezzano_04': 'Fimbrarel',
};

void main() {
  testWidgets(
    'Selected Scostubanditi and faithful Errati ink are bundled by exact ID',
    (tester) async {
      for (final (id, digest) in [
        (
          'scostubanditi',
          'a451ac43991d5cf3642d8126b47cf0d6657c292eebd9a438aea54ae54c242a7d',
        ),
        (
          'scostubandito_errato',
          '0665d3134d808af1ce6663e2cc80edf648888438f58789f4ad7c7e1b5b2c5d0b',
        ),
        (
          'scostubandito_veterano_errato',
          '6cebae5505b15111972498fdd56b373aa8f6bb07a7efa96f6ef8fcefe6b00f9d',
        ),
      ]) {
        final monster = monsterBookEntryById(id)!;
        final theme = OculumMonsterTheme(
          monster,
          oculumMonsterColors(monster).first,
        );
        expect(theme.preserveIllustrationFraming, isTrue, reason: id);
        final bytes = await rootBundle.load(theme.illustration!);
        final actual = SHA256Digest()
            .process(
              bytes.buffer.asUint8List(
                bytes.offsetInBytes,
                bytes.lengthInBytes,
              ),
            )
            .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
            .join();
        expect(
          actual,
          digest,
          reason: '$id must use the author-approved image',
        );
      }
    },
  );
  testWidgets('Confirmed ink themes match the catalogue and packaged assets', (
    tester,
  ) async {
    for (final (id, name, digest) in [
      (
        'baby_forest_demon_variante_rituale',
        'Silvarkrath',
        'c91eec83811cd863eba84f9a881404c0efa389172c84a85a47c2d0f4d01b02e6',
      ),
      (
        'granscostumato_empatico',
        'GranScostumato Empatico',
        'cdc530417d59a036097041eba0e8e548538145366ea55e24b09da81d26a19536',
      ),
      (
        'granscostumato',
        'GranScostumato',
        '52a722431b3aaff5a67e04a2cdd03ecabb9177da36a424ab00fc145ad88b3f7c',
      ),
      (
        'habitat_postea_serpente_di_cavi_variante_veterana',
        'Visfunycord',
        '28eb9ffe01811a672d4d9cb82c1f42eea6b07e2dcb71c7a53aa4d505aa15fc7c',
      ),
      (
        'mosca_campana_variante_veterana',
        'Vistynbell',
        '837b4f99380cc181f2a84076db0db1594bd05e8faafa1c9ffedf6a5399e6aaa4',
      ),
      (
        'habitat_diabolico_re_dei_patti_consumati_variante_errante',
        'Foedryx',
        '26c7ccb49688d7541f6de60e13b8473ea124127374af786a9022cb4e276caa4b',
      ),
      (
        'habitat_foresta_elementale_rospo_delle_spore_sonore_variante_veterana',
        'Visporym',
        'fd8c184fb437028a21ab9ca6b17036b07d404b69873e53c02a571a79f94b2eec',
      ),
      (
        'base_mezzano_04',
        'Fimbraglow',
        '952e99a13f6a6e79cc4755883e9438385a92ec2dcd731e2ae5479415b9016556',
      ),
      (
        'habitat_vero_inferno_segugio_delle_nove_fornaci',
        'Clibanfang',
        'a8c24ba1e4aef330ee5699801e456c15df0200f1461e473496a90aba77f86772',
      ),
      (
        'uomo_maschera_rossa',
        'Voultyfist',
        '28c8f689551ae7e64ccce629ba6c33d1b4f5813cf7343d8de81e6d996f70e913',
      ),
      (
        'hero_path_diverso_lancia_variante_errante',
        'Vaguspike',
        '5368f2435c763066bb6fcbddd6203e0f0ca61769c5f991c95f4df20998e3ec19',
      ),
      (
        'affogato_palmatore_dei_nastri_variante_veleno',
        'Toxyvitta',
        'c55da9aec55baece8c2fea1be60b0d6c174d3df652937f9e24bf5030be700724',
      ),
      (
        'habitat_nuvole_rocciose_riccio_delle_saette_corte_variante_corazzata',
        'Echynspark',
        '801807ba264a1fad836e1d4437f40e582ef8ee71ed47e4f1217e2dd6dbf3f64e',
      ),
      (
        'base_caramella_05',
        'Rospo Marshmallow',
        '8c97d5f64f74cae8230e9cee953c07ee259e5ba04befa9f8f24b4255f1db0467',
      ),
      (
        'habitat_ghiaccio_drago_della_notte_polare_variante_veterana',
        'Polaryscale',
        '1bb60a49927205f0d249ce1dbf3c4a4fb62ae1899d5881f216e742f3f9994c81',
      ),
      (
        'habitat_caramella_volpe_di_gelatina_variante_veterana',
        'Visgel',
        '4f813f9bee672bdf2b4a18a1ad9da995ad3e9ecd3e59de517bb0cc5222f5bacf',
      ),
      (
        'habitat_nuvole_rocciose_rospo_della_pioggia_obliqua',
        'Imbrywing',
        'f0d00d85dce73e99ee9efcd02f9f12e080c6ba9461a97ef7ca33eb52868d76c2',
      ),
      (
        'gatto_ciotola_variante_corazzata',
        'Bowlyward',
        'dd85a4aa33f5a6166c7aa0a8b4b44b05f5c2cca16d5bda8501438597109fc6f0',
      ),
      (
        'eiva_serracapo_mosaici_variante_fulmine',
        'Cuprosajur',
        'f328e63f9a8f501a05a9dc071ca27720da1bb27217502e1df3f6c4ca87c3c829',
      ),
      (
        'habitat_nuvole_rocciose_medusa_dei_fulmini_lenti',
        'Lapysurge',
        'f96e9515722b5636ce60793639775d848bcd960bb4319a336224b5dda0657988',
      ),
      (
        'affogato_granchio_delle_cappelle_variante_ghiaccio',
        'Gelycarapace',
        '7fb1e7471ddd0d05b76a65a41b8af28a6471b1b79bac0ca89b73ba4b118d1144',
      ),
      (
        'ragno_putrido_variante_corazzata',
        'Pustrysilk',
        'e3cd7c39fde9cca3dbf358627924154e8ef7b402710d001025cebaecae16693a',
      ),
    ]) {
      final monster = monsterBookEntryById(id);
      expect(monster, isNotNull, reason: id);
      final currentName = _latestNameById[id] ?? name;
      expect(monster!.nameIt, currentName);
      expect(
        monster.nameEn,
        id == 'granscostumato_empatico'
            ? 'Empathic GranScostumato'
            : currentName,
      );
      expect(oculumMonsterNameSearchAliases(monster), contains(name));
      final theme = OculumMonsterTheme(
        monster,
        oculumMonsterColors(monster).first,
      );
      expect(theme.preserveIllustrationFraming, isTrue, reason: id);
      final asset = theme.illustration;
      expect(asset, isNotNull, reason: id);
      final bytes = await rootBundle.load(asset!);
      final actual = SHA256Digest()
          .process(
            bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          )
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();
      expect(actual, digest, reason: asset);
    }
  });

  testWidgets('Confirmed Classic ink backgrounds load the approved B plates', (
    tester,
  ) async {
    const confirmedDigests = {
      'classic_reliquary':
          '81ee021f0330654508e49a0b29657a22910744dbe6b56a5a5436b266f5c2a1d8',
      'classic_rpg':
          'a7a049f13af60676cfa195ede57459727d12539f51926d6742340ad175914f69',
      'classic_low_detail':
          '9ca0d977e2e1dcd087b89e3cfa771c9366d87d44c91ac3fd5cbac8d443b6dc29',
    };
    for (final entry in confirmedDigests.entries) {
      final asset = oculumThemeAssetPacks[entry.key]!.storyScene;
      final bytes = await rootBundle.load(asset);
      final actual = SHA256Digest()
          .process(
            bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          )
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();
      expect(actual, entry.value, reason: asset);
    }
  });

  testWidgets('Open gallery approvals bind to each selected artwork surface', (
    tester,
  ) async {
    Future<void> expectDigest(String asset, String digest) async {
      final data = await rootBundle.load(asset);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final actual = SHA256Digest()
          .process(bytes)
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();
      expect(actual, digest, reason: asset);
    }

    for (final (id, surface, digest) in [
      (
        'base_foresta_05',
        'desktop',
        '8f62dc98e3d8cff86734e597e31d94a44bd1a27dc625cbc33c5715dfd0b2824e',
      ),
      (
        'base_postea_03',
        'desktop',
        '7910f3379432d19e2d2ced0515d580e97f0c26eb344fde24dcf77e32de173eb9',
      ),
      (
        'base_postea_04',
        'desktop',
        '83d5993efeb8985ec17818cce44319b0c91f4970036af2f0a062336a442f7876',
      ),
      (
        'costrutto_dei_tre_crani',
        'desktop',
        'd6115471c6f445aac749c8bf51665add09ccbecca73809e0ba623cdc6a3866f6',
      ),
      (
        'habitat_caramella_vespa_di_miele_scuro',
        'desktop',
        '6a454135342ed1e900cc33be9e9c00fb901878dfb1a69199799985f5f4695d2f',
      ),
      (
        'hero_path_brace',
        'desktop',
        'dc5ead47e8fb54d80459965185184e591695e35b99c25ec16b842fa1e2e9df6a',
      ),
      (
        'affogato_faldavela_variante_ghiaccio',
        'desktop',
        '96c06747e4f07ae6c678fc835c7049197efd3ce14bedb8c09d21ef53021115e5',
      ),
      (
        'affogato_razziatore_delle_fronde_variante_veleno',
        'desktop',
        '26d35cbff82608edf063579be0db125a644bb4a347de7a0f6214945ecb1cc125',
      ),
      (
        'affogato_sentinella_di_basalto_variante_fulmine',
        'desktop',
        '32063e03af59683fd498230179bb8d6c6940f21e49ed7a2528ce08b3faa80761',
      ),
      (
        'base_affogato_03',
        'desktop',
        '18c1e07f002a18ac1cedacd2b2d5e7260f75875950175afd8be0dbdbd7a931ca',
      ),
      (
        'base_sotterraneo_05',
        'desktop',
        '64c0e9efd389aa5e7e5c6e34cb7ced3523d22dd31cd282239ccad307ccd3a20f',
      ),
      (
        'base_sotterraneo_07',
        'desktop',
        '9823135be4cd867cfb3021530b38107c587cee96101b7dec3107843ea9698700',
      ),
      (
        'distruttor_caramella',
        'reliquia',
        '6934d821479851231a7ee68c12330a07d98b373d04bbeb337e9059c0a117562d',
      ),
      (
        'distruttor_caramella',
        'telefono',
        '23a4ce874953a86a82b8f257f24af8c8d62059deb6fc00993dc189ac5697a270',
      ),
      (
        'divoramitu',
        'reliquia',
        '39225bc579e0113e0a3d0d059701a82d6a7474db54c622ca760ed0fcdeaa2df7',
      ),
      (
        'divoramitu',
        'telefono',
        '008d19e465e80c08dc9cab770fe5164973213ae3a4aaa11e5c36231cc9163f91',
      ),
      (
        'divoramitu_elite',
        'reliquia',
        '00982b9a9d35d6067d090755dc06b1cb2d5db42ee3b372d68a0b0076bd47848c',
      ),
      (
        'divoramitu_elite',
        'telefono',
        'a023b8dc2847789b081d1bcc410873118b8432957d16afbce86faf34c8436a2b',
      ),
      (
        'eiva_razza_cisterne_variante_roccia',
        'desktop',
        '0f549a6b92afb266a45feda518c3d4140f6a3c65a5889eddc4ca657586026659',
      ),
      (
        'eiva_spugna_salmastra_variante_acqua',
        'desktop',
        '4ee6e666dfb61a900af640e051fb97a5f9a0f4823a383f8e93284330558118b9',
      ),
      (
        'forest_rune_golem_variante_veterana',
        'desktop',
        'b292b7b0b7813eed934ffc78e315f0b58fabb67a3f43d1d89c37a4051fbd58c2',
      ),
      (
        'habitat_angelico_falena_del_canto_d_argento',
        'desktop',
        '05b014fdad24b677d449b00cb36b4d3ad0fa41bf3d68869230f8b56fb886bce7',
      ),
      (
        'habitat_diabolico_segugio_del_patto_di_ferro',
        'desktop',
        '404ca69af32151b7d3779ed1d3dfcfc2a090c3113c3b165fa77d51285f1a5053',
      ),
      (
        'habitat_foresta_elementale_antico_dei_venti_elementi',
        'desktop',
        'd0621f4c71766aa9f2880386cd421934038013b030c13a67a98a3547bb5654a4',
      ),
      (
        'habitat_foresta_elementale_ragno_della_linfa_acida_variante_errante',
        'desktop',
        '674b3bddf9679ea0de9766c404eeb1011cf1487ba2ac3a0ebbe68ba00b8550ef',
      ),
      (
        'habitat_foresta_elementale_salamandra_delle_felci_ardenti',
        'desktop',
        'a4d3a1d9f54a9d2cdf706689b550e2c23b338e811cb2e0bca764cfc58a2a54f1',
      ),
      (
        'habitat_foresta_elementale_serpente_del_muschio_psichico',
        'desktop',
        '3012b74e7f9fba0588367f56bec733fb1ff3a5176f1d7cd02db15279a33f0117',
      ),
      (
        'habitat_ghiaccio_falena_della_neve_nera_variante_errante',
        'desktop',
        'f5fa2830a53ab92bb9dcf75a57692873b0ee6543afae1cea1086d66495e153a0',
      ),
      (
        'habitat_isole_granchio_delle_navi_aeree_variante_corazzata',
        'desktop',
        '23cb3ca9b074adc9cb592879729d433269cffa291d96c334d47557a7555b095b',
      ),
      (
        'habitat_morti_segugio_del_camposanto',
        'desktop',
        'f1f792ee19a9e7017afc32a235349ea7e242decc247a91764758b1b551db1436',
      ),
      (
        'habitat_nuvole_rocciose_masticatore_degli_archi_celesti_variante_errante',
        'desktop',
        'e0ce2bb950dad3a17fab340d5156eb2c5914c859bf48e06fe1ee734b61b1f80e',
      ),
      (
        'habitat_nuvole_rocciose_rospo_della_pioggia_obliqua_variante_corazzata',
        'desktop',
        '6ab38603f0afb830742a345e6b78bd92e8d349e96f70e93953eed80caeb8137d',
      ),
      (
        'habitat_postea_mantide_a_pistoni_variante_rituale',
        'desktop',
        'e8ad90b85b5336a3167dd7911295f1a30125db8510319f9a15d6a6c94acc6da3',
      ),
      (
        'habitat_postea_ragno_saldatore',
        'desktop',
        '315f116b1f54f6399961fcb07c386c57b65fb8656b0023113916ada096c09a70',
      ),
      (
        'habitat_postea_segugio_dei_circuiti_runici_variante_veterana',
        'desktop',
        'c0c39a8aa83a41fdbf3c31253bd3051b35f80e976ff4aab2ebf8d827d436f81f',
      ),
      (
        'habitat_sacro_giudice_dalle_sette_aureole',
        'desktop',
        '9f95c50abbfc66d735b319d39dc3f029abb630c5482b8b1e5103909fa642b149',
      ),
      (
        'habitat_sotterraneo_maggiore_talpa_del_diamante_nero',
        'desktop',
        '03057a3aa89c0a852d9f9dfc128a96a723ac1353fd169a6348feb8f06d394056',
      ),
      (
        'habitat_sotterraneo_salamandra_della_ghiaia',
        'desktop',
        '7d039517cda3b1d7b4d29d29dfd2a489481ea46820f6e6574852aaccd874e059',
      ),
      (
        'habitat_vero_inferno_sovrano_della_fiamma_originaria_variante_rituale',
        'desktop',
        'a96f1d751553a50ccb0d04cffce23c8661c36c2b9c70554879fa60ec02ddf2d1',
      ),
      (
        'ice_shield',
        'desktop',
        '2ac4853d33aaa92bc76027d8a67e9e8d5ca5194de1ece42e38e173dea149a002',
      ),
      (
        'tappo_con_zampe',
        'desktop',
        '2bde92aed0f168cb381387fd8b00c2dada2f76d13fed9d3e037cf25d68a214c3',
      ),
      (
        'terrore_sotterranei_variante_rituale',
        'desktop',
        'd248bcbc5bde4a53e895fff2be33acb0c6d09a603df3fd06da353ad0df8600bc',
      ),
      (
        'uomo_maschera',
        'desktop',
        'd17acce6f754f9953261c0cab5707d604d504e47ad2776eb6bd4ed3178fefd45',
      ),
    ]) {
      final entry = monsterBookEntryById(id)!;
      final theme = OculumMonsterTheme(entry, oculumMonsterColors(entry).first);
      final asset = switch (surface) {
        'desktop' => theme.illustration,
        'telefono' => theme.illustrationMobile,
        _ => theme.relicIllustration,
      };
      expect(asset, isNotNull, reason: '$id · $surface');
      if (surface == 'desktop') {
        expect(theme.preserveIllustrationFraming, isTrue, reason: id);
      }
      await expectDigest(asset!, digest);
    }

    await expectDigest(
      oculumLunarSymbolIllustration,
      '62ebb22cf729bcf3b70797f9f8b18c7a16c690b41ba619b0d58ab642132c657e',
    );
  });

  test('Open gallery names keep the exact identity and previous aliases', () {
    for (final (id, name, previous) in [
      ('base_foresta_05', 'Florycoil', 'Serpe dei Fiori Notturni'),
      ('base_postea_03', 'Talpabor', 'Talpa Trivella'),
      ('costrutto_dei_tre_crani', 'Tryasmorem', 'Costrutto dei Tre Crani'),
      (
        'habitat_caramella_vespa_di_miele_scuro',
        'Melysting',
        'Vespa di miele scuro',
      ),
      (
        'habitat_postea_mantide_a_pistoni_variante_rituale',
        'Miruscyrus',
        'Mantide a pistoni Rituale',
      ),
      ('hero_path_brace', 'Umacenerys Errante', 'Sacrestano di Brace'),
      (
        'affogato_razziatore_delle_fronde_variante_veleno',
        'Toxifern',
        'Razziatore delle Fronde di Veleno',
      ),
      (
        'affogato_sentinella_di_basalto_variante_fulmine',
        'Fulgheryft',
        'Luxryf di Fulmine',
      ),
      ('base_sotterraneo_07', 'Lapypede', 'Millepiedi di Quarzo'),
      (
        'eiva_razza_cisterne_variante_roccia',
        'Tegylfin',
        'Razza delle cisterne Di coccio',
      ),
      (
        'eiva_spugna_salmastra_variante_acqua',
        'Salyfunnel',
        'Spugna succhiasale dell’ansa',
      ),
      (
        'forest_rune_golem_variante_veterana',
        'Visrune',
        'Forest Rune Golem Veterana',
      ),
      (
        'habitat_angelico_falena_del_canto_d_argento',
        'Argentymoth',
        'Falena del canto d’argento',
      ),
      (
        'habitat_diabolico_segugio_del_patto_di_ferro',
        'Ferryl',
        'Segugio del patto di ferro',
      ),
      (
        'habitat_foresta_elementale_antico_dei_venti_elementi',
        'Cortexward',
        'Antico dei venti elementi',
      ),
      (
        'habitat_foresta_elementale_ragno_della_linfa_acida_variante_errante',
        'Sapstalk',
        'Ragno della linfa acida Errante',
      ),
      (
        'habitat_foresta_elementale_salamandra_delle_felci_ardenti',
        'Cindercoil',
        'Salamandra delle felci ardenti',
      ),
      (
        'habitat_foresta_elementale_serpente_del_muschio_psichico',
        'Muscuspair',
        'Serpente del muschio psichico',
      ),
      (
        'habitat_ghiaccio_falena_della_neve_nera_variante_errante',
        'Nivymoth',
        'Falena della neve nera Errante',
      ),
      (
        'habitat_isole_granchio_delle_navi_aeree_variante_corazzata',
        'Navysnare',
        'Granchio delle navi aeree Corazzata',
      ),
      (
        'habitat_morti_segugio_del_camposanto',
        'Funehound',
        'Segugio del camposanto',
      ),
      (
        'habitat_nuvole_rocciose_masticatore_degli_archi_celesti_variante_errante',
        'Vagusclasp',
        'Masticatore degli archi celesti Errante',
      ),
      (
        'habitat_nuvole_rocciose_rospo_della_pioggia_obliqua_variante_corazzata',
        'Imbryplate',
        'Rospo della pioggia obliqua Corazzata',
      ),
      ('habitat_postea_ragno_saldatore', 'Ragno Saldatore', 'Ragno saldatore'),
      (
        'habitat_postea_segugio_dei_circuiti_runici_variante_veterana',
        'Visrunhound',
        'Segugio dei circuiti runici Veterana',
      ),
      (
        'habitat_sacro_giudice_dalle_sette_aureole',
        'Aurumjud',
        'Giudice dalle sette aureole',
      ),
      (
        'habitat_sotterraneo_maggiore_talpa_del_diamante_nero',
        'Talpyshard',
        'Talpa del diamante nero',
      ),
      (
        'habitat_sotterraneo_salamandra_della_ghiaia',
        'Glarynewt',
        'Salamandra della ghiaia',
      ),
      (
        'habitat_vero_inferno_sovrano_della_fiamma_originaria_variante_rituale',
        'Primyflare',
        'Sovrano della fiamma originaria Rituale',
      ),
      (
        'terrore_sotterranei_variante_rituale',
        'Mirusrend',
        'Terrore dei Sotterranei Rituale',
      ),
    ]) {
      final entry = monsterBookEntryById(id)!;
      expect(entry.nameIt, _latestNameById[id] ?? name, reason: id);
      expect(
        oculumMonsterNameSearchAliases(entry),
        containsAll([name, previous]),
      );
      expect(oculumLookupMonsterId(name).exact?.id, id, reason: name);
    }
  });

  testWidgets('November 17 art and names bind to the chosen exact entries', (
    tester,
  ) async {
    for (final (id, name, oldName, digest) in [
      (
        'affogato_granchio_delle_cappelle_variante_roccia',
        'Sacrycrab',
        'Granchio delle Cappelle di Roccia',
        '04fb7e08d41c6c9213e420fcc96334612d24b6b54a4baad10bb61df8eb76b886',
      ),
      (
        'generated_normal_002_variante_errante',
        'Orcryst',
        'Orco del Sottoscala Errante',
        '2c27c5fb2f6f80c653d04c1f8417fe031ae3dddf695c8a5aba9188dd43176422',
      ),
      (
        'pesce_mutato_variante_corazzata',
        'Squamyscute',
        'Pesce Mutato Corazzata',
        '8fa545e9cef42145025308bcb1fcc29cb0b89aba11c5c04de7b621d211ef069b',
      ),
      (
        'base_sotterraneo_06',
        'Turrysilk',
        'Ragno Campanile',
        '494ea8aee032d7432c9552f3fec8abb3d50ca8660f1c054ae792e22db733ddaa',
      ),
      (
        'habitat_diabolico_segugio_del_patto_di_ferro_variante_errante',
        'Vaghound',
        'Segugio del patto di ferro Errante',
        'c0bf50010550ab795feb962ecfd3a890fdac1a8e55521963250404cb76e8b87c',
      ),
      (
        'habitat_ghiaccio_golem_del_ghiacciaio_cavo_variante_rituale',
        'Mirusrime',
        'Golem del ghiacciaio cavo Rituale',
        '339814f39794000059223914132e5cfaaa5b44584d577929c0e6654797338785',
      ),
      (
        'habitat_morti_vedova_delle_ossa_cucite_variante_corazzata',
        'Sutywidow',
        'Vedova delle ossa cucite Corazzata',
        '9657b78ab62b95d83892f9ddff7e6a177af448ac6e69b3559a1c1bee967fbe9c',
      ),
      (
        'inspired_rospaccio_rosso_variante_corazzata',
        'Rubrytoad',
        'Rospaccio Rosso Corazzata',
        '8f85eed658598d6b415aa4408c02ae4c6ede19af4b4dba2b1a4b68ecb54ea63f',
      ),
      (
        'lanterniere_osso_variante_errante',
        'Ossylight',
        'Lanterniere d’Osso Errante',
        'a63a797bafcd8145b70319b608f9b867fe352c33a9f41752452f0cfbd8a4384e',
      ),
      (
        'larva_del_grimorio_variante_corazzata',
        'Larvascrybus',
        'Larva del Grimorio Corazzata',
        '9e1778a690ad062e99121e336bd6f1942bdb5977268ecd297a6e45a3b3358fbf',
      ),
      (
        'lightning_skull_variante_rituale',
        'Fulgurskull',
        'Teschio di fulmine Rituale',
        '42c8faa8ca766aa71fe797742bbf1f23da4af2b2791535ca3105d2a2bd5d590d',
      ),
      (
        'lumaca_assassina_variante_errante',
        'Clavytrail',
        'Lumaca Assassina Errante',
        'a2c5579eccf3d9f1e484e6c6e763e8292999d2f5b293b0a17cdb0333ac99c11d',
      ),
      (
        'mammut_corazzato_variante_corazzata',
        'Mammuth di Ferro Runico',
        'Mammut Corazzato Corazzata',
        'a750f1f82f4764b93aaccad7f6ed3fb4c41130df0ba8f4bfd2dfbfb034fd9375',
      ),
      (
        'santo_vuoto_piccolo_variante_corazzata',
        'Nyhlward',
        'Santo Vuoto Piccolo Corazzata',
        'c99f16ee3ac9caa30311cb777bcc3745f047e92408bd3e024008a2bc818252a0',
      ),
    ]) {
      final entry = monsterBookEntryById(id)!;
      final currentName = _latestNameById[id] ?? name;
      expect(
        [entry.nameIt, entry.nameEn],
        [currentName, currentName],
        reason: id,
      );
      expect(
        oculumMonsterNameSearchAliases(entry),
        contains(oldName),
        reason: id,
      );
      expect(oculumLookupMonsterId(name).exact?.id, id, reason: name);
      expect(oculumLookupMonsterId(oldName).exact?.id, id, reason: oldName);

      final theme = OculumMonsterTheme(entry, oculumMonsterColors(entry).first);
      final asset =
          'assets/oculum/home_art_authored/theme_${id}_canon_20261117.webp';
      expect(theme.illustration, asset, reason: id);
      expect(theme.preserveIllustrationFraming, isTrue, reason: id);
      final data = await rootBundle.load(asset);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final actual = SHA256Digest()
          .process(bytes)
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();
      expect(actual, digest, reason: id);
    }
  });

  testWidgets('Both large lots bundle the twelve exact selected WebPs', (
    tester,
  ) async {
    const expected = {
      'marionettista_boss':
          '59b9407f92f64c75a2f03b9e4bcd48eb5adcf71c4e347e2cac6288447e14b8dc',
      'mammuth_in_decomposizione':
          '05ff8c991c6fe2e488e15193e1d4167ed0da4ef5869edf9e8e0c2d14d2a24c36',
      'scheletro_bombarolo':
          '176a534f09f90cc8e15e5e7505151d47b6d70717b7925d70d8daaa6c2700a591',
      'armaiolo_della_fila_lunga_variante_rituale':
          'e576f17257a955cb850e738e543c0ba87b726757eac82eda220ff8b612ee3619',
      'lupo_infernale_del_ghiaccio':
          '506cd23d6479a7a52628bbe05ff6faeff38fc822aab443bb30abd809fd63da56',
      'aberrazione_oro_marmo_superiore_angelica':
          'f13fa2696997eefa705bdb0892a350a4c6a69a4697b86acd603ba929e00cf3cc',
      'pawn_guardiano':
          '29fd72341ec787ca60217e416d97a9807336b957533d338197097d37e6f9be37',
      'pinepine':
          'b12c7b3f23713366f290c68e5b24f9060f4076a8c6a5668997fff79e53c98a92',
      'bambola_vapium_variante_veterana':
          'cdce4b9d8f5563a67179166275a4203fe4c1779c64162b599d9886952e493db7',
      'demone_glaciale_minore':
          'a2e323e0e063fd07f82eaca443bbc108453368db8de3d656d9a1f3f825c79e8b',
      'larva_del_vespro_variante_errante':
          '7dc284c14022b0fa516c0be863e4455934c494058456bda38d668acc812e377a',
      'snorlo':
          '140bbb9539b8859c48b90930877872b10815198c98e1fdb07aa524907fc8a078',
    };
    for (final entry in expected.entries) {
      final id = entry.key;
      final monster = monsterBookEntryById(id)!;
      final theme = OculumMonsterTheme(
        monster,
        oculumMonsterColors(monster).first,
      );
      final asset =
          'assets/oculum/home_art_authored/theme_${id}_canon_20261115.webp';
      expect(theme.illustration, asset, reason: id);
      expect(theme.preserveIllustrationFraming, isTrue, reason: id);
      final data = await rootBundle.load(asset);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final sha256 = SHA256Digest()
          .process(bytes)
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();
      expect(sha256, entry.value, reason: id);
    }

    for (final (id, stem) in [
      ('mammuth_in_decomposizione', 'mammuth_decomposizione'),
      ('pawn_guardiano', 'pawn'),
      ('pinepine', 'pinepine'),
    ]) {
      final monster = monsterBookEntryById(id)!;
      final theme = OculumMonsterTheme(
        monster,
        oculumMonsterColors(monster).first,
      );
      expect(
        theme.illustrationMobile,
        'assets/oculum/home_art_webp/theme_${stem}_mobile_v1.webp',
      );
      expect(
        theme.relicIllustration,
        'assets/oculum/home_art_webp/relic_${stem}_v1.webp',
      );
      expect(theme.preserveMobileIllustrationFraming, isFalse);
    }
    final aurybone = monsterBookEntryById(
      'aberrazione_oro_marmo_superiore_angelica',
    )!;
    final solar = OculumMonsterTheme.desktopIllustrationForId(
      'aberrazione_oro_marmo_superiore_solare',
    );
    expect(solar, endsWith('_canon_20261109_votes7.png'));
    expect(
      oculumMonsterPrecisionAnatomy(
        aurybone,
      ).where((part) => part['group'] == 'wings').map((part) => part['side']),
      unorderedEquals(['left', 'right']),
    );
  });

  testWidgets('November 15 approved backgrounds load by exact monster ID', (
    tester,
  ) async {
    for (final id in [
      'aberrazione_oro_marmo_intermedia_angelica',
      'aberrazione_oro_marmo_intermedia_solare',
      'acuagoblin_variante_curioso',
      'acuagoblin_variante_predatore',
      'acuagoblin_variante_territoriale',
      'agla_variante_corazzata',
      'air_navigator',
      'ammasso_carne_ossa_errante_variante_rituale',
      'ammasso_pustoloso',
      'angelo_fustigatore_variante_rituale',
      'arcangelo_variante_errante',
      'armadillo_cristallo',
      'armadillo_legno',
      'arpia_base_variante_veterana',
      'baby_forest_demon_variante_rituale',
      'baby_rock_rhino',
      oculumIntermediateRockRhynoId,
      'baby_rock_rhino_variante_veterana',
      'bandito_base_variante_veterana',
      'bunnys_variante_veterana',
      'corvo_della_morte_evoluto',
      'cuore_lava_variante_corazzata',
      'distruttor_caramella',
      'divoramitu',
      'divoramitu_elite',
      'golem_runico_variante_veterana',
      'guardia_solare',
      'guardia_solare_elite',
      'guardiano_solare',
      'habitat_demoniaco_regina_delle_gole_vulcaniche',
      'habitat_foresta_elementale_ragno_della_linfa_acida',
      'larva_lava_variante_corazzata',
      'lignobark',
      'meccanio_ammaccato_variante_errante',
      'oblyvuard',
      'ombra_ignota',
      'snorlo_variante_corazzata',
      'topo_mutante',
      'troll_base_variante_veterana',
    ]) {
      final monster = monsterBookEntryById(id)!;
      final theme = OculumMonsterTheme(
        monster,
        oculumMonsterColors(monster).first,
      );
      final asset = id == 'baby_forest_demon_variante_rituale'
          ? 'assets/oculum/home_art_authored/theme_baby_forest_demon_variante_rituale_canon_20261118_ink_f.webp'
          : 'assets/oculum/home_art_authored/theme_${id}_canon_20261115.webp';
      expect(theme.illustration, asset);
      expect(theme.preserveIllustrationFraming, isTrue);
      expect((await rootBundle.load(asset)).lengthInBytes, greaterThan(0));
    }
    expect(monsterBookEntryById('agla_variante_corazzata')!.nameIt, 'Loryel');
    for (final (id, name, alias) in [
      ('ammasso_pustoloso', 'Ossyblayn', 'Caro Blisterhide'),
      ('angelo_fustigatore_variante_rituale', 'Miruslash', 'Flagellum Vow'),
      ('arcangelo_variante_errante', 'Vagarwyngh', 'Ordinwing Wingstray'),
      ('base_ghiaccio_05', 'Nyvowl', 'Gufo di Neve Blu'),
      ('troll_base_variante_veterana', 'Visbark', 'Troll Veterana'),
      ('idra_base', 'Tryjaw', 'Idra'),
      ('cuore_lava_variante_corazzata', 'Ignyshell', 'Cuore di Lava Corazzato'),
      (
        'meccanio_ammaccato_variante_errante',
        'Vaghyuil',
        'Meccanio Malconcio Errante',
      ),
      (
        'bandito_base_variante_veterana',
        'Bandita Veterana',
        'Bandito Veterana',
      ),
    ]) {
      final monster = monsterBookEntryById(id)!;
      expect(monster.nameIt, _latestNameById[id] ?? name);
      expect(oculumMonsterNameSearchAliases(monster), contains(alias));
    }
    expect(
      oculumMonsterNameSearchAliases(
        monsterBookEntryById('arcangelo_variante_errante')!,
      ),
      containsAll(['Vagawyng', 'Vagarwingh']),
    );
    for (final (id, approvedVariant) in [
      ('acuagoblin_variante_predatore', 'acuagoblin_variante_territoriale'),
      ('acuagoblin_variante_curioso', 'acuagoblin_variante_territoriale'),
      ('corvo_della_morte', 'corvo_della_morte_evoluto'),
      ('divoramitu_elite', 'divoramitu'),
      ('baby_rock_rhino_variante_veterana', 'baby_rock_rhino'),
      ('snorlo', 'snorlo_variante_corazzata'),
      ('troll_base', 'troll_base_variante_veterana'),
      ('meccanio_ammaccato', 'meccanio_ammaccato_variante_errante'),
      (
        'aberrazione_oro_marmo_intermedia_angelica',
        'aberrazione_oro_marmo_intermedia_solare',
      ),
    ]) {
      expect(
        OculumMonsterTheme.desktopIllustrationForId(id),
        isNot(OculumMonsterTheme.desktopIllustrationForId(approvedVariant)),
      );
    }
  });

  testWidgets('ink selections resolve to the exact approved artwork', (
    tester,
  ) async {
    const expected = {
      'affogato_faldavela':
          '6164f6cda3101d313159d5d118e3d8a8db44f5615cfaf6788aca5992c781d6af',
      'armadillo_sabbia':
          '034fe6c89b41718b3870978341d58b2df1693abf9ea32d5279c53dc3bc11799c',
      'balena_dai_mille_occhi':
          '44047a480291affb0ac198d086ea379a28b19bab48899767774b081ea27ec7ce',
      'base_ghiaccio_05':
          '8cbeca98b5e893a24788d5b009345f29dd8ba97b2721cfef3547ad35849a2200',
      'ciclo_mantide_vampa':
          '9f6febc61d9880e8b9dbd1bd17e85d5d9c88316524bdcd0c5bed67a6a43531d9',
      'eiva_tassello_cupole':
          'd3c43b6a3657b51d89a22a3e8d362f266b4a25707e7c6c1e7a91a284faf768df',
      'gigante_sabbia':
          '56c8002683cd1b808a1d350fe6f703a2df7652489e54ec85f7b1dfbab2404ff9',
      'graga_rana_azzurra_variante_corazzata':
          'f2454b19146c7ca88cc49d134094d49f7194a74e1ed095020f27958a0db9ca07',
      'habitat_caramella_medusa_di_confettura':
          '2a4f69f0cf45ac6a149f56313d19af503a8b5634363e8d36716bb470cf692c91',
      'habitat_diabolico_scarabeo_dei_contratti_ardenti':
          'da10abbdc7519c6fa41aa28ef831dd0efa396a0610243c00ba55da891dc0efa5',
      'habitat_foresta_elementale_lince_di_brina_verde_variante_corazzata':
          'dc17072a046fbd7bb7fa8fc395f8d4566d21c4430aa9a48991031c3f3c79c85a',
      'habitat_morti_falena_del_sudario_variante_veterana':
          'e31823b1f07b90262e0eed7e9b6d1a68983b1fe943329c6833bd3ce858adbb08',
      'habitat_nuvole_rocciose_cinghiale_delle_creste_volanti_variante_errante':
          '5fed06388c0d4661c0529fe87b8a43d69ff23404585310a0209274238935109e',
      'habitat_nuvole_rocciose_golem_delle_ghiaie_orbitanti':
          '7db5fcfc67d04e1976adb542837911dcdb7106641b7b4193cdd62c60c79e9888',
      'habitat_sotterraneo_regina_delle_miniere_mute_variante_rituale':
          '8ef480ac1c8bb9c846c475544e2cfcc7aad72692f98127c8c9665319e4710be0',
      'hero_path_diverso_ascia_variante_corazzata':
          '0ac2fa5da9e28af42719dc74fb41681d7f586e5b3ba3972621f172bcd27bf7be',
      'idra_base':
          '4ff7617c21317018a62bf2f0caee3d638170e0bc2c80054f1710e2ec27aab175',
      'lumin_gommoso_variante_corazzata':
          '86cb741bcc9421edf3cc2d8986026d97776693c4844d5928174fed44bd259a0e',
      'mostricciattolo_di_carta_variante_rituale':
          '42e30ba3b7ffc4d3e4e8894f48972588c653a60c3d05b92953e2dcd850bbdcf8',
      'piovra_succhiasangue':
          'd8ec42496f74445611fe3f4b92fc18438fab598aaeb3a53930e8882662b9ab74',
      'ragno_putrido':
          '9bbfee3e23a6625c0696b8c6a774f9ef2b0b34f6b2dcc26bd510aee5501e1615',
      'strana_presenza':
          '38ec346e995921582c6a6b18f6e8f0c3da358773fbe4e869be086f778d1ee4ac',
    };
    for (final MapEntry(key: id, value: digest) in expected.entries) {
      final monster = monsterBookEntryById(id)!;
      final theme = OculumMonsterTheme(
        monster,
        oculumMonsterColors(monster).first,
      );
      final suffix = switch (id) {
        'eiva_tassello_cupole' || 'ragno_putrido' => '20261117_ink_c',
        'hero_path_diverso_ascia_variante_corazzata' ||
        'lumin_gommoso_variante_corazzata' => '20261117_ink_b',
        'ciclo_mantide_vampa' ||
        'gigante_sabbia' ||
        'graga_rana_azzurra_variante_corazzata' ||
        'habitat_caramella_medusa_di_confettura' ||
        'habitat_diabolico_scarabeo_dei_contratti_ardenti' ||
        'habitat_foresta_elementale_lince_di_brina_verde_variante_corazzata' ||
        'habitat_morti_falena_del_sudario_variante_veterana' ||
        'habitat_sotterraneo_regina_delle_miniere_mute_variante_rituale' ||
        'mostricciattolo_di_carta_variante_rituale' ||
        'strana_presenza' => '20261116',
        _ => '20261116_riallineamento',
      };
      final asset =
          'assets/oculum/home_art_authored/theme_${id}_canon_$suffix.webp';
      expect(theme.illustration, asset, reason: id);
      final data = await rootBundle.load(asset);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final sha256 = SHA256Digest()
          .process(bytes)
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();
      expect(sha256, digest, reason: id);
    }
  });

  test(
    'newly illustrated variants keep their search and anatomy identities',
    () {
      for (final (id, name, aliases) in [
        (
          'aberrazione_oro_marmo_intermedia_solare',
          'Aurystride',
          ['Sunwalker', 'Auristride'],
        ),
        (
          'arpia_base_variante_veterana',
          'Ventyclaw',
          ['Arpia Veterana', 'Veteran Harpy', 'Venticlaw'],
        ),
        (
          'larva_lava_variante_corazzata',
          'Syntermoltys',
          ['Larva di Lava Corazzata', 'Armored Lava Larva', 'Syntermoltis'],
        ),
        (
          'golem_runico_variante_veterana',
          'Viscuprum',
          ['Golem Runico Veterano', 'Golem Runico Veterana', 'Vis Cuprum'],
        ),
        (
          'baby_rock_rhino_variante_veterana',
          'Visrhyno',
          ['Baby Rock Rhino Veterana', 'Veteran Baby Rock Rhino', 'Visrhino'],
        ),
        (
          oculumIntermediateRockRhynoId,
          'RockRhyno',
          ['Rock Rhino Intermedio', 'Intermediate Rock Rhino'],
        ),
      ]) {
        final entry = monsterBookEntryById(id)!;
        final currentName = _latestNameById[id] ?? name;
        expect([entry.nameIt, entry.nameEn], [currentName, currentName]);
        expect(oculumMonsterNameSearchAliases(entry), containsAll(aliases));
        for (final alias in aliases) {
          expect(oculumLookupMonsterId(alias).exact?.id, id, reason: alias);
        }
      }

      final arpia = monsterBookEntryById('arpia_base_variante_veterana')!;
      final arpiaParts = oculumMonsterPrecisionAnatomy(arpia);
      final wings = arpiaParts.where((part) => part['group'] == 'wings');
      expect(
        wings.map((part) => part['id']),
        unorderedEquals(['wings_1', 'wings_2']),
      );
      expect(wings.every((part) => part['weak'] == true), isTrue);
      expect(arpiaParts.where((part) => part['group'] == 'arms'), hasLength(2));

      final larva = monsterBookEntryById('larva_lava_variante_corazzata')!;
      final larvaParts = oculumMonsterPrecisionAnatomy(larva);
      expect(
        larvaParts.singleWhere((part) => part['id'] == 'joint')['weak'],
        isTrue,
      );

      const golemId = 'golem_runico_variante_veterana';
      final golemParts = oculumMonsterPrecisionAnatomy(
        monsterBookEntryById(golemId)!,
      );
      List<Object?> targetsAfterPlateDamage(int damage) {
        final exposed = oculumRunicGolemPlatesBroken({
          'anatomicalParts': {
            'parts': {
              'chest_plates': {'maximumHp': 10, 'damageTaken': damage},
            },
          },
        });
        return oculumReferenceCreaturePrecisionParts(
          golemParts,
          monsterId: golemId,
          runicGolemCoreExposed: exposed,
        ).map((part) => part['id']).toList();
      }

      expect(targetsAfterPlateDamage(9), contains('chest_plates'));
      expect(targetsAfterPlateDamage(9), isNot(contains('core')));
      expect(targetsAfterPlateDamage(10), contains('core'));
    },
  );

  testWidgets(
    'Home second option follows the current theme and preserves the manual image choice',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 1000),
      );
      final p = OculumPerformanceProbe(state);
      final tag = tester
          .widget<OculumNarrativeBackground>(
            find.byType(OculumNarrativeBackground),
          )
          .sheetId;
      state.updateOculumHomeUi(() {
        state.paginaCorrente = 17;
        state.homeArtworkChoice = 'amber_shore';
        state.homeArtworkFollowsTheme = false;
      });
      oculumSheetRelicSelections.value = {tag: 'hidenas'};
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(p.homeHeroArtwork(), 'assets/oculum/home_art/amber_shore.png');
      await tester.tap(find.text('Usa il tema attuale'));
      await tester.pump();
      expect(
        p.homeHeroArtwork(),
        'assets/oculum/theme_stories/webp/hidenas.webp',
      );
      expect(p.snapshot()['homeArtworkFollowsTheme'], isTrue);
      expect(state.homeArtworkChoice, 'amber_shore');
      oculumSheetRelicSelections.value = {tag: 'dedicated_indigo'};
      await tester.pump();
      expect(
        p.homeHeroArtwork(),
        'assets/oculum/theme_stories/webp/dedicated_indigo.webp',
      );
      await tester.tap(find.text('Immagini Home'));
      await tester.pump();
      expect(p.homeHeroArtwork(), 'assets/oculum/home_art/amber_shore.png');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
      oculumSheetRelicSelections.value = {};
    },
  );
  test(
    'power reading exposes only categories and failed reading only the dominant stat',
    () {
      expect(
        oculumScoutPower(3, [5, 2, 1, 0]),
        11,
      ); // Grade 0, HP multiplier 9 adds 0.
      expect(oculumScoutPower(4, [5, 2, 1, 0]), 13);
      expect(oculumScoutPowerBand(0, 0), 'equal');
      expect(oculumScoutPowerBand(0, 1), 'impossible');
      for (final (target, expected) in [
        (64, 'much_stronger'),
        (65, 'stronger'),
        (90, 'equal'),
        (110, 'equal'),
        (135, 'weaker'),
        (136, 'much_weaker'),
        (200, 'impossible'),
      ]) {
        expect(oculumScoutPowerBand(100, target), expected);
        expect(
          oculumPowerReadPhrases[expected],
          isNot(contains(RegExp(r'\d'))),
        );
      }
      for (final stat in ['resilienza', 'volonta', 'materia', 'oculum']) {
        expect(oculumScoutDominantStat({stat: 10}), stat);
        expect(
          oculumScoutFailurePhrase(stat),
          contains('non mi permette di percepire'),
        );
      }
      expect(oculumScoutUnlocksTheme(false, 0), isFalse);
      expect(oculumScoutUnlocksTheme(true, 89), isTrue);
      expect(oculumScoutUnlocksTheme(true, 90), isFalse);
    },
  );

  test(
    'every species and exact variant has a stable identity and valid weighted colours',
    () {
      final identifiers = <String>{};
      for (final monster in monsterBookEntries) {
        final colors = oculumMonsterColors(monster);
        expect(
          colors.fold<int>(0, (n, c) => n + c.weight),
          100,
          reason: monster.id,
        );
        for (final color in colors) {
          final theme = OculumMonsterTheme(monster, color);
          expect(identifiers.add(theme.id), isTrue, reason: theme.id);
          expect(oculumMonsterThemeById(theme.id)?.name, theme.name);
        }
        expect(
          oculumRollMonsterColor(monster, random: Random(42)).id,
          oculumRollMonsterColor(monster, random: Random(42)).id,
        );
      }
      for (final id in [
        'vendulo',
        'rascalume',
        'brumilio',
        'guravo',
        'mirula',
      ]) {
        final m = monsterById(id)!;
        expect(
          [
            'resilienza',
            'volonta',
            'materia',
            'oculum',
          ].fold<int>(0, (n, k) => n + (m.stats[k] ?? 0)),
          3,
        );
        expect(
          m.skillIds.length,
          14,
        ); // Two authored + twelve growth techniques.
        expect(m.dropIds, isNotEmpty);
        expect(m.planeIds.every(oculumMonsterHabitats.containsKey), isTrue);
      }
    },
  );

  testWidgets('full-page art leaves desktop and phone controls clickable', (
    tester,
  ) async {
    final previous = oculumSheetRelicSelections.value;
    addTearDown(() => oculumSheetRelicSelections.value = previous);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final size in [const Size(390, 844), const Size(1440, 900)]) {
      tester.view.physicalSize = size;
      var taps = 0;
      oculumSheetRelicSelections.value = {'preview': 'hidenas'};
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: const [
              OculumGothOrnaments(
                family: OculumGothFamily.forged,
                ink: Colors.white,
                accent: Colors.amber,
                opacity: .3,
                themeId: 'classic_reliquary',
              ),
            ],
          ),
          home: Scaffold(
            body: Stack(
              children: [
                const Positioned.fill(
                  child: OculumNarrativeBackground(sheetId: 'preview'),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Vita 100/100 · Oculum 10/10'),
                      FilledButton(
                        onPressed: () => taps++,
                        child: const Text('Attacco'),
                      ),
                      OutlinedButton(
                        onPressed: () => taps++,
                        child: const Text('Difesa'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      for (final id in oculumStoryThemePacks.keys) {
        oculumSheetRelicSelections.value = {'preview': id};
        await tester.pump();
        expect(
          find.byKey(ValueKey('narrative-background-$id')),
          findsOneWidget,
        );
        await tester.tap(find.text('Attacco'));
        await tester.tap(find.text('Difesa'));
      }
      expect(taps, oculumStoryThemePacks.length * 2);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'appearance survives JSON and exact-variant unlocks stay separate and per sheet',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 1000),
      );
      final p = OculumPerformanceProbe(state);
      state.datiCaricati = false;
      final sheet = <String, dynamic>{
        'sheetTag': 'AppearanceOcu:3690AAAA',
        'monsterBookSourceId': 'nuvi',
      };
      p.restoreCreatureAppearance(sheet);
      final appearance = Map<String, dynamic>.from(sheet['monsterAppearance']);
      p.restoreCreatureAppearance(sheet);
      expect(sheet['monsterAppearance'], appearance);
      oculumSheetRelicSelections.value = {'AppearanceOcu:3690AAAA': 'hidenas'};
      expect(
        oculumThemePresentationForSheet('AppearanceOcu:3690AAAA').artPackId,
        'hidenas',
      );
      expect(
        oculumThemePresentationForSheet('another-sheet').artPackId,
        isNot('hidenas'),
      );
      p.unlockCreatureTheme('uomo_maschera', page: true);
      expect(p.creatureKnowledge('uomo_maschera')?['themeUnlocked'], isTrue);
      expect(
        p.creatureKnowledge('uomo_maschera_viola')?['themeUnlocked'],
        isNot(isTrue),
      );
      p.unlockCreatureTheme('uomo_maschera_viola', theme: true);
      p.unlockCreatureTheme('uomo_maschera_viola');
      expect(
        p.creatureKnowledge('uomo_maschera_viola')?['themeUnlocked'],
        isTrue,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
      oculumSheetRelicSelections.value = {};
    },
  );
}
