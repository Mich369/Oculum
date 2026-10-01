# Realtime: affidabilita e punti modificabili

## Interventi del 29 settembre 2026

- Aggiornamenti scheda al Master ogni 500 ms al massimo durante una sequenza di modifiche: la finestra non viene continuamente spostata dagli input.
- Una sola connessione in corso per servizio, con protezione da completamenti e messaggi di un canale ormai abbandonato.
- Ripubblicazione dello stato anche quando il canale Supabase recupera autonomamente la connessione.
- Reinvio agli amici quando cambia la loro sessione, anche con gli stessi tag. I normali refresh Presence non causano reinvii.
- Ripubblicazione dei token visibili e della Fight gia pubblicata dopo riconnessione o ingresso di partecipanti.
- Una sola conferma Master pendente per scheda: un nuovo invio sostituisce i tentativi precedenti. Il timer parte dopo la risposta del trasporto, senza ricreare conferme gia ricevute.
- Controllo del ruolo e della scheda nelle conferme Master; deduplicazione degli eventi comprensiva di scheda, proprietario, consegna e destinatario.
- Il messaggio di invio completo distingue accettazione del server e ricezione del Master, coerentemente con https://supabase.com/docs/guides/realtime/broadcast.

## Tutti i punti modificabili di questo intervento

| File | Cosa modificare |
| --- | --- |
| `lib/services/oculum_realtime_service.dart` | Connessione, callback di riconnessione, timeout del trasporto (6 s), sottoscrizione (12 s), eventi supportati e Presence. |
| `lib/src/main/oculum_realtime_integration.dart` | Frequenza invii (500 ms), timeout conferma (3/5 s, poi 30 s), destinatari, reinvio dopo riconnessione, token/Fight e testi di esito. |
| `test/oculum_realtime_delivery_test.dart` | Scenari simulati: sessioni, connessioni concorrenti, risottoscrizione, errori, timeout e risposta tardiva dopo disconnessione. |

Le prove automatiche usano un canale simulato, senza salvataggi personali. Il recap della consegna indica separatamente verifiche automatiche, build e verifica reale fra dispositivi. Nessuna modifica allo schema cloud o alle chiavi dei salvataggi.

Verifica eseguita: `flutter analyze --no-pub` senza problemi e 15 test superati nelle suite `oculum_realtime_delivery_test.dart`, `oculum_realtime_patch_test.dart` e `oculum_theme_share_reliability_test.dart`. La consegna fra due dispositivi reali e le interruzioni di rete reali restano da verificare.

## Ricezione schede: 1 ottobre 2026

- Le schede pesanti vengono trasferite a blocchi senza ridurre o rimuovere immagini, note, inventario o altri campi. Il destinatario importa esclusivamente il messaggio completo; blocchi mancanti, incoerenti o scaduti non producono schede parziali.
- Le schede piccole mantengono l'evento originale. Il trasferimento a blocchi richiede questa versione su entrambi i dispositivi (protocollo Presence 3); il formato dei salvataggi non cambia.
- I tentativi non terminano dopo cinque invii: proseguono ogni 30 secondi mentre connessione e Master restano disponibili. Se il Master rientra, Presence e richiesta esplicita riprendono l'invio.
- Il Master richiede le schede quando si connette e può usare «Richiedi schede ai Player». Il solo ACK del server non marca come ricevuta dal Master una scheda che attende il suo ACK.
- Un solo trasferimento per scheda alla volta: le modifiche intermedie vengono accorpate nell'aggiornamento seguente. Le nuove versioni hanno un nuovo identificativo di consegna; le vecchie conferme non chiudono gli invii nuovi.
- L'ACK del Master viene emesso dopo validazione e inserimento nel registro delle schede ricevute. Non equivale a conferma di un merge senza conflitti o di scrittura su disco remoto.
- Il salvataggio locale protetto precede l'invio delle modifiche al proprietario; un'attesa di rete non blocca la scrittura locale. Modifiche sopraggiunte durante l'invio rimangono da inviare.

### Parametri e file modificabili

| File | Cosa modificare |
| --- | --- |
| `lib/services/oculum_sheet_transfer.dart` | Dimensione blocco (64 KiB di base64), massimo 1024 blocchi, memoria aggregata 64 MiB, massimo 8 trasferimenti incompleti, scadenza 3 minuti. |
| `lib/services/oculum_realtime_service.dart` | Encoding fuori dal thread UI su desktop/mobile, evento blocchi, richiesta schede e protezioni al cambio canale; timeout per blocco 6 secondi. |
| `lib/src/main/oculum_realtime_integration.dart` | Reinvii 3/5/30 secondi, accorpamento, ACK Master, controllo revisioni di consegna, pulsante richiesta. |
| `lib/main.dart` | Registri temporanei dei trasferimenti e delle conferme. |
| `lib/src/main/oculum_home_persistence.dart` | Ordine locale prima della rete e risalvataggio dei flag dopo l'invio. |
| `test/oculum_sheet_transfer_test.dart`, `test/oculum_realtime_delivery_test.dart` | Blocchi mancanti/duplicati/fuori ordine, dati non validi, riconnessione, immagine grande e invio fallito. |
| `.github/workflows/test_windows_distribution.yml` | Test di ricezione inclusi nella build Windows test isolata. |

La coda persistente generale e l'interfaccia completa dei conflitti richieste per l'architettura offline-first rimangono interventi distinti: questo aggiornamento rinforza il trasporto esistente, senza dichiararle implementate.

Verifica della versione finale: 578 test passati, uno saltato; analizzatore senza problemi. Il benchmark è stato rieseguito con `OculumBenchmarkLabel=realtime-20261001` dopo un blocco Windows sul precedente file di report. Trasporto verificato con canale simulato, non con due dispositivi Supabase live.

Successiva prova live del 1 ottobre: `test/oculum_realtime_live_delivery_test.dart` passato con `--dart-define=OculumLiveRealtimeTest=true`. Due client Supabase reali sulla stessa macchina hanno verificato trasferimento completo di una scheda sintetica con immagine di 500.000 caratteri, distinzione fra ACK server e destinatario, reinvio e ricezione dopo riconnessione. La stanza temporanea è distinta dalle campagne; nessun dato personale o salvataggio viene utilizzato. Non è una prova completa dell'interfaccia su due dispositivi fisici. Il test è opzionale e normalmente saltato, quindi la suite e l'app rimangono indipendenti dalla rete. È eseguibile anche da `diary_tests.yml` con l'input manuale `live_realtime`.
