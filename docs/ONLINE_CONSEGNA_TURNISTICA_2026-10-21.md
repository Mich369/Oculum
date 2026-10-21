# Consegna schede e turnistica del Master — 21 ottobre 2026

## Problemi dimostrati

- Nella stanza della prova il player era approvato ma il tag attivo era stato escluso dalle identità accettate. Il tag era già associato a un'altra identità: la connessione non equivale alla consegna della scheda.
- La scelta della campagna per turnistica e permessi utilizzava la prima sessione Master in Presence. Due dispositivi dello stesso Master, aperti su campagne locali diverse, potevano far scartare uno snapshot valido.
- La pubblicazione dipendeva dal pulsante manuale Pubblica, anche con uno scontro attivo online.
- Molte schede grandi del Master partivano contemporaneamente e venivano ripetute su cambi Presence. Il ricevitore ha un assemblatore con limite di otto trasferimenti: un party più grande poteva superarlo.
- I ritratti completi erano duplicati nella radice e negli scontri dello snapshot turnistica, rischiando di superare il limite della RPC.
- Una richiesta manuale di scheda poteva fermarsi davanti alla vecchia conferma ancora in attesa. La condivisione completa dipendeva inoltre dai tag amici/Staff, anche se il canale verso il Master è indirizzato per ruolo.

## Correzioni

- Scontro attivo del Master condiviso automaticamente; pubblicazione esplicita e chiusura restano disponibili. La chiusura volontaria non viene annullata dai successivi aggiornamenti della stessa connessione.
- Campagna della sessione che ha pubblicato la turnistica e numeri di sequenza del database per evitare che un vecchio snapshot di un altro dispositivo sostituisca il nuovo.
- Schede grandi inviate in sequenza; invii Master/Co-Master identici deduplicati anche durante un trasferimento. Firma del contenuto SHA-256, senza conservare ulteriori copie dei ritratti nella cache.
- Il replay esclude gli eventi prodotti dalla stessa sessione. Le altre sessioni dello stesso account continuano a riceverli.
- Lo snapshot turnistica non incorpora ritratti oltre 4 KB; la turnistica riusa il ritratto ricevuto separatamente nella scheda/token, senza duplicarlo ad ogni turno. Le immagini restano nei JSON e nei salvataggi.
- Pulsante Invia scheda al Master; richiesta manuale che forza il reinvio della sola scheda attiva, anche con ACK precedente mancante. Distinti invio al server e conferma del Master.
- Avviso immediato di conflitto del tag. «Crea copia e invia» richiede una scelta esplicita e utilizza la duplicazione esistente; nessuna appropriazione di schede altrui.
- Condivisione al Master disponibile senza amici e senza tag Master annunciati in Presence, usando il canale Staff protetto già presente.

## Dati preservati e personalizzazione

Nessuna migrazione o cancellazione del database per queste correzioni. Restano salvataggi locali, immagini, inventari, diari, schede offline e JSON personalizzati. Master e player conservano gli editor di abilità, effetti, costi, durata e bersagli.

Restano modificabili codice e password della stanza, nome visibile, scheda attiva, partecipanti, ordine e round del Master, visibilità delle schede nemiche e pubblicazione/chiusura della turnistica. Il Master continua a scegliere i partecipanti: non viene aggiunto l'archivio privato del player allo scontro.

Il Master conserva la modifica delle schede condivise tramite il canale `sheetEdit` già autorizzato dal backend: variazioni a Vita, scudi e HP temporanei raggiungono il proprietario senza trasferire il tag. La prova live di combattimento verifica anche questo percorso.

## Verifiche

I risultati locali, i test con Auth/Supabase reali, la CI, il sito e i pacchetti sono da riportare separatamente. Un test del trasporto con client reali non certifica da solo una prova manuale fra tre applicazioni Windows/Chrome/Windows Test.
