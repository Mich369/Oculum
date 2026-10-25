import 'package:flutter/material.dart';

/// Readable accents taken from each habitat/material, not a shared blue tint.
Color oculumNarrativeAccent(String id) {
  final key = id.toLowerCase();
  const exact = {
    'hidenas': Color(0xffefad69),
    'benedict': Color(0xffdfc78c),
    'plane_demoniaco': Color(0xffef8264),
    'plane_diabolico': Color(0xffdd7c99),
    'plane_mezzano': Color(0xffc8ae80),
    'plane_sacro': Color(0xfff0c66e),
    'plane_angelico': Color(0xffd9d8b6),
    'plane_oblio': Color(0xffbca0ec),
    'plane_shadow_hell': Color(0xffce8eb6),
    'plane_isole': Color(0xffa8bafa),
    'plane_affogato': Color(0xff69c7c6),
    'plane_sotterraneo': Color(0xffb7ae7c),
    'plane_sotterraneo_maggiore': Color(0xffb2a1df),
    'plane_postea': Color(0xff6fd4d7),
    'plane_caramella': Color(0xffeea4bb),
    'plane_foresta_elementale': Color(0xff96d09b),
    'plane_morti': Color(0xffa5cba3),
    'plane_ghiaccio': Color(0xffa1d9ec),
    'plane_nuvole_rocciose': Color(0xffa8b4e5),
    'dedicated_indigo': Color(0xffafa7f3),
    'dedicated_cloud_sea': Color(0xff8fc8f3),
    'dedicated_aurora': Color(0xffe1b1e9),
    'restyle_sogno': Color(0xffb5b2f1),
  };
  if (exact.containsKey(key)) return exact[key]!;
  for (final entry in const <String, Color>{
    'lava': Color(0xfff29a5b),
    'fuoco': Color(0xffed8773),
    'acqua': Color(0xff73bde8),
    'gelo': Color(0xffb2dfea),
    'ghiaccio': Color(0xffb2dfea),
    'terra': Color(0xffc4a57b),
    'roccia': Color(0xffb6b2a3),
    'natura': Color(0xff97ca8b),
    'pianta': Color(0xff97ca8b),
    'veleno': Color(0xffb0d36d),
    'acido': Color(0xffd1da73),
    'fulmine': Color(0xffecd47b),
    'energia': Color(0xff8bdaea),
    'buio': Color(0xffb4a2dd),
    'oblio': Color(0xffbca0ec),
    'oculum': Color(0xffc2a0f0),
    'sogno': Color(0xffc7b6ed),
    'psichico': Color(0xffdc9ddd),
    'sonoro': Color(0xffee9fce),
    'sangue': Color(0xffdf8998),
    'vento': Color(0xff95d8c9),
    'nuvola': Color(0xffb6c8ef),
    'solare': Color(0xffedc269),
    'angelico': Color(0xffe3dbb7),
    'spirit': Color(0xffb7d4df),
    'morti': Color(0xffa5cba3),
  }.entries) {
    if (key.contains(entry.key)) return entry.value;
  }
  return const Color(0xffb8b9ca);
}
