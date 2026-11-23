part of '../../main.dart';

// Alternate labels used by the Master catalogue. The original technique name
// and its effect IDs still identify the saved skill and its forms.
const _oculumMonsterSkillNames = <(String, String, String, List<String>)>[
  (
    'Passiva della Marionettista',
    'Legame di Necthrall',
    'Necthrall’s Bond',
    ['Puppeteer’s Bond', 'Puppeteer Bond', 'Fili della Marionettista'],
  ),
  ('Falce dell’Anima', 'Anymareap', 'Soul Reap', ['Animareap']),
  ('Eco intracranica', 'Sonoryft', 'Intracranial Echo', ['Sonorift']),
  ('Rintocco d’arresto', 'Systochime', 'Arresting Chime', ['Sistochime']),
  ('Getto d’Acqua', 'Aquaspyte', 'Water Jet', ['Aquaspite', 'Getto salmastro']),
  ('Soglia muta', 'Muteward', 'Silent Threshold', ['Guardia silenziosa']),
  ('Fendente dell’Oblio', 'Oblyslash', 'Oblivion Slash', ['Oblislash']),
  ('Velo d’incenso', 'Cynervyl', 'Incense Veil', ['Cinervil']),
  (
    'Sigillo di cenere',
    'Cynermark',
    'Ash Seal',
    ['Cinermark', 'Marchio di cenere'],
  ),
];

final _oculumMonsterSkillNamesByAlias = {
  for (final entry in _oculumMonsterSkillNames)
    for (final label in [entry.$1, entry.$2, entry.$3, ...entry.$4])
      oculumNormalizeText(label): entry,
};

String? oculumMonsterSkillDisplayName(String name) =>
    _oculumMonsterSkillNamesByAlias[oculumNormalizeText(name)]?.$2;

Iterable<String> oculumMonsterSkillSearchAliases(String name) {
  final entry = _oculumMonsterSkillNamesByAlias[oculumNormalizeText(name)];
  if (entry == null) return const [];
  return [entry.$1, entry.$2, entry.$3, ...entry.$4];
}
