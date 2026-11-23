part of 'monster_book.dart';

/// Draft entries are admitted together once encounter generation can spawn
/// both sheets atomically. Elements and skill numbers remain unconfirmed.
const oculumSpectralPairEntries = <MonsterBookEntry>[
  MonsterBookEntry(
    id: oculumAlbashardId,
    nameIt: 'Albashard',
    nameEn: 'Albashard',
    descIt:
        'Spettro bianco con un occhio in un anello color rame, due braccia '
        'scheletriche uncinate e una veste che si dissolve. Compare con Atrawisp.',
    descEn:
        'A white spectre with an eye in a copper-coloured ring, two hooked '
        'skeletal arms and a dissolving cloak. It appears with Atrawisp.',
    elementId: 'sconosciuto',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    encounterRules: {
      'authoredCanonical': true,
      'requiredCompanionMonsterId': oculumAtrawispId,
      'hasAnatomicalWeakPoint': false,
      'precisionBodyParts': [
        {
          'id': 'body',
          'group': 'body',
          'label': 'Corpo spettrale',
          'material': 'spectral',
        },
        {'id': 'eyes', 'group': 'eyes', 'label': 'Occhio centrale'},
        {
          'id': oculumAlbashardRingPart,
          'group': 'ring',
          'label': 'Anello dell’occhio',
        },
        {
          'id': 'arms_1',
          'group': 'arms',
          'label': 'Braccio uncinato destro',
          'side': 'right',
          'material': 'bone',
        },
        {
          'id': 'arms_2',
          'group': 'arms',
          'label': 'Braccio uncinato sinistro',
          'side': 'left',
          'material': 'bone',
        },
      ],
    },
  ),
  MonsterBookEntry(
    id: oculumAtrawispId,
    nameIt: 'Atrawisp',
    nameEn: 'Atrawisp',
    descIt:
        'Spettro nero dalla sagoma affusolata, con maschera a chevron e due '
        'ancore su catene distinte. Compare con Albashard.',
    descEn:
        'A slender black spectre with a chevron mask and two anchors on '
        'separate chains. It appears with Albashard.',
    elementId: 'sconosciuto',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    encounterRules: {
      'authoredCanonical': true,
      'requiredCompanionMonsterId': oculumAlbashardId,
      'hasAnatomicalWeakPoint': false,
      'precisionBodyParts': [
        {
          'id': 'body',
          'group': 'body',
          'label': 'Corpo spettrale',
          'material': 'spectral',
        },
        {
          'id': 'head',
          'group': 'head',
          'label': 'Testa con maschera a chevron',
        },
        {
          'id': oculumAtrawispFirstAnchorPart,
          'group': 'anchor',
          'label': 'Prima ancora',
        },
        {
          'id': oculumAtrawispSecondAnchorPart,
          'group': 'anchor',
          'label': 'Seconda ancora',
        },
      ],
    },
  ),
];
