# Patch del 29 ottobre — verifiche e limiti

Questo rapporto riguarda le modifiche successive a e188eafe. Le prove di quel commit già distribuito non vengono attribuite alla nuova patch. Le righe del registro attività diventano concluse al100% solo dopo la conferma richiesta dall'utente.

## Verifiche locali

| Prova | Risultato ed evidenza |
|---|---|
| Prima suite completa |1615 passati,36 falliti,6 saltati; i fallimenti sono stati esaminati singolarmente. Log locale `build/oct29-full-patch-tests.log`. Non è una suite verde. |
| Ripetizione dei file falliti e nuove regressioni |155 passati; un test del mercante non raggiungeva gli acquisti perché il clic avveniva prima del nuovo layout dopo lo scroll. Corretto solo il sincronismo della fixture. `build/oct29-full-failure-regressions.log`. |
| Ultime correzioni di turno, anatomia, reset e mercante |45 prove passate; l'esportazione di Lusier incontrava un file canonico mappato da un altro lettore. Le esportazioni dei test ora vanno prima in `build/verified-character-exports`, senza scrivere sopra i file importati da altre suite. `build/oct29-final-regressions.log`. |
| Personaggi dopo l'isolamento degli export |11/11 passati, inclusi PT, risorse, carte, Derisione, Titolo e ciclo Open; `build/oct29-character-export-retest.log`. |
| Consegna e permessi |11/11 passati: importazione del codice finale di Lusier a690/690 Vita e301PT, reset di sole schede possedute o autorizzate, log versione e chiusura esterna; `build/oct29-final-handoff-tests.log`. |
| Anatomia e turno manuale |54 prove passate nel gruppo locale, compresi23 casi di parti,9 nuove regressioni di crescita Pawn e selezione manuale senza ricarica. Un percorso di test inesistente indicato dal comando è stato corretto; i test reali non sono stati disabilitati. `build/oct29-anatomy-growth-turn-regressions.log`. |
| Artwork lunari/Ik, Bramble, Ogle e Pawn |72/72 verifiche renderer passate, incluse tre larghezze, margini, controlli cliccabili e trasparenza delle reliquie. I pixel quasi trasparenti ammettono alpha1/255 agli angoli, mantenendo le soglie di trasparenza effettiva e contenuto visibile. |
| Analisi statica |Nessun problema nella revisione finale locale. Gli avvisi introdotti dai nuovi moduli sono stati corretti, non ignorati globalmente. |
| Codici dei personaggi |Tre JSON e tre OC3 verificati per checksum e identità dei dati; nessun identificativo privato del proprietario. Senka81Vita, maschera non indossata; Lusier690Vita/301PT; Erik260Vita/131PT. I JSON di prova vengono promossi solo dopo le verifiche. |

I gruppi si sovrappongono: i conteggi non vanno sommati come test unici. La suite completa finale e le prove online autenticate devono essere lette dal run GitHub dello stesso commit compilato.

## Difetti concreti corretti durante la revisione

- Selezionare manualmente un partecipante poteva ripristinare Azioni, Reazioni e Movimento. La selezione conserva ora le risorse; il vero avanzamento del turno conserva il proprio ripristino.
- Una richiesta di reset autenticata poteva nominare una scheda altrui per raggiungerne il fight. Si verifica anche la proprietà della scheda nominata; seconde schede dello stesso giocatore e staff autorizzato restano validi.
- La generazione di un tag mancante poteva ricorrere nelle statistiche derivate. L'identità iniziale usa valori di base e rimane stabile.
- Gli effetti del partecipante non attivo potevano essere una lista immutabile; il cambio turno usa una copia modificabile e non elimina gli effetti Open o permanenti soltanto perché hanno durata zero.
- La crescita di Pawn e l'editor degli Occhi usavano ancora il moltiplicatore Vita precedente. Ora rispettano la fase del livello, conservando ferite, sovramassimali consentiti e formule speciali.
- Il percorso della nuova Open dei Guardiani Lunari non era collegato all'attivazione. Il test dell'attivazione reale verifica ora costo, Buff e raffica.

## Duello richiesto

Riga D29 approvata dall'utente: le due schede OC3 originali, Senka con maschera, motore e dadi reali.19 attacchi alternati, vittoria di Senka a135/135Vita,14Scudo e20ScudoOculum. Senka riceve82EXP alla conclusione,151 complessive contando69 dai tiri; nessun aumento di livello. La seconda chiusura non duplica il premio. È un singolo scenario casuale, non una stima del tasso di vittoria. Gli input, gli snapshot e la traccia completa restano privati sotto `build/simulations` e non vengono pubblicati.

## Cosa rimane modificabile

Statistiche e sottotratti; costi e loro risorse, minimi e massimi; requisiti e cooldown; elementi, bersagli, quantità e durate delle tecniche; moltiplicatori e soglie di corazza/nucleo; integrità, materiali, penalità e recupero delle parti; equipaggiamento e inventario personalizzati; distanza, membri e percentuale del mezzo nel viaggio; scelta dei premi e preparazione degli eventi da parte del Master. L'interruttore PT è separato per scheda. Le personalizzazioni restano nel JSON e non vengono sostituite dalle definizioni aggiornate del catalogo.

## Verifiche distinte e lavoro ancora aperto

CI, quattro prove online autenticate, pacchetti locali, avvio dell'EXE, firma APK e download pubblici sono passaggi distinti da completare per questa patch. Non costituiscono una prova di tre sessioni su dispositivi indipendenti o di assenza assoluta di bug.

Sono collegati dieci pack completi approvati, non tutti i temi del catalogo:1199 voci comprese varianti,1188 con almeno un artwork dedicato mancante nell'inventario tecnico. Le domande anatomiche delle creature successive restano da risolvere prima di canonizzarne i nuovi disegni. La proiezione pubblica degli stati anatomici remoti ha un modello con campi consentiti, ma la sua interfaccia nemica remota non è certificata da questi test locali.
