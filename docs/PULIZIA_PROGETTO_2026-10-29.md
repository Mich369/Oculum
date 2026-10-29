# Pulizia verificata del progetto — 29 ottobre 2026

Richiesta dell’utente: «ripulisci il progetto dalle cose inutili assicurandoti che lo siano».

Rimossi **1.588.938.160 byte** di copie temporanee ricostruibili, circa **1,59 GB / 1,48 GiB**, e **4.418 cartelle vuote** create dai test.

| Percorso rimosso | Byte | Motivo |
|---|---:|---|
| `build/test_cache` | 193.069.248 | Due file compilati `.dill` del test runner. |
| `build/unit_test_assets` | 694.598.692 | Bundle generato per i test; asset originali conservati. |
| `build/web` | 502.955.499 | Compilazione web locale inattiva; nessun server la stava usando. |
| `build/app` | 93.025.980 | Intermedi Android generati/Kotlin/tmp, senza APK da conservare. |
| `android/.gradle` | 105.288.741 | Cache Gradle locale inattiva. |

Le cartelle vuote erano 4.173 `theme-effect-test-*`, 140 `afona-test-*` e 105 `threshold-actions-*`. Ogni cartella è stata ricontrollata vuota immediatamente prima della rimozione **non ricorsiva**; le 761 cartelle simili non vuote sono state conservate.

Prima della rimozione sono stati verificati percorsi assoluti interni al progetto, esclusione Git, assenza di file tracciati, di collegamenti a directory e di processi di compilazione/Oculum attivi. Per `build/web` sono stati controllati anche eventuali server Python/Node/Dart, senza esporne righe di comando.

**Conservati:** sorgenti, documenti e personalizzazioni, salvataggi, chiavi, allegati, artwork e revisioni, schede esportate, distribuzione attiva, backup, download GitHub già verificati e pacchetto isolato del prossimo intervento sul sonno. Nessun file non tracciato è stato considerato inutile soltanto per il suo stato Git.

Il prossimo test o build ricreerà le proprie cache. Non sono stati rieseguiti test per questa sola pulizia: ne avrebbero rigenerato immediatamente il contenuto. Il rapporto della rimozione è `build/cleanup-verified-2026-10-29.json`.

Separatamente dal totale sopra, è stato rimosso soltanto l’archivio Linux parziale da 671.088.640 byte creato dal tentativo di installazione interrotto per spazio insufficiente. Non era un pacchetto verificato né una versione precedente da conservare.
