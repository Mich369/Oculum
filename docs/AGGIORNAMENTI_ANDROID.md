# Aggiornare Android conservando dati e accesso

L'aggiornamento diretto richiede lo stesso identificativo `com.mich.oculum`, un codice versione crescente e una firma compatibile con l'app installata. La build GitHub usa il keystore stabile già presente nei segreti del repository; non genera una nuova chiave a ogni build. Il certificato pubblico atteso è conservato in `android/signing-certificate.sha256`. Il controllo Gradle e `scripts/verify_android_signing.py` impediscono di distribuire accidentalmente una firma diversa. Nessuna chiave privata o password fa parte del repository o dei pacchetti.

Un aggiornamento Android compatibile conserva i dati dell'app: salvataggi, personalizzazioni e sessione locale ricordata. Questo non certifica da solo la connessione online effettiva, che va provata separatamente. La preferenza di non ricordare l'accesso continua a essere rispettata.

Se la vecchia app GitHub fu firmata con una chiave precedente non più disponibile, non è possibile ricreare quella chiave dall'APK. La chiave stabile attuale esiste dal 23 ottobre 2026; non è ancora stato letto il certificato dell'app sul telefono dell'utente, quindi la compatibilità con quella specifica installazione resta da verificare.

Prima di un'eventuale reinstallazione, esportare i salvataggi fuori dallo spazio dell'app e verificare di poter rientrare nello stesso account. **Disinstallare cancella i dati locali e può far perdere l'identità online anonima**: il solo JSON non recupera la sessione o l'identità di Supabase. Non disinstallare come tentativo di aggiornamento quando i backup e il recupero dell'accesso non sono verificati.

Le versioni successive alla prima installazione con la chiave stabile potranno aggiornarsi mantenendo firma, identificativo e versioni crescenti. Il controllo dell'updater resta attivo contro firma errata, pacchetto diverso o downgrade.

Riferimento: [firma e aggiornamenti Android](https://developer.android.com/studio/publish/app-signing).
