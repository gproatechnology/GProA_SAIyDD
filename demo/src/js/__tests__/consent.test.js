import { describe, it, expect, beforeEach } from "vitest";
import {
  getConsentStatus,
  setConsent,
  isConsentGranted,
  clearAllChildData,
} from "../utils/consent.js";

class MemoryStorage {
  constructor() {
    this.store = new Map();
  }
  getItem(key) {
    return this.store.has(key) ? this.store.get(key) : null;
  }
  setItem(key, value) {
    this.store.set(String(key), String(value));
  }
  removeItem(key) {
    this.store.delete(key);
  }
  clear() {
    this.store.clear();
  }
  get length() {
    return this.store.size;
  }
  key(index) {
    return Array.from(this.store.keys())[index] || null;
  }
}

describe("consent utils", () => {
  beforeEach(() => {
    globalThis.localStorage = new MemoryStorage();
  });

  it("returns default not granted status when no consent has been set", () => {
    const status = getConsentStatus();
    expect(status.granted).toBe(false);
    expect(status.timestamp).toBeNull();
    expect(status.guardianConfirmed).toBe(false);
    expect(isConsentGranted()).toBe(false);
  });

  it("sets and retrieves parental consent", () => {
    const updated = setConsent(true);
    expect(updated.granted).toBe(true);
    expect(updated.guardianConfirmed).toBe(true);
    expect(typeof updated.timestamp).toBe("string");

    const status = getConsentStatus();
    expect(status.granted).toBe(true);
    expect(isConsentGranted()).toBe(true);
  });

  it("revokes parental consent", () => {
    setConsent(true);
    expect(isConsentGranted()).toBe(true);

    setConsent(false);
    expect(isConsentGranted()).toBe(false);
  });

  it("clears all child data while respecting preserveConsent option", () => {
    setConsent(true);
    globalThis.localStorage.setItem(
      "saiydd_profile",
      JSON.stringify({ name: "Luna" }),
    );
    globalThis.localStorage.setItem(
      "saiydd_sessions_demo",
      JSON.stringify([{ id: "s1" }]),
    );
    globalThis.localStorage.setItem(
      "saiydd_blocks_demo",
      JSON.stringify({ levelIndex: 2 }),
    );
    globalThis.localStorage.setItem("other_app_data", "preserve-this");

    expect(globalThis.localStorage.getItem("saiydd_profile")).toBeTruthy();

    clearAllChildData({ preserveConsent: true });

    expect(globalThis.localStorage.getItem("saiydd_profile")).toBeNull();
    expect(globalThis.localStorage.getItem("saiydd_sessions_demo")).toBeNull();
    expect(globalThis.localStorage.getItem("saiydd_blocks_demo")).toBeNull();
    expect(globalThis.localStorage.getItem("other_app_data")).toBe(
      "preserve-this",
    );
    expect(isConsentGranted()).toBe(true);
  });

  it("clears everything including consent when preserveConsent is false", () => {
    setConsent(true);
    globalThis.localStorage.setItem(
      "saiydd_profile",
      JSON.stringify({ name: "Luna" }),
    );

    clearAllChildData({ preserveConsent: false });

    expect(globalThis.localStorage.getItem("saiydd_profile")).toBeNull();
    expect(isConsentGranted()).toBe(false);
  });
});
