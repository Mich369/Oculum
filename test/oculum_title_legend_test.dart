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

  test('grado e punti allocati del Titolo sopravvivono al JSON', () {
    final title = OculumTitle.fromJson({
      'nome': 'Titolo graduato',
      'tipo': 'Titolo Azione',
      'ottenimento': '',
      'buff': '',
      'puntoCieco': '',
      'skill': '',
      'richiede': '',
      'grade': 2,
      'gradeStatAllocation': {'resilienza': 5, 'volonta': 2, 'materia': 3},
    });
    final restored = OculumTitle.fromJson(title.toJson());
    expect(restored.grade, 2);
    expect(restored.gradeStatAllocation.values.reduce((a, b) => a + b), 10);
    expect(restored.gradeStatAllocation['resilienza'], 5);
  });

  test(
    'solo un Titolo indossato e prioritariamente con Open attivabile resta visibile',
    () {
      OculumTitle title(String name, {required bool evolved}) => OculumTitle(
        nome: name,
        tipo: 'Titolo Azione',
        ottenimento: '',
        leggenda: '$name leggenda',
        buff: '',
        puntoCieco: '',
        skill: '',
        richiede: '',
        equipaggiato: true,
        evoluto: evolved,
        sempreVisibile: true,
      );

      final normal = title('Normale', evolved: false);
      final evolved = title('Evoluto', evolved: true);
      final titles = [normal, evolved];
      oculumNormalizeAlwaysVisibleTitles(titles);

      expect(oculumTitleHasActivatableOpen(normal), isFalse);
      expect(oculumTitleHasActivatableOpen(evolved), isTrue);
      expect(oculumAlwaysVisibleTitle(titles), same(evolved));
      expect(normal.sempreVisibile, isFalse);
      expect(oculumTitleCanBeAlwaysVisible(normal, titles), isFalse);
      expect(oculumTitleCanBeAlwaysVisible(evolved, titles), isTrue);
      expect(OculumTitle.fromJson(evolved.toJson()).sempreVisibile, isTrue);
    },
  );
}
