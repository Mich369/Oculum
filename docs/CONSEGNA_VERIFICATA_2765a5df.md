# Consegna verificata 2765a5df — 2 novembre 2026

La patch compilata è `2765a5dff2b2c1893a323612049aa71ff27df514`, [run 41373092302](https://github.com/Mich369/Oculum/actions/runs/41373092302). È pubblicata e installata in `C:\Oculum App\oculum\build\distribution`. Questo rapporto registra le prove successive alla compilazione: non cambia il log incorporato nei pacchetti e non approva al 100% le righe del registro.

## Contenuto consegnato

- **23 temi completi, 69 PNG canonici esatti:** desktop, telefono e reliquia. Comprendono i 19 set votati e Golem Runico, Goblin Kamikaze, Diavolo Obliterato e Zombie dello Sbocco Acido. Conservate le tre revisioni di scala approvate.
- **Golem Runico:** prima si rompono le piastre del torace, poi si può mirare al nucleo. Integrità iniziale pari al 35% della Vita massima, minimo 3, modificabile; il colpo danneggia il corpo una sola volta. La pagina del Book non espone automaticamente il nucleo.
- **Anatomia e bersagli:** completate sette famiglie, corrette parti e materiali e mantenuti punti deboli specifici. Il riconoscimento non crea più ali, braccia, antenne o organi da frammenti di altre parole. I dati personalizzati del Master hanno la precedenza.
- **Aggiornamenti:** APK e AAB pubblicati separatamente; il riconoscimento dell'APK resta compatibile con il nome storico. Windows normale e Windows Test conservano cartelle e ZIP distinti. Firma Android e verifica macOS rese più affidabili senza eliminare i test.

La precedente distribuzione è conservata in `C:\Oculum App\oculum\build\distribution-backup-f86951cb-20261102-035410572`. Backup del profilo: `C:\Oculum App\oculum\build\startup-save-backup-41373092302-20261102-035302553`. Nessun salvataggio è stato ripristinato o sovrascritto.

La pulizia verificata ha rimosso 11.609.882.715 byte logici di cache, download invalidi e duplicati dimostrati: [criteri ed evidenze](PULIZIA_VERIFICATA_2026-11-02.md). Conservati file unici, versioni precedenti e personalizzazioni.

## Verifiche distinte

| Ambito | Risultato verificato | Limite della prova |
|---|---|---|
| Test locali | Gruppi da 211, 118 e 41 test; 34 Python; 11 Flutter per download/aggiornamento; 4 del log versione; analisi pulita. | I gruppi si sovrappongono: non sommare i conteggi. |
| CI coordinata | **2250 passati, 6 saltati**, tutti i 9 job riusciti. | Esito del commit indicato, non di revisioni successive. |
| Online autenticato | **4 prove passate** per trasporto e combattimento, separate dalla suite ordinaria. | Nessuna nuova prova completa su tre dispositivi fisici. |
| Download pubblici | **12 archivi senza login** dalla pagina download/menu Web; dimensioni e digest allineati fra CI, Release immutabile e catalogo. | Ricomputati integralmente gli SHA dei tre archivi scaricati localmente; per gli altri verificati metadati e accesso anonimo. |
| Web | Commit verificato in index/bootstrap/main.js e 69 PNG verificati per SHA. | Non equivale a una nuova sessione completa di gioco nel browser. |
| Pacchetti installati | **16639 file senza differenze**, EXE completo, cartelle e ZIP normale/Test, APK. **594 confronti artwork**, 6 log e 112 file sorgente congelati verificati. | Controllo dei file e degli archivi. |
| Android | APK firmato, package invariato, versionCode **100271**. | Verifica del pacchetto; nessuna installazione nuova su un telefono fisico. |
| Avvio Windows | Normale e Test attivi per 8 secondi; **62 file** del profilo salvati, **0 modificati**. Chiusi soltanto i processi avviati dalla prova. | Controlli grafici non ispezionati in questa prova. |
| macOS indipendente | [Run 41373092247](https://github.com/Mich369/Oculum/actions/runs/41373092247) riuscito, stessa suite 2.250/6; ZIP e checksum pubblici verificati senza login. | Non sono ulteriori casi unici, né un'installazione su Mac fisico. Provenienza verificata tramite checkout/run; il workflow separato non incorpora ancora il campo OculumSourceCommit, presente invece nel macOS coordinato. |

Certificato Android SHA-256: `f883a37f4be2b4f038bac52c9e247021e2bb9dd2a9fe45e857b8f5572e40b876`.

[Release immutabile](https://github.com/Mich369/Oculum/releases/tag/oculum-build-41373092302) · [Canale download](https://github.com/Mich369/Oculum/releases/tag/oculum-downloads) · [Versione Web](https://mich369.github.io/Oculum/).

## Righe complete da approvare

Ogni riga resta **in attesa della tua conferma**, anche se implementazione e consegna hanno superato le verifiche.

| Riga | Adattamento consegnato | Prove pertinenti |
|---|---|---|
| **ART47 — Collegare Golem Runico E2, telefono v2 e reliquia v2; rompere prima le piastre per mirare al nucleo.** | Tre PNG esatti; integrità separata 35%/minimo 3; bersagli locali/pubblici, salvataggi e ricevute idempotenti. | 14 test iniziali piastre/scatola e gruppo finale da 41, compresa la regressione contro il torace debole. |
| **ART48 — Collegare Goblin Kamikaze A2 e derivati approvati senza nuovi poteri.** | Tre PNG esatti; innesco specifico nel ventre. | Gruppo da 211 test grafici/anatomici e CI finale. |
| **ART49 — Collegare i 19 set votati più i quattro precedenti: 23 specie/69 immagini; revisioni di Robot, RockShield e Golem di nuvole.** | Immagini canoniche esatte, telefono intero, reliquie trasparenti e controlli sottostanti cliccabili. | 211 test e 594 confronti nei pacchetti, comprendenti anche set precedenti. Le righe si sovrappongono: non sommare. |
| **BUG50 — Riconoscere parole anatomiche vere senza ali/braccia da frammenti.** | Partono, umano, manopola e palato non creano parti o fragilità; personalizzazioni conservate. | 13 test iniziali e regressioni finali. |
| **BUG51 — Rendere pubblici tutti i pacchetti riusciti preservando gli aggiornamenti dalle versioni precedenti.** | APK storico e AAB separati; updater compatibile anche se AAB compare prima. | 14 test Python publisher, 11 Flutter download/updater; 12 archivi pubblici verificati. |
| **BUG52 — Rivedere anatomia e punti colpibili dai disegni, cercando anche bug meno probabili.** | Sette famiglie completate, punti deboli precisi, parole intere e priorità dei dati Master. | 41 test locali, analisi pulita in 50,4 secondi, CI finale riuscita. |
| **BUG53/BUG54 — Rendere affidabili firma Android e verifiche macOS senza perdere controlli.** | Ambiente comune per APK/AAB, copie dopo entrambe le build, heap CI 6 GB/due worker, errori bloccanti; macOS separato 90 minuti/concorrenza 2. | 34 Python complessivi; CI coordinata e macOS indipendente riusciti con suite intera. La causa precisa del vecchio errore AAB non è stata dimostrata. |
| **QA46 — Distribuire il commit verificato con EXE completo, Windows/Test separati, ZIP, APK, backup e download pubblici allineati.** | Consegna del commit indicato, versione precedente e profilo conservati. | 2250 test/6 saltati, 4 autenticati, 16639 file corretti, APK 100271, 12 download anonimi e sito dello stesso commit; avvio di 8 secondi distinto dalle prove UI. |

## Immagini nuove e domande raccolte

**108 proposte per 18 creature**, sei alternative A–F ciascuna, tutte da votare nella [galleria completa](../output/artwork/proposte_sei_notte_2026-11-01/GALLERIA.html). Originali, revisioni e provenienza conservati; nessuna integrazione automatica nel gioco.

Sono Cinghiale del Fango, Uomo Cactus Assetato, Coniglio Prestigiatore, Teschio di Fulmine, Medusa di Vetro, Ragno degli Obser Falsi, Slime Blu, Tempesta Sorridente, Scarabeo Ferrigno, Lucertola d'Ambra, Lince della Brina, Razza delle Rovine, Lepre di Zucchero Filato, Pipistrello Risonante, Corvo delle Valanghe, Carpa Lanterna, Bringi e Feralis Ancestrale. Controlli PNG/SHA superati per tutti i 108 file. Questo non significa che l'intero catalogo abbia già tutti i temi.

Le domande anatomiche su Nuvì, Patalpa, Mimic, Slime Roccioso, Cervo Candela e RockShield sono in [DOMANDE_RACCOLTE.md](../output/artwork/proposte_sei_notte_2026-11-01/DOMANDE_RACCOLTE.md). Resta da allineare il campo identificativo nel solo workflow macOS indipendente; il pacchetto macOS coordinato già pubblicato lo incorpora. Questa osservazione non modifica i pacchetti congelati.

## Tutto ciò che resta modificabile

- Temi e reliquie selezionati, colori e trasparenze.
- Descrizioni, statistiche, anatomia, parti colpibili, loro Vita/integrità e materiali, punti deboli e resistenze.
- Skill, Art e Open; forme, costi, formule, risorse, bersagli, elementi, durata e cooldown.
- Oggetti ed effetti associati.

Gli editor e il JSON esistenti conservano queste scelte. Il catalogo non riscrive le personalizzazioni salvate e le decorazioni non aggiungono poteri o drop.

## Storia delle verifiche

Il run d3bd477e era riuscito, ma la pubblicazione aveva rifiutato Android oltre 2 GiB senza promuovere pacchetti. Il run c0195380 è stato annullato intenzionalmente per includere BUG52. Il run 41364016022/bc4811b7 aveva superato 2.250 test/6 saltati e 4 autenticati, ma la firma AAB era fallita due volte: non è stato distribuito. Due diagnosi isolate sullo stesso codice/certificato sono riuscite; la causa iniziale non è dimostrata. La pipeline finale è riuscita realmente e non converte errori in successi. Il vecchio macOS indipendente si era fermato a 45 minuti; quello finale è riuscito con il limite esteso, mantenendo i test.
