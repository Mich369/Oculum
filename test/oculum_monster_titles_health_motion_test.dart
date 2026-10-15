import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_resource_bar_fx.dart';
import 'package:oculum/widgets/oculum_theme_presentation.dart';

void main() {
  test('only explicit minor creatures may spawn without techniques', () {
    for (final monster in defaultMonsterBookEntries.where((m) => !m.isNpc)) {
      final count =
          oculumMonsterBookSkills(monster).length +
          (oculumMonsterBookImportArt(monster)?.skills.length ?? 0);
      if (count == 0) {
        expect(
          monster.formTags,
          contains('Creatura Minore'),
          reason: monster.id,
        );
        expect(monster.skillIds, isEmpty, reason: monster.id);
      }
    }
  });
  test('Chaos wanderers receive editable titles with real trade-offs', () {
    final monster = monsterById('ghoul_errante')!;
    final pool = oculumMonsterBookTitles(monster);
    expect(pool, hasLength(3));
    expect(pool.every((title) => title.tipo == 'Titolo di Chaos'), isTrue);
    expect(pool.where((title) => title.sempreVisibile), hasLength(1));
    expect(pool.every((title) => title.buff.contains('@')), isTrue);
    expect(pool.every((title) => title.puntoCieco.contains('-')), isTrue);
    final original = pool.first;
    final restored = OculumTitle.fromJson(original.toJson());
    expect(oculumActiveTitleFormulaTexts(restored), isNotEmpty);
    restored.sempreVisibile = false;
    expect(oculumActiveTitleFormulaTexts(restored), isEmpty);
    restored.sempreVisibile = true;
    restored.equipaggiato = false;
    expect(oculumActiveTitleFormulaTexts(restored), isEmpty);
    expect(pool.every((title) => title.oculum == 0), isTrue);
  });
  test('health colour is continuous at each danger threshold', () {
    for (final stop in [.15, .30, .50, .75]) {
      final before = oculumHealthColor(stop - .0001);
      final after = oculumHealthColor(stop + .0001);
      expect((before.r - after.r).abs(), lessThan(.02));
      expect((before.g - after.g).abs(), lessThan(.02));
      expect((before.b - after.b).abs(), lessThan(.02));
    }
    expect(oculumHealthColor(double.nan), oculumHealthColor(0));
    expect(oculumHealthColor(2), oculumHealthColor(1));
  });
  testWidgets('life fill interpolates and respects reduced motion settings', (
    tester,
  ) async {
    final previous = oculumThemePresentation.value;
    addTearDown(() => oculumThemePresentation.value = previous);
    oculumThemePresentation.value = const OculumThemePresentation();
    Widget fill(double value, {bool disabled = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disabled),
        child: SizedBox(
          width: 200,
          height: 20,
          child: OculumAnimatedResourceFill(
            fraction: value,
            child: const ColoredBox(color: Colors.red),
          ),
        ),
      ),
    );
    await tester.pumpWidget(fill(.8));
    await tester.pumpWidget(fill(.2));
    await tester.pump(const Duration(milliseconds: 190));
    final middle = tester
        .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
        .widthFactor!;
    expect(middle, greaterThan(.2));
    expect(middle, lessThan(.8));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      tester
          .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .widthFactor,
      .2,
    );
    await tester.pumpWidget(fill(.9, disabled: true));
    await tester.pump();
    expect(
      tester
          .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .widthFactor,
      .9,
    );
  });
}
