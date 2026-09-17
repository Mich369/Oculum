import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oculum/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('fallen eyes filters render on desktop and phone', (
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
    final directory = Directory(
      'build/afona-test-${DateTime.now().microsecondsSinceEpoch}',
    )..createSync(recursive: true);
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
    final homeKey = GlobalKey();
    final boundaryKey = GlobalKey();
    Widget? page;
    Widget host() => MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: Stack(
          children: [
            Offstage(child: OculumHomePage(key: homeKey)),
          if (page != null) RepaintBoundary(key: boundaryKey, child: page),
          ],
        ),
      ),
    );
    await tester.pumpWidget(host());
    await tester.runAsync(
      () async => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump(const Duration(seconds: 1));
    final dynamic state = homeKey.currentState!;
    final probe = OculumPerformanceProbe(homeKey.currentState!);
    state.schedePersonaggio.add(<String, dynamic>{
      'sheetTag': 'test-owner',
      'nome': 'Viandante',
    });
    state.schedaCorrente = 0;
    final owner = probe.ownerTag();
    for (var i = 0; i < 3; i++) {
      state.occhiCaduti.add(<String, dynamic>{
        'id': 'eye$i',
        'ownerSheetId': owner,
        'name': ['Snorlo', 'Legno Marcio', 'Custode Risvegliato'][i],
        'rarity': i == 2 ? 'oculum' : 'raro',
        'originalRarity': i == 2 ? 'oculum' : 'raro',
        'bond': [160, 650, 1000][i],
        'active': i == 0,
        'perdutoPerSempre': i > 0,
        'deathWounds': i > 0 ? 3 : 0,
        'currentHp': i > 0 ? 0 : 50,
        'integrityMax': 40,
        'integrityCurrent': 30,
        'activeArts': [],
        'sheetData': {'livello': '5', 'exp': '150'},
      });
    }
    page = probe.fallenEyesPage();
    await tester.pumpWidget(host());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    for (final width in [1440.0, 390.0]) {
      tester.view.physicalSize = Size(width, width == 390 ? 844 : 900);
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'output/ui/occhi-caduti-${width.toInt()}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.tap(find.text('In attesa di Rinascita'));
    await tester.pump();
    expect(find.text('Snorlo'), findsNothing);
    probe.cancelPendingSave();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });
}
