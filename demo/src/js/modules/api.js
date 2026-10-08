import data from "../data/data.js";
import { answerKeys } from "../data/answers.js";
import { API_TOKEN, API_URL } from "../config.js";

const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const { childProfiles, activities, sessions } = data;

const BACKEND_URL = (API_URL || "").replace(/\/+$/, "");

function publicActivity({ correctIndices, ...publicFields }) {
  return publicFields;
}

async function request(method, path, body) {
  const headers = {};
  if (API_TOKEN) {
    headers.Authorization = `Bearer ${API_TOKEN}`;
  }
  const init = { method, headers };
  if (body !== undefined) {
    headers["Content-Type"] = "application/json";
    init.body = JSON.stringify(body);
  }
  const res = await fetch(`${BACKEND_URL}${path}`, init);
  if (!res.ok) {
    throw new Error(`Backend error ${res.status} en ${method} ${path}`);
  }
  return res.json();
}

export const api = {
  async getActivities() {
    if (BACKEND_URL) {
      return request("GET", "/api/activities");
    }
    await delay(120);
    return activities.map(publicActivity);
  },

  async getProfile(childId) {
    if (BACKEND_URL) {
      return request("GET", `/api/children/${encodeURIComponent(childId)}`);
    }
    await delay(80);
    return (childProfiles || []).find((c) => c.id === childId) || null;
  },

  async saveSession(session) {
    if (BACKEND_URL) {
      const record = await request("POST", "/api/sessions", session);
      return Boolean(record && record.id);
    }
    await delay(100);
    (sessions || []).push({
      ...session,
      id: `sess_${String(Date.now()).slice(-6)}`,
    });
    return true;
  },

  async getProgress(childId) {
    if (BACKEND_URL) {
      const report = await request(
        "GET",
        `/api/children/${encodeURIComponent(childId)}/progress`,
      );
      return {
        total: report.totalSessions,
        avg: report.averageScore,
        lastAt: report.lastActivityAt || null,
      };
    }
    await delay(100);
    const list = (sessions || []).filter((s) => s.childId === childId);
    const total = list.length;
    const avg = total
      ? Math.round(list.reduce((a, s) => a + (s.score || 0), 0) / total)
      : 0;
    return { total, avg, lastAt: list.at(-1)?.finishedAt || null };
  },

  async submitAnswer(activityId, step, selectedIndex) {
    await delay(60);
    const act = activities.find((a) => a.id === activityId);
    if (!act) return { correct: false, correctOption: null };

    const opts = act.options || [];
    if (act.type === "memory") {
      const correct = opts[selectedIndex] === opts[step];
      return { correct, correctOption: opts[step] ?? null };
    }

    const keys = answerKeys[activityId] || [];
    const correctIndex = keys[step];
    return {
      correct: selectedIndex === correctIndex,
      correctOption: opts[correctIndex] ?? null,
    };
  },
};
