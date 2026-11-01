# Consegna verificata — 0b82cb37

Commit compilato: `0b82cb37bb175496e10744a3003e816230949795`.
Build coordinata: <https://github.com/Mich369/Oculum/actions/runs/41230439056>.

## Modifiche consegnate

- Integrati i 18 PNG esatti già approvati: desktop, telefono e reliquia di Specchio Mangiavoce, Teschio Mostruoso, Torretta Oculum, Adoratore della Bestia, Cavaliere Morto e Scheletro Bombarolo.
- Inquadratura intera sui telefoni alti per questi sei pacchetti; immagini personali e identificativi precedenti conservati.
- Cavaliere Morto: punto debole coerente con la conferma dell'utente, sfera di Oculum nascosta alla base della vita. La sfera non compare anticipatamente fra le parti selezionabili con Precisione finché non viene scoperta. Le definizioni personalizzate restano conservate.
- Cuore Filo ritirato dal manuale/catalogo attivo, dalle varianti attive e dai nuovi incontri. Compatibilità di ID e definizioni già salvate conservata; non sono cancellate schede o personalizzazioni.
- Registro cumulativo e relativo asset offline sincronizzati. La transizione ai log separati per versione non è anticipata.

## Verifiche distinte

- CI della revisione consegnata: analisi senza problemi; **2.000 test passati, 6 saltati**. Gruppo separato: **4 prove online autenticate passate**, non prova grafica su tre dispositivi fisici. I 15 test del workflow Diari sono un gruppo sovrapposto, non sommato al totale.
- Localmente: 197 test mirati sui sei pacchetti e sull'accesso al punto debole; 57 test finali sul ritiro e sui percorsi collegati. I gruppi si sovrappongono. Suite locale precedente: 1.995 passati/6 saltati prima del ritiro; non viene presentata come suite locale completa di questa revisione.
- Build coordinate riuscite: Windows normale e Test, Android, web, Linux, macOS e iOS unsigned. Il workflow macOS autonomo è separato ed è stato cancellato; non compromette il pacchetto macOS coordinato riuscito.
- Distribuzione locale sostituita dopo verifica: **16.518 file, zero differenze**. EXE completo di runtime nella radice; cartelle `windows` e `windows-test` separate; ZIP normale, ZIP Test e APK. Precedente distribuzione conservata in `build/distribution-backup-41230439056-20261031-205702340`.
- **108 confronti SHA** sui 18 PNG approvati nelle tre cartelle runtime e nei tre pacchetti locali: nessuna differenza.
- APK: `com.mich.oculum`, `versionCode 100265`, firma verificata e coerente con il certificato precedente. Nessuna installazione su telefono fisico eseguita in questa verifica.
- **11 download pubblici senza login**: nomi, dimensioni e digest corrispondono agli artifact del run e agli asset effettivi della Release immutabile. Verificati risposta anonima e header ZIP, non riscaricati integralmente tutti gli archivi pubblici. I pacchetti locali sono stati invece scaricati con SHA completo verificato.
- Sito pubblicato: commit compilato verificato in HTML/bootstrap/JavaScript; SHA dei sei desktop pubblicati uguali agli approvati. Nessuna nuova sessione grafica indipendente su tre dispositivi dichiarata.
- Gli EXE normali non sono stati avviati di nascosto per questa consegna: si conserva la visualizzazione del log al primo avvio dell'utente. I test UI automatici e l'integrità dei runtime sono le prove disponibili.

## File e personalizzazioni

Distribuzione: `C:\Oculum App\oculum\build\distribution`.
Download pubblici: <https://mich369.github.io/Oculum/>; Release immutabile: <https://github.com/Mich369/Oculum/releases/tag/oculum-build-41230439056>.

Restano personalizzabili negli strumenti e nel JSON già esistenti: selezione del tema e immagini personali, descrizioni, punto debole e anatomia esplicita della scheda; Skill, costi, bersagli, durate ed effetti continuano a mantenere le personalizzazioni salvate. I nuovi PNG decorativi non aggiungono da soli Skill o drop. Il catalogo predefinito esclude Cuore Filo; le sue vecchie schede restano compatibili.

Prove locali dettagliate: `build/SIX_CANONICAL_PACKS_VERIFICATION.json`, `build/six-packs-packaged-artwork.json`, `build/six-packs-public-release.json`, `build/six-packs-apk-signing.json`.

## Lavoro separato ancora da valutare

Le sei alternative A–F dei lotti notturni sono proposte, non immagini installate o approvate automaticamente. Indice e domande in `output/artwork/sei_varianti_notte_2026-10-31/`.

Le discrepanze anatomiche preesistenti di Meccanio e Obser Sunshine sono registrate in `docs/APPUNTI_SEI_VARIANTI_NOTTE_2026-10-31.md`, da correggere nella revisione successiva; questa consegna non le dichiara risolte.

Riga completa da chiudere: **ART43 — Integrare i sei set canonici desktop/telefono/reliquia, correggere la sfera del Cavaliere Morto e preservare personalizzazioni e leggibilità.**

Adattamento consegnato: 18 file già approvati collegati senza ritoccarne i pixel; composizioni intere sui telefoni alti; sfera del Cavaliere nascosta fino alla scoperta; compatibilità delle anatomie personalizzate. Evidenze: 197 test mirati locali, CI 2.000 passati/6 saltati, 4 prove autenticate separate, 108 confronti artwork nei pacchetti, 16.518 file verificati, 11 download pubblici e commit web corrispondente.

**Domanda raccolta per il risveglio:** approvi la chiusura al 100% della sola riga ART43 per questa consegna? Le nuove proposte notturne, i problemi anatomici segnalati e le prove su dispositivi fisici restano separati.

Riga ART43 e nuove proposte rimangono in attesa della conferma dell'utente prevista dal registro. La verifica tecnica non costituisce approvazione al 100% della riga.
