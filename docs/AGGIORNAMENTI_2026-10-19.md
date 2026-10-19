# Oculum — aggiornamento del 19 ottobre 2026

## Implementazione e verifiche sono distinte

Questo elenco descrive il codice della patch. Le verifiche concluse e la versione effettivamente pubblicata/installata sono riportate alla fine. Non equivale a una prova online fra due browser reali.

## Combattimento e destinatari

- Attacco e Difesa mantengono VC e CM, con tiri aggiuntivi, colori delle statistiche e pulsanti +/−. Per un attacco alternativo basta spiegarlo a voce.
- Ogni effetto può salvare `minimumTargets` e `maximumTargets`: vuoti/zero lasciano il riconoscimento automatico. La scelta dei colpi consente ripetizioni sullo stesso bersaglio; quelli minimi mancanti si distribuiscono casualmente fra i selezionati. Gli ID sono diversi anche sullo stesso nemico.
- I parser riconoscono numeri e parole, quantità esatte, intervalli e limiti basati sull'Oculum investito. Le frasi non riconosciute restano manuali; costi e requisiti non diventano danni o buff.
- Cure e supporti passano dal selettore destinatari, con Se stessi e più applicazioni. Gli effetti vengono congelati al momento dell'uso e non si ritirano dopo un reinvio. Si usano gli stessi effetti anche offline su schede locali.
- Aiuta compagno conserva anche i risultati negativi e li consuma una volta nel prossimo tiro del destinatario.
- Le reazioni possono essere concesse agli alleati tramite l'effetto aggiungi reazioni, con costo/durata configurabili; la concessione non introduce un costo implicito non scritto.
- Scheda propria verde, alleati azzurri e nemici rossi nei nuovi selettori. Il ruolo deriva dai lati della turnistica.
- La consegna online attende una conferma del destinatario; i messaggi pendenti vengono ritentati ogni cinque secondi, nello stesso fight e con controlli su identità/sessione/campagna. Un duplicato non ripete danni, cure o aiuti.
- Il danno risolto continua a usare Difesa, resistenze elementali, Scudi, HP temporanei e Vita, con Pawn e relative eccezioni. Schivata Oculum è preparabile dal riquadro delle difese online.
- Vampirismo usa la conferma dell'attacco riuscito e i danni dichiarati, come da regola già presente: non trasforma i soli HP persi dal bersaglio nella nuova base di cura. Le ricevute duplicate non assegnano una seconda cura.

## Osservazione e scontri

- Tiri e azioni mostra il migliore fra Percezione e Investigazione sbloccate. L'azione offre sia il lancio libero sia la scelta di un partecipante; anche Percezione nei Sottotratti apre questa scelta.
- Un totale almeno pari a **Livello + Velo** rivela il livello esatto e abilita le stime. Se manca di massimo 5, il livello percepito si riduce dello scarto mantenendo il Grado; oltre 5 compare «Non senti abbastanza». Il critico scopre il punto debole, con Fragilità Semi Letale per sé e alleati fino alla fine dello scontro. Una nuova lettura peggiore non cancella una scoperta migliore.
- Le informazioni sono distinte per campagna, scontro e lato. La fine del fight le elimina; l'unione esplicita conserva quelle dei fight riuniti.
- Il Master può unire scontri. Partecipanti duplicati non vengono aggiunti due volte; gli altri scontri rimangono salvati e vengono svuotati dei partecipanti trasferiti. Le richieste pendenti compatibili passano allo scontro unito.

## Titoli e Chained Fate

- Riepilogo cliccabile dei titoli indossati e slot distinti. Standard: 6 iniziali, 7 al III, 8 al VI, 9 al IX.
- Apprendimento: 1 + Grado. Con Rebirth i primi 3 Evoluti non usano slot.
- Malanno: uno ogni 6 Resilienza; non si rimuove volontariamente. Chaos: uno ogni −10 Karma. I vecchi nomi Caos sono riconosciuti come Chaos senza riscrivere le personalizzazioni.
- Alchimia/Magia: massimo pari al Grado, con uno già utilizzabile al Grado 0 per Rebirth.
- Prima Art: traguardi della prima forma della prima skill, seconda forma della seconda skill e terza forma della terza skill, assegnati una volta.
- Il Master avvia Chained Fate con partecipanti espliciti e lo completa oppure termina senza premio. I primi tre completamenti danno uno slot Fato ciascuno; EXP ×2 nei primi tre, poi ×3. Gli ID completati impediscono premi duplicati.
- I titoli già equipaggiati nei vecchi salvataggi non vengono rimossi automaticamente quando superano una nuova capacità.

## Riserva statistica e Reputazioni

- Livelli 5/15/25/50/100/200: riserva rispettivamente +2/+4/+7/+13/+25/+50. Ogni soglia si ottiene una volta, anche dopo abbassamento/rialzo del livello o caricamento. Distribuzione dal pannello EXP; Oculum non assegnabile quando il massimo naturale è zero.
- Reputazioni organizzabili in cartelle e sottocartelle senza limite fisso. È possibile creare cartelle vuote, navigarle e spostare città/luoghi fra cartelle. Valori, descrizioni e contributo Karma rimangono conservati.

## Grafica e personalizzazione

- Tre artwork dell'utente inclusi localmente in `assets/oculum/home_art`: città/occhio gotico, Sole con isole volanti e scena ambrata. Nessuna connessione Canva necessaria all'avvio.
- Occhio del sigillo reattivo al puntatore con ridisegno isolato e riduzione animazioni rispettata. Gli asset dei ruoli esistenti restano gli stessi.
- Cornici e colori usano il tema dell'app. Le informazioni dettagliate del confronto sono richiudibili.
- Modificabili: nomi, testi, costi, cooldown, effetti, destinatari, numero di colpi, durate e ruoli tramite editor esistenti; cartelle e reputazioni dal relativo pannello; distribuzione della riserva dal pannello EXP; partecipanti/inizio/fine Chained Fate dal Master. Gli artwork possono essere sostituiti con file mantenendo i percorsi dichiarati nel pubspec.

## Stato verifiche

- Test mirati finali: 25 passati. Dettaglio in `output/reports/combat-review-20261019.json`; le verifiche di trasporto e condivisione sono riportate nella revisione sotto.
- Build finali Web, Windows normale e Windows Test completate. Gli archivi Web e Windows hanno superato la verifica di contenuto e hash. L'esito definitivo della distribuzione si legge nel suo `BUILD-VERIFICATE.json` e nel risultato dello script di verifica; la sola presenza di questo documento non certifica l'APK.
- Analisi statica finale: `dart analyze lib`, nessun problema.
- Suite completa e CI del nuovo commit non eseguite in questa rifinitura. Pages non aggiornato da questa esecuzione.
- Verifica browser locale: avvio, selezione ruolo Player e apertura della creazione scheda riusciti. Computer Use si è poi fermato perché non poteva confermare l'URL corrente; il combattimento completo fra browser normale e incognito resta da verificare.
- Canva: collegamento successivamente ripristinato. Il PNG a risoluzione completa consegnato dall'utente è incluso come `assets/oculum/home_art/canva_spirit_duelist.png`; nessuna ulteriore modifica alle mani.

## Revisione combattimento e Percezione — 19 ottobre

- Identità online: la presenza dichiara solo schede possedute. Cambiare scheda non invalida un messaggio in arrivo; i bersagli sul Master usano l'identificativo originale del proprietario, anche se la copia locale ha un altro identificativo.
- Una difesa pendente su un'altra scheda posseduta compare con un pulsante per aprire quella scheda. Nessuna seconda applicazione dei danni alla ricezione di duplicati.
- Il Master inoltra al Co-Master le schede dei partecipanti, comprese le proprie creature, conservando la proprietà originale. Il registro si aggiorna anche quando la campagna locale del Player ha un identificativo diverso. Il Player non importa l'inoltro destinato al personale.
- Percezione: scelta di un partecipante oppure lancio libero; soglia esatta Livello + Velo, pari sufficiente. Scarto da 1 a 5: livello percepito ridotto dello scarto, Grado conservato e probabilità dichiarate approssimate. Scarto maggiore: «Non senti abbastanza», senza percentuali. Un tentativo peggiore non cancella una lettura migliore. Il critico riuscito conserva la scoperta del punto debole.
- Le mosse con fascia da 1 a più bersagli mantengono la separazione fra base da dividere e bonus individuali anche quando si sceglie un solo bersaglio. Il test di regressione verifica il bonus Danni +8 una sola volta nella skill singola.
- Verifiche completate: 25 test mirati di Percezione, pianificatore, danni, consegna online, regole dei mostri e attacchi contrapposti; test di trasporto/condivisione e test con due client Supabase reali, con scheda grande, conferma del destinatario e riconnessione. Queste verifiche non equivalgono a una prova completa fra due finestre browser.
- Personalizzabili negli editor esistenti: Livello, Grado e Velo che determinano la soglia; statistiche, costi, cooldown, effetti, elemento, durata e fascia bersagli delle tecniche; partecipanti e unione degli scontri. Le letture ottenute sono salvate per campagna, scontro e lato. Le regole della soglia sono definite in `lib/game/oculum_combat_scout_rules.dart`.
- Packaging locale riproducibile: `scripts/build_combat_distribution.ps1`. Compila Web, Windows, Windows Test con salvataggi separati e APK; verifica contenuto e hash degli ZIP, runtime e APK, conserva il vecchio pacchetto in backup e blocca la sostituzione se Oculum è aperto o se cambiano le sorgenti durante la compilazione. Il manifest dichiara esplicitamente origine locale e presenza di modifiche non committate.

## Atelier e Aiuto e utilità (aggiunte successive)

- Editor raggiungibile dalle Impostazioni: immagini su layer, anteprima, posizione, dimensione, rotazione, ordine, opacità, importazione/esportazione di codice con immagini incorporate. Nessun percorso locale nel codice condiviso.
- Colori delle quattro statistiche con selettore visuale HSV, RGB e HEX sincronizzati, anteprima precedente/nuovo e ripristino. Le etichette e le abilità che usano `statFormulaColor` seguono gli override.
- PNG Figma realmente esportati e collegati: `assets/oculum/atelier/oculo.png`, `cuspide.png`, `reliquiario.png`. Disponibili come pulsanti nell'editor, inclusi nell'esportazione se aggiunti ai layer.
- Sorgente Figma modificabile: https://www.figma.com/design/ZooYFl2ORaXAPZks3Jb8B1
- Ritratto leggermente rettangolare, occhio originale mantenuto.
- Tasto della scheda e del Party «Aiuto e utilità»: tiro di aiuto, Art/Skill/Titoli di supporto e cura manuale concordata. Online usa le schede della turnistica corrente, offline quelle locali. I membri narrativi senza una scheda collegata non sono destinatari di rete.
- Monitor della vecchia distribuzione eliminato su richiesta dell'utente: nessuna vecchia build deve sostituire questi sorgenti.

- Nuovo artwork originale anime gotico generato attraverso Figma (nodo 2:2), ispirato alla qualità delle illustrazioni promozionali del riferimento e non alla grafica in-game. PNG conservato localmente: `assets/oculum/home_art/anime_reliquary.png`.
- Selettore colori verificato con modifica del cursore R e inserimento HEX; entrambi aggiornano gli altri controlli. Test mirati finali: 9 passati (`build/test-custom-theme-final.log`).
- Web locale con Atelier: compilazione release completata (`build/web-custom-theme.log`). Questo non dimostra pubblicazione Pages né sincronizzazione reale fra due browser.

## Rifinitura successiva di negozi e combattimento

- Sei test mirati superati su acquisto Dust, limite di tre e ripristino al Riposo Lungo, persistenza dei nuovi campi, buff percentuali, premi e richieste Master senza duplicati (`build/test-refinement-merchant.log`).
- Il requisito di Grado dell'equipaggiamento considera sia il Grado oggetto sia il requisito esplicito. La skill rapida verifica il maggiore fra livello oggetto e livello della forma anche dopo la conferma.
- Open principali e aggiuntive dei titoli nei gruppi combattimento, usando l'attivazione originale; bonus non applicati una seconda volta.
- Le condizioni preesistenti da un'azione vengono consumate prima di aggiungere gli effetti nuovi della skill: una condizione appena concessa non perde subito la propria durata.
- Uno scontro selezionato che scompare non viene sostituito con il primo fight disponibile. Alla prima ricezione si seleziona automaticamente soltanto un fight contenente la propria scheda.
- Cibi e infusi riportano nel log la durata effettiva; il bonus Chained Fate di fine fight si limita ai partecipanti del dungeon.
- Modificabili negli editor: livello/Grado/requisito degli oggetti, statistica e punti di crescita, abilità e forme, costi, ricariche, effetti, destinatari; DT e durata delle condizioni dal menu contestuale Master. Prezzi e definizioni iniziali di cibi/pet si trovano nel catalogo sorgente del mercante e in `oculum_alchemy_pets.dart`.
- Analisi statica completa: `No issues found!` (`build/analyze-refinement-final.log`). Suite completa: **842 passati, 2 saltati** (`build/test-oculum-refinement-full-final.log`). Gli otto test mirati per pergamene, mercanti, attacco/danno online, effetti offline, tecniche mostro, bilanciamento e pannelli combattimento sono passati (`build/test-oculum-refinement-targeted-rerun.log`).
- Il test di Aiuta compagno ora verifica che il modificatore salvato, positivo o negativo, corrisponda al log e nomini il destinatario. Il precedente test imponeva erroneamente un valore non negativo, contrario alla regola confermata.
- Il commit locale `bc96f1c2` raccoglie la rifinitura verificata. Run Actions `39185190149` su `745cc891ec7b9247265a1b28b428e77f4cc5ae8c` ha tutti gli 8 job riusciti, ma i relativi artefatti precedono questo commit locale e non vanno installati come versione finale.
- Il push del commit `bc96f1c2` a `main` è stato respinto dalla revisione automatica. Il repository remoto è ancora a `745cc891ec7b9247265a1b28b428e77f4cc5ae8c`; Pages e CI aggiornate non sono partite.
- La pubblicazione Pages e la verifica dal sito non sono ancora state confermate. Il browser locale continua a essere disabilitato in Work; nessuna prova reale fra due browser è stata fatta.
- `build/distribution` contiene ancora i pacchetti del 17 ottobre. Saranno sostituiti soltanto con artefatti verificati costruiti dai sorgenti aggiornati; la cartella precedente resta intatta fino a quel momento.

## Turnistica autorevole del Master
- Ingresso online tramite condivisione scheda, conferma nello snapshot del Master e recupero della richiesta se la scheda arriva dopo.
- Cambio PG: selezione automatica del suo scontro; Co-Master può consultare gli scontri condivisi senza crearne copie indipendenti.
- Risorse dei partecipanti riallineate dalle schede ricevute, mantenendo iniziativa, ordine e risorse del turno del tracker.
- Condizioni, cooldown e Art avanzano con il contatore del Master; bloccato il contatore personale online indipendente.
- Eventi di combattimento ricevuti dal Master instradati al relativo scontro pubblicato anche se ne sta visualizzando un altro.
- Snapshot numerati e associati alla sessione del Master: messaggi vecchi o estranei non sostituiscono lo stato più recente.
- Verifiche locali: 12 test mirati riusciti; analisi di lib pulita. Prova completa fra due browser da eseguire separatamente.
- Modificabili: partecipanti, lato alleato/nemico, ordine e iniziativa, turno, condizioni e durate, valori di abilità ed effetti tramite gli editor esistenti. La sorgente online dei turni è il Master; offline resta manuale.
- Estensione: cure/condizioni automatiche anche su schede possedute non aperte, ricevute emesse con l'identità del destinatario, progressione dei relativi turni senza cambiare la scheda visibile. Bonus e malus di Aiuta compagno visibili e consumati nel tiro successivo. Log difensivo con mossa e DT dal tiro nemico. Verifiche mirate comprendono danni a strati, cura unica, condizione ricevuta e aiuto negativo.
- Home: le cinque anteprime sotto l'immagine principale sono selezionabili. L'immagine scelta viene salvata, rimane al cambio scheda e si può ripristinare con «Originale». La scelta non modifica le immagini del personaggio o dei mostri.
- Parser testuale collegato anche all'attivazione Skill/forme Art/Open senza effetti configurati, rispettando gli override manuali e i comandi rapidi esistenti. Aggiunte sintassi Cura/Stato, numeri romani delle condizioni e testo Markdown.
- Classificazione multipla: buff/debuff sempre in Supporto e utilità; valori offensivi e difensivi pari in entrambi i gruppi, altrimenti prevale quello maggiore. Rinomina applicata anche alle pagine precedenti della scheda.
- Erbe fumabili aggiunte allo stock esistente dell’alchimista senza rigenerarlo: prezzo stabile 30–50 Obser, buff con tre limiti alternativi, Confuso successivo con −20% danni e DT +2, cura/riposo come rimozione. Dati salvati nel JSON dell’oggetto e della scheda.
- Scroll inventario nella barra combattimento, classificate dagli effetti. Connessione online ai bersagli con tiro della scroll riutilizzato, consumo monouso e condizioni mantenuti. Test mirati: 53 riusciti (parser, effetti strutturati, danni, cure e supporto, erbe e Confuso).
- Segno del Fato nell’alchimista, prezzo del negozio 50–120 Obser e una sola copia con probabilità visibili. Curva confermata 70/20/10 → 30/40/30, costo conservato sull’oggetto, consumo e assegnazione dell’ispirazione mediante il sistema esistente. Test della somma 100%, monotonia e confini delle estrazioni.

- Correzione utente: Segno del Fato ha prezzo fissato dal negozio, 50–120 Obser, una sola copia nello stesso shop. Segno del Chaos: solo alchimista, presenza 3% per negozio, prezzo 60–120 Obser. Consumandolo, ogni 10 Obser del suo prezzo (per difetto) genera un’estrazione indipendente su Resilienza/Volontà/Materia/Oculum casuale: 75% +1 punto, 13% +2, 9% +3, 3% +0. Punti permanenti; disponibilità e prezzo persistenti.

Personalizzazione segni: costo e disponibilità nello stock JSON del mercante; costo conservato in craftData.fateSign/chaosSign nell’inventario. Curva Fato, rarità Chaos e probabilità punti centralizzate in lib/src/main/oculum_fate_sign.dart. Nessun prezzo cambia riaprendo il negozio. Verifiche: analisi lib senza problemi; 17 test mirati superati, inclusi acquisto ripetuto rifiutato, esaurimento persistente nel JSON e consumo unico del Chaos.

## Recupero automatico online — 19 ottobre 2026
Richiesta utente: tutte le proprie schede online devono poter arrivare al Master e partecipare alla sua turnistica. Correzione più recente: la connessione, l’arrivo del Master e la richiesta di recupero sincronizzano automaticamente solo la scheda attualmente usata; le copie ricevute non vengono rispedite come proprie. L’ingresso richiesto resta in attesa e viene ritentato finché lo snapshot del Master non contiene il partecipante. La presenza in ritardo non elimina una richiesta: il Master la ricontrolla dopo la presenza o la scheda. Restano verificati proprietario/sessione, campagna e fight pubblicata. Il recupero di una singola scheda usa il suo tag.

Confronto trasferimenti staff: esclusi solo i timestamp volatili dalla firma del contenuto, mantenendoli nel payload; una scheda invariata non provoca reinvii ricorsivi. Verifiche: 7 test mirati riusciti; prova reale con due client Supabase su trasferimento grande, ACK e riconnessione riuscita. Non è una prova completa di combattimento in due browser.

- Precisazione utente: invio automatico al Master soltanto della scheda attualmente usata, senza inviare in blocco le altre. Restano conferma di ricezione e ritentativi per la scheda scelta.
