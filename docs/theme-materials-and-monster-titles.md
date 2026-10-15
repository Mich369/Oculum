# Materiali, vita e titoli dei mostri

## Materiali e livelli

La texture condivisa occupa tutta l'area disponibile: vale per legno, cenere e le altre famiglie. Le texture restano ripetute alla scala prevista, mentre la scena decorativa di fondo usa un livello separato a copertura dell'area. I livelli decorativi ignorano il puntatore e non intercettano i pulsanti.

Restano configurabili tema, colori e preferenze di movimento esistenti. Non vengono spostati i controlli. I test verificano dimensioni della texture e clic sui pulsanti per legno e cenere.

## Vita e sottotratti

- La tinta della vita varia continuamente con la percentuale, conservando lo stile della barra scelto.
- Le variazioni della barra sono interpolate; le preferenze di movimento ridotto o disattivato vengono rispettate.
- La nuova scheda mostra la vita recuperabile di Ricordo Vitale accanto alla vita e sulla barra, senza rivelarla quando la vita è nascosta.
- I sottotratti sono ordinati alfabeticamente in due colonne verticali. I controlli dei punti sono richiudibili. Il colore segue la statistica; Fortuna è oro, quelli senza statistica sono grigi.

## Titoli delle nuove creature

Le nuove schede delle creature idonee ricevono tre titoli modificabili. Gli Erranti e le creature Chaos ricevono una scelta specifica, con il primo titolo inizialmente visibile:

| Titolo Chaos | Beneficio | Penalità |
|---|---|---|
| Dove il mondo sbaglia | VC +2 | CM -1 |
| Senza un ieri | Difesa +4 | VC -1 |
| Ospite dell'ultima stanza | Danni +4 | CM -1 |

Esistono anche assortimenti per creature aeree, corazzate e altre creature. Le formule si attivano solo mentre il titolo è equipaggiato e visibile. Le leggende descrivono conseguenze narrative; non aggiungono automatismi nascosti. Le regole preesistenti dei punti del titolo visibile restano applicate. I titoli salvati e personalizzati non vengono sovrascritti.

La generazione delle schede controlla le abilità effettivamente disponibili, comprese quelle derivate dal catalogo, invece di cancellarle solo perché la lista grezza degli ID è vuota. Le creature esplicitamente prive di poteri restano tali.

Questa patch non rende automaticamente unico ogni kit del catalogo: alcune famiglie di tecniche condividono ancora meccaniche.
