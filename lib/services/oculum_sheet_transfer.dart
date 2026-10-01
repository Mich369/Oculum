import 'dart:convert';

/// Partial transfers never reach the sheet importer; memory is bounded.
class OculumSheetTransferAssembler {
  static const chunkSize = 64 * 1024;
  static const maxChunks = 1024;
  static const maxBufferedCharacters = 64 * 1024 * 1024;
  final Map<String, _SheetTransfer> _pending = {};
  int _buffered = 0;

  void clear() {
    _pending.clear();
    _buffered = 0;
  }

  Map<String, dynamic>? accept(Map<String, dynamic> payload, DateTime now) {
    for (final key in _pending.keys.toList()) {
      if (now.difference(_pending[key]!.createdAt) >
          const Duration(minutes: 3)) {
        _remove(key);
      }
    }
    final id = payload['transferId'];
    final index = payload['chunkIndex'];
    final count = payload['chunkCount'];
    final data = payload['data'];
    if (id is! String ||
        id.isEmpty ||
        id.length > 200 ||
        index is! int ||
        count is! int ||
        count < 1 ||
        count > maxChunks ||
        index < 0 ||
        index >= count ||
        data is! String ||
        data.length > chunkSize ||
        data.isEmpty) {
      return null;
    }
    if (!_pending.containsKey(id) && _pending.length >= 8) return null;
    final transfer = _pending.putIfAbsent(id, () => _SheetTransfer(count, now));
    if (transfer.count != count) {
      _remove(id);
      return null;
    }
    final previous = transfer.chunks[index];
    if (previous != null) {
      if (previous != data) _remove(id);
      return null;
    }
    if (_buffered + data.length > maxBufferedCharacters) {
      _remove(id);
      return null;
    }
    transfer.chunks[index] = data;
    _buffered += data.length;
    if (transfer.chunks.length != count) return null;
    final encoded = List.generate(count, (i) => transfer.chunks[i]!).join();
    _remove(id);
    try {
      final decoded = jsonDecode(utf8.decode(base64Decode(encoded)));
      return decoded is Map<String, dynamic> && decoded['sheet'] is Map
          ? decoded
          : null;
    } on FormatException {
      return null;
    }
  }

  void _remove(String id) {
    final removed = _pending.remove(id);
    if (removed != null) {
      for (final chunk in removed.chunks.values) {
        _buffered -= chunk.length;
      }
    }
  }
}

class _SheetTransfer {
  _SheetTransfer(this.count, this.createdAt);
  final int count;
  final DateTime createdAt;
  final Map<int, String> chunks = {};
}

String oculumEncodeSheetTransfer(Map<String, dynamic> payload) =>
    base64Encode(utf8.encode(jsonEncode(payload)));
