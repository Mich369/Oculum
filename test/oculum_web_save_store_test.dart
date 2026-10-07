@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/src/main/oculum_web_save_store_web.dart';

void main() {
  test('Web saves persist large portrait blobs and update safely', () async {
    final key = 'oculum_web_test_${DateTime.now().microsecondsSinceEpoch}';
    final data = 'Rose | Tutto pur di Salvarla 🌙 ${'x' * (1024 * 1024)}';
    try {
      expect(await oculumWebSaveWrite(key, data), true);
      expect(await oculumWebSaveRead(key), data);
      expect(await oculumWebSaveWrite(key, 'aggiornato'), true);
      expect(await oculumWebSaveRead(key), 'aggiornato');
      expect(await oculumWebSaveDelete(key), true);
      expect(await oculumWebSaveRead(key), isNull);
    } finally {
      await oculumWebSaveDelete(key);
    }
  });
}
