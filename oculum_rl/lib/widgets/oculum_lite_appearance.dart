import 'dart:math';

import 'package:flutter/material.dart';

enum OculumLiteHair {
  cropped('Corti'),
  tied('Legati'),
  shaggy('Scomposti'),
  highPony('Coda alta'),
  longBraid('Treccia lunga'),
  curls('Ricci'),
  mohawk('Cresta'),
  swept('Ciuffo laterale');

  const OculumLiteHair(this.label);
  final String label;
  bool get needsPaintedSilhouette => index > shaggy.index;
}

enum OculumLiteOutfit {
  cloak,
  cuirass,
  vest,
  duelist,
  ritual,
  postea,
  forager,
  lamellar,
}

enum OculumLiteLineage { human, goblin }

enum OculumLiteBody { masculine, feminine, androgynous, stocky, longlimbed }

enum OculumLiteFace { angular, rounded, strong, gaunt, square, soft }

enum OculumLiteHeadgear { none, band, circlet, horns, goggles, hood }

enum OculumLiteFaceDetail {
  none,
  scar,
  warpaint,
  freckles,
  clasp,
  blindfold,
  inkRunes,
}

enum OculumLiteEmblem { none, eye, moon, flame, rune, feather, crystal }

@immutable
class OculumLiteAppearance {
  const OculumLiteAppearance({
    this.cloth = const Color(0xff604262),
    this.accent = const Color(0xffd1a574),
    this.hair = const Color(0xff3b2827),
    this.skin = const Color(0xffc7926c),
    this.hairstyle = OculumLiteHair.tied,
    this.outfit = OculumLiteOutfit.cloak,
    this.lineage = OculumLiteLineage.human,
    this.body = OculumLiteBody.masculine,
    this.face = OculumLiteFace.angular,
    this.frame = .5,
    this.ears = .56,
    this.eyes = const Color(0xffdcab54),
    this.headgear = OculumLiteHeadgear.none,
    this.faceDetail = OculumLiteFaceDetail.none,
    this.emblem = OculumLiteEmblem.none,
  });

  final Color cloth, accent, hair, skin, eyes;
  final OculumLiteHair hairstyle;
  final OculumLiteOutfit outfit;
  final OculumLiteLineage lineage;
  final OculumLiteBody body;
  final OculumLiteFace face;
  final double frame, ears;
  final OculumLiteHeadgear headgear;
  final OculumLiteFaceDetail faceDetail;
  final OculumLiteEmblem emblem;

  bool get usesFeminineAtlas =>
      body == OculumLiteBody.feminine || body == OculumLiteBody.androgynous;

  static const evasore = OculumLiteAppearance(
    cloth: Color(0xff325a5c),
    accent: Color(0xffc6d4a4),
    hair: Color(0xff382831),
    skin: Color(0xffc58f72),
    hairstyle: OculumLiteHair.shaggy,
    outfit: OculumLiteOutfit.vest,
  );

  static const scostubandito = OculumLiteAppearance(
    cloth: Color(0xff554132),
    accent: Color(0xffab7846),
    hair: Color(0xff2a2423),
    skin: Color(0xff7b8549),
    eyes: Color(0xffe3bf57),
    lineage: OculumLiteLineage.goblin,
    body: OculumLiteBody.stocky,
    face: OculumLiteFace.strong,
    hairstyle: OculumLiteHair.cropped,
    outfit: OculumLiteOutfit.vest,
    headgear: OculumLiteHeadgear.hood,
    faceDetail: OculumLiteFaceDetail.scar,
    ears: .84,
  );

  static const clothPalette = [
    Color(0xff604262),
    Color(0xff355b50),
    Color(0xff812f39),
    Color(0xff31506f),
    Color(0xffa0916c),
    Color(0xff343139),
    Color(0xffb06637),
    Color(0xff5c457b),
    Color(0xff246c70),
    Color(0xff915b71),
    Color(0xff667342),
    Color(0xffd1c0a1),
  ];
  static const accentPalette = [
    Color(0xffd1a574),
    Color(0xffbac3cb),
    Color(0xff984f89),
    Color(0xff5f9696),
    Color(0xffcb7250),
    Color(0xffbfba6a),
    Color(0xff625a8d),
    Color(0xffe0c9a1),
  ];
  static const hairPalette = [
    Color(0xff3b2827),
    Color(0xff16131e),
    Color(0xffb76945),
    Color(0xffeee1ca),
    Color(0xff8e6d42),
    Color(0xff584373),
    Color(0xff366764),
    Color(0xff753a4a),
    Color(0xff4d6051),
    Color(0xff274a58),
    Color(0xffa65537),
    Color(0xff9c808d),
  ];
  static const skinPalette = [
    Color(0xffc7926c),
    Color(0xffedbd9e),
    Color(0xff8a583d),
    Color(0xff643c33),
    Color(0xff718255),
    Color(0xff44695e),
    Color(0xff78808c),
    Color(0xffa17e98),
    Color(0xff9da471),
    Color(0xffb28797),
    Color(0xff9baeb5),
    Color(0xff7c6260),
  ];
  static const eyePalette = [
    Color(0xffdcab54),
    Color(0xffd67756),
    Color(0xff79ccb4),
    Color(0xffced0e0),
    Color(0xffa48ed4),
    Color(0xffb5cb6f),
    Color(0xff77a8e8),
    Color(0xffde717f),
  ];

  OculumLiteAppearance copyWith({
    Color? cloth,
    Color? accent,
    Color? hair,
    Color? skin,
    Color? eyes,
    OculumLiteHair? hairstyle,
    OculumLiteOutfit? outfit,
    OculumLiteLineage? lineage,
    OculumLiteBody? body,
    OculumLiteFace? face,
    double? frame,
    double? ears,
    OculumLiteHeadgear? headgear,
    OculumLiteFaceDetail? faceDetail,
    OculumLiteEmblem? emblem,
  }) => OculumLiteAppearance(
    cloth: cloth ?? this.cloth,
    accent: accent ?? this.accent,
    hair: hair ?? this.hair,
    skin: skin ?? this.skin,
    eyes: eyes ?? this.eyes,
    hairstyle: hairstyle ?? this.hairstyle,
    outfit: outfit ?? this.outfit,
    lineage: lineage ?? this.lineage,
    body: body ?? this.body,
    face: face ?? this.face,
    frame: frame ?? this.frame,
    ears: ears ?? this.ears,
    headgear: headgear ?? this.headgear,
    faceDetail: faceDetail ?? this.faceDetail,
    emblem: emblem ?? this.emblem,
  );

  factory OculumLiteAppearance.random(Random random) {
    T pick<T>(List<T> options) => options[random.nextInt(options.length)];
    final lineage = pick(OculumLiteLineage.values);
    return OculumLiteAppearance(
      cloth: pick(clothPalette),
      accent: pick(accentPalette),
      hair: pick(hairPalette),
      skin: pick(skinPalette),
      eyes: pick(eyePalette),
      hairstyle: pick(OculumLiteHair.values),
      outfit: pick(OculumLiteOutfit.values),
      lineage: lineage,
      body: pick(OculumLiteBody.values),
      face: pick(OculumLiteFace.values),
      frame: random.nextDouble(),
      ears: random.nextDouble(),
      headgear: pick(OculumLiteHeadgear.values),
      faceDetail: pick(OculumLiteFaceDetail.values),
      emblem: pick(OculumLiteEmblem.values),
    );
  }

  factory OculumLiteAppearance.fromJson(Object? source) {
    final json = source is Map ? source : const {};
    const defaults = OculumLiteAppearance();
    T option<T extends Enum>(List<T> values, String key, T fallback) =>
        values.where((item) => item.name == json[key]).firstOrNull ?? fallback;
    double proportion(String key, double fallback) {
      final value = json[key];
      return value is num && value.isFinite
          ? value.toDouble().clamp(0.0, 1.0)
          : fallback;
    }

    Color color(String key, Color fallback) {
      final value = json[key];
      return value is int && value >= 0 && value <= 0xffffffff
          ? Color(0xff000000 | value)
          : fallback;
    }

    return OculumLiteAppearance(
      cloth: color('cloth', defaults.cloth),
      accent: color('accent', defaults.accent),
      hair: color('hair', defaults.hair),
      skin: color('skin', defaults.skin),
      eyes: color('eyes', defaults.eyes),
      hairstyle: option(OculumLiteHair.values, 'hairstyle', defaults.hairstyle),
      outfit: option(OculumLiteOutfit.values, 'outfit', defaults.outfit),
      lineage: option(OculumLiteLineage.values, 'lineage', defaults.lineage),
      body: option(OculumLiteBody.values, 'body', defaults.body),
      face: option(OculumLiteFace.values, 'face', defaults.face),
      frame: proportion('frame', defaults.frame),
      ears: proportion('ears', defaults.ears),
      headgear: option(
        OculumLiteHeadgear.values,
        'headgear',
        defaults.headgear,
      ),
      faceDetail: option(
        OculumLiteFaceDetail.values,
        'faceDetail',
        defaults.faceDetail,
      ),
      emblem: option(OculumLiteEmblem.values, 'emblem', defaults.emblem),
    );
  }

  Map<String, Object> toJson() => {
    'cloth': cloth.toARGB32(),
    'accent': accent.toARGB32(),
    'hair': hair.toARGB32(),
    'skin': skin.toARGB32(),
    'eyes': eyes.toARGB32(),
    'hairstyle': hairstyle.name,
    'outfit': outfit.name,
    'lineage': lineage.name,
    'body': body.name,
    'face': face.name,
    'frame': frame,
    'ears': ears,
    'headgear': headgear.name,
    'faceDetail': faceDetail.name,
    'emblem': emblem.name,
  };

  bool sameAs(OculumLiteAppearance other) =>
      cloth == other.cloth &&
      accent == other.accent &&
      hair == other.hair &&
      skin == other.skin &&
      eyes == other.eyes &&
      hairstyle == other.hairstyle &&
      outfit == other.outfit &&
      lineage == other.lineage &&
      body == other.body &&
      face == other.face &&
      frame == other.frame &&
      ears == other.ears &&
      headgear == other.headgear &&
      faceDetail == other.faceDetail &&
      emblem == other.emblem;
}
