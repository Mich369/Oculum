part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _OculumAppUpdateUi on _OculumHomePageState {
  void scheduleOculumStartupLog() {
    if (oculumStartupLogPending || oculumStartupLogChecked) return;
    oculumStartupLogPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!kIsWeb) {
          final cache = await getApplicationCacheDirectory();
          final failure = await oculumReadUpdateFailure(
            cacheRoot: cache.path,
            edition: oculumUsesIsolatedSaveProfile ? 'test' : 'normal',
          );
          if (mounted && failure != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failure),
                duration: const Duration(seconds: 15),
              ),
            );
          }
        }
        final prefs = await _prefs().timeout(const Duration(seconds: 3));
        if (!mounted ||
            !oculumShouldShowVersionLog(prefs, oculumSourceCommit)) {
          return;
        }
        final text = await rootBundle
            .loadString(oculumCumulativeLogAsset)
            .timeout(const Duration(seconds: 3));
        if (!mounted) return;
        await oculumRememberVersionLog(prefs, oculumSourceCommit);
        if (!mounted) return;
        await oculumShowVersionLogDialog(context, text, oculumSourceCommit);
      } catch (_) {
        // Offline local startup must remain usable even if preferences or an
        // optional notice asset cannot be read. Saves are never modified here.
      } finally {
        if (mounted) {
          setState(() {
            oculumStartupLogChecked = true;
            oculumStartupLogPending = false;
          });
        }
      }
    });
  }

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

    Directory? staging;
    OculumAppUpdate? selectedUpdate;
    var stage = 'checking';
    final progress = ValueNotifier<({String message, double? value})>((
      message: 'Controllo aggiornamento…',
      value: null,
    ));
    DialogRoute<void>? progressRoute;

    Future<void> reportStage(
      String state,
      String message, {
      double? value,
    }) async {
      stage = state;
      progress.value = (message: message, value: value);
      if (staging != null) {
        await File('${staging.path}/frontend-status.json').writeAsString(
          jsonEncode({
            'state': state,
            'message': message,
            'commit': selectedUpdate?.commit,
            'edition': oculumUsesIsolatedSaveProfile ? 'test' : 'normal',
            'attemptId': staging.uri.pathSegments
                .where((s) => s.isNotEmpty)
                .last,
            'updatedAtUtc': DateTime.now().toUtc().toIso8601String(),
          }),
          flush: true,
        );
      }
    }

    try {
      final artifact = oculumUpdateArtifact;

      final update = await oculumCheckAppUpdate(client, artifact);
      selectedUpdate = update;

      if (!mounted) return;

      if (update == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Non c’è un aggiornamento verificato installabile. La pagina Download indica l’ultima build pubblicata.',
            ),
          ),
        );
        return;
      }

      final confirm = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          title: const Text('Aggiorna Oculum'),
          content: SingleChildScrollView(
            child: Text(
              'Nuova versione ${update.commit.substring(0, 7)}. ${kIsWeb
                  ? 'Salva e ricarica il sito.'
                  : Platform.isAndroid
                  ? 'Scarica il pacchetto verificato e apre la conferma Android.'
                  : 'Scarica e verifica i file, conserva un backup del runtime e riavvia Oculum.'} I salvataggi vengono conservati.',
            ),
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

      if (!kIsWeb) {
        final cache = await getApplicationCacheDirectory();
        // Every retry owns fresh files; a previous helper or partial download
        // can never share its archive, config, status or extraction directory.
        staging = await Directory(
          cache.path,
        ).createTemp('oculum-update-${update.runId}-');
        await File(
          '${cache.path}/oculum-update-latest-${oculumUsesIsolatedSaveProfile ? 'test' : 'normal'}.json',
        ).writeAsString(
          jsonEncode({
            'work': staging.absolute.path,
            'edition': oculumUsesIsolatedSaveProfile ? 'test' : 'normal',
            'commit': update.commit,
          }),
          flush: true,
        );
      }

      final updateContext = context;
      if (!updateContext.mounted) return;
      progressRoute = DialogRoute<void>(
        context: updateContext,
        barrierDismissible: false,
        builder: (_) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('Aggiornamento Oculum'),
            content: ValueListenableBuilder<({String message, double? value})>(
              valueListenable: progress,
              builder: (_, status, _) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(status.message),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: status.value),
                  const SizedBox(height: 12),
                  const Text(
                    'Attendi il completamento. I salvataggi vengono conservati.',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      unawaited(
        Navigator.of(updateContext, rootNavigator: true).push(progressRoute),
      );
      await reportStage('backup', 'Salvataggio e verifica del backup…');

      final prefs = await _prefs();
      Future<String> verifyLatestSave() => oculumRequireVerifiedUpdateSave(
        saveLatest: () => forzaSalvataggioImmediato(soloLocale: true),
        readPersisted: () => _readSaveBlob(prefs, _OculumHomePageState.saveKey),
        dataLoaded: () => datiCaricati,
        writeBlocked: () => salvataggioBloccatoPerErrore,
        writeFailures: () => salvataggioFallimentiConsecutivi,
        lastConfirmedRaw: () => ultimoRawSalvataggioConfermato,
        looksMeaningful: _rawLooksLikeMeaningfulSave,
      );
      final rawBackup = await verifyLatestSave();
      await _creaBackupDelSalvataggioCorrente(prefs, force: true);

      final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(
        RegExp('[^0-9]'),
        '',
      );

      Future<void> writeUpdateBackup(String raw) async {
        if (kIsWeb) {
          final backupKey =
              '${_OculumHomePageState.saveKey}_before_update_$stamp';
          await _writeSaveBlob(prefs, backupKey, raw);
          if (await _readSaveBlob(prefs, backupKey) != raw) {
            throw StateError('Backup web non riuscito.');
          }
          await oculumDownloadBytes(
            bytes: Uint8List.fromList(utf8.encode(raw)),
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
          await file.writeAsString(raw, flush: true);
          if (await file.readAsString() != raw) {
            throw StateError('Backup su disco non verificato.');
          }
        }
      }

      await writeUpdateBackup(rawBackup);

      if (kIsWeb) {
        await oculumReloadUpdatedWeb(update.commit);
        return;
      }

      final archive = File('${staging!.path}/release.zip');

      await reportStage('downloading', 'Download del pacchetto…', value: 0);

      final request = await client
          .send(http.Request('GET', Uri.parse(update.url)))
          .timeout(const Duration(seconds: 30));

      if (request.statusCode != 200) {
        throw StateError('Download non disponibile (${request.statusCode}).');
      }

      var received = 0;
      final sink = archive.openWrite();
      final downloadClock = Stopwatch()..start();
      var lastProgress = -100;

      try {
        await sink.addStream(
          request.stream.timeout(const Duration(seconds: 60)).map((chunk) {
            received += chunk.length;
            if (received > update.bytes) {
              throw StateError('Dimensione del pacchetto non valida.');
            }
            if (downloadClock.elapsedMilliseconds - lastProgress >= 100) {
              progress.value = (
                message:
                    'Download: ${(received / 1048576).toStringAsFixed(1)} / ${(update.bytes / 1048576).toStringAsFixed(1)} MB',
                value: received / update.bytes,
              );
              lastProgress = downloadClock.elapsedMilliseconds;
            }
            return chunk;
          }),
        );
        await sink.flush();
      } finally {
        await sink.close();
      }

      if (received != update.bytes) {
        throw StateError(
          'Integrità del pacchetto non valida. Nessun file installato.',
        );
      }

      await reportStage(
        'verifying',
        'Verifica SHA-256 del pacchetto…',
        value: 0,
      );
      await oculumVerifyUpdateArchive(
        archive.path,
        expectedBytes: update.bytes,
        expectedSha256: update.sha256,
        onProgress: (bytes, total) => progress.value = (
          message: 'Verifica SHA-256: ${(100 * bytes / total).floor()}%',
          value: bytes / total,
        ),
      );

      // The download may take minutes while online state changes. Persist and
      // verify again before an installer exists; a refused write must leave the
      // current application running instead of handing off an older save.
      await reportStage('backup', 'Conferma del salvataggio più recente…');
      final latestRawBackup = await verifyLatestSave();
      if (latestRawBackup != rawBackup) {
        await writeUpdateBackup(latestRawBackup);
      }

      await reportStage(
        'preparing',
        'Preparazione dell’installazione verificata…',
      );
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
          'startupTimeoutSeconds': 45,
          'attemptId': staging.uri.pathSegments.where((s) => s.isNotEmpty).last,
        }),
        flush: true,
      );

      if (Platform.isAndroid) {
        await const MethodChannel(
          'com.mich.oculum/update',
        ).invokeMethod<void>('installApk', {'archive': archive.path});

        await reportStage(
          'installer_opened',
          'Conferma di installazione Android aperta.',
        );

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
        flush: true,
      );

      await reportStage(
        'handoff',
        'Avvio del programma di installazione e riavvio…',
      );

      if (Platform.isWindows) {
        // Start-Process creates a detached hidden helper; it waits for this PID.

        final arguments =
            '-NoProfile -ExecutionPolicy Bypass -File "${helper.path}" "${config.path}"';
        final command =
            "\$ErrorActionPreference = 'Stop'; Start-Process -WindowStyle Hidden -FilePath powershell.exe -ArgumentList ${_psUpdateQuote(arguments)}";

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

      exit(0);
    } catch (error) {
      if (staging != null) {
        try {
          await File('${staging.path}/frontend-status.json').writeAsString(
            jsonEncode({
              'state': 'frontend_error',
              'stage': stage,
              'message': '$error',
              'commit': selectedUpdate?.commit,
              'edition': oculumUsesIsolatedSaveProfile ? 'test' : 'normal',
              'updatedAtUtc': DateTime.now().toUtc().toIso8601String(),
            }),
            flush: true,
          );
        } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Aggiornamento non riuscito durante ${switch (stage) {
                'checking' => 'il controllo della versione',
                'backup' => 'la verifica del backup',
                'downloading' => 'il download',
                'verifying' => 'la verifica del pacchetto',
                _ => 'la preparazione dell’installazione',
              }}. I salvataggi sono conservati. Puoi riprovare.',
            ),
          ),
        );
      }
    } finally {
      client.close();
      if (progressRoute?.isActive ?? false) {
        progressRoute!.navigator?.removeRoute(progressRoute);
      }
      progress.dispose();
      if (mounted) setState(() => oculumUpdateBusy = false);
    }
  }

  String _psUpdateQuote(String value) => "'${value.replaceAll("'", "''")}'";
}
