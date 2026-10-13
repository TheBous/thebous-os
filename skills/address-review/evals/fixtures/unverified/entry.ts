import type { LeaseStore } from "./lease-store";
import { processJob } from "./worker";
// The host injects the adapter from a private package, not included in this checkout.
export function createWorker(store: LeaseStore) {
  return (id: string, run: () => Promise<void>) => processJob(store, id, run);
}
