import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  tearDown(resetMonsterBookEntries);

  test('Monster Book custom entry keeps names, image, category and drops', () {
    const entry = MonsterBookEntry(
      id: 'custom_keeper',
      nameIt: 'Custode Personalizzato',
      nameEn: 'Custom Keeper',
      descIt: 'Descrizione modificabile.',
      descEn: 'Editable description.',
      elementId: 'ombra',
      spriteAssetPath: 'assets/custom.png',
      imageBase64: 'aW1hZ2U=',
      isMiniBoss: false,
      isBoss: false,
      isNpc: true,
      isNullFateless: false,
      dropIds: ['chiave_ombra', 'occhio_vetro'],
    );

    final restored = MonsterBookEntry.fromJson(entry.toJson());

    expect(restored.nameIt, entry.nameIt);
    expect(restored.imageBase64, entry.imageBase64);
    expect(restored.presetType, 'NPC');
    expect(restored.dropIds, entry.dropIds);
  });

  test('Monster Book overrides built-ins and hides removed presets', () {
    final original = defaultMonsterBookEntries.first;
    final renamed = original.copyWith(nameIt: 'Nome Rispettato');

    configureMonsterBookEntries(
      customEntries: [renamed],
      removedIds: [defaultMonsterBookEntries[1].id],
    );

    expect(monsterById(original.id)?.nameIt, 'Nome Rispettato');
    expect(monsterById(defaultMonsterBookEntries[1].id), isNull);
  });
}
