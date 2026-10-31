import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_monster_theme.dart';
import 'package:oculum/main.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  testWidgets('Precision hides the Knight sphere until actual discovery', (
    tester,
  ) async {
    final dynamic state = await fixtures.mountSheet(
      tester,
      const Size(1440, 900),
    );
    final probe = OculumPerformanceProbe(state);
    final token = <String, dynamic>{
      'id': 'hidden_knight',
      'monsterBookId': 'cavaliere_morto',
      'name': 'Cavaliere',
    };
    final first = probe.selectPrecisionPart(token);
    await tester.pumpAndSettle();
    expect(find.textContaining('Sfera di Oculum'), findsNothing);
    expect(find.text('Sfera di Oculum alla base della vita'), findsNothing);
    await tester.tap(find.text('Corpo'));
    await tester.pumpAndSettle();
    expect((await first)?['id'], 'body');
    probe.rememberMonsterDiscovery('cavaliere_morto', weakPoint: true);
    final second = probe.selectPrecisionPart(token);
    await tester.pumpAndSettle();
    expect(find.text('Sfera di Oculum alla base della vita'), findsOneWidget);
    await tester.tap(find.text('Sfera di Oculum alla base della vita'));
    await tester.pumpAndSettle();
    expect((await second)?['id'], 'core');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  test('discovery filtering preserves input and explicit Master anatomy', () {
    final knight = monsterBookEntryById('cavaliere_morto')!;
    final original = oculumMonsterPrecisionAnatomy(knight);
    final hidden = oculumMonsterPrecisionChoices(
      original,
      monster: knight,
      weakPointDiscovered: false,
    );
    expect(hidden.any((p) => p['id'] == 'core'), isFalse);
    expect(original.any((p) => p['id'] == 'core'), isTrue);
    final custom = knight.copyWith(
      encounterRules: {'precisionBodyParts': original},
    );
    expect(
      oculumMonsterPrecisionChoices(
        original,
        monster: custom,
        weakPointDiscovered: false,
      ),
      original,
    );
  });
  final receipt =
      jsonDecode(
            File(
              'design/approved-six-monster-packs-2026-10-31.json',
            ).readAsStringSync(),
          )
          as Map;
  final files = (receipt['files'] as List).cast<Map>();

  test(
    'six approved packs preserve all eighteen exact PNGs and their bindings',
    () {
      expect(files, hasLength(18));
      final ids = files.map((f) => f['species'] as String).toSet();
      expect(ids, hasLength(6));
      expect(files.map((f) => f['asset']).toSet(), hasLength(18));
      for (final id in ids) {
        final theme = OculumMonsterTheme(
          monsterBookEntryById(id)!,
          oculumMonsterColors(monsterBookEntryById(id)!).first,
        );
        expect(theme.preserveIllustrationFraming, isTrue);
        final pack = files.where((f) => f['species'] == id);
        expect(pack.map((f) => f['kind']).toSet(), {
          'desktop',
          'phone',
          'relic',
        });
        for (final f in pack) {
          expect(f['user_approved'], isTrue);
          final bytes = File(f['asset'] as String).readAsBytesSync();
          final hash = SHA256Digest()
              .process(bytes)
              .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
              .join();
          expect(hash, f['sha256'], reason: '${f['asset']}');
          expect(bytes.length, f['bytes']);
          final binding = switch (f['kind']) {
            'desktop' => theme.illustration,
            'phone' => theme.illustrationMobile,
            'relic' => theme.relicIllustration,
            _ => null,
          };
          expect(binding, f['asset']);
        }
      }
    },
  );

  test(
    'Dead Knight sphere replaces skeletal joints in both languages and variants',
    () {
      final knight = monsterBookEntryById('cavaliere_morto')!;
      for (final entry in [
        knight,
        knight.copyWith(
          id: 'cavaliere_morto_variante_qa',
          weakPointIt: '',
          weakPointEn: '',
        ),
      ]) {
        expect(entry.weakPointDescriptionIt, contains('sfera di Oculum'));
        expect(entry.weakPointDescriptionEn, contains('base of the waist'));
        final parts = oculumMonsterPrecisionAnatomy(entry);
        expect(parts.where((p) => p['weak'] == true).single['id'], 'core');
        expect(
          parts.singleWhere((p) => p['id'] == 'core')['label'],
          contains('base della vita'),
        );
        expect(parts.where((p) => p['group'] == 'arms'), hasLength(2));
        expect(parts.where((p) => p['group'] == 'legs'), hasLength(2));
        expect(parts.where((p) => p['group'] == 'eyes'), isEmpty);
        expect(parts.where((p) => p['group'] == 'heart'), isEmpty);
        expect(
          parts
              .where((p) => p['id'] != 'core')
              .every((p) => p['material'] == 'metal'),
          isTrue,
        );
      }
    },
  );

  test('saved Master weak points and custom anatomy remain authoritative', () {
    final knight = monsterBookEntryById('cavaliere_morto')!;
    final custom = knight.copyWith(
      weakPointIt: 'Il gomito destro.',
      encounterRules: {
        'precisionBodyParts': [
          {'id': 'custom_elbow', 'group': 'arms', 'weak': true, 'hp': 17},
        ],
      },
    );
    final restored = MonsterBookEntry.fromJson(custom.toJson());
    expect(restored.weakPointDescriptionIt, 'Il gomito destro.');
    expect(
      oculumMonsterPrecisionAnatomy(restored).single['id'],
      'custom_elbow',
    );
    expect(oculumMonsterPrecisionAnatomy(restored).single['hp'], 17);
    final customText = knight.copyWith(weakPointIt: 'Il gomito destro.');
    expect(
      oculumMonsterPrecisionAnatomy(
        customText,
      ).where((p) => p['weak'] == true).every((p) => p['group'] == 'arms'),
      isTrue,
    );
  });

  test('stand, mirror and turret do not acquire imagined limbs or eyes', () {
    List<Map<String, dynamic>> parts(String id) =>
        oculumMonsterPrecisionAnatomy(monsterBookEntryById(id)!);
    final worshipper = parts('adoratore_bestia');
    expect(monsterBookEntryById('adoratore_bestia')!.descIt, contains('stand'));
    expect(worshipper.where((p) => p['group'] == 'arms'), hasLength(2));
    expect(worshipper.where((p) => p['group'] == 'legs'), hasLength(2));
    for (final id in ['specchio_mangiavoce', 'torretta_oculum']) {
      expect(
        parts(
          id,
        ).where((p) => {'arms', 'legs', 'eyes', 'head'}.contains(p['group'])),
        isEmpty,
      );
    }
    expect(
      parts('teschio_mostruoso').where((p) => p['group'] == 'arms'),
      hasLength(4),
    );
    expect(
      parts('teschio_mostruoso').where((p) => p['group'] == 'legs'),
      hasLength(2),
    );
  });
}
