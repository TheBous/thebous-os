import { readInvoice } from "./repository";
export type Session = { userId: string; organizationId: string };
export async function getInvoice(session: Session | null, invoiceId: string) {
  if (!session) return { status: 401, body: null };
  const invoice = await readInvoice(invoiceId);
  if (!invoice) return { status: 404, body: null };
  return { status: 200, body: invoice };
}
