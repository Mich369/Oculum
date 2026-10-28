import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_monster_theme.dart';

void main() {
  for (final id in ['guardia_solare', 'guardia_solare_elite']) {
    for (final width in [320.0, 834.0, 1440.0]) {
      testWidgets(
        '$id dedicated relic fits ${width.toInt()}px and does not intercept controls',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final monster = monsterBookEntryById(id)!;
          final theme = OculumMonsterTheme(
            monster,
            oculumMonsterColors(monster).first,
          );
          var taps = 0;
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 240,
                    height: 280,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => taps++,
                            child: const SizedBox.expand(),
                          ),
                        ),
                        OculumMonsterRelic(theme: theme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          final image = tester.widget<Image>(find.byType(Image));
          expect(image.fit, BoxFit.contain);
          expect(
            (image.image as AssetImage).assetName,
            theme.relicIllustration,
          );
          await tester.runAsync(
            () =>
                precacheImage(image.image, tester.element(find.byType(Image))),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(tester.getRect(find.byType(Image)).width, lessThan(240));
          expect(tester.getRect(find.byType(Image)).height, lessThan(280));
          await tester.tapAt(tester.getCenter(find.byType(OculumMonsterRelic)));
          expect(taps, 1);
        },
      );
    }
  }
}
