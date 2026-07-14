# Configurazione build Supabase

La configurazione client publishable del progetto Oculum è inclusa come
fallback in `lib/main.dart`, quindi `flutter run` e le build locali funzionano
anche senza argomenti aggiuntivi.

I valori possono essere sovrascritti con `--dart-define`:

- `OculumSupabaseUrl`
- `OculumSupabasePublishableKey` (nome preferito)
- `OculumSupabaseAnonKey` (alias legacy ancora supportato)

GitHub Actions può sovrascriverli tramite i secret:

- `OCULUM_SUPABASE_URL`
- `OCULUM_SUPABASE_PUBLISHABLE_KEY`

Valori vuoti non disabilitano accidentalmente il fallback incluso. Una
configurazione con URL o chiave non validi lascia comunque l'app in modalità
locale. Google e Apple OAuth restano disabilitati finché i provider non vengono
attivati nella dashboard Supabase e nelle relative console.

Il salvataggio cloud richiede inoltre la migrazione SQL presente in
`supabase/migrations/20260712000000_create_oculum_cloud_saves.sql`.

Per i client nativi il callback incluso è
`com.mich.oculum://login-callback`. Va aggiunto una sola volta alla allow list
**Redirect URLs** del progetto Supabase. Android, iOS e macOS sono già
registrati per aprire questo URL nell'app.
