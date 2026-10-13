import { getInvoice, type Session } from "./route";
export function handleRequest(session: Session | null, invoiceId: string) {
  return getInvoice(session, invoiceId);
}
