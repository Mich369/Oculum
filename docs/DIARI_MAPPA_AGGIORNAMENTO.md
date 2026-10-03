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

### Immagini e Costellazione — 1 ottobre 2026

- Le miniature del Party e dei token vengono decodificate fuori dal thread dell'interfaccia, con massimo due worker e richieste duplicate accorpate. Originali, esportazioni e immagini salvate conservano tutti i byte.
- I salvataggi di almeno 1 MiB usano i file protetti già presenti senza duplicare enormi JSON nelle preferenze. Prima di togliere una vecchia copia dalle preferenze, viene conservata in un file `*_legacy_preferences*.json`. All'avvio vengono migrate solo copie esattamente uguali al file protetto; le versioni differenti restano recuperabili. Il fallback nelle preferenze rimane quando il file non si può scrivere. Backup, verifiche e autosave restano attivi.
- La Costellazione è visibile all'inizio di Storia, con un'anteprima dei collegamenti scritti nei Diari. Premere la costellazione o «Apri la Costellazione degli Occhi» apre la mappa completa; il Master può aprire anche quella della campagna.
- La costruzione della Mappa viene differita al microtask successivo e la pagina si apre subito, senza trasferire oggetti Dart complessi tra isolate desktop/mobile. Backlink, conteggi e connessioni usano l'indice invece di riscorrere tutte le relazioni durante ogni confronto di ordinamento. Il filtro viene riutilizzato durante il cambio del nodo; rinomina, ruoli e comunicazioni invalidano la cache. Fonti e permessi rimangono quelli esistenti.
- Il benchmark di 300 schede usa ora ritratti con contenuti base64 distinti e immagini nei token. Non riutilizza una sola immagine in tutte le schede. Il test delle relazioni verifica 10.000 collegamenti e tutte le fonti.

| Parametro modificabile | Dove |
| --- | --- |
| Cache miniature: 64 immagini / 24 MiB; massimo 2 worker | `lib/src/main/oculum_home_image_cache.dart`, `OculumDecodedImageCache` |
| Qualità/dimensioni miniature, forme e fallback | `lib/src/main/oculum_home_secondary_pages.dart`, `masterPartyAvatar`, `initiativeTokenAvatar` |
| Soglia file protetti (1 MiB), archivio delle copie precedenti e migrazione | `lib/src/main/oculum_home_persistence.dart`, `_writeSaveBlob`, `_archiveLegacyPreferenceMirror`, `_migrateMatchingLargePreferenceMirrors` |
| Anteprima in Storia: 6 collegamenti, altezza 190, apertura personale/campagna | `lib/src/main/oculum_home_titles_inventory_pages.dart`, `storyConstellationPanel`, `openEyeMemory` |
| Costruzione differita e indice della mappa | `lib/src/main/oculum_home_titles_inventory_pages.dart`, `openEyeMemory` |
| Indice di backlink, menzioni e connessioni, invalidazione esplicita dopo sostituzioni di relazioni | `lib/services/oculum_diary_memory.dart`, `DiaryMemory` |
| Filtro memorie e ridisegno della costellazione | `lib/pages/oculum_eye_memory_page.dart` |
| Prove di immagini originali, migrazione, 300 ritratti e apertura da Storia | `test/oculum_performance_safety_test.dart`, `test/oculum_save_load_role_regression_test.dart`, `test/oculum_large_campaign_benchmark_test.dart`, `test/oculum_diary_typing_test.dart` |

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

## Identità visiva della campagna — 1 ottobre 2026

Il guscio dell'app espone un **sigillo vivo** che apre direttamente la Mappa degli Occhi. La variante estesa mostra campagna, scheda, pagina e numero di pagine del Diario; la barra superiore usa il sigillo compatto. La memoria resta raggiungibile anche dalle schede, dal Master e dagli inventari.

La barra superiore usa inoltre una sfumatura cattedrale e un indicatore discreto della connessione. È una modifica solo visiva: navigazione, dati, autosave, modalità offline e compatibilità mobile restano invariati.

| Cosa puoi modificare | File / parametro |
| --- | --- |
| Sigillo, anello, tacche delle pagine e accessibilità | `lib/widgets/oculum_living_seal.dart` |
| Associazione campagna/scheda/pagina e apertura Mappa degli Occhi | `lib/main.dart`, `OculumLivingSeal` nell'AppBar |
| Colori della sfumatura superiore | `backgroundMidColor` e `primaryColor` in `lib/main.dart` |

## Schede, Master e regole aggiuntive — 1 ottobre 2026

Sei nuovi preset modificabili sono disponibili nelle Impostazioni: Originale, Cenere, Sangue, Aurora, Natura e Lume. Mantengono il sistema dei colori esistente e si aggiungono ai temi precedenti. Campi e pulsanti condivisi seguono subito la palette attiva, con contrasto leggibile. Ogni pagina principale mostra una breve indicazione del primo passo; si può nasconderla e riattivarla da Impostazioni → Indicazioni per iniziare.

I pannelli condivisi usano cornici incise e titoli con sigillo: la modifica si estende alle pagine che li usano (schede, combattimento, Master, inventario, mercato e risorse). I colori seguono la personalizzazione della scheda; le immagini non vengono tinte. Le incisioni sono statiche e si disattivano in modalità leggera. Il riferimento visivo inviato dall’autore orienta il restyle: le illustrazioni e la disposizione completa del mockup non sono state sostituite automaticamente alle schermate esistenti. Aiuta compagno conserva i propri comandi e regole.

La pagina Master costruisce i pannelli quando entrano nell’area visibile. Su desktop le due colonne scorrono indipendentemente. La generazione permette nome, elemento e livello; risorse e vita iniziano piene. La redistribuzione conserva i punti posseduti e varia di circa ±10% le proporzioni della creatura. Senza peculiarità: Resilienza > Volontà > Oculum > Materia. Senza Oculum Art, Oculum va alle altre tre. Crescita per livello: 9 comune, 11 Mini-Boss, 13 Boss; per Grado: 10, 12, 15. La compensazione dei Titoli (+3 per livello) resta inclusa nella generazione.

**Punto Cieco:** nei controlli danni del nemico il Master può indicare la parte colpita, il danno base e la fragilità per colpo. Il primo colpo ha già +10%, poi +20%, +30% e così via; il valore percentuale è modificabile. L’anteprima mostra il danno prima della conferma. Il danno attraversa scudo, armatura e vita esistenti. Riduci contatore corregge solo il contatore, senza ripristinare la vita. Nomi, fragilità e contatori sono salvati separatamente dalla scheda condivisa: i Player ricevono solo i normali effetti dei danni.

**Accordo col Fato:** una volta per scheda, anche per quelle precedenti prive del nuovo campo. Da Risorse scegli il tiro attivo: normale usa l’effetto dell’Ispirazione base; critico negativo ha 80% effetto Super Ispirazione e 20% scelta Oculum (nuovo critico 50% positivo/50% negativo). Rinunciare all’opzione Oculum concede un’Ispirazione base e conserva il tiro. L’Accordo non torna ai riposi. La scelta Oculum salva prima una ricompensa base di sicurezza, evitando di perderla chiudendo l’app durante la scelta.

Livelli guadagnati: +3 temporaneo alle quattro statistiche per livello, +2 dopo riposo breve, zero dopo lungo. Gradi guadagnati: +5 statistiche e +100 scudo; il breve dimezza solo il bonus statistico, il lungo azzera quel bonus e dimezza lo scudo residuo ottenuto dai Gradi. Nessun premio retroattivo sui livelli dei salvataggi precedenti.

Il mercato include carni di mostri, erbe e alcolici consumabili. Carne di Forest Demon: +2 Volontà e +1 Materia. Liquore di Cenere: ogni dose -2 Volontà, +1 Materia e +1 Oculum; nessun bonus Resilienza. Gli effetti si sommano e terminano al prossimo riposo; il loro registro è separato dagli altri buff temporanei.

Le nuove menzioni negli Occhi della Memoria alimentano un registro persistente: ogni tre menzioni si tenta 10%, aumentando di dieci punti dopo ogni insuccesso e tornando al 10% dopo la ricompensa. Il controllo avviene alla costruzione della memoria, senza analisi aggiuntiva a ogni battuta. Riaprire lo stesso grafo non genera nuovi premi. Il legame dell’Occhio dei Caduti concede 10 EXP ogni 30 punti guadagnati. Le Open offensive generate usano un dado da d60 a d120 più Attacco; i poteri già scritti conservano la propria descrizione.

La DT del Master può essere applicata a più schede Player ricevute. Salvataggio prima dell’invio e modifiche rimaste locali vengono ritentate alla connessione tramite il protocollo patch esistente. I test locali non equivalgono alla verifica su due dispositivi fisici.

| Cosa puoi modificare | Dove |
| --- | --- |
| Cornici, spaziature, incisioni e colori dei pannelli | `lib/src/main/oculum_design_system.dart`, `oculum_home_colors_and_base_widgets.dart` |
| Layout Master e Aiuta compagno | `oculum_home_secondary_pages.dart`, `oculum_home_sheet_page.dart` |
| Punti per livello/Grado e proporzioni dei mostri | `oculum_starter_creation.dart` |
| Nome, elemento, livello e risorse della generazione | `oculum_home_persistence.dart` |
| Fragilità, nomi e contatori dei Punti Ciechi | Pulsante Punti Ciechi · Master; formula in `lib/services/oculum_blind_spot.dart` |
| Probabilità Accordo col Fato | `lib/services/oculum_fate_pact.dart`; azione in `oculum_home_resources_rest_titles_data.dart` |
| Bonus di progressione e riposi | `lib/services/oculum_progression_surge.dart`, `oculum_home_resources_rest_titles_data.dart` |
| Carni, erbe, alcolici: prezzi e bonus | `oculum_home_merchant.dart`, `ensureMerchantFoodOffers` |
| Menzioni e probabilità d’Ispirazione | `lib/services/oculum_memory_inspiration.dart` |
| Legame ed esperienza degli Occhi dei Caduti | `oculum_fallen_eyes.dart` |
| DT multipla e ritentativi | `oculum_home_secondary_pages.dart`, `oculum_realtime_integration.dart` |
| Compilazioni e verifica ZIP/runtime | `scripts/build_diary_distribution.ps1` |

### Scheda compatta e modalità desktop
La scheda Cattedrale presenta ritratto, Vita e Oculum, quattro statistiche compatte e azioni immediate. I pannelli completi restano nelle sezioni espandibili. Modifica e ricerca aprono il pannello necessario. Su desktop è disponibile il menu laterale; sui telefoni la scheda si adatta fino a 320 px. Il pulsante «Oculum: usa le fiammelle» ripristina il pannello precedente e conserva la scelta nel salvataggio della scheda.

| Cosa puoi modificare | Dove |
| --- | --- |
| Composizione della scheda, dimensioni ritratto, statistiche e sezioni | `lib/src/main/oculum_reference_sheet.dart` |
| Barra oppure fiammelle | Pulsante nella scheda; campo `referenceOculumFlames` |
| Modalità desktop e menu laterale | Impostazioni e freccia del menu |
Avvio Windows: `oculum.exe --desktop` attiva la modalità desktop e apre il menu laterale, conservando i dati delle schede.

## Layout della campagna — aggiornamento finale 1 ottobre 2026

La versione Cattedrale usa le illustrazioni e le cornici dell'immagine originale dell'autore, conservata senza alterazioni in assets/oculum/campaign_reference.png. I controlli rimangono widget interattivi: l'immagine di riferimento non sostituisce l'app.

Su desktop il menu esterno serve le pagine dell'app; Art, Diario, Inventario e Occhi sono nel menu interno della scheda, evitando doppioni. Impostazioni rimane nel menu esterno. I pulsanti compatti aprono pagine dedicate con i controlli completi. La scelta Player/Master rimane disponibile dalla barra superiore e dalla Home. Su mobile restano i collegamenti adattati alla larghezza.

| Cosa puoi modificare nell'app | Dove |
| --- | --- |
| Tornare al vecchio design, senza cambiare i salvataggi | Impostazioni → Torna al vecchio design; disattiva per ritornare al nuovo |
| Barra Oculum oppure fiammelle precedenti | Scheda → Oculum: usa le fiammelle/barra |
| Statistiche attuali e massimali separati | Scheda → Statistiche |
| Vita attuale e massimale, oppure massimale automatico | Scheda → Statistiche; i valori restano nascosti con Vita Afona |
| Colori delle statistiche e delle risorse | Personalizzazioni esistenti della scheda |
| Sfondo a tinta unita, sfumature verticali/orizzontali/diagonali/radiali o scacchi | Impostazioni → Disegno dello sfondo; colori alto/centro/basso |
| Nome, identità e ritratto | Scheda → Modifica |
| Immagine assegnata a un partecipante e informazioni rivelate | Controlli dell'incontro; i mostri non usano ritratti generici automatici |
| Nome e immagine riconosciuti personalmente | Incontro Player → Assegna nome e immagine |
| Quantità, uso dei consumabili, donazione locale e vendita ridotta | Inventario; vendita subordinata al mercato aperto |
| Diari, collegamenti, ruoli e fonti della memoria | Diario e Mappa degli Occhi |
| Menu e composizione delle pagine, per lo sviluppo | lib/src/main/oculum_reference_campaign.dart e oculum_reference_sheet.dart |
| Cornici e porzioni dell'illustrazione originale, per lo sviluppo | lib/widgets/oculum_reference_frame.dart e oculum_reference_art.dart |

La donazione descritta qui trasferisce oggetti fra schede locali autorizzate. Gli scambi online esistenti conservano il proprio percorso. I test di widget generano anteprime desktop/mobile con dati dimostrativi; non certificano la ricezione fra due dispositivi fisici né le prestazioni GPU di ciascun telefono. I log precedenti in questo documento sono verifiche storiche: per questa distribuzione usare output/restyle-package-tests.log, output/restyle-package-analyze.log e il rapporto distribution/diari-verifica-distribuzione.json.

Verifica finale: 611 test di regressione superati, 2 prove live facoltative saltate. Verifica aggiuntiva: swipe fra 300 partecipanti a 320 px superato; navigare non avanza il turno. Analisi statica: nessun problema. Anteprime Home, Statistiche, NPC, Mostro, Mini-Boss e Boss prodotte dai widget reali con dati dimostrativi in output/ui/campaign-desktop-final-20261001. Le anteprime Windows/macOS sono test di layout, non build macOS.


## Aggiornamento Art, comandi e creazione — 1 ottobre 2026

- Sottotratti apribili da un pulsante compatto sotto Tiri e azioni, cliccabili per il tiro; controlli di turno accanto al titolo.
- Attacco, difesa e bonus apre VC, CM, danni inflitti, difesa e modifica bonus, mantenendo iniziativa, movimento e schivata.
- Difficoltà nella pagina Identità; Ritratto e Occhio limitato a 390 pixel anche sul desktop.
- Art incorporate conservate ed editabili. Oculum: azione senza visione dagli occhi indicati, poi un turno senza subire colpi per risvegliare il potere. Martial, Defiled ed Emblem istantanee. Illness: debito di 1 azione e 2 reazioni, +5 statistiche durante l'uso; Skill pagate in Follia. Emblem: Skill a cooldown, +3 VOL e +2 MAT per ogni Emblem incorporata oltre la prima. Defiled: cinque evoluzioni, risorse Obser, oggetti o statistiche selezionabili.
- Tipi Art riconosciuti anche dal nome, indipendentemente da maiuscole e posizione della parola Art. Le Art dei vecchi salvataggi restano disponibili: nessuna viene archiviata automaticamente.
- Libri runici: scegli sei parole aggiuntive, rispettando i prerequisiti; le parole obbligatorie restano tali.
- NPC e nemici umanoidi: Nome, Livello, Ruolo, tipo Art, bonus e numero di Titoli del Fato nella stessa finestra. Anteprima statistiche e sottotratti aggiornata col livello. Le creature non umanoidi conservano i preset del Bestiario.
- Nuove Art di ruolo situazionali: evoluzioni ai livelli 0/3/6, Defiled anche 9/12. Costi crescenti 2/5/9/14/20; Martial ed Emblem usano cooldown. Apertura al livello 15, Defiled 20, dopo tutte le Skill alla massima evoluzione. Le Art già salvate non vengono sostituite.
- Art glaciale: Apertura con 1d100 ghiaccio e Gelo III; Buff +5 statistiche finché attiva; Spine glaciali con 1d30, Gelo I su critico dichiarato, cooldown 2 turni. Apertura riutilizzabile dopo 10 turni. Il Master sceglie i bersagli validi, senza colpire automaticamente tutte le schede; senza bersagli locali il risultato viene registrato per la sessione.
- Titoli generati con nomi narrativi distinti e bonus esplicito nell'ottenimento. I titoli esistenti mantengono nomi e dati, modificabili manualmente.
- Risorse: intestazione a larghezza intera, colonne indipendenti senza righe con vuoti enormi. Recupero dell'Art e bonus temporanei hanno intestazioni unite ai rispettivi pannelli.

### Cosa puoi modificare
Nome, livello, grado, difficoltà, statistiche massime e attuali, Vita, Oculum e stile barra/fiamme; immagini manuali; sfondo e sfumature; sottotratti; ruoli, elementi, equipaggiamento e Titoli; nomi, descrizioni, evoluzioni, requisiti testuali, costi, risorse e cooldown delle Art; Apertura, Buff e Skill Open; Art in uso/incorporate e occhi coinvolti; parole runiche aggiuntive; bonus danni e difesa; turni, risorse, condizioni e tutte le precedenti funzioni di diario, inventario e mappe.

I profili normale e Test restano separati. I test automatici non costituiscono una verifica online tra due dispositivi reali.


### Cinque turnistiche
Sotto Tiri e azioni compaiono due pulsanti compatti, Sottotratti e Turnistica, come gli altri comandi. Turnistica apre cinque scontri a tendina. Entrando con la propria scheda in un nuovo scontro, l’iniziativa viene tirata automaticamente; riaprire lo stesso scontro non la ritira. Il contatore mostra round e turno della stessa turnistica del combattimento, anche online. Estendono i gruppi già esistenti: turni, round, partecipanti e ordine sono salvati separatamente nella campagna. Il Master può selezionare uno scontro, aggiungervi PG/NPC/mostri, gestirlo e pubblicarlo. I Player online possono entrare in uno scontro pubblicato; quelli privati non vengono condivisi. Eventuali gruppi oltre i primi cinque restano accessibili nel centro combattimento. Nome e partecipanti sono modificabili nella gestione completa. Strumenti autorizzati: misure e aree VTT, condizioni a durata e Aiuta compagno erano già presenti e sono conservati. Prova di gruppo rimossa su richiesta; nessun nuovo sistema di prove di gruppo.


Verifica: strumenti Supabase Broadcast controllati sulla documentazione ufficiale, senza cambiare SDK o infrastruttura. La verifica fra due dispositivi collegati a Internet rimane da svolgere; i test automatici coprono i percorsi locali e il contenuto dei messaggi.


Verifiche del 1 ottobre: suite completa 617 test superati, 2 test live opzionali saltati perché richiedono ambiente esterno. Catture di widget reali a larghezze desktop e telefono con dati sintetici; le ultime correzioni di layout e alias online sono verificate nuovamente con test mirati. Le modifiche ai titoli generati riguardano solo le nuove schede.

Verifica finale dei menu compatti: 16 test mirati superati, incluse le varianti Windows, macOS e Android, ingresso con iniziativa senza duplicazione, Art e messaggi online. Analisi di tutta lib senza problemi. Il layout telefono è verificato a 320×640 con widget reali e dati sintetici; non è una prova su un dispositivo fisico. Il nome di ciascuno dei cinque scontri è modificabile direttamente nella sua tendina dal Master.


### Ultime correzioni — desktop e mobile
- Categorie compatte centrate, testo allineato al centro.
- Occhi dei Caduti attivi: numero della scheda corrente e accesso alla custodia, escludendo i morti.
- Bonus danno numerico separato dalla difesa, spazio corretto fra i campi; i pulsanti +1/-1 restano disponibili.
- HP Attuali modificabili direttamente anche mentre la barra Vita è visibile; Vita Afona mantiene gli HP nascosti.
- Aggiunta PG/NPC/mostri disponibile negli scontri locali anche da Player; online restano i permessi esistenti.
- Nuovi scontri e riavvio iniziativa da turno zero; i turni dei salvataggi esistenti non vengono azzerati.
- Le pagine di dettaglio si aggiornano dopo l’aggiunta e consentono la navigazione nella gestione dello scontro.
- Anche l’EXE nella radice distribution viene aggiornato insieme al runtime completo.


Verifica dopo le ultime correzioni: 618 test superati, 2 prove live opzionali saltate; analisi lib senza problemi. Il test dell’interfaccia aggiunge realmente un personaggio dalla tendina locale nelle varianti Windows, macOS e Android, controlla HP Attuali con barra visibile e Bonus danno. Catture aggiornate in output/ui/centered-actions-final-20261001.


### Ricerca e ritorno a Generale
- Ctrl+F e Cmd+F funzionano nella scheda e nei dettagli, usando lo stesso catalogo del pulsante Cerca: pagine, funzioni, manuale, Titoli, Skill, Art, inventario e testi già indicizzati.
- Aggiunti i risultati diretti Sottotratti e Turnistica: aprono le relative pagine e tendine.
- Selezionando un risultato da un dettaglio si chiudono le pagine sovrapposte prima di raggiungere la destinazione.
- Corretto il controller della ricerca eliminato troppo presto durante la chiusura.
- Esc o clic/tocco fuori dal riquadro riportano a Generale; i controlli dentro il riquadro continuano a funzionare.
- Verifica aggiuntiva: 3 test di interfaccia completi superati nelle varianti Windows, macOS e Android, includendo Ctrl+F dalla scheda e dai dettagli, apertura del risultato, Esc e clic esterno. Analisi lib senza problemi.


### Iniziativa e Riflessi
- L’iniziativa mantiene il tiro più il bonus Iniziativa della scheda e le regole già presenti per critici e difficoltà.
- A parità di totale precede Riflessi più alto. Con Riflessi uguali resta l’ordine stabile, salvo l’ordinamento manuale del Master.
- Spareggio vinto con Riflessi: 3 × grado × 2 EXP Riflessi (6 × grado), usando la progressione dei sottotratti esistente. Grado 0: zero EXP secondo la formula.
- La ricompensa è memorizzata nella turnistica e non si ripete riordinando, riaprendo o cambiando scontro. I turni extra temporanei non generano ricompense.
- Per partecipanti collegati a schede l’EXP va al sottotratto della scheda; per token senza scheda il totale resta registrato sul token. Le schede online modificate passano dai controlli e dalla coda di invio già presenti; prova reale fra dispositivi ancora da effettuare.


Verifica conclusiva di tutte le ultime modifiche, compresa EXP Riflessi: 618 test superati, 2 test live opzionali saltati. Analisi di tutta lib senza problemi. Le catture desktop e telefono usano widget reali con dati sintetici; non attestano una prova su telefono fisico o una sessione online fra due dispositivi.


### Tutorial, avvio Windows e costi delle Skill
- Il tutorial usa cornice e colori della scheda, una guida compatta alle azioni, turnistica, aiuto compagni, memoria, ricerca e salvataggi. I 9 punti dei sottotratti, massimo 3 ciascuno, restano disponibili anche saltandolo.
- Per le nuove Art iniziali, evoluzioni Skill, Open e Titoli compare [Richiede: ???], da definire con il Master. I poteri e costi dei preset restano conservati; i requisiti già definiti del Monster Book non vengono sostituiti.
- L’EXE Windows parte in modalità desktop al primo avvio e per vecchi dati privi della preferenza. Una scelta esplicita salvata viene rispettata. Gli altri dispositivi mantengono la loro modalità.
- Nelle evoluzioni Art il costo è mostrato prima degli effetti e bonus. Il consumo della risorsa avviene prima dell’applicazione dei bonus.
- Costi dal testo: Costo: (1/10) Oculum; massimo crescita: 20. Sono riconosciuti anche (1/10) prima degli effetti, il precedente costo in fondo e (1/10)oculum. Il testo del giocatore non viene riscritto.
- Le Skill libere leggono il range nel campo Costo o nella descrizione. Le Art lo leggono nel testo della singola evoluzione. I limiti numerici configurati manualmente mantengono la precedenza.
- Massimo crescita: 20 oppure limite maestria: 20 imposta il limite della crescita. Senza limite esplicito resta la soglia della forma successiva, o +10 rispetto al massimo iniziale. La maestria già guadagnata non viene cancellata. L’interruttore Aumento massimo Oculum continua a bloccare la crescita.
- Cose modificabili aggiuntive: requisiti del Master, range Min/Max, risorsa consumata, limite di crescita testuale, crescita attiva/disattiva, testo degli effetti, bonus, cooldown, stile della scheda e modalità desktop. L’elenco delle altre impostazioni è riportato sopra.
- Costo dal testo è selezionabile per ogni evoluzione Art e ogni Forma Skill libera. Attivandolo si leggono i costi senza azzerare il progresso; modificando Min/Max si ritorna alla configurazione manuale. Anche le schede precedenti possono attivarlo.

Verifica finale di tutorial, avvio desktop, riconoscimento automatico costi e selettore Costo dal testo: 621 test superati, 2 test live opzionali saltati; analisi di lib senza problemi. Catture di widget reali con dati sintetici a desktop e 320 pixel, varianti Windows/macOS/Android, in output/ui/cost-automation-release-20261001. Non è una verifica online fra dispositivi fisici.

### Correzioni della turnistica — 1 ottobre 2026
- I comandi di turnistica aggiornano anche le pagine di dettaglio aperte: avanzamento, cambio partecipante, azioni, reazioni e riordino.
- Riordinare l’iniziativa conserva il partecipante già attivo tramite la sua identità, invece di mantenere soltanto la posizione nella lista.
- Reselezionare il partecipante già attivo non gli restituisce gratuitamente azione e reazioni.
- I turni extra creati al round 0 conservano la scadenza 0 e vengono rimossi al passaggio al round successivo.
- Restano modificabili: partecipanti PG/NPC/mostri, nomi dei cinque scontri, iniziativa, ordine manuale, partecipante attivo, avanzamento e reset dei round, azioni, reazioni e turni extra. Le altre impostazioni modificabili sono elencate sopra. Nessun azzeramento degli scontri salvati.

### Note e scelta dell’occhio nei Ricordi
- Seleziona un nodo, scegli **Cambia ruolo**, il nuovo ruolo e aggiungi una **Nota facoltativa**. Conferma salva ruolo e nota; Annulla lascia entrambi invariati.
- Esempio: Quercia Sepolta → Morto, nota **Ucciso da [[Hoshy]] nel [[Luogo:Bosco Nero]].**. La Mappa collega Hoshy al nemico ucciso e il nemico al luogo citato. Sono riconosciuti anche i nomi già conosciuti senza parentesi.
- Le nuove relazioni hanno come fonte cliccabile la nota originale, separata dal Diario. Le note rimangono nella cronologia del ruolo, con data e autore. La riapertura ricostruisce i legami senza duplicarli.
- «Forse ucciso da Hoshy» conserva l’incertezza. La presenza di un personaggio nella nota non lo rende automaticamente l’uccisore. Le frasi che attribuiscono un’uccisione a un altro bersaglio non vengono assegnate al nodo selezionato.
- Le note del Master e le preferenze degli occhi restano personali: i metadati della memoria sono esclusi dalla normale condivisione della scheda. Il comando di comunicazione mirata esistente non diffonde automaticamente queste note.
- **Scegli occhio** cambia l’icona del singolo nodo fra alleato/NPC, nemico/mostro, morto e obliterato. La scelta è grafica e non cambia il ruolo né la storia; **Automatico dal ruolo** ripristina l’icona dello stato corrente. La scelta vale anche nella Costellazione della pagina Storia ed è salvata per scheda.
- I salvataggi precedenti senza note o preferenze degli occhi continuano a usare il comportamento originale. I dettagli coperti da un’altra pagina vengono ricostruiti dallo stato salvato quando si torna indietro; i controlli del turno si adattano anche agli schermi stretti.

### Ritratto della scheda e PNG trasparenti
- Il ritratto in cima alla scheda è cliccabile e apre **Ritratto e Occhio**. Restano disponibili caricamento, trascinamento, appunti, ritaglio, copia e rimozione.
- **Occhio nel ritratto** permette di scegliere l’occhio originale o una delle quattro immagini: alleato, nemico, morto e obliterato. La scelta è salvata nella singola scheda.
- **Mantieni l’occhio dietro il ritratto** mostra o nasconde l’occhio di sfondo. Con un PNG trasparente, l’occhio è visibile attraverso le parti trasparenti soltanto quando l’opzione è attiva. Disattivandola rimane il solo ritratto.
- Anteprima e ritaglio dei PNG con alpha conservano la trasparenza usando PNG; le immagini opache mantengono il percorso JPEG esistente. Il ritratto compatto contiene l’immagine senza tagliarla per riempire il riquadro.
- Per salvataggi precedenti: occhio originale e sfondo attivo, senza modificare o ricodificare le immagini già salvate.

Verifica finale: 626 test superati, 2 test online opzionali saltati; analisi completa di lib senza problemi. Verificati note, attribuzione dell’uccisore e incertezza, ricostruzione dei legami, scelta degli occhi, PNG con alpha, impostazioni del ritratto salvate e ripristinate, turnistica e interfacce Windows/macOS/Android. Le foto in output/ui/oculum-eyes-final-20261001 provengono dai widget reali con dati sintetici; non attestano una sessione online fra dispositivi fisici.
