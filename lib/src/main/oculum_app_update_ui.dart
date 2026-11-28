part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

const _oculumAndroidUpdateChannel = MethodChannel('com.mich.oculum/update');

Future<OculumAndroidIncrementalPlan?> _oculumPrepareAndroidUpdate(
  http.Client client,
  OculumAppUpdate update,
) async {
  final reference = update.incremental;
  if (reference == null || reference.edition != 'android') return null;
  final installed = await _oculumAndroidUpdateChannel
      .invokeMapMethod<String, Object?>('installedApk');
  final source = installed?['path'];
  final version = installed?['versionCode'];
  if (source is! String || source.isEmpty || version is! int) return null;

  var uri = Uri.parse(reference.url);
  for (var redirects = 0; redirects < 5; redirects++) {
    if (uri.scheme != 'https' ||
        uri.port != 443 ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment ||
        !const {
          'github.com',
          'release-assets.githubusercontent.com',
          'objects.githubusercontent.com',
        }.contains(uri.host)) {
      throw StateError('Indirizzo del manifesto Android non valido.');
    }
    final request = http.Request('GET', uri)..followRedirects = false;
    request.headers['Accept-Encoding'] = 'identity';
    final response = await client
        .send(request)
        .timeout(const Duration(seconds: 25));
    if (const {301, 302, 303, 307, 308}.contains(response.statusCode)) {
      final location = response.headers['location'];
      await response.stream.listen(null).cancel();
      if (location == null || location.isEmpty) break;
      uri = uri.resolve(location);
      continue;
    }
    final length = response.contentLength;
    if (response.statusCode != 200 ||
        (length != null && length != reference.bytes) ||
        !const {
          null,
          'identity',
        }.contains(response.headers['content-encoding'])) {
      await response.stream.listen(null).cancel();
      throw StateError('Manifesto Android non disponibile.');
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response.stream.timeout(
      const Duration(seconds: 30),
    )) {
      if (bytes.length + chunk.length > reference.bytes) {
        throw StateError('Dimensione del manifesto Android non valida.');
      }
      bytes.add(chunk);
    }
    if (bytes.length != reference.bytes) {
      throw StateError('Dimensione del manifesto Android non valida.');
    }
    final plan = await OculumAndroidIncrementalPlan.prepare(
      manifestBytes: bytes.takeBytes(),
      manifestSha256: reference.sha256,
      commit: update.commit,
      runId: update.runId,
      apkUrl: Uri.parse(reference.packageUrl),
      apkBytes: reference.packageBytes,
      apkSha256: reference.packageSha256,
      installedApk: File(source),
      installedVersionCode: version,
    );
    return plan.isNoOp ||
            (plan.canStage &&
                plan.downloadBytes + reference.bytes < update.bytes)
        ? plan
        : null;
  }
  throw StateError('Manifesto Android non disponibile.');
}

class _OculumWindowsUpdatePlan {
  const _OculumWindowsUpdatePlan(this.work, this.config, this.preview);

  final Directory work;
  final Map<String, Object> config;
  final Map<String, dynamic> preview;

  int get files => preview['downloadCount'] as int;
  int get bytes => preview['downloadBytes'] as int;
  int get changed => preview['changedCount'] as int;
  int get removed => preview['removeCount'] as int;
  bool get isNoOp => changed == 0 && removed == 0;

  static String _digest(Uint8List bytes) => SHA256Digest()
      .process(bytes)
      .map((value) => value.toRadixString(16).padLeft(2, '0'))
      .join();

  static Future<void> _runDriver(Directory work, String mode) async {
    final result = await Process.run('powershell.exe', [
      '-NoProfile',
      '-NonInteractive',
      '-ExecutionPolicy',
      'Bypass',
      '-File',
      '${work.path}/incremental_driver.ps1',
      '-Mode',
      mode,
      '-ConfigPath',
      '${work.path}/incremental-config.json',
    ]);
    if (result.exitCode != 0) {
      throw StateError(
        mode == 'Plan'
            ? 'Non è stato possibile confrontare i file installati.'
            : 'Download incrementale interrotto. Puoi riprovare.',
      );
    }
  }

  static Future<void> _downloadIndex(
    http.Client client,
    File file,
    String url,
    int size,
    String checksum,
  ) async {
    final response = await client
        .send(http.Request('GET', Uri.parse(url)))
        .timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) throw StateError('Indice non disponibile.');
    final output = file.openWrite();
    var length = 0;
    try {
      await output.addStream(
        response.stream.timeout(const Duration(seconds: 30)).map((chunk) {
          length += chunk.length;
          if (length > size) {
            throw StateError('Indice oltre la dimensione attesa.');
          }
          return chunk;
        }),
      );
    } finally {
      await output.close();
    }
    await oculumVerifyUpdateArchive(
      file.path,
      expectedBytes: size,
      expectedSha256: checksum,
    );
  }

  static Future<_OculumWindowsUpdatePlan> prepare(
    http.Client client,
    OculumAppUpdate update,
  ) async {
    final reference = update.incremental!;
    final cache = await getApplicationCacheDirectory();
    final work = await cache.createTemp('oculum-update-${update.runId}-');
    final manifest = File('${work.path}/incremental-target.json');
    final helper = File('${work.path}/oculum_incremental_windows.ps1');
    final code = await rootBundle.load(
      'assets/update/oculum_incremental_windows.ps1',
    );
    final bytes = code.buffer.asUint8List(
      code.offsetInBytes,
      code.lengthInBytes,
    );
    final helperSha = _digest(bytes);
    await helper.writeAsBytes(bytes, flush: true);
    await File('${work.path}/incremental_driver.ps1').writeAsString(
      await rootBundle.loadString('assets/update/incremental_driver.ps1'),
      flush: true,
    );
    await _downloadIndex(
      client,
      manifest,
      reference.url,
      reference.bytes,
      reference.sha256,
    );
    final executable = File(Platform.resolvedExecutable).absolute.path;
    final cacheId = _digest(
      utf8.encode(
        '${executable.toLowerCase()}\n${reference.edition}\n${reference.sha256}',
      ),
    );
    final config = <String, Object>{
      'work': work.absolute.path,
      'executable': executable,
      'commit': update.commit,
      'edition': reference.edition,
      'incrementalManifest': manifest.absolute.path,
      'incrementalManifestSha256': reference.sha256,
      'incrementalHelper': helper.absolute.path,
      'incrementalHelperSha256': helperSha,
      'incrementalPlan': '${work.path}/incremental-stage.json',
      'incrementalRunId': update.runId,
      'incrementalPackageUrl': reference.packageUrl,
      'incrementalPackageBytes': reference.packageBytes,
      'incrementalPackageSha256': reference.packageSha256,
      'incrementalCachedObjectsRoot':
          '${cache.path}${Platform.pathSeparator}oculum-update-objects-$cacheId',
    };
    final previous = await oculumFindInstalledWindowsManifest(
      client,
      reference.edition,
    );
    if (previous != null) {
      final source = File('${work.path}/incremental-source.json');
      try {
        await _downloadIndex(
          client,
          source,
          previous.url,
          previous.bytes,
          previous.sha256,
        );
        config['incrementalSourceManifest'] = source.absolute.path;
        config['incrementalSourceManifestSha256'] = previous.sha256;
        config['incrementalSourceCommit'] = oculumSourceCommit;
      } catch (_) {
        // A legacy version without a verifiable index can still update the
        // managed destination, while all obsolete paths are left alone.
      }
    }
    await File(
      '${work.path}/incremental-config.json',
    ).writeAsString(jsonEncode(config), flush: true);
    await _runDriver(work, 'Plan');
    final raw = await File(
      '${work.path}/incremental-preview.json',
    ).readAsString();
    final preview =
        jsonDecode(raw.replaceFirst('\uFEFF', '')) as Map<String, dynamic>;
    if (preview['commit'] != update.commit ||
        preview['edition'] != reference.edition ||
        ['downloadCount', 'downloadBytes', 'changedCount', 'removeCount'].any((
          key,
        ) {
          final value = preview[key];
          return value is! int || value < 0;
        })) {
      throw StateError('Piano di aggiornamento non valido.');
    }
    return _OculumWindowsUpdatePlan(work, config, preview);
  }

  Future<String> stage() async {
    await _runDriver(work, 'Stage');
    final raw = await File(
      '${work.path}/incremental-stage.json',
    ).readAsString();
    final receipt = jsonDecode(raw.replaceFirst('\uFEFF', '')) as Map;
    final name = '${receipt['runtimeDirectoryName']}';
    if (!RegExp(r'^incremental-runtime-[a-f0-9]{32}$').hasMatch(name)) {
      throw StateError('Cartella di installazione incrementale non valida.');
    }
    return '${work.path}${Platform.pathSeparator}$name';
  }
}

String _oculumUpdateMegabytes(int bytes) =>
    '${(bytes / 1000000).toStringAsFixed(2)} MB';

@visibleForTesting
Future<bool> oculumConfirmAppUpdate(
  BuildContext context, {
  required String description,
  bool incremental = false,
  String? fullArchiveSize,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Aggiorna Oculum'),
          content: SingleChildScrollView(child: Text(description)),
          actions: [
            TextButton(
              autofocus: fullArchiveSize != null,
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Dopo'),
            ),
            if (fullArchiveSize != null)
              TextButton(
                onPressed: () => Navigator.pop(dialog, true),
                child: Text('Pacchetto intero ($fullArchiveSize)'),
              )
            else
              FilledButton(
                onPressed: () => Navigator.pop(dialog, true),
                child: Text(
                  incremental ? 'Scarica le modifiche' : 'Aggiorna ora',
                ),
              ),
          ],
        ),
      ) ??
      false;
}

Future<bool> _oculumWebBuildIsPublished(
  http.Client client,
  String commit,
) async {
  try {
    final marker = Uri.base
        .resolve('oculum-build.json')
        .replace(queryParameters: {'version': commit});
    final response = await client
        .get(marker)
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200 || response.body.length > 256) return false;
    final payload = jsonDecode(response.body);
    return payload is Map && payload['commit'] == commit;
  } catch (_) {
    return false;
  }
}

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
        final versionIdentity = oculumVersionLogIdentity(oculumSourceCommit);
        final prefs = await _prefs().timeout(const Duration(seconds: 3));
        if (!mounted || !oculumShouldShowVersionLog(prefs, versionIdentity)) {
          return;
        }
        final text = await rootBundle
            .loadString(oculumCumulativeLogAsset)
            .timeout(const Duration(seconds: 3));
        if (!mounted) return;
        await oculumRememberVersionLog(prefs, versionIdentity);
        if (!mounted) return;
        await oculumShowVersionLogDialog(context, text, versionIdentity);
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
    if (oculumSmokeStorageActive) return;
    if (!kIsWeb && Platform.isIOS) return;
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

      if (kIsWeb && !await _oculumWebBuildIsPublished(client, update.commit)) {
        return;
      }
      if (!mounted) return;

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
    if (oculumSmokeStorageActive) return;
    if (oculumUpdateBusy) return;
    if (!kIsWeb && Platform.isIOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Su iPhone aggiorna Oculum dallo stesso canale da cui l’hai installato.',
          ),
        ),
      );
      return;
    }

    setState(() => oculumUpdateBusy = true);

    final client = http.Client();

    Directory? staging;
    File? androidCandidate;
    _OculumWindowsUpdatePlan? windowsPlan;
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

      if (kIsWeb && !await _oculumWebBuildIsPublished(client, update.commit)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'I download sono pronti. La nuova versione del sito è ancora in pubblicazione.',
              ),
            ),
          );
        }
        return;
      }
      if (!mounted) return;

      final windows = !kIsWeb && Platform.isWindows;
      final android = !kIsWeb && Platform.isAndroid;
      OculumAndroidIncrementalPlan? androidPlan;
      if (android && update.incremental != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Confronto del pacchetto Android installato…'),
          ),
        );
        try {
          androidPlan = await _oculumPrepareAndroidUpdate(client, update);
        } catch (_) {
          // The full archive stays a separate, explicitly sized action.
        }
        if (!mounted) return;
      }
      if (windows && update.incremental != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Confronto dei file di Oculum installati…'),
          ),
        );
        try {
          windowsPlan = await _OculumWindowsUpdatePlan.prepare(client, update);
        } catch (_) {
          // An unavailable plan requires a separate choice of the full archive.
        }
        if (!mounted) return;
      }
      final plan = windowsPlan;
      if (plan?.isNoOp == true || androidPlan?.isNoOp == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'I file installati corrispondono già alla versione verificata.',
            ),
          ),
        );
        return;
      }
      final fullSize = _oculumUpdateMegabytes(update.bytes);
      final description = kIsWeb
          ? 'Salva e ricarica il sito.'
          : plan != null
          ? '${plan.changed} file da aggiornare, ${plan.removed} obsoleti da rimuovere. '
                'Download di ${plan.files} file per ${_oculumUpdateMegabytes(plan.bytes)}.'
          : androidPlan != null
          ? 'Scarica ${androidPlan.changedCount} parti per '
                '${_oculumUpdateMegabytes(androidPlan.downloadBytes)} e apre '
                'la conferma Android per l’APK firmato.'
          : windows || android
          ? 'Aggiornamento incrementale non disponibile. Puoi riprovare più tardi o scegliere il pacchetto intero.'
          : 'Scarica 1 pacchetto completo ($fullSize) e conserva un backup del runtime.';
      final confirmed = await oculumConfirmAppUpdate(
        context,
        description:
            'Nuova versione ${update.commit.substring(0, 7)}. $description '
            'I salvataggi vengono conservati.',
        incremental: plan != null || androidPlan != null,
        fullArchiveSize:
            (windows || android) && plan == null && androidPlan == null
            ? fullSize
            : null,
      );

      if (!confirmed || !mounted) return;
      final incremental = plan;

      if (!kIsWeb) {
        final cache = await getApplicationCacheDirectory();
        // Every retry owns fresh files; a previous helper or partial download
        // can never share its archive, config, status or extraction directory.
        staging =
            incremental?.work ??
            await Directory(
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
      String? incrementalRuntime;

      if (androidPlan != null) {
        await reportStage('downloading', 'Preparazione dell’APK incrementale…');
        androidCandidate = await androidPlan.stage(
          workDirectory: staging,
          client: client,
          onProgress: (received, total) => progress.value = (
            message: total == 0 || received == total
                ? 'Verifica dell’APK ricostruito…'
                : 'Download: ${_oculumUpdateMegabytes(received)} / '
                      '${_oculumUpdateMegabytes(total)}',
            value: total == 0 || received == total ? null : received / total,
          ),
        );
      } else if (incremental != null) {
        await reportStage(
          'downloading',
          'Download e verifica dei file modificati…',
        );
        incrementalRuntime = await incremental.stage();
      } else {
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
      }

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
      if (android) {
        final installerStatus = androidPlan == null
            ? await _oculumAndroidUpdateChannel.invokeMethod<String>(
                'installApk',
                {'archive': archive.path},
              )
            : await _oculumAndroidUpdateChannel
                  .invokeMethod<String>('installIncrementalApk', {
                    'apk': androidCandidate!.path,
                    'sha256': androidPlan.apkSha256,
                    'versionCode': androidPlan.versionCode,
                  });
        if (installerStatus != 'installer_opened' &&
            installerStatus != 'installer_permission_required') {
          throw StateError(
            'Impossibile confermare lo stato dell’installazione Android.',
          );
        }

        await reportStage(
          installerStatus!,
          installerStatus == 'installer_permission_required'
              ? 'Android richiede l’autorizzazione a installare Oculum.'
              : 'Conferma di installazione Android aperta.',
        );
        // Android has already copied and verified the separate APK it opens.
        // The downloaded ZIP is owned by this attempt and is no longer needed.
        try {
          if (await FileSystemEntity.type(archive.path, followLinks: false) ==
              FileSystemEntityType.file) {
            await archive.delete();
          }
        } catch (_) {
          // Cache cleanup must not change the successful installer handoff.
        }

        return;
      }

      final config = File('${staging.path}/update.json');

      final executable = File(Platform.resolvedExecutable).absolute.path;

      await config.writeAsString(
        jsonEncode({
          if (incremental == null) 'archive': archive.absolute.path,
          if (incremental != null) ...incremental.config,
          'incrementalRuntime': ?incrementalRuntime,
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
      final candidate = androidCandidate;
      if (candidate != null) {
        try {
          if (await FileSystemEntity.type(candidate.path, followLinks: false) ==
              FileSystemEntityType.file) {
            await candidate.delete();
          }
        } catch (_) {
          // Native Android owns the candidate after it moves it to the installer.
        }
      }
      if (progressRoute?.isActive ?? false) {
        progressRoute!.navigator?.removeRoute(progressRoute);
      }
      progress.dispose();
      if (mounted) setState(() => oculumUpdateBusy = false);
    }
  }

  String _psUpdateQuote(String value) => "'${value.replaceAll("'", "''")}'";
}
