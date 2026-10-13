import { readInvoice } from "./repository";
import { withOrganization } from "./scope";
export const getInvoice = withOrganization(async (scope, invoiceId: string) => {
  const invoice = await readInvoice(scope, invoiceId);
  if (!invoice) return { status: 404, body: null };
  return { status: 200, body: invoice };
});
