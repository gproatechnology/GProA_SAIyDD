import data from '../data/data.js';

const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

const { childProfiles, activities, sessions } = data;

export const api = {
  async getActivities() {
    await delay(120);
    return [...(activities || [])];
  },

  async getProfile(childId) {
    await delay(80);
    return (childProfiles || []).find(c => c.id === childId) || null;
  },

  async saveSession(session) {
    await delay(100);
    (sessions || []).push({ ...session, id: `sess_${String(Date.now()).slice(-6)}` });
    return true;
  },

  async getProgress(childId) {
    await delay(100);
    const list = (sessions || []).filter(s => s.childId === childId);
    const total = list.length;
    const avg = total ? Math.round(list.reduce((a, s) => a + (s.score || 0), 0) / total) : 0;
    return { total, avg, lastAt: list.at(-1)?.finishedAt || null };
  },
};