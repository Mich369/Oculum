import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  group('mod Oculus', () {
    test('inizia con quattro dadi d4 e conserva una sola scheda dati', () {
      final data = oculusDefaultCharacterData();
      expect(data['resilienzaDie'], 4);
      expect(data['volontaDie'], 4);
      expect(data['materiaDie'], 4);
      expect(data['oculumDie'], 4);
      expect(data['forceDie'], 4);
      expect(data['activeForce'], 'fato');
      expect(data['skills'], hasLength(3));
      expect(data['missions'], hasLength(12));
    });

    test('normalizza dati legacy senza perdere campi sconosciuti', () {
      final data = oculusNormalizeCharacterData(<String, dynamic>{
        'name': 'Iris',
        'skills': <String>['Una'],
        'futureField': 7,
      });
      expect(data['name'], 'Iris');
      expect(data['skills'], hasLength(3));
      expect(data['futureField'], 7);
    });

    test('ogni Art predefinita offre sei Skill e se ne scelgono tre', () {
      expect(
        oculusArtSkillCatalog.keys,
        containsAll(<String>[
          'Fuoco',
          'Acqua',
          'Terra',
          'Aria',
          'Luce',
          'Ombra',
        ]),
      );
      for (final skills in oculusArtSkillCatalog.values) {
        expect(skills, hasLength(6));
        expect(skills.map((skill) => skill.$1).toSet(), hasLength(6));
      }
    });
  });

  test('un sottotratto Homebrew resta compatibile nel JSON', () {
    final original = HiddenEyeStat(
      id: 'homebrew_eco_rosso',
      nome: 'Eco Rosso',
      descrizione: 'Ascolta il sangue.',
      valore: 2,
      category: 'altro',
      homebrew: true,
    );
    final restored = HiddenEyeStat.fromJson(original.toJson());
    expect(restored.category, 'altro');
    expect(restored.homebrew, isTrue);
    expect(restored.valore, 2);
  });
}
