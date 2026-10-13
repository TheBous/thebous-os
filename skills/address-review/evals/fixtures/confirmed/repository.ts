export type Invoice = { id: string; organizationId: string; total: number };
const invoices: Invoice[] = [
  { id: "invoice-a", organizationId: "org-a", total: 100 },
  { id: "invoice-b", organizationId: "org-b", total: 900 },
];
export async function readInvoice(id: string): Promise<Invoice | undefined> {
  return invoices.find((invoice) => invoice.id === id);
}
