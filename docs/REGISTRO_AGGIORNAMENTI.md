# Registro cumulativo per i giocatori

## Patch del 31 ottobre — parser, Senka e Oblivion Shield

- Danno/Cura: `25%` usa la Vita attuale, `25%Tot` la massima. Restano Difesa, resistenze, Scudi, Oltre Difesa/Oltre Scudi e gli importi automatici delle Skill.
- Costi leggibili con minimo/massimo; effetti secondari su critico e Danni alla Vita modificabili negli editor comuni di Skill, Art, Titoli e Open. Corrette anteprime Bonus/Malus e collocazione degli effetti offensivi. Le note descrittive non allungano più le formule oltre il punto di frase, senza nascondere errori matematici o perdere decimali.
- Oblivion Shield è il nuovo nome del Famelico, con ID compatibile. Fiammata del non ricordo: critico che danneggia la Vita, resistenza Memoria(+Fortuna per il Fato), perdita della prima A/R/RV tentata e log «cosa stavo facendo?». Restano Scudi critici e contrasto vincente; l'effetto viene preparato prima del colpo e non si duplica con la consegna dei messaggi.
- Nuovo codice Senka:100EXP già presenti, un Vitalium Ridefinito, coltellino+3Tagliente equipaggiato e maschera non equipaggiata. Bonus nei campi corretti, senza doppioni nelle note; salvataggi e personalizzazioni conservati.
- Anatomie approvate allineate: niente arti o code duplicati nella Bestia delle Nuvole, Saltalungo, Oblivion e Forest Demon. Gli override del Master conservano la precedenza.
- Lupo Infernale del Ghiaccio ora glaciale delle zone ghiacciate dell'Inferno: morso/carica Ghiaccio, resistenza Ghiaccio e materiale coerente. Identificativi precedenti, valori e limiti restano compatibili. I nuovi artwork ancora da scegliere non sono dichiarati integrati dalla sola generazione.

Costi, effetti, forme, durata, bersagli, tipi di danno, equipaggiamento, anatomie e temi restano modificabili. [Verifiche e limiti della patch](PATCH_2026-10-31_PARSER_OBLIVION.md).

## Patch del 30 ottobre — Nuvola, corazze e nuove varianti

- Nuovi temi scelti: Sciamano Malizioso con felci e maschera a rombo, Custode altissimo con campana conica, Mammuth compatto e Armadillo tondo. Sciamano dispone anche di telefono/reliquia approvati. Descrizioni e bersagli seguono i disegni, senza attribuire nuovi poteri; la campana non nasconde un volto e le zanne/proboscide del Mammuth sono distinte. Corretto il riconoscimento anatomico che confondeva«corso» con«orso» e«progress» con«ogre».

- Nuvola in bottiglia cambia fase solo se sopravvive. Il critico mirato rompe la bottiglia soltanto danneggiando la Vita; recuperi40/75% e bersaglio bottiglia rimosso nella seconda fase. La scarica Open cresce dal secondo bersaglio; Fulmine ferma Azione interrompe l'Azione in corso o consuma la prossima, preservando Reazioni e Reazioni veloci. Le nuove Art usano effetti e valori modificabili; le personalizzazioni salvate restano conservate.
- Costrutto Minore: prima si rompe la scatola, poi si può mirare il nucleo. I colpi alla scatola danneggiano corpo e integrità; Ultime forze non cancella più il danno strutturale appena ricevuto. Pacchetti vecchi non possono colpire un nucleo ancora nascosto.
- Quattro Armadilli — base, Sabbia, Cristallo e Legno — con appallottolamento tramite Azione o Reazione: +6/+9/+16CM nelle tre forme, rotolamento e speronamento consentiti. Regole, costi, anatomia, materiali e drop rimangono modificabili; gli attacchi già preparati non possono mirare parti ormai coperte.
- Mezzo Demone Massiccio come variante distinta: più Resilienza, meno Volontà/Materia/Oculum, a parità di totale base; non sostituisce la versione atletica. Pinepine mantiene la pigna integra con una squama più tenera, senza ferita preesistente.
- Nuovi pack approvati desktop/telefono/reliquia di Massiccio, Mastino della Cripta, Forest Demon e Forest Demon Blu. Anatomie allineate: comune quadrupede con corno frontale e due laterali; Blu quadrupede con due corna rosa. Gli altri sette pack approvati restano separati dalla futura integrazione delle specie. Corretto Pinepine: due braccia, due gambe e squama tenera mirabile, senza ferita iniziale; la fragilità elementale non lo rende incorporeo.

Verifiche locali sulla revisione:185test e analisi senza problemi; le precedenti113prove e gli altri conteggi sono in parte ripetuti, non sommabili. LaCIprecedente con tre fallimenti non è stata distribuita: nuovaCI, pacchetti e pubblicazione sono controlli distinti, documentati nella consegna quando completati.

## Patch successiva del 29 ottobre — sonno, bisogni e creature di sabbia

- Corretto il canale delle richieste online dei giocatori per riposi, viaggi e visite ai mercanti: conferme, tempo e recuperi restano autorizzati dal Master. La coda gratuita dei mostri di sabbia rispetta ora anche il blocco delle Skill durante Sfinimento.
- Dormire usa una durata scelta dal Master: minimo90minuti e, iniziando di Notte, almeno fino alla prima Mattina. Una dormita più lunga rigenera di più ma conta sempre un solo Riposo Lungo. Online la richiesta conserva le risorse fino alla conferma; le ricevute impediscono cure duplicate e il tempo condiviso resiste a snapshot ricevuti fuori ordine.
- Fame, sete e sonno avanzano con la campagna e hanno penalità distinte. Cibo, acqua e sonno rimuovono soltanto i rispettivi effetti. I Costrutti non biologici richiedono manutenzione/riposo ma sono esenti da cibo e acqua; il cambio di fisiologia ricalcola i valori automatici preservando le impostazioni esplicite. Fame e bonus notturni non creano punti risorsa permanenti dopo il recupero.
- Il Master può far passare ore e minuti della sola campagna. Nell'ultima mezz'ora della Notte il Sole risbuca scendendo dall'Oblio presso le Isole volanti e i bonus delle creature calano gradualmente fino a zero. Corruzione e calendario contano le Notti effettivamente trascorse, anche restando svegli; dormire di giorno non aggiunge una Notte.
- Mostro e Gigante di sabbia condividono attacco e parata gratuiti di coda, anche fuori turno, con recupero comune di due turni personali. La parata senza dado usa Resistenza come riferimento e riceve il65%dei Danni dopo Difesa e prima degli Scudi. Il Gigante non ha un punto debole anatomico: resta fragile al Fuoco. Un doppio critico valido di Lava che arriva alla Vita ha50%di vetrificarlo; se sopravvive, Materia dimezzata per tre turni, con rinnovo senza accumulo.
- Corretta la parata senza tiro delle Aberrazioni metalliche: il confronto contrapposto non annulla più il colpo prima della percentuale del mantello. Restano usura già sul colpo critico, Resistenza passiva, costi e protezioni degli Scudi.
- Tredici nuovi sfondi desktop e dieci coppie telefono/reliquia approvati: Funghetto Cappuccio Rosso, Costrutto Minore, Shadow Devil, Mostro e Gigante di sabbia, Mezzo Demone Cosciente, Nuvola in bottiglia, Il Doppione e le due Aberrazioni metalliche hanno un pack completo; Sharp, Topino Avventuroso e Mosca Campana ricevono il desktop approvato. Non attribuiscono nuovi poteri o drop.
- Parti colpibili riviste sui disegni confermati: numero di occhi/arti/ali, materiali e protezioni coerenti; elmi solari metallici e volti scoperti dei due fratelli distinti. Nuclei nascosti, cristalli e anatomie personalizzate mantengono le proprie eccezioni. Importazione dei runtime migliorata anche per mappe create internamente prima dell'esportazione JSON.


## Patch del 29 ottobre — combattimento, premi e viaggio

- Turnistica Master: menu del partecipante per ostilità e morte; mostri e NPC possono fuggire. Selezionare manualmente un partecipante conserva Azioni, Reazioni, Reazioni veloci e Movimento già consumati. Le richieste online di reset verificano anche la proprietà della scheda indicata.
- Nuova assegnazione dei premi, selezionabile: avviene alla conclusione dell'intero fight e considera soltanto gli ostili morti. Usa la media dei massimi PT raggiunti nei turni personali, escludendo equipaggiamenti ordinari e maschera di Senka; conserva separati ultimo colpo, aiuti, cure, difese, risorse spese e sottotratti usati. Ricevute persistenti impediscono premi duplicati; EXP e aumenti di livello entrano nel log, anche condiviso quando autorizzato.
- Obser all'uccisore dalla differenza PT positiva; un solo Cristallo di Ascension Dust nella cassa del party, della taglia più alta raggiunta fra piccolo, medio e grande. Non contano i nemici vivi o fuggiti; per il party contano PG, NPC e Occhi dei Caduti.
- Vita: moltiplicatori iniziali ridotti a ogni Grado, poi progressione ordinaria; alla PT si aggiunge il relativo bonus Vita. Movimento e Iniziativa si riducono sotto metà Vita e ulteriormente sotto il10%, senza applicare ripetutamente la stessa penalità. Corrette anche crescita di Pawn ed editor degli Occhi dei Caduti.
- Open: Buff oltre il singolo fight fino al recupero della propria Open; nuova Open sostituisce il Buff precedente, salvo l'eccezione Defiled Art. Recupero con due Riposi Lunghi oppure un Lungo e tre Brevi, due Brevi per gli alleati del Fato. Il potenziamento della Skill Open ha contatori indipendenti: tre fight oppure due Brevi e un Lungo. Le altre Skill Open restano utilizzabili.
- Guardiano Solare: Potere dell'oro, spadone, riflesso dei Danni ravvicinati e Muro d'oro/cupola con Concentrazione. Aggiunte Guardie Lunari, Elité Lunari, Guardiani Lunari, Guardie Infernali Ik, Elité Ik e Guardiani della Devil Moon, con tecniche, colori, resistenze e anatomie proprie. Il nucleo dei Guardiani Lunari resta nascosto fino alla rottura della corazza e al successivo grave colpo al petto.
- Parti colpibili: Precisione+3 apre la scelta della parte. Un colpo mirato danneggia parte e corpo; critico valido o integrità a zero provocano una lesione coerente col materiale. Restano prevalenti le regole speciali di cristalli, nuclei, corazze e maschera. Integrità, soglie, penalità e riparazioni sono modificabili e persistenti.
- Tempo della campagna: giornata di nove ore, turni da dieci secondi, Riposo Breve30minuti e Lungo90. Viaggio a piedi o con mezzo, distanza e Movimento medio del party; percentuale del mezzo modificabile. Eventi di viaggio nella coda privata del Master, con incontri, bauli/Mimic e mercanti. I mercanti concedono al massimo due Riposi Brevi per giornata Oculum, secondo visite valide distanziate di almeno15minuti reali, senza timer mostrati.
- Inventario riordinato con ricerca e categorie: il catalogo si carica soltanto aprendo Aggiungi oggetto. PT propria visibile tramite opzione separata per ogni scheda; il Master autorizzato vede le PT disponibili e il totale del party.
- Dieci pack di artwork collegati con sfondo desktop, telefono e reliquia: Pinepine, Bramble, Ogle, Pawn e le sei creature lunari/Ik. Aspetti approvati, centro leggibile e reliquie trasparenti; non introducono nuovi bonus o ritratti nel Monster Book. Gli altri artwork restano censiti nel registro dedicato.
- Codici aggiornati di Senka, Lusier III ed Erik I. Con il nuovo bonus Vita alla PT, Lusier misura301 ed Erik131; Senka parte con81 Vita e raggiunge135 con la maschera, inizialmente non indossata. Costi leggibili, requisiti, effetti e riserve restano nei rispettivi campi modificabili.

Le sezioni precedenti conservano la cronologia: queste regole sostituiscono i vecchi valori nello stesso ambito. La pubblicazione e le verifiche si riferiscono al commit effettivamente compilato; l'inventario degli artwork mancanti non equivale a contenuti già distribuiti.

## Patch del 28 ottobre — fuga, aggiornamento e Guardiano Solare

- Aggiornamento Windows: tentativi separati, avanzamento download/verifica/installazione, controllo integrità in background e diagnostica persistente. Il successo richiede conferma di avvio della nuova versione; backup e ripristino preservano i file precedenti.
- Installazione locale: correzione dello spostamento parziale delle cartelle bloccate; le verifiche distinguono app precedente ancora aperta, pacchetto scaricato e nuova versione effettivamente avviata.
- Salvataggi prima dell’aggiornamento: controllo dell’ultima scrittura e rilettura verificata, ripetuto dopo il download. Un vecchio backup valido non basta se il nuovo salvataggio fallisce; l’app resta aperta senza avviare l’installer. Guida di installazione raggiungibile dai download pubblici e dal menu web.
- Fuga: «Blocca» e «Aiuta» usano il fight della scheda anche se ne era selezionato un altro. Il colpo gratuito d’intercettazione conserva come bersaglio chi sta fuggendo. Richieste scadute non consumano risorse e le Reazioni non avanzano il turno.
- Gli attacchi contro chi fugge usano1d16 per colpire; il tiro di blocco e gli attacchi ordinari conservano1d20.
- Guardiano Solare: sfondo illustrato dedicato per desktop e telefono, reliquia coerente con elmo del colosso, arco e due frecce d’oro; controllata la corda dell’arco. Nessun ritratto imposto nel Monster Book e nessuna modifica alle statistiche.
- Guardiano Solare, nuova Skill Mazza d’oro: Danni×1,2 per1d3 turni nella Forma I, ×1,3 per1d3+2 nella II, ×1,5 per1d3+3 nella III. Costi2/4/6Oculum e cooldown4/6/8turni personali, modificabili; durata e bonus persistono nel salvataggio.

## Patch del 28 ottobre — sessioni, personaggi e sblocchi

- Combattimento: corretti il mantenimento di Reazioni/RV nei fight uniti, lo stato a fight concluso e i permessi del Co-Master. Gli esiti di intangibilità non applicano più Danni o consumo degli Scudi e vengono mantenuti nelle conferme online; gli attacchi capaci di colpire immateriali restano validi.
- Senka: corretto anche il Mantello d’ombra copiato dai cloni, che funziona senza la maschera dell’originale e conserva durata e limiti. Costi leggibili e reali, maschera inizialmente non indossata, riattivazione dopo il critico valido, Passo nell’Ombra con confronto e Reazione veloce, Mille Tagli come unico pacchetto e Sfinimento a lei. Fusione richiede Velo permanente13; Mille Tagli Riflessi permanenti9 e Erik I, senza livello minimo. Erik vale anche se più debole.
- Ricordo della Luna: sblocco dal progresso personale; Open e Buff insieme, +30% sulle statistiche effettive di Senka e +5% ai Lunari nel fight. Tagli lunari disponibili dopo lo sblocco anche a Open spenta, con un unico tiro e distribuzione dei tagli; potenziamento soltanto della propria Open. I bonus personali terminano a fine fight senza restituire l’uso della Open.
- Lusier III: Titolo Io, Padrone del Io, raggi, protezione e Vitalium Solare; cura65% della Vita attuale +10% della massima, entro il massimo, senza eliminare riserve preesistenti. PT misurata298. Erik I: scheda personale Elité Lv8 Grado0, depotenziata a PT130 come eccezione confermata, con Custodia del Girone ridotta; la Guardia Elité generica conserva la propria crescita. Equipaggiamenti e tecniche conservano i propri campi modificabili.
- Scostubanditi: rapina solo a fine fight vittorioso sugli sconfitti rimasti, Errato75% e Veterano100% con uccisione; Titoli Item esclusi. Aura5%/15% e coordinazione+2 non cumulativa, sincronizzata anche con difesa remota. Una vittima curata può rientrare nel fight.
- Sblocchi permanenti da statistiche e sottotratti senza buff temporanei; progressi personali su specie, elementi, critici e obiettivi nominali. Un nemico fino a25 PT sotto il partecipante conta, da26 sotto non conta; esclusi evocati e duplicati. Raccogli, Possiedi e Consuma restano distinti.
- Libri: consumo alla lettura, ricette condivise e conservate sulle schede alleate locali anche non attive; preferiti bloccati non rivelano ingredienti. Il Master conserva la vista completa.
- Occhi dei Caduti: conservati sottotratti e statistiche della creatura viva; le Skill ereditate dalle Art hanno forme, costi, cooldown ed effetti utilizzabili. Preservati limiti della rarità e personalizzazioni già salvate.
- Temi: nuovo scenario personale di Senka nei gironi poveri di Lost Town, Haniel aggiornato e Sky nella stanza; reliquie delle Guardie Solari approvate e sfondo sotterraneo Grofix. Cornice personale di Senka con centro libero e asset separati per telefono dove previsti. Inventario dei temi mancanti separato dalle aggiunte effettive.

## Versione stabile del 27 ottobre — schede, costi e personaggi

- Attacco nella barra del fight: bersagli e tiro seguono il fight della scheda, anche quando il Master ne ha selezionato un altro o ci sono fight condivisi. Corretto il riconoscimento del partecipante con maiuscole/spazi diversi nei tag. Senza bersagli validi compare un avviso e non si consumano Azioni o Reazioni; il tiro non ripiega silenziosamente su un dado generico senza bersaglio.

- Firma Android: il repository include l'impronta pubblica del certificato stabile per permettere il controllo della firma anche su GitHub; la chiave privata non cambia e rimane separata dal codice.

- Corretta la duplicazione delle tecniche aggiuntive della Larva. I costi in Obser o statistiche non richiedono anche Oculum per apparire fra le mosse disponibili; la risorsa Follia viene riconosciuta nei costi strutturati. Conservati i costi dopo il salvataggio e la Maestria nelle descrizioni aggiornate. Scroll delle tecniche di crescita collegate alla tecnica naturale corretta, comprese le Reazioni veloci; gli Occhi dei Caduti mantengono distinte le tecniche prive di nome.

- Il Master può assegnare una o più proprie schede a un giocatore. Selezione iniziale vuota; salvataggio locale del destinatario prima della conferma e copia online per il Master, senza cambiare il tag della scheda né duplicare consegne già ricevute. Immagini, personalizzazioni e ricevute dei premi restano conservate.
- Pagina Master riordinata per categorie e ricerca, con disposizione adatta a telefono e desktop. Costi Skill con risorse e limiti generici, parser PT e Sfinimento proporzionale; formule e costi restano modificabili.
- Senka Kamaria organizzata con storia, incubo, Sky, Haniel, Titoli Un Ricordo della Luna e Vendetta, maschera indossabile e poteri iniziali. Riserve della trasformazione, Scudo Oculum, clone personale, limite totale per fight e fusione conservati nel JSON. Le evoluzioni future dichiarate in lavorazione non sono certificate dal solo testo della scheda.
- Lusier III: Guardia Solare Élite livello13, Grado I, 1 Scudo critico e150 Scudo Oculum; abito protettivo, spada sacra +20 Danni Solari, Vitalium Ridefinito e mazzo personale. La PT effettiva misurata è277 e alimenta la frase di Haniel nella storia di Senka.
- Carte esplosive di Grado I: forme ai livelli10/12/20, capienze5/10/15, recupero1/2/3 per turno; massimo5 carte per lancio, ciascuna1d25 + un quinto per difetto dei Danni attuali. Lusier mantiene recupero personale3 anche nella II; il suo mazzo compare nei drop della morte confermata. Vendita solo al Mercato Nero con incasso180–250 Obser, proposta iniziale215 modificabile.
- Osservazione progressivamente facilitata per PT50/30/20/10. Fino a50 PT, margine+5 sulla DT rivela punto debole e PT esatta senza un naturale minimo; varianti coerenti di Percezione usano le stesse regole.
- Elementi automatici separati: maggior bonus Danni per attaccare, maggior bonus Difesa per difendersi; la Skill con elemento proprio prevale. Skill, Art e Titoli equipaggiati/in uso concedono3 punti percentuali di resistenza elementale, forme contate una volta, con limite90% e immunità già presenti conservate.
- Resistenze delle creature coerenti con anatomia e materiali. Mezzo Slime con +2 MAT, Controllo corporeo e Riflessi e fragilità25% a Fuoco/Esplosioni. Titoli Item evocabili/disevocabili senza Azioni né ricarica gratuita delle riserve consumate. Entrare da un mercante esegue Riposo Breve completo.
- I costi scritti come `@mat-1` o `@ocu-2` vengono consumati soltanto all’attivazione, senza diventare malus permanenti mentre la Skill è equipaggiata.
- Corretto il costo di una Skill Open che cambiava dopo la riapertura JSON dei Titoli Item. I controlli su catalogo, conversione e progressione mantengono separati valori originari e potenziamenti.
- Schede, statistiche, sottotratti, effetti, costi min/max, requisiti, durata, cooldown, inventario e descrizioni restano modificabili. Test locali, build, pacchetti pubblici e sessioni reali sono verifiche distinte. Le grandi espansioni non ancora validate restano dichiarate in lavorazione per conservare quota.


## Correzioni delle segnalazioni del 26 ottobre 2026

- Stabilità durante il cambio turno e l'apertura dei menu: animazioni limitate alle decorazioni, con controlli stabili e accessibili. Il feedback al tocco parte dopo il tap e rispetta le finestre aperte.

- Trasparenze evidenziate progressivamente fino alla piena visibilità in tre secondi, con mouse e tocco; testi, icone e controlli cliccabili conservati.
- Richieste d'ingresso al Master controllate anche durante il recupero lento di presenza/eventi; nessuna nuova interrogazione continua.
- Tiri di sottotratto e richieste Master: completamento dopo il dado reale, riprova se mancano risorse, Percezione richiesta senza scelta di un nuovo bersaglio; Azioni supplementari e Azioni sotto Sfinimento riconosciute.
- Fuga e rientro: risorse consentite anche fuori fight, consumo sincronizzato una volta al Master, vecchie richieste chiuse al nuovo fight.
- EXP personale della fuga verificata nell'assegnazione effettiva e dopo il caricamento JSON, senza doppioni. Formule confermate di fuga e ricompense ordinarie per Grado conservate.
- Trasparenze di base e parametri di schede, abilità, oggetti e Role restano modificabili negli editor e conservati nel JSON. Dettagli in [Verifica bug del 26 ottobre](VERIFICA_BUG_2026-10-26.md).

Modifiche successive alla build `b917217d98d16861a5bbaf1706d78825d883c970`, run `40242640717`, incluse quelle del commit `12cbe566`. Questo registro conserva tutte le novità dalla versione di partenza. Per la build distribuita fare riferimento al commit e ai download della release GitHub.

## Creature e tecniche

Alle 24 specie delle dodici fasi, con 48 tecniche, si aggiungono 11 creature del ciclo e due Giganti, con 29 tecniche: 37 specie e 77 tecniche dopo la build di riferimento. Restano forme I/II/III, costi, requisiti, cooldown, anatomia, punti deboli, materiali, scroll e Open. Fase, luogo e ricerca sono combinabili. Le soglie personalizzate delle scroll restano rispettate; naturale 18/19 assegna una tecnica e 20 entrambe per le specie con due tecniche, senza duplicati. L'Ultimo Ciclo conserva le due specie precedenti.

- Riccio dei Sentieri Quieti: pacifico, tre tecniche di utilità/protezione. Cinghiale del Fango: Fango, Terra e Roccia in questo ordine. Uomo Cactus: escrescenze carnose spinose che conservano liquidi, perdita del senno e caccia ai corpi per reidratarsi.
- La Follia: +1 Follia sul critico riuscito; una Reazione veloce extra al proprio turno se è vivo un alleato dell'Illness. Gigante Goblin: −5 ai tiri d'attacco; una Reazione normale al primo turno personale degli altri Goblin, una volta per scontro.
- Forest Demon Blu dalle Corna Rosa: Nuvola/Sogno. Nube con −3 Movimento fino a fine fight, senza sovrapposizioni; probabilità di impedire la difesa 5% per ogni suo critico nello scontro, massimo 100%. Scudi critici proteggono dai debuff critici.
- Solare della Siccità: infligge e riceve +50% Danni contro Lunari, ali danneggiabili separatamente. Identità Solare/Lunare distinta da Fato/Chaos; Mhunan Lunari di base, altre razze senza appartenenza fino alla scelta.
- Lupo Lunare: Pedata Manifestazione del Potere contro Resistenza, −6 a tutti i tiri per un turno a chi perde, CD iniziale 4. Morso Lunare/Ombra secondo la maggiore efficacia sul bersaglio, casuale a parità.
- Marmocchi del Fato: durante The Fate, ai membri Fato +1 alle quattro statistiche nel 75% dei casi, +2 nel 25%. Tre donatori distinti al massimo, nessun dono ripetuto dallo stesso: totale +3…+6. Uscire dalla fase azzera doni e conteggio; compreso Oculum.
- Melma di The Null: oblio narrativo dell'identità, schede e progressi conservati. Orso dagli Aculei Ghiacciati: 1d8+2 colpi; ogni precedente colpo riuscito sul medesimo bersaglio dà +5% Danni, su un altro +10%. Critico: Gelo un turno, stadio crescente con applicazioni ripetute.
- Gigante comune: fino a tre bersagli; danno base ripartito, poi +15 +5×livello a ciascuno. Gigante Scheletro: Vita Afona per 1d3 turni con naturale 19–20 riuscito. Telecinesi: metri = attacco−difesa−2 su naturale 1–17, attacco−difesa su 18–20. Ripresa gratuita: superare l'attacco su 1–17, DT 13+metri su 18, DT 16+metri su 19. Su 20 si spende Azione/Reazione e serve almeno il doppio dell'attacco, senza successo automatico del naturale 20. Ripresa riuscita: solo Danno base. Altrimenti +2 Danni per metro, bonus Schianto dal 19, normali effetti critici al 20.

## Fuga, rientro e Role

Utility Fuga: 1d20 + Movimento + max(Riflessi, Velo). Costa Azione nel proprio turno, Reazione fuori turno. Chi nota blocca con 1d20 + Movimento + Riflessi. Parità: Movimento maggiore; se pari, Fuga riuscita. Con Velo, visibilità = naturale + Velo contro Percezione passiva senza +10; l'ultimo attaccante ha +3 per notare salvo sia stato attaccato successivamente. Visibilità correggibile dal Master.

L'ultimo aggressore che ha tolto Vita ha un tentativo gratuito di colpire oppure bloccare solo se nota. Il colpo non ferma la Fuga salvo critico riuscito o Precisione con totale almeno quattro quinti del tiro di Fuga. Gli aiutanti spendono Azione/Reazione: +3 se nell'ultimo colpo, +2 altrimenti. Dal lato di chi fugge, il compagno con il più alto precedente Aiuto ha un tentativo gratuito.

Fuori fight: non attaccabile, ma conserva il turno; una Azione e due Reazioni, con singola estrazione al 50% che converte una in veloce. Fuga critica: tre Reazioni veloci al primo turno fuori fight. Solo cure, riparazioni e utilità su di sé oppure rientro, che costa una Azione. Rientro con Velo: +3 al prossimo tiro per colpire e +Velo ai Danni contro ciascun bersaglio con Percezione passiva non superiore al Velo; possono aiutare solo coloro che percepiscono chi rientra. I membri Fato dello stesso party si percepiscono sempre. Rientro con Riflessi: visibile, una Reazione veloce ora e nel successivo turno. Reinvii senza duplicazione dei benefici.

Tutto il party vivo fuggito conclude il fight. EXP personale = max(Vita reale persa personalmente, Vita reale tolta ai nemici ÷ membri per difetto − propria statistica Danni). Scudi esclusi; ricevute duplicate non ricontano Vita. Nessun nuovo bonus prima sconfitta o Chained Fate su questa ricompensa.

Ogni scontro ha una cartella apribile Role, rinominabile dal Master: accoglie chi fugge e il party rimasto a fine fight. Master la vede anche vuota, altri solo se contiene qualcuno. Pressione prolungata sul partecipante: il Master lo sposta in Role. Nome e appartenenze persistono nella turnistica; iniziare un nuovo fight ripristina la partecipazione.

## Scudo del provocatore

Nuova skill di Difesa con forme I/II/III, livelli iniziali 0/3/6. Costo 5/10/20 Oculum, durata tre turni, CD tre turni. Probabilità di attirare attacchi 60%/75%/90%; Scudo 30/40/60×livello. Difesa iniziale scelta su delega dell'utente: +5/+10/+15. Riserva separata dagli Scudi esistenti, nuova attivazione sostituisce la precedente, scadenza elimina il residuo.

Solo il colpo che rompe la barriera riflette il 50%/75%/100% dei danni da essa assorbiti in quel colpo più il 50%/75%/100% della propria statistica Danni, totale per difetto. Valgono le normali Difesa e protezioni dell'attaccante; reinvio senza doppio danno. Fra più barriere attive la selezione usa la probabilità maggiore; contrattacchi e intercettazioni con bersaglio obbligato mantengono il bersaglio.

## Interfaccia, editor e compatibilità

Impostazioni riorganizzate in sette sezioni con ricerca dedicata: Preferenze, Aspetto, Colori, Scheda, Sessione, Regole e mod, Dati e backup. Gallerie costruite solo nella sezione aperta. Tutti i precedenti controlli e collegamenti rapidi restano disponibili; nessuna cancellazione di dati. Trasparenze precedenti di default aggiornate una sola volta, valori personalizzati conservati.

Statistiche e pulsanti inferiori: trasparenza indipendente 0–40%, consigliata 24%; GUI generale 34%. Controlli vicini ma separati, affiancati su desktop e impilati sul telefono; testi/icone pieni, hover sul controllo.

Modificabili: nomi, descrizioni, statistiche, anatomia, punti deboli, resistenze, materiali/drop, skill/Open, forme, costi, risorse, livelli, bersagli, quantità, durata, cooldown, formule, dadi e percentuali della nuova skill. Persistono identità, trasparenza e nome Role. Nuove definizioni senza sovrascrivere personalizzazioni JSON. Nessun nuovo tipo generale di parser: effetti strutturati esistenti con nuovi bersagli specifici; condizione dedicata Pressione del Lupo Lunare.

Download automatici dal commit realmente compilato, versioni precedenti conservate, verifiche anonime degli archivi separate da suite locale, Supabase e prova con app indipendenti. L'istruzione corrente richiede anche EXE con runtime, ZIP e APK, Windows e Windows Test in cartelle normali.

## Slime Roccioso e bilanciamento

Conferme dell’utente: la voce Monster Book e il relativo pool comprendono Palla di roccia slime, Rimbalzo, Indurimento e Apertura Masso Slime. I cuccioli attaccano tutto, gli adulti sono neutrali buoni; Gradi Senza Grado/I/II. Il drop raro Indurimento è identico alla tecnica del mostro.

- Palla I: Oculum immesso +15 Danni, costo 1–4, livello 0. II: Danni pari all’Oculum immesso oppure blocco con Vita Oculum immesso ×3 e Reazione contro il bersaglio, costo 5–10, livello 5. III: blocco ×10, costo 11–20, livello 13. Cooldown iniziali scelti per bilanciamento: 2/3/4.
- Rimbalzo I/II: una Reazione e +25%/+50% Danni per la prossima azione, costo 1–3/4–6, livello 1/6. III: un solo tiro 1d3 determina rimbalzi, Reazioni e +50% Danni ciascuno per il turno, costo 7–10, livello 12. Cooldown iniziali 2/3/5.
- Indurimento I: Scudo 10 + Oculum immesso, Difesa 5 + Oculum immesso; costo 1–2, livello 0. II: Scudo 25 + Oculum immesso ×1,5, Difesa 6 + Oculum immesso ×1,5; costo 3–4, livello 3. III: Scudo 1d250 +50 + Oculum immesso ×3, Difesa 15 + Oculum immesso ×3; costo 5–10, livello 10. Difesa sei turni, Scudo fino a esaurimento, cooldown iniziali 3/4/6.
- Masso Slime, livello 15: colpo iniziale Oculum ×5, separato da Schiaccio. Buff Open +5 a tutte le statistiche e +9 ai tiri. Ultima scelta esplicita dell’utente: Schiaccio ×3 totale, riutilizzabile con CD 3; sostituisce la precedente conferma ×4. L’amplificazione Open è già inclusa nel ×3.
- Drop: Roccia Slime 250 g; Indurimento dal totale 15; Rimbalzo sul naturale 20.

Audit del catalogo: 1.157 voci, 8.352 forme, 4.611 forme distinte. Quindici forme attive a pagamento che danno cure, Scudo o Reazioni avevano CD zero: ai soli nuovi modelli sono assegnati CD 3/4/5 per forma. Cooldown espliciti e passivi prevalgono; nessuna riscrittura delle skill salvate. L’audit verifica economia e definizioni, non dimostra da solo il bilanciamento di ogni combattimento.

## Nuvola, Golem e stanze inattive

Vita della Nuvola attira i mostri: gli attacchi dei mostri danno priorità alle forme nuvola nemiche disponibili. Il pugno del Golem di Roccia Nuvola sceglie fra Nuvola, Roccia e Fulmine in base alla resistenza del bersaglio; parità casuale. La barriera colpita nello Scudo effettua un tiro automatico gratuito di Manifestazione +5; un critico riuscito colpisce anche gli altri nemici e stordisce per un’Azione. Le scariche non innescano altre scariche; ricevute duplicate non ripetono gli effetti.

Inattività: 30 minuti senza input di alcun partecipante, poi avviso al Master di 60 secondi con «Resta online». Mouse, tocco, scorrimento e tastiera di chiunque annullano la chiusura; presenza di rete automatica non conta come attività. La stanza inattiva disconnette le sessioni senza eliminare schede o salvataggi. Gli input sono aggregati alla presenza periodica, senza un messaggio per ogni movimento del mouse.

## Potere totale e rilevatori

Conferme dell’utente: Potere totale = Resilienza + Volontà + Materia + Oculum + Livello + Grado ×3. Da Lettura dell’aura +20 la tua Potenza esatta e i numeri già scoperti si aggiornano automaticamente; gli altri rimangono un confronto qualitativo fino alla scoperta. Una lettura mirata riuscita di Percezione o del migliore sottotratto di osservazione ha probabilità 5% per ogni punto oltre 20 se il bersaglio ha Potenza inferiore a 100, oppure oltre 40 da 100 in su; massimo 100%. La lettura del numero è distinta da livello, probabilità e punto debole.

I rilevatori funzionano anche sugli altri personaggi. Gli alchimisti vendono amuleti, bracciali e cavigliere in legno magico con cristalli che riflettono il cielo anche senza vederlo. A Postea sono gadget cyberpunk. Portata = 50 + livello oggetto ×30. La lettura è una stima entro ±10%; oltre portata mostra solo «oltre la portata» senza il valore reale. Il destinatario online calcola il risultato senza trasmettere le proprie statistiche.

- Alchimisti: 1d9 +6 utilizzi (7–15), tirati una sola volta all’acquisto.
- Postea: ultima correzione confermata 1d23 +12 utilizzi (13–35), prezzo sei volte tanto allo stesso livello.
- Prezzo iniziale scelto su delega: 30 +15 × livello in Obser; Postea sei volte questa cifra.
- Uso: selezione del bersaglio dall’inventario; una normale Azione/Reazione in combattimento. Una carica per scansione, anche oltre la portata; annullare la selezione non consuma. Riaprire negozio o JSON non ritira gli utilizzi.
- Nome, note, livello e utilizzi residui sono modificabili nell’editor oggetto e conservati nel JSON. Portata ricalcolata dal livello modificato, quantità degli acquisti separate. Costi/offerte restano modificabili dal mercante.

Lo Slime Roccioso e le sue varianti seguono le soglie specifiche confermate: Roccia Slime materiale, Indurimento al totale 15 e Rimbalzo al naturale 20, senza imporre la DT generica 20 + livello + Grado ×3. Gli altri mostri conservano la propria DT.

## Verifiche locali del primo aggiornamento del 26 ottobre

Il riferimento richiesto è la build GitHub 40242640717, commit b917217d98d16861a5bbaf1706d78825d883c970. Comprende anche l’integrazione 12cbe566 delle prime 24 creature, non solo le modifiche successive. Il catalogo passa da 1.120 a 1.157 voci; 37 specie e 77 tecniche sono aggiunte complessive rispetto al riferimento.

Il 26 ottobre la suite locale completa ha superato 1.181 test, con sei test condizionali saltati. Analisi Flutter senza problemi, 11 test dei download pubblici e tre test dell’updater Windows superati. Il controllo dei temi copre tutti i 61 elementi ufficiali, comprese scene, cornici, varianti e cinque stati dei pulsanti. Le prove UI delle sette sezioni Impostazioni coprono 320 e 1.440 pixel; salvataggio e aggiornamento delle trasparenze sono verificati separatamente.

Queste verifiche locali non sostituiscono la CI del commit finale, i download anonimi, l’installazione dei pacchetti e la prova online con applicazioni indipendenti. I relativi esiti vanno registrati dopo il completamento.

## Mercanti, skill di Potenza totale, stanze e download separati


Conferme esplicite: i mercanti considerano anche la Potenza totale per proporre oggetti adatti. Il valore usa Resilienza + Volontà + Materia + Oculum + Livello + Grado ×3. La selezione aggiunge la compatibilità con la potenza a livello, disponibilità e preferenze; prezzi e acquisti conservati non cambiano.

Scarica totale e Impeto totale aggiungono la propria Potenza totale ai Danni di un singolo attacco, una sola volta anche con raffiche e più bersagli. Il prossimo tiro per colpire e il primo tiro nemico per colpirti ricevono +max(2, 10 − Adattamento). Il bonus si consuma quando il singolo attacco viene dichiarato, anche se manca il bersaglio.

Sfinimento: azzera immediatamente tutte le Reazioni disponibili, normali, veloci, gratuite e supplementari; blocca ogni nuovo guadagno, anche da skill, critici, rimbalzi, mecha, Fuga o altre fonti. Durata = 1d3 turni personali + un turno ogni 160 Potenza totale per difetto. Non viene annullato da Stato di Forza. Le Azioni continuano a funzionare. Nuova attivazione sostituisce il colpo in attesa e non accorcia lo Sfinimento. Le Reazioni eliminate non vengono restituite alla scadenza; riprendono i normali nuovi recuperi.

Impostazioni iniziali scelte sulla delega al bilanciamento: costo 5 Oculum per Scarica, 5 Volontà per Impeto; CD tre turni. Nomi, descrizioni, costi, cooldown, formula del bonus, dadi e durata base sono modificabili tramite editor e JSON; le definizioni salvate non vengono sovrascritte.

Online: nessuna nuova connessione usa implicitamente la stanza «test». Il giocatore inserisce il codice del Master; un Master senza codice riceve un codice nuovo. Le stanze già salvate conservano il codice esplicito. Stanze private e approvazione del Master restano operative.

Distribuzione GitHub: Windows normale e Windows Test in ZIP e artifact di cartella separati. Le versioni precedenti restano conservate.

## Per recuperare dalla vostra versione

Scaricate la nuova edizione dalla pagina download. Windows normale e Windows Test hanno archivi distinti. Conservate la vostra edizione e i vostri salvataggi; i valori personalizzati restano rispettati. Il codice stanza deve essere identico su tutti i dispositivi e il Master deve ammettere i giocatori prima della condivisione. Una stanza privata non elimina i personaggi.

## Equipaggiamenti e verifica delle 37 specie aggiunte

Tutte le 37 specie hanno armi, armature e scudi derivati dalle proprie 77 tecniche: 231 oggetti e 693 forme delle skill sugli oggetti. Le 231 forme originali sono verificate con applicazione effettiva degli effetti, compresi i supporti. Tecniche speciali del ciclo e Potenza totale compaiono in Attacco e preparano il colpo senza spendere due volte la risorsa di turno. Resta il supporto ai vecchi effetti del Morso Lunare senza marcatore, senza sovrascrivere le personalizzazioni. [Tabella per specie e metodo di verifica](VERIFICA_MOSTRI_AGGIUNTI.md).

## Log al primo avvio di una nuova versione

Il registro completo, sempre cumulativo dalla build b917217, compare automaticamente solo al primo avvio di ogni nuova versione installata. Un clic fuori dalla finestra lo chiude; sono disponibili anche Chiudi ed Esc/Indietro. Il riconoscimento della versione è persistente e separato fra Oculum normale e Test. Il contenuto è incluso nel pacchetto e funziona offline, senza traffico Supabase. Le aperture successive della stessa versione non ripropongono il log. La consultazione volontaria resta disponibile dal menu download web e nel registro GitHub.

## Ordine del Monster Book del Master

Il Monster Book del Master mostra prima i più deboli e poi i più forti, varianti comprese, usando Potenza totale crescente: Resilienza + Volontà + Materia + Oculum + Livello + Grado ×3. Parità risolte con livello, Grado, nome e ID. Filtri e ricerca mantengono questo ordine; il valore compare nella riga. L’ordinamento viene memorizzato con i risultati filtrati e non modifica il catalogo o le schede salvate.

## Aura, numeri scoperti e osservazione mirata

- Con Lettura dell’aura almeno +20 conosci la tua Potenza totale esatta e confronti automaticamente la tua forza con quella dei bersagli osservati, senza ricevere il loro numero se non lo hai ancora scoperto.
- Il valore esatto degli altri si scopre con una lettura mirata riuscita di Percezione o del migliore sottotratto di osservazione disponibile: Percezione, Investigazione, Furbizia, Valutazione o Lettura dell’aura. Bersaglio sotto 100 Potenza: soglia oltre 20; da 100 in su: oltre 40. Probabilità = 5% per ogni punto oltre la soglia, massimo 100%.
- L’ultima Potenza esatta scoperta resta in piccolo accanto al nome del PG e nella turnistica di nemici e compagni, anche dagli incontri precedenti. Con Aura +20 i numeri già scoperti si aggiornano automaticamente quando cambiano; sotto +20 rimane l’ultimo valore conosciuto fino a una nuova lettura. Le risposte vecchie non sovrascrivono scoperte più recenti.
- I rilevatori conservano la propria lettura stimata ±10% e la portata: la stima è indicata con ≈ e non sostituisce un precedente numero esatto. Il confronto qualitativo e una lettura fallita non eliminano numeri conosciuti.
- Un’osservazione mirata eseguibile ha probabilità pari al valore del sottotratto usato, massimo 95%, di non consumare Azione/Reazione. Esempi: +32 → 32%, +110 → 95%. Fuori combattimento non c’è costo di turnistica. Lo Sfinimento continua a bloccare le Reazioni.
- Le conoscenze sono memorizzate nella scheda e nel JSON per osservatore, campagna e identità del bersaglio. L’Aura usa confronti autenticati e aggiornamenti su variazione della Potenza; nessuna interrogazione continua. La snapshot pubblica contiene solo una revisione, mai le statistiche o la Potenza interna nascosta.

## Consegna online con tag salvati

Corretto il confronto tra il tag autenticato restituito in maiuscolo dal server e i tag salvati con maiuscole/minuscole: attacchi, difese, aiuti, risposte Aura e conferme di consegna mantengono la stessa identità. Anche i frammenti delle schede confrontano l’identità senza cambiare il tag salvato. Ruoli, sessioni, proprietari, approvazione del Master e controlli contro mittenti falsificati restano verificati. La prova con quattro profili e il test Supabase autenticato includono ora tag con maiuscole/minuscole.

Le schede ricevute mantengono il tag originale anche oltre il terzo posto nell’archivio del Master. L’installazione locale riutilizza gli artifact di cartella verificati per evitare copie temporanee dei runtime, preservando la distribuzione precedente fino alla verifica finale.

Aura: anche una modifica salvata dal Master aggiorna la revisione pubblica della Potenza; chi aveva già scoperto il numero lo riceve automaticamente con Aura +20. Salvataggi senza variazioni di Potenza non inviano nuove snapshot. Il numero nascosto resta escluso dalla turnistica pubblica.
