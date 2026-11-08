import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/oculum_sleep_rules.dart';

void main() {
  const hour = 3600;
  const minute = 60;

  test(
    'meal credit changes at 05:30 and recovery is a separate rolling timer',
    () {
      final meals = OculumPersonalNeedsProgress.fromJson({}, now: 0);
      final breakfast = meals.recordMeal(hour, manual: true, canRest: true);
      expect(breakfast.window, 'first');
      expect(breakfast.shortRest, isTrue);
      expect(
        meals.recordMeal(hour, manual: true, canRest: true).consumed,
        isFalse,
      );

      final lunch = meals.recordMeal(
        5 * hour + 29 * minute,
        manual: false,
        canRest: true,
      );
      expect(lunch.window, isNull);
      expect(lunch.shortRest, isFalse);

      final dinner = meals.recordMeal(
        5 * hour + 30 * minute,
        manual: false,
        canRest: true,
      );
      expect(dinner.window, 'second');
      expect(dinner.second, isTrue);
      expect(dinner.shortRest, isTrue);
      expect(
        meals.recordMeal(7 * hour, manual: false, canRest: true).second,
        isFalse,
      );
      expect(meals.mealsToday(7 * hour), 2);
    },
  );

  test(
    'late-night breakfast applies to the next day and survives serialization',
    () {
      var meals = OculumPersonalNeedsProgress.fromJson({}, now: 0);
      meals.recordMeal(0, manual: false, canRest: true);
      meals.recordMeal(6 * hour, manual: false, canRest: true);
      final early = meals.recordMeal(
        8 * hour + 30 * minute,
        manual: false,
        canRest: true,
      );
      expect(early.early, isTrue);
      expect(early.second, isFalse);
      expect(early.shortRest, isFalse);
      expect(meals.mealsToday(8 * hour + 30 * minute), 2);

      meals = OculumPersonalNeedsProgress.fromJson(
        jsonDecode(jsonEncode(meals.toJson())) as Map,
        now: 9 * hour,
      );
      meals.advanceTo(9 * hour);
      expect(meals.mealsToday(9 * hour), 1);
      expect(
        meals.recordMeal(10 * hour, manual: false, canRest: true).window,
        isNull,
      );
      final dinner = meals.recordMeal(15 * hour, manual: false, canRest: true);
      expect(dinner.second, isTrue);
      expect(dinner.shortRest, isTrue);
    },
  );

  test('three actual meals grant the extra bonus before the evening band', () {
    var meals = OculumPersonalNeedsProgress.fromJson({}, now: 0);
    expect(meals.recordMeal(hour, manual: true, canRest: false).third, isFalse);
    expect(
      meals.recordMeal(2 * hour, manual: false, canRest: false).third,
      isFalse,
    );
    final third = meals.recordMeal(3 * hour, manual: false, canRest: false);
    expect(third.third, isTrue);
    expect(third.second, isFalse);
    expect(meals.mealsToday(3 * hour), 1);

    meals = OculumPersonalNeedsProgress.fromJson(
      jsonDecode(jsonEncode(meals.toJson())) as Map,
      now: 3 * hour,
    );
    expect(
      meals.recordMeal(4 * hour, manual: false, canRest: false).third,
      isFalse,
    );
    final dinner = meals.recordMeal(6 * hour, manual: false, canRest: false);
    expect(dinner.second, isTrue);
    expect(dinner.third, isFalse);
    expect(meals.mealsToday(6 * hour), 2);
  });

  test('one meal causes a light deficit cleared by the next meal alone', () {
    final meals = OculumPersonalNeedsProgress.fromJson({
      'config': {'waterEnabled': false},
    }, now: 0);
    meals.recordMeal(hour, manual: false, canRest: false);
    meals.advanceTo(9 * hour, random: Random(7));
    expect(meals.episodes.single['id'], 'meal-deficit:0');
    expect(meals.ash, 0);
    expect((meals.episodes.single['stats'] as Map).values.single, -1);
    meals.advanceTo(9 * hour, random: Random(7));
    expect(meals.episodes, hasLength(1));
    meals.recordMeal(9 * hour + minute, manual: false, canRest: true);
    expect(meals.episodes, isEmpty);
  });
}
