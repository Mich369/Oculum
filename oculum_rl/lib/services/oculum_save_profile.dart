/// Profilo di salvataggio scelto alla compilazione.
///
/// Il profilo vuoto è la versione normale e conserva tutti gli ID storici.
/// Un profilo come `test` usa chiavi e file separati: può iniziare pulito
/// senza leggere, eliminare o sovrascrivere i dati dell'app principale.
const String oculumSaveProfile = String.fromEnvironment(
  'OculumSaveProfile',
  defaultValue: '',
);

bool get oculumUsesIsolatedSaveProfile => oculumSaveProfile.trim().isNotEmpty;

String oculumProfiledStorageKey(String baseKey) {
  final profile = oculumSaveProfile.trim();
  return profile.isEmpty ? baseKey : '${baseKey}__$profile';
}

/// Keeps Supabase identities isolated alongside each local save profile.
/// The normal build retains its historical Auth key; e.g. the Test build
/// gets a separate anonymous/user session so two app variants can join the
/// same room as distinct participants on one Windows machine.
String oculumAuthSessionStorageKey(String projectRef, {bool browser = false}) =>
    oculumProfiledStorageKey(
      'sb-$projectRef-auth-token${browser ? '-browser' : ''}',
    );

String get oculumProfileFileSuffix {
  final profile = oculumSaveProfile.trim();
  return profile.isEmpty ? '' : '_$profile';
}
