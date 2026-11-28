import 'dart:async';

import 'package:flutter/material.dart';

import 'oculum_auth_service.dart';
import 'oculum_cloud_save_service.dart';

typedef OculumReadCloudBackup =
    Future<Map<String, dynamic>?> Function(
      String accountId,
      bool Function() stillAuthorized,
    );
typedef OculumRestoreCloudBackup =
    Future<bool> Function(
      Map<String, dynamic> payload,
      bool Function() stillAuthorized,
    );

class OculumCloudSavesDialog extends StatefulWidget {
  const OculumCloudSavesDialog({
    super.key,
    required this.auth,
    required this.cloud,
    required this.accountId,
    required this.readLocalBackup,
    required this.restoreLocalBackup,
  });

  final OculumAuthService auth;
  final OculumCloudSaveService cloud;
  final String accountId;
  final OculumReadCloudBackup readLocalBackup;
  final OculumRestoreCloudBackup restoreLocalBackup;

  @override
  State<OculumCloudSavesDialog> createState() => _OculumCloudSavesDialogState();
}

class _OculumCloudSavesDialogState extends State<OculumCloudSavesDialog> {
  final _currentFolder = OculumCloudSaveFolder.forOrigin(
    currentOculumCloudDeviceOrigin(),
  );
  late OculumCloudSaveFolder _folder = _currentFolder;
  List<OculumCloudSaveSummary> _copies = [];
  int _nextOffset = 0;
  bool _more = false;
  bool _busy = false;
  bool _writingLocal = false;
  bool _sessionEnded = false;
  String? _message;

  bool get _sessionMatches =>
      widget.auth.state.canSyncToCloud &&
      !widget.auth.isSigningOut &&
      widget.auth.state.userId == widget.accountId &&
      widget.cloud.isCurrentAccount(widget.accountId);

  bool _stillAuthorized() => mounted && !_sessionEnded && _sessionMatches;

  @override
  void initState() {
    super.initState();
    widget.auth.addListener(_accountChanged);
    if (_sessionMatches) {
      unawaited(_load());
    } else {
      _sessionEnded = true;
    }
  }

  void _accountChanged() {
    if (!mounted || _sessionEnded || _sessionMatches) return;
    setState(() {
      _sessionEnded = true;
      _copies = [];
      _more = false;
    });
  }

  @override
  void dispose() {
    widget.auth.removeListener(_accountChanged);
    super.dispose();
  }

  Future<void> _readPage({required bool append}) async {
    final offset = append ? _nextOffset : 0;
    final list = await widget.cloud.listFolder(
      widget.accountId,
      _folder,
      offset: offset,
    );
    if (!_stillAuthorized()) return;
    setState(() {
      _copies = {
        if (append)
          for (final copy in _copies) copy.id: copy,
        for (final copy in list) copy.id: copy,
      }.values.toList();
      _nextOffset = offset + list.length;
      _more = list.length == OculumCloudSaveService.folderPageSize;
    });
  }

  Future<void> _run(
    Future<void> Function() action, {
    required String failureMessage,
  }) async {
    if (_busy || !_stillAuthorized()) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
    } catch (_) {
      if (_stillAuthorized()) setState(() => _message = failureMessage);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _writingLocal = false;
        });
      }
    }
  }

  Future<void> _load({bool append = false}) => _run(
    () => _readPage(append: append),
    failureMessage: 'Impossibile leggere la cartella cloud. Riprova.',
  );

  Future<void> _save() => _run(() async {
    final payload = await widget.readLocalBackup(
      widget.accountId,
      _stillAuthorized,
    );
    if (!_stillAuthorized()) return;
    final saved =
        payload != null &&
        await widget.cloud.uploadSnapshot(widget.accountId, payload);
    if (!_stillAuthorized()) return;
    if (!saved) {
      setState(() => _message = 'Copia cloud non confermata.');
      return;
    }
    setState(() {
      _folder = _currentFolder;
      _copies = [];
      _more = false;
      _message = 'Copia salvata in ${_folder.label}.';
    });
    try {
      await _readPage(append: false);
    } catch (_) {
      if (_stillAuthorized()) {
        setState(() => _message = 'Copia salvata. Aggiorna l’elenco.');
      }
    }
  }, failureMessage: 'Impossibile creare la copia cloud. Riprova.');

  Future<void> _restore(OculumCloudSaveSummary copy) async {
    if (_busy || !_stillAuthorized()) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Ripristinare questa copia?'),
        content: Text(
          '${_copyLabel(dialog, copy)}\n\n'
          'La copia selezionata diventerà il salvataggio di questo dispositivo. '
          'Oculum conserva prima una copia locale dei dati attuali.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Ripristina su questo dispositivo'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() async {
      final payload = await widget.cloud.fetchSnapshotForRestore(
        widget.accountId,
        copy.id,
      );
      if (!_stillAuthorized()) return;
      if (payload == null) {
        setState(() => _message = 'La copia non è più disponibile.');
        return;
      }
      setState(() => _writingLocal = true);
      final restored = await widget.restoreLocalBackup(
        payload,
        _stillAuthorized,
      );
      if (_stillAuthorized()) {
        setState(() {
          _message = restored
              ? 'Copia ripristinata su questo dispositivo.'
              : 'Ripristino non confermato.';
        });
      }
    }, failureMessage: 'Impossibile ripristinare la copia. Riprova.');
  }

  String _copyLabel(BuildContext context, OculumCloudSaveSummary copy) {
    final localizations = MaterialLocalizations.of(context);
    final updated = copy.updatedAt.toLocal();
    final date = localizations.formatCompactDate(updated);
    final time = localizations.formatTimeOfDay(TimeOfDay.fromDateTime(updated));
    final origin = switch (copy.deviceOrigin) {
      'windows' => 'Windows',
      'macos' => 'macOS',
      'linux' => 'Linux',
      'android' => 'Android',
      'ios' => 'iOS',
      'web' => 'Web',
      _ => OculumCloudSaveFolder.older.label,
    };
    return '$origin · $date $time';
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_writingLocal,
    child: AlertDialog(
      scrollable: true,
      title: const Text('Salvataggi cloud'),
      content: SizedBox(
        width: 480,
        child: _sessionEnded
            ? const Text('Sessione cambiata. Riapri i salvataggi dall’account.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final folder in OculumCloudSaveFolder.values)
                        ChoiceChip(
                          label: Text(folder.label),
                          selected: folder == _folder,
                          onSelected: _busy
                              ? null
                              : (selected) {
                                  if (!selected || _folder == folder) return;
                                  setState(() {
                                    _folder = folder;
                                    _copies = [];
                                    _more = false;
                                  });
                                  unawaited(_load());
                                },
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_busy) const LinearProgressIndicator(),
                  if (_message case final message?) Text(message),
                  if (!_busy && _copies.isEmpty && _message == null)
                    const Text('Nessuna copia in questa cartella.'),
                  for (final copy in _copies)
                    ListTile(
                      key: ValueKey(copy.id),
                      contentPadding: EdgeInsets.zero,
                      title: Text(_copyLabel(context, copy)),
                      trailing: const Icon(Icons.restore),
                      enabled: !_busy,
                      onTap: _busy ? null : () => _restore(copy),
                    ),
                  if (_more)
                    TextButton(
                      onPressed: _busy ? null : () => _load(append: true),
                      child: const Text('Altre copie'),
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Aggiorna'),
                      ),
                      FilledButton.icon(
                        onPressed: _busy ? null : _save,
                        icon: const Icon(Icons.cloud_upload_outlined),
                        label: const Text('Salva copia di questo dispositivo'),
                      ),
                    ],
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: _writingLocal ? null : () => Navigator.pop(context),
          child: const Text('Chiudi'),
        ),
      ],
    ),
  );
}
