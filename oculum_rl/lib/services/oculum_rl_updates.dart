import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'oculum_rl_release.dart';
import 'oculum_rl_update_stub.dart'
    if (dart.library.io) 'oculum_rl_update_native.dart'
    as platform;
import 'oculum_save_profile.dart';

void acknowledgeOculumRlUpdate() => platform.acknowledgeOculumRlUpdate();
void exitForOculumRlUpdate() => platform.exitForOculumRlUpdate();

class OculumRlUpdates extends ChangeNotifier {
  static final _current = OculumRlVersion.parse(oculumRlVersion);
  static final _pref = oculumProfiledStorageKey('oculum_rl_automatic_updates');

  bool get supported =>
      platform.supportsOculumRlUpdates &&
      _current != null &&
      (oculumSaveProfile.isEmpty || oculumSaveProfile == 'test');

  OculumRlEdition get edition => oculumSaveProfile == 'test'
      ? OculumRlEdition.test
      : OculumRlEdition.normal;

  SharedPreferences? _preferences;
  Timer? _timer;
  bool _disposed = false;
  bool automatic = true;
  bool checking = false;
  OculumRlVersion? ready;
  String? message;

  void start(SharedPreferences? preferences) {
    if (!supported || _timer != null) return;
    _preferences = preferences;
    automatic = preferences?.get(_pref) != false;
    if (automatic) unawaited(check());
    _timer = Timer.periodic(const Duration(hours: 6), (_) {
      if (automatic) unawaited(check());
    });
  }

  void setAutomatic(bool value) {
    automatic = value;
    final preferences = _preferences;
    if (preferences != null) {
      unawaited(preferences.setBool(_pref, value));
    }
    notifyListeners();
    if (value) unawaited(check());
  }

  Future<void> check() async {
    if (!supported || checking || _disposed) return;
    checking = true;
    message = 'Controllo la disponibilità e preparo il pacchetto…';
    notifyListeners();
    try {
      ready = await platform.prepareOculumRlUpdate(_current!, edition);
      message = ready == null
          ? 'Hai già la versione più recente.'
          : 'Versione $ready pronta.';
    } on Exception {
      message = 'Aggiornamento momentaneamente non disponibile. Puoi giocare e riprovare più tardi.';
    } on StateError {
      message = 'Il pacchetto non può essere preparato. Puoi continuare con questa versione.';
    } finally {
      checking = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> launch() async {
    final version = ready;
    if (version == null) return false;
    try {
      return await platform.startOculumRlUpdate(version, edition);
    } on Exception {
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
