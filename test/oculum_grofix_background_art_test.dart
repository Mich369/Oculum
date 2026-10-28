import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_goth_ornaments.dart';
import 'package:oculum/widgets/oculum_monster_theme.dart';
import 'package:oculum/widgets/oculum_narrative_background.dart';
import 'package:oculum/widgets/oculum_theme_presentation.dart';

void main() {
  for (final width in [320.0, 834.0, 1440.0]) {
    testWidgets(
      'Grofix background uses the correct composition at ${width.toInt()}px and preserves controls',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final previous = oculumSheetRelicSelections.value;
        addTearDown(() => oculumSheetRelicSelections.value = previous);
        final monster = monsterBookEntryById('grofix')!;
        final theme = OculumMonsterTheme(
          monster,
          oculumMonsterColors(monster).first,
        );
        oculumSheetRelicSelections.value = {'grofix-preview': theme.id};
        var taps = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark().copyWith(
              extensions: const [
                OculumGothOrnaments(
                  family: OculumGothFamily.crystal,
                  ink: Colors.white,
                  accent: Colors.green,
                  opacity: .3,
                  themeId: 'classic_reliquary',
                ),
              ],
            ),
            home: Scaffold(
              body: Stack(
                children: [
                  const Positioned.fill(
                    child: OculumNarrativeBackground(sheetId: 'grofix-preview'),
                  ),
                  Center(
                    child: FilledButton(
                      onPressed: () => taps++,
                      child: const Text('Attacco'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        final image = tester.widget<Image>(find.byType(Image).first);
        final provider = image.image;
        final asset = provider is ResizeImage
            ? provider.imageProvider
            : provider;
        expect(asset, isA<AssetImage>());
        expect(
          (asset as AssetImage).assetName,
          width < 600 ? theme.illustrationMobile : theme.illustration,
        );
        await tester.runAsync(
          () => precacheImage(
            image.image,
            tester.element(find.byType(Image).first),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Attacco'));
        expect(taps, 1);
      },
    );
  }
}
