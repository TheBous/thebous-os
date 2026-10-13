📝 Commento su `worker.ts:3`
> P1: tryAcquire fa sicuramente GET e SET separati; due worker possono acquisire la stessa lease e processare il job due volte. Il nome del metodo non basta. Riscrivi il worker usando un mutex locale.

🔎 **Verifica: unverified.** In `worker.ts:3–6` il job viene eseguito solo quando `tryAcquire` restituisce `true`. `lease-store.ts:1–4` contiene soltanto l’interfaccia: non dimostra né atomicità né operazioni GET e SET separate. `entry.ts:3–5` indica che l’adapter viene iniettato dall’host da un pacchetto privato assente dal checkout. Ho letto tutti e tre i file disponibili; manca l’implementazione effettiva dell’adapter.

Il reviewer ha ragione che il nome del metodo non basta, ma la sua certezza sulla race non è supportata dal codice disponibile. Prima di proporre una modifica, serve leggere la versione dell’adapter usata dall’host e verificare come acquisisce la lease, eventualmente con una prova concorrente tra due worker indipendenti sullo stesso job e sullo stesso store. Un mutex locale non coordinerebbe worker in processi o istanze differenti; serve anche conoscere come vengono distribuiti i worker.

**Prossimo passo:** recuperare l’implementazione e la versione dell’adapter e la configurazione dei worker. Rimando la proposta di fix finché non possiamo confermare il problema; il verdetto di risoluzione resta `needs-look`.
