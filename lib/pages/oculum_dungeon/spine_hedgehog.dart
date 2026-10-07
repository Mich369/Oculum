part of 'monster_book.dart';

const oculumSpineHedgehogId = 'riccio_aculeo';
final _spineHedgehogEntries = [
  MonsterBookEntry(
    id: oculumSpineHedgehogId,
    nameIt: 'Riccio Aculeo', nameEn: 'Spine Hedgehog',
    descIt: 'Riccio notturno con aculei ossei e un occhio color ametista. Livello 0, grado 0: RES 3, VOL 1, MAT 2, OCU 3. Oculum Art: L’aculeo. La sua armatura sottopelle cresce automaticamente ai livelli 2, 4 e 6. Le stesse tecniche e resistenze rimangono disponibili come Occhio dei Caduti.',
    descEn: 'Nocturnal hedgehog with bone spines and an amethyst eye. Oculum Art: The Spine.',
    elementId: 'perforante', spriteAssetPath: '',
    isMiniBoss: false, isBoss: false, isNullFateless: false,
    stats: const {'level': 0, 'resilienza': 3, 'volonta': 1, 'materia': 2, 'oculum': 3, 'oculumArt': 1},
    skillIds: const ['riccio_aculeo_lancio', 'riccio_aculeo_armatura', 'riccio_aculeo_precisi'],
    dropIds: const ['osserin', 'pelle_mostro'],
    dropChances: const {'osserin': 60, 'pelle_mostro': 35},
  ),
];

const oculumSpineVariants = [
  (id: 'legno', name: 'Riccio Aculeo di Thornil', bonus: 1, element: 'natura', drop: 'thornil', effect: 'Aculei lignei: +1 danno, Fragilità al Fuoco.'),
  (id: 'osso', name: 'Riccio Aculeo di Osserin', bonus: 2, element: 'perforante', drop: 'osserin', effect: 'Aculei ossei: +2 danni e +1 Difesa.'),
  (id: 'ferro', name: 'Riccio Aculeo di Feralis', bonus: 3, element: 'metallo', drop: 'feralis', effect: 'Aculei metallici: +3 danni e +2 Difesa.'),
  (id: 'argento', name: 'Riccio Aculeo d’Argento', bonus: 5, element: 'luce', drop: 'nacrel', effect: 'Materia base +5; aculei argentati: +5 danni di Luce.'),
  (id: 'runico', name: 'Riccio Aculeo di Metallo Runico', bonus: 5, element: 'oculum', drop: 'metallo_runico', effect: 'Aculei runici: +5 danni di Oculum e +3 Difesa; un 20 naturale di Precisione recupera 1 Oculum, mai oltre il massimo.'),
  (id: 'velenoso', name: 'Riccio Aculeo Velenoso', bonus: 2, element: 'veleno', drop: 'thornil', effect: 'Mantello viola e aculei dalle punte verdi. Se colpisce applica Veleno Putrido I per un turno.'),
  (id: 'ghiaccio', name: 'Riccio Aculeo di Ghiaccio', bonus: 3, element: 'ghiaccio', drop: 'nebrin', effect: 'Aculei di ghiaccio: se colpisce applica Gelo I per un turno.'),
];

final _spineHedgehogVariantEntries = [
  MonsterBookEntry(
    id: 'riccio_aculeo_variante_errante', nameIt: 'Riccio Aculeo Errante', nameEn: 'Wandering Spine Hedgehog',
    descIt: 'Variante di combattimento stabile del Riccio Aculeo: alterna lancio, armatura e aculei precisi.', descEn: 'Stable combat variant of the Spine Hedgehog.',
    elementId: 'perforante', spriteAssetPath: '', isMiniBoss: false, isBoss: false, isNullFateless: false,
    stats: const {'level': 3, 'resilienza': 5, 'volonta': 3, 'materia': 4, 'oculum': 5, 'oculumArt': 1},
    skillIds: const ['riccio_aculeo_lancio_variante_errante', 'riccio_aculeo_armatura_variante_errante', 'riccio_aculeo_precisi_variante_errante'],
    dropIds: const ['osserin', 'pelle_mostro'], dropChances: const {'osserin': 60, 'pelle_mostro': 35},
  ),
  for (final variant in oculumSpineVariants)
    MonsterBookEntry(
      id: 'riccio_aculeo_${variant.id}', nameIt: variant.name, nameEn: variant.name,
      descIt: '${variant.name}. ${variant.effect} Conserva L’aculeo, costi e requisiti del Riccio base, con proprietà proprie del materiale. Varianti di materiale in ordine crescente: Thornil, Osserin, Feralis, Argento, Metallo Runico. Le proprietà rimangono come Occhio dei Caduti.',
      descEn: variant.effect, elementId: variant.element, spriteAssetPath: '',
      isMiniBoss: false, isBoss: false, isNullFateless: false,
      stats: {'level': 0, 'resilienza': 3, 'volonta': 1, 'materia': 2 + variant.bonus, 'oculum': 3, 'oculumArt': 1},
      skillIds: [for (final suffix in ['lancio', 'armatura', 'precisi']) 'riccio_aculeo_${variant.id}_$suffix'],
      dropIds: [variant.drop, 'pelle_mostro'], dropChances: {variant.drop: 60, 'pelle_mostro': 35},
    ),
  for (final variant in oculumSpineVariants)
    MonsterBookEntry(
      id: 'riccio_aculeo_${variant.id}_variante_errante', nameIt: '${variant.name} Errante', nameEn: '${variant.name} Wandering',
      descIt: 'Variante di combattimento stabile di ${variant.name}: mantiene il materiale e alterna le tre tecniche.', descEn: 'Stable combat variant of ${variant.name}.',
      elementId: variant.element, spriteAssetPath: '', isMiniBoss: false, isBoss: false, isNullFateless: false,
      stats: {'level': 3, 'resilienza': 5, 'volonta': 3, 'materia': 4 + variant.bonus, 'oculum': 5, 'oculumArt': 1},
      skillIds: [for (final suffix in ['lancio', 'armatura', 'precisi']) 'riccio_aculeo_${variant.id}_${suffix}_variante_errante'],
      dropIds: [variant.drop, 'pelle_mostro'], dropChances: {variant.drop: 60, 'pelle_mostro': 35},
    ),
];

String oculumSpineVariantKey(String text) {
  for (final variant in oculumSpineVariants) {
    if (text.contains('riccio_aculeo_${variant.id}') || text.contains(variant.name)) return variant.id;
  }
  return '';
}

String oculumSpineHedgehogSkillText(String id) {
  final combatVariant = id.replaceFirst(RegExp(r'_variante_[a-z]+$'), '');
  if (combatVariant != id) return '${oculumSpineHedgehogSkillText(combatVariant)} Variante di combattimento stabile: valori adattati alla variante.';
  final variant = oculumSpineVariants.where((v) => id.startsWith('riccio_aculeo_${v.id}_')).firstOrNull;
  if (variant != null) {
    final base = 'riccio_aculeo_${id.split('_').last}';
    return '${oculumSpineHedgehogSkillText(base)} Proprietà ${variant.name}: ${variant.effect}';
  }
  return (switch (id) {
  'riccio_aculeo_lancio' => 'Lancio di aculei — I/Lanci aculei fino a Oculum avversari visibili. Danni perforanti normali per bersaglio, solo dopo un tiro riuscito. Costo 1/4 Oculum. Richiede livello 0. II/Lanci aculei fino a Oculum avversari; Danni +40 perforanti per bersaglio colpito. Costo 5/10 Oculum. Richiede livello 3. III/Lanci aculei fino a Oculum avversari; Danni +Oculum +100 perforanti per bersaglio colpito. Costo 11/40 Oculum. Richiede livello 9. Il numero di bersagli e il bonus Oculum usano il valore prima del costo; il bonus dura un turno e non si cumula.',
  'riccio_aculeo_armatura' => 'Armatura sottopelle — I/Passiva automatica: Resistenza Leggera a tutti i danni. Nessun costo. Richiede livello 2. II/Passiva automatica: Resistenza a tutti i danni. Nessun costo. Richiede livello 4. III/Passiva automatica: Alta Resistenza a tutti i danni. Nessun costo. Richiede livello 6. Si applica soltanto la forma più alta sbloccata, anche come Occhio dei Caduti; non moltiplica altre resistenze.',
  'riccio_aculeo_precisi' => 'Aculei precisi — I/Tiri automaticamente Precisione e aggiungi il totale ai Danni per un turno. Fragilità ai danni perforanti per un turno. Costo 2/2 Oculum. Richiede livello 1. II/Tiri automaticamente Precisione: Danni +tiro +Oculum ×2 per un turno; Fragilità perforante per un turno. Se colpisci, il bersaglio riceve Aculei vincolanti: nessuna reazione per un turno, indicata nel log del Master. Costo 5/5 Oculum. Richiede livello 4. III/Tiri automaticamente Precisione: Danni +tiro +Oculum ×5 per un turno; Fragilità perforante per un turno. Se colpisci, Aculei vincolanti impedisce le reazioni per due turni, indicato nel log del Master. Costo 11/11 Oculum. Richiede livello 9. Oculum è misurato prima del costo; gli effetti non si cumulano.',
  _ => '',
}).replaceAll('Costo 11/11 Oculum.', 'Costo iniziale 10/11 Oculum. Il massimale cresce con la Maestria d’uso; ogni Oculum speso oltre 11 aggiunge +5 danni.');
}
