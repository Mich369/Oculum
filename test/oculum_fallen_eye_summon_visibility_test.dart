import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oculum/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'summoned Eyes stay in the sheet list, repair missing records and remove owner bonuses',
    (tester) async {
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
      await tester.pumpWidget(MaterialApp(home: OculumHomePage(key: homeKey)));
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pump(const Duration(seconds: 1));
      final dynamic state = homeKey.currentState!;
      final probe = OculumPerformanceProbe(homeKey.currentState!);
      Future<void> runWithFrames(Future<void> Function() operation) async {
        var complete = false;
        Object? failure;
        StackTrace? failureStack;
        await tester.runAsync(() async {
          unawaited(
            operation()
                .then((_) {
                  complete = true;
                })
                .catchError((Object error, StackTrace stack) {
                  failure = error;
                  failureStack = stack;
                  complete = true;
                }),
          );
          await Future<void>.delayed(const Duration(milliseconds: 20));
        });
        final watch = Stopwatch()..start();
        while (!complete && watch.elapsed < const Duration(seconds: 45)) {
          await tester.pump(const Duration(milliseconds: 100));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
        }
        if (failure != null) Error.throwWithStackTrace(failure!, failureStack!);
        expect(
          complete,
          isTrue,
          reason: 'Reload did not finish while frames and IO were pumped',
        );
      }

      state.saveBlobDirectoryFuture = Future<Directory>.value(directory);
      await runWithFrames(() async {
        while (state.datiCaricati != true) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });
      state.salvataggioBloccatoPerErrore = false;
      probe.load({
        'nome': 'Owner',
        'sheetTag': 'owner-restore-test',
        'resilienza': '3',
        'volonta': '4',
        'materia': '2',
        'oculum': '0',
        'currentResilienza': '3',
        'currentVolonta': '4',
        'currentMateria': '2',
        'currentOculum': '0',
        'currentHp': '30',
        'livello': '0',
        'grado': '0',
      });
      probe.saveSheet();
      final ownerTag = probe.ownerTag();
      final before = probe.snapshot();
      final eye = <String, dynamic>{
        'id': 'eye-persistence',
        'ownerSheetId': ownerTag,
        'name': 'Riccio ereditato',
        'rarity': 'raro',
        'originalRarity': 'raro',
        'sourceMonsterId': 'riccio_aculeo',
        'active': false,
        'bond': 0,
        'sheetData': <String, dynamic>{
          'nome': 'Riccio ereditato',
          'livello': '3',
          'grado': '1',
          'resilienza': '3',
          'volonta': '3',
          'materia': '3',
          'oculum': '3',
          'currentHp': '45',
          'currentResilienza': '3',
          'currentVolonta': '3',
          'currentMateria': '3',
          'currentOculum': '3',
        },
      };
      state.occhiCaduti.add(eye);
      await runWithFrames(() => probe.activateFallenEye(eye));
      await tester.pump();
      expect(eye['active'], isTrue);
      final List sheets = state.schedePersonaggio;
      expect(
        sheets.where((s) => s['occhioCadutoId'] == eye['id']),
        hasLength(1),
      );
      final bonuses = Map<String, dynamic>.from(
        eye['summonStatBonuses'] as Map,
      );
      final after = probe.snapshot();
      for (final stat in ['resilienza', 'volonta', 'materia', 'oculum']) {
        expect(
          readIntValue(after[stat]),
          readIntValue(before[stat]) + readIntValue(bonuses[stat]),
        );
      }
      expect(
        probe.grantThreshold(),
        isFalse,
        reason: 'Temporary summon stats cannot unlock a base-stat reward',
      );
      final sheet = Map<String, dynamic>.from(
        sheets.singleWhere((s) => s['occhioCadutoId'] == eye['id']) as Map,
      );
      expect(sheet['arti'], isNotEmpty);
      final originalBond = eye['bond'];
      sheets.removeWhere((s) => s['occhioCadutoId'] == eye['id']);
      await runWithFrames(() => probe.activateFallenEye(eye));
      expect(
        sheets.where((s) => s['occhioCadutoId'] == eye['id']),
        hasLength(1),
      );
      expect(eye['bond'], originalBond);
      expect(
        probe.snapshot()['volonta'],
        after['volonta'],
        reason: 'Recovery cannot grant the bonus twice',
      );
      expect(
        probe.repairFallenEyeSheets(),
        0,
        reason: 'Repair must be idempotent',
      );
      await runWithFrames(probe.save);
      await runWithFrames(probe.reloadSave);
      await tester.pump();
      final restoredEye =
          (state.occhiCaduti as List).singleWhere((e) => e['id'] == eye['id'])
              as Map<String, dynamic>;
      expect(
        (state.schedePersonaggio as List).where(
          (s) => s['occhioCadutoId'] == eye['id'],
        ),
        hasLength(1),
      );
      await runWithFrames(() => probe.deactivateFallenEye(restoredEye));
      await tester.pump();
      final restoredOwner = probe.snapshot();
      for (final stat in ['resilienza', 'volonta', 'materia', 'oculum']) {
        expect(
          readIntValue(restoredOwner[stat]),
          readIntValue(before[stat]),
          reason: '$stat bonus remained after dismiss',
        );
      }
      probe.cancelPendingSave();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    },
  );
}
