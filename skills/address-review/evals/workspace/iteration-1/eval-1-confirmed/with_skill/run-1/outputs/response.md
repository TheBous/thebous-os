📝 Commento su `route.ts`: «getInvoice restituisce fatture di altre organizzazioni […] Basta conoscere invoice-b mentre si è in org-a.»

🔎 **Verifica: confirmed.** Il problema è raggiungibile nel codice corrente:

- [entry.ts:2](/Users/lucvalse/lucvalse/personal/thebous-os/skills/address-review/evals/fixtures/confirmed/entry.ts:2) inoltra sessione e identificativo direttamente a `getInvoice`, senza un controllo tenant.
- [route.ts:4](/Users/lucvalse/lucvalse/personal/thebous-os/skills/address-review/evals/fixtures/confirmed/route.ts:4) verifica soltanto che la sessione esista; alla riga 5 passa al repository solo `invoiceId`.
- [repository.ts:7](/Users/lucvalse/lucvalse/personal/thebous-os/skills/address-review/evals/fixtures/confirmed/repository.ts:7) cerca esclusivamente per `id`. La fattura `invoice-b` appartiene a `org-b` (riga 4).
- Con una sessione di `org-a` e `invoiceId = "invoice-b"`, la ricerca restituisce quella fattura; [route.ts:7](/Users/lucvalse/lucvalse/personal/thebous-os/skills/address-review/evals/fixtures/confirmed/route.ts:7) risponde `200` includendola. Nei tre file del repository non ci sono altri guard che impediscano questo percorso.

💡 Propongo di estendere il controllo alla riga 6: restituire `404` se la fattura manca **oppure** se `invoice.organizationId !== session.organizationId`. Questo blocca la divulgazione e mantiene la stessa risposta per fatture assenti o appartenenti a un'altra organizzazione.

Approvi questa modifica? La skill [address-review](/Users/lucvalse/lucvalse/personal/thebous-os/skills/address-review/SKILL.md), step 7, richiede il tuo consenso esplicito prima di cambiare il codice. La verifica deriva dalla lettura del percorso completo; non ho eseguito test né modificato il fixture.
