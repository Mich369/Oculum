# GitHub Actions — 14 settembre 2026

Commit pubblicato: `4d27e350913fc6a207f7058163bc69ae56158a02`.

## Problemi riscontrati

- Le ultime esecuzioni pubblicate erano riuscite, ma tutti e cinque gli
  artefatti della distribuzione del 3 settembre risultavano scaduti: durata 1 giorno.
- La release `oculum-macos-latest` non esisteva. Il passo di pubblicazione
  dipendeva soltanto da un input presente nell'avvio manuale, saltando i push.
- La verifica locale delle dipendenze usava una pipeline con `grep -q`, che
  può chiudere anticipatamente la pipe e far fallire il comando con `pipefail`.

## Correzioni

- Conservazione impostata a 30 giorni per tutti e sei gli upload.
- Pubblicazione macOS sui push; nell'avvio manuale resta rispettata la scelta
  di non pubblicare.
- Verifica delle dipendenze sul file prodotto da `flutter pub deps`.
- Durante la verifica reale, il test di connessione macOS ha rilevato un dominio
  non risolvibile. Il progetto Supabase esistente risultava `INACTIVE`.
  È stata avviata la riattivazione dello stesso progetto, senza modificare
  schema, dati, URL, credenziali o disattivare il test.

Sono stati pubblicati esclusivamente `.github/workflows/build_distribution.yml`
e `.github/workflows/build_macos.yml`. Le build remote usano i sorgenti già
presenti su GitHub; nessun altro sorgente locale, salvataggio o allegato è stato
incluso nel commit.

## Verifiche

- Actionlint 1.7.12: entrambi i workflow validi; checksum del validatore verificato.
  Shellcheck e pyflakes non eseguiti.
- Parsing YAML e controllo dei sei valori di retention superati.
- Controllati i casi push, avvio manuale con pubblicazione e avvio manuale senza.
- Il commit remoto contiene esattamente i due workflow previsti.

Esecuzioni di verifica:

- [Build distribution](https://github.com/Mich369/Oculum/actions/runs/34860177244):
  riuscita su Windows, Android, Linux, macOS e iOS. Tutti e cinque gli artefatti
  risultano disponibili fino al 14 ottobre 2026.
- [Crea e aggiorna macOS](https://github.com/Mich369/Oculum/actions/runs/34860177317):
  secondo tentativo riuscito, inclusi connessione Supabase, test Flutter,
  compilazione e pubblicazione della release.
- Supabase verificato nello stato `ACTIVE_HEALTHY` dopo la riattivazione.
- [Release macOS](https://github.com/Mich369/Oculum/releases/tag/oculum-macos-latest)
  pubblicata con `Oculum-macOS.zip` e `Oculum-macOS.sha256`.
- I 12 artefatti locali già aggiornati in `build/distribution` sono stati
  riverificati per dimensioni e SHA-256. Non sono cambiati i sorgenti applicativi
  in questo intervento; non è stata necessaria una nuova compilazione locale.

Riferimento: [contesto inputs di GitHub Actions](https://docs.github.com/en/enterprise-cloud%40latest/actions/reference/workflows-and-actions/contexts).
