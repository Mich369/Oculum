# Configurazione build Supabase

Valori client passati con `--dart-define`:

- `OculumSupabaseUrl`
- `OculumSupabaseAnonKey` (publishable key client)

GitHub Actions li riceve esclusivamente dai secret:

- `OCULUM_SUPABASE_URL`
- `OCULUM_SUPABASE_PUBLISHABLE_KEY`

Se uno dei due valori manca, Supabase non viene inizializzato e l’app resta
Guest/local-only. Google e Apple OAuth rimangono disabilitati.
