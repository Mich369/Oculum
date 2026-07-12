import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String oculumOAuthRedirectUrl = String.fromEnvironment(
  'OculumOAuthRedirectUrl',
  defaultValue: '',
);
const bool _googleOAuthConfigured = bool.fromEnvironment(
  'OculumGoogleOAuthEnabled',
  defaultValue: false,
);
const bool _appleOAuthConfigured = bool.fromEnvironment(
  'OculumAppleOAuthEnabled',
  defaultValue: false,
);

enum OculumAuthProvider { google, apple }

enum OculumBackendAuthEventType {
  signedIn,
  signedOut,
  tokenRefreshed,
  userUpdated,
  userDeleted,
}

class OculumBackendUser {
  const OculumBackendUser({required this.id, this.provider});

  final String id;
  final String? provider;
}

class OculumBackendAuthEvent {
  const OculumBackendAuthEvent(this.type, {this.user});

  final OculumBackendAuthEventType type;
  final OculumBackendUser? user;
}

abstract class OculumAuthBackend {
  OculumBackendUser? get currentUser;
  Stream<OculumBackendAuthEvent> get events;

  Future<bool> startOAuth(
    OculumAuthProvider provider, {
    required String? redirectTo,
  });

  Future<void> signOut();
}

class SupabaseOculumAuthBackend implements OculumAuthBackend {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  OculumBackendUser? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null || _client.auth.currentSession == null) return null;
    return OculumBackendUser(
      id: user.id,
      provider: user.appMetadata['provider']?.toString(),
    );
  }

  @override
  Stream<OculumBackendAuthEvent> get events =>
      _client.auth.onAuthStateChange.map((data) {
        final user = data.session?.user;
        final mappedUser = user == null
            ? null
            : OculumBackendUser(
                id: user.id,
                provider: user.appMetadata['provider']?.toString(),
              );
        final type = switch (data.event) {
          AuthChangeEvent.signedIn => OculumBackendAuthEventType.signedIn,
          AuthChangeEvent.tokenRefreshed =>
            OculumBackendAuthEventType.tokenRefreshed,
          AuthChangeEvent.userUpdated => OculumBackendAuthEventType.userUpdated,
          AuthChangeEvent.signedOut => OculumBackendAuthEventType.signedOut,
          _ =>
            mappedUser == null
                ? OculumBackendAuthEventType.signedOut
                : OculumBackendAuthEventType.userUpdated,
        };
        return OculumBackendAuthEvent(type, user: mappedUser);
      });

  @override
  Future<bool> startOAuth(
    OculumAuthProvider provider, {
    required String? redirectTo,
  }) {
    return _client.auth.signInWithOAuth(
      provider == OculumAuthProvider.apple
          ? OAuthProvider.apple
          : OAuthProvider.google,
      redirectTo: redirectTo,
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
      scopes: provider == OculumAuthProvider.apple ? 'name email' : null,
    );
  }

  @override
  Future<void> signOut() => _client.auth.signOut(scope: SignOutScope.global);
}

class OculumAuthState {
  const OculumAuthState({
    required this.isAuthenticated,
    required this.isGuest,
    required this.isLoading,
    required this.userId,
    required this.provider,
    this.message,
    this.errorMessage,
    this.isOffline = false,
  });

  final bool isAuthenticated;
  final bool isGuest;
  final bool isLoading;
  final String? userId;
  final String? provider;
  final String? message;
  final String? errorMessage;
  final bool isOffline;

  bool get canSyncToCloud => isAuthenticated && !isGuest;

  String get displayLabel {
    if (isAuthenticated) return 'Accesso effettuato';
    if (isGuest) return 'Modalità locale';
    return 'Accesso non effettuato';
  }

  String get providerLabel => switch (provider) {
    'google' => 'Google',
    'apple' => 'Apple',
    'guest' => 'Guest',
    _ => 'Nessuno',
  };
}

class OculumAuthService extends ChangeNotifier {
  OculumAuthService._({
    OculumAuthBackend? backend,
    Future<bool> Function()? connectivityCheck,
    bool? googleConfigured,
    bool? appleConfigured,
    Duration oauthTimeout = const Duration(minutes: 2),
    bool requireOAuthRedirect = true,
  }) : _backend = backend,
       _connectivityCheck = connectivityCheck ?? _hasNetworkConnection,
       _googleConfiguredOverride = googleConfigured,
       _appleConfiguredOverride = appleConfigured,
       _oauthTimeout = oauthTimeout,
       _requireOAuthRedirect = requireOAuthRedirect;

  static final OculumAuthService instance = OculumAuthService._();

  @visibleForTesting
  factory OculumAuthService.forTesting({
    OculumAuthBackend? backend,
    required Future<bool> Function() connectivityCheck,
    bool googleConfigured = true,
    bool appleConfigured = true,
    Duration oauthTimeout = const Duration(milliseconds: 100),
  }) {
    return OculumAuthService._(
      backend: backend,
      connectivityCheck: connectivityCheck,
      googleConfigured: googleConfigured,
      appleConfigured: appleConfigured,
      oauthTimeout: oauthTimeout,
      requireOAuthRedirect: false,
    );
  }

  static const _guestModePrefsKey = 'oculum.auth.guest_mode';
  static const _userIdPrefsKey = 'oculum.auth.user_id';
  static const _providerPrefsKey = 'oculum.auth.provider';

  OculumAuthBackend? _backend;
  final Future<bool> Function() _connectivityCheck;
  final bool? _googleConfiguredOverride;
  final bool? _appleConfiguredOverride;
  final Duration _oauthTimeout;
  final bool _requireOAuthRedirect;
  StreamSubscription<OculumBackendAuthEvent>? _authSubscription;
  Timer? _oauthTimer;
  bool _operationInProgress = false;
  OculumAuthProvider? _lastAttemptedProvider;

  final ValueNotifier<OculumAuthState> stateNotifier = ValueNotifier(
    const OculumAuthState(
      isAuthenticated: false,
      isGuest: true,
      isLoading: false,
      userId: null,
      provider: 'guest',
      message: 'Gioca e salva sul dispositivo.',
    ),
  );

  OculumAuthState get state => stateNotifier.value;
  bool get isSupabaseReady => _backend != null;
  bool get googleConfigured =>
      _googleConfiguredOverride ?? _googleOAuthConfigured;
  bool get appleConfigured => _appleConfiguredOverride ?? _appleOAuthConfigured;

  bool isProviderSupported(OculumAuthProvider provider) {
    if (provider == OculumAuthProvider.google) return googleConfigured;
    return appleConfigured;
  }

  String providerAvailabilityLabel(OculumAuthProvider provider) {
    if (!isSupabaseReady) return 'Supabase non configurato';
    if (!isProviderSupported(provider)) return 'Prossimamente';
    return 'Disponibile';
  }

  Future<void> initialize({bool supabaseReady = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (supabaseReady && _backend == null) {
      _backend = SupabaseOculumAuthBackend();
    }
    await _authSubscription?.cancel();
    _authSubscription = _backend?.events.listen(
      _handleBackendEvent,
      onError: (_) => _showRecoverableError(
        'Sessione non disponibile. Puoi continuare in modalità locale.',
      ),
    );

    final currentUser = _backend?.currentUser;
    if (currentUser != null) {
      await _applySignedIn(currentUser);
      return;
    }

    final guestMode = prefs.getBool(_guestModePrefsKey) ?? true;
    _setState(
      OculumAuthState(
        isAuthenticated: false,
        isGuest: guestMode,
        isLoading: false,
        userId: null,
        provider: guestMode ? 'guest' : prefs.getString(_providerPrefsKey),
        message: _backend == null
            ? 'Funzioni online non disponibili. I salvataggi locali restano attivi.'
            : 'Accedi per usare le funzioni online.',
      ),
    );
  }

  Future<bool> signInWithGoogle({String? redirectTo}) =>
      _signIn(OculumAuthProvider.google, redirectTo: redirectTo);

  Future<bool> signInWithApple({String? redirectTo}) =>
      _signIn(OculumAuthProvider.apple, redirectTo: redirectTo);

  Future<bool> retryLastSignIn() async {
    final provider = _lastAttemptedProvider;
    if (provider == null) return false;
    return _signIn(provider);
  }

  Future<bool> _signIn(
    OculumAuthProvider provider, {
    String? redirectTo,
  }) async {
    if (_operationInProgress) return false;
    _lastAttemptedProvider = provider;
    if (_backend == null) {
      _showRecoverableError(
        'Supabase non è configurato. Puoi continuare in modalità locale.',
      );
      return false;
    }
    if (!isProviderSupported(provider)) {
      _showRecoverableError(
        '${_providerName(provider)} sarà disponibile prossimamente.',
      );
      return false;
    }
    final effectiveRedirect = redirectTo ?? oculumOAuthRedirectUrl;
    if (_requireOAuthRedirect && !kIsWeb && effectiveRedirect.isEmpty) {
      _showRecoverableError(
        '${_providerName(provider)} richiede ancora la configurazione OAuth.',
      );
      return false;
    }
    _operationInProgress = true;
    if (!await _connectivityCheck()) {
      _operationInProgress = false;
      _setState(
        OculumAuthState(
          isAuthenticated: state.isAuthenticated,
          isGuest: state.isGuest,
          isLoading: false,
          userId: state.userId,
          provider: state.provider,
          isOffline: true,
          errorMessage: 'Connessione assente. Controlla la rete e riprova.',
        ),
      );
      return false;
    }

    _setState(
      OculumAuthState(
        isAuthenticated: state.isAuthenticated,
        isGuest: state.isGuest,
        isLoading: true,
        userId: state.userId,
        provider: _providerId(provider),
        message: 'Completa l’accesso nel browser di sistema.',
      ),
    );
    try {
      final launched = await _backend!
          .startOAuth(provider, redirectTo: kIsWeb ? null : effectiveRedirect)
          .timeout(const Duration(seconds: 15));
      if (!launched) {
        _finishOperationWithError('Impossibile aprire il browser di accesso.');
        return false;
      }
      _oauthTimer?.cancel();
      _oauthTimer = Timer(_oauthTimeout, () {
        if (_operationInProgress) {
          _finishOperationWithError(
            'Accesso non completato o annullato. Puoi riprovare.',
          );
        }
      });
      return true;
    } on TimeoutException {
      _finishOperationWithError(
        'Il servizio di accesso non risponde. Riprova.',
      );
    } on AuthException catch (error) {
      _finishOperationWithError(_friendlyAuthError(error.message));
    } catch (_) {
      _finishOperationWithError('Accesso non riuscito. Riprova più tardi.');
    }
    return false;
  }

  Future<bool> continueAsGuest() async {
    _cancelPendingOperation();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestModePrefsKey, true);
    await prefs.remove(_userIdPrefsKey);
    await prefs.remove(_providerPrefsKey);
    _setState(
      const OculumAuthState(
        isAuthenticated: false,
        isGuest: true,
        isLoading: false,
        userId: null,
        provider: 'guest',
        message:
            'Modalità locale attiva. Nessun salvataggio è stato modificato.',
      ),
    );
    return true;
  }

  Future<bool> signOut() async {
    if (_operationInProgress) return false;
    _operationInProgress = true;
    _setState(
      OculumAuthState(
        isAuthenticated: state.isAuthenticated,
        isGuest: state.isGuest,
        isLoading: true,
        userId: state.userId,
        provider: state.provider,
        message: 'Disconnessione in corso…',
      ),
    );
    try {
      await _backend?.signOut().timeout(const Duration(seconds: 10));
    } catch (_) {
      // Local cleanup must remain available when the remote endpoint is down.
    }
    await continueAsGuest();
    return true;
  }

  void cancelPendingSignIn() {
    if (!_operationInProgress) return;
    _cancelPendingOperation();
    _showRecoverableError('Accesso annullato. Puoi continuare in locale.');
  }

  Future<void> _handleBackendEvent(OculumBackendAuthEvent event) async {
    switch (event.type) {
      case OculumBackendAuthEventType.signedIn:
      case OculumBackendAuthEventType.tokenRefreshed:
      case OculumBackendAuthEventType.userUpdated:
        final user = event.user ?? _backend?.currentUser;
        if (user != null) await _applySignedIn(user);
      case OculumBackendAuthEventType.signedOut:
      case OculumBackendAuthEventType.userDeleted:
        await continueAsGuest();
    }
  }

  Future<void> _applySignedIn(OculumBackendUser user) async {
    _cancelPendingOperation();
    final provider = user.provider ?? _providerId(_lastAttemptedProvider);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestModePrefsKey, false);
    await prefs.setString(_userIdPrefsKey, user.id);
    if (provider != null) await prefs.setString(_providerPrefsKey, provider);
    _setState(
      OculumAuthState(
        isAuthenticated: true,
        isGuest: false,
        isLoading: false,
        userId: user.id,
        provider: provider,
        message:
            'Sessione attiva. I salvataggi locali non vengono sincronizzati senza conferma.',
      ),
    );
  }

  void _finishOperationWithError(String message) {
    _cancelPendingOperation();
    _showRecoverableError(message);
  }

  void _cancelPendingOperation() {
    _operationInProgress = false;
    _oauthTimer?.cancel();
    _oauthTimer = null;
  }

  void _showRecoverableError(String message) {
    _setState(
      OculumAuthState(
        isAuthenticated: state.isAuthenticated,
        isGuest: state.isGuest,
        isLoading: false,
        userId: state.userId,
        provider: state.provider,
        errorMessage: message,
      ),
    );
  }

  void _setState(OculumAuthState next) {
    stateNotifier.value = next;
    notifyListeners();
  }

  static String _providerName(OculumAuthProvider provider) =>
      provider == OculumAuthProvider.apple ? 'Apple' : 'Google';

  static String? _providerId(OculumAuthProvider? provider) =>
      switch (provider) {
        OculumAuthProvider.google => 'google',
        OculumAuthProvider.apple => 'apple',
        null => null,
      };

  static String _friendlyAuthError(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('cancel')) return 'Accesso annullato.';
    if (normalized.contains('provider') || normalized.contains('enabled')) {
      return 'Provider non configurato in Supabase.';
    }
    if (normalized.contains('network') || normalized.contains('socket')) {
      return 'Connessione assente. Controlla la rete e riprova.';
    }
    return 'Accesso non riuscito. Verifica la configurazione e riprova.';
  }

  static Future<bool> _hasNetworkConnection() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any((result) => result != ConnectivityResult.none);
    } catch (_) {
      return true;
    }
  }

  @override
  void dispose() {
    _oauthTimer?.cancel();
    _authSubscription?.cancel();
    stateNotifier.dispose();
    super.dispose();
  }
}
