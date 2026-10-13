Il commento è **confutato dal codice corrente**. Non serve aggiungere il confronto nel route handler.

Il percorso completo è questo:

- `entry.ts:3-4` passa la sessione a `getInvoice`.
- `route.ts:3` avvolge il gestore con `withOrganization`. In `scope.ts:5-6` il wrapper respinge una sessione assente con 401 e costruisce lo scope usando `session.organizationId`.
- `route.ts:4` passa quello scope a `readInvoice`. In `repository.ts:8` la ricerca richiede sia l’ID della fattura sia `invoice.organizationId === scope.organizationId`.

Quindi una sessione di `org-a` che richiede `invoice-b` non trova alcuna fattura: la fattura appartiene a `org-b` (`repository.ts:5`) e il gestore restituisce **404 con body null** (`route.ts:5`). Il confronto esiste nel repository e si applica anche a questa richiesta.

Propongo di mantenere il codice e spiegare al reviewer queste evidenze. Il verdetto previsto è `not-fixed`, nel senso che non occorre alcuna modifica perché il problema segnalato non si verifica; non rappresenta un bug rimasto aperto. Non ho modificato codice né contattato servizi.
