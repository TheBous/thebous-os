📝 Commento su `route.ts`: il reviewer sostiene che una sessione di `org-a` possa leggere `invoice-b`, appartenente a `org-b`.

Il codice fornito smentisce questo caso. `entry.ts` passa la sessione a `getInvoice`; `withOrganization` in `scope.ts` ricava `scope.organizationId` dalla sessione e restituisce 401 se manca. `route.ts` passa questo scope a `readInvoice`, che in `repository.ts` cerca contemporaneamente per ID e organizzazione:

```ts
invoice.id === id && invoice.organizationId === scope.organizationId
```

Con sessione `org-a` e ID `invoice-b`, la ricerca restituisce `undefined` e il route handler risponde 404. È una conclusione dalla lettura del percorso completo; non ho eseguito test.

💡 Propongo di mantenere il codice attuale e spiegare al reviewer dove viene applicato il filtro. Aggiungere il confronto nel handler sarebbe ridondante. La preoccupazione risulta già coperta dal codice corrente (`fixed` nella rubric), senza una modifica applicata in questa sessione.

Bozza di risposta GitHub:
> ✅ Fixed — Organization isolation is already enforced by readInvoice using the scope derived from the session. An org-a session requesting invoice-b receives 404.

Sei d'accordo con questa risposta? Mi fermo qui come richiesto, senza modifiche né accessi ai servizi. Lo step 7 della [skill address-review](/Users/lucvalse/lucvalse/personal/thebous-os/skills/address-review/evals/workspace/skill-snapshot/SKILL.md) richiede di discutere fino a convergere su un'azione, che può essere «don't change anything».
