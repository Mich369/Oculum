import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  group('pulizia caratteri corrotti', () {
    test('ripara singole sequenze senza alterare simboli gia validi', () {
      const corrupted =
          'Testo già valido • volontÃ , unitÃ  e l\'oggetto sarÃ  attivo 😀';

      expect(
        oculumCleanMojibakeText(corrupted),
        'Testo già valido • volontà, unità e l\'oggetto sarà attivo 😀',
      );
    });

    test('ripara apostrofi e separatori corrotti', () {
      expect(
        oculumCleanMojibakeText('Inventario â€¢ l\'Art dellâ€™eroe'),
        'Inventario • l\'Art dell’eroe',
      );
    });

    test('normalizza i testi inventario caricati dai vecchi salvataggi', () {
      final item = InventoryItem.fromJson(<String, dynamic>{
        'nome': 'Convertitore di volontÃ ',
        'peso': 0.2,
        'quantita': 1,
        'note': 'Massimo 10 unitÃ  per utilizzo â€¢ sarÃ  attivo',
        'buff': '@VolontÃ +1',
        'elementoDanno': 'ElettricitÃ ',
      });

      expect(item.nome, 'Convertitore di volontà');
      expect(item.note, 'Massimo 10 unità per utilizzo • sarà attivo');
      expect(item.buff, '@Volontà+1');
      expect(item.elementoDanno, 'Elettricità');
    });
  });
}
