import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const BASE = "http://127.0.0.1:8000";

function jsonResponse(data, status = 200) {
  return {
    ok: status >= 200 && status < 300,
    status,
    json: async () => data,
  };
}

describe("api (modo backend)", () => {
  let api;
  let fetchMock;

  beforeEach(async () => {
    vi.stubEnv("VITE_SAIYDD_API_URL", BASE);
    vi.stubEnv("VITE_SAIYDD_API_TOKEN", "test-token");
    fetchMock = vi.fn();
    vi.stubGlobal("fetch", fetchMock);
    const mod = await import("../modules/api.js");
    api = mod.api;
  });

  afterEach(() => {
    vi.unstubAllEnvs();
    vi.unstubAllGlobals();
  });

  it("fetches public activities from the backend", async () => {
    const activities = [{ id: "act_001", title: "Sonidos", prompts: ["¿mu?"] }];
    fetchMock.mockResolvedValue(jsonResponse(activities));
    const result = await api.getActivities();
    expect(result).toEqual(activities);
    expect(fetchMock).toHaveBeenCalledWith(
      `${BASE}/api/activities`,
      expect.objectContaining({
        method: "GET",
        headers: { Authorization: "Bearer test-token" },
      }),
    );
  });

  it("fetches a child profile by id", async () => {
    const profile = { id: "child_001", name: "Luna", avatar: "estelar" };
    fetchMock.mockResolvedValue(jsonResponse(profile));
    const result = await api.getProfile("child_001");
    expect(result).toEqual(profile);
    expect(fetchMock).toHaveBeenCalledWith(
      `${BASE}/api/children/child_001`,
      expect.objectContaining({ method: "GET" }),
    );
  });

  it("saves a session and reports success", async () => {
    const session = {
      childId: "child_001",
      activityId: "act_001",
      score: 90,
      durationSeconds: 120,
      interactions: [],
    };
    fetchMock.mockResolvedValue(jsonResponse({ ...session, id: "sess_abc" }));
    const saved = await api.saveSession(session);
    expect(saved).toBe(true);
    expect(fetchMock).toHaveBeenCalledWith(
      `${BASE}/api/sessions`,
      expect.objectContaining({
        method: "POST",
        headers: expect.objectContaining({
          "Content-Type": "application/json",
          Authorization: "Bearer test-token",
        }),
        body: JSON.stringify(session),
      }),
    );
  });

  it("maps backend progress report to the demo shape", async () => {
    const report = {
      childId: "child_001",
      totalSessions: 3,
      averageScore: 85.5,
      totalSeconds: 300,
      lastActivityAt: "2026-10-08T10:00:00Z",
    };
    fetchMock.mockResolvedValue(jsonResponse(report));
    const progress = await api.getProgress("child_001");
    expect(progress).toEqual({
      total: 3,
      avg: 85.5,
      lastAt: "2026-10-08T10:00:00Z",
    });
  });

  it("maps missing last activity to null", async () => {
    fetchMock.mockResolvedValue(
      jsonResponse({
        childId: "child_001",
        totalSessions: 0,
        averageScore: 0,
        totalSeconds: 0,
        lastActivityAt: null,
      }),
    );
    const progress = await api.getProgress("child_001");
    expect(progress).toEqual({ total: 0, avg: 0, lastAt: null });
  });

  it("reports failure when the session record has no id", async () => {
    fetchMock.mockResolvedValue(jsonResponse({ error: "unexpected" }));
    const saved = await api.saveSession({
      childId: "child_001",
      activityId: "act_001",
      score: 1,
      durationSeconds: 1,
      interactions: [],
    });
    expect(saved).toBe(false);
  });

  it("propagates backend errors", async () => {
    fetchMock.mockResolvedValue(jsonResponse({ error: "nope" }, 401));
    await expect(api.getActivities()).rejects.toThrow(/401/);
  });
});
