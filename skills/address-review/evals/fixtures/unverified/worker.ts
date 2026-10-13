import type { LeaseStore } from "./lease-store";
export async function processJob(store: LeaseStore, jobId: string, run: () => Promise<void>) {
  const acquired = await store.tryAcquire(jobId, 30000);
  if (!acquired) return "busy";
  try {
    await run();
    return "done";
  } finally {
    await store.release(jobId);
  }
}
