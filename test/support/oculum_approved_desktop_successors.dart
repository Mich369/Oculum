import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/digests/sha256.dart';

// Explicit successors to the October/early-November plates, approved on
// 14-18 November. Freeze their paths and hashes here: historical receipts
// still verify the originals, while this fixture checks the later choices.
// Ensypuppet C1 has its own violet-eye correction receipt; its hash is not
// substituted for the immutable C vote.
const approvedDesktopSuccessors = <String, ({String asset, String sha256})>{
  'air_navigator': (
    asset:
        'assets/oculum/home_art_authored/theme_air_navigator_canon_20261115.webp',
    sha256: '4d89e371fb9d561af03d4dc9e77f339546c42c72b408c2b56686ae51789740c8',
  ),
  'armadillo_cristallo': (
    asset:
        'assets/oculum/home_art_authored/theme_armadillo_cristallo_canon_20261115.webp',
    sha256: 'ec628de4f7ef5837df9687a2b88cbf4dbea8ed1c8dd8916e887bc8470456e032',
  ),
  'armadillo_legno': (
    asset:
        'assets/oculum/home_art_authored/theme_armadillo_legno_canon_20261115.webp',
    sha256: '255d69b44018498b15c70a169efe650e1cc854ab5dcd855ae07c2f7c41da9eaa',
  ),
  'armadillo_sabbia': (
    asset:
        'assets/oculum/home_art_authored/theme_armadillo_sabbia_canon_20261116_riallineamento.webp',
    sha256: '034fe6c89b41718b3870978341d58b2df1693abf9ea32d5279c53dc3bc11799c',
  ),
  'armaiolo_della_fila_lunga_variante_rituale': (
    asset:
        'assets/oculum/home_art_authored/theme_armaiolo_della_fila_lunga_variante_rituale_canon_20261115.webp',
    sha256: 'e576f17257a955cb850e738e543c0ba87b726757eac82eda220ff8b612ee3619',
  ),
  'baby_forest_demon': (
    asset:
        'assets/oculum/home_art_authored/theme_baby_forest_demon_canon_20261115.webp',
    sha256: '6d43a9a09073a7b678e0cde0c83b88b778d5b5ffdb46ac69410bb57c3ed15ffa',
  ),
  'baby_rock_rhino': (
    asset:
        'assets/oculum/home_art_authored/theme_baby_rock_rhino_canon_20261115.webp',
    sha256: '8b05bdbf885b97720674876e10e2ae8cecfc188eebbb15776957587bfb770e0c',
  ),
  'baby_rock_rhino_variante_veterana': (
    asset:
        'assets/oculum/home_art_authored/theme_baby_rock_rhino_variante_veterana_canon_20261115.webp',
    sha256: '41d2bdf0137f83eed8fc40f93274d7c4359975ea97fd33b2a584f25e1e0acfd3',
  ),
  'bambola_vapium_variante_veterana': (
    asset:
        'assets/oculum/home_art_authored/theme_bambola_vapium_variante_veterana_canon_20261115.webp',
    sha256: 'cdce4b9d8f5563a67179166275a4203fe4c1779c64162b599d9886952e493db7',
  ),
  'bandito_base_variante_veterana': (
    asset:
        'assets/oculum/home_art_authored/theme_bandito_base_variante_veterana_canon_20261115.webp',
    sha256: '1c3f4645f7a7806843eebad88daa477554c70258f685081e3b081d95e7686091',
  ),
  'bunnys': (
    asset: 'assets/oculum/home_art_authored/theme_bunnys_canon_20261115.webp',
    sha256: 'ebac3698aea47759e2f251a380e17c3a49f27bf96beda2647c27e46301063d90',
  ),
  'ciclo_cervo_radure_miti': (
    asset:
        'assets/oculum/home_art_authored/theme_ciclo_cervo_radure_miti_canon_20261116.webp',
    sha256: '146a0100f6e1071d1a6e1e383763955555d1420a082f5933829efba5dee59ff6',
  ),
  'ciclo_rospo_gronde_marce': (
    asset:
        'assets/oculum/home_art_authored/theme_ciclo_rospo_gronde_marce_canon_20261116.webp',
    sha256: 'ea557ae7ea23b2684bf646d1eb899465be304eb256593656f66481ba24f7c799',
  ),
  'ciclo_scarabeo_sigillo_ardente': (
    asset:
        'assets/oculum/home_art_authored/theme_ciclo_scarabeo_sigillo_ardente_canon_20261116.webp',
    sha256: '28fedddce20a58abf32171ff7a62c36a3bf81b7789cae0add34e7206b535e321',
  ),
  'ciclope_del_fato': (
    asset:
        'assets/oculum/home_art_authored/theme_ciclope_del_fato_canon_20261115.webp',
    sha256: 'd92ca7f189ce50e78dbeebe6a573bf20b826a0d066ee27bd77006c6cdc01df36',
  ),
  'demone_glaciale_minore': (
    asset:
        'assets/oculum/home_art_authored/theme_demone_glaciale_minore_canon_20261115.webp',
    sha256: 'a2e323e0e063fd07f82eaca443bbc108453368db8de3d656d9a1f3f825c79e8b',
  ),
  'habitat_foresta_elementale_antico_dei_venti_elementi': (
    asset:
        'assets/oculum/home_art_authored/theme_habitat_foresta_elementale_antico_dei_venti_elementi_canon_20261117.webp',
    sha256: 'd0621f4c71766aa9f2880386cd421934038013b030c13a67a98a3547bb5654a4',
  ),
  'lupo_infernale_del_ghiaccio': (
    asset:
        'assets/oculum/home_art_authored/theme_lupo_infernale_del_ghiaccio_canon_20261115.webp',
    sha256: '506cd23d6479a7a52628bbe05ff6faeff38fc822aab443bb30abd809fd63da56',
  ),
  'manichino_spada': (
    asset:
        'assets/oculum/home_art_authored/theme_manichino_spada_canon_20261118_v2.webp',
    sha256: '710886acfde3584d91c58f76acb00c8654ba1b6c52d54fbb5a32da039b3bc115',
  ),
  'strana_presenza': (
    asset:
        'assets/oculum/home_art_authored/theme_strana_presenza_canon_20261116.webp',
    sha256: '38ec346e995921582c6a6b18f6e8f0c3da358773fbe4e869be086f778d1ee4ac',
  ),
  'teschio_quattro_lame': (
    asset:
        'assets/oculum/home_art_authored/theme_teschio_quattro_lame_canon_20261118.webp',
    sha256: 'c4008d06fe6da4c06d99fa1621a075992742d088640f1023eeeb308136f4a23f',
  ),
};

Future<void> expectApprovedDesktopSuccessor(String id) async {
  final successor = approvedDesktopSuccessors[id];
  expect(successor, isNotNull, reason: id);
  final asset = successor!.asset;
  final bytes = File(asset).readAsBytesSync();
  final digest = SHA256Digest()
      .process(bytes)
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  expect(digest, successor.sha256, reason: id);
  final bundled = await rootBundle.load(asset);
  final bundledDigest = SHA256Digest()
      .process(
        bundled.buffer.asUint8List(
          bundled.offsetInBytes,
          bundled.lengthInBytes,
        ),
      )
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  expect(bundledDigest, successor.sha256, reason: id);
}
