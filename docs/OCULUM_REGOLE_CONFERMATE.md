# Oculum — registro delle regole confermate

Ultimo aggiornamento: 19 ottobre 2026. Documento da consultare prima di modificare il regolamento.

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

- Conferma del 18 ottobre 2026: il danno al partecipante selezionato, dopo il confronto dei tiri, passa per Difesa, Scudo Oculum, Scudo normale, HP temporanei e infine Vita. Il quasi riuscito mantiene la Difesa ×1,5 arrotondata per eccesso; un attacco evitato non consuma protezioni. Restano le eccezioni esplicite già definite per abilità, Resistenza, Scudo di Salvataggio e Pawn. Un duplicato della stessa risoluzione non applica di nuovo il danno.

- Online, in una turnistica, scegli il bersaglio e il tiro d'attacco. VC è il tiro ordinario; Schianto, Forza, Riflessi o altri tiri alternativi richiedono una descrizione e una motivazione al Master.
- Il log del bersaglio richiede una difesa con CM, Riflessi, Resistenza o Manifestazione del Potere, secondo la mossa. Non pubblicare statistiche nascoste per calcolare probabilità.
- Offline le abilità devono continuare a funzionare. Scelta del bersaglio, tiro difensivo ed esito possono essere manuali, senza autorizzazione del Master online.
- Gli effetti su un nemico non devono diminuire per errore le statistiche di chi li attiva.

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
- Anche cure, effetti, difese e supporti possono avere più destinatari. Il riconoscimento deve funzionare sia per effetti strutturati sia per parser del testo.
- Si possono concedere reazioni ad altri. La propria scheda è verde, gli alleati azzurri, i nemici rossi.
- Online le azioni riguardano solo il proprio fight; deve esistere una funzione esplicita per unire più fight. Offline resta possibile la gestione manuale intuitiva.
- Attacchi senza skill usano i Danni inflitti della scheda. La risoluzione deve rispettare Difesa, resistenze per tipo, Schivata Oculum, Scudi, HP temporanei e Vita, anche online. Migliorare il collegamento del vampirismo con danni realmente inflitti e turnistica.
- Nascondere inizialmente le probabilità. Percezione o Investigazione selezionano un bersaglio; un totale almeno pari al livello ne rivela livello esatto e probabilità. Mostrare nei Tiri e azioni il migliore dei due tiri. Un critico scopre il punto cieco per sé e alleati: richiesta di attacchi «semi letali», il cui effetto preciso e durata sono **da chiarire**.
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
