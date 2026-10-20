# Stanze online: ingresso, richieste e password opzionale

## Come collegare Master e player

1. Il Master può aprire **Password stanza (opzionale)** e inserire una password prima di premere **Crea nuova stanza**. Il codice generato identifica la stanza; l'identità autenticata determina il proprietario.
2. Il Master comunica il **Room ID** e l'eventuale password ai partecipanti.
3. Il player inserisce lo stesso Room ID, lascia disattivato **Entra come Master**, inserisce l'eventuale password e preme **Connetti**.
4. Il Master apre la busta **Richieste al Master** in alto e preme **Ammetti** o **Rifiuta**. La decisione è confermata dal backend prima di risultare completata nella UI.
5. L'account già approvato rientra senza una nuova approvazione, salvo revoca. Un nuovo ospite o un altro account è una nuova identità e richiede l'approvazione.

La password può essere modificata dal proprietario con **Applica password**. Un campo vuoto rimuove la protezione. I partecipanti già approvati mantengono il loro accesso; per escluderli serve la revoca, non il semplice cambio password. Il QR resta una scorciatoia al codice della stanza.

## Correzioni

- Lo stato di attesa non riattiva **Connetti** e non avvia riconnessioni concorrenti. **Annulla ingresso** interrompe l'attesa.
- Una stanza esistente conserva il suo proprietario anche quando un altro account seleziona il ruolo Master. Il messaggio distingue ruolo richiesto e ruolo effettivo.
- La registrazione della richiesta avviene una volta. L'attesa legge soltanto la propria membership ogni 10 secondi, evitando ripetuti lock di scrittura della stanza.
- Le richieste di accesso compaiono nella busta in alto e non tengono occupato il ciclo di sincronizzazione mentre il Master decide.
- Cambiare scheda durante un aggiornamento Presence fa completare la registrazione della nuova identità prima dell'invio dell'azione.
- Se il server non riconosce la scheda selezionata come appartenente all'account, il client mostra il conflitto e invia al Master una segnalazione nelle richieste in alto. La segnalazione contiene nome e tag, non la scheda privata, e non trasferisce proprietà.
- È possibile accedere all'account originale o creare esplicitamente una copia con un nuovo tag tramite la duplicazione esistente. L'originale resta conservato.

## Password e compatibilità

Migrazione additiva: `supabase/migrations/20261020194205_optional_oculum_room_password.sql`, applicata al progetto Oculum. Nessuna stanza o scheda esistente viene cancellata.

Gli hash bcrypt sono nella tabella privata `oculum_private.room_passwords`, senza accesso client. Nessuna password entra nei JSON delle schede o nei salvataggi locali. Il limite è 72 byte UTF-8. Anche la RPC precedente attraversa il controllo della password, mantenendo compatibili le stanze senza password e gli account già approvati.

Solo il proprietario può cambiare o rimuovere la password. La password corretta non attribuisce il ruolo Master e non sostituisce l'approvazione. Password errate e codici inesistenti richiedono un intervento dell'utente, senza tentativi automatici continui.

Il rollback esplicito è preparato in `supabase/tests/rollback_optional_room_password.sql`: rimuove soltanto la funzionalità password e i suoi hash. Non è stato eseguito.

## Verifiche

- Test SQL su Supabase con ruoli autenticati simulati e dati interamente annullati: password errata, vecchia RPC, richiesta pending, impossibilità di auto-promozione, cambio password riservato al proprietario, hash illeggibili dal client, rientro approvato e revoca: PASS.
- `flutter analyze --no-pub`: nessun problema dopo la correzione dell'avviso sulle parentesi.
- Test locali del trasporto simulato e del pannello: 19 passati. Verificano anche apertura della busta, segnalazione leggibile, rifiuto di segnalazioni senza identità server e assenza della password dal JSON della scheda.
- Test di trasporto e permessi/soglie: 20 passati; test Auth/cloud: 14 passati.
- Tre test con client Supabase autenticati reali passati: Auth, trasferimento di schede grandi con ACK/riconnessione, difesa/danni/cura/aiuto con segno. Sono processi sulla stessa macchina, non una verifica manuale fra Windows e Chrome.
- I risultati della CI del nuovo commit e dei pacchetti di distribuzione vanno riportati separatamente.
- L'[advisor RLS](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy) segnala la tabella privata con RLS senza policy: è una negazione intenzionale dell'accesso client, verificata dal test SQL. Le policy per gli ospiti autenticati rimangono vincolate all'utente e all'appartenenza alla stanza.

## Personalizzabile

Room ID, nome visibile, password opzionale, approvazione/rifiuto del partecipante e scelta della scheda da usare. Questa correzione non modifica regole di combattimento, abilità o cataloghi personalizzati.

