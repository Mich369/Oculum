# Consegna 641ec7ed — pacchetti locali verificati il 6 novembre

Fonte compilata: `641ec7ed6eb8bcfc0a737f6878b54b9dc2a0b30b`, run coordinato [42022970211](https://github.com/Mich369/Oculum/actions/runs/42022970211), numero versione Android verificato **100272**. Questo rapporto è successivo al congelamento; non viene presentato come parte del commit già compilato.

## Risultati conclusi

| Verifica | Esito effettivo |
|---|---|
| CI coordinata | Tutti i nove job riusciti, comprese le sette build e le cartelle Windows normale/Test separate. |
| Regressione completa CI | **2.275 test passati, 6 saltati, zero fallimenti**. Il precedente tentativo locale con sei fallimenti rimane documentato, seguito dalle correzioni delle fixture e delle aspettative. |
| Prove autenticate CI | **4 passate**, separate dalla suite ordinaria: Auth, isolamento cloud, realtime/ACK/riconnessione e combattimento/riposo con client automatizzati. Non sono tre dispositivi fisici o tre sessioni UI indipendenti. |
| Pages | Workflow [42029671211](https://github.com/Mich369/Oculum/actions/runs/42029671211) riuscito. I tre file pubblici verificati contengono il commit atteso. |
| Download pubblici | Publisher [42029670933](https://github.com/Mich369/Oculum/actions/runs/42029670933) riuscito automaticamente. **12 archivi** disponibili senza login, header ZIP e dimensioni corretti, SHA del catalogo/release uguali agli artifact della CI. Le richieste anonime di prova usano quattro byte, non un nuovo hash completo del payload anonimo. |
| Interfaccia Web | Avvio osservato nel browser integrato: log `641ec7ed` cumulativo da `b917217`, chiusura con clic esterno e assenza del log automatico al secondo avvio della stessa versione. Menu con dodici pulsanti attivi, Windows/Test e APK/AAB separati. Non cliccati tutti i grandi download nella sessione UI; gli URL sono verificati separatamente. |
| Archivio artwork locale | **2.410 alternative per 1.205 creature**, otto proposte ritirate e 29 revisioni storiche conservate. **4.820 SHA** e riferimenti controllati, nessun file o doppione selezionato mancante. Corretto un errore nei metadati di undici JPEG, senza alterare le immagini. |

Evidenze locali: `build/ci42022970211-validation-summary.json`, `build/ci42022970211-analyze-and-test.log`, `build/publication-641ec7ed-42022970211.json`, `build/web-ui-641ec7ed-20261105.json`, `build/AUDIT_MANIFEST_ARTWORK_FINALE_20261105.json`.

## Pacchetti locali — verifica conclusa, approvazione della consegna separata

La distribuzione attiva in `C:\Oculum App\oculum\build\distribution` contiene adesso la fonte `641ec7ed`: EXE completo di runtime alla radice, cartelle normali Windows e Windows Test separate, i due ZIP Windows, APK, AAB, macOS, IPA, Linux e Web. Nessun pacchetto Windows Test è inserito nell'edizione normale.

| Verifica locale del 6 novembre | Esito effettivo |
|---|---|
| Acquisizione | Tutti i **12 archivi originali** della CI scaricati, SHA-256 integrale su disco uguale al digest GitHub prima di estrarre; inventari estratti ricontrollati contro gli ZIP prima dello staging. Archivi originali conservati. |
| Staging | **16.803 file, zero differenze**, controllati prima dello swap. |
| APK prima dello swap | Firma crittografica verificata con certificato pubblico previsto, `com.mich.oculum`, versione esatta **100272**. SHA APK `39fcb674429a71da63558fb618ec87e43fe89f82f43328a6ffae0da8381a1d37`. Nessuna chiave privata creata o sostituita. |
| Dodici immagini canoniche | **132 confronti su 11 destinazioni, tutti identici**: tre runtime e otto pacchetti, compresi APK/AAB e tar Linux letto in streaming. Controllo concluso prima dello swap; il successivo controllo integrale certifica gli stessi file installati. |
| Installazione effettiva | Nuova lettura integrale dopo l'interruzione descritta sotto: **16.803 file, zero differenze**, commit `641ec7ed`. Non è soltanto una verifica dello staging. |
| Backup precedente | `build/distribution-backup-42022970211-20261106-052042271`, commit `2765a5df`; **16.639 file, zero differenze**, verificati integralmente dopo lo swap. |
| Download e Pages | Nuova prova del 6 novembre: **12 URL anonimi** validi, catalogo/release/digest CI concordi e commit Web corretto. Runtime normale/Test separati e copia completa della radice confrontati. Quattro byte per URL, non nuovi download anonimi integrali. |
| Avvio locale | EXE normale e Test avviati nascosti e ancora vivi dopo **8 secondi ciascuno**; terminati soltanto i due PID della prova. Backup preventivo di **62 file preesistenti** dei profili, nessuno di questi file cambiato, nessun ripristino o sovrascrittura dei salvataggi. Nessuna prova completa dei controlli grafici o di tre dispositivi fisici. |

Evidenze: `build/recovery-download-641ec7ed-20261106-01.log`, `build/install-recovery-641ec7ed-42022970211-20261106.log`, `build/android-signing-641ec7ed-42022970211-preswap.json`, `build/canonical-twelve-package-audit-641ec7ed-42022970211-preswap.json`, `build/distribution-reverification-after-pause-641ec7ed-20261106.log`, `build/distribution-backup-reverification-2765a5df-20261106.log`, `build/publication-runtime-641ec7ed-42022970211-20261106.json` e `build/startup-smoke-641ec7ed-42022970211-20261106-052644819.json`.

Durante la richiesta successiva di usare G, il tentativo di pausa è arrivato quando lo swap aveva già promosso i nuovi file. Un errore PowerShell non terminante nell'acquisizione del lock ha lasciato proseguire il comando che ha fermato il solo installer, durante la verifica successiva allo swap; la sua uscita resta **−1**, non viene dichiarata riuscita. È un errore del recupero locale, non della CI o del pacchetto. Non sono stati eliminati runtime o salvataggi. Dopo questo episodio, distribuzione attiva e backup sono stati nuovamente verificati per intero con gli esiti della tabella. La ricevuta `distribution-paused-for-G-641ec7ed-20261106.json` conteneva una dichiarazione errata sul lock: è esplicitamente superata da `build/distribution-pause-attempt-correction-641ec7ed-20261106.json` e dalle due riverifiche integrali.

Al passaggio di consegne non restano processi Python, Dart, Oculum o Oculum-Test di questa attività. I dodici ZIP inattivi occupano **10.634.274.295 byte**; la relativa cartella download completa contiene 14 file per **10.636.956.339 byte**. Inventario precedente al trasferimento: `build/inactive-artifact-archives-for-G-641ec7ed-20261106-sizes-v2.json`. I payload estratti sono stati trasferiti nell'installazione, quindi un futuro recupero dagli ZIP richiederà una nuova estrazione.

**Attività successiva del 6 novembre:** artwork, cartella download 641 e backup del 19 ottobre sono stati archiviati su G, con tre junction ai percorsi C: 31.098 file e 39,30 GiB, SHA/ADS/Git verificati. Distribuzione attiva e backup immediato restano cartelle ordinarie su C. [Rapporto separato STORAGE06](ARCHIVIAZIONE_DISCO_G.md); compatibilità dei quattro helper attivi verificata localmente dopo la consegna, con otto test Python dei percorsi e cinque controlli del filtro passati, distinti dalle prove di migrazione. Questa archiviazione non è una nuova prova UI della patch. Il 6 novembre l’utente ha poi approvato separatamente entrambe le righe: «Sì, consegna 641 approvata» e «Sì, STORAGE06 conclusa». Le due attività sono chiuse al 100% nei rispettivi perimetri verificati.

Il primo tentativo PowerShell è stato interrotto quando aveva già estratto quattro artifact; le cartelle sono conservate. L'indicazione iniziale di zero byte era insufficiente per concludere che il trasferimento fosse bloccato. Il successivo recupero seriale ha verificato l'APK ed è stato fermato intenzionalmente per passare a quattro trasferimenti con ripresa dei prefissi. Il recupero richiede SHA GitHub integrali prima di estrarre e conserva gli archivi originali. Queste interruzioni locali non sono fallimenti della CI o della pubblicazione.

## Comportamenti della patch

- Nuove schede con tre punti di Fortuna magica; saldi già salvati conservati. L'opzione per scheda propone la spesa dopo il tiro nei percorsi interattivi supportati, un punto per ogni +1 al totale. Corretti i controlli prima della spesa su richieste scadute/sostituite e controattacchi autenticati con token in ritardo.
- Pool ordinari di almeno nove Skill e due Open; tre Skill assegnate, Open generiche sorteggiate. Kit speciali e Open personali conservati. La successiva risposta «Mantieni fissa la Open personale» conferma il comportamento già compilato.
- Sette voci del Ghiaccio e dodici desktop già approvati collegati ai temi. Idrax con anatomia da serpente.
- Sedia e Ombrello, con varianti, ritirati da manuale attivo, nuove generazioni e Mercato Nero; schede e Occhi già salvati conservati. Rimane anche il ritiro precedente del Ragno degli Obser Falsi.

## Voti successivi al congelamento

[Registro delle scelte](SCELTE_ALTERNATIVE_MOSTRI_2026-11-05.json): Idrax Glaciale mantiene il precedente; FireShield mantiene il desktop C già distribuito; Mimic sceglie A, da integrare nella prossima revisione delle immagini. Questi voti non modificano retroattivamente il contenuto di `641ec7ed`.

Il filtro della galleria locale mostra per primo soltanto gli ID ancora da scegliere. Snapshot iniziale successivo al congelamento: 1.072 ancora da votare e 133 esclusi; dopo le ulteriori conferme del 6 novembre, il censimento incrementale è 1.060 ancora da scegliere e 145 esclusi, con 15 voti nel registro delle alternative. Tutte le alternative restano consultabili. Il censimento non sostituisce eventuali approvazioni testuali non ancora normalizzate. L'apertura della galleria `file:` è stata bloccata dal browser integrato: controlli di file/hash/filtri non vengono chiamati nuova prova visiva nel browser.

## Cosa può essere personalizzato

Saldo Fortuna e proposta dopo il tiro per ogni scheda; statistiche, Skill e Open assegnate; requisiti, costi reali, bersagli, elementi, Danni, effetti, durate e recuperi; equipaggiamento, immagini, temi, reliquie e anatomie personali. Gli editor e il JSON della scheda conservano le scelte. Un voto artistico non assegna nuovi bonus o drop. I percorsi specialistici e automatici non diventano tutti interattivi per deduzione.

**Consegna 641ec7ed conclusa al 100%** con la conferma esplicita «Sì, consegna 641 approvata». [Ricevuta](CONFERME_UTENTE_2026-11-06.json). Le nuove immagini e anatomie sono successive a questa build e mantengono verifiche e consegna separate.
