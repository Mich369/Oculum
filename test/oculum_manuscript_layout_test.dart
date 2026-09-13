import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oculum/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Manuscript real screen fits desktop, short windows and phone', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final regular = await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
    for (final family in [
      'Poppins',
      'Roboto',
      'serif',
      'Segoe UI',
      'Garamond',
      'Georgia',
    ]) {
      await (FontLoader(family)..addFont(Future.value(regular))).load();
    }
    final icons = File(
      'build/unit_test_assets/fonts/MaterialIcons-Regular.otf',
    );
    if (icons.existsSync()) {
      await (FontLoader('MaterialIcons')..addFont(
            Future.value(ByteData.sublistView(icons.readAsBytesSync())),
          ))
          .load();
    }
    final directory = Directory('build/layout-test-data')
      ..createSync(recursive: true);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => directory.absolute.path,
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (_) async => ['none'],
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
      (_) async => null,
    );
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final capture = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: RepaintBoundary(key: capture, child: const OculumHomePage()),
      ),
    );
    await tester.runAsync(
      () async => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump(const Duration(seconds: 1));
    final dynamic state = tester.state(find.byType(OculumHomePage));
    final portrait = base64Encode(
      (await rootBundle.load(
        'assets/icon/oculum_eye.png',
      )).buffer.asUint8List(),
    );
    state.updateOculumHomeUi(() {
      state.activeGameMod = 'manuscript_living';
      state.modalitaDesktop = true;
      state.tutorialCompletato = true;
      state.datiCaricati = true;
      state.nomeController.text = 'Viandante del Bosco';
      state.schedePersonaggio.addAll(
        List<Map<String, dynamic>>.generate(
          10,
          (i) => {
            'id': 'visual_test_$i',
            'nome': i == 0 ? 'Viandante del Bosco' : 'Custode ${i + 1}',
            'tipoScheda': 'Personaggio',
            'immagine': portrait,
            'resilienza': '10',
            'volonta': '20',
            'materia': '18',
            'oculum': '30',
            'currentHp': '100',
          },
        ),
      );
    });
    for (final size in [
      const Size(1440, 900),
      const Size(1100, 600),
      const Size(390, 844),
    ]) {
      tester.view.physicalSize = size;
      await tester.pump(const Duration(milliseconds: 400));
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull, reason: '$size');
      await tester.runAsync(() async {
        final boundary =
            capture.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final picture = await boundary.toImage(pixelRatio: 1);
        final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
        final out = Directory('output/ui')..createSync(recursive: true);
        File(
          '${out.path}/manuscript-${size.width.toInt()}.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        picture.dispose();
      });
      if (size.width >= 760) expect(find.text('Attacco · VC'), findsOneWidget);
      expect(find.textContaining('Closure:'), findsNothing);
    }
    await tester.tap(find.text('TURNO E DADI'));
    await tester.pumpAndSettle();
    expect(find.text('DADI RAPIDI'), findsOneWidget);
    expect(tester.takeException(), isNull);
    state.updateOculumHomeUi(() {
      state.activeGameMod = '';
      state.modalitaDesktop = false;
    });
    for (final size in [const Size(390, 844), const Size(320, 640)]) {
      tester.view.physicalSize = size;
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull, reason: 'Classic $size');
      expect(find.text('Modifica'), findsWidgets);
      await tester.runAsync(() async {
        final boundary =
            capture.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final picture = await boundary.toImage(pixelRatio: 1);
        final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
        File(
          'output/ui/classic-${size.width.toInt()}.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        picture.dispose();
      });
    }
    state.updateOculumHomeUi(() {
      state.paginaCorrente = 16;
      state.occhiCaduti.addAll(
        List<Map<String, dynamic>>.generate(
          3,
          (i) => {
            'id': 'eye_$i',
            'ownerSheetId': state.schedePersonaggio[state.schedaCorrente]['sheetTag'],
            'name': 'Custode $i',
            'rarity': 'non_comune',
            'active': false,
            'originalArts': [],
            'activeArts': [],
            'sheetData': <String, dynamic>{
              'nome': 'Custode $i',
              'resilienza': '10',
              'currentHp': '100',
            },
            'integrityCurrent': 35,
            'integrityMax': 35,
          },
        ),
      );
    });
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull, reason: 'Fallen Eyes mobile');
    expect(find.text('OCCHI DEI CADUTI'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });
}
