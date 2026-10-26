import 'package:shared_preferences/shared_preferences.dart';
import 'oculum_save_profile.dart';

const oculumCumulativeLogAsset = 'assets/update/oculum_cumulative_log.md';
const oculumCumulativeLogBaseline = 'b917217d98d16861a5bbaf1706d78825d883c970';

String get oculumUpdateLogSeenKey =>
    oculumProfiledStorageKey('oculum_update_log_seen_commit_v1');

bool oculumShouldShowVersionLog(
  SharedPreferences prefs,
  String version, {
  String? storageKey,
}) =>
    version.trim().isNotEmpty &&
    prefs.getString(storageKey ?? oculumUpdateLogSeenKey) != version;

Future<void> oculumRememberVersionLog(
  SharedPreferences prefs,
  String version, {
  String? storageKey,
}) async {
  if (version.trim().isNotEmpty) {
    await prefs.setString(storageKey ?? oculumUpdateLogSeenKey, version);
  }
}

String oculumReadableUpdateLog(String markdown) => markdown
    .replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^\)]+\)'),
      (match) => match.group(1)!,
    )
    .replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '')
    .replaceAll('`', '')
    .trim();
