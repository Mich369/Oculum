import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_monster_theme.dart';
import 'package:oculum/widgets/oculum_theme_relic.dart';
import 'package:pointycastle/digests/sha256.dart';

const _picks = <({String monster, String? skin, String path, String sha})>[
  (
    monster: 'velario_uncinato',
    skin: null,
    path:
        'assets/oculum/home_art_authored/theme_velario_uncinato_ink_20261128.webp',
    sha: '61f17686f247705ee97efb39a1ca0179355123a12adc3bfa62730b7c758cd263',
  ),
  (
    monster: 'velario_uncinato',
    skin: 'ink_verderame',
    path:
        'assets/oculum/home_art_authored/theme_velario_uncinato_alt_verderame_ink_20261128.webp',
    sha: '77f93a6954b16191777e36d593695a06a58fba2ef89160293b9a6da6530abc75',
  ),
  (
    monster: 'occhio_quadrilama',
    skin: null,
    path:
        'assets/oculum/home_art_authored/theme_occhio_quadrilama_ink_20261128.webp',
    sha: '144f7cb9106ab870e0d2c5fd6c1fc5ca36020977ff3ebd1132e5d5d480a8d074',
  ),
  (
    monster: 'occhio_quadrilama',
    skin: 'ink_verderame',
    path:
        'assets/oculum/home_art_authored/theme_occhio_quadrilama_alt_verderame_ink_20261128.webp',
    sha: '44f97a79a2eb63270bee127a8a9ae1d44806e2fc9599376208265fc962865fb4',
  ),
  (
    monster: 'occhio_quadrilama',
    skin: 'ink_perla',
    path:
        'assets/oculum/home_art_authored/theme_occhio_quadrilama_alt_perla_ink_20261128.webp',
    sha: '1676697253173b4369e207d2744389cbbc4bd38b7f49d486de7b76fbd1fcc57b',
  ),
  (
    monster: 'habitat_oblio_maschera_della_memoria_spenta',
    skin: null,
    path:
        'assets/oculum/home_art_authored/theme_habitat_oblio_maschera_della_memoria_spenta_ink_20261128.webp',
    sha: 'b35f38e552732acf4fb076910b806d22e8ee581533606fbc017c62f43d7557a2',
  ),
  (
    monster: 'lavastrello',
    skin: null,
    path: 'assets/oculum/home_art_authored/theme_lavastrello_ink_20261128.webp',
    sha: '9a742f98072b914524135c1d5a9aaad48c8ac3f95ec3b8d95132445aad96c080',
  ),
  (
    monster: 'thunderbird',
    skin: null,
    path: 'assets/oculum/home_art_authored/theme_thunderbird_ink_20261128.webp',
    sha: 'ebc657f024aab3e22ed36de95560b52ca88d3fdae4e223e10a21d59549a8425b',
  ),
  (
    monster: 'nuvola_in_bottiglia',
    skin: null,
    path:
        'assets/oculum/home_art_authored/theme_nuvola_in_bottiglia_ink_20261128.webp',
    sha: '1bd44a56e80d6ef112730cc5ba60c659855a9a9ba0da88c5d650ac5f703f678f',
  ),
  (
    monster: 'il_doppione',
    skin: null,
    path: 'assets/oculum/home_art_authored/theme_il_doppione_ink_20261128.webp',
    sha: 'cf434bd288756a705089db7bd353750366345106d62f674e599047a373ecf461',
  ),
  (
    monster: 'mezzo_demone_cosciente',
    skin: null,
    path:
        'assets/oculum/home_art_authored/theme_mezzo_demone_cosciente_ink_20261128.webp',
    sha: 'b1890fade7e09a384b1cf232cbdee21e2226a3c82ffff5189de4fc16ef6cb819',
  ),
  (
    monster: 'mostro_lunare_demoniaco',
    skin: null,
    path:
        'assets/oculum/home_art_authored/theme_mostro_lunare_demoniaco_ink_20261128.webp',
    sha: 'bf0460bfebe70415a893898c0effa077ab98c862f090641cc0d891ae00ce4f12',
  ),
];
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('creatures resolve their exact approved desktop art', () async {
    for (final pick in _picks) {
      final entry = monsterBookEntryById(pick.monster)!;
      final skin = pick.skin;
      final theme = skin == null
          ? oculumCreatureRecognitionTheme(entry)
          : oculumMonsterThemeById('monster/${pick.monster}/$skin')!;
      expect(theme.monster, same(entry));
      expect(theme.illustration, pick.path);
      final data = await rootBundle.load(pick.path);
      final digest = SHA256Digest()
          .process(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          )
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();
      expect(digest, pick.sha);
      if (skin != null) {
        expect(theme.color.weight, 0);
        expect(
          theme.relicIllustration,
          oculumCreatureRecognitionTheme(entry).relicIllustration,
        );
      }
    }
  });

  test('explicit skins keep the base appearance roll and unlock rules', () {
    const id = 'occhio_quadrilama';
    final creature = monsterBookEntryById(id)!;
    final colors = oculumMonsterColors(creature);
    expect(colors.map((color) => color.id), [
      'naturale',
      'scuro',
      'pallido',
      'ink_verderame',
      'ink_perla',
    ]);
    expect(colors.map((color) => color.weight), [65, 25, 10, 0, 0]);
    final random = Random(2811);
    for (var i = 0; i < 150; i++) {
      expect(
        oculumRollMonsterColor(creature, random: random).weight,
        isPositive,
      );
    }
    const alt = 'monster/occhio_quadrilama/ink_perla';
    const base = 'monster/occhio_quadrilama/naturale';
    final unlocked = oculumMonsterThemeUnlocks.value;
    final sheets = oculumSheetMonsterThemes.value;
    addTearDown(() {
      oculumMonsterThemeUnlocks.value = unlocked;
      oculumSheetMonsterThemes.value = sheets;
    });
    oculumMonsterThemeUnlocks.value = {};
    oculumSheetMonsterThemes.value = {'own': base};
    expect(oculumCanSelectRelic(alt, sheetId: 'other'), isFalse);
    expect(oculumCanSelectRelic(alt, sheetId: 'own'), isTrue);
    oculumMonsterThemeUnlocks.value = {id};
    expect(oculumCanSelectRelic(alt, sheetId: 'other'), isTrue);
  });
}
