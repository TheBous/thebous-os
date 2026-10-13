export type Session = { userId: string; organizationId: string };
export type OrganizationScope = { organizationId: string };
export function withOrganization<T>(handler: (scope: OrganizationScope, id: string) => Promise<T>) {
  return async (session: Session | null, id: string) => {
    if (!session) return { status: 401, body: null };
    return handler({ organizationId: session.organizationId }, id);
  };
}
