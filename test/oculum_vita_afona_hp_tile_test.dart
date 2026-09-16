import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oculum/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('HP condition tile masks current HP under Vita Afona', (
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
    Widget? tile;
    final tileKey = GlobalKey();
    Widget app() => MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: Stack(
          children: [
            Offstage(child: OculumHomePage(key: homeKey)),
            if (tile != null)
              Center(
                child: SizedBox(key: tileKey, width: 180, child: tile),
              ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(app());
    await tester.runAsync(
      () async => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump(const Duration(seconds: 1));
    final dynamic state = homeKey.currentState!;
    final probe = OculumPerformanceProbe(homeKey.currentState!);
    state.activeGameMod = '';
    state.resilienzaController.text = '4';
    state.currentResilienzaController.text = '4';
    state.currentHpController.text = '10';
    state.activeConditions.clear();
    state.invalidateDerivedDataCaches();
    tile = probe.hpConditionTile();
    await tester.pumpWidget(app());
    expect(
      find.descendant(of: find.byKey(tileKey), matching: find.text('10/40')),
      findsOneWidget,
    );
    state.activeConditions.add(
      OculumConditionInstance.fromJson({
        'id': 'afona-test',
        'conditionType': 'vita_afona',
        'category': 'negative',
        'duration': 3,
      }),
    );
    state.invalidateDerivedDataCaches();
    tile = probe.hpConditionTile();
    await tester.pumpWidget(app());
    expect(
      find.descendant(of: find.byKey(tileKey), matching: find.text('???/40')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byKey(tileKey), matching: find.text('10/40')),
      findsNothing,
    );
    expect(state.currentHpController.text, '10');
    state.activeConditions.clear();
    state.invalidateDerivedDataCaches();
    tile = probe.hpConditionTile();
    await tester.pumpWidget(app());
    expect(
      find.descendant(of: find.byKey(tileKey), matching: find.text('10/40')),
      findsOneWidget,
    );
    probe.cancelPendingSave();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });
}
