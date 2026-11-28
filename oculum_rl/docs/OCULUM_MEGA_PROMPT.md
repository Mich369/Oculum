OCULUM — MEGA PROMPT DI IMPLEMENTAZIONE

App, VTT e campagna roguelite 2D expressive ink / dark fantasy

Lavora direttamente sul repository Oculum disponibile nell'ambiente. Voglio modifiche reali, integrate e verificabili, con una versione avviabile che mi permetta di giocare. Procedi dall'analisi all'implementazione, al playtest e alla build. Mantieni questo documento come specifica completa: le priorità servono a organizzare il lavoro, non a eliminare richieste.

La nuova modalità è una campagna roguelite 2D in tempo reale, giocabile in solo e nelle partite online condivise descritte sotto, con le creature, le regole e l'identità di Oculum. Deve sostituire il vecchio Dungeon/Ascesa degli Eroi e convivere con l'app delle schede e con il VTT online migliorato.

1. Regole di lavoro e tutela del progetto

Prima di modificare il codice:

Leggi AGENTS.md, le istruzioni locali, i manuali, le regole confermate e gli arretrati pertinenti. Cerca anche docs/OCULUM_REGOLE_CONFERMATE.md e docs/manuale-consultazione.md, se esistono.

Esamina lo stato Git e conserva le modifiche dell'utente. Lavora in modo reversibile, senza reset distruttivi, cancellazioni indiscriminate o riscritture del progetto.

Individua dati canonici, salvataggi, cataloghi di creature, armi, equipaggiamenti, sottotratti, Art, Occhi dei Caduti, negozi e immagini approvate.

Distingui il regolamento Oculum da eventuali modalità semplificate Oculus. Usa il sistema corretto per ogni modalità.

Controlla vecchie modifiche, TODO, regressioni e attività incomplete relative alle funzioni richieste. Verifica cosa funziona davvero.

In caso di differenze tra documentazione e codice, documentale. Questa richiesta definisce le nuove modifiche; le altre regole confermate devono rimanere coerenti.

Crea una checklist nel progetto e registra le decisioni di bilanciamento ancora provvisorie. Le richieste esplicite non sono negoziabili; i numeri non forniti devono provenire dal regolamento oppure essere indicati chiaramente come proposte configurabili.

Lavora autonomamente sulle decisioni reversibili. Chiedi solo ciò che blocca davvero una decisione essenziale e non è ricavabile dai file. Se uno strumento o un servizio non è disponibile, completa le parti indipendenti e descrivi il blocco esatto.

Se puoi usare agenti paralleli, assegna ambiti distinti: audit e salvataggi, parser e regole, VTT, gameplay, grafica e verifica. Integra il risultato con un unico controllo di coerenza.

2. Priorità assoluta: PRIMA CONSEGNA GIOCABILE

Voglio poter giocare dalla PRIMA BUILD CONSEGNATA. Realizza e avvia il nucleo del gioco nel primo ciclo di implementazione; l'editor avanzato, il catalogo completo e gli ampliamenti del VTT proseguono mentre questa versione è già utilizzabile.

Metti un pulsante “GIOCA SUBITO”: personaggio iniziale pronto, scelta rapida tra le tre armi, difficoltà e seed, ingresso nel primo stage. Deve essere possibile partire anche senza configurare una stanza online, una videochiamata o servizi esterni. Usa uno slot libero e proteggi quelli occupati.

La prima consegna deve già chiudere questo percorso:
avvio → scelta salvataggio → personaggio → arma → seed → combattimento → loot → shop → avanzamento → morte → ricompense → nuovo tentativo.

Comprendi fin dall'inizio:

Movimento normale di corsa, mira, attacco, duplicazione, scatto con Shift, camminata lenta con Ctrl e inventario.

Tre armi funzionanti, nemici Oculum animati e camera richiesta.

Almeno una mappa giocabile per ciascuna ambientazione richiesta: Campo Scostubanditi, foresta con radura e grande dungeon con uscita da trovare. Devono usare il generatore e le regole della partita reale.

Primo stage completabile, danni, EXP, level up, risorse e ricompense.

Gran Scostumato e Forest Demon come élite con i propri eventi, un passaggio segreto funzionante e una ricompensa a scelta unica.

Evocazioni realmente utilizzabili, oltre alla duplicazione iniziale: almeno un'Art di evocazione ottenibile nel gioco, senza assegnarla gratuitamente al primo personaggio.

Oggetti distruttibili e un pericolo ambientale realmente dannoso, clash tra attacchi e comportamento adattivo iniziale dei nemici.

Salvataggio e ripresa, morte e ripartenza, sblocco del personaggio della levitazione dopo la prima run conclusa.

Necromante sbloccabile con le condizioni previste, preset completo e trasformazione/cura sul tasto 3; verifica in solo e nella sessione online condivisa.

Daphne con preset completo, robot curatore/Pawn V2, doppia arma per 5 secondi e cambio arma con rotellina o 5; gli altri personaggi cambiano con rotellina o 4.

Tre quest compatibili per piano, achievement distinti e premio maggiore di un cristallo grande di Ascension Dust più 20 Obser.

R per interagire e ricaricare, portali volontari dopo il fight e moneta rara per accedere a una Micro Realtà giocabile.

Cooperativa effettiva con gli amici già presenti nella stanza: stessa run, nemici, quest, progressione del mondo e passaggi condivisi.

Incontri boss La tua Luce e La tua Ombra accessibili attraverso la progressione e i seed di verifica.

Accesso ai sei slot delle azioni e alle impostazioni essenziali.

Un percorso concreto per aprire il gioco: build eseguibile o indirizzo realmente accessibile dall'utente.

Appena il nucleo supera una prova completa, consegna l'accesso e continua lo sviluppo delle altre richieste. Non aspettare la fine dell'intero incarico per rendermi disponibile una partita. Mantieni avviabile quella versione durante le estensioni.

Nella prima consegna distingui chiaramente le funzionalità già operative da quelle ancora in completamento. “Giocabile” deve significare che hai avviato e provato il ciclo, non soltanto che il codice compila.

Procedi con questa priorità:

Tutela dati, ricognizione e correzioni strutturali necessarie.

Primo ciclo completo con personaggio iniziale, tre armi, tre ambientazioni giocabili, incontri élite, segreti, evocazioni, salvataggio e progressione.

Grimorio, scroll, gruppo, Occhi, narrativa, stagioni, difficoltà e contenuti.

Completamento delle modifiche app/VTT, musica e videochiamata, lavorabili anche in parallelo.

Rifinitura visiva, prestazioni e verifica finale.

Una parte completata non rende completato l'intero incarico. Se incontri un limite dell'ambiente, lascia il lavoro salvato, una versione avviabile e l'elenco preciso di ciò che resta, senza dichiararlo implementato.

3. Direzione artistica: expressive ink e dark fantasy

La direzione principale è EXPRESSIVE INK + DARK FANTASY, con un'impronta grafica simile a DON'T STARVE, integrata nel tratto Oculum già approvato:

Contorni a inchiostro energici, tratteggi, pennellate e macchie controllate.

Silhouette riconoscibili e animazioni espressive.

Materiali vissuti, architetture inquietanti, contrasti decisi e accenti di colore leggibili.

Creature fedeli al loro aspetto e alla loro identità: carine quando il catalogo le definisce carine, macabre quando devono esserlo.

Interfaccia gotica chiara, coerente e utilizzabile anche su schermi piccoli.

Effetti di colpo e magia che sembrino parte dello stesso mondo illustrato.

Usa le MIE creature e le loro versioni approvate. Cerca gli asset corretti prima di produrne di nuovi. Scostubandito e Gran Scostumato devono corrispondere alle versioni attuali del progetto; non ripristinare immagini scartate.

Anima personaggi, mostri, armi, ambiente ed effetti con priorità alla leggibilità. I nemici devono avere comportamento, silhouette e attacchi propri, non essere tutti lo stesso nemico con una texture diversa.

REGOLA DI AMBIENTAZIONE: LE FATE SONO MALVAGE.
Mantienilo in dialoghi, quest, reclutamento, eventi, descrizioni e comportamento. Una fata può apparire dolce o amichevole per ingannare, ma non deve diventare automaticamente una guida benevola o una guaritrice buona. Distingui le fate dal Titolo del Fato e dagli altri termini del regolamento.

Da Don't Starve riprendi come direzione visiva il disegno espressivo, i contorni irregolari, il tratteggio, le forme leggermente deformate e il contrasto tra apparenza fiabesca e inquietudine. Applica questa resa a creature, ambienti, oggetti e animazioni originali Oculum. Mantieni la camera della foto e una simulazione 2D.

4. Telecamera: riferimento alla foto allegata

La foto di Nuclear Throne che ho fornito riguarda LA TELECAMERA.

Implementa una visuale 2D top-down a tre quarti:

Orientamento fisso, terreno visto dall'alto e personaggi leggibili anche frontalmente.

Pareti e ostacoli con profondità disegnata e corretto ordinamento degli elementi.

Camera che segue il protagonista con movimento fluido e limiti della mappa.

Campo visivo sufficiente a leggere minacce, proiettili, alleati e vie d'uscita.

Leggero anticipo verso la mira solo se utile e regolabile.

Inquadratura stabile, adatta sia al mouse sia ai controlli touch.

La foto non cambia la direzione artistica: mantieni expressive ink e dark fantasy. Le altre ispirazioni non devono cambiare questa inquadratura. Se Codex non riceve l'immagine, usa questa descrizione e segnala il riferimento visivo mancante senza bloccare il gioco.

5. Ispirazioni da tradurre in caratteristiche concrete

Rielabora queste direzioni nel linguaggio di Oculum:

Nuclear Throne: partite dinamiche, scelte di build, armi riconoscibili, segreti, shortcut, ricompense immediate e ripartenza rapida.

Dead Estate: horror grottesco, stanze compatte, esplorazione, negozi, personaggi distinti e sorprese.

Hotline Miami 2: risposta immediata dei comandi, scontri incisivi, importanza di porte, coperture, traiettorie e posizionamento.

Wizard of Legend: magie reattive, combinazioni tra abilità, effetti elementali riconoscibili e sperimentazione della build.

Gunfire Reborn: costruzione della build attraverso combinazioni tra personaggio, armi, abilità e potenziamenti; varietà degli incontri, percorsi e stanze di ricompensa. Adatta questi principi alle evocazioni e alle regole Oculum.

Don't Starve: caratterizzazione grafica disegnata, animazioni espressive e atmosfera cupa e fiabesca, adattate alle creature Oculum.

Hero Forge: ampiezza della personalizzazione del personaggio e anteprima comprensibile delle modifiche.

Mantieni Vita, Oculum, Difesa, Scudo, resistenze e progressione del nostro sistema. L'ispirazione al ritmo di un gioco non autorizza a sostituire queste regole con la morte obbligatoria in un solo colpo.

Crea asset, ambientazioni, musica e interfacce originali coerenti con Oculum. Usa i riferimenti per principi di progettazione e sensazioni di gioco.

Conserva la visuale 2D a tre quarti, la campagna solo e l'identità expressive ink/dark fantasy. L'influenza di Gunfire Reborn riguarda struttura e combinazioni del gameplay; non richiede di trasformare Oculum in uno sparatutto in prima persona.

6. Architettura e rimozione del vecchio Dungeon

Rispetta lo stack reale del repository. Se l'app è Flutter, scegli un'integrazione 2D adeguata ai suoi target; se esiste già un runtime di gioco valido, riutilizzalo. Documenta la scelta del motore e verifica la compatibilità delle dipendenze prima di introdurle.

Separa:

Regole di combattimento e simulazione.

Rendering, animazioni e camera.

Input e interfaccia.

Generazione del mondo e storia.

Salvataggi e progressione.

Servizi della stanza online.

Rimuovi completamente la vecchia modalità Dungeon/Ascesa degli Eroi dalla navigazione, dai collegamenti e dal codice esclusivo dopo aver identificato le dipendenze. Conserva cataloghi, creature, shop, inventari e sistemi condivisi necessari alla nuova modalità o alle schede.

Proteggi i dati preesistenti con una migrazione versionata e recuperabile. La rimozione di una modalità non autorizza a cancellare le schede della campagna principale.

Il GRANDE DUNGEON richiesto qui è una nuova ambientazione esplorabile del roguelite. La rimozione della vecchia modalità Dungeon/Ascesa degli Eroi rimane valida: crea il nuovo bioma senza ripristinare quel vecchio flusso.

7. Animazioni, schivate Oculum e Vantaggio nell'app

Le animazioni devono essere ATTIVE DI BASE nelle nuove installazioni e quando manca una preferenza salvata. Correggi eventuali default precedenti errati, distinguendo una preferenza esplicita dell'utente. Offri un controllo per ridurle o disattivarle.

Schivate Oculum:

Il contatore mostra soltanto la quantità disponibile: 0, 1, 2, 3.

Con due schivate deve mostrare esattamente “2”, non “2/2”.

Clic destro su desktop e pressione prolungata sul controllo touch aprono lo stesso menu contestuale in stile Oculum.

Il menu permette di impostare la quantità con controlli chiari e convalidati.

Quantità, consumo, salvataggio e sincronizzazione devono restare coerenti e non scendere sotto zero.

Accanto inserisci “Vantaggio”, con gestione di vantaggi e svantaggi applicati davvero ai tiri pertinenti. Mostra il modificatore nel riepilogo dell'azione.

Usa la regola Oculum confermata: se il sistema usa modificatori come +3/-3, conservali; non importare automaticamente altre convenzioni. Definisci secondo il regolamento accumulo, annullamento, durata e consumo.

Le modifiche di quantità devono rispettare proprietà delle schede e autorizzazioni della stanza.

8. Parser: usare il risultato di un tiro nelle formule

Supporta almeno:

@danni+tiroriflessi

@difesa+1/2tiromateria

Il primo esempio aggiunge al danno il risultato valido del tiro Riflessi pertinente. Il secondo aggiunge alla Difesa metà del risultato valido del tiro Materia.

Requisiti:

Collega ogni riferimento all'attore e all'azione corretti.

Riutilizza il risultato realmente ottenuto, includendo una sola volta i modificatori dovuti.

Non eseguire un nuovo tiro nascosto e non recuperare accidentalmente un tiro vecchio.

Interpreta 1/2tiromateria come tiromateria / 2.

Gestisci parentesi, precedenze, frazioni e sintassi già supportata.

Applica la convenzione di arrotondamento canonica; se manca, scegli e documenta una regola unica, senza arrotondamenti intermedi incoerenti.

Se il tiro necessario non esiste, richiedilo nel flusso dell'azione o segnala il dato mancante; non sostituirlo con zero in silenzio.

Mostra un riepilogo leggibile: base, tiro usato, frazione, modificatori, risultato finale.

Usa un parser con grammatica limitata e validazione, evitando esecuzione arbitraria di codice.

Verifica casi numerici concreti, attori differenti, modificatori, frazioni, tiro assente e compatibilità con formule preesistenti.

9. VTT: qualità, automazioni e funzioni della stanza

Migliora il VTT con funzioni utili alle sessioni Oculum. Consulta le release stabili attuali di Foundry e la documentazione dei moduli pertinenti. Confronta capacità concrete e registra cosa implementi.

Aree da coprire:

Scene e mappe, token, movimento, selezione e misurazioni.

Porte, muri, linee di vista, illuminazione e nebbia di guerra.

Stati, effetti, tiri, bersagli, danni e turnistica del VTT.

Zone con eventi, trigger, trappole, transizioni e scorciatoie.

Diario, handout, schede condivise, bestiario e strumenti del Master.

Animazioni collegate alle azioni, suoni contestuali e automazioni configurabili.

Permessi per proprietario, giocatore e Master.

Riconnessione con recupero dello stato corrente.

Studia, quando pertinenti, le idee di moduli come Sequencer e Monk's Active Tile Triggers. Implementa equivalenti adeguati a Oculum: non presumere che un modulo Foundry possa essere installato direttamente in un'app diversa.

“Fatto meglio” deve diventare verificabile: meno passaggi per le operazioni comuni, interfaccia touch utilizzabile, minore ingombro, caricamenti mirati, comportamento prevedibile e assenza di regressioni note.

Le funzioni e i pacchetti configurati dal Master devono risultare disponibili agli utenti della sua stanza senza installazioni individuali superflue. Distribuisci automaticamente configurazione e risorse consentite, con versioni e cache. Il possesso di un contenuto non va confuso con il diritto di ridistribuirlo.

Valida i privilegi sul backend e mantieni leggera la sincronizzazione: invia cambiamenti necessari, non l'intero stato a ogni fotogramma.

10. Musica condivisa dal Master

Il Master deve poter condividere una canzone o un video e far ascoltare nella stanza la componente audio.

Implementa:

Importazione di file audio e video supportati.

Per i video importati, riproduzione della traccia audio senza mostrare il filmato sul tavolo.

Playlist e controlli Master: avvio, pausa, ripresa, posizione, cambio traccia, loop, volume della traccia e dissolvenze.

Riproduzione sincronizzata anche per chi entra dopo o si riconnette.

Volume personale e mute per ciascun partecipante.

Canali distinti per musica, effetti e voce.

“Solo traccia musicale” significa anzitutto audio del contenuto; non presumere la necessità di separare automaticamente voce e strumenti.

Per link esterni usa soltanto integrazioni realmente supportate. Non promettere di estrarre audio da qualunque sito: se un provider non consente l'operazione, spiega il limite e permetti l'importazione del file disponibile.

Usa il backend stanza per lo stato e il signaling; scegli una distribuzione media appropriata. Non trasmettere continuamente file audio/video come aggiornamenti di schede.

Gestisci consenso alla riproduzione e limitazioni del browser con un pulsante “Attiva audio” chiaro. Il Master controlla la sessione, ma non può forzare l'audio contro il mute locale.

11. Videochiamata visibile e discreta

Deve esserci un pulsante riconoscibile nella stanza: “Avvia chiamata” oppure “Entra in chiamata”.

La chiamata deve avere:

Pannello compatto, spostabile, riducibile e minimizzabile.

Microfono, videocamera, selezione dispositivi e uscita sempre comprensibili.

Modalità solo audio e gestione dei permessi negati.

Nessuna attivazione silenziosa di microfono o videocamera.

Gestione della riconnessione e messaggi utili in caso di errore.

Verifica il percorso reale su due client. Configura trasporto e servizi di connessione necessari, considerando HTTPS e reti differenti. Se mancano credenziali o infrastruttura indispensabile, indica precisamente cosa serve e non presentare una semplice interfaccia come chiamata funzionante.

12. Il roguelite: obiettivo e ciclo di gioco

La modalità è una campagna in tempo reale GIOCABILE IN SOLO E IN COOPERATIVA ONLINE CON GLI AMICI CHE HANNO GIÀ JOINATO LA STANZA. L'obiettivo è sopravvivere il più a lungo possibile, condividendo la stessa run quando si gioca insieme.

Il ciclo comprende esplorazione, combattimenti, scelte narrative, salvataggio di NPC, reclutamento, loot, shop, riposi, crescita, morte e nuovo tentativo.

Dopo uno stage completato proponi TRE destinazioni realmente diverse e raggiungibili. Differenziale per rischio, risorse, creature, eventi, mercanti e conseguenze sulla storia.

Distingui sempre:

Livello del personaggio: EXP e crescita.

Piano/stage: unità di avanzamento con tre quest e scelta delle destinazioni successive.

Stanza/area: porzione di un piano; entrarvi non genera automaticamente un nuovo set di quest.

Giorno: sopravvivenza e ciclo temporale.

Tentativo/run: partita dalla partenza alla conclusione.

Le tre destinazioni appartengono all'avanzamento negli stage. Un level up di EXP durante un combattimento non deve teletrasportare o concludere automaticamente la stanza.

12-bis. Tre quest fattibili per ogni piano e achievement distinti

Ogni PIANO presenta ESATTAMENTE TRE QUEST, tutte completabili nello stesso tentativo e compatibili fra loro. Ogni quest assegna un ACHIEVEMENT DIVERSO dalle altre due. Mostra obiettivo, progresso, condizioni e ricompensa, mantenendoli coerenti con l'ambientazione, la difficoltà e il personaggio o gruppo effettivamente presente.

Genera e valida le tre quest insieme alla mappa. Bersagli, oggetti, accessi e strumenti necessari devono essere disponibili e raggiungibili in quel seed. Non assegnare una quest che richieda un'Art non ottenibile, un particolare personaggio assente, una porta senza chiave raggiungibile, una moneta rara non garantita oppure un nemico che non viene generato.

Le tre condizioni devono essere compatibili: per esempio, non richiedere contemporaneamente di risparmiare un NPC e uccidere lo stesso NPC. Non rendere una quest impossibile in seguito al completamento corretto di un'altra. La fattibilità garantita riguarda le condizioni iniziali e la logica della generazione; le scelte e le azioni del giocatore possono comunque produrre conseguenze e fallimenti leggibili.

Varia il tipo di obiettivi in base al luogo: esplorazione, incontro, recupero, salvataggio, scoperta, uso dei sottotratti o sfida di combattimento. Non inventare nuovi mostri o sottotratti per riempire una quest se esistono già quelli del catalogo Oculum. Le interazioni richieste devono essere eseguibili DOPO il fight, in accordo con la regola di R; eventuali salvataggi durante lo scontro devono avvenire attraverso il combattimento o altre azioni già consentite.

Difficoltà e premio maggiore

INTERPRETAZIONE OPERATIVA ESPLICITA di «il più forte»: è l'obiettivo più impegnativo fra le tre quest del piano, non un premio assegnato automaticamente anche al nemico con la statistica più alta.

Calibra requisiti, incontri e complessità delle tre quest sulla difficoltà selezionata. L'obiettivo più impegnativo assegna, al completamento:

UN CRISTALLO GRANDE DI ASCENSION DUST.

ESATTAMENTE 20 OBSER.

La difficoltà modifica la sfida; non cambia automaticamente queste quantità, che sono state indicate dall'utente. Recupera l'oggetto «cristallo grande di Ascension Dust» dal catalogo. Non sostituirlo con un'unità di polvere, un cristallo casuale o una quantità inventata di Dust: un'eventuale conversione segue il suo valore canonico.

Le altre due quest hanno achievement distinti e le eventuali ricompense definite nei dati di gioco. Non attribuire a tutte e tre il premio maggiore. I drop normali/élite/boss già previsti restano eventi separati: assegna ciascun premio una volta secondo la sua origine, senza confondere il completamento della quest con una seconda morte del nemico.

Progresso, persistenza e cooperativa

Mantieni distinti quest del piano, achievement persistente del profilo e premio ottenuto nella run. Possedere già un achievement non impedisce di completare la quest e ricevere la ricompensa prevista in una nuova run; non sblocca però nuovamente lo stesso achievement come se fosse inedito.

Registra piano, tre obiettivi, entità coinvolte, progressi, completamento e premi riscossi. Salvataggio, riapertura del diario, riconnessione, viaggio in una Micro Realtà o ritorno non rigenerano le quest e non ripagano quelle concluse. Una Micro Realtà che costituisce un piano autonomo ha il proprio identificatore e le proprie tre quest; un'area laterale del piano corrente condivide quelle già presenti. Questa distinzione deve essere definita nei dati del luogo.

Nella cooperativa usa TRE QUEST CONDIVISE PER PIANO, non tre set incompatibili per ciascun amico. Le azioni dei giocatori e delle loro unità contribuiscono secondo l'obiettivo; lo stesso evento viene contato una volta. Come regola operativa iniziale, gli achievement e il premio si attribuiscono una volta a ciascun partecipante idoneo, mantenendo 1 cristallo grande e 20 Obser per il premio maggiore. Sono idonei i giocatori presenti nel gruppo durante il completamento, compresi quelli già partecipanti momentaneamente disconnessi; chi entra nella run soltanto dopo non ottiene retroattivamente un premio già concluso. Riconnessione e cambio dispositivo non creano una nuova idoneità.

Al termine del piano conserva il tempo per leggere obiettivi, raccogliere premi e usare i servizi. Il portale non trascina via il gruppo. Se è consentito partire con una quest incompleta, mostra la conseguenza prima della scelta di uscita.

12-ter. Giocare online con gli amici che hanno joinato la stanza

REQUISITO CONFERMATO: gli amici già entrati nella stanza devono poter GIOCARE INSIEME nella stessa campagna roguelite. Devono controllare i propri personaggi nella stessa mappa, affrontare gli stessi nemici e contribuire alle stesse quest. La sola condivisione di schede, seed, videochiamata o schermate non soddisfa questa funzione.

Dalla stanza alla partita

Integra nella stanza un accesso visibile al roguelite cooperativo, riutilizzando partecipanti, identità, ruoli e accessi già verificati. Non richiedere agli amici di creare una seconda stanza o configurare una nuova connessione per giocare insieme.

Il Master/organizzatore sceglie i parametri della run consentiti: seed, difficoltà, ambientazione iniziale e opzioni della sessione. Ogni partecipante seleziona il proprio personaggio utilizzabile e l'equipaggiamento ammesso, vede gli altri e indica di essere pronto. Distingui chi gioca da chi osserva. I contenuti condivisibili e le configurazioni della stanza devono arrivare ai partecipanti secondo le regole già previste per le risorse del Master.

Avvia la partita con uno stato condiviso e una schermata chiara per eventuali risorse ancora in caricamento. Un ingresso tardivo deve poter unirsi alla run in corso in un punto sicuro; durante un fight può attendere il prossimo punto di ingresso valido, con il motivo e lo stato visibili. Non inizializzare un nuovo mondo locale indipendente per chi entra dopo.

Giocatori umani e compagni autonomi

Per mantenere utilizzabili evocazioni e talenti anche quando ci sono amici, adotta questa REGOLA OPERATIVA ONLINE: i giocatori umani occupano i posti giocatore della stanza, distinti dai compagni autonomi. Ogni PG mantiene il limite di TRE compagni autonomi, comprendenti reclutati, cloni, robot ed evocazioni di supporto/combattenti, più UN Occhio dei Caduti. Il limite di due cloni e di due altri PG salvati controllati come compagni resta applicabile al proprietario.

Un amico che controlla il proprio PG non occupa automaticamente uno dei tre posti destinati all'IA. L'ingresso di un amico non cancella un robot o un alleato e non disabilita di fatto il Q di Daphne o la mano del Necromante. Evita che lo stesso PG venga contemporaneamente controllato da un amico e duplicato come compagno salvato senza una regola esplicita.

Il numero massimo di GIOCATORI UMANI non è stato fissato dall'utente. Usa la capienza supportata dall'infrastruttura e dalle verifiche effettive, rendendola configurabile e visibile prima di unirsi. Non presentare il vecchio numero di quattro unità complessive come un limite già approvato. Verifica prestazioni e sincronizzazione con giocatori e compagni al limite dichiarato.

Un solo risultato di gioco

Una sola autorità della sessione convalida movimento rilevante, attacchi, clash, schivate, effetti, AI, evocazioni, cure, loot, EXP, quest, consumo di monete e transizioni. I client inviano azioni riferite al proprio personaggio; non decidono autonomamente HP, premi o disponibilità delle abilità.

Mantieni controlli reattivi e riconciliazione dello stato, con interpolazione visiva degli altri partecipanti. Usa identità degli eventi e numerazione delle richieste per evitare doppi colpi, cure, monete e ricompense durante ritardi o ritentativi. Separa gli aggiornamenti frequenti di gioco dai salvataggi persistenti: non salvare l'intera mappa a ogni frame e non usare una scrittura persistente per ogni particella o movimento cosmetico.

Sincronizza mappa, seed e stato casuale pertinente, nemici, incontri, tempo del giorno, fame, quest, oggetti interattivi, segreti, portali e scelte narrative. Inventari, valute, sblocchi e premi mantengono un proprietario definito; una raccolta valida o una ricompensa condivisa viene attribuita secondo la sua politica, non una volta per ogni messaggio ricevuto.

Le tre quest del piano sono condivise e i premi individuali rispettano la regola di idoneità e riscossione unica. I compagni contribuiscono a danni e progressi per il proprio proprietario senza moltiplicare uccisioni o EXP. Un amico non può modificare lo stato privato di un altro oltre i permessi espliciti del Master e della sessione.

R e transizioni del gruppo

R su un portale disponibile apre la richiesta di destinazione condivisa. Mostra luogo, eventuale moneta/costo e obiettivi lasciati incompleti. I giocatori attivi coinvolti confermano di essere pronti; il trasferimento avviene una volta sola quando le condizioni sono valide. Nessun giocatore viene risucchiato o trascinato fuori da un combattimento perché un altro tocca il portale.

Un incontro richiesto ancora attivo o un'ondata obbligatoria non risolta impedisce la transizione. Gestisci esplicitamente giocatori morti, in attesa d'ingresso e disconnessi: non richiedere una conferma impossibile a un personaggio che non può agire. Il giocatore disconnesso conserva identità e stato; al rientro raggiunge la destinazione corrente del gruppo secondo le regole di recupero, senza nuovo addebito della moneta o ricompense iniziali duplicate.

Riposi e avanzamenti che cambiano il tempo condiviso seguono una decisione del gruppo. Aprire il proprio inventario o le impostazioni non mette in pausa gli altri. La modalità in solo mantiene invece le sue regole di pausa.

Ripresa e verifica reale

Conserva identificatore della run, partecipanti e proprietari dei PG, stato del mondo, progressi individuali e checkpoint. La riconnessione ripristina il proprio personaggio, HP, posizione valida, inventario, evocazioni e tempi residui, senza creare copie nuove o reinizializzare la run. Proteggi le schede e i sei salvataggi personali: giocare con gli amici non sovrascrive una campagna estranea.

Se l'autorità dipende dall'host e l'host esce, implementa e prova il recupero previsto dall'infrastruttura: continuità/migrazione se supportata oppure pausa recuperabile e ripresa dal checkpoint. Non dichiarare una migrazione automatica non verificata e non lasciare progredire copie divergenti della stessa partita.

Prova almeno DUE CLIENT SEPARATI entrati nella STESSA STANZA e nella STESSA RUN. Verifica controllo contemporaneo, un nemico danneggiato da entrambi, quest condivise, ricompense uniche, moneta, R sul portale, conferma del gruppo, ingresso tardivo e riconnessione durante un'abilità. Prova inoltre il massimo gruppo dichiarato con evocazioni attive e condizioni di rete controllate. Una schermata di lobby riuscita non conclude la verifica del gioco online.

13. Seed, spawn, stagioni e storia

Genera il mondo con un seed visibile, copiabile e inseribile. Deve governare mappe, spawn, incontri, loot, eventi e selezione iniziale di stagione e giorno, secondo regole riproducibili.

Mantieni flussi casuali distinti: un effetto grafico o un suono non deve alterare il prossimo drop. Salva lo stato casuale necessario alla ripresa. La riproducibilità riguarda seed, versione, condizioni iniziali e stesse decisioni del giocatore.

Fra le condizioni iniziali includi lo stato iniziale della memoria adattiva: nelle difficoltà Difficile/Oculum può provenire da tentativi precedenti. Per riprodurre una run o confrontare due prove, conserva anche quella fotografia iniziale e la versione delle regole; lo stesso seed con una diversa storia dell'IA non garantisce lo stesso combattimento.

Prevedi più punti iniziali, non soltanto coordinate differenti:

Ogni inizio cambia primi incontri, minacce, opportunità e agganci narrativi.

Uno degli inizi possibili è la Tana/Campo degli Scostubanditi.

Gli altri usano ambienti e creature coerenti con il catalogo Oculum.

Gli spawn devono essere validi, percorribili e protetti da danni inevitabili immediati.

Prevedi gruppi nemici, élite, miniboss, boss, segreti e percorsi alternativi.

Stagione e giorno iniziale sono casuali. LITTLE BREATH deve essere la stagione più comune. Recupera nomi, significati e pesi esistenti; se mancano, documenta le aggiunte come proposta di ambientazione e configurazione.

Le scelte devono cambiare davvero il mondo: NPC vivi o morti, alleanze, negozi, prezzi, accessi, dialoghi, incontri e possibili esiti. Salva questi fatti e applicali agli eventi successivi.

Gli NPC destinati a morire devono poter essere salvati attraverso azioni concrete. Lo sblocco successivo deve essere persistente. Evita scelte cosmetiche che conducono sempre allo stesso risultato.

Usa i sottotratti Oculum negli eventi pertinenti: osservazione, trattative, sopravvivenza, agguati, percorsi, conoscenze, trappole e altri casi sostenuti dal catalogo. Mostra il sottotratto, i modificatori e le conseguenze del risultato.

Collega il seed a profili di ambientazione: ogni profilo seleziona soltanto creature compatibili con quell'habitat. Geometria, arredo, incontri, storia e ricompense devono esprimere la stessa identità.

14. Ambientazioni create attorno alle creature di Oculum

Crea MAPPE DI GIOCO COMPLETE, percorribili e interattive, costruite attorno ai mostri Oculum che le abitano. L'ambientazione deve far capire perché quelle creature si trovano lì.

Parti da schede, immagini e descrizioni canoniche: habitat, materiali, proporzioni, abitudini e tipi di attacco. Ricava da questi elementi terreno, ostacoli, ripari, tracce, decorazioni, illuminazione, suoni e situazioni narrative. Inserisci proprio le creature da cui deriva l'ambiente; non sostituirle con nemici generici.

Per ogni bioma definisci un profilo con:

Creature consentite e varianti di incontro.

Terreno, geometrie, elementi grafici e collisioni.

Punti di spawn del giocatore e dei nemici.

Obiettivi, progressione narrativa ed evento élite.

Shop, loot, riposi, segreti e uscite.

Variazioni per seed, stagione, fase del giorno e difficoltà.

Genera prima la rete di aree e collegamenti, poi geometria, decorazioni e spawn. Combina parti disegnate con cura e variazioni procedurali. Verifica raggiungibilità dell'uscita, spazi di combattimento, passaggi per il gruppo e assenza di nemici bloccati nei muri.

Ogni ambiente deve avere una forma e un modo di giocare riconoscibili, non soltanto colori differenti sulla stessa stanza. Implementa fin dalla prima versione giocabile le tre ambientazioni descritte di seguito.

14-bis. Regno Affogato, Micro Realtà e Regni di Oculum

Amplia l'elenco delle mappe richieste includendo esplicitamente il REGNO AFFOGATO, le MICRO REALTÀ e i REGNI di Oculum. La richiesta è di rendere il gioco riconoscibile come questo mondo: luoghi, creature, incontri, eventi, personaggi e percorsi devono derivare dalla sua ambientazione.

Questi nomi sono confermati dall'utente. Le ultime indicazioni confermano anche l'uso di MOSTRI GIÀ ESISTENTI IN OCULUM, la moneta rara per accedere alle Micro Realtà, R per le interazioni e i portali, e le tre quest per piano. La geografia completa e l'elenco dei Regni devono essere ricavati dai materiali canonici del progetto e dalla cartella /oculum indicata dall'utente. Non trattare definizioni mancanti come se fossero già approvate. Continua le parti già specificate mentre recuperi i documenti di ambientazione necessari.

Regno Affogato

Crea un profilo di ambientazione dedicato con mappe percorribili, più varianti da seed, spawn, creature canoniche, oggetti interattivi, incontri e conseguenze narrative propri. La parola «Affogato» da sola non stabilisce se il personaggio nuoti, cammini in zone emerse o segua altre regole: chiarisci questo punto con il canone.

Un diario di Oculum già consultato racconta un viaggio attraverso il Regno Affogato verso il Regno Mezzano. Usalo come aggancio narrativo documentato da confrontare con i materiali più aggiornati; la presenza di quel viaggio non rende automaticamente ogni percorso obbligatorio né descrive l'intera topologia del mondo. Non trasformare tutti gli incontri narrati in eventi garantiti a ogni run.

Per popolare il Regno Affogato usa i MOSTRI DI OCULUM STESSO: recupera ID, descrizioni, habitat, statistiche, comportamenti e asset dal bestiario esistente. Seleziona quelli compatibili con le zone e le condizioni definite dal canone. Non creare un bestiario estraneo o rinominare genericamente i nemici come «mostro affogato». Ricava da questi dati anche élite/boss appropriati, terreno e scelte narrative; se l'habitat non è specificato, dichiara la selezione come proposta senza alterare la scheda canonica della creatura.

Micro Realtà

Inseriscile come contenuto esplorabile con identità e stato propri. L'ACCESSO è ora definito: una MONETA RARA permette di raggiungerle attraverso un passaggio attivato intenzionalmente. La moneta può essere trovata nella run e conservata; la probabilità di ritrovamento deve restare rara e provenire dai dati canonici oppure da una proposta dichiarata, non da una percentuale presentata come già approvata.

Come flusso operativo iniziale, scegliere la moneta come oggetto utilizzabile prepara un portale in una posizione valida. Prepararlo o raccogliere la moneta non trasporta il personaggio. Il giocatore si avvicina al portale e preme R, soltanto a combattimento concluso. La stessa regola si applica agli altri portali e accessi dei Regni: niente risucchio, attrazione verso l'uscita, ingresso per sola collisione o teletrasporto automatico al termine del fight.

La moneta viene riservata per l'accesso e consumata una sola volta quando la destinazione è pronta e la transizione viene confermata dall'autorità della partita. Annullamento, errore prima del trasferimento o richiesta rifiutata non la fanno perdere. Associa moneta, portale e destinazione a un'identità stabile: riaprire un menu o ripetere un messaggio non crea altre destinazioni e non spende altre monete. Dopo un trasferimento confermato, un'interruzione riprende quello stesso viaggio senza restituire una moneta già spesa o addebitarla di nuovo.

In cooperativa, proposta esplicita: basta UNA moneta posseduta e autorizzata da un membro per aprire l'accesso del gruppo, senza richiederne una a ciascun amico. Il gruppo conferma il passaggio secondo le regole online; nessuno consuma la moneta di un altro giocatore senza la sua azione. Conserva un punto di ritorno valido e, come regola operativa iniziale, non richiedere una seconda moneta per tornare. Anche il ritorno richiede R e lo stato di combattimento appropriato.

La natura e le regole ambientali interne delle Micro Realtà restano quelle del canone: non attribuire automaticamente tempo rallentato, gravità invertita o altre proprietà sulla sola base del nome. Ogni moneta trovata deve consentire un accesso effettivamente giocabile, non un collegamento a una schermata vuota.

Una volta definita la natura, traduci le loro regole in comportamento effettivo: geometrie, accessi, condizioni d'uscita, incontri, ricompense e conseguenze. Rendi comprensibili al giocatore le regole locali che cambiano una decisione di gioco. Se è possibile tornare, conserva lo stato della singola Micro Realtà: creature sconfitte, oggetti distrutti, shop, scelte, NPC e ricompense già raccolte non si azzerano al rientro.

Regni

Usa i nomi e le identità dei Regni effettivamente definiti dall'utente. Mantieni distinguibili un Regno, le sue zone e le singole mappe di gioco se il canone prevede questa gerarchia. Non confondere un'Oculum Art che contiene la parola «Regno» nel nome con un luogo geografico.

Per ciascun Regno incluso, costruisci mappe coerenti con abitanti, creature, architettura, poteri, conflitti e storia disponibili nei materiali. Collega i suoi incontri e NPC alle scelte della run: salvare qualcuno, sostenere una parte, scoprire un passaggio o completare un evento deve poter modificare le possibilità successive secondo regole dichiarate. Se esistono aree sicure, civili o creature pacifiche, conserva questa identità e non trasformare automaticamente tutti gli abitanti in nemici.

Generazione, percorsi e requisiti di completamento

Registra per ogni ambiente un'identità stabile, le varianti, i contenuti consentiti e le regole confermate. Il seed sceglie fra possibilità valide per quel luogo, senza mescolare indiscriminatamente fauna, edifici e temi di altri Regni.

Collega accessi e uscite alla struttura narrativa definita. Le tre destinazioni proposte dopo uno stage devono rispettare i collegamenti e le condizioni realmente previsti dal mondo, inclusi quelli scoperti o sbloccati dal giocatore.

Applica i sottotratti Oculum pertinenti ad esplorazione, accessi, interazioni e scelte. Recupera i nomi dal catalogo, evitando sottotratti inventati per riempire un evento.

Mantieni segreti, negozi, evocazioni, compagni, difficoltà e memoria dell'IA compatibili con ogni nuova ambientazione. Le fate rimangono malvage anche qui.

Verifica percorribilità, spawn sicuri, collisioni, gruppo e condizioni d'uscita secondo le regole locali, in solo e online. Una proprietà insolita del mondo deve essere intenzionale e leggibile; un blocco accidentale non conta come evento narrativo.

Una voce nel menu o un profilo vuoto non equivale a una mappa completata. Per ogni ambiente effettivamente consegnato servono geometria giocabile, contenuti coerenti, almeno un percorso completo e salvataggio/ripresa verificati. Mantieni espliciti i dettagli ancora in attesa del canone, senza impedire di giocare alle ambientazioni già definite.

Fonte narrativa consultata per il passaggio Regno Affogato → Regno Mezzano: diario Oculum, Pasted text(4).txt. Se l'ambiente di implementazione non può aprirlo, usa i documenti già presenti nel progetto o chiedi il passaggio necessario; non dichiarare di aver letto una fonte inaccessibile.

15. Campi degli Scostubanditi e Gran Scostumato élite

Crea campi abitati dagli SCOSTUBANDITI canonici. Usa il loro aspetto e la loro descrizione per progettare ripari, passaggi, accampamenti, oggetti e tracce della loro presenza.

Varia con il seed entrate, corridoi esterni, zone aperte, coperture, pattuglie, imboscate e segreti, mantenendo spazio per leggere e schivare gli attacchi.

Il GRAN SCOSTUMATO è l'ÉLITE caratteristico di questa ambientazione. Conserva identità, aspetto e capacità canoniche; applica il ruolo élite alla variante d'incontro del roguelite senza alterare indiscriminatamente il bestiario della campagna.

Questo campo può essere il primo stage. Completandolo almeno una volta si sblocca lo SCOSTUBANDITO giocabile, in modo persistente.

Mantieni il primo shortcut richiesto nel primo livello: nella variante Campo Scostubanditi la sua attivazione fa comparire un GRAN SCOSTUMATO ÉLITE. Per quell'istanza del Campo, shortcut ed evento élite condividono un unico identificatore d'incontro. Se il Gran Scostumato è già presente o sconfitto, attivare nuovamente il shortcut non crea un'altra copia o ricompensa. Questo limite riguarda quell'istanza e non impedisce altri incontri in campi successivi.

Rendi la condizione del shortcut scopribile con indizi coerenti. Verifica che attivarlo non impedisca di completare lo stage o raggiungere una delle tre destinazioni successive.

Ricompensa dell'élite: 3 Oculum spento + 1 Ascension Dust, con eventuali drop canonici separati.

16. Foresta, radura centrale e Forest Demon élite

Crea una FORESTA con UNO SPAZIO CENTRALE APERTO riconoscibile: la radura è il fulcro della mappa. Collega sentieri, zone alberate, passaggi secondari e aree d'incontro.

Popola la foresta con i suoi NEMICI CANONICI, recuperati dal progetto. Collega vegetazione, tracce e architetture naturali a quelle creature. Non inventare arbitrariamente un bestiario diverso. Se compaiono fate, rispetta la loro natura malvagia.

Dopo la sconfitta di TUTTI I NEMICI PREVISTI PER COMPLETARE LO STAGE FORESTALE, fai arrivare nella radura un FOREST DEMON classificato ÉLITE.

Rendi esplicita la condizione:

Considera tutte le ondate e gli incontri obbligatori del percorso forestale.

Escludi giocatore, alleati, cloni, Occhio, mercanti, NPC neutrali e il Forest Demon ancora da generare.

Gestisci le evocazioni ostili attive degli incontri obbligatori: devono essere sconfitte o terminare secondo la loro regola prima di considerare concluso quell'incontro.

Le stanze segrete facoltative hanno un registro separato e non devono bloccare l'evento.

Un nemico fuori schermo o temporaneamente scaricato non conta come morto.

Annuncia l'arrivo con un effetto e un segnale leggibile. Non infliggere danni inevitabili materializzando l'élite sopra il protagonista e non teletrasportare il giocatore senza motivo.

Salva la sequenza: esplorazione → nemici richiesti sconfitti → Forest Demon apparso → Forest Demon sconfitto → stage completato.

Genera un solo élite per quell'evento, anche ricaricando. Dopo la sua sconfitta applica ricompensa élite, conseguenze narrative e accesso alle tre destinazioni successive.

17. Grande dungeon: esplorazione e orientamento per uscire

Crea un DUNGEON GRANDE come ambientazione del nuovo roguelite. Deve richiedere orientamento: non deve ridursi a una stanza o a un unico corridoio.

Genera camere, incroci, anelli, diramazioni, collegamenti tra settori, aree di riposo, incontri, scorciatoie e passaggi segreti. L'aspetto delle stanze e i nemici devono derivare dal catalogo Oculum e dalla storia del luogo.

Il giocatore deve TROVARE L'USCITA:

Non rivelarla automaticamente all'ingresso.

Offri riferimenti visivi distinguibili, tracce, segni, indicazioni ambientali ed eventuali NPC.

Prevedi minimappa esplorata progressivamente e marcatori personali.

Usa sottotratti pertinenti per interpretare indizi, individuare tracce o capire strutture.

Garantiscine la raggiungibilità per ogni seed accettato.

Se ci sono chiavi o meccanismi, verifica che si possano raggiungere e usare con le risorse disponibili.

Mantieni almeno un percorso di uscita che non dipenda da una stanza segreta facoltativa.

Combattere non deve sostituire l'esplorazione: eliminare i nemici non fa comparire automaticamente l'uscita ai piedi del protagonista. Il completamento richiede raggiungerla e soddisfare gli eventuali obiettivi dichiarati.

Il dungeon deve avere una dimensione e una distribuzione di incontri compatibili con movimento, pasti e giornata di gioco, evitando lunghi tratti vuoti e vicoli ciechi indistinguibili.

All'uscita, presenta le tre destinazioni successive.

18. Muri attraversabili, stanze segrete e scelta di una ricompensa

Alcuni muri devono NASCONDERE PASSAGGI ATTRAVERSABILI. Il giocatore può entrarci camminando e raggiungere una stanza segreta.

Seleziona questi passaggi durante la generazione e salvali. Usa indizi discreti coerenti con l'ink e l'ambientazione: differenze di tratto, vegetazione, suoni o tracce. Sottotratti appropriati possono aiutare a individuarli.

Il passaggio deve funzionare davvero per collisioni, camera, giocatore e compagni. Prevedi un ritorno praticabile e non richiedere una bomba o un'abilità speciale non prevista. La scoperta non deve rendere attraversabili tutti i muri della mappa.

Genera due tipi principali di stanza:

A. SHOP SPECIALE
Un mercante con prezzi effettivamente inferiori a quelli ordinari degli stessi oggetti. Usa gli sconti canonici o una proposta configurabile dichiarata. Mostra prezzo normale, prezzo scontato e disponibilità. Conserva offerte e acquisti dopo rientro e caricamento.

B. TRE OFFERTE, UNA SOLA SCELTA
Mostra tre power up oppure tre armi; eventuali terne miste sono ammesse solo se configurate esplicitamente. Il giocatore può prenderne ESATTAMENTE UNA.

Le tre offerte vengono determinate una volta. Uscire, rientrare, riaprire il pannello o caricare il salvataggio non deve modificarle.

La scelta deve assegnare la ricompensa e bloccare le altre due nella stessa operazione. Compagni, evocazioni e cloni non possono raccogliere le alternative. Gestisci inventario pieno e sostituzione dell'arma prima di consumare definitivamente la scelta.

Un power up scelto dura per la run secondo le regole ordinarie. Un'arma scelta è equipaggiabile e visibile. Indica chiaramente quando la ricompensa è già stata riscossa.

Integra questi segreti nei campi, nella foresta e nel dungeon, con frequenze adatte e seed di verifica.

19. Oggetti di campo distruttibili e attacchi ambientali

Il campo deve essere interattivo. Classifica gli oggetti come distruttibili, armi ambientali o entrambe le cose.

Colpire e rompere alcuni oggetti permette di ottenere OBSER secondo tabelle coerenti. Il contenuto si determina una volta, la distruzione si salva e il loot non ricompare caricando o rientrando.

Altri oggetti devono produrre VERI ATTACCHI, con anticipazione, collisione, traiettoria, danno ed eventuali stati. Permetti al giocatore di sfruttarli contro i nemici.

ESEMPIO OBBLIGATORIO: STALAGMITE.
Quando un colpo la fa cedere, registra la posizione di chi ha inferto quel colpo e falla ribaltare VERSO QUELLA POSIZIONE. Non farla cadere automaticamente nella direzione opposta e non farle inseguire il giocatore dopo l'avvio.

Mostra crepe, cedimento e una breve anticipazione leggibile.

Muovi realmente la sagoma e l'area pericolosa.

Chi si trova nella traiettoria può essere colpito; il protagonista può spostarsi o scattare via.

Calcola un solo impatto valido per vittima, salvo un attacco multiplo esplicitamente configurato.

Applica danno e resistenze attraverso il sistema di combattimento.

Se a innescarla è un nemico, usa la posizione di quell'attaccante.

Gestisci attivazioni simultanee e attribuzione delle uccisioni senza duplicazioni. Usa una regola esplicita per danni a giocatore, nemici e compagni.

Distruzioni, detriti e cadute devono aggiornare navigazione e collisioni senza rendere impossibile raggiungere uscite o segreti. Gli oggetti ordinari non fanno parte del conteggio dei nemici della foresta.

Distingui i pericoli evitabili, riflettibili o contrastabili: una roccia che cade non deve diventare automaticamente un proiettile riflettibile o un'arma coinvolta nei clash.

20. Personaggi, editor e sei salvataggi

Implementa un editor ricco, ispirato all'ampiezza delle modifiche di Hero Forge, adattato a personaggi animati 2D.

Permetti, compatibilmente con le razze disponibili:

Corpo, proporzioni e aspetto.

Volto, occhi, capelli, segni, cicatrici, tatuaggi e colori.

Abiti, armature, accessori, armi e dettagli caratteristici.

Anteprima animata, viste direzionali e verifica dell'equipaggiamento.

Nome, dati di gioco e scelta delle opzioni iniziali consentite.

Ogni modifica visibile deve comparire nel personaggio giocabile. L'aspetto non deve produrre hitbox incoerenti o vantaggi numerici accidentali.

Mantieni FINO A SEI SLOT DI SALVATAGGIO, con personaggio sempre riutilizzabile. Ogni slot deve mostrare anteprima, avanzamento e presenza di una partita riprendibile.

Distingui personaggio persistente, sblocchi, grimorio, progressione permanente e stato della run. La morte termina il tentativo, non cancella il personaggio.

Proteggi le schede della campagna principale: eventuali importazioni nel roguelite devono usare copie o un adattamento esplicito, senza scrivere accidentalmente sulle schede originali.

RENDI I PERSONAGGI MOLTO DIFFERENTI TRA LORO. Ogni personaggio giocabile deve avere silhouette, animazioni, talento, punti di forza, limiti e un modo di combattere riconoscibile. Usa razze, statistiche, capacità e identità canoniche; per i nuovi personaggi documenta le proposte. Le differenze devono influenzare le decisioni di gioco, oltre a nome e colore.

Il grimorio condiviso non deve appiattire le identità: preserva talenti innati, caratteristiche e interazioni distintive, pur lasciando accessibili le Art sbloccate. Il primo personaggio rimane quello con duplicazione e probabilità di apprendimento raddoppiata.

21. Grimorio e sei skill impostabili

Il primo personaggio e QUALUNQUE PERSONAGGIO CREATO NELL'EDITOR possiedono un grimorio.

Il grimorio conserva le Oculum Art apprese/sbloccate e permette di impostare SEI skill. La raccolta delle Art conosciute è distinta dalle sei azioni equipaggiate: cambiare una skill non cancella ciò che hai imparato. Tutti e sei gli slot possono ospitare Art; attacco dell'arma e talento sono opzioni assegnabili, non due posti permanentemente sottratti al grimorio.

Le Art sbloccate con punti e quelle ottenute senza punti devono poter essere assegnate:

Al grimorio del primo personaggio.

Al grimorio di qualsiasi personaggio creato nell'editor.

Come sostituzione di una skill per altri personaggi giocabili che usano un insieme di abilità predefinito.

La sostituzione deve far scegliere lo slot e mostrare il risultato prima di applicarlo. Conserva le abilità conosciute secondo il sistema del personaggio.

Mantieni un catalogo persistente degli sblocchi del profilo, accessibile al primo personaggio e a tutti quelli creati nell'editor, compresi quelli creati successivamente. Ogni personaggio ha sei assegnazioni indipendenti. Equipaggiare un'Art su un personaggio non la sottrae agli altri e non richiede un nuovo pagamento.

Non applicare un nuovo tiro casuale soltanto per equipaggiare un'Art già sbloccata. Costi, requisiti, limiti e progressione devono essere quelli canonici.

Alla primissima creazione, prima di qualsiasi sblocco, il primo personaggio parte senza Oculum Art e con la raccolta del grimorio vuota. La duplicazione è un talento innato. Gli apprendimenti persistenti devono rimanere disponibili nei tentativi successivi; i power up della singola run seguono invece la loro durata.

22. Comandi e impostazioni complete

Imposta un sistema di azioni rimappabili. Interpretazione operativa della mappatura: i sei slot corrispondono inizialmente a clic sinistro, clic destro, Q, 1, 2, 3. Sono tutti modificabili. Questo è il preset iniziale del primo personaggio:

Comando

Azione iniziale

WASD / frecce

Movimento normale, già di corsa

Mouse

Mira

Clic sinistro

Slot 1, attacco principale dell'arma

Clic destro sul campo

Slot 2, talento; duplicazione per il primo personaggio

Q

Slot 3, uso della scroll equipaggiata o dell'Art assegnata

1

Slot 4

2

Slot 5

3

Slot 6

Rotellina sul campo di gioco

Arma precedente/successiva; vale anche per Daphne

4

Arma successiva per tutti i personaggi tranne Daphne

5, con Daphne

Arma successiva; sostituisce il suo comando predefinito sul 4

R

Interazione contestuale dopo il fight, anche sui portali; altrimenti ricarica dell'arma quando applicabile

E

Apri/chiudi inventario

Shift

Scatto direzionale

Ctrl

Muoviti lentamente

Esc

Pausa / impostazioni / indietro

Tutti e sei gli slot sono realmente impostabili, anche con sei Art quando sbloccate. Nel preset iniziale attacco, duplicazione e scroll occupano i primi tre; gli altri tre sono disponibili per le abilità apprese. Se assegno un'Art al posto dell'attacco, della duplicazione o della scroll, quel comando esegue soltanto la nuova assegnazione. Le azioni precedenti restano disponibili nel catalogo per essere riassegnate. Non devono partire due azioni con lo stesso input.

Q usa la scroll selezionata rispettandone le regole. Se lo slot contiene un'Art appresa, esegue quell'Art. Mostra sempre cosa è assegnato e quale costo comporta.

Il cambio arma è un comando di equipaggiamento distinto dai sei slot delle abilità: non crea una settima Art. Scorre soltanto le armi possedute e inserite nell'equipaggiamento rapido, in un ordine visibile e persistente. Con una sola arma non duplica nulla. Il 4 di Daphne non cambia arma e non riceve automaticamente una nuova abilità; rimane non assegnato nel preset. Le rimappature volontarie restano possibili e devono rilevare conflitti.

Il cambio arma non azzera preparazione, recuperi, ricariche o cooldown delle armi, e non riavvia talenti, trasformazioni o modalità temporanee. Rispetta eventuali finestre di annullamento previste dal combattimento; un cambio ripetuto non deve accelerare un'arma lenta.

La rotellina cambia arma soltanto nel campo attivo del roguelite. Sopra inventario, impostazioni, chat o altri pannelli continua a scorrere l'interfaccia e non cambia equipaggiamento. Mantieni distinti anche i comandi della mappa VTT. Mostra su touch un comando di cambio arma e sulle altre periferiche il comando rimappato.

R — Interagire, usare i portali e ricaricare

R è un comando contestuale distinto dai sei slot delle abilità e funziona per TUTTI I PERSONAGGI, compresa Daphne. Mostra l'azione disponibile accanto al bersaglio o nell'HUD. Un singolo input esegue una sola azione:

Situazione

Azione di R

Fight attivo

Ricarica l'arma compatibile usando le munizioni/risorse previste; le interazioni del mondo restano bloccate.

Fight concluso, oggetto/NPC/negozio evidenziato e raggiungibile

Esegue l'interazione indicata.

Fight concluso, portale o accesso evidenziato

Richiede il passaggio volontario; online apre la conferma della destinazione condivisa.

Nessuna interazione valida selezionata

Ricarica l'arma compatibile, se necessario e se dispone delle risorse.

Chat o menu che cattura l'input

Segue il contesto UI, senza attivare comandi del campo di gioco.

INTERPRETAZIONE OPERATIVA: la limitazione «si può interagire solo a fight finito» riguarda interazioni del mondo, negozi, dialoghi, raccolte manuali e portali. La ricarica è un'azione di combattimento e rimane disponibile durante lo scontro. Non convertire R in consumo automatico di Vitalium, scroll o altri consumabili non selezionati. Per armi senza meccanica di ricarica mostra soltanto le azioni pertinenti.

La ricarica consuma le risorse previste e rispetta durata, annullamenti e stato dell'arma. Una richiesta ripetuta non duplica munizioni e non azzera il recupero. Quando un'interazione viene scelta, la stessa pressione non deve anche ricaricare o consumare risorse.

La fine del fight è uno stato esplicito dell'incontro condiviso: devono essere risolti nemici, ondate e attivazioni obbligatorie previste. Nella foresta, uccidere i nemici preliminari e far comparire il Forest Demon non chiude anticipatamente l'incontro. Non richiedere invece di eliminare ogni nemico di tutte le zone ancora inesplorate del grande dungeon per poter interagire in un'area completata.

Un R premuto durante un fight non viene conservato per entrare automaticamente in un portale appena muore l'ultimo nemico. Serve una nuova pressione volontaria quando l'interazione è disponibile. Il portale resta fermo e leggibile; non sposta, attira o risucchia il personaggio.

La raccolta automatica degli OBSER nel raggio, gli attacchi agli oggetti di campo e il movimento attraverso i muri segreti restano le rispettive meccaniche già definite. Non trasformarli in interazioni R obbligatorie. Un negozio trovato dietro il muro richiede invece la normale interazione fuori combattimento.

Per Daphne durante la doppia arma, proposta iniziale: R ricarica l'ultima delle due armi usata, se ricaricabile; mostra chiaramente quale e conserva recuperi separati. Eventuali ricariche simultanee richiedono una regola esplicita, non sono un effetto automatico della doppia arma.

Clic destro sul campo e clic destro sui controlli UI devono avere contesti separati: aprire il menu delle schivate non deve creare un clone. I comandi di gioco non devono scattare mentre si scrive o si interagisce con un menu.

Aggiungi equivalenti touch per mira, movimento, scatto, camminata lenta, abilità e inventario. Integra controller se già supportato dal progetto.

Crea impostazioni curate:

Comandi, rimappatura, sensibilità e comportamento tieni-premuto/interruttore.

Grafica, qualità effetti, ombre, particelle, limite FPS e scala UI.

Audio separato per musica, effetti, interfaccia e chiamata.

Intensità camera shake, lampeggi, leggibilità, dimensione testo e movimento ridotto.

Opzioni di gioco coerenti con la difficoltà.

Salvataggio, ripresa e uscita.

Ripristino dei valori predefiniti per categoria.

Le impostazioni devono funzionare, persistere e avere un riscontro immediato.

MOVIMENTO AGGIORNATO: il personaggio corre già durante il movimento normale. SHIFT ESEGUE UNO SCATTO, sostituendo la vecchia associazione Shift = corsa. Ctrl rallenta il movimento. Aggiorna anche tutorial, HUD, touch e impostazioni.

Lo scatto ha direzione, distanza, durata e recupero configurabili e collisioni affidabili. Da fermo usa la direzione di mira come default dichiarato. Non assegnargli automaticamente invulnerabilità, consumo di Oculum o consumo di una schivata Oculum: sono proprietà separate da definire con le regole effettive.

23. Primo personaggio: duplicazione

Talento innato assegnato inizialmente al clic destro sul campo di gioco. Una rimappatura esplicita segue le regole dei sei slot; non lasciare un secondo comando di duplicazione nascosto.

Requisiti espliciti:

Duplicarsi costa il 2% di HP.

Può creare al massimo due duplicati.

Ogni duplicato è un combattente con il 2% della Vita del protagonista.

Ogni duplicato infligge il danno del protagonista.

I duplicati combattono con un'IA funzionante.

Assunzioni operative PROVVISORIE da usare se non esistono regole più precise:

Calcola il 2% sulla Vita massima; il costo si sottrae alla Vita corrente, senza ridurre permanentemente la massima.

Arrotonda secondo il regolamento, con minimo 1 per Vita e costo se i valori sono interi.

Non attivare se il costo porterebbe sotto 1 HP.

Interpreta “massimo due volte” come limite di due cloni contemporanei; la possibilità di ricrearli dopo la morte e gli eventuali cooldown devono essere esplicitati nella configurazione, senza spacciare una scelta nuova per regola confermata.

Ogni clone occupa uno slot compagno, rispettando il limite generale del gruppo.

I cloni durano fino alla loro morte o alla conclusione della run, salvo regola canonica differente.

Il loro danno usa la stessa formula e gli stessi bonus applicabili del protagonista una sola volta.

I cloni non possono creare altri cloni.

Se mancano Vita, slot o requisiti, non sottrarre il costo e mostra la ragione. Salva numero, stato e limitazioni dei cloni per evitare duplicazioni mediante caricamento.

24. Personaggio sbloccato dopo la prima run: levitazione e riflesso

Aggiungi un personaggio distinto che si sblocca dopo LA PRIMA RUN EFFETTIVAMENTE CONCLUSA, anche se conclusa con la morte. L'apertura del menu o un caricamento non devono attribuire lo sblocco. Rendilo selezionabile e salva lo sblocco una sola volta.

Ha LEGGERMENTE PIÙ VITA del primo personaggio a parità di condizioni. Se manca un valore canonico, usa come proposta iniziale +10% alla Vita base, centralizzato e dichiarato come bilanciamento provvisorio; non confonderlo con il danno dell'esplosione.

Il suo talento innato, assegnato inizialmente allo slot del clic destro, permette di FLUTTUARE PER UN SECONDO:

Rendi visibile la levitazione con posa, altezza e ombra coerenti.

Durante quell'intervallo, i proiettili a distanza che lo raggiungerebbero vengono rimandati indietro verso la provenienza, senza applicare prima il danno al personaggio.

Conserva caratteristiche e danno del proiettile secondo la regola di riflessione, aggiornando proprietario e bersagli validi.

Il riflesso non garantisce che il proiettile restituito colpisca: rimane soggetto a traiettoria e ostacoli.

Un COLPO RAVVICINATO VALIDO interrompe immediatamente la levitazione.

L'interruzione da quel colpo scatena UNA SOLA ESPLOSIONE che infligge il 10% DEL DANNO DEL PERSONAGGIO a TUTTI I NEMICI VICINI.

Il colpo ravvicinato continua a seguire le normali regole del danno; non aggiungere un'immunità melee non richiesta.

Calcola l'esplosione da una definizione unica del danno offensivo corrente, con equipaggiamento e modificatori applicabili, prima delle difese del singolo bersaglio. Non usare il 10% della Vita. Applica poi resistenze, scudi e difese previste a ogni nemico.

Un tentativo di attacco schivato o annullato dal clash non è un colpo ravvicinato valido. La scadenza naturale del secondo di levitazione non causa l'esplosione.

Definisci raggio, costo e cooldown usando il regolamento oppure proposte configurabili dichiarate. Impedisci rinnovi infiniti, esplosioni duplicate e rimbalzi senza limite tra due riflettori. Per impatti simultanei usa un ordine di risoluzione deterministico.

La levitazione non permette automaticamente di attraversare muri o uscire dalla mappa. Il personaggio resta meccanicamente diverso dal primo: nessun raddoppio automatico dell'apprendimento delle scroll o duplicazione ereditata senza una regola.

24-bis. Necromante: medico della peste e forma mostruosa

Aggiungi un personaggio con aspetto di MEDICO DELLA PESTE: maschera a becco, vesti scure, silhouette leggibile e animazioni expressive ink/dark fantasy. La sua trasformazione riprende l'immagine allegata del gigantesco essere corvino: becco allungato, occhi luminosi, massa di piume e appendici nere, proporzioni imponenti. Adatta questa direzione alla grafica e alle creature di Oculum, con animazioni originali e attacchi leggibili nella telecamera di gioco.

Sblocco persistente

Il Necromante si sblocca con UNA delle due condizioni, in OR:

Raggiungere la TERZA MORTE effettiva del giocatore.

Sconfiggere il PRIMO BOSS della progressione di una run in difficoltà DIFFICILE.

Interpretazione operativa del contatore: le morti sono cumulative nel profilo, anche fra personaggi e tentativi; una morte seguita da una rinascita prevista dalla difficoltà conta una volta. Non contano morti dei compagni, evocazioni, disconnessioni, caricamenti o la sola sconfitta della forma mostruosa. Quest'ultima fa tornare alla forma normale e non è ancora la morte del personaggio. Il contatore non deve crescere due volte per lo stesso evento. Il Gran Scostumato e il Forest Demon restano élite e non soddisfano la condizione del boss. Per la seconda via usa esattamente Difficile; l'eventuale estensione alla difficoltà Oculum è un parametro esplicito, non un requisito già confermato.

Preset delle sei azioni

La revisione più recente assegna la trasformazione a 3. E resta inventario. Il set completo rispetta i sei slot esistenti: clic sinistro, clic destro, Q, 1, 2, 3. Nessuna azione aggiuntiva nascosta.

Comando

Abilità del Necromante

Clic sinistro

Attacco principale dell'arma equipaggiata.

Clic destro

Evoca UNA MANO SCHELETRICA che combatte insieme al Necromante.

Q

Mani scheletriche emergono nell'area di 10 metri e bloccano il movimento dei nemici colpiti.

1

Sfera di necromanzia VERDE E NERA che attira i nemici verso il proprio centro e li danneggia.

2

Attacco a SLASH di necromanzia, con direzione, preparazione, zona attiva e recupero leggibili.

3, in forma normale

Trasformazione mostruosa per SEI SECONDI, con cura iniziale della forma normale descritta sotto.

3, già trasformato

Cura della forma mostruosa pari al 15% del danno effettivamente inflitto e ancora disponibile per questa conversione.

E

Apri/chiudi inventario; non trasforma.

Le due righe del tasto 3 sono due stati della STESSA abilità, nello stesso slot. Le assegnazioni possono essere cambiate con le regole del grimorio. Se sostituisci questa abilità, il vecchio comando non continua ad attivarla. Non consentire di cambiarne l'assegnazione durante una trasformazione attiva.

La nuova versione del 3 sostituisce la vecchia cura del 10% in forma base e il vecchio urlo al 150% del danno in forma trasformata. Questi effetti non si sommano al nuovo funzionamento.

Evocazione, controllo dell'area e attacchi

La mano evocata con il clic destro è una vera unità alleata: ha Vita, attacchi, bersagli validi e IA, rispetta collisioni, porte e passaggi segreti, e occupa uno dei tre posti compagno. Per il preset iniziale proponi al massimo UNA mano del Necromante attiva; se manca capienza, mostra il motivo senza spendere risorse. Le mani del Q sono invece l'effetto di immobilizzazione e non generano decine di compagni autonomi.

I 10 metri del Q non specificano raggio o diametro: interpretazione iniziale dichiarata e configurabile, RAGGIO DI 10 METRI centrato sul Necromante. Mostra la stessa area effettiva nel mirino e nell'effetto visivo. Il blocco impedisce il movimento; stordimento, interruzione degli attacchi e resistenze dei boss seguono eventuali regole canoniche. Non colpire gli alleati. Come valore provvisorio, se il regolamento non ne fornisce uno, usa 2 secondi di immobilizzazione.

La sfera attira e danneggia realmente, con raggio, velocità di attrazione, durata e intervalli di danno dichiarati nei dati di bilanciamento. Non trascina attraverso muri o dentro geometrie invalicabili. Lo slash ha una zona d'impatto coerente con l'animazione e applica il danno una volta per bersaglio per colpo, salvo regola esplicita di attacco multiplo. Ricava danni, costi di Oculum e statistiche della mano dal regolamento; eventuali valori mancanti vanno risolti con proposte giocabili e configurabili chiaramente distinte dal canone.

Vita normale, Vita trasformata e cura iniziale

INTERPRETAZIONE OPERATIVA DA DICHIARARE: conserva la Vita della forma normale come riserva separata mentre è attiva la forma mostruosa. Quest'ultima ha la propria barra. Questo rende definibile il ritorno con meno Vita anche quando la barra del mostro arriva a zero.

All'attivazione valida del 3 dalla forma normale:

Controlla disponibilità dell'abilità, risorse, cooldown e stato vitale.

Cura la forma normale del 5% DELLA SUA VITA MASSIMA, senza superarla: vitaNormale = min(vitaMassimaNormale, vitaNormale + 0.05 * vitaMassimaNormale).

Conserva questa Vita normale aggiornata come riserva. La cura del 5% avviene una sola volta all'ingresso; non è una cura continua né una seconda cura applicata anche alla barra mostruosa.

Inizializza la Vita della forma mostruosa dai suoi dati di bilanciamento e avvia il timer di 6 secondi. Se non esiste una regola canonica, proposta iniziale configurabile: la forma ha Vita massima e iniziale pari alla Vita massima normale; le dimensioni grafiche non implicano altri bonus statistici automatici.

Azzera il conteggio dei danni convertibili della nuova trasformazione.

L'interpretazione del 5% come cura ALL'ATTIVAZIONE basata sui massimi normali, e l'uso di due barre, sono decisioni operative in assenza di ulteriori dettagli. Mantienile esplicite e facilmente modificabili. Un'attivazione rifiutata non cura, non consuma e non avvia il cooldown.

Tasto 3 durante la trasformazione: conversione del danno in cura

Interpreta il 15% come conversione attivata premendo 3 del danno GIA' INFLITTO durante la trasformazione e non ancora convertito. Non introdurre una durata aggiuntiva non richiesta: l'accumulo e la possibilità di usarlo esistono soltanto nei 6 secondi della forma.

Accumula il danno effettivamente sottratto alla Vita dei nemici dagli attacchi e dalle Art personali del Necromante, dopo difese, schivate e clash. Non contare danno teorico, overkill, oggetti di scena, autolesioni o bersagli alleati. L'eventuale inclusione del danno delle evocazioni richiede una regola esplicita; come proposta iniziale non contribuisce.

Premendo 3 durante la forma, quando il recupero della cura lo permette, ripristina min(vitaMostruosaMancante, 0.15 * dannoConvertibile) e consuma quel conteggio una volta sola. Anche l'eccesso oltre la Vita massima viene consumato: non diventa una cura futura gratuita.

Se non manca Vita o non c'è danno convertibile, non consumare il conteggio né avviare il cooldown della cura.

Il conto riparte dai danni successivi. Premere ripetutamente non riutilizza lo stesso danno, non riapplica il 5%, non crea una nuova trasformazione e non rinnova i 6 secondi.

Il cambio di forma non genera una seconda pressione del tasto: una pressione tenuta durante l'ingresso non deve attivare automaticamente anche la cura. Registra richieste d'azione distinte.

La cura va alla BARRA MOSTRUOSA, non aumenta anche la riserva normale. Alla fine della forma il conteggio residuo viene eliminato.

Esempio: 100 danni effettivi ancora convertibili consentono fino a 15 HP di cura, entro la Vita mancante della forma.

Fine della trasformazione e sconfitta del mostro

Alla SCADENZA NATURALE dei 6 secondi, ritorna alla forma normale con la sua riserva attuale conservata; nessuna penalità del 60% e nessun trasferimento automatico della Vita mostruosa residua.

Se la VITA MOSTRUOSA ARRIVA A ZERO prima della scadenza, interrompi la trasformazione e torna subito normale con il 40% DELLA VITA NORMALE ATTUALE CONSERVATA: vitaNormale = 0.40 * vitaNormaleConservata. Questo applica una perdita del 60% di quella Vita attuale, non del massimo. Non calcolare il 60% sugli zero HP della forma morta.

Esempio completo: Vita massima normale 100, Vita normale attuale 60. L'ingresso cura 5 e conserva 65 HP. Alla scadenza naturale torni con 65 HP; se invece il mostro viene sconfitto, torni con 26 HP, cioè il 40% di 65.

La sconfitta della forma non consuma una rinascita della difficoltà, non conclude la run e non incrementa il contatore di morti del profilo. La vera morte può avvenire quando successivamente si esaurisce la Vita normale. Usa l'arrotondamento canonico; se il modello ha solo HP interi, proposta iniziale: il rientro da una riserva positiva lascia almeno 1 HP.

Risolvi il ritorno una sola volta e non applicare anche alla forma normale una seconda copia dello stesso colpo mortale. Colpi successivi e distinti restano validi; non concedere invulnerabilità aggiuntiva senza una regola. Se scadenza, danno e richiesta di cura arrivano nello stesso aggiornamento, usa un ordine deterministico documentato: lo stato vitale deciso dall'autorità prevale, una forma già sconfitta non può curarsi per annullare retroattivamente il ritorno.

Mantieni posizione, equipaggiamento, effetti, timer e risorse secondo le regole della trasformazione. Le dimensioni devono essere imponenti senza nascondere tutti i nemici o bloccare il personaggio nei corridoi. Prevedi animazione d'ingresso, ritorno naturale, ritorno anticipato, colpi e cura; la collisione deve restare coerente con ciò che si vede. Non aggiungere un ripristino di Vita/Oculum o dei cooldown a ogni cambio di forma.

Resta valida la regola generale del level up in combattimento: ripristina Vita e Oculum. Per la gestione delle due barre, interpreta questo evento come ripristino sia della riserva normale sia della Vita mostruosa ai rispettivi massimi aggiornati. È un evento di crescita distinto dall'ingresso nella forma e non riavvia durata o cooldown.

Cooldown espliciti

Usa prima gli eventuali valori canonici. In loro assenza, questi sono VALORI INIZIALI DI BILANCIAMENTO PROPOSTI, modificabili in un'unica configurazione:

Abilità

Recupero proposto

Decorrenza

Mano scheletrica

8 s

Dall'evocazione riuscita.

Mani del Q

14 s

Dall'attivazione riuscita.

Sfera del tasto 1

6 s

Dall'attivazione riuscita.

Slash del tasto 2

3 s

Dall'attivazione riuscita.

Trasformazione del tasto 3

30 s

Dal ritorno alla forma normale, naturale o anticipato.

Cura del tasto 3 durante la forma

2 s

Da ogni conversione riuscita.

Il recupero della cura è distinto dal recupero della trasformazione pur appartenendo allo stesso slot contestuale. Uscire dalla forma non permette di trasformarsi subito di nuovo. Cambio stanza, rimappatura, salvataggio, riconnessione e morte della forma non azzerano i recuperi. Il menu in pausa della partita solo segue il tempo di simulazione; online decide il tempo condiviso della sessione.

Necromante e partite online

Le abilità devono funzionare nella simulazione online reale, oltre che in solo. Se l'architettura esistente non permette ancora una partita roguelite condivisa, implementa il percorso necessario e rendi verificabile l'ingresso di almeno due giocatori nella stessa run; non presentare una dimostrazione locale come multigiocatore completato.

Definisci un'unica autorità della partita per convalidare sblocchi, input, costi, cooldown, bersagli, danni, cure, evocazioni e cambio di forma. Il client invia richieste d'azione e mostra riscontri immediati compatibili con la riconciliazione; non decide da solo HP, premi o morti. Usa la stessa regola di gioco in solo e online, con il tempo di simulazione della sessione per i 6 secondi e i cooldown.

Sincronizza almeno stato e Vita delle due forme, riserva normale, scadenza della trasformazione, conteggio del danno convertibile, recuperi, mano evocata, bersagli immobilizzati e forze della sfera. Gestisci ogni attivazione, evento di danno, cura e ritorno con identità stabile per impedire applicazioni duplicate quando un messaggio viene ritentato. Un client non può usare le abilità di un altro personaggio.

Un ingresso tardivo o una riconnessione deve ricostruire lo stato attuale, non ricominciare i 6 secondi né regalare nuovamente il 5% o la conversione dei danni. Definisci la continuità della sessione in caso di uscita dell'host secondo l'infrastruttura effettiva. Non promettere una migrazione dell'host che non sia implementata e provata. In online aprire l'inventario di un giocatore non mette in pausa il tempo per gli altri.

Applica la distinzione fra giocatori umani e compagni definita per la cooperativa: gli amici entrati nella stanza non consumano i posti IA del Necromante. La mano richiede uno dei suoi tre posti compagno e l'Occhio usa lo slot dedicato. Mostra il proprietario di ogni unità e non trasferire involontariamente danni, cure o cooldown tra due Necromanti presenti nella stessa partita.

Prova almeno due client separati, ritardo di rete controllato, richieste ripetute e riconnessione durante la forma. Confronta Vita, danni, cure, durata, cooldown e sblocchi fra i client e l'autorità; descrivi le condizioni realmente verificate e gli eventuali limiti rimasti. Le animazioni e gli effetti possono essere interpolati, ma il risultato del combattimento deve essere unico.

24-ter. Daphne: anziana inventrice, elettricità e robot

Identità visiva

DAPHNE è un'anziana combattente e inventrice, coerente con l'immagine allegata: viso segnato dall'età, capelli bianchi voluminosi con possibili ciocche colorate, tatuaggi, gilet scuro da lavoro, cinture e utensili, protesi e grandi componenti meccaniche color ottone/ocra. Mantieni riconoscibili età, carattere e silhouette anche nella vista di gioco. Le protesi partecipano ad attacchi, presa e schianto, con articolazioni leggibili.

Adatta questa direzione al tratto expressive ink/dark fantasy approvato per Oculum. Evita una semplice variante del corpo o delle abilità del Necromante: Daphne combatte attraverso meccanica, controllo dello spazio, elettricità e supporto dei robot. Le armi equipaggiate devono essere visibili anche durante salto, presa e uso contemporaneo.

Non sono state indicate nuove condizioni di sblocco per Daphne. Recupera quelle eventualmente già definite nel progetto; se mancano, rendila selezionabile nel prototipo come scelta provvisoria, senza inventare una missione obbligatoria.

Sei slot e cambio arma

Comando predefinito

Azione di Daphne

Clic sinistro

Attacco dell'arma principale.

Clic destro

Scarica elettrica con danno ridotto, capace di colpire anche nemici vicini al primo bersaglio. Durante la doppia arma usa la seconda arma, i cui attacchi possono anche FOLGORARE occasionalmente.

Q

Evoca un robot: piccolo curatore fragile oppure Pawn V2, grande tank con impeti lenti e potenti.

1

Per CINQUE SECONDI permette di usare entrambe le armi tramite i due tasti del mouse.

2

Salto e schianto con i pugni a terra: danno ad area e respinta dei nemici verso l'esterno.

3

Afferra UN nemico, lo attira verso Daphne e gli infligge danno.

Rotellina / 5

Cambio arma. Per Daphne il 4 non esegue questa azione.

E / Shift / Ctrl

Inventario / scatto / movimento lento, come negli altri preset.

Restano sei slot attivi: clic sinistro, clic destro, Q, 1, 2 e 3. La funzione contestuale del clic destro è parte della doppia arma. DURANTE LA DOPPIA ARMA LA SECONDA ARMA PUÒ ANCHE FOLGORARE: l'elettricità occasionale è un effetto dei suoi attacchi, non una settima abilità né una seconda pressione del comando.

1 — Doppia arma per cinque secondi

Daphne usa due armi REALMENTE POSSEDUTE. L'inventario permette di indicare una seconda arma preferita; se non è impostata, scegli la successiva arma valida nell'equipaggiamento rapido e mostrala prima dell'attivazione. Due copie dello stesso modello sono ammesse solo se sono due oggetti distinti. Con meno di due armi disponibili, l'abilità mostra il requisito e non consuma risorse né avvia il recupero.

Nei 5 secondi, clic sinistro attacca con la prima arma e clic destro con la seconda, anche con pressioni contemporanee. Ogni arma conserva danni, tempi d'attacco, eventuali munizioni e cooldown propri. Non raddoppiare automaticamente i bonus passivi dell'intero personaggio. Gestisci esplicitamente l'applicazione di Scudo e Difesa dell'equipaggiamento, senza contare due volte lo stesso oggetto.

FOLGORAZIONE OCCASIONALE DELLA SECONDA ARMA, richiesta confermata anche durante questa modalità:

Gli attacchi eseguiti con il clic destro mantengono il normale danno dell'arma e possono aggiungere una scarica elettrica ridotta, capace di raggiungere nemici vicini. Il danno ridotto riguarda la componente elettrica aggiuntiva, non l'intero attacco dell'arma.

La frequenza «ogni tanto» non contiene una percentuale definita. Come PROPOSTA INIZIALE usa il 20% per attacco della seconda arma che ottiene un impatto valido, con probabilità configurabile. Non significa una folgorazione garantita ogni cinque colpi.

Esegui un solo controllo, al primo impatto valido dell'attacco, dopo clash e schivate. Un fallimento non viene ritirato sugli altri bersagli, proiettili o impatti dello stesso attacco. Anche un attacco ad area o multiplo può generare al massimo una folgorazione con la sua catena; il conteggio dipende dagli attacchi reali, non dai frame.

Usa i coefficienti della componente elettrica a partire dai dati offensivi della seconda arma relativi a quell'attacco, poi applica le difese dei bersagli. Limiti di bersagli e distanze seguono la propagazione dichiarata. La catena non genera altre catene o ulteriori controlli di folgorazione. «Folgora» non aggiunge automaticamente stordimento: eventuali stati elettrici seguono il regolamento.

Questo effetto aggiuntivo non attiva anche l'intera abilità manuale della scarica ordinaria. La modalità di doppia arma contiene la possibilità di folgorare; i tempi dell'arma restano quelli dell'arma e la scarica occasionale non richiede un'altra pressione.

Registra sull'attacco la sua origine dalla seconda arma e l'idoneità alla folgorazione quando viene emesso. Come scelta operativa, un proiettile già sparato mantiene questa proprietà se colpisce dopo la scadenza dei 5 secondi o dopo un cambio arma; non assegnarla retroattivamente a proiettili emessi prima della modalità.

L'autorità della partita determina e registra una sola volta esito casuale e bersagli. Tutti i client riproducono lo stesso evento; una conferma di rete, ripresa o riconnessione non provoca un secondo tiro o un secondo danno.

Interpretazione operativa per il cambio durante questa modalità: rotellina o 5 scorre le alternative per la mano principale mantenendo la seconda arma; se sono disponibili soltanto le due armi impugnate, le scambia fra i due tasti. In nessun caso duplica un oggetto, azzera un recupero o rinnova i 5 secondi. Il giocatore deve vedere quale arma corrisponde a ciascun tasto.

Alla scadenza la mano principale resta quella effettivamente selezionata, la seconda arma viene riposta e il clic destro torna all'assegnazione precedente, normalmente la scarica elettrica. Un attacco accettato prima della scadenza completa soltanto la propria azione secondo le regole ordinarie, senza consentire nuove attivazioni della seconda arma oltre il termine. Non convertire il tasto già tenuto premuto in una scarica involontaria: serve una nuova attivazione valida per l'azione ripristinata.

La durata non si accumula premendo di nuovo 1. Durante i 5 secondi non cambiare dal menu le assegnazioni coinvolte: ripristina il preset precedente in modo coerente. Anche un'Art personalizzata torna allo slot corretto; non reinserire la scarica se era stata sostituita nel grimorio. Il talento funziona con i due tasti effettivamente rimappati, mantenendo il mouse come preset.

Le tre armi iniziali richiedono pose compatibili: spada e scudo costituiscono un equipaggiamento, i guanti un altro. Non contare uno scudo come seconda arma indipendente. Supporta le combinazioni effettivamente previste, adattando l'animazione alle protesi di Daphne e mostrando eventuali requisiti reali nell'inventario.

Clic destro — Scarica elettrica che si propaga

Fuori dalla doppia arma, il clic destro produce un attacco elettrico diretto con danno inferiore al normale attacco principale di riferimento e propagazione verso nemici vicini al bersaglio colpito. L'indicazione «meno danni» riguarda il singolo bersaglio; la capacità di colpirne più di uno è il vantaggio dell'abilità.

Definisci nei dati coefficiente del primo impatto, danno dei salti, distanza fra bersagli e limite della propagazione. Ogni nemico può essere colpito una volta per scarica salvo una modifica esplicita; evita rimbalzi infiniti e danni moltiplicati per frame. La linea elettrica visibile deve corrispondere ai bersagli effettivi e rispettare ostacoli e regole delle magie. Alleati, robot e Daphne non vengono danneggiati senza una regola esplicita di fuoco amico.

2 — Salto e schianto

Anima preparazione, salto e impatto dei pugni sul terreno. Al contatto con il suolo, applica una volta il danno a tutti i nemici nell'area e una respinta RADIALE: ciascun nemico viene spinto lontano da Daphne, non verso un'unica direzione arbitraria. Mostra area e impatto prima che il danno risulti inevitabile.

La destinazione del salto deve essere valida e raggiungibile secondo le sue regole. Il salto non concede automaticamente invulnerabilità, passaggio attraverso muri o attraversamento di ogni voragine. La respinta si arresta sugli ostacoli e non incastra i nemici fuori dalla mappa; eventuali urti aggiuntivi seguono regole esplicite.

3 — Presa e trascinamento

Seleziona un singolo bersaglio valido nella direzione di mira, con portata finita, e rendi riconoscibile il collegamento della presa. Infliggi il danno previsto una volta al contatto riuscito e attira il nemico fino a una posizione sicura davanti a Daphne, senza sovrapporne i corpi o trascinarlo attraverso muri.

Il testo della richiesta non completa la distanza della presa: non considerarla illimitata. Recupera il valore canonico oppure usa una proposta configurabile; per il primo bilanciamento si può partire da 8 metri. Dimensioni, resistenze allo spostamento e immunità dichiarate dei nemici restano significative; un nemico resistente al trascinamento può comunque subire il danno se il colpo è valido. Non inventare immunità universali dei boss.

Q — Robot piccolo oppure Pawn V2

INTERPRETAZIONE DICHIARATA: «può nascere» indica inizialmente un'evocazione CASUALE fra due varianti, e Pawn V2 è il nome del robot grande. La selezione manuale non è una regola già confermata. Mantieni la modalità di selezione configurabile se il progetto contiene indicazioni diverse.

Variante

Ruolo e comportamento

Robot piccolo

Curatore fragile, con poca Vita. Segue Daphne e la cura periodicamente quando è viva, ferita e nel raggio utile. Continua finché non viene ucciso; non scade dopo pochi secondi. Non resuscita Daphne e non cura automaticamente tutto il gruppo.

Pawn V2

Robot grande da prima linea, molto resistente. Si avvicina ai nemici, li ingaggia e compie impeti/assalti lenti ma potenti, con preparazioni visibili e un recupero reale. «Tank» significa capacità di sostenere il combattimento, non immunità a ogni danno.

In mancanza di pesi già definiti, usa come proposta iniziale 50% curatore e 50% Pawn V2, in dati modificabili. L'esito viene stabilito dall'autorità della partita mediante il flusso casuale del gameplay e resta associato all'evento di evocazione. Un messaggio ritentato o un caricamento non esegue una nuova estrazione. Un tentativo rifiutato per risorse, cooldown, spazio o capienza non consuma risorse e non cambia l'esito casuale futuro.

Ogni attivazione riuscita crea UN robot. Sia i robot curativi sia quelli combattenti occupano un posto nei TRE posti compagno; l'Occhio resta separato. Come scelta operativa iniziale possono coesistere più robot, anche delle due varianti, solo entro quel limite complessivo. Non aggiungere un esercito oltre la capienza e non cancellare un alleato per fare spazio senza scelta esplicita.

I robot vivi seguono nei cambi stanza; quelli morti non riappaiono automaticamente. Ricrearli richiede una nuova evocazione valida. Il curatore cerca una posizione utile evitando di bloccarsi dietro un muro; Pawn V2 trova percorsi compatibili con le proprie dimensioni. Definisci una procedura di transizione stanza che mantenga posizioni valide, HP e recuperi senza bloccare il gruppo nei passaggi segreti. Concludendo la run, i robot evocati non diventano automaticamente compagni permanenti.

Vita, cure, danni, difese, velocità, raggio e tempi degli attacchi provengono dai dati Oculum; dove mancano, inserisci proposte giocabili dichiarate. Le cure si applicano su intervalli di simulazione e non una volta per frame, non superano i massimi e sono attribuite al robot corretto. Gli attacchi del tank seguono lo stesso sistema di danni e clash degli altri attacchi compatibili.

Recuperi e funzionamento online

Se non esistono valori canonici, usa questa PROPOSTA INIZIALE DI COOLDOWN, centralizzata e modificabile:

Abilità

Recupero proposto

Scarica elettrica ordinaria

1,5 s dall'attivazione accettata

Q, robot

20 s dall'evocazione riuscita

1, doppia arma

20 s dalla conclusione dei 5 secondi

2, schianto

12 s dall'attivazione accettata

3, presa

8 s dall'attivazione accettata

Un'azione rifiutata prima di cominciare non costa; un attacco realmente eseguito ma mancato segue il normale costo e recupero. Una presa o uno schianto iniziati non diventano gratuiti perché il nemico si sposta. Le armi della modalità doppia conservano i propri tempi senza usare il cooldown della scarica elettrica.

Applica a Daphne la stessa autorità online prevista per gli altri personaggi. Sincronizza armi realmente equipaggiate, scadenza dei 5 secondi, ripristino del clic destro, bersaglio della presa, impatto e respinta dello schianto, catena elettrica, folgorazioni occasionali della seconda arma e variante/stato dei robot. Valida una sola volta ogni danno, cura ed evocazione. Una riconnessione riprende il tempo residuo e gli stessi robot senza nuove estrazioni, cure duplicate o reset dei cooldown.

25. Scroll, apprendimento e Oculum Art rare

Le scroll/pergamene possono essere trovate e conservate nell'inventario. Prima dello sblocco il giocatore vede SOLTANTO IL NOME; descrizione, effetto e informazioni che rivelano il contenuto restano nascosti.

Distingui:

Probabilità di trovare la scroll.

Rarità del contenuto.

Probabilità di apprenderla/sbloccarla.

Uso della scroll equipaggiata.

Assegnazione di un'Art già appresa al grimorio.

Usa le SOLITE PERCENTUALI di Oculum per il meccanismo corretto, cercandole nel codice e nel manuale. Non usare automaticamente la tabella degli Occhi dei Caduti per l'apprendimento delle scroll.

Il primo personaggio ha il DOPPIO DELLA PROBABILITÀ DI APPRENDIMENTO. Questa interpreta “doppio delle proprietà” come probabilità, non come danno:
probabilità del primo personaggio = min(100%, 2 × probabilità ordinaria risultante).

Applicala una sola volta. Se la probabilità ordinaria fosse 20%, diventerebbe 40%; questo esempio non stabilisce la probabilità base. Uno sblocco già garantito rimane garantito.

Le Oculum Art si possono trovare anche esplorando, MOLTO RARAMENTE. Recupera le tabelle esistenti oppure definisci una proposta di rarità in configurazione; non trattarle come bottino comune.

Al successo, registra l'Art e rendila assegnabile al grimorio o agli slot sostituibili degli altri personaggi. Consumo, costi, requisiti e fallimenti devono seguire le regole pertinenti. Uno sblocco con punti non deve pagare nuovamente o ritirare senza motivo quando lo si equipaggia.

Se la tabella canonica non è reperibile, segnala esattamente il dato mancante. Mantieni disponibile il resto del gioco e non dichiarare “solite percentuali” una tabella inventata.

Salva pergamene chiuse, tentativi effettuati, apprendimenti e assegnazioni. Nessuna ricompensa ripetuta ricaricando o premendo rapidamente Q.

26. Combattimento Oculum in tempo reale

Usa statistiche, danni, difese, scudi, resistenze, vulnerabilità, stati, stati di forza, costi Oculum e sottotratti effettivi del progetto.

Adatta le durate espresse in turni a tempi e cooldown con una regola unica e documentata. Questa conversione riguarda la modalità solo; la turnistica della campagna VTT deve mantenere il proprio funzionamento.

Il combattimento deve comprendere:

Movimento e mira reattivi.

Collisioni affidabili e attacchi leggibili.

Corpo a corpo, proiettili, armi da lancio e magie.

Anticipazioni degli attacchi nemici, recupero e finestre di risposta.

IA differenziata per creature, alleati, élite e boss.

Stati con applicazione, durata, cumulabilità e rimozione coerenti.

Combinazioni tra Art, armi e power up supportate da regole esplicite.

Ogni attacco valido deve avere un'identità. Un proiettile o una sovrapposizione non deve applicare danno e ritirare probabilità a ogni fotogramma. Per gli attacchi multipli definisci intervalli e numero di colpi consentiti.

Ogni attacco deve distinguere preparazione, impatto attivo e recupero. La simulazione usa passi temporali fissi e controlli di collisione adeguati anche a proiettili, scatti e cadute veloci. Le durate reali non cambiano con il numero di fotogrammi.

27. Clash: attacchi simultanei, danno annullato e respinta

Quando DUE ATTACCHI COMPATIBILI si incontrano nello stesso momento valido, si verifica un CLASH: NESSUNO DEI DUE COLPI INFLIGGE DANNO e i due combattenti vengono respinti, creando distanza.

La simultaneità riguarda l'IMPATTO, non la pressione del pulsante. Deve esserci un contatto geometrico valido tra gli attacchi, non soltanto due animazioni avviate.

Esempio da implementare come verifica:

Ascia: avvio a t = 0; impatto dopo 1,6 secondi.

Spada: avvio a t = 0,7; impatto dopo 0,9 secondi.

Entrambe arrivano a t = 1,6: se si incontrano possono produrre un clash.

Se entrambe partono a t = 0, la spada arriva a t = 0,9 e l'ascia a t = 1,6: non esiste un clash automatico.

1,6 E 0,9 SONO SECONDI DI ATTACCO, NON METRI DI RESPINTA.

Usa una piccola finestra temporale centralizzata; se manca una regola, 50 ms è una proposta iniziale da verificare. La distanza di respinta è un altro parametro: per esempio 1,5 metri per combattente come proposta provvisoria, indipendente dai tempi dell'esempio.

Raccogli gli impatti del passo di simulazione, risolvi i clash prima del danno e applica soltanto i colpi ancora validi. Se la tolleranza attraversa due passi, gestiscila senza applicare prematuramente uno dei danni.

Il clash annulla i danni e gli effetti che richiedono quei colpi riusciti; non annulla attacchi estranei. Non deve consumare una schivata Oculum o interrompere una levitazione come se il colpo fosse andato a segno.

Respinta:

Direzioni opposte e distanza espressa in metri di gioco, con conversione unica in coordinate.

Arresto davanti a muri e ostacoli, senza attraversarli o uscire dall'arena.

Una sola applicazione per partecipante e clash.

Recupero, feedback sonoro e animazione leggibili.

Definisci quali attacchi possono scontrarsi: almeno quelli fisici compatibili. Proiettili, Art, aree e pericoli ambientali usano regole esplicite, senza annullamento universale.

La velocità dell'arma deve restare significativa, ma anche un'arma lenta può produrre un clash con il giusto tempismo.

28. IA dei nemici capace di adattarsi al combattimento

Voglio un'IA di qualità, con nemici differenti che IMPARANO DAL MODO IN CUI COMBATTO.

Implementa adattamento reale, verificabile e leggero attraverso osservazioni del comportamento:

Distanza preferita, uso di corpo a corpo o proiettili.

Attacchi e combinazioni ripetuti.

Direzioni e frequenza degli scatti.

Uso di coperture, oggetti ambientali, cure ed evocazioni.

Tendenza a isolare nemici o affrontare gruppi.

Dopo osservazioni sufficienti, aggiorna gradualmente la scelta tra tattiche disponibili: aggiramento, distanza, pressione, attesa, attacchi sfalsati, gestione dei varchi e cambio di bersaglio. Non limitarti ad aumentare Vita o danni.

Mantieni l'identità della creatura: percezione, aggressività, intelligenza, repertorio, limiti, reazioni e comportamento sociale vengono dal catalogo. Un nemico semplice e un boss non devono adottare le stesse strategie.

L'IA può reagire soltanto a informazioni che ha potuto osservare. Niente lettura dei tasti prima che il personaggio agisca, conoscenza di azioni future o contrattacchi istantanei impossibili. Riconoscere uno stile non significa diventare immune a quello stile.

Consenti al giocatore di cambiare tattica e sorprendere l'avversario. Usa soglie, limiti all'adattamento e memoria che si aggiorna; la difficoltà modifica pressione e rapidità entro valori dichiarati.

Esegui l'adattamento nel motore di simulazione, senza dipendere da un servizio AI esterno. In solo lo esegue la partita locale; online lo decide l'autorità della sessione, con uno stato coerente per tutti i client. Salva contatori, pesi e stato casuale nella run: caricare la stessa partita o usare una rinascita al suo interno conserva ciò che i nemici hanno già imparato.

Durata della memoria secondo la difficoltà

La nuova regola riguarda LA MEMORIA ADATTIVA DEI NEMICI. Non cambia la persistenza di personaggi, grimori, sblocchi, contatori delle morti, storia e progressione permanente.

Difficoltà della run

Memoria dell'IA

Molto facile

Si aggiorna e resta disponibile soltanto nella run attuale. Un nuovo tentativo riparte senza gli apprendimenti precedenti.

Facile

Come Molto facile: memoria limitata alla singola run.

Medio

Memoria limitata alla singola run, compresi tutti i suoi stage e salvataggi.

Difficile

Conserva gli apprendimenti fra tentativi e usali nelle run successive di questa difficoltà.

Oculum

Conserva gli apprendimenti fra tentativi e usali nelle run successive di questa difficoltà.

Nelle prime tre difficoltà, aprire un'altra stanza, ricaricare, riconnettersi o rinascere non costituisce una nuova run e non azzera la memoria. Avviare un vero nuovo tentativo crea invece una nuova memoria, senza importare apprendimenti da run precedenti o da modalità più difficili.

Per Difficile e Oculum, interpretazione iniziale dell'ambito: archivio persistente separato per profilo, personaggio e difficoltà, con versione delle regole. I sei slot di salvataggio non costituiscono una memoria globale condivisa indistintamente. Le modalità inferiori non leggono né aggiornano questo archivio e non lo cancellano quando vengono giocate.

Alla creazione di una run difficile conserva una fotografia della memoria iniziale; durante la run aggiorna soltanto il suo stato. Registra nell'archivio persistente le nuove osservazioni una sola volta tramite checkpoint identificati dalla run e dall'intervallo osservato. Ricaricare un checkpoint, riconnettersi o ripetere un messaggio non deve sommare nuovamente l'intera memoria né moltiplicare il peso degli stessi eventi.

Il regime di persistenza dipende dalla difficoltà della run stabilita all'avvio, non da una preferenza locale del client. Non cambiarlo a metà run per importare in Difficile apprendimenti ottenuti in Facile o trasferire quelli di Oculum in Medio. Se il progetto consente il cambio di difficoltà durante una run, documenta la gestione: come scelta iniziale, una run con difficoltà modificata mantiene soltanto la propria memoria temporanea e non aggiorna gli archivi persistenti.

Online, le osservazioni su un giocatore restano attribuite a quel giocatore e al personaggio effettivamente osservato; l'apprendimento aggregato sul gruppo resta nella sessione. Un partecipante non scrive la memoria personale degli altri. La riconnessione recupera l'identità corretta e non crea un nuovo bersaglio privo di storia per eludere l'adattamento.

Anche la memoria persistente conserva limiti, decadimento delle osservazioni vecchie e capacità proprie di ogni specie. I nemici possono ricordare abitudini, ma non ottengono conoscenza di input futuri, danni illimitati o immunità automatiche. Nel debug rendi visibili origine e durata degli apprendimenti per verificare che le difficoltà normali non ereditino quelli persistenti.

Verifica due stili di combattimento diversi nello stesso scenario e mostra, nei dati di debug, quali decisioni cambiano e perché.

29. Boss: La tua Luce e La tua Ombra

Inserisci fra i BOSS:

LA TUA LUCE: il tuo personaggio in una versione luminosa.

LA TUA OMBRA: il tuo personaggio in una versione molto più scura.

Devono conservare sagoma, equipaggiamento e dettagli riconoscibili del protagonista. La luminosità non deve accecare e l'ombra non deve diventare illeggibile sullo sfondo.

HANNO LE TUE STESSE SKILL. Interpretazione operativa: all'inizio dell'incontro crea una fotografia indipendente del personaggio, con sei azioni equipaggiate, talento innato, equipaggiamento e modificatori pertinenti. Non attribuire automaticamente tutte le Art non equipaggiate del grimorio.

Il boss usa realmente queste azioni con risorse e cooldown propri. Non cambia skill istantaneamente per contrastare ogni decisione successiva del giocatore e non modifica la scheda originale.

Il talento innato conserva identità ed eventuali proprietà passive; la sua azione attiva è utilizzabile dal boss soltanto se presente nei sei slot copiati. Se il giocatore ha sostituito duplicazione o levitazione, non aggiungerla come settima abilità. Il boss deve avere le stesse azioni attive effettivamente disponibili al protagonista all'inizio dell'incontro.

Sono BOSS, non cloni al 2% di Vita. Vita, risorse e altri parametri del boss seguono il bilanciamento dichiarato di stage e difficoltà; la copia delle skill non impone statistiche identiche a quelle del protagonista.

Distingui i loro comportamenti attraverso l'uso delle stesse capacità e l'IA, senza sostituirle con un set estraneo. L'aspetto chiaro/scuro non cambia automaticamente l'elemento di tutti gli attacchi.

Le abilità di evocazione copiate rispettano un tetto esplicito: fino a tre compagni del boss, con massimo due cloni al loro interno; l'Occhio separato soltanto se previsto dalle capacità disponibili. Nessuna clonazione ricorsiva o ricompensa boss attribuita ai suoi duplicati.

Se viene copiato il personaggio della levitazione, il boss deve riflettere, essere interrompibile dal melee e generare l'esplosione secondo le stesse regole, con parametri derivati dalla sua build.

Se viene copiato il Necromante con l'abilità del 3 equipaggiata, il boss usa la stessa trasformazione di 6 secondi, cura iniziale del 5%, conversione del 15%, riserva normale e ritorno con il 40% della riserva in caso di sconfitta della forma. Le due funzioni del 3 restano un solo slot, con recuperi distinti. Non attribuire lo sblocco del primo boss né il loot finché non viene sconfitto il boss nella sua forma normale; la sola fine della trasformazione non completa l'incontro.

Se viene copiata Daphne, conserva le due armi e le assegnazioni effettive. La doppia arma dura 5 secondi e sostituisce temporaneamente l'azione secondaria con le stesse regole; la seconda arma del boss conserva anche la probabilità di folgorazione occasionale, senza lanciare in aggiunta l'intera abilità manuale della scarica. Presa, schianto, propagazione e robot conservano i rispettivi limiti e cooldown. I robot del boss appartengono alla fazione ostile, il curatore cura quel boss e la loro Vita/IA è indipendente dai robot di Daphne. Si applica il budget dei compagni del boss, senza evocazioni infinite.

Salva snapshot, stato del boss, evocazioni e adattamento. La ricompensa boss si ottiene una sola volta: 5 Oculum spento + 1 cristallo Ascension Dust casuale, oltre agli eventuali drop distinti previsti.

30. Fortuna e probabilità di schivata

Aggiungi una probabilità di schivata derivata dalla Fortuna, visibile nell'interfaccia.

È distinta dalle schivate Oculum consumabili:

Schivata da Fortuna: controllo probabilistico sui colpi idonei.

Schivata Oculum: risorsa con quantità intera, governata dalle proprie regole.

Prima cerca la formula canonica. Se manca, usa questa PROPOSTA DI BILANCIAMENTO iniziale, centralizzata e modificabile:

probabilitàSchivata = limita(FortunaEffettiva × 1%, minimo 0%, massimo 25%)

Esempi: Fortuna 0 → 0%; Fortuna 8 → 8%; Fortuna 20 → 20%; Fortuna 40 → 25%.

FortunaEffettiva deve essere un valore numerico coerente con il sistema. Non interpretare automaticamente un dado d20 come 20 punti Fortuna.

Esegui un solo controllo per evento di colpo idoneo. Rispetta l'ordine canonico tra schivata, difesa, scudo e danno. Non consumare una schivata Oculum se il colpo è già evitato o non può colpire.

Indica nel feedback cosa è successo. I danni periodici o inevitabili devono rispettare i propri flag, senza diventare automaticamente schivabili.

Lo scatto su Shift è una terza meccanica distinta: il movimento può evitare geometricamente un attacco, ma non è automaticamente una schivata Oculum né una garanzia di invulnerabilità. Un colpo annullato da un clash o riflesso dalla levitazione non deve consumare una schivata Oculum.

31. Gruppo, reclutamento e Occhi dei Caduti

Limite del gruppo in solo e delle unità autonome associate a ciascun PG in cooperativa:

1 protagonista.

Massimo 3 compagni.

1 Occhio dei Caduti in uno slot dedicato.

Nei tre posti compagno possono entrare NPC, mostri buoni e fino a DUE altri personaggi salvati. I due personaggi occupano posti del limite di tre.

Gli amici che hanno joinato la stanza e giocano controllando i propri PG occupano i posti umani della cooperativa, non questi posti compagno. Applica limiti e attribuzione per proprietario; il gruppo online complessivo comprende i giocatori umani e le rispettive unità. Il numero massimo di giocatori umani deve essere dichiarato e verificato, non dedotto dal limite di tre compagni.

Il reclutamento deve rispettare allineamento e comportamento delle creature. Ricorda che le fate sono malvage.

Ogni NPC effettivamente sbloccato deve diventare utilizzabile come personaggio. Riutilizza la sua scheda oppure crea un adattamento giocabile coerente: l'assenza di una scheda preesistente non annulla lo sblocco. Incontrare un NPC e sbloccarlo sono eventi distinti. Salvare un NPC destinato a morire deve poter produrre questo sblocco e conseguenze narrative.

A ogni level up rendi possibile spendere 1 punto livello per un alleato temporaneo. Usa o definisci chiaramente la relativa risorsa, senza consumare in silenzio un altro tipo di punto.

Interpretazione provvisoria: il temporaneo segue la run finché resta vivo; se muore in una stanza non ricompare nella successiva. Non persiste nel nuovo tentativo. Se il regolamento ne limita la durata alla sola stanza, conserva quella regola e indicalo nell'interfaccia.

Cloni, temporanei ed evocazioni autonome combattenti O DI SUPPORTO rispettano il limite compagni. Entrambi i robot di Daphne, compreso il piccolo curatore, occupano un posto. A gruppo pieno proponi una scelta esplicita; nessuna cancellazione silenziosa di un alleato.

Integra gli Occhi dei Caduti con rarità, drop, sintonia/legame, evocazione, evoluzione, Art e rinascita secondo le regole attuali del progetto. Non trasformarli in semplici pet cosmetici.

32. Evocazioni come sistema di combattimento

Implementa EVOCAZIONI REALI con creature visibili, animate, bersagliabili e capaci di agire. Oltre ai cloni iniziali e all'Occhio dei Caduti, devono esistere Art o effetti di evocazione ottenibili nella partita.

Per ogni evocazione definisci origine, creatura, costo, cooldown, Vita, danni, difese, durata, comportamento e condizione di scomparsa secondo le regole Oculum. Se un dato manca, registra una proposta configurabile.

Distingui:

Compagni reclutati.

Cloni del primo personaggio.

Alleati temporanei ottenuti con punto livello.

Creature evocate da Art o oggetti.

Robot curativi e combattenti di Daphne, con le stesse regole di capienza delle altre unità autonome.

L'unico Occhio dei Caduti, che mantiene il suo slot dedicato.

Ogni evocazione alleata autonoma combattente O DI SUPPORTO occupa uno dei TRE posti compagno DEL PROPRIETARIO, insieme a reclutati, cloni e temporanei. Il limite di due cloni resta aggiuntivo. Gli effetti grafici o le aree prive di un'unità autonoma non occupano un posto. In cooperativa i PG umani degli amici non consumano questa capienza.

A capienza piena mostra una scelta esplicita di sostituzione o rifiuta l'evocazione senza consumare risorse. Non cancellare automaticamente un compagno.

Implementa inseguimento, attacco, distanza utile, gestione degli ostacoli, passaggi segreti e cambio stanza. Se la durata consente di proseguire, l'evocazione viva segue; una creatura morta non ricompare per il solo cambio di mappa.

Attribuisci correttamente danni e uccisioni al proprietario, senza duplicare EXP o loot. Gli alleati e le evocazioni congedate non producono ricompense nemiche.

Prevedi sinergie leggibili tra Art, armi, power up ed evocazioni. Limita catene ricorsive, generazioni infinite e sovrapposizioni ingestibili. Le evocazioni ostili usano budget e limiti coerenti con incontro e difficoltà.

33. Tre equipaggiamenti iniziali

Alla partenza sono sbloccate queste tre scelte:

Equipaggiamento

Bonus

Comportamento

Boomerang in legno

+5 danni

Colpisce lungo il percorso e traccia un arco verso il nemico più vicino

Spada e scudo

+6 danni, +6 Scudo, +1 Difesa

Attacco corpo a corpo e protezione effettiva

Guanti d'arme giganti

+10 danni

Colpi ravvicinati pesanti, leggibili e animati

I bonus si sommano nel punto corretto della formula, una sola volta.

Per il boomerang gestisci andata, arco, ritorno, bersaglio assente, ostacoli e limiti dei colpi sullo stesso nemico. Non deve moltiplicare il danno per il numero di frame.

Armi e armature devono VEDERSI sul personaggio in tutte le direzioni e animazioni. Usa ancoraggi, stratificazione e pose coerenti; niente scudi fluttuanti, armi invertite, pezzi scollegati o equipaggiamento che sparisce durante l'attacco.

Conserva elenco e ordine dell'equipaggiamento rapido, arma attiva e seconda arma preferita di Daphne. Il cambio con rotellina/4, oppure rotellina/5 per Daphne, aggiorna modello, animazioni, dati e HUD nella stessa operazione. Un oggetto presente nell'inventario non è automaticamente in uso e non applica bonus attivi senza una regola. La modalità di Daphne mostra due armi per 5 secondi, mantenendo cooldown e proprietà dei singoli oggetti.

34. Giornata, fame, stagioni e riposi

Una giornata dura NOVE ORE DI GIOCO, equivalenti a TRENTA MINUTI REALI.

Fase

Durata reale

Mattina

10 minuti

Mattina inoltrata

2 minuti

Pomeriggio

6 minuti

Pomeriggio inoltrato

2 minuti

Notte

9 minuti

Prima mattina

1 minuto

Totale 30 minuti: conserva esattamente questa scansione. Non convertirla in una giornata ordinaria di 24 ore.

Illuminazione, suoni, incontri e opportunità possono dipendere da fase e stagione. Salva il tempo residuo e il giorno corrente.

Bisogna mangiare DUE VOLTE AL GIORNO. Implementa cibo, pasti conteggiati, fame e conseguenze coerenti, con avvisi chiari. Riutilizza le regole esistenti; se mancano, documenta il modello proposto.

Pause, menu bloccanti e sospensione dell'app in solo non devono far morire il personaggio fuori controllo. Sonno e riposo avanzano il tempo in modo esplicito e applicano correttamente pasti, scadenze e stati.

Dopo il completamento dello stage e la gestione della crescita, permetti di scegliere se dormire, fare un riposo breve presso uno shop disponibile o proseguire, secondo costi e condizioni. Il level up in combattimento non deve obbligare a interrompere l'azione con un negozio.

35. Cinque difficoltà

Difficoltà

Caratteristica richiesta

Molto facile

Tre rinascite; memoria adattiva dell'IA limitata alla run

Facile

Una rinascita e achievement aggiuntivi che attivano eventi; memoria dell'IA limitata alla run

Medio

Più eventi possibili; memoria dell'IA limitata alla run

Difficile

Esaurire completamente Oculum può causare malattia; memoria dell'IA persistente fra tentativi

Oculum

Tutto estremamente più difficile; memoria dell'IA persistente fra tentativi

Per rendere finito il tentativo, interpreta provvisoriamente le rinascite come TRE PER RUN in Molto facile e UNA PER RUN in Facile. Mostra quelle rimaste. Gli altri livelli non ricevono rinascite gratuite, salvo effetti canonici specifici.

Gli incontri devono dipendere dalla difficoltà mediante budget, composizione, comportamento, élite, risorse e rischi, oltre agli eventuali moltiplicatori numerici.

La malattia si controlla quando Oculum passa da un valore positivo a zero, una volta per esaurimento, senza tiri continui mentre rimane a zero. Probabilità, condizioni e cure devono essere canoniche o proposte dichiarate.

La difficoltà Oculum deve essere estrema ma leggibile: conserva la possibilità di comprendere gli attacchi e le cause della sconfitta.

36. EXP, crescita e power up

Integra EXP e avanzamento secondo il sistema Oculum.

Quando sali di livello DURANTE IL COMBATTIMENTO, Vita e Oculum si riempiono completamente sui massimi aggiornati. L'effetto avviene una volta per level up, non a ogni riapertura della schermata.

Mantieni funzionanti sottotratti, crescita, abilità e stati di forza. Mostra chiaramente cosa migliora e cosa può essere speso.

I power up raccolti DURANTE UNA RUN durano per tutta quella run. Definisci accumulo, limiti e incompatibilità; non trasformarli accidentalmente in bonus permanenti.

L'Ascension Dust permette di potenziarsi secondo le regole del progetto. Distingui chiaramente gli usi e le risorse, evitando che “punti livello”, “punti per Art” e “Oculum spento” vengano scambiati tra loro.

37. Loot, Obser, Vitalium e progressione permanente

Gli Obser vengono raccolti automaticamente quando il protagonista entra nel loro raggio. Anima l'attrazione e accredita ogni raccolta una sola volta. Adatta gli shop della campagna solo al catalogo Oculum.

Ricompense richieste:

Nemico sconfitto

Ricompensa

Normale

1 Oculum spento

Élite

3 Oculum spento + 1 Ascension Dust

Boss

5 Oculum spento + 1 cristallo Ascension Dust casuale

Conserva la distinzione tra Dust ordinaria e cristallo casuale. La tua Luce e La tua Ombra sono BOSS e seguono la ricompensa boss. I loro duplicati non sono nuovi boss da cui ottenere quella ricompensa.

Gran Scostumato nei campi e Forest Demon nella foresta sono ÉLITE: applica 3 Oculum spento + 1 Ascension Dust, oltre agli eventuali drop canonici distinti. Non assegnare loro anche la ricompensa dei boss per lo stesso incontro. Per i miniboss usa il catalogo o dichiara la tabella proposta.

A fine tentativo il giocatore riceve Oculum spento in rapporto a quanto è avanzato. Nel riepilogo separa ricompense delle uccisioni ed eventuale bonus di avanzamento: nessun doppio accredito della stessa valuta.

Usa identificatori persistenti per uccisioni, raccolte, acquisti e ricompense finali. Una ripresa del salvataggio non deve ripagare un boss o uno sblocco.

Vitalium:

Con poca Vita compare più spesso, con una probabilità limitata e configurata.

Un power up della run può convertirlo in VITALIUM RIDEFINITO.

Una progressione acquistabile a fine partita può rendere permanente la conversione dei futuri drop in Vitalium ridefinito.

Conserva nomi ed effetti canonici, distinguendo conversione temporanea e sblocco permanente.

Prevedi miglioramenti permanenti, tra cui +Vita iniziale e +Oculum iniziale. Mostra costo, livello, beneficio e limiti. Il personaggio resta riutilizzabile dopo la morte.

38. HUD e chiarezza

Mostra almeno:

Livello del personaggio.

Barre Vita e Oculum con valori leggibili e percentuali.

Due informazioni secondarie compatte sotto le barre.

Sei slot con tasti, icone, stato, costi e cooldown.

Schivate Oculum come singolo numero.

Probabilità di schivata da Fortuna.

Obser, risorse, fase del giorno, pasti, compagni e Occhio quando pertinenti.

Le tre quest del piano, i rispettivi achievement, progressi e stato delle ricompense; distingue il premio maggiore senza aprire finestre obbligatorie durante gli attacchi.

Azione contestuale di R, stato dell'incontro e disponibilità del portale; eventuale moneta richiesta e destinazione.

In cooperativa, amici nella run, proprietari delle unità, stato di connessione e conferme per il passaggio condiviso.

Le “altre due” statistiche sotto le barre non sono identificate con certezza: recuperale dal progetto o rendile selezionabili. Usa percentuali solo quando esiste una base sensata; non inventare una percentuale di Difesa se la statistica non ha un massimo.

Mantieni il centro dello schermo libero, i pannelli secondari compatti e i testi leggibili. Nessun HUD enorme che nasconde gli attacchi.

Nel grande dungeon aggiungi una minimappa con esplorazione progressiva e marcatori personali. Mostra luoghi visitati e riferimenti scoperti, mantenendo ignoti uscita e segreti finché il giocatore non li scopre.

Mostra recupero dello scatto, durata della levitazione e disponibilità dei talenti. Il feedback del clash deve distinguersi da danno, schivata e scudo. Mantieni leggibili La tua Luce e La tua Ombra anche su sfondi chiari o molto scuri.

Per il Necromante mostra il 3 contestuale, i 6 secondi residui e il recupero pertinente. Durante la forma mostruosa distingui la barra attiva dalla Vita normale conservata, in modo compatto. L'anteprima del ritorno anticipato mostra il 40% della riserva; la cura disponibile indica il 15% dei danni realmente convertibili, limitato alla Vita mancante. Mantieni identiche regole e informazioni nei client online.

Mostra l'arma attiva e il comando di cambio corretto per il personaggio: 4 oppure 5 per Daphne, oltre alla rotellina. Per Daphne mostra inoltre le due armi associate ai tasti durante la modalità, i 5 secondi residui e i robot vivi con tipo e Vita. L'icona del clic destro passa dalla scarica alla seconda arma, indicando la possibilità di folgorazione occasionale, e torna correttamente alla fine. Nella scelta della difficoltà indica se la memoria dei nemici resta nella run o può proseguire fra tentativi.

39. Salvataggi, prestazioni e qualità

Salva almeno personaggio, aspetto, grimorio, sei slot, equipaggiamento, inventario, pergamene, team, cloni, evocazioni, Occhio, seed, RNG, ambientazione, stanza, EXP, risorse, tempo, fame, difficoltà, rinascite, storia e sblocchi.

Conserva anche incontri completati, ondate, stato degli élite, percorso esplorato, marcatori, muri segreti scoperti, offerte dei negozi, sconti e scelta delle ricompense. La rigenerazione della mappa non deve azzerare o replicare questi eventi.

Usa scritture atomiche, versioni dello schema e recupero dall'ultimo stato valido. Autosalva nei punti appropriati e permetti di riprendere una run senza duplicare ricompense.

Ottimizza concretamente:

Caricamento delle risorse necessarie alla scena.

Riutilizzo di proiettili ed effetti.

Atlanti e animazioni efficienti.

Culling degli elementi fuori vista.

Aggiornamento dell'interfaccia solo quando cambia lo stato.

Limiti a particelle, luci, audio e numero di entità.

Qualità adattabile e memoria controllata.

Il gioco solo deve poter funzionare senza una connessione continua se l'architettura lo permette. Mantieni i servizi online separati dalle dipendenze essenziali della partita.

Misura tempi di frame e memoria su scenari rappresentativi. Punta a fluidità stabile e verifica anche scene con gruppo completo, cloni, Occhio, nemici e magie. Dichiara i dispositivi realmente provati.

Riduci peso inutile e duplicazioni senza eliminare contenuti richiesti, funzioni o salvataggi.

Salva inoltre oggetti distrutti, loot ambientale già prodotto, cadute in corso, stato di scatto e levitazione, snapshot dei boss specchio, memorie comportamentali dell'IA e sblocco ottenuto alla fine della prima run. Riprendere non deve resettare un cooldown o riattivare un'esplosione già avvenuta.

Per il Necromante conserva anche contatore persistente delle morti, sblocco ottenuto, eventuale prima vittoria sul boss in Difficile, riserva della Vita normale, Vita della forma mostruosa, durata residua, danni convertibili, cooldown distinti e identità degli eventi già applicati. Un caricamento o rientro online non costituisce una nuova attivazione, cura, morte o ricompensa.

Per Daphne conserva ordine delle armi rapide, arma attiva, seconda arma, assegnazione da ripristinare, durata residua della doppia arma, recuperi per arma e per abilità, robot vivi/morti e loro variante, Vita e prossima cura. Conserva anche presa, salto/atterraggio e scariche in corso secondo le regole degli eventi di combattimento, senza rieseguire gli impatti già applicati. Per la folgorazione occasionale conserva origine/idoneità degli attacchi emessi e controllo già eseguito o ancora da eseguire, con il risultato già deciso: un caricamento non ritenta un esito fallito.

Separa il salvataggio della memoria della run dall'archivio persistente dell'IA per Difficile/Oculum. Salva regime di persistenza, difficoltà iniziale, fotografia della memoria all'avvio, stato corrente e checkpoint già contabilizzati. Una nuova run Molto facile/Facile/Medio parte pulita; la ripresa della stessa run conserva l'apprendimento. Una migrazione da un vecchio salvataggio privo di questi campi non importa automaticamente memoria difficile nelle modalità inferiori.

Conserva inoltre i tre obiettivi e achievement del piano, progressi, premio maggiore, idoneità dei partecipanti e riscossioni; monete rare, portali preparati, costo riservato/consumato, Micro Realtà generata e punto di ritorno. Lo stato di transizione deve consentire di riprendere senza perdere monete né ripetere premi.

La run online conserva stanza di origine, partecipanti, personaggi assegnati e proprietari di inventari/unità, difficoltà e seed condivisi, richieste già applicate e checkpoint dell'autorità. Ogni utente mantiene l'identità dei propri sei salvataggi. Rientrare nella stanza non deve moltiplicare personaggi, risorse, achievement, evocazioni o morti conteggiate.

40. Verifiche di accettazione obbligatorie

Non fermarti alla compilazione. Esegui controlli di regole, integrazione e gioco reale.

Verifica almeno:

Nuova partita, movimento normale di corsa, mira, Shift per lo scatto, Ctrl per camminare lentamente, attacco e pausa.

Sei slot impostabili, Q/1/2/3, inventario E e rimappatura persistente.

Clic destro della duplicazione separato dai menu UI.

Costo e Vita dei cloni al 2%, danno corretto, limite di due, capienza team e assenza di cloni ricorsivi.

Animazioni inizialmente attive, schivate mostrate come “2” e modifica tramite mouse/touch.

Vantaggi e svantaggi applicati ai tiri e formule con risultati Riflessi/Materia corretti.

Fortuna: soglie, cap, un controllo per colpo e nessun consumo improprio di schivate Oculum.

Le tre armi con bonus corretti ed equipaggiamento visibile durante movimento e attacchi.

Level up in combattimento con ripristino di Vita e Oculum.

Tre percorsi dopo uno stage, negozio, riposi, pasti e ciclo esatto di 30 minuti.

Cinque difficoltà, rinascite finite e malattia controllata sull'esaurimento.

Scroll chiusa con solo nome, persistenza, probabilità canonica, bonus doppio del primo e apprendimento una sola volta.

Art sbloccata con punti e senza punti: assegnazione al grimorio di primo/custom e sostituzione delle skill degli altri. Crea anche un nuovo PG dopo lo sblocco e verifica che possa assegnarla senza pagare o tirare di nuovo.

Gruppo completo, due PG salvati, reclutamento, temporaneo morto che non ricompare e Occhio funzionante.

Due spawn differenti e due scelte narrative con conseguenze successive dimostrabili.

Salvataggio di un NPC destinato a morire, sblocco e utilizzo successivo.

Completamento del Campo, Scostubandito selezionabile, shortcut e Gran Scostumato classificato élite con ricompensa corretta.

Loot e progressione senza duplicazioni dopo morte, ricaricamento e nuovo tentativo.

Sei salvataggi, ripresa della run e tutela delle schede preesistenti.

Due client online: Master e giocatore, permessi, risorse della stanza, audio condiviso, ingresso tardivo e riconnessione.

Pulsante chiamata e chiamata reale, con minimizzazione e controlli.

Coerenza delle fate malvage negli eventi e nei contenuti generati.

Tre ambientazioni percorribili e riconoscibili, con creature canoniche appropriate e più seed validi.

Foresta: il Forest Demon non compare prima del completamento dei nemici richiesti, compare una sola volta nella radura e resta nello stato corretto dopo salvataggio/ripresa.

Dungeon grande: ingresso e uscita collegati, orientamento possibile con indizi, minimappa progressiva, nessun blocco dovuto a chiavi o abilità irraggiungibili.

Muro segreto attraversabile, stanza e ritorno percorribili anche dal gruppo; uno shop realmente scontato e una stanza con tre offerte ma una sola ricompensa ottenibile.

Uscita, rientro e caricamento non cambiano le offerte né ripristinano le due ricompense scartate; gestisci anche inventario pieno.

Un'Art di evocazione ottenibile e assegnabile: costo, IA, durata, capienza, danni, attribuzione uccisioni e comportamento al cambio stanza funzionanti.

Oggetti distruttibili: Obser una sola volta, stalagmite che cade verso la posizione dell'attaccante al momento del cedimento, danno reale e vie d'uscita preservate.

Clash: ascia da 1,6 s iniziata a t=0 e spada da 0,9 s iniziata a t=0,7 s; con contatto valido entrambi i danni sono zero e la respinta avviene una volta. Provare anche attacchi iniziati insieme, impatti fuori tolleranza, ostacoli e differenti FPS.

IA: confronta due stili di combattimento con lo stesso scenario; verifica cambiamenti misurabili nelle tattiche, rispetto della percezione e assenza di reazioni a input futuri.

La tua Luce e La tua Ombra: stessa build copiata all'ingresso, skill realmente eseguibili, risorse indipendenti, limiti delle evocazioni, ricompensa boss e ripresa corretta.

Prima run conclusa: personaggio della levitazione sbloccato anche dopo sconfitta; Vita iniziale maggiore, durata di un secondo, proiettili riflessi senza danno al personaggio, colpo ravvicinato valido che interrompe e causa una sola esplosione al 10% del danno.

Scadenza naturale della levitazione, melee schivato o annullato da clash non producono l'esplosione; nessun rimbalzo infinito dei proiettili.

Necromante: nessuno sblocco alla prima o seconda morte, sblocco alla terza; via alternativa completando il primo vero boss in Difficile. Eventi ripetuti, élite e sconfitta della sola forma mostruosa non duplicano o anticipano lo sblocco.

Necromante: sei slot, E inventario, mano alleata con posto compagno, Q con misura dell'area dichiarata, sfera con attrazione reale e slash coerente; tutte le abilità hanno cooldown verificabili.

Necromante: prima pressione del 3 trasforma per 6 secondi e cura una sola volta il 5% dei massimi normali. Una seconda pressione converte il 15% dei danni validi e consuma il conteggio; provare overkill, Vita piena, nessun danno, spam, clash e tasti tenuti premuti.

Necromante: con massimi normali 100 e Vita attuale 60, ingresso a riserva 65, ritorno naturale a 65 e sconfitta della forma con ritorno a 26. Verificare anche Vita bassa, arrotondamento, colpo letale, scadenza contemporanea, cooldown e mancato consumo delle rinascite.

Necromante online: almeno due client nella stessa partita, stato concorde durante evocazione, immobilizzazione, attrazione, trasformazione, cura e ritorno; verificare latenza controllata, duplicazione delle richieste e riconnessione senza cure o reset aggiuntivi.

Boss specchio del Necromante: stessa abilità contestuale senza settimo slot, stessi vincoli di cura e ritorno, ricompensa e vittoria solo dopo la vera sconfitta del boss.

Cambio arma: rotellina/4 su altri personaggi, rotellina/5 su Daphne, 4 inattivo nel suo preset; menu e chat non cambiano arma. Controlla rimappature, touch, una sola arma, ordine dell'elenco e cooldown non azzerati.

Daphne: 1 attiva esattamente 5 secondi di doppia arma, due oggetti realmente posseduti e comandi separati; gli attacchi del clic destro possono ANCHE folgorare occasionalmente, conservando il danno dell'arma. Prova esiti positivo/negativo, un solo controllo per attacco multiplo, assenza di catene ricorsive, clash, proiettile che arriva dopo la scadenza, cambio arma, tasto tenuto, ripresa e slot personalizzati.

Daphne: scarica con danno ridotto e propagazione limitata; presa di un solo nemico entro portata; schianto con danno ad area e respinta radiale. Prova muri, assenza di bersaglio, resistenze, bersagli sovrapposti e cooldown degli attacchi mancati.

Robot: entrambi gli esiti del Q, curatore fragile che cura Daphne fino alla morte, Pawn V2 resistente con impeti lenti, consumo dei posti compagno anche per il curatore. Prova gruppo pieno, cambio stanza, morte, ripresa e rifiuto senza consumo o nuova estrazione.

Memoria IA: ripresa e rinascita nella stessa run conservano gli apprendimenti; nuova run Molto facile/Facile/Medio li azzera; due run Difficile e due Oculum conservano i rispettivi apprendimenti senza duplicare checkpoint. Tornare a Medio non deve leggere o aggiornare l'archivio difficile. Prova anche cambio difficoltà, profili/PG distinti e baseline identica nei confronti con seed uguale.

Daphne online e boss specchio: su due client armi, durata, evocazione casuale, cure, trascinamento e respinta concordano con l'autorità; riconnessione senza duplicazioni. Il boss usa la build copiata e i propri robot, senza curare Daphne o ricevere una settima azione.

Regno Affogato, Micro Realtà e Regni: controlla che ogni ambientazione consegnata abbia regole e creature riconducibili al canone, una mappa effettivamente giocabile e accessi/uscite coerenti. Segnala separatamente le definizioni ancora da ricevere: il solo nome nel menu non supera la verifica.

Nuove ambientazioni: più seed validi, tre destinazioni compatibili con la storia, ritorno e salvataggio che conservano NPC, negozi, segreti e ricompense; compagni, robot, dimensioni delle trasformazioni e autorità online funzionano anche nelle geometrie specifiche di questi luoghi.

Tre quest per piano: verifica tutti e tre gli obiettivi nello stesso seed, anche con il primo PG senza Art; niente obiettivi incompatibili, bersagli assenti o accessi dipendenti da una moneta rara non garantita. Cambiare stanza o tornare da una Micro Realtà non rigenera il set.

Achievement distinti e premio maggiore: la quest più impegnativa assegna una sola volta 1 cristallo grande di Ascension Dust e 20 Obser. Prova difficoltà diverse, achievement già posseduto, drop separato dell'élite/boss, idoneità in cooperativa e riconnessione dopo la riscossione.

R: durante il fight ricarica soltanto l'arma compatibile; dopo il fight interagisce con l'elemento evidenziato, inclusi i portali. Prova chat/menu, pressione tenuta, ondate ancora previste, Forest Demon in arrivo e dungeon con nemici inesplorati fuori dall'incontro attivo.

Portali e moneta: nessun risucchio, ingresso per sola collisione o trasferimento al raccogliere la moneta. R volontario, destinazione valida, consumo unico solo al trasferimento confermato, annullamento senza perdita, ritorno e ripresa senza nuova generazione o doppio pagamento.

Amici della stanza: due account/client già nella stessa stanza scelgono i PG, entrano nella stessa run e combattono sullo stesso nemico, condividendo le tre quest e ricevendo correttamente i premi. Verifica anche ingresso tardivo e ripristino del proprio PG dopo disconnessione.

Cooperativa con evocazioni: un amico umano non occupa i posti IA del proprietario; Daphne e Necromante possono ancora usare robot/mano quando giocano con altri umani. Verifica cap3 compagni e1 Occhio perPG, proprietari distinti e il massimo numero di giocatori dichiarato.

Transizione del gruppo: R propone la destinazione, i partecipanti attivi confermano, non si abbandona un fight in corso e non si resta bloccati dalla conferma impossibile di un morto/disconnesso. Una moneta autorizzata apre l'accesso condiviso una volta; al rientro un amico non paga ancora né duplica loot e quest.

Usa seed e scenari controllati per verificare gli eventi molto rari senza renderli comuni nella partita normale.

Non riscrivere test soltanto per farli passare: confronta eventuali fallimenti con la specifica e con le regole confermate.

41. Risultato finale da consegnare

Consegna:

Codice integrato nel progetto e dati di gioco necessari.

Build avviabile per i target verificabili nell'ambiente.

Percorso concreto per iniziare a giocare, con i comandi essenziali.

Istruzioni sintetiche per scegliere personaggio, arma, seed e difficoltà.

Percorso verificato «stanza già condivisa → scegli il tuo PG → pronto → stessa run con gli amici», con capienza umana dichiarata, limiti delle unità autonome e modalità di riconnessione.

Un piano verificato con tre quest tutte completabili, tre achievement distinti e premio maggiore corretto; una Micro Realtà raggiungibile mediante moneta e R, con portale privo di attrazione automatica.

Seed verificati per provare Campo Scostubanditi, foresta, grande dungeon, passaggio segreto e scelta tra tre ricompense. Devono aprire i contenuti reali, con gli stessi sistemi usati nella partita normale.

Seed e accessi verificati per Regno Affogato, Micro Realtà e ciascun Regno aggiunto, con indicazione delle regole canoniche applicate e dei dettagli eventualmente ancora da definire con l'utente.

Documentazione delle regole nuove e delle assunzioni provvisorie.

Riepilogo di cosa funziona, cosa hai provato e quali blocchi reali rimangono.

Elenco delle modifiche e degli arretrati corretti.

Nessuna dichiarazione di compatibilità, completezza o assenza di bug non sostenuta da verifiche.

Se la distribuzione ha una pipeline già prevista, prepara correttamente gli artifact e verifica che contengano la build completa. Esegui pubblicazioni esterne solo quando autorizzate nel contesto operativo.

Il risultato deve conservare l'identità Oculum: le mie creature, le fate malvage, il tratto expressive ink/dark fantasy, le scelte narrative e un combattimento in tempo reale realmente divertente da giocare.

Riferimenti da consultare durante l'implementazione

Hero Forge: https://www.heroforge.com/

Hero Forge, panoramica delle possibilità: https://heroforge.com/content/press-kit/

Nuclear Throne: https://www.nuclearthrone.com/

Dead Estate: https://store.steampowered.com/app/1484720/Dead_Estate/

Hotline Miami 2: https://www.devolverdigital.com/games/hotline-miami-2-wrong-number

Wizard of Legend: https://wizardoflegend.com/

Gunfire Reborn: https://gfr.yijoys.com/en/

Don't Starve: https://www.klei.com/games/dont-starve/

Foundry, release ufficiali: https://foundryvtt.com/releases/

Foundry, playlist: https://foundryvtt.com/article/playlists/

Foundry, audio/video: https://foundryvtt.com/article/audio-video/

Monk's Active Tile Triggers: https://foundryvtt.com/packages/monks-active-tiles

Ricontrolla versioni e documentazione al momento del lavoro. Questi riferimenti guidano la progettazione; le regole e i contenuti Oculum vengono dal progetto e da questa specifica.