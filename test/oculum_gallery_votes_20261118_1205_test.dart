import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart' show oculumLookupMonsterId;
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_monster_theme.dart';
import 'package:pointycastle/digests/sha256.dart';

typedef _GalleryVote = ({
  String id,
  String name,
  String previousName,
  String slot,
  String sha256,
});

// Explicit desktop/name choices received on 18 November. Kept independent of
// mutable output galleries, pending cleanup receipts and local Downloads.
const _votes = <_GalleryVote>[
  (
    id: 'habitat_caramella_rospo_di_crema_variante_veterana',
    name: 'Dulcycrust',
    previousName: 'Rospo di crema Veterana',
    slot: 'B',
    sha256: 'cae32ed87f422877cd38435dc1746f9d6f9bf240abc630b2cdd32bc3cf8cb5d5',
  ),
  (
    id: 'habitat_oblio_divoratore_degli_ultimi_nomi_variante_errante',
    name: 'Oblyravyn',
    previousName: 'Divoratore degli ultimi nomi Errante',
    slot: 'B',
    sha256: '4bac10f469fa6550301556bde6d845f35a4cb320d4917242ab09da8a806d2488',
  ),
  (
    id: 'mantide_sanguescatto',
    name: 'Vyridblade',
    previousName: 'Mantide Sanguescatto',
    slot: 'G',
    sha256: '129c32a1f4ca3add0efef52423ca0f5eddf881dca1f23b02ba081a5270ee9f62',
  ),
  (
    id: 'teschio_quattro_lame',
    name: 'Quadrilame',
    previousName: 'Teschio Quattro Lame',
    slot: 'G',
    sha256: 'c4008d06fe6da4c06d99fa1621a075992742d088640f1023eeeb308136f4a23f',
  ),
  (
    id: 'habitat_caramella_falena_di_zucchero_filato_variante_errante',
    name: 'Vagafloss',
    previousName: 'Falena di zucchero filato Errante',
    slot: 'A',
    sha256: 'ab84c937c7d093f718738c7e5dd91643f1ab93a15dc0195817b4297130e4a410',
  ),
  (
    id: 'habitat_isole_razza_del_cielo_basso_variante_corazzata',
    name: 'Ventyscute',
    previousName: 'Razza del cielo basso Corazzata',
    slot: 'G',
    sha256: '45f5bb509b83b02f4df0710ade2f26cbec4d7a20493622d96139f1ea4b0fb0bb',
  ),
  (
    id: 'base_postea_02',
    name: 'Runycrick',
    previousName: 'Grillo a Molla',
    slot: 'G',
    sha256: 'c66fe7cef9d8d70242123121ba09ff86fa03735b61bd863b37d59804f0b6ec9d',
  ),
  (
    id: 'weak_horror_mastino',
    name: 'Cynyscarn',
    previousName: 'Mastino della Cripta',
    slot: 'F',
    sha256: 'dbd3f92f059e1ee282e99ae568cb829149c81d0441ab8316221d87bf0ba75424',
  ),
  (
    id: 'pellegrino_senza_volto_variante_errante',
    name: 'Senza Volto Errante',
    previousName: 'Pellegrino Senza Volto Errante',
    slot: 'H',
    sha256: 'f55eb4c59a32831650839fd2ec953fd9bb2f682bc683b7ab6fb048f4aae1aa88',
  ),
  (
    id: 'manichino_spada',
    name: 'Ensypuppet',
    previousName: 'Manichino della Spada',
    slot: 'C',
    sha256: '4882c529f208f7d7312879bdb8a2479438c8e00301902a6e9bf14c8fb9a5260d',
  ),
];

// Later name revisions leave the original plate/name votes above intact.
const _latestNameById = <String, String>{
  'habitat_caramella_rospo_di_crema_variante_veterana': 'Dulcryn',
  'habitat_oblio_divoratore_degli_ultimi_nomi_variante_errante': 'Oblyraven',
  'mantide_sanguescatto': 'Vyridryx',
  'teschio_quattro_lame': 'Quadryth',
  'habitat_caramella_falena_di_zucchero_filato_variante_errante': 'Vagaflyr',
  'habitat_isole_razza_del_cielo_basso_variante_corazzata': 'Ventryss',
  'base_postea_02': 'Runykryx',
  'weak_horror_mastino': 'Cynyskar',
  'pellegrino_senza_volto_variante_errante': 'Senvyrel',
  'manichino_spada': 'Ensypeth',
};

// The user then requested only the sword eye to return to violet. The original
// C vote above is immutable; C1 is a separately receipted ImageGen derivative.
const _ensypuppetCorrectedSha256 =
    '710886acfde3584d91c58f76acb00c8654ba1b6c52d54fbb5a32da039b3bc115';

String _runtimeAsset(_GalleryVote vote) => vote.id == 'manichino_spada'
    ? 'assets/oculum/home_art_authored/theme_manichino_spada_canon_20261118_v2.webp'
    : 'assets/oculum/home_art_authored/theme_${vote.id}_canon_20261118.webp';

Future<String> _assetDigest(String asset) async {
  final data = await rootBundle.load(asset);
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  return SHA256Digest()
      .process(bytes)
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('All ten desktop canons load the exact user-selected bytes', (
    tester,
  ) async {
    expect(_votes.map((vote) => vote.id).toSet(), hasLength(10));
    for (final vote in _votes) {
      final asset = _runtimeAsset(vote);
      expect(
        OculumMonsterTheme.desktopIllustrationForId(vote.id),
        asset,
        reason: '${vote.id} · ${vote.slot}',
      );
      expect(
        await _assetDigest(asset),
        vote.id == 'manichino_spada' ? _ensypuppetCorrectedSha256 : vote.sha256,
        reason: '${vote.id} · ${vote.slot}',
      );
      if (vote.id == 'manichino_spada') {
        expect(
          await _assetDigest(
            'assets/oculum/home_art_authored/theme_manichino_spada_canon_20261118.webp',
          ),
          vote.sha256,
          reason:
              'The original C remains preserved after the requested correction',
        );
      }
      final theme = OculumMonsterTheme(
        monsterById(vote.id)!,
        const OculumCreatureColor(
          'canonical',
          'Canonical',
          Color(0xff777777),
          100,
        ),
      );
      expect(theme.illustration, asset);
      expect(theme.preserveIllustrationFraming, isTrue);
    }
  });

  test('Exact IDs use revised names and retain historical vote aliases', () {
    for (final vote in _votes) {
      final monster = monsterById(vote.id)!;
      expect(monster.id, vote.id);
      final currentName = _latestNameById[vote.id]!;
      expect(monster.nameIt, currentName);
      expect(monster.nameEn, currentName);
      expect(oculumLookupMonsterId(vote.name).exact?.id, vote.id);
      final aliases = oculumMonsterNameSearchAliases(monster);
      expect(aliases, containsAll([currentName, vote.name, vote.previousName]));
      expect(aliases, contains(monster.speciesNameIt));
    }
    expect(
      monsterById('pellegrino_senza_volto')!.nameIt,
      'Pellegrino Senza Volto',
    );
  });

  test('Saved custom names and descriptions remain authoritative', () {
    addTearDown(resetMonsterBookEntries);
    for (final vote in _votes) {
      final custom = monsterById(vote.id)!.copyWith(
        nameIt: 'Nome personale ${vote.id}',
        nameEn: 'Custom ${vote.id}',
        descIt: 'Descrizione personale ${vote.id}',
        descEn: 'Custom description ${vote.id}',
      );
      final before = custom.toJson();
      configureMonsterBookEntries(customEntries: [custom]);
      final loaded = monsterById(vote.id)!;
      expect(loaded.toJson(), before, reason: vote.id);
      final aliases = oculumMonsterNameSearchAliases(loaded);
      expect(aliases, contains(vote.name));
      expect(aliases, contains(vote.previousName));
      resetMonsterBookEntries();
    }
  });
}
