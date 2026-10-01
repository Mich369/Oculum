# Aggiornamento Oculum: Diari, Mappa degli Occhi e recuperi

## Funzioni aggiunte e corrette

- Diari multipli per personaggio tramite nome del diario; editor e testo originale conservati. Vecchi salvataggi senza nome usano «Diario».
- Memoria personale e di campagna: cronologia, creature, luoghi, PNG, oggetti, missioni, eventi, relazioni e risonanze tra diari.
- Mappa degli Occhi: nodi a occhio, collegamenti con stato, centro selezionabile, ricerca, filtri, zoom, movimento e visualizzazione adattata a desktop e mobile.
- Peso dinamico della memoria: ogni menzione aumenta il peso del nodo; le entità co-menzionate ricevono una risonanza documentata dalla stessa frase. Nodi più ricordati crescono visivamente e vengono ordinati prima, senza alterare il testo originale.
- Ogni relazione derivata apre il diario originale e mette in evidenza la frase sorgente. Le modifiche al diario ricostruiscono la memoria, evitando fatti rimasti da testi eliminati.
- Esiti distinti per incontro, combattimento, sconfitta, abbattimento, uccisione, fuga del nemico, fuga del gruppo e incertezza. Negazioni, intenzioni e dubbi non diventano vittorie automatiche.
- Tutorial: nove punti iniziali liberamente distribuibili, massimo tre assegnati a ciascun sottotratto. Se salti, puoi assegnarli in seguito dalla scheda. Il registro salvato evita assegnazioni duplicate.
- Mostri: niente scelte iniziali di razza, background umano, titolo del Fato o Oculum Art del personaggio. Origine dalla terra per Fato/Chaos, dal nulla per Oblio/Errante. Peculiarità della creatura conservate.
- Shop: quattro gemme occasionali, una per tipo quando compare; prezzo e dado dipendono dalla rispettiva statistica. Il dado viene fissato all’acquisto. Le gemme recuperano punti attuali; l’eccesso sopravvive al salvataggio e al riposo breve e termina al riposo lungo, senza aumentare la statistica base.
- Realtime: conferma del trasporto prima di registrare gli hash, reinvio alle variazioni di presenza/ruolo, conservazione dei diari nei merge protetti e gestione delle schede al Master.
- Mappa esistente: aggiornamenti leggeri conservano le immagini della stessa scena; cambio scena/immagine invalida quelle precedenti. Richieste concorrenti e invii falliti non vengono ignorati.
- Ricerca delle creature nel tutorial e miglioramenti delle schede/Occhi Caduti già presenti inclusi nella distribuzione.
- Test grafici: output separati per piattaforma per evitare collisioni tra screenshot.
- GitHub Actions: controllo codice e test prima delle build; Windows normale/test, macOS, Linux, Android APK/AAB, iOS senza firma e Web. Artifact conservati 30 giorni.

- Correzione del lag nella scrittura: i campi dei Diari non invalidano i calcoli di gioco a ogni carattere. Anteprime dei comandi dopo 320 ms di pausa, autosave dopo 2600 ms; testo e cursore restano immediati. Test su testo lungo e digitazione ripetuta.

## Parametri modificabili

| Parametro | Dove modificarlo |
| --- | --- |
| Nomi delle quattro gemme, costo iniziale (3 Obser), scatto (+3 ogni 10), dado (statistica / 3, minimo d1), apparizione (25% per tipo) | `lib/src/main/oculum_home_merchant.dart`: `oculumStatGemNames`, `oculumStatGemBaseCost`, `oculumStatGemPrice`, `oculumStatGemDieFaces`, `oculumStatGemAvailable` |
| Nuovi stati e riconoscitori del testo | `lib/services/oculum_diary_memory.dart`: `diaryStateLabels`, `additionalStates`, regole del builder |
| Alias delle creature | Catalogo Monster Book passato al builder e collegamenti espliciti nel testo |
| Pausa prima delle anteprime (320 ms) e del salvataggio dei Diari (2600 ms) | `campoModello` in `lib/src/main/oculum_home_colors_and_base_widgets.dart`, opzione `narrativeText` |
| Colori, occhi, distanze, pagine del grafo e cronologia | `lib/pages/oculum_eye_memory_page.dart` |
| Punti iniziali e limite di assegnazione | `lib/src/main/oculum_starter_creation.dart` e interfacce di tutorial/scheda |
| Origine dei mostri | Helper di creazione e selezione nel tutorial |
| Profili separati e chiavi di salvataggio | `lib/services/oculum_save_profile.dart`, definizione compilata `OculumSaveProfile=test` |
| Piattaforme, nomi artifact e giorni di conservazione | `.github/workflows/build_distribution.yml` |
| Percorsi di SDK e packaging locale | `scripts/build_diary_distribution.ps1` |

## Come rendere espliciti nomi ambigui nei Diari

La lettura è locale e usa riconoscitori conservativi, non comprende arbitrariamente tutta la lingua naturale. Le creature del catalogo e diversi nomi di luogo vengono riconosciuti automaticamente. Per un nome nuovo o ambiguo, usa `[[luogo:Bosco Nero]]`, `[[png:Arven]]`, `[[creatura:Forest Demon]]`, `[[oggetto:Chiave d’Ossa]]`, `[[missione:La Torre]]`, `[[evento:Eclisse]]` oppure `[[personaggio:Hoshy]]`. Il testo resta la fonte; questi collegamenti migliorano la classificazione.

## Verifiche e limiti

Suite completa locale aggiornata al 1 ottobre 2026: 578 test passati, uno saltato. I test comprendono gemme, salvataggio, riposi, assegnazione iniziale e nuovo trasferimento delle schede a blocchi. Profilo test compilato verificato separatamente. Analizzatore senza problemi dopo le correzioni.

Layout desktop/mobile e trasporto realtime verificati automaticamente; non costituiscono una prova su due dispositivi fisici. L’autenticazione Supabase live è stata verificata separatamente. Le build iOS/macOS senza firma richiedono le rispettive procedure di installazione/firma.

## Distribuzione locale

Tutti gli artifact vengono raccolti in `build/distribution`: `windows/oculum.exe` con runtime completo, `Oculum-Windows.zip`, `test/windows/Oculum-Test.exe` con runtime completo, `Oculum-Test-Windows.zip`, `Oculum-Android-release.apk`, `Oculum-Android-release.aab`, `web/` e `Oculum-Web.zip`. Le Actions macOS, iOS e Linux usano la stessa cartella nei rispettivi runner; i relativi artifact devono essere scaricati nella distribution locale quando disponibili.

La versione Windows test usa salvataggi separati e salta l’avvio cloud automatico. Avvia l’EXE dentro la sua cartella, senza separarlo da DLL e directory `data`. Il report `diari-verifica-distribuzione.json` registra dimensioni e SHA256 degli artifact creati.

## Ricezione schede — 1 ottobre 2026

Schede grandi e immagini vengono trasferite a blocchi, con importazione solo a messaggio completo. Il reinvio al Master continua ogni 30 secondi dopo i primi tentativi; il Master richiede le schede all'ingresso e dispone di «Richiedi schede ai Player». Le conferme Master sono distinte dall'ACK del server. Invii concorrenti della stessa scheda vengono accorpati e una conferma precedente non chiude una consegna nuova. Il salvataggio locale precede gli invii delle modifiche ai proprietari.

Per il trasferimento a blocchi aggiorna sia Master sia Player. Salvataggi e immagini restano nello stesso formato. I test di consegna utilizzano un canale simulato; la prova live su due dispositivi resta da eseguire.

Tutti i parametri modificabili sono elencati in `docs/REALTIME_AFFIDABILITA.md`: blocchi 64 KiB, memoria complessiva 64 MiB, massimo 8 trasferimenti incompleti e scadenza 3 minuti in `oculum_sheet_transfer.dart`; timeout canale/invio in `oculum_realtime_service.dart`; reinvio, accorpamento e richieste in `oculum_realtime_integration.dart`; ordine di salvataggio in `oculum_home_persistence.dart`; registri temporanei in `main.dart`; test di trasferimento e workflow Windows test nei rispettivi file.
