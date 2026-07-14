part of '../../main.dart';

class OculumDecodedImageCache {
  OculumDecodedImageCache({
    this.maxEntries = 64,
    this.maxBytes = 24 * 1024 * 1024,
  }) : assert(maxEntries > 0),
       assert(maxBytes > 0);

  final int maxEntries;
  final int maxBytes;
  final Map<String, Uint8List> _entries = <String, Uint8List>{};
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

  void clear() {
    _entries.clear();
    _sizeBytes = 0;
  }

  String? _cacheKey(String clean) {
    if (clean.isEmpty) return null;
    return _oculumRawSampleSignature(clean);
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

extension _OculumHomeImageCache on _OculumHomePageState {
  Uint8List? decodedBase64ImageCached(String raw) {
    return decodedImageBase64Cache.decode(raw);
  }
}
