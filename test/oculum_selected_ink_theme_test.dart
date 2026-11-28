import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_monster_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all selected desktop art belongs to the exact catalogue entry', () async {
    const ids = [
      'armadillo_corazzato_variante_placche_scolpite',
      'armadillo_corazzato_variante_scaglie_larghe',
      'costrutto_minore',
      'costrutto_minore_variante_trapezoidale',
      'costrutto_minore_variante_rapido',
      'mosca_campana',
      'mosca_campana_variante_oculum_ametista',
      'ciclo_cinghiale_fango',
      'ciclo_cinghiale_fango_variante_chikar',
      'ciclo_uomo_cactus',
      'ciclo_uomo_cactus_variante_aberion_blu',
      'ciclo_uomo_cactus_variante_aberion',
      'ciclo_airone_guado_quieto',
      'ciclo_airone_guado_quieto_variante_colorato',
      'ciclo_airone_guado_quieto_variante_lunare',
      'ciclo_tartaruga_pioggia_chiara',
      'ciclo_tartaruga_pioggia_chiara_variante_solida',
      'ciclo_tartaruga_pioggia_chiara_variante_incantatrice',
      'weak_horror_larva',
      'weak_horror_larva_variante_potenziata',
      'weak_horror_larva_variante_velenosa',
      'ferrynox',
      'ferrynox_variante_dune_vetro',
      'ferrynox_variante_foresta_scoria',
      'anfravyre',
      'anfravyre_variante_gallerie_indaco',
      'anfravyre_variante_pietra_nera',
    ];
    for (final id in ids) {
      final creature = monsterBookEntryById(id);
      expect(creature?.id, id);
      expect(creature?.spriteAssetPath, isEmpty);
      final path = OculumMonsterTheme.desktopIllustrationForId(id);
      expect(path, 'assets/oculum/home_art_authored/theme_${id}_ink_20261128.webp');
      final art = await rootBundle.load(path!);
      expect(art.lengthInBytes, greaterThan(1024));
      expect(
        String.fromCharCodes(art.buffer.asUint8List(art.offsetInBytes + 8, 4)),
        'WEBP',
      );
    }
  });
}
