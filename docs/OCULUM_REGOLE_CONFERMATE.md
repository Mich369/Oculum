# Oculum — registro delle regole confermate

## Creature delle dodici fasi — 25 ottobre 2026

Richiesta esplicita: aggiungere mostri tematici per ogni fase del Ciclo Oculum. Introdotte due specie distinte per fase (24), con due tecniche ciascuna (48), Open, anatomia e materiale proprio. Livelli, statistiche, costi fissi 1/2/3 Oculum, cooldown e valori degli effetti sono bilanciamenti iniziali modificabili, non nuove soglie confermate dall’utente.
L’affinità di fase è conservata nei dati del Monster Book e consultabile nel dossier; il selettore consente di filtrarla insieme al piano e al nome. Non modifica date, durata o effetti globali del calendario e non impedisce al Master di scegliere manualmente una creatura. Safe Monster ha specie pacifiche con tecniche protettive e curative; The Moon richiama reliquie lunari e stelle alleate, senza Luna nel cielo. Le capacità di The Null non cancellano i dati della scheda né attribuiscono automaticamente un nuovo Fato alle vittime.
Le personalizzazioni delle voci già salvate conservano precedenza. La prima lavorazione separata non includeva APK; il 26 ottobre l’utente ha richiesto di includere queste creature nell’aggiornamento completo, con pacchetti GitHub per tutte le piattaforme, APK compreso.

## Ultime creature e Scudi critici — 25 ottobre 2026

Zombie con sbocco d’acido e Cavaliere del Non Ritorno aggiunti. Il Cavaliere ha spadone, armatura nera opaca con punte e vortice sul petto che termina in un occhio. Bilanciamento iniziale modificabile: tre Scudi critici e due Schivate Oculum; valori e ricompense sono dati di catalogo.
Conferma generale: lo Scudo critico impedisce Frattura e ogni debuff che richiede un critico finché protegge il colpo, compreso quello che ne consuma l’ultima carica. Gli effetti che non richiedono critico restano ordinari.

## Precisione, NPC e creazione — ultime conferme 25 ottobre 2026

- Ogni mostro ha punti anatomici coerenti con il corpo descritto. Le appendici multiple si selezionano prima per tipo e poi per lato/numero; un solo elemento non richiede un secondo passaggio. I punti particolari scoperti sono evidenziati. I mostri usano soltanto il punto debole del Monster Book; i personaggi usano i punti delle proprie Art. Martial Art: −2 Precisione; un colpo riuscito al punto dell'Art dà −3 soltanto ai tiri di quell'Art per una sua Azione. Il Master può rivelare la voce esatta senza rivelarne le varianti.
- Fate Golem: colpire «Nucleo con fata» restituisce il danno all'attaccante senza tiro contrapposto; Azione/Reazione viene comunque consumata. La distinta regola del Mini Fate Golem resta separata.
- Ali: un critico riuscito con perdita di Vita danneggia l'ala scelta. Una ala danneggiata dimezza i bonus del volo; due ali distinte impediscono di volare e causano `max(0, 1d60 − Riflessi della creatura che cade)` Danni. Danno di caduta con normali protezioni come valore iniziale; ripristino al Riposo Lungo o intervento manuale del Master.
- Frattura: massimo tre arti distinti, senza applicarla nuovamente allo stesso arto. −1/−2/−3 soltanto ai tiri che usano gli arti fratturati. Dopo il terzo, ogni critico successivo con perdita di Vita aumenta il malus di uno e sorteggia al 50% Danni oppure Difesa, riducendo quel valore del totale progressivo. I malus dei due tipi restano entrambi: quarto critico Danni −4, quinto Difesa −5 conserva anche Danni −4. Un nuovo esito sostituisce soltanto il valore dello stesso tipo. La condizione richiede la propria cura; non sparisce a fine fight.
- Creazione rapida NPC: scelta elemento, una skill di Attacco, una di Supporto e una di Difesa senza ripetizioni, sostituibili nel catalogo grande con filtri. Le carte selezionano singole skill delle Art, ordinate dal livello richiesto più basso. «Livello richiesto X» e, ad esempio, «Nome I · prossima II, lvl 6»; II rimane bloccata finché non si raggiunge 6. Hover di 0,9 secondi o pressione prolungata mostra evoluzioni, costi, effetti, CD e livelli. I costi sono pagamenti reali e restano editabili/serializzati.
- Crafting/forgiatura degli indossabili: chance `min(90, 10 + Fortuna)%`, tetto 100% per Rebirthati. Una sola estrazione alla creazione riuscita; bonus pari al livello dell'oggetto a Danni se offensivo, Difesa se difensivo, entrambi se ibrido. Una forgiatura riuscita aggiunge un livello all'oggetto. Esito salvato, senza nuove estrazioni ricaricando. Aggiunte ricette dai nuovi drop e sete magiche antiurto con resistenze editabili.
- Scroll dei Rebirthati: Fortuna ×1,5 arrotondata per eccesso; restano tetti 75% prima del Grado IX del personaggio e 90% dal IX. Affinità +15 punti include gli elementi delle armi equipaggiate.
- Trasparenza regolabile: superfici 0–40%, impostazione iniziale 18%; testi/icone restano sempre visibili. Hover ripristina le superfici; entrando in Tiri e azioni si evidenziano i tasti del gruppo, poi soltanto quello sotto il mouse. Layout telefono con azioni principali in due colonne e altri tiri espandibili. Colori coerenti con elemento e ambiente, distinti dalle risorse.

## Creature, scroll e animazioni — conferme 25 ottobre 2026

- Le tecniche scritte sotto un mostro sono sue capacità; le condizioni di uccisione governano le ricompense. Costi reali, cooldown e requisiti del livello del singolo utilizzatore si applicano anche ai mostri. Nascondere le forme in cooldown dai pannelli rapidi, conservandole negli editor.
- Apprendimento scroll: 20 naturale, DT `30 + 10×Grado scroll + 2×max(0, livello richiesto dalla skill − livello personaggio)`. Fortuna dà +1 punto percentuale per punto. Un elemento già utilizzabile, incluse Art e armi equipaggiate, dà +15 punti. Tetto finale 75% sotto il Grado IX del personaggio, 90% dal IX, inclusi tutti i bonus. La finestra mostra la chance colorata prima di consumare: fasce iniziali UI rosso ≤20, arancione ≤40, giallo ≤55, giallo-verde ≤74, verde acceso oltre.
- Empatici: 10% iniziale, +6 Empatia; nome completo nella scheda, «Scostubandito»/«GranScostumato» in turnistica. Entrambi non letali e sottraggono il 50% degli Obser personali. L’ultima precisazione sostituisce il premio ipotizzato: chi li uccide PERDE `10 + 3×livello mostro` Obser, una sola volta e fino a zero. Cassa comune esclusa. Fino al Riposo Lungo gli Scostubanditi e i GranScostumati riconoscono l’uccisore con un teschio, gli danno priorità e infliggono +25% Danni; gli Empatici restano non letali.
- Feralis è Mini Boss. Normale resistenza al primo elemento ricevuto diverso dai propri; in più Resistenza elementale separata per Fuoco/Acqua/Gelo/Terra/Vento/Fulmine: +15 per colpo fino al 150%, azzerata a fine fight. L’immagine scura approvata è della variante più forte Feralis Ancestrale, distinta dal base. La descrizione del base segue il riferimento IA fornito dall’utente; le altre creature restano originali, ispirate ai riferimenti.
- Furia Primordiale: a metà Vita o meno, danni doppi/ricevuti metà, un quarto Oculum massimo solo all’attivazione; dal secondo turno personale 3 Oculum e +5 Danni/+2 Difesa cumulativi, termina se non pagabile o a scelta. La tua morte è la mia rinascita recupera metà Vita e Oculum CORRENTI per uccisione, entro i massimi.
- Seconda Vita e Rianimazione, soglie dei drop, Ki Mortale, Bramble, ThunderBird, Sempre Verde, GranScostumato, Teschi, Ogor, Teirak, Laer, Torretta e Manichino sono descritti separatamente nel nuovo capitolo del manuale interno/esportato. I valori mancanti di bilanciamento sono iniziali modificabili, non ulteriori conferme numeriche dell’utente.
- Ki Mortale usa Oculum ATTUALE ÷6, migliorabile con un critico per divisore fino a ÷3. Barra verde persistente finché spesa; sostituisce Oculum. Ogni veloce extra costa 5 Ki. Attivazione gratuita e una Azione extra, CD 2 sessioni; meno di 5 Ki dà invece bonus alle statistiche per una Azione.
- DeadlySins: Boss con 13 Oculum di base al livello 0. Colpo potenziato costi definitivi 9/13/16, durata tre turni, CD condiviso nove; I depotenziata (valore iniziale +Forza), II/III +2×Forza. Regen: propria Azione, Resistenza, recupera metà Vita persa nell’ultimo attacco, tutta con critico positivo O negativo; una volta per quel colpo, CD 4 proposto e accettato. Adattamento dell’arma dopo NOVE Riposi Lunghi d’uso, non dieci sessioni. Katana consolida un terzo per difetto del guadagno a fine sessione.
- Monster Book: contatori del party nella campagna, varianti separate e totale specie. Le immagini fornite sono riferimenti descrittivi, non ritratti importati; gli sfondi generati sono temi. L’immagine della forgia con il piccolo essere di brace è approvata per Fuocherelli.
- Le animazioni devono essere artistiche, coerenti e discrete, rispettare le direttive della lore e lasciare i controlli fermi e utilizzabili. La modalità Viva e le preferenze Movimento restano scelte dell’utente.
- Ultima istruzione sulle build: non eseguirle in questa fase. Conservare i pacchetti presenti e preparare commit/push e comando manuale GitHub. Non dichiarare aggiornati i download fino alla pubblicazione riuscita.

## Maschere, Percezione e temi — 25 ottobre 2026

Conferma aggiuntiva: finché è Master, il Master dispone di tutti i temi e le reliquie e può assegnarli. L’utente ha confermato «Solo per la scheda scelta»: assegnare un aspetto conserva solo quel tema/reliquia e colore nel JSON della scheda destinataria, senza sbloccarli per il party né rivelare informazioni sui mostri. L’accesso completo deriva dal ruolo attuale e termina quando si torna giocatore; le assegnazioni ricevute restano disponibili. La scelta Automatico ripristina l’aspetto del mostro/piano senza cancellare gli sblocchi. Online si usa il ruolo autenticato Master e il percorso esistente delle modifiche alla scheda, rispettando la sola lettura.

Consultazione dei mostri: aspetto, comportamento, habitat, statistiche base, punto debole, resistenze, skill, Buff Open, Skill Open e drop vengono consultati in sezioni distinte. Ogni tecnica presenta separatamente forme, requisiti, costi e cooldown letti dai dati reali. È una modifica di presentazione: non aggiunge effetti né modifica quelli personalizzati salvati. I codici tecnici degli effetti speciali non sostituiscono la loro descrizione.

Uomo con la maschera: quattro colori, Verde (Resilienza e Ricordo Vitale permanente secondo la condizione esistente), Rosso (Volontà), Blu (Materia), Viola (Oculum). Pugno serio è gratuito in Azioni/Reazioni, CD condiviso 3 turni: tira Schianto e aggiunge il totale al danno, poi +10/20/50% secondo la forma. Concatenazione blu usa una sola Azione o Reazione, CD condiviso 2 turni. Riflessi +5: 1d5+1 / 1d6+3 / 1d8+5 colpi, ciascuno da un terzo dei Danni; Precisione, disponibile solo dopo la scoperta del punto debole: 1d3+1 / 1d5+2 / 1d6+3 colpi, ciascuno da tre settimi dei Danni e con la normale Fragilità di Precisione applicata prima del singolo colpo. Puoi distribuire la raffica fra bersagli fino al numero di colpi; il danno si divide fra loro e aumenta del 5% per bersaglio. Inizia l’ultimo aggressore, se selezionato, altrimenti l’ordine è casuale. Una difesa critica positiva che supera l’attacco ferma tutti i colpi futuri; dal terzo colpo basta il critico positivo di un bersaglio selezionato, anche prima che venga il suo colpo. I danni già subiti restano. Il Viola recupera 2 Oculum al proprio turno; se già pieno ha il 20% di ricevere 1 temporaneo.

L’Ombra Ignota è una variante separata: maschera nera a spirale con un solo foro a mandorla e un occhio viola. L’Art L’Ombra rende immune al Fisico e aggiunge +5 ai tiri di Attacco e Difesa: forma I una propria azione, II fino alla fine del turno corrente, III fino al prossimo turno personale. Se prima in iniziativa, +3 Danni e +1 Difesa ogni 10 livelli, minimo +2 e +1. Teletrasporto nell’ombra: +9 al prossimo Attacco oppure +10 alla prossima Difesa, senza doppio consumo di Azione/Reazione; chance 10/15/30% di una Reazione veloce extra secondo l’ultima forma dell’Art.

Assassini Solari: maschera d’oro con sole inciso, raggi, piccoli soli e arco con due frecce solari, +3 al tiro. Assassini Angelici: arco con tre frecce angeliche, +9 al tiro, fino a tre bersagli; +25% Danni contro Chaos. Ogni tre colpi che tolgono Vita recuperano il 5% della Vita corrente per eccesso, senza risorgere a zero. Contatore azzerato a fine fight. Costi, forme, cooldown ed effetti restano modificabili e salvati.

Cinque creature comuni di livello iniziale 1: Vèndulo, Rascalume, Brumìlio, Gùravo e Mìrula; nessun bonus straordinario alle statistiche, due tecniche e materiali coerenti per ciascuna. Il catalogo planare comprende ora 357 voci fra specie e varianti.

Percezione, Investigazione, Furbizia e Valutazione: con dado naturale almeno 18 e lettura riuscita, il confronto di Livello + somma delle quattro statistiche dà solo un giudizio narrativo. Entro ±10% siete alla pari o quasi; fra 10 e 35% leggermente più forte/debole, oltre 35% nettamente; avversario almeno doppio: impossibile da battere. Non rivela il punteggio. Se la lettura fallisce, il log indica solo la statistica più alta che ostacola la percezione.

Temi e reliquie: comprare la pagina del mostro sblocca il suo aspetto per il party; una lettura riuscita che lo identifica ha il 90% di sbloccarlo, ritentabile con una nuova lettura riuscita. Varianti separate richiedono il proprio sblocco. La campagna condivide gli sblocchi, ogni scheda sceglie il proprio tema. Mostri ed evocazioni conservano l’aspetto della propria variante; i piani cambiano automaticamente il tema salvo scelta manuale della scheda. Colore e scelta restano nel JSON. Il selettore reliquie ha ricerca e righe da quattro.

Home: “Immagini Home” mantiene la scelta manuale o il casuale di sessione; la seconda opzione “Usa il tema attuale” mostra la stessa illustrazione del tema della scheda. Rame fatato originale è conservato. I campi colore accettano HEX #RGB, #RRGGBB e 0xAARRGGBB; i valori non validi non sostituiscono il colore.

Canone visivo: Luna buona, morta e assente dal cielo; Sole malvagio con l’occhio oro/arancio e pupilla scura del tema Benedict. Lunari e Stelle alleati, Solari nemici; fate generalmente malvagie, mai associate alla Luna. La maggioranza dei diavoli è lunare e il castello nero con luna rossa è una roccaforte alleata. Benedict è l’eroina solare eccezionale, la statua di marmo e oro protegge la città bassa di Lost Town. Obser: pietra grigia crepata con occhio centrale inciso. Dettagli in docs/OCULUM_LORE_VISIVA.md.

## Turnistica di sessione e inventario di Volontà — 25 ottobre 2026

Turnistica di sessione: resta utilizzabile per le azioni di roleplay anche fuori combattimento. Il Master usa Inizia fight per ritirare tutte le iniziative e iniziare il giro 0; il comando diventa Fine combattimento durante lo scontro. Alla fine vengono assegnati i drop e restano party e alleati, con turnistica ancora utilizzabile. Il consumo di Azioni e Reazioni segue la turnistica anche fuori fight; gli effetti riservati al combattimento restano separati.
Inventario di Volontà: non è gestito da borse, ma da uno spazio generato dalla tua Volontà, sempre più ampio e capace di reggere peso. A 15 Volontà è una stanzetta, da 25 una stanza sempre più grande; a 500 puoi creare un intero regno. La capacità meccanica resta Volontà totale ×3 kg. Il regno occupa il 25% della capacità, limitato allo spazio libero se inferiore; cambia dimensione con lo spazio e la Volontà. Ogni kg effettivamente occupato dà +0,01% Danni e Difesa e +0,005% ai sottotratti, nessun aumento alle quattro statistiche. I risultati finali si arrotondano per difetto. Esempio: 375 kg → +3,75% Danni/Difesa e +1,875% sottotratti. Il bonus dura finché il regno esiste; in Inventario puoi crearlo o distruggerlo, liberando peso e rimuovendo il bonus.

## Nuvì, conigli e difese percentuali — 25 ottobre 2026

Nuvì è il nome confermato della creatura soffice e normalmente pacifica. Ogni esemplare riceve un colore nel nome (Avorio, Lavanda, Pesca, Celeste, Menta), conservato nel JSON. Ha soltanto il volo naturale permanente: +3 Difesa e +3 Movimento, nessun costo o tecnica offensiva; questa richiesta specifica prevale sull’Open generica per tutti i mostri.
Coniglio Prestigiatore: Mezzano, livello base 3, telecinesi e tre affinità elementali casuali scelte alla creazione e salvate, ognuna con la propria tecnica. Cappello magico costa 2/3/4 Oculum secondo la forma, cooldown condiviso 4 turni. La prima Azione prepara Instabile (−2, un colpo); ogni successiva Azione personale può caricare Stabile (+1, due colpi) e Perfetto (+5, tre colpi). Il lancio è incluso nell’ultima Azione, senza doppia spesa. Puoi scegliere fino a tre bersagli; con meno bersagli i colpi si ripetono fino al numero previsto. Ogni nuovo bersaglio dopo il primo aggiunge +25% del danno base, ogni colpo aggiuntivo sullo stesso +30%; ogni colpo estrae indipendentemente il 60% di usare l’elemento cui il proprio bersaglio è più fragile. Se non ha fragilità, l’elemento resta casuale. Il danno base iniziale del raggio è Danni della scheda +12 +6×Forma; conserva buff e protezioni normali.
Coniglio al Plasma: variante robot di Postea, livello base 3, zero Oculum, raggi runici al plasma e telecinesi alimentati da Materia. L’oggetto Catene runiche d’intrappolamento immobilizza dopo il colpo riuscito fino a una prova di Forza o Riflessi pari o superiore al tiro originale; nessuna scadenza a turni. La liberazione usa la normale risorsa del tiro.
Coniglio al Plasma: Ricarica di Materia I/II/III recupera 1d4 / 1d8+3 / 1d12+6, senza costo statistico, con Azione nel proprio turno o Reazione fuori turno e CD condiviso 4 turni. Riempie prima la Materia mancante; metà dell'eccesso per difetto diventa Materia temporanea, spesa prima della normale e rimossa a fine scontro.
Pupazzo Vivente Artigliato: forma magica del Regno Mezzano, vuota all'interno e animata dalla magia, con colori variabili, maniche lunghe, artigli e gambe corte a molla. Artigli +15/+22/+30 danni Taglio. Fuoco ×2; danni spirituali e all'Anima non lo danneggiano. Scatto a molla costa Materia 1/2/3, CD condiviso 4 turni, +3 ai tiri di Attacco/Difesa per un turno e 90% di una Reazione veloce extra. Costume del Pupazzo: totale Drop ≥43, una tecnica casuale diversa dal salto più Scatto a molla, entrambi con costo e cooldown.
Robot Artigliato a Molla: variante di Postea, tecniche Plasma, Energia e Fulmine; Fulmine rigenera il 100%, Taglio/Fuoco −50%, Contundente ×2. Gli Scarti robotici consentono tre tentativi con Meccanica o Crafting −2: supera strettamente DT 26 + livello robot + max(0, livello robot − tuo livello). Critico positivo deve comunque superarla: statistiche 100%; successo normale 80%, stessa Vita e resistenze. Critico negativo esaurisce i tentativi. I rottami distrutti danno un solo tiro al 65% per un nucleo rotto del livello del robot.
Mecha: Azione personale per entrare o uscire. Il corpo del robot assorbe prima i danni con Vita propria. Il pilota mantiene le proprie risorse e riceve una Reazione del mecha al proprio turno, veloce con costruzione critica. Da solo il robot ha una sola Reazione (veloce se critico), nessuna Azione e infligge il 40% dei danni. Il tasto Esci dal mecha resta visibile; uscendo spariscono statistiche, resistenze, abilità ed effetti del robot e si ripristinano quelli del pilota. Danni e cooldown del robot restano salvati nel suo corpo, senza guarire entrando e uscendo.
Distruzione del mecha: 30% di esplodere. Fuga senza Reazioni = 1d24 + Riflessi/2 + livello pilota/3; con Reazione = 1d20 + Riflessi +5 + livello/2; veloce dà altri +5 e riduce del 25% i danni se fallisce. Divisioni per difetto; serve superare 16 + livello macchina. Fuga riuscita evita tutto. Danno Esplosivo iniziale modificabile 20 +3×livello macchina, +150% danni agli Scudi, con le normali protezioni del pilota.
Medusa di Vetro (Affogato, livello 2): Puntura erosiva infligge 8/12/16% delle riserve correnti del bersaglio con Difesa e Scudi normali; Campana chiusa aggiunge +20/30/40% Difesa per un turno. Nocciolo Corazzato (Foresta elementale/Mezzano, livello 1): Guscio elastico passivo riduce ogni colpo del 15% prima di Difesa e Scudi, senza tiro né costo; Guscio serrato aggiunge +20/30/40% Difesa per un turno. Valori, costi, forme e cooldown rimangono modificabili; i nuovi materiali e le scroll seguono i drop del catalogo, le catene si ottengono come oggetto su naturale 18+.

## Costi multipli, Open e danno percentuale — 25 ottobre 2026

Skill e forme Art possono configurare fino a quattro risorse consumabili, ciascuna con minimo e massimo. Le risorse aggiuntive si pagano insieme, con verifica completa prima del consumo; sono salvate nel JSON senza rimuovere il costo precedente. Il pagamento alternativo di Observer’s Tear resta distinto.
Le Open mancanti dei mostri ricevono buff coerenti sulla creatura, una Skill separata e cooldown modificabili. Il bonus `monster_open_bonus` collega il Buff ai valori reali della Skill Open; lo Scudo protettivo iniziale proposto è 50 + Livello ×3. Le Open personalizzate salvate non vengono sostituite.
Danno percentuale contro il bersaglio: base = Vita attuale + HP temporanei + Scudo + Scudo Oculum. Il 30% di 100+20+30+10 è 48 prima della normale Difesa. Oltre Scudi esclude i due Scudi dalla base (120 → 36) e li ignora nell’applicazione; Oltre Difesa salta soltanto la Difesa. Il bonus percentuale ai propri danni conserva il significato precedente.

## Observer’s Tear e nuove creature — 25 ottobre 2026

Observer’s Tear è la forma normale viola, più forte: livello base 6, statistiche iniziali 10/16/10/6, Manifestazione del Potere +18, 80–200 Obser e 6 Oculum. Mani invisibili (costo totale 3/5/7) e tentacoli (2/3/4) si pagano liberamente in Obser, Oculum o entrambi; aggiungono Manifestazione del Potere e somma delle risorse spese ai danni. ObserSunshine è la variante solare dorata: livello 3, statistiche 5/10/6/0, Manifestazione +10, 20–100 Obser, zero Oculum; mani 6/9/12 e tentacoli 4/6/8, esclusivamente Obser. I tentacoli immobilizzano per un turno dopo un colpo riuscito. CD mani 3/3/4, tentacoli 3/4/4. Il controattacco contro entrambe riceve +120% Danni prima delle protezioni se vinto, pareggiato o perso di massimo 3 punti. Gli Obser non spesi del nemico ucciso vanno in cassa comune una sola volta per sconfitta, esclusi gli evocati.
Il pagamento misto mostra cinque piccoli suggerimenti sulla stessa riga: Oculum, ¼ Obser, ½ Obser, ¾ Obser, Obser. Tooltip dopo 0,8 secondi di hover e pressione prolungata mostrano quantità esatte. Gli scarti vanno alla quota maggiore; a 50/50 si sceglie casualmente una volta per finestra. I valori restano modificabili manualmente. Sunshine non mostra pagamenti Oculum.
Saltalungo Maculato: Mezzano/Foresta elementale, livello base 2, braccia allungabili e salti enormi, Riflessi +6 da coda integra. Un critico mirato alla coda con perdita di Vita rimuove il +6 e dà −3 Iniziativa fino a fine scontro, senza cumulare. Famelico dell’Oblio: Oblio/Shadow Hell, livello base 4, assalto con tiro Forza o Riflessi e danni aggiuntivi pari alla loro somma; Morso avvia uno stadio di memoria incrinata, controllo con Resistenza, Canalizzazione, Memoria, Controllo corporeo o Crepa contro il totale del Morso. Riuscita rimuove uno stadio, fallimento ne aggiunge uno; al quinto stadio 50% di perdere la Reazione normale al proprio turno, log «cosa stavo facendo?». Riposo Lungo azzera gli stadi. La morte causata dal Famelico nasconde l’identità nei riferimenti del party, conservando scheda, progressi e premi. Tutte e quattro le voci hanno materiali distinti, scroll su naturale 18+ e reliquia su 20; livelli, statistiche, costi, cooldown e tecniche sono modificabili negli editor e nei JSON.

## Presentazione del catalogo Skill e Art — 25 ottobre 2026

Il catalogo include tecniche delle creature e delle Art iniziali e salvate, senza modificare le definizioni personalizzate. Le carte si adattano a desktop, tablet e telefono; il bordo indica il costo e il nome la statistica potenziata. Oculum: viola; Fortuna: oro; Obser: grigio sfumato Oculum; materiali e oggetti: nero opaco. Volontà, Materia e Resilienza mantengono i colori della scheda. Costi combinati e beneficio sfumano nello stesso bordo. Le forme restano espandibili e modificabili negli editor esistenti.

## Controattacco e risorse personali — conferme 25 ottobre 2026

Aumento di velocità è una skill a tre forme con attivazione gratuita anche a risorse di turno esaurite; consuma soltanto il costo statistico/risorsa del mostro. CD personali condivisi fra le forme: 6/4/3. I e II concedono una Reazione normale extra al prossimo turno personale; III concede subito una veloce extra, anche nel giro 0 quando può sommarsi a quella iniziale. II e III danno +10% Attacco e Difesa per un turno; tutte le forme danno +1/+3/+6 Iniziativa per un turno. Le extra sono separate dalla veloce iniziale. Valori iniziali modificabili: Lepre Scattobrina (Terre di ghiaccio), costo Volontà 1/2/3; Geco Turbina (Postea), Materia 1/2/3; Mantide Sanguescatto (Foresta elementale), Vita 5/8/12. Sono tre specie distinte, con anatomia, punto debole, materiali e tecnica offensiva propria; abilità apprendibili e scroll seguono le normali regole.

Queste conferme prevalgono sui rinnovi di Reazione veloce descritti nelle sezioni precedenti. Dopo l’iniziativa (giro 0) tutti ricevono una Reazione veloce; l’Azione arriva al proprio turno. Dal giro 1, al proprio turno arrivano Azione e Reazione normale: questa sostituisce la veloce iniziale, che non viene rigenerata. La veloce inutilizzata fino al proprio turno del giro 1 concede +9 al prossimo tiro e +5 ai prossimi Danni o Difesa; i premi iniziano dal secondo turno personale, non dal primo. Utility e Percezione consumano il +9 ma conservano il +5 fino al successivo attacco/difesa. La Reazione normale inutilizzata mantiene il bonus +3 già previsto e il bonus complessivo ai tiri resta massimo +12. Le risorse consumate non ricompaiono al cambio del giro globale: si rinnovano al turno del proprietario.

Spendere una Reazione veloce aggiunge +3 al relativo tiro (attacco, difesa, Utility, Percezione e varianti); chi è primo nella turnistica riceve invece +6 nel solo giro 0. Il bonus si consuma una sola volta. A risorse esaurite non si può agire; resta gratuita la prima difesa contro ciascun attacco.

Attacco contro attacco: puoi rispondere a un colpo ancora da difendere attaccando il suo autore. Se il tuo totale supera quello nemico infliggi il tuo danno e non ricevi il suo; con parità entrambi ricevono il 50% del danno dell’altro; se perdi di 1–3 punti ricevi il 75% e infliggi il 25%; se perdi di almeno 4 ricevi il 100% e non infliggi danni. Le percentuali sono arrotondate per difetto e applicate prima di Difesa, resistenze e Scudi di ciascuno. Consuma una sola risorsa: Azione nel proprio turno; se sei il prossimo partecipante, anticipa la prossima Azione e la lascia consumata quando arriva il tuo turno; altrimenti una Reazione normale o veloce. La parità vinta dalla difesa resta valida nel confronto ordinario attacco/difesa.

## Specie base e varianti del Monster Book — 24 ottobre 2026

- Quattro specie base sono disponibili come voci distinte: Lupo (`lupo_base`), Goblin (`goblin_base`), Coboldo (`kobold_base`, nome italiano visualizzato “Coboldo”) e Gnoll (`gnoll_base`). Il Lupo comune non sostituisce il Lupo Gigante né il Lupo delle Nevi.
- Varianti aggiunte: Goblin Incendiario (Mezzano/Regno demoniaco), Coboldo Minatore (Regni sotterranei), Coboldo Runico di Postea, Gnoll delle Nevi (Terre di ghiaccio) e Gnoll Diabolico (Regno diabolico). Ogni variante mantiene un ID e un materiale distintivi, un punto debole descritto e due tecniche con nomi/ruoli propri; si collega alla specie base per i progressi del Monster Book Party.
- Le mosse sono bilanciamenti iniziali: forme I–III, costo Oculum 1/2/3, cooldown 2/2/3 per gli attacchi e 2/3/3 per le protezioni; le tecniche di Grado più alto hanno requisiti di livello. Le skill di Gelo e Fuoco applicano la propria condizione solo nelle forme superiori e su colpo riuscito. Costi, valori, cooldown, requisiti, drop, statistiche, debolezze, resistenze, descrizioni e habitat restano modificabili nel Monster Book e salvabili nel JSON.
- Le voci sono additive: non rinominano o sovrascrivono personalizzazioni già salvate. Le varianti non sono copie generiche: il Gnoll di Ghiaccio usa falce e rallentamento; quello Diabolico usa lancia e riposizionamento; il Coboldo di Postea usa rune di Fulmine e paratia; quello minatore usa piccozza e copertura; il Goblin Incendiario usa pece e fumo; il Lupo comune usa morso e passo laterale.

## Varianti del Lupo delle Nevi — bilanciamento iniziale del 24 ottobre 2026

- Aggiunta una famiglia coerente collegata alla specie esistente `lupo_di_bruma`: Lupo delle Nevi (Terre di ghiaccio), Lupo Infernale del Ghiaccio (Regno demoniaco), Lupo d’Ombra dell’Oblio (Oblio/Shadow Hell) e Lupo Runico di Postea. Le varianti condividono i progressi di specie del party, ma conservano aspetto, elementi, debolezze, skill, drop e ID distinti; i salvataggi delle voci esistenti non vengono rinominati.
- Le skill delle nuove forme richiedono dal livello della creatura; le forme II e III richiedono rispettivamente +3 e +6 livelli e pagano Oculum con cooldown. I valori proposti si possono modificare nel Monster Book.
- Drop: naturale 8+ materiale distintivo della variante (Zanna brinata, Scheggia di brace lupina, Filo ululante d’Oblio, Dente a circuito); naturale 18+ entrambe le scroll delle skill della forma; naturale 20 reliquia arma con una skill collegata, utilizzabile al livello richiesto. Le scroll conservano apprendimento normale. I materiali fondono con equipaggiamento compatibile e aggiungono Danni o Difesa secondo livello/Grado; l’oggetto risultante conserva i requisiti e la skill del pezzo base.

## Meccanio — conferme successive del 24 ottobre 2026

- Varianti canoniche aggiuntive richieste: ruoli distinti, descrizioni proprie e skill nuove coerenti con il luogo. Sei nuove voci iniziali: Goblin Assassino, Goblin Arciere, Segugio runico Sentinella, Ragno saldatore Recuperatore, Marshmallow e Marshmallow Incenerito. Mantengono gli ID e il legame al capostipite; non generano a loro volta una variante generica ripetuta. Forme, costi, cooldown, statistiche e materiali sono bilanciamenti iniziali modificabili, non ulteriori regole imposte dal manuale.
- Estensione successiva della famiglia: Lupo delle Nevi nelle Terre di ghiaccio, Lupo Infernale del Ghiaccio nel Regno demoniaco, Lupo d’Ombra in Oblio/Shadow Hell e Lupo Runico a Postea. Le forme discendono dal Lupo delle Nevi e i progressi di uccisione restano unici per specie. Naturalmente 8+ lascia materiale, 18+ le due scroll, 20 una reliquia arma con skill. Forme II/III richiedono +3/+6 livelli; costi, cooldown, abilità e requisiti restano modificabili.
- Thunder Bot: sfera rotante di Postea, senza Oculum, Art o Difesa. La sola abilità è l'autodistruzione, con un attacco Fulmine contro tutti gli avversari dello schieramento, senza limite di bersagli. Danno base a ciascuno = Vita attuale + Danni inflitti della scheda, non diviso fra i bersagli. Consuma la normale Azione, nessun costo di statistiche; dopo il lancio il bot muore. Non usa la Vita massima e non somma il danno storico dello scontro. Statistiche iniziali proposte modificabili: livello 2, RES2/VOL0/MAT4/OCU0.

- Queste indicazioni prevalgono sulla prima bozza di Meccanio riportata sotto. L'implementazione estesa deve ancora essere completata e verificata prima della distribuzione.
- Aspetto: robottino su una sola ruota, busto e testa arrotondati, grandi lenti luminose, braccia snodate con pinze; colore variabile per acquisto, da conservare sulla singola creatura.
- Nessun Oculum né Art. Tre skill casuali, con almeno una offensiva; Protezioni di Emergenza è sempre presente e separata dalle tre skill. Una sola Open casuale con buff e tecnica coerenti. Forme I–III e cooldown separati: quando la forma superiore è in recupero, le inferiori restano utilizzabili se disponibili.
- Meccanio dispone solo di Reazioni. Mitra sulla spalla è gratuito e limitato dal cooldown. Sfera elettro consuma una Reazione per iniziare la carica e concede nel prossimo turno di Meccanio un'unica Azione dedicata al lancio. Durante la carica valgono i controlli di Concentrazione già confermati, soltanto quando perde Vita, senza controlli per danni interamente assorbiti dagli Scudi o dagli HP temporanei.
- Missile e Mitra automatici sono Open alternative. Missile infligge 50+25 danni a ciascun nemico e cura ciascun alleato del 75% della Vita realmente sottratta complessivamente ai nemici, entro la Vita massima. Scudi, HP temporanei e sovradanno non aumentano la cura.
- Riparazioni con Meccanica al posto di Medicina, anche eseguite dal padrone. Droni riparatori raddoppiano la riparazione; a Vita piena si ottiene Scudo entro il limite della forma. Scudo iniziale e limite di riparazione possono essere distinti: una riparazione non deve sottrarre Scudo già presente.
- Ogni evento di rigenerazione in presenza di Scudo Oculum concede +1 Resilienza e +2 Volontà/Materia. Meccanio non riceve Oculum. Ciascuna statistica è limitata al corrispondente valore del padrone; i bonus durano fino al Riposo Lungo eseguito dal padrone. La formula numerica che lega le statistiche alla percentuale di integrità resta un bilanciamento iniziale modificabile.
- Resistenze confermate: livello 0, riduzione Taglio 25% e cura dal Fulmine pari al 25% del danno; livello 10, 50%; livello 20, 75%; livello 30, immunità al Taglio e rigenerazione totale dal Fulmine (100%).
- Folgorazione: su critico, unica estrazione esclusiva 15% tutti i nemici colpiti / 25% i due più deboli fra i colpiti / 30% il più debole fra i colpiti / 30% nessuna Folgorazione. Non si selezionano avversari non colpiti; con meno bersagli si usano solo quelli presenti.
- Pool richiesto: Raggi mortali rari (critico: Oltre Difesa per un turno), Droni riparatori, Folgorazione fino a tre bersagli, Mitra sulla spalla, Sfera elettro e nuove tecniche coerenti. I numeri non precisati restano proposte di bilanciamento modificabili.
- Varianti selvatiche: Ammaccato (più debole), Primordiale (roccia e rune del Fulmine) ed Élite (più forte). Se privo di padrone, addestramento con Meccanica ≥ 13 + livello Meccanio + 3 × suo Grado. Massimo un Meccanio per padrone.
- Precisazione successiva: i nomi visualizzati sono Malconcio e Primitivo (ID precedenti conservati). Malconcio ha metà Scudo e skill indebolite; Primitivo più Difesa, meno Scudo e poco Scudo Oculum; Élite skill potenziate. Bilanciamento iniziale modificabile nel JSON `meccanio`: potenza skill 75/100/125%, Scudo iniziale 90/120/180% Vita rispettivamente Malconcio/Primitivo/Élite; Primitivo +3 Difesa e Scudo Oculum 10% Vita. I limiti di riparazione del Malconcio sono dimezzati rispetto alla forma normale.
- Ogni aggressione del futuro padrone o del padrone imposta al 60% il rifiuto dei suoi comandi, controllato a ogni comando. Ogni suo Riposo Breve riduce la probabilità di 20 punti; ogni suo Riposo Lungo di 50, minimo zero.
- Empatia compare in Supporto e utilità del padrone: un solo tiro tra due riposi, recuperato sia con Riposo Breve sia con Riposo Lungo. Sottrae il totale del tiro in punti percentuali dal rifiuto di Meccanio, minimo zero (esempio: 17 trasforma 60% in 43%). Non è una riduzione moltiplicativa.
- Inganno è un'alternativa che condivide l'unico tentativo per riposo con Empatia. Con dado naturale sotto 12 il rifiuto aumenta di 10 punti percentuali, massimo 100%; altrimenti sottrae il totale come Empatia.
- Se il padrone protegge Meccanio con Aiuto e la difesa riesce, il rifiuto diminuisce di 5–30 punti percentuali casuali, minimo zero. Se fallisce, diminuisce comunque di 2–40 punti proporzionali alla percentuale di Vita massima persa dal padrone durante la protezione: 2 + 38 × frazione persa, arrotondato e limitato a 2–40. Un solo premio per attacco risolto; gli aiuti offensivi non lo attivano. Scudi e HP temporanei non contano come Vita persa.

## Conferme del 23 ottobre 2026 — bestiario e quest

- Conferma del 24 ottobre: Raggio Angelico e Richiamo dei Piranha sono acquistabili come pergamene apprendibili nei rispettivi mercati Angelico/Sacro e Affogato. Seguono costo Volontà, recupero e apprendimento normali delle pergamene. Prezzi iniziali: 300 × (Grado+1)² Obser, moltiplicati per il mercato (Angelico ×1,2; Sacro ×3 e Grado minimo III; Affogato ×1), poi modifica personale del mercante. Definizioni e prezzi salvati restano modificabili.
- Meccanio: compagno robot acquistabile a Postea, pacifico/neutrale. Si autoripara con Meccanica al posto di Medicina e può essere riparato dal padrone con il suo tiro di Meccanica, usando la cura ordinaria (totale del tiro, doppio su 20 naturale, entro la Vita massima). Combatte con turnistica ordinaria e rimane nel party dopo lo scontro. Valori iniziali proposti e modificabili: livello 0, RES4/VOL2/MAT4/OCU0, prezzo 120 Obser, peso 6 kg.
- Moderazione delle stanze: Master e Co-Master possono espellere i giocatori; ban, revoca del ban e relativo elenco sono riservati al Master e verificati anche dal server.

- Piranha Mortale: creatura comune del Regno Affogato, caccia in gruppo; i suoi attacchi coordinati usano un solo tiro e non moltiplicano il danno per ogni pesce. Può richiamare fino a due Piranha minori con iniziativa, 1/3/5 Vita secondo la forma, 1 Resilienza, senza abilità né capacità di evocare altri. Il Morso può applicare Sanguinante dopo un colpo riuscito; statistiche, costo, durata e recupero sono valori iniziali modificabili.
- Raggio Angelico: skill a elemento Angelico con danno base + Karma dell’attaccante + valore assoluto del Karma negativo del bersaglio. Dopo la somma applica ×2 contro Demoni, ×1,5 contro Diavoli e ×1,3 contro Arcidiavoli. I moltiplicatori e i valori delle forme sono modificabili nella skill salvata.

- Solo alcune skill hanno carica crescente: attivazione 2 Oculum e una Azione; danni +40% senza incrementi, poi +80%, +120% e +180% dopo uno/due/tre incrementi. Ogni incremento costa 1 Oculum e una Azione, massimo uno per turno personale. Rilascio anticipato con normale Azione/Reazione; stessi controlli di Concentrazione quando si perde Vita. Costi e progressione modificabili nell’editor e conservati nel JSON.
- Solo le skill esplicitamente preparate richiedono due fasi: Azione di preparazione; rilascio con il successivo attacco/difesa spendendo normalmente Azione o Reazione, senza una terza risorsa o doppio costo della skill. La preparazione si interrompe soltanto in seguito a perdita di Vita, non se Scudi o HP temporanei assorbono tutto. Bonus Concentrazione +3 = 3% di mantenimento, massimo 100%. Nemico superiore di due Gradi: −10 punti percentuali; di tre: −20; poi altri −10 per ogni Grado.
- Soltanto la scroll fornisce +3 × suo Grado alla Concentrazione per la tecnica che lo richiede; il bonus non resta nella skill appresa e non aumenta la Concentrazione generale.
- Potenziamento: usa lo stesso controllo Preparati già esistente, con soglie di livello/Grado, +3 al tiro per Oculum e +2 Danni per punto se attacchi. Nel tiro di preparazione aumenta anche il mantenimento della concentrazione. Pulsante nella riga Tiri e azioni quando il limite per regola è almeno 1; selezione numerica entro il limite corrente e consumo al prossimo tiro.
- Tecniche che consumano Volontà o Materia: bonus numerici positivi inizialmente aumentati del 20%, arrotondamento per eccesso, come bilanciamento richiesto e modificabile nella formula; non aumenta durate né Azioni/Reazioni.
- Fluttuare: versione ridotta delle Ali di Fata, confermata dall’utente: 1d4 turni, +3 Difesa e +3 Movimento, costo 2 Oculum, CD 3 turni, Azione nel proprio turno o Reazione fuori turno; nessuna immunità automatica. Valori modificabili.
- Quest: tre obiettivi contemporanei brevi, fattibili nel luogo corrente; combattimenti con nemici almeno di livello pari al riferimento del party. Le uccisioni contano dalla comparsa della quest. Obser alla cassa comune; bonus personale a chi completa, con unica estrazione 25% Ispirazione / 10% Super / 5% Oculum / 3% Schivata / 1% tutte e tre più Schivata / 56% nessun bonus personale.
- Bringi: pacifico e neutrale; prima aggressione 1d20 semi, dopo tre colpi ricevuti 1d100+20 semi, ognuno da 1 Vita. Aspetto di scoiattolo con guance piene; assegnazione editoriale al Regno Mezzano e alla Foresta elementale.
- Annichilimento: Titolo Malanno @res-30%, durata tre Riposi Lunghi; la fuga del Diavolo nasconde l’identità nel Monster Book conservando i progressi.
- Premi speciali delle creature: scroll con apprendimento normale. Soglie speciali Drop sul dado naturale. Le nuove statistiche e i costi non espressamente confermati sono bilanciamenti iniziali modificabili, non regole del manuale storico.
- Aggiornamento tecnico: backup verificato dei salvataggi prima della sostituzione; nessuna disinstallazione Android. L’utente autorizza la conservazione della chiave Android come secret privato cifrato GitHub Actions, mai nei sorgenti o nei download. La pubblicazione segue le build riuscite di qualsiasi ramo del repository.

## Correzioni definitive dalla revisione del 22 ottobre 2026

- Percezione fuori turnistica: il tiro usa la prova già prevista e può mirare alle altre schede visibili senza avviare o richiedere l’ordine d’iniziativa. Le informazioni di grado seguono il normale esito della lettura; il punto debole continua a richiedere il critico naturale previsto dalla regola confermata.
- Stanze online inattive: dopo 30 minuti senza impulsi di attività, la stanza viene rimossa; il Master riceve prima un avviso con 60 secondi per evitare la rimozione. Il movimento del mouse di qualunque player rinnova l’attività della stanza.
- Immagini della Home: all’avvio viene scelta casualmente un’immagine/tema grafico se il giocatore non ha già selezionato un pacchetto immagini. Una scelta esplicita resta salvata.

- Padrone della Corruzione: contro un mostro di livello superiore servono tanti colpi pieni quanti sono i livelli di differenza. PG 5 contro mostro 8: tre colpi pieni; i mezzi successi e i colpi durante la ricarica non contano. Dopo un tentativo resistito servono altri tre colpi: il contatore si azzera a ogni tentativo. Conteggi distinti per fonte, bersaglio e fight, persistenti e protetti da duplicati. La resistenza aggiuntiva +50 punti percentuali resta sempre passiva.
- Occhi del Mercato Nero: base casuale 36–69 Obser al livello 0, salvata nell'offerta; crescita lineare fino a 115 al livello 10 e stesso incremento oltre il 10. Esempio autorizzato: base 50 → 115 al livello 10 → 180 al 20. Alla base si aggiungono le statistiche totali del mostro ×2. Ogni blocco completo di 20 statistiche del mostro oltre il totale del personaggio aggiunge 25 punti percentuali al prezzo. Arrotondamento generale per difetto. Mostro livello 10, 18 statistiche, PG con almeno 18: 115+36=151 Obser, prima del modificatore personale del negoziante. Sostituisce la precedente formula statistiche ×5 e crescita percentuale per livello; le offerte già salvate mantengono i propri prezzi.
- Raccoglitore: tredici versioni, Grado 0–XII; ognuna raddoppia i materiali raccolti di Grado pari o inferiore al proprio. «XII» non è un requisito di livello 12. Gli oggetti già salvati non vengono riscritti. Prezzo iniziale di catalogo modificabile: 350+70×Grado Obser.
- Mercanti online: tutti i membri della campagna condividono l’elenco dei mercanti, i banchi e i relativi metadati. Scorte, offerte, prezzi personali, selezioni e contatori d’acquisto restano separati per personaggio e non vengono inviati agli altri. Gli oggetti acquistati restano nell’inventario della scheda e si sincronizzano normalmente. Il roster condiviso usa un evento leggero del party log, senza reinviare la scheda o il catalogo completo.
- Offerte dei mercanti: ogni combinazione mercante/banco seleziona casualmente 6–9 offerte; nel 16% dei casi ne seleziona 12. Gli oggetti devono essere distinti e, quando condividono lo stesso effetto o contenuto, compare una sola versione. Ogni banco mostra solo le categorie che vende. La scelta resta salvata per quel mercante e per quel personaggio; un giocatore vede la propria scorta. Gli oggetti acquistati restano nell’inventario della scheda e si sincronizzano normalmente. La selezione privilegia il livello del personaggio e considera il budget in misura minore. Se un’offerta monouso si esaurisce, viene rimpiazzata mantenendo le altre ancora disponibili. Catalogo e personalizzazioni salvate non vengono cancellati o sovrascritti.
- Cibi e bevande: aggiunti piatti e infusi Oculum, compresi Ricordo Vitale, Vampirismo I–III, +30% Danni, +20% Difesa, Trasparenza, Invisibilità, Accelerato e Concentrato. Gli effetti da combattimento indicati durano 3 turni; condizioni, stadio, durata, bonus e prezzo restano modificabili nella definizione salvata dell’oggetto. Le varianti dello stesso effetto non occupano più offerte dello stesso banco.
- EXP Boss: base ×2 in Normale/Oculum, ×2,1 in Facile, ×1,9 in Difficile. Si mantengono gli aggiustamenti per difficoltà e tutti gli altri confronti EXP. Mini Boss invariati: base ×1,3, ±0,1 in Facile/Difficile.
- Fragilità: Assoluta +90%, Distruttiva +100%, Semi Letale +250%, Letale +500% (danno ×6). Queste conferme risolvono i nomi scambiati e il precedente testo «×5» del manuale.
- Punto debole: il Monster Book mostra «???» finché il party non ha scoperto la creatura o acquistato la relativa pagina. Un critico di Percezione/Investigazione scopre il punto debole anatomico e concede Semi Letale (+250 punti percentuali) fino a fine scontro. Il +250% si somma alla percentuale di danno già impostata, senza sostituirla; non rende automatico il colpo.
- Invisibilità e Trasparenza: soltanto una lettura esatta di Percezione dimezza per difetto il bonus al Velo della condizione attiva. Il dimezzamento si applica a chi individua il bersaglio e ai suoi alleati fino a fine fight; bonus personalizzati e crescita per livello sono dimezzati insieme. Una lettura approssimata o insufficiente non cambia il bonus.
- Precisione mirata: quando il punto debole è noto al party, ogni membro può selezionare «Precisione · punto debole». Usa il tiro e la progressione Precisione già esistenti; il normale esito di attacco determina comunque se colpisce. La pagina acquistata nel Mercato Nero rivela il nome della creatura, punto debole e resistenze e sblocca il tentativo mirato, ma non concede da sola Semi Letale.
- Monster Book Party: scoperte e pagine acquistate si salvano per campagna e si condividono con il party tramite un singolo evento leggero con l’ID stabile della creatura, senza reinviare scheda o Monster Book. Le anatomie e le resistenze sono modificabili nell’editor del Monster Book. Il Mercato Nero offre al massimo tre pagine di creature erranti/aberrazioni, distinte e scelte in base a livello e statistiche del personaggio: 56 Obser per gli erranti, 90 per le aberrazioni.
- Resistenze anatomiche: i tipi di danno restano quelli esistenti e le voci specifiche del mostro si sommano alla percentuale di danno configurata. Per esempio, gusci e corazze riducono Taglio e Perforante e aumentano Contundente; costrutti runici resistono ai colpi taglienti e all’Acido ma cedono più al Contundente e all’Elettrico; entità incorporee resistono ai colpi fisici e cedono alla Luce. Le personalizzazioni esplicite salvate prevalgono sui valori anatomici predefiniti.

## Vampirismo online — richiesta e bilanciamento iniziale del 22 ottobre 2026

- Richiesta dell'utente: automatizzare il recupero HP nel fight online, adeguandolo ai danni effettivi, alla difficoltà e agli HP. Questa indicazione prevale sul precedente uso online dei danni dichiarati. Offline resta il comportamento precedente; resta anche il recupero per stadio a inizio turno.
- Impostazioni iniziali scelte nel bilanciamento richiesto, tutte modificabili nell'editor della condizione e nel JSON: 3% della Vita realmente sottratta per stadio (I–XII); fattori Facile 1,25 / Normale 1 / Difficile 0,75 / Oculum 0,5. Limite cumulativo per singolo attacco pari a 3% della Vita massima di chi cura per stadio, con lo stesso fattore. Arrotondamento per difetto, minimo 1 soltanto se c'è danno Vita e il limite lo consente; mai oltre la Vita sottratta o la Vita mancante.
- Danni agli Scudi o HP temporanei, attacchi evitati, sovradanno oltre gli HP rimasti e pacchetti duplicati non assegnano cura. I bersagli dello stesso attacco condividono il limite; la stessa ricevuta viene consumata una volta, con stato persistente. Colpito manuale durante il fight online non concede una seconda cura. Una vecchia ricevuta senza perdita Vita verificabile non usa i danni dichiarati come ripiego.
- Il recupero avviene sulla scheda dell'attaccante anche se nel frattempo è stata aperta un'altra scheda locale. Le altre regole che modificano le cure, come Maledetto, continuano ad applicarsi.

## Padrone della Corruzione — conferma del 22 ottobre 2026

- Resistenza attiva confermata: il bersaglio di livello pari o superiore alla fonte può tirare Crepa o Fermezza (Volontà), pareggiando o superando il tiro dell'attacco o della pergamena che applica Corruzione. A livello pari applica **−3** al tiro di Crepa/Fermezza; a livello superiore nessuna penalità. A livello inferiore questo tentativo non è disponibile. La prova non sostituisce la resistenza percentuale passiva.

- La passiva aggiunge **+50 punti percentuali** alla resistenza alla Corruzione già presente, senza sostituirla: 20% + 50% = 70%; 50% + 50% = 100%. Il bonus resta modificabile nell'editor della skill e conservato nel suo JSON. Per risolvere il contagio la resistenza effettiva è limitata al 100%, senza abbassare il valore salvato.
- La probabilità base del contagio viene ridotta dalla resistenza totale: possibilità iniziale 100% e resistenza totale 70% danno 30%; possibilità iniziale 60% e resistenza totale 70% danno 18%. Il bonus non si moltiplica per la resistenza preesistente.

## Conferme online e condizioni — 21 ottobre 2026, ultime indicazioni

- Priorità: schede selezionate ricevute dal Master, comprese evocazioni e Occhi attivi. Copie nella cartella separata in fondo, aggiornamenti nella stessa identità anche dopo cambio nome/titolo. Controllo periodico locale delle firme; nessun invio se invariato.
- Attacco, Aiuta compagno e difesa seguono la turnistica condivisa del Master senza attendere approvazione manuale: spendono l’Azione disponibile solo nel proprio turno, altrimenti una Reazione. Il Master approva soltanto l’ingresso di nuovi partecipanti. Tutti iniziano con Reazione disponibile; nel proprio turno si possono usare sia Azione sia Reazione. Massimo un secondo tentativo di difesa per attacco, spendendo un’altra Reazione prima del danno. Le Reazioni ottenute contro un mostro possono essere spese anche per utility.
- Trasparenza: +6 + livello a Velo. Invisibilità: +18 + livello a Velo. Condizioni con bonus e durata modificabili, senza cambiare il valore base del sottotratto.
- Doppio critico: 20 naturale e totale almeno doppio del tiro opposto. Bonus danno +3 per livello e +6 per Grado, minimo +2; +10 punti percentuali alla fragilità. Doppia difesa: +9 al tiro della reazione d’attacco contro l’attaccante. Medicina: cura base pari al totale del tiro, raddoppiata sul critico naturale.
- Corrosione acida è condizione elementale: danni diretti alla Vita a fine turno oltre Difesa e Scudi. Sputatore Corrosivo: valori iniziali autorizzati 2/3/6 danni nelle tre forme, durata Facile 2, Normale 3, Difficile 5, Oculum 6; valori modificabili.
- Drop: +3 in Difficile, +6 in Oculum.
- Goblin Kamikaze: unica Skill, esplosione dopo CD iniziale 2 turni, Vita massima danni a ogni avversario dello schieramento corrente, danneggiamento Scudo 150%, morte del goblin. Come Occhio dei Caduti segue lo schieramento del proprietario.
- Golem Runico: RES10 VOL3 MAT6 OCU0, senza immagine. Passive gratuite con crescita iniziale autorizzata ai livelli 0/3/6: riflessione 10/15/20% dopo difesa superata, malus Difesa 2/3/4 per un turno se infligge perdita Vita effettiva, CM3/4/5. Open attiva dal livello6: Vita attuale danni per ciascun bersaglio scelto, metà sul semicolpito; CD6 e una volta per fight come valori iniziali modificabili.

Ultimo aggiornamento: 22 ottobre 2026. Documento da consultare prima di modificare il regolamento.

## Conferme e impostazioni iniziali del 21 ottobre 2026

- Ogni grado aggiunto a un Titolo o oggetto permette di assegnare 10 punti alle quattro statistiche (Resilienza, Volontà, Materia, Oculum). L'interfaccia rapida mostra −, valore corrente e + per ciascuna statistica; la distribuzione deve totalizzare i punti disponibili. Grado e allocazione sono persistenti e non alterano i vecchi salvataggi privi dei nuovi campi.
- I bonus casuali sugli oggetti del manuale possono riguardare una statistica base o un sottotratto: Resilienza era un esempio, non l'unico bersaglio. Gli affissi sono conservati come comando @ editabile nel JSON dell'oggetto. Probabilità iniziali scelte per il catalogo, ancora modificabili: 20% per +1 e 5% per +2.
- Gli oggetti e materiali derivati dai drop del manuale espongono un prezzo in Obser; equipaggiamento graduato usa i minimi del Fabbro, materiali e componenti iniziano a prezzo basso e scalano con livello e Grado. I prezzi di catalogo e le probabilità degli affissi sono valori iniziali modificabili, non ulteriori soglie confermate dall'utente.

## Conferme successive — aberrazioni e penetrazione

- Aberrazioni d’oro e marmo: Minore = Mostro a due fasi; Intermedia = Mini Boss a due fasi; Maggiore = Boss a due fasi; Superiore = Boss a tre fasi. Varianti Solare (glass cannon, elemento Sole) e Angelica (equilibrata, elemento Luce). Le basi esistenti 20/40/60 e il piccolo surplus angelico restano; per le nuove Superiori è scelto un valore iniziale modificabile 80/82.
- Le prime due fasi usano la stessa barra, passaggio al 50% Vita. Solo la Superiore, alla prima sconfitta, entra nella terza fase recuperando il 75% della Vita massima e ricevendo +2 × livello Danni. Passaggio e risveglio non si ripetono per messaggi duplicati; lo stato è persistente nel JSON.
- Raggi multipli: Minori due bersagli; Intermedie tre con +25 Danni; Maggiori sei con +80 Danni alla forma completa. Per le Superiori si conserva il profilo a sei raggi come base modificabile. Le forme precedenti hanno bonus ridotti.
- Oltre Difesa, Oltre Scudi e percentuale aggiuntiva ai danni sugli Scudi sono parametri del singolo colpo sul bersaglio, consumati con il colpo; non cambiano le impostazioni permanenti della vittima. Nuove tecniche individuali con penetrazione hanno CD 2–5 turni; quelle con Oltre Difesa e CD 2 partono scariche.
- Online la turnistica del Master sostituisce la fonte locale di turni e bersagli del player finché collegato. La turnistica locale resta salvata per il ritorno offline.
- Riconfermato il 21 ottobre 2026: online si usa la turnistica del Master della stanza, non una turnistica manuale separata del player. Lo scontro attivo del Master si pubblica automaticamente; «Pubblica» resta disponibile per un invio esplicito e «Chiudi player» conserva la possibilità di interrompere la pubblicazione. Richiesta schede e invio realtime devono funzionare anche senza amicizia fra i tag. Un tag già appartenente a un altro account non viene riassegnato automaticamente: account originale o copia esplicita con nuovo tag, mantenendo l'originale.
- Il Master conserva la possibilità di agire sulle schede online condivise nella propria stanza; le modifiche autorizzate vengono riportate al proprietario. I controlli sulla proprietà del tag non devono impedire queste operazioni del Master e non trasferiscono la proprietà del personaggio.

## Conferme del 20 ottobre 2026 — emblema, mercanti e Open

- Nei tre pannelli di combattimento non compaiono skill in cooldown o senza risorse per alcuna forma; se almeno una forma è utilizzabile la skill resta visibile e la scelta contiene le sole forme disponibili. I sottotratti come tiri rimangono utilizzabili.
- Le Open mancanti dei mostri vengono completate con un'ultimate che aggiunge al danno base 1d50+25 nei gradi iniziali; i profili più forti crescono da 1d90+60 fino a 1d250+400. Sono valori iniziali modificabili, scelti nel bilanciamento delegato. Sblocco al massimo livello richiesto dalle altre tre forme; Buff Open @Stats+4 (più alto per i gradi maggiori) e capacità ridotta con recupero autonomo di tre turni. Le Open e gli effetti già personalizzati non vengono riscritti.
- Emblema di evocazione dell'alchimista: slime per l'intero fight con **120 HP**, fino a **tre** destinatari scelti (anche se stessi), **+3 a ciascuna delle quattro statistiche e +2 a tutti i sottotratti**. L'utente autorizza il prezzo e richiede che sia maggiore di Pawn: valore iniziale modificabile **200 Obser**, Pawn 100. La Vita dello slime è una riserva condivisa; l'assorbimento riusa il percorso dei Guardiani dopo le difese personali. Non ottiene la rigenerazione di Pawn. Bonus temporanei mentre è vivo e rimozione a fine scontro. HP, bonus, destinatari e durata personalizzata sono salvati nel JSON.
- Ogni mercante ha prezzi leggermente diversi: impostazione ordinaria scelta ±5%. Per nuovo negozio, **3%** di probabilità di aumentare i prezzi del **25%**; **1%** di ridurli del **15%**, senza dichiarare il modificatore. La percentuale è persistente: riaprire, cercare, filtrare e ricaricare non ritirano i prezzi. Arrotondamento per difetto, minimo 1 Obser. Il Segno del Chaos usa quanto effettivamente pagato.
- Catalogo Master nell'inventario: filtri combinabili per Grado e categoria (armi, armature/vesti, scudi, oggetti, consumabili, cibo/bevande, materiali, scroll e compagni/evocazioni). Gli oggetti ibridi possono appartenere a più categorie. Nessuna modifica agli inventari o ai requisiti.
- La singola Open usata viene nascosta da Attacco, Difesa e Supporto e utilità fino al prossimo Riposo Lungo. Dato personale alla scheda, persistente. Le eventuali skill della Open mantengono il proprio comando e recupero.
- L'Open attiva il proprio Open Buff. Gli editor offrono una scelta semplice della collocazione nei pannelli; gli effetti avanzati restano chiusi fino al clic. La collocazione conserva tipi/elementi, parser e JSON. Buff e debuff restano anche in Supporto secondo la conferma precedente.

## Equipaggiamento del Fabbro — conferme e implementazione del 20 ottobre 2026

- Ogni arma, armatura e scudo di catalogo indica il proprio livello. Il livello della skill dell'oggetto non può essere inferiore al livello dell'oggetto; ogni forma può avere un requisito più alto. La skill è utilizzabile solo quando il personaggio raggiunge il requisito e ha l'oggetto equipaggiato. Il requisito viene controllato nel pannello rapido, nell'editor e al momento dell'attivazione, anche se la UI è obsoleta.
- Un oggetto di grado superiore a quello del personaggio non è acquistabile. Gli oggetti dello stesso grado o di grado inferiore sono acquistabili, anche se il personaggio non ha ancora il livello per sbloccarne la skill.
- Minimo prezzo equipaggiamento: Grado 0 50 Obser; ogni grado aggiunge 70, quindi Grado I 120, II 190, III 260, IV 330 e così via. Il minimo del Grado III è 260 Obser. La fascia di livello base è 5 × grado; ogni livello oltre tale fascia aggiunge 10 Obser. Le statistiche possono alzare ulteriormente il prezzo. Questi minimi e formule sono impostazioni iniziali del negozio, non impediscono la personalizzazione dei prezzi.
- I bonus statistici degli equipaggiamenti restano 1–3 punti per livello e sono memorizzati nel JSON. Nuove armi del Fabbro includono Stocco dell'Eco Riflessa (1/4 Riflessi), Martello della Faglia (1/3 Forza), Lancia della Soglia Velata (1/5 Velo) e Pugnale della Misura Esatta (1/4 Precisione). Sono aggiunte anche una corazza e uno scudo con livelli e skill difensive. Le frazioni si attivano soltanto usando il relativo sottotratto e il testo rimane modificabile.
- Testi, livello, grado, bonus, skill, forme, costi, cooldown e formula restano modificabili/salvati nell'oggetto; gli equipaggiamenti già salvati mantengono i loro valori. Il livello degli oggetti legacy senza campo `livelloOggetto` rimane 0 per non alterare i salvataggi.

## Accesso online — conferme del 19 ottobre 2026

- Ospite protetto tramite Supabase, senza registrazione obbligatoria. Email facoltativa nelle Impostazioni, collegabile all’ospite mantenendo la sua identità.
- Accesso online (riconfermato il 20 ottobre 2026): il Master deve accettare ogni nuovo utente. La stessa identità già approvata nella stessa stanza può rientrare senza nuova richiesta, salvo revoca o espulsione. Il codice e il QR individuano la stanza e non autorizzano l'accesso; un ospite che perde la sua identità è un nuovo utente.
- Account utilizzabile su più dispositivi; chiedere se mantenere l’accesso sul dispositivo. L’offline resta disponibile senza account e il login non sovrascrive i salvataggi locali.
- Il Master deve essere autorizzato anche dal backend. Per l’avanzamento delle implementazioni e le verifiche distinte consultare `ONLINE_AUDIT_2026-10-19.md`; le parti ancora in prova non costituiscono consegna completata.

## Mostri e organizzazione — conferme del 19 ottobre 2026

- Correzione del 21 ottobre — Armatura del Patalpa: conserva +5 Difesa; lo Scudo parte da 6 e aumenta di +6 per ogni livello dell’oggetto e di +4 × livello dell’oggetto per ogni Grado: `6 + 6×livello + 4×Grado×livello`. Restano +2 Materia, +1 Volontà, +1 Resilienza e il Richiamo del Patalpa. Il valore calcolato viene salvato sull’oggetto, che resta modificabile.
- Patalpa evocato: il totale delle statistiche segue il budget della creatura al suo livello ed è distribuito 20% Resilienza, 50% Volontà, 30% Materia. Il Patalpa del Bestiario non ha Oculum; nel 75% degli spawn non riceve il punto extra di Resilienza per livello, nel 25% lo riceve. La distribuzione e l’esito casuale sono salvati sulla scheda evocata.
- Richiamo del Patalpa: un uso ogni tre fight completati, conteggiati una sola volta per scontro nella turnistica. Il pulsante tematico «CD ripristinata» è sempre presente nel pannello Supporto e utilità per il Patalpa e la sua armatura; può azzerare il cooldown solo senza uno scontro attivo, online oppure offline.

- Costrutto Rinsecchito, base Grado 0–I: Res 2, Vol 3, Mat 1 crescente, Ocu 3. Tank con scudi; Ricordo Vitale dura Oculum turni e costa 1 Oculum per turno. Attacco +4/+12/+34 più Oculum, seconda forma ×1,5 e terza ×2. Drop nucleo rotto debole fascia 0–III, rami e cuore raro. Il cuore cura il 90% Vita e dà Ricordo Vitale per 1d9 turni.
- Larva Bianca, base Grado 0–I: Res 1, Vol 2, Mat 0, Ocu 0. Il punto debole è il ventre sul lato inferiore, esposto mentre striscia. Mosse gratuite a cooldown. Assalto +5/+15/+45 più Oculum ×1/×1,5/×2. Nidiata 1d100 / 1d200+20 / 1d250+100 larve con 1 Vita, sacrificate una per danno. La riserva compare come barra Vita rossa sotto la Vita del personaggio; dopo Scudi e HP temporanei assorbe un danno per larva. Scavata: fuga su Velo oppure attacco con svantaggio alto. Un 20 sul Drop dà una scroll Nidiata; l'apprendimento dalla scroll resta raro e non automatico.
- L’utente autorizza la scelta di cooldown e potenza dello svantaggio, purché modificabili. I valori iniziali del catalogo sono riportati nel manuale come impostazioni modificabili, non come ulteriori conferme numeriche.
- Schede organizzabili in cartelle/sottocartelle rinominabili, con menu alla pressione prolungata e spostamento libero. Gli identificativi e gli indici fisici delle schede non devono cambiare per organizzare la barra laterale.
- Se evochi un Occhio dei Caduti mentre il suo proprietario è già nella turnistica, la creatura entra automaticamente nello stesso scontro: offline viene aggiunta localmente; online il proprietario invia la scheda e richiede al Master l'inserimento autorizzato.
- Clone d’ombra: la creazione diretta produce una scheda alleata con le statistiche del proprietario tranne Resilienza, 10 Vita e durata pari ai turni di Oculum. La scroll Ombra viva usa invece Vita pari a 5 × livello del proprietario, copia le altre statistiche tranne Resilienza e dura `grado della scroll × 2 + 3` turni. Se il proprietario è già in turnistica, la scheda del clone viene aggiunta allo scontro: offline localmente; online viene inviata al Master, che ne autorizza l’ingresso nella turnistica condivisa.
- Nella schermata iniziale gli occhi seguono il puntatore anche mentre si premono i controlli. Passando sul ruolo Master, gli occhi orientano lo sguardo in direzione opposta al puntatore.

## Fonti e precedenza

1. Correzione esplicita più recente dell'utente, registrata qui con un esempio.
2. [Manuale integrale consultabile](manuale-consultazione.md), esportato dal manuale interno `lib/src/main/oculum_manual_sections.dart` con `dart run scripts/export_manual_reference.dart`.
3. Codice e test indicano il comportamento implementato: non dimostrano da soli che una regola sia corretta.

Non considerare questo registro la prova che ogni regola è già implementata e verificata. Per l'esito della patch consulta il suo rapporto di verifica. Non inventare regole mancanti: chiedi all'utente, registrane la risposta e aggiungi esempi e test.

## Conferme del 18 ottobre 2026: attacco e difesa

**Arrotondamento generale confermato:** normalmente per difetto. Una regola può dichiarare un'eccezione: la Difesa ×1,5 del quasi riuscito arrotonda per eccesso. Non estendere automaticamente questa eccezione ad altri valori.

Indichiamo con A il totale del tiro d'attacco e con D il totale del tiro difensivo. La Difesa numerica della scheda è una grandezza distinta da D.

| Difficoltà | Quasi riuscito | Pieno ordinario | Evitato ordinario |
|---|---|---|---|
| Facile | A − D da 1 a 6 | A − D da 7 in su | A ≤ D |
| Medio/Normale | A − D da 1 a 5 | A − D da 6 in su | A ≤ D |
| Difficile | A − D da 1 a 3 | A − D da 4 in su | A ≤ D |
| Oculum | A = D oppure A = D − 1 | A > D | A ≤ D − 2 |

Quasi riuscito: la Difesa numerica contro quel colpo vale ×1,5, **arrotondata per eccesso** (conferma dell'utente: Difesa 7 → 11). Il danno base non viene dimezzato. La durata degli effetti in turni/azioni è dimezzata, arrotondata per difetto, minimo 0: 1 diventa 0, 3 diventa 1, 6 diventa 3. Un effetto con durata risultante 0 non viene applicato; 0 non significa durata infinita.

Esempio Oculum, D=10: A=9 o 10 quasi riuscito; A=11 pieno; A=8 evitato.

### Critico positivo da tiro doppio

- A almeno doppio di D: critico positivo dell'attacco.
- D almeno doppio di A: difesa critica positiva e una reazione gratuita contro chi ha provato a colpire. Il log deve dire **«reazione gratuita su chi ha provato a colpirti»**; il contrattacco è critico.
- Esempio confermato: A=4, D=8 dà la reazione gratuita al difensore.
- Il raddoppio del danno riguarda **solo il bonus critico**, non il danno totale. Il critico interagisce con gli stadi di resistenza/Fragilità secondo il manuale.
- L'eccezione del critico da tiro doppio ha precedenza sulla fascia ordinaria del quasi riuscito.

Bonus critico ordinario ricevuto, in base al livello L del nemico:

| Difficoltà | Bonus ordinario | Bonus nel critico da tiro doppio |
|---|---|---|
| Facile | 3 × L | 6 × L |
| Medio/Normale | 2 × L | 4 × L |
| Difficile | L | 2 × L |
| Oculum | L diviso 2, per difetto | doppio del bonus ordinario già arrotondato |

Esempio: 51 danni base, nemico livello 10, Medio: bonus ordinario 20; tiro doppio → 51+40=91 prima di Difesa, resistenze e Scudi. Non 102.

### Online e offline

- Compatibilità di rete: Windows, browser e dispositivi mobili devono comunicare tra Wi‑Fi, rete mobile, Ethernet, VPN e reti che non consentono WebSocket, usando l'autenticazione e le autorizzazioni della stanza. Realtime resta il trasporto immediato; quando il WebSocket non si apre, invio e ricezione passano al registro persistente HTTPS già protetto da RLS. La consegna della scheda si considera completata solo con la conferma `sheet_received_ack` del destinatario; un semplice invio accettato dal server non equivale alla ricezione. Offline continua a funzionare localmente. Le reti senza accesso a Internet o che bloccano anche HTTPS non possono sincronizzare finché la connessione non torna.
- Conferma del 18 ottobre 2026: il danno al partecipante selezionato, dopo il confronto dei tiri, passa per Difesa, Scudo Oculum, Scudo normale, HP temporanei e infine Vita. Il quasi riuscito mantiene la Difesa ×1,5 arrotondata per eccesso; un attacco evitato non consuma protezioni. Restano le eccezioni esplicite già definite per abilità, Resistenza, Scudo di Salvataggio e Pawn. Un duplicato della stessa risoluzione non applica di nuovo il danno.

- Online, in una turnistica, scegli il bersaglio e il tiro d'attacco. VC è il tiro ordinario; Schianto, Forza, Riflessi o altri tiri alternativi richiedono una descrizione e una motivazione al Master.
- Il log del bersaglio richiede una difesa con CM, Riflessi, Resistenza o Manifestazione del Potere, secondo la mossa. Non pubblicare statistiche nascoste per calcolare probabilità.
- La sessione online dichiara tutte le proprie schede, non le copie ricevute. Perciò, passando da una propria scheda all'altra, una richiesta di attacco resta valida anche prima del completamento dell'aggiornamento Presence. Se il bersaglio è già nella turnistica selezionata, può ricevere la richiesta anche quando il token dell'attaccante arriva un istante dopo nel suo snapshot.
- Master e Co-Master hanno lo stesso registro in sola lettura delle schede dei partecipanti nella turnistica. Dal partecipante possono aprire «Apri scheda»; la condivisione non trasferisce proprietà, né abilita un player a modificare la scheda di un altro player.
- Offline le abilità devono continuare a funzionare. Scelta del bersaglio, tiro difensivo ed esito possono essere manuali, senza autorizzazione del Master online.
- Gli effetti su un nemico non devono diminuire per errore le statistiche di chi li attiva.
- Conferma del 19 ottobre 2026: una skill ad area divide il danno totale fra i colpi/bersagli scelti; ogni quota è arrotondata per eccesso. Ogni bersaglio effettua la propria difesa e applica le proprie resistenze. Se una forma richiede più colpi di quanti bersagli distinti sono scelti, i colpi mancanti si assegnano casualmente fra i bersagli selezionati; uno stesso bersaglio può ricevere più colpi. Costo e cooldown si applicano una sola volta all'azione.
- Conferma del 19 ottobre 2026: la generazione casuale assegna a ogni mostro non-NPC e non Pawn una tecnica multi-bersaglio equilibrata oltre a una variante individuale. Le tecniche generate sono persistite nella scheda e restano modificabili dall'editor.

## Conferme precedenti da conservare

- Vita massima: Resilienza × (10 + 5 × Grado). Le statistiche di base del mostro non devono essere conteggiate come punti guadagnati salendo di livello. Un Mostro guadagna 9 punti per livello aggiuntivi alla base.
- Costi: `5/5` è un esempio di costo fisso, non il costo universale. Un intervallo `1/5` ha senso quando l'investimento aumenta realmente danno, difesa, durata, statistiche o altro effetto dichiarato. Le passive non devono richiedere una spesa attiva fittizia.
- Le tecniche hanno un'identità concreta; evitare descrizioni generiche come «attacco tematico». Conservare identità, statistiche, drop e personalizzazioni dei mostri.
- Le pergamene possono essere apprese: devono avere costi e cooldown utilizzabili anche come skill apprese. Non clonare ogni tecnica in ogni elemento.
- Nei Libri Runici, le parole conosciute permettono di inventare skill. Le parole composte generano una Rune Art usabile; le skill si scrivono con il Master, concordando costi, DT, durata, bersagli ed effetti.
- Pawn protegge la Vita dopo gli Scudi del protetto. Si deve contare anche la Difesa del Pawn e scrivere chiaramente nel log chi prende danno e quanta Vita perde. Lo Scudo di Salvataggio blocca l'overflow del colpo che esaurisce l'ultimo Scudo, poi si disattiva.
- Luna e Sole sono nemici. La grafica dei temi è decorativa e coerente con l'elemento; non deve cambiare la disposizione dei tasti o coprire testi e zone cliccabili.

## Larva Bianca — conferma del 18 ottobre 2026

- La modalità fuga di **Scavata** usa il sottotratto **Velo** (`velo`). Questa indicazione riguarda la fuga; non cambia il tiro della modalità di attacco sotterraneo.
- Fonte: correzione esplicita dell'utente «il tiro per la fuga della larva deve essere su velo».

## Nidiata — barra e scroll, conferma del 20 ottobre 2026

- Infestazione mostra una barra Vita rossa pari al numero di mini larve generate. Ogni larva ha 1 Vita e viene sacrificata per assorbire un danno dopo Scudi e HP temporanei; il danno rimasto prosegue verso il personaggio.
- La stessa barra e lo stesso assorbimento si applicano a chi apprende Infestazione con una scroll: è un esito raro secondo le probabilità già previste per apprendere una tecnica da scroll. Usare una scroll esegue la tecnica e la consuma; l'apprendimento non è automatico.
- I nove ranghi della scroll Nidiata hanno questi dadi e modificatori, aggiungendo il Livello dell'utilizzatore: I `1d50+20+livello`; II `1d100+30+livello`; III `1d120+50+livello`; IV `1d200+60+livello`; V `1d200+100+livello`; VI `1d250+120+livello`; VII `1d250+150+livello`; VIII `1d250+200+livello`; IX `2d250+200+livello`.
- Una nuova nidiata sostituisce quella precedente. Le larve e la Vita residua sono salvate nella scheda e incluse negli aggiornamenti online della Vita.

## Pergamene — aggiornamento del 18 ottobre 2026

- Usare una pergamena esegue la tecnica e consuma un esemplare; non assegna automaticamente una skill permanente. Il consumo avviene anche se il tiro fallisce.
- Apprendimento separato: resta necessario 20 naturale e totale almeno `30 + 10 × grado`. Solo allora si effettua un controllo percentuale: Facile 20%, Medio 15%, Difficile 10%, Oculum 5%.
- La scelta delle percentuali è delegata dall'utente. Il 20% precedente viene mantenuto in Facile e ridotto progressivamente nelle difficoltà maggiori. Un doppione non genera una seconda skill. La skill appresa mantiene costi e cooldown e non è evolvibile.
- Colori delle abilità nella barra combattimento: Oculum usa il colore Oculum personalizzato; Resilienza verde, Volontà rosso, Materia blu. Il colore dipende dalla risorsa, non dalla categoria Attacco/Difesa/Supporto.

## Dettagli da chiedere prima di introdurre nuove regole

### IA dei mostri — conferma del 18 ottobre 2026

- Il mostro agisce con l'IA quando il Master passa il suo turno senza avere compiuto azioni per quel mostro. Un'azione già effettuata manualmente impedisce un secondo intervento automatico a fine turno.
- Correzione più recente: **nessun debito sul prossimo turno**. Ogni creatura ha una Reazione, salvo Skill che ne concedano altre. Le Reazioni si ripristinano a ogni nuovo turno proprio senza accumularsi. L'IA può usare una Reazione ancora disponibile prima del ripristino, invece di sprecarla; non ne crea altre e non ne sottrae al turno seguente.
- Questa è una regola confermata; la sua presenza nel registro non certifica che il nuovo gestore IA sia già implementato.

- Eccezioni specifiche di una tecnica alla scelta del tiro difensivo.
- Effetti senza durata, multibersaglio e condizionali non descritti dal manuale: non assegnare valori o condizioni arbitrarie.
- Confronti di raddoppio con totali nulli/negativi: non introdurre premi infiniti o catene automatiche; chiedere la regola se il caso deve essere regolato diversamente.

## Come aggiornare il riferimento

Registra la nuova conferma con data, esempio e fonte. Aggiorna il manuale interno; riesporta il manuale consultabile; aggiungi test sui limiti della regola. Non cancellare una decisione precedente senza indicare quale nuova decisione la sostituisce.

## Conferma del 19 ottobre 2026: Maestria iniziale

Le soglie dipendono esclusivamente dai punti ottenuti tramite Maestria, non dai punti base, manuali o dai buff. Sottotratti: 100, 200, 350, 500, 700, 850; dopo sei punti guadagnati la soglia resta 1000. VC, CM e Aiuta compagno: 250, 500, 750; dal quarto punto 1000. Iniziativa: 200, 400, 600, 800; dal quinto punto 1000. L'avanzo si conserva. Le difficoltà mantengono i diversi guadagni EXP per tiro; non modificano queste soglie. I salvataggi precedenti non contengono il conteggio separato: si preservano valori e progresso, iniziando il nuovo contatore da zero senza attribuire aumenti retroattivi al caricamento.


## Richieste e correzioni del 19 ottobre 2026 — turnistica e titoli

Questo registro conserva le richieste; non certifica la loro implementazione. Le regole successive dell'utente devono essere aggiunte qui prima di applicarle. I punti ambigui restano da chiarire.

### Combattimento, aiuto e bersagli

- Per un attacco alternativo a VC basta descrivere e motivare l'attacco **a voce** al Master. Scrivere è facoltativo e non deve bloccare il tiro né la consegna online.
- Aiuta compagno permette di scegliere il destinatario; il totale, anche negativo, diventa rispettivamente un + o un − nel suo tiro. Cura e supporto devono scegliere i bersagli della turnistica, includendo «Se stessi» quando appropriato.
- Ogni attacco deve avere una fascia di bersagli/colpi modificabile. È possibile selezionare più volte lo stesso nemico. Se si selezionano meno destinatari del numero richiesto, i colpi rimasti si distribuiscono casualmente fra quelli selezionati, anche se il destinatario è uno solo. Costo e cooldown non vengono pagati per ogni colpo.
- Negli attacchi a più bersagli si divide soltanto il danno base; ogni bonus piatto esplicito, per esempio «Danni +8», si applica per intero a ciascun bersaglio. Ogni quota base si arrotonda per eccesso, poi si aggiunge il bonus individuale.
- Anche cure, effetti, difese e supporti possono avere più destinatari. Il riconoscimento deve funzionare sia per effetti strutturati sia per parser del testo.
- Si possono concedere reazioni ad altri. La propria scheda è verde, gli alleati azzurri, i nemici rossi.
- Online le azioni riguardano solo il proprio fight; deve esistere una funzione esplicita per unire più fight. Offline resta possibile la gestione manuale intuitiva.
- Attacchi senza skill usano i Danni inflitti della scheda. La risoluzione deve rispettare Difesa, resistenze per tipo, Schivata Oculum, Scudi, HP temporanei e Vita, anche online. Migliorare il collegamento del vampirismo con danni realmente inflitti e turnistica.
- Nascondere inizialmente le probabilità. Percezione o Investigazione sono azioni lanciabili anche senza bersaglio; scegliendo un partecipante, il totale deve raggiungere **Livello + Velo** usando Oculum per rivelare livello esatto e probabilità. Se manca di al massimo 5, mostra una stima con livello più basso ma stesso Grado; se manca di più, mostra solo «Non senti abbastanza». Mostrare nei Tiri e azioni il migliore dei due tiri. Un critico scopre il punto cieco per sé e alleati: richiesta di attacchi «semi letali», il cui effetto preciso e durata sono **da chiarire**.
- Precisazione successiva confermata: **pari basta**. In caso di lettura approssimata il livello percepito si riduce dello scarto del tiro, minimo 0, conservando il Grado. Esempio: livello 12, Velo 5, tiro 14 → scarto 3, livello percepito 9; tiro 17 → esatto. L'azione Percezione deve offrire sia la scelta di una persona sia il lancio libero senza bersaglio.
- Le skill dei titoli comprendono Open, skill della Open e skill conferite dal titolo stesso. Molte skill iniziali dei mostri vanno rese disponibili dal livello 0, preservando le eccezioni intenzionali.

### Slot e categorie di titoli

- Apprendimento: **1 slot fin dall'inizio + 1 per Grado**. Con Rebirth i primi tre titoli Evoluti non occupano slot. Provengono da addestramento, Maestria o critici.
- Standard: sei iniziali, sette al Grado III, otto al VI, nove al IX (conferma successiva dell'utente).
- Fato: uno alla prima forma della prima skill, uno alla seconda forma della seconda skill, uno alla terza forma della terza skill. Ogni Chained Fate completato concede uno slot dedicato Fato.
- Malanno: uno slot ogni 6 Resilienza. Titoli obbligati non rimovibili volontariamente, non masterabili; a slot pieni possono sospendere un Evoluto. Possibile evoluzione narrativa in Oscuri/Maledetti.
- Benessere: titoli momentanei senza slot, fino al termine della sessione o dello stato positivo; decadono subito con malus gravi, crisi o trauma.
- Alchimia/Magia: slot separati; Rebirth dà uno slot iniziale utilizzabile anche al Grado 0, senza Rebirth uno per aumento di Grado. Massimo equipaggiato pari al Grado, salvo questa eccezione iniziale confermata.
- Chaos: scrivere sempre Chaos. Titoli già Evoluti, bonus forti e punti ciechi forti; uno slot dedicato ogni −10 Karma.
- Attributo: bonus ordinario +1..+3, Evoluto fino +6, Reforgiato +7, entrambi +9, +1 per Grado e crescita statistiche; massimo +12. Tre parole attive dello stesso titolo aumentano il + del 25% (arrotondamento generale per difetto). Un attributo attivabile per livello, massimo 13.
- Attributo del Fato: raddoppia i + ai tiri, massimo +16. Ogni ciclo di 369 giorni offre ai più fortunati fino a 12 slot; con Rebirth la possibilità ricorre ad ogni nuova fase. Non assegnarli automaticamente senza l'evento concordato.
- Leggende: titolo normale una parola di Fato; Evoluto o Reforgiato due parole e una debolezza; entrambi tre parole e due debolezze. Le debolezze danno − pari al +. Se condizioni positive e negative coesistono possono annullarsi o lottare secondo il contesto del Master.
- Lotta delle parole: 9 o 19 dà +; 20 dà + con ulteriore +3 e vittoria automatica alla prossima lotta; 8 o 2 dà −; 1 dà − con ulteriore −3 e prossima sconfitta automatica. Ogni critico comporta tre + o −. Non inventare esiti per le altre facce.
- Le parole possono attivare bonus statistici temporanei per tutto il fight una sola volta, mantenendo riutilizzabile il bonus al tiro. Possono anche rappresentare paura o conseguenze narrative; non tutte le parole evidenziate sono bonus meccanici.
- I titoli Attributo equipaggiati danno Karma pari al proprio +, modificabile dall'interlocutore e dai tratti.
- Chained Fate: dungeon del Fato avviato dal Master, partecipanti espliciti; primi tre completamenti con EXP ×2 e slot Fato, poi EXP ×3 e nessun ulteriore slot premio (conferma successiva). Registrare inizio/fine/completamento per evitare premi duplicati.

### Presentazione e riferimenti grafici

- Pannello cliccabile Titoli indossati, capacità per livello/Grado, Chained Fate completati, informazioni progressive e leggibili.
- Decorazioni minime coerenti per tema, eventualmente occhi animati che seguono il mouse; nessuna sovrapposizione ai testi o perdita di cliccabilità.
- Immagini ricevute il 19 ottobre: home con città gotica e occhio viola; scena arancione con insetti azzurri; vero Sole come enorme occhio luminoso sopra isole volanti. Sono riferimenti artistici e devono restare distinti dalla Luna, nemica del Sole.


### Conferme successive del 19 ottobre

- Confermato: slot standard 6 iniziali, 7 al Grado III, 8 al VI, 9 al IX.
- Confermato: il critico di Percezione/Investigazione scopre il punto debole; sé e alleati applicano Fragilità Semi Letale a quel nemico fino a fine fight.
- Confermato: i primi tre Chained Fate completati concedono slot Fato ed EXP ×2. Dai successivi non si ottengono ulteriori slot premio e l'EXP nei Chained Fate passa a ×3.
- Reputazioni: cartelle e sottocartelle liberamente creabili, senza un limite fisso, per città e luoghi scoperti. Organizzazione salvata nella scheda, senza perdere valori o reputazioni precedenti. È possibile spostare le reputazioni tra cartelle.

### Conferme di combattimento del 20 ottobre 2026

- Percezione, Investigazione, Furbizia e Valutazione possono essere usate per osservare. La scheda propone il valore più alto fra i quattro; il tiro può anche essere lanciato liberamente senza bersaglio.
- Precisione da +6: il colpo ha 80% di avanzare la Fragilità di uno stadio, 15% di due stadi, 5% di tre, senza superare Fragilità Letale. Ogni punto oltre +6 trasferisce un punto percentuale dalla fascia +1 a quella +2 fino a 50/45/5; poi dalla fascia +2 alla fascia +3 fino a 50/40/10. La modifica vale soltanto per il colpo e non cambia la resistenza salvata sulla scheda.
- Da Precisione +20 si ritaglia un ulteriore 5% dalla fascia +1 per un esito speciale che fa ricevere al bersaglio il 260–350% del danno normale, scelto casualmente. Questo esito resta separato dalla progressione delle fasce; la fascia +1 si riduce di conseguenza.
- Schianto: un bersaglio di Grado 0–II colpito salta la propria azione, ma conserva la Reazione e la tira con Schianto +10 contro l'attaccante. Sopra il Grado II questa mossa non nega l'azione.
- Riflessi: con +6 un critico concede una Reazione aggiuntiva contro l'attaccante solo se il movimento dell'attaccante è pari o inferiore al proprio; da +12 il risultato naturale 19 o 20 la concede, da +20 bastano 18, 19 o 20, senza vincolo di movimento. L'effetto aggiunge una sola Reazione per il trigger e non accumula Reazioni oltre i limiti concessi da Skill.
- Concentrazione (statistica almeno 10): un tiro Utility in combattimento con dado naturale maggiore di 10 prepara il prossimo attacco (+10% Danni) oppure la prossima difesa (+12%), consumando il bonus al primo dei due usato.
- Adattamento (statistica almeno 10): un tiro Utility in combattimento con dado naturale maggiore di 10 prepara una riduzione al prossimo danno ricevuto pari a 1 + (dado naturale − 10). La riduzione si consuma sul primo danno e non si accumula oltre il valore maggiore già pronto.
- Schianto contro un bersaglio di Grado 0–II: il colpo riuscito gli fa saltare l'azione, ma conserva la Reazione e la tira con Schianto +10 contro l'attaccante. Sopra il Grado II l'effetto non nega l'azione. La sincronizzazione del salto azione tra dispositivi richiede autorità della turnistica del Master.
- Queste sono regole confermate, non una certificazione che ogni risoluzione offline/online sia già implementata. Conservare costi, durate, bersagli e valori modificabili dagli editor.

### Elementi in combattimento — conferma del 20 ottobre 2026

- Attacco e Difesa mostrano un selettore dell'elemento scelto, sempre visibile prima del tiro e scorribile. L'attaccante sceglie l'elemento del danno; il difensore sceglie l'affinità con cui protegge questa risposta. La scelta difensiva non riscrive resistenze o personalizzazioni salvate.
- Un'affinità che prevale sull'elemento in arrivo riduce del 25% il danno di quell'attacco: Acqua protegge dal Fuoco; Oscuro protegge da Luce/Sacro; Solare protegge da Lunare. Il vantaggio elementale si applica al danno, incluso il bonus del critico, prima delle protezioni e della Vita. L'elemento originale resta quello usato per resistenze e Fragilità.
- Angelico e Diabolico si indeboliscono reciprocamente: ciascuno riduce del 25% i danni dell'altro. Questa protezione vale finché la Vita del difensore è almeno il 30% del massimo; sotto tale soglia svanisce.
- Per gli elementi base, la prima implementazione aggiunge Acqua > Fuoco/Lava, Fuoco > Gelo, Gelo > Vento, Vento > Terra/Radice e Terra > Fulmine > Acqua. Le coppie non elencate, gli elementi personalizzati e i danni Fisico/Taglio/Perforante/Contundente non ricevono vantaggi automatici. La tabella è intenzionalmente circoscritta e può essere ampliata senza cambiare il formato dei salvataggi.
- Regola esplicita: «il Buio batte la Luce per la credenza per la Luna» e «Sole batte Luna»; Angelico e Diabolico sono pari nel senso che si riducono reciprocamente gli attacchi. Conferma utente del 20 ottobre 2026.


### Presentazione confermata durante l'implementazione

- Le immagini consegnate dall'utente sono già artwork IA: possono essere riutilizzate direttamente nella home come riferimenti e scene di Oculum.
- Mantenere ogni superficie coerente con il tema attivo e valorizzare l'occhio, con animazioni leggere e reattive. Non sacrificare fluidità, funzioni o salvataggi. Riduzione animazioni e cliccabilità vanno preservate.
- Test e verifiche finali devono partire dopo aver completato le modifiche, come richiesto dall'utente.

- Conferma successiva: con Rebirth lo slot Alchimia/Magia è utilizzabile anche al Grado 0 (eccezione iniziale al massimo pari al Grado).


### Riserva statistica dei livelli — conferma del 19 ottobre

Ai livelli 5, 15, 25, 50, 100 e 200 si ottengono rispettivamente 2, 4, 7, 13, 25 e 50 punti: un quarto della soglia, arrotondato per eccesso. Confermato dall'utente: riserva da distribuire liberamente, una sola volta per soglia, non un bonus a ogni statistica. I premi già ottenuti restano marcati anche se si abbassa e rialza il livello; nessuna seconda assegnazione caricando il salvataggio.

## 19 ottobre 2026 — Atelier, colori e supporto
- Tema personale con più immagini, ordine dei layer, posizione normalizzata, dimensione, rotazione e opacità. Codice `OCULUM1:` con immagini incluse, importabile senza percorsi locali. Decorazioni in IgnorePointer ed escluse dalla semantica: non intercettano comandi.
- Colori di Resilienza, Volontà, Materia e Oculum personalizzabili nell'Atelier tramite selettore HSV, RGB e HEX. Mantiene i colori precedenti finché non vengono impostati override; ripristino disponibile. Colori opachi per i testi delle statistiche.
- Ritratto della scheda leggermente rettangolare (116×104 desktop, 80×72 compatto), con asset dell'occhio originale già utilizzato nel profilo.
- Contenitore della scheda: «Aiuto e utilità». Comprende il tiro Aiuta compagno, Art/Skill/Titoli di supporto e cura manuale già concordata col Master; nessuna nuova formula di cura introdotta.
- Cure e aiuti usano i destinatari della turnistica corrente online, con conferma di ricezione e protezione dai duplicati; offline applicazione alle schede locali. Il Party apre lo stesso pannello condiviso. I membri annotati solo come testo non diventano automaticamente schede online.

### Riferimento artwork — 19 ottobre
L'utente indica le illustrazioni promozionali anime di S4 League, più curate della grafica del gioco, come riferimento di qualità per nuove immagini originali di Oculum; atmosfera più gotica. Non richiede un sistema di annunci nell'app. Prima immagine generata in Figma: spadaccino e cattedrali sospese, esportata in assets/oculum/home_art/anime_reliquary.png. File Figma: ZooYFl2ORaXAPZks3Jb8B1, nodo 2:2.

## Regole confermate e interventi successivi — 19 ottobre
- EXP a fine scontro: per ogni nemico ucciso, Livello del nemico + somma delle sue statistiche; premio intero a ogni partecipante. Implementati pulsante Termina scontro, reset turnistica e chiusura delle unioni; assegnazione con ricevute contro duplicati. Verifica online reale ancora da completare.
- Cibi di mostri: probabilità di apprendere una loro skill pari a 0,5% + Fortuna in punti percentuali. Esempio confermato: Fortuna 5 → 5,5%. Implementata sui cibi di mostri predisposti dal catalogo, separatamente dal consumo.
- DT della condizione: difficoltà del tiro per liberarsene; durata e DT gestibili dal Master con menu contestuale (destro/pressione prolungata).
- Anima staccata: Svantaggio Oculum per una azione. Il selettore esistente definisce Svantaggio Oculum −12; applicarlo ai tiri Oculum, non alle statistiche permanenti.
- Nuovi buff minori: utente autorizza percentuali e durate contenute e modificabili. Proposta implementata: cinque famiglie (quattro statistiche singole e tutte), stadi I–VI +2/4/6/8/10/12%, 3 turni. Bonus della stessa famiglia non cumulativi; arrotondamento per difetto. 30 cibi/infusi di prezzo crescente collegati ai rispettivi stadi.
- Negozi: materiali con Vitalium sempre disponibile; fabbro armi e Pawn; alchimista cristalli e crafting; chef cibi e bibite.
- Solo alchimista: 1 Ascension Dust per acquisto, prezzo 33–69 Obser, fino a 3. Il periodo Riposo Lungo è mantenuto dal comportamento precedente e va chiarito se richiesto diversamente; nessun raddoppio di potenza assunto dopo la precisazione «1 Ascension Dust».
- Schermata iniziale: solo occhi che seguono il puntatore, alcuni mobili; artwork spostati nella Home.
- Canva: collegamento verificato nuovamente con fetch riuscito del design DAHX-kQUyBo. Nuova generazione avviata; non dichiarare esportata finché il risultato non è scaricato e integrato.

### Stato della rifinitura successiva
- Ambito ribadito dall'utente: Oculum normale (schede, mostri, abilità, negozi e turnistica), non Cammino dell'Eroe. Non trasferire le nuove regole al suo sistema di gioco.
- Integrato il PNG originale consegnato dall'utente «Correzione della mano sulla spada.png» nella galleria Home, senza ulteriori modifiche alle mani.
- Requisiti equipaggiamento: il messaggio mostra il maggiore fra Grado oggetto e Grado richiesto; l'attivazione rapida verifica anche il livello della forma.
- Le Open principali e aggiuntive dei titoli sono accessibili nei gruppi combattimento tramite il comando originale; nessuna seconda applicazione separata degli effetti Open.
- Il log dei nutrimenti indica i turni effettivi, distinguendoli dalle erbe a riposi.
- Il moltiplicatore EXP Chained Fate è limitato ai partecipanti del dungeon.
- Analisi statica `dart analyze lib`: nessun problema. Questo risultato non certifica prove online reali, pacchetti o pubblicazione. Pubblicazione e sostituzione sospese su richiesta dell'utente fino alla rifinitura completa.

## Turnistica online del Master — 19 ottobre 2026
- Online, i turni vengono avanzati dal Master; i player seguono lo scontro pubblicato che contiene la propria scheda. Cambiare PG seleziona lo scontro del nuovo PG, senza unire fight differenti.
- Entra nello scontro condivide la scheda e richiede l'inserimento al Master. La turnistica cambia dopo la conferma nel suo aggiornamento; l'arrivo della scheda in ritardo non perde la richiesta.
- Le schede dei partecipanti aggiornano vita e risorse nella turnistica del Master, preservando ordine, iniziativa e reazioni gestite dal tracker.
- Il progresso personale ricevuto dal Master attiva condizioni, cooldown e avanzamento Art una sola volta. Offline i contatori rimangono manuali.
- In fight, danni, cure, modificatori di Aiuta compagno e condizioni si applicano al destinatario secondo l'esito. Un totale negativo di Aiuta compagno sottrae dal prossimo tiro. Nessun reinvio deve ripetere la mutazione.
- Il log del difensore indica attaccante, mossa, danni dichiarati e DT difensiva uguale al totale del tiro nemico. Restano valide le soglie e le eccezioni del confronto attacco/difesa confermate sopra.
- Cure e condizioni sulle proprie schede non aperte vengono applicate senza cambiare la scheda visualizzata; anche il loro progresso segue i turni del Master.
- Preferenza utente: l'immagine Home si sceglie dalle anteprime sotto la scena principale, con selezione persistente e ripristino dell'originale.
- Nome del pannello: «Supporto e utilità». Ogni abilità che dona/applica buff o debuff compare anche qui, pur restando nelle eventuali altre categorie. Per i potenziamenti misti VC/CM o Danni/Difesa, pari valore comporta presenza sia in Attacco sia in Difesa; altrimenti prevale il valore maggiore.
- Erbe fumabili, solo alchimista: 30–50 Obser. +6 Volontà e +4 Materia fino al primo limite tra 3 turni di combattimento, 2 riposi brevi e 1 lungo. Alla fine Confuso: −20% danni e DT +2 per 2 turni oppure fino alla prossima cura o riposo. Il +2% iniziale è sostituito dalla correzione esplicita DT +2.
- Le scroll presenti in inventario devono comparire nei pannelli Attacco/Difesa/Supporto e utilità secondo gli effetti, collegandosi ai bersagli della fight. L'uso consuma la scroll e mantiene i requisiti e le probabilità di apprendimento già confermati.
- Segno del Fato, solo alchimista: il negozio fissa un prezzo da 50 a 120 Obser; una sola copia per negozio. A 50 le probabilità sono 70% Ispirazione normale, 20% Super, 10% Oculum. A 120 sono 30%/40%/30%, con interpolazione graduale confermata. Consumare un segno assegna immediatamente una delle tre ispirazioni secondo le regole già esistenti, senza duplicare il consumo.

- Correzione utente: Segno del Fato ha prezzo fissato dal negozio, 50–120 Obser, una sola copia nello stesso shop. Segno del Chaos: solo alchimista, presenza 3% per negozio, prezzo 60–120 Obser. Consumandolo, ogni 10 Obser del suo prezzo (per difetto) genera un’estrazione indipendente su Resilienza/Volontà/Materia/Oculum casuale: 75% +1 punto, 13% +2, 9% +3, 3% +0. Punti permanenti; disponibilità e prezzo persistenti.
- Occhi dei Caduti acquistabili dall'alchimista: probabilità iniziali configurate al 20% per l'offerta medio rara e 5% per quella rara, una sola generazione casuale per mercante e stock salvato. La creatura è scelta casualmente dal Monster Book, senza NPC; le sue statistiche base non superano il totale delle statistiche del compratore e sono selezionate il più vicino possibile alla metà di quel totale. Il medio raro ha livello pari al livello del compratore meno un terzo arrotondato per eccesso, minimo 0, e prezzo casuale 56–89 + livello + 3 × Grado Obser. Il raro ha livello pari a metà del livello del compratore arrotondato per eccesso; le quattro statistiche della scheda risultano dalla somma delle statistiche del compratore e delle statistiche base del mostro. Prezzo casuale 230–450 + metà del livello del compratore arrotondata per difetto + 4 × Grado Obser. Acquistare crea l'Occhio tramite il flusso esistente e consuma l'offerta una sola volta; prezzo e scheda sorgente sono persistenti.

## Recupero automatico online — 19 ottobre 2026
Richiesta utente: tutte le proprie schede online devono poter arrivare al Master e partecipare alla sua turnistica. Correzione più recente: la connessione, l’arrivo del Master e la richiesta di recupero sincronizzano automaticamente solo la scheda attualmente usata; le copie ricevute non vengono rispedite come proprie. L’ingresso richiesto resta in attesa e viene ritentato finché lo snapshot del Master non contiene il partecipante. La presenza in ritardo non elimina una richiesta: il Master la ricontrolla dopo la presenza o la scheda. Restano verificati proprietario/sessione, campagna e fight pubblicata. Il recupero di una singola scheda usa il suo tag.

- Precisazione utente: invio automatico al Master soltanto della scheda attualmente usata, senza inviare in blocco le altre. Restano conferma di ricezione e ritentativi per la scheda scelta.

## Uso dei sottotratti — 20 ottobre 2026
- Correzione esplicita dell'utente: i sottotratti in sé sono sempre utilizzabili; le soglie di Maestria non sono un requisito per poterli tirare. La Maestria continua a governare i propri avanzamenti e benefici. Nei pannelli di combattimento sono selezionabili i sottotratti pertinenti all'azione, anche se il vecchio campo `unlocked` del salvataggio è falso. Strategia è disponibile anche come scelta difensiva.
- In attacco, Manifestazione del Potere con totale almeno +6 aggiunge +3 danni per livello a ciascun bersaglio colpito; negli attacchi multipli il bonus piatto si applica a ogni bersaglio.

## Conferma del 21 ottobre 2026 — EXP a fine scontro
- Ogni nemico ucciso contribuisce al premio totale di fine fight con il proprio livello più la somma delle proprie statistiche. In scontri con molti nemici vanno conteggiati tutti gli uccisi, mantenendo la distinzione già presente Mostro/Mini Boss/Boss.
- Il Grado del nemico deve essere indicato da 0 a XII. L'utente conferma di riusare la formula già nella sezione EXP: ×1,2 per ogni Grado sopra quello del personaggio; stesso Grado o inferiore ×1. Il confronto è individuale per ogni partecipante e ogni nemico. Si conservano i moltiplicatori esistenti Mostro/Mini Boss/Boss per difficoltà e il bonus EXP di Grado già previsto dall'app. L'EXP ricevuta fa salire di livello tramite le soglie e l'opzione automatica esistenti, senza assegnare livelli aggiuntivi arbitrari.

## Ascension Dust e bottino — 21 ottobre 2026
- A fine scontro si tira il Drop di ogni mostro ucciso presente nella turnistica e lo si distribuisce al party partecipante; zero Vita o KO senza morte confermata non bastano. Obser per nemico = livello + Grado ×3, interi per ogni partecipante effettivo al fight.
- Un 20 naturale sul tiro Drop di un mostro della turnistica genera al massimo un Occhio per uccisione, senza dipendere dal totale con bonus. L'Occhio conserva corpo e tecniche della creatura sorgente; se la scheda sorgente manca, usa il preset corrispondente del Monster Book. Viene assegnato una volta a un partecipante effettivo e non crea duplicati.
- Se le statistiche totali di un nemico superano quelle del ricevente: 1 Dust, più 1 per ogni Grado sopra quello del ricevente; massimo 3 Dust complessive per fight e personaggio. I pari totali non bastano.
- Nuovo uso Dust: un unico 1d90+20+60×proprio Grado dona EXP a ciascuna delle quattro statistiche e a un sottotratto fra quelli col valore più alto. L'EXP personale riceve lo stesso valore più metà delle statistiche totali.
- Limite di 3 usi su se stessi per Riposo Lungo. Aggiunge anche un bonus +1/+3 a una statistica: 60% +1, 20% +2, 10% +3; mancano conferma sul 10% restante, permanenza e progressione per difficoltà. Non inventare i valori.
- Durante un fight non terminato consuma Azione, Reazione o Reazione veloce; può sfruttare una Reazione ottenuta contro un nemico. La Dust viene consumata applicandola sul petto.
- L'espansione di potere dona EXP ridotta al party online selezionato; il 20% e il 50% si riferiscono all'uso Dust, non ai premi di uccisione. Precisazione richiesta sulla ripartizione fra EXP statistiche e personale. Gli esterni non ricevono EXP/Obser/Dust del fight.

- Precisazione più recente: le percentuali 20%/50% sono soltanto per l'espansione EXP della Dust; non attribuire premi del fight a chi non vi ha partecipato. Mancano conferme su bonus statistica permanente/scelta, 10% residuo e incremento con difficoltà. Questi punti sono in attesa di risposta, non regole definite.

### Precisazioni Dust più recenti (prevalgono sul testo sopra)
- Il 10% residuo del bonus statistica dà zero.
- Il +1/+3 alla statistica non è permanente: dura tre Riposi Lunghi.
- Il sottotratto destinatario dell'EXP è quello usato più spesso, non quello dal valore più alto. Serve registrare i tiri effettivi; per vecchi salvataggi non inventare una cronologia.
- Il bonus si collega a poca Vita attuale o massima rispetto al livello; soglia e applicabilità anche all'EXP ancora da precisare. Richiesta spiegazione sull'aumento di probabilità con difficoltà: si intende maggiore probabilità di +2/+3 contro nemici più forti; nessuna progressione confermata.
- Il party riceve EXP ridotta su tutte le EXP: precisazione richiesta per distinguere quota 20% e quota 50%. Non attribuire risorse o premi fight agli esterni.

### Risposte utente successive — Dust (21 ottobre 2026)
- Il requisito di poca Vita attuale o massima rispetto al livello riguarda soltanto il bonus statistica temporaneo, non l'EXP. Soglie numeriche non ancora indicate.
- Espansione al party: 20% della parte base e 50% della parte aggiuntiva (+), su tutte le EXP donate. Nessun Obser o Dust agli esterni per questa espansione.
- Quantità Dust: un Grado superiore 2/3 Dust; due Gradi superiori o più 3 Dust; classe Mini Boss 4 Dust, Boss 5 Dust. Da chiarire se 4/5 sostituiscono il vecchio tetto di 3 per fight e la scelta 2/3.
- Per ogni 25 statistiche nemiche sopra quelle del ricevente, aumenta leggermente la probabilità di bonus statistica maggiori: ridurre soprattutto il 60% del +1 e molto meno il 10% dello zero. Il confronto considera il o i mostri del fight e si effettua a fine scontro. Incrementi numerici non ancora confermati.

### Dust — conferme definitive successive
- Mini Boss (4 Dust) e Boss (5 Dust) sono eccezioni al tetto ordinario 3 per fight. Un Grado sopra privilegia 2 Dust; lo zero diventa 1 Dust. Mappatura della distribuzione base limitata a 3: 10% 1 Dust, 60% 2, 30% 3. Due Gradi sopra o più: 3 Dust.
- Ogni 25 statistiche totali nemiche sopra le proprie: spostare 2 punti percentuali da +1 e 0,5 dallo zero verso +2 (+1,5) e +3 (+1). Nessuna probabilità negativa; esaurite le fasce donatrici, dividere la massa effettivamente trasferita 60% verso +2 e 40% verso +3.
- Soglia Vita attuale 50% per il solo bonus temporaneo; destinazione alla statistica con maggiore carenza attuale o generale. Oculum a zero escluso.

## Stati, morte e fuga — 21 ottobre 2026
- Il Master può segnare Morto o Fuggito; online gli stati sono quelli della turnistica Master. Fuggito è escluso da turni e bersagli disponibili e non genera premi di uccisione.
- Morte automatica solo dopo l'effettivo esito delle regole di morte; Vita zero da sola significa caduto, non ucciso. Rinascita, fasi e recuperi Vita devono risolversi prima dell'esito; non assegnare drop per un semplice azzeramento della barra.
- Correzione esplicitamente confermata: Ferito a Vita >0 e ≤60% del massimo; Morente a Vita >0 e ≤30%, sostituisce Ferito. Sono etichette informative, non nuovi malus. Disponibili anche online senza rivelare il valore numerico della Vita nascosta.

## Corazza scheletrica del Forest Demon — conferma 21 ottobre
- Conferma esplicita: il +5 Volontà della skill dura 1 turno. L'esempio di livello 3 ha +6 Difesa e +60 Scudo; la skill richiede il livello dell'oggetto. Ricarica 3 turni, pronta a inizio fight. Valori ed effetti restano modificabili e serializzati nel JSON.

## Drop e reliquia dello Slime Blu — conferma 21 ottobre
- Il totale del tiro Drop include il dado e il relativo bonus. Con un totale di 50 la Fata Cacciatrice garantisce entrambe le Mezze ali di fata; sotto 50 non le lascia.
- L'Elmetto-scudo di melma blu ha elemento Slime e Scudo Oculum pari a 10 + livello del mostro affrontato. La reliquia resta un oggetto modificabile e serializzato.

## Reliquie mostruose e carne — conferma 21 ottobre
- Catalogo generato di almeno 500 armi, armature e scudi rari; ogni pezzo riprende una Art o Skill concreta di un mostro, elemento, grado e livello affrontato. I bonus propri dell'equipaggiamento non copiano le statistiche base del mostro.
- Il Drop totale è dado + bonus. Le reliquie ordinarie hanno una soglia alta crescente col Grado; ogni uccisione assegna al massimo una reliquia dal catalogo, mai tutte le varianti. Le abilità restano bloccate fino al livello del mostro/item e poi alle forme successive richieste.
- I drop materiali hanno probabilità individuali; quando non è definita dal mostro la probabilità è 35%. Le creature commestibili possono lasciare carne cruda da cuocere (45%); costrutti, golem e non morti non lasciano carne. È possibile ottenere solo carne o nessun bottino.

## Armi equipaggiate — conferma 21 ottobre 2026
- Massimo 3 + Grado ×5 armi. La principale è quella col bonus Danno maggiore e contribuisce per intero. Ogni secondaria contribuisce per un terzo del proprio bonus: per difetto se livello e Grado sono entrambi inferiori alla principale, per eccesso se almeno uno è pari o superiore. Si arrotonda ciascuna secondaria separatamente, poi si somma. Il bonus potenzia direttamente i danni tramite il calcolo esistente; non richiede sommare manualmente il danno della singola arma. Salvare e preservare le personalizzazioni degli oggetti; nei vecchi salvataggi oltre limite non cancellare armi, ma attivare soltanto le più forti entro il limite.


## Prima sconfitta e varianti — conferme 21 ottobre 2026
- Ogni partecipante effettivo riceve +50% dell’EXP del primo tipo di creatura sconfitto, arrotondato per eccesso; una sola volta per tipo. Ogni nuova variante, incluse veterane o di un altro elemento anche a pari livello/Grado/statistiche, dà +25%, arrotondato per difetto, una sola volta per variante. Una variante inferiore di Grado non dà bonus se è già stata affrontata la versione di Grado più alto. La cronologia è personale e persistente; duplicati e riapertura dello stesso premio non la duplicano. Le varianti generate usano l’identità stabile della voce base del Monster Book; per voci distinte il Master può indicare una famiglia EXP comune nell’identità avanzata della scheda mostro. Le evocazioni restano soggette al proprio premio limitato senza questo bonus.

## Negozi, Refull e Potenziamento — conferma del 22 ottobre 2026
- Il Potenziamento sostituisce l’etichetta Oculum nei tiri fight, mantenendo gli stessi sblocchi e limiti per Livello/Grado: ogni punto speso dà +3 al tiro e +2 Danni per punto se è un attacco.
- Il Fabbro vende il Raccoglitore Grado 0/XII: Livello XII, Grado 0; nell’inventario raddoppia i materiali da raccolta di Grado pari o inferiore. È una passiva senza costo per raccolta.
- Il Mercato Nero vende inizialmente Art Archivio delle Scorie (18.000 Obser), Colpo di Brace (8.000; +20 Fuoco; recupero 3 turni) e Taglio di Gelo (12.000; +30 Ghiaccio; recupero 4 turni). Art, Skill, costi, effetti e recuperi restano editabili e serializzati.
- Infermiera Eroica: HP mancanti 1 Obser ogni 10; Scudo Oculum mancante 2 Obser per punto. Pacchetti iniziali: 1 Obser per +1 Volontà o Materia, 2 per +15 HP temporanei o +10 Scudo normale, 3 per +1 Oculum attuale.
- Refull completo ripristina HP, statistiche attuali, Oculum, Scudo Oculum già sbloccato e integrità Art, rimuove debuff e aggiunge gratuitamente +20 Scudo normale. Il costo base iniziale usa 1 Obser ogni 10 HP mancanti, 2 per punto di Scudo Oculum, 1 per punto statistica, 1 ogni 10 integrità Art e 5 per condizione negativa; applica lo sconto del 15% e aggiunge il prezzo del buff.
- All’apertura del negozio il buff per la prossima battaglia viene estratto fra 10%, 15%, 20%, 25% e 30% a Danni e Difesa, con sovrapprezzo di 1 Obser ogni 5%. Durata: 9 turni Facile, 6 Medio, 3 Difficile, 1 Oculum. Al jackpot iniziale modificabile dell’1%, il buff è +40% o +60% e aggiunge Scudo gratis pari a un quarto degli HP massimi del personaggio, arrotondato per difetto. Un’altra probabilità iniziale modificabile dell’1% regala HP temporanei pari a 5 × Livello.
- Il Refull nella pagina Statistiche ripristina HP, statistiche attuali, Oculum e Scudo Oculum già disponibile; non ricarica lo Scudo normale. Valori iniziali scelti per completare la regola restano modificabili negli editor/offerta JSON, senza sovrascrivere personalizzazioni salvate.
- Il Mercato Nero include anche offerte di livello 0, seleziona due pergamene del Grado corrente e può vendere Art Oculum, Skill e armi del Monster Book e un Occhio dei Caduti al livello del personaggio. Skill/Art possono richiedere il livello corrente o fino a due livelli in più; gli sblocchi restano registrati dopo l'acquisto. Il catalogo evita duplicati semantici anche se cambiano nome variante, danno o prezzo.
- L'Ascension Dust del Mercato Nero costa 30–50 Obser al primo acquisto, poi +10 per dose, massimo 69 alla terza; massimo tre dosi per Riposo Lungo. Per gli Occhi del Mercato Nero: statistiche totali ×5, +25% per ogni dieci livelli, arrotondamento al multiplo di 5 superiore; al livello 10, 18 punti costano 115. La creatura è al livello del personaggio e il totale statistiche è limitato al totale del personaggio +10%, con almeno 2 punti di margine.
- Il dono casuale di HP temporanei del Refull usa le tre fasce iniziali modificabili: 1% di 5 × livello, 2% di metà massimale arrotondata per eccesso, 5% di metà arrotondata per difetto.

## Iniziativa nelle schede Master online — correzione 22 ottobre 2026
- Il riepilogo remoto usa il totale iniziativa salvato quando il tiro o la base non sono presenti o non consentono di mostrare una formula attendibile; non deve visualizzare `0 + 0 = totale`. Le iniziative legacy negative senza dado vengono normalizzate a zero. Il nome usa, in ordine, nome della scheda, titolo visibile, tag scheda/ID e tipo, evitando `???` quando esiste un identificatore utile.
- Il payload pubblico della turnistica include tiro iniziativa, base, totale e Riflessi, così il Master riceve gli stessi dati necessari a mostrare la scheda selezionata.

## Azioni e reazioni nella turnistica — conferma 22 ottobre 2026
- Precisazione esplicita del 23 ottobre 2026: l'Azione si usa soltanto nel proprio turno. Ogni Azione di un partecipante, inclusi i nemici, fa avanzare la turnistica di una posizione; Reazione e Reazione veloce non la fanno avanzare. Anche il comando manuale del Master rispetta il turno del partecipante.
- Nel primo giro ogni partecipante ha 1 Azione di base e 1 Reazione veloce; la Reazione normale di base non è ancora disponibile. L’Azione si rinnova al turno personale.
- Nei giri successivi si rinnova 1 Reazione veloce all’inizio del nuovo giro completo. Quando arriva il turno personale del partecipante, si rinnova 1 Reazione normale di base. La Reazione veloce scade all’inizio del nuovo giro; la normale scade al successivo turno personale.
- Ogni Reazione normale non usata quando scade aggiunge +3 al prossimo tiro; ogni Reazione veloce inutilizzata aggiunge casualmente +6 oppure +9 (mai valori intermedi), accumulando fino a +12 in attesa. Il bonus si consuma al primo tiro successivo. Usare una Reazione non avanza il turno attivo.
- Il primo tiro di difesa è gratuito. Contro lo stesso attacco è consentito al massimo un secondo tentativo, spendendo una Reazione prima dei danni. L’Azione si usa solo nel proprio turno; le Reazioni restano utilizzabili fuori turno.
- La Reazione gratuita ottenuta con doppia difesa può essere spesa per le azioni e utility di combattimento che accettano una risorsa di turno, non soltanto per il contrattacco. Le richieste consumano prima una Reazione gratuita disponibile; altrimenti usano l’Azione nel turno personale o una Reazione normale/veloce fuori turno. Il Master sincronizza i consumi una sola volta.

- Conferma 23 ottobre 2026: i log esplicitano attaccante, tecnica, attacco, difesa e aiuti; esempio Schianto 23 contro Riflessi 19 + aiuto 4 = 23, parità vinta dalla difesa. Aiuta compagno è utilizzabile anche per il tiro di attacco.

### Trasparenza e Invisibilità — conferma 23 ottobre 2026
Trasparenza non nasconde il corpo a chi ha Grado superiore al suo utilizzatore. Chi individua il corpo con una lettura esatta, oppure lo vede automaticamente per Grado, ottiene +1 Difesa per proprio livello contro gli attacchi di quel solo utilizzatore. Il bonus riguarda la Difesa che assorbe i danni, non il tiro difensivo, ed è personale; resta legato alla condizione Trasparenza attiva. Invisibilità permette la vista automatica alle soglie: utilizzatore Grado 0–2 visto da Grado 3+, 3–5 da 6+, 6–8 da 9+, 9–11 da 12+. La vista automatica non richiede un tiro e ignora il bonus Velo della condizione. I bonus personalizzati e le durate restano conservati nel JSON. Il bonus Difesa è specifico di Trasparenza.

### Creatrice di vestiti — 23 ottobre 2026
Banco Sartoria con capi di livello e skill di protezione modificabili. Prezzo base casuale 9–18 Obser: +2 ogni 5 HP temporanei, +5 ogni 3 Scudo Oculum, +2 ogni 3 Scudo. Supplementi proposti e modificabili: +2 Obser per il tratto di crescita, +2 per punto Danni/Difesa. Crescita del livello oggetto: +1 a una statistica ogni 3 livelli oppure +1 a un sottotratto ogni 2. Bonus secondari piccoli; Scudo Oculum raro. Quando lo Scudo del singolo vestito si rompe, i suoi bonus passivi si dimezzano per difetto; con la ricarica tornano interi. Livello, destinazione e intervallo di crescita, buff, Scudo e skill restano modificabili e salvati nel JSON. L'integrità del capo è indipendente dagli altri equipaggiamenti.


### Postea e svantaggio VC/CM — conferme 23 ottobre 2026
Il Mitra runico Postea costa 50 Obser. Compare tra gli Attacchi: soltanto scegliendolo aggiunge +15 Danni. Solo quei 15 ignorano le resistenze; il resto dell’attacco segue le resistenze normali. Non ignora Difesa o Scudi e non dà un bonus passivo permanente. Valore ed esclusione delle resistenze sono modificabili nell’effetto della skill e salvati nel JSON.
Un tiro VC o CM che supera quello avversario di almeno due terzi del totale avversario infligge −3 a tutti i tiri del nemico per un turno. Esempio: 20 contro 12 soddisfa la soglia; 19 contro 12 no. Gli altri tipi di tiro non applicano questo svantaggio.

Stivali Postea: 60 Obser; doppio salto gratuito fuori fight oppure un solo reroll CM +3 dopo la prima CM fallita. Compare nelle Difese, non consuma Azione, Reazione normale o veloce, CD 5 turni. Cooldown e descrizione restano modificabili nell’abilità dell’oggetto.
Cenere: ogni critico positivo ricevuto ha il 30% di dare +1 Cenere. Si esegue solo metà dei precedenti controlli di svenimento, mantenendo le prove e gli esiti preesistenti. A ogni turno personale, se Cenere > Livello +3, probabilità min(100, 20 + Cenere)% di perdere la Reazione normale per quel turno; la veloce resta distinta. I log mostrano tiro, soglia e risultato.

Log fight: indicare sempre attaccante e difensore per nome, tecnica e tiro. Prima della difesa: “deve difendersi”; dopo: totale difesa con aiuto e chi ha vinto. Aiuta compagno resta disponibile per attaccante e difensore.


### Abiti, corazze Postea e parità — 23 ottobre 2026
La parità tra attacco e difesa favorisce sempre la difesa, anche in difficoltà Oculum.
La sartoria vende tagli femminili, maschili e unisex, con descrizioni di tessuti, silhouette, dettagli e uso: gotico/dark fantasy e abiti pratici non gotici. I nuovi modelli non sovrascrivono quelli personalizzati già salvati.
Le armature cyberpunk Postea hanno Scudo pari a metà HP massimi all’acquisto, per eccesso; prezzo 36 + tale Scudo. La misura resta fissata, senza adattarsi ai successivi HP. Alla rottura diventano Armatura logora, con bonus passivi dimezzati per difetto e senza ricarica automatica. Una sola attivazione al 99% assegna un buff di 6 turni: condizione positiva, statistica o uno dei sottotratti più usati.
Valori proposti e modificabili: +2 + Grado a Danni e Difesa; crescita +1 alla statistica ogni 3 livelli oggetto; buff di statistica +1 + Grado/3 per difetto (massimo 4), oppure sottotratto +3 + Grado/3 per difetto (massimo 6), oppure Vigore di radice I. La destinazione piu_usato si risolve alla rottura usando lo storico tiri. Scudo, buff, crescita, probabilità, durata, destinazione e condizione sono editabili e serializzati.
Ogni oggetto ha un peso modificabile. Per oggetti privi di peso positivo: stime iniziali di 1,5 kg per armi, 2 kg per protezioni, 0,1 kg per altri oggetti; i pesi positivi già salvati restano invariati.


### Piani e mercati — 23 ottobre 2026
Selezione del piano salvata per scheda, predefinita Regno mezzano. Piani naturali: Regno sacro (minimo Grado 3, Solare/Angelico, Occhi di aberrazioni); Regno angelico (Angelico); Oblio (Mercante Nero e creature dell’Oblio); Isole volanti (soprattutto Fulmine, poi Nuvola/Acqua/Ghiaccio); Regno mezzano; Regno affogato (ambiente acquatico respirabile, Acqua); Regno sotterraneo (Roccia/Terra/Buio); Regno sotterraneo maggiore (base Grado I/II); Regno demoniaco (Demoniaco/Fuoco/Lava/Fisico); Shadow Hell (minimo Grado IV, contaminazione Oblio e riflesso diabolico, pendagli protettivi); Regno diabolico (minimo Grado III); Il vero inferno (minimo Grado IX). Micro realtà: Postea (futuro errato basato sulle rune, mercato dedicato) e Regno Caramella (cioccolato, candy cane e dolci, poco sopra il mezzano).
Moltiplicatori iniziali proposti del catalogo: Sacro ×3; Angelico ×1,2; Sotterraneo maggiore ×1,3; Demoniaco ×1,2; Shadow Hell ×2,5; Diabolico ×2; Vero inferno ×4; Caramella ×1,1. Sono bilanciamenti iniziali, non numeri confermati dall’utente. Le offerte conservano prezzo, grado, elementi e descrizione; i cambi piano filtrano i negozi senza alterare gli acquisti o gli oggetti personalizzati già salvati.

### Cassa comune e premi specie — conferme 23 ottobre 2026
Cassa nell’Inventario, isolata per campagna del Master. Tutti i partecipanti online possono versare/prelevare Obser e oggetti non usati; il Master sincronizza automaticamente le operazioni senza approvazione manuale. Offline la gestione locale è manuale. Gli Obser non pesano. Capienza: 1 kg per partecipante registrato online nella campagna +0,5 kg per ogni suo livello, includendo chi è temporaneamente offline. Mostri, boss, Occhi dei Caduti, Pawn e creature non contribuiscono. Depositi e prelievi hanno identificatori persistenti per non ripetersi; un deposito in attesa resta riservato fino alla conferma o restituzione.
Premio cumulativo, una sola volta per specie e party anche attraverso più sessioni: 3 mostri ordinari → 10 Obser + somma delle quattro statistiche dei tre; 2 miniboss → 30 + somma statistiche dei due; 1 boss → 50 + sue statistiche. Gli Obser vanno nella cassa comune (ultima correzione dell’utente); il Monster Book Party mostra progresso e accredito, ordinando prima le creature con scoperte. Evocazioni escluse dalle uccisioni premio.
Conversione di un singolo oggetto in Titolo Item: Ascension Dust pari a metà livello oggetto per eccesso +1; preserva effetti, peso e personalizzazioni, abilita forme evolutive modificabili. Nessun incremento automatico non concordato degli effetti.

Conferma: Diabolico e Demoniaco sono elementi distinti. Difesa Diabolica riduce del 75% i danni Demoniaci (moltiplicatore 0,25), senza requisito di Vita. Nessuna riduzione reciproca automatica.

Micro realtà aggiunte: Foresta elementale (tutti gli elementi del catalogo), Regno dei Morti (necromanzia ed evocazioni), Terre di ghiaccio (Ghiaccio, resistenze e vestiti pesanti), Nuvole rocciose (Roccia, Fulmine, Nuvola, Vento). Nelle Terre di ghiaccio, senza un capo pesante equipaggiato: −2 Iniziativa, −1 Movimento, −1 Materia, minimi zero. I capi pesanti si riconoscono dal flag heavyClothing o dalla descrizione pesante/termica/pelliccia.
Amuleto Teschio: prezzo confermato 120 +10×Grado Obser; richiede un’Azione nel turno personale, recupero al Riposo Lungo. Forma casuale di non morto del livello del personaggio, con Vita/Oculum/abilità separate. Durata max(1, livello/10 per difetto) attacchi subiti; schivate escluse, eccesso di danno annullato tornando alla forma originale. Evocazioni necromantiche: alleati con iniziativa propria, statistiche e capacità del non morto al livello del compratore, durata 3 turni del proprietario. Prezzo proposto sigillo 90 +10×Grado, recupero proposto 6 turni; valori modificabili.

Pressione del piano: prova Adattamento solo se almeno due Gradi sotto il minimo dell’area. DT 18 + Grado minimo da superare strettamente. Critico negativo: −20 a tutte le statistiche; successo: nessun malus; fallimento entro 3 punti dalla DT (parità inclusa), oppure naturale 18+ insufficiente: −5; altro fallimento: −10. Dura fino all’uscita dal piano, senza accumulo tra tentativi; statistiche minime zero.

Recupero pressione in fight: ogni proprio critico positivo riduce di 3 il solo malus da area; doppio critico di 6 complessivi. Valori fissi, non casuali; minimo zero. I malus di altra origine restano invariati.


### Identità Fato / Chaos e occhi — conferme 23 ottobre 2026
Identità Fato / Chaos: Fato è predefinito. A ogni nuovo Grado un solo tiro: 6% niente, 14% una Ispirazione normale, 30% normale e Super, 40% normale/Super/Oculum, 9% le tre più una Schivata Oculum, 1% le tre più Schivata, Scudo pari al 20% della Vita attuale e Scudo Oculum aggiuntivo pari al 25% di quello Scudo, per eccesso. Cambiare identità o abbassare il Grado non ripete i premi; nessun premio retroattivo.
Chaos: a inizio fight e a ogni turno personale estrae indipendentemente da −3 a +3 sulle quattro statistiche; sostituisce i bonus precedenti e li rimuove a fine fight. Dopo un attacco riuscito o una difesa riuscita, 25% di infliggere −3 a tutti i tiri all’avversario per un turno, una sola estrazione per avversario nel proprio turno. I valori di base salvati non vengono alterati.
Raccolta materiali: chi ha identità Chaos ottiene 1,8 volte i grammi estratti, arrotondati per eccesso. Il bonus sostituisce il moltiplicatore del Raccoglitore e non si cumula con esso; non modifica i materiali ricevuti come drop.
Gli occhi seguono il mouse muovendosi leggermente. Solo il clic sul ruolo Master li fa guardare dalla parte opposta in 0,4 secondi; a 0,6 secondi dal clic riprendono a seguire. La cornice del ritratto è più larga del 20%, con bordo proporzionato.

### Monster Book e costi delle skill — 24 ottobre 2026
Il catalogo include 80 creature base distribuite in otto habitat, con statistiche iniziali basse, anatomia e punto debole descritti, drop materiale e due tecniche ciascuna. Ogni tecnica può essere appresa dal catalogo Skill o tramite pergamena secondo le normali regole di apprendimento. I costi delle forme si leggono dalla definizione concreta: Oculum, Volontà, Materia, Resilienza, Vita, Scudo, Obser, Fortuna, Follia, oggetti o materiali; non si sostituisce una risorsa dichiarata con un costo generico. Il parser legge i costi espliciti prima dei numeri di quantità o danno. Per i costi non dichiarati, il Monster Book usa una risorsa positiva coerente con la creatura, oppure nessun costo; non presume Oculum o Materia. Consente un massimo variabile solo quando l’effetto scala davvero con la risorsa spesa. Costi, cooldown, drop, statistiche iniziali e valori restano modificabili nell’editor e salvati sulla scheda.

Il catalogo planare atteso contiene 357 voci fra specie e varianti canoniche, prive di duplicati. Il conteggio comprende le varianti e le creature inserite nelle precedenti aggiunte; le 80 creature base costituiscono un sottoinsieme distinto.

### Catalogo Rusty — prezzi proposti e conferme precedenti
Anti malus 50 Obser, prima copia in omaggio al primo acquisto Postea per personaggio: rimuove una condizione negativa scelta e la blocca fino alla fine dello scontro corrente o prossimo. Il Curatore ha 100 HP e Medicina propria fissata all’acquisto: estrazione equiprobabile 150/100/75/50% della Medicina del compratore, per eccesso. Prezzi proposti modificabili: 95/80/70/60 Obser. Cura 20 + Medicina a ogni proprio turno il proprietario.
Pawn Postea 250 Obser: statistiche iniziali 10/15/25/0; +3 Resilienza per turno vivo solo nel fight. Rinasce soltanto dopo vittoria con +1 permanente a tutte le statistiche, una volta per scontro; iniziativa e Reazione veloce al primo giro.
Core autoriparabile: 90 + livello + Grado ×2, costrutto al livello fissato all’acquisto, riparato al Riposo Lungo. Katana del Fato: 200 Obser, +30 Danni da arma, niente critici negativi mentre equipaggiata, +1 Ispirazione alla chiusura della sessione. Guanti: 60 Obser, +15 Danni scegliendo l’attacco corpo a corpo e 20 Scudo rinnovati a sessione. Runa d’impatto: 50 Obser, +20 Danni selezionati per 20 utilizzi iniziali modificabili. Gli esempi di usi non sono limiti universali su tutte le armi.
Chaos colpisce con lo stesso malus anche chi ha aiutato l’avversario nello stesso confronto, conferma 23 ottobre.

### Cristalli Dust, fusione e board — conferme 23 ottobre 2026
A fine scontro party e NPC alleati restano sulla board; tutti i nemici uccisi generano comunque il proprio drop. Piccolo 1d3 Dust e prezzo 40–60; Medio 1d6+2 e prezzo 90–120; Grande 1d10+2 e prezzo 150–200 Obser, modificabili. Sono materiali crafting e consumabili rompibili a scelta, senza assegnazione automatica della Dust.
Drop aggiuntivo soltanto da nemico ucciso almeno tre livelli sopra chi tira: totale Drop almeno 20 + livello mostro + Grado ×2. Poi una sola estrazione: 25% piccolo, 15% medio, 6% grande, 54% nulla. Non sostituisce gli altri drop; evocazioni escluse.
Fusione I/II/III visibile solo possedendo il cristallo richiesto; ne consuma uno. +1/+2/+3 a tutte le quattro statistiche e +10/+20/+30% agli effetti positivi Art (statistiche, sottotratti, Danni, Difesa, cura). Durata Piccolo 1d3 Riposi Lunghi, Medio 1d6+1, Grande 1d10+2. Una fusione attiva, nuova sostituisce precedente; in fight richiede Azione propria. Bonus temporanei separati dalle statistiche base.
### Parassiti e Martire Mortale — conferme 23 ottobre 2026
Parassita: 1 Resilienza, 0 Volontà, 0 Materia, 0 Oculum, Riflessi +9–15. Unico attacco: infiltrazione con Azione usando Riflessi. Infestato controllato dal Master; il proprietario può tentare liberazione con Resistenza o Volontà una volta per turno spendendo Azione e superando il precedente tiro del parassita. Penalità cumulativa −3 per turno fino a −9. Fallimento entro cinque punti rimuove una Reazione al controllore; fallimento di uno aggiunge −4 al suo prossimo tiro. Critico che danneggia Vita dell’infestato dà +5 al prossimo tentativo di liberazione. Medicina naturale elimina il parassita a 14 con Riflessi9/10,15 con11/12,16 con13,17 con14,18 con15. Vita del parassita non cresce, non è attaccabile dentro l’ospite e non subisce il danno inflitto all’ospite. Metà dei suoi Danni e Difesa si aggiunge all’ospite.
Martire Mortale: debole, EXP dimezzata; alla morte il Master sceglie massimo tre alleati. Bonus statistico 10% +10% ogni dieci livelli, durata max(1, livello/5 per difetto) turni.

Correzione fusione: il +10/+20/+30% si applica anche agli effetti positivi delle Skill, oltre alle Art; Danni e Difesa personali ricevono +15% per la stessa durata, fisso per ogni taglia.

Ultima correzione: il bonus personale a Danni e Difesa della fusione è +5/+10/+15% rispettivamente Piccolo/Medio/Grande; resta +10/+20/+30% agli effetti positivi Art e Skill.

## Conferme e completamenti del 26 ottobre 2026

Modifiche successive alla build `b917217d98d16861a5bbaf1706d78825d883c970`, run `40242640717`, incluse quelle del commit `12cbe566`. Il codice presente non certifica la pubblicazione: verifiche e pacchetti sono riportati separatamente nel resoconto finale.

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

Statistiche e pulsanti inferiori: trasparenza indipendente 0–40%, inizialmente due terzi della generale (12% rispetto al 18% consigliato). Controllo sotto quello generale e ripristino del rapporto; testi/icone pieni, hover sul controllo.

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

Conferme dell’utente: Potere totale = Resilienza + Volontà + Materia + Oculum + Livello + Grado ×3. La scheda mostra il proprio valore. Una Percezione riuscita con totale oltre 40 ha probabilità (totale −40) ×5%, massimo 100%, di leggere il potere totale esatto di NPC e nemici. Questa verifica è distinta dalla lettura ordinaria di livello, probabilità e punto debole.

I rilevatori funzionano anche sugli altri personaggi. Gli alchimisti vendono amuleti, bracciali e cavigliere in legno magico con cristalli che riflettono il cielo anche senza vederlo. A Postea sono gadget cyberpunk. Portata = 50 + livello oggetto ×30. La lettura è una stima entro ±10%; oltre portata mostra solo «oltre la portata» senza il valore reale. Il destinatario online calcola il risultato senza trasmettere le proprie statistiche.

- Alchimisti: 1d9 +6 utilizzi (7–15), tirati una sola volta all’acquisto.
- Postea: ultima correzione confermata 1d23 +12 utilizzi (13–35), prezzo sei volte tanto allo stesso livello.
- Prezzo iniziale scelto su delega: 30 +15 × livello in Obser; Postea sei volte questa cifra.
- Uso: selezione del bersaglio dall’inventario; una normale Azione/Reazione in combattimento. Una carica per scansione, anche oltre la portata; annullare la selezione non consuma. Riaprire negozio o JSON non ritira gli utilizzi.
- Nome, note, livello e utilizzi residui sono modificabili nell’editor oggetto e conservati nel JSON. Portata ricalcolata dal livello modificato, quantità degli acquisti separate. Costi/offerte restano modificabili dal mercante.

Lo Slime Roccioso e le sue varianti seguono le soglie specifiche confermate: Roccia Slime materiale, Indurimento al totale 15 e Rimbalzo al naturale 20, senza imporre la DT generica 20 + livello + Grado ×3. Gli altri mostri conservano la propria DT.

## Potenza totale nei mercanti e colpo potenziato — 26 ottobre 2026

Conferme esplicite: i mercanti considerano anche la Potenza totale per proporre oggetti adatti. Il valore usa Resilienza + Volontà + Materia + Oculum + Livello + Grado ×3. La selezione aggiunge la compatibilità con la potenza a livello, disponibilità e preferenze; prezzi e acquisti conservati non cambiano.

Scarica totale e Impeto totale aggiungono la propria Potenza totale ai Danni di un singolo attacco, una sola volta anche con raffiche e più bersagli. Il prossimo tiro per colpire e il primo tiro nemico per colpirti ricevono +max(2, 10 − Adattamento). Il bonus si consuma quando il singolo attacco viene dichiarato, anche se manca il bersaglio.

Sfinimento: azzera immediatamente tutte le Reazioni disponibili, normali, veloci, gratuite e supplementari; blocca ogni nuovo guadagno, anche da skill, critici, rimbalzi, mecha, Fuga o altre fonti. Durata = 1d3 turni personali + un turno ogni 160 Potenza totale per difetto. Non viene annullato da Stato di Forza. Le Azioni continuano a funzionare. Nuova attivazione sostituisce il colpo in attesa e non accorcia lo Sfinimento. Le Reazioni eliminate non vengono restituite alla scadenza; riprendono i normali nuovi recuperi.

Impostazioni iniziali scelte sulla delega al bilanciamento: costo 5 Oculum per Scarica, 5 Volontà per Impeto; CD tre turni. Nomi, descrizioni, costi, cooldown, formula del bonus, dadi e durata base sono modificabili tramite editor e JSON; le definizioni salvate non vengono sovrascritte.

Online: nessuna nuova connessione usa implicitamente la stanza «test». Il giocatore inserisce il codice del Master; un Master senza codice riceve un codice nuovo. Le stanze già salvate conservano il codice esplicito. Stanze private e approvazione del Master restano operative.

Distribuzione GitHub: Windows normale e Windows Test in ZIP e artifact di cartella separati. Le versioni precedenti restano conservate.
