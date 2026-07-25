import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('il catalogo Rune Art contiene tutte le parole ufficiali richieste', () {
    const expected = <String, (String, int, int)>{
      'Self / Ally': ('TARGET', 0, 0),
      'Zona 3m': ('TARGET', 1, 0),
      'Zona 5m': ('TARGET', 2, 0),
      'Zona 7m': ('TARGET', 3, 0),
      'Linea 10m': ('TARGET', 1, 0),
      'WARD': ('VERBO', 1, 1),
      'MEND': ('VERBO', 1, 1),
      'PURGE': ('VERBO', 1, 1),
      'BIND': ('VERBO', 1, 2),
      'CHANNEL': ('VERBO', 1, 1),
      'MIRROR': ('VERBO', 2, 3),
      'INTERCEPT': ('VERBO', 1, 2),
      'FORTIFY': ('VERBO', 1, 1),
      'DESTR0Y': ('VERBO', 3, 5),
      'Vital': ('ASPETTO', 1, 0),
      'Lunar': ('ASPETTO', 1, 1),
      'Aqua': ('ASPETTO', 1, 0),
      'Shadow': ('ASPETTO', 1, 1),
      'Stone': ('ASPETTO', 1, 0),
      'Wind': ('ASPETTO', 1, 1),
      'Flame': ('ASPETTO', 1, 1),
      'Mind': ('ASPETTO', 1, 2),
      'Pulse': ('MOD', 0, 0),
      'Dome': ('MOD', 1, 1),
      'Veil': ('MOD', 0, 0),
      'Tether': ('MOD', 1, 1),
      'Glyph': ('MOD', 0, 0),
      'Totem': ('MOD', 1, 1),
      'Halo': ('MOD', 1, 1),
      'I': ('INTENSITA', 0, 0),
      'II': ('INTENSITA', 1, 1),
      'III': ('INTENSITA', 2, 2),
      'IV': ('INTENSITA', 3, 3),
      '1 azione': ('DURATA', 0, 0),
      '3 turni': ('DURATA', 1, 0),
      '5 turni': ('DURATA', 2, 1),
      'Scena': ('DURATA', 3, 2),
      'On Crit': ('TRIGGER', 1, 1),
      'On Hit': ('TRIGGER', 1, 1),
      '<50% Vita': ('TRIGGER', 1, 1),
    };

    expect(runeArtOfficialWords, hasLength(expected.length));
    expect(
      runeArtOfficialWords.map((word) => word.id).toSet(),
      hasLength(runeArtOfficialWords.length),
    );

    for (final word in runeArtOfficialWords) {
      final values = expected[word.choiceIt];
      expect(values, isNotNull, reason: 'Parola inattesa: ${word.choiceIt}');
      expect(word.block, values!.$1, reason: word.choiceIt);
      expect(word.cost, values.$2, reason: word.choiceIt);
      expect(word.dt, values.$3, reason: word.choiceIt);
      expect(word.effectIt.trim(), isNotEmpty, reason: word.choiceIt);
    }
  });

  test('Self Ally e Pulse sono le prime basi con Intensita I', () {
    expect(runeArtRequiredStartingWordIds, const [
      'target_self_ally',
      'mod_pulse',
      'intensity_i',
    ]);
    expect(runeArtBaseWordIds, containsAll(runeArtRequiredStartingWordIds));
  });

  test('tutte le parole sono visibili ma solo le note sono selezionabili', () {
    expect(runeArtOfficialWords, hasLength(40));
    final selectable = runeArtSelectableWordIds(const <String>[]);
    expect(selectable, runeArtBaseWordIds);
    expect(selectable.length, lessThan(runeArtOfficialWords.length));
  });

  test('ogni Libro Runico completo insegna esattamente sei parole', () {
    final known = <String>{...runeArtBaseWordIds};

    for (var book = 0; book < 6; book++) {
      final before = runeArtSelectableWordIds(known).length;
      final learned = runeArtBookLearningPlan(
        words: runeArtOfficialWords,
        knownWordIds: known,
      );
      expect(
        learned,
        hasLength(runeArtWordsPerBook),
        reason: 'libro ${book + 1}',
      );
      known.addAll(learned.map((word) => word.id));
      expect(
        runeArtSelectableWordIds(known).length,
        before + runeArtWordsPerBook,
        reason: 'parole selezionabili dopo il libro ${book + 1}',
      );
    }

    expect(known, containsAll(runeArtOfficialWords.map((word) => word.id)));
    expect(
      runeArtBookLearningPlan(words: runeArtOfficialWords, knownWordIds: known),
      isEmpty,
    );
  });

  test('la formula somma costo Oculum e DT delle parole selezionate', () {
    const selected = <String>{'target_zone_5m', 'verb_bind', 'intensity_ii'};
    expect(
      runeArtFormulaCostForSelection(
        words: runeArtOfficialWords,
        selectedWordIds: selected,
      ),
      4,
    );
    expect(
      runeArtFormulaDtForSelection(
        words: runeArtOfficialWords,
        selectedWordIds: selected,
      ),
      3,
    );
  });

  test('usare Rune Art spende Oculum e aumenta davvero la DT', () {
    final first = runeArtUseResult(
      currentOculum: 10,
      currentDifficulty: 2,
      formulaCost: 4,
      formulaDt: 3,
    );
    expect(first.used, isTrue);
    expect(first.remainingOculum, 6);
    expect(first.nextDifficulty, 5);

    final second = runeArtUseResult(
      currentOculum: first.remainingOculum,
      currentDifficulty: first.nextDifficulty,
      formulaCost: 4,
      formulaDt: 3,
    );
    expect(second.used, isTrue);
    expect(second.remainingOculum, 2);
    expect(second.nextDifficulty, 8);

    final blocked = runeArtUseResult(
      currentOculum: 2,
      currentDifficulty: 8,
      formulaCost: 4,
      formulaDt: 3,
    );
    expect(blocked.used, isFalse);
    expect(blocked.remainingOculum, 2);
    expect(blocked.nextDifficulty, 8);
  });

  test(
    'le Rune restano compatibili e persistenti nel JSON multipiattaforma',
    () {
      final legacy = CharacterArt.fromJson(<String, dynamic>{
        'nome': 'Rune Art legacy',
        'tipo': 'Rune Art',
        'descrizione': '',
        'skills': <Map<String, dynamic>>[],
      });
      expect(legacy.runeWordsKnown, isEmpty);
      expect(legacy.runeBooksRead, 0);
      expect(legacy.runeActiveSlot, 1);

      final source = CharacterArt(
        nome: 'Rune Art',
        tipo: 'Rune Art',
        descrizione: '',
        skills: <ArtSkill>[],
        runeWordsKnown: const <String>['verb_ward', 'aspect_vital'],
        runeQuickWordIds: const <String>['verb_ward'],
        runeQuickWordIdsSlot2: const <String>['aspect_vital'],
        runeActiveSlot: 2,
        runeBooksRead: 3,
      );
      final restored = CharacterArt.fromJson(source.toJson());
      expect(restored.runeWordsKnown, source.runeWordsKnown);
      expect(restored.runeQuickWordIds, source.runeQuickWordIds);
      expect(restored.runeQuickWordIdsSlot2, source.runeQuickWordIdsSlot2);
      expect(restored.runeActiveSlot, 2);
      expect(restored.runeBooksRead, 3);
    },
  );
}
