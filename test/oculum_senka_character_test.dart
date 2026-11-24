import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/widgets/oculum_goth_ornaments.dart';
import 'package:oculum/widgets/oculum_narrative_background.dart';
import 'package:oculum/widgets/oculum_theme_asset_packs.dart';
import 'package:oculum/widgets/oculum_theme_presentation.dart';

void main() {
  test(
    'Senka code imports one private-data-free sheet and preserves editable models',
    () {
      final folder = Directory('output/characters/senka_kamaria');
      final sheet = oculumDecodeSheetShareText(
        File('${folder.path}/Senka_Kamaria.codice.txt').readAsStringSync(),
      ).single;
      expect(
        sheet,
        jsonDecode(
          File('${folder.path}/Senka_Kamaria.json').readAsStringSync(),
        ),
      );
      expect(sheet['nome'], 'Senka Kamaria');
      expect(sheet['livello'], '1');
      expect(sheet['grado'], '0');
      expect(sheet['razza'], 'Mhunan');
      expect(sheet['exp'], '100');
      final knife = (sheet['inventario'] as List).singleWhere(
        (item) => item['nome'] == 'Coltello di Senka',
      );
      expect(knife['bonusDanno'], 3);
      expect(knife['elementoDanno'], 'Tagliente');
      expect(knife['equipaggiata'], true);
      expect(
        (sheet['inventario'] as List)
            .where((item) => item['nome'] == 'Vitalium Ridefinito')
            .single['quantita'],
        1,
      );
      for (final key in [
        'id',
        'sheetTag',
        'realtimeOwnerTag',
        'realtimeCampaignId',
      ]) {
        expect(sheet.containsKey(key), isFalse);
      }
      final art = CharacterArt.fromJson(
        Map<String, dynamic>.from((sheet['arti'] as List).single),
      );
      expect(art.skills, hasLength(3));
      expect(art.skills.map((s) => s.livello), [1, 1, 0]);
      expect(art.skills.first.oculumMinimoPerLivello(1), 3);
      expect(art.skills.last.unlockRequirementsPerLevel.first['level'], 3);
      final restored = CharacterArt.fromJson(art.toJson());
      expect(restored.toJson(), art.toJson());
      final mask = (sheet['inventario'] as List)
          .map((t) => InventoryItem.fromJson(Map<String, dynamic>.from(t)))
          .firstWhere((t) => t.craftData['senkaMask'] == true);
      expect(mask.buff, '@res+6; @vol+5; @mat+10; @ocu+5');
      expect(mask.equipaggiata, isFalse);
      expect(mask.note, isNot(contains('@Danni+6 @Difesa+3')));
      expect(mask.note, contains('VELO'));
      expect(mask.note, contains('ceil(3 × tiro / 4)'));
      expect(mask.note, contains('RICARICANO'));
      expect(
        [mask.bonusDanno, mask.bonusDifesa, mask.bonusScudoOculum],
        [6, 3, 20],
      );
      final abilities = (sheet['skills'] as List)
          .map((t) => CharacterSkill.fromJson(Map<String, dynamic>.from(t)))
          .toList();
      final attack = abilities.firstWhere((s) => s.nome == 'Mille Tagli');
      expect(attack.forme.single.costoStrutturato!.resource, 'materia');
      expect(attack.forme.single.cooldownStrutturato!.unit, 'riposi_lunghi');
      expect(attack.descrizione, contains('SENKA riceve Sfinimento'));
      expect(attack.descrizione, contains('UNICO danno'));
      expect(attack.equipaggiata, isFalse);
      expect(
        CharacterSkill.fromJson(attack.toJson()).toJson(),
        attack.toJson(),
      );
      expect(oculumCharacterSkillFormCost(attack.forme.single)!.minimum, 1);
      expect(attack.costo, '1 Materia');
      expect(sheet['relicArtPackId'], 'senka_kamaria');
      expect(sheet['notePersonaggio'], contains('Sotto le radici'));
      expect(sheet['notePersonaggio'], contains('Fra le travi'));
      expect(sheet['currentHp'], '63');
      expect(sheet['background'], contains('piani più bassi di Lost Town'));
      final clone = abilities.firstWhere(
        (s) => s.nome == 'Clone d’ombra di Senka',
      );
      final cost = oculumCharacterSkillFormCost(clone.forme.single)!;
      expect([cost.resource, cost.minimum, cost.maximum], ['materia', 1, 10]);
      expect(clone.costo, '1–10 Materia');
      for (final ability in abilities) {
        for (final form in ability.forme) {
          final parsed = oculumParseAbilityCost(form.costo);
          final actual = oculumCharacterSkillFormCost(form);
          expect(parsed, isNotNull, reason: '${ability.nome}: ${form.costo}');
          expect(parsed!.resource, actual!.resource);
          expect(parsed.minimum, actual.minimum);
          expect(parsed.maximum, actual.maximum);
        }
      }
      expect(clone.descrizione, contains('0 Azioni e 1 Reazione normale'));
    },
  );

  testWidgets('Senka uses approved art and keeps a custom selection', (
    tester,
  ) async {
    const sheetId = 'senka-art-preview';
    const artPackId = 'senka_kamaria';
    final pack = oculumThemeAssetPacks[artPackId]!;
    final otherPack = oculumThemeAssetPacks['moon_iron']!;
    final previous = oculumSheetRelicSelections.value;
    addTearDown(() => oculumSheetRelicSelections.value = previous);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    oculumSheetRelicSelections.value = {sheetId: artPackId};

    Widget background({bool masked = false}) => MaterialApp(
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
      home: OculumNarrativeBackground(
        sheetId: sheetId,
        senkaMaskActive: masked,
      ),
    );
    Image scenery() => tester.widget<Image>(find.byType(Image).first);
    String assetName() {
      final provider = scenery().image;
      return ((provider is ResizeImage ? provider.imageProvider : provider)
              as AssetImage)
          .assetName;
    }

    expect(
      pack.storyScene,
      endsWith('theme_senka_kamaria_canon_20261115.webp'),
    );
    expect(pack.relic, endsWith('relic_senka_kamaria_canon_20261115.webp'));
    final bundled = await tester.runAsync(
      () => AssetManifest.loadFromAssetBundle(rootBundle),
    );
    expect(
      bundled!.listAssets(),
      containsAll([
        pack.storyScene,
        pack.storySceneMobileAsset,
        pack.maskedStorySceneAsset,
        pack.relic,
      ]),
    );

    tester.view.physicalSize = const Size(1440, 900);
    await tester.pumpWidget(background());
    expect(assetName(), pack.storyScene);
    await tester.pumpWidget(background(masked: true));
    expect(assetName(), pack.maskedStorySceneAsset);
    expect(scenery().fit, BoxFit.cover);

    tester.view.physicalSize = const Size(392, 850);
    await tester.pumpWidget(background());
    expect(assetName(), pack.storySceneMobileAsset);
    await tester.pumpWidget(background(masked: true));
    expect(assetName(), pack.maskedStorySceneAsset);
    expect(scenery().fit, BoxFit.cover);

    oculumSheetRelicSelections.value = {sheetId: otherPack.id};
    await tester.pump();
    expect(assetName(), otherPack.storyScene);
    expect(tester.takeException(), isNull);
  });
}
