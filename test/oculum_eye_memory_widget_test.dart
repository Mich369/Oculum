import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_eye_memory_page.dart';
import 'package:oculum/services/oculum_diary_memory.dart';

void main() {
  testWidgets('Eye map fits phone and desktop and opens original evidence', (
    tester,
  ) async {
    final memory = DiaryMemoryBuilder().build(
      [
        const DiaryDocument(
          id: 'a',
          author: 'Hoshy',
          diary: 'Memorie del Bosco',
          title: 'Il demone',
          day: 3,
          text:
              'Oggi nel Bosco Nero ho affrontato un Forest Demon. Dopo un combattimento lunghissimo sono riuscito ad abbatterlo.',
        ),
      ],
      [const DiaryEntity('demon', 'Forest Demon', 'creature')],
    );
    final font = await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
    await (FontLoader('Poppins')..addFont(Future.value(font))).load();
    final icons = File(
      'build/unit_test_assets/fonts/MaterialIcons-Regular.otf',
    );
    if (icons.existsSync()) {
      await (FontLoader('MaterialIcons')..addFont(
            Future.value(ByteData.sublistView(icons.readAsBytesSync())),
          ))
          .load();
    }
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final capture = GlobalKey();
    for (final size in [const Size(1200, 900), const Size(390, 844)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Poppins'),
          ),
          home: RepaintBoundary(
            key: capture,
            child: OculumEyeMemoryPage(memory: memory, author: 'Hoshy'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('MAPPA DEGLI OCCHI'), findsOneWidget);
      await tester.runAsync(() async {
        final boundary =
            capture.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final picture = await boundary.toImage();
        final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
        const captureLabel = String.fromEnvironment('OculumBenchmarkLabel');
        final capturePath = captureLabel.isEmpty
            ? 'output/ui'
            : 'output/ui/${captureLabel.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}';
        Directory(capturePath).createSync(recursive: true);
        File(
          '$capturePath/diari-${size.width.toInt()}.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        picture.dispose();
      });
      final source = find.byKey(
        const ValueKey('memory_a_0_character:hoshy_diary:a_written'),
      );
      await tester.scrollUntilVisible(
        source,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(source);
      await tester.pumpAndSettle();
      expect(find.byType(SelectableText), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Chiudi'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    }
  });
}
