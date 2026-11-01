# Pulizia verificata — 1/2 novembre 2026

La pulizia autorizzata ha rimosso soltanto cache ricostruibili, download incompleti e duplicati dimostrati. Dimensione logica totale: 11.609.882.715 byte (10.81 GiB).

| Categoria | File | Byte | Verifica |
|---|---:|---:|---|
| Cache Dart ricostruibile | 6 | 451638688 | Nessun compilatore attivo; sei file regolari vecchi, solo nella radice build. |
| Download interrotti non validi | 2 | 847249408 | Solo due ZIP incompleti non apribili; conservati quelli validi. |
| Vecchi ZIP di staging duplicati | 11 | 5071280407 | Ogni membro confrontato con la cartella Windows estratta conservata; SHA ricontrollati prima della rimozione. |
| Seconda copia data nei vecchi staging | 50479 | 5239714212 | 50479 file confrontati con windows/data dello stesso run, poi SHA di entrambe le copie ricontrollati; cartelle Windows complete e Windows Test conservate. |

Tutte le operazioni sono confinate ai percorsi assoluti verificati dentro build. La distribuzione attiva, tutti i backup, i salvataggi, le immagini originali/personali, i JSON e i pacchetti unici sono conservati. Negli staging obsoleti la copia completa rimane nella relativa cartella windows; le seconde copie data e gli ZIP equivalenti sono ricreabili da quella. Nessun processo dell’utente è stato chiuso.

Le ricevute dettagliate, con percorsi e SHA, sono nei quattro JSON build usati per questa tabella. Il rapporto descrive la pulizia locale e non certifica la pubblicazione della nuova patch.
