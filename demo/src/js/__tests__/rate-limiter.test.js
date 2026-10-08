import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { allowAction, getRemaining } from "../utils/rate-limiter.js";

describe("allowAction", () => {
  beforeEach(() => vi.useFakeTimers());
  afterEach(() => vi.useRealTimers());

  it("allows up to the limit then blocks", () => {
    for (let i = 0; i < 3; i++) {
      expect(allowAction("limit-test", 3, 60000)).toBe(true);
    }
    expect(allowAction("limit-test", 3, 60000)).toBe(false);
    expect(getRemaining("limit-test")).toBe(0);
  });

  it("resets after the time window", () => {
    expect(allowAction("reset-test", 1, 1000)).toBe(true);
    expect(allowAction("reset-test", 1, 1000)).toBe(false);
    vi.advanceTimersByTime(1001);
    expect(allowAction("reset-test", 1, 1000)).toBe(true);
  });

  it("tracks remaining actions within the window", () => {
    allowAction("remaining-test", 5, 60000);
    allowAction("remaining-test", 5, 60000);
    expect(getRemaining("remaining-test")).toBe(3);
  });

  it("uses independent counters per key", () => {
    expect(allowAction("key-1", 1, 60000)).toBe(true);
    expect(allowAction("key-1", 1, 60000)).toBe(false);
    expect(allowAction("key-2", 1, 60000)).toBe(true);
  });
});
