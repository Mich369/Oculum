part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _OculumAppUpdateUi on _OculumHomePageState {
  List<Widget> additionalOculumToolbarActions() => [
    if (readIntValue(planarState['chargePower']) > 0)
      IconButton(
        tooltip: planarCharging
            ? 'Carica e spendi il turno o la Reazione'
            : 'Rilascia Scarica di fulmini',
        onPressed: continuePlanarCharge,
        icon: Icon(Icons.bolt, color: tertiaryColor),
      ),
    IconButton(
      key: const ValueKey('party_quests_button'),
      tooltip: 'Quest del party',
      onPressed: showPartyQuests,
      icon: Icon(Icons.assignment_outlined, color: tertiaryColor),
    ),
    IconButton(
      tooltip: oculumUpdateBusy ? 'Aggiornamento in corso' : 'Aggiorna Oculum',
      onPressed: oculumUpdateBusy ? null : checkAndInstallOculumUpdate,
      icon: Icon(Icons.system_update_alt, color: primaryColor),
    ),
    if (kIsWeb) OculumWebDownloads(color: primaryColor),
  ];

  String get oculumUpdateArtifact => kIsWeb
      ? 'Oculum-Windows'
      : Platform.isWindows
      ? (oculumUsesIsolatedSaveProfile
            ? 'Oculum-Test-Windows'
            : 'Oculum-Windows')
      : Platform.isMacOS
      ? 'Oculum-macOS'
      : Platform.isLinux
      ? 'Oculum-Linux'
      : 'Oculum-Android';

  Future<void> checkOculumUpdateAutomatically() async {
    if (!mounted ||
        oculumSourceCommit.isEmpty ||
        oculumUpdateBusy ||
        oculumUpdateChecking) {
      return;
    }

    final now = DateTime.now();

    if (oculumUpdateLastCheck != null &&
        now.difference(oculumUpdateLastCheck!) < const Duration(minutes: 30)) {
      return;
    }

    oculumUpdateLastCheck = now;

    oculumUpdateChecking = true;

    final client = http.Client();

    try {
      final update = await oculumCheckAppUpdate(client, oculumUpdateArtifact);

      if (!mounted ||
          update == null ||
          update.commit == oculumUpdateNotifiedCommit) {
        return;
      }

      oculumUpdateNotifiedCommit = update.commit;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Una nuova versione di Oculum è disponibile.'),

          duration: const Duration(seconds: 15),

          action: SnackBarAction(
            label: 'Aggiorna',
            onPressed: () => unawaited(checkAndInstallOculumUpdate()),
          ),
        ),
      );
    } catch (_) {
      // Offline and API limits must never interrupt play. The next check retries.
    } finally {
      client.close();
      oculumUpdateChecking = false;
    }
  }

  Future<void> checkAndInstallOculumUpdate() async {
    if (oculumUpdateBusy) return;

    setState(() => oculumUpdateBusy = true);

    final client = http.Client();

    try {
      final artifact = oculumUpdateArtifact;

      final update = await oculumCheckAppUpdate(client, artifact);

      if (!mounted) return;

      if (update == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La tua versione è già aggiornata o più recente.'),
          ),
        );
        return;
      }

      final confirm = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          title: const Text('Aggiorna Oculum'),
          content: Text(
            'Nuova versione ${update.commit.substring(0, 7)}. ${kIsWeb
                ? 'Salva e ricarica il sito.'
                : Platform.isAndroid
                ? 'Scarica il pacchetto verificato e apre la conferma Android.'
                : 'Scarica e verifica i file, conserva un backup del runtime e riavvia Oculum.'} I salvataggi vengono conservati.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Dopo'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(d, true),
              child: const Text('Aggiorna ora'),
            ),
          ],
        ),
      );

      if (confirm != true || !mounted) return;

      await forzaSalvataggioImmediato(soloLocale: true);

      final prefs = await _prefs();

      await _creaBackupDelSalvataggioCorrente(prefs, force: true);

      final rawBackup = await _readSaveBlob(
        prefs,
        _OculumHomePageState.saveKey,
      );

      if (rawBackup == null || !await _rawLooksLikeMeaningfulSave(rawBackup)) {
        throw StateError(
          'Backup dei salvataggi non verificabile: aggiornamento interrotto.',
        );
      }

      final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(
        RegExp('[^0-9]'),
        '',
      );

      if (kIsWeb) {
        final backupKey =
            '${_OculumHomePageState.saveKey}_before_update_$stamp';

        await _writeSaveBlob(prefs, backupKey, rawBackup);

        if (await _readSaveBlob(prefs, backupKey) != rawBackup) {
          throw StateError('Backup web non riuscito.');
        }

        await oculumDownloadBytes(
          bytes: Uint8List.fromList(utf8.encode(rawBackup)),
          fileName: 'Oculum-backup-$stamp.json',
          mimeType: 'application/json',
        );
      } else {
        final documents = await getApplicationDocumentsDirectory();

        final backups = await Directory(
          '${documents.path}/Oculum-update-backups',
        ).create(recursive: true);

        final file = File(
          '${backups.path}/Oculum${oculumUsesIsolatedSaveProfile ? '-Test' : ''}-$stamp.json',
        );

        await file.writeAsString(rawBackup, flush: true);

        if (await file.readAsString() != rawBackup) {
          throw StateError('Backup su disco non verificato.');
        }
      }

      if (kIsWeb) {
        await oculumReloadUpdatedWeb(update.commit);
        return;
      }

      final directory = await getApplicationCacheDirectory();

      final staging = await Directory(
        '${directory.path}/oculum-update-${update.runId}',
      ).create(recursive: true);

      final archive = File('${staging.path}/release.zip');

      final request = await client
          .send(http.Request('GET', Uri.parse(update.url)))
          .timeout(const Duration(seconds: 30));

      if (request.statusCode != 200) {
        throw StateError('Download non disponibile (${request.statusCode}).');
      }

      final digest = SHA256Digest();
      var received = 0;
      final sink = archive.openWrite();

      try {
        await for (final chunk in request.stream.timeout(
          const Duration(seconds: 60),
        )) {
          received += chunk.length;
          if (received > update.bytes) {
            throw StateError('Dimensione del pacchetto non valida.');
          }
          digest.update(Uint8List.fromList(chunk), 0, chunk.length);
          sink.add(chunk);
        }
      } finally {
        await sink.close();
      }

      final hashBytes = Uint8List(digest.digestSize);
      digest.doFinal(hashBytes, 0);

      final hash = hashBytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();

      if (received != update.bytes || hash != update.sha256) {
        throw StateError(
          'Integrità del pacchetto non valida. Nessun file installato.',
        );
      }

      final config = File('${staging.path}/update.json');

      final executable = File(Platform.resolvedExecutable).absolute.path;

      await config.writeAsString(
        jsonEncode({
          'archive': archive.absolute.path,
          'work': staging.absolute.path,
          'executable': executable,
          'pid': pid,
          'platform': Platform.operatingSystem,
          'commit': update.commit,
          'edition': oculumUsesIsolatedSaveProfile ? 'test' : 'normal',
        }),
      );

      if (Platform.isAndroid) {
        await const MethodChannel(
          'com.mich.oculum/update',
        ).invokeMethod<void>('installApk', {'archive': archive.path});

        return;
      }

      final helper = File(
        '${staging.path}/${Platform.isWindows ? 'update.ps1' : 'update.py'}',
      );

      await helper.writeAsString(
        await rootBundle.loadString(
          Platform.isWindows
              ? 'assets/update/update.ps1'
              : 'assets/update/update.py',
        ),
      );

      if (Platform.isWindows) {
        // Start-Process creates a detached hidden helper; it waits for this PID.

        final command =
            "Start-Process -WindowStyle Hidden -FilePath powershell.exe -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',${_psUpdateQuote(helper.path)},${_psUpdateQuote(config.path)})";

        final result = await Process.run('powershell.exe', [
          '-NoProfile',
          '-Command',
          command,
        ]);

        if (result.exitCode != 0) {
          throw StateError(
            'Impossibile avviare il programma di aggiornamento.',
          );
        }
      } else {
        final result = await Process.run('python3', ['--version']);

        if (result.exitCode != 0) {
          throw StateError(
            'Aggiornamento automatico richiede Python 3. Usa il pacchetto pubblico del sito.',
          );
        }

        await Process.start('python3', [
          helper.path,
          config.path,
        ], mode: ProcessStartMode.detached);
      }

      await salvaDatiSoloLocale();

      exit(0);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Aggiornamento: $error')));
      }
    } finally {
      client.close();
      if (mounted) setState(() => oculumUpdateBusy = false);
    }
  }

  String _psUpdateQuote(String value) => "'${value.replaceAll("'", "''")}'";
}
