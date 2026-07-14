import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('i vecchi Titoli senza Leggenda restano compatibili', () {
    final title = OculumTitle.fromJson({
      'nome': 'Titolo legacy',
      'tipo': 'Titolo Azione',
      'ottenimento': 'Ricordo precedente',
      'buff': '',
      'puntoCieco': '',
      'skill': '',
      'richiede': '',
    });

    expect(title.leggenda, isEmpty);
  });

  test('la Leggenda viene salvata e ricaricata insieme al Titolo', () {
    final title = OculumTitle.fromJson({
      'nome': 'Titolo narrativo',
      'tipo': 'Titoli del Fato',
      'ottenimento': 'Impresa memorabile',
      'leggenda': 'Una storia tramandata nel tempo.',
      'buff': '',
      'puntoCieco': '',
      'skill': '',
      'richiede': '',
    });

    final restored = OculumTitle.fromJson(title.toJson());
    expect(restored.leggenda, 'Una storia tramandata nel tempo.');
    expect(restored.toJson()['leggenda'], restored.leggenda);
  });
}
