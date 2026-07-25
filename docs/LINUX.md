# Oculum su Linux

La distribuzione Linux ufficiale viene prodotta dal job GitHub Actions
`Build Linux` come artifact `Oculum-Linux`.

## Avvio

1. Scaricare l'artifact `Oculum-Linux` da GitHub Actions, non il solo script
   `package_linux_release.sh`.
2. Aprire lo ZIP dell'artifact e prendere `Oculum-Linux-x64.tar.gz`.
3. Estrarre l'intero archivio `.tar.gz`.
4. Eseguire `./Avvia-Oculum.sh` dalla cartella estratta.

Lo script `scripts/package_linux_release.sh` serve agli sviluppatori che hanno
scaricato l'intero progetto. Se la build non esiste, ora esegue automaticamente:

```bash
flutter config --enable-linux-desktop
flutter pub get
flutter build linux --release
```

Se Flutter non è installato, bisogna utilizzare l'artifact già pronto prodotto
da GitHub Actions.

## Pacchetto portatile senza Flutter

`build/distribution/Oculum-Linux-Portable-Web.zip` può essere trasferito
direttamente a un utente Linux. Dopo averlo estratto completamente basta:

```bash
bash Avvia-Oculum-Linux.sh
```

Questa variante usa il browser locale e richiede soltanto Python 3. Mantiene
sempre lo stesso indirizzo `http://127.0.0.1:8765`, così i salvataggi del
browser restano associati allo stesso sito. Non bisogna cancellare i dati del
sito del browser; è comunque consigliato esportare periodicamente le schede.

Non bisogna spostare soltanto l'eseguibile `oculum`: il programma richiede
anche le cartelle `lib` e `data` presenti nel bundle.

## Distribuzioni supportate

Il pacchetto è compilato per Linux desktop x86_64 e viene verificato su Ubuntu.
Su Ubuntu, Debian e Linux Mint le librerie runtime possono essere installate con:

```bash
sudo apt update
sudo apt install libgtk-3-0 libsecret-1-0 liblzma5
```

Il browser interno non è disponibile su Linux. Le mappe e i collegamenti online
vengono aperti nel browser di sistema, senza impedire l'uso locale dell'app.

## Protezione dei dati

Il supporto Linux non cambia lo schema dei salvataggi. I dati vengono conservati
nel profilo dell'utente tramite `shared_preferences`; eventuali errori dei
servizi online non impediscono l'avvio in modalità locale.
