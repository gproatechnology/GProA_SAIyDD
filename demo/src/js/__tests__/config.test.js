import { describe, it, expect } from "vitest";
import { validatePin, PIN, PIN_FROM_ENV } from "../config.js";

describe("config", () => {
  it("falls back to demo PIN when env is not set", () => {
    expect(PIN_FROM_ENV).toBe(false);
    expect(PIN).toBeTruthy();
  });

  it("validates the configured PIN", () => {
    expect(validatePin(PIN)).toBe(true);
    expect(validatePin("wrong-pin")).toBe(false);
    expect(validatePin(null)).toBe(false);
    expect(validatePin("   ")).toBe(false);
  });
});
