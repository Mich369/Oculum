import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/services/oculum_save_profile.dart';
import 'package:oculum/services/oculum_smoke_storage.dart';
import 'package:oculum/services/oculum_smoke_storage_io.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:path_provider_windows/path_provider_windows.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';
import 'package:shared_preferences_windows/shared_preferences_windows.dart';

// The same documented Windows SDK KNOWNFOLDERIDs used by the real provider.
const _syntheticRoamingFolderId = '{3EB685DB-65F9-4CF6-A03A-E3EF65729F3D}';
const _syntheticLocalFolderId = '{F1B32785-6FBA-4FCF-9D55-7B8E7F157091}';

class _SyntheticWindowsPaths extends PathProviderWindows {
  _SyntheticWindowsPaths(this.roaming, this.local);
  final String roaming;
  final String local;
  int knownFolderReads = 0;

  @override
  Future<String> getPath(String folderID) async {
    knownFolderReads++;
    if (folderID == _syntheticRoamingFolderId) return roaming;
    if (folderID == _syntheticLocalFolderId) return local;
    throw StateError('Unexpected synthetic known folder');
  }

  @override
  Future<String?> getApplicationSupportPath() async =>
      '$roaming${Platform.pathSeparator}original-app';
}

class _UnsupportedPaths extends PathProviderPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory fixture;
  late Directory root;
  late Directory roaming;
  late Directory local;
  late _SyntheticWindowsPaths paths;
  late SharedPreferencesWindows preferences;
  late SharedPreferencesAsyncWindows asyncPreferences;
  late PathProviderPlatform oldPaths;
  late SharedPreferencesStorePlatform oldPreferences;
  SharedPreferencesAsyncPlatform? oldAsync;
  HttpOverrides? oldHttp;

  Future<void> marker(Directory directory, {String? contents}) async {
    await directory.create(recursive: true);
    await File(
      '${directory.path}${Platform.pathSeparator}$oculumSmokeStorageMarker',
    ).writeAsString(contents ?? oculumSmokeStorageMarkerContents);
  }

  Future<OculumSmokeWindowsInstallation> prepare([String? candidate]) =>
      prepareOculumSmokeWindowsStorage(
        candidate ?? root.path,
        originalPaths: paths,
        originalPreferences: preferences,
        originalAsyncPreferences: asyncPreferences,
      );

  setUp(() async {
    oldPaths = PathProviderPlatform.instance;
    oldPreferences = SharedPreferencesStorePlatform.instance;
    oldAsync = SharedPreferencesAsyncPlatform.instance;
    oldHttp = HttpOverrides.current;
    fixture = await Directory.systemTemp.createTemp('oculum-smoke-synthetic-');
    root = Directory('${fixture.path}${Platform.pathSeparator}copy');
    roaming = Directory('${fixture.path}${Platform.pathSeparator}live-roaming');
    local = Directory('${fixture.path}${Platform.pathSeparator}live-local');
    await roaming.create();
    await local.create();
    await marker(root);
    paths = _SyntheticWindowsPaths(roaming.path, local.path);
    preferences = SharedPreferencesWindows();
    // ignore: invalid_use_of_visible_for_testing_member
    preferences.pathProvider = paths;
    asyncPreferences = SharedPreferencesAsyncWindows();
    // ignore: invalid_use_of_visible_for_testing_member
    asyncPreferences.pathProvider = paths;
    PathProviderPlatform.instance = paths;
    SharedPreferencesStorePlatform.instance = preferences;
    SharedPreferencesAsyncPlatform.instance = asyncPreferences;
    oculumSetSmokeStorageActiveForTesting(false);
  });

  tearDown(() async {
    PathProviderPlatform.instance = oldPaths;
    SharedPreferencesStorePlatform.instance = oldPreferences;
    SharedPreferencesAsyncPlatform.instance = oldAsync;
    HttpOverrides.global = oldHttp;
    oculumSetSmokeStorageActiveForTesting(false);
    // Only the exact directory returned by createTemp belongs to this test.
    expect(fixture.path, contains('oculum-smoke-synthetic-'));
    await fixture.delete(recursive: true);
  });

  test(
    'absent flag leaves registered backends and storage untouched',
    () async {
      final before = await root.list().map((entry) => entry.path).toList();
      await configureOculumSmokeStorage(<String>['--desktop']);
      expect(oculumSmokeStorageActive, isFalse);
      expect(paths.knownFolderReads, 0);
      expect(PathProviderPlatform.instance, same(paths));
      expect(SharedPreferencesStorePlatform.instance, same(preferences));
      expect(SharedPreferencesAsyncPlatform.instance, same(asyncPreferences));
      expect(HttpOverrides.current, same(oldHttp));
      expect(await root.list().map((entry) => entry.path).toList(), before);
    },
  );

  test('only one explicit nonempty root argument is accepted', () {
    expect(oculumSmokeStorageRootArgument(<String>[]), isNull);
    expect(
      oculumSmokeStorageRootArgument(<String>[
        '--oculum-smoke-data-dir=${root.path}',
      ]),
      root.path,
    );
    for (final arguments in <List<String>>[
      <String>['--oculum-smoke-data-dir'],
      <String>['--oculum-smoke-data-dir='],
      <String>['--oculum-smoke-data-dir= ${root.path}'],
      <String>['--oculum-smoke-data-directory=other'],
      <String>[
        '--oculum-smoke-data-dir=${root.path}',
        '--oculum-smoke-data-dir=${root.path}',
      ],
    ]) {
      expect(
        () => oculumSmokeStorageRootArgument(arguments),
        throwsA(isA<OculumSmokeStorageException>()),
      );
    }
  });

  test(
    'relative and traversing roots fail before known-folder reads',
    () async {
      for (final candidate in <String>[
        'relative-copy',
        '${root.path}${Platform.pathSeparator}..${Platform.pathSeparator}copy',
      ]) {
        await expectLater(
          prepare(candidate),
          throwsA(isA<OculumSmokeStorageException>()),
        );
      }
      expect(paths.knownFolderReads, 0);
    },
  );

  test(
    'a missing or incorrect marker never creates backend directories',
    () async {
      final markerFile = File(
        '${root.path}${Platform.pathSeparator}$oculumSmokeStorageMarker',
      );
      await markerFile.delete();
      await expectLater(prepare(), throwsA(isA<OculumSmokeStorageException>()));
      await marker(root, contents: 'not-an-approved-copy');
      await expectLater(prepare(), throwsA(isA<OculumSmokeStorageException>()));
      expect(paths.knownFolderReads, 0);
      expect(
        await Directory(
          '${root.path}${Platform.pathSeparator}support',
        ).exists(),
        isFalse,
      );
      expect(SharedPreferencesStorePlatform.instance, same(preferences));
    },
  );

  test('live AppData, its ancestors and descendants are rejected', () async {
    await marker(roaming);
    await expectLater(
      prepare(roaming.path),
      throwsA(isA<OculumSmokeStorageException>()),
    );
    await marker(fixture);
    await expectLater(
      prepare(fixture.path),
      throwsA(isA<OculumSmokeStorageException>()),
    );
    final descendant = Directory(
      '${roaming.path}${Platform.pathSeparator}copy',
    );
    await marker(descendant);
    await expectLater(
      prepare(descendant.path),
      throwsA(isA<OculumSmokeStorageException>()),
    );
    expect(SharedPreferencesStorePlatform.instance, same(preferences));
    expect(
      await Directory('${root.path}${Platform.pathSeparator}support').exists(),
      isFalse,
    );
  });

  test(
    'unsupported backend fails before directory or known-folder access',
    () async {
      await expectLater(
        prepareOculumSmokeWindowsStorage(
          root.path,
          originalPaths: _UnsupportedPaths(),
          originalPreferences: preferences,
          originalAsyncPreferences: asyncPreferences,
        ),
        throwsA(
          isA<OculumSmokeStorageException>().having(
            (error) => error.code,
            'code',
            'unsupported_backend',
          ),
        ),
      );
      await expectLater(
        prepareOculumSmokeWindowsStorage(
          root.path,
          originalPaths: paths,
          originalPreferences: preferences,
          originalAsyncPreferences: null,
        ),
        throwsA(isA<OculumSmokeStorageException>()),
      );
      expect(paths.knownFolderReads, 0);
      expect(
        await Directory(
          '${root.path}${Platform.pathSeparator}support',
        ).exists(),
        isFalse,
      );
    },
  );

  test('Windows backends read and persist only a synthetic copy', () async {
    final support = Directory('${root.path}${Platform.pathSeparator}support');
    await support.create();
    final copy = File(
      '${support.path}${Platform.pathSeparator}shared_preferences.json',
    );
    final normalKey = 'flutter.synthetic_save';
    final testKey = 'flutter.synthetic_save__test';
    await copy.writeAsString(
      jsonEncode(<String, Object>{
        normalKey: 'normal-copy',
        testKey: 'test-copy',
      }),
    );
    final liveSupport = Directory(
      '${roaming.path}${Platform.pathSeparator}original-app',
    );
    await liveSupport.create();
    final live = File(
      '${liveSupport.path}${Platform.pathSeparator}shared_preferences.json',
    );
    await live.writeAsString('synthetic-original-must-stay-byte-identical');
    final originalBytes = await live.readAsBytes();

    final installation = await prepare();
    expect(PathProviderPlatform.instance, same(paths));
    expect(await installation.preferences.getAll(), <String, Object>{
      normalKey: 'normal-copy',
      testKey: 'test-copy',
    });
    await installation.preferences.setValue(
      'String',
      normalKey,
      'changed-copy',
    );
    expect(
      await installation.asyncPreferences.getString(
        normalKey,
        const SharedPreferencesOptions(),
      ),
      'changed-copy',
    );
    await installation.asyncPreferences.setString(
      'synthetic_async',
      'async-copy',
      const SharedPreferencesOptions(),
    );
    final written =
        jsonDecode(await copy.readAsString()) as Map<String, dynamic>;
    expect(written[normalKey], 'changed-copy');
    expect(written[testKey], 'test-copy');
    expect(written['synthetic_async'], 'async-copy');
    expect(await live.readAsBytes(), originalBytes);
    expect(
      oculumProfiledStorageKey('synthetic_save'),
      oculumSaveProfile.isEmpty
          ? 'synthetic_save'
          : 'synthetic_save__$oculumSaveProfile',
    );
    expect(
      oculumProfileFileSuffix,
      oculumSaveProfile.isEmpty ? '' : '_$oculumSaveProfile',
    );
  });

  test(
    'installation checks every backend identity before any global swap',
    () async {
      final installation = await prepare();
      SharedPreferencesAsyncPlatform.instance = SharedPreferencesAsyncWindows();
      expect(
        installation.install,
        throwsA(
          isA<OculumSmokeStorageException>().having(
            (error) => error.code,
            'code',
            'backend_changed',
          ),
        ),
      );
      expect(PathProviderPlatform.instance, same(paths));
      expect(SharedPreferencesStorePlatform.instance, same(preferences));
      expect(HttpOverrides.current, same(oldHttp));
    },
  );

  test(
    'installed providers route every directory inside the copy and deny HTTP',
    () async {
      final installation = await prepare();
      installation.install();
      expect(PathProviderPlatform.instance, same(installation.paths));
      expect(
        SharedPreferencesStorePlatform.instance,
        same(installation.preferences),
      );
      expect(
        SharedPreferencesAsyncPlatform.instance,
        same(installation.asyncPreferences),
      );
      // ignore: invalid_use_of_visible_for_testing_member
      expect(installation.preferences.pathProvider, same(installation.paths));
      // ignore: invalid_use_of_visible_for_testing_member
      expect(
        installation.asyncPreferences.pathProvider,
        same(installation.paths),
      );
      final isolatedPaths = await Future.wait(<Future<String?>>[
        installation.paths.getApplicationSupportPath(),
        installation.paths.getApplicationCachePath(),
        installation.paths.getApplicationDocumentsPath(),
        installation.paths.getTemporaryPath(),
        installation.paths.getDownloadsPath(),
        installation.paths.getLibraryPath(),
        installation.paths.getExternalStoragePath(),
      ]);
      for (final path in isolatedPaths) {
        expect(
          path,
          startsWith('${installation.root}${Platform.pathSeparator}'),
        );
      }
      expect(
        () => OculumSmokeOfflineHttpOverrides().createHttpClient(null),
        throwsA(
          isA<OculumSmokeStorageException>().having(
            (error) => error.code,
            'code',
            'network_disabled',
          ),
        ),
      );
      await expectLater(
        installation.paths.getPath('unsupported-folder'),
        throwsA(isA<OculumSmokeStorageException>()),
      );
    },
  );

  test('metadata receipt records readiness without names or values', () async {
    final installation = await prepare();
    installation.install();
    await recordOculumSmokeStatusPlatform(
      'bootstrap_validated',
      <String, Object?>{
        'edition': 'normal',
        'saveProfile': '',
        'preferenceKeyCount': 0,
        'firstFrameSeen': false,
        'localSaveLoadVerified': false,
      },
    );
    await recordOculumSmokeStatusPlatform('first_frame', <String, Object?>{
      'viewCount': 1,
      'physicalWidth': 1280.0,
      'physicalHeight': 720.0,
      'devicePixelRatio': 1.0,
      'firstFrameSeen': true,
    });
    final statusFile = File(
      '${installation.root}${Platform.pathSeparator}SMOKE-STATUS.json',
    );
    final status =
        jsonDecode(await statusFile.readAsString()) as Map<String, dynamic>;
    expect(status['phase'], 'first_frame');
    expect(status['firstFrameSeen'], isTrue);
    expect(status['localSaveLoadVerified'], isFalse);
    expect(status['preferenceKeyCount'], 0);
    expect(status['offline'], isTrue);
    expect(status['paths'], hasLength(7));
    expect(
      () => recordOculumSmokeStatusPlatform('first_frame', <String, Object?>{
        'preferenceValues': 'must-be-rejected',
      }),
      throwsA(isA<OculumSmokeStorageException>()),
    );
    expect(
      await statusFile.readAsString(),
      isNot(contains('must-be-rejected')),
    );
  });

  test(
    'async backend rejects paths and the unisolated plugin reload hook',
    () async {
      final installation = await prepare();
      expect(
        () => installation.asyncPreferences.getString(
          'synthetic',
          const SharedPreferencesWindowsOptions(fileName: '../outside'),
        ),
        throwsA(isA<OculumSmokeStorageException>()),
      );
      // ignore: invalid_use_of_visible_for_testing_member
      expect(
        () => installation.asyncPreferences.reload(
          const SharedPreferencesWindowsOptions(),
        ),
        throwsA(isA<OculumSmokeStorageException>()),
      );
    },
  );

  test('a linked entry inside an otherwise marked copy is rejected', () async {
    final link = Link('${root.path}${Platform.pathSeparator}linked-original');
    try {
      await link.create(roaming.path);
    } on FileSystemException {
      // Windows installations may require Developer Mode for directory symlinks.
      markTestSkipped(
        'Directory symlink creation is unavailable on this host.',
      );
      return;
    }
    await expectLater(prepare(), throwsA(isA<OculumSmokeStorageException>()));
    expect(SharedPreferencesStorePlatform.instance, same(preferences));
  });
}
