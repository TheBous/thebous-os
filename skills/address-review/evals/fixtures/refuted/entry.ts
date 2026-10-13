import { getInvoice } from "./route";
import type { Session } from "./scope";
export function handleRequest(session: Session | null, invoiceId: string) {
  return getInvoice(session, invoiceId);
}
