import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/widgets/oculum_goth_ornaments.dart';
import 'write_fresh_capture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
    await (FontLoader('Roboto')..addFont(Future.value(font))).load();
  });
  test('Goth motifs follow the theme identity', () {
    expect(oculumGothFamily('vervain'), OculumGothFamily.botanical);
    expect(oculumGothFamily('frost'), OculumGothFamily.crystal);
    expect(oculumGothFamily('kingi'), OculumGothFamily.forged);
    expect(oculumGothFamily('lunar'), OculumGothFamily.astral);
    expect(oculumGothFamily('tide'), OculumGothFamily.tide);
    expect(oculumGothFamily('ember'), OculumGothFamily.ember);
    expect(oculumGothFamily('none'), OculumGothFamily.none);
  });
  for (final size in [const Size(1100, 750), const Size(390, 844)]) {
    testWidgets('Every goth motif paints without blocking controls at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final family in OculumGothFamily.values) {
        var clicked = 0;
        final spec = OculumGothOrnaments(
          family: family,
          ink: const Color(0xff749a8b),
          accent: const Color(0xffc095ef),
          opacity: .4,
          motion: true,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: RepaintBoundary(
              key: const ValueKey('goth-preview'),
              child: OculumGothAmbience(
                spec: spec,
                child: Scaffold(
                  backgroundColor: const Color(0xff100c16),
                  body: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'OCULUM · Grimoire',
                          style: TextStyle(
                            color: Color(0xffeaded2),
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        CustomPaint(
                          foregroundPainter: OculumGothPainter(
                            spec,
                            panel: true,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Rose | Tutto pur di Salvarla',
                                  style: TextStyle(
                                    color: Color(0xffeaded2),
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                FilledButton(
                                  onPressed: () => clicked++,
                                  child: const Text('Tira iniziativa'),
                                ),
                                const SizedBox(height: 18),
                                const Text(
                                  'Vita e scudo · 30 / 30',
                                  style: TextStyle(color: Color(0xffeaded2)),
                                ),
                                const LinearProgressIndicator(
                                  value: 1,
                                  color: Color(0xffa18fcc),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Tira iniziativa'));
        expect(clicked, 1);
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('goth-preview')),
        );
        final filename =
            'output/ui/temi-goth/${family.name}-${size.width.toInt()}.png';
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          final file = File(filename);
          await file.parent.create(recursive: true);
          writeFreshCapture(file, bytes!.buffer.asUint8List());
        });
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
