📝 Commento su `route.ts`: «getInvoice restituisce fatture di altre organizzazioni […] Aggiungi una verifica tenant.»

Il problema è confermato dal codice: `handleRequest` passa direttamente la sessione a `getInvoice`, che verifica solo che esista. `readInvoice` cerca esclusivamente per ID. Con una sessione di `org-a` e `invoice-b`, il percorso restituisce quindi `200` e la fattura di `org-b`, incluso il totale di 900. Non c’è un controllo dell’organizzazione nei tre file letti.

💡 Propongo di estendere la condizione in `getInvoice` a `!invoice || invoice.organizationId !== session.organizationId`, restituendo `404` in entrambi i casi. È una modifica circoscritta che impedisce di restituire fatture di altre organizzazioni e non ne rivela l’esistenza; le fatture della propria organizzazione continuano a restituire `200`, mentre una sessione assente restituisce `401`.

Approvi questa modifica? La skill address-review richiede l’approvazione esplicita della proposta prima di applicarla. Non ho modificato il codice né contattato servizi.
