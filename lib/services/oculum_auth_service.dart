import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'oculum_save_profile.dart';
import 'oculum_smoke_storage.dart';
import 'oculum_secure_auth_storage.dart';

const String oculumOAuthRedirectUrl = String.fromEnvironment(
  'OculumOAuthRedirectUrl',
  defaultValue: 'com.mich.oculum://login-callback',
);
const bool _googleOAuthConfigured = bool.fromEnvironment(
  'OculumGoogleOAuthEnabled',
  defaultValue: true,
);
const bool _appleOAuthConfigured = bool.fromEnvironment(
  'OculumAppleOAuthEnabled',
  defaultValue: false,
);

enum OculumAuthProvider { google, apple }

enum _OculumAccountRequest { email, signOut }

enum OculumBackendAuthEventType {
  signedIn,
  signedOut,
  passwordRecovery,
  tokenRefreshed,
  userUpdated,
  userDeleted,
}

class OculumBackendUser {
  const OculumBackendUser({
    required this.id,
    this.provider,
    this.hasVerifiedEmail = false,
    this.identityProviders = const <String>{},
  });

  final String id;
  final String? provider;
  final bool hasVerifiedEmail;
  final Set<String> identityProviders;
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

abstract class OculumIdentityLinkBackend {
  Future<bool> linkGoogle({required String redirectTo});
}

String oculumWebAuthRedirect(Uri page) => Uri(
  scheme: page.scheme,
  host: page.host,
  port: page.hasPort ? page.port : null,
  path: page.path,
).toString();

String get oculumPlatformAuthRedirect {
  if (kIsWeb) return oculumWebAuthRedirect(Uri.base);
  if (defaultTargetPlatform == TargetPlatform.windows &&
      oculumSaveProfile.trim() == 'test' &&
      oculumOAuthRedirectUrl == 'com.mich.oculum://login-callback') {
    return 'com.mich.oculum.test://login-callback';
  }
  return oculumOAuthRedirectUrl;
}

/// Optional capability so existing offline/test backends remain compatible.
abstract class OculumEmailAuthBackend {
  Future<void> signInAnonymously();
  Future<void> requestEmail(String email, {required bool linkGuest});
  Future<void> linkGuestEmailPassword(String email, String password);
  Future<void> signInWithEmailPassword(String email, String password);
  Future<void> setPassword(String password);
  Future<void> requestPasswordReset(String email);
  Future<void> verifyEmail(
    String email,
    String token, {
    required bool linkGuest,
  });
}

/// Preserves the SDK's existing session key while honoring the user's choice.
class OculumSessionStorage extends LocalStorage {
  OculumSessionStorage({
    required String persistSessionKey,
    OculumSecureAuthStorage? secureStorage,
    bool useBrowserStorage = kIsWeb,
  }) : _key = persistSessionKey,
       _secure = useBrowserStorage
           ? null
           : secureStorage ?? OculumSecureAuthStorage(),
       _browser = SharedPreferencesLocalStorage(
         persistSessionKey: persistSessionKey,
       );
  static String get rememberKey =>
      oculumProfiledStorageKey('oculum.auth.remember_access');
  final String _key;
  final OculumSecureAuthStorage? _secure;
  final LocalStorage _browser;
  late SharedPreferences _prefs;
  Future<void> _storageTail = Future<void>.value();

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _storageTail.then((_) => operation());
    _storageTail = result.then<void>((_) {}, onError: (_, _) {});
    return result;
  }

  @override
  Future<void> initialize() async {
    if (oculumSmokeStorageActive) return;
    _prefs = await SharedPreferences.getInstance();
    if (_secure == null) await _browser.initialize();
    if (!(_prefs.getBool(rememberKey) ?? true)) {
      await removePersistedSession();
    }
  }

  @override
  Future<bool> hasAccessToken() async => await accessToken() != null;

  @override
  Future<String?> accessToken() => _serialize(() async {
    if (oculumSmokeStorageActive) return null;
    if (!(_prefs.getBool(rememberKey) ?? true)) return null;
    final secure = _secure;
    return secure == null
        ? _browser.accessToken()
        : secure.read(_key, legacy: _prefs);
  });

  @override
  Future<void> removePersistedSession() => _serialize(_removeSession);

  Future<void> _removeSession() {
    if (oculumSmokeStorageActive) return Future<void>.value();
    final secure = _secure;
    return secure == null
        ? _browser.removePersistedSession()
        : secure.delete(_key, legacy: _prefs);
  }

  @override
  Future<void> persistSession(String session) => _serialize(() async {
    if (oculumSmokeStorageActive) return;
    if (_prefs.getBool(rememberKey) ?? true) {
      final secure = _secure;
      if (secure == null) {
        await _browser.persistSession(session);
      } else {
        await secure.write(_key, session, legacy: _prefs);
      }
    } else {
      await _removeSession();
    }
  });
}

class SupabaseOculumAuthBackend
    implements
        OculumAuthBackend,
        OculumEmailAuthBackend,
        OculumIdentityLinkBackend {
  SupabaseClient get _client {
    if (oculumSmokeStorageActive) {
      throw const OculumSmokeStorageException('network_disabled');
    }
    return Supabase.instance.client;
  }

  static const _windowsOAuth = MethodChannel('oculum/windows_oauth');

  Future<void> _prepareNativeRedirect(String? redirectTo) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) return;
    final registered = redirectTo == null
        ? false
        : await _windowsOAuth.invokeMethod<bool>(
            'registerCallback',
            redirectTo,
          );
    if (registered != true) {
      throw const AuthException('Windows OAuth callback registration failed');
    }
  }

  OculumBackendUser _mapUser(User user) => OculumBackendUser(
    id: user.id,
    hasVerifiedEmail:
        user.emailConfirmedAt != null &&
        (user.email?.trim().isNotEmpty ?? false),
    provider: user.isAnonymous
        ? 'anonymous'
        : user.appMetadata['provider']?.toString(),
    identityProviders: {
      for (final identity in user.identities ?? const <UserIdentity>[])
        identity.provider,
    },
  );

  @override
  OculumBackendUser? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null || _client.auth.currentSession == null) return null;
    return _mapUser(user);
  }

  @override
  Stream<OculumBackendAuthEvent> get events =>
      _client.auth.onAuthStateChange.map((data) {
        final user = data.session?.user;
        final mappedUser = user == null ? null : _mapUser(user);
        final type = switch (data.event) {
          AuthChangeEvent.signedIn => OculumBackendAuthEventType.signedIn,
          AuthChangeEvent.passwordRecovery =>
            OculumBackendAuthEventType.passwordRecovery,
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
  }) async {
    await _prepareNativeRedirect(redirectTo);
    return _client.auth.signInWithOAuth(
      provider == OculumAuthProvider.apple
          ? OAuthProvider.apple
          : OAuthProvider.google,
      redirectTo: redirectTo,
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
      scopes: provider == OculumAuthProvider.apple
          ? 'name email'
          : 'openid email profile',
    );
  }

  @override
  Future<bool> linkGoogle({required String redirectTo}) async {
    await _prepareNativeRedirect(redirectTo);
    return _client.auth.linkIdentity(
      OAuthProvider.google,
      redirectTo: redirectTo,
      scopes: 'openid email profile',
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
  }

  @override
  Future<void> signOut() => _client.auth.signOut(scope: SignOutScope.local);

  @override
  Future<void> signInAnonymously() async {
    await _client.auth.signInAnonymously();
  }

  @override
  Future<void> requestEmail(String email, {required bool linkGuest}) async {
    final redirect = _emailRedirect;
    if (linkGuest) {
      await _client.auth.updateUser(
        UserAttributes(email: email),
        emailRedirectTo: redirect,
      );
    } else {
      await _client.auth.signInWithOtp(email: email, emailRedirectTo: redirect);
    }
  }

  String get _emailRedirect => oculumPlatformAuthRedirect;

  @override
  Future<void> linkGuestEmailPassword(String email, String password) async {
    await _client.auth.updateUser(
      UserAttributes(email: email, password: password),
      emailRedirectTo: _emailRedirect,
    );
  }

  @override
  Future<void> signInWithEmailPassword(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> setPassword(String password) async {
    final auth = _client.auth;
    final expectedUser = auth.currentSession?.user.id;
    final result = await auth.updateUser(UserAttributes(password: password));
    final current = auth.currentSession;
    if (current == null || result.user?.id != expectedUser) {
      throw const AuthException('Password session changed');
    }
    // Another browser tab can change the session during the SDK request.
    // This checks local consistency only. Supabase authorizes the update.
    final token = current.accessToken.split('.');
    final claims =
        jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(token[1]))))
            as Map<String, dynamic>;
    if (claims['sub'] != current.user.id) {
      await auth.signOut(scope: SignOutScope.local);
      throw const AuthException('Password session changed');
    }
    if (current.user.id != expectedUser) {
      throw const AuthException('Password session changed');
    }
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    final redirect = _emailRedirect;
    await _prepareNativeRedirect(redirect);
    await _client.auth.resetPasswordForEmail(email, redirectTo: redirect);
  }

  @override
  Future<void> verifyEmail(
    String email,
    String token, {
    required bool linkGuest,
  }) async {
    await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: linkGuest ? OtpType.emailChange : OtpType.email,
    );
  }
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

  bool get canSyncToCloud => isAuthenticated && !isGuest && !isLoading;

  String get displayLabel {
    if (provider == 'anonymous') return 'Ospite online protetto';
    if (isAuthenticated) return 'Accesso effettuato';
    if (isGuest) return 'Modalità locale';
    return 'Accesso non effettuato';
  }

  String get providerLabel => switch (provider) {
    'google' => 'Google',
    'apple' => 'Apple',
    'guest' => 'Guest',
    'anonymous' => 'Ospite protetto',
    'email' => 'Email',
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

  static final _guestModePrefsKey = oculumProfiledStorageKey(
    'oculum.auth.guest_mode',
  );
  static final _userIdPrefsKey = oculumProfiledStorageKey(
    'oculum.auth.user_id',
  );
  static final _providerPrefsKey = oculumProfiledStorageKey(
    'oculum.auth.provider',
  );

  OculumAuthBackend? _backend;
  final Future<bool> Function() _connectivityCheck;
  final bool? _googleConfiguredOverride;
  final bool? _appleConfiguredOverride;
  final Duration _oauthTimeout;
  final bool _requireOAuthRedirect;
  StreamSubscription<OculumBackendAuthEvent>? _authSubscription;
  Timer? _oauthTimer;
  bool _operationInProgress = false;
  _OculumAccountRequest? _accountRequest;
  String? pendingEmail;
  String? _emailLinkAccount;
  bool rememberAccess = true;
  static OculumSessionStorage? sessionStorage;
  OculumAuthProvider? _lastAttemptedProvider;
  bool _lastAttemptWasLink = false;
  String? _linkingGoogleUserId;
  final _passwordRecovery = ValueNotifier<String?>(null);
  final _invalidAuthLink = ValueNotifier<int>(0);
  bool _completingPasswordRecovery = false;
  bool _disposed = false;

  ValueListenable<String?> get passwordRecovery => _passwordRecovery;
  ValueListenable<int> get invalidAuthLink => _invalidAuthLink;
  static const invalidAuthLinkMessage =
      'Link non più valido. Richiedine uno nuovo e aprilo nello stesso browser o nella stessa app in cui lo hai richiesto.';
  bool get hasVerifiedEmail {
    final user = _backend?.currentUser;
    return user != null && user.id == state.userId && user.hasVerifiedEmail;
  }

  bool get hasGoogleIdentity {
    final user = _backend?.currentUser;
    return user?.identityProviders.contains('google') == true ||
        user?.provider == 'google';
  }

  bool get canLinkGoogle =>
      state.isAuthenticated &&
      _backend is OculumIdentityLinkBackend &&
      isProviderSupported(OculumAuthProvider.google) &&
      !hasGoogleIdentity;

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
  bool get isBusy => _operationInProgress || _accountRequest != null;
  bool get isSigningOut => _accountRequest == _OculumAccountRequest.signOut;
  bool get canCancelSignIn => _operationInProgress && state.isLoading;
  bool get isSupabaseReady => !oculumSmokeStorageActive && _backend != null;
  bool get googleConfigured =>
      _googleConfiguredOverride ?? _googleOAuthConfigured;
  bool get appleConfigured => _appleConfiguredOverride ?? _appleOAuthConfigured;

  bool isProviderSupported(OculumAuthProvider provider) {
    if (provider == OculumAuthProvider.google) {
      // The Linux tarball has no protocol handler installation.
      return googleConfigured &&
          (kIsWeb || defaultTargetPlatform != TargetPlatform.linux);
    }
    return appleConfigured;
  }

  String providerAvailabilityLabel(OculumAuthProvider provider) {
    if (!isSupabaseReady) return 'Supabase non configurato';
    if (!isProviderSupported(provider)) {
      if (provider == OculumAuthProvider.google &&
          googleConfigured &&
          !kIsWeb &&
          defaultTargetPlatform == TargetPlatform.linux) {
        return 'Disponibile nella versione web';
      }
      return 'Prossimamente';
    }
    return 'Disponibile';
  }

  Future<void> initialize({bool supabaseReady = false}) async {
    if (oculumSmokeStorageActive) return;
    final prefs = await SharedPreferences.getInstance();
    rememberAccess = prefs.getBool(OculumSessionStorage.rememberKey) ?? true;
    if (supabaseReady && _backend == null) {
      _backend = SupabaseOculumAuthBackend();
    }
    await _authSubscription?.cancel();
    _authSubscription = _backend?.events.listen(
      _handleBackendEvent,
      onError: _handleBackendError,
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

  Future<void> setRememberAccess(bool remember) async {
    if (oculumSmokeStorageActive || isBusy) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OculumSessionStorage.rememberKey, remember);
    rememberAccess = remember;
    try {
      if (!remember) {
        await sessionStorage?.removePersistedSession();
      } else if (_backend is SupabaseOculumAuthBackend) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          await sessionStorage?.persistSession(jsonEncode(session.toJson()));
        }
      }
    } catch (_) {
      _showRecoverableError(
        'Lo storage della sessione non è disponibile. I dati locali restano accessibili.',
      );
    }
    notifyListeners();
  }

  Future<bool> signInAsProtectedGuest() => _runEmailOperation(() async {
    if (_backend!.currentUser == null) {
      await (_backend as OculumEmailAuthBackend).signInAnonymously();
    }
    final user = _backend!.currentUser;
    if (user == null) throw StateError('Missing guest session');
    await _applySignedIn(user);
  });

  Future<bool> requestEmailAccess(String email) => _runEmailOperation(() async {
    final normalized = _validateEmail(email);
    final account = _backend?.currentUser;
    if (account != null && account.provider != 'anonymous') {
      throw const FormatException(
        'Esci da questo account prima di accedere a un altro.',
      );
    }
    await (_backend as OculumEmailAuthBackend).requestEmail(
      normalized,
      linkGuest: account != null,
    );
    pendingEmail = normalized;
    _emailLinkAccount = account?.id;
  });

  Future<bool> linkGuestEmailPassword(String email, String password) =>
      _runEmailOperation(() async {
        final normalized = _validateEmail(email);
        _validatePassword(password);
        final account = _backend?.currentUser;
        if (account?.provider != 'anonymous' || account?.id != state.userId) {
          throw const FormatException(
            'Accedi prima come ospite online protetto per collegare l’email.',
          );
        }
        await (_backend as OculumEmailAuthBackend).linkGuestEmailPassword(
          normalized,
          password,
        );
        pendingEmail = normalized;
        _emailLinkAccount = account!.id;
      });

  Future<bool> signInWithEmailPassword(String email, String password) =>
      _runEmailOperation(() async {
        final normalized = _validateEmail(email);
        if (_backend?.currentUser != null) {
          throw const FormatException(
            'Esci da questo account prima di accedere a un altro.',
          );
        }
        if (password.isEmpty) {
          throw const FormatException('Inserisci la password.');
        }
        await (_backend as OculumEmailAuthBackend).signInWithEmailPassword(
          normalized,
          password,
        );
        final user = _backend!.currentUser;
        if (user == null) throw StateError('Missing email session');
        await _applySignedIn(user);
      });

  Future<bool> setAccountPassword(String password) => _runEmailOperation(
    () async {
      _validatePassword(password);
      if (!state.isAuthenticated || state.isGuest) {
        throw const FormatException(
          'Accedi o collega prima un account email per impostare la password.',
        );
      }
      await (_backend as OculumEmailAuthBackend).setPassword(password);
    },
  );

  Future<bool> requestPasswordReset(String email) =>
      _runEmailOperation(() async {
        final normalized = _validateEmail(email);
        try {
          await (_backend as OculumEmailAuthBackend).requestPasswordReset(
            normalized,
          );
        } on AuthException catch (error) {
          if (error.code != 'user_not_found') rethrow;
        }
      });

  Future<bool> completePasswordRecovery(
    String accountId,
    String password,
  ) async {
    if (_completingPasswordRecovery ||
        _passwordRecovery.value != accountId ||
        _backend?.currentUser?.id != accountId) {
      return false;
    }
    _completingPasswordRecovery = true;
    try {
      final success = await _runEmailOperation(() async {
        _validatePassword(password);
        await (_backend as OculumEmailAuthBackend).setPassword(password);
      }, timeout: null);
      if (!success ||
          _passwordRecovery.value != accountId ||
          _backend?.currentUser?.id != accountId) {
        return false;
      }
      _passwordRecovery.value = null;
      return true;
    } finally {
      _completingPasswordRecovery = false;
    }
  }

  void dismissPasswordRecovery() {
    if (!_completingPasswordRecovery) _passwordRecovery.value = null;
  }

  static String _validateEmail(String email) {
    final normalized = email.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized)) {
      throw const FormatException('Email non valida');
    }
    return normalized;
  }

  static void _validatePassword(String password) {
    if (password.length < 8) {
      throw const FormatException(
        'La password deve contenere almeno 8 caratteri.',
      );
    }
  }

  Future<bool> verifyEmailAccess(String code) => _runEmailOperation(() async {
    final email = pendingEmail;
    final linkAccount = _emailLinkAccount;
    if (email == null || code.trim().isEmpty) {
      throw const FormatException('Codice mancante');
    }
    if (_backend?.currentUser?.id != linkAccount) {
      _clearPendingEmail();
      throw const FormatException(
        'La sessione è cambiata. Richiedi un nuovo codice.',
      );
    }
    await (_backend as OculumEmailAuthBackend).verifyEmail(
      email,
      code.trim(),
      linkGuest: linkAccount != null,
    );
    final user = _backend!.currentUser;
    if (user == null) throw StateError('Missing email session');
    _clearPendingEmail();
    await _applySignedIn(user);
  });

  void _clearPendingEmail() {
    pendingEmail = null;
    _emailLinkAccount = null;
  }

  Future<bool> _runEmailOperation(
    Future<void> Function() operation, {
    Duration? timeout = const Duration(seconds: 20),
  }) async {
    if (oculumSmokeStorageActive) return false;
    if (isBusy) return false;
    if (_backend is! OculumEmailAuthBackend) {
      _showRecoverableError(
        'Accesso online non disponibile. I salvataggi restano locali.',
      );
      return false;
    }
    _accountRequest = _OculumAccountRequest.email;
    notifyListeners();
    Future<void>? pending;
    var releaseOnReturn = true;
    void release() {
      _accountRequest = null;
      if (!_disposed) notifyListeners();
    }

    try {
      final result = pending = operation();
      await (timeout == null ? result : result.timeout(timeout));
      return true;
    } on TimeoutException {
      final request = pending;
      if (request != null) {
        // A UI timeout does not cancel the SDK request or its session event.
        releaseOnReturn = false;
        unawaited(
          request.then<void>(
            (_) => release(),
            onError: (Object _) => release(),
          ),
        );
      }
      _showRecoverableError('Il servizio di accesso non ha ancora risposto.');
    } on AuthException catch (error) {
      _showRecoverableError(_friendlyAuthError(error));
    } on FormatException catch (error) {
      _showRecoverableError(error.message);
    } catch (_) {
      _showRecoverableError(
        'Accesso non riuscito. Controlla la rete e riprova.',
      );
    } finally {
      if (releaseOnReturn) release();
    }
    return false;
  }

  Future<bool> signInWithGoogle({String? redirectTo}) => state.isAuthenticated
      ? _signIn(
          OculumAuthProvider.google,
          redirectTo: redirectTo,
          linkIdentity: true,
        )
      : _signIn(OculumAuthProvider.google, redirectTo: redirectTo);

  Future<bool> linkGoogle() =>
      _signIn(OculumAuthProvider.google, linkIdentity: true);

  Future<bool> signInWithApple({String? redirectTo}) =>
      _signIn(OculumAuthProvider.apple, redirectTo: redirectTo);

  Future<bool> retryLastSignIn() async {
    final provider = _lastAttemptedProvider;
    if (provider == null) return false;
    return _signIn(provider, linkIdentity: _lastAttemptWasLink);
  }

  Future<bool> _signIn(
    OculumAuthProvider provider, {
    String? redirectTo,
    bool linkIdentity = false,
  }) async {
    if (oculumSmokeStorageActive) return false;
    if (isBusy || state.isAuthenticated && !linkIdentity) return false;
    _lastAttemptedProvider = provider;
    _lastAttemptWasLink = linkIdentity;
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
    if (linkIdentity && !canLinkGoogle) return false;
    final effectiveRedirect = redirectTo ?? oculumPlatformAuthRedirect;
    if (_requireOAuthRedirect && !kIsWeb && effectiveRedirect.isEmpty) {
      _showRecoverableError(
        '${_providerName(provider)} richiede ancora la configurazione OAuth.',
      );
      return false;
    }
    _operationInProgress = true;
    if (linkIdentity) _linkingGoogleUserId = _backend!.currentUser?.id;
    notifyListeners();
    if (!await _connectivityCheck().catchError((Object _) => false)) {
      _cancelPendingOperation();
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
        provider: linkIdentity ? state.provider : _providerId(provider),
        message: linkIdentity
            ? 'Completa il collegamento a Google nel browser di sistema.'
            : 'Completa l’accesso nel browser di sistema.',
      ),
    );
    try {
      final operation = linkIdentity
          ? (_backend as OculumIdentityLinkBackend).linkGoogle(
              redirectTo: effectiveRedirect,
            )
          : _backend!.startOAuth(provider, redirectTo: effectiveRedirect);
      final launched = await operation.timeout(const Duration(seconds: 15));
      if (!_operationInProgress) return launched;
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
      _finishOperationWithError(_friendlyAuthError(error));
    } catch (_) {
      _finishOperationWithError('Accesso non riuscito. Riprova più tardi.');
    }
    return false;
  }

  Future<bool> continueAsGuest() async {
    if (isBusy || state.isAuthenticated || _backend?.currentUser != null) {
      return false;
    }
    await _enterGuestMode();
    return true;
  }

  Future<void> _enterGuestMode() async {
    _passwordRecovery.value = null;
    _cancelPendingOperation();
    _clearPendingEmail();
    _lastAttemptedProvider = null;
    _lastAttemptWasLink = false;
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
  }

  Future<bool> signOut() async {
    if (oculumSmokeStorageActive) return false;
    if (isBusy) return false;
    _accountRequest = _OculumAccountRequest.signOut;
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
      var remotelyConfirmed = true;
      try {
        await _backend?.signOut().timeout(const Duration(seconds: 10));
      } catch (_) {
        remotelyConfirmed = false;
      }
      if (_backend?.currentUser != null) {
        _showRecoverableError('La sessione è ancora attiva. Riprova a uscire.');
        return false;
      }
      await _enterGuestMode();
      try {
        await sessionStorage?.removePersistedSession();
      } catch (_) {
        _showRecoverableError(
          'Impossibile confermare la rimozione della sessione dal dispositivo.',
        );
        return false;
      }
      if (!remotelyConfirmed) {
        _showRecoverableError(
          'Uscita completata su questo dispositivo. Revoca online non confermata.',
        );
      }
      return true;
    } finally {
      _accountRequest = null;
      if (!_disposed) notifyListeners();
    }
  }

  void cancelPendingSignIn() {
    if (!_operationInProgress) return;
    _cancelPendingOperation();
    _showRecoverableError('Accesso annullato. Puoi continuare in locale.');
  }

  Future<void> _handleBackendEvent(OculumBackendAuthEvent event) async {
    if (_disposed || isSigningOut) return;
    switch (event.type) {
      case OculumBackendAuthEventType.passwordRecovery:
        final user = event.user;
        if (user != null &&
            user.provider != 'anonymous' &&
            _backend?.currentUser?.id == user.id) {
          await _applySignedIn(user);
          if (!_disposed &&
              _backend?.currentUser?.id == user.id &&
              state.userId == user.id) {
            _passwordRecovery.value = user.id;
          }
        }
      case OculumBackendAuthEventType.signedIn:
      case OculumBackendAuthEventType.tokenRefreshed:
      case OculumBackendAuthEventType.userUpdated:
        final user = event.user ?? _backend?.currentUser;
        if (user != null) {
          final expectedLinkUser = _linkingGoogleUserId;
          if (expectedLinkUser != null) {
            if (user.id != expectedLinkUser) {
              _finishOperationWithError(
                'Il collegamento non ha confermato lo stesso account Oculum.',
              );
              await signOut();
              _showRecoverableError(
                'Collegamento non riuscito. Accedi al tuo account Oculum.',
              );
              return;
            }
            if (!user.identityProviders.contains('google') &&
                user.provider != 'google') {
              return;
            }
          }
          await _applySignedIn(user);
        }
      case OculumBackendAuthEventType.signedOut:
      case OculumBackendAuthEventType.userDeleted:
        if (_backend?.currentUser == null) await _enterGuestMode();
    }
  }

  void _handleBackendError(Object error) {
    if (_disposed || isSigningOut) return;
    const invalidLinkCodes = {
      'otp_expired',
      'flow_state_expired',
      'flow_state_not_found',
      'bad_code_verifier',
      'invalid_grant',
    };
    if (error is AuthPKCEGrantCodeExchangeError ||
        (error is AuthException &&
            (invalidLinkCodes.contains(error.code) ||
                invalidLinkCodes.contains(error.statusCode) ||
                error.message.toLowerCase().contains('code verifier')))) {
      _invalidAuthLink.value++;
      _showRecoverableError(invalidAuthLinkMessage);
      return;
    }
    _showRecoverableError(
      'Sessione non disponibile. Puoi continuare in modalità locale.',
    );
  }

  Future<void> _applySignedIn(OculumBackendUser user) async {
    if (_disposed || isSigningOut || _backend?.currentUser?.id != user.id) {
      return;
    }
    if (_passwordRecovery.value != user.id) _passwordRecovery.value = null;
    final provider = user.provider ?? _providerId(_lastAttemptedProvider);
    final prefs = await SharedPreferences.getInstance();
    if (_disposed || isSigningOut || _backend?.currentUser?.id != user.id) {
      return;
    }
    await prefs.setBool(_guestModePrefsKey, false);
    await prefs.setString(_userIdPrefsKey, user.id);
    if (provider != null) await prefs.setString(_providerPrefsKey, provider);
    if (_disposed || isSigningOut || _backend?.currentUser?.id != user.id) {
      return;
    }
    _cancelPendingOperation();
    _setState(
      OculumAuthState(
        isAuthenticated: true,
        isGuest: user.provider == 'anonymous',
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
    _linkingGoogleUserId = null;
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
    if (_disposed) return;
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

  static String _friendlyAuthError(AuthException error) {
    final normalized = error.message.toLowerCase();
    if (error.statusCode == '429' ||
        const {
          'over_request_rate_limit',
          'over_email_send_rate_limit',
        }.contains(error.code)) {
      return 'Troppe richieste. Attendi prima di riprovare.';
    }
    if (normalized.contains('callback registration')) {
      return 'Impossibile configurare il ritorno a Oculum su Windows.';
    }
    if (normalized.contains('identity') && normalized.contains('already')) {
      return 'Questo account Google è già collegato a un account Oculum.';
    }
    if (normalized.contains('manual linking')) {
      return 'Il collegamento Google non è ancora abilitato in Supabase.';
    }
    if (normalized.contains('cancel')) return 'Accesso annullato.';
    if (normalized.contains('password session changed')) {
      return 'La sessione è cambiata. Accedi di nuovo e verifica la password.';
    }
    if (normalized.contains('rate limit') ||
        normalized.contains('security purposes')) {
      return 'Attendi prima di inviare un’altra richiesta e riprova.';
    }
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
    _disposed = true;
    _oauthTimer?.cancel();
    _authSubscription?.cancel();
    stateNotifier.dispose();
    _passwordRecovery.dispose();
    _invalidAuthLink.dispose();
    super.dispose();
  }
}
