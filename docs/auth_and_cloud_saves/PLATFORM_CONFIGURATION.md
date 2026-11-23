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

Il callback OAuth nativo è `com.mich.oculum://login-callback`. Android usa
l’intent filter, iOS e macOS lo schema dichiarato nel bundle, Windows la
registrazione per l’utente corrente al momento dell’accesso. Windows Test ha
uno schema distinto per evitare che una delle due edizioni intercetti il
ritorno dell’altra. L’URL web di produzione e le istruzioni per i provider
sono nel [setup Google](GOOGLE_SIGN_IN_SETUP.md).
