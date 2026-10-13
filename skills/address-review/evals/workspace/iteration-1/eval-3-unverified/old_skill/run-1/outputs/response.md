📝 Commento su `worker.ts:3`
> «P1: tryAcquire fa sicuramente GET e SET separati; due worker possono acquisire la stessa lease e processare il job due volte. Il nome del metodo non basta. Riscrivi il worker usando un mutex locale.»

Ho letto tutti e tre i file del fixture. Il worker chiama `store.tryAcquire`, ma `lease-store.ts` espone soltanto un’interfaccia. `entry.ts` dice che l’adapter viene iniettato dall’host da un pacchetto privato assente dal checkout. Quindi non possiamo stabilire se l’acquisizione sia atomica: l’affermazione su GET e SET separati resta da verificare.

Un mutex locale protegge soltanto le esecuzioni che condividono quel mutex nello stesso processo; non risolve la concorrenza tra worker in processi o host diversi.

💡 Proposta: classificare provvisoriamente l’item come ❓ `needs-look` e verificare l’implementazione concreta dell’adapter, insieme alla topologia dei worker. Se l’acquisizione risulta non atomica, correggerla nello store condiviso con un’operazione atomica appropriata al backend. Prima di proporre una patch serve il sorgente dell’adapter o una prova delle sue garanzie di concorrenza.

Vuoi procedere recuperando queste informazioni? La skill address-review, step 7, richiede il tuo accordo sulla proposta prima di applicare modifiche.
