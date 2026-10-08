import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

beforeEach(async () => {
  vi.stubEnv("VITE_SAIYDD_API_URL", "");
  vi.stubEnv("VITE_SAIYDD_API_TOKEN", "");
});

afterEach(() => {
  vi.unstubAllEnvs();
});

describe("api.getActivities", () => {
  it("returns activities without answer keys", async () => {
    const { api } = await import("../modules/api.js");
    const acts = await api.getActivities();
    expect(acts.length).toBeGreaterThan(0);
    for (const act of acts) {
      expect(act).not.toHaveProperty("correctIndices");
      expect(act.id).toBeTruthy();
      expect(Array.isArray(act.prompts)).toBe(true);
    }
  });
});

describe("api.submitAnswer", () => {
  it("validates visual activity answers", async () => {
    const { api } = await import("../modules/api.js");
    const ok = await api.submitAnswer("act_002", 0, 0);
    expect(ok.correct).toBe(true);
    expect(ok.correctOption).toBe("🔴");

    const bad = await api.submitAnswer("act_002", 0, 1);
    expect(bad.correct).toBe(false);
    expect(bad.correctOption).toBe("🔴");
  });

  it("validates memory activity by pair match", async () => {
    const { api } = await import("../modules/api.js");
    const ok = await api.submitAnswer("act_003", 0, 0);
    expect(ok.correct).toBe(true);

    const bad = await api.submitAnswer("act_003", 0, 1);
    expect(bad.correct).toBe(false);
  });

  it("returns incorrect for unknown activity", async () => {
    const { api } = await import("../modules/api.js");
    const res = await api.submitAnswer("unknown", 0, 0);
    expect(res.correct).toBe(false);
    expect(res.correctOption).toBe(null);
  });
});

describe("api.getProgress", () => {
  it("computes totals for a child", async () => {
    const { api } = await import("../modules/api.js");
    const p = await api.getProgress("child_001");
    expect(p.total).toBeGreaterThan(0);
    expect(typeof p.avg).toBe("number");
  });

  it("returns zeros for unknown child", async () => {
    const { api } = await import("../modules/api.js");
    const p = await api.getProgress("nobody");
    expect(p.total).toBe(0);
    expect(p.avg).toBe(0);
  });
});
