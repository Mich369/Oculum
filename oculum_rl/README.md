# Oculum RL

La versione Windows autonoma si avvia da `Gioca/Oculum RL.exe` nella cartella della versione attiva. Su questa installazione, `C:/Oculum App/Oculum RL/VERSIONE-ATTIVA.json` indica il percorso. Mantieni `data` e le DLL accanto all’eseguibile. Windows Test ha una cartella, uno ZIP e un profilo di salvataggio propri.

## Oculum RL 0.5.0

- **Fuga dal Campo Scostubanditi.** Il colpo fatale dei banditi può riaprire la run in prigionia. Gli altri personaggi si svegliano al 25% di Vita e perdono il 60% delle risorse di run, comprese le pergamene. Scostubandito e Gran Scostumato tengono il bottino e si liberano premendo R una volta. L’uscita finale si apre dopo l’Elité, anche se restano dei rinforzi in piedi.
- **Compagni furtivi.** Pet, copie, evocazioni e alleati seguono il proprio giocatore senza attaccare quando è nascosto. L’avvistamento di un giocatore in cooperativa fa uscire allo scoperto i suoi compagni.
- **Grimorio.** La Pittrice vende Art con descrizione e costo. L’icona del Grimorio in gioco apre i sei slot per attacco, talento, pergamene e Art. Le assegnazioni si conservano per personaggio e il Master risolve gli ordini in co-op.
- **Audio.** Sei ambientazioni hanno musiche distinte per esplorazione e scontro. Quando si perdono le tracce torna la musica di esplorazione. I boss hanno precedenza e il Gran Scostumato ha un segnale d’ingresso.
- **Campagna.** Oltre il piano 12 può comparire una Boss Rush che vale un livello intero. I quattro attributi crescono con il personaggio. Per il personaggio creato i punti si distribuiscono a mano. Il Vitalium usa la Vita di riferimento del piano. Arconte ha due fasi al piano 24. Aerovyr ne ha tre al piano 36 e si rialza una volta al 50% della Vita massima.

La prova di rete usa due client autenticati nella stessa stanza Supabase. Verifica prigionia, rientro del Master, R, portali, furtività dei singoli pet, uscita con rinforzi vivi e uso del Grimorio dall’ospite. Si esegue con `flutter test --dart-define=OculumRLBanditLiveProof=true test/oculum_rl_coop_live_test.dart`.

## Anteprima 0.4.29

- **Guardie e nascondigli.** Il cono mostra dove cerca la guardia. Le guardie ricordano gli ostacoli che hanno visto e la tua ultima posizione nota. Dopo 10 s fuori dalla vista di tutti i nemici dell’arena hai 1,3 s per ripararti. Durante il preavviso, una guardia non allertata che ti vede per almeno 0,9 s ha il 60% di probabilità di controllare il punto dopo che ti sei nascosto.
- **Cespugli.** Entrando diventi semitrasparente. Da fuori, i cespugli nascondono chi è dentro e coprono ciò che sta dietro. Una guardia allertata può seguirti con lo sguardo se ha visto il tuo ingresso. I colpi attraversano i cespugli. In alcune stanze c’è un avversario già nascosto. In Caramella si riconoscono dai marshmallow.
- **Richiami.** I nemici emettono il proprio verso o battuta dopo 3 s di allerta. Il giocabile ha una risposta quando l’intero gruppo nemico è allertato. Le impostazioni del volume effetti valgono anche per le voci.
- **Nuove animazioni.** Miruscyrus e Costrutto Minore usano le tavole approvate. La forma furtiva del Vampiro usa il Pipistrello di Pece.

[Arretrati e verifiche](docs/ARRETRATI-RL.md) · [Attribuzioni audio](docs/ATTRIBUZIONI_AUDIO.md)
## Anteprima 0.4.28

- **Furtività.** Tieni Ctrl o attiva Cammina su schermo piccolo, anche in cooperativa. I nemici in ronda ti vedono se attraversi il loro campo visivo. Sentono la corsa e lo scatto più da lontano. Il colpo di Forza contro un bersaglio inconsapevole è silenzioso se basta ad abbatterlo. Un testimone con la visuale libera può comunque dare l’allarme. I boss e i miniboss iniziano in combattimento.
- **Mostri giocabili.** Cerca Mosca Campana e Armadillo Corazzato nella Foresta Elementale. La Mosca combatte con due campane. L’Armadillo si chiude nel carapace, rotola e sperona. I due personaggi hanno attacchi naturali, Talento e Open propri.
- **Equipaggiamento in arena.** Le creature mostrano solo le armi che impugnano. Le copie conservano la sagoma del personaggio che le ha create. Le Guardie Solari copiate dal Doppelganger mantengono l’equipaggiamento dipinto nello sprite.

## Anteprima 0.4.27

- **Occhio del Deserto Divoratore.** Apri Gioca subito con seed 41119 e imbocca il percorso a ovest. La fenditura si attiva mettendoci piede. Chi cade nella fenditura subisce 1d12 Taglio, con Scudo e difese normali. Camminare sulla sabbia resta innocuo. La Fortuna è condivisa fra tutti i combattenti. Gli esiti 1 e 2–10 hanno scontri diversi. Gli esiti 11–19 e 20 aprono subito il portale di ritorno. La deviazione non sostituisce un piano della campagna.
- **Personaggi e compagni.** Abbatti Gablyn o Funerys con un tuo colpo per sbloccarlo. Gablyn schiva in affondo con la picca, Funerys raduna e rallenta i nemici. Entrambi hanno Talento e Open propri. Saldino si scopre con il Ragno Saldatore e il Frammento di Lapysrieth con Lapysrieth.
- **Forgia.** Becco della Caverna, Falce di Funerys e Bobina di Postea costano 53, 64 e 67 Obser. Ognuna ha la sua tecnica su G, si può temprare e si può fondere con un’altra arma.
- **Movimento Ink Expressive.** Nuove sequenze per Luce, Ombra, Doppelganger, Pyrel, Lithra, Vegliante, Sacrycrab, Lapysrieth e Thalvyr. Il compagno di Lapysrieth condivide la sagoma canonica. La modalità cammino o corsa viene mantenuta negli snapshot co-op.
- **Leggibilità.** Vesanybel mostra l’impatto aggiuntivo sotto metà Vita. Il riepilogo di fine run indica seed, difficoltà, piani superati e risorse rimaste. Quando cade l’Arconte puoi ancora entrare nell’Atto III.

## Aggiornamenti Windows

Le edizioni Windows normale e Windows Test cercano automaticamente una release Oculum RL pubblica più recente. Il gioco verifica la dimensione, lo SHA-256 e i file del runtime, poi prepara la nuova versione in una cartella separata per edizione. La versione corrente si chiude soltanto dopo che quella nuova ha aperto la sua prima schermata. Durante una run o una stanza online il riavvio aspetta il ritorno al menu.

Da **Aggiornamenti** puoi disattivare i controlli automatici, cercare una nuova versione e riavviare quando vuoi. Per avviare un eseguibile precedente senza passare all’ultimo, aggiungi `--no-update` al suo collegamento. Web e APK restano scaricabili dalla pagina release.

## Barre Vita

In cooperativa, il colore della barra Vita è assegnato al posto nella squadra. L’host usa l’azzurro e fino a cinque ospiti usano oro, viola, avorio, cobalto e rame. L’HUD usa il colore del giocatore locale. In solo la barra è azzurra. Il verde identifica NPC alleati, pet ed evocazioni con barra Vita. Il rosso identifica i nemici.

## Chakram d’Iridio

Il disco ha un anello d’acciaio e la stessa sagoma nella mano e in volo. Ruota durante il lancio, lascia una scia breve e risale verso la mano quando rientra. Doppia orbita su G usa gli stessi effetti.

## Prima prova delle mappe

1. Apri **Gioca subito**, imposta il seed **251** e seleziona **Campo Scostubanditi** come primo piano. Per questa prova usa **Duplicatore**, **Guanti d’arme giganti** e **Molto facile**.
2. Al bivio, vai verso l’alto per il mercante. **R** apre la compravendita: la prima visita anticipata dà 12 Obser per la Spada e scudo. Puoi tornare dopo lo scontro.
3. Per il fianco, gira sotto la palizzata, poi risali verso la prima sentinella restando alle sue spalle. Tieni **Ctrl** per camminare. Ripeti correndo sullo stesso percorso per vedere la sentinella indagare. Con il **tasto destro** puoi distrarla mandando avanti un clone. Un colpo di Forza letale durante il passo lento può restare silenzioso. Una sentinella con visuale libera può comunque vederlo.
4. Clicca la minimappa per i nomi dei settori e per segnare un punto. Una parte della mappa si rivela entrando nella relativa zona. Nel Regno Sotterraneo attacca la barriera della scorciatoia dall’interno per aprirla. Nelle Cappelle di Roccia del Regno Affogato l’acqua rallenta. Le scariche dello Scettro possono raggiungere un secondo bersaglio nella stessa pozza.

Nella Sala di ristoro il Fabbro applica fino a **12 ranghi per arma**. Ogni rango aggiunge il 4% ai Danni dell’arma. La prima tempra costa 17 Obser e il prezzo sale di 5 Obser per rango. A rango 12, **G** con Spada e scudo descrive un semicerchio davanti al personaggio. La portata della Riposta passa da 3,1 m a 6,2 m e i bersagli colpiti possono essere sbalzati di 12 m se il terreno è libero.

Dal secondo ristoro la **Venditrice di Art** propone Plasma, Falci di Vaitern e Linfa verde. La scelta si salva per la run. Con **E** usi l’Art, con **G** la tecnica dell’arma. Guardia Solare ed Elité hanno Affondo della pattuglia, il Cavaliere Lunare ha Affondo delle lame lunari. Il riepilogo prima del portale mostra equipaggiamento, progressi e potenziamenti ancora da scegliere.

Nel Regno Sotterraneo dal piano 6, un nascondiglio svelato può aprire la sfida a **Baghest**, Eiva della Corruzione Rossa. Abbatti un compagno corrotto e tieni **R** per rialzarlo. Se la presa blocca un giocatore, premi **R** cinque volte per spezzarla. La vittoria sblocca la relativa Defiled Art alla Venditrice. I compagni vivi ricevono il 30% della guarigione effettiva del loro proprietario e crescono fino a +48% Danni. Ogni frammento del Simbolo della Luna vale **60 Obser**.

## Scatto e schivata

Shift apre una scia d’inchiostro ocra lungo il movimento. La schivata intangibile dell’Evasore lascia impronte viola, il suo Open aggiunge luce dorata e il Velo dello Slime lascia una traccia verde azzurra. Nel clash le due scie ramate separano i combattenti. Questi effetti usano il volume **Effetti**. Shift da solo non concede intangibilità.

## Atto II e deviazioni

- **Pollo Meccanico**. Dopo aver sbloccato il Pollo di Brace, in una run senza aver ferito la fauna cerca un gruppo di tre polli. Resta fermo al centro per dieci secondi. Il profilo salva subito lo sblocco. Clic sinistro lancia tre raggi runici a inseguimento. Clic destro o V spara all’indietro tre uova di Postea, che percorrono fino a 6,8 m ed esplodono in un raggio di 2,25 m. Spazio potenzia le uova. Mira con un raggio a un tuo uovo atterrato per anticiparne l’esplosione.
- **Finiture per tutti i personaggi**. Scegli Canonica, Ferro Cremisi o Patina di Eiva dalla selezione, dal menu della run già salvata o dalla sala online. Le due finiture alternative aggiungono un sigillo e una scia d’inchiostro. Il Pollo Meccanico ha anche quattro sprite distinti per ciascuna finitura.

- **Voci delle botteghe**. Goblin, Armaiola, Taverniera, Fabbro e Veggente salutano con un verso specifico e una battuta sottotitolata. Usa l’icona accanto al testo per sentirne un’altra. I valori predefiniti sono 35% musica e 50% effetti. Le voci usano il cursore effetti. In impostazioni puoi ripristinare questi due volumi.
- **Tecniche su G**. Ogni arma ha una mossa, con costo ordinario di 3 Oculum e recupero di 4,2 s. F continua a bloccare, lo Scostubandito conserva Fucile schivata e l’arco consuma tre frecce per il ventaglio. Divoramitù Elité e boss hanno una sagoma e una zona di contatto più grandi. Il boss è largo circa cinque volte il Pollo di Brace. L’hitbox allungata è segnata sul terreno e segue il balzo insieme alla barra Vita. L’Atto II mantiene lo speed-up del +40%.
- **Stabilità**. I comandi online sono associati alla sala in cui partono. La fauna ferita riprende la posa di movimento dopo l’impatto.
- **Atto II**. Dopo la dodicesima stanza, dal ristoro scegli Inferno, Regno Caramella o Postea. Ognuno ha quattro visitazioni e un premio conclusivo. Le prime tre permettono di scegliere una reliquia. L’ordine delle reliquie cambia le sinergie di Danni, recupero di Oculum e protezione.
- **Divoramitù**. Le crepe a terra segnalano l’emersione ad arco. Shift di lato per evitare il contatto. È vulnerabile mentre è fuori dal terreno. Inferno sblocca Demone Minore, Intermedio, Maggiore Prediletto dall’aspetto umano e Diavolo del Patto.
- **Dungeon solare**. Un riparo frangibile nasconde le scale d’oro. L’Elité Solare, due Guardie e un’Aberrazione difendono la penultima sala. Dopo lo scontro ricevi 72 Obser e accedi al ristoro. Il Guardiano Solare alterna due frecce d’oro, un raggio e il colpo di mazza. Sconfiggilo per altri 96 Obser e nuovi personaggi. Con un Solare alla guida, il percorso principale oppone i Lunari. La nona stanza schiera un Custode, due Elité e tre Guardie.
- **Fauna**. Pollo, raganella e pipistrello popolano le arene e si sbloccano risparmiandoli. Nelle prime sei stanze in cui la attacchi, la fauna ferita scappa. Nelle successive ti attacca a vista. Il Pollo usa beccata e tre uova sparate all’indietro, esplosive all’impatto o dopo 0,9 secondi da ferme. Alla morte con un animale, il 12% innesca la Muta e sblocca il Doppelganger con il 65% Vita fino a Normale e il 30% da Difficile.
- **Sale di ristoro** con botteghe dopo la sesta, la dodicesima, la diciottesima e la ventiquattresima stanza, prima del finale. La Taverniera prepara pietanze per tre scontri. Il Fabbro vende anche lo Chakram d’Iridio. Il Mercante offre pergamene, evoluzioni a tre ranghi e Gettone di Rinascita. La Veggente può custodire un acquisto della visita per la prossima run.
- **Simbolo della Luna di Vaitern**. Il Cavaliere Elité Lunare può trovarlo abbattendo nemici comuni, Elité e boss con probabilità 1%, 6% e 12%. Le due mezze lune e il disco centrale valgono 60 Obser ciascuno. I nuovi asset usano Expressive Ink e il drop di Obser mostra la pietra canonica con l’occhio.

## Scelta, abilità e sbloccabili

- **Cavaliere Elité Lunare** sbloccabile completando la campagna in Facile o superiore. Spada e scudo raddoppiati, blocco a 300, due Guardie Lunari con la skill e un Guardiano Lunare che respinge fino a 12 m con l’Open.
- **Slime Blu** si sblocca abbattendo dieci Slime sommati fra run. Q attiva lo scatto invisibile. L’assorbimento si mantiene con clic ripetuti e restituisce Vita e Oculum. Gli organici vicini cercano di circondarlo; i nemici meccanici continuano ad attaccare.
- **Vampiro** respinge i nemici di 3 m, poi 6 m dal livello 3. Contro un riparo infligge 5 Danni aggiuntivi e rompe quelli frangibili. Può volare da pipistrello per 3 secondi intangibili o raddoppiare la propria forza, velocità e Vita con l’Open. La forma di sangue toglie il 5% della Vita massima ai nemici molto vicini a ogni pulsazione.
- **Campo goblin segreto** con sei ondate, Re Goblin giocabile, fango che oscura la gran parte dello schermo per 0,9 s e Spara-colla raro. Il Re usa la stessa combo stordente anche come avversario. Q rialza gli alleati entro 10 m al 50% Vita. L’Open evoca due goblin col coltello e un fangoso; dopo il primo Spara-colla abbattuto lo aggiunge come quarto alleato. Il Re nemico ha il 6% di averlo prima della scoperta e il 100% dopo. Lo sparo fa pochi Danni. La colla a terra rallenta soltanto mentre la attraversi.
- Mostri, NPC, pet ed evocazioni cercano percorsi attorno ai ripari. I tiratori arretrano e si spostano di lato per mantenere la distanza. Gli alleati reagiscono ai nemici che minacciano il loro proprietario. Lupo Lunare, Gablyn e la fanteria goblin hanno pose dedicate. Le Guardie e il Guardiano rispettano le tavole canoniche.

Nel Campo goblin, usa un’arma contro il muro crepato e visita il sigillo dopo aver terminato lo scontro del piano. Il Re giocabile usa il colpo stordente con Destro o V ogni 1,8 s. Lo stordimento dura 0,9 s sui nemici comuni, 0,6 s sulle Elité e sui giocatori colpiti dal Re, 0,3 s sui boss. Q spende 4 Oculum e si ricarica in 12 s. Le abilità su Q del Re e dello Slime sostituiscono il primo slot di pergamena per quei due personaggi.

- Il seed assegna l’ambientazione all’avvio e a ogni portale. Deserto Divoratore introduce Rasvyr e Orea Zalira introduce Orbryx. Nelle stanze con muro crepato, rompi il muro per raggiungere la sala nascosta con Vitalium Grezzo, Obser e una pergamena.
- **Pyrel** spara una palla di fuoco che rimbalza fino a tre volte su pareti e bersagli. **Lithra** apre una faglia che colpisce in linea e si ferma davanti ai ripari solidi; con l’Open genera tre faglie. **Doppelganger** combatte a mani nude finché non copia un nemico visibile entro 7 m. Riceve Vita attuale e massima e attacchi della forma. Non copia boss né eco. Se la forma viene abbattuta torna al 65% della Vita che aveva prima di copiarla.
- Sconfiggi La tua Luce al piano 3, La tua Ombra al piano 9 e Veyrth al 23 per renderli giocabili. La Luce usa la lancia e lo Scudo, l’Ombra si riposiziona e diventa intangibile per 3 secondi con l’Open, Veyrth lancia sfere in direzione del bersaglio e a cerchio con l’Open.
- Clic destro o **V** attiva l’abilità. **Spazio** usa l’Open per 5 Oculum. **B** lancia la bomba dello Scostubandito per 2 Oculum; recupero 5,5 secondi. **G** rimane Fucile schivata.
- Le pergamene **Brace errante**, **Spaccaterra** e **Linfa verde** usano gli stessi quattro slot. Linfa verde restituisce il 20% della Vita massima e 10 di Resistenza del blocco.
- **Piccola Marea** si unisce dopo tre Rasvyr abbattuti nella run. **Orbietto** si nasconde in una sala segreta di Orea Zalira. **Lumin d’eco** entra nel gruppo quando il Doppelganger copia uno Slime. Il menu Compagni conserva le scoperte.
- All’avvio puoi portare un pet fra un massimo di tre già sbloccati. Il seed dà la precedenza alle specie della zona. Al Ristoro il Bandito dei pet può proporre uno scambio valido per quella run.
- Sconfiggi il Divoramitù Miniboss per reclutare il **Divoramitù Mini**. Il miniboss combatte con due cuccioli che strisciano e guadagna 0,3 di velocità per ciascun cucciolo abbattuto. Il pet si interra ogni 10 secondi durante uno scontro e riemerge lasciando un cratere di 3 secondi. Ai bordi i nemici rallentano del 40%. Il centro infligge danni a intervalli e raddoppia la velocità d’attacco degli alleati. In tutto il cratere gli alleati si muovono il 40% più in fretta.
- Abbatti un **Bunnys** per reclutarne uno. Cura il compagno più ferito vicino a lui. Quando cade cura gli alleati ancora in piedi e non può essere rianimato.
- **Fabbro**. Sbloccalo portando un’arma a Tempra 3. Il fabbro del Ristoro ha sei pose dipinte, con incudine e fucina su livelli fissi. Il giocabile ha otto pose per appoggio, corsa, scatto, carica e colpo. La Frattura della forgia respinge i nemici entro portata. L’Open evoca fino a 20 armi da 7 Vita con 2 secondi iniziali di invulnerabilità. Le armi sono di energia, non proiettano ombra e non possono ricevere cure o essere rianimate.
- La Guardia Elité Lunare legge il proprio prologo su schermo nero prima della nuova run. Puoi avanzare con **Continua** oppure attendere cinque secondi. Il prologo viene saltato quando riprendi un salvataggio.
- Nell’editor del Duplicatore puoi variare nome, lignaggio, corpo, volto, pettinatura, copricapo, tenuta, emblema e colori. Le nuove tenute da esploratore e lamellare, benda e rune del volto, emblemi piuma e cristallo si combinano con le opzioni precedenti.

Gioco autonomo con campagna roguelite 2D. Usa salvataggi e impostazioni propri. Il client online riutilizza l’autenticazione e l’approvazione delle stanze Oculum, con messaggi di gioco temporanei e un’unica simulazione sul client del Master.

## Avvio

- **Gioca subito** apre la configurazione di una nuova run nel primo slot libero. Scegli il personaggio, una sola arma iniziale, la difficoltà e il seed, poi premi **Inizia la run**.
- **Online** apre la stanza. Il Master può ospitare e approvare gli ingressi. Tutti i combattenti scelgono un kit e premono **Pronto**. Dopo l’avvio gli altri scelgono **Entra nella partita**. La capienza è di sei combattenti, Master incluso.
- Per riprendere una run online, il Master riapre lo stesso codice con lo stesso account e seleziona **Entra nella partita**. Supabase salva un checkpoint all’avvio, ai traguardi della stanza e ogni sei secondi mentre si gioca. Gli ospiti già nell’arena attendono il Master e riprendono dalla sua nuova connessione. Può andare perso il tratto giocato tra l’ultimo salvataggio e una chiusura improvvisa.
- I comandi singoli vengono confermati dal Master e ritrasmessi con lo stesso identificativo quando necessario. I Sigilli dei piani completati vengono registrati anche per i combattenti in cooperativa.
- WASD o frecce per muoverti, clic sinistro per attaccare, clic destro per il talento, Shift per scattare, Ctrl per camminare, R per interagire o ricaricare. **Esc** apre le impostazioni in solo. Regola separatamente musica ed effetti e usa il mute quando serve.
- Seleziona **Duplicatore** e **Personalizza in 2D**. Combina fisionomia umana o goblin, cinque modelli del corpo, sei lineamenti, corporatura, apertura delle orecchie, otto pettinature, sei tenute, copricapi, dettagli del volto, emblemi, iride, colori e nome. Puoi generare un aspetto casuale, ritoccarlo e provarlo con le otto pose delle armi. L’arma iniziale si sceglie nella schermata della run. In solo l’aspetto resta nello slot. In cooperativa prepara il tuo aspetto prima di premere **Pronto**. La stanza condivide le scelte di ogni Clonatore per tutta la partita.
- **Ashley** è un’anziana meccanica con il braccio a molla. Il clic destro colpisce a 4,2 m e si ricarica in 3,4 secondi. Infligge 14 Danni base, più 2 per livello. I valori sono del bilanciamento iniziale.
- Il guanto a molla resta sul braccio di Ashley anche quando impugna un’altra arma. Il clic destro continua a usare il pugno.
- In cooperativa ogni Duplicatore crea fino a due copie con la propria arma e paga il costo con la propria Vita. Anche Ashley può usare il pugno a molla in cooperativa.

## Combattimento e progressione

Luce, Ombra e gli Echi Speculari usano la stessa illustrazione da combattimento del personaggio copiato. Il Curatore della Peste conserva maschera, mantello e scettro.

I passi seguono la distanza percorsa nell’arena, con appoggi più leggibili e peso del corpo sulla gamba in carico. Le pose di attacco conservano le loro finestre di combattimento. La cadenza segue anche il cambio di velocità dei piani e si ferma quando un ostacolo blocca il movimento.

- Dopo aver ripulito il piano, premi **R** al portale. L’anteprima del piano assegnato indica prima ondata, disposizione dei ripari, eventuale élite o boss e possibile pergamena a Postea. In solo mostra anche il potenziamento di zona, il Ristoro dopo la vittoria e gli eventuali potenziamenti non riscossi che scadrebbero partendo. In cooperativa il Master apre l’anteprima del percorso assegnato e il gruppo lo conferma.
- La campagna contiene 25 stanze principali, numerate da 0 a 24. Ci sono Élite ai piani 0, 6, 12 e 18 e boss ai piani 3, 9, 15, 21, 23 e 24. Veyrth precede la sala di ristoro. L’Arconte delle Fratture chiude il percorso principale al piano 24. Le deviazioni dell’Atto II e le stanze segrete restano aggiuntive. Dopo l’Arconte puoi proseguire dallo stesso salvataggio con **Entra nell’Atto III**. I salvataggi già al vecchio scontro finale con Veyrth mantengono la loro versione del finale al piano 13 o 24.
- **Atto III**. Undici sale fra Cripta della Campana Cieca, Cappelle di Roccia e Passerelle del Cumulonembo, per 36 piani di campagna. Vesanybel e Thalvyr precedono Aerovyr, boss del piano 36. Aerovyr entra nella seconda fase al 50% della prima barra. Alla prima sconfitta si rialza al 50% della Vita massima e inizia la terza fase. La vittoria arriva quando viene sconfitto di nuovo. I suoi attacchi includono un ventaglio di schegge, una croce di scariche e una corona con centro sicuro. Le deviazioni e le segrete restano aggiuntive.
- **Open**. Spazio, 5 Oculum e un effetto principale triplicato. Dopo l’uso l’Open si ricarica entrando in nuove stanze di combattimento. Le due successive passano in recupero e puoi riusarla entrando nella terza. Il recupero è personale e resta nel salvataggio anche in cooperativa. Ristoro e dimensioni positive dell’Occhio del Deserto non contano.
- **Art**. L’istruttrice è disponibile dal primo Ristoro. Ogni Art appresa può ricevere due lezioni, ciascuna con una forma effettiva aggiuntiva fino al massimo dell’Art e una riduzione del 10% del recupero. Il grimorio e i miglioramenti sono personali.
- **Traguardi**. Ogni cinque piani completati si ottengono personaggi o armi di Oculum. Si sbloccano anche i premi delle difficoltà inferiori.
- **Sale segrete**. Ogni blocco completo di sei livelli ha un ingresso nascosto, sorteggiato fra tutti e sei. Anche la deviazione dell’Atto II ha un nascondiglio in una delle quattro sale. Cerca le pareti crepate.
- **Pericoli ambientali**. Nelle sale ordinarie dell’Atto I, Postea ha presse e le segrete hanno sigilli. Nell’Atto II le braci di Inferno, le presse di Postea e lo sciroppo di Caramella hanno aree e ritmi distinti. Le aree si illuminano prima dell’attivazione. Le presse, le braci e i sigilli colpiscono una volta per attivazione. Lo sciroppo rallenta finché ci si cammina sopra.
- **Pozzi**. Nelle sale che hanno un pozzo puoi vedere fino a tre offerte. Lo scontro va concluso prima di confermarne una. In co-op il Master conferma il potenziamento comune.
- **Lupi Lunari**. Attaccano una squadra con almeno un Solare, aiutano i Lunari e restano neutrali con gli altri. I compagni e le evocazioni crescono con il livello di chi li guida.
- **Arconte delle Fratture**. La seconda fase scatta al 50% della Vita massima. Frattura colpisce un’area marcata. Spaccatura segue una corsia che termina al primo riparo. Corona spezzata lancia undici schegge lasciando un varco nella direzione marcata. Le pause fra gli attacchi si accorciano a ogni fase.
- Veyrth evoca dodici sfere color prugna. Le vedi formarsi in cerchio per 0,47 secondi prima che partano in tutte le direzioni. Anche intangibile, Veyrth può usare le sfere.
- Il ritmo dell’arena aumenta di 10 punti percentuali ogni tre piani e raggiunge +80% al finale. Si applica a movimento, animazioni e tempi di combattimento per tutto il gruppo.
- Dal piano 3 i nemici hanno +15% Vita e +12% Danni. I bonus crescono di altri 2 punti percentuali di Vita e 1 di Danni a ogni piano e si combinano con difficoltà e cooperativa. Gli incontri speciali da quel piano moltiplicano ancora Vita e Danni. Élite +20% e +10%, boss +25% e +15%, Veyrth +30% e +18%, Arconte +38% e +24%. Dal piano 13, cioè dalla quattordicesima stanza, il bonus di Vita aumenta di altri 24 punti percentuali, più uno per piano successivo. Il bonus ai Danni cresce di altri 14 punti percentuali. I minion di Veyrth restano a un colpo.
- Le quattro arene hanno sfondi dipinti a tutta stanza. Mercante, Ristoro, portale, pietre curative, gemme e consegna delle armi hanno sprite dedicati.
- Per combattente aggiuntivo la Vita base dei mostri cresce di 1%, 3%, 6%, 9% o 12%, rispettivamente da Molto facile a Oculum. Il limite di un colpo per i minion di Veyrth resta valido.
- Quando perdi Vita ricevi 1,9 secondi di protezione. Un colpo interamente assorbito dallo Scudo ne dà 0,95. Un attacco personale andato a segno interrompe questa finestra. Le schivate hanno un timer distinto.
- Proiettili avversari e colpi ravvicinati si possono annullare all’intersezione. Nel clash fra due impatti ravvicinati entrambi arretrano per 0,26 secondi guardandosi, intangibili durante lo scatto.
- Guanti e carabina mostrano la preparazione prima del rilascio. Le lame lasciano scie, le schivate un tratto breve e il braccio di Ashley segue il pugno con una scia più lunga. I colpi alla Vita producono tre tagli, quelli sullo Scudo schegge azzurre. Questi effetti seguono lo stato della partita anche per gli ospiti.
- Il passo segue lo spostamento reale. Le animazioni riusano gli atlanti e passano da 121 a 49 vertici per gli sprite piccoli a schermo. Anche in cooperativa la posa avanza tra due aggiornamenti del Master.
- I potenziamenti della run salgono fino al grado III. C’è una scelta al termine di un piano; i riflessi copiano il kit e i potenziamenti che il protagonista ha in quel momento.
- Il Ristoro è disponibile una volta dopo lo scontro a partire dal piano 0, ogni tre piani fino al 21. Aggiunge il 50% della Vita massima e il 25% dell’Oculum massimo. Il Vitalium Grezzo cura il 20% della Vita normale di riferimento del piano, pari a 20 punti al piano 0. Il Vitalium Ridefinito cura il 100% di quel riferimento, pari a 100 punti al piano 0, e ripristina l’Oculum al massimo. Le cure sono uguali per tutti sullo stesso piano e si fermano al massimale del personaggio. I compagni vivi del proprietario ricevono il 30% della sua cura effettiva. Valori di prova dei drop 18% e 2% rispettivamente, distinti dal recupero al passaggio di livello.
- Il mercante alterna armaiola e goblin, secondo seed e piano. Le altre armi si possono acquistare o trovare in combattimento.
- La tua Luce lascia la **Picca d’ossidiana**, con un affondo stretto da 4,3 m. La tua Ombra lascia la **Balestra runica**, con quadrelli da 11 m che rallentano brevemente i nemici comuni. Le armi raccolte entrano nell’arsenale della run e, in cooperativa, vengono raccolte dal Master.
- Dopo aver sconfitto il Gran Scostumato si unisce alla run la **Vedetta Scostubandita**. Dopo Miruscyrus si unisce il **Drone di Postea**. Seguono il gruppo e attaccano da soli. Possono cadere e si soccorrono tenendo **R** vicino. I compagni viventi seguono attraverso i portali e vengono conservati nel salvataggio della run.
- I nemici possono mirare a combattenti, duplicati, compagni ed evocazioni. Preferiscono il bersaglio vivo più vicino che vedono. I compagni a terra possono essere soccorsi con **R**.

## Riprendere una run

- In solo la run si salva anche ai cambiamenti importanti, come completare un piano, reclutare o rialzare un alleato, raccogliere un’arma o comprare dal mercante. Nel menu di pausa usa **Salva ora** oppure **Salva e torna ai salvataggi**.
- Dopo la morte, **Nuovo tentativo** riapre la scelta di personaggio, arma, area, difficoltà e seed, anche con uno slot già concluso in una versione precedente. La schermata parte dai valori salvati. **Annulla** conserva il tentativo precedente.
- Le edizioni native conservano ogni slot e la sua copia di sicurezza in file distinti. Possono leggere i salvataggi delle versioni precedenti. Se serve la copia di sicurezza, la schermata degli slot lo indica. Nel browser restano disponibili le copie locali dello slot.
- Se manca l’aspetto nel salvataggio, viene usato quello predefinito. Una preferenza audio illeggibile usa il valore predefinito. Se il profilo dei Sigilli non si aggiorna, il gioco mostra un avviso distinto dal risultato del salvataggio della run.

## Sblocchi tra le run

- Lo **Scostubandito** diventa giocabile dopo che attraversi il portale oltre il Forest Demon adulto con la Vedetta ancora viva. Usa il suo stesso sprite e parte sempre con un solo equipaggiamento, il **Fucile Scostubandito** (+5 Danni, 12 m). Il clic sinistro spara o usa il calcio del fucile se c’è un nemico entro 2 m. Il clic destro dà un pugno con 25% di critico. Puoi raccogliere altre armi nella run.
- Con **G** o **Fucile schivata** spendi 4 Oculum per infondere quattro spari. Ogni sparo infuso ha il 25% di essere critico. Un critico a segno rende intangibile il prossimo scatto con Shift. Lo Scostubandito parte con 8 Scudo. Se lo Scudo assorbe un colpo e resiste, respinge e infligge 6 Danni entro 2 m. La prima rottura di ogni piano lo ripristina a 16 + 2 per livello sopra il primo, dopo eventuali danni alla Vita.
- I piani 0, 3, 6, 9, 12, 13, 15, 18, 21 e 24 danno un Sigillo al primo completamento, anche se il traguardo è già presente in un salvataggio leggibile. In **Potenziamenti permanenti** spendi un Sigillo per grado. Per grado puoi ottenere +5 Vita massima, +1 Danni base, +1 Oculum massimo, +5% portata delle armi, +0,75 m di attrazione Obser, +5% velocità e ritmo dei compagni, +4 Scudo a ogni piano o +10 capacità del blocco. Ogni voce ha due gradi. Il personaggio riceve i bonus all’avvio di ogni nuova run, anche in cooperativa.
- Con lo **Scettro magico** equipaggiato due scintille orbitano attorno al personaggio. Ogni 0,86 secondi di gioco una scarica può colpire il nemico visibile più vicino entro 2,6 m. La scarica infligge 4 Danni base e riduce la velocità di movimento del 30% per 0,5 secondi.

## Piani esplorabili e Occhio d’Ombra

- Nelle nuove run i piani principali ordinari ed élite iniziano in un atrio protetto. Si usano due gallerie, la pittrice di Art, un banco scelto dal seed e l’arena che custodisce l’uscita. R apre i banchi quando si è vicini. Il guardiano deve essere sconfitto per aprire il portale.
- A Postea la Reysercth aumenta dell’8% Vita massima e Danni arma una volta per combattente. Il propulsore respinge fino a 3 metri e si ferma davanti ai ripari.
- Nell’Occhio d’Ombra trovi Eco velata, Passo senza luce e Filo d’Ombra. Le forme crescono con il livello e gli studi. Il raggio tiene fermo chi lo lancia e segue lentamente la mira fino al primo riparo. Un colpo subito, il blocco o uno scatto lo interrompono.

## Open e deviazioni

- Premi **Spazio** oppure **Open** su telefono. L’Open è di grado 1 fino al livello 2, di grado 2 ai livelli 3–5 e di grado 3 dal livello 6. Il comando mostra il grado quando l’abilità è pronta e le stanze di recupero rimanenti dopo l’uso, in solo e in cooperativa.
- L’Evasore scatta intangibile per 0,48/0,58/0,68 s. Il Duplicatore fa apparire fino a due copie nei primi due gradi e fino a tre al terzo, per 12/14/16 s. Ashley colpisce fino a 5/5,45/5,90 m con Danni maggiori. Il Gran Scostumato evocato dallo Scostubandito e i due Scostubanditi evocati dal Gran restano 12/15/18 s, con più Vita e Danni a ogni grado.
- Il **Curatore della Peste** è un necromante senza sesso, disponibile da subito con lo Scettro magico. Il clic destro evoca uno scheletro con Falce runica e un arciere per 18 s, al massimo uno per tipo. Uccidere con un colpo proprio o dei suoi scheletri restituisce l’8% di Vita massima e 10 Resistenza al blocco. L’Open attiva una forma corvina gigante per 4/4,5/5 s. Vita e Vita massima raddoppiano, i colpi respingono chi sopravvive. Quando la forma termina, si conserva la percentuale di Vita residua.
- Il **Gran Scostumato** si sblocca completando la run con lo Scostubandito. Il clic destro spara col cannone e può distruggere i ripari. Puoi reclutare la **Sentinella di Pietra** dopo il Costrutto e il **Baby Forest Demon** dopo il Forest Demon adulto. Loro e il Drone di Postea diventano giocabili se li tieni in vita nel piano successivo al reclutamento e attraversi il portale con loro. Gli sblocchi restano nel profilo, anche quando ottenuti in cooperativa.
- In cooperativa tieni **R** o il pulsante **Soccorso** vicino a un altro giocatore o compagno a terra. Dopo 1,2 s il bersaglio torna con il 30% di Vita e l’arco di chi soccorre si ricarica. Un colpo che toglie Vita o Scudo sospende il progresso per 0,35 s. Puoi continuare tenendo premuto. Il Ristoro spetta a ognuno una volta per piano previsto, avvicinandosi al punto e premendo **R** dopo lo scontro. Ogni giocatore recupera Vita e Oculum all’aumento di livello, se è in piedi.
- Tieni **F** oppure **Blocco** su touch. Il danno consuma Resistenza prima di Scudo e Vita. La capacità base è 100, 160 con Spada e scudo, oppure 300 con il Cavaliere Elité Lunare e Spada e scudo. Il consumo resta salvato e cambiare arma modifica solo il limite. Ogni oggetto curativo raccolto restituisce 10 punti a chi lo prende, anche in cooperativa. Durante il blocco puoi muoverti e usare l’Open. Rilascia il blocco per usare attacchi, talento e pergamene.
- Dai piani ordinari successivi al primo, un portale propone una deviazione legata al seed e indica il rischio. **Battuta dei predoni** aggiunge due nemici e premia con 22 Obser. **Patto di ferro** dà ai nemici +25% Vita e premia con 28 Obser. **Caccia al varco** dà ai nemici +15% velocità e premia con 35 Obser se chiudi entro 40 secondi di arena. Scadere il tempo fa perdere il premio extra e puoi comunque proseguire.
- **Occhio lungo** aumenta la portata delle armi dell’8%, 18% o 35%. **Iride vorace** aggiunge 1,25 m, 2,75 m o 4,50 m al raggio base di 1 m con cui attiri gli Obser. Queste ricompense sono condivise in cooperativa e si sommano ai bonus permanenti personali. Attrazione Obser aggiunge 0,75 m per grado acquistato con i Sigilli, fino a due gradi. Le monete scorrono verso il combattente idoneo più vicino, senza attraversare i ripari, e vengono accreditate al gruppo una sola volta. Vitalium ed equipaggiamento si raccolgono a contatto.
- **Legame vigile** accelera movimento e ritmo degli interventi dei compagni del 10%, 22% o 40%. **Pelle runica** dà 5, 12 o 25 Scudo subito e a ogni nuovo piano. **Ferro vivo** aumenta di 12, 30 o 65 punti la capacità del blocco con F. Il consumo della Resistenza viene conservato e ogni oggetto curativo ne restituisce 10.
- **Braci d’impatto** provoca 5/10/20 Danni ai nemici entro 2 m da un Clash di proiettili. **Riflusso d’Oculum** aggiunge 5/10/22 Scudo all’attivazione della tua Open. **Risonanza d’ombra** riduce del 18/32/50% il recupero dell’arma per 4 secondi dopo l’Open. In cooperativa il Master sceglie un potenziamento condiviso dopo lo scontro e gli Obser extra della deviazione vanno a ogni combattente.

## Sviluppo e verifiche

- Da questa cartella esegui `flutter pub get`, poi `flutter run -d windows` per l’avvio locale. Le edizioni Windows e Windows Test usano profili separati. La variante Android di prova ha un proprio identificativo.
- `flutter test` prova la simulazione, gli slot e il generatore. Imposta `--dart-define=OculumRLLiveProof=true` per il test esplicito online. `--dart-define=OculumRLLivePartySize=6` estende la prova a sei client. I test online usano stanze e identità di test. Sulla 0.4.28 la prova API con `--dart-define=OculumRLWormholeLiveProof=true` ha verificato con sei client autenticati la sospensione degli ospiti senza il Master e il rientro di un nuovo client del Master nella stessa run. I sei client sono tornati insieme dall’Occhio del Deserto, con lo Scudo del solo personaggio caduto ridotto una volta e 5 Obser assegnati una volta a ciascun combattente. I due eseguibili Windows della 0.4.28 sono stati avviati localmente. Resta da provare il rientro dopo la chiusura del processo del Master con due installazioni Windows collegate da reti separate.
- `dart tool/verify_campaign.dart` gioca due percorsi completi, dal piano 0 al boss finale, con input di movimento, attacco e ricarica.
- `tool/build_distribution.ps1` prepara eseguibili con runtime, ZIP distinti, APK e versione Web.
- Nel creatore puoi usare **Carica aspetto salvato** per ripartire da nome e aspetto di un Duplicatore salvato in solo, anche dalla stanza online. Le modifiche si applicano solo alla copia. L’arma si sceglie separatamente e resta visibile nell’anteprima, che puoi ingrandire.
- La specifica completa è [OCULUM_MEGA_PROMPT.md](docs/OCULUM_MEGA_PROMPT.md). Restano in lavorazione altre ambientazioni e Micro Realtà, i personaggi avanzati descritti nella specifica, il grimorio condiviso e la chiamata audiovisiva.

## Impostazioni e personalizzazione

Puoi cambiare seed, difficoltà, ambientazione, percorso dell’Atto II, equipaggiamento, tecniche e pergamene assegnate, ordine delle reliquie, aspetto 2D del Duplicatore, musica ed effetti. Nei sorgenti il catalogo delle Botteghe, le soglie di sblocco, i tempi di combattimento e i valori delle tecniche sono nei moduli sotto lib/game.
