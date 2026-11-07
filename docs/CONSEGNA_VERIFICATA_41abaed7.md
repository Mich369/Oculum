# Consegna verificata della patch 275

La patch è pubblicata e installata. I pacchetti sono stati compilati dal commit `41abaed7b53c07e06a3b088dc504e41e9af99035`. [Build coordinata 42280975683](https://github.com/Mich369/Oculum/actions/runs/42280975683)

La consegna include 55 sfondi desktop scelti, l’Assassino generato come NPC nemico, il nuovo nome Armaiolo della spada e scudo con la sua variante Rituale e il ritiro dalle nuove selezioni del Duellante Errante e della famiglia Sagrestano Cavo. Le schede salvate conservano le proprie definizioni e immagini. [Modifiche e parametri personalizzabili](PATCH_2026-11-06_ASSASSINO_VOTI_ARTWORK.md)

| Verifica | Risultato |
| --- | --- |
| Sorgente locale | 80 casi Flutter distinti, 44 regressioni Python delle gallerie e 14 prove Python del publisher. Analisi statica senza problemi |
| CI coordinata | 9 job riusciti, 2.304 test passati e 6 saltati |
| Online autenticato | 4 prove automatizzate passate nella sessione dedicata |
| Artifact | 12 archivi acquisiti con controllo SHA256 integrale |
| Staging e installazione | 17.078 file verificati con zero difformità. EXE con runtime, ZIP e APK, con cartelle Windows normale e Test distinte |
| Immagini nei pacchetti | 605 confronti esatti dei 55 PNG, fra tre runtime e otto archivi |
| Versione precedente | Backup 5f89ea2b conservato e verificato su 16.913 file con zero difformità |
| Android | APK firmato `com.mich.oculum` con versionCode 100275. SHA256 della copia finale `a0b4522eef0e4d3774d6626ae27554022b1c9d5f6794e892b93d231008c5fd98` |
| Avvio Windows | EXE normale e Test attivi dopo otto secondi. Backup preventivo di 62 file dei profili, tutti identici dopo la prova |
| Download pubblici | 12 archivi accessibili senza login, con header ZIP e dimensioni verificati. Digest concordi fra CI, catalogo e release |
| Web | `index.html`, `flutter_bootstrap.js` e `main.dart.js` letti integralmente, con marker del commit compilato verificato |

L’installazione si è fermata prima dello scambio mentre Esplora file teneva aperta la cartella Windows. Dopo la conferma di chiusura, lo staging è stato ricontrollato e lo scambio completato. Il controllo anonimo dei download ha letto l’header ZIP e le dimensioni. Il controllo integrale dei digest appartiene all’acquisizione locale degli artifact. La prova Windows copre l’avvio e i profili. Restano fuori da questa verifica le interazioni complete dell’interfaccia e la prova su tre dispositivi fisici.

La cartella attiva è `C:\Oculum App\oculum\build\distribution`. Il backup della versione precedente è in `build/distribution-backup-42280975683-resume-20261107-044909995-28232`.

[Download pubblici della build](https://github.com/Mich369/Oculum/releases/tag/oculum-build-42280975683) · [Canale download](https://github.com/Mich369/Oculum/releases/tag/oculum-downloads) · [App web](https://mich369.github.io/Oculum/)

Le ricevute locali in `build` sono `RESUME_41abaed7_42280975683_20261107-044909995-28232.json`, `APK_INSTALLED_275_20261107.json`, `startup-smoke-41abaed7-42280975683-20261107-055921218.json`, `CI_42280975683_VALIDATION_SUMMARY.json` e `publication-41abaed7-42280975683.json`.
