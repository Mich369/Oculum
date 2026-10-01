part of '../../main.dart';

Uint8List? _oculumDecodePortrait(String raw) {
  try {
    return base64Decode(raw);
  } catch (_) {
    return null;
  }
}

class OculumDecodedImageCache {
  OculumDecodedImageCache({
    this.maxEntries = 64,
    this.maxBytes = 24 * 1024 * 1024,
  }) : assert(maxEntries > 0),
       assert(maxBytes > 0);

  final int maxEntries;
  final int maxBytes;
  final Map<String, Uint8List> _entries = <String, Uint8List>{};
  final Map<String, Future<Uint8List?>> _pending = {};
  final Queue<VoidCallback> _workerQueue = Queue<VoidCallback>();
  int _activeWorkers = 0;
  int _generation = 0;
  int _sizeBytes = 0;

  int get length => _entries.length;
  int get sizeBytes => _sizeBytes;

  bool containsRaw(String raw) {
    final key = _cacheKey(raw.trim());
    return key != null && _entries.containsKey(key);
  }

  Uint8List? decode(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return null;

    final key = _cacheKey(clean);
    if (key == null) return null;

    final cached = _entries.remove(key);
    if (cached != null) {
      _entries[key] = cached;
      return cached;
    }

    try {
      final bytes = base64Decode(clean);
      _store(key, bytes);
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> decodeAsync(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return Future.value();
    final cached = _entries.remove(clean);
    if (cached != null) {
      _entries[clean] = cached;
      return Future.value(cached);
    }
    return _pending.putIfAbsent(clean, () {
      final generation = _generation;
      return _decodeInWorker(clean)
          .then((bytes) {
            if (generation == _generation && bytes != null) {
              _store(clean, bytes);
            }
            return bytes;
          })
          .whenComplete(() {
            if (generation == _generation) _pending.remove(clean);
          });
    });
  }

  Future<Uint8List?> _decodeInWorker(String raw) {
    final result = Completer<Uint8List?>();
    _workerQueue.add(() {
      compute(_oculumDecodePortrait, raw, debugLabel: 'oculum-portrait')
          .then(
            result.complete,
            onError: (Object error, StackTrace stack) => result.complete(null),
          )
          .whenComplete(() {
            _activeWorkers--;
            _pumpWorkers();
          });
    });
    _pumpWorkers();
    return result.future;
  }

  void _pumpWorkers() {
    while (_activeWorkers < 2 && _workerQueue.isNotEmpty) {
      _activeWorkers++;
      _workerQueue.removeFirst()();
    }
  }

  void clear() {
    _generation++;
    _pending.clear();
    _entries.clear();
    _sizeBytes = 0;
  }

  String? _cacheKey(String clean) {
    if (clean.isEmpty) return null;
    // Full content equality prevents unrelated images with identical sampled
    // prefixes/middles/suffixes from sharing an entry. The original is retained.
    return clean;
  }

  void _store(String key, Uint8List bytes) {
    final previous = _entries.remove(key);
    if (previous != null) _sizeBytes -= previous.lengthInBytes;

    if (bytes.lengthInBytes > maxBytes) {
      _trim();
      return;
    }

    _entries[key] = bytes;
    _sizeBytes += bytes.lengthInBytes;
    _trim();
  }

  void _trim() {
    while (_entries.length > maxEntries || _sizeBytes > maxBytes) {
      final oldestKey = _entries.keys.first;
      final oldest = _entries.remove(oldestKey);
      if (oldest == null) break;
      _sizeBytes -= oldest.lengthInBytes;
    }
    if (_sizeBytes < 0) _sizeBytes = 0;
  }
}

/// Visible avatars decode in a worker and keep their Future across parent
/// rebuilds. Original bytes remain untouched in the sheet and in storage.
class OculumAsyncPortrait extends StatefulWidget {
  const OculumAsyncPortrait({
    super.key,
    required this.raw,
    required this.cache,
    required this.fallback,
    required this.cacheSide,
  });
  final String raw;
  final OculumDecodedImageCache cache;
  final Widget fallback;
  final int cacheSide;
  @override
  State<OculumAsyncPortrait> createState() => _OculumAsyncPortraitState();
}

class _OculumAsyncPortraitState extends State<OculumAsyncPortrait> {
  late Future<Uint8List?> bytes;
  @override
  void initState() {
    super.initState();
    bytes = widget.cache.decodeAsync(widget.raw);
  }

  @override
  void didUpdateWidget(OculumAsyncPortrait oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.raw != widget.raw || oldWidget.cache != widget.cache) {
      bytes = widget.cache.decodeAsync(widget.raw);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: bytes,
    builder: (context, snapshot) =>
        snapshot.connectionState == ConnectionState.done &&
            snapshot.data != null
        ? Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            cacheWidth: widget.cacheSide,
            cacheHeight: widget.cacheSide,
            gaplessPlayback: true,
            errorBuilder: (_, error, stack) => widget.fallback,
          )
        : widget.fallback,
  );
}

extension _OculumHomeImageCache on _OculumHomePageState {
  Uint8List? decodedBase64ImageCached(String raw) {
    return decodedImageBase64Cache.decode(raw);
  }
}
