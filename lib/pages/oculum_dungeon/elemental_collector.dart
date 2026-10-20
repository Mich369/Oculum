part of 'monster_book.dart';

/// A towering, unsettling clown that collects and replays elements used
/// against it. Its level-zero stats and base elemental ward are fixed by the
/// encounter entry; its abilities remain editable after import.
const List<MonsterBookEntry> _elementalCollectorEntries = [
  MonsterBookEntry(
    id: 'collezionista_di_elementi',
    nameIt: 'Collezionista di Elementi',
    nameEn: 'Element Collector',
    descIt:
        'Boss: un clown gigante e inquietante, vestito d’oro e marmo screpolato. Parte con la Resistenza standard (-25%) contro tutti gli elementi. Ogni elemento che lo colpisce viene registrato e può essere riutilizzato nei suoi attacchi; il più recente è proposto per primo. Se il bersaglio tenta di parare un suo attacco usando lo stesso elemento, subisce -2 al tiro difensivo. Adattamento da boss: +6% Resistenza per ogni elemento a ogni colpo, fino al 75%. Livello 0: RES 10, VOL 10, MAT 5, OCU 15; +15 Danni e +5 Difesa. Possiede una sola abilità: evoca tra le mani un martello elementale che solo lui può maneggiare.',
    descEn:
        'Boss: a towering, unsettling clown in cracked gold and marble. Starts with standard Resistance (-25%) against every element. Each element that hits it is recorded and can be replayed in its attacks; the most recently collected one is offered first. A target attempting to parry one of its attacks with the same element takes -2 to the defense roll. Boss adaptation: +6% Resistance for each element on every hit, up to 75%. Level 0: RES 10, WILL 10, MAT 5, OCU 15; +15 Damage and +5 Defense. It has one ability: conjures an elemental hammer between its hands that only it can wield.',
    elementId: 'fisico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: true,
    isNullFateless: false,
    stats: {
      'level': 0,
      'resilienza': 10,
      'volonta': 10,
      'materia': 5,
      'oculum': 15,
      'damageBonus': 15,
      'defenseBonus': 5,
      'elementalResistancePreset': 1,
    },
    skillIds: ['collettore_martello_elementale'],
    dropIds: ['frammento_oro_marmo', 'nucleo_elementale_incrinato'],
    classificationTags: ['Boss', 'Collezionista', 'Clown', 'Oro e Marmo'],
  ),
];
