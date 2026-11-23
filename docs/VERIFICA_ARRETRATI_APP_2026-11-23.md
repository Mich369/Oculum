# Oculum principale — verifica degli arretrati del 23 novembre 2026

## Sorgenti e ambito

Il checkout principale era a `f88388a3`, mentre i pacchetti locali successivi provenivano da un’altra revisione. Recuperati i sorgenti dell’app dalla candidata `7353cae76b1a79f61d8b03aa336a2390dbd6ee04`: 698 file confrontati per SHA-256, senza sovrascrivere le modifiche locali preesistenti. Cinque file erano già equivalenti alla candidata; `scripts/build_combat_distribution.ps1` è stato preservato nella sua versione locale. Il recupero è documentato in `build/qa-app-arretrati-20261123/source-integration-receipt.json`. Non sono stati modificati `oculum_rl/`, salvataggi reali o pacchetti precedenti. Le cartelle di artwork collegate a G: non sono state ripulite.

Le funzioni riportate come presenti erano già nella candidata: il recupero non equivale a una loro nuova implementazione. Le modifiche funzionali nuove di questa verifica sono la generazione dei feriti confermata in questa chat e la correzione dell’editor Schivate.

## Fight Creator

Presenti il tasto in cima alla prima pagina Master, squadre multiple con nomi e colori, quantità da 1 a 10 per generazione, schede distinte, confronto delle Potenze individuali e sommate e suggerimenti filtrati per area, regno e microrealtà. Accesso riservato al Master; bozze e schede generate restano private fino a «Pubblica Fight». Creare o preparare una bozza non avvia lo scontro. Prove locali includono selezione, quantità, privacy, cambio di ruolo e disposizione a 320 px.

**Completamento nuovo:** ogni nuovo nemico ha il 20% di probabilità di nascere ferito. Percentuale intera casuale di Vita residua dal 25% al 75% inclusi, arrotondata per eccesso e almeno 1 quando il massimo è positivo. Un’estrazione indipendente per creatura. Restano invariati alleati, schede esistenti, Scudi e statistiche. Nessuna frattura o condizione viene inventata. Testati gli estremi, tutte le facce della probabilità, copie distinte, ricaricamento JSON e preparazione dello scontro. I valori generati rimangono modificabili nella scheda.

## Turnistica e Monster Book Party

Il codice della candidata include token esagonali per PG, NPC e mostri, bordi della squadra, immagini canoniche o ritaglio della famiglia e apertura dell’immagine completa. Le informazioni del Party restano progressive: incontro nel Fight e pagina acquistata seguono i permessi esistenti. Verificati caricamento e scoperte della campagna, ritratti e protezione delle informazioni ignote. Questo non certifica una prova con più client reali.

## EXP, Drop e allenamento

Verificate le regole più recenti: EXP comune dalla somma delle Potenze valide dei nemici morti o a terra, sottraendo una sola volta la Potenza del partecipante; un KO non produce i Drop da morte. Nel metodo corrente si conservano le regole della PT media e dei bonus di Grado. Allenamento separato non letale, bonus personale +150 dopo Riposo Lungo e +100 se Difesa nemica e Danni propri differiscono al massimo di 6. Assenti i premi da uccisione nell’allenamento. I test usano schede e archivi isolati, senza modificare i salvataggi dell’utente.

## Rebirth, Occhi dei Caduti, azioni gratuite e Schivate

Presenti e verificati Rebirth con conferma e annullamento, cronologia e quote, bonus del party e frazioni conservate. Le regressioni degli Occhi dei Caduti verificano rinascita, eredità delle forme, costi ed effetti e preservazione delle modifiche. La forma Skill con Azione gratuita conserva l’opzione e il costo nel JSON.

**Correzione nuova:** il clic destro sul contatore delle Schivate extra apriva già l’editor, ma il salvataggio poteva riutilizzare il controller dopo la sua eliminazione durante la chiusura. La finestra ora attende la chiusura completa. La regressione riproduce il clic destro, salva e verifica che le cariche consumate non vengano restituite.

## Temi e telefono

Verificati sfondo a piena pagina sotto i menu e ritaglio mobile a 1920×1080, 1080×1920 e 390×844. Ispezionata la cattura telefono generata dal test. Cornici e controlli rimangono separati; nessuna nuova scelta artistica è stata approvata per deduzione.

## Filtri, consumabili e pagine acquistate

Verificati filtri di regni e microrealtà, assegnazione del tema alla sola scheda scelta, perdita dei privilegi Master, pagine acquistate del Party e relativi dati visibili. Le prove dei consumabili includono bersaglio alleato, inventario e risorsa di chi usa l’oggetto, parte anatomica scomparsa, prezzi persistenti e durata fino al Riposo Lungo. Non sono stati modificati il catalogo o gli oggetti personalizzati salvati.

## Immagini e nomi arretrati

[Elenco completo per ID e nome corrente](ARRETRATO_VISIVO_APP_2026-11-23.md) e [dati con i percorsi degli asset](ARRETRATO_VISIVO_APP_2026-11-23.json), ricavati dal risolutore runtime e verificati sul disco:

| Ambito | Conteggio |
| --- | ---: |
| Voci attive di creature, varianti incluse e NPC esclusi | 1.262 |
| Senza desktop dedicato collegato | 702 |
| Senza telefono dedicato collegato | 1.194 |
| Senza reliquia dedicata collegata | 1.191 |
| Con tutti e tre gli asset dedicati | 67 |

I conteggi misurano collegamenti tecnici, non nuove approvazioni dello stile. Il fallback desktop su telefono resta disponibile. I nomi correnti e gli alias storici sono conservati. L’elenco non trasforma un nome in un voto mancante: le proposte creative e i lotti ancora aperti restano nelle rispettive ricevute e in `DA_FARE_PATCH_E_SUCCESSIVI.md`. Nessuna sostituzione automatica o generazione massiva è stata avviata.

## Verifiche locali

- Gruppo priorità: **84 test passati**, log `build/qa-app-arretrati-20261123/priority-tests.log`.
- Gruppo feriti e salvataggi: **103 test passati**, log `build/qa-app-arretrati-20261123/wounds-and-saves-tests.log`.
- Inventario, visibilità, ritratti e parser: **37 test passati**, log `build/qa-app-arretrati-20261123/inventory-and-compatibility-tests.log`.
- Schivate e log dopo la correzione: **7 test passati**, log `build/qa-app-arretrati-20261123/dodge-and-log-final.log`.
- Regressione finale feriti, Schivate e log: **11 test passati**, compresa la conservazione della Vita all’avvio del Fight, log `build/qa-app-arretrati-20261123/final-regressions.log`.
- Esportatore del manuale: **2 test Python passati**; esportate tutte le 116 sezioni del manuale interno.

I gruppi si sovrappongono: non sommarli come test distinti. La prima prova delle Schivate ha riprodotto il difetto poi corretto. Il primo controllo statico ha rilevato una parentesi graffa mancante attorno a un `if`, corretta senza cambiare la regola. Il controllo successivo non ha riportato problemi. La suite completa dell’intero repository non è stata certificata da questa verifica.

## Pacchetti e pubblicazione

La candidata precedente `build/distribution/Oculum-CandidataEspansione-7353cae7` ha superato il controllo di tutti i **12.310 file** e degli SHA-256. Ciascuno ZIP Windows contiene **6.151 file**, identici al runtime della propria edizione. Verificate integrità dell’APK debug e corrispondenza del registro cumulativo in tutti i pacchetti. Questa verifica riguarda i pacchetti precedenti alla nuova regola dei feriti, non li presenta come aggiornati con il nuovo codice.

Per la nuova candidata si usa `scripts/build_local_app_candidate.ps1`: prepara una nuova sottocartella di `build/distribution`, senza sostituzioni o pulizie, con Windows normale e Test in cartelle e ZIP separati e APK esplicitamente debug. Il builder registra commit e impronta dei sorgenti, verifica che non cambino durante le build e controlla tutti i file e i contenuti degli archivi. Gli esiti della nuova compilazione sono nelle ricevute di build; non sono anticipati da questo documento.

La firma Android stabile non è configurata: assenti `android/key.properties` e il percorso del keystore stabile. Il debug non è un aggiornamento firmato per le installazioni di produzione. GitHub, sito, download anonimi e prove online reali restano verifiche distinte. La pubblicazione è sospesa fino alle scelte dei lotti e dei nomi, come richiesto. Non sono state applicate migrazioni al database né attivate funzionalità a pagamento.

## Cosa può essere personalizzato

- **Schede:** nome, tipo, livello, Grado, statistiche, Vita e riserve correnti, Scudi, ritratto e ritaglio, note e campagna tramite gli editor esistenti.
- **Fight Creator:** partecipanti, quantità, livello e distribuzione delle statistiche delle nuove creature; variante, nome dello scontro, squadre, colori, guardiani disponibili, allenamento, area e obiettivo percentuale della Potenza. La Potenza è calcolata dai dati della scheda.
- **Feriti:** Vita corrente modificabile dopo la generazione. Il 20% e l’intervallo 25–75% sono la regola automatica appena confermata, non nuovi cursori di bilanciamento.
- **Skill, Art e altre capacità:** forme, requisiti, costi e risorse, Azione gratuita dove prevista dall’editor, recuperi, durata, bersagli, effetti e descrizioni. Le personalizzazioni nel JSON restano prioritarie rispetto al catalogo.
- **Occhi dei Caduti e creature:** valori, abilità e forme attraverso gli editor già disponibili; nessuna crescita statistica aggiunta dalla sola dimensione dei nodi della Mappa degli Occhi.
- **Oggetti e consumabili:** offerte e prezzi modificabili nelle scorte, quantità e dati dell’oggetto nell’inventario; effetti e durata dove esposti dai rispettivi editor. Gli oggetti già salvati non vengono sostituiti.
- **Aspetto:** tema e colore della singola scheda, reliquia, scelte manuali o automatiche, trasparenze, caratteri, presentazione e opzioni mobile esistenti.
- **Schivate:** cariche extra tramite clic destro e modifiche rapide; le cariche già consumate restano registrate.
