part of 'monster_book.dart';

const oculumResiliumId = 'resilium';
const oculumMaterialId = 'material';

const _volenterosiUltimateIds = [
  'volenterosi_ultimo_giuramento',
  'volenterosi_corona_di_braci',
  'volenterosi_verdetto_cremisi',
];
const _resiliumUltimateIds = [
  'resilium_battito_rinnovato',
  'resilium_baluardo_vivente',
  'resilium_rinascita_verde',
];
const _materialUltimateIds = [
  'material_passo_inesistente',
  'material_eclissi_azzurra',
  'material_assenza_profonda',
];

const _resilium = MonsterBookEntry(
  id: oculumResiliumId,
  planeIds: ['mezzano'],
  nameIt: 'Resilium',
  nameEn: 'Resilium',
  descIt:
      'Custodi dall’aura verde. Respirano lentamente dietro una corazza '
      'consumata e ricompongono le ferite con tecniche di rigenerazione. Il '
      'primo attacco che sottrae Vita attiva Ricordo Vitale per 12 turni '
      'personali o fino al Riposo Lungo, che ricarica anche la passiva.',
  descEn:
      'Guardians with a green aura and worn armour who mend wounds. The '
      'first attack that removes Life activates Vital Memory for 12 personal '
      'turns or until a Long Rest, which also recharges the passive.',
  elementId: 'oculum',
  spriteAssetPath: '',
  isMiniBoss: false,
  isBoss: false,
  isNullFateless: false,
  stats: {
    'level': 3,
    'resilienza': 11,
    'volonta': 4,
    'materia': 6,
    'oculum': 5,
  },
  encounterRules: {
    'authoredCanonical': true,
    'loadoutPolicy': 'sample_three',
    'signatureSkillId': 'resilium_rimargina',
    'authoredUltimateIds': _resiliumUltimateIds,
  },
  skillIds: [
    'resilium_rimargina',
    'resilium_polso_verde',
    'resilium_pelle_cicatrizzata',
    'resilium_saldo_radice',
    'resilium_respiro_lento',
    'resilium_spalla_di_ferro',
    'resilium_ricuce_il_compagno',
    'resilium_contraccolpo',
    'resilium_riserva_vitale',
  ],
  classificationTags: ['Umanoide', 'Custode'],
);

const _material = MonsterBookEntry(
  id: oculumMaterialId,
  planeIds: ['mezzano'],
  nameIt: 'Material',
  nameEn: 'Material',
  descIt:
      'Viandanti rapidi con un’aura che sfuma dall’azzurro al blu. '
      'Sottraggono la propria sagoma alla traiettoria degli attacchi con '
      'scarti improvvisi e possono diventare Invisibili.',
  descEn:
      'Nimble wanderers with an aura that fades from light blue to navy. '
      'They slip out of the path of attacks and can turn Invisible.',
  elementId: 'oculum',
  spriteAssetPath: '',
  isMiniBoss: false,
  isBoss: false,
  isNullFateless: false,
  stats: {
    'level': 3,
    'resilienza': 6,
    'volonta': 4,
    'materia': 11,
    'oculum': 5,
  },
  encounterRules: {
    'authoredCanonical': true,
    'loadoutPolicy': 'sample_three',
    'signatureSkillId': 'material_sparizione',
    'authoredUltimateIds': _materialUltimateIds,
  },
  skillIds: [
    'material_scarto_azzurro',
    'material_sparizione',
    'material_velo_blu',
    'material_scivolo',
    'material_mano_liquida',
    'material_rifrazione',
    'material_traiettoria_rotta',
    'material_scia_fredda',
    'material_ombra_compagna',
  ],
  classificationTags: ['Umanoide', 'Viandante'],
);

final _lineageTechniques = <String, MonsterConcreteTechnique>{
  'volenterosi_guardia_di_braci': _lineageTechnique(
    'Guardia di Braci',
    'Stringi il pugno e forma una protezione cremisi',
    'scudo',
    ['8', '14', '22'],
  ),
  'volenterosi_affondo_risoluto': _lineageTechnique(
    'Affondo Risoluto',
    'Affonda in linea retta contro un bersaglio',
    'danno',
    ['4', '8', '13'],
    element: 'perforante',
  ),
  'volenterosi_passo_del_voto': _lineageTechnique(
    'Passo del Voto',
    'Avanza con passo deciso mentre chiudi la distanza',
    'velocita',
    ['2', '3', '4'],
  ),
  'volenterosi_giuramento_breve': _lineageTechnique(
    'Giuramento Breve',
    'Concentra la volontà nel braccio che impugna la spada',
    'modifica_statistica',
    ['2', '4', '6'],
    target: 'volonta',
  ),
  'volenterosi_mira_rossa': _lineageTechnique(
    'Mira Rossa',
    'Segui con l’occhio rosso una giuntura esposta',
    'modifica_sottotratto',
    ['2', '3', '5'],
    target: 'precisione',
  ),
  'volenterosi_respiro_fermo': _lineageTechnique(
    'Respiro Fermo',
    'Riprendi fiato senza interrompere la guardia',
    'cura',
    ['4', '7', '10'],
  ),
  'volenterosi_ultimo_giuramento': _lineageTechnique(
    'Ultimo Giuramento',
    'Lancia un fendente breve la cui forza cresce con il livello',
    'danno',
    ['2+livello', '4+livello', '6+livello'],
    element: 'taglio',
    cooldown: 5,
  ),
  'volenterosi_corona_di_braci': _lineageTechnique(
    'Corona di Braci',
    'Chiudi l’aura attorno al petto come uno scudo',
    'scudo',
    ['20+livello*2', '30+livello*2', '40+livello*2'],
    level: 9,
    cooldown: 6,
  ),
  'volenterosi_verdetto_cremisi': _lineageTechnique(
    'Verdetto Cremisi',
    'Concentrati su una sola lama cremisi',
    'danno',
    ['20+livello*2', '30+livello*2', '40+livello*2'],
    element: 'taglio',
    level: 15,
    cooldown: 7,
  ),

  'resilium_rimargina': _lineageTechnique(
    'Rimargina',
    'Richiudi parte di una tua ferita con l’aura verde',
    'cura',
    ['6', '10', '16'],
  ),
  'resilium_polso_verde': _lineageTechnique(
    'Polso Verde',
    'Distribuisci una piccola cura su due turni',
    'cura',
    ['3', '5', '8'],
    mode: 'rigenerazione',
    duration: '2',
  ),
  'resilium_pelle_cicatrizzata': _lineageTechnique(
    'Pelle Cicatrizzata',
    'Stringi l’aura contro la corazza',
    'scudo',
    ['8', '14', '21'],
  ),
  'resilium_saldo_radice': _lineageTechnique(
    'Saldo come Radice',
    'Pianta i piedi e rafforza la Difesa',
    'difesa',
    ['3', '6', '9'],
  ),
  'resilium_respiro_lento': _lineageTechnique(
    'Respiro Lento',
    'Stabilizza il respiro per rinforzare la Resilienza',
    'modifica_statistica',
    ['2', '4', '6'],
    target: 'resilienza',
  ),
  'resilium_spalla_di_ferro': _lineageTechnique(
    'Spalla di Ferro',
    'Colpisci a contatto con lo spallaccio',
    'danno',
    ['4', '8', '12'],
    element: 'contundente',
  ),
  'resilium_ricuce_il_compagno': _lineageTechnique(
    'Ricuci il Compagno',
    'Richiudi una ferita di un alleato vicino',
    'cura',
    ['5', '9', '14'],
    recipient: 'alleato',
  ),
  'resilium_contraccolpo': _lineageTechnique(
    'Contraccolpo Verde',
    'Reagisci con un colpo del palmo contro un avversario a contatto',
    'danno',
    ['3', '6', '9'],
    element: 'contundente',
  ),
  'resilium_riserva_vitale': _lineageTechnique(
    'Riserva Vitale',
    'Raduna l’aura verde in una breve riserva protettiva',
    'hp_temporanei',
    ['5', '8', '12'],
  ),
  'resilium_battito_rinnovato': _lineageTechnique(
    'Battito Rinnovato',
    'Recupera una piccola quantità di Vita che cresce con il livello',
    'cura',
    ['3+livello', '5+livello', '7+livello'],
    cooldown: 5,
  ),
  'resilium_baluardo_vivente': _lineageTechnique(
    'Baluardo Vivente',
    'Fai addensare l’aura in un largo riparo',
    'scudo',
    ['20+livello*2', '30+livello*2', '40+livello*2'],
    level: 9,
    cooldown: 6,
  ),
  'resilium_rinascita_verde': _lineageTechnique(
    'Rinascita Verde',
    'Rigenera Vita per tre turni',
    'cura',
    ['10+livello', '15+livello', '20+livello'],
    mode: 'rigenerazione',
    duration: '3',
    level: 15,
    cooldown: 7,
  ),

  'material_scarto_azzurro': _lineageTechnique(
    'Scarto Azzurro',
    'Scarta dalla traiettoria e rinforza i Riflessi',
    'modifica_sottotratto',
    ['4', '7', '10'],
    target: 'riflessi',
  ),
  'material_sparizione': _lineageTechnique(
    'Sparizione',
    'Dissolvi la sagoma nell’aura blu e diventa Invisibile',
    'stato',
    ['1', '1', '1'],
    target: 'invisibile',
  ),
  'material_velo_blu': _lineageTechnique(
    'Velo Blu',
    'Addensa una pellicola azzurra attorno al corpo',
    'scudo',
    ['6', '10', '16'],
  ),
  'material_scivolo': _lineageTechnique(
    'Scivolo',
    'Scivola oltre la portata dell’attacco',
    'velocita',
    ['3', '4', '6'],
  ),
  'material_mano_liquida': _lineageTechnique(
    'Mano Liquida',
    'Colpisci mentre la sagoma si ricompone accanto al bersaglio',
    'danno',
    ['4', '8', '12'],
  ),
  'material_rifrazione': _lineageTechnique(
    'Rifrazione',
    'Sfalsa il contorno per rinforzare la Difesa',
    'difesa',
    ['4', '7', '10'],
  ),
  'material_traiettoria_rotta': _lineageTechnique(
    'Traiettoria Rotta',
    'Punta una giuntura da un’angolazione inattesa',
    'modifica_sottotratto',
    ['2', '4', '6'],
    target: 'precisione',
  ),
  'material_scia_fredda': _lineageTechnique(
    'Scia Fredda',
    'Lascia un breve profilo azzurro che confonde la mira',
    'modifica_sottotratto',
    ['2', '3', '4'],
    target: 'riflessi',
    duration: '2',
  ),
  'material_ombra_compagna': _lineageTechnique(
    'Ombra Compagna',
    'Usa la tua aura per rendere Invisibile un alleato',
    'stato',
    ['1', '1', '1'],
    target: 'invisibile',
    recipient: 'alleato',
  ),
  'material_passo_inesistente': _lineageTechnique(
    'Passo Inesistente',
    'Sottraiti al colpo con Riflessi che migliorano con il livello',
    'modifica_sottotratto',
    ['2+livello/3', '3+livello/3', '4+livello/3'],
    target: 'riflessi',
    cooldown: 5,
  ),
  'material_eclissi_azzurra': _lineageTechnique(
    'Eclissi Azzurra',
    'Svanisci completamente nell’aura blu per due turni',
    'stato',
    ['1', '1', '1'],
    target: 'invisibile',
    duration: '2',
    level: 9,
    cooldown: 6,
  ),
  'material_assenza_profonda': _lineageTechnique(
    'Assenza Profonda',
    'Diventa Invisibile per tre turni',
    'stato',
    ['1', '1', '1'],
    target: 'invisibile',
    duration: '3',
    level: 15,
    cooldown: 7,
  ),
};

MonsterConcreteTechnique _lineageTechnique(
  String name,
  String action,
  String type,
  List<String> values, {
  String element = 'oculum',
  String target = '',
  String recipient = 'se_stesso',
  String duration = '1',
  String mode = 'finche_attivo',
  int level = 3,
  int cooldown = 2,
}) => MonsterConcreteTechnique(
  name: name,
  action: action,
  element: element,
  kind: type,
  requiredLevel: level,
  minimums: const [1, 2, 3],
  maximums: const [1, 2, 3],
  cooldownValues: [cooldown, cooldown + 1, cooldown + 2],
  forms: [
    for (final value in values)
      [
        MonsterTechniqueEffect(
          type,
          value,
          target: target,
          recipient: recipient,
          duration: duration,
          mode: type == 'danno' ? 'prossima_azione' : mode,
        ),
      ],
  ],
);
