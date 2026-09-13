import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oculum/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Merchant Dust purchase is limited until Long Rest', (
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
    state.updateOculumHomeUi(() {
      state.activeGameMod = '';
      state.modalitaDesktop = true;
      state.tutorialCompletato = true;
      state.datiCaricati = true;
      state.paginaCorrente = 6;
      state.obserController.text = '100';
      state.ascensionDustController.text = '0';
    });
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Mercante in vista'));
    await tester.pumpAndSettle();
    final buy = find.widgetWithText(
      OutlinedButton,
      '20 Obser → 1 Ascension Dust · 1 per Riposo Lungo',
    );
    final callback = tester.widget<OutlinedButton>(buy).onPressed!;
    callback();
    callback(); // A queued second click must also be rejected by the transaction.
    await tester.pump();
    expect(state.obserController.text, '80');
    expect(state.ascensionDustController.text, '1');
    expect(state.merchantDustPurchasedSinceLongRest, isTrue);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(
              OutlinedButton,
              'Dust acquistata · disponibile dopo il Riposo Lungo',
            ),
          )
          .onPressed,
      isNull,
    );
    state.updateOculumHomeUi(() {
      state.paginaCorrente = 1;
    });
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    final shortRest = find.widgetWithText(ElevatedButton, 'Riposo Breve');
    tester.widget<ElevatedButton>(shortRest).onPressed!();
    expect(state.merchantDustPurchasedSinceLongRest, isTrue);
    final longRest = find.widgetWithText(
      ElevatedButton,
      'Riposo Lungo — 1 ora e mezza',
    );
    tester.widget<ElevatedButton>(longRest).onPressed!();
    expect(state.merchantDustPurchasedSinceLongRest, isFalse);
    callback();
    expect(state.obserController.text, '60');
    expect(state.ascensionDustController.text, '2');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });
}
