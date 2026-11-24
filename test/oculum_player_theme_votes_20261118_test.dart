import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/widgets/oculum_approved_theme_art.dart';
import 'package:oculum/widgets/oculum_custom_theme.dart';
import 'package:oculum/widgets/oculum_goth_ornaments.dart';
import 'package:oculum/widgets/oculum_narrative_background.dart';
import 'package:oculum/widgets/oculum_theme_asset_packs.dart';
import 'package:oculum/widgets/oculum_theme_presentation.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'oculum_theme_effects_portrait_test.dart' as fixtures;

typedef _Vote = ({
  String id,
  String slot,
  String sha256,
  String originalSha256,
});

const _angelicoPhone =
    'assets/oculum/theme_stories/webp/element_pack_angelico_mobile_canon_20261124_f_b17b8d78.webp';

// Frozen user choices received on 18 November, independent of local gallery
// files, Downloads or generated manifests. Each prior source stays intact.
const _votes = <_Vote>[
  (
    id: 'abyssal_tide',
    slot: 'D',
    sha256: 'dc86d3759b13adfae5da531b0d1e61444c77c44b14a78dff60c8c33d0a7a0a7a',
    originalSha256:
        '108b0699b3dac76c17ab1c38408d6197adfdbd60c7d639469e121901ab7b06bd',
  ),
  (
    id: 'benedict',
    slot: 'A',
    sha256: '8007de516b665b933a84f0aed3283f2e4254099e84b7023fdf33df538b70fc37',
    originalSha256:
        '1c6356047fb44db63e26beebff2e29d55a0b8b8601d0080261fd8506e5931a56',
  ),
  (
    id: 'blood_court',
    slot: 'A',
    sha256: 'e614e4271977b073d0043248b1437fff43296f38c5e090a31cecda8875542f62',
    originalSha256:
        '36f16d0e74c65352d96fdf9bc7c42366c4cd8316a96d19e70b01c74459ff5f59',
  ),
  (
    id: 'bolted_black_iron',
    slot: 'D',
    sha256: 'd59878f7d28740a4a0d283ed49563d37d565f38a55142b149902884a08cae17f',
    originalSha256:
        '3358f7791393de7b97f99cfbefb335664ebcd630115120666c9d198c0fd2587c',
  ),
  (
    id: 'bone_saint',
    slot: 'A',
    sha256: '45867a79cfb50e40de3af84cb79a2f91de9fe5de7f40cdb789190daa2fa79c0a',
    originalSha256:
        '1841be7bf18920087d8fce99544b5d0b7b469db0d1b3e2867b8fd30c61e5b092',
  ),
  (
    id: 'cell_crimson_run',
    slot: 'F',
    sha256: 'b398b69cbd75a2401502f4e9bcb0ce121a40a3d6eeaad534f389695658d70953',
    originalSha256:
        'a96672404635d40ce3cade5984f6a60875517148d9faa837a3dfa73ee8f38541',
  ),
  (
    id: 'element_pack_acido',
    slot: 'B',
    sha256: 'ac4df5aebc0d246eaf774fa2a338b451a1183a800d216e51553a957d08fd5728',
    originalSha256:
        '44b128cc67db381418522d4a42129525d2451fb9028d1323a98a129b4da187ce',
  ),
  (
    id: 'element_pack_angelico',
    slot: 'D',
    sha256: 'db1a1e098a6b971db919664abeeb5972a9e0a8a346b2824eae5fa08f9da82f25',
    originalSha256:
        '2da8ea44582e1a2b51263cfc8468f4331b87678ea90ede1607716edd0370ebc8',
  ),
  (
    id: 'element_pack_esplosivo',
    slot: 'D',
    sha256: '8ccf2c04c79f3fbea3d8a956fbfdc1bcb1ac05083734d7d44a8cfa83e9e65cc9',
    originalSha256:
        'dd60c98bec3be317ef2e5b56005c7879114accca23e53007f3acc8dee108c5ac',
  ),
  (
    id: 'element_pack_postea',
    slot: 'B',
    sha256: '2ebd66f10ac0e57ef906270290ce900207fd39fe34e3662cdfdc80b3bb7e991f',
    originalSha256:
        '5d68b73aa526534bf3239d2acc41c2e966a73cb338e6757426b899124a82c3da',
  ),
  (
    id: 'element_pack_proiettile',
    slot: 'A',
    sha256: '4e39892377ccf8f71c06c78eb2ed86f601af9a9125c2c77a51142c7070f4de07',
    originalSha256:
        '1dfeef59ecf84397a9ebc9a310059f20c33c411f3df93cdb8ff14586d7fc5b2b',
  ),
  (
    id: 'element_pack_radiazione',
    slot: 'D',
    sha256: '21ace57d812335b05cceb72e8cfb75352c31847eed30f29fc14367d29feb01fc',
    originalSha256:
        '1d9063788680d13304eb1d5005837eb6cb7ec98e12e7d194ab0ee89d33ea079e',
  ),
  (
    id: 'element_pack_radice',
    slot: 'D',
    sha256: '2a24b13069616afbb6137aeb37ac11f411b428f6b3b01257c2d78cde278c32f2',
    originalSha256:
        '6b7305299fde4ac45e9723472795d7172c7c854700a2f10ce55fa0ca7b4a8433',
  ),
  (
    id: 'element_pack_spazio',
    slot: 'D',
    sha256: 'a7620466e47101586f1b2a8967cc57e8cb317bc4a238489d5e8fabae50e96ccf',
    originalSha256:
        '65a1cb0cba696af87601263b2b3f6e6d585ff8ea09db59e80aeb1ce99919a6f4',
  ),
  (
    id: 'element_pack_tempo',
    slot: 'B',
    sha256: '62c9fe859692ce88a76bf2eda2a9ec6a2dc4bfece8fb45086c1100181d402bd5',
    originalSha256:
        '43c1200f066d15a492108069f5ed99847981fce30978549a0141b20998588767',
  ),
  (
    id: 'element_pack_veleno',
    slot: 'B',
    sha256: 'a5cef01553ea546870edf1e71d62e8f221771d2b6d91d60f3af35788b30866f3',
    originalSha256:
        'afea717ec1942a0ea3b014f6118f17413431784a53bd8d13f5169eda599b2d44',
  ),
  (
    id: 'home_canva_spirit_duelist',
    slot: 'B',
    sha256: '89d19026c55061c659d6965d9887461e210388d2ad09efc85e2e0504d067f926',
    originalSha256:
        '544b1fa54054e59621957a997eaa9141d69b51864e16a0dce37e9fbda4a7a362',
  ),
  (
    id: 'home_cathedral_eye',
    slot: 'E',
    sha256: '41839ab5463cb815833d7037fa5c55083e79aa490e61f38e0fcf66150f382463',
    originalSha256:
        '1c281396d2521976f48ce3fdafc758c81cbca1da65afb82c781e2ef36b7597ed',
  ),
  (
    id: 'hoshy_cosmic_cat',
    slot: 'D',
    sha256: '9802ff9d59c112964d982c1239212c317a77ecce2706a16c5fc0ce40a3596c2c',
    originalSha256:
        'bb3054753340a3a236541b3d065ff8d515557ef3570f3a14e5f9ac6272d929b7',
  ),
  (
    id: 'karma_duality',
    slot: 'B',
    sha256: 'b7cd5b146e662560e12a432ede1d9afafab728e6640c9a7b637d43d9fddae814',
    originalSha256:
        '875360c774b2e6f0eb15a804c2943ec28e5c418300c2408d1c2ce3983c3bda61',
  ),
  (
    id: 'lunar_eclipse',
    slot: 'F',
    sha256: '89c626557afe36df34a9f6976040dba7cf880d12aeaea06b9f8c841107afa0d1',
    originalSha256:
        '438fe2b71b2cf3ed1e3c6538db8a9fe76386113f058f8e922e4af24da4c6d730',
  ),
  (
    id: 'meadow_sprite',
    slot: 'B',
    sha256: '20ad125af4c30b0ba6798d789df3f669307991bd7969bc07a86ccf637678be00',
    originalSha256:
        '9ebec6f555f0c5830e1128e0bf5101dc1bc7120db01fb796a39a850dcedcbfae',
  ),
  (
    id: 'moon_iron',
    slot: 'E',
    sha256: '4ab89f48e4def99f07aedc4edf6d081deb14c4452bc04b4956349786efd49184',
    originalSha256:
        'e9e04f99656e9a7286087ede94811ae498236f7e7087a0ba47e040307ab15a6b',
  ),
  (
    id: 'obsidian_sigil',
    slot: 'E',
    sha256: '91693ee8a0c63cf3a1d26d976b63b93d9e44353f8c137e34eff4242d8d27b95f',
    originalSha256:
        '64105bfb99b34be7aaab33f38a3fc4590753237aa8da37f0453ec410f227fe94',
  ),
  (
    id: 'phobia_dark',
    slot: 'D',
    sha256: '9fc04a9f09a1787e8cff5052323a635104d2ded1092281fccf978c12734825ff',
    originalSha256:
        'c860ba589b303594848875ca404181c167f57dbb09cf6ed25c9be5f4fdfac5b9',
  ),
  (
    id: 'restyle_lume',
    slot: 'B',
    sha256: '5200a706315fe58e04aeb51caf30cee151ae282f31c3980f81827b1af30c07c9',
    originalSha256:
        '7411a78cb6608607b6f468da44340941739552cd48b27bead84ceffb8113c8a6',
  ),
  (
    id: 'restyle_sogno',
    slot: 'A',
    sha256: 'f2f4d7244b79bd30666831c40cf794956c96d3fe63ceaa959e7b97e33f847270',
    originalSha256:
        'ebb6830360afb018a8b9f59ef57350dfe2fa80ebcf5e2fcd32340113d783cbb8',
  ),
  (
    id: 'solar_reliquary',
    slot: 'B',
    sha256: '81f72337c7332fe7452d7bb04b2ae424c19507395eda6bc936b0071592adcd96',
    originalSha256:
        '1ce6dbbda13c840b0e3d722f933cb1c236d6d0bf01e74da0d7afaf369eae0d36',
  ),
  (
    id: 'vervain_gothic',
    slot: 'B',
    sha256: '97839b7a41e028d49e9cc743c6d5379dae28ac9b41ee0b63c28a538d18a574e8',
    originalSha256:
        '3f1fbe79f726fbbca1a5c691ab266ce54b9645fdfbfa1dc412709dfbc9e623ed',
  ),
  (
    id: 'void_liturgy',
    slot: 'B',
    sha256: '65550dd8e108a44fed6bdc2e2ba3a9e6b876e73b1d6d2e34b7743f8ee00ad8a5',
    originalSha256:
        '64ece07f507ae93dc256a67947f9d2d49f3d06e0472961de4d2fc876f707a11b',
  ),
];

String _votedPath(_Vote vote) =>
    'assets/oculum/theme_stories/webp/${vote.id}_canon_20261118_'
    '${vote.slot.toLowerCase()}_${vote.sha256.substring(0, 8)}.webp';

Future<void> _expectDigest(String asset, String expected) async {
  final data = await rootBundle.load(asset);
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  final digest = SHA256Digest()
      .process(bytes)
      .map((value) => value.toRadixString(16).padLeft(2, '0'))
      .join();
  expect(digest, expected, reason: asset);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('The canon includes the thirty choices and the two later themes', () {
    expect(
      oculumApprovedThemeStoryAssets.keys,
      unorderedEquals([
        ..._votes.map((vote) => vote.id),
        'kingi_wrong_future',
        'element_pack_oculum',
      ]),
    );
    expect(oculumApprovedThemeStoryAsset('whispering_reliquary'), isNull);
    expect(oculumApprovedThemeStoryAsset('senka_kamaria'), isNull);
  });

  test(
    'Iride cesellata loads the approved C scene and keeps the original',
    () async {
      const id = 'element_pack_oculum';
      const chosen =
          'assets/oculum/theme_stories/webp/element_pack_oculum_canon_20261119_c_1455481c.webp';
      expect(oculumThemeAssetPacks[id]!.storyScene, chosen);
      await _expectDigest(
        chosen,
        '1455481c4b6e76d9c1ff154933fb0b21928ae5e69623463a66e187c49d46dcd9',
      );
      await _expectDigest(
        'assets/oculum/theme_stories/webp/$id.webp',
        '75862848778cf7ccade907103fc47668bf99fcde3834f4964234e461f10008c9',
      );
    },
  );

  test('Kingi shows the approved F scene and preserves its original', () async {
    const id = 'kingi_wrong_future';
    const chosen =
        'assets/oculum/theme_stories/webp/kingi_wrong_future_canon_20261119_f_cd1a4468.webp';
    final pack = oculumThemeAssetPacks[id]!;
    expect(pack.storyScene, chosen);
    expect(pack.relic, 'assets/themes/$id/overlays/relic.png');
    await _expectDigest(
      chosen,
      'cd1a44685152467a7f6d03a7f88741005b90211fd8e592f84f554c21243f53b1',
    );
    await _expectDigest(
      'assets/oculum/theme_stories/webp/$id.webp',
      'c640019286f53b80d8b671b4cd87bf6a716fd3555533ba2fa1a0b7123a51f3e8',
    );
  });

  testWidgets(
    'The thirty bundled canons match the user SHA and keep originals',
    (tester) async {
      for (final vote in _votes) {
        final asset = _votedPath(vote);
        expect(oculumApprovedThemeStoryAsset(vote.id), asset, reason: vote.id);
        await _expectDigest(asset, vote.sha256);
        await _expectDigest(
          'assets/oculum/theme_stories/webp/${vote.id}.webp',
          vote.originalSha256,
        );
      }
    },
  );

  test(
    'Existing pack IDs resolve the new scene without changing other surfaces',
    () {
      for (final vote in _votes) {
        if (vote.id.startsWith('home_')) {
          expect(oculumThemeAssetPacks.containsKey(vote.id), isFalse);
          continue;
        }
        final pack = oculumThemeAssetPacks[vote.id];
        expect(pack, isNotNull, reason: vote.id);
        expect(pack!.id, vote.id);
        expect(pack.storyScene, _votedPath(vote), reason: vote.id);
        // Angelico has a separate user vote for phone.
        expect(
          pack.storySceneMobileAsset,
          vote.id == 'element_pack_angelico' ? _angelicoPhone : null,
          reason: vote.id,
        );
        expect(pack.relic, 'assets/themes/${vote.id}/overlays/relic.png');
      }
    },
  );

  testWidgets('Angelico switches from desktop D to phone F in portrait', (
    tester,
  ) async {
    const sheetId = 'angelico-portrait-vote';
    const id = 'element_pack_angelico';
    final pack = oculumThemeAssetPacks[id]!;
    final previous = oculumSheetRelicSelections.value;
    addTearDown(() => oculumSheetRelicSelections.value = previous);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    oculumSheetRelicSelections.value = {sheetId: id};
    tester.view.devicePixelRatio = 1;

    await _expectDigest(
      _angelicoPhone,
      'b17b8d788dcdcb445b6e0ef454345d088ea65c14cfa45909ae5f850352f810fc',
    );
    final app = MaterialApp(
      theme: ThemeData.dark().copyWith(
        extensions: const [
          OculumGothOrnaments(
            family: OculumGothFamily.crystal,
            ink: Colors.white,
            accent: Colors.blueGrey,
            opacity: .3,
            themeId: 'classic_reliquary',
          ),
        ],
      ),
      home: const OculumNarrativeBackground(sheetId: sheetId),
    );
    String scenePath() {
      final provider = tester.widget<Image>(find.byType(Image).first).image;
      final asset = provider is ResizeImage ? provider.imageProvider : provider;
      return (asset as AssetImage).assetName;
    }

    tester.view.physicalSize = const Size(1440, 1000);
    await tester.pumpWidget(app);
    expect(scenePath(), pack.storyScene);
    tester.view.physicalSize = const Size(390, 844);
    await tester.pump();
    expect(scenePath(), _angelicoPhone);
    expect(
      pack.relic,
      'assets/themes/element_pack_angelico/overlays/relic.png',
    );
    expect(tester.takeException(), isNull);
  });

  test(
    'Explicit story, phone and relic overrides take precedence over stock art',
    () {
      const pack = OculumThemeAssetPack(
        'element_pack_angelico',
        'Custom title',
        'Custom motif',
        'Custom motion',
        framePackId: 'custom_frame',
        identityPrefix: 'custom_identity',
        storySceneAsset: 'assets/custom/story.webp',
        storySceneMobileAsset: 'assets/custom/phone.webp',
        relicAsset: 'assets/custom/relic.webp',
        maskedStorySceneAsset: 'assets/custom/masked.webp',
      );
      expect(pack.storyScene, 'assets/custom/story.webp');
      expect(pack.storySceneMobileAsset, 'assets/custom/phone.webp');
      expect(pack.relic, 'assets/custom/relic.webp');
      expect(pack.maskedStorySceneAsset, 'assets/custom/masked.webp');
      expect(
        pack.identityFrame,
        'assets/themes/custom_frame/frames/custom_identity-normal.png',
      );
    },
  );

  test(
    'Only voted manual Home aliases change and saved choice IDs remain valid',
    () {
      for (final (alias, id) in const [
        ('cathedral_eye', 'home_cathedral_eye'),
        ('canva_spirit_duelist', 'home_canva_spirit_duelist'),
        ('benedict', 'benedict'),
      ]) {
        expect(oculumHomeArtworkChoices, contains(alias));
        expect(oculumHomeArtworkPath(alias), oculumApprovedThemeStoryAsset(id));
        expect(oculumHomeArtworkPath(id), oculumApprovedThemeStoryAsset(id));
      }
      expect(oculumApprovedHomeStoryAsset('blood_court'), isNull);
      expect(
        oculumHomeArtworkPath('amber_shore'),
        'assets/oculum/home_art/amber_shore.png',
      );
      expect(
        oculumHomeArtworkPath('solar_islands'),
        'assets/oculum/theme_stories/webp/home_solar_islands.webp',
      );
      expect(
        oculumHomeArtworkPath('carne_viva_soglia_della_sutura'),
        'assets/oculum/theme_stories/webp/carne_viva_soglia_della_sutura.webp',
      );
    },
  );

  testWidgets('Different login scenes and the approved Senka surfaces stay intact', (
    tester,
  ) async {
    for (final (asset, digest) in const [
      (
        'assets/oculum/home_art/cathedral_eye.png',
        '2d8bfbf0c64b7dd6283c5789433147031a36a5bc88ff51463748dd39fa8da887',
      ),
      (
        'assets/oculum/home_art/canva_spirit_duelist.png',
        '5cb272b4ba75c9c1ae9ca49bb5105782e938e91d02308d25d994ba6188806cb7',
      ),
      (
        'assets/oculum/home_art_authored/theme_senka_kamaria_canon_20261115.webp',
        '5a4da2f6010d7b19dceb982aec98b2c2b78f03d1b1c693eef8f4a967addb0aba',
      ),
      (
        'assets/oculum/home_art_authored/theme_senka_kamaria_mobile_canon_20261115.webp',
        '401b45f8e5eca48af4bc88d87f02803696e2ef81f6b39ab1d0ffd9ebbf966f74',
      ),
      (
        'assets/oculum/home_art_authored/relic_senka_kamaria_canon_20261115.webp',
        'b58f5995de82bb03c0f03537967e5805056904cc687362bb26824728d8dfb005',
      ),
    ]) {
      await _expectDigest(asset, digest);
    }
    final senka = oculumThemeAssetPacks['senka_kamaria']!;
    expect(
      senka.storyScene,
      'assets/oculum/home_art_authored/theme_senka_kamaria_canon_20261115.webp',
    );
    expect(
      senka.storySceneMobileAsset,
      'assets/oculum/home_art_authored/theme_senka_kamaria_mobile_canon_20261115.webp',
    );
    expect(
      senka.relic,
      'assets/oculum/home_art_authored/relic_senka_kamaria_canon_20261115.webp',
    );
  });

  test(
    'Loading saved global, per-sheet and custom artwork does not migrate them',
    () async {
      final beforePresentation = oculumThemePresentation.value;
      final beforeSelections = Map<String, String>.of(
        oculumSheetRelicSelections.value,
      );
      final beforeCustom = Map<String, dynamic>.of(oculumCustomArtwork.value);
      addTearDown(() {
        oculumThemePresentation.value = beforePresentation;
        oculumSheetRelicSelections.value = beforeSelections;
        oculumCustomArtwork.value = beforeCustom;
      });
      final custom = <String, dynamic>{
        'version': 1,
        'enabled': true,
        'layers': [
          {
            'image': base64Encode([1, 2, 3]),
            'x': .3,
            'y': .8,
            'size': .2,
            'opacity': .3,
            'rotation': .5,
          },
        ],
        'colors': {'volonta': 0xff123456},
      };
      final values = <String, Object>{
        'oculum.transparency20261026': true,
        'oculum.themeArtPack': 'element_pack_angelico',
        'oculum.sheetRelicSelections': jsonEncode({
          'sheet-a': 'abyssal_tide',
          'sheet-b': 'moon_iron',
          'legacy-sheet': 'unknown-custom-id',
        }),
        'oculum.customArtwork.v1': encodeOculumArtwork(custom),
        'oculum.surfaceTransparency': .31,
        'oculum.controlTransparency': .21,
        'unrelated.save.sentinel': 'keep-this-byte-for-byte',
      };
      SharedPreferences.setMockInitialValues(values);
      await loadOculumThemePresentation();
      expect(oculumThemePresentation.value.artPackId, 'element_pack_angelico');
      expect(
        oculumThemePresentationForSheet('sheet-a').artPackId,
        'abyssal_tide',
      );
      expect(oculumThemePresentationForSheet('sheet-b').artPackId, 'moon_iron');
      expect(
        oculumThemePresentationForSheet('legacy-sheet').artPackId,
        'unknown-custom-id',
      );
      expect(oculumCustomArtwork.value, custom);
      expect(oculumCustomStatColor('volonta'), const Color(0xff123456));
      for (final id in ['element_pack_angelico', 'abyssal_tide', 'moon_iron']) {
        expect(
          oculumThemeAssetPacks[id]!.storyScene,
          oculumApprovedThemeStoryAsset(id),
        );
      }
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), unorderedEquals(values.keys));
      for (final entry in values.entries) {
        expect(prefs.get(entry.key), entry.value, reason: entry.key);
      }
    },
  );

  testWidgets('Voted Home artwork remains selectable through the real menu', (
    tester,
  ) async {
    final dynamic state = await fixtures.mountSheet(
      tester,
      const Size(1440, 1000),
    );
    final probe = OculumPerformanceProbe(state);
    state.updateOculumHomeUi(() {
      state.paginaCorrente = 17;
      state.homeArtworkChoice = 'amber_shore';
      state.homeArtworkFollowsTheme = false;
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    final choice = find.byKey(
      const ValueKey('choose_home_artwork_cathedral_eye'),
    );
    expect(choice, findsOneWidget);
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    await tester.pump();
    expect(state.homeArtworkChoice, 'cathedral_eye');
    expect(probe.snapshot()['homeArtworkChoice'], 'cathedral_eye');
    expect(probe.snapshot()['homeArtworkFollowsTheme'], isFalse);
    expect(
      probe.homeHeroArtwork(),
      oculumApprovedThemeStoryAsset('home_cathedral_eye'),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });
}
