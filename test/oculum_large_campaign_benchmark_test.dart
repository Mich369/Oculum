import 'dart:io';
import 'dart:convert';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oculum/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('large campaign reproducible performance', (tester) async {
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
      'build/performance-fixture-${DateTime.now().microsecondsSinceEpoch}',
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
    final probe = OculumPerformanceProbe(state);
    final fixture = probe.snapshot();
    // Valid image bytes, repeated in retained attachments to model large saves.
    final bytes = (await rootBundle.load(
      'assets/oculum/manuscript_reference.png',
    )).buffer.asUint8List();
    final portrait = base64Encode(bytes);
    fixture['textAttachments'] = {
      'notes': List.generate(
        1,
        (i) => {'imageBase64': portrait, 'name': 'Original $i'},
      ),
    };
    fixture['resilienza'] = '30';
    fixture['currentHp'] = '300';
    fixture['immaginePersonaggioBase64'] = portrait;
    final sheets = List.generate(
      120,
      (i) => <String, dynamic>{
        ...oculumCopyJsonTree(fixture) as Map<String, dynamic>,
        'nome': 'Creature $i',
        'sheetTag': 'perf_$i',
        'tipoScheda': i == 0 ? 'Personaggio' : 'Mostro',
      },
    );
    final report = <String, dynamic>{
      'sheets': 120,
      'eyes': 300,
      'tokens': 120,
      'mode':
          'Flutter debug widget test; CPU pump wall time is not GPU frame time',
    };
    Future<void> measure(String label, Future<void> Function() run) async {
      probe.cancelPendingSave();
      debugPrint('Benchmark: $label');
      final watch = Stopwatch()..start();
      await run();
      report[label] = watch.elapsedMicroseconds / 1000;
      debugPrint('$label: ${report[label]}');
      const runLabel = String.fromEnvironment('OculumBenchmarkLabel', defaultValue: 'latest');
      Directory('output/performance').createSync(recursive: true);
      File('output/performance/$runLabel.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
    }

    await measure('load_sheet_ms', () async {
      probe.load(sheets[0]);
    });
    state.updateOculumHomeUi(() {
      state.activeGameMod = '';
      state.modalitaDesktop = true;
      state.modalitaMaster = true;
      state.tutorialCompletato = true;
      state.datiCaricati = true;
      state.schedePersonaggio.clear();
      state.schedePersonaggio.addAll(sheets);
      state.schedaCorrente = 0;
      state.masterInitiativeTokens.clear();
      state.masterInitiativeTokens.addAll(
        List.generate(
          120,
          (i) => <String, dynamic>{
            'id': 'token_$i',
            'name': 'Creature $i',
            'sheetTag': 'perf_$i',
            'sheetIndex': i,
            'currentHp': 300,
            'maxHp': 300,
            'status': 'ready',
            'side': 'enemy',
            'initiative': 120 - i,
          },
        ),
      );
      state.occhiCaduti.clear();
      state.occhiCaduti.addAll(
        List.generate(
          300,
          (i) => <String, dynamic>{
            'id': 'eye_$i',
            'ownerSheetId': 'perf_0',
            'name': 'Eye $i',
            'rarity': 'non_comune',
            'active': false,
            'originalArts': [],
            'activeArts': [],
            'sheetData': {
              'nome': 'Eye $i',
              'immaginePersonaggioBase64': portrait,
            },
            'integrityCurrent': 30,
            'integrityMax': 30,
          },
        ),
      );
    });
    await measure('campaign_decode_ms', () async {
      final raw = jsonEncode(sheets);
      report['campaign_bytes'] = raw.length;
      final decoded = jsonDecode(raw) as List;
      expect(decoded.length, 120);
    });
    await measure('master_open_ms', () async {
      state.updateOculumHomeUi(() {
        state.paginaCorrente = 9;
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });
    var rebuilds = 0;
    debugOnRebuildDirtyWidget = (element, built) {
      if (built) rebuilds++;
    };
    await measure('hp_10_ms', () async {
      for (var i = 0; i < 10; i++) {
        probe.hp(1);
        await tester.pump();
        probe.cancelPendingSave();
      }
    });
    report['hp_rebuilds'] = rebuilds;
    rebuilds = 0;
    await measure('turn_10_ms', () async {
      for (var i = 0; i < 10; i++) {
        probe.turn();
        await tester.pump();
        probe.cancelPendingSave();
      }
    });
    report['turn_rebuilds'] = rebuilds;
    debugOnRebuildDirtyWidget = null;
    await measure('history_20_ms', () async {
      for (var i = 0; i < 20; i++) {
        state.nomeController.text = 'Edit $i';
        probe.saveSheet();
      }
    });
    report['history_entries'] = (state.undoHistory as List).length;
    await measure('book_lookup_1000_ms', () async {
      for (var i = 0; i < 1000; i++) {
        probe.lookup(
          defaultMonsterBookEntries[i % defaultMonsterBookEntries.length].id,
        );
      }
    });
    await measure('eyes_open_ms', () async {
      state.updateOculumHomeUi(() {
        state.paginaCorrente = 16;
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });
    // RSS is process-wide, including the test runner and compiler allocations.
    report['rss_bytes'] = ProcessInfo.currentRss;
    await measure('autosave_ms', () async {
      await tester.runAsync(() async {
        state.sharedPreferencesFuture = SharedPreferences.getInstance();
        state.saveBlobDirectoryFuture = Future<Directory>.value(directory);
        await probe.save();
      });
    });
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final dir = Directory('output/performance')..createSync(recursive: true);
      const label = String.fromEnvironment(
        'OculumBenchmarkLabel',
        defaultValue: 'latest',
      );
      File(
        '${dir.path}/$label.json',
      ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
    });
    probe.cancelPendingSave();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  }, timeout: const Timeout(Duration(minutes: 5)));
}
