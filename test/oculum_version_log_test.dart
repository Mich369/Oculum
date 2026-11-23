import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oculum/services/oculum_update_log.dart';
import 'package:oculum/widgets/oculum_update_log_dialog.dart';

void main() {
  test('version notice persists once per build and save profile', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    expect(oculumShouldShowVersionLog(prefs, ''), false);
    expect(oculumShouldShowVersionLog(prefs, 'version-a'), true);
    await oculumRememberVersionLog(prefs, 'version-a');
    expect(oculumShouldShowVersionLog(prefs, 'version-a'), false);
    expect(oculumShouldShowVersionLog(prefs, 'version-b'), true);
    expect(
      oculumShouldShowVersionLog(
        prefs,
        'version-a',
        storageKey: '${oculumUpdateLogSeenKey}__test',
      ),
      true,
    );
    await oculumRememberVersionLog(
      prefs,
      'version-b',
      storageKey: '${oculumUpdateLogSeenKey}__test',
    );
    expect(oculumShouldShowVersionLog(prefs, 'version-a'), false);
    expect(
      oculumShouldShowVersionLog(
        prefs,
        'version-b',
        storageKey: '${oculumUpdateLogSeenKey}__test',
      ),
      false,
    );
  });

  test(
    'content fingerprints distinguish local builds of the same commit',
    () async {
      const commit = '968866652a53bd367a6220ab32124b186aaec880';
      final first = oculumVersionLogIdentity(commit, buildId: 'a' * 64);
      final second = oculumVersionLogIdentity(commit, buildId: 'b' * 64);
      expect(first, isNot(second));
      expect(oculumVersionLogIdentity(commit, buildId: 'A' * 64), first);
      SharedPreferences.setMockInitialValues({
        oculumUpdateLogSeenKey: commit,
        'saved_sheet_sentinel': 'Preserved character data',
      });
      final prefs = await SharedPreferences.getInstance();
      expect(oculumShouldShowVersionLog(prefs, first), isTrue);
      await oculumRememberVersionLog(prefs, first);
      expect(oculumShouldShowVersionLog(prefs, first), isFalse);
      expect(oculumShouldShowVersionLog(prefs, second), isTrue);
      await oculumRememberVersionLog(prefs, second);
      expect(oculumShouldShowVersionLog(prefs, second), isFalse);
      expect(
        oculumShouldShowVersionLog(
          prefs,
          second,
          storageKey: '${oculumUpdateLogSeenKey}__test',
        ),
        isTrue,
      );
      expect(
        prefs.getString('saved_sheet_sentinel'),
        'Preserved character data',
      );
    },
  );

  test(
    'official fallback keeps the previous commit-based notice state',
    () async {
      const commit = '968866652a53bd367a6220ab32124b186aaec880';
      expect(oculumVersionLogIdentity(commit, buildId: ''), commit);
      expect(
        oculumVersionLogIdentity(commit, buildId: 'not-a-fingerprint'),
        commit,
      );
      expect(oculumVersionLogIdentity('', buildId: ''), isEmpty);
      SharedPreferences.setMockInitialValues({oculumUpdateLogSeenKey: commit});
      final prefs = await SharedPreferences.getInstance();
      expect(
        oculumShouldShowVersionLog(
          prefs,
          oculumVersionLogIdentity(commit, buildId: ''),
        ),
        isFalse,
      );
      final localVersion = oculumVersionLogIdentity(commit, buildId: 'c' * 64);
      expect(oculumShouldShowVersionLog(prefs, localVersion), isTrue);
      await oculumRememberVersionLog(prefs, localVersion);
      expect(oculumShouldShowVersionLog(prefs, localVersion), isFalse);
      expect(prefs.getString(oculumUpdateLogSeenKey), localVersion);
    },
  );

  test(
    'offline notice is the entire current cumulative log from the fixed baseline',
    () {
      final source = File('docs/REGISTRO_AGGIORNAMENTI.md').readAsStringSync();
      final bundled = File(oculumCumulativeLogAsset).readAsStringSync();
      expect(bundled, source);
      expect(bundled, contains(oculumCumulativeLogBaseline));
      expect(bundled, contains('Sfinimento'));
      expect(bundled, contains('231 oggetti'));
      expect(
        oculumReadableUpdateLog(
          '[Registro](https://example.com)\n## Novità\n`valore`',
        ),
        'Registro\nNovità\nvalore',
      );
    },
  );

  for (final width in [320.0, 1440.0]) {
    testWidgets('outside click closes a scrollable version log at $width px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => oculumShowVersionLogDialog(
                    context,
                    File(oculumCumulativeLogAsset).readAsStringSync(),
                    'version-test',
                  ),
                  child: const Text('Apri log'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Apri log'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('oculum_version_log_dialog')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.tapAt(const Offset(1, 1));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('oculum_version_log_dialog')),
        findsNothing,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}
