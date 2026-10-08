import { describe, it, expect } from "vitest";
import { escapeHtml, clampText, isSafeText } from "../utils/sanitize.js";

describe("escapeHtml", () => {
  it("escapes HTML special characters", () => {
    expect(escapeHtml(`<script>"x" & 'y'</script>`)).toBe(
      "&lt;script&gt;&quot;x&quot; &amp; &#39;y&#39;&lt;/script&gt;",
    );
  });

  it("returns empty string for non-strings", () => {
    expect(escapeHtml(null)).toBe("");
    expect(escapeHtml(undefined)).toBe("");
    expect(escapeHtml(42)).toBe("");
  });
});

describe("clampText", () => {
  it("keeps short text intact", () => {
    expect(clampText("hola", 10)).toBe("hola");
  });

  it("trims and truncates long text", () => {
    expect(clampText("aaaaaaaaaa", 5)).toBe("aa...");
  });

  it("returns empty for non-strings", () => {
    expect(clampText(null)).toBe("");
  });
});

describe("isSafeText", () => {
  it("accepts normal text", () => {
    expect(isSafeText("hola")).toBe(true);
  });

  it("rejects empty, blank or too long text", () => {
    expect(isSafeText("")).toBe(false);
    expect(isSafeText("   ")).toBe(false);
    expect(isSafeText("x".repeat(501))).toBe(false);
    expect(isSafeText(123)).toBe(false);
  });
});
