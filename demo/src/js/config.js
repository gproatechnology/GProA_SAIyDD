const env = import.meta.env || {};

export const PIN = env.VITE_SAIYDD_PIN || "1234";
export const PIN_FROM_ENV = Boolean(env.VITE_SAIYDD_PIN);

export const API_URL = (env.VITE_SAIYDD_API_URL || "").trim();
export const API_TOKEN = env.VITE_SAIYDD_API_TOKEN || "";

if (API_URL && !API_TOKEN) {
  console.warn(
    "[SAIyDD] VITE_SAIYDD_API_URL sin VITE_SAIYDD_API_TOKEN: las rutas protegidas fallarán (401).",
  );
}

if (!PIN_FROM_ENV && env.PROD) {
  console.warn(
    "[SAIyDD] Usando PIN por defecto. Configura VITE_SAIYDD_PIN antes de producir.",
  );
}

export function validatePin(input) {
  return String(input ?? "").trim() === PIN;
}
