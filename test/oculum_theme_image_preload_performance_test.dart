import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/widgets/oculum_goth_ornaments.dart';
import 'package:oculum/widgets/oculum_theme_presentation.dart';
import 'package:oculum/widgets/oculum_theme_sheet_art.dart';

class _RecordingArtBundle extends CachingAssetBundle {
  final List<String> imageRequests = <String>[];
  int loadedImageBytes = 0;

  @override
  Future<ByteData> load(String key) async {
    final bytes = await rootBundle.load(key);
    if (key.endsWith('.png') || key.endsWith('.webp') || key.endsWith('.jpg')) {
      imageRequests.add(key);
      loadedImageBytes += bytes.lengthInBytes;
    }
    return bytes;
  }
}

String _assetName(ImageProvider<Object> provider) {
  if (provider is ResizeImage) return _assetName(provider.imageProvider);
  if (provider is AssetImage) return provider.assetName;
  if (provider is ExactAssetImage) return provider.assetName;
  throw StateError('Expected bundled theme artwork, got $provider');
}

void main() {
  for (final size in const <Size>[Size(390, 844), Size(1440, 900)]) {
    for (final packId in const <String>['abyssal_tide', 'canva_ice']) {
      testWidgets('sheet loads only visible artwork for $packId at $size', (
        tester,
      ) async {
        final originalPresentation = oculumThemePresentation.value;
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(() {
          oculumThemePresentation.value = originalPresentation;
        });
        oculumThemePresentation.value = OculumThemePresentation(
          motion: OculumThemeMotion.disabled,
          variant: OculumThemeVariant.alive,
          artPackId: packId,
        );

        final bundle = _RecordingArtBundle();
        var taps = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark().copyWith(
              extensions: <ThemeExtension<dynamic>>[
                OculumGothOrnaments(
                  family: OculumGothFamily.tide,
                  ink: Colors.teal,
                  accent: Colors.amber,
                  opacity: .5,
                  themeId: packId,
                ),
              ],
            ),
            home: DefaultAssetBundle(
              bundle: bundle,
              child: Scaffold(
                body: Center(
                  child: OculumThemeSheetBackdrop(
                    child: OculumThemeSheetFrame(
                      child: SizedBox(
                        width: 300,
                        height: 160,
                        child: Center(
                          child: FilledButton(
                            onPressed: () => taps++,
                            child: const Text('Usa abilità'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        // Resolve the actual visible providers, including their resize keys.
        // Each scenario has its own cold bundle, without global cache tuning.
        final images = find.byType(Image).evaluate().toList();
        expect(images, isNotEmpty);
        final visibleAssets = images
            .map((element) => _assetName((element.widget as Image).image))
            .toSet();
        await tester.runAsync(() async {
          await Future.wait<void>(
            images.map(
              (element) =>
                  precacheImage((element.widget as Image).image, element),
            ),
          );
        });
        await tester.pump();

        expect(
          bundle.imageRequests,
          unorderedEquals(visibleAssets),
          reason:
              'Hidden legacy frames or duplicate resize providers '
              'must not decode alongside the visible artwork.',
        );
        expect(bundle.loadedImageBytes, greaterThan(0));
        expect(
          tester.getSize(find.byType(OculumThemeSheetFrame)),
          const Size(300, 160),
        );
        await tester.tap(find.text('Usa abilità'));
        expect(taps, 1);
        expect(tester.takeException(), isNull);
        final requests = bundle.imageRequests.length;
        final bytes = bundle.loadedImageBytes;
        debugPrint(
          'Theme image loads $packId at $size: '
          '$requests requests, $bytes encoded bytes; '
          'no undisplayed images.',
        );

        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
