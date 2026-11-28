import 'dart:async';

import 'package:flutter/material.dart';

import 'oculum_campaign_directory.dart';

/// Displays only server-authorized directory labels for the active account.
class OculumCampaignDirectoryPanel extends StatefulWidget {
  const OculumCampaignDirectoryPanel({
    super.key,
    required this.accountChanges,
    required this.currentAccountId,
    required this.load,
    required this.openOwn,
    required this.openShared,
    required this.english,
    required this.accent,
    this.activeCampaignId = '',
    this.activeShareRoomId,
    this.setSharing,
    this.renameMaster,
  });

  final Listenable accountChanges;
  final String? Function() currentAccountId;
  final Future<OculumCampaignDirectory> Function(String accountId) load;
  final Future<void> Function(String accountId, OculumOtherDeviceCampaign item)
  openOwn;
  final Future<void> Function(String accountId, OculumSharedCampaign item)
  openShared;
  final bool english;
  final Color accent;
  final String activeCampaignId;
  final String? activeShareRoomId;
  final Future<void> Function(String accountId, bool share)? setSharing;
  final Future<void> Function(String accountId)? renameMaster;

  @override
  State<OculumCampaignDirectoryPanel> createState() =>
      _OculumCampaignDirectoryPanelState();
}

class _OculumCampaignDirectoryPanelState
    extends State<OculumCampaignDirectoryPanel>
    with WidgetsBindingObserver {
  String? _accountId;
  OculumCampaignDirectory? _directory;
  int _generation = 0;
  bool _busy = false;
  bool _failed = false;

  String _t(String italian, String english) =>
      widget.english ? english : italian;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.accountChanges.addListener(_accountChanged);
    _accountChanged();
  }

  @override
  void didUpdateWidget(OculumCampaignDirectoryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.accountChanges != oldWidget.accountChanges) {
      oldWidget.accountChanges.removeListener(_accountChanged);
      widget.accountChanges.addListener(_accountChanged);
    }
    _accountChanged();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _accountId != null && !_busy) {
      unawaited(_reload());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.accountChanges.removeListener(_accountChanged);
    super.dispose();
  }

  bool _isCurrent(String id, int generation) =>
      mounted &&
      _accountId == id &&
      widget.currentAccountId() == id &&
      generation == _generation;

  void _accountChanged() {
    final account = widget.currentAccountId();
    if (_accountId == account) return;
    final generation = ++_generation;
    setState(() {
      _accountId = account;
      _directory = null;
      _busy = account != null;
      _failed = false;
    });
    if (account != null) unawaited(_request(account, generation));
  }

  Future<void> _reload() async {
    final account = _accountId;
    if (account == null || widget.currentAccountId() != account || _busy) {
      return;
    }
    final generation = ++_generation;
    setState(() {
      _directory = null;
      _busy = true;
      _failed = false;
    });
    await _request(account, generation);
  }

  Future<void> _request(String account, int generation) async {
    try {
      final result = await widget.load(account);
      if (!_isCurrent(account, generation)) return;
      setState(() {
        _directory = result;
        _busy = false;
      });
    } catch (_) {
      if (!_isCurrent(account, generation)) return;
      setState(() {
        _directory = null;
        _busy = false;
        _failed = true;
      });
    }
  }

  void _notice(String message) => ScaffoldMessenger.maybeOf(
    context,
  )?.showSnackBar(SnackBar(content: Text(message)));

  Future<void> _act(Future<void> Function(String, int) action) async {
    final account = _accountId;
    if (account == null || widget.currentAccountId() != account || _busy) {
      return;
    }
    final generation = ++_generation;
    setState(() => _busy = true);
    try {
      await action(account, generation);
    } catch (_) {
      if (!_isCurrent(account, generation)) return;
      setState(() {
        _directory = null;
        _failed = true;
      });
    } finally {
      if (_isCurrent(account, generation)) setState(() => _busy = false);
    }
  }

  Future<void> _openShared(OculumSharedCampaign previous) =>
      _act((account, generation) async {
        final current = await widget.load(account);
        if (!_isCurrent(account, generation)) return;
        setState(() => _directory = current);
        final item = current.shared.where((row) {
          return row.roomId == previous.roomId &&
              row.ownerId == previous.ownerId &&
              row.campaignId == previous.campaignId;
        }).firstOrNull;
        if (item == null) {
          _notice(
            _t(
              'La campagna non è più condivisa con te.',
              'This campaign is no longer shared with you.',
            ),
          );
          return;
        }
        await widget.openShared(account, item);
      });

  Future<void> _manage(Future<void> Function(String) action) => _act((
    account,
    generation,
  ) async {
    await action(account);
    if (_isCurrent(account, generation)) await _request(account, generation);
  });

  String _platform(String platform) => switch (platform) {
    'windows' => 'Windows',
    'macos' => 'macOS',
    'linux' => 'Linux',
    'android' => 'Android',
    'ios' => 'iOS',
    'web' => 'Web',
    _ => _t('Altro dispositivo', 'Other device'),
  };

  @override
  Widget build(BuildContext context) {
    final account = _accountId;
    if (account == null || widget.currentAccountId() != account) {
      return Text(
        _t(
          'Accedi per vedere campagne sugli altri dispositivi e condivise.',
          'Sign in to see campaigns on other devices and shared campaigns.',
        ),
      );
    }
    final directory = _directory;
    final groups = <String, List<OculumSharedCampaign>>{};
    for (final item in directory?.shared ?? const <OculumSharedCampaign>[]) {
      groups.putIfAbsent(item.ownerId, () => []).add(item);
    }
    final owners = groups.values.toList()
      ..sort(
        (a, b) => a.first.ownerName.toLowerCase().compareTo(
          b.first.ownerName.toLowerCase(),
        ),
      );
    final room = widget.activeShareRoomId;
    final sharing =
        room != null &&
        (directory?.ownedShares.any(
              (item) =>
                  item.roomId == room &&
                  item.campaignId == widget.activeCampaignId,
            ) ??
            false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _t('Campagne online', 'Online campaigns'),
                style: TextStyle(
                  color: widget.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              key: const ValueKey('campaign-directory-refresh'),
              tooltip: _t(
                'Aggiorna campagne online',
                'Refresh online campaigns',
              ),
              onPressed: _busy ? null : _reload,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        if (_busy) const LinearProgressIndicator(),
        if (_failed)
          Text(
            _t(
              'Elenco online non disponibile. Aggiorna per riprovare.',
              'Online list unavailable. Refresh to try again.',
            ),
          ),
        if (directory != null) ...[
          ExpansionTile(
            key: PageStorageKey('campaign-devices:$account'),
            leading: const Icon(Icons.devices_outlined),
            title: Text(_t('Altri dispositivi', 'Other devices')),
            children: [
              if (directory.otherDevices.isEmpty)
                ListTile(
                  title: Text(
                    _t(
                      'Nessuna campagna Master su altri dispositivi.',
                      'No Master campaigns on other devices.',
                    ),
                  ),
                ),
              for (final item in directory.otherDevices)
                ListTile(
                  key: ValueKey((item.deviceId, item.campaignId)),
                  title: Text(item.campaignName),
                  subtitle: Text(_platform(item.platform)),
                  trailing: const Icon(Icons.cloud_download_outlined),
                  onTap: _busy
                      ? null
                      : () => _act((id, _) => widget.openOwn(id, item)),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: 8,
              top: 8,
              bottom: 4,
            ),
            child: Text(
              _t('Condivise dai Master', 'Shared by Masters'),
              style: TextStyle(
                color: widget.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (owners.isEmpty)
            ListTile(
              dense: true,
              title: Text(
                _t(
                  'Nessuna campagna condivisa con te.',
                  'No campaigns shared with you.',
                ),
              ),
            ),
          for (final campaigns in owners)
            ExpansionTile(
              key: PageStorageKey((
                'campaign-master',
                account,
                campaigns.first.ownerId,
              )),
              leading: const Icon(Icons.folder_outlined),
              title: Text(campaigns.first.ownerName),
              children: [
                for (final item in campaigns)
                  ListTile(
                    key: ValueKey((item.roomId, item.campaignId)),
                    title: Text(item.campaignName),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: _busy ? null : () => _openShared(item),
                  ),
              ],
            ),
          if (widget.renameMaster != null ||
              (room != null && widget.setSharing != null))
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (widget.renameMaster case final rename?)
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _manage(rename),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(
                      _t('Nome Master visibile', 'Visible Master name'),
                    ),
                  ),
                if (room != null && widget.setSharing != null)
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () =>
                              _manage((id) => widget.setSharing!(id, !sharing)),
                    icon: Icon(
                      sharing ? Icons.link_off : Icons.folder_shared_outlined,
                    ),
                    label: Text(
                      sharing
                          ? _t('Revoca condivisione', 'Revoke sharing')
                          : _t(
                              'Condividi campagna della stanza',
                              'Share room campaign',
                            ),
                    ),
                  ),
              ],
            ),
        ],
      ],
    );
  }
}
