# Consegna verificata f86951cb — Meccanio e FireShield

Commit compilato **f86951cb9f6e30914e2404f02b0ad226286eab87**, [CI 41286042480](https://github.com/Mich369/Oculum/actions/runs/41286042480). Documento di evidenza successivo alla compilazione: non modifica il log già incluso nei pacchetti.

## Righe approvate al 100% dall’utente — 1 novembre

Risposte esplicite: «Sì, ART45 conclusa», «Sì, ART46 conclusa», «Sì, BUG49 conclusa» e «Sì, QA45 consegna conclusa». La chiusura riguarda le righe e le prove qui descritte; non estende l’approvazione ad altri artwork o a nuove prove fisiche. Ricevuta: [CONFERME_CHIUSURA_f86951cb.json](CONFERME_CHIUSURA_f86951cb.json).

| Riga | Richiesta e adattamento completo | Evidenze e stato |
|---|---|---|
| ART45 | Collegare i tre temi canonici Meccanio: F2 Carbone e rame, Malconcio A2 Latta rientrata, Primitivo C2 Nodulo antico; desktop e sei derivati approvati. Nove PNG identici agli originali, composizione intera su telefono e reliquie decorative senza nuovi poteri/drop; nessuna sovrascrittura delle immagini salvate. | 87 test del gruppo misto e 15 prove sfondi/pagine acquistate passati, gruppi sovrapposti. 54 copie di questi nove file verificate nei tre runtime, due ZIP e APK; comprese nei 180 confronti complessivi. Pubblicati e installati. **100% approvato: «Sì, ART45 conclusa».** |
| ART46 | Collegare FireShield C2: circa 5 metri, due braccia e due zampe; telefono v1 e reliquia v2 con soltanto la testa, tutti esplicitamente canonici. Tre PNG esatti, poteri/valori conservati, BlackDragonShield e altre specie invariati. | 20 test finali pacchetti/anatomia e 5 prove sfondo/pagina FireShield passati, conteggi sovrapposti. 18 copie dei tre file verificate nei pacchetti, comprese nei 180 confronti; margine visibile della reliquia 16,9%, residui alpha1 conservati. Pubblicati e installati. **100% approvato: «Sì, ART46 conclusa».** |
| BUG49 | Correggere ali spurie da parole come scanalata, singolare occhio/lente interpretato come coppia, radici dell’habitat scambiate per organi e Scostubanditi/Granscostumato Empatici classificati Robot. Conservare veri organi vegetali, altri robot e parti personalizzate salvate dal Master. | 62 regressioni mirate passate, più suite CI completa riuscita. Correzioni presenti nei pacchetti pubblicati e installati. **100% approvato: «Sì, BUG49 conclusa».** |
| QA45 | Distribuire il commit verificato con EXE completo, Windows normale/Test in cartelle e ZIP separati, APK firmato, backup precedente e download pubblici allineati. Conservare log cumulativo e dati. | CI: 2.040 test passati, 6 saltati e 4 prove online autenticate separate; analisi pulita. 16.554 file installati, nessuna differenza; APK100267 firmato; 180 confronti immagini, 6 log coerenti e 11 download anonimi verificati. Nessun avvio nativo/nuova prova su tre dispositivi fisici dichiarato. **100% della consegna approvato: «Sì, QA45 consegna conclusa».** |

## Distribuzione locale e backup

- [EXE Windows con runtime](../build/distribution/windows/oculum.exe); copia completa anche nella radice `build/distribution`.
- [Windows ZIP](../build/distribution/Oculum-Windows.zip).
- [Windows Test ZIP](../build/distribution/Oculum-Test-Windows.zip) e cartella `build/distribution/windows-test` separati; payload `app.so` diverso, profilo di test isolato.
- [APK Android](../build/distribution/Oculum-Android-release.apk): package `com.mich.oculum`, versione **100267**, certificato `f883a37f4be2b4f038bac52c9e247021e2bb9dd2a9fe45e857b8f5572e40b876`.
- Backup integrale: `C:\Oculum App\oculum\build\distribution-backup-41286042480-20261101-100851151`.
- Verifica prima e dopo la sostituzione: **16,554 file, 0 differenze**. Il primo tentativo si è fermato con l’app aperta, il secondo con Esplora file nella cartella. Dopo la chiusura confermata dell’app è stata spostata solo quella finestra alla cartella padre, senza chiuderla; sostituzione con rollback e backup riuscita. Nessuna app avviata per consumare il primo avvio della versione.
- Eliminato soltanto l’AAB intermedio di questo download, già presente nell’archivio pubblico; APK, originali artwork, salvataggi e distribuzioni precedenti conservati. Audit `build/four-packs-unretained-aab.json`.

## CI, pubblicazione e limiti delle prove

- Coordinata Windows normale/Test, Android APK/AAB, macOS, iOS unsigned, Linux e web riuscita. Il primo tentativo di firma AAB è fallito; il solo job Android ripetuto sullo stesso commit è riuscito. La causa interna del primo errore non è stata stabilita.
- Un precedente run9e4d4123 si è fermato a 2.039 test passati/1 fallito/6 saltati. Corretta esclusivamente la fixture casuale del contrattacco; nessuna regola del motore cambiata. I 10 test correlati e tre ripetizioni locali sono passati prima della nuova CI.
- [Download pubblici](https://github.com/Mich369/Oculum/releases/tag/oculum-downloads) e [release immutabile](https://github.com/Mich369/Oculum/releases/tag/oculum-build-41286042480): 11 archivi accessibili senza autenticazione, origine e digest artifact/release concordanti. Questa verifica non ha riscaricato integralmente tutti gli 11 archivi remoti; gli archivi necessari all’installazione locale sono stati scaricati e verificati per SHA.
- Pages e publisher riusciti; verificati commit effettivo di index/bootstrap/main.dart.js e hash di 10 desktop canonici pubblicati. Non è una nuova prova grafica indipendente su tre dispositivi.
- **180 copie artwork** identiche: 30 PNG canonici (18 precedenti +12 nuovi) in tre runtime, due ZIP e APK. Gli altri archivi pubblici non sono tutti mantenuti sul disco locale.
- **37 file congelati** ancora identici al momento della consegna. Sei copie del log cumulativo coerenti col registro: Windows conserva CRLF e Android LF, unica differenza di fine riga ammessa. Nessuna differenza nel testo.
- Prove locali/CI, autenticazione online, pacchetti, pubblicazione e prove fisiche restano evidenze distinte. L’APK non è stato installato su un dispositivo Android fisico in questa consegna.

## Cosa resta personalizzabile

Negli editor esistenti e nel JSON: nomi/descrizioni; statistiche/sottotratti; Skill, Art, Open e forme; risorse, costi leggibili e minimi/massimi; effetti, elementi, bersagli, durata e cooldown; inventario/equipaggiamento; resistenze; anatomia, parti colpibili e loro Vita; temi, immagini, reliquie, colori e trasparenze. Le definizioni di catalogo non riscrivono le schede personalizzate.

## Conferme successive e scelte ancora aperte

- Golem Runico **E2 — Torace a botte** approvato mentre la build era già congelata. Originale copiato identico in `output/artwork/approvazioni_2026-11-01/golem_runico_desktop_canonico.png`; ricevuta nel manifest e nota `CANONE_SUCCESSIVO_ALLA_BUILD.md`. **Non incluso nella build f86951cb**; derivati e integrazione successivi non sono dichiarati approvati o implementati.
- [Indice delle scelte correnti](../output/artwork/SCELTE_CORRENTI_2026-11-01.html): 26 creature/156 alternative esatte in queste due raccolte; 21 desktop ancora da scegliere dopo Golem E2. Questo non è il totale delle creature del catalogo senza artwork.
- ART45, ART46, BUG49 e QA45 sono chiuse al 100% dopo le quattro risposte esplicite riportate sopra. Le altre righe e i nuovi artwork restano separati; le approvazioni visive già ricevute non sono richieste nuovamente.

## Ricevute riproducibili

`build/FOUR_CANONICAL_PACKS_VERIFICATION.json`, `build/four-packs-local-install.json`, `build/four-packs-packaged-artwork.json`, `build/four-packs-apk-signing.json`, `build/four-packs-public-release.json`, `build/four-packs-frozen-sources-and-logs.json`; ricevute originali dei quattro temi in `design/approved-meccanio-packs-2026-11-01.json` e `design/approved-fire-shield-pack-2026-11-01.json`.
