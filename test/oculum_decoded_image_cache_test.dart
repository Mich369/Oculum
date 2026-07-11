import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  group('OculumDecodedImageCache', () {
    String encoded(List<int> bytes) {
      return base64Encode(Uint8List.fromList(bytes));
    }

    test('reuses decoded bytes and evicts the least recently used entry', () {
      final cache = OculumDecodedImageCache(maxEntries: 2, maxBytes: 1024);
      final firstRaw = encoded(<int>[1, 2, 3]);
      final secondRaw = encoded(<int>[4, 5, 6]);
      final thirdRaw = encoded(<int>[7, 8, 9]);

      final firstDecoded = cache.decode(firstRaw);
      expect(firstDecoded, isNotNull);
      expect(cache.decode(firstRaw), same(firstDecoded));

      cache.decode(secondRaw);
      cache.decode(firstRaw);
      cache.decode(thirdRaw);

      expect(cache.containsRaw(firstRaw), isTrue);
      expect(cache.containsRaw(secondRaw), isFalse);
      expect(cache.containsRaw(thirdRaw), isTrue);
      expect(cache.length, 2);
    });

    test('keeps the cache under the configured byte budget', () {
      final cache = OculumDecodedImageCache(maxEntries: 10, maxBytes: 4);
      final firstRaw = encoded(<int>[1, 2, 3]);
      final secondRaw = encoded(<int>[4, 5, 6]);

      cache.decode(firstRaw);
      cache.decode(secondRaw);

      expect(cache.sizeBytes, lessThanOrEqualTo(4));
      expect(cache.containsRaw(firstRaw), isFalse);
      expect(cache.containsRaw(secondRaw), isTrue);
    });

    test('returns oversized images without retaining them in memory', () {
      final cache = OculumDecodedImageCache(maxEntries: 10, maxBytes: 2);
      final raw = encoded(<int>[1, 2, 3]);

      expect(cache.decode(raw), isNotNull);
      expect(cache.containsRaw(raw), isFalse);
      expect(cache.sizeBytes, 0);
    });

    test('ignores invalid base64 safely', () {
      final cache = OculumDecodedImageCache(maxEntries: 2, maxBytes: 1024);

      expect(cache.decode('not valid base64'), isNull);
      expect(cache.length, 0);
      expect(cache.sizeBytes, 0);
    });
  });
}
