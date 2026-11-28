# Installare e aggiornare Oculum

I [download pubblici](https://github.com/Mich369/Oculum/releases/tag/oculum-downloads) non richiedono un account GitHub. Il menu Download della [versione web](https://mich369.github.io/Oculum/) rimanda agli stessi pacchetti verificati. La versione normale e Windows Test sono distribuzioni separate.

## Aggiornamento dall’app

Salva la sessione e usa **Aggiorna Oculum**. Su Windows puoi vedere quali file cambiano e la dimensione del download prima di scegliere **Scarica le modifiche**. Il confronto controlla i file presenti anche se hai saltato più versioni. Puoi scegliere **Pacchetto intero** dalla stessa finestra. Chiudi anche eventuali altre finestre di Oculum che usano la stessa cartella. L’aggiornamento le attende e conserva un backup del runtime. Conferma il successo quando la nuova app ha aperto il primo fotogramma con il commit e l’edizione attesi.

Un messaggio di download completato non prova che la versione sia stata sostituita. Se l’aggiornamento non termina, riapri l’app dalla cartella verificata e controlla la versione; puoi riprovare. Conserva il backup e la cartella precedente fino alla verifica dei tuoi salvataggi e delle immagini personalizzate.

## Versioni Windows precedenti

Per una versione precedente, apri i download ufficiali e cerca **Aggiornamento incrementale per installazioni Windows esistenti**. Estrai il suo ZIP in una cartella dedicata. Da PowerShell avvia lo script indicando il tuo EXE. Sostituisci il percorso con quello effettivo. Lo script mostra l’anteprima prima di scaricare il contenuto.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Oculum-Aggiornamento-Incrementale.ps1 -Executable 'C:\Oculum\oculum.exe'
```

Per Windows Test indica `Oculum-Test.exe` dalla sua cartella. Aggiungi `-DryRun` per consultare il piano senza installare. Se il manifest della versione precedente manca, l’aggiornamento conserva i file rimasti fuori dal nuovo elenco. I download completi restano compatibili con le versioni precedenti.

In questo caso scarica il pacchetto Windows completo ed estrailo **in una nuova cartella**, poi avvia l’EXE da lì. Conserva tutta la cartella con `data` e le DLL: l’EXE isolato non basta. Apri l’edizione che usavi prima; Windows Test mantiene un profilo separato. Conserva la vecchia cartella, soprattutto se contiene immagini personalizzate collegate tramite percorso assoluto.

## Android

Per installare o aggiornare scegli **Oculum-Android**, che contiene l’APK e il rapporto di compatibilità della firma. La pagina pubblica e il menu web includono anche **Oculum-Android-AAB** per lo store, **Oculum-UI-Catture** e **Oculum-Verifica-Mostri**, in archivi separati.

Apri l’APK verificato e conferma l’aggiornamento nel programma di installazione Android. L’aggiornamento diretto richiede lo stesso identificativo applicazione, lo stesso certificato di firma e un codice versione ammesso dal dispositivo. I nuovi APK usano la firma stabile del progetto.

Un vecchio APK firmato con una chiave diversa non può essere sostituito mantenendo i dati tramite il normale aggiornamento Android. **Non disinstallarlo prima di aver esportato e controllato il backup delle schede e delle immagini.** Un’eventuale reinstallazione richiede poi il ripristino del backup e potrebbe richiedere nuovamente l’accesso online. Il progetto non può recuperare una vecchia chiave privata mancante.

## Altre piattaforme

Su macOS e Linux l’aggiornamento automatico attuale richiede Python3; in alternativa usa il pacchetto completo della piattaforma. Il pacchetto iOS indicato come non firmato non è un’app installabile direttamente su tutti gli iPhone: richiede firma e distribuzione appropriate. Sul web salva prima di ricaricare la versione aggiornata.

Le note della patch sono nel [registro cumulativo](REGISTRO_AGGIORNAMENTI.md). Costi, requisiti, statistiche, Skill, Art, Titoli e temi personalizzati restano modificabili negli editor e nel JSON: l’aggiornamento del catalogo non deve sovrascrivere le personalizzazioni salvate.
