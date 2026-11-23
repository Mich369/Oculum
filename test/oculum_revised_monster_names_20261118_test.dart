import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart' show oculumLookupMonsterId;
import 'package:oculum/game/oculum_name_search.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

// Confirmed 18 and 19 November revisions. These expectations do not read the
// mutable output gallery or rewrite the earlier image/name vote receipts.
const _revisions = <String, ({String name, String previousName})>{
  'base_postea_03': (name: 'Talparel', previousName: 'Talpabor'),
  'base_postea_04': (name: 'Gecuprkren', previousName: 'Gecko di Rame'),
  'habitat_postea_mantide_a_pistoni_variante_rituale': (
    name: 'Cyrketh',
    previousName: 'Miruscyrus',
  ),
  'affogato_faldavela_variante_ghiaccio': (
    name: 'Faldelryn',
    previousName: 'Faldavela di Gelo',
  ),
  'affogato_razziatore_delle_fronde_variante_veleno': (
    name: 'Toxyriel',
    previousName: 'Toxifern',
  ),
  'affogato_sentinella_di_basalto_variante_fulmine': (
    name: 'Fulgeryx',
    previousName: 'Fulgheryft',
  ),
  'base_affogato_03': (name: 'Ruinyryx', previousName: 'Razza delle Rovine'),
  'base_sotterraneo_05': (
    name: 'Talpobreth',
    previousName: 'Talpa d’Ossidiana',
  ),
  'base_sotterraneo_07': (name: 'Lapyrith', previousName: 'Lapypede'),
  'eiva_razza_cisterne_variante_roccia': (
    name: 'Tegylryn',
    previousName: 'Tegylfin',
  ),
  'habitat_nuvole_rocciose_medusa_dei_fulmini_lenti': (
    name: 'Lapysrieth',
    previousName: 'Lapysurge',
  ),
  'ragno_putrido_variante_corazzata': (
    name: 'Pustryth',
    previousName: 'Pustrysilk',
  ),
  'base_foresta_05': (name: 'Florel', previousName: 'Florycoil'),
  'piovra_succhiasangue': (name: 'Cruoryn', previousName: 'Octocruor'),
  'base_ghiaccio_05': (name: 'Nyveth', previousName: 'Nyvowl'),
  'idra_base': (name: 'Tryjyr', previousName: 'Tryjaw'),
  'habitat_nuvole_rocciose_golem_delle_ghiaie_orbitanti': (
    name: 'Lapyrel',
    previousName: 'Lapyorbit',
  ),
  'ciclo_cervo_radure_miti': (name: 'Cervyss', previousName: 'Cervydew'),
  'ciclo_falena_delirio': (name: 'Delyr', previousName: 'Delyrmoth'),
  'mosca_campana_variante_veterana': (
    name: 'Tynbell',
    previousName: 'Vistynbell',
  ),
  'base_caramella_05': (name: 'Mallyr', previousName: 'Rospo Marshmallow'),
  'gatto_ciotola_variante_corazzata': (
    name: 'Bowlyx',
    previousName: 'Bowlyward',
  ),
  'habitat_caramella_volpe_di_gelatina_variante_veterana': (
    name: 'Gelyss',
    previousName: 'Visgel',
  ),
  'affogato_granchio_delle_cappelle_variante_ghiaccio': (
    name: 'Gelycryn',
    previousName: 'Gelycarapace',
  ),
  'eiva_serracapo_mosaici_variante_fulmine': (
    name: 'Cuproth',
    previousName: 'Cuprosajur',
  ),
  'habitat_foresta_elementale_rospo_delle_spore_sonore_variante_veterana': (
    name: 'Sporym',
    previousName: 'Visporym',
  ),
  'habitat_vero_inferno_segugio_delle_nove_fornaci': (
    name: 'Clibryx',
    previousName: 'Clibanfang',
  ),
  'hero_path_diverso_lancia_variante_errante': (
    name: 'Vagryss',
    previousName: 'Vaguspike',
  ),
  'uomo_maschera_rossa': (name: 'Voultyr', previousName: 'Voultyfist'),
  'habitat_diabolico_re_dei_patti_consumati_variante_errante': (
    name: 'Foedryn',
    previousName: 'Foedryx',
  ),
  'habitat_postea_serpente_di_cavi_variante_veterana': (
    name: 'Funyrn',
    previousName: 'Visfunycord',
  ),
  'base_postea_02': (name: 'Runykryx', previousName: 'Runycrick'),
  'habitat_caramella_rospo_di_crema_variante_veterana': (
    name: 'Dulcryn',
    previousName: 'Dulcycrust',
  ),
  'manichino_spada': (name: 'Ensypeth', previousName: 'Ensypuppet'),
  'habitat_caramella_falena_di_zucchero_filato_variante_errante': (
    name: 'Vagaflyr',
    previousName: 'Vagafloss',
  ),
  'habitat_isole_razza_del_cielo_basso_variante_corazzata': (
    name: 'Ventryss',
    previousName: 'Ventyscute',
  ),
  'pellegrino_senza_volto_variante_errante': (
    name: 'Senvyrel',
    previousName: 'Senza Volto Errante',
  ),
  'teschio_quattro_lame': (name: 'Quadryth', previousName: 'Quadrilame'),
  'weak_horror_mastino': (name: 'Cynyskar', previousName: 'Cynyscarn'),
  'habitat_oblio_divoratore_degli_ultimi_nomi_variante_errante': (
    name: 'Oblyraven',
    previousName: 'Oblyravyn',
  ),
  'mantide_sanguescatto': (name: 'Vyridryx', previousName: 'Vyridblade'),
  'gabli_caverne': (name: 'Gablyn', previousName: 'Gabli delle Caverne'),
  'habitat_diabolico_re_dei_patti_consumati': (
    name: 'Scoryth',
    previousName: 'Scoryrex',
  ),
  'habitat_morti_regina_delle_cripte_sommerse_variante_corazzata': (
    name: 'Funerys',
    previousName: 'Funeryshroud',
  ),
  'habitat_isole_vipera_dei_parafulmini_variante_rituale': (
    name: 'Fulgryn',
    previousName: 'Mirusfulgur',
  ),
  'habitat_nuvole_rocciose_serpente_del_cumulonembo_variante_corazzata': (
    name: 'Nymboryth',
    previousName: 'Nymboscyte',
  ),
  'habitat_oblio_ragno_delle_ombre_cancellate_variante_veterana': (
    name: 'Abrasyrel',
    previousName: 'Abrasyweb',
  ),
  'habitat_vero_inferno_custode_del_cancello_senza_ritorno_variante_rituale': (
    name: 'Claustyr',
    previousName: 'Mirusclaust',
  ),
  'habitat_sotterraneo_talpa_dei_cristalli_ciechi': (
    name: 'Vibryn',
    previousName: 'Vibryclaw',
  ),
  'habitat_shadow_hell_regina_dello_specchio_dell_oblio_variante_veterana': (
    name: 'Umbreth',
    previousName: 'Umbracrown',
  ),
  'eiva_tassello_cupole': (name: 'Tessyrel', previousName: 'Tessyfin'),
  'habitat_caramella_vespa_di_miele_scuro': (
    name: 'Melyriel',
    previousName: 'Melysting',
  ),
  'habitat_foresta_elementale_salamandra_delle_felci_ardenti': (
    name: 'Cinderel',
    previousName: 'Cindercoil',
  ),
  'habitat_ghiaccio_drago_della_notte_polare_variante_veterana': (
    name: 'Polarith',
    previousName: 'Polaryscale',
  ),
  'habitat_isole_granchio_delle_navi_aeree_variante_corazzata': (
    name: 'Navyreth',
    previousName: 'Navysnare',
  ),
  'habitat_nuvole_rocciose_riccio_delle_saette_corte_variante_corazzata': (
    name: 'Echynrel',
    previousName: 'Echynspark',
  ),
  'habitat_nuvole_rocciose_rospo_della_pioggia_obliqua': (
    name: 'Imbryn',
    previousName: 'Imbrywing',
  ),
  'hero_path_diverso_ascia_variante_corazzata': (
    name: 'Foryan',
    previousName: 'Forisplit',
  ),
  'lumin_gommoso_variante_corazzata': (
    name: 'Lumlorel',
    previousName: 'Lumin Gommoso Corazzata',
  ),
  'ragno_putrido': (name: 'Venereth', previousName: 'Venemuk'),
  'affogato_palmatore_dei_nastri_variante_veleno': (
    name: 'Toxivryth',
    previousName: 'Toxyvitta',
  ),
  'base_mezzano_04': (name: 'Fimbrarel', previousName: 'Fimbraglow'),
};

String _normalize(String value) => value.trim().toLowerCase();

void main() {
  tearDown(resetMonsterBookEntries);

  test('All 62 revised names resolve existing stable catalogue IDs', () {
    expect(_revisions, hasLength(62));
    for (final id in _revisions.keys) {
      expect(monsterBookEntryById(id), isNotNull, reason: id);
      expect(
        defaultMonsterBookEntries.any((entry) => entry.id == id),
        isTrue,
        reason: '$id remains an active catalogue entry',
      );
    }
  });

  test('All 62 preferred names and historical aliases remain searchable', () {
    for (final revision in _revisions.entries) {
      final monster = monsterBookEntryById(revision.key)!;
      expect(monster.nameIt, revision.value.name, reason: revision.key);
      expect(monster.nameEn, revision.value.name, reason: revision.key);
      final aliases = oculumMonsterNameSearchAliases(monster);
      expect(
        aliases,
        containsAll({
          revision.value.name,
          revision.value.previousName,
          monster.speciesNameIt,
          monster.speciesNameEn,
        }),
        reason: revision.key,
      );
      for (final name in [revision.value.name, revision.value.previousName]) {
        expect(
          oculumLookupMonsterId(name).exact?.id,
          revision.key,
          reason: 'Global exact lookup of $name',
        );
        expect(
          oculumMonsterNameMatchScore(
            monster,
            OculumNameQuery(_normalize(name)),
            normalize: _normalize,
          ),
          1000,
          reason: '${revision.key}: exact search for $name',
        );
      }
    }
  });

  test('Custom labels and JSON remain authoritative for all revised IDs', () {
    for (final revision in _revisions.entries) {
      final stock = monsterBookEntryById(revision.key)!;
      final custom = stock.copyWith(
        nameIt: 'Nome personale ${revision.key}',
        nameEn: 'Custom name ${revision.key}',
        descIt: 'Descrizione personale',
        descEn: 'Custom description',
        stats: {...stock.stats, 'res': 71},
        encounterRules: {...stock.encounterRules, 'customQaValue': 47},
      );
      final before = custom.toJson();
      final restored = MonsterBookEntry.fromJson(before);
      configureMonsterBookEntries(customEntries: [restored]);
      final loaded = monsterBookEntryById(revision.key)!;
      expect(loaded.toJson(), before, reason: revision.key);
      final aliases = oculumMonsterNameSearchAliases(loaded);
      expect(
        aliases,
        containsAll([
          custom.nameIt,
          custom.nameEn,
          revision.value.name,
          revision.value.previousName,
        ]),
        reason: revision.key,
      );
      resetMonsterBookEntries();
    }
  });

  test('A matching spelling never changes a different custom species ID', () {
    for (final revision in _revisions.entries) {
      final other = monsterBookEntryById(revision.key)!.copyWith(
        id: 'qa_other_${revision.key}',
        nameIt: revision.value.previousName,
        nameEn: revision.value.previousName,
        encounterRules: const {},
      );
      configureMonsterBookEntries(customEntries: [other]);
      final loaded = monsterBookEntryById(other.id)!;
      expect(loaded.nameIt, revision.value.previousName);
      expect(loaded.nameEn, revision.value.previousName);
      expect(loaded.toJson(), other.toJson());
      expect(
        oculumLookupMonsterId(revision.value.previousName).exact?.id,
        other.id,
        reason: 'Custom display label retains priority',
      );
      expect(
        oculumMonsterNameSearchAliases(loaded),
        isNot(contains(revision.value.name)),
        reason: revision.key,
      );
      resetMonsterBookEntries();
    }
  });
}
