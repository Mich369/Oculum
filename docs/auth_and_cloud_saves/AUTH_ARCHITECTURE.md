# Architettura autenticazione Oculum

`OculumAuthService` centralizza sessione, logout e codice OAuth futuro. La UI
non accede direttamente a Supabase.

- Supabase viene inizializzato solo quando `OculumSupabaseUrl` e
  `OculumSupabaseAnonKey` sono entrambi presenti.
- Senza configurazione l’app resta Guest/local-only e i salvataggi locali
  continuano a funzionare.
- Google e Apple sono disabilitati e mostrati come “Prossimamente”.
- Nessun redirect OAuth o deep link definitivo è configurato nel repository.
- Il codice per avviare OAuth e gestire la sessione resta disponibile per una
  futura configurazione esplicita.
- Il login non collega, carica, scarica o sovrascrive salvataggi.

L’identificativo applicazione corrente è `com.mich.oculum`.
