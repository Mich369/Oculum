# Audit online — 19 ottobre 2026

## Decisioni confermate

Ospite protetto senza registrazione obbligatoria; email facoltativa nelle Impostazioni; scelta «Mantieni l’accesso»; più dispositivi. Invio automatico della sola scheda usata. Preservare offline, salvataggi e JSON. Dopo l’online completare mostri, cartelle e occhio: vedere `LAVORI_IN_CORSO_2026-10-19.md`.

## Correzioni implementate

- Installata la tabella cloud assente nel progetto, con RLS per proprietario.
- Code cloud separate per account, lettura compatibile delle vecchie chiavi; rifiuto di contenuti vuoti o codifiche incoerenti.
- Identificativi casuali a 128 bit, nuovi inserimenti invece di sovrascritture, SHA-256 canonico e copia profonda del contenuto.
- Logout limitato al dispositivo; persistenza della sessione configurabile.
- Stanze con proprietario autenticato, approvazione degli ingressi, ruoli server e proprietari delle schede.
- Identificativi di sessione casuali: riprodotta e corretta una collisione con quelli basati sull’orologio.
- Canali privati: viene annunciato solo l’ID dell’evento validato. Il corpo si legge dal database con RLS per stanza e destinatario. Le schede dello staff non sono leggibili dai player.
- Presenza autenticata dal backend; recupero eventi recenti e deduplicazione. Un errore di presenza conserva l’ultimo elenco noto.
- `fullShare` e `sheetEdit` separati dal ruolo autenticato. Modifiche dei player autorizzate dal proprietario; revoche e blocchi applicati sul backend.
- Ammissione con scelta esplicita: il clic fuori dal dialogo non rifiuta il player. Se il salvataggio della decisione fallisce, la richiesta può essere riproposta.

## Verifiche completate

- 22 test locali di autenticazione e salvataggio.
- Due ospiti reali: impossibile leggere, inserire, modificare o cancellare i salvataggi altrui. Righe cloud di prova rimosse.
- Test database con ruolo `authenticated`, transazione annullata: proprietario, ingresso pendente, rifiuto dell’auto-promozione, approvazione.
- Due client reali: ingresso autorizzato, trasferimento scheda, ricevuta del destinatario distinta dall’ACK del server, riconnessione.
- Runtime Flutter del player e client Master su Supabase reale: richiesta di difesa nel log, difesa risolta, Scudo Oculum → Scudo → HP temporanei → Vita, ricevuta del danno, aiuto negativo e cura senza duplicati. Test: `flutter test --no-pub --dart-define=OculumLiveRealtimeTest=true test/oculum_combat_live_application_test.dart`.
- Analisi completa `dart analyze lib test`: nessun problema. Ultima regressione locale: 44 test riusciti su mostri/cartelle, VTT, permessi, autenticazione e cloud.
- Due sessioni Chrome con origini locali separate, stesso build release e Supabase reale: avvio Master/player, ospiti indipendenti, ingresso pendente e dialogo di ammissione verificati. La prova completa di combattimento e riconnessione da queste due interfacce non è ancora conclusa.

Le prove di combattimento completate usano client/runtime di test. Non equivalgono a una prova manuale completa fra due browser o dispositivi fisici. L'utente ha chiarito che chiedeva se tutte le prove fossero passate: non ha dichiarato di averle eseguite.

## Da completare

Completati anche 8 test locali di regressione del combattimento e `supabase/tests/oculum_room_authority.sql`: ruoli simulati sul database reale, transazione annullata, rifiuto di falsi eventi Master e sessioni altrui, riservatezza delle schede staff, concessione e revoca delle modifiche. Gli advisor non segnalano più RPC privilegiate nello schema pubblico.

Restano la prova completa fra due browser, tablet/telefono fisici, email reale e accesso da più dispositivi; CI, Pages e distribuzione aggiornata sono verifiche separate. Le regressioni locali VTT/mappe sono incluse nei 44 test finali.

La distribuzione precedente ha hash discordanti: non certifica queste modifiche. Preparare e sostituire pacchetti verificati solo a sorgenti stabili. Il registro eventi è persistente; il recupero automatico corrente legge gli ultimi cinque minuti. Rifinire conservazione e recupero dopo assenze più lunghe.

## Personalizzazione

Abilità, costi, durata, bersagli ed effetti restano negli editor e nel JSON, senza sostituire le personalizzazioni con il catalogo. Le opzioni di accesso sono nelle Impostazioni.

## Migrazioni applicate

- `20261019175126_create_oculum_cloud_saves.sql`
- `20261019175540_secure_oculum_rooms.sql`
- `20261019180013_authenticated_oculum_events.sql`
- `20261019180324_harden_oculum_rpc_entrypoints.sql`
- `20261019181221_preserve_oculum_sheet_sharing_permissions.sql`

Nessun salvataggio cancellato. Implementazioni privilegiate nello schema privato con `search_path` vuoto, controllo UID e permessi espliciti; ingressi pubblici come chiamante. Gli accessi degli ospiti autenticati segnalati dagli advisor sono intenzionali e limitati da proprietà/appartenenza. Ricontrollare gli advisor dopo le ultime migrazioni: https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable

