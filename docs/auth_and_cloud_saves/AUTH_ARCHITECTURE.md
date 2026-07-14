# Architettura autenticazione Oculum

`OculumAuthService` centralizza sessione, logout e codice OAuth futuro. La UI
non accede direttamente a Supabase.

- Supabase usa la configurazione publishable inclusa nell'app; i `dart-define`
  possono sovrascriverla senza essere obbligatori.
- Senza configurazione l’app resta Guest/local-only e i salvataggi locali
  continuano a funzionare.
- Google e Apple sono disabilitati e mostrati come “Prossimamente”.
- Il redirect OAuth nativo è `com.mich.oculum://login-callback` ed è registrato
  su Android, iOS e macOS.
- Il codice per avviare OAuth e gestire la sessione resta disponibile per una
  futura configurazione esplicita.
- Il login non collega, carica, scarica o sovrascrive salvataggi.

L’identificativo applicazione corrente è `com.mich.oculum`.
