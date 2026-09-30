# Realtime Master e ricerca mostri — 26 settembre 2026

Le schede vengono reinviate quando un partecipante assume il ruolo Master o Co-Master, anche se i suoi tag non cambiano, e quando compare una nuova sessione dello staff. I normali aggiornamenti della Presence non provocano ulteriori invii se ruolo e sessione restano uguali.

Il cambio ruolo dalle impostazioni e dal dialogo di ingresso aggiorna anche la Presence realtime, rispettando il Master già presente nella stanza.

Il servizio controlla la risposta effettiva del canale: errori e timeout non sono più considerati successi. La scheda viene memorizzata come inviata solo dopo la conferma del canale; gli invii falliti restano ripetibili. La conferma del canale è distinta dalla conferma di ricezione del Master, già gestita dal protocollo.

Nel Rito di Creazione, attivare **Genera come Mostro**, scegliere il tipo e premere **Cerca un mostro nel Monster Book**. La ricerca filtra per nome italiano, inglese e identificativo, senza distinguere maiuscole e minuscole. Selezionare il risultato per applicarlo; **Annulla** conserva la scelta precedente; **Crea una creatura libera** rimuove il preset. Restano il filtro Mostro/Mini Boss/Boss, le forme e le regole di generazione esistenti.

## Punti modificabili

- `lib/services/oculum_realtime_service.dart`: trasporto, esito degli invii, timeout e identificativo della sessione Presence.
- `lib/src/main/oculum_realtime_integration.dart`: riconoscimento dello staff, reinvio, deduplicazione, tentativi e conferme Master; permessi e importazione delle schede.
- `lib/src/main/oculum_home_share_content.dart`: aggiornamento del ruolo online dal dialogo di ingresso.
- `lib/widgets/oculum_monster_picker.dart`: ricerca, campi cercati, testi, dimensioni e lista risultati.
- `lib/src/main/oculum_home_rules_settings_search.dart`: collegamento al tutorial, filtro del tipo, scelta delle varianti e applicazione del preset.
- `lib/pages/oculum_dungeon/monster_book.dart`: nomi, contenuti e statistiche dei mostri.
- `lib/services/oculum_save_profile.dart`: profilo test con chiavi e file separati.

## Distribuzione e verifiche

In `build/distribution`: EXE e ZIP Windows normali, APK normale; in `test`, EXE test con runtime, più `Oculum-Test-Windows.zip`. Nessun APK test.

I test usano un canale simulato e non accedono ai salvataggi personali. Coprono cambio ruolo e sessione dello staff, errore/timeout/successo del canale, ricerca e selezione su schermo stretto, annullamento e creatura libera, oltre alle regressioni esistenti di condivisione e generazione mostri. La consegna fra due dispositivi reali resta da verificare.
