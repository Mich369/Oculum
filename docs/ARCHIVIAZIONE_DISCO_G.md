# Oculum: archiviazione selettiva su G — 6 novembre 2026

Il progetto continua ad aprirsi da `C:\Oculum App\oculum`. Tre cartelle pesanti risiedono ora su `G:\Oculum-Progetto\oculum`; nei rispettivi percorsi C restano junction NTFS verso le copie verificate su G. Non è il trasferimento integrale del repository: sorgenti Flutter, `lib`, `assets`, Git, salvataggi e distribuzione attiva non sono stati spostati da questa operazione.

G è un disco dati fisso NTFS su un SSD fisico distinto da quello di C. Il controllo locale delle partizioni associa C al disco 1 e G al disco 0; entrambi i supporti risultano SSD SATA.

## Cartelle trasferite

| Percorso usato su C, ora junction | Destinazione fisica su G | File | Byte |
|---|---|---:|---:|
| `C:\Oculum App\oculum\output\artwork` | `G:\Oculum-Progetto\oculum\output\artwork` | 12.551 | 6.972.047.507 |
| `C:\Oculum App\oculum\build\distribution-download-42022970211-python-641ec7ed` | `G:\Oculum-Progetto\oculum\build\distribution-download-42022970211-python-641ec7ed` | 14 | 10.636.956.339 |
| `C:\Oculum App\oculum\build\distribution-backup-20261019-115907` | `G:\Oculum-Progetto\oculum\build\distribution-backup-20261019-115907` | 18.533 | 24.586.162.964 |
| **Totale** | | **31.098** | **42.195.166.810** |

Il totale logico trasferito è **39,30 GiB**. Nello snapshot successivo alle tre migrazioni C aveva **101.002.686.464 byte liberi, circa 94,07 GiB**, e G **60.817.510.400 byte, circa 56,64 GiB**. Sono valori rilevati il 6 novembre, soggetti alle successive scritture del sistema; non rappresentano una riserva fissa.

I quattordici file della cartella download comprendono i dodici ZIP originali della CI e i relativi metadati rimasti. I pacchetti sono conservati, non eliminati. Il backup del 19 ottobre è ancora disponibile tramite il suo percorso storico C, oltre alla destinazione fisica G.

Restano cartelle ordinarie su C:

- `C:\Oculum App\oculum\build\distribution`, distribuzione attiva `641ec7ed`, con EXE completo, Windows e Windows Test separati, ZIP, APK e altri pacchetti;
- `C:\Oculum App\oculum\build\distribution-backup-42022970211-20261106-052042271`, backup immediato `2765a5df`;
- la radice del progetto, i sorgenti e gli asset dell'app, con i percorsi di salvataggio esistenti conservati.

## Verifiche effettive

Le tre esecuzioni reali risultano `stage: complete`, `passed: true`, con uscita 0. Per ciascuna: piano vincolato al proprio SHA-256, copia senza mirror, confronto di struttura, contenuti e stream NTFS ADS, verifica attraverso la junction e confronto dello stato Git prima e dopo. Le directory vuote sono state conservate. La copia temporanea C è stata rimossa soltanto dopo i controlli e limitatamente ai file censiti nel manifest; non restano directory temporanee `.__C_before_G_20261106` dei tre trasferimenti.

Prima delle migrazioni sono passati **dieci casi isolati sul filesystem più un caso aggiuntivo sulla sostituzione atomica del journal: undici in totale**. Coprono copia/hash, stream ADS, directory vuote, rifiuto di contenuti e stream corrotti, lettura della junction, rifiuto di collegamenti inattesi, rollback, ripresa di cleanup parziale e rimozione limitata alla copia verificata. Sono prove con fixture sintetiche; la revisione indipendente del migratore è statica e distinta dalle esecuzioni del coordinatore.

Due problemi preliminari di PowerShell 5 sono stati corretti prima delle esecuzioni riuscite: `Get-FileHash` rifiutava la sintassi con due punti degli stream ADS, ora letti e verificati con un handle nativo in sola lettura; `File.Replace` riceveva una stringa vuota al posto di null, ora passato come `[NullString]::Value`, con regressione dedicata sul journal. Il primo tentativo relativo a quest'ultimo problema si era fermato prima della copia e delle rinomine, conservando la sorgente.

Evidenze locali:

- [Risultato artwork](../build/storage-G-20261106/artwork.result.json), [piano con hash dei file](../build/storage-G-20261106/artwork.plan.json) e [log copia](../build/storage-G-20261106/artwork.robocopy.log).
- [Risultato download 641](../build/storage-G-20261106/downloads641.result.json), [piano](../build/storage-G-20261106/downloads641.plan.json) e [log copia](../build/storage-G-20261106/downloads641.robocopy.log).
- [Risultato backup storico](../build/storage-G-20261106/backup20261019.result.json), [piano](../build/storage-G-20261106/backup20261019.plan.json) e [log copia](../build/storage-G-20261106/backup20261019.robocopy.log).
- [Undici prove filesystem](../build/storage-G-selftest-20261106.json) e [revisione indipendente con limiti espliciti](../build/REVIEW_MIGRATORE_G_20261106.json).

Queste prove non sono nuovi test Flutter, una nuova CI, una nuova pubblicazione o una nuova prova dell'interfaccia e delle sessioni online. I riscontri della patch già installata restano nel [rapporto 641ec7ed](CONSEGNA_VERIFICATA_641ec7ed.md).

## Artwork futuri e compatibilità dei percorsi

I nuovi originali ImageGen continuano su `G:\Oculum-Artwork`, nella sottocartella del lotto. Gallerie, anteprime, ricevute e proposte del progetto continuano a usare il percorso logico `C:\Oculum App\oculum\output\artwork`, ora collegato alla cartella su G. Le immagini non sono state ridisegnate né rese canoniche da questa migrazione; i loro voti restano separati.

**Compatibilità verificata per i quattro entrypoint attivi.** Il problema di `Path(__file__).resolve()`, che dopo la junction poteva cercare il repository sotto G, è corretto separando la radice logica C dalla posizione fisica delle immagini. Il risolutore condiviso [oculum_artwork_paths.py](../scripts/oculum_artwork_paths.py) è usato da `aggiorna_alternative.py`, `aggiorna_galleria.py`, `audit_approved_runtime_copies.py` e `refresh_creature_art_backlog.py`. Le quattro modifiche sono censite con gli SHA precedenti e successivi nel [rapporto dei file modificati](../build/ARTWORK_PATHFIX4_CHANGES_20261106.json).

Sono passati **otto test Python dei percorsi su Windows**, distinti dagli undici test filesystem del migratore, e **cinque controlli del filtro**. Il refresh è stato invocato realmente dal percorso fisico G con `--metadata-only`: **6.038 collegamenti validi, nessuno mancante**, SHA del manifest e delle **2.447 ricevute invariati**. [Test dei percorsi](../scripts/tests/test_oculum_artwork_paths.py), [esito dei cinque filtri](../build/TEST_SCELTE_FILTER_20261105.json) e [audit finale](../build/AUDIT_ARTWORK_PATHFIX_AMMASSO_20261106.json).

Il controllo è locale su percorsi, HTML e metadati; non è un nuovo rendering osservato nel browser o nell'app. Non sono state ricalcolate tutte le immagini in questo passaggio: l'audit dichiara espressamente `allImagesRehashed: false` e usa le verifiche integrali precedenti per i binari invariati. La correzione riguarda i quattro entrypoint elencati; non attesta l'esecuzione di tutti i builder storici. Le nuove proposte native C su G sono successive e separate dal manifest e dalle ricevute storiche conservate.

Il migratore locale [oculum_storage_to_G_20261106.ps1](../build/oculum_storage_to_G_20261106.ps1) ammette soltanto i tre identificativi `artwork`, `downloads641`, `backup20261019`. Percorsi e ambito sono definiti da `$Repo`, `$Storage` e `$Allowed`; ogni altro trasferimento richiede un piano dedicato, verifica della capienza con riserva e controllo del suo SHA. Non è una nuova impostazione di gameplay e non autorizza a spostare altre cartelle in modo automatico.

## Ripristino su C, se richiesto in futuro

Le indicazioni seguenti sono una procedura da preparare e verificare; **nessun ripristino è stato eseguito**.

1. Fermare i processi che scrivono nella cartella interessata e controllare lo spazio C necessario. Censire lo stato corrente su G, inclusi file aggiunti dopo la migrazione, con SHA, stream ADS e directory vuote; non usare alla cieca il vecchio manifest se i dati sono cambiati.
2. Copiare la cartella G in una nuova directory ordinaria temporanea su C, conservando dati, attributi, date e ADS. Non usare mirror, spostamenti distruttivi o cancellazioni della sorgente G.
3. Verificare integralmente la copia C contro il censimento corrente G. Confermare che il vecchio percorso C sia ancora esattamente la junction attesa verso quella destinazione G.
4. Solo dopo la verifica, rimuovere **il collegamento C**, senza ricorsione e senza seguire la destinazione. La rimozione va limitata alla junction validata; non utilizzare `Remove-Item -Recurse` sul percorso collegato. Rinominare poi la copia C verificata con il nome storico previsto.
5. Controllare lettura, gallerie e helper interessati dal percorso ripristinato. Conservare i dati G fino alla conclusione delle prove e a un'eventuale autorizzazione distinta per eliminare duplicati.

Le verifiche locali di **STORAGE06 sono complete per questo perimetro**: migrazioni, compatibilità dei quattro helper attivi e controlli dei metadati. La chiusura al 100% è stata approvata dall’utente con «Sì, STORAGE06 conclusa», il 6 novembre. [Ricevuta delle conferme](CONFERME_UTENTE_2026-11-06.json).
