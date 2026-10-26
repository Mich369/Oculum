part of 'monster_book.dart';

/// Affinities, not new calendar rules or forced seasonal spawn restrictions.
const oculumCycleMonsterPhaseNames = <String, String>{
  'safe_monster': 'Safe Monster',
  'illness': 'Illness',
  'little_breath': 'Little Breath',
  'piogge_fertilizzanti': 'Piogge Fertilizzanti',
  'the_sun': 'The Sun',
  'mezzo_ciclo': 'Mezzo Ciclo',
  'the_moon': 'The Moon',
  'the_fate': 'The Fate',
  'caldo_infernale': 'Caldo Infernale',
  'the_null': 'The Null',
  'ghiaccio_imponente': 'Ghiaccio Imponente',
  'ultimo_ciclo': 'Ultimo Ciclo',
};

String oculumMonsterCyclePhase(MonsterBookEntry monster) =>
    '${monster.encounterRules['cyclePhase'] ?? ''}';

String oculumMonsterCyclePhaseName(MonsterBookEntry monster) =>
    oculumCycleMonsterPhaseNames[oculumMonsterCyclePhase(monster)] ?? '';

typedef _CycleMove = ({String name, String action, String kind});

class _CycleSpecies {
  const _CycleSpecies(
    this.id,
    this.name,
    this.element,
    this.description,
    this.weakPoint,
    this.material,
    this.first,
    this.second,
    this.openName, {
    this.habitats = const ['mezzano', 'foresta_elementale'],
    this.stats = const [2, 2, 2, 2],
    this.level = 1,
    this.peaceful = false,
  });
  final String id, name, element, description, weakPoint, material, openName;
  final _CycleMove first, second;
  final List<String> habitats;
  final List<int> stats;
  final int level;
  final bool peaceful;
}

const _cycleSpecies = <String, List<_CycleSpecies>>{
  'safe_monster': [
    _CycleSpecies(
      'ciclo_lepre_guscio_quieto',
      'Lepre del Guscio Quieto',
      'natura',
      'Una lepre color salvia porta sul dorso un guscio sottile a forma di foglia, con orecchie corte e zampe coperte di trifogli. Durante Safe Monster raccoglie semi vicino ai sentieri e si lascia avvicinare senza aggredire. Quando ha paura ripara se stessa e si allontana; non possiede attacchi offensivi.',
      'La giuntura morbida tra il guscio e la spalla, visibile quando salta.',
      'scaglia_foglia_del_guscio_quieto',
      (
        name: 'Riparo dei trifogli',
        action:
            'Le foglie del guscio si sovrappongono e creano uno Scudo normale.',
        kind: 'scudo',
      ),
      (
        name: 'Passo senza allarme',
        action:
            'Si abbassa tra l’erba e prepara uno spostamento breve senza colpire.',
        kind: 'movimento',
      ),
      'La radura trattiene il fiato',
      peaceful: true,
    ),
    _CycleSpecies(
      'ciclo_cervo_radure_miti',
      'Cervo delle Radure Miti',
      'cura',
      'Un cervo basso dal mantello grigio miele ha palchi ricurvi coperti di muschio chiaro e nastri vegetali. Si raduna con creature di specie diverse senza contendersi il pascolo. Offre la rugiada raccolta sui palchi a un alleato ferito e protegge chi si ripara vicino a lui; è pacifico e non ha tecniche offensive.',
      'La base dei palchi, priva di muschio protettivo.',
      'muschio_del_cervo_mite',
      (
        name: 'Rugiada quieta',
        action:
            'Lascia cadere rugiada dai palchi su un alleato scelto e ne cura la Vita entro il massimo.',
        kind: 'cura',
      ),
      (
        name: 'Corna intrecciate',
        action: 'Abbassa i palchi e irrigidisce la guardia per un turno.',
        kind: 'difesa',
      ),
      'Cerchio del pascolo',
      peaceful: true,
      stats: [4, 3, 3, 3],
      level: 3,
    ),
  ],
  'illness': [
    _CycleSpecies(
      'ciclo_falena_delirio',
      'Falena del Delirio',
      'psichico',
      'Una falena grande come una mano mostra ali color gesso attraversate da nervature viola e piccoli occhi asimmetrici disegnati sulle scaglie. In Illness esce dalle crepe dei muri seguendo sussurri che gli altri non sentono. Le antenne vibrano prima della sua scarica psichica; il pulviscolo che la circonda nasconde la direzione del volo.',
      'Le due antenne nude, esposte mentre accumula il pulviscolo.',
      'scaglie_della_falena_delirio',
      (
        name: 'Polvere dei pensieri',
        action:
            'Scuote le ali e concentra una scarica psichica in un solo attacco.',
        kind: 'danno',
      ),
      (
        name: 'Velo di febbre',
        action:
            'Avvolge il proprio corpo in un pulviscolo che aumenta Velo per un turno.',
        kind: 'velo',
      ),
      'Il sussurro prende forma',
    ),
    _CycleSpecies(
      'ciclo_scrutatore_febbri',
      'Scrutatore delle Febbri',
      'psichico',
      'Una creatura allungata cammina su quattro dita uncinate, con pelle traslucida color malva e una testa incassata fra due spalle ossute. Un occhio lattiginoso si apre verticalmente sulla fronte. Compare ai margini delle strade durante Illness e osserva a lungo chi trema, poi inclina la testa per emettere un impulso psichico. Le pieghe del collo vibrano come una gola di vetro.',
      'La piega trasparente sotto l’occhio verticale.',
      'membrana_dello_scrutatore_febbrile',
      (
        name: 'Sguardo febbrile',
        action: 'Fissa un bersaglio ed emette un unico impulso psichico.',
        kind: 'danno',
      ),
      (
        name: 'Pieghe tremule',
        action:
            'Le pieghe del collo si gonfiano e aumentano la Difesa per un turno.',
        kind: 'difesa',
      ),
      'Veglia senza sonno',
      habitats: ['mezzano', 'oblio'],
      stats: [4, 5, 3, 4],
      level: 4,
    ),
  ],
  'little_breath': [
    _CycleSpecies(
      'ciclo_rondine_respiro_lieve',
      'Rondine del Respiro Lieve',
      'vento',
      'Una piccola rondine indaco ha penne della coda lunghe e cave, simili a sottili canne d’argento. In Little Breath nidifica sotto archi abbandonati e accompagna le correnti più deboli senza provocare tempeste. Il suo richiamo distende il respiro di un alleato ferito; quando viene minacciata scivola lateralmente nell’aria.',
      'Le penne cave della coda, fragili alla base.',
      'penna_cava_del_respiro_lieve',
      (
        name: 'Soffio rasserenante',
        action:
            'Dirige un soffio leggero verso un alleato scelto e ne cura la Vita entro il massimo.',
        kind: 'cura',
      ),
      (
        name: 'Virata silenziosa',
        action:
            'Sfrutta una corrente breve per aumentare Movimento per un turno.',
        kind: 'movimento',
      ),
      'Un solo respiro',
      peaceful: true,
      habitats: ['mezzano', 'isole'],
    ),
    _CycleSpecies(
      'ciclo_custode_nastri_sospesi',
      'Custode dei Nastri Sospesi',
      'vento',
      'Un quadrupede dalle zampe sottili porta un collare naturale di corteccia e lunghi nastri azzurri che galleggiano senza vento. Il muso ricorda quello di una capra, ma due piccole corna trasparenti crescono verso il basso. In Little Breath intreccia nastri fra gli alberi, preparando ripari leggeri per le creature stanche.',
      'Il nodo di corteccia al centro del collare.',
      'nastro_del_custode_sospeso',
      (
        name: 'Intreccio dei ripari',
        action: 'Tende i nastri attorno al corpo e ottiene uno Scudo normale.',
        kind: 'scudo',
      ),
      (
        name: 'Nodo del primo passo',
        action:
            'Un nastro indica il passaggio libero e aumenta Iniziativa per un turno.',
        kind: 'iniziativa',
      ),
      'Riparo del vento mite',
      peaceful: true,
      stats: [3, 4, 4, 3],
      level: 3,
    ),
  ],
  'piogge_fertilizzanti': [
    _CycleSpecies(
      'ciclo_porcello_fango_grasso',
      'Porcello del Fango Grasso',
      'terra',
      'Un piccolo suide dal pelo rado e marrone porta sul dorso zolle di fango verdastro, attraversate da radichette pallide. Il grugno largo espelle bolle dense e le zanne corte raschiano le gronde. Durante le Piogge Fertilizzanti cerca pozze appena formate e difende con urti il cibo nascosto nel fango. Il suo rivestimento si indurisce quando viene minacciato.',
      'La pelle chiara sotto il grugno, non coperta dalle zolle.',
      'zolla_del_porcello_fangoso',
      (
        name: 'Urto della pozza',
        action:
            'Carica da una pozza e concentra la spinta in un colpo di Terra.',
        kind: 'danno',
      ),
      (
        name: 'Crosta del temporale',
        action: 'Il fango si compatta sul dorso e forma uno Scudo normale.',
        kind: 'scudo',
      ),
      'La pozza si solleva',
    ),
    _CycleSpecies(
      'ciclo_rospo_gronde_marce',
      'Rospo delle Gronde Marce',
      'veleno',
      'Un rospo verde petrolio ha sacche gonfie sotto la gola e placche di argilla lungo le cosce. Si appende alle gronde con dita a ventosa e inghiotte il fango della pioggia prima di riversarlo sui passanti. Le sacche diventano gialle prima dello sputo; mentre attende comprime il corpo sotto una copertura viscida.',
      'Le sacche della gola mentre si tendono prima dello sputo.',
      'argilla_delle_gronde_marce',
      (
        name: 'Sputo delle gronde',
        action: 'Rilascia un solo getto velenoso contro il bersaglio scelto.',
        kind: 'danno',
      ),
      (
        name: 'Mantello vischioso',
        action:
            'Stende il rivestimento sulle sacche e aumenta Difesa per un turno.',
        kind: 'difesa',
      ),
      'Gronde traboccanti',
      stats: [4, 3, 5, 3],
      level: 4,
    ),
  ],
  'the_sun': [
    _CycleSpecies(
      'ciclo_scarabeo_sigillo_ardente',
      'Scarabeo del Sigillo Ardente',
      'solare',
      'Uno scarabeo nero lucido reca sulle elitre un sigillo a occhio d’oro arancio, con pupilla scura e raggi incisi. Le zampe anteriori terminano in piccoli uncini roventi. Nei sei giorni di The Sun lascia i sotterranei e pattuglia pietre esposte, incidendo segni solari. È aggressivo e protegge il sigillo chiudendo le elitre.',
      'La sutura nera fra le due elitre incise.',
      'elitra_del_sigillo_ardente',
      (
        name: 'Uncino del mezzogiorno',
        action: 'Concentra calore solare negli uncini per un singolo attacco.',
        kind: 'danno',
      ),
      (
        name: 'Elitre del sigillo',
        action: 'Chiude le elitre e ottiene uno Scudo normale.',
        kind: 'scudo',
      ),
      'Sigillo allo zenit',
      habitats: ['sacro', 'mezzano'],
    ),
    _CycleSpecies(
      'ciclo_araldo_sei_albe',
      'Araldo delle Sei Albe',
      'solare',
      'Un uccello alto e scheletrico porta sei placche dorate a ventaglio dietro il cranio, un becco nero e piume color cenere calda. Fra le placche ruota un disco inciso a occhio. Durante The Sun si posa sui tetti alti e scaccia le creature lunari con un raggio concentrato. Non è un angelo: il suo piumaggio è bruciato e la sua presenza ostile.',
      'Il perno scuro dietro il disco, scoperto quando apre il ventaglio.',
      'placca_delle_sei_albe',
      (
        name: 'Raggio delle sei placche',
        action: 'Allinea il ventaglio e scaglia un unico raggio Solare.',
        kind: 'danno',
      ),
      (
        name: 'Ventaglio rovente',
        action: 'Inclina le placche per aumentare Difesa per un turno.',
        kind: 'difesa',
      ),
      'La sesta alba',
      habitats: ['sacro', 'angelico'],
      stats: [4, 5, 4, 5],
      level: 5,
    ),
  ],
  'mezzo_ciclo': [
    _CycleSpecies(
      'ciclo_airone_guado_quieto',
      'Airone del Guado Quieto',
      'acqua',
      'Un airone color ardesia ha lunghe zampe color rame, un becco a spatola e piccole piume azzurre sotto il mento. Con il ritorno delle piogge naturali cerca guadi poco profondi e ripulisce il fondo dagli insetti. Difende il proprio nido con un solo affondo e poi si sposta tra le pietre, senza alterare il corso dell’acqua.',
      'La parte sottile del collo sotto le piume del mento.',
      'piuma_del_guado_quieto',
      (
        name: 'Affondo del guado',
        action: 'Raccoglie l’acqua sul becco e la concentra in un affondo.',
        kind: 'danno',
      ),
      (
        name: 'Passo fra le pietre',
        action:
            'Si muove lungo i sassi asciutti e aumenta Movimento per un turno.',
        kind: 'movimento',
      ),
      'Il guado ritrovato',
      peaceful: true,
      habitats: ['mezzano', 'affogato'],
    ),
    _CycleSpecies(
      'ciclo_tartaruga_pioggia_chiara',
      'Tartaruga della Pioggia Chiara',
      'acqua',
      'Una tartaruga dal carapace largo porta piccole cavità di quarzo che raccolgono pioggia limpida. Il collo verde oliva termina in un muso piatto e le zampe sono palmate. Attraversa lentamente prati e rive durante Mezzo Ciclo, lasciando bere le creature minute dalle cavità del guscio. Si ritrae per proteggersi e può versare acqua curativa su un alleato.',
      'La membrana alla base del collo quando lo estende.',
      'quarzo_della_pioggia_chiara',
      (
        name: 'Guscio delle cisterne',
        action: 'Si ritrae nel carapace e ottiene uno Scudo normale.',
        kind: 'scudo',
      ),
      (
        name: 'Acqua delle cavità',
        action:
            'Versa acqua da una cavità del guscio e cura un alleato entro la Vita massima.',
        kind: 'cura',
      ),
      'Riparo della pioggia chiara',
      peaceful: true,
      habitats: ['mezzano', 'affogato'],
      stats: [5, 3, 4, 3],
      level: 3,
    ),
  ],
  'the_moon': [
    _CycleSpecies(
      'ciclo_cerbiatto_voti_lunari',
      'Cerbiatto dei Voti Lunari',
      'lunare',
      'Un cerbiatto dal pelo blu fumo porta un piccolo pendaglio a falce fra le corna, legato con fili color avorio. Il simbolo è una reliquia della Luna scomparsa, non un astro nel cielo. Nei giorni di The Moon cammina fra accampamenti di razze diverse e lascia avvicinare i feriti. Una luce fredda segue i fili quando prepara un riparo o offre una cura.',
      'Il nodo dei fili sotto il pendaglio, visibile quando china il capo.',
      'filo_dei_voti_lunari',
      (
        name: 'Riparo del voto',
        action:
            'Tende i fili della reliquia attorno al corpo e ottiene uno Scudo normale.',
        kind: 'scudo',
      ),
      (
        name: 'Dono della veglia',
        action:
            'Condivide una luce fredda con un alleato e ne cura la Vita entro il massimo.',
        kind: 'cura',
      ),
      'Veglia delle razze accolte',
      peaceful: true,
    ),
    _CycleSpecies(
      'ciclo_gufo_stelle_alleate',
      'Gufo delle Stelle Alleate',
      'stella',
      'Un gufo grande dalle piume indaco e argento ha due ciuffi ricurvi e piccole macchie stellari sul petto. Sulla zampa porta un anello inciso con una falce commemorativa. Sorveglia le celebrazioni di The Moon sotto un cielo di sole stelle e interviene contro chi aggredisce gli ospiti. I suoi occhi color ghiaccio seguono i movimenti fra i rami.',
      'L’anello di piume corte sotto il becco.',
      'piuma_delle_stelle_alleate',
      (
        name: 'Artiglio della stella vigile',
        action: 'Un bagliore stellare segue gli artigli in un singolo attacco.',
        kind: 'danno',
      ),
      (
        name: 'Occhi della veglia',
        action: 'Apre il disco facciale e aumenta Percezione per un turno.',
        kind: 'percezione',
      ),
      'Le stelle restano alleate',
      peaceful: true,
      stats: [3, 4, 5, 4],
      level: 4,
    ),
  ],
  'the_fate': [
    _CycleSpecies(
      'ciclo_ragno_fili_giurati',
      'Ragno dei Fili Giurati',
      'magia',
      'Un ragno color avorio cammina su otto zampe sottili, ciascuna segnata da un anello dorato. Fili tesi fra due piccoli rocchetti naturali sul dorso tintinnano quando una preda attraversa la tela. Durante The Fate intreccia nodi simili a sigilli vicino ai crocevia. La sua magia tende i fili e rinforza il corpo, lasciando piccoli nodi luminosi sui rami.',
      'I due rocchetti molli sul dorso, esposti fra i fili.',
      'filo_del_giuramento_aracnide',
      (
        name: 'Filo del giuramento',
        action: 'Tende un filo inciso e concentra Magia in un solo attacco.',
        kind: 'danno',
      ),
      (
        name: 'Nodo del bastione',
        action:
            'Intreccia i fili attorno al corpo e ottiene uno Scudo normale.',
        kind: 'scudo',
      ),
      'Il nodo non si spezza',
    ),
    _CycleSpecies(
      'ciclo_cavaliere_filo_oro',
      'Cavaliere del Filo d’Oro',
      'magia',
      'Un costrutto cavo di piastre color piombo tiene una lama corta con fili dorati tesi fra guardia, gomito e spalla. Il volto è una visiera liscia attraversata da una sola cucitura luminosa. Durante The Fate custodisce promesse incise su placche ai bordi delle strade. I fili guidano il fendente e serrano le piastre in difesa.',
      'Il nodo che collega il filo della spalla alla guardia della lama.',
      'placca_del_cavaliere_giurato',
      (
        name: 'Fendente del filo teso',
        action: 'Il filo guida un solo fendente carico di Magia.',
        kind: 'danno',
      ),
      (
        name: 'Guardia della promessa',
        action:
            'Serra le piastre attraverso il filo e aumenta Difesa per un turno.',
        kind: 'difesa',
      ),
      'La promessa regge',
      stats: [5, 5, 4, 4],
      level: 5,
    ),
  ],
  'caldo_infernale': [
    _CycleSpecies(
      'ciclo_scorpione_cisterne_secche',
      'Scorpione delle Cisterne Secche',
      'veleno',
      'Uno scorpione di sabbia rossastra ha chele piatte e un addome ricoperto di placche opache simili a cocci. Conserva una piccola riserva liquida nella coda e si nasconde nelle cisterne prosciugate durante il Caldo Infernale. Attende all’ombra e punge chi cerca acqua, poi abbassa le chele per coprire il ventre.',
      'La sacca chiara sotto l’ultimo segmento della coda.',
      'placca_della_cisterna_secca',
      (
        name: 'Puntura della sete',
        action: 'Usa la riserva della coda per un singolo attacco Veleno.',
        kind: 'danno',
      ),
      (
        name: 'Chele parasole',
        action: 'Copre il ventre con le chele e aumenta Difesa per un turno.',
        kind: 'difesa',
      ),
      'L’ultima goccia',
      habitats: ['mezzano', 'demoniaco'],
    ),
    _CycleSpecies(
      'ciclo_mantide_vampa',
      'Mantide della Vampa',
      'fuoco',
      'Una mantide alta color rame bruciato mostra lame anteriori dentellate, un addome sottile e ali corte attraversate da nervature rosse. Sul torace una crepa luminosa espelle aria rovente. Durante il Caldo Infernale caccia sui muri arroventati e percorre i bordi delle ombre, aprendo le ali per cambiare posizione dopo il colpo.',
      'La crepa del torace mentre espelle aria rovente.',
      'nervatura_della_mantide_vampa',
      (
        name: 'Falce della vampa',
        action: 'Il calore corre lungo le lame per un singolo attacco Fuoco.',
        kind: 'danno',
      ),
      (
        name: 'Scarto della fornace',
        action: 'Un getto d’aria dalle ali aumenta Movimento per un turno.',
        kind: 'movimento',
      ),
      'Vampa fra le ombre',
      habitats: ['mezzano', 'demoniaco'],
      stats: [4, 4, 6, 4],
      level: 5,
    ),
  ],
  'the_null': [
    _CycleSpecies(
      'ciclo_larva_nome_vuoto',
      'Larva del Nome Vuoto',
      'vuoto',
      'Una larva color porcellana ha tre coppie di piccole zampe e una cavità scura al posto del muso. Attorno al corpo scorrono segni incompleti che non formano parole. Durante The Null si annida vicino a pietre funerarie prive di iscrizione. La sua morsura lascia un impulso di Vuoto.',
      'L’anello morbido dietro la cavità del muso.',
      'scaglia_del_nome_vuoto',
      (
        name: 'Morso senza nome',
        action: 'La cavità del muso si chiude in un singolo attacco di Vuoto.',
        kind: 'danno',
      ),
      (
        name: 'Pelle senza segni',
        action: 'Le scaglie si sovrappongono e aumentano Difesa per un turno.',
        kind: 'difesa',
      ),
      'La cavità rimane',
      habitats: ['oblio', 'morti'],
    ),
    _CycleSpecies(
      'ciclo_viandante_ricordi_spenti',
      'Viandante dei Ricordi Spenti',
      'oblio',
      'Una figura curva indossa un mantello di strisce grigie cucite attorno a un corpo di corteccia cava. Porta al collo piccole targhe lisce e cammina con un bastone privo di ombra. Appare durante The Null lungo sentieri abbandonati e raccoglie oggetti senza riconoscerli. È Senza Fato; le sue tecniche concentrano Oblio e velano il proprio corpo; il mantello lascia una scia di cenere priva di impronte.',
      'La cavità fra le targhe e il petto di corteccia.',
      'targa_dei_ricordi_spenti',
      (
        name: 'Colpo del sentiero vuoto',
        action: 'Concentra Oblio nel bastone per un singolo colpo.',
        kind: 'danno',
      ),
      (
        name: 'Mantello dei nomi assenti',
        action:
            'Le strisce del mantello si confondono e aumentano Velo per un turno.',
        kind: 'velo',
      ),
      'Il sentiero senza nome',
      habitats: ['oblio', 'morti'],
      stats: [4, 5, 4, 4],
      level: 4,
    ),
  ],
  'ghiaccio_imponente': [
    _CycleSpecies(
      'ciclo_lepre_fiato_vetro',
      'Lepre del Fiato di Vetro',
      'gelo',
      'Una lepre dal pelo bianco azzurro ha orecchie traslucide e piccoli baffi rigidi come vetro. Il suo fiato si condensa in aghi corti senza ricoprire tutta l’area. In Ghiaccio Imponente cerca cavità fra le radici e si difende dai predatori con un breve getto di Gelo, poi fugge su zampe larghe e pelose.',
      'La base rosata delle orecchie traslucide.',
      'baffo_del_fiato_di_vetro',
      (
        name: 'Fiato delle schegge',
        action: 'Concentra gli aghi del respiro in un singolo attacco Gelo.',
        kind: 'danno',
      ),
      (
        name: 'Balzo sulla crosta',
        action:
            'Distribuisce il peso sulla neve e aumenta Movimento per un turno.',
        kind: 'movimento',
      ),
      'Respiro sotto la brina',
      peaceful: true,
      habitats: ['ghiaccio', 'mezzano'],
    ),
    _CycleSpecies(
      'ciclo_golem_brina_profonda',
      'Golem della Brina Profonda',
      'gelo',
      'Un golem basso e massiccio è formato da strati di roccia gelata e ghiaccio opaco, con braccia larghe e un nucleo incassato color indaco. Tracce di stoffa congelata pendono dalle spalle. Durante Ghiaccio Imponente protegge le cavità più fredde e rimuove gli intrusi con un pugno pesante, accumulando brina sul corpo prima di difendersi.',
      'La fessura del nucleo sotto il ghiaccio del petto.',
      'strato_della_brina_profonda',
      (
        name: 'Pugno della brina profonda',
        action: 'Raccoglie il peso del ghiaccio in un singolo attacco Gelo.',
        kind: 'danno',
      ),
      (
        name: 'Strati del silenzio',
        action: 'Sovrappone ghiaccio compatto e ottiene uno Scudo normale.',
        kind: 'scudo',
      ),
      'Il freddo custodito',
      habitats: ['ghiaccio', 'sotterraneo'],
      stats: [6, 3, 5, 4],
      level: 5,
    ),
  ],
  'ultimo_ciclo': [
    _CycleSpecies(
      'ciclo_volpe_lanterne_spente',
      'Volpe delle Lanterne Spente',
      'sonoro',
      'Una volpe color prugna porta ciuffi d’avorio sulle orecchie e una coda lunga segnata da piccoli nodi di pelo dorato. Raccoglie involucri di lanterne già spente dopo i festeggiamenti di Ultimo Ciclo e li allinea all’ingresso della tana. Il loro fruscio accompagna il suo passo; fugge senza aggredire e ripara il corpo con una vibrazione leggera.',
      'La punta chiara del muso sotto i baffi.',
      'nodo_della_volpe_lanterna',
      (
        name: 'Passo dei festeggiamenti',
        action:
            'Segue il fruscio delle lanterne e aumenta Movimento per un turno.',
        kind: 'movimento',
      ),
      (
        name: 'Riparo dei nastri usati',
        action:
            'Una vibrazione dispone i nastri attorno al corpo e crea uno Scudo normale.',
        kind: 'scudo',
      ),
      'L’ultima lanterna',
      peaceful: true,
    ),
    _CycleSpecies(
      'ciclo_guardiano_dodici_rintocchi',
      'Guardiano dei Dodici Rintocchi',
      'sonoro',
      'Un quadrupede di ceramica scura e legno reca dodici piccole campane lungo la schiena, zampe a zoccolo e un volto liscio inciso con cerchi concentrici. Si ferma alle porte dei villaggi durante Ultimo Ciclo e accompagna i cortei con rintocchi bassi. Difende i passaggi dagli aggressori con rintocchi che fanno vibrare i ciottoli.',
      'Il perno di legno sotto la campana centrale.',
      'campanella_dei_dodici_rintocchi',
      (
        name: 'Rintocco del corteo',
        action: 'Allinea il suono delle campane in un unico attacco Sonoro.',
        kind: 'danno',
      ),
      (
        name: 'Guardia delle campane',
        action:
            'Le campane vibrano attorno al corpo e aumentano Difesa per un turno.',
        kind: 'difesa',
      ),
      'Il ciclo viene ricordato',
      peaceful: true,
      stats: [5, 4, 3, 4],
      level: 4,
    ),
  ],
};

final List<MonsterBookEntry> oculumCycleMonsterEntries = List.unmodifiable([
  ..._suggestedCycleEntries,
  for (final phase in _cycleSpecies.entries)
    for (final spec in phase.value)
      _canonicalCreature(
        spec.id,
        spec.name,
        '',
        spec.habitats,
        spec.element,
        spec.stats,
        spec.level,
        '${spec.description} Affinità del ciclo: ${oculumCycleMonsterPhaseNames[phase.key]}.',
        spec.weakPoint,
        ['${spec.id}_prima', '${spec.id}_seconda'],
        spec.material,
        peaceful: spec.peaceful,
      ).copyWith(
        isNullFateless: phase.key == 'the_null',
        classificationTags: [
          'Creatura del ciclo',
          'Fase: ${oculumCycleMonsterPhaseNames[phase.key]}',
        ],
        encounterRules: {
          'authoredCanonical': true,
          'cyclePhase': phase.key,
          'cycleScrollNaturalMinimum': 18,
          'cycleOpenName': spec.openName,
          'cycleOpenKind':
              spec.first.kind == 'cura' ||
                  phase.key == 'safe_monster' ||
                  phase.key == 'little_breath' ||
                  spec.id == 'ciclo_cerbiatto_voti_lunari'
              ? 'cura'
              : spec.first.kind == 'danno'
              ? 'danno'
              : 'scudo',
          'dispositions': spec.peaceful ? ['pacifico', 'neutrale'] : ['ostile'],
        },
      ),
]);

MonsterConcreteTechnique _cycleTechnique(
  _CycleSpecies owner,
  _CycleMove move,
) => _planarMove(
  move.name,
  move.action,
  owner.element,
  const {'movimento', 'velo', 'percezione', 'iniziativa'}.contains(move.kind)
      ? 'movimento'
      : move.kind,
  [
    for (var form = 0; form < 3; form++)
      [
        switch (move.kind) {
          'danno' => MonsterTechniqueEffect(
            'danno',
            '${4 + form * 5}',
            mode: 'prossima_azione',
            duration: '',
          ),
          'scudo' => MonsterTechniqueEffect(
            'scudo',
            '${8 + form * 7}',
            mode: 'immediato',
            duration: '',
          ),
          'cura' => MonsterTechniqueEffect(
            'cura',
            '${5 + form * 5}',
            mode: 'immediato',
            duration: '',
            recipient: 'alleato',
          ),
          'difesa' => MonsterTechniqueEffect(
            'difesa',
            '${3 + form * 2}',
            duration: '1',
          ),
          _ => MonsterTechniqueEffect(
            'modifica_sottotratto',
            '${2 + form * 2}',
            target: move.kind,
            duration: '1',
          ),
        },
      ],
  ],
  level: owner.level,
  minimums: const [1, 2, 3],
  maximums: const [1, 2, 3],
  cd: move.kind == 'cura' ? const [3, 3, 4] : const [2, 2, 3],
);

final _cycleMonsterTechniques = <String, MonsterConcreteTechnique>{
  ..._suggestedCycleTechniques,
  for (final species in _cycleSpecies.values)
    for (final spec in species) ...{
      '${spec.id}_prima': _cycleTechnique(spec, spec.first),
      '${spec.id}_seconda': _cycleTechnique(spec, spec.second),
    },
};
