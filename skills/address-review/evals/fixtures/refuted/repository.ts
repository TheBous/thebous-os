import type { OrganizationScope } from "./scope";
type Invoice = { id: string; organizationId: string; total: number };
const invoices: Invoice[] = [
  { id: "invoice-a", organizationId: "org-a", total: 100 },
  { id: "invoice-b", organizationId: "org-b", total: 900 },
];
export async function readInvoice(scope: OrganizationScope, id: string) {
  return invoices.find((invoice) => invoice.id === id && invoice.organizationId === scope.organizationId);
}
