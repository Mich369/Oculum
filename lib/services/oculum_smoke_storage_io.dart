import 'dart:convert';
import 'dart:io';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:path_provider_windows/path_provider_windows.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';
import 'package:shared_preferences_windows/shared_preferences_windows.dart';

import 'oculum_smoke_storage_policy.dart';

// Win32 KNOWNFOLDERIDs from path_provider_windows 2.3.0 src/folders.dart:
// WindowsKnownFolder.RoamingAppData/LocalAppData/Documents/Downloads.
// Its non-FFI export intentionally contains no getters, so retain these stable
// Windows SDK IDs without importing a private package implementation.
const _smokeRoamingAppDataFolderId = '{3EB685DB-65F9-4CF6-A03A-E3EF65729F3D}';
const _smokeLocalAppDataFolderId = '{F1B32785-6FBA-4FCF-9D55-7B8E7F157091}';
const _smokeDocumentsFolderId = '{FDD39AD0-238F-46AF-ADB4-6C85480369C7}';
const _smokeDownloadsFolderId = '{374DE290-123F-4565-9164-39C4925E467B}';

OculumSmokeWindowsInstallation? _activeSmokeInstallation;
Map<String, Object?> _smokeStatus = <String, Object?>{};
Future<void> _smokeStatusWriteTail = Future<void>.value();

Future<void> configureOculumSmokeStoragePlatform(String root) async {
  // In particular, never invoke Windows FFI on Android, Linux, or macOS.
  if (!Platform.isWindows) {
    throw const OculumSmokeStorageException('unsupported_platform');
  }
  final installation = await prepareOculumSmokeWindowsStorage(
    root,
    originalPaths: PathProviderPlatform.instance,
    originalPreferences: SharedPreferencesStorePlatform.instance,
    originalAsyncPreferences: SharedPreferencesAsyncPlatform.instance,
  );
  installation.install();
  _activeSmokeInstallation = installation;
}

/// Serializes a strictly limited metadata receipt inside the validated root.
Future<void> recordOculumSmokeStatusPlatform(
  String phase,
  Map<String, Object?> metadata,
) {
  final installation = _activeSmokeInstallation;
  if (installation == null) {
    throw const OculumSmokeStorageException('storage_not_configured');
  }
  const phases = <String>{
    'bootstrap_validated',
    'preferences_ready',
    'first_frame',
    'framework_error',
  };
  const allowedFields = <String>{
    'edition',
    'saveProfile',
    'preferenceKeyCount',
    'localSaveLoadVerified',
    'firstFrameSeen',
    'frameworkErrorCount',
    'lastFrameworkErrorType',
    'viewCount',
    'physicalWidth',
    'physicalHeight',
    'devicePixelRatio',
  };
  if (!phases.contains(phase) ||
      metadata.keys.any((key) => !allowedFields.contains(key))) {
    throw const OculumSmokeStorageException('invalid_status_metadata');
  }
  final values = Map<String, Object?>.from(metadata);
  final write = _smokeStatusWriteTail.then((_) async {
    _smokeStatus = <String, Object?>{
      ..._smokeStatus,
      ...values,
      'schemaVersion': 1,
      'phase': phase,
      'updatedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'offline': true,
      'paths': <String, String>{
        for (final name in OculumSmokeWindowsPaths.subdirectories)
          name: _child(installation.root, name),
      },
    };
    final target = File(_child(installation.root, 'SMOKE-STATUS.json'));
    final temporary = File('${target.path}.tmp-$pid');
    await temporary.writeAsString(jsonEncode(_smokeStatus), flush: true);
    await temporary.rename(target.path);
  });
  // Retain serialization after an error; the caller still receives that error.
  _smokeStatusWriteTail = write.then<void>((_) {}, onError: (Object error) {});
  return write;
}

/// Validates only the marked copy and Windows known-folder metadata.
/// Does not read preference/save contents or mutate the registered backends.
/// The caller creating the copy must use real copies, never NTFS hardlinks.
Future<OculumSmokeWindowsInstallation> prepareOculumSmokeWindowsStorage(
  String requestedRoot, {
  required PathProviderPlatform originalPaths,
  required SharedPreferencesStorePlatform originalPreferences,
  required SharedPreferencesAsyncPlatform? originalAsyncPreferences,
}) async {
  if (originalPaths is! PathProviderWindows ||
      originalPreferences is! SharedPreferencesWindows ||
      originalAsyncPreferences is! SharedPreferencesAsyncWindows) {
    throw const OculumSmokeStorageException('unsupported_backend');
  }
  final rootDirectory = Directory(requestedRoot);
  if (!rootDirectory.isAbsolute ||
      requestedRoot.contains('\u0000') ||
      requestedRoot.replaceAll('\\', '/').split('/').contains('..') ||
      requestedRoot.startsWith(r'\\?\') ||
      requestedRoot.startsWith(r'\\.\')) {
    throw const OculumSmokeStorageException('invalid_root');
  }
  if (await FileSystemEntity.type(requestedRoot, followLinks: false) !=
      FileSystemEntityType.directory) {
    throw const OculumSmokeStorageException('root_not_plain_directory');
  }
  final root = await rootDirectory.resolveSymbolicLinks();
  final marker = File(_child(root, oculumSmokeStorageMarker));
  if (await FileSystemEntity.type(marker.path, followLinks: false) !=
          FileSystemEntityType.file ||
      (await marker.stat()).size != oculumSmokeStorageMarkerContents.length ||
      await marker.readAsString() != oculumSmokeStorageMarkerContents) {
    throw const OculumSmokeStorageException('missing_or_invalid_marker');
  }

  // The real support/cache folders are descendants of these known folders.
  // getPath reads SHGetKnownFolderPath; unlike getApplicationSupportPath it
  // does not create the real application's directory during validation.
  for (final folder in <String>[
    _smokeRoamingAppDataFolderId,
    _smokeLocalAppDataFolderId,
  ]) {
    final actualPath = _requireProtectedWindowsPath(
      await originalPaths.getPath(folder),
    );
    final protected = await Directory(actualPath).resolveSymbolicLinks();
    if (_containsPath(root, protected) || _containsPath(protected, root)) {
      throw const OculumSmokeStorageException('overlaps_live_appdata');
    }
  }

  // Reject junctions/symlinks anywhere in the supplied copy so subsequent
  // application blob/journal writes cannot traverse out of this root.
  await for (final entity in Directory(
    root,
  ).list(recursive: true, followLinks: false)) {
    final type = await FileSystemEntity.type(entity.path, followLinks: false);
    if (type != FileSystemEntityType.file &&
        type != FileSystemEntityType.directory) {
      throw const OculumSmokeStorageException('linked_or_special_entry');
    }
    if (!_containsPath(root, await entity.resolveSymbolicLinks())) {
      throw const OculumSmokeStorageException('entry_outside_root');
    }
  }

  for (final child in OculumSmokeWindowsPaths.subdirectories) {
    await Directory(_child(root, child)).create();
  }
  final paths = OculumSmokeWindowsPaths(root);
  final preferences = SharedPreferencesWindows();
  // The federated backend owns its own provider; overriding only the global
  // PathProviderPlatform would leave real preferences exposed.
  // ignore: invalid_use_of_visible_for_testing_member
  preferences.pathProvider = paths;
  final asyncPreferences = OculumSmokeSharedPreferencesAsyncWindows();
  // ignore: invalid_use_of_visible_for_testing_member
  asyncPreferences.pathProvider = paths;
  return OculumSmokeWindowsInstallation._(
    root: root,
    paths: paths,
    preferences: preferences,
    asyncPreferences: asyncPreferences,
    originalPaths: originalPaths,
    originalPreferences: originalPreferences,
    originalAsyncPreferences: originalAsyncPreferences,
  );
}

class OculumSmokeWindowsInstallation {
  OculumSmokeWindowsInstallation._({
    required this.root,
    required this.paths,
    required this.preferences,
    required this.asyncPreferences,
    required this.originalPaths,
    required this.originalPreferences,
    required this.originalAsyncPreferences,
  });

  final String root;
  final OculumSmokeWindowsPaths paths;
  final SharedPreferencesWindows preferences;
  final SharedPreferencesAsyncWindows asyncPreferences;
  final PathProviderPlatform originalPaths;
  final SharedPreferencesStorePlatform originalPreferences;
  final SharedPreferencesAsyncPlatform originalAsyncPreferences;

  void install() {
    // Validate all identities before the first swap. A late backend change
    // cannot produce a partially isolated application.
    if (!identical(PathProviderPlatform.instance, originalPaths) ||
        !identical(
          SharedPreferencesStorePlatform.instance,
          originalPreferences,
        ) ||
        !identical(
          SharedPreferencesAsyncPlatform.instance,
          originalAsyncPreferences,
        )) {
      throw const OculumSmokeStorageException('backend_changed');
    }
    PathProviderPlatform.instance = paths;
    SharedPreferencesStorePlatform.instance = preferences;
    SharedPreferencesAsyncPlatform.instance = asyncPreferences;
    HttpOverrides.global = OculumSmokeOfflineHttpOverrides();
    _activeSmokeInstallation = this;
    _smokeStatus = <String, Object?>{};
  }
}

/// No method can fall back to the real Windows provider/FFI after installation.
class OculumSmokeWindowsPaths extends PathProviderWindows {
  OculumSmokeWindowsPaths(this.root);

  static const subdirectories = <String>[
    'support',
    'cache',
    'temporary',
    'documents',
    'downloads',
    'library',
    'external',
  ];
  final String root;

  @override
  Future<String?> getApplicationSupportPath() async => _child(root, 'support');
  @override
  Future<String?> getApplicationCachePath() async => _child(root, 'cache');
  @override
  Future<String?> getTemporaryPath() async => _child(root, 'temporary');
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      _child(root, 'documents');
  @override
  Future<String?> getDownloadsPath() async => _child(root, 'downloads');
  @override
  Future<String?> getLibraryPath() async => _child(root, 'library');
  @override
  Future<String?> getExternalStoragePath() async => _child(root, 'external');
  @override
  Future<List<String>?> getExternalCachePaths() async => <String>[
    _child(root, 'cache'),
  ];
  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async => <String>[_child(root, 'external')];
  @override
  Future<String> getPath(String folderID) async {
    if (folderID == _smokeRoamingAppDataFolderId) {
      return _child(root, 'support');
    }
    if (folderID == _smokeLocalAppDataFolderId) {
      return _child(root, 'cache');
    }
    if (folderID == _smokeDocumentsFolderId) {
      return _child(root, 'documents');
    }
    if (folderID == _smokeDownloadsFolderId) {
      return _child(root, 'downloads');
    }
    throw const OculumSmokeStorageException('unsupported_known_folder');
  }
}

/// Reject options that could escape the copy, including the plugin's testing
/// reload hook which otherwise constructs its own live Windows provider.
final class OculumSmokeSharedPreferencesAsyncWindows
    extends SharedPreferencesAsyncWindows {
  void _checkOptions(SharedPreferencesOptions options) {
    if (SharedPreferencesWindowsOptions.fromSharedPreferencesOptions(
          options,
        ).fileName !=
        'shared_preferences') {
      throw const OculumSmokeStorageException('unsupported_preferences_file');
    }
  }

  @override
  Future<void> reload(SharedPreferencesWindowsOptions options) {
    throw const OculumSmokeStorageException('unsupported_preferences_reload');
  }

  @override
  Future<Set<String>> getKeys(
    GetPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) {
    _checkOptions(options);
    return super.getKeys(parameters, options);
  }

  @override
  Future<Map<String, Object>> getPreferences(
    GetPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) {
    _checkOptions(options);
    return super.getPreferences(parameters, options);
  }

  @override
  Future<void> clear(
    ClearPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) {
    _checkOptions(options);
    return super.clear(parameters, options);
  }

  @override
  Future<void> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) {
    _checkOptions(options);
    return super.setString(key, value, options);
  }

  @override
  Future<String?> getString(String key, SharedPreferencesOptions options) {
    _checkOptions(options);
    return super.getString(key, options);
  }

  @override
  Future<void> setBool(
    String key,
    bool value,
    SharedPreferencesOptions options,
  ) {
    _checkOptions(options);
    return super.setBool(key, value, options);
  }

  @override
  Future<bool?> getBool(String key, SharedPreferencesOptions options) {
    _checkOptions(options);
    return super.getBool(key, options);
  }

  @override
  Future<void> setDouble(
    String key,
    double value,
    SharedPreferencesOptions options,
  ) {
    _checkOptions(options);
    return super.setDouble(key, value, options);
  }

  @override
  Future<double?> getDouble(String key, SharedPreferencesOptions options) {
    _checkOptions(options);
    return super.getDouble(key, options);
  }

  @override
  Future<void> setInt(String key, int value, SharedPreferencesOptions options) {
    _checkOptions(options);
    return super.setInt(key, value, options);
  }

  @override
  Future<int?> getInt(String key, SharedPreferencesOptions options) {
    _checkOptions(options);
    return super.getInt(key, options);
  }

  @override
  Future<void> setStringList(
    String key,
    List<String> value,
    SharedPreferencesOptions options,
  ) {
    _checkOptions(options);
    return super.setStringList(key, value, options);
  }

  @override
  Future<List<String>?> getStringList(
    String key,
    SharedPreferencesOptions options,
  ) {
    _checkOptions(options);
    return super.getStringList(key, options);
  }
}

class OculumSmokeOfflineHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw const OculumSmokeStorageException('network_disabled');
  }
}

String _child(String root, String name) =>
    '$root${Platform.pathSeparator}$name';

String _requireProtectedWindowsPath(String? value) {
  if (value == null || value.isEmpty) {
    throw const OculumSmokeStorageException('unknown_protected_directory');
  }
  return value;
}

bool _containsPath(String parent, String child) {
  String normalize(String value) {
    final normalized = value.replaceAll('\\', '/').toLowerCase();
    return normalized.endsWith('/')
        ? normalized.substring(0, normalized.length - 1)
        : normalized;
  }

  final base = normalize(parent);
  final candidate = normalize(child);
  return candidate == base || candidate.startsWith('$base/');
}
