# Configurazione piattaforme

Identificativo applicazione corrente: `com.mich.oculum`.

- Android: namespace e application ID `com.mich.oculum`.
- iOS: bundle identifier `com.mich.oculum`.
- macOS: bundle identifier `com.mich.oculum`.
- Linux: application ID `com.mich.oculum`.

Supabase usa lo stesso URL HTTPS e la stessa chiave publishable su tutte le
piattaforme. Android include i permessi `INTERNET` e `ACCESS_NETWORK_STATE`;
macOS include il diritto sandbox `com.apple.security.network.client`; iOS non
richiede eccezioni ATS perché il progetto Supabase usa HTTPS.

Il callback OAuth nativo è `com.mich.oculum://login-callback` ed è registrato
come intent filter Android e URL type iOS/macOS. Lo stesso URL deve essere
aggiunto alla allow list **Redirect URLs** della dashboard Supabase prima di
attivare Google o Apple. I provider restano disabilitati nell'app finché non
sono configurati nella dashboard Supabase e nelle rispettive console.
