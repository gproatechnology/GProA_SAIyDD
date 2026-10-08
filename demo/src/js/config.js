const env = import.meta.env || {};

export const PIN = env.VITE_SAIYDD_PIN || '1234';
export const PIN_FROM_ENV = Boolean(env.VITE_SAIYDD_PIN);

if (!PIN_FROM_ENV && env.PROD) {
  console.warn('[SAIyDD] Usando PIN por defecto. Configura VITE_SAIYDD_PIN antes de producir.');
}

export function validatePin(input) {
  return String(input ?? '').trim() === PIN;
}
