/// Persists and re-reads the current save before an update may hand control to
/// an installer. A previous, meaningful save is not proof that the latest write
/// succeeded: the persistence layer can deliberately refuse a write.
Future<String> oculumRequireVerifiedUpdateSave({
  required Future<void> Function() saveLatest,
  required Future<String?> Function() readPersisted,
  required bool Function() dataLoaded,
  required bool Function() writeBlocked,
  required int Function() writeFailures,
  required String? Function() lastConfirmedRaw,
  required Future<bool> Function(String raw) looksMeaningful,
}) async {
  bool writeIsReady() =>
      dataLoaded() && !writeBlocked() && writeFailures() == 0;

  if (!dataLoaded()) {
    throw StateError(
      'Attendi il caricamento dei salvataggi prima di aggiornare Oculum.',
    );
  }

  await saveLatest();
  if (!writeIsReady()) {
    throw StateError(
      'Il salvataggio corrente non è stato confermato: Oculum resta aperto. '
      'Risolvi l’errore di salvataggio prima di aggiornare.',
    );
  }

  final raw = await readPersisted();
  if (raw == null ||
      raw.trim().isEmpty ||
      raw != lastConfirmedRaw() ||
      !await looksMeaningful(raw) ||
      !writeIsReady() ||
      raw != lastConfirmedRaw()) {
    throw StateError(
      'Backup dei salvataggi non verificabile: aggiornamento interrotto. '
      'Oculum resta aperto.',
    );
  }
  return raw;
}
