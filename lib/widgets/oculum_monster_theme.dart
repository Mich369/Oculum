import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../pages/oculum_dungeon/monster_book.dart';

/// Cosmetic data only: these weights never change a creature's statistics.
@immutable
class OculumCreatureColor {
  const OculumCreatureColor(this.id, this.name, this.color, this.weight);
  final String id, name;
  final Color color;
  final int weight;
}

int oculumMonsterArtSeed(String value) =>
    value.codeUnits.fold(17, (seed, unit) => (seed * 31 + unit) & 0x7fffffff);

List<OculumCreatureColor> oculumMonsterColors(MonsterBookEntry monster) {
  if (monster.encounterRules['lunarGuardFamily'] == true) {
    return [
      OculumCreatureColor(
        'canonico',
        'Argento annerito · ${monster.encounterRules['infernalIk'] == true ? 'Rosa infernale' : 'Viola lunare'}',
        monster.encounterRules['infernalIk'] == true
            ? const Color(0xff8f1b5b)
            : const Color(0xff6a4cb0),
        100,
      ),
    ];
  }
  const violet = Color(0xffab91cf);
  const gold = Color(0xffc4a365);
  final id = monster.id;
  if (id == 'bramble') {
    return const [
      OculumCreatureColor('muschio', 'Muschio', Color(0xffa8b86a), 65),
      OculumCreatureColor('sottobosco', 'Sottobosco', Color(0xff7e9a7b), 25),
      OculumCreatureColor(
        'corteccia',
        'Corteccia ambrata',
        Color(0xffb9a177),
        10,
      ),
    ];
  }
  if (id == 'ombra_ignota') {
    return const [OculumCreatureColor('ossidiana', 'Ossidiana', violet, 100)];
  }
  if (id.contains('maschera')) {
    final (name, color) = id.endsWith('verde')
        ? ('Giada', const Color(0xff70a68a))
        : id.endsWith('rossa')
        ? ('Cinabro', const Color(0xffce7d73))
        : id.endsWith('blu')
        ? ('Zaffiro', const Color(0xff80a8cb))
        : id.endsWith('viola')
        ? ('Ametista', violet)
        : id.contains('solare') || id.contains('angelica')
        ? ('Oro pallido', gold)
        : ('Avorio', const Color(0xffbfb9a7));
    return [OculumCreatureColor('canonico', name, color, 100)];
  }
  if (id == 'nuvi') {
    return const [
      OculumCreatureColor('avorio', 'Avorio', Color(0xffd2c3a4), 32),
      OculumCreatureColor('lavanda', 'Lavanda', Color(0xffb6a1d0), 22),
      OculumCreatureColor('pesca', 'Pesca', Color(0xffdba58b), 18),
      OculumCreatureColor('celeste', 'Celeste', Color(0xff93bed0), 16),
      OculumCreatureColor('menta', 'Menta', Color(0xff92b9a1), 12),
    ];
  }
  if (id.contains('pupazzo')) {
    return const [
      OculumCreatureColor('ardesia', 'Ardesia', Color(0xff91a2ae), 40),
      OculumCreatureColor('prugna', 'Prugna', Color(0xffb28aa6), 25),
      OculumCreatureColor('muschio', 'Muschio', Color(0xff9eaa7c), 20),
      OculumCreatureColor('blu_notte', 'Blu notte', Color(0xff8297b3), 15),
    ];
  }
  if (id.contains('sunshine')) {
    return const [OculumCreatureColor('oro', 'Oro', gold, 100)];
  }
  if (id.contains('observer') || id.contains('denero')) {
    return const [OculumCreatureColor('viola', 'Viola Oculum', violet, 100)];
  }
  final element = monster.elementId;
  if (monster.planeIds.contains('postea') ||
      RegExp('meccan|robot|bot|runic').hasMatch(id)) {
    return const [
      OculumCreatureColor('rame', 'Rame ossidato', Color(0xff9eb6a7), 45),
      OculumCreatureColor('acciaio', 'Acciaio brunito', Color(0xff9ba9bb), 35),
      OculumCreatureColor('ottone', 'Ottone', gold, 20),
    ];
  }
  final (name, color) = switch (element) {
    'fuoco' => ('Brace', const Color(0xffe89770)),
    'lava' => ('Lava', const Color(0xffedaa60)),
    'demoniaco' => ('Cinabro', const Color(0xffdf8077)),
    'diabolico' => ('Rubino lunare', const Color(0xffcd849f)),
    'solare' => ('Oro solare', const Color(0xffdfb85e)),
    'luce' => ('Champagne', const Color(0xffddd1a0)),
    'angelico' => ('Avorio dorato', const Color(0xffd8d7b1)),
    'acqua' => ('Azzurro profondo', const Color(0xff79b7d3)),
    'gelo' => ('Cristallo di brina', const Color(0xffacd8e5)),
    'fulmine' => ('Ambra elettrica', const Color(0xffddc46e)),
    'energia' => ('Ciano', const Color(0xff87d2de)),
    'buio' => ('Viola notte', const Color(0xffaa9ac9)),
    'oblio' || 'vuoto' => ('Ametista scura', const Color(0xffbc94ce)),
    'psichico' => ('Orchidea', const Color(0xffce96c9)),
    'sogno' => ('Lavanda', const Color(0xffb5b5e4)),
    'oculum' => ('Viola Oculum', violet),
    'vento' => ('Verde aria', const Color(0xff98cbb9)),
    'nuvola' => ('Perla azzurra', const Color(0xffbecae3)),
    'veleno' => ('Chartreuse', const Color(0xffb2c771)),
    'natura' => ('Muschio', const Color(0xff97bb82)),
    'terra' => ('Ocra', const Color(0xffc2a074)),
    'roccia' => ('Ardesia', const Color(0xffaeb2ad)),
    _ => ('Bruno', const Color(0xffb7a38a)),
  };
  return [
    OculumCreatureColor('naturale', name, color, 65),
    OculumCreatureColor(
      'scuro',
      '$name scuro',
      Color.lerp(color, const Color(0xff5b5861), .30)!,
      25,
    ),
    OculumCreatureColor(
      'pallido',
      '$name pallido',
      Color.lerp(color, const Color(0xffdfd6c4), .35)!,
      10,
    ),
  ];
}

OculumCreatureColor oculumRollMonsterColor(
  MonsterBookEntry monster, {
  math.Random? random,
}) {
  final colors = oculumMonsterColors(monster);
  var roll = (random ?? math.Random.secure()).nextInt(
    colors.fold(0, (n, c) => n + c.weight),
  );
  for (final color in colors) {
    roll -= color.weight;
    if (roll < 0) return color;
  }
  return colors.last;
}

@immutable
class OculumMonsterTheme {
  const OculumMonsterTheme(this.monster, this.color);
  final MonsterBookEntry monster;
  final OculumCreatureColor color;
  String get id => 'monster/${monster.id}/${color.id}';
  String get name => '${monster.nameIt} · ${color.name}';
  int get seed => oculumMonsterArtSeed(monster.id);
  Color get accent => color.color;
  Color get surface => Color.lerp(const Color(0xff0d1013), accent, .055)!;
  String? get relicIllustration => switch (monster.id) {
    'mezzo_demone_cosciente' =>
      'assets/oculum/home_art/relic_mezzo_demone_cosciente_v1.png',
    'nuvola_in_bottiglia' =>
      'assets/oculum/home_art/relic_nuvola_in_bottiglia_v1.png',
    'il_doppione' => 'assets/oculum/home_art/relic_il_doppione_v1.png',
    'aberrazione_metallica_angelica' =>
      'assets/oculum/home_art/relic_aberrazione_metallica_angelica_v1.png',
    'aberrazione_metallica_solare' =>
      'assets/oculum/home_art/relic_aberrazione_metallica_solare_v1.png',
    'funghetto_cappuccio_rosso' =>
      'assets/oculum/home_art/relic_funghetto_cappuccio_rosso_v1.png',
    'costrutto_minore' =>
      'assets/oculum/home_art/relic_costrutto_minore_v1.png',
    'shadow_devil' => 'assets/oculum/home_art/relic_shadow_devil_v1.png',
    'mostro_sabbia' => 'assets/oculum/home_art/relic_mostro_sabbia_v1.png',
    'gigante_sabbia' => 'assets/oculum/home_art/relic_gigante_sabbia_v1.png',
    'bramble' => 'assets/oculum/home_art/relic_bramble_v3.png',
    'pawn_guardiano' => 'assets/oculum/home_art/relic_pawn_v1.png',
    'ogle' => 'assets/oculum/home_art/relic_ogle_v1.png',
    'guardia_lunare' => 'assets/oculum/home_art/relic_guardia_lunare_v1.png',
    'guardia_lunare_elite' =>
      'assets/oculum/home_art/relic_guardia_lunare_elite_v1.png',
    'guardiano_lunare' =>
      'assets/oculum/home_art/relic_guardiano_lunare_v1.png',
    'guardian_devil_moon' =>
      'assets/oculum/home_art/relic_guardian_devil_moon_v1.png',
    'guardia_infernale_ik' =>
      'assets/oculum/home_art/relic_guardia_infernale_ik_v1.png',
    'guardia_infernale_ik_elite' =>
      'assets/oculum/home_art/relic_guardia_infernale_ik_elite_v1.png',
    'pinepine' => 'assets/oculum/home_art/relic_pinepine_v1.png',
    'guardia_solare' => 'assets/oculum/home_art/relic_guardia_solare_v1.png',
    'guardia_solare_elite' =>
      'assets/oculum/home_art/relic_guardia_solare_elite_v1.png',
    'guardiano_solare' =>
      'assets/oculum/home_art/relic_guardiano_solare_v2.png',
    _ => null,
  };
  String? get illustration => switch (monster.id) {
    'weak_horror_mastino' =>
      'assets/oculum/home_art/theme_mastino_cripta_v1.png',
    'forest_demon' => 'assets/oculum/home_art/theme_forest_demon_v1.png',
    'ciclo_forest_demon_blu' =>
      'assets/oculum/home_art/theme_forest_demon_blu_v1.png',
    'mezzo_demone_massiccio' =>
      'assets/oculum/home_art/theme_mezzo_demone_massiccio_v1.png',
    'mezzo_demone_cosciente' =>
      'assets/oculum/home_art/theme_mezzo_demone_cosciente_v1.png',
    'nuvola_in_bottiglia' =>
      'assets/oculum/home_art/theme_nuvola_in_bottiglia_v1.png',
    'il_doppione' => 'assets/oculum/home_art/theme_il_doppione_v1.png',
    'aberrazione_metallica_angelica' =>
      'assets/oculum/home_art/theme_aberrazione_metallica_angelica_v1.png',
    'aberrazione_metallica_solare' =>
      'assets/oculum/home_art/theme_aberrazione_metallica_solare_v1.png',
    'funghetto_cappuccio_rosso' =>
      'assets/oculum/home_art/theme_funghetto_cappuccio_rosso_v1.png',
    'costrutto_minore' =>
      'assets/oculum/home_art/theme_costrutto_minore_v1.png',
    'shadow_devil' => 'assets/oculum/home_art/theme_shadow_devil_v1.png',
    'mostro_sabbia' => 'assets/oculum/home_art/theme_mostro_sabbia_v1.png',
    'gigante_sabbia' => 'assets/oculum/home_art/theme_gigante_sabbia_v1.png',
    'sharp' => 'assets/oculum/home_art/theme_sharp_v1.png',
    'topino_avventuroso' =>
      'assets/oculum/home_art/theme_topino_avventuroso_v1.png',
    'mosca_campana' => 'assets/oculum/home_art/theme_mosca_campana_v1.png',
    'pawn_guardiano' => 'assets/oculum/home_art/theme_pawn_v1.png',
    'ogle' => 'assets/oculum/home_art/theme_ogle_v1.png',
    'guardia_lunare' => 'assets/oculum/home_art/theme_guardia_lunare_v1.png',
    'guardia_lunare_elite' =>
      'assets/oculum/home_art/theme_guardia_lunare_elite_v1.png',
    'guardiano_lunare' =>
      'assets/oculum/home_art/theme_guardiano_lunare_v1.png',
    'guardian_devil_moon' =>
      'assets/oculum/home_art/theme_guardian_devil_moon_v1.png',
    'guardia_infernale_ik' =>
      'assets/oculum/home_art/theme_guardia_infernale_ik_v1.png',
    'guardia_infernale_ik_elite' =>
      'assets/oculum/home_art/theme_guardia_infernale_ik_elite_v1.png',
    'pinepine' => 'assets/oculum/home_art/theme_pinepine_v2.png',
    'grofix' => 'assets/oculum/home_art/theme_grofix_v1.png',
    'guardia_solare' => 'assets/oculum/home_art/theme_guardia_solare_v2.png',
    'guardia_solare_elite' =>
      'assets/oculum/home_art/theme_guardia_solare_elite_v2.png',
    'guardiano_solare' =>
      'assets/oculum/home_art/theme_guardiano_solare_v4.png',
    'mostro_lunare' => 'assets/oculum/home_art/creature_mostro_lunare_v1.png',
    'mostro_lunare_demoniaco' =>
      'assets/oculum/home_art/creature_mostro_lunare_demoniaco_v1.png',
    'scostubandito_errato' =>
      'assets/oculum/home_art/creature_scostubandito_errato_v1.png',
    'scostubandito_veterano_errato' =>
      'assets/oculum/home_art/creature_scostubandito_veterano_errato_v1.png',
    'fuocherelli' =>
      'assets/oculum/theme_stories/webp/creature_fuocherelli.webp',
    'feralis_ancestrale' =>
      'assets/oculum/theme_stories/webp/creature_feralis.webp',
    'granscostumato' =>
      'assets/oculum/theme_stories/webp/creature_granscostumato.webp',
    'sempre_verde' =>
      'assets/oculum/theme_stories/webp/creature_sempre_verde.webp',
    'lavastrello' =>
      'assets/oculum/theme_stories/webp/creature_lavastrello.webp',
    'thunderbird' =>
      'assets/oculum/theme_stories/webp/creature_thunderbird.webp',
    'scostubanditi' =>
      'assets/oculum/theme_stories/webp/creature_scostubanditi.webp',
    'bramble' => 'assets/oculum/home_art/theme_bramble_v3.png',
    'ombra_ignota' => 'assets/oculum/home_art/creature_ombra_v2.png',
    'uomo_maschera_solare' => 'assets/oculum/home_art/creature_solare_v2.png',
    'uomo_maschera_angelica' => 'assets/oculum/home_art/creature_angelico.png',
    'uomo_maschera_viola' => 'assets/oculum/home_art/creature_viola.png',
    'nuvi' => 'assets/oculum/home_art/creature_nuvi.png',
    _ => null,
  };
  String? get illustrationMobile => switch (monster.id) {
    'mezzo_demone_cosciente' =>
      'assets/oculum/home_art/theme_mezzo_demone_cosciente_mobile_v1.png',
    'nuvola_in_bottiglia' =>
      'assets/oculum/home_art/theme_nuvola_in_bottiglia_mobile_v1.png',
    'il_doppione' => 'assets/oculum/home_art/theme_il_doppione_mobile_v1.png',
    'aberrazione_metallica_angelica' =>
      'assets/oculum/home_art/theme_aberrazione_metallica_angelica_mobile_v1.png',
    'aberrazione_metallica_solare' =>
      'assets/oculum/home_art/theme_aberrazione_metallica_solare_mobile_v1.png',
    'funghetto_cappuccio_rosso' =>
      'assets/oculum/home_art/theme_funghetto_cappuccio_rosso_mobile_v1.png',
    'costrutto_minore' =>
      'assets/oculum/home_art/theme_costrutto_minore_mobile_v1.png',
    'shadow_devil' => 'assets/oculum/home_art/theme_shadow_devil_mobile_v1.png',
    'mostro_sabbia' =>
      'assets/oculum/home_art/theme_mostro_sabbia_mobile_v1.png',
    'gigante_sabbia' =>
      'assets/oculum/home_art/theme_gigante_sabbia_mobile_v1.png',
    'bramble' => 'assets/oculum/home_art/theme_bramble_mobile_v3.png',
    'pawn_guardiano' => 'assets/oculum/home_art/theme_pawn_mobile_v1.png',
    'ogle' => 'assets/oculum/home_art/theme_ogle_mobile_v1.png',
    'guardia_lunare' =>
      'assets/oculum/home_art/theme_guardia_lunare_mobile_v1.png',
    'guardia_lunare_elite' =>
      'assets/oculum/home_art/theme_guardia_lunare_elite_mobile_v1.png',
    'guardiano_lunare' =>
      'assets/oculum/home_art/theme_guardiano_lunare_mobile_v1.png',
    'guardian_devil_moon' =>
      'assets/oculum/home_art/theme_guardian_devil_moon_mobile_v1.png',
    'guardia_infernale_ik' =>
      'assets/oculum/home_art/theme_guardia_infernale_ik_mobile_v1.png',
    'guardia_infernale_ik_elite' =>
      'assets/oculum/home_art/theme_guardia_infernale_ik_elite_mobile_v1.png',
    'pinepine' => 'assets/oculum/home_art/theme_pinepine_mobile_v1.png',
    'grofix' => 'assets/oculum/home_art/theme_grofix_mobile_v1.png',
    'guardiano_solare' =>
      'assets/oculum/home_art/theme_guardiano_solare_mobile_v2.png',
    _ => null,
  };
  String get shape {
    if (const {
      'aberrazione_metallica_angelica',
      'aberrazione_metallica_solare',
    }.contains(monster.id)) {
      return 'plate';
    }
    if (monster.id == 'nuvola_in_bottiglia') return 'drop';
    if (monster.id == 'pinepine') return 'root';
    if (monster.id == 'guardiano_solare') return 'plate';
    final text = '${monster.id} ${monster.nameIt} ${monster.formTags.join(' ')}'
        .toLowerCase();
    if (text.contains('maschera') || monster.id == 'ombra_ignota') {
      return 'mask';
    }
    if (RegExp('observer|obser|denero').hasMatch(text)) return 'tear';
    if (RegExp('meccan|robot|bot|runic').hasMatch(text)) return 'core';
    if (RegExp(
      'farfall|falena|nuvi|brumilio|uccell|mosca|navigatore|ala|thunderbird',
    ).hasMatch(text)) {
      return 'wing';
    }
    if (RegExp('teschio|scheletr|morti|ossa').hasMatch(text)) return 'skull';
    if (RegExp('pupazzo|artiglio|mantide|ragno').hasMatch(text)) return 'claw';
    if (RegExp('golem|scudo|tartarug|roc|guravo|corazz').hasMatch(text)) {
      return 'plate';
    }
    if (RegExp(
      'coniglio|lepre|top|ogle|rascalume|scostubandit',
    ).hasMatch(text)) {
      return 'ears';
    }
    if (RegExp('albero|radic|legno|fung|vendulo|bramble').hasMatch(text)) {
      return 'root';
    }
    if (RegExp('medusa|slime|acqua|pesce|mirula').hasMatch(text)) return 'drop';
    return 'fang';
  }

  String get motif => switch (monster.id) {
    'mezzo_demone_cosciente' =>
      'Fauci del risveglio · corna a lama e pelle oliva',
    'nuvola_in_bottiglia' =>
      'Ampolla dei temporali · vetro e ricevitori color rame',
    'il_doppione' => 'Corona dell’illusione · lembi e copie',
    'aberrazione_metallica_angelica' =>
      'Mantello angelico · metallo bianco e oro',
    'aberrazione_metallica_solare' => 'Lamelle del mantello solare · oro',
    'funghetto_cappuccio_rosso' =>
      'Cappello rosso del sottobosco · muschio e foglie',
    'costrutto_minore' => 'Scudo del piccolo costrutto · bronzo consumato',
    'shadow_devil' => 'Resti dello Shadow Hell · corna e filamenti d’ombra',
    'mostro_sabbia' => 'Coda delle dune · strati di sabbia e artigli',
    'gigante_sabbia' => 'Coda del gigante · sabbia stratificata e artigli',
    'sharp' => 'Calotta dello scavatore · metallo e denti triangolari',
    'topino_avventuroso' =>
      'Ricordo del viandante · fiaccola e mantello tortora',
    'mosca_campana' => 'Rintocco del bosco · bronzo ossidato e ali sottili',
    'bramble' => 'Cuore del custode · corteccia e quattro tralci di rovi',
    'pawn_guardiano' => 'Sigillo del pedone · spada e scudo sospesi',
    'ogle' => 'Occhi del sottobosco · malva e artigli gialli',
    'guardia_lunare' =>
      'Sigillo della ronda pallida · argento annerito e pietra lunare',
    'guardia_lunare_elite' =>
      'Cimiero dei custodi antichi · argento annerito e viola lunare',
    'guardiano_lunare' =>
      'Corazza del colosso lunare · pietra integra e vene viola-blu',
    'guardian_devil_moon' =>
      'Sigillo della Devil Moon · pietra diabolica e luce infernale',
    'guardia_infernale_ik' =>
      'Emblema della ronda Ik · argento annerito e rosa infernale',
    'guardia_infernale_ik_elite' =>
      'Cimiero reale Ik · corazza e scudo della guardia Elité',
    _ => _fallbackMotif,
  };
  String get _fallbackMotif => monster.id == 'pinepine'
      ? 'Squame della pigna curiosa · aghi e seme del bosco'
      : monster.id == 'guardiano_solare'
      ? 'Elmo del colosso · arco e due frecce d’oro'
      : switch (shape) {
          'mask' =>
            monster.id == 'ombra_ignota'
                ? 'Spirale d’ossidiana · un solo occhio viola'
                : 'Maschera incisa · ${color.name.toLowerCase()}',
          'tear' => 'Lacrima d’Obser · fenditure e iride',
          'core' => 'Nucleo runico · ottone e giunti bruniti',
          'wing' => 'Piume e nervature · argento consumato',
          'skull' => 'Osso inciso · filo funerario',
          'claw' => 'Artigli ricurvi · cuciture e legature',
          'plate' => 'Scaglie sovrapposte · pietra levigata',
          'ears' => 'Orecchie sottili · talismano intagliato',
          'root' => 'Radici intrecciate · nodi di corteccia',
          'drop' => 'Goccia sospesa · vetro e filamenti',
          _ => 'Zanne legate · incisioni della creatura',
        };
}

OculumMonsterTheme? oculumMonsterThemeById(String key) {
  final parts = key.split('/');
  if (parts.length != 3 || parts.first != 'monster') return null;
  final monster = monsterBookEntryById(parts[1]);
  if (monster == null) return null;
  final colors = oculumMonsterColors(monster);
  final color = colors.where((c) => c.id == parts[2]).firstOrNull;
  return color == null ? null : OculumMonsterTheme(monster, color);
}

/// Artwork and access are separate. Owning a creature never unlocks its theme
/// for all player sheets; the party must still discover or buy its exact page.
final oculumMonsterThemeUnlocks = ValueNotifier<Set<String>>({});
final oculumSheetMonsterThemes = ValueNotifier<Map<String, String>>({});

class OculumMonsterRelic extends StatelessWidget {
  const OculumMonsterRelic({super.key, required this.theme});
  final OculumMonsterTheme theme;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          width: 240,
          height: 280,
          child: theme.relicIllustration == null
              ? CustomPaint(painter: OculumMonsterRelicPainter(theme))
              : Padding(
                  padding: const EdgeInsets.all(19.2),
                  child: Image.asset(
                    theme.relicIllustration!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        CustomPaint(painter: OculumMonsterRelicPainter(theme)),
                  ),
                ),
        ),
      ),
    ),
  );
}

/// Small authored silhouettes, engraved rather than glowing. All geometry is
/// vector-native, so the same relic stays crisp on a phone and a large display.
class OculumMonsterRelicPainter extends CustomPainter {
  OculumMonsterRelicPainter(this.theme);
  final OculumMonsterTheme theme;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final scale = math.min(size.width / 200, size.height / 240);
    canvas.translate(
      (size.width - 200 * scale) / 2,
      (size.height - 240 * scale) / 2,
    );
    canvas.scale(scale);
    final accent = theme.accent;
    final edge = Paint()
      ..color = Color.lerp(accent, const Color(0xffe1d6bc), .25)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final cut = Paint()
      ..color = const Color(0xff080a0e)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round;
    final etch = Paint()
      ..color = accent.withValues(alpha: .45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7;
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(accent, const Color(0xff28282e), .52)!,
          const Color(0xff14151b),
          Color.lerp(accent, const Color(0xff111318), .75)!,
        ],
      ).createShader(const Rect.fromLTWH(20, 20, 160, 190));
    final inset = 18 + theme.seed % 9;
    // A broken suspension frame, with asymmetrical ties rather than a halo.
    final suspension = Path()
      ..moveTo(100, 7)
      ..lineTo(93, 18)
      ..lineTo(100, 26)
      ..lineTo(107, 18)
      ..close();
    canvas.drawPath(suspension, etch);
    for (final side in [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(100 + side * 8, 22)
          ..cubicTo(
            100 + side * 77,
            35,
            100 + side * 91,
            154,
            100 + side * 58,
            196,
          ),
        etch,
      );
      for (var i = 0; i < 4; i++) {
        final y = 71.0 + i * 29 + theme.seed % 5;
        canvas.drawLine(
          Offset(100 + side * (78 - i * 2), y),
          Offset(100 + side * (83 - i * 2), y + 3),
          edge,
        );
      }
    }
    void plate(Path p) {
      canvas.drawPath(p, fill);
      canvas.drawPath(p, edge);
    }

    void eye(double x, double y, {double width = 19, bool purple = false}) {
      final p = Path()
        ..moveTo(x - width, y)
        ..quadraticBezierTo(x, y - 12, x + width, y)
        ..quadraticBezierTo(x, y + 10, x - width, y)
        ..close();
      canvas.drawPath(p, Paint()..color = const Color(0xff05060a));
      canvas.drawPath(p, etch);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: width * .63, height: 17),
        Paint()..color = purple ? const Color(0xffaa79da) : accent,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 3, height: 13),
        Paint()..color = const Color(0xff11101b),
      );
      canvas.drawCircle(
        Offset(x - 2, y - 4),
        1.7,
        Paint()..color = const Color(0xffddd1ee),
      );
    }

    switch (theme.shape) {
      case 'mask':
        plate(
          Path()
            ..moveTo(100, 34)
            ..cubicTo(29, 32, 35, 121, 56, 161)
            ..quadraticBezierTo(100, 216, 144, 161)
            ..cubicTo(165, 121, 171, 32, 100, 34)
            ..close(),
        );
        if (theme.monster.id == 'ombra_ignota') {
          final p = Path();
          for (var i = 0; i < 250; i++) {
            final t = i / 249 * math.pi * 6.1;
            final r = 3 + t * 3.5;
            final point = Offset(
              78 + math.cos(t) * r * .94,
              108 + math.sin(t) * r * 1.15,
            );
            if (i == 0) {
              p.moveTo(point.dx, point.dy);
            } else {
              p.lineTo(point.dx, point.dy);
            }
          }
          canvas.save();
          canvas.clipPath(
            Path()..addOval(const Rect.fromLTWH(44, 37, 113, 158)),
          );
          canvas.drawPath(p, cut);
          canvas.drawPath(p.shift(const Offset(.8, 1)), etch);
          canvas.restore();
          eye(78, 108, width: 20, purple: true);
        } else {
          if (theme.monster.id.contains('solare') ||
              theme.monster.id.contains('angelica')) {
            eye(78, 108, width: 20);
          } else {
            eye(76, 108, width: 15);
            eye(124, 108, width: 15);
          }
          canvas.drawPath(
            Path()
              ..moveTo(100, 110)
              ..lineTo(95, 139)
              ..lineTo(104, 141),
            etch,
          );
          canvas.drawPath(
            Path()
              ..moveTo(80, 159)
              ..quadraticBezierTo(100, 166, 120, 159),
            cut,
          );
          if (theme.monster.id.contains('solare') ||
              theme.monster.id.contains('angelica')) {
            canvas.drawCircle(const Offset(100, 66), 10, edge);
            for (var i = 0; i < 12; i++) {
              final a = i * math.pi / 6;
              canvas.drawLine(
                Offset(100 + math.cos(a) * 14, 66 + math.sin(a) * 14),
                Offset(100 + math.cos(a) * 20, 66 + math.sin(a) * 20),
                etch,
              );
            }
          } else {
            canvas.drawPath(
              Path()
                ..moveTo(77, 65)
                ..lineTo(100, 80)
                ..lineTo(123, 65)
                ..moveTo(88, 66)
                ..lineTo(100, 54)
                ..lineTo(112, 66),
              etch,
            );
          }
        }
      case 'tear':
        plate(
          Path()
            ..moveTo(100, 31)
            ..cubicTo(82, 60, 38, 110, 45, 153)
            ..cubicTo(54, 218, 146, 218, 155, 153)
            ..cubicTo(162, 110, 118, 60, 100, 31)
            ..close(),
        );
        eye(
          100,
          134,
          width: 42,
          purple: !theme.monster.id.contains('sunshine'),
        );
        for (var i = 0; i < 7; i++) {
          final a = i * math.pi * 2 / 7;
          canvas.drawPath(
            Path()
              ..moveTo(100 + math.cos(a) * 50, 137 + math.sin(a) * 57)
              ..lineTo(
                100 + math.cos(a + .08) * 65,
                137 + math.sin(a + .08) * 69,
              )
              ..lineTo(100 + math.cos(a) * 73, 137 + math.sin(a) * 78),
            etch,
          );
        }
      case 'wing':
        for (final s in [-1.0, 1.0]) {
          canvas.save();
          canvas.translate(100, 118);
          canvas.scale(s, 1);
          plate(
            Path()
              ..moveTo(0, 26)
              ..cubicTo(16, -33, 48, -64, 79, -73)
              ..quadraticBezierTo(82, -23, 38, 31)
              ..lineTo(10, 50)
              ..close(),
          );
          for (var i = 0; i < 7; i++) {
            canvas.drawPath(
              Path()
                ..moveTo(7, 28)
                ..quadraticBezierTo(
                  30 + i * 4,
                  -i * 5,
                  75 - i * 7,
                  -64 + i * 13,
                ),
              etch,
            );
          }
          canvas.restore();
        }
        canvas.drawLine(const Offset(100, 67), const Offset(100, 183), edge);
      case 'core':
        plate(
          Path()
            ..moveTo(63, 59)
            ..lineTo(137, 59)
            ..lineTo(165, 92)
            ..lineTo(165, 153)
            ..lineTo(133, 184)
            ..lineTo(67, 184)
            ..lineTo(35, 153)
            ..lineTo(35, 92)
            ..close(),
        );
        canvas.drawCircle(const Offset(100, 122), 37, cut);
        canvas.drawCircle(const Offset(100, 122), 30, edge);
        eye(100, 122, width: 24);
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          canvas.drawCircle(
            Offset(100 + math.cos(a) * 53, 122 + math.sin(a) * 53),
            2.3,
            etch,
          );
        }
        canvas.drawPath(
          Path()
            ..moveTo(62, 84)
            ..lineTo(70, 94)
            ..lineTo(59, 104)
            ..moveTo(138, 160)
            ..lineTo(130, 150)
            ..lineTo(141, 140),
          edge,
        );
      case 'skull':
        plate(
          Path()
            ..moveTo(100, 49)
            ..cubicTo(28, 47, 42, 129, 58, 142)
            ..lineTo(69, 177)
            ..lineTo(131, 177)
            ..lineTo(142, 142)
            ..cubicTo(158, 129, 172, 47, 100, 49)
            ..close(),
        );
        canvas.drawOval(
          const Rect.fromLTWH(60, 98, 29, 31),
          Paint()..color = const Color(0xff090a10),
        );
        canvas.drawOval(
          const Rect.fromLTWH(111, 98, 29, 31),
          Paint()..color = const Color(0xff090a10),
        );
        canvas.drawPath(
          Path()
            ..moveTo(100, 127)
            ..lineTo(91, 145)
            ..lineTo(109, 145)
            ..close(),
          cut,
        );
        for (var i = 0; i < 5; i++) {
          canvas.drawLine(
            Offset(77 + i * 11, 157),
            Offset(77 + i * 11, 177),
            etch,
          );
        }
      case 'ears':
        for (final s in [-1.0, 1.0]) {
          canvas.save();
          canvas.translate(100, 110);
          canvas.scale(s, 1);
          plate(
            Path()
              ..moveTo(9, 0)
              ..cubicTo(14, -51, 33, -79, 43, -81)
              ..cubicTo(57, -44, 51, -16, 29, 15)
              ..close(),
          );
          canvas.drawLine(const Offset(26, -7), const Offset(39, -62), etch);
          canvas.restore();
        }
        plate(
          Path()
            ..moveTo(55, 109)
            ..quadraticBezierTo(100, 82, 145, 109)
            ..quadraticBezierTo(162, 157, 100, 185)
            ..quadraticBezierTo(38, 157, 55, 109)
            ..close(),
        );
        eye(77, 132, width: 11);
        eye(123, 132, width: 11);
        canvas.drawPath(
          Path()
            ..moveTo(96, 155)
            ..lineTo(100, 159)
            ..lineTo(104, 155),
          etch,
        );
      case 'plate':
        for (var row = 0; row < 3; row++) {
          for (var col = 0; col < 3; col++) {
            final x = 63.0 + col * 35 + (row.isOdd ? 9 : 0),
                y = 75.0 + row * 38;
            plate(
              Path()
                ..moveTo(x - 22, y)
                ..quadraticBezierTo(x, y - 22, x + 22, y)
                ..lineTo(x + 14, y + 21)
                ..lineTo(x, y + 32)
                ..lineTo(x - 14, y + 21)
                ..close(),
            );
          }
        }
      case 'claw':
      case 'fang':
        for (var i = 0; i < 3; i++) {
          final x = 59.0 + i * 37;
          plate(
            Path()
              ..moveTo(x - 9, 69 + i * 4)
              ..cubicTo(x - 24, 121, x + 12, 154, x - 6, 181 + i * 5)
              ..cubicTo(x + 40, 151, x + 15, 103, x + 10, 65 + i * 4)
              ..close(),
          );
          canvas.drawPath(
            Path()
              ..moveTo(x - 7, 80)
              ..quadraticBezierTo(x + 3, 122, x + 1, 150),
            etch,
          );
        }
        canvas.drawPath(
          Path()
            ..moveTo(38, 80)
            ..quadraticBezierTo(103, 106, 159, 80),
          cut,
        );
        canvas.drawPath(
          Path()
            ..moveTo(38, 77)
            ..quadraticBezierTo(103, 103, 159, 77),
          edge,
        );
      case 'root':
        for (var i = 0; i < 5; i++) {
          final x = 57.0 + i * 22;
          plate(
            Path()
              ..moveTo(98, 67)
              ..cubicTo(x + 20, 91, x - 16, 155, x - 14, 187)
              ..quadraticBezierTo(x + 8, 168, x + 4, 154)
              ..cubicTo(x + 23, 133, 113, 105, 102, 67)
              ..close(),
          );
        }
        canvas.drawOval(const Rect.fromLTWH(72, 48, 56, 35), fill);
        canvas.drawOval(const Rect.fromLTWH(72, 48, 56, 35), edge);
      case 'drop':
        plate(
          Path()
            ..moveTo(100, 44)
            ..cubicTo(92, 88, 48, 105, 57, 150)
            ..cubicTo(63, 192, 137, 192, 143, 150)
            ..cubicTo(152, 105, 108, 88, 100, 44)
            ..close(),
        );
        for (var i = 0; i < 4; i++) {
          canvas.drawPath(
            Path()
              ..moveTo(73 + i * 17, 155)
              ..cubicTo(60 + i * 20, 181, 85 + i * 10, 197, 69 + i * 22, 213),
            etch,
          );
        }
        canvas.drawPath(
          Path()
            ..moveTo(83, 103)
            ..quadraticBezierTo(67, 127, 76, 143),
          edge,
        );
    }
    // The engraving pattern is unique for each exact species/variant, and is
    // stable across platforms. It never uses random values while painting.
    for (var i = 0; i < 9; i++) {
      final x = 65.0 + i * 8;
      final h = 3.0 + ((theme.seed >> (i * 2)) & 3) * 2;
      canvas.drawLine(Offset(x, 218), Offset(x, 218 + h), etch);
    }
    canvas.drawPath(
      Path()
        ..moveTo(inset.toDouble() + 24, 210)
        ..quadraticBezierTo(100, 230, 176 - inset.toDouble(), 210),
      etch,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant OculumMonsterRelicPainter oldDelegate) =>
      oldDelegate.theme.id != theme.id;
}
