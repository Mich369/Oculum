import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../services/oculum_download_artifacts.dart';

class OculumWebDownloads extends StatefulWidget {
  const OculumWebDownloads({super.key, this.client, this.color});
  final http.Client? client;
  final Color? color;

  @override
  State<OculumWebDownloads> createState() => _OculumWebDownloadsState();
}

class _OculumWebDownloadsState extends State<OculumWebDownloads> {
  late final http.Client _client = widget.client ?? http.Client();
  List<OculumDownloadArtifact>? _artifacts;
  bool _loading = false;
  bool _failed = false;

  Future<void> _load() async {
    if (_loading || _artifacts != null) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final artifacts = await oculumFetchDownloadArtifacts(_client);
      if (mounted) setState(() => _artifacts = artifacts);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _open(Uri url) =>
      unawaited(launchUrl(url, mode: LaunchMode.externalApplication));

  @override
  void dispose() {
    if (widget.client == null) _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();
    return MenuAnchor(
      style: MenuStyle(
        maximumSize: WidgetStatePropertyAll(
          Size(340, MediaQuery.sizeOf(context).height * .55),
        ),
      ),
      menuChildren: [
        if (_loading)
          const MenuItemButton(
            onPressed: null,
            child: Text('Caricamento download…'),
          ),
        if (_failed)
          MenuItemButton(
            onPressed: _load,
            child: const Text('Riprova a caricare i download'),
          ),
        if (!_loading && !_failed && _artifacts?.isEmpty == true)
          const MenuItemButton(
            onPressed: null,
            child: Text('Nessun artifact disponibile'),
          ),
        for (final artifact in _artifacts ?? <OculumDownloadArtifact>[])
          MenuItemButton(
            onPressed: () => _open(artifact.url),
            leadingIcon: const Icon(Icons.download_outlined),
            child: SizedBox(
              width: 230,
              child: Text(
                '${artifact.name}\n${(artifact.bytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                maxLines: 3,
              ),
            ),
          ),
        const Divider(),
        MenuItemButton(
          onPressed: () => _open(Uri.parse(oculumBuildDownloadsUrl)),
          child: const Text('Apri tutti i download su GitHub'),
        ),
        const Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            width: 250,
            child: Text(
              'Ultime build riuscite per ogni piattaforma. Download gratuiti, senza account.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
      builder: (context, controller, child) => IconButton(
        key: const ValueKey('oculum_public_downloads'),
        tooltip: 'Scarica Oculum',
        onPressed: () {
          if (controller.isOpen) {
            controller.close();
          } else {
            unawaited(_load());
            controller.open();
          }
        },
        icon: Icon(Icons.download_outlined, color: widget.color),
      ),
    );
  }
}
