# Oculum config report

## 1) Variabili Supabase richieste dal codice

- OculumSupabaseUrl
  - Stato: MANCANTE
  - File dove viene letta: [lib/main.dart](lib/main.dart)
  - Metodo di ricezione: --dart-define (via const String.fromEnvironment in [lib/main.dart](lib/main.dart))

- OculumSupabaseAnonKey
  - Stato: MANCANTE
  - File dove viene letta: [lib/main.dart](lib/main.dart)
  - Metodo di ricezione: --dart-define (via const String.fromEnvironment in [lib/main.dart](lib/main.dart))

## 2) Punto esatto in cui Supabase viene inizializzato

- Inizializzazione in [lib/main.dart](lib/main.dart) nella funzione _initializeOculumSupabase(), che chiama Supabase.initialize(...) con url e anonKey.

## 3) Sistemi di accesso presenti nel codice

- Email e password: NON PRESENTI
  - Fonti: [lib/services/oculum_auth_service.dart](lib/services/oculum_auth_service.dart), [lib/services/oculum_auth_ui.dart](lib/services/oculum_auth_ui.dart)
- Google: PRESENTE
  - Fonte: [lib/services/oculum_auth_service.dart](lib/services/oculum_auth_service.dart), [lib/services/oculum_auth_ui.dart](lib/services/oculum_auth_ui.dart)
- Apple: PRESENTE
  - Fonte: [lib/services/oculum_auth_service.dart](lib/services/oculum_auth_service.dart), [lib/services/oculum_auth_ui.dart](lib/services/oculum_auth_ui.dart)
- Altri: Guest/local-only presente
  - Fonte: [lib/services/oculum_auth_service.dart](lib/services/oculum_auth_service.dart), [lib/services/oculum_auth_ui.dart](lib/services/oculum_auth_ui.dart)

## 4) Stato di Google e Apple

- Google: presente nel codice come pulsante e chiamata OAuth, ma non verificabile come completamente configurato nelle console esterne da questo repository.
  - Fonti: [lib/services/oculum_auth_ui.dart](lib/services/oculum_auth_ui.dart), [lib/services/oculum_auth_service.dart](lib/services/oculum_auth_service.dart)
- Apple: presente nel codice come pulsante e chiamata OAuth, ma non verificabile come completamente configurato nelle console esterne da questo repository.
  - Fonti: [lib/services/oculum_auth_ui.dart](lib/services/oculum_auth_ui.dart), [lib/services/oculum_auth_service.dart](lib/services/oculum_auth_service.dart)

## 5) Configurazioni mancanti nelle console esterne

- Supabase: mancanti i valori di configurazione richiesti dal codice per l’inizializzazione client, quindi la connessione non è verificabile da questo repository.
  - Fonti: [lib/main.dart](lib/main.dart), [docs/auth_and_cloud_saves/REQUIRED_ENVIRONMENT_VARIABLES.md](docs/auth_and_cloud_saves/REQUIRED_ENVIRONMENT_VARIABLES.md)
- Google Cloud: non verificabile da questo repository; il codice mostra il provider ma non indica che le credenziali/redirect siano già configurati.
  - Fonti: [lib/services/oculum_auth_service.dart](lib/services/oculum_auth_service.dart), [lib/services/oculum_auth_ui.dart](lib/services/oculum_auth_ui.dart)
- Apple Developer: non verificabile da questo repository; il codice mostra il provider ma non indica che Sign in with Apple sia già configurato a livello di provisioning/entitlements.
  - Fonti: [lib/services/oculum_auth_service.dart](lib/services/oculum_auth_service.dart), [lib/services/oculum_auth_ui.dart](lib/services/oculum_auth_ui.dart)

## 6) Configurazioni OAuth mancanti per piattaforme

- Android: non verificabile da questo repository; il codice non mostra redirect/callback/URL scheme già definiti.
  - Fonti: [lib/services/oculum_auth_service.dart](lib/services/oculum_auth_service.dart), [android/app/build.gradle.kts](android/app/build.gradle.kts)
- iOS: non verificabile da questo repository; mancano elementi di configurazione esterna visibili nel repo.
  - Fonti: [lib/services/oculum_auth_service.dart](lib/services/oculum_auth_service.dart), [ios/Runner/Info.plist](ios/Runner/Info.plist)
- Windows: non verificabile da questo repository; il repo non mostra configurazione OAuth specifica per desktop.
  - Fonti: [lib/services/oculum_auth_service.dart](lib/services/oculum_auth_service.dart), [windows/CMakeLists.txt](windows/CMakeLists.txt)
- macOS: non verificabile da questo repository; il repo non mostra configurazione OAuth specifica per desktop.
  - Fonti: [lib/services/oculum_auth_service.dart](lib/services/oculum_auth_service.dart), [macos/Runner/Info.plist](macos/Runner/Info.plist)
- Web: non verificabile da questo repository; il repo non mostra redirect origin/callback già definiti.
  - Fonti: [lib/services/oculum_auth_service.dart](lib/services/oculum_auth_service.dart), [web/index.html](web/index.html)

## 7) Package name / applicationId Android

- Android applicationId: com.example.oculum
  - Fonte: [android/app/build.gradle.kts](android/app/build.gradle.kts)

## 8) Bundle identifier iOS e macOS

- iOS bundle identifier: non verificabile in modo preciso dal repository; il valore presente in [ios/Runner/Info.plist](ios/Runner/Info.plist) va verificato nel progetto Xcode.
- macOS bundle identifier: non verificabile in modo preciso dal repository; il valore presente in [macos/Runner/Info.plist](macos/Runner/Info.plist) va verificato nel progetto Xcode.

## 9) Redirect URL, callback URL, URL scheme e deep link configurati

- Redirect URL / callback URL: non verificabili nel repository; il codice invoca OAuth tramite Supabase, ma non contiene URL concrete configurate nel repo.
  - Fonti: [lib/services/oculum_auth_service.dart](lib/services/oculum_auth_service.dart), [lib/main.dart](lib/main.dart)
- URL scheme: non verificabili nel repository.
  - Fonte: [ios/Runner/Info.plist](ios/Runner/Info.plist), [macos/Runner/Info.plist](macos/Runner/Info.plist)
- Deep link: non verificabili nel repository.
  - Fonte: [lib/services/oculum_auth_service.dart](lib/services/oculum_auth_service.dart)

## 10) GitHub Secrets o Variables richiesti dalle build

- Non sono presenti nel repository riferimenti a GitHub Actions Secrets o Variables per Supabase o OAuth.
  - Fonti: [.github/workflows/build_distribution.yml](.github/workflows/build_distribution.yml), [.github/workflows/build_macos.yml](.github/workflows/build_macos.yml)
- I workflow mostrano build standard ma non dichiarano secret/variables di runtime.

## 11) Comandi di build attualmente utilizzati per Android, Windows e macOS

- Android: flutter build apk --release
  - Fonte: [.github/workflows/build_distribution.yml](.github/workflows/build_distribution.yml)
- Windows: flutter build windows --release
  - Fonte: [.github/workflows/build_distribution.yml](.github/workflows/build_distribution.yml)
- macOS: flutter build macos --release
  - Fonte: [.github/workflows/build_distribution.yml](.github/workflows/build_distribution.yml), [.github/workflows/build_macos.yml](.github/workflows/build_macos.yml)

## 12) Workflow presenti in .github/workflows e cosa costruisce ciascuno

- [.github/workflows/build_distribution.yml](.github/workflows/build_distribution.yml)
  - Costruisce Windows, macOS, iOS unsigned e Android.
- [.github/workflows/build_macos.yml](.github/workflows/build_macos.yml)
  - Costruisce e valida il bundle macOS release, con eventuale pubblicazione di release GitHub.

## 13) Problemi che impedirebbero il login o la compilazione

- Variabili Supabase richieste dal codice non risultano configurate nel repository.
  - Fonte: [lib/main.dart](lib/main.dart)
- Il codice presenta provider Google/Apple ma non c’è evidenza nel repo di configurazione esterna completata.
  - Fonti: [lib/services/oculum_auth_service.dart](lib/services/oculum_auth_service.dart), [lib/services/oculum_auth_ui.dart](lib/services/oculum_auth_ui.dart)
- Android applicationId è ancora il valore di esempio com.example.oculum.
  - Fonte: [android/app/build.gradle.kts](android/app/build.gradle.kts)
- Non sono presenti nel repository riferimenti a secret/variables GitHub per Supabase/OAuth nelle build workflow.
  - Fonti: [.github/workflows/build_distribution.yml](.github/workflows/build_distribution.yml), [.github/workflows/build_macos.yml](.github/workflows/build_macos.yml)

## 14) Conclusione

### Indispensabile adesso
- Definire e fornire le variabili Supabase richieste dal codice.
- Completare la configurazione Google Cloud e Apple Developer esterna.
- Definire redirect/callback/URL scheme/deep link reali per le piattaforme target.

### Necessario prima della pubblicazione
- Sostituire l’applicationId Android di esempio con un valore reale.
- Verificare i bundle identifier iOS e macOS nei file di configurazione Xcode.
- Collegare eventuali secret/variables GitHub alle workflow di build.

### Facoltativo
- Aggiungere ulteriori provider di accesso oltre a Google/Apple/guest.
- Migliorare la UX di fallback offline e di recupero sessione.
