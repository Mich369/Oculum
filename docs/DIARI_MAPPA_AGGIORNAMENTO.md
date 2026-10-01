# Aggiornamento Oculum: Diari, Mappa degli Occhi e recuperi

## Correzione caricamento e Attacco — 1 ottobre 2026

Eliminata la dipendenza circolare fra formula Attacco, Vita massima e formule rapide. Un errore di interpretazione dell'app non deve più sostituire un JSON valido con un backup precedente. I salvataggi normali e Test mantengono le chiavi originali e la loro separazione.

Il campo «Bonus Attacco (danni inflitti)» aggiunge danni senza aumentare VC. La VC contribuisce ai danni inflitti. Il campo Danno/Cura applica danni subiti o cure. Le formule per elemento e i fallback delle schede Master/connesse seguono la stessa separazione. La regola esistente dei comandi `@VC` (Volontà ×3) rimane valida.

Modificabile: formule in `oculum_home_calculations.dart`; etichette in `oculum_home_sheet_page.dart` e `oculum_home_dialogs_quick_edit.dart`; fallback Master/connessi in `oculum_home_combat_progression.dart` e `oculum_home_share_content.dart`; protezione dal recupero di una revisione precedente in `oculum_home_persistence.dart`. Test: `oculum_save_load_role_regression_test.dart`, con copie private opzionali tramite `OculumRecoveryFixture`.

Le copie locali di recupero in `output/save-recovery-20261001` sono escluse da Git. Non vengono distribuite con l'app.

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

### Master con 300 schede — 1 ottobre 2026

- La plancia Party usa un elenco a righe costruite quando entrano nel viewport: tutte le schede restano disponibili scorrendo, senza montare centinaia di schede insieme. Lo stesso principio è applicato ai turni riportati delle campagne.
- Il riepilogo dei turni legge solo identificativo, nome e token: non duplica diari, inventari o immagini della campagna a ogni aggiornamento.
- Gli identificativi già normalizzati vengono letti senza riattraversare l'intero elenco. Caricamento, importazione, creazione e salvataggio mantengono la normalizzazione completa e la verifica di unicità.
- La ricerca delle schede durante la normalizzazione dei token usa un indice locale, ricreato a ogni chiamata per evitare dati obsoleti.
- Il test di campagna supporta 300 schede, tutte nel Party, 300 token collegati, 300 Occhi e immagini originali. Controlla anche che l'autosave conservi ogni scheda e il ritratto. Il test di scrittura dei Diari mantiene 300 schede e verifica testo, cursore e assenza di invalidazione dei calcoli a ogni carattere.
- Le misure sono test CPU in modalità debug, non una certificazione di frame rate su ogni dispositivo. I salvataggi molto grandi richiedono ancora tempo per completare la scrittura protetta; autosave e backup rimangono attivi.

| Cosa si può modificare | File e punto |
| --- | --- |
| Soglia della plancia Party (6), larghezza di colonna (330), altezza (280–620), precaricamento (100) | `lib/src/main/oculum_home_secondary_pages.dart`, `masterDashboardPartyBoardPanel` |
| Soglia e viewport dei nemici (8, massimo 720), iniziativa (6, massimo 720), anteprima Party (24), righe elenco salvato (64) | `lib/src/main/oculum_home_secondary_pages.dart`, pannelli Master |
| Altezza del riepilogo turni (massimo 320) e righe (48) | `lib/src/main/oculum_skill_effects_ui.dart`, `masterAllBattlesTurnDashboard` |
| Lettura rapida degli identificativi e normalizzazione dei salvataggi | `lib/src/main/oculum_home_persistence.dart`, `sheetTagAt`, `sheetInMasterPartyAt`, `assicuraTagSchede` |
| Indice temporaneo token/schede | `lib/src/main/oculum_home_combat_progression.dart`, `normalizeMasterInitiativeTokens` |
| Numero di schede e nome del rapporto | `test/oculum_large_campaign_benchmark_test.dart`: definizioni `OculumBenchmarkSheets` e `OculumBenchmarkLabel` |
| Campagna di prova durante la digitazione | `test/oculum_diary_typing_test.dart`: elenco di 300 schede |
| Test automatico GitHub con 300 schede e rapporto scaricabile | `.github/workflows/diary_tests.yml` |

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

Suite completa locale aggiornata al 1 ottobre 2026: 584 test passati, due prove di rete opzionali saltate. I test comprendono gemme, salvataggio, riposi, assegnazione iniziale, trasferimento delle schede a blocchi, suggerimenti e cambi di ruolo dall'Occhio. La prova realtime live è stata eseguita separatamente ed è passata. Profilo test compilato verificato separatamente. Analizzatore senza problemi dopo le correzioni.

Layout desktop/mobile e trasporto realtime verificati automaticamente; non costituiscono una prova su due dispositivi fisici. L’autenticazione Supabase live è stata verificata separatamente. Le build iOS/macOS senza firma richiedono le rispettive procedure di installazione/firma.

## Distribuzione locale

Tutti gli artifact vengono raccolti in `build/distribution`: `windows/oculum.exe` con runtime completo, `Oculum-Windows.zip`, `test/windows/Oculum-Test.exe` con runtime completo, `Oculum-Test-Windows.zip`, `Oculum-Android-release.apk`, `Oculum-Android-release.aab`, `web/` e `Oculum-Web.zip`. Le Actions macOS, iOS e Linux usano la stessa cartella nei rispettivi runner; i relativi artifact devono essere scaricati nella distribution locale quando disponibili.

La versione Windows test usa salvataggi separati e salta l’avvio cloud automatico. Avvia l’EXE dentro la sua cartella, senza separarlo da DLL e directory `data`. Il report `diari-verifica-distribuzione.json` registra dimensioni e SHA256 degli artifact creati.

## Ricezione schede — 1 ottobre 2026

Schede grandi e immagini vengono trasferite a blocchi, con importazione solo a messaggio completo. Il reinvio al Master continua ogni 30 secondi dopo i primi tentativi; il Master richiede le schede all'ingresso e dispone di «Richiedi schede ai Player». Le conferme Master sono distinte dall'ACK del server. Invii concorrenti della stessa scheda vengono accorpati e una conferma precedente non chiude una consegna nuova. Il salvataggio locale precede gli invii delle modifiche ai proprietari.

Per il trasferimento a blocchi aggiorna sia Master sia Player. Salvataggi e immagini restano nello stesso formato. I test di consegna utilizzano un canale simulato; la prova live su due dispositivi resta da eseguire.

Tutti i parametri modificabili sono elencati in `docs/REALTIME_AFFIDABILITA.md`: blocchi 64 KiB, memoria complessiva 64 MiB, massimo 8 trasferimenti incompleti e scadenza 3 minuti in `oculum_sheet_transfer.dart`; timeout canale/invio in `oculum_realtime_service.dart`; reinvio, accorpamento e richieste in `oculum_realtime_integration.dart`; ordine di salvataggio in `oculum_home_persistence.dart`; registri temporanei in `main.dart`; test di trasferimento e workflow Windows test nei rispettivi file.

## Nomi ricordati e ruoli modificabili dall'Occhio

Scrivendo `[[querci` viene proposto anche `[[Nemico:Quercia Sepolta]]` se compare in una pagina precedente dello stesso personaggio. Funziona fra raccolte e dopo il ripristino del salvataggio. I collegamenti appena completati vengono ricordati anche durante la stessa scrittura; l'input non rilegge tutte le pagine a ogni tasto.

Un nome nuovo come `[[Soldato Forte`, `[[Soldato Forte]]` o `[[Soldato Forte[]]` propone tutte le categorie: Party, Alleato, Personaggio, NPC, Mostro, Nemico, Morto, Ambiente, Luogo, Arma, Armatura, Scudo, Oggetto, Occhio dei Caduti, Art, Titolo, Fazione, Missione ed Evento. Il giocatore sceglie il collegamento; nessun testo viene classificato o riscritto senza il clic. `Alleato` appartiene al Party, mantenendo il termine originale nel suggerimento.

Nella Mappa seleziona il nodo e premi «Cambia ruolo». Può passare da Party a Nemico, Morto, Mostro, Occhio dei Caduti o alle altre categorie disponibili. «Evoluzione del ruolo» conserva i passaggi con data. L'identità del nodo, i collegamenti e le citazioni originali restano; il cambio riguarda la memoria, non modifica statistiche, inventario o schede di gioco. Il registro è locale alla scheda ed è salvato nel campo aggiuntivo `diaryEntityRoles`; vecchi salvataggi senza il campo si aprono con registro vuoto. Le copie online limitate o in sola lettura non consentono il cambio.

La vista campagna completa è riservata al Master; la vista Player usa i propri testi. Il catalogo dei suggerimenti personali non legge i diari degli altri personaggi.

Il registro personale `diaryEntityRoles` viene escluso dalle schede realtime e dalle patch al proprietario: modificare un ruolo nella propria memoria non sovrascrive la conoscenza di un altro utente. Rimane nei salvataggi e nei backup locali.

| File | Cosa puoi modificare |
| --- | --- |
| `lib/services/oculum_diary_links.dart` | Categorie proposte, alias ricordati, ricerca entro 256 caratteri, limite 8 suggerimenti di nomi e inserimento del collegamento. Tutte le categorie di un nome nuovo rimangono disponibili. |
| `lib/services/oculum_diary_memory.dart` | Sinonimi come Alleato/Party, Nemico, Mostro, NPC, categorie ed estrazione conservativa. |
| `lib/services/oculum_diary_roles.dart` | Ruoli disponibili, registro dei passaggi, ripristino e identità persistente. |
| `lib/pages/oculum_eye_memory_page.dart` | Filtri, pulsante cambio ruolo, dialogo ed evoluzione del nodo. |
| `lib/src/main/oculum_home_colors_and_base_widgets.dart` | Suggerimenti nel testo, finestra locale di 512 caratteri per ricordare link appena completati e aggiornamento differito di 320 ms. |
| `lib/src/main/oculum_home_titles_inventory_pages.dart` | Catalogo della scheda, cache, apertura della Mappa, permessi e salvataggio del cambio ruolo. |
| `lib/src/main/oculum_home_persistence.dart` e `lib/main.dart` | Campo `diaryEntityRoles`, migrazione per assenza del campo e stato della scheda. |
| `test/oculum_diary_roles_links_test.dart`, `test/oculum_diary_typing_test.dart` | Esempi richiesti, interfaccia, cronologia, identità, salvataggi e assenza di invalidazioni globali durante la scrittura. |
| `.github/workflows/diary_tests.yml`, `.github/workflows/test_windows_distribution.yml` | Test di ruoli e suggerimenti nelle Actions; prova realtime live opzionale con input `live_realtime`. |

La prova realtime live del 1 ottobre è passata: due client Supabase reali nella stessa macchina, stanza temporanea e dati sintetici, immagine test di 500.000 caratteri, confronto completo, ACK del destinatario distinto dal server e riconnessione. Non equivale a una prova delle interfacce Player/Master su due dispositivi fisici.

## Icone trasparenti e Obliterati — 1 ottobre 2026

Le immagini finali sono estratte direttamente dai pixel originali, su autorizzazione dell'utente. Le prove con ImageGen sono state scartate perché alteravano il disegno. Nessun originale viene sovrascritto; dimensioni e RGB dei pixel conservati restano identici. La rimozione agisce sul canale alpha.

| Cosa modificare | File / parametro |
| --- | --- |
| NPC vivi e Party / Alleati: occhio viola | `assets/oculum/icons/oculum_npc_eye.png` (512×512) |
| Nemici e Mostri: occhio rosso originale già trasparente | `assets/icon/oculum_eye.png` (512×512, invariato) |
| Morti: occhio grigio infranto | `assets/oculum/icons/oculum_dead_eye.png` (1254×1254) |
| Obliterati / Oblio: Reliquia senza bianco | `assets/oculum/icons/oculum_obliterated_eye.png` (256×256) |
| Associazione fra ruolo e immagine | `lib/widgets/oculum_memory_eye.dart`, `oculumMemoryEyeAsset` |
| Dimensione nodo: 84 centrale, 64 periferico, crescita massima +30 | `lib/pages/oculum_eye_memory_page.dart` |
| Soglia del bianco: minimo RGB 225, neutralità massima 18 | `scripts/remove_eye_background.ps1` |
| Pulizia del bordo bianco: soglia 190, un passaggio sui bordi | `EdgeWhiteThreshold` nello stesso script |
| Riflessi interni protetti per NPC/Morti | `EyeCenterX/Y`, `EyeRadiusX/Y`; NPC: .5/.46/.29/.13, Morti: .5/.44/.25/.13 |
| Rimozione anche del bianco interno della Reliquia | `-RemoveAllWhite`; conserva grigi, neri e trasparenza già presente |
| Nuovo ruolo persistente e cronologia | `lib/services/oculum_diary_roles.dart`, chiave `obliterated` |
| Link manuali e suggerimenti | `[[Obliterato:Nome]]`, alias Oblio/Obliterata/Obliterati, servizi Diari |
| Test trasparenza, dimensioni, cambio icona, persistenza ruolo | `test/oculum_memory_eye_test.dart` |

Cambiare ruolo nell'Occhio cambia subito l'icona, conserva identità, fonti e cronologia. La classificazione personale non modifica automaticamente stirpe o statistiche della scheda. Gli altri tipi di nodo conservano il sigillo generico. I ritratti caricati nelle schede restano disponibili.

Verifica dei pixel finali: 53.124 pixel visibili dell'NPC, 342.872 dei Morti e 21.219 degli Obliterati confrontati con gli originali, senza differenze RGB. La prova controlla anche le dimensioni. La suite usa screenshot del Manoscritto separati per piattaforma e, con `OculumBenchmarkLabel`, per esecuzione: evita collisioni e blocchi Windows sui PNG aperti.

Verifica della modifica alle icone: 588 test superati, 2 prove live facoltative saltate; log `output/eye-icons-final-regression-20261001.log`. I test dei layout includono desktop e mobile simulati. Il test live Supabase descritto nelle sezioni precedenti resta una verifica separata svolta con due client sullo stesso computer.

## Sottotratti, Schianto e correzioni della memoria — 1 ottobre 2026

Ogni sottotratto aggiunge il Livello al bonus esistente, una volta sola. Anche i sottotratti personalizzati ricevono questo bonus. Fortuna mantiene la sua formula precedente: non riceve il nuovo bonus di Livello intero. Base, maestria, bonus temporanei e valori salvati restano distinti dal bonus calcolato.

Schianto è nel gruppo Volontà, con bonus metà Volontà + Livello oltre ai punti base e agli altri bonus esistenti. I salvataggi precedenti ricevono il nuovo sottotratto a base zero conservando gli altri valori. Le metà intere seguono la convenzione esistente dell'app (31 / 2 → 15).

Il manuale descrive la distanza di volo come differenza positiva fra Volontà dell'attaccante e del bersaglio, aumentabile dalle Skill. Schianto può scagliare contro pareti o da alture: Danno + metà Volontà + durezza della superficie. Il recupero dal volo è possibile fino al proprio Livello in metri. Restano descritte le precedenti proporzioni per l'impatto (fragile ÷2, muro ×1, rinforzato ×2). Il valore numerico della durezza nella nuova formula additiva è ancora da chiarire con l'autore: non è stato inventato un automatismo di danno.

Nei Diari, seleziona un nome e usa il tasto destro su desktop o la pressione prolungata su mobile: «Assegna ruolo» conserva Copia/Incolla e inserisce un collegamento esplicito. Se la selezione è dentro un link già esistente, riclassifica il collegamento senza annidarlo. Solo questa azione esplicita modifica il testo selezionato.

Il Master può rinominare un'entità nella propria mappa, cambiarne il ruolo privatamente e consultare la cronologia di nomi e ruoli. L'identità, gli alias originali e le citazioni dei Diari restano invariati. «Condividi con il party» consente di scegliere separatamente nome e ruolo, con destinatari singoli o tutti i membri disponibili. Per segnare un morto per tutti: cambia il ruolo in Morto, apri Condividi e seleziona tutto il party.

Questa condivisione usa il realtime esistente: le comunicazioni selettive sono cifrate per destinatario, salvate prima dell'invio e mantenute nella coda fino alla conferma del destinatario, anche dopo riconnessione. Il ricevente conserva una comunicazione del Master cliccabile come fonte, senza alterare i suoi Diari. Al momento il nuovo invio selettivo è integrato nel realtime Supabase; il trasporto LAN/relay continua a funzionare per le funzioni precedenti e non trasmette il registro privato né l'identità crittografica. La nuova condivisione selettiva su LAN/relay e la verifica su due dispositivi fisici restano da completare.

| Cosa puoi modificare | File / parametro |
| --- | --- |
| Bonus di Livello e basi dei sottotratti, Schianto e gruppo | `lib/src/main/oculum_home_calculations.dart`, `oculumHiddenEyeDerivedBonusFor`, `defaultHiddenEyeStats` |
| Descrizione del bonus nelle schede | `lib/src/main/oculum_home_sheet_page.dart`, `hiddenEyeStatDescription` |
| Test bonus, Fortuna e migrazione | `test/oculum_subtrait_level_test.dart` |
| Regole Schianto italiane e inglesi | `lib/src/main/oculum_manual_sections.dart`, sezione 12 |
| Menu destro / pressione prolungata | `lib/widgets/oculum_diary_context_menu.dart` e `lib/services/oculum_diary_links.dart` |
| Cronologia dei nomi, alias e ruoli privati | `lib/services/oculum_diary_roles.dart` |
| Pulsanti Master, ricerca alias e cronologie | `lib/pages/oculum_eye_memory_page.dart` |
| Campi condivisi e destinatari, tentativi ogni 30 secondi | `lib/src/main/oculum_diary_knowledge_integration.dart` |
| Coda persistente, revisioni, ACK, cifratura e limiti dei messaggi | `lib/services/oculum_diary_knowledge_sync.dart` |
| Presenza e nuovi eventi nel realtime esistente | `lib/services/oculum_realtime_service.dart`, `lib/src/main/oculum_realtime_integration.dart` |
| Esclusione dei metadati privati da LAN/relay | `lib/src/main/oculum_p2p_network.dart`, `diaryPublicSheet` |
| Campo aggiuntivo locale `diaryKnowledgeSync` e lettura retrocompatibile | `lib/src/main/oculum_home_persistence.dart` |
| Verifiche menu, cifratura, coda, rinomina e protezione patch | `test/oculum_diary_context_menu_test.dart`, `test/oculum_diary_knowledge_sync_test.dart`, `test/oculum_realtime_patch_test.dart` |
| Test nelle Actions e schermate separate per esecuzione | `.github/workflows/diary_tests.yml`, `.github/workflows/test_windows_distribution.yml`, `test/oculum_eye_memory_widget_test.dart` |
