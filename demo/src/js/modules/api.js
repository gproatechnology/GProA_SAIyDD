import data from "../data/data.js";
import { answerKeys } from "../data/answers.js";

const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const { childProfiles, activities, sessions } = data;

function publicActivity({ correctIndices, ...publicFields }) {
  return publicFields;
}

export const api = {
  async getActivities() {
    await delay(120);
    return activities.map(publicActivity);
  },

  async getProfile(childId) {
    await delay(80);
    return (childProfiles || []).find((c) => c.id === childId) || null;
  },

  async saveSession(session) {
    await delay(100);
    (sessions || []).push({
      ...session,
      id: `sess_${String(Date.now()).slice(-6)}`,
    });
    return true;
  },

  async getProgress(childId) {
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
