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
| `lib/src/main/oculum_realtime_integration.dart` | Frequenza invii (500 ms), timeout conferma (3/5 s), massimo tentativi (5), destinatari, reinvio dopo riconnessione, token/Fight e testi di esito. |
| `test/oculum_realtime_delivery_test.dart` | Scenari simulati: sessioni, connessioni concorrenti, risottoscrizione, errori, timeout e risposta tardiva dopo disconnessione. |

Le prove automatiche usano un canale simulato, senza salvataggi personali. Il recap della consegna indica separatamente verifiche automatiche, build e verifica reale fra dispositivi. Nessuna modifica allo schema cloud o alle chiavi dei salvataggi.

Verifica eseguita: `flutter analyze --no-pub` senza problemi e 15 test superati nelle suite `oculum_realtime_delivery_test.dart`, `oculum_realtime_patch_test.dart` e `oculum_theme_share_reliability_test.dart`. La consegna fra due dispositivi reali e le interruzioni di rete reali restano da verificare.
