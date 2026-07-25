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

## Firma e notarizzazione macOS

Per evitare il blocco Gatekeeper "Apple non può verificare la presenza di
malware", le build macOS GitHub richiedono questi secret aggiuntivi:

- `APPLE_DEVELOPER_ID_CERTIFICATE_BASE64`: certificato **Developer ID
  Application** esportato come `.p12` e codificato Base64.
- `APPLE_DEVELOPER_ID_CERTIFICATE_PASSWORD`: password del file `.p12`.
- `APPLE_ID`: Apple ID usato per la notarizzazione.
- `APPLE_APP_SPECIFIC_PASSWORD`: password specifica per l'app generata per
  l'Apple ID.
- `APPLE_TEAM_ID`: Team ID dell'account Apple Developer.

Il workflow fallisce intenzionalmente se uno di questi valori manca. Dopo la
build applica firma Developer ID con hardened runtime, invia lo ZIP ad Apple
Notary Service, applica il ticket con `stapler` e verifica il bundle con
Gatekeeper prima di pubblicarlo.
