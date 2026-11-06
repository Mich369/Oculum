# Consegna verificata — 5f89ea2b, 6 novembre 2026

La patch del lotto scelto, dei quattro ritiri e del Gigante Massiccio è pubblicata e installata. La fonte realmente compilata è `5f89ea2b6f48cd4d17eb5da3d87fc62db87747d0`, build coordinata 273, [run 42206168903](https://github.com/Mich369/Oculum/actions/runs/42206168903). Questo rapporto successivo alla compilazione registra le prove; non cambia la fonte dei pacchetti.

Il Gigante Comune conserva B; la variante Gigante Massiccio usa C e un bilanciamento più robusto delegato dall’utente. Alla creazione ordinaria verificata, livello 6 e Grado 0: RES 50 / VOL 25 / MAT 21 / OCU 19, Vita 500. Le basi di catalogo sono 18 / 10 / 10 / 5: la crescita ordinaria resta separata. Il Comune a livello 4 mantiene 34 / 18 / 15 / 14 e Vita 340. Il bonus della famiglia si aggiunge correttamente a ogni bersaglio dopo la divisione del danno base.

Sono collegati 36 desktop nativi scelti; 37 PNG sono conservati nei pacchetti senza ricompressione. Il Guardiano dei Dodici Rintocchi A resta sospeso dal collegamento, in attesa della decisione sulle dieci campane visibili rispetto alle dodici del catalogo. Il telefono usa il fallback esistente con desktop intero: questa consegna non dichiara nuove immagini telefono o reliquie native. Immagini e preferenze personali hanno precedenza.

Ritirate dalle nuove selezioni e dal manuale attivo le quattro famiglie richieste: Ragno dei Fili Giurati, Rondine del Respiro Lieve, Viandante dei Ricordi Spenti, Lepre del Fiato di Vetro. Schede salvate, personalizzazioni, lookup legacy e sorgenti degli Occhi restano compatibili. Corretti anche il doppio livello delle decorazioni personali, il refresh cached dei ritiri e l’exporter del manuale con titoli su più righe. [Modifiche e parametri personalizzabili](PATCH_2026-11-06_LOTTO_GIGANTE_RITIRI.md).

## Verifiche distinte

| Ambito | Risultato verificato |
|---|---|
| Fonte locale | 103 test Flutter distinti passati; analisi completa pulita; 21 test Python; manuale riesportato in 82 sezioni |
| Riesame indipendente | Nessuna nuova regressione individuata nel diff 641ec7ed → 5f89ea2b; riesame statico, senza ripetere test o attestare l’interfaccia |
| CI coordinata | 9/9 job riusciti; 2.294 test passati, 6 saltati; analisi senza problemi |
| Online autenticato | 4 prove automatizzate passate separatamente; non tre dispositivi fisici |
| Artifact | Tutti i 12 artifact acquisiti con controllo dei digest SHA256 e fonte compilata |
| Staging e installazione | 16.913 file, zero differenze in entrambi i controlli; 16.912 payload più il manifest |
| Versione precedente | Backup 641ec7ed conservato e ricontrollato: 16.803 file, zero differenze |
| Immagini nei pacchetti | 407/407 confronti esatti dei 37 PNG su 11 destinazioni: tre runtime e otto archivi |
| Windows | Normale e Test separati, cartelle complete con runtime; 5.591 file standalone confrontati, `app.so` distinti |
| Android | APK 100273, `com.mich.oculum`, firma verificata e certificato identico alla versione 100272; copia installata nel pacchetto identica all’APK firmato verificato prima dello swap |
| Avvio locale | EXE normale e Test vivi dopo otto secondi ciascuno; terminati soltanto i processi avviati dalla prova |
| Profilo | 62 file salvati nel backup preventivo, nessun file preesistente cambiato durante la prova di avvio; nessun ripristino sovrascrivente |
| Pubblicazione | Publisher 42212911695 riuscito; 12 download senza login con header ZIP e dimensioni coerenti, digest API/catalogo/release concordi |
| Web | Pages 42212911747 riuscito; `index.html`, `flutter_bootstrap.js` e `main.dart.js` pubblici verificati con il commit 5f89ea2b |

Il controllo anonimo dei download non ha ricalcolato l’hash dell’intero payload pubblico; l’acquisizione locale degli artifact ha invece verificato i digest completi. Le tre risorse web sono state lette integralmente. Non è stata svolta una nuova prova completa dei controlli grafici o dei clic del menu download, né una prova su tre dispositivi fisici. L’archivio iOS resta unsigned; nessuna installazione iOS è dichiarata. Il confronto dei PNG certifica i byte, mentre mapping e personalizzazioni hanno le proprie prove nella fonte.

## Pacchetti e ricevute

Distribuzione locale: `C:\Oculum App\oculum\build\distribution`, con EXE completo, ZIP e APK; Windows normale in `windows`, Test in `windows-test`. Backup precedente: `build/distribution-backup-42206168903-20261106-133736127`.

[Download pubblici della build](https://github.com/Mich369/Oculum/releases/tag/oculum-build-42206168903) · [Canale download](https://github.com/Mich369/Oculum/releases/tag/oculum-downloads) · [App web](https://mich369.github.io/Oculum/).

Ricevute locali, conservate in `build` e non presentate come file pubblicati nel repository:

- `RELEASE_5f89ea2b_42206168903_PROGRESS.json`: esito completo di CI, acquisizione, installazione e controlli separati.
- `ci42206168903-analyze-and-test.log`, `ci42206168903-artifact-inventory.json`, `install-5f89ea2b-42206168903.log`.
- `verified-37-artworks-5f89ea2b-installed.json`, `postinstall-runtime-5f89ea2b-42206168903.json`, `android-signing-5f89ea2b-42206168903-preswap.json`.
- `startup-smoke-5f89ea2b-42206168903-20261106-134742986.json`, `verify-backup641-after-5f89ea2b.log`.
- `publication-5f89ea2b-42206168903.json`, `pages-5f89ea2b-42212911747.json`, `FINAL_SOURCE_STATIC_AUDIT_5f89ea2b_20261106.json`.

## Lavoro artistico successivo, non incluso nei pacchetti

Snapshot locale del 6 novembre: 89 ID con una C generata, 110 PNG comprese revisioni e scarti conservati; 33 mostri ancora senza scelta nella galleria A/B/C, per 99 confronti. Dodici C raw attendono ancora controllo o rifinitura; 975 voci della coda non hanno ancora una C. Gli originali sono su G; i canoni già scelti e i ritiri sono esclusi dal nuovo voto. Le nuove C non ricevono un’approvazione automatica e non sono state aggiunte alla build 5f89ea2b.

Archivista e Antico hanno nuove revisioni per margini e leggibilità degli arti, mentre Lacrimante C v1 è stato mantenuto dopo verifica delle due braccia collegate. Corretti anche quattro nomi di metadati con doppio punto, mediante rinomina a SHA invariato; il primo tentativo di aggiornamento della galleria era fallito senza sostituire il vecchio HTML. La galleria finale è stata rigenerata con 33 voci e hash delle immagini verificati, senza nuova prova browser o widget reali.

**Stato della riga CAT06 / ART06:** consegna verificata, in attesa della conferma dell’utente richiesta dal registro; non segnata al 100%. I voti artistici precedenti restano validi, mentre le proposte nuove e il chiarimento del Guardiano rimangono separati.
