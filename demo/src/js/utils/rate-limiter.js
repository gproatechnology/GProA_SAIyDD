const stores = new Map();

export function allowAction(key, limit = 10, windowMs = 60000) {
  const now = Date.now();
  const entry = stores.get(key) || { count: 0, resetAt: now + windowMs };
  if (now > entry.resetAt) {
    entry.count = 0;
    entry.resetAt = now + windowMs;
  }
  entry.count += 1;
  stores.set(key, entry);
  return entry.count <= limit;
}

export function getRemaining(key) {
  const entry = stores.get(key);
  if (!entry) return 0;
  const now = Date.now();
  if (now > entry.resetAt) {
    stores.delete(key);
    return 0;
  }
  return Math.max(0, 10 - entry.count);
}