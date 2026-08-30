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

String get oculumProfileFileSuffix {
  final profile = oculumSaveProfile.trim();
  return profile.isEmpty ? '' : '_$profile';
}
