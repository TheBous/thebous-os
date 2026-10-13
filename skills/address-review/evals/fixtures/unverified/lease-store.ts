export interface LeaseStore {
  tryAcquire(key: string, ttlMs: number): Promise<boolean>;
  release(key: string): Promise<void>;
}
