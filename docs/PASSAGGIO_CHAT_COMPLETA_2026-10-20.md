# Passaggio di consegne — Oculum, 20 ottobre 2026

Questo file accompagna il fork dell'intera conversazione richiesto dall'utente. La cronologia del fork è la fonte per le richieste originali; questo indice NON dichiara che tutto sia implementato. Non usare un vecchio messaggio di successo come prova della versione corrente.

## Ultime richieste, da portare a termine

1. Continuare in una nuova chat mantenendo tutta la cronologia e ogni lavoro rimandato.
2. Home: «Riva d’ambra» diventa «Rame fatato». Già cambiata la label di `amber_shore` in `oculum_reference_campaign.dart`; mantenuto ID e immagine per compatibilità dei salvataggi.
3. Download SOLO WEB: icona classica di download accanto all'icona del computer della barra mostrata nell'ultimo screenshot. Menu a tendina con tutti gli artifact delle ultime build GitHub riuscite, download SENZA LOGIN. La prima implementazione provvisoria è nella scelta iniziale Player/Master: va spostata alla posizione esatta richiesta. Non basta un link agli artifact Actions che richiedono autenticazione.
4. Pubblicazione automatica di TUTTI gli artifact delle Actions di build, con pagina pubblica. Se l'automazione fallisce, completare manualmente. Direttiva già aggiunta ad AGENTS.md.
5. PROVA PRIORITARIA REALE con TRE OCULUM SEPARATI, tutti ONLINE NELLA STESSA TURNISTICA DEL MASTER: uno Master, un attaccante, un difensore; il terzo aiuta la difesa dalla propria scheda. Verificare richiesta difesa, DT, aiuto prima del tiro, esito, condizioni, scudi/HP, log e sincronizzazione. Non confondere tre schede nello stesso processo con tre client indipendenti. Se il terzo/Master deve usare un PG, predisporre una scheda sintetica controllata, senza modificare salvataggi personali.

## Vincoli permanenti

- Repository C:\Oculum App\oculum. Leggere AGENTS.md e regole/manuale prima di interventi di gioco.
- User NON può pagare Supabase. Restare sul piano gratuito, nessun upgrade di compute, piano, IOPS o altra spesa.
- Preservare salvataggi, immagini, diari, JSON personalizzati e offline. Solo scheda attiva condivisa, non archivio privato. Parametri di skill/Art/Open/titoli/oggetti modificabili e persistenti in JSON; avanzate nascoste finché aperte.
- Distribuzione sempre EXE completo runtime, ZIP, APK, Windows e Windows Test anche in cartelle normali. Verificare staging e hash prima della sostituzione; preservare backup, non chiudere app in uso.
- Distinguere test simulati, live Supabase stessa macchina, browser/app reali, CI, pacchetti e sito pubblicato. Non dichiarare l'online perfetto per un test passato.
- L'utente ha chiesto GitHub Actions e artifact DOPO verifiche. Autorizzazione a pubblicare aggiornamento e distribuzione; non pubblicare file privati o output di salvataggi.

## Stato sorgenti al passaggio

- HEAD verificato in precedenza: a49c7c4e987df4b3eea82d6be20de3348b751741 su main. Ricontrollare: utente può fare push autonomamente.
- Numerose modifiche NON COMMITTATE. Non resettarle né sovrascriverle. `git status` comprende anche PDF, benchmark e screenshot rigenerati dai test: separare dagli interventi sorgenti, non pubblicare tutto indiscriminatamente.
- Modifiche correnti: realtime service, turnistica remota/permessi, danni per colpo, parser/editor effetti, aberrazioni, label Oculum nella barra, nuovi test; docs registro e manuale aggiornati. Vedere `git diff`.
- `docs/VERIFICA_ONLINE_2026-10-20.md` descrive evidenze e limiti, da aggiornare con risultati finali.
- Nessun nuovo push, CI della nuova versione o installazione finale pacchetti verificati è stato completato in questo segmento.

## Supabase — evidenze e interventi

- Progetto jgpxdlkbuxhriltxezdc. Plugin Supabase funziona. Solo chiave publishable nel client; niente secret/service_role.
- Outage precedente: DB 57P03, PostgREST PGRST002 schema cache, test stanza falliti per infrastruttura. Successivamente servizi Healthy e accesso/test combattimento riusciti. Non usare i fallimenti come motivo per abbassare RLS o disabilitare test.
- Dashboard Chrome 20 ottobre: CPU scesa da 99 a 81 nel campione, non prova di risoluzione. Quota FREE egress 7,672/5 GB (153%), ciclo 27 settembre–27 ottobre. Database circa188MB/500, realtime circa233k/2M; no query applicative bloccate nel campione SQL. Le statistiche di query includevano introspezione catalogo/Auth lente. Non attribuire tutta la CPU all'app senza misure.
- Migrazione additiva APPLICATA `reduce_oculum_room_io`, locale `supabase/migrations/20261020132707_reduce_oculum_room_io.sql`: indici ultimo evento per tipo, pending memberships, sessioni recenti. EXPLAIN usa indice ultima turnistica. Nessuna cancellazione dati/policy allargata. Verificare allineamento timestamp con history server prima di db push.
- Client: accorpa refresh concorrenti; presenza invariata riscritta ogni15s anziché3/5, variazione scheda immediata, backoff fino60s, presenza prima del replay e prima invio nuova scheda.
- Ultima correzione in corso: guardie `_generation` impediscono risposta tardiva vecchia connessione di modificare quella nuova, inclusa modalità HTTPS con channel null. Future refresh/read azzerate alla disconnessione e chiuse solo dalla propria generazione.
- Player connesso usa snapshot Master e non ripiega sulla turnistica locale in attesa dati; copia locale conservata per offline. Campagna remota verificata da presenza Master o snapshot autorevole.
- Problemi ancora da verificare: snapshot schede persistenti oltre replay5min, conflitti/revisioni, cambio account anonimo/proprietà tag, revoche/accessi; non dichiararli risolti senza test codice/database.

## Test effettivi e test in sospeso

- Auth live `OculumLiveSupabaseTest=true`: passato dopo ripristino.
- Combat live `OculumLiveRealtimeTest=true`, `oculum_combat_live_application_test.dart`: passato in33s con due client Supabase reali autenticati, difesa/danni/cura/aiuto con segno. NON prova UI Windows/Chrome né tre client.
- Realtime simulati:11 passati, incluso reconnect con vecchia risposta presence bloccata, accorpamento10refresh e cambio sheet. Più2 test download puri:13 passati insieme.
- Aberrazioni/penetrazione:3 passati. Nuovo test evidenziava doppia applicazione percentuale agli scudi come danno globale; corretto marcando l'intervallo del parser come già consumato.
- Damage layers: nuovo blocco one-shot e superior revival. Intermittenza test erbe: azzeramento_vulnerabilita casuale attivo sopprime legittimamente malus; fixture ora resetta Stato di Forza prima test erbe, mirato passato.
- `oculum_all_themes_test.dart`: errore Windows1224 su immagine già mappata; ora usa `writeFreshCapture` esistente per conservare cattura nuova con nome diverso. NON ignorare overflow o fallimenti reali.
- Suite completa precedente910 passati5skip1fail(parser poi corretto); successiva909pass5skip2fail(fixture erbe e file bloccato, poi corretti). Una terza suite concurrency2, session34045, procedeva senza fallimenti ma risultato finale NON acquisito. Non dichiararla passata.
- Analyze pulito prima download UI; nuova analyze session83821 finale NON acquisito. Python test publisher3 passati con elevazione. Download UI/servizio nuove parti non ancora verificate completamente.
- Alcune sessioni exec sono divenute Unknown process dopo nuovi messaggi; usare `--file-reporter json:build/...` nei prossimi test per prova durevole. Flutter help conferma flag.
- Vecchie CI di a49c tutte verdi: distribution39409595617, Pages39409595614, Diari39409595625, WindowsTest39409595611, macOS39409595599. Non sono CI delle modifiche attuali.

## Browser e prova multipiattaforma

- Chrome ora accessibile tramite cua. Primo inventario era disabilitato, poi ha mostrato browser2 extension. Dashboard Supabase letta e quota verificata realmente.
- Scheda Oculum preesistente1665263860 non controllabile: timeout focus CDP. Nuova scheda1665264030 caricava sito, Enable accessibility -> Player/Master visibili. Nessuna prova combattimento UI completata.
- Tentativo anteprima localhost8765 non rispondeva; server Python lanciato in tool poi interrotto. Binding read-only default non consentiva socket; elevato poi timeout. Non dichiarare localChrome verificata. Due tentativi Chrome localhost non completati.
- Non usare Playwright esterno/CDP o richieste nascoste aggirando cua; usare API browser documentate. Servizi purpose-built e test Flutter CLI restano utilizzabili.
- Prova crossplatform già esistente `test/oculum_cross_platform_live_test.dart`: richiede CrossPlatformRoom e URL/key; Windows master realtime + Chrome player HTTPS scambiano scheda300k e reconnect, max9min. Non ancora eseguita. Richiesta ultima aggiunge TERZO client aiuto difesa.

## Distribuzione

- Staging recenti incompleti `build/distribution-combat-20261020-162847` e precedenti. Web e Windows di quello staging compilati, ZIP web/windows verificati; WindowsTest in compilazione quando interrotto intenzionalmente dopo nuova correzione service. Sono OBSOLETI rispetto ai sorgenti attuali.
- `build/distribution` precedente non va presentata aggiornata. Non spostare staging parziale o vecchio.
- `scripts/build_combat_distribution.ps1` preserva backup, controlla runtime, ZIP, APK, manifest e fingerprint di tutte sorgenti. Modificato Invoke-FlutterBuild per output diretto ed exit code+log riepilogo, perché redirezione interna risultava bloccata in tool. Può richiedere elevazione.
- `scripts/install_github_distribution.ps1` ora impedisce installare artifact con sorgenti pendenti, preserva backup invece di Remove-Item distribuzione; verifica manifest prima e dopo spostamento. Modifiche recentissime da rivedere/testare prima uso.
- `build/verify_eye_auto_distribution.ps1 -ExpectedCommit` verifica hash, numero file e pacchetti richiesti.

## Download pubblici: implementazione NUOVA non conclusa

- `lib/widgets/oculum_web_downloads.dart`: MenuAnchor soltanto kIsWeb, fetch solo clic, errori con retry, apertura URL tramite url_launcher. IMPORTATO in main e provvisoriamente aggiunto startup. SPOSTARE accanto icona computer (ultimo screenshot), icona download invece testo grande.
- `lib/services/oculum_download_artifacts.dart`: una richiesta pubblica alla release `oculum-downloads`; legge catalogo JSON nel body con marker `<!-- OCULUM_DOWNLOADS:`; accetta solo URL release GitHub Mich369/Oculum atteso con runID e nome artifact sicuro. NO token/Supabase. Due test puri passati.
- `.github/workflows/public_downloads.yml`: workflow_run su build distribution/WindowsTest/macOS/Pages/Diari su main, success trusted repo; dispatch manuale run_id. Concurrency unica, permissions ristrette jobs. NON pubblicato.
- `scripts/publish_github_downloads.py`: scarica archivi artifact senza estrarli/eseguirli, verifica dimensione e sha256 GitHub, carica ZIP in release prerelease per run `oculum-build-<runID>`, aggiorna pagina release centrale `oculum-downloads` conservando ultimo gruppo per workflow. Non sostituisce gruppo se run più vecchia dell'ultima success. Non pubblica build fallite/fork/nomi non sicuri. Usa GH_TOKEN solo env. Serve revisione edge case rerun stessa run, asset2GB, timeout, verifica anonima e pubblicazione reale.
- Python3 test in `scripts/tests/test_publish_github_downloads.py` passati; nessuna release nuova è stata creata ancora.
- Repo pubblico verificato con gh. Artifact vecchia distribution sono8, tot~3,8GB: Android1,016GB, Windows459MB, Test459MB, iOS456MB, web456MB, macOS473MB, UI29MB, Linux456MB. Si possono pubblicare via workflow GitHub per evitare trasporto locale pesante; NON usare Supabase.

## Indice delle richieste storiche da verificare, non dimenticare

Confrontare ogni voce con registro/manuale, codice e test prima di marcarla completata. La cronologia completa del fork contiene formule e conferme dettagliate.

- Multiplayer: Auth ospite protetto/email in impostazioni, mantieni accesso esplicito e multidevice; approvazione Master e RLS backend; scheda attiva con consenso/ACK reale; campagne isolate, coMaster schede turnistica, reconnect, duplicati, concorrenza, protezioni salvataggi, mappe/pedine/turni, unione e separazione fight, finefight/reset/EXP nemico(lvl+stats) intera a tutti.
- Azioni automatiche online e manuali intuitive offline: attacchi/difese/condizioni/resistenze/scudi/scudoOCU/HPtemporanei/larve rosse; aiuto positivo/negativo al tiro scelto e cura party inclusi se stessi; reazioni donate; selezione multipla e ripetuta, residui random ai selezionati. Danno base ripartito per eccesso, bonus +N su ciascun bersaglio. Skill multiuso in tutti pannelli pertinenti, utility per ogni buff/debuff/evocazione; scroll inventario connesse; Open e titoli parser+effetti editabili, requisiti/cooldown/costi nascondono abilità inutilizzabili ma sottotratti restano tiri sempre utilizzabili.
- Osservazione: Percezione/Investigazione/Furbizia/Valutazione migliore, libera o bersaglio; soglia >=lvl+Velo esatta e probabilità; fallimentoentro5 approssima sottraendo scarto stessoGrado, oltre nonabbastanza; crit punto debole SemiLetale alleati finofinefight. Log Nome | Titolo se nickvuoto e richieste difesa DTnemico visibili al difensore.
- Sottotratti: Strategia+5 att/dif +2peraiuto; Concentrazione10 utility nat>10 +10%danno/+12%dif prossimaazione; Adattamento10 nat>10 riduzione1+totale-10 prossimodanno; Velo6 contestopercezione; Manifestazione6 +3×lvl; Precisione6 80/15/5 fragilità1/2/3 capLetale, cresce15 fino50/45/5 poi verso50/40/10; Precisione20 5%speciale separato260–350% sottratto+1; Riflessi6 crit reazione se movimento nemico<=PG,12 nat19/20 e20 nat18/19/20 senzalimite; Schianto10 saltazione no reazione persa, non contro2gradioltre; altre meccaniche delegate logiche tranneVC. Maestria soglie confermate in registro.
- Elementi semprevisibili att/dif, interazioni25%, buio>luce, sole>luna; angelico/demoniaco resistenzareciproca fino30%HP; crit aumento danno+fragilità elemento subito. MiniBoss primaelemento +3%fino60, bossognielemento+6fino75.
- Mostri: costrutto rinsecchito/larva grado0/1 e skill tutteforme; RicordoVitale1OCU/turno durataOCU, cuore90%HP+1d9ricordo. Nidiata barraHP rossa numero larve,20natapprendimento e scrollmoltorara, forme scroll I–IX formule nelregistro. Boss clown Collezionista elementi, martello scalamenti/risorse/danno+base specificati in cronologia. Aberrazioni minore2fasi/intermedia2/miniboss/maggiore2boss/superiore3boss, Solareglasscannon Angelicaequilibrata+stats;50%sogliastessabarra e superrevive75%+2lvl. Pool tecniche multi, penetrazioneCD2–5/CD2scarica iniziofight; colpo resetta oltre dif/scudi/bonus%scudo.
- Evocazioni: OcchiCaduti aggiungono vera scheda+turnistica del Master; parser cloneombra stats10HP durataOCU; scroll OmbraViva5×lvlHP noRES copiata, durata2grado+3; supportoutility; emblemaslime120HP3bersagli+self+3allstats/+2sottotratti duratafight prezzo200>Paw100, personalizzabile.
- Inventario/mercanti: livelli equip1–3stats/lvl, skillunica usabile da lvlitem, gradoalto nonacquisto/equip; Fabbro dadoriflessi/frazioni/altrisottotratti ai danni conlivello; minimi50+70grado (III260). Filtri Mastergrado/categoria. Prezzi±5,3%+25%/1%-15% nascosto. AlchimistaVitaliumleggeromeno/materialmerchant; dust33–69fino3 soloalchimista; piccoli pet rigeneranti/scrollgrado; erbe30–50 VOL6MAT4 3turni/2brevi/1lungopoiConfuso-20%DT2 2turniocura/riposo. SegnoFato50–120 unico shop70/20/10->30/40/30; Chaos3%shop60–120ogni10Obser stats1/2/3/0 con75/13/9/3%. Cibi1–120buffminorI–VIstats% e mostrofoodskill0,5%+Fortunapunti.
- Titoli: base6,gradoIII7/VI8/IX9; apprendimentounosubito+1grado/Rebirthprimi3evolutifree; forme1skill1,2skill2,3skill3 slot; Fateprimi3dungeon slot3,EXP2poisaturato3, Masterstart; malannoRES/6forzati; benesserefree temporanei; AlchimiaRebirthslotusabilegrado0,maxalmeno1; Chaoskarma-10. Attributi/parole/leggende/karma/cicli/limiti/lotta/dadi come regole in docs. Riserva stats ceil(lvl/4) unavoltasoglie5/15/25/50/100/200.
- Cartelle: schede sinistra e reputazioni sottocartelle illimitate, rinomina/sposta/longpress; preservarearchivio. Ricordare esplicitamente mostri e cartelle dopo online.
- UI/art: temi Oculum gotici leggibili nonintasati, effetti occhi suiventmouse/player/antimouseMaster; primarysoloocchi nonillustrazioni, Homeimmaginiselezionabili; editorlayer multipli immagini condivisibili mai bloccoinput, RGBplus VOL/MAT/RES/OCU, profiloocchio piùrettangolare/largo; immaginiCanvaAI dita da correggere specifica, terza Soleconisole; FigmaCanvaGameStudio quando utili, distinguere pluginautorizzati/disponibili. Nuova labelRameFatato e downloadaccantocomputer sono istruzioni piùrecenti.
- Vecchia automazione completa-distribuzione-oculum: utente chiese rimozione se ancoraquellavecchia; verificare stato automazione prima di lasciare notifiche vecchicommit. Non rimetterla attiva automaticamente.

## Richieste successive da portare nel medesimo arretrato — 22 ottobre 2026

Queste richieste arrivano dopo il primo indice. Sono tutte da confrontare con il codice attuale e con test mirati; la presenza di modifiche nel working tree non prova che siano concluse. L'ordine resta: online e consegna al Master, poi turnistica/combattimento, poi contenuti e distribuzione.

### Priorità online e turnistica

- Le schede selezionate dai player devono arrivare davvero al Master, comprese evocazioni e Occhi dei Caduti attivi. Copie ricevute in una cartella `online` separata, in fondo a cartelle e schede; identità stabile usando account se disponibile, altrimenti titolo visibile, senza duplicati se account o titolo cambia. Aggiornamento un secondo dopo aver finito una modifica, all'apertura/sincronizzazione e periodicamente, senza carico inutile su Supabase.
- Ogni richiesta che richiede approvazione deve comparire al Master. L'approvazione del Master serve solo per nuovi partecipanti, non per le azioni ordinarie dei giocatori.
- Verificare su Windows normale e Windows Test ricezione schede e turnistica Master; preservare sessioni/Auth indipendenti e permettere al browser di entrare online mentre il desktop è connesso. Le prove con client Auth o test locali non sostituiscono il controllo delle app reali.
- Turnistica automatica: ogni azione fa avanzare il conteggio; una reazione non cambia il personaggio di turno (se tocca a Luca e Giulio reagisce, resta Luca). Loggare il turno corrente e le azioni/reazioni usate; mostrare `A`, `R`, `RV`, tooltip con il conteggio usato e residui nella scheda/mini-turnistica. Primo round: tutti hanno un'Azione e una Reazione veloce; dai round successivi, Reazione veloce a inizio round e Reazione normale al proprio turno. Difesa ordinaria iniziale senza consumo; una difesa fallita può avere al massimo un secondo tentativo per quell'attacco. Reazioni inutilizzate danno +3 al tiro successivo ciascuna, massimo +12, e le residue vengono eliminate quando si rinnova la relativa riserva; le reazioni contro mostri possono servire anche per utility.
- Chiudere verifica end-fight basata sui mostri presenti nella turnistica: tiri drop a fine fight, EXP per ogni creatura sconfitta, Occhi dei Caduti e tutte le creature che ciascun Occhio contiene; supportare più creature e distribuirne correttamente ricompense/EXP.
- Eseguire la prova richiesta con quattro profili isolati (Master, attaccante, difensore, compagno): azione, reazione, azione e reazione nello stesso turno, aiuto prima della difesa, attacco/difesa, richieste duplicate, turni e log. Distinguere test simulati, live backend e prova manuale multi-app.

### Contenuti e regole successive

- Concludere e verificare Sputo Acido come condizione elementale con danni nel tempo e durata per difficoltà; Golem Runico con passive gratuite scalabili, riflessione, malus Difesa, bonus CM e Open multi-bersaglio; Goblin Kamikaze con sola esplosione dopo CD 2, danno pari alla Vita massima a tutti gli avversari, danneggiamento Scudo 150% e morte. Parametri nuovi devono restare modificabili e non sovrascrivere JSON personalizzati.
- Aggiungere Invisibilità (+18 + livello Velo) e Trasparenza (+6 + livello Velo), controllandone parser, effetti, log e condizioni.
- Finire doppio critico e contabilità danni, inclusi danni agli scudi, fragilità, doppia difesa e Medicina secondo il registro delle regole confermate.
- Corruzione: Pergamena Nera di attacco, solo Mercato Nero e prezzo alto; possibilità iniziale 100%, −20 punti per ogni Grado sopra la scroll, fino a zero. Skill passiva Padrone della Corruzione: +50 punti percentuali alla resistenza già presente (conferma del 22 ottobre) e contagio al colpo pieno contro mostri di livello maggiore, senza successi parziali; CD iniziale dal principio dello scontro e contatore in secondi a 6 secondi per turno; sul mostro corrotto il proprietario sceglie il bersaglio nel 90% degli attacchi. La skill deve restare una sola forma. Verificare la selezione del bersaglio e il flusso realtime, non solo la condizione locale.
- Negozi: Raccoglitore (Grado 0/XII, fino al doppio dei materiali di grado pari/inferiore); Mercato Nero con Art/skill soprattutto Oculum, scroll meno rare, armi di mostri, massimo 3 Ascension Dust a prezzi crescenti e Occhi dei Caduti con creature multiple di livello/statistiche appropriate. Aggiungere Infermiera Eroica, cura e Refull, rimozione debuff, prezzi/buff casuali per apertura shop e probabilità HP temporanei/scudo concordate; non duplicare offerte equivalenti nella stessa sessione del Mercato Nero. Aggiungere opzioni acquistabili anche per livello 0.
- Concludere la scroll **Reazione Fulminea**: utility, reazione veloce a tutti i bersagli scelti, bonus alla prossima azione pari a Grado ×6 (Grado 0: +1), apprendimento non automatico e possibile bonus di apprendimento in battaglia; item combat nei pannelli Attacco/Difesa/Utility solo in quello coerente con la funzione. Skill appresa con CD 1, costo Reazione o Azione nel proprio turno, nessuna auto-selezione, 6% di non spendere la risorsa con log «Provi Gratitudine».
- Campagne: spostare schede tra campagne e creare una campagna nuova dalla stessa funzione, preservando copie originali e dati. Rifinire tutto nel tema Oculum e per desktop, tablet e telefono.

### Distribuzione e criterio di chiusura

- Prima delle build di distribuzione completare gli interventi e i controlli necessari; eseguire build solo se serve a un test o dopo le modifiche complete. Poi preparare `build/distribution` con EXE completo del runtime, ZIP e APK e mantenere Windows/Windows Test nelle cartelle normali, sostituendo i pacchetti solo dopo verifica.
- Verificare CI GitHub, pubblicazione di tutti gli artifact delle build riuscite e download pubblici anonimi dalla pagina/menu Web. Questi risultati sono separati dai test locali e dalle prove online reali; non caricare salvataggi o file privati e non usare traffico Supabase per il menu download.
- Finché ogni voce non ha test appropriati e, quando richiesta, verifica Windows/browser o pubblicazione, va riportata come aperta o parzialmente verificata. Restare sul piano Supabase gratuito e preferire test locali mirati per limitare il carico.

## Procedura consigliata al successore

1. Leggere questo file, AGENTS, registro/manuale e diff. Non ricominciare da zero.
2. Completare downloadtoolbar+publisher+test/validazione workflow; documentare chiaro no-login.
3. Eseguire prova3client nella stessaturnistica. Se toolindisponibili spiegare limite concretamente, senza chiedere ripetutamente permessi giàautorizzati.
4. Analyze e suite tutte con file-report finale; testlive selettivi, limitaretrafficoFREE. Correggere regressioni dimostrate.
5. Commit/push sorgenti mirati, Actions percommit, attenderesuccess, pubblicazioneartifactanonima, verifica sito e downloadanonimo, distribuzione locale verificata+backup. Noninstallarepacchettivecchi suHEADnuovo.
6. Tornare all'indice arretrati e verificare senza dichiarazioni generiche «fatto tutto».
