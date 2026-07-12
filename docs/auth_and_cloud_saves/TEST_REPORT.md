# Verifica autenticazione e cloud save

Verifica locale del 2026-07-11:

- `flutter pub get`: riuscito.
- `dart format` sui soli file Dart modificati: riuscito.
- `flutter analyze`: nessun problema.
- `flutter test`: 117 test superati.
- test auth/cloud mirati: 16 superati.
- parsing YAML dei due workflow: riuscito.
- parsing AndroidManifest e Info.plist: riuscito.
- `flutter build windows --release`: riuscito.
- `flutter build apk --release`: riuscito.
- `flutter build web --release`: riuscito, incluso Wasm dry run.

macOS e iOS non sono compilabili sul runner Windows locale; i relativi comandi
sono presenti nei workflow macOS GitHub Actions. I test non contattano Supabase
né provider reali.
